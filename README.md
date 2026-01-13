# Britenites Claude Code Plugins

Official Claude Code plugin bundle for the Britenites organization.

## Installation

Add this marketplace to your Claude Code configuration:

```bash
claude plugins add git@github.com:brite-nites/britenites-claude-plugins.git
```

## Plugins

### britenites-core

Baseline tools for Britenites org including:

- **basic-review** skill - Simple code review for quality and best practices

## Configuration

The core plugin includes an MCP server for internal API access. Set the following environment variable:

```bash
export BRITENITES_API_KEY="your-api-key"
```

## Development

To add new plugins, create a directory under `plugins/` following the Claude Code plugin structure.

## License

MIT
