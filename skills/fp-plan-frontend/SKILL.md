---
name: fp-plan-frontend
description: Use when generating frontend FeaturePilot task plans from proposal.md and the canonical frontend design entrypoint/fragments, especially for project-configured component libraries, Figma mapping, page, route, state, API, style, and visual-check work.
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.
---

# FeaturePilot Frontend Plan

Generate the frontend implementation plan from confirmed FeaturePilot design artifacts.

## Canonical design layout

前端设计稳定入口是 `fp-docs/changes/<slug>/design/frontend.md`。若 `design/frontend/00-index.md` 存在，无论稳定入口是否显式链接它，都必须读取该索引列出的全部编号分片后才能规划；缺失任一分片即停止并报告。

## Legacy read compatibility

仅当 canonical entrypoint 不存在时，允许只读回退到 `fp-docs/changes/<slug>/design-frontend.md`。不得创建或修改旧路径。

## Inputs

Read:

- `fp-docs/manifest.md` if present, followed by only relevant manifest-listed settings/intel
- `fp-docs/changes/<slug>/proposal.md`
- 按 canonical-first 规则解析的完整前端设计
- `fp-docs/settings/agent.md` if present
- `fp-docs/settings/frontend.md` if present
- `fp-docs/settings/prototype-style.md` if prototype/visual behavior is in scope

Treat intel as navigation only; verify current routes, components, scripts, tokens, and commands from source/config files.

If neither the canonical nor legacy frontend design entrypoint exists, stop and explain that this change has no confirmed frontend plan. Do not create frontend placeholders.

## Output

Write the stable frontend entrypoint:

```text
fp-docs/changes/<slug>/tasks/plan-frontend.md
```

Small frontend plans keep all executable tasks in this stable file. If the frontend plan exceeds 500 lines, `plan-frontend.md` keeps Global Constraints, component/state/style/visual summaries, coverage, and navigation but no executable task checkbox; detailed executable tasks must be split into:

```text
fp-docs/changes/<slug>/tasks/frontend/00-index.md
fp-docs/changes/<slug>/tasks/frontend/01-<topic>.md
fp-docs/changes/<slug>/tasks/frontend/02-<topic>.md
```

Split fragments use deterministic numbered filenames, are listed in `tasks/frontend/00-index.md` in execution order, and should stay <=200 lines where practical. Read `../fp-plan/task-layout-template.md` when splitting and use its per-end index schema. Each executable task checkbox exists exactly once: either in `plan-frontend.md` for a small plan or in one numbered frontend fragment for a split plan. `plan-frontend.md` and `tasks/frontend/00-index.md` must not duplicate executable task checkboxes.

Use stable task IDs `frontend-001`, `frontend-002`, ... across the whole frontend plan. Numbering continues across fragments and never resets per file. Return every `(task ID, owner file, dependencies)` tuple to `fp-plan` so it can build `tasks/00-overview.md`; this end-specific skill does not write the change-level overview.

## Planning rules

- Start with `Global Constraints`, extracted from proposal, design, settings, and existing code. Include only concrete values you can cite.
- Do not assume a framework, component prefix, or UI library. Use settings or existing code to identify them.
- Every task must include `Interfaces`: Consumes / Produces / Contract checks.
- Keep dependencies ordered: API/client wrapper → state/composable/store → route/navigation → page skeleton → component details → style/visual refinement → lint/build/visual checks.
- Page/component tasks must carry forward the resolved frontend design component mapping and Visual Checks. Do not invent new class names, component choices, tokens, or layout rules during execution.
- If settings and existing code do not answer a visual or interaction decision, mark it as a planning blocker or explicit user question.

## Recommended plan structure

Use `plan-template.md`. Load it only after the plan facts and contracts are derived.

## Task format

Each task must be small enough to implement and review independently and must use the complete Task format in `plan-template.md`, including the unique task-level `- [ ] **Task frontend-NNN: ...**` marker plus `Depends on`. Subsections such as Visual / UX Checks must not use checkbox syntax.

## Invalid plans

Revise the plan if any of these appear:

- Empty placeholders such as `TBD`, `TODO`, `按需处理`, `类似上面`, `实现页面`, or `补充样式`.
- Framework, component library, component prefix, token, or test command not sourced from settings or existing code.
- Component tasks without concrete Interfaces and Contract checks.
- Visual Checks that cannot be traced to the resolved frontend design, settings, Figma, screenshot, or existing code.
- Verification steps that only say “run tests” or “check page” without exact command/path/expected result.

## Self-review

Before returning to `fp-plan`, verify:

1. Every frontend/UI requirement from proposal and design maps to a task.
2. Settings were read or explicitly absent.
3. Component/library/framework assumptions are sourced.
4. Backend/frontend contracts match design.
5. Visual continuity is preserved.
6. Commands are executable in the target project.
7. If `tasks/frontend/00-index.md` exists, every listed fragment exists, no unindexed fragment exists, order is deterministic, no consumer needs glob order, and every executable task checkbox appears exactly once with none in the stable entrypoint or index.
8. `frontend-NNN` IDs are unique across all owner files, continue across fragments, and dependencies reference existing IDs; after execution begins, plan revisions do not silently move or renumber tasks.
