# README Storytelling Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn `README.md` into a restrained, story-led developer homepage and move installation, command, architecture, and artifact detail into three focused documents under `docs/` without changing FeaturePilot runtime behavior.

**Architecture:** `README.md` becomes a human-facing landing page and navigation hub. `docs/getting-started.md`, `docs/reference/commands-and-skills.md`, and `docs/reference/architecture-and-artifacts.md` own the detailed human documentation, while `skills/` and `skills/_shared/` remain the Agent runtime sources of truth. A focused PowerShell contract test verifies document responsibilities, complete command coverage, and local-link integrity; existing domain tests move technical README assertions to the corresponding docs.

**Tech Stack:** Markdown, PowerShell 5-compatible contract tests, Git, existing `scripts/validate-plugin.ps1` test orchestration.

## Global Constraints

- Target readers are developers evaluating or adopting FeaturePilot.
- Tone is story-led but restrained: real development pain, short paragraphs, no unverifiable metrics or exaggerated claims.
- README target is approximately 120–150 lines; contract tolerance is 100–170 lines.
- Keep `1.0.0`, Claude Code, Codex, DeepSeek Harness, all 12 public commands, specialist guides, and release notes discoverable.
- `skills/` and `skills/_shared/` remain runtime contract owners; human docs do not override them.
- Do not modify command names, skill names, trigger rules, state machines, evidence schemas, artifact paths, installation behavior, or canonical artifact rules.
- Preserve existing `docs/user_guide/`, `docs/release_notes/`, historical specs, and historical plans.
- All new documentation uses repository-relative Markdown links.
- PowerShell test code must remain compatible with Windows PowerShell 5.1 and UTF-8/CRLF checkouts.
- Final scope is README, the three new docs, the approved design/plan, and documentation contract tests only.

---

### Task 1: Establish the documentation contract and getting-started guide

**Files:**
- Create: `scripts/test-readme-docs-contract.ps1`
- Create: `docs/getting-started.md`
- Modify: `scripts/validate-plugin.ps1`
- Test: `scripts/test-readme-docs-contract.ps1`

**Interfaces:**
- Consumes: Current runtime manifests, `.agents/skills/sync-plugin-runtimes/SKILL.md`, and the existing installation sections in `README.md`.
- Produces: `Read-Utf8`, `Assert-Condition`, and `Test-LocalMarkdownLinks` test helpers; a human installation/update/verification guide; a validator registration block used by the remaining tasks.

- [ ] **Step 1: Write the failing documentation contract test**

Create `scripts/test-readme-docs-contract.ps1` with strict path and local-link checks:

```powershell
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "README/docs contract validation failed: $message"
    }
}

function Read-Utf8([string]$relativePath) {
    $path = Join-Path $root $relativePath
    Assert-Condition (Test-Path -LiteralPath $path -PathType Leaf) "missing document: $relativePath"
    return [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
}

function Test-LocalMarkdownLinks([string]$relativePath, [string]$text) {
    $sourceDirectory = Split-Path -Parent (Join-Path $root $relativePath)
    foreach ($match in [regex]::Matches($text, '\[[^\]]+\]\((?<target>[^)]+)\)')) {
        $target = $match.Groups['target'].Value.Split('#')[0]
        if (-not $target -or $target -match '^(?:https?://|mailto:|#)') { continue }
        $decodedTarget = [Uri]::UnescapeDataString($target)
        $resolved = [IO.Path]::GetFullPath((Join-Path $sourceDirectory $decodedTarget))
        if (-not (Test-Path -LiteralPath $resolved)) { return $false }
    }
    return $true
}

$gettingStarted = Read-Utf8 'docs\getting-started.md'
foreach ($anchor in @(
    '# 开始使用 FeaturePilot'
    '## Claude Code'
    '## Codex'
    '## DeepSeek Harness'
    'sync-plugin-runtimes.ps1'
    '-VerifyOnly'
    'validate-plugin.ps1'
    'new task'
    '无需重启'
)) {
    Assert-Condition ($gettingStarted.Contains($anchor)) "getting-started lost anchor: $anchor"
}
Assert-Condition (Test-LocalMarkdownLinks 'docs\getting-started.md' $gettingStarted) 'getting-started contains a broken local link'

Write-Output 'README/docs contract validation passed.'
```

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-readme-docs-contract.ps1
```

Expected: FAIL with `missing document: docs\getting-started.md`.

- [ ] **Step 3: Create the getting-started guide**

Create `docs/getting-started.md` with this exact responsibility order:

```markdown
# 开始使用 FeaturePilot

