# Plan: Define context loading cascade architecture

**Issue**: BRI-2006 — Define context loading cascade architecture
**Branch**: holden/bri-2006-define-context-loading-cascade-architecture
**Tasks**: 5 (estimated 30 min)

## Prerequisites
- Design doc approved at `docs/designs/BRI-2006-context-loading-cascade.md`
- Audit of current skills completed during brainstorming (all 4 inner-loop skills read)

## Audit Results (from brainstorming Phase 1)

| Stage | Skill | What it loads today | Tier compliance |
|-------|-------|-------------------|-----------------|
| session-start | session-start.md | CLAUDE.md, auto-memory, Company Context check | Tier 1+2 only — compliant |
| brainstorm | brainstorming/SKILL.md | Linear issue, CLAUDE.md, auto-memory, relevant code | Tier 1+2 only — compliant |
| plan | writing-plans/SKILL.md | Design doc, Linear issue, CDR INDEX (Context7 query), source code, test patterns | CDR is Tier 3 on-demand — compliant |
| execute | executing-plans/SKILL.md | Design doc, plan file; subagents get task desc + relevant files + conventions | Narrowest scope — compliant |
| review | review.md | Diff, changed files; agents read files themselves | Task-scoped — compliant |
| ship | ship.md + compound-learnings | CLAUDE.md, diff, commit history | Project-scoped — compliant |

**Conclusion**: All current skills are cascade-compliant. No behavioral changes needed.

## Tasks

### Task 1: Expand design doc with authoritative spec tables
**Files**: `docs/designs/BRI-2006-context-loading-cascade.md`
**Why**: The design doc currently has brainstorming output only. Add the authoritative 7-stage loading table and 5-layer context model, audited against actual skill code.

**Implementation**:
1. After the existing "Open Questions" section, add a `---` divider and new `## Authoritative Specification` section
2. Add `### Governing Principle` with the "narrowest scope" rule
3. Add `### 7-Stage Loading Table` — use the PRD's table structure but fill with audited values from the Audit Results above. Add a `Status` column: "implemented" for current, "planned (BRI-XXXX)" for future
4. Add `### 5-Layer Context Model` — same approach: audited current state with "planned" markers
5. Add `### Future Capabilities` section listing planned but unbuilt features with issue refs: CDR compliance at review (no issue yet), precedent search at brainstorm (BRI-1960), per-task context filtering (no issue yet), freshness tracking (BRI-1938), context budget limits (BRI-2003)

**Verify**: File exists and contains both tables with "implemented" and "planned" status markers.

---

### Task 2: Add cascade YAML blocks to workflow-spec.md
**Files**: `docs/workflow-spec.md`
**Why**: Machine-parseable spec for downstream automation and validation.

**Implementation**:
1. After section `## 5. Error Handling Contracts` (ends ~line 1899), add `## 6. Context Loading Cascade`
2. Add intro paragraph: "Authoritative specification for when context loads during the inner loop. See `docs/designs/BRI-2006-context-loading-cascade.md` for rationale."
3. Add `### 6a. Loading Table` with anchor `<!-- spec:cascade:loading-table -->` and a YAML block containing the 7-stage loading table (stage, skill, what-loads, how, tier, status fields)
4. Add `### 6b. Context Layers` with anchor `<!-- spec:cascade:context-layers -->` and a YAML block containing the 5-layer model (layer, scope, examples, loaded-at, refresh, status fields)
5. Add `### 6c. Governing Principle` with anchor `<!-- spec:cascade:principle -->` and a YAML block: `principle: "Load context at the narrowest scope that still informs the decision"` plus the tier definitions

**Verify**: Run `scripts/validate.sh` — must pass (the script validates YAML blocks in workflow-spec.md).

---

### Task 3: Add cascade reference comments to inner-loop skills
**Files**: `plugins/workflows/commands/session-start.md`, `plugins/workflows/skills/writing-plans/SKILL.md`, `plugins/workflows/skills/executing-plans/SKILL.md`, `plugins/workflows/skills/brainstorming/SKILL.md`
**Why**: Breadcrumb trail so skill editors know the cascade spec exists and can check compliance.

