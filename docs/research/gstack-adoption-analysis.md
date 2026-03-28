# Deep gstack Architectural Analysis for Brite Adoption

**Issue:** BC-2465
**Consumes:** garrytan/gstack source (250+ files, 26 skills, 47 releases)
**Consumed by:** BC-2466 (template docs), BC-2467 (telemetry), BC-2468 (health scoring), BC-2469 (release engineering), BC-2470 (anti-slop guardrails), BC-2471 (dev iteration tooling)
**Date:** 2026-03-28

---

## 1. Current State

Brite has adopted gstack as a **reference architecture** for Claude Code plugin development. Prior research (BC-2458, BC-2459) analyzed specific subsystems — the SessionRunner testing pattern and the CLAUDE.md conflict avoidance patterns. This document completes the picture by analyzing every major gstack infrastructure pattern against Brite's actual architecture.

### What we've already adopted

| Pattern | Source | Brite Implementation | Status |
|---------|--------|---------------------|--------|
| SessionRunner subprocess | `test/helpers/session-runner.ts` | `scripts/test-behavioral.sh` | Shipped (BC-2462) |
| LLM-as-judge scoring | `test/helpers/llm-judge.ts` | `scripts/score-behavioral.sh` | Shipped (BC-2462) |
| 3-tier test model | `ARCHITECTURE.md` | Tier 1 (304 tests), Tier 2/3 (framework ready) | Shipped (BC-2462) |
| Conflict avoidance patterns | `CLAUDE.md` (309 lines) | Instruction audit methodology | Shipped (BC-2459) |

### What's missing

| Gap | Impact | gstack Solution |
|-----|--------|-----------------|
| Instruction drift across 23 skills | Conflicting shared blocks, stale content | Template-driven generation |
| Zero telemetry | Can't prioritize, can't debug usage | JSONL event logging + dashboard |
| No quality rubrics | Behavioral tests exist but lack scoring criteria | LLM-as-judge with per-skill rubrics |
| No release process | Version bumps for cache only, no changelog | VERSION file + CHANGELOG + named releases |
| No anti-slop guardrails | Output quality varies by skill | Explicit anti-pattern blacklist |
| Slow dev iteration | Edit → restart session → test | Symlink hot-reload + single-skill validation |

### Scale comparison

| Dimension | gstack | Brite |
|-----------|--------|-------|
| Skills | 26 | 23 |
| SKILL.md lines (total) | ~662 (generated) | ~4,307 (manual) |
| Command instructions | 0 (skills only) | ~4,527 (21 commands) |
| Total instruction surface | ~1,000 effective | ~9,071 |
| Shared behavior mechanism | Code generation (32 resolvers) | Convention (`_shared/`, copy-paste) |
| Test count | 400+ (3 tiers + touchfile selection) | 304 (structural) + behavioral framework |
| Releases | 47 in 18 days | No formal releases |
| Telemetry | JSONL + Supabase + dashboard | None |

---

## 2. Pattern Analysis

### 2.1 Template-Driven Skill Documentation

**gstack files:** `SKILL.md.tmpl` (per skill), `scripts/gen-skill-docs.ts` (~290 lines), `scripts/resolvers/` (7 modules, 32 resolvers), `.github/workflows/skill-docs.yml`

**How it works:** Each skill has a `.tmpl` file containing human-written prose (workflows, tips, judgment content) interspersed with `{{PLACEHOLDER}}` tags. The `gen-skill-docs.ts` pipeline reads each template, resolves placeholders by calling pure-function resolvers `(ctx: TemplateContext) => string`, and writes the final `.md` file. CI runs the generator on every push and uses `git diff --exit-code` to fail if committed files are stale.

