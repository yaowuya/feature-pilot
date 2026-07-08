---
name: fp-init
description: Use when a project is adopting FeaturePilot for the first time, needs a single-manifest fp-docs information layer, or wants guided creation of optional fp-docs/settings/agent.md, frontend.md, and backend.md configuration.
---

## FeaturePilot workspace and information layer


# FeaturePilot Init

`fp-init` bootstraps a FeaturePilot information layer with low setup cost. It creates the minimal skeleton and optionally guides the user through lightweight read-only discovery to populate `fp-docs/intel/`.

## Goals

- Create the FeaturePilot information layer skeleton: `fp-docs/manifest.md` (single entry point), `fp-docs/settings/`, and `fp-docs/intel/`.
- Explain the workflow: `/fp-prd` clarifies requirements; `/fp-start` picks up a PRD or feature description and drives design → plan → execution.
- Optionally generate lean `fp-docs/settings/agent.md` (general FeaturePilot policy adapter), `fp-docs/settings/frontend.md` (frontend/UI/visual), and/or `fp-docs/settings/backend.md` (backend/API/data/security) with user confirmation.
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

Walk upward from the current working directory to find `fp-docs/`.

If absent, create only:

- `fp-docs/`
- `fp-docs/settings/`
- `fp-docs/intel/`

Do **not** create `fp-docs/changes/`、`fp-docs/archive/`、`fp-docs/history/` or any sample files — those are created on-demand by later phases (`fp-prd`/`fp-propose`/`fp-archive`).

### 2. Create skeleton information layer

If missing, create these skeleton files. Existing files are never overwritten without explicit approval.

#### `fp-docs/manifest.md`

```markdown
# FeaturePilot Manifest

Schema: fp-manifest/v1
Generated: <timestamp>
Project root: `<detected local path>`
FP docs root: `fp-docs/`
Git SHA: <sha or unavailable>
Working tree: clean | dirty | unavailable

## Precedence

For current-state facts, current code and command output win over settings and intel.
For target-state requirements, user instructions and approved active change artifacts win.

## Settings Files

| File | Role | Authoritative For | Status |
| --- | --- | --- | --- |
| `settings/agent.md` | Lean FeaturePilot policy adapter | workflow, constraints, external-doc pointers | missing |
| `settings/frontend.md` | Frontend/UI/visual settings | UI implementation and visual acceptance | missing/not-applicable |
| `settings/backend.md` | Backend/API/data/security settings | backend implementation and backend acceptance | missing/not-applicable |

## Intel Artifacts

| File | Purpose | Freshness | Sources |
| --- | --- | --- | --- |
| `intel/unknowns-and-decisions.md` | Project-level unknowns and confirmations | fresh | init skeleton |
| `intel/refresh-policy.md` | Freshness and staleness rules | fresh | init skeleton |
| `intel/sdd-handoff.md` | SDD handoff contract | fresh | init skeleton |

## External Project Docs

| File | Priority | Notes |
| --- | --- | --- |

## Critical Unknowns

- None recorded yet.

## Consumption Rules

- Read this manifest first.
- Pull only relevant settings and intel for the current phase.
- Current code and command output win for current-state facts.
- Approved change artifacts win for target-state requirements.
- Re-open referenced source files before editing.
- Re-run commands before claiming validation.
- Missing referenced paths make dependent sections stale.
- UI-related phases must read `settings/frontend.md` when present.
- Backend-related phases must read `settings/backend.md` when present.
```

#### `fp-docs/intel/unknowns-and-decisions.md`

```markdown
# Unknowns and Decisions

## Unknowns

| Area | Unknown | Impact | Resolve By | Blocking For |
| --- | --- | --- | --- | --- |

## Decisions

| Date | Decision | Source | Applies To |
| --- | --- | --- | --- |
```

#### `fp-docs/intel/refresh-policy.md`

```markdown
# Refresh Policy

Generated intel is navigation, not proof of current behavior.

## Hard-stale

- Referenced paths disappear.
- Package manifests/config files change.
- Test/build/lint config changes.
- Route/API framework config changes.
- Auth/permission files change.
- Component library/theme/token files change.
- Any depends-on source recorded in `sources-and-provenance.md` has a changed git blob SHA or content hash.

## Soft-stale

- Git SHA differs from recorded SHA.
- Working tree was dirty during generation.
- Profile is old.
- Current change touches an area covered by an intel artifact.

On stale intel, verify just-in-time.
```

