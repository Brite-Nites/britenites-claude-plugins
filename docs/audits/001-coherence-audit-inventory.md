# Coherence Audit — Inventory & Deterministic Checks

**Issue:** BC-2461
**Methodology:** `docs/research/instruction-audit-methodology.md` (BC-2459)
**Date:** 2026-03-25

---

## 1. File Inventory

**Total instruction surface: 49 files, 10,161 lines** (excluding workflow-spec.md reference doc)

### SKILL.md Files (23 files, 4,307 lines)

| File | Lines | >200? |
|------|------:|:-----:|
| `executing-plans/SKILL.md` | 391 | YES |
| `ui-ux-pro-max/SKILL.md` | 387 | YES |
| `agent-browser/SKILL.md` | 357 | YES |
| `code-quality/SKILL.md` | 355 | YES |
| `compound-learnings/SKILL.md` | 339 | YES |
| `handbook-drift-check/SKILL.md` | 245 | YES |
| `systematic-debugging/SKILL.md` | 216 | YES |
| `best-practices-audit/SKILL.md` | 216 | YES |
| `writing-plans/SKILL.md` | 196 | |
| `brainstorming/SKILL.md` | 190 | |
| `verification-before-completion/SKILL.md` | 171 | |
| `precedent-search/SKILL.md` | 160 | |
| `git-worktrees/SKILL.md` | 155 | |
| `testing-strategy/SKILL.md` | 148 | |
| `find-skills/SKILL.md` | 134 | |
| `react-best-practices/SKILL.md` | 126 | |
| `python-best-practices/SKILL.md` | 112 | |
| `create-issues/SKILL.md` | 99 | |
| `refine-plan/SKILL.md` | 91 | |
| `setup-claude-md/SKILL.md` | 73 | |
| `post-plan-setup/SKILL.md` | 64 | |
| `frontend-design/SKILL.md` | 42 | |
| `web-design-guidelines/SKILL.md` | 40 | |

### Command Files (21 files, 4,527 lines)

| File | Lines | >200? |
|------|------:|:-----:|
| `project-start.md` | 1,086 | YES |
| `review.md` | 336 | YES |
| `promote-precedent.md` | 333 | YES |
| `retrospective.md` | 263 | YES |
| `architecture-decision.md` | 247 | YES |
| `bug-report.md` | 204 | YES |
| `session-start.md` | 190 | |
| `ship.md` | 188 | |
| `security-audit.md` | 187 | |
| `sprint-planning.md` | 186 | |
| `scope.md` | 161 | |
| `deployment-checklist.md` | 155 | |
| `flywheel-metrics.md` | 150 | |
| `onboarding-checklist.md` | 148 | |
| `audit-trail.md` | 148 | |
| `code-review.md` | 123 | |
| `tech-stack.md` | 121 | |
| `create-plugin.md` | 111 | |
| `smoke-test.md` | 70 | |
| `setup-claude-md.md` | 62 | |
| `fact-check.md` | 58 | |

### Shared Templates (5 files, 349 lines)

| File | Lines |
|------|------:|
| `commands/_shared/trait-doc-templates.md` | 398 |
| `commands/_shared/company-context-template.md` | 113 |
| `skills/_shared/observability.md` | 76 |
| `skills/_shared/output-formats.md` | 73 |
| `skills/_shared/validation-pattern.md` | 13 |

### Other (3 files)

| File | Lines | >200? |
|------|------:|:-----:|
| `CLAUDE.md` | 236 | YES |
| `docs/workflow-guide.md` | 343 | YES |
| `hooks/hooks.json` | 75 | |

### Summary

- **Files exceeding 200 lines:** 16 (8 skills, 6 commands, CLAUDE.md, workflow-guide.md)
- **Largest file:** `project-start.md` (1,086 lines)
- **Largest skill:** `executing-plans/SKILL.md` (391 lines)

---

## 2. Imperative Instruction Count

**Total strong imperatives: 352** (matches using `must`, `should`, `shall`, `never`, `always`, `do not`, `MUST`, `NEVER`, `ALWAYS`, `IMPORTANT`, `CRITICAL`)

This is above the ~150-200 effective instruction capacity (IFScale research), though instructions are distributed across files and only a subset is active per session (typically CLAUDE.md + 1-2 skills + 1 command).

Top files by imperative count:
| File | Count |
|------|------:|
| `project-start.md` | 59 |
| `review.md` | 30 |
| `executing-plans/SKILL.md` | 25 |
| `retrospective.md` | 25 |
| `compound-learnings/SKILL.md` | 23 |
| `best-practices-audit/SKILL.md` | 23 |
| `promote-precedent.md` | 23 |
| `systematic-debugging/SKILL.md` | 21 |
| `handbook-drift-check/SKILL.md` | 20 |
| `CLAUDE.md` | 13 |

---

## 3. Structural Baseline

