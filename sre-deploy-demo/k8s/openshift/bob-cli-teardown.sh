#!/bin/bash
# Remove Bob CLI from OpenShift
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
K8S_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if ! oc whoami &>/dev/null; then
    echo "Error: Not logged into OpenShift."
    exit 1
fi

NAMESPACE=$(oc project -q)
echo "Removing Bob CLI from namespace: $NAMESPACE"

oc delete -f "$K8S_DIR/bob-cli-deployment.yaml" 2>/dev/null || true
oc delete secret bob-cli-credentials 2>/dev/null || true
oc delete sa bob-cli -n "$NAMESPACE" 2>/dev/null || true

echo "Bob CLI removed."
