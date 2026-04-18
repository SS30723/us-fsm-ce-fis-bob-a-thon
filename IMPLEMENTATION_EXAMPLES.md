# Multi-User Jenkins Implementation Examples

This document provides ready-to-use configuration examples for implementing the multi-user Jenkins setup with Bob sidecars.

---

## 1. Jenkins Agent Pod Template with Bob Sidecar

### Updated Jenkinsfile Agent Configuration

```groovy
pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins-agent: sre-pipeline
spec:
  serviceAccountName: jenkins
  volumes:
  - name: shared-workspace
    emptyDir: {}
  containers:
  # Main pipeline agent container
  - name: pipeline-agent
    image: image-registry.openshift-image-registry.svc:5000/jenkins-project/sre-jenkins-agent:latest
    command: ['sleep']
    args: ['infinity']
    env:
    - name: HOME
      value: /home/jenkins
    volumeMounts:
    - name: shared-workspace
      mountPath: /shared
    resources:
      requests:
        memory: "512Mi"
        cpu: "250m"
      limits:
        memory: "1Gi"
        cpu: "1"
  
  # Bob CLI sidecar container
  - name: bob-cli
    image: image-registry.openshift-image-registry.svc:5000/jenkins-project/sre-bob-cli:latest
    command: ['sleep']
    args: ['infinity']
    env:
    - name: BOBSHELL_API_KEY
      valueFrom:
        secretKeyRef:
          name: bob-api-key
          key: BOBSHELL_API_KEY
    - name: BOB_ACCEPT_LICENSE
      value: "true"
    - name: HOME
      value: /workspace
    volumeMounts:
    - name: shared-workspace
      mountPath: /shared
    resources:
      requests:
        memory: "256Mi"
        cpu: "10m"
      limits:
        memory: "2Gi"
        cpu: "200m"
"""
            defaultContainer 'pipeline-agent'
        }
    }
    
    parameters {
        string(name: 'BRANCH', defaultValue: 'main', description: 'Branch to build')
        string(name: 'USER_PROJECT', defaultValue: 'user1-project', description: 'Target OpenShift project')
    }
    
    // ... rest of pipeline
}
```

---

## 2. Updated askBob Helper Function

### Option A: Using Shared Volume (Recommended)

```groovy
def askBob(prompt) {
    // Write prompt to shared volume from pipeline-agent container
    def promptFile = "/shared/bob-prompt-${System.currentTimeMillis()}.txt"
    
    container('pipeline-agent') {
        writeFile(file: promptFile, text: prompt)
    }
    
    // Execute Bob in the bob-cli sidecar container
    def result = container('bob-cli') {
        sh(
            script: "bob -p \"\$(cat ${promptFile})\" --hide-intermediary-output 2>/dev/null || echo 'Bob analysis unavailable'",
            returnStdout: true
        ).trim()
    }
    
    // Clean up
    container('pipeline-agent') {
        sh "rm -f ${promptFile}"
    }
    
    return result
}
```

### Option B: Using kubectl exec (Alternative)

```groovy
def askBob(prompt) {
    def podName = sh(
        script: "hostname",
        returnStdout: true
    ).trim()
    
    def promptFile = ".bob-prompt-${System.currentTimeMillis()}.txt"
    writeFile(file: promptFile, text: prompt)
    
    // Copy to bob-cli container and execute
    sh "cat ${promptFile} | kubectl exec -i ${podName} -c bob-cli -- bash -c 'cat > /tmp/bob-prompt.txt'"
    
    def result = sh(
        script: "kubectl exec ${podName} -c bob-cli -- bash -c 'bob -p \"\$(cat /tmp/bob-prompt.txt)\" --hide-intermediary-output'",
        returnStdout: true
    ).trim()
    
    sh "rm -f ${promptFile}"
    return result
}
```

---

## 3. Setup Scripts

### Master Setup Script

