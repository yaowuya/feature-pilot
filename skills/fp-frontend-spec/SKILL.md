---
name: fp-frontend-spec
description: Use when a FeaturePilot UI task needs project-specific visual rules, design tokens, component-library constraints, interaction rules, validation behavior, or fallback guidance from fp-docs/settings/frontend.md, prototype-style.md, and fp-docs/manifest.md.
---

# FeaturePilot Frontend Spec

This public plugin does not ship customer-specific UI tokens, component-library rules, or interaction rules. UI/UX behavior must come from the target project.

## FeaturePilot workspace and information layer

插件资源锚定、`${CLAUDE_PLUGIN_ROOT}` 路径映射与缺失即停止规则见 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md`；不要在消费者项目中搜索 `skills/**`。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy UI settings, stale-intel evidence, precedence, and public-plugin neutrality. Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` before resolving or contributing to a frontend design; it owns exclusive forms, split manifests, hard limits, and historical structural-conflict rejection. There is no compatibility fallback.

## Required source of truth

Before making UI visual or interaction decisions, read the target project's configuration:

1. `fp-docs/settings/frontend.md` — component library, design tokens, Figma mapping rules, visual states, UX rules, component behavior, visual/interaction acceptance checks.
2. `fp-docs/settings/prototype-style.md` — prototype visual style reference and prototype behavior, when prototype/Figma visual continuity or UX acceptance is relevant.
3. `fp-docs/settings/agent.md` — general project policy (fallback when frontend.md is absent).
4. Existing project code — adjacent pages, shared components, style variables, package dependencies, forms, tables, dialogs, messages, navigation, and error handling.

If settings are absent, do not invent a design system. Infer only from existing code and ask the user when visual requirements are ambiguous or behavior changes product semantics.

## Native prototype context

用于基座/需求原型时读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/prototype-contract.md`，只读取当前 app 的基座 manifest 和实际相关组件/样式/providers。已有前端使用同框架真实组件，不从文字风格重新仿写 HTML；检查版本、样式入口、字体/图标、布局、路由/国际化上下文和 Mock 隔离。

基座 metadata 是来源指针，不覆盖当前源码或人工约束；过期时报告并交由 `/fp-prototype-init` 按批准刷新。输出来源说明放在调用方的基座证据或 `3.N.4 原型` 内，不为原型另建 frontend design 文件。原型的 Mock/截图不充当真实 E2E 或 Figma 专属 UI 证据。

## What to extract

Record concrete values in the design or plan only when they come from settings, Figma, screenshot evidence, or existing code:

- Component library name and import/component prefixes.
- Color tokens, typography, spacing, radius, shadow, z-index, breakpoints.
- Form/table/button/dialog/message/loading/empty-state rules.
- Form validation timing and error placement.
- Button hierarchy, disabled/loading behavior, and destructive-action confirmation.
- Table sorting, filtering, selection, pagination, empty/loading/error states.
- Dialog, drawer, popover, tooltip, message, and notification behavior.
- Navigation, permissions, keyboard/accessibility, and responsive behavior.
- Visual and UX checks to carry into the canonical frontend design (`design/frontend.md` or indexed fragments), task plans, execution, and review.

## Public-plugin constraints

- Do not assume a customer component library or vendor-specific interaction API.
- Do not hardcode customer colors, component names, message APIs, or modal APIs.
- Do not assume any customer component prefix or vendor.
- If settings define project-specific behavior, use it exactly and cite the setting file.
- If behavior is not configured and not visible in existing code, mark it as a design question.
- If settings are missing, prefer existing in-repo shared components over new custom components.

## Output requirement

Resolve the chosen canonical frontend representation before contributing design content. When used for canonical frontend design, preserve the form selected by `fp-brainstorm`: small form is only `design/frontend.md`; split form is only `design/frontend/00-index.md` plus manifest-listed fragments. `design/00-index.md` points directly to the selected entry. Do not create both forms.

Producer dual-form input is a structural conflict and must be rejected; this helper must not choose one side or continue writing. Place this source note with the single detailed owner of `Visual Source`, component mapping, and `Visual Checks`: in `design/frontend.md` for small form, or in one manifest-listed detail fragment for split form. Each visual section has exactly one detailed owner, forming the unique visual owner and the unique visual/interaction owner; indexes contain only navigation and ownership metadata. Every design file, including indexes and fragments, must stay within **500 lines** and **30,000 characters**; crossing either hard fallback limit requires another semantic split.

When used for planning instead, include the source note in the plan's relevant detailed owner and follow that plan's artifact-layout rules; do not create or revise design files from the planning helper call.

```markdown
#### UI/UX Settings Source
- Settings read: `fp-docs/settings/frontend.md` / `fp-docs/settings/prototype-style.md` / `fp-docs/settings/agent.md` / not present
- Existing references: <paths inspected>
- Confirmed tokens/components: <list>
- Confirmed UX rules: <list>
- Unknowns requiring user confirmation: <list or none>
```
