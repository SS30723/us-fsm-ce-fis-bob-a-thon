# Setup Guide

This guide walks you through deploying the SRE Deploy Lab to an OpenShift cluster. The lab showcases how IBM Bob integrates into a Jenkins CI/CD pipeline for the SRE use case, using a sample Order Service as the application under deployment.

**Time required:** ~20 minutes for the app (plus ~10 minutes for image builds), ~10 more minutes if adding Jenkins

---

## Step 0: Fork and clone the repo

Fork this repo to your own GitHub account, then clone your fork:

```bash
git clone https://github.ibm.com/<your-username>/sre-project
cd sre-project
```

Copy the example environment file and fill in your values:

```bash
cp .env.example .env
```

Edit `.env` and set:
- `GITHUB_REPO_URL` — your fork URL (e.g., `https://github.ibm.com/<your-username>/sre-project`)
- `GITHUB_PAT` — a GitHub Enterprise personal access token with `repo` scope only ([create one here](https://github.ibm.com/settings/tokens))
- `BOBSHELL_API_KEY` — your Bob Shell API key (check Slack for your welcome message from Ask Bob)

The deploy scripts read these values automatically.

> **Important:** Never commit `.env` to git. It is already in `.gitignore`.

---

## Prerequisites

Install these tools first (macOS):

```bash
xcode-select --install          # gives you git, make, and curl
brew install openshift-cli      # the oc CLI
brew install podman             # builds container images locally
```

Start the Podman machine (one-time setup):

```bash
podman machine init
podman machine start
```

---

## Step 1: Reserve a TechZone Environment

Go to the [Base OpenShift TechZone collection](https://techzone.ibm.com/collection/695ee737853c17e9e412046e/journey-base-open-shift) and select **"OCP-V on IBM Cloud"** to reserve your environment.

When configuring the reservation, select the **16 vCPU / 64 GB RAM** worker node flavor with **100 GB** ephemeral storage. This is the minimum size that comfortably runs all services — smaller flavors run out of CPU for scheduling.

Once your reservation is ready (usually 15-30 minutes), you'll receive credentials on the reservation page:

| Credential | What It's For |
|---|---|
| **API URL** | Used for `oc login` (e.g., `https://api.your-cluster.cloud.ibm.com:6443`) |
| **Cluster admin username** | Login username (e.g., `kubeadmin`) |
| **Cluster admin password** | Login password |
| **OCP Console URL** | Web UI for browsing the cluster (optional) |

Keep this page open — you'll need these values in Step 3.

### What You Get

- OpenShift 4.18 cluster with up to 7 worker nodes (16 vCPU / 64 GB RAM each)
- Public ingress (your app will be accessible via HTTPS)
- A built-in container image registry (no Docker Hub or external registry needed)

---

## Step 2: Install the OpenShift CLI

The `oc` command-line tool is how you interact with the cluster from your terminal.

**macOS (Homebrew):**
```bash
brew install openshift-cli
```

**Other platforms:**
Download from the OCP Console (your TechZone reservation provides the URL) — click the **?** icon in the top-right → **Command Line Tools**.

**Verify it installed:**
```bash
oc version
```

---

## Step 3: Log In to Your Cluster

Use the credentials from your TechZone reservation page:

```bash
oc login --username=<cluster-admin-username> --password=<password> --server=<api-url>
```

Example:
```bash
oc login --username=kubeadmin --password=abc123-XYZ --server=https://api.my-cluster.cloud.ibm.com:6443
```

You may see a certificate warning — type `y` to accept (TechZone clusters use self-signed certs).

> **Tip:** Save your full `oc login` command somewhere handy (e.g., a sticky note or text file). OpenShift tokens expire after a period of inactivity and you'll need to re-authenticate. Having the command ready makes it quick to get back in.

**Verify you're connected:**
```bash
oc whoami        # Should print your username
oc get nodes     # Should list the cluster's worker nodes
```

---

## Step 4: Create a Project (Namespace)

A project is a logical space on the cluster that holds all your app's resources.

```bash
oc new-project sre-deploy-lab
```

---

## Step 5: Enable the Internal Image Registry

OpenShift has a built-in container image registry. On TechZone UPI clusters, it starts disabled. You need to turn it on so the deploy scripts can build images on the cluster.

Check if the registry is already running:
```bash
oc get configs.imageregistry.operator.openshift.io/cluster -o jsonpath='{.spec.managementState}'
```

- If the output is **`Managed`** — skip to Step 6.
- If the output is **`Removed`** — deploy it:

```bash
oc patch configs.imageregistry.operator.openshift.io/cluster --type merge \
  --patch '{"spec":{"managementState":"Managed","storage":{"emptyDir":{}}}}'
```

Wait for the registry pod to start:
```bash
oc get pods -n openshift-image-registry -w
```

Press `Ctrl+C` once you see `image-registry-xxxxx` at `1/1 Running`.

> **Note:** `emptyDir` storage means images are lost if the registry pod restarts. This is fine for labs — just re-run `make oc-deploy` if it happens.

---

## Step 6: Deploy the Application

```bash
make oc-deploy
```

That's it. The script handles everything automatically:

1. Verifies you're logged in and in the right project
2. Gets the registry hostname from the cluster
3. Creates a service account token and logs into the registry
4. Builds container images with `podman build --platform linux/amd64` (safe on Apple Silicon and Intel Macs)
5. Pushes the images to the internal registry
6. Applies security context constraints (so database containers can run)
7. Applies all Kubernetes manifests (dynamically rewrites image references)
8. Builds and deploys the Bob CLI pod with your API key
9. Prints the app URL

**Build times:** Expect ~10 minutes on the first run (downloading base images + cross-compilation on Apple Silicon). Subsequent runs are faster thanks to layer caching.

Once you see `Deployment complete!`, wait for all pods to be ready:

```bash
oc get pods -w
```

Watch until every pod shows `1/1` under the `READY` column. This may take 1-2 minutes as the databases initialize and the services start. Press `Ctrl+C` once they're all ready.

---

## Step 7: Verify the Deployment

**Check pod status:**
```bash
oc get pods
```

All pods should show `Running` with `1/1` ready. It may take 1-2 minutes for all pods to start.

---

## Step 8: Deploy ArgoCD

ArgoCD watches your Git repo and syncs the k8s manifests to the cluster. The pipeline uses it for deployments.

```bash
make oc-deploy-argocd
```

This installs the OpenShift GitOps operator, grants it access to your namespace, and creates an Application CR pointing at the `k8s/` directory in this repo.

When it finishes, it prints the ArgoCD UI URL. Log in with username `admin` and the password from:

```bash
oc extract secret/openshift-gitops-cluster -n openshift-gitops --to=-
```

---

## Step 9: Deploy Bob CLI

Bob CLI runs as a pod on the cluster. The labs use it to add AI-assisted analysis to the pipeline.

```bash
make oc-deploy-bob
```

Verify it's running:

```bash
oc get pods -l component=bob-cli
make oc-bob PROMPT="Say hello in one sentence"
```

---

## Step 10: Deploy Jenkins

This section adds Jenkins CI/CD to your OpenShift deployment so you can run the lab scenarios with a live SRE pipeline — PR analysis, PCI compliance checks, risk assessment, and automated change control.

**Prerequisite:** Complete Steps 1-9 above first (app, ArgoCD, and Bob CLI deployed).

### What You'll Need

You'll need a **GitHub Enterprise PAT** — create one at [github.ibm.com/settings/tokens](https://github.ibm.com/settings/tokens) with `repo` scope.

### Deploy Jenkins + Create Pipeline Job

One command does everything — deploys Jenkins, installs plugins, configures credentials, and creates the pipeline job:

```bash
make oc-deploy-jenkins
```

The script will prompt you for your GitHub PAT. Or pass it as an environment variable to skip the prompt:

```bash
GITHUB_PAT=ghp_xxx make oc-deploy-jenkins
```

**What this does automatically:**

1. Deploys Jenkins on OpenShift with 2Gi memory and 5Gi persistent storage
2. Waits for Jenkins to fully start (2-5 minutes)
3. Installs required plugins (Pipeline, Git, GitHub, Credentials)
4. Creates the `github-pat` credential in Jenkins
5. Creates the `sre-pipeline` job pointing to the `Jenkinsfile` in this repo

**First time opening Jenkins UI:** Log in with your TechZone cluster credentials (the same username and password you used for `oc login`). OpenShift will then show a permissions consent screen asking Jenkins to access `user:info` and `user:check-access`. Click **"Allow selected permissions"** — this is a one-time prompt per user.

When the setup script finishes, it prints the Jenkins URL:

```
========================================
  Jenkins setup complete!
========================================

Jenkins UI:     https://jenkins-sre-deploy-lab.apps.your-cluster.cloud.ibm.com
Pipeline job:   https://jenkins-sre-deploy-lab.apps.your-cluster.cloud.ibm.com/job/sre-pipeline/
```

### Test It

#### From Jenkins UI

1. Open the Jenkins URL printed by the setup script
2. Click on **sre-pipeline**
3. Click **"Build with Parameters"** on the left sidebar
4. Leave BRANCH as `main`
5. Click **Build**

---

## Troubleshooting

### Pods stuck in `ImagePullBackOff`
The registry may have lost its images (emptyDir storage). Re-run:
```bash
make oc-deploy
```

### Database pods stuck in `CrashLoopBackOff`
The security context constraint (SCC) patch may not have applied. Check:
```bash
oc get clusterrolebinding sre-deploy-lab-anyuid
```
If it doesn't exist, the script should have created it. Try re-running `make oc-deploy`.

### Pods crash with `exec format error`
Images were built for the wrong CPU architecture. The deploy script uses `--platform linux/amd64` to handle this automatically. If you see this error, make sure you're using the `setup.sh` script (via `make oc-deploy`) and not building images manually.

### `oc login` fails with connection errors
- Double-check the API URL from your TechZone reservation page
- Make sure you're on a network that can reach IBM Cloud (some corporate VPNs may block it)
- If your reservation expired, request a new one

### Order Service not responding
The service or database may still be starting. Wait a minute and check:
```bash
oc logs deployment/order-service --tail=20
```

### Jenkins pod stuck in `Pending`
The cluster may not have enough resources. Check:
```bash
oc describe pod -l name=jenkins
```
Look for "Insufficient cpu" or "Insufficient memory" in the Events section. You may need to scale down other deployments or use a larger TechZone flavor.

### GitHub clone fails with SSL error
`github.ibm.com` uses IBM's internal CA. In Jenkins UI:
1. Go to **Manage Jenkins** → **Global Tool Configuration** → **Git**
2. Add extra git option: `-c http.sslVerify=false`

Or set it cluster-wide for the Jenkins pod:
```bash
oc set env dc/jenkins GIT_SSL_NO_VERIFY=true
```

---

## Day-to-Day Commands

```bash
# Deploy everything (app + ArgoCD + Bob + Jenkins)
make setup

# Remove everything from the cluster
make teardown

# Redeploy the app only
make oc-deploy

# Redeploy just the order-service
make oc-redeploy

# View logs
oc logs deployment/order-service -f

# Check pod status
oc get pods

# Deploy/update Jenkins
make oc-deploy-jenkins

# Remove Jenkins from the cluster
make oc-teardown-jenkins

# View Jenkins logs
oc logs dc/jenkins -f

# Restart Jenkins
oc rollout restart dc/jenkins

# Deploy/remove ArgoCD
make oc-deploy-argocd
make oc-teardown-argocd

# Deploy/remove Bob CLI
make oc-deploy-bob
make oc-teardown-bob

# Ask Bob a question on the cluster
make oc-bob PROMPT="check the order-service deployment health"

# Run tests locally
make test
make lint
make pci-check
```

---

## Switching to a New TechZone Environment

When your TechZone reservation expires and you get a new one, just repeat Steps 3-6 (your `.env` file is already in place):

```bash
oc login --username=<new-user> --password=<new-password> --server=<new-api-url>
oc new-project sre-deploy-lab

# Enable registry (Step 5)
oc patch configs.imageregistry.operator.openshift.io/cluster --type merge \
  --patch '{"spec":{"managementState":"Managed","storage":{"emptyDir":{}}}}'
# Wait for registry pod...

# Deploy
make oc-deploy

# Then re-deploy Jenkins (if using it)
make oc-deploy-jenkins
```

No code changes needed. The deploy script detects everything from the cluster automatically. Your lab branches on GitHub Enterprise persist across environments — no need to recreate them.
