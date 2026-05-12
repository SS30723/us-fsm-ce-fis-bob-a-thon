# Lab 1 — Code Review with Bob

## Table of Contents

- [Overview of Lab 1](#overview-of-lab-1)
  - [The story](#the-story)
  - [What you'll build in Lab 1](#what-youll-build-in-lab-1)
  - [What you'll reuse from the repo](#what-youll-reuse-from-the-repo)
- [Before you start](#before-you-start)
- [Part 1 — Branch off main and capture team standards as Bob rules](#part-1--branch-off-main-and-capture-team-standards-as-bob-rules)
- [Part 2 — Pull the ticket, move it In Progress, build the feature](#part-2--pull-the-ticket-move-it-in-progress-build-the-feature)
- [Part 3 — Pre-commit gauntlet, lap 1: built-in `/review`](#part-3--pre-commit-gauntlet-lap-1-built-in-review)
- [Part 4 — Pre-commit gauntlet, lap 2: standards-aware review with a custom mode](#part-4--pre-commit-gauntlet-lap-2-standards-aware-review-with-a-custom-mode)
- [Part 5 — Pre-commit gauntlet, lap 3: security review](#part-5--pre-commit-gauntlet-lap-3-security-review)
- [Part 6 — Optional: Advanced Code Review Challenges](#part-6--optional-advanced-code-review-challenges)
- [Stuck?](#stuck)

---

## Overview of Lab 1

You'll add a real feature to the order-service, then put the diff through the same review gauntlet your team should be running before any commit hits `main`. Each lap of the gauntlet is a different Bob surface — built-in slash command, custom mode you write, and a security mode provided in the repo — and each one catches things the others miss.

### The story

You're on the order-service team. Java 17, Spring Boot 3.2, PostgreSQL, PCI-scoped. Remember the refund endpoint ticket you created in the morning intro lab? Customer support needs that endpoint live so they can issue refunds on existing orders. The ticket has acceptance criteria attached.

You'll pull the ticket down with the Jira MCP server you configured this morning, deliver to spec, then run the diff through three reviewers before you commit — because in this codebase the cost of a bug shipping is real money and an audit finding.

### What you'll build in Lab 1

1. **Workspace rules** in `.bob/rules/` — your team's coding standards (SLF4J logging conventions, `BigDecimal` for money, no hardcoded secrets, conventional-commit message format) written once. Every Bob mode that runs in this workspace reads them, including `/review` and the commit-message generator.

2. **The refund feature itself** — `POST /api/orders/{id}/refund` plus tests, implemented in **Code** mode from the Jira ticket's acceptance criteria. The ticket is intentionally minimal; concerns it doesn't mention (authorization, audit logging, idempotency) are exactly what the three review laps will surface.

3. **An `orders-code-reviewer` custom mode** — built with **Mode Writer**, rules in `.bob/rules-orders-code-reviewer/`. Pinned output shape, domain-specific concerns (audit logging, `@Transactional`, money comparisons, PII in logs).

4. **Three review laps** before commit:
   - **Lap 1** — built-in `/review` (broad strokes, populates Bob Findings)
   - **Lap 2** — your `orders-code-reviewer` mode (your standards)
   - **Lap 3** — the provided `software-security-reviewer` mode (vulnerability-focused)

5. **The PR** — created with `/create-pr`, with the security review posted as an inline PR comment via the `gh` CLI. The saved markdown doubles as a wiki-ready review artifact.

### What you'll reuse from the repo

- **The `software-security-reviewer` mode** — a pre-built security review mode shipped with this lab at `labs/app/lab1/software-security-reviewer.yaml`. You'll install it into Bob before running the third review lap in Part 5.

---

## Before you start

- [ ] `gh auth status` shows you're logged into GitHub
- [ ] `mvn test` passes from `order-service/`
- [ ] You have the **ticket key** from the refund ticket you created in the morning intro lab (the one Jira assigned when Bob created it — e.g. `OS-7`, `REF-12`, etc.). If you didn't write it down, jump back to Settings → MCP → atlassian, switch to Advanced mode, and ask: `Use jira_search to find the refund ticket I created earlier.`

---

## Part 1 — Branch off main and capture team standards as Bob rules

**Create your branch.** Start clean off `main` so your refund work is isolated and reviewable. From a terminal at the repo root:

```bash
git checkout main
git pull
git checkout -b lab1-refunds
git push -u origin lab1-refunds
```

**Capture your team's standards.** Real teams have coding standards that aren't fully expressible in a linter — "don't log customer names," "every status transition emits an audit log," "money is always `BigDecimal`." A Bob rules file makes those standards visible to every mode that runs in the workspace, including `/review` and the commit-message generator. You write them once, every reviewer reads them.

Create `.bob/rules/coding-standards.md`:

```markdown
# Order Service Coding Standards

## Logging
- Use SLF4J `logger.info / warn / error`. Never `System.out` or `System.err`.
- Never log customer PII (customerName, email, account id, card number) — not at any level.
- Use `logger.error("message", ex)`, never `e.printStackTrace()`.

## Money handling
- All amounts use `BigDecimal`. Compare with `.compareTo()`, never `==` or `.equals()`.
- Never `double` or `float` for money.

## Configuration
- No hardcoded secrets, IP addresses, URLs, or business thresholds.
- Externalize via `@Value("${...}")` and `application.properties`.

## Persistence and transactions
- Service-layer methods that perform multiple writes must be `@Transactional`.
- Status transitions on `Order` must be validated and audit-logged.

## Crypto
- Never `java.util.Random` for security-sensitive values; use `SecureRandom`.
- Never MD5 or SHA-1; use SHA-256 or stronger.

## Commit messages
- Conventional Commits: `feat | fix | refactor | test | docs | chore`.
- Subject line: `<type>(orders): [ORD-XXXX] <description>` — Jira ticket required.
- Subject ≤ 72 chars. Body explains the *why*, not the *what*.
```

These rules apply everywhere Bob runs in this workspace. You don't have to restate them in any prompt for the rest of the lab.

---

## Part 2 — Pull the ticket, move it In Progress, build the feature

Remember the refund ticket you created in the morning intro lab? Time to pull it down, mark it In Progress, and implement it.

**Fetch the ticket.** Switch to **🤖 Advanced** mode (so MCP tools are available), start a new task, and paste — replacing `<your-ticket-key>` with the actual key Jira assigned:

```
Use jira_get_issue to fetch <your-ticket-key>. Read me the acceptance criteria.
```

Bob calls `jira_get_issue` on the Atlassian MCP server and reads the description back.

**Move the ticket to In Progress.** Before writing code, mark the ticket as work-in-progress — same thing you'd do manually at the start of any sprint task. In the same task, paste:

```
Move <your-ticket-key> to "In Progress" status.
```

Bob picks the Jira transition tool. Because that tool isn't in your `alwaysAllow` list, Bob asks for approval before calling it — approve it once.

Now **open your Jira board in the browser** and confirm the ticket is sitting in the **In Progress** column. Take a moment to look — this is the IDE-to-tracker loop closing in real time, no manual click-through required.

**Build the feature.** Back in Bob, hand off to Code mode:

```
Switch to Code mode and implement the feature described in the ticket. Update the Order model, OrderService, OrderController, and add tests.
```

Bob proposes the mode switch; approve it and let it deliver the feature against the ticket's acceptance criteria.

Bob should automatically run tests, but if it doesn't just tell Bob to test.

**Don't commit yet.** The interesting part of this lab is what the spec didn't ask for — audit logging, idempotency on retries, authorization, validation that the refund amount doesn't exceed the original — and what each review lap catches. Real Jira tickets don't spell these out; that's what code review is for.

---

## Part 3 — Pre-commit gauntlet, lap 1: built-in `/review`

`/review` is Bob's built-in code review command. With no arguments, it analyzes uncommitted changes in your working tree.

In the same task, type:

```
/review
```

Bob scans the diff and populates the **Bob Findings** panel. Expect things like:

- Missing tests for failure paths (refunding an already-refunded order, refund amount over original)
- Magic numbers (e.g. a hardcoded refund window or threshold)
- Possible NPEs in the request-body parsing
- Broad `catch (Exception e)` blocks

Each finding has **Fix with Bob** / **Mark as Resolved** / **Dismiss**. Use **Fix with Bob** on the ones you agree with; dismiss the stylistic noise.

`/review` is the broad pass. It picks up `.bob/rules/coding-standards.md` automatically because workspace rules apply to every mode. The next two laps tighten the focus.

---

## Part 4 — Pre-commit gauntlet, lap 2: standards-aware review with a custom mode

`/review` won't always emphasize your domain's specific concerns — audit logging on money movement, `@Transactional` discipline, money comparisons. A custom code-review mode pins the lens.

Switch to **🪄 Mode Writer** in a new task and paste:

```
Write a custom mode with slug `orders-code-reviewer`. Append it to @.bob/custom_modes.yaml — don't overwrite anything else.

Job: code review specialist for our Java/Spring Boot order-service. Focus on:
- Audit logging on every status transition and money movement
- @Transactional coverage for service methods that perform multiple writes
- BigDecimal-only money handling, .compareTo() not == or .equals()
- No PII (customerName, email, card data) in logs at any level
- Authorization checks for actions that move money (refund, cancel)
- Idempotency guards on operations that can be retried (refunds, payments)

Read @.bob/rules/coding-standards.md and apply those standards. Cite file:line for every finding. Group findings by severity: BLOCKER, MAJOR, MINOR. End with a one-line verdict: "READY TO MERGE" or "BLOCKED ON N FINDINGS".

Tool groups: read only.
```

Mode Writer creates the mode entry in `.bob/custom_modes.yaml` and a `.bob/rules-orders-code-reviewer/` directory with rules that constrain the output shape. Read-only is deliberate — review modes should report and recommend, not edit.

**Restart Bob IDE** so the new mode appears in your mode dropdown.

In a new task, switch to **Orders Code Reviewer** and paste:

```
Review the uncommitted refund changes against our standards.
```

This pass could surface things `/review` glossed over — missing audit log on the refund, no `@Transactional`, a `customerName` in a log line, no idempotency guard, no validation that refund amount ≤ original order amount. Apply the fixes you agree with (in Code mode — Orders Code Reviewer is read-only).

---

## Part 5 — Pre-commit gauntlet, lap 3: security review

The first two laps covered standards and quality. The third lap is about exploitable risk. This directory has a file called `software-security-reviewer.yaml` representing a mode.

Lets import that Mode into Bob. 

1. In your Bob chat window, click the setting cog at the top. 
2. Click Modes on the left side.
3. Find the small import button.
4. Select the file `software-security-reviewer.yaml` from your local filesystem.
5. Restart Bob IDE to ensure the new mode appears.

In a new task, switch to **Software Security Reviewer** and paste:

```
Review the uncommitted refund changes. Focus on:
- Money-movement endpoints without authorization
- PII / cardholder data exposure in logs or error responses
- Weak cryptography (MD5, SHA-1, java.util.Random for security-sensitive values)
- Hardcoded secrets, URLs, or thresholds

Output the standard CRITICAL / HIGH / MEDIUM / LOW findings with code patches. Save the result to bob-security-review.md.
```

The security mode applies a different lens than laps 1 and 2 — same diff, but graded on exploitability rather than style or domain correctness. Save the markdown; you'll post it on the PR in Part 7.

---
## Part 6 — Optional: Advanced Code Review Challenges

If you have completed the lab and want to explore different code review workflows and Bob capabilities, here are some ideas:

### Challenge 1: Create a Git Commit Message Writer Mode
1. Use Mode Writer to create a `commit-message-writer` mode
2. Configure it to read `.bob/rules/coding-standards.md` for commit format requirements
3. Have it analyze uncommitted changes and generate conventional commit messages
4. Include Jira ticket reference, type (feat/fix/refactor), and meaningful body text
5. Test it by asking: "Generate a commit message for my refund changes"

### Challenge 2: Create a Unit Test Writer Mode
1. Design a `test-writer` mode specialized in JUnit 5 and Mockito
2. Configure it to follow your team's test naming conventions
3. Have it identify untested edge cases and generate parameterized tests
4. Test on the refund endpoint: "Write tests for all failure scenarios"

### Challenge 3: Create a Test-and-Commit Orchestrator Mode
1. Build a `test-and-commit-orchestrator` mode that coordinates multiple workflows
2. Configure it to use the `test-writer` mode to run tests
3. If tests pass, use the `commit-message-writer` mode to generate a commit message
4. Have it execute the commit with the generated message
5. Test by asking: "Run the tests and commit when tests pass"
6. Bonus: Add rollback logic if tests fail after code changes

### Challenge 4: Automate Review Findings Export
1. Use Bob to parse the Bob Findings panel and export to JSON
2. Create a script that posts findings as GitHub PR review comments
3. Use the `gh` CLI to add inline comments at specific file:line locations
4. Bonus: Add labels to the PR based on finding severity (needs-security-review, has-blockers)

### Challenge 6: Create a Pre-Commit Hook Integration
1. Write a Git pre-commit hook that runs `/review` automatically
2. Block commits if BLOCKER findings exist
3. Save review results to `.bob/review-history/` with timestamps
4. Add a bypass flag for emergencies: `git commit --no-verify`

### Challenge 7: Implement Review Ratcheting
1. Establish a baseline: run all three review modes and save finding counts
2. Create a script that fails CI if new findings exceed the baseline
3. Use Bob to categorize findings as "new" vs "existing technical debt"
4. Gradually lower the baseline threshold as you fix existing issues

---


## Stuck?

- **The `orders-code-reviewer` mode doesn't appear in the dropdown.** Custom modes load at IDE startup. Restart Bob IDE. Confirm the mode exists: `grep "orders-code-reviewer" .bob/custom_modes.yaml`.

- **The custom mode produces a wall of text instead of structured findings.** The rules in `.bob/rules-orders-code-reviewer/` aren't constraining output enough. Re-open Mode Writer and tighten — explicit BLOCKER/MAJOR/MINOR sections, file:line citation required, one-line verdict at the end.

- **You want to start over.** The lab makes only additive changes. Reset with `git checkout -- order-service/ .bob/ && rm -f .bob/rules/coding-standards.md bob-security-review.md && rm -rf .bob/rules-orders-code-reviewer/`. The `orders-code-reviewer` mode entry will still be in `.bob/custom_modes.yaml` — remove it by hand or with another Mode Writer prompt.

---

When you're ready, open [LAB2_SEMANTIC_VERSIONING.md](../lab2/LAB2_SEMANTIC_VERSIONING.md).
