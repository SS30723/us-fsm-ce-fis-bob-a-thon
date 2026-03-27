#!/bin/bash
# Build custom Jenkins agent image on OpenShift
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Building sre-jenkins-agent image ==="

if ! oc get bc/sre-jenkins-agent &>/dev/null 2>&1; then
    oc new-build --binary --name=sre-jenkins-agent \
        --docker-image=jenkins/inbound-agent:latest-jdk17 \
        --strategy=docker
fi

oc start-build sre-jenkins-agent \
    --from-dir="${SCRIPT_DIR}/jenkins-agent" \
    --follow --wait

echo "Jenkins agent image built."
