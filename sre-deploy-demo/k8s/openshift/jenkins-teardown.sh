#!/bin/bash
# Remove Jenkins from OpenShift
set -e

echo "=== Removing Jenkins ==="
oc delete dc/jenkins 2>/dev/null || oc delete deployment/jenkins 2>/dev/null || true
oc delete svc/jenkins 2>/dev/null || true
oc delete svc/jenkins-jnlp 2>/dev/null || true
oc delete route/jenkins 2>/dev/null || true
oc delete pvc/jenkins 2>/dev/null || true
oc delete sa/jenkins 2>/dev/null || true
oc delete rolebinding/jenkins_edit 2>/dev/null || true
oc delete secret/jenkins-frontend-credentials 2>/dev/null || true
oc delete is/sre-jenkins-agent 2>/dev/null || true
oc delete bc/sre-jenkins-agent 2>/dev/null || true

echo "Done."
