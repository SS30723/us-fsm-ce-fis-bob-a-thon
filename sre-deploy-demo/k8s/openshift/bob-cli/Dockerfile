FROM node:22-slim

# Install oc CLI
RUN apt-get update && \
    apt-get install -y curl bash tar jq && \
    curl -sL https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz | tar xz -C /usr/local/bin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Bob Shell (--pm npm skips the interactive package manager prompt)
RUN curl -s https://s3.us-south.cloud-object-storage.appdomain.cloud/bobshell/install-bobshell.sh | bash -s -- --pm npm

# Set HOME so Bob can write to ~/.bob (OpenShift runs as arbitrary UID)
ENV HOME=/workspace \
    BOB_ACCEPT_LICENSE=true

# Create workspace directory with write permissions
WORKDIR /workspace
RUN mkdir -p /workspace/.bob && chmod -R 777 /workspace

# Keep the container running so we can oc exec into it
CMD ["sleep", "infinity"]
