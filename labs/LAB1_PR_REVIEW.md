# Lab 1 — PR / Git Diff Review with Bob

## What you'll build

- An **`askBob` helper function** in your Jenkinsfile — a clean way to call Bob from any stage without repeating the plumbing. You'll reuse this in every subsequent lab.
- A custom Bob mode **`pipeline-git-diff-overview`** that reads a git diff like a senior developer glancing at a PR — summarizing what changed, risk-ranking each change, and calling out areas worth a closer look.
- A **`PR Review` stage** in your Jenkinsfile that runs right after `Checkout`, captures the diff of the commit that triggered the build, and hands it to Bob via the helper.

By the end, every push will trigger a rubber-duck senior reviewer that surfaces risk before any other stage runs.

---

## Before you start

- [ ] Lab 0 complete (branch created, pipeline pointed at it, one successful `Checkout`-only build)
- [ ] You're on your working branch (e.g. `user1-labs`)

---

## Part 1 — Add the `askBob` helper to your Jenkinsfile

Every stage that invokes Bob has to do the same two things: step into `container('bob')` and run `bob --chat-mode …`. Factor that out **once** and each stage just passes a prompt and a mode, and gets back the analysis string to do whatever it wants with.

Because this helper is shared workshop infrastructure — you'll call it the same way in every subsequent lab — we're giving you the code directly rather than having you generate it. Paste it into your `@Jenkinsfile` at the bottom, **outside** the `pipeline { }` block:

```groovy
// ── Helper: ask Bob, optionally with a specific custom mode ──────────────────
// Writes the prompt to a tempfile in the shared workspace and runs
// `bob` in the bob container, adding `--chat-mode <mode>` only if mode is
// provided (otherwise Bob uses its built-in default mode). Returns the
// analysis as a string. Using a tempfile (instead of inlining the prompt
// on the command line) avoids shell-escaping issues when the prompt
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

A few things to notice while you paste it in:

- **It lives outside `pipeline { }`.** Groovy functions at the top level of the Jenkinsfile are callable from any stage. Functions declared *inside* `pipeline { }` get interpreted as stage definitions by the Jenkins DSL, which isn't what you want.
- **It runs inside `container('bob')`.** The pipeline pod has three containers (`build-tools`, `oc-tools`, `bob`). Bob only lives in the last one, so every `bob` command has to be wrapped in `container('bob')`.
- **`mode` is optional** (`String mode = null`). Call `askBob("quick question")` to use Bob's default mode, or `askBob("do the thing", "some-custom-mode")` to pin a specific mode. For every lab in this workshop you'll pass a mode — that's the whole point of custom modes — but keeping the parameter optional means the helper is also usable for one-off asks.
- **The prompt goes through a file, not the command line.** This is the pattern you'll use to hand Bob larger inputs (diffs, scan outputs, logs) later in the workshop. Keeps shell quoting clean no matter what's in the prompt.
- **The helper is deliberately minimal.** It doesn't print banners, write archives, or decide what to do with the result — each stage handles that for itself. Keeps the helper composable for later labs that might do different things with Bob's output (fail the build on a keyword, post a PR comment, push to Jira, etc.).

No push yet — nothing calls the helper. On to the mode.

---

## Part 2 — Create the `pipeline-git-diff-overview` custom mode

The `askBob` helper is mode-agnostic. The *behavior* — what Bob actually does when invoked — comes from the custom mode you pass in. For Lab 1 that's a "senior developer glancing at a PR" mode: a short, risk-ranked summary, not an exhaustive review.

Start a new task and switch to the built-in **Mode Writer** mode. Paste this as a starting prompt, or write your own:

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

Watch Bob work and provide input where it helps.

Notice that this mode has only `read` permission — deliberately narrower than an IDE mode. A pipeline mode should do the minimum it needs to.

Since you won't be invoking this mode from the IDE, there's **no need to restart Bob IDE**. When the pipeline runs, Bob reads `.bob/custom_modes.yaml` fresh from the checked-out workspace, so the new mode is available as soon as the branch is pushed.

---

## Part 3 - Create a custom mode for writing Jenkinsfile stages with Bob integration

Before you start writing stages that call Bob, let's create a mode that understands both Jenkins pipeline DSL and Bob integration patterns. Start a new task and switch to the built-in Mode Writer mode. Paste this prompt:

```
Write me a custom mode for creating Jenkins pipeline stages that integrate Bob. This mode is a specialist in Jenkins Declarative Pipeline DSL + Bob CLI integration patterns.

The slug should be: jenkins-bob-integration

The mode's expertise includes:
  - Writing declarative pipeline stages that invoke Bob via the askBob helper
  - Understanding when to use container('bob') vs other containers
  - Structuring file-based prompts to avoid shell escaping issues (especially with diffs and logs)
  - Selecting appropriate Bob custom modes for different pipeline tasks (PR review, test analysis, security scans, etc.)
  - Handling Bob's output: capturing return values, formatting for Jenkins console (no ANSI colors), archiving as artifacts
  - Making stages resilient with catchError and post blocks so Bob analysis runs even when earlier steps fail
  - Understanding Jenkins workspace file paths (/workspace/...) and temp file patterns
  - Writing clear console banners to make Bob's output easy to spot in build logs

