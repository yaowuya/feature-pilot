---
description: 基于已确认的 PRD 或 proposal，通过苏格拉底式提问生成技术设计方案
---

根据「$ARGUMENTS」调用并严格执行 `fp-brainstorm` skill（Codex fallback：读取 `skills/fp-brainstorm/SKILL.md`）；该 skill 及其共享 workspace contract 是完整事实源。

Gate checksum：

- 先读取已确认 proposal，并按当前代码验证实现事实。
- 每次只问一个架构问题；提出 2–3 个方案和 trade-off。
- 方案和设计章节都获确认后，才按实际范围写 `design-backend.md` 和/或 `design-frontend.md`。
- 不预建 tasks 或 execution 产物。
