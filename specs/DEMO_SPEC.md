# DEMO_SPEC — Demo Branches, README, and Lab Guide

---

## Demo Branches

Three branches, each designed to trigger a different pipeline outcome. Created from `main` with one targeted change each.

### `lab/happy-path`

All checks pass. Bob recommends approval. Shows the full 10-step flow end-to-end.

**What to change:** A minor, safe modification — add a comment or bump the version.

```bash
git checkout main && git pull
git checkout -b lab/happy-path

# Add a harmless comment to OrderService.java
# In order-service/src/main/java/com/example/orders/service/OrderService.java
# Add this comment above the class declaration:
#   // Version 1.0.1 — improved logging for audit compliance

git commit -am "chore: improve logging comments for audit compliance"
git push origin lab/happy-path
```

**Expected pipeline result:**
- Lint: PASS
- PCI Check: PASS
- Tests: PASS (9/9)
- Security: LOW risk
- Bob DCR: "Low risk, recommend approval"
- Deployment: SUCCESS
- Smoke tests: ALL PASS

### `lab/test-failure`

Unit tests fail. Bob analyzes the failure and explains the root cause.

**What to change:** Remove the null check in `validateStatusTransition` so it throws a NullPointerException.

```bash
git checkout main && git pull
git checkout -b lab/test-failure

# In order-service/src/main/java/com/example/orders/service/OrderService.java
# Replace the validateStatusTransition method with this broken version:

#   private void validateStatusTransition(String currentStatus, String newStatus) {
#       // Simplified validation — just check if transition makes sense
#       if (currentStatus.equals(newStatus)) {
#           throw new IllegalStateException("Status is already " + currentStatus);
#       }
#   }

# This breaks the test because:
# - updateOrderStatus_invalidTransition_throwsException expects "Cannot transition from PENDING to DELIVERED"
#   but now any different status is accepted
# - updateOrderStatus_fromTerminalStatus_throwsException expects terminal status check
#   but it's been removed

git commit -am "refactor: simplify status validation logic"
git push origin lab/test-failure
```

**Expected pipeline result:**
- Lint: PASS
- PCI Check: PASS
- Tests: FAIL (2 failures)
- Bob DCR: "HIGH risk — test failures detected, do not deploy"
- Pipeline stops at approval gate (or reviewer rejects)

### `lab/security-vuln`

Security scan finds vulnerabilities. PCI compliance check also fails.

**What to change:** Add a `System.out.println` (PCI violation) and use an old base image in the Dockerfile (security vulnerability).

```bash
git checkout main && git pull
git checkout -b lab/security-vuln

# 1. In order-service/src/main/java/com/example/orders/service/OrderService.java
#    Add this line inside the createOrder method, before the return:
#       System.out.println("Creating order for: " + order.getCustomerName() + " amount: " + order.getAmount());

# 2. In order-service/Dockerfile
#    Change the base image from:
#       FROM eclipse-temurin:17-jre-alpine
#    To an older version with known CVEs:
#       FROM eclipse-temurin:17.0.1-jre-alpine

git commit -am "chore: add debug logging and pin base image version"
git push origin lab/security-vuln
```

**Expected pipeline result:**
- Lint: PASS
- PCI Check: FAIL (PCI-01: System.out usage)
- Tests: PASS
- Security: HIGH risk (CVEs in old base image)
- Bob DCR: "CRITICAL risk — PCI compliance violation and security vulnerabilities"
- Reviewer sees detailed risk assessment and rejects

### `lab/pci-violation` (optional fourth branch)

Shows only PCI violations without security scan issues. Good for focusing the demo on compliance.

```bash
git checkout main && git pull
git checkout -b lab/pci-violation

# In order-service/src/main/java/com/example/orders/service/OrderService.java
# Add multiple PCI violations:
#   1. System.out.println("Processing order: " + order.toString());  // PCI-01
#   2. private String apiKey = "sk-1234567890abcdef";                // PCI-02
#   3. Add a TODO comment: // TODO: add encryption for PII fields    // PCI-06

git commit -am "feat: add order processing debug output"
git push origin lab/pci-violation
```

---

## `README.md`

