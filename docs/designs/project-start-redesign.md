## Design: Project-Start Redesign

**Issue**: BC-1948 (superseded — scope expanded to full redesign)
**Date**: 2026-03-18
**Milestone**: Project-Start Redesign

### Problem

The current `project-start.md` has four structural problems:

1. **CLAUDE.md before plan** — CLAUDE.md is generated before the V1 plan, but the plan reveals what CLAUDE.md should contain (better @imports, tech decisions, trait-conditional docs). The generated CLAUDE.md is always stale by the time planning finishes.

2. **No review gates** — Everything generates in one shot with no user feedback loop. Interview → CLAUDE.md → git → Linear → plan → ADRs all fire sequentially. Users can't adjust the plan before scaffolding is committed to disk.

3. **No trait classification** — A single binary question ("Are you technical or not?") drives all branching. Projects like marketing campaigns, data pipelines, or hiring plans don't fit either category. The 11-trait system from the PRD (BC-1942) replaces this with combinatorial classification.

4. **Disconnected pipeline** — Users must manually run `/workflows:post-plan-setup` after project-start to get refined tasks and Linear issues. The flow should be one continuous pipeline with review gates, not two separate commands stitched together manually.

### Current Flow (What Exists Today)

```
Step 1: Determine technical level (binary: Path A or Path B)
Step 2: Shared interview topics
Step 3: Path-specific questions
   ↓ (no review gate)
Step 4: Generate CLAUDE.md (Path A or Path B template)
Step 5: Git repository setup
Step 6: Create Linear project
Step 7: Write V1 project plan (docs/project-plan-v1.md)
Step 8: Generate ADRs for all tech decisions
Step 9: Update CLAUDE.md with ADR @imports
   ↓
"Run /workflows:session-start to begin working"
```

Problems with this ordering:
- CLAUDE.md (Step 4) is written before the plan (Step 7) and ADRs (Step 8), so it lacks @imports to those artifacts
- ADRs (Step 8) lack real implementation context — they're speculative, based on interview assumptions
- The plan (Step 7) can't inform CLAUDE.md structure because CLAUDE.md was already written
- No opportunity for the user to review or adjust anything between steps

### Proposed Flow — 5 Phases

```
Phase 1: Discovery (Interview)
  ├── Three-phase interview methodology (BC-1943)
  │   ├── Phase 1a: Understand (JTBD + MI + Design Thinking)
  │   ├── Phase 1b: Define (SPIN + Impact Mapping + Story Mapping)
  │   └── Phase 1c: Classify + Configure
  ├── Trait classification from interview answers (BC-1942)
  │   └── 11 traits: produces-code, produces-documents, involves-data,
  │       requires-decisions, has-external-users, client-facing, needs-design,
  │       needs-marketing, needs-sales, cross-team, automation
  ├── Show detected traits with evidence for confirmation
  ├── MCP verification based on detected traits (BC-1949)
  └── Express mode shortcut (BC-1950) / brownfield detection (BC-1951)

  ══════════════════════════════════════════════════════
  No review gate here — trait confirmation IS the gate
  ══════════════════════════════════════════════════════

Phase 2: V1 Plan Generation
  ├── Generate V1 plan from interview (enhanced)
  │   ├── Features (must-have / nice-to-have)
  │   ├── Architecture & tech decisions
  │   ├── Trait classification + what it triggers
  │   ├── Doc scaffolding plan (which docs, based on traits)
  │   ├── Plugin/skill recommendations (BC-1947)
  │   └── Constraints + success criteria
  ├── Present to user
  └── ═══ REVIEW GATE 1 ═══
      User reviews plan, asks questions, makes edits

Phase 3: Plan Refinement
  ├── Run refine-plan on approved V1 plan
  │   └── Output: docs/project-plan-refined.md with task breakdown
  ├── Show refined plan with issue breakdown
  │   ├── Task dependency graph (Mermaid)
  │   ├── Each task: Context, Steps, Validation, Complexity, Dependencies
  │   └── Issue count + estimated scope
  └── ═══ REVIEW GATE 2 ═══
      User reviews tasks, adjusts priorities/scope

Phase 4: Scaffolding (only after approval)
  ├── 1. Git repo setup (BC-1946) — need filesystem first
  │   └── If produces-code: GitHub repo in Brite-Nites org
  │   └── Otherwise: local git init or skip
  ├── 2. Reference docs — trait-conditional (BC-1944)
  │   └── Per-trait doc mapping (see Trait Activation Matrix)
  ├── 3. ADRs — for confirmed decisions from approved plan
  │   └── Real implementation context from plan, not speculative
  ├── 4. CLAUDE.md with @imports (BC-1945) — informed by ALL of the above
  │   └── Dynamic @imports to: docs, ADRs, handbook, trait-conditional docs
  └── 5. Linear project created

Phase 5: Issue Creation
  ├── Run create-issues from refined plan
  │   └── Issues use Explore → Plan → Execute → Verify format
  ├── Post-setup verification (BC-1952)
  │   └── Confirm: CLAUDE.md exists, Linear project created, docs scaffolded
  ├── Summary: links, counts, dependencies
  └── "Run /workflows:session-start to begin working"
```

