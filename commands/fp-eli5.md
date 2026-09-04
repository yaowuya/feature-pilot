---
description: 对普通概念或当前项目事实直接展示零基础专业中文图解
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-eli5/SKILL.md`，将自然语言输入「$ARGUMENTS」作为 public input。

Gate checksum：

- 仅在显式 `/fp-eli5`、`$fp-eli5` 或明确图解请求下运行，不自动触发。
- 仓库主题由 `fp-eli5` 单向调用现有 `fp-explore` public standalone；不得修改 `fp-explore`。
- 默认直接展示中文图解，不依赖原始 HTML 标签或 Mermaid；仅在用户明确要求且宿主具备专用网页图解能力时才生成临时网页图解，默认不写仓库。
