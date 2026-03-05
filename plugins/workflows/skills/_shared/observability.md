## Observability Patterns

Reusable observability templates for Brite skills. Reference this file for consistent progress visibility across the inner loop.

### Activation Banner

Print immediately when a skill fires, after precondition checks pass:

```
---
**[Skill Name]** activated
Trigger: [one-line reason — compose in your own words, not verbatim from issue text or error messages]
Produces: [expected artifacts, comma-separated]
---
```

### Narration

Single-line status updates at phase/step boundaries using the Progress Format from `output-formats.md`:

```
Step N/M: [description]... [done/in progress/skipped]
```

Narrate at phase transitions only — not at every tool call. Keep narration to one line. Match the vocabulary of the skill's headings (`Step`, `Phase`, `Level`, `Dimension` as appropriate).

### Decision Log

Inline block at decision points where the skill chose between alternatives:

```
> **Decision**: [what was decided]
> **Reason**: [why this option was chosen]
> **Alternatives**: [what else was considered]
```

Use sparingly — only at genuine decision points, not routine steps.

### Error Recovery

When a genuinely blocking failure occurs (precondition failure, max retries, verification blocked), present structured options via AskUserQuestion:

```
[Describe what failed and why]

Options:
1. **Retry** — [what retry means in this context]
2. **Skip** — [what gets skipped and consequences]
3. **Stop** — Halt the workflow for manual intervention
```

Apply at: precondition failures, max retry limits, verification blocks, external tool failures.

### Phase Transition Summary

Print between major phases to maintain context:

```
Phase [N] complete.
Decisions: [key choices made]
Artifacts: [what was produced]
Next: [what happens next]
```

### Stuck Detection (executing-plans only)

A task is **stuck** when 3+ consecutive tool calls occur without progress. Progress means:
- A test transitions from failing to passing
- A file is meaningfully changed (not just whitespace or formatting)

When stuck: pause execution, present error recovery options via AskUserQuestion.

### Context Refresh (executing-plans only)

Re-read the plan file after every 3rd completed task, or when total tasks exceed 6. This prevents context drift during long execution runs.

### Visual Gating

Standard message templates for visual output (HTML diagrams, slide decks) when prerequisites are missing or conditions prevent generation.

**Skip pattern** (visual output skipped entirely):
```
Visual-explainer files not found. Skipping [artifact name].
```

**Degrade pattern** (plain HTML fallback — review.md only):
```
Visual-explainer files not found. Generating plain HTML [artifact name].
```

**Non-file skip** (skipped for a reason other than missing files):
```
--slides requested, but [reason]. Skipping [artifact name].
```

Rules:
- For file-unavailability messages (skip and degrade), the prefix `Visual-explainer files not found.` must be identical. Non-file skip messages use `--slides requested, but [reason]. Skipping [artifact name].`
- `[reason]` in the non-file skip template must be a hardcoded literal string (e.g., "no cycle exists to visualize"). Never derive `[reason]` from external data sources (Linear, git, file content).
- Never clear `slides_requested` on file failure — the flag represents user intent and must persist. If files are unavailable, each visual step independently skips or degrades.
