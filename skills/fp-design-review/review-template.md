# Technical Design Review Entry Template

Read this file only after `fp-design-review` resolved the canonical design artifacts and every merged Decision Ledger row is terminal; blocking conditions are owned by `SKILL.md`.

写入 `fp-docs/changes/<slug>/review.md`：change 根唯一评审入口，仅 small form，覆盖全部实际端。叙述性内容默认使用中文；代码、命令、路径、技术标识符、API 字段保留必要英文。

```markdown
# <功能描述> — 开发设计评审

> 评审导航摘要：事实以 Decision Ledger 与设计正文为准；本文件不得复制决策正文。

- **决策统计**：共 <N> 项（阻塞 <N> / 非阻塞 <N>），全部终态
- **数据变更**：<计数与 `design/<端>.md#锚点` 引用，或 `无`>
- **接口变更**：<计数与 `design/<端>.md#锚点` 引用，或 `无`>

## 评审关注点（按章节）

### <设计章节名>（`design/<端>.md#锚点`）
- [ ] <可评审的具体问题，例如字段取舍与迁移、索引是否满足查询、接口幂等、组件复用兼容性>

## 建议评审顺序

- <高风险章节在前，逐项列出章节与锚点>

## 建议抽查路径

- `<path:line>`、`<path:line>`

## 设计入口

- `design/00-index.md`
```

`review.md` 是评审导航摘要，不是决策记录、确认证据或 PRD/proposal/design/task artifact；它不改变任何 Decision Ledger 状态，也不复制台账或设计正文。评审关注点必须引用设计章节锚点，只提炼设计文档已有内容，不得编造；设计未涉及数据或接口变更时对应行显示 `无`。模板占位符替换规则与设计正文相同：`<...>` 占位符在最终产物中无效。
