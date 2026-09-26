#!/usr/bin/env bash
# =============================================================================
# cursor-powered-up — Multi-Agent Installer (macOS / Linux)
# =============================================================================
# One install for every AI coding agent: Claude Code, Cursor, Codex CLI,
# Gemini CLI, Antigravity, GitHub Copilot (VS Code), Windsurf/Devin, OpenCode,
# Kiro, Cline. Skills, MCP servers and rules come from config/ + src/rules/ and
# are applied per agent by scripts/lib/powerup.mjs.
#
# Usage:
#   ./scripts/install.sh                                  # Interactive
#   ./scripts/install.sh --agents detected                # Every agent found on this machine
#   ./scripts/install.sh --agents claude-code,cursor,codex --packs default,workflow
#   ./scripts/install.sh --agents all --mcp all --non-interactive
#   ./scripts/install.sh --dry-run                        # Show the plan, change nothing
#   ./scripts/install.sh --ide cursor                     # Legacy flag (still supported)
#
# Flags:
#   --agents <spec>      detected | all | comma list (see: node scripts/lib/powerup.mjs --help)
#   --packs <spec>       Skill packs: default | all | none | ui-design,motion,3d,dataflow,workflow
#   --mcp <spec>         MCP servers: core (default) | extra | all | none | names
#   --dry-run            Print what would be installed; change nothing
#   --force              Re-install skills/plugins; refresh this repo's own rule blocks
#   --non-interactive    Skip all prompts (defaults to --agents detected)
#   --gsd-only           Only copy GSD files (Cursor)
#   --powerup-only       Skip GSD copy
#   --ide <cursor|vscode|antigravity|all>   Legacy alias for --agents
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
POWERUP="$SCRIPT_DIR/lib/powerup.mjs"
FORCE=false
GSD_ONLY=false
POWERUP_ONLY=false
NON_INTERACTIVE=false
DRY_RUN=false
AGENTS_SPEC=""
PACKS_SPEC="default"
MCP_SPEC="core"

need_value() { [[ -n "${2:-}" && "${2:0:1}" != "-" ]] || { echo "Error: $1 requires a value"; exit 1; }; }

while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)         FORCE=true;           shift ;;
        --gsd-only)         GSD_ONLY=true;        shift ;;
        --powerup-only)     POWERUP_ONLY=true;    shift ;;
        --non-interactive)  NON_INTERACTIVE=true; shift ;;
        --dry-run)          DRY_RUN=true;         shift ;;
        --agents)           need_value "$1" "${2:-}"; AGENTS_SPEC="$2"; shift 2 ;;
        --packs)            need_value "$1" "${2:-}"; PACKS_SPEC="$2";  shift 2 ;;
        --mcp)              need_value "$1" "${2:-}"; MCP_SPEC="$2";    shift 2 ;;
        --ide)
            need_value "$1" "${2:-}"
            case "$2" in
                cursor)      AGENTS_SPEC="cursor" ;;
                vscode)      AGENTS_SPEC="github-copilot" ;;
                antigravity) AGENTS_SPEC="antigravity" ;;
                all)         AGENTS_SPEC="cursor,github-copilot,antigravity" ;;
                *) echo -e "${RED}Invalid --ide value: $2${NC} (cursor|vscode|antigravity|all)"; exit 1 ;;
            esac
            shift 2 ;;
        --help|-h)
            sed -n '3,31p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *) echo "Unknown option: $1 (see --help)"; exit 1 ;;
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
echo -e "${GREEN}${BOLD}║   cursor-powered-up  —  Multi-Agent Installer    ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GRAY}Source:  $SOURCE_PATH${NC}"

if ! command -v node &>/dev/null; then
    echo -e "${RED}node 18+ is required (https://nodejs.org or: brew install node)${NC}"
    exit 1
fi

# ── Agent selection ───────────────────────────────────────────────────────────
DETECTED="$(node "$SCRIPT_DIR/lib/agents.mjs" detected)"

if [[ -z "$AGENTS_SPEC" ]]; then
    if [[ "$NON_INTERACTIVE" = true ]]; then
        AGENTS_SPEC="detected"
    else
        echo ""
        echo -e "${BOLD}Detected AI coding agents:${NC} ${DETECTED:-none}"
        echo ""
        echo "  1) All detected agents (recommended)"
        echo "  2) Pick agents (comma list)"
        echo "  3) Every supported agent (also pre-configures ones you install later)"
        echo ""
        read -r -p "  Select [1-3]: " choice
        case "$choice" in
            1|"") AGENTS_SPEC="detected" ;;
            2)
                echo -e "  ${GRAY}ids: $(node "$SCRIPT_DIR/lib/agents.mjs" all | tr ' ' ',')${NC}"
                read -r -p "  Agents: " AGENTS_SPEC ;;
            3) AGENTS_SPEC="all" ;;
            *) echo -e "${RED}Invalid selection.${NC}"; exit 1 ;;
        esac
    fi
