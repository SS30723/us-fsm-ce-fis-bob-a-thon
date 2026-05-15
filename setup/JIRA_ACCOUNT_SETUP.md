# Jira Account Setup — Bob-a-thon Workshop

Setup steps for the 14 Jira instances Lab 5 needs. Users are paired across the 14 instances (user1/2 share `jira-creds-a`, user3/4 share `jira-creds-b`, …, user27/28 share `jira-creds-n`). user29–user40 share user28's instance (`jira-creds-n`).

## Table of Contents

1. [Instance assignments](#1-instance-assignments)
2. [Per-instance Jira setup](#2-per-instance-jira-setup)
   - [2.1 Create the site](#21-create-the-site)
   - [2.2 Create the project](#22-create-the-project)
   - [2.3 Disable notifications](#23-disable-notifications)
   - [2.4 Open project visibility](#24-open-project-visibility)
   - [2.5 Generate the API token](#25-generate-the-api-token)
   - [2.6 Verify with curl](#26-verify-with-curl)
3. [Jenkins admin steps](#3-jenkins-admin-steps)
   - [3.1 Required values](#31-required-values)
   - [3.2 Create the Kubernetes secrets](#32-create-the-kubernetes-secrets)
   - [3.3 Edit the Jenkinsfile pod template](#33-edit-the-jenkinsfile-pod-template)
   - [3.4 Push to main](#34-push-to-main)
4. [Student → instance mapping](#4-student--instance-mapping)
5. [Verification](#5-verification)
6. [Common Issues and Fixes](#common-issues-and-fixes)

---

## 1. Instance assignments

| Secret | Student(s) |
|---|---|
| `jira-creds-a` | user1, user2 |
| `jira-creds-b` | user3, user4 |
| `jira-creds-c` | user5, user6 |
| `jira-creds-d` | user7, user8 |
| `jira-creds-e` | user9, user10 |
| `jira-creds-f` | user11, user12 |
| `jira-creds-g` | user13, user14 |
| `jira-creds-h` | user15, user16 |
| `jira-creds-i` | user17, user18 |
| `jira-creds-j` | user19, user20 |
| `jira-creds-k` | user21, user22 |
| `jira-creds-l` | user23, user24 |
| `jira-creds-m` | user25, user26 |
| `jira-creds-n` | user27, user28 **and** user29–user40 (shared fallback) |

Each instance uses project key `KAN` — Atlassian's default for any Space/project created from the Kanban template. Keys are scoped per-site, so `KAN` on one site is independent of `KAN` on another. No collision.

---

## 2. Per-instance Jira setup

Repeat Section 2 once per Jira account (14 times total). ~15 min each.

### 2.1 Create the site

1. <https://www.atlassian.com/try/cloud/signup?bundle=jira-software>
2. Sign up with a workshop-dedicated email (a throwaway Gmail is fine).
3. Pick the site URL from Section 1 (e.g., `bobathon1.atlassian.net`). The subdomain becomes part of `JIRA_URL`.
4. Choose **Free**.
5. Skip the invite-teammates wizard.

The signup email is your `JIRA_USERNAME`.

### 2.2 Create the project

In Atlassian's newer **Spaces** UI the entry point is **Create** (top-right) → **Space** → **Kanban** template. In classic Jira it's **Projects → Create project**.

1. Choose the **Kanban** template (under "Software development" in classic Jira; under the Kanban tile in Spaces).
2. Name the project/space `FIS Bobathon` (or similar).
3. The project key is auto-assigned as `KAN` — you don't enter it. Confirm by opening the board and checking that sample task cards show `KAN-1`, `KAN-2`.
4. Delete any sample tasks the template seeded.

### 2.3 Disable notifications

Cuts admin inbox noise and avoids hitting the 200/day cap.

1. **Project settings → Notifications**
2. Turn off: Issue created, Issue commented, Issue updated, Issue transitioned.

If the UI doesn't expose toggles for those exact events, add an inbox filter dropping `*@atlassian.net` for the duration of the workshop.

### 2.4 Open project visibility

So students can open ticket URLs without an Atlassian account.

1. **Project settings → Access**
2. Enable public/anonymous read access for the project.
3. Verify by opening any ticket URL in an incognito window.

If your account doesn't expose anonymous read, add students as users on the site (burns 5 of your 10 user slots per instance, but works).

### 2.5 Generate the API token

1. <https://id.atlassian.com/manage-profile/security/api-tokens>
2. **Create API token** → label it `bobathon-jenkins`
3. Copy the token immediately (only shown once). Save in a password manager.

### 2.6 Verify with curl

```bash
curl -s -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
  "$JIRA_URL/rest/api/3/project/$JIRA_PROJECT" | head -50
```

Expected: JSON describing your project. `401` = bad username/token; `404` = bad URL or project key.

---

## 3. Jenkins admin steps

Once all 14 Jira instances are provisioned per Section 2, wire everything up.

### 3.1 Required values

Capture these four values for each of the 14 instances. Keep them in a password manager (1Password, etc.) — **not** Slack or Teams.

| Variable | Example |
|---|---|
| `JIRA_URL` | `https://bobathon1.atlassian.net` (no trailing slash) |
| `JIRA_USERNAME` | `bobathon1@gmail.com` (the signup email) |
| `JIRA_API_TOKEN` | `ATATT3xFf...` |
| `JIRA_PROJECT` | `KAN` |

### 3.2 Create the Kubernetes secrets

Run once per instance, naming the secrets `jira-creds-a` through `jira-creds-n` (14 total):

```bash
oc create secret generic jira-creds-a \
  --from-literal=JIRA_URL=<JIRA_URL> \
  --from-literal=JIRA_USERNAME=<JIRA_USERNAME> \
  --from-literal=JIRA_API_TOKEN=<JIRA_API_TOKEN> \
  --from-literal=JIRA_PROJECT=KAN \
  -n jenkins
```

Grant the Jenkins ServiceAccount read access to all 14 secrets. If a `jira-secret-reader` Role already exists from an earlier (3-secret) version of this setup, delete it first — `oc create role` is not idempotent and won't update `--resource-name` in place:

```bash
oc delete role jira-secret-reader -n jenkins --ignore-not-found

oc create role jira-secret-reader \
  --verb=get \
  --resource=secrets \
  --resource-name=jira-creds-a \
  --resource-name=jira-creds-b \
  --resource-name=jira-creds-c \
  --resource-name=jira-creds-d \
  --resource-name=jira-creds-e \
  --resource-name=jira-creds-f \
  --resource-name=jira-creds-g \
  --resource-name=jira-creds-h \
  --resource-name=jira-creds-i \
  --resource-name=jira-creds-j \
  --resource-name=jira-creds-k \
  --resource-name=jira-creds-l \
  --resource-name=jira-creds-m \
  --resource-name=jira-creds-n \
  -n jenkins

oc create rolebinding jira-secret-reader \
  --role=jira-secret-reader \
  --serviceaccount=jenkins:jenkins \
  -n jenkins
```

### 3.3 Edit the Jenkinsfile pod template

The pod template is inline in the repo's root `Jenkinsfile` (the `yaml """..."""` block in the `agent { kubernetes { } }` stanza). No JCasC, no Jenkins-side template. Two changes:

**Change 1 — routing variable.** Add at the top of the file, above `pipeline { }`:

```groovy
@NonCPS
def routeJiraSecret(String jobName) {
    def m = jobName =~ /user0*(\d+)/
    if (!m) return 'jira-creds-n'
    int userNum = m[0][1].toInteger()
    if (userNum < 1) return 'jira-creds-n'
    def letters = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n']
    int letterIdx = Math.min((userNum - 1).intdiv(2), 13)
    return "jira-creds-${letters[letterIdx]}"
}

def jiraSecret = routeJiraSecret(env.JOB_NAME ?: '')
```

Pulls the numeric portion of the username from the job name (`user1`, `user01`, `user015` all parse to integers) and pairs each user into one of 14 secrets: user1/2 → `jira-creds-a`, user3/4 → `jira-creds-b`, …, user27/28 → `jira-creds-n`. Anything outside that range (user29+, or parse failures) falls through to `jira-creds-n` — the same instance user28 uses.

`.intdiv(2)` is Groovy's integer division (`/` between ints returns a `BigDecimal`, which the array index would reject). The `Math.min(..., 13)` cap handles users above 28 without needing a separate branch.

`@NonCPS` is required: Groovy's regex `Matcher` object isn't `Serializable`, and Jenkins' CPS engine serializes all local pipeline variables across checkpoints. Wrapping the regex work in a `@NonCPS` method keeps the Matcher contained — it never becomes a top-level pipeline variable, so the serializer never sees it.

**Change 2 — env entries.** In the bob container's `env:` block (after `BOBSHELL_API_KEY`, `BOB_ACCEPT_LICENSE`, `HOME`), add:

```yaml
    - name: JIRA_URL
      valueFrom:
        secretKeyRef:
          name: ${jiraSecret}
          key: JIRA_URL
    - name: JIRA_USERNAME
      valueFrom:
        secretKeyRef:
          name: ${jiraSecret}
          key: JIRA_USERNAME
    - name: JIRA_API_TOKEN
      valueFrom:
        secretKeyRef:
          name: ${jiraSecret}
          key: JIRA_API_TOKEN
    - name: JIRA_PROJECT
      valueFrom:
        secretKeyRef:
          name: ${jiraSecret}
          key: JIRA_PROJECT
```

`${jiraSecret}` interpolates via the existing Groovy GString (`"""..."""`) — no syntax change to the YAML block.

### 3.4 Push to main

Commit the updated `Jenkinsfile` to `main`. Students who fork their working branch from `main` after this commit pick up the change automatically. Existing branches need a `git merge main` (or rebase) before Lab 5.

Agent pods are dynamic — no Jenkins or OpenShift restart needed. The next build on each pipeline spawns a pod with the new env vars in place.

> **Verified Bob behavior:** `mcp-atlassian` reads `JIRA_*` from its process environment. Bob expands `${VAR}` placeholders in `.bob/mcp.json`'s `env:` block against its own process env before launching the MCP subprocess. Confirmed 2026-05-06 by an in-cluster test that expanded `${BOB_ACCEPT_LICENSE}` correctly. The lab's existing `mcp.json` config (using `${JIRA_URL}` etc.) works without modification once the env vars are present on the bob container.

---

## 4. Student → instance mapping

| Students | Secret | Site URL to share |
|---|---|---|
| user1, user2 | `jira-creds-a` | URL from the secret |
| user3, user4 | `jira-creds-b` | URL from the secret |
| user5, user6 | `jira-creds-c` | URL from the secret |
| user7, user8 | `jira-creds-d` | URL from the secret |
| user9, user10 | `jira-creds-e` | URL from the secret |
| user11, user12 | `jira-creds-f` | URL from the secret |
| user13, user14 | `jira-creds-g` | URL from the secret |
| user15, user16 | `jira-creds-h` | URL from the secret |
| user17, user18 | `jira-creds-i` | URL from the secret |
| user19, user20 | `jira-creds-j` | URL from the secret |
| user21, user22 | `jira-creds-k` | URL from the secret |
| user23, user24 | `jira-creds-l` | URL from the secret |
| user25, user26 | `jira-creds-m` | URL from the secret |
| user27, user28, **and** user29–user40 | `jira-creds-n` | URL from the secret (shared) |

Each pair of students shares a Jira instance — except user29–user40, who all share user27/28's. Within any shared instance, students filter the project board by their branch label (`user15-labs`, etc.) to find their own DCR tickets.

---

## 5. Verification

Before workshop day, run one full pipeline against each instance:

1. Spot-check a sample of usernames (at minimum user1, user28, and user29 — covers the first pair, the last dedicated pair, and the shared-instance fallback) and create branches `userNN-labs` on the workshop repo.
2. Configure the pipeline per `labs/sre/00_SETUP.md`.
3. Walk the Jenkinsfile through Labs 1, 2, and 5.
4. **Build Now.**

For each build, confirm:
- The `DCR` stage prints a Jira ticket key matching the expected project (e.g., `KAN-1`).
- The ticket is reachable at `<JIRA_URL>/browse/<KEY>` in an incognito window.
- The ticket has labels `bob-dcr` and `<branch>`.
- `deployment-change-request.md` is in the build's archived artifacts.

---

## Common Issues and Fixes

- **`401 Unauthorized` from the curl check.** `JIRA_USERNAME` must be the email address, not a display name. Confirm at <https://id.atlassian.com/manage-profile/profile-and-visibility>.
- **`404 Not Found` from the curl check.** Bad `JIRA_URL` (trailing slash, typo) or wrong project key.
- **`jira_create_issue` returns 403.** API token's account lacks Create Issues on the project. Check **Project settings → Access**.
- **`jira_create_issue` returns 400 / "No project could be found".** `JIRA_PROJECT` is empty in the K8s secret. Re-check the `oc create secret` command.
- **Build fails with `${jiraSecret}` literal in pod YAML.** The Groovy variable wasn't defined or the YAML isn't a GString. Confirm the pod template is wrapped in `"""..."""` (triple double-quote) and the `def jiraSecret = ...` line is above `pipeline { }`.
- **Multiple students share a board, can't find their tickets.** Use the board's **Label** filter and pick the branch name. Every DCR ticket has the branch as a label.
- **Branch name has slashes/spaces — Jira label rejection.** The lab's mode sanitizes branch names to label-safe form. If it isn't, re-prompt Mode Writer to add the sanitization rule.
- **Hit 200-emails/day cap.** Re-do Section 2.3 or set the project's notification scheme to "no notifications" until the cap resets.
