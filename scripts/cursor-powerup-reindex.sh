#!/usr/bin/env bash
# Refresh CodeGraph + GitNexus after phase execution or manual request.
# Installed to ~/.cursor/get-shit-done/scripts/ by install.sh
set -euo pipefail

export PATH="${HOME}/.npm-global/bin:${HOME}/.local/bin:${PATH}"

echo "=== Cursor Power-Up Re-index ==="

REINDEXED=0

if [ -d .codegraph ] && command -v codegraph >/dev/null 2>&1; then
  echo "→ CodeGraph index..."
  codegraph index 2>/dev/null && REINDEXED=1 || echo "  WARN: codegraph index failed"
elif command -v codegraph >/dev/null 2>&1; then
  echo "→ CodeGraph init + index..."
  codegraph init -i 2>/dev/null || codegraph init 2>/dev/null || true
  codegraph index 2>/dev/null && REINDEXED=1 || echo "  WARN: codegraph index failed"
else
  echo "  SKIP CodeGraph (CLI not on PATH — add ~/.npm-global/bin to PATH)"
fi

if [ -d .git ]; then
  echo "→ GitNexus analyze..."
  if npx --yes gitnexus analyze 2>/dev/null; then
    REINDEXED=1
  else
    echo "  WARN: gitnexus analyze failed"
  fi
else
  echo "  SKIP GitNexus (not a git repo)"
fi

if [ -f .planning/CURSOR-POWERUP.md ]; then
  {
    echo ""
    echo "## Last re-index: $(date +%Y-%m-%dT%H:%M)"
  } >> .planning/CURSOR-POWERUP.md
fi

echo ""
echo "=== Manual checks (cannot be automated) ==="
if curl -sf --max-time 2 http://localhost:3111/agentmemory/health >/dev/null 2>&1; then
  echo "  OK   agentmemory server"
else
  echo "  !!   Start agentmemory: run 'agentmemory' in a terminal"
fi
if [ -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]; then
  echo "  OK   GITHUB_PERSONAL_ACCESS_TOKEN is set"
else
  echo "  !!   Set GitHub PAT: export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_... in ~/.zshrc"
fi

echo ""
[ "$REINDEXED" -eq 1 ] && echo "Re-index complete." || echo "Re-index finished with warnings."