```bash
#!/bin/bash
# setup-multi-user-jenkins.sh
# Creates Jenkins instance and 20 user projects with proper RBAC

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "=== Multi-User Jenkins Setup ==="
echo "This will create:"
echo "  - 1 Jenkins project (jenkins-project)"
echo "  - 20 user projects (user1-project through user20-project)"
echo "  - Bob CLI sidecar configuration"
echo ""

# Check prerequisites
if ! command -v oc &>/dev/null; then
    echo "Error: oc CLI not found"
    exit 1
fi

if ! oc whoami &>/dev/null; then
    echo "Error: Not logged into OpenShift"
    exit 1
fi

if [ -z "$BOBSHELL_API_KEY" ]; then
    if [ -f "$PROJECT_DIR/.env" ] && grep -q BOBSHELL_API_KEY "$PROJECT_DIR/.env"; then
        export $(grep BOBSHELL_API_KEY "$PROJECT_DIR/.env" | xargs)
    else
        echo "Error: BOBSHELL_API_KEY not set"
        echo "Set it in .env file or export BOBSHELL_API_KEY=your-key"
        exit 1
    fi
fi

# Step 1: Create Jenkins project
echo ""
echo "=== Step 1: Creating Jenkins Project ==="
if oc get project jenkins-project &>/dev/null 2>&1; then
    echo "jenkins-project already exists"
    oc project jenkins-project
else
    oc new-project jenkins-project
fi

# Step 2: Create Bob API key secret
echo ""
echo "=== Step 2: Creating Bob API Key Secret ==="
oc delete secret bob-api-key -n jenkins-project 2>/dev/null || true
oc create secret generic bob-api-key \
    --from-literal=BOBSHELL_API_KEY="$BOBSHELL_API_KEY" \
    -n jenkins-project
echo "Bob API key secret created"

# Step 3: Build Bob CLI image
echo ""
echo "=== Step 3: Building Bob CLI Image ==="
if ! oc get bc/sre-bob-cli-build &>/dev/null 2>&1; then
    oc new-build --binary --name=sre-bob-cli-build --strategy=docker
fi
oc start-build sre-bob-cli-build \
    --from-dir="$SCRIPT_DIR/../bob-cli" \
    --follow --wait

# Step 4: Build Jenkins agent image
echo ""
echo "=== Step 4: Building Jenkins Agent Image ==="
if ! oc get bc/sre-jenkins-agent-build &>/dev/null 2>&1; then
    oc new-build --binary --name=sre-jenkins-agent-build --strategy=docker
fi
oc start-build sre-jenkins-agent-build \
    --from-dir="$SCRIPT_DIR/../jenkins-agent" \
    --follow --wait

# Step 5: Deploy Jenkins
echo ""
echo "=== Step 5: Deploying Jenkins ==="
if oc get dc/jenkins &>/dev/null 2>&1; then
    echo "Jenkins already deployed"
else
    if oc get template jenkins-persistent -n openshift &>/dev/null 2>&1; then
        oc new-app jenkins-persistent \
            --param MEMORY_LIMIT=4Gi \
            --param VOLUME_CAPACITY=10Gi \
            --param ENABLE_OAUTH=true
    else
        oc new-app jenkins-ephemeral \
            --param MEMORY_LIMIT=4Gi \
            --param ENABLE_OAUTH=true
    fi
fi

echo "Waiting for Jenkins to start..."
oc rollout status dc/jenkins --timeout=300s

JENKINS_ROUTE=$(oc get route jenkins -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
if [ -z "$JENKINS_ROUTE" ]; then
    oc expose svc/jenkins
    JENKINS_ROUTE=$(oc get route jenkins -o jsonpath='{.spec.host}')
fi

# Step 6: Create user projects
echo ""
echo "=== Step 6: Creating User Projects ==="
for i in {1..20}; do
    PROJECT="user${i}-project"
    
    if oc get project ${PROJECT} &>/dev/null 2>&1; then
        echo "  ${PROJECT} already exists"
    else
        echo "  Creating ${PROJECT}..."
        oc new-project ${PROJECT}
        oc label namespace ${PROJECT} \
            lab-user="user${i}" \
            lab-type="participant"
    fi
    
    # Grant Jenkins service account edit access
    echo "  Granting Jenkins access to ${PROJECT}..."
    oc policy add-role-to-user edit \
        system:serviceaccount:jenkins-project:jenkins \
        -n ${PROJECT} 2>/dev/null || true
done

# Step 7: Deploy applications to user projects
echo ""
echo "=== Step 7: Deploying Applications ==="
for i in {1..20}; do
    PROJECT="user${i}-project"
    echo "  Deploying to ${PROJECT}..."
    
    oc project ${PROJECT}
    
    # Enable anyuid for PostgreSQL
    oc adm policy add-scc-to-user anyuid -z default -n ${PROJECT} 2>/dev/null || true
    
    # Deploy database
    oc apply -f "$PROJECT_DIR/k8s/order-db-deployment.yaml" 2>/dev/null || true
    oc apply -f "$PROJECT_DIR/k8s/order-db-service.yaml" 2>/dev/null || true
    
    # Create build config if it doesn't exist
    if ! oc get bc/order-service-build &>/dev/null 2>&1; then
        oc new-build --binary --name=order-service-build --strategy=docker
    fi
    
    # Build order-service (skip if already built)
    if ! oc get istag order-service-build:latest &>/dev/null 2>&1; then
        echo "    Building order-service..."
        cd "$PROJECT_DIR/order-service"
        mvn package -DskipTests -q
        cd "$PROJECT_DIR"
        oc start-build order-service-build \
            --from-dir=order-service \
            --follow --wait
    fi
    
    # Deploy order-service
    IMAGE="image-registry.openshift-image-registry.svc:5000/${PROJECT}/order-service-build:latest"
    sed "s|IMAGE_PLACEHOLDER|${IMAGE}|g" "$PROJECT_DIR/k8s/order-service-deployment.yaml" | oc apply -f -
    oc apply -f "$PROJECT_DIR/k8s/order-service-service.yaml"
    
    # Create route
    oc expose svc/order-service 2>/dev/null || true
done

# Step 8: Configure Jenkins credentials
echo ""
echo "=== Step 8: Configuring Jenkins Credentials ==="
if [ -n "$GITHUB_PAT" ]; then
    echo "GitHub PAT will be configured via Jenkins UI or API"
else
    echo "Note: Set GITHUB_PAT environment variable to auto-configure GitHub credentials"
fi

# Done
echo ""
echo "========================================"
echo "  Multi-User Jenkins Setup Complete!"
echo "========================================"
echo ""
echo "Jenkins URL:     https://${JENKINS_ROUTE}"
echo "User projects:   user1-project through user20-project"
echo ""
echo "Next steps:"
echo "1. Log into Jenkins: https://${JENKINS_ROUTE}"
echo "2. Configure GitHub credentials (if not already done)"
echo "3. Create Jenkins folders and jobs for each user"
echo "4. Test with a single user first"
echo ""
echo "To create Jenkins jobs, run:"
echo "  ./configure-jenkins-jobs.sh"
echo ""
```

