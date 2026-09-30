# Technical Design Output Template

Read this file only after every design-required Decision Ledger row is terminal, the user has confirmed each required decision ID, and the user separately authorizes writing the selected approach, reviewed sections, form, exact paths, and any conversion/removal.

Apply the artifact-layout contract already loaded by `fp-brainstorm` as the normative layout contract. Use only sections relevant to the actual backend/frontend scope, and select each end's mutually exclusive form before writing:

- Small: `design/backend.md` or `design/frontend.md` owns the complete end design; do not create the corresponding end directory.
- Split: `design/backend/00-index.md` or `design/frontend/00-index.md` owns the `| Order | File | Kind | Owns |` manifest and links semantically divided numbered fragments; do not create the corresponding end `.md` file.

默认选择 small form。只有预计 small form 超过 500 行或 30,000 字符、用户明确批准 split form，或目标项目设置明确要求 split form 时才拆分；多个 feature、subsystem、page area 或 ownership domain 仅用于已选 split form 的分片边界，不单独触发拆分。

Every index and fragment must stay within both hard fallback limits: **500 lines** and **30,000 characters**. `design/00-index.md` links directly to the form selected for each actual end. The chosen end entry directly owns either the complete small design or the split fragment manifest; no stable summary sits beside a split directory. Do not create a combined root-level `design.md`, legacy `design-backend.md` / `design-frontend.md`, an empty endpoint placeholder, or both forms for one end.

叙述性内容默认使用中文；代码、命令、路径、技术标识符、API 字段以及本模板要求精确匹配的英文 schema 标题保留必要英文。若用户或目标项目设置明确指定其他语言，按共享优先级执行。

Keep `design/00-index.md` metadata-only and use this exact end-map section/table. The optional navigation lines may only link to the listed canonical entries; requirements, contracts, decisions, or design body sections belong in the selected end artifact.

```markdown
# <功能描述> Design Index

## Canonical End Entrypoints

| End | Canonical entrypoint | Mode |
| --- | --- | --- |
| Backend | `design/backend.md` | small |
| Frontend | `design/frontend/00-index.md` | split |
```

```markdown
# <功能描述> — 技术方案设计

## 第一部分：架构决策

### Decision Ledger

| ID | Decision | Source | Blocking | Status | Evidence / explicit confirmation |
| --- | --- | --- | --- | --- | --- |
| D-001 | <架构、接口、数据、安全或视觉决策> | `proposal.md#...` / `<path:line>` / user answer | yes | `user-confirmed` | confirmation record or code evidence |

### 决策 1：[主题]
- **ID**：`D-001`
- **选择**：[用户确认的选择]
- **理由**：[依据]
- **来源**：[proposal 台账 / PRD / 当前代码 / 本轮用户回答]
- **状态**：[终态状态]
- **是否阻塞**：[是 / 否]

（涉及新增复杂度时，在“理由”中说明最简单可行方案为何不足，并给出当前需求、实际变体或性能约束的证据；遵循 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/engineering-quality.md`，不以未来可能复用代替必要性依据。）

### 决策 2：[主题]
- **选择**：[用户确认的选择]
- **理由**：[依据]

### Pre-write Confirmation Evidence

- Covered IDs: `D-001`
- Outstanding blocking decisions: `none`
- Explicit user authorization to write: <本次确认消息或等价明确授权>

## 第二部分：技术方案详述

### 设计范围适用性

| 评审范围 | 要求 | Canonical owner section | 证据或不适用理由 |
| --- | --- | --- | --- |
| 架构主线 | 必填 | `#架构主线` | <proposal、代码或用户确认> |
| 核心对象与职责 | 必填 | `#核心对象与职责` | <对象/模块边界证据> |
| 数据模型 | 条件适用 | <适用时填 owner；否则 `N/A`> | <证据或不适用理由> |
| 状态、并发与执行流程 | 条件适用 | <适用时填 owner；否则 `N/A`> | <证据或不适用理由> |
| 接口、权限与兼容边界 | 条件适用 | <适用时填 owner；否则 `N/A`> | <证据或不适用理由> |
| 前端方案 | 条件适用 | <适用时填 owner；否则 `N/A`> | <证据或不适用理由> |
| 风险、迁移、发布、回滚与监控 | 必填 | `#风险迁移发布回滚与监控` | <具体风险，或有证据的无风险结论> |
| 验证方案 | 必填 | `#验证方案` | <可执行验证依据> |