**Implementation**:
1. In `session-start.md`: After the `## Step 1: Environment Setup` heading (line 25), add a blockquote: `> **Context cascade**: This step loads Tier 1+2 context (CLAUDE.md, auto-memory). See `docs/designs/BRI-2006-context-loading-cascade.md` for the full cascade spec.`
2. In `brainstorming/SKILL.md`: After the `## Phase 1: Context Gathering` heading (line 42), add: `> **Context cascade**: This phase loads Tier 1+2 context (issue, CLAUDE.md, memory, code). See `docs/designs/BRI-2006-context-loading-cascade.md` for the full cascade spec.`
3. In `writing-plans/SKILL.md`: After the `## Context Loading` heading (line 33), add: `> **Context cascade**: This step loads Tier 1+2 context plus Tier 3 CDR INDEX on-demand. See `docs/designs/BRI-2006-context-loading-cascade.md` for the full cascade spec.`
4. In `executing-plans/SKILL.md`: After the `### Context Anchor` heading (line 35), add: `> **Context cascade**: Subagents load only task-scoped context (Tier 5). See `docs/designs/BRI-2006-context-loading-cascade.md` for the full cascade spec.`

**Verify**: `grep -r "Context cascade" plugins/workflows/` returns exactly 4 matches.

---

### Task 4: Commit CLAUDE.md Company Context + all spec changes
**Files**: `CLAUDE.md`, all files from Tasks 1-3
**Why**: The Company Context block has been pending since the housekeeping phase. Bundle it with the spec work.

**Implementation**:
1. Stage: `CLAUDE.md`, `docs/designs/BRI-2006-context-loading-cascade.md`, `docs/plans/BRI-2006-plan.md`, `docs/workflow-spec.md`, `plugins/workflows/commands/session-start.md`, `plugins/workflows/skills/writing-plans/SKILL.md`, `plugins/workflows/skills/executing-plans/SKILL.md`, `plugins/workflows/skills/brainstorming/SKILL.md`
2. Commit with message: "Define context loading cascade architecture (BRI-2006)"

**Verify**: `git status` shows clean working directory. `git log -1` shows the commit.

---

### Task 5: Update Linear cross-references
**Files**: None (Linear API calls)
**Why**: The 4 related issues need links to the cascade spec so implementers find it.

**Implementation**:
1. Add a comment on BRI-1938 (freshness tracking): "Context loading cascade spec defined in BRI-2006 — see `docs/designs/BRI-2006-context-loading-cascade.md`. Freshness tracking is marked as 'planned' in the cascade."
2. Add a comment on BRI-2003 (context budget): "Context loading cascade spec defined in BRI-2006. Budget strategy should constrain the tiers defined in the cascade."
3. Add a comment on BRI-1945 (CLAUDE.md dynamic imports): "Context loading cascade spec defined in BRI-2006. Dynamic @imports should follow the tier loading rules."
4. Add a comment on BRI-1939 (CDR check): "Context loading cascade spec defined in BRI-2006. CDR check is documented as Tier 3 on-demand at plan stage."

**Verify**: Each comment is visible on the respective Linear issue.

## Task Dependencies
- Task 1 is independent
- Task 2 is independent (can run parallel with Task 1)
- Task 3 depends on Task 1 (references the spec doc)
- Task 4 depends on Tasks 1, 2, 3
- Task 5 depends on Task 4 (commit should exist before cross-referencing)

## Verification Checklist
- [ ] `scripts/validate.sh` passes
- [ ] `docs/designs/BRI-2006-context-loading-cascade.md` contains 7-stage table and 5-layer model
- [ ] `docs/workflow-spec.md` contains `## 6. Context Loading Cascade` with 3 YAML blocks
- [ ] 4 skills contain "Context cascade" reference comments
- [ ] `CLAUDE.md` contains `## Company Context` with `Last refreshed: 2026-03-16`
- [ ] `git status` shows clean working directory
- [ ] 4 Linear issues have cross-reference comments
