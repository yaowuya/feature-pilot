---
name: fp-plan
description: Use when coordinating FeaturePilot task plan generation after proposal and design files are confirmed, especially when deciding whether to invoke backend and/or frontend planning skills.
---


## FeaturePilot workspace and customer settings

Before choosing output paths, component-library guidance, test commands, or workflow rules, locate the target project's FeaturePilot workspace:

1. Walk upward from the current working directory to find `fp-docs/`.
2. If it does not exist and this phase needs to create artifacts, initialize the minimal tree:
   - `fp-docs/settings/`
   - `fp-docs/changes/`
   - `fp-docs/archive/`
   - `fp-docs/agents/`
3. Read any settings files that exist. Do not create or overwrite customer settings unless the user explicitly asks.

Settings are optional. If a file is missing, fall back to current project code, adjacent implementations, and public defaults only; never invent customer-specific conventions.

Recommended settings file:

- `fp-docs/settings/agent.md` — optional project-specific FeaturePilot rules, including workflow, paths, component library, design system, UI tokens, Figma mapping, and visual review requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, or workflow policy in public skills. Customer-specific rules may be described in optional `fp-docs/settings/agent.md`.

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

用户确认后输出：`✅ 执行计划已确认，进入执行阶段`