**Key design decisions observed in source:**
- **32 resolvers** organized by domain: browse (3), preamble (2), design (8), testing (4), review (10), utility (6). Each is a pure function — no I/O, no side effects, independently testable.
- **Tiered preamble system (T1–T4):** Skills declare a `preamble-tier` in frontmatter. Higher tiers get more shared content (T1 ~100 lines, T4 ~500+ lines). This is a **context window budget optimization** — simpler skills don't waste tokens on irrelevant methodology.
- **Multi-host compilation:** Same template generates output for Claude Code and OpenAI Codex with host-specific path rewriting. Codex gets stripped frontmatter (1024-char description limit) and env-var paths instead of `~/` paths.
- **Token budget reporting:** After generation, prints a table of every skill's line count and estimated token count (~4 chars/token). First-class concern for context management.
- **Strict validation:** Unknown placeholders throw errors. Unresolved placeholders after resolution throw. No silent failures.
- **Generated header:** `<!-- AUTO-GENERATED from {source} -- do not edit directly -->` injected after frontmatter. Git blame still works on human-written sections.

**Convention-based discovery:** `scripts/discover-skills.ts` scans for `SKILL.md.tmpl` files in root + one level of subdirectories. No registry file to maintain — the filesystem IS the registry.

**Does this solve a real Brite problem?** YES — critical. Our 23 skills have ~4,307 lines of manually maintained instructions. Shared content (phase transitions, verification patterns, error handling) is copy-pasted via `_shared/` convention. Drift is inevitable and undetectable until a user reports misbehavior.

**Can we implement it in our architecture?** YES with adaptation. gstack uses Bun/TypeScript. We need a lighter approach:
- **Option A:** Pure bash (sed/awk placeholder replacement) — limited but zero-dep
- **Option B:** Minimal Node.js script — richer, and `node` is already in our CI
- **Option C:** Python script — `python3` is already a dependency (used by `validate.sh`)
- **Recommended:** Option B. Node.js is available in CI and on dev machines. A single `scripts/gen-skill-docs.mjs` (~200 lines) could handle placeholder resolution, frontmatter validation, and token budget reporting without adding `package.json` or `node_modules`.

**Minimal viable version:** Start with 5-8 shared blocks (preamble, phase transitions, verification, error handling, observability banners) extracted from `_shared/`. Template 3 inner-loop skills first. Add CI freshness check.

**Effort:** L (create gen script, define resolver functions, write templates for 23 skills, CI integration)

**Recommendation:** ADAPT — build a Node.js-based generator following gstack's architecture but scoped to our needs. Skip multi-host compilation (we only target Claude Code). Adopt tiered preamble concept to address our 9x instruction surface problem.

---

### 2.2 Skill Usage Telemetry

**gstack files:** `bin/gstack-telemetry-log` (169 lines bash), `bin/gstack-analytics` (148 lines bash), `scripts/analytics.ts` (134 lines), `test/telemetry.test.ts` (297 lines), `supabase/functions/telemetry-ingest/index.ts`

**JSONL event schema (v1):**
```json
{
  "v": 1,
  "ts": "2026-03-28T12:00:00Z",
  "event_type": "skill_run",
  "skill": "qa",
  "session_id": "12345-1710756600",
  "gstack_version": "0.13.1.0",
  "os": "darwin",
  "duration_s": 142,
  "outcome": "success",
  "error_class": null,
  "used_browse": false,
  "sessions": 1,
  "installation_id": null
}
```

**Three-tier privacy model:**

| Tier | Behavior | installation_id |
|------|----------|-----------------|
| `off` (default) | No JSONL written | N/A |
| `anonymous` | JSONL written locally only | `null` |
| `community` | JSONL + optional remote sync | Stable UUID v4 |

**Key implementation details from source:**
- **Never exits non-zero** — telemetry must never break the user's workflow. Uses `set -uo pipefail` but no `-e`.
- **Pending marker crash recovery:** Each session creates a `.pending-$SESSION_ID` file. If the skill crashes, the next invocation finalizes stale markers as `outcome: "unknown"`. Own-session markers skipped to avoid races.
- **JSON injection prevention:** `json_safe()` strips quotes, backslashes, control chars, truncates to 200 chars. Error messages get special escaping.
- **Local-only fields:** `_repo_slug` and `_branch` prefixed with `_` — never transmitted remotely.
- **Installation ID:** Generated from `uuidgen`, NOT from hostname/username (privacy fix in v0.11.16.1).
- **Analytics dashboard:** Pure bash with awk-based JSONL parsing (no `jq` dependency). ASCII bar charts, per-skill average duration, success rate.

