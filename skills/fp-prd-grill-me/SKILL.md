---
name: fp-prd-grill-me
description: Use only after fp-prd has been explicitly selected, when PRD-blocking product decisions still need confirmation.
---

## FeaturePilot workspace and information layer

插件资源锚定、`${CLAUDE_PLUGIN_ROOT}` 路径映射与缺失即停止规则见 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md`；不要在消费者项目中搜索 `skills/**`。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` when classifying PRD form, semantic split boundaries, existing-artifact conflicts, or conversions. This dependency skill does not independently broaden `fp-prd` discovery.


# FeaturePilot PRD Grill Me

This skill 内联通用 grill-me 原则并专用于 PRD 访谈。

## First Step

通用 grill-me 原则：持续追问直到达成共享理解，沿决策树逐支解决依赖；能用代码探索回答的问题先探索代码；推荐只是推荐，不是用户确认。本 skill 在此之上增加 PRD 专属决策门禁、输出期望与更严格的问答协议。

### PRD override for code exploration

通用 grill-me 原则中的"能用代码探索回答的问题先探索代码"只适用于实现事实与既有产品约束。它**不**适用于产品决策。

Code exploration may answer:

- which modules, menus, enums, routes, permissions, APIs, or components already exist;
- what current behavior and constraints are;
- which neighboring patterns can inform options.

Code exploration may **not** decide:

- target users and business value;
- MVP vs out-of-scope boundaries;
- whether an existing module should be split, merged, or replaced by a new one;
- risk acceptance, permission policy, audit needs, or operational fallback expectations;
- lifecycle, version, or reference semantics;
- acceptance criteria, success metrics, or prototype expectations.

`prd-product-surface-facts` may be described as current product behavior after fact conversion; `prd-implementation-evidence` stays an implementation fact, never a product answer; `prd-product-decisions` are always user-owned. A high-confidence code fact is not a high-confidence product decision.

Unless the user provided a complete PRD or explicitly authorized assumption-based generation, run Batch Confirmation Mode: Phase 1 batch-review Bucket A/B decisions, then Phase 2 ask Bucket C questions sequentially one at a time with a 3-5 question target. Do not self-answer Bucket C.

## Business-first analysis

在 PRD-first 和 Prototype-first 中，先整理下面的业务骨架，再讨论页面布局与文案。把结果放入已有 A/B 审阅和 C 提问，不增加独立访谈轮次或业务分析文件；只追问会改变本次范围、行为、风险或验收的缺口。

1. **现状流程**：谁在什么条件下发起，业务对象经过哪些角色/系统，怎样结束、由谁看到结果；区分用户陈述、当前代码证据与未知。新业务明确“无现有流程”，不虚构历史行为。
2. **目标流程**：说明从触发、准入、处理、角色交接到最终业务结果的完整链路，而非只列点击、跳转和提示。
3. **变化与影响**：对照现状说明入口、流程、规则、状态或信息展示的变化，以及涉及的用户端、运营/审核后台、外部系统的变更/不变/不适用及依据。MVP 与不做范围随本项确认。
4. **状态与规则**：对实际有生命周期的业务对象，逐项确认业务状态、触发条件、执行角色、准入/校验规则、下一状态或退出条件、允许操作及结果可见位置。Loading/empty/error 等页面状态只表达呈现，不能替代业务状态。
5. **异常闭环**：按实际链路确认失败、拒绝、中断或结果未知时的业务状态、补救责任、重试/取消边界和结果反馈；异步、重复操作或跨系统回执存在时，再追问超时、重复提交和迟到结果的处置。
6. **页面映射**：最后将已确认的流程、规则和状态映射到页面入口、按钮可用性、提示及后台操作；无页面的需求写不适用。

**不改结论的证据门禁：** “后台无需修改”或“沿用现有能力”须逐项关联当前代码/测试证据或用户明确提供的业务依据，说明相关字段、状态、权限、审核/处理流程和结果回显为何仍满足目标流程。找不到依据就标记未知：先在 Minimal Fact Exploration 预算内核实；影响范围、风险或验收时进入 Bucket C，不能用“估计不改”排除后台，也不能自行决定要改后台。明确授权的假设仍标为假设，不得伪装成已验证事实。

**按复杂度收敛：** 简单文案、筛选或纯展示变化可用几条事实说明业务流程/状态不变及理由，不强制增加状态机或后台工作。完整输入直接复用已确认内容；部分输入只补缺口。保留产品层的规则、责任和可观察结果，数据表、接口签名、队列/事务实现留给后续技术设计。

完成标准是拿掉页面描述后仍能解释业务如何开始、流转、结束及异常如何收束；不能闭环的高影响决策保持未决并进入 C 提问。

## Business-object and relation phases

在业务骨架之后、任何页面或组件问题之前，按顺序完成下列建模。结果落入同一套 A/B 审阅与 C 提问，不新增产物。只有需求确实涉及多个业务对象时才展开，并且下列每一项都是 Bucket C，必须由用户确认。

1. **对象清单**：列出需求中的核心名词，逐项判定是独立业务对象、页面字段，还是当前实现的内部概念。只做字段、不承载身份与生命周期的名词不构成业务对象。
2. **关系消歧**：每对可能相关的对象先确认关系类型——归属、绑定、引用、筛选条件、数据来源、使用限制或无关系。关系类型确认前不得询问一对一、一对多或多对多，也不得把 UI 顺序、现有字段或外键暗示成业务关系。
3. **生命周期与引用语义**：对适用对象确认创建/草稿/启用/停用/归档等状态、各状态可编辑与可被引用的范围、引用方绑定对象本身还是具体版本、新版本是否自动生效、旧版本失效后既有引用如何处理、历史结果是否冻结。
4. **内容模型审阅**：当需求围绕可配置内容、模板、字段或区块展开时，先确认目标内容模型是否复用当前区块、是否拆分、是否合并、是否新增当前实现不存在的区块、默认显隐、数据范围由谁配置、是否随版本冻结。当前代码枚举不作为目标内容模型。

**版本触发器**：出现下列任一模式时自动执行第 3 项——可配置对象被其他对象引用；配置修改可能影响历史结果；同一配置需长期复用；已发布内容不可随意变化；消费方需要稳定、可追溯结果。

**中性问法**：询问两个对象的关系时，不得预设存在持久关系，先给出关系类型选项：

```markdown
对象 A 在这里对对象 B 的作用是什么？
- 决定归属
- 形成绑定或引用
- 仅用于筛选候选
- 仅作为数据来源
- 只限制可用范围
- 两者没有业务关系
```

## Batch Confirmation Mode

The PRD interview has two phases: **batch review** (Buckets A/B), then **sequential questions** (Bucket C only).

### Decision Classification

For every item in the PRD Blocking Decisions list, classify it into one of three buckets:

**Bucket A — Confident Inference（可自行确定）：** The assistant has enough information from user input, verified current product behavior, or existing product patterns to propose a reasonable answer with high confidence. Bucket A contains only:

- decisions the user already stated explicitly;
- current product behavior verified in this session;
- wording, structure, or summarization that changes no scope, risk, or behavior.

Bucket A never contains product inference about scope, roles, deployment, objects, relations, lifecycle, or acceptance.

**Bucket B — Low-Risk Default（低风险默认）：** The decision has a clear industry-standard or product-convention default that is easily reversible, cheap to get wrong, and changes no data boundary, permission, lifecycle, or acceptance criteria. Propose the default, mark confidence level, and include in the batch summary. Anything failing any of those conditions is Bucket C.

**Bucket C — Must Ask（必须提问）：** The decision has high impact, no clear default, genuinely ambiguous trade-offs, or the assistant's confidence is low. **The assistant MUST NOT decide Bucket C items.** These become the "需确认" questions and must be asked one at a time.

**Always Bucket C:** deployment and isolation boundary; the relationship between two business objects; lifecycle and states; whether versioning is needed; whether a consumer binds the object or a specific version; whether a new version takes effect automatically; how existing references behave after a version is deactivated; whether historical results are frozen; the main delivery experience and secondary output scope; new content blocks absent from current implementation; high-risk failure and fallback policy; any new business object.

**HARD RULE:** The assistant must NEVER self-answer Bucket C items. Bucket C items can only be resolved by the user's explicit answer.

### JIT `fp-eli5` handoff

This is an explicit-only JIT path. 仅当用户显式要求解释 Phase 1 的当前 A/B review item、当前唯一 Bucket C 问题，或明确接受一次图解建议时，读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/eli5-handoff.md`，加载 `fp:fp-eli5`，并传入。Before invoking, replace every <...> metavariable with the current session's exact value; never send an unresolved metavariable.

```markdown
<!-- fp-eli5-handoff
caller: fp-prd-grill-me
topic: <exact current A/B review item or sole C question>
active-slug: <current PRD slug or N/A>
pending-gate: <exact Phase 1 batch confirmation or current C N/Total>
allowed-sources:
  - <current PRD input, confirmed facts, exact options/impacts/recommendation, and bounded verified code facts>
return-to: <fp-prd-grill-me + same review item/question>
-->
```

图解不得重分类或代答 Bucket C，不得把 recommendation 当答案，不得提前呈现下一题，也不得把 interview completion 当作 PRD/prototype write approval。返回后保持原分类和回答状态，重新呈现同一 review item/question 并等待用户显式答复。

### Phase 1: Batch Review (Buckets A/B)

1. Reuse caller-provided product-surface facts and implementation evidence; explore only missing facts within Minimal Fact Exploration and read relevant settings. Apply fact conversion: describe current behavior in product language and keep member names, paths, interfaces, and fields out of the batch summary.
2. Apply Business-first analysis and the Business-object and relation phases, then classify every applicable PRD Blocking Decision into Bucket A, B, or C. Keep evidence, user-confirmed decisions, and proposed defaults distinguishable, and never present an assistant recommendation as a user decision.
3. Output a single batch review message:

```markdown
## PRD 决策确认

以下是建议采用的默认项（待批量确认）：根据你的需求、当前产品行为和常见实践整理。请快速审阅，有异议的指出即可。

### 建议采用的默认项（待批量确认）

| # | 桶 | 决策项 | 推断结果 | 置信度 | 依据 |
|---|---|---|---|---|---|
| 1 | A/B | <决策项> | <结果> | high/medium/low | <依据> |
| 2 | ... | ... | ... | ... | ... |

### 待确认问题（接下来逐个确认）

- 问题 1：<主题>
- 问题 2：<主题>
- 问题 3：<主题>
```

4. Wait for user response. Accepted responses:
   - `全部确认` / `没问题` → proceed to Phase 2.
   - `第3项改成...` → apply correction, re-confirm changed items, then proceed.

### Phase 2: Sequential Questions (Bucket C — one at a time)

**HARD GATE:** Bucket C questions MUST be asked one at a time. After each question, wait for the user's answer before asking the next. Do NOT bundle multiple C questions in one message. Do NOT answer for the user. Do NOT skip ahead.

Bucket C target: 3–5 questions, not a cap or a quota. Prioritize upstream and highest-impact decisions; if more remain, continue one at a time until each blocker is resolved or the user explicitly narrows scope so it no longer applies. Never downgrade Bucket C to Bucket B, hide it as a non-blocking open question, or combine several independent decisions into one question to meet the target. Do not invent questions when decisions are already confirmed.

Question format (one question per turn):

```markdown
### 需确认（第 N/Total 个）

已确认事实：
- <事实>

**问题：** <具体问题>

选项：
- A. <选项A> — <影响>
- B. <选项B> — <影响>
- C. <选项C> — <影响>

**推荐：** A，因为 <依据>。

请回答 A/B/C 或给出你的方案。
```

After the user answers, briefly confirm (`收到，确认为 A：<摘要>`) and immediately ask the next C question. Do not re-state already-answered questions.

### After Phase 2

When all Bucket C questions are answered, produce a brief confirmation summary of all Bucket C decisions, then return to `fp-prd` for canonical-form selection, the final output-path summary, and explicit pre-write approval. Do not treat interview completion as write approval.

### Special: 0 Bucket C Items

If no items fall into Bucket C, re-check the applicable PRD Blocking Decisions and Business-first analysis for omissions. If there are genuinely no unresolved blockers, show the Phase 1 batch summary and ask for `全部确认`, then return to `fp-prd`; do not manufacture questions to reach 3–5. Complete PRDs and explicitly authorized assumption-based generation follow the same evidence/assumption labeling. Any actual unresolved high-impact decision stays in Bucket C.

## PRD Blocking Decisions

Before `fp-prd` writes either PRD form or the resolved prototype, confirm every decision that can change product scope, user value, risk, or acceptance criteria:

- Target users, roles, and user stories.
- Business problem, pain point, and expected outcome.
- Deployment and isolation boundary: single instance or multi-tenant, organization/project/space/business isolation, which roles create, use, view and manage, and whether data is shared across scopes.
- MVP scope, out-of-scope items, and delivery boundary.
- Current and target business workflows, their differences, affected roles/systems and evidence for unchanged scope, following Business-first analysis.
- Business objects, their relation types, lifecycles, reference/version semantics, historical consistency, and the target content model, following the Business-object and relation phases.
- Business-state transitions, rules, approval, async work, scheduling, or frontend/backend coordination when applicable.
- Main delivery experience and secondary output scope: which output is designed in depth and which only needs a consistency requirement.
- Page entry, key interactions, and critical page elements.
- Key fields, validation rules, and data boundaries.
- Permission model, visibility, and unauthorized access risk.
- Audit/operation log requirements.
- High-risk error handling and fallback behavior: the object's state after failure, who owns recovery, retry/cancel boundary, and where the result becomes visible.
- Whether a prototype is needed; the user's explicit choice among direct PRD, lightweight product wireframe, or runnable interaction prototype; its rendering mode, selected app/baseReference and source/Mock/build scope; and which simple interactions the resolved prototype must support, such as dialog open/close, form validation, search/filter, table selection, step navigation, submit success/error, loading, or permission-disabled states.
- Acceptance criteria and core test scenarios.
- PRD form and split strategy for multi-change input: default to the small form in compact `prd.md`; use the mutually exclusive split form in `prd/00-index.md` plus a fragment manifest only under the shared artifact-layout contract's overflow/approval/setting gates, keeping complete feature blocks together on semantic boundaries.
- Existing PRD disposition when `prd.md`, `prd/`, or an incomplete/conflicting split form is present; any conversion/removal requires explicit approval.

涉及原型模式、基座或构建/预览时，先读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/prototype-contract.md`。访谈只确认需求与批准范围，不创建共享基座；project-native 的目标 app、baseReference、源码/Mock/预览路径及命令/cwd 纳入原型摘要。已有前端默认推荐原生复用，保留明确选择的 standalone-html，不因旧模板示例而自动仿写 HTML。

## Prototype-first Interview

When `fp-prd` selects Prototype-first mode, this skill narrows the interview to prototype-blocking decisions first. It still requires the user's explicit prototype choice; a UI-heavy idea alone never triggers this interview. Apply Business-first analysis and the Business-object and relation phases first to the business chain, objects, relations, rules and states that the prototype will demonstrate; retain other business unknowns for confirmation before PRD writing. The goal is to create a reviewable the resolved prototype before writing either PRD Markdown form. 原型确认只覆盖已演示的行为，不自动确认未展示的业务规则、异常闭环、版本语义或后台不改结论。

Prototype-first still uses the same Bucket A/B/C discipline:

- Bucket A/B: batch review inferred/default prototype decisions for user correction.
- Bucket C: ask one at a time, and never self-answer.

Confirm these prototype-blocking decisions before the resolved prototype is written:

- Target page, dialog, wizard, dashboard, or interaction scenario.
- Primary user and job-to-be-done for the prototype.
- Page entry point and previous/next navigation context.
- Key layout regions and hierarchy.
- Key fields, filters, table columns, actions, and button states.
- Loading, empty, success, error, disabled, and permission-denied states that must be visible or switchable.
- Concrete interactions to simulate, such as dialog open/close, form validation, search/filter, table selection, wizard step navigation, submit success/error, and permission-disabled controls.
- Visual source: existing page, Figma, screenshot, `fp-docs/settings/prototype-style.md`, `fp-frontend-spec`, or neutral default.

Do **not** ask backend implementation questions during the prototype-first interview unless they affect visible behavior or required user states. Backend/API/data/security details can be asked later before PRD writing.

After the prototype is generated, the user must review it. If the user asks for visual or interaction changes, update the prototype and ask for review again. Only after the user explicitly confirms the prototype may `fp-prd` derive PRD requirements from it.

## Minimal Fact Exploration

Explore only facts that reduce PRD questions. This skill is not allowed to load all project docs.

Allowed default context:

- Read `fp-docs/manifest.md` if present, as an index only.
- Read at most 1-2 directly relevant settings files:
  - `settings/prototype-style.md` only for prototype generation.
  - `settings/frontend.md` only for UI/page/prototype decisions.
  - `settings/backend.md` only for backend/API/data/security/permission product decisions.
- Read `intel/unknowns.md` / `intel/decisions.md` only if the manifest lists actual directly relevant project-level content. Their absence is not a blocker; keep ordinary questions as `change-local unknowns` in the current PRD interview.
- During one-release compatibility, a manifest-listed `intel/unknowns-and-decisions.md` may be read as a legacy hint only, never required current proof.

Do not read by default:

- all `fp-docs/intel/*` files;
- broad backend/frontend/project scan files;
- historical `fp-docs/changes/*`, `archive/*`, or `history/*`;
- unrelated design, task, execution, or review artifacts.

Code/current-state exploration limits:

- Use the current environment's best search tools; do not require a specific command.
- Read at most 3 constraint/README files.
- Use 3-8 high-value search terms.
- Run at most 6 file/content searches.
- Read at most 8 relevant files, only the relevant excerpts.
- Stop when you can ask the next useful question.

Stale intel rule:

- Generated intel is a stale-prone hint, not proof.
- If an intel file is stale, broad, or lacks freshness metadata, use it only to choose search terms.
- Verify exact menus, routes, enums, APIs, permissions, components, tokens, or commands from current code before using them as confirmed facts.

Code facts can explain current behavior and existing patterns; they cannot decide business goals, MVP tradeoffs, risk acceptance, or acceptance criteria for the user.

## Question Format (for Bucket C sequential questions)

Reuse the exact Phase 2 format above: numbered N/Total, one question per turn, scoped A/B/C options with impacts, and a recommendation. Never bundle questions. A recommendation is not confirmation; proceed only after the user answers.

## Ambiguous Answer Handling

If the user answers with an unscoped option letter such as `A`, `B`, or `C` during a single Bucket C question, treat it as the answer for the current question and briefly restate: `收到，确认为 A：<摘要>。`

If the user's answer is genuinely ambiguous (unclear which question, unclear intent), ask once for clarification of the current question only, then proceed.

## Correction Handling

Users may correct previous answers using phrases like `不是`, `改成`, `纠正一下`, `上一题选错了`.

When a correction appears:
1. Identify which earlier Bucket C question is being corrected.
2. Restate the old and new interpretation.
3. If the new answer is clear, update the decision and continue with the next question.
4. Do NOT re-ask already-answered questions unless the correction creates a contradiction with a later answer. In that case, surface the contradiction and ask how to resolve.

Confirm briefly: `收到，我更正为：问题 N 选择 B（<新含义>），不是 A（<旧含义>）。` Then continue.

For prototype requests, do not accept “make a prototype” as sufficient. Confirm the concrete interactions to demonstrate. If the user does not specify them, recommend a minimal interaction set based on the workflow and ask for approval.

## Stop Condition

When all PRD-blocking decisions are confirmed, return to `fp-prd` with:

- Confirmed user stories.
- Confirmed scope and out-of-scope items.
- Confirmed current/target business flow and changes, actor/system impacts with evidence for unchanged scope, and applicable state/rule/exception closure; distinguish verified facts, user decisions and authorized assumptions.
- Confirmed business objects, relation types, lifecycle and reference/version semantics, and target content model, with the user's decision as the source for each.
- Confirmed main delivery experience, secondary output scope, and each feature's confirmed user stories and goals.
- Confirmed workflow/prototype decision, including the user's explicit prototype choice.
- Confirmed prototype interactions, if the resolved prototype will be generated.
- Confirmed non-functional requirements.
- Non-blocking open questions, each with why it is non-blocking.
- Recommended small or split PRD form, semantic fragment ownership when split, and any existing-artifact conflict or proposed conversion. `fp-prd` owns the final selection and approval gate.
