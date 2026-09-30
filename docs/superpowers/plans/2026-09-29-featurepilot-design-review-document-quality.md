# FeaturePilot Document Style and Design Review Quality Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add one self-contained document-style contract for FeaturePilot PRD, proposal, design, and review artifacts while upgrading design investigation and `review.md` into an independently readable engineering review document.

**Architecture:** Put reusable writing rules in `skills/_shared/document-style.md`, then load that file just in time after each producer's existing gate and immediately before its output template. Keep artifact-specific semantics in the four producer skills/templates, enforce the links and invariants with focused PowerShell contract tests, and register those tests in the global plugin validator.

**Tech Stack:** Markdown prompt contracts and output templates; PowerShell 5/7 static contract tests; FeaturePilot command adapters and plugin validation scripts.

## Global Constraints

- The approved specification is `docs/superpowers/specs/2026-09-29-featurepilot-design-review-quality-design.md`.
- Apply the shared style contract only to PRD, proposal, backend/frontend design, and `review.md`. Do not extend it to task plans, execution progress, prototype evidence, or unrelated artifacts.
- Preserve all existing Decision Ledger states, per-item confirmation, separate write authorization, canonical artifact layout, and fixed template schemas.
- `fp-brainstorm` remains the only technical-design owner. `fp-design-review` remains a read-only canonical-design consumer and must never invent or repair design facts.
- The shared contract is a repository-owned snapshot derived from `https://github.com/ruanyf/document-style-guide` at commit `5719517`, whose README marks the content as public domain.
- Runtime files must not read, mention as a dependency, or require `D:\01-code\document-style-guide`; no runtime network fetch is allowed.
- “Must”, “recommended”, and “exact-content exception” rules remain distinct. Sentence-length guidance must not become a character-count failure gate.
- Exact code, commands, paths, URLs, hashes, API fields, model fields, fixed headings, table schemas, Decision Ledger content, user quotations, and error messages must not be rewritten for style.
- Existing limits remain: every generated Markdown file is at most 500 lines and 30,000 characters; every `commands/fp-*.md` adapter is at most 20 lines.
- Narrative defaults to Chinese. Code, commands, paths, branch names, hashes, API fields, and other exact technical identifiers retain necessary English.
- The angle-bracket markers shown in output-template snippets are required runtime metavariables, not unfinished implementation-plan content.
- Do not commit, push, open a pull request, or synchronize installed plugin runtimes. End each task with tests and a diff/status checkpoint instead of a commit.

## File and Responsibility Map

| File | Responsibility |
| --- | --- |
| `skills/_shared/document-style.md` | Single source of truth for provenance, required/recommended writing rules, exact-content exceptions, logical-artifact self-review, and safe repair behavior |
| `skills/_shared/decision-ledger.md` | Shared contract for understandable decision questions; no output-format ownership |
| `skills/fp-prd/SKILL.md` | JIT loading of the style contract after final PRD approval |
| `skills/fp-prd/prd-template.md` | PRD-specific readable-product-language self-review without changing the six-section schema |
| `skills/fp-propose/SKILL.md` | JIT loading of the style contract after proposal write authorization |
| `skills/fp-propose/proposal-template.md` | Proposal-specific readability self-review without changing Why/What/Capabilities/Out of Scope/Impact |
| `skills/fp-brainstorm/SKILL.md` | Real-code model investigation, understandable design questions, and JIT style loading before design output |
| `skills/fp-brainstorm/design-template.md` | Reviewable model code, physical-storage/constraint/migration slots, and design readability self-review |
| `skills/fp-design-review/SKILL.md` | Canonical-design sufficiency gate, precise return-to-design failure path, and complete review generation |
| `skills/fp-design-review/review-template.md` | Independently readable `review.md` structure and review-specific readability checks |
| `skills/fp-start/SKILL.md` | Outer-flow handoff wording for complete review output and insufficiency recovery |
| `commands/fp-prd.md` | Thin public checksum for PRD style loading |
| `commands/fp-start.md` | Thin public checksum for proposal/design/review quality routing |
| `commands/fp-design-review.md` | Thin public checksum for sufficiency, read-only generation, and shared style |
| `scripts/test-document-style-contract.ps1` | Focused static coverage for shared style provenance, layering, JIT consumers, templates, docs, and validator wiring |
| `scripts/test-design-review-contract.ps1` | Focused static coverage for model-design completeness and full review output |
| `scripts/test-decision-gate-contract.ps1` | Existing decision-gate suite extended with understandable-question and model-investigation anchors |
| `scripts/validate-plugin.ps1` | Global invocation of both new focused suites plus updated capability anchors |
| `docs/reference/commands-and-skills.md` | User-visible explanation of independent review output and shared readability rules |

---

### Task 1: Establish the shared document-style contract

**Files:**
- Create: `scripts/test-document-style-contract.ps1`
- Create: `skills/_shared/document-style.md`

**Interfaces:**
- Consumes: The approved source baseline `ruanyf/document-style-guide@5719517` and existing artifact-layout terminology (`logical artifact`, `manifest order`, `unique owner`).
- Produces: `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md`, which Tasks 2–4 load after their existing gates and before their output templates.

- [ ] **Step 1: Write the failing shared-contract test**

Create `scripts/test-document-style-contract.ps1` with this complete initial content:

```powershell
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "Document-style contract validation failed: $message"
    }
}

function Read-Utf8([string]$relativePath) {
    $path = Join-Path $root $relativePath
    Assert-Condition (Test-Path -LiteralPath $path -PathType Leaf) "missing file: $relativePath"
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Assert-Anchors([string]$text, [string[]]$anchors, [string]$surface) {
    foreach ($anchor in $anchors) {
        Assert-Condition ($text.Contains($anchor)) "$surface lost anchor: $anchor"
    }
}

$contractPath = 'skills\_shared\document-style.md'
$contract = Read-Utf8 $contractPath

Assert-Anchors $contract @(
    'https://github.com/ruanyf/document-style-guide'
    '5719517'
    'public domain'
    '## 必须遵守'
    '## 建议遵守'
    '## 精确内容例外'
    '## Document readability self-review'
    'PRD'
    'proposal'
    'design'
    'review.md'
    'manifest order'
    '一个段落只表达一个主题'
    '主动语态'
    '肯定表达'
    '中文与英文或技术标识符之间保留一个半角空格'
    '标题末尾不使用句号、逗号、分号或冒号'
    '正文'
    '表格'
    '列表'
    '代码块'
    '引用第三方'
    '普通叙述句优先控制在约 20 个汉字'
    '不作为逐字计数失败条件'
    'Decision Ledger schema'
    '样式修复不得改变已确认需求、技术结论、字段含义或决策状态'
) 'shared document-style contract'

Assert-Condition (-not $contract.Contains('D:\01-code\document-style-guide')) 'shared contract has a machine-local runtime dependency'
Assert-Condition (@($contract -split "`r?`n").Count -le 500) 'shared contract exceeds 500 lines'
Assert-Condition ($contract.Length -le 30000) 'shared contract exceeds 30,000 characters'

Write-Output 'Document-style contract validation passed.'
```

