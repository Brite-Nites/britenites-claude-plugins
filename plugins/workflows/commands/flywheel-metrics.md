---
description: Compute and display the 5 compound knowledge flywheel metrics from accumulated decision traces
---

# Flywheel Metrics

You are computing the 5 flywheel metrics defined in the Brite Agent Platform PRD. These measure whether the compound knowledge flywheel is working — better context leads to better decisions leads to better precedent leads to better context.

## Phase 0: Prerequisites

Narrate: `Phase 0/3: Checking prerequisites...`

1. **Precedent data exists**: Check that `docs/precedents/INDEX.md` exists using Read. If it doesn't exist, stop with: "No precedent data found. Decision traces are created during `/workflows:ship`. Run at least one full session-start → execute → ship cycle to generate data."
2. **Project CLAUDE.md exists**: Check that the project has a CLAUDE.md file. If missing, log: "No CLAUDE.md found — context freshness metric will be unavailable."

Print the activation banner:

```
---
**Flywheel Metrics** activated
Produces: Dashboard of 5 compound knowledge flywheel metrics
---
```

Narrate: `Phase 0/3: Checking prerequisites... done`

## Phase 1: Compute Metrics

Narrate: `Phase 1/3: Computing flywheel metrics...`

### Data Collection

1. **Read INDEX.md**: Parse the markdown table. Count total data rows (exclude header and separator). Extract the Date column from each row.
2. **Read trace files**: Glob for `docs/precedents/*.md` excluding `INDEX.md`, `INDEX-archive.md`, and `README.md`. For each trace file:
   - Parse each `## Trace —` section
   - Extract: `**Confidence:** N/10` value, `**Precedent Referenced:**` value, date from the heading
3. **Read CLAUDE.md @imports**: Extract all `@import` paths. For each, check for `last_refreshed` and `refresh_cadence` YAML frontmatter (read first 10 lines only).

### Metric Computation

**Metric 1: Precedent Hit Rate**
- Definition: % of brainstorm sessions that find relevant precedent
- Data needed: brainstorm session count (not currently tracked) + precedent match count
- Status: **Not yet computable** — requires brainstorm instrumentation
- Output: `N/A — needs brainstorm session tracking. To enable: add a hit/miss counter to the brainstorming skill's precedent-search integration.`

**Metric 2: Decision Confidence Trend**
- Definition: Average confidence score across all traces
- Computation:
  1. Collect all `Confidence: N/10` values from trace files
  2. Compute overall average: `sum(confidence) / count(traces)`
  3. Group by month (YYYY-MM from trace date) and compute per-month average
  4. Determine trend: compare last 2 months — improving (>0.5 increase), declining (>0.5 decrease), or stable
- If fewer than 2 months of data, trend is `insufficient data for trend`

**Metric 3: CDR Coverage**
- Definition: % of agent decisions that have a relevant CDR
- Computation:
  1. For each trace, check the `**Precedent Referenced:**` field
  2. A trace has CDR coverage if the field contains a CDR reference (pattern: `CDR-\d+`) — NOT "None" and NOT just an ADR reference
  3. Coverage = `count(traces with CDR) / total traces * 100`
  4. Group by month for trend analysis

**Metric 4: Context Freshness**
- Definition: % of context docs within their refresh cadence
- Computation:
  1. For each @imported file with `last_refreshed` + `refresh_cadence` metadata:
     - Compute staleness_ratio = days_since_last_refreshed / cadence_days
     - Fresh if ratio <= 1.0
  2. Freshness = `count(fresh docs) / count(docs with metadata) * 100`
  3. Files without freshness metadata are excluded from the denominator (not penalized)
- If no files have freshness metadata, output: `N/A — no context docs have freshness metadata. Add last_refreshed and refresh_cadence to YAML frontmatter.`

**Metric 5: Override Rate**
- Definition: % of decisions that override a CDR
- Data needed: semantic comparison between decisions and referenced CDRs to detect conflicts
- Status: **Not yet computable** — requires CDR conflict detection
- Output: `N/A — needs CDR conflict detection. To enable: add an override flag to compound-learnings trace extraction when a decision contradicts a referenced CDR.`

Narrate: `Phase 1/3: Metrics computed.`

## Phase 2: Trend Analysis

Narrate: `Phase 2/3: Analyzing trends...`

Group computable metrics (2, 3, 4) by month and compute trends:

1. **Monthly breakdown table**: For each month with trace data, show:
   - Month (YYYY-MM)
   - Trace count
   - Average confidence
   - CDR coverage %

2. **Trend direction**: For metrics with 2+ months of data:
   - Compare the most recent month to the previous month
   - Arrow indicators: `improving` (metric going in desired direction), `declining` (going wrong), `stable` (within tolerance)
   - Desired directions: confidence ↑, CDR coverage ↑, context freshness ↑

3. **Volume indicator**: Total traces, traces this month, average traces per month. If volume is very low (<5 total), note: "Low data volume — metrics will stabilize as more traces accumulate."

Narrate: `Phase 2/3: Trend analysis complete.`

## Phase 3: Report

Narrate: `Phase 3/3: Generating metrics dashboard...`

Present the dashboard:

```
# Flywheel Metrics Dashboard

**Project:** <project name from CLAUDE.md or repo name>
**Period:** <earliest trace date> to <latest trace date>
**Total traces:** <N>

## Metrics Summary

| # | Metric                  | Value              | Trend     | Target              |
|---|-------------------------|--------------------|-----------|---------------------|
| 1 | Precedent Hit Rate      | N/A                | —         | >50% after 6 months |
| 2 | Decision Confidence     | N.N/10 avg         | ↑/↓/→     | Increasing          |
| 3 | CDR Coverage            | N% (N/M traces)    | ↑/↓/→     | Increasing          |
| 4 | Context Freshness       | N% (N/M docs)      | ↑/↓/→     | >90%                |
| 5 | Override Rate            | N/A                | —         | Low                 |

## Monthly Breakdown

| Month   | Traces | Avg Confidence | CDR Coverage |
|---------|--------|---------------|-------------|
| 2026-03 | N      | N.N/10        | N%          |
| 2026-02 | N      | N.N/10        | N%          |
[...]

## Insights

[Generate 2-3 actionable insights based on the data, e.g.:]
- "CDR coverage is low (N%) — consider creating CDRs for frequently recurring decision categories."
- "Context freshness is high (N%) — all monitored docs are within their refresh cadence."
- "Low data volume (N traces) — metrics will become more meaningful after 10+ traces."

## Not Yet Computable

These metrics need additional instrumentation:
1. **Precedent Hit Rate**: Add hit/miss counter to brainstorming skill's precedent-search integration
5. **Override Rate**: Add CDR conflict detection to compound-learnings trace extraction
```

If no trace files exist (INDEX has rows but no corresponding .md files), still compute what's available from INDEX data (dates, categories) and note the limitation.

Narrate: `Phase 3/3: Dashboard complete.`
