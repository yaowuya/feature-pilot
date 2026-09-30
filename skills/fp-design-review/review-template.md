# Technical Design Review Output Contract

Read this file only after `fp-design-review` resolves canonical design artifacts, verifies every merged Decision Ledger row is terminal, and passes design sufficiency. The skill must already have loaded `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md`.

Write only `fp-docs/changes/<slug>/review.md`. It is the change-root unique review entry, always small form, and covers every actual end. Narrative defaults to Chinese; exact code, commands, paths, identifiers, and API fields retain necessary English.

Generate applicable sections only. Omit an inapplicable data/state/interface/frontend section instead of writing empty boilerplate. Never omit the opening conclusion, business/technical mainline, core-object responsibilities, risks and validation, review order, conclusion record, or design entry.

决策统计、数据变更、接口变更、评审关注点、建议评审顺序和建议抽查路径必须融入下列完整评审结构；不得复制决策正文，不得编造设计事实。

````markdown
# <功能描述> — 开发设计评审

## 评审结论

<首段直接给出建议结论：通过、有条件通过或退回修改；说明最主要依据和仍需关注的风险。>

| 评审面 | 结论 | 设计依据 |
| --- | --- | --- |
| 决策 | <共 N 项；阻塞 N / 非阻塞 N；全部终态> | <唯一 design 锚点> |
| 数据 | <关键变化或无> | <唯一 design 锚点或“无”> |
| 接口 | <关键变化或无> | <唯一 design 锚点或“无”> |
| 前端 | <关键变化或无> | <唯一 design 锚点或“无”> |
| 不做事项 | <明确边界> | <唯一 design 锚点> |

## 业务和技术主线

<按触发、处理、状态变化、结果与失败收束说明完整主线；只提炼设计已有内容。>

## 核心对象与职责

| 对象/模块 | 职责 | 不负责 | 协作对象 | 设计依据 |
| --- | --- | --- | --- | --- |
| <对象> | <单一职责> | <边界> | <依赖或调用方> | <design 锚点> |

## 数据模型评审

数据模型适用时，只生成一种字段定义表示：canonical design 含接近实现的模型代码时精确摘录代码并省略“完整字段定义”；否则使用已确认的完整字段定义表并省略代码小节。不得从字段表推导或编造模型代码。

### 接近实现的模型代码

```text
<仅当 canonical design 含已确认模型代码时精确摘录；不得自行补充字段。>
```

### 完整字段定义

| 字段 | 类型 | 必填/空值 | 默认值 | 关联/约束 | 设计依据 |
| --- | --- | --- | --- | --- | --- |
| <仅在无模型代码时摘录完整字段定义> | <类型> | <规则> | <默认值> | <关联或约束> | <design 锚点> |

### 物理存储、继承与重复存储

| 逻辑对象 | 物理表/存储 | 继承字段来源 | 主键与关联键 | 重复存储结论 |
| --- | --- | --- | --- | --- |
| <对象> | <表或存储> | <基类/mixin/无> | <主键、外键或引用> | <结论> |

### 字段与存储取舍

| 字段或存储选择 | 最终方案 | 主要取舍 | 项目证据 |
| --- | --- | --- | --- |
| <文本/JSON/压缩/关联等选择> | <方案> | <数据体积、读写与维护影响> | <design 锚点> |

### 查询模式与索引映射、约束与迁移

| 查询模式 | 过滤/排序/关联字段 | 索引或访问路径 | 设计依据 |
| --- | --- | --- | --- |
| <查询> | <字段顺序> | <索引/访问路径> | <design 锚点> |

<补充唯一约束、软删除语义、migration 和回滚影响；不得重新设计。>

## 状态、并发和执行流程

<仅在适用时生成；说明状态入口、并发控制、执行顺序、失败恢复和可观察结果。>

## 接口、权限和旧入口隔离

| 接口/入口 | 主键或资源 | 权限 | 兼容或隔离边界 | 设计依据 |
| --- | --- | --- | --- | --- |
| <接口或入口> | <标识> | <角色/权限点> | <新旧边界> | <design 锚点> |

## 前端方案

<仅在适用时生成；说明页面、组件、状态、路由、视觉来源和可执行 Visual Checks。>

## 主要风险、迁移、发布和验证

### 主要风险

| 具体失败场景 | 影响 | 预防或处理 | 设计依据 |
| --- | --- | --- | --- |
| <触发条件和错误结果> | <用户/数据/系统影响> | <已确认处理> | <design 锚点> |

### 迁移与发布

<说明 schema/data migration、兼容窗口、发布顺序、回滚和监控；无适用项时说明设计为何无此风险。>

### 验证清单

- [ ] <可执行命令、测试或人工检查；写出预期结果和 design 锚点。>

## 评审顺序与抽查路径

1. <最高风险章节及原因；附 design 锚点。>
2. <下一章节及原因；附 design 锚点。>

- 建议抽查：`<path:line>`

## 评审结论记录

- [ ] 通过：设计完整，可以进入计划阶段。
- [ ] 有条件通过：<必须在计划或实现前满足的条件。>
- [ ] 退回修改：<需要返回 fp-brainstorm 的精确章节。>

## 设计入口

- `design/00-index.md`
````

`review.md` is a review document, not a decision record or second design owner. Decision Ledger is summarized by count only;不得复制 Decision Ledger rows，不得机械复制设计正文。字段定义只可从已确认设计精确摘录，并由模型代码或完整字段定义表之一承载；不得自行补充字段或推导代码。

The complete file must remain within 500 lines and 30,000 characters. If deduplication and links cannot keep it within both limits, block instead of truncating because `review.md` has no split form.

复选框只用于验证清单和最终评审结论。正文、表格、模型代码和解释各自承担不同职责，不重复同一事实。设计入口只出现一次。

## Document readability self-review

- 第一段直接给出结果，主线先于局部细节。
- 标题最多三级；段落不超过 7 行，并优先控制在 4 行以内。
- 必要术语首次出现时使用直白解释；精确技术标识符保持不变。
- 风险写出具体失败场景、影响和已确认处理，不使用“注意风险”等空泛措辞。
- 复选框只用于验证清单和最终评审结论。
- Decision Ledger 只统计，设计事实只提炼，不新增或改变结论。
- 字段定义只由模型代码或完整字段定义表之一承载；物理映射、字段/存储取舍和查询/索引表不重复字段事实。
- 数据表格、代码和解释不重复表达同一事实。
- `## 设计入口` 恰好出现一次。
