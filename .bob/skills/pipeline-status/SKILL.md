---
name: pipeline-status
description: Check the health of all Jenkins pipelines and flag anything that needs attention
---

# Pipeline Status

When invoked, follow these steps:

1. Use the Jenkins MCP `getJobs` tool to list all jobs
2. For each job, check the last build result and health score
3. Flag any jobs that are:
   - Currently failing (last build result is FAILURE)
   - Unstable (last build result is UNSTABLE)
   - In the queue (pending execution)
   - Not built recently (stale)
4. Present a summary table:
   - Job name | Last build | Result | Duration | Health
5. If any jobs need attention, provide a brief recommendation for each
