# Portable setup — new machine restore

Everything installs from a single clone + one script.

## New machine — restore everything

```bash
# macOS / Linux
git clone https://github.com/umer-jahangier/cursor-powered-up.git
cd cursor-powered-up
./scripts/install.sh
```

```powershell
# Windows (PowerShell)
git clone https://github.com/umer-jahangier/cursor-powered-up.git
cd cursor-powered-up
.\scripts\install.ps1
```

## After install — manual steps

**Add to `~/.zshrc`** (Mac/Linux) then `source ~/.zshrc`:

```bash
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here
```

**Windows** — add to PowerShell profile (`$PROFILE`):

```powershell
$env:GITHUB_PERSONAL_ACCESS_TOKEN = "ghp_your_token_here"
```

## Every coding session

```bash
agentmemory    # keep terminal open — serves memory MCP on :3111
```

Restart **Cursor** after first install (MCP + hooks take effect on restart).

## Per project

| Situation | Command |
|-----------|---------|
| New project | `/gsd-new-project` in Cursor |
| Existing project | `/gsd-map-codebase` in Cursor |
| Re-index only | `bash ~/.cursor/get-shit-done/scripts/cursor-powerup-reindex.sh` |

## What's installed where

| In this repo | Installed to |
|--------------|-------------|
| `src/commands/gsd/*` | `~/.cursor/commands/gsd/` |
| `src/agents/*` | `~/.cursor/agents/` |
| `src/workflows/*` | `~/.cursor/get-shit-done/workflows/` |
| `src/templates/*` | `~/.cursor/get-shit-done/templates/` |
| `src/references/*` | `~/.cursor/get-shit-done/references/` |
| `src/hooks/*` | `~/.cursor/hooks/` |
| `src/skills/gsd-for-cursor/` | `~/.cursor/skills/gsd-for-cursor/` |
| `src/skills/animation-designer/` | `~/.cursor/skills/animation-designer/` |
| `src/skills/immersive-3d-web/` | `~/.cursor/skills/immersive-3d-web/` |
| `scripts/cursor-powerup-reindex.sh` | `~/.cursor/get-shit-done/scripts/` |

**Not in repo** (machine state): `~/.cursor/mcp.json` secrets, agentmemory DB, `.codegraph/` per project.

## Verify

```bash
cat ~/.cursor/POWERUP-INSTALLED.md
which agentmemory codegraph agnix
cat ~/.cursor/mcp.json
# In Cursor:
/gsd-help
```
