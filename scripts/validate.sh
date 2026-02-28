#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

# ── Paths ──────────────────────────────────────────────────────────────
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"

# ── Counters & helpers ─────────────────────────────────────────────────
errors=0
warnings=0

pass()    { printf "  \033[32mPASS\033[0m  %s\n" "$1"; }
fail()    { printf "  \033[31mFAIL\033[0m  %s\n" "$1"; errors=$((errors + 1)); }
warn()    { printf "  \033[33mWARN\033[0m  %s\n" "$1"; warnings=$((warnings + 1)); }
section() { printf "\n\033[1m=== %s ===\033[0m\n" "$1"; }

# ── Prereqs ────────────────────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
  echo "ERROR: python3 is required but not found." >&2
  exit 2
fi

# Extract frontmatter (lines between first --- and second ---)
frontmatter() {
  sed -n '2,/^---$/{/^---$/d; p;}' "$1"
}

# Get a YAML value by key (simple single-line values only)
yaml_val() {
  # $1 = frontmatter text, $2 = key
  echo "$1" | grep "^$2:" | head -1 | sed "s/^$2: *//" || true
}

echo "Brite Plugin Validator"
echo "Repo root: $REPO_ROOT"

# ══════════════════════════════════════════════════════════════════════
# Section 1 — Marketplace JSON Validity
# ══════════════════════════════════════════════════════════════════════
section "1. JSON Validity (marketplace)"

if [ ! -f "$MARKETPLACE" ]; then
  fail "$MARKETPLACE does not exist"
else
  label="${MARKETPLACE#"$REPO_ROOT"/}"
  if python3 -m json.tool "$MARKETPLACE" > /dev/null 2>&1; then
    pass "$label"
  else
    fail "$label is not valid JSON"
  fi
fi

# ══════════════════════════════════════════════════════════════════════
# Section 2 — Marketplace Fields
# ══════════════════════════════════════════════════════════════════════
section "2. Marketplace Fields"

