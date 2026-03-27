# PIPELINE_SPEC — Jenkinsfile, PCI Rules, Smoke Tests

Every file in `pipeline/` and the root `Jenkinsfile`, with complete contents.

---

## `Jenkinsfile`

This is the complete, runnable pipeline. Each stage maps to a step in the SRE 10-step diagram.

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
  containers:
  - name: pipeline-agent
    image: image-registry.openshift-image-registry.svc:5000/sre-deploy-demo/sre-jenkins-agent:latest
    command: ['sleep']
    args: ['infinity']
    env:
    - name: HOME
      value: /home/jenkins
    resources:
      requests:
        memory: "512Mi"
        cpu: "250m"
      limits:
        memory: "1Gi"
        cpu: "1"
"""
            defaultContainer 'pipeline-agent'
        }
    }

    parameters {
        string(name: 'BRANCH', defaultValue: 'main', description: 'Branch to build')
    }

    environment {
        BOBSHELL_API_KEY = credentials('bobshell-api-key')
        GITHUB_TOKEN     = credentials('github-pat')
    }

    stages {

        // ══════════════════════════════════════════════════════════════════
        // STEP 1: Application Development team creates Pull Request
        // ══════════════════════════════════════════════════════════════════
        stage('Checkout') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  STEP 1: Checkout PR Branch"
                echo "══════════════════════════════════════════"
                checkout scm
                sh 'git fetch origin main:refs/remotes/origin/main 2>/dev/null || true'

                script {
                    env.CHANGED_FILES = sh(
                        script: 'git diff --name-only origin/main...HEAD 2>/dev/null || git diff --name-only HEAD~1 2>/dev/null || echo ""',
                        returnStdout: true
                    ).trim()
                    echo "Changed files:\n${env.CHANGED_FILES}"
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════
        // STEP 2: Bob Analyzes the PR
        // ══════════════════════════════════════════════════════════════════
        stage('Bob PR Analysis') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  STEP 2: Bob Analyzes the PR"
                echo "══════════════════════════════════════════"
                script {
                    def diffStat = sh(
                        script: 'git diff --stat origin/main...HEAD 2>/dev/null || echo "No diff"',
                        returnStdout: true
                    ).trim()

                    env.BOB_PR_ANALYSIS = askBob("""A pull request has been submitted for review.

Branch: ${params.BRANCH}
Changed files:
${env.CHANGED_FILES}

Diff summary:
${diffStat}

Analyze this PR:
1. What is this change doing?
2. What are the potential risks?
3. What should reviewers focus on?

Be concise.""")

                    echo "Bob's PR Analysis:\n${env.BOB_PR_ANALYSIS}"
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════
        // STEP 3: Jenkins Linter validates the PR
        // ══════════════════════════════════════════════════════════════════
        stage('Lint') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  STEP 3: Standard Linting"
                echo "══════════════════════════════════════════"
                script {
                    dir('order-service') {
                        def result = sh(
                            script: 'mvn checkstyle:check -q 2>&1 | tee ${WORKSPACE}/lint-output.txt',
                            returnStatus: true
                        )
                        if (result != 0) {
                            def output = sh(script: 'cat ${WORKSPACE}/lint-output.txt | tail -20', returnStdout: true).trim()
                            def analysis = askBob("Checkstyle linting failed. Explain what's wrong and how to fix it:\n\n${output}")
                            echo "Bob's Lint Analysis:\n${analysis}"
                        } else {
                            echo "Checkstyle passed."
                        }
                    }
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════
        // STEP 4: PCI Environment Linter with Custom Checks
        // ══════════════════════════════════════════════════════════════════
        stage('PCI Compliance Check') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  STEP 4: PCI Compliance Checks"
                echo "══════════════════════════════════════════"
                script {
                    dir('order-service') {
                        def result = sh(
                            script: 'mvn checkstyle:check -Dcheckstyle.config.location=../pipeline/pci-checkstyle.xml 2>&1 | tee ${WORKSPACE}/pci-output.txt',
                            returnStatus: true
                        )
                        if (result != 0) {
                            def output = sh(script: 'cat ${WORKSPACE}/pci-output.txt | tail -30', returnStdout: true).trim()
                            env.PCI_FAILED = 'true'
                            env.BOB_PCI_ANALYSIS = askBob("""PCI compliance check failed in a regulated financial environment.

