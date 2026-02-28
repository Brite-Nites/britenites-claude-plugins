# Plugin Best Practices Audit — Brite Claude Plugins

## Context

Compared the full brite-claude-plugins codebase against the official Claude Code plugin reference docs (plugins-reference, plugins, plugin-marketplaces, skills, sub-agents). The goal is to identify deviations from best practices and spec compliance issues.

---

## COMPLIANT (things done correctly)

1. **Plugin manifest location** — `.claude-plugin/plugin.json` at plugin root, not mixed with components
2. **Marketplace required fields** — `name`, `owner.name`, `plugins` array with `name` + `source` all present
3. **Relative paths use `./` prefix** — All paths in plugin.json start with `./`
4. **Skills directory structure** — All 10 skills use `skills/<name>/SKILL.md` convention; `name` matches directory name
5. **Commands have `description` frontmatter** — All 7 command files have valid frontmatter
6. **Hook events are valid** — Uses `PreToolUse`, `PostToolUse`, `SessionStart` which are all documented events
7. **Hook types are valid** — Uses `prompt` and `command` types, both documented
8. **Agent frontmatter** — `name`, `description`, `model`, `tools` are ALL documented fields per the sub-agents reference
9. **Skill frontmatter `agent` and `context`** — Both are documented fields per the skills reference (`context: fork` runs in forked subagent, `agent` specifies which subagent type)
10. **Skill `user-invocable` usage** — Correctly marks orchestrator sub-skills as `user-invocable: false` and user-facing skills as `true`
11. **Supporting files pattern** — `agent-browser` has `references/` directory, `react-best-practices` has `AGENTS.md`, `setup-claude-md` has `claude-code-best-practices.md` — all valid per docs
12. **Shared utilities in `_shared/`** — Valid pattern for reusable content

---

## ISSUES (deviations that may cause problems)

### 1. ~~`pluginRoot` + `source` may cause double-pathing~~ RESOLVED
**Files:** `.claude-plugin/marketplace.json`

**Resolution:** `pluginRoot` removed from marketplace.json metadata. Source path `./plugins/workflows` is the full relative path. Fixed in v2.0.0.

### 2. ~~`agents/` directory not declared in plugin.json~~ RESOLVED
**Files:** `plugins/workflows/.claude-plugin/plugin.json`

**Resolution:** Added `"agents": "./agents/"` to plugin.json. 7 agents now declared and discoverable. Fixed in v2.0.0.

### 3. ~~`argument-hint` is nested under `metadata` instead of being top-level~~ RESOLVED
**Files:** `plugins/workflows/skills/web-design-guidelines/SKILL.md`

**Resolution:** `argument-hint` is already at top-level in the current file. Verified in v2.0.0.

### 4. ~~MCP tool names in skills/agents may not match plugin-namespaced names~~ RESOLVED
**Files:** All agent `.md` files, skills with `allowed-tools`

**Resolution:** Updated all 4 agents and 4 skills to use plugin-namespaced format (`mcp__plugin_britenites_sequential-thinking__sequentialthinking`, `mcp__plugin_britenites_linear-server__*`). Fixed in v2.0.0.

### 5. ~~`allowed-tools` format inconsistency (YAML array vs comma-separated string)~~ RESOLVED
**Files:** Multiple SKILL.md files

**Resolution:** All skills now use comma-separated strings for `allowed-tools` per docs spec. Fixed in v2.0.0.

---

## WARNINGS (works but doesn't follow best practice)

### 1. Version set in plugin.json instead of marketplace.json
**Files:** `plugins/workflows/.claude-plugin/plugin.json`
**Reference:** Plugin marketplaces docs — "For relative-path plugins, set version in marketplace entry"

Version `1.5.0` is in plugin.json. For relative-path plugins (which this is), the docs recommend setting version in the marketplace entry instead. If someone later adds a version to marketplace.json, plugin.json silently wins, causing confusion.

### 2. `commands/` directory is legacy
**Reference:** Skills docs — "Custom slash commands have been merged into skills. Your existing `.claude/commands/` files keep working."
**Reference:** Plugins reference — "commands/: Skill Markdown files (legacy; use `skills/` for new skills)"

The 4 commands still work but are on a deprecated path. New content should use `skills/` format. Migration isn't urgent since the docs explicitly say commands keep working.

### 3. CI workflow over-validates plugin.json
**Files:** `.github/workflows/validate-plugin.yml`
**Reference:** Plugins reference — "`name` is the only required field" in plugin.json

CI checks for `name`, `description`, `version`, AND `author` as required. This is stricter than the spec (only `name` is required). Fine as an internal policy, but worth documenting that it's intentional.

### 4. ~~No `LICENSE` file at plugin root~~ RESOLVED

LICENSE file exists at `plugins/workflows/LICENSE`.

---

## RECOMMENDATIONS (prioritized)

### P0 — ~~Test and fix immediately~~ ALL RESOLVED
1. ~~**Fix `pluginRoot`/`source` interaction**~~ — Resolved: `pluginRoot` removed from marketplace.json
2. ~~**Test agent discovery**~~ — Resolved: `"agents": "./agents/"` added to plugin.json
3. ~~**Verify MCP tool naming**~~ — Resolved: Updated to `mcp__plugin_britenites_*` prefix

### P1 — ~~Fix soon~~ MOSTLY RESOLVED
4. ~~**Standardize `allowed-tools` format**~~ — Resolved: All skills use comma-separated strings
5. ~~**Move `argument-hint` to top level**~~ — Resolved: Already at top level
6. **Move version to marketplace.json** — Open: version is in both plugin.json and marketplace.json. Low priority.

### P2 — Address when convenient
7. ~~**Add LICENSE file**~~ — Resolved: exists at `plugins/workflows/LICENSE`
8. **Consider migrating commands to skills** — Open: `code-review` and `tech-stack` are candidates
9. **Document CI over-validation** — Open: add comment noting stricter-than-spec validation is intentional

---

## Verification

After making changes:
1. Run `claude plugin validate .` from the repo root
2. Test with `claude --plugin-dir ./plugins/workflows` and verify:
   - All skills appear in `/help`
   - Agents appear in `/agents`
   - Try invoking `/workflows:post-plan-setup` to test agent delegation
   - Try invoking `/workflows:agent-browser` to test allowed-tools
3. Run the CI workflow to ensure validation passes
