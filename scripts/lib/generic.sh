#!/usr/bin/env bash
# =============================================================================
# generic.sh — Shared install phases (all IDEs)
# =============================================================================
# Phases: prereqs, npm prefix, npm globals, reference repo clones, gitnexus
# Called by install.sh after IDE selection.
# =============================================================================

# ── Phase 1 — Detect OS & check prerequisites ────────────────────────────────
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

# ── Phase 2 — npm user prefix (no sudo) ──────────────────────────────────────
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

# ── Phase 3 — npm global tools ───────────────────────────────────────────────
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

# ── Phase 4 — Clone reference repos ──────────────────────────────────────────
phase 4 "Clone reference repos"

REPOS_DIR="$HOME/.cursor/repos"
mkdir -p "$REPOS_DIR"

clone_if_missing() {
    local name="$1" url="$2"
    if [ -d "$REPOS_DIR/$name" ]; then
        info "Already exists: $name"
    else
        echo -n "  Cloning $name ... "
        git clone --depth 1 "$url" "$REPOS_DIR/$name" 2>/dev/null \
            && echo -e "${GREEN}ok${NC}" \
            || echo -e "${YELLOW}WARN — clone failed (non-fatal)${NC}"
    fi
}

clone_if_missing agentmemory              "https://github.com/rohitg00/agentmemory"
clone_if_missing codegraph                "https://github.com/colbymchenry/codegraph"
clone_if_missing antigravity-awesome-skills "https://github.com/sickn33/antigravity-awesome-skills"
clone_if_missing awesome-cursorrules      "https://github.com/PatrickJS/awesome-cursorrules"

# ── Phase 5 — Ensure gitnexus available ──────────────────────────────────────
phase 5 "gitnexus availability"

if command -v gitnexus &>/dev/null; then
    ok "gitnexus binary found: $(command -v gitnexus)"
else
    echo -n "  Installing gitnexus globally ... "
    npm install -g gitnexus 2>/dev/null \
        && echo -e "${GREEN}ok${NC}" \
        || { echo -e "${YELLOW}WARN — npm install -g gitnexus failed${NC}"; \
             info "Use: npx gitnexus analyze   (works without global install)"; }
fi
