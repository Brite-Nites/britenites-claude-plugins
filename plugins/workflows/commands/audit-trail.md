---
description: Query the full context picture for any issue — what context was used, staleness status, and frequency analysis
---

# Audit Trail

You are reconstructing the full context audit for a specific issue. This answers: "What context did the agent use to make decisions on this issue?" — critical for compliance, debugging, and improvement.

**Input:** `$ARGUMENTS` should contain an issue ID (e.g., `BC-1234`). If empty, ask the user.

## Phase 0: Prerequisites

Narrate: `Phase 0/5: Checking prerequisites...`

1. **Validate issue ID**: Extract the issue ID from `$ARGUMENTS`. It must match `^[A-Z]+-[0-9]+$`. If `$ARGUMENTS` is empty, use AskUserQuestion: "Which issue would you like to audit?" If the ID doesn't match the pattern, stop with: "Invalid issue ID format. Expected pattern: BC-1234"
2. **Precedent directory exists**: Check that `docs/precedents/` exists using Glob for `docs/precedents/*.md`. If the directory is empty or missing, stop with: "No precedent data found. Decision traces are created during `/workflows:ship`."

Print the activation banner:

```
---
**Audit Trail** activated
Issue: <ISSUE-ID>
Produces: Context audit report with staleness and frequency analysis
---
```

Narrate: `Phase 0/5: Checking prerequisites... done`

## Phase 1: Gather Trace Data

Narrate: `Phase 1/5: Gathering trace data for <ISSUE-ID>...`

1. **Read trace file**: Read `docs/precedents/<ISSUE-ID>.md`. If the file does not exist, report: "No decision traces found for <ISSUE-ID>. Traces are created during `/workflows:ship` when the executing-plans skill emits them." Then skip to Phase 2 (still show session context).

2. **Parse traces**: For each `## Trace —` section in the file, extract:
   - **Decision**: the `**Decision:**` field value
   - **Category**: the `**Category:**` field value
   - **Confidence**: the `**Confidence:**` field value (e.g., `8/10`)
   - **Inputs**: all bullet items under the `**Inputs:**` heading (these are the `context_used` files)
   - **Precedent Referenced**: the `**Precedent Referenced:**` field value (CDR/ADR reference or "None")

3. **Count traces**: Record the total number of traces found.

Narrate: `Phase 1/5: Gathering trace data... done ([N] traces found)`

## Phase 2: Reconstruct Session Context

Narrate: `Phase 2/5: Reconstructing session-level context...`

Session-level context is loaded by every agent session via CLAUDE.md `@import` directives. These files inform all decisions but may not appear in per-task `context_used` lists.

1. **Read project CLAUDE.md**: Read the project's CLAUDE.md file.
2. **Extract @imports**: Find all lines matching `@` followed by a relative file path (the `@import` pattern). Collect the file paths.
3. **Label**: Mark these as "Session-level context (loaded via CLAUDE.md @imports)" — they are always available to agents, even if not listed in individual trace Inputs.

Narrate: `Phase 2/5: Reconstructing session context... done ([N] @imports found)`

## Phase 3: Staleness Check

Narrate: `Phase 3/5: Checking context staleness...`

For every file referenced in Phase 1 Inputs AND Phase 2 session context:

1. **Existence check**: Use Glob to verify the file exists. If missing, flag as `MISSING — file no longer exists (context was stale or deleted)`.

2. **Freshness check**: For files that exist, read the first 10 lines to check for YAML frontmatter containing `last_refreshed` (ISO date) and `refresh_cadence` (`quarterly`=90d, `monthly`=30d, `weekly`=7d, `on-change`=skip).
   - If both fields are present, compute: `staleness_ratio = days_since_last_refreshed / cadence_days`
   - Classify:
     - **Fresh** (ratio <= 1.0): No flag
     - **Aging** (ratio 1.0–1.5): Flag as `AGING`
     - **Stale** (ratio 1.5–2.0): Flag as `STALE`
     - **Very Stale** (ratio > 2.0): Flag as `VERY STALE`
   - If either field is missing, classify as `No freshness metadata` (no flag — this is normal for most files)

3. **Collect warnings**: Accumulate all MISSING, STALE, and VERY STALE entries for the report summary.

Narrate: `Phase 3/5: Staleness check... done ([N] warnings)`

## Phase 4: Frequency Analysis

Narrate: `Phase 4/5: Computing frequency analysis...`

Analyze how often each file appears across all traces for this issue:

1. **Build frequency map**: Count occurrences of each file path across all trace Inputs sections.
2. **Most referenced**: Top 5 files by frequency (high utility — these are the most important context for this issue).
3. **Session-only context**: Files from Phase 2 that never appear in any trace's Inputs list. These are loaded but potentially unused for this issue's decisions.
4. **Single-use context**: Files appearing in only one trace's Inputs (may indicate narrow relevance).

Narrate: `Phase 4/5: Frequency analysis... done`

## Phase 5: Report

Narrate: `Phase 5/5: Generating audit report...`

Present the full audit report in this structure:

```
# Context Audit — <ISSUE-ID>

## Summary
- Traces: [N] decision traces recorded
- Context files: [N] unique files referenced across all traces
- Session context: [N] @imported files from CLAUDE.md
- Staleness warnings: [N] (breakdown: [N] missing, [N] stale, [N] very stale)

## Per-Trace Audit

### Trace 1: <Decision summary>
- Category: <category>
- Confidence: <N/10>
- Precedent: <CDR/ADR reference or None>
- Inputs:
  - `path/to/file.md` — Fresh
  - `path/to/other.md` — STALE (last refreshed: 2026-01-15, cadence: monthly, ratio: 2.3)
  - `path/to/deleted.md` — MISSING

[Repeat for each trace]

## Session-Level Context
Files loaded via CLAUDE.md @imports (available to all agent sessions):
- `docs/decisions/001-cross-repo-import-solution.md` — Fresh
- `docs/decisions/002-trait-evolution-mechanism.md` — No freshness metadata
[...]

## Frequency Analysis

### Most Referenced (across all traces)
| File | References | Freshness |
|------|-----------|-----------|
| path/to/frequently-used.md | 4 | Fresh |
[...]

### Session-Only Context (loaded but not directly cited in traces)
- `path/to/session-only.md` — loaded via @import but not referenced in any trace Inputs

### Single-Use Context
- `path/to/one-time.md` — referenced in 1 trace only

## Staleness Warnings
[List all MISSING, STALE, and VERY STALE files with details]
If no warnings: "All referenced context files are current."
```

If no traces were found (Phase 1 returned nothing), the report shows only the Session-Level Context and Staleness sections with a note: "No decision traces recorded for this issue. Run `/workflows:ship` after completing work to emit traces."

Narrate: `Phase 5/5: Audit report complete.`
