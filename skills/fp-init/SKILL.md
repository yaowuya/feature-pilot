---
name: fp-init
description: Use when a project is adopting FeaturePilot for the first time, needs an fp-docs workspace, or wants guided creation of optional fp-docs/settings/agent.md configuration.
---

# FeaturePilot Init

`fp-init` bootstraps FeaturePilot with low setup cost. Settings are optional: a project can use FeaturePilot with only `fp-docs/changes/`, and can add `fp-docs/settings/agent.md` later when conventions need to be explicit.

## OpenSpec-inspired init principles

Borrow these initialization patterns:

- **Minimal tree first**: create only the directories needed to start working.
- **Helpful next steps**: always end with concrete next commands, not abstract advice.
- **Existing-file safety**: detect existing settings and ask before changing them.
- **Marker-ready content**: generated `agent.md` should be easy to update later by section, with stable headings and no hidden state.
- **Low ceremony**: settings remain optional; the user can start with `/fp-prd` immediately.

## Goals

- Create the minimal `fp-docs/` workspace.
- Explain the workflow: `/fp-prd` clarifies requirements; `/fp-start` picks up a PRD or feature description and drives design → plan → execution.
- Optionally generate `fp-docs/settings/agent.md` from project facts and user confirmation.
- Never overwrite existing customer settings without explicit approval.

## Workspace structure

```text
fp-docs/
  settings/
    agent.md        # optional project-specific guidance
  changes/
  archive/
  agents/
    history.md
```

## Process

### 1. Locate or create workspace

Walk upward from the current working directory to find `fp-docs/`.

If absent, create only:

- `fp-docs/settings/`
- `fp-docs/changes/`
- `fp-docs/archive/`
- `fp-docs/agents/`
- `fp-docs/agents/history.md` if it does not exist

Do not create sample changes.

### 2. Check existing settings

If `fp-docs/settings/agent.md` exists:

- Read it.
- Summarize key settings.
- Ask before changing it.

If it does not exist, ask whether to generate it:

```markdown
FeaturePilot can run without settings. I can optionally generate `fp-docs/settings/agent.md` so future PRD/design/plan/execution steps know this project's conventions.

Choose one:
1. Generate settings now — inspect current project and write a draft for review.
2. Skip settings — use code/context inference only for now.
```

### 3. Generate optional `settings/agent.md`

Only if the user chooses generation:

1. Read lightweight project facts:
   - root README / AGENTS / CLAUDE files if present
   - package/build/test config files if present
   - top-level source/test directories
   - nearby UI/API/store/router conventions when discoverable cheaply
2. Do not run package install, build, tests, or external network calls during init.
3. Write a draft with this structure:

```markdown
# FeaturePilot Project Agent Settings

## Project Overview

- Product/domain:
- Primary users:
- Main tech stack:

## Source and Test Paths

- Backend/source:
- Frontend/source:
- Tests:
- API/client modules:
- Routes/navigation:
- State/store:

## Workflow Rules

- Preferred verification commands:
- Review gates:
- Commit policy:
- Branch/PR expectations:

## UI and Design System

- Component library:
- Design tokens/source:
- Figma/screenshot rules:
- Visual checks:

## Security and Data Rules

- Permission model:
- Sensitive data:
- Audit/logging:
- Multi-tenant/data isolation:

## FeaturePilot Preferences

- Default flow: `/fp-prd` for requirement design, then `/fp-start` for development.
- Small-change policy:
- SDD execution preference:

## Unknowns

- <facts that could not be inferred and should be confirmed later>
```

Use `Unknowns` instead of guessing.

### 4. Report next steps

After init, report:

- Workspace path.
- Whether `settings/agent.md` exists or was generated.
- Any unknowns.
- Suggested next command:
  - `/fp-prd <idea>` for requirement design.
  - `/fp-start <slug or feature description>` to continue into development.

## Guardrails

- Do not make settings mandatory.
- Do not hardcode a customer component library, vendor, component prefix, design token, or workflow policy.
- Do not overwrite existing settings without explicit user approval.
- Do not create `fp-docs/changes/<slug>/` during init unless the user explicitly asks.
- Keep generated settings concise and editable.
