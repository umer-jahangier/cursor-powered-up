# Changelog

All notable changes to cursor-powered-up will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.0.0] - 2026-09-27

### Added

- **Works with any AI coding agent.** A new engine, `scripts/lib/powerup.mjs`, applies skills, MCP servers and
  rules to Claude Code, Cursor, OpenAI Codex CLI, Gemini CLI, Antigravity (IDE + `agy`), GitHub Copilot
  (VS Code), Windsurf/Devin Desktop, OpenCode, Kiro and Cline. Each agent gets its own paths and config dialect,
  all defined in `scripts/lib/agents.mjs`.
- **Declarative config.** `config/skill-packs.json` and `config/mcp-servers.json` are the single source of
  truth. To add a skill or server, edit the JSON; no installer changes are needed.
- **`ui-design` pack**: Impeccable (primary), Taste Skill (`design-taste-frontend`), Anthropic frontend-design,
  UI UX Pro Max, ibelick ui-skills (baseline-ui, fixing-motion-performance, fixing-accessibility), and Vercel
  web-design-guidelines / React best practices.
- **`motion` pack**: all 13 Emil Kowalski skills and all 8 official GSAP skills.
- **`3d` pack**: all 24 Three.js / React Three Fiber skills.
- **`dataflow` pack**: Understand-Anything (interactive codebase knowledge graph and API/data-flow dashboard),
  oh-my-mermaid (`/omm-scan` Mermaid data-flow docs, installed globally instead of through its
  project-local `omm setup`), and the Mermaid + C4 diagram skills.
- **`workflow` pack (opt-in)**: Superpowers, plus Anthropic webapp-testing, mcp-builder and skill-creator.
- **New MCP servers**:
  - core: context7, shadcn, chrome-devtools
  - extra: next-devtools, deepwiki, excalidraw, figma, sentry, appmap
- **Global rules.** `src/rules/` holds the design-skill precedence rules (Impeccable > Taste Skill dials only
  on request > frontend-design) and "map the data flow first". They are appended to every agent's global
  rules file, marker-guarded, and never stacked on top of an equivalent section you already wrote.
- `powerup.mjs project-init` writes a cross-tool `AGENTS.md`, plus a `CLAUDE.md` that imports it, into any repo.
- `powerup.mjs status` shows detected agents, skill counts and MCP config locations.
- New installer flags: `--agents`, `--packs`, `--mcp`, `--dry-run`. PowerShell equivalents: `-Agents`,
  `-Packs`, `-Mcp`, `-DryRun`.
- `docs/SKILLS-AND-TOOLS.md`: full catalog, the three install routes, a comparison of data-flow tools, and the
  tools that stay manual.

### Changed

- Skill install order: the Claude Code plugin comes first; then the upstream README's own installer
  (`npx impeccable install`, `uipro init`); then `npx skills add` as the universal fallback. `npx skills`
  is also used automatically whenever a native installer fails.
- `--ide` still works as an alias for `--agents`.
- The install record now lives at `~/.agents/POWERUP-INSTALLED.md`.
- `docs/IDE-PATHS.md` was rewritten for 10 agents, with 2026 paths.

### Fixed

- **Antigravity MCP path.** The installer wrote to `~/Library/Application Support/Antigravity/User/mcp_config.json`,
  which Antigravity no longer reads. It now writes to `~/.gemini/config/mcp_config.json`.
- **VS Code skills path.** Skills went to `~/.vscode/skills`, which Copilot never read. They now go to `~/.copilot/skills`.
- **UI UX Pro Max.** The repo root was git-cloned into the skills dir, but `SKILL.md` is nested there.
  It now installs through the plugin, `ui-ux-pro-max-cli`, or `npx skills`. The old `uipro-cli` package is stale.
- **Cursor `settings.json`.** Without `jq`, the file was overwritten, and the `jq` path replaced the whole
  `hooks` key. It is now a merge that only adds what is missing (`scripts/lib/cursor-settings.mjs`).
- **Windows `install.ps1`.** `ConvertFrom-Json -AsHashtable` (PowerShell 7 only) failed on Windows
  PowerShell 5.1, and the fallback then replaced `mcp.json` and `settings.json` with only this repo's entries.
  Both now go through the shared Node engine.
- **GSD overwrite prompt.** Answering "N" printed "Skipping" but copied the files anyway.
- **Three.js skill repo moved.** It was `OpenAEC-Foundation/Three.js-Claude-Skill-Package` and is now
  `Impertio-Studio/Three.js-Claude-Skill-Package`.

### Removed

- `scripts/lib/bundled-skills.sh`. Bundled skills are now copied by `powerup.mjs` to every selected agent.
- The per-IDE MCP merge code in `cursor.sh`, `vscode.sh` and `antigravity.sh`. `powerup.mjs` replaces it.

## [3.0.0] - 2026-06-26

### Added

- Multi-IDE installer (Cursor, VS Code, Antigravity) with an interactive IDE picker.
- **`immersive-3d-web` bundled skill** covering scroll-scrubbed frame sequences, WebGL / Three.js /
  R3F scenes, glass shaders, asset pipeline scripts, and a reference gallery for immersive,
  Awwwards-style sites.
- `animation-designer` bundled skill, ui-ux-pro-max, and the antigravity development/backend skills.

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
