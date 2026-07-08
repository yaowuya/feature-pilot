---
name: fp-prd-grill-me
description: Use with fp-prd to grill a product idea, pain point, user story, or rough requirement until PRD-blocking decisions are confirmed.
---

## FeaturePilot workspace and information layer

Before choosing output paths, commands, UI/backend rules, or workflow behavior:

1. Treat the target project repository root as the FeaturePilot project root, and look only for `fp-docs/` directly under that root.
2. If `fp-docs/manifest.md` exists, read it first.
3. Read only relevant settings and intel listed by the manifest.
4. If UI/frontend is involved and `fp-docs/settings/frontend.md` exists, read it as a required source.
5. If backend/API/data/security behavior is involved and `fp-docs/settings/backend.md` exists, read it as a required source.
6. Treat settings/intel as navigation and constraints; verify exact implementation facts against current code.
7. Use two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, backend framework, API envelope, or workflow policy in public skills. Customer-specific rules belong in target-project settings.

Compatibility rule: if the project root has no `fp-docs/manifest.md`, continue from current code and existing settings when safe, recommend `/fp-init`, and do not force initialization. If the current phase must write FeaturePilot artifacts, create only the necessary artifact directories under the project-root `fp-docs/`; do not create manifest/settings/intel except through `/fp-init`.


# FeaturePilot PRD Grill Me

This skill specializes `grill-me` for PRD creation.

## First Step

Load and follow `grill-me` first. This skill adds PRD-specific decision gates, output expectations, and stricter question/answer protocol. If `grill-me` conflicts with this skill, this skill wins for PRD interviews.

### PRD override for code exploration

The base `grill-me` rule “If a question can be answered by exploring the codebase, explore the codebase instead” applies only to implementation facts and existing-product constraints. It does **not** apply to product decisions.

Code exploration may answer:

- which modules, menus, enums, routes, permissions, APIs, or components already exist;
- what current behavior and constraints are;
- which neighboring patterns can inform options.

Code exploration may **not** decide:

- target users and business value;
- MVP vs out-of-scope boundaries;
- risk acceptance, permission policy, audit needs, or operational fallback expectations;
- acceptance criteria, success metrics, or prototype expectations.

Unless the user provided a complete PRD or explicitly authorized assumption-based generation, ask at least one PRD-blocking question before returning to `fp-prd`.

## Batch Confirmation Mode

The PRD interview must minimize user friction. The default mode is **batch confirmation**, not question-by-question.

### Decision Classification

For every item in the PRD Blocking Decisions list, classify it into one of three buckets:

**Bucket A — Confident Inference（可自行确定）：** The assistant has enough information from user input, code facts, existing product patterns, or common best practices to propose a reasonable answer with high confidence. These go into the batch confirmation summary as "已确定" items.

**Bucket B — Low-Risk Default（低风险默认）：** The decision has a clear industry-standard or product-convention default that carries low risk if wrong. Propose the default, mark confidence level, and include in the batch summary.

**Bucket C — Must Ask（必须提问）：** The decision has high impact, no clear default, genuinely ambiguous trade-offs, or the assistant's confidence is low. These become the "需确认" questions.

### Batch Confirmation Flow

1. Explore code facts and read relevant settings.
2. Classify every PRD Blocking Decision into Bucket A, B, or C.
3. Prepare a single batch confirmation message:

```markdown
## PRD 决策确认

以下是根据你的需求、现有代码和常见实践整理的决策。请快速审阅，有异议的指出即可，没异议我会直接使用。

### 已确定（基于现有代码/实践推断）

| # | 决策项 | 推断结果 | 依据 |
|---|---|---|---|
| 1 | <决策项> | <结果> | <依据> |
| 2 | ... | ... | ... |

### 需确认（3-5 个关键问题）
```

4. Ask **only Bucket C items** as numbered questions. Target 3–5 questions. If Bucket C exceeds 5, keep only the 5 highest-impact questions; move the rest to Bucket A with lower confidence noted.
5. The user can respond with:
   - `全部确认` / `没问题` → proceed with all decisions.
   - `第3项改成...` / `问题2选B` → apply the correction, re-confirm only the changed item.
   - Individual corrections → apply and proceed.
6. After user confirmation, proceed to write the PRD.

### Bucket C Selection Rules

- Maximum 5 Bucket C questions. If more than 5 decisions are genuinely uncertain, prioritize by: safety/risk impact > scope/cost impact > user experience impact.
- If 0 Bucket C items remain (everything is A or B), still show the batch summary and ask for a single `全部确认` before proceeding.
- Every Bucket C question must include a recommended answer with reasoning.
- Multi-question format for Bucket C follows the existing multi-question format in Question Format below.

## PRD Blocking Decisions

Before `fp-prd` writes `prd.md` or `prototype.html`, confirm every decision that can change product scope, user value, risk, or acceptance criteria:

