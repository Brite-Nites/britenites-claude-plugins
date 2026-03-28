#!/usr/bin/env bash
set -euo pipefail

# ── Template-Driven Skill Documentation Generator ────────────────────
# Generates SKILL.md from .tmpl templates with shared block resolution.
#
# Usage:
#   bash scripts/gen-skill-docs.sh              # Generate all
#   bash scripts/gen-skill-docs.sh --check       # Dry-run: exit 1 if stale
#   bash scripts/gen-skill-docs.sh --skill NAME  # Process single skill
# ─────────────────────────────────────────────────────────────────────

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# ── Prereqs ──────────────────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
  echo "ERROR: python3 is required but not found." >&2
  exit 2
fi

# ── Run generator ────────────────────────────────────────────────────
exec python3 "$REPO_ROOT/scripts/gen-skill-docs.py" "$@"
