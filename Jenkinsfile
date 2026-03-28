// ═══════════════════════════════════════════════════════════════════
// SRE Pipeline — Baseline (no Bob integration)
//
// This pipeline implements the client's 10-step regulated deployment
// flow. It runs linting, PCI compliance, tests, security scanning,
// an approval gate, ArgoCD deployment, and smoke tests — but has
// NO Bob AI calls. You will add them in the lab exercises.
//
// See labs/solution/Jenkinsfile.solution for the completed version.
// ═══════════════════════════════════════════════════════════════════

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
    image: image-registry.openshift-image-registry.svc:5000/sre-deploy-lab/sre-jenkins-agent:latest
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
        GITHUB_TOKEN = credentials('github-pat')
    }

    stages {

        // ── STEP 1: Checkout ────────────────────────────────────────────
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

        // ── STEP 2: Bob PR Analysis ───────────────────────────────────
        // ╔════════════════════════════════════════════════════════════╗
        // ║  EXERCISE 2: Add a Bob PR Analysis stage here             ║
        // ╚════════════════════════════════════════════════════════════╝

        // ── STEP 3: Standard Linting ──────────────────────────────────
        stage('Lint') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  STEP 3: Standard Linting"
                echo "══════════════════════════════════════════"
                dir('order-service') {
                    sh 'mvn checkstyle:check -q'
                }
                echo "Checkstyle passed."
            }
        }

        // ── STEP 4: PCI Compliance ────────────────────────────────────
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
                            echo "PCI compliance FAILED. Violations:\n${output}"
                        } else {
                            env.PCI_FAILED = 'false'
                            echo "PCI compliance check passed."
                        }
                    }

                    if (env.PCI_FAILED == 'true') {
                        unstable("PCI compliance check failed")
                    }
                }
            }
        }

        // ── STEP 5: Unit Tests ────────────────────────────────────────
        stage('Test') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  STEP 5: Running Unit Tests"
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

                            // ╔════════════════════════════════════════════════════╗
                            // ║  EXERCISE 3: Add Bob test failure analysis here    ║
                            // ╚════════════════════════════════════════════════════╝

                            echo "Tests FAILED:\n${testOutput}"
                        } else {
                            env.TEST_FAILED = 'false'
                        }
                    }

                    if (env.TEST_FAILED == 'true') {
                        unstable("Unit tests failed")
                    }
                }
            }
        }

        // ── STEP 6: Security Scan ─────────────────────────────────────
        stage('Security Scan') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  STEP 6: Security Vulnerability Scan"
                echo "══════════════════════════════════════════"
                script {
                    def scanResult = sh(
                        script: 'trivy fs --severity CRITICAL,HIGH --exit-code 0 order-service/ 2>&1 || true',
                        returnStdout: true
                    ).trim()

                    if (scanResult.contains('CRITICAL') || scanResult.contains('HIGH')) {
                        env.SECURITY_RISK = 'HIGH'
                        echo "Security scan found HIGH/CRITICAL vulnerabilities:\n${scanResult}"

                        // ╔════════════════════════════════════════════════════╗
                        // ║  EXERCISE 4: Add Bob security scan analysis here   ║
                        // ╚════════════════════════════════════════════════════╝

                        unstable("Security scan found HIGH/CRITICAL vulnerabilities")
                    } else {
                        env.SECURITY_RISK = 'LOW'
                        echo "No critical or high vulnerabilities found."
                    }
                }
            }
        }

        // ── STEP 7: Approval Gate ─────────────────────────────────────
        stage('Approval') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  STEP 7: Awaiting Approval"
                echo "══════════════════════════════════════════"
                script {
                    def pciStatus = env.PCI_FAILED == 'true' ? 'FAILED' : 'PASSED'
                    def testStatus = env.TEST_FAILED == 'true' ? 'FAILED' : 'PASSED'

                    // ╔════════════════════════════════════════════════════════════╗
                    // ║  EXTRA: Replace this manual summary with a                 ║
                    // ║  Bob-generated Deployment Change Request (DCR)             ║
                    // ╚════════════════════════════════════════════════════════════╝

                    try {
                        input message: """
Deployment Review
═════════════════
Branch:         ${params.BRANCH}
PCI Compliance: ${pciStatus}
Unit Tests:     ${testStatus} (${env.TEST_SUMMARY})
Security Risk:  ${env.SECURITY_RISK}

Do you approve this deployment?
""",
                            ok: 'Approve Deployment',
                            submitter: ''
                    } catch (e) {
                        echo "Deployment REJECTED."
                        error("Deployment rejected — aborted")
                    }
                    echo "Deployment APPROVED."
                }
            }
        }

        // ── STEP 8: Build Image ───────────────────────────────────────
        stage('Build Image') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  STEP 8: Build Container Image"
                echo "══════════════════════════════════════════"
                script {
                    dir('order-service') {
                        sh 'mvn package -DskipTests -q'
                    }

                    sh """
                    oc start-build order-service-build \
                        --from-dir=order-service \
                        --follow \
                        --wait 2>/dev/null || echo "Using existing image"
                    """

                    echo "Image built."
                }
            }
        }

        // ── STEP 9: Deploy via ArgoCD ─────────────────────────────────
        stage('Deploy via ArgoCD') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  STEP 9: ArgoCD Sync"
                echo "══════════════════════════════════════════"
                script {
                    echo "Triggering ArgoCD sync for order-service..."
                    sh """
                    oc patch application order-service -n openshift-gitops \
                        --type merge -p '{"operation":{"initiatedBy":{"username":"jenkins"},"sync":{"revision":"HEAD"}}}' \
                        2>/dev/null || echo "ArgoCD sync triggered"
                    """

                    echo "Waiting for ArgoCD sync..."
                    sh """
                    for i in \$(seq 1 30); do
                        HEALTH=\$(oc get application order-service -n openshift-gitops -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
                        SYNC=\$(oc get application order-service -n openshift-gitops -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
                        echo "  Sync: \$SYNC | Health: \$HEALTH"
                        if [ "\$HEALTH" = "Healthy" ] && [ "\$SYNC" = "Synced" ]; then
                            break
                        fi
                        sleep 10
                    done
                    """

                    sh "oc rollout status deployment/order-service --timeout=120s"
                    echo "Deployment complete."
                }
            }
        }

        // ── STEP 10: Smoke Tests ──────────────────────────────────────
        stage('Smoke Tests') {
            steps {
                echo "══════════════════════════════════════════"
                echo "  STEP 10: Post-Deployment Smoke Tests"
                echo "══════════════════════════════════════════"
                script {
                    sleep 10

                    def smokeOutput = sh(
                        script: 'bash pipeline/smoke-test.sh 2>&1 | tee ${WORKSPACE}/smoke-output.txt',
                        returnStdout: true
                    ).trim()

                    def smokeResult = sh(
                        script: 'bash pipeline/smoke-test.sh > /dev/null 2>&1; echo $?',
                        returnStdout: true
                    ).trim()

                    echo "Smoke Test Results:\n${smokeOutput}"

                    if (smokeResult != '0') {
                        env.DEPLOY_STATUS = 'DEGRADED'

                        // ╔════════════════════════════════════════════════════╗
                        // ║  EXTRA: Add Bob smoke test analysis here           ║
                        // ╚════════════════════════════════════════════════════╝

                        echo "Smoke tests detected issues."
                        unstable("Smoke tests failed")
                    } else {
                        env.DEPLOY_STATUS = 'HEALTHY'
                        echo "All smoke tests passed."
                    }
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
