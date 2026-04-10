# Integration Catalog

Last Updated (UTC): 2026-04-10T04:26:12Z
Current Repo Version: v2026.04.10.3

## Version Matrix

| Component | Version | Source |
| --- | --- | --- |
| repo | v2026.04.10.3 | manifests/manifest.lock.json |
| rules | v2026.04.10.3 | rules/base.md |
| mcp | v2026.04.10.3 | mcp/servers.yaml |
| plugins | v2026.04.10.3 | plugins/registry.yaml |
| skills | v2026.04.10.3 | skills/catalog.yaml |

## MCP Servers

| Name | Transport | Command |
| --- | --- | --- |
| example-local | stdio | node |

## Skills Catalog

- $(@{id=openspec-apply-change; name=OpenSpec Propose; source=.codex/skills/openspec-propose; summary=Implement tasks from an existing OpenSpec change and advance task completion.; capabilities=System.Object[]}.id) | OpenSpec Propose | Implement tasks from an existing OpenSpec change and advance task completion.

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

- `[OpenSpec Propose]` **** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `openspec-archive-change`
  - summary: Archive a completed OpenSpec change after checking artifacts, tasks, and sync status.
  - introduced: `v2026.04.10.3`
- `[OpenSpec Propose]` **** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `openspec-propose`
  - summary: Create a new OpenSpec change with proposal, design, and task artifacts in one pass.
  - introduced: `v2026.04.10.3`
- `[OpenSpec Propose]` **** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `openspec-explore`
  - summary: Explore ideas, investigate problems, and clarify requirements without implementing code.
  - introduced: `v2026.04.10.3`
- `[OpenSpec Propose]` **Change archival** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.archive.finalize-change`
  - summary: Moves completed changes into the archive path with a dated archive location.
  - introduced: `v2026.04.10.3`
- `[OpenSpec Propose]` **Change context loading** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.apply.context-loading`
  - summary: Reads proposal, design, specs, and task context before implementation starts.
  - introduced: `v2026.04.10.3`
- `[OpenSpec Propose]` **Change scaffolding** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.propose.change-scaffold`
  - summary: Creates a new OpenSpec change directory and prepares artifact generation order.
  - introduced: `v2026.04.10.3`
- `[OpenSpec Propose]` **Change task implementation** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.apply.implement-tasks`
  - summary: Executes pending OpenSpec tasks and updates task completion status during implementation.
  - introduced: `v2026.04.10.3`
- `[OpenSpec Propose]` **Completion verification** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.archive.completion-check`
  - summary: Checks artifact state, task completion, and delta spec sync state before archiving.
  - introduced: `v2026.04.10.3`
- `[OpenSpec Propose]` **Problem exploration** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.explore.problem-discovery`
  - summary: Investigates requirements, tradeoffs, and codebase context before implementation.
  - introduced: `v2026.04.10.3`
- `[OpenSpec Propose]` **Proposal artifact generation** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.propose.artifact-generation`
  - summary: Generates proposal, design, and task files required to make a change implementation-ready.
  - introduced: `v2026.04.10.3`
- `[OpenSpec Propose]` **Spec-aware discovery** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.explore.spec-capture`
  - summary: Connects exploration results back to OpenSpec proposals, designs, and specs when useful.
  - introduced: `v2026.04.10.3`

## Release Diff Summary

- [Skill] `OpenSpec Propose` -> `` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Propose` -> `` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Propose` -> `` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Propose` -> `Change archival` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Propose` -> `Change context loading` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Propose` -> `Change scaffolding` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Propose` -> `Change task implementation` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Propose` -> `Completion verification` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Propose` -> `Problem exploration` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Propose` -> `Proposal artifact generation` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Propose` -> `Spec-aware discovery` <span style="color:#d9480f;font-weight:600;">NEW</span>

## Release Rule

- On each release, run `scripts/release.ps1` so this catalog stays aligned with the published version tag.
- NEW badges are computed by comparing the current release against the previous release tag.