FeaturePilot 在 Claude Code、Codex 与 DeepSeek Harness 中共享同一套 `skills/`。选择你的运行时完成安装，然后从一个新会话开始。

## 先选你的运行时

| 运行时 | 加载方式 | 更新后如何生效 |
|---|---|---|
| Claude Code | Claude plugin marketplace | 重启 Claude Code |
| Codex | personal plugin source/cache | 创建 new task |
| DeepSeek Harness | `~/.dsh/skills` | 新会话自动加载，无需重启 |

## Claude Code

[保留当前 README 中 marketplace add、plugin install、重启和示例命令。]

## Codex

[保留当前 README 中 personal marketplace、plugin source/cache、plugin add 和 new task 说明。]

## DeepSeek Harness

[保留当前 README 中 DSH skills root、`$DSH_HOME`、Chokidar 和新会话说明。]

## 一次同步三端

[保留 `sync-plugin-runtimes.ps1` 正常模式与 `-VerifyOnly` 命令，并说明逐文件 SHA-256 验证。]

## 验证仓库插件

[保留 `scripts/validate-plugin.ps1` 命令。]

## 下一步

- 返回 [README](../README.md)
- 查看 [命令与技能参考](reference/commands-and-skills.md)
- 查看 [架构与产物参考](reference/architecture-and-artifacts.md)
```

Replace bracketed instructions with the exact current commands and facts from `README.md` and `.agents/skills/sync-plugin-runtimes/SKILL.md`; do not leave bracketed prose in the file.

- [ ] **Step 4: Register the focused validator**

Add this reachable block near the other focused validators in `scripts/validate-plugin.ps1`:

```powershell
$readmeDocsContractValidator = Join-Path $root 'scripts\test-readme-docs-contract.ps1'
Assert-Condition (Test-Path $readmeDocsContractValidator) 'focused README/docs contract validator is missing'
& powershell -NoProfile -ExecutionPolicy Bypass -File $readmeDocsContractValidator
Assert-Condition ($LASTEXITCODE -eq 0) 'focused README/docs contract validator failed'
```

- [ ] **Step 5: Run the focused test and global validator**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-readme-docs-contract.ps1
```

Expected: `README/docs contract validation passed.`

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
```

Expected: existing suites plus the new README/docs suite pass.

- [ ] **Step 6: Commit the independently useful installation guide**

```bash
git add docs/getting-started.md scripts/test-readme-docs-contract.ps1 scripts/validate-plugin.ps1
git commit -m "docs: add FeaturePilot getting started guide"
```

---

### Task 2: Create the complete command and skill reference

**Files:**
- Create: `docs/reference/commands-and-skills.md`
- Modify: `scripts/test-readme-docs-contract.ps1`
- Modify: `scripts/test-eli5-contract.ps1`
- Modify: `scripts/test-explore-contract.ps1`
- Modify: `scripts/test-coverage-contract.ps1`
- Modify: `scripts/test-module-review-contract.ps1`
- Test: `scripts/test-readme-docs-contract.ps1`

**Interfaces:**
- Consumes: `commands/fp-*.md`, matching `skills/fp-*/SKILL.md`, and existing specialist user guides.
- Produces: One human intent-to-command reference covering every public command exactly once; domain tests that check detailed human documentation in the reference or specialist guide rather than README.

- [ ] **Step 1: Extend the focused test for complete command coverage**

Add:

```powershell
$commandsReference = Read-Utf8 'docs\reference\commands-and-skills.md'
$commandNames = @(
    Get-ChildItem (Join-Path $root 'commands') -Filter 'fp-*.md' -File |
        ForEach-Object { $_.BaseName } |
        Sort-Object
)
foreach ($commandName in $commandNames) {
    Assert-Condition (
        [regex]::Matches($commandsReference, '(?<![A-Za-z0-9-])' + [regex]::Escape($commandName) + '(?![A-Za-z0-9-])').Count -ge 1
    ) "commands reference omits $commandName"
}
foreach ($anchor in @(
    '# FeaturePilot 命令与技能参考'
    '## 从你的问题出发'
    '## 完整命令表'
    '## 默认 direct 与显式 SDD'
    'docs/user_guide/fp-coverage.md'
    'docs/user_guide/fp-module-review.md'
)) {
    Assert-Condition ($commandsReference.Contains($anchor)) "commands reference lost anchor: $anchor"
}
Assert-Condition (Test-LocalMarkdownLinks 'docs\reference\commands-and-skills.md' $commandsReference) 'commands reference contains a broken local link'
```

Use correct relative link strings in the final assertions (`../user_guide/...` from `docs/reference/`).

- [ ] **Step 2: Run and verify RED**

Expected: FAIL with `missing document: docs\reference\commands-and-skills.md`.

- [ ] **Step 3: Create `commands-and-skills.md`**

Use this structure:

```markdown
# FeaturePilot 命令与技能参考

