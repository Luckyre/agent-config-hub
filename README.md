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
.\scripts\sync.ps1 -TargetVersion v2026.04.10.2 -Tool codex -Profile home
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

<!-- BEGIN:CAPABILITY-CATALOG -->

### MCP 能力枚举

- `[example-local]` Example inspection <span style="color:#d9480f;font-weight:600;">NEW</span>: Exposes inspection endpoints for local debugging. (`introduced: v2026.04.10.2`)
- `[example-local]` Local example execution <span style="color:#d9480f;font-weight:600;">NEW</span>: Runs the bundled local example server over stdio. (`introduced: v2026.04.10.2`)

### Plugins 能力枚举

- `[sample.plugin]` Local plugin install <span style="color:#d9480f;font-weight:600;">NEW</span>: Makes the sample plugin available from the local registry. (`introduced: v2026.04.10.2`)

### Skills 能力枚举

- 暂无托管 Skills 能力项。

> 标记说明：带有 `<span style="color:#d9480f;font-weight:600;">NEW</span>` 的能力表示“相对上一个 release tag，本次版本刚新增”。

<!-- END:CAPABILITY-CATALOG -->

## 当前版本映射

| 组件 | 版本 |
| --- | --- |
| repo | v2026.04.10.2 |
| rules | v2026.04.10.2 |
| mcp | v2026.04.10.2 |
| plugins | v2026.04.10.2 |
| skills | v2026.04.10.2 |

## 版本迭代要求（每次发布必做）

1. 按需更新 `rules/`、`mcp/`、`plugins/`、`skills/`、`configs/`。
2. 执行 `.\scripts\release.ps1 -Notes "<本次变更说明>"`。
3. 发布脚本会自动更新：
   - `manifests/manifest.lock.json`
   - `manifests/integration-history.json`
   - `CHANGELOG.md`（含版本矩阵与 MCP/Plugins/Skills 摘要）
   - `docs/integration-catalog.md`
   - `README.md` 与 `README.en.md` 中的能力枚举托管区块
4. 推送提交与标签：`git push origin HEAD --tags`。
