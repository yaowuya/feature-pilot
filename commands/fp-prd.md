---
description: 将用户故事、想法或痛点澄清为 PRD 文档
---

# FeaturePilot PRD


## FeaturePilot workspace

执行命令前，先遵守目标项目的 `fp-docs` 契约：如需生成产物，使用 `fp-docs/changes/`、`fp-docs/archive/`；如存在 `fp-docs/settings/agent.md`，先读取与当前阶段相关的配置。不要创建或覆盖客户 settings，除非用户明确要求。
**想法 / 用户故事 / 需求描述：** $ARGUMENTS

**如果输入为空**，请提示工程师给出一句想法、痛点、目标或用户故事即可；不要要求一次性提供完整 PRD。

调用 `fp-prd` skill，完成：
- 先加载 `fp-prd-grill-me` 完成必要提问与确认
- 生成 `fp-docs/changes/<slug>/prd.md`
- 如需要页面/交互原型，生成同级 `prototype.html`
- 停止在 PRD 交付阶段，不自动进入 proposal/design/plan/execute
- 下一步建议用户运行 `/fp-start <slug>` 接住 PRD 并进入开发链路

---

**现在开始：** 根据「$ARGUMENTS」调用 `fp-prd` skill。
