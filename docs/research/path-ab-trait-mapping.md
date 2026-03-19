# Path A/B Template to Trait Mapping

**Issue:** BC-2125
**Date:** 2026-03-18
**Author:** Holden Halford
**Depends on:** BC-2124 (trait model validation), BC-2126/BC-2128 (trait classification + confirmation)
**Feeds into:** BC-2130 (unified trait-conditional template)

## Summary

The current `project-start.md` generates CLAUDE.md from two parallel templates: Path A (non-technical user) and Path B (technical collaborator). This document maps every section of both templates to the trait system, identifies overlaps and gaps, and proposes a unified template skeleton that replaces the two-path fork with a single trait-conditional template where autonomy level is a content modifier rather than a structural branch.

**Key finding:** The current templates only address `produces-code` infrastructure. 10 of 11 traits have no corresponding CLAUDE.md section. The templates are essentially "generic code project" templates with an autonomy dial.

---

## 1. Section-to-Trait Mapping Table

All 18 sections across both paths, categorized by when they should appear.

### Categories

- **Always-include**: Present regardless of traits. Content may vary by autonomy level.
- **Autonomy-conditional**: Only appears for one autonomy level (A or B). Not trait-dependent.
- **Trait-conditional**: Should only appear when specific traits are active.

### Full Mapping

| # | Path A Section | Path B Section | Category | Controlling Trait(s) | Notes |
|---|----------------|----------------|----------|---------------------|-------|
| 1 | User Profile | Collaborator Profile | Always (autonomy-varied) | -- | Same purpose, different framing. A: goals in plain language, constraints. B: technical background, preferred technologies, role in project. |
| 2 | Project Traits | Project Traits | Always (identical) | -- | Identical structure in both paths. Lists `active:` traits, `path:`, and trait evidence. |
| 3 | Communication Rules | Communication Style | Always (autonomy-varied) | -- | A: never use jargon, translate technical terms. B: use technical language freely, share reasoning. |
| 4 | Decision-Making Authority | Decision-Making Model | Always (autonomy-varied) | -- | A: full technical authority, choose boring tech, document as ADRs. B: three-tier model (collaborative / autonomous / deferred). |
| 5 | When to Involve Them | -- | Autonomy-conditional (A only) | -- | When to surface decisions to non-technical users. Includes examples of ask/don't-ask. |
| 6 | -- | How to Disagree | Autonomy-conditional (B only) | -- | Protocol for technical disagreements with collaborator. |
| 7 | Engineering Standards | Engineering Standards | Trait-conditional (autonomy-varied) | `produces-code` | A: apply automatically, comprehensive testing, security, maintainability. B: baseline standards, adjust based on collaborator preferences. |
| 8 | Quality Assurance | -- | Trait-conditional (A only) | `produces-code` | Never show broken things, test before demoing, automated checks. Only makes sense for A because B collaborators can handle broken states. |
| 9 | -- | Technical Vision | Trait-conditional (B only) | `produces-code` (+ autonomy B) | Agreed tech stack, architectural decisions, open questions, constraints. Only B because A users don't engage with tech stack discussions. |
| 10 | Showing Progress | Showing Progress | Always (autonomy-varied) | -- | A: working demos, screenshots, experience-terms. B: PRs, technical context, blockers, transparency. |
| 11 | Project-Specific Details | Project-Specific Details | Always (identical purpose) | -- | Catch-all for interview context. Same structure, different content emphasis. |

### Section Count Summary

| Category | Count | Sections |
|----------|-------|----------|
| Always-include (autonomy-varied) | 5 | Profile, Traits, Communication, Decision-Making, Progress |
| Always-include (identical) | 1 | Project-Specific Details |
| Autonomy-conditional | 2 | When to Involve Them (A), How to Disagree (B) |
| Trait-conditional | 3 | Engineering Standards, Quality Assurance (A), Technical Vision (B) |

---

## 2. Overlap Analysis

### Identical Sections (merge directly)

These appear in both paths with the same structure and purpose. Can be collapsed into a single section.

| Section | Path A | Path B | Merge Strategy |
|---------|--------|--------|----------------|
| Project Traits | Lines 187-206 | Lines 272-291 | Single section. Content is template-generated from trait classification. No autonomy variation needed. |
| Project-Specific Details | Line 259-260 | Line 347-348 | Single section. Insert point for interview context. The content naturally varies by what was discussed, not by autonomy level. |

