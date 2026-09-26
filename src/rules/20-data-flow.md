## Understanding data and API flow

Before changing code that crosses layers (UI → API → service → database), map the flow first instead of guessing:

- `understand` / `understand-dashboard` (Understand-Anything): build and open the interactive knowledge graph; `understand-domain` for business flows, `understand-diff` for change impact.
- `/omm-scan` (oh-my-mermaid): write architecture and data-flow Mermaid diagrams to `.omm/`; `omm view` to browse them.
- GitNexus `route_map` / `api_impact` and CodeGraph for exact call paths when those MCP tools are available.
- `mermaid-diagrams` / `c4-architecture` when the user wants a diagram in docs or a PR.
