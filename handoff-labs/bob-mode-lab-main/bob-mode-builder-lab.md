# Bob Mode Builder Lab

**Duration:** ~30 minutes  
**Level:** Beginner to Intermediate  
**Prerequisites:** Basic familiarity with Bob

---

## 🎯 What You'll Learn

By completing this lab, you'll be able to:
- Understand what Bob modes are and why they're a key differentiator
- Create custom modes tailored to your workflows
- Build modes with and without workflows
- Implement todo tracking and mandatory steps
- Share modes across projects or make them globally available

---

## 📚 Introduction to Bob Modes

### What Are Bob Modes?

Bob modes are **customizable behavior profiles** that tailor Bob's instructions, tools, and workflows for specific tasks. Think of them as specialized "personalities" that Bob can adopt to better serve different development scenarios.

### Why Modes Matter: A Key Differentiator

According to the [Bob Differentiators](resources/bob-differentiators.md), **customizable modes** are one of Bob's four key differentiators that set it apart from other AI coding assistants:

> **Customizable Modes** let you tailor the AI's behavior for specific workflows:
> - **Code Mode** - For implementation, refactoring, and file operations
> - **Ask Mode** - For questions, explanations, and learning
> - **Plan Mode** - For architecture planning and task breakdown
> - **Custom Modes** - Create your own modes for specialized workflows

**Key Benefits:**
- ✅ Tailor AI behavior to specific tasks
- ✅ Share custom modes through the marketplace
- ✅ Adapt Bob to your team's unique workflows
- ✅ Ensure consistent behavior across team members
- ✅ Encapsulate domain-specific knowledge and best practices

### Real-World Use Cases

**Example Custom Modes:**
- **Code Review Mode** - Specific quality checks and security reviews
- **Documentation Mode** - Optimized for writing technical docs
- **Architecture Mode** - System design discussions and planning
- **Security Audit Mode** - Vulnerability scanning and compliance
- **Feature Development Mode** - Structured workflow from design to deployment

> **💡 Note for New Users:** If you're new to Bob, modes are accessed via the mode selector in the UI. The default modes (Code, Ask, Plan, Advanced) are always available. Custom modes appear in the same selector once created.

---

## 🔧 Essential Mode Concepts

### Global vs Project Modes

Bob supports two types of modes, both stored in YAML configuration files:

#### **Global Modes**
- **Location:** Stored in `~/.bob/custom_modes.yaml` (user home directory)
- **Availability:** Available in ALL projects and workspaces
- **Use Cases:**
  - Personal workflows you use across projects
  - Company-wide standards and practices
  - General-purpose modes (code review, documentation)
- **How to Create:** Add mode definition to `~/.bob/custom_modes.yaml`

#### **Project Modes**
- **Location:** Stored in `.bob/custom_modes.yaml` (project root directory)
- **Availability:** Only available when that project is open
- **Use Cases:**
  - Project-specific workflows
  - Domain-specific knowledge for that codebase
  - Team conventions for a particular repository
- **Auto-Discovery:** When you clone a repo with `.bob/custom_modes.yaml`, those modes automatically appear in Bob
- **How to Create:** Add mode definition to `.bob/custom_modes.yaml` in your project

**Best Practice:** Start with project modes for experimentation, then promote successful modes to global when they prove useful across projects.


### YAML vs XML: Choosing Your Format

Bob supports two formats for defining modes, and **Mode Writer mode uses a hybrid approach**:

#### **Mode Writer's Default Behavior** 🤖

When you use Mode Writer mode to create a new mode:
- **Mode definition** → YAML format in `.bob/custom_modes.yaml`
- **Rules and workflow** → XML format in `.bob/rules-[mode-slug]/` directory

This hybrid approach combines the best of both worlds:
- Simple YAML for mode metadata and basic configuration
- Structured XML for complex rules and workflows

#### **YAML Format - For Mode Definitions** ✅

**Location:** `.bob/custom_modes.yaml` or `~/.bob/custom_modes.yaml`

**Best For:**
- Mode metadata (slug, name, description)
- Basic instructions
- Simple modes without complex workflows
- All-in-one configuration (if you prefer)

**Advantages:**
- ✅ Single file configuration
- ✅ Easy to read and edit
- ✅ Portable (copy/paste between projects)
- ✅ Version control friendly
- ✅ Standard format for mode marketplace

