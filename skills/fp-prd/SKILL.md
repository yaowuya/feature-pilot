---
name: fp-prd
description: Use when a user invokes /fp-prd or provides a product idea, feature request, user story, pain point, rough requirement, 需求想法, 产品需求, 用户故事, 痛点, or 半成品需求 that needs PRD clarification.
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.
---

# FeaturePilot PRD

`fp-prd` turns a product idea, pain point, user story, or rough requirement into a PRD artifact.

It only creates product requirements artifacts:

- `fp-docs/changes/<slug>/prd.md`
- optionally `fp-docs/changes/<slug>/prototype.html`

It supports two modes:

1. **PRD-first mode（默认）**: confirm PRD-blocking decisions, write `prd.md`, optionally write `prototype.html`.
2. **Prototype-first mode（原型优先）**: confirm prototype-blocking decisions, write/review/iterate `prototype.html` first, then generate `prd.md` from the confirmed prototype and decisions.

It must not create `proposal.md`, `design.md`, or `tasks/`, and must not enter implementation.

## Required Interview Skill

Before writing any PRD file, load and follow `fp-prd-grill-me`.

`fp-prd-grill-me` is responsible for questioning, code-fact exploration limits, blocking decisions, recommended answers, answer-format instructions, ambiguity handling, correction handling, and confirmation gates. `fp-prd` is responsible only for the PRD path, template, prototype rules, self-review, and handoff.

### Hard interview gate

`fp-prd` is a requirements-interview workflow, not a one-shot PRD generator.

Before creating any directory or file, the assistant must complete the `fp-prd-grill-me` Batch Confirmation Mode unless one of these explicit exceptions applies:

1. Answers from the PRD interview plus explicit approval of the confirmation summary.
2. A user-provided complete PRD that already covers all PRD-blocking decisions, plus explicit approval to normalize it into the template.
3. An explicit user instruction such as “无需提问，按以下假设生成” or “直接按你的假设生成”, in which case every assumption must be listed in the confirmation summary before writing.

If none of the above is true, run `fp-prd-grill-me` Batch Confirmation Mode: Phase 1 must batch-review Bucket A/B decisions for user correction, then Phase 2 must ask Bucket C questions sequentially one at a time. Target 3-5 Bucket C questions unless the input is already a complete PRD or the user explicitly authorized assumption-based generation. The assistant must never self-answer Bucket C. Code facts, existing menus, enums, routes, or adjacent implementations can reduce technical uncertainty, but they must not replace user confirmation of product goals, MVP scope, roles, permissions risk, acceptance criteria, or prototype expectations.

Writing `fp-docs/prd-*.md`, `fp-docs/*.prd.md`, or any PRD outside `fp-docs/changes/<slug>/prd.md` is invalid. If such a legacy path exists, offer to migrate or regenerate under `fp-docs/changes/<slug>/prd.md`; do not keep writing to the legacy path.

The generated `prd.md` must use the Mandatory PRD Structure exactly. Do not rename, merge, remove, reorder, or add top-level sections. Do not replace required headings with synonyms. Do not change required table columns. The PRD may add rows and may repeat `3.N <功能名称>` blocks for multiple features, but every feature block must keep the exact five subsections `功能说明` / `交互逻辑` / `异常处理` / `页面元素` / `原型`.

## Input

If input is empty, stop and ask the user for one sentence describing an idea, pain point, goal, or user story. Do not explore files or create anything.

Valid inputs include:

- `想给告警列表加负责人筛选`
- `作为运维人员，我想批量重启主机，以便快速处理故障`
- `发布失败后排查很麻烦`
- Semi-structured background, scope, screenshots, Figma links, or reference pages

## Context Budget and Lazy Reads

`fp-prd` must minimize token usage. It must not read the whole `fp-docs/` tree and must not treat init-generated intel as always current.

Default read set:

1. `fp-docs/manifest.md`, if present — read as an index only.
2. `fp-docs/intel/unknowns-and-decisions.md`, only if the manifest lists it and it is small/relevant.
3. `fp-docs/settings/prototype-style.md`, only when generating or updating `prototype.html`.
4. `fp-docs/settings/frontend.md`, only when UI/page/prototype behavior is involved.
5. `fp-docs/settings/backend.md`, only when backend/API/data/security/permission behavior affects product decisions.

