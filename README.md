# cursor-powered-up

> **One clone. One install. Full AI power-up for Cursor, VS Code, and Antigravity.**
> GSD (Get Shit Done) spec-driven workflows + agent memory + CodeGraph + MCP wiring + 1,400+ safe skills bundle.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Quick Start

```bash
# macOS / Linux — interactive IDE selection
git clone https://github.com/umer-jahangier/cursor-powered-up.git
cd cursor-powered-up
./scripts/install.sh
```

```bash
# Non-interactive: install for specific IDE
./scripts/install.sh --ide cursor --non-interactive
./scripts/install.sh --ide vscode --non-interactive
./scripts/install.sh --ide antigravity --non-interactive
./scripts/install.sh --ide all --non-interactive --force
```

```powershell
# Windows (PowerShell — run as your normal user, not admin)
git clone https://github.com/umer-jahangier/cursor-powered-up.git
cd cursor-powered-up
.\scripts\install.ps1
```

The installer handles everything — see [what it does](#what-the-installer-does) below.

> **After install:** follow **[docs/POST-INSTALL.md](./docs/POST-INSTALL.md)** to set your GitHub PAT, start agentmemory, and optionally enable the [21st.dev MCP](./docs/POST-INSTALL.md#step-4--21stdev-mcp--ui-components).

---

## Multi-IDE Support

| IDE | What you get |
|-----|-------------|
| **Cursor** | Full stack: GSD commands + skills + MCP + memory + hooks |
| **VS Code** (Copilot) | Skills + MCP (user-level) + memory — no GSD (Cursor-exclusive) |
| **Antigravity** | Skills + MCP + memory — no GSD (Cursor-exclusive) |

### Interactive prompt

```
$ ./scripts/install.sh

Which IDE(s) would you like to install for?

  1) Cursor
  2) VS Code (Copilot + MCP)
  3) Antigravity
  4) All

  Select [1-4]:
```

### CLI flags

| Flag | Description |
|------|-------------|
| `--ide cursor\|vscode\|antigravity\|all` | Target IDE(s) |
| `--non-interactive` | Skip all prompts (requires `--ide`) |
| `--force` | Overwrite existing installation |
| `--gsd-only` | Only copy GSD files (Cursor only) |
| `--powerup-only` | Only run power-up phases (skip GSD) |

---

## Power Stack

`install.sh` installs the **core stack** automatically. The **full power** stack adds UI generation and requires your own API key — follow [docs/POST-INSTALL.md](./docs/POST-INSTALL.md) after the installer finishes.

| Layer | Tool | Install | IDEs |
|-------|------|---------|------|
| Agent memory | agentmemory MCP | Auto | All |
| Browser automation | Playwright MCP | Auto | All |
| GitHub integration | GitHub MCP | Auto | All |
| Codebase graph | CodeGraph + GitNexus | Auto | All |
| Safe skills bundle | antigravity development,backend | Auto | All |
| ui-ux-pro-max | Premium UI/UX skill | Auto | All |
| animation-designer | Framer Motion, GSAP, R3F, Lenis, shaders | Auto | All |
| GSD workflows | 27 `/gsd-*` commands | Auto | **Cursor only** |
| **21st.dev MCP** | **UI component generation** | **Post-install** | Cursor, VS Code |
| **Framer Motion** | **Animation library** | **Per-project** | All |

---

## What the Installer Does

### Generic phases (all IDEs)

| Phase | Action |
|-------|--------|
| 1 | Detect OS; check node 18+, npm, npx, git, python3 |
| 2 | Set up `~/.npm-global` prefix (no sudo/admin) |
| 3 | `npm install -g @agentmemory/agentmemory @colbymchenry/codegraph agnix` |
| 4 | Shallow-clone reference repos to `~/.cursor/repos/` |
| 5 | Install / verify `gitnexus` |

### Cursor-specific phases

| Phase | Action |
|-------|--------|
| C1 | Copy GSD commands, agents, workflows, templates, references, hooks to `~/.cursor/` |
| C2 | `agentmemory connect cursor` |
| C3 | Ensure `playwright` + `github` in `~/.cursor/mcp.json` |
| C4 | `npx antigravity-awesome-skills --path ~/.cursor/skills --category development,backend --risk safe` |
| C4b | Bundled skills: `gsd-for-cursor`, `animation-designer`, … from `src/skills/` |

### VS Code-specific phases

| Phase | Action |
|-------|--------|
| V1 | `npx antigravity-awesome-skills --path ~/.vscode/skills --category development,backend --risk safe` |
| V2 | Write MCP config (agentmemory, playwright, github) to user-level `mcp.json` |

### Antigravity-specific phases

| Phase | Action |
|-------|--------|
| A1 | `npx antigravity-awesome-skills --path ~/.agents/skills --category development,backend --risk safe` |
| A2 | `agentmemory connect antigravity` |
| A3 | Ensure `playwright` + `github` in Antigravity `mcp_config.json` |

---

## Still Manual (cannot be automated without asking)

1. **Add to `~/.zshrc`** (Mac/Linux) then `source ~/.zshrc`:
   ```bash
   export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"
   export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here
   ```
2. **Every coding session** — run `agentmemory` in a terminal (keep it open).
3. **Restart your IDE** after first install.
4. **21st.dev MCP** — required for full UI power:
   ```bash
   # Cursor
   npx -y @21st-dev/cli@latest install cursor --api-key "YOUR_KEY"
   # VS Code
   npx -y @21st-dev/cli@latest install vscode --api-key "YOUR_KEY"
   ```
5. **Framer Motion** — install per React project:
   ```bash
   npm install framer-motion
   ```

See the full walkthrough in **[docs/POST-INSTALL.md](./docs/POST-INSTALL.md)**.

---

## Cursor Power-Up Integration (Cursor-exclusive)

| Command | What it does |
|---------|-------------|
| `/gsd-new-project` | CodeGraph + GitNexus + `.cursor/rules/` bootstrap |
| `/gsd-map-codebase` | Bootstrap brownfield project |
| `/gsd-execute-phase N` | Execute plan + auto re-index |
| `/gsd-help` | See all 27 commands |

> **Note:** GSD slash commands are Cursor-exclusive. VS Code and Antigravity get the full skills + MCP + memory stack but not GSD workflows.

---

## GSD Commands Overview (Cursor only)

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
| [docs/IDE-PATHS.md](./docs/IDE-PATHS.md) | **Multi-IDE paths reference** — skills dirs, MCP configs per IDE |
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
