# FP Init Information Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update FeaturePilot so `/fp-init` creates a single-manifest project information layer and downstream skills consume it consistently for SDD-safe planning, execution, and review.

**Architecture:** `fp-docs/manifest.md` becomes the single entry point for FeaturePilot project context. Human-confirmed settings are split into lean `settings/agent.md`, domain-specific `settings/frontend.md`, and domain-specific `settings/backend.md`; generated source-backed guidance lives under `fp-docs/intel/`. Downstream skills read the manifest first, then consume only relevant settings/intel and verify exact facts against current code.

**Tech Stack:** Claude Code plugin markdown commands and skills; no runtime code or package dependencies. Verification is grep-based consistency checking plus markdown review.

---

## Source Spec

Implement exactly this approved design:

- `docs/superpowers/specs/2026-07-08-fp-init-information-layer-design.md`

Key contract:

```text
fp-docs/
  manifest.md
  settings/
    agent.md
    frontend.md
    backend.md
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

Forbidden final-state terms except in explicit migration/deprecation notes:

- `fp-docs/settings/manifest.md`
- `fp-docs/intel/manifest.md`
- `fp-docs/settings/frontend_design.md`
- “read any settings files that exist” as the primary read-order rule

## File Structure Map

### Files to modify

- `commands/fp-init.md` — user-facing init command summary and contract.
- `commands/fp-start.md` — workspace/read-order contract before orchestration.
- `commands/fp-quick.md` — quick-flow read-order and domain settings rules.
- `commands/fp-propose.md` — proposal-flow read-order and context rules.
- `commands/fp-brainstorm.md` — design-flow read-order and frontend/backend settings rules.
- `commands/fp-figma.md` — Figma/UI read-order; rename frontend settings.
- `commands/fp-review.md` — final review read-order and information-layer drift checks.
- `commands/fp-archive.md` — archive policy reads manifest without using history as implementation context.
- `commands/fp-prd.md` — PRD flow reads manifest and unknowns.
- `skills/fp-init/SKILL.md` — main init behavior, skeleton templates, optional discovery contract.
- `skills/fp-prd/SKILL.md` — PRD flow manifest/unknowns consumption.
- `skills/fp-prd-grill-me/SKILL.md` — PRD critique reads manifest/settings/intel.
- `skills/fp-start/SKILL.md` — orchestration read order and no-exhaustive-index rule.
- `skills/fp-quick/SKILL.md` — quick changes still consume manifest/domain settings.
- `skills/fp-propose/SKILL.md` — proposal questions use unknowns and relevant settings.
- `skills/fp-brainstorm/SKILL.md` — design questions use frontend/backend settings and intel.
- `skills/fp-grill-me/SKILL.md` — design critique uses manifests, unknowns, target/current precedence.
- `skills/fp-ui-spec/SKILL.md` — UI spec reads `settings/frontend.md`.
- `skills/fp-ux-spec/SKILL.md` — UX spec reads `settings/frontend.md`.
- `skills/fp-figma/SKILL.md` — Figma workflow reads `settings/frontend.md` and manifest.
- `skills/fp-plan/SKILL.md` — general plan reads manifest and blocks on relevant unknowns.
- `skills/fp-plan-backend/SKILL.md` — backend plan reads `settings/backend.md` and backend intel.
- `skills/fp-plan-frontend/SKILL.md` — frontend plan reads `settings/frontend.md` and frontend intel.
- `skills/fp-execute/SKILL.md` — inline execution respects information-layer gates.
- `skills/fp-execute-sdd/SKILL.md` — SDD controller reads manifest, `sdd-handoff.md`, relevant settings/intel.
- `skills/fp-execute-sdd/task-brief-template.md` — add relevant project information layer section.
- `skills/fp-execute-sdd/implementer-prompt.md` — implementers must re-open referenced files and not trust stale intel.
- `skills/fp-execute-sdd/task-reviewer-prompt.md` — reviewers check information-layer compliance and stale-intel use.
- `skills/fp-execute-sdd/review-package-template.md` — include manifest/settings/intel evidence in review package.
- `skills/fp-execute-sdd/fix-prompt.md` — fixers must respect the same information-layer excerpts, re-open source files, and report stale-intel blockers.
- `skills/fp-review/SKILL.md` — final review checks manifest usage, domain settings usage, unknowns, stale intel.
- `skills/fp-review/final-reviewer.md` — final reviewer prompt checks information-layer process drift and source-backed validation.
- `skills/fp-archive/SKILL.md` — archive reads manifest for archive policy but not historical implementation context.
- `README.md` — public docs for new information layer and renamed settings.
- `AGENTS.md` — repository guidance for FeaturePilot info-layer structure.

### Files to create

No standalone template files are required unless implementation chooses to extract repeated markdown templates. Prefer keeping templates in `skills/fp-init/SKILL.md` to match current repository style.

### Cross-cutting text blocks

Use this shared read-order block, adapted to each file’s tone:

```markdown
Before choosing output paths, commands, UI/backend rules, or workflow behavior:

