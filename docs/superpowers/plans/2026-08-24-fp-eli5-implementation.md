# FeaturePilot `fp-eli5` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增显式按需的 `fp-eli5` 零基础专业图解能力，在仓库主题下单向复用未修改的 `fp-explore` public standalone，并安全接入五个 FeaturePilot checkpoint。

**Architecture:** `skills/fp-eli5/SKILL.md` 是解释与能力降级的唯一权威，`commands/fp-eli5.md` 只是 Claude Code 薄入口。仓库事实由 `fp-eli5` 调用现有 `fp-explore` standalone 获得；五个 caller 通过延迟加载的 shared handoff 暂停并恢复同一 gate。PowerShell 5.1 聚焦测试保护显式触发、单向依赖、输出降级、零持久化、门禁恢复和三运行时静态分发。

**Tech Stack:** Markdown skill/command contracts；PowerShell 5.1 + .NET regex/UTF-8 APIs；宿主可选 HTML artifact；内联 HTML/CSS/SVG；Markdown + Mermaid/纯文本 fallback。无新依赖、服务、CLI 或持久化运行时。

## Global Constraints

- 权威规格是 `docs/superpowers/specs/2026-08-24-fp-eli5-design.md`；计划与规格冲突时停止并回到规格。
- `skills/fp-explore/SKILL.md` 与 `commands/fp-explore.md` 必须保持不变；禁止新增 `eli5-facts` profile、caller 或反向 handoff。
- `fp-eli5` 只能单向调用现有 `fp-explore` public standalone，不能伪装内部 profile 或要求新 return shape。
- 只在显式 `/fp-eli5`、`$fp-eli5`、明确图解请求，或用户接受一次 JIT 图解建议后运行；普通问题和阶段切换不自动触发。
- 双模式固定为 `generic`、`repository-grounded`，需要当前外部事实时归入 `external-current` 并沿用现有研究授权边界。
- 输出顺序固定为 HTML artifact → Markdown + Mermaid → 纯文本；没有明确 artifact 能力时不得创建 HTML 文件或启动服务器。
- 默认运行不得写仓库、创建 `fp-docs` artifact、复用 `prototype.html` 或改变 git 状态。
- 默认语气是“零基础专业”，类比必须标记为非系统事实。
- `FAIL`、`BLOCKED`、`CANNOT_VERIFY`、风险、未知和证据不得在降级中丢失或弱化。
- 五个 JIT caller 仅为 `fp-init`、`fp-prd-grill-me`、`fp-brainstorm`、`fp-plan`、`fp-start`；返回后恢复完全相同的 gate。
- 图解不得更新 Decision Ledger、task checkbox、coverage state、review verdict，不产生 write authorization，不把 recommendation 当答案。
- 新 skill frontmatter 只有 `name` 与 `description`；`SKILL.md` 不超过 500 行。
- 新 command 不超过 20 行，只做代理和 gate checksum。
- 所有新增 Markdown 文件不超过 500 行和 30,000 字符；过程说明默认中文，精确技术标识保留英文。
- HTML/Markdown 模板无 CDN、远程字体、远程图片、外部脚本或原始不可信 HTML 插值。
- PowerShell 测试兼容 Windows PowerShell 5.1，fixture 只在内存或临时目录中，不在仓库创建运行时产物。
- 当前未提交的已确认设计文档必须保留。除非用户明确授权 commit，否则下面所有 commit 步骤均跳过并记录原因。
- 下面 schema 中的尖括号是要写入合同的 metavariable，不是未完成内容。

---

## File Structure Map

### New files

- `commands/fp-eli5.md` — Claude Code 显式入口和简短 gate checksum。
- `skills/fp-eli5/SKILL.md` — 双模式、单向调查、真实性、安全、输出和返回合同。
- `skills/fp-eli5/output-template.md` — 延迟加载的 HTML/Markdown/文本视觉故事结构。
- `skills/_shared/eli5-handoff.md` — 五个 caller 共用的结构化 JIT 调用和恢复规则。
- `scripts/test-eli5-contract.ps1` — 聚焦静态合同和负面边界测试。

