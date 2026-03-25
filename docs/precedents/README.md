# Decision Trace Precedents

This directory contains decision traces accumulated by the compound-learnings skill during `/workflows:ship`. Each file records non-trivial decisions made by agents during task execution.

**Spec:** `docs/designs/BC-1955-decision-trace-spec.md`

## Directory Structure

```
docs/precedents/
├── INDEX.md              # Active precedent index (lazy-load: read this first)
├── INDEX-archive.md      # Archived entries older than 6 months
├── README.md             # This file — conventions and algorithms
├── <ISSUE-ID>.md         # All decision traces from a single Linear issue
└── ...
```

**Lazy-loading pattern:** Agents read `INDEX.md` first to find relevant precedents by tag, category, or keyword. Only when a match is found do they load the full trace file (`<ISSUE-ID>.md`). This mirrors the CDR INDEX pattern in the handbook.

## INDEX Format

| Column | Type | Constraints |
|--------|------|-------------|
| Issue | string | Issue ID (e.g., `BC-1234`). Links to `<ISSUE-ID>.md` in this directory. |
| Decision | string | Max 120 chars. Single line. From the trace's **Decision** field. |
| Category | enum | `architecture` \| `library-selection` \| `pattern-choice` \| `trade-off` \| `bug-resolution` \| `scope-change` |
| Date | date | ISO format `YYYY-MM-DD`. From the trace heading. |
| Tags | string | Comma-separated, max 5 per entry. See Tag Conventions below. |

## Tag Conventions

Tags enable lightweight search across precedents without reading full trace files.

### Derivation

compound-learnings derives tags automatically during `/workflows:ship`:

1. **Tag #1** is always the category (e.g., `architecture`)
2. **Tags #2-5** are key nouns from the Decision field — technology names, domain concepts, or pattern names

### Format Rules

- Lowercase kebab-case: `^[a-z0-9]+(-[a-z0-9]+)*$`
- Max 30 characters per tag
- Max 5 tags per INDEX entry

### Preferred Vocabulary

| Type | Examples |
|------|---------|
| Technology names | `supabase`, `prisma`, `next-js`, `resend`, `stripe`, `clerk` |
| Domain concepts | `multi-tenant`, `auth`, `email`, `billing`, `onboarding`, `rls` |
| Pattern names | `rls`, `cqrs`, `pub-sub`, `event-sourcing`, `result-type`, `lazy-load` |

**Avoid** generic terms: `code`, `fix`, `change`, `update`, `improvement`, `refactor`

## Auto-Update Algorithm

compound-learnings executes this during Phase 2f of `/workflows:ship`:

1. **Read** `INDEX.md` (create with empty template if missing)
2. **Parse** the markdown table — skip the header row and separator row
3. **Match** each new trace against existing rows by composite key: Issue column + Decision text
4. **Replace** matched rows (re-execution of same task produces updated trace). **Append** unmatched rows at the bottom.
5. **Sort order:** Chronological by insertion (newest last). No re-sorting on update — avoids gratuitous diffs.
6. **Archive check:** If row count exceeds 200, move entries with Date older than 6 months to `INDEX-archive.md`
7. **Write** the full `INDEX.md` file (atomic rewrite, not incremental append). Preserve the HTML comment block above the table header.

### Dedup on Re-Execution

When a task is re-executed (e.g., after a revert), the new trace replaces the old one:

- Parse the Issue column and Decision text from each existing row
- Compare against the new trace's issue ID and decision summary
- If both match: replace the entire row (Date and Tags may change)
- If Issue matches but Decision differs: new trace from the same issue — append

### Archive Rotation

Triggered when INDEX.md exceeds 200 data rows after an update:

1. Identify rows where Date is older than 6 months from today
2. Remove those rows from INDEX.md
3. Append them to INDEX-archive.md (create with header if missing)
4. Log: "Archived [N] precedent entries older than 6 months to INDEX-archive.md"

## Org-Level INDEX

The handbook repo (`handbook/precedents/INDEX.md`) uses the same format. Traces promoted from project-level are copied there after human review. Promotion criteria (BC-1955 Section 6):

1. Confidence >= 8/10
2. Category is `architecture`, `library-selection`, or `trade-off`
3. Establishes a reusable pattern (not project-specific)

compound-learnings creates a Linear issue with label `precedent-promotion` for eligible traces. Promotion is never automatic.

## Promotion Workflow

The `/workflows:promote-precedent` command handles the human-reviewed promotion of flagged traces to the handbook. The full flow:

1. **Flag** — During `/workflows:ship`, compound-learnings (Phase 2g) identifies traces meeting all 3 promotion criteria and creates a Linear issue with label `precedent-promotion`
2. **Review** — Developer runs `/workflows:promote-precedent` to review flagged candidates one at a time. Each candidate is presented with full trace context and a generalizability assessment
3. **Promote** — Approved traces are copied to a shallow clone of `Brite-Nites/handbook`, with project-specific paths generalized (e.g., `src/foo.ts` → `<project>/src/foo.ts`)
4. **PR** — A PR is opened against the handbook repo with all promoted traces. The handbook INDEX is updated using the same auto-update algorithm as the project-level INDEX
5. **Close** — Linear issues are updated with the PR link and transitioned to Done (promoted) or Cancelled (skipped)

**Important**: Project-level traces remain in `docs/precedents/` after promotion. The handbook copy is independent — the project retains its own decision history.

## Consumers

| Consumer | How it uses INDEX.md |
|----------|---------------------|
| `precedent-search` skill (BC-1961) | Reads INDEX to find relevant past decisions by tag/category, loads full trace files on match |
| `brainstorming` skill | Searches INDEX for prior art before design |
| `writing-plans` skill | References INDEX for established patterns |
| `compound-learnings` skill | Writes new rows during `/workflows:ship` |
