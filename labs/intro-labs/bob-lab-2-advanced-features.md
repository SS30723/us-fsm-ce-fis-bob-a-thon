# Lab 2: Bob Advanced Features
**Duration:** 45 minutes  
**Objective:** Master BobShell, MCP integrations, and custom modes

**Prerequisites:**
- Completed Lab 1: Bob Fundamentals
- Bob application running
- Command-line terminal access
- `uv` installed ([install instructions](https://docs.astral.sh/uv/getting-started/installation/)) — required for the Jira MCP section
- Jira credentials handed out by your instructor (URL, username, API token) — required for the Jira MCP section

> 📌 **Documentation:** [Bob IDE](https://bob.ibm.com/docs/ide) | [BobShell](https://bob.ibm.com/docs/shell)

---

## Table of Contents
1. [Overview](#overview)
2. [BobShell Fundamentals](#bobshell-fundamentals)
3. [BobShell in Practice](#bobshell-in-practice)
4. [Understanding MCP](#understanding-mcp)
5. [Setting Up the Jira MCP Server](#setting-up-the-jira-mcp-server)
6. [Custom Modes](#custom-modes)
7. [Practical Applications](#practical-applications)
8. [Troubleshooting](#troubleshooting)
9. [Key Takeaways](#key-takeaways)

---

## Overview

This lab introduces Bob's most powerful advanced capabilities that extend beyond the IDE:

- **BobShell**: Command-line interface for automation and CI/CD
- **MCP (Model Context Protocol)**: Connect Bob to external tools and services
- **Custom Modes**: Tailor Bob to your specific workflows

### Learning Objectives

By the end of this lab, you will:

- ✅ Use BobShell for interactive and automated workflows
- ✅ Understand how MCP extends Bob's capabilities
- ✅ Create and manage custom modes
- ✅ Apply these features to real-world scenarios
- ✅ Integrate Bob into your development pipeline

### Why These Features Matter

> **🎯 Bob Differentiator: Extensible Architecture**
>
> Bob's extensibility is its superpower. Through BobShell, MCP, and custom modes, Bob adapts to YOUR environment and workflows. Unlike other AI assistants that work in isolation, Bob can connect to internal APIs, databases, documentation systems, and custom tools. This makes Bob uniquely valuable for enterprise teams with specific needs and existing toolchains.

---

## BobShell Fundamentals

### What is BobShell?

BobShell is Bob's command-line interface that brings AI assistance to:

- **Terminal workflows**: Chat with Bob directly from the command line
- **Automation scripts**: Integrate Bob into shell scripts
- **CI/CD pipelines**: Use Bob in build and deployment processes
- **Batch operations**: Process multiple files or tasks in sequence
- **Remote environments**: Use Bob on servers without a GUI

> **🧠 Bob Differentiator: Intelligent Resource Optimization**
>
> BobShell automatically selects the most appropriate AI model for each task. Simple operations use lighter models for speed, while complex analysis uses frontier-class models for accuracy. This happens transparently, reducing costs by up to 60% while maintaining quality.

### Installation and Setup

**Verify BobShell Installation:**

```bash
# Check BobShell version
bob --version

# View available commands
bob --help
```

**Expected Output:**
```
Bob CLI v1.x.x
Usage: bob [options] [command]
...
```

**If you see "command not found":**
- Follow the [BobShell installation guide](https://bob.ibm.com/docs/shell/getting-started/install-and-setup)
- Verify Bob is in your system PATH
- Restart your terminal after installation

> 📌 **Full Documentation:** https://bob.ibm.com/docs/shell

---

## BobShell in Practice

### Interactive Mode

First, navigate to the sandbox directory you created in Intro Lab 1 — Bob's working directory is wherever you launch it from, and you want this session scoped to your sandbox:

```bash
cd labs/intro-labs/sandbox
```

Then launch Bob in interactive mode for terminal-based conversations:

```bash
# Start interactive session
bob
```

**Try these commands:**

```
# Ask for explanations
> Explain what a closure is in JavaScript

# Generate code
> Create a Python function to calculate fibonacci numbers

# Get help with errors
> Why would I get a "connection refused" error when connecting to a database?
```

**To exit:** Press `Ctrl+C` twice

**What's Happening:**
- Interactive mode provides a conversational interface in the terminal
- Perfect for quick queries without opening the IDE
- Session history is maintained during the conversation
- All Bob capabilities available through natural language

> 📌 **Learn More:** [Interactive Mode Documentation](https://bob.ibm.com/docs/shell/getting-started/start-bobshell-interactive)

### Non-Interactive Mode

Execute single commands for automation and scripting:

**Create a test file first:**

```bash
# You should already be in the sandbox directory
cat > calculator.py << 'EOF'
def add(a, b):
    return a + b

def multiply(x, y):
    return x * y
EOF
```

**Now try non-interactive commands:**

```bash
# Explain code in a file
bob "Explain what calculator.py does"

# Review code
bob "Review calculator.py and suggest improvements"

# Generate new code with YOLO mode.
bob "Create a Python function that calculates factorial" --yolo --hide-intermediary-output > factorial.py

# Quick questions
bob "What is the difference between a list and a tuple in Python?"
```

**Key Flags:**
- `--yolo`: Auto-approve all actions (use carefully!)
- `--hide-intermediary-output`: Clean output for file redirection
- `--chat-mode <mode>`: Specify which mode to use

**What's Happening:**
- Non-interactive mode executes a single command and exits
- Perfect for automation and scripting
- Results output to stdout for easy capture
- Can be chained with other CLI tools using pipes

> 📌 **Learn More:** [Non-Interactive Mode Documentation](https://bob.ibm.com/docs/shell/getting-started/start-bobshell-non-interactive)

### Session Management

Bob automatically saves your interactive sessions for later resume:

```bash
# List available sessions
bob --list-sessions

# Resume the most recent session
bob --resume latest

# Resume a specific session by index
bob --resume 5

# Delete a session
bob --delete-session 3
```

**Example Workflow:**

```bash
# Start working on a feature
bob
> Analyze myapp.js for performance issues
# Bob identifies issues...
> Suggest optimizations for the database queries
# Exit session (Ctrl+C twice)

# Later, resume to continue
bob --resume latest
> Let's implement those database optimizations now
# Bob remembers the previous context
```

**When to Use Session Resume:**
- Continue work after a break
- Maintain context across sessions
- Switch between different projects
- Return to previous explorations

### Output Redirection Best Practices

When redirecting Bob's output to files, use these approaches for clean results:

**Option 1: Use `--hide-intermediary-output` flag**
```bash
# Generate clean code files
bob "Create a sorting function in Python" --yolo --hide-intermediary-output > sort.py
```

**Option 2: Ask Bob to write the file directly**
```bash
# Bob writes the file itself
bob "Create a sorting function in Python and write it to sort.py" --yolo
```

**What Gets Included Without These:**
- Bob's thinking process
- Tool usage messages
- Status updates
- The generated code (mixed with above)

**What You Get With These:**
- Only clean, generated code
- No intermediary messages
- Ready-to-use files

### BobShell in Automation

**Example: Code Review Script**

```bash
#!/bin/bash
# review-changes.sh - Review uncommitted changes

echo "Reviewing uncommitted changes..."
bob "Review uncommitted changes (git diff HEAD) and provide a summary" --hide-intermediary-output > review.md
echo "Review saved to review.md"
```

**Example: Batch File Processing**

```bash
#!/bin/bash
# analyze-files.sh - Analyze multiple files

for file in src/*.py; do
    echo "Analyzing $file..."
    bob "Analyze $file for potential bugs and security issues" --hide-intermediary-output > "reports/$(basename $file .py)-analysis.txt"
done
```

**Example: CI/CD Integration**

```bash
# In your CI/CD pipeline
bob "Review the code changes in this PR and check for: security issues, performance problems, and code quality" --hide-intermediary-output > pr-review.md
```

### BobShell Best Practices

1. **Be Specific in Requests**
   ```bash
   # Good
   bob "Create a React component for user authentication with email/password fields, validation, and error handling"
   
   # Less specific
   bob "Create a login form"
   ```

2. **Use Appropriate Output Formats**
   ```bash
   # JSON for programmatic processing
   bob "Analyze ./src and provide results in JSON format" --hide-intermediary-output > analysis.json
   
   # Markdown for documentation
   bob "Review ./src for code quality in markdown format" --hide-intermediary-output > review.md
   ```

3. **Leverage Git Integration**
   ```bash
   # Review changes in current branch
   bob "Review code changes between main and HEAD branches"
   
   # Review uncommitted changes
   bob "Review uncommitted changes (git diff HEAD)"
   ```

> 💡 **Automatic Optimization:** Bob automatically selects the most appropriate model for each task, optimizing for both quality and cost.

---

## Understanding MCP

### What is MCP?

**Model Context Protocol (MCP)** is an open protocol that enables Bob to:
- Access external data sources
- Execute custom tools and functions
- Integrate with third-party services
- Extend capabilities beyond built-in features

> **🎯 Why MCP Matters**
> MCP allows Bob to integrate with your company's internal tools, APIs, and services. Bob can access your documentation, query your databases, create tickets in your issue tracker, and deploy to your infrastructure—all through natural language. Bob adapts to YOUR environment.

### MCP Architecture

```
┌─────────────┐         MCP Protocol       ┌─────────────┐
│             │◄──────────────────────────►│             │
│  Bob Client │    JSON-RPC over stdio     │ MCP Server  │
│             │    or HTTP/WebSocket       │             │
└─────────────┘                            └─────────────┘
       │                                          │
       │                                          │
       ▼                                          ▼
  User Requests                            External Services
  - Ask questions                          - JIRA API
  - Execute tasks                          - Databases
  - Get information                        - Deployment tools
                                          - Custom APIs
```

### MCP Components

**1. Tools**: Functions Bob can call
```json
{
  "name": "create_ticket",
  "description": "Create a new issue ticket",
  "parameters": {
    "title": "string",
    "description": "string",
    "priority": "string"
  }
}
```

**2. Resources**: Data Bob can access
```json
{
  "uri": "docs://api-reference",
  "name": "API Documentation",
  "mimeType": "text/markdown"
}
```

**3. Prompts**: Pre-defined templates
```json
{
  "name": "code_review",
  "description": "Perform code review",
  "template": "Review this code for: {criteria}"
}
```

### MCP Server Lifecycle

```
1. Initialize → 2. Register Tools → 3. Handle Requests → 4. Cleanup
     │                  │                    │               │
     ▼                  ▼                    ▼               ▼
  Setup            Define tools        Execute tools    Close connections
  connections      and resources       return results   cleanup resources
```

### Configuring MCP Servers

**To add an MCP server:**

1. Open Bob Settings (gear icon) → MCP
2. Choose Global or Project MCP configuration
3. Edit the JSON configuration:

```json
{
  "mcpServers": {
    "my-custom-server": {
      "command": "node",
      "args": ["server.js"],
      "cwd": "/path/to/server"
    }
  }
}
```

4. Save and restart Bob

**Configuration Locations:**
- Global MCPs: `~/.bob/mcp.json`
- Project MCPs: `.bob/mcp.json` in project root

### Using MCP Tools

**Important:** MCP tools are only available in **Advanced mode**.

```
# In Bob (Advanced mode)
> Create a ticket for the bug we just found

# Bob uses the MCP server's create_ticket tool
> Deploy the latest changes to staging

# Bob uses the MCP server's deploy tool
```

> 📌 **Learn More:** [MCP Documentation](https://bob.ibm.com/docs/ide/configuration/mcp/understanding-mcp)

---

## Setting Up the Jira MCP Server

Time to put MCP into practice. You'll configure the **Atlassian MCP server** so Bob can read and act on Jira tickets directly from your IDE — same registration mechanic you just learned, applied to a real-world service.

> **🎯 Why This Matters**
>
> Most engineering teams already track work in Jira. Wiring Bob into it means you can search tickets, summarize an issue, or comment on a story without leaving your IDE. The pattern you use here applies to any MCP server — GitHub, Confluence, ServiceNow, Slack, internal APIs — they're all configured the same way.

### Step 1: Log In to Jira

Before wiring Bob into Jira, confirm you can reach Jira yourself with the credentials your instructor handed out:

1. Open your Jira URL in a browser (the value labeled **JIRA_URL** on your credential sheet)
2. Sign in with your Jira **username** (your workshop email) and password
3. Confirm you can see the workshop Jira project. The project key for this workshop is **`KAN`** — you'll see it as the prefix on every issue (e.g. `KAN-1`, `KAN-12`). Bob will use this project key when creating a ticket in Step 7.

If you can't log in, ask your instructor before continuing — every step below assumes a working Jira session and a known API token.

### Step 2: Open the Project MCP Config

This workshop uses **project-level** MCP config so the server registration is part of the repo. The file is already in place at the repo root:

```
.bob/mcp.json
```

Open it in your editor. It contains an empty `mcpServers` object:

```json
{
    "mcpServers": {
    }
}
```

> 📌 **Why project-level?** Bob loads `.bob/mcp.json` from whatever workspace it has open. Committing it to the repo means every Bob instance — your IDE locally and the bob-cli container in the Jenkins pipeline (SRE track) — picks up the same server registrations from `git checkout`. No one has to hand-edit a global config.

### Step 3: Add the Atlassian Server Block

Replace the contents with:

```json
{
  "mcpServers": {
    "atlassian": {
      "command": "bash",
      "args": [
        "-c",
        "set -a; source .env; set +a; exec uvx mcp-atlassian"
      ],
      "disabled": false,
      "alwaysAllow": [
        "jira_get_issue",
        "jira_search",
        "jira_add_comment"
      ]
    }
  }
}
```

**What's Happening:**

- **`command: "bash"`** with the `-c` script — `bash` runs as a thin launcher. It enables auto-export (`set -a`), sources `.env` from the workspace root, turns auto-export off (`set +a`), then `exec`s `uvx mcp-atlassian` so the Jira credentials land in the MCP server's environment.
- **`uvx mcp-atlassian`** — `uvx` is `uv`'s "run a published PyPI tool" mode. It pulls `mcp-atlassian` from PyPI on first use and runs it as a subprocess.
- **No `env` block, no `${VAR}` substitution** — credentials never appear in this committed file. The bash launcher sources them from `.env` at MCP-server launch time.
- **`alwaysAllow`** — Jira tools Bob can call without prompting for approval each time. Starting with three read/comment-leaning tools; destructive ones (transition, delete) stay off this list.

Save the file.

### Step 4: Provide Your Credentials via `.env`

The bash launcher in Step 3 sources `.env` from the repo root at startup, so the credentials live there. A `.env.example` template ships at the repo root — copy it:

```bash
cp .env.example .env
```

Open `.env` and replace the placeholders with the credentials your instructor handed out:

```bash
JIRA_URL=https://your-org.atlassian.net
JIRA_USERNAME=your.email@example.com
JIRA_API_TOKEN=your-token-here
```

`.env` is gitignored at the repo root, so your token won't be committed.

> ⚠️ **Security Reminder:** API tokens are secrets. Don't paste yours into chat, screenshots, or commits. If exposed, rotate it at id.atlassian.com.

### Step 5: Restart Bob

Bob reads `.bob/mcp.json` and `.env` once at startup. Quit Bob completely and reopen the workspace.

**Verify the server started:**

1. Open Settings → MCP
2. Look for `atlassian` in the server list
3. Status should show **Connected** (green)

If you see **Failed**, double-check that `.env` is at the repo root and that all three values are filled in with no quotes or extra spaces.

### Step 6: Use the Jira Tools in Advanced Mode

Switch to **Advanced mode** (MCP tools aren't available in Plan, Code, or Ask).

**Try this prompt:**

```text
List the MCP tools you have access to from the atlassian server.
```

### Step 7: Create a Ticket from the IDE

Bob can **create** tickets from within the IDE. The ticket you create here is the same one the App team will pull down and implement in their Lab 1.

Still in **Advanced** mode, paste:

```text
Use the atlassian MCP server to create a new Jira issue in project KAN with these details:

Summary: Add refund endpoint to order-service

Description:
As a customer support agent, I want to issue refunds on existing orders so that customers can be reimbursed for returned products.

Acceptance criteria:
- POST /api/orders/{id}/refund with body { "amount": 29.99, "reason": "..." }
- Returns 200 with the updated order
- Order status changes to "REFUNDED"
- Refund amount and reason stored on the order
- Cannot refund an order that is already in REFUNDED status

Issue type: Story

Tell me the ticket key Jira assigned.
```

**What's Happening:**

- Bob picks the `jira_create_issue` tool from the Atlassian server
- Because `jira_create_issue` is **not** in your `alwaysAllow` list, Bob asks for approval before calling it — approve it for this one call
- Jira creates the ticket and Bob reports back the key it was assigned (something like `OS-7`, `KAN-12`, etc.)

> 📝 **Write down the ticket key.** The App team will need it to start Lab 1 this afternoon. If you forget, you can always run `jira_search` to find it again.

### What You've Practiced

- ✅ Registered a real MCP server in project-level config
- ✅ Sourced credentials from `.env` via a bash launcher instead of inline values
- ✅ Used `alwaysAllow` to scope which tools run without approval
- ✅ Invoked external service tools from Advanced mode
- ✅ Created a real Jira ticket from inside Bob — the same one you'll pull down in the afternoon

---

## Custom Modes

### What Are Custom Modes?

Custom modes configure Bob for specific workflows and tasks. They define:
- Specialized behavior and focus
- Available tools and capabilities
- Pre-defined prompts and templates
- When to use the mode

> **🎯 Bob Differentiator: Customizable Modes**
> Custom modes are a key differentiator for Bob. Create specialized modes for code review, documentation, architecture design, DevOps workflows, or any team-specific process. Share modes through the marketplace for consistent behavior across your team. This level of customization is unique to Bob.

### Example Custom Modes

#### DevOps Mode
**Purpose:** Optimize for DevOps workflows

**Capabilities:**
- Deployment automation
- Infrastructure management
- Monitoring and alerting
- Incident response
- Log analysis

**Tools:**
- `deploy`: Deploy applications
- `rollback`: Rollback deployments
- `scale`: Scale services
- `logs`: View logs
- `metrics`: Get metrics

#### Code Review Mode
**Purpose:** Specialized for code reviews

**Capabilities:**
- Automated code analysis
- Security scanning
- Best practices checking
- Performance analysis
- Documentation review

**Tools:**
- `analyze_code`: Deep code analysis
- `check_security`: Security scan
- `review_pr`: PR review
- `suggest_improvements`: Improvement suggestions

#### Architecture Mode
**Purpose:** For architecture and design

**Capabilities:**
- System design assistance
- Architecture documentation
- Technology recommendations
- Scalability analysis
- Cost estimation

**Tools:**
- `design_system`: System design help
- `evaluate_tech`: Technology evaluation
- `estimate_cost`: Cost estimation
- `generate_diagram`: Architecture diagrams

### Creating Custom Modes

Custom modes live in `.bob/custom_modes.yaml` (project-scoped) or `~/.bob/custom_modes.yaml` (global). The file holds a list under `customModes:` — each entry is one mode.

**Basic Mode Structure:**

```yaml
customModes:
  - slug: my-custom-mode
    name: My Custom Mode
    roleDefinition: |
      You are a specialized assistant for [specific task]. Focus on [key areas].
    whenToUse: |
      Use this mode when [specific scenarios].
    groups:
      - read
      - edit
      - command
```

Valid `groups` values: `read`, `edit`, `command`, `browser`, `mcp`. (`command` is what gives the mode permission to run shell commands — there is no `execute` group.)

**Advanced Mode with MCP:**

```yaml
customModes:
  - slug: devops-mode
    name: 🚀 DevOps Mode
    roleDefinition: |
      You are a DevOps specialist. Help with deployments, monitoring, and infrastructure.
    whenToUse: |
      Use for deployment, infrastructure, and operational tasks.
    groups:
      - read
      - edit
      - command
      - mcp
```

To give a mode MCP access, include `mcp` in its `groups`. The MCP **servers themselves** (their command, args, env, `alwaysAllow` list, etc.) are declared separately in `.bob/mcp.json` — the same file you edited earlier in this lab. The mode just declares whether it's *allowed* to call MCP tools; which specific tools auto-approve vs. prompt for confirmation is governed by `alwaysAllow` in `.bob/mcp.json`.

### Managing Custom Modes

**To install a custom mode:**
1. Open Bob Settings
2. Navigate to **Modes**
3. Click **Import Mode**
4. Select your mode file (`.yaml`)
5. The mode appears in Bob's mode selector

**To remove a custom mode:**
1. Open Bob Settings
2. Navigate to **Custom Modes**
3. Find the mode to remove
4. Click the delete/trash icon
5. Confirm deletion

**Alternative — manual management:**
- Custom modes are stored in `.bob/custom_modes.yaml` (project-scoped) or `~/.bob/custom_modes.yaml` (global).
- Add a mode by appending a new entry under `customModes:`. Remove a mode by deleting its entry.
- Bob picks up changes on the next mode-selector load — no IDE restart needed for project-scoped edits.

> 📌 **Learn More:** [Custom Modes Documentation](https://bob.ibm.com/docs/ide/configuration/custom-modes)

---

## Troubleshooting

### Common Issues

**1. BobShell Command Not Found**
- Verify installation: `which bob`
- Check PATH: `echo $PATH`
- Reinstall BobShell if needed
- Restart terminal after installation

**2. MCP Tools Not Available**
- **Most Common:** Verify you're in **Advanced mode**
- Check MCP server is configured in Bob Settings → MCP
- Verify server is running: `ps aux | grep node`
- Check server logs for errors
- Restart MCP server and reload Bob

**3. Custom Mode Not Working**
- Verify mode file is valid JSON
- Check mode is enabled in Bob Settings
- Restart Bob after importing
- Review mode configuration for errors

**4. Session Resume Fails**
- List sessions: `bob --list-sessions`
- Try specific session: `bob --resume <index>`
- Clear old sessions if needed
- Check session storage: `~/.bob/sessions/`

**5. Output Redirection Issues**
- Use `--hide-intermediary-output` flag
- Or ask Bob to write file directly
- Check file permissions
- Verify output directory exists

---

## Key Takeaways

### BobShell
- ✅ Interactive mode for terminal conversations
- ✅ Non-interactive mode for automation
- ✅ Session management for context preservation
- ✅ Perfect for CI/CD and scripting

### MCP (Model Context Protocol)
- ✅ Extends Bob with external tools
- ✅ Connects to internal APIs and services
- ✅ Only available in Advanced mode
- ✅ Enables enterprise integrations

### Custom Modes
- ✅ Tailor Bob to specific workflows
- ✅ Create team-specific modes
- ✅ Share modes across organization
- ✅ Combine with MCP for powerful integrations

### Bob's Extensibility
> **🎯 Extensibility: Bob's Superpower**
>
> You've now experienced Bob's extensible architecture. Through BobShell, MCP servers, and custom modes, you can tailor Bob to your organization's unique needs. This extensibility—combined with Bob's intelligent resource optimization, multi-mode intelligence, and enterprise features—makes Bob uniquely powerful for development teams.

---

## Next Steps

Now that you've mastered Bob's advanced features:
- Integrate BobShell into your daily workflows
- Create custom modes for your team's processes
- Explore MCP integrations for your tools
- Share your modes and best practices with your team
- Apply Bob to your specific development challenges

---

## Additional Resources

- [Bob Documentation](https://bob.ibm.com/docs/ide)
- [BobShell Documentation](https://bob.ibm.com/docs/shell)
- [MCP Documentation](https://bob.ibm.com/docs/ide/configuration/mcp/understanding-mcp)
- [Custom Modes Guide](https://bob.ibm.com/docs/ide/configuration/custom-modes)
- [Best Practices](https://bob.ibm.com/docs/ide/getting-started/best-practices)

---

## Cleanup

Throughout Labs 1 and 2 you created scratch files under `labs/intro-labs/sandbox/`. Now that you're done with the intro labs, clean it up so the workshop repo stays tidy for the afternoon tracks.

**Switch to Code mode** and ask Bob:

```text
Delete the labs/intro-labs/sandbox/ directory and everything in it.
```

Approve the deletion when Bob prompts. Confirm the directory is gone before moving on to the App or SRE track.

---

**Lab 2 Complete! 🎉**

You've mastered Bob's advanced features and are ready to integrate Bob into your development workflows, automation pipelines, and team processes. These capabilities make Bob a powerful tool for any development environment.