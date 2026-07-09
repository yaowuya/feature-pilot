# FeaturePilot (`fp`) for Codex and other agents

FeaturePilot is an AI feature-development guide that runs the lifecycle:

`需求 → 原型/设计 → 计划 → 执行 → 归档`

This repository is a Claude Code plugin, but Codex can use the same command and skill files as plain Markdown process instructions. Current release: `0.3.0`.

## How to use in Codex

Codex does not run Claude Code plugins or slash commands directly. Treat `/fp-*` names as workflow labels that map to Markdown files in `skills/` and `commands/`. When the user asks to run FeaturePilot, read the matching skill file before acting:

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

## 0.3.0 release behavior

This release documents the current FeaturePilot gates for both Claude Code and Codex:

- `fp-prd` is an interview workflow, not a one-shot PRD generator: Bucket A/B confirmed items are reviewed in one batch, Bucket C unresolved decisions are asked sequentially one at a time, assistant recommendations are not user confirmation, and the assistant must never self-answer Bucket C.
- PRD-first mode must complete the PRD interview gate and receive explicit approval of the confirmation summary before writing `fp-docs/changes/<slug>/prd.md`.
- Prototype-first mode applies when the user wants to see/adjust a prototype first or the requirement is UI-heavy: confirm prototype-blocking decisions, write `prototype.html`, wait for user confirmation, then ask remaining PRD-blocking questions and write `prd.md`.
- Generated intel under `fp-docs/intel/` is stale-prone navigation only. Use current code/search/command output for current-state facts.
- Do not bulk-read settings, intel, historical changes, archive, or history files; read the smallest relevant subset for the current phase.

## Workspace and settings

Before choosing output paths, component-library guidance, test commands, or workflow behavior, treat the target project repository root as the FeaturePilot project root and look only for `fp-docs/` directly under that root:

1. If `fp-docs/manifest.md` exists directly under the target project root, read it first.
2. Do **not** walk upward to reuse a parent directory's `fp-docs/`.
3. Do **not** bulk-read all `fp-docs/settings/` or `fp-docs/intel/` files. Read only the smallest relevant subset for the current phase/question.
4. If UI/frontend/prototype behavior is involved and `fp-docs/settings/frontend.md` or `fp-docs/settings/prototype-style.md` exists, read only the relevant sections as required sources.
5. If backend/API/data/security behavior is involved and `fp-docs/settings/backend.md` exists, read only the relevant sections as required sources.
6. Treat generated intel as stale-prone navigation, not proof of current behavior. If intel is stale or broad, verify just-in-time from current source files.
7. If the information layer is absent, fall back to current project code, adjacent implementations, and public defaults only.
8. Do not create, overwrite, or rewrite customer manifest/settings/intel unless the user explicitly asks.
9. Do not assume any customer component library, vendor, component prefix, design token, backend framework, or workflow policy in public workflow behavior.

Information layer structure:

```text
fp-docs/
  manifest.md               # FeaturePilot 信息层唯一入口
  settings/
    agent.md                # 可选：轻量 FeaturePilot policy adapter
    frontend.md             # 可选：前端/UI/视觉/设计系统规则
    backend.md              # 可选：后端/API/数据/安全规则
    prototype-style.md      # 可选：原型视觉风格参考
  intel/                    # 生成的 source-backed 但 stale-prone 的导航线索
```

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

1. `/fp-init` when the project has no `fp-docs/` workspace or wants the full information layer (`fp-docs/manifest.md` as single entry point, optional `fp-docs/settings/agent.md`/`frontend.md`/`backend.md`/`prototype-style.md`, `fp-docs/intel/`).
2. For `/fp-prd <idea>`, use PRD-first by default; use Prototype-first when the user asks to see/adjust a prototype first or the requirement is UI-heavy.
3. `/fp-prd` must not create directories or write `prd.md`/`prototype.html` before the relevant confirmation summary is explicitly approved.
4. `/fp-start <slug>` to pick up the PRD and continue into proposal, design, plan, execution, review, and archive.
5. If `fp-init` detects a likely Canway/CW project, it may only ask whether to adopt labelled examples from `examples/canway-cw/fp-docs/settings/` as editable target-project settings. It must not auto-copy them, overwrite existing files, or treat them as public defaults.

For the user-facing init/prd/start guide, see `docs/user_guide/init-prd-start.md`.

## Mandatory gates

Do not skip phases unless the selected skill explicitly allows it.

1. Generate and confirm `fp-docs/changes/<slug>/prd.md` through `fp-prd` when starting from a rough idea. Use the mandatory PRD template and never write PRDs outside `fp-docs/changes/<slug>/prd.md`.
2. Generate and confirm `fp-docs/changes/<slug>/proposal.md`.
3. Generate and confirm design files under `fp-docs/changes/<slug>/`.
4. Generate and confirm task plans under `fp-docs/changes/<slug>/tasks/`.
5. Execute tasks using the confirmed task files, not chat summaries.
6. Review and archive when complete, using `fp-docs/archive/`, and `fp-docs/history/history.md` as the canonical archive/spec/history locations.

## Naming

Use the `fp-*` namespace for FeaturePilot commands and skills.
