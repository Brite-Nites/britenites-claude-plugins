# BC-1955: Decision Trace Format Specification

**Issue:** BC-1955
**Date:** 2026-03-20
**Status:** Accepted
**Blocks:** BC-1956, BC-1957, BC-1959, BC-1961

---

## Problem

The executing-plans skill emits per-task execution traces and the compound-learnings skill extracts decision traces during `/workflows:ship`. Both skills need formal, field-level specifications for their respective formats — what to emit, how to validate, where to store, and when to promote. The PRD (`docs/designs/brite-agent-platform.md`, lines 578–754) sketches the formats but lacks validation rules, size limits, data safety constraints, and a formal integration contract between emitting and consuming skills.

Without this spec, BC-1956 (trace emission) and BC-1957 (trace extraction) cannot be implemented — they have no shared schema to code against. BC-1959 (precedent INDEX) and BC-1961 (precedent search) depend on the storage paths and INDEX format defined here.

---

## Key Terminology

- **CDR** (Company Decision Record) — org-level, long-lived, formal. "We use Supabase for all new databases."
- **ADR** (Architecture Decision Record) — project-level, long-lived, formal. "We chose Next.js App Router."
- **Decision Trace** — task-level, continuous, lightweight. Emitted automatically during execution when a non-trivial decision is made. Stored in `docs/precedents/`.
- **Execution Trace** — YAML block emitted by executing-plans at task completion. Contains `decisions_made` entries that compound-learnings converts to decision traces.
- **Precedent** — an accumulated decision trace that future agents can search to inform current decisions.

---

## Formal Specification

### 1. Decision Trace Markdown Format

The decision trace is the stored format — what lives in `docs/precedents/<ISSUE-ID>.md` after compound-learnings extracts it from execution traces.

```markdown
## Trace — <ISSUE-ID>/task-<N> — <YYYY-MM-DD>

**Decision:** <One-line summary of what was decided>
**Category:** architecture | library-selection | pattern-choice | trade-off | bug-resolution | scope-change
**Confidence:** N/10

### Inputs
- <What information was available when the decision was made>
- <Which context docs were read>
- <What code was examined>

### Alternatives Considered
1. **<Chosen option>** — <why chosen>
2. **<Rejected option>** — <why rejected>

### Precedent Referenced
- <CDR-XXX, ADR-YYY, or previous decision trace>
- Or "None — first time encountering this pattern"

### Outcome
- **Files changed:** <list>
- **Tests:** <N> added, <N> passed, <N> failed
- **Approved by:** <PR review / human checkpoint / auto-verified>
```

#### Field Validation

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| Decision | string | yes | Max 120 chars. Single line. No newlines. |
| Category | enum | yes | One of: `architecture`, `library-selection`, `pattern-choice`, `trade-off`, `bug-resolution`, `scope-change` |
| Confidence | integer | yes | Range 1–10 inclusive. Display as `N/10` in markdown; bare integer in YAML. Conversion strips `/10` suffix. |
| Inputs | bullet list | yes | Min 1 item. Each item max 200 chars. |
| Alternatives Considered | numbered list | yes | Min 2 items. Exactly 1 "chosen" + at least 1 "rejected". |
| Precedent Referenced | bullet list | yes | "None" allowed as a single item. Each item max 200 chars. |
| Outcome: Files changed | string list | yes | Relative paths only. Max 20 items. |
| Outcome: Tests | string | yes | Format: `<N> added, <N> passed, <N> failed` or `N/A` |
| Outcome: Approved by | string | yes | One of: `PR review`, `human checkpoint`, `auto-verified` |

### 2. Execution Trace YAML Format

The execution trace is the emitted format — what executing-plans produces at each task checkpoint. It is inlined in the conversation context as a fenced YAML block.

```yaml
# execution-trace-v1
task: <ISSUE-ID>/task-<N>
agent: execute-subagent
timestamp: <ISO-8601>
duration: <N>m <N>s

context_used:
  - <relative file path or doc reference>

decisions_made:
  - type: <category>
    chose: "<chosen option>"
    over: ["<rejected option 1>", "<rejected option 2>"]
    reason: "<why chosen>"
    confidence: <1-10>

files_changed:
  - <relative path> (<action>, +<added> -<removed>)

tests:
  added: <N>
  passed: <N>
  failed: <N>

verification:
  build: pass | fail
  tests: pass | fail
  acceptance_criteria: pass | fail | partial
  integration: pass | fail | skipped
```