1. Locate `fp-docs/`.
2. If `fp-docs/manifest.md` exists, read it first.
3. Read only relevant settings and intel listed by the manifest.
4. If UI/frontend is involved and `fp-docs/settings/frontend.md` exists, read it as a required source.
5. If backend/API/data/security behavior is involved and `fp-docs/settings/backend.md` exists, read it as a required source.
6. Treat settings/intel as navigation and constraints; verify exact implementation facts against current code.
7. Use two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.
```

---

## Task 1: Update `/fp-init` command contract

**Files:**
- Modify: `commands/fp-init.md`
- Test: grep consistency checks

- [ ] **Step 1: Inspect current command**

Run:

```bash
python - <<'PY'
from pathlib import Path
print(Path('commands/fp-init.md').read_text(encoding='utf-8'))
PY
```

Expected: current command mentions minimal `fp-docs/settings/`, optional `settings/agent.md`, and `frontend_design.md`.

- [ ] **Step 2: Update command text**

Modify `commands/fp-init.md` so it says `/fp-init`:

- creates `fp-docs/manifest.md`, `fp-docs/settings/`, and `fp-docs/intel/` skeleton;
- never creates `changes/`, `archive/`, or `history/`;
- offers optional `settings/agent.md`, `settings/frontend.md`, and `settings/backend.md`;
- optionally performs lightweight read-only discovery;
- never overwrites existing manifest/settings/intel without explicit approval;
- invokes `skills/fp-init/SKILL.md` as the authoritative behavior.

Suggested replacement body after frontmatter:

```markdown
# FeaturePilot Init

**初始化目标（可选）：** $ARGUMENTS

## FeaturePilot workspace

执行命令前，先遵守目标项目的 `fp-docs` 信息层契约：如需生成产物，使用 `fp-docs/manifest.md` 作为唯一入口；如存在 `fp-docs/settings/agent.md`、`fp-docs/settings/frontend.md`、`fp-docs/settings/backend.md` 或 `fp-docs/intel/*`，先读取 `fp-docs/manifest.md` 判断相关文件。不要覆盖客户 manifest/settings/intel，除非用户明确要求。

调用并严格遵守本插件内 `fp-init` skill：`skills/fp-init/SKILL.md`。

`fp-init` 用于低成本接入 FeaturePilot 信息层：

- 创建 `fp-docs/manifest.md`、`fp-docs/settings/`、`fp-docs/intel/` 的最小骨架。
- 不创建 `fp-docs/changes/`、`fp-docs/archive/`、`fp-docs/history/`。
- 如果项目根目录已有 `CLAUDE.md` 或 `AGENTS.md`，在 `fp-docs/manifest.md` 中记录引用，不复制大段内容。
- 引导用户选择是否生成轻量 `fp-docs/settings/agent.md` adapter。
- 引导用户选择是否生成 `fp-docs/settings/frontend.md` 和/或 `fp-docs/settings/backend.md`。
- 引导用户选择是否运行轻量只读 discovery，填充 `fp-docs/intel/*`。
- 如果用户不同意，只创建信息层骨架，不强制配置。

完成后输出工作区路径、manifest 路径、配置生成状态、intel 生成状态、Unknowns 和下一步建议（通常是 `/fp-prd` 或 `/fp-start`）。
```

- [ ] **Step 3: Verify command no longer names old frontend settings as active output**

Run:

```bash
python - <<'PY'
from pathlib import Path
text=Path('commands/fp-init.md').read_text(encoding='utf-8')
assert 'frontend_design.md' not in text
assert 'fp-docs/manifest.md' in text
assert 'settings/frontend.md' in text
assert 'settings/backend.md' in text
print('fp-init command contract OK')
PY
```

Expected: `fp-init command contract OK`.

- [ ] **Step 4: Commit**

```bash
git add commands/fp-init.md
git commit -m "docs: update fp-init command contract"
```

---

## Task 2: Rewrite `fp-init` skill for single-manifest information layer

**Files:**
- Modify: `skills/fp-init/SKILL.md`
- Test: grep and structural assertions

- [ ] **Step 1: Read current skill**

Run:

```bash
python - <<'PY'
from pathlib import Path
print(Path('skills/fp-init/SKILL.md').read_text(encoding='utf-8'))
PY
```

Expected: current skill describes optional `agent.md` and `frontend_design.md`, minimal `settings/` only.

- [ ] **Step 2: Update frontmatter description**

Change description to mention:

```yaml
description: Use when a project is adopting FeaturePilot for the first time, needs a single-manifest fp-docs information layer, or wants guided creation of optional fp-docs/settings/agent.md, frontend.md, and backend.md configuration.
```

- [ ] **Step 3: Replace workspace structure section**

The workspace structure must become:

```text
fp-docs/
  manifest.md
  settings/
    agent.md
    frontend.md
    backend.md
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

