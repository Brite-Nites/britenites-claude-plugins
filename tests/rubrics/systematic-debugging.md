---
skill: systematic-debugging
version: "1.0"
pass_threshold: 3.0
dimensions:
  - name: clarity
    threshold: 4
  - name: completeness
    threshold: 4
  - name: actionability
    threshold: 4
  - name: adherence
    threshold: 3
---

# Systematic Debugging Rubric

## Clarity (1-5)

Is the output well-organized, easy to follow, and free of confusion?

| Score | Anchor |
|-------|--------|
| 1 | Incoherent — debugging steps jumbled, no clear progression from symptom to root cause |
| 2 | Partially organized but isolation logic is hard to follow or root cause is ambiguous |
| 3 | Acceptable structure — phases exist but the reasoning chain from reproduction to fix could be clearer |
| 4 | Well-organized with clear phase progression, documented narrowing steps, and precise root cause statement |
| 5 | Exemplary — every phase is self-contained, the bisection path is traceable, root cause is unambiguous |

## Completeness (1-5)

Does the output cover all required aspects of the debugging task?

| Score | Anchor |
|-------|--------|
| 1 | Major gaps — jumps to a fix without reproduction or isolation |
| 2 | Addresses some phases but skips critical steps (e.g., no reproduction, no root cause categorization) |
| 3 | Covers basics — all 4 phases touched but defense-in-depth analysis is missing |
| 4 | Thorough — all 4 phases addressed with root cause categorized and regression test written |
| 5 | Comprehensive — all phases complete, defense-in-depth gaps identified, related patterns checked, full debugging report |

### Skill-Specific Completeness Criteria

- Documents reproduction with exact steps, expected vs actual behavior, and frequency (Phase 1)
- Narrows bug location using binary search, git bisect, or minimal reproduction (Phase 2)
- Records isolation path showing scope narrowed from broad to specific location (Phase 2)
- Identifies root cause category (logic, state, integration, environment, missing handling) (Phase 3)
- Performs defense-in-depth analysis: why tests, types, and review did not catch the bug (Phase 3)
- Writes failing regression test before applying fix (Phase 4 TDD red phase)
- Applies minimal fix, verifies test passes, runs full test suite (Phase 4)
- Adds defense-in-depth measures (type constraints, validation, assertions, error messages) (Phase 4)

## Actionability (1-5)

Can the fix be implemented and regression test written?

| Score | Anchor |
|-------|--------|
| 1 | No clear fix — root cause is guessed, no regression test, symptom suppressed |
| 2 | Fix direction is clear but implementation details or regression test are missing |
| 3 | Fix is implementable but regression test is weak or defense-in-depth measures absent |
| 4 | Clear fix with regression test that reproduces the original bug, full test suite passing |
| 5 | Minimal precise fix, strong regression test, defense-in-depth additions, related patterns fixed where applicable |

## Adherence to Instructions (1-5)

Does the output follow the systematic-debugging skill's defined protocol?

| Score | Anchor |
|-------|--------|
| 1 | Ignores protocol entirely — skips to guessing a fix without structured investigation |
| 2 | Follows some protocol but skips major required steps |
| 3 | Follows general protocol but misses specific requirements |
| 4 | Follows all major steps with minor deviations |
| 5 | Strict compliance — all phases, all artifacts, all rules followed |

### Skill-Specific Instruction Criteria

- Prints activation banner with symptom description
- Follows 4-phase structure: Reproduce, Isolate, Analyze, Fix with narration at each boundary
- Does not proceed to fixing without successful reproduction (or explicit user override)
- Uses binary search strategy for isolation (boundaries, assertions, bisection)
- Categorizes root cause into one of 5 categories (logic, state, integration, environment, missing handling)
- Logs root cause decision with Decision/Reason/Alternatives format
- Asks defense-in-depth questions (why not caught by tests, types, review)
- Writes failing test before applying fix (TDD red-green)
- Uses condition-based waiting for timing bugs (never arbitrary sleep/setTimeout)
- Removes debugging artifacts before shipping (extra logs, temporary assertions)
- Prints completion marker with root cause, regression test path, files changed, and compound learning note
