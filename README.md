# agent-config-hub

语言: 中文 | [English](README.en.md)

基于 Git 的集中化配置仓库，用于多设备同步，覆盖：
- 工具：`codex`、`claudex`
- 系统：`windows`、`macos`
- 环境：`company`、`home`

本仓库采用折中版本策略：
- 对外：每次变更发布整仓版本 `tag`
- 对内：在 `manifests/manifest.lock.json` 预留组件锁字段

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

3. 同步到指定版本：

```powershell
.\scripts\sync.ps1 -TargetVersion v2026.04.10.1 -Tool codex -Profile home
```

4. 配置更新后发布版本：

```powershell
.\scripts\release.ps1 -Notes "update rules and mcp servers"
```

## 配置合并优先级

`base -> tool -> os -> profile -> local.override`

## 集成能力清单

- MCP 服务：`mcp/servers.yaml`
- 插件清单：`plugins/registry.yaml`
- Skills 清单：`skills/README.md`
- 版本锁文件：`manifests/manifest.lock.json`
- 设备选型总览：`docs/integration-catalog.md`

## 当前版本映射

| 组件 | 版本 |
| --- | --- |
| repo | v2026.04.10.1 |
| rules | v2026.04.10.1 |
| mcp | v2026.04.10.1 |
| plugins | v2026.04.10.1 |
| skills | v2026.04.10.1 |

## 版本迭代要求（每次发布必做）

1. 按需更新 `rules/`、`mcp/`、`plugins/`、`skills/`、`configs/`。
2. 执行 `.\scripts\release.ps1 -Notes "<本次变更说明>"`。
3. 发布脚本会自动更新：
   - `manifests/manifest.lock.json`
   - `CHANGELOG.md`（含版本矩阵与 MCP/Plugins/Skills 摘要）
   - `docs/integration-catalog.md`
4. 推送提交与标签：`git push origin HEAD --tags`。

## 文档

- 英文设计文档：`docs/superpowers/specs/2026-04-09-codex-config-design.md`
- 中文设计文档：`docs/superpowers/specs/2026-04-09-codex-config-design.zh-CN.md`
- 英文 README：`README.en.md`
