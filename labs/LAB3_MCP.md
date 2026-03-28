# Lab 3: Jenkins MCP Server

Connect Bob to Jenkins via MCP so you can operate pipelines directly from the terminal.

**Prerequisites:** Lab 1 complete (Jenkins running on the cluster).

---

## 3.1 — Install the Jenkins MCP plugin

Open Jenkins UI, go to **Manage Jenkins** > **Plugins** > **Available plugins**, search for `mcp-server`, and install it. Restart Jenkins when prompted.

```bash
# Or install via CLI
oc exec dc/jenkins -- jenkins-cli install-plugin mcp-server -restart
```

Verify the endpoint is available:

```bash
JENKINS_HOST=$(oc get route jenkins -o jsonpath='{.spec.host}')
curl -sk "https://$JENKINS_HOST/mcp-server/mcp" \
  -H "Authorization: Basic $(echo -n admin:$(oc whoami -t) | base64)"
```

---

## 3.2 — Create a Jenkins API token

In Jenkins UI: click your username (top right) > **Configure** > **API Token** > **Add new Token**. Copy the token value.

---

## 3.3 — Configure Bob

Edit `.bob/mcp.json` in the project root:

```json
{
  "mcpServers": {
    "jenkins": {
      "type": "streamableHttp",
      "url": "https://<jenkins-host>/mcp-server/mcp",
      "headers": {
        "Authorization": "Basic <base64-encoded-username:token>"
      }
    }
  }
}
```

Generate the base64 value:

```bash
echo -n "admin:<your-api-token>" | base64
```

Replace `<jenkins-host>` with your Jenkins route:

```bash
oc get route jenkins -o jsonpath='{.spec.host}'
```

---

## 3.4 — Test it

Open Bob and try:

```
List all Jenkins jobs
```

```
Show me the last build of sre-pipeline
```

```
Get the build log for sre-pipeline build #1
```

```
Trigger sre-pipeline with BRANCH=main and wait for it to finish
```

> **Checkpoint:** Bob can list jobs, read logs, and trigger builds without you opening the Jenkins UI.

---

## Available MCP tools

Once connected, Bob has access to:

| Tool | What it does |
|------|-------------|
| `getJobs` | List all jobs with status |
| `getJob` | Get details for a specific job |
| `triggerBuild` | Trigger a job with parameters |
| `getBuild` | Get build metadata |
| `getBuildLog` | Read console output |
| `searchBuildLog` | Search logs for a pattern |
| `getQueueItem` | Check queue status |
| `getBuildChangeSets` | View SCM changes in a build |
| `whoAmI` | Current Jenkins user |
| `getStatus` | Jenkins health |

---

## How MCP works in Bob

- MCP servers are configured per-project in `.bob/mcp.json`
- Bob connects as a client to the MCP server using the transport type you specify (`streamableHttp`, `sse`, or `stdio`)
- Once connected, the MCP tools become available to Bob automatically — you don't invoke them directly, Bob decides when to use them based on your prompts
- MCP tools are available in any mode that has `mcp` in its tool groups
- Never hardcode credentials in `mcp.json` if it's committed to version control — use environment variables or keep the file in `.gitignore`
