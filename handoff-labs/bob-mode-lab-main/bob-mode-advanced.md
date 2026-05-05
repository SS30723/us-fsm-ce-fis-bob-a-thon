# Bob Mode Builder - Advanced Topics

**Level:** Advanced  
**Prerequisites:** Complete the [Bob Mode Builder Lab](bob-mode-builder-lab.md)

---

## 📚 Overview

This guide covers advanced mode creation techniques, complex workflow patterns, MCP server integration, and mode marketplace publishing.

---

## 📝 YAML vs XML: Advanced Format Considerations

### Format Overview

Bob supports two formats for defining modes. **Mode Writer mode uses a hybrid approach by default**: YAML for mode definitions, XML for rules and workflows.

#### **Mode Writer's Hybrid Approach**

**Default Behavior:**
- **Mode definition** → YAML in `.bob/custom_modes.yaml`
- **Rules and workflow** → XML in `.bob/rules-[mode-slug]/` directory

This combines:
- Simple YAML for metadata and basic configuration
- Structured XML for complex rules and workflows

#### **YAML Format - For Mode Definitions**

**When to Use:**
- Mode metadata (slug, name, description, basic instructions)
- Simple modes without complex workflows
- All-in-one configuration (if you prefer simplicity)
- Modes you plan to share or publish to marketplace

**Strengths:**
- Single-file simplicity
- Easy version control
- Portable across projects
- Standard marketplace format
- Lower learning curve

**Limitations:**
- Can become unwieldy for very complex workflows (10+ steps)
- Limited hierarchical structure
- Harder to maintain when rules exceed 100 lines

**Example - All-in-One YAML:**
```yaml
modes:
  - slug: simple-reviewer
    name: Simple Code Reviewer
    instructions: |
      Review code for quality and security.
    rules:
      - Check for security issues
      - Verify test coverage
    workflow:
      - step: Review code
        todos:
          - Check security
          - Check tests
```

#### **XML Format - For Rules and Workflows**

**When to Use:**
- Complex workflows (5+ steps)
- Detailed rule sets (50+ lines)
- Structured, hierarchical organization
- Enterprise governance requirements
- Modes requiring conditional logic

**Strengths:**
- Structured hierarchy with nested elements
- Split across multiple files (1_workflow.xml, 2_rules.xml, etc.)
- Better organization for complex content
- Supports advanced patterns (conditions, gates, approvals)
- Clear separation of concerns

**Limitations:**
- More verbose syntax
- Requires understanding XML structure
- Not standard for marketplace (use YAML wrapper)

**Example XML Structure:**
```
.bob/
  custom_modes.yaml              # Mode definition (YAML)
  rules-enterprise-mode/         # Rules and workflow (XML)
    1_workflow.xml               # Workflow definition
    2_rules.xml                  # Core rules
    3_templates.xml              # Code templates
    4_validations.xml            # Validation rules
```

See [examples/.bob/rules-feature-dev-workflow/](../examples/.bob/rules-feature-dev-workflow/) and [examples/.bob/rules-bug-fix-workflow/](../examples/.bob/rules-bug-fix-workflow/) for complete XML examples.

### The Hybrid Approach (Recommended)

**Mode Writer's default** - combines best of both formats:

```yaml
# .bob/custom_modes.yaml
modes:
  - slug: enterprise-mode
    name: Enterprise Mode
    description: Complex enterprise workflow
    instructions: |
      Follow the structured enterprise workflow with quality gates.
    # Bob automatically discovers XML files in .bob/rules-enterprise-mode/
    # based on the mode slug (no explicit link needed)
```

Then maintain detailed rules and workflows in `.bob/rules-enterprise-mode/*.xml`:
- `1_workflow.xml` - Step-by-step workflow
- `2_rules.xml` - Core rules and guidelines
- `3_quality_standards.xml` - Quality gates and checks

**Convention-Based Discovery:** Bob automatically finds XML files using the pattern `.bob/rules-[mode-slug]/`. The mode's `slug` field determines the directory name. No explicit path configuration is needed in the YAML definition.

### Format Decision Matrix

