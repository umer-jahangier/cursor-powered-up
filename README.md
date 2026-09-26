# cursor-powered-up

> **One clone. One install. The same AI power-up in every coding agent.**
> Claude Code · Cursor · Codex CLI · Gemini CLI · Antigravity · GitHub Copilot · Windsurf/Devin · OpenCode · Kiro · Cline
>
> Covers design-taste and UI/UX skills, animation and 3D skills, data-flow visualization, MCP servers, agent memory, codebase graphs, and GSD spec-driven workflows.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Quick Start

```bash
# macOS / Linux
git clone https://github.com/umer-jahangier/cursor-powered-up.git
cd cursor-powered-up
./scripts/install.sh            # detects your agents and asks before installing
```

```powershell
# Windows (PowerShell, as your normal user)
git clone https://github.com/umer-jahangier/cursor-powered-up.git
cd cursor-powered-up
.\scripts\install.ps1
```

Preview first, then pick exactly what you want:

```bash
./scripts/install.sh --dry-run                                   # show the plan, change nothing
./scripts/install.sh --agents detected --non-interactive         # every agent found on this machine
./scripts/install.sh --agents claude-code,cursor,codex --packs default,workflow --mcp all
node scripts/lib/powerup.mjs status                              # what's detected / installed
```

> **After install:** follow **[docs/POST-INSTALL.md](./docs/POST-INSTALL.md)** to set your GitHub token, start agentmemory, and set up per-project rules.

---

## What you get

| Layer | What | Default |
|-------|------|---------|
| **Design taste** | Impeccable (primary) · Taste Skill · Anthropic frontend-design · UI UX Pro Max · ibelick ui-skills · Vercel web-design-guidelines | ✅ `ui-design` |
| **Motion** | Emil Kowalski skills (13) · official GSAP skills (8) | ✅ `motion` |
| **3D** | Three.js / React Three Fiber skill package (24) | ✅ `3d` |
| **Data-flow visualization** | Understand-Anything (interactive API/service/data graph) · oh-my-mermaid (Mermaid data-flow docs) · Mermaid + C4 skills | ✅ `dataflow` |
| **Workflow discipline** | Superpowers (brainstorm → plan → TDD → verify) · Anthropic webapp-testing / mcp-builder | opt-in `workflow` |
| **MCP servers** | playwright · github · agentmemory · context7 · shadcn · chrome-devtools | ✅ `core` |
| **More MCP** | next-devtools · deepwiki · excalidraw · figma · sentry · appmap | opt-in `--mcp all` |
| **Global rules** | Design-skill precedence + "map the data flow first" | ✅ appended, never duplicated |
| **Codebase graph + memory** | CodeGraph · GitNexus · agentmemory | ✅ |
| **Bundled skills** | animation-designer · immersive-3d-web · gsd-for-cursor | ✅ |
| **GSD workflows** | 27 `/gsd-*` commands | Cursor |

Full catalog, install routes and the data-flow tool comparison: **[docs/SKILLS-AND-TOOLS.md](./docs/SKILLS-AND-TOOLS.md)**.

### Supported agents

| Agent | Skills | MCP | Global rules | GSD |
|-------|:-----:|:---:|:-----:|:---:|
| Claude Code | ✅ (plugins + skills) | ✅ via `claude mcp` | ✅ `~/.claude/CLAUDE.md` | upstream |
| Cursor | ✅ | ✅ | per-project `AGENTS.md` | ✅ |
| OpenAI Codex CLI | ✅ | ✅ `config.toml` | ✅ `~/.codex/AGENTS.md` | — |
| Gemini CLI | ✅ | ✅ | ✅ `~/.gemini/GEMINI.md` | — |
| Antigravity (IDE + `agy`) | ✅ | ✅ | ✅ `~/.gemini/GEMINI.md` | — |
| GitHub Copilot (VS Code) | ✅ | ✅ | ✅ `~/.copilot/instructions/` | — |
| Windsurf / Devin Desktop | ✅ | ✅ | ✅ `global_rules.md` | — |
| OpenCode | ✅ | ✅ | ✅ | — |
| Kiro | ✅ | ✅ | ✅ steering | — |
| Cline | ✅ | in-app | per-project | — |

Paths and config dialects for each agent: **[docs/IDE-PATHS.md](./docs/IDE-PATHS.md)**.

---

## How it works