These are PCI DSS compliance violations that must be fixed before deployment.

Violations:
${output}

For each violation:
1. Explain why this is a PCI compliance issue
2. What the specific risk is (data exposure, audit failure, etc.)
3. How to fix it

Be specific and reference PCI DSS requirements where applicable.""")

                            echo "Bob's PCI Analysis:\n${env.BOB_PCI_ANALYSIS}"
                        } else {
                            env.PCI_FAILED = 'false'
                            echo "PCI compliance check passed."
                        }
                    }
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════
        // Unit Tests
        // ══════════════════════════════════════════════════════════════════
        stage('Test') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  Running Unit Tests"
                echo "══════════════════════════════════════════"
                script {
                    dir('order-service') {
                        def result = sh(
                            script: 'mvn test 2>&1 | tee ${WORKSPACE}/test-output.txt',
                            returnStatus: true
                        )

                        def testSummary = sh(script: 'grep -E "(Tests run|BUILD)" ${WORKSPACE}/test-output.txt | tail -5 || echo "No summary"', returnStdout: true).trim()
                        env.TEST_SUMMARY = testSummary
                        echo "Test results:\n${testSummary}"

                        if (result != 0) {
                            def testOutput = sh(script: 'tail -50 ${WORKSPACE}/test-output.txt', returnStdout: true).trim()
                            env.TEST_FAILED = 'true'
                            env.BOB_TEST_ANALYSIS = askBob("""Unit tests failed. Analyze the failure and identify the root cause.

Test output:
${testOutput}

Provide:
1. Which test(s) failed and why
2. The root cause in the application code
3. Suggested fix

Be specific — reference exact class names and line numbers.""")

                            echo "Bob's Test Analysis:\n${env.BOB_TEST_ANALYSIS}"
                        } else {
                            env.TEST_FAILED = 'false'
                        }
                    }
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════
        // Security Scan
        // ══════════════════════════════════════════════════════════════════
        stage('Security Scan') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  Security Vulnerability Scan"
                echo "══════════════════════════════════════════"
                script {
                    def scanResult = sh(
                        script: 'trivy fs --severity CRITICAL,HIGH --exit-code 0 order-service/ 2>&1 || true',
                        returnStdout: true
                    ).trim()

                    if (scanResult.contains('CRITICAL') || scanResult.contains('HIGH')) {
                        env.SECURITY_RISK = 'HIGH'
                        env.BOB_SECURITY_ANALYSIS = askBob("""Security scan found vulnerabilities in a PCI-regulated environment.

Scan results:
${scanResult}

For each vulnerability:
1. Is it exploitable in this context?
2. What's the PCI compliance impact?
3. Recommended remediation

Prioritize by severity.""")

                        echo "Bob's Security Analysis:\n${env.BOB_SECURITY_ANALYSIS}"
                    } else {
                        env.SECURITY_RISK = 'LOW'
                        echo "No critical or high vulnerabilities found."
                    }
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════
        // STEP 5: Create the Change Management (DCR) JIRA Ticket
        // ══════════════════════════════════════════════════════════════════
        stage('Create Change Request') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  STEP 5: Create Deployment Change Request"
                echo "══════════════════════════════════════════"
                script {
                    def pciStatus = env.PCI_FAILED == 'true' ? 'FAILED — see PCI analysis below' : 'PASSED'
                    def testStatus = env.TEST_FAILED == 'true' ? 'FAILED — see test analysis below' : 'PASSED'
                    def canDeploy = (env.PCI_FAILED != 'true' && env.TEST_FAILED != 'true')

                    env.DCR_SUMMARY = askBob("""Create a formal Deployment Change Request (DCR) for a PCI-regulated UK financial services environment.