State that `changes/`, `archive/`, and `history/` are created by later phases only.

- [ ] **Step 4: Add manifest skeleton template**

Add a required template section for `fp-docs/manifest.md`:

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

- [ ] **Step 5: Add required intel skeleton templates**

Add minimal templates for:

`fp-docs/intel/unknowns-and-decisions.md`:

```markdown
# Unknowns and Decisions

## Unknowns

| Area | Unknown | Impact | Resolve By | Blocking For |
| --- | --- | --- | --- | --- |

## Decisions

| Date | Decision | Source | Applies To |
| --- | --- | --- | --- |
```

`fp-docs/intel/refresh-policy.md`:

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

`fp-docs/intel/sdd-handoff.md`:

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

- [ ] **Step 6: Add optional settings skeleton templates**

Add concrete templates for the three optional settings files. They must be described as generated only with user approval and must use `Unknown` instead of guessing.

`fp-docs/settings/agent.md` template:

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

`fp-docs/settings/frontend.md` template:

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

`fp-docs/settings/backend.md` template:

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
- Multi-tenant/workspace/project/account isolation:

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

- [ ] **Step 7: Replace optional settings generation rules**

Rules:

- `settings/agent.md`: offer only with user approval; lean adapter; no frontend/backend detail.
- `settings/frontend.md`: offer when UI/frontend is detected or expected.
- `settings/backend.md`: offer when backend/API/data/security behavior is detected or expected.
- If existing `CLAUDE.md`/`AGENTS.md` exists, still create/update `fp-docs/manifest.md`; do not skip manifest normalization.
- Existing files are never overwritten without explicit approval.

- [ ] **Step 8: Add lightweight discovery section**

Discovery is optional and read-only. It may inspect docs, manifests, configs, obvious roots, and small representative files. It must not install packages, run tests/build/lint without approval, index the full repo, read secrets, or guess unsupported facts.

- [ ] **Step 9: Verify skill structure**

Run:

```bash
python - <<'PY'
from pathlib import Path
text=Path('skills/fp-init/SKILL.md').read_text(encoding='utf-8')
required=[
 'fp-docs/manifest.md',
 'settings/frontend.md',
 'settings/backend.md',
 'intel/unknowns-and-decisions.md',
 'intel/refresh-policy.md',
 'intel/sdd-handoff.md',
 'current-state facts',
 'target-state requirements',
]
missing=[s for s in required if s not in text]
assert not missing, missing
assert 'frontend_design.md' not in text
assert 'settings/manifest.md' not in text
assert 'intel/manifest.md' not in text
print('fp-init skill information layer contract OK')
PY
```

Expected: `fp-init skill information layer contract OK`.

- [ ] **Step 10: Commit**

```bash
git add skills/fp-init/SKILL.md
git commit -m "feat: define fp-init information layer"
```

---

## Task 3: Update shared workspace/read-order headers in commands

**Files:**
- Modify: `commands/fp-prd.md`
- Modify: `commands/fp-start.md`
- Modify: `commands/fp-propose.md`
- Modify: `commands/fp-brainstorm.md`
- Modify: `commands/fp-quick.md`
- Modify: `commands/fp-figma.md`
- Modify: `commands/fp-review.md`
- Modify: `commands/fp-archive.md`
- Test: grep assertions

- [ ] **Step 1: Verify command files exist**

Run:

```bash
python - <<'PY'
from pathlib import Path
required=['commands/fp-prd.md','commands/fp-start.md','commands/fp-propose.md','commands/fp-brainstorm.md','commands/fp-quick.md','commands/fp-figma.md','commands/fp-review.md','commands/fp-archive.md']
missing=[f for f in required if not Path(f).exists()]
print('missing command files:', missing)
assert not missing, missing
PY
```

Expected: `missing command files: []`.

- [ ] **Step 2: Locate old command wording**

Run:

```bash
python - <<'PY'
from pathlib import Path
for p in Path('commands').glob('fp-*.md'):
    text=p.read_text(encoding='utf-8')
    hits=[]
    for needle in ['settings/agent.md','frontend_design.md','read any settings','settings/frontend']:
        if needle in text:
            hits.append(needle)
    if hits:
        print(p, hits)
PY
```

Expected: list shows old settings wording to update.

- [ ] **Step 3: Update each command header**

For each command, ensure it says to read `fp-docs/manifest.md` first when present and then relevant settings/intel.

Minimum command-specific additions:

- `fp-prd.md`: PRD discovery should use manifest and relevant unknowns.
- `fp-start.md`: orchestration should read manifest first and should not generate an exhaustive project index.
- `fp-propose.md`: proposal should use manifest, unknowns, frontend/backend settings as relevant.
- `fp-brainstorm.md`: design should use manifest, architecture/contracts/security intel, frontend/backend settings.
- `fp-quick.md`: quick changes still obey manifest/domain settings and verify current code.
- `fp-figma.md`: Figma/UI flow must read `settings/frontend.md` when present.
- `fp-review.md`: review must check manifest/settings/intel consumption and stale-intel issues.
- `fp-archive.md`: archive may read manifest for archive policy but must not use history/archive as implementation background.

- [ ] **Step 4: Verify command consistency**

Run:

```bash
python - <<'PY'
from pathlib import Path
required_manifest=['commands/fp-prd.md','commands/fp-start.md','commands/fp-propose.md','commands/fp-brainstorm.md','commands/fp-quick.md','commands/fp-figma.md','commands/fp-review.md','commands/fp-archive.md']
for f in required_manifest:
    text=Path(f).read_text(encoding='utf-8')
    assert 'fp-docs/manifest.md' in text, f
assert 'settings/frontend.md' in Path('commands/fp-figma.md').read_text(encoding='utf-8')
assert 'frontend_design.md' not in ''.join(Path(f).read_text(encoding='utf-8') for f in required_manifest)
print('command read-order contracts OK')
PY
```

Expected: `command read-order contracts OK`.

- [ ] **Step 5: Commit**

```bash
git add commands/fp-*.md
git commit -m "docs: align fp commands with manifest read order"
```

---

## Task 4: Update shared workspace/read-order headers in workflow skills

**Files:**
- Modify: `skills/fp-prd/SKILL.md`
- Modify: `skills/fp-prd-grill-me/SKILL.md`
- Modify: `skills/fp-start/SKILL.md`
- Modify: `skills/fp-quick/SKILL.md`
- Modify: `skills/fp-propose/SKILL.md`
- Modify: `skills/fp-brainstorm/SKILL.md`
- Modify: `skills/fp-grill-me/SKILL.md`
- Modify: `skills/fp-ui-spec/SKILL.md`
- Modify: `skills/fp-ux-spec/SKILL.md`
- Modify: `skills/fp-figma/SKILL.md`
- Modify: `skills/fp-plan/SKILL.md`
- Modify: `skills/fp-plan-backend/SKILL.md`
- Modify: `skills/fp-plan-frontend/SKILL.md`
- Modify: `skills/fp-execute/SKILL.md`
- Modify: `skills/fp-execute-sdd/SKILL.md`
- Modify: `skills/fp-review/SKILL.md`
- Modify: `skills/fp-archive/SKILL.md`
- Test: grep assertions

- [ ] **Step 1: Identify current workspace header variants**

Run:

```bash
python - <<'PY'
from pathlib import Path
needles=['FeaturePilot workspace','customer settings','settings/agent.md','frontend_design.md','read any settings']
for p in sorted(Path('skills').glob('fp-*/SKILL.md')):
    text=p.read_text(encoding='utf-8')
    hits=[n for n in needles if n in text]
    if hits:
        print(p, hits)
PY
```

Expected: list of skills requiring header updates.

- [ ] **Step 2: Apply shared read-order block**

Add or replace the workspace/settings section in each workflow skill with this concept, matching each file’s style:

```markdown
## FeaturePilot workspace and information layer

Before choosing output paths, commands, UI/backend rules, or workflow behavior:

1. Walk upward from the current working directory to find `fp-docs/`.
2. If `fp-docs/` does not exist and this phase needs artifacts, create only the directories this phase writes to. Do not pre-create unrelated directories.
3. If `fp-docs/manifest.md` exists, read it first.
4. Read only relevant settings and intel listed by the manifest.
5. If UI/frontend is involved and `fp-docs/settings/frontend.md` exists, read it as a required source.
6. If backend/API/data/security behavior is involved and `fp-docs/settings/backend.md` exists, read it as a required source.
7. Treat settings/intel as navigation and constraints; verify exact implementation facts against current code.
8. Use two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, backend framework, API envelope, or workflow policy in public skills. Customer-specific rules belong in target-project settings.

Compatibility rule: if an older project has no `fp-docs/manifest.md`, continue from current code and existing settings when safe, and recommend `/fp-init` repair/refresh. If `fp-execute-sdd` cannot find `fp-docs/intel/sdd-handoff.md` and the missing handoff makes fresh-subagent dispatch unsafe, block with a clear repair instruction instead of dispatching.
```

Do not blindly paste if a skill has narrower needs; keep the same meaning.

- [ ] **Step 3: Batch A — update requirements and orchestration skills**

Modify:

