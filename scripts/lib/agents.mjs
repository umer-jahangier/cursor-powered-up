// =============================================================================
// agents.mjs — Registry of supported AI coding agents (single source of truth)
// =============================================================================
// Every per-agent path and config dialect lives here. powerup.mjs reads this
// registry; the shell/PowerShell installers only pass agent ids through.
// `skillsId` is the id the `npx skills -a <id>` CLI expects. `skillsDir` is the
// agent's own global skills folder; `alsoReads` lists shared folders the agent
// also discovers skills in (npx skills 1.7 installs Cursor/Codex/Gemini/Copilot/
// OpenCode skills into the shared ~/.agents/skills). A skill found in any of
// them counts as installed, so it is never installed twice.
//
// Paths verified 2026-09 against official docs — see docs/IDE-PATHS.md.
// =============================================================================

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const HOME = os.homedir();
const IS_WIN = process.platform === 'win32';
const IS_MAC = process.platform === 'darwin';
const APPDATA = process.env.APPDATA || path.join(HOME, 'AppData', 'Roaming');

const h = (...p) => path.join(HOME, ...p);

const VSCODE_USER = IS_WIN
  ? path.join(APPDATA, 'Code', 'User')
  : IS_MAC
    ? h('Library', 'Application Support', 'Code', 'User')
    : h('.config', 'Code', 'User');

const DEVIN_DIR = IS_WIN ? path.join(APPDATA, 'devin') : h('.config', 'devin');

