---
name: fp-prd
description: Use when a user explicitly invokes /fp-prd or $fp-prd, or explicitly asks to create, write, revise, or complete a PRD or product requirements document.
---
## FeaturePilot workspace and information layer

If any anchored plugin resource is missing or unreadable, stop, report the exact resource and an incomplete FeaturePilot installation/cache, and never search the consumer repository for `skills/**` or continue without it.

Read `${CLAUDE_SKILL_DIR}/../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.

Read `${CLAUDE_SKILL_DIR}/../_shared/artifact-layout.md` before resolving, creating, or revising the PRD. It owns canonical form selection, fragment manifest rules, size limits, conflict handling, and Producer/Consumer resolution.
---

# FeaturePilot PRD

`fp-prd` turns a product idea, pain point, user story, or rough requirement into a PRD artifact.

It only creates product requirements artifacts:

- small PRD: `fp-docs/changes/<slug>/prd.md`; or
- split PRD: `fp-docs/changes/<slug>/prd/00-index.md` plus indexed fragments;
- optionally `fp-docs/changes/<slug>/prototype.html`

`prd.md` and `prd/00-index.md` are mutually exclusive forms of one logical template. Select exactly one before writing. `prototype.html` remains a single sibling file in either form.

It supports two modes:

1. **PRD-first mode（默认）**: confirm PRD-blocking decisions, write the selected PRD form, optionally write `prototype.html`.
2. **Prototype-first mode（原型优先）**: confirm prototype-blocking decisions, write/review/iterate `prototype.html` first, then generate the selected PRD form from the confirmed prototype and decisions.

It must not create `proposal.md`, `design.md`, or `tasks/`, and must not enter implementation.

## Required Interview Skill

Before writing any PRD file, load and follow `fp-prd-grill-me`.

`fp-prd-grill-me` is responsible for questioning, code-fact exploration limits, blocking decisions, recommended answers, answer-format instructions, ambiguity handling, correction handling, and confirmation gates. `fp-prd` is responsible only for the PRD path, template, prototype rules, self-review, and handoff.

### Shared code-fact exploration

Before either PRD-first or Prototype-first interviewing, invoke the Skill tool with `fp:fp-explore` and supply the structured `prd-facts` block below only when the input is non-empty, concerns an existing product/page/API/model/permission/compatibility behavior, current repository facts can reduce technical uncertainty, and the idea is not purely greenfield. Do not search for or directly read `skills/fp-explore/SKILL.md`. If the Skill tool cannot invoke `fp:fp-explore`, report the plugin availability or installation failure and stop before interviewing or writing; do not search the consumer project for a fallback. Empty input keeps the existing immediate-stop rule and performs no exploration.

<!-- fp-explore-invoke
profile: prd-facts
objective: Establish existing user-visible behavior, implementation entrypoints, interface/data facts, adjacent product patterns, and technical constraints relevant to this PRD input without deciding requirements, scope, acceptance criteria, or prototype expectations.
caller: fp-prd
active-slug:
caller-owned-context:
  - current non-empty user input and already confirmed product facts
scope-include:
  - user-named pages, routes, APIs, models, permissions, components, and tests
scope-exclude:
  - unrelated fp-docs/changes, archive, and history
budget-profile: small
return-shape: profile-default
external-research: not-authorized
approved-research-boundary:
-->

Consume `verified-facts`, `prd-existing-behavior`, and `prd-technical-constraints` only as code facts for `fp-prd-grill-me`. Keep every `prd-product-decisions` item unanswered for Bucket C or the confirmation summary. Existing UI, enums, routes, APIs, permissions, and adjacent patterns do not imply that the user wants to preserve them. `fp-prd-grill-me` remains the only interview and confirmation authority, and `fp-prd` must never self-answer Bucket C.

### Hard interview gate

`fp-prd` is a requirements-interview workflow, not a one-shot PRD generator.

Before creating any directory or file, the assistant must complete the `fp-prd-grill-me` Batch Confirmation Mode unless one of these explicit exceptions applies:

1. Answers from the PRD interview plus explicit approval of the confirmation summary.
2. A user-provided complete PRD that already covers all PRD-blocking decisions, plus explicit approval to normalize it into the template.
3. An explicit user instruction such as “无需提问，按以下假设生成” or “直接按你的假设生成”, in which case every assumption must be listed in the confirmation summary before writing.

If none of the above is true, run `fp-prd-grill-me` Batch Confirmation Mode: Phase 1 must batch-review Bucket A/B decisions for user correction, then Phase 2 must ask Bucket C questions sequentially one at a time. Target 3-5 Bucket C questions unless the input is already a complete PRD or the user explicitly authorized assumption-based generation. The assistant must never self-answer Bucket C. Code facts, existing menus, enums, routes, or adjacent implementations can reduce technical uncertainty, but they must not replace user confirmation of product goals, MVP scope, roles, permissions risk, acceptance criteria, or prototype expectations.

Writing `fp-docs/prd-*.md`, `fp-docs/*.prd.md`, or any PRD outside the canonical pair `fp-docs/changes/<slug>/prd.md` / `fp-docs/changes/<slug>/prd/00-index.md` is invalid. If such a legacy path exists, offer to migrate or regenerate into one canonical form; do not keep writing to the legacy path.

The generated logical PRD must use the Mandatory PRD Structure exactly. Do not rename, merge, remove, reorder, or add top-level sections. Do not replace required headings with synonyms. Do not change required table columns. The PRD may add rows and may repeat `3.N <功能名称>` blocks for multiple features, but every feature block must keep the exact five subsections `功能说明` / `交互逻辑` / `异常处理` / `页面元素` / `原型` together in one owner file.

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

1. For a non-empty existing-product request that meets the Shared code-fact exploration conditions, invoke `fp:fp-explore` through the Skill tool, run the `prd-facts` invocation above, and pass only its verified facts and unanswered product decisions into `fp-prd-grill-me`. For a purely greenfield idea, skip repository exploration.
2. Load `fp-prd-grill-me`; it owns the interview even when `prd-facts` ran.
3. Stop code-fact investigation as soon as the next useful product question is known.
4. Use `fp-prd-grill-me` Batch Confirmation Mode to confirm PRD-blocking decisions. Unless the user provided a complete PRD or explicitly authorized assumption-based generation, Phase 1 must batch-review Bucket A/B decisions, then Phase 2 must ask Bucket C questions one at a time with a 3-5 question target. Do not self-answer Bucket C.
5. Generate a kebab-case slug, then resolve the existing PRD paths under `fp-docs/changes/<slug>/` according to the shared artifact-layout contract. Do not write yet.
6. Select the final PRD form before writing:
   - for form selection, default to the small form in `prd.md` when the complete logical artifact is expected to stay within 500 lines and 30,000 characters;
   - use split form in `prd/00-index.md` plus a fragment manifest and indexed fragments only when the small form is expected to exceed either hard limit, the user explicitly approves split form, or an applicable target-project setting explicitly requires it. Multiple features, page areas, subsystems, change scopes, or ownership domains guide fragment boundaries after splitting; they do not trigger split form by themselves;
   - preserve an existing canonical form unless the confirmed change requires an explicitly approved conversion.
6. Show a confirmation summary containing confirmed decisions, assumptions, non-blocking open questions, prototype decision, selected form, canonical entrypoint, and planned fragment ownership when split. Include any overwrite, revision, or conversion/removal action.
7. Wait for explicit user approval of that summary. A recommendation from the assistant is not approval.
8. Create only the necessary project-root artifact path for the approved form. Do not create or modify `fp-docs/manifest.md`, `settings/`, or `intel/`; recommend `/fp-init` separately when they are absent.
9. Write the selected form from `${CLAUDE_SKILL_DIR}/prd-template.md`. The logical PRD must preserve exact top-level headings 一 through 六, exact subsection headings, exact table columns, exact ordering, and no extra top-level sections. In split form, write the final fragments directly in manifest order; do not generate and mechanically cut a monolith.
10. If a prototype is confirmed as needed, write `fp-docs/changes/<slug>/prototype.html` and reference it from the unique fragment that owns the complete `3.N` feature block and its `3.N.5 原型` subsection.
11. Run PRD self-review and report the canonical entrypoint and prototype path.

### Prototype-first mode

Use this mode to make the prototype the primary clarification artifact before PRD writing.

1. For a non-empty existing-product request that meets the Shared code-fact exploration conditions, invoke `fp:fp-explore` through the Skill tool, run `prd-facts`, and pass only verified facts and unanswered decisions to `fp-prd-grill-me`. For a purely greenfield idea, skip repository exploration.
2. Load `fp-prd-grill-me`; it owns the Prototype-first interview even when `prd-facts` ran.
3. Generate a kebab-case slug early for artifact paths and resolve any existing `prd.md`, `prd/00-index.md`, `prd/`, and `prototype.html`, but do not write files yet. Block structural conflicts before prototype work.
4. Use `fp-prd-grill-me` Prototype-first interview to confirm only prototype-blocking decisions first:
   - target page or interaction scenario;
   - primary user and job-to-be-done;
   - page entry and core workflow;
   - key screens/regions/components;
   - required fields, table columns, actions, states, and validation;
   - visual source: existing page, Figma, screenshot, `fp-docs/settings/prototype-style.md`, or neutral default;
   - concrete interactions the prototype must demonstrate.
4. Show a prototype confirmation summary with target path `fp-docs/changes/<slug>/prototype.html`, including any overwrite/revision action, and wait for explicit user approval.
5. Create only `fp-docs/changes/<slug>/` if it is missing.
6. Write `fp-docs/changes/<slug>/prototype.html` first. If `fp-docs/settings/prototype-style.md` exists, read and apply it before writing. If it does not exist, use neutral defaults and offer style extraction after the prototype is accepted.
7. Report the prototype path and ask the user to review it. Do **not** write either PRD Markdown form yet.
8. If the user requests prototype changes, update `prototype.html` and ask for review again. Repeat until the user explicitly says the prototype is confirmed.
9. After prototype confirmation, derive PRD decisions from the confirmed prototype plus the interview answers. Use `fp-prd-grill-me` to ask only remaining PRD-blocking Bucket C questions one at a time; do not re-ask prototype decisions that the user already confirmed through the prototype.
10. Select `prd.md` or `prd/00-index.md` before writing using the same semantic split and size rules as PRD-first mode. Preserve an existing canonical form unless an explicitly approved conversion is required.
11. Show the final PRD confirmation summary with selected form, canonical entrypoint, planned fragment ownership when split, and any overwrite, revision, or conversion/removal action. Wait for explicit approval.
12. Write the selected form using the Mandatory PRD Structure verbatim. The unique owner of the complete feature block and its `3.N.5 原型` subsection must reference the confirmed `prototype.html` and state that the requirements were derived from the confirmed prototype.
13. Run PRD self-review and report the canonical entrypoint and prototype path.

Do not create directories or write files before the relevant confirmation summary is approved. In Prototype-first mode, `prototype.html` may be written after prototype confirmation, but every PRD Markdown form must wait until the prototype is reviewed and explicitly confirmed.

### Existing artifact and conflict handling

Before every PRD write or revision, check `prd.md`, `prd/`, and `prd/00-index.md`:

- If `prd.md` and `prd/` both exist, stop: PRD has no compatible dual-form legacy mode. Ask the user to authorize a migration that transfers all unique content into one canonical form, validates it, and removes the obsolete path.
- If `prd/` exists without `prd/00-index.md`, stop and report the incomplete split artifact.
- If exactly one canonical form exists, preserve it unless the confirmed content requires conversion. State the conversion and obsolete-path removal in the pre-write summary and wait for explicit approval.
- For an existing canonical artifact, ask whether to revise it, overwrite/replace it, or cancel. Do not append content outside the logical template.
- If `prototype.html` exists, ask whether to revise it, overwrite/replace it, or cancel before writing it.

A conversion must transfer all unique content, validate the new logical artifact, and remove the old form before completion so `prd.md` and `prd/` never remain together as Producer output.

## PRD output contract

Do not load the output template during interview turns. After the final PRD confirmation summary is explicitly approved and immediately before writing, read `${CLAUDE_SKILL_DIR}/prd-template.md` completely.

- Small form writes only `prd.md`.
- Split form writes only `prd/00-index.md` and its listed Markdown fragments. Its authoritative fragment manifest uses `| Order | File | Kind | Owns |`; every sibling fragment is listed exactly once, and the index owns navigation/ownership metadata only.
- The two forms are mutually exclusive. Every generated Markdown file, including the index, is at most 500 lines and 30,000 characters.
- Logical concatenation in fragment manifest order must pass logical template validation against the exact Mandatory PRD Structure. Every mandatory heading and table has exactly one owner and appears in canonical order.
- Keep every complete `3.N` feature block in one fragment. Other fragments link to an owner instead of duplicating detailed content.

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

Run the checklist in `${CLAUDE_SKILL_DIR}/prd-template.md`. For split form, parse the fragment manifest, read every listed fragment in exact order, reject missing/unindexed/duplicate-owner fragments, and run the same logical template validation over the concatenated logical PRD. If any check fails, fix the PRD/prototype before reporting completion.

## Invalid Output Recovery

If self-review finds structural drift, do not report completion. Rewrite the selected canonical form to conform exactly to Mandatory PRD Structure while preserving confirmed content. If `prototype.html` lacks required interactions, update it before reporting.

## Output

Every successful PRD completion response MUST end with a clearly labeled next-step prompt containing this exact copyable command:

```text
/fp-start <slug>
```

Replace `<slug>` with the completed change slug when it is known. This prompt is required, not optional: never omit it when summarizing, keeping the response concise, reporting a prototype, or reporting non-blocking open questions.

Report:

- PRD canonical entrypoint: `prd.md` or `prd/00-index.md`.
- Prototype path, if generated.
- If this is the project's first prototype, recommend extracting visual style to `fp-docs/settings/prototype-style.md`.
- Confirmed key requirements.
- Non-blocking open questions.
- Required next step: explicitly tell the user they can run `/fp-start <slug>` to resolve the PRD through the shared artifact-layout contract, read split fragments in manifest order when present, and continue into design, planning, and development.
