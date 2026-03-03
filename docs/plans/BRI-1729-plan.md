# BRI-1729: Port visual-explainer skill and templates

## Overview

Port the [visual-explainer](https://github.com/nicobailon/visual-explainer) skill (MIT) into `plugins/workflows/skills/visual-explainer/`. This adds visual HTML output capabilities (diagrams, architecture overviews, data tables, slide decks) to the workflows plugin.

## Tasks

### Task 1: Create directory structure

**Files:** `plugins/workflows/skills/visual-explainer/`, `templates/`, `references/`

**Steps:**
1. Create `plugins/workflows/skills/visual-explainer/`
2. Create `plugins/workflows/skills/visual-explainer/templates/`
3. Create `plugins/workflows/skills/visual-explainer/references/`

**Verify:** Directories exist.

---

### Task 2: Port SKILL.md with adapted frontmatter

**File:** `plugins/workflows/skills/visual-explainer/SKILL.md`

**Steps:**
1. Fetch upstream SKILL.md from `https://github.com/nicobailon/visual-explainer`
2. Replace frontmatter with our standard:
   ```yaml
   ---
   name: visual-explainer
   description: Generate beautiful, self-contained HTML pages that visually explain systems, code changes, plans, and data. Use when the user asks for a diagram, architecture overview, diff review, plan review, project recap, comparison table, or any visual explanation of technical concepts. Also use proactively when about to render a complex ASCII table (4+ rows or 3+ columns) — present it as a styled HTML page instead.
   user-invocable: true
   license: MIT
   metadata:
     author: nicobailon
     version: "0.4.4"
   ---
   ```
3. Keep all skill body content as-is (workflow phases, anti-patterns, quality checks, diagram types)

**Verify:** `name` matches directory name `visual-explainer`. Frontmatter passes validation.

---

### Task 3: Port 4 HTML templates

**Files:**
- `plugins/workflows/skills/visual-explainer/templates/architecture.html`
- `plugins/workflows/skills/visual-explainer/templates/data-table.html`
- `plugins/workflows/skills/visual-explainer/templates/mermaid-flowchart.html`
- `plugins/workflows/skills/visual-explainer/templates/slide-deck.html`

**Steps:**
1. Fetch each template from upstream repo
2. Write as-is to `templates/` subdirectory (no modifications)

**Verify:** All 4 files exist and are valid HTML.

---

### Task 4: Port 4 reference docs

**Files:**
- `plugins/workflows/skills/visual-explainer/references/css-patterns.md`
- `plugins/workflows/skills/visual-explainer/references/libraries.md`
- `plugins/workflows/skills/visual-explainer/references/responsive-nav.md`
- `plugins/workflows/skills/visual-explainer/references/slide-patterns.md`

**Steps:**
1. Fetch each reference from upstream repo
2. Write as-is to `references/` subdirectory (no modifications)

**Verify:** All 4 files exist.

---

### Task 5: Update CLAUDE.md skill routing

**File:** `CLAUDE.md`

**Steps:**
1. Add `visual-explainer` to the Design Skills table in the Skill Routing section:
   ```
   | `visual-explainer` | "diagram", "architecture overview", "visual explanation", complex tables | Generate styled HTML pages |
   ```

**Verify:** CLAUDE.md has the new entry.

---

### Task 6: Version bump

**Files:**
- `plugins/workflows/.claude-plugin/plugin.json` — bump `3.10.0` → `3.11.0`
- `.claude-plugin/marketplace.json` — bump version if present

**Verify:** Versions match.

---

### Task 7: Run validation

**Steps:**
1. Run `scripts/validate.sh`
2. Fix any issues found

**Verify:** Validation passes with 0 errors.

---

## Out of Scope

- Commands/prompts (7 files) — that's BRI-1730
- Brite-specific customization — separate effort per issue notes
- surf-cli integration — optional dependency, document but don't require