### Parallel Sections (merge with autonomy-conditional language)

These serve the same purpose but use different language/framing based on autonomy level. They become single sections with conditional phrasing.

| Section | Path A Framing | Path B Framing | Merge Strategy |
|---------|---------------|---------------|----------------|
| **Profile** | "Non-technical user", plain-language goals, constraints | "Technical background", preferred technologies, project role | Single section. Autonomy level determines which prompts are used to populate it. The generated content naturally reflects the person. |
| **Communication** | Never use jargon, translate everything, "smart friend who doesn't work in tech" | Use technical language freely, share reasoning, reference code/PRs directly | Single section with autonomy-conditional register. A: `<!-- autonomy:A -->` block with jargon prohibition. B: `<!-- autonomy:B -->` block with technical language permission. |
| **Decision-Making** | Full technical authority, boring tech, ADRs for future devs | Three-tier model: collaborative, autonomous, deferred | Single section with autonomy-conditional boundaries. The *structure* (what decisions exist) is shared; the *authority model* (who decides) varies. |
| **Engineering Standards** | Apply automatically, comprehensive testing, security | Baseline standards, adjust per collaborator preferences | Single section gated on `produces-code`. Autonomy level modifies the tone: A = "apply without discussion", B = "discuss strategy with them". |
| **Showing Progress** | Working demos, screenshots, experience-terms, celebrate milestones | PRs, technical context, blockers, transparency | Single section. Autonomy level determines the default format: A = visual demos, B = PRs + written updates. |

### Asymmetric Sections (keep as autonomy-conditional blocks)

These exist in only one path and have no counterpart. They become conditional blocks within the unified template.

| Section | Path | Purpose | In Unified Template |
|---------|------|---------|-------------------|
| When to Involve Them | A only | Defines the boundary between autonomous and user-facing decisions | Appears as a conditional block when autonomy = A. Content: what to ask about (UX tradeoffs) vs. what to decide silently (all technical). |
| How to Disagree | B only | Protocol for technical disagreements | Appears as a conditional block when autonomy = B. Content: state recommendation, acknowledge their view, defer if they feel strongly. |
| Quality Assurance | A only | Never show broken things, test before demoing | Merges into Engineering Standards as an A-conditional sub-section. The principle ("test before showing") applies regardless, but the strictness ("NEVER show anything broken") is A-specific. |
| Technical Vision | B only | Agreed tech stack, open questions, constraints | Becomes a conditional block when autonomy = B AND `produces-code` is active. For A, the agent documents tech decisions in ADRs silently. For B, they're surfaced in CLAUDE.md for collaborative reference. |

---

## 3. Gap Analysis

Maps each of the 11 traits to what the PRD says project-start should generate (from the activation matrix at PRD lines 1101-1113), then compares against what the current templates actually provide.

### Trait Coverage Matrix

