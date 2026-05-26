#!/usr/bin/env bash
# =============================================================================
# antigravity.sh — Antigravity IDE-specific install phases
# =============================================================================
# Handles: Skills to ~/.agents/skills, MCP wiring, agentmemory connect
# Note: GSD is Cursor-exclusive. Antigravity gets skills + MCP + memory stack.
# =============================================================================

# Determine Antigravity MCP config path
case "$OS" in
    darwin) ANTIGRAVITY_USER_DIR="$HOME/Library/Application Support/Antigravity/User" ;;
    linux)  ANTIGRAVITY_USER_DIR="$HOME/.config/Antigravity/User" ;;
    *)      ANTIGRAVITY_USER_DIR="$HOME/.config/Antigravity/User" ;;
esac

ANTIGRAVITY_SKILLS="$HOME/.agents/skills"
ANTIGRAVITY_MCP="$ANTIGRAVITY_USER_DIR/mcp_config.json"

# ── Phase A1 — Skills directory ──────────────────────────────────────────────
phase "A1" "antigravity skills → ~/.agents/skills (development,backend)"

mkdir -p "$ANTIGRAVITY_SKILLS"
echo -n "  Installing antigravity skills (development,backend, risk=safe) ... "
npx --yes antigravity-awesome-skills \
    --path "$ANTIGRAVITY_SKILLS" \
    --category development,backend \
    --risk safe 2>/dev/null \
    && echo -e "${GREEN}ok${NC}" \
    || echo -e "${YELLOW}WARN — antigravity install failed (non-fatal)${NC}"

# ui-ux-pro-max skill
if [ ! -d "$ANTIGRAVITY_SKILLS/ui-ux-pro-max" ]; then
    echo -n "  Installing ui-ux-pro-max skill ... "
    git clone --depth 1 "https://github.com/nextlevelbuilder/ui-ux-pro-max-skill" \
        "$ANTIGRAVITY_SKILLS/ui-ux-pro-max" 2>/dev/null \
        && echo -e "${GREEN}ok${NC}" \
        || echo -e "${YELLOW}WARN — clone failed (non-fatal)${NC}"
else
    info "ui-ux-pro-max already installed"
fi

SKILL_COUNT=$(find "$ANTIGRAVITY_SKILLS" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
ok "Total skills installed: $SKILL_COUNT"

# ── Phase A2 — agentmemory connect antigravity ───────────────────────────────
phase "A2" "agentmemory → Antigravity MCP"

if command -v agentmemory &>/dev/null; then
    agentmemory connect antigravity 2>/dev/null && ok "agentmemory connect antigravity done" \
        || warn "agentmemory connect antigravity returned non-zero — check manually"
else
    warn "agentmemory not on PATH yet — run: agentmemory connect antigravity"
fi

# ── Phase A3 — Ensure playwright + github in mcp_config.json ─────────────────
phase "A3" "Ensure playwright + github in Antigravity mcp_config.json"

mkdir -p "$ANTIGRAVITY_USER_DIR"

merge_mcp_antigravity() {
python3 - "$ANTIGRAVITY_MCP" <<'PY'
import json, os, sys
p = sys.argv[1]
try:
    with open(p) as f:
        d = json.load(f)
except Exception:
    d = {}
s = d.setdefault("mcpServers", {})
changed = False
if "playwright" not in s:
    s["playwright"] = {"command": "npx", "args": ["-y", "@playwright/mcp@latest"]}
    changed = True
if "github" not in s:
    s["github"] = {
        "url": "https://api.githubcopilot.com/mcp/",
        "headers": {"Authorization": "Bearer ${env:GITHUB_PERSONAL_ACCESS_TOKEN}"}
    }
    changed = True
if changed:
    with open(p, "w") as f:
        json.dump(d, f, indent=2)
        f.write("\n")
    print("Antigravity MCP: ensured playwright + github entries")
else:
    print("Antigravity MCP: all entries already present")
PY
}

if command -v python3 &>/dev/null; then
    merge_mcp_antigravity && ok "Antigravity mcp_config.json updated" || warn "mcp merge failed"
elif command -v node &>/dev/null; then
    node -e "
const fs=require('fs'), path=require('path'), p='$ANTIGRAVITY_MCP';
let d={}; try{d=JSON.parse(fs.readFileSync(p,'utf8'))}catch(e){}
const s=d.mcpServers||(d.mcpServers={});
if(!s.playwright) s.playwright={command:'npx',args:['-y','@playwright/mcp@latest']};
if(!s.github) s.github={url:'https://api.githubcopilot.com/mcp/',headers:{Authorization:'Bearer \${env:GITHUB_PERSONAL_ACCESS_TOKEN}'}};
fs.mkdirSync(path.dirname(p),{recursive:true});
fs.writeFileSync(p,JSON.stringify(d,null,2)+'\n');
console.log('Antigravity MCP: ensured entries');
" && ok "Antigravity mcp_config.json updated (node fallback)"
else
    cat > "$ANTIGRAVITY_MCP" << 'EOF'
{
  "mcpServers": {
    "agentmemory": {
      "command": "npx",
      "args": ["-y", "@agentmemory/mcp"],
      "env": { "AGENTMEMORY_URL": "http://localhost:3111" }
    },
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    },
    "github": {
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": { "Authorization": "Bearer ${env:GITHUB_PERSONAL_ACCESS_TOKEN}" }
    }
  }
}
EOF
    ok "Created Antigravity mcp_config.json"
fi

ok "Antigravity install complete (skills + MCP + memory). GSD commands are Cursor-exclusive."
info "Skills installed at: $ANTIGRAVITY_SKILLS"
info "MCP config at: $ANTIGRAVITY_MCP"
