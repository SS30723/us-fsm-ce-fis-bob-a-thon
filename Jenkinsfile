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

                        def analysis = askBob(prompt, 'solution-pipeline-git-diff-overview')

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

                            def analysis = askBob(prompt, 'solution-pipeline-test-failure-analyzer')

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

        stage('DCR') {
            options {
                timeout(time: 5, unit: 'MINUTES')
            }
            steps {
                script {
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        echo '════════════════════════════════════════════════════════'
                        echo '  📋 Deployment Change Request (DCR) Generation'
                        echo '════════════════════════════════════════════════════════'

                        // Gather change material into workspace files
                        sh '''
                            git config --global --add safe.directory "$WORKSPACE"
                            
                            # Commit log
                            git log origin/main..HEAD --pretty=format:'%h %s' > dcr-commits.txt || : > dcr-commits.txt
                            
                            # Diffstat
                            git diff origin/main...HEAD --stat > dcr-diffstat.txt || : > dcr-diffstat.txt
                            
                            # Context metadata
                            echo "BUILD_NUMBER=${BUILD_NUMBER}" > dcr-context.txt
                            echo "BRANCH=$(git rev-parse --abbrev-ref HEAD)" >> dcr-context.txt
                            echo "JIRA_PROJECT=KAN" >> dcr-context.txt
                        '''

                        // Build prompt for Bob
                        def prompt = """
Read the following files and produce a Deployment Change Request (DCR) per the mode's rules:

- dcr-commits.txt (commit history)
- dcr-diffstat.txt (file change statistics)
- dcr-context.txt (build metadata)
- bob-pr-review.md (if present)
- bob-test-analysis.md (if present)

Generate a comprehensive DCR document suitable for filing as a Jira ticket.
"""

                        // Invoke Bob with DCR mode
                        def dcr = askBob(prompt, 'solution-pipeline-dcr-jira-reporter')

                        echo dcr
                        echo '════════════════════════════════════════════════════════'

                        // Save DCR for archiving
                        writeFile file: 'deployment-change-request.md', text: dcr
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'deployment-change-request.md,dcr-*.txt',
                                   allowEmptyArchive: true,
                                   fingerprint: true
                }
            }
        }

        stage('Security Analysis') {
            options {
                timeout(time: 15, unit: 'MINUTES')
            }
            environment {
                SONAR_TOKEN = credentials('sonarqube-token')
                SONAR_HOST_URL = 'https://sonarqube-sonarqube.apps.itz-8ggai0.infra01-lb.wdc04.techzone.ibm.com'
                PROJECT_KEY = "order-service-${env.USER}-${env.BUILD_NUMBER}"
            }
            steps {
                script {
                    // Initialize serializable results map with String primitives only
                    def securityResults = [
                        sonarqube: [:],
                        grype: [:],
                        riskLevel: '',
                        riskScore: 0,
                        deploymentDecision: ''
                    ]

                    echo '════════════════════════════════════════════════════════'
                    echo '  🔒 Security Analysis - Multi-Phase Scanning'
                    echo '════════════════════════════════════════════════════════'

                    // ═══════════════════════════════════════════════════════
                    // Phase 1: SonarQube Security Scanning
                    // ═══════════════════════════════════════════════════════
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        echo ''
                        echo '📊 Phase 1: SonarQube Security Scanning'
                        echo '─────────────────────────────────────────────────────'

                        container('build-tools') {
                            // Single quotes so $SONAR_TOKEN is expanded by the
                            // shell at runtime, not interpolated by Groovy into
                            // the rendered command (which Jenkins warns about
                            // as insecure secret handling).
                            sh '''
                                cd order-service
                                mvn clean test-compile sonar:sonar \
                                    -Dsonar.projectKey=$PROJECT_KEY \
                                    -Dsonar.host.url=$SONAR_HOST_URL \
                                    -Dsonar.token=$SONAR_TOKEN
                            '''
                        }

                        echo '⏳ Waiting for SonarQube analysis to complete...'

                        // Phase 1a: Wait for task completion
                        def taskStatus = ''
                        def maxRetries = 12
                        def retryDelay = 10

                        for (int i = 0; i < maxRetries; i++) {
                            try {
                                sleep(retryDelay)
                                
                                container('build-tools') {
                                    taskStatus = sh(
                                        script: '''
                                            curl -s -u "$SONAR_TOKEN:" \
                                                "$SONAR_HOST_URL/api/ce/component?component=$PROJECT_KEY" \
                                                | grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4
                                        ''',
                                        returnStdout: true
                                    ).trim()
                                }

                                echo "  Attempt ${i+1}/${maxRetries}: Task status = ${taskStatus}"

                                if (taskStatus == 'SUCCESS') {
                                    echo '✅ SonarQube analysis completed successfully'
                                    break
                                } else if (taskStatus == 'FAILED') {
                                    echo '❌ SonarQube analysis failed'
                                    error('SonarQube task failed')
                                }
                            } catch (Exception e) {
                                echo "  Warning: Task status check failed: ${e.message}"
                                if (i == maxRetries - 1) {
                                    throw e
                                }
                            }
                        }

                        if (taskStatus != 'SUCCESS') {
                            error('SonarQube analysis did not complete in time')
                        }

                        // Phase 1b: Fetch metrics after task completion
                        echo '📈 Fetching SonarQube metrics...'
                        
                        def metricsJson = null
                        def sonarData = null
                        maxRetries = 6
                        retryDelay = 5

                        for (int i = 0; i < maxRetries; i++) {
                            try {
                                sleep(retryDelay)
                                
                                container('build-tools') {
                                    metricsJson = sh(
                                        script: '''
                                            curl -s -u "$SONAR_TOKEN:" \
                                                "$SONAR_HOST_URL/api/measures/component?component=$PROJECT_KEY&metricKeys=bugs,vulnerabilities,code_smells,security_hotspots,security_rating,reliability_rating,security_review_rating"
                                        ''',
                                        returnStdout: true
                                    ).trim()
                                }

                                // Parse JSON using Groovy JsonSlurper
                                sonarData = readJSON text: metricsJson

                                if (sonarData?.component?.measures && sonarData.component.measures.size() > 0) {
                                    echo "✅ Successfully fetched ${sonarData.component.measures.size()} metrics"
                                    break
                                } else {
                                    echo "  Attempt ${i+1}/${maxRetries}: Metrics not ready yet"
                                }
                            } catch (Exception e) {
                                echo "  Warning: Metrics fetch failed: ${e.message}"
                                if (i == maxRetries - 1) {
                                    throw e
                                }
                            }
                        }

                        // Store metrics as String primitives
                        if (sonarData?.component?.measures) {
                            sonarData.component.measures.each { measure ->
                                securityResults.sonarqube[measure.metric] = measure.value ?: '0'
                            }
                        }

                        // Clear JSON object to avoid serialization issues
                        sonarData = null

                        echo ''
                        echo '📊 SonarQube Results:'
                        echo "  Bugs: ${securityResults.sonarqube.bugs ?: '0'}"
                        echo "  Vulnerabilities: ${securityResults.sonarqube.vulnerabilities ?: '0'}"
                        echo "  Code Smells: ${securityResults.sonarqube.code_smells ?: '0'}"
                        echo "  Security Hotspots: ${securityResults.sonarqube.security_hotspots ?: '0'}"
                        echo "  Security Rating: ${securityResults.sonarqube.security_rating ?: 'N/A'}"
                    }

                    // ═══════════════════════════════════════════════════════
                    // Phase 2: Grype Vulnerability Scanning
                    // ═══════════════════════════════════════════════════════
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        echo ''
                        echo '🔍 Phase 2: Grype Vulnerability Scanning'
                        echo '─────────────────────────────────────────────────────'

                        container('build-tools') {
                            // Install Grype on-demand
                            echo '📦 Installing Grype...'
                            sh '''
                                curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
                                grype version
                            '''

                            // Run Grype scan
                            echo '🔎 Scanning for vulnerabilities...'
                            sh '''
                                cd order-service
                                grype dir:. --scope all-layers -o json > grype-report.json || true
                            '''

                            // Parse the report once via readJSON. Counting by
                            // grep'ing "severity" out of the raw JSON would
                            // over-count, because each match has a severity on
                            // vulnerability AND on every relatedVulnerabilities
                            // entry.
                            def report = readJSON file: 'order-service/grype-report.json'
                            def criticalCount = 0
                            def highCount = 0
                            def mediumCount = 0
                            report.matches.each { m ->
                                switch (m.vulnerability?.severity) {
                                    case 'Critical': criticalCount++; break
                                    case 'High':     highCount++;     break
                                    case 'Medium':   mediumCount++;   break
                                }
                            }
                            // Drop the parsed object so CPS doesn't try to
                            // serialize it across steps (same pattern as Phase 1).
                            report = null

                            // Store as Integer primitives
                            securityResults.grype.critical = criticalCount
                            securityResults.grype.high = highCount
                            securityResults.grype.medium = mediumCount
                            securityResults.grype.total = criticalCount + highCount + mediumCount

                            echo ''
                            echo '🔍 Grype Results:'
                            echo "  Critical: ${criticalCount}"
                            echo "  High: ${highCount}"
                            echo "  Medium: ${mediumCount}"
                            echo "  Total: ${securityResults.grype.total}"
                        }
                    }

                    // ═══════════════════════════════════════════════════════
                    // Phase 3: CVE Analysis with Bob (conditional)
                    // ═══════════════════════════════════════════════════════
                    def bobAnalysis = ''
                    def deploymentRecommendation = 'PROCEED'

                    if (securityResults.grype.total > 0) {
                        catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                            echo ''
                            echo '🤖 Phase 3: Bob CVE Analysis'
                            echo '─────────────────────────────────────────────────────'

                            def prompt = """
Perform comprehensive CVE and security analysis based on the following results:

=== SONARQUBE RESULTS ===
Bugs: ${securityResults.sonarqube.bugs ?: '0'}
Vulnerabilities: ${securityResults.sonarqube.vulnerabilities ?: '0'}
Code Smells: ${securityResults.sonarqube.code_smells ?: '0'}
Security Hotspots: ${securityResults.sonarqube.security_hotspots ?: '0'}
Security Rating: ${securityResults.sonarqube.security_rating ?: 'N/A'}

=== GRYPE VULNERABILITY SCAN ===
Critical CVEs: ${securityResults.grype.critical}
High CVEs: ${securityResults.grype.high}
Medium CVEs: ${securityResults.grype.medium}
Total Vulnerabilities: ${securityResults.grype.total}

Please provide:
1. **Risk Assessment**: Overall security posture evaluation
2. **Top 3 Vulnerabilities**: Most critical issues requiring immediate attention
3. **Remediation Steps**: Specific actions to address vulnerabilities
4. **Deployment Recommendation**: One of:
   - BLOCK: Critical issues prevent deployment
   - WARN: Issues present but deployment possible with caution
   - PROCEED: Safe to deploy

Format your response with clear sections and end with:
DEPLOYMENT RECOMMENDATION: [BLOCK|WARN|PROCEED]
"""

                            bobAnalysis = askBob(prompt, null)  // Use default 'code' mode

                            echo bobAnalysis
                            writeFile file: 'bob-cve-analysis.txt', text: bobAnalysis

                            // Extract deployment recommendation
                            if (bobAnalysis.contains('DEPLOYMENT RECOMMENDATION: BLOCK')) {
                                deploymentRecommendation = 'BLOCK'
                            } else if (bobAnalysis.contains('DEPLOYMENT RECOMMENDATION: WARN')) {
                                deploymentRecommendation = 'WARN'
                            } else if (bobAnalysis.contains('DEPLOYMENT RECOMMENDATION: PROCEED')) {
                                deploymentRecommendation = 'PROCEED'
                            }

                            echo ''
                            echo "🎯 Bob Recommendation: ${deploymentRecommendation}"
                        }
                    } else {
                        echo ''
                        echo '✅ Phase 3: Skipped (no vulnerabilities detected)'
                        bobAnalysis = 'No vulnerabilities detected by Grype scan.'
                        writeFile file: 'bob-cve-analysis.txt', text: bobAnalysis
                    }

                    // ═══════════════════════════════════════════════════════
                    // Phase 4: Risk Level Calculation
                    // ═══════════════════════════════════════════════════════
                    echo ''
                    echo '📊 Phase 4: Risk Level Calculation'
                    echo '─────────────────────────────────────────────────────'

                    // Parse SonarQube String values to Integer safely
                    def bugs = 0
                    def vulnerabilities = 0
                    def hotspots = 0

                    try {
                        bugs = Integer.parseInt(securityResults.sonarqube.bugs ?: '0')
                    } catch (Exception e) {
                        echo "Warning: Could not parse bugs count: ${e.message}"
                    }

                    try {
                        vulnerabilities = Integer.parseInt(securityResults.sonarqube.vulnerabilities ?: '0')
                    } catch (Exception e) {
                        echo "Warning: Could not parse vulnerabilities count: ${e.message}"
                    }

                    try {
                        hotspots = Integer.parseInt(securityResults.sonarqube.security_hotspots ?: '0')
                    } catch (Exception e) {
                        echo "Warning: Could not parse hotspots count: ${e.message}"
                    }

                    // Calculate risk score
                    def riskScore = (vulnerabilities * 10) +
                                   (hotspots * 5) +
                                   (bugs * 2) +
                                   (securityResults.grype.critical * 20) +
                                   (securityResults.grype.high * 10)

                    securityResults.riskScore = riskScore

                    // Determine risk level
                    def riskLevel = 'LOW'
                    if (riskScore >= 50) {
                        riskLevel = 'CRITICAL'
                    } else if (riskScore >= 30) {
                        riskLevel = 'HIGH'
                    } else if (riskScore >= 10) {
                        riskLevel = 'MEDIUM'
                    }

                    securityResults.riskLevel = riskLevel

                    echo "  Risk Score: ${riskScore}"
                    echo "  Risk Level: ${riskLevel}"

                    // ═══════════════════════════════════════════════════════
                    // Phase 5: Deployment Decision
                    // ═══════════════════════════════════════════════════════
                    echo ''
                    echo '🚦 Phase 5: Deployment Decision'
                    echo '─────────────────────────────────────────────────────'

                    if (riskLevel == 'CRITICAL') {
                        securityResults.deploymentDecision = 'BLOCK'
                        echo '🔴 BLOCK: Critical security issues detected'
                        echo '   Deployment is blocked until issues are resolved'
                        currentBuild.result = 'UNSTABLE'
                    } else if (riskLevel == 'HIGH') {
                        securityResults.deploymentDecision = 'WARN'
                        echo '🟡 WARN: High-risk issues detected'
                        echo '   Manual review recommended before deployment'
                    } else {
                        securityResults.deploymentDecision = 'PROCEED'
                        echo '🟢 PROCEED: Security posture acceptable'
                        echo '   Deployment approved'
                    }

                    // Override with Bob's recommendation if more restrictive
                    if (deploymentRecommendation == 'BLOCK' && securityResults.deploymentDecision != 'BLOCK') {
                        securityResults.deploymentDecision = 'BLOCK'
                        echo ''
                        echo '⚠️  Bob analysis recommends BLOCK - overriding decision'
                        currentBuild.result = 'UNSTABLE'
                    }

                    // ═══════════════════════════════════════════════════════
                    // Phase 6: Consolidated Report Generation
                    // ═══════════════════════════════════════════════════════
                    echo ''
                    echo '📝 Phase 6: Generating Consolidated Report'
                    echo '─────────────────────────────────────────────────────'

                    def report = """# Security Analysis Report

## Executive Summary

**Build**: ${env.BUILD_NUMBER}
**Date**: ${new Date()}
**Risk Level**: ${securityResults.riskLevel}
**Risk Score**: ${securityResults.riskScore}
**Deployment Decision**: ${securityResults.deploymentDecision}

---

## SonarQube Analysis

| Metric | Value |
|--------|-------|
| Bugs | ${securityResults.sonarqube.bugs ?: '0'} |
| Vulnerabilities | ${securityResults.sonarqube.vulnerabilities ?: '0'} |
| Code Smells | ${securityResults.sonarqube.code_smells ?: '0'} |
| Security Hotspots | ${securityResults.sonarqube.security_hotspots ?: '0'} |
| Security Rating | ${securityResults.sonarqube.security_rating ?: 'N/A'} |
| Reliability Rating | ${securityResults.sonarqube.reliability_rating ?: 'N/A'} |

**SonarQube Dashboard**: ${SONAR_HOST_URL}/dashboard?id=${PROJECT_KEY}

---

## Grype Vulnerability Scan

| Severity | Count |
|----------|-------|
| Critical | ${securityResults.grype.critical} |
| High | ${securityResults.grype.high} |
| Medium | ${securityResults.grype.medium} |
| **Total** | **${securityResults.grype.total}** |

---

## Bob CVE Analysis

${bobAnalysis}

---

## Deployment Recommendation

**Decision**: ${securityResults.deploymentDecision}

${securityResults.deploymentDecision == 'BLOCK' ? '🔴 **BLOCKED**: Critical security issues must be resolved before deployment.' : ''}
${securityResults.deploymentDecision == 'WARN' ? '🟡 **WARNING**: Manual security review recommended before proceeding with deployment.' : ''}
${securityResults.deploymentDecision == 'PROCEED' ? '🟢 **APPROVED**: Security posture is acceptable for deployment.' : ''}

---

*Generated by Jenkins Security Analysis Pipeline*
"""

                    writeFile file: 'security-analysis-report.md', text: report

                    echo '✅ Report generated: security-analysis-report.md'
                    echo ''
                    echo '════════════════════════════════════════════════════════'
                    echo '  Security Analysis Complete'
                    echo "  Risk Level: ${securityResults.riskLevel}"
                    echo "  Decision: ${securityResults.deploymentDecision}"
                    echo '════════════════════════════════════════════════════════'
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'security-analysis-report.md,bob-cve-analysis.txt,order-service/grype-report.json',
                                   allowEmptyArchive: true,
                                   fingerprint: true
                }
            }
        }

        stage('Run Linters') {
            options {
                timeout(time: 10, unit: 'MINUTES')
            }
            steps {
                script {
                    echo '════════════════════════════════════════════════════════'
                    echo '  🔍 Running Linters'
                    echo '════════════════════════════════════════════════════════'

                    // Create lint-results directory
                    sh 'mkdir -p lint-results'

                    // Run Checkstyle
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        echo ''
                        echo '📋 Running Checkstyle...'
                        sh '''
                            mvn -f order-service/pom.xml checkstyle:check || true
                            if [ -f order-service/target/checkstyle-result.xml ]; then
                                cp order-service/target/checkstyle-result.xml lint-results/checkstyle.xml
                                echo "✅ Checkstyle report saved"
                            else
                                echo "⚠️  Checkstyle report not found"
                            fi
                        '''
                    }

                    // Run Hadolint
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        echo ''
                        echo '🐳 Running Hadolint...'
                        container('lint-tools') {
                            sh '''
                                hadolint order-service/Dockerfile > lint-results/hadolint.txt 2>&1 || true
                                if [ -s lint-results/hadolint.txt ]; then
                                    echo "✅ Hadolint report saved"
                                else
                                    echo "✅ No Hadolint issues found" > lint-results/hadolint.txt
                                fi
                            '''
                        }
                    }

                    // Run Checkov
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        echo ''
                        echo '☁️  Running Checkov...'
                        container('lint-tools') {
                            sh '''
                                checkov -d order-service/deploy-flawed/ --compact --quiet > lint-results/checkov.txt 2>&1 || true
                                if [ -s lint-results/checkov.txt ]; then
                                    echo "✅ Checkov report saved"
                                else
                                    echo "✅ No Checkov issues found" > lint-results/checkov.txt
                                fi
                            '''
                        }
                    }

                    // Run KubeLinter
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        echo ''
                        echo '☸️  Running KubeLinter...'
                        container('lint-tools') {
                            sh '''
                                kube-linter lint order-service/deploy-flawed/ > lint-results/kubelinter.txt 2>&1 || true
                                if [ -s lint-results/kubelinter.txt ]; then
                                    echo "✅ KubeLinter report saved"
                                else
                                    echo "✅ No KubeLinter issues found" > lint-results/kubelinter.txt
                                fi
                            '''
                        }
                    }

                    echo ''
                    echo '════════════════════════════════════════════════════════'
                    echo '  Linting Complete'
                    echo '════════════════════════════════════════════════════════'
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'lint-results/*',
                                   allowEmptyArchive: true,
                                   fingerprint: true
                }
            }
        }

        stage('Bob Lint Analysis') {
            when {
                expression {
                    return fileExists('lint-results/checkstyle.xml') ||
                           fileExists('lint-results/hadolint.txt') ||
                           fileExists('lint-results/checkov.txt') ||
                           fileExists('lint-results/kubelinter.txt')
                }
            }
            options {
                timeout(time: 10, unit: 'MINUTES')
            }
            steps {
                script {
                    catchError(buildResult: 'UNSTABLE', stageResult: 'FAILURE') {
                        echo '════════════════════════════════════════════════════════'
                        echo '  🤖 Bob Lint Analysis'
                        echo '════════════════════════════════════════════════════════'

                        def prompt = """
Analyze the linting results from multiple tools and provide a consolidated report.

Read and analyze the following files:
- lint-results/checkstyle.xml
- lint-results/hadolint.txt
- lint-results/checkov.txt
- lint-results/kubelinter.txt

Also review the source files for context:
- order-service/src/
- order-service/Dockerfile
- order-service/deploy-flawed/

Provide:
1. **Findings by Severity**: Group all findings by severity (Critical, High, Medium, Low)
2. **De-duplication**: Identify and consolidate overlapping findings from different tools
3. **Top Priority Issues**: List the 3-5 highest-priority issues that should be fixed first
4. **Concrete Fixes**: For each top priority issue, provide specific remediation steps with code examples
5. **Summary Statistics**: Count of issues by tool and severity

Format the output in markdown with clear sections.
"""

                        def analysis = askBob(prompt, 'solution-pipeline-lint-analyzer')

                        echo analysis
                        writeFile file: 'bob-lint-report.md', text: analysis

                        echo ''
                        echo '────────────────────────────────────────────────────────'
                        echo '  Generating PR Comment'
                        echo '────────────────────────────────────────────────────────'

                        def prCommentPrompt = """
Read bob-lint-report.md and create a concise PR comment summary.

The comment should:
- Be brief (max 15 lines)
- Highlight only the most critical findings
- Use emoji for visual clarity
- Include a quick stats summary
- End with a link reference to the full report

Format as markdown suitable for a GitHub PR comment.
"""

                        def prComment = askBob(prCommentPrompt, 'solution-pipeline-lint-analyzer')

                        echo prComment
                        writeFile file: 'bob-lint-pr-comment.md', text: prComment

                        echo ''
                        echo '════════════════════════════════════════════════════════'
                        echo '  📊 Lint Analysis Summary'
                        echo '════════════════════════════════════════════════════════'

                        // Print short summary
                        def summaryLines = analysis.split('\n').findAll { line ->
                            line.contains('Critical') || line.contains('High') ||
                            line.contains('Total') || line.contains('Priority')
                        }.take(5)

                        summaryLines.each { line ->
                            echo "  ${line.trim()}"
                        }

                        echo ''
                        echo '  📄 Full report: bob-lint-report.md (archived)'
                        echo '  💬 PR comment: bob-lint-pr-comment.md (archived)'
                        echo '════════════════════════════════════════════════════════'
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'bob-lint-report.md,bob-lint-pr-comment.md',
                                   allowEmptyArchive: true,
                                   fingerprint: true
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