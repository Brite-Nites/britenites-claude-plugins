# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Superpowers methodology + compound engineering + Linear integration.** A Process + Org plugin for the Brite organization — structured workflow (brainstorm → plan → worktree → execute → review → compound → audit) with Linear woven into every step.

## Linear Project

Project: Brite Plugin Marketplace

## Plugin Philosophy

- **Process**: Superpowers' full workflow with TDD, subagent-per-task execution, and compound knowledge accumulation
- **Org**: Linear integration at every step, security hooks, team conventions
- **Not domain**: Tech-stack skills belong in separate plugins. Use context7 MCP for framework docs.

## Repository Structure

```
.claude-plugin/marketplace.json    # Plugin registry - defines available plugins
.github/workflows/                 # CI/CD validation
plugins/
  workflows/
    .claude-plugin/plugin.json     # Plugin metadata (name, version, author)
    commands/
      *.md                         # Command definitions (markdown format)
    skills/
      */SKILL.md                   # Skill definitions (auto-invoked by Claude)
      _shared/                     # Shared utilities referenced by skills
    hooks/
      hooks.json                   # PreToolUse, PostToolUse, SessionStart hooks
    .mcp.json                      # MCP server configurations
```

## How the Plugin System Works

- **marketplace.json**: Registers plugins for distribution. Each plugin's `source` is a path relative to the repo root (e.g., `./plugins/workflows`).
- **plugin.json**: Each plugin has metadata defining name, description, version, and author. See **plugin.json Schema** below — this is critical.
- **Commands**: Markdown files in `commands/` become slash commands (e.g., `sprint-planning.md` → `/sprint-planning`).
- **Auto-discovery**: `agents/`, `hooks/hooks.json`, and `.mcp.json` are discovered by convention from the plugin root. Do NOT declare them in `plugin.json`.

## Adding New Commands

1. Create a new `.md` file in `plugins/workflows/commands/`
2. Add YAML frontmatter with `description` field
3. Write the command instructions in markdown

Example structure:
```markdown
---
description: Short description of what this command does
---

Command instructions for Claude go here...
```

## SKILL.md Frontmatter Standard

All skills must follow this frontmatter schema:

```yaml
---
name: skill-name              # Required. Must match the directory name.
description: When to use...   # Required. Unquoted. Describes trigger conditions.
user-invocable: true           # Required. Explicit true or false.
allowed-tools: Tool(pattern)   # Optional. Only when skill needs specific tool permissions.
license: MIT                   # Optional. SPDX identifier for third-party content.
metadata:                      # Optional. Only for skills from external sources.
  author: source-org
  version: "1.0.0"
---
```

Rules:
- `name` must match the skill's directory name exactly (e.g., `skills/react-best-practices/` → `name: react-best-practices`)
- `description` must not be quoted — use plain YAML string
- `user-invocable` must always be explicit, never rely on defaults
- `license` is only needed when the skill contains third-party content
- `metadata` is only needed for skills ported from external sources (e.g., Vercel)

## Hooks

The plugin includes hooks in `plugins/workflows/hooks/hooks.json` (auto-loaded by Claude Code — do NOT add a `hooks` field to `plugin.json`):

