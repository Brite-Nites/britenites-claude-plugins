#!/usr/bin/env bash
set -euo pipefail

# ── Behavioral Scorer (Tier 3 — LLM-as-Judge) ───────────────────────
# Reads the latest behavioral test results and scores outputs using
# an LLM judge (Haiku). Uses per-skill rubric files from tests/rubrics/
# when available (4 dimensions: clarity, completeness, actionability,
# adherence). Falls back to hardcoded 3-dimension scoring otherwise.
#
# Usage:
#   bash scripts/score-behavioral.sh                   # score latest results
#   bash scripts/score-behavioral.sh results-file.json # score specific file
#   bash scripts/score-behavioral.sh --help
#
# Environment:
#   ANTHROPIC_API_KEY     Required. API key for scoring calls.
#   JUDGE_MODEL           Model for judging (default: claude-haiku-4-5-20251001)
# ─────────────────────────────────────────────────────────────────────

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RESULTS_DIR="$REPO_ROOT/tests/evals"
JUDGE_MODEL="${JUDGE_MODEL:-claude-haiku-4-5-20251001}"

# ── Load rubric helpers ─────────────────────────────────────────────
source "$REPO_ROOT/scripts/_lib/rubric-helpers.sh"

# ── Counters & helpers ───────────────────────────────────────────────
scored=0
passed=0
failed=0

pass()    { printf "  \033[32mPASS\033[0m  %s\n" "$1"; passed=$((passed + 1)); }
fail()    { printf "  \033[31mFAIL\033[0m  %s\n" "$1"; failed=$((failed + 1)); }
section() { printf "\n\033[1m=== %s ===\033[0m\n" "$1"; }

usage() {
  printf "Usage: bash %s [results-file.json]\n\n" "$0"
  printf "Scores behavioral test outputs using LLM-as-judge.\n"
  printf "Reads the latest file in tests/evals/ if no file is specified.\n\n"
  printf "Environment:\n"
  printf "  ANTHROPIC_API_KEY   Required. API key for Anthropic API.\n"
  printf "  JUDGE_MODEL         Judge model (default: claude-haiku-4-5-20251001)\n"
  exit 0
}

# ── Parse args ───────────────────────────────────────────────────────
RESULTS_FILE=""

if [[ "${1:-}" == "--help" ]]; then
  usage
fi

if [[ -n "${1:-}" ]]; then
  RESULTS_FILE="$1"
else
  # Find latest results file
  RESULTS_FILE=$(ls -t "$RESULTS_DIR"/behavioral-*.json 2>/dev/null | head -1 || true)
fi

# ── Guards ───────────────────────────────────────────────────────────
if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  printf "ERROR: ANTHROPIC_API_KEY must be set.\n"
  exit 2
fi

if ! command -v jq &>/dev/null; then
  printf "ERROR: 'jq' is required. Install: brew install jq\n"
  exit 2
fi

if ! command -v curl &>/dev/null; then
  printf "ERROR: 'curl' is required.\n"
  exit 2
fi

if [[ -z "$RESULTS_FILE" ]] || [[ ! -f "$RESULTS_FILE" ]]; then
  printf "ERROR: No results file found.\n"
  printf "Run test-behavioral.sh first, or pass a results file path.\n"
  exit 2
fi

# ── Load results ─────────────────────────────────────────────────────
result_count=$(jq '.results | length' "$RESULTS_FILE")
model_used=$(jq -r '.model' "$RESULTS_FILE")

echo "Brite Plugin — Behavioral Scorer (Tier 3)"
echo "Results:  $RESULTS_FILE"
echo "Judge:    $JUDGE_MODEL"
echo "Entries:  $result_count"
echo "Model:    $model_used"
echo ""

# ── Score each result with a rubric ──────────────────────────────────
score_entries=()

