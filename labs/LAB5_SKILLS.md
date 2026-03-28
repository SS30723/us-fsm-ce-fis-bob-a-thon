# Lab 5: SRE Skills

Create reusable skills that Bob can invoke on demand for common SRE tasks.

**Prerequisites:** Lab 4 complete (SRE Operator mode active with Jenkins MCP).

---

## 5.1 — Review the skills

Three skills are defined in `.bob/skills/`:

| Skill | Trigger | What it does |
|-------|---------|-------------|
| `diagnose-build` | `/diagnose-build` | Reads a failed build log, identifies root cause, suggests fix |
| `create-dcr` | `/create-dcr` | Generates a formal DCR from latest build results |
| `pipeline-status` | `/pipeline-status` | Health check across all pipelines |

Each skill is a `SKILL.md` file with YAML frontmatter (`name`, `description`) and step-by-step instructions.

---

## 5.2 — Test diagnose-build

First, trigger a build that will fail:

```
Trigger sre-pipeline with BRANCH=lab/test-failure
```

Wait for it to finish, then:

```
/diagnose-build
```

Bob should:
1. Find the latest failed build via MCP
2. Pull the full console log
3. Identify the failed stage and root cause
4. Suggest a specific fix with PCI context

---

## 5.3 — Test create-dcr

Run a passing build first:

```
Trigger sre-pipeline with BRANCH=lab/happy-path
```

Then:

```
/create-dcr
```

Bob should pull the build results via MCP and generate a formal DCR with risk assessment, validation evidence, and a recommendation.

Now try it after a failed build — the DCR should recommend REJECT.

---

## 5.4 — Test pipeline-status

```
/pipeline-status
```

Bob should list all jobs with their last build result and flag anything unhealthy.

---

## 5.5 — Create your own skill

Create a new skill at `.bob/skills/<your-skill>/SKILL.md`. Ideas:

**Rollback assessment:**
```yaml
---
name: assess-rollback
description: Determine whether to rollback based on current deployment health
---
```
Steps: check smoke test results, compare with pre-deploy baseline, recommend rollback or investigate.

**Incident report:**
```yaml
---
name: incident-report
description: Generate a post-incident report from a failed deployment
---
```
Steps: gather build log, deployment events, smoke test output, timeline, and produce a formal incident report.

> **Checkpoint:** All three skills work end-to-end using Jenkins MCP data. Bob follows the SRE Operator rules while executing them.

---

## How skills work in Bob

- Skills are reusable instruction sets stored in `.bob/skills/<name>/SKILL.md` (project-level) or `~/.bob/skills/<name>/SKILL.md` (global)
- Each `SKILL.md` requires YAML frontmatter with `name` and `description` fields
- Skills require Advanced mode to run
- Invoke a skill by typing `/<skill-name>` (e.g., `/diagnose-build`)
- Bob uses the `description` field to determine when a skill is relevant
- You can include supporting files (checklists, templates) alongside `SKILL.md` in the same directory
- By default Bob asks permission before activating a skill — this can be changed in Auto-Approve settings