- [ ] **Step 2: Run the focused test and verify the missing-file failure**

Run:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-document-style-contract.ps1
```

Expected: non-zero exit with `missing file: skills\_shared\document-style.md`.

- [ ] **Step 3: Create the self-contained shared contract**

Create `skills/_shared/document-style.md` with the following complete content:

```markdown
# FeaturePilot Document Style Contract

## 来源与适用范围

本契约提炼自 [ruanyf/document-style-guide](https://github.com/ruanyf/document-style-guide) 的 `5719517` 基线。上游 README 将内容声明为 public domain。

本文件是 FeaturePilot 仓库内的自包含规则快照。运行时不得读取本机外部副本，不得通过网络刷新规则，也不得因上游变化自动改变当前契约。

本契约只适用于以下 logical artifact：

- `fp-prd` 生成的 PRD；
- `fp-propose` 生成的 proposal；
- `fp-brainstorm` 生成的 backend/frontend design；
- `fp-design-review` 生成的 `review.md`。

它不扩展到 task plan、执行进度、prototype evidence 或其他未列产物。

## 加载时机与优先级

产物 skill 必须先完成自己已有的访谈、Decision Ledger、设计充分性和写入授权门禁。门禁通过后，先读取本契约，再读取对应输出模板。

本契约只规范表达与排版。以下内容拥有更高优先级：

1. 已确认的需求、业务规则和技术结论；
2. 固定章节、表格列和 Decision Ledger schema；
3. canonical artifact layout、manifest order 和 unique owner；
4. 产物创建、覆盖、转换与删除授权。

发生冲突时，保留精确语义与固定 schema，只对周围解释文字应用本契约。

## 必须遵守

### 读者与结构

- 文档开头先说明目的、范围、方案主线或结论，再展开细节。
- 标题不得跳级，也不得与直接上级重名。
- 标题最多四级，并优先控制在三级以内。固定模板要求的四级标题可以保留。
- 除固定 schema 外，避免创建只有一个子标题的孤立层级。

### 段落与句子

- 一个段落只表达一个主题，中心句尽量放在段首。
- 每段不超过 7 行，并优先控制在 4 行以内。段落之间保留一个空行。
- 优先使用短句、简单句、主动语态和肯定表达。
- 避免双重否定、“一逗到底”和指代不明。
- 必要术语第一次出现时使用直白中文解释。
- 不使用冷僻、生造或只有作者能理解的缩写。

### 空格、标点与数值

- 中文与英文或技术标识符之间保留一个半角空格。
- 中文句子使用全角标点；完整英文句子使用半角标点。
- 标题末尾不使用句号、逗号、分号或冒号。
- 同一 logical artifact 内的中文与数字空格风格保持一致。
- 数值、单位、百分比和范围写法在同一 logical artifact 内保持一致。

### 信息载体与来源

- 正文解释原因与结论。
- 表格承载结构化比较。
- 列表承载并列事项。
- 代码块保留精确实现或示例。
- 同一事实不得在正文、表格、列表和代码块中重复描述。
- 引用第三方文字、图片或规范时标明来源。

## 建议遵守

- 普通叙述句优先控制在约 20 个汉字；超过 40 个汉字时优先拆句。
- 优先使用三级以内标题和 4 行以内段落。
- 4 位以上数值优先使用千分位。
- 数值范围两端都写单位或百分号。
- 中文并列项的最后一项优先使用“和”连接。

这些数值是生成与人工自检目标，不作为逐字计数失败条件。

## 精确内容例外

以下精确片段不得为满足写作规则而改写：

- 代码、命令、路径、URL、哈希和 API 字段；
- 类名、函数名、数据库字段和其他精确技术标识符；
- 固定模板标题、表格列名和 Decision Ledger schema；
- 用户原文、错误消息和需要精确引用的第三方内容。

例外只豁免精确片段，不豁免周围解释文字。样式修复不得改变已确认需求、技术结论、字段含义或决策状态。

## Document readability self-review

对 small form 直接检查完整文件。对 split form，先验证 fragment manifest，再按 manifest order 读取全部分片，并同时检查每个文件和完整 logical artifact。

按以下顺序检查：

1. **结构**：开头是否先给目的、范围、主线或结论；标题是否连续且不重复上级标题。
2. **语言**：段落是否主题单一；句子是否简短、主动、肯定；术语和指代是否清楚。
3. **排版**：中英文空格、标点、数字、单位和范围是否一致。
4. **载体**：正文、表格、列表和代码是否各司其职，是否重复表达同一事实。
5. **例外**：精确内容是否原样保留，例外是否只作用于必要片段。
6. **语义保护**：样式修复是否保持已确认内容、固定 schema、Decision Ledger 和 canonical layout 不变。

## 修复与失败处理

拆分长句、补空格、明确指代、解释术语和删除重复说明等纯表达问题，可以依据已确认内容直接修复。

如果修复可能改变范围、业务规则、技术结论、字段含义、固定 schema 或 Decision Ledger，不得自动改写。精确内容只记录适用例外；原文自身存在语义歧义时，返回对应内容所有者重新确认。

样式检查不得绕过写入授权，也不得成为覆盖现有产物的额外授权。
```

- [ ] **Step 4: Run the focused test and verify the base contract passes**

Run:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-document-style-contract.ps1
```

Expected: exit `0` and `Document-style contract validation passed.`

- [ ] **Step 5: Record a no-commit checkpoint**

Run:

```bash
git status --short
```

Expected: both new files are untracked; do not stage or commit them.

---

### Task 2: Integrate PRD and proposal output

**Files:**
- Modify: `scripts/test-document-style-contract.ps1`
- Modify: `skills/fp-prd/SKILL.md:241-278`
- Modify: `skills/fp-prd/prd-template.md:4-20,150-183`
- Modify: `skills/fp-propose/SKILL.md:66-108`
- Modify: `skills/fp-propose/proposal-template.md:4-81`
- Modify: `commands/fp-prd.md:6-14`

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md` from Task 1.
- Produces: Two JIT consumer contracts and two artifact-specific `Document readability self-review` sections. Later global validation relies on the exact shared path and self-review heading.

- [ ] **Step 1: Extend the focused test with failing PRD/proposal assertions**

Insert before the final `Write-Output` in `scripts/test-document-style-contract.ps1`:

```powershell
$prdSkill = Read-Utf8 'skills\fp-prd\SKILL.md'
$prdTemplate = Read-Utf8 'skills\fp-prd\prd-template.md'
$proposalSkill = Read-Utf8 'skills\fp-propose\SKILL.md'
$proposalTemplate = Read-Utf8 'skills\fp-propose\proposal-template.md'
$prdCommand = Read-Utf8 'commands\fp-prd.md'

$prdLoadContract = 'read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md` completely, then read `${CLAUDE_PLUGIN_ROOT}/skills/fp-prd/prd-template.md` completely'
$proposalLoadContract = '读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md`，再读取 `${CLAUDE_PLUGIN_ROOT}/skills/fp-propose/proposal-template.md`'

Assert-Condition ($prdSkill.Contains($prdLoadContract)) 'fp-prd does not load document style before its template'
Assert-Condition ($proposalSkill.Contains($proposalLoadContract)) 'fp-propose does not load document style before its template'
Assert-Anchors $prdTemplate @(
    '## Document readability self-review'
    '固定六章结构和必需四级标题保持不变'
    '先说明用户、问题、价值和业务结果'
    '不得引入实现语言'
    '按 fragment manifest 顺序检查完整 logical PRD'
) 'PRD template readability review'
Assert-Anchors $proposalTemplate @(
    '## Document readability self-review'
    '`Why` 先说明痛点、目标和现在为什么做'
    '每个 `What Changes` 小节只承载一个变更主题'
    '`Impact` 中的路径和技术标识符保持精确'
    '按 fragment manifest 顺序检查完整 logical proposal'
) 'proposal template readability review'
Assert-Anchors $prdCommand @('共享文档风格契约', '写入门禁后') 'fp-prd command checksum'
```

- [ ] **Step 2: Run the focused test and verify the consumer assertions fail**

Run:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-document-style-contract.ps1
```

Expected: non-zero exit at `fp-prd does not load document style before its template`.

- [ ] **Step 3: Add JIT loading to `fp-prd`**

Replace the first paragraph under `## PRD output contract` with this exact ordering:

```markdown
Do not load the shared writing contract or output template during interview turns. After the final PRD confirmation summary is explicitly approved and immediately before writing, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md` completely, then read `${CLAUDE_PLUGIN_ROOT}/skills/fp-prd/prd-template.md` completely. Apply the shared contract to the complete logical PRD without changing the Mandatory PRD Structure, confirmed product content, or product-language gate.
```

Update the `## Self-Review` paragraph so it explicitly runs the template's structure, product-language, business-closure, and document-readability checklists over the manifest-ordered logical PRD. Preserve the existing recovery rule that unresolved product decisions return to `fp-prd-grill-me`.

- [ ] **Step 4: Add the PRD-specific readability checklist**

Insert this section immediately before `## Structure self-review` in `skills/fp-prd/prd-template.md`:

```markdown
## Document readability self-review

Apply `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md` after resolving the complete logical PRD.

- 按 fragment manifest 顺序检查完整 logical PRD，同时检查每个分片的局部结构。
- 固定六章结构和必需四级标题保持不变；四级标题属于固定 schema 例外。
- 每个功能先说明用户、问题、价值和业务结果，再说明规则、交互与异常。
- 普通段落主题单一，术语与指代清楚；实现证据先转换为产品语言。
- 不为缩短句子而拆散完整业务规则，也不得引入实现语言。
- 表格只承载结构化规则、异常、日志和验收信息，不重复相邻正文。
- 纯表达缺陷可依据已确认内容修复；可能改变产品含义时返回 `fp-prd-grill-me`。
```

- [ ] **Step 5: Add JIT loading to `fp-propose`**

Replace stage 3 step 5 with:

```markdown
5. 【立即用工具执行】只有全部 proposal-required 台账行终态且获得 separate write authorization 后，才读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md`，再读取 `${CLAUDE_PLUGIN_ROOT}/skills/fp-propose/proposal-template.md`。按共享写作契约填写批准的最终结构并直接写入；不要先生成 monolith 再机械拆分。把终态 Decision Ledger 和 Pre-write Confirmation Evidence 写入 `Impact` 的 unique detailed owner；不得持久化 `needs-user-confirmation` 行。
```

Replace the lazy-load sentence near the end of stage 3 with:

```markdown
Do not load the shared writing contract or `${CLAUDE_PLUGIN_ROOT}/skills/fp-propose/proposal-template.md` during exploration or questioning. Load them in that order only after the pre-write confirmation gate, so early turns carry decisions rather than output boilerplate.
```

- [ ] **Step 6: Add the proposal-specific readability checklist**

Insert this section immediately before `## Structure self-review` in `skills/fp-propose/proposal-template.md`:

```markdown
## Document readability self-review

Apply `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md` after resolving the complete logical proposal.

- 按 fragment manifest 顺序检查完整 logical proposal，同时检查每个分片的局部结构。
- `Why` 先说明痛点、目标和现在为什么做。
- 每个 `What Changes` 小节只承载一个变更主题。
- Capabilities 与 Out of Scope 使用可独立理解的行为结果，不使用需要自行解码的抽象标签。
- `Impact` 中的路径和技术标识符保持精确，周围文字说明受影响模块和原因。
- Decision Ledger 与 Pre-write Confirmation Evidence 保持原 schema 和原语义。
- 纯表达缺陷可依据已确认内容修复；可能改变范围、影响或交付策略时返回 proposal 决策门禁。
```

- [ ] **Step 7: Update the PRD command checksum without exceeding 20 lines**

Add this bullet to `commands/fp-prd.md`:

```markdown
- 写入门禁后先加载共享文档风格契约，再加载 PRD 模板；只改善表达，不改变固定六章、产品事实或确认结果。
```

- [ ] **Step 8: Run focused and PRD regression tests**

Run each command and require exit `0`:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-document-style-contract.ps1
```

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-prd-business-contract.ps1
```

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-prd-product-first-contract.ps1
```

Expected final lines: `Document-style contract validation passed.`, `PRD business contract checks passed...`, and `PRD product-first contract checks passed...`.

- [ ] **Step 9: Record a no-commit checkpoint**

Run:

```bash
git diff --check
```

Expected: no output and exit `0`. Do not stage or commit.

---

### Task 3: Make decision questions understandable and design models directly reviewable

**Files:**
- Modify: `scripts/test-decision-gate-contract.ps1:217-286,372-377`
- Modify: `scripts/test-document-style-contract.ps1`
- Modify: `skills/_shared/decision-ledger.md:22-36`
- Modify: `skills/fp-brainstorm/SKILL.md:17-35,55-64,149-177,190-204`
- Modify: `skills/fp-brainstorm/design-template.md:28-100`
- Modify: `commands/fp-start.md:8-15`

**Interfaces:**
- Consumes: Shared writing contract from Task 1 and existing terminal Decision Ledger states.
- Produces: A question-shape contract used by proposal/design decisions, verified model-design evidence, and a design template that `fp-design-review` can later consume without re-reading code.

- [ ] **Step 1: Add failing decision-question and model-design assertions**

Extend the existing `$decisionLedger` anchor list in `scripts/test-decision-gate-contract.ps1` with:

```powershell
    '可理解的决策问题'
    '为什么现在需要这个决定'
    '会影响哪些产物或运行行为'
    '每个选项采用后的实际行为'
    '主要代价或风险'
    '推荐选项及推荐理由'
    '以业务或行为结果命名'
    '必须先用直白语言解释'
```

Extend the `$brainstormSkill` assertions with:

```powershell
Assert-Anchors $brainstormSkill @(
    '项目模型规范调查'
    '公共基类'
    '字段长度常量'
    '显式字段与继承字段'
    '逻辑模型与实际物理表'
    '软删除后的唯一性含义'
    '没有实际数据库收益的迁移'
    'Django 条件化检查'
    'abstract、proxy 和 multi-table inheritance'
    '`choices` 是否进入 migration state'
    '联合索引左前缀'
    '不得擅自统一选择'
) 'fp-brainstorm model investigation'
```

Extend the `$designTemplate` assertions with:

```powershell
Assert-Anchors $designTemplate @(
    '接近实现的模型代码'
    '逻辑模型与物理存储'
    '继承字段与重复存储结论'
    '索引、约束与软删除'
    'Migration 影响'
    '技术栈专项结论'
) 'design template model review contract'
```

Then extend `scripts/test-document-style-contract.ps1` before its final output:

```powershell
$brainstormSkill = Read-Utf8 'skills\fp-brainstorm\SKILL.md'
$designTemplate = Read-Utf8 'skills\fp-brainstorm\design-template.md'
$brainstormLoadContract = '读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md`，再读取 `${CLAUDE_PLUGIN_ROOT}/skills/fp-brainstorm/design-template.md`'
Assert-Condition ($brainstormSkill.Contains($brainstormLoadContract)) 'fp-brainstorm does not load document style before its template'
Assert-Anchors $designTemplate @(
    '## Document readability self-review'
    '先给出架构主线和已确认决策'
    '模型代码、表格和正文不得重复表达同一事实'
    '按 fragment manifest 顺序检查完整 logical design'
) 'design template readability review'
```

- [ ] **Step 2: Run both focused suites and verify they fail on the new anchors**

Run:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-decision-gate-contract.ps1
```

Expected: non-zero exit naming the missing `可理解的决策问题` anchor.

Run:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-document-style-contract.ps1
```

Expected: non-zero exit at the missing `fp-brainstorm` style-load contract.

- [ ] **Step 3: Add the understandable-question contract**

Insert this section in `skills/_shared/decision-ledger.md` immediately before `## 写入前门禁`:

```markdown
## 可理解的决策问题

每个需要用户选择的问题必须说明：

1. 为什么现在需要这个决定。
2. 该决定会影响哪些产物或运行行为。
3. 每个选项采用后的实际行为。
4. 每个选项的主要代价或风险。
5. 推荐选项及推荐理由。
6. 以业务或行为结果命名的选项标签。

禁止只提供“方案 A”“双层核验”“职责边界”等需要用户自行解码的标签。用户表示不理解时，必须先用直白语言解释，再重新提问；不得把未理解的回答视为确认。

本节只规定问题是否可理解，不改变 Decision Ledger 状态、逐项确认或 separate write authorization。
```

- [ ] **Step 4: Add bounded real-code model investigation to `fp-brainstorm`**

Under `### 第一步：读取上下文`, after the current-code bullet, add:

```markdown
#### 项目模型规范调查

仅当本次变更涉及数据库模型时执行。`fp-brainstorm` 必须读取目标项目的真实代码，再展示和确认模型设计；设计阶段完成调查，`fp-design-review` 不重复扫描代码。

调查至少覆盖：

- 目标模型、公共基类、manager、mixin 和相邻版本模型；
- 字段长度常量、字段类型和序列化惯例；
- 显式字段与继承字段，以及是否重复存储；
- 逻辑模型与实际物理表；
- `null`、`blank`、默认值、索引、联合约束和排序；
- 审计、软删除和软删除后的唯一性含义；
- 发布、下线、调试等生命周期数据的归属；
- 模型元数据变化是否产生没有实际数据库收益的迁移。

#### Django 条件化检查

仅当目标项目使用 Django 且本次涉及模型时，继续检查：

- 公共 `Model`、manager 和 mixin 已提供的字段与查询行为；
- abstract、proxy 和 multi-table inheritance 创建的物理表；
- `verbose_name` 是否符合当前项目惯例；
- `choices` 是否进入 migration state；选项经常变化时，必须把“模型层接受 migration”与“serializer/service 校验”作为真实选项交给用户确认，不得擅自统一选择；
- `JSONField`、文本字段或压缩字段是否符合数据体积与读取方式；
- 联合索引左前缀是否已覆盖单列查询；
- 软删除记录是否继续占用唯一约束，以及该行为是否符合业务含义。

非 Django 项目只执行对应 ORM 与 schema migration 检查，不生成 Django 专属内容。

设计正文必须记录证据路径和最终结论。当前代码无法证明的新选择仍进入 Decision Ledger；不得把推荐写成 `code-verified`。
```

In `## 提问原则`, add a bullet requiring every question to follow `skills/_shared/decision-ledger.md#可理解的决策问题`, including real-behavior option labels and a plain-language retry when the user does not understand.

- [ ] **Step 5: Load style before the design template**

Replace the template-read sentence in stage 5 with:

```markdown
【立即用工具执行】只有上述门禁全部满足后，才读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md`，再读取 `${CLAUDE_PLUGIN_ROOT}/skills/fp-brainstorm/design-template.md`，并按实际涉及端写入设计文件。每个实际端的 unique detailed owner 写入自己的终态 `### Decision Ledger` 与 `### Pre-write Confirmation Evidence`；所有端共用 globally unique D-NNN sequence，跨端决策只能由一个 owner 持有，其他端只链接。每个 owner 的 `Covered IDs` 必须恰好覆盖自己的台账行。`design/00-index.md` 只记录 ownership，不复制决策正文，且不得持久化 `needs-user-confirmation`。
```

Update `## 设计文档格式` to say neither shared style nor the output template is loaded during Socratic questioning; after the gate, load them in the same order.

- [ ] **Step 6: Expand the design template's data-model slots**

Replace the current `### 数据模型` placeholder with:

```markdown
### 数据模型

#### 接近实现的模型代码

（展示已确认字段、类型、默认值、`null`/`blank`、关联和 Meta；只精确摘录或形成设计草图，不伪装成已实现代码。）

#### 逻辑模型与物理存储

| 逻辑对象 | ORM/Schema 对象 | 物理表或存储 | 主键与关联键 | 证据 |
| --- | --- | --- | --- | --- |
| （对象） | （模型/schema） | （真实表/集合/主题） | （主键、外键或引用） | （`path:line`） |

#### 继承字段与重复存储结论

（列出公共基类、manager、mixin 和继承字段；明确哪些字段不重复声明，以及原因。）

#### 索引、约束与软删除

（列出索引、联合约束、排序、审计、软删除，以及软删除记录是否继续占用唯一约束。）

#### 生命周期数据归属

（说明发布、下线、调试等状态或记录由哪个模型/服务持有。）

#### Migration 影响

（说明 schema 变化、数据迁移、回滚影响，以及纯元数据变化是否产生没有实际数据库收益的 migration。）

#### 技术栈专项结论

（仅记录适用技术栈的专项结论及证据。Django 模型按需覆盖公共 Model/manager/mixin、继承物理表、`verbose_name`、`choices` migration state、字段存储方式、联合索引左前缀和软删除唯一性；非 Django 项目记录对应 ORM/schema 结论，不生成 Django 占位内容。）
```

Add this section after all template/body instructions:

```markdown
## Document readability self-review

Apply `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md` after resolving each actual end and the complete logical design.

- 按 fragment manifest 顺序检查完整 logical design，同时检查每个 end/fragment 的局部结构。
- 先给出架构主线和已确认决策，再展开数据、接口、状态和前端细节。
- 首次出现的必要术语使用直白解释，精确技术标识符保持不变。
- 模型代码、表格和正文不得重复表达同一事实。
- Decision Ledger、Pre-write Confirmation Evidence、接口字段和代码保持原 schema 与原语义。
- 纯表达缺陷可依据已确认内容修复；可能改变技术选择时返回对应 `D-NNN`。
```

- [ ] **Step 7: Update the `fp-start` command checksum**

Add these bullets while keeping `commands/fp-start.md` at or below 20 lines:

```markdown
- proposal/design 写入门禁后加载共享文档风格契约；样式修复不得改变确认内容、Decision Ledger 或 canonical layout。
- 设计涉及模型时由 `fp-brainstorm` 核验真实基类、继承字段、物理存储、约束和 migration；评审阶段不重新设计。
```

- [ ] **Step 8: Run decision, style, and plugin-shape regressions**

Run:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-decision-gate-contract.ps1
```

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-document-style-contract.ps1
```

Expected: both exit `0` with their pass messages.

- [ ] **Step 9: Record a no-commit checkpoint**

Run:

```bash
git status --short
```

Expected: only the approved specification, plan, and implementation files are modified/untracked. Do not stage or commit.

---

### Task 4: Upgrade `fp-design-review` from navigation summary to full review document

**Files:**
- Create: `scripts/test-design-review-contract.ps1`
- Modify: `skills/fp-design-review/SKILL.md:21-41`
- Replace: `skills/fp-design-review/review-template.md`
- Modify: `skills/fp-start/SKILL.md:150-164`
- Modify: `commands/fp-design-review.md:6-12`
- Modify: `scripts/test-document-style-contract.ps1`

**Interfaces:**
- Consumes: Canonical design content from Task 3, shared style from Task 1, and the existing artifact-layout/Decision Ledger contracts.
- Produces: A deterministic sufficiency decision (`generate` or precise `return to fp-brainstorm`) and one complete small-form `review.md` with no new design facts.

- [ ] **Step 1: Write the failing design-review contract test**

Create `scripts/test-design-review-contract.ps1`:

```powershell
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "Design-review contract validation failed: $message"
    }
}

function Read-Utf8([string]$relativePath) {
    $path = Join-Path $root $relativePath
    Assert-Condition (Test-Path -LiteralPath $path -PathType Leaf) "missing file: $relativePath"
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Assert-Anchors([string]$text, [string[]]$anchors, [string]$surface) {
    foreach ($anchor in $anchors) {
        Assert-Condition ($text.Contains($anchor)) "$surface lost anchor: $anchor"
    }
}

$brainstorm = Read-Utf8 'skills\fp-brainstorm\SKILL.md'
$designTemplate = Read-Utf8 'skills\fp-brainstorm\design-template.md'
$reviewSkill = Read-Utf8 'skills\fp-design-review\SKILL.md'
$reviewTemplate = Read-Utf8 'skills\fp-design-review\review-template.md'
$command = Read-Utf8 'commands\fp-design-review.md'

Assert-Anchors $brainstorm @(
    '项目模型规范调查'
    '逻辑模型与实际物理表'
    '软删除后的唯一性含义'
    'Django 条件化检查'
    '不得擅自统一选择'
) 'fp-brainstorm'
Assert-Anchors $designTemplate @(
    '接近实现的模型代码'
    '继承字段与重复存储结论'
    'Migration 影响'
) 'design template'

Assert-Anchors $reviewSkill @(
    '设计充分性检查'
    '完整字段定义或接近实现的模型代码'
    '逻辑模型与物理表映射'
    '关联、索引、唯一约束和软删除规则'
    '项目规范证据'
    'migration 影响'
    '不生成或覆盖 `review.md`'
    '无法生成 review.md'
    'fp-brainstorm'
    '不得重新扫描代码库'
    '不得修改设计'
) 'fp-design-review skill'

Assert-Anchors $reviewTemplate @(
    '## 评审结论'
    '## 业务和技术主线'
    '## 核心对象与职责'
    '## 数据模型评审'
    '接近实现的模型代码'
    '物理表与继承字段'
    '## 状态、并发和执行流程'
    '## 接口、权限和旧入口隔离'
    '## 前端方案'
    '## 主要风险、迁移、发布和验证'
    '具体失败场景'
    '## 评审顺序与抽查路径'
    '## 评审结论记录'
    '## 设计入口'
    '不得复制 Decision Ledger'
    '不得自行补充字段'
    '500 lines'
    '30,000 characters'
    '## Document readability self-review'
) 'review template'

Assert-Condition ([regex]::Matches($reviewTemplate, '(?m)^## 设计入口\s*$').Count -eq 1) 'review template must have exactly one design entry section'
Assert-Condition ($reviewTemplate.Contains('复选框只用于验证清单和最终评审结论')) 'review template does not restrict checkboxes'
Assert-Condition (@($reviewTemplate -split "`r?`n").Count -le 500) 'review template exceeds 500 lines'
Assert-Condition ($reviewTemplate.Length -le 30000) 'review template exceeds 30,000 characters'
Assert-Anchors $command @('设计充分性', '完整评审文档', '共享文档风格契约') 'fp-design-review command checksum'
Assert-Condition (@($command -split "`r?`n").Count -le 20) 'fp-design-review command exceeds 20 lines'

Write-Output 'Design-review contract validation passed.'
```

- [ ] **Step 2: Run the new suite and verify the old skill fails sufficiency anchors**

Run:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-design-review-contract.ps1
```

Expected: non-zero exit naming the missing `设计充分性检查` anchor.

- [ ] **Step 3: Add the canonical-design sufficiency gate**

In `skills/fp-design-review/SKILL.md`, insert a new `### 第三步：设计充分性检查` between material extraction and generation. Require every applicable design to expose enough confirmed content to populate the review. For model scope, include these exact bullets:

```markdown
数据模型范围至少包含：

- 完整字段定义或接近实现的模型代码；
- 继承字段和重复存储结论；
- 逻辑模型与物理表映射；
- 关联、索引、唯一约束和软删除规则；
- 项目规范证据；
- migration 影响。
```

Define the failure behavior exactly:

```markdown
若适用信息不足，不生成或覆盖 `review.md`。输出“无法生成 review.md”、逐项缺失内容、需要修订的精确 design 章节，以及“返回 `fp-brainstorm` 做定点修订并重新确认设计”。不得只写“设计不完整”或“请补充信息”，不得重新扫描代码库、修改设计或自行补齐字段。
```

Renumber generation to step 4. At the beginning of generation, require this order:

```markdown
【立即用工具执行】设计充分性检查通过后，读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md`，再读取 `${CLAUDE_PLUGIN_ROOT}/skills/fp-design-review/review-template.md`，生成 change 根唯一的 small-form `review.md`。
```

Update the boundary section so repeated generation is idempotent only after sufficiency passes; a failed check must preserve an existing `review.md` rather than overwrite it with a partial document.

- [ ] **Step 4: Replace the review template with a complete, scope-aware structure**

Replace `skills/fp-design-review/review-template.md` with this structure and instructions. Preserve the outer four-backtick fence so the inner model-code fence remains valid:

`````markdown
# Technical Design Review Output Contract

Read this file only after `fp-design-review` resolves canonical design artifacts, verifies every merged Decision Ledger row is terminal, and passes design sufficiency. The skill must already have loaded `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md`.

Write only `fp-docs/changes/<slug>/review.md`. It is the change-root unique review entry, always small form, and covers every actual end. Narrative defaults to Chinese; exact code, commands, paths, identifiers, and API fields retain necessary English.

Generate applicable sections only. Omit an inapplicable data/state/interface/frontend section instead of writing empty boilerplate. Never omit the opening conclusion, business/technical mainline, risks and validation, review order, conclusion record, or design entry.

````markdown
# <功能描述> — 开发设计评审

## 评审结论

<首段直接给出建议结论：通过、有条件通过或退回修改；说明最主要依据和仍需关注的风险。>

| 评审面 | 结论 | 设计依据 |
| --- | --- | --- |
| 决策 | <共 N 项；阻塞 N / 非阻塞 N；全部终态> | <唯一 design 锚点> |
| 数据 | <关键变化或无> | <唯一 design 锚点或“无”> |
| 接口 | <关键变化或无> | <唯一 design 锚点或“无”> |
| 前端 | <关键变化或无> | <唯一 design 锚点或“无”> |
| 不做事项 | <明确边界> | <唯一 design 锚点> |

## 业务和技术主线

<按触发、处理、状态变化、结果与失败收束说明完整主线；只提炼设计已有内容。>

## 核心对象与职责

| 对象/模块 | 职责 | 不负责 | 协作对象 | 设计依据 |
| --- | --- | --- | --- | --- |
| <对象> | <单一职责> | <边界> | <依赖或调用方> | <design 锚点> |

## 数据模型评审

### 接近实现的模型代码

```text
<从已确认设计精确摘录；不得自行补充字段。>
```

### 物理表与继承字段

| 逻辑对象 | 物理表/存储 | 显式字段 | 继承字段 | 重复存储结论 |
| --- | --- | --- | --- | --- |
| <对象> | <表或存储> | <字段> | <字段> | <结论> |

### 关联、索引、约束与迁移

<说明关联、索引、唯一约束、软删除语义、migration 和回滚影响；不得重新设计。>

## 状态、并发和执行流程

<仅在适用时生成；说明状态入口、并发控制、执行顺序、失败恢复和可观察结果。>

## 接口、权限和旧入口隔离

| 接口/入口 | 主键或资源 | 权限 | 兼容或隔离边界 | 设计依据 |
| --- | --- | --- | --- | --- |
| <接口或入口> | <标识> | <角色/权限点> | <新旧边界> | <design 锚点> |

## 前端方案

<仅在适用时生成；说明页面、组件、状态、路由、视觉来源和可执行 Visual Checks。>

## 主要风险、迁移、发布和验证

### 主要风险

| 具体失败场景 | 影响 | 预防或处理 | 设计依据 |
| --- | --- | --- | --- |
| <触发条件和错误结果> | <用户/数据/系统影响> | <已确认处理> | <design 锚点> |

### 迁移与发布

<说明 schema/data migration、兼容窗口、发布顺序、回滚和监控；无适用项时说明设计为何无此风险。>

### 验证清单

- [ ] <可执行命令、测试或人工检查；写出预期结果和 design 锚点。>

## 评审顺序与抽查路径

1. <最高风险章节及原因；附 design 锚点。>
2. <下一章节及原因；附 design 锚点。>

- 建议抽查：`<path:line>`

## 评审结论记录

- [ ] 通过：设计完整，可以进入计划阶段。
- [ ] 有条件通过：<必须在计划或实现前满足的条件。>
- [ ] 退回修改：<需要返回 fp-brainstorm 的精确章节。>

## 设计入口

- `design/00-index.md`
````

`review.md` is a review document, not a decision record or second design owner. Decision Ledger is summarized by count only;不得复制 Decision Ledger rows，不得机械复制设计正文。模型代码只可从已确认设计精确摘录，不得自行补充字段。

The complete file must remain within 500 lines and 30,000 characters. If deduplication and links cannot keep it within both limits, block instead of truncating because `review.md` has no split form.

复选框只用于验证清单和最终评审结论。正文、表格、模型代码和解释各自承担不同职责，不重复同一事实。设计入口只出现一次。

## Document readability self-review

- 第一段直接给出结果，主线先于局部细节。
- 标题最多三级；段落不超过 7 行，并优先控制在 4 行以内。
- 必要术语首次出现时使用直白解释；精确技术标识符保持不变。
- 风险写出具体失败场景、影响和已确认处理，不使用“注意风险”等空泛措辞。
- 复选框只用于验证清单和最终评审结论。
- Decision Ledger 只统计，设计事实只提炼，不新增或改变结论。
- 数据表格、代码和解释不重复表达同一事实。
- `## 设计入口` 恰好出现一次。
`````

- [ ] **Step 5: Update the outer `fp-start` handoff**

Replace the existing design-review sentence in `skills/fp-start/SKILL.md` with wording that:

1. invokes `fp-design-review` after the design write verification;
2. displays the review conclusion, business/technical mainline, primary risks, review order, and entry path;
3. treats a sufficiency failure as a return to `fp-brainstorm` for the listed sections;
4. never lets `fp-start` or `fp-design-review` invent the missing design;
5. waits for the existing post-write design confirmation before entering planning.

Use this exact core sentence:

```markdown
加载 `${CLAUDE_PLUGIN_ROOT}/skills/fp-design-review/SKILL.md` 生成 `fp-docs/changes/<slug>/review.md`，并展示评审结论、业务和技术主线、主要风险、建议评审顺序与入口路径。设计充分性检查失败时，按其缺失清单返回 `fp-brainstorm` 定点修订并重新确认；`fp-start` 和 `fp-design-review` 都不得编造缺失设计。review.md 不复制决策正文，不改变台账状态，仍属于 fp-start 的写入后产物确认步骤。
```

- [ ] **Step 6: Update the public design-review checksum**

Replace the checksum bullets in `commands/fp-design-review.md` with concise bullets covering:

```markdown
- 只从已核验的 canonical design 生成；先做设计充分性检查，缺字段/物理表/约束/证据/migration 时保留现有 review.md，并返回 `fp-brainstorm` 定点修订。
- 只写 change 根 `fp-docs/changes/<slug>/review.md`，仅 small form，覆盖全部实际端；生成独立可读的完整评审文档，不复制台账或设计正文，不编造设计事实。
- 充分性通过后先加载共享文档风格契约，再加载 review 模板；结论和主线先于细节，复选框只用于验证与最终结论。
- 不修改设计文件、Decision Ledger 或任何台账状态；不推进任何阶段。
```

Keep the whole command at or below 20 lines.

- [ ] **Step 7: Extend the shared-style suite for review**

Insert before the final output in `scripts/test-document-style-contract.ps1`:

```powershell
$reviewSkill = Read-Utf8 'skills\fp-design-review\SKILL.md'
$reviewTemplate = Read-Utf8 'skills\fp-design-review\review-template.md'
$reviewLoadContract = '读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md`，再读取 `${CLAUDE_PLUGIN_ROOT}/skills/fp-design-review/review-template.md`'
Assert-Condition ($reviewSkill.Contains($reviewLoadContract)) 'fp-design-review does not load document style before its template'
Assert-Anchors $reviewTemplate @(
    '## Document readability self-review'
    '第一段直接给出结果'
    '标题最多三级'
    '复选框只用于验证清单和最终评审结论'
) 'review template readability review'
```

- [ ] **Step 8: Run focused and decision regressions**

Run:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-design-review-contract.ps1
```

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-document-style-contract.ps1
```

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-decision-gate-contract.ps1
```

Expected: all three exit `0` with their pass messages.

- [ ] **Step 9: Record a no-commit checkpoint**

Run:

```bash
git diff --check
```

Expected: no output and exit `0`. Do not stage or commit.

---

### Task 5: Wire global validation and user-facing documentation

**Files:**
- Modify: `scripts/test-document-style-contract.ps1`
- Modify: `scripts/validate-plugin.ps1:481-576,940-970`
- Modify: `docs/reference/commands-and-skills.md:14-19,93-97`
- Modify only if its current anchors require it: `scripts/test-readme-docs-contract.ps1:49-66`

**Interfaces:**
- Consumes: Both focused suites and all producer/template changes from Tasks 1–4.
- Produces: Global validation entrypoints and user-visible documentation. No README change unless the existing command index becomes inaccurate.

- [ ] **Step 1: Add failing validator/docs assertions to the style suite**

Insert before the final output in `scripts/test-document-style-contract.ps1`:

```powershell
$validator = Read-Utf8 'scripts\validate-plugin.ps1'
$commandsReference = Read-Utf8 'docs\reference\commands-and-skills.md'

Assert-Anchors $validator @(
    "`$documentStyleContractValidator = Join-Path `$root 'scripts\test-document-style-contract.ps1'"
    '& powershell -NoProfile -ExecutionPolicy Bypass -File $documentStyleContractValidator'
    "Assert-Condition (`$LASTEXITCODE -eq 0) 'focused document-style contract validator failed'"
    "`$designReviewContractValidator = Join-Path `$root 'scripts\test-design-review-contract.ps1'"
    '& powershell -NoProfile -ExecutionPolicy Bypass -File $designReviewContractValidator'
    "Assert-Condition (`$LASTEXITCODE -eq 0) 'focused design-review contract validator failed'"
) 'global validator wiring'
Assert-Anchors $commandsReference @(
    'PRD、proposal、design 和 review'
    '共享文档风格契约'
    '独立可读的完整评审文档'
) 'commands and skills reference'

