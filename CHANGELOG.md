# Changelog

All notable changes to the Britenites Claude Plugins bundle will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [2.0.0] - 2026-02-24

### Added
- 3 new commands: `session-start` (pick a Linear issue and plan work), `review` (run review agents in parallel, fix P1s), `ship` (create PR, update Linear, compound learnings)
- 3 new agents: `code-reviewer` (P1/P2/P3 code quality), `security-reviewer` (OWASP Top 10, secrets exposure), `typescript-reviewer` (type safety, React/Next.js patterns)
- Two-layer hook security: regex command hooks (deterministic, first) + haiku prompt hooks (fallback, second) for both Bash and Write/Edit
- `agents` directory declaration in plugin.json for explicit agent discovery
- Plugin-namespaced MCP tool references in agents and skills

### Changed
- Hook architecture from single-layer prompt hooks to two-layer regex+prompt
- `pluginRoot` removed from marketplace.json (was causing double-pathing)
- `hooks` field removed from plugin.json (Claude Code auto-loads hooks.json)
- MCP tool names updated to plugin-namespaced format (`mcp__plugin_britenites_*`)

### Fixed
- Plugin source path resolution in marketplace.json
- Agent discoverability via explicit plugin.json declaration

## [1.5.0] - 2026-02-23

### Added
- ARCHITECTURE.md with Mermaid diagrams, runtime flow, skill routing, hook execution, agent delegation, design decisions
- CONTRIBUTING.md with quick reference, frontmatter standard, branch/commit conventions, CI checks
- docs/getting-started.md for plugin development setup
- docs/troubleshooting.md for common issues and solutions

### Changed
- ROADMAP.md rewritten with 7-phase lifecycle vision, coverage map, competitive context, and detailed development phases
- README.md updated: version 1.4.0 → 1.5.0, added Vision section, post-plan skills in matrix, Documentation table, current plugin.json example, simplified Contributing

## [1.3.0] - 2026-02-23

### Added

- Post-plan workflow: `refine-plan`, `create-issues`, `setup-claude-md`, `post-plan-setup` skills
- 4 custom agents: `plan-refiner`, `issue-creator`, `claude-md-generator`, `post-plan-orchestrator`
- Shared validation/retry pattern for skills (`skills/_shared/validation-pattern.md`)
- `/code-review` command with frontend, backend, and data engineering checklists
- `/onboarding-checklist` command for new developer environment setup
- CHANGELOG.md, ROADMAP.md documentation
- SKILL.md frontmatter standard documented in CLAUDE.md
- Skill coverage matrix and MCP server docs in README

### Changed

- Standardized frontmatter across all 10 skills (explicit `user-invocable`, plain string descriptions)
- Renamed `vercel-react-best-practices` skill to `react-best-practices` to match directory name
- Improved README with prerequisites, quick start, and verification steps
- Registered `commands` and `agents` directories in plugin.json

## [1.2.0] - 2026-01-27

### Added

- 5 new skills: `frontend-design`, `ui-ux-pro-max`, `web-design-guidelines`, `find-skills`, `agent-browser`
- Skills cover frontend design, UI/UX intelligence, design review, skill discovery, and browser automation

## [1.1.0] - 2026-01-21

### Added

- `/tech-stack` command for technology stack decisions
- Technical collaborator path in `/project-start` command

## [1.0.0] - 2026-01-15

### Added

- Plugin bundle with marketplace configuration
- `/project-start` command with guided interview for non-technical users
- `react-best-practices` skill (45 Vercel Engineering rules for React/Next.js)
- Sequential-thinking MCP server
- Linear MCP server for project management integration
- CLAUDE.md and README.md documentation

### Changed

- Linear MCP server renamed from `linear` to `linear-server`
- Linear MCP URL updated from `.dev` to `.app`

[Unreleased]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v1.5.0...v2.0.0
[1.5.0]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v1.3.0...v1.5.0
[1.3.0]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Brite-Nites/britenites-claude-plugins/releases/tag/v1.0.0