### User Project Teardown Script

```bash
#!/bin/bash
# teardown-multi-user-jenkins.sh
# Removes all user projects and Jenkins

set -e

echo "=== Multi-User Jenkins Teardown ==="
echo "This will DELETE:"
echo "  - jenkins-project"
echo "  - user1-project through user20-project"
echo ""
read -p "Are you sure? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted"
    exit 0
fi

# Delete user projects
echo ""
echo "=== Deleting User Projects ==="
for i in {1..20}; do
    PROJECT="user${i}-project"
    if oc get project ${PROJECT} &>/dev/null 2>&1; then
        echo "  Deleting ${PROJECT}..."
        oc delete project ${PROJECT} --wait=false
    fi
done

# Delete Jenkins project
echo ""
echo "=== Deleting Jenkins Project ==="
if oc get project jenkins-project &>/dev/null 2>&1; then
    echo "  Deleting jenkins-project..."
    oc delete project jenkins-project --wait=false
fi

echo ""
echo "Teardown initiated. Projects will be deleted in the background."
echo "Check status with: oc get projects | grep -E 'jenkins-project|user.*-project'"
```

---

## 4. Jenkins Job Configuration

### Job DSL Script for Creating User Folders

```groovy
// create-user-folders.groovy
// Run this in Jenkins Script Console: Manage Jenkins > Script Console

import jenkins.model.Jenkins
import com.cloudbees.hudson.plugins.folder.Folder
import hudson.model.FreeStyleProject
import org.jenkinsci.plugins.workflow.job.WorkflowJob
import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import hudson.plugins.git.GitSCM
import hudson.plugins.git.BranchSpec

def jenkins = Jenkins.instance

// GitHub repo URL - update this
def repoUrl = 'https://github.ibm.com/YOUR-ORG/sre-project'
def credentialsId = 'github-pat'

(1..20).each { i ->
    def folderName = "user${i}"
    def userProject = "user${i}-project"
    
    // Create folder if it doesn't exist
    def folder = jenkins.getItem(folderName)
    if (!folder) {
        folder = jenkins.createProject(Folder.class, folderName)
        folder.setDescription("Pipeline jobs for user${i}")
        println "Created folder: ${folderName}"
    }
    
    // Create pipeline job in folder
    def jobName = "sre-pipeline"
    def job = folder.getItem(jobName)
    
    if (!job) {
        job = folder.createProject(WorkflowJob.class, jobName)
        job.setDescription("AI-augmented CI/CD pipeline for ${userProject}")
        
        // Configure Git SCM
        def scm = new GitSCM(repoUrl)
        scm.branches = [new BranchSpec('*/${BRANCH}')]
        scm.userRemoteConfigs[0].credentialsId = credentialsId
        
        // Configure pipeline from SCM
        def definition = new CpsScmFlowDefinition(scm, 'Jenkinsfile')
        definition.lightweight = true
        job.setDefinition(definition)
        
        // Add parameters
        def paramDef = new hudson.model.ParametersDefinitionProperty(
            new hudson.model.StringParameterDefinition('BRANCH', 'main', 'Branch to build'),
            new hudson.model.StringParameterDefinition('USER_PROJECT', userProject, 'Target OpenShift project')
        )
        job.addProperty(paramDef)
        
        job.save()
        println "Created job: ${folderName}/${jobName}"
    }
}

jenkins.save()
println "\nDone! Created folders and jobs for 20 users."
```

