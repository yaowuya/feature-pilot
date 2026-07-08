---
description: 初始化 fp-docs 信息层（单一 manifest.md、settings/agent.md/frontend.md/backend.md、intel/），并引导生成可选的 settings 与轻量 discovery
---

# FeaturePilot Init

**初始化目标（可选）：** $ARGUMENTS

## FeaturePilot workspace and information layer

Before choosing output paths, commands, UI/backend rules, or workflow behavior:

1. Walk upward from the current working directory to find `fp-docs/`.
2. If `fp-docs/manifest.md` exists, read it first.
3. Read only relevant settings and intel listed by the manifest.
4. If UI/frontend is involved and `fp-docs/settings/frontend.md` exists, read it as a required source.
5. If backend/API/data/security behavior is involved and `fp-docs/settings/backend.md` exists, read it as a required source.
6. Treat settings/intel as navigation and constraints; verify exact implementation facts against current code.
7. Use two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, backend framework, API envelope, or workflow policy in public skills. Customer-specific rules belong in target-project settings.

Compatibility rule: if an older project has no `fp-docs/manifest.md`, continue from current code and existing settings when safe, and recommend `/fp-init` repair/refresh.

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
