# agent-config-hub

Language: [中文](README.md) | English

Git-based centralized configuration for multi-device sync across:
- Tools: `codex`, `claudex`
- OS: `windows`, `macos`
- Profiles: `company`, `home`

This repository follows a hybrid version strategy:
- External: single repo release tag per change
- Internal: reserved component lock fields in `manifests/manifest.lock.json`

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

3. Sync to a specific version:

```powershell
.\scripts\sync.ps1 -TargetVersion v2026.04.10.1 -Tool codex -Profile home
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

- `[example-local]` Example inspection <span style="color:#d9480f;font-weight:600;">NEW</span>: Exposes inspection endpoints for local debugging. (`introduced: v2026.04.10.1`)
- `[example-local]` Local example execution <span style="color:#d9480f;font-weight:600;">NEW</span>: Runs the bundled local example server over stdio. (`introduced: v2026.04.10.1`)

### Plugin Capabilities

- `[sample.plugin]` Local plugin install <span style="color:#d9480f;font-weight:600;">NEW</span>: Makes the sample plugin available from the local registry. (`introduced: v2026.04.10.1`)

### Skill Capabilities

- No managed skill capabilities.

> Badge rule: items marked with `<span style="color:#d9480f;font-weight:600;">NEW</span>` were introduced in this release compared with the previous release tag.

<!-- END:CAPABILITY-CATALOG -->

## Current Version Matrix

| Component | Version |
| --- | --- |
| repo | v2026.04.10.1 |
| rules | v2026.04.10.1 |
| mcp | v2026.04.10.1 |
| plugins | v2026.04.10.1 |
| skills | v2026.04.10.1 |

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

