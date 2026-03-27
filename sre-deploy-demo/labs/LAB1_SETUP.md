# Lab 1: Environment Setup

In this lab you will deploy the order-service application, Bob CLI, and Jenkins to an OpenShift cluster. By the end you will have a working pipeline that you can extend with Bob AI in Lab 2.

**Time:** ~30 minutes
**Prerequisites:** OpenShift cluster (TechZone), `oc` CLI, `podman`, a GitHub Enterprise PAT, and a Bob Shell API key.

---

## 1.1 — Log in to the cluster

Get your credentials from the TechZone reservation page, then:

```bash
oc login --username=<user> --password=<pass> --server=<api-url>
```

Accept the certificate warning if prompted. Verify you're connected:

```bash
oc whoami
oc get nodes
```

---

## 1.2 — Create a project

```bash
oc new-project sre-deploy-demo
```

---

## 1.3 — Enable the internal image registry

OpenShift has a built-in container registry. On TechZone clusters it starts disabled.

```bash
# Check current state
oc get configs.imageregistry.operator.openshift.io/cluster \
  -o jsonpath='{.spec.managementState}'
```

If the output is `Removed`, enable it:

```bash
oc patch configs.imageregistry.operator.openshift.io/cluster --type merge \
  --patch '{"spec":{"managementState":"Managed","storage":{"emptyDir":{}}}}'
```

Wait for the registry pod to start (press Ctrl+C once it shows `1/1 Running`):

```bash
oc get pods -n openshift-image-registry -w
```

Then expose the registry route:

```bash
oc patch configs.imageregistry.operator.openshift.io/cluster --type merge \
  --patch '{"spec":{"defaultRoute":true}}'
```

---

## 1.4 — Create your .env file

Create a `.env` file in the project root with your Bob Shell API key:

```bash
echo "BOBSHELL_API_KEY=your-key-here" > .env
```

> The deploy scripts read this file on your machine and create a Kubernetes Secret on the cluster. The `.env` file never leaves your machine.

---

## 1.5 — Deploy the application

```bash
make oc-deploy
```

This builds the order-service container image, deploys PostgreSQL and the Spring Boot app, and creates a route.

**Verify it worked:**

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

## 1.6 — Deploy Bob CLI

```bash
make oc-deploy-bob
```

This builds a container image with the Bob CLI tool, pushes it to the cluster registry, creates a Secret with your API key, and starts the pod.

**Verify it worked:**

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

## 1.7 — Deploy Jenkins

You'll need your GitHub Enterprise PAT. Pass it as an environment variable (or the script will prompt you):

```bash
GITHUB_PAT=ghp_xxx make oc-deploy-jenkins
```

This deploys Jenkins, builds a custom agent image (with Maven, Trivy, oc), installs plugins, creates credentials, and creates the `sre-pipeline` job.

**Verify it worked:**

```bash
# Jenkins pod is running
oc get pods | grep jenkins
# Expected: jenkins pod in Running/Ready state

# Get the Jenkins URL
JENKINS_URL=$(oc get route jenkins -o jsonpath='{.spec.host}')
echo "Open in browser: https://$JENKINS_URL"
```

Open the Jenkins URL in your browser. OpenShift will show a permissions consent screen — click **"Allow selected permissions"**.

Navigate to **sre-pipeline** and click **Build with Parameters**. Set BRANCH to `main` and click **Build**. The build will run but some stages may fail (no demo branches yet) — that's OK. The point is to verify Jenkins can start a build.

> **Checkpoint:** Jenkins UI is accessible and a build starts.

---

## 1.8 — Install the starter pipeline

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
