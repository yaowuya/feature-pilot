---
description: 启动全流程开发向导 (propose → brainstorm → plan → execute)
---

根据「$ARGUMENTS」调用并严格执行 `fp-start` skill（Codex fallback：读取 `skills/fp-start/SKILL.md`）；该 skill 及其共享 workspace contract 是完整事实源。

同时读取 `../skills/_shared/artifact-layout.md`；所有恢复、交接与核验都委托其 canonical-first Consumer 解析，Producer 写入仍遵守互斥 canonical form。

Gate checksum：

- 用一次 `fp-explore start-routing` 复用匹配 PRD、判断阶段并提供 quick/full 证据；只有用户确认后才切换 `fp-quick`。
- 依次加载 `fp-propose` → `fp-brainstorm` → `fp-plan`，每阶段产物核验并等待明确确认。
- 计划确认前不得修改业务代码；执行必须读取已确认 task 文件并先做 pre-flight review。
- 计划确认后默认加载 `fp-execute`，在当前上下文直接连续执行；用户明确要求逐任务确认时才使用 semi。
- 只有用户明确要求 `fp-execute-sdd`、SDD 或 fresh implementer/reviewer 隔离时才进入复杂模式，不根据任务规模自动切换。
- 仅当用户选择 SDD 后，再让用户选择 SDD 逐项确认或自动连续；直接执行完成后运行一次独立 `fp-review`，再建议归档。

现在根据功能描述「$ARGUMENTS」启动流程。
