---
description: 快速处理小型开发需求、轻量功能、局部 bugfix 或微调优化
---

# FeaturePilot Quick

**快速任务：** $ARGUMENTS

## FeaturePilot workspace

执行命令前，先遵守目标项目的 `fp-docs` 契约。如需生成产物，按需使用 `fp-docs/changes/`；如存在 `fp-docs/settings/agent.md`，先读取配置。

调用并严格遵守本插件内 `fp-quick` skill：`skills/fp-quick/SKILL.md`。

`fp-quick` 用于不适合走完整 proposal-design-plan 链路的小型需求：

- 先加载 `fp-propose` 并复用其项目探索与需求澄清规则，但不生成 proposal.md 或完整的 `fp-docs/changes/` 产物。
- 如果需求清晰可直接实施，输出内联实现计划并等待用户确认。
- 如果存在阻塞疑问，向用户提问澄清。
- 确认后按计划实现与验证。

完成后直接交付改动，不生成持久化流程文档。
