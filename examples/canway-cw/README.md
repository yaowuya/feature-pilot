# Canway / CW FeaturePilot init example

This directory contains an explicitly labelled FeaturePilot example for Canway / CW-style projects.

It is **not** a global default for the public FeaturePilot plugin. `/fp-init` may offer to copy these files into a target project's `fp-docs/settings/` only when it heuristically detects a Canway / CW project and the user explicitly opts in.

## Example settings

```text
examples/canway-cw/fp-docs/settings/
  agent.md             # Lightweight workflow adapter
  backend.md           # Backend/API/data/security conventions
  frontend.md          # Frontend implementation + UI + UX conventions
  prototype-style.md   # HTML prototype visual/interaction style
```

## Coverage mapping

| Requested area | Example file | Notes |
|---|---|---|
| Backend specs / 后端规范 | `fp-docs/settings/backend.md` | Backend stack signals, API/service/data conventions, security, permissions, validation expectations, Unknowns |
| Frontend specs / 前端规范 | `fp-docs/settings/frontend.md` | Vue/frontend stack signals, implementation rules, commands, current-code verification expectations |
| UI specs / UI 规范 | `fp-docs/settings/frontend.md` | Component preferences, visual tokens, layout, forms, tables, dialogs, drawers, empty/error states |
| UX specs / UX 规范 | `fp-docs/settings/frontend.md` | Interaction rules, validation timing, loading/empty/error/permission states, feedback and copy rules |
| Prototype visual/interaction style | `fp-docs/settings/prototype-style.md` | Single-file HTML prototype shell, colors, typography, layout, component patterns, interactions, copy |

`frontend.md` intentionally contains frontend implementation guidance plus UI and UX rules; `prototype-style.md` is only for HTML prototype visual and interaction consistency.

## Adoption rules

When copied into a target project:

- Treat these files as editable initial drafts.
- Verify exact current implementation details against the target project's code before planning or editing.
- Preserve existing target-project settings unless the user explicitly approves overwrite.
- Use `Unknown` instead of inventing project-specific facts.
