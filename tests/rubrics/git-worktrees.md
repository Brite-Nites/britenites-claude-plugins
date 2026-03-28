---
skill: git-worktrees
version: "1.0"
pass_threshold: 3.0
dimensions:
  - name: clarity
    weight: 1.0
    threshold: 4
  - name: completeness
    weight: 1.0
    threshold: 4
  - name: actionability
    weight: 1.0
    threshold: 4
  - name: adherence
    weight: 1.0
    threshold: 3
---

# Git Worktrees Rubric

## Clarity (1-5)

Is the output well-organized, easy to follow, and free of confusion?

| Score | Anchor |
|-------|--------|
| 1 | Incoherent — setup steps jumbled, worktree path unclear, baseline results missing |
| 2 | Partially organized but key details (branch name, base commit, baseline status) hard to find |
| 3 | Acceptable structure — steps executed but status reporting could improve |
| 4 | Well-organized with clear step narration, worktree path, branch name, and baseline results |
| 5 | Exemplary — every step narrated, all artifacts listed, baseline results precise, zero confusion about workspace state |

## Completeness (1-5)

Does the output cover all required aspects of the worktree setup task?

| Score | Anchor |
|-------|--------|
| 1 | Major gaps — worktree not created, no baseline verification, no dependency installation |
| 2 | Worktree created but significant steps skipped (e.g., no baseline tests, no dependency install) |
| 3 | Covers basics — worktree exists and dependencies installed but baseline verification incomplete |
| 4 | Thorough — all 5 steps completed with test/build/lint baseline recorded |
| 5 | Comprehensive — full setup including env file handling, dirty-state recovery, and artifact inventory from prior phases |

### Skill-Specific Completeness Criteria

- Reads plan file at `docs/plans/<issue-id>-plan.md` and extracts context
- Checks for design doc via Glob (`docs/designs/<issue-id>-*.md`)
- Verifies git prerequisites: inside work tree, clean state, fetches latest
- Creates worktree with correct branch naming: `[issue-id]/[short-description]`
- Worktree placed in `.claude/worktrees/[issue-id]`
- Dependencies installed based on detected package manager
- Environment setup handled (`.env.example` copied if needed)
- Clean baseline verified: tests, build, lint all run and results recorded
- Completion marker printed with worktree path, branch, base commit, and baseline results

## Actionability (1-5)

Is the workspace ready for development?

| Score | Anchor |
|-------|--------|
| 1 | Workspace unusable — worktree not created or in broken state |
| 2 | Worktree exists but dependencies missing or baseline unknown |
| 3 | Workspace functional but some setup incomplete (e.g., env vars not configured, baseline not recorded) |
| 4 | Ready for development — worktree clean, dependencies installed, baseline recorded |
| 5 | Immediately productive — full setup complete, baseline documented, known failures flagged, executing-plans can start without any additional setup |

## Adherence to Instructions (1-5)

Does the output follow the git-worktrees skill's defined protocol?

| Score | Anchor |
|-------|--------|
| 1 | Ignores protocol entirely — no worktree, creates branch directly in main working directory |
| 2 | Follows some protocol but skips major required steps (e.g., no baseline verification) |
| 3 | Follows general protocol but misses specific requirements (e.g., branch naming convention, worktree path) |
| 4 | Follows all major steps with minor deviations |
| 5 | Strict compliance — all 5 steps, all naming conventions, all artifacts produced correctly |

### Skill-Specific Instruction Criteria

- Prints activation banner with trigger reason
- Follows 5-step structure: Verify Prerequisites, Create Branch & Worktree, Project Setup, Verify Clean Baseline, Confirm Ready
- Narrates step progress (e.g., `Step 2/5: Creating branch and worktree... done`)
- Validates issue ID matches `^[A-Z]+-[0-9]+$` before use in shell commands
- Branch naming follows `[issue-id]/[short-description]` convention
- Description slugified: lowercase, hyphens, max 50 chars, validated against `^[a-z0-9][a-z0-9-]*[a-z0-9]$`
- Worktree based on latest `origin/main` (or default branch)
- Worktree placed in `.claude/worktrees/` (not project root)
- Uses EnterWorktree tool when available, falls back to manual git commands
- Handles dirty working directory via error recovery (stash/commit/abort options)
- Handles baseline test failures via error recovery (proceed/investigate/stop options)
- Prints completion marker with worktree path, branch, base commit hash, and baseline results
- Hands off to executing-plans