#### `fp-docs/intel/sdd-handoff.md`

```markdown
# SDD Handoff

## Mandatory Context Files

- `fp-docs/manifest.md`

## Global Constraints Sources

- Unknown

## Allowed Edit Scope Rules

- Unknown

## Validation Evidence Requirements

- Unknown

## Commit Policy

- Unknown

## Review Severity Policy

- Unknown

## Visual Evidence Requirements

- Unknown

## Backend Evidence Requirements

- Unknown

## Security/Data Constraints

- Unknown

## Common Project Pitfalls

- Unknown

## Stale Intel Handling

- Re-open source files before editing.
- Re-run commands before claiming validation.
- If a referenced path is missing, treat the dependent section as stale.
```

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

### 4. Ask about optional settings

After updating the manifest, offer optional settings files.

#### 4-a. Offer `settings/agent.md`

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

If the user chooses to generate, write:

```markdown
# FeaturePilot Agent Settings

## Purpose

- <why FeaturePilot settings exist for this project>

## Authoritative Project Docs

- <CLAUDE.md / AGENTS.md / other docs, or Unknown>

## Workflow Preferences

- Branching:
- Commit style:
- Review expectations:

## General Allowed / Forbidden Areas

- Allowed:
- Forbidden:

## General Validation Expectations

- <cross-domain validation expectations only; exact commands belong in intel/commands-and-quality-gates.md>

## General Security / Data Notes

- <cross-domain policy only; concrete API/auth/data/ops rules belong in settings/backend.md>

## Related Domain Settings

- Frontend/UI: `fp-docs/settings/frontend.md` if present
- Backend/API/Data/Security: `fp-docs/settings/backend.md` if present

## Unknowns

- <unknown general policy items>
```

#### 4-b. Offer `settings/frontend.md`

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

If the user chooses to generate, read lightweight project frontend facts and write:

```markdown
# FeaturePilot Frontend Settings

## Frontend Framework and Source Locations

- Framework:
- Source roots:
- Route locations:

## Component Library and Imports

- Library:
- Import patterns:
- Component prefix:

## Design Tokens and Styling

- Token/style sources:
- Layout/responsive rules:

## Figma / Screenshot Handling

- Design sources:
- Mapping rules:

## Preview and Visual Verification

- Local preview command:
- Browser/visual checks:

## Unknowns

- <unknown frontend/UI/visual items>
```

#### 4-c. Offer `settings/backend.md`

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

If the user chooses to generate, write:

```markdown
# FeaturePilot Backend Settings

## Backend Framework and Source Locations

- Framework:
- Source roots:
- API/router locations:

## API / Service / Data Patterns

- Controller/service patterns:
- Data model/schema/migration conventions:
- Request/response/error envelope:

## Auth / Permissions / Isolation

- Auth/session model:
- Permission/action naming:
- Multi-tenant / workspace / project / account isolation:

## Jobs / Operations / Observability

- Background job patterns:
- Audit/logging expectations:
- Deployment/migration notes:

## Backend Validation Expectations

- Backend test command/pattern:
- Data/security negative-test expectations:

## Unknowns

- <unknown backend/API/data/security items>
```

### 5. Ask about lightweight discovery

After handling settings, ask:

```markdown
FeaturePilot 可以为 SDD 构建一个轻量只读项目信息层，记录源代码根、验证命令发现、架构边界、契约、安全和 Unknowns。它不会安装依赖、运行测试、构建、索引所有文件或复制 secrets。

现在构建轻量信息层？

1. 生成轻量 intel（推荐）— 只读扫描并写入 `fp-docs/intel/*`。
2. 仅骨架 — 只保留 manifest + unknowns/refresh/sdd-handoff 骨架。
```

If approved, perform a read-only discovery pass.

### 6. Lightweight discovery boundaries

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

### 7. Report next steps

After init, report:

- Workspace path.
- Whether `fp-docs/manifest.md` was created/updated.
- Whether `settings/agent.md` was created/skipped.
- Whether `settings/frontend.md` was created/skipped.
- Whether `settings/backend.md` was created/skipped.
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

## Compatibility

If an older project has `fp-docs/` but no `fp-docs/manifest.md`, treat it as a pre-information-layer project. Create only the manifest and missing skeleton files; do not overwrite existing `settings/` or `intel/` files. Recommend `/fp-init` as repair/refresh when safe.
