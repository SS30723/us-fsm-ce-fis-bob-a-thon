# Lab 5 — DCR Generation + Jira MCP Reporting with Bob

## Table of Contents

- [Overview of Lab 5](#overview-of-lab-5)
  - [What you'll build in Lab 5](#what-youll-build-in-lab-5)
  - [What you'll reuse from Labs 1 & 2](#what-youll-reuse-from-labs-1--2)
- [Before you start](#before-you-start)
- [Part 1 — Create the `pipeline-dcr-jira-reporter` custom mode](#part-1--create-the-pipeline-dcr-jira-reporter-custom-mode)
- [Part 2 — Dogfood the mode against your own Jira](#part-2--dogfood-the-mode-against-your-own-jira)
- [Part 3 — Iterate if needed](#part-3--iterate-if-needed)
- [Part 4 — Swap `.bob/mcp.json` to the cluster-friendly form](#part-4--swap-bobmcpjson-to-the-cluster-friendly-form)
- [Part 5 — Add the `DCR` stage to your Jenkinsfile](#part-5--add-the-dcr-stage-to-your-jenkinsfile)
- [Part 6 — Push and watch](#part-6--push-and-watch)
- [Part 7 — Make it idempotent (optional)](#part-7--make-it-idempotent-optional)
- [Stuck?](#stuck)

---

## Overview of Lab 5

You'll do three things in Lab 5: generate a **Deployment Change Request (DCR)** report from the branch, wire **Bob up to a Jira MCP server** so it can act on that report, and add a `DCR` stage to your Jenkinsfile that ties them together.

Up to this point, every Bob mode you've created has been a **read-only analyst** — Bob looks at code/tests/diffs and writes a summary. In this lab Bob actually **does something with an external system**. The mechanism is [MCP (Model Context Protocol)](https://modelcontextprotocol.io): Bob talks to a Jira server through a small adapter process declared in `.bob/mcp.json`, and the custom mode you write tells Bob which Jira tools it's allowed to call.

The pattern: build the mode in the IDE, prove it works against your own Jira instance from the morning intro lab, then swap configuration and ship it to CI.

### What you'll build in Lab 5

1. **A custom Bob mode for DCR + Jira reporting** (`pipeline-dcr-jira-reporter`) — a pipeline mode with the `mcp` tool group enabled and a tight `alwaysAllow` list of Jira tools so the mode can file the DCR without prompting for approval mid-build. You'll dogfood this mode locally against your own Jira before pushing it to CI.

2. **A cluster-friendly `.bob/mcp.json`** — once the mode is solid, swap the bash-launcher MCP registration from the morning intro lab for one that reads credentials from the pod's environment. The mode itself doesn't change.

3. **A `DCR` stage** in your Jenkinsfile — runs after Unit Tests, gathers the change material (commits since `main`, diff stats, test results, artifacts from earlier stages), hands it to Bob in the new mode, and Bob both writes a `deployment-change-request.md` artifact **and** creates a new Jira ticket containing the DCR.

By the end, every push produces a structured DCR in Jenkins **and** a fresh Jira ticket your release manager can act on — without anyone copy-pasting between tools.

### What you'll reuse from Labs 1 & 2

- **The `askBob` helper function** — same call pattern, just a new mode slug.
- **The `jenkins-bob-integration` mode** — you'll use this in your IDE to write the DCR stage.
- **Earlier-stage artifacts** — the DCR mode can read `bob-pr-review.md` and `bob-test-analysis.md` from the workspace if you want the report to roll up the rest of the pipeline's findings.

---

## Before you start

- [ ] Labs 1 and 2 complete (PR Review + Unit Tests stages already in your Jenkinsfile)
- [ ] You're on your working branch (e.g. `user1-labs`)
- [ ] Your `.bob/mcp.json` still has the `atlassian` bash-launcher entry from the morning intro lab, and `.env` at the repo root with your Jira credentials. We'll dogfood the mode against your own Jira before swapping to the CI form.

---

## Part 1 — Create the `pipeline-dcr-jira-reporter` custom mode

The mode is the **behavior**: it knows how to assemble a DCR from pipeline outputs and is allowed to talk to the Jira MCP server.

Start a new task and switch to **Mode Writer** mode. The prompt below is a starter — read through it to understand what we are trying to add. Anything you want every DCR to follow (section structure, ticket title format, labels, what to do when Jira is down) belongs in this prompt rather than the per-stage call.

The `inputs` section is the list of files that the mode will use to generate the report, they are defined in the pipeline stage in Part 5 of this lab. 

```
Write a custom mode with slug `pipeline-dcr-jira-reporter`. Append it to @.bob/custom_modes.yaml — don't overwrite anything.

Job: generate a Deployment Change Request (DCR) for the branch and file it as a new Jira ticket via the `atlassian` MCP server.

Inputs (relative paths in the workspace):
  - dcr-commits.txt, dcr-diffstat.txt — git material the pipeline pre-computes
  - dcr-context.txt — three KEY=VALUE lines: BUILD_NUMBER, BRANCH, JIRA_PROJECT
  - bob-pr-review.md, bob-test-analysis.md — earlier-stage analyses, if present

Output:
  1. Produce a markdown DCR with H2 sections in this order: Summary, Changes, Risk Assessment, Test Results, Rollback Plan, Reviewer Notes. Plain markdown, no tables, under 200 lines.
  2. File it as a Jira ticket via `jira_create_issue` against the project named by JIRA_PROJECT:
       - Issue type: Task
       - Title: exactly `DCR: <BRANCH> build #<BUILD_NUMBER>`
       - Description: the full DCR markdown
       - Labels: ["bob-dcr", "<BRANCH>"] (sanitize spaces or slashes in the branch name to hyphens)
     Create exactly once. If Jira is unreachable or the call fails, log clearly and continue — the markdown is the source of truth.
  3. Return the DCR markdown plus a one-line "created KAN-N" or "Jira create failed: ..." status so the pipeline stage can echo and archive it.

Hard rules for the Jira call (do NOT deviate from these):
  - Call `jira_create_issue` directly by name. Bob exposes MCP tools as native tools — there is no `use_mcp_tool` wrapper. Do not instruct Bob to invoke any meta-tool or pass `server_name` / `tool_name` arguments. Reference the tool by its name only.
  - Describe the call's fields in prose only (project, summary, description, issue type, labels). Do NOT hardcode a JSON arguments object in the mode. `mcp-atlassian`'s parameter names have shifted across versions (`project` vs `project_key`, `issuetype` vs `issue_type`); the live tool schema is the source of truth and Bob will resolve the correct field names at call time.

Tool groups:
  - read
  - mcp
```


> **Why this mode is more constrained than the modes in previous labs.** This is the first mode in the workshop that calls an external system through an MCP server, and it has to get the tool call right on the first try. The pipeline runs unattended in a Jenkins pod — there's no one to answer a clarification prompt or approve an interactive tool call — so a malformed call surfaces as a hard failure.

Submit the prompt to Bob.

The title and label format is a hard contract — Part 7 (if you do it) uses the per-branch label to find prior tickets.

Mode Writer may put everything in the mode definition in `.bob/custom_modes.yaml`, or it may split larger constraints into supporting markdown files under `.bob/rules-pipeline-dcr-jira-reporter/`. Either shape works — what matters is the behavior, which you'll validate in Part 2.

---

## Part 2 — Dogfood the mode against your own Jira

Your JIRA MCP server should be `.bob/mcp.json` from the morning intro lab. Lets use that to validate the mode before we run it on the pipeline. In part 5, we will have the pipeline create 3 files that act as inputs for Bob. Let's create them locally now for testing. Open your terminal in Bob and run these from the repo root, then paste:

```bash
git log origin/main..HEAD --pretty=format:'%h %s' > dcr-commits.txt
git diff origin/main...HEAD --stat > dcr-diffstat.txt
printf 'BUILD_NUMBER=local\nBRANCH=%s\nJIRA_PROJECT=KAN\n' "$(git rev-parse --abbrev-ref HEAD)" > dcr-context.txt
```

These three files are throwaway scratch — they exist only to mirror what the pipeline writes at runtime. We delete them in Part 6 before committing.

Now start a new task, and switch to the new `pipeline-dcr-jira-reporter` mode in Bob's mode picker (or type `/pipeline-dcr-jira-reporter`) and ask Bob to generate the DCR:

```
Generate the DCR for this branch using dcr-commits.txt, dcr-diffstat.txt, and dcr-context.txt. File the resulting Jira ticket per the mode's rules.
```

Watch Bob:

1. Read the three input files
2. Assemble the markdown DCR
3. Call `jira_create_issue` against your own Jira instance
4. Report back the ticket key

If Bob fails any MCP tool calls during this step, call over an instructor. This means we need to provide more explicit instructions to Bob about how to call the MCP tools in the mode. Since this will be running on the pipeline, any need for human interaction will be skipped over by Bob. 

Open your own JIRA board to view the ticket. Read the description. Check the labels. Decide if it's you are happy with it.

---

## Part 3 — Iterate if needed

If the first dogfood looked solid — DCR sections are populated, risk assessment is concrete, labels are correct — **skip this part**. Don't add constraints for problems you don't have.

If something is off, switch back to **Mode Writer** and describe the gap concretely. Vague prompts ("make it better") get vague fixes; useful prompts look like:

> When I ran the mode, the Rollback Plan section was just 'revert the merge'. Tighten the rule so Rollback Plan must reference specific commits and services affected, in at least two sentences.

> The Jira ticket title came out as `DCR: feature/refunds build #local` — the slash in the branch name wasn't sanitized. Enforce that branch names are converted to lowercase + hyphens before being used in the title or labels.

Mode Writer will update the mode definition (and may break large constraints out into rules files under `.bob/rules-pipeline-dcr-jira-reporter/` — that's fine, leave whatever shape it produces).

Re-run Part 2's dogfood. Confirm the fix landed. Delete the bad ticket from your Jira board and repeat until the output is solid.

This is the agentic-development loop: write the mode, run it, observe drift, tighten the rules, run it again. The IDE is the cheap place to do this — CI is not.

---

## Part 4 — Swap `.bob/mcp.json` to the cluster-friendly form

Now that your mode is validated in the IDE, we are going to add a new JIRA MCP declaration that Bob can use on the pipeline. Rename your existing `atlassian` MCP server to `atlassianIDE`, then add the new declaration below. The bash launcher works fine in your local IDE because `.env` sits next to the repo on your machine; it does **not** work in the pipeline pod — there's no `.env` file inside the `bob-cli` container, and we don't want one. Secrets in CI come from Kubernetes.

Open `.bob/mcp.json` and append the new `atlassian` entry, your `mcp.json` should look like this:

```json
{
  "mcpServers": {
  "atlassianIDE": {
    ...
  },
  "atlassian": {
    "command": "uvx",
    "args": ["mcp-atlassian"],
    "env": {
      "JIRA_URL": "${JIRA_URL}",
      "JIRA_USERNAME": "${JIRA_USERNAME}",
      "JIRA_API_TOKEN": "${JIRA_API_TOKEN}"
    },
    "disabled": false,
    "alwaysAllow": ["jira_get_issue", "jira_search", "jira_add_comment", "jira_create_issue"]
    }
  }
}
```

### Key characteristics of this MCP registration:

- **Server name**: `atlassian` (same as the intro lab — the mode's `alwaysAllow` list and any explicit `mcp__atlassian__*` tool calls reference this string)
- **Transport**: `stdio` (the default — `uvx` launches the server as a subprocess of bob)
- **Credentials**: pulled from the container's environment via `${VAR}` substitution, **not** baked into `mcp.json` and **not** read from a `.env` file on disk. The cluster has already injected `JIRA_URL`, `JIRA_USERNAME`, and `JIRA_API_TOKEN` into the `bob-cli` pod as env vars (same `secretKeyRef` pattern as `BOBSHELL_API_KEY`).
- **`disabled: false`**: explicit because the file is committed to git and a future maintainer reading it shouldn't have to guess
- **`alwaysAllow` list**: By default, Bob requires human approval for all MCP tool calls. When we run Bob on a remote cluster, we aren't able to provide approval to Bob. Anything not in `alwaysAllow` will require the model's tool call to surface a prompt that nobody is around to answer in a CI run, so the Jira write effectively no-ops — which is sometimes what you want. Treat this list as the contract.

After saving `.bob/mcp.json`, restart the `atlassian` MCP server so Bob picks up the new config:

1. Open **Settings → MCP**
2. Find `atlassian` in the server list, click on it
3. Click the restart/reload button

---

## Part 5 — Add the `DCR` stage to your Jenkinsfile

Start a new task and switch to the **Jenkins Pipeline Integration** mode (same one you used in Labs 1 and 2). Paste the following prompt:

```
Add a "DCR" stage to @Jenkinsfile right after the Unit Tests stage. It should be the last stage before the global post block. The stage should:

- Gather change material into three relative-path files in the workspace:
    - dcr-commits.txt — output of `git log origin/main..HEAD --pretty=format:'%h %s'`
    - dcr-diffstat.txt — output of `git diff origin/main...HEAD --stat`
    - dcr-context.txt — exactly three lines: `BUILD_NUMBER=${BUILD_NUMBER}`, `BRANCH=$(git rev-parse --abbrev-ref HEAD)`, `JIRA_PROJECT=KAN` (derive BRANCH from git since `BRANCH_NAME` isn't set on non-multibranch pipelines; hardcode `JIRA_PROJECT=KAN` since every student's Jira instance uses that key and the env var isn't available in the default container)
- Call askBob with the `pipeline-dcr-jira-reporter` mode and a short prompt asking Bob to read those three files (plus `bob-pr-review.md` and `bob-test-analysis.md` if present) and produce the DCR per the mode's rules
- Save askBob's return value to deployment-change-request.md and archive it as a build artifact
```

---

## Part 6 — Push and watch

Before staging anything, delete the dogfood artifacts you created in Part 2. They share names with files the pipeline writes at runtime and should never live on a branch:

```bash
rm -f dcr-commits.txt dcr-diffstat.txt dcr-context.txt
```

Run `git status` and confirm the only modified/new files are the ones you actually meant to change (`Jenkinsfile`, `.bob/mcp.json`, `.bob/custom_modes.yaml`, possibly a `.bob/rules-pipeline-dcr-jira-reporter/` directory).

Then:

```bash
git add Jenkinsfile .bob/
git commit -m "Lab 5 — DCR stage with Jira MCP reporting"
git push
```

In Jenkins, click **Build Now** on your pipeline and watch the console.

Expected:

- `Checkout`, `PR Review`, and `Unit Tests` run as in Labs 1 & 2
- `DCR` stage runs last. The console shows your stage's banner with the generated DCR markdown printed between the banner lines, followed by the new Jira ticket key and URL
- Build page lists `deployment-change-request.md` under **Build Artifacts**
- A brand-new ticket appears in your assigned Jira project (the one named by `JIRA_PROJECT`). Open the project's board — you'll see your ticket alongside everyone else's on your instance
- The board is shared with up to 4 other students on the same Jira instance. To find just your tickets, click the board's label filter and pick your branch name (e.g., `user1-labs`) — every DCR ticket gets that label
- Pipeline ends SUCCESS (or UNSTABLE if Jira was unreachable — but the artifact is still there)

Push a second commit on the same branch and re-build. You'll get a **second** ticket — `DCR: user1-labs build #2` next to `DCR: user1-labs build #1`. That's the lab's first-pass behavior: one ticket per build. If that bothers you (it should — release managers don't want a new ticket every commit), [Part 7](#part-7--make-it-idempotent-optional) is for you.

---

## Part 7 — Make it idempotent (optional)

Your pipeline currently creates a **new** Jira ticket on every push. That's fine for a demo, but a release manager looking at the board sees five "DCR: user1-labs build #N" tickets and has to figure out which one matters. The production-grade version is: one ticket per branch, with subsequent builds **commenting on** the original.

You already have everything you need to make this work — the per-branch label (`user1-labs`) the mode applies on create is a stable handle for finding the prior ticket. The work is in two places:

1. **Expand `alwaysAllow` in `.bob/mcp.json`** to include `jira_search` (find prior tickets by label) and `jira_add_comment` (post the new DCR onto the existing ticket).
2. **Refine the mode's rules** so its Jira flow becomes:
   - First call `jira_search` with a JQL query like `project = ${JIRA_PROJECT} AND labels = "<BRANCH>" AND labels = "bob-dcr" ORDER BY created DESC`
   - If the search returns one or more tickets, use `jira_add_comment` on the most recent one with the new DCR (or a digest of it — long comments get unwieldy on a real ticket)
   - If the search returns nothing, fall back to the create flow you already have
   - Log clearly which path was taken so the Jenkins console tells you "commented on KAN-3" vs "created KAN-7"

Push twice and confirm: the first push creates a ticket, the second push lands a comment on the same ticket. Open the ticket and read the comment thread — does it tell a clear story across builds, or does each comment repeat too much?

If the search ever returns the **wrong** ticket (e.g., a coworker's tickets show up because branch labels collide), that's a signal to tighten the JQL — narrow by reporter, by additional label, or by date. The whole point of the rules file is to encode that contract once and have every build respect it.

---

## Stuck?

- **`uvx: command not found` in the bob container's startup logs.** The image doesn't have `uv` installed. The fix is on the instructor — `setup/bob-cli/Dockerfile` needs `pip install uv` (or `curl -LsSf https://astral.sh/uv/install.sh | sh`) and a rebuild + push. Without this, the MCP server can't launch.
- **MCP server connects but every Jira call returns 401.** The `JIRA_*` env vars aren't reaching the bob container. Confirm the secret was created in the `jenkins` namespace and that the container's `env` block in the Jenkinsfile pod spec references it via `secretKeyRef`. Rotate the API token if the credential is correct but expired.
- **`jira_create_issue` returns 400 / "project is required"  / "No project could be found".** `JIRA_PROJECT` is empty or wrong in `dcr-context.txt`. Confirm (a) the env var is injected into the bob container alongside the other `JIRA_*` vars, and (b) the value matches an existing project key on your instance — capitalization matters (`KAN` ≠ `kan`).
- **`jira_create_issue` returns 403 / "you do not have permission".** The API token's account doesn't have *Create Issues* on the target project. On Jira Cloud free, the site admin (your instructor) can grant this in **Project settings → Access**. Don't add `jira_*` write tools to `alwaysAllow` as a workaround — fix the permission.
- **Ticket is created but the description is empty / shows raw markdown asterisks.** `mcp-atlassian` converts markdown to Atlassian Document Format on send, but headers and code blocks sometimes render weirdly. Read the actual ticket on Jira's web UI before assuming the data is wrong — it's often just a render difference between the Jenkins console and Jira's editor.
- **Bob says `Tool jira_transition_issue not in alwaysAllow list`.** Working as intended. Mutating tools that aren't in the list trigger an interactive approval prompt, which never gets answered in CI. Either add the tool to `alwaysAllow` (only if you actually want CI to perform that action), or rewrite the mode's rules so it doesn't try to transition.
- **I can't find my ticket on the shared board.** Use the board's label filter and pick your branch name. If you don't see your branch under the label dropdown at all, the create call probably never happened — check the console for an error from `jira_create_issue`. If your branch contains a slash or other unusual character, the mode should have sanitized it to hyphens; look for the sanitized form in the labels.
- **Build goes UNSTABLE but everything else worked.** Open the archived `deployment-change-request.md` and the console output for the `DCR` stage. The most common cause is the MCP server timing out on a slow Jira instance — the DCR file is still good, the build is just flagging that the Jira side didn't confirm.
- **Want to validate `.bob/mcp.json` locally before pushing.** Most JSON validators work, but if you also want to check that Bob can parse it: in your IDE, run `bob --list-mcp-servers` (or whatever the equivalent command is in the version you're on) — the same parser runs in both places.
- **`Jenkinsfile` not working?** Copy `Jenkinsfile.lab5solution` from the repo root over your own `Jenkinsfile` and push. That's the reference state after Lab 5 with all 5 stages integrated.

---

That's Lab 5 — and the workshop. You now have a Jenkins pipeline that reviews diffs, runs and diagnoses tests, and files a structured release report into Jira, all driven by Bob and all configured from a single branch in this repo.
