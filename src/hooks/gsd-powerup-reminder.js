#!/usr/bin/env node
// SessionStart: remind about global manual power-up steps (once per session output).
const http = require('http');
const os = require('os');

const lines = [];

function checkMemory(cb) {
  const req = http.get('http://localhost:3111/agentmemory/health', { timeout: 1500 }, (res) => {
    cb(res.statusCode === 200);
  });
  req.on('error', () => cb(false));
  req.on('timeout', () => {
    req.destroy();
    cb(false);
  });
}

checkMemory((ok) => {
  if (!ok) lines.push('[GSD Power-Up] Start memory: run `agentmemory` in a terminal');
  if (!process.env.GITHUB_PERSONAL_ACCESS_TOKEN) {
    lines.push('[GSD Power-Up] GitHub MCP: set GITHUB_PERSONAL_ACCESS_TOKEN in ~/.zshrc');
  }
  if (lines.length) {
    console.error(lines.join(os.EOL));
  }
});
