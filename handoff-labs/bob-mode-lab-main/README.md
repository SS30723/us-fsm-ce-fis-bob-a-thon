# Bob Mode Builder Lab

Welcome to the Bob Mode Builder Lab! This comprehensive learning resource teaches you how to create custom Bob modes to enhance your development workflow.

---

## 🎯 What You'll Learn

- Understand Bob modes and why they're a key differentiator
- Create custom modes tailored to your workflows
- Build modes with and without workflows
- Implement todo tracking and mandatory steps
- Encapsulate domain-specific knowledge
- Share modes across projects and teams

---

## 📚 Lab Contents

### Main Lab Guide
**[Bob Mode Builder Lab](bob-mode-builder-lab.md)** - Start here!
- **Duration:** ~30 minutes
- **Level:** Beginner to Intermediate
- Complete walkthrough of mode creation
- 2 detailed examples (simple + workflow)
- Troubleshooting guide

### Advanced Topics
**[Advanced Topics Guide](bob-mode-advanced.md)** - Optional deep dive
- Domain knowledge encapsulation
- Complex workflow patterns
- MCP server integration
- Mode marketplace publishing

### Templates
Ready-to-use templates for quick mode creation:
- **[mode-template.md](templates/mode-template.md)** - Basic mode template
- **[workflow-mode-template.md](templates/workflow-mode-template.md)** - Workflow mode template

### Example Modes
5 complete, working examples you can use or customize:

**Simple Modes (No Workflow):**
1. **[Code Reviewer Mode](examples/code-reviewer-mode.md)** - Quality checks, security review, best practices
2. **[API Documentation Writer Mode](examples/api-doc-writer-mode.md)** - Consistent API docs, OpenAPI specs
3. **[Security Auditor Mode](examples/security-auditor-mode.md)** - Vulnerability scanning, compliance checks

**Workflow Modes (5-7 Steps):**
4. **[Feature Development Workflow Mode](examples/feature-dev-workflow-mode.md)** - Requirements → Design → Implementation → Testing → Documentation → Review → Deployment
5. **[Bug Fix Workflow Mode](examples/bug-fix-workflow-mode.md)** - Reproduce → Root Cause → Fix → Test → Regression Check → Documentation → Deploy

---

## 🚀 Quick Start

### Option 1: Complete the Lab (Recommended)
1. Read [bob-mode-builder-lab.md](bob-mode-builder-lab.md)
2. Follow the step-by-step guide
3. Create your first mode
4. Explore the examples

### Option 2: Use an Example Mode
1. Browse the [examples/](examples/) directory
2. Copy a mode that fits your needs
3. Customize it for your workflow
4. Convert to YAML and add to `.bob/custom_modes.yaml` (project) or `~/.bob/custom_modes.yaml` (global)

### Option 3: Start from Template
1. Choose a template from [templates/](templates/)
2. Fill in the sections
3. Test your mode
4. Iterate and refine

---

## 📂 Project Structure

```
bob-mode-lab/
├── README.md                           # This file
├── bob-mode-builder-lab.md            # Main 30-minute lab guide
├── bob-mode-advanced.md               # Advanced topics (optional)
│
├── templates/                          # Reusable templates
│   ├── mode-template.md               # Basic mode template
│   └── workflow-mode-template.md      # Workflow mode template
│
├── examples/                           # 5 complete example modes
│   ├── code-reviewer-mode.md          # Simple mode example
│   ├── api-doc-writer-mode.md         # Simple mode example
│   ├── security-auditor-mode.md       # Simple mode example
│   ├── feature-dev-workflow-mode.md   # Workflow mode example
│   └── bug-fix-workflow-mode.md       # Workflow mode example
│
└── resources/                          # Background information
    ├── modes-vs-skills.md             # Modes vs Skills guide
    ├── bob-differentiators.md         # Why Bob modes matter
    ├── bob-installation.md            # Installation guide
    └── bob-productivity-gains-client-zero.md  # Real-world impact
```

