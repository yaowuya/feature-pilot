---
name: fp-plan-backend
description: Use when generating backend FeaturePilot task plans from the resolved logical proposal and canonical backend design representation, especially for server-side model, service, API, serializer, IAM, provider, URL, and test changes.
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.

Read `../_shared/artifact-layout.md` before resolving or writing the backend plan. Its mutually exclusive canonical forms, semantic split selection, 500 lines / 30,000 characters hard limits, manifest schema, ownership rules, and Producer/Consumer compatibility boundaries are mandatory.
---

# FeaturePilot Backend Plan

后端计划 skill 必须自包含。不要依赖外部 skill 目录、外部 `writing-plans` 文件或本机绝对路径。

本 skill 已融合 `writing-plans` 的核心方法：先锁定文件结构，再拆成小粒度 TDD 任务；每个任务必须给出精确文件、测试代码、运行命令、最小实现、通过验证和提交步骤。

## Canonical input resolution

Resolve the proposal representation before reading either form: detect `proposal.md` and `proposal/00-index.md`, reject dual or malformed state as a structural conflict, then read the small file or every split fragment in complete manifest order.

Resolve the backend design representation before reading either form: detect `design/backend.md` and `design/backend/00-index.md`, reject dual or malformed state as a structural conflict, then read the small file or every split fragment in complete manifest order. If the parent supplied resolved logical content, canonical entrypoint, mode, and ordered fragment paths, verify them against disk before using them. Never discover split content from a stable-file body link.

## Historical layout blocker

检测到 `fp-docs/changes/<slug>/design-backend.md` 时，立即作为 structural conflict 阻塞，不读取其正文。必须先明确批准迁移到 `design/backend.md` 或 `design/backend/00-index.md`、删除旧路径并验证，之后才能规划。

## 输入

【立即用工具执行】读取：
- `fp-docs/manifest.md`（如存在，作为信息层入口）
- 已按 XOR 规则解析的 proposal logical content、canonical entrypoint、mode 与 ordered fragment paths
- 按 canonical-first 规则解析的完整后端设计
- `fp-docs/settings/backend.md`（如存在，作为后端/API/数据/安全约束）
- manifest 列出的、与本次后端范围直接相关的 intel（仅作导航，当前事实回到代码验证）

不要读取前端设计来生成后端任务。

## 输出

写入前检查 small file、split index 和 historical paths；任何 historical/dual structure 都先作为 structural conflict 阻塞，迁移后再选择下列一种 mutually exclusive canonical form：

```text
Small form: fp-docs/changes/<slug>/tasks/plan-backend.md
Split form: fp-docs/changes/<slug>/tasks/backend/00-index.md plus indexed fragments
```

The two forms are mutually exclusive. Small form keeps the complete logical plan and all executable tasks in `plan-backend.md`; it does not create `tasks/backend/`. Split form writes only the end directory and must not create or retain `plan-backend.md`. Select split form directly when independently readable task groups or ownership domains exist, or when any proposed Markdown file exceeds 500 lines or 30,000 characters. Every produced file must stay within both hard limits.

For split form, use semantic task-kind fragments rather than mechanically cutting a monolith:

```text
fp-docs/changes/<slug>/tasks/backend/00-index.md
fp-docs/changes/<slug>/tasks/backend/01-context.md
fp-docs/changes/<slug>/tasks/backend/05-interfaces.md
fp-docs/changes/<slug>/tasks/backend/10-<topic>-tasks.md
fp-docs/changes/<slug>/tasks/backend/90-coverage.md
```

Read `../fp-plan/task-layout-template.md` when splitting and use its authoritative `Order / File / Kind / Owns` manifest. The `context` fragment uniquely owns the header, goal, architecture, tech stack, Global Constraints, and file structure. The `interface` fragment uniquely owns the Backend Interface Ledger. One or more `tasks` fragments uniquely own the logical TDD task bodies. The `coverage` fragment uniquely owns the Coverage Matrix. The index contains navigation and ownership metadata only; every sibling Markdown fragment is listed exactly once.

Each executable task checkbox exists exactly once: in `plan-backend.md` for small form or one `tasks`-kind fragment for split form. Split `00-index.md`, `context`, `interface`, and `coverage` fragments contain no executable checkbox. When converting an existing canonical form, transfer all unique content, validate the new representation, and remove the obsolete form. Never produce the historical stable-file-plus-directory combination.

