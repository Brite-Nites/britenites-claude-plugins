---
skill: best-practices-audit
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

# Best Practices Audit Rubric

## Clarity (1-5)

Is the output well-organized, easy to follow, and free of confusion?

| Score | Anchor |
|-------|--------|
| 1 | Incoherent — audit findings jumbled, no distinction between auto-fixes and flagged items |
| 2 | Partially organized but findings are hard to locate or lack context |
| 3 | Acceptable structure — sections exist but auto-fix vs flag distinction could be clearer |
| 4 | Well-organized with clear separation of auto-fixes, flagged items, and recommendations |
| 5 | Exemplary — each finding is precise with file references, dimension narration is crisp, report is scannable |

## Completeness (1-5)

Does the output cover all required aspects of the audit?

| Score | Anchor |
|-------|--------|
| 1 | Major gaps — skips most audit dimensions, superficial treatment |
| 2 | Addresses some dimensions but misses critical checks (e.g., no size check, no command accuracy) |
| 3 | Covers basics — hits required dimensions but lacks depth in analysis |
| 4 | Thorough — all 8 audit dimensions addressed with reasonable depth |
| 5 | Comprehensive — all dimensions covered, hook candidates identified, staleness verified, accuracy validated |

### Skill-Specific Completeness Criteria

- Checks CLAUDE.md size against thresholds (under 80 good, 80-120 acceptable, over 120 critical)
- Verifies all 4 required sections exist (Build & Test Commands, Code Conventions, Architecture Decisions, Gotchas & Workarounds)
- Evaluates @import structure for sections over ~10 lines
- Flags auto-exclude patterns (generic advice, standard conventions, file-by-file descriptions)
- Cross-references commands against package.json scripts
- Identifies hook candidates (rules that should be deterministic enforcement)
- Checks for staleness (references to removed files, old patterns, dead dependencies)
- Validates accuracy of file paths, @import paths, commands, and named references

## Actionability (1-5)

Can identified issues be fixed immediately?

| Score | Anchor |
|-------|--------|
| 1 | Findings are vague observations — no clear path to fixing anything |
| 2 | Some findings are actionable but most lack specificity or context |
| 3 | Findings point to real issues but require interpretation to resolve |
| 4 | Clear auto-fixes applied, flagged items have enough context for developer decision |
| 5 | Every finding is immediately actionable — auto-fixes already applied, flags include proposed resolution |

## Adherence to Instructions (1-5)

Does the output follow the best-practices-audit skill's defined protocol?

| Score | Anchor |
|-------|--------|
| 1 | Ignores protocol entirely — no audit dimensions, no report format |
| 2 | Follows some protocol but skips major required steps |
| 3 | Follows general protocol but misses specific requirements |
| 4 | Follows all major steps with minor deviations |
| 5 | Strict compliance — all dimensions checked, auto-fix vs flag distinction respected, report format followed |

### Skill-Specific Instruction Criteria

- Validates precondition (CLAUDE.md exists) before starting
- Prints activation banner with trigger reason
- Narrates at each dimension boundary (Dimension N/8: name)
- Reads best-practices reference from setup-claude-md skill if accessible
- Auto-fixes structural issues silently (reorder sections, remove self-evident entries, fix command syntax, extract long sections)
- Logs each auto-fix decision with Decision/Reason/Alternatives format
- Flags content changes for developer review (never auto-removes potentially intentional content)
- Verifies claims using dedicated tools, not Bash (file paths via Glob/Read, commands via Read of package.json)
- Classifies accuracy findings as Confirmed, Stale, or Unverifiable
- Produces final report with size status, accuracy stats, auto-fixes, flagged items, recommendations, hook candidates
- Prints completion marker with artifact summary and handoff to ship