**Does this solve a real Brite problem?** PARTIALLY. We have zero visibility into skill/command usage. But the primary value depends on having enough data to act on, and our plugin has a small user base (internal team).

**Can we implement it?** YES with constraints. gstack logs from a bash preamble that runs at skill start. Our PreToolUse hooks don't fire from plugins (upstream bug #6305). We'd need to log from commands we control (session-start, ship, review) and from the SessionStart hook.

**Minimal viable version:** Log `session_id`, `command_name`, `timestamp`, `duration_s`, `outcome` from session-start and ship commands. Store in `~/.brite-plugins/telemetry/events.jsonl`. Add a `/workflows:analytics` command to display the dashboard.

**Effort:** M (port telemetry-log bash script, adapt schema, hook into commands, build dashboard)

**Recommendation:** ADAPT — build minimal command-level telemetry first. Skip remote sync (Supabase). Skip privacy tier UI (default to anonymous-local). Add pending marker recovery from day one — it's small code with high safety value.

---

### 2.3 Health Scoring Rubrics

**gstack files:** `test/helpers/llm-judge.ts`, `test/skill-llm-eval.test.ts`, `test/helpers/eval-store.ts`

**How gstack scores:**
- **`judge()` function:** Three dimensions scored 1-5 by claude-sonnet-4-6:
  1. **Clarity** — Is the output clear and well-structured?
  2. **Completeness** — Does it cover all aspects of the task?
  3. **Actionability** — Can the user act on this output immediately?
- **`outcomeJudge()` function:** For planted-bug scenarios. Compares QA reports against ground-truth fixtures. Returns `detected[]`, `missed[]`, `false_positives`, `detection_rate`, `evidence_quality`.
- **Eval storage:** Results saved to `~/.gstack/projects/$SLUG/evals/{version}-{branch}-{tier}-{timestamp}.json`. Partial writes (`_partial` suffix) survive crashes. `compareEvalResults()` computes per-test status changes with investigation guidance.

**Does this solve a real Brite problem?** YES. Our behavioral test framework (BC-2462) can run skills and capture output, but has no scoring rubrics to evaluate quality. Without rubrics, "the skill ran and produced output" is the only assertion.

**Can we implement it?** YES. Our `scripts/score-behavioral.sh` already shells out to an LLM for scoring. We need to define per-skill rubrics with dimensions and thresholds.

**Minimal viable version:** Define 3 rubric dimensions (clarity, completeness, adherence-to-instructions) for the 10 inner-loop skills. Store rubrics in `tests/rubrics/{skill-name}.md`. Score using Haiku (cheaper than Sonnet for rubric grading). Threshold: average ≥ 3.0/5.0 to pass.

**Effort:** M (define rubrics for 10 skills, integrate with score-behavioral.sh, add regression comparison)

**Recommendation:** ADOPT — gstack's 3-dimension model works as-is. Add `adherence-to-instructions` as a Brite-specific fourth dimension (given our 9x instruction surface, this is a critical quality signal).

---

### 2.4 Anti-Slop Quality Guardrails

**gstack source:** `AI_SLOP_BLACKLIST` constant embedded in `scripts/gen-skill-docs.ts`. Injected into skills via the preamble resolver system.

**The 10 anti-patterns (from source):**
gstack defines explicit output anti-patterns that skills must avoid. These are embedded as constants in the generation pipeline and injected into every skill's preamble. The patterns cover common LLM output quality issues: vague hedging language, unnecessary caveats, filler phrases, circular definitions, and format-over-substance patterns.

**Does this solve a real Brite problem?** YES. Review agents frequently flag output quality issues, and compound-learnings captures feedback about skill verbosity and hedging. An explicit blacklist makes quality standards machine-checkable.

**Can we implement it?** YES — trivially. Create `skills/_shared/anti-slop.md` with the anti-pattern list. Reference it from skills via the existing `_shared/` convention. When template generation (BC-2466) ships, migrate to a resolver.

**Minimal viable version:** Create the anti-pattern list, add it to the 10 inner-loop skills' SKILL.md files, validate via the instruction coherence test.

**Effort:** S

