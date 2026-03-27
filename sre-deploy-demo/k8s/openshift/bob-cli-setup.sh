#!/bin/bash
# Deploy Bob CLI to OpenShift
#
# Prerequisites:
# - oc login completed
# - oc project set to sre-deploy-demo
# - Internal registry enabled (same as main setup)
# - .env file with BOBSHELL_API_KEY in project root

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
K8S_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$(cd "$K8S_DIR/.." && pwd)"

INTERNAL_REGISTRY="image-registry.openshift-image-registry.svc:5000"

# ── Preflight checks ─────────────────────────────────────────────────────────

echo "=== Bob CLI Deploy — Preflight checks ==="

if ! command -v oc &>/dev/null; then
    echo "Error: oc CLI not found."
    exit 1
fi

if ! oc whoami &>/dev/null; then
    echo "Error: Not logged into OpenShift."
    exit 1
fi

NAMESPACE=$(oc project -q)
echo "Namespace: $NAMESPACE"

# ── Check for API key ──────────────────────────────────────────────────────────
# The API key is read here on YOUR MACHINE, then stored as a Kubernetes Secret
# on the cluster. Bob CLI is NOT installed locally — it only runs inside the pod.

if [ -z "$BOBSHELL_API_KEY" ]; then
    if [ -f "$PROJECT_DIR/.env" ] && grep -q BOBSHELL_API_KEY "$PROJECT_DIR/.env"; then
        export $(grep BOBSHELL_API_KEY "$PROJECT_DIR/.env" | xargs)
        echo "Loaded BOBSHELL_API_KEY from .env file"
    else
        echo "Error: BOBSHELL_API_KEY is not set."
        echo ""
        echo "Create a .env file in the project root with:"
        echo "  BOBSHELL_API_KEY=your-key-here"
        echo ""
        echo "This key is used to create a Kubernetes Secret on the cluster."
        echo "Bob CLI runs inside the pod, not on your machine."
        exit 1
    fi
fi

# ── Get registry hostname ────────────────────────────────────────────────────

REGISTRY_HOST=$(oc get route default-route -n openshift-image-registry -o jsonpath='{.spec.host}' 2>/dev/null)
if [ -z "$REGISTRY_HOST" ]; then
    echo "Error: Internal registry route not found. Run 'make oc-deploy' first to set up the registry."
    exit 1
fi

# ── Authenticate to registry ────────────────────────────────────────────────

echo ""
echo "=== Authenticating to registry ==="

SA_NAME="registry-pusher"
oc get sa "$SA_NAME" -n "$NAMESPACE" &>/dev/null 2>&1 || \
    oc create sa "$SA_NAME" -n "$NAMESPACE"
oc policy add-role-to-user registry-editor "system:serviceaccount:$NAMESPACE:$SA_NAME" 2>/dev/null || true

SA_TOKEN=$(oc create token "$SA_NAME" -n "$NAMESPACE")
podman login -u serviceaccount -p "$SA_TOKEN" --tls-verify=false "$REGISTRY_HOST"

# ── Build and push Bob CLI image ────────────────────────────────────────────

FULL_TAG="$REGISTRY_HOST/$NAMESPACE/sre-bob-cli:latest"

echo ""
echo "=== Building Bob CLI image (linux/amd64) ==="
podman build --platform linux/amd64 \
    -t "$FULL_TAG" \
    -f "$SCRIPT_DIR/bob-cli/Dockerfile" \
    "$PROJECT_DIR"

echo "=== Pushing Bob CLI image ==="
podman push --tls-verify=false "$FULL_TAG"

# ── Create Secret for API key ───────────────────────────────────────────────

echo ""
echo "=== Creating Bob CLI credentials Secret ==="
oc delete secret bob-cli-credentials 2>/dev/null || true
oc create secret generic bob-cli-credentials \
    --from-literal=BOBSHELL_API_KEY="$BOBSHELL_API_KEY"

# ── Create ServiceAccount with permissions ──────────────────────────────────

echo ""
echo "=== Creating Bob CLI ServiceAccount ==="
oc get sa bob-cli -n "$NAMESPACE" &>/dev/null 2>&1 || \
    oc create sa bob-cli -n "$NAMESPACE"

# Grant edit access so bob-cli can manage pods, deployments, configmaps, etc.
oc policy add-role-to-user edit "system:serviceaccount:$NAMESPACE:bob-cli" 2>/dev/null || true

# ── Apply deployment manifest ───────────────────────────────────────────────

echo ""
echo "=== Deploying Bob CLI pod ==="
sed \
    "s|sre-bob-cli:latest|$INTERNAL_REGISTRY/$NAMESPACE/sre-bob-cli:latest|g;
     s|imagePullPolicy: IfNotPresent|imagePullPolicy: Always|g" \
    "$K8S_DIR/bob-cli-deployment.yaml" | oc apply -f -

# ── Restart pod to pick up new image ─────────────────────────────────────────

echo ""
echo "=== Restarting Bob CLI pod ==="
oc rollout restart deployment/bob-cli
oc rollout status deployment/bob-cli --timeout=120s

# ── Verify ──────────────────────────────────────────────────────────────────

echo ""
BOB_POD=$(oc get pods -l component=bob-cli -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
echo "=== Verifying Bob CLI ==="
echo "Pod: $BOB_POD"

# Check bob is installed and can authenticate
oc exec "$BOB_POD" -- bob -p "Reply with exactly: BOB_CLI_OK" --hide-intermediary-output 2>/dev/null | grep -q "BOB_CLI_OK" && \
    echo "Bob CLI is working!" || \
    echo "Warning: Bob CLI verification did not return expected output. Check 'oc logs $BOB_POD' for details."

echo ""
echo "========================================"
echo "  Bob CLI deployed!"
echo "========================================"
echo ""
echo "Run a command:  oc exec $BOB_POD -- bob -p \"your prompt here\""
echo "View logs:      oc logs $BOB_POD"
echo ""
