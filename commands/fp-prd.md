---
description: 将用户故事、想法或痛点澄清为 PRD 文档
---

根据「$ARGUMENTS」调用并严格执行 `fp-prd` skill（Codex fallback：读取 `skills/fp-prd/SKILL.md`），再按其要求加载 `fp-prd-grill-me`；skill 链及共享 workspace contract 是完整事实源。

Gate checksum：

- 默认 PRD-first；用户要求先看原型或 UI-heavy 时用 Prototype-first。
- Bucket A/B 批量审阅；Bucket C 一次一问且不得代答，通常 3–5 个。
- 相关确认摘要获明确批准前，不创建目录、不写 `prd.md` 或 `prototype.html`。
- PRD 只写 `fp-docs/changes/<slug>/prd.md`，并严格使用 skill 指定的懒加载模板。
