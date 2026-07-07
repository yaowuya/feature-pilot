---
name: fp-plan-frontend
description: Use when generating frontend FeaturePilot task plans from proposal.md and design-frontend.md, especially for project-configured component libraries, Figma mapping, page, route, state, API, style, and visual-check work.
---

## FeaturePilot workspace and customer settings

Before choosing output paths, component-library guidance, test commands, or workflow rules, locate the target project's FeaturePilot workspace:

1. Walk upward from the current working directory to find `fp-docs/`.
2. If it does not exist and this phase needs to create artifacts, initialize the minimal tree: `fp-docs/settings/`, `fp-docs/changes/`, `fp-docs/archive/`, `fp-docs/agents/`.
3. Read any settings files that exist. Do not create or overwrite customer settings unless the user explicitly asks.
4. If settings are absent, fall back to current project code, adjacent implementations, and public defaults only; never invent customer-specific conventions.

Recommended settings file:

- `fp-docs/settings/agent.md` — optional project-specific FeaturePilot rules, including workflow, paths, component library, design system, UI tokens, Figma mapping, and visual review requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, frontend framework, design token, or workflow policy in public skills. Customer-specific rules may be described in optional `fp-docs/settings/agent.md`.

---

# FeaturePilot Frontend Plan

Generate the frontend implementation plan from confirmed FeaturePilot design artifacts.

## Inputs

Read:

- `fp-docs/changes/<slug>/proposal.md`
- `fp-docs/changes/<slug>/design-frontend.md`
- `fp-docs/settings/agent.md` if present

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

```markdown
# <Feature> Frontend Plan

## Global Constraints
- Framework/runtime: <from settings/package/existing code>
- Component library/design system: <from fp-docs/settings/agent.md or existing code>
- Script/style conventions: <from settings or existing code>
- Visual source: <Figma / screenshot / existing page / settings>
- Verification commands: <from settings/agent.md or package scripts>

## 1. Page goal and visual contract

## 2. Component tree and template outline

## 3. State/API/interaction design

## 4. Style and responsive design

## 5. Visual and UX checks

## 6. Task breakdown
```

## Task format

Each task must be small enough to implement and review independently.

```markdown
### Task N: <component or behavior>

**Files:**
- Create: `exact/path/to/new-file`
- Modify: `exact/path/to/existing-file`
- Test: `exact/path/to/test-file`

**Reasoning:**
- Why this task is independent.
- Which proposal/design requirement it covers.
- What observable UI or behavior changes after completion.

**Interfaces:**
- Consumes: <existing or prior task API/state/route/component/visual contract>
- Produces: <new API/state/route/component/classes/events/visual structure>
- Contract checks: <how to verify the contract>

**Template Outline:**
- Use the project component names from settings or existing code.
- Include container hierarchy, slots, props, and events when relevant.

**Script/State Outline:**
- Use the project-standard script/state pattern.
- Define state, derived values, lifecycle/data loading, and event handlers.

**Style Outline:**
- Use project tokens/classes/mixins when configured.
- Specify layout strategy and key spacing only when sourced.

**Visual / UX Checks:**
- [ ] <check traceable to design-frontend.md, settings, Figma, screenshot, or existing code>
```

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
