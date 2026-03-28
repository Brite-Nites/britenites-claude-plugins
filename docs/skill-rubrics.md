# Skill Health Scoring Rubrics

Quantitative evaluation of skill output quality using LLM-as-judge. Each inner-loop skill has a rubric file defining scoring dimensions, 1-5 anchor scales, and pass thresholds.

## Dimensions

| Dimension | What It Measures | Why |
|-----------|-----------------|-----|
| **Clarity** | Organization, readability, scannability | Agents and humans must parse output quickly |
| **Completeness** | Coverage of requirements, depth | Incomplete output causes downstream failures |
| **Actionability** | Concrete next steps, executable output | Output that can't be acted on has no value |
| **Adherence** | Protocol compliance, artifact production | Brite skills have 9x the instruction surface of typical agents — compliance is a critical quality signal |

The first three dimensions come from [gstack's LLM-as-judge pattern](https://github.com/garrytan/gstack). Adherence-to-instructions is Brite-specific (see `docs/research/gstack-adoption-analysis.md` Section 2.3).

## Scoring Scale

| Score | Meaning |
|-------|---------|
| 1 | Unacceptable — fails basic expectations |
| 2 | Below expectations — significant gaps |
| 3 | Meets minimum bar — acceptable but improvable |
| 4 | Good — meets expectations clearly |
| 5 | Excellent — exceeds expectations |

## Pass Criteria

Both conditions must be met for an overall PASS:

1. **Per-dimension**: Each dimension score >= its threshold (defined in rubric YAML)
2. **Overall average**: Weighted average of all dimension scores >= `pass_threshold` (default: 3.0)

## Rubric Files

Location: `tests/rubrics/{skill-name}.md`

### Format

```markdown
---
skill: brainstorming
version: "1.0"
pass_threshold: 3.0
dimensions:
  - name: clarity
    weight: 1.0
    threshold: 4
  - name: completeness
    weight: 1.0
    threshold: 4
  - name: actionability
    weight: 1.0
    threshold: 4
  - name: adherence
    weight: 1.0
    threshold: 3
---

# {Skill Name} Rubric

## Clarity (1-5)
{1-5 anchor table}

## Completeness (1-5)
{1-5 anchor table}
### Skill-Specific Completeness Criteria
{Checklist}

## Actionability (1-5)
{1-5 anchor table}

## Adherence to Instructions (1-5)
{1-5 anchor table}
### Skill-Specific Instruction Criteria
{Checklist}
```

The YAML frontmatter is machine-parsed by `scripts/_lib/parse_rubric.py`. The markdown body is included verbatim in the LLM judge prompt.

### Available Rubrics

Run `bash scripts/score-skill-output.sh --list` or check `tests/rubrics/`:

- `brainstorming` — Design exploration and Socratic discovery
- `precedent-search` — Past decision trace search
- `writing-plans` — Task breakdown and planning
- `git-worktrees` — Workspace isolation setup
- `executing-plans` — Subagent-per-task execution
- `verification-before-completion` — 4-level verification protocol
- `compound-learnings` — Knowledge capture and CLAUDE.md updates
- `best-practices-audit` — CLAUDE.md compliance audit
- `handbook-drift-check` — Handbook staleness detection
- `systematic-debugging` — 4-phase root cause analysis

## Usage

### Ad-hoc scoring

Score any skill output against its rubric:

```bash
# From file
bash scripts/score-skill-output.sh --skill brainstorming --input output.txt

# From stdin
echo "some output" | bash scripts/score-skill-output.sh --skill writing-plans --input -

# JSON output
bash scripts/score-skill-output.sh --skill brainstorming --input output.txt --format json
```

Exit code: 0 = PASS, 1 = FAIL.

### Pipeline scoring (behavioral tests)

`score-behavioral.sh` automatically uses per-skill rubrics when a `rubric_file` field is present in the test case (or falls back to `expected_skill` name). Tests without a matching rubric file use the legacy 3-dimension hardcoded prompt.

```bash
EVALS=1 bash scripts/test-behavioral.sh     # run behavioral tests
bash scripts/score-behavioral.sh              # score with rubrics
```

## Writing a New Rubric

1. Read the skill's `SKILL.md` — identify phases, artifacts, rules
2. Copy an existing rubric (e.g., `tests/rubrics/brainstorming.md`) as template
3. Customize anchor tables where the generic text is insufficient for the skill
4. Write skill-specific criteria checklists under Completeness and Adherence
5. Set thresholds conservatively (start at 3-4, raise after calibration data)
6. Verify: `python3 scripts/_lib/parse_rubric.py tests/rubrics/your-skill.md --meta | jq .`

## Calibration

Initial thresholds are conservative. After 3-5 CI runs with real behavioral test data, adjust based on observed score distributions. Scored results are uploaded as CI artifacts (90-day retention) in `.github/workflows/behavioral-tests.yml`.

## Architecture

```
tests/rubrics/{skill}.md          ← Rubric definitions (human + LLM readable)
scripts/_lib/parse_rubric.py      ← YAML frontmatter parser (Python 3 stdlib)
scripts/_lib/rubric-helpers.sh    ← Shared bash functions (load, prompt, parse, API)
scripts/score-skill-output.sh     ← Ad-hoc scorer (standalone)
scripts/score-behavioral.sh       ← Pipeline scorer (reads behavioral test results)
```