**Example - Complete Mode in YAML:**
```yaml
modes:
  - slug: code-reviewer
    name: Code Reviewer
    instructions: |
      You are a code review specialist...
    rules:
      - Always check for security issues
      - Verify test coverage
    workflow:
      - step: Initial Review
        mandatory: false
        todos:
          - Read the code changes
```

**Example - Mode Definition with XML Rules:**
```yaml
modes:
  - slug: feature-dev-workflow
    name: Feature Development Workflow
    description: Structured workflow for feature development
    instructions: |
      Follow the structured workflow for feature development.
    # Bob automatically discovers XML files in .bob/rules-feature-dev-workflow/
    # based on the mode slug (convention-based discovery)
```

**Note:** Bob automatically discovers XML files using the pattern `.bob/rules-[mode-slug]/`. No explicit link is needed in the YAML definition. The reference to the XML folder in instructions (line 139 above) is optional documentation for human readers only.

#### **XML Format - For Rules and Workflows** 🔧

**Location:** `.bob/rules-[mode-slug]/` directory with numbered XML files

**Best For:**
- Complex workflows (5+ steps)
- Detailed rule sets
- Structured, hierarchical organization
- Enterprise governance requirements

**Advantages:**
- ✅ Better organization for complex content
- ✅ Structured hierarchy (nested rules, conditions)
- ✅ Easier to maintain large rule sets
- ✅ Split across multiple files (1_workflow.xml, 2_rules.xml, etc.)
- ✅ Clear separation of concerns

**Example Structure:**
```
.bob/
  custom_modes.yaml              # Mode definition
  rules-feature-dev-workflow/    # Rules and workflow
    1_workflow.xml
    2_rules.xml
```

See [examples/.bob/rules-feature-dev-workflow/](examples/.bob/rules-feature-dev-workflow/) for complete XML examples.

#### **Format Decision Guide**

| Scenario | Recommended Approach |
|----------|---------------------|
| Simple mode (no workflow) | YAML only (all-in-one) |
| Mode with workflow (< 5 steps) | YAML only or Hybrid |
| Mode with workflow (5-10 steps) | Hybrid (YAML + XML) |
| Complex workflow (10+ steps) | Hybrid (YAML + XML) |
| Enterprise governance | Hybrid (YAML + XML) |
| Sharing/marketplace | YAML only (easier to share) |

#### **Three Approaches You Can Use**

1. **All-in-One YAML** (Simplest)
   - Everything in `.bob/custom_modes.yaml`
   - Best for simple modes and learning

2. **Hybrid YAML + XML** (Mode Writer Default)
   - Mode definition in YAML
   - Rules/workflow in XML files
   - Best for complex workflows

3. **Manual Choice**
   - You can always manually create modes in either format
   - Mode Writer's hybrid approach is just the default

**Best Practice:** Let Mode Writer choose the format for you. It will create the hybrid structure (YAML + XML) which works well for most use cases. For very simple modes, you can manually consolidate everything into YAML if preferred.

### Mode Storage Format

Modes are defined in YAML format within the `custom_modes.yaml` file. Each mode is a YAML object with structured sections for metadata, instructions, rules, and workflows.

**Basic Structure:**
```yaml
modes:
  - slug: mode-slug
    name: Mode Name
    description: Brief description
    instructions: |
      Your mode instructions here
    rules:
      - Rule 1
      - Rule 2
    workflow:
      - step: Step 1 description
        mandatory: false
      - step: Step 2 description
        mandatory: true
```

### Mode Components

A Bob mode consists of several key components defined in YAML format:

#### 1. **Metadata**
```yaml
slug: mode-slug
name: Mode Name
description: Brief description of what this mode does
```

#### 2. **Instructions/Prompts**
The core behavior definition that tells Bob how to act in this mode:
```yaml
instructions: |
  You are a specialized assistant focused on [specific task].
  Your primary goals are:
  - Goal 1
  - Goal 2
  - Goal 3
```

#### 3. **Rules**
Constraints and guidelines Bob must follow:
```yaml
rules:
  - Always check for security vulnerabilities
  - Follow the project's coding standards
  - Include unit tests for all new code
```

#### 4. **Workflows** (Optional)
Step-by-step processes with todo tracking:
```yaml
workflow:
  - step: Analyze requirements
    mandatory: false
  - step: Design solution
    mandatory: true
  - step: Implement code
    mandatory: false
  - step: Write tests
    mandatory: true
  - step: Review and refine
    mandatory: false
```