#### Field Validation

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| task | string | yes | Pattern: `^[A-Z]+-[0-9]+/task-[0-9]+$` |
| agent | string | yes | Non-empty |
| timestamp | string | yes | ISO-8601 format |
| duration | string | yes | Pattern: `^[0-9]+m [0-9]+s$` |
| context_used | string[] | yes | Each item max 200 chars. Relative paths only. |
| decisions_made | object[] | no | Empty array if no non-trivial decisions. Each entry validated per Decision Entry schema below. |
| decisions_made[].type | enum | yes | Same values as Category in decision trace |
| decisions_made[].chose | string | yes | Max 120 chars |
| decisions_made[].over | string[] | yes | Min 1 item. Each max 120 chars. |
| decisions_made[].reason | string | yes | Max 200 chars |
| decisions_made[].confidence | integer | yes | Range 1–10 inclusive |
| files_changed | string[] | yes | Relative paths. Max 20 items. Format: `<path> (<action>, +<N> -<N>)` |
| tests.added | integer | yes | >= 0 |
| tests.passed | integer | yes | >= 0 |
| tests.failed | integer | yes | >= 0 |
| verification.build | enum | yes | `pass` or `fail` |
| verification.tests | enum | yes | `pass` or `fail` |
| verification.acceptance_criteria | enum | yes | `pass`, `fail`, or `partial` |
| verification.integration | enum | yes | `pass`, `fail`, or `skipped` |

### 3. Emission Categories

Decision traces are categorized into 6 types. Each has a trigger condition and example.

| Category | Trigger Condition | Example Scenario | Example Decision Summary |
|----------|-------------------|------------------|--------------------------|
| `architecture` | Choosing between structural approaches, patterns, or component boundaries | Multi-tenancy implementation | "Chose row-level security over app-level filtering" |
| `library-selection` | Picking a dependency when alternatives exist | Auth library choice | "Chose @supabase/ssr over next-auth" |
| `pattern-choice` | Selecting a coding pattern, data flow, or API design | Error handling strategy | "Chose Result type over try/catch for domain layer" |
| `trade-off` | Explicitly choosing between competing concerns | Performance vs readability | "Chose denormalized table for read perf over normalized for write simplicity" |
| `bug-resolution` | Root cause identified and fix approach chosen | Flaky test investigation | "Root cause: race condition in cleanup hook; fix: explicit teardown ordering" |
| `scope-change` | Implementation diverges from plan | Feature dropped mid-task | "Dropped real-time sync from scope; will implement as follow-up" |

### 4. Emission Rules

**EMIT when:**
- The decision falls into one of the 6 categories above, AND
- The decision is non-trivial (affects multiple files, changes architecture, or involves rejected alternatives)

**DO NOT EMIT when:**
- Variable naming, formatting, or import ordering
- Using standard patterns already established in the project
- Choosing between trivially equivalent approaches (e.g., `for` vs `.map()` for a 3-item array)
- Following a CDR/ADR exactly as written (no deviation = no trace needed)

**Confidence threshold for storage:** Traces with confidence >= 6 are persisted to `docs/precedents/`. Traces with confidence < 6 are ephemeral — shown in the task checkpoint output for transparency but NOT written to disk.

**Max traces per task:** 3. If a task generates more than 3 qualifying decisions, combine related decisions into a single trace or escalate to a design doc. This forces prioritization — capture the most impactful decisions, not every micro-choice.

### 5. Trace Identity

**Heading format:**
```
## Trace — <ISSUE-ID>/task-<N> — <YYYY-MM-DD>
```

**File path:** `docs/precedents/<ISSUE-ID>.md` — one file per issue, multiple trace sections appended as H2 headings.

**INDEX path:** `docs/precedents/INDEX.md` — project-level index of all precedent files.

**Identity:** The H2 heading is the unique identifier within the project. The combination of issue ID + task number + date ensures uniqueness. If the same task is re-executed (e.g., after a revert), the new trace replaces the previous one with the same task identifier.

**Deep-link anchors:** compound-learnings should emit an HTML anchor before each trace heading for direct linking:
```markdown
<a id="BC-1234-task-3"></a>
## Trace — BC-1234/task-3 — 2026-03-10
```
Anchor format: `<ISSUE-ID>-task-<N>` (kebab-case). Consumers can link to `docs/precedents/<ISSUE-ID>.md#<ISSUE-ID>-task-<N>` to jump directly to a specific trace.

