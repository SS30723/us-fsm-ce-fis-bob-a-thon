# Jira Disaster Recovery — Workshop Day

Fast-path mitigations when one or more `jira-creds-{a..n}` secrets are broken at workshop start. All fixes are cluster-side — students do not need to merge anything, switch branches, or rebuild. Their next Jenkins build picks up the patched secret immediately.

## Table of Contents

1. [Identify which secret is broken](#1-identify-which-secret-is-broken)
2. [Fix A — Patch broken secrets in place](#2-fix-a--patch-broken-secrets-in-place)
3. [Fix B — Collapse everyone onto one instance](#3-fix-b--collapse-everyone-onto-one-instance)
4. [Fix C — Jenkinsfile override (only if pre-staged)](#4-fix-c--jenkinsfile-override-only-if-pre-staged)
5. [Rollback](#5-rollback)

---

## 1. Identify which secret is broken

A student reports their `DCR` stage fails on the Jira call. Map their job name to the secret using the routing in `Jenkinsfile`:

| User | Secret |
|---|---|
| user1, user2 | jira-creds-a |
| user3, user4 | jira-creds-b |
| user5, user6 | jira-creds-c |
| user7, user8 | jira-creds-d |
| user9, user10 | jira-creds-e |
| user11, user12 | jira-creds-f |
| user13, user14 | jira-creds-g |
| user15, user16 | jira-creds-h |
| user17, user18 | jira-creds-i |
| user19, user20 | jira-creds-j |
| user21, user22 | jira-creds-k |
| user23, user24 | jira-creds-l |
| user25, user26 | jira-creds-m |
| user27, user28, **and** user29..user40 | jira-creds-n |

Verify the secret's credentials directly:

```bash
JIRA_URL=$(oc get secret jira-creds-g -n jenkins -o jsonpath='{.data.JIRA_URL}' | base64 -d)
JIRA_USERNAME=$(oc get secret jira-creds-g -n jenkins -o jsonpath='{.data.JIRA_USERNAME}' | base64 -d)
JIRA_API_TOKEN=$(oc get secret jira-creds-g -n jenkins -o jsonpath='{.data.JIRA_API_TOKEN}' | base64 -d)
JIRA_PROJECT=$(oc get secret jira-creds-g -n jenkins -o jsonpath='{.data.JIRA_PROJECT}' | base64 -d)

curl -s -u "$JIRA_USERNAME:$JIRA_API_TOKEN" \
  "$JIRA_URL/rest/api/3/project/$JIRA_PROJECT" | head -20
```

- `401` — bad token/username
- `404` — bad URL or project key
- JSON project body — secret is fine; problem is elsewhere (mode, MCP launch, network)

---

## 2. Fix A — Patch broken secrets in place

Use when one or two secrets are broken and the rest work. Overwrites the broken secret with a copy of a known-good one. The affected student now files tickets on the same Jira instance as the good secret's owner — they remain distinguishable via the branch label filter.

```bash
# Replace jira-creds-g with a copy of jira-creds-a:
oc get secret jira-creds-a -n jenkins -o json \
  | jq '.metadata = {name: "jira-creds-g", namespace: "jenkins"}' \
  | oc replace -n jenkins -f -
```

Repeat per broken secret. No restart needed — next pipeline build mounts the new values.

---

## 3. Fix B — Collapse everyone onto one instance

Use when multiple secrets are broken, you're not sure which, or you want a clean reset. Overwrites all 14 secrets with the contents of one known-good secret (e.g., `jira-creds-a`).

```bash
GOOD=jira-creds-a
for L in a b c d e f g h i j k l m n; do
  TARGET="jira-creds-$L"
  [ "$TARGET" = "$GOOD" ] && continue
  oc get secret "$GOOD" -n jenkins -o json \
    | jq --arg name "$TARGET" '.metadata = {name: $name, namespace: "jenkins"}' \
    | oc replace -n jenkins -f -
done
```

All 20 students now file DCR tickets against one Jira site. The board's label filter (each student's branch name is on every ticket) keeps tickets separable.

RBAC is unaffected — the `jira-secret-reader` Role already grants `get` on all 14 names.

---

## 4. Fix C — Jenkinsfile override (only if pre-staged)

**Only available if this line was committed to `Jenkinsfile` before workshop day:**

```groovy
def jiraSecret = env.JIRA_SECRET_OVERRIDE?.trim() ?: routeJiraSecret(env.JOB_NAME ?: '')
```

If present, set the global env var in **Manage Jenkins → Configure System → Global properties → Environment variables**:

| Name | Value |
|---|---|
| `JIRA_SECRET_OVERRIDE` | `jira-creds-a` |

Save. Next builds across all pipelines route to `jira-creds-a` regardless of job name. No secret edits, no `oc` commands.

Caveat: this only works for students whose branches were cut from (or merged) main *after* the override line was added. If you didn't pre-stage it, use Fix A or B instead.

---

## 5. Rollback

**After Fix A or B:** the original secret contents are gone. Re-run the relevant `oc create secret` block from `setup/JIRA_ACCOUNT_SETUP.md` §3.2 once the broken Jira instance is repaired.

**After Fix C:** delete the `JIRA_SECRET_OVERRIDE` global env var. Routing reverts immediately on the next build.

---

## Decision flow

```
broken count = 1-2 ?
  yes -> Fix A (patch in place)
  no  -> Fix C available (pre-staged) ?
           yes -> Fix C (env override)
           no  -> Fix B (collapse all to one)
```
