# Workflow Specification

Machine-parseable specification of the Brite Workflows plugin. Structured data for downstream automation (trigger registry, step-sequence validation, contract enforcement).

## Purpose

This file is the single source of truth for:
- **Trigger conditions** — when each skill activates, with keywords, preconditions, and precedence
- **Step sequences** — ordered steps for each orchestrator command, with skip/fail semantics
- **Cross-skill contracts** — what each skill provides and requires from the chain
- **Visual gating patterns** — standardized message templates for conditional visual output
- **Error handling contracts** — failure points and recovery actions per skill and command

### Format Contract

Structured data is embedded in fenced YAML blocks preceded by an HTML comment anchor:

```
<!-- spec:section-name:identifier -->
```

Downstream scripts extract blocks with:

```bash
# Validate ANCHOR against safe character class first
if ! [[ "$ANCHOR" =~ ^[a-zA-Z0-9:_-]+$ ]]; then
  echo "Invalid ANCHOR: $ANCHOR" >&2; exit 1
fi
sed -n "/<!-- spec:${ANCHOR} -->/,/^\`\`\`$/{ /^<!--/d; /^\`\`\`/d; p; }" docs/workflow-spec.md
```

Each block is independently parseable YAML. Adding or removing a skill touches one block.

**Anchor segments**: The middle segment is one of: `trigger`, `steps`, `contract`, `visual-gating`, `errors`. The third segment is the skill or command name.

**`visual-gating` field**: In step-sequence blocks, `visual-gating: true` means the step contains at least one conditional visual output path. It does not guarantee a visual artifact is always produced — the output may be gated by user choice, `--slides` flag, or file availability.

