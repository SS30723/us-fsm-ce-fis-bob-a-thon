---
name: create-dcr
description: Generate a formal Deployment Change Request from Jenkins build results
---

# Create DCR

When invoked, follow these steps:

1. Use the Jenkins MCP `getJob` tool on `sre-pipeline` to get the latest build
2. Use `getBuild` to retrieve build metadata (result, parameters, duration)
3. Use `getBuildLog` to read the console output
4. Extract validation results from the log: lint status, PCI compliance, test results, security scan findings
5. Generate a formal DCR with these sections:
   - **CHANGE DESCRIPTION** — What is changing and why (based on the BRANCH parameter and log output)
   - **RISK ASSESSMENT** — Low/Medium/High/Critical with justification from pipeline results
   - **AFFECTED SERVICES** — Services and environments impacted
   - **VALIDATION EVIDENCE** — Summary of all check results from the build
   - **ROLLBACK PLAN** — How to revert if deployment fails
   - **RECOMMENDATION** — APPROVE or REJECT with reasoning
6. Format as a formal document suitable for management review
