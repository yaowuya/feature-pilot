---
name: fp-init
description: Use when a project is adopting FeaturePilot for the first time, needs a single-manifest fp-docs information layer, wants optional CodeGraph setup, guided creation of fp-docs settings, or may adopt labelled project-family examples such as Canway/CW settings.
---

## FeaturePilot workspace and information layer

If any anchored plugin resource is missing or unreadable, stop, report the exact resource and an incomplete FeaturePilot installation/cache, and never search the consumer repository for `skills/**` or continue without it.
下文以 `${CLAUDE_PLUGIN_ROOT}/...` 表示 Claude Code 安装后的插件资源。在 Codex/Markdown 中，从 available-skill 元数据提供的当前技能入口映射同一个 `skills/...` 插件相对路径。两端都不得在消费者项目中搜索插件文件。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting. For this skill, apply its `fp-init` ownership exception: only init may create or repair project-level `fp-docs/manifest.md`, settings, and intel, and existing files require explicit overwrite approval.

# FeaturePilot Init

`fp-init` bootstraps a FeaturePilot information layer with low setup cost. It can set up an optional local CodeGraph under explicit gates, creates the minimal skeleton, and optionally guides the user through lightweight read-only discovery to populate `fp-docs/intel/`.

## Goals

- Create the FeaturePilot information layer skeleton: `fp-docs/manifest.md` (single entry point), `fp-docs/settings/`, and `fp-docs/intel/`.
- Explain the workflow: `/fp-prd` clarifies requirements; `/fp-start` picks up a PRD or feature description and drives design → plan → execution.
- Optionally generate lean `fp-docs/settings/agent.md` (general FeaturePilot policy adapter), `fp-docs/settings/frontend.md` (frontend/UI/visual), `fp-docs/settings/backend.md` (backend/API/data/security), and/or `fp-docs/settings/prototype-style.md` (prototype visual style reference) with user confirmation.
- Optionally install CodeGraph through npm, configure Agent MCP separately, and build a project-local code map with explicit user authorization.
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

### 2. Offer optional CodeGraph setup

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/codegraph.md` now. Only this section may install CodeGraph or build a project code map, and only after the confirmations below. CodeGraph remains optional; every unavailable or failed path continues normal init.

First detect `codegraph --version`. If normal command resolution fails and npm is available, use `npm prefix -g` only to check the platform launcher documented in the shared contract.

#### 2-a. CLI unavailable

Ask one decision:

```markdown
未检测到可用的 CodeGraph CLI。是否为 FeaturePilot 配置可选代码地图？

1. 自动安装（推荐）（`auto-install`）— 使用 npm 全局安装；会写入 npm 全局目录。选择后也授权为当前项目执行首次建图。
2. 展示安装步骤（`show-install-steps`）— 只展示 npm 前置条件、安装、可选 MCP 配置和建图命令，本轮不执行。
3. 跳过（`skip-codegraph`）— 不安装、不配置、不建图，继续普通 init。
```

`auto-install includes first graph build`：用户选择自动安装后，仍须遵守宿主环境的联网和全局写入审批；只允许执行：

```text
npm install -g @colbymchenry/codegraph@latest
```

执行前运行 `npm --version`。npm 不可用时不得自动安装 Node.js，也不得改用 `irm`、`curl`、`install.ps1`、`install.sh` 或 `npx`；说明 Node.js/npm 前置条件和上述 npm 命令，将 CodeGraph 记为 `unavailable`，然后继续普通 init。

安装后先验证 `codegraph --version`。当前进程的 `PATH` 尚未刷新时，运行 `npm prefix -g` 并使用共享合同中的 Windows 或 macOS/Linux launcher 再验证。仍不可用时不得宣称安装成功，不继续 MCP 配置或建图。

选择 `show-install-steps` 时只展示以下顺序，不运行命令：安装 Node.js/npm 前置条件、唯一 npm 安装命令、可选 Agent MCP 命令、`codegraph init <project-root>`。选择 `skip-codegraph` 时不展示冗长步骤，也不执行任何 CodeGraph 命令。

#### 2-b. Separate Agent MCP confirmation

CLI 已验证可用后，单独询问：

```markdown
是否允许 CodeGraph 配置检测到的 Claude Code/Codex MCP？该操作可能修改用户级 MCP 和 instructions 配置。

