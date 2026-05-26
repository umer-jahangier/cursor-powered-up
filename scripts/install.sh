#!/usr/bin/env bash
# =============================================================================
# cursor-powered-up — Multi-IDE Installer
# =============================================================================
# Interactive installer supporting Cursor, VS Code, and Antigravity.
#
# Usage:
#   ./scripts/install.sh                              # Interactive IDE selection
#   ./scripts/install.sh --ide cursor                 # Cursor only
#   ./scripts/install.sh --ide vscode                 # VS Code only
#   ./scripts/install.sh --ide antigravity            # Antigravity only
#   ./scripts/install.sh --ide all                    # All IDEs
#   ./scripts/install.sh --ide cursor --non-interactive --force
#
# Flags:
#   --ide <cursor|vscode|antigravity|all>  Target IDE(s)
#   --force                                 Overwrite without prompting
#   --non-interactive                       Skip all prompts (use with --ide)
#   --gsd-only                              Only copy GSD files (Cursor only)
#   --powerup-only                          Only run power-up phases (skip GSD)
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
FORCE=false
GSD_ONLY=false
POWERUP_ONLY=false
NON_INTERACTIVE=false
IDE_TARGET=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)         FORCE=true;           shift ;;
        --gsd-only)         GSD_ONLY=true;        shift ;;
        --powerup-only)     POWERUP_ONLY=true;    shift ;;
        --non-interactive)  NON_INTERACTIVE=true;  shift ;;
        --ide)
            shift
            IDE_TARGET="${1:-}"
            [[ -z "$IDE_TARGET" ]] && { echo "Error: --ide requires a value (cursor|vscode|antigravity|all)"; exit 1; }
            shift ;;
        --help|-h)
            echo "Usage: $0 [--force] [--ide cursor|vscode|antigravity|all] [--non-interactive]"
            echo ""
            echo "  --ide <target>     Target IDE: cursor, vscode, antigravity, all"
            echo "  --force            Overwrite existing installation without prompting"
            echo "  --non-interactive  Skip all interactive prompts"
            echo "  --gsd-only         Only copy GSD files (Cursor only, skip npm/MCP/skills)"
            echo "  --powerup-only     Only run power-up phases (skip GSD copy)"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

NPM_PREFIX="$HOME/.npm-global"
export PATH="${NPM_PREFIX}/bin:$HOME/.local/bin:${PATH}"

# ── Phase helpers ─────────────────────────────────────────────────────────────
phase() { echo -e "\n${CYAN}${BOLD}▶ Phase $1: $2${NC}"; }
ok()    { echo -e "  ${GREEN}✓${NC} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC}  $1"; }
info()  { echo -e "  ${GRAY}  $1${NC}"; }

# ── Header ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║   cursor-powered-up  —  Multi-IDE Installer      ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GRAY}Source:  $SOURCE_PATH${NC}"
echo ""

# ── IDE Selection ─────────────────────────────────────────────────────────────
INSTALL_CURSOR=false
INSTALL_VSCODE=false
INSTALL_ANTIGRAVITY=false

if [[ -n "$IDE_TARGET" ]]; then
    case "$IDE_TARGET" in
        cursor)       INSTALL_CURSOR=true ;;
        vscode)       INSTALL_VSCODE=true ;;
        antigravity)  INSTALL_ANTIGRAVITY=true ;;
        all)          INSTALL_CURSOR=true; INSTALL_VSCODE=true; INSTALL_ANTIGRAVITY=true ;;
        *) echo -e "${RED}Invalid --ide value: $IDE_TARGET${NC}"; echo "Valid: cursor, vscode, antigravity, all"; exit 1 ;;
    esac
elif [[ "$NON_INTERACTIVE" = true ]]; then
    echo -e "${RED}Error: --non-interactive requires --ide flag${NC}"
    exit 1
else
    echo -e "${BOLD}Which IDE(s) would you like to install for?${NC}"
    echo ""
    echo "  1) Cursor"
    echo "  2) VS Code (Copilot + MCP)"
    echo "  3) Antigravity"
    echo "  4) All"
    echo ""
    read -r -p "  Select [1-4]: " ide_choice
    case "$ide_choice" in
        1) INSTALL_CURSOR=true ;;
        2) INSTALL_VSCODE=true ;;
        3) INSTALL_ANTIGRAVITY=true ;;
        4) INSTALL_CURSOR=true; INSTALL_VSCODE=true; INSTALL_ANTIGRAVITY=true ;;
        *) echo -e "${RED}Invalid selection.${NC}"; exit 1 ;;
    esac
fi

echo ""
echo -e "${CYAN}Install targets:${NC}"
[[ "$INSTALL_CURSOR" = true ]]      && echo -e "  ${GREEN}✓${NC} Cursor (GSD + skills + MCP + memory)"
[[ "$INSTALL_VSCODE" = true ]]      && echo -e "  ${GREEN}✓${NC} VS Code (skills + MCP + memory)"
[[ "$INSTALL_ANTIGRAVITY" = true ]] && echo -e "  ${GREEN}✓${NC} Antigravity (skills + MCP + memory)"
echo ""

