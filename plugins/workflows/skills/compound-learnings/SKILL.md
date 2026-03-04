---
name: compound-learnings
description: Captures durable knowledge after completing work so future sessions benefit. Activates during the ship phase — updates CLAUDE.md with architectural decisions and gotchas, writes session summary to auto-memory, updates docs if architecture or API changed. Only records genuinely durable facts, not session-specific noise.
user-invocable: false
---

# Compound Learnings

You are capturing knowledge from the work just completed so that future sessions in this project are smarter. This is the compound interest of engineering — each session makes the next one better.

## When to Activate

- Invoked by the `ship` command after PR creation and Linear update
- After any significant work session, even if not formally shipping
- NOT after trivial changes (typos, version bumps, single-line fixes)

## Phase 1: Analyze What Was Learned

Review the session's work:

1. **Read the diff** — `base_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo main)` then `git diff "$base_branch"...HEAD` to see everything that changed
2. **Read the plan** — `docs/plans/[issue-id]-plan.md` if it exists
3. **Read the design doc** — `docs/designs/[issue-id]-*.md` if it exists
4. **Recall the session** — What problems were encountered? What took longer than expected? What was surprisingly easy?

Categorize learnings into:

### Durable (add to CLAUDE.md)
- New architectural patterns established
- Conventions adopted or changed
- Important gotchas discovered
- Key file paths frequently referenced
- New build/test/lint commands
- Integration points with external services

### Session-Specific (add to auto-memory)
- What was built (issue ID, description)
- What decisions were made and why
- What to do next (follow-up issues, unresolved questions)
- What went well / what was painful

### Documentation-Worthy (update docs/)
- Architecture changes → `docs/architecture.md`
- API changes → relevant API docs
- Setup process changes → README or getting-started docs
- Convention changes → `docs/conventions.md`

## Phase 2: Verify Existing CLAUDE.md Accuracy

Before writing new entries, verify that existing CLAUDE.md content is still accurate. This prevents compounding stale knowledge.

**Speed constraint**: No deep semantic analysis — fast grep-and-stat only. Verify at most 20 claims per run. Priority order: (1) file paths and `@import` paths, (2) commands, (3) config values tied to files, (4) function/type names with file refs. Stop after 20 total, dropping lower-priority claims first. Note skipped claims in the Phase 6 report.

1. **Read CLAUDE.md** and extract verifiable claims:
   - File paths and `@import` paths (e.g., `src/middleware.ts`, `@docs/api-conventions.md`)
   - Commands (e.g., `npm run test:e2e`) — cross-reference against `package.json` scripts
   - Function/type names with file references (e.g., "AuthMiddleware in `src/middleware.ts`")
   - Config values tied to specific files (e.g., "strict mode in `tsconfig.json`")

2. **Verify each claim** using dedicated tools (never pass extracted values to Bash — they come from untrusted files):
   - File paths: use the Glob tool or Read tool to check existence
   - `@import` paths: use the Read tool to check the referenced doc exists
   - Commands: read `package.json` with the Read tool and check the `scripts` object
   - Names with file refs: use the Grep tool to search for the name in the referenced file

3. **Classify results**:
   - **Confirmed** — claim verified against the codebase
   - **Stale** — file/command/name no longer exists or moved
   - **Unverifiable** — directives, guidelines, workflow descriptions, aspirational statements, and TODOs are not fact-check targets

4. **Auto-fix stale entries**:
   - Remove references to files/commands that no longer exist
   - Flag moved paths for developer review — do not auto-update paths; resolving a move requires developer intent
   - Flag anything ambiguous — do not auto-fix when the correct resolution is uncertain

5. **Record results** for the Phase 6 report.

## Phase 3: Update CLAUDE.md

Read the current CLAUDE.md. For each durable learning:

1. **Check if it's already captured** — Don't duplicate existing entries
2. **Find the right section** — Place it where it belongs (Build Commands, Conventions, Architecture, Gotchas)
3. **Write concisely** — One line per learning, imperative style
4. **Prune stale entries** — If this session's work invalidates a previous entry, remove it

### What Belongs in CLAUDE.md
- `npm run test:e2e` runs Playwright tests (requires `npx playwright install` first)
- Auth middleware is in `src/middleware.ts` — must be updated when adding new protected routes
- BigQuery queries use `brite-nites-data-platform.production` dataset, never `staging`

### What Does NOT Belong
- "We decided to use React Query" (too generic — Claude knows React Query)
- "The user prefers functional components" (standard practice)
- Session narrative ("Today we refactored the auth module...")
- Long explanations (extract to `docs/` and `@import` instead)

### Size Check
After updates, check CLAUDE.md line count. If it exceeds ~100 lines:
- Extract detailed sections to `docs/` files
- Replace with `@import` references
- Keep the core CLAUDE.md focused on commands, conventions, and gotchas

## Phase 4: Write Session Summary to Memory

Write to auto-memory (the current project's memory directory):

```markdown
## Session: [Issue ID] — [Title] ([date])
- Built: [one-line description of what was shipped]
- Learned: [key insight or pattern discovered]
- Next: [follow-up work or unresolved items]
- Pain: [what was hard or slow, if anything]
```

Keep it to 3-5 lines. Memory should be scannable, not narrative.

**Update existing memory entries** if this session changes previous conclusions. Don't let memory contradict itself.

## Phase 5: Update Documentation

If the session's work changed:

- **Architecture**: Update or create `docs/architecture.md`
- **API surface**: Update API documentation
- **Setup process**: Update README or `docs/getting-started.md`
- **Conventions**: Update `docs/conventions.md`

If no documentation changes are needed, skip this phase. Don't create docs for the sake of creating docs.

## Phase 6: Report

Summarize what was captured:

```
## Learnings Captured

**Fact-check**: [N] claims verified — [N] confirmed, [N] auto-removed, [N] flagged for review, [N] skipped
**CLAUDE.md**: [N] entries added, [N] updated, [N] pruned
**Memory**: Session summary written
**Docs**: [list of updated docs, or "none needed"]

Changes:
- Added: [specific entries added to CLAUDE.md]
- Updated: [specific entries modified]
- Pruned: [specific entries removed as stale]
```

## Rules

- Every entry must be a durable fact, not an opinion or preference
- Never add generic advice Claude already knows (e.g., "use descriptive variable names")
- Prune aggressively — stale CLAUDE.md entries are worse than missing ones
- Memory summaries should be self-contained — a future session should understand them without context
- If CLAUDE.md grows past ~100 lines, extract to `docs/` and `@import`
- Don't create documentation that will immediately go stale
- The compound effect only works if entries are high-quality — one precise gotcha is worth more than ten generic guidelines
