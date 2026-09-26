#!/usr/bin/env node
// =============================================================================
// powerup.mjs — Cross-agent installer engine (skills, MCP servers, rules)
// =============================================================================
// Reads config/skill-packs.json, config/mcp-servers.json and src/rules/*.md and
// applies them to every selected agent in that agent's own format.
// Called by scripts/install.sh and scripts/install.ps1; also usable directly:
//
//   node scripts/lib/powerup.mjs all      --agents detected
//   node scripts/lib/powerup.mjs skills   --agents cursor,codex --packs default,workflow
//   node scripts/lib/powerup.mjs mcp      --agents all --mcp core,figma --dry-run
//   node scripts/lib/powerup.mjs rules
//   node scripts/lib/powerup.mjs project-init --dir ~/code/my-app
//   node scripts/lib/powerup.mjs status
//
// Safety contract: never overwrites a user's existing skill, MCP entry or rules
// text. Existing items are reported as "exists". --force only re-installs
// skills/plugins and refreshes blocks this repo previously wrote (marker-guarded).
// Every edited config file gets a one-time "<file>.powerup-backup" copy.
// =============================================================================

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';
import { AGENTS, resolveAgents, onPath, skillDirsOf, SHARED_SKILLS_DIR } from './agents.mjs';

const REPO = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const IS_WIN = process.platform === 'win32';
const HOME = os.homedir();

const { values: opt, positionals } = parseArgs({
  allowPositionals: true,
  options: {
    agents: { type: 'string', default: 'detected' },
    packs: { type: 'string', default: 'default' },
    mcp: { type: 'string', default: 'core' },
    dir: { type: 'string', default: process.cwd() },
    'dry-run': { type: 'boolean', default: false },
    force: { type: 'boolean', default: false },
    help: { type: 'boolean', short: 'h', default: false },
  },
});
const DRY = opt['dry-run'];
const FORCE = opt.force;

const C = process.stdout.isTTY && !process.env.NO_COLOR
  ? { g: '\x1b[32m', y: '\x1b[33m', r: '\x1b[31m', c: '\x1b[36m', d: '\x1b[90m', b: '\x1b[1m', n: '\x1b[0m' }
  : { g: '', y: '', r: '', c: '', d: '', b: '', n: '' };

// ── Result tracking ──────────────────────────────────────────────────────────
const rows = [];
const record = (area, item, agent, status, detail = '') => rows.push({ area, item, agent, status, detail });

const readJson = (p) => JSON.parse(fs.readFileSync(p, 'utf8'));
const exists = (p) => fs.existsSync(p);

