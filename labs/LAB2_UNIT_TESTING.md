# Lab 2 — Unit Testing with Bob

## Overview of Lab 2

Lab 2 builds on the **foundational infrastructure** from Lab 1 to add automated unit test analysis to your pipeline.

### What you'll build in Lab 2

1. **A custom Bob mode for writing unit tests** (`java-unit-test-mode`) — An IDE mode that's an expert at JUnit 5 + Mockito best practices for Spring Boot applications.

2. **A custom Bob mode for analyzing test failures** (`pipeline-test-failure-analyzer`) — A read-only pipeline mode that diagnoses test failures and provides actionable remediation steps.

3. **A `Unit Tests` stage** in your Jenkinsfile — Uses the `askBob` helper from Lab 1 to run tests and automatically analyze failures.

By the end, failing tests won't just break your build — Bob will explain what broke, why it broke, and how to fix it, all in plain English in your Jenkins console.

### What you'll reuse from Lab 1

- **The `askBob` helper function** — You'll call this to invoke Bob with your test-failure-analyzer mode
- **The `jenkins-bob-integration` mode** — You'll use this in your IDE to write the Unit Tests stage

---

## Before you start

- [ ] Lab 1 complete (your Jenkinsfile already has a PR Review stage)
- [ ] You're working on your branch (e.g. `user1-labs`)

---

## Part 1 — Create a custom mode for writing unit tests

Start a new task and switch to the built-in **Mode Writer** mode. Read this prompt template, then adjust how you see fit before sending. If you have personal preferences about how to write unit tests (naming conventions, @DisplayName annotations, whatever) add it to the prompt. 

```
Write me a custom mode for writing Java unit tests. This mode should be an expert at JUnit 5 + Mockito unit test best practices. Specifically for a Spring Boot application. This mode should also read existing unit tests to ensure we match code style and naming conventions of existing tests. 

The slug should be: java-unit-test-mode

Tool groups:
  - `read`
  - `edit`

Add a rules directory with XML files for this mode. 

Append this to the bottom of the existing custom_modes file, don't overwrite anything. 
```

Watch Bob work on the task, and provide input where needed. 

Once the task is complete, restart Bob IDE for the mode to appear in your mode dropdown. 

---

## Part 2 — Use your new mode to add a test

Start a new task and switch Bob to Ask mode.

Ask Bob:

> "Read @OrderService.java and @OrderServiceTest.java. What edge cases aren't covered?"

Pick one of Bob's suggestions, then in the same task switch to your new unit test mode, and tell Bob:

> "Write a test for [the edge case] and add it to @OrderServiceTest.java."

Bob will write the test. 

Then ask Bob: 

> "Can you run the test and ensure it passes?"

Bob should automatically switch modes and run the tests. 

```bash
cd order-service
mvn test
```

---

## Part 3 — Create a custom mode for analyzing test failures

Your test-writer mode is great for the IDE, but for the pipeline you want something different: a mode that only reads (no edits), trained on test-failure diagnosis.

Start a new task and switch to Mode Writer mode. Paste this as a starting prompt, or enter your own prompt.

```
Write me a custom mode for analyzing test failures on my jenkins pipeline. The mode's purpose to analyze failed test logs and provide a human readable output with actionable steps to rectify. 

Tool groups: read

Slug: pipeline-test-failure-analyzer

Add a rules directory with XML files for this mode. 

Append this to the bottom of the existing custom_modes file, don't overwrite anything. 
```

Notice how this mode has **fewer** permissions than your test-writer — just `read`. That's deliberate: a mode invoked from CI pipelines should do the minimum it needs to.

Since you won't be using this mode in the IDE, there is no need to restart Bob. When we push the branch to github and run the jenkins pipeline, the Bob pod will pickup the new mode. 

---

## Part 4 — Add the Unit Tests stage with Bob analysis to your Jenkinsfile

Ensure you have restarted Bob IDE for the `jenkins-bob-integration` mode to appear in your mode dropdown — modes are loaded at IDE startup.

Then, start a new task and switch to the **Jenkins Bob Integration** mode. From that mode, write your own prompt that asks Bob to do all of the following:

- Add a new stage called **`Unit Tests`** to `@Jenkinsfile` that runs after the PR Review stage.
- The stage should run `mvn test` inside the `order-service/` directory using the `build-tools` container.
- Wrap the maven test execution in `catchError` with `buildResult: 'UNSTABLE'` so the pipeline continues even if tests fail — you want Bob's analysis to run regardless.
- Publish test results to Jenkins UI using the `junit` step pointing to `order-service/target/surefire-reports/*.xml`.
- After the test execution (in a separate script block or post-condition), check if tests failed by looking for test report files with failures.
- If tests failed, call the `askBob` helper with mode `pipeline-test-failure-analyzer` and a prompt telling Bob to read the test reports from `order-service/target/surefire-reports/` and relevant source files under `order-service/src/`.
- Capture Bob's analysis and print it between banner lines in the Jenkins console.
- Write Bob's analysis to `bob-test-analysis.md` and archive it as a build artifact.

Watch Bob work. Before pushing, read the diff and sanity-check:

- The stage uses `catchError` so failures don't kill the pipeline
- The `junit` step path matches the surefire reports location
- `askBob` is called with the exact mode slug `pipeline-test-failure-analyzer`
- The analysis is both printed to console and archived as an artifact

---

## Part 5 — Break a test intentionally and watch Bob analyze it

Pick one of the existing tests (or the one your test-writer mode added) and flip an assertion so it'll fail. For example, in `OrderServiceTest.java`:

```java
// before
assertThat(result).isEqualTo(expected);

// after (deliberate break)
assertThat(result).isEqualTo(expected + 1);
```

After making that change, `git add` all of the new files you made, git commit and push your branch to github. 

In Jenkins, click **Build Now**. Watch:

- `Unit Tests` turns **yellow (UNSTABLE)** — the failing test is recorded, but the pipeline continues
- Jenkins's Test Results link surfaces the failure with the exact assertion message
- `Bob Test Analysis` runs, and the console shows Bob's plain-English breakdown: which test failed, what kind of failure, the likely root cause, and a suggested fix

**That's Lab 2 done.** Revert the broken test, push once more to get back to green, and you're ready for Lab 3.

---

## Stuck?

- **Jenkinsfile not working?** Copy `Jenkinsfile.lab2solution` from the repo root over your own `Jenkinsfile` and push. That's the reference state after Lab 2 — Lab 1 + Lab 2 stages in one file.
- **Mode not loading?** Check (a) `.bob/custom_modes.yaml` has the slug you're passing to `--chat-mode`, (b) the mode's `groups` matches what it needs to do, (c) `.bob/` is on your branch and pushed. Bob reads `.bob/custom_modes.yaml` fresh from the workspace on every pipeline run.
- **`mvn test` fails the stage hard?** You forgot the `catchError` wrapper — without it, Maven's non-zero exit code kills the pipeline before Bob ever runs.
- **`junit` step says "no test reports"?** Check the path: `order-service/target/surefire-reports/*.xml`.

---

When you're ready, open [LAB3_SECURITY_SCANNING.md](LAB3_SECURITY_SCANNING.md).