<!-- Canonical trait definitions: plugins/workflows/commands/project-start.md § Trait Definitions. This table quotes the PRD at time of analysis. -->
| Trait | PRD: Documentation to Generate | PRD: Infrastructure | Current Template Section | Gap? |
|-------|-------------------------------|--------------------|--------------------------|----- |
| `produces-code` | `docs/engineering-context.md` | GitHub repo, CI, pre-commit, .vscode | Engineering Standards (Sec 7A / 7B) | **Partial** -- section exists but is generic. Missing: CI/deployment specifics, tech stack documentation, pre-commit configuration, .vscode setup details. The template says "write clean code" but doesn't scaffold `engineering-context.md`. |
| `produces-documents` | `docs/brief.md`, `docs/outline.md` scaffold | -- | -- | **GAP** -- No document structure section. No mention of brief, outline, or document workflow. A `produces-documents` project needs: document purpose/audience, outline structure, review/approval workflow, output format (markdown, PDF, slides). |
| `involves-data` | Data source noted in CLAUDE.md | BigQuery MCP verified | -- | **GAP** -- No data context section. Should include: data sources and access methods, key tables/models, data freshness expectations, query patterns, warehouse-specific conventions (Snowflake, not BigQuery per BC-2124). |
| `requires-decisions` | CDR INDEX @imported, `docs/decisions/` | -- | Decision-Making (Sec 4A / 5B) | **Partial** -- Decision-making authority exists but covers WHO decides, not HOW to document decisions. Missing: ADR methodology, CDR INDEX reference, evaluation framework templates, decision criteria. |
| `has-external-users` | Accessibility requirements | Deployment config, monitoring | -- | **GAP** -- No user-facing requirements section. Should include: accessibility standards (WCAG level), performance budgets (LCP, CLS), browser/device support matrix, error handling for end-users, monitoring/alerting thresholds. |
| `client-facing` | Communication cadence in CLAUDE.md | -- | -- | **GAP** -- No client management section. Should include: client communication cadence (weekly updates, milestone demos), deliverable format expectations, escalation path, status update templates, SOW/timeline references. |
| `needs-design` | `docs/design-context.md` | Design plugin | -- | **GAP** -- No design approach section. Should include: brand guidelines reference, color palette/tokens, typography choices, component library, design review process, Figma/design tool links. |
| `needs-marketing` | `docs/marketing-context.md` | Marketing plugin | -- | **GAP** -- No marketing approach section. Should include: target audience/ICP, positioning statement, key messages, channel strategy, launch timeline, competitive context. |
| `needs-sales` | `docs/sales-context.md` | Sales plugin | -- | **GAP** -- No sales approach section. Should include: ICP definition, competitive landscape, pricing strategy, objection handling, demo script structure, proposal templates. |
| `cross-team` | `docs/stakeholders.md` @imported | -- | -- | **GAP** -- No stakeholder coordination section. Should include: stakeholder map (who cares about what), RACI matrix, communication channels per stakeholder, decision escalation path, cross-team dependency tracking. |
| `automation` | Script/scheduler patterns in CLAUDE.md | -- | -- | **GAP** -- No automation patterns section. Should include: scheduler configuration (cron syntax, trigger conditions), retry/failure handling strategy, logging/monitoring for automated processes, integration points and API contracts. |

### Gap Summary

| Status | Count | Traits |
|--------|-------|--------|
| **Covered** (has template section) | 0 | -- |
| **Partially covered** | 2 | `produces-code`, `requires-decisions` |
| **Not covered at all** | 9 | `produces-documents`, `involves-data`, `has-external-users`, `client-facing`, `needs-design`, `needs-marketing`, `needs-sales`, `cross-team`, `automation` |

**Conclusion:** The current templates are "generic code project + autonomy level" templates. They assume every project produces code and differ only in how much the user participates in technical decisions. The trait system's power -- generating project-type-specific context -- is entirely unrealized in the current CLAUDE.md templates.

---

## 4. Collaboration Level as a Separate Axis

### What Path A/B Actually Captures

The binary Path A/B selection captures three properties of the **person-project relationship** (not the project itself):

| Property | Path A (Non-Technical) | Path B (Technical Collaborator) |
|----------|----------------------|-------------------------------|
| **Autonomy level** | Full technical authority -- agent decides everything technical | Shared authority -- architecture and stack are collaborative |
| **Communication register** | Plain language, translate jargon | Technical language, reference code directly |
| **Decision boundaries** | Simple rule: all technical = autonomous | Three-tier: collaborative / autonomous / deferred |

### Why It's Orthogonal to Traits

Evidence from BC-2124 (trait model validation across 5 real Brite projects):

- **Same trait, different paths:** `produces-code` projects can be Path A (Website with non-technical stakeholder) or Path B (Data Platform with technical lead). The trait determines WHAT infrastructure to set up; the path determines HOW to communicate about it.
- **Same output type, different paths:** `produces-documents` projects can be Path A (Handbook -- agent decides CI/GitHub workflow) or Path B (Plugin repo -- collaborative on markdown structure, hook design).
- **Trait meaning changes per path:** `requires-decisions` in Path A means the agent makes and documents decisions autonomously (ADRs for future developers). In Path B, decisions are discussed collaboratively (tradeoffs presented, alternatives evaluated together).

### How the Unified Template Handles Autonomy

Autonomy level becomes a **content modifier** on always-include sections, not a structural fork:

```
autonomy_level = A | B    # Set during interview Step 1

# Modifies these sections:
Profile           -> A: plain-language goals  | B: technical background
Communication     -> A: no jargon            | B: technical freely
Decision-Making   -> A: full authority       | B: three-tier model
Progress          -> A: demos + screenshots  | B: PRs + written updates

# Adds conditional blocks:
if A: "When to Involve Them" block
if B: "How to Disagree" block
if A + produces-code: "Quality Assurance" sub-block in Engineering Standards
if B + produces-code: "Technical Vision" block
```

