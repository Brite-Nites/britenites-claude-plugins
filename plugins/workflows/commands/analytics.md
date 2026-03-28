---
description: Show plugin usage analytics — command frequency, success rates, and duration trends
---

# Plugin Analytics

Display usage statistics for the Brite plugin — how often commands run, success rates, average durations, and recent errors.

## Step 1: Check Data Availability

Check if `~/.brite-plugins/telemetry/events.jsonl` exists:

```bash
test -f ~/.brite-plugins/telemetry/events.jsonl && echo "Data found" || echo "No data"
```

If no data exists, tell the user: "No telemetry data yet. Usage is logged automatically during sessions. Start a session with `/workflows:session-start` to begin collecting data."

## Step 2: Run Analytics Dashboard

Resolve the plugin repo root and run the analytics script. Pass through any `$ARGUMENTS` (supports `--since YYYY-MM-DD` and `--until YYYY-MM-DD` for date filtering):

```bash
BRITE_ROOT="$(cat ~/.brite-plugins/.repo-root 2>/dev/null)" && bash "$BRITE_ROOT/scripts/brite-analytics.sh" $ARGUMENTS 2>/dev/null
```

If the script is not found (`.repo-root` missing or stale), fall back:

```bash
echo "Analytics script not found. Ensure a session has been started at least once to initialize telemetry paths."
```

## Step 3: Present Results

Display the dashboard output to the user exactly as rendered by the script. Do not reformat or summarize — the script output is the final presentation.
