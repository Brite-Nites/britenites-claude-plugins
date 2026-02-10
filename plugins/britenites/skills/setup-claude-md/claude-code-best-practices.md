# Claude Code Best Practices — Reference

## CLAUDE.md Best Practices
- Include all bash commands (build, test, lint, typecheck, single-test)
- Document code style conventions specific to the project
- Keep it concise — under 150 lines ideal, performance degrades with length
- Include common pitfalls and gotchas
- Add verification checklists
- Never include generic advice — every line must be project-specific
- Use short, imperative sentences; avoid prose paragraphs
- Put the most important commands first (build/test/lint)

## Context Window Management
- Context fills fast; performance degrades as it fills
- Scope conversations to one feature/task at a time
- Use /clear between unrelated tasks
- Break large projects into plans saved to files, not held in context
- Use sub-agents (context: fork) for multi-phase work
- Prefer file-based communication between phases over context passing

## Plan Before Coding
- Use Plan Mode to separate exploration from execution
- Four phases: explore → plan → review → execute
- Never let the agent jump straight to coding on complex tasks
- Save plans to files so they survive context resets
- Include validation criteria in every plan step

## Verification
- Include tests, screenshots, or expected outputs for self-checking
- Run build, lint, and typecheck after every meaningful change
- Invest in making verification rock-solid — agents can only self-correct
  if they can detect their own mistakes
- Prefer automated checks over manual review
- Test commands should be runnable with a single command

## Task Decomposition for Agents
- Each task needs full context (an agent should never need to ask questions)
- Include: what to do, why, relevant files, constraints, how to verify
- Complexity estimate (S/M/L) helps agents plan their approach
- Explicit dependencies prevent ordering mistakes
- Self-contained tasks can be parallelized across agents

## Writing Effective Issue Descriptions
- Start with Context section: background, architectural decisions, constraints
- Include Implementation Steps: numbered, specific, but not over-prescriptive
- End with Validation Criteria: concrete checks the agent runs after completing
- Link to relevant files and prior decisions
- An agent reading the issue cold should be able to start immediately

## Sub-Agent Best Practices
- Use context: fork to give each phase a clean context window
- Communicate between phases via files, not context
- Each sub-agent should have a focused role and limited tool access
- Validate sub-agent output before proceeding to next phase
- Keep sub-agent instructions under 500 lines for best performance

## Hooks
- Pre-edit: run formatters on files being changed
- Post-edit: run typecheck on changed files
- Keep hooks lightweight to avoid token consumption
- Hooks run automatically — use them for guardrails, not features

## Common Anti-Patterns to Avoid
- Bloated CLAUDE.md with generic advice (>150 lines degrades performance)
- Too many complex slash commands competing for context
- Excessive MCP tools (>20k tokens of MCPs degrades performance)
- Skipping the planning phase on non-trivial tasks
- Not verifying agent output before marking tasks complete
- Circular dependencies in task graphs
- Holding large plans in context instead of saving to files
- Over-prescriptive steps that prevent agents from problem-solving
- Missing validation criteria that leave completion ambiguous

## CLAUDE.md Section Checklist
Use this when generating a new CLAUDE.md:
- [ ] Project Overview (2-3 sentences)
- [ ] Bash Commands (build, test, lint, typecheck, dev, single-test)
- [ ] Code Style (imports, naming, module system, formatting)
- [ ] Architecture (patterns, state, data flow, directories)
- [ ] Workflow Rules (branches, commits, PRs, CI)
- [ ] Testing Conventions (framework, naming, coverage)
- [ ] Environment Setup (env vars, secrets, dependencies)
- [ ] Common Pitfalls (gotchas, fragile areas)
- [ ] Verification Checklist (pre-completion checks)
