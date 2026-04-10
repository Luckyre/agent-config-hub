# Codex-Config 多设备同化设计（OpenSpec + Superpowers）

版本：v0.1（设计草案）  
日期：2026-04-09  
策略：折中基线（整仓单一版本 + 组件锁字段预留）

## 1. 目标与范围

目标：
- 使用 Git 作为配置中心，实现“一次配置，多端同化”。
- 使用 OpenSpec 管理配置 schema 与变更治理。
- 支持多工具同化（`codex`、`claudex`）与多系统同化（Windows、macOS）。
- 允许每台设备手动指定目标仓库版本（tag 或 commit）。

范围：
- 管理资产：`rules`、`mcp`、`plugins`、`skills`，以及渲染后的运行时配置。
- 同化方式：以手动指定版本为主，可选周期性更新检查。

非目标（第一阶段）：
- 暂不建设组件级独立发布流水线。
- 仓库中不存放任何明文密钥。

## 2. 架构

采用分层架构：

1. 配置源层（Git）
- 一个仓库存放全部配置资产与脚本。
- 任意有效变更都会产生新的仓库版本 tag（示例：`v2026.04.09.1`）。

2. 规范层（OpenSpec）
- 定义 schema、变更类型与校验门禁。
- 发布前统一走 `change/spec/validate` 流程。

3. 同化运行时层（scripts）
- 按 tool + OS + profile 渲染最终配置。
- 原子应用，失败回滚，并更新本机状态。

4. 适配层（Adapters）
- 工具适配：`codex`、`claudex`
- 系统适配：`windows`、`macos`
- 环境 profile：`company`、`home`
- 本地覆盖：`local.override`（不入库）

## 3. 版本策略（折中方案）

### 3.1 对外版本：整仓单一版本
- `rules/mcp/plugins/skills` 任一变化都发布新的整仓 tag。
- 设备侧只需维护一个 `target_version` 指针。
- 该方案操作简单、可预期性高。

### 3.2 对内元数据：预留组件锁字段
- 在 `manifest.lock.json` 预留以下字段：
  - `rulesVersion`
  - `mcpVersion`
  - `pluginsVersion`
  - `skillsVersion`
- 第一阶段这些字段可与整仓 tag 保持一致。
- 这样可为后续升级到“组件独立版本”保留平滑迁移路径。

## 4. 建议仓库结构

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

## 5. 配置合并优先级

最终配置合并顺序：

`base -> tool -> os -> profile -> local.override`

说明：
- `base`：全局默认值
- `tool`：客户端差异映射
- `os`：路径与 shell 差异
- `profile`：公司/家庭环境差异
- `local.override`：仅本机临时覆盖

## 6. 发布与同化流程

### 6.1 发布流程（维护端）

当 `rules/mcp/plugins/skills` 新增或修改时：

1. 创建 OpenSpec 变更提案。
2. 修改配置资产与映射。
3. 执行校验：
   - `openspec validate`
   - 自定义一致性检查脚本
4. 生成/更新 `manifest.lock.json`（hash、兼容矩阵、组件锁预留字段）。
5. 更新 `CHANGELOG.md`。
6. 创建并推送整仓 tag（示例：`v2026.04.09.1`）。

### 6.2 同化流程（设备端）

手动指定目标版本：

`sync.ps1 -TargetVersion <tag|commit> -Tool <codex|claudex> -Profile <company|home>`

执行顺序：

1. `git fetch --tags`
2. `git checkout <TargetVersion>`
3. `openspec validate`
4. 按 `tool + os + profile` 渲染配置到 `generated/`
5. 备份当前生效配置
6. 原子替换
7. 更新本机状态（`current`、`last_successful`、时间戳）

失败处理：
- 快速失败并回滚到 `last_successful_version`。
- 输出失败原因与差异摘要。

## 7. 清单与本机状态

### 7.1 `manifest.lock.json`（仓库内）

用途：
- 作为可复现同化的不可变快照元数据。

示例：

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

### 7.2 本机状态文件（每台设备本地，不入库）

建议路径：
- Windows：`%USERPROFILE%\\.codex-config\\state.json`
- macOS：`~/.codex-config/state.json`

字段：
- `targetVersion`
- `currentVersion`
- `lastSuccessfulVersion`
- `tool`
- `os`
- `profile`
- `lastSyncAt`

## 8. 安全基线

- 严禁提交真实凭据。
- 仅保留 `secrets.example` 模板。
- 通过环境变量或系统密钥服务注入敏感信息。
- `local.override` 与设备状态文件加入 `.gitignore`。
- 发布前在 CI 增加密钥扫描。

## 9. OpenSpec 与 Superpowers 的职责

OpenSpec：
- 负责规范模型、变更生命周期与校验门禁。

Superpowers：
- 负责执行流程标准化与文档质量控制。

当前交付为设计阶段文档。  
下一步应输出单独的 implementation plan（实现计划）。

## 10. 第一阶段验收标准

- 在一台 Windows 与一台 macOS 设备上可同化到同一 tag。
- `codex` 与 `claudex` 适配层都能渲染并应用有效配置。
- 可手动回滚到历史 tag。
- 每次变更都能产出可校验的 manifest 与 changelog 条目。
- 同化失败可自动回滚并保留日志。

## 11. 里程碑建议

1. M1：单工具 + 单系统基线
- 完成 `codex + windows + company/home` 的 `bootstrap/sync/release`。

2. M2：多工具支持
- 增加 `claudex` 适配与兼容性校验。

3. M3：跨系统支持
- 增加 `macos` 适配并完成双系统验证矩阵。

4. M4：治理增强
- 补齐 CI 校验、密钥扫描与发布自动化。

