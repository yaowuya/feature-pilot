---
description: 仅生成变更提案文档，不进入后续阶段
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-propose/SKILL.md`，将「$ARGUMENTS」作为输入；该 skill 及其共享 workspace contract 是完整事实源。

Gate checksum：

- 从互斥的 `prd.md` / `prd/00-index.md` 解析已确认 PRD，写入 Decision Ledger 已确认行，不重复访谈。
- proposal-required 未决项须 per-item confirmation；整体确认不能替代带 decision ID 的选择。
- 摘要、终态台账和单独写入授权齐全后才写；Proposal 只选 `proposal.md` 或 `proposal/00-index.md`，不预建 design/tasks。
