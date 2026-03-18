# Trait Model Validation — Real Brite Projects

**Issue:** BC-2124
**Date:** 2026-03-18
**Author:** Holden Halford

## Summary

Validated the PRD's 11-trait classification system against 5 real Brite projects. Key findings: the trait set provides good coverage (all projects classifiable, no project left traitless), but detection signals have accuracy issues — `client-facing` and `automation` signals produce false positives, and `involves-data` references BigQuery instead of Snowflake. The `has-external-users` / `client-facing` distinction is valid but easily confused. Path A/B autonomy level is orthogonal to traits and should be a separate dimension. Recommendations: keep 11 traits, fix 4 detection signals, clarify 2 trait descriptions, add signal exclusion rules.

## Projects Classified

| # | Project | Type | Status | Team | Lead |
|---|---------|------|--------|------|------|
| 1 | **Plugin Repo** (britenites-claude-plugins) | Claude Code plugin platform — commands, skills, hooks in markdown/shell/JSON | In Progress | Brite Company | Amanuel Belay |
| 2 | **Handbook** (Brite Handbook) | Company knowledge base — 659 markdown files, GitBook + GitHub | In Progress | Brite Company | Jaime Lyons |
| 3 | **Data Platform** (Brite Enterprise Data Platform) | Data warehouse + pipelines — Snowflake, Fivetran, dbt Cloud, Python services | In Progress | Brite Company | Corinne Brewer |
| 4 | **Recruiting** (Brite Recruiting) | Seasonal hiring strategy — ~90 hires/year across 12 markets, vendor evaluation | In Progress | Brite Nites | Michael Menendez |
| 5 | **Website** (Brite Labs Website) | Commercial/experiential lighting website for Brite Labs entity | In Progress | Brite Company | Kells Nixon |

## Classification Matrix

Y = Present, N = Absent

| Trait | Plugin | Handbook | Data Platform | Recruiting | Website |
|-------|--------|----------|---------------|------------|---------|
| `produces-code` | Y (Med) | N (High) | Y (High) | N (High) | Y (High) |
| `produces-documents` | Y (High) | Y (High) | N (Med) | Y (High) | N (High) |
| `involves-data` | N (High) | N (High) | Y (High) | N (High) | N (High) |
| `requires-decisions` | Y (High) | N (Med) | Y (High) | Y (High) | Y (Med) |
| `has-external-users` | N (High) | N (High) | N (High) | N (Med) | Y (High) |
| `client-facing` | N (High) | N (High) | N (High) | N (High) | N (High) |
| `needs-design` | N (High) | N (High) | N (High) | N (High) | Y (High) |
| `needs-marketing` | N (High) | N (High) | N (High) | N (High) | Y (High) |
| `needs-sales` | N (High) | N (High) | N (High) | N (High) | N (High) |
| `cross-team` | Y (High) | Y (High) | Y (High) | Y (High) | N (High) |
| `automation` | Y (Med) | N (High) | Y (High) | N (High) | N (High) |

**Trait counts per project:** Plugin: 5, Handbook: 2, Data Platform: 5, Recruiting: 3, Website: 4

---

## Detailed Classification

### 1. Plugin Repo

**Expected traits:** `produces-documents`, `requires-decisions`, `cross-team`, `automation`, possibly `produces-code`

| Trait | Classification | Evidence |
|-------|---------------|----------|
| `produces-code` | **Y** (Med) | Writes shell scripts (hooks, validate.sh, pre-commit.sh), JS (inject-claude-md.mjs, pretooluse-skill-inject.mjs), JSON (plugin.json, hooks.json), YAML (CI workflows). Primary output is markdown, but the repo has real code requiring CI and quality gates. The infrastructure `produces-code` activates (GitHub repo, CI, pre-commit) is genuinely needed. |
| `produces-documents` | **Y** (High) | Commands are markdown, skills are markdown, design docs, research docs, ADRs. Documentation IS the product. |
| `involves-data` | **N** (High) | No data analysis, no warehouse, no metrics dashboards. |
| `requires-decisions` | **Y** (High) | ADR 001 (cross-repo import solution) is a first-class decision. Plugin architecture, hook design, skill routing are all documented decisions. |
| `has-external-users` | **N** (High) | Internal tooling for the Brite engineering team. |
| `client-facing` | **N** (High) | No external client relationship. |
| `needs-design` | **N** (High) | No visual design. |
| `needs-marketing` | **N** (High) | No marketing needs. |
| `needs-sales` | **N** (High) | No sales needs. |
| `cross-team` | **Y** (High) | Infrastructure used by all Brite teams. Part of "Shared Infrastructure to Move Quick" initiative. Affects how every project is set up and managed. |
| `automation` | **Y** (Med) | CI/CD (GitHub Actions), pre-commit hooks, SessionStart hooks, auto-linting hooks. But automation is supportive, not the project's primary purpose. |

**Boundary analysis — `produces-code`:** The plugin repo has JS hooks, shell scripts, and CI workflows. It has a GitHub repo, .gitignore, and CI — exactly what `produces-code` activates. The PRD signals ("build an app", "create a tool", "implement", "programming languages mentioned") would fire on "create a tool" and the presence of JS/shell. **Verdict: Y.** The trait SHOULD activate because the infrastructure it provides (GitHub repo, CI, pre-commit) is genuinely needed. The fact that the primary output is markdown doesn't change that the repo has real code requiring CI and quality gates. Classifying it N would either miss needed infrastructure or require special-case logic.

