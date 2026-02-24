# Contributing

Internal guide for the Brite Nites team working on this plugin bundle.

## Quick Reference

### Add a command

1. Create `plugins/britenites/commands/my-command.md`
2. Add YAML frontmatter with `description`
3. Write instructions in markdown — use `$ARGUMENTS` for user input

### Add a skill

1. Create `plugins/britenites/skills/my-skill/SKILL.md`
2. Add frontmatter matching the [standard](#skillmd-frontmatter-standard) below
3. Ensure `name` matches the directory name exactly
4. Write skill instructions in markdown

### Add an agent

1. Create `plugins/britenites/agents/my-agent.md`
2. Add frontmatter: `name`, `description`, `model`, `tools`
3. Write system prompt with role and principles
4. Reference from a skill via `agent: my-agent` in the skill's frontmatter

### Add a hook

1. Edit `plugins/britenites/hooks/hooks.json`
2. Add to the appropriate event (`PreToolUse`, `PostToolUse`, `SessionStart`)
3. Choose type: `prompt` (LLM-evaluated) or `command` (shell script)
4. Set a `matcher` regex for which tools trigger the hook
5. Run `python3 -m json.tool hooks/hooks.json` to validate JSON

## SKILL.md Frontmatter Standard

Source of truth: [CLAUDE.md](CLAUDE.md) — reproduced here for convenience.

```yaml
---
name: skill-name              # Required. Must match the directory name.
description: When to use...   # Required. Unquoted plain YAML string.
user-invocable: true           # Required. Explicit true or false.
allowed-tools: Tool(pattern)   # Optional. Only when skill needs specific tool permissions.
license: MIT                   # Optional. SPDX identifier for third-party content.
metadata:                      # Optional. Only for skills from external sources.
  author: source-org
  version: "1.0.0"
---
```

**Rules:**
- `name` must match the skill's directory name (`skills/react-best-practices/` → `name: react-best-practices`)
- `description` must not be quoted — use plain YAML string (no `>` folded blocks, no `"..."`)
- `user-invocable` must always be explicit — never rely on defaults
- `license` is only needed for third-party content
- `metadata` is only needed for skills ported from external sources

**Agent-linked skills** also use:
- `agent: agent-name` — references an agent in `agents/`
- `context: fork` — intended for isolated execution (currently has upstream bugs, runs inline)

## Branch Conventions

Branch from `main`. Use these prefixes:

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feat/` | New feature (command, skill, agent) | `feat/deploy-command` |
| `fix/` | Bug fix | `fix/hook-matcher-regex` |
| `docs/` | Documentation only | `docs/architecture-guide` |

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add /deploy command for production deployments
fix: correct hook matcher for Write|Edit tools
docs: add ARCHITECTURE.md with system diagrams
chore: bump version to 1.5.0
refactor: extract shared validation to _shared/
```

Examples from this repo's history:

```
feat: add interactive Linear project setup to create-issues
Complete Milestone 1 foundation: fix plugin.json, add docs, standardize skills
Standardize post-plan skills frontmatter and register agents directory
Update CHANGELOG.md with v1.3.0 entry
```

## Pull Request Process

1. Create a branch with the appropriate prefix
2. Make your changes
3. Push and open a PR against `main`
4. CI runs automatically (see [CI Checks](#ci-checks) below)
5. PR description should include:
   - What changed and why
   - Which components were added/modified (commands, skills, agents, hooks)
   - How to test the changes

## CI Checks

The GitHub Actions workflow (`validate-plugin.yml`) validates on every push/PR to `main`:

| Check | What it validates |
|-------|-------------------|
| JSON validity | `marketplace.json`, `plugin.json`, `hooks.json` parse correctly |
| Required fields | `plugin.json` has `name`, `description`, `author` |
| Directory existence | `commands/`, `skills/`, `agents/` exist |
| Command frontmatter | Every `commands/*.md` has `---` block with `description` |
| Skill frontmatter | Every `skills/*/SKILL.md` has `name`, `description`, `user-invocable` |
| Skill name matching | `name` field matches the directory name |
| Hooks structure | `hooks.json` is valid JSON with proper event/handler structure |

## Testing Changes Locally

### Automated validation

Run the validation script (requires `python3`):

```bash
./scripts/validate.sh
```

This mirrors all CI checks plus additional ones: marketplace field validation, path resolution, `allowed-tools` format, `argument-hint` nesting, agent frontmatter, and cross-reference integrity.

To run validation automatically before every push:

```bash
./scripts/setup-hooks.sh
```

### Manual testing checklist

After `./scripts/validate.sh` passes, test interactively:

```bash
claude --plugin-dir ./plugins/britenites
```

1. Type `/britenites:` — confirm 4 commands appear
2. Say "review my UI" — should trigger `web-design-guidelines` skill
3. Say "build a login form" — should trigger `frontend-design` skill
4. New session check — SessionStart hook fires ("Loading Britenites context...")
5. Edit a `.ts` file — PostToolUse linter hook fires
6. Run `claude plugin validate .` from repo root for official CLI validation

## Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **Major** (X.0.0): Breaking changes to plugin structure or command interfaces
- **Minor** (0.X.0): New commands, skills, agents, or hooks
- **Patch** (0.0.X): Bug fixes, documentation updates, typo corrections

When bumping a version:

1. Update `version` in `.claude-plugin/marketplace.json` (under the plugin's entry)
2. Add an entry to `CHANGELOG.md` under `[Unreleased]` or a new version heading
3. Follow [Keep a Changelog](https://keepachangelog.com/) format

## Skill Routing Updates

When adding a new design-related skill, check the routing table in [ARCHITECTURE.md](ARCHITECTURE.md#design-skills-three-way-split). Design skills must have distinct trigger language to avoid conflicts:

- **Implementation** triggers: "build", "create", "implement", "code"
- **Planning** triggers: "choose", "plan", "explore", "brainstorm"
- **Review** triggers: "review", "audit", "check", "evaluate"

Write the `description` field to clearly signal which category the skill belongs to.

## Using `_shared/` Utilities

Two shared files in `skills/_shared/` are available for any skill to reference:

| File | What it provides |
|------|------------------|
| `validation-pattern.md` | Self-validation & retry loop (check → evaluate → retry 3x → flag for human) |
| `output-formats.md` | Standard severity levels, finding format, summary/progress blocks |

To use them, add to your skill's instructions:

```markdown
### Validation Criteria
Read `.claude/skills/_shared/validation-pattern.md` and apply it.
```

Do not duplicate the shared content into individual skills.