- `skills/fp-prd/SKILL.md`: relevant unknowns from `fp-docs/intel/unknowns-and-decisions.md` become PRD questions.
- `skills/fp-prd-grill-me/SKILL.md`: pressure-test PRD against manifest, relevant settings/intel, and unresolved unknowns.
- `skills/fp-start/SKILL.md`: orchestrates manifest read order, preserves no-exhaustive-index rule, and recommends `/fp-init` repair/refresh when old projects lack `fp-docs/manifest.md`.
- `skills/fp-quick/SKILL.md`: quick changes must read frontend/backend settings when touching those domains, but should not create `changes/` artifacts.

Targeted assertion:

```bash
python - <<'PY'
from pathlib import Path
for f in ['fp-prd','fp-prd-grill-me','fp-start','fp-quick']:
    text=Path(f'skills/{f}/SKILL.md').read_text(encoding='utf-8')
    assert 'fp-docs/manifest.md' in text, f
assert 'unknowns-and-decisions.md' in Path('skills/fp-prd/SKILL.md').read_text(encoding='utf-8')
assert 'settings/frontend.md' in Path('skills/fp-quick/SKILL.md').read_text(encoding='utf-8')
assert 'settings/backend.md' in Path('skills/fp-quick/SKILL.md').read_text(encoding='utf-8')
print('batch A skills OK')
PY
```

- [ ] **Step 4: Batch B — update proposal/design/grill skills**

Modify:

- `skills/fp-propose/SKILL.md`: uses manifest, unknowns, and frontend/backend settings as relevant, then verifies current code.
- `skills/fp-brainstorm/SKILL.md`: uses architecture/contracts/security intel plus frontend/backend settings to shape design questions.
- `skills/fp-grill-me/SKILL.md`: challenges assumptions using current-state vs target-state precedence.

Targeted assertion:

```bash
python - <<'PY'
from pathlib import Path
for f in ['fp-propose','fp-brainstorm','fp-grill-me']:
    text=Path(f'skills/{f}/SKILL.md').read_text(encoding='utf-8')
    assert 'fp-docs/manifest.md' in text, f
    assert 'settings/backend.md' in text or f == 'fp-grill-me', f
assert 'current-state facts' in Path('skills/fp-grill-me/SKILL.md').read_text(encoding='utf-8')
assert 'target-state requirements' in Path('skills/fp-grill-me/SKILL.md').read_text(encoding='utf-8')
print('batch B skills OK')
PY
```

- [ ] **Step 5: Batch C — update UI/frontend skills**

Modify:

- `skills/fp-ui-spec/SKILL.md`: required UI settings source is `settings/frontend.md`.
- `skills/fp-ux-spec/SKILL.md`: required UX/frontend settings source is `settings/frontend.md`.
- `skills/fp-figma/SKILL.md`: read manifest and `settings/frontend.md`; do not assume frontend framework.
- `skills/fp-plan-frontend/SKILL.md`: require `settings/frontend.md` when present; verify exact UI patterns in current code.

Targeted assertion:

```bash
python - <<'PY'
from pathlib import Path
for f in ['fp-ui-spec','fp-ux-spec','fp-figma','fp-plan-frontend']:
    text=Path(f'skills/{f}/SKILL.md').read_text(encoding='utf-8')
    assert 'fp-docs/manifest.md' in text, f
    assert 'settings/frontend.md' in text, f
    assert 'frontend_design.md' not in text, f
print('batch C skills OK')
PY
```

- [ ] **Step 6: Batch D — update backend/planning/execution/review/archive skills**

Modify:

- `skills/fp-plan/SKILL.md`: blocks on relevant unknowns.
- `skills/fp-plan-backend/SKILL.md`: require `settings/backend.md` when present; verify exact contracts in code.
- `skills/fp-execute/SKILL.md`: inline execution respects information-layer gates.
- `skills/fp-execute-sdd/SKILL.md`: controller reads manifest, `intel/sdd-handoff.md`, and relevant settings/intel before task briefs; block with repair guidance if handoff is missing and dispatch would be unsafe.
- `skills/fp-review/SKILL.md`: reviews process drift against manifest/settings/intel.
- `skills/fp-archive/SKILL.md`: does not use archive/history as implementation background.

Targeted assertion:

```bash
python - <<'PY'
from pathlib import Path
for f in ['fp-plan','fp-plan-backend','fp-execute','fp-execute-sdd','fp-review','fp-archive']:
    text=Path(f'skills/{f}/SKILL.md').read_text(encoding='utf-8')
    assert 'fp-docs/manifest.md' in text, f
assert 'settings/backend.md' in Path('skills/fp-plan-backend/SKILL.md').read_text(encoding='utf-8')
assert 'intel/sdd-handoff.md' in Path('skills/fp-execute-sdd/SKILL.md').read_text(encoding='utf-8')
print('batch D skills OK')
PY
```