1. 配置 MCP — 运行 `codegraph install --target=auto --location=global --yes`。
2. 跳过 MCP — 保留 CLI 能力，不影响当前项目建图。
```

只有明确选择配置后才执行。成功后提示用户重启相应 Agent；当前工作流不等待 MCP 热加载，继续使用 CLI。

#### 2-c. Build or reuse the project graph

只检查 `<project-root>/.codegraph/`，不得向上查找父目录索引。

- 本轮 `auto-install` 成功且没有项目图：直接运行 `codegraph init <project-root>`，因为自动安装选择已包含首次建图授权。
- `preinstalled-cli-requires-build-confirmation`：CLI 原本已安装但没有项目图时，单独询问是否构建；只有明确同意后才运行 `codegraph init <project-root>`。
- `show-install-steps` 或 `skip-codegraph`：不建图。

首次建图完成或发现已有 `.codegraph/` 后，本轮最多执行一次：

```text
codegraph status <project-root> --json
```

状态显示待同步变化时最多运行一次 `codegraph sync <project-root> --quiet`，以同步命令成功退出作为本轮刷新证据，不再次运行 `status`。任何失败都只报告一次精简原因并继续 init；不得删除索引、运行 `codegraph uninit`、修改 `.gitignore`，或把图内容复制到 `fp-docs/intel/`。

保留本节实际检测结果，供新 manifest 的 Code Map 使用。已有 manifest 只有在用户明确同意更新后才可写入 Code Map；实时检测结果始终优先于历史记录。

### 3. Create skeleton information layer

If missing, create the skeleton files below. Existing files are never overwritten without explicit approval.

Use the exact skeleton templates in `${CLAUDE_PLUGIN_ROOT}/skills/fp-init/templates.md`:

| Target file | Template section |
| --- | --- |
| `fp-docs/manifest.md` | `FeaturePilot Manifest` |
| `fp-docs/intel/unknowns-and-decisions.md` | `Unknowns and Decisions` |
| `fp-docs/intel/refresh-policy.md` | `Refresh Policy` |
| `fp-docs/intel/sdd-handoff.md` | `SDD Handoff` |

### 4. Check existing project-level agent/docs

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

### 5. Detect labelled project-family examples

After checking project docs, run only a small read-only project-family signal check. If no plausible signal exists, continue generic init without loading extra context. If a signal exists, read `${CLAUDE_PLUGIN_ROOT}/skills/fp-init/project-family-examples.md` and follow its confidence, consent, selective-copy, and overwrite rules.

### 6. Ask about optional settings

After updating the manifest and handling any accepted project-family example, offer optional settings files.

#### 6-a. Offer `settings/agent.md`

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

If the user chooses to generate, write the `FeaturePilot Agent Settings` template from `${CLAUDE_PLUGIN_ROOT}/skills/fp-init/templates.md`.

#### 6-b. Offer `settings/frontend.md`

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

If the user chooses to generate, read lightweight project frontend facts and write the `FeaturePilot Frontend Settings` template from `${CLAUDE_PLUGIN_ROOT}/skills/fp-init/templates.md`.

#### 6-c. Offer `settings/backend.md`

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

If the user chooses to generate, write the `FeaturePilot Backend Settings` template from `${CLAUDE_PLUGIN_ROOT}/skills/fp-init/templates.md`.

#### 6-d. Offer `settings/prototype-style.md`

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

If the user chooses to generate, write the `FeaturePilot Prototype Style` template from `${CLAUDE_PLUGIN_ROOT}/skills/fp-init/templates.md`.

### 7. Ask about lightweight discovery

After handling settings, ask:

```markdown
FeaturePilot 可以为 SDD 构建一个轻量只读项目信息层，记录源代码根、验证命令发现、架构边界、契约、安全和 Unknowns。轻量 discovery 本身不会安装依赖、运行测试、构建、穷举索引所有文件或复制 secrets；前面单独确认的 CodeGraph 步骤不属于 discovery。

现在构建轻量信息层？

1. 生成轻量 intel（推荐）— 只读扫描并写入 `fp-docs/intel/*`。
2. 仅骨架 — 只保留 manifest + unknowns/refresh/sdd-handoff 骨架。
```

If approved, perform a read-only discovery pass.

### 8. Lightweight discovery boundaries

**Allowed:**
- Read project docs and manifests.
- Inspect `package.json` / `pyproject.toml` / `go.mod` / `Cargo.toml` / lockfiles / build configs / lint configs / CI configs / tsconfig / vite / webpack / etc.
- Inspect obvious source/test root structure.
- Inspect a small number of representative adjacent files only when needed to identify conventions (e.g., one route file to confirm routing pattern, one component to confirm import pattern).
- Record sources, confidence, git blob SHAs / content hashes where available, and Unknowns.

**Forbidden:**
- Installing packages, except the npm global CodeGraph install explicitly approved in Section 2.
- Running test/build/lint commands unless explicitly approved.
- Exhaustive repository indexing, except the project-local CodeGraph build explicitly approved in Section 2.
- Reading secrets or env values.
- Copying credentials or data samples.
- Guessing unsupported frameworks, design systems, tokens, backend frameworks, API envelopes, or command names.

If facts cannot be confirmed from source files, write `Unknown` — not a guess.

### 9. Report next steps

After init, report:

- Workspace path.
- Whether `fp-docs/manifest.md` was created/updated.
- CodeGraph CLI version or unavailable/skipped/failed state.
- Whether Agent MCP configuration was applied or skipped, and whether an Agent restart is required.
- Whether the project graph was built, reused, synchronized, skipped, or failed, plus any one-time fallback reason.
- Whether the manifest Code Map was created or explicitly approved for update.
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
- CodeGraph is optional and `navigation-hint-only`; its failure must not block init or weaken current-source verification.

## Compatibility

If an older project has `fp-docs/` but no `fp-docs/manifest.md`, treat it as a pre-information-layer project. Create only the manifest and missing skeleton files; do not overwrite existing `settings/` or `intel/` files. Recommend `/fp-init` as repair/refresh when safe.
