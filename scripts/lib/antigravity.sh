#!/usr/bin/env bash
# =============================================================================
# antigravity.sh — Google Antigravity (IDE + agy CLI) extras
# =============================================================================
# Skill packs, bundled skills, MCP servers (~/.gemini/config/mcp_config.json,
# "serverUrl" for remote servers) and rules (~/.gemini/GEMINI.md) are applied by
# scripts/lib/powerup.mjs. This file adds agentmemory + the awesome-skills bundle.
# =============================================================================

ANTIGRAVITY_SKILLS="$HOME/.gemini/antigravity/skills"

phase "A1" "antigravity skills → ~/.gemini/antigravity/skills (development,backend)"

mkdir -p "$ANTIGRAVITY_SKILLS"
echo -n "  Installing antigravity skills (development,backend, risk=safe) ... "
npx --yes antigravity-awesome-skills \
    --path "$ANTIGRAVITY_SKILLS" \
    --category development,backend \
    --risk safe 2>/dev/null \
    && echo -e "${GREEN}ok${NC}" \
    || echo -e "${YELLOW}WARN — antigravity install failed (non-fatal)${NC}"

phase "A2" "agentmemory → Antigravity MCP"

if command -v agentmemory &>/dev/null; then
    agentmemory connect antigravity 2>/dev/null && ok "agentmemory connect antigravity done" \
        || warn "agentmemory connect antigravity returned non-zero — check manually"
else
    warn "agentmemory not on PATH yet — run: agentmemory connect antigravity"
fi
