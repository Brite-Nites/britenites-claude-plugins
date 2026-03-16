# BRI-1627: Dynamic Agent Selection + Expanded Review Agent Roster

## Summary

Transform `/workflows:review` from a static 3-agent system to a dynamic 8-agent system with stack-aware selection. Projects get the right reviewers automatically — TypeScript reviewers skip Python projects, data reviewers only activate when Prisma/migrations exist, accessibility reviewers trigger on JSX changes.

## Research

Landscape scan of 10+ implementations (see Linear issue for full sources):

| Source | Agents | Selection | Key takeaway |
|--------|--------|-----------|-------------|
| Anthropic `code-review` (official) | 4 | Static | 9-step pipeline, model tiering, aggressive false-positive filtering |
| Anthropic `pr-review-toolkit` (official) | 6 | Opt-in | comment-analyzer, test-analyzer, silent-failure-hunter, type-design, code-reviewer, simplifier |
| Compound Engineering | 15 | Dynamic (setup skill) | Stack defaults + config file, `compound-engineering.local.md` |
| HAMY (community) | 9 | Static | Most comprehensive, ~75% useful rate, includes dependency/deployment safety |
| Qodo PR-Agent | 15+ | Dynamic (orchestrator) | Judge agent for dedup, recommendation agent with PR history |
| CodeRabbit | Multi-dim | Profile-based | 40 integrated static analyzers, "Chill" vs "Assertive" modes |
| claude-review-loop | 4 | Conditional | Project-type file detection (Next.js config → Next.js agent) |

**Key findings:**
- Industry standard is 6-15 agents with dynamic selection
- Every successful implementation uses parallel dispatch
- Confidence scoring is the primary false-positive reduction mechanism
- Stack-specific agents (Rails, Python, TS) are universally conditional

**Dimensions we're missing vs the landscape:**
- Performance (N+1, bundle, memory) — in 4+ tools
- Data/migrations (constraints, transactions) — in 2+ tools
- Python conventions — in 2+ tools
- Architecture (coupling, SOLID) — in 2+ tools
- Accessibility (WCAG, a11y) — in 2 tools
- Test quality (coverage effectiveness, flakiness) — in 3+ tools (deferred to follow-up)

## Tasks

### Task 1: Create performance-reviewer agent
**File:** `plugins/workflows/agents/performance-reviewer.md`
**Time:** ~3 min

Create agent file with frontmatter matching existing agent pattern. Review areas:
1. **Algorithmic complexity** — O(n²)+ without justification, nested loops over collections
2. **Database queries** — N+1 patterns (Prisma `.findMany` in loops), missing `include`/`select`, unbounded queries
3. **Memory** — Unbounded arrays, large object retention, missing cleanup in effects/subscriptions
4. **Bundle size** — Heavy imports (`import lodash` vs `import get from 'lodash/get'`), dynamic import candidates
5. **Caching** — Missing memoization (`useMemo`/`useCallback` candidates), repeated expensive computations
6. **Network** — Redundant API calls, missing request batching, overfetching

Output: P1/P2/P3 severity with `file:line` references.

**Verify:** Agent file passes validate.sh Section 9 (agent frontmatter).

### Task 2: Create python-reviewer agent
**File:** `plugins/workflows/agents/python-reviewer.md`
**Time:** ~3 min

Create agent file. Reference `python-best-practices` skill for rule categories but keep the agent prompt self-contained. Review areas:
1. **FastAPI patterns** — Dependency injection, response models, async endpoint correctness
2. **Pydantic v2** — Model validators, field constraints, serialization
3. **Type hints** — Missing annotations, `Any` usage, incorrect generics
4. **Async patterns** — Blocking calls in async functions, missing `await`, sync DB in async context
5. **Error handling** — Bare `except`, missing HTTP error responses, swallowed exceptions
6. **Import organization** — Circular imports, unused imports, wildcard imports

Output: P1/P2/P3 severity with `file:line` references.

**Verify:** Agent file passes validate.sh Section 9.

### Task 3: Create data-reviewer agent
**File:** `plugins/workflows/agents/data-reviewer.md`
**Time:** ~3 min

Create agent file. Review areas:
1. **Migration safety** — Destructive operations without confirmation, missing rollback, data loss risk
2. **Schema constraints** — Missing NOT NULL, missing unique constraints, incorrect cascade behavior
3. **Transaction boundaries** — Multi-step operations without transactions, long-running transactions
4. **Query safety** — Raw SQL without parameterization, unbounded queries, missing pagination
5. **Prisma-specific** — Missing `@relation`, incorrect `onDelete`, `findFirst` without `where` uniqueness
6. **Data privacy** — PII in logs, missing encryption for sensitive fields, retention concerns

Output: P1/P2/P3 severity with `file:line` references.

**Verify:** Agent file passes validate.sh Section 9.

### Task 4: Create architecture-reviewer agent
**File:** `plugins/workflows/agents/architecture-reviewer.md`
**Time:** ~3 min

