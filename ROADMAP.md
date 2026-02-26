# Roadmap

Development plan for the Britenites Claude Plugins bundle.

For detailed issue tracking, see the [Linear project](https://linear.app/brite-nites/project/brite-claude-code-plugin-402b57908532).

## Philosophy

**Superpowers methodology + compound engineering + Linear integration.**

This is a **Process + Org plugin** — superpowers' full workflow (brainstorming, worktrees, bite-sized plans, subagent execution, TDD, code review, branch completion) with Linear woven into every step, compound engineering's knowledge accumulation, and Anthropic's best practices enforced automatically.

- **Process**: brainstorm → plan → worktree → execute (subagent-per-task + TDD) → review → compound → audit
- **Org**: Linear integration at every step, security hooks, team conventions, onboarding
- **Not domain**: Tech-stack skills (Python, Shopify, GCP, etc.) belong in separate domain plugins

Influenced by [superpowers](https://github.com/obra/superpowers) and [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin).

## The Three Workflows

### 1. Greenfield: `/britenites:project-start`
Runs once per project. Creates everything from scratch.
```
project-start → post-plan-setup (refine → issues → CLAUDE.md) → ready for sessions
```

### 2. Daily Work: The Inner Loop
Every coding session follows this sequence. Skills activate automatically:
```
session-start → brainstorm → plan → [worktree] → execute (subagent-per-task + TDD) → review → ship (compound + audit)
```
**User runs 3 commands**: session-start, review, ship. Everything else is skills that activate in sequence.

### 3. Direction-Setting: `/britenites:scope`
Collaborative creative session for deciding *what to build next*. Produces Linear issues.
```
scope → [Socratic discovery] → [ideation] → [Linear issue creation] → [prioritization]
```

## Current State (v3.0.0)

**Shipped:**
- 13 commands, 19 skills, 7 agents, 4 hook layers, 2 MCP servers
- Full inner loop: session-start → brainstorm → plan → worktree → execute → review → ship
- Compound methodology: knowledge accumulates across sessions via CLAUDE.md + memory
- Best-practices audit: auto-audit CLAUDE.md after every cycle
- Security: two-layer hooks (regex + haiku), pre-commit quality, auto-linter
- CI/CD: GitHub Actions validation, 5 test scripts

## Milestones

### Milestone 1: Foundation ✅
*Shipped Feb 2026 (v1.0.0 – v2.3.0)*

Plugin infrastructure, core commands, hooks, CI, docs.

### Milestone 2: The Inner Loop (expanded)
*Target: Mar 18, 2026*

Core session workflow. All skills needed for the full inner loop.

| Issue | Type | Priority | Status |
|-------|------|----------|--------|
| BRI-1617 | skill | High | **writing-plans** — bite-sized tasks, files, verification |
| BRI-1618 | skill | High | **executing-plans** — subagent-per-task + TDD + checkpoints |
| BRI-1619 | skill | High | **compound-learnings** — knowledge capture (invoked by ship) |
| BRI-1620 | skill | Medium | **systematic-debugging** — 4-phase root cause |
| BRI-1621 | enhancement | Medium | Enhance session-start with brainstorming + plans integration |
| BRI-1622 | enhancement | Medium | Enhance ship with compound + best-practices audit |
| BRI-1630 | documentation | High | Docs update for v3.0 ✅ |
| BRI-1636 | skill | High | **brainstorming** — Socratic discovery before planning ✅ |
| BRI-1637 | skill | Medium | **git-worktrees** — isolated workspace per task ✅ |
| BRI-1638 | skill | High | **best-practices-audit** — CLAUDE.md audit + auto-fix ✅ |
| BRI-1639 | skill | Medium | **verification-before-completion** — ensure tasks genuinely done ✅ |
| BRI-1640 | reference | High | Update best-practices reference from official Anthropic docs |

### Milestone 3: Scoping & Discovery
*Target: Apr 8, 2026*

Direction-setting and team coordination across sprints.

| Issue | Type | Priority | Status |
|-------|------|----------|--------|
| BRI-1641 | command | High | **scope** — collaborative creative scoping + Linear issues ✅ |
| BRI-1624 | command | Medium | **architecture-decision** — ADR generator |
| BRI-1626 | infrastructure | High | **Linear sync hook** — auto-status from git |

### Milestone 4: Orchestration
*Target: May 6, 2026*

Multi-agent coordination and automation.

| Issue | Type | Priority | Description |
|-------|------|----------|-------------|
| BRI-1352 | agent | Medium | **Onboarding agent** — Interactive setup wizard |
| BRI-1627 | enhancement | Low | Enhanced parallel review agents with scoring |

### Milestone 5: Plugin Ecosystem
*Target: Jun 3, 2026*

Tooling and templates for domain-specific plugins.

| Issue | Type | Priority | Description |
|-------|------|----------|-------------|
| BRI-1628 | infrastructure | High | Domain plugin template and `/create-plugin` generator |
| BRI-1629 | spike | Medium | Scaffold first domain plugin |

## What Makes This Different from Superpowers

1. **Linear integration at every step** — Issues inform brainstorming, branch names include issue IDs, ship updates status, scoping creates issues
2. **Compound methodology** — System gets smarter after every session via CLAUDE.md + memory
3. **Best-practices enforcement** — Auto-audit CLAUDE.md against Anthropic's guidelines, auto-fix, enforce `@import` structure
4. **Security hooks** — Two-layer regex + haiku protection
5. **Org conventions** — Brite-Nites-specific standards, onboarding, deployment

## Domain Plugin Strategy

Domain-specific knowledge lives in **separate plugins**:

- `britenites-shopify` — Shopify Plus / Liquid patterns
- `britenites-data` — dbt, BigQuery, Prefect patterns
- `britenites-hubspot` — HubSpot CRM integration patterns

Each domain plugin is its own repo, scaffolded from the template in Milestone 5.