#### 5. **Mandatory Steps** (Optional)
Steps marked with `mandatory: true` must be completed before proceeding to subsequent steps. Bob will enforce these checkpoints.

#### 6. **User Interaction Options** (Optional)
Predefined choices for common decisions:
```yaml
user_options:
  testing_approach:
    question: "What testing approach should we use?"
    options:
      - label: Unit tests only
        value: unit
      - label: Unit + Integration tests
        value: unit_integration
      - label: Full test pyramid
        value: full_pyramid
```

---

## 🛠️ Creating Your First Mode

### Step-by-Step Guide

#### Step 1: Decide on Initial Mode Type

Start with either:
- **Simple Mode** (no workflow) - For general behavior changes
- **Workflow Mode** - For structured, multi-step processes

> **💡 Note:** You can always add a workflow to a simple mode later, or remove a workflow from a workflow mode. This is just your starting point.

#### Step 2: Use Mode Writer Mode

> **💡 Tip:** Bob has a built-in "Mode Writer" mode that helps you create new modes!

1. Switch to Mode Writer mode in Bob
2. Tell Bob what you want your mode to do:
   ```
   "Create a code review mode that checks for security issues, 
   code quality, and follows our team's style guide"
   ```
3. Bob will generate a mode file for you

#### Step 3: Customize the Generated Mode

Review and edit the generated mode file:
- Adjust instructions to match your needs
- Add or remove rules
- Configure workflow steps if needed
- Set mandatory checkpoints

> **💡 Note:** Mode Writer mode will automatically save the mode definition to the appropriate YAML file (`.bob/custom_modes.yaml` for project modes or `~/.bob/custom_modes.yaml` for global modes). You can also manually specify where to save it.

#### Step 4: Test Your Mode

1. Restart Bob or refresh the mode list (if needed)
2. Select your new mode from the mode selector
3. Test it with a sample task
4. Iterate and refine based on results

#### Step 5: Making a Mode Global

If you created a project mode and want to make it global:

1. Open your project's `.bob/custom_modes.yaml`
2. Copy the mode definition (the entire YAML object for that mode)
3. Open or create `~/.bob/custom_modes.yaml`
4. Paste the mode definition into the global file under the `modes:` array
5. Optionally remove it from the project file if you only want it globally

**Example:**
```yaml
# In ~/.bob/custom_modes.yaml
modes:
  - slug: my-global-mode
    name: My Global Mode
    description: Now available everywhere
    instructions: |
      Mode instructions here
```

---

## 📋 Mode Examples

This lab includes **5 complete mode examples** that you can use as-is or customize:

### Simple Modes (No Workflow)

1. **[Code Reviewer Mode](examples/code-reviewer-mode.md)**
   - Focus: Quality checks, security review, best practices
   - Use case: PR reviews, code audits
   - **Detailed walkthrough below** ⬇️

2. **[API Documentation Writer Mode](examples/api-doc-writer-mode.md)**
   - Focus: Consistent API docs, OpenAPI specs
   - Use case: API documentation projects

3. **[Security Auditor Mode](examples/security-auditor-mode.md)**
   - Focus: Vulnerability scanning, compliance checks
   - Use case: Security assessments

### Workflow Modes (With 5-7 Steps)

4. **[Feature Development Workflow Mode](examples/feature-dev-workflow-mode.md)**
   - Steps: Requirements → Design → Implementation → Testing → Documentation → Review
   - Todo tracking enabled, mandatory design approval
   - **Detailed walkthrough below** ⬇️

5. **[Bug Fix Workflow Mode](examples/bug-fix-workflow-mode.md)**
   - Steps: Reproduce → Root Cause → Fix → Test → Regression Check → Documentation
   - Todo tracking enabled, mandatory testing step

---

## 🔍 Detailed Example 1: Code Reviewer Mode (Simple)

Let's walk through a **simple mode without a workflow** to understand the basic structure.

### Use Case
You want Bob to act as a code reviewer, focusing on:
- Security vulnerabilities
- Code quality and maintainability
- Adherence to best practices
- Performance considerations

### Mode Structure

See the complete mode in [examples/code-reviewer-mode.md](examples/code-reviewer-mode.md). Here's how it would be defined in YAML:

