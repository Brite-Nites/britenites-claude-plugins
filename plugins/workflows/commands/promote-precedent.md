---
description: Review and promote flagged decision traces from project precedents to the org-level handbook
---

# Promote Precedent

You are reviewing decision traces that have been flagged for promotion to the org-level handbook. Promotion is the final step of the compound knowledge flywheel — high-value project-level decisions become searchable across ALL projects via `handbook/precedents/`.

`$ARGUMENTS` is unused by this command.

## Phase 0: Prerequisites

Narrate: `Phase 0/7: Checking prerequisites...`

1. **GitHub CLI authenticated**: Run `gh auth status` via Bash. If it fails, stop with: "GitHub CLI not authenticated — run `gh auth login` first."
2. **Handbook repo accessible**: Run `gh api repos/Brite-Nites/handbook --jq .name` via Bash. If it fails, stop with: "Handbook repo not accessible — check org access."
3. **Project precedents exist**: Check that `docs/precedents/INDEX.md` exists using Read. If it doesn't exist, stop with: "No project precedents found. Decision traces are created during `/workflows:ship`."

Print the activation banner:

```
---
**Promote Precedent** activated
Trigger: Manual invocation — reviewing promotion candidates
Produces: Handbook PR with promoted decision traces
---
```

Narrate: `Phase 0/7: Checking prerequisites... done`

## Phase 1: Gather Candidates

Narrate: `Phase 1/7: Gathering promotion candidates...`

Collect candidates from two sources, then merge.

### Source A: Linear issues with `precedent-promotion` label

Query Linear MCP: `list_issues` with `label: "precedent-promotion"` and `project` set to the project name from CLAUDE.md `## Linear Project`. Filter to issues where `status` is NOT "Done" and NOT "Cancelled".