| Mode Complexity | Recommended Approach | Rationale |
|----------------|---------------------|-----------|
| Simple (no workflow, < 20 lines) | YAML only | Simplicity wins |
| Basic workflow (< 5 steps, < 50 lines) | YAML only | Still manageable |
| Moderate (5-10 steps, 50-100 lines) | Hybrid (YAML + XML) | Better organization |
| Complex (10-15 steps, 100-200 lines) | Hybrid (YAML + XML) | Required structure |
| Enterprise (15+ steps, 200+ lines) | Hybrid (YAML + XML) | Essential for maintenance |

### When to Override Mode Writer's Default

**Use YAML only when:**
- Creating very simple modes for learning
- Sharing modes via marketplace (easier distribution)
- Prototyping and quick iteration
- Mode has < 5 workflow steps and < 50 lines total

**Stick with Hybrid (Mode Writer default) when:**
- Workflow has 5+ steps
- Rules exceed 50 lines
- Need structured organization
- Multiple team members will maintain the mode
- Enterprise governance required

### Migration Strategy

If you start with all-in-one YAML and need to migrate to hybrid:

1. **Keep YAML mode definition** with basic metadata
2. **Extract rules to XML** - Create `2_rules.xml` in `.bob/rules-[mode-slug]/`
3. **Extract workflow to XML** - Create `1_workflow.xml` in same directory
4. **Update YAML instructions** to reference XML files
5. **Test thoroughly** after migration
6. **Document the structure** for maintainers

**Example Migration:**

Before (YAML only):
```yaml
modes:
  - slug: my-mode
    name: My Mode
    instructions: |
      Complex instructions here...
    rules:
      - 50+ lines of rules...
    workflow:
      - 10+ workflow steps...
```

After (Hybrid):
```yaml
modes:
  - slug: my-mode
    name: My Mode
    instructions: |
      Follow the workflow in .bob/rules-my-mode/
```

Plus XML files in `.bob/rules-my-mode/`.


---

## 🧠 Encapsulating Domain-Specific Knowledge

### What is Domain Knowledge Encapsulation?

Domain knowledge encapsulation means embedding specialized expertise directly into a mode, making Bob an expert in specific domains without requiring the user to have that expertise.

### Examples of Domain Knowledge

**1. Industry-Specific Regulations**
```yaml
modes:
  - slug: hipaa-compliance-reviewer
    name: HIPAA Compliance Reviewer
    description: Healthcare software development with HIPAA compliance expertise
    instructions: |
      You are a healthcare software development expert with deep knowledge of HIPAA compliance.
      
      When reviewing or writing code, you must ensure:
      - PHI (Protected Health Information) is encrypted at rest and in transit
      - Access logs are maintained for all PHI access
      - Minimum necessary principle is followed
      - Business Associate Agreements are considered
      - Breach notification procedures are documented
    rules:
      - Flag any PHI storage without encryption
      - Require audit logging for all PHI access
      - Verify access controls follow least privilege
      - Check for proper consent management
      - Ensure data retention policies are implemented
```

**2. Technology-Specific Best Practices**
```yaml
modes:
  - slug: react-performance-optimizer
    name: React Performance Optimizer
    description: React performance optimization expert
    instructions: |
      You are a React performance optimization expert.
      
      Focus on:
      - Component re-render optimization (useMemo, useCallback, React.memo)
      - Code splitting and lazy loading strategies
      - Virtual scrolling for large lists
      - Image optimization and lazy loading
      - Bundle size reduction techniques
    rules:
      - Identify unnecessary re-renders
      - Suggest memoization opportunities
      - Recommend code splitting points
      - Check for proper key usage in lists
      - Verify proper cleanup in useEffect
```

**3. Company-Specific Standards**
```yaml
modes:
  - slug: acme-corp-standards
    name: Acme Corp Standards Enforcer
    description: Expert in Acme Corp's coding standards and architecture patterns
    instructions: |
      You are an expert in Acme Corp's coding standards and architecture patterns.
      
      Our standards require:
      - All API endpoints follow RESTful conventions
      - Error responses use standard error codes (ACME-XXX format)
      - Logging uses our centralized logging service
      - Authentication via our OAuth2 provider
      - Database migrations use our migration framework
      
      Company Patterns:
      - Repository pattern for data access
      - Service layer for business logic
      - DTO pattern for API contracts
      - Factory pattern for object creation
    rules:
      - Enforce RESTful API conventions
      - Validate error code format (ACME-XXX)
      - Check logging integration
      - Verify OAuth2 authentication
      - Validate migration framework usage
```

