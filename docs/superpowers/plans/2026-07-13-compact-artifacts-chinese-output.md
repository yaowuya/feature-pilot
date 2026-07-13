# FeaturePilot 紧凑产物与中文输出 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 FeaturePilot 在硬限制以内默认生成单文件过程产物，并让过程文档的叙述性内容默认使用中文。

**Architecture:** `skills/_shared/artifact-layout.md` 作为 form 选择的唯一规范来源，`skills/_shared/workspace-rules.md` 作为过程文档语言的唯一共享规范来源。阶段 skill、输出模板、公开说明和 Codex 插件元数据只做一致复述；`scripts/validate-plugin.ps1` 用正向锚点和旧规则负向检查防止契约漂移。

**Tech Stack:** Markdown prompt contracts、PowerShell validation、Claude Code/Codex plugin manifests。

## Global Constraints

- small form 与 split form 的互斥路径、manifest schema、Consumer 解析顺序和历史结构冲突规则保持不变。
- 每个 Markdown 文件继续执行 500 行和 30,000 字符双重硬上限。
- 默认中文只约束叙述性过程文档；代码、命令、路径、技术标识符、API 字段及规范要求精确匹配的 schema 关键词保留必要英文。
- 当前用户明确语言指令优先于目标项目设置，目标项目设置优先于默认中文。
- 不迁移或重写现有客户项目产物，不回写历史 `docs/superpowers/specs/` 与 `docs/superpowers/plans/`。

---

### Task 1: 用失败断言定义共享契约并实现唯一规范来源

**Files:**
- Modify: `scripts/validate-plugin.ps1:205-219`
- Modify: `skills/_shared/workspace-rules.md:13-20`
- Modify: `skills/_shared/artifact-layout.md:43-58`

**Interfaces:**
- Consumes: 当前 `Read-Utf8`、`Assert-Condition`、`$sharedText` 和 `$artifactLayoutText` 验证接口。
- Produces: `Process document language` 共享语言契约，以及 `Default to the small form` 紧凑优先选择契约，供所有 FeaturePilot producer/consumer skill 使用。

- [ ] **Step 1: 写共享契约失败断言**

在 `$sharedText` 现有 anchor 检查后加入：

```powershell
foreach ($anchor in @('Process document language', 'Chinese by default', 'current explicit user instruction', 'target-project setting', 'necessary English')) {
    Assert-Condition ($sharedText.Contains($anchor)) "shared workspace contract is missing process-document language rule: $anchor"
}
```

在 `$artifactLayoutText` 现有 anchor 检查后加入：

```powershell
foreach ($anchor in @('Default to the small form', 'user explicitly approves split form', 'target-project setting explicitly requires split form', 'does not by itself trigger split form')) {
    Assert-Condition ($artifactLayoutText.Contains($anchor)) "shared artifact-layout contract is missing compact-first selection rule: $anchor"
}
```

- [ ] **Step 2: 运行验证并确认新断言失败**

Run: `pwsh -NoProfile -File scripts/validate-plugin.ps1`

Expected: FAIL，首个错误包含 `shared workspace contract is missing process-document language rule`。

- [ ] **Step 3: 在 workspace-rules 中实现默认中文契约**

在 `## Evidence and precedence` 之前加入完整规则：

```markdown
## Process document language

- Write FeaturePilot-generated process-document prose in Chinese by default, including titles, explanations, decisions, requirements, task descriptions, acceptance text, review findings, and archive/history summaries.
- Language precedence is: current explicit user instruction, then an explicit target-project setting, then Chinese by default. A project setting never overrides the current user's explicit language request.
- Preserve necessary English for code, commands, file paths, package/class/function/variable names, API fields, protocol terms, standard technical terms, and schema headings or enum values that another contract requires to match exactly.
```

- [ ] **Step 4: 在 artifact-layout 中实现紧凑优先选择**

用以下规则替换现有“多个独立语义域即拆分”的段落：

```markdown
## Split selection and safety limits

A Producer selects one form before writing. Default to the small form whenever the complete logical artifact is expected to fit within both hard limits below.

Select split form only when at least one of these conditions is true:

1. the complete small form is expected to exceed 500 lines or 30,000 characters;
2. the user explicitly approves split form; or
3. an applicable target-project setting explicitly requires split form.

The presence of multiple features, subsystems, page areas, task groups, or ownership domains does not by itself trigger split form. Once split form is selected, use those semantic boundaries to define fragments and write the final structure directly; do not generate a monolith and mechanically cut it later.
```

保留紧随其后的文件硬限制、完整语义单元和唯一 owner 规则。

- [ ] **Step 5: 运行共享契约验证并确认通过当前阶段**

Run: `pwsh -NoProfile -File scripts/validate-plugin.ps1`