### Key Insight: Corrected Execution Order

> **V1 deviation:** The V1 implementation (Steps 0-8 in `project-start.md`) does not yet follow this proposed ordering. V1 generates CLAUDE.md at Step 5 (before Plan and ADRs), then patches it when ADRs are generated at Step 8. The full reordering with review gates is planned for Wave 2.

The fundamental ordering change is that **CLAUDE.md is generated LAST among file artifacts** because it references everything else via @imports.

| Step | Current order | Proposed order | Why |
|------|--------------|----------------|-----|
| 1 | CLAUDE.md | Plan | Plan reveals what to build and what docs are needed |
| 2 | Git | Review gate | User validates before anything hits disk |
| 3 | Linear project | Refine plan | Tasks inform scope and issue structure |
| 4 | Plan | Review gate | User validates tasks before scaffolding |
| 5 | ADRs | Git setup | Need filesystem before writing files |
| 6 | CLAUDE.md @imports | Trait-conditional docs | Generated from approved plan, not speculation |
| 7 | — | ADRs | Real context from plan, not interview assumptions |
| 8 | — | CLAUDE.md | Generated LAST — knows about all docs, ADRs, plan |
| 9 | — | Linear project + issues | Project exists; issues reference correct file paths |

### Phase 1 Detail: Discovery

#### Interview Methodology (BC-1943)

Replaces the flat question list with a three-phase composite methodology:

**Phase 1a — Understand** (JTBD + MI + Design Thinking)
- JTBD trigger: "What happened that made you decide to do this now?"
- MI OARS as conversational backbone (Open questions, Affirmations, Reflective listening, Summaries)
- Design Thinking stories: "Walk me through the last time you dealt with this"
- Five Whys drill-down when user states a solution instead of a problem
- Appreciative Inquiry for brownfield: "What's working today?"

**Phase 1b — Define** (SPIN + Impact Mapping + Story Mapping)
- SPIN Implication: "What happens if this isn't solved?"
- Impact Mapping: Goal → Actors → Impacts → Deliverables
- Story Mapping: "What does the user do first? Then what?"
- Lean Canvas: "Top 3 problems. Rank them."

**Phase 1c — Classify + Configure**
- Automated trait classification from conversation signals
- Plugin discovery based on traits
- MCP verification for required tools
- User confirms traits before proceeding

**8 design principles** embedded as behavioral guardrails:
1. Reflect before advancing (MI)
2. Ask about situations, not opinions (Design Thinking)
3. Drill when someone states a solution (Five Whys)
4. Use implications to reveal priority (SPIN)
5. Walk the user journey for scope (Story Mapping)
6. Summarize at transitions (MI)
7. Classify late, not early
8. Cap at 3 (Lean Canvas)

#### Trait Classification (BC-1942)

After the interview, Claude analyzes the conversation for trait signals and proposes a trait set.

