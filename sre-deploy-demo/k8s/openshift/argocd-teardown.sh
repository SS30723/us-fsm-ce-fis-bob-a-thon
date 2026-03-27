#!/bin/bash
# Remove ArgoCD application (not the operator — that's cluster-wide)
set -e

echo "=== Removing ArgoCD Application ==="
oc delete application order-service -n openshift-gitops 2>/dev/null || true

echo "Done. (GitOps operator left in place — remove via OperatorHub if needed)"
