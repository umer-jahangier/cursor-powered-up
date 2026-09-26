#!/usr/bin/env node
// Ensure GSD hooks + statusline in ~/.cursor/settings.json without replacing
// any user keys or hooks. Invalid JSON → exit 1 and leave the file untouched.
// Usage: node cursor-settings.mjs [path]   (default: ~/.cursor/settings.json)
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const p = process.argv[2] || path.join(os.homedir(), '.cursor', 'settings.json');
let d = {};
if (fs.existsSync(p)) {
  const raw = fs.readFileSync(p, 'utf8');
  if (raw.trim()) {
    try { d = JSON.parse(raw); } catch {
      console.error(`${p} is not plain JSON — left untouched`);
      process.exit(1);
    }
  }
  if (!fs.existsSync(`${p}.powerup-backup`)) fs.copyFileSync(p, `${p}.powerup-backup`);
}

const want = ['node ~/.cursor/hooks/gsd-check-update.js', 'node ~/.cursor/hooks/gsd-powerup-reminder.js'];
d.hooks ??= {};
d.hooks.SessionStart ??= [];
const present = new Set(d.hooks.SessionStart.flatMap((g) => (g.hooks ?? []).map((h) => h.command)));
const missing = want.filter((c) => !present.has(c));
if (missing.length) d.hooks.SessionStart.push({ hooks: missing.map((command) => ({ type: 'command', command })) });
d.statusLine ??= { type: 'command', command: 'node ~/.cursor/hooks/gsd-statusline.js' };

fs.mkdirSync(path.dirname(p), { recursive: true });
fs.writeFileSync(p, JSON.stringify(d, null, 2) + '\n');
