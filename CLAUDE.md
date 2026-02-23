# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Claude Code Plugin Bundle** for the Britenites organization. It provides custom commands that extend Claude Code's functionality, distributed via a marketplace system.

## Repository Structure

```
.claude-plugin/marketplace.json    # Plugin registry - defines available plugins
.github/workflows/                 # CI/CD validation
plugins/
  britenites/
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

- **marketplace.json**: Registers plugins for distribution. The `pluginRoot` field points to `./plugins`.
- **plugin.json**: Each plugin has metadata defining name, description, version, and author.
- **Commands**: Markdown files in `commands/` become slash commands (e.g., `project-start.md` → `/project-start`).

## Adding New Commands

1. Create a new `.md` file in `plugins/britenites/commands/`
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

The plugin includes hooks in `plugins/britenites/hooks/hooks.json`:

- **PreToolUse (Bash)**: Security scan — checks commands for destructive operations, piped downloads, credential exposure
- **PreToolUse (Write/Edit)**: Security scan — checks file content for hardcoded secrets, injection patterns
- **PostToolUse (Write/Edit)**: Auto-linter — runs ESLint (JS/TS) or Ruff (Python) if available
- **SessionStart**: Team context — reminds Claude of Britenites conventions

## Skill Routing

Design skills are differentiated by intent:

| Skill | Triggers on | Purpose |
|-------|-------------|---------|
| `frontend-design` | "build", "create", "implement" UI | Write production code |
| `ui-ux-pro-max` | "choose palette", "design system", "plan visual direction" | Design planning |
| `web-design-guidelines` | "review", "audit", "check" existing UI | Compliance review |

## Adding New Plugins

1. Create a new directory under `plugins/` with `.claude-plugin/plugin.json`
2. Register the plugin in `.claude-plugin/marketplace.json` under the `plugins` array

## No Build Process

This repository has no dependencies, build steps, or tests. Changes are version-controlled with Git and distributed directly.

## CI/CD

A GitHub Actions workflow (`.github/workflows/validate-plugin.yml`) runs on push/PR to main and validates:
- JSON validity of marketplace.json, plugin.json, and hooks.json
- Required fields in plugin.json
- Frontmatter in all commands and SKILL.md files
- Skill name-to-directory matching
