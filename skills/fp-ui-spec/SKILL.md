---
name: fp-ui-spec
description: Use when a FeaturePilot UI task needs project-specific visual rules, design tokens, component-library constraints, or fallback guidance from fp-docs/settings/frontend.md and fp-docs/manifest.md.
---

# FeaturePilot UI Settings

This public plugin does not ship customer-specific UI tokens or component-library rules.

## FeaturePilot workspace and information layer

If any anchored plugin resource is missing or unreadable, stop, report the exact resource and an incomplete FeaturePilot installation/cache, and never search the consumer repository for `skills/**` or continue without it.
下文以 `${CLAUDE_PLUGIN_ROOT}/...` 表示 Claude Code 安装后的插件资源。在 Codex/Markdown 中，从 available-skill 元数据提供的当前技能入口映射同一个 `skills/...` 插件相对路径。两端都不得在消费者项目中搜索插件文件。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy UI settings, stale-intel evidence, precedence, and public-plugin neutrality. Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` before resolving or contributing to a frontend design; it owns exclusive forms, split manifests, hard limits, and historical structural-conflict rejection. There is no compatibility fallback.

## Required source of truth

Before making UI visual decisions, read the target project's configuration:

1. `fp-docs/settings/frontend.md` — component library, design tokens, Figma mapping rules, visual states.
2. `fp-docs/settings/prototype-style.md` — prototype visual style reference, when prototype/Figma visual continuity is relevant.
3. `fp-docs/settings/agent.md` — general project policy (fallback when frontend.md is absent).
4. Existing project code — adjacent pages, shared components, style variables, package dependencies.

If settings are absent, do not invent a design system. Infer only from existing code and ask the user when visual requirements are ambiguous.

## What to extract

Record concrete values in the design or plan only when they come from settings, Figma, screenshot evidence, or existing code:

- Component library name and import/component prefixes.
- Color tokens, typography, spacing, radius, shadow, z-index, breakpoints.
- Form/table/button/dialog/message/loading/empty-state rules.
- Accessibility and responsive behavior.
- Visual checks that can be verified during execution.

## Public-plugin constraints

- Do not assume any customer component prefix or vendor.
- Do not hardcode customer colors, component names, screenshots, or Figma files.
- If settings mention a component library, use those names exactly.
- If settings are missing, prefer existing in-repo shared components over new custom components.

## Output requirement

Resolve the chosen canonical frontend representation before contributing design content. When used for the canonical frontend design, preserve the form selected by `fp-brainstorm`: small form is only `design/frontend.md`; split form is only `design/frontend/00-index.md` plus manifest-listed fragments. `design/00-index.md` points directly to the selected entry. Do not create both forms.

Producer dual-form input is a structural conflict and must be rejected; this helper must not choose one side or continue writing. Place this source note with the single detailed owner of `Visual Source`, component mapping, and `Visual Checks`: in `design/frontend.md` for small form, or in one manifest-listed detail fragment for split form. Each visual section has exactly one detailed owner, forming the unique visual owner; indexes contain only navigation and ownership metadata. Every design file, including indexes and fragments, must stay within **500 lines** and **30,000 characters**; crossing either hard fallback limit requires another semantic split.

```markdown
#### UI Settings Source
- Settings read: `fp-docs/settings/frontend.md` / `fp-docs/settings/prototype-style.md` / `fp-docs/settings/agent.md` / not present
- Existing references: <paths inspected>
- Confirmed tokens/components: <list>
- Unknowns requiring user confirmation: <list or none>
```
