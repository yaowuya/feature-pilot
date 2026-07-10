---
name: fp-prd-grill-me
description: Use with fp-prd to grill a product idea, pain point, user story, or rough requirement until PRD-blocking decisions are confirmed.
---

## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.


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

Unless the user provided a complete PRD or explicitly authorized assumption-based generation, run Batch Confirmation Mode: Phase 1 batch-review Bucket A/B decisions, then Phase 2 ask Bucket C questions sequentially one at a time with a 3-5 question target. Do not self-answer Bucket C.

## Batch Confirmation Mode

The PRD interview has two phases: **batch review** (Buckets A/B), then **sequential questions** (Bucket C only).

### Decision Classification

For every item in the PRD Blocking Decisions list, classify it into one of three buckets:

**Bucket A — Confident Inference（可自行确定）：** The assistant has enough information from user input, code facts, existing product patterns, or common best practices to propose a reasonable answer with high confidence. These go into the batch summary as "已确定" items. The assistant proposes them; the user reviews and corrects as needed.

**Bucket B — Low-Risk Default（低风险默认）：** The decision has a clear industry-standard or product-convention default that carries low risk if wrong. Propose the default, mark confidence level, and include in the batch summary.

**Bucket C — Must Ask（必须提问）：** The decision has high impact, no clear default, genuinely ambiguous trade-offs, or the assistant's confidence is low. **The assistant MUST NOT decide Bucket C items.** These become the "需确认" questions and must be asked one at a time.

**HARD RULE:** The assistant must NEVER self-answer Bucket C items. Bucket C items can only be resolved by the user's explicit answer.

### Phase 1: Batch Review (Buckets A/B)

1. Explore code facts and read relevant settings.
2. Classify every PRD Blocking Decision into Bucket A, B, or C.
3. Output a single batch review message:

```markdown
## PRD 决策确认

以下是根据你的需求、现有代码和常见实践整理的决策。请快速审阅，有异议的指出即可，没异议我会直接使用。

### 已确定

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

Bucket C target: 3–5 questions. If more than 5, keep only the 5 highest-impact; move the rest to Bucket B with lower confidence noted.

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

When all Bucket C questions are answered, produce a brief confirmation summary of all Bucket C decisions, then immediately return to `fp-prd` to write the PRD.

### Special: 0 Bucket C Items

If no items fall into Bucket C, this is valid only when the input is already a complete PRD or the user explicitly authorized assumption-based generation. Still show the Phase 1 batch summary and ask for `全部确认`. After user confirmation, return to `fp-prd`. Otherwise, re-check the PRD Blocking Decisions and select the highest-impact unresolved decisions as Bucket C.

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

## Prototype-first Interview

When `fp-prd` selects Prototype-first mode, this skill narrows the interview to prototype-blocking decisions first. The goal is to create a reviewable `prototype.html` before writing `prd.md`.

Prototype-first still uses the same Bucket A/B/C discipline:

- Bucket A/B: batch review inferred/default prototype decisions for user correction.
- Bucket C: ask one at a time, and never self-answer.

Confirm these prototype-blocking decisions before `prototype.html` is written:

- Target page, dialog, wizard, dashboard, or interaction scenario.
- Primary user and job-to-be-done for the prototype.
- Page entry point and previous/next navigation context.
- Key layout regions and hierarchy.
- Key fields, filters, table columns, actions, and button states.
- Loading, empty, success, error, disabled, and permission-denied states that must be visible or switchable.
- Concrete interactions to simulate, such as dialog open/close, form validation, search/filter, table selection, wizard step navigation, submit success/error, and permission-disabled controls.
- Visual source: existing page, Figma, screenshot, `fp-docs/settings/prototype-style.md`, `fp-ui-spec`, `fp-ux-spec`, or neutral default.

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
- Read `intel/unknowns-and-decisions.md` only if the manifest lists it and it is directly relevant.

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
- Confirmed workflow/prototype decision.
- Confirmed prototype interactions, if `prototype.html` will be generated.
- Confirmed non-functional requirements.
- Non-blocking open questions, each with why it is non-blocking.
