---
name: fp-start
description: 启动并严格执行全流程开发向导（propose → brainstorm → plan → execute）。用于中大型或需要 FeaturePilot 留痕的需求；必须按阶段门禁执行，显式加载 fp-propose、fp-brainstorm、fp-plan、fp-execute 子 skill，生成并核验对应产物，等待用户确认后才能进入下一阶段。
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.
Read `../_shared/artifact-layout.md` once before resolving or producing change artifacts; it is the normative layout, ownership, historical-layout rejection, and validation contract.
---

# FeaturePilot Start

你是一个全流程开发向导，将引导用户完成从需求到实现的完整流程。这个 skill 是强流程，不是普通建议。

**功能描述或 PRD slug：** 用户在命令中提供的需求文本，或 resolved logical PRD content（small `prd.md` 或 split `prd/00-index.md` + fragments）对应的 slug。

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

## Shared canonical artifact resolution

Every phase uses the shared contract's canonical-first Consumer resolution before reading, resuming, validating, or handing off artifacts:

1. Detect both alternatives before reading either: `prd.md` or `prd/00-index.md`; `proposal.md` or `proposal/00-index.md`; `design/backend.md` or `design/backend/00-index.md`; `design/frontend.md` or `design/frontend/00-index.md`; `tasks/plan-backend.md` or `tasks/backend/00-index.md`; and `tasks/plan-frontend.md` or `tasks/frontend/00-index.md`.
2. A Producer writes exactly one canonical form. A Consumer rejects every indexless split, historical path, and dual form as a structural conflict. There is no read-only compatibility. Migration requires explicit approval, one validated canonical form, and deletion of obsolete paths before the phase continues.
3. For split form, the directory `00-index.md` is the sole canonical entry; parse its fragment table and read every listed file in exact manifest order. Reject a missing listed file, duplicate owner, or unindexed fragment; never use a recursive glob, filesystem order, or body link as ordering evidence.
4. For split plans, only manifest rows whose Kind is `tasks` produce `tasks`-kind task-owner files. Every task ID and checkbox has one unique task owner; indexes, context/interface/coverage fragments, and overview contain no executable checkbox.
5. `tasks/00-overview.md` exists exactly when both backend and frontend plans exist. A single-end plan never has an overview. Only for a valid two-end overview, validate cross-end references/cycles and recompute derived progress from the unique owner checkboxes.

Resume and post-write checks record resolved mode, entry, ordered fragments, task owners, and structural conflicts. Producer phases never read or update historical combinations in place; migration needs explicit approval under the shared contract.

---

## 上下文来源规则

读取项目上下文时必须以当前代码为准：
- 不要生成项目索引；读取 `fp-docs/settings/` 中与当前阶段相关的客户配置，并以当前代码作为最终实现事实来源。
- 不要读取历史 `fp-docs/changes/` 或 `fp-docs/archive/` 作为实现背景或设计依据。
- 只允许读取当前 slug 的 resolved logical PRD content、resolved logical proposal content、适用设计和任务 logical content；每项都通过 small file OR split index/fragments 解析后作为本次流程阶段产物。
- 如果需要了解现有实现，必须用 `rg` / `rg --files` 定位真实代码、测试、路由、模型、组件和 API。

---

## Artifact model

FeaturePilot uses an OpenSpec-inspired artifact graph, optimized for low-cost AI development:

```text
prd → proposal → design → tasks → execute → review → archive
```

Dependencies are enablers, not busywork:

- If `/fp-prd` already produced resolved logical PRD content in small or split form, reuse its complete manifest-ordered content instead of re-asking requirements.
- If a change is small and the user confirms `fp-quick`, avoid the full document chain.

---

## Shared start-routing exploration

After the non-empty-input and init-availability checks, load `fp-explore` once before phase 1. `fp-start` remains responsible for canonical artifact resolution, the final active slug, the quick/full choice, and every stage gate.

<!-- fp-explore-invoke
profile: start-routing
objective: Establish current PRD and stage evidence, quick-versus-full routing evidence, implementation boundaries, and the minimum verified context reusable by the next phase for this request.
caller: fp-start
active-slug: <caller-resolved exact slug or empty>
caller-owned-context:
  - current user argument, explicit continuation facts, and already confirmed PRD facts
scope-include:
  - fp-docs/manifest.md when present
  - the exact candidate change directory only when fp-start already resolved one
  - requirement-related source, routes, interfaces, models, components, and tests
scope-exclude:
  - unrelated fp-docs/changes, archive, and history
budget-profile: standard
return-shape: profile-default
external-research: not-authorized
approved-research-boundary:
-->