| Trait | Detection Signals | Documentation | Infrastructure |
|-------|------------------|---------------|----------------|
| `produces-code` | "build an app", "implement", programming languages | `docs/engineering-context.md` | GitHub repo, CI, pre-commit, .vscode |
| `produces-documents` | "write a plan", "create docs", "report" | `docs/brief.md`, `docs/outline.md` | — |
| `involves-data` | "analyze", "data warehouse", "Snowflake", "BigQuery", "Redshift", "Databricks", "dashboard"; "metrics" only with data infrastructure co-terms | Data source in CLAUDE.md | Warehouse MCP verified |
| `requires-decisions` | "evaluate", "choose between", "build vs buy" | CDR INDEX @imported | docs/decisions/ |
| `has-external-users` | "customers", "users", "public-facing" | Accessibility requirements | Deployment config, monitoring |
| `client-facing` | "client", "client deliverable", "external stakeholder", "SOW", "client relationship" | Communication cadence in CLAUDE.md | — |
| `needs-design` | "brand", "visual", "colors", "palette" | `docs/design-context.md` | Design plugin |
| `needs-marketing` | "launch", "campaign", "audience", "positioning" | `docs/marketing-context.md` | Marketing plugin |
| `needs-sales` | "pricing", "sales deck", "objections", "demo" | `docs/sales-context.md` | Sales plugin |
| `cross-team` | "multiple teams", "stakeholders", "org-wide" | `docs/stakeholders.md` @imported | — |
| `automation` | "scheduled", "cron", "pipeline", "CI/CD", "bot" | Script/scheduler patterns in CLAUDE.md | — |

**Always created** (regardless of traits): CLAUDE.md, Linear project, `docs/decisions/` directory.

BC-1942 already has sub-issues for incremental delivery:
- BC-2127: Add trait definition table to project-start (data only, no behavior change)
- BC-2128: Add trait classification + confirmation step (post-interview detection)
- BC-2131: Wire trait output for downstream consumption (conditional infrastructure)

#### Alternate Entry Paths

**Express mode** (BC-1950): Auto-detects traits from existing codebase signals without a full interview. Activated via `$ARGUMENTS` containing "express" or when existing project files detected. Scans file markers → maps to traits → quick confirmation → skip to Phase 4.

**Brownfield support** (BC-1951): Extends express mode for onboarding existing projects. Imports context from README/CLAUDE.md/docs, detects conventions from codebase, pre-fills context docs, reconciles with CDRs. Lower priority — depends on express mode.

### Phase 2 Detail: V1 Plan

