# Lab 1 — PR / Git Diff Review with Bob

## Table of Contents

- [Overview of Lab 1](#overview-of-lab-1)
  - [What you'll build in Lab 1](#what-youll-build-in-lab-1)
- [Before you start](#before-you-start)
- [Part 1 — Add the `askBob` helper to your Jenkinsfile](#part-1--add-the-askbob-helper-to-your-jenkinsfile)
- [Part 2 — Build the `PR Review` stage with a simple prompt](#part-2--build-the-pr-review-stage-with-a-simple-prompt)
- [Part 3 — TBD: intermediate push & build?](#part-3--tbd-intermediate-push--build)
- [Part 4 — Upgrade `askBob` to accept an optional mode](#part-4--upgrade-askbob-to-accept-an-optional-mode)
- [Part 5 — Create the `pipeline-git-diff-overview` mode](#part-5--create-the-pipeline-git-diff-overview-mode)
  - [Key characteristics of this mode](#key-characteristics-of-this-mode)
- [Part 6 — Update the stage to use the new mode](#part-6--update-the-stage-to-use-the-new-mode)
- [Part 7 — Push and watch](#part-7--push-and-watch)
- [Stuck?](#stuck)

---

## Overview of Lab 1

You'll build a working pipeline stage with a plain prompt, see the limits of that, and then crystallize the behavior you want into a reusable Bob custom mode.

### What you'll build in Lab 1

1. **The `askBob` helper function** — your pipeline's reusable interface to Bob. You'll write it twice: a one-argument version first (just a prompt), then upgrade it to take an optional custom mode once you need one. Every subsequent lab calls this helper.

2. **A `PR Review` stage** — your first pipeline stage that calls `askBob`. You'll build it the cheap way first: hand Bob a one-line prompt and read the generic output. That generic output is the point — it sets up the contrast for what custom modes give you next.

3. **A custom Bob mode** (`pipeline-git-diff-overview`) — once you've felt the limits of a plain prompt, you'll use **Mode Writer** mode to build a reusable mode that produces structured, scannable output. The same stage now produces a senior-developer-style risk-ranked review without you having to spell that out in the prompt each time.

By the end, every push triggers a structured PR review in your Jenkins console — and you've practiced the prompt-then-mode loop you'll repeat for unit tests, security scans, and linting in the labs that follow.

---

## Before you start

- [ ] Lab 0 complete (branch created, pipeline pointed at it, one successful `Checkout`-only build)
- [ ] You're on your working branch (e.g. `user1-labs`)

---

## Part 1 — Add the `askBob` helper to your Jenkinsfile

Every stage that invokes Bob has to do the same two things: step into `container('bob')` and run `bob …`. Factor that out **once** and each stage just passes a prompt and gets back the analysis string to do whatever it wants with.

Because this helper is shared workshop infrastructure — you'll call it the same way in every subsequent lab — we're giving you the code directly rather than having you generate it.

The line that actually invokes Bob is:

```sh
bob -p "$(cat ${promptFile})" --hide-intermediary-output
```

Piece by piece:

- **`bob`** — the Bob CLI, available in the `bob` container.
- **`-p "..."`** — runs Bob in one-shot prompt mode: take this prompt, do the work, print the result to stdout, exit. No interactive chat.
- **`"$(cat ${promptFile})"`** — substitutes in the contents of a tempfile as the prompt. We go through a file (instead of inlining the prompt) because diffs and logs contain quotes, backticks, and newlines that wreck shell escaping.
- **`--hide-intermediary-output`** — suppresses Bob's tool-call traces and "thinking" output so we capture only the final analysis. Without this, `returnStdout` would pick up everything Bob printed about it's thought process along the way.

Now paste the helper into your `@Jenkinsfile` at the bottom, **outside** the `pipeline { }` block:

```groovy
// ── Helper: ask Bob ───────────────────────────────────────────────────────────
// Writes the prompt to a tempfile in the shared workspace and runs `bob` in
// the bob container. Returns the analysis as a string. Using a tempfile
// (instead of inlining the prompt on the command line) avoids shell-escaping
// issues when the prompt contains quotes, backticks, or newlines — common
// with diffs.
def askBob(String prompt) {
    container('bob') {
        def promptFile = ".bob-prompt-${System.currentTimeMillis()}.txt"
        writeFile file: promptFile, text: prompt

        def analysis = sh(
            script: """bob -p "\$(cat ${promptFile})" --hide-intermediary-output""",
            returnStdout: true
        ).trim()

        sh "rm -f ${promptFile}"
        return analysis
    }
}
```

---

## Part 2 — Build the `PR Review` stage with a simple prompt

You're going to write the stage by *describing* it to Bob and letting Bob write the Groovy. Open a new task in your Bob IDE in **Plan** mode and ask Bob to plan a `PR Review` stage for your Jenkinsfile.

The prompt you give Bob should cover the *plumbing* (where in the Jenkinsfile, what to compute, how to call `askBob`) — but the prompt your stage hands to `askBob` should be **deliberately minimal**. Something like:

```
Read git-diff.txt and tell me what changed in this PR.
```

For this lab, our prompt will have two distinct parts. 

The first is **environment context** — quirks of our Jenkins + Bob setup that Bob can't figure out from reading the repo. You have to tell it. The bullets are the same in every pipeline lab, so save them somewhere — you'll paste them into Lab 2's pipeline prompt and beyond. 

The second part is the actual **task**: what *this stage* does, lab-specific.

Here is an example prompt:

```
Add a new stage called "PR Review" to my @Jenkinsfile, immediately after the Checkout stage.

Environment context for our Jenkins + Bob pipeline setup (these apply to any pipeline stage you write — keep them in mind):

- As the FIRST line of any git-using shell step in this pipeline, run:
    git config --global --add safe.directory "$WORKSPACE"
  Without this, git refuses to operate inside the build-tools (maven) container
  with "fatal: detected dubious ownership in repository" — Jenkins's checkout
  creates files owned by a UID different from the one git runs as inside the
  maven image. Scope the trust to $WORKSPACE rather than the '*' wildcard.

- Bob's working directory when invoked from the pipeline is the Jenkins job
  workspace (/workspace/workspace/<folder>/<job>/), and Bob's tooling only
  reads files within that subtree. Any file shared between a shell step and
  Bob must use a PLAIN RELATIVE PATH (e.g. `git-diff.txt`), NEVER an absolute
  path like /workspace/git-diff.txt.

- Jenkins's `checkout scm` already fetches origin/main — you don't need to
  fetch it again before diffing.

What the stage should do:

- Compute the diff of the entire branch against main using three-dot syntax:
    git diff origin/main...HEAD
  Three-dot mirrors what a reviewer sees in a PR — everything the branch has
  added since it forked from main, not just the latest commit. Write the diff
  to git-diff.txt.
- Make the shell step resilient — fall back to writing an empty file rather
  than failing the stage if the diff can't be computed (e.g., on a build of
  main itself).
- Call the askBob helper that's already defined at the bottom of the Jenkinsfile.
  Hand it the literal prompt: "Read git-diff.txt and tell me what changed in
  this PR." Nothing more — keep the prompt short on purpose.
- Capture askBob's return value into a local variable.
- Print the analysis between banner lines (e.g. echo '════════════════') so it's
  easy to spot in the build log.
- Write the analysis to bob-pr-review.md and archive it as a build artifact.

Do NOT modify the askBob helper. Do NOT create any new files outside the Jenkinsfile.
```

Watch Bob work. Before pushing, read the diff and sanity-check:

- The stage sits between `Checkout` and wherever Lab 2's `Unit Tests` stage will go.
- `git config --global --add safe.directory "$WORKSPACE"` is the first line of the shell step.
- `askBob` is called with a single, short prompt — no format hints.
- The diff is written to a relative path (`git-diff.txt`) and Bob is told to read the same relative path.
- The `archiveArtifacts` path matches the `writeFile` path.

---

## Part 3 — TBD: intermediate push & build?

> Decide whether students push and run here — to see Bob's
> generic output and prove the plumbing works — before progressing to modes.
---

## Part 4 — Upgrade `askBob` to accept an optional mode

The helper you wrote in Part 1 takes one argument. That's fine for "ask Bob anything," but every subsequent lab is going to want to pin a *specific* custom mode (so Bob behaves like a unit-test analyst, a security analyst, a linter analyst, etc.). Time to grow the helper.

Replace your `askBob` definition with this version — note the second parameter has a default of `null`, so existing calls (one argument, no mode) keep working unchanged:

```groovy
// ── Helper: ask Bob, optionally with a specific custom mode ──────────────────
// Same as before, but adds `--chat-mode <mode>` only if mode is provided.
// Without a mode, Bob uses its built-in default behavior (what you saw in Part 2).
// With a mode, Bob applies the rules and tools defined for that custom mode.
def askBob(String prompt, String mode = null) {
    container('bob') {
        def promptFile = ".bob-prompt-${System.currentTimeMillis()}.txt"
        writeFile file: promptFile, text: prompt

        def modeFlag = mode ? "--chat-mode ${mode}" : ""
        def analysis = sh(
            script: """bob ${modeFlag} -p "\$(cat ${promptFile})" --hide-intermediary-output""",
            returnStdout: true
        ).trim()

        sh "rm -f ${promptFile}"
        return analysis
    }
}
```

Two things changed:

- **`String mode = null` parameter.** Optional. Existing callers (`askBob(prompt)`) are unaffected. New callers can do `askBob(prompt, "some-mode")` to pin a behavior.
- **`--chat-mode <mode>` is appended only when a mode is passed.** No mode → no flag → Bob uses its built-in default (which is what your Part 2 stage relies on).

Your Part 2 stage still calls `askBob(prompt)` with one argument — and it still works. We haven't broken anything. Now we've got the door open for the next part.

---

## Part 5 — Create the `pipeline-git-diff-overview` mode

Your Part 2 stage works, but the output is generic — whatever Bob feels like saying about a diff that day. For CI you want the same shape every time: a one-line summary, an explicit risk band, a "watch for" list. That's what custom modes are for. The mode owns the *how* (output format, what to prioritize, what to skip) so the stage's prompt can stay short and the *behavior* stays consistent across runs.

### Key characteristics of this mode:

- **Purpose**: Quick risk-oriented PR triage, not exhaustive code review
- **Permissions**: Read-only (minimal permissions for CI environment)
- **Output format**: Plain text optimized for Jenkins console (no ANSI colors or complex markdown)
- **Structure**: Organized sections (Summary, Risk, Watch for) for easy scanning
- **Scope**: Focuses on notable changes only — security, concurrency, null-safety, behavior changes, missing tests

Start a new task and switch to **Plan** mode. Tell Bob you want to draft a prompt for **Mode Writer** mode that defines a custom mode for pipeline-side PR review. Walk through what behavior you want (using the bullets above as a starting point). There's an example prompt at the bottom of this step you can use as a starting point or reference.

Once you're happy with the drafted prompt, copy it, start a new task, switch to **Mode Writer** mode and paste. Press enter and watch Bob create the mode. Bob may ask you a few clarifying questions.

Since you won't be invoking this mode from the IDE (it's used by the pipeline), there's **no need to restart Bob IDE**. When the pipeline runs, Bob reads `.bob/custom_modes.yaml` fresh from the checked-out workspace, so the new mode is available as soon as the branch is pushed.

Notice that this mode has only `read` permission — deliberately narrower than an IDE mode. A pipeline mode should do the minimum it needs to.

```
Write me a custom mode called pipeline-git-diff-overview. The slug should be exactly: pipeline-git-diff-overview.

The mode's job is to look at a git diff like a senior developer glancing at a pull request. It is NOT a full code review — it's a quick risk-oriented overview. For each notable change, it should:
  - Summarize what changed in one or two plain-English sentences
  - Rank the risk as high / medium / low
  - Call out specific things the reviewer should look at closely — null-safety, concurrency, behavior changes, security surface, performance hot paths, tests missing for new branches, etc.

Output constraints:
  - Readable in a Jenkins console — plain text only, no ANSI colors, no markdown tables that rely on column alignment
  - Section headers like "Summary", "Risk", "Watch for"
  - Short — this is a quick triage, not a dissertation. If nothing notable changed, say so in one sentence.

Tool groups: read (only). This mode runs in CI and should have minimum permissions.

Add a rules directory for this mode with XML files describing how to structure the output and what kinds of observations to prioritize.

Append the new mode to the bottom of the existing @.bob/custom_modes.yaml file — do not overwrite anything.
```

---

## Part 6 — Update the stage to use the new mode

You've got an upgraded `askBob` (Part 4) and a custom mode (Part 5). Now wire them together. Open a new task with the default mode (or any mode you like — this is a quick edit), point Bob at `@Jenkinsfile`, and ask it to:

- Update the `PR Review` stage to call `askBob` with **two** arguments: the prompt and the mode slug `pipeline-git-diff-overview`.
- The prompt itself stays short — the mode now owns the format, so something like *"Read `git-diff.txt` and produce the senior-developer PR overview."* is enough.
- Leave the rest of the stage untouched (safe.directory, diff computation, banner printing, artifact archiving).

Re-read the diff and sanity-check:

- `askBob` is called with the exact mode slug from Part 5 (`pipeline-git-diff-overview`).
- The `archiveArtifacts` path still matches the `writeFile` path.

This is the pattern you'll repeat in every subsequent lab: write the stage with a short prompt and let a custom mode shape the output. Modes are how you keep stages small and behaviors consistent.

---

## Part 7 — Push and watch

```bash
git add Jenkinsfile .bob/
git commit -m "Lab 1 — PR review stage with askBob helper + pipeline-git-diff-overview mode"
git push
```

In Jenkins, click **Build Now** on your pipeline and watch the console.

Expected:

- `Checkout` stage turns green
- `PR Review` stage runs next. The console shows your stage's banner (`Bob — PR Review` or however you wrote it) with Bob's summary / risk / watch-for output between the banner lines
- Build page lists `bob-pr-review.md` under **Build Artifacts**
- Pipeline ends SUCCESS

Open the archived artifact from the build page and you've got a persistent record of Bob's take on that commit — searchable in Jenkins's build history.

**Optional:** make a commit that does something a senior developer would flag — add a null-unchecked parameter, or a broad `catch (Exception e)` that swallows errors, or a hardcoded secret — push, and read Bob's output. Does the risk ranking match your intuition? Does Bob surface the thing you'd mention in a code review? Tune the mode's rules if not.

---

## Stuck?

- **Pipeline fails with something like `askBob: method not found`.** Your helper function is inside the `pipeline { }` block. Move it to the top level of the file (outside the `pipeline { }` braces).
- **Bob stage runs but says the mode wasn't found.** Check (a) `.bob/custom_modes.yaml` contains the slug `pipeline-git-diff-overview`, (b) you're passing that exact string to `askBob`, (c) you committed and pushed `.bob/`. Bob reads `custom_modes.yaml` fresh from the workspace on every run.
- **Part 2 stage works but the output is messy / inconsistent across runs.** Expected — that's the whole reason for Parts 4–6. Without a mode, you're relying on the prompt to enforce format every time, and the prompt in Part 2 is intentionally minimal.
- **The diff is empty.** Two common causes: (a) your branch hasn't diverged from `main` yet — there are no commits since the branch point — or (b) `origin/main` isn't available locally on the Jenkins agent (rare, but possible if the Git plugin's clone config was customized). Confirm by adding `git branch -r` to your shell step temporarily: it should list `origin/main` after `checkout scm`. If it doesn't, the agent isn't fetching `main`; you may need an explicit `git fetch origin main` before the diff.
- **Pipeline fails with `fatal: detected dubious ownership in repository`.** Git refuses to operate when the directory's owner UID doesn't match the user running git. The `build-tools` (maven) container runs as a different user than the one that owns the checked-out files. Fix: add `git config --global --add safe.directory "$WORKSPACE"` as the **first** command in your stage's shell step, before any other git invocation. Use `$WORKSPACE` rather than the `'*'` wildcard so you're only trusting the directory you actually need.
- **Bob says `git-diff.txt` "is not accessible from the current workspace directory".** This means your stage wrote the diff to an absolute path outside Bob's reachable directory tree — almost always `/workspace/git-diff.txt` instead of `git-diff.txt`. Bob's CWD is the Jenkins job workspace (`/workspace/workspace/<folder>/<job>/`), not the root of the shared volume; its tooling won't reach up out of its own workspace. Fix: write the diff to a **relative path** (`git-diff.txt`, no leading slash) and tell Bob to read the same relative path.
- **Bob output looks like a novel, not a triage summary.** The mode's rules file probably isn't constraining output length. Re-open Mode Writer and refine the rules to enforce brevity — cap per-change output to a few lines, require the three-section structure, tell Bob to skip uninteresting changes.
- **`Jenkinsfile` not working?** Copy `Jenkinsfile.lab1solution` from the repo root over your own `Jenkinsfile` and push. That's the reference state after Lab 1 and a safe reset point.

---

When you're ready, open [LAB2_UNIT_TESTING.md](LAB2_UNIT_TESTING.md).
