---
name: gsd-for-cursor
description: Runs Get Shit Done (GSD) spec-driven workflows in Cursor via /gsd slash commands. Use when planning phases, executing roadmaps, mapping codebases, verifying work, debugging with GSD, or when the user mentions GSD, get-shit-done, or phase/milestone planning.
---

# GSD for Cursor (power-up edition)

Source repo: `cursor-powered-up` → `./scripts/install.sh` installs everything to `~/.cursor/`.

## Commands

```
/gsd-help
/gsd-new-project        # Phase 1.5 power-up bootstrap + planning
/gsd-map-codebase       # Brownfield map + bootstrap if missing
/gsd-execute-phase N    # Executes plans + auto re-index before verify
```

## Automatic (no user action)

| When | What |
|------|------|
| `/gsd-new-project` | CodeGraph init/index, GitNexus, `.cursor/rules/`, `CURSOR-POWERUP.md` |
| `/gsd-map-codebase` | Same bootstrap if `CURSOR-POWERUP.md` missing |
| `/gsd-execute-phase` | `cursor-powerup-reindex.sh` after plans, before verification |
| While coding | CodeGraph MCP file watcher (incremental sync) |

## Manual reminders — tell the user when relevant

**Every session (global):**

1. Run `agentmemory` in a terminal (memory MCP needs `:3111`).
2. Optional: open http://localhost:3113 for memory viewer.

**Once per machine (global):**

1. `export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_...` in `~/.zshrc` → restart Cursor.
2. `export PATH="$HOME/.npm-global/bin:$PATH"` in `~/.zshrc` (for `codegraph`, `agentmemory`).

**After huge refactor outside GSD** (or if graphs feel wrong):

```bash
bash ~/.cursor/get-shit-done/scripts/cursor-powerup-reindex.sh
```

**New machine / reinstall:**

```bash
git clone https://github.com/umer-jahangier/cursor-powered-up.git
cd cursor-powered-up
./scripts/install.sh
# Then: agentmemory + GITHUB_PERSONAL_ACCESS_TOKEN in ~/.zshrc, restart Cursor
```

See `docs/PORTABLE-SETUP.md` in the repo.

## References

- Bootstrap: `~/.cursor/get-shit-done/references/cursor-powerup-bootstrap.md`
- Re-index: `~/.cursor/get-shit-done/references/cursor-powerup-reindex.md`
- Portable setup: `docs/PORTABLE-SETUP.md`

## Agent behavior

At **start** of `/gsd-new-project` or `/gsd-execute-phase`, if agentmemory health fails or `GITHUB_PERSONAL_ACCESS_TOKEN` is unset, output a **short reminder block** (3 lines max) — do not block the workflow.
