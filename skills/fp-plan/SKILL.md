---
name: fp-plan
description: Use when coordinating FeaturePilot task plan generation after proposal and design files are confirmed, especially when deciding whether to invoke backend and/or frontend planning skills.
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.
---

# FeaturePilot Plan

`fp-plan` 是计划阶段的调度入口。它不直接写后端或前端任务细节；它负责读取已确认的设计产物、按实际范围加载对应子 skill、核验输出文件，并把计划交给用户确认。

## Canonical design layout

### Conditional canonical index read

`fp-docs/changes/<slug>/design/00-index.md` **存在时**，先读取它，再按其索引读取实际存在的 `design/backend.md`、`design/frontend.md` 及其链接的全部分片。稳定入口存在但某个索引分片缺失时停止并报告，不得从不完整设计生成计划。canonical 总索引不存在时不要报错，继续执行下方 legacy fallback。

## Legacy read compatibility

只有某一端 canonical entrypoint 不存在时，才可回退读取变更根目录旧 `design-backend.md` 或 `design-frontend.md`。旧文件仅用于读取已有活跃变更；本阶段不得创建、更新或把旧路径写入新计划契约。

## Canonical task layout

Small plans keep executable tasks in stable files `tasks/plan-backend.md` and `tasks/plan-frontend.md`. If an end-specific plan exceeds 500 lines, the stable file becomes concise constraints/summary/navigation/coverage and executable tasks move to `tasks/backend/00-index.md` plus numbered backend fragments, or `tasks/frontend/00-index.md` plus numbered frontend fragments. Fragments should stay <=200 lines where practical.

Every executable task checkbox must appear exactly once in its task-owner file, using a stable `backend-NNN` or `frontend-NNN` ID that continues across fragments. Stable entrypoints for split ends and all indexes contain no executable task checkboxes.

Read `task-layout-template.md` only after both subplans are known. Create `tasks/00-overview.md` when both ends are planned or either end is split. It is the change-level source for cross-end execution order, dependencies, coverage, and progress roll-up, but it must not copy task checkboxes. For one small single-end plan, do not create an overview, fragment directory, or placeholder.

## 输入

【立即用工具执行】读取：
- `fp-docs/changes/<slug>/proposal.md`
- 按上述 canonical-first 规则解析的已确认设计产物。

如果 canonical 和 legacy 两种布局都没有任何端的设计产物，停止并说明缺少已确认设计文件，不要生成任务计划。

## Information-layer planning gate

生成任务前：

1. 先读取 `fp-docs/manifest.md`（如存在），再按 manifest 读取与本次后端/前端范围相关的 settings 和 intel。
2. 将会改变接口、权限、数据安全、框架/组件选择或视觉验收的 unresolved Unknown 视为 planning blocker；先请求决策或回到设计阶段，不要把 Unknown 写成任务假设。
3. 只把 intel 当作搜索导航和新鲜度提示；具体文件、契约、命令和当前行为必须回到当前代码或命令输出验证。

## 调度规则

1. 确认 `fp-docs/changes/<slug>/tasks/` 目录存在；不存在则创建。
2. 如果解析到后端设计入口：
   - 【必须先加载】`fp-plan-backend` skill。
   - 将 `proposal.md`、后端稳定入口及其索引的全部分片作为输入。
   - 输出 `fp-docs/changes/<slug>/tasks/plan-backend.md`；若拆分，另输出 `fp-docs/changes/<slug>/tasks/backend/00-index.md` 和其列出的编号 fragments。
3. 如果解析到前端设计入口：
   - 【必须先加载】`fp-plan-frontend` skill。
   - 将 `proposal.md`、前端稳定入口及其索引的全部分片作为输入。
   - 输出 `fp-docs/changes/<slug>/tasks/plan-frontend.md`；若拆分，另输出 `fp-docs/changes/<slug>/tasks/frontend/00-index.md` 和其列出的编号 fragments。
4. 如果不存在某一端设计文件，视为该端不在本次范围内；不要生成空计划或占位文件。
5. 两端都生成计划，或任一端生成分片时，使用 `task-layout-template.md` 写入 `tasks/00-overview.md`；把 backend/frontend task IDs 按真实依赖合并为一个确定顺序。单端小计划不生成该文件。

## 完成检查

每个实际生成的计划文件都必须用工具确认存在。若 `tasks/backend/00-index.md` 或 `tasks/frontend/00-index.md` 存在，还必须按 index 列表确认每个 fragment 存在，且 `tasks/00-overview.md` 存在；缺失或未被 index 列出的 fragment 必须阻塞，不得依赖 entrypoint 链接或 glob 顺序。

把所有任务标记解析为 `(task ID, owner file)` 后验证：task ID 和 checkbox 各出现一次；拆分端的稳定入口、`tasks/00-overview.md`、端内 `00-index.md` 均不含 task checkbox；跨端 overview 顺序覆盖全部 task IDs 且依赖无环；overview progress summary 与 owner checkbox 的派生计数一致。

检查摘要必须包含：
- 生成的计划文件路径。
- 后端计划是否使用 `fp-plan-backend`。
- 前端计划是否使用 `fp-plan-frontend`。
- 哪一端被明确跳过，以及跳过原因。
- 每个 task ID 的唯一 owner file，以及跨端依赖摘要。

输出计划摘要后，明确询问用户是否确认计划。

写出 `plan-backend.md` / `plan-frontend.md` 只表示计划草案已生成，不等于用户确认。没有用户明确确认前，不得进入 `fp-execute`、`fp-execute-sdd`，也不得修改业务代码。

用户确认后输出：`✅ 执行计划已确认，进入执行阶段`