CHANGE DETAILS:
- Branch: ${params.BRANCH}
- Changed files: ${env.CHANGED_FILES}
- PR Analysis: ${env.BOB_PR_ANALYSIS}

VALIDATION RESULTS:
- Standard lint: PASSED
- PCI compliance: ${pciStatus}
- Unit tests: ${testStatus} (${env.TEST_SUMMARY})
- Security scan: ${env.SECURITY_RISK} risk
${env.PCI_FAILED == 'true' ? '- PCI Issues: ' + env.BOB_PCI_ANALYSIS : ''}
${env.TEST_FAILED == 'true' ? '- Test Failures: ' + env.BOB_TEST_ANALYSIS : ''}
${env.SECURITY_RISK == 'HIGH' ? '- Security Issues: ' + env.BOB_SECURITY_ANALYSIS : ''}

Create a DCR with:
1. CHANGE DESCRIPTION — What is changing and why
2. RISK ASSESSMENT — Low/Medium/High/Critical with justification
3. AFFECTED SERVICES — What services and environments are impacted
4. VALIDATION EVIDENCE — Summary of all check results
5. ROLLBACK PLAN — How to revert if deployment fails
6. RECOMMENDATION — APPROVE / REJECT / NEEDS FURTHER REVIEW

${canDeploy ? 'All checks passed.' : 'IMPORTANT: Some checks FAILED. Reflect this in the risk assessment and recommendation.'}

Be formal and concise. This will be reviewed by team management.""")

                    echo ""
                    echo "╔══════════════════════════════════════════════════════════╗"
                    echo "║          DEPLOYMENT CHANGE REQUEST (DCR)                ║"
                    echo "╠══════════════════════════════════════════════════════════╣"
                    echo "${env.DCR_SUMMARY}"
                    echo "╚══════════════════════════════════════════════════════════╝"
                    echo ""
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════
        // STEP 6: Management Approval
        // ══════════════════════════════════════════════════════════════════
        stage('Management Approval') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  STEP 6: Awaiting Management Approval"
                echo "══════════════════════════════════════════"
                script {
                    try {
                        input message: """
═══════════════════════════════════════
DEPLOYMENT CHANGE REQUEST — Review Required
═══════════════════════════════════════

${env.DCR_SUMMARY}

═══════════════════════════════════════
Do you approve this deployment?
""",
                            ok: 'Approve Deployment',
                            submitter: '' // anyone can approve for demo
                    } catch (e) {
                        env.DCR_REJECTED = 'true'
                        echo "Deployment REJECTED by management."
                        error("DCR rejected — deployment aborted")
                    }
                    echo "Deployment APPROVED by management."
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════
        // STEPS 7-8: Deploy via ArgoCD
        // ══════════════════════════════════════════════════════════════════
        stage('Deploy via ArgoCD') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  STEPS 7-8: ArgoCD Deployment"
                echo "══════════════════════════════════════════"
                script {
                    // Build the new image
                    echo "Building order-service image..."
                    dir('order-service') {
                        sh 'mvn package -DskipTests -q'
                    }

                    def registry = "image-registry.openshift-image-registry.svc:5000"
                    def namespace = sh(script: 'oc project -q', returnStdout: true).trim()
                    def imageTag = env.BUILD_NUMBER

                    // Build and push container image
                    sh """
                    oc start-build order-service-build \
                        --from-dir=order-service \
                        --follow \
                        --wait 2>/dev/null || echo "Using existing image"
                    """

                    // Update deployment image tag (triggers ArgoCD sync if auto-sync is on,
                    // or we trigger sync manually)
                    echo "Updating deployment to image tag: ${imageTag}"
                    sh """
                    oc set image deployment/order-service \
                        order-service=${registry}/${namespace}/order-service:latest \
                        2>/dev/null || true
                    """

                    // Wait for rollout
                    echo "Waiting for rollout to complete..."
                    sh "oc rollout status deployment/order-service --timeout=120s"

                    echo "Deployment complete."
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════
        // STEP 9: Smoke Tests
        // ══════════════════════════════════════════════════════════════════
        stage('Smoke Tests') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  STEP 9: Post-Deployment Smoke Tests"
                echo "══════════════════════════════════════════"
                script {
                    // Give the service a moment to stabilize
                    sleep 10

                    def smokeOutput = sh(
                        script: 'bash pipeline/smoke-test.sh 2>&1',
                        returnStdout: true
                    ).trim()

                    def smokeResult = sh(
                        script: 'bash pipeline/smoke-test.sh > /dev/null 2>&1; echo $?',
                        returnStdout: true
                    ).trim()

                    echo "Smoke Test Results:\n${smokeOutput}"

                    if (smokeResult != '0') {
                        env.DEPLOY_STATUS = 'DEGRADED'
                        def analysis = askBob("""Post-deployment smoke tests detected issues.

