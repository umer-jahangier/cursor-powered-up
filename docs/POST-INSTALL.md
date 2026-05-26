# Post-Install Guide — Enable Full Power

> Run these steps **after** `./scripts/install.sh` completes.
> The installer handles all the heavy lifting; these are the manual steps that require your own credentials and preferences.

---

## Step 1 — Restart Your IDE

The new MCP servers (agentmemory, playwright, github) only activate after a full restart.

**Close and reopen your IDE** before continuing.

---

## Step 2 — Set Environment Variables

Add to `~/.zshrc` (macOS/Linux) or `~/.bashrc` (Linux):

```bash
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here
```

Then reload:

```bash
source ~/.zshrc
```

Get a GitHub PAT at [github.com/settings/tokens](https://github.com/settings/tokens) — scopes: `repo`, `read:org`.

---

## Step 3 — Start agentmemory Each Session

The agent memory server must be running for the memory MCP to work. Run this in a terminal and keep it open:

```bash
agentmemory
```

> Tip: open a dedicated terminal tab for agentmemory and leave it running while you code.

---

## Step 4 — 21st.dev MCP — UI Components

[21st.dev](https://21st.dev) provides an MCP server that lets AI agents generate polished React UI components. **This step requires your own 21st.dev API key** (free tier available at [21st.dev dashboard](https://21st.dev)).

### For Cursor

```bash
npx -y @21st-dev/cli@latest install cursor --api-key "YOUR_21ST_DEV_API_KEY"
```

### For VS Code

```bash
npx -y @21st-dev/cli@latest install vscode --api-key "YOUR_21ST_DEV_API_KEY"
```

### For Antigravity

21st.dev CLI does not currently support Antigravity. Add the MCP entry manually to `mcp_config.json` if/when support is available.

**After running the command:** restart your IDE, then verify the server is active in MCP settings.

---

## Step 5 — Framer Motion (for animated React UI)

21st.dev-generated components use [framer-motion](https://www.framer.com/motion/) for animations. Install it in each React/Next.js project:

```bash
npm install framer-motion
```

---

## Step 6 — Bootstrap Each Project (Cursor only)

For a **new project**:

```
/gsd-new-project
```

For an **existing codebase** (brownfield):

```
/gsd-map-codebase
```

This runs CodeGraph indexing and GitNexus analysis.

> **Note:** GSD commands are Cursor-exclusive. VS Code and Antigravity users: run `codegraph init -i` in project roots for codebase indexing.

---

## Step 7 — Verify the Full Setup

### Cursor

```bash
# Tools installed
which agentmemory codegraph agnix gitnexus

# MCP wired
cat ~/.cursor/mcp.json

# Skills installed
ls ~/.cursor/skills/ | wc -l

# agentmemory health
curl -sf http://localhost:3111/agentmemory/health && echo "OK" || echo "WARN: start agentmemory"
```

### VS Code

```bash
# Skills installed
ls ~/.vscode/skills/ | wc -l

# MCP config (macOS)
cat "$HOME/Library/Application Support/Code/User/mcp.json"

# Enable MCP discovery in VS Code settings:
# chat.mcp.discovery.enabled = true
```

### Antigravity

```bash
# Skills installed
ls ~/.agents/skills/ | wc -l

# MCP config (macOS)
cat "$HOME/Library/Application Support/Antigravity/User/mcp_config.json"
```

---

## Quick-Reference Checklist

### All IDEs

```
[ ] IDE restarted after install
[ ] PATH + GITHUB_PERSONAL_ACCESS_TOKEN in ~/.zshrc
[ ] agentmemory running each session
[ ] framer-motion added to React projects
```

### Cursor-specific

```
[ ] 21st.dev MCP installed → Cursor Settings → MCP → 21st = green
[ ] /gsd-new-project or /gsd-map-codebase run in each repo
```

### VS Code-specific

```
[ ] chat.mcp.discovery.enabled = true in VS Code settings
[ ] 21st.dev MCP installed
[ ] MCP servers visible in Copilot chat tools
```

### Antigravity-specific

```
[ ] Skills discoverable via @skill-name in agent chat
[ ] MCP servers active
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `agentmemory: command not found` | Add `$HOME/.npm-global/bin` to PATH (Step 2) |
| GitHub MCP not working | Set `GITHUB_PERSONAL_ACCESS_TOKEN` and restart IDE |
| 21st.dev MCP not responding | Re-run install command; verify key at 21st.dev dashboard |
| GSD commands not found (Cursor) | Run `./scripts/install.sh --ide cursor --force` |
| GitNexus stale index | Run `npx gitnexus analyze` in project root |
| VS Code MCP tools not showing | Enable `chat.mcp.discovery.enabled` in settings |
| Antigravity skills not found | Verify `~/.agents/skills/` contains SKILL.md files |

---

See also:
- [docs/IDE-PATHS.md](./IDE-PATHS.md) for the full paths reference
- [docs/PORTABLE-SETUP.md](./PORTABLE-SETUP.md) for setting up on a new machine
