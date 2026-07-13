---
name: fp-execute
description: 按 TDD 流程执行任务，支持半自动与全自动两种模式，并在执行前做计划冲突扫描、用 progress ledger 支持中断恢复
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.
Read `../_shared/artifact-layout.md` once before resolving execution inputs; it is the normative layout and validation contract.
---

# FeaturePilot Execute

你正在执行 `{{tasksPath}}` 中的任务清单。

**自动化模式：`{{automationMode}}`**
**任务状态：{{tasksSummary}}**

## Shared canonical artifact resolution

执行前对所有需求与计划输入做 canonical-first Consumer 解析，不得把 `{{tasksPath}}` 或聊天摘要当事实源：

1. Detect both alternatives before reading either: `prd.md` or `prd/00-index.md`; `proposal.md` or `proposal/00-index.md`; `design/backend.md` or `design/backend/00-index.md`; `design/frontend.md` or `design/frontend/00-index.md`; `tasks/plan-backend.md` or `tasks/backend/00-index.md`; and `tasks/plan-frontend.md` or `tasks/frontend/00-index.md`.
2. A Producer must leave one canonical form. This execution Consumer rejects every indexless split, historical path, and dual form as a structural conflict. There is no read-only compatibility; migration must finish before execution.
3. A split directory's `00-index.md` is its sole canonical entry. Parse its manifest and read every listed fragment in exact manifest order; reject missing/duplicate entries, duplicate owners, or an unindexed fragment. Never infer order from recursive glob, filesystem order, or body links.
4. For split plans, only manifest Kind=`tasks` rows create `tasks`-kind task-owner files. Every stable task ID/checkbox has one unique task owner; context/interface/coverage fragments, indexes, and overview contain no executable checkbox. Reject missing references, duplicate task IDs/checkboxes, and dependency cycles.
5. `tasks/00-overview.md` exists exactly when both backend and frontend plans exist. A single-end plan never has an overview. Validate cross-end edges and recompute derived progress only for a valid two-end overview; otherwise keep the single end's manifest order.

Record the resolved canonical entries, ordered fragments, task owners, and structural conflicts in `progress.md`. Split plan directories, not stable files, are the canonical entries. Only when an end's split directory is absent may the Consumer read its small `tasks/plan-<end>.md`; if both exist, stop before reading either.

## 执行模式

### 半自动模式（semi）
1. 读取解析后的全部 task-owner files，按确定顺序展示所有待完成任务及 owner path。
2. 读取或初始化 `.fp-execute/progress.md`，确认哪些任务已经完成。
3. 询问用户："从哪个任务开始？"
4. 执行单个任务（TDD 流程）。
5. 任务完成后：更新唯一 task-owner file 中的 checkbox（`[ ]` → `[x]`）；只有两端都存在时才从 owner checkboxes 重算 `tasks/00-overview.md` 的 derived progress summary，并追加 progress ledger。
6. **停下**，等待用户确认："继续下一任务？"

### 全自动模式（full）
1. 读取解析后的全部 task-owner files，获取所有未完成任务。
2. 读取或初始化 `.fp-execute/progress.md`；发现 ledger/checkbox 不一致时先按下方规则核验和对账，不得仅凭任一方重复执行或宣告完成。
3. 按顺序为每个任务执行（TDD 流程）。
4. 测试失败时：最多重试 3 次。
5. 重试 3 次仍失败：**降级为半自动**，通知用户："任务 <task-id> 需要人工介入"，并在 ledger 中记录 BLOCKED。
6. 全部任务完成后：先完成下方 final review scope；final review 通过或第 3 次后只剩已记录的非阻断 review debt，才输出执行报告并提示运行 `fp archive` 或 `/fp-archive`。

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
- <tasks/00-overview.md only for a two-end plan>
- <tasks/plan-backend.md OR tasks/backend/00-index.md plus manifest-ordered fragments>
- <tasks/plan-frontend.md OR tasks/frontend/00-index.md plus manifest-ordered fragments>

Base SHA: <执行开始时的 git sha>

## Completed Evidence
- backend-001 (owner: tasks/backend/01-domain.md): checkbox reconciled; commits <base>..<head>; tests `<command>`; review inline clean

## Blocked
- None

## Review Debt
- None

## Notes
- <Minor findings or follow-up notes>