$runtimeSurfaces = @(
    'skills\_shared\document-style.md'
    'skills\fp-prd\SKILL.md'
    'skills\fp-prd\prd-template.md'
    'skills\fp-propose\SKILL.md'
    'skills\fp-propose\proposal-template.md'
    'skills\fp-brainstorm\SKILL.md'
    'skills\fp-brainstorm\design-template.md'
    'skills\fp-design-review\SKILL.md'
    'skills\fp-design-review\review-template.md'
    'commands\fp-prd.md'
    'commands\fp-start.md'
    'commands\fp-design-review.md'
)
foreach ($surface in $runtimeSurfaces) {
    Assert-Condition (-not (Read-Utf8 $surface).Contains('D:\01-code\document-style-guide')) "$surface has a machine-local runtime dependency"
}
```

- [ ] **Step 2: Run the style suite and verify validator wiring fails**

Run:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-document-style-contract.ps1
```

Expected: non-zero exit naming the missing `$documentStyleContractValidator` anchor.

- [ ] **Step 3: Register both focused suites in `validate-plugin.ps1`**

Insert after the decision-gate validator block and before PRD business validation:

```powershell
$documentStyleContractValidator = Join-Path $root 'scripts\test-document-style-contract.ps1'
Assert-Condition (Test-Path $documentStyleContractValidator) 'focused document-style contract validator is missing'
& powershell -NoProfile -ExecutionPolicy Bypass -File $documentStyleContractValidator
Assert-Condition ($LASTEXITCODE -eq 0) 'focused document-style contract validator failed'

$designReviewContractValidator = Join-Path $root 'scripts\test-design-review-contract.ps1'
Assert-Condition (Test-Path $designReviewContractValidator) 'focused design-review contract validator is missing'
& powershell -NoProfile -ExecutionPolicy Bypass -File $designReviewContractValidator
Assert-Condition ($LASTEXITCODE -eq 0) 'focused design-review contract validator failed'
```

