# Portable setup — new machine restore

Everything installs from a single clone and one script, for every AI coding agent on the machine.

## New machine — restore everything

```bash
# macOS / Linux
git clone https://github.com/umer-jahangier/cursor-powered-up.git
cd cursor-powered-up
./scripts/install.sh --agents detected --non-interactive
```

```powershell
# Windows (PowerShell)
git clone https://github.com/umer-jahangier/cursor-powered-up.git
cd cursor-powered-up
.\scripts\install.ps1 -Agents detected
```

Install your AI agents **before** running the installer so they are detected. If you add an agent later, re-run the installer. It only adds what is missing.

## After install — manual steps

**Add to `~/.zshrc`** (Mac/Linux), then run `source ~/.zshrc`:

```bash
export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_your_token_here
```

**Windows**: add to your PowerShell profile (`$PROFILE`):

```powershell
$env:GITHUB_PERSONAL_ACCESS_TOKEN = "ghp_your_token_here"
```

## Every coding session

```bash
agentmemory    # keep terminal open — serves memory MCP on :3111
```

Restart every agent / IDE after the first install. MCP servers, skills and hooks load at startup.

## Per project

| Situation | Command |
|-----------|---------|
| Shared rules for every agent | `node <repo>/scripts/lib/powerup.mjs project-init --dir .` |
| See data / API flow | `/understand-dashboard` or `/omm-scan` |
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
| `src/skills/animation-designer/` | every selected agent's skills dir |
| `src/skills/immersive-3d-web/` | every selected agent's skills dir |
| `scripts/cursor-powerup-reindex.sh` | `~/.cursor/get-shit-done/scripts/` |
| `config/skill-packs.json` | every agent's skills dir (see [IDE-PATHS.md](./IDE-PATHS.md)) |
| `config/mcp-servers.json` | every agent's MCP config, in its own dialect |
| `src/rules/*.md` | every agent's global rules file (marker-guarded blocks) |

**Not in repo** (machine state): tokens (read from env vars, never written to config), the agentmemory DB, and `.codegraph/` per project.

## Verify

```bash
node scripts/lib/powerup.mjs status
cat ~/.agents/POWERUP-INSTALLED.md
which agentmemory codegraph agnix gitnexus omm
# In Cursor:
/gsd-help
```
