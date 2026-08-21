# UI/E2E 原生分阶段契约设计

**状态：** 已确认
**日期：** 2026-08-10
**范围：** FeaturePilot 插件本身，不修改消费者项目的业务代码。

## 1. 背景与目标

FeaturePilot 已有 Figma/source gate、case 级视觉证据、独立审查和最终整分支审查，但 UI 还原、交互实现和 E2E 证据之间还没有统一的强制状态机。现有实现也不能区分静态 UI、交互 UI 与包含真实业务链路的 UI，更无法阻止“截图通过但真实页面流程未验证”的归档。

本设计迁移 SDD-RIPER 的核心思想：设计基线优先、静态视觉先于交互、独立复核、真实浏览器 E2E、证据可追溯、失败不能被人工文字绕过。FeaturePilot 保持插件/规则层架构，不复制 SDD-RIPER 的 Node CLI、固定 Playwright 探针、签名回执或其专用文件结构。

目标：

- 让 `fp-execute` 和 `fp-execute-sdd` 对所有 UI Case 使用同一套分阶段门禁。
- 把 UI Case 的真实前端 E2E 从“可选验证命令”提升为可审查的任务/终审/归档契约。
- 对有交互或业务链路的 Case 禁止所有 mock 数据、mock 接口和伪造状态。
- 以需求、设计、任务、接口和已识别风险为来源，尽可能完整地覆盖 E2E 边界条件，而不是只跑主流程。
- 目标项目没有可用 E2E 工具时，向客户展示浏览器能力选择和影响；只有客户选择并授权后才使用新增本机能力，无法取得可用能力时阻断 required E2E。

非目标：

- 不新增用户可见命令或第二套 UI 工作流。
- 不硬编码项目 URL、包管理器、认证方案、存储路径、全局像素阈值或客户组件库；不自动安装工具、浏览器组件或修改客户项目依赖、lockfile、配置与 CI。
- 不承诺复制 SDD-RIPER 的签名、防重放和固定浏览器探针能力。

## 2. 架构决策

新增 `skills/_shared/ui-e2e-contract.md`，作为唯一的 UI/E2E 阶段、证据和阻断规则来源。它不是新工作流；以下既有入口直接读取并执行它：

| 入口 | 责任 |
| --- | --- |
| `fp-figma` | 记录可信设计源和可执行 Visual Checks。 |
| `fp-plan-frontend` | 为每个 UI Case 选择交付级别，写入视觉和 E2E 覆盖契约。 |
| `fp-execute` | 在当前上下文按阶段实现、复核和验证。 |
| `fp-execute-sdd` | 用 fresh implementer/reviewer 角色执行相同契约。 |
| `fp-final-review` | 回读每个 Case 的阶段和证据，裁决最终结论。 |
| `fp-archive` | 拒绝绕过未完成的核心 UI/E2E Gate。 |

共享文件防止同一规则在六个 skill 中漂移；用户仍然只使用当前的 `fp-execute` 或 `fp-execute-sdd`。

## 3. UI Case 交付级别与状态机

一个已计划的视觉 Case 必须声明唯一的 `UI Delivery Level`：

| 级别 | 适用范围 | 必需终态 |
| --- | --- | --- |
| `static-only` | 仅展示，无用户交互、业务 API、持久化或权限链路。 | `VISUAL_REVIEW_PASS` 加合法 `E2E N/A`。 |
| `interactive` | 有用户交互，但不以本次范围内业务 API/持久化/权限为核心验收。 | `FRONTEND_E2E_PASS`。 |
| `business-flow` | 涉及业务 API、持久化、权限、数据隔离或关键业务状态。 | `FRONTEND_E2E_PASS`，并有真实业务链路证明。 |

状态严格按以下顺序流转：

```text
SOURCE_READY
  -> STATIC_UI_READY
  -> VISUAL_REVIEW_PASS
  -> INTERACTION_READY
  -> FRONTEND_E2E_PASS
  -> FINAL_REVIEW
  -> ARCHIVE
```

`static-only` 在 `VISUAL_REVIEW_PASS` 后必须写入有范围依据的 `E2E N/A`，然后才可视为 Case 完成。其余级别不能使用 `SKIPPED`、聊天结论或人工确认替代 `FRONTEND_E2E_PASS`。

状态转换规则：

1. `SOURCE_READY` 需要批准的设计源、`reference.png`、真实运行时 route/state、viewport 与稳定环境说明。
2. `STATIC_UI_READY` 只能实现静态 UI 表面并采集 `current.png`；此时不得把交互/API/E2E 标为完成。
3. `VISUAL_REVIEW_PASS` 需要只读视觉复核真实 baseline 与真实运行截图。直接执行模式使用一个单独、禁止修改文件的复核阶段；SDD 模式使用 fresh read-only reviewer。
4. 只有视觉通过后才能进入交互/API 实现并标为 `INTERACTION_READY`。
5. `FRONTEND_E2E_PASS` 需要项目真实浏览器 runner 的实际执行产物；`business-flow` 还需要真实 API、真实持久化或真实权限可见结果。

