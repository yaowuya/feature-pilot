---
description: Use when a user explicitly invokes /fp-prd or $fp-prd, or explicitly asks to create, write, revise, or complete a PRD or product requirements document.
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-prd/SKILL.md`，将「$ARGUMENTS」作为输入，再按其要求加载 `fp-prd-grill-me`；skill 链及共享 workspace contract 是完整事实源。

Gate checksum：

- 默认 PRD-first；用户要求先看原型或 UI-heavy 时用 Prototype-first。
- 非空且涉及现有产品时，`fp-explore` 只提供代码事实；`fp-prd-grill-me` 仍独占产品决策提问与确认。
- Bucket A/B 批量审阅；Bucket C 一次一问且不得代答，通常 3–5 个。
- 相关确认摘要获明确批准前，不创建目录、不写任何 PRD form 或 `prototype.html`。
- PRD 在互斥的 `prd.md` / `prd/00-index.md` 中预选一种；split form 按 manifest 顺序保持完整逻辑模板，`prototype.html` 仍为同级单文件。
