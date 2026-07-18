---
name: fp-ux-spec
description: Use when a FeaturePilot UI task needs project-specific interaction rules, validation behavior, table actions, dialogs, messages, navigation behavior, or fallback guidance from fp-docs/settings/frontend.md and fp-docs/manifest.md.
---

# FeaturePilot UX Settings

This public plugin does not ship customer-specific interaction rules. UX behavior must come from the target project.

## FeaturePilot workspace and information layer

If any anchored plugin resource is missing or unreadable, stop, report the exact resource and an incomplete FeaturePilot installation/cache, and never search the consumer repository for `skills/**` or continue without it.

Read `${CLAUDE_SKILL_DIR}/../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy UX settings, stale-intel evidence, precedence, and public-plugin neutrality. Read `${CLAUDE_SKILL_DIR}/../_shared/artifact-layout.md` before resolving or contributing to a frontend design; it owns exclusive forms, split manifests, hard limits, and historical structural-conflict rejection. There is no compatibility fallback.

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
- UX checks to carry into the canonical frontend design (`design/frontend.md` or indexed fragments), task plans, execution, and review.

## Public-plugin constraints

- Do not assume a customer component library or vendor-specific interaction API.
- Do not hardcode customer colors, component names, message APIs, or modal APIs.
- If settings define project-specific behavior, use it exactly and cite the setting file.
- If behavior is not configured and not visible in existing code, mark it as a design question.

## Output requirement

Resolve the chosen canonical frontend representation before contributing design content. When used for canonical frontend design, preserve the form selected by `fp-brainstorm`: small form is only `design/frontend.md`; split form is only `design/frontend/00-index.md` plus manifest-listed fragments. `design/00-index.md` points directly to the selected entry. Do not create both forms.

Producer dual-form input is a structural conflict and must be rejected; this helper must not choose one side or continue writing. Place this source note with the single detailed owner of `Visual Source`, component mapping, and `Visual Checks`: in `design/frontend.md` for small form, or in one manifest-listed detail fragment for split form. Each visual section has exactly one detailed owner, forming the unique visual/interaction owner; indexes contain only navigation and ownership metadata. Every design file, including indexes and fragments, must stay within **500 lines** and **30,000 characters**; crossing either hard fallback limit requires another semantic split.

When used for planning instead, include the source note in the plan's relevant detailed owner and follow that plan's artifact-layout rules; do not create or revise design files from the planning helper call.

```markdown
#### UX Settings Source
- Settings read: `fp-docs/settings/frontend.md` / `fp-docs/settings/prototype-style.md` / `fp-docs/settings/agent.md` / not present
- Existing interaction references: <paths inspected>
- Confirmed UX rules: <list>
- Open interaction questions: <list or none>
```
