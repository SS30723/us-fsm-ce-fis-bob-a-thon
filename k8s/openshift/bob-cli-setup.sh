#!/bin/bash
# Deploy Bob CLI to OpenShift
#
# Prerequisites:
# - oc login completed
# - oc project set to sre-deploy-lab
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

# ── Build Bob CLI image on cluster ────────────────────────────────────────────

echo ""
echo "=== Building Bob CLI image (on-cluster BuildConfig) ==="

if ! oc get bc/sre-bob-cli-build &>/dev/null 2>&1; then
    oc new-build --binary --name=sre-bob-cli-build \
        --docker-image=registry.access.redhat.com/ubi8/ubi-minimal:latest \
        --strategy=docker
fi

oc start-build sre-bob-cli-build \
    --from-dir="$SCRIPT_DIR/bob-cli" \
    --follow --wait

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
    "s|sre-bob-cli:latest|$INTERNAL_REGISTRY/$NAMESPACE/sre-bob-cli-build:latest|g;
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
