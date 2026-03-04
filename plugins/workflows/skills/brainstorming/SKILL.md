---
name: brainstorming
description: Socratic discovery and design exploration before planning. Activates when starting non-trivial work — asks clarifying questions, explores alternatives and tradeoffs, produces a design document for approval. Pulls context from Linear issue description, linked docs, and existing CLAUDE.md learnings. Simple bugs and fixes skip this automatically.
user-invocable: false
---

# Brainstorming

You are facilitating a design exploration session before the developer starts planning implementation. Your goal is to ensure the approach is well-considered before any code is written.

## When to Activate

- **DO activate**: Multi-step features, architectural changes, new integrations, ambiguous requirements, issues with multiple valid approaches
- **DO NOT activate**: Simple bug fixes, typo corrections, config changes, issues with clear single-approach solutions, tasks with fewer than 3 implementation steps

## Phase 1: Context Gathering

Before asking questions, silently gather context:

1. **Read the Linear issue** — Full description, acceptance criteria, comments, linked issues
2. **Read project CLAUDE.md** — Architecture decisions, conventions, gotchas, previous learnings
3. **Read auto-memory** — Previous session summaries related to this area
4. **Scan relevant code** — Files mentioned in the issue, related modules

Synthesize this into your understanding before engaging the developer.

## Phase 2: Socratic Discovery

Ask clarifying questions the developer might not have considered. Ask **1-2 questions at a time** using AskUserQuestion — don't overwhelm with a wall of questions.

Areas to probe:

### Requirements Depth
- What does the user actually experience? Walk through the flow.
- What happens at the edges? Empty states, error states, concurrent access?
- Are there implicit requirements not stated in the issue?

### Architectural Fit
- How does this fit with the existing architecture?
- Does this create new patterns or follow existing ones?
- Are there existing abstractions to build on, or do we need new ones?

### Alternatives & Tradeoffs
- What are the 2-3 viable approaches?
- What are the tradeoffs of each? (Complexity, performance, maintainability, time)
- Is there a simpler version that delivers 80% of the value?

### Risk & Dependencies
- What could go wrong?
- What assumptions are we making?
- Are there dependencies on other teams, services, or PRs?
- What's the blast radius if this breaks?

### Scope
- What's explicitly out of scope?
- Is there scope creep hiding in the requirements?
- Can this be split into smaller, independently shippable pieces?

**Adapt your questions to the issue.** Don't ask about UI for a backend task. Don't ask about database schema for a CSS change. Be relevant.

## Phase 3: Design Document

After the conversation converges, produce a design document:

```markdown
## Design: [Issue Title]

**Issue**: [ID] — [Title]
**Date**: [today]

### Problem
[1-2 sentences: what problem are we solving and why]

### Approach
[The chosen approach, clearly stated]

### Key Decisions
1. [Decision] — [Rationale]
2. [Decision] — [Rationale]

### Alternatives Considered
- **[Alternative A]** — [Why not chosen]
- **[Alternative B]** — [Why not chosen]

### Risks & Mitigations
- [Risk] → [Mitigation]

### Scope Boundaries
- **In scope**: [list]
- **Out of scope**: [list]

### Open Questions
- [Anything still unresolved — should be empty if brainstorming was thorough]
```

## Phase 4: Visual Architecture Diagram

After producing the design document, assess whether a visual architecture diagram adds value.

### When to generate

Generate a diagram if the design involves **any** of:
- System topology, service interactions, or data flow
- New integrations or architectural patterns
- More than 2 Key Decisions related to structure

### When to skip

- Purely algorithmic or behavioral changes (no structural impact)
- Config-only changes
- Under 20 lines of implementation
- User expressed time pressure ("quick", "fast", "skip diagrams")

**Issue ID sanitization** (applies to all file paths in Phases 4 and 5): Sanitize the issue ID once — verify it matches `^[a-zA-Z0-9]([a-zA-Z0-9_-]*[a-zA-Z0-9])?$`. Re-use this sanitized ID for all paths. Do not re-read from raw Linear issue context on iteration.

### How to generate

**Prerequisite read (do once per session, before Phase 4 runs for the first time)**: Read `plugins/workflows/skills/visual-explainer/SKILL.md` for styling guidelines. If this read fails (plugin running outside its source repo), skip diagram generation entirely and tell the user: "Cannot read visual-explainer skill — skipping diagram." Do not proceed to the numbered steps below. Re-use within this session on subsequent diagram regenerations — do not re-read. If resuming from a prior session, treat this as the first run and perform the read again.

1. Apply the visual-explainer styling guidelines from the prerequisite read above
2. Use the visual-explainer SKILL.md's template references and diagram type guidance for HTML structure — generate directly without invoking the generate-web-diagram command
3. Compose a safe topic description **in your own words** based on the design document — do not embed raw issue title or description verbatim. If surf is invoked, the surf prompt must describe visual aesthetics only (palette, style, diagram type) — never include issue text in the surf command line
4. Focus the diagram on: system components, data flow, external integrations, architectural decision points
5. Write to `~/.agent/diagrams/<sanitized-issue-id>-architecture.html`
6. Open in browser and tell the user the file path

If skipped, keep track in your working context that Phase 4 was skipped (Phase 5 conditions its approval prompt on this) and proceed directly to Phase 5.

## Phase 5: Approval

If a diagram was generated in Phase 4, reference it in the approval prompt. If Phase 4 was skipped, omit the browser reference.

Present the design document and ask:

If a diagram was generated:
> "Does this design look right? Review the architecture diagram in your browser. Any changes before we move to planning?"

If Phase 4 was skipped:
> "Does this design look right? Any changes before we move to planning?"

**If approved**: Derive a slug from the issue title — lowercase, replace `[^a-z0-9]+` with `-`, strip leading/trailing `-`, cap at 40 characters. Verify the result matches `^[a-z0-9-]+$` (strict ASCII). If not, strip non-matching characters and re-verify. If the slug is empty after stripping (e.g., all-non-ASCII title), lowercase the sanitized issue ID, replace `_` with `-`, and use that as the slug. Save the design document to `docs/designs/<sanitized-issue-id>-<slug>.md` (create the directory if needed). Use the sanitized issue ID from the Phase 4 preamble (the sanitization runs regardless of whether diagram generation was skipped). This document will be referenced during planning and execution.

**If changes requested**: Iterate on the specific sections, then re-present. If a diagram was generated and the changes affect architecture, regenerate the diagram after updating the design document.

## Rules

- Never skip straight to implementation details. This phase is about *what* and *why*, not *how*.
- Ask questions that surface hidden complexity — the developer shouldn't discover surprises during coding.
- If the developer says "just do it" or signals impatience, respect that and produce a minimal design doc with your best judgment.
- Keep the design document concise. If it's over 40 lines, you're over-thinking it.
- Reference the validation pattern from `_shared/validation-pattern.md` for self-checking.