Update the existing `fp-design-review` capability-anchor entry near the current `review-template.md` requirements. Its required anchors must include:

```powershell
'fp-design-review' = @(
    'review-template.md'
    'review.md'
    '设计充分性检查'
    '评审结论'
    '业务和技术主线'
    '主要风险'
    '不得复制决策正文'
    'design/00-index.md'
    'manifest order'
    'canonical-first'
    '阻塞'
)
```

Do not duplicate the full focused-test logic in `validate-plugin.ps1`; the global validator owns invocation and broad capability anchors only.

- [ ] **Step 4: Update the command/skill reference**

In `docs/reference/commands-and-skills.md`:

- Change the `fp-design-review` result cell to `独立可读的完整 review.md 评审文档`.
- Replace the design-review bullet under `### Figma 与设计评审` with:

```markdown
- `fp-design-review` 先核对 canonical design 是否足够评审，再生成独立可读的完整 `review.md`；信息不足时返回 `fp-brainstorm` 定点修订，不在评审阶段重新设计；
```

- Add this paragraph after that list:

```markdown
PRD、proposal、design 和 review 统一遵循仓库内共享文档风格契约：先给目的、范围、主线或结论，再展开细节；使用清楚的段落、术语、空格和标点，同时保持代码、路径、API 字段、固定 schema 与 Decision Ledger 精确不变。
```

