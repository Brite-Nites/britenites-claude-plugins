---
name: systematic-debugging
description: Four-phase root cause analysis for bug investigation. Activates when debugging unexpected behavior, failing tests, or production issues — follows reproduce, isolate, analyze, fix with defense-in-depth. Uses condition-based waiting instead of arbitrary delays. Available anytime, not tied to the inner loop sequence.
user-invocable: true
---

# Systematic Debugging

You are investigating a bug using a structured four-phase process. The goal is to find and fix the root cause, not just suppress the symptom.

## When to Activate

- Bug reports or unexpected behavior
- Failing tests that shouldn't be failing
- Production issues or error reports
- "It works on my machine" type problems
- Any situation where the cause isn't immediately obvious

## Phase 1: Reproduce

Before anything else, reliably reproduce the problem.

### Steps
1. **Understand the report** — What's expected? What's happening instead? When did it start?
2. **Reproduce locally** — Run the exact steps that trigger the bug
3. **Document the reproduction**:
   ```
   ## Reproduction
   Steps: [exact steps]
   Expected: [what should happen]
   Actual: [what happens instead]
   Frequency: [always / intermittent / specific conditions]
   Environment: [OS, Node version, browser, etc.]
   ```
4. **If intermittent**: Identify conditions that increase frequency (load, timing, specific data)

### If You Can't Reproduce
- Check environment differences (versions, config, data)
- Add logging to narrow down when/where it occurs
- Ask the reporter for more details
- Do NOT proceed to fixing without reproduction — you'll likely fix the wrong thing

## Phase 2: Isolate

Narrow down where the bug lives.

### Binary Search Strategy
1. **Identify the boundaries** — Which systems/modules are involved in the failing flow?
2. **Add assertions at boundaries** — Verify inputs and outputs at each layer
3. **Bisect** — Is the problem in the frontend or backend? In the handler or the model? In the query or the transformation?
4. **Narrow until you find the exact location** — The specific function, line, or condition

### Isolation Techniques
- **Git bisect** — If the bug is a regression, find the commit that introduced it: `git bisect start`, `git bisect bad`, `git bisect good [known-good-commit]`
- **Minimal reproduction** — Strip away unrelated code until you have the smallest case that fails
- **Logging** — Add targeted logging (not scattershot `console.log` everywhere)
- **Assertion insertion** — Add `assert` statements at key points to catch violations

### What to Record
```
## Isolation
Location: [file:line or module]
Narrowed from: [original scope] → [isolated location]
Method: [how you narrowed it down]
```

## Phase 3: Analyze Root Cause

Understand *why* the bug exists, not just *where*.

### Root Cause Categories
1. **Logic error** — Code does the wrong thing (off-by-one, wrong operator, missing case)
2. **State corruption** — Data gets into an invalid state (race condition, missing validation, stale cache)
3. **Integration mismatch** — Two components disagree on interface, format, or protocol
4. **Environment issue** — Config, version, or platform difference
5. **Missing handling** — Edge case, error path, or boundary not covered

### Analysis Questions
- Why does this code exist? What was the original intent?
- What changed recently? (Check git log for the area)
- Are there similar patterns elsewhere that work correctly? What's different?
- Is this the only place this bug manifests, or is it a systemic issue?

### Defense in Depth
After identifying the root cause, ask:
- Why wasn't this caught by tests?
- Why wasn't this caught by types?
- Why wasn't this caught by code review?
- What other similar bugs might exist?

```
## Root Cause
Cause: [precise description]
Category: [logic / state / integration / environment / missing handling]
Why it wasn't caught: [gap in testing, types, or review]
Related risks: [other places with similar patterns]
```

## Phase 4: Fix

Fix the root cause and prevent regression.

### Fix Process
1. **Write a failing test** that reproduces the bug (TDD red phase)
2. **Verify the test fails** — It should fail for the same reason as the bug
3. **Apply the minimal fix** — Change as little as possible
4. **Verify the test passes** — The fix resolves the bug
5. **Run the full test suite** — The fix doesn't break anything else
6. **Check for related issues** — Fix similar patterns elsewhere if applicable

### Defense-in-Depth Fixes
Beyond the immediate fix, consider:
- **Add type constraints** that would prevent this class of bug
- **Add validation** at the boundary where bad data enters
- **Add assertions** that would catch this sooner
- **Improve error messages** so the next person gets a clearer signal

### Condition-Based Waiting
If the bug involves timing or async behavior:
- **Never use arbitrary delays** (`sleep 5`, `setTimeout(5000)`)
- **Wait for conditions**: poll for the expected state, with a timeout
- **Example**: Instead of `sleep 2 && check_result`, use `while ! check_result; do sleep 0.1; done` with a max iteration count

### Fix Report
```
## Fix
Change: [what was changed and why]
Files: [list of modified files]
Test: [the regression test that was added]
Defense: [additional protective measures added]
Related fixes: [similar patterns fixed elsewhere, or "none"]
```

## Completion

Present the full debugging report:

```
## Debugging Complete: [Brief title]

**Bug**: [one-line description]
**Root cause**: [one-line root cause]
**Fix**: [one-line fix description]

**Reproduction** → **Isolation** → **Analysis** → **Fix**
[Link to each section above]

**Regression test**: [test name and how to run it]
**Tests**: All passing
**Build**: Clean

**Compound learning**: [If this revealed a pattern, it should be captured via compound-learnings]
```

## Rules

- Never fix a bug you can't reproduce — you're guessing
- Never suppress a symptom without understanding the root cause
- Always add a regression test — bugs that come back are morale killers
- Log your debugging process — it helps others (and future you) with similar bugs
- Don't scatter `console.log` — add targeted, informative logging
- Remove debugging artifacts (extra logs, temporary assertions) before shipping, unless they improve production observability
- If the bug is in a dependency, document the workaround and file an upstream issue