## 从你的问题出发
[Intent table: understand, explain, quick change, PRD/full flow, Figma/design review/database adaptation, coverage/module/final review/archive.]

## 完整命令表
[Exactly one row for each of the 12 files currently under commands/: archive, coverage, design-review, eli5, explore, figma, final-review, init, module-review, prd, quick, start.]

## 命令与技能如何配合
[Explain thin command adapters and runtime skills without copying full runtime contracts.]

## 默认 direct 与显式 SDD
[State current selection boundary: confirmed plans default to fp-execute; only explicit SDD request or recorded SDD resume selects fp-execute-sdd.]

## 专项流程
[Link coverage and module-review guides; summarize design-review, db-adapter, Figma and final-review.]

## 下一步
[Links to README, getting started, architecture reference.]
```

Include exact public names and descriptions from current command/skill sources. Do not publish internal handoff fields or private prompt schemas.

- [ ] **Step 4: Move domain documentation assertions off README**

Update tests:

- `test-eli5-contract.ps1`: read `docs/reference/commands-and-skills.md`; move detailed `直接展示中文图解`, `原始 HTML 标签`, `专用网页图解`, and `默认不写仓库` assertions there. README later retains only `fp-eli5` discoverability.
- `test-explore-contract.ps1`: keep detailed public behavior on `docs/user_guide/init-prd-start.md` and commands reference; README later only needs the `fp-explore` scenario entry.
- `test-coverage-contract.ps1`: remove README from detailed coverage contract surfaces. Keep README link discovery; detailed coverage assertions remain on `docs/user_guide/fp-coverage.md` and `init-prd-start.md`.
- `test-module-review-contract.ps1`: remove README from detailed module-review surfaces. Keep the README link; detailed assertions remain on `docs/user_guide/fp-module-review.md` and `init-prd-start.md`.

- [ ] **Step 5: Run focused and affected tests**

Run the new docs test plus the four modified domain tests. Expected: all pass.

- [ ] **Step 6: Commit the command reference**

```bash
git add docs/reference/commands-and-skills.md scripts/test-readme-docs-contract.ps1 scripts/test-eli5-contract.ps1 scripts/test-explore-contract.ps1 scripts/test-coverage-contract.ps1 scripts/test-module-review-contract.ps1
git commit -m "docs: centralize command and skill reference"
```

---

### Task 3: Create architecture/artifact reference and migrate technical assertions

**Files:**
- Create: `docs/reference/architecture-and-artifacts.md`
- Modify: `scripts/test-readme-docs-contract.ps1`
- Modify: `scripts/validate-plugin.ps1`
- Modify: `scripts/test-codegraph-contract.ps1`
- Modify: `scripts/test-init-information-layer-contract.ps1`
- Modify: `scripts/test-ui-e2e-integration-contract.ps1`
- Test: `scripts/test-readme-docs-contract.ps1`

**Interfaces:**
- Consumes: `skills/_shared/workspace-rules.md`, `artifact-layout.md`, `decision-ledger.md`, `codegraph.md`, `ui-e2e-contract.md`, current README architecture/trees, and specialist guides.
- Produces: One human technical reference; technical public-doc tests that target this reference while runtime tests continue targeting shared contracts.

- [ ] **Step 1: Extend the focused test for architecture ownership**

Add checks for:

```powershell
$architectureReference = Read-Utf8 'docs\reference\architecture-and-artifacts.md'
foreach ($anchor in @(
    '# FeaturePilot 架构与产物参考'
    'skills/_shared/workspace-rules.md'
    'skills/_shared/artifact-layout.md'
    'skills/_shared/decision-ledger.md'
    'skills/_shared/codegraph.md'
    'skills/_shared/ui-e2e-contract.md'
    'manifest-only default'
    'compact-first'
    '500 lines'
    '30,000 characters'
    'BROWSER_CAPABILITY_GATE'
    'dirty-after-write'
    'post-write-sync'
    'fp-docs/archive/'
)) {
    Assert-Condition ($architectureReference.Contains($anchor)) "architecture reference lost anchor: $anchor"
}
Assert-Condition (Test-LocalMarkdownLinks 'docs\reference\architecture-and-artifacts.md' $architectureReference) 'architecture reference contains a broken local link'
```

- [ ] **Step 2: Run and verify RED**

Expected: FAIL with `missing document: docs\reference\architecture-and-artifacts.md`.

- [ ] **Step 3: Create the architecture/artifact reference**

Use this ordered structure:

```markdown
# FeaturePilot 架构与产物参考
## 一张图看懂三端架构
## command、skill 与 shared contract
## 项目信息层
## 变更产物与执行证据
## Canonical small/split 规则
## CodeGraph 可选导航层
## UI/E2E、Figma 与 final review
## 归档与历史
## 从 OpenSpec 借鉴了什么
## 运行时事实源
```

Move and reconcile the current README architecture diagram, information-layer tree, artifact table/tree, CodeGraph lifecycle, UI/E2E explanation, Figma/final-review boundaries, OpenSpec notes, and process-language rule. Use links to runtime owner files and specialist guides; do not invent new behavior.

- [ ] **Step 4: Migrate technical README assertions**

- In `validate-plugin.ps1`, remove README from the detailed compact-first/process-language public surfaces; add `docs\reference\architecture-and-artifacts.md` instead. Keep README discovery in the new focused test.
- In `test-codegraph-contract.ps1`, replace README in the detailed CodeGraph documentation surfaces with `docs/getting-started.md` and/or architecture reference. The installation command belongs to getting-started; lifecycle/freshness belongs to architecture reference.
- In `test-init-information-layer-contract.ps1`, replace README’s `manifest-only default` assertion with architecture reference while keeping the user guide and runtime owners.
- In `test-ui-e2e-integration-contract.ps1`, require the detailed staged UI/E2E section in architecture reference and user guide, not README.

- [ ] **Step 5: Run focused and affected tests**

Run docs contract, global validator, CodeGraph contract, init information-layer contract, and UI/E2E integration contract. Expected: all pass.

- [ ] **Step 6: Commit the architecture reference**

```bash
git add docs/reference/architecture-and-artifacts.md scripts/test-readme-docs-contract.ps1 scripts/validate-plugin.ps1 scripts/test-codegraph-contract.ps1 scripts/test-init-information-layer-contract.ps1 scripts/test-ui-e2e-integration-contract.ps1
git commit -m "docs: move architecture and artifact reference under docs"
```

---

### Task 4: Rewrite README as the developer landing page

**Files:**
- Modify: `README.md`
- Modify: `scripts/test-readme-docs-contract.ps1`
- Modify: `scripts/test-coverage-contract.ps1`
- Modify: `scripts/test-module-review-contract.ps1`
- Modify: `scripts/test-eli5-contract.ps1`
- Modify: `scripts/test-explore-contract.ps1`
- Test: `scripts/test-readme-docs-contract.ps1`

**Interfaces:**
- Consumes: The three new docs and existing specialist/release guides.
- Produces: A 100–170-line landing page with value narrative, three-minute start, scenario routing, concise artifact value, and complete docs navigation.

- [ ] **Step 1: Extend the focused test with the final README contract**

Add:

```powershell
$readme = Read-Utf8 'README.md'
$readmeLineCount = @($readme -split "`r?`n").Count
Assert-Condition ($readmeLineCount -ge 100 -and $readmeLineCount -le 170) "README line count is $readmeLineCount; expected 100..170"

