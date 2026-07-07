# FeaturePilot (`fp`) for Codex and other agents

FeaturePilot is an AI feature-development guide that runs the lifecycle:

`需求 → 设计 → 计划 → 执行 → 归档`

This repository is a Claude Code plugin, but Codex can use the same command and skill files as plain Markdown process instructions.

## How to use in Codex

When the user asks to run FeaturePilot, read the matching skill file before acting:

| User intent | Read first |
|---|---|
| Initialize workspace/config | `skills/fp-init/SKILL.md` |
| Full feature workflow | `skills/fp-start/SKILL.md` |
| PRD from rough idea | `skills/fp-prd/SKILL.md` |
| Proposal only | `skills/fp-propose/SKILL.md` |
| Technical design | `skills/fp-brainstorm/SKILL.md` |
| Implementation plan | `skills/fp-plan/SKILL.md` |
| Execute confirmed plan | `skills/fp-execute/SKILL.md` or `skills/fp-execute-sdd/SKILL.md` |
| Final review | `skills/fp-review/SKILL.md` |
| Archive completed change | `skills/fp-archive/SKILL.md` |

## Workspace and settings

Before choosing output paths, component-library guidance, test commands, or workflow behavior, locate the target project's FeaturePilot workspace:

1. Walk upward from the current working directory to find `fp-docs/`.
2. If `fp-docs/` does not exist and the selected phase needs to create artifacts, create only the directories this phase actually writes to. Do not pre-create empty directories for other phases. Most phases only need `fp-docs/changes/`. Only `fp-archive` creates `fp-docs/archive/` and `fp-docs/history/`. `fp-init` only creates `fp-docs/settings/`.
3. Read `fp-docs/settings/agent.md` if it exists. It may contain project-specific FeaturePilot rules, component/design-system guidance, checks, review gates, source/test paths, and workflow preferences.
4. If settings are absent, fall back to current project code, adjacent implementations, and public defaults only.
5. Do not create, overwrite, or rewrite customer settings unless the user explicitly asks.
6. Do not assume any customer component library, vendor, component prefix, design token, or workflow policy in public workflow behavior.

## OpenSpec-inspired artifact model

Use `fp-docs/changes/<slug>/` as the review unit for a feature. Keep artifacts together:

- `prd.md` — product requirement design from `/fp-prd`.
- `proposal.md` — concise development intent, scope, and impact.
- `design-*.md` — technical approach and architecture decisions.
- `tasks/` — implementation checklist.
- `.fp-execute/` — execution ledger, task briefs, packages, and reviews.

When archiving, preserve history under `fp-docs/archive/YYYY-MM-DD-<slug>/` and summarize the change in `fp-docs/history/history.md`.

## Low-cost flow

Preferred path:

1. `/fp-init` when the project has no `fp-docs/` workspace or wants optional `settings/agent.md` guidance.
2. `/fp-prd <idea>` to complete requirement design in `fp-docs/changes/<slug>/prd.md`.
3. `/fp-start <slug>` to pick up the PRD and continue into proposal, design, plan, execution, review, and archive.

## Mandatory gates

Do not skip phases unless the selected skill explicitly allows it.

1. Generate and confirm `fp-docs/changes/<slug>/proposal.md`.
2. Generate and confirm design files under `fp-docs/changes/<slug>/`.
3. Generate and confirm task plans under `fp-docs/changes/<slug>/tasks/`.
4. Execute tasks using the confirmed task files, not chat summaries.
5. Review and archive when complete, using `fp-docs/archive/`, and `fp-docs/history/history.md` as the canonical archive/spec/history locations.

## Naming

Use the `fp-*` namespace for FeaturePilot commands and skills.