Consume `start-active-stage`, advisory `start-route-assessment`, and `start-reusable-context`. `fp-explore` may report exact paths and candidate matches but never generates or normalizes the slug. When evidence supports `quick`, explain why and wait for an explicit user choice between `fp-quick` and the full `fp-start` flow. Only after the user chooses quick may `fp-start` load `fp-quick`; otherwise continue to phase 1.

For the full flow, pass `start-reusable-context` to `fp-propose` together with the exploration objective, inspected scope, evidence paths/lines, budget state, relevant observed worktree state, uninspected areas, and separately labeled inferences. When the request resolves to existing PRD content, pass the complete resolved logical PRD content in manifest order. `fp-propose` preserves the resolved proposal form when revising one, or selects small file OR split index/fragments before writing; downstream phases consume the complete resolved logical proposal content. Exploration does not advance a stage and does not count as proposal confirmation.

---

## 阶段 1：理解需求 & 生成变更提案

【必须先加载】`fp-propose` skill，然后完成：
- 复用 fresh `start-reusable-context` 中范围仍匹配、相关工作树内容未变化的 verified facts，并把推断继续作为推断；不要把探索建议当作用户确认。
- 只对未覆盖、已变化或不足以判断 proposal 范围/影响/交付策略的缺口继续探索真实代码、测试、路由、模型、组件和 API。
- Socratic 需求澄清（如需要）
- Generate one resolved proposal form: small `fp-docs/changes/<slug>/proposal.md` or split `fp-docs/changes/<slug>/proposal/00-index.md` plus its manifest-listed fragments.

阶段完成检查：
- Resolve and validate the selected proposal form with the shared contract; confirm its canonical entry and all manifest-listed fragments exist.
- 向用户展示 slug、proposal 路径、Why / What Changes / Impact 摘要。
- 明确询问用户是否确认 proposal。

等待用户确认提案后，输出 `✅ 提案已确认，进入设计阶段`，然后才进入阶段 2。

---

## 阶段 2：技术方案设计

【必须先加载】`fp-brainstorm` skill。一次 `fp-brainstorm` 调用必须持续执行到适用的设计文件写入并核验存在后才返回；Socratic 问答完成或方案确认都不是子 skill 的返回点。其职责包括：
- 基于真实代码定位涉及模块、API、数据模型、组件和约定
- Socratic 架构决策问答（后端 + 前端维度）
- 如果包含前端需求，利用 **本插件内** 的 `fp-figma` skill 分析设计稿，完成精准的前端页面与组件映射设计；**禁止回退到全局 `figma-to-vue` skill**。
- 按实际涉及端生成设计文档：每一端选择 small file 或 split directory 的一个 canonical form；始终生成 `design/00-index.md` 并让它直指所选端入口；没有前端计划时不得生成前端设计入口、分片或空占位文件。

### No second design finalizer

设计生成和写入完全属于当前 `fp-brainstorm` 调用。它返回后，`fp-start` 不得启动第二个设计收尾 Agent 或 Workflow，不得重复扫描代码库、重新推导决策、重写设计或发起多轮交叉验证。外层只能核验已写入文件、从文件提取摘要并请求写入后产物确认；若发现具体缺失或矛盾，返回同一 `fp-brainstorm` 上下文定点补齐或向用户报告阻塞。

### Post-write artifact confirmation

阶段完成检查属于**写入后产物确认**，与 `fp-brainstorm` 内部的写入前内容确认不同：
- 用工具确认 `design/00-index.md` 及实际涉及端解析出的 small file 或 split `00-index.md` 存在；split design 还必须按 manifest order 确认每个 listed fragment 存在。
- 向用户展示关键架构决策、改动模块、前端组件/布局映射（如涉及）。
- 明确询问用户是否确认设计。

等待用户确认设计后，输出 `✅ 设计确认，进入计划阶段`，然后才进入阶段 3。

### Resume boundary

会话中断或用户说“继续”时，以当前 slug 的实际产物和已明确完成的门禁恢复，不重新启动整段设计：

- 适用的 canonical-first resolved design 已存在：只核验 entry/index/ordered fragments、展示摘要并恢复写入后产物确认；除非用户明确要求修改，不得重跑 `fp-brainstorm`。
- 写入前内容确认已经完成但设计文件尚不存在：恢复同一次 `fp-brainstorm` 的第五步，使用已确认内容直接读取模板、写文件并核验；不得重新探索、问答、起草或另建 finalization workflow。
- 无法从当前会话确定写入前内容是否已确认：明确说明缺少哪个门禁，只补问该门禁，不得假设完成或重新做全流程。
- 恢复判断只读取当前 slug 的 resolved logical PRD/proposal content、适用设计 logical content 和当前会话中的明确确认，不读取历史 change/archive，也不创建新的 slug。

### Bookkeeping failure