```
config/skill-packs.json ─┐
config/mcp-servers.json ─┼──▶ scripts/lib/powerup.mjs ──▶ each agent, in its own format
src/rules/*.md ──────────┤        ▲                         (skills dir · MCP JSON/TOML · rules file)
src/skills/* ────────────┘        │
                     scripts/lib/agents.mjs  (paths + dialects for 10 agents)
```

For each skill and each agent, the first route that applies wins:

1. **Claude Code plugin**, when one exists.
2. **The upstream README's own installer**, e.g. `npx impeccable install` or `uipro init`.
3. **`npx skills add`**, the universal fallback for 70+ agents.

**Safety:** existing skills, MCP entries and rules text are never overwritten. Every edited config gets a one-time `*.powerup-backup` copy. `--force` re-installs skills and refreshes only the blocks this repo wrote.

### CLI flags

| Flag (bash) | PowerShell | Description |
|-------------|-----------|-------------|
| `--agents <spec>` | `-Agents` | `detected` (default) · `all` · comma list of ids |
| `--packs <spec>` | `-Packs` | `default` · `all` · `none` · `ui-design,motion,3d,dataflow,workflow` |
| `--mcp <spec>` | `-Mcp` | `core` (default) · `extra` · `all` · `none` · server names |
| `--dry-run` | `-DryRun` | Print the plan; change nothing |
| `--force` | `-Force` | Re-install skills/plugins; refresh this repo's rule blocks |
| `--non-interactive` | — | No prompts (defaults to `--agents detected`) |
| `--gsd-only` / `--powerup-only` | `-GsdOnly` / `-PowerupOnly` | GSD copy only / skip GSD copy |
| `--ide cursor\|vscode\|antigravity\|all` | — | Legacy alias for `--agents` |

---

## Per-project setup (any agent)

```bash
node ~/path/to/cursor-powered-up/scripts/lib/powerup.mjs project-init --dir .
```

This writes a shared `AGENTS.md` (read by Codex, Cursor, Copilot, Windsurf, OpenCode, Antigravity and Kiro) and a `CLAUDE.md` containing `@AGENTS.md` for Claude Code. Every agent in the repo then follows the same design precedence and data-flow rules.

To see how data moves through the app:

```text
/understand-dashboard      # Understand-Anything: interactive API → service → data graph
/omm-scan                  # oh-my-mermaid: data-flow + architecture diagrams in .omm/
```

---

## GSD Commands (Cursor)

```
/gsd-new-project        # bootstrap + questioning → research → requirements → roadmap
/gsd-map-codebase       # map an existing codebase (CodeGraph + GitNexus)
/gsd-discuss-phase N    # capture implementation decisions
/gsd-plan-phase N       # create executable plans
/gsd-execute-phase N    # execute plans with atomic commits + auto re-index
/gsd-verify-work N      # user acceptance testing
/gsd-help               # full command list
```

Claude Code users: GSD is available natively from the upstream [get-shit-done](https://github.com/glittercowboy/get-shit-done) package.

---

## Screenshots

![Cursor Opening Subagents](assets/mapcodebase.png)

![Cursor GSD Commands](assets/commands.png)

---

## Documentation

| Document | Description |
|----------|-------------|
| [docs/POST-INSTALL.md](./docs/POST-INSTALL.md) | Post-install steps: tokens, agentmemory, 21st.dev, per-project rules, verification |
| [docs/SKILLS-AND-TOOLS.md](./docs/SKILLS-AND-TOOLS.md) | Every skill, MCP server and tool, how it's installed, and how to add your own |
| [docs/IDE-PATHS.md](./docs/IDE-PATHS.md) | Skills / MCP / rules paths and dialects for each agent |
| [docs/PORTABLE-SETUP.md](./docs/PORTABLE-SETUP.md) | New machine restore guide |
| [docs/GSD-CURSOR-ADAPTATION.md](./docs/GSD-CURSOR-ADAPTATION.md) | GSD → Cursor adaptation details |
| [CHANGELOG.md](./CHANGELOG.md) | Version history |
| [MIGRATION.md](./MIGRATION.md) | Updating from upstream GSD |

---

## Credits

- Original GSD system: [glittercowboy/get-shit-done](https://github.com/glittercowboy/get-shit-done)
- Cursor adaptation: Royi Mindel
- Skills by their authors: Paul Bakaus (Impeccable), Leonxlnx (Taste Skill), Anthropic, nextlevelbuilder, Emil Kowalski, GreenSock, Impertio Studio, ibelick, Vercel, Egonex-AI, oh-my-mermaid, softaworks, Jesse Vincent (Superpowers)
- Power-up packaging: cursor-powered-up

MIT License — see [LICENSE](./LICENSE).
