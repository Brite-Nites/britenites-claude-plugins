# Comprehensive Testing Guide

Complete testing reference for the Britenites Claude Code plugin. Covers automated validation, interactive skill/command testing, end-to-end flows, hooks, and agent dispatch.

Use this guide when working on the plugin itself or when verifying behavior after changes.

## Prerequisites

- Fresh terminal (not inside Claude)
- Plugin installed or loaded via `--plugin-dir`
- A test Linear project with at least 1 open issue
- GitHub CLI authenticated (`gh auth status`)
- A test project directory for commands that write files (e.g., `/tmp/test-project`)

## Quick Smoke Subset (~10 min)

For fast validation after changes, run only these:

1. T0.1 + T0.2 — automated scripts pass
2. T1.1 + T1.2 — plugin loads, SessionStart fires
3. T1.3 — smoke-test command
4. T2.1 + T2.7 + T2.9 — one skill from each category triggers
5. T3.1 — tech-stack renders
6. T3.6 — code-review quick mode on a diff

---

## Layer 0: Automated Validation (~2 min)

Run these outside Claude, from a regular terminal or CI.

| Test | Command | Expected |
|------|---------|----------|
| T0.1 Structural validation | `bash scripts/validate.sh` | 0 errors (3 warnings for orphan agents are expected) |
| T0.2 Hook regex tests | `bash scripts/test-hooks.sh` | 37/37 pass |
| T0.3 Prerequisites check | `bash scripts/check-prereqs.sh` | All PASS (or explained SKIPs) |
| T0.4 Command registration | `bash scripts/test-plugin-load.sh` | All 14 commands found |
| T0.5 CI workflow | Push to branch, check GitHub Actions | All steps green |

---

## Layer 1: Plugin Loading & Environment (~3 min)

| Test | Steps | Expected |
|------|-------|----------|
| T1.1 Plugin loads | Start `claude --plugin-dir ./plugins/britenites`, type `/britenites:` | 14 commands in autocomplete: `bug-report`, `code-review`, `deployment-checklist`, `onboarding-checklist`, `project-start`, `review`, `scope`, `security-audit`, `session-start`, `setup-claude-md`, `ship`, `smoke-test`, `sprint-planning`, `tech-stack` |
| T1.2 SessionStart hook | Observe session start output | Environment banner with git/node/gh/npx status + key commands listed |
| T1.3 Smoke test | Run `/britenites:smoke-test` | Summary table with PASS/FAIL/SKIP/KNOWN ISSUE for 8 checks (env, MCP, hooks, agents) |

---

## Layer 2: Skill Trigger Tests (~10 min)

Test that saying specific phrases activates the correct skill. Verify by observing which skill name appears in the response context.

### Inner Loop Skills

| Test | Say this | Expected skill |
|------|----------|----------------|
| T2.1 | "I need to plan a new feature for user onboarding" | `brainstorming` |
| T2.2 | "I have a bug that's hard to reproduce" | `systematic-debugging` |
| T2.3 | (after brainstorming) Plan is presented | `writing-plans` |
| T2.4 | (after plan approval) Worktree setup begins | `git-worktrees` |
| T2.5 | (after worktree) Execution begins | `executing-plans` |
| T2.6 | (during execution) Checkpoint verification | `verification-before-completion` |

Note: T2.3–T2.6 are sequential — they trigger as part of the inner loop flow and are also tested in Layer 4 (T4.1).

### Design Skills

| Test | Say this | Expected skill |
|------|----------|----------------|
| T2.7 | "Build a login form with email and password" | `frontend-design` |
| T2.8 | "Choose a color palette for a SaaS dashboard" | `ui-ux-pro-max` |
| T2.9 | "Review my UI for accessibility issues" | `web-design-guidelines` |

### Quality / Reference Skills

| Test | Say this | Expected skill |
|------|----------|----------------|
| T2.10 | "Review this React component for performance" | `react-best-practices` |
| T2.11 | "Set up ESLint and Prettier for this project" | `code-quality` |
| T2.12 | "Find a skill for database migrations" | `find-skills` |

---

## Layer 3: Individual Command Tests (~20 min)

### Safe / Read-Only

