# Lab 3: Security Vulnerability Analysis & Pipeline Integration

**Objective:** Learn how to perform security analysis with Bob Findings, run automated scans with SonarQube, and integrate comprehensive security checks into a CI/CD pipeline.

 
**Difficulty:** Intermediate  
**Prerequisites:** 
- Setup complete (order-service, SonarQube, Jenkins running)
- Bob CLI configured
- Basic understanding of security concepts

---

## Lab Overview

In this lab, you will:
1. Inject security vulnerabilities into the order-service code
2. Perform manual security analysis with Bob
3. Run automated SonarQube security scans
4. Generate comprehensive security reports
5. Enhance the Jenkins pipeline with security stages
6. Create CVE analysis prompts for pipeline integration

## Table of Contents

- [Lab Overview](#lab-overview)
- [Before you start](#before-you-start)
- [Part 1: Inject Security Vulnerabilities](#part-1-inject-security-vulnerabilities)
  - [Step 1.1: Review Bob Findings Before Injection](#step-11-review-bob-findings-before-injection)
  - [Step 1.2: Run the Vulnerability Injection Script](#step-12-run-the-vulnerability-injection-script)
  - [Step 1.3: Review Bob Findings After Injection](#step-13-review-bob-findings-after-injection)
- [Part 2: Security Analysis with Software Security Reviewer Mode](#part-2-security-analysis-with-software-security-reviewer-mode)
  - [Step 2.1: Import the Software Security Reviewer Mode](#step-21-import-the-software-security-reviewer-mode)
  - [Step 2.2: Perform Comprehensive Security Analysis](#step-22-perform-comprehensive-security-analysis)
  - [Step 2.3: Review Security Findings](#step-23-review-security-findings)
- [Part 3: SonarQube Security Scanning](#part-3-sonarqube-security-scanning)
  - [Step 3.1: Generate SonarQube Token](#step-31-generate-sonarqube-token)
  - [Step 3.2: Run SonarQube Scan](#step-32-run-sonarqube-scan)
  - [Step 3.3: Review SonarQube Results](#step-33-review-sonarqube-results)
- [Part 4: Enhance Jenkins Pipeline](#part-4-enhance-jenkins-pipeline)
  - [Step 4.1: Add Comprehensive Security Stage](#step-41-add-comprehensive-security-stage)
- [Part 5: CVE Analysis Prompt](#part-5-cve-analysis-prompt)
  - [Step 5.1: Create CVE Analysis Prompt](#step-51-create-cve-analysis-prompt)
  - [Step 5.2: Test CVE Analysis](#step-52-test-cve-analysis)
- [Part 6: Push and Watch](#part-6-push-and-watch)
  - [Step 6.1: Restore Original Code](#step-61-restore-original-code)
  - [Step 6.2: Commit and Push Changes](#step-62-commit-and-push-changes)
- [Lab Summary](#lab-summary)

---
---

## Before you start

- [ ] Lab 2 complete (your Jenkinsfile already has a PR Review stage and the askBob helper)
- [ ] You're on your working branch (e.g. `user1-labs`)


## Part 1: Inject Security Vulnerabilities

### Step 1.1: Review Bob Findings Before Injection

Select **Bob Findings** at the bottom of the screen. You will observe that it is currently empty. This is expected, as no vulnerabilities have been injected into the file yet, so Bob has no findings to display.

### Step 1.2: Run the Vulnerability Injection Script

> **Note:** Ensure you are in **Code Mode** before proceeding with this step.

**Prompt to Bob:**
```
Bob run script inject_vulnerabilities_modify_existing.sh
```

**What Bob does:**
- Executes `pipeline/inject_vulnerabilities_modify_existing.sh`
- Modifies `order-service/src/main/java/com/example/orders/service/OrderService.java`
- Injects 6 types of vulnerabilities:
  1. Hardcoded credentials (BACKUP_DB_PASSWORD, LEGACY_API_KEY)
  2. Insecure logging (System.out.println)
  3. Weak cryptography (MD5)
  4. Stack trace exposure (printStackTrace)
  5. Weak random (java.util.Random)
  6. Information exposure (detailed error messages)
- Creates backup file: `OrderService.java.backup`

**Expected Output:**
```
🔧 Modifying existing OrderService.java with vulnerabilities...
✅ Vulnerabilities injected into OrderService.java
📍 Modified: order-service/src/main/java/com/example/orders/service/OrderService.java
📍 Backup:   order-service/src/main/java/com/example/orders/service/OrderService.java.backup
```

**Verification:**
```bash
# Check that vulnerabilities were injected
grep -n "BACKUP_DB_PASSWORD\|LEGACY_API_KEY\|System.out\|MD5\|printStackTrace\|Random" \
  order-service/src/main/java/com/example/orders/service/OrderService.java
```

### Step 1.3: Review Bob Findings After Injection

Now that vulnerabilities have been injected, let's see what Bob detects in real-time:

1. **Open the modified file:**
   - Navigate to: `order-service/src/main/java/com/example/orders/service/OrderService.java`
   - Open the file in Bob's editor

2. **Check Bob Findings:**
   - Click **"Bob Findings"** at the bottom of the screen
   - Bob will analyze the file and identify security issues in real-time
   - You should see inline warnings and highlights for the injected vulnerabilities

3. **Review the inline findings:**
   - Bob will highlight issues like:
     - 🔴 Hardcoded credentials (lines 19-20)
     - 🔴 Insecure logging patterns
     - 🔴 Weak cryptography (MD5)
     - 🟡 Stack trace exposure
     - 🟡 Weak random generation
     - 🟡 Information disclosure

This gives you a preview of what Bob detects at the code level before we perform a comprehensive security analysis in Part 2.

---

## Part 2: Security Analysis with Software Security Reviewer Mode

### Step 2.1: Import the Software Security Reviewer Mode

Bob has a specialized **Software Security Reviewer** mode that provides comprehensive security analysis. Let's import it:

1. **Locate the mode file:**
   - Navigate to: `labs/lab3/software-security-reviewer.yaml`

2. **Import the mode into Bob:**
   - Click the **Settings icon** (⚙️) in the top right corner of Bob
   - Click **"Modes"** in the settings menu
   - Click **"Import"** button
   - Select the file: `labs/lab3/software-security-reviewer.yaml`
   - Click **"Import"** to confirm

3. **Verify the mode was imported:**
   - You should see **"🛡️🔐 Software Security Reviewer"** in your modes list
   - Close the settings panel

### Step 2.2: Switch to Software Security Reviewer Mode

1. **Change Bob's mode:**
   - Click the current mode indicator at the top of Bob (e.g., "💻 Code")
   - Select **"🛡️🔐 Software Security Reviewer"** from the dropdown
   - Bob is now in security analysis mode

2. **Verify mode switch:**
   - The mode indicator should show: **"🛡️🔐 Software Security Reviewer"**

### Step 2.3: Generate Comprehensive Security Analysis Report

Now let's have Bob perform a full security audit of the order-service application.

**Prompt to Bob:**
```
Evaluate order-service for vulnerabilities, insecure patterns, misconfigurations, and compliance gaps and generate an analysis report.
```

**What Bob does:**
- Creates a TODO list to track the security analysis process
- Scans all application files (Java code, configuration, Dockerfile, K8s manifests)
- Identifies security vulnerabilities and insecure patterns
- Analyzes compliance gaps (PCI DSS, OWASP Top 10)
- Evaluates misconfigurations in infrastructure
- Generates comprehensive security report: `SECURITY_ANALYSIS_REPORT.md`

**Expected Output:**

A detailed security analysis report containing:

**Executive Summary:**
- 🔴 **CRITICAL RISK RATING** - Application must not be deployed
- **25 total findings:** 9 Critical, 9 High, 7 Medium
- Deployment blocking recommendation

**Critical Findings (9):**
1. Hardcoded credentials in source code (OrderService.java)
2. API keys logged in plain text
3. No authentication on API endpoints
4. Insecure Direct Object Reference (IDOR)
5-9. Hardcoded credentials in infrastructure (Dockerfile, K8s manifests)

**High-Priority Vulnerabilities (9):**
10. Sensitive customer data logged
11. MD5 hash for verification codes
12-13. Stack trace exposure
14. Information disclosure in error messages
15. No rate limiting
16. Actuator endpoints exposed
17. No database encryption
18. No TLS for database connection
19. Order status logged

**Medium-Priority Issues (7):**
20. Weak random number generator
21. Missing input validation
22. Outdated Spring Boot version
23. Container runs as root
24. No security headers
25. No CORS configuration
26. No audit logging

**Additional Sections:**
- 📊 Threat model diagram
- 🎯 Attack scenarios
- 🔧 Remediation roadmap (Immediate, Short-term, Long-term)
- ✅ Compliance mapping (PCI DSS, OWASP, CWE)
- 📋 Testing recommendations

**Verification:**
```bash
# Check report was created
ls -lh SECURITY_ANALYSIS_REPORT.md

# View executive summary
head -100 SECURITY_ANALYSIS_REPORT.md

# Count findings by severity
grep -c "CRITICAL" SECURITY_ANALYSIS_REPORT.md
grep -c "HIGH" SECURITY_ANALYSIS_REPORT.md
grep -c "MEDIUM" SECURITY_ANALYSIS_REPORT.md
```

**How This Complements Bob Findings:**

The Software Security Reviewer mode builds upon Bob's inline findings to provide a comprehensive security assessment:

| Feature | Bob Findings (Inline) | Software Security Reviewer |
|---------|----------------------|---------------------------|
| **Scope** | Single file analysis | Full application (code + infrastructure) |
| **Detection** | Real-time as you code | Comprehensive audit on demand |
| **Findings** | 6 code-level issues | 25 issues across all layers |
| **Context** | Line-by-line warnings | Application-wide security posture |
| **Output** | Inline highlights | Detailed report with remediation |

**Complementary Strengths:**

1. **Bob Findings** (Part 1.3):
   - ✅ Immediate feedback while coding
   - ✅ Catches issues as you write code
   - ✅ Focuses on code-level vulnerabilities
   - ✅ Perfect for developer workflow

2. **Software Security Reviewer** (Part 2):
   - ✅ Expands to infrastructure security (Dockerfile, K8s manifests)
   - ✅ Adds compliance mapping (PCI DSS, OWASP, CWE)
   - ✅ Provides threat modeling and attack scenarios
   - ✅ Includes prioritized remediation roadmap
   - ✅ Perfect for security audits and reviews

**Together, they provide:**
- 🔍 **Real-time detection** (Bob Findings) + **Comprehensive analysis** (Security Reviewer)
- 💻 **Code-level issues** + **Infrastructure vulnerabilities**
- ⚡ **Developer feedback** + **Security team reporting**
- 🎯 **Immediate fixes** + **Strategic remediation planning**

---

## Part 3: SonarQube Security Scanning

### Step 3.1: Create SonarQube Token

> **Note:** Switch back to **Code Mode** before proceeding with this step.

**Your instructor will provide the SonarQube cluster URL.**

Once you have the URL, use Bob to generate your token.

**Prompt to Bob:**
```
Run the following to create a token for SonarQube: curl -u demo:Demo123lab123@ -X POST "https://sonarqube-sonarqube.apps.itz-8ggai0.infra01-lb.wdc04.techzone.ibm.com/api/user_tokens/generate?name=order-service-scan-$(date +%s)" 2>/dev/null
```

**Example with actual URL:**
```
Run the following to create a token for SonarQube: curl -u demo:Demo123lab123@ -X POST "https://sonarqube-sonarqube.apps.itz-8ggai0.infra01-lb.wdc04.techzone.ibm.com/api/user_tokens/generate?name=order-service-scan-$(date +%s)" 2>/dev/null
```

**What Bob does:**
- Executes the curl command to generate a SonarQube token
- Authenticates using the demo user credentials
- Creates a uniquely named token with timestamp

**Expected Output:**
```json
{
  "login": "demo",
  "name": "order-service-scan-1775587069",
  "token": "squ_4fbcce9dfc4e594d2e00f9265a9daa338b558a9b",
  "createdAt": "2026-04-07T14:37:49-0400",
  "type": "USER_TOKEN"
}
```

**Extract just the token (if you have jq installed):**
```bash
curl -u demo:Demo123lab123@ -X POST "https://sonarqube-sonarqube.apps.itz-8ggai0.infra01-lb.wdc04.techzone.ibm.com/api/user_tokens/generate?name=order-service-scan-$(date +%s)" 2>/dev/null | jq -r '.token'
```

**Save the token** - you'll need it for the next step.

**Note:** The demo user credentials are:
- Username: `demo`
- Password: `Demo123lab123@`

### Step 3.2: Run SonarQube Scan

**Prompt to Bob:**
```
Scan order-service with SonarQube and generate an analysis report
```

**What Bob does:**
1. Uses the SonarQube URL from Step 3.1
2. Uses the generated token from Step 3.1
3. Automatically fills in the URL and token in the Maven command
4. Runs the scan with `-DskipTests` (tests fail due to injected vulnerabilities)
5. Fetches issues from SonarQube API
6. Retrieves project metrics
7. Generates comprehensive report: `SonarQube_Analysis_Report.md`

**Bob will execute:**
```bash
cd order-service && mvn clean compile sonar:sonar \
  -Dsonar.projectKey=order-service \
  -Dsonar.host.url=https://sonarqube-sonarqube.apps.itz-8ggai0.infra01-lb.wdc04.techzone.ibm.com \
  -Dsonar.login=<GENERATED_TOKEN> \
  -DskipTests
```

Where:
- `https://sonarqube-sonarqube.apps.itz-8ggai0.infra01-lb.wdc04.techzone.ibm.com` = The SonarQube cluster URL
- `<GENERATED_TOKEN>` = The token generated in Step 3.1 (e.g., `squ_4fbcce9dfc4e594d2e00f9265a9daa338b558a9b`)

**Bob automatically fills in these values from the previous step.**

**Expected Output (Initial Test Failure):**
```
The tests are failing as expected (the injected vulnerabilities broke the validation logic).
Let me skip the tests and run the SonarQube scan directly.
```

Bob will then run:
```bash
cd order-service && mvn clean compile sonar:sonar \
  -Dsonar.projectKey=order-service \
  -Dsonar.host.url=https://sonarqube-sonarqube.apps.itz-8ggai0.infra01-lb.wdc04.techzone.ibm.com \
  -Dsonar.login=<GENERATED_TOKEN>  \
  -DskipTests
```

**Expected Scan Results:**
```
[INFO] ANALYSIS SUCCESSFUL
[INFO] Analysis report uploaded
[INFO] Dashboard: http://localhost:9000/dashboard?id=order-service
```

**Note:** The test failures are intentional. The injected vulnerabilities broke the `validateStatusTransition` method, causing tests that expect validation to fail. This is expected behavior and demonstrates how security issues can impact functionality.

**Metrics:**
- Lines of Code: 295
- Bugs: 2
- Vulnerabilities: 1
- Code Smells: 8
- Security Hotspots: 4
- Technical Debt: 130 minutes

**Key Issues Detected:**
1. 🔴 **BLOCKER** - java:S2068 - Hardcoded password (Line 19)
2. 🔴 **CRITICAL** - java:S2119 - Insecure Random (Line 116)
3. 🟠 **MAJOR** - java:S106 - System.out usage (Lines 47, 60, 82, 133)
4. 🟠 **MAJOR** - java:S112 - Generic exceptions (Line 128)

**Verification:**
```bash
# Check report was created
ls -lh SonarQube_Analysis_Report.md

# View SonarQube dashboard
open http://localhost:9000/dashboard?id=order-service
```

### Step 3.3: Compare Bob vs SonarQube Findings

**Key Observation:**
✅ **100% Correlation** - All 6 vulnerabilities identified by Bob were confirmed by SonarQube:
- Hardcoded credentials ✓
- Insecure logging ✓
- Weak cryptography (MD5) ✓
- Stack trace exposure ✓
- Weak random generation ✓
- Information exposure ✓

**Additional SonarQube Findings:**
- Unused private fields
- Unused method parameters
- Generic wildcard usage
- Math.abs edge case

---

## Part 4: Enhance Jenkins Pipeline

### Step 4.1: Add Comprehensive Security Stage

> **Note:** Switch to **Jenkins Pipeline Integration** mode before proceeding with this step.

**Prompt to Bob:**
```
Use the information from Security Analysis Report and SonarQube Analysis Report to create Security Stage to jenkinsfile
```

**What Bob does:**
- Reads existing `Jenkinsfile`
- Enhances Stage 6 (Security Analysis) with comprehensive multi-layer security checks
- Adds 6 security scan layers:
  1. **Secret Scanning** - Detects hardcoded passwords, API keys, tokens, and credentials
  2. **SonarQube Static Analysis** - Automated token generation, quality metrics, and security hotspots
  3. **Dependency Vulnerability Scan** - Uses Trivy to scan for CRITICAL/HIGH vulnerabilities
  4. **Code Pattern Security Checks** - Detects insecure logging, stack trace exposure, weak crypto, weak PRNG
  5. **Configuration Security Checks** - Scans Kubernetes manifests and Dockerfiles for security issues
  6. **Risk Assessment & Reporting** - Calculates overall risk level and generates comprehensive reports
- Implements risk-based deployment gates (CRITICAL/HIGH/MEDIUM/LOW)
- Generates detailed security artifacts and reports
- **BLOCKS deployment** if CRITICAL issues are detected

**Enhanced Security Stage Features:**

**6 Security Check Layers:**
```groovy
// 6.1: Secret Scanning
grep -r "password=|api_key=|token=" --include="*.java" --include="*.properties" --include="*.yaml"

// 6.2: SonarQube Static Analysis
# Auto-generates token, runs analysis, fetches metrics and security hotspots
mvn sonar:sonar -Dsonar.projectKey=order-service

// 6.3: Dependency Vulnerability Scan
trivy fs --severity CRITICAL,HIGH order-service/

// 6.4: Code Pattern Security Checks
grep -r "System.out.println|printStackTrace|MD5|java.util.Random" order-service/

// 6.5: Configuration Security Checks
# Scans K8s manifests for hardcoded credentials
# Checks Dockerfile for missing USER directive

// 6.6: Risk Assessment & Reporting
# Calculates SECURITY_RISK level and generates comprehensive reports
```

**Security Risk Levels:**
- **🔴 CRITICAL:** Any critical issues detected → **BLOCKS deployment** (Pipeline fails)
- **🟠 HIGH:** High-severity issues detected → Pipeline marked unstable, review required
- **🟡 MEDIUM:** Security hotspots require review → Pipeline continues, manual review recommended
- **🟢 LOW:** No critical/high issues → Pipeline continues normally

**Generated Artifacts:**
- `SECURITY_REPORT.txt` - Comprehensive security summary
- `security-secrets.txt` - Hardcoded secrets detected (if any)
- `security-hotspots.txt` - SonarQube security hotspots (if any)
- `security-dependencies.txt` - Dependency vulnerabilities (if any)

**Security Metrics Tracked:**
- `SECURITY_CRITICAL` - Count of critical security issues
- `SECURITY_HIGH` - Count of high-severity issues
- `SECURITY_MEDIUM` - Count of medium-severity issues
- `SECURITY_HOTSPOTS` - Count of SonarQube security hotspots
- `SECURITY_RISK` - Overall risk level (CRITICAL/HIGH/MEDIUM/LOW)

**Verification:**
```bash
# Check Jenkinsfile was updated
git diff Jenkinsfile

# Verify security stage exists
grep -A 50 "stage('Security Scan')" Jenkinsfile
```

---

## Part 5: CVE Analysis Prompt

### Step 5.1: Create CVE Analysis Prompt

> **Note:** Ensure you are in **Code mode** before proceeding with this step.

**Prompt to Bob:**
```
Write prompt for CVE analysis on pipeline as a txt file in pipeline/cve-analysis-prompt.txt
```

**What Bob does:**
- Creates `pipeline/cve-analysis-prompt.txt`
- Comprehensive prompt template for CVE analysis
- Includes input data structure, analysis requirements, output format
- Provides example analysis
- Integration instructions for Jenkins

**Prompt Features:**
- CVE prioritization framework
- Risk assessment methodology
- Remediation guidance templates
- False positive analysis
- Deployment decision matrix
- PCI DSS compliance focus
- Example CVE analysis

**Verification:**
```bash
# Check prompt was created
ls -lh pipeline/cve-analysis-prompt.txt

# View prompt structure
head -100 pipeline/cve-analysis-prompt.txt
```

### Step 5.2: Add the CVE Analysis Prompt to the Pipeline

> **Note:** Switch to **Jenkins Pipeline Integration** mode before proceeding with this step.

**Prompt to Bob:**
```text
Use pipeline/cve-analysis-prompt.txt to add a CVE analysis step to the Jenkins pipeline.
```

**What Bob does:**
- Reads `pipeline/cve-analysis-prompt.txt`
- Updates `Jenkinsfile` to include a CVE analysis step in the security workflow
- Ensures the pipeline can use scan results as input for CVE evaluation
- Generates a CVE analysis report when applicable
- Incorporates the CVE findings into the pipeline security decision

**Expected Pipeline Behavior:**
- If no critical or high CVEs are detected, the pipeline skips detailed CVE analysis or records a clean result
- If critical or high CVEs are detected, the pipeline runs CVE analysis using the prompt
- The pipeline generates `CVE_ANALYSIS_REPORT.md`
- CVE findings contribute to the final security summary and deployment decision

**Verification:**
```bash
# Check Jenkinsfile includes CVE analysis logic
grep -A 50 -i "CVE\|cve-analysis-prompt" Jenkinsfile

# Review the pipeline changes
git diff Jenkinsfile
```

---

## Part 6: Push and Watch

### Step 6.1: Restore Original Code

Before pushing to git, we need to restore the original code by removing the injected vulnerabilities.

> **Note:** Ensure you are in **Code mode** before proceeding with this step.

**Prompt to Bob:**
```
Bob run script restore_vulnerabilities.sh
```

**What Bob does:**
- Executes `labs/sre/lab3/restore_vulnerabilities.sh`
- Restores the original `OrderService.java` from the backup file
- Removes the injected vulnerabilities
- Cleans up backup files

**Expected Output:**
```
🔄 Restoring original OrderService.java...
✅ Original code restored
📍 Restored: order-service/src/main/java/com/example/orders/service/OrderService.java
```

### Step 6.2: Commit and Push Changes

**Prompt to Bob:**
```
git add Jenkinsfile .bob/ labs/sre/lab3/
git commit -m "Lab 3 — Security Analysis stage with vulnerability scanning and CVE analysis"
git push
```

In Jenkins, click **Build Now** on your pipeline and watch the console.

**Expected:**

- `Checkout` and `PR Review` stages turn green
- `Security Scan` stage runs with multiple security checks:
  - Secret scanning detects hardcoded credentials
  - SonarQube analysis identifies security hotspots
  - Dependency vulnerability scan runs
  - Code pattern checks flag insecure practices
  - Configuration security checks validate K8s/Docker configs
  - Risk assessment calculates overall security posture
- Security reports are generated and archived as build artifacts:
  - `Security_Analysis_Report.md` - Bob's comprehensive security analysis
  - `SonarQube_Analysis_Report.md` - SonarQube findings
  - `CVE_ANALYSIS_REPORT.md` - CVE analysis (if vulnerabilities detected)
  - `SECURITY_REPORT.txt` - Pipeline security summary
- Pipeline may turn **UNSTABLE (yellow)** or **FAILURE (red)** depending on severity of findings
- Build page lists all security reports under **Build Artifacts**

Open the archived artifacts from the build page to review:
- Bob's detailed security analysis with remediation guidance
- SonarQube's quality gate status and security hotspots
- CVE analysis with risk assessment and deployment recommendations

**Note:** The security stage is designed to block deployment if CRITICAL issues are detected. Review the console output and security reports to understand what needs to be fixed before the next deployment.

For detailed pipeline execution and troubleshooting, refer to `labs/sre/lab3/PIPELINE_EXECUTION_GUIDE.md`.

**Recommended workflow after finishing this lab:**
```bash
# Commit the lab outputs
git add Jenkinsfile Security_Analysis_Report.md SonarQube_Analysis_Report.md pipeline/cve-analysis-prompt.txt
git commit -m "lab: add comprehensive security analysis"

# Push changes so Jenkins can build the updated pipeline
git push origin main
```

Then follow `labs/lab3/PIPELINE_EXECUTION_GUIDE.md` step by step to test the pipeline in Jenkins.

**Expected Pipeline Behavior with injected vulnerabilities:**
1. Checkout stage passes
2. Lint stage passes
3. PCI Compliance stage reports violations
4. Test stage may fail due to intentionally broken validation logic
5. Security Scan stage detects critical/high-risk findings
6. Overall security risk is expected to be **CRITICAL**
7. Deployment is expected to be **BLOCKED** until issues are remediated

**Validation Checklist:**
- Confirm the pipeline starts successfully in Jenkins
- Confirm SonarQube analysis runs and publishes results
- Confirm the security summary is generated
- Confirm the pipeline blocks deployment when critical findings are present
- Confirm you can review reports and determine remediation actions using the guide

---

## Lab Summary

### What You Accomplished

✅ **Injected Vulnerabilities:**
- 6 types of security vulnerabilities in OrderService.java
- Realistic security issues (hardcoded credentials, weak crypto, etc.)

✅ **Manual Security Analysis:**
- Generated comprehensive Security Analysis Report
- Identified all vulnerabilities with remediation guidance
- Mapped to CWE and PCI DSS requirements

✅ **Automated Security Scanning:**
- Created SonarQube token
- Ran automated code quality and security scan
- Generated SonarQube Analysis Report
- Verified 100% correlation with manual findings

✅ **Pipeline Enhancement:**
- Added comprehensive Security Analysis stage to Jenkinsfile
- Implemented 6-layer security scanning (Secret Scanning, SonarQube, Dependency Scan, Code Patterns, Configuration Checks, Risk Assessment)
- Created risk-based deployment gates (CRITICAL/HIGH/MEDIUM/LOW)
- Added automated security metrics tracking and comprehensive report generation
- Set deployment gates that BLOCK deployment on CRITICAL issues

✅ **CVE Analysis Framework:**
- Created reusable CVE analysis prompt
- Standardized vulnerability assessment process
- Integrated compliance requirements (PCI DSS)

### Key Takeaways

1. **Defense in Depth:** Multiple security scanning layers catch different types of issues
2. **Automation + Manual:** Automated tools (SonarQube) validate manual analysis (Bob)
3. **Actionable Intelligence:** Reports provide specific remediation steps, not just findings
4. **Compliance Focus:** Security analysis tied to regulatory requirements (PCI DSS)
5. **Pipeline Integration:** Security gates prevent vulnerable code from reaching production

### Files Created/Modified

```
Security_Analysis_Report.md              # Manual security analysis
SonarQube_Analysis_Report.md             # Automated scan results
Jenkinsfile                               # Enhanced security stage with 6-layer scanning
pipeline/cve-analysis-prompt.txt         # CVE analysis template
order-service/src/.../OrderService.java  # Modified with vulnerabilities
order-service/src/.../OrderService.java.backup  # Original backup
SECURITY_REPORT.txt                      # Pipeline security summary (generated during pipeline run)
```

---

## Cleanup (Optional)

### Restore Original Code

**Prompt to Bob:**
```
Run script pipeline/restore_vulnerabilities.sh
```

This will:
- Restore `OrderService.java` from backup
- Remove injected vulnerabilities
- Clean up backup file

### Remove Generated Reports

```bash
rm Security_Analysis_Report.md
rm SonarQube_Analysis_Report.md
rm SECURITY_REPORT.txt
rm security-*.txt  # Remove all security artifact files
```

### Revert Pipeline Changes

```bash
git checkout Jenkinsfile
```

---

## Troubleshooting

### Issue: SonarQube scan fails

**Solution:**
```bash
# Check SonarQube is running
curl http://localhost:9000/api/system/status

# Verify token is valid
curl -u demo:Demo123lab123@ http://localhost:9000/api/authentication/validate
```

### Issue: Tests fail after vulnerability injection

**Expected behavior** - The injected vulnerabilities break the validation logic. Use `-DskipTests` to continue:
```bash
mvn clean compile -DskipTests
```

### Issue: Bob can't find files

**Solution:**
```bash
# Verify you're in the correct directory
pwd
# Should be: /Users/jordanbond/Desktop/fis_sre_bob/sre-project-test2

# List files
ls -la order-service/src/main/java/com/example/orders/service/
```

### Issue: Pipeline security stage fails

**Check:**
1. SonarQube is accessible: `curl http://localhost:9000`
2. Token is set: `echo $SONAR_TOKEN`
3. Maven can compile: `cd order-service && mvn compile`

---

## Advanced Exercises

### Exercise 1: Add More Vulnerability Types

Inject additional vulnerabilities:
- SQL Injection
- XML External Entity (XXE)
- Cross-Site Scripting (XSS)
- Insecure Deserialization

**Prompt:**
```
Bob, add SQL injection vulnerability to OrderService searchByCustomerUnsafe method
```

### Exercise 2: Create Custom Checkstyle Rules

Add custom rules to `pipeline/pci-checkstyle.xml`:
- Detect hardcoded IP addresses
- Flag TODO/FIXME comments in production code
- Enforce secure random usage

### Exercise 3: Integrate with JIRA

Modify the security stage to create JIRA tickets for CRITICAL findings:
```groovy
if (env.SECURITY_RISK == 'CRITICAL') {
    // Create JIRA ticket with Bob
    def jiraTicket = askBob("""
    Create JIRA ticket for critical security findings:
    ${env.SECURITY_FINDINGS}
    """)
}
```

### Exercise 4: Add Security Metrics Dashboard

Create a dashboard showing:
- Security score trends over time
- Vulnerability remediation velocity
- Mean time to fix (MTTF) by severity
- Compliance status

---

## Additional Resources

### Documentation
- [SonarQube Security Rules](https://rules.sonarsource.com/java/type/Vulnerability)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [PCI DSS Requirements](https://www.pcisecuritystandards.org/)
- [CWE Top 25](https://cwe.mitre.org/top25/)

### Tools
- [Trivy](https://github.com/aquasecurity/trivy) - Container vulnerability scanner
- [OWASP Dependency-Check](https://owasp.org/www-project-dependency-check/) - Dependency vulnerabilities
- [Checkmarx](https://checkmarx.com/) - SAST scanning
- [Snyk](https://snyk.io/) - Developer-first security

### Related Labs
- `LAB_BOB_PIPELINE.md` - Basic Bob pipeline integration
- `LAB_ARGOCD_DEPLOYMENT.md` - GitOps deployment
- `LAB_MONITORING.md` - Observability and monitoring

---

## Feedback

Did you complete this lab successfully? Have suggestions for improvement?

**Share your feedback:**
- Create an issue in the repository
- Submit a pull request with improvements
- Share your experience with the team

---

**Lab Version:** 1.0  
**Last Updated:** April 7, 2026  
**Author:** Bob (Senior Software Engineer)  
**Difficulty:** Intermediate  