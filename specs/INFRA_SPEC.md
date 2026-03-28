# INFRA_SPEC — Kubernetes Manifests, Setup Scripts, Makefile

All infrastructure files with complete contents.

---

## Kubernetes Manifests

### `k8s/order-db-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-db
  labels:
    app: order-db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: order-db
  template:
    metadata:
      labels:
        app: order-db
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: orders
        - name: POSTGRES_USER
          value: orderuser
        - name: POSTGRES_PASSWORD
          value: orderpass
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        readinessProbe:
          exec:
            command: ["pg_isready", "-U", "orderuser", "-d", "orders"]
          initialDelaySeconds: 5
          periodSeconds: 10
```

### `k8s/order-db-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: order-db
spec:
  selector:
    app: order-db
  ports:
  - port: 5432
    targetPort: 5432
```

### `k8s/order-service-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  labels:
    app: order-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
    spec:
      containers:
      - name: order-service
        image: IMAGE_PLACEHOLDER
        ports:
        - containerPort: 8080
        env:
        - name: DB_HOST
          value: order-db
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: orders
        - name: DB_USER
          value: orderuser
        - name: DB_PASS
          value: orderpass
        resources:
          requests:
            memory: "256Mi"
            cpu: "200m"
          limits:
            memory: "512Mi"
            cpu: "1"
        startupProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 5
          failureThreshold: 20
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: 8080
          periodSeconds: 15
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: 8080
          periodSeconds: 10
```

### `k8s/order-service-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: order-service
spec:
  selector:
    app: order-service
  ports:
  - port: 8080
    targetPort: 8080
```

---

## Jenkins Agent Dockerfile

### `k8s/openshift/jenkins-agent/Dockerfile`

Simplified from the dental claims version — Java and Maven only, no Node.js or Python.

```dockerfile
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
```

---

## Setup Scripts

### `k8s/openshift/setup.sh`

Deploys the order-service application to OpenShift.

```bash
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
```

### `k8s/openshift/teardown.sh`

```bash
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
```

### `k8s/openshift/jenkins-setup.sh`

Identical in structure to the existing dental claims `jenkins-setup.sh`, but creates a job called `sre-pipeline` pointing to the `Jenkinsfile` in this repo. The script should be **copied from the existing project** (`ibm-bob-sdlc-lab/k8s/openshift/jenkins-setup.sh`) and modified with these changes:

1. Change `GITHUB_REPO_URL` default to point to the new repo
2. Change the job name from `dental-pipeline` to `sre-pipeline`
3. Change the `scriptPath` in the job XML from `Jenkinsfile` to `Jenkinsfile`  (same, just confirming)
4. Change the default branch from `lab/happy-path` to `lab/happy-path`  (same)
5. Remove the frontend service account patching (Step 5) — there is no frontend in this project
6. Keep everything else (plugin installation, credential creation, auth detection, crumb handling)

The modified sections:

```bash
# Line ~89: Change repo URL
GITHUB_REPO_URL="${GITHUB_REPO_URL:-https://github.ibm.com/Andy-Madden/sre-project}"

# Line ~282: Change job name
echo "=== Step 4: Creating sre-pipeline job ==="
# ... (use 'sre-pipeline' wherever 'dental-pipeline' appeared)

# Remove Step 5 entirely (no frontend to configure)
```

### `k8s/openshift/jenkins-teardown.sh`

```bash
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
```

### `k8s/openshift/jenkins-agent-build.sh`

```bash
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
```

### `k8s/openshift/bob-cli-setup.sh`

Copy directly from existing project (`ibm-bob-sdlc-lab/k8s/openshift/bob-cli-setup.sh`). No changes needed — the Bob CLI pod is generic and works for any project.

### `k8s/openshift/bob-cli-teardown.sh`

Copy directly from existing project. No changes needed.

### `k8s/openshift/argocd-setup.sh`

ArgoCD installation. Follow the plan in `docs/plans/ARGO_PLAN.md` from the existing project.

```bash
#!/bin/bash
# Install ArgoCD (OpenShift GitOps) and create Application CR
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NAMESPACE=$(oc project -q)