- **PreToolUse (Bash)**: Two-layer security — regex command hook (deterministic, blocks `rm -rf`, `--force`, `DROP`, `chmod 777`, piped downloads) runs first, then Haiku prompt hook as fallback
- **PreToolUse (Bash)**: Pre-commit quality — intercepts `git commit` commands, detects project type (`package.json` → JS/TS, `pyproject.toml`/`setup.py` → Python), runs linters on staged files only (ESLint, `tsc --noEmit`, Ruff). Degrades gracefully if no linters installed. Note: inactive from plugins until upstream [#6305](https://github.com/anthropics/claude-code/issues/6305) is fixed.
- **PreToolUse (Write/Edit)**: Two-layer security — regex command hook (deterministic, blocks `sk-proj-`, `AKIA`, `ghp_`, `sk_live/test` patterns) runs first, then Haiku prompt hook as fallback
- **PostToolUse (Write/Edit)**: Auto-linter — runs ESLint (JS/TS) or Ruff (Python) if available
- **SessionStart**: Team context — runs environment health checks (git, node, gh, npx) and shows key commands

A standalone version of the pre-commit hook is available at `scripts/pre-commit.sh` for direct installation as a git hook (`cp scripts/pre-commit.sh .git/hooks/pre-commit`). This works today regardless of the upstream plugin hook bug.

## Skill Routing

### Inner Loop Skills (auto-activate in sequence)

| Skill | Triggers on | Purpose |
|-------|-------------|---------|
| `brainstorming` | Non-trivial issue, before planning | Socratic discovery, design document |
| `writing-plans` | Multi-step task, before coding | Bite-sized tasks with TDD, verification |
| `git-worktrees` | After plan approval, before coding | Isolated workspace with Linear issue ID |
| `executing-plans` | Given an approved plan | Subagent-per-task + TDD + checkpoints |
| `verification-before-completion` | Task checkpoints | 4-level verification before marking done |
| `compound-learnings` | After completing work (via ship) | Knowledge capture to CLAUDE.md + memory |
| `best-practices-audit` | After compound (via ship) | CLAUDE.md audit + auto-fix |
| `systematic-debugging` | Bug investigation (anytime) | 4-phase root-cause analysis |

### Backend Skills

| Skill | Triggers on | Purpose |
|-------|-------------|---------|
| `python-best-practices` | Writing, reviewing, refactoring FastAPI/Python code | Architectural patterns audit |

### Design Skills

| Skill | Triggers on | Purpose |
|-------|-------------|---------|
| `frontend-design` | "build", "create", "implement" UI | Write production code |
| `ui-ux-pro-max` | "choose palette", "design system", "plan visual direction" | Design planning |
| `web-design-guidelines` | "review", "audit", "check" existing UI | Compliance review |

## plugin.json Schema (STRICT — read before editing)

**Claude Code validates plugin.json against a strict Zod schema. Any unrecognized field causes a silent hard failure — the entire plugin won't load (no commands, no skills, nothing). There is no error message shown to the user.**

Only these fields are recognized:

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `name` | string | yes | |
| `description` | string | yes | |
| `author` | `{ name, email? }` | yes | |
| `version` | string | no | Must bump for cache invalidation |
| `homepage` | string | no | |
| `repository` | string | no | |
| `license` | string | no | |
| `keywords` | string[] | no | |
| `commands` | string | no | Path to commands dir (e.g., `"./commands/"`) |
| `skills` | string | no | Path to skills dir (e.g., `"./skills/"`) |
| `mcpServers` | object | no | **Inline object only**, not a file path |

**NEVER add these to plugin.json** (they are auto-discovered from the plugin root):
- `agents` — the `agents/` directory is scanned automatically
- `hooks` — `hooks/hooks.json` is loaded automatically
- `mcpServers` as a string path (e.g., `"./.mcp.json"`) — `.mcp.json` is loaded automatically. If you must declare MCP servers in plugin.json, use the inline object format.

The `scripts/validate.sh` pre-push hook and CI workflow both enforce this allowlist.

## Adding New Plugins

1. Create a new directory under `plugins/` with `.claude-plugin/plugin.json`
2. Register the plugin in `.claude-plugin/marketplace.json` under the `plugins` array

## Testing & Validation

- `scripts/validate.sh` — structural validation (JSON, frontmatter, schema, cross-refs). Run pre-push and in CI.
- `scripts/test-hooks.sh` — tests security and quality hook regex patterns against 37 known inputs. Run in CI.
- `scripts/check-prereqs.sh` — verifies CLI tools, MCP servers, plugin JSON validity.
- `scripts/test-plugin-load.sh` — verifies all commands register (runs outside Claude, for CI).
- `/workflows:smoke-test` — in-session diagnostic (env, MCP, hooks, agent dispatch).
- `docs/testing-guide.md` — comprehensive testing guide (51 tests across 7 layers).

## Known Issues

- **PreToolUse/PostToolUse hooks don't fire from plugins** — upstream Claude Code bug ([#6305](https://github.com/anthropics/claude-code/issues/6305)). Our hook definitions in `hooks/hooks.json` are correct; no changes needed on our side. SessionStart hooks work fine. Track the issue for updates.

## No Build Process

This repository has no dependencies, build steps, or tests. Changes are version-controlled with Git and distributed directly.

## CI/CD

A GitHub Actions workflow (`.github/workflows/validate-plugin.yml`) runs on push/PR to main and validates:
- JSON validity of marketplace.json, plugin.json, and hooks.json
- Required fields in plugin.json
- Frontmatter in all commands and SKILL.md files
- Skill name-to-directory matching
