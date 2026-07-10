---
description: 快速处理小型开发需求、轻量功能、局部 bugfix 或微调优化
---

根据「$ARGUMENTS」调用并严格执行 `fp-quick` skill（Codex fallback：读取 `skills/fp-quick/SKILL.md`）；该 skill 及其共享 workspace contract 是完整事实源。

Gate checksum：

- 仅复用 `fp-propose` 的探索/澄清规则，不生成 FeaturePilot change 文档。
- 有阻塞问题才提问；否则输出内联实现计划。
- 用户确认计划后才能修改代码，并运行与范围匹配的验证。
