---
name: fp-init
description: Use when a project is adopting FeaturePilot for the first time, needs a single-manifest fp-docs information layer, wants guided creation of optional fp-docs/settings/agent.md, frontend.md, backend.md configuration, or may adopt labelled project-family examples such as Canway/CW settings.
---

## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting. For this skill, apply its `fp-init` ownership exception: only init may create or repair project-level `fp-docs/manifest.md`, settings, and intel, and existing files require explicit overwrite approval.

# FeaturePilot Init

`fp-init` bootstraps a FeaturePilot information layer with low setup cost. It creates the minimal skeleton and optionally guides the user through lightweight read-only discovery to populate `fp-docs/intel/`.

## Goals

- Create the FeaturePilot information layer skeleton: `fp-docs/manifest.md` (single entry point), `fp-docs/settings/`, and `fp-docs/intel/`.
- Explain the workflow: `/fp-prd` clarifies requirements; `/fp-start` picks up a PRD or feature description and drives design → plan → execution.
- Optionally generate lean `fp-docs/settings/agent.md` (general FeaturePilot policy adapter), `fp-docs/settings/frontend.md` (frontend/UI/visual), `fp-docs/settings/backend.md` (backend/API/data/security), and/or `fp-docs/settings/prototype-style.md` (prototype visual style reference) with user confirmation.
- Optionally run lightweight read-only discovery to populate `fp-docs/intel/*` with source-backed project facts.
- Never overwrite existing customer manifest/settings/intel without explicit approval.

## OpenSpec-inspired init principles

- **Single entry point**: `fp-docs/manifest.md` is the only manifest. No `settings/manifest.md` or `intel/manifest.md`.
- **Minimal tree first**: create only the directories needed to start working.
- **Helpful next steps**: always end with concrete next commands, not abstract advice.
- **Existing-file safety**: detect existing settings and ask before changing them.
- **Marker-ready content**: generated files use stable headings and `Unknown` placeholders instead of guesses.
- **Low ceremony**: settings remain optional; the user can start with `/fp-prd` immediately.
- **Lean agent.md**: `settings/agent.md` keeps only general FeaturePilot policy; frontend/backend domain detail goes to `frontend.md` / `backend.md`.

## Workspace structure

```text
fp-docs/
  manifest.md                # Single global entry point: read order, precedence, artifacts, freshness
  settings/
    agent.md                 # Optional lean FeaturePilot policy adapter
    frontend.md              # Optional UI/frontend/visual/design-system settings
    backend.md               # Optional backend/API/data/security settings
    prototype-style.md       # Optional prototype visual style reference
  intel/
    sources-and-provenance.md
    workspace-map.md
    tech-stack.md
    commands-and-quality-gates.md
    architecture-and-boundaries.md
    contracts.md
    security-data-and-ops.md
    unknowns-and-decisions.md
    refresh-policy.md
    sdd-handoff.md
```

`fp-docs/changes/`、`fp-docs/archive/`、`fp-docs/history/` 由后续阶段按需自动创建，`fp-init` 不预建。

---

## Process

### 1. Locate or create workspace

Treat the target project repository root as the FeaturePilot project root. `fp-init` must create and manage `fp-docs/` only at:

```text
<project-root>/fp-docs/
```

Do not walk upward to reuse or create a parent directory's `fp-docs/`. If the current working directory is a subdirectory, first identify the repository/project root, then create the workspace there.

If absent at the project root, create only:

- `fp-docs/`
- `fp-docs/settings/`
- `fp-docs/intel/`

Do **not** create `fp-docs/changes/`、`fp-docs/archive/`、`fp-docs/history/` or any sample files — those are created on-demand by later phases (`fp-prd`/`fp-propose`/`fp-archive`).

### 2. Create skeleton information layer

If missing, create the skeleton files below. Existing files are never overwritten without explicit approval.

Use the exact skeleton templates in `templates.md`:

| Target file | Template section |
| --- | --- |
| `fp-docs/manifest.md` | `FeaturePilot Manifest` |
| `fp-docs/intel/unknowns-and-decisions.md` | `Unknowns and Decisions` |
| `fp-docs/intel/refresh-policy.md` | `Refresh Policy` |
| `fp-docs/intel/sdd-handoff.md` | `SDD Handoff` |

### 3. Check existing project-level agent/docs

Before offering to generate settings, check the project root and `.claude/` / `.cursor/` / `.gemini/` for these files (in priority order):

1. `CLAUDE.md` (root or `.claude/CLAUDE.md`)
2. `AGENTS.md` (root or `.agents/AGENTS.md`)
3. `GEMINI.md`
4. `CURSOR.md` / `.cursorrules`

If **any** of these exist:

- Read them silently.
- Record discovered paths in `fp-docs/manifest.md` External Project Docs table.
- Report: "检测到项目已有 `xxx.md`，FeaturePilot 已在 `fp-docs/manifest.md` 中记录引用，不会在 `fp-docs/settings/agent.md` 中重复内容。"

Note: `fp-docs/manifest.md` is always created or updated regardless of whether external project docs exist. FeaturePilot normalization via the manifest should not be skipped.

### 4. Detect labelled project-family examples

After checking project docs, run only a small read-only project-family signal check. If no plausible signal exists, continue generic init without loading extra context. If a signal exists, read `project-family-examples.md` and follow its confidence, consent, selective-copy, and overwrite rules.

### 5. Ask about optional settings

After updating the manifest and handling any accepted project-family example, offer optional settings files.

#### 5-a. Offer `settings/agent.md`

Ask:

```markdown
是否需要生成 `fp-docs/settings/agent.md`（轻量 FeaturePilot policy adapter）？

该文件仅包含通用工作流策略：
- 权威项目文档引用
- 工作流偏好
- 通用允许/禁止区域
- 通用验证期望
- 跨领域安全/数据说明

前端细节进 `fp-docs/settings/frontend.md`，后端细节进 `fp-docs/settings/backend.md`。

选项：
1. 生成 — 创建轻量 adapter 模板，你可以后续编辑。
2. 跳过 — 后续从当前代码和 manifest 推断即可。
```

If the user chooses to generate, write the `FeaturePilot Agent Settings` template from `templates.md`.

#### 5-b. Offer `settings/frontend.md`

Ask:

```markdown
是否需要生成 `fp-docs/settings/frontend.md`？

该文件包含：
- 前端框架与源代码位置
- 组件库与导入规则
- 设计 token 来源
- 路由/状态/API-client 模式
- Figma 映射规则
- 本地预览与视觉验收期望
- 前端特有 Unknowns

选项：
1. 生成 — 根据项目现有前端代码和依赖推断模板供你确认。
2. 跳过 — 后续前端设计步骤会从当前代码推断。
```

If the user chooses to generate, read lightweight project frontend facts and write the `FeaturePilot Frontend Settings` template from `templates.md`.

#### 5-c. Offer `settings/backend.md`

Ask:

```markdown
是否需要生成 `fp-docs/settings/backend.md`？

该文件包含：
- 后端框架与源代码位置
- API / 服务 / 数据模式
- 请求/响应/错误格式约定
- 认证/权限/隔离规则
- 后台任务与运维约定
- 后端特有 Unknowns

选项：
1. 生成 — 根据项目现有后端代码和依赖推断模板供你确认。
2. 跳过 — 后续后端设计步骤会从当前代码推断。
```

If the user chooses to generate, write the `FeaturePilot Backend Settings` template from `templates.md`.

#### 5-d. Offer `settings/prototype-style.md`

Ask:

```markdown
是否需要生成 `fp-docs/settings/prototype-style.md`（HTML 原型视觉风格参考）？

该文件用于后续 `/fp-prd` 生成 `prototype.html` 时保持项目原型风格一致，包含：
- 原型适用场景
- 页面骨架与布局模式
- 颜色、字体、间距 token
- 常用组件/表格/表单/弹窗/抽屉风格
- 原型交互与文案规则

选项：
1. 生成 — 根据已有原型、截图、Figma 或相邻页面提炼初始草稿；不确定项写 Unknown。
2. 跳过 — 后续首个原型确认后再提取。
```