### Alternative: Jenkins Configuration as Code (JCasC)

```yaml
# jenkins-casc.yaml
# Place in /var/lib/jenkins/casc_configs/ or configure via CASC_JENKINS_CONFIG

jenkins:
  systemMessage: "Multi-User Jenkins with Bob CLI Integration"
  numExecutors: 0
  mode: EXCLUSIVE
  
  securityRealm:
    openshift:
      serviceAccountDirectory: /run/secrets/kubernetes.io/serviceaccount
      serviceAccountName: jenkins
  
  authorizationStrategy:
    roleBased:
      roles:
        global:
          - name: "admin"
            description: "Jenkins administrators"
            permissions:
              - "Overall/Administer"
            assignments:
              - "admin"
          - name: "authenticated"
            description: "Authenticated users"
            permissions:
              - "Overall/Read"
            assignments:
              - "authenticated"

credentials:
  system:
    domainCredentials:
      - credentials:
          - usernamePassword:
              scope: GLOBAL
              id: github-pat
              username: git
              password: ${GITHUB_PAT}
              description: "GitHub Enterprise PAT"

jobs:
  - script: >
      (1..20).each { i ->
        folder("user${i}") {
          description("Pipeline jobs for user${i}")
        }
        
        pipelineJob("user${i}/sre-pipeline") {
          description("AI-augmented CI/CD pipeline for user${i}-project")
          
          parameters {
            stringParam('BRANCH', 'main', 'Branch to build')
            stringParam('USER_PROJECT', "user${i}-project", 'Target OpenShift project')
          }
          
          definition {
            cpsScm {
              scm {
                git {
                  remote {
                    url('https://github.ibm.com/YOUR-ORG/sre-project')
                    credentials('github-pat')
                  }
                  branch('*/${BRANCH}')
                }
              }
              scriptPath('Jenkinsfile')
            }
          }
        }
      }
```

---

## 5. RBAC Configuration Examples

### Grant Jenkins Access to All User Projects

