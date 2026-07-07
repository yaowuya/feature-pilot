---
description: 归档已完成的变更
---

# FeaturePilot Archive


## FeaturePilot workspace

执行命令前，先遵守目标项目的 `fp-docs` 契约：如需生成产物，使用 `fp-docs/changes/`、`fp-docs/archive/`；如存在 `fp-docs/settings/agent.md`，先读取与当前阶段相关的配置。不要创建或覆盖客户 settings，除非用户明确要求。
**变更 slug（可选）：** $ARGUMENTS

调用 `fp-archive` skill，完成：
- 确认归档目标（slug 或从列表选择）
- 移动变更目录并更新历史记录
- 更新 `fp-docs/agents/history.md` 和 `AGENTS.md`

等待执行完成后，输出 `✅ 已归档`。

---

**现在开始：** 根据「$ARGUMENTS」调用 fp-archive skill。
