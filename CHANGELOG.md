# Changelog

All notable changes to cursor-powered-up will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-05-26

### Added

- **Unified installer** (`scripts/install.sh` + `scripts/install.ps1`) — merges the previous
  `install.sh` and `install-cursor-powerup.sh` into a single 11-phase script. One clone + one
  install restores the full power-up stack on any Mac, Linux, or Windows machine.
- Phase 1: OS detection + prerequisite checks (node 18+, npm, npx, git, python3) with clear
  install hints for missing tools (brew on Mac, apt on Linux, nodejs.org on Windows).
- Phase 2: `~/.npm-global` prefix setup without sudo/admin; PATH added to `~/.zshrc`,
  `~/.bashrc`, and PowerShell profile.
- Phase 3: `npm install -g @agentmemory/agentmemory @colbymchenry/codegraph agnix`.
- Phase 4: Copy all GSD src to `~/.cursor` (commands, agents, workflows, templates,
  references, hooks, skills, reindex script).
- Phase 5: `agentmemory connect cursor` MCP wiring.
- Phase 6: Ensure `playwright` + `github` entries in `~/.cursor/mcp.json` via Python / Node
  JSON merge; fallback creates the file from scratch.
- Phase 7: `npx antigravity-awesome-skills` safe dev bundle (non-fatal if unavailable).
- Phase 8: Shallow-clone reference repos to `~/.cursor/repos/` (agentmemory, codegraph,
  antigravity-awesome-skills, awesome-cursorrules, gitnexus).
- Phase 9: Global `gitnexus` install; falls back to `npx gitnexus` if install fails.
- Phase 10: `chmod` all scripts; write `~/.cursor/POWERUP-INSTALLED.md` with version + date.
- Phase 11: Print final checklist (PAT, `agentmemory` session, restart Cursor).
- `--gsd-only` and `--powerup-only` flags for partial installs.
- `scripts/install-cursor-powerup.sh` kept as a backwards-compat shim that calls `install.sh`.
- Repo renamed / rebranded to **cursor-powered-up**.

### Changed

- README rewritten to show two-step quick start only.
- `docs/PORTABLE-SETUP.md` simplified: clone + install in one step.
- `src/skills/gsd-for-cursor/SKILL.md` updated with new repo name and paths.

---

## [Unreleased]

## [1.0.0] - 2026-01-25

### Added

- Initial Cursor IDE adaptation of GSD (based on [glittercowboy/get-shit-done](https://github.com/glittercowboy/get-shit-done))
- Complete adaptation guide (`GSD-CURSOR-ADAPTATION.md`)
- Migration documentation for future updates
- Installation scripts for Windows and macOS/Linux
- Migration scripts for Windows (PowerShell) and macOS/Linux (Bash)
- All 27 commands, 11 agents, 12 workflows, 20+ templates, 9 references, and 2 hooks

### Changed

- Command prefix from `/gsd:` to `/gsd-` (Cursor convention)
- Configuration directory from `~/.claude/` to `~/.cursor/`
- Tool names from PascalCase to snake_case
- Frontmatter tools format from array to object with booleans
- Color values from names to hex codes