视觉失败只回退到静态 UI 阶段；交互或 E2E 失败只回退到交互/API 阶段，已通过的视觉证据保留但必须仍匹配当前源码和运行状态。

## 4. Case 证据模型

现有 `.fp-execute/visual/<task-id>/<case-id>/manifest.md` 保留来源、截图和交互证据，并补充以下字段：

```markdown
UI Delivery Level: static-only | interactive | business-flow
Gate State: <current state>

## Gate History
| State | Result | Evidence | Reviewed At | Notes |
| --- | --- | --- | --- | --- |

Visual Review: PASS | FAIL | CANNOT_VERIFY
Visual Reviewer Mode: direct-read-only | fresh-reviewer

E2E Applicability: REQUIRED | N/A
E2E N/A Reason: <required only for static-only>
E2E Runner: <project-configured command/tool>
E2E Runtime URL and Route: <real runtime>
E2E Scenarios: <exact scenario names>
E2E Result: PASS | FAIL | CANNOT_VERIFY | N/A
E2E Output: <project-relative report/log/trace/screenshot paths>
E2E Executed At: <ISO-8601>

Core API Mode: real | N/A
Mocked Core API: false | N/A
Data Lifecycle Evidence: <create/read/update/delete or N/A with rationale>
Permission/Persistence Evidence: <observable real result or N/A with rationale>
```

真实 E2E 的详细证据放在 `.fp-execute/e2e/<task-id>/<case-id>/`：至少包含执行日志/报告引用、`coverage-matrix.md`、失败时可用的真实浏览器截图或 trace 引用，以及运行环境说明。证据文件路径必须相对目标项目根目录，且报告中的命令、路由、场景和结果必须可由终审回查。

没有可信 `reference.png` 或真实运行时 `current.png` 时，视觉结果只能是 `CANNOT_VERIFY`。没有实际 runner 输出时，E2E 不能标为 `PASS`。

## 5. 零 Mock 的真实前端 E2E

所有 `interactive` 与 `business-flow` Case 的真实前端 E2E 都适用以下硬规则：

- 禁止 API/network interception、`route.fulfill`、MSW、Cypress stub/intercept、mock module、fixture JSON、硬编码接口数据、前端 store 注入、localStorage 伪造业务数据、数据库 seed 或任何其他伪造业务状态的方式。
- 页面展示、创建、编辑、删除和校验的数据必须来自真实运行前端与真实后端。
- 需要新数据时，场景通过正常页面业务流程创建，并在同一真实链路中验证和清理；不能用直接数据库/API 写入替代页面行为。
- 可以使用已授权的真实测试账号会话状态，但不能伪造用户、权限、角色或业务数据。
- 视觉截图可继续使用稳定、非敏感 fixture；它是视觉证据，不得被复用为 E2E 数据或 E2E PASS 依据。
- 没有真实环境、真实账号或可安全清理的真实数据时，Case 为 `BLOCKED`，不得降级为 mock、截图或人工通过。

异常、失败和重试边界也只能通过真实环境支持的真实业务条件、真实权限条件或真实服务状态触发。不得为了覆盖错误态而拦截、改写或伪造请求/响应；若某个仍在本次范围内的条件无法安全地在真实环境触发，coverage matrix 必须标记为 `blocked` 并记录原因，不能把环境不可达伪装成 `N/A`。

`business-flow` 的结果额外要求 `Core API Mode: real`、`Mocked Core API: false`，并记录对应的真实持久化、权限或数据隔离可见结果。

## 6. E2E 覆盖矩阵

每个 `interactive` / `business-flow` Case 必须在 `.fp-execute/e2e/<task-id>/<case-id>/coverage-matrix.md` 中建立覆盖矩阵。矩阵从 PRD、proposal、frontend design、任务接口、Visual Checks、API/路由契约和已识别风险生成，而不是从单一 happy path 反推。

以下类别逐项标为 `covered`、`N/A` 或 `blocked`；`N/A` 必须说明不适用的范围依据：

- 正常流程及关键分支；
- 表单校验、空值、边界值、非法输入与重复提交；
- 加载、空态、失败态、重试和网络/服务异常后的可见行为；
- 未授权、角色差异、权限拒绝与数据隔离；
- 创建、编辑、删除、刷新/跳转后的持久化结果；
- 并发、顺序依赖、取消/返回、重复操作等状态转换；
- 本次变更相关的 API 响应边界、分页、筛选、排序和兼容行为。

“尽可能完整”不以固定的场景数量衡量：每个从当前范围可观察、可达的条件都必须映射到真实 E2E 场景与实际证据，或有可审查的 `N/A`/`BLOCKED` 原因。缺少核心边界场景不能成为 review debt。

## 7. Browser 能力选择

当某个需要 E2E 的目标前端项目没有可用 browser/E2E runner 时，FeaturePilot 进入 `BROWSER_CAPABILITY_GATE`：