### Modified files

- `skills/fp-init/SKILL.md` — init 决策的按需解释与同 gate 恢复。
- `skills/fp-prd-grill-me/SKILL.md` — 当前 A/B item 或唯一 Bucket C 问题的按需解释。
- `skills/fp-brainstorm/SKILL.md` — 当前 `D-NNN`/方案/章节的按需解释。
- `skills/fp-plan/SKILL.md` — 计划确认前的 task/dependency 图解。
- `skills/fp-start/SKILL.md` — 全阶段统一的显式 JIT checkpoint 规则。
- `README.md` — command、skill、用法和三运行时 fallback。
- `AGENTS.md` — intent routing 和非权威边界。
- `scripts/validate-plugin.ps1` — 注册聚焦 `fp-eli5` validator。

### Verify unchanged

- `skills/fp-explore/SKILL.md`
- `commands/fp-explore.md`
- `.claude-plugin/plugin.json`
- `.codex-plugin/plugin.json`
- `.agents/skills/sync-plugin-runtimes/scripts/sync-plugin-runtimes.ps1`

---

## Task 1: Build the Core `fp-eli5` Contract and RED/GREEN Validator

**Files:**
- Create: `scripts/test-eli5-contract.ps1`
- Create: `commands/fp-eli5.md`
- Create: `skills/fp-eli5/SKILL.md`
- Create: `skills/fp-eli5/output-template.md`
- Create: `skills/_shared/eli5-handoff.md`
- Verify unchanged: `skills/fp-explore/SKILL.md`, `commands/fp-explore.md`

**Interfaces:**
- Consumes: natural-language public input or one `fp-eli5-handoff` comment block.
- Produces: `USAGE_ONLY`, `NEEDS_SCOPE`, `CANNOT_EXPLAIN_WITH_EVIDENCE`, `EXTERNAL_RESEARCH_NOT_AUTHORIZED`, `RENDERED_HTML_ARTIFACT`, `RENDERED_MARKDOWN_FALLBACK`, or `RENDERED_TEXT_FALLBACK`.
- JIT fields: `caller`, `topic`, `active-slug`, `pending-gate`, `allowed-sources`, `return-to`.

- [ ] **Step 1: Capture the protected baseline**

Run:

```bash
git status --short
git diff --exit-code -- skills/fp-explore/SKILL.md commands/fp-explore.md
```

Expected: status includes the approved untracked design document; the second command exits `0` with no output. Preserve every pre-existing change.

- [ ] **Step 2: Write the first failing focused validator**

Create `scripts/test-eli5-contract.ps1` with this PowerShell 5.1 foundation and core assertions:

