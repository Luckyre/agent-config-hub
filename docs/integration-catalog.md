# 集成总览

最后更新时间（UTC）：2026-04-10T04:29:42Z
当前仓库版本：`v2026.04.10.5`

## 版本矩阵

| 组件 | 版本 | 来源 |
| --- | --- | --- |
| repo | v2026.04.10.5 | `manifests/manifest.lock.json` |
| rules | v2026.04.10.5 | `rules/base.md` |
| mcp | v2026.04.10.5 | `mcp/servers.yaml` |
| plugins | v2026.04.10.5 | `plugins/registry.yaml` |
| skills | v2026.04.10.5 | `skills/catalog.yaml` |

## MCP 服务

| 名称 | 传输方式 | 启动命令 |
| --- | --- | --- |
| example-local | stdio | node |

## Skills 清单

- `openspec-apply-change` | OpenSpec Apply Change | 从已有 OpenSpec change 继续实现，并推进 task 完成状态。
- `openspec-archive-change` | OpenSpec Archive Change | 在检查 artifacts、tasks 与同步状态后归档已完成的 OpenSpec change。
- `openspec-explore` | OpenSpec Explore | 在不直接实现代码的前提下，探索想法、定位问题并澄清需求。
- `openspec-propose` | OpenSpec Propose | 一次性创建新的 OpenSpec change，并生成 proposal、design 与 tasks 制品。

## Plugins 清单

| ID | 启用状态 | 来源 |
| --- | --- | --- |
| sample.plugin | true | local |

## MCP 能力

说明：保留英文术语名与能力 ID，解释与摘要优先使用中文。

- `[example-local]` **Example inspection**
  - id: `mcp.example.inspect`
  - summary: 暴露本地调试所需的 inspection 能力入口。
  - introduced: `v2026.04.10.2`
- `[example-local]` **Local example execution**
  - id: `mcp.example.execute`
  - summary: 通过 stdio 运行仓库内置的本地示例服务。
  - introduced: `v2026.04.10.2`

## Plugin 能力

- `[sample.plugin]` **Local plugin install**
  - id: `plugin.sample.install`
  - summary: 使示例插件可从本地 registry 直接安装和使用。
  - introduced: `v2026.04.10.2`

## Skill 能力

- `[OpenSpec Apply Change]` **Change context loading** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.apply.context-loading`
  - summary: 在实现开始前读取 proposal、design、specs 与 task 上下文。
  - introduced: `v2026.04.10.5`
- `[OpenSpec Apply Change]` **Change task implementation** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.apply.implement-tasks`
  - summary: 执行待处理的 OpenSpec tasks，并在实现过程中更新完成状态。
  - introduced: `v2026.04.10.5`
- `[OpenSpec Archive Change]` **Change archival** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.archive.finalize-change`
  - summary: 将已完成的 change 按日期归档到 archive 路径。
  - introduced: `v2026.04.10.5`
- `[OpenSpec Archive Change]` **Completion verification** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.archive.completion-check`
  - summary: 在归档前检查 artifact 状态、task 完成度与 delta spec 同步情况。
  - introduced: `v2026.04.10.5`
- `[OpenSpec Explore]` **Problem exploration** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.explore.problem-discovery`
  - summary: 在实现前探索需求、权衡点与代码上下文。
  - introduced: `v2026.04.10.5`
- `[OpenSpec Explore]` **Spec-aware discovery** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.explore.spec-capture`
  - summary: 在合适时把探索结果回连到 OpenSpec proposals、designs 与 specs。
  - introduced: `v2026.04.10.5`
- `[OpenSpec Propose]` **Change scaffolding** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.propose.change-scaffold`
  - summary: 创建新的 OpenSpec change 目录，并准备后续 artifact 生成顺序。
  - introduced: `v2026.04.10.5`
- `[OpenSpec Propose]` **Proposal artifact generation** <span style="color:#d9480f;font-weight:600;">NEW</span>
  - id: `skill.openspec.propose.artifact-generation`
  - summary: 生成让 change 进入可实现状态所需的 proposal、design 与 task 文件。
  - introduced: `v2026.04.10.5`

## 版本差异摘要

- [Skill] `OpenSpec Apply Change` -> `Change context loading` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Apply Change` -> `Change task implementation` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Archive Change` -> `Change archival` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Archive Change` -> `Completion verification` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Explore` -> `Problem exploration` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Explore` -> `Spec-aware discovery` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Propose` -> `Change scaffolding` <span style="color:#d9480f;font-weight:600;">NEW</span>
- [Skill] `OpenSpec Propose` -> `Proposal artifact generation` <span style="color:#d9480f;font-weight:600;">NEW</span>

## 更新规则

- 每次 release 执行 `scripts/release.ps1`，确保该清单与发布版本保持一致。
- `NEW` 标记基于“当前 release 相对上一个 release tag”的差异计算得出。
