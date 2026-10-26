# FeaturePilot Frontend Reuse Contract

本契约用于前端能力复用、Plan 阶段的新模块目录确认及其执行交接。它不改变 proposal/design 决策、计划批准、任务完成权威或 UI/E2E 门禁，也不依赖个人目录中的同名 Skill。

## Applicability

按实际工作判断，不按扩展名或是否有 Figma 判断：

| Frontend Scope | Reuse investigation | New-module directory confirmation |
| --- | --- | --- |
| `new-module` | required | Plan 阶段展示具体方案后确认 |
| `refactor` | required | 不新增首次确认；遵守已批准结构和下方变更规则 |
| `new-files` | required | 不新增首次确认；遵守已批准结构和下方变更规则 |
| `not-applicable` | not-required | 不要求 |

新模块、已有前端模块重构（含整体重写、删除后重新生成）、新增前端源码文件适用。新增文件包括页面、组件、hook/composable、状态、样式和前端工具；不能把所有 `.js` / `.ts` 文件都归为前端。执行中临时发现需要新增前端文件时也先检查复用。

不涉及重构或新增前端源码的普通修复、样式调整、只读调查，仅在用户明确要求时加载本契约。纯后端、过程文档、原型产物和生成证据不触发本契约，不生成空的前端记录。

## Discovery And Reuse

先读目标项目规范，用文件清单定位真实前端工程、workspace/package 边界，再结合别名、导出、自动注册、import 和实际调用判断职责。业务组件与公共组件是职责层级，不是固定目录；不预设 `common`、`components`、`src/components`，也不要求项目新建这些目录。已有调查仍然有效时只补查变化或缺口。

对每项实际能力，按“同类模块 → 业务组件 → 公共组件/hook/工具 → 已安装 UI 库”查找实现与调用。上层满足需求就停止；需要跳层时记录已查范围与具体不适配原因，不为凑齐四层重复搜索。文件名、搜索命中或一个 import 本身不证明已经理解能力。

核对项目实际 UI 库版本和原生 API；项目要求 MCP 时遵循项目规则，不可用则按项目允许的安装源码、类型或匹配版本文档验证。沿用原生搜索、清空、分页、校验、禁用等能力，不外包一层旧组件后在内部重写相同状态与交互。旧实现有缺陷或冲突时保留有效部分并说明差异，不盲目照抄。

只有已有能力不能覆盖实际需求时才新增最小实现，并落在现有合适层级。保留需求范围内的 API、权限、输入/展示、筛选、分页、校验、异步和错误处理，以及图标、token、样式与注册方式；不省掉原有功能，也不补用户未要求的交互。

## Single Record Owner

复用结论只有一个详细 owner：通常在 canonical frontend design；没有独立设计时在 frontend plan，`fp-quick` 则在内联计划。其他阶段引用它，不另建复用报告、目录审批文件或第二份计划。

### Frontend Reuse Decisions

| Capability | Reference | Reuse Decision | Gap / Deviation | Verification |
| --- | --- | --- | --- | --- |
| `<实际能力>` | `<已读实现、调用位置或匹配版本的库 API>` | `<直接复用 / 组合扩展 / 最小新增>` | `<实际缺口、搜索范围及跳层原因>` | `<对应验收检查>` |

在已批准但缺少这些字段的计划上继续时，只补查当前适用范围并把结论记入现有允许的记录；不要求重写整个计划、迁移历史产物或重新确认未变化的决定。不能证明新模块的具体结构已获批准时，仍须按下一节恢复 Plan 确认，不能编造历史授权。

## Plan Directory Confirmation

新模块的目录确认在 Plan 阶段完成，不延迟到 Execute 或第一个源码文件创建时。Research/Design 可以先调查和提出建议，不另开目录审批；原有设计 Decision Ledger 与设计产物写入授权保持不变。

在现有 frontend plan 开头记录 `Frontend Scope`、`Reference Modules`、`Reuse Decisions` 引用、`Directory Proposal`、`Directory Confirmation` 和 `Confirmation Source`。沿用其 `File Structure`，展示完整项目相对目录树、每个文件的 `[new]` / `[modify]` / `[reuse]`、职责及路由/注册/API 等接入点。small form 由计划本身持有，split form 由已有 context fragment 持有；索引只导航。quick 使用同一内容的内联计划，不创建 `fp-docs/changes/` 产物。

新模块的用户可见 Plan 交付以 **待确认：新模块目录与文件职责（一次性）** 开头，直接展示目录树和职责，不能只给文件链接或笼统询问“是否继续”。可与原有计划批准一次完成，但确认对象必须明确包含展示过的结构。

`Directory Confirmation` 为 `pending | confirmed | not-required`。`confirmed` 必须引用用户看过该具体方案后的明确回复及相应 Plan/Design 位置；已有同一方案的明确批准直接引用，不重复提问。沉默、超时、自动继续模式或泛泛的“开发这个模块”不等于批准目录。`not-required` 说明为何不是新模块。

新模块尚未确认时只调查和完善方案，不创建该模块源码、占位文件或脚手架。已有模块内重构或新增文件不自动触发“新模块首次确认”；仍按已批准计划复用和实施。若需要改变已批准目录、文件职责或增加计划外源码，主 Agent 更新同一 Plan，集中展示差异并确认，再写变化部分；不重问未变化内容。

## Execution And Review

创建每个适用前端源码文件前，核对复用结论与计划路径/职责。发现能力缺口先更新其唯一 owner；需要结构变更时返回 Plan 差异确认，不先建文件再补理由。

SDD controller 在已有 task brief 中传递本契约的插件内路径、复用 owner/结论、目录方案、实际确认来源及允许写入路径。实现者可读获准参考实现，不重复未变化的调查；不能自批新目录、增加计划外文件或自行修改计划，遇到差异返回 controller 集中处理。review package 引用同一 brief 和 owner，不复制复用表。不增加专门的审批子代理，也不改变原有独立审查与串行执行规则。

直接执行的 inline review、SDD task review 和 final review 用实际 diff 对照该记录，检查重复实现、原生 API 被绕过、行为丢失、无关交互和层级偏差；只对本次适用范围提出有证据的问题，不因无关历史记录缺字段而阻塞。

这是 Agent 工作流约束，不是文件写入 hook；记录、静态校验或代理声明都不机械证明用户确认真实发生。沿用现有 UI/E2E、零 mock、证据新鲜度、独立复核和归档要求，不为复用检查额外引入整套 E2E。
