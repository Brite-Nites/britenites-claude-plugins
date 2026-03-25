# Instruction Coherence Audit Methodology

**Issue:** BC-2459
**Consumes:** Arbiter (arxiv 2603.08993v1), ALICE (Springer), Contradish, IFScale, Anthropic docs, gstack analysis
**Consumed by:** BC-2461 (Instruction coherence audit)
**Date:** 2026-03-25

---

## 1. Instruction Defect Taxonomy

Five defect types, each with definition, detection strategy, and Brite-specific examples.

### 1.1 Default Behavior

**Definition:** Instructions that tell Claude to do what it already does natively. These waste context tokens and dilute important rules. Every unnecessary instruction degrades follow-through on the instructions that matter (IFScale research: frontier LLMs reliably follow ~150-200 instructions; performance degrades uniformly across all instructions as count increases).

**Detection strategy:** Manual + LLM-as-judge. For each instruction, ask: "Would Claude do this without being told?" Score on a 3-point scale: definitely-default (remove), probably-default (flag for review), not-default (keep).

**Examples to check in Brite:**
- "Use named exports" -- Claude defaults to named exports in TypeScript
- "Keep components small and composable" -- Claude's default style
- Conventions that repeat standard Next.js/React patterns
- Instructions that restate Claude Code's built-in behaviors (tool safety, file reading before editing)

**Automated assist:** Extract all imperative instructions. Send each to Claude in a clean context (no CLAUDE.md loaded): "Would you do this by default when writing code? Answer: definitely / probably / no." Batch 50 at a time. Cost: ~$0.10 per full audit.

### 1.2 Conflicts

**Definition:** Two rules that cannot both be followed simultaneously. The agent that resolves the conflict cannot be the agent that detects it -- an LLM executing contradictory instructions smooths over inconsistencies silently (Arbiter, 2026). External evaluation is required.

