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

## Step 5: Final Report

Present the final state to the developer:

```
## Review Complete

**P1 (fixed)**: [list what was fixed, or "None"]
**P2 (your call)**: [list remaining P2s with context]
**P3 (FYI)**: [list P3s briefly]

**Tests**: Passing / Failing (details)
**Build**: Clean / Errors (details)

**Verdict**: Ready to ship / Needs your input on P2s / Blocked on P1
```

If all P1s are fixed and tests pass, suggest: "Ready for `/workflows:ship` when you are."

If P2s need decisions, ask the developer which to fix and which to accept.

## Rules

- Always self-verify before launching agents — catch the obvious stuff yourself.
- Launch all 3 agents in parallel — don't wait for one before starting another.
- Only fix P1s automatically. P2s require developer approval.
- Never suppress or downgrade a P1 finding. If you disagree with an agent's classification, present both perspectives to the developer.
- If no test suite exists, flag that as a P2 finding ("no automated tests").
- The fix loop is for P1s only — don't enter a fix loop for P2s or P3s.
