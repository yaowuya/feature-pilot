---
description: 审查并提交当前代码；显式 auto 模式推送后创建 PR/MR，不自动合并
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-commit/SKILL.md`，将「$ARGUMENTS」作为本轮输入；该 skill 与共享 workspace contract 是完整事实源。

Gate checksum：

- 代码规范未初始化时停止，转 `/fp-init`；审查缺陷须修复并验证后才提交。
- `auto` 仅在用户本轮显式选择时启用，创建 PR/MR 后停止，不执行最终合并。
