# IDE Paths Reference

> Research document for multi-IDE installer. Covers skills directories, MCP config paths, and tool-specific commands for each supported IDE.

---

## Summary Table

| Tool / Feature | Cursor | VS Code (Copilot) | Antigravity |
|----------------|--------|-------------------|-------------|
| **Skills dir** | `~/.cursor/skills/` | `~/.vscode/skills/` (user-created) | `~/.agents/skills/` |
| **MCP config** | `~/.cursor/mcp.json` | User profile `mcp.json` ¹ | `~/Library/Application Support/Antigravity/User/mcp_config.json` (macOS) or `~/.config/Antigravity/User/mcp_config.json` (Linux) |
| **MCP key format** | `"mcpServers": {}` | `"servers": {}` | `"mcpServers": {}` |
| **agentmemory connect** | `agentmemory connect cursor` | Manual MCP block ² | `agentmemory connect antigravity` |
| **GSD commands** | `~/.cursor/commands/gsd/` | N/A (Cursor-exclusive) | N/A (Cursor-exclusive) |
| **21st.dev CLI** | `npx @21st-dev/cli install cursor --api-key KEY` | `npx @21st-dev/cli install vscode --api-key KEY` ³ | N/A |
| **CodeGraph** | `codegraph init -i` (auto-detects) | `codegraph init -i` (auto-detects) | `codegraph init -i` (auto-detects) |
| **antigravity-awesome-skills** | `npx antigravity-awesome-skills --path ~/.cursor/skills --category development,backend --risk safe` | `npx antigravity-awesome-skills --path ~/.vscode/skills --category development,backend --risk safe` | `npx antigravity-awesome-skills --path ~/.agents/skills --category development,backend --risk safe` |

¹ VS Code user-level MCP path varies by OS:
- macOS: `~/Library/Application Support/Code/User/mcp.json`
- Linux: `~/.config/Code/User/mcp.json`
- Windows: `%APPDATA%\Code\User\mcp.json`

² No `agentmemory connect vscode` command exists. The MCP block must be written manually to the VS Code user mcp.json using the `"servers"` key (not `"mcpServers"`).

³ 21st.dev CLI `install vscode` support is unconfirmed as of 2026-05. Documented as best-effort.

---

## Detailed Notes

### Cursor

- **Skills**: `~/.cursor/skills/` — Cursor auto-discovers `SKILL.md` files via their description field
- **MCP**: `~/.cursor/mcp.json` — uses `"mcpServers"` as the top-level key
- **Hooks**: `~/.cursor/hooks/` — JS files, registered via `~/.cursor/settings.json`
- **Commands**: `~/.cursor/commands/` — slash commands available in chat
- **agentmemory**: `agentmemory connect cursor` writes the MCP entry automatically

### VS Code (with GitHub Copilot)

- **Skills**: No native skills directory. We use `~/.vscode/skills/` as a convention
  - Copilot discovers context via `.github/copilot-instructions.md` (project-level) or MCP tools
  - Skills at the user level need to be referenced manually or via MCP context providers
- **MCP**: `.vscode/mcp.json` (workspace) or user-level `mcp.json` (via Command Palette → "MCP: Open User Configuration")
  - Uses `"servers"` key (NOT `"mcpServers"`)
  - Format: `{"servers": {"name": {"command": "...", "args": [...]}}}`
- **agentmemory**: No dedicated connect command. Write MCP block manually:
  ```json
  {
    "servers": {
      "agentmemory": {
        "command": "npx",
        "args": ["-y", "@agentmemory/mcp"],
        "env": { "AGENTMEMORY_URL": "http://localhost:3111" }
      }
    }
  }
  ```
- **Hooks**: Not applicable (no hook system equivalent to Cursor)

### Antigravity

- **Skills**: `~/.agents/skills/` — default path for `npx antigravity-awesome-skills`
- **MCP**: `mcp_config.json` in Antigravity's User directory
  - macOS: `~/Library/Application Support/Antigravity/User/mcp_config.json`
  - Linux: `~/.config/Antigravity/User/mcp_config.json`
  - Uses `"mcpServers"` key format
- **agentmemory**: `agentmemory connect antigravity` — writes the MCP entry automatically
- **Hooks**: Not documented for Antigravity as of 2026-05

---

## Tool Install Commands

| Tool | Command | Notes |
|------|---------|-------|
| agentmemory | `npm install -g @agentmemory/agentmemory` | Global CLI, start with `agentmemory` |
| CodeGraph | `npm install -g @colbymchenry/codegraph` | Also: `curl -fsSL .../install.sh \| sh` |
| agnix | `npm install -g agnix` | Utility |
| gitnexus | `npm install -g gitnexus` | Also: `npx gitnexus analyze` |
| 21st.dev | `npx @21st-dev/cli install <ide> --api-key KEY` | Requires user API key (post-install) |

---

## What's IDE-Exclusive

| Feature | Cursor | VS Code | Antigravity |
|---------|--------|---------|-------------|
| GSD slash commands | Yes | No | No |
| GSD agents | Yes | No | No |
| GSD hooks (statusline, update check) | Yes | No | No |
| Skills discovery (native) | Yes | Partial ⁴ | Yes |
| MCP tools | Yes | Yes | Yes |
| agentmemory | Yes | Yes | Yes |
| CodeGraph | Yes | Yes | Yes |
| antigravity skills | Yes | Yes | Yes |

⁴ VS Code discovers MCP tools natively. Skill files require manual reference or Copilot instructions pointing to the skills directory.
