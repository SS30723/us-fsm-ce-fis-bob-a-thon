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
