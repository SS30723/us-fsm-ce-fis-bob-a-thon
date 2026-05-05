// ═══════════════════════════════════════════════════════════════════
// FIS Bob-a-thon — Base Pipeline (Jenkinsfile)
//
// Starting point for the 5-lab workshop. Provisions a Kubernetes
// agent pod with three containers — build-tools (Maven + JDK17),
// oc-tools (OpenShift CLI), and bob (IBM Bob CLI) — sharing a
// workspace-volume emptyDir mounted at /workspace on all three,
// with HOME set to /workspace so Bob can read .bob/custom_modes.yaml
// from the checkout.
//
// This file has a single Checkout stage. Each lab adds one more
// stage beneath it; see labs/LAB<N>_*.md for instructions.
//
// Before running: if your OpenShift project is NOT named `jenkins`,
// update the `bob` container image URL below.
// ═══════════════════════════════════════════════════════════════════

pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: build-tools
    image: maven:3.9-eclipse-temurin-17
    command: ['sleep', 'infinity']
    workingDir: /workspace
    volumeMounts:
    - name: workspace-volume
      mountPath: /workspace
    env:
    - name: HOME
      value: /workspace
  - name: oc-tools
    image: quay.io/openshift/origin-cli:latest
    command: ['sleep', 'infinity']
    workingDir: /workspace
    volumeMounts:
    - name: workspace-volume
      mountPath: /workspace
    env:
    - name: HOME
      value: /workspace
  - name: bob
    image: image-registry.openshift-image-registry.svc:5000/jenkins/bob-cli:latest
    command: ['sleep', 'infinity']
    workingDir: /workspace
    volumeMounts:
    - name: workspace-volume
      mountPath: /workspace
    env:
    - name: BOBSHELL_API_KEY
      valueFrom:
        secretKeyRef:
          name: bob-cli-credentials
          key: BOBSHELL_API_KEY
    - name: BOB_ACCEPT_LICENSE
      value: "true"
    - name: HOME
      value: /workspace
  volumes:
  - name: workspace-volume
    emptyDir: {}
"""
            defaultContainer 'build-tools'
        }
    }

    stages {
        stage('Checkout') {
            steps {
                echo "=== Checking out repository ==="
                checkout scm

                echo "=== Verifying workspace contents ==="
                sh '''
                    echo "Current directory: $(pwd)"
                    echo "Workspace contents:"
                    ls -la
                '''
            }
        }

        // ── Lab 1: PR / Git Diff Review ──────────────────────────
        stage('PR Review') {
            options {
                timeout(time: 5, unit: 'MINUTES')
            }
            steps {
                script {
                    echo '════════════════════════════════════════════════════════'
                    echo '  Bob — PR Review'
                    echo '════════════════════════════════════════════════════════'
                    
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        // Configure git safe directory and compute diff
                        sh '''
                            git config --global --add safe.directory "$WORKSPACE"
                            git diff origin/main...HEAD > git-diff.txt || : > git-diff.txt
                        '''
                        
                        // Ask Bob to analyze the diff
                        def analysis = askBob(
                            "Read git-diff.txt and produce the senior-developer PR overview.",
                            'solution-pipeline-git-diff-overview'
                        )
                        
                        echo analysis
                        echo '════════════════════════════════════════════════════════'
                        
                        // Save analysis for archiving
                        writeFile file: 'bob-pr-review.md', text: analysis
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'bob-pr-review.md', allowEmptyArchive: true
                }
            }
        }

        // ── Lab 2: Unit Testing ──────────────────────────────────
        stage('Unit Tests') {
            options {
                timeout(time: 5, unit: 'MINUTES')
            }
            steps {
                script {
                    echo '════════════════════════════════════════════════════════'
                    echo '  Running Unit Tests'
                    echo '════════════════════════════════════════════════════════'
                    
                    // Run tests in build-tools container, continue even if tests fail
                    catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {
                        sh 'mvn -f order-service/pom.xml test'
                    }
                }
            }
            post {
                always {
                    // Publish JUnit test results
                    junit testResults: 'order-service/target/surefire-reports/*.xml',
                          allowEmptyResults: true
                }
            }
        }

        stage('Bob Test Analysis') {
            when {
                expression {
                    // Only run if test reports exist
                    fileExists('order-service/target/surefire-reports')
                }
            }
            options {
                timeout(time: 5, unit: 'MINUTES')
            }
            steps {
                script {
                    echo '════════════════════════════════════════════════════════'
                    echo '  Bob — Test Failure Analysis'
                    echo '════════════════════════════════════════════════════════'
                    
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        // Gather test reports
                        def reports = sh(
                            script: 'find order-service/target/surefire-reports -name "*.txt" -exec cat {} + || true',
                            returnStdout: true
                        ).trim()
                        
                        // Build prompt for Bob
                        def prompt = """
Analyze the test failures from the surefire reports under order-service/target/surefire-reports/
and the relevant source files under order-service/src/.

Provide:
1. Root cause of each failure
2. Whether failures are related
3. Suggested fixes with code examples
4. Priority of fixes

Test Reports:
${reports}
"""
                        
                        // Ask Bob to analyze
                        def analysis = askBob(prompt, 'pipeline-test-failure-analyzer')
                        
                        echo analysis
                        echo '════════════════════════════════════════════════════════'
                        
                        // Save analysis for archiving
                        writeFile file: 'bob-test-analysis.md', text: analysis
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'bob-test-analysis.md', allowEmptyArchive: true
                }
            }
        }

        // ── Lab 3: Security Scanning ─────────────────────────────
        //    Add a scanner stage + Bob CVE/vuln analysis.
        //    See labs/LAB3_SECURITY_SCANNING.md.

        // ── Lab 4: Linting ───────────────────────────────────────
        //    Add a lint stage + Bob lint analysis + parse and post
        //    Jenkins report as a PR comment.
        //    See labs/LAB4_LINTING.md.

        // ── Lab 5: DCR & Reporting ───────────────────────────────
        //    Add a DCR generation stage; Bob pushes the result to
        //    Jira via the Jira MCP server.
        //    See labs/LAB5_DCR_REPORTING.md.
    }

    post {
        always {
            echo "=== Pipeline Complete ==="
            echo "Result: ${currentBuild.result ?: 'SUCCESS'}"
        }
    }
}

def askBob(String prompt, String mode = null) {
    container('bob') {
        def promptFile = ".bob-prompt-${System.currentTimeMillis()}.txt"
        writeFile file: promptFile, text: prompt

        def modeFlag = mode ? "--chat-mode ${mode}" : ""
        def analysis = sh(
            script: """bob ${modeFlag} -p "\$(cat ${promptFile})" --hide-intermediary-output""",
            returnStdout: true
        ).trim()

        sh "rm -f ${promptFile}"
        return analysis
    }
}