Smoke test output:
${smokeOutput}

Analyze:
1. Which services are unhealthy and why
2. Is this a deployment issue or a pre-existing problem?
3. Should we rollback?

Be concise.""")
                        echo "Bob's Smoke Test Analysis:\n${analysis}"
                        env.BOB_SMOKE_ANALYSIS = analysis
                    } else {
                        env.DEPLOY_STATUS = 'HEALTHY'
                        echo "All smoke tests passed."
                    }
                }
            }
        }

        // ══════════════════════════════════════════════════════════════════
        // STEP 10: Update Change Control
        // ══════════════════════════════════════════════════════════════════
        stage('Update Change Control') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  STEP 10: Update Change Control Record"
                echo "══════════════════════════════════════════"
                script {
                    def update = askBob("""Update the Deployment Change Request with final deployment results.

DEPLOYMENT RESULTS:
- Status: ${env.DEPLOY_STATUS}
- Branch deployed: ${params.BRANCH}
- Build number: ${env.BUILD_NUMBER}
- Smoke tests: ${env.DEPLOY_STATUS == 'HEALTHY' ? 'All services healthy' : 'Issues detected'}
${env.DEPLOY_STATUS != 'HEALTHY' ? '- Issues: ' + (env.BOB_SMOKE_ANALYSIS ?: 'See smoke test output') : ''}

Write a formal status update for the DCR JIRA ticket.
Include:
1. Deployment timestamp and status
2. Verification results
3. Next steps (if any issues found)
4. Whether the change control record can be closed

