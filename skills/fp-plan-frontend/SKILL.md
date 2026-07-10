---
name: fp-plan-frontend
description: Use when generating frontend FeaturePilot task plans from proposal.md and design-frontend.md, especially for project-configured component libraries, Figma mapping, page, route, state, API, style, and visual-check work.
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.
---

# FeaturePilot Frontend Plan

Generate the frontend implementation plan from confirmed FeaturePilot design artifacts.

## Inputs

Read:

- `fp-docs/manifest.md` if present, followed by only relevant manifest-listed settings/intel
- `fp-docs/changes/<slug>/proposal.md`
- `fp-docs/changes/<slug>/design-frontend.md`
- `fp-docs/settings/agent.md` if present
- `fp-docs/settings/frontend.md` if present
- `fp-docs/settings/prototype-style.md` if prototype/visual behavior is in scope

Treat intel as navigation only; verify current routes, components, scripts, tokens, and commands from source/config files.

If `design-frontend.md` does not exist, stop and explain that this change has no confirmed frontend plan. Do not create frontend placeholders.

## Output

Write:

```text
fp-docs/changes/<slug>/tasks/plan-frontend.md
```

If the plan would exceed 500 lines, split it into smaller files under `fp-docs/changes/<slug>/tasks/` and create `00-overview.md` as the index.

## Planning rules

- Start with `Global Constraints`, extracted from proposal, design, settings, and existing code. Include only concrete values you can cite.
- Do not assume a framework, component prefix, or UI library. Use settings or existing code to identify them.
- Every task must include `Interfaces`: Consumes / Produces / Contract checks.
- Keep dependencies ordered: API/client wrapper → state/composable/store → route/navigation → page skeleton → component details → style/visual refinement → lint/build/visual checks.
- Page/component tasks must carry forward the `design-frontend.md` component mapping and Visual Checks. Do not invent new class names, component choices, tokens, or layout rules during execution.
- If settings and existing code do not answer a visual or interaction decision, mark it as a planning blocker or explicit user question.

## Recommended plan structure

Use `plan-template.md`. Load it only after the plan facts and contracts are derived.

## Task format

Each task must be small enough to implement and review independently and must use the complete Task format in `plan-template.md`.

## Invalid plans

Revise the plan if any of these appear:

- Empty placeholders such as `TBD`, `TODO`, `按需处理`, `类似上面`, `实现页面`, or `补充样式`.
- Framework, component library, component prefix, token, or test command not sourced from settings or existing code.
- Component tasks without concrete Interfaces and Contract checks.
- Visual Checks that cannot be traced to `design-frontend.md`, settings, Figma, screenshot, or existing code.
- Verification steps that only say “run tests” or “check page” without exact command/path/expected result.

## Self-review

Before returning to `fp-plan`, verify:

1. Every frontend/UI requirement from proposal and design maps to a task.
2. Settings were read or explicitly absent.
3. Component/library/framework assumptions are sourced.
4. Backend/frontend contracts match design.
5. Visual continuity is preserved.
6. Commands are executable in the target project.
