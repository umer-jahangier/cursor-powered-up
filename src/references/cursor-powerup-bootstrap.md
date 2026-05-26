# Cursor Power-Up Bootstrap (per-repo)

Run during `/gsd-new-project` Phase 1.5 and when onboarding any repo. Global tools live in `~/.cursor/`; this wires **this project** so agents perform like a master developer.

## Global vs per-repo

| Already global (no per-repo install) | Per-repo (this bootstrap) |
|--------------------------------------|---------------------------|
| Skills `~/.cursor/skills/` | CodeGraph index `.codegraph/` |
| GSD commands `~/.cursor/commands/gsd/` | GitNexus graph + `AGENTS.md` |
| MCP `~/.cursor/mcp.json` | `.cursor/rules/*.mdc` |
| agentmemory, Playwright, GitHub MCP | `.planning/CURSOR-POWERUP.md` status |
| 21st.dev MCP (optional, user API key) | — |

**agentmemory:** User must run `agentmemory` in a terminal (global server). Remind once if health check fails.

## Optional MCP: 21st.dev (UI components + framer-motion)

21st.dev is **not auto-installed** by `install.sh` because it requires the user's own API key. It is an optional post-install step.

When available, it enables Cursor agents to generate production-ready React components with:
- [framer-motion](https://www.framer.com/motion/) animation patterns baked in
- Tailwind + shadcn-compatible output
- Design-system-coherent tokens

**Install command (user runs once, their own key):**

```bash
npx -y @21st-dev/cli@latest install cursor --api-key "YOUR_21ST_DEV_API_KEY"
```

Keys available at [21st.dev](https://21st.dev). The CLI writes the MCP entry to `~/.cursor/mcp.json`.

**Frontend skills that pair with 21st.dev** (already installed at `~/.cursor/skills/`):
- `design-taste-frontend` — high-agency UI with calibrated color and motion
- `high-end-visual-design` — agency-grade premium interfaces
- `gpt-taste` — GSAP-heavy pages with wide hero typography and bento grids
- `stitch-design-taste` — design systems with motion intent

**framer-motion project setup:**
```bash
npm install framer-motion   # or: pnpm add framer-motion
```

## Bootstrap checklist (execute with Bash)

```bash
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"
POWERUP_LOG=".planning/CURSOR-POWERUP.md"
mkdir -p .planning .cursor/rules

# 1. CodeGraph
if [ ! -d .codegraph ]; then
  codegraph init -i 2>/dev/null || codegraph init
fi
codegraph index 2>/dev/null || echo "WARN: codegraph index failed"

# 2. GitNexus
npx --yes gitnexus analyze 2>/dev/null || echo "WARN: gitnexus analyze failed"

# 3. Cursor rules — always useful
RULES_SRC="$HOME/.cursor/repos/awesome-cursorrules/rules"
if [ -d "$RULES_SRC" ]; then
  cp -n "$RULES_SRC/clean-code.mdc" .cursor/rules/ 2>/dev/null || true
else
  git clone --depth 1 https://github.com/PatrickJS/awesome-cursorrules /tmp/awesome-cursorrules 2>/dev/null
  RULES_SRC="/tmp/awesome-cursorrules/rules"
  cp -n "$RULES_SRC/clean-code.mdc" .cursor/rules/ 2>/dev/null || true
fi

# 4. Stack-specific rules (copy if detected, never overwrite)
if ls *.py app.py main.py requirements.txt 2>/dev/null | grep -q .; then
  cp -n "$RULES_SRC/python.mdc" .cursor/rules/ 2>/dev/null || true
  cp -n "$RULES_SRC/python-projects-guide-cursorrules-prompt-file.mdc" .cursor/rules/ 2>/dev/null || true
fi
if [ -f package.json ]; then
  for f in "$RULES_SRC"/*react*.mdc "$RULES_SRC"/*typescript*.mdc "$RULES_SRC"/*nextjs*.mdc; do
    [ -f "$f" ] && cp -n "$f" .cursor/rules/ 2>/dev/null && break
  done
fi
if [ -f go.mod ]; then
  cp -n "$RULES_SRC"/go-*.mdc .cursor/rules/ 2>/dev/null || true
fi
if [ -f Cargo.toml ]; then
  cp -n "$RULES_SRC"/rust*.mdc .cursor/rules/ 2>/dev/null || true
fi

# 5. .gitignore — add standard entries (never duplicate, preserve existing)
# Full template documented in: references/gitignore-template.md
GITIGNORE_ENTRIES=(
  ".env" ".env.*" "!.env.example"
  ".codegraph/"
  ".cursor/projects/"
  "__pycache__/" "*.py[cod]" "*.pyo"
  ".pytest_cache/" ".mypy_cache/" ".ruff_cache/"
  ".coverage" "htmlcov/"
  "node_modules/" "dist/" "build/" ".next/" "out/" ".turbo/"
  "*.log" "logs/"
  ".DS_Store" "Thumbs.db" "*.swp" "*.swo"
  ".idea/" ".vscode/"
  "output/"
  "*.egg-info/"
)
for entry in "${GITIGNORE_ENTRIES[@]}"; do
  grep -qxF "$entry" .gitignore 2>/dev/null || echo "$entry" >> .gitignore
done
# Stack-specific additions
if ls *.py app.py main.py requirements.txt pyproject.toml 2>/dev/null | grep -q .; then
  for entry in "venv/" ".venv/"; do
    grep -qxF "$entry" .gitignore 2>/dev/null || echo "$entry" >> .gitignore
  done
fi
if [ -f go.mod ]; then grep -qxF "vendor/" .gitignore 2>/dev/null || echo "vendor/" >> .gitignore; fi
if [ -f Cargo.toml ]; then grep -qxF "target/" .gitignore 2>/dev/null || echo "target/" >> .gitignore; fi

# 6. Status file
cat > "$POWERUP_LOG" <<EOF
# Cursor Power-Up — $(date +%Y-%m-%d)

| Step | Status |
|------|--------|
| CodeGraph | $([ -d .codegraph ] && echo done || echo skipped) |
| GitNexus | $([ -f AGENTS.md ] && echo done || echo partial) |
| Cursor rules | $(ls .cursor/rules/*.mdc 2>/dev/null | wc -l | tr -d ' ') rules in .cursor/rules/ |
|| .gitignore | $([ -f .gitignore ] && echo updated || echo created) |

## Agent instructions

- Prefer CodeGraph/GitNexus MCP tools over blind grep when exploring structure.
- Use global skills from ~/.cursor/skills/ (security, performance, clean-code).
- Persist decisions via agentmemory MCP when the server is running.
- Follow .cursor/rules/ for style on matching files.
- GSD artifacts live in .planning/ — read PROJECT.md and STATE.md before large changes.

## User reminders

- Global: \`agentmemory\` running, \`GITHUB_PERSONAL_ACCESS_TOKEN\` for GitHub MCP
- Re-index after major refactors: automatic on \`/gsd-execute-phase\`; manual: \`bash ~/.cursor/get-shit-done/scripts/cursor-powerup-reindex.sh\`
EOF
```

## After bootstrap

1. Read `AGENTS.md` (if created) and `.planning/CURSOR-POWERUP.md`.
2. Mention power-up status in one line when starting questioning (no long lecture).
3. Commit bootstrap artifacts with first project commit if `commit_docs` is yes:
   - `AGENTS.md`, `.cursor/rules/`, `.planning/CURSOR-POWERUP.md`, `.gitignore`
   - Do **not** commit `.codegraph/` (it is gitignored by the step above)

## Verify global stack

```bash
bash ~/.cursor/skills/cursor-powerup/scripts/verify-setup.sh
curl -sf http://localhost:3111/agentmemory/health >/dev/null && echo "agentmemory OK" || echo "WARN: start agentmemory in a terminal"
```
