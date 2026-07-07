---
description: 启动全流程开发向导 (propose → brainstorm → plan → execute)
---

# FeaturePilot Start


## FeaturePilot workspace

执行命令前，先遵守目标项目的 `fp-docs` 契约：如需生成产物，使用 `fp-docs/changes/`、`fp-docs/archive/`；如存在 `fp-docs/settings/agent.md`，先读取与当前阶段相关的配置。不要创建或覆盖客户 settings，除非用户明确要求。

**功能描述或 PRD slug：** $ARGUMENTS

你是一个全流程开发向导，将引导用户完成从需求到实现的完整流程。这个命令必须按 `fp-start` skill 的阶段门禁执行。

**如果功能描述为空**，请提示工程师提供详细的需求说明：背景与目标、具体需求、约束与边界；不要继续扫描或创建文件。

## 强制执行规则

- 立即加载并遵守本插件内 `fp-start` skill：`skills/fp-start/SKILL.md`。
- 每个阶段进入前，显式加载对应子 skill：`fp-propose`、`fp-brainstorm`、`fp-plan`、`fp-execute`。
- 阶段 1、2、3 完成后必须停下等待用户确认；没有明确确认，不得进入下一阶段。
- 每个阶段完成后必须用工具核验目标文件存在，并展示路径与摘要。
- 启动后先判断是否为小需求；若适合 `fp-quick`，必须先征求用户确认。用户确认后加载 `fp-quick` 并按它执行；用户不确认则继续完整 `fp-start`。
- 除小需求分流且用户确认的情况外，不得跳过 proposal/design/plan 直接实现。

**通用规则：大文档自动拆分**

任何阶段生成的 Markdown 文档，若预计超过 500 行，**必须主动拆分为多个小文件**：
- `design.md` 超大时：按子系统拆分，`00-overview.md` + `01-<子系统>.md` …
- `plan.md` 超大时：按任务拆分，`00-overview.md` + `01-<任务名>.md` …
- 每个文件控制在 200 行以内，`00-overview.md` 包含其他文件的索引链接

---

## 上下文来源规则

读取项目上下文时必须以当前代码为准，同时读取 `fp-docs/settings/` 中与当前阶段相关的客户配置：
- 不要生成项目索引；`fp-docs/settings/` 是客户配置来源，当前代码是实现事实来源。
- 不要读取历史 `fp-docs/changes/` 或 `fp-docs/archive/` 作为实现背景或设计依据。
- 只允许读取当前正在处理的 `fp-docs/changes/<slug>/proposal.md`、设计文件和任务文件，用作本次流程阶段产物。
- 如果需要了解现有实现，必须用 `rg` / `rg --files` 定位真实代码、测试、路由、模型、组件和 API。

---

## PRD 接续模式

如果 `$ARGUMENTS` 是 `fp-docs/changes/<slug>/prd.md` 对应的 slug，或能定位到唯一相关 PRD，必须先读取 PRD，并把它作为需求来源交给 `fp-start` / `fp-propose`，避免重复做需求访谈。

---

## 小需求分流

在前置检查和阶段 1 之前，先根据「$ARGUMENTS」判断是否明显属于小需求：
- 局部页面/组件调整
- 小型接口、字段、校验、状态或文案变更
- 明确范围内的 bugfix
- 单一模块内的轻量能力补充
- 不需要 FeaturePilot 留痕、跨团队评审或长期规范沉淀

如果判断适合小需求，先向用户说明原因，并询问是否确认改走 `fp-quick`。

用户确认后：
- 显式加载 `fp-quick` skill。
- 由 `fp-quick` 加载 `fp-propose` 进行探索与澄清。
- 不创建 `fp-docs/changes/` 产物。

用户不确认或复杂度不确定时，继续完整 `fp-start`。

---

## 前置检查：代码上下文

不检查、不生成项目索引。进入阶段 1 前，先读取 `fp-docs/settings/` 中存在的相关配置，再根据需求关键词用 `rg` / `rg --files` 轻量定位真实代码、测试、路由、模型、组件和 API；如果暂时无法定位，继续由 `fp-propose` 做代码探索和澄清。

---

## 阶段 1：理解需求 & 生成变更提案

显式加载 `fp-propose` skill，完成：
- 探索项目现状（读取 `fp-docs/settings/` 的客户配置，并以真实代码、测试、路由、模型、组件和 API 为实现事实依据）
- Socratic 需求澄清（如需要）
- 生成 `fp-docs/changes/<slug>/proposal.md`

用工具确认 proposal 文件存在，展示摘要并等待用户确认。确认后输出 `✅ 提案已确认，进入设计阶段`。

---

## 阶段 2：技术方案设计

显式加载 `fp-brainstorm` skill，完成：
- 基于真实代码定位涉及模块、API、数据模型、组件和约定
- Socratic 架构决策问答（后端 + 前端维度）
- 如果包含前端需求，利用 **本插件内** 的 `fp-figma` skill 分析设计稿，完成精准的前端页面与组件映射设计；**禁止回退到全局 `figma-to-vue` skill**。
- 按实际涉及端生成设计文档：涉及后端才生成 `design-backend.md`；涉及前端/UI 才生成 `design-frontend.md`；没有前端计划时不得生成前端设计文档或空占位文件。

用工具确认设计文件存在，展示摘要并等待用户确认。确认后输出 `✅ 设计确认，进入计划阶段`。

---

## 阶段 3：生成执行计划

显式加载 `fp-plan` skill，完成：
- 基于设计文档生成超级细粒度的 TDD 任务清单
- 按实际涉及端生成任务计划：涉及后端才生成 `tasks/plan-backend.md`；涉及前端/UI 才生成 `tasks/plan-frontend.md`
- 没有前端计划或不存在已确认的 `design-frontend.md` 时，不得生成 `plan-frontend.md` 或前端任务占位文件
- 后端任务按 Model → Service → ViewSet → Serializer → URL → Tests 顺序执行；前端任务按 API 模块 → Store → 路由 → 页面/组件 → ESLint 顺序执行，并严格兑现 `design-frontend.md` 中的设计稿映射

用工具确认任务计划文件存在，展示摘要并等待用户确认。确认后输出 `✅ 计划确认，进入执行阶段`。

---

## 阶段 4：执行任务

根据计划规模选择执行 skill：
- 默认加载 `fp-execute`，适合小到中等计划。
- 中大型、跨端、权限/数据/API/UI 契约复杂或需要连续自动执行时，优先加载 `fp-execute-sdd`；每任务 fresh implementer + task review + fix loop，最后加载 `fp-review` 做整分支 review。

执行前必须做 Pre-flight Plan Review；每完成任务更新 checkbox 和 `.fp-execute/progress.md`。若连续失败、review 发现 Critical/Important、或发现计划缺陷，暂停并说明，不得绕过测试或 review。

执行完所有任务并通过最终 review 后提示：运行 `/fp:archive` 归档本次变更。

---

**现在开始：** 根据功能描述「$ARGUMENTS」启动阶段 1。