export function onPath(cmd) {
  try {
    execFileSync(IS_WIN ? 'where' : 'which', [cmd], { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

const exists = (p) => fs.existsSync(p);

/** Every folder an agent discovers global skills in (own dir first). */
export const skillDirsOf = (agent) => [agent.skillsDir, ...(agent.alsoReads ?? [])];

/** Where `npx skills -g` puts skills for "universal" agents (cursor, codex, gemini-cli, antigravity…). */
export const SHARED_SKILLS_DIR = h('.agents', 'skills');

/**
 * mcp.kind:
 *   'claude-cli'  → `claude mcp add-json --scope user` (Claude owns ~/.claude.json)
 *   'json'        → merge into file[key]; `remote` picks the URL dialect
 *   'codex-toml'  → append [mcp_servers.<name>] tables to config.toml
 *   'opencode'    → merge into opencode.json "mcp" with local/remote shapes
 * mcp.bearer: how to reference an env var in an Authorization header,
 *   or null when the agent's env expansion is unverified (bearer servers skipped).
 *
 * rules.mode:
 *   'append'  → shared user file; append a marker-guarded block, never rewrite
 *   'own'     → a file this repo owns outright (safe to (re)write)
 */
export const AGENTS = {
  'claude-code': {
    label: 'Claude Code',
    skillsId: 'claude-code',
    skillsDir: h('.claude', 'skills'),
    alsoReads: [],
    detect: () => onPath('claude') || exists(h('.claude')),
    mcp: { kind: 'claude-cli', bearer: (v) => `Bearer \${${v}}` },
    rules: { mode: 'append', file: h('.claude', 'CLAUDE.md') },
  },
  cursor: {
    label: 'Cursor',
    skillsId: 'cursor',
    skillsDir: h('.cursor', 'skills'),
    alsoReads: [h('.agents', 'skills'), h('.claude', 'skills')],
    detect: () => exists(h('.cursor')),
    mcp: { kind: 'json', file: h('.cursor', 'mcp.json'), key: 'mcpServers', remote: 'url', bearer: (v) => `Bearer \${env:${v}}` },
    // Cursor user rules are UI-only; project rules ship via templates/project/.cursor/rules
    rules: null,
  },
  codex: {
    label: 'OpenAI Codex CLI',
    skillsId: 'codex',
    skillsDir: h('.codex', 'skills'),
    alsoReads: [h('.agents', 'skills')],
    detect: () => onPath('codex') || exists(h('.codex')),
    mcp: { kind: 'codex-toml', file: h('.codex', 'config.toml') },
    rules: { mode: 'append', file: h('.codex', 'AGENTS.md') },
  },
  'gemini-cli': {
    label: 'Gemini CLI',
    skillsId: 'gemini-cli',
    skillsDir: h('.gemini', 'skills'),
    alsoReads: [h('.agents', 'skills')],
    detect: () => onPath('gemini') || exists(h('.gemini', 'settings.json')),
    mcp: { kind: 'json', file: h('.gemini', 'settings.json'), key: 'mcpServers', remote: 'httpUrl', bearer: (v) => `Bearer $${v}` },
    rules: { mode: 'append', file: h('.gemini', 'GEMINI.md') },
  },
  antigravity: {
    label: 'Antigravity (IDE + agy)',
    skillsId: 'antigravity',
    skillsDir: h('.gemini', 'config', 'skills'), // Antigravity 2.0 + IDE
    alsoReads: [h('.gemini', 'antigravity', 'skills')], // legacy, still read by the IDE
    detect: () => onPath('agy') || exists(h('.gemini', 'config')) || exists(h('.gemini', 'antigravity')),
    // 2026 layout. The legacy ~/.gemini/antigravity/mcp_config.json is a symlink to this file.
    mcp: { kind: 'json', file: h('.gemini', 'config', 'mcp_config.json'), key: 'mcpServers', remote: 'serverUrl', bearer: (v) => `Bearer \${env:${v}}` },
    rules: { mode: 'append', file: h('.gemini', 'GEMINI.md') }, // shared with Gemini CLI; marker dedupes
  },
  'github-copilot': {
    label: 'GitHub Copilot (VS Code)',
    skillsId: 'github-copilot',
    skillsDir: h('.copilot', 'skills'),
    alsoReads: [h('.agents', 'skills'), h('.claude', 'skills')],
    detect: () => exists(VSCODE_USER) || onPath('code'),
    // VS Code authenticates the GitHub MCP itself, so no bearer header.
    mcp: { kind: 'json', file: path.join(VSCODE_USER, 'mcp.json'), key: 'servers', remote: 'typed-http', bearer: null, bearerOptional: ['github'] },
    rules: { mode: 'own', file: h('.copilot', 'instructions', 'cursor-powered-up.instructions.md'), frontmatter: "---\napplyTo: '**'\n---\n\n" },
  },
  windsurf: {
    label: 'Windsurf / Devin Desktop',
    skillsId: 'windsurf',
    skillsDir: h('.codeium', 'windsurf', 'skills'),
    alsoReads: [path.join(DEVIN_DIR, 'skills')],
    detect: () => exists(DEVIN_DIR) || exists(h('.codeium', 'windsurf')),
    mcp: {
      kind: 'json',
      file: exists(DEVIN_DIR) ? path.join(DEVIN_DIR, 'mcp_config.json') : h('.codeium', 'windsurf', 'mcp_config.json'),
      key: 'mcpServers', remote: 'serverUrl', bearer: (v) => `Bearer \${env:${v}}`,
    },
    rules: { mode: 'append', file: h('.codeium', 'windsurf', 'memories', 'global_rules.md') },
  },
  opencode: {
    label: 'OpenCode',
    skillsId: 'opencode',
    skillsDir: h('.config', 'opencode', 'skills'),
    alsoReads: [h('.agents', 'skills'), h('.claude', 'skills')],
    detect: () => onPath('opencode') || exists(h('.config', 'opencode')),
    mcp: { kind: 'opencode', file: h('.config', 'opencode', 'opencode.json'), bearer: (v) => `Bearer {env:${v}}` },
    rules: { mode: 'append', file: h('.config', 'opencode', 'AGENTS.md') },
  },
  kiro: {
    label: 'Kiro',
    skillsId: 'kiro-cli',
    skillsDir: h('.kiro', 'skills'),
    alsoReads: [],
    detect: () => onPath('kiro') || exists(h('.kiro')),
    mcp: { kind: 'json', file: h('.kiro', 'settings', 'mcp.json'), key: 'mcpServers', remote: 'url', bearer: null },
    rules: { mode: 'own', file: h('.kiro', 'steering', 'cursor-powered-up.md') },
  },
  cline: {
    label: 'Cline',
    skillsId: 'cline',
    skillsDir: h('.agents', 'skills'),
    alsoReads: [h('.cline', 'skills')],
    detect: () => exists(h('.cline')),
    mcp: null, // settings path moves between releases — configure in-app
    rules: null,
  },
};

/** Resolve a comma list ("all", "detected", or ids) into registry ids. */
export function resolveAgents(spec = 'detected') {
  const ids = Object.keys(AGENTS);
  if (spec === 'all') return ids;
  if (spec === 'detected') return ids.filter((id) => AGENTS[id].detect());
  const wanted = spec.split(',').map((s) => s.trim()).filter(Boolean);
  const unknown = wanted.filter((id) => !AGENTS[id]);
  if (unknown.length) {
    throw new Error(`Unknown agent id(s): ${unknown.join(', ')}. Valid: ${ids.join(', ')}`);
  }
  return wanted;
}

// CLI: `node agents.mjs <spec> [--skills-ids]` prints resolved ids (space separated)
if (import.meta.url === `file://${process.argv[1]}` || process.argv[1]?.endsWith('agents.mjs')) {
  try {
    const spec = process.argv[2] || 'detected';
    const ids = resolveAgents(spec);
    const out = process.argv.includes('--skills-ids') ? ids.map((id) => AGENTS[id].skillsId) : ids;
    process.stdout.write(out.join(' ') + '\n');
  } catch (e) {
    process.stderr.write(`Error: ${e.message}\n`);
    process.exit(1);
  }
}