Expected: PASS，输出 `FeaturePilot plugin validation passed`。

- [ ] **Step 6: 提交共享契约**

```bash
git add scripts/validate-plugin.ps1 skills/_shared/workspace-rules.md skills/_shared/artifact-layout.md
git commit -m "fix: default to compact Chinese artifacts"
```

---

### Task 2: 锁定并同步阶段生产者与输出模板

**Files:**
- Modify: `scripts/validate-plugin.ps1:380-530`
- Modify: `skills/fp-prd/SKILL.md:128-138`
- Modify: `skills/fp-prd/prd-template.md:5-18`
- Modify: `skills/fp-prd-grill-me/SKILL.md:130-140`
- Modify: `skills/fp-propose/SKILL.md:28-40`
- Modify: `skills/fp-propose/proposal-template.md:5-18`
- Modify: `skills/fp-brainstorm/SKILL.md:80-90`
- Modify: `skills/fp-brainstorm/design-template.md:1-14`
- Modify: `skills/fp-figma/SKILL.md:27-35`
- Modify: `skills/fp-plan/SKILL.md:28-36`
- Modify: `skills/fp-plan-backend/SKILL.md:43-53`
- Modify: `skills/fp-plan-backend/plan-template.md:1-12`
- Modify: `skills/fp-plan-frontend/SKILL.md:45-55`
- Modify: `skills/fp-plan-frontend/plan-template.md:1-12`
- Modify: `skills/fp-review/SKILL.md:1-15`
- Modify: `skills/fp-review/final-review-template.md:1-12`
- Modify: `skills/fp-archive/SKILL.md:1-15`

**Interfaces:**
- Consumes: Task 1 的 `Default to the small form` 与 `Process document language` 共享规则。
- Produces: 所有主要过程文档 producer 的就近紧凑优先/中文输出提醒；不会引入第二套阈值或不同优先级。

- [ ] **Step 1: 写 producer/template 一致性失败断言**

在 `scripts/validate-plugin.ps1` 的模板/skill 检查区域加入：

```powershell
$compactFirstFiles = @(
    'skills\fp-prd\SKILL.md',
    'skills\fp-prd\prd-template.md',
    'skills\fp-prd-grill-me\SKILL.md',
    'skills\fp-propose\SKILL.md',
    'skills\fp-propose\proposal-template.md',
    'skills\fp-brainstorm\SKILL.md',
    'skills\fp-brainstorm\design-template.md',
    'skills\fp-figma\SKILL.md',
    'skills\fp-plan\SKILL.md',
    'skills\fp-plan-backend\SKILL.md',
    'skills\fp-plan-frontend\SKILL.md'
)
foreach ($relativePath in $compactFirstFiles) {
    $text = Read-Utf8 (Join-Path $root $relativePath)
    Assert-Condition ($text.Contains('default to the small form') -or $text.Contains('默认选择 small form')) "$relativePath is missing compact-first form selection"
}

$chineseProcessFiles = @(
    'skills\fp-prd\prd-template.md',
    'skills\fp-propose\proposal-template.md',
    'skills\fp-brainstorm\design-template.md',
    'skills\fp-plan-backend\plan-template.md',
    'skills\fp-plan-frontend\plan-template.md',
    'skills\fp-review\final-review-template.md',
    'skills\fp-archive\SKILL.md'
)
foreach ($relativePath in $chineseProcessFiles) {
    $text = Read-Utf8 (Join-Path $root $relativePath)
    Assert-Condition ($text.Contains('叙述性内容默认使用中文')) "$relativePath is missing the default Chinese output reminder"
}

$obsoleteAutoSplitPatterns = @(
    'Use split form for multiple independently readable',
    'Select split form directly when independently readable',
    '内容有多个可独立阅读的 feature',
    'confirmed content has multiple independently readable'
)
foreach ($relativePath in $compactFirstFiles) {
    $text = Read-Utf8 (Join-Path $root $relativePath)
    foreach ($pattern in $obsoleteAutoSplitPatterns) {
        Assert-Condition (-not $text.Contains($pattern)) "$relativePath retains obsolete semantic auto-split wording: $pattern"
    }
}
```

- [ ] **Step 2: 运行验证并确认 producer 检查失败**

Run: `pwsh -NoProfile -File scripts/validate-plugin.ps1`

Expected: FAIL，错误包含 `is missing compact-first form selection`。

- [ ] **Step 3: 同步 PRD 与 proposal producer**

在 `fp-prd`、`prd-template`、`fp-prd-grill-me`、`fp-propose`、`proposal-template` 中使用以下同义规则，替换旧的多域自动拆分条件：

