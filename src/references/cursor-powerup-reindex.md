# Cursor Power-Up Re-index

Run after `/gsd-execute-phase` completes (automatic) or when the graph feels stale.

## Script (preferred)

```bash
bash ~/.cursor/get-shit-done/scripts/cursor-powerup-reindex.sh
```

From repo source before install:

```bash
bash scripts/cursor-powerup-reindex.sh
```

## What it does

1. `codegraph index` (or init + index if missing)
2. `npx gitnexus analyze`
3. Appends timestamp to `.planning/CURSOR-POWERUP.md`
4. Prints **manual reminders** (agentmemory server, GitHub PAT)

## When execute-phase runs it

Automatically **after all plans in the phase finish** and **before phase verification** — so the verifier and next phase use an up-to-date graph.

Does not replace CodeGraph’s live file watcher during editing; this is a full refresh after bulk changes.

## Manual only (never automated)

| Item | Action |
|------|--------|
| agentmemory | `agentmemory` in a terminal each Mac session |
| GitHub MCP | `export GITHUB_PERSONAL_ACCESS_TOKEN=...` in `~/.zshrc` |
| Restart Cursor | After MCP or env changes |
| New machine | `./scripts/install.sh --force` + `./scripts/install-cursor-powerup.sh` |
