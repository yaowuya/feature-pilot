---
name: fp-execute
description: 按 TDD 流程执行任务，支持半自动与全自动两种模式，并在执行前做计划冲突扫描、用 progress ledger 支持中断恢复
---
## FeaturePilot workspace and information layer

Before choosing output paths, commands, UI/backend rules, or workflow behavior:

1. Treat the target project repository root as the FeaturePilot project root, and look only for `fp-docs/` directly under that root.
2. If `fp-docs/manifest.md` exists, read it first.
3. Do **not** bulk-read all `fp-docs/settings/` or `fp-docs/intel/` files. Read only the smallest relevant subset for the current phase/question.
4. If UI/frontend/prototype behavior is involved and `fp-docs/settings/frontend.md` or `fp-docs/settings/prototype-style.md` exists, read only the relevant sections as required sources.
5. If backend/API/data/security behavior is involved and `fp-docs/settings/backend.md` exists, read only the relevant sections as required sources.
6. Treat generated intel as stale-prone navigation, not proof of current behavior. If intel is stale or broad, verify just-in-time from current source files.
7. Use two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, backend framework, API envelope, or workflow policy in public skills. Customer-specific rules belong in target-project settings.

Compatibility rule: if the project root has no `fp-docs/manifest.md`, continue from current code and existing settings when safe, recommend `/fp-init`, and do not force initialization. If the current phase must write FeaturePilot artifacts, create only the necessary artifact directories under the project-root `fp-docs/`; do not create manifest/settings/intel except through `/fp-init`.
---

# FeaturePilot Execute

你正在执行 `{{tasksPath}}` 中的任务清单。

**自动化模式：`{{automationMode}}`**
**任务状态：{{tasksSummary}}**

## 执行模式

### 半自动模式（semi）
1. 读取 `{{tasksPath}}`，展示所有待完成任务。
2. 读取或初始化 `.fp-execute/progress.md`，确认哪些任务已经完成。
3. 询问用户："从哪个任务开始？"
4. 执行单个任务（TDD 流程）。
5. 任务完成后：更新 `{{tasksPath}}` 中的 checkbox（`[ ]` → `[x]`），并追加 progress ledger。
6. **停下**，等待用户确认："继续下一任务？"

### 全自动模式（full）
1. 读取 `{{tasksPath}}`，获取所有未完成任务。
2. 读取或初始化 `.fp-execute/progress.md`；ledger 已标记完成的任务不得重复执行。
3. 按顺序为每个任务执行（TDD 流程）。
4. 测试失败时：最多重试 3 次。
5. 重试 3 次仍失败：**降级为半自动**，通知用户："任务 N 需要人工介入"，并在 ledger 中记录 BLOCKED。
6. 全部完成后：输出执行报告，提示运行 `fp archive` 或 `/fp-archive`。

## 执行状态目录

执行前在当前变更目录下维护状态目录：

```text
fp-docs/changes/<slug>/.fp-execute/
  progress.md
```

如果当前执行的任务文件不在 `fp-docs/changes/<slug>/tasks/` 下，则在任务文件同级目录创建 `.fp-execute/progress.md`。

`progress.md` 是恢复执行的事实来源，格式建议：

```markdown
# Execution Progress

Plan files:
- tasks/plan-backend.md
- tasks/plan-frontend.md

Base SHA: <执行开始时的 git sha>

## Completed
- Task backend-001: complete (commits <base>..<head>, tests: `<command>`, review: inline clean)

## Blocked
- None

## Notes
- <Minor findings or follow-up notes>
```

规则：
- 启动执行时必须先读取 `progress.md`；不存在则创建。
- ledger 标记 complete 的任务即使 `{{tasksPath}}` checkbox 仍是 `[ ]`，也不要重复执行；先说明不一致并修正 checkbox。
- checkbox 是用户可见进度，ledger 是恢复执行依据；两者冲突时，以 ledger + `git log`/实际文件状态为准，并向用户说明。
- 每完成一个任务，必须在同一次收尾中更新 checkbox、追加 ledger、记录验证命令和 commit 范围。
- 如果任务 BLOCKED，记录阻塞原因、已尝试命令和下一步需要的人工决策。

## Pre-flight Plan Review

执行任何任务前，必须先做一次计划冲突扫描。这个扫描不修改业务代码，只检查任务文件与 proposal/design/项目约束是否自洽。

检查项：
1. **范围一致性**：任务是否只覆盖已确认的 proposal/design 范围；Out of Scope 不得进入执行。
2. **Global Constraints**：如果计划包含 `Global Constraints`，每个任务都不得违反其中的版本、依赖、权限、命名、兼容性、安全和 UI 约束。
3. **Interfaces**：如果任务包含 `Interfaces`，后续任务引用的函数、字段、URL、route、store、组件 props/events 必须由现有代码或前序任务明确产出。
4. **前后端契约**：后端 API、字段名、错误结构、权限 action 与前端 API wrapper/store/page 任务必须一致；不一致时暂停并汇总给用户决策。
5. **TDD 可执行性**：每个任务必须有明确失败测试、失败预期、最小实现、通过验证和提交步骤；泛泛的 `run tests` 或 `实现页面` 视为计划缺陷。
6. **前端骨架完整性**：前端任务必须包含 `Reasoning`、`Template Outline`、`Script Outline`、`Style Outline`、`Visual Checks`；前端任务必须显式遵循项目现有前端框架和脚本/状态管理写法。
7. **占位符扫描**：发现 `TBD`、`TODO`、`按需处理`、`类似上面`、`补充样式`、`Add appropriate error handling` 等占位表达，先修正计划或请求用户确认，不要直接执行。
8. **review 风险前置**：如果计划要求了明显会被代码审查判为缺陷的做法（例如测试没有断言、硬编码敏感配置、跳过权限负向测试），先把问题与对应计划文本一起提交给用户决定哪个约束优先。

如果扫描通过，继续执行；如果发现冲突，必须一次性汇总所有冲突，等待用户决策或先修正计划后再执行。

## TDD 执行流程（每个任务）

1. **读取任务**：从 `{{tasksPath}}` 或具体 plan 文件获取任务描述、`Files`、`Reasoning`、`Interfaces` 和验收标准；如果是前端任务，必须同时读取并严格兑现任务中的 `Template Outline`、`Script Outline`、`Style Outline`、`Visual Checks`。
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
- 若发现 `plan-frontend.md` 缺少必要的模板/脚本/样式骨架、接口契约或视觉检查，先回退补全计划，再继续执行。

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
