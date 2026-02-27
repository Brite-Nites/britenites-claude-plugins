---
name: writing-plans
description: Breaks work into bite-sized tasks before coding. Activates when a multi-step task needs planning — creates tasks small enough for a junior developer to follow (2-5 minutes each), with exact file paths, complete implementation details, and verification steps. References Linear issue context and project-specific test commands from CLAUDE.md.
user-invocable: false
---

# Writing Plans

You are creating a detailed execution plan that breaks work into bite-sized tasks. Each task should be small enough that a fresh subagent with no prior context can execute it correctly.

## When to Activate

- After brainstorming (if it ran) or directly after issue selection for straightforward work
- When the developer approves the approach and is ready to plan implementation
- NOT for tasks that are already a single atomic change

## Context Loading

Before writing the plan, gather:

1. **Linear issue details** — Description, acceptance criteria, linked docs
2. **Design document** — If brainstorming produced one (`docs/designs/[issue-id]-*.md`)
3. **Project CLAUDE.md** — Build commands, test commands, conventions, architecture
4. **Relevant source code** — Files that will be modified or referenced
5. **Test patterns** — How existing tests are structured in this project

## Plan Structure

Save the plan to `docs/plans/[issue-id]-plan.md`:

```markdown
# Plan: [Issue Title]

**Issue**: [ID] — [Title]
**Branch**: [branch-name]
**Tasks**: N (estimated [time])

## Prerequisites
- [Any setup needed before starting]
- [Dependencies that must be in place]

## Tasks

### Task 1: [Short imperative title]
**Files**: `path/to/file.ts`, `path/to/test.ts`
**Why**: [One sentence — what this accomplishes]

**Implementation**:
1. [Exact change to make]
2. [Exact change to make]

**Test**:
- Write test: [describe the test]
- Run: `[exact test command]`
- Expected: [what passing looks like]

**Verify**: [how to confirm this task is done]

---

### Task 2: [Short imperative title]
...

## Task Dependencies
- Task 3 depends on Task 1 (needs the interface defined in Task 1)
- Tasks 4 and 5 are independent (can run in parallel)

## Verification Checklist
- [ ] All tests pass: `[test command]`
- [ ] Build succeeds: `[build command]`
- [ ] Lints clean: `[lint command]`
- [ ] [Issue-specific acceptance criteria]
```

## Task Writing Rules

### Size
- Each task should take **2-5 minutes** for a focused agent
- If a task has more than 5 implementation steps, split it
- If a task touches more than 3 files, split it
- A task that "adds a REST endpoint" is too big. "Add the route handler", "add the validation schema", "add the test" are right-sized.

### Self-Contained Context
Each task must include everything a fresh agent needs:
- **Exact file paths** — no "find the relevant file"
- **Complete implementation details** — not "implement the function" but what the function does, its signature, its behavior
- **Explicit constraints** — from CLAUDE.md conventions (naming, patterns, imports)
- **Test specification** — what to test, how to run it, what success looks like

### Ordering
- Tasks that define interfaces/types come before tasks that use them
- Tests can be written before or alongside implementation (TDD preference)
- Mark independent tasks explicitly — they can be parallelized
- Group related tasks but maintain clear boundaries

### Verification Steps
Every task ends with a verification step that is:
- **Automated** — a command that returns pass/fail, not "visually inspect"
- **Specific** — `npm test -- --grep "auth"` not just "run tests"
- **From CLAUDE.md** — use the project's actual test/build/lint commands

## Plan Approval

After writing the plan:

1. Present a summary: task count, estimated complexity, key decisions
2. Ask: "Does this plan look right? Any tasks to add, remove, or reorder?"
3. **If approved**: Plan is ready for execution via the `executing-plans` skill
4. **If changes requested**: Iterate and re-present

## Rules

- Never write vague tasks. "Set up the database" is bad. "Add Prisma model `User` with fields `id`, `email`, `name`, `createdAt` to `prisma/schema.prisma`" is good.
- Include the TDD cycle in task structure: test file changes alongside implementation changes.
- If the plan exceeds 12 tasks, suggest splitting into multiple PRs/issues.
- Reference `_shared/validation-pattern.md` for self-checking after plan creation.
- Plan files persist across sessions — a new session can pick up where the last left off.