### 6. Storage & Accumulation Flow

#### Project-Level Storage

```
docs/precedents/
├── INDEX.md                    # Markdown table index of all precedents
├── BC-1234.md                  # All traces from issue BC-1234
├── BC-1567.md                  # All traces from issue BC-1567
└── ...
```

#### Org-Level Storage

```
handbook/precedents/
├── INDEX.md                    # Cross-project index
├── BC-1234.md                  # Promoted traces from BC-1234
└── ...
```

#### INDEX Format

```markdown
# Precedent Index

| Issue | Decision | Category | Date | Tags |
|-------|----------|----------|------|------|
| BC-1234 | Row-level security for multi-tenancy | architecture | 2026-03-10 | multi-tenant, supabase, rls |
| BC-1189 | Chose Resend over SendGrid for transactional email | library-selection | 2026-02-28 | email, transactional |
```

INDEX columns:
- **Issue:** Issue ID (links to the precedent file)
- **Decision:** Decision field from the trace (max 120 chars)
- **Category:** One of the 6 emission categories
- **Date:** ISO date from the trace heading
- **Tags:** Comma-separated, lowercase, kebab-case. Max 5 per entry. Derived from the decision content by compound-learnings.

#### Accumulation Flow

```
Agent executes task
  → executing-plans emits execution trace YAML at checkpoint
    → compound-learnings extracts decisions_made entries during /ship
      → Traces with confidence >= 6 written to docs/precedents/<ISSUE-ID>.md
        → INDEX.md updated with new entries
          → Eligible traces flagged for org-level promotion
```

#### Promotion Criteria

A trace is eligible for promotion to `handbook/precedents/` when ALL of:
1. Confidence >= 8/10
2. Category is `architecture`, `library-selection`, or `trade-off`
3. Establishes or validates a reusable pattern (not project-specific)

**Promotion is never automatic.** compound-learnings flags eligible traces and creates a Linear issue for human review. The reviewer decides whether to copy the trace to the handbook. This is deliberate — bad precedents at the org level are high-stakes.

### 7. Size & Volume Limits

| Constraint | Limit | Rationale |
|------------|-------|-----------|
| Per-trace | Max 30 lines | Keeps traces scannable; forces conciseness |
| Per-issue file | Max 15 traces | Caps file size; most issues have 1–5 tasks |
| Decision field | Max 120 chars | Single line, scannable in INDEX |
| Bullet items (Inputs, Alternatives, Precedent) | Max 200 chars each | Prevents paragraph-length bullets |
| Outcome: Files changed | Max 20 items | Limits scope of a single trace |
| Tags per INDEX entry | Max 5 | Prevents tag sprawl |
| INDEX.md rows | Advisory: 200 rows | When exceeded, archive entries older than 6 months to INDEX-archive.md |
| Cumulative execution traces per session | Advisory: ~500 lines for a 15-task plan | Traces accumulate in conversation context; budget impact ~5-10% of context window |
| docs/precedents/ directory | Advisory: 50 files | Not enforced; signals when pruning is needed |

### 8. Data Safety

Decision traces contain agent-generated content from execution. The primary risk surface is user-supplied data (issue titles, descriptions, acceptance criteria) flowing into trace fields.

#### Sanitization Rules

**Single-line fields** (Decision, chose, over, reason):
- Strip newline characters (`\n`, `\r`)
- Allow characters matching `[a-zA-Z0-9 _./@#:()'\"-]`
- Strip all other characters
- Enforce field-specific length caps (see Section 7)

**Bullet-list fields** (Inputs, Alternatives Considered, Precedent Referenced):
- Apply the same character allowlist as single-line fields: `[a-zA-Z0-9 _./@#:()'\"-]`
- Strip markdown link syntax: no `[text](url)` or `![alt](url)`
- Strip HTML tags
- Each item max 200 chars (see Section 7)

**Code snippets** in Inputs or Alternatives:
- Wrap in backticks
- Max 80 chars inline (longer snippets = reference the file path instead)

**File paths:**
- Must be relative to project root
- No absolute paths (no `/Users/...`, no `~/...`)
- Must not contain `..` path segments (no traversal)
- Pattern: must not start with `/` or `~`

**ISSUE-ID in storage paths:**
- Must match `^[A-Z]+-[0-9]+$` (same constraint as the task field prefix)
- Validate that resolved path is within `docs/precedents/` before writing