fi

SELECTED="$(node "$SCRIPT_DIR/lib/agents.mjs" "$AGENTS_SPEC")" || exit 1
has_agent() { [[ " $SELECTED " == *" $1 "* ]]; }

echo ""
echo -e "${CYAN}Install targets:${NC} ${SELECTED:-none}"
echo -e "${CYAN}Skill packs:${NC}     $PACKS_SPEC   ${CYAN}MCP:${NC} $MCP_SPEC"
[[ "$DRY_RUN" = true ]] && echo -e "${YELLOW}Dry run — nothing will be changed.${NC}"

POWERUP_FLAGS=(--agents "$AGENTS_SPEC" --packs "$PACKS_SPEC" --mcp "$MCP_SPEC")
[[ "$DRY_RUN" = true ]] && POWERUP_FLAGS+=(--dry-run)
[[ "$FORCE" = true ]]   && POWERUP_FLAGS+=(--force)

if [[ "$DRY_RUN" = true ]]; then
    node "$POWERUP" all "${POWERUP_FLAGS[@]}"
    exit 0
fi

# =============================================================================
# GENERIC PHASES (all agents) — prereqs, npm prefix, CLI tools, reference repos
# =============================================================================
if [[ "$GSD_ONLY" = false ]]; then
    source "$SCRIPT_DIR/lib/generic.sh"
fi

# =============================================================================
# GSD + legacy per-IDE extras
# =============================================================================
if has_agent cursor; then
    echo -e "\n${GREEN}${BOLD}── Cursor ──────────────────────────────────────────${NC}"
    source "$SCRIPT_DIR/lib/cursor.sh"
fi
if has_agent github-copilot && [[ "$GSD_ONLY" = false ]]; then
    echo -e "\n${GREEN}${BOLD}── GitHub Copilot (VS Code) ────────────────────────${NC}"
    source "$SCRIPT_DIR/lib/vscode.sh"
fi
if has_agent antigravity && [[ "$GSD_ONLY" = false ]]; then
    echo -e "\n${GREEN}${BOLD}── Antigravity ─────────────────────────────────────${NC}"
    source "$SCRIPT_DIR/lib/antigravity.sh"
fi

# =============================================================================
# CROSS-AGENT POWER-UP — skill packs, bundled skills, MCP servers, global rules
# =============================================================================
if [[ "$GSD_ONLY" = false ]]; then
    phase "P" "Skills + MCP + rules for: $SELECTED"
    node "$POWERUP" all "${POWERUP_FLAGS[@]}" \
        || warn "Some items failed (see table above) — re-run with --force to retry"
fi

# =============================================================================
# FINALIZE
# =============================================================================
phase "F" "Finalize & write install record"

chmod +x "$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/lib/*.sh 2>/dev/null || true

INSTALLED_AT="$(date '+%Y-%m-%d %H:%M %Z')"
INSTALLED_VERSION="4.0.0"

mkdir -p "$HOME/.agents"
cat > "$HOME/.agents/POWERUP-INSTALLED.md" << EOF
# cursor-powered-up installation record

| Field   | Value |
|---------|-------|
| Version | $INSTALLED_VERSION |
| Date    | $INSTALLED_AT |
| Source  | $SCRIPT_DIR |
| Agents  | $SELECTED |
| Packs   | $PACKS_SPEC |
| MCP     | $MCP_SPEC |

Check state any time: \`node $POWERUP status\`

## Update

\`\`\`bash
cd <cursor-powered-up-repo> && git pull
./scripts/install.sh --agents detected --force
\`\`\`
EOF
has_agent cursor && cp "$HOME/.agents/POWERUP-INSTALLED.md" "$HOME/.cursor/POWERUP-INSTALLED.md"
ok "Wrote ~/.agents/POWERUP-INSTALLED.md"

# =============================================================================
# BANNER
# =============================================================================
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║   cursor-powered-up v${INSTALLED_VERSION} installed!           ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}${BOLD} NEXT STEPS (docs/POST-INSTALL.md):${NC}"
echo -e "${YELLOW}   • Restart your agents / IDEs${NC}"
echo -e "${YELLOW}   • export GITHUB_PERSONAL_ACCESS_TOKEN=... in ~/.zshrc${NC}"
echo -e "${YELLOW}   • Run 'agentmemory' each coding session${NC}"
echo -e "${YELLOW}   • Per repo: node $POWERUP project-init --dir .   (AGENTS.md for every agent)${NC}"
echo -e "${YELLOW}   • Optional: 21st.dev Magic MCP (needs your API key)${NC}"
echo -e "${YELLOW}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
