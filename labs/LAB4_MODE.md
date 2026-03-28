# Lab 4: Custom SRE Operator Mode

Create a custom Bob mode with rules tailored for SRE operations in a PCI-regulated environment.

**Prerequisites:** Lab 3 complete (Jenkins MCP connected).

---

## 4.1 — Review the mode configuration

The mode is defined in `.bob/custom_modes.yaml`:

```yaml
customModes:
  - slug: sre-operator
    name: SRE Operator
    groups:
      - read
      - command
      - mcp
      - - edit
        - fileRegex: \.(yaml|yml|properties|sh|groovy)$
          description: Infrastructure and pipeline config files only
```

Key design decisions:
- **MCP enabled** — Bob can reach Jenkins directly
- **Edit restricted** — only infra/pipeline files, not application code (SRE shouldn't be editing Java)
- **Command enabled** — Bob can run `oc` and `make` commands

---

## 4.2 — Review the rules

Rules live in `.bob/rules-sre-operator/` and load alphabetically:

| File | Purpose |
|------|---------|
| `01-change-management.md` | DCR requirements, risk levels, approval gates |
| `02-pci-compliance.md` | PCI DSS rules, violation patterns, compliance requirements |
| `03-jenkins-operations.md` | How to use Jenkins MCP tools, pipeline conventions |
| `04-rollback-safety.md` | Rollback procedures, post-rollback verification |

Read through each file. These rules shape how Bob behaves in SRE Operator mode — they're the equivalent of an SRE runbook encoded as AI instructions.

---

## 4.3 — Activate the mode

Switch to the SRE Operator mode:

```
/sre-operator
```

---

## 4.4 — Test the rules

Try these prompts and observe how the rules influence Bob's responses:

**Change management:**
```
The latest build of sre-pipeline passed all checks on lab/happy-path. Should we deploy?
```
Bob should insist on a DCR before deployment.

**PCI compliance:**
```
A developer wants to add System.out.println for debugging in production. Is that OK?
```
Bob should flag this as a PCI violation and cite the relevant requirement.

**Jenkins operations:**
```
Check the status of sre-pipeline and tell me if it's safe to deploy
```
Bob should use the MCP tools to check Jenkins, not ask you to open the UI.

**Rollback:**
```
Smoke tests are failing after the last deployment. What should we do?
```
Bob should recommend rollback with `oc rollout undo` and post-rollback verification.

> **Checkpoint:** Bob's responses reflect the rules — formal DCRs, PCI awareness, MCP-first Jenkins interaction, and rollback procedures.

---

## 4.5 — Customize a rule

Add your own rule. Create `.bob/rules-sre-operator/05-your-rule.md` with a policy relevant to your team. Examples:

- Deployment windows (e.g., no deploys after 4pm Friday)
- Escalation procedures for critical failures
- Required approvers for different risk levels

---

## How modes and rules work in Bob

**Modes:**
- Custom modes are defined in `.bob/custom_modes.yaml` (project-level) or your global Bob config
- Each mode has a `slug`, `name`, `roleDefinition`, `whenToUse`, tool `groups`, and optional `customInstructions`
- Switch modes with `/slug` (e.g., `/sre-operator`) or from the mode dropdown
- Tool groups control what Bob can do: `read`, `edit`, `command`, `browser`, `mcp`
- Edit permissions can be restricted by file regex pattern

**Rules:**
- Mode-specific rules go in `.bob/rules-{mode-slug}/` (preferred) or a single `.bobrules-{mode-slug}` file
- General rules for all modes go in `.bob/rules/`
- Files in rules directories load alphabetically and combine with `customInstructions` from the mode config
- Workspace rules (`.bob/rules/`) override global rules (`~/.bob/rules/`)
- Rules should be specific and actionable — "Use 4 spaces for indentation" not "Format code nicely"
