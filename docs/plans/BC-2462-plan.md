# BC-2462: Build Runtime Behavioral Test Framework

**Issue:** [BC-2462](https://linear.app/brite-nites/issue/BC-2462)
**Research:** `docs/research/behavioral-testing-evaluation.md` (BC-2458)
**Branch:** `holden/bc-2462-build-runtime-behavioral-test-framework-gstack-inspired`
**Milestone:** Plugin Quality & Testing Infrastructure

---

## Scope

Build the Tier 2 (behavioral) and Tier 3 (LLM-as-judge) test framework. Tier 1 structural tests already exist. Cross-skill contract validation (BC-2463) and instruction coherence (BC-2461, done) are separate issues.

**Deliverables:**
1. `scripts/test-behavioral.sh` — Tier 2 integration test runner
2. `scripts/score-behavioral.sh` — Tier 3 LLM-as-judge scoring
3. `tests/fixtures/behavioral-registry.json` — Seed test cases (10)
4. `.github/workflows/behavioral-tests.yml` — CI workflow (manual + scheduled)
5. Documentation update in `docs/testing-guide.md`

**Out of scope:** Skillgrade eval.yaml files (deferred — tool is unverified and per-skill evals are a follow-on task), Promptfoo migration, expanding beyond 10 seed cases.

---

## Tasks

### Task 1: Create test directory structure
**Files:** `tests/evals/.gitkeep`, `tests/rubrics/.gitkeep`
**Do:**
- Create `tests/evals/` (future: per-skill eval results)
- Create `tests/rubrics/` (future: LLM-as-judge rubric templates)
- The `tests/fixtures/` directory already exists (has `scenario-registry.json`)
**Verify:** `ls tests/` shows `evals/`, `fixtures/`, `rubrics/`
**Time:** ~1 min

### Task 2: Create behavioral-registry.json fixture
**Files:** `tests/fixtures/behavioral-registry.json`
**Do:**
- Implement the 10 seed test cases from research doc Section 7
- Schema: `{ id, description, tier, prompt, expected_skill, expected_markers, not_expected_markers, not_expected_skills, judge_rubric, estimated_cost, notes }`
- Cover: activation (B01, B03, B04, B05, B08), non-activation (B02, B09), precedence (B06, B07), quality (B10)
- Use full prompts that are realistic (not toy examples)
**Verify:** `python3 -m json.tool tests/fixtures/behavioral-registry.json` succeeds; 10 test cases present
**Time:** ~5 min

### Task 3: Build test-behavioral.sh runner (Tier 2)
**Files:** `scripts/test-behavioral.sh`
**Do:**
- Follow existing `pass()`/`fail()`/`section()` pattern from `validate.sh`
- Guard: `EVALS=1` env var required (abort with message if unset)
- Guard: must be outside Claude session (`CLAUDE_SESSION_ID` check)
- Guard: `claude` CLI must be available
- Guard: `jq` must be available
- Read test cases from `tests/fixtures/behavioral-registry.json` via `jq`
- For each test case:
  1. Run `claude --plugin-dir ./plugins/workflows -p --model "${EVALS_MODEL:-claude-sonnet-4-6}" "$prompt"` with timeout
  2. Check `expected_markers` (case-insensitive grep, all must match)
  3. Check `not_expected_markers` (none should match)
  4. Check `expected_skill` via activation banner pattern `**SkillName** activated`
  5. Check `not_expected_skills` (no activation banner for these)
  6. Track pass/fail per assertion
- Non-determinism: Run each test `${EVALS_TRIALS:-1}` times. Pass if `≥80%` of trials pass.
- Cost tracking: Log estimated cost per test from fixture, sum total at end.
- Output results JSON to `tests/evals/behavioral-${timestamp}.json`
- Summary: total tests, passed, failed, estimated cost, duration
**Verify:** `EVALS=1 bash scripts/test-behavioral.sh --dry-run` parses all fixtures without invoking Claude
**Time:** ~15 min

### Task 4: Build score-behavioral.sh (Tier 3 LLM-as-judge)
**Files:** `scripts/score-behavioral.sh`
**Do:**
- Reads the latest results file from `tests/evals/behavioral-*.json`
- For each test case with `judge_rubric` (non-null):
  1. Extract the captured output from the results JSON
  2. Call Anthropic API via `curl` with Haiku model
  3. Rubric prompt: score clarity (1-5), completeness (1-5), actionability (1-5)
  4. Parse JSON response, compare against thresholds from fixture
- Guard: `ANTHROPIC_API_KEY` must be set
- Guard: `jq` must be available
- Output: append scores to the results JSON file
- Summary: per-test scores, average scores, pass/fail against threshold
**Verify:** `bash scripts/score-behavioral.sh --help` shows usage
**Time:** ~10 min

### Task 5: Create CI workflow
**Files:** `.github/workflows/behavioral-tests.yml`
**Do:**
- Triggers: `workflow_dispatch` (manual), schedule `0 6 * * 1,4` (Mon+Thu 6am UTC)
- Environment: `ANTHROPIC_API_KEY` from secrets, `EVALS=1`
- Job 1: `behavioral` — checkout, run `test-behavioral.sh`
- Job 2: `scoring` (needs: behavioral) — run `score-behavioral.sh`
- Upload `tests/evals/behavioral-*.json` as artifact for regression comparison
- Budget safeguard note in workflow comment
**Verify:** YAML is valid (`python3 -c "import yaml; yaml.safe_load(open(...))"` or manual check)
**Time:** ~5 min

### Task 6: Add --dry-run mode to test-behavioral.sh
**Files:** `scripts/test-behavioral.sh` (update)
**Do:**
- `--dry-run` flag: parse all fixtures, validate JSON, print test plan, but skip `claude -p` invocations
- `--list` flag: print test case IDs and descriptions only
- `--filter <id>` flag: run only the specified test case (e.g., `--filter B01`)
- These flags make the framework usable without spending money
**Verify:** `EVALS=1 bash scripts/test-behavioral.sh --dry-run` runs cleanly
**Time:** ~5 min (part of Task 3 implementation)

### Task 7: Update testing documentation
**Files:** `docs/testing-guide.md` (update existing)
**Do:**
- Add "Tier 2: Behavioral Tests" section
- Add "Tier 3: LLM-as-Judge Scoring" section
- Document: how to run (`EVALS=1 bash scripts/test-behavioral.sh`), how to add test cases, cost expectations
- Document: `--dry-run`, `--list`, `--filter` flags
- Document: CI workflow schedule and manual trigger
- Reference research doc for architectural decisions
**Verify:** New sections are coherent with existing doc structure
**Time:** ~5 min

### Task 8: Regression check — all existing tests pass
**Files:** None (read-only)
**Do:**
- Run `bash scripts/validate.sh`
- Run `bash scripts/test-hooks.sh`
- Run `bash scripts/test-skill-triggers.sh`
- Run `bash scripts/test-scenarios.sh`
- All must pass with 0 failures
**Verify:** All 4 scripts exit 0
**Time:** ~2 min

### Task 9: End-to-end validation
**Files:** None
**Do:**
- Run `EVALS=1 bash scripts/test-behavioral.sh --dry-run` — validates fixture parsing
- Run `EVALS=1 bash scripts/test-behavioral.sh --list` — lists all 10 test cases
- Verify results JSON format is valid
- If time/budget allows: run 1-2 actual test cases with `--filter B02` (cheapest: non-activation test)
**Verify:** Dry-run produces expected output, list shows 10 cases
**Time:** ~3 min

---

## Execution Order

Tasks 1-2 are independent (parallel).
Task 3 depends on Task 2 (reads fixture).
Task 6 is part of Task 3 (built together).
Task 4 depends on Task 3 (reads results JSON).
Task 5 depends on Tasks 3+4 (references both scripts).
Task 7 depends on Tasks 3+4+5 (documents them).
Task 8 is independent (can run anytime).
Task 9 depends on Tasks 3+6 (validates the framework).

```
[1] + [2] → [3+6] → [4] → [5] → [7] → [9]
                                    [8] ↗
```

## Test/Build/Lint Commands

- Validate: `bash scripts/validate.sh`
- Hooks: `bash scripts/test-hooks.sh`
- Triggers: `bash scripts/test-skill-triggers.sh`
- Scenarios: `bash scripts/test-scenarios.sh`
- Behavioral (dry): `EVALS=1 bash scripts/test-behavioral.sh --dry-run`
- Behavioral (live): `EVALS=1 bash scripts/test-behavioral.sh`
- Scoring: `bash scripts/score-behavioral.sh`

## Risk Notes

- **Skillgrade deferred:** The tool is unverified (March 2026, not on npm/Context7). Per-skill eval.yaml files are a follow-on task once availability is confirmed. The custom bash framework is the primary deliverable.
- **Cost:** Live behavioral tests cost ~$2-5 per run. Dry-run mode allows development without spending.
- **Non-determinism:** Tests may flicker with 1 trial. Default is 1 trial for speed; use `EVALS_TRIALS=5` for reliable results.
- **Claude CLI required:** Tests need `claude` CLI installed. CI will need it too (or skip behavioral tests in environments without it).
