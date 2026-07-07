---
description: 初始化 fp-docs 工作区，并引导生成可选的 settings/agent.md 项目配置
---

# FeaturePilot Init

**初始化目标（可选）：** $ARGUMENTS

## FeaturePilot workspace

执行命令前，先遵守目标项目的 `fp-docs` 契约：如需生成产物，使用 `fp-docs/changes/`、`fp-docs/archive/`；如存在 `fp-docs/settings/agent.md`，先读取配置。不要覆盖客户 settings，除非用户明确要求。

调用并严格遵守本插件内 `fp-init` skill：`skills/fp-init/SKILL.md`。

`fp-init` 用于低成本接入 FeaturePilot：

- 创建最小 `fp-docs/` 目录结构。
- 引导用户选择是否生成 `fp-docs/settings/agent.md`。
- 如果用户同意，基于当前项目真实代码、README、package/依赖和测试脚本生成项目配置草案。
- 如果用户不同意，只创建工作区基础目录，不强制配置。

完成后输出工作区路径、是否生成配置、下一步建议（通常是 `/fp-prd` 或 `/fp-start`）。
