---
name: git-worktrees
description: Creates an isolated git worktree for task execution. Activates when starting work on a planned issue — sets up a new branch with Linear issue ID, runs project setup, and verifies a clean test baseline before coding begins.
user-invocable: false
---

# Git Worktrees

You are setting up an isolated workspace for a development task. Worktrees prevent work-in-progress from polluting the main working directory and enable easy cleanup or abandonment.

## When to Activate

- After a plan is approved and before execution begins
- When the developer wants to work on a task in isolation
- NOT needed for single-file changes or documentation-only updates

## Setup Process

### Step 1: Verify Prerequisites

```
1. Confirm git repo: `git rev-parse --is-inside-work-tree`
2. Confirm clean state: `git status --porcelain` (should be empty)
3. Fetch latest: `git fetch origin`
4. Identify base branch: usually `main` or `master`
```

If working directory is dirty, ask the developer how to proceed (stash, commit, or abort).

### Step 2: Create Branch & Worktree

Use the EnterWorktree tool to create an isolated worktree. Name it after the Linear issue:

**Branch naming convention**: `[issue-id]/[short-description]`
- Example: `BRI-1617/writing-plans-skill`
- Example: `BRI-42/fix-auth-redirect`

**Validate the issue ID** before using it in shell commands — it must match `^[A-Z]+-[0-9]+$`. Reject any ID containing spaces, semicolons, pipes, or other shell metacharacters.

If the EnterWorktree tool is not available, fall back to manual git commands (always quote variables).

Derive `DESCRIPTION` from the issue title: lowercase, replace non-alphanumeric characters with hyphens, collapse consecutive hyphens, strip leading/trailing hyphens, truncate to 50 chars. Validate it matches `^[a-z0-9][a-z0-9-]*[a-z0-9]$` (or `^[a-z0-9]$` for single-char). If validation fails, ask the developer for a safe branch description.

```bash
# ISSUE_ID = Linear issue ID (e.g. BRI-42)
# DESCRIPTION = slugified short summary (e.g. fix-auth-redirect)
git worktree add ".claude/worktrees/${ISSUE_ID}" -b "${ISSUE_ID}/${DESCRIPTION}" origin/main
```

### Step 3: Project Setup

In the new worktree, run project setup:

1. **Install dependencies** — Check for and run:
   - `package.json` → `npm install` or `yarn install` or `pnpm install`
   - `pyproject.toml` → `pip install -e .` or `poetry install`
   - `Gemfile` → `bundle install`
   - If no dependency file found, skip

2. **Environment setup** — Check for:
   - `.env.example` → Copy to `.env` if `.env` doesn't exist, warn developer to fill in values
   - Other config files that need local copies

### Step 4: Verify Clean Baseline

Before any changes are made, verify the project is in a known-good state:

1. **Run tests**: Execute the project's test command (from CLAUDE.md or `package.json`)
2. **Run build**: Execute the build command
3. **Run lint**: Execute the lint command

Record the baseline results. If tests fail before you've changed anything, flag it:

> "Baseline tests are failing on main. [N] test(s) fail. Proceeding, but these failures are pre-existing — not caused by our changes."

### Step 5: Confirm Ready

Report to the developer:

```
## Worktree Ready

**Branch**: [branch-name]
**Path**: [worktree-path]
**Base**: origin/main @ [commit-hash]

**Baseline**:
- Tests: [pass/fail count]
- Build: [clean/errors]
- Lint: [clean/warnings]

Ready to execute the plan.
```

## Cleanup

Worktree cleanup happens during the `ship` command:

- **If shipping**: Worktree is cleaned up after PR is created
- **If abandoning**: `git worktree remove [path]` and `git branch -D [branch-name]`
- **If pausing**: Worktree persists for the next session

## Rules

- Always base worktrees on the latest `origin/main` (or default branch)
- Never reuse a worktree from a previous issue — always start fresh
- If baseline tests fail, document it but don't block — the developer may know about it
- Branch names must include the Linear issue ID for traceability
- Keep worktrees in `.claude/worktrees/` to avoid cluttering the project root
