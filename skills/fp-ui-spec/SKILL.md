---
name: fp-ui-spec
description: Use when a FeaturePilot UI task needs project-specific visual rules, design tokens, component-library constraints, or fallback guidance from fp-docs/settings/frontend.md and fp-docs/manifest.md.
---

# FeaturePilot UI Settings

This public plugin does not ship customer-specific UI tokens or component-library rules.

## FeaturePilot workspace and information layer

Before choosing output paths, commands, UI/backend rules, or workflow behavior:

1. Treat the target project repository root as the FeaturePilot project root, and look only for `fp-docs/` directly under that root.
2. If `fp-docs/manifest.md` exists, read it first.
3. Do **not** bulk-read all `fp-docs/settings/` or `fp-docs/intel/` files. Read only the smallest relevant subset for the current phase/question.
4. If UI/frontend/prototype behavior is involved and `fp-docs/settings/frontend.md` or `fp-docs/settings/prototype-style.md` exists, read only the relevant sections as required sources.
5. If backend/API/data/security behavior is involved and `fp-docs/settings/backend.md` exists, read only the relevant sections as required sources.
6. Treat generated intel as stale-prone navigation, not proof of current behavior. If intel is stale or broad, verify just-in-time from current source files.
7. Use two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, backend framework, API envelope, or workflow policy in public skills. Customer-specific rules belong in target-project settings.

Compatibility rule: if the project root has no `fp-docs/manifest.md`, continue from current code and existing settings when safe, recommend `/fp-init`, and do not force initialization. If the current phase must write FeaturePilot artifacts, create only the necessary artifact directories under the project-root `fp-docs/`; do not create manifest/settings/intel except through `/fp-init`.

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

When used for `design-frontend.md`, include a short source note:

```markdown
#### UI Settings Source
- Settings read: `fp-docs/settings/frontend.md` / `fp-docs/settings/prototype-style.md` / `fp-docs/settings/agent.md` / not present
- Existing references: <paths inspected>
- Confirmed tokens/components: <list>
- Unknowns requiring user confirmation: <list or none>
```