For each Linear issue found:
- Extract the issue ID from the title or description (e.g., the trace's source issue ID)
- Record the decision summary from the issue description
- Record the Linear issue ID for later status updates

If Linear MCP is unavailable, skip Source A and log: "Linear MCP unavailable — gathering candidates from INDEX scan only."

### Source B: Direct INDEX scan

Read `docs/precedents/INDEX.md` and parse the markdown table. For each row where Category is `architecture`, `library-selection`, or `trade-off`:

1. Load the full trace file from `docs/precedents/<ISSUE-ID>.md`
2. Parse the trace section matching this INDEX row
3. Check if Confidence >= 8
4. If yes, add as a candidate

### Merge and deduplicate

Merge candidates from Source A and Source B. Deduplicate by Issue ID + Decision text. Prefer Source A entries (they have Linear issue context).

Sort candidates by:
1. Confidence descending (highest first)
2. Date descending (newest first)

If no candidates found from either source:
- Narrate: "No promotion candidates found. Decision traces are flagged for promotion during `/workflows:ship` when they meet all criteria: confidence >= 8, category in {architecture, library-selection, trade-off}, and generalizable pattern."
- Exit.

Narrate: `Phase 1/7: Gathering promotion candidates... done ([N] candidates)`

## Phase 2: Clone Handbook

Narrate: `Phase 2/7: Cloning handbook...`

Derive a unique clone path using the current timestamp:

```bash
CLONE_PATH="/tmp/handbook-promote-$(date +%s)"
gh repo clone Brite-Nites/handbook "$CLONE_PATH" -- --depth 1
```

If the clone fails, present via AskUserQuestion:
- **Retry** — Try the clone again
- **Stop** — Halt for manual intervention

After cloning, read `$CLONE_PATH/precedents/INDEX.md` if it exists. Parse the existing handbook INDEX table for deduplication in Phase 3. If the file doesn't exist, note that the handbook precedents directory may need to be created.

Narrate: `Phase 2/7: Cloning handbook... done`

## Phase 3: Review Each Candidate

Narrate: `Phase 3/7: Reviewing candidates...`

For each candidate (in sorted order):

### 3a. Load the full trace

Read the project-level trace from `docs/precedents/<ISSUE-ID>.md`. Extract the specific trace section matching this candidate (match by the `## Trace —` heading that contains the decision summary).

If the trace file is missing or the section cannot be found:
- Log: "Trace file missing for [ISSUE-ID] — skipping this candidate."
- Continue to next candidate.

### 3b. Deduplication check

Compare against the handbook INDEX parsed in Phase 2 using the composite key: Issue ID + Decision text (case-insensitive match on Decision text).

If already present in the handbook:
- Log: "Already promoted: [ISSUE-ID] — [Decision summary]. Skipping."
- If a Linear issue exists for this candidate, add a comment: "Already present in handbook precedents. Closing as duplicate." and transition to Done.
- Continue to next candidate.

### 3c. Present for review

Display the trace to the user:

```
### Candidate [N] of [total]

**Issue:** [ISSUE-ID]
**Decision:** [Decision summary]
**Category:** [category]
**Confidence:** [N]/10
**Date:** [YYYY-MM-DD]

#### Inputs
[bullet list from trace]

#### Alternatives Considered
[numbered list from trace]

#### Precedent Referenced
[bullet list from trace]

#### Outcome
[files changed, tests, approved by]
```

Then assess generalizability:
- Flag any project-specific file paths (e.g., `src/middleware/auth.ts` — these should be generalized to `<project>/src/middleware/auth.ts`)
- Flag project-specific configuration or environment references
- Note whether the pattern is genuinely reusable across projects

### 3d. Human decision

Use AskUserQuestion with these options:
- **Promote** — Include this trace in the handbook PR as-is (with path generalization applied automatically)
- **Edit first** — Review and modify the trace content before promoting (for generalizing project-specific details)
- **Skip** — This trace is too project-specific or not valuable enough for org-level
- **Skip all remaining** — Stop reviewing further candidates

For **"Edit first"**: Display the trace content as it would appear in the handbook. Let the user describe what changes they want. Apply the changes, then confirm the edited version before staging.

For **"Skip"**: Use AskUserQuestion to ask for a brief reason (used in the Linear issue comment). Options:
- **Too project-specific** — Pattern doesn't generalize
- **Low confidence in hindsight** — Decision may not hold up
- **Already covered** — Similar precedent exists (different wording)
- (User can also type a custom reason)

Record each decision (promote/skip) with the trace details for the summary report.

Narrate: `Phase 3/7: Reviewing candidates... done ([N] promoted, [N] skipped)`

If no candidates were promoted, skip to Phase 6 (update Linear for skipped candidates) and Phase 7 (summary).

## Phase 4: Write to Handbook Clone

Narrate: `Phase 4/7: Writing promoted traces to handbook...`

For each promoted trace:

### 4a. Write the trace file

Write to `$CLONE_PATH/precedents/<ISSUE-ID>.md`:

- If the file already exists in the handbook clone (same issue, different trace from a previous promotion), append the new trace section below existing content
- If the file does not exist, create it with the trace content
- **Generalize project-specific paths**: Replace absolute or project-relative paths with `<project>/path` notation (e.g., `src/middleware/auth.ts` → `<project>/src/middleware/auth.ts`)
- **Preserve all other trace content** exactly as it appears in the project-level file

### 4b. Update handbook INDEX

Apply the auto-update algorithm from `docs/precedents/README.md`:

1. Read `$CLONE_PATH/precedents/INDEX.md` (create with the standard header template if missing):
   ```
   # Precedent Index

   <!-- Auto-updated by promote-precedent. Do not edit manually. -->

   | Issue | Decision | Category | Date | Tags |
   |-------|----------|----------|------|------|
   ```
2. Parse the markdown table — skip header and separator rows
3. Match each promoted trace against existing rows by composite key: Issue column + Decision text
4. Replace matched rows (re-promotion updates the entry). Append unmatched rows at the bottom.
5. Sort order: Chronological by insertion (newest last) — no re-sorting on update
6. Archive check: If row count exceeds 200, move entries with Date older than 6 months to `$CLONE_PATH/precedents/INDEX-archive.md`
7. Write the full INDEX.md file. Preserve the HTML comment block above the table header.

Narrate: `Phase 4/7: Writing promoted traces... done ([N] trace files, INDEX updated)`

## Phase 5: Create Handbook PR

Narrate: `Phase 5/7: Creating handbook PR...`

Only runs if at least one trace was promoted in Phase 3.

### Branch and commit

Derive the project repo name: `basename $(git rev-parse --show-toplevel)`.

```bash
cd "$CLONE_PATH"
git checkout -b "precedent-promotion/$(date +%Y-%m-%d)"
git add precedents/INDEX.md
# Add each promoted trace file specifically (not git add -A)
git add precedents/<ISSUE-ID-1>.md precedents/<ISSUE-ID-2>.md ...
git commit -m "Promote [N] decision traces from [project-repo]

Traces promoted via /workflows:promote-precedent.
Source project: [project-repo]"
git push -u origin "precedent-promotion/$(date +%Y-%m-%d)"
```

### Create PR

```bash
gh pr create --repo Brite-Nites/handbook \
  --base main \
  --head "precedent-promotion/$(date +%Y-%m-%d)" \
  --title "Promote [N] decision traces to org precedents" \
  --body "## Precedent Promotion

Source: [project-repo]
Reviewed by: [developer name] via /workflows:promote-precedent

### Traces Promoted
- [ISSUE-ID]: [Decision summary] (Category, Confidence N/10)
- ...

### Source Linear Issues
- [links to precedent-promotion Linear issues, if any]

---
*Auto-generated by `/workflows:promote-precedent`*"
```

Record the PR URL for the summary report and Linear issue updates.

### Error recovery

If the push or PR creation fails, present via AskUserQuestion:
- **Retry** — Try push and PR creation again
- **Skip PR** — Keep the clone at `$CLONE_PATH` for manual push. Log the clone path.
- **Stop** — Halt for manual intervention

### Clean up

**Always** clean up the shallow clone, even if any prior step failed:

```bash
rm -rf "$CLONE_PATH"
```

Exception: if the user chose "Skip PR", do NOT clean up — they need the clone for manual push. Log: "Handbook clone preserved at: $CLONE_PATH"

Narrate: `Phase 5/7: Creating handbook PR... done ([PR URL])`

## Phase 6: Update Linear Issues

Narrate: `Phase 6/7: Updating Linear issues...`

If Linear MCP is unavailable, skip with: "Linear MCP unavailable — skipping issue updates."

### For each promoted trace with a Linear issue:

1. Add a comment on the Linear issue:
   ```
   Promoted to org-level handbook via /workflows:promote-precedent.
   Handbook PR: [PR URL]
   ```
2. Transition the issue to "Done" status using `save_issue`

### For each skipped trace with a Linear issue:

1. Add a comment on the Linear issue:
   ```
   Reviewed via /workflows:promote-precedent — not promoted.
   Reason: [user's reason from Phase 3d]
   ```
2. Transition the issue to "Cancelled" status using `save_issue`

Narrate: `Phase 6/7: Updating Linear issues... done`

## Phase 7: Summary Report

Narrate: `Phase 7/7: Summary`

```
## Precedent Promotion Complete

**Candidates reviewed**: [N]
**Promoted**: [N]
**Skipped**: [N]
**Already in handbook**: [N]
**Handbook PR**: [URL or "none — all candidates skipped"]

### Promoted Traces
| Issue | Decision | Category | Confidence |
|-------|----------|----------|------------|
| [ID]  | [summary]| [cat]    | [N]/10     |

### Skipped Traces
| Issue | Decision | Reason |
|-------|----------|--------|
| [ID]  | [summary]| [reason] |

Run `/workflows:promote-precedent` again after the next `/workflows:ship` to review new candidates.
```
