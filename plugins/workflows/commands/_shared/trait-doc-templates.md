# Trait-Conditional Documentation Templates

Shared templates for scaffolding documentation files based on active project traits. Used by `project-start` during the "Scaffold Trait-Conditional Documentation" step.

Each template defines the heading structure and placeholder content for its trait's documentation file. The calling command populates placeholders with interview data and marks under-discussed sections with `<!-- needs-review -->`.

---

## `produces-code`

```markdown
# Engineering Context

## Tech Stack
- Language(s): [from interview]
- Framework(s): [from interview]
- Key libraries: [from interview or autonomous choice]

## Architecture Overview
- High-level pattern: [monolith, microservices, serverless, etc.]
- Key components and their responsibilities
- Data flow between components

## Development Environment
- Required tooling and versions
- Local setup steps
- Environment variables needed (names only, not values)

## Code Conventions
- Style guide or linter config: [ESLint, Prettier, Ruff, etc.]
- Naming conventions: [files, components, variables]
- Import ordering and module boundaries

## CI/CD & Deployment
- Build command and output
- Test command(s)
- Deployment target: [Vercel, AWS, self-hosted, etc.]
- Branch strategy: [trunk-based, gitflow, etc.]
```

---

## `produces-documents` (brief)

```markdown
# Project Brief

## Purpose & Audience
- What this document/deliverable achieves
- Primary audience: [who reads or uses it]
- Secondary audience: [if any]

## Scope & Deliverables
- Included deliverables: [list]
- Explicitly excluded: [list]
- Format(s): [PDF, slide deck, wiki, etc.]

## Constraints
- Deadline: [date or milestone]
- Length/format requirements
- Brand or style guidelines to follow

## Review Process
- Reviewer(s): [names or roles]
- Review cadence: [async, scheduled, per-draft]
- Approval criteria: [what "done" looks like]
```

---

## `produces-documents` (outline)

```markdown
# Document Outline

## Document Structure
- Sections and their purpose
- Estimated length per section
- Logical flow and dependencies between sections

## Source Material
- Existing documents to reference: [list]
- Data sources: [dashboards, databases, interviews]
- Subject matter experts: [names or roles]

## Output Format
- Final format: [Google Doc, Markdown, PDF, slides]
- Template to follow: [link or description]
- Visual assets needed: [charts, diagrams, screenshots]

## Approval Workflow
- Draft review cycle: [number of rounds]
- Sign-off required from: [names or roles]
- Distribution plan: [how and where it gets shared]
```

---

## `involves-data`

```markdown
# Data Context

## Data Sources & Access
- Primary source(s): [warehouse, API, database]
- Access method: [direct query, API, export]
- Credentials/permissions needed: [role or access level]

## Key Tables/Models
- Core tables or models used by this project
- Relationships and join patterns
- Row counts / data volume (approximate)

## Data Freshness & SLAs
- Refresh cadence: [real-time, hourly, daily, manual]
- Acceptable staleness: [how old is too old]
- Upstream dependencies: [pipelines, ETL jobs]

## Query Patterns
- Common query shapes: [aggregations, joins, filters]
- Performance-sensitive queries: [list any known slow paths]
- Materialized views or pre-aggregated tables: [if any]

## Warehouse-Specific Notes
- Platform: [Snowflake, BigQuery, Redshift, Databricks, etc.]
- Compute/cost considerations: [warehouse size, slot limits]
- Naming conventions: [schema.table patterns, prefixes]
```

---

## `requires-decisions`

```markdown
# Decision Methodology

## ADR Process
- Location: `docs/decisions/NNN-kebab-title.md`
- Numbering: sequential, zero-padded to 3 digits
- Statuses: Proposed → Accepted → Superseded | Deprecated

## Evaluation Framework
- How options are identified: [research, team discussion, spikes]
- How options are compared: [pros/cons, weighted criteria, prototypes]
- Who has decision authority: [individual, team, leadership]

## Decision Criteria Template
- Business impact: [revenue, user experience, compliance]
- Technical fit: [maintainability, scalability, team expertise]
- Cost: [licensing, infrastructure, opportunity cost]
- Reversibility: [easy to change later vs. locked in]

## ADR Conflict Checking
- Check existing ADRs before proposing conflicting decisions
- Reference superseded decisions when revisiting a topic
- Escalation path for deadlocked decisions: [who breaks ties]
```

---

## `has-external-users`

```markdown
# User Requirements

## Accessibility Standards
- WCAG target level: [A, AA, AAA]
- Assistive technology support: [screen readers, keyboard-only]
- Color contrast and text sizing requirements

## Performance Budgets
- LCP target: [e.g., < 2.5s]
- CLS target: [e.g., < 0.1]
- FID/INP target: [e.g., < 200ms]
- Bundle size budget: [if applicable]

## Browser & Device Support
- Supported browsers: [Chrome, Firefox, Safari, Edge — versions]
- Mobile support: [responsive, native, PWA]
- Minimum screen resolution: [if applicable]

## Error Handling
- User-facing error message style: [friendly, technical, contextual]
- Error reporting: [how errors surface to the team]
- Fallback behavior: [graceful degradation strategy]

## Monitoring
- Uptime target: [e.g., 99.9%]
- Alerting: [PagerDuty, Slack, email — who gets paged]
- Key metrics to track: [error rate, latency, conversion]
```