for i in $(seq 0 $((result_count - 1))); do
  id=$(jq -r ".results[$i].id" "$RESULTS_FILE")
  status=$(jq -r ".results[$i].status" "$RESULTS_FILE")
  has_rubric=$(jq ".results[$i].has_rubric" "$RESULTS_FILE")
  output=$(jq -r ".results[$i].output // \"\"" "$RESULTS_FILE")

  # Try to resolve a rubric file early (before gate) so we can score
  # tests that have a rubric file but no inline judge_rubric
  rubric_skill=$(jq -r ".results[$i].rubric_file // .results[$i].expected_skill // \"\"" "$RESULTS_FILE")
  has_rubric_file=false
  if [[ -n "$rubric_skill" ]] && [[ "$rubric_skill" != "null" ]] && [[ -f "${RUBRIC_DIR}/${rubric_skill}.md" ]]; then
    has_rubric_file=true
  fi

  # Skip entries without any rubric (inline or file) or without output
  if [[ "$has_rubric" != "true" ]] && [[ "$has_rubric_file" != true ]]; then
    continue
  fi
  if [[ -z "$output" ]] || [[ "$output" == "null" ]]; then
    continue
  fi

  if [[ "$status" == "skipped" ]]; then
    continue
  fi

  section "$id: Scoring output quality"
  scored=$((scored + 1))

  desc=$(jq -r ".results[$i].description // \"Test $id\"" "$RESULTS_FILE")

  # Try to load a per-skill rubric file
  use_rubric_file=false
  if [[ "$has_rubric_file" == true ]] && load_rubric "$rubric_skill" 2>/dev/null; then
    use_rubric_file=true
    printf "  Rubric:        %s (%d dimensions)\n" "$rubric_skill" "$RUBRIC_DIM_COUNT"
  fi

  if [[ "$use_rubric_file" == true ]]; then
    # ── Rubric-based scoring (per-skill rubric file) ──────────────
    judge_prompt=$(build_judge_prompt "$desc" "$output")

    if ! call_judge_api "$judge_prompt"; then
      printf "  \033[33mAPI ERROR\033[0m HTTP %s\n" "$JUDGE_HTTP_CODE"
      fail "$id: API call failed (HTTP $JUDGE_HTTP_CODE)"
      continue
    fi

    judge_json=$(printf '%s' "$JUDGE_TEXT" | parse_judge_response)
    reasoning=$(printf '%s' "$judge_json" | jq -r '.reasoning // "no reasoning"')

    # Dynamic dimension checking — collect scores, build JSON once
    all_pass=true
    total_score=0
    dim_args=(--arg id "$id" --arg reasoning "$reasoning")

    for dim in $RUBRIC_DIM_NAMES; do
      score_val=$(printf '%s' "$judge_json" | jq --arg d "$dim" '.[$d] // 0 | floor')
      threshold_val=$(rubric_get_threshold "$dim")
      printf "  %-16s %s/5 (threshold: %s)\n" "${dim}:" "$score_val" "$threshold_val"

      if [[ "$score_val" -lt "$threshold_val" ]]; then
        fail "$id: $dim $score_val < threshold $threshold_val"
        all_pass=false
      fi

      total_score=$((total_score + score_val))
      dim_args+=(--argjson "$dim" "$score_val")
    done

    printf "  Reasoning:     %s\n" "$reasoning"

    # Check overall average against pass threshold
    if [[ "$RUBRIC_DIM_COUNT" -gt 0 ]]; then
      avg=$(awk "BEGIN { printf \"%.1f\", $total_score / $RUBRIC_DIM_COUNT }")
      printf "  Average:       %s/5 (pass: >= %s)\n" "$avg" "$RUBRIC_PASS_THRESH"
      if ! awk "BEGIN { exit ($avg >= $RUBRIC_PASS_THRESH) ? 0 : 1 }"; then
        fail "$id: Average $avg < pass_threshold $RUBRIC_PASS_THRESH"
        all_pass=false
      fi
    fi

    if [[ "$all_pass" == true ]]; then
      pass "$id: All dimensions meet thresholds"
    fi

    # Build score entry in one jq call
    score_entry=$(jq -n "${dim_args[@]}" '$ARGS.named')
  else
    # ── Fallback: hardcoded 3-dimension scoring ───────────────────
    threshold_clarity=$(jq -r ".results[$i].judge_rubric.clarity // 4" "$RESULTS_FILE")
    threshold_completeness=$(jq -r ".results[$i].judge_rubric.completeness // 4" "$RESULTS_FILE")
    threshold_actionability=$(jq -r ".results[$i].judge_rubric.actionability // 4" "$RESULTS_FILE")

    judge_prompt=$(build_default_judge_prompt "$desc" "$output")

    if ! call_judge_api "$judge_prompt"; then
      printf "  \033[33mAPI ERROR\033[0m HTTP %s\n" "$JUDGE_HTTP_CODE"
      fail "$id: API call failed (HTTP $JUDGE_HTTP_CODE)"
      continue
    fi

    judge_json=$(printf '%s' "$JUDGE_TEXT" | parse_judge_response)

    clarity=$(printf '%s' "$judge_json" | jq '.clarity // 0 | floor')
    completeness=$(printf '%s' "$judge_json" | jq '.completeness // 0 | floor')
    actionability=$(printf '%s' "$judge_json" | jq '.actionability // 0 | floor')
    reasoning=$(printf '%s' "$judge_json" | jq -r '.reasoning // "no reasoning"')

    printf "  Clarity:       %s/5 (threshold: %s)\n" "$clarity" "$threshold_clarity"
    printf "  Completeness:  %s/5 (threshold: %s)\n" "$completeness" "$threshold_completeness"
    printf "  Actionability: %s/5 (threshold: %s)\n" "$actionability" "$threshold_actionability"
    printf "  Reasoning:     %s\n" "$reasoning"

    all_pass=true
    if [[ "$clarity" -lt "$threshold_clarity" ]]; then
      fail "$id: Clarity $clarity < threshold $threshold_clarity"
      all_pass=false
    fi
    if [[ "$completeness" -lt "$threshold_completeness" ]]; then
      fail "$id: Completeness $completeness < threshold $threshold_completeness"
      all_pass=false
    fi
    if [[ "$actionability" -lt "$threshold_actionability" ]]; then
      fail "$id: Actionability $actionability < threshold $threshold_actionability"
      all_pass=false
    fi

    if [[ "$all_pass" == true ]]; then
      pass "$id: All dimensions meet thresholds"
    fi

    score_entry=$(jq -n \
      --arg id "$id" \
      --argjson clarity "$clarity" \
      --argjson completeness "$completeness" \
      --argjson actionability "$actionability" \
      --arg reasoning "$reasoning" \
      '{id: $id, clarity: $clarity, completeness: $completeness, actionability: $actionability, reasoning: $reasoning}')
  fi

  score_entries+=("$score_entry")
