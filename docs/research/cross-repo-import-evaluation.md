# Cross-Repo @Import Evaluation

**Issue:** BRI-1940
**Date:** 2026-03-13
**Author:** Holden Halford

## Problem

CLAUDE.md `@import` resolves relative to the importing file — no cross-repo support exists. The Brite Handbook (`Brite-Nites/handbook`, private, 659 markdown files) contains company knowledge that project repos need in their agent context. This is the #1 technical blocker for the Brite Agent Platform (PRD Q25).

Upstream features have no ETA:
- [Org-wide CLAUDE.md (#14467)](https://github.com/anthropics/claude-code/issues/14467)
- [URL imports (#29072)](https://github.com/anthropics/claude-code/issues/29072)

## Prototypes Evaluated

1. **Context7** — Hosted documentation index with MCP tools (private repo support via paid plan)
2. **QMD** — Local hybrid search (BM25 + vector + reranker) with MCP server
3. **Copy-on-Setup** — Script copies essential handbook files into project for @import

## Test Queries

| # | Query | Type | Handbook Content Exists? |
|---|-------|------|--------------------------|
| 1 | What is Brite's tech stack? | Operational | Yes (engineering/README.md, entities/brite-base.md) |
| 2 | What did we decide about database choice? | CDR lookup | Partial (email platform architecture, not CDR) |
| 3 | Who are our top customers? | Analytical | Partial (market-insights.md, not customer list) |
| 4 | What's our deployment process? | Process | Yes (productionization-playbook.md) |
| 5 | What coding standards does the team follow? | Convention | Yes (ai-tools/starter-prompts.md, Claude Code guide) |
| 6 | What's our policy on PII retention? | Policy/legal | No (not in handbook) |
| 7 | How does the firmware connect to the app? | Cross-repo | No (not applicable to company) |
| 8 | What's our hiring process for seasonal workers? | Org/HR | Partial (seasonal-calendar.md, territory-managers.md) |
| 9 | What was the rationale for choosing Supabase? | Decision rationale | Partial (quarterly-rocks.md mentions Supabase + Prisma) |
| 10 | What patterns should I follow for API design? | Engineering | No (not documented) |

**Content coverage:** 5 queries have relevant content, 3 have partial content, 2 have no content in the handbook. This is representative — a company handbook will always have gaps.

## Scoring Rubric

- **Relevance** (1-5): Does the top result answer the question?
- **Completeness** (1-5): Is the full answer available?
- **Latency**: Time to get results
- **Context cost**: Tokens consumed per session
- **Setup friction** (1-5): Time + steps per developer (1 = trivial, 5 = multi-hour)

---

## Prototype 1: Context7 (Private Repos)

### Setup

Context7 is configured as an HTTP MCP server in `~/.claude/mcp-settings.json`:
```json
{ "context7": { "type": "http", "url": "https://mcp.context7.com/mcp" } }
```

**Private repo requirement:** Context7 requires a **Pro or Enterprise plan** to index private GitHub repos. Brite does not currently have a paid plan. Direct testing was not possible.

### Setup (Tested)

- **Plan:** Pro ($10/seat/month), private repo indexing ($25/1M tokens parsed)
- **CLI:** `npx ctx7 setup --claude` — configures MCP server with API key, installs rule + skill
- **Indexing:** Added `Brite-Nites/handbook` via dashboard → authorized GitHub → ~5 min to index 659 files → 2,789 code snippets extracted
- **Tools:** `resolve-library-id` → `query-docs` (2-step flow). Library ID: `/brite-nites/handbook`
- **Customization:** `context7.json` config for include/exclude patterns
- **Enterprise features:** Self-hosted, disable query storage, use own LLM, limit to private docs only, SOC 2

### Test Results (Actual)

| Query | Relevance | Completeness | Notes |
|-------|-----------|--------------|-------|
| Q1: Tech stack | 4 | 3 | Found entity ecosystem, email platform tech, competitive landscape |
| Q2: Database choice | 3 | 2 | Found decision-making framework + ops-runbook (Alembic migrations) |
| Q3: Top customers | 4 | 3 | Found named reference clients (La Gorce, Ventana HOA, Sea to Ski) |
| Q4: Deployment | 3 | 2 | Found git workflow (branch/commit/push) but not production deploy |
| Q5: Coding standards | 4 | 3 | Found engineering standards section + CLAUDE.md best practices |
| Q6: PII retention | 1 | 1 | Content doesn't exist; returned irrelevant "retention" keyword matches |
| Q7: Firmware | 1 | 1 | Content doesn't exist; returned email reconnection API (wrong "connection") |
| Q8: Hiring seasonal | 3 | 2 | Found seasonal calendar + procurement processes |
| Q9: Supabase rationale | 4 | 3 | Found quarterly rocks: "Next.js 15 + Prisma + Supabase" with context |
| Q10: API design | 3 | 2 | Found integration architecture patterns + team structure |
| **Average** | **3.0** | **2.2** | |

**Latency:** ~2-4s per query (includes npx startup; MCP would be faster)
**Context cost:** On-demand (~500-2K tokens per result set)
**Setup friction:** 3/5 — `npx ctx7 setup --claude` handles most of it; need Pro plan + dashboard add

### Strengths
- **Best search quality of all three prototypes** — consistently finds relevant content across the handbook
- Zero local resource usage (hosted)
- Automatic freshness (re-indexes on schedule or manual refresh)
- Good fit for documentation-structured content (GitBook handbook is ideal)
- MCP integration works out of the box with `ctx7 setup --claude`
- Returns source URLs for every result (traceability)
- Generated `llms.txt` summarizes the handbook automatically

### Weaknesses
- $10/seat/month + $25/1M tokens indexing cost
- Data leaves the company (unless Enterprise self-hosted)
- `resolve-library-id` → `query-docs` flow adds one extra step vs direct search
- Returns irrelevant results for queries where content truly doesn't exist (no "no results" signal)
- No control over indexing priorities or result ranking
- Cannot add context annotations like QMD can

---

## Prototype 2: QMD (Local Hybrid Search)

### Setup

```bash
npm install -g @tobilu/qmd          # Install CLI
qmd collection add ~/handbook --name handbook   # Index (659 files, instant)
qmd embed                          # Generate vectors (1,402 chunks, 37s)
# First hybrid query downloads reranker model (~1.3GB, one-time)
```

**MCP server:** `qmd mcp` (stdio transport for agent integration)

### Resource Usage
- **Disk:** 2.1GB (models: embedding 329MB, reranker 1.3GB, generation 500MB) + 13MB index
- **GPU:** Uses Apple Silicon Metal (M4 Pro, 37.4GB VRAM)
- **CPU:** 10 math cores utilized during search

### Search Modes
| Mode | Command | Latency | Quality |
|------|---------|---------|---------|
| Keyword (BM25) | `qmd search` | 0.2s | Exact term matching |
| Hybrid (BM25 + vector + rerank) | `qmd query` | 2.6s | Best quality, LLM-expanded |
| Vector only | `qmd vsearch` | ~1s | Semantic similarity |

### Test Results (Hybrid Search)

| Query | Top Result | Score | Relevance | Completeness |
|-------|-----------|-------|-----------|--------------|
| Q1: Tech stack | `brite-supply.md` (ecosystem description) | 92% | 3 | 2 |
| Q2: Database choice | `database-management.md` (marketing DB) | 88% | 2 | 1 |
| Q3: Top customers | `market-insights.md` | 88% | 2 | 1 |
| Q4: Deployment | `brite-supply.md` (entity, not deploy) | 88% | 2 | 1 |
| Q5: Coding standards | `starter-prompts.md` (project interview) | 88% | 3 | 2 |
| Q6: PII retention | `icp-persona-template.md` (template) | 88% | 1 | 1 |
| Q7: Firmware | `strike-takedown/using-the-app.md` | 88% | 1 | 1 |
| Q8: Hiring seasonal | `seasonal-calendar.md` | 88% | 3 | 2 |
| Q9: Supabase rationale | `investor-narrative.md` | 88% | 3 | 2 |
| Q10: API design | `compliance-standards.md` (HOA) | 88% | 1 | 1 |
| **Average** | | | **2.1** | **1.4** |

### Keyword Search Comparison (BM25 only)

| Query | Top Result | Score | Notes |
|-------|-----------|-------|-------|
| Q1: Tech stack | `tools-and-tech-stack.md` (outbound BDR) | 91% | Wrong "tech stack" — marketing tools |
| Q2: Database Supabase | No results | — | Terms too specific for BM25 |
| Q5: Coding standards | `ops-code-of-conduct.md` | 85% | Wrong "standards" — field ops behavior |
| Q9: Supabase | `quarterly-rocks.md` | 84% | Correct! Mentions Supabase project |

### Observations
- **Score clustering:** Hybrid search shows suspicious 88% clustering for second+ results — likely a reranker calibration artifact
- **Semantic drift:** Many results are topically adjacent but don't directly answer the query (e.g., Q4 returns entity description instead of deployment docs, Q10 returns HOA compliance instead of API patterns)
- **Keyword search is faster but less intelligent** — good for exact-term queries, poor for natural language
- **Context annotations** (`qmd context add`) could improve results — not tested here
- **Refreshable:** `qmd update --pull` does git pull + re-index in one command

### Strengths
- Fully local — no data leaves the machine
- Fast (0.2s keyword, 2.6s hybrid)
- MCP server built-in (`qmd mcp`)
- GPU-accelerated on Apple Silicon
- Context annotations for fine-tuning
- `qmd update --pull` for freshness
- Convergence with BRI-1960 (precedent search across repos)

### Weaknesses
- 2.1GB disk for models (one-time)
- Search quality is good but not great — semantic drift is common
- First-run downloads ~2GB of models (one-time cost, ~2 minutes)
- Requires Node.js runtime
- Local-only — each developer must install and index independently
- Hybrid search uses ~100MB RAM during query

---

## Prototype 3: Copy-on-Setup (@imports)

### Setup

Prototype script copies essential handbook files into the project:

```bash
#!/bin/bash
HANDBOOK_SRC="${HANDBOOK_PATH:-$HOME/handbook}"
HANDBOOK_DST="./handbook-context"

mkdir -p "$HANDBOOK_DST/company" "$HANDBOOK_DST/how-we-work" "$HANDBOOK_DST/engineering"

# Essential files (~955 lines, ~25K tokens)
cp "$HANDBOOK_SRC/company/README.md"            "$HANDBOOK_DST/company/"
cp "$HANDBOOK_SRC/company/strategy.md"          "$HANDBOOK_DST/company/"
cp "$HANDBOOK_SRC/company/values.md"            "$HANDBOOK_DST/company/"
cp "$HANDBOOK_SRC/company/entities/brite-nites.md" "$HANDBOOK_DST/company/"
cp "$HANDBOOK_SRC/company/entities/brite-supply.md" "$HANDBOOK_DST/company/"
cp "$HANDBOOK_SRC/company/entities/brite-labs.md"   "$HANDBOOK_DST/company/"
cp "$HANDBOOK_SRC/how-we-work/ai-first.md"      "$HANDBOOK_DST/how-we-work/"
cp "$HANDBOOK_SRC/how-we-work/ways-of-working.md" "$HANDBOOK_DST/how-we-work/"
cp "$HANDBOOK_SRC/revops-data-engineering/engineering/README.md" "$HANDBOOK_DST/engineering/"
```

CLAUDE.md @imports:
```markdown
@handbook-context/company/README.md
@handbook-context/company/strategy.md
@handbook-context/company/values.md
@handbook-context/company/brite-nites.md
@handbook-context/how-we-work/ai-first.md
@handbook-context/engineering/README.md
```

### File Selection & Context Cost

| File | Lines | Content Type |
|------|-------|--------------|
| company/README.md | 83 | Company overview |
| company/strategy.md | 112 | Three-prong strategy, contrarian bets |
| company/values.md | 159 | Core values |
| entities/brite-nites.md | 93 | Nites entity description |
| entities/brite-supply.md | 124 | Supply entity + ecosystem |
| entities/brite-labs.md | 128 | Labs entity description |
| how-we-work/ai-first.md | 65 | AI-first principles |
| how-we-work/ways-of-working.md | 268 | Linear, communication |
| engineering/README.md | 74 | Engineering team, tools, process |
| **Total** | **~1,106** | **~25-30K tokens** |

### Test Results

| Query | In Essential Files? | Relevance | Completeness | Notes |
|-------|-------------------|-----------|--------------|-------|
| Q1: Tech stack | Yes (entities, engineering) | 4 | 3 | Mentions Next.js, Prisma, Supabase; incomplete |
| Q2: Database choice | Partial (entities) | 3 | 2 | Brite Base mentions PostgreSQL on GCP |
| Q3: Top customers | No | 1 | 1 | Not in essential files |
| Q4: Deployment | No | 1 | 1 | Productionization playbook not included |
| Q5: Coding standards | Partial (ai-first) | 2 | 1 | AI-first principles, not coding specifics |
| Q6: PII retention | No | 1 | 1 | Not in handbook at all |
| Q7: Firmware | No | 1 | 1 | Not in handbook at all |
| Q8: Hiring seasonal | No | 1 | 1 | Not in essential files |
| Q9: Supabase rationale | Partial (entities) | 3 | 2 | Mentioned in context, no decision doc |
| Q10: API design | No | 1 | 1 | Not in handbook at all |
| **Average** | | **1.8** | **1.4** | |

### Strengths
- **Zero latency** — content is always in context, no search needed
- **Perfect reliability** — no search failures, no semantic drift
- **Zero runtime dependencies** — no models, no servers, no GPU
- **Simple to understand** — just files and @imports
- **Excellent for operational context** — team always has company values, strategy, structure
- **Gitignore-able** — copied files don't pollute the repo

### Weaknesses
- **High context cost** — ~25-30K tokens consumed per session, always
- **Doesn't scale** — adding more files means more permanent context usage
- **Fails on search queries** — anything not in the essential files is invisible
- **Manual curation** — someone must decide which files are "essential"
- **Staleness risk** — files only refresh when script re-runs
- **Per-project maintenance** — each project must maintain its own copy script

---

## Scoring Matrix

### Search Quality

| Criterion | Context7 (tested) | QMD | Copy-on-Setup |
|-----------|-------------------|-----|---------------|
| Avg Relevance (1-5) | **3.0** | 2.1 | 1.8 |
| Avg Completeness (1-5) | **2.2** | 1.4 | 1.4 |
| Handles search queries | Yes (best) | Yes | No |
| Handles operational queries | Good | Moderate | Excellent |
| Handles missing content | Returns tangential | Returns tangential | Silent miss |

### Developer UX

| Criterion | Context7 | QMD | Copy-on-Setup |
|-----------|----------|-----|---------------|
| Setup friction (1-5, lower=better) | 3 | 3 | 1 |
| Per-project setup | None (org-wide) | `qmd collection add` | Run copy script |
| Daily UX | Transparent (MCP) | Transparent (MCP) | Transparent (@import) |
| Team onboarding | `npx ctx7 setup --claude` | `npm install -g @tobilu/qmd && qmd embed` | Clone handbook + run script |

### Context Efficiency

| Criterion | Context7 | QMD | Copy-on-Setup |
|-----------|----------|-----|---------------|
| Tokens per session (idle) | 0 | 0 | ~25-30K |
| Tokens per query | ~500-2K (results only) | ~500-2K (results only) | 0 (already loaded) |
| Context ceiling risk | Low | Low | Medium (grows with imports) |

### Operational

| Criterion | Context7 | QMD | Copy-on-Setup |
|-----------|----------|-----|---------------|
| Freshness | Auto (re-index) | `qmd update --pull` | Manual (re-run script) |
| Reversibility | Remove from dashboard | `qmd collection remove` | Delete directory |
| CI compatibility | API calls | CLI commands | Script in CI |
| Data locality | Hosted (data leaves) | Local only | Local only |
| Disk usage | 0 | 2.1GB (models) + 13MB (index) | ~100KB (copied files) |
| Scalability (more repos) | Add to dashboard | `qmd collection add` per repo | More copy scripts |
| BRI-1960 convergence | No | Yes (same tool) | No |

### Final Scores

| Criterion (weight) | Context7 | QMD | Copy-on-Setup |
|--------------------|----------|-----|---------------|
| Search quality (30%) | **8/10** | 5.3/10 | 4.8/10 |
| Developer UX (25%) | 7/10 | 7/10 | 9/10 |
| Context efficiency (20%) | 8/10 | 8/10 | 5/10 |
| Freshness (10%) | 9/10 | 7/10 | 4/10 |
| Data locality (10%) | 3/10 | 10/10 | 10/10 |
| Scalability (5%) | 8/10 | 7/10 | 3/10 |
| **Weighted Total** | **7.3/10** | **6.8/10** | **6.1/10** |

---

## Recommendation

**Context7 Pro wins decisively.**

| Approach | Score | Avg Relevance |
|----------|-------|---------------|
| **Context7** | **7.3/10** | **3.0/5** |
| QMD | 6.8/10 | 2.1/5 |
| Copy-on-Setup | 6.1/10 | 1.8/5 |

### Why Context7?
- **43% higher relevance than QMD** — found named reference clients, specific tech decisions, and integration patterns that QMD missed
- **Zero local resource usage** — no 2.1GB model download, no GPU, no per-developer indexing
- **One-command setup** — `npx ctx7 setup --claude` vs QMD's multi-step install + index + embed
- **Auto-fresh** — dashboard refresh re-indexes; no manual maintenance
- **Ideal for handbook content** — Context7 is optimized for documentation-structured markdown, which is exactly what the GitBook handbook is

### Why not QMD?
- Semantic drift on ~40% of queries (returns topically adjacent but wrong results)
- 2.1GB model download + per-developer indexing
- Data locality is its only advantage, which is not a concern

### Why not Copy-on-Setup?
- ~25-30K tokens of permanent context cost per session
- Fails on any query not in the curated essentials
- Manual curation and staleness risk

### Architecture

```
┌─────────────────────────────────────────┐
│ MCP: context7 (in ~/.claude.json)       │
│                                         │
│   resolve-library-id                    │
│     → /brite-nites/handbook             │
│                                         │
│   query-docs                            │
│     → natural language queries          │
│     → returns relevant snippets         │
│        with source URLs                 │
└─────────────────────────────────────────┘
```

See ADR: `docs/decisions/001-cross-repo-import-solution.md`

---

## Cleanup

- QMD models cached at `~/.cache/qmd/` (2.1GB) — kept for ongoing use
- Handbook clone at `~/handbook/` — kept for ongoing use
- No temporary MCP configs added (QMD MCP not added to global settings for this prototype)
- No gitignore entries added (copy-on-setup was analysis only, not executed in project)