Do not modify README because its short command index remains accurate.

- [ ] **Step 5: Update docs-test anchors only if needed**

Run the docs contract first. If it passes, leave `scripts/test-readme-docs-contract.ps1` unchanged. If the commands-reference edit changes an asserted anchor, update only that exact anchor while preserving local-link checks and README constraints; do not add duplicated style-contract logic there because `test-document-style-contract.ps1` owns it.

Run:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-readme-docs-contract.ps1
```

Expected: exit `0`. Any failure must name the exact stale anchor before editing the test.

- [ ] **Step 6: Run focused and global validation**

Run:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-document-style-contract.ps1
```

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-design-review-contract.ps1
```

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
```

Expected: all exit `0`; global validation ends with `FeaturePilot plugin validation passed:`.

- [ ] **Step 7: Record a no-commit checkpoint**

Run:

```bash
git status --short
```

Expected: implementation and documentation changes remain uncommitted. Do not stage, push, or sync runtimes.

---

### Task 6: Run the complete verification matrix and inspect final scope

**Files:**
- Verify only: all files listed in the File and Responsibility Map
- Modify only when a command exposes a concrete defect; rerun the failing focused test immediately after any repair

**Interfaces:**
- Consumes: Completed Tasks 1–5.
- Produces: Fresh command evidence for every success criterion and a clean, uncommitted working-tree handoff.