foreach ($anchor in @(
    '# FeaturePilot'
    '把一句需求，稳稳带到可交付代码'
    'Claude Code'
    'Codex'
    'DeepSeek Harness'
    '## AI 写得很快，为什么开发还是会失控？'
    '## FeaturePilot 怎么接住开发过程？'
    '## 3 分钟开始'
    '## 按场景选择入口'
    '## 它会留下什么？'
    '## 继续深入'
    'docs/getting-started.md'
    'docs/reference/commands-and-skills.md'
    'docs/reference/architecture-and-artifacts.md'
    'docs/user_guide/fp-coverage.md'
    'docs/user_guide/fp-module-review.md'
    'docs/release_notes/1.0.0.md'
)) {
    Assert-Condition ($readme.Contains($anchor)) "README lost landing-page anchor: $anchor"
}

foreach ($forbidden in @(
    '## 核心技能'
    '## 输出目录'
    '## Codex 使用方式'
    '## DeepSeek Harness 使用方式'
    '├── .fp-coverage/'
    'npm install -g @colbymchenry/codegraph@latest'
    '| 逻辑产物 | 小型形式 | 拆分形式 |'
    'SOURCE_READY -> STATIC_UI_READY'
)) {
    Assert-Condition (-not $readme.Contains($forbidden)) "README still embeds technical-reference content: $forbidden"
}
Assert-Condition (Test-LocalMarkdownLinks 'README.md' $readme) 'README contains a broken local link'
```

- [ ] **Step 2: Run and verify RED**

Expected: FAIL because the current README is about 327 lines and contains forbidden technical sections.

- [ ] **Step 3: Rewrite README with the approved narrative**

Write the final README in this exact section order:

```markdown
# FeaturePilot (`fp`)
> **把一句需求，稳稳带到可交付代码。**
[One-paragraph definition, runtime badges/text, release link.]

