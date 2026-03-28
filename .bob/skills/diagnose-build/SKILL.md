---
name: diagnose-build
description: Diagnose a failed Jenkins build by reading its log and identifying the root cause
---

# Diagnose Build

When invoked, follow these steps:

1. If no build number is provided, use the Jenkins MCP `getJob` tool on `sre-pipeline` to find the latest failed build
2. Use `getBuildLog` to retrieve the full console output for that build
3. Identify which pipeline stage failed (Lint, PCI Compliance, Test, Security Scan, Deploy, Smoke Tests)
4. Analyze the failure output and determine the root cause
5. Provide:
   - **Stage**: Which stage failed
   - **Root cause**: What went wrong and why
   - **Fix**: Specific code or config change to resolve it
   - **PCI impact**: Whether this failure has compliance implications
