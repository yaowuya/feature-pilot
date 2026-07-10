---
description: 仅生成变更提案文档，不进入后续阶段
---

根据「$ARGUMENTS」调用并严格执行 `fp-propose` skill（Codex fallback：读取 `skills/fp-propose/SKILL.md`）；该 skill 及其共享 workspace contract 是完整事实源。

Gate checksum：

- 复用已确认 PRD，不重复访谈已确认决策。
- Why / What Changes / Out of Scope / Impact 摘要获明确确认后才写文件。
- 只写 `fp-docs/changes/<slug>/proposal.md`，不预建 design/tasks。