1. 按顺序探测并复用 existing project runner、已安装 browser extension 和本机已有 `playwright-cli`。
2. 三者都不可用时，向客户报告发现结果、Node.js 前提、浏览器下载/网络/磁盘影响和项目文件影响，并让客户选择安装 browser extension、全局 local CLI 或不安装。
3. local CLI 安装时展示精确命令；客户自行执行，或明确授权 FeaturePilot 仅执行该命令一次。
4. 不自动修改目标项目依赖、lockfile、浏览器配置、CI 或测试栈，也不安装额外浏览器组件；已有配置只能复用。
5. 记录客户选择、授权、实际命令、版本、可用性验证和后续 runner 证据；无可用且获批准能力时为 `BLOCKED`，不能回退到 mock。

## 8. 两种执行模式

`fp-execute` 和 `fp-execute-sdd` 使用完全相同的字段、状态机、零 mock 规则和完成条件。

| 环节 | `fp-execute` | `fp-execute-sdd` |
| --- | --- | --- |
| 静态实现 | 当前执行上下文实现。 | fresh implementer 实现。 |
| 视觉复核 | 单独的 read-only pass，复核期间禁止改文件。 | fresh read-only visual reviewer。 |
| E2E | 执行者以项目 runner 执行并保存证据。 | 独立 E2E verifier 只运行/审查 E2E，不修改 UI。 |
| 失败修复 | 回退到责任阶段并重跑。 | 保留现有 fixer/reviewer 机制，回退到责任阶段。 |

每个 Case 最多三轮复核/修复，沿用当前 SDD 的三次上限。第三次后，核心视觉缺口、真实 E2E 缺口、零 mock 违规和核心边界场景缺失都保持 `BLOCKED`，不得降为 review debt。

## 9. 最终审查与归档

`fp-final-review` 对每个已计划 UI Case 回读视觉 manifest、E2E evidence 和覆盖矩阵：

- `static-only` 必须有 `VISUAL_REVIEW_PASS` 和可验证的 `E2E N/A Reason`。
- `interactive` 必须有真实前端 `FRONTEND_E2E_PASS`。
- `business-flow` 还必须证明 `Core API Mode: real`、`Mocked Core API: false` 与相应的持久化/权限结果。
- 缺失可信 source/runtime、runner 输出、核心边界覆盖或出现任何 mock 数据/接口，结论不得为 `PASS` 或 `PASS_WITH_NOTES`。

`fp-archive` 在移动变更前重复检查上述核心门禁。用户确认可以继续当前的普通未完成任务归档提示，但不能绕过任何未完成 UI/E2E 核心门禁；仅已完成 Case 或合法 `static-only/N/A` Case 可进入归档。

客户选择的 local CLI、browser extension 或既有 runner 及其相关证据必须出现在计划 File Structure、任务 file scope、执行证据和终审 Scope Matrix 中；不得把客户项目依赖、lockfile、浏览器配置或 CI 变更作为自动步骤。

## 10. 插件验证与文档

新增 `scripts/test-ui-e2e-contract.ps1`，并接入 `scripts/validate-plugin.ps1`。测试不依赖消费者业务项目，重点验证分发 skill 的契约文本和跨文件一致性。

测试覆盖：

- 共享规则被所有六个入口读取；
- 三种交付级别、严格状态顺序和合法 `N/A`；
- `fp-execute` 与 `fp-execute-sdd` 的同等硬门禁；
- `BROWSER_CAPABILITY_GATE` 的已有 runner / extension / local CLI 选择、客户授权、无静默安装和无项目依赖/配置改写边界；
- 零 mock 规则及对 route/intercept/fixture/stub/mock/seed/store 注入等的拒绝；
- E2E 覆盖矩阵必须逐类判定、不能只接受主流程；
- `fp-final-review` 与 `fp-archive` 对缺失核心 E2E 的阻断；
- 反向变异测试：删除字段、允许 `SKIPPED`、把 mock 改为允许、移除终审/归档 gate，都必须让测试失败。

扩展 `test-figma-evidence-contract.ps1` 和 `test-final-review-contract.ps1`，使现有视觉来源/运行时证据规则与新阶段契约一致。同步更新 README、根 `AGENTS.md`、相关 commands 与模板，说明默认与 SDD 执行模式的相同 UI/E2E 闭环。

## 11. 验收标准

实现完成后，以下事实必须同时成立：

1. 计划可为每个视觉 Case 选择唯一交付级别，并生成必需证据/覆盖矩阵路径。
2. 两个执行 skill 都不能在视觉通过前完成交互/E2E，也不能在 required E2E 缺失时完成任务。
3. 缺失 runner 时会进入客户选择的浏览器能力门禁；没有可用且获批准能力时留下准确阻断证据，不修改目标项目依赖或配置。
4. 任何 mock 数据或 mock 接口使真实 E2E Case 失效。
5. 终审和归档都无法把未通过的核心 UI/E2E Case 变成可归档状态。
6. `scripts/validate-plugin.ps1` 和新增/扩展的契约测试通过，且变异样例被正确拒绝。
