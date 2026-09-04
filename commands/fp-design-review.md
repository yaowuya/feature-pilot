---
description: 从已确认设计生成开发设计评审入口 review.md
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-design-review/SKILL.md`，将「$ARGUMENTS」作为 slug 输入；该 skill 与其 review-template.md 是完整事实源。

Gate checksum：

- 只从已核验的 canonical design 生成；设计缺失、dual form/historical path 或台账存在未终态行时阻塞并报告，不生成。
- 只写 change 根 `fp-docs/changes/<slug>/review.md`，仅 small form，覆盖全部实际端；不得复制决策正文或设计正文，不得编造。
- 不修改设计文件、Decision Ledger 或任何台账状态；不推进任何阶段。
- 生成后报告实际路径并展示评审入口摘要。
