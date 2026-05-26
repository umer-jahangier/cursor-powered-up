# GSD `.gitignore` Template

Reference used by `cursor-powerup-bootstrap.md` when creating or updating `.gitignore` during `/gsd-new-project` and `/gsd-map-codebase`.

**Agent rule:** When applying this template, use `grep -qxF` to check each line before appending — never duplicate existing entries.

---

## Standard blocks (always added)

```gitignore
# ── Secrets ──────────────────────────────────────────────────
.env
.env.*
!.env.example

# ── Agent / codebase index artifacts ─────────────────────────
.codegraph/

# ── GSD / planning output (conditional — see commit_docs) ────
# .planning/   ← added only when commit_docs: false (Phase 5 of /gsd-new-project)

# ── Cursor IDE ───────────────────────────────────────────────
# .cursor/rules/ is INTENTIONALLY committed (team-shared conventions)
# Only suppress per-machine project state:
.cursor/projects/

# ── Python ───────────────────────────────────────────────────
__pycache__/
*.py[cod]
*.pyo
.pytest_cache/
.mypy_cache/
.ruff_cache/
.coverage
htmlcov/
.tox/

# ── Node / JS / TS ───────────────────────────────────────────
node_modules/
dist/
build/
.next/
out/
.turbo/
.vercel/
.parcel-cache/

# ── Logs ─────────────────────────────────────────────────────
*.log
logs/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# ── OS junk ──────────────────────────────────────────────────
.DS_Store
Thumbs.db
*.swp
*.swo
*~

# ── Editor state ─────────────────────────────────────────────
.idea/
.vscode/

# ── Build / generated output ─────────────────────────────────
output/
*.egg-info/
*.egg
```

---

## Stack-specific lines (appended during bootstrap when detected)

These are added **only if** the relevant stack is detected in the project root. The bootstrap bash block checks for indicators before appending.

| Stack | Detection | Extra lines added |
|-------|-----------|-------------------|
| Python (venv) | `requirements.txt`, `*.py`, `pyproject.toml` | `venv/`, `.venv/` |
| Go | `go.mod` | `vendor/` (only if not a module proxy setup) |
| Rust | `Cargo.toml` | `target/` |
| Java/Kotlin | `pom.xml`, `build.gradle` | `.gradle/`, `*.class`, `*.jar` |

---

## Conditional: `.planning/` (commit_docs setting)

During **Phase 5** of `/gsd-new-project`, the user chooses whether planning docs are committed:

- `commit_docs: true` (default / recommended) — **do NOT add** `.planning/` to `.gitignore`; roadmap, requirements, and state docs are version-controlled.
- `commit_docs: false` — **add** `.planning/` to `.gitignore`; planning docs stay local-only.

This logic is already handled in `new-project.md` Phase 5. The bootstrap does **not** add `.planning/` — only the Phase 5 config step does, conditionally.

---

## What is intentionally NOT ignored

| Path | Reason |
|------|--------|
| `.cursor/rules/` | Team-shared AI conventions — should be committed |
| `.cursor/mcp.json` | Per-machine, lives in `~/.cursor/`, not the project |
| `AGENTS.md`, `CLAUDE.md` | GitNexus/AI context — should be committed |
| `.planning/` (default) | GSD docs are valuable project artifacts |
| `.env.example` | Template showing required env vars — should be committed |

---

## Applying this template (bash reference)

```bash
# Add all standard entries that are not already present
GITIGNORE_ENTRIES=(
  ".env"
  ".env.*"
  "!.env.example"
  ".codegraph/"
  ".cursor/projects/"
  "__pycache__/"
  "*.py[cod]"
  "*.pyo"
  ".pytest_cache/"
  ".mypy_cache/"
  ".ruff_cache/"
  ".coverage"
  "htmlcov/"
  "node_modules/"
  "dist/"
  "build/"
  ".next/"
  "out/"
  ".turbo/"
  "*.log"
  "logs/"
  ".DS_Store"
  "Thumbs.db"
  "*.swp"
  "*.swo"
  ".idea/"
  ".vscode/"
  "output/"
  "*.egg-info/"
)

for entry in "${GITIGNORE_ENTRIES[@]}"; do
  grep -qxF "$entry" .gitignore 2>/dev/null || echo "$entry" >> .gitignore
done

# Stack-specific
if ls *.py app.py main.py requirements.txt pyproject.toml 2>/dev/null | grep -q .; then
  for entry in "venv/" ".venv/"; do
    grep -qxF "$entry" .gitignore 2>/dev/null || echo "$entry" >> .gitignore
  done
fi
if [ -f go.mod ]; then
  grep -qxF "vendor/" .gitignore 2>/dev/null || echo "vendor/" >> .gitignore
fi
if [ -f Cargo.toml ]; then
  grep -qxF "target/" .gitignore 2>/dev/null || echo "target/" >> .gitignore
fi
```
