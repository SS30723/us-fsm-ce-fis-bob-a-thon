FROM python:3.12-slim

ARG HADOLINT_VERSION=v2.12.0
ARG KUBELINTER_VERSION=0.7.2
ARG CHECKOV_VERSION=3.2.313

RUN apt-get update && \
    apt-get install -y curl bash jq git ca-certificates tar && \
    pip install --no-cache-dir checkov==${CHECKOV_VERSION} && \
    curl -L -o /usr/local/bin/hadolint \
      https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64 && \
    curl -L -o /tmp/kube-linter.tar.gz \
      https://github.com/stackrox/kube-linter/releases/download/v${KUBELINTER_VERSION}/kube-linter-linux.tar.gz && \
    tar -xzf /tmp/kube-linter.tar.gz -C /tmp && \
    mv /tmp/kube-linter /usr/local/bin/kube-linter && \
    chmod +x /usr/local/bin/hadolint /usr/local/bin/kube-linter && \
    rm -f /tmp/kube-linter.tar.gz && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV HOME=/workspace

RUN mkdir -p /workspace && \
    chgrp -R 0 /workspace && \
    chmod -R g=u /workspace

WORKDIR /workspace
CMD ["sleep", "infinity"]

# Made with Bob
