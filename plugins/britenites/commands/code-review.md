---
description: Standardized code review for Britenites projects
---

# Code Review

Perform a thorough code review following Britenites standards. Reference the tech stack established in `/britenites:tech-stack` for technology-specific expectations.

## Determine Review Scope

First, determine what to review based on the user's input:

**If `$ARGUMENTS` specifies a PR number or URL:** Use `gh pr diff` to get the changes and `gh pr view` for context.

**If `$ARGUMENTS` specifies files or directories:** Review those files directly.

**If `$ARGUMENTS` is empty:** Check for uncommitted changes with `git diff` and `git diff --staged`. If there are none, ask the user what to review.

## Review Process

Work through each section. Only report issues you actually find — skip sections with no findings.

### 1. Correctness

- Does the code do what it's supposed to?
- Are there logic errors, off-by-one mistakes, or unhandled edge cases?
- Are conditionals and loops correct?
- Are null/undefined/empty states handled?

### 2. Security

- Input validation at system boundaries (user input, API payloads, URL params)
- SQL injection, XSS, command injection risks
- Secrets or credentials in code (API keys, passwords, tokens)
- Proper authentication/authorization checks
- CORS and CSP configuration where applicable

### 3. Frontend Checklist (React / Next.js / TypeScript)

Only apply if reviewing frontend code. Defer to the **react-best-practices** skill for the full 45-rule audit (waterfalls, bundle size, re-renders, server components, etc.). In this review, focus on:

- Server vs. client component boundaries are correct (Next.js App Router)
- Tailwind CSS used for styling (not CSS modules or styled-components)
- TypeScript types are meaningful (no excessive `any`)
- Zod schemas validate external data at system boundaries

### 4. Backend Checklist (FastAPI / Python)

Only apply if reviewing backend code:

- Pydantic models validate request/response data
- Async endpoints where I/O-bound
- SQLAlchemy queries are efficient (no N+1, proper joins)
- Alembic migrations are reversible
- Error responses follow consistent format
- Type hints on all function signatures
- Black/Ruff formatting compliance

### 5. Data Engineering Checklist

Only apply if reviewing data code:

- Prefect flows have proper error handling and retries
- BigQuery queries are cost-conscious (avoid `SELECT *`, use partitioning)
- dbt models follow the project's naming conventions
- Data transformations are idempotent
- Schema changes are backward-compatible

### 6. Code Quality

- Functions and variables have clear, descriptive names
- No dead code, commented-out code, or TODO comments without tracking
- DRY violations (duplicated logic that should be shared)
- Functions are focused (single responsibility)
- Error handling is appropriate (not swallowing errors silently)
- Tests cover the new/changed behavior

### 7. Architecture

- Changes align with existing project patterns
- New dependencies are justified and from the approved tech stack
- No unnecessary abstractions or premature optimization
- File and folder structure follows project conventions

## Output Format

Present findings grouped by severity:

**Critical** — Must fix before merge (bugs, security issues, data loss risks)

**Recommended** — Should fix, improves quality (code smells, missing tests, unclear naming)

**Nit** — Optional polish (formatting, style preferences, minor improvements)

For each finding, include:
1. File and line reference
2. What the issue is
3. Why it matters
4. Suggested fix (code snippet when helpful)

End with a summary: total findings by severity, overall assessment (approve, request changes, or needs discussion), and any positive callouts for well-written code.