Use stable task IDs `backend-001`, `backend-002`, ... across the whole backend plan. Numbering continues across fragments and never resets per file. Return every `(task ID, owner file, dependencies)` tuple to `fp-plan` for whole-graph validation and derived totals. Only when both ends exist may `fp-plan` write `tasks/00-overview.md`, and it publishes only cross-end edges/stages and derived totals; this end-specific skill never writes the overview.

不要写入其它计划目录。不要输出 subagent/inline execution 选择；`fp-start` 会在用户确认计划后进入 `fp-execute`。

## Scope Check

生成计划前先检查已解析的完整 logical proposal 和完整后端设计：

- 如果后端设计覆盖多个互相独立的子系统，先提示应拆成多个后端计划；不要把无关子系统塞进一个任务链。
- 每个计划必须能独立产出可测试的软件增量。
- 如果某个需求点只在 proposal 中出现、未在 design-backend 中设计，标记为设计缺口，不要自行补设计后继续生成任务。

## File Structure

定义任务前，先生成“文件结构规划”，列出将创建或修改的业务文件及职责。Small form 把它写入 `plan-backend.md`；split form 把它写入唯一的 `context` fragment。

要求：

- 文件职责必须清晰，避免一个任务同时堆模型、服务、接口、权限、测试等无关改动。
- 按现有项目模式组织文件；不要为了计划而引入全新分层。
- 如果现有文件过大且本次必须修改，可在计划中加入小范围拆分任务，但必须说明拆分服务于当前需求。
- 文件结构规划决定后续任务拆分；后续任务不得凭空新增未规划文件，除非在任务中先说明原因并更新规划。

## Plan Header

写入前读取 `plan-template.md`，使用其中的 logical header。Small form 把 header 与 `Global Constraints` 写入 `plan-backend.md`；split form 把它们写入唯一的 `context` fragment。`Global Constraints` 必须从 resolved logical proposal、完整后端设计、项目约束和当前代码中提取精确值：
- 版本/框架/依赖限制。
- API 返回结构、错误码、权限 action、命名约定。
- 数据迁移、兼容性、安全、性能或审计要求。
- 明确禁止的做法，例如不得新增第三方依赖、不得跳过权限负向测试。

这些约束默认约束每个任务，后续任务不得与之冲突。不要在推导任务期间提前加载模板。

## Task Granularity

每个任务必须足够小，通常 2-5 分钟可完成。任务边界以“能独立经历一次测试与 review”为准：脚手架、配置、文档和注册步骤应并入真正需要它们的交付任务；只有当 reviewer 可以合理地批准一个任务、拒绝另一个任务时，才拆成两个任务。

一个任务内的每个步骤只能做一件事：

- 写失败测试。
- 运行测试确认失败。
- 写最小实现。
- 运行测试确认通过。
- 提交本任务变更。

超过该粒度时继续拆分。

## Backend Task Order

按真实设计范围和项目现有分层拆任务。常见边界包括：

```text
Data/schema changes → business/service logic → request/response contracts → API handlers/routes → permissions/integration points → tests
```

但不要机械生成不存在的层：

- 没有模型变更，不要创建 Model 任务。
- 没有序列化器变更，不要创建 Serializer 任务。
- 权限、provider、注册入口、异步任务、数据迁移等边界必须独立成可验证任务。

## Backend Interface Ledger

生成任务前必须先建立后端接口账本；small form 的 owner 是 `plan-backend.md`，split form 的唯一 owner 是 `interface` fragment。每个任务的 `**Interfaces:**` 必须与账本一致。

接口包括：
- Python 函数、类、方法、构造参数、返回值。
- service 层输入/输出对象和错误类型。
- serializer/schema 字段、校验规则、只读/必填规则。
- ViewSet/API action、HTTP method、URL name、request body、query params、response shape、status code。
- URL/router 注册名称。
- IAM/permission action mapping。
- provider / registry / hook 的注册 key、调用签名和生命周期。
- 异步任务、定时任务、外部服务 client 的调用契约。

格式使用 `plan-template.md` 的 Backend Interface Ledger。

后续任务只能消费账本中已经存在的接口、现有代码中的接口，或本任务明确创建的接口；不得临时发明未声明的函数、字段、action、route 或 provider key。

## Task Format