### 2. Handbook

**Expected traits:** `produces-documents`, `cross-team`, `automation`

| Trait | Classification | Evidence |
|-------|---------------|----------|
| `produces-code` | **N** (High) | Primary output is markdown documentation. Has some automation scripts but code isn't the product. |
| `produces-documents` | **Y** (High) | 659 markdown files across 15+ directories. Documentation IS the entire product. |
| `involves-data` | **N** (High) | Documents data concepts and metric definitions but doesn't analyze data. |
| `requires-decisions` | **N** (Med) | Decisions about content structure and taxonomy exist (handbook restructure, maturity model) but decision-making isn't the primary purpose. No formal ADR process. |
| `has-external-users` | **N** (High) | Internal audience — employees and AI agents. |
| `client-facing` | **N** (High) | No external client relationship. |
| `needs-design` | **N** (High) | GitBook provides the design. "Identity & Brand" milestone is about documenting the brand, not designing it. |
| `needs-marketing` | **N** (High) | Not a marketing effort. Contains marketing team content but the handbook itself isn't marketing. |
| `needs-sales` | **N** (High) | Contains "Sales Handbook MVP" milestone but that's documenting sales processes, not doing sales. |
| `cross-team` | **Y** (High) | Company-wide knowledge base. 11 milestones spanning operations, sales, marketing, engineering, onboarding. Serves every department. |
| `automation` | **N** (High) | Has CI, GitBook sync, Slack notifications, link validation — but all of this is maintenance tooling, not the project's purpose. The handbook is a documentation project that *uses* automation, not an automation project. Reclassified from Y (Low) to N after review — this is the canonical example of the `automation` signal false positive. |

### 3. Data Platform

**Expected traits:** `produces-code`, `involves-data`, `requires-decisions`, `cross-team`, `automation`

| Trait | Classification | Evidence |
|-------|---------------|----------|
| `produces-code` | **Y** (High) | Python pipeline services (acquisition, enrichment, scoring), dbt models (SQL), infrastructure code. GitHub repo: brite-data-platform. |
| `produces-documents` | **N** (Med) | Has documentation but it's supportive, not the primary output. |
| `involves-data` | **Y** (High) | This IS the data platform. Snowflake warehouse, 7 core marts, 10+ data sources, Fivetran ingestion, dbt transformation. |
| `requires-decisions` | **Y** (High) | Active vendor evaluations: Fivetran vs Airbyte vs Stitch for ingestion, BI tool selection (Lightdash, Metabase, Sigma, Hex), architecture decisions for pipeline orchestration. |
| `has-external-users` | **N** (High) | Internal analytics platform for Brite team. |
| `client-facing` | **N** (High) | No external client deliverables. |
| `needs-design` | **N** (High) | BI dashboards are tool-driven (Metabase/Lightdash), not custom-designed. |
| `needs-marketing` | **N** (High) | Not a marketing effort. Provides marketing analytics but isn't marketing. |
| `needs-sales` | **N** (High) | Not a sales effort. Provides sales analytics but isn't sales. |
| `cross-team` | **Y** (High) | Serves every department — marketing (channel attribution, CAC), sales (pipeline, conversion), operations (job profitability, workforce efficiency), finance (budget analysis). Part of "Shared Infrastructure to Move Quick" initiative. |
| `automation` | **Y** (High) | Data pipelines, ETL/ELT orchestration, scheduled Fivetran syncs, dbt Cloud CI/CD, queue-based processing with cost tracking. Automation is central to the project's purpose. |

**Note:** This is the densest project — 5 traits activated. Each trait independently provides useful infrastructure. The combination represents a "data engineering" archetype that's common enough to potentially warrant a recognized pattern template (see Q8).

### 4. Recruiting

**Expected traits:** `produces-documents`, `requires-decisions`, `cross-team`, possibly `involves-data`

| Trait | Classification | Evidence |
|-------|---------------|----------|
| `produces-code` | **N** (High) | Phase 1 is pure strategy and research. Has a GitHub repo for documentation but produces no application code. Phase 2 MIGHT involve code (ATS integration, custom tooling) but that's future scope. |
| `produces-documents` | **Y** (High) | Strategy docs, recruiting playbooks, candidate ICPs, scoring rubrics, compensation frameworks, vendor evaluations. Documentation is the primary deliverable. |
| `involves-data` | **N** (High) | Uses data (headcount models, scoring rubrics, compensation ranges) but at spreadsheet level, not data engineering. Doesn't need Snowflake MCP verification or data source configuration. Reclassified from Y (Low) — this is the canonical example of the "metrics" signal false positive. The project is data-*informed* strategy, not data infrastructure. |
| `requires-decisions` | **Y** (High) | Build-vs-buy ATS evaluation (TeamTailor, Rippling, Salesforce, Workable, Lever/Ashby, custom build). Milestone 4 is literally "Tooling Decision Made." Multiple competing options with scoring matrices. |
| `has-external-users` | **N** (Med) | Candidates are external to the company but they're not "users" of a product. The recruiting process serves internal hiring managers. Medium confidence because "users" is ambiguous — candidates do interact with whatever ATS is chosen. |
| `client-facing` | **N** (High) | No external client relationship. Internal stakeholders (Holden as project owner, territory managers as consumers of hiring pipeline). |
| `needs-design` | **N** (High) | No visual design needed for strategy/process work. |
| `needs-marketing` | **N** (High) | Related to employer branding but the project is process design, not marketing campaigns. |
| `needs-sales` | **N** (High) | No sales component. |
| `cross-team` | **Y** (High) | 12 markets, affects operations teams in every territory, involves HR (Gusto), finance (compensation), and operations (seasonal workforce). Cross-functional by nature. |
| `automation` | **N** (High) | No CI/CD, no pipelines, no scheduled jobs. The project is strategy and process design. Future ATS implementation might add automation but that's out of scope. |