- [ ] **Step 7: Verify skill consistency**

Run:

```bash
python - <<'PY'
from pathlib import Path
skills=list(Path('skills').glob('fp-*/SKILL.md'))
text_all='\n'.join(p.read_text(encoding='utf-8') for p in skills)
assert 'frontend_design.md' not in text_all
assert 'settings/manifest.md' not in text_all
assert 'intel/manifest.md' not in text_all
for f in skills:
    text=f.read_text(encoding='utf-8')
    if f.name == 'SKILL.md':
        assert 'fp-docs/manifest.md' in text or f.parent.name == 'fp-init', f
for required in ['settings/frontend.md','settings/backend.md','current-state facts','target-state requirements']:
    assert required in text_all, required
print('workflow skill information-layer headers OK')
PY
```

Expected: `workflow skill information-layer headers OK`.

- [ ] **Step 8: Commit**

```bash
git add skills/fp-*/SKILL.md
git commit -m "docs: align fp skills with manifest information layer"
```

---

## Task 5: Update SDD execution templates and prompts

**Files:**
- Modify: `skills/fp-execute-sdd/task-brief-template.md`
- Modify: `skills/fp-execute-sdd/implementer-prompt.md`
- Modify: `skills/fp-execute-sdd/task-reviewer-prompt.md`
- Modify: `skills/fp-execute-sdd/review-package-template.md`
- Modify: `skills/fp-execute-sdd/fix-prompt.md`
- Test: template assertions

- [ ] **Step 1: Inspect current templates**

Run:

```bash
python - <<'PY'
from pathlib import Path
for f in ['task-brief-template.md','implementer-prompt.md','task-reviewer-prompt.md','review-package-template.md','fix-prompt.md']:
    p=Path('skills/fp-execute-sdd')/f
    print('\n---', p, '---')
    print(p.read_text(encoding='utf-8'))
PY
```

Expected: templates currently mention task-specific constraints but not a required project information-layer section.

- [ ] **Step 2: Add task brief section**

In `task-brief-template.md`, add:

```markdown
## Relevant Project Information Layer

- FeaturePilot manifest:
- Relevant settings excerpts:
- Relevant workspace-map excerpts:
- Relevant commands/quality-gates excerpts:
- Relevant architecture/contracts excerpts:
- Relevant security/data excerpts:
- Relevant frontend settings excerpts:
- Relevant backend settings excerpts:
- Unknowns checked:
- Staleness notes:
```

Place it before task-specific implementation instructions so implementers see it early.

- [ ] **Step 3: Update implementer prompt**

Add rules:

```markdown
Before editing, read the task brief's Relevant Project Information Layer section. Re-open every referenced live source/config file before relying on it. Treat settings/intel as navigation and constraints, not proof of current behavior. If a referenced path is missing or stale, stop and report the blocker instead of guessing.
```

- [ ] **Step 4: Update reviewer prompt**

Add review checks:

```markdown
Check whether the implementer followed the Relevant Project Information Layer section. If the task touched UI, verify `settings/frontend.md` was considered when present. If it touched backend/API/data/security behavior, verify `settings/backend.md` was considered when present. Flag any reliance on stale intel or missing source-file revalidation.
```

- [ ] **Step 5: Update review package template**

Add fields:

```markdown
## Information Layer Evidence

- Manifest read:
- Settings considered:
- Intel considered:
- Unknowns checked:
- Stale sections found:
- Source files re-opened:
```

- [ ] **Step 6: Update fix prompt**

Add rules to `fix-prompt.md`:

```markdown
Before fixing, read the review package's Information Layer Evidence and the task brief's Relevant Project Information Layer section. Re-open referenced source/config files before changing them. Do not use stale intel as proof of current behavior. If the fix requires project-level settings/intel changes, stop and ask for explicit approval instead of silently editing project-level information.
```

- [ ] **Step 7: Verify template consistency**

Run:

```bash
python - <<'PY'
from pathlib import Path
base=Path('skills/fp-execute-sdd')
checks={
 'brief_manifest': 'FeaturePilot manifest' in (base/'task-brief-template.md').read_text(encoding='utf-8'),
 'brief_frontend': 'Relevant frontend settings excerpts' in (base/'task-brief-template.md').read_text(encoding='utf-8'),
 'brief_backend': 'Relevant backend settings excerpts' in (base/'task-brief-template.md').read_text(encoding='utf-8'),
 'impl_reopen': 'Re-open' in (base/'implementer-prompt.md').read_text(encoding='utf-8') or 're-open' in (base/'implementer-prompt.md').read_text(encoding='utf-8'),
 'review_stale': 'stale intel' in (base/'task-reviewer-prompt.md').read_text(encoding='utf-8'),
 'package_evidence': 'Information Layer Evidence' in (base/'review-package-template.md').read_text(encoding='utf-8'),
 'fix_reopen': 're-open' in (base/'fix-prompt.md').read_text(encoding='utf-8').lower() or 'reopening' in (base/'fix-prompt.md').read_text(encoding='utf-8').lower(),
}
for k,v in checks.items(): print(k, v)
assert all(checks.values()), checks
print('SDD templates information-layer contract OK')
PY
```

