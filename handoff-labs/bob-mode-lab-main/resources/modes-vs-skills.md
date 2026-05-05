# Modes vs Skills vs Rules in Bob

## Overview
Bob's functionality is organized into three distinct concepts: **Modes**, **Skills**, and **Rules**. Understanding the differences and how they interact is crucial for effective customization.

## Modes

### Definition
Modes are complete behavioral contexts that define how Bob operates. When you switch modes, you're changing Bob's entire approach, personality, and available capabilities.

### Characteristics
- **Exclusive**: Only one mode active at a time
- **Comprehensive**: Defines complete behavior, tools, and constraints
- **Context-switching**: Switching modes changes Bob's entire operational context
- **Persistent**: Remains active until explicitly changed
- **Workflow Capabilities**: Support advanced features like:
  - Iterative workflows (repeat until condition met)
  - Conditional branching (if/then/else logic)
  - Todo list management (track multi-step progress)
  - User prompting (request input at decision points)

### Examples
- **💻 Code Mode**: Full development capabilities with all tools
- **💬 Chat Mode**: Conversational, no file system access
- **🚀 Advanced Mode**: Extended capabilities with MCP servers
- **Custom Modes**: User-defined specialized behaviors

### Use Cases
- Different project phases (planning vs implementation)
- Different security contexts (restricted vs full access)
- Different interaction styles (conversational vs technical)
- Workflow-specific behaviors (feature dev vs bug fixing)

## Skills

### Definition
Skills are modular capabilities that can be added to modes. They extend or modify a mode's behavior without replacing it entirely.

### Characteristics
- **Additive**: Multiple skills can be active simultaneously
- **Modular**: Can be mixed and matched
- **Mode-compatible**: Work within the current mode's constraints
- **Stackable**: Skills combine to create complex behaviors