```markdown
# SRE Deploy Demo

Demonstrates the SRE team's 10-step regulated production deployment flow with Bob AI assistance.

**What it shows:**
1. Developer creates a PR
2. Jenkins validates (linting + PCI compliance)
3. Bob creates a Change Management (DCR) ticket with risk assessment
4. Management reviews and approves/rejects
5. ArgoCD deploys to the cluster
6. Bob runs smoke tests
7. Bob updates the change control record

**Time to set up:** ~15 minutes (after OpenShift is ready)

## Prerequisites

- OpenShift cluster (TechZone reservation — see OPENSHIFT_SETUP.md)
- `oc` CLI installed (`brew install openshift-cli`)
- `podman` installed (`brew install podman`)
- GitHub repo with this code
- Bob API key
- GitHub PAT with `repo` scope

## Quick Start

```bash
# 1. Login to OpenShift
oc login --username=<user> --password=<pass> --server=<api-url>

# 2. Create project
oc new-project sre-deploy-lab

# 3. Deploy everything
make setup

# 4. (Optional) Add ArgoCD
make oc-deploy-argocd

# 5. Open Jenkins UI (URL printed by setup)
# 6. Click "Build with Parameters" → set BRANCH to lab/happy-path → Build
```

## Demo Scenarios

| Branch | What happens | Bob's role |
|--------|-------------|------------|
| `lab/happy-path` | All checks pass, deployment succeeds | Creates DCR: "Low risk, approve" |
| `lab/test-failure` | Tests fail, pipeline blocks | Analyzes root cause, creates DCR: "Do not deploy" |
| `lab/security-vuln` | PCI + security failures | Explains PCI violations and CVE remediation |

## Make Targets

```bash
make help                 # Show all targets
make setup                # Deploy app + Jenkins + Bob
make teardown             # Remove everything
make oc-deploy-argocd     # Add ArgoCD
make test                 # Run tests locally
make pci-check            # Run PCI compliance check locally
make oc-redeploy          # Rebuild and redeploy the app
make oc-bob PROMPT="..."  # Ask Bob a question on the cluster
```

## Project Structure

```
├── order-service/        # Spring Boot CRUD API (the application)
├── k8s/                  # Kubernetes manifests + OpenShift setup scripts
├── pipeline/             # PCI checkstyle rules + smoke test script
├── Jenkinsfile           # The 10-step pipeline
├── Makefile              # All commands
└── DEMO.md               # Step-by-step demo guide
```
```

---

## `DEMO.md`

```markdown
# Demo Guide — SRE Production Deployment Flow

This guide walks through the demo step by step. Total time: ~2 hours.

## Before the Demo

Ensure everything is running:

```bash
oc get pods
# Should see: order-service, order-db, jenkins, bob-cli
# All should be Running/Ready

# Verify Jenkins is accessible
oc get route jenkins -o jsonpath='{.spec.host}'

