# Britenites Claude Plugins

Claude Code plugin bundle for the Britenites organization. Provides custom commands, skills, and MCP integrations that extend Claude Code's functionality.

**Current version:** 1.2.0 | [Changelog](CHANGELOG.md) | [Roadmap](ROADMAP.md)

## Prerequisites

- [Claude Code](https://claude.ai/code) CLI installed
- Node.js 18+ (for MCP servers)

## Quick Start

Install the plugin bundle:

```bash
claude plugins add https://github.com/Brite-Nites/britenites-claude-plugins
```

Or manually add to your `.claude/settings.json`:

```json
{
  "plugins": [
    {
      "source": "https://github.com/Brite-Nites/britenites-claude-plugins",
      "plugins": ["britenites"]
    }
  ]
}
```

Verify installation by typing `/britenites:` in Claude Code — you should see the available commands in the slash menu.

## Available Commands

| Command | Description |
|---------|-------------|
| `/britenites:project-start` | Start a new project with a guided interview |
| `/britenites:tech-stack` | Display the Britenites technology stack for tech decisions |
| `/britenites:code-review` | Standardized code review for Britenites projects |
| `/britenites:onboarding-checklist` | Guide for setting up a new dev environment |

## Skill Coverage Matrix

Skills activate automatically when Claude detects relevant context. No manual invocation needed.

| Skill | Domain | Trigger |
|-------|--------|---------|
| `react-best-practices` | React / Next.js | Writing, reviewing, or optimizing React components |
| `frontend-design` | Frontend UI | Building web components, pages, landing pages, dashboards |
| `ui-ux-pro-max` | UI/UX Design | Design tasks across 50 styles, 9 frameworks, 21 palettes |
| `web-design-guidelines` | Design Review | Reviewing UI code for best practices and accessibility |
| `agent-browser` | Browser Automation | Navigating websites, filling forms, taking screenshots |
| `find-skills` | Skill Discovery | Looking for new skills or capabilities to install |

### Manually Invoking Skills

Some skills can also be invoked directly:

```
/britenites:react-best-practices
```

## MCP Servers

The plugin configures two MCP servers automatically:

| Server | Transport | Purpose |
|--------|-----------|---------|
| `sequential-thinking` | stdio | Structured reasoning via `@modelcontextprotocol/server-sequential-thinking` |
| `linear-server` | HTTP | Linear project management integration |

The Linear MCP server provides tools for managing issues, projects, milestones, and documentation directly from Claude Code.

---

## Plugin Development Guide

### Repository Structure

```
.claude-plugin/
  marketplace.json          # Plugin registry (required for bundles)
plugins/
  britenites/
    .claude-plugin/
      plugin.json           # Plugin metadata
    commands/               # Slash commands
    skills/                 # Model-invoked skills
    agents/                 # Specialized subagents
    hooks/                  # Event handlers
    styles/                 # Output style overrides
    .mcp.json               # MCP server configurations
```

### Plugin Manifest (plugin.json)

Each plugin requires `.claude-plugin/plugin.json`:

```json
{
  "name": "britenites",
  "description": "Baseline tools for Britenites org",
  "version": "1.0.0",
  "author": {
    "name": "Britenites"
  },
  "commands": "./commands/",
  "skills": "./skills/",
  "agents": "./agents/",
  "hooks": "./hooks/hooks.json",
  "mcpServers": "./.mcp.json"
}
```

---

## Adding Commands

Commands are slash commands that users invoke directly. Create a markdown file in `commands/`.

### File Structure

```
commands/
  my-command.md      # Becomes /britenites:my-command
```

### Command Format

```markdown
---
description: Brief description shown in slash menu
---

Instructions for Claude on how to handle this command.

Use $ARGUMENTS for the full user input after the command.
Use $1, $2, etc. for positional arguments.
```

### Example: Deploy Command

`commands/deploy.md`:

```markdown
---
description: Deploy the current project to production
---

You are deploying the user's project. Follow these steps:

1. Run all tests to ensure the build is stable
2. Build the production bundle
3. Deploy using the configured deployment method

The user specified: $ARGUMENTS
```

---

## Adding Skills

Skills are model-invoked capabilities that Claude uses automatically based on context. Unlike commands, users don't invoke skills directly — Claude decides when to use them.

### File Structure

```
skills/
  code-review/
    SKILL.md           # Required: Skill definition
    templates/         # Optional: Supporting files
  security-scan/
    SKILL.md
```

### SKILL.md Format

```markdown
---
name: code-review
description: When to use this skill - Claude reads this to decide
allowed-tools: Read, Grep, Glob
user-invocable: true
---

# Code Review Skill

Detailed instructions for how Claude should perform this skill.

## When to Activate
- User asks for code review
- PR review is requested
- Code quality assessment needed

## Process
1. First step...
2. Second step...
```

### Frontmatter Options

| Field | Description |
|-------|-------------|
| `name` | Skill identifier (required) |
| `description` | When/why Claude should use this skill (required) |
| `allowed-tools` | Tools Claude can use without asking permission |
| `model` | Specific model to use (e.g., `haiku`, `sonnet`) |
| `context: fork` | Run in isolated sub-agent |
| `agent` | Agent type when using `context: fork` |
| `user-invocable` | Show in slash menu (default: `true`) |

---

## Adding MCP Server Configurations

MCP (Model Context Protocol) servers connect Claude to external tools, APIs, and databases.

### File Location

Create `.mcp.json` at the plugin root:

```
plugins/
  britenites/
    .mcp.json           # MCP configuration
```

### Configuration Format

```json
{
  "mcpServers": {
    "database": {
      "command": "npx",
      "args": ["@britenites/mcp-database"],
      "env": {
        "DB_PATH": "${CLAUDE_PLUGIN_ROOT}/data"
      }
    },
    "api-client": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/api-server.js",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"]
    }
  }
}
```

### Path Variables

| Variable | Description |
|----------|-------------|
| `${CLAUDE_PLUGIN_ROOT}` | Absolute path to the plugin directory |

### Transport Types

**stdio (default)**:
```json
{
  "mcpServers": {
    "local-server": {
      "command": "./server.js",
      "args": []
    }
  }
}
```

**HTTP/SSE**:
```json
{
  "mcpServers": {
    "remote-server": {
      "url": "https://api.example.com/mcp",
      "transport": "sse"
    }
  }
}
```

---

## Adding Hooks

Hooks respond to Claude Code events automatically (formatting, validation, notifications).

### File Location

Create `hooks/hooks.json` or define inline in `plugin.json`:

```
plugins/
  britenites/
    hooks/
      hooks.json
```

### Hook Events

| Event | When it fires |
|-------|---------------|
| `PreToolUse` | Before Claude uses any tool |
| `PostToolUse` | After tool execution |
| `PostToolUseFailure` | After a tool fails |
| `UserPromptSubmit` | When user submits a prompt |
| `Stop` | When Claude attempts to stop |
| `SessionStart` | When a session begins |
| `SessionEnd` | When a session ends |

### Configuration Format

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh $CLAUDE_FILE_PATH"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Verify this command is safe to run"
          }
        ]
      }
    ]
  }
}
```

### Hook Types

| Type | Description |
|------|-------------|
| `command` | Execute a shell command/script |
| `prompt` | LLM-based evaluation (uses Haiku) |
| `agent` | Full agent with tool access |

---

## Adding Agents

Agents are specialized subagents that Claude can delegate tasks to.

### File Structure

```
agents/
  security-reviewer.md
  performance-tester.md