The V1 plan is KEPT (contradicting BC-1948's original "remove" scope) but REORDERED — it now comes BEFORE scaffolding, not after CLAUDE.md generation.

The plan file at `docs/project-plan-v1.md` contains:
- Overview (what and why)
- Target users
- Features (must-have / nice-to-have)
- Architecture & technical decisions
- Trait classification + what each trait triggers
- Doc scaffolding plan (which docs will be generated)
- Plugin/skill recommendations
- Constraints + success criteria
- Open questions

**Review Gate 1**: User reviews the plan. This is where tech decisions get challenged, scope gets adjusted, and the trait list gets finalized. Nothing has been written to disk yet — the plan is purely conversational until approved.

### Phase 3 Detail: Plan Refinement

After the user approves the V1 plan, the existing `refine-plan` agent (plan-refiner, Opus) decomposes it into agent-ready tasks.

Output: `docs/project-plan-refined.md` with:
- Task dependency graph (Mermaid)
- Each task: Context, Steps, Validation, Complexity, Dependencies
- Issue count + estimated scope

**Review Gate 2**: User reviews the refined task breakdown. Can adjust task granularity, reorder priorities, remove tasks, split or merge. This gate is critical — it's the last chance to change scope before files hit disk and Linear issues are created.

### Phase 4 Detail: Scaffolding

Only executes after both review gates pass. Order matters:

**Step 1: Git repo setup** (BC-1946)
- If `produces-code`: `gh repo create Brite-Nites/<name> --private`, .gitignore, pre-commit, .vscode
- If no `produces-code` but other traits: local `git init` with appropriate .gitignore
- If document-only project: may skip git entirely (user choice)
- Fallback: if `gh` unavailable, local `git init` with warning

**Step 2: Reference docs** (BC-1944)
Trait-conditional doc scaffolding. Only creates docs for active traits. Templates populated from interview answers.

**Step 3: ADRs**
For confirmed decisions from the approved plan. These now have real context — the plan specifies WHY decisions were made, what alternatives were considered, and what constraints apply. Much higher quality than speculative ADRs from a raw interview.

**Step 4: CLAUDE.md** (BC-1945)
Generated LAST among files. Dynamic @imports to:
- Handbook context (always: CDR INDEX, operational context)
- Trait-conditional docs (only for active traits)
- ADRs (for decisions made in the plan)
- Project-specific sections (from interview)
- Budget constraint: <100 lines, extract detail to docs/ via @imports

**Step 5: Linear project**
Created after file artifacts so the project description can reference actual file paths.

### Phase 5 Detail: Issue Creation

#### Issue Template Redesign

Current `create-issues` format:
```
## Context
## Implementation Steps
## Validation Criteria
## Dependencies
```

Proposed Explore → Plan → Execute → Verify format:
```markdown
## Context
[Why this issue exists, what it's part of, architectural decisions that apply]

## Explore
- Read CLAUDE.md for project conventions
- Read [specific files] to understand current state
- Check for existing patterns/utilities to reuse

## Plan
- Use sequential-thinking to design implementation
- Consider: [specific trade-offs relevant to this task]
- Produce a task-level plan before coding

## Execute
- [Specific implementation steps]
- [Exact file paths to create/modify]
- [Patterns to follow from codebase]

## Verify
- [ ] [Testable acceptance criterion]
- [ ] [Build/lint/test commands pass]
- [ ] [Integration check if applicable]

## Dependencies
[Blocks/blocked-by with issue IDs]
```

This template aligns with the inner loop: each issue naturally flows through brainstorming (Explore), writing-plans (Plan), executing-plans (Execute), and verification-before-completion (Verify).

#### Post-Setup Verification (BC-1952)

Final checklist:
- CLAUDE.md exists and is valid
- Linear project created with correct description
- All trait-conditional docs scaffolded
- ADRs generated for confirmed decisions
- Plugins activated (or missing ones flagged)
- MCP connections verified

### /scope Command Alignment

Both `project-start` and `/scope` share the same core pipeline:

```
Interview → V1 plan → review → refine → review → scaffold/update → create issues
```

| Aspect | project-start | /scope |
|--------|--------------|--------|
| Creates from scratch | CLAUDE.md, git, Linear project, docs/ | — |
| Updates existing | — | New docs, CLAUDE.md additions, new issues |
| Interview depth | Full three-phase (JTBD + MI + SPIN) | Focused Socratic dialogue |
| Trait classification | Full 11-trait detection | Incremental (add traits to existing set) |
| Git setup | Full repo creation | Already exists |
| Linear | New project | Existing project, new issues |

The shared pattern is documented here. Extracting a common pipeline module is deferred to a future issue — both commands currently contain their own pipeline. When the pattern stabilizes after implementation, a shared pipeline skill may make sense.

### Existing Issue Mapping

| Issue | What it covers | Phase | Status in redesign |
|-------|---------------|-------|-------------------|
| BC-1942 | Trait classification system (11 traits, detection, wiring) | 1 | **Core dependency** — has sub-issues BC-2127, BC-2128, BC-2131 |
| BC-1943 | Interview rewrite (JTBD + MI + SPIN three-phase methodology) | 1 | **Core dependency** — feeds trait signals to BC-1942 |
| BC-1944 | Trait-conditional doc scaffolding | 4 (step 2) | Unchanged — consumes trait output |
| BC-1945 | CLAUDE.md with dynamic @imports | 4 (step 4) | Unchanged — but now executes LAST, not first |
| BC-1946 | GitHub repo creation | 4 (step 1) | Unchanged — conditional on `produces-code` |
| BC-1947 | Plugin discovery + activation | 1 (classify phase) | Unchanged — trait → plugin mapping |
| BC-1948 | Remove premature plan + ADR | — | **SUPERSEDED** — plan kept but reordered; ADRs moved to Phase 4 |
| BC-1949 | Dynamic MCP verification | 1 (classify phase) | Unchanged — trait → MCP mapping |
| BC-1950 | Express mode | 1 (alternate path) | Unchanged — bypasses interview, goes to Phase 4 |
| BC-1951 | Brownfield support | 1 (alternate path) | Unchanged — extends express mode |
| BC-1952 | Post-setup verification | 5 (end) | Unchanged — verifies all artifacts |
| BC-1953 | Update docs (workflow-spec, guide, testing) | Post-impl | Unchanged — reflects final state |
| BC-1954 | Update validate.sh + CI | Post-impl | Unchanged — validates new structure |
| BC-2005 | End-to-end scenario validation | Post-impl | Unchanged — acceptance tests from PRD |

### Implementation Order

The phases above describe the user-facing flow. Implementation order is different — it follows dependency chains:

**Wave 1: Foundation** (no dependencies between these)
- BC-1942 (trait classification) — sub-issues BC-2127 → BC-2128 → BC-2131
- BC-1943 (interview rewrite) — blocked by BC-1942

**Wave 2: Plan + Review Gates** (depends on Wave 1)
- Reorder project-start to generate V1 plan BEFORE scaffolding
- Add Review Gate 1 after plan presentation
- Integrate refine-plan into project-start flow
- Add Review Gate 2 after refinement

**Wave 3: Scaffolding** (depends on Wave 2)
- BC-1946 (GitHub repo creation)
- BC-1944 (trait-conditional docs)
- BC-1945 (dynamic CLAUDE.md — reordered to execute last)
- ADR generation (moved from interview-time to post-plan)

**Wave 4: Issue Pipeline** (depends on Wave 3)
- Issue template redesign (Explore → Plan → Execute → Verify)
- Integrate create-issues into project-start flow
- BC-1952 (post-setup verification)

**Wave 5: Alternate Paths** (independent, lower priority)
- BC-1950 (express mode)
- BC-1951 (brownfield support)
- BC-1949 (dynamic MCP verification)
- BC-1947 (plugin discovery)

**Wave 6: Documentation** (after implementation stabilizes)
- BC-1953 (workflow-spec, guide, testing docs)
- BC-1954 (validate.sh + CI)
- BC-2005 (end-to-end scenario validation)

### What Does NOT Change

- `/workflows:session-start` — unchanged (already works well with brainstorm → plan per issue)
- `/workflows:architecture-decision` — unchanged (organic ADR generation during development)
- Inner loop skills — unchanged (brainstorming, writing-plans, executing-plans, etc.)
- Review pipeline (`/workflows:review`) — unchanged
- Existing agents (plan-refiner, issue-creator) — templates updated, core logic stays
- Context loading cascade (BRI-2006) — project-start stage in the loading table may need updating but the cascade architecture is unaffected
- Budget management (BC-2003) — the <100 line budget constraint on CLAUDE.md still applies

### New Issue Needed

BC-1948 should be updated to status **Superseded** with a link to this design doc. Its original scope ("remove premature plan + ADR") is subsumed by the redesign — plans are kept but reordered, ADRs are moved to Phase 4.

No net-new issues are needed. The plan's reference to "BC-1942 doesn't exist yet" was incorrect — it does exist (created 2026-03-12) and already has 3 sub-issues.

### Risks & Mitigations

**Long session risk** — The full 5-phase pipeline is significantly longer than the current project-start. Mitigation: Express mode (BC-1950) provides a fast path. Review gates let users bail out early ("just generate CLAUDE.md, skip the rest"). Phase 3-5 can be deferred to a follow-up session.

**Context window pressure** — A full interview + plan + refinement + scaffolding in one session may push context limits. Mitigation: Each phase produces durable artifacts (plan file, refined plan, CLAUDE.md). If context compresses mid-session, artifacts on disk preserve state.

**Scope creep** — 14 issues across 6 waves. Mitigation: Waves are independent. Wave 1 (traits + interview) delivers value alone. Each subsequent wave is additive.

**Agent template adoption** — The Explore → Plan → Execute → Verify issue template needs validation with real agent execution. Mitigation: Test with 2-3 real issues in a separate project before rolling out across all issue creation.

### Cross-References

- **Trait system**: BC-1942 (parent) + BC-2127, BC-2128, BC-2131 (sub-issues)
- **Interview methodology**: BC-1943
- **Context cascade**: `docs/designs/BRI-2006-context-loading-cascade.md` — project-start stage
- **Budget management**: `docs/designs/BC-2003-context-budget-management.md` — CLAUDE.md <100 line constraint
- **PRD**: `docs/designs/brite-agent-platform.md` Section 6 (Project-Start), Section 10 (Scenarios), Appendix C (Trait Combinations)
- **Current implementation**: `plugins/workflows/commands/project-start.md`
