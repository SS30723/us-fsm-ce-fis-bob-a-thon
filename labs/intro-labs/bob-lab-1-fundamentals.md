# Lab 1: Bob Fundamentals
**Duration:** 40 minutes  
**Objective:** Master Bob's core workflows, modes, and interactive capabilities

**Prerequisites:**
- Bob application installed and running
- Basic familiarity with software development concepts

> 📌 **Bob Documentation:** https://bob.ibm.com/docs/ide

---

## Table of Contents
1. [Overview](#overview)
2. [Getting Started](#getting-started-with-bob)
3. [Understanding Modes](#understanding-bobs-modes)
4. [Approvals & Control](#approvals-and-safe-collaboration)
5. [Hands-On Practice](#hands-on-practice)
6. [Key Takeaways](#key-takeaways)
7. [Troubleshooting](#troubleshooting-tips)

---

## Overview

This lab introduces you to Bob's core capabilities through practical, hands-on exercises. You'll learn how to work with Bob effectively, regardless of your specific development environment or project type.

### Learning Objectives

By the end of this lab, you will:

- ✅ Navigate Bob's interface confidently
- ✅ Understand and switch between Bob's modes
- ✅ Master the approval workflow for safe collaboration
- ✅ Use Bob for planning, coding, and learning
- ✅ Apply Bob to your own development workflows

### Why Bob?

> **🎯 Bob Differentiator: Multi-Mode Intelligence**
> Unlike other AI assistants that use a one-size-fits-all approach, Bob provides specialized modes optimized for different tasks. Plan mode helps you design before coding, Code mode implements your ideas, and Ask mode explains concepts. This separation ensures Bob gives you the right type of help at the right time.

---

## Getting Started with Bob

### The Bob Interface

Open the Bob application. The interface is similar to VS Code but optimized for AI-assisted development:

**Key Components:**

1. **Mode Selector** (bottom left)
   - Shows your current mode (Plan, Code, Ask, Advanced)
   - Click to switch between modes
   - Each mode optimizes Bob's behavior for specific tasks

2. **Chat Panel** (main area)
   - Conversation history with Bob
   - Tool activity indicators (when Bob reads/edits files)
   - Input box for your prompts and questions

3. **File Explorer** (left sidebar)
   - Navigate your project structure
   - Create, rename, and delete files
   - Quick access to any file

4. **File Viewer** (right panel)
   - View file contents with syntax highlighting
   - Preview Bob's proposed changes before approval
   - Compare original and modified versions

5. **Settings** (gear icon)
   - Configure API keys and model selection
   - Set auto-approval preferences
   - Manage custom modes
   - Adjust theme and display options

> 📌 **Learn More:** [Chat Interface Features](https://bob.ibm.com/docs/ide/features/chat-interface)

### Your First Interaction

Let's start with a simple conversation to understand Bob's capabilities:

**Try this:**
```text
Hi Bob! I'm new here. Can you tell me 3 things you can help me with?
```

**Then ask:**
```text
What mode are you in right now, and what does that mean?
```

**What's Happening:**
- Bob responds conversationally to help you understand its capabilities
- Bob explains the current mode and its purpose
- You're building familiarity with how Bob communicates

**💡 Tip:** Feel free to ask Bob questions about itself, your project, or development concepts. Bob is designed to be helpful and informative.

---

## Understanding Bob's Modes

Bob has specialized modes, each optimized for different types of work:

> **🎯 Bob Differentiator: Customizable Modes
>
> Bob's mode system is a key differentiator. The three built-in modes are just the beginning—you can create custom modes tailored to your team's specific workflows (code review, documentation, architecture design, DevOps, etc.). This extensibility makes Bob uniquely adaptable to your organization's needs.

### The Three Core Modes

#### 📋 Plan Mode
**When to use:** Planning, designing, strategizing before implementation

**Perfect for:**
- Designing system architecture
- Planning API endpoints
- Creating database schemas
- Breaking down complex features
- Making technical decisions
- Outlining project structure

**Example prompts:**
```text
Help me design a REST API for a user management system
```

```text
Plan the database schema for an e-commerce application
```

```text
What's the best architecture for a microservices-based system?
```

#### 💻 Code Mode
**When to use:** Writing, modifying, or refactoring code

**Perfect for:**
- Implementing features
- Creating new files
- Modifying existing code
- Fixing bugs
- Refactoring code
- Adding tests

**Example prompts:**
```text
Create a user authentication module in Python
```
```text
Add error handling to the payment processing function
```
```text
Refactor this code to use async/await
```

#### ❓ Ask Mode
**When to use:** Learning, understanding, getting explanations

**Perfect for:**
- Understanding code concepts
- Getting documentation
- Explaining errors
- Learning best practices
- Comparing technologies
- Clarifying requirements

**Example prompts:**
```text
Explain how JWT authentication works
```
```text
What's the difference between REST and GraphQL?
```
```text
Why is this code throwing a NullPointerException?
```

### Switching Between Modes

**To switch modes:**
1. Look for the mode selector at the bottom left of the chat panel
2. Click to see available modes
3. Select the mode you need
4. Bob adapts its behavior immediately

### Mode Practice Exercise

Let's practice switching modes and seeing how Bob's responses differ:

**Step 1: Plan Mode**
Switch to Plan mode and ask:
```text
Help me plan a task management application. What features should I include and how should I structure it?
```

**What to observe:**
- Bob asks clarifying questions about your requirements
- Bob provides architectural guidance
- Bob suggests features and structure without writing code

**Step 2: Ask Mode**
Switch to Ask mode and ask:
```text
What are the key differences between SQL and NoSQL databases, and when should I use each?
```

**What to observe:**
- Bob provides educational explanations
- Bob compares and contrasts concepts
- Bob helps you understand, not just implement

**Step 3: Code Mode**
Switch to Code mode and ask:
```text
Create a simple Python function that validates email addresses using regex
```

**What to observe:**
- Bob writes actual code
- Bob creates files or modifies existing ones
- Bob focuses on implementation

> 📌 **Learn More:** [Bob Modes Documentation](https://bob.ibm.com/docs/ide/features/modes)

---

## Approvals and Safe Collaboration

Approvals are Bob's safety mechanism—you stay in control of all changes to your codebase.

### How Approvals Work

When Bob wants to make changes, it:
1. Shows you exactly what it plans to do
2. Displays a preview of the changes
3. Waits for your approval before proceeding
4. Only makes changes after you confirm

### Best Practices for Approvals

**Before approving, always:**
1. ✅ Read the preview carefully
2. ✅ Check which file will be modified
3. ✅ Verify the changes match your request
4. ✅ Look for unintended side effects

**Red flags to watch for:**
- Changes to files you didn't mention
- Deletions of important code
- Modifications that seem too broad
- Anything that doesn't match your intent

### Set Up the Workshop Sandbox

> 📁 **Sandbox convention:** Throughout Labs 1 and 2, every scratch file you create with Bob will live under `labs/intro-labs/sandbox/` so the workshop repo stays tidy. You'll delete this directory as the final step of Lab 2.

Before practicing approvals, ask Bob to create the sandbox directory. **In Code mode:**

```text
Create an empty directory at labs/intro-labs/sandbox/
```

Approve the action when Bob prompts. All subsequent file-creation exercises in this lab (and the BobShell exercises in Lab 2) will write into this directory.

### Approval Exercise

Now let's practice the approval workflow with an actual file:

**Step 1: Simple File Creation**
In Code mode, ask Bob:
```text
Create a file at labs/intro-labs/sandbox/hello.txt with the text "Hello from Bob"
```

**Watch for:**
- Which tool Bob uses (`write_to_file`)
- When the approval prompt appears
- What the preview shows
- The file path and content

**Step 2: Review and Approve**
- Read the preview
- Verify the filename is correct
- Check the content matches your request
- Click "Approve" or "Reject"

### Understanding Auto-Approvals

**Auto-approvals** allow Bob to make multiple changes without asking each time. This is useful for:
- Creating multiple related files
- Making consistent changes across files
- Batch operations

**⚠️ Important Safety Notes:**
- Only enable auto-approvals when you trust the operation
- Review all changes after Bob completes them
- You can always undo changes using version control
- Start with manual approvals until you're comfortable

**To enable auto-approvals:**
1. Look for auto-approval settings in Bob's interface
2. Enable for the current session
3. Bob will make changes more rapidly
4. Review the results when complete

> 📌 **Learn More:** [Auto-Approving Actions](https://bob.ibm.com/docs/ide/features/auto-approving-actions)

---

## Hands-On Practice

Now let's put everything together with practical exercises. These work with any programming language or framework.

### Exercise 1: Planning a Feature

**Switch to Plan Mode** and try this:

```text
I want to add a user profile feature to my application. Help me plan:
1. What data should I store?
2. What API endpoints do I need?
3. How should I structure the code?
```

**Bob's Interactive Approach:**
- Bob will ask clarifying questions about your requirements
- Bob helps you think through the design
- Bob provides suggestions while letting you drive decisions

**Respond with your preferences:**
- Answer Bob's questions based on your needs
- Ask follow-up questions if anything is unclear
- Iterate until you have a clear plan

### Exercise 2: Creating Files

**Switch to Code Mode** for these quick exercises:

**Step 1: Create a configuration file**
```text
Create labs/intro-labs/sandbox/config.json with basic application settings:
- app name
- version
- environment (development)
Keep it simple.
```

**Step 2: Create a utility function**
```text
Create a utils file inside labs/intro-labs/sandbox/ (in [your preferred language]) with a function that formats dates.
Keep it minimal and well-commented.
```

**Step 3: Connect related files**
```text
Create a main file inside labs/intro-labs/sandbox/ that imports and uses the utility function from the utils file in the same directory.
```

### Exercise 3: Understanding Code

**Switch to Ask Mode** and try:

```text
Explain what each file in labs/intro-labs/sandbox/ does in simple terms:
- config.json
- utils file
- main file
```

### Exercise 4: Making Improvements

**Back to Code Mode:**

```text
Add error handling to the date formatting function in labs/intro-labs/sandbox/utils.
Include a comment explaining why error handling is important here.
```

**What You've Practiced:**
- ✅ Planning before implementing
- ✅ Creating files with Bob
- ✅ Understanding your code
- ✅ Making improvements iteratively

---

## Key Takeaways

### Bob's Modes
- **Plan Mode**: Design and strategize before coding
- **Code Mode**: Implement features and make changes
- **Ask Mode**: Learn and understand concepts
- **Custom Modes**: Create specialized modes for your workflows ([Learn more](../bob-differentiators.md#customizable-modes))

### Working with Bob
- Bob shows what it will do before taking action
- You stay in control through approvals
- Switch modes based on your current task
- Ask clarifying questions when needed
- Iterate and refine your requests

### Best Practices
- Plan before implementing (use Plan mode first)
- Review all changes before approving
- Start with specific, focused requests
- Use the right mode for each task
- Ask Bob to explain when you're unsure

---

## Troubleshooting Tips

### Bob is doing too much

**Solution:** Be more specific and narrow in your requests

```text
❌ "Build a complete application"
✅ "Create just the user model file for now"
```

### The generated code is too complex

**Solution:** Ask Bob to simplify

```text
Please simplify this to beginner-friendly code with minimal features
```

### I'm not sure which mode to use

**Quick reference:**
- Planning/designing → **Plan mode**
- Creating/editing code → **Code mode**
- Learning/understanding → **Ask mode**
- Complex workflows → **Advanced mode**

### I don't understand the code

**Solution:** Switch to Ask mode and request an explanation

```text
Explain this code line by line in plain English
```

### Bob isn't giving me what I want

**Solution:** Provide more context and be specific

```text
❌ "Fix this"
✅ "Fix the null pointer exception on line 45 in UserService.java by adding a null check"
```

---

## What You've Learned

✅ How to navigate Bob's interface  
✅ How to switch between modes effectively  
✅ How approvals keep you in control  
✅ How to plan before implementing  
✅ How to create and modify files safely  
✅ How to use Bob for learning and understanding  

---

## Next Steps

Now that you understand Bob's fundamentals, you're ready to:
- Apply Bob to your actual projects
- Explore advanced features in Lab 2
- Create custom modes for your workflows
- Integrate Bob into your development process

---

## Additional Resources

- [Bob Documentation](https://bob.ibm.com/docs/ide)
- [Bob Modes Guide](https://bob.ibm.com/docs/ide/features/modes)
- [Chat Interface Features](https://bob.ibm.com/docs/ide/features/chat-interface)
- [Auto-Approval Settings](https://bob.ibm.com/docs/ide/features/auto-approving-actions)

---

**Lab 1 Complete! 🎉**

You've mastered Bob's fundamentals through practical, hands-on exercises. You're now ready to apply these skills to any development project and explore Bob's advanced capabilities.