# Post-Install Guide — Enable Full Cursor Power

> Run these steps **after** `./scripts/install.sh` completes (or `.\scripts\install.ps1` on Windows).
> The installer handles all the heavy lifting; these are the manual steps that require your own credentials and preferences.

---

## Step 1 — Restart Cursor

The new MCP servers (agentmemory, playwright, github) and hooks only activate after a full restart.

**Close and reopen Cursor** before continuing.

---

## Step 2 — Set environment variables

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

## Step 3 — Start agentmemory each session

The agent memory server must be running for the memory MCP to work. Run this in a terminal and keep it open:

```bash
agentmemory
```

> Tip: open a dedicated terminal tab for agentmemory and leave it running while you code.

---

## Step 4 — 21st.dev MCP (optional — UI components)

[21st.dev](https://21st.dev) provides an MCP server that lets Cursor agents generate polished React UI components on demand, with built-in [framer-motion](https://www.framer.com/motion/) animations and modern design patterns.

**This step requires your own 21st.dev API key** (free tier available). Get one at [21st.dev dashboard](https://21st.dev).

```bash
npx -y @21st-dev/cli@latest install cursor --api-key "YOUR_21ST_DEV_API_KEY"
```

Replace `YOUR_21ST_DEV_API_KEY` with your actual key. The CLI writes the MCP entry to `~/.cursor/mcp.json` automatically.

### What 21st.dev unlocks

| Capability | Notes |
|------------|-------|
| On-demand React component generation | Ask Cursor to "build a hero section with 21st.dev" |
| framer-motion animation patterns | Components ship with motion presets |
| Tailwind + shadcn-compatible output | Integrates cleanly with modern stacks |
| Design system coherence | Consistent tokens across generated components |

### framer-motion in your project

When using 21st.dev-generated components, ensure `framer-motion` is in your project:

```bash
npm install framer-motion
# or
pnpm add framer-motion
```

The following skills already installed at `~/.cursor/skills/` pair naturally with 21st.dev:

- `design-taste-frontend` — high-agency interfaces with calibrated color and motion
- `high-end-visual-design` — agency-grade premium interfaces
- `gpt-taste` — GSAP-heavy pages with bento grids
- `stitch-design-taste` — design systems with motion intent

---

## Step 5 — Bootstrap each project

For a **new project**:

```
/gsd-new-project
```

For an **existing codebase** (brownfield):

```
/gsd-map-codebase
```

This runs CodeGraph indexing and GitNexus analysis, creating `.codegraph/` and `AGENTS.md` in the repo.

---

## Step 6 — Verify the full setup

```bash
bash ~/.cursor/skills/cursor-powerup/scripts/verify-setup.sh
```

Or check manually:

```bash
# Tools installed
which agentmemory codegraph agnix gitnexus

# MCP wired
cat ~/.cursor/mcp.json

# Skills installed
ls ~/.cursor/skills/

# agentmemory health
curl -sf http://localhost:3111/agentmemory/health && echo "agentmemory OK" || echo "WARN: start agentmemory"
```

---

## Quick-reference checklist

```
[ ] Cursor restarted
[ ] PATH + GITHUB_PERSONAL_ACCESS_TOKEN in ~/.zshrc
[ ] agentmemory running in a terminal
[ ] (optional) 21st.dev MCP installed with your API key
[ ] /gsd-new-project or /gsd-map-codebase run in each repo
[ ] verify-setup.sh passes
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `agentmemory: command not found` | Add `$HOME/.npm-global/bin` to PATH (Step 2) |
| GitHub MCP not working | Set `GITHUB_PERSONAL_ACCESS_TOKEN` and restart Cursor |
| 21st.dev MCP not responding | Re-run install command; verify key at 21st.dev dashboard |
| GSD commands not found | Run `./scripts/install.sh --force` from the cloned repo |
| GitNexus warnings about stale index | Run `npx gitnexus analyze` in the project root |

---

See also: [docs/PORTABLE-SETUP.md](./PORTABLE-SETUP.md) for setting up on a new machine.
