#!/usr/bin/env bash
set -euo pipefail

# ── Behavioral Scorer (Tier 3 — LLM-as-Judge) ───────────────────────
# Reads the latest behavioral test results and scores outputs using
# an LLM judge (Haiku) for clarity, completeness, and actionability.
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
scores_json="[]"

for i in $(seq 0 $((result_count - 1))); do
  id=$(jq -r ".results[$i].id" "$RESULTS_FILE")
  status=$(jq -r ".results[$i].status" "$RESULTS_FILE")
  has_rubric=$(jq ".results[$i].has_rubric" "$RESULTS_FILE")
  output=$(jq -r ".results[$i].output // \"\"" "$RESULTS_FILE")

  # Skip entries without rubric or without output
  if [[ "$has_rubric" != "true" ]] || [[ -z "$output" ]] || [[ "$output" == "null" ]]; then
    continue
  fi

  if [[ "$status" == "skipped" ]]; then
    continue
  fi

  section "$id: Scoring output quality"
  scored=$((scored + 1))

  # Load thresholds from the results file (embedded by test-behavioral.sh)
  threshold_clarity=$(jq -r ".results[$i].judge_rubric.clarity // 4" "$RESULTS_FILE")
  threshold_completeness=$(jq -r ".results[$i].judge_rubric.completeness // 4" "$RESULTS_FILE")
  threshold_actionability=$(jq -r ".results[$i].judge_rubric.actionability // 4" "$RESULTS_FILE")
  desc=$(jq -r ".results[$i].description // \"Test $id\"" "$RESULTS_FILE")

  # Truncate output to avoid huge API calls (keep first 4000 chars)
  truncated_output="${output:0:4000}"

  # Build the judge prompt
  judge_prompt="You are an expert evaluator scoring the quality of an AI agent's output.

Task description: $desc

Score the following output on three dimensions, each on a scale of 1-5:

1. **Clarity** (1-5): Is the output well-organized, easy to follow, and free of confusion?
2. **Completeness** (1-5): Does the output address all aspects of the task? Are there gaps?
3. **Actionability** (1-5): Can the user take concrete next steps based on this output?

Output to evaluate:
---
$truncated_output
---

Respond with ONLY a JSON object, no other text:
{\"clarity\": N, \"completeness\": N, \"actionability\": N, \"reasoning\": \"one sentence\"}"

  # Escape the prompt for JSON payload
  escaped_prompt=$(printf '%s' "$judge_prompt" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')

  # Call Anthropic API
  api_response=$(curl -s -w "\n%{http_code}" \
    https://api.anthropic.com/v1/messages \
    -H "content-type: application/json" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -d "{
      \"model\": \"$JUDGE_MODEL\",
      \"max_tokens\": 256,
      \"messages\": [{\"role\": \"user\", \"content\": $escaped_prompt}]
    }" 2>/dev/null) || true

  # Split response body and HTTP status
  http_code=$(echo "$api_response" | tail -1)
  response_body=$(echo "$api_response" | sed '$d')

  if [[ "$http_code" != "200" ]]; then
    printf "  \033[33mAPI ERROR\033[0m HTTP %s\n" "$http_code"
    fail "$id: API call failed (HTTP $http_code)"
    continue
  fi

  # Extract the judge's text response
  judge_text=$(echo "$response_body" | jq -r '.content[0].text // ""')

  if [[ -z "$judge_text" ]]; then
    fail "$id: Judge returned empty response"
    continue
  fi

  # Parse scores from judge response (extract JSON from potentially wrapped text)
  judge_json=$(echo "$judge_text" | python3 -c '
import sys, json, re
text = sys.stdin.read()
# Try direct parse first
try:
    d = json.loads(text)
    print(json.dumps(d))
    sys.exit(0)
except: pass
# Try extracting JSON from markdown code block
m = re.search(r"\{[^{}]+\}", text)
if m:
    try:
        d = json.loads(m.group())
        print(json.dumps(d))
        sys.exit(0)
    except: pass
print("{}")
' 2>/dev/null) || judge_json="{}"

  clarity=$(echo "$judge_json" | jq '.clarity // 0 | floor')
  completeness=$(echo "$judge_json" | jq '.completeness // 0 | floor')
  actionability=$(echo "$judge_json" | jq '.actionability // 0 | floor')
  reasoning=$(echo "$judge_json" | jq -r '.reasoning // "no reasoning"')

  printf "  Clarity:       %s/5 (threshold: %s)\n" "$clarity" "$threshold_clarity"
  printf "  Completeness:  %s/5 (threshold: %s)\n" "$completeness" "$threshold_completeness"
  printf "  Actionability: %s/5 (threshold: %s)\n" "$actionability" "$threshold_actionability"
  printf "  Reasoning:     %s\n" "$reasoning"

  # Check thresholds
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

  # Accumulate scores (use jq -n for safe JSON construction)
  score_entry=$(jq -n \
    --arg id "$id" \
    --argjson clarity "$clarity" \
    --argjson completeness "$completeness" \
    --argjson actionability "$actionability" \
    --arg reasoning "$reasoning" \
    '{id: $id, clarity: $clarity, completeness: $completeness, actionability: $actionability, reasoning: $reasoning}')
  scores_json=$(echo "$scores_json" | jq --argjson s "$score_entry" '. += [$s]')
done

# ── Write scores back to results file ────────────────────────────────
tmp=$(mktemp)
jq --argjson scores "$scores_json" --arg jm "$JUDGE_MODEL" '. + {scores: $scores, judge_model: $jm}' "$RESULTS_FILE" > "$tmp" \
  && mv "$tmp" "$RESULTS_FILE"

# ══════════════════════════════════════════════════════════════════════
# Summary
# ══════════════════════════════════════════════════════════════════════
section "Summary"

if [[ "$scored" -eq 0 ]]; then
  echo "  No results with rubrics found to score."
  echo "  Run test-behavioral.sh (live, not --dry-run) first."
  exit 0
fi

# Compute averages
avg_clarity=$(echo "$scores_json" | jq '[.[].clarity] | add / length | . * 10 | round / 10')
avg_completeness=$(echo "$scores_json" | jq '[.[].completeness] | add / length | . * 10 | round / 10')
avg_actionability=$(echo "$scores_json" | jq '[.[].actionability] | add / length | . * 10 | round / 10')

echo "  Scored:         $scored"
echo "  Passed:         $passed"
echo "  Failed:         $failed"
echo "  Avg Clarity:    $avg_clarity/5"
echo "  Avg Complete:   $avg_completeness/5"
echo "  Avg Action:     $avg_actionability/5"
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
