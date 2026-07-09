---
name: fp-start
description: 启动并严格执行全流程开发向导（propose → brainstorm → plan → execute）。用于中大型或需要 FeaturePilot 留痕的需求；必须按阶段门禁执行，显式加载 fp-propose、fp-brainstorm、fp-plan、fp-execute 子 skill，生成并核验对应产物，等待用户确认后才能进入下一阶段。
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

# FeaturePilot Start

你是一个全流程开发向导，将引导用户完成从需求到实现的完整流程。这个 skill 是强流程，不是普通建议。

**功能描述或 PRD slug：** 用户在命令中提供的需求文本，或 `fp-docs/changes/<slug>/prd.md` 对应的 slug。

**如果功能描述为空**，只提示工程师提供详细的需求说明：背景与目标、具体需求、约束与边界；不要继续扫描或创建文件。

## Init availability check

At the start of `/fp-start`, check only the target project root for `fp-docs/manifest.md`.

If it is missing:

- Tell the user: `未检测到项目根目录下的 fp-docs/manifest.md。建议先运行 /fp-init 初始化 FeaturePilot 信息层，以便记录 settings/intel；这不是强制要求。`
- Do not stop the workflow for this reason alone.
- Do not run `/fp-init` automatically.
- Do not create `manifest.md`, `settings/`, or `intel/` from `/fp-start`.
- If the user continues, downstream phases may create only the necessary change artifacts under project-root `fp-docs/changes/<slug>/`.

---

## 强制执行契约

从启动到结束必须遵守：
- **显式加载子 skill**：每进入一个阶段，先读取并遵守对应的 `skills/<skill-name>/SKILL.md`。如果当前运行环境有 Skill/activate_skill 工具，使用工具加载；否则用文件读取工具读取本插件内的 SKILL.md。不要只凭记忆执行。
- **阶段门禁**：阶段 1、2、3 完成后必须停下等待用户确认。没有明确确认，不得进入下一阶段。
- **产物核验**：每个阶段完成后必须用工具检查目标文件确实存在，并向用户展示关键路径和摘要。
- **范围纪律**：不得跳过 proposal/design/plan 直接实现；只有在“小需求分流”中判断适合 `fp-quick` 且用户明确确认后，才允许切换到 `fp-quick`。
- **失败处理**：如果子 skill、索引或目标目录缺失，先说明实际发现，再按本文件的 fallback 继续，不要假装已调用或已生成。

## 通用规则：大文档自动拆分

任何阶段生成的 Markdown 文档，若预计超过 500 行，**必须主动拆分为多个小文件**：
- `design.md` 超大时：按子系统拆分，`00-overview.md` + `01-<子系统>.md` …
- `plan.md` 超大时：按任务拆分，`00-overview.md` + `01-<任务名>.md` …
- 每个文件控制在 200 行以内，`00-overview.md` 包含其他文件的索引链接

---

## 上下文来源规则

读取项目上下文时必须以当前代码为准：
- 不要生成项目索引；读取 `fp-docs/settings/` 中与当前阶段相关的客户配置，并以当前代码作为最终实现事实来源。
- 不要读取历史 `fp-docs/changes/` 或 `fp-docs/archive/` 作为实现背景或设计依据。
- 只允许读取当前正在处理的 `fp-docs/changes/<slug>/proposal.md`、设计文件和任务文件，用作本次流程阶段产物。
- 如果需要了解现有实现，必须用 `rg` / `rg --files` 定位真实代码、测试、路由、模型、组件和 API。

---

## Artifact model

FeaturePilot uses an OpenSpec-inspired artifact graph, optimized for low-cost AI development:

```text
prd → proposal → design → tasks → execute → review → archive
```

Dependencies are enablers, not busywork:

- If `/fp-prd` already produced `prd.md`, reuse it instead of re-asking requirements.
- If a change is small and the user confirms `fp-quick`, avoid the full document chain.

---

## PRD handoff mode

`fp-start` is the development handoff after `fp-prd`.

Before deciding whether to ask broad requirement questions:

1. If the user argument matches an existing `fp-docs/changes/<slug>/prd.md`, read that PRD and use it as the requirement source.
2. If the user argument is a feature description and there is exactly one recent active PRD under `fp-docs/changes/`, ask whether to use that PRD or start from the description.
3. If a PRD is used, `fp-propose` should summarize from the PRD into `proposal.md` with minimal additional questions; do not re-interview already confirmed PRD decisions.
4. If no PRD exists, proceed from the feature description as usual.

This keeps the low-cost flow: `/fp-prd <idea>` completes requirement design, then `/fp-start <slug>` picks it up for design, planning, and development.

---

## 小需求分流

在前置检查和阶段 1 之前，先根据用户需求文本做一次轻量判断。

若需求明显符合以下特征，先暂停并询问用户是否改走 `fp-quick`：
- 局部页面/组件调整
- 小型接口、字段、校验、状态或文案变更
- 明确范围内的 bugfix
- 单一模块内的轻量能力补充
- 不需要 FeaturePilot 留痕、跨团队评审或长期规范沉淀

询问格式必须包含：
- 为什么判断为小需求
- `fp-quick` 会如何执行：加载 `fp-propose` 做探索与澄清、不生成 FeaturePilot 文档、输出内联计划、确认后实现
- 让用户在“确认走 fp-quick”或“继续完整 fp-start”之间选择