---

## `client-facing`

```markdown
# Client Management

## Communication Cadence
- Regular check-ins: [weekly, biweekly, milestone-based]
- Format: [call, email, shared doc, Slack]
- Point of contact: [name and role, both sides]

## Deliverable Format
- How work is presented: [demo, document, deployment]
- Deliverable naming/versioning: [convention]
- Handoff process: [how deliverables are transferred]

## Status Update Template
- Completed since last update: [list]
- In progress: [list with % or ETA]
- Blocked or at risk: [list with mitigation]
- Next steps: [list with owners]

## Escalation Path
- Internal escalation: [who to loop in, when]
- Client escalation: [who on their side, when to escalate]
- SLA or response-time commitments: [if any]

## SOW References
- Statement of Work location: [link or path]
- Key milestones and dates from SOW
- Change request process: [how scope changes are handled]
```

---

## `needs-design`

```markdown
# Design Context

## Brand Guidelines
- Brand guide location: [link or path]
- Logo usage rules: [sizing, clear space, variants]
- Voice and tone: [formal, casual, playful, authoritative]

## Color Palette & Tokens
- Primary: [hex/oklch]
- Secondary: [hex/oklch]
- Accent: [hex/oklch]
- Semantic tokens: [success, warning, error, info]
- Dark mode considerations: [if applicable]

## Typography & Components
- Heading font: [name, weights]
- Body font: [name, weights]
- Monospace font: [name, for code/data]
- Component library: [shadcn/ui, MUI, custom, etc.]

## Design Review Process
- Who reviews: [designer name/role]
- Review format: [Figma comments, PR review, meeting]
- Approval required before implementation: [yes/no]

## Tool Links
- Figma project: [link]
- Design system: [link]
- Asset repository: [link]
```

---

## `needs-marketing`

```markdown
# Marketing Context

## Target Audience / ICP
- Primary audience: [demographics, role, pain points]
- Secondary audience: [if any]
- Audience research: [link to personas, surveys, data]

## Positioning & Messages
- One-line positioning statement
- Key messages: [3-5 bullets]
- Differentiators: [what sets this apart]

## Channel Strategy
- Primary channels: [social, email, content, paid, events]
- Channel-specific requirements: [character limits, formats]
- Content calendar: [link or cadence]

## Launch Timeline
- Soft launch date: [if applicable]
- Public launch date: [date]
- Pre-launch milestones: [list]
- Post-launch follow-up: [what happens after launch]

## Competitive Context
- Key competitors: [list]
- Competitive advantages: [list]
- Positioning relative to competitors: [how to frame]
```

---

## `needs-sales`

```markdown
# Sales Context

## ICP Definition
- Ideal customer profile: [industry, size, role, pain]
- Qualifying criteria: [budget, authority, need, timeline]
- Disqualifying signals: [when to walk away]

## Competitive Landscape
- Direct competitors: [list with brief positioning]
- Indirect competitors: [adjacent solutions]
- Win/loss patterns: [why we win, why we lose]

## Pricing
- Pricing model: [per-seat, usage, flat, tiered]
- Price points: [list tiers or ranges]
- Discounting authority: [who can approve, limits]

## Objection Handling
- Common objections: [list top 3-5]
- Recommended responses: [per objection]
- Proof points: [case studies, metrics, testimonials]

## Demo & Proposal Structure
- Demo flow: [what to show, in what order]
- Proposal template: [link or description]
- Follow-up cadence: [timing and touchpoints after demo]
```

---

## `cross-team`

```markdown
# Stakeholders

## Stakeholder Map
- Executive sponsor: [name, role]
- Project lead: [name, role]
- Key contributors: [name, role, responsibility]
- Informed parties: [name, role — kept in the loop]

## RACI Model
- Responsible: [who does the work]
- Accountable: [who owns the outcome]
- Consulted: [who provides input]
- Informed: [who needs updates]

## Communication Channels
- Primary channel: [Slack channel, email list, meeting]
- Async updates: [where and how often]
- Sync meetings: [cadence, attendees, format]

## Cross-Team Dependencies
- Depends on: [team/project — what we need from them]
- Depended on by: [team/project — what they need from us]
- Shared resources: [infrastructure, data, design, etc.]

## Escalation Path
- Technical blockers: [who to contact]
- Priority conflicts: [who arbitrates]
- Timeline risks: [who needs to know, when]
```

---

## `automation`

```markdown
# Automation Patterns

## Trigger Configuration
- Trigger type: [cron schedule, webhook, event, manual]
- Schedule: [cron expression or cadence]
- Event source: [what system fires the trigger]

## Retry & Failure Handling
- Retry strategy: [exponential backoff, fixed delay, none]
- Max retries: [number]
- Dead letter queue: [where failed items go]
- Alert on failure: [who gets notified, how]

## Logging & Monitoring
- Log destination: [stdout, file, external service]
- Log level: [info, warn, error — what gets logged]
- Metrics to track: [run count, duration, error rate]
- Dashboard: [link or description]

## Integration Points
- Upstream systems: [what feeds into this automation]
- Downstream systems: [what this automation triggers]
- Authentication: [how the automation authenticates to external services]

## Idempotency
- Idempotent operations: [which steps are safe to re-run]
- Non-idempotent risks: [which steps must not double-execute]
- Deduplication strategy: [how duplicate triggers are handled]
```
