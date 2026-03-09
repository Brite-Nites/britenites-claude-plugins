# Workflow Guide

A complete reference for using the Brite Workflows plugin. Covers the inner loop (daily development), visual features, orchestrator commands, and troubleshooting.

## Table of Contents

1. [The Inner Loop](#1-the-inner-loop)
2. [Skill Reference](#2-skill-reference)
3. [Visual Features](#3-visual-features)
4. [Orchestrator Commands](#4-orchestrator-commands)
5. [Troubleshooting](#5-troubleshooting)
6. [Configuration](#6-configuration)

---

## 1. The Inner Loop

The inner loop is the core development workflow. You run **3 commands** — everything else activates automatically.

```
/workflows:session-start ──► brainstorm ──► plan ──► worktree ──► execute
                                                                      │
                                        ship ◄── /workflows:ship      │
                                          │                            │
                                          └── compound ── audit        │
                                                                       ▼
                                                            /workflows:review
```

### What you type

| Step | Command | When |
|------|---------|------|
| Start | `/workflows:session-start` | Beginning of a work session |
| Review | `/workflows:review` | After executing the plan |
| Ship | `/workflows:ship` | After review passes |

### What happens automatically

Between those 3 commands, skills activate in sequence based on the work:

1. **session-start** pulls latest, reads CLAUDE.md and auto-memory, queries Linear for your next issue
2. **brainstorming** activates if complexity criteria are met (2+ modules, 4+ tasks, 2+ approaches, or new patterns) — produces a design document via Socratic discovery
3. **writing-plans** breaks the work into 2-5 minute tasks with exact file paths, verification steps, and TDD structure
4. **git-worktrees** creates an isolated branch and workspace, installs dependencies, verifies clean baseline
5. **executing-plans** runs each task via a fresh subagent with TDD enforcement (red-green-refactor) and checkpoints
6. **verification-before-completion** runs 4-level verification at each checkpoint during execution
7. After you run `/workflows:review`, a simplify pass runs 3 agents (code reuse, quality, efficiency) to auto-fix behavior-preserving improvements, then review agents are dynamically selected based on your stack (3-8 agents) and run in parallel, P1s are auto-fixed (up to 3 attempts), and a visual HTML report is generated
8. After you run `/workflows:ship`, a PR is created, Linear is updated, then **compound-learnings** captures durable knowledge to CLAUDE.md and auto-memory, and **best-practices-audit** keeps CLAUDE.md healthy

### Artifacts produced

| Phase | Artifact | Path |
|-------|----------|------|
| Brainstorming | Design document | `docs/designs/<issue-id>-<slug>.md` |
| Planning | Execution plan | `docs/plans/<issue-id>-plan.md` |
| Planning | Visual plan (4+ tasks) | `~/.agent/diagrams/<issue-id>-visual-plan.html` |
| Planning | Plan review | `~/.agent/diagrams/<issue-id>-plan-review.html` |
| Worktree | Isolated branch | `.claude/worktrees/<issue-id>/` |
| Review | Visual report | `~/.agent/diagrams/review-<sanitized-branch>.html` |
| Ship | Pull request | GitHub |
| Ship | CLAUDE.md + memory updates | Project root + auto-memory |

---

## 2. Skill Reference

### Inner Loop Skills (8)

These activate automatically in sequence. None need to be invoked manually.

| Skill | Activates When | Purpose | Produces |
|-------|---------------|---------|----------|
| `brainstorming` | 2+ modules, 4+ tasks, 2+ approaches, or new patterns | Socratic discovery | `docs/designs/<issue-id>-<slug>.md` |
| `writing-plans` | Multi-step task, after brainstorm or complexity skip | Break into 2-5min tasks with TDD | `docs/plans/<issue-id>-plan.md` |
| `git-worktrees` | Plan approved, before coding | Isolated workspace + clean baseline | `.claude/worktrees/` branch |
| `executing-plans` | Plan file exists | Subagent-per-task + TDD + checkpoints | Implemented code + tests |
| `verification-before-completion` | Task checkpoints during execution | 4-level verification (build, tests, acceptance, integration) | Verification report |
| `compound-learnings` | Via `/workflows:ship` after PR | Knowledge capture | CLAUDE.md + memory updates |
| `best-practices-audit` | Via `/workflows:ship` after compound | CLAUDE.md audit + auto-fix | Audit report |
| `systematic-debugging` | Bug investigation (anytime) | 4-phase root cause analysis (reproduce, isolate, analyze, fix) | Fix + regression test |

`systematic-debugging` is the only inner loop skill that can also be triggered manually — all others activate automatically in the chain.

### Design Skills

| Skill | Triggers On | Purpose |
|-------|------------|---------|
| `frontend-design` | "build", "create", "implement" UI components | Write production code (HTML/CSS/JS/React) |
| `ui-ux-pro-max` | "choose palette", "design system", "plan visual direction" | Design planning (50+ styles, 97 palettes, 57 font pairings) |
| `web-design-guidelines` | "review", "audit", "check" existing UI | Compliance review against Web Interface Guidelines |
| `visual-explainer` | "diagram", "architecture overview", complex tables | Generate styled HTML pages |

### Backend & Quality Skills

| Skill | Triggers On | Purpose |
|-------|------------|---------|
| `react-best-practices` | Writing/reviewing React or Next.js code | Performance optimization patterns (from Vercel Engineering) |
| `python-best-practices` | Writing/reviewing FastAPI/Python code | 38 architectural rules across 8 categories |
| `testing-strategy` | Writing/reviewing test code | Patterns for Vitest, RTL, MSW, Playwright, pytest (46 rules) |
| `code-quality` | Setting up linting/formatting | ESLint, Prettier, Ruff, mypy, TypeScript strict mode |

### Utility Skills

| Skill | Triggers On | Purpose |
|-------|------------|---------|
| `find-skills` | "how do I do X", "find a skill for X" | Discover and install agent skills |
| `agent-browser` | Navigate websites, fill forms, take screenshots | Browser automation for web testing |

### Post-Plan Skills

| Skill | Purpose |
|-------|---------|
| `refine-plan` | Refine v1 plans into agent-ready tasks |
| `create-issues` | Create Linear issues from refined plans |
| `setup-claude-md` | Generate best-practices CLAUDE.md |
| `post-plan-setup` | Orchestrate all three above in sequence |

---

## 3. Visual Features

### 3a. Inner Loop Visuals (auto-triggered)

These visuals are generated automatically during the inner loop workflow.

| Phase | Visual | Trigger | Output Path |
|-------|--------|---------|-------------|
| Brainstorming | Architecture diagram | Design involves topology or new patterns | `~/.agent/diagrams/<issue-id>-architecture.html` |
| Writing Plans | Visual plan | 4+ tasks | `~/.agent/diagrams/<issue-id>-visual-plan.html` |
| Writing Plans | Plan review | All plans | `~/.agent/diagrams/<issue-id>-plan-review.html` |
| Review | Review report | Always (Step 6) | `~/.agent/diagrams/review-<sanitized-branch>.html` |
| Ship | Audit report | Optional | `~/.agent/diagrams/audit-<project>.html` |

### 3b. Outer Loop Visuals (`--slides` flag)

These visuals are available from outer loop commands, typically via the `--slides` flag.

| Command | Visual | Trigger | Output Path |
|---------|--------|---------|-------------|
| `/workflows:session-start` | Project recap | User opt-in (Step 1) | `~/.agent/diagrams/<repo>-project-recap.html` |
| `/workflows:sprint-planning` | Sprint slides | `--slides` flag | `~/.agent/diagrams/sprint-cycle-<N>-overview.html` |
| `/workflows:retrospective` | Retro deck | `--slides` flag | `~/.agent/diagrams/retro-cycle-<N>.html` |
| `/workflows:scope` | Mind map | Auto (during scoping) | `~/.agent/diagrams/scope-<project>-mindmap.html` |
| `/workflows:scope` | Summary slides | `--slides` flag | `~/.agent/diagrams/scope-<project>-slides.html` |
| `/workflows:architecture-decision` | Before/after diagrams | Auto (optional) | `~/.agent/diagrams/adr-<slug>-diagrams.html` |

### 3c. Standalone Visual Commands

These commands can be run anytime to generate visual HTML pages.

| Command | Description |
|---------|-------------|
| `/workflows:generate-web-diagram` | Generate a standalone HTML diagram from a topic |
| `/workflows:generate-slides` | Generate a magazine-quality slide deck as HTML |
| `/workflows:generate-visual-plan` | Generate a visual implementation plan with state machines and code snippets |
| `/workflows:fact-check` | Verify a document's claims against the actual codebase |
| `/workflows:diff-review` | Generate a before/after architecture comparison from a git diff |
| `/workflows:plan-review` | Generate a visual comparison of codebase state vs. implementation plan |
| `/workflows:project-recap` | Rebuild mental model of a project's current state and recent decisions |

All visual outputs are self-contained HTML files written to `~/.agent/diagrams/` and opened in the default browser.

---

## 4. Orchestrator Commands

### Inner Loop Commands

#### `/workflows:session-start`

Start a work session. Guides you from issue selection through execution.

| Step | Name | What happens |
|------|------|-------------|
| 0 | Verify Prerequisites | Confirm Linear MCP and sequential-thinking MCP are available |
| 1 | Environment Setup | Git pull, read CLAUDE.md + auto-memory, optional visual project recap |
| 2 | Query Linear | Find in-progress issues first, then backlog; scoped to project in CLAUDE.md |
| 3 | Read Issue Details | Fetch full issue, linked docs, identify relevant code |
| 4 | Brainstorm | Objective complexity check — brainstorm if criteria met, skip if not |
| 5 | Write Plan | Break work into tasks, visual plan approval for 4+ tasks |
| 6 | Set Up Worktree | Isolated branch + dependency install + clean baseline |
| 7 | Execute | Subagent-per-task with TDD and checkpoints |

#### `/workflows:review`

Self-verify work, simplify code, run review agents in parallel, fix P1s, produce a visual report.

**Depth Modes**

Control how many review agents run via `$ARGUMENTS`:

```
/workflows:review fast            # Tier 1 only (3 agents) — quick checks
/workflows:review                 # Tier 1 + Tier 2 (default, 3-6 agents)
/workflows:review comprehensive   # All tiers (3-8 agents) — pre-release
```

| Mode | Agents | When to use |
|------|--------|-------------|
| `fast` | Tier 1 only (code, security, performance) | Quick checks, small changes |
| `thorough` (default) | Tier 1 + Tier 2 (stack-conditional) | Normal reviews |
| `comprehensive` | All tiers including Tier 3 opt-ins | Major features, pre-release |

Depth can be combined with other flags: `/workflows:review fast skip simplify show all`.

| Step | Name | What happens |
|------|------|-------------|
| 0 | Verify Agent Dispatch | Test Task tool with trivial agent before committing to parallel agents |
| 1 | Self-Verification | Check plan steps, run tests, verify build, review own diff |
| 2 | Simplify Pass | 3 agents in parallel (code reuse, quality, efficiency) auto-fix behavior-preserving improvements |
| 3 | Select & Launch Review Agents | Parse depth mode, then dynamic agent selection (Tier 1 always, Tier 2 stack-detected, Tier 3 opt-in), launch in parallel |
| 4 | Collect & Classify | Merge, deduplicate, and confidence-filter findings (>= 7 included, low-confidence P2/P3 filtered, borderline P1s to human review) |
| 5 | Fix Loop | Auto-fix high-confidence P1s (>= 7, max 3 attempts), present borderline P1s for human review |
| 6 | Visual Review Report | Generate 6-section HTML report (summary, KPIs with avg confidence, architecture, findings with confidence pills, file map, tests) |
| 7 | Final Report | Present verdict: ready to ship, needs input on P2s, blocked, or has borderline P1s for review |

**Review Agent Roster**

| Tier | Agent | Activation | Focus |
|------|-------|-----------|-------|
| 1 (always) | `code-reviewer` | Always | Bugs, logic errors, edge cases |
| 1 (always) | `security-reviewer` | Always | OWASP Top 10, secrets, auth |
| 1 (always) | `performance-reviewer` | Always | Complexity, N+1, memory leaks, bundle size |
| 2 (stack) | `typescript-reviewer` | `tsconfig.json` exists | Type safety, React/Next.js patterns |
| 2 (stack) | `python-reviewer` | `pyproject.toml` or `requirements.txt` exists | FastAPI, Pydantic v2, async patterns |
| 2 (stack) | `data-reviewer` | `prisma/schema.prisma`, `alembic/`, or `**/migrations/` exists | Migration safety, query patterns, constraints |
| 3 (opt-in) | `architecture-reviewer` | CLAUDE.md enables OR diff touches 5+ directories | Coupling, SOLID, dependency direction |
| 3 (opt-in) | `accessibility-reviewer` | CLAUDE.md enables (opt-in only) | WCAG 2.1, keyboard nav, ARIA, screen reader |

**CLAUDE.md Review Agent Overrides**

Add a `## Review Agents` section to your project's CLAUDE.md to customize which agents run:

```markdown
## Review Agents

include:
  - accessibility-reviewer
  - architecture-reviewer

exclude:
  - typescript-reviewer
```

`include:` adds agents that wouldn't otherwise activate. `exclude:` removes agents from the selection. Tier 1 agents (code-reviewer, security-reviewer, performance-reviewer) cannot be excluded.

**Confidence Scoring**

Every review agent self-assesses confidence (1-10) on each finding. This reduces false-positive noise from the expanded agent roster.

| Score | Meaning |
|-------|---------|
| 9-10 | Certain — exact code path identified |
| 7-8 | High — strong evidence, minor gaps |
| 5-6 | Medium — pattern-based |
| 3-4 | Low — educated guess |
| 1-2 | Speculative |

Step 4 applies threshold filtering: findings with confidence >= 7 are included in the report. Low-confidence P2/P3s are filtered (count shown in appendix). Borderline P1s (confidence < 7) are kept but marked "Needs Human Review" and excluded from auto-fix. Use "show all" in `$ARGUMENTS` to bypass filtering.

#### `/workflows:ship`

Create PR, update Linear, capture learnings, audit CLAUDE.md, suggest next issue.

| Step | Name | What happens |
|------|------|-------------|
| 0 | Verify GitHub CLI | Confirm `gh` is authenticated and repo is connected |
| 1 | Pre-Ship Checks | Clean state, tests pass, build succeeds, branch up to date |
| 2 | Create Pull Request | Push branch, create PR with structured description |
| 3 | Update Linear | Move issue to "In Review", add comment with PR link |
| 4 | Compound Learnings | Accuracy pass on CLAUDE.md, capture durable knowledge (sanitization enforced in `compound-learnings` skill), write session summary |
| 5 | Best Practices Audit | 8-dimension audit of CLAUDE.md, auto-fix structural issues |
| 6 | Worktree Cleanup | Remove worktree and local branch if applicable |
| 7 | Session Close | Summary of what shipped, learnings captured, suggested next issue |

### Outer Loop Commands

| Command | Description |
|---------|-------------|
| `/workflows:sprint-planning` | Pull backlog, review velocity, assign issues to cycles. Supports `current` mode and `--slides` flag. |
| `/workflows:retrospective` | Review completed cycle, facilitate retro discussion, post status update to Linear. |
| `/workflows:scope` | Collaborative scoping session — discover what to build, create Linear issues, prioritize. |
| `/workflows:architecture-decision` | Generate Architecture Decision Records (ADRs) with structured analysis of alternatives. |

---

## 5. Troubleshooting

### Top 5 Quick Fixes

| Problem | Quick Fix |
|---------|-----------|
| Skills don't trigger | Check plugin is loaded (`/workflows:` in autocomplete). Verify your prompt matches the skill's `description` field. |
| Linear queries return wrong issues | Add a `## Linear Project` section to CLAUDE.md with `Project: <name>`. |
| Visual outputs not generating | Verify visual-explainer skill files exist. Use `--slides` flag for outer loop commands. |
| Hooks not firing | Known upstream bug [#6305](https://github.com/anthropics/claude-code/issues/6305) — PreToolUse/PostToolUse hooks (security blocking, pre-commit quality) don't fire from plugins. SessionStart hooks (environment banner) work. Use `scripts/pre-commit.sh` as a direct git hook in the meantime. |
| Stale behavior after plugin update | Bump `version` in both `plugin.json` and `marketplace.json` to invalidate cache. |

For detailed troubleshooting, see [troubleshooting.md](troubleshooting.md).

---

## 6. Configuration

### Required: `## Linear Project` in CLAUDE.md

The inner loop scopes all Linear queries to a specific project. Add this section to your project's CLAUDE.md:

```markdown
## Linear Project

Project: Your Project Name
```

Without this, `/workflows:session-start` will ask for the project name manually each time.

### Output directory

All visual HTML outputs are written to `~/.agent/diagrams/`. This directory is created automatically on first use. Files are opened in the default browser after generation.

### Diagnostics

Run `/workflows:smoke-test` to check the plugin environment:
- CLI tools (git, node, gh, npx)
- MCP servers (Linear, sequential-thinking)
- Hook registration
- Agent dispatch capability

See [testing-guide.md](testing-guide.md) for the full 66-test validation suite.
