# Integration Catalog

Last Updated (UTC): 2026-04-10T00:55:24Z
Current Repo Version: v2026.04.10.1

## Version Matrix

| Component | Version | Source |
| --- | --- | --- |
| repo | v2026.04.10.1 | manifests/manifest.lock.json |
| rules | v2026.04.10.1 | rules/base.md |
| mcp | v2026.04.10.1 | mcp/servers.yaml |
| plugins | v2026.04.10.1 | plugins/registry.yaml |
| skills | v2026.04.10.1 | skills/README.md |

## MCP Servers

| Name | Transport | Command |
| --- | --- | --- |
| example-local | stdio | node |

## Plugins

| ID | Enabled | Source |
| --- | --- | --- |
| sample.plugin | true | local |

## Skills

- (skills/README.md only)

## Release Rule

- On each release, run `scripts/release.ps1` so this catalog stays aligned with the published version tag.
