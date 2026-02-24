#!/usr/bin/env bash
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ln -sf "$REPO_ROOT/.githooks/pre-push" "$REPO_ROOT/.git/hooks/pre-push"
echo "Pre-push hook installed."
