#!/usr/bin/env bash
# =============================================================================
# cursor-powered-up — Unified Installer
# =============================================================================
# One script that does everything: GSD for Cursor + global power-up stack.
#
# Usage:
#   ./scripts/install.sh [--force] [--gsd-only] [--powerup-only]
#
# =============================================================================

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
NC='\033[0m'

# ── Args ──────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_PATH="$(cd "$SCRIPT_DIR/../src" && pwd)"
CURSOR_DIR="$HOME/.cursor"
FORCE=false
GSD_ONLY=false
POWERUP_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)      FORCE=true;        shift ;;
        --gsd-only)      GSD_ONLY=true;     shift ;;
        --powerup-only)  POWERUP_ONLY=true; shift ;;
        --help|-h)
            echo "Usage: $0 [--force] [--gsd-only] [--powerup-only]"
            echo ""
            echo "  --force          Overwrite existing installation without prompting"
            echo "  --gsd-only       Only copy GSD files (skip npm/MCP/skills phases)"
            echo "  --powerup-only   Only run power-up phases (skip GSD copy)"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

NPM_PREFIX="$HOME/.npm-global"
export PATH="${NPM_PREFIX}/bin:$HOME/.local/bin:${PATH}"

# ── Header ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║   cursor-powered-up  —  Full Installer   ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GRAY}Source:  $SOURCE_PATH${NC}"
echo -e "${GRAY}Target:  $CURSOR_DIR${NC}"
echo ""

# ── Phase helpers ─────────────────────────────────────────────────────────────
phase() { echo -e "\n${CYAN}${BOLD}▶ Phase $1: $2${NC}"; }
ok()    { echo -e "  ${GREEN}✓${NC} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC}  $1"; }
info()  { echo -e "  ${GRAY}  $1${NC}"; }

# =============================================================================
# PHASE 1 — Detect OS & check prerequisites
# =============================================================================
phase 1 "Detect OS & prerequisites"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "$OS" in
    darwin) ok "macOS detected" ;;
    linux)  ok "Linux detected" ;;
    *)      warn "Unknown OS: $OS — continuing anyway" ;;
esac

check_cmd() {
    local cmd="$1" pkg="$2" brew_pkg="${3:-$2}"
    if command -v "$cmd" &>/dev/null; then
        ok "$cmd found ($(command -v "$cmd"))"
    else
        echo -e "  ${RED}✗ $cmd not found${NC}"
        if [[ "$OS" == "darwin" ]]; then
            echo -e "    ${YELLOW}Install with: brew install $brew_pkg${NC}"
        else
            echo -e "    ${YELLOW}Install with: sudo apt-get install -y $pkg  (or your distro's package manager)${NC}"
        fi
        MISSING_PREREQS=1
    fi
}

MISSING_PREREQS=0

# Node version check
if command -v node &>/dev/null; then
    NODE_VER=$(node -e "process.stdout.write(process.version.replace('v','').split('.')[0])")
    if [[ "$NODE_VER" -ge 18 ]]; then
        ok "node v$(node --version | tr -d v) (≥18)"
    else
        echo -e "  ${RED}✗ node v$NODE_VER found but ≥18 required${NC}"
        [[ "$OS" == "darwin" ]] && echo -e "    ${YELLOW}Upgrade: brew upgrade node${NC}"
        MISSING_PREREQS=1
    fi
else
    echo -e "  ${RED}✗ node not found — node 18+ required${NC}"
    [[ "$OS" == "darwin" ]] && echo -e "    ${YELLOW}Install: brew install node${NC}"
    MISSING_PREREQS=1
fi

check_cmd npm   npm     node
check_cmd npx   npm     node
check_cmd git   git     git
check_cmd python3 python3 python3 || check_cmd python python3 python3 2>/dev/null || warn "python3 not found — MCP JSON merge will use fallback"

if [[ $MISSING_PREREQS -eq 1 ]] && [[ "$FORCE" = false ]]; then
    echo ""
    echo -e "  ${RED}One or more prerequisites are missing.${NC}"
    echo -e "  ${YELLOW}Install them then re-run, or use --force to skip this check.${NC}"
    exit 1
fi

# =============================================================================
# PHASE 2 — npm user prefix (no sudo)
# =============================================================================
if [[ "$GSD_ONLY" = false ]]; then
phase 2 "npm user prefix (no sudo)"

mkdir -p "${NPM_PREFIX}/bin"
npm config set prefix "$NPM_PREFIX" 2>/dev/null || true

add_path_line() {
    local file="$1"
    local line='export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"'
    if [[ -f "$file" ]]; then
        if ! grep -q 'npm-global/bin' "$file" 2>/dev/null; then
            echo "$line" >> "$file"
            ok "Added npm-global/bin to $file"
        else
            info "npm-global already in $file"
        fi
    fi
}

