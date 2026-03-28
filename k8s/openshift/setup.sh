#!/bin/bash
# Deploy order-service to OpenShift
# Prerequisites: oc login completed, project created
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== Preflight checks ==="
if ! oc whoami &>/dev/null; then
    echo "Error: Not logged into OpenShift. Run: oc login ..."
    exit 1
fi

NAMESPACE=$(oc project -q)
REGISTRY="image-registry.openshift-image-registry.svc:5000/${NAMESPACE}"
echo "Namespace: $NAMESPACE"
echo "Registry:  $REGISTRY"

# ── Enable internal registry (if not already) ────────────────────────────
echo ""
echo "=== Enabling internal registry ==="
oc patch configs.imageregistry.operator.openshift.io/cluster \
    --type merge -p '{"spec":{"managementState":"Managed"}}' 2>/dev/null || true
oc patch configs.imageregistry.operator.openshift.io/cluster \
    --type merge -p '{"spec":{"defaultRoute":true}}' 2>/dev/null || true

# ── Deploy database ─────────────────────────────────────────────────────
echo ""
echo "=== Deploying order-db ==="
oc apply -f "$PROJECT_DIR/k8s/order-db-deployment.yaml"
oc apply -f "$PROJECT_DIR/k8s/order-db-service.yaml"
echo "Waiting for order-db..."
oc rollout status deployment/order-db --timeout=120s

# ── Build order-service image ────────────────────────────────────────────
echo ""
echo "=== Building order-service ==="
cd "$PROJECT_DIR/order-service"
mvn package -DskipTests -q
cd "$PROJECT_DIR"

# Create build config if it doesn't exist
if ! oc get bc/order-service-build &>/dev/null 2>&1; then
    oc new-build --binary --name=order-service-build \
        --image-stream=openshift/ubi8-openjdk-17:1.18 \
        --strategy=docker 2>/dev/null || \
    oc new-build --binary --name=order-service-build \
        --docker-image=eclipse-temurin:17-jre-alpine \
        --strategy=docker
fi

oc start-build order-service-build \
    --from-dir=order-service \
    --follow --wait

# ── Deploy order-service ─────────────────────────────────────────────────
echo ""
echo "=== Deploying order-service ==="
IMAGE="${REGISTRY}/order-service-build:latest"
sed "s|IMAGE_PLACEHOLDER|${IMAGE}|g" "$PROJECT_DIR/k8s/order-service-deployment.yaml" | oc apply -f -
oc apply -f "$PROJECT_DIR/k8s/order-service-service.yaml"

# Create route if it doesn't exist
oc expose svc/order-service 2>/dev/null || true

echo "Waiting for order-service..."
oc rollout status deployment/order-service --timeout=180s

# ── Verify ───────────────────────────────────────────────────────────────
echo ""
echo "=== Verifying deployment ==="
ORDER_ROUTE=$(oc get route order-service -o jsonpath='{.spec.host}' 2>/dev/null || echo "")

echo ""
echo "========================================"
echo "  Deployment complete!"
echo "========================================"
echo ""
echo "Order Service: http://${ORDER_ROUTE}/api/orders"
echo "Health Check:  http://${ORDER_ROUTE}/api/orders/health"
echo ""
echo "Test with:"
echo "  curl http://${ORDER_ROUTE}/api/orders/health"
echo ""
