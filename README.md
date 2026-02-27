# Britenites Claude Plugins

A **Process + Org** plugin for Claude Code. Superpowers methodology + compound engineering + Linear integration — structured workflow (brainstorm → plan → worktree → execute → review → compound → audit) with Linear woven into every step.

**Current version:** 3.0.0 | [Changelog](CHANGELOG.md) | [Roadmap](ROADMAP.md)

## Philosophy

This plugin teaches *how* to work, not *what* to know about specific technologies:

```
session-start → brainstorm → plan → [worktree] → execute (subagent + TDD) → review → ship (compound + audit)
       ↑                                                                                         |
       └───────────────────── scope (creative discovery) ←───────────────────────────────────────┘
```

- **Process**: Superpowers' full workflow with TDD, subagent-per-task execution, and compound knowledge
- **Org**: Linear integration at every step, security hooks, team conventions
- **Domain skills are separate plugins** — tech-stack knowledge comes from context7 MCP or dedicated domain plugins

Influenced by [superpowers](https://github.com/obra/superpowers) and [compound-engineering](https://github.com/EveryInc/compound-engineering-plugin). See the [Roadmap](ROADMAP.md) for what's coming next.

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

**Core workflow (the inner loop):**

| Command | Description |
|---------|-------------|
| `/britenites:session-start` | Start a work session — pick a Linear issue, brainstorm, plan, execute |
| `/britenites:review` | Run review agents in parallel, fix P1s, report findings |
| `/britenites:ship` | Create PR, update Linear, compound learnings, best-practices audit |

**Direction-setting:**

| Command | Description |
|---------|-------------|
| `/britenites:scope` | Collaborative scoping session — discover what to build, create Linear issues |
| `/britenites:project-start` | Start a new project with a guided interview |

**Utilities:**

| Command | Description |
|---------|-------------|
| `/britenites:code-review` | Standardized code review for Britenites projects |
| `/britenites:security-audit` | Comprehensive project security audit |
| `/britenites:bug-report` | Standardized bug reporting with Linear integration |
| `/britenites:deployment-checklist` | Pre-deployment validation checklist |
| `/britenites:tech-stack` | Display the Britenites technology stack |
| `/britenites:onboarding-checklist` | Guide for setting up a new dev environment |
| `/britenites:setup-claude-md` | Generate best-practices CLAUDE.md for a project |
| `/britenites:smoke-test` | Diagnostic checks on plugin environment |

## Skill Coverage Matrix

Skills activate automatically when Claude detects relevant context.

**Inner Loop skills** (auto-activate in sequence):

| Skill | Category | Trigger |
|-------|----------|---------|
| `brainstorming` | Discovery | Non-trivial issue, before planning |
| `writing-plans` | Planning | Multi-step task, before coding |
| `git-worktrees` | Setup | After plan approval, before coding |
| `executing-plans` | Execution | Given an approved plan to implement |
| `verification-before-completion` | Quality | Task checkpoints during execution |
| `compound-learnings` | Knowledge | After completing work (via ship) |
| `best-practices-audit` | Quality | After compound learnings (via ship) |
| `systematic-debugging` | Debugging | Bug investigation (anytime) |

**Design & quality skills** (shipped):

| Skill | Category | Trigger |
|-------|----------|---------|
| `react-best-practices` | Frontend | Writing, reviewing, or optimizing React components |
| `frontend-design` | Frontend | Building web components, pages, dashboards |
| `ui-ux-pro-max` | Design | Design tasks across 50 styles, 9 frameworks, 21 palettes |
| `web-design-guidelines` | Design | Reviewing UI code for best practices and accessibility |
| `code-quality` | Quality | ESLint, Prettier, Ruff, TypeScript strict enforcement |
| `agent-browser` | Automation | Navigating websites, filling forms, taking screenshots |
| `find-skills` | Discovery | Looking for new skills or capabilities to install |

**Workflow skills** (shipped):

| Skill | Category | Trigger |
|-------|----------|---------|
| `post-plan-setup` | Workflow | After `/britenites:project-start` produces a v1 plan (orchestrates 3 phases) |
| `refine-plan` | Workflow | Decomposes v1 plans into agent-ready tasks (internal) |
| `create-issues` | Workflow | Creates Linear issues from refined plans (internal) |
| `setup-claude-md` | Workflow | Generates best-practices CLAUDE.md for a project (internal) |

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
    .mcp.json               # MCP server configurations
```

### Plugin Manifest (plugin.json)

Each plugin requires `.claude-plugin/plugin.json`:

```json
{
  "name": "britenites",
  "description": "Process + Org plugin — structured workflow methodology with Linear integration",
  "version": "3.0.0",
  "author": { "name": "Britenites" },
  "homepage": "https://github.com/brite-nites/britenites-claude-plugins",
  "repository": "https://github.com/brite-nites/britenites-claude-plugins",
  "license": "MIT",
  "keywords": ["claude-code", "plugin", "process", "workflow", "linear"],
  "commands": "./commands/",
  "skills": "./skills/"
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
    "description": "Claude Code plugins for the Britenites organization"
  },
  "plugins": [
    {
      "name": "britenites",
      "source": "./plugins/britenites",
      "description": "Process + Org plugin — structured workflow methodology with Linear integration",
      "version": "3.0.0"
    }
  ]
}
```

To add a new plugin to the bundle, create the plugin directory and add it to the `plugins` array.

---

## Documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | System diagrams, runtime flow, skill routing, design decisions |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to add commands, skills, agents, hooks; branch and PR conventions |
| [docs/getting-started.md](docs/getting-started.md) | Developer setup for working on this repo |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Common issues and solutions |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [ROADMAP.md](ROADMAP.md) | Development plan and lifecycle vision |
| [CLAUDE.md](CLAUDE.md) | Instructions for Claude Code when working in this repo |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full contributor guide, including:
- Step-by-step instructions for adding commands, skills, agents, and hooks
- SKILL.md frontmatter standard
- Branch naming and commit message conventions
- CI checks and local testing

## License

MIT

## Issue Tracking

Issues for this project are tracked in [Brite Claude Code Plugin](https://linear.app/brite-nites/project/brite-claude-code-plugin-402b57908532).
