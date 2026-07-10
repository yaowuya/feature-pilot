---
name: fp-execute
description: 按 TDD 流程执行任务，支持半自动与全自动两种模式，并在执行前做计划冲突扫描、用 progress ledger 支持中断恢复
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.
---

# FeaturePilot Execute

你正在执行 `{{tasksPath}}` 中的任务清单。

**自动化模式：`{{automationMode}}`**
**任务状态：{{tasksSummary}}**

## Canonical task plan resolution

执行前先把任务计划解析成有序的 task-owner files，不得把 `{{tasksPath}}` 当成唯一文件：

1. 读取存在的稳定入口 `tasks/plan-backend.md`、`tasks/plan-frontend.md`，以及 `tasks/00-overview.md`（如存在）。overview 只提供跨端顺序、依赖、覆盖和进度汇总，不拥有 checkbox。
2. 对每一端检查 `tasks/backend/00-index.md` 或 `tasks/frontend/00-index.md` 是否存在。存在时，稳定入口和 index 都是摘要/约束，按 index 明示顺序读取全部 numbered fragments；这些 fragments 才是该端 task-owner files。不存在时，该端稳定入口本身是 task-owner file。
3. 缺失 indexed fragment、目录中存在 unindexed fragment、summary/index 出现 task checkbox、task ID 重复或同一 checkbox 出现多次时，立即阻塞，不执行任务。不得依赖稳定入口是否碰巧链接分片、recursive glob 或文件系统顺序。
4. `tasks/00-overview.md` 存在时按其跨端顺序执行，并确认它覆盖每个 `backend-NNN` / `frontend-NNN`。旧的小计划没有 overview 时，保留各稳定文件中的既有顺序；跨端依赖不明确则在 pre-flight 阶段阻塞。
5. 每个任务的 ID、checkbox 和 owner path 组成唯一身份。完成时只更新 owner file 中那一行，不在 overview、index、稳定摘要或 ledger 中复制 checkbox。

## 执行模式

### 半自动模式（semi）
1. 读取解析后的全部 task-owner files，按确定顺序展示所有待完成任务及 owner path。
2. 读取或初始化 `.fp-execute/progress.md`，确认哪些任务已经完成。
3. 询问用户："从哪个任务开始？"
4. 执行单个任务（TDD 流程）。
5. 任务完成后：更新唯一 task-owner file 中的 checkbox（`[ ]` → `[x]`），从 owner checkboxes 重算 `tasks/00-overview.md` 的 derived progress summary（如存在），并追加 progress ledger。
6. **停下**，等待用户确认："继续下一任务？"

### 全自动模式（full）
1. 读取解析后的全部 task-owner files，获取所有未完成任务。
2. 读取或初始化 `.fp-execute/progress.md`；发现 ledger/checkbox 不一致时先按下方规则核验和对账，不得仅凭任一方重复执行或宣告完成。
3. 按顺序为每个任务执行（TDD 流程）。
4. 测试失败时：最多重试 3 次。
5. 重试 3 次仍失败：**降级为半自动**，通知用户："任务 <task-id> 需要人工介入"，并在 ledger 中记录 BLOCKED。
6. 全部完成后：输出执行报告，提示运行 `fp archive` 或 `/fp-archive`。

## 执行状态目录

执行前在当前变更目录下维护状态目录：

```text
fp-docs/changes/<slug>/.fp-execute/
  progress.md
```

如果当前执行的任务文件不在 `fp-docs/changes/<slug>/tasks/` 下，则在任务文件同级目录创建 `.fp-execute/progress.md`。

`progress.md` 是 append-only 恢复与证据日志，not a second completion authority，格式建议：

```markdown
# Execution Progress

Plan files:
- tasks/00-overview.md
- tasks/plan-backend.md
- tasks/backend/00-index.md
- tasks/backend/01-domain.md
- tasks/plan-frontend.md

Base SHA: <执行开始时的 git sha>

## Completed Evidence
- backend-001 (owner: tasks/backend/01-domain.md): checkbox reconciled; commits <base>..<head>; tests `<command>`; review inline clean

## Blocked
- None

## Notes
- <Minor findings or follow-up notes>
```

规则：
- 启动执行时必须先读取 `progress.md`；不存在则创建。
- task-owner file 中的唯一 checkbox 是计划完成状态；ledger 只记录恢复证据，不能覆盖 checkbox 或单独证明最终完成。
- ledger 显示 complete 但 checkbox 未勾选时，不要盲目重做，也不得直接宣告完成；检查 owner file、`git log`、实际文件和验证结果，确认已完成则补勾 checkbox，未完成则修正 ledger 并继续任务。反向冲突同样先核验。
- 每完成一个任务，必须在同一次收尾中更新 checkbox、从 owner files 重算 overview progress counts（如存在）、追加 ledger、记录验证命令和 commit 范围。overview 计数与 owner 冲突时直接重算，不把计数当独立状态。
- 如果任务 BLOCKED，记录阻塞原因、已尝试命令和下一步需要的人工决策。

## Canonical design layout

