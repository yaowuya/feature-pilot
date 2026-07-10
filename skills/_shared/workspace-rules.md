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
- Canonical design layout: new design artifacts live under `fp-docs/changes/<slug>/design/`. `design/00-index.md` is the change-level design index; `design/backend.md` and `design/frontend.md` are stable per-end entrypoints when those ends are in scope. If either entrypoint would exceed 500 lines, keep it as a concise summary/index and split details into `design/backend/00-index.md` + numbered subsystem files or `design/frontend/00-index.md` + numbered area files; keep each file at or below 200 lines where practical.
- Canonical task layout: small task plans keep executable tasks in stable files `fp-docs/changes/<slug>/tasks/plan-backend.md` and/or `tasks/plan-frontend.md`. If an end-specific plan exceeds 500 lines, keep its stable file as concise constraints/navigation/coverage and move executable tasks into `tasks/backend/00-index.md` + deterministic numbered fragments, or `tasks/frontend/00-index.md` + deterministic numbered fragments; keep fragments at or below 200 lines where practical. Create `tasks/00-overview.md` when both ends are planned or either end is split; it owns cross-end order, dependencies, coverage, and progress roll-up without executable checkboxes. A single small end needs no overview or empty directories.
- Task checkbox authority: every executable task uses one stable end-prefixed ID and exactly one real task-list marker such as `- [ ] **Task backend-001: ...**`, located in the small stable plan or one numbered fragment. IDs continue across fragments and do not restart per file. `tasks/00-overview.md`, per-end indexes, and split stable entrypoints must not copy executable task checkboxes. Overview progress counts are derived roll-ups that must be recomputed from owner checkboxes, never independent state.
- Split task consumers must resolve task-owner files by per-end index existence: if `tasks/backend/00-index.md` or `tasks/frontend/00-index.md` exists, read the stable entrypoint, the index, and every indexed fragment in listed order; block on missing or unindexed fragments, duplicate task IDs/checkboxes, or task checkboxes in summary/index files. Do not depend on entrypoint links, recursive globs, or filesystem order.
- `.fp-execute/progress.md` is an append-only recovery/evidence log, not a second completion authority. The single checkbox in the resolved task-owner file is the planned completion state. On mismatch, inspect the owner file, git history, tests, and actual implementation, then reconcile checkbox and ledger before continuing; never declare completion from a ledger-only record or blindly re-execute it.
- Legacy read compatibility: consumers may read existing root-level `design-backend.md` / `design-frontend.md` only when the canonical entrypoint for that end is absent. Producers must never create or update those legacy paths.
- `fp-archive` may only move the confirmed active change to `fp-docs/archive/` and update `fp-docs/history/history.md` after its confirmation gate.
