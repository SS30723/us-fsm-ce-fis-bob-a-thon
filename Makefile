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
