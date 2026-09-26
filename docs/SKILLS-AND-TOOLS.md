# Skills & Tools Catalog

Everything the installer can put in front of your agents, why it's there, and how it gets installed.
The machine-readable sources are [`config/skill-packs.json`](../config/skill-packs.json) and
[`config/mcp-servers.json`](../config/mcp-servers.json). Edit those files to add or remove items. The installers don't need changes.

> Verified against upstream READMEs on **2026-09-27**.

---

## How each item is installed

For each item and each agent, the first route that applies wins:

1. **Claude Code plugin**: used when the item ships one and the agent is Claude Code. Runs `claude plugin marketplace add` and then `claude plugin install`.
2. **Native installer**: used when the upstream README recommends its own CLI and that CLI supports the agent. Examples are `npx impeccable install` and `uipro init`.
3. **`npx skills add`**: the universal fallback ([vercel-labs/skills](https://github.com/vercel-labs/skills)). It works with 70+ agents. It stores one canonical copy and symlinks it into each agent's skills folder.

If a native installer fails, the item automatically falls back to `npx skills`. This matters today because Impeccable's own bundle download has been returning HTTP 404 ([pbakaus/impeccable#479](https://github.com/pbakaus/impeccable/issues/479)).

Skills that already exist in an agent's skills folder are **never overwritten**. Pass `--force` to re-install or update them.

---

## Skill packs

Install packs with `--packs <list>`. `default` = `ui-design,motion,3d,dataflow`.

### `ui-design` (default)

| Item | What it gives you | Route |
|------|-------------------|-------|
| **Impeccable** ([pbakaus/impeccable](https://github.com/pbakaus/impeccable)) | Primary design authority: `/impeccable audit`, `polish`, `critique`, anti-pattern checks | Claude plugin · `npx impeccable install` (Cursor, Codex, Gemini, Copilot, OpenCode) · `npx skills` for the rest |
| **frontend-design** ([anthropics](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/frontend-design)) | Anthropic's fallback baseline for distinctive frontends | Claude plugin · `npx skills add anthropics/skills` |
| **Taste Skill** ([Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill)) | `design-taste-frontend` with variance / motion / density dials | `npx skills` |
| **UI UX Pro Max** ([nextlevelbuilder](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)) | 60+ styles, palettes, font pairings, design-system generator (needs Python 3 at runtime) | Claude plugin · `uipro init --global --ai <agent>` · `npx skills` |
| **ibelick ui-skills** ([ibelick/ui-skills](https://github.com/ibelick/ui-skills)) | `baseline-ui`, `fixing-motion-performance`, `fixing-accessibility` | `npx skills` |
| **Vercel agent-skills** ([vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills)) | `web-design-guidelines` (UI review against Web Interface Guidelines), React best practices, composition patterns, view transitions | `npx skills` |

### `motion` (default)

| Item | Skills | Route |
|------|--------|-------|
| **Emil Kowalski** ([emilkowalski/skills](https://github.com/emilkowalski/skills)) | emil-design-eng, animate, animate-expo, review/improve/find-animation-*, animation-vocabulary, apple-design, pick-ui-library, prototype, mobile-native, write-swift, ask-sonner | `npx skills` |
| **GSAP official** ([greensock/gsap-skills](https://github.com/greensock/gsap-skills)) | gsap-core, -timeline, -scrolltrigger, -plugins, -utils, -react, -frameworks, -performance | `npx skills` |

### `3d` (default)

| Item | Skills | Route |
|------|--------|-------|
| **Three.js / R3F** ([Impertio-Studio/Three.js-Claude-Skill-Package](https://github.com/Impertio-Studio/Three.js-Claude-Skill-Package)) | 24 skills: core, syntax, impl (R3F, drei, WebGPU, XR, physics, post-processing…), errors, agents | `npx skills` |

> ⚠️ **Moved:** `OpenAEC-Foundation/Three.js-Claude-Skill-Package` now redirects to `Impertio-Studio/…`.
> Don't `git clone` it into a skills folder. Its `SKILL.md` files are nested at `skills/source/<group>/<name>/`, so agents never discover them. `npx skills` flattens them correctly.

### `dataflow` (default): see how data and APIs flow through your app

| Item | What it does | Route |
|------|--------------|-------|
| **Understand-Anything** ([Egonex-AI/Understand-Anything](https://github.com/Egonex-AI/Understand-Anything), MIT) | Five parallel agents build a knowledge graph of the codebase and open an **interactive React Flow dashboard**. Nodes are colour-coded by layer (API / Service / Data / UI / Utility). `understand-domain` draws business/process flows, `understand-diff` shows change impact, `understand-onboard` writes a guided tour. | Claude plugin · `npx skills` for every other agent |
| **oh-my-mermaid** ([oh-my-mermaid/oh-my-mermaid](https://github.com/oh-my-mermaid/oh-my-mermaid), MIT) | `/omm-scan` writes Mermaid *perspectives* (overall architecture, **data flow**, integrations) into `.omm/`. `omm view` opens a local viewer. Lightweight, and the output is committed to git. | Claude plugin · `npx skills` (every agent) + `npm i -g oh-my-mermaid` for the `omm` CLI |
| **Diagram skills** ([softaworks/agent-toolkit](https://github.com/softaworks/agent-toolkit)) | `mermaid-diagrams` (sequence, flowchart, ER, data-flow) and `c4-architecture` for docs and PRs | `npx skills` |

Typical use:

```text
/understand              # build the graph (first run takes a while on big repos)
/understand-dashboard    # open the interactive flow dashboard
/understand-domain       # business / request flows
/omm-scan                # Mermaid architecture + data-flow docs in .omm/
```

These complement the GitNexus `route_map` / `api_impact` MCP tools and CodeGraph, which the base installer already sets up. Those tools answer exact call-path questions. The tools above produce the visual picture.

### `workflow` (opt-in: `--packs default,workflow`)

| Item | What it does | Route |
|------|--------------|-------|
| **Superpowers** ([obra/superpowers](https://github.com/obra/superpowers)) | brainstorm → plan → TDD → systematic debugging → verification-before-completion | Claude plugin (`superpowers@claude-plugins-official`) · `npx skills` |
| **Anthropic dev skills** ([anthropics/skills](https://github.com/anthropics/skills)) | `webapp-testing` (Playwright), `mcp-builder`, `skill-creator` | `npx skills` |

Superpowers is opt-in because it's opinionated. Its `using-superpowers` skill tells the agent to check for skills before every reply, and that can clash with GSD or your own workflow.

### Bundled with this repo (`src/skills/`)

| Skill | Installed to |
|-------|--------------|
| `animation-designer` | every selected agent |
| `immersive-3d-web` | every selected agent |
| `gsd-for-cursor` | Cursor only |

---

## Design-skill precedence (global rules)

Impeccable, Taste Skill and frontend-design overlap. The installer appends
[`src/rules/10-design-precedence.md`](../src/rules/10-design-precedence.md) to every agent's global rules file:

1. **Impeccable** is the primary design authority.
2. **Taste Skill** dials apply only when you ask for a specific variance / motion / density level.
3. **frontend-design** is the fallback baseline.

The higher-ranked skill wins, and conflicting rules are never blended. Each block is marker-guarded, so re-running doesn't duplicate it. If your rules file already has a `## Frontend design skills: precedence` section, it's left alone.

---

## MCP servers

Choose servers with `--mcp <list>`. The default is `core`.

| Server | Tier | What it does | Key? |
|--------|------|--------------|------|
| playwright | core | Browser automation, E2E checks | — |
| github | core | Repos, issues, PRs | `GITHUB_PERSONAL_ACCESS_TOKEN` |
| agentmemory | core | Persistent memory across sessions | run `agentmemory` |
| **context7** | core | Up-to-date, version-specific library docs (stops hallucinated APIs) | optional |
| **shadcn** | core | Search and install shadcn/ui registry components | — |
| **chrome-devtools** | core | Performance traces, console, network, DOM, the debugging Playwright lacks | — |
| next-devtools | extra | Live errors, routes and logs from a running Next.js 16+ dev server | — |
| deepwiki | extra | Ask about any public GitHub repo's architecture | — |
| excalidraw | extra | Hand-drawn diagrams inline (needs an MCP-Apps client) | — |
| figma | extra | Design-to-code context from Figma | OAuth on first use |
| sentry | extra | Production errors and traces | OAuth on first use |
| appmap | extra | **Runtime** API → function → SQL flows (see below) | needs AppMap CLI |

Existing server entries with the same name are never modified.

---

## Manual-only tools

These tools are worth knowing about, but they can't be auto-installed.

| Tool | Why manual | How |
|------|-----------|-----|
| **AppMap** ([appmap.io](https://appmap.io)) | The only tool that records **real runtime** flows (HTTP request → functions → SQL) as sequence diagrams. It needs your app instrumented and recorded first. | Install the VS Code extension `appland.appmap` (or the JetBrains plugin), record, run `appmap index`, then `./scripts/install.sh --mcp appmap` |
| **CodeViz** ([codeviz.ai](https://codeviz.ai)) | A VS Code extension with C4 diagrams and end-to-end data-movement views. It has a commercial free tier and no MCP server. | `code --install-extension CodeViz.codeviz` |
| **21st.dev Magic** | Generates UI components. Needs your API key. | See [POST-INSTALL.md](./POST-INSTALL.md#step-4--21stdev-magic-mcp) |
| **Motion AI Kit** ([motion.dev](https://motion.dev/docs/ai-kit-install)) | `/motion` skill plus a docs MCP. Some features need Motion+. | `npx motion-ai` |
| **Storybook MCP** | Per project, Vite-based Storybook only | `npm i -D @storybook/addon-mcp`, then add it to `.storybook/main.ts` |
| **Serena** | LSP-based semantic navigation (GPL-3.0). It overlaps with CodeGraph and GitNexus. | `uv tool install -p 3.13 serena-agent` |

---

## Adding your own item

Add an entry to a pack in `config/skill-packs.json`:

```json
{
  "id": "my-skill",
  "description": "What it does",
  "url": "https://github.com/me/my-skills",
  "skills": { "source": "me/my-skills", "names": ["my-skill"] }
}
```

Run `npx skills add me/my-skills --list` to see the exact skill names. Then preview the install with `node scripts/lib/powerup.mjs skills --dry-run`.
