# BRI-1817: Review depth modes (fast / thorough / comprehensive)

## Task 1: Add depth mode parsing to `review.md` Step 3
- Add depth parsing at the top of Step 3, before agent selection
- Parse `$ARGUMENTS` for keywords: `fast`, `thorough`, `comprehensive` (default: `thorough`)
- `fast` → Tier 1 only, skip Tier 2 and Tier 3 entirely
- `thorough` → Tier 1 + Tier 2 (current behavior, no change)
- `comprehensive` → Tier 1 + Tier 2 + all Tier 3 agents (architecture-reviewer + accessibility-reviewer, regardless of CLAUDE.md overrides or directory count)
- Depth must coexist with existing `$ARGUMENTS` parsing ("skip simplify", "show all")
- Add narration showing selected depth mode

## Task 2: Update `docs/workflow-spec.md`
- Update `spec:steps:review` Step 3 to reference depth parameter
- Update `spec:errors:review` to add degradation for unrecognized depth mode (default to `thorough`)

## Task 3: Update `docs/workflow-guide.md`
- Add depth modes table to the `/workflows:review` section
- Show usage examples
- Note depth can combine with other flags

## Task 4: Update `CLAUDE.md` and `CHANGELOG.md`
- Add depth modes mention to review command description
- Add changelog entry
- Bump version in plugin.json and marketplace.json

## Task 5: Validate
- Run `scripts/validate.sh`
