# OpenShift Setup Guide

This guide walks you through deploying the Dental Claims application to an OpenShift cluster from scratch. It assumes you have no prior OpenShift experience.

**Time required:** ~20 minutes (plus ~10 minutes for image builds)

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
oc new-project dental-claims
```

---

## Step 5: Enable the Internal Image Registry

OpenShift has a built-in container image registry. On TechZone UPI clusters, it starts disabled. You need to turn it on so the deploy script can push your images.

### 5a: Deploy the Registry

Check if the registry is already running:
```bash
oc get configs.imageregistry.operator.openshift.io/cluster -o jsonpath='{.spec.managementState}'
```

- If the output is **`Managed`** — skip to Step 5b.
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

> **Note:** `emptyDir` storage means images are lost if the registry pod restarts. This is fine for demos — just re-run `make oc-deploy` if it happens.

### 5b: Expose the Registry Route

This creates a public hostname so you can push images from your laptop:

```bash
oc patch configs.imageregistry.operator.openshift.io/cluster --type merge \
  --patch '{"spec":{"defaultRoute":true}}'
```

Verify the route was created:
```bash
oc get route default-route -n openshift-image-registry
```

You should see a hostname like `default-route-openshift-image-registry.apps.your-cluster.cloud.ibm.com`.

---

## Step 6: Add Your Bob Shell API Key

Bob CLI runs inside the cluster and provides AI-assisted operations (diagnosing failures, fixing configurations, recovering deployments). You need a Bob Shell API key before deploying.

Check your Slack history for a welcome message from Ask Bob that includes your key. Then create a `.env` file in the project root:

```
BOBSHELL_API_KEY=your-key-here
```

The deploy script reads this file on your machine, creates a Kubernetes Secret on the cluster, and the Bob CLI pod picks up the key from that Secret. The `.env` file stays on your machine — it is not copied into any container.

> **Important:** Never commit the `.env` file to git. It is already in `.gitignore`.

---

## Step 7: Deploy the Application

```bash
make oc-deploy
```

That's it. The script handles everything automatically:

1. Verifies you're logged in and in the right project
2. Gets the registry hostname from the cluster
3. Creates a service account token and logs into the registry
4. Builds all 5 container images with `podman build --platform linux/amd64` (safe on Apple Silicon and Intel Macs)
5. Pushes the images to the internal registry
6. Applies security context constraints (so database containers can run)
7. Creates ConfigMaps for database initialization scripts
8. Applies all Kubernetes manifests (dynamically rewrites image references)
9. Applies the frontend Route for public HTTPS access
10. Builds and deploys the Bob CLI pod with your API key
11. Prints the app URL

**Build times:** Expect ~10 minutes on the first run (downloading base images + cross-compilation on Apple Silicon). Subsequent runs are faster thanks to layer caching.

Once you see `Deployment complete!`, wait for all pods to be ready:

```bash
oc get pods -w
```

Watch until every pod shows `1/1` under the `READY` column. This may take 1-2 minutes as the databases initialize and the services start. Press `Ctrl+C` once they're all ready.

---

## Step 8: Verify the Deployment

**Get your app URL:**
```bash
oc get route frontend -o jsonpath='{.spec.host}'
```

Open `https://<that-host>` in your browser. You should see the Dental Claims frontend.

**Check pod status:**
```bash
oc get pods
```

All pods should show `Running` with `1/1` ready. It may take 1-2 minutes for all pods to start.

---

## Architecture Notes

### Frontend Runs as a Single Replica

The frontend deployment is set to `replicas: 1`. This is intentional — the AI Operations terminal uses Server-Sent Events (SSE) with an in-memory event bus. Multiple replicas would cause events from the bob-cli pod to land on different frontend pods than the user's browser SSE connection, resulting in missing terminal events.

### SSE Route Timeout

The frontend route includes a `haproxy.router.openshift.io/timeout: 300s` annotation. Bob CLI can take 60-90 seconds to analyze and respond to issues. Without this annotation, HAProxy's default 30-second timeout kills the SSE connection mid-operation, causing missed events.

If you manually create the route instead of using `oc apply -f k8s/openshift/frontend-route.yaml`, add the annotation:

```bash
oc annotate route frontend haproxy.router.openshift.io/timeout=300s
```

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
oc get clusterrolebinding dental-claims-anyuid
```
If it doesn't exist, the script should have created it. Try re-running `make oc-deploy`.

### Pods crash with `exec format error`
Images were built for the wrong CPU architecture. The deploy script uses `--platform linux/amd64` to handle this automatically. If you see this error, make sure you're using the `setup.sh` script (via `make oc-deploy`) and not building images manually.

### `oc login` fails with connection errors
- Double-check the API URL from your TechZone reservation page
- Make sure you're on a network that can reach IBM Cloud (some corporate VPNs may block it)
- If your reservation expired, request a new one

### Frontend loads but shows no data
The backend services or databases may still be starting. Wait a minute and refresh. Check:
```bash
oc logs deployment/claims-service --tail=20
```

---

## Day-to-Day Commands

```bash
# Redeploy everything (rebuild all images + apply manifests)
make oc-deploy

# Redeploy a single service (faster — only rebuilds one image)
make oc-redeploy-claims
make oc-redeploy-patients
make oc-redeploy-providers
make oc-redeploy-analytics
make oc-redeploy-frontend

# View logs
oc logs deployment/claims-service -f
oc logs deployment/frontend -f

# Check pod status
oc get pods

# Remove everything from the cluster
make oc-teardown
```

---

## Switching to a New TechZone Environment

When your TechZone reservation expires and you get a new one, just repeat Steps 3-5 and 7 (your `.env` file is already in place):

```bash
oc login --username=<new-user> --password=<new-password> --server=<new-api-url>
oc new-project dental-claims

# Enable registry (Steps 5a and 5b)
oc patch configs.imageregistry.operator.openshift.io/cluster --type merge \
  --patch '{"spec":{"managementState":"Managed","storage":{"emptyDir":{}}}}'
# Wait for registry pod...
oc patch configs.imageregistry.operator.openshift.io/cluster --type merge \
  --patch '{"spec":{"defaultRoute":true}}'

# Deploy
make oc-deploy
```

No code changes needed. The deploy script detects everything from the cluster automatically.

---

## Next: Add Jenkins CI/CD (Optional)

If you want to demo the live CI/CD Pipeline page (instead of mock mode), see **[JENKINS_SETUP.md](JENKINS_SETUP.md)**. It takes ~10 minutes on top of this setup and gives you a real Jenkins instance with AI-augmented pipelines.