**Recommendation:** ADOPT — nearly 1:1. Change delivery mechanism from code constant to markdown shared block. This has the best effort/benefit ratio of any pattern.

---

### 2.5 Release Engineering

**gstack files:** `VERSION` (single line: `0.13.1.0`), `CHANGELOG.md` (1,433 lines, 47 releases)

**Release note format (from source):**
```markdown
## [0.13.1.0] - 2026-03-28 — Defense in Depth

<1-2 sentence narrative hook>

### Fixed
- **Bold headline.** Details in plain language.

### Added
- **Bold headline.** Details.

### Changed
- **Bold headline.** Details.

### For contributors
- Internal details separated from user-facing content.
```

**Key conventions observed:**
- **User-first language:** "You can now..." not "Refactored the..."
- **Named releases:** Major releases get a subtitle (e.g., "Your Agent Can Design Now")
- **Contributor section:** Internal details (test counts, resolver changes) go at the bottom, never in the main body
- **4-part semver:** `MAJOR.MINOR.PATCH.BUILD`. Build for hotfixes.
- **Branch-scoped entries:** Written at ship time, never folded into a prior release
- **TODOS.md integration:** Completed items get `— SHIPPED` suffix with version and date
- **Release velocity:** 47 releases in 18 days (2.6/day) — enabled by the structured format

**Does this solve a real Brite problem?** YES. Our version bumps are for cache invalidation only. No changelog means no record of what changed between versions, making regression debugging harder and user communication impossible.

**Can we implement it?** YES. Plain text files, no tooling required.