The same project could legitimately be Path A for one team member and Path B for another. This confirms the BC-2124 finding: autonomy is a property of the person-project relationship, not an intrinsic project property.

### Where Autonomy Lives in the Flow

1. **Interview Step 1** (unchanged): Determine technical level
2. **Trait classification** (BC-2128): Detect project traits from interview signals
3. **Template generation** (BC-2130): Single template, traits control which sections appear, autonomy level controls language/framing within each section

This is independent of the trait activation and should remain so.

---

## 5. Unified Template Skeleton

Replaces both Path A and Path B templates with a single structure. Sections are grouped by when they appear.

### Always-Include Sections

These appear in every generated CLAUDE.md regardless of traits or autonomy level.

```markdown
## 1. {User Profile | Collaborator Profile}
# Heading varies by autonomy. Content populated from interview.
# A: plain-language goals, constraints, communication preferences
# B: technical background, preferred technologies, project role

## 2. Project Traits
<!-- Classified by project-start. Edit active list to reclassify. -->
active: {comma-separated trait list}
autonomy: {A | B}

### Trait Evidence
- {trait}: {evidence from interview}

## 3. Communication {Rules | Style}
# Heading and content vary by autonomy.
# A: no jargon, translate everything, plain language
# B: technical language, share reasoning, reference code/PRs

## 4. Decision-Making {Authority | Model}
# Heading and content vary by autonomy.
# A: full technical authority, boring tech, ADRs silently
# B: three-tier (collaborative / autonomous / deferred)

## 5. Showing Progress
# Content varies by autonomy.
# A: demos, screenshots, experience-terms
# B: PRs, technical context, blockers, transparency

## 6. Project-Specific Details
# Interview context catch-all. Always present.
```

### Autonomy-Conditional Blocks

Appear based on autonomy level, independent of traits.

```markdown
## When to Involve Them                    <!-- autonomy: A only -->
# Boundary between autonomous and user-facing decisions.
# Examples of when to ask vs. when to decide silently.

## How to Disagree                         <!-- autonomy: B only -->
# Protocol for technical disagreements.
# State recommendation, acknowledge, defer if strong feelings.
```

### Trait-Conditional Sections

Each section appears only when its controlling trait(s) are active. Content within may be further modified by autonomy level.

```markdown
## Engineering Standards                   <!-- trait: produces-code -->
# A: apply automatically, comprehensive, no discussion
# B: baseline, adjust per collaborator preferences
# Sub-block (A only): Quality Assurance -- never show broken things

## Technical Vision                        <!-- trait: produces-code + autonomy B -->
# Agreed tech stack, architecture decisions, open questions, constraints
# (A: this info goes silently into ADRs, not surfaced in CLAUDE.md)

## Document Structure                      <!-- trait: produces-documents -->
# Document purpose and audience
# Outline structure and section conventions
# Review/approval workflow
# Output format (markdown, PDF, slides)
# @import docs/brief.md, docs/outline.md

## Data Context                            <!-- trait: involves-data -->
# Data sources and access methods (warehouse, APIs, files)
# Key tables/models and their relationships
# Data freshness expectations
# Query patterns and conventions
# @import relevant data documentation

## Decision Methodology                    <!-- trait: requires-decisions -->
# ADR format and location (docs/decisions/)
# Evaluation framework (criteria, scoring)
# CDR INDEX @import for conflict checking
# How past decisions are referenced

## User-Facing Requirements                <!-- trait: has-external-users -->
# Accessibility standards (WCAG level target)
# Performance budgets (LCP, CLS, FID thresholds)
# Browser/device support matrix
# Error handling and user-facing messaging
# Monitoring and alerting thresholds

## Client Management                       <!-- trait: client-facing -->
# Communication cadence (frequency, format, channel)
# Deliverable format expectations
# Status update template
# Escalation path
# SOW/timeline references

## Design Approach                         <!-- trait: needs-design -->
# Brand guidelines reference
# Color palette / design tokens
# Typography and component library
# Design review process
# Figma/design tool links
# @import docs/design-context.md

## Marketing Context                       <!-- trait: needs-marketing -->
# Target audience / ICP
# Positioning statement and key messages
# Channel strategy
# Launch timeline
# Competitive context
# @import docs/marketing-context.md

## Sales Context                           <!-- trait: needs-sales -->
# ICP definition
# Competitive landscape
# Pricing strategy
# Objection handling
# Demo/proposal structure
# @import docs/sales-context.md

## Stakeholder Coordination                <!-- trait: cross-team -->
# Stakeholder map (who, what they care about, how to reach them)
# RACI or responsibility model
# Cross-team dependency tracking
# Escalation path
# @import docs/stakeholders.md

## Automation Patterns                     <!-- trait: automation -->
# Scheduler configuration (cron expressions, triggers)
# Retry and failure handling strategy
# Logging and monitoring for automated processes
# Integration points and API contracts
# Idempotency requirements
```

