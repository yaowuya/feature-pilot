---
description: 启动全流程开发向导
---

读取 `${CLAUDE_PLUGIN_ROOT}/skills/fp-start/SKILL.md`，以「$ARGUMENTS」执行。

按 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` 以 canonical-first Consumer 解析。

Gate checksum：

- `fp-explore` 路由后，用户确认才切换 `fp-quick`。
- 依次加载 `fp-propose` → `fp-brainstorm` → `fp-plan`；逐阶段核验/确认，proposal/design 还核验 Decision Ledger 与 per-item confirmation。
- 计划确认前不改业务代码；执行读取已确认 task 文件。
- 计划确认后默认加载 `fp-execute`；逐任务确认才使用 semi。
- 只有用户明确要求 `fp-execute-sdd`、SDD 或 fresh implementer/reviewer isolation 才进入 SDD；再选择 SDD 逐项确认或自动连续，完成后运行 `fp-review`。