done

# Assemble scores array in one jq call
if [[ ${#score_entries[@]} -gt 0 ]]; then
  scores_json=$(printf '%s\n' "${score_entries[@]}" | jq -s '.')
else
  scores_json="[]"
fi

# ── Write scores back to results file ────────────────────────────────
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
jq --argjson scores "$scores_json" --arg jm "$JUDGE_MODEL" '. + {scores: $scores, judge_model: $jm}' "$RESULTS_FILE" > "$tmp" \
  && mv "$tmp" "$RESULTS_FILE"
trap - EXIT

# ══════════════════════════════════════════════════════════════════════
# Summary
# ══════════════════════════════════════════════════════════════════════
section "Summary"

if [[ "$scored" -eq 0 ]]; then
  echo "  No results with rubrics found to score."
  echo "  Run test-behavioral.sh (live, not --dry-run) first."
  exit 0
fi

# Compute averages for all dimensions present across scores
echo "  Scored:         $scored"
echo "  Passed:         $passed"
echo "  Failed:         $failed"

# Dynamically find all dimension keys (excluding id and reasoning)
dim_keys=$(printf '%s' "$scores_json" | jq -r '[.[] | keys[] | select(. != "id" and . != "reasoning")] | unique | .[]')
for dim_key in $dim_keys; do
  avg=$(printf '%s' "$scores_json" | jq --arg k "$dim_key" \
    '[.[] | .[$k] // empty] | if length > 0 then add / length | . * 10 | round / 10 else 0 end')
  printf "  Avg %-12s %s/5\n" "${dim_key}:" "$avg"
done

echo "  Results:        $RESULTS_FILE"
echo ""

if [[ "$failed" -gt 0 ]]; then
  printf "  \033[31m%d scoring check(s) failed\033[0m\n" "$failed"
  echo ""
  exit 1
else
  printf "  \033[32mAll scoring checks passed\033[0m\n"
  echo ""
  exit 0
fi