**Sub-types (from Arbiter's interference taxonomy):**
- **Mandate-Prohibition:** Direct contradictions where instructions mutually exclude each other (e.g., "always X" in file A vs "never X" in file B)
- **Priority Marker Ambiguity:** Multiple authority sources without specified resolution order (e.g., "IMPORTANT:" in two files giving opposite guidance on the same topic)
- **Implicit Dependencies:** Unresolved interactions across sections creating "dead zones" where behavior is undefined

**Detection strategy:** Primarily static (Arbiter found 95% of interference is statically detectable).
1. Decompose all files into typed blocks (mandate, prohibition, guidance, information)
2. Tag each block with scope (what topics/tools it governs)
3. Pairwise comparison of blocks with overlapping scope
4. Flag mandate-prohibition pairs, priority ambiguity, and implicit dependencies

**Examples to check in Brite:**
- Commands that reference skills by behavior vs. SKILL.md that defines different behavior
- Routing table entries in CLAUDE.md vs. actual SKILL.md description triggers
- Review agent configuration in CLAUDE.md vs. review.md command instructions
- Shared patterns (verification steps, Linear integration) that may have drifted between files

**Key risk area:** Cross-references. Every time a command references a skill or vice versa, both sides must agree on the interface. This is the #1 class of bug in a distributed instruction architecture.

### 1.3 Redundancy

**Definition:** The same instruction restated in multiple places, sometimes with subtle differences. Redundancy creates three problems: (1) context waste, (2) maintenance burden (updating one copy but not others), and (3) subtle drift where copies diverge over time.

**Sub-types:**
- **Verbatim Duplication:** Identical text in multiple files
- **Scope Overlap:** Same behavioral constraint restated in 2-3 locations with different wording, potentially creating subtle semantic differences

**Detection strategy:** Hybrid static + LLM.
- **Static:** Structural hashing of instruction blocks for exact/near-duplicate detection. Fuzzy match (cosine similarity on sentence embeddings) for semantic duplicates.
- **LLM:** For flagged near-duplicates, ask: "Do these two instructions say the same thing? If not, how do they differ?"

**Examples to check in Brite:**
- `_shared/observability.md` patterns vs. individual SKILL.md verification sections
- Plugin.json schema rules in CLAUDE.md vs. validate.sh enforcement
- Step-numbering conventions that may be restated in multiple skills
- Linear integration patterns repeated across commands

### 1.4 One-Off Fix

**Definition:** Instructions added to fix one specific bad output, not a general improvement. These accumulate over time as "scar tissue" -- each individually reasonable, but collectively they bloat the instruction file with overly specific rules that may no longer apply.

**Detection strategy:** Manual review with git-blame assist. For each instruction:
1. `git blame` to find when it was added
2. Check the commit message / PR for context: was it a reaction to a specific bad output?
3. Ask: "Is this rule general enough to keep? Or was it a patch for one incident?"

**Indicators of one-off fixes:**
- Very specific instructions ("when generating X, make sure to Y")
- Instructions that reference specific incidents or conversations
- Rules added in the same commit as a bug fix
- Instructions that address symptoms rather than root causes

**Examples to check in Brite:**
- Known Issues section entries that may have been resolved upstream
- Specific tool-routing instructions that were added after a bad agent interaction
- Warnings about specific MCP tool behaviors

### 1.5 Vagueness

**Definition:** Instructions that can be interpreted differently each invocation. These create non-deterministic behavior -- the agent may comply differently depending on context, leading to inconsistent outputs across sessions.

**Detection strategy:** LLM-as-judge. For each instruction, ask: "Generate 3 different reasonable interpretations of this instruction. Are they materially different?"

**Indicators of vagueness:**
- Subjective qualifiers: "appropriate", "reasonable", "when needed", "as necessary"
- Conditional without clear trigger: "consider doing X" (when? under what conditions?)
- Comparative without baseline: "prefer X over Y" (how strong is the preference? are there exceptions?)
- Scope ambiguity: "keep things simple" (what counts as simple?)

**gstack pattern (imperative over conditional):**
- Vague: "Consider bisecting commits when debugging"
- Clear: "Always bisect commits when an E2E eval fails"
- Vague: "Prefer the browse binary over MCP tools"
- Clear: "NEVER use `mcp__claude-in-chrome__*` tools. Use the browse binary."

**Examples to check in Brite:**
- "Tech-stack skills belong in separate plugins" -- what counts as a tech-stack skill?
- "Use context7 MCP for framework docs" -- when exactly? every time a framework is mentioned?
- Any instruction using "when appropriate", "if needed", "as necessary"

---

## 2. gstack CLAUDE.md Patterns

Analysis of gstack (garrytan/gstack) -- 309 lines, 17 flat H2 sections, 26 skills.

### Structure

gstack's CLAUDE.md is 309 lines organized as 17 H2 sections with no H3 nesting. Average 18 lines/section, largest section 51 lines. No section exceeds ~50 lines. This is a deliberate constraint.

**Section categories:**
| Category | Lines | % | Examples |
|----------|-------|---|---------|
| Dev workflow commands | 53 | 17% | Build/test/run commands, test tiers |
| Orientation / map | 57 | 18% | Project structure, local plans |
| Contribution conventions | 34 | 11% | SKILL.md workflow, template rules |
| Behavioral rules | 62 | 20% | Platform-agnostic design, effort compression |
| Guard rails / safety | 38 | 12% | Compiled binaries, symlink hazards |
| Release process | 46 | 15% | Commit style, changelog conventions |

### Five Conflict Avoidance Patterns

**Pattern 1: Single Concern Per Section.** Every H2 section addresses exactly one topic. Zero cross-references between sections. "Commit style" never mentions testing. Each section readable in isolation. Cost: some repetition, but repetition is safer than cross-referencing.

**Pattern 2: Separate the Audience.** Hard boundary between CLAUDE.md (contributor instructions -- how to develop gstack) and SKILL.md (runtime behavior -- how to behave when executing as a tool). Zero overlap. This is the single most important conflict avoidance mechanism.

**Pattern 3: Generated, Not Written.** All SKILL.md files generated from `.tmpl` templates via `bun run gen:skill-docs`. Shared behavioral instructions (preamble, AskUserQuestion format, completeness principle, telemetry) defined once in `gen-skill-docs.ts`, injected into every skill. Structurally impossible for two skills to have conflicting versions of the same behavioral rule.

**Pattern 4: Flat Hierarchy, No Precedence Rules.** Zero precedence rules. No "this section overrides that section." Instead, avoids the need for precedence by ensuring sections never address the same concern. Precedence rules are themselves a source of ambiguity.

**Pattern 5: Imperative, Not Conditional.** Instructions stated as absolutes: "NEVER commit browse/dist/" not "avoid committing browse/dist/ unless...". Very few conditional instructions. Those that exist use explicit if/then: "If `PROACTIVE` is `false`, do not proactively suggest."

### Comparison: gstack (Centralized) vs Brite (Distributed)

| Dimension | gstack | Brite |
|-----------|--------|-------|
| CLAUDE.md | 309 lines | 237 lines |
| Skill instructions | ~662 lines (generated) | 4,307 lines (23 files) |
| Command instructions | 0 (skills only) | 4,527 lines (21 files) |
| Total instruction surface | ~1,000 effective | ~9,071 |
| Shared behavior mechanism | Code generation (templates) | Convention (`_shared/`, copy-paste) |
| Cross-references | Zero | Moderate (commands <-> skills) |
| Routing | Implicit (SKILL.md description) | Explicit (routing table in CLAUDE.md) |

### Takeaways for Brite

1. **Audit for audience confusion.** Brite's CLAUDE.md mixes contributor instructions (Adding New Commands, plugin.json Schema) and runtime routing (Skill Routing, Review Agents). Classify each section by audience.
2. **Map all cross-references.** Every command->skill and skill->command reference must agree on the interface. This is the #1 drift class gstack avoids by design.
3. **Check for conditional vs imperative language.** Convert ambiguous conditionals to imperatives where possible.
4. **Consider code-generating shared preambles.** If multiple skills share verification patterns, Linear integration, or step conventions, a template pipeline eliminates drift permanently. (This is BC-2466's scope, not this audit's.)
5. **The routing table is a strength.** Keep it, but verify it stays in sync with SKILL.md trigger descriptions.

---

## 3. Automated Detection Strategies

Based on Arbiter's finding that 95% of instruction interference is statically detectable, and ALICE's finding that hybrid formal+LLM achieves 72% accuracy vs 47% for LLM-only.

### Detection Pipeline (3 tiers)

#### Tier 1: Deterministic (scripts, zero LLM cost)

| Check | Method | Catches |
|-------|--------|---------|
| **Verbatim duplication** | Structural hash of normalized text blocks | Exact copies across files |
| **Near-duplicate detection** | Levenshtein distance on instruction sentences | Copy-paste with minor edits |
| **Line count audit** | Count lines per file | Files exceeding 200-line Anthropic guidance |
| **Instruction count** | Extract imperative sentences, count total | Exceeding 150-instruction capacity (IFScale) |
| **Cross-reference integrity** | Parse skill/command references, verify targets exist | Broken references, renamed skills |
| **Frontmatter compliance** | Validate SKILL.md frontmatter against schema | Missing fields, name mismatches |
| **Routing table sync** | Compare CLAUDE.md routing table entries to SKILL.md descriptions | Stale routing entries |

**Existing coverage:** `scripts/validate.sh` already covers frontmatter compliance, name-to-directory matching, and some cross-reference checks. Extend, don't replace.

#### Tier 2: LLM-as-Judge (targeted, low cost)

| Check | Method | Catches |
|-------|--------|---------|
| **Semantic duplicate detection** | Embed instruction blocks, cluster by cosine similarity >0.85, LLM confirms | Redundant rules with different wording |
| **Default behavior identification** | Ask Claude per-instruction: "Would you do this without being told?" | Wasted context tokens |
| **Vagueness scoring** | Ask Claude: "Generate 3 interpretations. Do they differ materially?" | Ambiguous instructions |
| **Conflict detection** | For pairs with overlapping scope: "Can both rules be followed simultaneously?" | Mandate-prohibition conflicts |

**Cost estimate:** ~$0.30-0.50 for full corpus (based on Arbiter's $0.27 for cross-vendor analysis).

#### Tier 3: Multi-Model Scouring (broad, cheap insurance)

Send the full instruction corpus to 3-4 different LLMs with open-ended prompts: "Read these instructions carefully. What stands out as unusual, contradictory, or problematic?"

**Why multiple models:** Different LLMs bring categorically different analytical perspectives (Arbiter finding). Claude Opus spots structural contradictions. Other models spot resource exploitation, data integrity issues, impossible instructions. "The categories don't converge; the coverage does."

**Convergent termination:** Three consecutive models declining to surface new issues = done.

**Cost:** ~$0.30 total.

### Detection Script Sketches

**Duplicate detector (Tier 1):**
```
1. For each .md file in skills/ and commands/:
   a. Extract imperative sentences (start with verb, contain "must"/"should"/"never"/"always")
   b. Normalize: lowercase, remove articles, collapse whitespace
   c. Hash each sentence
2. Group by hash → exact duplicates
3. For non-exact: compute Levenshtein distance between all pairs
4. Flag pairs with distance < 15% of shorter string length → near-duplicates
5. Output: CSV with file1, line1, file2, line2, similarity score
```

**Cross-reference checker (Tier 1):**
```
1. Parse all files for patterns: `skill activates`, `triggers`, references to other skill/command names
2. Build a directed graph: file → references → file
3. For each edge, verify target file exists
4. For skill references, verify SKILL.md description matches the claimed trigger
5. Output: broken references, stale entries, bidirectional consistency failures
```

**Default behavior scorer (Tier 2):**
```
1. Extract all imperative instructions (same as duplicate detector step 1a)
2. Batch into groups of 50
3. For each batch, send to Claude:
   "For each instruction below, score:
    3 = I would definitely do this without being told
    2 = I would probably do this without being told
    1 = I would NOT do this without being told
    [instructions]"
4. Flag all score-3 instructions for removal review
5. Output: scored CSV with instruction, file, line, score, reasoning
```

### What Cannot Be Automated

- **One-off fix detection:** Requires git-blame context + human judgment about whether a rule is general or incident-specific. LLMs can assist but cannot determine intent.
- **Audience classification:** Whether a section is "contributor instruction" vs "runtime behavior" requires understanding the plugin system's execution model. LLM can suggest, human must decide.
- **Priority decisions:** When a conflict is found, deciding which rule to keep requires product/architecture judgment.

---

## 4. Audit Checklist

Step-by-step process for BC-2461 to follow. Ordered by yield (highest-value checks first).

### Phase 1: Inventory (30 min)

- [ ] **1.1** Generate complete file inventory with line counts
  - CLAUDE.md, all SKILL.md files, all command .md files, _shared/ templates, hooks.json, trigger-registry.json
  - Record total instruction surface area
- [ ] **1.2** Extract all imperative instructions into a flat list
  - One row per instruction: file, line number, text, category (mandate/prohibition/guidance/information)
  - Estimated ~300-500 instructions across 47+ files
- [ ] **1.3** Tag each instruction with scope (what topics/tools it governs)
  - Use keywords: git, testing, Linear, skills, commands, hooks, review, security, etc.

### Phase 2: Deterministic Checks (1 hour)

- [ ] **2.1** Run `scripts/validate.sh` -- baseline structural validation
- [ ] **2.2** Check line counts: flag files exceeding 200 lines
- [ ] **2.3** Check total instruction count: flag if >150 extractable instructions
- [ ] **2.4** Run duplicate detection (exact hash + Levenshtein)
- [ ] **2.5** Run cross-reference integrity check
  - Every command->skill reference: does the skill exist? does the SKILL.md description match?
  - Every CLAUDE.md routing table entry: does the skill exist? triggers accurate?
- [ ] **2.6** Verify frontmatter compliance across all SKILL.md files

### Phase 3: LLM-Assisted Analysis (1 hour)

- [ ] **3.1** Default behavior scan: score all extracted instructions (3/2/1)
  - Triage: remove score-3, flag score-2 for human review, keep score-1
- [ ] **3.2** Vagueness scan: identify instructions with subjective qualifiers
  - For each: generate 3 interpretations, assess material difference
  - Propose imperative rewrites for vague instructions
- [ ] **3.3** Conflict detection: for instruction pairs with overlapping scope
  - Can both be followed simultaneously? If not, which takes precedence?
  - Classify: mandate-prohibition, priority ambiguity, or implicit dependency
- [ ] **3.4** Semantic duplicate detection: cluster similar instructions
  - For each cluster: keep one canonical version, mark others as redundant

### Phase 4: Structural Review (30 min)

- [ ] **4.1** Audience classification: for each CLAUDE.md section
  - Is it a contributor instruction or runtime behavior? Flag mixed sections.
- [ ] **4.2** Single concern audit: does each section address exactly one topic?
  - Flag sections with cross-references or multiple concerns
- [ ] **4.3** Conditional language audit: identify "consider", "prefer", "when appropriate"
  - Propose imperative rewrites for each
- [ ] **4.4** One-off fix scan: git-blame instructions added in bug-fix commits
  - For each: is the rule general enough to keep?

### Phase 5: Report (30 min)

- [ ] **5.1** Compile findings into structured report
  - Per finding: file, line, defect type, severity (curious/notable/concerning/alarming), recommendation
- [ ] **5.2** Compute summary metrics
  - Total instructions, default-behavior count, conflict count, redundancy count, vague count, one-off count
  - Estimated token savings from recommended removals
- [ ] **5.3** Produce actionable cut list
  - Instructions to remove (default behavior, redundancy)
  - Instructions to rewrite (vagueness, conflicts)
  - Instructions to relocate (audience confusion)
  - Structural changes (section splitting, cross-reference cleanup)

**Estimated total audit time:** 3-4 hours for a ~10,000-line corpus.

---

## 5. Top 10 Instruction Anti-Patterns

Drawn from research + Brite codebase observations. Ordered by impact.

### 1. The Bloated CLAUDE.md
**Pattern:** CLAUDE.md grows past 200 lines as instructions accumulate over time.
**Impact:** Anthropic explicitly warns: "If your CLAUDE.md is too long, Claude ignores half of it because important rules get lost in the noise." IFScale research confirms performance degrades uniformly across all instructions as count increases.
**Fix:** Extract to `docs/`, `_shared/`, or skill-specific files. Use `@import` for on-demand loading.

### 2. The Silent Contradiction
**Pattern:** Two files give opposite guidance on the same topic, but neither file references the other. Claude picks one arbitrarily per session, creating non-deterministic behavior.
**Impact:** Arbiter found 4 critical direct contradictions in Claude Code's own 1,490-line system prompt. In Brite's 9,071-line distributed corpus, the probability is higher.
**Fix:** Pairwise scope comparison during audit. Designate one authoritative source per topic.

### 3. The Drifted Copy
**Pattern:** A shared pattern (verification steps, Linear integration, step numbering) is copy-pasted into multiple skills/commands. Over time, copies diverge as individual files are updated.
**Impact:** Creates subtle inconsistencies where the same concept works slightly differently depending on which skill is active.
**Fix:** Extract to `_shared/` templates or code-generate from a single source (gstack pattern). The audit should diff shared patterns across all files.

### 4. The Stating-the-Obvious Rule
**Pattern:** Instructions that tell Claude to do what it already does by default. "Use TypeScript strict mode." "Read files before editing."
**Impact:** Each obvious instruction consumes context budget that could be used for genuinely novel guidance. With a ~150-instruction effective capacity, wasting 20% on defaults means 30 fewer meaningful rules.
**Fix:** Default behavior scan (Section 3, Tier 2). Remove instructions scored as "definitely default."

### 5. The Vague Directive
**Pattern:** Instructions using subjective qualifiers: "keep things simple", "when appropriate", "be concise". Different interpretations across sessions.
**Impact:** Non-deterministic behavior. The user gets inconsistent results and can't understand why.
**Fix:** Convert to imperatives with explicit thresholds. "Keep things simple" -> "Components must not exceed 100 lines." "When appropriate" -> "When the file has more than 3 functions."

### 6. The Scar Tissue Rule
**Pattern:** An instruction added to fix one specific bad output. "Don't add emojis to commit messages." "Always check if the directory exists before creating files." These are individually reasonable but accumulate.
**Impact:** Over months, the instruction file becomes a graveyard of incident responses that may no longer be relevant. Each scar-tissue rule reduces the budget for proactive guidance.
**Fix:** Git-blame audit. For each instruction, check if it was added in response to a specific incident. If so, ask: is this still relevant? Is there a more general form?

### 7. The Unresolvable Precedence
**Pattern:** Two instructions both claim authority ("IMPORTANT:", "CRITICAL:", "MUST") and give different guidance. No explicit precedence rule exists.
**Impact:** Claude biases toward instructions at the peripheries of the prompt (IFScale finding). The "winner" depends on position, not importance.
**Fix:** Establish a clear precedence hierarchy. In Brite: CLAUDE.md > SKILL.md > command .md. Within a file: explicit precedence markers or section ordering. Avoid multiple "IMPORTANT" markers on the same topic.

### 8. The Cross-Reference Rot
**Pattern:** Command A says "the brainstorming skill will activate." The brainstorming skill was renamed or its trigger conditions changed. Command A's reference is now stale.
**Impact:** The agent attempts to activate a skill that doesn't match the described behavior, or worse, the reference silently points to nothing.
**Fix:** Automated cross-reference integrity check (Section 3, Tier 1). Run on every PR.

### 9. The Audience-Confused Section
**Pattern:** A single section mixes contributor instructions (how to add skills) with runtime behavior (when skills activate). The LLM processes both as equally authoritative runtime guidance.
**Impact:** Claude may treat contributor documentation as behavioral rules. "Skills must follow this frontmatter schema" becomes "I must validate frontmatter schema on every invocation."
**Fix:** Classify each section by audience. Separate contributor docs from runtime instructions. Move contributor docs to README or a dedicated contributors guide.

### 10. The Leverage Amplifier
**Pattern:** A small instruction error in CLAUDE.md cascades through every phase of the workflow because CLAUDE.md is loaded in every session.
**Impact:** "A bad code line impacts one artifact. A bad instruction in CLAUDE.md cascades across every phase of the workflow, affecting all subsequent artifacts -- amplifying harm exponentially." (HumanLayer)
**Fix:** Weight audit severity by file scope. A conflict in CLAUDE.md is more severe than a conflict in a single SKILL.md. Prioritize CLAUDE.md review first.

---

## Sources

- [Arbiter: Detecting Interference in LLM Agent System Prompts](https://arxiv.org/html/2603.08993v1) (March 2026) -- primary methodology reference
- [ALICE: Automated Logic for Identifying Contradictions in Engineering](https://link.springer.com/article/10.1007/s10515-024-00452-x) -- hybrid formal+LLM, 72% accuracy
- [Contradish](https://www.contradish.com/) -- behavioral output consistency testing
- [ContraDoc: Self-Contradictions in Documents](https://aclanthology.org/2024.naacl-long.362/) -- human-annotated contradiction dataset
- [IFScale: How Many Instructions Can LLMs Follow?](https://arxiv.org/pdf/2507.11538) -- instruction capacity research, ~150-200 limit
- [GPTLint](https://gptlint.dev/) -- two-pass LLM linting architecture
- [KnowledgeBase Guardian](https://github.com/datarootsio/knowledgebase_guardian) -- vector similarity contradiction detection
- [Promptfoo](https://github.com/promptfoo/promptfoo) -- declarative prompt evaluation with LLM-as-judge
- [Best Practices for Claude Code](https://code.claude.com/docs/en/best-practices) -- Anthropic official guidance
- [How Claude Remembers Your Project](https://code.claude.com/docs/en/memory) -- CLAUDE.md sizing, <200 lines
- [Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md) -- leverage hierarchy warning
- [gstack](https://github.com/garrytan/gstack) -- 309-line CLAUDE.md, 5 conflict avoidance patterns
