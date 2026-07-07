---
description: 仅生成变更提案文档，不进入后续阶段
---

# FeaturePilot Propose


## FeaturePilot workspace

执行命令前，先遵守目标项目的 `fp-docs` 契约：如需生成产物，使用 `fp-docs/changes/`、`fp-docs/archive/`；如存在 `fp-docs/settings/agent.md`，先读取与当前阶段相关的配置。不要创建或覆盖客户 settings，除非用户明确要求。
**功能描述：** $ARGUMENTS

**如果功能描述为空**，请提示工程师提供详细的需求说明：背景与目标、具体需求、约束与边界。

调用 `fp-propose` skill，完成：
- 探索项目现状（读取 `fp-docs/settings/` 的客户配置，不读取历史 changes/archive；必须以真实代码、测试、路由、模型、组件和 API 为实现事实依据）
- Socratic 需求澄清（如需要，2-4 轮）
- 生成 `fp-docs/changes/<slug>/proposal.md`
- 引导工程师逐节确认提案

等待用户确认后，输出 `✅ 提案已确认`。

---

**现在开始：** 根据「$ARGUMENTS」调用 fp-propose skill。