| Test | Command | Steps | Expected |
|------|---------|-------|----------|
| T3.1 | `/britenites:tech-stack` | Run it | Technology stack tables displayed (no external deps) |
| T3.2 | `/britenites:onboarding-checklist` | Run, answer first 2 prompts, then abort | Interactive checklist with `[x]` tracking |

### Requires Linear MCP

| Test | Command | Steps | Expected |
|------|---------|-------|----------|
| T3.3 | `/britenites:session-start` | Run → Step 0 passes → issue table shows → select issue → plan generated | Abort after plan is presented (before worktree/execution). Verify: MCP check passes, issues load, plan has tasks with file paths |
| T3.4 | `/britenites:scope` | Run → Step 0 passes → answer 2-3 interview questions → themes presented | Abort after themes. Verify: MCP check passes, Socratic questions asked via AskUserQuestion, themes use sequential-thinking |
| T3.5 | `/britenites:bug-report` | Run with a test bug title → fill in details → approve draft | Verify: Linear issue created with Bug label, structured description, environment table. **Cleanup:** delete the test issue in Linear |

### Requires Changes on a Branch

| Test | Command | Setup | Steps | Expected |
|------|---------|-------|-------|----------|
| T3.6 | `/britenites:code-review` | Make a small code change | Run without args | Quick review with P1/P2/P3 findings on current diff |
| T3.7 | `/britenites:code-review --deep` | Same branch | Run with `--deep` | 3 review agents dispatched in parallel, merged report |
| T3.8 | `/britenites:review` | Same branch | Run → Step 0 agent dispatch check → self-verify → 3 agents → report | Full review report with verdict |
| T3.9 | `/britenites:security-audit` | Any project | Run | Automated checks (deps, secrets, env) + agent review + health grade (A–F) |
| T3.10 | `/britenites:security-audit --quick` | Any project | Run with `--quick` | Automated checks only (no agent dispatch), faster |

### Requires gh CLI + Committed Changes

| Test | Command | Setup | Steps | Expected |
|------|---------|-------|-------|----------|
| T3.11 | `/britenites:ship` | Committed changes on a branch | Run → gh auth check → pre-ship checks → PR created → Linear updated → compound learnings → session summary | PR URL returned, Linear issue moved to "In Review". **Cleanup:** delete test PR |
| T3.12 | `/britenites:deployment-checklist` | Any project with package.json | Run | Deployment Confidence Report table with READY/CAUTION/BLOCKED |

### Creates Files (use temp directory)

| Test | Command | Setup | Steps | Expected |
|------|---------|-------|-------|----------|
| T3.13 | `/britenites:project-start` | `mkdir /tmp/test-project && cd /tmp/test-project` | Run → select "Technical collaborator" → answer 2-3 questions | Abort before file creation. Verify: interview follows Path B |
| T3.14 | `/britenites:setup-claude-md` | Any project | Run | CLAUDE.md generated/updated with required sections. Agent dispatched |

---

## Layer 4: End-to-End Flow Tests (~30+ min each)

### T4.1: Inner Loop (full cycle)

**Prerequisites:** Linear project with an open issue, gh authenticated, test repo

1. `/britenites:session-start` → select an issue
2. Observe `brainstorming` activates (if non-trivial) → approve design doc
3. Observe `writing-plans` activates → review plan with tasks → approve
4. Observe `git-worktrees` activates → worktree created with issue ID branch
5. Observe `executing-plans` activates → subagents dispatched per task → TDD enforced
6. Observe `verification-before-completion` runs at checkpoints
7. `/britenites:review` → 3 agents run → P1s fixed → verdict
8. `/britenites:ship` → PR created → Linear updated → `compound-learnings` runs → `best-practices-audit` runs (if CLAUDE.md changed) → session summary

**Cleanup:** Delete test PR, remove worktree, clean up generated files.

### T4.2: Greenfield Flow

**Prerequisites:** Empty directory, Linear MCP

1. `/britenites:project-start` → complete full interview
2. Verify: CLAUDE.md created, `docs/project-plan-v1.md` created, Linear project created
3. `/britenites:post-plan-setup` → refine-plan runs → approve → create-issues runs → approve → setup-claude-md runs → approve
4. Verify: `docs/project-plan-refined.md` exists, Linear issues created with dependencies, CLAUDE.md updated

