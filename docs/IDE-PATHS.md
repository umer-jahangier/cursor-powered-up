# Agent Paths Reference

Where each AI coding agent keeps its skills, MCP servers and rules, and the dialect each one expects.
The installer encodes all of this in [`scripts/lib/agents.mjs`](../scripts/lib/agents.mjs). To fix or add a path, change that one file.

> Verified 2026-09-27 against official docs. `~` = home directory (`%USERPROFILE%` on Windows).
> Run `node scripts/lib/powerup.mjs status` to see what is detected on your machine.

---

## Summary

| Agent (`--agents` id) | Global skills dir | User MCP config | MCP top-level key · remote URL key | Global rules file |
|---|---|---|---|---|
| Claude Code (`claude-code`) | `~/.claude/skills/` | `~/.claude.json`, written via `claude mcp add-json --scope user` | `mcpServers` · `type:"http"` + `url` | `~/.claude/CLAUDE.md` |
| Cursor (`cursor`) | `~/.cursor/skills/`, also reads `~/.agents/skills/`, `~/.claude/skills/` | `~/.cursor/mcp.json` | `mcpServers` · `url` | Settings UI only. Use `AGENTS.md` / `.cursor/rules/*.mdc` per project |
| OpenAI Codex CLI (`codex`) | `~/.codex/skills/` (`npx skills`), `~/.agents/skills/` | `~/.codex/config.toml` | `[mcp_servers.<name>]` · `url` + `bearer_token_env_var` | `~/.codex/AGENTS.md` |
| Gemini CLI (`gemini-cli`) | `~/.gemini/skills/` | `~/.gemini/settings.json` | `mcpServers` · `httpUrl` (streamable HTTP; `url` means SSE) | `~/.gemini/GEMINI.md` |
| Antigravity IDE + `agy` CLI (`antigravity`) | `~/.gemini/config/skills/` (IDE also reads legacy `~/.gemini/antigravity/skills/`) ³ | `~/.gemini/config/mcp_config.json` ¹ | `mcpServers` · **`serverUrl`** | `~/.gemini/GEMINI.md` (shared with Gemini CLI) |
| GitHub Copilot in VS Code (`github-copilot`) | `~/.copilot/skills/`, also `~/.claude/skills/`, `~/.agents/skills/` | User `mcp.json` ² | **`servers`** · `type:"http"` + `url` | `~/.copilot/instructions/*.instructions.md` |
| Windsurf / Devin Desktop (`windsurf`) | `~/.codeium/windsurf/skills/` | `~/.config/devin/mcp_config.json` (or legacy `~/.codeium/windsurf/mcp_config.json`) | `mcpServers` · **`serverUrl`** | `~/.codeium/windsurf/memories/global_rules.md` (6,000-char limit) |
| OpenCode (`opencode`) | `~/.config/opencode/skills/` | `~/.config/opencode/opencode.json` | **`mcp`** · `type:"local"` (command array) / `type:"remote"` | `~/.config/opencode/AGENTS.md` |
| Kiro (`kiro`) | `~/.kiro/skills/` | `~/.kiro/settings/mcp.json` | `mcpServers` · `url` | `~/.kiro/steering/*.md` |
| Cline (`cline`) | `~/.agents/skills/` | configure in-app (path varies by release) | `mcpServers` | `.clinerules/` per project |

¹ In 2026, Antigravity moved from `~/Library/Application Support/Antigravity/User/mcp_config.json` to `~/.gemini/config/mcp_config.json`. `~/.gemini/antigravity/mcp_config.json` is kept as a symlink to it. v3 of this repo still wrote to the old path. v4 fixes that.

² VS Code user `mcp.json`: macOS `~/Library/Application Support/Code/User/mcp.json` · Linux `~/.config/Code/User/mcp.json` · Windows `%APPDATA%\Code\User\mcp.json`. VS Code authenticates the GitHub MCP itself, so no token header is written. If this file contains comments (JSONC), the installer leaves it untouched and tells you.

³ `npx skills` v1.7 installs Antigravity's global skills into the shared `~/.agents/skills`, but Antigravity only reads that folder inside a workspace. The installer symlinks them into `~/.gemini/config/skills` (a junction on Windows).

---

## Token headers (GitHub MCP)

Each agent references environment variables differently. The installer writes the right form for each one:

| Agent | Written as |
|---|---|
| Claude Code | `Bearer ${GITHUB_PERSONAL_ACCESS_TOKEN}` |
| Cursor, Antigravity, Windsurf | `Bearer ${env:GITHUB_PERSONAL_ACCESS_TOKEN}` |
| Gemini CLI | `Bearer $GITHUB_PERSONAL_ACCESS_TOKEN` |
| OpenCode | `Bearer {env:GITHUB_PERSONAL_ACCESS_TOKEN}` |
| Codex | `bearer_token_env_var = "GITHUB_PERSONAL_ACCESS_TOKEN"` |
| VS Code | no header; uses VS Code's GitHub sign-in |
| Kiro | skipped because the env syntax is unverified. Add it by hand |

---

## Project-level files (per repo)

`node scripts/lib/powerup.mjs project-init --dir <repo>` sets these up once, so every agent in that repo shares the same rules:

| File | Read by |
|---|---|
| `AGENTS.md` | Codex, Cursor, Copilot, Windsurf/Devin, OpenCode, Antigravity, Kiro, Gemini (if `context.fileName` includes it) |
| `CLAUDE.md` containing `@AGENTS.md` | Claude Code, which imports AGENTS.md |

Agent-specific project files you may still want: `.cursor/rules/*.mdc` (Cursor, needs frontmatter), `.github/copilot-instructions.md`, `.windsurf/rules/`, `.kiro/steering/`.

---

## What's agent-exclusive

| Feature | Available for |
|---|---|
| GSD `/gsd-*` commands, agents, hooks from this repo | Cursor. Claude Code users get GSD from the upstream `get-shit-done` package |
| Claude Code plugins (Impeccable, frontend-design, UI UX Pro Max, Understand-Anything, oh-my-mermaid, Superpowers) | Claude Code. Other agents get the same skills via native installers or `npx skills` |
| Everything else (skill packs, MCP, rules) | All agents above |

---

## Adding a new agent

1. Add an entry to `AGENTS` in `scripts/lib/agents.mjs`. It needs:
   - `skillsId`, the `npx skills -a` id (full list: [vercel-labs/skills](https://github.com/vercel-labs/skills#supported-agents))
   - `skillsDir`
   - a `detect()` function
   - an `mcp` dialect
   - a `rules` file
2. Preview the result with `node scripts/lib/powerup.mjs all --agents <new-id> --dry-run`.
