---
description: Self-verify work, run review agents in parallel, fix P1s, report findings
---

# Review Loop (Phase 5)

You are reviewing work before it ships. Your job is to verify correctness, run specialized review agents, fix critical issues, and produce a clean report for the developer.

## Step 0: Verify Agent Dispatch

Before running review agents, confirm the Task tool works:

1. **Launch a trivial Task agent** — Dispatch a general-purpose agent with the prompt: "Reply with the single word: pong". Set max_turns to 1.
2. **If it completes** and returns "pong" (or any response) → proceed to Step 1.
3. **If it fails or times out** → Stop with: "Agent dispatch failed. Cannot run review agents. Check Task tool availability."

This catches the case where you'd wait for 3 parallel agents that all silently fail.

## Step 1: Self-Verification

Before launching review agents, verify your own work against the execution plan:

1. **Check each plan step** — Was it completed? Does the implementation match what was planned?
2. **Run the test suite** — Execute the project's test command (check `package.json` scripts, CLAUDE.md, or common patterns like `npm test`, `npx vitest`, `npx jest`). If no test suite exists, note it and proceed.
3. **Verify the build** — Run `npm run build` (or equivalent) to catch type errors and build failures.
4. **Review your own diff** — Run `git diff` and read through every change. Look for:
   - Files you changed that you didn't mean to
   - Debug code, console.logs, or TODO comments left behind
   - Incomplete implementations or placeholder code

If self-verification reveals issues, fix them before proceeding to agent review.

## Step 2: Launch Review Agents

Dispatch three specialized review agents **in parallel** using the Task tool. Each agent reviews the current diff against the codebase.

**Prepare the review context** first:
- Run `git diff main...HEAD` (or appropriate base branch) to capture all changes
- Identify which files were modified, added, or deleted

**Launch all three simultaneously:**

1. **code-reviewer** agent — "Review the code changes on this branch for bugs, logic errors, and quality issues. The diff is from `git diff main...HEAD`. Use P1/P2/P3 severity."

2. **security-reviewer** agent — "Review the code changes on this branch for security vulnerabilities. The diff is from `git diff main...HEAD`. Use P1/P2/P3 severity."

3. **typescript-reviewer** agent — "Review the code changes on this branch for TypeScript, React, and Next.js issues. The diff is from `git diff main...HEAD`. Use P1/P2/P3 severity."

Wait for all three to complete.

## Step 3: Collect & Classify Findings

Merge findings from all three agents into a single report, deduplicated and sorted by severity:

```
## Review Findings

### P1 — Must Fix
- [Finding from agent] — [file:line]
- ...

### P2 — Should Fix
- [Finding from agent] — [file:line]
- ...

### P3 — Nit
- [Finding from agent] — [file:line]
- ...

---
**Totals**: X P1, Y P2, Z P3
**Sources**: code-reviewer (A findings), security-reviewer (B findings), typescript-reviewer (C findings)
```

## Step 4: Fix Loop (P1s Only)

If there are P1 findings:

1. Fix each P1 issue.
2. Re-run the test suite and build to verify fixes don't break anything.
3. Re-launch only the relevant review agent(s) to verify the P1 is resolved.
4. **Max 3 loops.** If a P1 persists after 3 fix attempts, flag it for human review with full context on what was tried.

If there are no P1 findings, skip to Step 5.

## Step 5: Visual Review Report

Generate a visual HTML review page using the visual-explainer skill. The agent findings from Step 3 are already available in the conversation — no additional data gathering is needed for that section.

### 5a. Load visual-explainer references

Read these files for styling rules, anti-slop guidelines, and structural patterns. If any path does not exist (plugin running outside its source repo), tell the user: "Visual-explainer skill files not found. Generating plain HTML without design constraints." Then skip to Step 5b, generate plain semantic HTML using the same 6-section structure as Step 5d (no external CSS patterns, no templates, no anime.js animations), and continue with Step 5e.

1. `plugins/workflows/skills/visual-explainer/SKILL.md` — workflow, styling rules, anti-slop design guidelines
2. `plugins/workflows/skills/visual-explainer/templates/architecture.html` — reference template for card-heavy layouts
3. `plugins/workflows/skills/visual-explainer/references/css-patterns.md` — CSS utility patterns
4. `plugins/workflows/skills/visual-explainer/references/responsive-nav.md` — responsive navigation patterns
5. `plugins/workflows/skills/visual-explainer/references/libraries.md` — CDN versions, anime.js animation API, Chart.js theming

### 5b. Gather supplemental data

Agent findings are already available from Step 3. If Step 4 made fix commits, the diff has changed — re-run all git commands now. Gather the remaining data:

0. Detect the base branch: use `git remote show origin | grep "HEAD branch"`, falling back to whichever of `main`, `master`, `develop` exists locally. Store as `BASE`. Use `BASE` in all subsequent git commands.
1. `git diff --stat BASE...HEAD` — file overview with per-file and total line counts (summary line provides added/removed totals)
2. `git diff --name-status BASE...HEAD` — new (A), modified (M), deleted (D) files
3. Read up to 5 affected files to understand module relationships for the architecture diagram. Prefer entry points, index files, or files with the most changes

### 5c. Verification checkpoint

Before generating HTML, produce a fact sheet of every quantitative figure:
- Line counts (added/removed) — verify against `--stat` summary line
- File counts (added/modified/deleted) — verify against `--name-status` output
- P1/P2/P3 counts per agent — verify against Step 3 findings
- Test/build status — verify against Step 1 results

Cross-check each claim against the actual data. Do not estimate or round.

### 5d. Generate HTML with 6 sections

Build a single self-contained HTML file. Follow visual-explainer SKILL.md rules strictly (no generic AI styling, no slop). Use the architecture.html template as a structural reference.

**Visual hierarchy**: Sections 1-2 are hero depth (larger type, accent background). Sections 3-4 are main content. Sections 5-6 are reference/collapsible.

**Color language**: Red = removed/critical, Green = added/fixed, Amber = warning/modified, Blue = neutral context.

**Large diffs** (>500 files or >10,000 lines): truncate the File Map to the first 50 files with a count badge for the remainder. Collapse P3 findings into a summary table instead of full cards.

1. **Executive Summary** — What changed and why, derived from git diff + commit messages. Hero treatment: larger type, accent background.

2. **KPI Dashboard** — Metric cards showing: lines added, lines removed, files changed, P1 count, P2 count, P3 count (with per-agent breakdown). Use count-up animation (anime.js from libraries.md).

3. **Module Architecture** — Mermaid diagram of affected modules and their relationships. Use `.mermaid-wrap` with zoom controls. If 10+ nodes, use hybrid pattern: a simple Mermaid overview (5-8 nodes showing module groups) followed by CSS Grid detail cards per module.

4. **Agent Findings** — Core section. Group by severity (P1 → P2 → P3). Each finding is a styled card with:
   - Severity badge (red for P1, amber for P2, blue for P3)
   - Agent source badge (code-reviewer / security-reviewer / typescript-reviewer)
   - `file:line` reference in monospace
   - Description and fix suggestion
   - P1s that were fixed in Step 4 get a green "Fixed" badge overlay

5. **File Map** — Color-coded file tree (green = added, amber = modified, red = deleted). Wrap in `<details>` collapsed by default if more than 15 files.

6. **Test Suite Status** — Test pass/fail result and test file count from Step 1. If no test suite exists, show "No automated tests detected" and the P2 finding from Step 3 if one was raised.

### 5e. Write and open

1. **Pre-sanitization safety check**: Reject (use `unnamed-branch` fallback) if the raw branch name contains `..`, path separators (`/`, `\`), or starts with `.`. Then sanitize: lowercase, replace any character outside `[a-z0-9]` with a hyphen, collapse consecutive hyphens, strip leading/trailing hyphens. The result must match `^[a-z0-9]([a-z0-9-]*[a-z0-9])?$` (allows single-character names). If the result is empty, use `unnamed-branch`.
2. **Post-sanitization safety check**: Re-verify the final name contains no `..`, no `/`, no `\`, and does not start with `.`. Reject and use `unnamed-branch` if violations found.
3. Write the HTML file to `~/.agent/diagrams/review-<sanitized-branch>.html`. Create the directory if it doesn't exist.
4. Verify the file was written successfully. If the write failed, report the error and skip the browser open.
5. Open the file in the default browser: `open` on macOS, `xdg-open` on Linux.
6. Tell the user the file path.

## Step 6: Final Report

Present the final state to the developer:

```
## Review Complete

**P1 (fixed)**: [list what was fixed, or "None"]
**P2 (your call)**: [list remaining P2s with context]
**P3 (FYI)**: [list P3s briefly]

**Tests**: Passing / Failing (details)
**Build**: Clean / Errors (details)

**Verdict**: Ready to ship / Needs your input on P2s / Blocked on P1
**Visual report**: [path from Step 5, or "Not generated" if Step 5 was skipped]
```

The full visual review with architecture diagram, finding cards, and file map is available at the HTML file from Step 5.

If all P1s are fixed and tests pass, suggest: "Ready for `/workflows:ship` when you are."

If P2s need decisions, ask the developer which to fix and which to accept.

## Rules

- Always self-verify before launching agents — catch the obvious stuff yourself.
- Launch all 3 agents in parallel — don't wait for one before starting another.
- Only fix P1s automatically. P2s require developer approval.
- Never suppress or downgrade a P1 finding. If you disagree with an agent's classification, present both perspectives to the developer.
- If no test suite exists, flag that as a P2 finding ("no automated tests").
- The fix loop is for P1s only — don't enter a fix loop for P2s or P3s.
