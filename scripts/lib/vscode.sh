#!/usr/bin/env bash
# =============================================================================
# vscode.sh — GitHub Copilot (VS Code) extras
# =============================================================================
# Skill packs, bundled skills, MCP servers (user mcp.json, "servers" key) and
# rules (~/.copilot/instructions/) are applied by scripts/lib/powerup.mjs.
# This file only adds the legacy antigravity-awesome-skills bundle.
# =============================================================================

COPILOT_SKILLS="$HOME/.copilot/skills"   # read natively by Copilot agent mode

phase "V1" "antigravity skills → ~/.copilot/skills (development,backend)"

mkdir -p "$COPILOT_SKILLS"
echo -n "  Installing antigravity skills (development,backend, risk=safe) ... "
npx --yes antigravity-awesome-skills \
    --path "$COPILOT_SKILLS" \
    --category development,backend \
    --risk safe 2>/dev/null \
    && echo -e "${GREEN}ok${NC}" \
    || echo -e "${YELLOW}WARN — antigravity install failed (non-fatal)${NC}"

info "Enable 'chat.mcp.discovery.enabled' in VS Code settings for MCP tools"
