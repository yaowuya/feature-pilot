---
description: 归档已完成的变更
---

根据「$ARGUMENTS」调用并严格执行 `fp-archive` skill（Codex fallback：读取 `skills/fp-archive/SKILL.md`）；该 skill 及其共享 workspace contract 是完整事实源。

Gate checksum：

- 移动前展示源路径、目标路径、未完成任务与 blocked/failed 摘要，并等待明确确认。
- 不创建或修复 manifest/settings/intel。
- 只移动所选 change，并更新 `fp-docs/history/history.md`。
