# cursor-powered-up

> **One clone. One install. Full Cursor AI power-up.**
> GSD (Get Shit Done) spec-driven workflows + agent memory + CodeGraph + MCP wiring + safe skills bundle.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Quick Start

```bash
# macOS / Linux
git clone https://github.com/umer-jahangier/cursor-powered-up.git
cd cursor-powered-up
./scripts/install.sh
```

```powershell
# Windows (PowerShell — run as your normal user, not admin)
git clone https://github.com/umer-jahangier/cursor-powered-up.git
cd cursor-powered-up
.\scripts\install.ps1
```

That's it. The installer handles everything — see [what it does](#what-the-installer-does) below.

> **After install:** follow **[docs/POST-INSTALL.md](./docs/POST-INSTALL.md)** to set your GitHub PAT, start agentmemory, and optionally enable the [21st.dev MCP](./docs/POST-INSTALL.md#step-4--21stdev-mcp-optional--ui-components) for AI-generated React UI components (requires your own free API key).

---

## What the installer does

| Phase | Action |
|-------|--------|
| 1 | Detect OS; check node 18+, npm, npx, git, python3 |
| 2 | Set up `~/.npm-global` prefix (no sudo/admin) |
| 3 | `npm install -g @agentmemory/agentmemory @colbymchenry/codegraph agnix` |
| 4 | Copy GSD commands, agents, workflows, templates, references, hooks to `~/.cursor/` |
| 5 | `agentmemory connect cursor` (wire memory MCP) |
| 6 | Ensure `playwright` + `github` entries in `~/.cursor/mcp.json` |
| 7 | `npx antigravity-awesome-skills` — safe dev/backend/frontend/security bundle |
| 8 | Shallow-clone reference repos to `~/.cursor/repos/` |
| 9 | Install / verify `gitnexus` (falls back to `npx gitnexus`) |
| 10 | `chmod` scripts, write `~/.cursor/POWERUP-INSTALLED.md` |
| 11 | Print final checklist (restart Cursor, set PAT, run `agentmemory`) |

### Still manual (cannot be automated without asking)

1. **Add to `~/.zshrc`** (Mac/Linux) then `source ~/.zshrc`:
   ```bash
   export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"
   export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here
   ```
2. **Every coding session** — run `agentmemory` in a terminal (keep it open).
3. **Restart Cursor** after first install.
4. **21st.dev MCP** (optional — AI-generated React UI with framer-motion): install with your own free API key from [21st.dev](https://21st.dev):
   ```bash
   npx -y @21st-dev/cli@latest install cursor --api-key "YOUR_21ST_DEV_API_KEY"
   ```

See the full walkthrough in **[docs/POST-INSTALL.md](./docs/POST-INSTALL.md)**.

---

## Cursor power-up integration

| Command | What it does |
|---------|-------------|
| `/gsd-new-project` | CodeGraph + GitNexus + `.cursor/rules/` bootstrap |
| `/gsd-map-codebase` | Bootstrap brownfield project |
| `/gsd-execute-phase N` | Execute plan + auto re-index |
| `/gsd-help` | See all 27 commands |

---

## GSD commands overview

```
/gsd-new-project        # Phase 1.5 bootstrap + questioning → research → requirements → roadmap
/gsd-map-codebase       # Map existing codebase
/gsd-discuss-phase N    # Capture implementation decisions
/gsd-plan-phase N       # Create executable plans
/gsd-execute-phase N    # Execute plans with atomic commits
/gsd-verify-work N      # User acceptance testing
/gsd-help               # Full command list
```

---

## Screenshots

![Cursor Opening Subagents](assets/mapcodebase.png)

![Cursor GSD Commands](assets/commands.png)

---

## Documentation

| Document | Description |
|----------|-------------|
| [docs/POST-INSTALL.md](./docs/POST-INSTALL.md) | **Post-install guide** — PAT, agentmemory, 21st.dev MCP, project bootstrap |
| [docs/PORTABLE-SETUP.md](./docs/PORTABLE-SETUP.md) | New machine restore guide |
| [docs/GSD-CURSOR-ADAPTATION.md](./docs/GSD-CURSOR-ADAPTATION.md) | Technical adaptation details |
| [CHANGELOG.md](./CHANGELOG.md) | Version history |
| [MIGRATION.md](./MIGRATION.md) | Updating from upstream GSD |

---

## Credits

- Original GSD system: [glittercowboy/get-shit-done](https://github.com/glittercowboy/get-shit-done)
- Cursor adaptation: Royi Mindel
- Power-up packaging: cursor-powered-up

MIT License — see [LICENSE](./LICENSE).