**Cleanup:** Delete test Linear project and issues.

### T4.3: Scoping Flow

**Prerequisites:** Linear project with existing issues

1. `/britenites:scope` → answer interview questions → themes generated → select items → issues created → prioritization table
2. Verify: Linear issues created with acceptance criteria, relationships set, deferred ideas in memory

**Cleanup:** Delete test issues.

### T4.4: Standalone Debugging

**Prerequisites:** A project with a reproducible bug (or simulate one)

1. Say "I have a bug: [description]"
2. Observe `systematic-debugging` activates
3. Walk through: Phase 1 (reproduce) → Phase 2 (isolate) → Phase 3 (analyze) → Phase 4 (fix)
4. Verify: Regression test written, debugging report generated

---

## Layer 5: Hook Tests (~5 min)

**Note:** PreToolUse/PostToolUse hooks don't fire from plugins due to upstream bug ([#6305](https://github.com/anthropics/claude-code/issues/6305)). These tests verify the hook *definitions* are correct and will work once the bug is fixed. SessionStart is the only hook that fires today.

| Test | Hook | Steps | Expected |
|------|------|-------|----------|
| T5.1 | SessionStart | Start a new session | Environment banner displayed with git/node/gh/npx status |
| T5.2 | Bash security (automated) | Already covered by `scripts/test-hooks.sh` | 37/37 pass |
| T5.3 | Write/Edit security (manual) | Try to write a file containing `sk-proj-AAAAAAAAAAAAAAAAAAA` | Should be blocked (if hooks fire — KNOWN ISSUE if not) |
| T5.4 | PostToolUse linter (manual) | Edit a `.ts` file with a lint error | Auto-linter should run (if hooks fire — KNOWN ISSUE if not) |

---

## Layer 6: Agent Dispatch Tests (~10 min)

| Test | Agent | How to trigger | Expected output |
|------|-------|----------------|-----------------|
| T6.1 | `code-reviewer` | `/britenites:review` or `/britenites:code-review --deep` | P1/P2/P3 findings with file:line references |
| T6.2 | `security-reviewer` | `/britenites:review` or `/britenites:security-audit` | Security findings with Attack/Impact/Fix + Risk Level |
| T6.3 | `typescript-reviewer` | `/britenites:review` | TypeScript/React/Next.js findings |
| T6.4 | `claude-md-generator` | `/britenites:setup-claude-md` | CLAUDE.md generated with required sections |
| T6.5 | `plan-refiner` | `/britenites:post-plan-setup` Phase 1 | Refined plan with agent-ready tasks |
| T6.6 | `issue-creator` | `/britenites:post-plan-setup` Phase 2 | Linear issues created with structured descriptions |
| T6.7 | `post-plan-orchestrator` | `/britenites:post-plan-setup` | Orchestrates phases 1–3 with review gates |

---

## Coverage Summary

| Component | Count | Covered by |
|-----------|-------|------------|
| Commands | 14 | T1.1, T3.1–T3.14 |
| Skills (Inner Loop) | 8 | T2.1–T2.6, T4.1 |
| Skills (Design) | 3 | T2.7–T2.9 |
| Skills (Quality/Ref) | 3 | T2.10–T2.12 |
| Skills (Post-plan) | 4 | T4.2 (refine-plan, create-issues, setup-claude-md, post-plan-setup) |
| Skills (Browser) | 1 | Not directly tested (requires browser MCP) |
| Agents | 7 | T6.1–T6.7 |
| Hooks | 4 types | T5.1–T5.4, T0.2 |
| Scripts | 4 | T0.1–T0.4 |

---

## Results Template

```
Date:       ____-__-__
Version:    ____
Tester:     ____
Environment: macOS / Linux / WSL

Layer 0 (Automated):  __/5
Layer 1 (Loading):    __/3
Layer 2 (Skills):     __/12
Layer 3 (Commands):   __/14
Layer 4 (E2E):        __/4
Layer 5 (Hooks):      __/4
Layer 6 (Agents):     __/7

Total:  __/49
Notes:  ____
```
