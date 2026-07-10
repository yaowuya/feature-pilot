---
description: 启动全流程开发向导 (propose → brainstorm → plan → execute)
---

根据「$ARGUMENTS」调用并严格执行 `fp-start` skill（Codex fallback：读取 `skills/fp-start/SKILL.md`）；该 skill 及其共享 workspace contract 是完整事实源。

Gate checksum：

- 复用匹配 PRD；小需求只有用户确认后才切换 `fp-quick`。
- 依次加载 `fp-propose` → `fp-brainstorm` → `fp-plan`，每阶段产物核验并等待明确确认。
- 计划确认前不得修改业务代码；执行必须读取已确认 task 文件并先做 pre-flight review。
- 中大型/跨端/权限/数据/API/UI 契约任务优先 `fp-execute-sdd`；完成后运行 `fp-review`，再建议归档。

现在根据功能描述「$ARGUMENTS」启动流程。
