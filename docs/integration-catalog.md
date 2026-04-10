# Integration Catalog

Last Updated (UTC): 2026-04-10T03:10:43Z
Current Repo Version: v2026.04.10.2

## Version Matrix

| Component | Version | Source |
| --- | --- | --- |
| repo | v2026.04.10.2 | manifests/manifest.lock.json |
| rules | v2026.04.10.2 | rules/base.md |
| mcp | v2026.04.10.2 | mcp/servers.yaml |
| plugins | v2026.04.10.2 | plugins/registry.yaml |
| skills | v2026.04.10.2 | skills/catalog.yaml |

## MCP Servers

| Name | Transport | Command |
| --- | --- | --- |
| example-local | stdio | node |

## Skills Catalog

- none

## Plugins

| ID | Enabled | Source |
| --- | --- | --- |
| sample.plugin | true | local |

## MCP Capabilities

- `[example-local]` **Example inspection** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `mcp.example.inspect`
  - summary: Exposes inspection endpoints for local debugging.
  - introduced: `v2026.04.10.1`
- `[example-local]` **Local example execution** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `mcp.example.execute`
  - summary: Runs the bundled local example server over stdio.
  - introduced: `v2026.04.10.1`

## Plugin Capabilities

- `[sample.plugin]` **Local plugin install** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `plugin.sample.install`
  - summary: Makes the sample plugin available from the local registry.
  - introduced: `v2026.04.10.1`

## Skill Capabilities

- none

## Release Diff Summary

- [MCP] `example-local` -> `Example inspection` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [MCP] `example-local` -> `Local example execution` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Plugin] `sample.plugin` -> `Local plugin install` <span style="color:#d9480f;font-weight:600;">NEW</span>

## Release Rule

- On each release, run `scripts/release.ps1` so this catalog stays aligned with the published version tag.
- NEW badges are computed by comparing the current release against the previous release tag.
