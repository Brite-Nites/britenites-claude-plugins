---
description: Create PR, update Linear, compound learnings, suggest next issue
---

# Ship & Compound (Phase 6)

You are shipping completed work and capturing what was learned. Your job is to create a clean PR, update project management, record learnings, and close the session loop.

## Step 1: Pre-Ship Checks

Before creating a PR:

1. **Verify clean state** — Run `git status`. All changes should be committed. If not, ask the developer what to do.
2. **Verify tests pass** — Run the test suite one final time.
3. **Verify build succeeds** — Run the build command one final time.
4. **Check branch is up to date** — `git fetch origin main && git log main..HEAD --oneline` to confirm your commits.

If any check fails, stop and report the issue.

## Step 2: Create Pull Request

Push the branch and create a PR using the GitHub CLI:

1. **Push branch**: `git push -u origin HEAD`
2. **Create PR** using `gh pr create` with this structure:

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
- [ ] Tests pass (`npm test`)
- [ ] Build succeeds (`npm run build`)
```

3. **Present the PR URL** to the developer.

## Step 3: Update Linear

Use the Linear MCP tools to update the issue:

1. **Move issue status** to "In Review" (or "Done" if the team merges without separate review).
2. **Add a comment** on the issue with the PR link and a brief summary of what was implemented.
3. **Link the PR** if Linear supports it via the API.

If Linear MCP isn't accessible, provide the manual steps to the developer.

## Step 4: Compound Learnings

This is the most important part of the session loop. Capture what was learned so future sessions benefit.

### 4a. Project CLAUDE.md Updates

If the work revealed something that future sessions should know, update the project's CLAUDE.md:

- New architectural patterns established
- New conventions adopted
- Important gotchas discovered
- Key file paths that are frequently referenced

Only add truly durable knowledge. Don't add session-specific noise.

### 4b. Session Summary to Memory

Write a brief session summary to your auto-memory. Include:

- What was built (issue ID, one-line description)
- What was learned (patterns, gotchas, decisions)
- What to do next (follow-up issues, unresolved questions)

Keep it concise — 5-10 lines max.

### 4c. Documentation Updates

If the work changed the project's architecture or public API:

- Update relevant docs in `docs/` if they exist
- Update README if the setup process changed
- Note any doc updates needed that are outside your scope

### 4d. CLAUDE.md Best Practices Check

Run the `britenites:claude-md-generator` agent against the project's CLAUDE.md to ensure it still follows best practices after any learning updates from 4a. Use `plugins/britenites/skills/setup-claude-md/claude-code-best-practices.md` as the reference.

- Auto-fix structural issues (missing sections, stale commands)
- Flag content questions for the developer (e.g., new conventions that need confirmation)
- Skip this step if CLAUDE.md wasn't modified in 4a

## Step 5: Session Close

Present a session summary to the developer:

```
## Session Complete

**Shipped**: [Issue ID] — [Title]
**PR**: [URL]
**Linear**: Updated to [status]

**What was learned**:
- [Key learning 1]
- [Key learning 2]

**Docs updated**: [list, or "none needed"]

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