每个 actual-end 的 detailed owner 都维护自己的适用性 inventory。必填范围必须有 canonical owner 和证据；条件适用范围只有标记为适用时才需要 owner section。条件范围不适用时，owner 写 `N/A`，由 inventory 行持有证据化理由，并省略对应正文。缺少 inventory、必填 owner、适用条件范围的 owner，或证据化不适用理由时，设计不完整。

### 架构主线

（按触发、处理、状态变化、结果和失败收束说明端内主线，并链接跨端 owner；不得只列文件。）

（先说明满足当前验收的最简单可行方案及复用的代码、框架能力；新增抽象、层、组件、依赖、缓存、异步或配置的必要性由相应决策 owner 持有，此处只链接。简化不得削减当前验收、安全、权限隔离或数据一致性。）

### 核心对象与职责

| 对象/模块 | 职责 | 不负责 | 协作对象 | 证据 |
| --- | --- | --- | --- | --- |
| <对象> | <单一职责> | <明确边界> | <依赖或调用方> | <`path:line` / confirmed decision> |

### 后端模块设计

（新建/修改目录与文件职责；仅后端范围。）

### 数据模型

数据模型适用时，字段定义只使用一种 canonical carrier：优先给出接近实现的模型代码；若当前技术栈或设计形态不适合代码，则给出完整字段定义表。另一种表示明确省略，不重复字段事实。

#### 接近实现的模型代码

（适用时展示已确认字段、类型、默认值、`null`/`blank`、关联和 Meta；只形成设计草图，不伪装成已实现代码。所有代码草图同步按共享工程质量契约和项目约定编写 docstring 与必要注释，解释职责、非显然约束和取舍原因，不逐行翻译代码。使用本小节时省略“完整字段定义”。）

#### 完整字段定义

| 字段 | 类型 | 必填/空值 | 默认值 | 关联/约束 | 证据 |
| --- | --- | --- | --- | --- | --- |
| <字段> | <类型> | <规则> | <默认值> | <关联或约束> | <`path:line` / decision> |

（仅在没有接近实现模型代码时使用；使用本表时省略代码小节，不得从字段表反推代码。）

#### 字段与存储取舍

| 字段/数据 | 候选表示 | 最终选择 | 数据体积与读取方式 | 选择理由 | 证据 |
| --- | --- | --- | --- | --- | --- |
| <数据> | <文本/JSON/压缩/关联等> | <选择> | <读写与边界> | <trade-off> | <`path:line` / decision> |

#### 逻辑模型与物理存储

| 逻辑对象 | ORM/Schema 对象 | 物理表或存储 | 主键与关联键 | 证据 |
| --- | --- | --- | --- | --- |
| （对象） | （模型/schema） | （真实表/集合/主题） | （主键、外键或引用） | （`path:line`） |

#### 继承字段与重复存储结论

（列出公共基类、manager、mixin 和继承字段；明确哪些字段不重复声明，以及原因。）

#### 索引、约束与软删除

（列出索引、联合约束、排序、审计、软删除，以及软删除记录是否继续占用唯一约束。）

#### 查询模式与索引映射

| 查询模式 | 过滤/排序/关联字段 | 对应索引或访问路径 | 选择理由 | 证据 |
| --- | --- | --- | --- | --- |
| <查询> | <字段顺序> | <索引/访问路径> | <如何服务该查询及避免冗余> | <`path:line`> |

#### 生命周期数据归属

（说明发布、下线、调试等状态或记录由哪个模型/服务持有。）

#### Migration 影响

（说明 schema 变化、数据迁移、回滚影响，以及纯元数据变化是否产生没有实际数据库收益的 migration。）

#### 技术栈专项结论

（仅记录适用技术栈的专项结论及证据。Django 模型按需覆盖公共 Model/manager/mixin、继承物理表、`verbose_name`、`choices` migration state、字段存储方式、联合索引左前缀和软删除唯一性；非 Django 项目记录对应 ORM/schema 结论，不生成 Django 占位内容。）

