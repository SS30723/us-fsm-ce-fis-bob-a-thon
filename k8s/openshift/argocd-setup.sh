#!/bin/bash
# Install ArgoCD (OpenShift GitOps) and create Application CR
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
NAMESPACE=$(oc project -q)

# ── Load config from .env file if available ───────────────────────────────────

if [ -f "$PROJECT_DIR/.env" ] && [ -z "$GITHUB_REPO_URL" ] && grep -q GITHUB_REPO_URL "$PROJECT_DIR/.env"; then
    export $(grep GITHUB_REPO_URL "$PROJECT_DIR/.env" | xargs)
    echo "Loaded GITHUB_REPO_URL from .env file"
fi

echo "=== Step 1: Install OpenShift GitOps Operator ==="

# Check if already installed
if oc get subscription openshift-gitops-operator -n openshift-operators &>/dev/null 2>&1; then
    echo "OpenShift GitOps operator already installed."
else
    cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops-operator
  namespace: openshift-operators
spec:
  channel: latest
  installPlanApproval: Automatic
  name: openshift-gitops-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
    echo "Waiting for operator to install (this takes 1-2 minutes)..."
    sleep 30
    oc wait --for=condition=Available deployment/openshift-gitops-server \
        -n openshift-gitops --timeout=300s 2>/dev/null || \
        echo "Waiting for GitOps operator to be ready..."
    sleep 30
fi

echo ""
echo "=== Step 2: Grant ArgoCD access to our namespace ==="

# Allow the ArgoCD controller to manage resources in our namespace
oc adm policy add-role-to-user admin \
    system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller \
    -n "$NAMESPACE" 2>/dev/null || true

echo ""
echo "=== Step 3: Create ArgoCD Application ==="

GITHUB_REPO_URL="${GITHUB_REPO_URL:-https://github.ibm.com/Andy-Madden/sre-project}"

# Apply the Application CR (but only if not already created)
if oc get application order-service -n openshift-gitops &>/dev/null 2>&1; then
    echo "ArgoCD Application 'order-service' already exists."
else
    sed "s|repoURL: .*|repoURL: ${GITHUB_REPO_URL}|g; s|namespace: .*|namespace: ${NAMESPACE}|g" \
        "$SCRIPT_DIR/argocd-application.yaml" | oc apply -f -
    echo "ArgoCD Application created (repo: ${GITHUB_REPO_URL})."
fi

ARGOCD_ROUTE=$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}' 2>/dev/null || echo "")

echo ""
echo "========================================"
echo "  ArgoCD setup complete!"
echo "========================================"
echo ""
echo "ArgoCD UI:  https://${ARGOCD_ROUTE}"
echo "App name:   order-service"
echo "Namespace:  ${NAMESPACE}"
echo ""
echo "Default admin password:"
echo "  oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-"
echo ""
