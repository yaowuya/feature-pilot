---
description: 对普通概念或当前项目事实生成零基础专业图解
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-eli5/SKILL.md`，将自然语言输入「$ARGUMENTS」作为 public input。

Gate checksum：

- 仅在显式 `/fp-eli5`、`$fp-eli5` 或明确图解请求下运行，不自动触发。
- 仓库主题由 `fp-eli5` 单向调用现有 `fp-explore` public standalone；不得修改 `fp-explore`。
- 优先临时 HTML artifact；不可用时降级为 Markdown + Mermaid 或纯文本，默认不写仓库。