```bash
#!/bin/bash
# configure-rbac.sh

echo "=== Configuring RBAC ==="

# Grant Jenkins service account edit access to all user projects
for i in {1..20}; do
    PROJECT="user${i}-project"
    echo "Granting Jenkins edit access to ${PROJECT}..."
    oc policy add-role-to-user edit \
        system:serviceaccount:jenkins-project:jenkins \
        -n ${PROJECT}
done

# Grant users view access to Jenkins project (to see their folder)
for i in {1..20}; do
    USER="user${i}"
    echo "Granting ${USER} view access to jenkins-project..."
    oc policy add-role-to-user view ${USER} -n jenkins-project
done

# Grant users edit access to their own project
for i in {1..20}; do
    USER="user${i}"
    PROJECT="user${i}-project"
    echo "Granting ${USER} edit access to ${PROJECT}..."
    oc policy add-role-to-user edit ${USER} -n ${PROJECT}
done

echo "RBAC configuration complete!"
```

### Network Policy for User Isolation

```yaml
# network-policy-user-isolation.yaml
# Apply to each user project to restrict cross-project traffic

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-cross-user-traffic
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Allow traffic from same namespace
  - from:
    - podSelector: {}
  # Allow traffic from Jenkins project
  - from:
    - namespaceSelector:
        matchLabels:
          name: jenkins-project
  # Allow traffic from OpenShift ingress
  - from:
    - namespaceSelector:
        matchLabels:
          network.openshift.io/policy-group: ingress
  egress:
  # Allow all egress (for external APIs, registries, etc.)
  - to:
    - podSelector: {}
  - to:
    - namespaceSelector: {}
```

### Resource Quota per User Project

```yaml
# resource-quota.yaml
# Apply to each user project to prevent resource exhaustion

apiVersion: v1
kind: ResourceQuota
metadata:
  name: user-quota
spec:
  hard:
    pods: "10"
    requests.cpu: "2"
    requests.memory: "4Gi"
    limits.cpu: "4"
    limits.memory: "8Gi"
    persistentvolumeclaims: "5"
    requests.storage: "10Gi"
```

---

## 6. Testing and Validation

### Test Script for Single User

```bash
#!/bin/bash
# test-single-user.sh
# Tests the setup with user1

set -e

echo "=== Testing User1 Setup ==="

# Check project exists
echo "Checking user1-project..."
oc project user1-project

# Check deployments
echo "Checking deployments..."
oc get deployments

# Check Jenkins can access the project
echo "Checking Jenkins RBAC..."
oc policy who-can edit deployment -n user1-project | grep jenkins

# Test Bob CLI image
echo "Testing Bob CLI image..."
oc run test-bob --image=image-registry.openshift-image-registry.svc:5000/jenkins-project/sre-bob-cli:latest \
    --env="BOBSHELL_API_KEY=${BOBSHELL_API_KEY}" \
    --env="BOB_ACCEPT_LICENSE=true" \
    --command -- sleep 3600

sleep 10
oc exec test-bob -- bob -p "Reply with: TEST_OK" --hide-intermediary-output | grep -q "TEST_OK" && \
    echo "Bob CLI test: PASSED" || echo "Bob CLI test: FAILED"

oc delete pod test-bob

echo ""
echo "User1 setup test complete!"
```

### Concurrent Pipeline Test

```bash
#!/bin/bash
# test-concurrent-pipelines.sh
# Triggers pipelines for multiple users simultaneously

echo "=== Testing Concurrent Pipelines ==="

# Get Jenkins URL and credentials
JENKINS_URL="https://$(oc get route jenkins -n jenkins-project -o jsonpath='{.spec.host}')"
TOKEN=$(oc whoami -t)

# Trigger builds for users 1-5
for i in {1..5}; do
    echo "Triggering pipeline for user${i}..."
    curl -sk -X POST \
        -H "Authorization: Bearer ${TOKEN}" \
        "${JENKINS_URL}/job/user${i}/job/sre-pipeline/buildWithParameters?BRANCH=main&USER_PROJECT=user${i}-project" &
done

wait

echo ""
echo "Triggered 5 concurrent pipelines. Check Jenkins UI to verify."
echo "Jenkins URL: ${JENKINS_URL}"
```

---

## 7. Troubleshooting Guide

### Common Issues and Solutions

#### Issue: Bob sidecar can't authenticate

**Symptoms:**
```
Error: BOBSHELL_API_KEY not set or invalid
```

