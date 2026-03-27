# Jenkins Setup Guide

This guide adds Jenkins CI/CD to your OpenShift deployment. It gives the Pipeline page a real Jenkins backend so you can demo AI-augmented pipelines with live builds instead of mock data.

**Time required:** ~10 minutes (after the app is already deployed)

**Prerequisite:** Complete [OPENSHIFT_SETUP.md](OPENSHIFT_SETUP.md) first — all services must be running on the cluster before setting up Jenkins.

---

## What You'll Need

Before starting, gather these two things:

| Secret | Where to Get It |
|---|---|
| **GitHub Enterprise PAT** | [github.ibm.com/settings/tokens](https://github.ibm.com/settings/tokens) — create a token with `repo` scope |
| **Bob Shell API Key** | Same key from your `.env` file (you already have this from the OpenShift setup) |

---

## Step 1: Deploy Jenkins + Create Pipeline Job

One command does everything — deploys Jenkins, installs plugins, configures credentials, and creates the pipeline job:

```bash
make oc-deploy-jenkins
```

The script will prompt you for your GitHub PAT and Bob API key. Or pass them as environment variables to skip the prompts:

```bash
GITHUB_PAT=ghp_xxx BOB_API_KEY=sk-xxx make oc-deploy-jenkins
```

**What this does automatically:**

1. Deploys Jenkins on OpenShift with 2Gi memory and 5Gi persistent storage
2. Waits for Jenkins to fully start (2-5 minutes)
3. Installs required plugins (Pipeline, Git, GitHub, Credentials)
4. Creates two credentials in Jenkins (`github-pat` and `bobshell-api-key`)
5. Creates the `dental-pipeline` job pointing to the `Jenkinsfile` in this repo
6. Patches the frontend to run as the `jenkins` service account — this auto-mounts a fresh, auto-rotating SA token so the Pipeline page can trigger builds without storing a static token
7. Sets `JENKINS_URL` and `JENKINS_AUTH_MODE` on the frontend deployment

**First time opening Jenkins UI:** When you visit the Jenkins URL, OpenShift will show a permissions consent screen asking Jenkins to access `user:info` and `user:check-access`. Click **"Allow selected permissions"** — this is standard OpenShift OAuth and lets Jenkins authenticate you as your cluster user. It's a one-time prompt per user.

When the setup script finishes, it prints the Jenkins URL:

```
========================================
  Jenkins setup complete!
========================================

Jenkins UI:     https://jenkins-dental-claims.apps.your-cluster.cloud.ibm.com
Pipeline job:   https://jenkins-dental-claims.apps.your-cluster.cloud.ibm.com/job/dental-pipeline/
```

---

## Step 2: Test It

### From Jenkins UI

1. Open the Jenkins URL from Step 1 in your browser
2. Click on **dental-pipeline**
3. Click **"Build with Parameters"** on the left sidebar
4. Leave BRANCH as `demo/happy-path` (or change to another demo branch)
5. Click **Build**

Watch the build progress in Jenkins. If you have the app's Pipeline page open with the toggle set to **Live**, events will stream in real-time.

### From the App

1. Open your app (`oc get route frontend -o jsonpath='{.spec.host}'`)
2. Go to the **Pipeline** page
3. Flip the toggle in the top-right from **Mock** to **Live**
4. Select a scenario and click **Run Pipeline**
5. Watch the stages animate and the terminal fill with real build output

> **Note:** If you haven't created the demo branches yet (Step 4), use Mock mode. The Live toggle triggers real Jenkins builds that need the branches to exist on GitHub.

---

## Step 3: Create Demo Branches (Optional)

The pipeline uses different Git branches to demonstrate different failure scenarios. Each branch is forked from `main` with one targeted change:

| Branch | What's Different | Pipeline Outcome |
|---|---|---|
| `demo/happy-path` | Minor change (comment, version bump) | All stages pass, Bob approves |
| `demo/test-failure` | Bug in ClaimService.java — missing null check | Test fails, Bob identifies fix |
| `demo/security-vuln` | Old base image in Dockerfile | Security scan finds CVEs, Bob analyzes |
| `demo/db-migration` | SQL migration adds column that already exists | Deploy fails, Bob fixes migration |

Create them from `main` after merging any pending PRs:

```bash
# Start from main
git checkout main
git pull

# Happy path — minor change so there's a diff for Bob to review
git checkout -b demo/happy-path
# Make a small change (add a comment, bump a version, etc.)
git commit -am "minor: add coverage notes to README"
git push origin demo/happy-path

# Test failure — remove null check in ClaimService
git checkout main
git checkout -b demo/test-failure
# Edit claims/service/src/.../service/ClaimService.java
# Remove the null check in validatePatient() so patient.getId() throws NPE
git commit -am "refactor: simplify patient validation"
git push origin demo/test-failure

# Security vulnerability — use old base image
git checkout main
git checkout -b demo/security-vuln
# Edit claims/service/Dockerfile — change base image to eclipse-temurin:17.0.8-jre-alpine
git commit -am "chore: pin base image version"
git push origin demo/security-vuln

# DB migration failure — add column that already exists
git checkout main
git checkout -b demo/db-migration
# Create claims/database/V4__add_coverage_type.sql with:
#   ALTER TABLE claims ADD COLUMN coverage_type VARCHAR(50);
# (without IF NOT EXISTS — this is the bug)
git commit -am "feat: add coverage type to claims"
git push origin demo/db-migration
```

---

## Verify Everything Works

Quick checklist:

```bash
# Jenkins is running
oc get pods | grep jenkins

# Pipeline job exists
curl -sk "https://$(oc get route jenkins -o jsonpath='{.spec.host}')/job/dental-pipeline/api/json" | python3 -c "import sys,json; print(json.load(sys.stdin)['displayName'])"

# Frontend uses the jenkins service account (auto-rotating token)
oc get deployment/frontend -o jsonpath='{.spec.template.spec.serviceAccountName}'
```

---

## Day-to-Day Commands

```bash
# Deploy/update Jenkins
make oc-deploy-jenkins

# Remove Jenkins from the cluster
make oc-teardown-jenkins

# View Jenkins logs
oc logs dc/jenkins -f

# Restart Jenkins
oc rollout restart dc/jenkins

# Trigger a build from the command line
oc get route jenkins -o jsonpath='{.spec.host}' | xargs -I{} \
  curl -sk -X POST "https://{}/job/dental-pipeline/buildWithParameters?BRANCH=demo/happy-path" \
  -H "Authorization: Basic $(echo -n admin:<your-token> | base64)"
```

---

## Troubleshooting

### Jenkins pod stuck in `Pending`
The cluster may not have enough resources. Check:
```bash
oc describe pod -l name=jenkins
```
Look for "Insufficient cpu" or "Insufficient memory" in the Events section. You may need to scale down other deployments or use a larger TechZone flavor.

### "JENKINS_TOKEN not configured and no SA token mounted" error in the app
The frontend pod isn't running as the `jenkins` service account. Re-run Jenkins setup to patch it:
```bash
make oc-deploy-jenkins
```
Or patch it manually:
```bash
oc patch deployment/frontend --type=json \
  -p '[{"op":"add","path":"/spec/template/spec/serviceAccountName","value":"jenkins"}]'
```

### Pipeline triggers but no events appear in the app
Jenkins events are sent to `http://frontend:3000/api/ai-ops/events` (cluster-internal). Check:
1. Jenkins can reach the frontend service: `oc exec dc/jenkins -- curl -s http://frontend:3000/health`
2. The `FRONTEND_URL` in the Jenkinsfile matches the frontend service name

### GitHub clone fails with SSL error
`github.ibm.com` uses IBM's internal CA. In Jenkins UI:
1. Go to **Manage Jenkins** → **Global Tool Configuration** → **Git**
2. Add extra git option: `-c http.sslVerify=false`

Or set it cluster-wide for the Jenkins pod:
```bash
oc set env dc/jenkins GIT_SSL_NO_VERIFY=true
```

---

## Switching to a New TechZone Environment

When your TechZone reservation expires and you get a new one, re-run the base setup first, then Jenkins:

```bash
# Steps 3-7 from OPENSHIFT_SETUP.md
oc login --username=<new-user> --password=<new-password> --server=<new-api-url>
oc new-project dental-claims
# ... enable registry (Steps 5a, 5b) ...
make oc-deploy

# Then re-deploy Jenkins
make oc-deploy-jenkins
```

Your demo branches on GitHub Enterprise persist across environments — no need to recreate them.