function run(cmd, { quiet = true } = {}) {
  const shown = cmd.map((a) => (/\s/.test(a) ? JSON.stringify(a) : a)).join(' ');
  if (DRY) {
    console.log(`  ${C.d}[dry-run] ${shown}${C.n}`);
    return { ok: true };
  }
  console.log(`  ${C.d}$ ${shown}${C.n}`);
  // With shell:true Node joins args verbatim, so quote anything cmd.exe would split
  // or mangle (JSON for `claude mcp add-json`, paths with spaces).
  const winQuote = (a) => (/[\s"&|<>^]/.test(a) ? `"${a.replace(/"/g, '\\"')}"` : a);
  const res = spawnSync(cmd[0], IS_WIN ? cmd.slice(1).map(winQuote) : cmd.slice(1), {
    stdio: quiet ? ['ignore', 'pipe', 'pipe'] : ['ignore', 'inherit', 'inherit'],
    shell: IS_WIN, // npx/npm are .cmd shims on Windows
    env: { ...process.env, DISABLE_TELEMETRY: '1', CI: process.env.CI ?? '1' },
    encoding: 'utf8',
    maxBuffer: 64 * 1024 * 1024,
    timeout: 10 * 60 * 1000,
  });
  const ok = res.status === 0;
  if (!ok && quiet) {
    const tail = `${res.stdout ?? ''}${res.stderr ?? ''}`.trim().split('\n').slice(-8).join('\n');
    console.log(`  ${C.r}✗ exit ${res.status ?? res.error?.code}${C.n}\n${C.d}${tail}${C.n}`);
  }
  return { ok, out: `${res.stdout ?? ''}${res.stderr ?? ''}` };
}

/** Write a config file atomically, keeping a one-time pristine backup. Follows symlinks. */
function writeConfig(file, content) {
  if (DRY) return;
  let target = file;
  try { target = fs.realpathSync(file); } catch { /* new file */ }
  fs.mkdirSync(path.dirname(target), { recursive: true });
  const backup = `${target}.powerup-backup`;
  if (exists(target) && !exists(backup)) fs.copyFileSync(target, backup);
  const tmp = `${target}.powerup-tmp`;
  fs.writeFileSync(tmp, content);
  fs.renameSync(tmp, target);
}

// =============================================================================
// SKILLS
// =============================================================================

function selectPacks(spec) {
  const { packs } = readJson(path.join(REPO, 'config', 'skill-packs.json'));
  const names = new Set();
  for (const tok of spec.split(',').map((s) => s.trim()).filter(Boolean)) {
    if (tok === 'all') Object.keys(packs).forEach((k) => names.add(k));
    else if (tok === 'default') Object.keys(packs).filter((k) => packs[k].default).forEach((k) => names.add(k));
    else if (tok === 'none') continue;
    else if (packs[tok]) names.add(tok);
    else throw new Error(`Unknown pack "${tok}". Valid: default, all, none, ${Object.keys(packs).join(', ')}`);
  }
  return [...names].map((k) => ({ name: k, ...packs[k] }));
}

const hasSkill = (agentId, name) => skillDirsOf(AGENTS[agentId]).some((d) => exists(path.join(d, name, 'SKILL.md')));

let claudePluginsCache;
function claudeInstalledPlugins() {
  if (claudePluginsCache) return claudePluginsCache;
  try {
    const d = readJson(path.join(HOME, '.claude', 'plugins', 'installed_plugins.json'));
    claudePluginsCache = new Set(Object.keys(d.plugins ?? d));
  } catch {
    claudePluginsCache = new Set();
  }
  return claudePluginsCache;
}

function installClaudePlugin(item) {
  const { marketplace, plugin } = item.claudePlugin;
  const manual = `claude plugin marketplace add ${marketplace} && claude plugin install ${plugin}`;
  if (!onPath('claude')) return record('skills', item.id, 'claude-code', 'manual', manual);
  if (claudeInstalledPlugins().has(plugin) && !FORCE) return record('skills', item.id, 'claude-code', 'exists', `plugin ${plugin}`);

  const mktName = plugin.split('@')[1];
  const listed = DRY ? '' : run(['claude', 'plugin', 'marketplace', 'list']).out ?? '';
  if (!listed.includes(mktName)) {
    if (!run(['claude', 'plugin', 'marketplace', 'add', marketplace]).ok) {
      return record('skills', item.id, 'claude-code', 'failed', `marketplace add ${marketplace}`);
    }
  }
  const ok = run(['claude', 'plugin', 'install', plugin, '--scope', 'user']).ok;
  record('skills', item.id, 'claude-code', ok ? (DRY ? 'dry-run' : 'installed') : 'failed', `plugin ${plugin}`);
}

const prereqDone = new Set();
/**
 * Run the upstream README's own installer for `agents`.
 * Returns the agents it could NOT handle, so the caller can fall back to `npx skills`.
 */
function installNative(item, agents) {
  const n = item.native;
  const check = item.skills?.names?.[0];
  const todo = [];
  for (const a of agents) {
    const bin = n.requiresBinary?.[a];
    if (!FORCE && check && hasSkill(a, check)) record('skills', item.id, a, 'exists', check);
    else if (bin && !onPath(bin)) record('skills', item.id, a, 'skipped', `needs \`${bin}\` on PATH`);
    else todo.push(a);
  }
  if (!todo.length) return [];

  if (n.prereq && !prereqDone.has(item.id)) {
    prereqDone.add(item.id);
    if ((FORCE || !onPath(n.cmd[0])) && !run(n.prereq).ok) return todo;
  }
  const fill = (tpl, vars) => tpl.map((t) => t.replace(/\{(\w+)\}/g, (_, k) => vars[k]));
  // An exit code of 0 is not proof: the skill must now be in a folder the agent reads.
  const landed = (a) => DRY || !check || hasSkill(a, check);
  const settle = (agents, ok) => agents.filter((a) => {
    if (ok && landed(a)) { record('skills', item.id, a, DRY ? 'dry-run' : 'installed', 'native installer'); return false; }
    return true; // → caller falls back to npx skills
  });
  if (n.mode === 'batch') {
    const providers = todo.map((a) => n.providers[a]).join(',');
    return settle(todo, run(fill(n.cmd, { providers })).ok);
  }
  return todo.flatMap((a) => settle([a], run(fill(n.cmd, { provider: n.providers[a] })).ok));
}

/** Symlink ~/.agents/skills/<name> into the agent's own skills dir. Returns true on success. */
function linkShared(agentId, name) {
  const src = path.join(SHARED_SKILLS_DIR, name);
  const dest = path.join(AGENTS[agentId].skillsDir, name);
  if (!exists(path.join(src, 'SKILL.md')) || exists(dest)) return false;
  try {
    fs.mkdirSync(path.dirname(dest), { recursive: true });
    fs.symlinkSync(src, dest, IS_WIN ? 'junction' : 'dir'); // junctions need no admin on Windows
    return true;
  } catch {
    return false;
  }
}

function installViaSkillsCli(item, agents) {
  const { source, names } = item.skills;
  // Group agents by the exact set of names they are missing, so no agent ever
  // gets an existing skill re-installed over the top of it.
  const groups = new Map();
  for (const a of agents) {
    const missing = FORCE ? names : names.filter((n) => !hasSkill(a, n));
    if (!missing.length) { record('skills', item.id, a, 'exists', `${names.length} skill(s)`); continue; }
    const key = missing.join(',');
    groups.set(key, [...(groups.get(key) ?? []), a]);
  }
  for (const [key, group] of groups) {
    const missing = key.split(',');
    // npx skills silently skips agents whose home folder doesn't exist yet.
    if (!DRY) group.forEach((a) => fs.mkdirSync(AGENTS[a].skillsDir, { recursive: true }));
    const cmd = ['npx', '-y', 'skills', 'add', source, '-g', '-y',
      '-a', ...group.map((a) => AGENTS[a].skillsId), '-s', ...missing];
    const ok = run(cmd).ok;
    for (const a of group) {
      // npx skills may place an agent's skills only in the shared ~/.agents/skills,
      // which some agents (e.g. Antigravity) don't read globally. Link them in.
      const linked = ok && !DRY ? missing.filter((n) => !hasSkill(a, n) && linkShared(a, n)) : [];
      const absent = DRY ? [] : missing.filter((n) => !hasSkill(a, n));
      if (!ok) record('skills', item.id, a, 'failed', `npx skills (${missing.length} skill(s))`);
      else if (absent.length) record('skills', item.id, a, 'failed', `exit 0 but not found: ${absent.slice(0, 3).join(', ')}${absent.length > 3 ? '…' : ''}`);
      else record('skills', item.id, a, DRY ? 'dry-run' : 'installed', `${missing.length} skill(s) via npx skills${linked.length ? ` (${linked.length} linked from ~/.agents/skills)` : ''}`);
    }
  }
}

/** Skills that ship inside this repo (src/skills/*). Agent-specific ones are prefixed. */
function installBundled(agentIds) {
  const src = path.join(REPO, 'src', 'skills');
  const skills = fs.readdirSync(src).filter((d) => exists(path.join(src, d, 'SKILL.md')));
  console.log(`\n${C.c}${C.b}▶ Bundled skills:${C.n} ${skills.join(', ')}`);
  for (const name of skills) {
    const onlyFor = name === 'gsd-for-cursor' ? 'cursor' : null;
    for (const a of agentIds) {
      if (onlyFor && a !== onlyFor) continue;
      if (hasSkill(a, name) && !FORCE) { record('skills', name, a, 'exists', 'bundled (use --force to update)'); continue; }
      if (!DRY) fs.cpSync(path.join(src, name), path.join(AGENTS[a].skillsDir, name), { recursive: true });
      record('skills', name, a, DRY ? 'dry-run' : 'installed', 'bundled');
    }
  }
}

function cmdSkills(agentIds) {
  if (opt.packs !== 'none') installBundled(agentIds);
  const packs = selectPacks(opt.packs);
  for (const pack of packs) {
    console.log(`\n${C.c}${C.b}▶ Skill pack: ${pack.name}${C.n} ${C.d}— ${pack.description}${C.n}`);
    for (const item of pack.items) {
      if (item.cli && (FORCE || !onPath(item.cli.bin))) {
        const ok = run(item.cli.install).ok;
        record('cli', item.cli.bin, '(global)', ok ? (DRY ? 'dry-run' : 'installed') : 'failed', item.cli.install.join(' '));
      }
      let remaining = [...agentIds];
      if (item.claudePlugin && remaining.includes('claude-code')) {
        installClaudePlugin(item);
        remaining = remaining.filter((a) => a !== 'claude-code');
      }
      let nativeFailed = [];
      if (item.native) {
        const mapped = remaining.filter((a) => item.native.providers[a]);
        if (mapped.length) nativeFailed = installNative(item, mapped);
        remaining = remaining.filter((a) => !mapped.includes(a));
      }
      if (nativeFailed.length && item.skills) {
        console.log(`  ${C.y}⚠ native installer failed or wrote elsewhere for ${nativeFailed.join(', ')} — falling back to npx skills${C.n}`);
        remaining.push(...nativeFailed);
      } else nativeFailed.forEach((a) => record('skills', item.id, a, 'failed', 'native installer'));

      if (item.skills && remaining.length) installViaSkillsCli(item, remaining);
      else remaining.forEach((a) => record('skills', item.id, a, 'n/a', 'no install route for this agent'));
    }
  }
}

// =============================================================================
// MCP
// =============================================================================

function selectServers(spec) {
  const { servers } = readJson(path.join(REPO, 'config', 'mcp-servers.json'));
  const out = new Map();
  for (const tok of spec.split(',').map((s) => s.trim()).filter(Boolean)) {
    if (tok === 'none') continue;
    for (const [name, s] of Object.entries(servers)) {
      if (tok === 'all' || s.tier === tok || name === tok) out.set(name, s);
    }
    if (!['all', 'core', 'extra'].includes(tok) && !servers[tok]) {
      throw new Error(`Unknown MCP server "${tok}". Valid: core, extra, all, none, ${Object.keys(servers).join(', ')}`);
    }
  }
  return out;
}

/** Translate a canonical server into the agent's JSON dialect. */
function toAgentShape(server, m, kind) {
  if (server.stdio) {
    const { command, args = [], env } = server.stdio;
    if (kind === 'opencode') return { type: 'local', command: [command, ...args], enabled: true, ...(env && { environment: env }) };
    const base = { command, args, ...(env && { env }) };
    return kind === 'claude-cli' || m.remote === 'typed-http' ? { type: 'stdio', ...base } : base;
  }
  const { url, bearerEnv } = server.http;
  const headers = bearerEnv && m.bearer ? { Authorization: m.bearer(bearerEnv) } : undefined;
  const h = headers ? { headers } : {};
  if (kind === 'claude-cli') return { type: 'http', url, ...h };
  if (kind === 'opencode') return { type: 'remote', url, enabled: true, ...h };
  switch (m.remote) {
    case 'httpUrl': return { httpUrl: url, ...h };
    case 'serverUrl': return { serverUrl: url, ...h };
    case 'typed-http': return { type: 'http', url, ...h };
    default: return { url, ...h };
  }
}

function toCodexToml(name, server) {
  const q = JSON.stringify;
  const lines = [`[mcp_servers.${name}]`];
  if (server.stdio) {
    lines.push(`command = ${q(server.stdio.command)}`, `args = [${(server.stdio.args ?? []).map(q).join(', ')}]`);
    if (server.stdio.env) lines.push(`env = { ${Object.entries(server.stdio.env).map(([k, v]) => `${k} = ${q(v)}`).join(', ')} }`);
  } else {
    lines.push(`url = ${q(server.http.url)}`);
    if (server.http.bearerEnv) lines.push(`bearer_token_env_var = ${q(server.http.bearerEnv)}`);
  }
  return lines.join('\n');
}

/** Servers an agent cannot take automatically (missing binary, unverified env syntax). */
function unsupportedReason(name, server, m) {
  if (server.requiresCommand && !onPath(server.requiresCommand)) return `needs \`${server.requiresCommand}\` on PATH`;
  if (server.http?.bearerEnv && m.kind === 'json' && !m.bearer && !(m.bearerOptional ?? []).includes(name)) {
    return `add manually (token env syntax unverified for this agent)`;
  }
  return null;
}

function cmdMcp(agentIds) {
  const servers = selectServers(opt.mcp);
  if (!servers.size) return;
  console.log(`\n${C.c}${C.b}▶ MCP servers:${C.n} ${[...servers.keys()].join(', ')}`);

  for (const id of agentIds) {
    const m = AGENTS[id].mcp;
    if (!m) { record('mcp', '(all)', id, 'manual', 'configure MCP in the app — see docs/IDE-PATHS.md'); continue; }

    const todo = [];
    for (const [name, s] of servers) {
      const why = unsupportedReason(name, s, m);
      if (why) record('mcp', name, id, 'skipped', why);
      else todo.push([name, s]);
    }
    if (!todo.length) continue;

    if (m.kind === 'claude-cli') {
      if (!onPath('claude')) { todo.forEach(([n]) => record('mcp', n, id, 'manual', 'claude CLI not on PATH')); continue; }
      let have = {};
      try { have = readJson(path.join(HOME, '.claude.json')).mcpServers ?? {}; } catch { /* first run */ }
      for (const [name, s] of todo) {
        if (have[name]) { record('mcp', name, id, 'exists'); continue; }
        const ok = run(['claude', 'mcp', 'add-json', '--scope', 'user', name, JSON.stringify(toAgentShape(s, m, 'claude-cli'))]).ok;
        record('mcp', name, id, ok ? (DRY ? 'dry-run' : 'added') : 'failed');
      }
      continue;
    }

    if (m.kind === 'codex-toml') {
      const text = exists(m.file) ? fs.readFileSync(m.file, 'utf8') : '';
      const have = new Set([...text.matchAll(/^\s*\[mcp_servers\.("?)([^\]"]+)\1\]/gm)].map((x) => x[2]));
      const blocks = [];
      for (const [name, s] of todo) {
        if (have.has(name)) { record('mcp', name, id, 'exists'); continue; }
        blocks.push(toCodexToml(name, s));
        record('mcp', name, id, DRY ? 'dry-run' : 'added');
      }
      if (blocks.length) writeConfig(m.file, `${text.replace(/\s*$/, '')}${text.trim() ? '\n\n' : ''}# added by cursor-powered-up\n${blocks.join('\n\n')}\n`);
      continue;
    }

    // JSON dialects (json / opencode)
    let doc = {};
    if (exists(m.file)) {
      const raw = fs.readFileSync(m.file, 'utf8');
      if (raw.trim()) {
        try { doc = JSON.parse(raw); } catch {
          todo.forEach(([n]) => record('mcp', n, id, 'skipped', `${m.file} is not plain JSON (comments?) — left untouched`));
          continue;
        }
      }
    }
    const key = m.kind === 'opencode' ? 'mcp' : m.key;
    if (m.kind === 'opencode' && !doc.$schema) doc.$schema = 'https://opencode.ai/config.json';
    const bucket = (doc[key] ??= {});
    let changed = false;
    for (const [name, s] of todo) {
      if (bucket[name]) { record('mcp', name, id, 'exists'); continue; }
      bucket[name] = toAgentShape(s, m, m.kind);
      changed = true;
      record('mcp', name, id, DRY ? 'dry-run' : 'added');
    }
    if (changed) writeConfig(m.file, JSON.stringify(doc, null, 2) + '\n');
  }
}

// =============================================================================
// RULES
// =============================================================================

function ruleBlocks() {
  const dir = path.join(REPO, 'src', 'rules');
  return fs.readdirSync(dir).filter((f) => f.endsWith('.md')).sort().map((f) => {
    const body = fs.readFileSync(path.join(dir, f), 'utf8').trim();
    const id = path.basename(f, '.md').replace(/^\d+-/, ''); // "10-foo.md" → "foo" (prefix = order)
    return {
      id,
      heading: body.split('\n')[0].trim(),
      start: `<!-- cursor-powered-up:${id}:start -->`,
      end: `<!-- cursor-powered-up:${id}:end -->`,
      body,
    };
  });
}

/**
 * Append each block to `text` unless it (or an equivalent heading written by
 * the user) is already there. Returns { text, statuses }.
 */
function mergeBlocks(text, blocks) {
  const statuses = [];
  let out = text;
  for (const b of blocks) {
    const wrapped = `${b.start}\n${b.body}\n${b.end}`;
    if (out.includes(b.start)) {
      if (FORCE) {
        const re = new RegExp(`${escapeRe(b.start)}[\\s\\S]*?${escapeRe(b.end)}`);
        out = out.replace(re, wrapped);
        statuses.push([b.id, 'refreshed']);
      } else statuses.push([b.id, 'exists']);
    } else if (out.split('\n').some((l) => l.trim() === b.heading)) {
      statuses.push([b.id, 'exists', 'equivalent section already present — not stacking']);
    } else {
      out = `${out.replace(/\s*$/, '')}${out.trim() ? '\n\n' : ''}${wrapped}\n`;
      statuses.push([b.id, 'added']);
    }
  }
  return { text: out, statuses };
}
const escapeRe = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

function cmdRules(agentIds) {
  const blocks = ruleBlocks();
  console.log(`\n${C.c}${C.b}▶ Global rules:${C.n} ${blocks.map((b) => b.id).join(', ')}`);
  const seen = new Set();
  for (const id of agentIds) {
    const r = AGENTS[id].rules;
    if (!r) {
      const hint = id === 'cursor' ? 'Cursor user rules are UI-only — run `project-init` per repo (AGENTS.md)' : 'no global rules file';
      record('rules', '(all)', id, 'manual', hint);
      continue;
    }
    if (seen.has(r.file)) { blocks.forEach((b) => record('rules', b.id, id, 'exists', 'shared file (already handled)')); continue; }
    seen.add(r.file);

    const current = exists(r.file) ? fs.readFileSync(r.file, 'utf8') : '';
    if (r.mode === 'own' && current && !current.includes('cursor-powered-up:') && !FORCE) {
      blocks.forEach((b) => record('rules', b.id, id, 'skipped', `${r.file} exists and is not ours`));
      continue;
    }
    const base = r.mode === 'own' && !current ? (r.frontmatter ?? '') : current;
    const { text, statuses } = mergeBlocks(base, blocks);
    statuses.forEach(([b, s, d]) => record('rules', b, id, DRY && s !== 'exists' ? 'dry-run' : s, d ?? ''));
    if (text !== current) writeConfig(r.file, text);
    if (id === 'windsurf' && text.length > 6000) record('rules', '(size)', id, 'warn', `global_rules.md is ${text.length} chars (limit 6000)`);
  }
}

// =============================================================================
// PROJECT INIT — cross-tool project rules (AGENTS.md is read by Codex, Cursor,
// Copilot, Windsurf/Devin, OpenCode, Antigravity, Kiro; Claude via @import)
// =============================================================================

function cmdProjectInit() {
  const dir = path.resolve(opt.dir.replace(/^~(?=$|\/|\\)/, HOME));
  if (!exists(dir)) throw new Error(`Project directory not found: ${dir}`);
  console.log(`\n${C.c}${C.b}▶ Project rules:${C.n} ${dir}`);
  const agentsMd = path.join(dir, 'AGENTS.md');
  const current = exists(agentsMd) ? fs.readFileSync(agentsMd, 'utf8') : '';
  const seed = current || '# AGENTS.md\n\nShared instructions for every AI coding agent working in this repo.\n';
  const { text, statuses } = mergeBlocks(seed, ruleBlocks());
  statuses.forEach(([b, s, d]) => record('project', b, 'AGENTS.md', DRY && s !== 'exists' ? 'dry-run' : s, d ?? ''));
  if (text !== current && !DRY) fs.writeFileSync(agentsMd, text);

  const claudeMd = path.join(dir, 'CLAUDE.md');
  if (!exists(claudeMd)) {
    if (!DRY) fs.writeFileSync(claudeMd, '@AGENTS.md\n');
    record('project', 'CLAUDE.md', 'claude-code', DRY ? 'dry-run' : 'added', 'imports AGENTS.md');
  } else if (!fs.readFileSync(claudeMd, 'utf8').includes('@AGENTS.md')) {
    record('project', 'CLAUDE.md', 'claude-code', 'manual', 'add a line `@AGENTS.md` so Claude Code reads the shared rules');
  } else record('project', 'CLAUDE.md', 'claude-code', 'exists');
}

// =============================================================================
// STATUS
// =============================================================================

function cmdStatus() {
  console.log(`\n${C.b}${'Agent'.padEnd(46)}${'Detected'.padEnd(10)}${'Skills'.padEnd(8)}MCP config${C.n}`);
  for (const [id, a] of Object.entries(AGENTS)) {
    const det = a.detect();
    const names = new Set();
    for (const dir of skillDirsOf(a)) {
      try { fs.readdirSync(dir).filter((d) => exists(path.join(dir, d, 'SKILL.md'))).forEach((d) => names.add(d)); } catch { /* none */ }
    }
    const skills = names.size;
    const mcp = a.mcp?.kind === 'claude-cli' ? '~/.claude.json (via claude CLI)'
      : a.mcp?.file && exists(a.mcp.file) ? a.mcp.file.replace(HOME, '~') : '—';
    const detected = (det ? 'yes' : 'no').padEnd(10);
    console.log(`${`${a.label} (${id})`.padEnd(46)}${det ? C.g : C.d}${detected}${C.n}${String(skills).padEnd(8)}${mcp}`);
  }
}

// =============================================================================
// REPORT + MAIN
// =============================================================================

function printReport() {
  if (!rows.length) return;
  const color = { installed: C.g, added: C.g, refreshed: C.g, exists: C.d, 'dry-run': C.c, manual: C.y, skipped: C.y, warn: C.y, 'n/a': C.d, failed: C.r };
  console.log(`\n${C.b}${'Area'.padEnd(8)}${'Item'.padEnd(24)}${'Agent'.padEnd(16)}${'Status'.padEnd(11)}Detail${C.n}`);
  for (const r of rows) {
    console.log(`${r.area.padEnd(8)}${r.item.padEnd(24)}${r.agent.padEnd(16)}${color[r.status] ?? ''}${r.status.padEnd(11)}${C.n}${C.d}${r.detail}${C.n}`);
  }
  const count = (s) => rows.filter((r) => r.status === s).length;
  console.log(`\n${C.b}Summary:${C.n} ${count('installed') + count('added') + count('refreshed')} done · ${count('exists')} already present · ${count('manual')} manual · ${count('skipped')} skipped · ${count('failed')} failed${DRY ? ` · ${count('dry-run')} planned (dry run)` : ''}`);
}

const HELP = `Usage: node scripts/lib/powerup.mjs <all|skills|mcp|rules|project-init|status> [options]

  --agents <spec>   detected (default) | all | comma list of: ${Object.keys(AGENTS).join(', ')}
  --packs <spec>    default (default) | all | none | comma list of packs in config/skill-packs.json
  --mcp <spec>      core (default) | extra | all | none | comma list of tiers/server names
  --dir <path>      project directory for project-init (default: cwd)
  --dry-run         print what would happen, change nothing
  --force           re-install skills/plugins and refresh this repo's own rule blocks`;

function main() {
  const cmd = positionals[0] ?? 'all';
  if (opt.help) { console.log(HELP); return; }
  if (cmd === 'status') return cmdStatus();
  if (cmd === 'project-init') { cmdProjectInit(); return printReport(); }

  const agentIds = resolveAgents(opt.agents);
  if (!agentIds.length) {
    console.log(`${C.y}No supported agents detected. Pass --agents <ids> explicitly (see --help).${C.n}`);
    return;
  }
  console.log(`${C.b}Agents:${C.n} ${agentIds.map((a) => AGENTS[a].label).join(', ')}${DRY ? `  ${C.c}(dry run)${C.n}` : ''}`);

  if (cmd === 'all' || cmd === 'skills') cmdSkills(agentIds);
  if (cmd === 'all' || cmd === 'mcp') cmdMcp(agentIds);
  if (cmd === 'all' || cmd === 'rules') cmdRules(agentIds);
  if (!['all', 'skills', 'mcp', 'rules'].includes(cmd)) { console.log(HELP); process.exitCode = 1; return; }

  printReport();
  if (rows.some((r) => r.status === 'failed')) process.exitCode = 2;
}

try {
  main();
} catch (e) {
  console.error(`${C.r}✗ ${e.message}${C.n}`);
  process.exitCode = 1;
}