**Reclassified — `involves-data`:** Changed from Y (Low) to N (High) after review. The recruiting project uses data in its analysis (headcount models, scoring rubrics, market breakdowns) but doesn't need data infrastructure. Activating `involves-data` would generate unnecessary infrastructure (Snowflake MCP verification, data source configuration). This validates the recommendation to add co-occurrence requirements to the "metrics" signal.

### 5. Website (Brite Labs Website)

**Expected traits:** `produces-code`, `has-external-users`, `needs-design`, `needs-marketing`, `requires-decisions`, possibly `client-facing`

| Trait | Classification | Evidence |
|-------|---------------|----------|
| `produces-code` | **Y** (High) | Website = code. Will involve HTML/CSS/JS, likely Next.js given Brite's tech stack. |
| `produces-documents` | **N** (High) | Not a documentation project. |
| `involves-data` | **N** (High) | Not data-focused. Will have analytics (GA, etc.) but data isn't the project's concern. |
| `requires-decisions` | **Y** (Med) | Tech stack, CMS, hosting, domain decisions. But these may be pre-determined by Brite's existing stack (Next.js, Vercel, Brite Design System). Medium confidence because decisions may be trivial/pre-answered. |
| `has-external-users` | **Y** (High) | Public-facing website for Brite Labs commercial entity. Potential clients, partners, and the general public will visit. |
| `client-facing` | **N** (High) | The website *attracts* clients but the project itself has no client relationship — no external deliverables, no communication cadence with a specific client, no SOW. `has-external-users` + `needs-marketing` already capture the external-facing nature. Reclassified from Y (Med) after review. |
| `needs-design` | **Y** (High) | Visual brand identity for Brite Labs. Portfolio/showcase of commercial lighting installations. High-quality visual design is essential. |
| `needs-marketing` | **Y** (High) | Part of "Enter Commercial & Experiential" initiative. The website IS a marketing tool — positioning Brite Labs for commercial lighting contracts. |
| `needs-sales` | **N** (High) | Supports sales indirectly by showcasing capabilities, but `needs-marketing` already covers client attraction. No pricing strategy, proposals, or sales decks are project deliverables. |
| `cross-team` | **N** (High) | Single entity (Brite Labs), single lead (Kells Nixon). Not org-wide. |
| `automation` | **N** (High) | Standard deployment CI doesn't make this an "automation project." |

**Note:** The Brite Labs Website project has minimal information in Linear (no description, no milestones). Classifications are inferred from the project's nature, initiative context ("Enter Commercial & Experiential"), and Brite Labs' role as the commercial entity.

---

## Signal Accuracy Assessment

For each trait, I evaluate whether the PRD detection signals (lines 1078-1090) would correctly identify the trait during an interview about each project.

| Trait | Signal | Would Fire On | Should Fire? | Accuracy |
|-------|--------|---------------|-------------|----------|
| `produces-code` | "build an app", "create a tool" | Plugin ("create a tool"), Data ("build"), Website ("build") | Yes for all three | **Correct** |
| `produces-code` | "programming languages mentioned" | Plugin (JS, shell), Data (Python, SQL), Website (React/TS) | Yes — but also fires on Handbook if someone mentions "shell scripts for CI" | **Mostly correct**, minor false positive risk |
| `produces-documents` | "write a plan", "create docs" | Plugin, Handbook, Recruiting | Yes for all three | **Correct** |
| `involves-data` | "BigQuery" | None — Brite uses Snowflake | Should fire on Data Platform conversations that mention Snowflake | **WRONG** — stale signal |
| `involves-data` | "metrics", "dashboard" | Data, Recruiting (metrics), Handbook (metrics section) | Data: yes. Recruiting/Handbook: no — they mention metrics but don't need data infrastructure | **Overfires** — 2 false positives |
| `requires-decisions` | "evaluate", "choose between" | Plugin, Data, Recruiting, Website | Correct for all | **Correct** |
| `has-external-users` | "customers", "users" | Website ("customers", "users"). Also Data Platform if someone says "internal users" | Website: correct. Data: would be false positive | **Mostly correct**, ambiguous "users" |
| `client-facing` | "deadline", "deliverable" | Plugin, Handbook, Data, Recruiting, Website — nearly ALL projects have deadlines | None should trigger — no project has an external client relationship | **OVERFIRES** — 5 false positives |
| `client-facing` | "stakeholder" | Plugin, Data, Recruiting — all have internal stakeholders | None of these are client-facing | **OVERFIRES** — 3 false positives |
| `needs-design` | "brand", "visual" | Website, Handbook ("Identity & Brand" milestone) | Website: correct. Handbook: false positive (documenting brand, not designing it) | **Mostly correct**, 1 false positive |
| `needs-marketing` | "launch", "landing page" | Website, possibly Recruiting ("launch recruiting program") | Website: correct. Recruiting: false positive | **Mostly correct**, 1 false positive |
| `needs-sales` | "pricing", "sales deck" | None of 5 projects | Correct — none need sales infrastructure | **Correct** |
| `cross-team` | "multiple teams", "org-wide" | Plugin, Handbook, Data, Recruiting | Correct for all | **Correct** |
| `automation` | "CI/CD" | Plugin, Handbook, Data, Website (all have CI) | Only Plugin and Data should trigger (automation is central to purpose) | **OVERFIRES** — 2 false positives |
| `automation` | "pipeline" | Data ("data pipeline"), Plugin ("review pipeline") | Data: correct. Plugin: false positive (review pipeline is a metaphor, not automation) | **Mostly correct**, 1 false positive |

