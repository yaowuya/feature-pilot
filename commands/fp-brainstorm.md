---
description: 基于已确认的 PRD 或 proposal，通过苏格拉底式提问生成技术设计方案
---

根据「$ARGUMENTS」调用并严格执行 `fp-brainstorm` skill（Codex fallback：读取 `skills/fp-brainstorm/SKILL.md`）；该 skill、共享 workspace contract 与 `../skills/_shared/artifact-layout.md` 是完整事实源。

Gate checksum：

- 先读取已确认 proposal，并按当前代码验证实现事实。
- 每次只问一个架构问题；提出 2–3 个方案和 trade-off。
- 方案、设计章节和 exact paths 都获确认后，每端只写 mutually exclusive form：`backend.md` 或 `backend/00-index.md`、`frontend.md` 或 `frontend/00-index.md`；`design/00-index.md` 直接指向所选入口。
- 按语义边界预选 split form；每个 design 文件的 500 lines 与 30,000 characters 任一 hard limit 都不可越过。
- 不预建 tasks 或 execution 产物。
