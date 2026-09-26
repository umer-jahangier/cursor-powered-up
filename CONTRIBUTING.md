# Contributing to GSD for Cursor

Thank you for your interest in contributing to the GSD Cursor adaptation!

## Types of Contributions

### 1. Bug Fixes
If you find a bug in the adaptation (e.g., incorrect path references, missing conversions), please:
1. Open an issue describing the bug
2. Submit a PR with the fix

### 2. Migration Updates
When the upstream GSD repository is updated, we need to migrate those changes:

1. **Pull the latest GSD master**
2. **Run the migration script**:
   ```powershell
   .\scripts\migrate.ps1 -SourcePath "path/to/gsd-master" -DryRun
   ```
3. **Review the changes**
4. **Run without dry-run** to apply
5. **Manual review** for any edge cases
6. **Test the installation**
7. **Update CHANGELOG.md**

### 3. Documentation Improvements
Help improve the documentation:
- Fix typos or unclear explanations
- Add examples
- Update outdated information

### 4. Skills, MCP servers and agents
The power-up layer is config-driven, so most additions need no script changes:

| To add… | Edit | Preview with |
|---------|------|--------------|
| A skill or skill repo | `config/skill-packs.json` | `node scripts/lib/powerup.mjs skills --dry-run` |
| An MCP server | `config/mcp-servers.json` | `node scripts/lib/powerup.mjs mcp --agents all --dry-run` |
| A global rule block | a new `src/rules/NN-name.md` (NN = order) | `node scripts/lib/powerup.mjs rules --dry-run` |
| A new AI agent | `scripts/lib/agents.mjs` | `node scripts/lib/powerup.mjs status` |

Before opening a PR, test real writes against a throwaway home directory:

```bash
SB=$(mktemp -d) && HOME=$SB npm_config_prefix=$SB/.npm-global node scripts/lib/powerup.mjs all --agents cursor,codex
```

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/rmindel/gsd-for-cursor.git
   cd gsd-for-cursor
   ```

2. Test your changes:
   ```powershell
   # Install to ~/.cursor/
   .\scripts\install.ps1
   
   # Open Cursor and test commands
   ```

## Coding Standards

### File Naming
- Commands: `kebab-case.md` (e.g., `new-project.md`)
- Agents: `gsd-kebab-case.md` (e.g., `gsd-executor.md`)

### Frontmatter Format

**Commands:**
```yaml
---
name: gsd-command-name
description: Brief description
tools:
  read: true
  write: true
---
```

**Agents:**
```yaml
---
name: gsd-agent-name
description: Brief description
tools:
  read: true
  write: true
color: "#FFFF00"
---
```

### Path References
- Always use `~/.cursor/` for global paths
- Always use `/gsd-` for command references

## Pull Request Process

1. Create a feature branch from `main`
2. Make your changes
3. Run verification:
   ```powershell
   # Check for remaining Claude references
   Select-String -Path "src/**/*.md" -Pattern "\.claude" -Recurse
   ```
4. Update CHANGELOG.md if needed
5. Submit PR with clear description

## Migration Checklist

When updating from GSD master:

- [ ] All path references converted (`~/.claude/` → `~/.cursor/`)
- [ ] All command references converted (`/gsd:` → `/gsd-`)
- [ ] All tool names converted (PascalCase → snake_case)
- [ ] All colors converted to hex
- [ ] Frontmatter format updated
- [ ] CHANGELOG.md updated
- [ ] Tested installation
- [ ] Tested basic commands (`/gsd-help`, `/gsd-progress`)

## Questions?

Open an issue for any questions about contributing.


