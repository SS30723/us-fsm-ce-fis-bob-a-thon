FROM jenkins/inbound-agent:latest-jdk17

USER root

# Maven 3.9
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl jq && \
    curl -fsSL https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz | \
    tar xz -C /opt && \
    ln -s /opt/apache-maven-3.9.9/bin/mvn /usr/local/bin/mvn

# Trivy (security scanner)
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | \
    sh -s -- -b /usr/local/bin

# OpenShift CLI (oc)
RUN curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz | \
    tar xz -C /usr/local/bin oc kubectl

# Python 3 (for JSON parsing in scripts)
RUN apt-get install -y --no-install-recommends python3 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Ensure /home/jenkins is writable by any UID (OpenShift random UIDs)
RUN chmod -R 775 /home/jenkins && chgrp -R 0 /home/jenkins

RUN mvn --version && jq --version && which oc && which trivy

USER 1001