```markdown
Default to the small form when the complete logical artifact is expected to stay within 500 lines and 30,000 characters. Use split form only when the small form is expected to exceed either hard limit, the user explicitly approves split form, or an applicable target-project setting explicitly requires it. Multiple features, page areas, subsystems, change scopes, or ownership domains guide fragment boundaries after splitting; they do not trigger split form by themselves.
```

在两个输出模板的 representation rules 后加入：

```markdown
叙述性内容默认使用中文；代码、命令、路径、技术标识符、API 字段以及本模板要求精确匹配的英文 schema 标题保留必要英文。若用户或目标项目设置明确指定其他语言，按共享优先级执行。
```

- [ ] **Step 4: 同步 design 与 Figma producer**

在 `fp-brainstorm`、`design-template` 和 `fp-figma` 中把“多个 feature/subsystem/page area/ownership domain 直接 split”替换为：

```markdown
默认选择 small form。只有预计 small form 超过 500 行或 30,000 字符、用户明确批准 split form，或目标项目设置明确要求 split form 时才拆分；多个 feature、subsystem、page area 或 ownership domain 仅用于已选 split form 的分片边界，不单独触发拆分。
```

在 `design-template.md` 的 representation rules 后加入与 Step 3 完全相同的中文叙述规则。

- [ ] **Step 5: 同步 plan producer**

在 `fp-plan`、`fp-plan-backend`、`fp-plan-frontend` 中把 task group/page area/ownership domain 自动拆分条件替换为：

```markdown
Default to the small form while the complete end-local plan is expected to fit within 500 lines and 30,000 characters. Select split form only when the small plan is expected to exceed either limit, the user explicitly approves split form, or an applicable target-project setting explicitly requires it. Task groups, page areas, and ownership domains define fragments only after split form has been selected.
```

在两个 plan template 的 representation rules 后加入与 Step 3 相同的中文叙述规则。

- [ ] **Step 6: 同步 review 与 archive 直接输出入口**

在 `final-review-template.md` 和 `fp-archive/SKILL.md` 的输出规则附近加入：

```markdown
叙述性内容默认使用中文；代码、命令、路径、技术标识符、API 字段以及契约要求精确匹配的英文 schema 标题保留必要英文。若用户或目标项目设置明确指定其他语言，按共享优先级执行。
```

`fp-review/SKILL.md` 只增加对共享语言契约的明确提醒，不改变 PASS/FAIL/BLOCKED 语义。

- [ ] **Step 7: 运行插件验证**

Run: `pwsh -NoProfile -File scripts/validate-plugin.ps1`

Expected: PASS，输出 `FeaturePilot plugin validation passed`。

- [ ] **Step 8: 提交 producer/template 同步**

```bash
git add scripts/validate-plugin.ps1 skills/fp-prd skills/fp-prd-grill-me skills/fp-propose skills/fp-brainstorm skills/fp-figma skills/fp-plan skills/fp-plan-backend skills/fp-plan-frontend skills/fp-review skills/fp-archive
git commit -m "fix: align artifact producers with compact Chinese output"
```

---

### Task 3: 同步公开契约与 Codex 插件元数据

**Files:**
- Modify: `scripts/validate-plugin.ps1:221-320`
- Modify: `AGENTS.md:74-82`
- Modify: `README.md:10-16`
- Modify: `README.md:145-154`
- Modify: `docs/user_guide/init-prd-start.md:229-247`
- Modify: `.codex-plugin/plugin.json:23`
- Modify: `commands/fp-brainstorm.md:8-14`

**Interfaces:**
- Consumes: Task 1 的共享契约和 Task 2 的 producer 行为。
- Produces: 对用户、Codex 插件发现界面和 Claude command adapter 一致可见的紧凑优先/中文默认说明。

- [ ] **Step 1: 写公开表面失败断言**

先把 `$publicArtifactAnchors` 中的 `'semantic-first'` 替换为 `'compact-first'`，再在 `$publicSurfaces` 之后加入：

```powershell
foreach ($surface in $publicSurfaces) {
    Assert-Condition ($surface.Text.Contains('compact-first') -or $surface.Text.Contains('紧凑优先')) "$($surface.Name) is missing compact-first artifact guidance"
    Assert-Condition ($surface.Text.Contains('Chinese by default') -or $surface.Text.Contains('默认使用中文')) "$($surface.Name) is missing default Chinese process-document guidance"
    Assert-Condition (-not $surface.Text.Contains('semantic-first')) "$($surface.Name) retains obsolete semantic-first public guidance"
}
```

- [ ] **Step 2: 运行验证并确认公开表面检查失败**

Run: `pwsh -NoProfile -File scripts/validate-plugin.ps1`

Expected: FAIL，错误包含 `is missing compact-first artifact guidance`。

- [ ] **Step 3: 更新 AGENTS、README 与用户指南**

