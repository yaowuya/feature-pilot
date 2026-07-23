---
name: fp-plan-frontend
description: Use when generating frontend FeaturePilot task plans from the resolved logical proposal and canonical frontend design representation, especially for project-configured component libraries, Figma mapping, page, route, state, API, style, and visual-check work.
---
## FeaturePilot workspace and information layer

If any anchored plugin resource is missing or unreadable, stop, report the exact resource and an incomplete FeaturePilot installation/cache, and never search the consumer repository for `skills/**` or continue without it.
下文以 `${CLAUDE_PLUGIN_ROOT}/...` 表示 Claude Code 安装后的插件资源。在 Codex/Markdown 中，从 available-skill 元数据提供的当前技能入口映射同一个 `skills/...` 插件相对路径。两端都不得在消费者项目中搜索插件文件。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` before resolving or writing the frontend plan. Its mutually exclusive canonical forms, semantic split selection, 500 lines / 30,000 characters hard limits, manifest schema, ownership rules, and Producer/Consumer compatibility boundaries are mandatory.
---

# FeaturePilot Frontend Plan

Generate the frontend implementation plan from confirmed FeaturePilot design artifacts.

## Canonical input resolution

Resolve the proposal representation before reading either form: detect `proposal.md` and `proposal/00-index.md`, reject dual or malformed state as a structural conflict, then read the small file or every split fragment in complete manifest order.

Resolve the frontend design representation before reading either form: detect `design/frontend.md` and `design/frontend/00-index.md`, reject dual or malformed state as a structural conflict, then read the small file or every split fragment in complete manifest order. If the parent supplied resolved logical content, canonical entrypoint, mode, and ordered fragment paths, verify them against disk before using them. Never discover split content from a stable-file body link.

## Historical layout blocker

检测到 `fp-docs/changes/<slug>/design-frontend.md` 时，立即作为 structural conflict 阻塞，不读取其正文。必须先明确批准迁移到 `design/frontend.md` 或 `design/frontend/00-index.md`、删除旧路径并验证，之后才能规划。

## Inputs

Read:

- `fp-docs/manifest.md` if present, followed by only relevant manifest-listed settings/intel
- resolved logical proposal content、canonical entrypoint、mode 与 ordered fragment paths
- 按 canonical-first 规则解析的完整前端设计
- `fp-docs/settings/agent.md` if present
- `fp-docs/settings/frontend.md` if present
- `fp-docs/settings/prototype-style.md` if prototype/visual behavior is in scope

Treat intel as navigation only; verify current routes, components, scripts, tokens, and commands from source/config files.

If no canonical frontend design entrypoint exists, stop and explain that this change has no confirmed frontend plan. A historical entrypoint is a blocker, not a usable input state. Do not create frontend placeholders.

## Output

Before writing, inspect the small file, split index, and historical paths. Block every historical or dual structure as a structural conflict; after migration, select one mutually exclusive canonical form:

```text
Small form: fp-docs/changes/<slug>/tasks/plan-frontend.md
Split form: fp-docs/changes/<slug>/tasks/frontend/00-index.md plus indexed fragments
```

The two forms are mutually exclusive. Small form keeps the complete logical plan and all executable tasks in `plan-frontend.md`; it does not create `tasks/frontend/`. Split form writes only the end directory and must not create or retain `plan-frontend.md`. For this end-local plan, default to the small form while the complete plan is expected to fit within 500 lines and 30,000 characters. Select split form only when the small plan is expected to exceed either limit, the user explicitly approves split form, or an applicable target-project setting explicitly requires it. Task groups, page areas, and ownership domains define fragments only after split form has been selected. A representation in which any produced Markdown file exceeds 500 lines or 30,000 characters is invalid; every produced file must stay within both hard limits.

For split form, use semantic task-kind fragments rather than mechanically cutting a monolith:

```text
fp-docs/changes/<slug>/tasks/frontend/00-index.md
fp-docs/changes/<slug>/tasks/frontend/01-context.md
fp-docs/changes/<slug>/tasks/frontend/05-interfaces.md
fp-docs/changes/<slug>/tasks/frontend/10-<topic>-tasks.md
fp-docs/changes/<slug>/tasks/frontend/90-coverage.md
```

Read `${CLAUDE_PLUGIN_ROOT}/skills/fp-plan/task-layout-template.md` when splitting and use its authoritative `Order / File / Kind / Owns` manifest. The `context` fragment uniquely owns the header, goal, Global Constraints, file structure, page goal, and visual context. The `interface` fragment uniquely owns component, state, API, route, interaction, style, responsive, and Visual / UX contracts. One or more `tasks` fragments uniquely own the logical TDD task bodies. The `coverage` fragment uniquely owns proposal/design/visual coverage and verification mapping. The index contains navigation and ownership metadata only; every sibling Markdown fragment is listed exactly once.

Each executable task checkbox exists exactly once: in `plan-frontend.md` for small form or one `tasks`-kind fragment for split form. Split `00-index.md`, `context`, `interface`, and `coverage` fragments contain no executable checkbox. When converting an existing canonical form, transfer all unique content, validate the new representation, and remove the obsolete form. Never produce the historical stable-file-plus-directory combination.

Use stable task IDs `frontend-001`, `frontend-002`, ... across the whole frontend plan. Numbering continues across fragments and never resets per file. Return every `(task ID, owner file, dependencies)` tuple to `fp-plan` for whole-graph validation and derived totals. Only when both ends exist may `fp-plan` write `tasks/00-overview.md`, and it publishes only cross-end edges/stages and derived totals; this end-specific skill never writes the overview.

## Planning rules

- Start with `Global Constraints`, extracted from proposal, design, settings, and existing code. Include only concrete values you can cite.
- In small form, Global Constraints and file structure belong to `plan-frontend.md`; in split form, their unique owner is the `context` fragment.
- Do not assume a framework, component prefix, or UI library. Use settings or existing code to identify them.
- Every task must include `Interfaces`: Consumes / Produces / Contract checks.
- In split form, the `interface` fragment is the unique detailed owner for component/state/API/route/interaction/style/visual contracts; task `Interfaces` link to those contracts without copying their bodies.
- Keep dependencies ordered: API/client wrapper → state/composable/store → route/navigation → page skeleton → component details → style/visual refinement → lint/build/visual checks.
- Page/component tasks must carry forward the resolved frontend design component mapping and Visual Checks. Do not invent new class names, component choices, tokens, or layout rules during execution.
- If settings and existing code do not answer a visual or interaction decision, mark it as a planning blocker or explicit user question.
- 每个需要视觉验收的 task 都必须携带 case-level `Visual Evidence Manifest`。每个 Case ID 记录 Approved design source、Figma node、revision/time、Frame/variant、可用的 variables / Auto Layout / assets、Runtime route、Scenario/state、Viewport、DPR、Locale、Theme、Deterministic non-sensitive fixture、Reference path、Current path、Diff path、Mask、Acceptance rule、Command/tool 与 Failure class。标准目录是 `.fp-execute/visual/<task-id>/<case-id>/`，包含 `manifest.md`、`reference.png`、`current.png`，`diff.png` 可选。
- `reference.png` 必须来自 approved Figma/static design source；local runtime screenshot must not replace 它。`current.png` 必须来自 real target runtime 的实际 route，使用 stable data 与 stable environment。optional diff 缺失时写明 missing diff，且 must not hide source/runtime 缺失。
- Browser interaction evidence 与 screenshot evidence 必须 separate；observable flow 要操作到 manifest 中的 approved states，不能用点击成功替代视觉对比。
- 优先使用 project-configured Playwright/browser runner 或等价浏览器工具，不硬编码框架或命令，do not define a global pixel threshold。若缺 browser runner，计划中新增 explicit task 并取得 authorization；do not silently install 依赖。

- Provenance: reference.png -> approved Figma/static design source; current.png -> real target runtime.
- Local runtime screenshot must not replace reference.png. current.png requires stable data and stable environment. Optional diff/missing diff explanation must not hide absent core source/runtime evidence.
- Evidence channels: browser interaction evidence is separate from screenshot evidence; browser interaction evidence must exercise approved states, and screenshot evidence must record case artifacts.

## Recommended plan structure

Use `${CLAUDE_PLUGIN_ROOT}/skills/fp-plan-frontend/plan-template.md`. Load it only after the plan facts and contracts are derived.

## Task format

Each task must be small enough to implement and review independently and must use the complete Task format in `${CLAUDE_PLUGIN_ROOT}/skills/fp-plan-frontend/plan-template.md`, including the unique task-level `- [ ] **Task frontend-NNN: ...**` marker plus `Depends on`. Subsections such as Visual / UX Checks must not use checkbox syntax.

## Invalid plans

Revise the plan if any of these appear:

- Empty placeholders such as `TBD`, `TODO`, `按需处理`, `类似上面`, `实现页面`, or `补充样式`.
- Framework, component library, component prefix, token, or test command not sourced from settings or existing code.
- Component tasks without concrete Interfaces and Contract checks.
- Visual Checks that cannot be traced to the resolved frontend design, settings, Figma, screenshot, or existing code.
- Core visual case 缺少 approved source、real runtime、稳定 fixture 或可重放命令；仅给 reason 不能替代证据。
- Verification steps that only say “run tests” or “check page” without exact command/path/expected result.

## Self-review

Before returning to `fp-plan`, verify:

1. Every frontend/UI requirement from proposal and design maps to a task.
2. Settings were read or explicitly absent.
3. Component/library/framework assumptions are sourced.
4. Backend/frontend contracts match design.
5. Visual continuity is preserved.
6. Commands are executable in the target project.
7. If `tasks/frontend/00-index.md` exists, `plan-frontend.md` does not exist; the manifest uses `Order / File / Kind / Owns`; every listed fragment exists, no unindexed fragment exists, order is deterministic, no consumer needs glob order, and every executable task checkbox appears exactly once only in a `tasks`-kind fragment, with none in the index/context/interface/coverage files.
8. `frontend-NNN` IDs are unique across all owner files, continue across fragments, and dependencies reference existing IDs; after execution begins, plan revisions do not silently move or renumber tasks.
9. Every output file is within 500 lines and 30,000 characters; small form has no `tasks/frontend/`, and a single-end frontend plan has no `tasks/00-overview.md`.
