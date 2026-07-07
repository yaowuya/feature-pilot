---
name: fp-ui-spec
description: Use when a FeaturePilot UI task needs project-specific visual rules, design tokens, component-library constraints, or fallback guidance from fp-docs/settings/agent.md.
---

# FeaturePilot UI Settings

This public plugin does not ship customer-specific UI tokens or component-library rules.

## Required source of truth

Before making UI visual decisions, read the target project's configuration:

1. `fp-docs/settings/agent.md` — component library, design tokens, Figma mapping rules, visual states.
2. `fp-docs/settings/agent.md` — frontend source paths and neighboring pages/components.
3. Existing project code — adjacent pages, shared components, style variables, package dependencies.

If `fp-docs/settings/agent.md` is absent, do not invent a design system. Infer only from existing code and ask the user when visual requirements are ambiguous.

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

When used for `design-frontend.md`, include a short source note:

```markdown
#### UI Settings Source
- Settings read: `fp-docs/settings/agent.md` / not present
- Existing references: `<paths inspected>`
- Confirmed tokens/components: `<list>`
- Unknowns requiring user confirmation: `<list or none>`
```