```powershell
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) { throw "ELI5 contract validation failed: $message" }
}
function Read-Utf8([string]$path) {
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

$paths = [ordered]@{
    Skill = 'skills\fp-eli5\SKILL.md'
    Command = 'commands\fp-eli5.md'
    Template = 'skills\fp-eli5\output-template.md'
    Handoff = 'skills\_shared\eli5-handoff.md'
}
foreach ($entry in $paths.GetEnumerator()) {
    Assert-Condition (Test-Path (Join-Path $root $entry.Value)) "$($entry.Value) is missing"
}

$skill = Read-Utf8 (Join-Path $root $paths.Skill)
$command = Read-Utf8 (Join-Path $root $paths.Command)
$template = Read-Utf8 (Join-Path $root $paths.Template)
$handoff = Read-Utf8 (Join-Path $root $paths.Handoff)
$exploreSkill = Read-Utf8 (Join-Path $root 'skills\fp-explore\SKILL.md')
$exploreCommand = Read-Utf8 (Join-Path $root 'commands\fp-explore.md')

$frontmatter = [regex]::Match($skill, '(?s)\A---\r?\n(?<body>.*?)\r?\n---')
Assert-Condition $frontmatter.Success 'fp-eli5 frontmatter is invalid'
$keys = @([regex]::Matches($frontmatter.Groups['body'].Value, '(?m)^([a-zA-Z0-9_-]+):') | ForEach-Object { $_.Groups[1].Value })
Assert-Condition ($keys.Count -eq 2 -and $keys -contains 'name' -and $keys -contains 'description') 'frontmatter must contain only name and description'
Assert-Condition ($skill -match '(?m)^name:\s*fp-eli5\s*$') 'skill name must match its directory'
Assert-Condition ((@($skill -split "`r?`n").Count) -le 500) 'SKILL.md exceeds 500 lines'
Assert-Condition ((@($command -split "`r?`n").Count) -le 20) 'command exceeds 20 lines'

foreach ($anchor in @('generic', 'repository-grounded', 'external-current', 'fp:fp-explore', 'public standalone', 'CANNOT_EXPLAIN_WITH_EVIDENCE', 'RENDERED_HTML_ARTIFACT', 'RENDERED_MARKDOWN_FALLBACK', 'RENDERED_TEXT_FALLBACK', '默认不写仓库')) {
    Assert-Condition ($skill.Contains($anchor)) "fp-eli5 is missing $anchor"
}
Assert-Condition (-not $skill.Contains('eli5-facts')) 'fp-eli5 must not invent an fp-explore profile'
Assert-Condition (-not $exploreSkill.Contains('fp-eli5')) 'fp-explore skill must remain unaware of fp-eli5'
Assert-Condition (-not $exploreCommand.Contains('fp-eli5')) 'fp-explore command must remain unaware of fp-eli5'
foreach ($anchor in @('事实', '推断', '风险', '未知', '类比', '一句话结论', '哪里会出错', '只需记住什么', '真实依据', 'Markdown + Mermaid', '纯文本')) {
    Assert-Condition ($template.Contains($anchor)) "output template is missing $anchor"
}
Assert-Condition ($template -notmatch '(?i)<script\s+src|<link\s+[^>]*href|@import|url\s*\(\s*["'']?https?://') 'output template permits an external resource'
foreach ($field in @('caller:', 'topic:', 'active-slug:', 'pending-gate:', 'allowed-sources:', 'return-to:')) {
    Assert-Condition ($handoff.Contains($field)) "handoff is missing $field"
}
Write-Output 'FeaturePilot fp-eli5 contract validation passed.'
```

- [ ] **Step 3: Run RED and verify the intended failure**

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-eli5-contract.ps1
```

Expected: FAIL with `skills\fp-eli5\SKILL.md is missing`; a syntax error is the wrong failure.

- [ ] **Step 4: Create the thin command**

Create `commands/fp-eli5.md` exactly as a thin adapter:

```markdown
---
description: 对普通概念或当前项目事实生成零基础专业图解
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-eli5/SKILL.md`，将自然语言输入「$ARGUMENTS」作为 public input。

Gate checksum：

- 仅在显式 `/fp-eli5`、`$fp-eli5` 或明确图解请求下运行，不自动触发。
- 仓库主题由 `fp-eli5` 单向调用现有 `fp-explore` public standalone；不得修改 `fp-explore`。
- 优先临时 HTML artifact；不可用时降级为 Markdown + Mermaid 或纯文本，默认不写仓库。
```

- [ ] **Step 5: Create the authoritative skill, output template, and handoff contract**

Use this exact discovery description in `skills/fp-eli5/SKILL.md`:

```yaml
name: fp-eli5
description: Use only when a user explicitly invokes /fp-eli5 or $fp-eli5, explicitly asks for a zero-background visual explanation, or accepts a FeaturePilot just-in-time explanation offer.
```

