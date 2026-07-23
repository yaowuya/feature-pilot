---
description: 对已完成的 FeaturePilot 变更执行归档前最终整分支只读审查
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-review/SKILL.md`，将「$ARGUMENTS」作为输入；该 skill 及其共享 workspace contract 是完整事实源。

Gate checksum：

- 除最终 review 报告外保持只读，不修复实现、任务、ledger 或 git history。
- 审查全部 proposal/design/tasks/progress/reviews 与整分支 diff、验证证据和信息层消费。
- 使用 Critical/High/Medium/Low 与唯一 verdict；报告只写 skill 指定路径。
- 缺 slug/baseRef 时按 skill 的确定规则处理，不猜测。
- Direct independent final scope attempt 1; does not auto-fix; does not auto-retry.
