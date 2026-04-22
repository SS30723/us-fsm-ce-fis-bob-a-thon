# ═══════════════════════════════════════════════════════════════════
# FIS Bob-a-thon — Jenkins Agent Image
#
# Base tooling for the workshop pipeline:
#   - Maven 3.9 + JDK17 (baseline for Lab 2 Java unit tests)
#   - git, curl, jq (general utilities)
#
# Lab colleagues extend this Dockerfile as needed:
#   - Lab 3: security scanner (colleague is using sonarqube or similar)
#   - Lab 4: linter (checkov, kubelinter, or similar)
#   - Lab 5: nothing here — MCP additions go in bob-cli-sidecar instead
#
# Rebuild after any change:
#   cd k8s/openshift/jenkins-agent
#   oc start-build jenkins-agent --from-dir=. --follow
# ═══════════════════════════════════════════════════════════════════

FROM jenkins/inbound-agent:latest-jdk17

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends git curl jq && \
    curl -fsSL https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz | \
    tar xz -C /opt && \
    ln -s /opt/apache-maven-3.9.9/bin/mvn /usr/local/bin/mvn && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# OpenShift runs containers as a random UID in the namespace's assigned
# range, always in group 0. Make /home/jenkins writable by group 0 so
# the agent can write temp files regardless of the runtime UID.
RUN chmod -R 775 /home/jenkins && chgrp -R 0 /home/jenkins

RUN mvn --version && jq --version

USER 1001