**YAML Definition:**
```yaml
modes:
  - slug: code-reviewer
    name: Code Reviewer Mode
    description: Specialized mode for thorough code reviews
    instructions: |
      You are an expert code reviewer focusing on:
      - Security vulnerabilities
      - Code quality and maintainability
      - Adherence to best practices
      - Performance considerations
    rules:
      - Always start with security concerns
      - Provide specific line numbers for issues
      - Use severity ratings (🔴 Critical, 🟠 High, 🟡 Medium, 🟢 Low)
      - Explain WHY issues matter, not just WHAT they are
      - Provide concrete examples of fixes
    output_format: |
      [Severity] Issue Title
      File: path/to/file, Line: XX
      Issue: Description
      Risk: What could go wrong
      Recommendation: How to fix
      Example: Code showing the fix
```

### Key Features

1. **No Workflow**: Can be used immediately for any code review
2. **Clear Structure**: Consistent output format
3. **Severity Ratings**: Prioritizes issues
4. **Educational**: Explains issues and solutions
5. **Reusable**: Works across any codebase

### When to Use

- Reviewing pull requests
- Auditing existing code
- Pre-deployment security checks
- Training team members on best practices

---

## 🔄 Detailed Example 2: Feature Development Workflow Mode

Now let's examine a **workflow mode** that guides you through a structured process.

### Use Case
Guide developers through the complete feature development lifecycle with clear steps, todo tracking, and mandatory quality checkpoints.

### Mode Structure

See the complete mode in [examples/feature-dev-workflow-mode.md](examples/feature-dev-workflow-mode.md). Here's how it would be defined in YAML:

**YAML Definition:**
```yaml
modes:
  - slug: feature-dev-workflow
    name: Feature Development Workflow
    description: Structured workflow for feature development
    instructions: |
      Guide developers through complete feature development lifecycle
      with clear steps, todo tracking, and mandatory quality checkpoints.
    rules:
      - Follow the workflow steps in order
      - Complete all mandatory steps before proceeding
      - Update todo items as you progress
      - Document decisions and rationale
    workflow:
      - step: Requirements Analysis
        mandatory: false
        todos:
          - Gather and document feature requirements
          - Identify user stories and acceptance criteria
          - List technical constraints
          - Define success metrics
      - step: Design Solution
        mandatory: true
        todos:
          - Create technical design document
          - Review design with team
          - Get design approval before implementation
      - step: Implementation
        mandatory: false
        todos:
          - Write code following design
          - Follow coding standards
          - Implement error handling
      - step: Testing
        mandatory: true
        todos:
          - Write unit tests
          - Write integration tests
          - Achieve required code coverage
          - All tests must pass
      - step: Documentation
        mandatory: false
        todos:
          - Update API documentation
          - Add code comments
          - Update README if needed
      - step: Code Review
        mandatory: false
        todos:
          - Submit pull request
          - Address review comments
          - Get approval from reviewers
      - step: Deployment Preparation
        mandatory: false
        todos:
          - Verify deployment checklist
          - Update deployment docs
          - Plan rollback strategy
    user_options:
      testing_strategy:
        question: "What testing approach should we use?"
        options:
          - label: Unit tests only
            value: unit
          - label: Unit + Integration tests
            value: unit_integration
          - label: Full test pyramid
            value: full_pyramid
      documentation_level:
        question: "What level of documentation is needed?"
        options:
          - label: Minimal (inline comments only)
            value: minimal
          - label: Standard (comments + README)
            value: standard
          - label: Comprehensive (full docs)
            value: comprehensive
```

**Key Features:**
- **7-Step Workflow** with clear progression
- **Mandatory Checkpoints** at steps 2 (Design) and 4 (Testing)
- **Todo Tracking** for each step
- **User Options** for testing strategy and documentation level

### Key Features

1. **Structured Process**: Clear progression through 7 steps
2. **Progress Tracking**: Built-in checklist
3. **Quality Gates**: Mandatory approval and testing
4. **Flexibility**: User options for different scenarios
5. **Guidance**: Questions and best practices at each step

### How It Works

1. Bob starts with Step 1 (Requirements)
2. Guides you through each step with questions
3. Asks for approval at mandatory checkpoints
4. Presents options when decisions are needed
5. Updates todo list as steps complete
6. Confirms completion when all steps done

### When to Use