**Secrets and credentials:**
- Never include raw tokens, API keys, or credentials in any trace field
- If a decision involves a secret (e.g., "chose environment variable over hardcoded key"), reference the pattern, not the value
- Match and redact known patterns: `sk-[a-zA-Z0-9]{20,}`, `sk-proj-[a-zA-Z0-9]{10,}`, `AKIA[A-Z0-9]{12,}`, `gh[ps]_[a-zA-Z0-9]{20,}`, `sk_(live|test)_[a-zA-Z0-9]{10,}`

**Tags:**
- Lowercase, kebab-case only: `[a-z0-9-]`
- Max 30 chars per tag

### 9. Integration Contract

#### Participants

| Role | Skill | When |
|------|-------|------|
| Emitter | executing-plans | At each task checkpoint, after task completion |
| Consumer | compound-learnings | During `/workflows:ship` |

#### Transport

Execution trace YAML is inlined in the conversation context as a fenced code block. This is the transport mechanism — no temp files, no shared state.

**Why conversation context?** Subagents spawned by executing-plans cannot share files with the parent conversation. The conversation transcript is the only reliable channel between execution and ship phases.

#### Emission (executing-plans → conversation)

1. At each task checkpoint, executing-plans emits a fenced YAML block with a structural marker:
   ````
   ```yaml
   # execution-trace-v1
   task: BC-1234/task-3
   agent: execute-subagent
   ...
   ```
   ````
2. The YAML block follows the Execution Trace schema (Section 2)
3. If the task had no non-trivial decisions, `decisions_made` is an empty array
4. The block is emitted AFTER the task verification report, BEFORE the next task begins

#### Extraction (compound-learnings ← conversation)

1. compound-learnings scans the conversation for fenced YAML blocks starting with `# execution-trace-v1` and `task:` as the second key
2. For each execution trace found:
   a. Parse `decisions_made` array
   b. Filter: keep entries with `confidence >= 6`
   c. Convert each qualifying entry to decision trace markdown (Section 1)
   d. Derive tags from the decision content (category + key nouns, max 5)

#### Storage (compound-learnings → filesystem)

1. Batch all qualifying traces per issue — write each `docs/precedents/<ISSUE-ID>.md` file once (not per-trace)
2. For each qualifying trace within the issue file:
   a. Append to the issue file (create file if new)
   b. If the file already contains a trace with the same heading (re-execution), replace it
3. After all issue files are written, update `docs/precedents/INDEX.md` once with all new/updated rows

#### Promotion Flagging (compound-learnings → Linear)

1. For each trace meeting promotion criteria (Section 6):
   a. Log: "Trace eligible for org-level promotion: [Decision summary]"
   b. Create a Linear issue with label `precedent-promotion` for human review
2. Do NOT copy to `handbook/precedents/` automatically

---

## Key Design Decisions

### Decision 1: One file per issue, not one file per trace

Traces are grouped by issue ID in `docs/precedents/<ISSUE-ID>.md`. Each trace is an H2 section within the file.

**Rationale:** A typical issue produces 1–5 tasks, each with 0–3 traces. One-file-per-trace would create 3–15 files per issue, rapidly bloating `docs/precedents/`. Grouping by issue keeps the directory flat (one file per issue worked on) and makes it easy to see all decisions from a single piece of work.

### Decision 2: Confidence >= 6 for storage, >= 8 for promotion

Two thresholds filter noise at different stages:
- **>= 6:** Persisted to project-level precedents. Agent was reasonably confident.
- **>= 8:** Eligible for org-level promotion. High-confidence, reusable pattern.

**Rationale:** Below 6 means the agent was uncertain — the decision might be wrong or context-dependent. Storing uncertain traces pollutes the precedent database. Promoting anything below 8 risks establishing bad patterns org-wide.

### Decision 3: Two distinct formats (execution YAML vs decision markdown)

The execution trace (YAML) and decision trace (markdown) serve different audiences:
- **Execution trace:** Machine-readable, comprehensive, emitted during execution. Includes files changed, tests, verification status.
- **Decision trace:** Human-readable, focused on reasoning. Omits operational details, emphasizes inputs, alternatives, and precedent.

**Rationale:** A single format would either be too verbose for humans (YAML with test counts) or too sparse for machines (markdown with no structured fields). The conversion step in compound-learnings is lightweight — it maps `decisions_made` entries to markdown sections.