### Best Practices for Knowledge Encapsulation

1. **Be Specific**: Include exact rules, not general guidelines
2. **Provide Examples**: Show what good and bad look like
3. **Reference Standards**: Link to internal docs or external standards
4. **Keep Updated**: Review and update as standards evolve
5. **Test Thoroughly**: Verify the mode catches violations

---

## 🔄 Complex Workflow Patterns

### Conditional Workflows

Workflows that branch based on user choices or conditions:

```markdown
## Workflow

### Step 1: Assess Change Type
- [ ] Determine if this is a breaking change
- [ ] Identify affected components

**Decision Point:** Is this a breaking change?
- If YES → Go to Step 2A (Breaking Change Path)
- If NO → Go to Step 2B (Non-Breaking Change Path)

### Step 2A: Breaking Change Path
- [ ] Create migration guide
- [ ] Update major version
- [ ] Notify all stakeholders
- [ ] Plan deprecation timeline

### Step 2B: Non-Breaking Change Path
- [ ] Update minor/patch version
- [ ] Add to changelog
- [ ] Deploy normally

### Step 3: Common Final Steps
(Both paths converge here)
- [ ] Update documentation
- [ ] Deploy changes
```

### Parallel Workflows

Multiple tasks that can be done simultaneously:

```markdown
## Workflow

### Step 1: Planning
- [ ] Define requirements

### Step 2: Parallel Development (Can be done simultaneously)

**Track A: Frontend**
- [ ] Design UI components
- [ ] Implement frontend logic
- [ ] Write frontend tests

**Track B: Backend**
- [ ] Design API endpoints
- [ ] Implement backend logic
- [ ] Write backend tests

**Track C: Infrastructure**
- [ ] Set up deployment pipeline
- [ ] Configure monitoring
- [ ] Prepare database migrations

### Step 3: Integration (After all tracks complete)
- [ ] Integrate frontend and backend
- [ ] End-to-end testing
- [ ] Deploy
```

### Iterative Workflows

Workflows that repeat until a condition is met:

```yaml
modes:
  - slug: iterative-review-workflow
    name: Iterative Review Workflow
    description: Repeat review cycles until approval
    instructions: |
      Guide through iterative review process with repeated cycles until approval.
    workflow:
      - step: Initial Implementation
        mandatory: false
        todos:
          - Implement feature
          - Write tests
      - step: Review Cycle
        repeatable: true
        repeat_until: all_reviewers_approve
        mandatory: false
        todos:
          - Submit for review
          - Receive feedback
          - Address feedback
          - Update tests
      - step: Finalization
        mandatory: false
        todos:
          - Merge to main
          - Deploy
```

---

## 🔌 Combining Modes with MCP Servers

### What are MCP Servers?

MCP (Model Context Protocol) Servers allow Bob to connect to external tools, APIs, and data sources. Combining custom modes with MCP servers creates powerful, context-aware workflows.

### Use Cases

**1. Internal Knowledge Base Integration**
```yaml
modes:
  - slug: doc-writer-with-kb
    name: Documentation Writer with Knowledge Base
    description: Documentation writer with access to internal knowledge base via MCP
    instructions: |
      You are a documentation writer with access to our internal knowledge base via MCP.
      
      Before writing documentation:
      1. Search the knowledge base for existing related docs
      2. Check for company terminology standards
      3. Verify technical accuracy against internal specs
      4. Follow our documentation templates
    mcp_tools:
      - knowledge_base_search
      - terminology_lookup
      - template_fetch
    rules:
      - Always search knowledge base before creating new docs
      - Verify terminology against company standards
      - Use approved templates
```

