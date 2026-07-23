---
description: 基于已确认 proposal 并复用同 slug PRD 决策，通过苏格拉底式提问生成技术设计方案
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-brainstorm/SKILL.md`，将「$ARGUMENTS」作为输入；该 skill 与 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` 是事实源。

Gate checksum：

- 读取已确认 proposal/Decision Ledger，并按当前代码验证事实；不重问已确认产品决策。
- 每次只问一个架构问题；每个 design-required decision ID 都需 per-item confirmation，再提出 2–3 个方案和 trade-off。
- 方案、章节、终态台账、exact paths 与写入授权齐全后，每端只写 mutually exclusive form：`backend.md` 或 `backend/00-index.md`、`frontend.md` 或 `frontend/00-index.md`；`design/00-index.md` 直指所选入口。
- 默认预选 small form；只有预计越过 500 lines / 30,000 characters、用户明确批准，或目标项目设置明确要求时才预选 split form，语义边界仅用于拆分后的分片。
- 过程文档叙述性内容默认使用中文，代码、路径、标识符和精确 schema 词保留必要英文。
- 不预建 tasks 或 execution 产物。
