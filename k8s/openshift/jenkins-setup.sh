#!/bin/bash
# Jenkins Setup Script for OpenShift
#
# Deploys Jenkins, installs plugins, configures credentials, and creates the
# sre-pipeline job — all via the Jenkins REST API (no manual UI clicks).
#
# Prerequisites:
# - oc login completed (connected to your OpenShift cluster)
# - The order-service app is already deployed (setup.sh has been run)
#
# Usage:
#   ./jenkins-setup.sh                          # interactive — prompts for secrets
#   GITHUB_PAT=xxx BOB_API_KEY=yyy ./jenkins-setup.sh  # non-interactive

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── Preflight checks ────────────────────────────────────────────────────────

echo "=== Preflight checks ==="

if ! command -v oc &>/dev/null; then
    echo "Error: oc CLI not found. Install with: brew install openshift-cli"
    exit 1
fi

if ! oc whoami &>/dev/null; then
    echo "Error: Not logged into OpenShift. Run: oc login ..."
    exit 1
fi

NAMESPACE=$(oc project -q)
echo "Cluster user:  $(oc whoami)"
echo "Namespace:     $NAMESPACE"

# ── Check if Jenkins is already fully set up ─────────────────────────────────

JENKINS_ALREADY_DEPLOYED=false
if oc get dc/jenkins &>/dev/null 2>&1 || oc get deployment/jenkins &>/dev/null 2>&1; then
    JENKINS_ALREADY_DEPLOYED=true
fi

# ── Load secrets from .env file if available ─────────────────────────────────

if [ -f "$PROJECT_DIR/.env" ]; then
    if [ -z "$GITHUB_PAT" ] && grep -q GITHUB_PAT "$PROJECT_DIR/.env"; then
        export $(grep GITHUB_PAT "$PROJECT_DIR/.env" | xargs)
        echo "Loaded GITHUB_PAT from .env file"
    fi
    if [ -z "$BOB_API_KEY" ] && grep -q BOBSHELL_API_KEY "$PROJECT_DIR/.env"; then
        BOB_API_KEY=$(grep BOBSHELL_API_KEY "$PROJECT_DIR/.env" | cut -d= -f2-)
        echo "Loaded BOB_API_KEY from .env file"
    fi
fi

# ── Collect secrets (skip if Jenkins is already deployed) ────────────────────

if [ "$JENKINS_ALREADY_DEPLOYED" = true ] && [ -z "$GITHUB_PAT" ] && [ -z "$BOB_API_KEY" ]; then
    echo ""
    echo "Jenkins is already deployed — skipping credential prompts."
    echo "  (Pass GITHUB_PAT and BOB_API_KEY env vars to update credentials)"
    SKIP_CREDENTIALS=true
else
    SKIP_CREDENTIALS=false

    if [ -z "$GITHUB_PAT" ]; then
        echo ""
        echo "Enter your GitHub Enterprise PAT (needs 'repo' scope)."
        echo "  Create one at: https://github.ibm.com/settings/tokens"
        read -rsp "GitHub PAT: " GITHUB_PAT
        echo ""
    fi

    if [ -z "$BOB_API_KEY" ]; then
        echo ""
        echo "Enter the Bob CLI API key (same as BOBSHELL_API_KEY in .env)."
        read -rsp "Bob API Key: " BOB_API_KEY
        echo ""
    fi

    if [ -z "$GITHUB_PAT" ] || [ -z "$BOB_API_KEY" ]; then
        echo "Error: Both GITHUB_PAT and BOB_API_KEY are required."
        exit 1
    fi
fi

GITHUB_REPO_URL="${GITHUB_REPO_URL:-https://github.ibm.com/ibm-us-fsm-ce/sre-deploy-lab}"

# ── Step 1: Deploy Jenkins ───────────────────────────────────────────────────

echo ""
echo "=== Step 1: Deploying Jenkins ==="

if oc get dc/jenkins &>/dev/null 2>&1 || oc get deployment/jenkins &>/dev/null 2>&1; then
    echo "Jenkins is already deployed — skipping."
else
    if oc get template jenkins-persistent -n openshift &>/dev/null 2>&1; then
        oc new-app jenkins-persistent \
            --param MEMORY_LIMIT=2Gi \
            --param VOLUME_CAPACITY=5Gi
    else
        echo "jenkins-persistent template not found — using jenkins-ephemeral"
        oc new-app jenkins-ephemeral \
            --param MEMORY_LIMIT=2Gi
    fi
    echo "Jenkins deployment created."