```

### Agent Format

```markdown
---
description: What this agent specializes in
capabilities:
  - security analysis
  - vulnerability detection
  - compliance checking
skills: security-scan, code-review
---

# Security Reviewer Agent

You are a security specialist. When delegated tasks:

1. Review code for security vulnerabilities
2. Check for OWASP Top 10 issues
3. Validate input sanitization
4. Report findings with severity levels
```

---

## Adding Output Styles

Output styles customize Claude's response format and behavior.

### File Structure

```
styles/
  concise.md
  verbose.md
```

### Style Format

```markdown
---
name: Concise Mode
description: Short, direct responses
keep-coding-instructions: true
---

Respond concisely. Use bullet points. Avoid lengthy explanations.
Maximum 3 sentences per response unless more detail is explicitly requested.
```

---

## Marketplace Configuration

The root `marketplace.json` registers plugins for distribution:

```json
{
  "name": "britenites-claude-plugins",
  "owner": {
    "name": "Britenites"
  },
  "metadata": {
    "description": "Claude Code plugins for the Britenites organization",
    "pluginRoot": "./plugins"
  },
  "plugins": [
    {
      "name": "britenites",
      "source": "./plugins/britenites",
      "description": "Baseline tools for Britenites org"
    }
  ]
}
```

To add a new plugin to the bundle, create the plugin directory and add it to the `plugins` array.

---

## Contributing

1. Create a new branch for your changes
2. Add or modify plugin components
3. Test locally by pointing Claude Code to your local directory
4. Submit a pull request

## License

MIT

## Issue Tracking

Issues for this project are tracked in [Brite Claude Code Plugin](https://linear.app/brite-nites/project/brite-claude-code-plugin-402b57908532).
