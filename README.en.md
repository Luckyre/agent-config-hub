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

- MCP servers: `mcp/servers.yaml`
- Plugins: `plugins/registry.yaml`
- Skills bundle: `skills/README.md`
- Version lock: `manifests/manifest.lock.json`
- Device version selection guide: `docs/integration-catalog.md`

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
   - `CHANGELOG.md` (with versions + MCP/Plugins/Skills summary)
   - `docs/integration-catalog.md`
4. Push commit and tags: `git push origin HEAD --tags`.

## Docs

- English design: `docs/superpowers/specs/2026-04-09-codex-config-design.md`
- Chinese design: `docs/superpowers/specs/2026-04-09-codex-config-design.zh-CN.md`
- Chinese README: `README.md`
