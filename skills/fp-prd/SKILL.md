---
name: fp-prd
description: Use when a user explicitly invokes /fp-prd or $fp-prd, or explicitly asks to create, write, revise, or complete a PRD or product requirements document.
---
## FeaturePilot workspace and information layer

插件资源锚定、`${CLAUDE_PLUGIN_ROOT}` 路径映射与缺失即停止规则见 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md`；不要在消费者项目中搜索 `skills/**`。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` before resolving, creating, or revising the PRD. It owns canonical form selection, fragment manifest rules, size limits, conflict handling, and Producer/Consumer resolution.
---

# FeaturePilot PRD

`fp-prd` turns a product idea, pain point, user story, or rough requirement into a PRD artifact.

It only creates product requirements artifacts:

- small PRD: `fp-docs/changes/<slug>/prd.md`; or
- split PRD: `fp-docs/changes/<slug>/prd/00-index.md` plus indexed fragments;
- optionally one prototype: native `fp-docs/changes/<slug>/prototype/manifest.json` with editable framework source, Mock and `preview/index.html`, or legacy `fp-docs/changes/<slug>/prototype.html`.

`prd.md` and `prd/00-index.md` are mutually exclusive forms of one logical template. Select exactly one before writing. 原型独立于 PRD 的 small/split 表示；涉及原型时读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/prototype-contract.md`，它拥有模式选择、基座、路径、构建与验证规则。

It supports two order modes:

1. **PRD-first mode（默认）**: confirm PRD-blocking decisions, optionally run an explicitly user-selected prototype, write the selected PRD form.
2. **Prototype-first mode（原型优先）**: only after the user explicitly selects it, confirm prototype-blocking decisions, generate/review/iterate the resolved prototype first, then generate the selected PRD form from the confirmed prototype and decisions.

原型渲染默认在已有前端使用 **project-native**：消费已确认 app 的基座，以同框架源码增量实现，全部业务数据 Mock，构建静态预览；**standalone-html** 仅保留既有形式或用户明确选择的轻量/降级路径。PRD-first/Prototype-first 不决定渲染技术。创建隔离原型源码不是生产实现授权。

It must not create `proposal.md`, `design.md`, or `tasks/`, and must not enter production implementation or modify shared prototype bases.

## Product-first contract

`fp-prd` owns a **product-first** interview-to-PRD path. 本契约是该路径的语言、事实和原型边界权威；`fp-prd-grill-me` 拥有提问与分类，`prd-template.md` 拥有写作槽位与自检。

### PRD audience and product-language gate

PRD 的默认读者是产品经理、业务方、设计师和研发评审者。PRD 只描述 Who / Why / What / Rule / Outcome，不描述 How。

除非用户明确要求技术型 PRD，PRD 正文不得包含：

- 源码路径、文件名和行号；
- 类名、函数名、模型名、接口名和字段设计；
- 数据库、队列、事务、序列化和框架实现；
- 构建命令、端口、SHA、Git 状态和验证计数。

实现方式进入 proposal、design 和 tasks。原型技术信息由 `prototype/manifest.json` 与原型 evidence 独占。

### Code-fact consumption boundary

代码探索结果只能回答：

- 当前用户能做什么、不能做什么；
- 当前行为有哪些兼容约束；
- 哪些能力需要前后端共同变化。

代码探索结果不能回答：

- 目标用户要什么、MVP 含哪些新能力；
- 模块应拆分、合并还是新增；
- 哪种生命周期、权限或版本策略正确；
- 用户是否希望保留当前限制。

### Fact conversion

消费 `fp-explore` 结果后、进入访谈前，按顺序转换：

1. 提取 `prd-product-surface-facts` 中用户可见、可操作、可感知的行为；
2. 删除实现标识（成员名、路径、接口、字段、命令）；
3. 将该现状改写成产品语言；
4. 保留 `prd-implementation-evidence` 给后续 proposal/design，不写入 PRD；
5. 禁止把实现能力直接写成目标范围，禁止用现有枚举、模块或字段决定 MVP 边界。

### Prototype selection gate

`UI-heavy` 只用于推荐原型，不切换模式。进入原型必须满足以下任一条件：

1. 用户明确要求先看原型；
2. 用户在原型选择中选择了轻量产品线框或可运行交互原型；
3. 当前唯一阻塞项只有可视化才能确认，且用户批准该成本。

未获用户选择前不创建任何原型工程、不安装依赖、不运行构建或预览。

### Report layering

默认完成汇报只面向产品读者，包含：PRD 入口、核心产品范围、原型入口（若有）、非阻塞问题、`/fp-start <slug>`。原型技术元数据、构建/浏览器/视觉检查与 Git 状态保留在 manifest/evidence 与内部报告中，仅在用户询问时展开。

## Required Interview Skill

Before writing any PRD file, load and follow `fp-prd-grill-me`.

`fp-prd-grill-me` is responsible for questioning, code-fact exploration limits, blocking decisions, recommended answers, answer-format instructions, ambiguity handling, correction handling, and confirmation gates. `fp-prd` is responsible only for the PRD path, template, prototype rules, self-review, and handoff.

### Shared code-fact exploration

在进入 PRD-first 或 Prototype-first 访谈前，仅当输入非空、涉及现有产品/页面/API/模型/权限/兼容行为、当前仓库事实能够降低技术不确定性，且需求并非纯绿地场景时，才使用当前运行时原生技能机制加载一次 `fp:fp-explore`，并向其 `prd-facts` profile 提供下方结构化块。加载顺序如下：如果运行时提供可调用的 `Skill` tool，直接调用 `fp:fp-explore`；否则，如果运行时的 `available skills` 元数据列出了 `fp:fp-explore` 及其 `SKILL.md` 入口路径，就从该路径读取已安装的 FeaturePilot 分发目录中的完整技能说明并严格执行。只有两种机制都无法解析或读取 `fp:fp-explore` 时，才报告插件可用性或安装失败，并在访谈和写入前停止。不得搜索消费者项目来寻找回退，也不得直接读取消费者项目中的 `skills/fp-explore/SKILL.md`。空输入仍按既有规则立即停止，不执行探索。

<!-- fp-explore-invoke
profile: prd-facts
objective: Establish existing user-visible behavior as product-language current behavior, plus implementation entrypoints, interface/data facts, adjacent product patterns, and technical constraints relevant to this PRD input without deciding requirements, scope, acceptance criteria, or prototype expectations.
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

Consume `verified-facts`, `prd-product-surface-facts`, `prd-implementation-evidence`, and `prd-technical-constraints` only as code facts for `fp-prd-grill-me`. Apply Fact conversion before any product question: `prd-product-surface-facts` becomes product-language current behavior, `prd-implementation-evidence` stays out of PRD prose, and every `prd-product-decisions` item stays unanswered for Bucket C or the confirmation summary. Existing UI, enums, routes, APIs, permissions, and adjacent patterns do not imply that the user wants to preserve them, and they never define MVP scope. `fp-prd-grill-me` remains the only interview and confirmation authority, and `fp-prd` must never self-answer Bucket C.

### Hard interview gate

`fp-prd` is a requirements-interview workflow, not a one-shot PRD generator.

Before creating any directory or file, the assistant must complete the `fp-prd-grill-me` Batch Confirmation Mode unless one of these explicit exceptions applies:

1. Answers from the PRD interview plus explicit approval of the confirmation summary.
2. A user-provided complete PRD that already covers all PRD-blocking decisions, plus explicit approval to normalize it into the template.
3. An explicit user instruction such as “无需提问，按以下假设生成” or “直接按你的假设生成”, in which case every assumption must be listed in the confirmation summary before writing.

If none of the above is true, run `fp-prd-grill-me` Batch Confirmation Mode: Phase 1 must batch-review Bucket A/B decisions for user correction, then Phase 2 must ask Bucket C questions sequentially one at a time. Target 3-5 Bucket C questions unless the input is already a complete PRD or the user explicitly authorized assumption-based generation. The assistant must never self-answer Bucket C. Code facts, existing menus, enums, routes, or adjacent implementations can reduce technical uncertainty, but they must not replace user confirmation of product goals, MVP scope, roles, permissions risk, acceptance criteria, or prototype expectations. Bucket A holds only user-stated decisions, current product behavior verified in this session, and wording that changes no scope, risk, or behavior; Bucket B holds only easily reversible, low-cost-to-be-wrong display defaults that change no data boundary, permission, lifecycle, or acceptance. Everything else is Bucket C.

Writing `fp-docs/prd-*.md`, `fp-docs/*.prd.md`, or any PRD outside the canonical pair `fp-docs/changes/<slug>/prd.md` / `fp-docs/changes/<slug>/prd/00-index.md` is invalid. If such a legacy path exists, offer to migrate or regenerate into one canonical form; do not keep writing to the legacy path.

The generated logical PRD must use the Mandatory PRD Structure exactly. Do not rename, merge, remove, reorder, or add top-level sections. Do not replace required headings with synonyms. Do not change required table columns. The PRD may add rows and may repeat `3.N <功能名称>` blocks for multiple features, but every newly generated feature block must keep the exact four subsections `功能说明` / `交互逻辑` / `异常处理` / `原型` together in one owner file. Historical blocks with `页面元素` and `3.N.5 原型` remain readable; do not add that legacy field to new PRDs.

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
2. `fp-docs/intel/unknowns.md` and `fp-docs/intel/decisions.md`, only if the manifest lists actual directly relevant project-level content. Their absence is not a blocker; keep ordinary questions as `change-local unknowns` and ask through the PRD interview.
3. `fp-docs/settings/prototype-style.md`, only when generating or updating a prototype.
4. `fp-docs/settings/frontend.md`, only when UI/page/prototype behavior is involved.
5. `fp-docs/settings/backend.md`, only when backend/API/data/security/permission behavior affects product decisions.
6. For native prototypes only, the selected app's exact base manifest and relevant sources/evidence under `fp-docs/prototype-bases/<app-id>/`; follow `prototype-contract.md`, not a recursive scan of all bases.

Default do-not-read set:

- Do not read all `fp-docs/intel/*`.
- Do not read historical `fp-docs/changes/*`, `fp-docs/archive/*`, or `fp-docs/history/*` as PRD context.
- Do not read broad scan files such as backend/frontend/project overview unless the current question explicitly needs them.
- Do not read implementation plans, design docs, or task files from unrelated changes.

When exact current implementation facts are needed, use current-code search and read only the relevant source excerpts. Generated intel may provide search hints, but current code and command output win for current-state facts.

For one-release compatibility, a manifest-listed `intel/unknowns-and-decisions.md` may be read as a legacy hint only. It is never required, never current proof, and `fp-prd` must not create or update it.

### Stale Intel Handling

If a relevant intel artifact is stale or has unknown freshness:

- Use it only as a hint for what to search next.
- Verify exact facts against current source files before using them in decisions.
- Mention stale/uncertain intel in the confirmation summary only when it affects a product decision.
- Do not refresh or rewrite project-level intel during `fp-prd`; `supported-init-rerun`：建议重新运行 `/fp-init`，由其展示实时 stale/conflict 清单并执行批准门禁。

## Business closure gate

在两种模式中都遵循 `fp-prd-grill-me` 的 Business-first analysis：先确认业务如何运行，再把已确认规则落到页面与交互。`fp-prd-grill-me` 拥有分析顺序与决策门禁，输出模板拥有内容落点与自检；不新增业务分析产物。

- PRD 确认摘要必须概括现状/目标流程、变化与范围、角色/系统影响、适用的业务状态/规则/异常闭环，以及不改结论的依据；简单功能按访谈规则缩减，不虚构复杂流程。
- 原型确认只覆盖已演示的行为。原型未展示的业务规则、后台能力和异常处置仍由访谈确认，不能从画面反推为产品事实。
- **业务闭环门禁：** 影响范围、风险或验收的未知事项解决后才进入最终 PRD 写入确认；3–5 只是提问目标，不是问题上限，也不为凑数提问。未决事项不可伪装成非阻塞问题；明确授权的假设须在摘要和 PRD 对应位置标明。
- 业务对象、关系语义和生命周期在页面问题之前确认；原型画面不能反推为产品事实。

## Process

At the start, choose one of two modes from user intent:

- **PRD-first mode（默认）**: use when the user wants a requirements document, user story clarification, or normal `/fp-prd <idea>` flow.
- **Prototype-first mode（原型优先）**: use only when the user says they want to see/try/adjust the prototype first, or mentions “先原型/先看页面/先出页面/先做交互稿”. A UI-heavy idea never selects this mode by itself; it only makes the Prototype selection gate a recommendation.

### PRD-first mode

1. For a non-empty existing-product request that meets the Shared code-fact exploration conditions, invoke `fp:fp-explore` through the Skill tool, run the `prd-facts` invocation above, apply Fact conversion, and pass only product-language current behavior plus unanswered product decisions into `fp-prd-grill-me`. For a purely greenfield idea, skip repository exploration.
2. Load `fp-prd-grill-me`; it owns the interview even when `prd-facts` ran.
3. Stop code-fact investigation as soon as the next useful product question is known.
4. Use `fp-prd-grill-me` Batch Confirmation Mode to confirm PRD-blocking decisions in the interview order it owns: intent, deployment/usage boundary, business objects, relations, lifecycle and reference semantics, content model, journey and output scope, then exceptions/permissions/logs/acceptance. Unless the user provided a complete PRD or explicitly authorized assumption-based generation, Phase 1 must batch-review Bucket A/B decisions, then Phase 2 must ask Bucket C questions one at a time with a 3-5 question target. Do not self-answer Bucket C.
5. Generate a kebab-case slug, then resolve the existing PRD paths under `fp-docs/changes/<slug>/` according to the shared artifact-layout contract. Do not write yet.
6. Select the final PRD form before writing per the shared artifact-layout contract: default to the small form in `prd.md`; use split form in `prd/00-index.md` plus a fragment manifest and indexed fragments only under that contract's overflow/approval/setting gates. Preserve an existing canonical form unless the confirmed change requires an explicitly approved conversion.
7. Apply the Prototype selection gate. When a prototype is part of the delivery, present the three options (直接写 PRD / 先做轻量产品线框 / 先做可运行交互原型) and wait for the user's choice; a UI-heavy idea only adds the recommendation. For a selected prototype, resolve its mode (defaulting to `static-modular` for an existing frontend), path, base and freshness through Prototype Rules before including source/Mock scope, preview commands/cwd and all dependency/configuration effects.
8. Show a confirmation summary containing the Business closure gate results, confirmed decisions, assumptions, non-blocking open questions, selected PRD form, canonical entrypoint, fragment ownership when split, and the resolved prototype choice. Include any overwrite, revision, or conversion/removal action. Wait for explicit user approval; a recommendation from the assistant is not approval.
9. Create only the necessary project-root artifact path for the approved form. Do not create or modify `fp-docs/manifest.md`, `settings/`, or `intel/`; recommend `/fp-init` separately when they are absent.
10. Write the selected form from `${CLAUDE_PLUGIN_ROOT}/skills/fp-prd/prd-template.md`, applying the product-language gate. The logical PRD must preserve exact top-level headings 一 through 六, exact subsection headings, exact table columns, exact ordering, and no extra top-level sections. In split form, write the final fragments directly in manifest order; do not generate and mechanically cut a monolith.
11. If a prototype was selected and approved, execute the Prototype Rules below for the approved rendering mode and reference the resolved manifest/preview or legacy HTML from the unique owner of the complete feature block and its `3.N.4 原型` subsection. Keep prototype technical metadata in manifest/evidence.
12. Run PRD self-review, then report using the Report layering contract.

### Prototype-first mode

Use this mode to make the prototype the primary clarification artifact before PRD writing. The user must have selected the runnable-interaction prototype option, or explicitly asked for a prototype first.

1. For a non-empty existing-product request that meets the Shared code-fact exploration conditions, invoke `fp:fp-explore` through the Skill tool, run `prd-facts`, apply Fact conversion, and pass only product-language current behavior and unanswered decisions to `fp-prd-grill-me`. For a purely greenfield idea, skip repository exploration.
2. Load `fp-prd-grill-me`; it owns the Prototype-first interview even when `prd-facts` ran. Before any page question, it must complete the business-object, relation, and lifecycle phases.
3. Generate a kebab-case slug early and resolve existing PRD forms and both prototype paths (`prototype.html`, `prototype/manifest.json`). Apply artifact-layout and prototype-contract conflict handling before any write.
4. Use `fp-prd-grill-me` Prototype-first interview to confirm prototype-blocking decisions: target user/page/workflow, relevant business and UI states, fields/actions/validation, concrete interactions, visual sources, and rendering mode. For project-native, include selected app, baseReference, incremental source/Mock scope and verified build/preview commands with cwd.
5. Show a prototype confirmation summary with the selected mode, canonical path and native source/preview paths, demonstrated behavior, remaining business unknowns, and all write/build/dependency/overwrite effects. Wait for explicit user approval; existing base setup approval is not this approval.
6. Create only the approved change-owned paths and generate the prototype using Prototype Rules. Do not create project-level bases, settings or intel.
7. Report the source and preview paths, verified local preview command/URL, actual verification and limitations. Ask the user to review; do **not** write either PRD Markdown form yet.
8. For requested changes, update prototype source/Mock, rebuild and revalidate the selected prototype; do not patch compiled preview output. Repeat review until explicit confirmation.
9. After prototype confirmation, derive only demonstrated PRD decisions from the confirmed prototype plus interview answers. Apply the Business closure gate and use `fp-prd-grill-me` for remaining Bucket C questions one at a time; do not re-ask confirmed decisions, and never treat an undemonstrated rule as confirmed by the prototype.
10. Select the PRD canonical form and show the final summary with Business closure gate results, entrypoint, fragment ownership and overwrite/conversion/removal actions. Wait for explicit approval.
11. Write the Mandatory PRD Structure verbatim, applying the product-language gate. The owner of `3.N.4 原型` keeps only the product-level prototype slots from the template and distinguishes demonstrated requirements from separately confirmed business decisions; prototype technical metadata stays in manifest/evidence.
12. Run self-review, then report using the Report layering contract.

Do not create directories, write files or run build/preview/install commands before their relevant summary is approved. Prototype-first permits prototype generation before PRD writing, not a bypass of PRD or production implementation gates.

### Existing artifact and conflict handling

Before every PRD write or revision, check `prd.md`, `prd/`, and `prd/00-index.md`:

- If `prd.md` and `prd/` both exist, stop: PRD has no compatible dual-form legacy mode. Ask the user to authorize a migration that transfers all unique content into one canonical form, validates it, and removes the obsolete path.
- If `prd/` exists without `prd/00-index.md`, stop and report the incomplete split artifact.
- If exactly one canonical form exists, preserve it unless the confirmed content requires conversion. State the conversion and obsolete-path removal in the pre-write summary and wait for explicit approval.
- For an existing canonical artifact, ask whether to revise it, overwrite/replace it, or cancel. Do not append content outside the logical template.
- If either prototype form exists, apply prototype-contract resolution, preserve the current mode and ask whether to revise, replace/convert, or cancel. Both forms or an incomplete native directory block prototype work; do not hide conflicts by choosing another filename.

A conversion must transfer all unique content, validate the new logical artifact, and remove the old form before completion so `prd.md` and `prd/` never remain together as Producer output.

## PRD output contract

Do not load the output template during interview turns. After the final PRD confirmation summary is explicitly approved and immediately before writing, read `${CLAUDE_PLUGIN_ROOT}/skills/fp-prd/prd-template.md` completely.

- Small form writes only `prd.md`.
- Split form writes only `prd/00-index.md` and its listed Markdown fragments. Its authoritative fragment manifest uses `| Order | File | Kind | Owns |`; every sibling fragment is listed exactly once, and the index owns navigation/ownership metadata only.
- The two forms are mutually exclusive. Every generated Markdown file, including the index, is at most 500 lines and 30,000 characters.
- Logical concatenation in fragment manifest order must pass logical template validation against the exact Mandatory PRD Structure. Every mandatory heading and table has exactly one owner and appears in canonical order.
- Keep every complete `3.N` feature block in one fragment. Other fragments link to an owner instead of duplicating detailed content.

## Prototype Rules

Generate a prototype only when the Prototype selection gate was satisfied for a page, dialog, complex form/table, wizard, dashboard, or unclear interaction. Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/prototype-contract.md` before choosing paths, generating or reviewing either mode.

Apply **prototype-gitignore-guard** before either mode is written/reused: include the managed-block diff for `fp-docs/.gitignore` and any tracked-prototype disposition in the approval summary, establish the ignore rules first, and verify actual Git ignore/index state. This narrow control-file permission does not authorize other information-layer edits. Prototype source, Mock, preview and evidence are local-only and must not be committed.

- For **static-modular** (default for an existing frontend), copy the base's static assets into the change, then add only this change's own page script, Mock scenarios and entry HTML. Keep `scriptOrder[0]` as the network guard, keep `componentMap` traceable to real components, and keep the entry openable through `file://` — no `type="module"`, no ESM, no CDN. There is no build step, so report `structure`/`directFile` verification instead of a build result.
- For **project-native**, follow Change-local incremental generation and Mock, preview and fidelity gate. Verify the selected base with `CheckFreshness` or equivalent; record `baseReference`, source/Mock entries, commands/cwd and actual evidence. Missing or stale bases route to `/fp-prototype-init`; PRD cannot build or overwrite the shared base. Do not silently fall back to HTML.
- For **standalone-html**, preserve the old single-file HTML/CSS/JS, no-CDN and local-Mock behavior. It is a deliberate single-file lightweight mode, not the default substitute for an existing framework.
- Mode is a user choice, never a failure fallback: a missing builder or a failed build does not authorize switching to `static-modular`, and choosing `static-modular` does not authorize skipping `componentMap` or visual-source checks.
- Apply current project frontend rules and real components/styles through `fp-frontend-spec`; Figma/screenshots and prototype-style provide confirmed constraints, not permission to ignore the current framework. Do not copy a project-family example's standalone output choice into a native project.
- Every confirmed control/field/action must be operable, validation visible, and required loading/empty/success/error/permission states demonstrable. If intentionally static, record why in prototype source; the PRD records only which product conclusions the prototype confirmed and what it did not cover. Unknown business rules return to the interview.
- All business data/state is local Mock; no real backend calls. Native build/preview/network/fidelity verification is separate from real E2E. If a required check cannot run, report the gap rather than completion.

### Prototype Style Consumption and Extraction

Read `fp-docs/settings/prototype-style.md` when present. In native mode, real components/tokens/styles are the rendering source; style settings add approved constraints rather than a second handwritten UI. Missing style settings do not justify neutral replacements for known existing components.

For an explicitly chosen greenfield/standalone prototype with no visual source, use confirmed neutral defaults. After its first accepted prototype, recommend `/fp-init` or a separately approved settings update to extract reusable style. `fp-prd` must not write `settings/prototype-style.md` or `fp-docs/manifest.md`, and it must not offer to re-extract an already registered native base on every requirement.

## Self-Review

Run the structure, business-closure, and product-language checklists in `${CLAUDE_PLUGIN_ROOT}/skills/fp-prd/prd-template.md`. For split form, parse the fragment manifest, read every listed fragment in exact order, reject missing/unindexed/duplicate-owner fragments, and run the same logical template validation over the concatenated logical PRD. Repair presentation defects using confirmed content. If a failure exposes an unresolved product decision, return to `fp-prd-grill-me` and obtain an updated confirmation summary before revising; do not invent rules to make the checklist pass. Report completion only after all three checklists pass.

## Invalid Output Recovery

If self-review finds structural drift or product-language leakage, do not report completion. Rewrite the selected canonical form to conform exactly to Mandatory PRD Structure while preserving confirmed content, converting implementation detail into product language or moving it to its owning artifact. If the resolved prototype lacks confirmed interactions, update its source and rerun required prototype checks before reporting.

## Output

Every successful PRD completion response MUST end with a clearly labeled next-step prompt containing this exact copyable command:

```text
/fp-start <slug>
```

Replace `<slug>` with the completed change slug when it is known. This prompt is required, not optional: never omit it when summarizing, keeping the response concise, reporting a prototype, or reporting non-blocking open questions.

Report through the Report layering contract, by default only:

- PRD canonical entrypoint: `prd.md` or `prd/00-index.md`.
- Core confirmed product scope.
- Prototype entrypoint, when one was generated.
- Non-blocking open questions.
- Required next step: explicitly tell the user they can run `/fp-start <slug>` to resolve the PRD through the shared artifact-layout contract, read split fragments in manifest order when present, and continue into design, planning, and development.

Keep build commands, ports, base versions, hashes, Git state, verification counters, and browser/visual logs in prototype manifest/evidence and the internal report; expand them only when the user asks. For a first greenfield/standalone prototype without registered style, recommend style extraction through `/fp-init`; do not repeat this for an existing native base.