Create agent file. Review areas:
1. **Coupling** — Direct imports across module boundaries, shared mutable state, tight integration
2. **SOLID violations** — God components, classes doing too much, incorrect abstraction levels
3. **Dependency direction** — Lower layers importing from higher layers, circular dependencies
4. **Boundary violations** — Business logic in UI components, data access in route handlers
5. **Pattern consistency** — Mixed patterns within the same codebase (e.g., some services use DI, others don't)
6. **API surface** — Overly broad exports, missing encapsulation, leaky abstractions

Output: P1/P2/P3 severity with `file:line` references.

**Verify:** Agent file passes validate.sh Section 9.

### Task 5: Create accessibility-reviewer agent
**File:** `plugins/workflows/agents/accessibility-reviewer.md`
**Time:** ~3 min

Create agent file. Review areas:
1. **WCAG 2.1 compliance** — Missing alt text, insufficient color contrast references, missing form labels
2. **Keyboard navigation** — Missing `tabIndex`, non-interactive elements with click handlers, focus trap issues
3. **ARIA** — Missing `aria-label`, incorrect `role`, redundant ARIA on semantic elements
4. **Screen reader** — Content order vs visual order mismatches, missing live regions for dynamic content
5. **Interactive elements** — Buttons as divs, links without href, missing disabled states
6. **Responsive** — Touch target sizes, zoom support, viewport units for text

Output: P1/P2/P3 severity with `file:line` references.

**Verify:** Agent file passes validate.sh Section 9.

### Task 6: Add dynamic agent selection to review.md Step 3
**File:** `plugins/workflows/commands/review.md`
**Time:** ~5 min

Modify Step 3 (Launch Review Agents) to add selection logic before dispatch:

```
### 3a. Select review agents

Start with Tier 1 (always): code-reviewer, security-reviewer, performance-reviewer.

Detect project stack by checking for file markers using Glob:
- `tsconfig.json` exists → add typescript-reviewer
- `pyproject.toml` OR `requirements.txt` exists → add python-reviewer
- `prisma/schema.prisma` OR `alembic/` OR `**/migrations/` exists → add data-reviewer

Check diff scope:
- Run `git diff BASE...HEAD --name-only` and count distinct top-level directories
- If 5+ directories changed → add architecture-reviewer
- If any `.tsx` or `.jsx` files changed → add accessibility-reviewer (only if CLAUDE.md enables it)

Check for CLAUDE.md override:
- Read project CLAUDE.md for a `## Review Agents` section
- If found, parse `include:` and `exclude:` lists
- `include:` adds agents regardless of auto-detection
- `exclude:` removes agents regardless of auto-detection

Narrate: `Step 3/7: Selected N review agents: code-reviewer, security-reviewer, performance-reviewer, typescript-reviewer (tsconfig.json detected). Launching in parallel...`
```

Update the dispatch to launch all selected agents (not hardcoded 3). Update agent dispatch error recovery to name the failed agent.

**Verify:** Step sequence passes validate.sh Section 13. Narration uses `N/7` format.

### Task 7: Enhance Step 4 deduplication for cross-agent findings
**File:** `plugins/workflows/commands/review.md`
**Time:** ~2 min

Update Step 4 (Collect & Classify) to handle variable agent count and cross-agent dedup:

1. When multiple agents flag the same `file:line`, keep the finding with the most specific agent (e.g., prefer `data-reviewer` over `code-reviewer` for a Prisma issue)
2. Include agent source badge for each finding in the report
3. Update the summary format: `**Sources**: [agent-name] (N findings)` for each agent that ran
4. If an agent returned 0 findings, note it: `security-reviewer: clean`

**Verify:** No stale references to "3 agents" or hardcoded agent names in the collection step.

### Task 8: Update workflow-spec.md
**File:** `docs/workflow-spec.md`
**Time:** ~3 min

1. Update review step sequence YAML — Step 3 name to "Select & Launch Review Agents"
2. Update error handling — add entries for "Stack detection fails" (degrade: use Tier 1 only) and "CLAUDE.md override parse fails" (degrade: ignore overrides, use auto-detection)
3. Update cross-skill contract — review `provides` list should mention agent selection results

**Verify:** Step sequence YAML is valid and consistent with review.md.

### Task 9: Update workflow-guide.md
**File:** `docs/workflow-guide.md`
**Time:** ~2 min

1. Update review step table — Step 3 description to mention dynamic selection
2. Add a "Review Agents" subsection under Section 2 (Skill Reference) listing all 8 agents with their tiers and activation conditions
3. Add a note about the `## Review Agents` CLAUDE.md override convention

**Verify:** Step table matches review.md steps.

### Task 10: Update CLAUDE.md
**File:** `CLAUDE.md` (repo root)
**Time:** ~2 min

Add documentation for the review agent override convention. In the Skill Routing section, update the review description and add the `## Review Agents` convention:

```markdown
## Review Agents (optional override)

include: [architecture-reviewer, accessibility-reviewer]
exclude: [typescript-reviewer]
```

**Verify:** CLAUDE.md is accurate against the actual agent files.

### Task 11: Update validate.sh cross-references
**File:** `scripts/validate.sh`
**Time:** ~2 min

Section 10 (Cross-References) scans command files for agent name references. With 5 new agents referenced in review.md, verify they're detected as "referenced by a skill or command" (not orphaned). The existing grep pattern should work since review.md mentions all agents by name — verify and fix if needed.

**Verify:** `scripts/validate.sh` passes with all 12 agents (7 existing + 5 new) showing as referenced.

### Task 12: Version bump + verification
**Files:** `plugins/workflows/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
**Time:** ~1 min

Bump version 3.19.0 → 3.20.0 in both files. Run full validation suite.

**Verify:**
- `scripts/validate.sh` — all sections pass
- `scripts/test-hooks.sh` — 37/37 pass
- `scripts/test-skill-triggers.sh` — 38/38 pass
- No stale "3 agents" references in review.md
- All 8 agents referenced in review.md exist as files
