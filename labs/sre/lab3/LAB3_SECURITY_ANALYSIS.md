# Lab 3: Security Vulnerability Analysis & Pipeline Integration

**Objective:** Learn how to perform security analysis with Bob Findings, run automated scans with SonarQube, and integrate comprehensive security checks into a CI/CD pipeline.

 
**Difficulty:** Intermediate
**Prerequisites:**
- Setup complete (order-service, SonarQube, Jenkins running)
- Bob CLI configured
- Basic understanding of security concepts

---

## Table of Contents

- [Lab Overview](#lab-overview)
- [Before you start](#before-you-start)
- [Part 1: Inject Security Vulnerabilities](#part-1-inject-security-vulnerabilities)
  - [Step 1.1: Review Bob Findings Before Injection](#step-11-review-bob-findings-before-injection)
  - [Step 1.2: Run the Vulnerability Injection Script](#step-12-run-the-vulnerability-injection-script)
  - [Step 1.3: Review Bob Findings After Injection](#step-13-review-bob-findings-after-injection)
- [Part 2: Security Analysis with Software Security Reviewer Mode](#part-2-security-analysis-with-software-security-reviewer-mode)
  - [Step 2.1: Understanding Software Security Reviewer Mode](#step-21-understanding-software-security-reviewer-mode)
  - [Step 2.2: Import the Software Security Reviewer Mode](#step-22-import-the-software-security-reviewer-mode)
  - [Step 2.3: Switch to Software Security Reviewer Mode](#step-23-switch-to-software-security-reviewer-mode)
  - [Step 2.4: Generate Comprehensive Security Analysis Report](#step-24-generate-comprehensive-security-analysis-report)
- [Part 3: SonarQube Security Scanning](#part-3-sonarqube-security-scanning)
  - [Step 3.1: Create SonarQube Token and Project](#step-31-create-sonarqube-token-and-project)
  - [Step 3.2: Run SonarQube Scan and Generate Analysis Report](#step-32-run-sonarqube-scan-and-generate-analysis-report)
  - [Step 3.3: Review the SonarQube Analysis Report](#step-33-review-the-sonarqube-analysis-report)
- [Part 4: Add SonarQube & Grype Security Analysis Stage](#part-4-add-sonarqube--grype-security-analysis-stage)
  - [Step 4.1: Add SonarQube & Grype Security Analysis Stage](#step-41-add-sonarqube--grype-security-analysis-stage)
- [Part 5: Push and Watch](#part-5-push-and-watch)
  - [Step 5.1: Commit and Push Changes](#step-51-commit-and-push-changes)
  - [Step 5.2: Add SonarQube Token to Jenkins and Run Build](#step-52-add-sonarqube-token-to-jenkins-and-run-build)
  - [Step 5.3: Restore Original Code](#step-53-restore-original-code)
- [Lab Summary](#lab-summary)

---

## Lab Overview

You'll inject security vulnerabilities into the order-service, analyze them with Bob's real-time findings and a comprehensive security review mode, run automated SonarQube scans, integrate security checks into your Jenkins pipeline, and learn proper Git workflows for managing experimental changes.

### What you'll build in Lab 3

1. **Security vulnerability injection** — use a script to inject 6 types of vulnerabilities into OrderService.java and observe Bob's real-time findings as they appear in your IDE.

2. **Comprehensive security analysis** — import and use the Software Security Reviewer mode to generate a full application security assessment covering code, infrastructure, compliance, and remediation roadmap.

3. **SonarQube integration** — generate a SonarQube token, run automated security scans, and review detailed vulnerability reports with metrics and issue tracking.

4. **Enhanced Jenkins pipeline** — add a comprehensive security stage to your Jenkinsfile that runs SonarQube scans and generates security reports on every build.

5. **Git workflow best practices** — use `git restore` to discard experimental vulnerability injections and maintain a clean working directory before pushing changes.

By the end, every push triggers automated security scanning in your Jenkins pipeline, and you've practiced using Bob's security analysis capabilities across multiple tools and workflows, including proper Git hygiene for managing temporary code changes.

---

## Before you start

- [ ] Lab 1 complete (askBob helper added to your Jenkinsfile)
- [ ] You're on your working branch (e.g. `user1-labs`)

**Reset your Jenkinsfile first.** Remove any stages you added in previous labs, keeping only the `Checkout` stage and the `askBob` helper at the bottom. Stacking every lab's stages stretches a single build past 15 minutes — clearing them keeps iteration fast and the logs readable. Use [`solution/Jenkinsfile.start`](../../../solution/Jenkinsfile.start) as the reference shape.


## Part 1: Inject Security Vulnerabilities

### Step 1.1: Review Bob Findings Before Injection

Select **Bob Findings** at the bottom of the screen. You will observe that it is currently empty. This is expected, as no vulnerabilities have been injected into the file yet, so Bob has no findings to display.

### Step 1.2: Run the Vulnerability Injection Script

> **Note:** Ensure you are in **Code Mode** before proceeding with this step.

**Prompt to Bob:**
```
Bob run script inject_vulnerabilities.sh
```

**What Bob does:**
- Executes `labs/sre/lab3/inject_vulnerabilities.sh`
- Modifies `order-service/src/main/java/com/example/orders/service/OrderService.java`
- Injects vulnerable dependencies into `order-service/pom.xml`
- Injects 9 types of vulnerabilities:
  
  **Code Vulnerabilities (6):**
  1. Hardcoded credentials (BACKUP_DB_PASSWORD, LEGACY_API_KEY)
  2. Insecure logging (System.out.println)
  3. Weak cryptography (MD5)
  4. Stack trace exposure (printStackTrace)
  5. Weak random (java.util.Random)
  6. Information exposure (detailed error messages)
  
  **Dependency Vulnerabilities (3):**
  7. Log4j 2.14.1 - CVE-2021-44228 (Log4Shell - Critical)
  8. Jackson Databind 2.12.3 - CVE-2020-36518 (High severity)
  9. SnakeYAML 1.30 - CVE-2022-1471 (Critical severity)

> **📊 CVE Impact:** The three vulnerable dependencies introduce **multiple high and critical severity CVEs** that will be detected by Grype during the security scan. This demonstrates how dependency vulnerabilities are identified, assessed, and prioritized in the pipeline.

**Expected Output:**
```
🔧 Vulnerability Injection Script
==================================

🔧 Injecting vulnerabilities into OrderService.java...
   ✅ Java vulnerabilities injected

🔧 Injecting vulnerable Log4j dependency into pom.xml...
   ✅ Vulnerable Log4j 2.14.1 dependency injected (CVE-2021-44228)

✅ Vulnerability injection complete!

📍 Modified files:
   - order-service/src/main/java/com/example/orders/service/OrderService.java
   - order-service/pom.xml

🔍 Injected vulnerabilities:
   1. Hardcoded credentials (BACKUP_DB_PASSWORD, LEGACY_API_KEY)
   2. Insecure logging (System.out.println with sensitive data)
   3. Weak cryptography (MD5 in generateOrderVerificationCode)
   4. Stack trace exposure (printStackTrace in multiple methods)
   5. Weak random (java.util.Random in generateTrackingNumber)
   6. Information exposure (detailed error messages)
   7. Vulnerable dependency (Log4j 2.14.1 - CVE-2021-44228)
   8. Vulnerable dependency (Jackson Databind 2.12.3 - CVE-2020-36518)
   9. Vulnerable dependency (SnakeYAML 1.30 - CVE-2022-1471)
```


### Step 1.3: Review Bob Findings After Injection

Now that vulnerabilities have been injected, let's see what Bob detects in real-time:

1. **Open the modified file:**
   - Navigate to: `order-service/src/main/java/com/example/orders/service/OrderService.java`
   - Open the file in Bob's editor

2. **Check Bob Findings:**
   - Click **"Bob Findings"** at the bottom of the screen
   - Bob will analyze the file and identify security issues in real-time
   - **You should see 4 critical findings** displayed in the Bob Findings panel

   > **Note:** Bob Findings should update with its security findings, if it does not, try to close and reopen the `OrderService.java` file or restart Bob

3. **Review the inline findings:**
   
   Bob Findings intelligently prioritizes and displays the **most critical security issues** that require immediate attention:
   
   **Expected: 4 Critical Findings in OrderService.java**
   - 🔴 **Scan (Secrets): Secret Keyword:19** - Hardcoded credential detected
   - 🔴 **Scan (Secrets): Secret Keyword:20** - Hardcoded credential detected
   - 🔴 **Scan (Vulnerabilities): Integer.toHexString...** - Weak cryptography implementation
   - 🔴 **Scan (Vulnerabilities): Detected MD5 hash...** - Insecure hash algorithm usage

**Why 4 findings instead of 9?**

While the script injected 9 types of vulnerabilities, Bob Findings focuses on **critical security issues** that pose the highest risk:

| Vulnerability Type | Detected by Bob Findings? | Reason |
|-------------------|---------------------------|---------|
| Hardcoded credentials | ✅ Yes (2 findings) | **CRITICAL** - Direct security breach risk |
| Weak cryptography (MD5) | ✅ Yes (2 findings) | **CRITICAL** - Cryptographically broken algorithm |
| Insecure logging (System.out) | ⚠️ Lower priority | Code smell, not critical vulnerability |
| Stack trace exposure | ⚠️ Lower priority | Context-dependent risk |
| Weak random (java.util.Random) | ⚠️ Lower priority | May be flagged differently |
| Information disclosure | ⚠️ Lower priority | Context-dependent risk |
| Vulnerable dependencies (3) | ⚠️ Not in code scan | Detected by dependency scanners (SonarQube/Grype) |

**This is expected behavior!** Bob Findings prioritizes critical security issues (secrets and cryptographic vulnerabilities) over code quality issues. The comprehensive Security Analysis Report in Part 2 will capture all issues, while Bob Findings focuses on what developers need to fix immediately.

**Key Insight:**
- **Bob Findings (4 items)** = Real-time critical security alerts for developers
- **Security Analysis Report (17 items)** = Comprehensive code & configuration audit with compliance mapping
- **SonarQube (15 items)** = Automated code quality and security analysis

This gives you a preview of what Bob detects at the code level before we perform a comprehensive security analysis in Part 2.

---

## Part 2: Security Analysis with Software Security Reviewer Mode

### Step 2.1: Understanding Software Security Reviewer Mode

Before importing the mode, take a moment to understand what it does and how it differs from Bob Findings.

**Option 1: Ask Bob to explain (Recommended)**

**Prompt to Bob:**
```
Read labs/sre/lab3/software-security-reviewer.yaml and explain what the Software Security Reviewer mode does and how it differs from Bob Findings. What types of analysis does it perform?
```

**What Bob explains:**
- **Software Security Reviewer** is a specialized mode for comprehensive application security audits
- It goes beyond code-level analysis to include infrastructure, configuration, and compliance
- Performs multi-layer security assessment across the entire application stack
- Generates detailed reports with remediation roadmaps and compliance mapping

**Option 2: Review the file yourself**

Navigate to `labs/sre/lab3/software-security-reviewer.yaml` and review the mode configuration to understand its capabilities.

**Key Differences:**

| Feature | Bob Findings | Software Security Reviewer |
|---------|--------------|---------------------------|
| **Scope** | Single file, real-time | Full application audit |
| **Analysis Depth** | Code-level vulnerabilities | Code + Infrastructure + Compliance |
| **When to Use** | During development | Security audits, pre-deployment reviews |
| **Output** | Inline warnings | Comprehensive security report |
| **Focus** | Critical issues (4 items) | All security layers (17+ items) |

Now let's import and use this powerful mode.

### Step 2.2: Import the Software Security Reviewer Mode

Let's import the specialized **Software Security Reviewer** mode:

1. **Locate the mode file:**
   - Navigate to: `labs/sre/lab3/software-security-reviewer.yaml`

2. **Import the mode into Bob:**
   - Click the **Settings icon** (⚙️) in the top right corner of Bob
   - Click **"Modes"** in the settings menu
   - Click **"Import"** button
   - Select the file: `labs/sre/lab3/software-security-reviewer.yaml`
   - Click **"Import"** to confirm

3. **Verify the mode was imported:**
   - You should see **"🛡️🔐 Software Security Reviewer"** in your modes list
   - Close the settings panel

### Step 2.3: Switch to Software Security Reviewer Mode

1. **Change Bob's mode:**
   - Click the current mode indicator at the top of Bob (e.g., "💻 Code")
   - Select **"🛡️🔐 Software Security Reviewer"** from the dropdown
   - Bob is now in security analysis mode

2. **Verify mode switch:**
   - The mode indicator should show: **"🛡️🔐 Software Security Reviewer"**

### Step 2.4: Generate Comprehensive Security Analysis Report

Now let's have Bob perform a full security audit of the order-service application.

**Prompt to Bob:**
```
Evaluate order-service for vulnerabilities, insecure patterns, misconfigurations, and compliance gaps and generate an analysis report.
```

**What Bob does:**

> **Note:** Bob's approach may vary. Sometimes Bob creates a TODO list to track the analysis process, other times it proceeds directly to scanning. Both approaches are valid.

- Scans all application files (Java code, configuration, Dockerfile, K8s manifests)
- Identifies security vulnerabilities and insecure patterns
- Analyzes compliance gaps (PCI DSS, OWASP Top 10)
- Evaluates misconfigurations in infrastructure
- Generates comprehensive security report: `SECURITY_ANALYSIS_REPORT.md`

**Expected Output:**

Bob will generate a comprehensive security analysis report: `SECURITY_ANALYSIS_REPORT.md`

> **Troubleshooting:** If Bob completes the analysis but doesn't create the report file, use this follow-up prompt:
> ```
> Create the SECURITY_ANALYSIS_REPORT.md file with all the findings you just analyzed
> ```

**Report Includes:**
- Detailed findings with CVSS scores, CWE mappings, and code examples
- Specific remediation steps for each vulnerability
- OWASP Top 10 (2021) compliance matrix
- PCI-DSS compliance status
- Prioritized remediation roadmap (4 phases over 6 weeks)
- Supply chain & infrastructure security recommendations
- CI/CD pipeline security gates

**Review the full report** to understand each finding, its impact, and remediation steps.

**Additional Sections:**
- 📊 Threat model diagram
- 🎯 Attack scenarios
- 🔧 Remediation roadmap (Immediate, Short-term, Long-term)
- ✅ Compliance mapping (PCI DSS, OWASP, CWE)
- 📋 Testing recommendations


**How This Complements Bob Findings:**

The Software Security Reviewer mode builds upon Bob's inline findings to provide a comprehensive security assessment:

| Feature | Bob Findings (Inline) | Software Security Reviewer |
|---------|----------------------|---------------------------|
| **Scope** | Single file analysis | Full application code analysis |
| **Detection** | Real-time as you code | Comprehensive audit on demand |
| **Findings** | 4 critical code issues | 17 issues across code & config |
| **Context** | Line-by-line warnings | Application-wide security posture |
| **Output** | Inline highlights | Detailed report with remediation |

**Complementary Strengths:**

1. **Bob Findings** (Part 1.3):
   - ✅ Immediate feedback while coding
   - ✅ Catches issues as you write code
   - ✅ Focuses on code-level vulnerabilities
   - ✅ Perfect for developer workflow

2. **Software Security Reviewer** (Part 2):
   - ✅ Expands to full code and configuration analysis
   - ✅ Adds compliance mapping (PCI DSS, OWASP, CWE)
   - ✅ Provides threat modeling and attack scenarios
   - ✅ Includes prioritized remediation roadmap
   - ✅ Perfect for security audits and reviews

**Together, they provide:**
- 🔍 **Real-time detection** (Bob Findings: 4 critical items) + **Comprehensive analysis** (Security Reviewer: 17 total findings)
- 💻 **Critical code issues** + **Full code & configuration security**
- ⚡ **Developer feedback** + **Security team reporting**
- 🎯 **Immediate fixes** + **Strategic remediation planning**

---

## Part 3: SonarQube Security Scanning

> **Important:** Before starting Part 3, click **"Start New Task"** in Bob to begin a fresh conversation. This ensures Bob focuses on the SonarQube scanning workflow without context from the previous security analysis.

### Step 3.1: Create SonarQube Token and Project

> **Note:** Switch back to **Code Mode** before proceeding with this step.

**SonarQube Information:**
- **URL:** `https://sonarqube-sonarqube.apps.itz-8ggai0.infra01-lb.wdc04.techzone.ibm.com`
- **Demo User Credentials:**
  - Username: `demo`
  - Password: `Demo123lab123@`

> **Note:** You don't need to visit the SonarQube UI for this lab. All interactions will be done via API commands through Bob.

> **⚠️ IMPORTANT:** Before executing the command below, replace `${USER}` with your actual username (e.g., `testuser1`, `testuser2`, etc.) in the prompt. This ensures your SonarQube project is uniquely identified.

**Prompt to Bob:**
```
Execute the following to create a SonarQube token and project for ${USER}:

TOKEN=$(curl -s -u demo:Demo123lab123@ -X POST "https://sonarqube-sonarqube.apps.itz-8ggai0.infra01-lb.wdc04.techzone.ibm.com/api/user_tokens/generate?name=token-$(date +%s)" | jq -r .token); PROJECT_KEY=order-service-${USER}-$(date +%s); curl -u demo:Demo123lab123@ -X POST "https://sonarqube-sonarqube.apps.itz-8ggai0.infra01-lb.wdc04.techzone.ibm.com/api/projects/create?project=$PROJECT_KEY&name=Order%20Service%20${USER}"; echo ""; echo "TOKEN=$TOKEN"; echo "PROJECT_KEY=$PROJECT_KEY"; echo "Project created in SonarQube!"
```

**Example with username replaced:**
```
Execute the following to create a SonarQube token and project for testuser1:

TOKEN=$(curl -s -u demo:Demo123lab123@ -X POST "https://sonarqube-sonarqube.apps.itz-8ggai0.infra01-lb.wdc04.techzone.ibm.com/api/user_tokens/generate?name=token-$(date +%s)" | jq -r .token); PROJECT_KEY=order-service-testuser1-$(date +%s); curl -u demo:Demo123lab123@ -X POST "https://sonarqube-sonarqube.apps.itz-8ggai0.infra01-lb.wdc04.techzone.ibm.com/api/projects/create?project=$PROJECT_KEY&name=Order%20Service%20testuser1"; echo ""; echo "TOKEN=$TOKEN"; echo "PROJECT_KEY=$PROJECT_KEY"; echo "Project created in SonarQube!"
```

**What Bob does:**
1. Generates a unique SonarQube authentication token
2. Creates a unique project key with timestamp (e.g., `order-service-testuser1-1778261688`)
3. Creates the project in SonarQube via API
4. Displays the token and project key for the next step

**Expected Output:**
```json
{
  "project": {
    "key": "order-service-testuser1-1778261688",
    "name": "Order Service testuser1",
    "qualifier": "TRK",
    "visibility": "public"
  }
}

TOKEN=squ_dc8b45225f4ebdcd40cc73a4a19d2b3b14f76755
PROJECT_KEY=order-service-testuser1-1778261688
Project created in SonarQube!
```

**Save both the TOKEN and PROJECT_KEY** - you'll need them for the next step.

**Benefits of User-Specific Projects:**
- ✅ Each user gets their own isolated project
- ✅ Timestamped project keys prevent conflicts in multi-user environments
- ✅ Users can track their own analysis history
- ✅ Results won't overwrite each other

### Step 3.2: Run SonarQube Scan and Generate Analysis Report

**Prompt to Bob:**
```
Scan order-service with the newly created SonarQube project and generate a comprehensive analysis report
```

**What Bob does:**

Bob performs a comprehensive 5-step analysis process:

**1. Runs SonarQube Scan**

Bob will first attempt to run the scan with tests:
```bash
cd order-service && mvn clean compile sonar:sonar \
  -Dsonar.projectKey=order-service-testuser1-1778261688 \
  -Dsonar.projectName="Order Service testuser1" \
  -Dsonar.host.url=https://sonarqube-sonarqube.apps.itz-8ggai0.infra01-lb.wdc04.techzone.ibm.com \
  -Dsonar.token=squ_dc8b45225f4ebdcd40cc73a4a19d2b3b14f76755
```

**Expected:** The tests will fail due to the injected vulnerabilities (they broke the `validateStatusTransition` method).

Bob will recognize the test failure and automatically correct itself by adding `-DskipTests`:
```bash
cd order-service && mvn clean compile sonar:sonar \
  -Dsonar.projectKey=order-service-testuser1-1778261688 \
  -Dsonar.projectName="Order Service testuser1" \
  -Dsonar.host.url=https://sonarqube-sonarqube.apps.itz-8ggai0.infra01-lb.wdc04.techzone.ibm.com \
  -Dsonar.token=squ_dc8b45225f4ebdcd40cc73a4a19d2b3b14f76755 \
  -DskipTests
```
- Uses the **PROJECT_KEY** and **TOKEN** from Step 3.1
- Bob automatically fills in these values from the previous step
- Skips tests to allow the scan to complete
- Uploads analysis results to your user-specific SonarQube project

**2. Fetches Issues from SonarQube API**
```bash
curl -s -u demo:Demo123lab123@ \
  "https://sonarqube.../api/issues/search?componentKeys=order-service&resolved=false&ps=500"
```
- Retrieves all 10 unresolved issues
- Gets full details: rule, severity, location, message

**3. Fetches Security Hotspots**
```bash
curl -s -u demo:Demo123lab123@ \
  "https://sonarqube.../api/hotspots/search?projectKey=order-service&ps=500"
```
- Retrieves 5 security hotspots
- Gets vulnerability probability ratings

**4. Fetches Project Metrics**
```bash
curl -s -u demo:Demo123lab123@ \
  "https://sonarqube.../api/measures/component?component=order-service&metricKeys=..."
```
- Gets quality gate metrics and ratings
- Retrieves bugs, vulnerabilities, code smells, coverage, technical debt

**5. Generates Comprehensive Analysis Report**

Creates `SONARQUBE_ANALYSIS_REPORT.md` with:
- Executive summary with quality gate status
- Detailed breakdown of all 15 issues (10 issues + 5 security hotspots)
- Security hotspots analysis with remediation code
- Bugs and code smells with fixes
- Comparison with manual security review (83% correlation)
- Remediation priority matrix
- CI/CD integration recommendations
- Quality gate configuration

**Expected Console Output:**
```
[INFO] ANALYSIS SUCCESSFUL
[INFO] Analysis report uploaded to SonarQube

Fetching issues from SonarQube API...
Retrieved 10 issues

Fetching security hotspots...
Retrieved 5 security hotspots

Fetching project metrics...
Quality Gate: PASSED

Generating comprehensive analysis report...
✅ Report created: SONARQUBE_ANALYSIS_REPORT.md
```

**Note:** Bob goes beyond just running the scan - it automatically fetches detailed data via API and creates a comprehensive markdown report with remediation guidance. This provides much more value than viewing results in the SonarQube UI!

### Step 3.3: Review the SonarQube Analysis Report

Open and review the generated `SONARQUBE_ANALYSIS_REPORT.md` to see:

**Summary of Findings (15 total):**
- 10 code issues (bugs, vulnerabilities, code smells)
- 5 security hotspots requiring review

**Key Correlation with Manual Analysis:**

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

## Part 4: Add SonarQube & Grype Security Analysis Stage

> **Note:** Switch to **Jenkins Pipeline Integration** mode before proceeding with this step.

### Step 4.1: Add SonarQube & Grype Security Analysis Stage

**Prerequisites:**
Before adding the security stage, ensure you have:
- ✅ Completed Part 3 (created SonarQube token and project)
- ✅ Your SonarQube token saved from Step 3.1

> **Important:** You will add the SonarQube token to Jenkins credentials in Step 5.2. The Jenkinsfile you create in this step will reference the credential ID `sonarqube-token`, which you'll configure before running the build.

#### 🎯 How Experienced Developers Use Bob for Complex Pipeline Stages

As an experienced developer, you can leverage Bob's capabilities by crafting **comprehensive, specification-style prompts** that describe exactly what you need. This transforms Bob from a simple assistant into a powerful code generation tool.

**The Power of Detailed Prompts:**
Instead of asking "Add security scanning," provide a complete technical specification with:
- ✅ Exact commands and tool versions
- ✅ Container contexts and file paths
- ✅ Data structure requirements (serializable types only)
- ✅ Error handling and retry logic
- ✅ Environment constraints (no external dependencies, rate limits)
- ✅ Success criteria and logging requirements

**Result:** Production-ready code in minutes, not hours of manual coding and testing.



**Prompt to Bob:**
```
Add a comprehensive Security Analysis stage to the Jenkinsfile that performs multi-layered security scanning. The stage should be placed after the existing stages and include:

REQUIREMENTS:

1. Environment Configuration:
   - Load SonarQube token from Jenkins credentials: credentials('sonarqube-token')
   - Set SONAR_HOST_URL to: https://sonarqube-sonarqube.apps.itz-8ggai0.infra01-lb.wdc04.techzone.ibm.com
   - Set PROJECT_KEY dynamically using: "order-service-${env.USER}-${env.BUILD_NUMBER}"

2. Phase 1 - SonarQube Security Scanning (MANDATORY):
   - Run Maven SonarQube scan from order-service directory
   - Use test-compile goal before sonar:sonar
   - **CRITICAL: Implement two-phase wait strategy:**
     
     **Phase 1a - Wait for Task Completion (12 retries, 10 seconds between):**
     - Check task status via: curl "${SONAR_HOST_URL}/api/ce/component?component=${PROJECT_KEY}"
     - Parse status using: grep -o '"status":"[^"]*"' | head -1 | cut -d'"' -f4
     - Continue only when status == 'SUCCESS'
     - Break if status == 'FAILED'
     - Use try-catch for error handling
     
     **Phase 1b - Fetch Metrics (6 retries, 5 seconds between):**
     - Only after task completion, fetch metrics via: curl "${SONAR_HOST_URL}/api/measures/component?component=${PROJECT_KEY}&metricKeys=bugs,vulnerabilities,code_smells,security_hotspots,security_rating,reliability_rating,security_review_rating"
     - Parse JSON response using Groovy JsonSlurper (no jq dependency)
     - Store metrics as String primitives in securityResults.sonarqube map
     - Check if sonarData.component?.measures exists and has size > 0
     - Set sonarData = null after parsing to avoid serialization issues
   
   - Store results in serializable Map structure with String values
   - Display metrics in console output

3. Phase 2 - Grype Vulnerability Scanning:
   - Install Grype on-demand in the build-tools container using: curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
   - Run scan from order-service directory: grype dir:. --scope all-layers -o json > grype-report.json
   - Parse JSON to count Critical, High, and Medium severity vulnerabilities
   - Use grep and wc -l for counting (no jq dependency)
   - Store counts as Integer primitives in securityResults.trivy map
   - Wrap in catchError to prevent pipeline failure

4. Phase 3 - CVE Analysis with Bob (conditional):
   - Only run if total vulnerabilities > 0
   - Use Bob in 'code' mode (not custom mode)
   - Provide detailed prompt including SonarQube and Grype results
   - Request: risk assessment, top 3 vulnerabilities, remediation steps, deployment recommendation
   - Save analysis to bob-cve-analysis.txt
   - Extract deployment recommendation (BLOCK/WARN/PROCEED)

5. Phase 4 - Risk Level Calculation:
   - Parse SonarQube String values to Integer safely using Integer.parseInt()
   - Calculate risk score: vulnerabilities*10 + hotspots*5 + bugs*2 + critical_cves*20 + high_cves*10
   - Determine risk level: CRITICAL (≥50), HIGH (≥30), MEDIUM (≥10), LOW (<10)
   - Store as serializable primitives (String/Integer only)

6. Phase 5 - Deployment Decision:
   - CRITICAL → BLOCK deployment, set currentBuild.result = 'UNSTABLE'
   - HIGH → WARN with manual review recommendation
   - MEDIUM/LOW → PROCEED with approval

7. Phase 6 - Consolidated Report Generation:
   - Create markdown report: security-analysis-report.md
   - Include: executive summary, SonarQube results table, Grype results, CVE analysis, deployment recommendation
   - Archive artifacts: security-analysis-report.md, bob-cve-analysis.txt, order-service/grype-report.json

IMPORTANT CONSTRAINTS:
- Use only serializable data types (String, Integer, Boolean) in securityResults Map
- No jq or external JSON parsers - use Groovy JsonSlurper for SonarQube, grep/wc for Grype
- Install Grype in build-tools container (no separate security-tools container due to Docker Hub rate limits)
- Use 15-minute timeout for the entire stage
- Wrap all phases in catchError blocks to ensure pipeline completion
- Use container('build-tools') for Grype installation and scanning
- Use container('bob') for CVE analysis
- **CRITICAL: Must implement two-phase SonarQube wait (task status check THEN metrics fetch)**
- Store SonarQube metrics as Strings, parse to Integer only when calculating risk score
- Clear JSON objects after parsing (set to null) to avoid serialization issues

The stage should provide clear console output with emoji indicators and progress messages for each phase.
```

**What Bob does:**

Bob generates a production-ready `Security Analysis` stage with the following structure:

**Environment Configuration:**
```groovy
environment {
    SONAR_TOKEN = credentials('sonarqube-token')
    SONAR_HOST_URL = 'https://sonarqube-sonarqube.apps.itz-8ggai0.infra01-lb.wdc04.techzone.ibm.com'
}
```
- Loads the SonarQube token from Jenkins credentials (ID: `sonarqube-token`)
- Sets the SonarQube server URL

**Stage Phases:**

**Phase 1: Mandatory SonarQube Security Scanning**

Uses the same SonarQube setup from Part 3 (Step 3.1 and 3.2):

1. **Runs SonarQube Scan** (required - must be configured with `SONAR_TOKEN` and `SONAR_PROJECT_KEY`)
   ```bash
   cd order-service && mvn clean compile sonar:sonar \
     -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
     -Dsonar.projectName="Order Service ${USER}" \
     -Dsonar.host.url=https://sonarqube-sonarqube.apps.itz-8ggai0.infra01-lb.wdc04.techzone.ibm.com \
     -Dsonar.token=${SONAR_TOKEN} \
     -DskipTests
   ```
   - Uses the **PROJECT_KEY** and **TOKEN** created in Part 3
   - Skips tests to allow the scan to complete
   - Uploads analysis results to SonarQube

2. **Fetches Issues from SonarQube API**
   - Retrieves all unresolved issues
   - Gets full details: rule, severity, location, message

3. **Fetches Security Hotspots**
   - Retrieves security hotspots
   - Gets vulnerability probability ratings

4. **Fetches Project Metrics**
   - Gets quality gate metrics and ratings
   - Retrieves bugs, vulnerabilities, code smells, coverage, technical debt

5. **Generates Comprehensive Analysis Report**
   - Creates `SONARQUBE_ANALYSIS_REPORT.md` with:
     - Executive summary with quality gate status
     - Detailed breakdown of all issues
     - Security hotspots analysis with remediation code
     - Bugs and code smells with fixes
     - Remediation priority matrix
     - CI/CD integration recommendations

- Pipeline fails if SonarQube is not configured

**Phase 2: Grype Vulnerability Scanning**
- **Installs Grype on-demand** in build-tools container
- Scans for vulnerabilities in dependencies and application code
- Counts Critical, High, and Medium severity CVEs
- Gracefully handles errors to prevent pipeline failure

**Phase 3: Intelligent CVE Analysis**
- Checks if any vulnerabilities were found in reports
- **If vulnerabilities detected:** Runs detailed CVE analysis using Bob
  - Assesses severity and exploitability
  - Determines deployment impact
  - Provides remediation guidance
  - Generates `CVE_ANALYSIS_REPORT.md`
- **If no vulnerabilities:** Skips detailed analysis, creates clean report

**Phase 4: Risk Assessment & Deployment Decision**
- Calculates overall risk level from all reports: CRITICAL/HIGH/MEDIUM/LOW
- Makes deployment decision:
  - 🔴 **CRITICAL:** Blocks deployment (pipeline fails)
  - 🟠 **HIGH:** Marks pipeline unstable, requires review
  - 🟡 **MEDIUM:** Proceeds with caution
  - 🟢 **LOW:** Approved for deployment
- Generates `SECURITY_SUMMARY.md` with consolidated findings
- Archives all security artifacts

**Key Benefits:**

✅ **Mandatory SonarQube Integration** - Ensures consistent security scanning across all builds
✅ **On-Demand Tool Installation** - Installs Grype dynamically to avoid Docker Hub rate limits
✅ **Intelligent CVE Analysis** - Uses Bob's AI for risk assessment and remediation guidance
✅ **Conditional Analysis** - Only runs detailed CVE analysis when vulnerabilities detected
✅ **Comprehensive Risk Assessment** - Considers ALL security reports together
✅ **No External Dependencies** - Uses Groovy JsonSlurper and grep/wc (no jq required)
✅ **Clear Deployment Decisions** - Automated risk-based gates with BLOCK/WARN/PROCEED logic

**Generated Reports:**
- `security-analysis-report.md` - Consolidated security report with executive summary
- `bob-cve-analysis.txt` - Bob's CVE analysis with remediation steps
- `order-service/grype-report.json` - Grype vulnerability scan results

**Security Risk Levels:**
- **🔴 CRITICAL:** Blocks deployment (pipeline fails)
- **🟠 HIGH:** Pipeline marked unstable, review required
- **🟡 MEDIUM:** Proceeds with caution, issues should be addressed soon
- **🟢 LOW:** Safe to deploy

**Note on Software Security Reviewer Mode:**

While this lab focuses on SonarQube as the mandatory security scanning tool, Bob's Software Security Reviewer mode (covered in Part 2) can be integrated into your pipeline for more comprehensive security analysis. However, this would require additional customization to fit your specific needs and workflow. The Software Security Reviewer mode is best used for:
- Pre-deployment security audits
- Compliance assessments (PCI DSS, OWASP)
- Threat modeling and attack scenario analysis
- Custom security requirements beyond standard code scanning

If you wish to integrate the Software Security Reviewer mode into your pipeline, you can customize the security stage to include Bob-based analysis alongside SonarQube scanning.

---

## Part 5: Push and Watch

### Step 5.1: Commit and Push Changes

**Prompt to Bob:**
```
git add Jenkinsfile .bob/ labs/sre/lab3/ order-service/src/main/java/com/example/orders/service/OrderService.java order-service/pom.xml
git commit -m "Lab 3 — Security Analysis stage with vulnerability scanning and injected vulnerabilities for testing"
git push
```

**What this does:**
- Adds the updated Jenkinsfile with the Security Analysis stage
- Adds any custom Bob modes from .bob/ directory
- Adds lab3 files (scripts, documentation)
- **Adds OrderService.java with injected vulnerabilities** for security testing
- **Adds pom.xml with vulnerable Log4j dependency** for dependency scanning
- Commits all changes with descriptive message
- Pushes to trigger Jenkins build with vulnerabilities present

> **Note:** We're intentionally committing the files with vulnerabilities so the Jenkins pipeline can detect them during the security scan. In Step 5.3, we'll remove these vulnerabilities and push clean code.

### Step 5.2: Add SonarQube Token to Jenkins and Run Build

Before running the build, you need to add your SonarQube token to Jenkins credentials so the pipeline can authenticate with SonarQube.

**Add SonarQube Token to Jenkins:**

1. **Navigate to Jenkins Credentials:**
   - Go to Jenkins → **Manage Jenkins** → **Credentials**
   - Click **Add Credentials**

2. **Create the credential:**
   - **Kind:** Secret text
   - **Scope:** Global
   - **Secret:** Paste your SonarQube token from Step 3.1 (e.g., `squ_dc8b45225f4ebdcd40cc73a4a19d2b3b14f76755`)
   - **ID:** `sonarqube-token`
   - **Description:** SonarQube authentication token
   - Click **Create**

3. **Run the Build:**
   - Navigate to your pipeline in Jenkins
   - Click **Build Now**
   - Watch the console output as the pipeline executes

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

### Step 5.3: Restore Original Code

After the Jenkinsfile changes have been pushed and the build has run, we need to remove the vulnerabilities from OrderService.java and pom.xml that were committed to the repository.

> **Note:** Ensure you are in **Code mode** before proceeding with this step.

**Prompt to Bob:**
```
Revert OrderService.java and pom.xml to their original state before vulnerability injection by checking out the version from before the vulnerabilities were added, then commit and push these changes
```

**What Bob does:**
1. Identifies the commit before vulnerabilities were injected
2. Restores the clean versions of the files:
   - `git checkout <commit-hash> -- order-service/src/main/java/com/example/orders/service/OrderService.java`
   - `git checkout <commit-hash> -- order-service/pom.xml`
3. Commits the restored files:
   - `git add order-service/src/main/java/com/example/orders/service/OrderService.java order-service/pom.xml`
   - `git commit -m "Restore OrderService.java and pom.xml to clean state - remove injected vulnerabilities"`
4. Pushes the changes:
   - `git push`

**Expected Output:**
```
✅ OrderService.java restored to clean version
✅ pom.xml restored to clean version
✅ Changes committed and pushed
✅ Vulnerabilities removed from repository
```

**Why this approach?**
- ✅ **Removes vulnerabilities from Git history** - Creates a new commit that reverts the files
- ✅ **Maintains audit trail** - Shows the restore action in commit history
- ✅ **Triggers new Jenkins build** - The push will run the security scan on clean code
- ✅ **Production-ready workflow** - Demonstrates proper way to revert committed changes
- ✅ **Educational value** - Teaches Git workflow for undoing committed changes

**Alternative approach using git revert:**
If you prefer to revert the entire vulnerability injection commit:
```bash
git log --oneline  # Find the commit hash of vulnerability injection
git revert <commit-hash>  # Creates a new commit that undoes the changes
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
  - `security-analysis-report.md` - Consolidated security analysis report
  - `bob-cve-analysis.txt` - Bob's CVE analysis (if vulnerabilities detected)
  - `order-service/grype-report.json` - Raw Grype vulnerability scan results
  
  > **Note:** In an ideal production environment, you would generate separate reports for each tool (SonarQube_Analysis_Report.md, CVE_ANALYSIS_REPORT.md, SECURITY_REPORT.txt). However, for demo purposes, this lab consolidates all findings into a single `security-analysis-report.md` that includes:
  > - Executive summary with risk level and deployment decision
  > - SonarQube analysis results (bugs, vulnerabilities, security hotspots, code smells)
  > - Grype vulnerability scan results (Critical, High, Medium severity counts)
  > - Risk assessment calculation and thresholds
  > - Deployment recommendation (BLOCK/WARN/PROCEED)
  > - Next steps based on risk level
- Pipeline may turn **UNSTABLE (yellow)** or **FAILURE (red)** depending on severity of findings
- Build page lists all security reports under **Build Artifacts**

Open the archived artifacts from the build page to review:
- Bob's detailed security analysis with remediation guidance
- SonarQube's quality gate status and security hotspots
- CVE analysis with risk assessment and deployment recommendations

**Note:** The security stage is designed to block deployment if CRITICAL issues are detected. Review the console output and security reports to understand what needs to be fixed before the next deployment.



**Recommended workflow after finishing this lab:**
```bash
# Commit the lab outputs
git add Jenkinsfile security-analysis-report.md bob-cve-analysis.txt order-service/grype-report.json
git commit -m "lab: add comprehensive security analysis"

# Push changes so Jenkins can build the updated pipeline
git push origin main
```



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