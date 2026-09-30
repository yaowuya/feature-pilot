---
description: 从已确认设计生成开发设计评审入口 review.md
---
用 `${CLAUDE_PLUGIN_ROOT}/skills/fp-design-review/SKILL.md` `$ARGUMENTS`
Gate checksum：
- 仅消费 canonical design；dual form/historical path、台账非终态、凭据无效或设计不足阻塞，保留 review.md，返回 `fp-brainstorm`
- 只写 change根 review.md，small form覆盖全端，生成独立可读的完整评审文档；不复制台账/叙述正文，字段载体仅精确摘录一种，不编造
- 充分性通过后加载共享文档风格契约→review模板；结论/主线优先，复选框仅验证/最终结论
- 成功后报告 review.md 路径和结论/主线/风险/评审顺序；不改设计、Decision Ledger/台账状态，不推进阶段
