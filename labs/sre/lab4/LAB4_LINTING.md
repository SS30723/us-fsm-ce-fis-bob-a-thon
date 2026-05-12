# Lab 4 — Linting and Compliance with Bob

## Table of Contents

- [Overview](#overview)
  - [What you'll build](#what-youll-build)
  - [Before you start](#before-you-start)
- [Part 1 — Code Linting with Checkstyle](#part-1--code-linting-with-checkstyle)
- [Part 2 — Deployment Artifact Linting](#part-2--deployment-artifact-linting)
- [Part 3 — Create the Bob Linter mode and Pipeline Stage](#part-3--create-the-bob-linter-mode-and-pipeline-stage)
- [Part 4 — Push and watch](#part-4--push-and-watch)
- [Part 5 — Optional: Advanced Linting Challenges](#part-5--optional-advanced-linting-challenges)
- [Troubleshooting](#troubleshooting)

---

## Overview

In this lab, you'll add a multi-tool linting and compliance workflow to the pipeline. All the while using IBM Bob to interpret results and provide recommendations.

> [!NOTE]
>
> - [`order-service/pom.xml`](order-service/pom.xml:74-88) already includes [Checkstyle](https://checkstyle.sourceforge.io/) configuration with Google's style checks. This lab leverages that existing configuration for both IDE and pipeline linting.
> - This lab makes use of the jenkins project / namespace. If you are using a different namespace, please update the Jenkinsfile appropriately.

- You'll use the Checkstyle for Java linter to find and fix Java code quality issues in the IDE.
- You'll use [Hadolint](https://github.com/hadolint/hadolint) to find issues in the `Dockerfile`.
- You'll use [Checkov](https://www.checkov.io/) to find issues in the deployment manifests.
- You'll use [KubeLinter](https://docs.kubelinter.io/) to find issues in the Kubernetes workload.

This lab intentionally makes use of slightly flawed deployment files with predictable findings. That allows us to focus on using AI to:

- interpret the linter findings
- anticipate likely pipeline findings before Jenkins runs
- recommend fixes
- produce a consolidated lint report

### What you'll build

By the end of this lab, you will use Bob to not just interact with linters — but it will explain what matters, which issues overlap across tools, what to fix first, and how to remediate them.

- **A Bob mode for lint reporting** (`pipeline-lint-analyzer`) — a read-only mode that reads the raw output from multiple linters and turns it into a Jenkins-friendly report.

- **A new set of pipeline stages** — one stage runs the linters (including Checkstyle), one stage asks Bob to summarize the results.

- **A final Bob-enriched lint report** — archived in Jenkins as a build artifact and summarized in a comment artifact.

**Key Concepts** you will learn:

- Linting layers: code quality, container security, infrastructure security, Kubernetes best practices
- De-duplication: recognizing when multiple tools flag the same underlying issue
- Risk-based prioritization: security > reliability > maintainability > style

### Before you start

- [ ] You should have completed Lab 1 at a minimum (your Jenkinsfile already has [`askBob()`](labs/sre/lab1/Jenkinsfile.lab1solution:153))
- [ ] You're on your working branch (for example `user1-labs`)

---

## Part 1 — Code Linting with Checkstyle

Before adding linters to our pipeline, lets start in the Bob IDE with some high level linting tasks at the code level.

1. If we were starting in a new project / application, we could actually have Bob review our application and help us identify linters already in place and provide recommendations for additional linters to consider including.

1. Start a new task in Bob and ensure you are in the **Ask** mode. Then prompt Bob with the following:

    ```text copy
    Analyze the files in my @/order-service  application and recommend what linters I should use in my build and deploy pipeline
    ```

1. Bob will review what linters are in place and what gaps might exist based on the files in the application. Review Bob's recommendations.

1. Lets narrow in on a specific linter. Start a new task in Bob and ensure you are in the **Ask** mode. Then prompt Bob with the following:

    ```text copy
    Read @order-service/src/main/java/com/example/orders/service/OrderService.java.
    Give me a concise view of what kinds of issues Checkstyle will likely flag here, which ones matter most, and what would you recommend fixing first?
    ```

1. Bob itself understands different linting frameworks and can be used to get intuition about what issues Checkstyle will likely flag here, which ones matter most, and what it recommends fixing first. Review Bob's insights.

1. Next, lets actually run Checkstyle from the command line to generate a report with all findings. From the terminal window, execute the following:

    ```bash copy
    cd order-service
    mvn checkstyle:check
    ```

1. This will generate a full report at `order-service/target/checkstyle-result.xml`. Lets ask Bob to analyze the output. In **Ask** mode, prompt Bob with the following:

    ```text copy
    I ran `mvn checkstyle:check` in the order-service directory. Read the output and explain:
    1. What are the most critical violations?
    2. Which ones could impact production reliability?
    3. What should I fix first?
    ```

    > **Note:** Bob will request permission to read the target directory and will find the correct output report xml file.

1. Review the findings from Bob. Notice how Bob:
    - Groups by severity
    - Explains the impact of each issue
    - Provides specific line numbers
    - Suggests concrete fixes
    - Prioritizes what matters most

Bob was not only able to find and read the report, it was able to provide immediate feedback for which are the most critical issues, which impact reliability and a prioritization for fixing the issues. We can use these insights to get ahead of any linting issues before our applications even hit our pipelines.

> **Note:** The prompts we are using can be adapted based on different perspectives, goals and end users.

---

## Part 2 — Deployment Artifact Linting

Beyond linting of the code artifacts, we can use Bob to inspect the deployment artifact files that are used to deploy this application and that the pipeline will scan. For the purposes of this lab, we have created a simplified set of artifacts for a Red Hat OpenShift deployment. The following files have been created with some "flaws", so that we can analyze them in this lab.

- [`order-service/Dockerfile`](order-service/Dockerfile)
- [`order-service/deploy-flawed/deployment.yaml`](order-service/deploy-flawed/deployment.yaml)
- [`order-service/deploy-flawed/service.yaml`](order-service/deploy-flawed/service.yaml)
- [`order-service/deploy-flawed/route.yaml`](order-service/deploy-flawed/route.yaml)

1. Start a new task and switch to **Ask** mode. Try a prompt Bob with the following:

    ```text copy
    Read @order-service/Dockerfile and the manifests under @order-service/deploy-flawed/.
    What issues are likely to be flagged by Hadolint, Checkov, or KubeLinter?
    Group them by file and explain which ones are most important to fix first.
    ```

1. Bob gives you immediate feedback and points out issues even before the linters have been run. Bob should identify issues, such as:

    - use of `latest` in container images
    - plaintext secrets or credentials in env vars
    - missing probes
    - missing resource requests and limits
    - weak or incomplete `securityContext`
    - overly permissive route or service settings

1. That prediction step is useful for two reasons:

    1. it helps you understand what the pipeline linters are likely to find
    2. it gives you a baseline to compare with the actual lint output later

While we could fix these issues now, we will leave these "flaws" in place to see how we can use Bob + various linters to identify the issues and suggest the appropriate fixes in a CI/CD pipeline.

---

## Part 3 — Create the Bob Linter mode and Pipeline Stage

Now, we will create a reusable Bob mode that specializes in lint analysis, insights and remediation recommendations. While we could create a mode to use in our IDE, we are going to focus on creating a mode that can be used in a CI/CD pipeline. The pipeline needs a read-only mode that can synthesize raw lint output from multiple tools and turn it into a concise report.

> Note: While we could use the mode in the Bob IDE, we want to minimize any requirements for installing linters to the lab participant machines, so we are just going to test in the pipeline.

1. Start a new task and switch to **Mode Writer** mode. Then ask Bob to create a new mode with a name `pipeline-lint-analyzer` that it should append to our `@.bob/custom_modes.yaml` file. Use this as a starter prompt:

    ```text copy
    Write a custom mode with slug `pipeline-lint-analyzer`. Append it to @.bob/custom_modes.yaml — don't overwrite anything else.

    Job: read lint output from Checkstyle, Hadolint, Checkov, and KubeLinter, plus the relevant application source files and application deployment files.
    Produce a short Jenkins-friendly report that:
    - groups findings by severity
    - identifies overlap across tools
    - names the most important fix-first items
    - suggests concrete remediations
    - stays concise and practical

    Output: plain text or Markdown suitable for a Jenkins artifact and easy to summarize in a PR comment.
    Use the following sections:
    - Executive Summary
    - Highest Priority Findings
    - Findings by Tool
    - Cross-Tool Themes
    - Recommended Fix Order

    If findings are duplicated across tools, call that out instead of repeating the same issue many times.

    Tool groups: read only.
    ```

    > [!TIP]
    > This prompt is a good starting point that has been tested with the pipeline, but feel free to extend the prompt above with your own preferences.

1. In Part 1 of this lab, you ran Checkstyle manually and saw how Bob can interpret its findings. Now we'll automate this in the pipeline along with other linters. So next, lets add the linting and analysis stages to the pipeline.

1. Start a new task and switch to the provided **Jenkins Pipeline Integration** mode.

1. Ask Bob to update [`Jenkinsfile`](Jenkinsfile) with a lint workflow after the earlier stages. Use a prompt like:

    ```text
    Update @Jenkinsfile to add linting and analysis stages after the existing stages.

    Requirements:
    - Run Checkstyle on the Java code: `mvn -f order-service/pom.xml checkstyle:check`
    - Copy the XML report from `order-service/target/checkstyle-result.xml` to `lint-results/checkstyle.xml`
    - Run Hadolint on @order-service/Dockerfile and save output to `lint-results/hadolint.txt`
    - Run Checkov on @order-service/deploy-flawed/ and save output to `lint-results/checkov.txt`
    - Run KubeLinter on @order-service/deploy-flawed/ and save output to `lint-results/kubelinter.txt`
    - Continue the pipeline even if the linters find issues (use catchError)
    - Archive the lint-results files in the Run Linters stage post block

    For the Bob Lint Analysis stage:
    - Add a `when` condition to only run if at least one lint result file exists
    - In the prompt, let Bob read the files directly - don't embed file contents in the prompt. Tell Bob to read:
        - lint-results/checkstyle.xml
        - lint-results/hadolint.txt
        - lint-results/checkov.txt
        - lint-results/kubelinter.txt
        - order-service/src/
        - order-service/Dockerfile
        - order-service/deploy-flawed/
    - Make a call using askBob using the `pipeline-lint-analyzer` mode to group findings by severity, de-duplicate overlapping findings, identify highest-priority remediations, and recommend concrete fixes
    - Save Bob's analysis to `bob-lint-report.md`
    - Make a second askBob call that reads `bob-lint-report.md` and produces a concise PR comment
    - Save the PR comment to `bob-lint-pr-comment.md`
    - Archive both markdown files in the post block
    - Print a short summary to the console
    ```

    > [!TIP]
    > We are asking Bob to create a "PR comment", which is a concise summary of the lint report. Though not currently implemented, this comment could be attached to a PR and displayed to the reviewer.

1. A couple of things to note about how we are asking Bob to build this into our pipeline:

    - We are asking Bob to split the work into the following stages:
      - `Run Linters` (runs Checkstyle, Hadolint, Checkov, KubeLinter)
      - `Bob Lint Analysis` (analyzes all findings)
      - `Post Lint PR Comment` (posts summary to GitHub)
    - The linters should run in their appropriate containers:
      - Checkstyle runs in the `build-tools` (Maven) container
      - Hadolint, Checkov, and KubeLinter run in the `lint-tools` container
    - The pipeline should produce files like:
      - `lint-results/checkstyle.xml` (or checkstyle.txt)
      - `lint-results/hadolint.txt`
      - `lint-results/checkov.txt`
      - `lint-results/kubelinter.txt`
      - `bob-lint-report.md`
      - `bob-lint-pr-comment.md`
    - Jenkins takes on the following responsibiltiies:
      - running the tools
      - saving files
      - archiving artifacts
    - Bob takes on the following responsibilities:
      - grouping findings
      - prioritizing fixes
      - suggesting remediation
      - generating the report text

1. Feel free to open and review the Jenkinsfile (optionally, you could even ask Bob to summarize the changes in the Jenkinsfile to you).

---

## Part 4 — Push and watch

1. Now that your Jenkinsfile and mode definitions are ready, let push them to your repo.

    ```bash copy
    git add Jenkinsfile .bob/
    git commit -m "Lab 4 — linting and compliance with Bob"
    git push
    ```

1. Back in the Jenkins instance, click **Build Now** and watch the updated pipeline run.

    - Expected behavior:
        - earlier stages still run
        - Checkstyle runs in the Maven container
        - the other lint tools run inside the `lint-tools` container
        - raw outputs are written under `lint-results/`
        - Bob prints a short summary in the console
        - bob-lint-report.md is archived as a build artifact
        - the build may end **UNSTABLE** if findings exist, but should still complete

1. Open the pipeline run artifacts, you should see a consolidated report that is far more useful than the raw scanner output alone.

---

## Part 5 — Optional: Advanced Linting Challenges

If you have completed the lab and want to explore different linting challenges, here are some ideas:

### Challenge 1: Add a Custom Checkstyle Rule

1. Create a custom Checkstyle configuration that enforces your team's naming conventions
2. Update `pom.xml` to use your custom config instead of `google_checks.xml`
3. Run the pipeline and see how Bob interprets your custom rules

### Challenge 2: Create a Lint Threshold Gate

1. Modify the pipeline to fail if critical issues exceed a threshold
2. Use Bob to categorize findings by severity
3. Parse Bob's output to count critical issues
4. Fail the build if count > 5

### Challenge 3: Generate a Trend Report

1. Archive lint results from multiple builds
2. Create a Bob mode that compares current vs. previous results
3. Generate a trend report showing improvement or regression

### Challenge 4: Auto-fix Simple Issues

1. Use Bob to generate fix patches for simple issues (import ordering, formatting)
2. Apply the patches automatically in the pipeline
3. Commit the fixes back to the branch
4. Re-run linters to verify fixes worked

---

## Troubleshooting

- **Checkstyle fails with `command not found`.** Checkstyle runs via Maven, not as a standalone command. Use `mvn checkstyle:check` in the Maven container, not the lint-tools container.
- **Hadolint, Checkov, or KubeLinter fail with `command not found`.** The image was built incorrectly or the wrong image is referenced in the Jenkins pod YAML. Verify the image from [`setup/lint-tools/Dockerfile`](setup/lint-tools/Dockerfile) was pushed and is being used.
- **Checkov output is huge and noisy.** Narrow the scan target to [`order-service/deploy-flawed/`](order-service/deploy-flawed) rather than the whole repo.
- **KubeLinter reports nothing useful.** Make sure you are linting the deployment manifests, especially [`order-service/deploy-flawed/deployment.yaml`](order-service/deploy-flawed/deployment.yaml).
- **`Jenkinsfile` not working?** Use the reference solution in [`labs/sre/lab4/Jenkinsfile.lab4solution`](labs/sre/lab4/Jenkinsfile.lab4solution) as your reset point once it is available in the repo.
- **Hadolint, Checkov, or KubeLinter fail with `command not found`**
  - Cause: The lint-tools image wasn't built correctly or isn't being used
  - Fix: Verify the image from `setup/lint-tools/Dockerfile` was pushed
  - Check: `oc get imagestream lint-tools -n jenkins`
  - Verify: Jenkinsfile references the correct image URL
- **Pipeline succeeds but no lint report is generated**
  - Cause: Bob analysis stage didn't run
  - Check: Verify at least one lint-results/*.txt file exists
  - Check: Look at the `when` condition in "Bob Lint Analysis" stage
  - Debug: Add `sh 'ls -la lint-results'` to see what files were created

---

When you're ready, continue to [`labs/sre/lab5/LAB5_DCR_JIRA.md`](labs/sre/lab5/LAB5_DCR_JIRA.md).