echo "=== Step 1: Install OpenShift GitOps Operator ==="

# Check if already installed
if oc get subscription openshift-gitops-operator -n openshift-operators &>/dev/null 2>&1; then
    echo "OpenShift GitOps operator already installed."
else
    cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops-operator
  namespace: openshift-operators
spec:
  channel: latest
  installPlanApproval: Automatic
  name: openshift-gitops-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
    echo "Waiting for operator to install (this takes 1-2 minutes)..."
    sleep 30
    oc wait --for=condition=Available deployment/openshift-gitops-server \
        -n openshift-gitops --timeout=300s 2>/dev/null || \
        echo "Waiting for GitOps operator to be ready..."
    sleep 30
fi

echo ""
echo "=== Step 2: Grant ArgoCD access to our namespace ==="

# Allow the ArgoCD controller to manage resources in our namespace
oc adm policy add-role-to-user admin \
    system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller \
    -n "$NAMESPACE" 2>/dev/null || true

echo ""
echo "=== Step 3: Create ArgoCD Application ==="

# Apply the Application CR (but only if not already created)
if oc get application order-service -n openshift-gitops &>/dev/null 2>&1; then
    echo "ArgoCD Application 'order-service' already exists."
else
    oc apply -f "$SCRIPT_DIR/argocd-application.yaml"
    echo "ArgoCD Application created."
fi

ARGOCD_ROUTE=$(oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}' 2>/dev/null || echo "")

echo ""
echo "========================================"
echo "  ArgoCD setup complete!"
echo "========================================"
echo ""
echo "ArgoCD UI:  https://${ARGOCD_ROUTE}"
echo "App name:   order-service"
echo "Namespace:  ${NAMESPACE}"
echo ""
echo "Default admin password:"
echo "  oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-"
echo ""
```

### `k8s/openshift/argocd-application.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: order-service
  namespace: openshift-gitops
spec:
  project: default
  source:
    # Update this to your repo URL
    repoURL: https://github.ibm.com/Andy-Madden/sre-project
    targetRevision: main
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    # Update this to your namespace
    namespace: sre-deploy-lab
  syncPolicy:
    # Manual sync for demo control — click "Sync" in ArgoCD UI
    # Change to automated for real use:
    # automated:
    #   prune: true
    #   selfHeal: true
    syncOptions:
    - CreateNamespace=false
```

### `k8s/openshift/argocd-teardown.sh`

```bash
#!/bin/bash
# Remove ArgoCD application (not the operator — that's cluster-wide)
set -e

echo "=== Removing ArgoCD Application ==="
oc delete application order-service -n openshift-gitops 2>/dev/null || true

echo "Done. (GitOps operator left in place — remove via OperatorHub if needed)"
```

---

## Makefile

### `Makefile`

```makefile
# ═══════════════════════════════════════════════════════════
# SRE Deploy Demo — Makefile
# ═══════════════════════════════════════════════════════════

SHELL := /bin/bash
SCRIPTS := k8s/openshift

.PHONY: help setup teardown test \
        oc-deploy oc-teardown oc-redeploy \
        oc-deploy-jenkins oc-teardown-jenkins oc-build-jenkins-agent \
        oc-deploy-argocd oc-teardown-argocd \
        oc-deploy-bob oc-teardown-bob \
        oc-bob demo-branches

# ── Help ─────────────────────────────────────────────────

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

# ── Full Setup / Teardown ────────────────────────────────

setup: oc-deploy oc-deploy-jenkins oc-deploy-bob ## Deploy everything (app + Jenkins + Bob)
	@echo ""
	@echo "Setup complete. Run 'make oc-deploy-argocd' to add ArgoCD."