### Decision 4: Conversation context as transport, not temp files

Execution traces are passed via the conversation transcript, not via temp files or shared directories.

**Rationale:** executing-plans spawns fresh subagents per task. These subagents cannot write to a shared temp directory that compound-learnings later reads — subagent file writes are scoped to the worktree, and compound-learnings runs in the parent conversation. The conversation transcript is the only guaranteed channel.

### Decision 5: Human-in-the-loop for org promotion

Promotion from project-level to org-level precedents requires human approval via a Linear issue.

**Rationale:** Org-level precedents influence all future projects. A bad precedent (e.g., "chose X over Y" when Y was actually correct) would propagate incorrect decisions across the organization. The cost of creating a Linear issue is low; the cost of a bad org-level precedent is high.

### Decision 6: Max 3 traces per task

If a single task generates more than 3 qualifying decisions, the agent must combine related decisions or escalate to a design doc.

**Rationale:** More than 3 non-trivial decisions in a single task suggests the task is too large or the agent is over-tracing. Combining forces the agent to identify the most impactful decisions. Escalating to a design doc (via brainstorming) is appropriate when a task involves enough decisions to warrant formal analysis.

---

## Examples

### Full Example: Architecture Decision

```markdown
## Trace — BC-1234/task-3 — 2026-03-10

**Decision:** Chose row-level security over app-level filtering for multi-tenant data isolation
**Category:** architecture
**Confidence:** 9/10

### Inputs
- Read `handbook/decisions/engineering/CDR-001.md` (mandates Supabase)
- Read `src/middleware/auth.ts` (145 lines, existing auth pattern)
- Precedent search: found BC-1089 used RLS successfully for similar scope

### Alternatives Considered
1. **Row-level security (RLS)** — database-enforced, no app-code leak risk, aligns with CDR-001
2. **App-level filtering** — more flexible but requires every query to include tenant_id; single missed WHERE = data leak

### Precedent Referenced
- BC-1089: "RLS for tenant isolation in billing module" (confidence 8, 2026-02-15)
- CDR-001: "All new databases use Supabase"

### Outcome
- **Files changed:** `src/middleware/auth.ts`, `prisma/schema.prisma`, `src/lib/supabase.ts`
- **Tests:** 3 added, 3 passed, 0 failed
- **Approved by:** auto-verified
```

### Minimal Example: Library Selection

```markdown
## Trace — BC-1567/task-1 — 2026-03-15

**Decision:** Chose Resend over SendGrid for transactional email
**Category:** library-selection
**Confidence:** 7/10

### Inputs
- Checked Vercel Marketplace for email integrations
- Read `docs/engineering-context.md` for existing infra

### Alternatives Considered
1. **Resend** — native Vercel Marketplace, auto-provisioned env vars, simpler API
2. **SendGrid** — more mature but requires manual key management, no Marketplace integration

### Precedent Referenced
- None — first time selecting an email provider in this project

### Outcome
- **Files changed:** `src/lib/email.ts`, `package.json`
- **Tests:** 1 added, 1 passed, 0 failed
- **Approved by:** human checkpoint
```

### Anti-Patterns

**Do NOT trace a variable rename:**
> "Renamed `userData` to `userProfile`" — this is a formatting/naming choice, not a non-trivial decision. No alternatives were considered, no trade-offs evaluated.

**Do NOT trace with confidence 3:**
> A trace with confidence 3/10 means the agent is guessing. This should not be persisted — it would pollute the precedent database with unreliable patterns. Show it in checkpoint output for transparency, but do not write to `docs/precedents/`.

**Do NOT trace standard pattern usage:**
> "Used Server Components for the dashboard page" — this follows the project's established convention (per CLAUDE.md). No deviation = no trace.

---

## Cross-References

- **PRD:** `docs/designs/brite-agent-platform.md` (lines 578–754)
- **Context-Skill Standard:** `docs/designs/BC-1966-context-skill-standard.md`
- **Workflow Spec:** `docs/workflow-spec.md` (contract: decision-trace, artifact registry, inner-loop chain, context layers)
- **BC-1956:** Trace emission in executing-plans (blocked by this spec)
- **BC-1957:** Trace extraction in compound-learnings (blocked by this spec)
- **BC-1959:** Precedent INDEX implementation (blocked by this spec)
- **BC-1961:** Precedent search skill (blocked by this spec)
