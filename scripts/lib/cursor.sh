#!/usr/bin/env bash
# =============================================================================
# cursor.sh — Cursor-specific install phases
# =============================================================================
# Handles: GSD copy, MCP wiring, agentmemory connect, skills, hooks
# =============================================================================

CURSOR_DIR="$HOME/.cursor"
CURSOR_SKILLS="$CURSOR_DIR/skills"
CURSOR_MCP="$CURSOR_DIR/mcp.json"

phase "C1" "Copy GSD files to ~/.cursor (Cursor-exclusive)"

if [ ! -d "$SOURCE_PATH" ]; then
    echo -e "  ${RED}ERROR: Source path not found: $SOURCE_PATH${NC}"
    exit 1
fi

if [ -d "$CURSOR_DIR/get-shit-done" ] && [ "$FORCE" = false ]; then
    echo -e "  ${YELLOW}Existing GSD installation found at: $CURSOR_DIR/get-shit-done${NC}"
    if [[ "$NON_INTERACTIVE" = true ]]; then
        info "Non-interactive mode — overwriting"
    else
        read -r -p "  Overwrite? (y/N) " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo -e "  ${CYAN}Skipping GSD file copy.${NC}"
        fi
    fi
fi

directories=(
    "commands/gsd"
    "agents"
    "get-shit-done/workflows"
    "get-shit-done/templates"
    "get-shit-done/templates/codebase"
    "get-shit-done/templates/research-project"
    "get-shit-done/references"
    "get-shit-done/scripts"
    "hooks"
    "skills"
    "cache"
    "repos"
)

for dir in "${directories[@]}"; do
    mkdir -p "$CURSOR_DIR/$dir"
done
ok "Directory structure ready"

copy_dir() {
    local src_dir="$1" dest_dir="$2" label="$3"
    if [ -d "$src_dir" ]; then
        local abs_src="$(cd "$src_dir" && pwd)"
        find "$abs_src" -type f | while read -r file; do
            local rel="${file#$abs_src/}"
            local dst="$dest_dir/$rel"
            mkdir -p "$(dirname "$dst")"
            cp "$file" "$dst"
        done
        ok "Copied $label"
    else
        info "SKIPPED (not found): $label"
    fi
}

copy_dir "$SOURCE_PATH/commands/gsd"  "$CURSOR_DIR/commands/gsd"              "commands/gsd"
copy_dir "$SOURCE_PATH/agents"        "$CURSOR_DIR/agents"                    "agents"
copy_dir "$SOURCE_PATH/workflows"     "$CURSOR_DIR/get-shit-done/workflows"   "workflows"
copy_dir "$SOURCE_PATH/templates"     "$CURSOR_DIR/get-shit-done/templates"   "templates"
copy_dir "$SOURCE_PATH/references"    "$CURSOR_DIR/get-shit-done/references"  "references"
copy_dir "$SOURCE_PATH/hooks"         "$CURSOR_DIR/hooks"                     "hooks"

REINDEX_SRC="$SCRIPT_DIR/cursor-powerup-reindex.sh"
if [ -f "$REINDEX_SRC" ]; then
    cp "$REINDEX_SRC" "$CURSOR_DIR/get-shit-done/scripts/cursor-powerup-reindex.sh"
    chmod +x "$CURSOR_DIR/get-shit-done/scripts/cursor-powerup-reindex.sh"
    ok "Copied cursor-powerup-reindex.sh"
fi

# Bundled repo skills (gsd-for-cursor, animation-designer, ...)
source "$SCRIPT_DIR/lib/bundled-skills.sh"
install_bundled_skills "$CURSOR_SKILLS"
ok "Bundled skills from src/skills/"

# Cursor settings.json (hooks + statusline)
settings_path="$CURSOR_DIR/settings.json"
if command -v jq &>/dev/null && [ -f "$settings_path" ]; then
    jq '. + {
        "hooks": {
            "SessionStart": [{"hooks": [
                {"type":"command","command":"node ~/.cursor/hooks/gsd-check-update.js"},
                {"type":"command","command":"node ~/.cursor/hooks/gsd-powerup-reminder.js"}
            ]}]
        },
        "statusLine": {"type":"command","command":"node ~/.cursor/hooks/gsd-statusline.js"}
    }' "$settings_path" > "$settings_path.tmp" && mv "$settings_path.tmp" "$settings_path"
    ok "Merged hooks into settings.json"
