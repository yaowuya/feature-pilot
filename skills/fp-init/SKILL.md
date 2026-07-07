---
name: fp-init
description: Use when a project is adopting FeaturePilot for the first time, needs an fp-docs workspace, or wants guided creation of optional fp-docs/settings/agent.md and frontend_design.md configuration.
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
- Optionally generate `fp-docs/settings/agent.md` from project facts and user confirmation (only if no existing CLAUDE.md / AGENTS.md exists).
- Optionally generate `fp-docs/settings/frontend_design.md` from frontend project facts and user confirmation.
- Never overwrite existing customer settings without explicit approval.

## Workspace structure

```text
fp-docs/
  settings/
    agent.md                # optional project-specific guidance
    frontend_design.md      # optional frontend design system settings
```
`fp-docs/changes/`、`fp-docs/archive/`、`fp-docs/history/` 由后续阶段按需自动创建，`fp-init` 不预建。


## Process

### 1. Locate or create workspace

Walk upward from the current working directory to find `fp-docs/`.

If absent, create only:

- `fp-docs/settings/`

Do **not** create `fp-docs/changes/`、`fp-docs/archive/`、`fp-docs/history/` or any sample files — those are created on-demand by later phases (`fp-prd`/`fp-propose`/`fp-archive`).

### 2. Check existing project-level agent/docs

Before offering to generate settings, check the project root and `.claude/` / `.cursor/` / `.gemini/` for these files (in priority order):

1. `CLAUDE.md` (root or `.claude/CLAUDE.md`)
2. `AGENTS.md` (root or `.agents/AGENTS.md`)
3. `GEMINI.md`
4. `CURSOR.md` / `.cursorrules`

If **any** of these exist:

- Read them silently.
- Report: \"检测到项目已有 `xxx.md`，FeaturePilot 将直接引用该文件作为 agent 配置，无需在 `fp-docs/settings/agent.md` 中重复生成。\"
- Skip `agent.md` generation entirely, and move to **Step 3-b (frontend_design.md)**.

If **none** exist, ask whether to generate `agent.md`:

```markdown
未检测到项目级 agent 文件（CLAUDE.md / AGENTS.md 等）。是否在 `fp-docs/settings/agent.md` 中为 FeaturePilot 生成一份轻量项目配置？

选项：
1. 生成 — 根据当前项目结构自动推断并写入草案供你确认。
2. 跳过 — 后续用代码和上下文推断即可。
```

### 3-a. Generate optional `settings/agent.md`

Only if the user chose generation in step 2 and no existing project-level agent/docs file was found.

Same generation rules as before (lightweight project facts, no package install, draft with stable headings).

### 3-b. Offer frontend design settings

After handling `agent.md` (or skipping it), always ask:

```markdown
是否需要生成前端规范配置文件 `fp-docs/settings/frontend_design.md`？

该文件包含：
- 组件库与组件映射
- 设计 token（色彩/字号/间距/圆角/阴影）
- Figma 还原规则
- 视觉验收检查点
- 布局策略（Flex/Grid）

选项：
1. 生成 — 根据项目现有前端代码、依赖和规范自动推断并写入草案供你确认。
2. 跳过 — 后续前端设计步骤会从现有页面和 UI/UX spec 推断。
```

If the user chooses to generate `frontend_design.md`:

1. Read lightweight project frontend facts:
   - `package.json` / `pyproject.toml` for UI dependencies
   - existing Vue/React component files
   - existing style/theme/token files
   - existing UI/UX spec files if any
2. Write a draft to `fp-docs/settings/frontend_design.md` with:

```markdown
# FeaturePilot Frontend Design Settings

## Component Library

- 主库:
- 组件前缀:
- 禁用/不推荐:
- 自封装规则:

## Design Tokens

- 色彩:
- 字号:
- 间距:
- 圆角:
- 阴影:

## Figma 还原规则

- 设计稿来源:
- 节点/页面映射规则:
- 截图还原规则:

## 布局策略

- 默认布局:
- 响应式断点:
- 禁止事项:

## 视觉验收检查点

- 通用检查项:
- 项目特有检查项:

## Unknowns

- <事实不足以推断、需后续确认的项>
```

Use `Unknowns` instead of guessing.

### 4. Report next steps

After init, report:

- Workspace path.
- Whether `settings/agent.md` exists, was generated, or was skipped (because project already has CLAUDE.md / AGENTS.md).
- Whether `settings/frontend_design.md` was generated or skipped.
- Any unknowns.
- Suggested next command:
  - `/fp-prd <idea>` for requirement design.
  - `/fp-start <slug or feature description>` to continue into development.

## Guardrails

- Do not make settings mandatory.
- Do not hardcode a customer component library, vendor, component prefix, design token, or workflow policy.
- Do not overwrite existing settings without explicit user approval.
- Do not create `fp-docs/changes/<slug>/` during init unless the user explicitly asks.
- When project root already has `CLAUDE.md` or `AGENTS.md`, reference it directly instead of duplicating content into `agent.md`.
- Keep generated settings concise and editable.
