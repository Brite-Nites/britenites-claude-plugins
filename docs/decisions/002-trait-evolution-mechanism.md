# 002. Trait Evolution Mechanism

**Status:** Accepted
**Date:** 2026-03-23

## Context

Projects change over time. A "documentation site" might gain `produces-code` when someone adds interactive features. A CLI tool might gain `has-external-users` when it's published for external consumption. The trait-based classification system (BC-1942) classifies traits at project-start, but provides no mechanism for updating them mid-project.

PRD Section 12, Question 9 asks: "How does the platform handle trait changes mid-project? Re-run classification? Manual override?"

Traits currently drive:
- Doc scaffolding (trait-to-doc mapping)
- CLAUDE.md sections (trait-conditional `@imports`)
- Linear labels (`trait:<name>`)
- Infrastructure gating (GitHub, CI/CD, MCP verification)
- Plugin activation (Engineering, Design, etc.)

A trait evolution mechanism must handle: adding new traits, removing stale traits, updating CLAUDE.md and Linear labels, and deciding what happens to existing scaffolded docs.

## Options Considered

### Option 1: Manual Re-Classify Command

A `/workflows:reclassify` command that re-runs Phase 3 (trait classification) from the interview.

- **Pros**: Thorough, uses the same detection logic as initial classification
- **Cons**: Heavyweight for a single trait change, requires re-running interview questions to gather evidence, no incremental path

### Option 2: Session-Start Auto-Detect

Scan for new file markers at the start of each session (same markers used by express mode). Additive only.

- **Pros**: Catches organic drift automatically (e.g., user adds `prisma/` directory → `involves-data` detected), no user action required, reuses express mode file marker table
- **Cons**: Cannot detect trait removal, cannot detect business-context traits (e.g., `client-facing`, `needs-marketing`) from file markers alone, adds ~1-2s to session-start

### Option 3: Explicit `add-trait` / `remove-trait` Commands

User manually runs `/workflows:add-trait <name>` or `/workflows:remove-trait <name>`.

- **Pros**: Surgical, fast, user stays in control, handles both addition and removal
- **Cons**: User must know the trait name, no automatic detection of drift

### Option 4: Hybrid (Auto-Detect + Manual Override)

Session-start scans for new file markers (additive). User can explicitly add or remove traits via commands.

- **Pros**: Most flexible — catches organic drift automatically while giving user explicit control, covers both technical traits (auto-detect) and business traits (manual)
- **Cons**: Slightly more complex to implement (two mechanisms), but each mechanism is simple independently

## Decision

**Hybrid approach (Option 4).**

### Auto-Detect (passive, at session-start)

- Reuse the express mode file marker table from `project-start.md`
- On each session-start, scan for markers that map to traits not currently in the active set
- If new trait(s) detected, show a **non-blocking notification**:
  > "New trait signal detected: `involves-data` (found `prisma/` directory). Run `/workflows:add-trait involves-data` to activate."
- **Additive only** — never auto-remove traits. Removal requires explicit user action.
- Lightweight check (Glob-based, no LLM inference), suitable for session-start timing

### Manual Add/Remove (explicit commands)

**`/workflows:add-trait <trait-name>`:**
1. Validate trait is in the fixed set of 11
2. Add to `active:` line in CLAUDE.md `## Project Traits` section
3. Scaffold missing docs for the trait (same trait-to-doc mapping from project-start)
4. Add `@import` to CLAUDE.md for the new trait-conditional section
5. Create the Linear `trait:<name>` label (if not exists)
6. Record evidence: `"User-added via /workflows:add-trait on YYYY-MM-DD"`

**`/workflows:remove-trait <trait-name>`:**
1. Validate trait exists in `active:` line
2. Remove from `active:` line in CLAUDE.md
3. Remove the `@import` for the trait-conditional section from CLAUDE.md
4. **Do NOT delete scaffolded docs** — they may contain valuable project context
5. Archive the Linear `trait:<name>` label
6. Record in evidence section: `"Removed via /workflows:remove-trait on YYYY-MM-DD. Docs preserved."`

### Key Design Decisions

- **Docs are never deleted when a trait is removed.** They were populated with project context and may still be useful. They simply stop being `@imported` into CLAUDE.md.
- **No full re-classify command.** The hybrid of auto-detect + manual covers all practical cases. Users who want a full re-evaluation can run `/workflows:project-start express` on their existing project — it reads the existing `## Project Traits` section and allows adjustment.
- **Auto-detect is additive only.** Detecting that a trait is no longer relevant requires understanding project intent, not just file markers. This is a human decision.
- **Session-start notification is non-blocking.** The developer can ignore the suggestion and proceed with their work.

## Consequences

### Positive

- Catches organic project drift automatically (new dependencies, new directories)
- Gives users surgical control over trait changes
- Preserves existing documentation when traits are removed
- Reuses express mode file marker infrastructure — no new detection logic needed
- Non-disruptive — notification pattern, not a blocking prompt

### Negative

- Auto-detect cannot catch business-context trait changes (e.g., gaining a client, starting marketing)
- Cannot detect when a trait becomes irrelevant — removal is always manual
- Session-start gets ~1-2s longer from the Glob scan
- Two new commands to implement (`add-trait`, `remove-trait`)

## Reversibility

Low-risk decision. If the hybrid approach proves too noisy:
1. Disable session-start auto-detect by removing the scan logic
2. Keep only the manual `add-trait`/`remove-trait` commands
3. No data migration needed — trait storage format in CLAUDE.md is unchanged

## Implementation Notes

These are future work items, not part of this ADR:
- `add-trait.md` and `remove-trait.md` command files in `plugins/workflows/commands/`
- Session-start trait drift detection: new step in `session-start.md` between environment setup and Linear query
- The trait interface contract in `workflow-spec.md` already supports mutation — the `active:` line is a comma-separated list
