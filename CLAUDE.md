# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Claude Code Plugin Bundle** for the Britenites organization. It provides custom commands that extend Claude Code's functionality, distributed via a marketplace system.

## Repository Structure

```
.claude-plugin/marketplace.json    # Plugin registry - defines available plugins
plugins/
  britenites/
    .claude-plugin/plugin.json     # Plugin metadata (name, version, author)
    commands/
      *.md                         # Command definitions (markdown format)
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

## Adding New Plugins

1. Create a new directory under `plugins/` with `.claude-plugin/plugin.json`
2. Register the plugin in `.claude-plugin/marketplace.json` under the `plugins` array

## No Build Process

This repository has no dependencies, build steps, or tests. Changes are version-controlled with Git and distributed directly.
