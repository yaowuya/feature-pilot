# FeaturePilot (`fp`) for Codex and other agents

FeaturePilot is an AI feature-development guide that runs the lifecycle:

`需求 → 原型/设计 → 计划 → 执行 → 归档`

This repository is both a Claude Code plugin and a Codex plugin. Codex loads the same skills through `.codex-plugin/plugin.json`, while this file remains the plain-Markdown fallback and repository contract. Current release: `0.3.0`.

## How to use in Codex

Codex does not run Claude Code slash commands directly. Treat `/fp-*` names as workflow labels that map to plugin skills in `skills/` and thin Claude adapters in `commands/`. When the user asks to run FeaturePilot, read the matching skill file before acting:

| User intent | Read first |
|---|---|
| Initialize workspace/config | `skills/fp-init/SKILL.md` |
| Read-only exploration of repository facts, behavior, constraints, risks, or options | `skills/fp-explore/SKILL.md` |
| Full feature workflow | `skills/fp-start/SKILL.md` |
| Explicit `/fp-prd`, `$fp-prd`, or explicit request to create, write, revise, or complete a PRD or product requirements document | `skills/fp-prd/SKILL.md` |
| Proposal only | `skills/fp-propose/SKILL.md` |
| Technical design | `skills/fp-brainstorm/SKILL.md` |
| Implementation plan | `skills/fp-plan/SKILL.md` |
| Execute confirmed plan | `skills/fp-execute/SKILL.md` or `skills/fp-execute-sdd/SKILL.md` |
| Final review | `skills/fp-review/SKILL.md` |
| Archive completed change | `skills/fp-archive/SKILL.md` |

## 0.3.0 release behavior

This release documents the current FeaturePilot gates for both Claude Code and Codex:

- Use fp-prd only when the user explicitly invokes /fp-prd or $fp-prd, or explicitly asks to create, write, revise, or complete a PRD or product requirements document.
- An ordinary idea, feature request, user story, pain point, or rough requirement does not trigger PRD authoring by itself.
- `fp-prd` is an interview workflow, not a one-shot PRD generator: Bucket A/B confirmed items are reviewed in one batch, Bucket C unresolved decisions are asked sequentially one at a time, assistant recommendations are not user confirmation, and the assistant must never self-answer Bucket C.
- PRD-first mode must complete the PRD interview gate and receive explicit approval of the confirmation summary before writing the resolved PRD small or split form.
- Prototype-first mode applies when the user wants to see/adjust a prototype first or the requirement is UI-heavy: confirm prototype-blocking decisions, write `prototype.html`, wait for user confirmation, then ask remaining PRD-blocking questions and write the resolved PRD small or split form.
- Generated intel under `fp-docs/intel/` is stale-prone navigation only. Use current code/search/command output for current-state facts.
- `fp-explore` accepts natural-language public input and remains read-only: it never writes artifacts, implements changes, or automatically dispatches another workflow. Its internal structured profiles may be invoked only by `fp-prd`, `fp-start`, and `fp-quick`, which retain their own product, routing, approval, and implementation gates.
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

Use `fp-docs/changes/<slug>/` as the review unit for a feature. Every logical artifact uses exactly one mutually exclusive canonical form:

| Logical artifact | Small form | Split form |
|---|---|---|
| PRD | `prd.md` | `prd/00-index.md` plus indexed fragments |
| Proposal | `proposal.md` | `proposal/00-index.md` plus indexed fragments |
| Backend design | `design/backend.md` | `design/backend/00-index.md` plus indexed fragments |
| Frontend design | `design/frontend.md` | `design/frontend/00-index.md` plus indexed fragments |
| Backend plan | `tasks/plan-backend.md` | `tasks/backend/00-index.md` plus indexed fragments |
| Frontend plan | `tasks/plan-frontend.md` | `tasks/frontend/00-index.md` plus indexed fragments |

产物形式采用紧凑优先（compact-first）且 small/split 互斥：预计完整逻辑产物不超过 500 行和 30,000 字符时默认使用 small form；只有预计超过任一硬限制、用户明确批准 split form，或目标项目设置明确要求 split form 时才拆分。功能、子系统、页面区域、任务组或 ownership domain 只用于拆分后的语义边界，不单独触发拆分。

FeaturePilot 过程文档的叙述性内容默认使用中文；代码、命令、路径、技术标识符、API 字段和契约要求精确匹配的 schema 关键词保留必要英文。当前用户明确语言指令优先于目标项目设置。

Every produced Markdown file, including indexes and fragments, continues to have hard limits of 500 lines and 30,000 characters; exceeding either limit requires another semantic split.

`design/00-index.md` maps only the design ends that exist to their direct canonical entrypoints. `tasks/00-overview.md` is a two-end-only overview: it exists exactly when both backend and frontend plans exist; a single-end plan never has an overview. It contains only the two canonical end entrypoints, cross-end dependencies or stages, and progress totals derived from unique owner checkboxes. `.fp-execute/` holds execution ledgers, task briefs, packages, and reviews, but never becomes a second completion authority.

Consumers resolve canonical small and split paths before reading. There is no read-only compatibility for root-level `design-backend.md` / `design-frontend.md` or former stable-file-plus-directory pairs. Producer and Consumer modes reject every dual structure; migration must merge or transfer required content into one canonical form and delete obsolete paths before work continues.

When archiving, preserve history under `fp-docs/archive/YYYY-MM-DD-<slug>/` and summarize the change in `fp-docs/history/history.md`.

## Low-cost flow

Preferred path:

1. `/fp-explore <question>` when the user wants read-only investigation or option comparison before choosing a workflow; empty input performs bounded orientation only.
2. `/fp-init` when the project has no `fp-docs/` workspace or wants the full information layer (`fp-docs/manifest.md` as single entry point, optional `fp-docs/settings/agent.md`/`frontend.md`/`backend.md`/`prototype-style.md`, `fp-docs/intel/`).
3. For `/fp-prd <idea>`, use PRD-first by default; use Prototype-first when the user asks to see/adjust a prototype first or the requirement is UI-heavy.
4. `/fp-prd` must not create directories or write `prd.md`/`prototype.html` before the relevant confirmation summary is explicitly approved.
5. `/fp-start <slug>` to pick up the PRD and continue into proposal, design, plan, execution, review, and archive.
6. If `fp-init` detects a likely Canway/CW project, it may only ask whether to adopt labelled examples from `examples/canway-cw/fp-docs/settings/` as editable target-project settings. It must not auto-copy them, overwrite existing files, or treat them as public defaults.

For the user-facing init/prd/start guide, see `docs/user_guide/init-prd-start.md`.

## Mandatory gates

Do not skip phases unless the selected skill explicitly allows it.

1. Run and confirm `fp-prd` only under the exact public trigger contract above. Use the mandatory logical PRD template and write exactly one canonical form: `fp-docs/changes/<slug>/prd.md` or `fp-docs/changes/<slug>/prd/00-index.md` plus its manifest-ordered fragments.
2. Generate and confirm exactly one proposal form: `proposal.md` or `proposal/00-index.md` plus its manifest-ordered fragments.
3. Generate and confirm the direct canonical design entrypoints under `design/`, choosing the small file or split directory form before writing.
4. Generate and confirm the direct canonical task-plan entrypoints under `tasks/`, choosing the small file or split directory form before writing, with every stable task ID and checkbox owned by exactly one file.
5. Execute tasks using the confirmed task files, not chat summaries.
6. Review and archive when complete, using `fp-docs/archive/`, and `fp-docs/history/history.md` as the canonical archive/spec/history locations.

## Naming

Use the `fp-*` namespace for FeaturePilot commands and skills.