### Signal Accuracy Summary

| Rating | Signals |
|--------|---------|
| **Correct** (no issues) | `produces-documents`, `requires-decisions`, `needs-sales`, `cross-team` signals ("multiple teams", "org-wide") |
| **Mostly correct** (1 false positive) | `produces-code`, `has-external-users`, `needs-design`, `needs-marketing` |
| **Overfires** (2+ false positives) | `involves-data` ("metrics"), `client-facing` ("deadline", "deliverable", "stakeholder"), `automation` ("CI/CD") |
| **Wrong** (stale) | `involves-data` ("BigQuery") |

---

## False Positives

These are specific signal → trait mappings that would fire during an interview but should NOT classify the project with that trait.

| Signal | Project | Trait Assigned | Why It's Wrong |
|--------|---------|---------------|---------------|
| "deadline" | Recruiting | `client-facing` | Recruiting has internal deadlines (season start ~October) but no external client. "Deadline" is universal — nearly every project has one. |
| "deadline" | Data Platform | `client-facing` | Data platform has target dates for milestones but serves internal teams, not clients. |
| "deadline" | Plugin Repo | `client-facing` | Plugin repo has release targets but is internal infrastructure. |
| "stakeholder" | Data Platform | `client-facing` | "Stakeholder" is used for internal consumers of the data platform (marketing, sales, ops teams). Not external clients. |
| "stakeholder" | Recruiting | `client-facing` | Internal stakeholders (territory managers, HR). |
| "deliverable" | Recruiting | `client-facing` | Strategy documents are deliverables but to internal team, not external clients. |
| "CI/CD" | Handbook | `automation` | Handbook has CI for markdown validation and GitBook sync. CI is a maintenance tool, not the project's purpose. |
| "CI/CD" | Website | `automation` | Any deployed website has CI/CD. The website is a marketing site, not an automation project. |
| "metrics" | Recruiting | `involves-data` | Recruiting mentions KPIs and headcount metrics but doesn't need data infrastructure (Snowflake MCP, data source config). |
| "metrics" | Handbook | `involves-data` | Handbook documents metric definitions but doesn't analyze data. |
| "BigQuery" | Any project | `involves-data` | Brite uses Snowflake, not BigQuery. Signal is stale. |
| "pipeline" | Plugin Repo | `automation` | "Review pipeline" is a metaphorical pipeline (review process), not a data/automation pipeline. |

### False Positive Risk by Trait

| Trait | False Positive Risk | Root Cause |
|-------|-------------------|------------|
| `client-facing` | **High** | Signals "deadline", "deliverable", "stakeholder" apply to virtually all projects |
| `automation` | **Medium** | Signal "CI/CD" fires for any project with continuous integration |
| `involves-data` | **Medium** | Signal "metrics" fires for any project that mentions KPIs; "BigQuery" is wrong |
| `needs-marketing` | **Low** | Signal "launch" is ambiguous but less common in non-marketing contexts |
| All others | **Low** | Signals are sufficiently specific |

---

## Orthogonality Analysis

### Co-occurrence Matrix

Counts how many of the 5 projects activate both traits simultaneously.

|  | prod-code | prod-docs | inv-data | req-dec | ext-users | client | design | marketing | sales | cross-team | automation |
|--|-----------|-----------|----------|---------|-----------|--------|--------|-----------|-------|------------|------------|
| **prod-code** | 3 | 1 | 1 | 2 | 1 | 0 | 1 | 1 | 0 | 2 | 2 |
| **prod-docs** | — | 3 | 0 | 2 | 0 | 0 | 0 | 0 | 0 | 3 | 1 |
| **inv-data** | — | — | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 1 | 1 |
| **req-dec** | — | — | — | 4 | 1 | 0 | 1 | 1 | 0 | 3 | 2 |
| **ext-users** | — | — | — | — | 1 | 0 | 1 | 1 | 0 | 0 | 0 |
| **client** | — | — | — | — | — | 0 | 0 | 0 | 0 | 0 | 0 |
| **design** | — | — | — | — | — | — | 1 | 1 | 0 | 0 | 0 |
| **marketing** | — | — | — | — | — | — | — | 1 | 0 | 0 | 0 |
| **sales** | — | — | — | — | — | — | — | — | 0 | 0 | 0 |
| **cross-team** | — | — | — | — | — | — | — | — | — | 4 | 2 |
| **automation** | — | — | — | — | — | — | — | — | — | — | 2 |