Expected: all checks print `True`, then `SDD templates information-layer contract OK`.

- [ ] **Step 8: Commit**

```bash
git add skills/fp-execute-sdd/task-brief-template.md skills/fp-execute-sdd/implementer-prompt.md skills/fp-execute-sdd/task-reviewer-prompt.md skills/fp-execute-sdd/review-package-template.md skills/fp-execute-sdd/fix-prompt.md
git commit -m "docs: add information layer to sdd handoffs"
```

---

## Task 6: Update README and repository guidance

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`
- Test: documentation assertions

- [ ] **Step 1: Inspect docs**

Run:

```bash
python - <<'PY'
from pathlib import Path
for f in ['README.md','AGENTS.md']:
    print('\n---', f, '---')
    print(Path(f).read_text(encoding='utf-8'))
PY
```

Expected: README still mentions optional `settings/agent.md` and `frontend_design.md`; AGENTS may mention old settings assumptions.

- [ ] **Step 2: Update README core command and workflow docs**

Update README so it documents:

```text
fp-docs/
  manifest.md
  settings/
    agent.md
    frontend.md
    backend.md
  intel/
    ...
```

Explain:

- `manifest.md` is the only entry point.
- `agent.md` is lean general policy.
- `frontend.md` holds frontend/UI/visual settings.
- `backend.md` holds backend/API/data/security settings.
- `intel/` is source-backed navigation/provenance, not implementation truth.
- `changes/`, `archive/`, `history/` are created later as needed.

- [ ] **Step 3: Update AGENTS**

Add repository guidance:

```markdown
FeaturePilot public plugin files must not hardcode customer frameworks, vendors, component libraries, prefixes, design tokens, backend frameworks, API envelopes, or workflow policies. Target-project customization belongs under `fp-docs/manifest.md` and `fp-docs/settings/*.md`; generated project facts belong under `fp-docs/intel/`.
```

Also mention the one-manifest rule and the `frontend.md` / `backend.md` split.

- [ ] **Step 4: Verify docs**

Run:

```bash
python - <<'PY'
from pathlib import Path
readme=Path('README.md').read_text(encoding='utf-8')
agents=Path('AGENTS.md').read_text(encoding='utf-8')
for s in ['fp-docs/manifest.md','settings/frontend.md','settings/backend.md','fp-docs/intel']:
    assert s in readme, s
assert 'frontend_design.md' not in readme
assert 'fp-docs/manifest.md' in agents
assert 'settings/frontend.md' in agents
assert 'settings/backend.md' in agents
print('README and AGENTS information-layer docs OK')
PY
```

Expected: `README and AGENTS information-layer docs OK`.

- [ ] **Step 5: Commit**

```bash
git add README.md AGENTS.md
git commit -m "docs: document FeaturePilot information layer"
```

---

## Task 7: Update final review process

**Files:**
- Modify: `skills/fp-review/SKILL.md`
- Modify: `skills/fp-review/final-reviewer.md`
- Test: final-review assertions

- [ ] **Step 1: Inspect final review files**

Run:

```bash
python - <<'PY'
from pathlib import Path
for f in ['skills/fp-review/SKILL.md','skills/fp-review/final-reviewer.md']:
    print('\n---', f, '---')
    print(Path(f).read_text(encoding='utf-8'))
PY
```

Expected: current review process does not fully check manifest/settings/intel consumption.

- [ ] **Step 2: Add process-drift review checks**

Update both files so final review checks:

- whether `fp-docs/manifest.md` was read when present;
- whether required settings/intel files were consumed;
- whether UI work used `settings/frontend.md` when present;
- whether backend/API/data/security work used `settings/backend.md` when present;
- whether relevant unknowns were resolved before plan/execution;
- whether validation commands were source-backed and actually run;
- whether implementation relied on stale intel instead of current code.

For legacy changes that predate the manifest, review should report missing information-layer use as a process risk only when it affects current review confidence, not as an automatic product defect.

- [ ] **Step 3: Verify final review checks**

Run:

```bash
python - <<'PY'
from pathlib import Path
text='\n'.join(Path(f).read_text(encoding='utf-8') for f in ['skills/fp-review/SKILL.md','skills/fp-review/final-reviewer.md'])
for s in ['fp-docs/manifest.md','settings/frontend.md','settings/backend.md','stale intel','validation commands']:
    assert s in text, s
