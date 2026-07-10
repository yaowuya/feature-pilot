# FeaturePilot Shared Workspace Contract

Read this file once per FeaturePilot workflow. Reuse it when later `fp-*` skills reference it; do not reload it in the same workflow.

## Root and read order

1. Treat the target repository root as the FeaturePilot project root. Look for `fp-docs/` only directly under that root; never inherit a parent workspace.
2. If `fp-docs/manifest.md` exists, read it first as an index.
3. Read only the smallest relevant manifest-listed settings/intel for the current phase. Never bulk-read settings, intel, historical changes, archive, or history.
4. For UI/frontend/prototype work, read relevant sections of `settings/frontend.md` and, when generating prototypes, `settings/prototype-style.md` if present.
5. For backend/API/data/security work, read relevant sections of `settings/backend.md` if present.

## Evidence and precedence

- Generated intel is stale-prone navigation, never proof of current behavior. Revalidate exact files, contracts, commands, components, routes, permissions, and schemas from current source/config/command output.
- Current code and command output win for current-state facts. Approved PRD/proposal/design/tasks win for target-state requirements.
- Public skills must not hardcode customer vendors, component libraries/prefixes, design tokens, backend frameworks, API envelopes, or workflow policy. Put customer rules in target-project settings.

## Compatibility and ownership

- Missing `fp-docs/manifest.md` does not block normal workflows. Recommend `/fp-init`, continue from current code/settings when safe, and create only artifacts owned by the active phase.
- Only `fp-init` may create or repair project-level `manifest.md`, `settings/`, or `intel/`, and it requires approval before overwriting existing files.
- Requirement/design/plan/execution phases may write only the active change under `fp-docs/changes/<slug>/` plus its execution state.
- `fp-archive` may only move the confirmed active change to `fp-docs/archive/` and update `fp-docs/history/history.md` after its confirmation gate.