# Verify the app works
curl http://$(oc get route order-service -o jsonpath='{.spec.host}')/api/orders/health
```

## Act 1: Happy Path (30 min)

**Story:** "A developer has made a small improvement to the order service. Let's watch it go through the regulated deployment process."

1. Open Jenkins UI in browser
2. Click **sre-pipeline** → **Build with Parameters**
3. Set BRANCH to `lab/happy-path`
4. Click **Build**

**What to point out as it runs:**

| Stage | What's happening | Talking point |
|-------|-----------------|---------------|
| Checkout | Jenkins pulls the PR branch | "Step 1 — the developer has submitted their change" |
| Bob PR Analysis | Bob reads the diff and summarizes | "Bob tells us what this change does before any checks run" |
| Lint | Checkstyle runs | "Step 3 — standard code quality checks" |
| PCI Compliance | Custom PCI rules run | "Step 4 — these are PCI DSS-specific checks. No hardcoded secrets, no System.out, no weak crypto." |
| Test | Maven runs 9 unit tests | "All tests pass — the status validation logic is working correctly" |
| Security Scan | Trivy scans for CVEs | "No critical or high vulnerabilities found in dependencies" |
| Create Change Request | Bob generates a DCR | **KEY MOMENT** — "Bob just wrote the change management ticket. Look at the risk assessment — it analyzed all the check results and concluded this is low risk." |
| Management Approval | Pipeline pauses | **INTERACTIVE** — "In production, a manager reviews this. Bob gave them the data they need to decide. Click Approve." |
| Deploy via ArgoCD | Image builds, rollout happens | "Steps 7-8 — the change deploys to the cluster" |
| Smoke Tests | Health checks run | "Step 9 — Bob verifies the deployment is healthy" |
| Update Change Control | Bob writes the status update | "Step 10 — the change control record is closed. Full audit trail from PR to production." |

**Key message:** "Bob automated the DCR creation, risk assessment, and status updates. A human still approves — Bob just gives them better data to decide with."

## Act 2: Test Failure (30 min)

**Story:** "Another developer made a change that looks fine but broke the status validation logic."

1. In Jenkins, click **Build with Parameters**
2. Set BRANCH to `lab/test-failure`
3. Click **Build**

**What to point out:**

| Stage | What's happening | Talking point |
|-------|-----------------|---------------|
| Lint + PCI | Both pass | "The code compiles fine, no style issues, no PCI violations" |
| Test | 2 tests fail | "But the unit tests caught a real bug" |
| Bob Test Analysis | Bob explains the failure | **KEY MOMENT** — "Bob identified that the refactored validation logic removed the status transition rules. It tells the developer exactly what broke and how to fix it." |
| Create Change Request | Bob writes DCR with REJECT recommendation | "Look at the DCR — Bob automatically flagged this as high risk because tests failed. A manager would never approve this." |
| Approval | Pipeline pauses | "Click Abort to reject the deployment." |

**Key message:** "Bob didn't just say 'tests failed.' It analyzed the failure, found the root cause, and told the developer how to fix it. The DCR reflected the real risk."

## Act 3: Security + PCI Violation (30 min)

**Story:** "A developer added some debug logging and pinned a base image version. Seems harmless, but..."

1. In Jenkins, click **Build with Parameters**
2. Set BRANCH to `lab/security-vuln`
3. Click **Build**

**What to point out:**

| Stage | What's happening | Talking point |
|-------|-----------------|---------------|
| PCI Compliance | FAILS | **KEY MOMENT** — "The PCI linter caught a System.out.println. In a PCI environment, that's a compliance violation — it could log cardholder data to stdout." |
| Bob PCI Analysis | Bob explains the PCI implications | "Bob doesn't just say 'violation found' — it explains WHY this is a PCI DSS issue and exactly what to do." |
| Security Scan | HIGH severity CVEs found | "The old base image has known vulnerabilities. Trivy found them." |
| Bob Security Analysis | Bob analyzes exploitability | "Bob looks at the CVEs and tells you which ones are actually exploitable in your context vs. theoretical risks." |
| Create Change Request | Bob writes DCR with CRITICAL risk | "Look at this DCR — Bob combined the PCI violation AND the security vulnerabilities into one risk assessment. It's recommending REJECT." |

**Key message:** "In a regulated environment, these aren't just warnings — they're blockers. Bob caught them, explained them in PCI DSS terms, and made sure the DCR reflected the real compliance risk."

## Act 4: Discussion (30 min)

**Questions to ask the audience:**

1. "How long does it take to write a DCR manually today?"
2. "What if Bob could create the DCR in your JIRA automatically?" (Show the JIRA MCP integration)
3. "What would you want Bob's risk assessment to consider that it doesn't today?"
4. "How does this map to your actual 10-step flow? What's different?"

**Things to show if asked:**

- **JIRA integration:** "Bob has MCP connectors for JIRA. In production, the DCR would be a real JIRA ticket, not just console output."
- **ArgoCD UI:** Open the ArgoCD route and show the sync status, resource tree, and health status.
- **Approval workflow:** "The Jenkins input step is simple. In production, this could trigger a Slack message, an email, or integrate with your change advisory board."
- **Multiple environments:** "The same pipeline can deploy to staging first, run smoke tests, then promote to production with a second approval gate."
```

---

## Notes for Implementation

- Demo branches must be created manually because each one introduces a specific, targeted change. Don't auto-generate them.
- The README should be simple — it's what someone sees when they clone the repo. Keep it under one screen.
- The DEMO.md is the script for the person running the demo. It tells them what to say, when to pause, and what to point at.
- The talking points in DEMO.md are designed around "key moments" where Bob's value is most visible. These are the lines that land with the audience.