fi

# ── Step 1b: Build custom Jenkins agent image ────────────────────────────────

if [ "${SKIP_AGENT_BUILD:-}" != "true" ]; then
    echo ""
    echo "=== Step 1b: Building custom Jenkins agent image ==="
    "$SCRIPT_DIR/jenkins-agent-build.sh"
else
    echo ""
    echo "=== Step 1b: Skipping agent image build (SKIP_AGENT_BUILD=true) ==="
fi

# ── Wait for Jenkins to be ready ─────────────────────────────────────────────

echo ""
echo "=== Waiting for Jenkins to start (this takes 2-5 minutes) ==="

if oc get dc/jenkins &>/dev/null 2>&1; then
    oc rollout status dc/jenkins --timeout=300s
else
    oc rollout status deployment/jenkins --timeout=300s
fi

JENKINS_ROUTE=$(oc get route jenkins -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
if [ -z "$JENKINS_ROUTE" ]; then
    echo "Warning: No Jenkins route found. Creating one..."
    oc expose svc/jenkins
    JENKINS_ROUTE=$(oc get route jenkins -o jsonpath='{.spec.host}')
fi

JENKINS_URL="https://$JENKINS_ROUTE"
echo "Jenkins is ready at: $JENKINS_URL"

# ── Determine authentication ─────────────────────────────────────────────────

echo ""
echo "=== Determining Jenkins authentication ==="

SA_TOKEN=$(oc whoami -t)
JENKINS_USER="admin"

# Test if Jenkins responds to OAuth token
HTTP_CODE=$(curl -sk -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $SA_TOKEN" \
    "$JENKINS_URL/api/json" 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo "Jenkins is using OpenShift OAuth — authenticating with oc token."
    AUTH_HEADER="Authorization: Bearer $SA_TOKEN"
else
    JENKINS_PASS=$(oc get secret jenkins -o jsonpath='{.data.JENKINS_PASSWORD}' 2>/dev/null | base64 -d 2>/dev/null || echo "")
    if [ -z "$JENKINS_PASS" ]; then
        echo ""
        echo "Could not auto-detect Jenkins password."
        echo "Check the Jenkins pod logs: oc logs dc/jenkins | grep -i password"
        read -rsp "Enter Jenkins admin password: " JENKINS_PASS
        echo ""
    fi
    AUTH_HEADER="Authorization: Basic $(echo -n "${JENKINS_USER}:${JENKINS_PASS}" | base64)"
fi

# Helper: call Jenkins REST API. Automatically includes auth + crumb headers.
CRUMB_ARGS=()

_setup_crumb() {
    # Only run once
    if [ "${_CRUMB_CHECKED:-}" = "1" ]; then return; fi
    _CRUMB_CHECKED=1

    local crumb_json
    crumb_json=$(curl -sk -H "$AUTH_HEADER" "${JENKINS_URL}/crumbIssuer/api/json" 2>/dev/null || echo "")

    if echo "$crumb_json" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d['crumbRequestField'] + ': ' + d['crumb'])
" > /tmp/_jenkins_crumb 2>/dev/null; then
        CRUMB_ARGS=(-H "$(cat /tmp/_jenkins_crumb)")
        echo "CSRF crumb obtained."
    else
        CRUMB_ARGS=()
        echo "No CSRF crumb needed (OpenShift OAuth mode)."
    fi
    rm -f /tmp/_jenkins_crumb
}

jenkins_post() {
    local path="$1"; shift
    _setup_crumb
    curl -sk -X POST -H "$AUTH_HEADER" "${CRUMB_ARGS[@]}" "$@" "${JENKINS_URL}${path}"
}

jenkins_get() {
    local path="$1"; shift
    curl -sk -H "$AUTH_HEADER" "$@" "${JENKINS_URL}${path}"
}

_setup_crumb

# ── Step 2: Install Plugins ─────────────────────────────────────────────────

echo ""
echo "=== Step 2: Installing plugins ==="

PLUGINS=("git" "github" "workflow-aggregator" "credentials" "pipeline-utility-steps" "pipeline-stage-view")

for plugin in "${PLUGINS[@]}"; do
    echo "  Installing: $plugin"
    jenkins_post "/pluginManager/installNecessaryPlugins" \
        -H "Content-Type: text/xml" \
        -d "<jenkins><install plugin=\"${plugin}@latest\" /></jenkins>" \
        > /dev/null 2>&1 || echo "    (may already be installed)"
done

echo "Plugins queued for installation. Jenkins may need a restart."
echo "  (It will auto-restart if needed, or you can visit $JENKINS_URL/restart)"

sleep 5

# ── Step 3: Configure Credentials ───────────────────────────────────────────

if [ "$SKIP_CREDENTIALS" = true ]; then
    echo ""
    echo "=== Step 3: Skipping credentials (already configured) ==="
else
    echo ""
    echo "=== Step 3: Configuring credentials ==="

    # Git SCM needs "Username with password" — username is ignored, password is the PAT
    GITHUB_CRED_XML=$(cat <<CREDEOF
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>github-pat</id>
  <description>GitHub Enterprise PAT</description>
  <username>git</username>
  <password>$GITHUB_PAT</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
CREDEOF
)

    echo "  Adding credential: github-pat (username/password type)"
    # Delete old credential if it exists (may be wrong type from previous run)
    jenkins_post "/credentials/store/system/domain/_/credential/github-pat/doDelete" \
        > /dev/null 2>&1 || true
    jenkins_post "/credentials/store/system/domain/_/createCredentials" \
        -H "Content-Type: application/xml" \
        -d "$GITHUB_CRED_XML" \
        > /dev/null 2>&1 || echo "    (may already exist)"

    BOB_CRED_XML=$(cat <<CREDEOF
<org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>bobshell-api-key</id>
  <description>Bob CLI API Key</description>
  <secret>$BOB_API_KEY</secret>
</org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
CREDEOF
)

    echo "  Adding credential: bobshell-api-key"
    jenkins_post "/credentials/store/system/domain/_/createCredentials" \
        -H "Content-Type: application/xml" \
        -d "$BOB_CRED_XML" \
        > /dev/null 2>&1 || echo "    (may already exist)"
fi

# ── Step 4: Create the Pipeline Job ─────────────────────────────────────────

echo ""
echo "=== Step 4: Creating sre-pipeline job ==="

JOB_XML=$(cat <<'JOBEOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <description>AI-augmented CI/CD pipeline with Bob CLI for SRE deployment demo</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.StringParameterDefinition>
          <name>BRANCH</name>
          <defaultValue>demo/happy-path</defaultValue>
          <description>Branch to build</description>
          <trim>true</trim>
        </hudson.model.StringParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps">
    <scm class="hudson.plugins.git.GitSCM" plugin="git">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>REPO_URL_PLACEHOLDER</url>
          <credentialsId>github-pat</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/${BRANCH}</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
JOBEOF
)

JOB_XML=$(echo "$JOB_XML" | sed "s|REPO_URL_PLACEHOLDER|$GITHUB_REPO_URL|g")

# Check if job already exists
JOB_STATUS=$(jenkins_get "/job/sre-pipeline/api/json" -o /dev/null -w "%{http_code}" 2>/dev/null || echo "404")

if [ "$JOB_STATUS" = "200" ]; then
    echo "  Job 'sre-pipeline' already exists — updating config."
    jenkins_post "/job/sre-pipeline/config.xml" \
        -H "Content-Type: application/xml" \
        -d "$JOB_XML" > /dev/null 2>&1
else
    echo "  Creating job 'sre-pipeline'..."
    jenkins_post "/createItem?name=sre-pipeline" \
        -H "Content-Type: application/xml" \
        -d "$JOB_XML" > /dev/null 2>&1
fi

echo "  Job created/updated."

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo "========================================"
echo "  Jenkins setup complete!"
echo "========================================"
echo ""
echo "Jenkins UI:     $JENKINS_URL"
echo "Pipeline job:   $JENKINS_URL/job/sre-pipeline/"
echo ""
echo "To test manually:"
echo "  1. Open $JENKINS_URL/job/sre-pipeline/"
echo "  2. Click 'Build with Parameters'"
echo "  3. Set BRANCH to 'demo/happy-path' (or any demo branch)"
echo "  4. Click 'Build'"
echo ""
echo "If GitHub SSL fails: Jenkins → Manage Jenkins → Git → set http.sslVerify=false"
echo ""
