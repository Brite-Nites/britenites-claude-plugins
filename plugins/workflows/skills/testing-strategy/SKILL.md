---
name: testing-strategy
description: Use when writing, reviewing, or refactoring test code. Triggers on Vitest tests, React Testing Library usage, MSW handlers, test structure decisions, or coverage configuration. Contains 32 testing rules across 8 categories.
user-invocable: true
---

# Testing Strategy — Core Patterns + Vitest

Testing patterns and conventions for Vitest, React Testing Library, and MSW. Contains 32 rules across 8 categories, prioritized by impact. Focuses on patterns that produce reliable, maintainable tests — test isolation, mock boundaries, query priorities, and meaningful coverage.

## When to Apply

Reference these guidelines when:
- Writing new test files or test cases
- Reviewing test code for correctness and maintainability
- Deciding what to mock and what to test through
- Setting up test infrastructure (MSW, factories, fixtures)
- Configuring coverage thresholds or CI test pipelines
- Refactoring flaky or brittle tests

## Target Versions

- Vitest 3.x
- React Testing Library 16.x
- MSW 2.x
- @testing-library/user-event 14.x

## Rule Categories by Priority

| Priority | Category | Impact | Prefix | Rules |
|----------|----------|--------|--------|-------|
| 1 | Test Structure | CRITICAL | `struct-` | 5 |
| 2 | Mocking Strategy | HIGH | `mock-` | 4 |
| 3 | Vitest Patterns | HIGH | `vitest-` | 5 |
| 4 | React Testing Library | HIGH | `rtl-` | 4 |
| 5 | MSW & API Mocking | MEDIUM-HIGH | `msw-` | 3 |
| 6 | Fixtures & Factories | MEDIUM | `fixture-` | 4 |
| 7 | Coverage & CI | MEDIUM | `ci-` | 4 |
| 8 | Snapshot Testing | LOW-MEDIUM | `snap-` | 3 |

## Quick Reference

### 1. Test Structure (CRITICAL)

- `struct-arrange-act-assert` — Follow AAA pattern: setup, execute, verify in every test
- `struct-single-concept` — Each test verifies one behavior, not multiple assertions on different things
- `struct-descriptive-names` — Test names describe behavior: "shows error when email is invalid", not "test1"
- `struct-test-isolation` — Tests must not depend on other tests' state or execution order
- `struct-no-logic` — No conditionals, loops, or try/catch in tests — tests are straight-line code

### 2. Mocking Strategy (HIGH)

- `mock-boundaries` — Mock at system boundaries (network, filesystem, time), not internal modules
- `mock-reset` — Reset mocks between tests to prevent state leakage
- `mock-minimal` — Mock the minimum needed — over-mocking makes tests pass when code is broken
- `mock-type-safety` — Mocked return values must match the real type signature

### 3. Vitest Patterns (HIGH)

- `vitest-vi-mock` — Use vi.mock for module mocking, vi.spyOn for method spying
- `vitest-test-each` — Use test.each for parameterized tests instead of loops
- `vitest-setup-teardown` — Use beforeEach/afterEach for per-test setup, beforeAll/afterAll for expensive shared setup
- `vitest-in-source` — Use in-source testing for pure utility functions when appropriate
- `vitest-fake-timers` — Use vi.useFakeTimers for time-dependent code, always restore after

### 4. React Testing Library (HIGH)

- `rtl-query-priority` — Query by role > label > text > testId. Avoid container.querySelector
- `rtl-user-event` — Use userEvent over fireEvent for realistic user interaction simulation
- `rtl-async-queries` — Use findBy for elements that appear asynchronously, waitFor for assertions
- `rtl-avoid-implementation` — Test behavior, not implementation — don't assert on state or props

### 5. MSW & API Mocking (MEDIUM-HIGH)

- `msw-handlers` — Define default handlers in a shared handlers file, override per-test for edge cases
- `msw-server-setup` — Use setupServer in test setup, resetHandlers in afterEach, close in afterAll
- `msw-response-assertions` — Assert on rendered output from API responses, not on whether fetch was called

### 6. Fixtures & Factories (MEDIUM)

- `fixture-factories` — Use factory functions that return valid defaults with optional overrides
- `fixture-no-shared-mutation` — Never mutate shared fixture objects — create fresh instances per test
- `fixture-realistic-data` — Use realistic data shapes, not placeholder strings like "test" or "abc"
- `fixture-builders` — Use builder pattern for complex objects with many optional fields

### 7. Coverage & CI (MEDIUM)

- `ci-meaningful-coverage` — Measure branch coverage, not just line coverage. Target 80% as a floor, not a ceiling
- `ci-parallel-execution` — Run tests in parallel by default; isolate tests that need serial execution
- `ci-flaky-quarantine` — Quarantine flaky tests immediately, fix root cause, don't retry-and-ignore
- `ci-test-splitting` — Split test suites across CI workers by file for faster pipelines

### 8. Snapshot Testing (LOW-MEDIUM)

- `snap-inline-small` — Use inline snapshots for small outputs (< 10 lines), file snapshots for large
- `snap-avoid-large` — Never snapshot entire component trees — snapshot the specific output that matters
- `snap-review-updates` — Review every snapshot update in diffs — never blindly run --update

## Linting & Formatting

For ESLint test plugins (eslint-plugin-testing-library, eslint-plugin-vitest) and other tooling, see the **code-quality** skill.

## Full Compiled Document

For the complete guide with all rules expanded and code examples: `AGENTS.md`
