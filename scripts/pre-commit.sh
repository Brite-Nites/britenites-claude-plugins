#!/usr/bin/env bash
set -euo pipefail

# ── Pre-Commit Quality Hook ──────────────────────────────────────────
# Runs linters on staged files by project type.
#
# Install as a git hook:
#   cp scripts/pre-commit.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# Or reference from husky/lefthook configs.
# ─────────────────────────────────────────────────────────────────────

errors=0

# ── Get staged files (excluding deleted) ─────────────────────────────
staged_files=()
while IFS= read -r f; do
  [ -n "$f" ] && staged_files+=("$f")
done < <(git diff --cached --name-only --diff-filter=d 2>/dev/null || true)

if [ "${#staged_files[@]}" -eq 0 ]; then
  exit 0
fi

# ── Detect project type ──────────────────────────────────────────────
is_js=false
is_python=false

[ -f "package.json" ] && is_js=true
{ [ -f "pyproject.toml" ] || [ -f "setup.py" ]; } && is_python=true

# ── JS/TS linting ────────────────────────────────────────────────────
if [ "$is_js" = true ]; then
  # Filter staged JS/TS files
  js_files=()
  for f in "${staged_files[@]}"; do
    case "$f" in
      *.js|*.jsx|*.ts|*.tsx) js_files+=("$f") ;;
    esac
  done

  if [ "${#js_files[@]}" -gt 0 ]; then
    # ESLint
    if command -v npx >/dev/null 2>&1 && npx --no-install eslint --version >/dev/null 2>&1; then
      echo "Running ESLint on staged files..."
      if ! npx --no-install eslint --no-error-on-unmatched-pattern -- "${js_files[@]}"; then
        echo ""
        echo "ESLint found issues. Fix with: npx eslint --fix <file>"
        errors=$((errors + 1))
      fi
    fi

    # TypeScript type checking
    # Note: tsc --noEmit checks the entire project (per tsconfig.json), not just staged files.
    # Pre-existing type errors in unstaged files will also block the commit.
    if [ -f "tsconfig.json" ] && command -v npx >/dev/null 2>&1 && npx --no-install tsc --version >/dev/null 2>&1; then
      echo "Running tsc --noEmit..."
      if ! npx --no-install tsc --noEmit; then
        echo ""
        echo "TypeScript found type errors."
        errors=$((errors + 1))
      fi
    fi
  fi
fi

# ── Python linting ───────────────────────────────────────────────────
if [ "$is_python" = true ]; then
  py_files=()
  for f in "${staged_files[@]}"; do
    case "$f" in
      *.py) py_files+=("$f") ;;
    esac
  done

  if [ "${#py_files[@]}" -gt 0 ]; then
    if command -v ruff >/dev/null 2>&1; then
      echo "Running Ruff on staged files..."
      if ! ruff check -- "${py_files[@]}"; then
        echo ""
        echo "Ruff found issues. Fix with: ruff check --fix <file>"
        errors=$((errors + 1))
      fi
    fi
  fi
fi

# ── Result ───────────────────────────────────────────────────────────
if [ "$errors" -gt 0 ]; then
  echo ""
  echo "Pre-commit checks failed. Fix the issues above before committing."
  exit 1
fi

exit 0
