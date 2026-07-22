# FeaturePilot Shared Workspace Contract

Read this file once per FeaturePilot workflow. Reuse it when later `fp-*` skills reference it; do not reload it in the same workflow.

## Root and read order

1. Treat the target repository root as the FeaturePilot project root. Look for `fp-docs/` only directly under that root; never inherit a parent workspace.
2. If `fp-docs/manifest.md` exists, read it first as an index.
3. Read only the smallest relevant manifest-listed settings/intel for the current phase. Never bulk-read settings, intel, historical changes, archive, or history.
4. For UI/frontend/prototype work, read relevant sections of `settings/frontend.md` and, when generating prototypes, `settings/prototype-style.md` if present.
5. For backend/API/data/security work, read relevant sections of `settings/backend.md` if present.

## Process document language

- Write FeaturePilot-generated process-document prose in Chinese by default, including titles, explanations, decisions, requirements, task descriptions, acceptance text, review findings, and archive/history summaries.
- Language precedence is: current explicit user instruction, then an explicit target-project setting, then Chinese by default. A project setting never overrides the current user's explicit language request.
- Preserve necessary English for code, commands, file paths, package/class/function/variable names, API fields, protocol terms, standard technical terms, and schema headings or enum values that another contract requires to match exactly.

## Evidence and precedence

- Generated intel is stale-prone navigation, never proof of current behavior. Revalidate exact files, contracts, commands, components, routes, permissions, and schemas from current source/config/command output.
- Current code and command output win for current-state facts. Approved PRD/proposal/design/tasks win for target-state requirements.
- Public skills must not hardcode customer vendors, component libraries/prefixes, design tokens, backend frameworks, API envelopes, or workflow policy. Put customer rules in target-project settings.

## Optional CodeGraph route

需要定位代码、符号、调用链、数据流、影响范围或相关源码候选时，按需读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/codegraph.md`。CodeGraph 只加速候选定位；不可用时继续现有搜索，不降低当前源码验证、读取预算、只读和授权边界。无需代码调查的阶段不得为了“预热”而加载、安装或构建代码图。

## Compatibility and ownership

- Missing `fp-docs/manifest.md` does not block normal workflows. Recommend `/fp-init`, continue from current code/settings when safe, and create only artifacts owned by the active phase.
- Only `fp-init` may create or repair project-level `manifest.md`, `settings/`, or `intel/`, and it requires approval before overwriting existing files.
- Requirement/design/plan/execution phases may write only the active change under `fp-docs/changes/<slug>/` plus its execution state.
- Artifact layout is governed by the mandatory artifact-layout contract already loaded by the owning skill. Every PRD, proposal, design, and task-plan Producer or Consumer must follow it for canonical paths, semantic splitting, safety limits, manifests, ownership, overview rules, resolution, and historical structural-conflict rejection. There is no compatibility fallback.
- `.fp-execute/progress.md` is an append-only recovery/evidence log, not a second completion authority. The single checkbox in the resolved task-owner file is the planned completion state. On mismatch, inspect the owner file, git history, tests, and actual implementation, then reconcile checkbox and ledger before continuing; never declare completion from a ledger-only record or blindly re-execute it.
- `fp-archive` may only move the confirmed active change to `fp-docs/archive/` and update `fp-docs/history/history.md` after its confirmation gate.