### Section Ordering Rationale

1. **Always-include first** -- establishes who, what, and how before specifics
2. **Autonomy-conditional next** -- sets the collaboration model
3. **Trait-conditional last** -- additive domain-specific context

Within trait-conditional sections, order follows rough frequency from BC-2124 validation data: `produces-code` (3/5 projects) before `produces-documents` (3/5) before `requires-decisions` (4/5) before less common traits.

### Budget Consideration

The design doc (BC-1945) specifies a <100 line budget for CLAUDE.md. The unified template handles this through @imports: each trait-conditional section is a thin pointer (`@import docs/engineering-context.md`) with 2-3 lines of inline context. The detailed content lives in scaffolded docs, not in CLAUDE.md itself.

A project with all 11 traits active would generate ~17 sections. At 3-5 lines each (heading + @import + 1-2 inline notes), that's 51-85 lines -- within budget. Real projects average 3-5 traits (BC-2124), producing ~10-12 sections at 30-60 lines.

---

## 6. Implementation Notes for BC-2130

### Template Engine Requirements

The unified template needs three types of conditionals:

1. **Autonomy switch** -- `{% if autonomy == 'A' %}...{% elif autonomy == 'B' %}...{% endif %}`
2. **Trait gate** -- `{% if 'produces-code' in traits %}...{% endif %}`
3. **Combined** -- `{% if 'produces-code' in traits and autonomy == 'B' %}` (for Technical Vision)

These are simple conditionals, not a full template language. The current template is already pseudo-templated with section headers and placeholder comments. The implementation can use string interpolation with conditional blocks.

### Migration Path

1. BC-2130 implements the unified template skeleton
2. Initially, only `produces-code` trait-conditional sections have real content (ported from current Path A/B Engineering Standards)
3. Subsequent issues (BC-1944 and its sub-tasks) populate the remaining trait-conditional sections with real content
4. The template gracefully degrades: if a trait is active but its section template isn't implemented yet, it generates a placeholder with a TODO comment

### What Changes in project-start.md

| Current | Unified |
|---------|---------|
| Step 1 asks "technical or not?" to select Path A or Path B | Step 1 asks "technical or not?" to set `autonomy: A\|B` |
| Two complete template blocks (lines 179-260 and 264-348) | One template block with conditional sections |
| 9 sections per path (18 total, some duplicated) | 6 always + 2 autonomy-conditional + up to 11 trait-conditional = up to 19 sections |
| Only `produces-code` has template content | All 11 traits have section stubs (content added incrementally) |

### Relationship to Design Doc Phases

This mapping informs Phase 4, Step 4 of the redesign (CLAUDE.md generation). The unified template is what gets generated LAST, after all other artifacts (git, docs, ADRs) are in place. The @imports in trait-conditional sections reference those artifacts.

---

## Cross-References

- **BC-2124** (trait model validation): Confirmed 11 traits are correct, autonomy is orthogonal
- **BC-2126/BC-2128** (trait classification + confirmation): Provides the trait set that drives the template
- **BC-2130** (unified trait-conditional template): Consumes this mapping directly
- **BC-1944** (trait-conditional doc scaffolding): Generates the docs that trait-conditional sections @import
- **BC-1945** (CLAUDE.md with dynamic @imports): The template generation engine
- **Design doc**: `docs/designs/project-start-redesign.md` -- Phase 4 detail
- **PRD activation matrix**: `docs/designs/brite-agent-platform.md` lines 1078-1113
