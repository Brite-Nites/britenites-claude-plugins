# Changelog

All notable changes to the Britenites Claude Plugins bundle will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [3.2.0] - 2026-02-27

### Changed
- **session-start issue picker scoped to repo's Linear project** — Step 2 now reads `## Linear Project` from CLAUDE.md to resolve the project name, queries only that project, falls back to both Todo and Backlog states if no in-progress issues, and shows an empty-state prompt if no issues exist at all (BRI-1654)
- Added `## Linear Project` section to CLAUDE.md with project mapping convention

## [3.1.0] - 2026-02-27

### Added
- **python-best-practices skill** — 38-rule architectural guide for FastAPI, Pydantic v2, and SQLAlchemy 2.0 covering async correctness, dependency injection, database patterns, error handling, API design, testing, and project structure (BRI-1339)
- `code-review.md` Section 4 defers to python-best-practices skill for full backend audit
- Backend Skills subsection in CLAUDE.md Skill Routing

## [3.0.1] - 2026-02-27

### Changed
- **Best-practices reference rewrite** — `claude-code-best-practices.md` expanded from 84 to 178 lines with memory hierarchy, modular rules, @import syntax, hooks system, custom slash commands, Model Context Protocol, and multi-project setup (BRI-1640)
- `setup-claude-md/SKILL.md` size guidance corrected from 150 to 100 lines to match Anthropic's current recommendation

### Fixed
- `best-practices-audit/SKILL.md` — reference path changed from ambiguous relative path to installed convention (`.claude/skills/setup-claude-md/claude-code-best-practices.md`)
- `git-worktrees/SKILL.md` — DESCRIPTION derivation now collapses consecutive hyphens and strips leading/trailing hyphens; validation regex tightened to `^[a-z0-9][a-z0-9-]*[a-z0-9]$`; derivation block moved before code block so agents read rules before using the variable

## [3.0.0] - 2026-02-26

### Added
- **8 new Inner Loop skills** — Full superpowers-equivalent methodology:
  - `brainstorming` — Socratic discovery before planning (BRI-1636)
  - `writing-plans` — Bite-sized tasks with exact files, TDD, verification (BRI-1617)
  - `git-worktrees` — Isolated workspace per task with Linear issue ID in branch name (BRI-1637)
  - `executing-plans` — Subagent-per-task execution with TDD enforcement (BRI-1618)
  - `compound-learnings` — Knowledge capture and compounding after each session (BRI-1619)
  - `systematic-debugging` — 4-phase root cause analysis (BRI-1620)
  - `best-practices-audit` — CLAUDE.md audit + auto-fix against Anthropic guidelines (BRI-1638)
  - `verification-before-completion` — 4-level verification before marking tasks done (BRI-1639)
- `/britenites:scope` command — Collaborative creative scoping sessions that produce Linear issues (BRI-1641)
- 6 new Linear issues created for v3 milestone items (BRI-1636 through BRI-1641)

### Changed
- **Plugin philosophy refactor** — Reframed as superpowers + compound engineering + Linear integration
- `/britenites:session-start` — Now drives the full inner loop: brainstorm → plan → worktree → execute
- `/britenites:ship` — Now invokes compound-learnings and best-practices-audit skills, adds worktree cleanup
- Plugin description updated to "Process + Org plugin — structured workflow methodology with Linear integration"
- Keywords updated: removed design-system/react/ui-ux, added process/workflow/tdd/compound-engineering
- Hook regex tests expanded from 24 to 37 (added git commit detection, force-push variants)
- ROADMAP.md rewritten with three-workflow model (Greenfield, Inner Loop, Scoping)
- Milestone 2 (Inner Loop) expanded with 5 new issues
- Milestone 3 renamed from "The Outer Loop" to "Scoping & Discovery" with scope command
- README.md updated: 13 commands, 19 skills, full inner loop diagram
- CLAUDE.md updated: complete skill routing tables, inner loop documentation
- Version bumped to 3.0.0 in plugin.json and marketplace.json

## [2.3.0] - 2026-02-25

### Added
- `/britenites:security-audit` command — comprehensive project-wide security audit with automated checks (dependency vulnerabilities, secret scanning, env config) and security-reviewer agent dispatch
- `/britenites:deployment-checklist` command — pre-deployment validation checklist
- `/britenites:bug-report` command — standardized bug reporting with Linear integration
- `code-quality` skill — ESLint, Prettier, Ruff, mypy, TypeScript strict enforcement
- Pre-commit quality hook (PreToolUse) — intercepts `git commit`, runs ESLint/tsc/Ruff on staged files by project type
- `scripts/pre-commit.sh` — standalone git pre-commit hook for direct installation
- `/britenites:smoke-test` command — in-session diagnostic for env, MCP, hooks, agent dispatch
- Step 0 prerequisite guards in `session-start` (Linear + sequential-thinking MCP), `review` (agent dispatch), `ship` (gh auth)
- `scripts/test-hooks.sh` — 24 regex tests for security hook patterns (CI + local)
- `scripts/check-prereqs.sh` — runtime prerequisite verification
- `scripts/test-plugin-load.sh` — command registration test (terminal/CI only)
- `docs/test-protocol.md` — manual flow verification checklist (7 tests)

### Changed
- SessionStart hook now shows environment health checks (git, node, gh, npx status)
- CI workflow runs `test-hooks.sh` alongside structural validation

### Security
- Fixed PostToolUse hook file path injection vulnerability
- Replaced `echo` with `printf` in security hook command pipes
- Fixed force-push regex to catch `--force-with-lease`
- Pinned MCP server package version in `.mcp.json`

## [2.0.1] - 2026-02-24

### Fixed
- SessionStart hook `echo` replaced with `printf` for portable newline handling across shells
- Version bumped to bust stale plugin cache (Claude Code caches by version key)

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

[Unreleased]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v3.2.0...HEAD
[3.2.0]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v3.1.0...v3.2.0
[3.1.0]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v3.0.1...v3.1.0
[3.0.1]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v3.0.0...v3.0.1
[3.0.0]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v2.3.0...v3.0.0
[2.3.0]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v2.0.1...v2.3.0
[2.0.1]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v1.5.0...v2.0.0
[1.5.0]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v1.3.0...v1.5.0
[1.3.0]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/Brite-Nites/britenites-claude-plugins/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/Brite-Nites/britenites-claude-plugins/releases/tag/v1.0.0
