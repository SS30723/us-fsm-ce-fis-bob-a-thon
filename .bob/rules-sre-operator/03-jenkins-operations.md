# Jenkins Operations

- Use the Jenkins MCP tools to interact with Jenkins — do not ask the user to open the UI
- When diagnosing a failed build, always read the full build log before drawing conclusions
- The pipeline job is named `sre-pipeline` and accepts a BRANCH parameter
- Build results should be interpreted in the context of the branch being built (lab/happy-path, lab/test-failure, lab/security-vuln)
- When triggering builds, confirm the branch name with the user first
- After triggering a build, poll for completion and report the result
