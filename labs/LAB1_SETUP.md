# Lab 1: Verify Your Environment

**Prerequisite:** Complete [SETUP.md](../SETUP.md) first — you should have the app, Bob CLI, and Jenkins deployed before starting this lab.

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

## 1.2 — Verify Bob CLI

```bash
# Pod is running
oc get pods -l component=bob-cli
# Expected: bob-cli pod in Running state

# Bob can respond
make oc-bob PROMPT="Say hello in one sentence"
# Expected: Bob responds with a greeting
```

> **Checkpoint:** Bob responds to prompts before continuing.

---

## 1.3 — Verify Jenkins

```bash
# Jenkins pod is running
oc get pods | grep jenkins
# Expected: jenkins pod in Running/Ready state

# Get the Jenkins URL
JENKINS_URL=$(oc get route jenkins -o jsonpath='{.spec.host}')
echo "Open in browser: https://$JENKINS_URL"
```

Open the Jenkins URL in your browser. OpenShift will show a permissions consent screen — click **"Allow selected permissions"**.

Navigate to **sre-pipeline** and click **Build with Parameters**. Set BRANCH to `main` and click **Build**. The build will run but some stages may fail (no lab branches yet) — that's OK. The point is to verify Jenkins can start a build.

> **Checkpoint:** Jenkins UI is accessible and a build starts.

---

## 1.4 — Install the starter pipeline

For Lab 2 you will start from a pipeline that has **no Bob integration**. Copy the starter Jenkinsfile into place:

```bash
cp labs/Jenkinsfile.starter Jenkinsfile
```

Commit and push this to a working branch:

```bash
git checkout -b lab/my-pipeline
git add Jenkinsfile
git commit -m "lab: start with baseline pipeline (no Bob)"
git push origin lab/my-pipeline
```

Run a build in Jenkins with `BRANCH=lab/my-pipeline` to confirm the baseline pipeline works end-to-end.

> **Checkpoint:** The starter pipeline runs all 8 stages — Checkout, Lint, PCI Compliance, Test, Security Scan, Approval, Deploy, Smoke Tests. No Bob calls yet.

---

## What you have now

| Component | Status |
|-----------|--------|
| order-service + PostgreSQL | Running on cluster |
| Bob CLI pod | Running, responds to prompts |
| Jenkins + sre-pipeline job | Running, builds trigger |
| Starter Jenkinsfile | Committed to `lab/my-pipeline` |

You're ready for **Lab 2: Integrating Bob into Your Pipeline**.
