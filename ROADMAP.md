# Roadmap

Development plan for the Britenites Claude Plugins bundle.

For detailed issue tracking, see the [Linear project](https://linear.app/brite-nites/project/brite-claude-code-plugin-402b57908532).

## Philosophy

This is a **Process + Org plugin** — it teaches *how* to work, not *what* to know about specific technologies.

- **Process**: Structured planning, step-by-step execution, parallel review, knowledge compounding
- **Org**: Linear integration, Britenites conventions, security hooks, team onboarding
- **Not domain**: Tech-stack skills (Python, Shopify, GCP, etc.) belong in separate domain plugins

Influenced by [superpowers](https://github.com/obra/superpowers) (61.8k stars, process-first methodology) and [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin) (9.6k stars, plan→work→review→compound cycle).

## Core Workflow

```
session-start → [plan] → [execute] → review → [compound] → ship
       ↑                                                      |
       └──────────── sprint-planning ← retrospective ←────────┘
```

The **inner loop** (plan → execute → review → compound) happens in a single session.
The **outer loop** (sprint-planning → sessions → retrospective) happens across sprints.

## Current State (v2.3.0)

**Shipped:**
- 12 commands, 12 skills, 7 agents, 4 hook layers, 2 MCP servers
- Core workflow: session-start → (ad-hoc coding) → review → ship
- Security: two-layer hooks (regex + haiku), pre-commit quality, auto-linter
- CI/CD: GitHub Actions validation, 5 test scripts
- Docs: README, CHANGELOG, CONTRIBUTING, ARCHITECTURE, CLAUDE.md

**Gap:** The middle of the workflow (planning, execution, compounding) is undefined. Session-start creates a loose plan, but there's no structured methodology for *how* to plan, execute, or capture learnings.

## Milestones

### Milestone 1: Foundation ✅
*Shipped Feb 2026 (v1.0.0 – v2.3.0)*

Plugin infrastructure, core commands, hooks, CI, docs. Everything through v2.3.0.

### Milestone 2: The Inner Loop
*Target: Mar 18, 2026*

How a developer plans, executes, and compounds knowledge in a single work session.

| Issue | Type | Priority | Description |
|-------|------|----------|-------------|
| BRI-1617 | skill | High | **writing-plans** — Structured planning with bite-sized tasks, exact files, verification steps |
| BRI-1618 | skill | High | **executing-plans** — Task-by-task execution with checkpoints and progress tracking |
| BRI-1619 | skill | High | **compound-learnings** — Knowledge capture and compounding after each task |
| BRI-1620 | skill | Medium | **systematic-debugging** — Four-phase root-cause analysis methodology |
| BRI-1621 | enhancement | Medium | Enhance session-start with writing-plans integration |
| BRI-1622 | enhancement | Medium | Enhance ship with explicit compound step |
| BRI-1630 | documentation | High | Update docs for v3.0 process-first refactor |

### Milestone 3: The Outer Loop
*Target: Apr 8, 2026*

How a team manages work across sprints and projects.

| Issue | Type | Priority | Description |
|-------|------|----------|-------------|
| BRI-1623 | command | High | **sprint-planning** — Linear-integrated sprint planning and prioritization |
| BRI-1624 | command | Medium | **architecture-decision** — ADR generator for technology decisions |
| BRI-1625 | command | Medium | **retrospective** — Sprint retro facilitation using Linear data |
| BRI-1626 | infrastructure | High | **Linear sync hook** — Auto-update Linear from git activity |

### Milestone 4: Orchestration
*Target: May 6, 2026*

Multi-agent coordination and automation.

| Issue | Type | Priority | Description |
|-------|------|----------|-------------|
| BRI-1352 | agent | Medium | **Onboarding agent** — Interactive setup wizard for new developers |
| BRI-1627 | enhancement | Low | Enhanced parallel review agents with scoring |

### Milestone 5: Plugin Ecosystem
*Target: Jun 3, 2026*

Tooling and templates for spinning up domain-specific plugins.

| Issue | Type | Priority | Description |
|-------|------|----------|-------------|
| BRI-1628 | infrastructure | High | Domain plugin template and `/create-plugin` generator |
| BRI-1629 | spike | Medium | Scaffold first domain plugin (Shopify or Data Engineering) |

## Domain Plugin Strategy

Domain-specific knowledge lives in **separate plugins**, not this one:

- `britenites-shopify` — Shopify Plus / Liquid patterns for Brite Supply
- `britenites-data` — dbt, BigQuery, Prefect patterns for data team
- `britenites-hubspot` — HubSpot CRM integration patterns

Each domain plugin is its own repo with its own Linear project, scaffolded from the template in Milestone 5.

## Competitive Context

The Claude Code plugin ecosystem (834+ plugins, 43 marketplaces) is organizing into three archetypes:

| Type | Examples | Focus |
|------|----------|-------|
| **Process** | superpowers, compound-engineering | How you work |
| **Domain** | marketingskills (32 marketing skills) | What you know |
| **Org** | Enterprise internal plugins | How your team works |

This plugin is **Process + Org**. Our differentiators:
1. **Linear integration** — Tight PM integration (session-start, ship, sprint-planning)
2. **Security-first hooks** — Two-layer regex + haiku, injection prevention
3. **Compound methodology** — Knowledge compounds across sessions via CLAUDE.md and memory
4. **Org conventions** — Tech stack, onboarding, deployment standards