Output constraints for stages this mode creates:
  - Use the askBob helper function (don't inline Bob CLI calls)
  - Always write prompts to temp files, never inline on command line
  - Format console output with clear banner lines (e.g., echo '════════════════')
  - Archive Bob's analysis as build artifacts for historical reference
  - Use catchError with buildResult: 'UNSTABLE' when you want the pipeline to continue after failures

Tool groups:
  - read
  - edit (restricted to Jenkinsfile.* and .bob/custom_modes.yaml only)

Add a rules directory for this mode with XML files covering:
  - The askBob helper pattern and when to use it
  - File-based prompt construction (avoiding shell escaping)
  - Container selection guidelines
  - Output handling patterns (banners, artifacts, console formatting)
  - Error resilience patterns (catchError, post blocks)
  - Common stage patterns (PR review, test analysis, security scan analysis)
  - How to select which Bob custom mode to use for different pipeline tasks

Append the new mode to the bottom of the existing @.bob/custom_modes.yaml file — do not overwrite anything.
```

Watch Bob work and provide input where it helps. This mode will be your go-to for all subsequent labs when you need to add or modify pipeline stages that call Bob.

Since you'll be using this mode in the IDE, restart Bob IDE after the mode is created so it appears in your mode dropdown.

## Part 4 — Add the `PR Review` stage to your Jenkinsfile

Ensure you have restarted Bob IDE for the new `jenkins-bob-integration` mode to appear in your mode dropdown — modes are loaded at IDE startup.

Then, start a new task and switch to the **Jenkins Bob Integration** mode. From that mode, write your own prompt that asks Bob to do all of the following:

- Add a new stage called **`PR Review`** to `@Jenkinsfile` that runs immediately after the Checkout stage.
- Compute the diff of the **entire branch against `main`** (`git diff origin/main...HEAD`) and write the output to **`git-diff.txt`** in the Jenkins workspace — i.e., a plain relative path, **not** `/workspace/git-diff.txt`. Bob's working directory when invoked from the pipeline is the Jenkins job workspace (`/workspace/workspace/<folder>/<job>/`), and Bob's tooling only reads files within that directory subtree. The three-dot syntax mirrors what a reviewer sees in a PR — everything the branch has added since it forked from `main`, not just the latest commit. Jenkins's `checkout scm` already fetches `origin/main`. Make the shell step resilient — fall back to an empty file rather than failing the stage if the diff can't be computed (e.g., on a build of `main` itself).
- Call the `askBob` helper from Part 1 with the mode `pipeline-git-diff-overview` (the one you created in Part 2) and a short prompt telling Bob to read **`git-diff.txt`** (the same relative path, **not** `/workspace/git-diff.txt`) and produce the senior-developer overview the mode is trained for.
- Capture `askBob`'s return value into a local variable.
- Print the analysis between banner lines in the Jenkins console so it's easy to spot in the build log.
- Write the analysis to `bob-pr-review.md` and archive it as a build artifact.

Watch Bob work. Before pushing, read the diff and sanity-check:

- The stage sits between `Checkout` and wherever Lab 2's `Unit Tests` stage will go.
- `askBob` is called with the exact mode slug from Part 2.
- The `archiveArtifacts` path matches the `writeFile` path.

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

**Optional:** make a commit that does something a senior developer would flag — add a null-unchecked parameter, or a broad `catch (Exception e)` that swallows errors, or a hardcoded secret — push, and read Bob's output. Does the risk ranking match your intuition? Does Bob surface the thing you'd mention in a code review? Tune the mode's rules if not.

---

## Stuck?

- **Pipeline fails with something like `askBob: method not found`.** Your helper function is inside the `pipeline { }` block. Move it to the top level of the file (outside the `pipeline { }` braces).
- **Bob stage runs but says the mode wasn't found.** Check (a) `.bob/custom_modes.yaml` contains the slug `pipeline-git-diff-overview`, (b) you're passing that exact string to `askBob`, (c) you committed and pushed `.bob/`. Bob reads `custom_modes.yaml` fresh from the workspace on every run.
- **The diff is empty.** Two common causes: (a) your branch hasn't diverged from `main` yet — there are no commits since the branch point — or (b) `origin/main` isn't available locally on the Jenkins agent (rare, but possible if the Git plugin's clone config was customized). Confirm by adding `git branch -r` to your shell step temporarily: it should list `origin/main` after `checkout scm`. If it doesn't, the agent isn't fetching `main`; you may need an explicit `git fetch origin main` before the diff.
- **Bob says `git-diff.txt` "is not accessible from the current workspace directory".** This means your stage wrote the diff to an absolute path outside Bob's reachable directory tree — almost always `/workspace/git-diff.txt` instead of `git-diff.txt`. Bob's CWD is the Jenkins job workspace (`/workspace/workspace/<folder>/<job>/`), not the root of the shared volume; its tooling won't reach up out of its own workspace. Fix: write the diff to a **relative path** (`git-diff.txt`, no leading slash) and tell Bob to read the same relative path.
- **Bob output looks like a novel, not a triage summary.** The mode's rules file probably isn't constraining output length. Re-open Mode Writer and refine the rules to enforce brevity — cap per-change output to a few lines, require the three-section structure, tell Bob to skip uninteresting changes.
- **`Jenkinsfile` not working?** Copy `Jenkinsfile.lab1solution` from the repo root over your own `Jenkinsfile` and push. That's the reference state after Lab 1 and a safe reset point.

---

When you're ready, open [LAB2_UNIT_TESTING.md](LAB2_UNIT_TESTING.md).