print('final review information-layer checks OK')
PY
```

Expected: `final review information-layer checks OK`.

- [ ] **Step 4: Commit**

```bash
git add skills/fp-review/SKILL.md skills/fp-review/final-reviewer.md
git commit -m "docs: add information layer checks to fp review"
```

---

## Task 8: Run repository-wide consistency verification

**Files:**
- No source modification expected unless verification finds misses.
- Test: repository-wide grep assertions and git diff check.

- [ ] **Step 1: Search for forbidden active references**

Run:

```bash
python - <<'PY'
from pathlib import Path
files=[p for p in Path('.').rglob('*') if p.is_file() and '.git' not in p.parts]
needles=['frontend_design.md','settings/manifest.md','intel/manifest.md']
for needle in needles:
    hits=[]
    for p in files:
        try:
            text=p.read_text(encoding='utf-8')
        except UnicodeDecodeError:
            continue
        if needle in text:
            hits.append(str(p))
    print(needle, hits)
PY
```

Expected:

- No hits in commands or skills.
- Hits are allowed only in the approved spec/plan migration notes if they explicitly describe deprecated names.

If unexpected hits exist, fix them and rerun this step.

- [ ] **Step 2: Verify required new references exist**

Run:

```bash
python - <<'PY'
from pathlib import Path
all_text='\n'.join(p.read_text(encoding='utf-8') for p in list(Path('commands').glob('fp-*.md')) + list(Path('skills').glob('fp-*/SKILL.md')) + list(Path('skills/fp-execute-sdd').glob('*.md')) + list(Path('skills/fp-review').glob('*.md')) + [Path('README.md'), Path('AGENTS.md')])
required=['fp-docs/manifest.md','settings/frontend.md','settings/backend.md','intel/sdd-handoff.md','current-state facts','target-state requirements']
for s in required:
    print(s, all_text.count(s))
    assert s in all_text, s
print('required new information-layer references exist')
PY
```

Expected: counts for all required strings and final success line.

- [ ] **Step 3: Run diff whitespace check**

Run:

```bash
git diff --check
```

Expected: no output and exit code 0.

- [ ] **Step 4: Review git status**

Run:

```bash
git status --short
```

Expected: clean if all prior task commits were made; otherwise only intentional files from this plan.

- [ ] **Step 5: Verify no target-project runtime artifacts were created in the plugin repo**

Run:

```bash
python - <<'PY'
from pathlib import Path
bad=[]
for p in [Path('fp-docs/manifest.md'), Path('fp-docs/settings'), Path('fp-docs/intel')]:
    if p.exists():
        bad.append(str(p))
print('runtime artifacts in plugin repo:', bad)
assert not bad, bad
PY
```

Expected: `runtime artifacts in plugin repo: []`.

- [ ] **Step 6: Commit any missed consistency fixes**

Only if verification required fixes:

```bash
git add <fixed-files>
git commit -m "docs: fix information layer consistency"
```

---

## Task 9: Final adversarial review before push

**Files:**
- Review only, unless issues are found.

- [ ] **Step 1: Dispatch SDD architecture review agent**

Use a fresh read-only subagent with this prompt:

```text
You are an SDD architecture reviewer for the FeaturePilot public Claude Code plugin. Review the current branch diff after implementing docs/superpowers/specs/2026-07-08-fp-init-information-layer-design.md. Focus on correctness of the information-layer contract, single fp-docs/manifest.md entry point, frontend.md/backend.md split, SDD handoff completeness, stale-intel guardrails, and public-plugin neutrality. Do not edit files. Return APPROVED or concrete blocking findings with file/line and failure scenario.
```

Expected: APPROVED or actionable findings.

- [ ] **Step 2: Fix blocking findings**

If findings exist, fix them in the relevant files, rerun Task 8 verification, then redispatch review.

- [ ] **Step 3: Commit review fixes**

If fixes were made:

```bash
git add <fixed-files>
git commit -m "docs: address information layer review"
```

---

## Task 10: Prepare final handoff and request push approval

**Files:**
- No file modifications.

- [ ] **Step 1: Confirm final status and branch**

Run:

```bash
git status --short
git branch --show-current
git log --oneline -5
```

Expected:

- clean working tree;
- branch is the intended implementation branch;
- recent commits correspond to this plan.

- [ ] **Step 2: Report ready-to-push state**

Report:

- commits created;
- verification commands run and results;
- any skipped checks with reason;
- whether final SDD architecture review approved;
- current branch and remote tracking status.

- [ ] **Step 3: Ask for explicit push approval**

Do not push from this plan automatically. Ask the user for explicit approval to push the current branch. If the branch is `develop` or another shared branch, recommend creating/pushing a feature branch instead unless the user explicitly confirms direct push.

If the user approves push in the active session, run:

```bash
git push
```

Expected: push succeeds.