## Events
- <ISO time> review_attempt task=<task-id> attempt=1/3 verdict=PASS critical=0 important=0 minor=0 review=inline
```

规则：
- 启动执行时必须先读取 `progress.md`；不存在则创建。
- task-owner file 中的唯一 checkbox 是计划完成状态；ledger 只记录恢复证据，不能覆盖 checkbox 或单独证明最终完成。
- ledger 显示 complete 但 checkbox 未勾选时，不要盲目重做，也不得直接宣告完成；检查 owner file、`git log`、实际文件和验证结果，确认已完成则补勾 checkbox，未完成则修正 ledger 并继续任务。反向冲突同样先核验。
- 每完成一个任务，必须在同一次收尾中更新 checkbox、追加 ledger、记录验证命令和 commit 范围；仅当两端都存在时从 owner files 重算 overview progress counts。overview 计数与 owner 冲突时直接重算，不把计数当独立状态。
- 如果任务 BLOCKED，记录阻塞原因、已尝试命令和下一步需要的人工决策。
- 每次 review 后追加 `review_attempt` event，记录 task、attempt、verdict、Critical / Important / Minor 数量、review 路径或 `inline` 以及处理结论；未通过点必须逐项保留，不能只记录数量。
- 恢复执行时从 ledger 恢复已有 review attempt；换 finding、reviewer、fixer、commit、会话或中断恢复都不能重置同一任务的计数。

## Resolved requirement and design context

按上述规则读取完整 PRD、proposal 和实际涉及端的 design logical content。Split inputs follow manifest order and include every listed fragment. Missing indexes/files、historical paths 或 dual structures 都在 pre-flight 记录为 structural conflict 并阻塞执行。Execution is a Consumer and never edits requirement/design artifacts or performs migration.

## Pre-flight Plan Review

执行任何任务前，必须先做一次计划冲突扫描。这个扫描不修改业务代码，只检查任务文件与 proposal/design/项目约束是否自洽。

检查项：
1. **范围一致性**：任务是否只覆盖已确认的 proposal/design 范围；Out of Scope 不得进入执行。
2. **Global Constraints**：如果计划包含 `Global Constraints`，每个任务都不得违反其中的版本、依赖、权限、命名、兼容性、安全和 UI 约束。
3. **Interfaces**：如果任务包含 `Interfaces`，后续任务引用的函数、字段、URL、route、store、组件 props/events 必须由现有代码或前序任务明确产出。
4. **Dependencies**：每个 `Depends on` 只能引用存在的 task ID；仅两端计划的跨端依赖必须与 `tasks/00-overview.md` 一致且无环。
5. **前后端契约**：后端 API、字段名、错误结构、权限 action 与前端 API wrapper/store/page 任务必须一致；不一致时暂停并汇总给用户决策。
6. **TDD 可执行性**：每个任务必须有明确失败测试、失败预期、最小实现、通过验证和提交步骤；泛泛的 `run tests` 或 `实现页面` 视为计划缺陷。
7. **前端骨架完整性**：前端任务必须包含 `Reasoning`、`Template Outline`、`Script Outline`、`Style Outline`、`Visual Checks`；前端任务必须显式遵循项目现有前端框架和脚本/状态管理写法。
8. **占位符扫描**：发现 `TBD`、`TODO`、`按需处理`、`类似上面`、`补充样式`、`Add appropriate error handling` 等占位表达，先修正计划或请求用户确认，不要直接执行。
9. **review 风险前置**：如果计划要求了明显会被代码审查判为缺陷的做法（例如测试没有断言、硬编码敏感配置、跳过权限负向测试），先把问题与对应计划文本一起提交给用户决定哪个约束优先。

如果扫描通过，继续执行；如果发现冲突，必须一次性汇总所有冲突，等待用户决策或先修正计划后再执行。

## Review 次数与上限（每个任务）

- 单个任务步骤最多执行 3 次 review，首次 review 计为第 1 次。
- 第 1 或第 2 次 review 未通过时，先把 Critical / Important 未通过点追加到 ledger，再做一次定向修复并进入下一次 review。
- 第 3 次 review 仍未通过时，停止该任务的 review/fix 循环，不得执行第 4 次 review，也不得再自动派生一次未验证的修复。
- 每个 non-pass 在 attempt 1 或 2 都必须追加原始 verdict、findings 和缺失证据，修复代码、验证证据或 review 输入，必要时重新生成 review 上下文，然后让同一 scope 的 attempt 恰好加 1 再 review；`CANNOT VERIFY FROM DIFF`、只有 Minor 却要求修复、没有 severity finding 的 FAIL 以及其他格式错误都适用，不得重复同一 attempt 或猜测 PASS。
- 达到上限后，把所有未通过点、严重级别、review 路径和处理结论记录为 review debt；不影响主流程时允许同步 task-owner checkbox，并按当前 semi/full 模式继续。
- Critical、核心验收不可用、安全/权限/数据风险、阻断下游的外部契约、必需构建或核心测试失败、需要修改批准范围或新增产品/架构/安全决策，均属于主流程阻断；此时记录 `BLOCKED`，不勾选 checkbox，并暂停请求用户决策。
- `CANNOT VERIFY FROM DIFF` 或缺少验证证据按未通过处理；第 3 次时依据缺失证据是否影响主流程进入 review debt 或 `BLOCKED`。
- 从 `progress.md` 恢复已有 review attempt；不得因换 finding、reviewer、fixer、commit、会话或恢复执行而重置计数。

## TDD 执行流程（每个任务）

1. **读取任务**：从解析出的唯一 task-owner file 获取任务描述、`Files`、`Reasoning`、`Depends on`、`Interfaces` 和验收标准；如果是前端任务，必须同时读取并严格兑现任务中的 `Template Outline`、`Script Outline`、`Style Outline`、`Visual Checks`。
2. **确认未完成**：检查 progress ledger 和 checkbox；已完成任务不得重复执行。
3. **写失败测试**：根据验收标准编写测试用例；若该任务不适合自动化测试，必须说明原因并写出替代验证步骤。
4. **运行测试**：验证测试确实失败，并记录命令和关键失败输出。
5. **写最小实现**：让测试通过的最少代码，不顺手重构无关内容。
6. **运行测试**：验证目标测试通过；必要时运行相关 lint/build/类型检查/浏览器视觉验证。
7. **代码审查**：做 inline 自审，检查命名、结构、代码风格、契约一致性、前端视觉约束；按上方 review attempt 规则记录、定向修复或在第 3 次后分类，不得无限重审。
8. **更新 checkbox**：review 通过，或第 3 次后仅剩非阻断 review debt 时，标记任务为完成；存在主流程阻断时保持未勾选。
9. **提交代码**：按任务提交；提交信息与任务交付行为一致。
10. **更新 ledger**：追加任务完成记录，包含 commit 范围、验证命令、结果和残余风险。

## Final Review Scope

- 全部 task-owner checkbox 已按任务 review 结果对账后，加载 `fp-review`，创建独立于各任务的 final review scope；final review scope 最多执行 3 次 review，首次 final review 计为第 1 次。
- 每次 final review attempt 前执行 clean-snapshot checkpoint：先追加待执行 attempt 事件，提交已授权的实现与执行状态产物（task-owner checkbox、有效 overview、ledger 和既有 review 证据），不得混入用户无关修改，并确认 `git status --short` 为空。checkpoint 失败不消耗 review attempt；记录并解决该 preflight blocker 后再运行 review。
- verdict 映射：`PASS` 成功结束；`PASS_WITH_NOTES` 结束 final review scope并记录非阻断 review debt；`FAIL` 是一次未通过；`BLOCKED` 作为主流程阻断立即暂停，直到缺失决定或不安全前置条件解决。
- `BLOCKED` verdict 消耗当前 final review attempt。阻断条件解决后恢复该已完成 attempt：attempt 小于 3 时先完成 clean-snapshot checkpoint，再让 attempt 恰好加 1 后 review；attempt 为 3 时保持阻断，同一 scope 不得再 review。只有用户明确授权开启新的 final review scope 才能重新审查，并把该决定追加到 ledger；不得伪装成第 4 次 review。
- severity 映射：`Critical` 保持 Critical；`High` 映射为 Important 且属于主流程阻断；`Medium` 映射为 Important；`Low` 映射为 Minor。Medium 只有符合上方主流程阻断条件时才阻塞，否则可以记录为 final review debt；Low 单独不阻塞。
- attempt 1 或 2 为 `FAIL` 时，把精确 finding、review 路径和映射结果追加到 ledger，只在当前上下文中修复这些 finding，重跑要求的验证，记录修复证据，将同一 final scope 的 attempt 加 1 后重新运行 `fp-review`。
- attempt 3 仍为 `FAIL` 时停止自动修复：非主流程 finding 逐项进入 final review debt；任何主流程阻断保持 `BLOCKED` 并阻止完成或归档；不得执行第 4 次 final review。
- 恢复执行时从 ledger 恢复已有 final review attempt、最新 review 路径、verdict/severity 映射和未解决 findings；换 finding、reviewer、fix commit、会话、compaction 或 restart 都不能重置 final scope。
- `PASS` 或 `PASS_WITH_NOTES` 后追加结果，并提交 final review report 和 ledger 证据，不再重跑 review；该 evidence-only commit 不得包含实现、task checkbox、overview、需求、设计或计划变更，否则 verdict 已失效，必须按有限 non-pass 转移处理。
- final review 不会仅因再次报告已有 task review debt 就重置或重开对应 task review scope。

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
- review attempts，以及已记录的 review debt 或主流程阻断。
- 是否有未解决风险。

全自动模式全部完成后汇报：
- 已完成任务列表。
- 未执行/跳过任务及原因。
- 所有验证命令及结果。
- progress ledger 路径。
- review debt、主流程阻断及其处理结论。
- 是否建议运行 `/fp-archive`。
