---
name: fp-ux-spec
description: Use when a FeaturePilot UI task needs project-specific interaction rules, validation behavior, table actions, dialogs, messages, navigation behavior, or fallback guidance from fp-docs/settings/frontend.md and fp-docs/manifest.md.
---

# FeaturePilot UX Settings

This public plugin does not ship customer-specific interaction rules. UX behavior must come from the target project.

## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy UX settings, stale-intel evidence, precedence, and public-plugin neutrality.

## Required source of truth

Before deciding interaction behavior, read:

1. `fp-docs/settings/frontend.md` — UX rules, component behavior, visual/interaction acceptance checks.
2. `fp-docs/settings/prototype-style.md` — prototype behavior or visual-style decisions when they affect UX acceptance.
3. `fp-docs/settings/agent.md` — general project policy (fallback when frontend.md is absent).
4. Existing project code — adjacent forms, tables, dialogs, messages, navigation, and error handling.

If settings are absent, infer only from existing code. Ask the user when behavior changes product semantics or when no reliable project pattern exists.

## What to extract

Capture concrete project rules for:

- Form validation timing and error placement.
- Button hierarchy, disabled/loading behavior, and destructive-action confirmation.
- Table sorting, filtering, selection, pagination, empty/loading/error states.
- Dialog, drawer, popover, tooltip, message, and notification behavior.
- Navigation, permissions, keyboard/accessibility, and responsive behavior.
- UX checks to carry into `design-frontend.md`, task plans, execution, and review.

## Public-plugin constraints

- Do not assume a customer component library or vendor-specific interaction API.
- Do not hardcode customer colors, component names, message APIs, or modal APIs.
- If settings define project-specific behavior, use it exactly and cite the setting file.
- If behavior is not configured and not visible in existing code, mark it as a design question.

## Output requirement

When used for frontend design or planning, include:

```markdown
#### UX Settings Source
- Settings read: `fp-docs/settings/frontend.md` / `fp-docs/settings/prototype-style.md` / `fp-docs/settings/agent.md` / not present
- Existing interaction references: <paths inspected>
- Confirmed UX rules: <list>
- Open interaction questions: <list or none>
```