- Building new features from scratch
- Ensuring consistent development process
- Training junior developers
- Complex features requiring structure

---

## 🐛 Troubleshooting

### Mode Not Appearing in Selector

**Symptoms:** New mode doesn't show up

**Solutions:**
1. Check file location (`.bob/custom_modes.yaml` or `~/.bob/custom_modes.yaml`)
2. Verify YAML syntax is valid
3. Ensure mode slug is unique
4. Restart Bob or refresh modes
5. Check for YAML indentation errors

### Workflow Steps Not Executing

**Symptoms:** Workflow doesn't follow defined steps

**Solutions:**
1. Use proper YAML workflow structure with `step:` and `todos:` fields
2. Set `mandatory: true` for required steps
3. Ensure proper indentation in YAML
4. Reference workflow in mode instructions

### Mode Behavior Not as Expected

**Symptoms:** Bob doesn't follow instructions

**Solutions:**
1. Make instructions specific and explicit
2. Use clear, actionable language
3. Provide examples of desired behavior
4. Avoid conflicting rules
5. Test incrementally

### Getting Help

- Check the 5 provided example modes
- Use Mode Writer mode for assistance
- See [Advanced Topics](bob-mode-advanced.md)
- Ask Bob in Ask mode

---

## 🎓 Next Steps

### Practice Exercises

1. **Customize an Example**
   - Take Code Reviewer mode
   - Add your team's specific standards
   - Test on your codebase

2. **Create a Simple Mode**
   - Identify a repetitive task
   - Create a mode to help
   - Share with your team

3. **Build a Workflow**
   - Map out a multi-step process
   - Create a workflow mode
   - Add mandatory checkpoints

### Advanced Learning

- **[Advanced Topics Guide](bob-mode-advanced.md)** - Complex patterns, MCP integration
- **[Mode Templates](templates/)** - Quick-start templates
- **[Additional Examples](examples/)** - More inspiration

### Share Your Modes

1. **Team sharing:** Commit `.bob/custom_modes.yaml` to repo
2. **Personal use:** Copy mode definitions to `~/.bob/custom_modes.yaml`
3. **Community:** Contribute to marketplace

---

## 📚 Quick Reference

### Mode Creation Checklist

- [ ] Choose mode type (simple or workflow)
- [ ] Define clear instructions
- [ ] Add specific rules
- [ ] Create workflow steps (if applicable)
- [ ] Mark mandatory steps (if applicable)
- [ ] Add user options (if applicable)
- [ ] Test the mode
- [ ] Save in correct location
- [ ] Verify mode appears in selector

### File Locations

```bash
# Project modes (repo-specific)
.bob/custom_modes.yaml

# Global modes (all projects)
~/.bob/custom_modes.yaml
```

**Note:** All modes are defined within the YAML file, not as separate files.

### Common Commands

```bash
# Create mode directories
mkdir -p .bob/modes          # Project mode
mkdir -p ~/.bob/modes        # Global mode

# View project modes
cat .bob/custom_modes.yaml

# View global modes
cat ~/.bob/custom_modes.yaml

# To copy a mode from project to global:
# 1. Open .bob/custom_modes.yaml
# 2. Copy the mode definition (YAML object)
# 3. Paste into ~/.bob/custom_modes.yaml under the modes: array
```

### Mode File Template

```markdown
# Mode Name
**Slug:** mode-slug
**Description:** What this mode does

## Instructions
You are a specialized assistant for [task].
Your goals are:
- Goal 1
- Goal 2

## Rules
1. Rule 1
2. Rule 2

## Workflow (optional)
1. [ ] Step 1
2. [ ] Step 2

## Mandatory Steps (optional)
- Step X must be approved

## User Options (optional)
When asked about X:
- Option A: Description
- Option B: Description
```

---

## 🎉 Congratulations!

You've completed the Bob Mode Builder Lab! You now know how to:
- ✅ Create custom Bob modes
- ✅ Build workflows with todo tracking
- ✅ Implement mandatory steps
- ✅ Share modes with your team
- ✅ Leverage Bob's key differentiator: customizable modes

**What's Next?**
- Explore the [5 example modes](examples/) in detail
- Read [Advanced Topics](bob-mode-advanced.md) for deeper knowledge
- Use the [templates](templates/) to quickly create new modes
- Share your modes with the community!

---

**Questions or feedback?** Ask Bob in Ask mode or check the documentation.