每个任务必须使用 `plan-template.md` 的 Task 格式，完整保留唯一 task-level `- [ ] **Task backend-NNN: ...**` marker、Files、Reasoning、Depends on、Interfaces、失败测试、预期失败、最小实现、通过验证和 Commit 五步。子步骤不得使用 checkbox 语法。

## No Placeholders

计划中禁止出现以下失败写法：

- `TBD`、`TODO`、`implement later`、`fill in details`
- `后续实现`、`按需处理`、`类似上面`
- `Add appropriate error handling`
- `Write tests for the above`
- 只描述“做什么”，不给测试代码、实现片段或精确命令
- 后续任务引用前面没有定义、也不是现有代码里的函数、类、字段、路径

如果代码片段过长，仍需给出关键函数、类、字段和调用结构；不能用一句“按设计实现”替代。

## Backend Boundary Checks

后端计划必须显式覆盖这些边界中实际涉及的部分：

- 数据模型和迁移。
- service/business logic。
- serializer/schema。
- ViewSet/API action。
- URL/router。
- IAM/permission/action mapping。
- resource provider / registry / hooks。
- 异步任务、定时任务、外部服务调用。
- 单元测试、集成测试、导入验证、权限负向测试。

不涉及的边界不要生成空任务。

## Coverage Matrix

后端 logical plan 必须在任务列表之后包含覆盖矩阵，用来证明 proposal 和 design-backend 的后端范围都被任务覆盖。Small form 的 owner 是 `plan-backend.md`；split form 的唯一 owner 是 `coverage` fragment。

格式使用 `plan-template.md` 的 Coverage Matrix。

规则：
- 每个 proposal 后端需求点必须映射到至少一个任务，或明确标记为 `Design gap — not planned`。
- 每个 design-backend 设计点必须映射到至少一个任务和一个验证命令。
- `Backend Boundary Checks` 中实际涉及的边界必须在矩阵中出现。
- 不涉及的边界不要写占位行。

## Self-Review

写入所选 canonical backend plan 后，必须自审并直接修正问题：

1. **Spec coverage:** 逐条检查 proposal 和 design-backend 的后端范围点，确认每一点都能指向 Coverage Matrix 中的具体任务；未设计点只能标记为设计缺口。
2. **Global constraints coverage:** 确认所有跨任务硬约束都进入 `Global Constraints`，且没有任务违反这些约束。
3. **Interface ledger consistency:** 确认 `Backend Interface Ledger`、每个任务的 `Consumes` / `Produces` / `Contract checks`、代码片段、测试代码和后续消费者使用同一组函数、类、字段、URL、权限 action、provider key。
4. **Placeholder scan:** 搜索 No Placeholders 中的红旗词。发现后直接改掉。
5. **Type consistency:** 后续任务使用的函数、类、字段、路径必须和前序任务或现有代码一致。
6. **Task independence:** 每个任务必须能独立执行、独立验证、独立提交，并且小到值得一次独立 review。
7. **Backend boundary coverage:** 检查模型/迁移、service、serializer/schema、ViewSet/API、URL/router、IAM/permission、provider/registry/hooks、异步任务、外部服务调用中实际涉及的部分都有任务和验证。
8. **Command validity:** 测试命令必须是项目中可执行的真实命令，不要写泛泛的 `run tests`。
9. **Split integrity:** 如果存在 `tasks/backend/00-index.md`，确认 `plan-backend.md` 不存在，manifest 使用 `Order / File / Kind / Owns`，列出的每个 fragment 都存在、目录中没有 unindexed fragment、顺序确定、没有依赖 glob 顺序；每个 executable task checkbox exactly once 且只在 `tasks`-kind fragment，index/context/interface/coverage 不含 task checkbox。
10. **Stable identity:** `backend-NNN` IDs 在全部 owner files 中唯一、跨 fragment 连续且依赖只引用存在的 task ID；开始执行后的计划修订不得静默移动或重编号任务。

若选择 small form，反向确认 `tasks/backend/` 不存在。无论哪种 form，确认每个文件不超过 500 lines 和 30,000 characters，并且单端规划不会创建 `tasks/00-overview.md`。

自审完成后，向 `fp-plan` 返回唯一 canonical entrypoint、manifest/owner files（split form）、任务摘要、Coverage Matrix 摘要和设计缺口列表（如有）。
