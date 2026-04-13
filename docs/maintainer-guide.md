# 维护说明

面向仓库维护者，汇总文档写作约定、标签样式、版本发布动作与全局工具资源说明。

## Markdown 编写约定

- 标题层级最多使用到 `###`，避免目录层级过深。
- 常规说明优先用短段落或列表；同级列表保持同一语气与句式。
- 只有在“需要横向对比”时才使用表格，纯说明性内容优先列表。
- 代码、命令、路径统一使用 fenced code block 或反引号标记。
- 表情可少量用于提示性场景，如 `📌`、`🆕`、`🛠`、`📘`，不要给每一项都加表情。
- 状态标签建议固定样式，避免同一文档内颜色和命名频繁变化。

## 推荐标签样式

- `<span style="color:#d9480f;font-weight:600;">NEW</span>`：本版本刚新增，适合标记新接入能力。
- `<span style="color:#1d4ed8;font-weight:600;">INFO</span>`：补充说明或使用提示。
- `<span style="color:#15803d;font-weight:600;">STABLE</span>`：已稳定、可长期依赖的内容。

## 版本迭代要求

1. 按需更新 `rules/`、`mcp/`、`plugins/`、`skills/`、`configs/`。
2. 执行 `./scripts/release.ps1 -Notes "<本次变更说明>"`。
3. 发布脚本会自动更新：
   - `manifests/manifest.lock.json`
   - `manifests/integration-history.json`
   - `CHANGELOG.md`，包含版本矩阵与 MCP / Plugins / Skills 摘要
   - `docs/integration-catalog.md`
   - `README.md` 与 `README.en.md` 中的能力枚举托管区块
4. 推送提交与标签：`git push origin HEAD --tags`。

## 全局工具资源

- `tooling/codex/prompts/global-style.md`：Codex 全局协作风格的仓库内版本源文件。
- `tooling/codex/start-codex.ps1`：启动 Codex 时注入全局 style prompt 的本地包装脚本模板。
- `tooling/claudex/prompts/global-style.md`：Claude / Claudex 侧复用的全局协作风格源文件。
- `tooling/claudex/start-claude.ps1`：启动 `claude.exe` 时通过 `--append-system-prompt` 注入全局 style prompt 的包装脚本模板。
- `configs/tools/claudex.yaml` 当前映射到本机实际配置根目录 `~/.claude`，而不是 `~/.claudex`。
- `scripts/install-tooling.ps1`：将仓库中的 tooling 资源安装到本机真实目录；`scripts/sync.ps1` 完成 live 配置更新后会自动调用。
- `scripts/sync.ps1`：当前还会渲染 `effective-config.json`，并把托管的 `rules`、运行时 `skills / commands` 以及生成的 MCP 配置 apply 到工具真实目录；插件注册表暂未直接驱动原生插件安装。
