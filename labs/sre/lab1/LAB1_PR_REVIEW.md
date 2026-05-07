# Lab 1 — PR / Git Diff Review with Bob

## Table of Contents

- [Overview of Lab 1](#overview-of-lab-1)
  - [What you'll build in Lab 1](#what-youll-build-in-lab-1)
- [Before you start](#before-you-start)
- [Part 1 — Add the `askBob` helper to your Jenkinsfile](#part-1--add-the-askbob-helper-to-your-jenkinsfile)
- [Part 2 - Use Bob to analyze git diff](#part-2---use-bob-to-analyze-git-diff)
- [Part 3 - Create the `pipeline-git-diff-overview` mode](#part-3---create-the-pipeline-git-diff-overview-mode)
- [Part 4 — Build the `PR Review` stage](#part-4--build-the-pr-review-stage)
- [Part 5 — Push and watch](#part-5--push-and-watch)
- [Part 6 — Stress-test the mode (optional)](#part-6--stress-test-the-mode-optional)
- [Stuck?](#stuck)

---

## Overview of Lab 1

You'll build a working pipeline stage that can be analyzed with the behavior you want in a reusable Bob custom mode.

### What you'll build in Lab 1

1. **The `askBob` helper function** — your pipeline's reusable interface to Bob. One helper, optional second argument for pinning a custom mode. Every subsequent lab calls this same helper.

2. **A built-in look at the diff** — before writing any pipeline code, you'll use Bob in your IDE (Advanced mode) to analyze the branch diff. The output is fine but unstructured — that gap is what motivates the next part.

3. **A custom Bob mode** (`pipeline-git-diff-overview`) — built with **Mode Writer**, this mode pins the output shape and the read-only permissions a CI mode should have. Your pipeline stage will hand Bob a one-line prompt and the mode does the rest.

4. **The `PR Review` stage** — uses the **Jenkins Pipeline Integration** mode (provided in this repo) to write a stage that calls `askBob` with your new mode and archives the result.

By the end, every push triggers a structured PR review in your Jenkins console — and you've practiced the prompt-then-mode loop you'll repeat for unit tests, security scans, and linting in the labs that follow.

---

## Before you start

- [ ] Lab 0 complete (branch created, pipeline pointed at it, one successful `Checkout`-only build)
- [ ] You're on your working branch (e.g. `user1-labs`)

---

## Part 1 — Add the `askBob` helper to your Jenkinsfile

Every stage of the pipeline that invokes Bob has to do the same two things: step into `container('bob')` and run `bob …`. Factor that out **once** and each stage just passes a prompt and gets back the analysis string to do whatever it wants with.

The code for this function is shared below. Paste the helper into your `@Jenkinsfile` at the bottom, **outside** the `pipeline { }` block:

```groovy
// ── Helper: ask Bob, optionally with a specific custom mode ───────────────────
// Writes the prompt to a tempfile in the shared workspace and runs `bob` in
// the bob container, adding `--chat-mode <slug>` only when a mode is provided.
// Returns the analysis as a string. Using a tempfile (instead of inlining the
// prompt on the command line) avoids shell-escaping issues when the prompt
// contains quotes, backticks, or newlines — common with diffs.
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

Once you've pasted the helper into your `@Jenkinsfile`, save the file, start a new task and switch to **Ask** mode. Ask bob:

```
Can you explain to me the key parts of the askBob function in @Jenkinsfile
```

The line that actually invokes Bob is:

```sh
bob ${modeFlag} -p "$(cat ${promptFile})" --hide-intermediary-output
```

Piece by piece:

- **`bob`** — the Bob CLI, available in the `bob` container.
- **`${modeFlag}`** — placeholder for the optional `--chat-mode <slug>` flag. When `askBob` is called with a second argument (a custom mode slug, e.g. `pipeline-git-diff-overview`), this expands to `--chat-mode pipeline-git-diff-overview` so Bob applies that mode's rules and tools. When no mode is passed, it's empty and Bob uses its built-in default. Custom modes are how you give a stage stable, structured output without spelling out the format in every prompt — you'll build one in Part 5.
- **`-p "..."`** — runs Bob in one-shot prompt mode: take this prompt, do the work, print the result to stdout, exit. No interactive chat.
- **`"$(cat ${promptFile})"`** — substitutes in the contents of a tempfile as the prompt. We go through a file (instead of inlining the prompt) because diffs and logs contain quotes, backticks, and newlines that wreck shell escaping.
- **`--hide-intermediary-output`** — suppresses Bob's tool-call traces and "thinking" output so we capture only the final analysis. Without this, `returnStdout` would pick up everything Bob printed about its thought process along the way.


Once you have a good understanding of how this helper works:

```
git add Jenkinsfile
git commit -m "Add askBob helper to @Jenkinsfile"
git push
```

---

## Part 2 - Use Bob to analyze git diff. 

Start a new task and switch to Advanced mode (bottom left of the Bob chat panel). Ask Bob to analyze the diff. Something like:

```
Bob, analyze the diff between my branch and main.
```

You may need to approve the tool calls Bob tries to make.

Bob has the ability analyze the diff using the `obtain_git_diff` tool, the Github MCP server or even with Github CLI. This is something you can specify in your `AGENTS.md` file once you gain a preference.

This overview of the diff is fine, but we can implement custom modes to get more detailed and better formatted information. 

## Part 3 - Create the `pipeline-git-diff-overview` mode

The overview Bob gave in Part 2 was unstructured — fine for a one-off, noisy on every push. A custom mode pins the output shape and the read-only permissions a CI mode should have.

Start a new task and switch to **Mode Writer** mode. Mode Writer turns a prompt into a reusable custom mode — you
describe the behavior you want once, and Bob applies it on every future invocation of that mode.

The prompt below is a starter for a senior-developer-style diff overview — a quick risk-oriented glance, not a
full code review. Treat it as a base. Anything you want every PR overview to do (output
format, patterns to flag, noise to skip, the tone you want Bob to take) belongs in this prompt.

```
Write a custom mode with slug `pipeline-git-diff-overview`. Append it to @.bob/custom_modes.yaml — don't overwrite anything else.

Job: senior dev glancing at a PR's git diff. Quick risk-oriented overview, not a full review. For each notable change:
  - 1–2 sentences on what changed
  - Risk: high / medium / low
  - Watch for: null-safety, concurrency, behavior changes, security surface, perf hot paths, missing tests

Output: plain text for a Jenkins console (no ANSI, no markdown tables). Sections: Summary, Risk, Watch for. Short — if nothing notable changed, say so in one sentence.

Tool groups: read only.
```

Read-only is deliberate — a pipeline mode should do the minimum it needs to. No IDE restart needed: Bob loads `custom_modes.yaml` fresh from the workspace on every pipeline run.

Run the prompt and answer any questions Bob might have about the implementation. 

---

## Part 4 — Build the `PR Review` stage

Now that you have created a custom mode, let's add the new stage to the `Jenkinsfile`. Start a new task, and switch to the provided **Jenkins Pipeline Integration** mode. This mode was provided to minimize configuration issues with the environment. It knows about `askBob`, the build-tools container, output archiving, and `catchError` resilience patterns. Rules live in `.bob/rules-jenkins-bob-integration/` if you want to look.

Paste the following prompt:

```
  Add a "PR Review" stage to @Jenkinsfile right after the Checkout stage. The stage should:

  - Compute the PR diff and write it to git-diff.txt
  - Call askBob with the pipeline-git-diff-overview mode and a short prompt
    asking it to read git-diff.txt and produce the overview
  - Save the analysis to bob-pr-review.md and archive it as a build artifact
  ```

  Provide feedback to Bob where needed and consider turning on auto-approval for some tool calls. 

---


## Part 5 — Push and watch

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

---

## Part 6 — Stress-test the mode (optional)

Introduce a few changes you'd flag as **high** or **critical** in a real review — broad `catch (Exception e)` that swallows errors, a hardcoded secret, a missing null check, an unbounded loop, an SQL string built by concatenation. Push and watch the build.

Did the mode's risk band match your call on each one? If it under-rated something obvious, that's a signal to refine the rules in `.bob/rules-pipeline-git-diff-overview/` — tighten what counts as "high risk" and what to surface in "Watch for."

---

## Stuck?

- **Pipeline fails with something like `askBob: method not found`.** Your helper function is inside the `pipeline { }` block. Move it to the top level of the file (outside the `pipeline { }` braces).
- **Bob stage runs but says the mode wasn't found.** Check (a) `.bob/custom_modes.yaml` contains the slug `pipeline-git-diff-overview`, (b) you're passing that exact string to `askBob`, (c) you committed and pushed `.bob/`. Bob reads `custom_modes.yaml` fresh from the workspace on every run.
- **Part 2 stage works but the output is messy / inconsistent across runs.** Expected — that's the whole reason for Parts 4–6. Without a mode, you're relying on the prompt to enforce format every time, and the prompt in Part 2 is intentionally minimal.
- **The diff is empty.** Two common causes: (a) your branch hasn't diverged from `main` yet — there are no commits since the branch point — or (b) `origin/main` isn't available locally on the Jenkins agent (rare, but possible if the Git plugin's clone config was customized). Confirm by adding `git branch -r` to your shell step temporarily: it should list `origin/main` after `checkout scm`. If it doesn't, the agent isn't fetching `main`; you may need an explicit `git fetch origin main` before the diff.
- **Pipeline fails with `fatal: detected dubious ownership in repository`.** Git refuses to operate when the directory's owner UID doesn't match the user running git. The `build-tools` (maven) container runs as a different user than the one that owns the checked-out files. Fix: add `git config --global --add safe.directory "$WORKSPACE"` as the **first** command in your stage's shell step, before any other git invocation. Use `$WORKSPACE` rather than the `'*'` wildcard so you're only trusting the directory you actually need.
- **Bob says `git-diff.txt` "is not accessible from the current workspace directory".** This means your stage wrote the diff to an absolute path outside Bob's reachable directory tree — almost always `/workspace/git-diff.txt` instead of `git-diff.txt`. Bob's CWD is the Jenkins job workspace (`/workspace/workspace/<folder>/<job>/`), not the root of the shared volume; its tooling won't reach up out of its own workspace. Fix: write the diff to a **relative path** (`git-diff.txt`, no leading slash) and tell Bob to read the same relative path.
- **Bob output looks like a novel, not a triage summary.** The mode's rules file probably isn't constraining output length. Re-open Mode Writer and refine the rules to enforce brevity — cap per-change output to a few lines, require the three-section structure, tell Bob to skip uninteresting changes.
- **`Jenkinsfile` not working?** Copy `labs/sre/lab1/Jenkinsfile.lab1solution` over your own `Jenkinsfile` and push. That's the reference state after Lab 1 and a safe reset point.

---

When you're ready, open [LAB2_UNIT_TESTING.md](../lab2/LAB2_UNIT_TESTING.md).