执行前若 `fp-docs/changes/<slug>/design/00-index.md` 存在，读取它、实际涉及端的稳定入口，以及端内索引列出的全部分片；索引引用缺失是执行阻塞。设计是任务和 proposal 一致性扫描的事实来源，不能只依赖聊天摘要。

## Legacy read compatibility

某一端 canonical entrypoint 不存在时，可只读回退到根目录旧 `design-backend.md` / `design-frontend.md`。不得由执行阶段创建或更新任何设计文件；canonical 与 legacy 同时存在时以 canonical 为准。

## Pre-flight Plan Review

执行任何任务前，必须先做一次计划冲突扫描。这个扫描不修改业务代码，只检查任务文件与 proposal/design/项目约束是否自洽。

检查项：
1. **范围一致性**：任务是否只覆盖已确认的 proposal/design 范围；Out of Scope 不得进入执行。
2. **Global Constraints**：如果计划包含 `Global Constraints`，每个任务都不得违反其中的版本、依赖、权限、命名、兼容性、安全和 UI 约束。
3. **Interfaces**：如果任务包含 `Interfaces`，后续任务引用的函数、字段、URL、route、store、组件 props/events 必须由现有代码或前序任务明确产出。
4. **Dependencies**：每个 `Depends on` 只能引用存在的 task ID；跨端依赖必须与 `tasks/00-overview.md` 一致且无环。
5. **前后端契约**：后端 API、字段名、错误结构、权限 action 与前端 API wrapper/store/page 任务必须一致；不一致时暂停并汇总给用户决策。
6. **TDD 可执行性**：每个任务必须有明确失败测试、失败预期、最小实现、通过验证和提交步骤；泛泛的 `run tests` 或 `实现页面` 视为计划缺陷。
7. **前端骨架完整性**：前端任务必须包含 `Reasoning`、`Template Outline`、`Script Outline`、`Style Outline`、`Visual Checks`；前端任务必须显式遵循项目现有前端框架和脚本/状态管理写法。
8. **占位符扫描**：发现 `TBD`、`TODO`、`按需处理`、`类似上面`、`补充样式`、`Add appropriate error handling` 等占位表达，先修正计划或请求用户确认，不要直接执行。
9. **review 风险前置**：如果计划要求了明显会被代码审查判为缺陷的做法（例如测试没有断言、硬编码敏感配置、跳过权限负向测试），先把问题与对应计划文本一起提交给用户决定哪个约束优先。

如果扫描通过，继续执行；如果发现冲突，必须一次性汇总所有冲突，等待用户决策或先修正计划后再执行。

## TDD 执行流程（每个任务）

1. **读取任务**：从解析出的唯一 task-owner file 获取任务描述、`Files`、`Reasoning`、`Depends on`、`Interfaces` 和验收标准；如果是前端任务，必须同时读取并严格兑现任务中的 `Template Outline`、`Script Outline`、`Style Outline`、`Visual Checks`。
2. **确认未完成**：检查 progress ledger 和 checkbox；已完成任务不得重复执行。
3. **写失败测试**：根据验收标准编写测试用例；若该任务不适合自动化测试，必须说明原因并写出替代验证步骤。
4. **运行测试**：验证测试确实失败，并记录命令和关键失败输出。
5. **写最小实现**：让测试通过的最少代码，不顺手重构无关内容。
6. **运行测试**：验证目标测试通过；必要时运行相关 lint/build/类型检查/浏览器视觉验证。
7. **代码审查**：做 inline 自审，检查命名、结构、代码风格、契约一致性、前端视觉约束；发现 Critical/Important 问题必须先修复。
8. **更新 checkbox**：标记任务为完成。
9. **提交代码**：按任务提交；提交信息与任务交付行为一致。
10. **更新 ledger**：追加任务完成记录，包含 commit 范围、验证命令、结果和残余风险。

## 项目约束

从项目 CLAUDE.md 提取的关键约束会在此处注入。遵守项目的代码风格、测试框架和提交规范。

## 前端任务补充约束

- 不能跳过 `template` 骨架直接堆 CSS。
- 不能忽略 `Reasoning` 中约定的组件映射与布局策略。
- 不能忽略 `Interfaces` 中约定的 API/store/route/props/events 契约。
- 不能在执行阶段擅自偏离 `Visual Checks` 中约定的设计稿对齐目标。
- 前端组件必须遵循项目现有框架、脚本/状态管理和样式写法；若任务生成了与项目惯例不一致的组件结构，必须立即改回项目既有模式。
- 若发现任一 frontend task-owner file 缺少必要的模板/脚本/样式骨架、接口契约或视觉检查，先回退补全计划，再继续执行。

## 完成汇报

每个任务完成后，在半自动模式下汇报：
- 任务编号和标题。
- 修改/新增文件。
- 测试或验证命令及结果。
- commit sha 或 commit 范围。
- ledger 路径。
- 是否有未解决风险。

全自动模式全部完成后汇报：
- 已完成任务列表。
- 未执行/跳过任务及原因。
- 所有验证命令及结果。
- progress ledger 路径。
- 是否建议运行 `/fp-archive`。
