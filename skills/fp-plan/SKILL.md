---
name: fp-plan
description: Use when coordinating FeaturePilot task plan generation after proposal and design files are confirmed, especially when deciding whether to invoke backend and/or frontend planning skills.
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.
---

# FeaturePilot Plan

`fp-plan` 是计划阶段的调度入口。它不直接写后端或前端任务细节；它负责读取已确认的设计产物、按实际范围加载对应子 skill、核验输出文件，并把计划交给用户确认。

## 输入

【立即用工具执行】读取：
- `fp-docs/changes/<slug>/proposal.md`
- 已确认存在的设计文件：
  - `fp-docs/changes/<slug>/design-backend.md`（如存在）
  - `fp-docs/changes/<slug>/design-frontend.md`（如存在）

如果两个设计文件都不存在，停止并说明缺少已确认设计文件，不要生成任务计划。

## Information-layer planning gate

生成任务前：

1. 先读取 `fp-docs/manifest.md`（如存在），再按 manifest 读取与本次后端/前端范围相关的 settings 和 intel。
2. 将会改变接口、权限、数据安全、框架/组件选择或视觉验收的 unresolved Unknown 视为 planning blocker；先请求决策或回到设计阶段，不要把 Unknown 写成任务假设。
3. 只把 intel 当作搜索导航和新鲜度提示；具体文件、契约、命令和当前行为必须回到当前代码或命令输出验证。

## 调度规则

1. 确认 `fp-docs/changes/<slug>/tasks/` 目录存在；不存在则创建。
2. 如果存在 `design-backend.md`：
   - 【必须先加载】`fp-plan-backend` skill。
   - 将 `proposal.md` 和 `design-backend.md` 作为输入。
   - 输出 `fp-docs/changes/<slug>/tasks/plan-backend.md`。
3. 如果存在 `design-frontend.md`：
   - 【必须先加载】`fp-plan-frontend` skill。
   - 将 `proposal.md` 和 `design-frontend.md` 作为输入。
   - 输出 `fp-docs/changes/<slug>/tasks/plan-frontend.md`。
4. 如果不存在某一端设计文件，视为该端不在本次范围内；不要生成空计划或占位文件。

## 完成检查

每个实际生成的计划文件都必须用工具确认存在。

检查摘要必须包含：
- 生成的计划文件路径。
- 后端计划是否使用 `fp-plan-backend`。
- 前端计划是否使用 `fp-plan-frontend`。
- 哪一端被明确跳过，以及跳过原因。

输出计划摘要后，明确询问用户是否确认计划。

写出 `plan-backend.md` / `plan-frontend.md` 只表示计划草案已生成，不等于用户确认。没有用户明确确认前，不得进入 `fp-execute`、`fp-execute-sdd`，也不得修改业务代码。

用户确认后输出：`✅ 执行计划已确认，进入执行阶段`
