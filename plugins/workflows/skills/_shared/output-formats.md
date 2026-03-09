## Standard Output Formats

Reusable output formatting templates for Brite skills. Reference this file when producing structured output.

### Severity Classification

Use this 3-tier system for review-type outputs:

| Severity | Meaning | Action |
|----------|---------|--------|
| **Critical** | Bugs, security issues, data loss risks | Must fix |
| **Recommended** | Code smells, missing tests, unclear naming | Should fix |
| **Nit** | Formatting, style preferences, minor polish | Optional |

### Finding Format

For each finding in a review or audit:

```
**[Severity]** `file:line` — Brief description

Why: Explanation of impact
Fix: Suggested resolution (code snippet when helpful)
Confidence: N/10
```

### Confidence Scoring

Self-assessed confidence on a 1-10 scale. Include with every finding.

| Score | Meaning | When to use |
|-------|---------|-------------|
| 9-10 | Certain | Exact code path identified, evidence unambiguous |
| 7-8 | High | Strong evidence, minor gaps in trace |
| 5-6 | Medium | Pattern-based, depends on runtime context |
| 3-4 | Low | Educated guess from common anti-patterns |
| 1-2 | Speculative | Feels off, no concrete failure scenario |

Threshold: findings with confidence >= 7 are included in reports. Lower-confidence P2/P3s are filtered. Lower-confidence P1s are kept but marked for human review.

### Summary Block

End review-type outputs with:

```
---
**Summary**: X critical, Y recommended, Z nits
**Verdict**: Approve / Request Changes / Needs Discussion
**Callouts**: Note any particularly well-written code
```

### Progress Format

For multi-step workflows:

```
Step 1/N: Description... done
Step 2/N: Description... done
Step 3/N: Description... in progress
```

### Validation Result Format

For skills using the validation-pattern.md:

```
Validation:
  - Criterion A: PASS
  - Criterion B: FAIL — reason
  - Criterion C: PASS

Result: 2/3 passed. Retrying failed criteria...
```