**Minimal viable version:** Create `VERSION` (3-part semver: `major.minor.patch`), create `CHANGELOG.md` with the format above, add version bump + changelog entry to the `/workflows:ship` command. Skip 4-part semver (we don't have hotfix branches). Skip named releases until we have enough cadence.

**Effort:** S

**Recommendation:** ADAPT — adopt the CHANGELOG format and VERSION file. Use 3-part semver instead of 4-part. Integrate into `/workflows:ship` so entries are written automatically at ship time. Skip TODOS.md integration (we use Linear).

---

### 2.6 Dev Iteration Tooling

**gstack files:** `bin/dev-setup` (52 lines bash), `bin/dev-teardown` (42 lines bash)

**How gstack's dev workflow works:**
1. `dev-setup`: Copies `.env`, runs `bun install`, creates `.claude/skills/` in repo, symlinks `.claude/skills/gstack` → repo root. Skill changes are **immediately live** — no copy/deploy needed.
2. `dev-teardown`: Removes all symlinks, restores global install as active.
3. Combined with `gen-skill-docs.ts --dry-run`: Edit template → regenerate → test immediately.

**Does this solve a real Brite problem?** MARGINALLY. Our edit cycle is: edit SKILL.md → restart Claude session → test. The restart is the bottleneck, and symlinks don't eliminate it (Claude reads SKILL.md at session start regardless). The real speedup would be single-skill validation.

**Can we implement it?** YES. `validate.sh` already validates the entire plugin. A `--skill <name>` flag would allow single-skill validation in <1s instead of ~5s.

**Minimal viable version:** Add `--skill <name>` flag to `validate.sh` for single-skill runs. Skip symlink management (our plugin directory structure is already discoverable).

**Effort:** S

**Recommendation:** ADAPT — build single-skill validation, skip symlink management. The ROI of symlinks is low in our architecture since Claude re-reads skills at session start anyway.

---

## 3. Mapping Table

| gstack Component | File(s) | Brite Equivalent | Gap |
|-----------------|---------|-----------------|-----|
| Template generation | `gen-skill-docs.ts` | None (manual SKILL.md) | Full pipeline needed |
| 32 resolvers | `scripts/resolvers/*.ts` | `skills/_shared/*.md` (copy-paste) | Need code-based injection |
| Tiered preamble | `preamble.ts` (T1–T4) | None | Addresses 9x instruction surface |
| CI freshness | `skill-docs.yml` | None | Add after gen pipeline |
| Convention discovery | `discover-skills.ts` | `plugin.json` registry | Already solved differently |
| Telemetry logging | `gstack-telemetry-log` | None | Port bash script |
| Analytics dashboard | `gstack-analytics` | None | Port bash script |
| Privacy tiers | 3-tier in telemetry-log | None | Adopt for telemetry |
| Pending markers | Crash recovery in telemetry | None | Adopt for robustness |
| LLM-as-judge | `llm-judge.ts` | `score-behavioral.sh` | Need rubric definitions |
| Eval storage | `eval-store.ts` | `tests/evals/` (framework ready) | Need comparison logic |
| Anti-slop blacklist | `AI_SLOP_BLACKLIST` constant | None | Create `_shared/anti-slop.md` |
| VERSION file | `VERSION` | None | Create VERSION file |
| CHANGELOG | `CHANGELOG.md` (1,433 lines) | None | Create CHANGELOG.md |
| Dev setup/teardown | `bin/dev-setup`, `bin/dev-teardown` | None | Single-skill validate flag |
| Multi-host output | Claude + Codex from same .tmpl | N/A | Not needed (Claude only) |
| Diff-based test selection | `touchfiles.ts` | N/A | Premature for our test count |
| Token budget reporting | In gen-skill-docs.ts | None | Fold into gen pipeline |
| Conductor sessions | `conductor.json` | None | Similar to worktree lifecycle |

---

## 4. Validated Adoption List (Ranked by ROI)

| Rank | Pattern | Issue | Recommendation | Effort | Benefit | ROI |
|------|---------|-------|----------------|--------|---------|-----|
| 1 | Template-driven docs | BC-2466 | ADAPT | L | High | High |
| 2 | Anti-slop guardrails | BC-2470 | ADOPT | S | Medium | High |
| 3 | Health scoring rubrics | BC-2468 | ADOPT | M | Medium-High | Medium-High |
| 4 | Release engineering | BC-2469 | ADAPT | S | Medium | Medium-High |
| 5 | Skill usage telemetry | BC-2467 | ADAPT | M | Medium | Medium |
| 6 | Dev iteration tooling | BC-2471 | ADAPT | S | Low | Low |

**Recommended execution order:** 2 → 4 → 1 → 3 → 5 → 6

Rationale: Start with anti-slop (S, immediate quality win) and release engineering (S, enables tracking). Then tackle templates (L, structural fix — the most impactful but most effort). Health scoring builds on the completed behavioral test framework. Telemetry and dev tooling are nice-to-haves.

---

## 5. Implementation Sketches

### BC-2466: Template-Driven Documentation Pipeline

```
scripts/gen-skill-docs.mjs          # Node.js generator (~200 lines)
scripts/resolvers/                   # Pure functions, one per shared block
  preamble.mjs                       # Phase transitions, verification, error handling
  observability.mjs                  # Observability banners, completion markers
  shared-rules.mjs                   # Anti-slop, behavioral rules
skills/brainstorming/SKILL.md.tmpl   # Human prose + {{PREAMBLE}} + {{PHASE_TRANSITION}}
```

**Generator architecture:**
1. Scan for `*.tmpl` files (convention-based, like gstack's `discover-skills.ts`)
2. Read template, find `{{PLACEHOLDER}}` patterns
3. Call resolver functions for each placeholder
4. Write output `.md` with `<!-- AUTO-GENERATED -->` header
5. `--dry-run` mode for CI: compare output to committed file, exit non-zero if stale
6. Token budget report: print lines + estimated tokens per skill

**CI integration:** Add to existing `validate.sh` or create `.github/workflows/skill-docs.yml` that runs `node scripts/gen-skill-docs.mjs --dry-run` and `git diff --exit-code`.

### BC-2470: Anti-Slop Guardrails

Create `skills/_shared/anti-slop.md` with 10-15 output anti-patterns. Reference from inner-loop skills. When BC-2466 ships, convert to a resolver that injects the list into every skill's preamble.

### BC-2468: Health Scoring Rubrics

Create `tests/rubrics/{skill-name}.md` files with 3-4 scoring dimensions (clarity, completeness, actionability, adherence-to-instructions) and per-skill criteria. Integrate with existing `scripts/score-behavioral.sh`. Add `compareEvalResults()` logic for regression detection between runs.

### BC-2469: Release Engineering

Create `VERSION` (initial: `1.0.0`). Create `CHANGELOG.md` with gstack's format. Modify `/workflows:ship` to prompt for changelog entry and bump VERSION. Add git tag on version bump.

### BC-2467: Skill Usage Telemetry

Port `bin/gstack-telemetry-log` to `scripts/telemetry-log.sh`. Adapt event schema for Brite (add `command` field, remove `used_browse`). Hook into `session-start` and `ship` commands. Create `/workflows:analytics` command with awk-based dashboard. Default privacy tier: `anonymous` (local only).

### BC-2471: Dev Iteration Tooling

Add `--skill <name>` and `--command <name>` flags to `validate.sh` for single-artifact validation. Skip symlink management.

---

## 6. Dropped Patterns

| Pattern | Why it looked good | Why it doesn't fit |
|---------|-------------------|-------------------|
| Multi-host compilation | Generates for Claude + Codex from same template | We only target Claude Code. No Codex/Gemini support planned. |
| Diff-based test selection | Saves CI time by only running affected tests | We have ~304 structural tests running in <5s. Premature optimization. Revisit when test suite exceeds 60s. |
| Convention-based discovery | Scan for .tmpl files, no registry | We already have `plugin.json` as a registry. Adding a second discovery mechanism creates confusion. |
| Conductor sessions | Project lifecycle with setup/teardown | Our `git-worktrees` skill already handles workspace lifecycle. Conductor is gstack-specific project management. |
| Remote telemetry sync | Supabase edge functions for community analytics | We're a small internal team. Local-only telemetry is sufficient. Revisit if/when we open-source. |
| Voice directive system | ~70 lines encoding Garry Tan's personal voice/tone | Highly personal to gstack's author. Brite's voice comes from the handbook, not a code constant. |

---

## 7. Surprises

### 7.1 Tiered Preamble System (Not in any downstream issue)

The most impactful pattern not captured by any existing issue. gstack skills declare a `preamble-tier` (1-4) in frontmatter, and the generator injects proportional shared content. T1 skills (simple browser commands) get ~100 lines of preamble. T4 skills (ship, review) get ~500+ lines including methodology sections.

**Why this matters for Brite:** Our total instruction surface is 9,071 lines vs gstack's ~1,000. The primary reason is that every Brite skill gets ALL shared content regardless of whether it needs it. A tiered system would let simple skills (agent-browser, find-skills) carry minimal preamble while complex skills (executing-plans, brainstorming) get the full methodology.

**Recommendation:** Create a new issue to implement tiered preamble as part of BC-2466 (template pipeline). This is the single highest-impact change for reducing our context window consumption.

### 7.2 Token Budget Reporting

`gen-skill-docs.ts` prints a token budget table after every generation run. This makes context window usage a **first-class engineering concern** — developers see exactly how many tokens each skill consumes.

**Recommendation:** Fold into BC-2466. Add token estimation (lines × 4) to the generation report. Consider adding a budget cap per tier.

### 7.3 Release Velocity Enabled by Structure

gstack shipped 47 releases in 18 days (2.6/day). This velocity is enabled by the structured CHANGELOG format — entries are formulaic enough to write quickly but informative enough to be useful. The "user-first, contributor-second" split means release notes serve both audiences without compromise.

**Recommendation:** Adopt the format in BC-2469. The velocity benefit compounds over time.

### 7.4 Effort Compression Tables

gstack's ETHOS.md defines a "Golden Age" compression ratio table: 100x for boilerplate, 50x for tests, 10x for design, 3x for research. These ratios appear throughout the codebase (CHANGELOG effort estimates, TODOS.md sizing, SKILL.md output). It's a shared vocabulary for estimation.

**Recommendation:** Consider adopting in the handbook as a standard estimation reference. Not a code change — a process change.

### 7.5 "Boil the Lake" Principle

gstack's core philosophy: when marginal cost is near-zero (AI-assisted work), implement completely rather than leaving gaps. The counterpoint: distinguish "lakes" (completeable) from "oceans" (unbounded). Anti-patterns include "Choose B — it covers 90% with less code."

**Recommendation:** Already partially adopted in our "verification-before-completion" skill. No code change needed, but worth documenting as a principle.

### 7.6 Guardrail Testing (Negative Assertions)

gstack's E2E tests include **negative behavior assertions** — verifying skills DON'T do things. Examples from `test/skill-e2e.test.ts`:
- `/qa-only` asserts `editCalls.length === 0` and git working tree is clean (QA must never fix bugs)
- `/document-release` asserts CHANGELOG is not clobbered when updating other docs
- `/ship` asserts no destructive git operations

This is a distinct testing pattern from positive assertions. Most test frameworks only check "did the skill produce correct output?" Guardrail tests check "did the skill respect its boundaries?"

**Recommendation:** Add guardrail test cases to our behavioral test framework (BC-2462). Define 3-5 negative assertions for inner-loop skills (e.g., `brainstorming` must not write code, `executing-plans` must not skip verification checkpoints).

---

## 8. Effort Estimates

| Issue | Pattern | Size | Estimated Effort | Dependencies | Priority |
|-------|---------|------|-----------------|--------------|----------|
| BC-2470 | Anti-slop guardrails | S | 2-3 hours | None | P2 |
| BC-2469 | Release engineering | S | 3-4 hours | None | P3 |
| BC-2471 | Dev iteration tooling | S | 2-3 hours | None | P4 |
| BC-2468 | Health scoring rubrics | M | 6-8 hours | BC-2462 (done) | P2 |
| BC-2467 | Skill usage telemetry | M | 8-12 hours | None | P3 |
| BC-2466 | Template-driven docs | L | 16-24 hours | None (but benefits from BC-2470 first) | P1 |

**Total milestone effort:** ~40-55 hours across 6 issues.

**Recommended sprint allocation:**
- Sprint 1: BC-2470 (S) + BC-2469 (S) — quick wins, establish quality baseline
- Sprint 2: BC-2466 (L) — structural fix, highest long-term ROI
- Sprint 3: BC-2468 (M) + BC-2467 (M) — quality measurement + observability
- Sprint 4: BC-2471 (S) — dev ergonomics polish

---

## Sources

| Source | URL/Path | What we used |
|--------|----------|--------------|
| gstack source | github.com/garrytan/gstack | Full tree (250+ files), 26 skills |
| gen-skill-docs.ts | `scripts/gen-skill-docs.ts` (~290 lines) | Template pipeline architecture, resolver pattern, token budget |
| 32 resolvers | `scripts/resolvers/*.ts` (7 modules) | Pure function pattern, domain organization, shared content injection |
| SKILL.md.tmpl | Per-skill template files | Placeholder syntax, frontmatter schema, tiered preamble |
| gstack-telemetry-log | `bin/gstack-telemetry-log` (169 lines bash) | JSONL schema v1, privacy tiers, pending markers, JSON injection prevention |
| gstack-analytics | `bin/gstack-analytics` (148 lines bash) | awk-based dashboard, zero-dependency approach |
| CHANGELOG.md | `CHANGELOG.md` (1,433 lines, 47 releases) | Release note format, named releases, contributor section |
| VERSION | `VERSION` (single line) | Version file format |
| ARCHITECTURE.md | `ARCHITECTURE.md` (~400 lines) | Three-tier test model, template system rationale |
| ETHOS.md | `ETHOS.md` (101 lines) | Boil the Lake, effort compression, search before building |
| dev-setup/teardown | `bin/dev-setup` (52 lines), `bin/dev-teardown` (42 lines) | Symlink hot-reload pattern |
| CLAUDE.md | `CLAUDE.md` (309 lines) | Section structure, conflict avoidance, test tiers |
| telemetry.test.ts | `test/telemetry.test.ts` (297 lines) | JSON injection tests, pending marker tests, analytics tests |
| skill-docs.yml | `.github/workflows/skill-docs.yml` | CI freshness check pattern |
| Brite behavioral-testing-evaluation | `docs/research/behavioral-testing-evaluation.md` | Prior gstack analysis (SessionRunner, LLM-as-judge) |
| Brite instruction-audit-methodology | `docs/research/instruction-audit-methodology.md` | Prior gstack analysis (CLAUDE.md patterns, scale comparison) |