teardown: oc-teardown-argocd oc-teardown-bob oc-teardown-jenkins oc-teardown ## Remove everything

# ── Application ──────────────────────────────────────────

oc-deploy: ## Deploy order-service to OpenShift
	bash $(SCRIPTS)/setup.sh

oc-teardown: ## Remove order-service from OpenShift
	bash $(SCRIPTS)/teardown.sh

oc-redeploy: ## Rebuild and redeploy order-service
	cd order-service && mvn package -DskipTests -q
	oc start-build order-service-build --from-dir=order-service --follow --wait
	oc rollout restart deployment/order-service
	oc rollout status deployment/order-service --timeout=120s

# ── Jenkins ──────────────────────────────────────────────

oc-deploy-jenkins: oc-build-jenkins-agent ## Deploy Jenkins + create pipeline job
	bash $(SCRIPTS)/jenkins-setup.sh

oc-teardown-jenkins: ## Remove Jenkins
	bash $(SCRIPTS)/jenkins-teardown.sh

oc-build-jenkins-agent: ## Build custom Jenkins agent image
	bash $(SCRIPTS)/jenkins-agent-build.sh

# ── ArgoCD ───────────────────────────────────────────────

oc-deploy-argocd: ## Install ArgoCD and create Application
	bash $(SCRIPTS)/argocd-setup.sh

oc-teardown-argocd: ## Remove ArgoCD Application
	bash $(SCRIPTS)/argocd-teardown.sh

# ── Bob CLI ──────────────────────────────────────────────

oc-deploy-bob: ## Deploy Bob CLI pod
	bash $(SCRIPTS)/bob-cli-setup.sh

oc-teardown-bob: ## Remove Bob CLI pod
	bash $(SCRIPTS)/bob-cli-teardown.sh

oc-bob: ## Run a Bob prompt on the cluster (PROMPT="your question")
	@if [ -z "$(PROMPT)" ]; then echo "Usage: make oc-bob PROMPT=\"your question\""; exit 1; fi
	@BOB_POD=$$(oc get pods -l component=bob-cli -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -z "$$BOB_POD" ]; then echo "Error: bob-cli pod not found. Run: make oc-deploy-bob"; exit 1; fi; \
	oc exec $$BOB_POD -- bob -p "$(PROMPT)" --hide-intermediary-output

# ── Testing ──────────────────────────────────────────────

test: ## Run unit tests locally
	cd order-service && mvn test

lint: ## Run checkstyle locally
	cd order-service && mvn checkstyle:check

pci-check: ## Run PCI compliance check locally
	cd order-service && mvn checkstyle:check -Dcheckstyle.config.location=../pipeline/pci-checkstyle.xml

smoke-test: ## Run smoke tests (from inside cluster)
	@BOB_POD=$$(oc get pods -l component=bob-cli -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	oc exec $$BOB_POD -- bash -c "$$(cat pipeline/smoke-test.sh)"

# ── Demo Branches ────────────────────────────────────────

demo-branches: ## Create demo branches for pipeline scenarios
	@echo "See DEMO.md for instructions on creating demo branches."
	@echo "This must be done manually to introduce specific, targeted changes."
```

---

## Notes for Implementation

- The `jenkins-setup.sh` should be copied from the existing project and modified as described above. It's the most complex script and has proven patterns for auth detection, CSRF handling, plugin installation, and job creation.
- The `bob-cli-setup.sh` and `bob-cli-teardown.sh` are identical to the existing project — copy them directly.
- The ArgoCD setup uses the OpenShift GitOps Operator, which is Red Hat's supported ArgoCD distribution. It installs cluster-wide but the Application CR is scoped to our namespace.
- The `IMAGE_PLACEHOLDER` in the deployment YAML gets replaced by `setup.sh` with the actual internal registry path. This is the same pattern the existing project uses.
- The Makefile follows the same conventions as the existing project (`oc-deploy-*`, `oc-teardown-*` naming pattern).
