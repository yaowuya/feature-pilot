---
description: 仅生成变更提案文档，不进入后续阶段
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-propose/SKILL.md`，将「$ARGUMENTS」作为输入；该 skill 及其共享 workspace contract 是完整事实源。

Gate checksum：

- 从互斥的 `prd.md` / `prd/00-index.md` 解析已确认 PRD，不重复访谈已确认决策。
- Why / What Changes / Out of Scope / Impact 摘要获明确确认后才写文件。
- Proposal 在互斥的 `proposal.md` / `proposal/00-index.md` 中预选一种，split form 以 manifest 保持逻辑模板；不预建 design/tasks。
