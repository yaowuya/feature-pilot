---
description: 启动全流程开发向导 (propose → brainstorm → plan → execute)
---

根据「$ARGUMENTS」调用并严格执行 `fp-start` skill（Codex fallback：读取 `skills/fp-start/SKILL.md`）；该 skill 及其共享 workspace contract 是完整事实源。

同时读取 `../skills/_shared/artifact-layout.md`；所有恢复、交接与核验都委托其 canonical-first Consumer 解析，Producer 写入仍遵守互斥 canonical form。

Gate checksum：

- 用一次 `fp-explore start-routing` 复用匹配 PRD、判断阶段并提供 quick/full 证据；只有用户确认后才切换 `fp-quick`。
- 依次加载 `fp-propose` → `fp-brainstorm` → `fp-plan`，每阶段产物核验并等待明确确认。
- 计划确认前不得修改业务代码；执行必须读取已确认 task 文件并先做 pre-flight review。
- 执行前必须由用户明确选择直接执行或 SDD，不得仅根据任务规模自动选择；每个选项必须说明执行方式、暂停条件和适用场景。
- 仅当用户选择 SDD 后，再让用户选择 SDD 逐项确认或自动连续；自动连续模式在正常任务边界不得停住。
- 完成后运行 `fp-review`，再建议归档。

现在根据功能描述「$ARGUMENTS」启动流程。