三处公开文档统一表达：

```markdown
产物形式采用紧凑优先（compact-first）且 small/split 互斥：预计完整逻辑产物不超过 500 行和 30,000 字符时默认使用 small form；只有预计超过任一硬限制、用户明确批准 split form，或目标项目设置明确要求 split form 时才拆分。功能、子系统、页面区域、任务组或 ownership domain 只用于拆分后的语义边界，不单独触发拆分。

FeaturePilot 过程文档的叙述性内容默认使用中文；代码、命令、路径、技术标识符、API 字段和契约要求精确匹配的 schema 关键词保留必要英文。当前用户明确语言指令优先于目标项目设置。
```

保留 canonical path 表、双硬限制、two-end overview 和历史结构拒绝说明。

- [ ] **Step 4: 更新 Codex 插件 longDescription**

将 `.codex-plugin/plugin.json` 中 `semantic-first` 句替换为包含以下完整含义的一行 JSON 字符串：

```text
Artifacts use compact-first, mutually exclusive small/split forms: small is the default within 500 lines and 30,000 characters; split requires an expected hard-limit overflow, explicit user approval, or an explicit target-project setting. Process-document prose is Chinese by default except for necessary code and exact technical/schema terms.
```

- [ ] **Step 5: 更新 fp-brainstorm command adapter**

把 `commands/fp-brainstorm.md` 中“按语义边界预选 split form”改为：

```markdown
- 默认预选 small form；只有预计越过 500 lines / 30,000 characters、用户明确批准，或目标项目设置明确要求时才预选 split form，语义边界仅用于拆分后的分片。
- 过程文档叙述性内容默认使用中文，代码、路径、标识符和精确 schema 词保留必要英文。
```

- [ ] **Step 6: 运行插件验证**

Run: `pwsh -NoProfile -File scripts/validate-plugin.ps1`

Expected: PASS，输出 `FeaturePilot plugin validation passed`。

- [ ] **Step 7: 提交公开契约同步**

```bash
git add scripts/validate-plugin.ps1 AGENTS.md README.md docs/user_guide/init-prd-start.md .codex-plugin/plugin.json commands/fp-brainstorm.md
git commit -m "docs: publish compact Chinese artifact defaults"
```

---

### Task 4: 全量回归与最终一致性检查

**Files:**
- Verify: `scripts/validate-plugin.ps1`
- Verify: `scripts/test-artifact-layout.ps1`
- Verify: `scripts/test-explore-contract.ps1`
- Verify: `scripts/test-sdd-benchmark-fixture.ps1`
- Verify: all modified Markdown and JSON files

**Interfaces:**
- Consumes: Tasks 1-3 的共享契约、producer/template 和公开说明。
- Produces: 可复现的完整验证结果和无旧自动拆分措辞的当前插件工作树。

- [ ] **Step 1: 扫描当前生效文件中的旧规则**

Run:

```powershell
rg -n "semantic-first|Use split form for multiple independently readable|Select split form directly when independently readable|确认内容存在可独立阅读.*拆分|内容有多个可独立阅读.*split" skills commands AGENTS.md README.md docs/user_guide .codex-plugin
```

Expected: 无匹配；历史 `docs/superpowers/**` 不在扫描范围内。

- [ ] **Step 2: 运行插件静态验证**

Run: `pwsh -NoProfile -File scripts/validate-plugin.ps1`

Expected: PASS，输出 `FeaturePilot plugin validation passed`。

- [ ] **Step 3: 运行 artifact layout 回归**

Run: `pwsh -NoProfile -File scripts/test-artifact-layout.ps1`

Expected: PASS，所有 small/split、manifest、dual-form、size-limit 和 dependency fixtures 通过。

- [ ] **Step 4: 运行 explore contract 回归**

Run: `pwsh -NoProfile -File scripts/test-explore-contract.ps1`

Expected: PASS，输出 explore contract tests passed。

- [ ] **Step 5: 运行 SDD benchmark fixture 回归**

Run: `pwsh -NoProfile -File scripts/test-sdd-benchmark-fixture.ps1`

Expected: PASS，输出 benchmark fixture validation passed。

- [ ] **Step 6: 检查格式与最终差异**

Run:

```powershell
git diff --check
git status --short
git diff --stat HEAD~3..HEAD
```

Expected: `git diff --check` 无输出；状态仅包含计划文件自身（如果计划尚未提交），最近三个实现提交只涉及计划列出的当前生效文件。

- [ ] **Step 7: 提交实现计划状态（仅计划文件尚未提交时）**

```bash
git add docs/superpowers/plans/2026-07-13-compact-artifacts-chinese-output.md
git commit -m "docs: plan compact Chinese artifact rollout"
```
