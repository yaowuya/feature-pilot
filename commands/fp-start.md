---
description: 启动全流程开发向导
---
用 `${CLAUDE_PLUGIN_ROOT}/skills/fp-start/SKILL.md` `$ARGUMENTS`；`${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md`：canonical-first Consumer
Gate checksum：
- `fp-explore`→用户确认→`fp-quick`
- `fp-propose`→`fp-brainstorm`→`fp-plan` 逐阶段核验/确认；proposal/design查 Decision Ledger/per-item confirmation
- proposal/design 写门禁后加载共享文档风格契约；禁改确认内容/Decision Ledger/canonical layout
- 模型由 `fp-brainstorm` 核验真实基类/继承字段/物理存储/约束/migration；评审禁重设计
- 计划确认前禁改业务代码；执行仅用已确认 task 文件，禁聊天摘要
- 默认加载 `fp-execute`；仅用户明确要求逐任务确认才用 `semi`
- 只有用户明确要求 `fp-execute-sdd`/通用 `SDD`/fresh implementer/reviewer isolation 才进 SDD，再选 SDD 逐项确认或自动连续
- 完成后由 `fp-final-review` 接管最终评审/交接
