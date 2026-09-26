#!/usr/bin/env bash
# =============================================================================
# cursor.sh — Cursor-specific install phases
# =============================================================================
# Handles: GSD copy + hooks, agentmemory connect, antigravity-awesome-skills.
# Skill packs, bundled skills, MCP servers and rules are applied for every agent
# by scripts/lib/powerup.mjs (called from install.sh).
# =============================================================================

CURSOR_DIR="$HOME/.cursor"
CURSOR_SKILLS="$CURSOR_DIR/skills"

DO_GSD=true
[[ "$POWERUP_ONLY" = true ]] && DO_GSD=false

if [[ "$DO_GSD" = true ]]; then
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
            DO_GSD=false
        fi
    fi
fi
fi

if [[ "$DO_GSD" = true ]]; then

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

# Cursor settings.json (hooks + statusline) — merge, never replace user keys
node "$SCRIPT_DIR/lib/cursor-settings.mjs" "$CURSOR_DIR/settings.json" \
    && ok "settings.json: GSD hooks + statusline ensured" \
    || warn "settings.json merge skipped — file left untouched"

echo "2.0.0" > "$CURSOR_DIR/get-shit-done/VERSION"
fi

[[ "$GSD_ONLY" = true ]] && return 0

# ── Phase C2 — agentmemory connect cursor ────────────────────────────────────
phase "C2" "agentmemory → Cursor MCP"

if command -v agentmemory &>/dev/null; then
    agentmemory connect cursor 2>/dev/null && ok "agentmemory connect cursor done" \
        || warn "agentmemory connect cursor returned non-zero — check manually"
else
    warn "agentmemory not on PATH yet — open a new terminal and run: agentmemory connect cursor"
    info "  (PATH will include ~/.npm-global/bin after restarting your shell)"
fi

# ── Phase C3 — antigravity skills (development,backend) ──────────────────────
phase "C3" "antigravity skills → ~/.cursor/skills (development,backend)"

mkdir -p "$CURSOR_SKILLS"
echo -n "  Installing antigravity skills (development,backend, risk=safe) ... "
npx --yes antigravity-awesome-skills \
    --path "$CURSOR_SKILLS" \
    --category development,backend \
    --risk safe 2>/dev/null \
    && echo -e "${GREEN}ok${NC}" \
    || echo -e "${YELLOW}WARN — antigravity install failed (non-fatal)${NC}"

# Count installed skills
SKILL_COUNT=$(find "$CURSOR_SKILLS" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
ok "Total skills installed: $SKILL_COUNT"
