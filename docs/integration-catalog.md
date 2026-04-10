# Integration Catalog

Last Updated (UTC): 2026-04-10T04:29:42Z
Current Repo Version: v2026.04.10.5

## Version Matrix

| Component | Version | Source |
| --- | --- | --- |
| repo | v2026.04.10.5 | manifests/manifest.lock.json |
| rules | v2026.04.10.5 | rules/base.md |
| mcp | v2026.04.10.5 | mcp/servers.yaml |
| plugins | v2026.04.10.5 | plugins/registry.yaml |
| skills | v2026.04.10.5 | skills/catalog.yaml |

## MCP Servers

| Name | Transport | Command |
| --- | --- | --- |
| example-local | stdio | node |

## Skills Catalog

- `openspec-apply-change` | OpenSpec Apply Change | Implement tasks from an existing OpenSpec change and advance task completion.
- `openspec-archive-change` | OpenSpec Archive Change | Archive a completed OpenSpec change after checking artifacts, tasks, and sync status.
- `openspec-explore` | OpenSpec Explore | Explore ideas, investigate problems, and clarify requirements without implementing code.
- `openspec-propose` | OpenSpec Propose | Create a new OpenSpec change with proposal, design, and task artifacts in one pass.

## Plugins

| ID | Enabled | Source |
| --- | --- | --- |
| sample.plugin | true | local |

## MCP Capabilities

- `[example-local]` **Example inspection**
  - id: `mcp.example.inspect`
  - summary: Exposes inspection endpoints for local debugging.
  - introduced: `v2026.04.10.2`
- `[example-local]` **Local example execution**
  - id: `mcp.example.execute`
  - summary: Runs the bundled local example server over stdio.
  - introduced: `v2026.04.10.2`

## Plugin Capabilities

- `[sample.plugin]` **Local plugin install**
  - id: `plugin.sample.install`
  - summary: Makes the sample plugin available from the local registry.
  - introduced: `v2026.04.10.2`

## Skill Capabilities

- `[OpenSpec Apply Change]` **Change context loading** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.apply.context-loading`
  - summary: Reads proposal, design, specs, and task context before implementation starts.
  - introduced: `v2026.04.10.5`
- `[OpenSpec Apply Change]` **Change task implementation** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.apply.implement-tasks`
  - summary: Executes pending OpenSpec tasks and updates task completion status during implementation.
  - introduced: `v2026.04.10.5`
- `[OpenSpec Archive Change]` **Change archival** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.archive.finalize-change`
  - summary: Moves completed changes into the archive path with a dated archive location.
  - introduced: `v2026.04.10.5`
- `[OpenSpec Archive Change]` **Completion verification** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.archive.completion-check`
  - summary: Checks artifact state, task completion, and delta spec sync state before archiving.
  - introduced: `v2026.04.10.5`
- `[OpenSpec Explore]` **Problem exploration** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.explore.problem-discovery`
  - summary: Investigates requirements, tradeoffs, and codebase context before implementation.
  - introduced: `v2026.04.10.5`
- `[OpenSpec Explore]` **Spec-aware discovery** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.explore.spec-capture`
  - summary: Connects exploration results back to OpenSpec proposals, designs, and specs when useful.
  - introduced: `v2026.04.10.5`
- `[OpenSpec Propose]` **Change scaffolding** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.propose.change-scaffold`
  - summary: Creates a new OpenSpec change directory and prepares artifact generation order.
  - introduced: `v2026.04.10.5`
- `[OpenSpec Propose]` **Proposal artifact generation** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.propose.artifact-generation`
  - summary: Generates proposal, design, and task files required to make a change implementation-ready.
  - introduced: `v2026.04.10.5`

## Release Diff Summary

- [Skill] `OpenSpec Apply Change` -> `Change context loading` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Apply Change` -> `Change task implementation` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Archive Change` -> `Change archival` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Archive Change` -> `Completion verification` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Explore` -> `Problem exploration` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Explore` -> `Spec-aware discovery` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Propose` -> `Change scaffolding` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Propose` -> `Proposal artifact generation` <span style="color:#d9480f;font-weight:600;">NEW</span>

## Release Rule

- On each release, run `scripts/release.ps1` so this catalog stays aligned with the published version tag.
- NEW badges are computed by comparing the current release against the previous release tag.