else
    cat > "$settings_path" << 'SETTINGS'
{
    "hooks": {
        "SessionStart": [
            {
                "hooks": [
                    {"type": "command", "command": "node ~/.cursor/hooks/gsd-check-update.js"},
                    {"type": "command", "command": "node ~/.cursor/hooks/gsd-powerup-reminder.js"}
                ]
            }
        ]
    },
    "statusLine": {
        "type": "command",
        "command": "node ~/.cursor/hooks/gsd-statusline.js"
    }
}
SETTINGS
    ok "Created settings.json"
fi

echo "2.0.0" > "$CURSOR_DIR/get-shit-done/VERSION"

# ── Phase C2 — agentmemory connect cursor ────────────────────────────────────
phase "C2" "agentmemory → Cursor MCP"

if command -v agentmemory &>/dev/null; then
    agentmemory connect cursor 2>/dev/null && ok "agentmemory connect cursor done" \
        || warn "agentmemory connect cursor returned non-zero — check manually"
else
    warn "agentmemory not on PATH yet — open a new terminal and run: agentmemory connect cursor"
    info "  (PATH will include ~/.npm-global/bin after restarting your shell)"
fi

# ── Phase C3 — Ensure playwright + github in mcp.json ────────────────────────
phase "C3" "Ensure playwright + github in Cursor mcp.json"

merge_mcp_cursor() {
python3 - <<'PY'
import json, os
p = os.path.expanduser("~/.cursor/mcp.json")
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
    print("MCP: ensured playwright + github entries")
else:
    print("MCP: playwright + github already present")
PY
}

if command -v python3 &>/dev/null; then
    merge_mcp_cursor && ok "Cursor mcp.json updated" || warn "mcp.json merge failed"
elif command -v node &>/dev/null; then
    node - "$CURSOR_MCP" <<'JS'
const fs=require('fs'), p=process.argv[1];
let d={}; try{d=JSON.parse(fs.readFileSync(p,'utf8'))}catch(e){}
const s=d.mcpServers||(d.mcpServers={});
if(!s.playwright) s.playwright={command:'npx',args:['-y','@playwright/mcp@latest']};
if(!s.github) s.github={url:'https://api.githubcopilot.com/mcp/',headers:{Authorization:'Bearer ${env:GITHUB_PERSONAL_ACCESS_TOKEN}'}};
fs.writeFileSync(p,JSON.stringify(d,null,2)+'\n');
console.log('MCP: ensured playwright + github');
JS
    ok "Cursor mcp.json updated (node fallback)"
else
    mkdir -p "$CURSOR_DIR"
    cat > "$CURSOR_MCP" << 'EOF'
{
  "mcpServers": {
    "agentmemory": {
      "command": "npx",
      "args": ["-y", "@agentmemory/mcp"],
      "env": { "AGENTMEMORY_URL": "${AGENTMEMORY_URL:-http://localhost:3111}" }
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
    ok "Created Cursor mcp.json with agentmemory, playwright, github"
fi

# ── Phase C4 — antigravity skills (development,backend) ──────────────────────
phase "C4" "antigravity skills → ~/.cursor/skills (development,backend)"

mkdir -p "$CURSOR_SKILLS"
echo -n "  Installing antigravity skills (development,backend, risk=safe) ... "
npx --yes antigravity-awesome-skills \
    --path "$CURSOR_SKILLS" \
    --category development,backend \
    --risk safe 2>/dev/null \
    && echo -e "${GREEN}ok${NC}" \
    || echo -e "${YELLOW}WARN — antigravity install failed (non-fatal)${NC}"

# ui-ux-pro-max skill
if [ ! -d "$CURSOR_SKILLS/ui-ux-pro-max" ]; then
    echo -n "  Installing ui-ux-pro-max skill ... "
    git clone --depth 1 "https://github.com/nextlevelbuilder/ui-ux-pro-max-skill" \
        "$CURSOR_SKILLS/ui-ux-pro-max" 2>/dev/null \
        && echo -e "${GREEN}ok${NC}" \
        || echo -e "${YELLOW}WARN — clone failed (non-fatal)${NC}"
else
    info "ui-ux-pro-max already installed"
fi

# Count installed skills
SKILL_COUNT=$(find "$CURSOR_SKILLS" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
ok "Total skills installed: $SKILL_COUNT"
