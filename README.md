# agent-config-hub

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

## Docs

- English design: `docs/superpowers/specs/2026-04-09-codex-config-design.md`
- Chinese design: `docs/superpowers/specs/2026-04-09-codex-config-design.zh-CN.md`
- Chinese README: `README.zh-CN.md`