`scripts/validate.sh` — **ALL CHECKS PASSED**
- Plugins validated: 1
- Commands: 21, Skills: 23, Agents: 15

---

## 4. Routing Table Sync

### Skills in CLAUDE.md routing tables: 16

| Table | Skills Listed |
|-------|-------------|
| Inner Loop | 10: brainstorming, precedent-search, writing-plans, git-worktrees, executing-plans, verification-before-completion, compound-learnings, best-practices-audit, handbook-drift-check, systematic-debugging |
| Backend | 1: python-best-practices |
| Design | 3: frontend-design, ui-ux-pro-max, web-design-guidelines |
| Quality | 2: testing-strategy, code-quality |

### SKILL.md files that exist: 23

### 7 skills missing from CLAUDE.md routing tables

| Missing Skill | Suggested Category | Notes |
|---------------|-------------------|-------|
| `agent-browser` | Utility | Browser automation for web testing |
| `create-issues` | Post-Plan | Creates Linear issues from refined plans |
| `find-skills` | Utility | Discovers and installs agent skills |
| `post-plan-setup` | Post-Plan | Orchestrates refine → create-issues → setup-claude-md |
| `react-best-practices` | Quality / Backend | React/Next.js performance optimization |
| `refine-plan` | Post-Plan | Refines v1 plans into agent-ready tasks |
| `setup-claude-md` | Post-Plan | Generates best-practices CLAUDE.md |

**Note:** `workflow-guide.md` lists all 23 skills across 4 sections (Inner Loop, Design, Backend & Quality, Utility, Post-Plan). CLAUDE.md is missing the Utility and Post-Plan categories entirely.

### Routing table alignment

*(Pending — see routing alignment check results)*

---

## 5. Shared Template References

`_shared/observability.md` — Referenced by 13 skills. All use relative `_shared/` paths consistently.
`_shared/validation-pattern.md` — Referenced by 9 skills. Some use `_shared/validation-pattern.md`, others use `.claude/skills/_shared/validation-pattern.md`. Path inconsistency flagged.
`_shared/output-formats.md` — Referenced by compound-learnings and best-practices-audit.

### Path inconsistency

Two skills reference validation-pattern with a different path prefix:
- `create-issues/SKILL.md:89` — `Read .claude/skills/_shared/validation-pattern.md`
- `refine-plan/SKILL.md:82` — `Read .claude/skills/_shared/validation-pattern.md`
- `setup-claude-md/SKILL.md:64` — `Read .claude/skills/_shared/validation-pattern.md`

All others use `_shared/validation-pattern.md` (relative). The `.claude/skills/` prefix assumes a specific install path that may not match.

---

## 6. Audience Classification (CLAUDE.md)

CLAUDE.md (236 lines) mixes two audiences: **runtime behavior** (what Claude should do during sessions) and **contributor documentation** (how to develop/modify the plugin).

### Runtime Sections (keep in CLAUDE.md)

| Section | Lines | Purpose |
|---------|------:|---------|
| Project Overview | 1-6 | Orientation |
| Linear Project | 8-9 | Issue scoping |
| Architecture Decisions (imports) | 12-15 | ADR pointers |
| Company Context | 16-26 | Org context |
| Plugin Philosophy | 28-31 | Design principles |
| Repository Structure | 33-52 | Codebase map |
| Skill Routing | 112-148 | What activates when |
| Review Agents | 150-170 | Agent config + overrides |
| Known Issues | 219-222 | Current limitations |
| No Build Process | 224-226 | Build expectations |

**~114 lines of runtime content.**

### Contributor Sections (extract to CONTRIBUTING.md)

| Section | Lines | Purpose |
|---------|------:|---------|
| How the Plugin System Works | 54-66 | Plugin architecture |
| Adding New Commands | 68-74 | Command authoring guide |
| SKILL.md Frontmatter Standard | 76-98 | Frontmatter schema + rules |
| Hooks (detailed descriptions) | 100-110 | Hook implementation details |
| plugin.json Schema | 172-197 | Strict schema rules |
| Adding New Plugins | 199-202 | Plugin registration |
| Testing & Validation | 204-213 | Test commands |
| ADR Convention | 215-217 | ADR process |
| CI/CD | 228-236 | CI pipeline |

**~122 lines of contributor content.**

### Hybrid Sections

- **Hooks** (100-110): The "do NOT add hooks field to plugin.json" warning is critical runtime behavior. The detailed hook descriptions are contributor docs. Split: keep warning in CLAUDE.md, move descriptions to CONTRIBUTING.md.

### Token Savings Estimate

| | Before | After |
|--|-------:|------:|
| CLAUDE.md | 236 lines | ~114 lines |
| CONTRIBUTING.md (new) | 0 lines | ~122 lines |
| **Net CLAUDE.md reduction** | | **~52% reduction** |

Target: CLAUDE.md under 120 lines (within Anthropic's <200-line guidance, ideally near 100).
