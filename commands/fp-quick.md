---
description: 快速处理小型开发需求、轻量功能、局部 bugfix 或微调优化
---

根据「$ARGUMENTS」调用并严格执行 `fp-quick` skill（Codex fallback：读取 `skills/fp-quick/SKILL.md`）；该 skill 及其共享 workspace contract 是完整事实源。

Gate checksum：

- 使用 `fp-explore quick` 获取候选文件、复用模式、验证路径与范围证据；不加载完整 `fp-propose`，不生成 FeaturePilot change 文档。
- 有阻塞问题时每轮最多问一个实质性问题；否则输出内联实现计划。
- 用户确认计划后才能修改代码，并运行与范围匹配的验证。