**Solution:**
```bash
# Verify secret exists
oc get secret bob-api-key -n jenkins-project

# Check secret content
oc get secret bob-api-key -n jenkins-project -o jsonpath='{.data.BOBSHELL_API_KEY}' | base64 -d

# Recreate secret if needed
oc delete secret bob-api-key -n jenkins-project
oc create secret generic bob-api-key \
    --from-literal=BOBSHELL_API_KEY="your-key-here" \
    -n jenkins-project
```

#### Issue: Jenkins agent can't pull Bob image

**Symptoms:**
```
Failed to pull image: ImagePullBackOff
```

**Solution:**
```bash
# Verify image exists
oc get is -n jenkins-project | grep bob

# Rebuild if needed
oc start-build sre-bob-cli-build --from-dir=k8s/openshift/bob-cli --follow

# Check image pull policy in Jenkinsfile (should be IfNotPresent or Always)
```

#### Issue: User can't see their Jenkins folder

**Symptoms:**
User logs into Jenkins but sees no folders or jobs.

**Solution:**
```bash
# Grant view access to Jenkins project
oc policy add-role-to-user view user1 -n jenkins-project

# Configure Jenkins authorization (in Jenkins UI):
# Manage Jenkins > Configure Global Security > Authorization
# Enable "Project-based Matrix Authorization Strategy"
# Add user1 with Read permission for folder "user1"
```

#### Issue: Pipeline can't deploy to user project

**Symptoms:**
```
Error: User "system:serviceaccount:jenkins-project:jenkins" cannot create deployments
```

**Solution:**
```bash
# Grant Jenkins SA edit access
oc policy add-role-to-user edit \
    system:serviceaccount:jenkins-project:jenkins \
    -n user1-project
```

---

## 8. Maintenance Procedures

### Adding a New User (user21)

```bash
#!/bin/bash
# add-user.sh user21

USER_NUM=$1
PROJECT="user${USER_NUM}-project"

echo "Adding ${PROJECT}..."

# Create project
oc new-project ${PROJECT}
oc label namespace ${PROJECT} lab-user="user${USER_NUM}" lab-type="participant"

# Grant Jenkins access
oc policy add-role-to-user edit \
    system:serviceaccount:jenkins-project:jenkins \
    -n ${PROJECT}

# Deploy application
oc project ${PROJECT}
oc adm policy add-scc-to-user anyuid -z default -n ${PROJECT}
oc apply -f k8s/order-db-deployment.yaml
oc apply -f k8s/order-db-service.yaml

# Create build and deploy order-service
oc new-build --binary --name=order-service-build --strategy=docker
oc start-build order-service-build --from-dir=order-service --follow
IMAGE="image-registry.openshift-image-registry.svc:5000/${PROJECT}/order-service-build:latest"
sed "s|IMAGE_PLACEHOLDER|${IMAGE}|g" k8s/order-service-deployment.yaml | oc apply -f -
oc apply -f k8s/order-service-service.yaml
oc expose svc/order-service

echo "${PROJECT} created successfully!"
echo "Next: Create Jenkins folder and job for user${USER_NUM}"
```

### Rotating Bob API Key

```bash
#!/bin/bash
# rotate-bob-api-key.sh

NEW_API_KEY=$1

if [ -z "$NEW_API_KEY" ]; then
    echo "Usage: ./rotate-bob-api-key.sh <new-api-key>"
    exit 1
fi

echo "Rotating Bob API key..."

# Update secret
oc delete secret bob-api-key -n jenkins-project
oc create secret generic bob-api-key \
    --from-literal=BOBSHELL_API_KEY="${NEW_API_KEY}" \
    -n jenkins-project

echo "API key rotated. New agent pods will use the new key."
echo "Existing running pipelines will continue with old key until completion."
```

---

## Summary

These examples provide everything needed to implement the multi-user Jenkins setup:

1. ✅ **Jenkins agent pod template** with Bob sidecar
2. ✅ **Updated askBob function** for sidecar communication
3. ✅ **Setup scripts** for automated deployment
4. ✅ **Jenkins job configuration** via DSL and JCasC
5. ✅ **RBAC examples** for proper isolation
6. ✅ **Testing procedures** to validate the setup
7. ✅ **Troubleshooting guide** for common issues
8. ✅ **Maintenance procedures** for ongoing operations

All scripts are production-ready and follow OpenShift/Kubernetes best practices.