# =============================================================================
# GENERIC PHASES (all IDEs)
# =============================================================================
if [[ "$GSD_ONLY" = false ]]; then
    source "$SCRIPT_DIR/lib/generic.sh"
fi

# =============================================================================
# IDE-SPECIFIC PHASES
# =============================================================================

if [[ "$INSTALL_CURSOR" = true ]]; then
    echo ""
    echo -e "${GREEN}${BOLD}── Cursor ──────────────────────────────────────────${NC}"
    if [[ "$POWERUP_ONLY" = false ]]; then
        source "$SCRIPT_DIR/lib/cursor.sh"
    fi
fi

if [[ "$INSTALL_VSCODE" = true ]] && [[ "$GSD_ONLY" = false ]]; then
    echo ""
    echo -e "${GREEN}${BOLD}── VS Code ─────────────────────────────────────────${NC}"
    source "$SCRIPT_DIR/lib/vscode.sh"
fi

if [[ "$INSTALL_ANTIGRAVITY" = true ]] && [[ "$GSD_ONLY" = false ]]; then
    echo ""
    echo -e "${GREEN}${BOLD}── Antigravity ─────────────────────────────────────${NC}"
    source "$SCRIPT_DIR/lib/antigravity.sh"
fi

# =============================================================================
# FINALIZE
# =============================================================================
phase "F" "Finalize & write install record"

chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
chmod +x "$SCRIPT_DIR"/lib/*.sh 2>/dev/null || true

INSTALLED_AT="$(date '+%Y-%m-%d %H:%M %Z')"
INSTALLED_VERSION="3.0.0"
INSTALLED_IDES=""
[[ "$INSTALL_CURSOR" = true ]]      && INSTALLED_IDES="${INSTALLED_IDES}Cursor, "
[[ "$INSTALL_VSCODE" = true ]]      && INSTALLED_IDES="${INSTALLED_IDES}VS Code, "
[[ "$INSTALL_ANTIGRAVITY" = true ]] && INSTALLED_IDES="${INSTALLED_IDES}Antigravity, "
INSTALLED_IDES="${INSTALLED_IDES%, }"

write_install_record() {
    local target_dir="$1"
    mkdir -p "$target_dir"
    cat > "$target_dir/POWERUP-INSTALLED.md" << EOF
# cursor-powered-up installation record

| Field   | Value |
|---------|-------|
| Version | $INSTALLED_VERSION |
| Date    | $INSTALLED_AT |
| Source  | $SCRIPT_DIR |
| IDEs    | $INSTALLED_IDES |

## What was installed

- Global npm tools: @agentmemory/agentmemory, @colbymchenry/codegraph, agnix, gitnexus
- antigravity skills (development,backend, risk=safe)
- ui-ux-pro-max skill
- MCP wired: agentmemory, playwright, github
- Reference repos cloned to ~/.cursor/repos/

## IDE-specific

- **Cursor**: GSD commands, agents, workflows, templates, references, hooks + full MCP
- **VS Code**: Skills + MCP (user-level) — GSD is Cursor-exclusive
- **Antigravity**: Skills + MCP — GSD is Cursor-exclusive

## Update

\`\`\`bash
cd <cursor-powered-up-repo>
git pull
./scripts/install.sh --ide all --force
\`\`\`
EOF
}

[[ "$INSTALL_CURSOR" = true ]]      && write_install_record "$HOME/.cursor"
[[ "$INSTALL_VSCODE" = true ]]      && write_install_record "$HOME/.vscode"
[[ "$INSTALL_ANTIGRAVITY" = true ]] && write_install_record "$HOME/.agents"

ok "Wrote install record(s)"

# =============================================================================
# BANNER
# =============================================================================
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║   cursor-powered-up v${INSTALLED_VERSION} installed!           ║${NC}"
echo -e "${GREEN}${BOLD}║   IDEs: ${INSTALLED_IDES}$(printf '%*s' $((30 - ${#INSTALLED_IDES})) '')║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}${BOLD} POST-INSTALL STEPS (see docs/POST-INSTALL.md):${NC}"
echo -e "${YELLOW}   • Restart your IDE(s)${NC}"
echo -e "${YELLOW}   • Set GITHUB_PERSONAL_ACCESS_TOKEN in ~/.zshrc${NC}"
echo -e "${YELLOW}   • Run 'agentmemory' each coding session${NC}"
if [[ "$INSTALL_CURSOR" = true ]] || [[ "$INSTALL_VSCODE" = true ]]; then
echo -e "${YELLOW}   • 21st.dev MCP (your API key):${NC}"
[[ "$INSTALL_CURSOR" = true ]] && echo -e "${YELLOW}       npx @21st-dev/cli install cursor --api-key YOUR_KEY${NC}"
[[ "$INSTALL_VSCODE" = true ]] && echo -e "${YELLOW}       npx @21st-dev/cli install vscode --api-key YOUR_KEY${NC}"
fi
echo -e "${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
