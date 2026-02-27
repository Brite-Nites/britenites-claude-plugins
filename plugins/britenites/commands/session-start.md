---
description: Start a work session — pull latest, pick a Linear issue, brainstorm, plan, execute
---

# Session Start

You are beginning a focused work session. Your job is to orient the developer, pick the next issue, and guide them through the inner loop: brainstorm → plan → worktree → execute.

## Step 0: Verify Prerequisites

Before starting, confirm critical dependencies:

1. **Linear MCP** — Call the Linear MCP to list projects (just 1 result). Confirms auth and connectivity.
2. **Sequential-thinking MCP** — Send a trivial thought (e.g., "Planning session start"). Confirms the MCP server is running.

If either fails:
- Stop with: "Cannot reach [Linear/sequential-thinking]. Run `/britenites:smoke-test` to diagnose."
- Do NOT proceed.

## Step 1: Environment Setup

1. **Check git status** — Ensure working directory is clean. If dirty, warn and ask how to proceed.
2. **Pull latest** — `git pull origin main` (or the default branch).
3. **Read project CLAUDE.md** — Load architecture context, conventions, previous learnings.
4. **Read auto-memory** — Check for session summaries and follow-ups from previous sessions.

## Step 2: Query Linear for Open Issues

Use the Linear MCP tools to find actionable work:

1. **List open issues** assigned to the current user or unassigned in the active project.
2. **Sort by priority** — Urgent/High first, then by cycle.
3. **Present the top 5** in a table:

```
| # | ID    | Title                        | Priority | Labels      |
|---|-------|------------------------------|----------|-------------|
| 1 | BN-42 | Add auth endpoint            | Urgent   | backend     |
| 2 | BN-38 | Fix dashboard loading state  | High     | frontend    |
| ...
```

4. **Suggest which to pick** based on priority, dependencies, and any follow-ups from auto-memory.
5. **Ask the user** which issue to work on using AskUserQuestion.

If `$ARGUMENTS` contains an issue ID or URL, skip the table and go directly to that issue.

## Step 3: Read Issue Details

Once an issue is selected:

1. **Fetch full issue details** — description, acceptance criteria, labels, linked issues, comments.
2. **Read linked docs** referenced in the issue (PRDs, design specs, etc.).
3. **Identify related code** — Find relevant files from the issue description and labels. Read them.

## Step 4: Brainstorm (Non-Trivial Issues)

**Assess complexity**: Is this issue non-trivial? (Multi-step feature, architectural change, ambiguous requirements, multiple valid approaches)

- **If non-trivial**: The `brainstorming` skill activates. Engage in Socratic discovery — ask clarifying questions, explore alternatives, produce a design document for approval.
- **If trivial** (simple bug fix, config change, single-file edit): Skip brainstorming and proceed to planning.

Ask the developer if unsure: "This looks straightforward — should we brainstorm approaches or jump to planning?"

## Step 5: Write Plan

The `writing-plans` skill activates to create a detailed execution plan:

1. Break the work into bite-sized tasks (2-5 minutes each)
2. Each task has exact file paths, implementation details, verification steps
3. Plan is saved to `docs/plans/[issue-id]-plan.md`
4. Plan references the project's actual test/build/lint commands from CLAUDE.md

**Present the plan** and ask for approval: "Does this plan look right? Any tasks to add, remove, or reorder?"

## Step 6: Set Up Worktree

After the plan is approved, the `git-worktrees` skill activates:

1. Create an isolated worktree with branch `[issue-id]/[short-description]`
2. Install dependencies
3. Verify clean test/build/lint baseline

If the developer prefers not to use worktrees, fall back to a simple branch: `git checkout -b [issue-id]/[short-description]`

## Step 7: Execute

The `executing-plans` skill activates:

1. Execute each task via subagent-per-task (fresh context per task)
2. TDD enforcement: red → green → refactor per task
3. Checkpoint after each task — `verification-before-completion` activates at each checkpoint (build, tests, acceptance criteria, integration)
4. Parallelize independent tasks

State clearly: "Plan approved. Starting execution. I'll checkpoint after each task and let you know when ready for review."

## Rules

- Never start writing code before the plan is approved.
- If an issue is vague, brainstorm first — don't guess.
- If the codebase doesn't have a CLAUDE.md, note it and proceed with what you can infer.
- If the plan exceeds 12 tasks, suggest splitting the issue into multiple PRs.
- If Linear isn't accessible, ask the user to provide issue details manually.
- The inner loop is: brainstorm → plan → worktree → execute → review → ship. Each step hands off to the next.
- Skills activate automatically in sequence — the developer only needs to run `session-start`, then `review`, then `ship`.