### Examples
- Code review guidelines
- Documentation standards
- Testing requirements
- Security audit procedures
- API design patterns
- Find more at [agentskills.io](https://agentskills.io)

### Use Cases
- Adding specialized knowledge to existing modes
- Enforcing project-specific standards
- Implementing team conventions
- Temporary capability enhancements
- Discovering and applying community-contributed capabilities

## Rules

### Definition
Rules are structured constraints and guidelines that govern Bob's behavior within a mode. They define priorities, enforcement levels, and specific requirements that Bob must follow during task execution.

### Characteristics
- **Hierarchical**: Rules have priority levels (critical, high, medium, low)
- **Enforceable**: Can mandate specific behaviors or checkpoints
- **Contextual**: Can be global, mode-specific, or workflow-specific
- **Structured**: Defined in XML format for precise control
- **Layered**: Multiple rule sets can apply simultaneously with clear precedence

### Priority Levels
Rules are organized by priority, which determines their enforcement order:

1. **Critical Priority**: Non-negotiable requirements that Bob must enforce
   - Example: "Never skip reproduction" in bug fix workflows
   - Example: "Always add regression tests" for bug fixes
   - Enforcement: Bob will block progress until requirement is met

2. **High Priority**: Important guidelines that strongly influence behavior
   - Example: "Update todo list after each step"
   - Example: "Ask for approval at mandatory checkpoints"
   - Enforcement: Bob will actively remind and encourage compliance

3. **Medium Priority**: Standard practices that should be followed
   - Example: "Document decisions throughout the process"
   - Example: "Keep user informed of progress and blockers"
   - Enforcement: Bob will incorporate into normal workflow

4. **Low Priority**: Suggestions and best practices
   - Example: Optional optimizations or enhancements
   - Enforcement: Bob will consider when appropriate

### Rule Types

#### Core Rules
Global rules that apply across all steps of a workflow:
```xml
<core_rules>
  <rule priority="critical">
    <name>Never skip mandatory steps</name>
    <description>Design approval and testing are required checkpoints</description>
    <enforcement>Bob will ask for explicit approval before proceeding</enforcement>
  </rule>
</core_rules>
```

#### Step-Specific Rules
Rules that apply only to particular workflow steps:
```xml
<step_rules step="2" name="Design Solution">
  <rule>Create visual diagrams for complex architectures</rule>
  <rule>MANDATORY: Obtain explicit approval before implementation</rule>
</step_rules>
```

#### Quality Standards
Measurable requirements for code quality, testing, and documentation:
```xml
<quality_standards>
  <standard category="testing">
    <requirement>Minimum 80% code coverage</requirement>
    <requirement>All critical paths tested</requirement>
  </standard>
</quality_standards>
```

### Rule Precedence Order
When multiple rule sets apply, they are evaluated in this order:

1. **Workflow-Specific Rules** (`.bob/rules-{workflow-name}/2_rules.xml`)
   - Highest precedence
   - Override mode and global rules
   - Apply only when specific workflow is active

2. **Mode-Specific Rules** (`.bob/modes/{mode-name}/rules.xml`)
   - Second precedence
   - Override global rules
   - Apply when mode is active

3. **Global Rules** (`~/.bob/rules/*.md`)
   - Base precedence
   - Apply to all modes and workflows
   - Provide consistent baseline behavior

4. **System Rules** (Built into Bob)
   - Lowest precedence
   - Core Bob functionality
   - Can be overridden by user rules

### Rule Locations

#### Global Rules Directory
```
~/.bob/rules/
├── global_rules.md          # Universal rules for all contexts
├── responses.md             # Response formatting guidelines
└── skills-mode-suggestion.md # Skills discovery behavior
```

#### Workflow Rules Directory
```
.bob/rules-{workflow-name}/
├── 1_workflow.xml           # Workflow definition
└── 2_rules.xml              # Workflow-specific rules
```

#### Mode Rules (Embedded)
Rules can be embedded directly in mode definitions using XML sections.

### Examples

#### Critical Rule Example
```xml
<rule priority="critical">
  <name>Always add regression tests</name>
  <description>
    Every bug fix must include an automated test that would have caught the bug.
  </description>
  <enforcement>
    Step 4 (Testing) is mandatory and must include a new regression test.
  </enforcement>
</rule>
```

#### High Priority Rule Example
```xml
<rule priority="high">
  <name>Keep fixes focused</name>
  <description>
    Don't mix bug fixes with refactoring, new features, or unrelated changes.
  </description>
  <rationale>
    Focused fixes are easier to review, test, and rollback if needed.
  </rationale>
</rule>
```

### Use Cases
- Enforcing mandatory checkpoints in workflows
- Defining quality standards for code and tests
- Establishing team conventions and best practices
- Implementing compliance requirements
- Customizing Bob's behavior for specific contexts

## Key Differences

| Aspect | Modes | Skills | Rules |
|--------|-------|--------|-------|
| **Scope** | Complete behavior | Specific capability | Constraints & guidelines |
| **Activation** | One at a time | Multiple simultaneously | Layered by precedence |
| **Impact** | Replaces entire context | Augments current context | Governs behavior |
| **Persistence** | Until switched | Can be toggled | Active when context applies |
| **Tools** | Defines available tools | Uses mode's tools | Enforces tool usage patterns |
| **Switching** | Explicit mode change | Add/remove as needed | Automatic by context |
| **Workflows** | Support iterative/conditional logic | Work within mode's workflow | Define workflow requirements |
| **Discovery** | Project-specific | Browse at agentskills.io | Project/user configuration |
| **Priority** | Exclusive selection | Additive combination | Hierarchical enforcement |

## Practical Examples

### Scenario 1: Code Review
**Mode Approach**: Create a "Code Reviewer" mode with limited tools and review-focused prompts
**Skill Approach**: Add code review guidelines as a skill to Code mode
**Rules Approach**: Define critical review checkpoints and quality standards

**When to use Mode**: Need restricted tool access, different interaction style
**When to use Skill**: Want review guidelines while maintaining full development capabilities
**When to use Rules**: Enforce mandatory review steps and quality gates

### Scenario 2: Security Audit
**Mode Approach**: Dedicated "Security Auditor" mode with security-focused tools and constraints
**Skill Approach**: Add security checklist as a skill to existing mode
**Rules Approach**: Define critical security requirements and compliance checks

**When to use Mode**: Formal audit requiring specific methodology and reporting
**When to use Skill**: Security awareness during normal development
**When to use Rules**: Enforce security standards and mandatory verification steps

### Scenario 3: Documentation
**Mode Approach**: "Documentation Writer" mode optimized for writing and formatting
**Skill Approach**: Add documentation standards as a skill to Code mode
**Rules Approach**: Define documentation requirements and quality standards

**When to use Mode**: Dedicated documentation sprint
**When to use Skill**: Inline documentation during development
**When to use Rules**: Ensure consistent documentation coverage and quality

### Scenario 4: Bug Fix Workflow
**Mode Approach**: Use Code mode with workflow capabilities
**Skill Approach**: Add debugging techniques as a skill
**Rules Approach**: Define mandatory steps (reproduction, testing, regression prevention)

**Combined Approach**:
- Mode provides tools and workflow structure
- Skill adds debugging expertise
- Rules enforce critical checkpoints (must reproduce bug, must add regression test)

## Implementation Guidelines

### Creating a Mode
```markdown
# Mode Definition
- Define complete system prompt
- Specify available tools
- Set behavioral constraints
- Define interaction style
- Establish success criteria
- Configure workflow features:
  - Iterative loops (repeat until done)
  - Conditional branches (if/then/else)
  - Todo list tracking
  - User prompt points
- Optionally embed mode-specific rules
```

### Creating a Skill
```markdown
# Skill Definition
- Define specific capability or knowledge
- Specify when to apply
- List requirements or constraints
- Provide examples
- Keep focused and modular
- Consider publishing to agentskills.io for community use
```

### Creating Rules
```xml
<!-- Rule Definition Structure -->
<rules>
  <core_rules>
    <rule priority="critical|high|medium|low">
      <name>Rule name</name>
      <description>What the rule requires</description>
      <enforcement>How Bob enforces it</enforcement>
      <rationale>Why this rule exists (optional)</rationale>
    </rule>
  </core_rules>
  
  <step_specific_rules>
    <step_rules step="N" name="Step Name">
      <rule>Specific requirement for this step</rule>
    </step_rules>
  </step_specific_rules>
  
  <quality_standards>
    <standard category="category_name">
      <requirement>Measurable quality requirement</requirement>
    </standard>
  </quality_standards>
</rules>
```

### Rule Priority Guidelines
- **Critical**: Use for non-negotiable requirements (safety, security, data integrity)
- **High**: Use for important workflow checkpoints and quality gates
- **Medium**: Use for standard practices and team conventions
- **Low**: Use for suggestions and optional optimizations

## Best Practices

### Use Modes When:
- Need complete behavioral change
- Require different tool access levels
- Want distinct interaction styles
- Implementing complex workflows
- Need isolation between contexts

### Use Skills When:
- Adding specialized knowledge
- Enforcing standards or conventions
- Temporary capability enhancement
- Combining multiple capabilities
- Maintaining current mode's tools

### Use Rules When:
- Enforcing mandatory checkpoints
- Defining quality standards
- Implementing compliance requirements
- Establishing team conventions
- Preventing common mistakes
- Ensuring consistent workflows

### Combining All Three:
- Create base modes for major contexts
- Add skills for specialized knowledge
- Define rules for enforcement and quality
- Stack skills for complex requirements
- Layer rules by precedence (workflow > mode > global)
- Switch modes for phase changes
- Keep skills focused and reusable
- Keep rules clear and measurable

## Migration Path

### From Skills to Modes
When a skill becomes complex enough to warrant its own mode:
1. Skill requires tool restrictions
2. Skill needs different interaction style
3. Skill conflicts with other skills
4. Skill represents complete workflow

### From Modes to Skills
When a mode is too specific:
1. Mode rarely used alone
2. Mode's capabilities needed in other contexts
3. Mode is primarily knowledge-based
4. Mode doesn't require tool changes

## Rule Precedence in Practice

### Example: Feature Development
```
Active Context:
├── Workflow: feature-dev-workflow
│   └── Rules: .bob/rules-feature-dev-workflow/2_rules.xml (HIGHEST)
├── Mode: code
│   └── Rules: .bob/modes/code/rules.xml (if exists)
└── Global: ~/.bob/rules/
    ├── global_rules.md
    ├── responses.md
    └── skills-mode-suggestion.md (LOWEST)
```

**Resolution**: If workflow rule says "Design approval required" (critical) and global rule says "Design approval optional" (medium), the workflow rule takes precedence.

### Example: Conflicting Priorities
```
Workflow Rule (Critical): "Must achieve 80% test coverage"
Mode Rule (High): "Must achieve 70% test coverage"
Global Rule (Medium): "Test coverage recommended"
```

**Resolution**: Workflow rule (80% coverage) is enforced because:
1. Workflow rules have highest precedence
2. Critical priority overrides lower priorities
3. More specific rules override general rules

## Conclusion

**Modes** define *how* Bob operates (the context)
**Skills** define *what* Bob knows (the capabilities)
**Rules** define *what* Bob must enforce (the constraints)

Choose modes for fundamental behavioral changes, skills for additive enhancements, and rules for enforcement and quality standards. The most powerful Bob configurations combine well-designed modes with complementary skills and clear, prioritized rules.