If the user chooses to generate, write the `FeaturePilot Prototype Style` template from `templates.md`.

### 6. Ask about lightweight discovery

After handling settings, ask:

```markdown
FeaturePilot 可以为 SDD 构建一个轻量只读项目信息层，记录源代码根、验证命令发现、架构边界、契约、安全和 Unknowns。它不会安装依赖、运行测试、构建、索引所有文件或复制 secrets。

现在构建轻量信息层？

1. 生成轻量 intel（推荐）— 只读扫描并写入 `fp-docs/intel/*`。
2. 仅骨架 — 只保留 manifest + unknowns/refresh/sdd-handoff 骨架。
```

If approved, perform a read-only discovery pass.

### 7. Lightweight discovery boundaries

**Allowed:**
- Read project docs and manifests.
- Inspect `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` / lockfiles / build configs / lint configs / CI configs / tsconfig / vite / webpack / etc.
- Inspect obvious source/test root structure.
- Inspect a small number of representative adjacent files only when needed to identify conventions (e.g., one route file to confirm routing pattern, one component to confirm import pattern).
- Record sources, confidence, git blob SHAs / content hashes where available, and Unknowns.

**Forbidden:**
- Installing packages.
- Running test/build/lint commands unless explicitly approved.
- Exhaustive repository indexing.
- Reading secrets or env values.
- Copying credentials or data samples.
- Guessing unsupported frameworks, design systems, tokens, backend frameworks, API envelopes, or command names.

If facts cannot be confirmed from source files, write `Unknown` — not a guess.

### 8. Report next steps

After init, report:

- Workspace path.
- Whether `fp-docs/manifest.md` was created/updated.
- Whether `settings/agent.md` was created/skipped/adopted.
- Whether `settings/frontend.md` was created/skipped/adopted.
- Whether `settings/backend.md` was created/skipped/adopted.
- Whether `settings/prototype-style.md` was created/skipped/adopted.
- Whether intel artifacts were created (lightweight discovery) or kept as skeleton.
- External docs detected and recorded in manifest.
- Critical unknowns.
- Suggested next command:
  - `/fp-prd <idea>` for requirement design.
  - `/fp-start <slug or feature description>` to continue into development.

## Guardrails

- Do not make settings mandatory.
- `fp-docs/manifest.md` is the only manifest entry point. Do not create `fp-docs/settings/manifest.md` or `fp-docs/intel/manifest.md`.
- `settings/agent.md` must not absorb frontend or backend domain detail when `frontend.md` or `backend.md` is a better home.
- `settings/frontend.md` replaces the old `frontend_design.md` name.
- `settings/backend.md` is the dedicated backend settings home.
- Do not hardcode a customer component library, vendor, component prefix, design token, backend framework, API envelope, or workflow policy.
- Do not overwrite existing manifest/settings/intel without explicit user approval.
- Do not create `fp-docs/changes/<slug>/` during init unless the user explicitly asks.
- When project root already has `CLAUDE.md` or `AGENTS.md`, record the reference in `fp-docs/manifest.md` instead of duplicating content into `agent.md`.
- Keep generated settings concise and editable; use `Unknown` instead of guessing.
- Manifest and generated intel must include `When To Read` / freshness guidance so downstream skills can avoid token-heavy bulk reads.
- Generated intel is stale-prone; downstream skills must verify exact current facts from code instead of treating intel as authoritative.

## Compatibility

If an older project has `fp-docs/` but no `fp-docs/manifest.md`, treat it as a pre-information-layer project. Create only the manifest and missing skeleton files; do not overwrite existing `settings/` or `intel/` files. Recommend `/fp-init` as repair/refresh when safe.
