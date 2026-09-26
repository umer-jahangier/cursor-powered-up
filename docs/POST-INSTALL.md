# Post-Install Guide — Enable Full Power

> Run these steps **after** `./scripts/install.sh` (or `install.ps1`) completes.
> The installer handles everything it can. These steps need your own credentials or a per-project decision.

---

## Step 1 — Restart your agents

New MCP servers, skills and plugins load at startup. **Quit and reopen** every IDE, and start a new session in every CLI agent (Claude Code, Codex, Gemini, `agy`, OpenCode).

---

## Step 2 — Set environment variables

Add to `~/.zshrc` (macOS) or `~/.bashrc` (Linux):

```bash
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here
```

```bash
source ~/.zshrc
```

On Windows, add this to your PowerShell profile (`$PROFILE`):

```powershell
$env:GITHUB_PERSONAL_ACCESS_TOKEN = "ghp_your_token_here"
```

Create a token at [github.com/settings/tokens](https://github.com/settings/tokens) with the scopes `repo` and `read:org`.
Every agent's GitHub MCP entry reads this variable in that agent's own syntax (see [IDE-PATHS.md](./IDE-PATHS.md#token-headers-github-mcp)). The token is never written into a config file.

---

## Step 3 — Start agentmemory each session

```bash
agentmemory      # keep this terminal open; serves the memory MCP on :3111
```

---

## Step 4 — 21st.dev Magic MCP

[21st.dev](https://21st.dev) Magic generates polished React UI components. It **needs your own API key** (free tier available).

```bash
# Claude Code
claude mcp add magic --scope user --env API_KEY="YOUR_KEY" -- npx -y @21st-dev/magic@latest
# Cursor / Windsurf / VS Code (best-effort)
npx -y @21st-dev/cli@latest install cursor   --api-key "YOUR_KEY"
npx -y @21st-dev/cli@latest install windsurf --api-key "YOUR_KEY"
npx -y @21st-dev/cli@latest install vscode   --api-key "YOUR_KEY"
```

For other agents, add the server to their MCP file by hand, using the formats in [IDE-PATHS.md](./IDE-PATHS.md).
21st.dev components use [Motion](https://motion.dev). Install it per project with `npm install motion`, or `framer-motion` in older projects.

---

## Step 5 — Per-project rules (every agent)

Run this once in each repo so every agent follows the same rules:

```bash
node ~/path/to/cursor-powered-up/scripts/lib/powerup.mjs project-init --dir .
```

It creates or appends `AGENTS.md`, and creates `CLAUDE.md` containing `@AGENTS.md` if you don't have one. It only appends, so existing content is kept.

**Cursor + GSD** — then bootstrap with:

```
/gsd-new-project       # new project
/gsd-map-codebase      # existing codebase (CodeGraph + GitNexus)
```

For other agents, run `codegraph init -i` and `npx gitnexus analyze` in the project root to build the code graphs.

---

## Step 6 — See how your data flows (first run)

Run these inside your agent, in the project:

| Command | Result |
|---------|--------|
| `/understand` then `/understand-dashboard` | Interactive knowledge graph: API → service → data → UI layers. The first run on a large repo takes a few minutes. |
| `/understand-domain` | Business/request flow graph |
| `/omm-scan`, then `omm view` in a terminal | Mermaid architecture and data-flow diagrams in `.omm/` (commit them) |

Claude Code runs `/understand` as a plugin command. In other agents, ask for the skill by name, e.g. "use the understand skill".
For **runtime** API → SQL traces, see AppMap in [SKILLS-AND-TOOLS.md](./SKILLS-AND-TOOLS.md#manual-only-tools).

---

## Step 7 — Optional extras

```bash
./scripts/install.sh --agents detected --mcp all          # figma, sentry, deepwiki, excalidraw, next-devtools
./scripts/install.sh --agents detected --packs workflow   # Superpowers + Anthropic dev skills
```

Figma and Sentry ask you to sign in with OAuth the first time an agent uses them.

---

## Step 8 — Verify

```bash
node scripts/lib/powerup.mjs status                        # agents detected, skill counts, MCP files
node scripts/lib/powerup.mjs all --dry-run                 # anything still missing? (should be all "exists")
cat ~/.agents/POWERUP-INSTALLED.md                         # install record
curl -sf http://localhost:3111/agentmemory/health && echo "memory OK"
```

Checks inside each agent:

| Agent | Check |
|-------|-------|
| Claude Code | `claude mcp list` · `claude plugin list` · `/impeccable` |
| Cursor | Settings → MCP (servers should be green) · `/gsd-help` |
| Codex | `codex mcp list` |
| Gemini CLI | `/mcp` · `/skills` |
| VS Code | Enable `chat.mcp.discovery.enabled`, then check the tools list in Copilot Chat |
| Antigravity | Agent panel → MCP servers |

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `agentmemory` / `omm` not found | Add `$HOME/.npm-global/bin` to PATH (Step 2), then open a new terminal |
| GitHub MCP unauthorized | Set `GITHUB_PERSONAL_ACCESS_TOKEN`, then restart the agent |
| Status table shows `skipped … not plain JSON` | That config has comments. Add the servers from `config/mcp-servers.json` by hand |
| A skill didn't update | Re-run with `--force`. Existing skills are left alone by default |
| `ui-ux-pro-max` search script fails | It needs `python3` on PATH |
| Want to undo a config change | Every edited file has a `<file>.powerup-backup` of its original |
| GSD commands missing (Cursor) | `./scripts/install.sh --agents cursor --force` |
| Stale code graph | `npx gitnexus analyze` / `codegraph sync` in the project root |

---

See also: [IDE-PATHS.md](./IDE-PATHS.md) · [SKILLS-AND-TOOLS.md](./SKILLS-AND-TOOLS.md) · [PORTABLE-SETUP.md](./PORTABLE-SETUP.md)
