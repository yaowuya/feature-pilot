---
name: fp-prd-grill-me
description: Use with fp-prd to grill a product idea, pain point, user story, or rough requirement until PRD-blocking decisions are confirmed.
---

## FeaturePilot workspace and customer settings

Before asking PRD-blocking questions that depend on project conventions, read relevant target-project settings when present:

- `fp-docs/settings/agent.md` for project-specific FeaturePilot rules.
- `fp-docs/settings/agent.md` for UI/component/design-system rules.
- `fp-docs/settings/agent.md` for review and execution rules.
- `fp-docs/settings/agent.md` for project path conventions.

If settings are absent, use current project code and adjacent implementations only. Do not assume any customer component library, vendor, component prefix, design token, or workflow policy.

# FeaturePilot PRD Grill Me

This skill specializes `grill-me` for PRD creation.

## First Step

Load and follow `grill-me` first. This skill adds PRD-specific decision gates, output expectations, and stricter question/answer protocol. If `grill-me` conflicts with this skill, this skill wins for PRD interviews.

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
