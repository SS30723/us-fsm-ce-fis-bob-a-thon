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

// Per-instance Jira credential routing. Each pipeline self-selects which
// jira-creds-{a..n} secret to mount based on the user number parsed
// from its job name. See setup/JIRA_ACCOUNT_SETUP.md Section 3.3.
//
// Users are paired across 14 Jira accounts:
//   user1/2 -> jira-creds-a, user3/4 -> jira-creds-b, ...,
//   user27/28 -> jira-creds-n. user29+ share user28's instance
//   (jira-creds-n) — we only provisioned 14 Jira accounts.
//
// @NonCPS keeps the regex Matcher object inside this method so it never
// becomes a CPS-serialized local variable (Matcher is not Serializable
// and would crash the pipeline on checkpoint).
@NonCPS
def routeJiraSecret(String jobName) {
    def m = jobName =~ /user0*(\d+)/
    if (!m) return 'jira-creds-n'
    int userNum = m[0][1].toInteger()
    if (userNum < 1) return 'jira-creds-n'
    def letters = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n']
    int letterIdx = Math.min((userNum - 1).intdiv(2), 13)
    return "jira-creds-${letters[letterIdx]}"
}

def jiraSecret = routeJiraSecret(env.JOB_NAME ?: '')

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
  - name: lint-tools
    image: image-registry.openshift-image-registry.svc:5000/jenkins/lint-tools:latest
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
    - name: JIRA_URL
      valueFrom:
        secretKeyRef:
          name: ${jiraSecret}
          key: JIRA_URL
    - name: JIRA_USERNAME
      valueFrom:
        secretKeyRef:
          name: ${jiraSecret}
          key: JIRA_USERNAME
    - name: JIRA_API_TOKEN
      valueFrom:
        secretKeyRef:
          name: ${jiraSecret}
          key: JIRA_API_TOKEN
    - name: JIRA_PROJECT
      valueFrom:
        secretKeyRef:
          name: ${jiraSecret}
          key: JIRA_PROJECT
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

        stage('PR Review') {
            steps {
                script {
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        echo '════════════════════════════════════════════════════════'
                        echo '  Bob PR Review Analysis'
                        echo '════════════════════════════════════════════════════════'

                        sh '''
                            git config --global --add safe.directory "$WORKSPACE"
                            git diff origin/main...HEAD > git-diff.txt || : > git-diff.txt
                        '''

                        def prompt = """
Read git-diff.txt and produce a concise PR overview with:
- Summary
- Risk
- Watch for
"""

                        def analysis = askBob(prompt, 'pipeline-git-diff-overview')

                        echo analysis
                        echo '════════════════════════════════════════════════════════'

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

        stage('Unit Tests') {
            steps {
                script {
                    echo '════════════════════════════════════════════════════════'
                    echo '  Running Unit Tests'
                    echo '════════════════════════════════════════════════════════'

                    // Run tests and capture result, continue even if tests fail
                    def testResult = sh(
                        script: 'mvn -f order-service/pom.xml test',
                        returnStatus: true
                    )

                    echo "Test exit code: ${testResult}"

                    // Publish JUnit results
                    junit testResults: 'order-service/target/surefire-reports/*.xml',
                          allowEmptyResults: true

                    // If tests failed, analyze with Bob
                    if (testResult != 0) {
                        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                            echo '════════════════════════════════════════════════════════'
                            echo '  Bob Test Failure Analysis'
                            echo '════════════════════════════════════════════════════════'

                            def prompt = """
Analyze the test failures in order-service/target/surefire-reports/ and the relevant source files under order-service/src/.

Provide:
1. Root cause of each failure
2. Whether failures are related
3. Suggested fixes with code examples
4. Priority of fixes (critical, high, medium, low)
"""

                            def analysis = askBob(prompt, 'pipeline-test-failure-analyzer')

                            echo analysis
                            echo '════════════════════════════════════════════════════════'

                            writeFile file: 'bob-test-analysis.md', text: analysis
                        }
                    } else {
                        echo '✅ All tests passed'
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'bob-test-analysis.md',
                                   allowEmptyArchive: true
                }
            }
        }

        // ── Lab 1: PR / Git Diff Review ──────────────────────────
        //    Add a stage here that runs Bob in a "senior developer"
        //    mode against the git diff. See labs/LAB1_PR_REVIEW.md.

        // ── Lab 2: Unit Testing ──────────────────────────────────
        //    Add a mvn test stage + Bob test-failure analysis.
        //    See labs/LAB2_UNIT_TESTING.md.

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

// ── Helper: ask Bob, optionally with a specific custom mode ───────────────────
// Writes the prompt to a tempfile in the shared workspace and runs `bob` in
// the bob container, adding `--chat-mode <slug>` only when a mode is provided.
// Returns the analysis as a string. Using a tempfile (instead of inlining the
// prompt on the command line) avoids shell-escaping issues when the prompt
// contains quotes, backticks, or newlines — common with diffs.
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