**2. Issue Tracker Integration**
```yaml
modes:
  - slug: bug-fix-with-jira
    name: Bug Fix Mode with Jira Integration
    description: Bug fixing with automatic Jira integration
    instructions: |
      When fixing bugs, automatically interact with Jira to track progress.
    mcp_tools:
      - jira_fetch_issue
      - jira_update_status
      - jira_add_comment
      - jira_link_pr
    workflow:
      - step: Fetch Bug Details
        mandatory: false
        todos:
          - Use MCP to fetch full bug details from Jira
          - Get related issues and history
          - Check for duplicate reports
      - step: Update Status
        mandatory: false
        todos:
          - Automatically update Jira status to "In Progress"
          - Add comments with progress updates
      - step: Close Bug
        mandatory: false
        todos:
          - Update Jira status to "Resolved"
          - Link PR to Jira ticket
          - Add resolution notes
```

**3. Deployment System Integration**
```yaml
modes:
  - slug: deployment-with-cicd
    name: Deployment Mode with CI/CD Integration
    description: Guide deployments with real-time CI/CD status
    instructions: |
      Guide deployments with real-time CI/CD status monitoring and control.
    mcp_tools:
      - cicd_check_status
      - cicd_trigger_deployment
      - cicd_monitor_progress
      - health_check_environment
    workflow:
      - step: Pre-Deployment Checks
        mandatory: true
        todos:
          - Use MCP to check CI/CD pipeline status
          - Verify all tests passed
          - Check deployment environment health
      - step: Deploy
        mandatory: false
        todos:
          - Trigger deployment via MCP
          - Monitor deployment progress
          - Watch for errors in real-time
      - step: Post-Deployment
        mandatory: true
        todos:
          - Verify deployment success via MCP
          - Check application health metrics
          - Update deployment log
```

### Setting Up MCP Integration

1. **Configure MCP Server**: Set up the MCP server with required tools
2. **Reference in Mode**: Document which MCP tools the mode uses
3. **Handle Errors**: Include error handling for MCP failures
4. **Test Integration**: Verify MCP calls work as expected

---

## 🏪 Mode Marketplace and Sharing

### Publishing to the Marketplace

**Preparation Checklist:**
- [ ] Mode is thoroughly tested
- [ ] Documentation is complete and clear
- [ ] Examples are provided
- [ ] Version number is set
- [ ] License is specified
- [ ] Author information is included

**Metadata for Marketplace:**
```yaml
modes:
  - slug: your-mode-slug
    name: Your Mode Name
    version: 1.0.0
    author: Your Name
    license: MIT
    category: Development
    tags:
      - code-review
      - security
      - best-practices
    description: |
      A comprehensive description of what this mode does and who should use it.
    requirements:
      bob_version: "2.0+"
      mcp_servers:
        - name: optional-mcp-server
          required: false
      access:
        - Optional access requirement
    installation: |
      1. Copy this mode definition to your custom_modes.yaml
      2. Add to .bob/custom_modes.yaml (project) or ~/.bob/custom_modes.yaml (global)
      3. Restart Bob or refresh modes
    instructions: |
      Your mode instructions here...
```

### Versioning Your Modes

Follow semantic versioning (SEMVER):
- **Major (1.0.0)**: Breaking changes to mode behavior
- **Minor (0.1.0)**: New features, backward compatible
- **Patch (0.0.1)**: Bug fixes, minor improvements

### Sharing Within Your Organization

**For Team Sharing:**
1. Create a shared repository for modes
2. Document each mode thoroughly
3. Establish a review process for new modes
4. Maintain a mode catalog/index

**Example Team Mode Repository Structure:**
```
company-bob-modes/
├── README.md (catalog of all modes)
├── .bob/
│   └── custom_modes.yaml (all team modes in one file)
├── development/
│   └── README.md (documentation for dev modes)
├── security/
│   └── README.md (documentation for security modes)
├── documentation/
│   └── README.md (documentation for doc modes)
└── templates/
    ├── mode-template.yaml
    └── workflow-template.yaml
```

**Note:** All modes are stored in `.bob/custom_modes.yaml`. The subdirectories contain documentation and examples, not the actual mode files.

---

## 🎯 Advanced Mode Techniques

### Dynamic Mode Behavior

Modes that adapt based on context:

```yaml
modes:
  - slug: adaptive-code-reviewer
    name: Adaptive Code Reviewer
    description: Adapts review criteria based on project type
    instructions: |
      Adapt your behavior based on the project type:
      
      **If Python project:**
      - Focus on PEP 8 compliance
      - Check for type hints
      - Verify virtual environment usage
      
      **If JavaScript project:**
      - Check for ESLint configuration
      - Verify package.json scripts
      - Review dependency versions
      
      **If Java project:**
      - Check for Maven/Gradle configuration
      - Verify proper exception handling
      - Review logging framework usage
    rules:
      - Detect project type from file extensions and config files
      - Apply language-specific best practices
      - Suggest appropriate tools for the language
```

### Multi-Stage Workflows

Complex workflows with gates and approvals:

```yaml
modes:
  - slug: multi-stage-deployment
    name: Multi-Stage Deployment Workflow
    description: Complex deployment with multiple gates and approvals
    instructions: |
      Guide through multi-stage deployment with quality gates.
    workflow:
      - step: Development Phase
        mandatory: false
        todos:
          - Write all code
          - Pass all tests
          - Complete code review
      - step: Gate 1 - Development Complete
        mandatory: true
        gate: true
        approval_required: true
        todos:
          - Verify all code written
          - Verify all tests passing
          - Verify code reviewed
      - step: Staging Phase
        mandatory: false
        todos:
          - Deploy to staging
          - Complete QA testing
          - Verify performance
      - step: Gate 2 - Staging Validated
        mandatory: true
        gate: true
        approval_required: true
        todos:
          - Verify staging deployment
          - Verify QA sign-off
          - Verify performance metrics
      - step: Production Phase
        mandatory: false
        todos:
          - Get stakeholder approval
          - Schedule deployment window
          - Prepare rollback plan
      - step: Gate 3 - Production Ready
        mandatory: true
        gate: true
        approval_required: true
        todos:
          - Verify stakeholder approval
          - Verify deployment window
          - Verify rollback plan ready
```

### Mode Composition

Combining multiple modes:

```yaml
modes:
  - slug: comprehensive-code-review
    name: Comprehensive Code Review
    description: Combines security, quality, and performance reviews
    instructions: |
      This mode combines aspects of:
      - Code Review Mode (for quality checks)
      - Security Audit Mode (for security checks)
      - Performance Analysis Mode (for performance checks)
      
      When reviewing code, apply all three perspectives:
      1. First pass: Security (highest priority)
      2. Second pass: Code quality
      3. Third pass: Performance
      
      Provide a comprehensive report covering all three areas.
    rules:
      - Always start with security review
      - Follow with code quality analysis
      - Complete with performance assessment
      - Provide integrated recommendations
```

---

## 🔧 Troubleshooting Advanced Issues

### Mode Performance Issues

**Problem:** Mode is slow or times out

**Solutions:**
- Break complex workflows into smaller steps
- Reduce the amount of context in instructions
- Use more focused, specific rules
- Consider splitting into multiple modes

### Mode Conflicts

**Problem:** Multiple modes interfere with each other

**Solutions:**
- Use clear, distinct slugs
- Avoid overlapping instructions
- Document which modes work well together
- Create a "mode compatibility matrix"

### MCP Integration Failures

**Problem:** MCP calls fail or timeout

**Solutions:**
- Add error handling in mode instructions
- Provide fallback behavior when MCP unavailable
- Test MCP connectivity before relying on it
- Document MCP requirements clearly

---

## 📖 Additional Resources

### Learning More

- **Bob Documentation**: Official Bob docs for latest features
- **MCP Protocol Spec**: Understanding MCP capabilities
- **Mode Examples Repository**: Community-contributed modes
- **Bob Community Forum**: Ask questions and share modes

### Contributing

- Submit your modes to the marketplace
- Contribute to mode templates
- Share best practices with the community
- Help improve mode documentation

---

## 🎓 Next Steps

Now that you've mastered advanced mode creation:

1. **Create a Complex Mode**: Build a mode with conditional workflows
2. **Integrate with MCP**: Connect a mode to your internal tools
3. **Publish a Mode**: Share your creation with the community
4. **Mentor Others**: Help teammates create their own modes

---

**Questions?** Refer back to the [main lab guide](bob-mode-builder-lab.md) or ask Bob in Ask mode!