Task/Todo 更新、进度展示或其他编排记账失败不代表阶段产物失败，也不是重新执行架构工作的依据。报告该失败后，仍以文件存在性和用户明确确认作为唯一阶段事实；不得因记账失败启动摘要、设计收尾、重写或验证 Workflow。若目标文件写入或核验本身失败，则停在当前阶段并报告，禁止进入计划阶段。

---

## 阶段 3：生成执行计划

【必须先加载】`fp-plan` skill，然后完成：
- 基于设计文档生成超级细粒度的 TDD 任务清单。
- 按实际涉及端生成任务计划：后端选择 small `tasks/plan-backend.md` 或 split `tasks/backend/00-index.md`；前端选择 small `tasks/plan-frontend.md` 或 split `tasks/frontend/00-index.md`，每端只能选一种。
- 没有前端计划，或 canonical Consumer 解析不存在已确认的前端设计入口时，不得生成任何前端 plan form 或占位文件；historical layout 直接阻塞。
- 后端/前端任务都按项目实际分层、已确认设计和现有代码依赖顺序生成；只覆盖真实涉及的模型、服务、接口、权限、客户端、状态、路由、页面/组件、样式和验证边界，不固定框架术语或工具名。
- 仅两端都有计划时生成 `tasks/00-overview.md`，只记录两个 canonical entries、跨端依赖/阶段和 derived progress，不复制端内导航或 task checkbox。

阶段完成检查：
- Resolve each end before reading any stable file. For split form, confirm its index and manifest-ordered fragments exist with no unindexed fragment; do not require an overview for a split single-end plan.
- 确认 task IDs/checkbox 只存在于 manifest Kind=`tasks` 的 owner files 且各有一个 unique task owner；only when both ends exist, validate overview cross-end edges/cycles and derived progress against owner checkboxes.
- 检查每个任务都包含 Files、Reasoning、测试/验证步骤；前端任务还必须包含 Template / Script / Style / Visual Checks。
- 向用户展示任务文件路径和任务摘要。
- 明确询问用户是否确认计划。

等待用户确认计划后，输出 `✅ 计划确认，进入执行阶段`，然后才进入阶段 4。

---

## 阶段 4：执行任务

### Execution strategy gate

Before loading either execution skill, stop and ask the user to choose one option. Explain what each option does, when it pauses, and when to use it. You may recommend one with a concrete reason based on task count, complexity, module span, or risk, but a recommendation is not selection; wait for the user's explicit choice. Never infer or auto-select SDD from those factors.

1. **Direct task execution (non-SDD)** — Load `fp-execute` and implement the approved task-owner files directly in the current execution context. It does not create per-task SDD briefs, fresh implementers, review packages, or per-task reviewer agents. Use `automationMode=full` and continue through the task list unless the user explicitly requests per-task confirmation (`automationMode=semi`). Pause only for a blocking plan conflict, an unsafe or unrecoverable validation failure, or a decision only the user can make. Choose this for smaller plans or lower orchestration overhead.
2. **SDD execution** — Load `fp-execute-sdd`. Every task gets a fresh implementer, review package, read-only reviewer, and blocking-finding fix loop, providing stronger isolation, recovery evidence, and quality gates with more orchestration and artifacts. Choose this for medium or large, cross-module, permission/data-sensitive, migration, or UI-contract work.

### SDD continuation mode gate

Ask this gate only after the user explicitly selects SDD. Explain what each option does, when it pauses, and when to use it, then wait for one explicit choice:

1. **Step-confirmation SDD** — Complete one task through implementation, review/fix, checkbox reconciliation, and ledger update; report its evidence and wait for explicit user confirmation before dispatching the next task. Choose this when the user wants to inspect each increment or control every task/commit boundary.
2. **Automatic-continuation SDD** — Run the same complete per-task SDD quality cycle, but after a clean task immediately continue to the next eligible task without asking. Per-task reports are progress updates, not return points. Continue through all tasks and final review; pause only for a genuine blocker, unresolved user decision, plan conflict, blocked implementation, or exhausted fix loop. Choose this for unattended execution without giving up SDD review rigor.

Pass the exact selected continuation mode (`step-confirmation` or `automatic-continuation`) to `fp-execute-sdd`. Do not display this second gate for direct task execution.

执行要求：
- 先读取已确认的任务文件，不得凭阶段 3 的聊天摘要执行。
- 执行前必须做 Pre-flight Plan Review；发现计划冲突先汇总处理，不要边执行边猜；执行者先解析唯一 task-owner files，若存在端内 index 则按 manifest order 读取 fragments；仅两端计划按 `tasks/00-overview.md` 合并跨端顺序。
- 每完成一个任务，只更新 owner file 中的唯一 checkbox，并维护作为恢复证据的 `.fp-execute/progress.md`；ledger 不得成为竞争性的完成状态。
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