Default do-not-read set:

- Do not read all `fp-docs/intel/*`.
- Do not read historical `fp-docs/changes/*`, `fp-docs/archive/*`, or `fp-docs/history/*` as PRD context.
- Do not read broad scan files such as backend/frontend/project overview unless the current question explicitly needs them.
- Do not read implementation plans, design docs, or task files from unrelated changes.

When exact current implementation facts are needed, use current-code search and read only the relevant source excerpts. Generated intel may provide search hints, but current code and command output win for current-state facts.

### Stale Intel Handling

If a relevant intel artifact is stale or has unknown freshness:

- Use it only as a hint for what to search next.
- Verify exact facts against current source files before using them in decisions.
- Mention stale/uncertain intel in the confirmation summary only when it affects a product decision.
- Do not refresh or rewrite project-level intel during `fp-prd`; recommend `/fp-init --refresh` or a future refresh command instead.

## Process

At the start, choose one of two modes from user intent:

- **PRD-first mode（默认）**: use when the user wants a requirements document, user story clarification, or normal `/fp-prd <idea>` flow.
- **Prototype-first mode（原型优先）**: use when the user says they want to see/try/adjust the prototype first, mentions “先原型/先看页面/先出页面/先做交互稿”, or when the idea is UI-heavy and a prototype would clarify the requirement faster.

### PRD-first mode

1. Load `fp-prd-grill-me`.
2. Perform only minimal fact exploration allowed by `fp-prd-grill-me`, then stop as soon as the next useful product question is known.
3. Use `fp-prd-grill-me` Batch Confirmation Mode to confirm PRD-blocking decisions. Unless the user provided a complete PRD or explicitly authorized assumption-based generation, Phase 1 must batch-review Bucket A/B decisions, then Phase 2 must ask Bucket C questions one at a time with a 3-5 question target. Do not self-answer Bucket C.
4. Show a confirmation summary containing confirmed decisions, assumptions, non-blocking open questions, prototype decision, and the target output path `fp-docs/changes/<slug>/prd.md`.
5. Wait for explicit user approval of that summary. A recommendation from the assistant is not approval.
6. Generate a kebab-case slug.
7. Create only the necessary project-root artifact directory `fp-docs/changes/<slug>/` if it is missing. Do not create or modify `fp-docs/manifest.md`, `settings/`, or `intel/`; recommend `/fp-init` separately when they are absent.
8. Write `fp-docs/changes/<slug>/prd.md` using the Mandatory PRD Structure verbatim: exact top-level headings 一 through 六, exact subsection headings, exact table columns, exact ordering, and no extra top-level sections.
9. If a prototype is confirmed as needed, write `fp-docs/changes/<slug>/prototype.html`.
10. Run PRD self-review and report paths.

### Prototype-first mode

Use this mode to make the prototype the primary clarification artifact before PRD writing.

1. Load `fp-prd-grill-me`.
2. Generate a kebab-case slug early for artifact paths, but do not write files yet.
3. Use `fp-prd-grill-me` Prototype-first interview to confirm only prototype-blocking decisions first:
   - target page or interaction scenario;
   - primary user and job-to-be-done;
   - page entry and core workflow;
   - key screens/regions/components;
   - required fields, table columns, actions, states, and validation;
   - visual source: existing page, Figma, screenshot, `fp-docs/settings/prototype-style.md`, or neutral default;
   - concrete interactions the prototype must demonstrate.
