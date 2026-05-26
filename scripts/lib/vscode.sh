#!/usr/bin/env bash
# =============================================================================
# vscode.sh — VS Code-specific install phases
# =============================================================================
# Handles: Skills copy, MCP wiring (user-level), agentmemory MCP
# Note: GSD is Cursor-exclusive. VS Code gets skills + MCP + memory stack.
# =============================================================================

# Determine VS Code user-level MCP path
case "$OS" in
    darwin) VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User" ;;
    linux)  VSCODE_USER_DIR="$HOME/.config/Code/User" ;;
    *)      VSCODE_USER_DIR="$HOME/.config/Code/User" ;;
esac

VSCODE_SKILLS="$HOME/.vscode/skills"
VSCODE_MCP="$VSCODE_USER_DIR/mcp.json"

# ── Phase V1 — Skills directory ──────────────────────────────────────────────
phase "V1" "antigravity skills → ~/.vscode/skills (development,backend)"

mkdir -p "$VSCODE_SKILLS"
echo -n "  Installing antigravity skills (development,backend, risk=safe) ... "
npx --yes antigravity-awesome-skills \
    --path "$VSCODE_SKILLS" \
    --category development,backend \
    --risk safe 2>/dev/null \
    && echo -e "${GREEN}ok${NC}" \
    || echo -e "${YELLOW}WARN — antigravity install failed (non-fatal)${NC}"

# ui-ux-pro-max skill
if [ ! -d "$VSCODE_SKILLS/ui-ux-pro-max" ]; then
    echo -n "  Installing ui-ux-pro-max skill ... "
    git clone --depth 1 "https://github.com/nextlevelbuilder/ui-ux-pro-max-skill" \
        "$VSCODE_SKILLS/ui-ux-pro-max" 2>/dev/null \
        && echo -e "${GREEN}ok${NC}" \
        || echo -e "${YELLOW}WARN — clone failed (non-fatal)${NC}"
else
    info "ui-ux-pro-max already installed"
fi

SKILL_COUNT=$(find "$VSCODE_SKILLS" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
ok "Total skills installed: $SKILL_COUNT"

# ── Phase V2 — MCP configuration ─────────────────────────────────────────────
phase "V2" "MCP wiring → VS Code user config"

mkdir -p "$VSCODE_USER_DIR"

merge_mcp_vscode() {
python3 - "$VSCODE_MCP" <<'PY'
import json, os, sys
p = sys.argv[1]
try:
    with open(p) as f:
        d = json.load(f)
except Exception:
    d = {}
s = d.setdefault("servers", {})
changed = False
if "agentmemory" not in s:
    s["agentmemory"] = {
        "command": "npx",
        "args": ["-y", "@agentmemory/mcp"],
        "env": {"AGENTMEMORY_URL": "http://localhost:3111"}
    }
    changed = True
if "playwright" not in s:
    s["playwright"] = {"command": "npx", "args": ["-y", "@playwright/mcp@latest"]}
    changed = True
if "github" not in s:
    s["github"] = {
        "type": "http",
        "url": "https://api.githubcopilot.com/mcp/"
    }
    changed = True
if changed:
    with open(p, "w") as f:
        json.dump(d, f, indent=2)
        f.write("\n")
    print("VS Code MCP: ensured agentmemory + playwright + github")
else:
    print("VS Code MCP: all entries already present")
PY
}

if command -v python3 &>/dev/null; then
    merge_mcp_vscode && ok "VS Code mcp.json updated" || warn "VS Code mcp.json merge failed"
elif command -v node &>/dev/null; then
    node -e "
const fs=require('fs'), p='$VSCODE_MCP';
let d={}; try{d=JSON.parse(fs.readFileSync(p,'utf8'))}catch(e){}
const s=d.servers||(d.servers={});
if(!s.agentmemory) s.agentmemory={command:'npx',args:['-y','@agentmemory/mcp'],env:{AGENTMEMORY_URL:'http://localhost:3111'}};
if(!s.playwright) s.playwright={command:'npx',args:['-y','@playwright/mcp@latest']};
if(!s.github) s.github={type:'http',url:'https://api.githubcopilot.com/mcp/'};
fs.mkdirSync(require('path').dirname(p),{recursive:true});
fs.writeFileSync(p,JSON.stringify(d,null,2)+'\n');
console.log('VS Code MCP: ensured entries');
" && ok "VS Code mcp.json updated (node fallback)"
else
    cat > "$VSCODE_MCP" << 'EOF'
{
  "servers": {
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
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    }
  }
}
EOF
    ok "Created VS Code mcp.json"
fi

ok "VS Code install complete (skills + MCP). GSD commands are Cursor-exclusive."
info "Skills installed at: $VSCODE_SKILLS"
info "MCP config at: $VSCODE_MCP"
info "Note: Enable 'chat.mcp.discovery.enabled' in VS Code settings for MCP tools"