if [ -f "$MARKETPLACE" ]; then
  mp_errors=$(python3 -c "
import json, sys, os

with open('$MARKETPLACE') as f:
    data = json.load(f)

errors = []

for field in ['name', 'plugins']:
    if field not in data:
        errors.append(f'Missing top-level field: {field}')

owner = data.get('owner', {})
if not owner.get('name'):
    errors.append('Missing owner.name')

for i, plugin in enumerate(data.get('plugins', [])):
    for field in ['name', 'source']:
        if field not in plugin:
            errors.append(f'plugins[{i}] missing {field}')
    source = plugin.get('source', '')
    resolved = os.path.normpath(os.path.join('$REPO_ROOT', source))
    if not os.path.isdir(resolved):
        errors.append(f'plugins[{i}] source resolves to {resolved} which does not exist')

for e in errors:
    print(f'ERROR:{e}')
if not errors:
    print('OK')
" 2>&1)

  if [ "$mp_errors" = "OK" ]; then
    pass "marketplace.json fields valid"
  else
    while IFS= read -r line; do
      fail "${line#ERROR:}"
    done <<< "$mp_errors"
  fi
fi

# ══════════════════════════════════════════════════════════════════════
# Discover plugins from marketplace.json
# ══════════════════════════════════════════════════════════════════════

plugin_dirs=()
if [ -f "$MARKETPLACE" ]; then
  while IFS= read -r src; do
    resolved=$(cd "$REPO_ROOT" && realpath "$src" 2>/dev/null || echo "$REPO_ROOT/$src")
    if [ -d "$resolved" ]; then
      plugin_dirs+=("$resolved")
    fi
  done < <(python3 -c "
import json
with open('$MARKETPLACE') as f:
    data = json.load(f)
for p in data.get('plugins', []):
    print(p.get('source', ''))
" 2>&1)
fi

if [ ${#plugin_dirs[@]} -eq 0 ]; then
  fail "No plugins discovered from marketplace.json"
  section "Summary"
  printf "  \033[31m%d error(s)\033[0m, %d warning(s)\n" "$errors" "$warnings"
  echo ""
  exit 1
fi

# ══════════════════════════════════════════════════════════════════════
# validate_plugin() — runs per-plugin validation (sections 3-10)
# ══════════════════════════════════════════════════════════════════════
validate_plugin() {
  local PLUGIN_ROOT="$1"
  local PLUGIN_JSON="$PLUGIN_ROOT/.claude-plugin/plugin.json"
  local HOOKS_JSON="$PLUGIN_ROOT/hooks/hooks.json"
  local MCP_JSON="$PLUGIN_ROOT/.mcp.json"
  local plugin_name
  plugin_name="$(basename "$PLUGIN_ROOT")"

  printf "\n\033[1;36m── Plugin: %s ──\033[0m\n" "$plugin_name"

  # ── JSON Validity (plugin files) ──────────────────────────────────
  section "3. JSON Validity ($plugin_name)"

  for json_file in "$PLUGIN_JSON" "$HOOKS_JSON" "$MCP_JSON"; do
    label="plugins/$plugin_name/${json_file#"$PLUGIN_ROOT"/}"
    if [ ! -f "$json_file" ]; then
      # plugin.json is required, others are optional
      if [ "$json_file" = "$PLUGIN_JSON" ]; then
        fail "$label does not exist"
      else
        warn "$label not found (optional)"
      fi
      continue
    fi
    if python3 -m json.tool "$json_file" > /dev/null 2>&1; then
      pass "$label"
    else
      fail "$label is not valid JSON"
    fi
  done

  # ── plugin.json Fields ────────────────────────────────────────────
  section "4. plugin.json Fields ($plugin_name)"

  if [ -f "$PLUGIN_JSON" ]; then
    pj_result=$(python3 -c "
import json, sys

with open('$PLUGIN_JSON') as f:
    data = json.load(f)

errors = []

# Required fields
required = ['name', 'description', 'author']
missing = [k for k in required if k not in data]
if missing:
    errors.append(f'Missing required fields: {missing}')

# Author validation
author = data.get('author', {})
if not author.get('name'):
    errors.append('author.name is missing')

# CRITICAL: Claude Code validates plugin.json against a strict Zod schema.
# Unrecognized fields cause a hard validation failure that silently prevents
# the entire plugin from loading. This allowlist matches the actual schema.
allowed_fields = {
    'name', 'description', 'author', 'version',
    'homepage', 'repository', 'license', 'keywords',
    'commands', 'skills', 'mcpServers'
}
unknown = set(data.keys()) - allowed_fields
if unknown:
    errors.append(f'Unrecognized fields will break plugin loading: {sorted(unknown)}')
    errors.append('agents/, hooks/, and .mcp.json are auto-discovered — do not declare in plugin.json')

# mcpServers must be an object, not a string path
mcp = data.get('mcpServers')
if isinstance(mcp, str):
    errors.append(f'mcpServers must be an inline object, not a file path (\"{mcp}\")')
    errors.append('.mcp.json is auto-discovered — either use inline object or remove the field')

if errors:
    for e in errors:
        print(f'ERROR:{e}')
else:
    print(f'OK:{data[\"name\"]}')
" 2>&1)

    while IFS= read -r line; do
      if [[ "$line" == OK:* ]]; then
        pass "plugin.json: ${line#OK:}"
      elif [[ "$line" == ERROR:* ]]; then
        fail "${line#ERROR:}"
      fi
    done <<< "$pj_result"
  fi

  # ── plugin.json Path References ───────────────────────────────────
  section "5. plugin.json Path References ($plugin_name)"

  if [ -f "$PLUGIN_JSON" ]; then
    path_output=$(python3 -c "
import json, os, sys

with open('$PLUGIN_JSON') as f:
    data = json.load(f)

# Only commands and skills are valid string-path references in plugin.json.
# agents/, hooks/, and .mcp.json are auto-discovered — not declared.
path_keys = ['commands', 'skills']
for key in path_keys:
    if key not in data:
        continue
    ref = data[key]
    if not isinstance(ref, str):
        continue
    resolved = os.path.normpath(os.path.join('$PLUGIN_ROOT', ref))
    exists = os.path.exists(resolved)
    print(f'{\"PASS\" if exists else \"FAIL\"}:{key} -> {ref} ({resolved})')
" 2>&1)

    while IFS= read -r line; do
      status="${line%%:*}"
      msg="${line#*:}"
      if [ "$status" = "PASS" ]; then
        pass "$msg"
      else
        fail "$msg does not exist"
      fi
    done <<< "$path_output"
  fi

  # ── Directory Existence ───────────────────────────────────────────
  section "6. Directory Existence ($plugin_name)"

  # commands/ and skills/ are expected if declared in plugin.json
  # agents/ and hooks/ are optional (auto-discovered)
  for dir in commands skills; do
    target="$PLUGIN_ROOT/$dir"
    if [ -d "$target" ]; then
      count=$(ls "$target" | wc -l | tr -d ' ')
      pass "$dir/ ($count entries)"
    else
      # Only fail if declared in plugin.json
      if [ -f "$PLUGIN_JSON" ] && python3 -c "
import json
with open('$PLUGIN_JSON') as f:
    data = json.load(f)
if '$dir' in data:
    exit(0)
exit(1)
" 2>/dev/null; then
        fail "$dir/ not found (declared in plugin.json)"
      else
        warn "$dir/ not found"
      fi
    fi
  done

  for dir in agents hooks; do
    target="$PLUGIN_ROOT/$dir"
    if [ -d "$target" ]; then
      count=$(ls "$target" | wc -l | tr -d ' ')
      pass "$dir/ ($count entries)"
    else
      warn "$dir/ not found (optional)"
    fi
  done

  # ── Command Frontmatter ───────────────────────────────────────────
  section "7. Command Frontmatter ($plugin_name)"

  local cmd_found=false
  for file in "$PLUGIN_ROOT"/commands/*.md; do
    [ -f "$file" ] || continue
    cmd_found=true
    base="$(basename "$file")"

    first_line=$(head -1 "$file")
    if [ "$first_line" != "---" ]; then
      fail "$base: missing YAML frontmatter"
      continue
    fi

    fm=$(frontmatter "$file")
    desc=$(yaml_val "$fm" "description")
    if [ -z "$desc" ]; then
      fail "$base: missing description in frontmatter"
    else
      pass "$base"
    fi
  done

  if [ "$cmd_found" = false ]; then
    warn "No commands found"
  fi

  # ── Skill Frontmatter ─────────────────────────────────────────────
  section "8. Skill Frontmatter ($plugin_name)"

  local skill_found=false
  for file in "$PLUGIN_ROOT"/skills/*/SKILL.md; do
    [ -f "$file" ] || continue
    dirname="$(basename "$(dirname "$file")")"

    # Skip _shared
    [ "$dirname" = "_shared" ] && continue
    skill_found=true

    first_line=$(head -1 "$file")
    if [ "$first_line" != "---" ]; then
      fail "$dirname/SKILL.md: missing YAML frontmatter"
      continue
    fi

    fm=$(frontmatter "$file")
    skill_ok=true

    # name
    name_val=$(yaml_val "$fm" "name")
    if [ -z "$name_val" ]; then
      fail "$dirname: missing 'name' field"
      skill_ok=false
    elif [ "$name_val" != "$dirname" ]; then
      fail "$dirname: name '$name_val' does not match directory"
      skill_ok=false
    fi

    # description — must exist and not be quoted
    desc_val=$(yaml_val "$fm" "description")
    if [ -z "$desc_val" ]; then
      fail "$dirname: missing 'description' field"
      skill_ok=false
    elif [[ "$desc_val" == \"* ]] || [[ "$desc_val" == \'* ]] || [[ "$desc_val" == ">"* ]]; then
      fail "$dirname: description must not be quoted"
      skill_ok=false
    fi

    # user-invocable — must be explicit true or false
    ui_val=$(yaml_val "$fm" "user-invocable")
    if [ -z "$ui_val" ]; then
      fail "$dirname: missing 'user-invocable' field"
      skill_ok=false
    elif [ "$ui_val" != "true" ] && [ "$ui_val" != "false" ]; then
      fail "$dirname: user-invocable must be 'true' or 'false', got '$ui_val'"
      skill_ok=false
    fi

    # allowed-tools — must be comma-separated string, not YAML array
    at_val=$(yaml_val "$fm" "allowed-tools")
    if [ -n "$at_val" ]; then
      # Check if next line after allowed-tools starts with "- " (YAML array)
      next_line=$(sed -n '/^allowed-tools:/{ n; p; }' "$file")
      if [[ "$next_line" =~ ^[[:space:]]*-[[:space:]] ]]; then
        fail "$dirname: allowed-tools must be comma-separated string, not YAML array"
        skill_ok=false
      else
        pass "$dirname: allowed-tools format ok"
      fi
    fi

    # argument-hint — must be top-level, not nested under metadata
    ah_in_meta=$(echo "$fm" | sed -n '/^metadata:/,/^[^ ]/p' | grep "argument-hint:" || true)
    ah_toplevel=$(echo "$fm" | grep "^argument-hint:" || true)
    if [ -n "$ah_in_meta" ]; then
      fail "$dirname: argument-hint must be top-level, not nested under metadata"
      skill_ok=false
    elif [ -n "$ah_toplevel" ]; then
      pass "$dirname: argument-hint is top-level"
    fi

    # agent reference — verify file exists
    agent_val=$(yaml_val "$fm" "agent")
    if [ -n "$agent_val" ]; then
      agent_file="$PLUGIN_ROOT/agents/$agent_val.md"
      if [ -f "$agent_file" ]; then
        pass "$dirname: agent '$agent_val' exists"
      else
        fail "$dirname: agent '$agent_val' references missing file agents/$agent_val.md"
        skill_ok=false
      fi
    fi

    # license — verify LICENSE file exists
    license_val=$(yaml_val "$fm" "license")
    if [ -n "$license_val" ]; then
      skill_dir="$(dirname "$file")"
      if [ -f "$skill_dir/LICENSE" ] || [ -f "$skill_dir/LICENSE.txt" ] || \
         [ -f "$PLUGIN_ROOT/LICENSE" ] || [ -f "$PLUGIN_ROOT/LICENSE.txt" ]; then
        pass "$dirname: LICENSE file found"
      else
        fail "$dirname: declares license '$license_val' but no LICENSE file in skill dir or plugin root"
        skill_ok=false
      fi
    fi

    if [ "$skill_ok" = true ]; then
      pass "$dirname"
    fi
  done

  if [ "$skill_found" = false ]; then
    warn "No skills found"
  fi

  # ── Agent Frontmatter ─────────────────────────────────────────────
  section "9. Agent Frontmatter ($plugin_name)"

  local agent_found=false
  for file in "$PLUGIN_ROOT"/agents/*.md; do
    [ -f "$file" ] || continue
    agent_found=true
    base="$(basename "$file" .md)"

    first_line=$(head -1 "$file")
    if [ "$first_line" != "---" ]; then
      fail "$base: missing YAML frontmatter"
      continue
    fi

    fm=$(frontmatter "$file")
    agent_ok=true

    # name must match filename
    name_val=$(yaml_val "$fm" "name")
    if [ -z "$name_val" ]; then
      fail "$base: missing 'name' field"
      agent_ok=false
    elif [ "$name_val" != "$base" ]; then
      fail "$base: name '$name_val' does not match filename"
      agent_ok=false
    fi

    # description
    desc_val=$(yaml_val "$fm" "description")
    if [ -z "$desc_val" ]; then
      fail "$base: missing 'description' field"
      agent_ok=false
    fi

    # model
    model_val=$(yaml_val "$fm" "model")
    if [ -z "$model_val" ]; then
      fail "$base: missing 'model' field"
      agent_ok=false
    elif [ "$model_val" != "opus" ] && [ "$model_val" != "sonnet" ] && [ "$model_val" != "haiku" ]; then
      fail "$base: model must be opus/sonnet/haiku, got '$model_val'"
      agent_ok=false
    fi

    # tools — must be comma-separated string
    tools_val=$(yaml_val "$fm" "tools")
    if [ -z "$tools_val" ]; then
      fail "$base: missing 'tools' field"
      agent_ok=false
    else
      next_line=$(sed -n '/^tools:/{ n; p; }' "$file")
      if [[ "$next_line" =~ ^[[:space:]]*-[[:space:]] ]]; then
        fail "$base: tools must be comma-separated string, not YAML array"
        agent_ok=false
      fi
    fi

    if [ "$agent_ok" = true ]; then
      pass "$base"
    fi
  done

  if [ "$agent_found" = false ]; then
    warn "No agents found (optional)"
  fi

  # ── Cross-References ──────────────────────────────────────────────
  section "10. Cross-References ($plugin_name)"

  # Collect all agent references from skills
  local -a referenced_agents=()
  for file in "$PLUGIN_ROOT"/skills/*/SKILL.md; do
    [ -f "$file" ] || continue
    dirname="$(basename "$(dirname "$file")")"
    [ "$dirname" = "_shared" ] && continue

    fm=$(frontmatter "$file")
    agent_val=$(yaml_val "$fm" "agent")
    if [ -n "$agent_val" ]; then
      referenced_agents+=("$agent_val")
      agent_file="$PLUGIN_ROOT/agents/$agent_val.md"
      if [ ! -f "$agent_file" ]; then
        fail "Skill '$dirname' references agent '$agent_val' — file missing"
      fi
    fi
  done

  # Check for orphan agents
  for file in "$PLUGIN_ROOT"/agents/*.md; do
    [ -f "$file" ] || continue
    base="$(basename "$file" .md)"
    found=false
    for ref in "${referenced_agents[@]+"${referenced_agents[@]}"}"; do
      if [ "$ref" = "$base" ]; then
        found=true
        break
      fi
    done
    if [ "$found" = true ]; then
      pass "Agent '$base' is referenced by a skill"
    else
      warn "Agent '$base' is not referenced by any skill (orphan)"
    fi
  done

  # plugin.json name matches marketplace entry
  if [ -f "$MARKETPLACE" ] && [ -f "$PLUGIN_JSON" ]; then
    match_result=$(python3 -c "
import json
with open('$MARKETPLACE') as f:
    mp = json.load(f)
with open('$PLUGIN_JSON') as f:
    pj = json.load(f)
pj_name = pj.get('name', '')
mp_names = [p.get('name', '') for p in mp.get('plugins', [])]
if pj_name in mp_names:
    print(f'PASS:plugin.json name \"{pj_name}\" found in marketplace')
else:
    print(f'FAIL:plugin.json name \"{pj_name}\" not found in marketplace plugins ({mp_names})')
" 2>&1)
    status="${match_result%%:*}"
    msg="${match_result#*:}"
    if [ "$status" = "PASS" ]; then
      pass "$msg"
    else
      fail "$msg"
    fi
  fi

  # ── Hooks Structure ──────────────────────────────────────────────
  section "11. Hooks Structure ($plugin_name)"

  if [ -f "$HOOKS_JSON" ]; then
    hooks_result=$(python3 -c "
import json, sys

with open('$HOOKS_JSON') as f:
    data = json.load(f)

errors = []
hooks = data.get('hooks')
if hooks is None:
    errors.append('Missing top-level \"hooks\" key')
else:
    valid_events = ['PreToolUse', 'PostToolUse', 'SessionStart']
    for event, handlers in hooks.items():
        if event not in valid_events:
            errors.append(f'Unknown event: {event} (expected one of {valid_events})')
            continue
        for i, handler in enumerate(handlers):
            for hook in handler.get('hooks', []):
                htype = hook.get('type')
                if htype not in ('prompt', 'command'):
                    errors.append(f'{event}[{i}]: hook type must be prompt or command, got {htype}')
                else:
                    print(f'OK:{event} -> {htype} hook')

for e in errors:
    print(f'ERROR:{e}')
" 2>&1)

    while IFS= read -r line; do
      if [[ "$line" == OK:* ]]; then
        pass "${line#OK:}"
      elif [[ "$line" == ERROR:* ]]; then
        fail "${line#ERROR:}"
      fi
    done <<< "$hooks_result"
  else
    warn "hooks.json not found (optional)"
  fi

  # ── Plugin Summary ───────────────────────────────────────────────
  local cmd_count=0
  for f in "$PLUGIN_ROOT"/commands/*.md; do [ -f "$f" ] && cmd_count=$((cmd_count + 1)); done

  local skill_count=0
  for f in "$PLUGIN_ROOT"/skills/*/SKILL.md; do
    [ -f "$f" ] || continue
    d="$(basename "$(dirname "$f")")"
    [ "$d" = "_shared" ] && continue
    skill_count=$((skill_count + 1))
  done

  local agent_count=0
  for f in "$PLUGIN_ROOT"/agents/*.md; do [ -f "$f" ] && agent_count=$((agent_count + 1)); done

  printf "\n  \033[1m%s\033[0m — Commands: %d, Skills: %d, Agents: %d\n" "$plugin_name" "$cmd_count" "$skill_count" "$agent_count"
}

# ══════════════════════════════════════════════════════════════════════
# Run validation for each plugin
# ══════════════════════════════════════════════════════════════════════

for plugin_dir in "${plugin_dirs[@]}"; do
  validate_plugin "$plugin_dir"
done

# ══════════════════════════════════════════════════════════════════════
# Section 12 — Summary
# ══════════════════════════════════════════════════════════════════════
section "Summary"

echo "  Plugins validated: ${#plugin_dirs[@]}"
echo ""

if [ "$errors" -gt 0 ]; then
  printf "  \033[31m%d error(s)\033[0m, %d warning(s)\n" "$errors" "$warnings"
  echo ""
  exit 1
else
  if [ "$warnings" -gt 0 ]; then
    printf "  \033[32m0 errors\033[0m, \033[33m%d warning(s)\033[0m\n" "$warnings"
  else
    printf "  \033[32mAll checks passed\033[0m\n"
  fi
  echo ""
  exit 0
fi
