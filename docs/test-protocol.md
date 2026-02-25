# Flow Test Protocol

Manual verification checklist for testing each plugin flow. Run through this after any significant plugin change.

## Prerequisites

- [ ] Fresh terminal (not inside Claude)
- [ ] Plugin installed or loaded via `--plugin-dir`
- [ ] A test Linear project with at least 1 open issue
- [ ] GitHub CLI authenticated (`gh auth status`)

## Test 1: Plugin Loading

- [ ] Start session with `claude --plugin-dir ./plugins/britenites`
- [ ] Type `/britenites:` and verify all 9 commands appear in autocomplete
- [ ] SessionStart hook fires and prints the environment health banner
- [ ] Environment checks show git, node, gh, npx status

**Expected commands:**
`tech-stack`, `session-start`, `review`, `ship`, `code-review`, `project-start`, `setup-claude-md`, `onboarding-checklist`, `smoke-test`

## Test 2: Smoke Test

- [ ] Run `/britenites:smoke-test`
- [ ] All environment checks pass (git, node, npx)
- [ ] gh CLI check passes or skips with clear message
- [ ] MCP connectivity checks run (sequential-thinking, Linear)
- [ ] Hook verification step triggers a security block (expected)
- [ ] Agent dispatch test completes
- [ ] Final table is rendered with PASS/FAIL/SKIP for all checks

## Test 3: Session Start Flow

- [ ] Run `/britenites:session-start`
- [ ] Step 0 runs — verifies Linear + sequential-thinking MCP
- [ ] Step 1 checks git status
- [ ] Step 2 queries Linear and shows issue table
- [ ] Select an issue → verify it creates an execution plan
- [ ] Approve the plan → verify branch is created
- [ ] ABORT (don't execute — this is just a loading test)

## Test 4: Review Flow

- [ ] Make a small change on a test branch (add a comment to a file)
- [ ] Run `/britenites:review`
- [ ] Step 0 runs — agent dispatch verification
- [ ] Step 1: self-verification runs (git diff, test suite)
- [ ] Step 2: 3 agents dispatched in parallel (code, security, TypeScript)
- [ ] Step 3: findings report generated with P1/P2/P3 sections
- [ ] Step 5: verdict rendered

## Test 5: Ship Flow

- [ ] With committed changes on a test branch
- [ ] Run `/britenites:ship`
- [ ] Step 0 runs — verifies `gh auth status` and repo connectivity
- [ ] Step 1: pre-ship checks run (tests, build, clean state)
- [ ] Step 2: PR is created with correct template
- [ ] Step 3: Linear issue is updated
- [ ] Step 4: compound learnings step runs
- [ ] Step 5: session summary shown
- [ ] DELETE the test PR after verification

## Test 6: Code Review

- [ ] Run `/britenites:code-review` on a small diff
- [ ] Verify findings are generated with P1/P2/P3
- [ ] Run `/britenites:code-review --deep`
- [ ] Verify 3 agents are dispatched

## Test 7: Project Start (abbreviated)

- [ ] Run `/britenites:project-start` in a temp directory
- [ ] Select "Technical collaborator"
- [ ] Answer 2-3 questions then verify it's following Path B
- [ ] ABORT before file creation — this is a flow test, not a full run

## Results

```
Date:    ____-__-__
Version: ____
Tester:  ____
Pass:    __/7
Fail:    __/7
Notes:   ____
```
