# Coherence Audit — Conflicts & Cross-Reference Integrity

**Issue:** BC-2461
**Date:** 2026-03-25
**Note:** Line numbers reference the pre-fix CLAUDE.md (236 lines). All findings below have been resolved. See `001-coherence-audit-report.md` Verification Results for post-fix state.

---

## C1: Ship Step Count Drift

**Severity: Concerning** — Step numbers don't match between the command and the guide.

| Source | Steps | Handbook Drift Check |
|--------|------:|:--------------------:|
| `ship.md` | 0-8 (9 steps) | Step 6 |
| `workflow-guide.md` | 0-7 (8 steps) | Missing |

**Details:**
- `ship.md` Steps 0-8: Verify CLI → Pre-Ship → Create PR → Update Linear → Compound → Audit → **Handbook Drift** → Worktree Cleanup → Session Close
- `workflow-guide.md` Steps 0-7: Same but skips Handbook Drift Check entirely. Steps 6-7 in the guide correspond to Steps 7-8 in ship.md.

**Also:** ship.md uses `Step N/8` narration markers (8 steps after step 0), but there are 9 steps total (0-8). This means the narration `Step 1/8` through `Step 8/8` is correctly used for steps 1-8, with step 0 being unnumbered — consistent within ship.md but the guide's table doesn't reflect it.

### Recommendation

Update `workflow-guide.md` ship table to include Step 6: Handbook Drift Check and renumber Steps 6-7 → 7-8.

---

## C2: Inner Loop Skill Count Drift

**Severity: Concerning** — CLAUDE.md and workflow-guide.md disagree on how many inner loop skills exist.

| Source | Count | Missing Skills |
|--------|------:|----------------|
| `CLAUDE.md` | 10 | — |
| `workflow-guide.md` | 8 | `precedent-search`, `handbook-drift-check` |

**Details:**
- CLAUDE.md correctly lists 10 inner loop skills.
- workflow-guide.md lists 8 (missing `precedent-search` and `handbook-drift-check`).
- However, `workflow-guide.md` step 2 narrative (line 42) mentions "searches past decision traces" in the brainstorming description — this is what `precedent-search` does, but the skill isn't in the table.
- `workflow-guide.md` step 8 narrative (line 48) mentions `best-practices-audit` but not `handbook-drift-check`.

### Recommendation

Update `workflow-guide.md` Inner Loop Skills table: add `precedent-search` and `handbook-drift-check`. Change header from "Inner Loop Skills (8)" to "Inner Loop Skills (10)".

---

## C3: Activation Chain Integrity

**Severity: Notable** — The handoff chain is mostly consistent but has two gaps.

### Verified Handoffs

| From | To | Reference |
|------|-----|-----------|
| `brainstorming` | `writing-plans` | Line 181: `Proceeding to → writing-plans` |
| `writing-plans` | `git-worktrees` | Line 186: `Proceeding to → git-worktrees` |
| `git-worktrees` | `executing-plans` | Line 136: `Proceeding to → executing-plans` |
| `executing-plans` | `/workflows:review` | Line 378: `Proceeding to → /workflows:review` |
| `compound-learnings` | `best-practices-audit` | Line 328: `Proceeding to → best-practices-audit` |
| `best-practices-audit` | `/workflows:ship` | Line 206: `Returning to → /workflows:ship` |

### Missing Handoffs

1. **`verification-before-completion`** — No handoff marker. This is correct: it's invoked inline by `executing-plans` at each checkpoint, not as a standalone step in the chain.
2. **`precedent-search`** — No handoff marker. This is also correct: it's invoked inline by `brainstorming` during discovery.
3. **`handbook-drift-check`** — No "Proceeding to" marker, only a completion marker (line 225). Returns to `/workflows:ship` implicitly via ship.md Step 6 orchestration. **Not a bug** — ship.md orchestrates the final chain, skills return to the orchestrator.

### Analysis

The chain is sound. Inner loop skills that operate within another skill's phase (verification-before-completion, precedent-search) correctly have no standalone handoff. Terminal skills (best-practices-audit, handbook-drift-check) return to their orchestrator (/workflows:ship).

---

## C4: Priority Ambiguity

**Severity: Curious** — No priority conflicts detected.

Only one strong priority marker in CLAUDE.md: the plugin.json schema warning (`NEVER add these...`). No overlapping `IMPORTANT`/`CRITICAL` markers on the same topic across CLAUDE.md and skills/commands.

The distributed architecture actually helps here — each skill file addresses a single concern, reducing the chance of priority conflicts (gstack Pattern 1: Single Concern Per Section).

---

## C5: Vagueness Instances

**Severity: Notable** — 3 vague instructions found.

| File | Line | Text | Issue |
|------|-----:|------|-------|
| `testing-strategy/SKILL.md` | 76 | "Use in-source testing for pure utility functions when appropriate" | Subjective: when is it "appropriate"? |
| `CLAUDE.md` | 29 | "Tech-stack skills belong in separate plugins" | Undefined: what counts as a "tech-stack skill"? |
| `CLAUDE.md` | 31 | "Use context7 MCP for framework docs" | Ambiguous: every time? only for setup questions? |

### Proposed Rewrites

1. **testing-strategy:76**: "Use in-source testing for pure utility functions with ≤3 dependencies and no side effects"
2. **CLAUDE.md:29**: "Skills that teach framework-specific patterns (React, Python, CI/CD) belong in domain plugins. Process skills (brainstorming, planning, execution) stay in the workflows plugin."
3. **CLAUDE.md:31**: "Not domain: Tech-stack skills belong in separate plugins. Use context7 MCP for framework docs." → already scoped by "Not domain" prefix. Acceptable as-is — the context7 directive is a clear instruction when read in the Plugin Philosophy section.

---

## C6: Path Inconsistency

**Severity: Notable** — Two different path formats used for `_shared/validation-pattern.md`.

| Format | Used By |
|--------|---------|
| `_shared/validation-pattern.md` | brainstorming, writing-plans, executing-plans, compound-learnings, handbook-drift-check, best-practices-audit, precedent-search |
| `.claude/skills/_shared/validation-pattern.md` | create-issues, refine-plan, setup-claude-md |

The `.claude/skills/` prefix assumes skills are installed at a specific path. The relative `_shared/` format is more portable.

### Recommendation

Standardize to `_shared/validation-pattern.md` (relative) in create-issues, refine-plan, and setup-claude-md.

---

## C7: workflow-spec.md Cross-References

**Severity: Curious** — Only 2 references from `project-start.md` to `workflow-spec.md`:
- Line 160: "See error handling in workflow-spec.md"
- Line 389: "See `docs/workflow-spec.md` Section 3d for the machine-readable parsing algorithm"

Both are specific section references (not broad "see the spec"). Low drift risk.

---

## Summary

| ID | Finding | Severity | Action |
|----|---------|----------|--------|
| C1 | Ship step count (guide missing Step 6) | Concerning | Update workflow-guide.md |
| C2 | Inner loop skill count (guide has 8, should be 10) | Concerning | Update workflow-guide.md |
| C3 | Activation chain gaps | Notable | No action (by design) |
| C4 | Priority ambiguity | Curious | None detected |
| C5 | Vagueness (3 instances) | Notable | Rewrite testing-strategy:76, clarify CLAUDE.md:29 |
| C6 | Path inconsistency (_shared/ references) | Notable | Standardize 3 files |
| C7 | workflow-spec.md cross-refs | Curious | No action needed |
