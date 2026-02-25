# Live Test Report — Britenites Plugin v2.0.0

**Date**: 2026-02-24 (updated after session restart)
**Tester**: Claude Opus 4.6 (automated)
**Branch**: `release/v2.0.0` (commit `cfdc67a`)

---

## Executive Summary

**Overall Status: PASS with known issue (Haiku false negatives)**

After the session restart, the plugin loads correctly:
- All **7 commands** visible and invocable
- All **3 new agents** registered and dispatchable in parallel
- **SessionStart hook** configured with correct status message
- **PostToolUse linter hook** fires on .ts/.js file writes
- **PreToolUse security hooks** fire but Haiku produces false negatives on `rm -rf /tmp/...` and `sk-proj-` patterns (Issue 3)

### Blocking Issue

**Issue 3 (Haiku false negatives)** is the only remaining gap. The hook infrastructure works, but the prompt-based Haiku model does not reliably block all dangerous patterns. A deterministic regex pre-filter is recommended before the Haiku layer.

---

## Issues Found

### Issue 1: Plugin Not Installed/Enabled (FIXED — Session 1)

**What**: The britenites plugin was registered as a marketplace in `known_marketplaces.json` but was NOT present in `installed_plugins.json` or `settings.json` `enabledPlugins`.

**Fix Applied**: Added `britenites@britenites-claude-plugins` to both config files. **Verified working after restart.**

### Issue 2: v2.0.0 Files Not Committed (FIXED — Session 1)

**What**: The 3 new commands, 3 new agents, and 1 new doc were untracked in git.

**Fix Applied**: All files committed to `release/v2.0.0` branch. Cache synced. **Verified working after restart.**

### Issue 3: Haiku Security Hook False Negatives (CONFIRMED)

**What**: The prompt-based Haiku hook does not reliably catch all dangerous patterns. Confirmed in Session 2:
- `rm -rf /tmp/test-dangerous` — **NOT blocked** (Haiku likely considers `/tmp/` low-risk)
- `sk-proj-abc123def456` in a Write — **NOT blocked** (Haiku did not flag the secret pattern)

**Recommendation**: Add a deterministic regex-based command hook as a pre-filter before the Haiku prompt hook:
```json
{
  "type": "command",
  "command": "echo \"$TOOL_INPUT\" | grep -qE 'rm\\s+-rf|git\\s+push\\s+--force|DROP\\s+TABLE|chmod\\s+777' && echo '{\"ok\":false,\"reason\":\"Destructive command pattern detected\"}' || echo '{\"ok\":true}'",
  "timeout": 5,
  "statusMessage": "Quick security check..."
}
```
And for Write/Edit secret detection:
```json
{
  "type": "command",
  "command": "echo \"$TOOL_INPUT\" | grep -qE '(sk-|AKIA|ghp_|ghs_|Bearer\\s+[A-Za-z0-9]|password\\s*=\\s*[\"'\\'']).{8,}' && echo '{\"ok\":false,\"reason\":\"Possible hardcoded secret detected\"}' || echo '{\"ok\":true}'",
  "timeout": 5,
  "statusMessage": "Secret scan..."
}
```
This gives deterministic blocking for known patterns, with Haiku as a second-layer review.

---

## Test Results

### Tier 1: Plugin Loads Correctly

| Test | Status | Notes |
|------|--------|-------|
| T1.1 SessionStart Hook | PASS | Hook configured with `"Loading Britenites context..."` status. Plugin loaded and enabled in this session. |
| T1.2 All 7 Commands | PASS | All 7 commands visible: project-start, tech-stack, code-review, onboarding-checklist, session-start, review, ship |
| T1.3 Safe Bash Command | PASS | `echo hello` executed successfully, passed security check |
| T1.4 Dangerous Bash Command | FAIL | `rm -rf /tmp/test-dangerous` NOT blocked — Haiku false negative (see Issue 3) |
| T1.5 Secret Detection | FAIL | `sk-proj-abc123def456` written without being blocked — Haiku false negative (see Issue 3) |
| T1.6 PostToolUse Linter | PASS | `.ts` file write triggers linter hook with `"Running linter..."` status. Gracefully no-ops when eslint not locally installed. |

### Tier 2: Existing Commands (Regression)

| Test | Status | Notes |
|------|--------|-------|
| T2.1 `/britenites:tech-stack` | PASS | Full stack displayed with all sections |
| T2.2 `/britenites:code-review` (no args) | PASS | Checked git diff, correct empty-state behavior |
| T2.3 `/britenites:code-review` (with args) | PARTIAL | Command loads. No live PR available for full test. |
| T2.4 `/britenites:onboarding-checklist` | PASS | Interactive checklist started, tool checks ran |

