# agent-config-hub

语言: 中文 | [English](README.en.md)

面向多设备、多工具、多环境的 Agent 配置中心仓库。

它的目标不是单纯“存一份配置”，而是把 `rules`、`mcp`、`plugins`、`skills` 和运行时 `configs` 放进同一条可追踪、可发布、可回滚的配置链路里，降低手工同步和跨设备漂移的成本。

仓库当前覆盖：
- 工具：`codex`、`claudex`
- 系统：`windows`、`macos`
- 环境：`company`、`home`

核心能力包括：
- 以 Git 作为配置分发与审计基础
- 通过 `bootstrap` / `sync` / `release` 脚本完成初始化、按版本同步、正式发布
- 同步时自动安装 `codex / claude` 的全局 prompt 与启动脚本，减少手工复制
- 对 `MCP / Plugins / Skills` 做结构化能力枚举与版本跟踪
- 通过版本锁文件和能力历史记录，明确“某个版本包含哪些能力”

适用场景包括：
- 个人在多台设备间保持一致的 Agent 配置
- 在家庭与公司环境之间切换不同配置组合
- 为团队维护一套可审计、可发布的配置基线

本仓库采用折中版本策略：
- 对外：每次有效变更发布整仓版本 `tag`
- 对内：在 `manifests/manifest.lock.json` 预留组件锁字段，便于后续演进

## 快速开始

1. 克隆仓库：

```powershell
git clone https://github.com/Luckyre/agent-config-hub.git
cd agent-config-hub
```

2. 初始化本机：

```powershell
.\scripts\bootstrap.ps1 -Tool codex -Profile company
```

3. 同步到当前稳定版本：

```powershell
.\scripts\sync.ps1 -TargetVersion v2026.04.10.5 -Tool codex -Profile home
```

4. 配置更新后发布新版本：

```powershell
.\scripts\release.ps1 -Notes "update rules and mcp servers"
```

## 配置合并优先级

`base -> tool -> os -> profile -> local.override`

## 集成能力清单

- MCP 服务定义：`mcp/servers.yaml`
- MCP 能力枚举：`mcp/servers.yaml` 中的 `capabilities`
- Plugin 清单：`plugins/registry.yaml`
- Plugin 能力枚举：`plugins/registry.yaml` 中的 `capabilities`
- Skills 清单：`skills/README.md`
- Skills 能力枚举：`skills/catalog.yaml`
- 能力历史记录：`manifests/integration-history.json`
- 版本锁文件：`manifests/manifest.lock.json`
- 集成总览：`docs/integration-catalog.md`
- 维护说明：`docs/maintainer-guide.md`

<!-- BEGIN:CAPABILITY-CATALOG -->

### MCP 能力枚举

说明：这里枚举的是每个 MCP 服务在当前配置里实际暴露的能力项，而不只是服务名称。

- `[example-local]` Example inspection：暴露本地调试所需的 inspection 能力入口。(`introduced: v2026.04.10.2`)
- `[example-local]` Local example execution：通过 stdio 运行仓库内置的本地示例服务。(`introduced: v2026.04.10.2`)

### Plugins 能力枚举

说明：这里枚举的是每个 Plugin 当前接入后的能力动作，而不只是注册表中的插件条目。

- `[sample.plugin]` Local plugin install：使示例插件可从本地 registry 直接安装和使用。(`introduced: v2026.04.10.2`)

### Skills 能力枚举

说明：这里枚举的是每个 Skill 可执行的能力动作，保留英文术语名，并用中文解释具体作用。

- `[OpenSpec Apply Change]` Change context loading <span style="color:#d9480f;font-weight:600;">NEW</span>：在实现开始前读取 proposal、design、specs 与 task 上下文；属于“变更上下文加载”能力。(`introduced: v2026.04.10.5`)
- `[OpenSpec Apply Change]` Change task implementation <span style="color:#d9480f;font-weight:600;">NEW</span>：执行待处理的 OpenSpec tasks，并在实现过程中更新完成状态；属于“任务落地执行”能力。(`introduced: v2026.04.10.5`)
- `[OpenSpec Archive Change]` Change archival <span style="color:#d9480f;font-weight:600;">NEW</span>：将已完成的 change 按日期归档到 archive 路径；属于“变更归档”能力。(`introduced: v2026.04.10.5`)
- `[OpenSpec Archive Change]` Completion verification <span style="color:#d9480f;font-weight:600;">NEW</span>：在归档前检查 artifact 状态、task 完成度与 delta spec 同步情况；属于“归档前校验”能力。(`introduced: v2026.04.10.5`)
- `[OpenSpec Explore]` Problem exploration <span style="color:#d9480f;font-weight:600;">NEW</span>：在实现前探索需求、权衡点与代码上下文；属于“问题探索”能力。(`introduced: v2026.04.10.5`)
- `[OpenSpec Explore]` Spec-aware discovery <span style="color:#d9480f;font-weight:600;">NEW</span>：在合适时把探索结果回连到 OpenSpec proposals、designs 与 specs；属于“面向规范的发现”能力。(`introduced: v2026.04.10.5`)
- `[OpenSpec Propose]` Change scaffolding <span style="color:#d9480f;font-weight:600;">NEW</span>：创建新的 OpenSpec change 目录，并准备后续 artifact 生成顺序；属于“变更脚手架生成”能力。(`introduced: v2026.04.10.5`)
- `[OpenSpec Propose]` Proposal artifact generation <span style="color:#d9480f;font-weight:600;">NEW</span>：生成让 change 进入可实现状态所需的 proposal、design 与 task 文件；属于“proposal 制品生成”能力。(`introduced: v2026.04.10.5`)

> 标记说明：带有 `<span style="color:#d9480f;font-weight:600;">NEW</span>` 的能力表示“相对上一个 release tag 本次刚新增”。

<!-- END:CAPABILITY-CATALOG -->

## 当前版本映射

| 组件 | 版本 |
| --- | --- |
| repo | v2026.04.10.5 |
| rules | v2026.04.10.5 |
| mcp | v2026.04.10.5 |
| plugins | v2026.04.10.5 |
| skills | v2026.04.10.5 |



