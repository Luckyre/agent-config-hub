# agent-config-hub

基于 Git 的集中化配置仓库，用于多设备同化，覆盖：
- 工具：`codex`、`claudex`
- 系统：`windows`、`macos`
- 环境：`company`、`home`

本仓库采用折中版本策略：
- 对外：每次变更发布整仓版本 tag
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

3. 同化到指定版本：

```powershell
.\scripts\sync.ps1 -TargetVersion v2026.04.10.1 -Tool codex -Profile home
```

4. 配置更新后发布版本：

```powershell
.\scripts\release.ps1 -Notes "update rules and mcp servers"
```

## 配置合并优先级

`base -> tool -> os -> profile -> local.override`

## 文档

- 英文设计文档：`docs/superpowers/specs/2026-04-09-codex-config-design.md`
- 中文设计文档：`docs/superpowers/specs/2026-04-09-codex-config-design.zh-CN.md`