### Tier 3: New Commands (Smoke Tests)

| Test | Status | Notes |
|------|--------|-------|
| T3.1 `session-start` (no args) | PASS | Command loaded, queried Linear MCP, returned real issues in table format. Full workflow operational. |
| T3.2 `session-start BN-XXX` | NOT TESTED | `get_issue` MCP verified available in Session 1. |
| T3.3 `/review` (agent dispatch) | PASS | All 3 agents dispatched in parallel: code-reviewer, security-reviewer, typescript-reviewer. Each confirmed identity and tool access. |
| T3.4 `code-review deep` | PASS | Deep mode dispatch path confirmed (same 3 agents as T3.3). Command references agents at lines 27-29. |
| T3.5 `/ship` | NOT TESTED | Command loaded (visible in session). `gh` auth and Linear `update_issue` verified in Session 1. |

### Tier 4: Full Workflow

| Test | Status | Notes |
|------|--------|-------|
| T4.1 Complete Session Loop | NOT TESTED | All prerequisites (T3.x) now pass. Ready for full workflow test. |

### Tier 5: Edge Cases

| Test | Status | Notes |
|------|--------|-------|
| T5.1 Dirty working directory | NOT TESTED | session-start now loaded; ready to test |
| T5.2 No test suite | NOT TESTED | review now loaded; ready to test |
| T5.3 Failing tests | NOT TESTED | ship now loaded; ready to test |
| T5.4 Linear MCP disconnected | NOT TESTED | Would need to disable MCP mid-session |
| T5.5 Piped download | NOT TESTED | Hooks fire but Haiku reliability uncertain (see Issue 3) |

---

## Agent Registration Verification

| Agent | Status | Tools |
|-------|--------|-------|
| `britenites:code-reviewer` | REGISTERED | Glob, Grep, Read, Bash |
| `britenites:security-reviewer` | REGISTERED | Glob, Grep, Read, Bash |
| `britenites:typescript-reviewer` | REGISTERED | Glob, Grep, Read, Bash |

All 3 agents confirmed: dispatch in parallel, respond with correct identity, have expected tool access.

---

## Infrastructure Verification Summary

| Dependency | Status |
|-----------|--------|
| Git CLI | Working (v2.50.1) |
| GitHub CLI (`gh`) | Authenticated (holdeeno) |
| Linear MCP | Connected, returns real issues |
| Linear `update_issue` | Available |
| Linear `create_comment` | Available |
| Sequential Thinking MCP | Available |
| Task tool (agent dispatch) | Working — all 3 new agents dispatchable |
| `AskUserQuestion` | Available |
| Plugin hooks (PreToolUse) | Firing — but Haiku false negatives |
| Plugin hooks (PostToolUse) | Firing — linter runs on .ts/.js writes |
| Plugin hooks (SessionStart) | Configured — loads Britenites context |

---

## Fixes Applied During Testing

### Session 1 (pre-restart)
1. **Created** `release/v2.0.0` branch with all v2.0.0 changes committed
2. **Synced** marketplace cache (`~/.claude/plugins/marketplaces/britenites-claude-plugins/`) with local files
3. **Created** v2.0.0 cache entry (`~/.claude/plugins/cache/britenites-claude-plugins/britenites/2.0.0/`)
4. **Added** `britenites@britenites-claude-plugins` to `installed_plugins.json`
5. **Enabled** `britenites@britenites-claude-plugins: true` in `settings.json`

### Session 2 (post-restart)
6. **Verified** all Session 1 fixes took effect
7. **Confirmed** Haiku false negatives (Issue 3) — not a hook infrastructure problem

---

## Next Steps

### Before merging release/v2.0.0
1. **Fix Issue 3**: Add regex-based deterministic pre-filter hooks before Haiku prompt hooks
2. Re-test T1.4 and T1.5 with the regex pre-filter in place
3. Push branch to GitHub: `git push -u origin release/v2.0.0`
4. Create PR for v2.0.0 release
5. Run CI validation (`.github/workflows/validate-plugin.yml`)

### Optional (post-merge)
6. Run T4.1 (full session loop) on a real issue
7. Run T5.1–T5.5 edge cases
8. Test T3.2 (`session-start BN-XXX`) and T3.5 (`/ship`) end-to-end
