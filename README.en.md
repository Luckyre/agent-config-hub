# agent-config-hub

Language: [中文](README.md) | English

A centralized Agent configuration repository for multiple devices, tools, and runtime profiles.

At its current stage, this repo is closer to an "Agent config release hub / versioned config skeleton" than a finished installer that applies every config directly into the real runtime directories of `Codex` or `Claudex`.

The goal is not just to store config files. This repo puts `rules`, `mcp`, `plugins`, `skills`, and runtime `configs` into a single workflow that is versioned, reviewable, releasable, and rollback-friendly, so configuration drift is easier to control across machines.

Current coverage:
- Tools: `codex`, `claudex`
- OS: `windows`, `macos`
- Profiles: `company`, `home`

Core capabilities:
- Git-based distribution and auditability for configuration assets
- `bootstrap` / `sync` / `release` scripts for setup, version-pinned sync, and formal publishing
- Automatic installation of `codex / claude` global prompts and startup wrappers during sync
- Structured capability inventories and release tracking for `MCP / Plugins / Skills`
- Version locks and capability history so each release can state exactly what it contains

This repository follows a hybrid version strategy:
- External: single repo release tag per change
- Internal: reserved component lock fields in `manifests/manifest.lock.json`

Typical use cases:
- Keep Agent configuration consistent across personal devices
- Switch between home and company profiles without manual rewiring
- Maintain a team baseline with traceable config changes and published releases

## Current Status

Already implemented:
- `bootstrap.ps1` runs `doctor.ps1` first so the target machine can be checked before sync starts
- `sync.ps1` generates a versioned snapshot under `~/.codex-config/live` based on `tool / os / profile`
- Layered config data is merged with the `base -> tool -> os -> profile -> local.override` priority and rendered into `effective-config.json`
- Managed `rules`, runtime `skills / commands`, and generated MCP config are applied into `~/.codex` or `~/.claude`
- `install-tooling.ps1` copies prompt and startup wrapper files from `tooling/` into `~/.codex` or `~/.claude`
- A real repository-local `mcp/example-server.js` is included, and synced MCP config points to the live snapshot copy under `~/.codex-config/live`
- `release.ps1` regenerates `manifest.lock.json`, `integration-history.json`, `CHANGELOG`, both READMEs, and the integration catalog

Not fully implemented yet:
- Final plugin installation / enablement through each tool's native plugin system is still not wired up; `plugins/registry.yaml` remains primarily an inventory and release-tracking source
- End-to-end automated coverage for the full `bootstrap / sync / release` path is still incomplete

Important usage notes:
- `bootstrap.ps1` is effectively a thin wrapper around `sync.ps1`
- `bootstrap` now runs `doctor` first and blocks devices that are missing `git`, `node`, or the selected tool CLI
- `sync.ps1 -TargetVersion <tag>` currently runs `git fetch --tags` and `git checkout <tag>`, so it changes the current repo HEAD
- `sync` preserves unmanaged content in existing `config.toml` / `mcp.json` / `settings.local.json` files and appends or merges the repo-managed sections on top
- Plugin files can ship inside the snapshot, but whether the target tool consumes them natively still depends on that tool's plugin model
- Startup wrappers under `tooling/` now resolve executables from PATH or `CODEX_BIN` / `CLAUDE_BIN` overrides instead of machine-specific absolute paths

## Quick Start

Clone the repository first:

```powershell
git clone https://github.com/Luckyre/agent-config-hub.git
cd agent-config-hub
```

### I am a config user

If you just want to generate and inspect the current config snapshot on your machine, decide these two inputs first:

- Which tool you use: `codex` or `claudex`
- Which profile you are in: `company` or `home`

#### Codex users

First-time setup:

```powershell
.\scripts\bootstrap.ps1 -Tool codex -Profile company
```

Sync to the current stable version:

```powershell
.\scripts\sync.ps1 -TargetVersion v2026.04.10.5 -Tool codex -Profile company
```

Sync result:
- The generated snapshot is written to `~/.codex-config/live`
- Codex-specific prompt and startup wrapper files are installed to `~/.codex`
- Managed `rules` / `skills` and MCP config are also applied into `~/.codex`

#### Claudex users

First-time setup:

```powershell
.\scripts\bootstrap.ps1 -Tool claudex -Profile company
```

Sync to the current stable version:

```powershell
.\scripts\sync.ps1 -TargetVersion v2026.04.10.5 -Tool claudex -Profile company
```

Sync result:
- The generated snapshot is written to `~/.codex-config/live`
- Claudex-specific prompt and startup wrapper files are installed to `~/.claude`
- Managed `skills` / `commands`, MCP config, and repo-tracked `settings.local.json` are also applied into `~/.claude`

#### How to choose a profile

- `-Profile company`: company environment config
- `-Profile home`: home environment config

If you have already initialized once and only want to switch profiles or upgrade to another version, run `sync` again. For example:

