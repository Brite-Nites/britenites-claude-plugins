#!/usr/bin/env bash
# ── Brite Plugin Analytics Dashboard ───────────────────────────────
# Reads ~/.brite-plugins/telemetry/events.jsonl and displays usage
# statistics with ASCII bar charts.
#
# Usage:
#   brite-analytics.sh                    Show all-time stats
#   brite-analytics.sh --since 2026-03-01 Filter by start date
#   brite-analytics.sh --until 2026-03-31 Filter by end date
#   brite-analytics.sh --since 2026-03-01 --until 2026-03-31
#
# No jq dependency — uses awk for JSONL parsing.
# ───────────────────────────────────────────────────────────────────

set -euo pipefail

EVENTS_FILE="$HOME/.brite-plugins/telemetry/events.jsonl"

# ── Parse Arguments ────────────────────────────────────────────────

SINCE=""
UNTIL=""

while [ $# -gt 0 ]; do
  case "$1" in
    --since) SINCE="${2:-}"; shift 2 ;;
    --until) UNTIL="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done

# ── Check Data ─────────────────────────────────────────────────────

if [ ! -f "$EVENTS_FILE" ] || [ ! -s "$EVENTS_FILE" ]; then
  echo "No telemetry data yet."
  echo "Usage is logged automatically during sessions."
  echo "Location: $EVENTS_FILE"
  exit 0
fi

# ── Render Dashboard ───────────────────────────────────────────────

awk -v since="$SINCE" -v until="$UNTIL" '
BEGIN {
  max_bar = 20
  session_count = 0
  first_date = ""
  last_date = ""
  cmd_count = 0
  err_count = 0
}

# Simple JSON field extractor: get value for a key from a JSON line
function json_val(line, key,    pat, val) {
  pat = "\"" key "\":[[:space:]]*"
  if (match(line, pat)) {
    val = substr(line, RSTART + RLENGTH)
    # String value
    if (substr(val, 1, 1) == "\"") {
      val = substr(val, 2)
      sub(/".*/, "", val)
      return val
    }
    # Null or number
    sub(/[,}].*/, "", val)
    gsub(/[[:space:]]/, "", val)
    return val
  }
  return ""
}

{
  ts = json_val($0, "ts")
  event_type = json_val($0, "event_type")
  command = json_val($0, "command")
  outcome = json_val($0, "outcome")
  duration = json_val($0, "duration_s")
  error_class = json_val($0, "error_class")

  # Date filter (compare ISO date strings)
  date = substr(ts, 1, 10)
  if (since != "" && date < since) next
  if (until != "" && date > until) next

  # Track date range
  if (first_date == "" || date < first_date) first_date = date
  if (last_date == "" || date > last_date) last_date = date

  # Count sessions
  if (event_type == "session_start") {
    session_count++
    next
  }

  # Skip events without a command
  if (command == "" || command == "null") next

  # Track command starts (for frequency)
  if (event_type == "command_start") {
    if (!(command in cmd_starts)) {
      cmds[cmd_count++] = command
    }
    cmd_starts[command]++
  }

  # Track command ends (for outcomes and duration)
  if (event_type == "command_end") {
    cmd_total[command]++
    if (outcome == "success") {
      cmd_success[command]++
    }
    if (outcome == "error" || outcome == "unknown") {
      if (err_count < 10) {
        errors[err_count] = date " " command "  " (error_class != "null" && error_class != "" ? error_class : outcome)
      }
      err_count++
    }
    if (duration != "null" && duration != "" && duration + 0 > 0) {
      cmd_duration_total[command] += duration + 0
      cmd_duration_count[command]++
    }
  }
}

function repeat_char(ch, n,    s, i) {
  s = ""
  for (i = 0; i < n; i++) s = s ch
  return s
}

function format_duration(secs,    m, s) {
  if (secs < 60) return secs "s"
  m = int(secs / 60)
  s = secs - (m * 60)
  return m "m " s "s"
}

END {
  if (session_count == 0 && cmd_count == 0) {
    print "No matching telemetry events found."
    exit 0
  }

  print ""
  print "Brite Plugin Analytics"
  print "======================================="

  # Period line
  period = first_date
  if (last_date != first_date) period = first_date " -- " last_date
  printf "Period: %s (%d sessions)\n", period, session_count
  print ""

  # ── Command Usage with bar chart ──
  if (cmd_count > 0) {
    # Find max for scaling
    max_val = 0
    for (i = 0; i < cmd_count; i++) {
      c = cmds[i]
      if (cmd_starts[c] + 0 > max_val) max_val = cmd_starts[c] + 0
    }

    # Sort by frequency (insertion sort — O(n²) is fine for n < 50 unique commands)
    for (i = 1; i < cmd_count; i++) {
      key = cmds[i]
      j = i - 1
      while (j >= 0 && cmd_starts[cmds[j]] + 0 < cmd_starts[key] + 0) {
        cmds[j + 1] = cmds[j]
        j--
      }
      cmds[j + 1] = key
    }

    print "Command Usage:"
    max_name_len = 0
    for (i = 0; i < cmd_count; i++) {
      if (length(cmds[i]) > max_name_len) max_name_len = length(cmds[i])
    }

    for (i = 0; i < cmd_count; i++) {
      c = cmds[i]
      count = cmd_starts[c] + 0
      bar_len = (max_val > 0) ? int((count / max_val) * max_bar) : 0
      if (bar_len < 1 && count > 0) bar_len = 1
      bar = repeat_char("#", bar_len)
      printf "  %-*s  %-*s  %d\n", max_name_len, c, max_bar, bar, count
    }
    print ""
  }

  # ── Success Rate ──
  has_outcomes = 0
  for (i = 0; i < cmd_count; i++) {
    c = cmds[i]
    if (cmd_total[c] + 0 > 0) { has_outcomes = 1; break }
  }

  if (has_outcomes) {
    print "Success Rate:"
    for (i = 0; i < cmd_count; i++) {
      c = cmds[i]
      total = cmd_total[c] + 0
      if (total == 0) continue
      success = cmd_success[c] + 0
      pct = int((success / total) * 100)
      printf "  %-*s  %d%% (%d/%d)\n", max_name_len, c, pct, success, total
    }
    print ""
  }

  # ── Average Duration ──
  has_duration = 0
  for (i = 0; i < cmd_count; i++) {
    c = cmds[i]
    if (cmd_duration_count[c] + 0 > 0) { has_duration = 1; break }
  }

  if (has_duration) {
    print "Avg Duration:"
    for (i = 0; i < cmd_count; i++) {
      c = cmds[i]
      dcount = cmd_duration_count[c] + 0
      if (dcount == 0) continue
      avg = int(cmd_duration_total[c] / dcount)
      printf "  %-*s  %s\n", max_name_len, c, format_duration(avg)
    }
    print ""
  }

  # ── Recent Errors ──
  show_errors = (err_count > 5) ? 5 : err_count
  if (show_errors > 0) {
    print "Recent Errors:"
    # Show last N errors (they are in chronological order)
    start_idx = (err_count > 5) ? err_count - 5 : 0
    for (i = start_idx; i < err_count && i < 10; i++) {
      printf "  %s\n", errors[i]
    }
    print ""
  }

  print "Data: " ENVIRON["HOME"] "/.brite-plugins/telemetry/events.jsonl"
  print "Privacy: All data is stored locally. No data is transmitted externally."
}
' "$EVENTS_FILE"
