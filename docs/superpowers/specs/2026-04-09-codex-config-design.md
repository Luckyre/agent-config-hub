# Codex-Config Multi-Device Sync Design (OpenSpec + Superpowers)

Version: v0.1 (design draft)  
Date: 2026-04-09  
Strategy: Hybrid baseline (single repo version + reserved component lock fields)

## 1. Goal and Scope

Goal:
- Use Git as the central config source for "configure once, sync everywhere".
- Use OpenSpec for schema and change governance.
- Support multi-tool sync (`codex`, `claudex`) and multi-OS sync (Windows, macOS).
- Allow each device to manually target a specific repo version (tag or commit).

Scope:
- Managed assets: `rules`, `mcp`, `plugins`, `skills`, plus rendered runtime config.
- Sync mode: manual target version first, optional periodic update checks.

Non-goals (phase 1):
- No independent component release pipelines yet.
- No plaintext secrets in repo.

## 2. Architecture

Layered architecture:

1. Source Layer (Git)
- One repository stores all config assets and scripts.
- Any valid change produces a new repo tag (example: `v2026.04.09.1`).

2. Spec Layer (OpenSpec)
- Define schema, change type, and validation gates.
- Use `change/spec/validate` workflow before release.

3. Sync Runtime Layer (scripts)
- Render effective config per tool + OS + profile.
- Apply atomically, rollback on failure, update local state.

4. Adapter Layer
- Tool adapters: `codex`, `claudex`
- OS adapters: `windows`, `macos`
- Environment profiles: `company`, `home`
- Local overrides: `local.override` (never committed)

## 3. Versioning Strategy (Hybrid)

### 3.1 External Versioning: Single Repo Version
- Any change in `rules/mcp/plugins/skills` triggers a new repo release tag.
- Devices only need one `target_version` pointer.
- This keeps operations simple and predictable.

### 3.2 Internal Metadata: Reserved Component Lock Fields
- Keep reserved fields in `manifest.lock.json`:
  - `rulesVersion`
  - `mcpVersion`
  - `pluginsVersion`
  - `skillsVersion`
- In phase 1, these can all equal the repo tag.
- This keeps future migration path open to component-level versioning.

## 4. Suggested Repository Layout

```text
codex-config/
  openspec/
    specs/
    changes/
    schemas/
  configs/
    base.yaml
    tools/
      codex.yaml
      claudex.yaml
    os/
      windows.yaml
      macos.yaml
    profiles/
      company.yaml
      home.yaml
  rules/
  mcp/
  plugins/
  skills/
  manifests/
    manifest.lock.json
  scripts/
    bootstrap.ps1
    sync.ps1
    release.ps1
    doctor.ps1
  generated/
  CHANGELOG.md
  README.md
  .gitignore
```

## 5. Merge Precedence

Effective config merge order:

`base -> tool -> os -> profile -> local.override`

Notes:
- `base`: global defaults
- `tool`: client-specific mapping
- `os`: path and shell differences
- `profile`: company/home differences
- `local.override`: local temporary overrides only

## 6. Release and Sync Flows

### 6.1 Release Flow (maintainer side)

When `rules/mcp/plugins/skills` are added or changed:

1. Create OpenSpec change proposal.
2. Modify config assets and mappings.
3. Validate:
   - `openspec validate`
   - custom consistency checks (script)
4. Generate/update `manifest.lock.json` (hashes, compatibility, reserved component fields).
5. Update `CHANGELOG.md`.
6. Create and push repo tag (example: `v2026.04.09.1`).

### 6.2 Sync Flow (device side)

Manual version target:

`sync.ps1 -TargetVersion <tag|commit> -Tool <codex|claudex> -Profile <company|home>`

Runtime sequence:

1. `git fetch --tags`
2. `git checkout <TargetVersion>`
3. `openspec validate`
4. Render config by `tool + os + profile` into `generated/`
5. Backup current live config
6. Atomic apply
7. Update local state (`current`, `last_successful`, timestamp)

Failure behavior:
- Fail fast and rollback to `last_successful_version`.
- Output failure reason and diff summary.

## 7. Manifest and Local State

### 7.1 `manifest.lock.json` (in repo)

Purpose:
- Immutable snapshot metadata for reproducible sync.

Example:

```json
{
  "repoVersion": "v2026.04.09.1",
  "generatedAt": "2026-04-09T00:00:00Z",
  "rulesVersion": "v2026.04.09.1",
  "mcpVersion": "v2026.04.09.1",
  "pluginsVersion": "v2026.04.09.1",
  "skillsVersion": "v2026.04.09.1",
  "compatibility": {
    "tools": ["codex", "claudex"],
    "os": ["windows", "macos"]
  },
  "files": [
    { "path": "rules/base.md", "sha256": "..." },
    { "path": "mcp/servers.yaml", "sha256": "..." }
  ]
}
```

### 7.2 Local state file (per device, not committed)

Suggested path:
- Windows: `%USERPROFILE%\\.codex-config\\state.json`
- macOS: `~/.codex-config/state.json`

Fields:
- `targetVersion`
- `currentVersion`
- `lastSuccessfulVersion`
- `tool`
- `os`
- `profile`
- `lastSyncAt`

## 8. Security Baseline

- Never commit real credentials.
- Keep `secrets.example` only.
- Inject secrets via env vars or OS keychain.
- Ignore `local.override` and device state in `.gitignore`.
- Add CI secret scan before release.

## 9. OpenSpec and Superpowers Responsibilities

OpenSpec:
- Defines spec model, change lifecycle, and validation gates.

Superpowers:
- Standardizes execution workflow and documentation quality.

Current output is design stage only.
Implementation planning should be produced next as a separate plan document.

## 10. Phase-1 Acceptance Criteria

- Sync to same tag succeeds on one Windows device and one macOS device.
- Both `codex` and `claudex` adapters can render and apply valid configs.
- Manual rollback to previous tag works.
- Every change can produce a validated manifest and changelog entry.
- Failed sync can auto-rollback and preserve logs.

## 11. Milestones

1. M1: Single tool + single OS baseline
- `codex + windows + company/home` with `bootstrap/sync/release`.

2. M2: Multi-tool support
- Add `claudex` adapter and compatibility checks.

3. M3: Cross-OS support
- Add `macos` adapter and validation matrix.

4. M4: Governance hardening
- CI validation, secret scanning, release automation.

