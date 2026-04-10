# agent-config-hub

Language: [中文](README.md) | English

A centralized Agent configuration repository for multiple devices, tools, and runtime profiles.

The goal is not just to store config files. This repo puts `rules`, `mcp`, `plugins`, `skills`, and runtime `configs` into a single workflow that is versioned, reviewable, releasable, and rollback-friendly, so configuration drift is easier to control across machines.

Current coverage:
- Tools: `codex`, `claudex`
- OS: `windows`, `macos`
- Profiles: `company`, `home`

Core capabilities:
- Git-based distribution and auditability for configuration assets
- `bootstrap` / `sync` / `release` scripts for setup, version-pinned sync, and formal publishing
- Structured capability inventories and release tracking for `MCP / Plugins / Skills`
- Version locks and capability history so each release can state exactly what it contains

This repository follows a hybrid version strategy:
- External: single repo release tag per change
- Internal: reserved component lock fields in `manifests/manifest.lock.json`

Typical use cases:
- Keep Agent configuration consistent across personal devices
- Switch between home and company profiles without manual rewiring
- Maintain a team baseline with traceable config changes and published releases

## Quick Start

1. Clone repository:

```powershell
git clone https://github.com/Luckyre/agent-config-hub.git
cd agent-config-hub
```

2. Initialize local machine:

```powershell
.\scripts\bootstrap.ps1 -Tool codex -Profile company
```

3. Sync to the current stable version:

```powershell
.\scripts\sync.ps1 -TargetVersion v2026.04.10.3 -Tool codex -Profile home
```

4. Create a release after config updates:

```powershell
.\scripts\release.ps1 -Notes "update rules and mcp servers"
```

## Merge Priority

`base -> tool -> os -> profile -> local.override`

## Integration Inventory

- MCP server definitions: `mcp/servers.yaml`
- MCP capability enums: `mcp/servers.yaml` -> `capabilities`
- Plugin registry: `plugins/registry.yaml`
- Plugin capability enums: `plugins/registry.yaml` -> `capabilities`
- Skills bundle: `skills/README.md`
- Skill capability enums: `skills/catalog.yaml`
- Capability history: `manifests/integration-history.json`
- Version lock: `manifests/manifest.lock.json`
- Device version selection guide: `docs/integration-catalog.md`

<!-- BEGIN:CAPABILITY-CATALOG -->

### MCP Capabilities

- `[example-local]` Example inspection: Exposes inspection endpoints for local debugging. (`introduced: v2026.04.10.2`)
- `[example-local]` Local example execution: Runs the bundled local example server over stdio. (`introduced: v2026.04.10.2`)

### Plugin Capabilities

- `[sample.plugin]` Local plugin install: Makes the sample plugin available from the local registry. (`introduced: v2026.04.10.2`)

### Skill Capabilities

- `[OpenSpec Propose]`  <span style="color:#d9480f;font-weight:600;">NEW</span>: Archive a completed OpenSpec change after checking artifacts, tasks, and sync status. (`introduced: v2026.04.10.3`)
- `[OpenSpec Propose]`  <span style="color:#d9480f;font-weight:600;">NEW</span>: Create a new OpenSpec change with proposal, design, and task artifacts in one pass. (`introduced: v2026.04.10.3`)
- `[OpenSpec Propose]`  <span style="color:#d9480f;font-weight:600;">NEW</span>: Explore ideas, investigate problems, and clarify requirements without implementing code. (`introduced: v2026.04.10.3`)
- `[OpenSpec Propose]` Change archival <span style="color:#d9480f;font-weight:600;">NEW</span>: Moves completed changes into the archive path with a dated archive location. (`introduced: v2026.04.10.3`)
- `[OpenSpec Propose]` Change context loading <span style="color:#d9480f;font-weight:600;">NEW</span>: Reads proposal, design, specs, and task context before implementation starts. (`introduced: v2026.04.10.3`)
- `[OpenSpec Propose]` Change scaffolding <span style="color:#d9480f;font-weight:600;">NEW</span>: Creates a new OpenSpec change directory and prepares artifact generation order. (`introduced: v2026.04.10.3`)
- `[OpenSpec Propose]` Change task implementation <span style="color:#d9480f;font-weight:600;">NEW</span>: Executes pending OpenSpec tasks and updates task completion status during implementation. (`introduced: v2026.04.10.3`)
- `[OpenSpec Propose]` Completion verification <span style="color:#d9480f;font-weight:600;">NEW</span>: Checks artifact state, task completion, and delta spec sync state before archiving. (`introduced: v2026.04.10.3`)
- `[OpenSpec Propose]` Problem exploration <span style="color:#d9480f;font-weight:600;">NEW</span>: Investigates requirements, tradeoffs, and codebase context before implementation. (`introduced: v2026.04.10.3`)
- `[OpenSpec Propose]` Proposal artifact generation <span style="color:#d9480f;font-weight:600;">NEW</span>: Generates proposal, design, and task files required to make a change implementation-ready. (`introduced: v2026.04.10.3`)
- `[OpenSpec Propose]` Spec-aware discovery <span style="color:#d9480f;font-weight:600;">NEW</span>: Connects exploration results back to OpenSpec proposals, designs, and specs when useful. (`introduced: v2026.04.10.3`)

> Badge rule: items marked with `<span style="color:#d9480f;font-weight:600;">NEW</span>` were introduced in this release compared with the previous release tag.

<!-- END:CAPABILITY-CATALOG -->

## Current Version Matrix

| Component | Version |
| --- | --- |
| repo | v2026.04.10.3 |
| rules | v2026.04.10.3 |
| mcp | v2026.04.10.3 |
| plugins | v2026.04.10.3 |
| skills | v2026.04.10.3 |
## Release Iteration Rule

1. Update `rules/`, `mcp/`, `plugins/`, `skills/`, `configs/` as needed.
2. Run `.\scripts\release.ps1 -Notes "<what changed>"`.
3. The release script updates:
   - `manifests/manifest.lock.json`
   - `manifests/integration-history.json`
   - `CHANGELOG.md` (with versions + MCP/Plugins/Skills summary)
   - `docs/integration-catalog.md`
   - managed capability sections in `README.md` and `README.en.md`
4. Push commit and tags: `git push origin HEAD --tags`.


