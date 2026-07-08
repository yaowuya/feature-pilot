---
description: 初始化 fp-docs 信息层（单一 manifest.md、settings/agent.md/frontend.md/backend.md、intel/），并引导生成可选的 settings 与轻量 discovery
---

# FeaturePilot Init

**初始化目标（可选）：** $ARGUMENTS

## FeaturePilot workspace

执行命令前，先遵守目标项目的 `fp-docs` 信息层契约：`fp-docs/manifest.md` 是唯一入口；如存在 `fp-docs/settings/agent.md`、`fp-docs/settings/frontend.md`、`fp-docs/settings/backend.md` 或 `fp-docs/intel/*`，先读取 `fp-docs/manifest.md` 判断相关文件。不要覆盖客户 manifest/settings/intel，除非用户明确要求。

调用并严格遵守本插件内 `fp-init` skill：`skills/fp-init/SKILL.md`。

`fp-init` 用于低成本接入 FeaturePilot 信息层：

- 创建 `fp-docs/manifest.md`、`fp-docs/settings/`、`fp-docs/intel/` 最小骨架。
- 不创建 `fp-docs/changes/`、`fp-docs/archive/`、`fp-docs/history/`。
- 如果项目根目录已有 `CLAUDE.md` 或 `AGENTS.md`，在 `fp-docs/manifest.md` 中记录引用，不复制大段内容到 `settings/agent.md`。
- 引导用户选择是否生成可选的 `fp-docs/settings/agent.md`（轻量 FeaturePilot policy adapter）、`fp-docs/settings/frontend.md`（前端/UI）和/或 `fp-docs/settings/backend.md`（后端/API/数据/安全）。
- 引导用户选择是否运行轻量只读 discovery，填充 `fp-docs/intel/*`。
- 所有可选文件均使用 Unknown 占位而非猜测；已有文件绝不覆盖，除非用户明确要求。
- 如果用户不同意可选配置，只创建信息层骨架，不强制配置。

完成后输出工作区路径、manifest 路径、配置生成状态、intel 生成状态、critical unknowns、下一步建议（通常是 `/fp-prd` 或 `/fp-start`）。