## AI 写得很快，为什么开发还是会失控？
[Three short pain paragraphs and restrained transition.]

## FeaturePilot 怎么接住开发过程？
`想清楚 → 设计清楚 → 拆成任务 → 验证着做 → 留下证据`
[Five short value bullets.]

## 3 分钟开始
[Runtime installation link, `/fp-init`, route choice, one compact example.]

## 按场景选择入口
[Problem-first table covering all 12 public commands by grouped rows.]

## 它会留下什么？
[Compact fp-docs tree and three value bullets.]

## 为什么它适合长期协作？
[Recoverability, evidence, three-runtime consistency; no detailed contracts.]

## 继续深入
[Links to the three new docs, existing guides, release notes.]

## 维护与验证
[One validator command and contributor pointers.]
```

Use short paragraphs, sentence-style headings, bold only for scan anchors, and no invented claims. Ensure all 12 commands are discoverable either directly in the scene table or through an explicit “完整命令参考” link; the focused test remains the authoritative full-coverage check for the commands reference.

- [ ] **Step 4: Finish domain-test migration**

Update affected tests so README checks only discovery links or short scenario terms:

- coverage: `fp-coverage` plus coverage guide link;
- module review: `fp-module-review` plus module guide link;
- ELI5: `fp-eli5` only; detailed presentation modes remain in commands reference/spec;
- explore: `fp-explore` only.

No domain test should require README to duplicate internal artifact paths, bootstrap dependencies, status vocabularies, or lifecycle rules.

- [ ] **Step 5: Run all documentation and domain tests**

Run focused docs, coverage, module review, ELI5, explore, CodeGraph, init, and UI/E2E tests. Expected: all pass.

- [ ] **Step 6: Run complete repository verification**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
```

Then run every `scripts/test-*.ps1`; expected: all pass. Run `git diff --check`; expected: exit 0. Run the focused local-link check; expected: all links resolve.

Verify final diff scope contains only:

- `README.md`
- `docs/getting-started.md`
- `docs/reference/commands-and-skills.md`
- `docs/reference/architecture-and-artifacts.md`
- approved design/plan files
- documentation contract tests and validator registration

- [ ] **Step 7: Commit the landing-page rewrite**

```bash
git add README.md docs scripts/test-readme-docs-contract.ps1 scripts/test-coverage-contract.ps1 scripts/test-module-review-contract.ps1 scripts/test-eli5-contract.ps1 scripts/test-explore-contract.ps1 scripts/test-codegraph-contract.ps1 scripts/test-init-information-layer-contract.ps1 scripts/test-ui-e2e-integration-contract.ps1 scripts/validate-plugin.ps1
git commit -m "docs: reshape README as developer landing page"
```

## Plan Self-Review

- Spec coverage: all README sections, three new docs, test migration, command completeness, runtime discoverability, local links, and no-behavior-change constraints map to Tasks 1–4.
- Placeholder scan: bracketed prose appears only as an explicit instruction in plan examples and must be replaced during implementation; no generated deliverable may retain it.
- Interface consistency: all tasks use the same `scripts/test-readme-docs-contract.ps1`, the same three document paths, and the same validator registration name.
- Scope: no command/skill/runtime source is modified; only human docs and documentation-validation code change.
