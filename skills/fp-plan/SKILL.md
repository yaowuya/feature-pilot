---
name: fp-plan
description: Use when coordinating FeaturePilot task plan generation after proposal and design files are confirmed, especially when deciding whether to invoke backend and/or frontend planning skills.
---
## FeaturePilot workspace and information layer

If any anchored plugin resource is missing or unreadable, stop, report the exact resource and an incomplete FeaturePilot installation/cache, and never search the consumer repository for `skills/**` or continue without it.

Read `${CLAUDE_SKILL_DIR}/../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.

Read `${CLAUDE_SKILL_DIR}/../_shared/artifact-layout.md` before resolving or writing task plans. Its mutually exclusive canonical forms, semantic split rules, 500 lines / 30,000 characters hard limits, manifest schema, ownership rules, and Producer/Consumer compatibility boundaries are mandatory.
---

# FeaturePilot Plan

`fp-plan` 是计划阶段的调度入口。它不直接写后端或前端任务细节；它负责读取已确认的设计产物、按实际范围加载对应子 skill、核验输出文件，并把计划交给用户确认。

## Canonical input resolution

Resolve the proposal representation before reading either form: detect `proposal.md` and `proposal/00-index.md` first, reject both-present or indexless-directory state as a structural conflict, then read the small file or every split fragment in complete manifest order. The resolved logical proposal is that one file or the ordered concatenation of all indexed fragments; body links, recursive glob order, and filename guesses are not inputs.

For each design end, detect `design/<end>.md` and `design/<end>/00-index.md` before reading either form. Reject dual, indexless, missing-fragment, unindexed-fragment, duplicate-owner, invalid-manifest, or historical paths as a structural conflict. Small mode reads the end file; split mode reads every fragment in complete manifest order. Whenever any design end exists, require `design/00-index.md` and verify that its exact `End / Canonical entrypoint / Mode` rows match every and only the actual end representations. Do not infer fragments from body links.

## Historical layout blocker

检测到变更根目录旧 `design-backend.md` 或 `design-frontend.md` 时，立即作为 structural conflict 阻塞；不得读取其正文或把它当作可用设计输入。明确批准的迁移必须先把必要内容转入唯一 canonical end form、删除旧路径并通过验证，之后才能重新开始规划。

## Canonical task layout

Each planned end selects exactly one mutually exclusive canonical form before writing:

- Backend: small `tasks/plan-backend.md` **or** split `tasks/backend/00-index.md` plus its indexed fragments.
- Frontend: small `tasks/plan-frontend.md` **or** split `tasks/frontend/00-index.md` plus its indexed fragments.

The split form does not create or retain the corresponding `tasks/plan-<end>.md`. For each planned end, default to the small form while the complete end-local plan is expected to fit within 500 lines and 30,000 characters. Select split form only when the small plan is expected to exceed either limit, the user explicitly approves split form, or an applicable target-project setting explicitly requires it. Task groups, page areas, and ownership domains define fragments only after split form has been selected. Every split file remains within both hard limits. A canonical-form conversion transfers all unique content, validates the result, and removes the obsolete form so Producer output never leaves a file-plus-directory pair.

Each split end uses the authoritative `| Order | File | Kind | Owns |` manifest. Context, interface ledger/contracts, executable task groups, and coverage have unique `context`, `interface`, `tasks`, and `coverage` fragment owners. Indexes contain navigation and ownership metadata only.

Every executable task checkbox must appear exactly once in either the small plan or one `tasks`-kind fragment, using a stable `backend-NNN` or `frontend-NNN` ID that continues across fragments. Index, context, interface, coverage, and overview files contain no executable task checkboxes.

Read `${CLAUDE_SKILL_DIR}/task-layout-template.md` only after the planned ends and their selected forms are known, and only when an end is split or both ends exist. `tasks/00-overview.md` exists exactly when both backend and frontend plans exist. A single-end plan never has an overview, whether its form is small or split. The overview owns only canonical end entrypoints, cross-end dependency edges or execution stages, and progress totals derived from the unique owner checkboxes; it does not copy end-local navigation, constraints, interfaces, coverage, task bodies, or checkboxes.

## 输入

【立即用工具执行】读取：
- 按上述 XOR 规则解析的 proposal logical content、canonical entrypoint、mode 与 ordered fragment paths。
- 按上述 canonical-first 规则解析的已确认设计产物。

如果没有任何端的 canonical 设计产物，停止并说明缺少已确认设计文件，不要生成任务计划。Historical entrypoint 不是可用输入状态。

## Information-layer planning gate

生成任务前：

1. 先读取 `fp-docs/manifest.md`（如存在），再按 manifest 读取与本次后端/前端范围相关的 settings 和 intel。
2. 将会改变接口、权限、数据安全、框架/组件选择或视觉验收的 unresolved Unknown 视为 planning blocker；先请求决策或回到设计阶段，不要把 Unknown 写成任务假设。
3. 只把 intel 当作搜索导航和新鲜度提示；具体文件、契约、命令和当前行为必须回到当前代码或命令输出验证。

## 调度规则

1. 确认 `fp-docs/changes/<slug>/tasks/` 目录存在；不存在则创建。
2. 如果解析到后端设计入口：
   - 【必须先加载】`fp-plan-backend` skill。
   - 传入已解析的 proposal 与后端 design logical content、canonical entrypoint、mode 和 ordered fragment paths。
   - 选择并仅输出 `fp-docs/changes/<slug>/tasks/plan-backend.md`，或 `fp-docs/changes/<slug>/tasks/backend/00-index.md` 及其 manifest 列出的 fragments。
3. 如果解析到前端设计入口：
   - 【必须先加载】`fp-plan-frontend` skill。
   - 传入已解析的 proposal 与前端 design logical content、canonical entrypoint、mode 和 ordered fragment paths。
   - 选择并仅输出 `fp-docs/changes/<slug>/tasks/plan-frontend.md`，或 `fp-docs/changes/<slug>/tasks/frontend/00-index.md` 及其 manifest 列出的 fragments。
4. 如果不存在某一端设计文件，视为该端不在本次范围内；不要生成空计划或占位文件。
5. 仅当两端都生成计划时，使用 `${CLAUDE_SKILL_DIR}/task-layout-template.md` 写入 `tasks/00-overview.md`；记录真实的跨端依赖边或执行阶段。任何单端计划都不生成该文件。

Pass the resolved logical proposal content, resolved logical design content, canonical entrypoint, mode, and ordered fragment paths to each child planner. Children must verify this resolution against disk before planning and must not reopen a guessed stable path first.

## 完成检查

每个实际生成的计划文件都必须用工具确认存在。对每端同时检查 small file 与 split index，Producer 输出必须恰好存在一种。若 `tasks/backend/00-index.md` 或 `tasks/frontend/00-index.md` 存在，必须按 `Order / File / Kind / Owns` manifest 确认每个 fragment 存在、每个 sibling Markdown fragment 恰好列出一次、每个详细内容 owner 唯一；缺失或未被 index 列出的 fragment 必须阻塞，不得依赖 body link、glob 或文件系统顺序。

把所有任务标记解析为 `(task ID, owner file)` 后验证：task ID 和 checkbox 各出现一次；拆分端只有 `tasks`-kind fragments 可以拥有 task checkbox，端内 `00-index.md`、context/interface/coverage fragments 与 `tasks/00-overview.md` 均不含 task checkbox；全部端内依赖与 overview 跨端依赖引用存在的 task ID 且无环；overview progress totals 与 owner checkbox 的派生计数一致。单端存在 overview 或双端缺少 overview 都必须阻塞。

检查摘要必须包含：
- 生成的计划文件路径。
- 后端计划是否使用 `fp-plan-backend`。
- 前端计划是否使用 `fp-plan-frontend`。
- 哪一端被明确跳过，以及跳过原因。
- 每个 task ID 的唯一 owner file，以及跨端依赖摘要。

输出计划摘要后，明确询问用户是否确认计划。

写出每端所选的 canonical small file 或 split directory 只表示计划草案已生成，不等于用户确认。没有用户明确确认前，不得进入 `fp-execute`、`fp-execute-sdd`，也不得修改业务代码。

用户确认后输出：`✅ 执行计划已确认，进入执行阶段`

默认推荐使用 `fp-execute` 在当前上下文直接完成计划，并使用 `automationMode=full` 连续执行；用户明确要求逐任务确认时改用 `automationMode=semi`。只有用户明确要求 `fp-execute-sdd`、SDD 或多代理隔离执行时，才把执行入口交给 `fp-execute-sdd`，不要根据任务数量、模块跨度或风险自动切换。