After the normal anchored-resource failure clause and Claude/Codex/DeepSeek path mapping, load `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md`. Implement these exact top-level sections: `Authority and non-authority`, `Public input`, `Topic classification`, `One-way fp-explore reuse`, `JIT handoff`, `Evidence classification`, `Visual story`, `Capability-adaptive output`, `Failure states`, `Safety`, `Return and resume`.

The `One-way fp-explore reuse` section must resolve `fp:fp-explore` through the native `Skill` tool first, then installed available-skill metadata, never consumer-repository `skills/**`; it passes a bounded natural-language standalone question and consumes only explicit facts/classifications/citations. It must fail with `CANNOT_EXPLAIN_WITH_EVIDENCE` rather than scanning independently.

Create `skills/fp-eli5/output-template.md` with the seven approved story regions, five textual evidence labels, inline-only HTML rules, accessible evidence disclosure, and information-equivalent Markdown/Mermaid/text fallbacks. `fp-eli5` must read this template only after it has enough facts to explain the topic and has selected the available rendering path. Create `skills/_shared/eli5-handoff.md` with the six fields above, the exact allowed caller set, malformed-block fail-closed behavior, and the common invariant that explanation never confirms, writes, checks a task, changes a verdict/state, or advances a gate. Load the shared handoff only when a structured JIT block is present; public natural-language input must not pay that context cost.

- [ ] **Step 6: Run GREEN and verify core invariants**

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-eli5-contract.ps1
git diff --exit-code -- skills/fp-explore/SKILL.md commands/fp-explore.md
```

Expected: focused validator prints `FeaturePilot fp-eli5 contract validation passed.`; unchanged check exits `0`.

- [ ] **Step 7: Commit only if explicitly authorized**

```bash
git add commands/fp-eli5.md skills/fp-eli5/SKILL.md skills/fp-eli5/output-template.md skills/_shared/eli5-handoff.md scripts/test-eli5-contract.ps1
git commit -m "feat: add fp-eli5 core skill"
```

Otherwise skip both commands and record `commit skipped: no explicit authorization`.

---

## Task 2: Add Five JIT Caller Handoffs Without Advancing Gates

**Files:**
- Modify: `scripts/test-eli5-contract.ps1`
- Modify: `skills/fp-init/SKILL.md:57-59`
- Modify: `skills/fp-prd-grill-me/SKILL.md:54-58`
- Modify: `skills/fp-brainstorm/SKILL.md:32-38`
- Modify: `skills/fp-plan/SKILL.md:87-90`
- Modify: `skills/fp-start/SKILL.md:36-45`

**Interfaces:**
- Consumes: one explicit explanation request plus the six-field `fp-eli5-handoff` block.
- Produces: one explanation followed by the caller re-presenting the identical `pending-gate`.

- [ ] **Step 1: Extend the focused validator for caller RED**

Add a table of the five paths, exact `caller:` value, shared anchor `` `${CLAUDE_PLUGIN_ROOT}/skills/_shared/eli5-handoff.md` ``, and caller-specific resume anchor. Assert all are present and assert `fp-execute`, `fp-execute-sdd`, `fp-archive`, `fp-quick`, both end planners, `fp-figma`, `fp-ui-spec`, and `fp-ux-spec` do not load `eli5-handoff.md`.

Run the focused validator. Expected: FAIL first on `fp-init` missing the handoff anchor.

- [ ] **Step 2: Insert the caller-specific JIT blocks**

Use the shared six fields and these exact values:

| File | caller | topic | active-slug | pending-gate | return-to |
|---|---|---|---|---|---|
| `fp-init` | `fp-init` | current init choice | `N/A` | exact install/MCP/build/refresh/manifest/settings/discovery/write-scope prompt | `fp-init:same-gate` |
| `fp-prd-grill-me` | `fp-prd-grill-me` | current A/B review item or sole C question | current PRD slug or `N/A` | Phase 1 batch confirmation or current C N/Total | same review item/question |
| `fp-brainstorm` | `fp-brainstorm` | current D-NNN/option/tradeoff/section | exact current slug | exact D-NNN or section/pre-write gate | same D-NNN/checkpoint |
| `fp-plan` | `fp-plan` | current plan/task ownership/dependencies | exact current slug | explicit plan confirmation | `fp-plan:plan-confirmation` |
| `fp-start` | `fp-start` | current routing/stage artifact/checkpoint | resolved slug or `N/A` | exact quick/full, proposal, design, plan, or SDD-mode gate | `fp-start:same-stage-gate` |

Each block must say “仅当用户显式要求” and JIT-load the shared contract plus `fp:fp-eli5`. Preserve these caller-specific prohibitions:

- `fp-init`: every install, MCP, graph, refresh, manifest, settings, discovery, and write-scope approval remains separate.
- `fp-prd-grill-me`: do not reclassify/answer Bucket C, bundle the next question, or treat interview completion as write approval.
- `fp-brainstorm`: do not alter `D-NNN`, recommendation status, section review, form/path decision, or separate write authorization.
- `fp-plan`: do not rewrite a plan, update checkbox, confirm the plan, or choose/start execution.
- `fp-start`: do not infer quick/full, artifact confirmation, resume completion, SDD mode, or load the next stage.

Finish every block with the shared invariant and require the caller to re-present exactly the same `pending-gate`.

- [ ] **Step 3: Run focused and adjacent GREEN suites**

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-eli5-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-init-information-layer-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-decision-gate-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-explore-contract.ps1
```