### 状态、并发与执行流程

（说明状态入口、状态机、并发控制、执行顺序、异步或外部调用、失败恢复和可观察结果。）

### 接口、权限与兼容边界

（说明路由、方法、请求/响应、错误、资源标识、权限，以及新旧入口的兼容或隔离边界。）

### 前端设计（仅 UI 范围）

#### 页面/视图
（页面路径、入口和导航。）

#### 组件
（复用/新建组件与布局层级。）

#### API 模块
（现有客户端封装位置和契约。）

#### 路由
（路由与权限守卫。）

#### 状态管理
（沿用当前项目的 store/composable/hook/context 或局部状态。）

### 风险、迁移、发布、回滚与监控

| 具体失败场景 | 影响 | 预防或处理 | 发布/回滚/监控安排 | 证据 |
| --- | --- | --- | --- | --- |
| <触发条件与错误结果> | <用户/数据/系统影响> | <已确认处理> | <发布顺序、回滚条件、监控信号> | <design evidence> |

（有意延后项在本节或既有架构决策中唯一记录：简化内容与原因、适用上限、可验证的升级触发条件及升级方向；此处只链接其他 owner，不重复正文。没有延后项时写“无”，不另建 debt 文件、表或状态机。实际代码中的说明遵循共享工程质量契约。）

### 验证方案

| 验证项 | 命令或操作 | 预期结果 | 覆盖的设计结论 | 证据 owner |
| --- | --- | --- | --- | --- |
| <验证> | <可执行命令/人工步骤> | <可观察结果> | <章节/决策> | <本节或引用> |

（覆盖当前验收和已确认简化边界，并安排实现时的注释自审；注释与实现同步完成，不拆成事后补注释任务。）
```

For every actual end, place the Decision Ledger and Pre-write Confirmation Evidence in exactly one unique detailed owner: the small end file or one manifest-listed detail fragment. All design end owners use one globally unique D-NNN sequence. Cross-end decisions have one owner only; the split index records ownership only and does not duplicate decision body content. Each owner's `Covered IDs` lists exactly that owner's persisted IDs. Persisted ledger rows need a unique ID, source, blocking value, terminal status, and confirmation evidence; `needs-user-confirmation` must not persist in final design output.

Before finalizing, replace every template placeholder with concrete evidence. A `placeholder`, `TBD`, `TODO`, `unknown`, generic `user answer`, or sample authorization is invalid in final design output; every evidence entry identifies its decision ID and the applicable source, selection, or user-message reference.

对 `user-confirmed` 行，Evidence 使用 `D-NNN: selected <value>; user message <reference>` 的等价具体记录；单独的 `D-NNN: user answer` 不合格。授权记录也必须引用实际批准的方案、form、路径与用户消息。

For frontend work, place the exact Visual Source / component mapping / Visual Checks sections required by `SKILL.md` together in exactly one detailed owner: `design/frontend.md` in small form or one manifest-listed detail fragment in split form. The split index records ownership only and does not duplicate those sections.

## Document readability self-review

Apply `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md` after resolving each actual end and the complete logical design.

- 按 fragment manifest 顺序检查完整 logical design，同时检查每个 end/fragment 的局部结构。
- 每个 actual-end 都有完整的设计范围适用性 inventory；架构主线、核心对象、风险结论和验证方案始终有唯一 owner，条件范围适用时有 owner、不适用时由 inventory 持有证据化理由。
- 先给出架构主线和已确认决策，再展开数据、接口、状态和前端细节。
- 新增复杂度有当前证据，延后项有适用上限和可验证升级条件；代码草图的 docstring/注释解释职责与原因，并与设计一致。
- 首次出现的必要术语使用直白解释，精确技术标识符保持不变。
- 数据模型的字段定义只由模型代码或完整字段表之一拥有；物理映射、字段/存储取舍、查询/索引映射不重复字段事实。
- Decision Ledger、Pre-write Confirmation Evidence、接口字段和代码保持原 schema 与原语义。
- 纯表达缺陷可依据已确认内容修复；可能改变技术选择时返回对应 `D-NNN`。
