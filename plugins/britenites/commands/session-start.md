---
description: Start a work session — pull latest, pick a Linear issue, create an execution plan
---

# Session Start (Phase 3)

You are beginning a focused work session. Your job is to get the developer oriented, pick the next issue to work on, and produce an execution plan they approve before any code is written.

## Step 0: Verify Prerequisites

Before starting the session, confirm critical dependencies are reachable:

1. **Linear MCP** — Call the Linear MCP to list projects (just 1 result). This confirms auth and connectivity.
2. **Sequential-thinking MCP** — Send a trivial thought (e.g., "Planning session start"). This confirms the MCP server is running.

If either fails:
- Stop immediately with a clear error: "Cannot reach [Linear/sequential-thinking]. Run `/britenites:smoke-test` to diagnose."
- Do NOT proceed to environment setup or issue querying.

If both succeed, continue to Step 1.

## Step 1: Environment Setup

1. **Check git status** — Ensure working directory is clean. If there are uncommitted changes, warn the user and ask how to proceed.
2. **Pull latest from main** — Run `git pull origin main` (or the project's default branch).
3. **Create a working branch** — After the user picks an issue (Step 3), create a branch: `git checkout -b <issue-id>/<short-description>` (e.g., `BN-42/add-auth-endpoint`).

## Step 2: Query Linear for Open Issues

Use the Linear MCP tools to find actionable work:

1. **List open issues** assigned to the current user or unassigned in the active project.
2. **Sort by priority** — P0/P1 first, then by cycle if applicable.
3. **Present the top 5** issues in a concise table:

```
| # | ID    | Title                        | Priority | Labels      |
|---|-------|------------------------------|----------|-------------|
| 1 | BN-42 | Add auth endpoint            | Urgent   | backend     |
| 2 | BN-38 | Fix dashboard loading state  | High     | frontend    |
| ...
```

4. **Suggest which to pick** based on priority and dependencies (e.g., "BN-42 is urgent and has no blockers — I'd start there").
5. **Ask the user** which issue to work on using the AskUserQuestion tool.

If `$ARGUMENTS` already contains an issue ID or URL, skip the table and go directly to that issue.

## Step 3: Read Issue Details

Once an issue is selected:

1. **Fetch full issue details** from Linear — description, acceptance criteria, labels, linked issues, comments.
2. **Read project CLAUDE.md** for architectural context, coding conventions, and patterns.
3. **Read any linked docs** referenced in the issue (PRD, design specs, etc.).
4. **Identify related code** — Use the issue description and labels to find relevant files in the codebase. Read them.

## Step 4: Create Execution Plan

Use the sequential-thinking MCP to work through the plan:

1. **Decompose the issue** into concrete implementation steps. Each step should be:
   - Specific (which file, which function, what change)
   - Ordered (dependencies explicit)
   - Testable (how to verify it works)

2. **Identify risks** — What could go wrong? What assumptions are you making? What needs clarification?

3. **Present the plan** to the user:

```
## Execution Plan: [Issue Title]

**Issue**: [ID] — [Title]
**Branch**: [branch-name]
**Estimated steps**: N

### Steps
1. [Specific change] — [file(s)] — [verification]
2. [Specific change] — [file(s)] — [verification]
...

### Risks & Assumptions
- [Risk or assumption that needs confirmation]

### Out of Scope
- [Anything explicitly excluded]
```

4. **Ask for approval** using AskUserQuestion: "Does this plan look right? Any changes before I start executing?"

## Step 5: Handoff to Execution

Once the plan is approved:

1. Confirm the working branch is created and checked out.
2. State clearly: "Plan approved. Starting execution. I'll work through the steps and let you know when ready for review."
3. Begin executing the plan steps sequentially.

## Rules

- Never start writing code before the user approves the plan.
- If an issue is vague, ask clarifying questions before planning — don't guess.
- If the codebase doesn't have a CLAUDE.md, note it and proceed with what you can infer.
- Keep the plan concise. 3-8 steps is typical. If it's more than 12, suggest splitting the issue.
- If Linear isn't accessible (MCP error), ask the user to provide the issue details manually.
