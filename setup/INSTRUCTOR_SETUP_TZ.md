# Jenkins on OpenShift — Bobathon Environment Setup Guide

## Table of Contents

1. [Deployment Overview](#1-deployment-overview)
   - [Architecture Decisions](#11-architecture-decisions)
   - [Repo Layout](#12-repo-layout)
   - [Namespace Layout](#13-namespace-layout)
   - [Per-Build Agent Pod](#14-per-build-agent-pod)
2. [Prerequisites](#2-prerequisites)
   - [Cluster Requirements](#21-cluster-requirements)
   - [Instructor Tooling](#22-instructor-tooling)
3. [Cluster Setup](#3-cluster-setup)
   - [Create Workshop User Accounts](#31-create-workshop-user-accounts)
   - [Create participants group](#32-create-participants-group)
   - [Create user projects](#33-create-user-projects)
4. [Jenkins Setup](#4-jenkins-setup)
   - [Deploy Jenkins](#41-deploy-jenkins)
   - [Grant the Jenkins ServiceAccount the cluster permissions it needs](#42-grant-the-jenkins-serviceaccount-the-cluster-permissions-it-needs)
   - [Configure Jenkins RBAC](#43-configure-jenkins-rbac)
5. [IBM Bob CLI Setup](#5-ibm-bob-cli-setup)
   - [Build and push IBM Bob image](#51-build-and-push-ibm-bob-image)
   - [Create the Bob API Key Kubernetes Secret](#52-create-the-bob-api-key-kubernetes-secret)
6. [Appendix / Reference](#appendix--reference)
   - [Health Checks](#health-checks)
   - [Common Issues and Fixes](#common-issues-and-fixes)
   - [Cleanup](#cleanup)

---

## 1. Deployment Overview

This guide covers everything needed to set up the environment needed to run Jenkins for a bob-a-thon with 15–20 participants. This guide is written for an OpenShift cluster in IBM TechZone where:

- **ArgoCD manages the OAuth `cluster` resource** — adding a new identity provider via `oc patch oauth cluster` will be reverted on the next sync cycle. Workshop users must be added to the existing identity system through TechZone reservation.

> **Important:** `jenkins-values.yaml` contains plaintext passwords once the JCasC
> users block is added. Ensure your `.gitignore` includes it.

> **Important:** We will make use of the namespace / project "jenkins" across several scripts and commands. If you want to deploy to another project, ensure that is reflected in the scripts and commands.

### 1.1 Architecture Decisions

| Decision | Choice & Rationale |
|---|---|
| Jenkins deployment | Single shared Jenkins instance deployed via Helm chart. Uses a standard Kubernetes `Deployment` — avoids the deprecated `DeploymentConfig` from the built-in OpenShift template. |
| Job structure | One pipeline job per user. |
| Agent execution | Dynamic Kubernetes agents with pod spun up per build, provides isolation and auto-cleanup. |
| User namespaces | One pre-provisioned OpenShift namespace per user (`userXX-dev`) as the deployment target. |
| Container registry | Internal OpenShift registry. |
| Jenkins authentication | JCasC local user database. |
| IBM Bob Shell | Deployed as sidecar container inside each dynamic agent pod instead of one static pod in each user namespace. |
| IBM Bob API key | Stored as a Kubernetes Secret in the `jenkins` namespace that gets mounted into the bob sidecar container via `secretKeyRef`. Ensures Jenkins never handles key and its independent of the Jenkins PVC, rotatable with a single `oc` command. |

> **Note:** The IBM Bob API key is managed entirely by Kubernetes — it is independent of the Jenkins PVC and survives a Jenkins reprovision. User GitHub PATs remain in the Jenkins credential store as they are user-scoped and naturally belong there. Users see credential ID strings in their Jenkinsfile but never any secret values.

### 1.2 Namespace Layout

```
OpenShift Cluster
│
├── jenkins/                        ← you manage this
│   ├── Jenkins master pod
│   ├── Ephemeral agent pods        ← spun up per build, auto-deleted
│   ├── bob-cli ImageStream
│   ├── Secret: bob-cli-credentials ← Kubernetes secret, independent of Jenkins PVC
│   └── Jenkins credentials store  ← holds user GitHub PATs only
│
├── user01-dev/                     ← user01's isolated target namespace
│   ├── workshop-app (Deployment)
│   └── workshop-app (ImageStream)
│
├── user02-dev/
│   └── ...
│
└── userXX-dev/  (×20 total)
```

### 1.3 Per-Build Agent Pod

Every pipeline run spins up a Kubernetes pod in the `jenkins` namespace containing three containers:

| Container | Image | Used for |
|---|---|---|
| `build-tools` | `maven:3.9-eclipse-temurin-17` | Compile, unit tests, package |
| `oc-tools` | `quay.io/openshift/origin-cli:latest` | `oc start-build`, `oc rollout`, GitHub Status API calls |
| `bob` | `<internal-registry>/jenkins/bob-cli:latest` | AI code review (Lab 5). `BOBSHELL_API_KEY` injected at runtime. |

> **Note:** The pod is deleted automatically when the pipeline finishes. Users never interact with it directly.

#### 1.3.1 Credential Flow

```
Kubernetes Secret: bob-cli-credentials (jenkins namespace)
└── mounted as $BOBSHELL_API_KEY in bob sidecar container via secretKeyRef

Jenkins Credential Store
└── userXX-github-pat  → $GITHUB_TOKEN in oc-tools container

Jenkins SA → edit role per userXX-dev namespace → oc start-build / oc rollout
```

---

## 2. Prerequisites

### 2.1 Cluster Requirements

- OpenShift 4.10 or later
- `cluster-admin` access for the instructor account
- Internal image registry enabled
- Dynamic volume provisioning available (for Jenkins PVC)
- Capacity: ~4 vCPU / 8 Gi baseline, plus up to 20 × agent pods at ~1 vCPU / 1 Gi each at peak

### 2.2 Instructor Tooling

- `oc` CLI — logged in as `cluster-admin`
- `helm` v3 — for Jenkins installation
- `podman` or `docker` — to build and push the bob-cli image
- `curl` and `jq`
- `bash`
- `uv` or python virtual environment.

---

## 3. Jenkins Setup

### 3.1 Deploy and Configure Jenkins

Makes use of the Helm chart based deployment of Jenkins to OpenShift. Jenkins is deployed using the **Jenkins Helm chart** with OpenShift OAuth
disabled. Users are added after install via a Groovy init script. Another approach is to make use of the built-in `jenkins-persistent` template. However, that will end up using a `DeploymentConfig`, which is deprecated from 4.14 onwards and result in deprecation warnings. Workshop users log in to Jenkins using accounts pre-created via JCasC (Jenkins Configuration as Code).

> **Alternative:** OpenShift OAuth can be used instead so users authenticate via their OpenShift
> credentials.

#### 3.1.1 Create the jenkins namespace

```bash
oc new-project jenkins \
  --description='Shared Jenkins for workshop' \
  --display-name='Jenkins Workshop'
```

#### 3.1.2 Add the Jenkins Helm repository

```bash
helm repo add jenkins https://charts.jenkins.io
helm repo update
```

#### 3.1.3 Apply the SCC binding

1. The Jenkins chart runs as UID 1000. Apply the SCC binding before installing so it takes effect the moment Helm creates the ServiceAccount:

    ```bash
    oc apply -f setup/assets/jenkins-scc.yaml
    ```

    Verify:

    ```bash
    oc get clusterrolebinding jenkins-anyuid
    ```

    >**Note**: If you used a different namespace, update the jenkins-scc.yaml file to match.

#### 3.1.4 Create the Jenkins Values file

1. Create a duplicate of the `setup/assets/template-jenkins-values_v2.yaml` file and call it `setup/assets/jenkins-values.yaml`.

1. [OPTIONAL] Validate the YAML before installing:

    ```bash
    python3 -c "import yaml; yaml.safe_load(open('jenkins-values.yaml'))" \
      && echo "YAML valid" || echo "YAML has errors — fix before installing"
    ```

#### 3.1.5 Install Jenkins via Helm

```bash
helm install jenkins jenkins/jenkins \
  -f setup/assets/jenkins-values.yaml \
  -n jenkins \
  --wait \
  --timeout 10m
```

#### 3.1.6 Setup Jenkins security

1. Retrieve the admin password. The chart auto-generates the admin password on first install and stores it in a Kubernetes Secret:

    ```bash
    oc get secret jenkins -n jenkins \
      -o jsonpath='{.data.jenkins-admin-password}' | base64 -d
    echo
    ```

    >Note: Save this password — you will need it to log in as `admin` to verify the setup and manage Jenkins. Do not distribute it to participants.

1. Create the Jenkins Route

    ```bash
    oc create route edge jenkins \
      --service=jenkins \
      --port=8080 \
      --insecure-policy=Redirect \
      -n jenkins
    ```

1. Get the Jenkins route

    ```bash
    oc get route jenkins -n jenkins -o jsonpath='{.spec.host}'
    ```

1. Jenkins usually starts unsecured by default. Run the following script to generate the security setup for Jenkins (paste in the admin password from previous step.):

    ```bash
    uv run setup/scripts/generate-security-setup.py --password <admin-password>
    ```

1. Navigate to `https://<jenkins-route>/script` in your browser.

1. Paste the output from generating the security setup script into the Script Console and click **Run**. Verify the output shows `Security configured`. *Note: In some cases you may get an 'Oops' screen. Go back to the login page to see if security was enabled.* 

1. Confirm you can log into the Jenkins UI as `admin` at `https://<jenkins-route>`. 

#### 3.1.7 Setup Jenkins users

Since JCasC is disabled to avoid startup issues, users are added using the Jenkins script console.

1. Generate the user creation script:

    ```bash
    uv run setup/scripts/generate-jenkins-users_v2.py 20 --password Workshop2024!
    ```

1. Logged in as `admin`, go to `https://<jenkins-route>/script`, paste the output from the above user creation script, and click **Run**. Verify the output shows `Done — 20 users created`.

1. Next we set up each user to get their own folder, so that credentials stored inside a folder are only visible to jobs in that folder — users cannot see each other's GitHub PATs. We will switch the authorization strategy from `loggedInUsersCanDoAnything` to
project-based matrix security, giving each user full control of only their own folder while blocking access to Manage Jenkins.

1. Paste this script into the Script Console and click **Run**:

    ```groovy
    import jenkins.model.*
    import hudson.security.*
    import com.cloudbees.hudson.plugins.folder.*
    import com.cloudbees.hudson.plugins.folder.properties.AuthorizationMatrixProperty

    def instance = Jenkins.getInstance()

    // Global strategy — authenticated users can log in but see nothing
    def strategy = new ProjectMatrixAuthorizationStrategy()
    strategy.add(Jenkins.ADMINISTER, "admin")
    strategy.add(Jenkins.READ,       "authenticated")
    instance.setAuthorizationStrategy(strategy)
    instance.save()

    // Per-folder permissions
    (1..20).each { i ->
        def username = String.format("user%d", i)

        def folder = instance.getItem(username)
        if (!folder) {
            folder = instance.createProject(Folder, username)
            println "Created folder: ${username}"
        }

        def prop = new AuthorizationMatrixProperty()
        prop.add(Item.BUILD,      username)
        prop.add(Item.CANCEL,     username)
        prop.add(Item.CONFIGURE,  username)
        prop.add(Item.CREATE,     username)
        prop.add(Item.DISCOVER,   username)
        prop.add(Item.READ,       username)
        prop.add(Item.WORKSPACE,  username)
        prop.add(Run.DELETE,      username)
        prop.add(Run.UPDATE,      username)
        prop.add(Run.ARTIFACTS,   username)
        prop.add(com.cloudbees.plugins.credentials.CredentialsProvider.VIEW,           username)
        prop.add(com.cloudbees.plugins.credentials.CredentialsProvider.CREATE,         username)
        prop.add(com.cloudbees.plugins.credentials.CredentialsProvider.UPDATE,         username)
        prop.add(com.cloudbees.plugins.credentials.CredentialsProvider.DELETE,         username)
        prop.add(com.cloudbees.plugins.credentials.CredentialsProvider.MANAGE_DOMAINS, username)

        folder.addProperty(prop)
        folder.save()
        println "Configured folder: ${username}"
    }

    println "Done — each user can only see their own folder"
    ```

1. Verify the output shows `Folders and authorization configured`.

#### 3.1.8 Configure the Kubernetes cloud

Jenkins starts with the Kubernetes plugin installed but no Cloud configured (the values file keeps `JCasC.defaultConfig: false`). Without a Cloud, pipelines that use `agent { kubernetes { ... } }` fail with `ERROR: No Kubernetes cloud was found.` — every workshop pipeline is blocked until we add one. Configure it via the Script Console, matching the pattern used by the security and user setup above.

1. Paste this Groovy into `https://<jenkins-route>/script` and click **Run**:

    ```groovy
    import jenkins.model.*
    import org.csanchez.jenkins.plugins.kubernetes.KubernetesCloud

    def jenkins = Jenkins.getInstance()
    jenkins.clouds.removeAll { it instanceof KubernetesCloud }

    def cloud = new KubernetesCloud("kubernetes")
    cloud.setNamespace("jenkins")
    cloud.setJenkinsUrl("http://jenkins.jenkins.svc.cluster.local:8080")
    cloud.setJenkinsTunnel("jenkins-agent.jenkins.svc.cluster.local:50000")
    cloud.setContainerCapStr("10")

    jenkins.clouds.add(cloud)
    jenkins.save()

    println "Kubernetes cloud configured: ${cloud.name} in ${cloud.namespace}"
    ```

    > **Note:** If your Jenkins namespace isn't `jenkins`, replace the three `jenkins` strings inside `setNamespace`, `setJenkinsUrl`, and `setJenkinsTunnel` with your namespace before pasting.

1. Verify the output shows `Kubernetes cloud configured: kubernetes in jenkins`.

1. [Optional] Verify via UI: **Manage Jenkins → Clouds** should list a `kubernetes` cloud pointing at your namespace.

### 3.2 Grant the Jenkins ServiceAccount the cluster permissions it needs

1. Allow Jenkins to manage pods in its own namespace (required for dynamic agents)

    ```bash
    oc adm policy add-role-to-user edit \
      system:serviceaccount:jenkins:jenkins \
      -n jenkins
    ```

1. Allow Jenkins to pull images from the internal registry

    ```bash
    oc policy add-role-to-user system:image-puller \
      system:serviceaccount:jenkins:jenkins \
      -n jenkins
    ```

---

## 4. Cluster Setup

### 4.1 Add Workshop User Accounts

> **This step is optional.** Participants do not need OpenShift console access to
> complete the workshop labs. All pipeline interactions with OpenShift use the Jenkins
> ServiceAccount. Skip this step unless you specifically want users to be able to view
> their namespace in the OpenShift console.

1. The cluster uses an OpenID identity provider managed externally. Add the users to the OpenShift reservation using the TechZone -> share reservation.

1. After users have been provisioned and have logged in to OpenShift at least once (which creates their `User` object), grant each user access to only their own namespace:

    ```bash
    for i in $(seq -w 1 20); do
      # Grant edit access to their own namespace only
      oc adm policy add-role-to-user edit {USER} -n user${i}-dev

      # Explicitly deny access to the jenkins namespace
      # (no role binding = no access — this is the default, but explicit is clearer)
    done
    ```

### 4.2 Create participants group

1. Creating a group makes it easy to apply RBAC in bulk and to clean up afterwards:

    ```bash
    # Create the group
    oc adm groups new workshop-participants
    ```

1. Add all the users to the group [TODO: CREATE SCRIPT TO AUTOMATE]

    ```bash
    # For each of the users
    oc adm groups add-users workshop-participants ${i}
    ```

1. Verify the group:

    ```bash
    # Verify
    oc get group workshop-participants -o yaml
    ```

### 4.3 Create user projects

1. Edit the `USERS` array in the `create-projects.sh` file to match your participant list, then run the script to create the user projects and set up the privileges.

1. Apply resource quotas to each user project [TODO: CREATE A SCRIPT TO AUTOMATE]

    ```bash
    oc apply -f workshop-user-project-quota.yaml -n ${USER}-dev
    ```

---

## 5. IBM Bob CLI Setup

> **Important:** The API key must **not** be baked into the image. It will be injected at runtime.

### 5.1 Build and push IBM Bob image

1. Build the image from the Dockerfile in this repo:

    ```bash
    cd setup/bob-cli
    podman build -t bob-cli:latest .
    cd -
    ```

1. Expose the OpenShift internal image registry externally so you can push from your laptop. TechZone clusters don't have this route by default:

    ```bash
    oc patch configs.imageregistry.operator.openshift.io/cluster \
      --type merge -p '{"spec":{"defaultRoute":true}}'

    # Wait for the route to appear (usually <30 seconds)
    until oc get route default-route -n openshift-image-registry >/dev/null 2>&1; do sleep 2; done

    REGISTRY=$(oc get route default-route -n openshift-image-registry -o jsonpath='{.spec.host}')
    echo "Registry route: $REGISTRY"
    ```

1. Log into the registry. The `-u` value is a literal dummy — the OpenShift registry only validates the bearer token from `-p`, not the username. Using `$(oc whoami)` directly breaks when it resolves to `kube:admin` because the colon makes podman read the value as `user:password`:

    ```bash
    podman login -u unused -p "$(oc whoami -t)" --tls-verify=false "$REGISTRY"
    ```

1. Tag and push into the `jenkins` namespace. The route uses a self-signed cert, so `--tls-verify=false` is required on push:

    ```bash
    podman tag bob-cli:latest "$REGISTRY/jenkins/bob-cli:latest"
    podman push --tls-verify=false "$REGISTRY/jenkins/bob-cli:latest"
    ```

1. Verify the ImageStream was created:

    ```bash
    oc get imagestream bob-cli -n jenkins
    ```

    Expected: a row with tag `latest`.

### 5.2 Create the Bob API Key Kubernetes Secret

The bob API key is stored as a Kubernetes Secret in the `jenkins` namespace and mounted directly into the bob sidecar container via `secretKeyRef`. Jenkins never handles this secret — it is injected by Kubernetes at pod scheduling time.

This approach is preferred over a Jenkins credential because:

- The secret is independent of the Jenkins PVC — it survives a Jenkins reprovision
- It is manageable with standard `oc` commands and compatible with GitOps/Vault/External Secrets
- Rotation requires a single `oc apply` with no Jenkins UI interaction

1. Create the Kubernetes Secret. The secret name and key must match what the Bob Shell CLI reads from env (`BOBSHELL_API_KEY`); anything else and Bob silently fails to authenticate even though the key is present in the pod:

    ```bash
    oc create secret generic bob-cli-credentials \
      --from-literal=BOBSHELL_API_KEY=<your-bob-api-key> \
      -n jenkins
    ```

1. Grant the Jenkins ServiceAccount read access to the secret:

    ```bash
    oc create role bob-secret-reader \
      --verb=get \
      --resource=secrets \
      --resource-name=bob-cli-credentials \
      -n jenkins

    oc create rolebinding bob-secret-reader \
      --role=bob-secret-reader \
      --serviceaccount=jenkins:jenkins \
      -n jenkins
    ```

    > **Note:** The secret value is never visible to users. It is injected directly into the bob container by Kubernetes before the container starts. There is no credential ID for users to reference in their Jenkinsfile for this key — it simply appears as the `$BOBSHELL_API_KEY` environment variable inside the bob container.

---

## Appendix / Reference

### Common Issues and Fixes

| Symptom | Fix |
|---|---|
| User cannot log in to OpenShift | Verify the HTPasswd provider is active: `oc get oauth cluster -o yaml`. Check OAuth pod logs: `oc logs -n openshift-authentication deployment/oauth-openshift`. Confirm the user was written to the htpasswd file: `htpasswd -v workshop-users.htpasswd userXX`. |
| User cannot log in to Jenkins | Confirm the user was created in JCasC: **Manage Jenkins → Manage Users**. If missing, JCasC did not apply — check logs: `oc logs deployment/jenkins -n jenkins \| grep -i "jcasc\|error" \| tail -30`. Re-run `helm upgrade` with the corrected values file. |
| Jenkins pod fails with SCC / UID error | The SCC binding was not applied before install. Run: `oc apply -f manifests/jenkins-scc.yaml`. If the install already timed out: `helm uninstall jenkins -n jenkins && oc delete pvc jenkins -n jenkins`, then reinstall from Step 1f — the binding persists and does not need to be reapplied. |
| Jenkins starts but is unsecured / no login prompt | JCasC did not apply — almost always an indentation error in `jenkins-values.yaml`. Validate the YAML: `python3 -c "import yaml; yaml.safe_load(open('jenkins-values.yaml'))"`. Fix any errors, then `helm uninstall jenkins -n jenkins && oc delete pvc jenkins -n jenkins` and reinstall from Step 1f. Verify with `oc exec statefulset/jenkins -n jenkins -c jenkins -- grep securityRealm /var/jenkins_home/config.xml` — must show `HudsonPrivateSecurityRealm`. |
| Jenkins `admin` password unknown | Retrieve from the Kubernetes Secret: `oc get secret jenkins -n jenkins -o jsonpath='{.data.jenkins-admin-password}' \| base64 -d` |
| Agent pod stuck in `Pending` | Check quota: `oc describe quota -n jenkins`. Too many concurrent builds — ask users to re-run once others complete. |
| `oc start-build` fails: `forbidden` | Re-run RBAC step: `oc adm policy add-role-to-user edit system:serviceaccount:jenkins:jenkins -n userXX-dev` |
| `bob` container: `ImagePullBackOff` | Verify image exists: `oc get imagestream -n jenkins`. Re-run the `podman push` command from Step 2. |
| GitHub PAT credential not found | User likely entered the wrong ID. It must be exactly `<github-username>-github-pat`. |
| `BOBSHELL_API_KEY` shows `****` but bob fails | The key is reaching bob correctly. Check whether the env var name matches what bob expects (`bob --help`). |
| BuildConfig not found | Provisioning did not complete for that user. Re-run `provision-users.sh` scoped to that user. |
| Jenkins `OOMKilled` | Scale up memory: `oc set resources statefulset/jenkins -n jenkins --limits=memory=6Gi` |

### Cleanup

1. Remove user namespaces

    ```bash
    for i in $(seq -w 1 20); do
      oc delete project user${i}-dev --wait=false
    done
    ```

1. Remove Jenkins

    ```bash
    helm uninstall jenkins -n jenkins
    ```

1. Remove OpenShift artifacts

    ```bash
    # Remove the SCC binding
    oc delete clusterrolebinding jenkins-anyuid --ignore-not-found

    # Then delete the namespace itself
    oc delete project jenkins
    ```

### Rotate the Bob API Key

Because the key is a Kubernetes Secret, rotation requires no Jenkins UI interaction and no image rebuild. The new value is picked up automatically on the next pipeline run.

```bash
# Rotate the key — dry-run generates the updated secret YAML, apply patches it in place
oc create secret generic bob-cli-credentials \
  --from-literal=BOBSHELL_API_KEY=<new-bob-api-key> \
  --dry-run=client -o yaml | oc apply -f -
```

> **Note:** In-flight builds use the old key until their bob container exits. The new key takes effect on the next agent pod scheduled.

### curl Reference

The following curl commands can be used to run Groovy scripts against the Jenkins Script Console from the command line. In practice, pasting scripts directly into the browser Script Console is more reliable due to CSRF handling. These commands are provided as a reference for automation.

```bash
JENKINS_URL="https://$(oc get route jenkins -n jenkins -o jsonpath='{.spec.host}')"
ADMIN_PASS=$(oc get secret jenkins -n jenkins \
  -o jsonpath='{.data.jenkins-admin-password}' | base64 -d)

# Get a CSRF crumb (required for all POST requests when Jenkins is secured)
CRUMB=$(curl -su "admin:${ADMIN_PASS}" \
  "${JENKINS_URL}/crumbIssuer/api/json" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); \
    print(d['crumbRequestField']+':'+d['crumb'])")

# Run an arbitrary Groovy script
curl -s -X POST \
  "${JENKINS_URL}/scriptText" \
  -u "admin:${ADMIN_PASS}" \
  -H "${CRUMB}" \
  --data-urlencode "script=$(cat /path/to/script.groovy)"
```

> **Note:** When Jenkins is still unsecured (before Step 1i Script 1 has been
> run), omit the `-u` flag and the crumb is not required for the first POST.
> After security is enabled, both the `-u` flag and crumb are required.