4. Show a prototype confirmation summary with target path `fp-docs/changes/<slug>/prototype.html` and wait for explicit user approval.
5. Create only `fp-docs/changes/<slug>/` if it is missing.
6. Write `fp-docs/changes/<slug>/prototype.html` first. If `fp-docs/settings/prototype-style.md` exists, read and apply it before writing. If it does not exist, use neutral defaults and offer style extraction after the prototype is accepted.
7. Report the prototype path and ask the user to review it. Do **not** write `prd.md` yet.
8. If the user requests prototype changes, update `prototype.html` and ask for review again. Repeat until the user explicitly says the prototype is confirmed.
9. After prototype confirmation, derive PRD decisions from the confirmed prototype plus the interview answers. Use `fp-prd-grill-me` to ask only remaining PRD-blocking Bucket C questions one at a time; do not re-ask prototype decisions that the user already confirmed through the prototype.
10. Show the final PRD confirmation summary and wait for explicit approval.
11. Write `fp-docs/changes/<slug>/prd.md` using the Mandatory PRD Structure verbatim. In `3.1.5 原型`, reference the confirmed `prototype.html` and state that PRD requirements were derived from the confirmed prototype.
12. Run PRD self-review and report paths.

Do not create directories or write files before the relevant confirmation summary is approved. In Prototype-first mode, `prototype.html` may be written after prototype confirmation, but `prd.md` must wait until the prototype is reviewed and explicitly confirmed.

If target `prd.md` or `prototype.html` already exists, do not overwrite silently. Ask whether to overwrite, revise, append, or cancel.

## PRD output contract

Do not load the output template during interview turns. After the final PRD confirmation summary is explicitly approved and immediately before writing, read `prd-template.md` completely, render its exact structure, then run its structure self-review.

## Prototype Rules

Generate `prototype.html` only when confirmed necessary for a page, dialog, complex form/table, wizard, dashboard, or unclear interaction.

Prototype requirements:

- Single-file HTML/CSS/JS.
- No external CDN.
- Existing-product work should follow existing pages, `fp-ui-spec`, `fp-ux-spec`, Figma, or screenshot facts.
- Prototype expresses information structure and interaction, not final implementation.
- Prototype must support simple interactions, not just static markup.

Interactive prototype minimum:

- Buttons, tabs, filters, forms, dialogs, expand/collapse, table row actions, or wizard steps that appear in the PRD must be clickable or otherwise operable.
- Form fields must accept input and show basic validation/error feedback for required or invalid values described in PRD.
- Loading, empty, success, and error states mentioned in PRD must be switchable through simple controls or simulated interactions.
- If the PRD includes a submit/confirm action, the prototype must show the resulting state change or message.
- If no meaningful interaction exists, write an inline comment in `prototype.html` explaining why the prototype is intentionally static.

Do not use backend calls. Simulate data and state in local JavaScript only.

### Prototype Style Extraction

After generating the first prototype for a project, recommend a separate settings handoff to the user:

> 检测到这是项目的第一个原型。是否需要在确认原型后，通过 `/fp-init` 或单独的设置更新流程，将当前原型的视觉风格（配色、字体、间距、组件样式、布局模式）提取到 `fp-docs/settings/prototype-style.md`？后续 PRD 生成原型时会自动参考该风格文件，保持视觉一致。

`fp-prd` itself must not create or update `fp-docs/settings/prototype-style.md` or `fp-docs/manifest.md`. If the user wants extraction, hand off to `/fp-init` or an explicit settings workflow after PRD/prototype completion.

### Prototype Style Consumption

Before generating a new `prototype.html`:

1. Check if `fp-docs/settings/prototype-style.md` exists.
2. If present, read it and apply its color palette, typography, spacing, component patterns, and layout patterns to the new prototype.
3. If the user requests a different visual direction, apply the new direction and offer to update `prototype-style.md` after approval.
4. If `prototype-style.md` is missing, proceed with sensible neutral defaults and recommend extraction after the first prototype.

## Self-Review

Run the checklist in `prd-template.md`. If any check fails, fix the PRD/prototype before reporting completion.

## Invalid Output Recovery

If self-review finds structural drift, do not report completion. Rewrite `prd.md` to conform exactly to Mandatory PRD Structure while preserving confirmed content. If `prototype.html` lacks required interactions, update it before reporting.

## Output

Report:

- PRD path.
- Prototype path, if generated.
- If this is the project's first prototype, recommend extracting visual style to `fp-docs/settings/prototype-style.md`.
- Confirmed key requirements.
- Non-blocking open questions.
- Suggested next step: run `fp-start <slug>` to pick up this PRD and continue into design, planning, and development.
