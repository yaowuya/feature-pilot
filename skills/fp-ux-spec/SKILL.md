---
name: fp-ux-spec
description: Use when a FeaturePilot UI task needs project-specific interaction rules, validation behavior, table actions, dialogs, messages, navigation behavior, or fallback guidance from fp-docs/settings/frontend.md and fp-docs/manifest.md.
---

# FeaturePilot UX Settings

This public plugin does not ship customer-specific interaction rules. UX behavior must come from the target project.

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