add_path_line "$HOME/.zshrc"
add_path_line "$HOME/.bashrc"
add_path_line "$HOME/.bash_profile"
fi  # end GSD_ONLY skip

# =============================================================================
# PHASE 3 — npm global tools
# =============================================================================
if [[ "$GSD_ONLY" = false ]]; then
phase 3 "npm global tools"

install_npm_global() {
    local pkg="$1"
    echo -n "  Installing $pkg ... "
    if npm install -g "$pkg" --prefix "$NPM_PREFIX" 2>/dev/null; then
        echo -e "${GREEN}ok${NC}"
    else
        echo -e "${YELLOW}WARN — retrying without prefix flag${NC}"
        npm install -g "$pkg" 2>/dev/null || warn "Failed to install $pkg — skip"
    fi
}

install_npm_global "@agentmemory/agentmemory"
install_npm_global "@colbymchenry/codegraph"
install_npm_global "agnix"
fi  # end GSD_ONLY skip

# =============================================================================
# PHASE 4 — Copy GSD files to ~/.cursor
# =============================================================================
if [[ "$POWERUP_ONLY" = false ]]; then
phase 4 "Copy GSD files to ~/.cursor"

if [ ! -d "$SOURCE_PATH" ]; then
    echo -e "  ${RED}ERROR: Source path not found: $SOURCE_PATH${NC}"
    exit 1
fi

if [ -d "$CURSOR_DIR/get-shit-done" ] && [ "$FORCE" = false ]; then
    echo -e "  ${YELLOW}Existing GSD installation found at: $CURSOR_DIR/get-shit-done${NC}"
    read -r -p "  Overwrite? (y/N) " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "  ${CYAN}Skipping GSD file copy.${NC}"
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

# Power-up reindex script
REINDEX_SRC="$SCRIPT_DIR/cursor-powerup-reindex.sh"
if [ -f "$REINDEX_SRC" ]; then
    cp "$REINDEX_SRC" "$CURSOR_DIR/get-shit-done/scripts/cursor-powerup-reindex.sh"
    chmod +x "$CURSOR_DIR/get-shit-done/scripts/cursor-powerup-reindex.sh"
    ok "Copied cursor-powerup-reindex.sh"
fi

# GSD skill
if [ -f "$SOURCE_PATH/skills/gsd-for-cursor/SKILL.md" ]; then
    mkdir -p "$CURSOR_DIR/skills/gsd-for-cursor"
    cp "$SOURCE_PATH/skills/gsd-for-cursor/SKILL.md" "$CURSOR_DIR/skills/gsd-for-cursor/SKILL.md"
    ok "Copied gsd-for-cursor skill"
fi

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
fi  # end POWERUP_ONLY skip

# =============================================================================
# PHASE 5 — agentmemory connect cursor (MCP wiring)
# =============================================================================
if [[ "$GSD_ONLY" = false ]]; then
phase 5 "agentmemory → Cursor MCP"

if command -v agentmemory &>/dev/null; then
    agentmemory connect cursor 2>/dev/null && ok "agentmemory connect cursor done" \
        || warn "agentmemory connect cursor returned non-zero — check manually"
else
    warn "agentmemory not on PATH yet — open a new terminal and run: agentmemory connect cursor"
    info "  (PATH will include ~/.npm-global/bin after restarting your shell)"
fi
fi  # end GSD_ONLY skip

# =============================================================================
# PHASE 6 — Ensure playwright + github in mcp.json
# =============================================================================
if [[ "$GSD_ONLY" = false ]]; then
phase 6 "Ensure playwright + github in mcp.json"

MCP="$HOME/.cursor/mcp.json"

