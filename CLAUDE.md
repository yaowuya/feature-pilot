# CLAUDE.md

## Pull Request 规则

- 创建或更新 Pull Request 时，Summary 和正文说明必须使用中文。
- 代码、命令、文件路径、分支名、提交哈希、API 字段及其他需要精确匹配的技术标识符保留必要英文。
- 验证状态、未完成事项、阻塞和合并冲突必须如实写入 Pull Request，不得省略或宣称未经实际验证的结果。

## CodeGraph 可选加速

- CodeGraph 是可选的本地代码地图，不是 FeaturePilot 的强依赖。
- `fp-init` 未检测到 CLI 时提供自动安装、展示步骤和跳过；自动安装只使用 `npm install -g @colbymchenry/codegraph@latest`，不得使用 `irm`、`curl`、远程安装脚本或 `npx`。
- Agent MCP 配置独立确认；首次建图和后续消费严格遵守 `skills/_shared/codegraph.md`。
- 后续代码调查按 `MCP → CLI → 原有搜索`；图结果只用于导航，失败时回退，关键结论仍须验证当前源码、测试和命令输出。
