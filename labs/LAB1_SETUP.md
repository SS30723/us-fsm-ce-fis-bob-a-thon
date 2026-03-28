# Lab 1: Verify Your Environment

**Prerequisite:** Complete [SETUP.md](../SETUP.md) first — you should have the app, ArgoCD, and Jenkins deployed before starting this lab.

**Time:** ~10 minutes

---

## 1.1 — Verify the application

```bash
# Pods are running
oc get pods
# Expected: order-db (Running), order-service (Running)

# Health check responds
curl http://$(oc get route order-service -o jsonpath='{.spec.host}')/api/orders/health
# Expected: {"status":"UP","service":"order-service"}

# Create a test order
curl -X POST http://$(oc get route order-service -o jsonpath='{.spec.host}')/api/orders \
  -H "Content-Type: application/json" \
  -d '{"customerName":"lab-test","product":"widget","amount":9.99,"status":"PENDING"}'
# Expected: JSON with an id
```

> **Checkpoint:** All three commands above should succeed before continuing.

---

## 1.2 — Verify Jenkins

```bash
# Jenkins pod is running
oc get pods | grep jenkins
# Expected: jenkins pod in Running/Ready state

# Get the Jenkins URL
JENKINS_URL=$(oc get route jenkins -o jsonpath='{.spec.host}')
echo "Open in browser: https://$JENKINS_URL"
```

Open the Jenkins URL in your browser. OpenShift will show a permissions consent screen — click **"Allow selected permissions"**.

Navigate to **sre-pipeline** and click **Build with Parameters**. Leave BRANCH as `main` and click **Build**. The pipeline should run all stages — Checkout, Lint, PCI Compliance, Test, Security Scan, Approval, Build Image, Deploy via ArgoCD, Smoke Tests. No Bob calls yet.

> **Checkpoint:** Jenkins UI is accessible and the pipeline runs end-to-end.

---

## 1.3 — Deploy Bob CLI

Bob CLI runs as a pod on the cluster. Deploy it now — you'll use it in Lab 2:

```bash
make oc-deploy-bob
```

Verify it's running:

```bash
# Pod is running
oc get pods -l component=bob-cli
# Expected: bob-cli pod in Running state

# Bob can respond
make oc-bob PROMPT="Say hello in one sentence"
# Expected: Bob responds with a greeting
```

> **Checkpoint:** Bob responds to prompts.

---

## What you have now

| Component | Status |
|-----------|--------|
| order-service + PostgreSQL | Running on cluster |
| ArgoCD | Watching k8s manifests |
| Jenkins + sre-pipeline job | Running, pipeline passes |
| Bob CLI pod | Running, responds to prompts |
| Jenkinsfile | Baseline pipeline (no Bob) — see `labs/Jenkinsfile.solution` for the completed version |

You're ready for **Lab 2: Integrating Bob into Your Pipeline**.