### Observations

**Strong co-occurrence (potential redundancy):**
- `needs-design` and `needs-marketing` co-occur perfectly (1/1). Semantically distinct: a design system (scenario 11) needs design but not marketing. A blog/content strategy (scenario 13) needs marketing but not design. **Not redundant.**

**Note on `has-external-users` vs `client-facing`:** After reclassifying the Website from `client-facing` Y to N, these traits have zero co-occurrence in our sample. The Website has external users (public visitors) but no client relationship. This validates that the distinction is real and useful — `client-facing` is specifically for projects with deliverables to a named external client (SOWs, client proposals, client onboarding). Appendix C confirms independent activation: scenario 6 (browser extension) has `has-external-users` alone; scenario 47 (client onboarding) has `client-facing` alone.

**Strong orthogonality (never co-occur):**
- `needs-sales` with everything — never activated in our sample. Appendix C shows it activating in scenarios 9, 19, 21, 23, 46 with various partners. **Orthogonal and valid**, just not represented in current Brite projects.
- `has-external-users` / `client-facing` / `needs-design` / `needs-marketing` with `cross-team` — 0 co-occurrence. This suggests an internal/external divide: outward-facing traits and inward-facing traits rarely combine. This makes sense — cross-team infrastructure projects serve internal teams, while user-facing products serve external audiences.
- `produces-documents` with `has-external-users` — 0 co-occurrence in our sample. But Appendix C shows scenarios 14, 15, 18 where they combine (newsletter, conference talk, training materials). **Not fundamentally orthogonal**, just not in our sample.

**Frequent co-occurrence (expected, not redundant):**
- `requires-decisions` + `cross-team` (3/4 cross-team projects) — cross-team projects inherently involve more decisions. Different traits: one captures decision methodology needs, the other captures stakeholder coordination needs.
- `produces-documents` + `cross-team` (3/3 document projects) — documentation projects tend to serve multiple teams. But Appendix C has solo doc projects (scenario 17: technical writing, scenario 28: code review process). Not always correlated.
- `cross-team` + `automation` (2/2 automation projects) — automation projects tend to be infrastructure that serves multiple teams. But automation can be single-team (scenario 3: API service, scenario 5: CLI tool).

### Cross-Reference with Appendix C

The 50 hypothetical scenarios in Appendix C were analyzed for trait distribution:

| Trait | Scenarios That Use It | % of 50 |
|-------|----------------------|---------|
| `produces-code` | 1-12, 15, 33, 37-40, 49-50 | 40% |
| `produces-documents` | 13-19, 27-32, 34-36, 41-42, 44, 46-48 | 38% |
| `involves-data` | 2, 7-8, 20-22, 24-25, 32-33, 35-41, 45, 50 | 36% |
| `requires-decisions` | 12, 20-26, 31, 34, 40, 42-45, 48-50 | 36% |
| `cross-team` | 24-27, 29-30, 34, 41-45, 50 | 26% |
| `has-external-users` | 1, 4, 6, 9, 14-15, 18, 32-33, 39 | 20% |
| `needs-marketing` | 1, 9, 13-14, 16, 19, 22, 35 | 16% |
| `needs-design` | 1, 4, 9, 11 | 8% |
| `automation` | 3, 5, 7-8, 49 | 10% |
| `client-facing` | 42, 46-48 | 8% |
| `needs-sales` | 9, 19, 21, 23, 46 | 10% |

**Distribution is healthy:** No trait dominates (max 40%), no trait is vestigial (min 8%). The least-used traits (`client-facing`, `needs-design`, `needs-sales`, `automation`) at 8-10% are still activated by 4-5 distinct scenarios.

---

## Path A/B Independence

### Classification of Each Project

| Project | Path | Reasoning |
|---------|------|-----------|
| **Plugin Repo** | B (Technical Collaborator) | Engineering lead (Amanuel) is deeply technical. Architecture decisions (hook design, skill routing, context cascade) require collaborative discussion. |
| **Handbook** | A (Non-Technical) | Lead (Jaime Lyons) is content-focused. Technical decisions (GitBook sync, CI, GitHub workflow) should be made autonomously by the agent. |
| **Data Platform** | B (Technical Collaborator) | Lead (Corinne Brewer) is a data engineer. Warehouse architecture, dbt model design, pipeline orchestration are collaborative decisions. |
| **Recruiting** | A (Non-Technical) | Strategy and process design. If code is needed (Phase 2), the agent should make technical decisions autonomously. Holden as project owner bridges to technical execution. |
| **Website** | Either A or B | Depends on Kells Nixon's technical background. If they're a designer/marketer → Path A. If they're a developer → Path B. |