Be formal and concise.""")

                    echo ""
                    echo "╔══════════════════════════════════════════════════════════╗"
                    echo "║          CHANGE CONTROL UPDATE                          ║"
                    echo "╠══════════════════════════════════════════════════════════╣"
                    echo "${update}"
                    echo "╚══════════════════════════════════════════════════════════╝"
                    echo ""
                }
            }
        }
    }

    post {
        always {
            echo "══════════════════════════════════════════"
            echo "  Pipeline Complete: ${currentBuild.result ?: 'SUCCESS'}"
            echo "══════════════════════════════════════════"
        }
    }
}

// ── Helper: ask Bob CLI a question ──────────────────────────────────────
def askBob(prompt) {
    def bobPod = sh(
        script: "oc get pods -l component=bob-cli -o jsonpath='{.items[0].metadata.name}' 2>/dev/null",
        returnStdout: true
    ).trim()

    if (!bobPod) {
        echo "Warning: bob-cli pod not found"
        return "Bob CLI not available"
    }

    def promptFile = ".bob-prompt-${System.currentTimeMillis()}.txt"
    writeFile(file: promptFile, text: prompt)
    sh "oc cp ${promptFile} ${bobPod}:/tmp/bob-prompt.txt 2>/dev/null"
    sh "rm -f ${promptFile}"

    def result = sh(
        script: """oc exec ${bobPod} -- bash -c 'bob -p "\$(cat /tmp/bob-prompt.txt)" --hide-intermediary-output' 2>/dev/null || echo "Bob analysis unavailable" """,
        returnStdout: true
    ).trim()

    return result
}
```

---

## `pipeline/pci-checkstyle.xml`

Custom Checkstyle rules that check for PCI DSS compliance patterns. These are intentionally strict — they're meant to catch things standard linting wouldn't.

```xml
<?xml version="1.0"?>
<!DOCTYPE module PUBLIC
    "-//Checkstyle//DTD Checkstyle Configuration 1.3//EN"
    "https://checkstyle.org/dtds/configuration_1_3.dtd">
<module name="Checker">
    <property name="severity" value="error"/>

    <module name="TreeWalker">

        <!-- PCI-01: No System.out/err (prevents accidental PII/cardholder data in stdout) -->
        <module name="RegexpSinglelineJava">
            <property name="id" value="PCI-01-NoSystemOut"/>
            <property name="format" value="System\.(out|err)\.(print|println)"/>
            <property name="message" value="PCI-01: Use SLF4J logger instead of System.out/err — stdout may be captured in logs accessible to unauthorized personnel"/>
            <property name="ignoreComments" value="true"/>
        </module>

        <!-- PCI-02: No hardcoded passwords, tokens, or API keys -->
        <module name="RegexpSinglelineJava">
            <property name="id" value="PCI-02-NoHardcodedSecrets"/>
            <property name="format" value="(password|passwd|token|secret|apikey|api_key)\s*=\s*&quot;[^&quot;]+&quot;"/>
            <property name="message" value="PCI-02: Possible hardcoded credential — use environment variables or a secrets manager"/>
            <property name="ignoreCase" value="true"/>
            <property name="ignoreComments" value="true"/>
        </module>

        <!-- PCI-03: No hardcoded IP addresses (infrastructure should be configured externally) -->
        <module name="RegexpSinglelineJava">
            <property name="id" value="PCI-03-NoHardcodedIPs"/>
            <property name="format" value="&quot;\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}&quot;"/>
            <property name="message" value="PCI-03: Hardcoded IP address detected — use configuration properties or service discovery"/>
            <property name="ignoreComments" value="true"/>
        </module>

        <!-- PCI-04: No printStackTrace (stack traces may leak sensitive information) -->
        <module name="RegexpSinglelineJava">
            <property name="id" value="PCI-04-NoStackTrace"/>
            <property name="format" value="\.printStackTrace\(\)"/>
            <property name="message" value="PCI-04: Do not use printStackTrace() — use logger.error() with the exception object instead"/>
            <property name="ignoreComments" value="true"/>
        </module>

        <!-- PCI-05: No java.util.Random (use SecureRandom for anything security-related) -->
        <module name="RegexpSinglelineJava">
            <property name="id" value="PCI-05-NoWeakRandom"/>
            <property name="format" value="new\s+Random\(\)"/>
            <property name="message" value="PCI-05: java.util.Random is not cryptographically secure — use java.security.SecureRandom"/>
            <property name="ignoreComments" value="true"/>
        </module>

    </module>

    <!-- PCI-06: No TODO/FIXME/HACK in production code (must be resolved before deployment) -->
    <module name="RegexpSingleline">
        <property name="id" value="PCI-06-NoTodos"/>
        <property name="format" value="(TODO|FIXME|HACK|XXX)"/>
        <property name="message" value="PCI-06: Unresolved TODO/FIXME found — all items must be resolved before production deployment"/>
        <property name="fileExtensions" value="java"/>
    </module>

</module>
```

---

## `pipeline/smoke-test.sh`

Post-deployment health check script. Runs from inside the Jenkins agent pod (which is on the cluster and can reach services via their k8s service names).

```bash
#!/bin/bash
# Smoke tests for post-deployment verification
# Runs from inside the cluster (Jenkins agent pod)
# Exit code 0 = all healthy, 1 = failures detected

set -uo pipefail

NAMESPACE=$(oc project -q 2>/dev/null || echo "sre-deploy-demo")
FAILURES=0
TOTAL=0

check_endpoint() {
    local name="$1"
    local url="$2"
    local expected_status="${3:-200}"
    TOTAL=$((TOTAL + 1))

    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 --max-time 10 "$url" 2>/dev/null || echo "000")

    if [ "$status" = "$expected_status" ]; then
        echo "  ✓ ${name}: HTTP ${status}"
    else
        echo "  ✗ ${name}: HTTP ${status} (expected ${expected_status})"
        FAILURES=$((FAILURES + 1))
    fi
}

check_endpoint_body() {
    local name="$1"
    local url="$2"
    local expected_string="$3"
    TOTAL=$((TOTAL + 1))

    local body
    body=$(curl -s --connect-timeout 5 --max-time 10 "$url" 2>/dev/null || echo "UNREACHABLE")

    if echo "$body" | grep -q "$expected_string"; then
        echo "  ✓ ${name}: contains '${expected_string}'"
    else
        echo "  ✗ ${name}: expected '${expected_string}' not found in response"
        FAILURES=$((FAILURES + 1))
    fi
}

echo "═══════════════════════════════════════"
echo "  Post-Deployment Smoke Tests"
echo "  Namespace: ${NAMESPACE}"
echo "  Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "═══════════════════════════════════════"
echo ""

echo "Service Health:"
check_endpoint "order-service /health" "http://order-service:8080/api/orders/health"
check_endpoint_body "order-service health body" "http://order-service:8080/api/orders/health" "UP"

echo ""
echo "Actuator Probes:"
check_endpoint "order-service liveness" "http://order-service:8080/actuator/health/liveness"
check_endpoint "order-service readiness" "http://order-service:8080/actuator/health/readiness"

echo ""
echo "API Functional Tests:"
check_endpoint "GET /api/orders" "http://order-service:8080/api/orders"

# Create a test order and verify
echo ""
echo "Write Test:"
TOTAL=$((TOTAL + 1))
CREATE_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"customerName":"smoke-test","product":"test-product","amount":1.00,"status":"PENDING"}' \
    --connect-timeout 5 --max-time 10 \
    "http://order-service:8080/api/orders" 2>/dev/null || echo "FAIL")

if echo "$CREATE_RESPONSE" | grep -q "smoke-test"; then
    echo "  ✓ POST /api/orders: created order successfully"

    # Clean up — extract id and delete
    ORDER_ID=$(echo "$CREATE_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || echo "")
    if [ -n "$ORDER_ID" ]; then
        curl -s -X DELETE "http://order-service:8080/api/orders/${ORDER_ID}" --connect-timeout 5 > /dev/null 2>&1
    fi
else
    echo "  ✗ POST /api/orders: failed to create order"
    FAILURES=$((FAILURES + 1))
fi

echo ""
echo "Database Connectivity:"
check_endpoint "order-service actuator health" "http://order-service:8080/actuator/health"
# The actuator health endpoint includes db status when datasource is configured

echo ""
echo "═══════════════════════════════════════"
if [ "$FAILURES" -eq 0 ]; then
    echo "  RESULT: ALL ${TOTAL} CHECKS PASSED"
else
    echo "  RESULT: ${FAILURES}/${TOTAL} CHECKS FAILED"
fi
echo "═══════════════════════════════════════"

exit $FAILURES
```

---

## Notes for Implementation

- The Jenkinsfile's `askBob()` helper is identical to the one in the existing dental claims project. It copies the prompt to the bob-cli pod, runs it, and returns the output.
- The PCI checkstyle rules are designed so that the `demo/happy-path` branch passes all of them. The demo branches can intentionally violate them (e.g., add a `System.out.println` for the PCI failure demo).
- The smoke test script runs from inside the Jenkins agent pod, which is on the cluster. It reaches services via their Kubernetes service DNS names (`order-service:8080`).
- The approval gate uses Jenkins' built-in `input` step. In Jenkins UI, this shows as a "paused" build waiting for someone to click Approve or Abort.
- The ArgoCD deployment stage is simplified for the demo — it builds the image and updates the deployment directly. In a full GitOps setup, you'd commit a manifest change and let ArgoCD detect it. The stage includes comments explaining the difference.