- Target users, roles, and user stories.
- Business problem, pain point, and expected outcome.
- MVP scope, out-of-scope items, and delivery boundary.
- Core workflow, state transitions, approval, async work, scheduling, or frontend/backend coordination.
- Page entry, key interactions, and critical page elements.
- Key fields, validation rules, and data boundaries.
- Permission model, visibility, and unauthorized access risk.
- Audit/operation log requirements.
- High-risk error handling and fallback behavior.
- Whether an HTML prototype is needed; what source it should follow; and which simple interactions `prototype.html` must support, such as dialog open/close, form validation, search/filter, table selection, step navigation, submit success/error, loading, or permission-disabled states.
- Acceptance criteria and core test scenarios.
- Split strategy for multi-change input.

## Minimal Fact Exploration

Explore only facts that reduce PRD questions:

- Use the current environment's best search tools; do not require a specific command.
- Read at most 3 constraint/README files.
- Use 3-8 high-value search terms.
- Run at most 6 file/content searches.
- Read at most 8 relevant files, only the relevant excerpts.
- Stop when you can ask the next useful question. Ask 2-3 questions only when the `Question Format` rules allow a rare multi-question turn.

Code facts can explain current behavior and existing patterns; they cannot decide business goals, MVP tradeoffs, risk acceptance, or acceptance criteria for the user.

## Question Format

Default to exactly one question per turn. Ask multiple questions in one turn only when they are tightly coupled, all are necessary to unblock the same immediate decision, and the answer format below makes ambiguity unlikely.

Every question must be numbered, even when there is only one question. Every option label is scoped to its question number.

For the common one-question case, use this format:

```markdown
### 需要确认：<问题主题>

已确认事实：
- <事实1>
- <事实2>

关键缺口：
- <缺口及影响>

**问题 1：** <具体问题>

选项：
1A. <选项A> — <影响>
1B. <选项B> — <影响>
1C. <选项C> — <影响>

**推荐：** 1A，因为 <依据>。

请按以下任一格式回答：
- `1A`
- `问题1：<你的具体答案>`
- `同意推荐`
```

For the rare multi-question case, include the answer instructions after every set of questions:

```markdown
### 需要确认：<问题主题>

**问题 1：** <具体问题>

选项：
1A. <选项A> — <影响>
1B. <选项B> — <影响>
1C. <选项C> — <影响>

**推荐：** 1A，因为 <依据>。

**问题 2：** <具体问题>

选项：
2A. <选项A> — <影响>
2B. <选项B> — <影响>
2C. <选项C> — <影响>

**推荐：** 2B，因为 <依据>。

请逐题回答，格式示例：
- `1A, 2B`
- `1A；问题2：<你的具体答案>`
- `全部同意推荐`

不要只回复 `A` / `B` / `C`；如果只回复单个字母，我会先确认你指的是哪一道问题。
```

A recommendation is not confirmation. Proceed only after the user chooses a question-scoped option such as `1A`, gives a concrete answer for the question, says `同意推荐` when exactly one question was asked, says `全部同意推荐` when multiple questions were asked, or explicitly authorizes the listed assumptions.

## Ambiguous Answer Handling

If the user answers with an unscoped option letter such as `A`, `B`, or `C`:

- If exactly one question was asked in the immediately preceding assistant turn, treat it as the corresponding option for that question and briefly restate the interpretation, for example: `我理解为你选择问题 1 的 1A：<选项摘要>。`
- If more than one question was asked, do not infer. Ask a clarification question before proceeding: `你回复了 “A”，但上一轮有多个问题。请确认是 1A、2A，还是其他？`

If the user provides fewer answers than the number of questions asked, record only the clearly answered items and ask the next unanswered question as a single-question follow-up.

If the user's free-form answer conflicts with an option label, prioritize the free-form content and ask a single clarification question if the intended decision is still unclear.

## Correction Handling

Users may correct a previous answer using phrases such as `不是`, `我说的是`, `改成`, `纠正一下`, or `上一题选错了`.

When a correction appears:

1. Stop advancing the interview.
2. Identify the exact prior decision being corrected by question number, option label, or topic.
3. Restate the old interpretation and the new interpretation.
4. Ask for confirmation only if the corrected target or new value is ambiguous.
5. Update the confirmed-decision summary before asking the next PRD-blocking question.

Example response:

```markdown
收到，我更正为：问题 1 选择 1B（<新含义>），不是 1A（<旧含义>）。

当前已确认：
- <更新后的决策>

下一个需要确认：...
```

For prototype requests, do not accept “make a prototype” as sufficient. Confirm the concrete interactions to demonstrate. If the user does not specify them, recommend a minimal interaction set based on the workflow and ask for approval.

## Stop Condition

When all PRD-blocking decisions are confirmed, return to `fp-prd` with:

- Confirmed user stories.
- Confirmed scope and out-of-scope items.
- Confirmed workflow/prototype decision.
- Confirmed prototype interactions, if `prototype.html` will be generated.
- Confirmed non-functional requirements.
- Non-blocking open questions, each with why it is non-blocking.