### What Path A/B Captures That Traits Don't

The binary split captures three things that are completely absent from the trait system:

1. **Autonomy level** — How much should the agent decide independently? Path A gives full technical authority. Path B requires collaborative decision-making on architecture and stack.

2. **Communication register** — Should the agent use technical language or plain language? Path A requires translation ("the database" → "where your information is stored"). Path B uses jargon freely.

3. **Decision authority boundaries** — Which decisions are autonomous, collaborative, or deferred? Path A has a simple rule: all technical decisions are autonomous. Path B has a nuanced three-tier model.

### Independence Assessment

**Path A/B is orthogonal to traits.** Evidence:

- `produces-code` projects can be Path A (Website for a non-technical stakeholder) or Path B (Data Platform with a technical lead). The trait determines WHAT infrastructure to set up; the path determines HOW to communicate about it.

- `produces-documents` projects can be Path A (Handbook — agent decides on CI, GitHub workflow) or Path B (Plugin repo — collaborative on markdown structure, hook design). Same output type, different collaboration model.

- `requires-decisions` means different things per path. Path A: agent makes and documents decisions autonomously (ADRs for future developers). Path B: decisions are discussed collaboratively (tradeoffs presented, alternatives evaluated together).

**Conclusion:** Autonomy level is a property of the **person-project relationship**, not the project itself. The same project could be Path A for one team member and Path B for another. It should remain a separate dimension — not a trait. The current approach (ask about technical background first, then classify traits) is correct.

**Recommendation for where autonomy lives:** Keep it as Step 1 of the interview (unchanged from current implementation). After trait classification, the autonomy level determines:
- CLAUDE.md template (Path A vs Path B sections — already implemented)
- Decision-making model (autonomous vs collaborative vs deferred)
- Communication register in all generated artifacts

This is independent of trait activation and should stay that way.

---

## Q7: Are 11 Traits the Right Number?

### Coverage Gaps

Three patterns emerged across the 5 projects that the current 11 traits don't cleanly capture:

**1. Internal vs external audience** — 4 of 5 projects are internal (Plugin, Handbook, Data, Recruiting). The trait system captures external (`has-external-users`, `client-facing`) but has no explicit trait for "internal tooling" or "infrastructure." This isn't necessarily a gap — the absence of external traits implies internal. But it means internal-focused projects get fewer trait activations and less tailored infrastructure. **Verdict: Not a gap.** Internal is the default; external traits are the additive signal. Adding an `internal-tooling` trait would fire on most projects and provide little differentiation.

**2. Research/evaluation phase** — Recruiting Phase 1 is pure research and strategy. The combination `produces-documents` + `requires-decisions` partially captures this, but the downstream infrastructure (docs/brief.md, docs/outline.md, ADR templates) isn't quite right for a competitive evaluation. A research project needs evaluation frameworks, scoring matrices, comparison templates — not brief/outline scaffolding. **Verdict: Minor gap.** Could be addressed by adding research-specific templates under `requires-decisions` rather than adding a new trait. The trait count is correct; the activation behavior needs refinement.

**3. Platform/infrastructure archetype** — The Data Platform has 5 traits. The Plugin Repo has 4-5. These are infrastructure projects that serve other projects. The trait system classifies them correctly but doesn't recognize the "platform" pattern — a project that other projects depend on. **Verdict: Not a trait.** "Platform" is an archetype (a common trait combination), not an independent classification dimension. It would always co-occur with other traits and add no unique downstream behavior.

### Unused Traits

| Trait | Activated? | Analysis |
|-------|-----------|----------|
| `needs-sales` | 0 of 5 projects | Brite's current Linear projects are mostly internal infrastructure and operations. Sales-facing projects (client proposals, pricing strategy, sales decks) are plausible future work — Brite Labs Website could evolve to include sales materials. **Keep.** |
| `client-facing` | 0 of 5 projects | Not activated in our sample. Brite is a service business — client-facing projects will become more common as the company matures (SOWs, client onboarding, project proposals). Appendix C shows 4 scenarios (42, 46-48). **Keep.** |

No trait is vestigial. All 11 are activated by at least 4 of the 50 Appendix C scenarios.

### Traits That Need Split/Merge

**No splits needed.** The `produces-code` classification for the Plugin Repo (scripts/hooks, not application code) works correctly — the trait activates needed infrastructure (GitHub repo, CI, pre-commit). Splitting into `produces-application-code` and `produces-scripts` would add complexity without meaningful downstream behavior differences.

**No merges needed.** The `has-external-users` / `client-facing` pair has semantic overlap but valid independent scenarios (see Orthogonality section). Merging them would lose the distinction between "product has public users" and "project has a client relationship."

### Answer to Q7

**11 is the right number.** No trait should be added, removed, split, or merged. The issues are in detection signals and activation behavior, not in the trait taxonomy itself. Specific fixes:

1. Fix `involves-data` signal: replace "BigQuery" with "Snowflake" (or better: make it data-warehouse-agnostic: "data warehouse", "Snowflake", "BigQuery", "Redshift")
2. Fix `client-facing` signals: remove "deadline" and "deliverable" (too generic). Keep "client" as the primary signal. Add "client deliverable", "client relationship", "external stakeholder."
3. Fix `automation` signal: change "CI/CD" to "CI/CD as primary purpose" or add exclusion: "CI/CD" only fires if the project's PURPOSE is automation, not if it merely uses CI.
4. Fix `involves-data` signal: "metrics" should require co-occurrence with data infrastructure terms ("warehouse", "pipeline", "ETL", "analytics platform"), not fire alone.

---

## Q8: Non-Obvious Trait Combinations?

### Observed Combinations Across 5 Projects

| Project | Trait Combination | Pattern Name | Notes |
|---------|------------------|--------------|-------|
| Plugin Repo | `produces-documents` + `requires-decisions` + `cross-team` + `automation` + `produces-code`(?) | **Meta-platform** | A project that builds tooling for other projects. The `produces-code` ambiguity is the only tension. |
| Handbook | `produces-documents` + `cross-team` | **Knowledge base** | Cleanest combination — just two traits. Automation reclassified to N (CI is maintenance tooling, not the project's purpose). |
| Data Platform | `produces-code` + `involves-data` + `requires-decisions` + `cross-team` + `automation` | **Data engineering** | 5-trait combination. Common archetype in the industry. Each trait activates independently without conflict. |
| Recruiting | `produces-documents` + `requires-decisions` + `cross-team` | **Strategic initiative** | Clean 3-trait combination. Data involvement reclassified to N — it's data-informed strategy, not data engineering. |
| Website | `produces-code` + `has-external-users` + `needs-design` + `needs-marketing` + `requires-decisions` | **Marketing site** | 5 traits. Maps to Appendix C scenario 1 (minus `client-facing`). Clean combination — the website attracts clients but the project has no client relationship. |

### Conflicting Downstream Behavior?

Tested each observed combination for conflicts in what infrastructure/docs/plugins would be activated:

| Combination | Conflict? | Analysis |
|------------|-----------|----------|
| `produces-code` + `produces-documents` (Plugin) | **No** | Code traits activate GitHub repo, CI, pre-commit. Document traits activate docs/ scaffold, brief.md, outline.md. Both apply — the plugin repo needs both. No conflict in what's generated. |
| `involves-data` + `requires-decisions` (Data, Recruiting) | **No** | Data trait activates MCP verification and data source config. Decision trait activates ADR templates. Independent, complementary. |
| `involves-data` + `produces-code` (Data) | **No** | Data infrastructure + code infrastructure. Both needed for a data engineering project. |
| `has-external-users` + `client-facing` (no project in sample) | **Minor overlap** (theoretical) | Both could activate deployment/monitoring config. `has-external-users` activates deployment config + monitoring + accessibility. `client-facing` activates communication cadence + deliverable milestones. Overlap is only in deployment config. **Mitigation: idempotent activation** (check if already set up before activating). Not observed in our 5 projects — Website is `has-external-users` without `client-facing`. |
| `cross-team` + `automation` (Plugin, Data) | **No** | Cross-team activates stakeholder map + org structure. Automation activates script structure + scheduler config. Independent concerns. |
| `needs-design` + `needs-marketing` (Website) | **No** | Design activates design plugin + design-context skill. Marketing activates marketing plugin + marketing-context skill. Different plugins, different docs. |

### Can Plugins Handle Combinations Independently?

**Yes.** Each trait maps to independent infrastructure, documentation, and plugin activations (see PRD lines 1101-1113). No trait's activation interferes with another's. The infrastructure is additive: more traits = more setup, but no setup conflicts.

The one exception is **idempotency** — if two traits both want to create deployment config (e.g., `has-external-users` and `client-facing`), the second activation should detect that the first already created it. This is an implementation detail, not a trait model issue.

### Non-Obvious Combinations from Appendix C

| Scenario | Combination | Why Non-Obvious |
|----------|-------------|-----------------|
| 15: Conference talk | `produces-documents` + `produces-code` (demo) + `has-external-users` | A talk is mostly docs, but the live demo is code. The code is throwaway/demo-quality, not production. Does it need full CI/pre-commit? |
| 33: A/B test design | `involves-data` + `produces-code` + `has-external-users` | Three distinct concerns: statistical design (data), implementation (code), and user impact (external users). Each trait adds value independently. |
| 42: Hiring plan | `produces-documents` + `cross-team` + `client-facing` + `requires-decisions` | "Client-facing" is questionable here — is a hiring plan client-facing? Only if hiring for a client project. This is a signal accuracy issue, not a trait combination issue. |
| 49: Plugin development | `produces-code` + `produces-documents` + `requires-decisions` + `automation` | This IS our plugin repo. The 4-trait combination is validated by real experience. |

### Answer to Q8

**No trait-interaction rules are needed.** Plugins can handle all observed combinations independently. The additive model (more traits = more infrastructure, each independent) works correctly.

Two implementation recommendations:

1. **Idempotent activation:** Infrastructure setup (deployment config, monitoring, GitHub repo) should check-before-create, so overlapping trait activations don't duplicate work.

2. **Archetype recognition (optional, not blocking):** Common combinations like "data engineering" (code + data + automation + decisions + cross-team) and "marketing site" (code + design + marketing + external-users) could be recognized as named archetypes. This isn't required — independent trait activation works — but archetype recognition could provide:
   - Better interview prompts ("This sounds like a data engineering project — let me ask about your data sources...")
   - Coherent template sets instead of 5 independent scaffolds
   - Richer initial CLAUDE.md content based on the archetype pattern

---

## Recommendations

### Signal Fixes (Priority 1 — required before BC-2127)

| # | Fix | Trait | Current Signal | Proposed Signal | Rationale |
|---|-----|-------|---------------|-----------------|-----------|
| 1 | Replace stale reference | `involves-data` | "BigQuery" | "data warehouse", "Snowflake", "BigQuery", "Redshift", "Databricks" | Brite uses Snowflake. Signal should be warehouse-agnostic. |
| 2 | Remove overly generic signals | `client-facing` | "deadline", "deliverable", "stakeholder" | "client", "client deliverable", "external stakeholder", "SOW", "client relationship" | "Deadline" fires on all projects. "Stakeholder" fires on all cross-team projects. Only "client" is specific to actual client relationships. |
| 3 | Add purpose qualifier | `automation` | "CI/CD" | "CI/CD" only when it's the project's primary purpose, OR add exclusion: don't fire when `produces-code` or `produces-documents` is the primary trait and CI/CD is supporting infrastructure | "CI/CD" fires on any project with continuous integration. Most code projects have CI but aren't "automation projects." |
| 4 | Add co-occurrence requirement | `involves-data` | "metrics" (fires alone) | "metrics" + data infrastructure terms ("warehouse", "pipeline", "ETL", "dbt", "analytics") | "Metrics" alone fires on recruiting (KPIs), handbook (metric definitions), and other non-data projects. Require co-occurrence with infrastructure terms. |

### Description Clarifications (Priority 2 — include in BC-2127)

| # | Trait | Current Description Gap | Proposed Addition |
|---|-------|------------------------|-------------------|
| 5 | `client-facing` | Confused with "has deadlines" or "has stakeholders" | Add to trait description: "Specifically for projects with an EXTERNAL client relationship — deliverables, timelines, and communication cadence with someone outside the organization. Internal stakeholders and internal deadlines do NOT make a project client-facing." |
| 6 | `automation` | Confused with "uses CI/CD" | Add to trait description: "Projects whose PRIMARY purpose is automation — data pipelines, scheduled jobs, bots, integration scripts. Projects that USE CI/CD as supporting infrastructure are NOT automation projects unless CI/CD design is a core deliverable." |

### Architecture Recommendations (Priority 3 — inform BC-2128 implementation)

| # | Recommendation | Evidence |
|---|---------------|----------|
| 7 | **Implement signal exclusion rules** — Some signals should be suppressed in certain contexts. "CI/CD" should not fire `automation` if the project is already classified as `produces-code`. "Metrics" should not fire `involves-data` if there are no data infrastructure signals. | 7 false positives traced to signals that fire in wrong context (see False Positives table). |
| 8 | **Classify with confidence scores** — Each trait classification should include a confidence level (High/Med/Low). Low-confidence classifications should be flagged to the user during confirmation: "I'm not sure about `involves-data` — you mention metrics but don't seem to need data infrastructure. Include it?" | 4 boundary cases identified across 5 projects (Plugin `produces-code`, Handbook `automation`, Recruiting `involves-data`, Website `client-facing`). |
| 9 | **Keep Path A/B separate from traits** — Autonomy level is orthogonal to project classification. It should remain Step 1 of the interview. Do not attempt to encode it as a trait. | Full independence assessment confirms: same project type can be A or B depending on who's leading. |
| 10 | **Consider archetype recognition** (optional) — Common trait combinations like "data engineering" and "marketing site" could be recognized as named archetypes to improve interview prompts and template coherence. Not blocking — independent trait activation works without it. | Data Platform (5 traits) and Website (4 traits) both map to recognizable industry archetypes with well-known infrastructure patterns. |

---

## Appendix: Raw Data Sources

| Source | What Was Gathered |
|--------|-------------------|
| This repo's CLAUDE.md + structure | Plugin repo classification — full project context |
| Linear: Brite Handbook project (11 milestones) | Handbook classification — purpose, scope, team structure |
| Linear: Brite Enterprise Data Platform (9 milestones) | Data platform classification — stack, data sources, architecture |
| Linear: Brite Recruiting (5 milestones) | Recruiting classification — mission, phases, constraints, decision model |
| Linear: Brite Labs Website (minimal data) | Website classification — initiative context, lead, status |
| Context7: /brite-nites/handbook — data platform query | Handbook content on Snowflake, dbt, data engineering team |
| Context7: /brite-nites/handbook — website query | Handbook content on Brite entities and organizational structure |
| Auto-memory: project_data_architecture.md | Snowflake (not BigQuery), Salesforce migration, three-layer model |
| PRD: brite-agent-platform.md lines 1074-1137 | Canonical trait definitions and activation matrix |
| PRD: Appendix C (lines 1970-2041) | 50 hypothetical scenarios for cross-reference |
| PRD: Q7-Q8 (lines 1828-1830) | Open questions being answered |
| Design doc: project-start-redesign.md | Implementation context for trait system |