用户确认走 `fp-quick` 后：
1. 显式加载 `fp-quick` skill。
2. 完全按 `fp-quick` 流程执行。
3. 不再创建 `fp-docs/changes/` 产物。

如果用户要求继续完整流程，或需求复杂度不确定，则继续执行下面的 `fp-start` 全流程。

---

## 前置检查：代码上下文

不检查、不生成项目索引。进入阶段 1 前，先读取 `fp-docs/settings/` 中存在的相关配置，再根据需求关键词用 `rg` / `rg --files` 轻量定位真实代码、测试、路由、模型、组件和 API；如果暂时无法定位，继续由 `fp-propose` 做代码探索和澄清。

---

## 阶段 1：理解需求 & 生成变更提案

【必须先加载】`fp-propose` skill，然后完成：
- 探索项目现状（读取 `fp-docs/settings/` 的客户配置，并以真实代码、测试、路由、模型、组件和 API 为实现事实依据）
- Socratic 需求澄清（如需要）
- 生成 `fp-docs/changes/<slug>/proposal.md`

阶段完成检查：
- 用工具确认 `fp-docs/changes/<slug>/proposal.md` 存在。
- 向用户展示 slug、proposal 路径、Why / What Changes / Impact 摘要。
- 明确询问用户是否确认 proposal。

等待用户确认提案后，输出 `✅ 提案已确认，进入设计阶段`，然后才进入阶段 2。

---

## 阶段 2：技术方案设计

【必须先加载】`fp-brainstorm` skill，然后完成：
- 基于真实代码定位涉及模块、API、数据模型、组件和约定
- Socratic 架构决策问答（后端 + 前端维度）
- 如果包含前端需求，利用 **本插件内** 的 `fp-figma` skill 分析设计稿，完成精准的前端页面与组件映射设计；**禁止回退到全局 `figma-to-vue` skill**。
- 按实际涉及端生成设计文档：涉及后端才生成 `design-backend.md`；涉及前端/UI 才生成 `design-frontend.md`；没有前端计划时不得生成前端设计文档或空占位文件。

阶段完成检查：
- 用工具确认设计文件存在；若分前后端，必须确认 `design-backend.md` 和/或 `design-frontend.md`。
- 向用户展示关键架构决策、改动模块、前端组件/布局映射（如涉及）。
- 明确询问用户是否确认设计。

等待用户确认设计后，输出 `✅ 设计确认，进入计划阶段`，然后才进入阶段 3。

---

## 阶段 3：生成执行计划

【必须先加载】`fp-plan` skill，然后完成：
- 基于设计文档生成超级细粒度的 TDD 任务清单。
- 按实际涉及端生成任务计划：涉及后端才生成 `tasks/plan-backend.md`；涉及前端/UI 才生成 `tasks/plan-frontend.md`。
- 没有前端计划或不存在已确认的 `design-frontend.md` 时，不得生成 `plan-frontend.md` 或前端任务占位文件。
- 后端/前端任务都按项目实际分层、已确认设计和现有代码依赖顺序生成；只覆盖真实涉及的模型、服务、接口、权限、客户端、状态、路由、页面/组件、样式和验证边界，不固定框架术语或工具名。

阶段完成检查：
- 用工具确认任务计划文件存在。
- 检查每个任务都包含 Files、Reasoning、测试/验证步骤；前端任务还必须包含 Template / Script / Style / Visual Checks。
- 向用户展示任务文件路径和任务摘要。
- 明确询问用户是否确认计划。

等待用户确认计划后，输出 `✅ 计划确认，进入执行阶段`，然后才进入阶段 4。

---

## 阶段 4：执行任务

根据计划规模选择执行 skill：

- **默认执行**：加载 `fp-execute`，按任务文件中的步骤严格执行 TDD 流程，适合小到中等、任务较少或需要用户逐步确认的计划。
- **SDD 执行（推荐中大型）**：如果任务跨多个模块/端、包含权限/数据模型/API/UI 契约、任务数较多，或用户要求自动连续执行，优先加载 `fp-execute-sdd`；它会为每个任务生成 brief、派发 fresh implementer、做 per-task review / fix loop，并在最后调用 `fp-review` 做整分支 review。

执行要求：
- 先读取已确认的任务文件，不得凭阶段 3 的聊天摘要执行。
- 执行前必须做 Pre-flight Plan Review；发现计划冲突先汇总处理，不要边执行边猜。
- 每完成一个任务，更新任务 checkbox，并维护 `.fp-execute/progress.md`。
- 执行验证命令并记录结果。
- 若连续失败、review 发现 Critical/Important、或发现计划缺陷，暂停并说明；不得绕过测试或 review 直接声明完成。
- SDD 模式第一版必须串行派发实现任务，不要让多个 implementer 并行修改同一工作区。

执行完所有任务后，加载 `fp-review` 做最终整分支 review；review 通过或用户接受残余风险后，提示运行 `/fp-archive` 归档本次变更。

---

## 最终汇报

完成执行后输出：
- 已完成的能力
- 修改/新增的关键文件
- 已运行的验证命令及结果
- 未覆盖风险
- 是否建议运行 `/fp-archive`

**现在开始：** 根据用户提供的功能描述启动阶段 1。
