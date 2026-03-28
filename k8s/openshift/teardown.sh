#!/bin/bash
# Remove order-service from OpenShift
set -e

echo "=== Removing order-service ==="
oc delete deployment/order-service 2>/dev/null || true
oc delete svc/order-service 2>/dev/null || true
oc delete route/order-service 2>/dev/null || true
oc delete bc/order-service-build 2>/dev/null || true
oc delete is/order-service-build 2>/dev/null || true

echo "=== Removing order-db ==="
oc delete deployment/order-db 2>/dev/null || true
oc delete svc/order-db 2>/dev/null || true

echo "Done."