---

## 🎓 Learning Path

### Beginner (30 minutes)
1. ✅ Read the [main lab guide](bob-mode-builder-lab.md)
2. ✅ Understand global vs project modes
3. ✅ Review the Code Reviewer example
4. ✅ Review the Feature Development Workflow example
5. ✅ Create your first simple mode

### Intermediate (1-2 hours)
1. ✅ Create a workflow mode for your team
2. ✅ Customize an example mode
3. ✅ Add mandatory steps and user options
4. ✅ Share a mode with your team

### Advanced (2+ hours)
1. ✅ Read the [advanced topics guide](bob-mode-advanced.md)
2. ✅ Encapsulate domain-specific knowledge
3. ✅ Create complex conditional workflows
4. ✅ Integrate with MCP servers
5. ✅ Publish to the mode marketplace

---

## 💡 Why Bob Modes Matter

From [Bob Differentiators](resources/bob-differentiators.md):

> **Customizable Modes** are one of Bob's four key differentiators that set it apart from other AI coding assistants. They let you:
> - ✅ Tailor AI behavior to specific tasks
> - ✅ Share custom modes through the marketplace
> - ✅ Adapt Bob to your team's unique workflows
> - ✅ Ensure consistent behavior across team members
> - ✅ Encapsulate domain-specific knowledge and best practices

**Real-World Impact:**
- 60-80% acceleration in development cycles
- Consistent code quality across teams
- Faster onboarding for new developers
- Reduced context switching

See [productivity gains](resources/bob-productivity-gains-client-zero.md) for detailed metrics.

---

## 🛠️ Using the Examples

### To Use an Example Mode:

1. **Copy the mode file:**
   ```bash
   # For project-specific mode
   # Create .bob directory if it doesn't exist
   mkdir -p .bob
   # Copy example mode definition to your custom_modes.yaml
   # (You'll need to convert the markdown example to YAML format)
   
   # For global mode (all projects)
   # Create global .bob directory if it doesn't exist
   mkdir -p ~/.bob
   # Add mode definition to your global custom_modes.yaml
   # (You'll need to convert the markdown example to YAML format)
   ```

2. **Restart Bob or refresh modes**

3. **Select the mode** from Bob's mode selector

4. **Test it** with a sample task

5. **Customize** as needed for your workflow

---

## 🤝 Contributing

Have a great mode to share? We'd love to see it!

1. Create your mode following the lab guidelines
2. Test it thoroughly
3. Document it clearly
4. Submit to the mode marketplace or share with the community

---

## 📖 Additional Resources

- **[Modes vs Skills](resources/modes-vs-skills.md)** - Understanding the difference between modes and skills
- **[Bob Differentiators](resources/bob-differentiators.md)** - What makes Bob unique
- **[Bob Installation](resources/bob-installation.md)** - Getting started with Bob
- **[Productivity Gains](resources/bob-productivity-gains-client-zero.md)** - Real-world impact data

---

## 🐛 Troubleshooting

**Mode not appearing?**
- Check file location (`.bob/custom_modes.yaml` or `~/.bob/custom_modes.yaml`)
- Verify YAML syntax is valid
- Ensure mode slug is unique
- Restart Bob

**Workflow not working?**
- Use proper checklist format: `- [ ] Task`
- Place under `## Workflow` heading
- Reference workflow in instructions

**Need help?**
- Check the [troubleshooting section](bob-mode-builder-lab.md#-troubleshooting) in the main lab
- Ask Bob in Ask mode
- Review the example modes

---

## 📝 License

This lab and all examples are provided as educational resources. Feel free to use, modify, and share them with your team.

---

## 🎉 Get Started!

Ready to build your first Bob mode? Start with the **[Bob Mode Builder Lab](bob-mode-builder-lab.md)** now!

**Questions?** Ask Bob in Ask mode or check the documentation.

---

*Happy mode building!* 🚀