```powershell
.\scripts\sync.ps1 -TargetVersion v2026.04.10.5 -Tool codex -Profile home
```

Notes:
- `sync` first generates a repository snapshot, then applies managed runtime assets into the tool-native directories
- `sync` rewrites repository-local MCP server paths so they point to the current machine's `~/.codex-config/live/mcp/` snapshot
- The plugin registry is still mainly a versioned inventory and does not yet drive native plugin installation directly

### I am a repository maintainer

If you maintain this repo and need to publish a new version after config changes:

```powershell
.\scripts\release.ps1 -Notes "update rules and mcp servers"
```

`release` updates the version lock, capability history, `CHANGELOG`, and the capability catalog blocks in the READMEs. For maintainer details, see `docs/maintainer-guide.md`.

## Documentation Map

- Quick Start: this page `README.en.md`
- Integration overview: `docs/integration-catalog.md`
- Release history: `CHANGELOG.md`
- Maintainer conventions and tooling notes: `docs/maintainer-guide.md`
- Design and planning records: `docs/superpowers/specs/`, `docs/superpowers/plans/`

## Declared Config Layering

`base -> tool -> os -> profile -> local.override`

Notes:
- This is the intended repository-level layering model
- The current scripts now render a merged effective config and keep the source layer files for traceability

## Integration Inventory

- MCP server definitions: `mcp/servers.yaml`
- MCP capability enums: `mcp/servers.yaml` -> `capabilities`
- Plugin registry: `plugins/registry.yaml`
- Plugin capability enums: `plugins/registry.yaml` -> `capabilities`
- Skills bundle: `skills/README.md`
- Skill capability enums: `skills/catalog.yaml`
- Capability history: `manifests/integration-history.json`
- Version lock: `manifests/manifest.lock.json`
- Integration catalog: `docs/integration-catalog.md`
- Maintainer guide: `docs/maintainer-guide.md`

<!-- BEGIN:CAPABILITY-CATALOG -->

### MCP Capabilities

This section lists the actual capability items exposed by each MCP server, not just server names.

- `[example-local]` Example inspection: Exposes inspection endpoints for local debugging. (`introduced: v2026.04.10.2`)
- `[example-local]` Local example execution: Runs the bundled local example server over stdio. (`introduced: v2026.04.10.2`)

### Plugin Capabilities

This section lists the capability actions made available by each plugin in the current configuration.

- `[sample.plugin]` Local plugin install: Makes the sample plugin available from the local registry. (`introduced: v2026.04.10.2`)

### Skill Capabilities

This section lists executable skill actions, keeping the English term names while making the capability purpose easier to scan.

- `[OpenSpec Apply Change]` Change context loading <span style="color:#d9480f;font-weight:600;">NEW</span>: Reads proposal, design, specs, and task context before implementation starts. (`introduced: v2026.04.10.5`)
- `[OpenSpec Apply Change]` Change task implementation <span style="color:#d9480f;font-weight:600;">NEW</span>: Executes pending OpenSpec tasks and updates task completion status during implementation. (`introduced: v2026.04.10.5`)
- `[OpenSpec Archive Change]` Change archival <span style="color:#d9480f;font-weight:600;">NEW</span>: Moves completed changes into the archive path with a dated archive location. (`introduced: v2026.04.10.5`)
- `[OpenSpec Archive Change]` Completion verification <span style="color:#d9480f;font-weight:600;">NEW</span>: Checks artifact state, task completion, and delta spec sync state before archiving. (`introduced: v2026.04.10.5`)
- `[OpenSpec Explore]` Problem exploration <span style="color:#d9480f;font-weight:600;">NEW</span>: Investigates requirements, tradeoffs, and codebase context before implementation. (`introduced: v2026.04.10.5`)
- `[OpenSpec Explore]` Spec-aware discovery <span style="color:#d9480f;font-weight:600;">NEW</span>: Connects exploration results back to OpenSpec proposals, designs, and specs when useful. (`introduced: v2026.04.10.5`)
- `[OpenSpec Propose]` Change scaffolding <span style="color:#d9480f;font-weight:600;">NEW</span>: Creates a new OpenSpec change directory and prepares artifact generation order. (`introduced: v2026.04.10.5`)
- `[OpenSpec Propose]` Proposal artifact generation <span style="color:#d9480f;font-weight:600;">NEW</span>: Generates proposal, design, and task files required to make a change implementation-ready. (`introduced: v2026.04.10.5`)

> Badge rule: items marked with `<span style="color:#d9480f;font-weight:600;">NEW</span>` were introduced in this release compared with the previous release tag.

<!-- END:CAPABILITY-CATALOG -->

## Current Version Matrix

| Component | Version |
| --- | --- |
| repo | v2026.04.10.5 |
| rules | v2026.04.10.5 |
| mcp | v2026.04.10.5 |
| plugins | v2026.04.10.5 |
| skills | v2026.04.10.5 |