- [ ] **Step 1: Run the shared style contract suite**

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-document-style-contract.ps1
```

Expected: exit `0`, `Document-style contract validation passed.`

- [ ] **Step 2: Run the design-review suite**

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-design-review-contract.ps1
```

Expected: exit `0`, `Design-review contract validation passed.`

- [ ] **Step 3: Run the shared decision-gate suite**

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-decision-gate-contract.ps1
```

Expected: exit `0`, `Decision-gate contract validation passed.`

- [ ] **Step 4: Run both PRD regression suites**

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-prd-business-contract.ps1
```

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-prd-product-first-contract.ps1
```

Expected: both exit `0` with their pass messages.

- [ ] **Step 5: Run the docs contract suite**

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-readme-docs-contract.ps1
```

Expected: exit `0`, `README/docs contract validation passed.`

- [ ] **Step 6: Run full plugin validation**

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
```

Expected: exit `0`, ending with `FeaturePilot plugin validation passed:`. Preserve and report the exact output of any nested failure.

- [ ] **Step 7: Measure context budgets**

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/measure-context.ps1
```

Expected: exit `0`; `fp-explore` and `ExplorePublic` remain below their guards. The style contract remains JIT content, like output templates, and therefore does not need to be added to the static always-loaded proxy.

- [ ] **Step 8: Check whitespace and machine-local dependency leakage**

```bash
git diff --check
```

Expected: no output and exit `0`.

Run:

```bash
rg -n -F 'D:\01-code\document-style-guide' skills commands scripts docs/reference
```

Expected: no output and exit `1` from `rg` because no runtime or public-reference file contains the machine-local path. The approved spec may retain that path as historical design context and is intentionally outside this search set.

- [ ] **Step 9: Inspect final scope without committing**

```bash
git status --short
```

Expected: only the approved spec, this plan, and the files listed in the File and Responsibility Map are changed or untracked. Report any unrelated pre-existing file separately; do not modify, stage, or discard it.

- [ ] **Step 10: Present the final diff for human review**

Review the complete uncommitted diff against the approved specification. Confirm explicitly that:

1. all four artifact types load one shared contract just in time;
2. PRD's six-section schema and product-language gate remain intact;
3. proposal/design Decision Ledger schemas remain intact;
4. model investigation happens in `fp-brainstorm`, not `fp-design-review`;
5. insufficiency preserves existing `review.md` and returns precise missing sections;
6. `review.md` has one design entry, no duplicated ledger rows, and checkboxes only in validation/conclusion;
7. no Git commit, push, PR, or runtime sync occurred.