Expected: all exit `0`; ELI5 and explore suites print their contract-validation success lines. Any existing gate-suite failure must be fixed without weakening the original gate.

- [ ] **Step 4: Commit only if explicitly authorized**

```bash
git add scripts/test-eli5-contract.ps1 skills/fp-init/SKILL.md skills/fp-prd-grill-me/SKILL.md skills/fp-brainstorm/SKILL.md skills/fp-plan/SKILL.md skills/fp-start/SKILL.md
git commit -m "feat: add fp-eli5 stage handoffs"
```

Otherwise skip and record the lack of authorization.

---

## Task 3: Publish Intent Routing and Verify Three-Runtime Distribution

**Files:**
- Modify: `scripts/test-eli5-contract.ps1`
- Modify: `README.md:37-65,140-146,262-269`
- Modify: `AGENTS.md:12-25,39-40,126-131`
- Test unchanged: `.codex-plugin/plugin.json`, `.agents/skills/sync-plugin-runtimes/scripts/sync-plugin-runtimes.ps1`

**Interfaces:**
- Produces: one explicit public intent route shared by Claude Code, Codex, and DeepSeek Harness; no per-skill manifest registry.

- [ ] **Step 1: Add public-surface assertions and run RED**

Extend the focused validator to require:

- README command row for `commands/fp-eli5.md`, core-skill bullet, low-cost flow step, invocation example, HTML/Markdown/text fallback, and default no-write statement.
- AGENTS intent row mapping explicit `/fp-eli5`, `$fp-eli5`, or explicit zero-background visual explanation to `skills/fp-eli5/SKILL.md`; a release-behavior bullet preserving non-authority; and a low-cost-flow entry.
- `.codex-plugin/plugin.json` still exposes `./skills/`.
- Public docs do not copy the internal six-field handoff schema.

Run the focused validator. Expected: FAIL on the missing README command row.

- [ ] **Step 2: Update README and AGENTS at the exact public surfaces**

In README, insert `fp-eli5` immediately after `fp-explore` in the core command table and core skill list; insert optional explanation after optional exploration in the low-cost flow; add `/fp-eli5 当前权限校验调用链` after the installation `/fp-explore` example. State that HTML artifact is capability-dependent and fallback is Markdown + Mermaid then text, with no repository write by default.

In AGENTS, insert this intent row immediately after read-only exploration:

```markdown
| Explicit `/fp-eli5`, `$fp-eli5`, or explicit request for a zero-background visual explanation | `skills/fp-eli5/SKILL.md` |
```

Add one release-behavior bullet and one low-cost-flow item. Keep internal handoff fields out of public docs.

Do not modify either plugin manifest or the sync implementation: Codex already points to `./skills/`; DeepSeek sync recursively hashes and copies every top-level `skills/` entry, including `fp-eli5/` and `_shared/eli5-handoff.md`.

- [ ] **Step 3: Run docs/distribution GREEN checks**

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-eli5-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-project-sync-skill.ps1
git diff --exit-code -- .claude-plugin/plugin.json .codex-plugin/plugin.json .agents/skills/sync-plugin-runtimes/scripts/sync-plugin-runtimes.ps1
```

Expected: both tests exit `0`; unchanged check exits `0`. Report static distribution verification only; do not claim unrun artifact rendering in any runtime.

- [ ] **Step 4: Commit only if explicitly authorized**

```bash
git add README.md AGENTS.md scripts/test-eli5-contract.ps1
git commit -m "docs: publish fp-eli5 usage"
```

Otherwise skip and record the reason.

---

## Task 4: Register Aggregate Validation and Prove Final Invariants

**Files:**
- Modify: `scripts/test-eli5-contract.ps1`
- Modify: `scripts/validate-plugin.ps1:514-522`
- Verify: every intended file above and the approved design document

**Interfaces:**
- Consumes: focused `test-eli5-contract.ps1` exit code.
- Produces: aggregate plugin validation that fails whenever the ELI5 contract regresses.

- [ ] **Step 1: Add aggregate-registration assertion and run RED**

Make the focused validator read `scripts/validate-plugin.ps1` and require `scripts\test-eli5-contract.ps1`, `focused fp-eli5 contract validator is missing`, and `focused fp-eli5 contract validator failed`.

Run the focused validator. Expected: FAIL because aggregate registration is absent.

- [ ] **Step 2: Register the focused validator**

Insert immediately after the existing `fp-explore` validator block:

```powershell
$eli5ContractValidator = Join-Path $root 'scripts\test-eli5-contract.ps1'
Assert-Condition (Test-Path $eli5ContractValidator) 'focused fp-eli5 contract validator is missing'
& powershell -NoProfile -ExecutionPolicy Bypass -File $eli5ContractValidator
Assert-Condition ($LASTEXITCODE -eq 0) 'focused fp-eli5 contract validator failed'
```

Do not reorder or weaken any existing validator.

- [ ] **Step 3: Run final focused and aggregate verification**

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-eli5-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
git diff --check
git diff --exit-code -- skills/fp-explore/SKILL.md commands/fp-explore.md .claude-plugin/plugin.json .codex-plugin/plugin.json .agents/skills/sync-plugin-runtimes/scripts/sync-plugin-runtimes.ps1
git status --short
```

Expected:

- focused validator prints `FeaturePilot fp-eli5 contract validation passed.`;
- aggregate validator and all nested suites exit `0`;
- `git diff --check` is silent;
- protected unchanged check exits `0`;
- status lists only the approved design/plan and intended implementation/test/doc files, with no generated HTML, `fp-docs/explainers/`, server output, cache, dependency, lockfile, or configuration changes.

- [ ] **Step 4: Perform the plan/spec self-review**

Map every design acceptance criterion to a passing focused assertion or final command. Confirm the same six handoff fields are used in the shared contract and all callers; confirm all three output statuses/fallbacks and all five evidence labels are spelled consistently. Fix any gap before reporting completion.

- [ ] **Step 5: Commit only if explicitly authorized**

```bash
git add scripts/validate-plugin.ps1 scripts/test-eli5-contract.ps1
git commit -m "test: register fp-eli5 contract validation"
```

Otherwise skip. Never include unrelated user changes in a commit.
