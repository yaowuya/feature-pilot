---
description: 基于已确认的 PRD 或 proposal，通过苏格拉底式提问生成技术设计方案
---

# FeaturePilot Brainstorm

**设计目标：** $ARGUMENTS

## FeaturePilot workspace

执行命令前，先遵守目标项目的 `fp-docs` 契约：如需生成产物，使用 `fp-docs/changes/`；如存在 `fp-docs/settings/agent.md`，先读取与当前阶段相关的配置。如果 settings 不存在，回退到当前代码和用户回答。

调用并严格遵守本插件内 `fp-brainstorm` skill：`skills/fp-brainstorm/SKILL.md`。

`fp-brainstorm` 在你已有一个已确认的 proposal（通过 `/fp-propose` 或 `/fp-start` 生成）时使用：

- 读取 `fp-docs/changes/<slug>/proposal.md` 确认范围。
- 通过一次一个问题的苏格拉底式提问，澄清架构决策。
- 根据实际涉及范围生成 `design-backend.md`、`design-frontend.md` 或两者。
- 不预建后续阶段的文件（`tasks/`、`.fp-execute/` 等）。

完成后输出生成的设计文件路径，提示下一步通常是 `/fp-start` 进入计划阶段。
