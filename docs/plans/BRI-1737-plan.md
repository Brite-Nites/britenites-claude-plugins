# BRI-1737: Core Testing Patterns + Vitest Skill — Execution Plan

## Overview
Create `plugins/workflows/skills/testing-strategy/` with SKILL.md (quick reference) and AGENTS.md (full compiled rules). Follows python-best-practices pattern.

## Rule Categories (8 categories, ~32 rules)

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

## Tasks

### Task 1: Create SKILL.md (~120 lines)
**File:** `plugins/workflows/skills/testing-strategy/SKILL.md`
**Details:**
- Frontmatter: `name: testing-strategy`, `description: ...`, `user-invocable: true`
- "When to Apply" section — 5 trigger scenarios
- Category priority table (above)
- Quick Reference — 8 subsections, each with category header + bulleted rules (prefix + one-liner)
- Reference to AGENTS.md for full details
**Verify:** Frontmatter name matches directory name, description is unquoted plain YAML

### Task 2: Create AGENTS.md (~300-400 lines)
**File:** `plugins/workflows/skills/testing-strategy/AGENTS.md`
**Details:**
- Full compiled document with all ~32 rules
- Each rule: h3 header with prefix, explanation, code example
- Code examples use Vitest/RTL/MSW syntax
- Organized by the 8 categories above
**Verify:** All rules referenced in SKILL.md quick reference are detailed here

### Task 3: Update CLAUDE.md skill routing
**File:** `CLAUDE.md` (project root)
**Details:**
- Add `testing-strategy` to the "Design, backend & quality skills" section (or rename section)
- Entry: `| testing-strategy | Quality | Writing, reviewing, or refactoring test code |`
**Verify:** Table formatting is consistent

### Task 4: Update plugin version + CHANGELOG
**Files:** `plugins/workflows/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `CHANGELOG.md`
**Details:**
- Bump version 3.7.0 → 3.8.0 (new skill = minor bump)
- Add CHANGELOG entry under `## [3.8.0]`
**Verify:** `scripts/validate.sh` passes

### Task 5: Run validation
**Command:** `bash scripts/validate.sh`
**Verify:** All checks pass (JSON valid, frontmatter valid, skill name matches directory)
