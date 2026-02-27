---
description: Create PR, update Linear, compound learnings, best-practices audit, suggest next issue
---

# Ship & Compound

You are shipping completed work and capturing what was learned. Your job is to create a clean PR, update Linear, run the compound + audit cycle, clean up, and close the session.

## Step 0: Verify GitHub CLI

Before creating a PR, confirm `gh` is available and authenticated:

1. **Run `gh auth status`** — Must succeed. If not: "GitHub CLI not authenticated. Run `gh auth login` first."
2. **Run `gh repo view --json name`** — Must succeed. If not: "Not in a GitHub-connected repository. Ensure a remote is configured."

## Step 1: Pre-Ship Checks

Before creating a PR:

1. **Verify clean state** — `git status`. All changes committed. If not, ask the developer.
2. **Verify tests pass** — Run the test suite one final time.
3. **Verify build succeeds** — Run the build command one final time.
4. **Check branch is up to date** — `git fetch origin main && git log main..HEAD --oneline` to confirm commits.

If any check fails, stop and report.

## Step 2: Create Pull Request

Push the branch and create a PR:

1. **Push branch**: `git push -u origin HEAD`
2. **Create PR** using `gh pr create`:

```
Title: [concise imperative description, under 70 chars]

## Summary
- [What was built/fixed and why]
- [Key implementation decisions]

## Changes
- [File-level summary of what changed]

## Linear Issue
[Link to Linear issue: LIN-XXX]

## Test Plan
- [ ] [How to verify this works]
- [ ] [Edge cases to check]
- [ ] Tests pass
- [ ] Build succeeds
```

3. **Present the PR URL** to the developer.

## Step 3: Update Linear

Use the Linear MCP tools:

1. **Move issue status** to "In Review" (or "Done" if team merges without separate review).
2. **Add a comment** on the issue with PR link and summary of what was implemented.
3. **Link the PR** via attachment if possible.

If Linear MCP isn't accessible, provide manual steps.

## Step 4: Compound Learnings

The `compound-learnings` skill activates to capture what was learned:

1. **CLAUDE.md updates** — Add durable learnings (new patterns, conventions, gotchas). Prune stale entries.
2. **Session summary to memory** — What was built, what was learned, what's next.
3. **Documentation updates** — Update `docs/` if architecture or API changed.

Only durable knowledge gets recorded. No session-specific noise.

## Step 5: Best Practices Audit

The `best-practices-audit` skill activates to keep CLAUDE.md healthy:

1. **Size check** — Is CLAUDE.md under ~100 lines? Extract to `docs/` with `@import` if needed.
2. **Section structure** — Required sections present (Build & Test, Conventions, Architecture, Gotchas)?
3. **Auto-exclude** — Flag generic advice, stale references, bloat.
4. **Command accuracy** — Do listed commands match `package.json` scripts?
5. **Hook candidates** — Are there advisory rules that should be deterministic hooks?
6. **Auto-fix** structural issues, flag content questions for the developer.

Skip this step if CLAUDE.md wasn't modified in Step 4.

## Step 6: Worktree Cleanup

If working in a git worktree:

1. Verify all changes are committed and pushed
2. Switch back to the main working directory: `cd` to the original repo root (outside `.claude/worktrees/`)
3. Remove the worktree: `git worktree remove .claude/worktrees/[ISSUE_ID]`
4. Optionally delete the local branch: `git branch -D [branch-name]`

If not in a worktree, skip this step.

## Step 7: Session Close

Present a session summary:

```
## Session Complete

**Shipped**: [Issue ID] — [Title]
**PR**: [URL]
**Linear**: Updated to [status]

**Learnings captured**:
- CLAUDE.md: [N] entries added/updated/pruned
- Memory: Session summary written
- Docs: [list, or "none needed"]

**Audit**: [clean / N issues auto-fixed / N items need your input]

**Suggested next issue**: [Issue ID] — [Title] — [Why this one next]
```

Query Linear for the next highest-priority open issue and suggest it.

## Rules

- Never push without confirming tests and build pass.
- Never mark a Linear issue as Done if the PR hasn't been created.
- Keep PR descriptions factual — what changed and why, not marketing copy.
- Learnings should be durable facts, not opinions or preferences.
- The session summary in memory should be self-contained — a future session should understand it without context.
- Always suggest a next issue to maintain momentum, but don't start it — the next session is a fresh context.
- The inner loop ends here: session-start → (brainstorm → plan → worktree → execute) → review → **ship**.