**Constraint**: YAML values must not contain a line that is exactly three backticks (`` ``` ``), as this would prematurely terminate the extraction range.

---

## 1. Trigger Conditions

### 1a. Inner Loop Skills

<!-- spec:trigger:brainstorming -->
```yaml
name: brainstorming
tier: inner-loop
user-invocable: false
position: 1
keywords:
  - "2+ modules or directories"
  - "4+ tasks"
  - "2+ viable implementation approaches"
  - "new pattern, integration, or architectural component"
negative-keywords:
  - "single-module change (1-2 files)"
  - "clear single approach"
  - "under 3 implementation steps"
  - "no new patterns or integrations"
activation-rule: "ANY keyword match activates; ALL negative keywords must be true to skip"
objective-criteria:
  modules: 2
  tasks: 4
  approaches: 2
  new-patterns: 1
preconditions:
  - "Issue ID available from session-start or conversation context"
  - "Issue readable via Linear MCP or description provided directly"
output-artifacts:
  - path: "docs/designs/<issue-id>-<slug>.md"
    type: file
    optional: false
  - path: "~/.agent/diagrams/<issue-id>-architecture.html"
    type: file
    optional: true
handoff:
  next: writing-plans
  marker: "**Brainstorming complete.**"
```

<!-- spec:trigger:writing-plans -->
```yaml
name: writing-plans
tier: inner-loop
user-invocable: false
position: 2
keywords:
  - "multi-step task needs planning"
  - "after brainstorming approval"
  - "after issue selection for straightforward work"
negative-keywords:
  - "single atomic change"
activation-rule: "ANY keyword match activates; ALL negative keywords must be true to skip"
objective-criteria: null
preconditions:
  - "Design doc exists if brainstorming criteria were met (glob docs/designs/<issue-id>-*.md)"
  - "Issue ID available from session-start or $ARGUMENTS"
optional-inputs:
  - source: "CDR INDEX via Context7 (handbook-library from ## Company Context)"
    condition: "## Company Context exists in CLAUDE.md and Context7 is available"
    on-unavailable: "Skip CDR check, log reason, proceed"
output-artifacts:
  - path: "docs/plans/<issue-id>-plan.md"
    type: file
    optional: false
  - path: "~/.agent/diagrams/<issue-id>-visual-plan.html"
    type: file
    optional: true
  - path: "~/.agent/diagrams/<issue-id>-plan-review.html"
    type: file
    optional: true
handoff:
  next: git-worktrees
  marker: "**Planning complete.**"
```

<!-- spec:trigger:git-worktrees -->
```yaml
name: git-worktrees
tier: inner-loop
user-invocable: false
position: 3
keywords:
  - "after a plan is approved"
  - "before execution begins"
  - "work in isolation"
negative-keywords:
  - "single-file changes"
  - "documentation-only updates"
activation-rule: ANY
objective-criteria: null
preconditions:
  - "Plan file exists at docs/plans/<issue-id>-plan.md"
  - "Issue ID matches ^[A-Z]+-[0-9]+$"
output-artifacts:
  - path: ".claude/worktrees/<issue-id>/"
    type: code
    optional: false
handoff:
  next: executing-plans
  marker: "**Worktree setup complete.**"
```

<!-- spec:trigger:executing-plans -->
```yaml
name: executing-plans
tier: inner-loop
user-invocable: false
position: 4
keywords:
  - "approved plan to implement"
  - "plan file exists"
negative-keywords:
  - "ad-hoc changes without a plan"
activation-rule: ANY
objective-criteria: null
preconditions:
  - "Plan file readable at docs/plans/<issue-id>-plan.md"
  - "Clean working state (git status --porcelain empty)"
output-artifacts:
  - path: "implemented code + tests"
    type: code
    optional: false
handoff:
  next: "/workflows:review"
  marker: "**Execution complete.**"
```

<!-- spec:trigger:verification-before-completion -->
```yaml
name: verification-before-completion
tier: inner-loop
user-invocable: false
position: null
keywords:
  - "task checkpoint during plan execution"
  - "before marking a Linear issue as done"
  - "after fixing a bug"
  - "before shipping"
negative-keywords: []
activation-rule: ANY
objective-criteria: null
preconditions:
  - "Invoked directly by executing-plans at each task checkpoint"
output-artifacts:
  - path: "verification report (inline)"
    type: context
    optional: false
handoff: null
```

<!-- spec:trigger:compound-learnings -->
```yaml
name: compound-learnings
tier: inner-loop
user-invocable: false
position: 5
keywords:
  - "ship phase after PR creation"
  - "after significant work session"
negative-keywords:
  - "trivial changes (typos, version bumps, single-line fixes)"
activation-rule: ANY
objective-criteria: null
preconditions:
  - "Diff exists (git log base..HEAD --oneline non-empty)"
  - "CLAUDE.md exists at project root"
output-artifacts:
  - path: "CLAUDE.md (updated)"
    type: file
    optional: false
  - path: "auto-memory session summary"
    type: file
    optional: false
  - path: "docs/ updates"
    type: file
    optional: true
handoff:
  next: best-practices-audit
  marker: "**Compound learnings complete.**"
```

<!-- spec:trigger:best-practices-audit -->
```yaml
name: best-practices-audit
tier: inner-loop
user-invocable: false
position: 6
keywords:
  - "ship phase after compound-learnings"
  - "after significant CLAUDE.md changes"
negative-keywords: []
activation-rule: ANY
objective-criteria: null
preconditions:
  - "CLAUDE.md exists at project root"
output-artifacts:
  - path: "CLAUDE.md (auto-fixed)"
    type: file
    optional: false
  - path: "~/.agent/diagrams/audit-<sanitized-project>.html"
    type: file
    optional: true
handoff:
  next: "/workflows:ship"
  marker: "**Best-practices audit complete.**"
```

<!-- spec:trigger:systematic-debugging -->
```yaml
name: systematic-debugging
tier: inner-loop
user-invocable: true
position: null
keywords:
  - "bug reports or unexpected behavior"
  - "failing tests that shouldn't be failing"
  - "production issues or error reports"
  - "it works on my machine"
  - "cause isn't immediately obvious"
negative-keywords: []
activation-rule: ANY
objective-criteria: null
preconditions: []
output-artifacts:
  - path: "regression test file"
    type: code
    optional: false
  - path: "fix + defense-in-depth"
    type: code
    optional: false
handoff:
  next: null
  marker: "**Debugging complete.**"
```

### 1b. Design Skills

<!-- spec:trigger:frontend-design -->
```yaml
name: frontend-design
tier: design
user-invocable: true
position: null
keywords:
  - "code"
  - "build"
  - "create"
  - "implement"
  - "web components"
  - "pages"
  - "layouts"
  - "dashboards"
  - "applications"
negative-keywords:
  - "design system planning"
  - "palette selection"
  - "style exploration"
activation-rule: ANY
objective-criteria: null
preconditions:
  - "User provides frontend requirements"
output-artifacts:
  - path: "production-grade HTML/CSS/JS/React code"
    type: code
    optional: false
handoff: null
```

<!-- spec:trigger:ui-ux-pro-max -->
```yaml
name: ui-ux-pro-max
tier: design
user-invocable: true
position: null
keywords:
  - "choose palette"
  - "select fonts"
  - "design system"
  - "plan visual direction"
  - "explore UI styles"
negative-keywords:
  - "building/coding UI"
  - "implementation"
activation-rule: ANY
objective-criteria: null
preconditions:
  - "Python 3 installed (setup step with guided remediation, not a hard blocker)"
  - "skills/ui-ux-pro-max/scripts/search.py available"
output-artifacts:
  - path: "design-system/MASTER.md"
    type: file
    optional: true
  - path: "design-system/pages/<page-name>.md"
    type: file
    optional: true
handoff: null
```

<!-- spec:trigger:visual-explainer -->
```yaml
name: visual-explainer
tier: design
user-invocable: true
position: null
keywords:
  - "diagram"
  - "architecture overview"
  - "diff review"
  - "plan review"
  - "project recap"
  - "comparison table"
  - "visual explanation"
  - "complex ASCII table (4+ rows or 3+ columns)"
negative-keywords: []
activation-rule: ANY
objective-criteria: null
preconditions: []
output-artifacts:
  - path: "~/.agent/diagrams/<sanitized-name>.html"
    type: file
    optional: false
handoff: null
```

<!-- spec:trigger:web-design-guidelines -->
```yaml
name: web-design-guidelines
tier: design
user-invocable: true
position: null
keywords:
  - "review my UI"
  - "check accessibility"
  - "audit design"
  - "review UX"
  - "check my site against best practices"
negative-keywords: []
activation-rule: ANY
objective-criteria: null
preconditions:
  - "Fetch guidelines from vercel-labs/web-interface-guidelines via WebFetch"
  - "User provides file or pattern argument"
output-artifacts:
  - path: "findings in file:line format (inline)"
    type: context
    optional: false
handoff: null
```

### 1c. Backend & Quality Skills

<!-- spec:trigger:react-best-practices -->
```yaml
name: react-best-practices
tier: backend-quality
user-invocable: true
position: null
keywords:
  - "writing React components"
  - "Next.js pages"
  - "data fetching"
  - "reviewing code for performance"
  - "refactoring React/Next.js"
  - "bundle optimization"
  - "load times"
negative-keywords: []
activation-rule: ANY
objective-criteria: null
preconditions: []
output-artifacts:
  - path: "advisory output (inline)"
    type: context
    optional: false
handoff: null
```

<!-- spec:trigger:python-best-practices -->
```yaml
name: python-best-practices
tier: backend-quality
user-invocable: true
position: null
keywords:
  - "FastAPI endpoints or routers"
  - "Pydantic models"
  - "SQLAlchemy queries or sessions"
  - "async Python code"
  - "Python API architecture"
negative-keywords:
  - "Ruff, mypy, Black configuration (use code-quality)"
activation-rule: ANY
objective-criteria: null
preconditions:
  - "Target: Python 3.11+, FastAPI 0.104+, Pydantic 2.x, SQLAlchemy 2.0+"
output-artifacts:
  - path: "advisory output (inline)"
    type: context
    optional: false
handoff: null
```

<!-- spec:trigger:testing-strategy -->
```yaml
name: testing-strategy
tier: backend-quality
user-invocable: true
position: null
keywords:
  - "writing test files or test cases"
  - "reviewing test code"
  - "what to mock"
  - "test infrastructure (MSW, factories, fixtures)"
  - "coverage thresholds"
  - "flaky or brittle tests"
  - "Playwright E2E"
  - "pytest fixtures"
  - "conftest.py"
negative-keywords:
  - "FastAPI-specific test patterns (use python-best-practices)"
  - "ESLint test plugins (use code-quality)"
activation-rule: ANY
objective-criteria: null
preconditions:
  - "Target: Vitest 3.x, RTL 16.x, MSW 2.x, Playwright 1.45+, pytest 8.x"
output-artifacts:
  - path: "advisory output (inline)"
    type: context
    optional: false
handoff: null
```

<!-- spec:trigger:code-quality -->
```yaml
name: code-quality
tier: backend-quality
user-invocable: true
position: null
keywords:
  - "setting up linting and formatting"
  - "reviewing code quality configs"
  - "generating ESLint, Prettier, Ruff, or mypy configs"
  - "lint/format steps to CI"
  - "linter not catching issues"
  - "migrating from legacy tooling (TSLint, Black/flake8/isort)"
negative-keywords: []
activation-rule: ANY
objective-criteria: null
preconditions:
  - "Auto-detect stack via package.json, tsconfig.json, pyproject.toml"
output-artifacts:
  - path: "eslint.config.mjs"
    type: file
    optional: true
  - path: ".prettierrc"
    type: file
    optional: true
  - path: "pyproject.toml (Ruff/mypy sections)"
    type: file
    optional: true
  - path: ".github/workflows/lint.yml"
    type: file
    optional: true
handoff: null
```

### 1d. Utility Skills

<!-- spec:trigger:agent-browser -->
```yaml
name: agent-browser
tier: utility
user-invocable: true
position: null
keywords:
  - "navigate websites"
  - "interact with web pages"
  - "fill forms"
  - "take screenshots"
  - "test web applications"
  - "extract information from web pages"
negative-keywords: []
activation-rule: ANY
objective-criteria: null
preconditions:
  - "agent-browser CLI installed and in PATH"
output-artifacts:
  - path: "screenshots, PDFs, video recordings, trace files"
    type: file
    optional: true
handoff: null
```

<!-- spec:trigger:find-skills -->
```yaml
name: find-skills
tier: utility
user-invocable: true
position: null
keywords:
  - "how do I do X"
  - "find a skill for X"
  - "is there a skill for X"
  - "can you do X"
  - "extending agent capabilities"
  - "search for tools, templates, or workflows"
negative-keywords: []
activation-rule: ANY
objective-criteria: null
preconditions:
  - "npx available for running skills CLI"
output-artifacts:
  - path: "conversational output with install commands"
    type: context
    optional: false
handoff: null
```

### 1e. Post-Plan Skills

<!-- spec:trigger:post-plan-setup -->
```yaml
name: post-plan-setup
tier: post-plan
user-invocable: true
position: null
keywords:
  - "after /plan-project produces a v1 plan"
negative-keywords: []
activation-rule: ANY
objective-criteria: null
preconditions:
  - "v1 plan file exists"
  - "Linear MCP available"
  - "Sequential thinking MCP available"
output-artifacts:
  - path: "docs/project-plan-refined.md"
    type: file
    optional: false
  - path: "docs/linear-issues-created.md"
    type: file
    optional: false
  - path: "CLAUDE.md"
    type: file
    optional: false
handoff: null
```

<!-- spec:trigger:refine-plan -->
```yaml
name: refine-plan
tier: post-plan
user-invocable: false
position: null
keywords:
  - "invoked by post-plan-setup orchestrator"
negative-keywords: []
activation-rule: ANY
objective-criteria: null
preconditions:
  - "v1 plan file exists"
  - "_shared/validation-pattern.md readable"
output-artifacts:
  - path: "docs/project-plan-refined.md"
    type: file
    optional: false
handoff:
  next: create-issues
  marker: null
```

<!-- spec:trigger:create-issues -->
```yaml
name: create-issues
tier: post-plan
user-invocable: false
position: null
keywords:
  - "invoked by post-plan-setup after refine-plan"
negative-keywords: []
activation-rule: ANY
objective-criteria: null
preconditions:
  - "Refined plan exists at docs/project-plan-refined.md"
  - "Linear MCP available"
  - "_shared/validation-pattern.md readable"
output-artifacts:
  - path: "Linear issues (created via MCP)"
    type: context
    optional: false
  - path: "docs/project-plan-refined.md (updated with issue IDs)"
    type: file
    optional: false
  - path: "docs/linear-issues-created.md"
    type: file
    optional: false
handoff:
  next: setup-claude-md
  marker: null
```

<!-- spec:trigger:setup-claude-md -->
```yaml
name: setup-claude-md
tier: post-plan
user-invocable: false
position: null
keywords:
  - "invoked by post-plan-setup after create-issues"
  - "project setup"
negative-keywords: []
activation-rule: ANY
objective-criteria: null
preconditions:
  - ".claude/skills/setup-claude-md/claude-code-best-practices.md readable"
  - "Project files for analysis (package.json, pyproject.toml, etc.)"
output-artifacts:
  - path: "CLAUDE.md"
    type: file
    optional: false
handoff: null
```

### 1f. Precedence Rules

<!-- spec:trigger:precedence -->
```yaml
precedence-rules:
  - rule: "frontend-design vs ui-ux-pro-max"
    condition: "If request involves building/coding, use frontend-design. If planning/exploring design direction, use ui-ux-pro-max."
    winner-keywords: ["build", "create", "implement", "code"]
    loser-keywords: ["choose palette", "design system", "plan visual direction"]

  - rule: "frontend-design vs web-design-guidelines"
    condition: "If request involves building new UI, use frontend-design. If reviewing/auditing existing UI, use web-design-guidelines."
    winner-keywords: ["build", "create", "implement"]
    loser-keywords: ["review", "audit", "check"]

  - rule: "python-best-practices vs code-quality"
    condition: "Architectural patterns use python-best-practices. Tooling config (Ruff, mypy, Black) uses code-quality."

  - rule: "testing-strategy vs python-best-practices"
    condition: "General test patterns use testing-strategy. FastAPI-specific test patterns (async clients, dependency overrides) use python-best-practices."

  - rule: "testing-strategy vs code-quality"
    condition: "Test code patterns use testing-strategy. ESLint test plugins and tooling use code-quality."

  - rule: "inner-loop chain order"
    condition: "Inner loop skills activate in strict sequence: brainstorming(1) → writing-plans(2) → git-worktrees(3) → executing-plans(4) → [review command] → compound-learnings(5) → best-practices-audit(6)"

  - rule: "systematic-debugging is standalone"
    condition: "systematic-debugging can activate anytime — not tied to inner loop sequence position."

  - rule: "verification-before-completion is a sub-skill"
    condition: "Only invoked by executing-plans at task checkpoints. Never activates independently."
```

---

## 2. Step Sequences

### 2a. session-start

<!-- spec:steps:session-start -->
```yaml
command: session-start
prereqs:
  - "Linear MCP — list projects (1 result) confirms auth"
  - "Sequential-thinking MCP — trivial thought confirms running"
  - "Context7 MCP — resolve-library-id('react') confirms running (non-blocking)"
steps:
  - id: 0
    name: "Verify Prerequisites"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: STOP
    activates-skill: null
    visual-gating: false
  - id: 1
    name: "Environment Setup"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: true
  - id: 2
    name: "Company Context"
    required: false
    skip-condition: "CLAUDE.md has ## Company Context section or <!-- no-company-context --> marker"
    skip-target: 3
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
    note: "Runs Company Context Interview from commands/_shared/company-context-template.md. Produces: company-context block in CLAUDE.md."
  - id: 3
    name: "Query Linear for Open Issues"
    required: true
    skip-condition: "$ARGUMENTS contains an issue ID or URL"
    skip-target: 4
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 4
    name: "Read Issue Details"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 5
    name: "Brainstorm (Objective Complexity Check)"
    required: true
    skip-condition: "ALL negative criteria true (single-module, single-approach, <3 steps, no new patterns)"
    skip-target: 6
    jump-on-fail: null
    activates-skill: brainstorming
    visual-gating: false
  - id: 6
    name: "Write Plan"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: writing-plans
    visual-gating: true
  - id: 7
    name: "Set Up Worktree"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: git-worktrees
    visual-gating: false
  - id: 8
    name: "Execute"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: executing-plans
    visual-gating: false
```

### 2b. review

<!-- spec:steps:review -->
```yaml
command: review
prereqs:
  - "Task tool dispatch — trivial agent returns 'pong'"
steps:
  - id: 0
    name: "Verify Agent Dispatch"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: STOP
    activates-skill: null
    visual-gating: false
  - id: 1
    name: "Self-Verification"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 2
    name: "Diff Triage"
    required: false
    skip-condition: "$ARGUMENTS contains 'skip triage' or 'no triage'"
    skip-target: 3
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
    note: "Haiku agent classifies diff as trivial/non-trivial. skip-target (3) applies to user skip only. TRIVIAL verdict jumps to Step 8 (abbreviated report, skipping Steps 3-7). Provides: TRIAGE_VERDICT."
  - id: 3
    name: "Simplify Pass"
    required: false
    skip-condition: "$ARGUMENTS contains 'skip simplify' or 'no simplify'"
    skip-target: 4
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 4
    name: "Select & Launch Review Agents"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
    note: "Depth mode from $ARGUMENTS: fast (Tier 1 only), thorough (Tier 1+2, default), comprehensive (all tiers). Unrecognized depth defaults to thorough. All review agents run on Opus."
  - id: 5
    name: "Collect & Classify Findings"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
    note: "Confidence threshold filtering: >= 7 included, low-confidence P2/P3 filtered, borderline P1s marked for human review. Missing confidence defaults to 5."
  - id: 6
    name: "Validate Findings"
    required: false
    skip-condition: "$ARGUMENTS contains 'skip validation' or 'no validation'; in fast mode, P2/P3 validation skipped (P1s still validated)"
    skip-target: 7
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
    note: "Per-finding verification: Opus subagent per P1, Sonnet subagent per P2/P3. Max 20 subagents. P1 verifiers: 10 turns, P2/P3 verifiers: 5 turns. In fast mode, only P1s validated. Provides: VALIDATED_FINDINGS."
  - id: 7
    name: "Fix Loop (P1s Only)"
    required: false
    skip-condition: "No auto-fixable P1 findings (confidence >= 7)"
    skip-target: 8
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 8
    name: "Visual Review Report"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: true
  - id: 9
    name: "Final Report"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
```

### 2c. ship

<!-- spec:steps:ship -->
```yaml
command: ship
prereqs:
  - "gh auth status succeeds"
  - "gh repo view --json name succeeds"
steps:
  - id: 0
    name: "Verify GitHub CLI"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: STOP
    activates-skill: null
    visual-gating: false
  - id: 1
    name: "Pre-Ship Checks"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 2
    name: "Create Pull Request"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 3
    name: "Update Linear"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 4
    name: "Compound Learnings"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: compound-learnings
    visual-gating: false
  - id: 5
    name: "Best Practices Audit"
    required: false
    skip-condition: "compound-learnings reported no CLAUDE.md changes of any kind (no entries added, updated, pruned, and no stale claims auto-removed or flagged)"
    skip-target: 6
    jump-on-fail: null
    activates-skill: best-practices-audit
    visual-gating: true
  - id: 6
    name: "Worktree Cleanup"
    required: false
    skip-condition: "Not working in a git worktree"
    skip-target: 7
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 7
    name: "Session Close"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
```

### 2d. sprint-planning

<!-- spec:steps:sprint-planning -->
```yaml
command: sprint-planning
prereqs:
  - "Linear MCP — list projects (1 result) confirms auth"
  - "Sequential-thinking MCP — trivial thought confirms running"
steps:
  - id: 0
    name: "Verify Prerequisites"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: STOP
    activates-skill: null
    visual-gating: false
  - id: 1
    name: "Resolve Context"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 2
    name: "Current State Assessment"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 3
    name: "Pull & Display Backlog"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 4
    name: "Interactive Planning"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 5
    name: "Assign to Cycle"
    required: false
    skip-condition: "Prioritization-only mode (no cycles exist)"
    skip-target: 6
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 6
    name: "Summary"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: true
```

### 2e. retrospective

<!-- spec:steps:retrospective -->
```yaml
command: retrospective
prereqs:
  - "Linear MCP — list projects (1 result) confirms auth"
  - "Sequential-thinking MCP — trivial thought confirms running"
steps:
  - id: 0
    name: "Verify Prerequisites"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: STOP
    activates-skill: null
    visual-gating: false
  - id: 1
    name: "Resolve Context"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 2
    name: "Delivery Summary"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 3
    name: "Retrospective Discussion"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 4
    name: "Visual Retro Deck"
    required: false
    skip-condition: "User declines slides and --slides not set"
    skip-target: 5
    jump-on-fail: null
    activates-skill: null
    visual-gating: true
  - id: 5
    name: "Post Status Update"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 6
    name: "Create Follow-up Issues"
    required: false
    skip-condition: "No action items marked 'Create Issue? = Yes'"
    skip-target: 7
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 7
    name: "Summary"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
```

### 2f. scope

<!-- spec:steps:scope -->
```yaml
command: scope
prereqs:
  - "Linear MCP — list projects (1 result) confirms auth"
  - "Sequential-thinking MCP — trivial thought confirms running"
steps:
  - id: 0
    name: "Verify Prerequisites"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: STOP
    activates-skill: null
    visual-gating: false
  - id: 1
    name: "Interview Phase"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 2
    name: "Context Gathering"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 3
    name: "Collaborative Ideation"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: true
  - id: 4
    name: "Issue Creation"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 5
    name: "Prioritization"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 6
    name: "Session Summary"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: true
```

### 2g. architecture-decision

<!-- spec:steps:architecture-decision -->
```yaml
command: architecture-decision
prereqs:
  - "Sequential-thinking MCP — trivial thought confirms running"
steps:
  - id: 0
    name: "Verify Prerequisites"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: STOP
    activates-skill: null
    visual-gating: false
  - id: 1
    name: "Identify the Decision"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 2
    name: "Explore Context"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 3
    name: "Analyze Options"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 4
    name: "Confirm the Decision"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 5
    name: "Document Consequences"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: true
  - id: 6
    name: "Determine Status"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 7
    name: "Write the ADR"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 8
    name: "Update CLAUDE.md"
    required: true
    skip-condition: "No project CLAUDE.md exists"
    skip-target: 9
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
  - id: 9
    name: "Summary"
    required: true
    skip-condition: null
    skip-target: null
    jump-on-fail: null
    activates-skill: null
    visual-gating: false
```

---

## 3. Cross-Skill Contracts

### 3a. Inner Loop Chain

<!-- spec:contract:inner-loop-chain -->
```yaml
chain: inner-loop
sequence:
  - from: session-start
    to: brainstorming
    provides:
      - "Issue ID"
      - "Issue details (description, acceptance criteria)"
      - "CLAUDE.md context"
      - "Auto-memory context"
    requires: []

  - from: brainstorming
    to: writing-plans
    provides:
      - "Design document at docs/designs/<issue-id>-<slug>.md"
      - "Architecture diagram at ~/.agent/diagrams/<issue-id>-architecture.html (optional)"
      - "Key decisions summary"
      - "Scope boundaries"
    requires:
      - "Issue ID"
      - "Issue readable via Linear or provided directly"

  - from: writing-plans
    to: git-worktrees
    provides:
      - "Plan file at docs/plans/<issue-id>-plan.md"
      - "Visual plan at ~/.agent/diagrams/<issue-id>-visual-plan.html (optional)"
      - "Plan review at ~/.agent/diagrams/<issue-id>-plan-review.html (optional)"
      - "Task count and dependency graph"
    requires:
      - "Issue ID"
      - "Design doc (if brainstorming ran)"

  - from: git-worktrees
    to: executing-plans
    provides:
      - "Worktree path at .claude/worktrees/<issue-id>/"
      - "Branch name (<issue-id>/<description>)"
      - "Base commit hash"
      - "Baseline test/build/lint status"
    requires:
      - "Plan file at docs/plans/<issue-id>-plan.md"
      - "Valid issue ID matching ^[A-Z]+-[0-9]+$"

  - from: executing-plans
    to: "/workflows:review"
    provides:
      - "Implemented code and tests"
      - "Commit history on branch"
      - "Per-task verification reports"
    requires:
      - "Plan file at docs/plans/<issue-id>-plan.md"
      - "Design doc at docs/designs/<issue-id>-*.md (if brainstorming ran)"
      - "Clean working state"

  - from: "/workflows:review"
    to: "/workflows:ship"
    provides:
      - "TRIAGE_VERDICT (trivial/non-trivial from diff-triage agent)"
      - "Agent selection results (tier, agent list, activation reasons, depth mode)"
      - "Simplify pass results (applied/suggestions/reverted)"
      - "Review findings (P1/P2/P3) with confidence scores"
      - "VALIDATED_FINDINGS (confirmed/downgraded/dismissed from per-finding verification)"
      - "P1 fixes applied (auto-fixable, confidence >= 7)"
      - "Borderline P1s for human review (confidence < 7)"
      - "Filtered finding count (low-confidence P2/P3s)"
      - "Visual review report"
      - "Verdict (ready/needs-input/blocked/has-borderline-p1s)"
    requires:
      - "Task tool dispatch working"

  - from: "/workflows:ship"
    to: compound-learnings
    provides:
      - "PR URL"
      - "Linear issue status update"
    requires:
      - "gh CLI authenticated"
      - "Tests and build passing"

  - from: compound-learnings
    to: best-practices-audit
    provides:
      - "CLAUDE.md updates (entries added/updated/pruned)"
      - "Fact-check results"
      - "Session summary in auto-memory"
    requires:
      - "Diff exists on branch"
      - "CLAUDE.md exists"

  # Return handoff: best-practices-audit completes and returns control to ship
  - from: best-practices-audit
    to: "/workflows:ship"
    provides:
      - "CLAUDE.md auto-fixes"
      - "Flagged items for developer"
      - "Visual audit report (optional)"
    requires:
      - "CLAUDE.md exists"
```

### 3b. Artifact Registry

<!-- spec:contract:artifact-registry -->
```yaml
artifacts:
  - id: design-doc
    path: "docs/designs/<issue-id>-<slug>.md"
    producer: brainstorming
    consumers: [writing-plans, git-worktrees, executing-plans, compound-learnings]
    persistence: permanent

  - id: architecture-diagram
    path: "~/.agent/diagrams/<issue-id>-architecture.html"
    producer: brainstorming
    consumers: []
    persistence: session

  - id: plan-file
    path: "docs/plans/<issue-id>-plan.md"
    producer: writing-plans
    consumers: [git-worktrees, executing-plans, compound-learnings]
    persistence: permanent

  - id: visual-plan
    path: "~/.agent/diagrams/<issue-id>-visual-plan.html"
    producer: writing-plans
    consumers: []
    persistence: session

  - id: plan-review
    path: "~/.agent/diagrams/<issue-id>-plan-review.html"
    producer: writing-plans
    consumers: []
    persistence: session

  - id: worktree
    path: ".claude/worktrees/<issue-id>/"
    producer: git-worktrees
    consumers: [executing-plans, "ship (command)"]
    persistence: temporary

  - id: review-report
    path: "~/.agent/diagrams/review-<sanitized-branch>.html"
    producer: "review (command)"
    consumers: []
    persistence: session

  - id: claude-md
    path: "CLAUDE.md"
    producer: compound-learnings
    consumers: [best-practices-audit, session-start, writing-plans]
    persistence: permanent

  - id: session-summary
    path: "auto-memory directory"
    producer: compound-learnings
    consumers: [session-start, scope]
    persistence: permanent

  - id: audit-report
    path: "~/.agent/diagrams/audit-<sanitized-project>.html"
    producer: best-practices-audit
    consumers: []
    persistence: session

  - id: sprint-slides
    path: "~/.agent/diagrams/sprint-cycle-<N>-overview.html"
    producer: "sprint-planning (command)"
    consumers: []
    persistence: session

  - id: retro-slides
    path: "~/.agent/diagrams/retro-cycle-<N>.html"
    path-alt: "~/.agent/diagrams/retro-cycle-<N>-midcheck.html"
    note: "alt path used in mid-sprint mode"
    producer: "retrospective (command)"
    consumers: []
    persistence: session

  - id: scope-mindmap
    path: "~/.agent/diagrams/scope-<sanitized-project>-mindmap.html"
    producer: "scope (command)"
    consumers: []
    persistence: session

  - id: scope-slides
    path: "~/.agent/diagrams/scope-<sanitized-project>-slides.html"
    producer: "scope (command)"
    consumers: []
    persistence: session

  - id: adr-diagrams
    path: "~/.agent/diagrams/adr-<slug>-diagrams.html"
    producer: "architecture-decision (command)"
    consumers: []
    persistence: session

  - id: adr-file
    path: "docs/decisions/NNN-<slug>.md"
    producer: "architecture-decision (command)"
    consumers: ["session-start (via CLAUDE.md @import)"]
    persistence: permanent

  - id: company-context
    path: "CLAUDE.md (## Company Context section)"
    producer: "session-start (command, Step 2)"
    consumers: [brainstorming, writing-plans, executing-plans, compound-learnings]
    persistence: permanent
    schema:
      fields:
        - name: initiative
          type: string
          source: "Linear MCP (get_project)"
          sanitization: "[a-zA-Z0-9 _.,/-], max 120 chars"
        - name: goal
          type: string
          source: "developer input (AskUserQuestion)"
        - name: team
          type: string
          source: "Linear MCP (get_project)"
          sanitization: "[a-zA-Z0-9 _.,/-], max 120 chars"
        - name: lead
          type: string
          source: "Linear MCP (get_project)"
          sanitization: "[a-zA-Z0-9 _.,/-], max 120 chars"
        - name: related-projects
          type: "string[]"
          source: "Linear MCP + developer input"
          sanitization: "[a-zA-Z0-9 _.,/-], max 120 chars each"
        - name: handbook-library
          type: string
          source: "hardcoded (/brite-nites/handbook)"
        - name: handbook-topics
          type: "string[]"
          source: "developer input (AskUserQuestion)"
          sanitization: "[a-zA-Z0-9 _-], max 40 chars each"

  - id: project-recap
    path: "~/.agent/diagrams/<repo-name>-project-recap.html"
    producer: "session-start (command)"
    alternate-producer: "project-recap (command)"
    optional: true
    condition: "user accepts visual recap offer in session-start Step 1"
    consumers: []
    persistence: session

  - id: refined-plan
    path: "docs/project-plan-refined.md"
    producer: refine-plan
    consumers: [create-issues]
    persistence: permanent

  - id: issues-created-log
    path: "docs/linear-issues-created.md"
    producer: create-issues
    consumers: []
    persistence: permanent
```

### 3c. Post-Plan Chain

<!-- spec:contract:post-plan-chain -->
```yaml
chain: post-plan
sequence:
  - from: post-plan-setup
    to: refine-plan
    provides:
      - "v1 plan file path"
    requires:
      - "v1 plan file exists"
      - "Linear MCP available"
      - "Sequential thinking MCP available"

  - from: refine-plan
    to: create-issues
    provides:
      - "Refined plan at docs/project-plan-refined.md"
      - "Task dependency graph"
      - "Per-task context, steps, validation, complexity"
    requires:
      - "v1 plan file"

  - from: create-issues
    to: setup-claude-md
    provides:
      - "Linear issues created and linked"
      - "Updated docs/project-plan-refined.md with issue IDs"
      - "docs/linear-issues-created.md"
    requires:
      - "Refined plan at docs/project-plan-refined.md"
      - "Linear MCP available"

  - from: setup-claude-md
    to: null
    provides:
      - "CLAUDE.md in project root"
    requires:
      - "claude-code-best-practices.md reference readable"
```

---

## 4. Visual Gating Patterns

### 4a. Pattern Definitions

<!-- spec:visual-gating:patterns -->
```yaml
patterns:
  - id: skip
    template: "Visual-explainer files not found. Skipping [artifact name]."
    trigger: "Any required visual-explainer file (SKILL.md, template, reference) cannot be read"
    action: "Skip visual output entirely, continue workflow"

  - id: degrade
    template: "Visual-explainer files not found. Generating plain HTML [artifact name]."
    trigger: "Visual-explainer files unavailable but plain HTML fallback exists"
    scope: "review.md Step 8 only"
    action: "Generate plain semantic HTML with same structure, no external CSS/templates/animations"

  - id: non-file-skip
    template: "--slides requested, but [reason]. Skipping [artifact name]."
    trigger: "Slides requested via --slides flag but a non-file condition prevents generation"
    constraint: "[reason] must be a hardcoded literal string, never derived from external data"
    action: "Skip visual output, continue workflow"

rules:
  - "Never clear slides_requested on file failure — flag represents user intent"
  - "Each visual step independently checks file availability"
  - "Prefix 'Visual-explainer files not found.' must be identical across skip and degrade patterns. non-file-skip uses a different prefix ('--slides requested, but...') — it applies when visual-explainer files ARE available but a non-file condition prevents generation."
```

### 4b. Per-File Matrix

<!-- spec:visual-gating:matrix -->
```yaml
visual-gating-files:
  - file: "commands/session-start.md"
    step: "Step 1 (project recap)"
    patterns: [skip]
    artifact: "project recap HTML"

  - file: "commands/review.md"
    step: "Step 6 (visual review report)"
    patterns: [degrade]
    artifact: "review report HTML"

  - file: "commands/sprint-planning.md"
    step: "Optional slides subsection after Step 6 (sprint overview slides)"
    patterns: [skip, non-file-skip]
    artifact: "sprint overview deck"

  - file: "commands/retrospective.md"
    step: "Step 4 (visual retro deck)"
    patterns: [skip, non-file-skip]
    artifact: "retro deck"

  - file: "commands/scope.md"
    step: "Step 3 item 6 (mind map)"
    patterns: [skip]
    artifact: "scope mind map"

  - file: "commands/scope.md"
    step: "Optional slides subsection after Step 6 (summary slides)"
    patterns: [skip]
    artifact: "scope summary slides"

  - file: "commands/architecture-decision.md"
    step: "Step 5b (architecture diagrams)"
    patterns: [skip]
    artifact: "before/after diagrams"

  - file: "skills/brainstorming/SKILL.md"
    step: "Phase 4 (architecture diagram)"
    patterns: [skip]
    artifact: "architecture diagram"

  - file: "skills/writing-plans/SKILL.md"
    step: "Visual Plan Approval prerequisite read"
    patterns: [skip]
    artifact: "visual plan and plan review"

  - file: "skills/best-practices-audit/SKILL.md"
    step: "Visual Audit Report availability check"
    patterns: [skip]
    artifact: "audit report HTML"
```

---

## 5. Error Handling Contracts

### 5a. Inner Loop Skills

<!-- spec:errors:brainstorming -->
```yaml
skill: brainstorming
error-handling:
  - failure-point: "Issue ID missing"
    action: escalate
    detail: "Ask developer for issue ID via AskUserQuestion"
  - failure-point: "Linear inaccessible"
    action: degrade
    detail: "Proceed with whatever context is available"
  - failure-point: "Approval fails after 3 iterations"
    action: escalate
    detail: "AskUserQuestion: Approve as-is / Continue iterating / Stop and proceed to planning"
  - failure-point: "Design doc file write verification fails"
    action: retry
    detail: "Retry once. If still fails, report error and do not print completion marker"
  - failure-point: "Visual-explainer files not found"
    action: skip
    detail: "Skip diagram generation entirely"
```

<!-- spec:errors:writing-plans -->
```yaml
skill: writing-plans
error-handling:
  - failure-point: "Design doc missing when brainstorming should have run"
    action: escalate
    detail: "AskUserQuestion: Run brainstorming first / Provide doc path / Proceed without one"
  - failure-point: "Issue ID missing"
    action: escalate
    detail: "Ask developer for issue ID"
  - failure-point: "CDR INDEX unavailable (no Company Context, Context7 down, or no results)"
    action: skip
    detail: "Log reason in Decision Log format, proceed with planning without CDR awareness"
  - failure-point: "Visual-explainer files not found"
    action: skip
    detail: "Skip Steps 2 and 3 of Visual Plan Approval, proceed to Step 4 (Approval)"
  - failure-point: "Plan file cannot be read for task count"
    action: degrade
    detail: "Fall back to counting tasks from plan text in context window, note discrepancy"
  - failure-point: "Plan-review reveals blocking issues after 3 iterations"
    action: escalate
    detail: "AskUserQuestion: Approve plan as-is / Continue iterating / Stop and revisit design"
```

<!-- spec:errors:git-worktrees -->
```yaml
skill: git-worktrees
error-handling:
  - failure-point: "Plan file does not exist"
    action: STOP
    detail: "No plan file found. Run planning first."
  - failure-point: "Issue ID invalid"
    action: STOP
    detail: "Stop and ask developer for valid issue ID"
  - failure-point: "Working directory dirty"
    action: escalate
    detail: "AskUserQuestion: Stash changes / Commit changes first / Abort worktree setup"
  - failure-point: "Baseline tests fail"
    action: escalate
    detail: "AskUserQuestion: Proceed with known failures / Investigate baseline failures / Stop and fix main first"
```

<!-- spec:errors:executing-plans -->
```yaml
skill: executing-plans
error-handling:
  - failure-point: "Plan file does not exist"
    action: STOP
    detail: "No plan file found. Run planning first."
  - failure-point: "Working directory dirty"
    action: STOP
    detail: "Commit or stash changes before executing"
  - failure-point: "Task stuck (3+ consecutive tool calls without progress)"
    action: escalate
    detail: "AskUserQuestion: Retry with different approach / Skip this task / Stop execution"
  - failure-point: "Skip requested but dependent tasks exist"
    action: escalate
    detail: "Warn user about dependents, treat as Stop unless explicitly confirmed"
  - failure-point: "Verification BLOCKED after 3 retries"
    action: escalate
    detail: "AskUserQuestion: Retry with different approach / Skip task and continue / Stop execution"
```

<!-- spec:errors:verification-before-completion -->
```yaml
skill: verification-before-completion
error-handling:
  - failure-point: "Level 1 (build) fails"
    action: STOP
    detail: "Task is NOT complete. Stop and fix."
  - failure-point: "Any verification level fails"
    action: retry
    detail: "Analyze root cause, fix, re-verify from Level 1"
  - failure-point: "Max 3 retries exhausted"
    action: escalate
    detail: "AskUserQuestion: Retry from Level 1 with different approach / Skip this level / Stop for manual review"
```

<!-- spec:errors:compound-learnings -->
```yaml
skill: compound-learnings
error-handling:
  - failure-point: "No commits on branch"
    action: skip
    detail: "Skip compounding: No commits on branch. Nothing to compound."
  - failure-point: "CLAUDE.md missing"
    action: escalate
    detail: "AskUserQuestion: Create one with /workflows:setup-claude-md / Skip compounding"
  - failure-point: "CLAUDE.md write fails"
    action: escalate
    detail: "AskUserQuestion: Retry write / Skip CLAUDE.md updates / Stop compounding"
```

<!-- spec:errors:best-practices-audit -->
```yaml
skill: best-practices-audit
error-handling:
  - failure-point: "CLAUDE.md missing"
    action: STOP
    detail: "No CLAUDE.md found. Use /workflows:setup-claude-md to create one."
  - failure-point: "Best-practices reference not accessible"
    action: degrade
    detail: "Use built-in audit checklist as authoritative guide"
  - failure-point: "Visual-explainer files missing"
    action: skip
    detail: "Skip visual output: Visual-explainer files not found. Skipping audit report."
```

<!-- spec:errors:systematic-debugging -->
```yaml
skill: systematic-debugging
error-handling:
  - failure-point: "Cannot reproduce bug"
    action: escalate
    detail: "AskUserQuestion: Add more logging and retry / Get more info from reporter / Proceed with best guess (risky)"
```

### 5b. Commands

<!-- spec:errors:session-start -->
```yaml
command: session-start
error-handling:
  - failure-point: "Linear MCP unavailable"
    action: STOP
    detail: "Cannot reach Linear. Run /workflows:smoke-test to diagnose."
  - failure-point: "Sequential-thinking MCP unavailable"
    action: STOP
    detail: "Cannot reach sequential-thinking. Run /workflows:smoke-test to diagnose."
  - failure-point: "Context7 MCP unavailable (Step 0)"
    action: degrade
    detail: "WARN — library docs and handbook context unavailable. Continue session."
  - failure-point: "Handbook not found on Context7 (Step 0)"
    action: degrade
    detail: "WARN — handbook not indexed. Company context interview skips handbook validation."
  - failure-point: "Working directory dirty (Step 1)"
    action: escalate
    detail: "Warn and ask how to proceed"
  - failure-point: "Company context interview skipped by user (Step 2)"
    action: skip
    detail: "Write <!-- no-company-context --> marker, proceed to Step 3"
  - failure-point: "No Linear project configured"
    action: escalate
    detail: "Warn and ask user for project name manually"
  - failure-point: "No open issues found"
    action: escalate
    detail: "AskUserQuestion: Create a new issue?"
  - failure-point: "Visual-explainer files not found (Step 1 recap)"
    action: skip
    detail: "Skip visual recap, proceed to Step 2"
```

<!-- spec:errors:review -->
```yaml
command: review
error-handling:
  - failure-point: "Agent dispatch fails (Step 0)"
    action: STOP
    detail: "Agent dispatch failed. Cannot run review agents."
  - failure-point: "Diff triage agent fails (Step 2)"
    action: degrade
    detail: "Assume NON-TRIVIAL, proceed to Step 3"
  - failure-point: "Simplify agent fails to dispatch (Step 3)"
    action: degrade
    detail: "Skip simplify pass, proceed to Step 4"
  - failure-point: "No test suite detected (Step 3 auto-fix)"
    action: degrade
    detail: "Report all simplify findings as suggestions only, skip auto-fix"
    note: "Branch condition within Step 3, not a step-level failure"
  - failure-point: "Review agent fails to dispatch (Step 4)"
    action: escalate
    detail: "AskUserQuestion: Retry failed agent / Continue with available results / Stop review"
  - failure-point: "Unrecognized depth mode in $ARGUMENTS (Step 4)"
    action: degrade
    detail: "Default to thorough (Tier 1 + Tier 2)"
  - failure-point: "Stack detection fails (Step 4)"
    action: degrade
    detail: "Proceed with Tier 1 agents only (code-reviewer, security-reviewer, performance-reviewer)"
  - failure-point: "CLAUDE.md override parse fails (Step 4)"
    action: degrade
    detail: "Ignore overrides, proceed with agents selected from Tiers 1-2"
  - failure-point: "Missing confidence score on finding (Step 5)"
    action: degrade
    detail: "Default to confidence 5. P2/P3 filtered, P1 routed to human review."
  - failure-point: "Validation subagent fails (Step 6)"
    action: degrade
    detail: "Treat finding as CONFIRMED, proceed with remaining validations"
  - failure-point: "Validation subagent cap exceeded (Step 6)"
    action: degrade
    detail: "Batch remaining P3s into a single Sonnet subagent"
  - failure-point: "P1 persists after 3 fix attempts (Step 7)"
    action: escalate
    detail: "Flag for human review with full context on what was tried"
  - failure-point: "Visual-explainer files not found (Step 8)"
    action: degrade
    detail: "Generate plain HTML review report"
```

<!-- spec:errors:ship -->
```yaml
command: ship
error-handling:
  - failure-point: "gh not authenticated (Step 0)"
    action: STOP
    detail: "GitHub CLI not authenticated. Run gh auth login first."
  - failure-point: "Not in GitHub-connected repo (Step 0)"
    action: STOP
    detail: "Not in a GitHub-connected repository."
  - failure-point: "Pre-ship check fails (Step 1)"
    action: escalate
    detail: "AskUserQuestion: Fix the failing check / Skip (requires double confirmation) / Stop"
  - failure-point: "PR creation fails (Step 2)"
    action: escalate
    detail: "AskUserQuestion: Retry push and PR creation / Create PR manually / Stop"
  - failure-point: "Linear MCP inaccessible (Step 3)"
    action: degrade
    detail: "Provide manual steps"
```

<!-- spec:errors:sprint-planning -->
```yaml
command: sprint-planning
error-handling:
  - failure-point: "Linear MCP unavailable (Step 0)"
    action: STOP
    detail: "Cannot reach Linear. Run /workflows:smoke-test to diagnose."
  - failure-point: "Sequential-thinking MCP unavailable (Step 0)"
    action: STOP
    detail: "Cannot reach sequential-thinking. Run /workflows:smoke-test to diagnose."
  - failure-point: "No Linear project configured (Step 1)"
    action: escalate
    detail: "Warn and ask user for project name manually"
  - failure-point: "Unrecognised $ARGUMENTS (Step 1)"
    action: escalate
    detail: "Warn and AskUserQuestion: Next cycle / Current cycle review / Specific cycle number"
  - failure-point: "No cycles exist (Step 1)"
    action: degrade
    detail: "Enter prioritization-only mode: skip Steps 2c and 5"
  - failure-point: "Individual issue assignment fails (Step 5)"
    action: degrade
    detail: "Continue with remaining assignments, report failures"
  - failure-point: "Visual-explainer files not found (Step 6 slides)"
    action: skip
    detail: "Visual-explainer files not found. Skipping sprint overview deck."
  - failure-point: "--slides in prioritization-only mode"
    action: skip
    detail: "--slides requested, but no cycle exists to visualize. Skipping sprint overview deck."
```

<!-- spec:errors:retrospective -->
```yaml
command: retrospective
error-handling:
  - failure-point: "Linear MCP unavailable (Step 0)"
    action: STOP
    detail: "Cannot reach Linear. Run /workflows:smoke-test to diagnose."
  - failure-point: "Sequential-thinking MCP unavailable (Step 0)"
    action: STOP
    detail: "Cannot reach sequential-thinking. Run /workflows:smoke-test to diagnose."
  - failure-point: "No cycles exist (Step 1)"
    action: STOP
    detail: "No cycles found. Create a cycle in Linear first."
  - failure-point: "Visual-explainer files not found (Step 4)"
    action: skip
    detail: "Visual-explainer files not found. Skipping retro deck."
  - failure-point: "Cycle number validation fails (Step 4)"
    action: skip
    detail: "Cycle number failed format validation. Skipping slide deck."
  - failure-point: "Individual issue creation fails (Step 6)"
    action: degrade
    detail: "Continue with remaining issues, report failures"
```

<!-- spec:errors:scope -->
```yaml
command: scope
error-handling:
  - failure-point: "Linear MCP unavailable (Step 0)"
    action: STOP
    detail: "Cannot reach Linear. Run /workflows:smoke-test to diagnose."
  - failure-point: "Sequential-thinking MCP unavailable (Step 0)"
    action: STOP
    detail: "Cannot reach sequential-thinking. Run /workflows:smoke-test to diagnose."
  - failure-point: "Visual-explainer files not found (Step 3 mind map)"
    action: skip
    detail: "Visual-explainer files not found. Skipping mind map."
  - failure-point: "Visual-explainer files not found (Step 6 slides)"
    action: skip
    detail: "Visual-explainer files not found. Skipping summary deck."
```

<!-- spec:errors:architecture-decision -->
```yaml
command: architecture-decision
error-handling:
  - failure-point: "Sequential-thinking MCP unavailable (Step 0)"
    action: STOP
    detail: "Cannot reach sequential-thinking. Run /workflows:smoke-test to diagnose."
  - failure-point: "$ARGUMENTS validation fails (Step 1)"
    action: degrade
    detail: "Treat as empty, ask user for topic manually"
  - failure-point: "Visual-explainer files not found (Step 5b)"
    action: skip
    detail: "Visual-explainer files not found. Skipping architecture diagrams."
  - failure-point: "Context fact-check finds inaccuracies (Step 7d)"
    action: escalate
    detail: "Present corrections to developer, incorporate accepted changes"
  - failure-point: "No project CLAUDE.md (Step 8)"
    action: skip
    detail: "Skip CLAUDE.md update, note: add @import when CLAUDE.md is created"
```