merge_mcp_python() {
python3 - <<'PY'
import json, os, sys
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

if [ -f "$MCP" ] && command -v python3 &>/dev/null; then
    merge_mcp_python && ok "mcp.json updated" || warn "mcp.json merge failed — see below"
elif [ -f "$MCP" ] && command -v node &>/dev/null; then
    # node fallback
    node - "$MCP" <<'JS'
const fs=require('fs'), p=process.argv[1];
let d={}; try{d=JSON.parse(fs.readFileSync(p,'utf8'))}catch(e){}
const s=d.mcpServers||(d.mcpServers={});
if(!s.playwright) s.playwright={command:'npx',args:['-y','@playwright/mcp@latest']};
if(!s.github) s.github={url:'https://api.githubcopilot.com/mcp/',headers:{Authorization:'Bearer ${env:GITHUB_PERSONAL_ACCESS_TOKEN}'}};
fs.writeFileSync(p,JSON.stringify(d,null,2)+'\n');
console.log('MCP: ensured playwright + github');
JS
    ok "mcp.json updated (node fallback)"
else
    # create from scratch
    mkdir -p "$HOME/.cursor"
    cat > "$MCP" << 'EOF'
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
    ok "Created mcp.json with agentmemory, playwright, github"
fi
fi  # end GSD_ONLY skip

# =============================================================================
# PHASE 7 — antigravity safe skills
# =============================================================================
if [[ "$GSD_ONLY" = false ]]; then
phase 7 "antigravity safe skills bundle"

mkdir -p "$CURSOR_DIR/skills"
npx --yes antigravity-awesome-skills \
    --path "$CURSOR_DIR/skills" \
    --category development,backend,frontend,security \
    --risk safe 2>/dev/null \
    && ok "antigravity skills installed" \
    || warn "antigravity install skipped or failed (non-fatal)"
fi  # end GSD_ONLY skip

# =============================================================================
# PHASE 8 — Clone reference repos to ~/.cursor/repos
# =============================================================================
if [[ "$GSD_ONLY" = false ]]; then
phase 8 "Clone reference repos to ~/.cursor/repos"

mkdir -p "$CURSOR_DIR/repos"

clone_if_missing() {
    local name="$1" url="$2"
    if [ -d "$CURSOR_DIR/repos/$name" ]; then
        info "Already exists: $name"
    else
        echo -n "  Cloning $name ... "
        git clone --depth 1 "$url" "$CURSOR_DIR/repos/$name" 2>/dev/null \
            && echo -e "${GREEN}ok${NC}" \
            || echo -e "${YELLOW}WARN — clone failed (non-fatal)${NC}"
    fi
}

clone_if_missing agentmemory              "https://github.com/rohitg00/agentmemory"
clone_if_missing codegraph                "https://github.com/colbymchenry/codegraph"
clone_if_missing antigravity-awesome-skills "https://github.com/sickn33/antigravity-awesome-skills"
clone_if_missing awesome-cursorrules      "https://github.com/PatrickJS/awesome-cursorrules"
fi  # end GSD_ONLY skip

# =============================================================================
# PHASE 9 — Ensure gitnexus available via npx
# =============================================================================
if [[ "$GSD_ONLY" = false ]]; then
phase 9 "gitnexus availability"

if command -v gitnexus &>/dev/null; then
    ok "gitnexus binary found: $(command -v gitnexus)"
else
    echo -n "  Installing gitnexus globally ... "
    npm install -g gitnexus 2>/dev/null \
        && echo -e "${GREEN}ok${NC}" \
        || { echo -e "${YELLOW}WARN — npm install -g gitnexus failed${NC}"; \
             info "Use: npx gitnexus analyze   (works without global install)"; }
fi
fi  # end GSD_ONLY skip

# =============================================================================
# PHASE 10 — chmod scripts & write POWERUP-INSTALLED.md
# =============================================================================
phase 10 "Finalize & write POWERUP-INSTALLED.md"

chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true

INSTALLED_AT="$(date '+%Y-%m-%d %H:%M %Z')"
INSTALLED_VERSION="2.0.0"

cat > "$CURSOR_DIR/POWERUP-INSTALLED.md" << EOF
# cursor-powered-up installation record

| Field   | Value |
|---------|-------|
| Version | $INSTALLED_VERSION |
| Date    | $INSTALLED_AT |
| Source  | $SCRIPT_DIR |
| Target  | $CURSOR_DIR |

## What was installed

- GSD for Cursor (commands, agents, workflows, templates, references, hooks)
- Global npm tools: @agentmemory/agentmemory, @colbymchenry/codegraph, agnix
- MCP wired: agentmemory, playwright, github
- antigravity safe skills bundle
- Reference repos cloned to ~/.cursor/repos/
- Hooks: gsd-check-update, gsd-powerup-reminder, gsd-statusline

## Update

\`\`\`bash
cd <cursor-powered-up-repo>
git pull
./scripts/install.sh --force
\`\`\`
EOF
ok "Wrote ~/.cursor/POWERUP-INSTALLED.md"

# =============================================================================
# PHASE 11 — Full power banner
# =============================================================================
phase 11 "Full power banner"

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║   cursor-powered-up  installed!          ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}${BOLD} FULL POWER — complete these steps (required for 21st.dev + UI):${NC}"
echo -e "${YELLOW}${BOLD} See: docs/POST-INSTALL.md in this repo${NC}"
echo -e "${YELLOW}   • 21st.dev MCP (your API key)${NC}"
echo -e "${YELLOW}   • framer-motion in React projects${NC}"
echo -e "${YELLOW}   • GITHUB_PERSONAL_ACCESS_TOKEN${NC}"
echo -e "${YELLOW}   • agentmemory each session${NC}"
echo -e "${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
