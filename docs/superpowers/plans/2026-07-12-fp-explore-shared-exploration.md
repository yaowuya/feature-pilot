# FeaturePilot `fp-explore` Shared Exploration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a public, strictly read-only `/fp-explore` skill with natural-language standalone exploration and three structured internal profiles, then integrate those profiles into `fp-prd`, `fp-start`, and `fp-quick` without weakening caller-owned product, approval, artifact, or execution gates.

**Architecture:** `skills/fp-explore/SKILL.md` is the sole detailed exploration authority and `commands/fp-explore.md` is a thin adapter. Internal callers exchange deterministic Markdown invocation/return blocks; a focused PowerShell 5.1 suite validates those contracts, caller ownership, negative mutations, documentation, and context budgets without adding runtime parsing or persisted explore state.

**Tech Stack:** Markdown Claude Code/Codex skill contracts; PowerShell 5.1 static validation using .NET regex and UTF-8 APIs; local read-only Git inspection. No runtime dependency, external package, state machine, dispatcher, service, or explore artifact.

## Global Constraints

- The approved source of truth is `docs/superpowers/specs/2026-07-12-fp-explore-shared-exploration-design.md`; stop and resolve any plan/spec discrepancy before implementation.
- Preserve all pre-existing uncommitted work. At plan creation time, protected tracked edits existed in `commands/fp-start.md`, `scripts/validate-plugin.ps1`, `skills/fp-execute-sdd/SKILL.md`, `skills/fp-prd/SKILL.md`, and `skills/fp-start/SKILL.md`; protected untracked execution-mode design/plan files also existed.
- Never use `git checkout`, `git restore`, `git reset`, broad file replacement from `HEAD`, or cleanup commands against protected files.
- `skills/fp-explore/SKILL.md` is the sole detailed policy authority, contains only `name` and `description` frontmatter keys, and remains at or below 500 physical lines.
- `commands/fp-explore.md` remains at or below 20 physical lines and contains only delegation, Markdown-agent fallback, and a non-authoritative gate checksum.
- Public `/fp-explore` accepts natural-language input. Internal use requires exactly one structured `fp-explore-invoke` block and returns one deterministic `fp-explore-return` block.
- Implement and integrate exactly three internal profiles: `prd-facts` for `fp-prd`, `start-routing` for `fp-start`, and `quick` for `fp-quick`.
- Every mode and profile is read-only by semantic prompt contract. Do not claim operating-system sandbox enforcement.
- `fp-prd-grill-me` remains the sole PRD interview/confirmation authority and must continue to prevent the assistant from answering Bucket C decisions.
- `fp-start` retains quick/full choice, every lifecycle stage gate, and the already-uncommitted direct-versus-SDD and SDD-continuation gates.
- `fp-quick` retains final suitability, user clarification, inline plan approval, implementation, validation, and no-FeaturePilot-artifact ownership.
- `fp-propose` remains independently usable; it consumes only fresh, scope-matching verified facts from `start-reusable-context` and performs gap-only follow-up exploration.
- External research always requires an exact, bounded, one-question approval envelope. Approval never expands silently.
- The focused validator must be PowerShell 5.1-compatible and keep synthetic fixtures in memory; it must not create fixture files in the repository.
- Plugin manifests change only if live schema evidence requires per-skill registration; current manifests discover commands/skills from the filesystem and expose `./skills/` to Codex.
- Do not commit during execution unless the user explicitly authorizes commits. Every commit step below is conditional and must be skipped otherwise.
- Angle-bracket expressions inside invocation/return examples are literal schema metavariables required by the approved contract, not unfinished implementation placeholders.

---

## File Structure Map

### New files

- `skills/fp-explore/SKILL.md` — authoritative standalone/internal exploration contract.
- `commands/fp-explore.md` — public `/fp-explore` adapter only.
- `scripts/test-explore-contract.ps1` — focused PowerShell 5.1 static contract, fixture, mutation, caller, docs, and context validation.

### Modified files

- `skills/fp-prd/SKILL.md` — invoke `prd-facts` only for relevant non-empty existing-product requests and pass facts to `fp-prd-grill-me`.
- `commands/fp-prd.md` — add a compact exploration checksum while preserving PRD interview gates.
- `skills/fp-start/SKILL.md` — replace three overlapping pre-stage scans with one `start-routing` pass while preserving lifecycle and execution gates.
- `commands/fp-start.md` — add the routing checksum without removing current execution-mode checks.
- `skills/fp-propose/SKILL.md` — consume fresh verified `start-reusable-context` and inspect only gaps.
- `skills/fp-quick/SKILL.md` — replace its dependency on full `fp-propose` exploration with the `quick` profile.
- `commands/fp-quick.md` — point the quick gate checksum at `fp-explore`.
- `scripts/validate-plugin.ps1` — discover/validate `fp-explore`, update quick anchors, and execute the focused suite while preserving current uncommitted execution-gate assertions.
- `scripts/measure-context.ps1` — measure public explore and caller scenarios and enforce a fixed explore size guard.
- `README.md` — document public command, shared skill, and caller integration at user level.
- `AGENTS.md` — add intent routing and Codex/Markdown fallback.
- `docs/user_guide/init-prd-start.md` — explain standalone exploration and internal reuse.

### Files that must remain otherwise untouched

- `skills/fp-execute-sdd/SKILL.md` — its current uncommitted continuation-mode work is protected and not part of `fp-explore`.
- `docs/superpowers/plans/2026-07-12-explicit-execution-mode-gates.md`
- `docs/superpowers/specs/2026-07-12-execution-mode-selection-design.md`

---

## Task 1: Build the Authoritative `fp-explore` Contract and Focused Validator

**Files:**
- Create: `scripts/test-explore-contract.ps1`
- Create: `skills/fp-explore/SKILL.md`
- Create: `commands/fp-explore.md`
- Read: `docs/superpowers/specs/2026-07-12-fp-explore-shared-exploration-design.md`
- Verify unchanged: `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`

**Interfaces:**
- Consumes: public natural-language `$ARGUMENTS`, or one internal `fp-explore-invoke` Markdown comment.
- Produces: conversational standalone output, or one deterministic `fp-explore-return` Markdown comment.
- Exposes exact caller/profile pairs: `fp-prd`/`prd-facts`, `fp-start`/`start-routing`, `fp-quick`/`quick`.

- [ ] **Step 1: Capture and inspect the protected working baseline**

Run from the repository root in PowerShell:

```powershell
$root = (Resolve-Path '.').Path
$protectedPatch = Join-Path $env:TEMP 'feature-pilot-before-fp-explore.patch'
git status --porcelain=v1 -uall
git diff --binary -- commands/fp-start.md scripts/validate-plugin.ps1 skills/fp-execute-sdd/SKILL.md skills/fp-prd/SKILL.md skills/fp-start/SKILL.md | Set-Content -Encoding UTF8 $protectedPatch
Get-Content $protectedPatch
Get-FileHash docs/superpowers/plans/2026-07-12-explicit-execution-mode-gates.md, docs/superpowers/specs/2026-07-12-execution-mode-selection-design.md
```

Expected: the patch records the existing execution-mode, PRD-output, and validator edits; both protected untracked files produce hashes. Do not modify or apply the patch. It is recovery evidence only.

- [ ] **Step 2: Write the first failing focused validator**

Create `scripts/test-explore-contract.ps1` with these exact PowerShell 5.1-compatible foundations:

```powershell
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) { throw "Explore contract validation failed: $message" }
}

function Read-Utf8([string]$path) {
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Get-CommentBlock([string]$text, [string]$name) {
    $pattern = '(?s)<!--\s*' + [regex]::Escape($name) + '\s*(?<body>.*?)\s*-->'
    $matches = [regex]::Matches($text, $pattern)
    Assert-Condition ($matches.Count -eq 1) "expected exactly one $name block, found $($matches.Count)"
    return $matches[0].Groups['body'].Value
}

function Assert-FieldsInOrder([string]$body, [string[]]$fields, [string]$label) {
    $last = -1
    foreach ($field in $fields) {
        $index = $body.IndexOf("$field`:", [System.StringComparison]::Ordinal)
        Assert-Condition ($index -ge 0) "$label is missing field $field"
        Assert-Condition ($index -gt $last) "$label field $field is out of order"
        $last = $index
    }
}

function Test-UnsafeExploreText([string]$text) {
    $patterns = @(
        '(?i)explor(?:e|ation)[^\r\n]{0,100}(?:may|can|should)\s+(?:implement|edit|write|create|save)'
        '(?i)(?:caller|context)[^\r\n]{0,100}(?:waive|override|disable)[^\r\n]{0,80}read-only'
        '(?i)external[^\r\n]{0,100}(?:without|no)\s+(?:approval|consent)'
        '(?i)findings?[^\r\n]{0,100}(?:count as|are)\s+(?:user\s+)?(?:approval|confirmation)'
        '(?:探索|调查)[^\r\n]{0,80}(?:可以|可|应当)(?:实现|修改|写入|创建|保存)'
        '(?:外部研究|联网)[^\r\n]{0,80}(?:无需|不需要)(?:授权|批准|同意)'
    )
    foreach ($pattern in $patterns) {
        if ($text -match $pattern) { return $true }
    }
    return $false
}

$skillPath = Join-Path $root 'skills\fp-explore\SKILL.md'
$commandPath = Join-Path $root 'commands\fp-explore.md'
Assert-Condition (Test-Path $skillPath) 'skills/fp-explore/SKILL.md is missing'
Assert-Condition (Test-Path $commandPath) 'commands/fp-explore.md is missing'
```

This first slice intentionally fails on the missing files.

- [ ] **Step 3: Run RED and verify the failure reason**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-explore-contract.ps1
```

Expected: FAIL with `skills/fp-explore/SKILL.md is missing`. A PowerShell syntax error is the wrong failure.

- [ ] **Step 4: Extend the validator with the exact invocation and return contracts**

Append these arrays and assertions after loading `$skillText` and `$commandText`:

```powershell
$skillText = Read-Utf8 $skillPath
$commandText = Read-Utf8 $commandPath

$invokeFields = @(
    'profile', 'objective', 'caller', 'active-slug', 'caller-owned-context',
    'scope-include', 'scope-exclude', 'budget-profile', 'return-shape',
    'external-research', 'approved-research-boundary'
)
$returnFields = @(
    'profile', 'status', 'objective', 'inspected-scope', 'budget-status',
    'verified-facts', 'inferences', 'risks', 'blocking-questions',
    'external-research', 'external-research-gap', 'next-caller-action',
    'profile-fields'
)
$profileFields = @(
    'prd-existing-behavior', 'prd-technical-constraints', 'prd-product-decisions',
    'start-active-stage', 'start-route-assessment', 'start-reusable-context',
    'quick-candidate-files', 'quick-reusable-patterns', 'quick-verification',
    'quick-scope-assessment'
)

$invokeBody = Get-CommentBlock $skillText 'fp-explore-invoke'
$returnBody = Get-CommentBlock $skillText 'fp-explore-return'
Assert-FieldsInOrder $invokeBody $invokeFields 'invoke contract'
Assert-FieldsInOrder $returnBody $returnFields 'return contract'
Assert-FieldsInOrder $returnBody $profileFields 'return profile fields'

foreach ($pair in @('fp-prd` + `prd-facts', 'fp-start` + `start-routing', 'fp-quick` + `quick')) {
    Assert-Condition ($skillText.Contains($pair)) "missing caller/profile pair $pair"
}
foreach ($anchor in @(
    'mode: standalone', 'tiny', 'small', 'standard', 'max',
    'not-authorized', 'approved-research-boundary', 'fail closed',
    'read-only', 'sensitive', 'one substantive question per turn',
    'never invoke', 'not a technical sandbox'
)) {
    Assert-Condition ($skillText.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "skill is missing $anchor"
}

$commandLines = @($commandText -split "`r?`n").Count
Assert-Condition ($commandLines -le 20) "fp-explore command exceeds 20 lines: $commandLines"
Assert-Condition ($commandText.Contains('fp:fp-explore')) 'command does not delegate to fp:fp-explore'
Assert-Condition ($commandText.Contains('skills/fp-explore/SKILL.md')) 'command lacks Markdown-agent fallback'
Assert-Condition ($commandText.Contains('Gate checksum')) 'command lacks gate checksum'
foreach ($forbidden in @('budget-profile: tiny', 'quick-candidate-files:', 'approved-research-boundary:', 'External research request:')) {
    Assert-Condition (-not $commandText.Contains($forbidden)) "command copied authoritative policy: $forbidden"
}
```

- [ ] **Step 5: Write the authoritative skill**

Create `skills/fp-explore/SKILL.md`. Use this exact section order so the validator and future readers have one stable authority:

```markdown
---
name: fp-explore
description: Explore repository facts, behavior, options, constraints, and risks without modifying files or advancing a FeaturePilot workflow.
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting. Read `../_shared/artifact-layout.md` only when the objective names or depends on a current FeaturePilot artifact, slug, stage, or canonical artifact path.

# FeaturePilot Explore

## Authority and ownership
## Modes
### Public mode: standalone
### Internal profiles
## Internal invocation contract
## Internal return contract
## Repository investigation flow
### Non-empty standalone input
### Empty standalone input
### Internal one-pass flow
## Budget profiles
## Evidence classification and context precedence
## Read-only and sensitive-data boundary
## External research approval envelope
## Caller profile responsibilities
### prd-facts
### start-routing
### quick
## Stopping and handoff rules
```

Within `## Internal invocation contract`, include exactly one literal `fp-explore-invoke` block with the approved fields and enums. Within `## Internal return contract`, include exactly one literal `fp-explore-return` block with `profile: prd-facts|start-routing|quick|invalid`, all common fields, and all ten profile fields in the order asserted above.

Include these exact policy statements:

```markdown
- Allowed pairs are exact: `fp-prd` + `prd-facts`, `fp-start` + `start-routing`, and `fp-quick` + `quick`.
- Invalid internal input must fail closed before investigation: do not infer missing values, select a default profile, fall back to standalone, or ask the end user directly.
- Internal profiles return caller-owned blocking questions and then return control to the caller.
- Exploration findings and recommendations never count as user approval or confirmation.
- The read-only boundary is a semantic prompt contract, not a technical sandbox.
- Public standalone exploration asks at most one substantive question per turn.
- Handoffs recommend but never invoke another workflow.
```

Use the exact budget maxima:

```markdown
| Budget | File reads | Searches/static inspections | Local Git inspections | External sources |
|---|---:|---:|---:|---:|
| `tiny` | 6 | 4 | 1 | 0 unless approved |
| `small` | 12 | 8 | 2 | 0 unless approved |
| `standard` | 24 | 14 | 3 | 0 unless approved |
| `max` | 40 | 20 | 5 | 0 unless approved |
```

Use the exact public research envelope labels from the approved spec: `Exact question`, `Why local evidence is insufficient`, `Allowed sources or domains`, `Maximum sources`, `Version or recency requirement`, `Repository terms allowed in queries`, and `Expiration`.

The prohibited-operations section must explicitly reject file mutation, workflow artifact creation, formatters/generators/migrations/installers, builds/tests/servers/previews that may write, database/service mutation, mutating Git operations, implementation, automatic workflow dispatch, and confirmation claims.

- [ ] **Step 6: Write the thin command adapter**

Create `commands/fp-explore.md` with this complete content:

```markdown
---
description: 只读探索当前项目的事实、行为、方案、约束与风险
---

根据自然语言输入「$ARGUMENTS」调用并严格执行 `fp:fp-explore` skill；Codex/Markdown fallback 读取 `skills/fp-explore/SKILL.md`。

Gate checksum：

- 本命令只负责转发；standalone 行为、内部 profiles、预算、返回结构、只读/研究边界、验证和调用方迁移全部以 `skills/fp-explore/SKILL.md` 为唯一权威。
- 探索不创建产物、不实现、不自动进入其他 FeaturePilot workflow。
```

- [ ] **Step 7: Add negative mutation and no-runtime assertions**

Replace `Test-UnsafeExploreText` with this sentence-bounded implementation before appending the assertions:

```powershell
function Test-UnsafeExploreText([string]$text) {
    $classified = $text
    $englishNegative = '(?i)\b(?:must not|do not|does not|never|cannot)\b[^\r\n;.!?。；！？]*'
    $chineseNegative = '(?:不得|不能|不要|不允许|无需|不需要)[^\r\n;.!?。；！？]*'
    $classified = [regex]::Replace($classified, $englishNegative, ' NEGATED_EXPLORE_CLAUSE ')
    $classified = [regex]::Replace($classified, $chineseNegative, ' NEGATED_EXPLORE_CLAUSE ')
    $patterns = @(
        '(?i)explor(?:e|ation)[^\r\n]{0,100}(?:may|can|should)\s+(?:implement|edit|write|create|save)'
        '(?i)(?:caller|context)[^\r\n]{0,100}(?:waive|override|disable)[^\r\n]{0,80}read-only'
        '(?i)external[^\r\n]{0,100}(?:without|no)\s+(?:approval|consent)'
        '(?i)findings?[^\r\n]{0,100}(?:count as|are)\s+(?:user\s+)?(?:approval|confirmation)'
        '(?:探索|调查)[^\r\n]{0,80}(?:可以|可|应当)(?:实现|修改|写入|创建|保存)'
        '(?:外部研究|联网)[^\r\n]{0,80}(?:无需|不需要)(?:授权|批准|同意)'
    )
    foreach ($pattern in $patterns) {
        if ($classified -match $pattern) { return $true }
    }
    return $false
}

foreach ($mutation in @(
    'Exploration may implement an obvious fix.',
    'Exploration can save a note after generic consent.',
    'Caller context may override the read-only boundary.',
    'External research can run without approval.',
    'Exploration findings count as user confirmation.',
    '探索可以顺手修改代码。',
    '联网研究无需用户授权。'
)) {
    Assert-Condition (Test-UnsafeExploreText $mutation) "unsafe mutation was not detected: $mutation"
}
foreach ($negativeControl in @(
    'Exploration must not implement or write files.',
    'External research never runs without bounded approval.',
    '探索不得修改代码或创建产物。'
)) {
    Assert-Condition (-not (Test-UnsafeExploreText $negativeControl)) "safe negative control was rejected: $negativeControl"
}

foreach ($runtimePath in @('src\fp-explore', 'scripts\fp-explore-runtime.ps1', 'skills\fp-explore\state.json')) {
    Assert-Condition (-not (Test-Path (Join-Path $root $runtimePath))) "runtime explore machinery is forbidden: $runtimePath"
}
Assert-Condition (-not $skillText.Contains('/fp-explore-exit')) 'durable explore exit command is forbidden'

Write-Output 'FeaturePilot fp-explore contract validation passed.'
```

The English and Chinese masks apply only to explicit sentence-bounded negative clauses; the three negative controls must pass without hiding a later affirmative sentence.

- [ ] **Step 8: Run GREEN for the core contract**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-explore-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
```

Expected: the focused suite passes. The full validator discovers one additional command and skill automatically and passes command/skill frontmatter, matching-name, 20-line command, 500-line skill, and total-command-character checks. If the total command budget fails, shorten existing/new adapter wording without weakening a gate; do not raise the global 5,000-character limit in this task.

- [ ] **Step 9: Conditional checkpoint commit**

Only if the user explicitly authorized commits:

```powershell
git add -- commands/fp-explore.md skills/fp-explore/SKILL.md scripts/test-explore-contract.ps1
git commit -m "feat: add shared read-only exploration contract"
```

Otherwise skip and record “Task 1 complete, uncommitted by instruction.”

---

## Task 2: Integrate `prd-facts` Without Weakening the PRD Interview

**Files:**
- Modify: `skills/fp-prd/SKILL.md`
- Modify: `commands/fp-prd.md`
- Modify: `scripts/test-explore-contract.ps1`
- Verify unchanged behavior: `skills/fp-prd-grill-me/SKILL.md`

**Interfaces:**
- Consumes: non-empty, existing-product PRD input.
- Produces: one `prd-facts` return whose verified facts feed `fp-prd-grill-me`; product decisions remain unanswered.

- [ ] **Step 1: Add failing PRD integration assertions**

Before the final success output in `scripts/test-explore-contract.ps1`, add:

```powershell
$prdSkill = Read-Utf8 (Join-Path $root 'skills\fp-prd\SKILL.md')
$prdCommand = Read-Utf8 (Join-Path $root 'commands\fp-prd.md')
foreach ($anchor in @(
    'profile: prd-facts', 'caller: fp-prd', 'budget-profile: small',
    'prd-existing-behavior', 'prd-technical-constraints', 'prd-product-decisions',
    'purely greenfield', 'fp-prd-grill-me', 'Bucket C'
)) {
    Assert-Condition ($prdSkill.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "fp-prd integration is missing $anchor"
}
Assert-Condition ($prdSkill.Contains('If input is empty, stop')) 'fp-prd empty-input stop rule was lost'
Assert-Condition ($prdSkill.Contains('must never self-answer Bucket C')) 'fp-prd Bucket C self-answering gate was lost'
Assert-Condition ($prdCommand.Contains('fp-explore') -and $prdCommand.Contains('fp-prd-grill-me')) 'fp-prd command checksum lacks explore/interview ownership'
```

- [ ] **Step 2: Run RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-explore-contract.ps1
```

Expected: FAIL because `skills/fp-prd/SKILL.md` lacks `profile: prd-facts`.

- [ ] **Step 3: Insert the shared exploration boundary into `fp-prd`**

Immediately after the current `## Required Interview Skill` ownership paragraph, insert this complete subsection:

```markdown
### Shared code-fact exploration

Before either PRD-first or Prototype-first interviewing, load `fp-explore` and invoke `prd-facts` only when the input is non-empty, concerns an existing product/page/API/model/permission/compatibility behavior, current repository facts can reduce technical uncertainty, and the idea is not purely greenfield. Empty input keeps the existing immediate-stop rule and performs no exploration.

<!-- fp-explore-invoke
profile: prd-facts
objective: Establish existing user-visible behavior, implementation entrypoints, interface/data facts, adjacent product patterns, and technical constraints relevant to this PRD input without deciding requirements, scope, acceptance criteria, or prototype expectations.
caller: fp-prd
active-slug:
caller-owned-context:
  - current non-empty user input and already confirmed product facts
scope-include:
  - user-named pages, routes, APIs, models, permissions, components, and tests
scope-exclude:
  - unrelated fp-docs/changes, archive, and history
budget-profile: small
return-shape: profile-default
external-research: not-authorized
approved-research-boundary:
-->

Consume `verified-facts`, `prd-existing-behavior`, and `prd-technical-constraints` only as code facts for `fp-prd-grill-me`. Keep every `prd-product-decisions` item unanswered for Bucket C or the confirmation summary. Existing UI, enums, routes, APIs, permissions, and adjacent patterns do not imply that the user wants to preserve them. `fp-prd-grill-me` remains the only interview and confirmation authority, and `fp-prd` must never self-answer Bucket C.
```

In both process branches, replace the old “minimal fact exploration” wording with an explicit reference to this subsection, followed by loading/running `fp-prd-grill-me`. Do not move or weaken the current hard interview gate, empty-input rule, output-form rules, or existing uncommitted `/fp-start <slug>` completion contract.

- [ ] **Step 4: Update only the PRD command checksum**

Add one checksum bullet after the existing PRD-first/Prototype-first bullet:

```markdown
- 非空且涉及现有产品时，`fp-explore` 只提供代码事实；`fp-prd-grill-me` 仍独占产品决策提问与确认。
```

Keep `commands/fp-prd.md` at or below 20 lines. Preserve its explicit-only frontmatter sentence exactly.

- [ ] **Step 5: Run GREEN and targeted regression**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-explore-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
git diff --check -- skills/fp-prd/SKILL.md commands/fp-prd.md scripts/test-explore-contract.ps1
```

Expected: all pass. The full validator still finds `Bucket A/B`, `Bucket C`, `Prototype-first`, `explicitly approved`, and `prd-template.md` in `fp-prd`.

- [ ] **Step 6: Conditional checkpoint commit**

Only if the user explicitly authorizes commits **and** the protected pre-existing `fp-prd` output-contract edits have already been committed separately or the user explicitly authorizes combining them in this commit:

```powershell
git add -- skills/fp-prd/SKILL.md commands/fp-prd.md scripts/test-explore-contract.ps1
git diff --cached -- skills/fp-prd/SKILL.md commands/fp-prd.md scripts/test-explore-contract.ps1
git commit -m "feat: feed explored code facts into PRD interviews"
```

Otherwise skip. Do not stage a protected hunk merely to satisfy the plan's checkpoint.

---

## Task 3: Consolidate `fp-start` Routing and Enable Gap-Only `fp-propose` Exploration

**Files:**
- Modify: `skills/fp-start/SKILL.md`
- Modify: `commands/fp-start.md`
- Modify: `skills/fp-propose/SKILL.md`
- Modify: `scripts/test-explore-contract.ps1`
- Protect: `skills/fp-execute-sdd/SKILL.md`

**Interfaces:**
- Consumes: feature description or caller-resolved active slug plus current-stage facts.
- Produces: advisory `start-route-assessment` and `start-reusable-context`.
- Downstream: `fp-propose` accepts verified upstream facts with inspected scope, evidence, budget, worktree state, and uninspected areas.

- [ ] **Step 1: Add failing start/propose assertions**

Add:

```powershell
$startSkill = Read-Utf8 (Join-Path $root 'skills\fp-start\SKILL.md')
$startCommand = Read-Utf8 (Join-Path $root 'commands\fp-start.md')
$proposeSkill = Read-Utf8 (Join-Path $root 'skills\fp-propose\SKILL.md')
foreach ($anchor in @(
    'profile: start-routing', 'caller: fp-start', 'budget-profile: standard',
    'start-active-stage', 'start-route-assessment', 'start-reusable-context',
    'advisory', 'explicit user choice'
)) {
    Assert-Condition ($startSkill.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "fp-start integration is missing $anchor"
}
foreach ($anchor in @('start-reusable-context', 'verified facts', 'inspected scope', 'uninspected areas', 'gap-only')) {
    Assert-Condition ($proposeSkill.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "fp-propose reuse contract is missing $anchor"
}
Assert-Condition ($startCommand.Contains('fp-explore') -and $startCommand.Contains('用户确认')) 'fp-start command lacks explore routing and user choice'
Assert-Condition ($startSkill.Contains('Execution strategy gate')) 'protected direct-versus-SDD gate was lost'
Assert-Condition ($startSkill.Contains('SDD continuation mode gate')) 'protected SDD continuation gate was lost'
```

- [ ] **Step 2: Run RED**

Expected focused failure: `fp-start` lacks `profile: start-routing`.

- [ ] **Step 3: Replace the three overlapping pre-stage sections with one shared routing section**

In `skills/fp-start/SKILL.md`, replace the current `## PRD handoff mode`, `## 小需求分流`, and `## 前置检查：代码上下文` sections with:

```markdown
## Shared start-routing exploration

After the non-empty-input and init-availability checks, load `fp-explore` once before phase 1. `fp-start` remains responsible for canonical artifact resolution, the final active slug, the quick/full choice, and every stage gate.

<!-- fp-explore-invoke
profile: start-routing
objective: Establish current PRD and stage evidence, quick-versus-full routing evidence, implementation boundaries, and the minimum verified context reusable by the next phase for this request.
caller: fp-start
active-slug: <caller-resolved exact slug or empty>
caller-owned-context:
  - current user argument, explicit continuation facts, and already confirmed PRD facts
scope-include:
  - fp-docs/manifest.md when present
  - the exact candidate change directory only when fp-start already resolved one
  - requirement-related source, routes, interfaces, models, components, and tests
scope-exclude:
  - unrelated fp-docs/changes, archive, and history
budget-profile: standard
return-shape: profile-default
external-research: not-authorized
approved-research-boundary:
-->

Treat `start-active-stage` and `start-route-assessment` as advisory evidence. `fp-explore` may report exact paths and candidate matches but never generates or normalizes the slug. When the evidence supports `quick`, explain why and wait for an explicit user choice between `fp-quick` and the full `fp-start` flow. Only after the user chooses quick may `fp-start` load `fp-quick`; otherwise continue to phase 1.

For the full flow, pass `start-reusable-context` to `fp-propose` together with the exploration objective, inspected scope, evidence paths/lines, budget state, relevant observed worktree state, uninspected areas, and separately labeled inferences. Exploration does not advance a stage and does not count as proposal confirmation.
```

Retain the current canonical artifact resolution section above it. In phase 1, change “探索项目现状” to “reuse fresh `start-reusable-context`, then let `fp-propose` inspect only gaps.” Do not alter the current design-finalization, resume, bookkeeping, planning, direct/SDD selection, SDD continuation, execution, or review sections.

- [ ] **Step 4: Add gap-only reuse to `fp-propose`**

After `## PRD handoff input`, insert:

```markdown
### Upstream start-routing context

When `fp-start` supplies `start-reusable-context`, reuse only its verified facts whose inspected scope still covers the proposal question and whose relevant files/worktree state have not changed. Preserve evidence paths, budget state, and uninspected areas. Treat inferences as inferences, never as reusable facts or user confirmation.

Perform gap-only exploration: inspect areas that were not covered, facts invalidated by relevant worktree changes, or evidence insufficient for proposal scope, impact, or delivery strategy. Direct `fp-propose` use without upstream context keeps the normal exploration phase.
```

Update the existing exploration bullets to say they apply fully when no reusable context exists and incrementally when it does.

- [ ] **Step 5: Update `commands/fp-start.md` without losing protected execution gates**

Replace the first checksum bullet with:

```markdown
- 用一次 `fp-explore start-routing` 复用匹配 PRD、判断阶段并提供 quick/full 证据；只有用户确认后才切换 `fp-quick`。
```

Preserve the current bullets requiring explicit direct-versus-SDD choice and SDD continuation choice. Keep the adapter at or below 20 lines.

- [ ] **Step 6: Run GREEN and protected-gate checks**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-explore-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
git diff -- skills/fp-execute-sdd/SKILL.md
git diff --check -- skills/fp-start/SKILL.md commands/fp-start.md skills/fp-propose/SKILL.md
```

Expected: validators pass. The `fp-execute-sdd` diff remains exactly the pre-existing continuation-mode diff captured in Task 1; this task adds no lines to it.

- [ ] **Step 7: Conditional checkpoint commit**

Only if the user explicitly authorizes commits **and** the protected pre-existing `fp-start`/validator edits have already been committed separately or the user explicitly authorizes combining them:

```powershell
git add -- skills/fp-start/SKILL.md commands/fp-start.md skills/fp-propose/SKILL.md scripts/test-explore-contract.ps1
git diff --cached -- skills/fp-start/SKILL.md commands/fp-start.md skills/fp-propose/SKILL.md scripts/test-explore-contract.ps1
git commit -m "feat: centralize start routing exploration"
```

Never stage `skills/fp-execute-sdd/SKILL.md`. Otherwise skip this checkpoint rather than mixing protected hunks.

---

## Task 4: Migrate `fp-quick` from Full `fp-propose` Exploration

**Files:**
- Modify: `skills/fp-quick/SKILL.md`
- Modify: `commands/fp-quick.md`
- Modify: `scripts/test-explore-contract.ps1`
- Modify later in Task 5: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: one small-change request.
- Produces: candidate files, reusable patterns, verification paths, risks, blocking questions, and an advisory scope assessment.

- [ ] **Step 1: Add failing quick assertions**

Add:

```powershell
$quickSkill = Read-Utf8 (Join-Path $root 'skills\fp-quick\SKILL.md')
$quickCommand = Read-Utf8 (Join-Path $root 'commands\fp-quick.md')
foreach ($anchor in @(
    'profile: quick', 'caller: fp-quick', 'budget-profile: small',
    'quick-candidate-files', 'quick-reusable-patterns', 'quick-verification',
    'quick-scope-assessment', 'one substantive question'
)) {
    Assert-Condition ($quickSkill.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "fp-quick integration is missing $anchor"
}
Assert-Condition (-not $quickSkill.Contains('用 fp-propose 探索项目背景')) 'fp-quick still delegates exploration to fp-propose'
Assert-Condition (-not $quickCommand.Contains('复用 `fp-propose`')) 'fp-quick command still delegates exploration to fp-propose'
Assert-Condition ($quickCommand.Contains('fp-explore')) 'fp-quick command lacks fp-explore routing'
foreach ($gate in @('不创建 `fp-docs/changes/', '等待明确确认', '验证')) {
    Assert-Condition ($quickSkill.Contains($gate)) "fp-quick lost caller-owned gate $gate"
}
```

- [ ] **Step 2: Run RED**

Expected: FAIL because `fp-quick` still loads `fp-propose` and permits 1–3 questions.

- [ ] **Step 3: Replace quick exploration with the structured profile**

Change the frontmatter description so it says `fp-quick` must load `fp-explore` with `profile: quick`, not `fp-propose`.

Replace `### 1. 用 fp-propose 探索项目背景` and its duplicated exploration list with:

```markdown
### 1. 用 fp-explore quick 探索项目背景

Load `fp-explore` once and invoke its `quick` profile. Do not load the full `fp-propose` skill for exploration.

<!-- fp-explore-invoke
profile: quick
objective: Locate candidate files, module boundaries, reusable code and test patterns, verification paths, implementation blockers, and quick-flow suitability evidence for this requested small change.
caller: fp-quick
active-slug:
caller-owned-context:
  - current user request and already confirmed constraints
scope-include:
  - user-named files, symbols, routes, APIs, models, components, and tests
scope-exclude:
  - fp-docs/changes/, archive/, and history/
budget-profile: small
return-shape: profile-default
external-research: not-authorized
approved-research-boundary:
-->

Use `quick-candidate-files`, `quick-reusable-patterns`, and `quick-verification` to build the inline plan. Treat `quick-scope-assessment` as advisory evidence only; `fp-quick` retains the final suitability decision. Keep current source and tests as the implementation truth and preserve the no-FeaturePilot-artifact boundary.
```

Replace “每次最多问 1-3 个关键问题” with:

```markdown
- Ask at most one substantive question per turn. If multiple decisions are genuinely inseparable, express them as one structured choice rather than a list of separate questions.
```

Retain the existing inline-plan fields, explicit approval requirement, implementation discipline, and validation report.

- [ ] **Step 4: Update the quick command checksum**

Replace its first checksum bullet with:

```markdown
- 使用 `fp-explore quick` 获取候选文件、复用模式、验证路径与范围证据；不加载完整 `fp-propose`，不生成 FeaturePilot change 文档。
```

Change the second bullet to:

```markdown
- 有阻塞问题时每轮最多问一个实质性问题；否则输出内联实现计划。
```

Keep plan confirmation and validation unchanged.

- [ ] **Step 5: Run focused GREEN**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-explore-contract.ps1
git diff --check -- skills/fp-quick/SKILL.md commands/fp-quick.md
```

Expected: focused suite passes. Full plugin validation is expected to fail at the old `fp-quick` anchor set until Task 5 updates it; the failure must name an obsolete `fp-propose`/`proposal.md` anchor, not a syntax or unrelated contract failure.

- [ ] **Step 6: Conditional checkpoint commit**

Only if explicitly authorized:

```powershell
git add -- skills/fp-quick/SKILL.md commands/fp-quick.md scripts/test-explore-contract.ps1
git commit -m "feat: use shared exploration in quick flow"
```

Otherwise skip.

---

## Task 5: Integrate `fp-explore` into Full Plugin Validation

**Files:**
- Modify: `scripts/validate-plugin.ps1`
- Modify: `scripts/test-explore-contract.ps1`
- Protect existing edits near current PRD-output and execution-strategy assertions.

**Interfaces:**
- Consumes: the focused validator as a child PowerShell script.
- Produces: one full plugin validation result that includes explore discovery, authority, caller migration, and negative contract coverage.

- [ ] **Step 1: Add a self-check that full validation invokes the focused suite**

In `scripts/test-explore-contract.ps1`, add:

```powershell
$fullValidator = Read-Utf8 (Join-Path $root 'scripts\validate-plugin.ps1')
Assert-Condition ($fullValidator.Contains('test-explore-contract.ps1')) 'validate-plugin.ps1 does not invoke the focused explore suite'
Assert-Condition ($fullValidator.Contains("'fp-explore'")) 'validate-plugin.ps1 lacks the fp-explore skill anchor set'
```

- [ ] **Step 2: Run RED**

Expected: FAIL because full validation does not yet invoke the focused suite.

- [ ] **Step 3: Update the central skill anchors**

In `$skillAnchors`, add:

```powershell
'fp-explore' = @('mode: standalone', 'prd-facts', 'start-routing', 'quick', 'fp-explore-invoke', 'fp-explore-return', 'read-only')
```

Replace the old `fp-quick` entry with:

```powershell
'fp-quick' = @('fp-explore', 'quick-candidate-files', 'quick-reusable-patterns', 'quick-verification', 'quick-scope-assessment', 'fp-docs/changes/')
```

Do not alter unrelated anchor sets.

- [ ] **Step 4: Invoke the focused suite from the full validator**

Immediately after the command/skill discovery and frontmatter loops, insert:

```powershell
$exploreContractValidator = Join-Path $root 'scripts\test-explore-contract.ps1'
Assert-Condition (Test-Path $exploreContractValidator) 'focused fp-explore contract validator is missing'
& powershell -NoProfile -ExecutionPolicy Bypass -File $exploreContractValidator
Assert-Condition ($LASTEXITCODE -eq 0) 'focused fp-explore contract validator failed'
```

Use a child `powershell` process rather than dot-sourcing so both scripts may keep their own strict mode, helper names, and `$root` variables.

- [ ] **Step 5: Add live negative migration assertions without touching protected blocks**

After `$skillAnchors` validation, add:

```powershell
$quickSkillText = Read-Utf8 (Join-Path $root 'skills\fp-quick\SKILL.md')
Assert-Condition (-not $quickSkillText.Contains('用 fp-propose 探索项目背景')) 'fp-quick still uses fp-propose as exploration authority'
Assert-Condition (-not $quickSkillText.Contains('每次最多问 1-3 个关键问题')) 'fp-quick still batches separate clarification questions'

$prdExploreText = Read-Utf8 (Join-Path $root 'skills\fp-prd\SKILL.md')
Assert-Condition ($prdExploreText.Contains('fp-prd-grill-me') -and $prdExploreText.Contains('must never self-answer Bucket C')) 'prd-facts weakened the PRD interview gate'

$startExploreText = Read-Utf8 (Join-Path $root 'skills\fp-start\SKILL.md')
Assert-Condition ($startExploreText.Contains('profile: start-routing') -and $startExploreText.Contains('explicit user choice')) 'start-routing lacks caller-owned routing choice'
Assert-Condition ($startExploreText.Contains('Execution strategy gate') -and $startExploreText.Contains('SDD continuation mode gate')) 'start-routing edit removed protected execution gates'
```

- [ ] **Step 6: Run full GREEN**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-explore-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
git diff --check -- scripts/validate-plugin.ps1 scripts/test-explore-contract.ps1
```

Expected: focused suite prints its pass line; full validator then prints the updated command/skill counts and succeeds. Existing PRD-output, artifact-layout, direct/SDD, and SDD-continuation assertions remain present and passing.

- [ ] **Step 7: Conditional checkpoint commit**

Only if explicitly authorized **and** the protected pre-existing validator hunks have already been committed separately or the user explicitly authorizes combining them:

```powershell
git add -- scripts/validate-plugin.ps1 scripts/test-explore-contract.ps1
git diff --cached -- scripts/validate-plugin.ps1 scripts/test-explore-contract.ps1
git commit -m "test: enforce shared exploration contracts"
```

Otherwise skip; do not try to stage only parts of `scripts/validate-plugin.ps1` with interactive Git commands in this harness.

---

## Task 6: Add Deterministic Context Measurements

**Files:**
- Modify: `scripts/measure-context.ps1`
- Modify: `scripts/test-explore-contract.ps1`

**Interfaces:**
- Produces: measured scenarios `ExplorePublic`, `PrdWithExplore`, `StartWithExplore`, `QuickWithExplore`, and `QuickLegacyWithPropose`.
- Enforces: `skills/fp-explore/SKILL.md` at or below 30,000 UTF-16 code units and `ExplorePublic` at or below 45,000 characters.

- [ ] **Step 1: Add failing measurement assertions**

Add to the focused suite:

```powershell
$measureText = Read-Utf8 (Join-Path $root 'scripts\measure-context.ps1')
foreach ($anchor in @(
    'ExplorePublic', 'PrdWithExplore', 'StartWithExplore',
    'QuickWithExplore', 'QuickLegacyWithPropose',
    'exploreSkillMaxChars', 'explorePublicMaxChars'
)) {
    Assert-Condition ($measureText.Contains($anchor)) "context measurement is missing $anchor"
}
```

- [ ] **Step 2: Run RED**

Expected: FAIL because `ExplorePublic` is missing.

- [ ] **Step 3: Extend `measure-context.ps1` with explicit scenarios**

After `$shared`, add:

```powershell
$exploreSkill = Get-Chars @('skills\fp-explore\SKILL.md')
$exploreSkillMaxChars = 30000
$explorePublicMaxChars = 45000
```

Extend `$current` with:

```powershell
ExplorePublic = $shared + (Get-Chars @('commands\fp-explore.md', 'skills\fp-explore\SKILL.md'))
PrdWithExplore = $shared + (Get-Chars @('commands\fp-prd.md', 'skills\fp-prd\SKILL.md', 'skills\fp-prd-grill-me\SKILL.md', 'skills\fp-grill-me\SKILL.md', 'skills\fp-explore\SKILL.md'))
StartWithExplore = $shared + (Get-Chars @('commands\fp-start.md', 'skills\fp-start\SKILL.md', 'skills\fp-explore\SKILL.md', 'skills\fp-propose\SKILL.md', 'skills\fp-brainstorm\SKILL.md', 'skills\fp-plan\SKILL.md', 'skills\fp-plan-backend\SKILL.md', 'skills\fp-plan-frontend\SKILL.md', 'skills\fp-execute-sdd\SKILL.md', 'skills\fp-review\SKILL.md'))
QuickWithExplore = $shared + (Get-Chars @('commands\fp-quick.md', 'skills\fp-quick\SKILL.md', 'skills\fp-explore\SKILL.md'))
QuickLegacyWithPropose = $shared + (Get-Chars @('commands\fp-quick.md', 'skills\fp-quick\SKILL.md', 'skills\fp-propose\SKILL.md'))
```

Because new scenarios have no historical baseline, print them in a separate table instead of adding fake baseline values:

```powershell
if ($exploreSkill -gt $exploreSkillMaxChars) {
    throw "fp-explore skill exceeds guard: $exploreSkill > $exploreSkillMaxChars"
}
if ($current.ExplorePublic -gt $explorePublicMaxChars) {
    throw "ExplorePublic exceeds guard: $($current.ExplorePublic) > $explorePublicMaxChars"
}

Write-Output 'Explore and caller prompt-character proxy:'
@('ExplorePublic', 'PrdWithExplore', 'StartWithExplore', 'QuickWithExplore', 'QuickLegacyWithPropose') | ForEach-Object {
    [PSCustomObject]@{ Scenario = $_; CurrentChars = $current[$_] }
} | Format-Table -AutoSize
```

Keep the existing `Core`, `Prd`, `Start`, and `Review` baseline table unchanged.

- [ ] **Step 4: Run GREEN and inspect the comparison**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\measure-context.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-explore-contract.ps1
```

Expected: both pass; output includes all five new scenarios. Record `QuickWithExplore` and `QuickLegacyWithPropose` values. If `QuickWithExplore` is not smaller, reduce duplicated exploration prose in `fp-quick`/`fp-explore`; do not remove required safety or caller gates and do not alter the legacy comparison formula.

- [ ] **Step 5: Conditional checkpoint commit**

Only if explicitly authorized:

```powershell
git add -- scripts/measure-context.ps1 scripts/test-explore-contract.ps1
git commit -m "test: measure shared exploration context"
```

Otherwise skip.

---

## Task 7: Synchronize Public Documentation and Markdown-Agent Routing

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `docs/user_guide/init-prd-start.md`
- Modify: `scripts/test-explore-contract.ps1`

**Interfaces:**
- Public docs describe only user-visible behavior and routing.
- Detailed profiles, budgets, result schemas, and safety policy remain in `skills/fp-explore/SKILL.md`.

- [ ] **Step 1: Add failing documentation assertions**

Add:

```powershell
$readme = Read-Utf8 (Join-Path $root 'README.md')
$agents = Read-Utf8 (Join-Path $root 'AGENTS.md')
$userGuide = Read-Utf8 (Join-Path $root 'docs\user_guide\init-prd-start.md')
foreach ($surface in @(
    @{ Name = 'README.md'; Text = $readme },
    @{ Name = 'AGENTS.md'; Text = $agents },
    @{ Name = 'user guide'; Text = $userGuide }
)) {
    Assert-Condition ($surface.Text.Contains('/fp-explore') -or $surface.Text.Contains('fp-explore')) "$($surface.Name) does not document fp-explore"
    Assert-Condition (-not $surface.Text.Contains('quick-candidate-files:')) "$($surface.Name) copied the internal return schema"
    Assert-Condition (-not $surface.Text.Contains('approved-research-boundary:')) "$($surface.Name) copied the internal invocation schema"
}
Assert-Condition ($readme.Contains('commands/fp-explore.md')) 'README command table lacks fp-explore'
Assert-Condition ($agents.Contains('skills/fp-explore/SKILL.md')) 'AGENTS intent routing lacks fp-explore fallback'
```

- [ ] **Step 2: Run RED**

Expected: FAIL because the public surfaces do not yet mention `fp-explore`.

- [ ] **Step 3: Update `README.md` concisely**

Add to the core command table:

```markdown
| `commands/fp-explore.md` | 只读调查当前代码事实、行为、约束、风险和可选方案；支持空输入的有界项目概览，不创建产物、不进入实现 |
```

Add to core skills:

```markdown
- `fp-explore`：公共自然语言探索入口，也是 `fp-prd`、`fp-start`、`fp-quick` 的共享只读调查能力；内部调用使用结构化 profile，但产品决策、确认、写入和实现始终由调用方负责。
```

In the low-cost flow, insert exploration as optional step 1 and renumber later steps:

```markdown
1. **可选探索**：运行 `/fp-explore <问题>` 调查当前实现或比较方案；空输入只做有界项目概览。探索不创建 FeaturePilot 产物，也不修改代码。
```

Add `/fp-explore 当前审批流的入口和权限边界是什么` to the local usage examples. Do not copy budget tables or invocation/return blocks.

- [ ] **Step 4: Update `AGENTS.md` routing**

Add one intent row or equivalent routing bullet:

```markdown
- 只读调查项目事实、行为、约束、风险或方案比较：读取 `skills/fp-explore/SKILL.md`；公共输入可用自然语言，内部 profile 只能由 `fp-prd`、`fp-start`、`fp-quick` 按该 skill 的结构化契约调用。
```

Add `fp-explore` to the skill-directory reference list. State that it never writes artifacts or automatically dispatches another workflow.

- [ ] **Step 5: Update the user guide**

Before PRD/start instructions, add:

```markdown
## 可选：先用 `/fp-explore` 调查

`/fp-explore <问题>` 用于只读调查当前代码、测试、接口、行为、约束、风险和可选方案。空输入只做有界项目概览，然后询问你想深入的方向。它不会创建 PRD/proposal/design/tasks，不会修改代码，也不会自动切换到其他流程。

`fp-prd`、`fp-start` 和 `fp-quick` 会在内部复用相同探索能力：PRD 只消费代码事实且仍由 `fp-prd-grill-me` 确认产品决策；start 仍由用户选择 quick/full；quick 仍须先确认内联计划才能实现。
```

- [ ] **Step 6: Run documentation GREEN and full validation**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-explore-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\measure-context.ps1
git diff --check -- README.md AGENTS.md docs/user_guide/init-prd-start.md
```

Expected: all pass; public docs contain no internal field schema.

- [ ] **Step 7: Conditional checkpoint commit**

Only if explicitly authorized:

```powershell
git add -- README.md AGENTS.md docs/user_guide/init-prd-start.md scripts/test-explore-contract.ps1
git commit -m "docs: document shared exploration workflow"
```

Otherwise skip.

---

## Task 8: Verify State-Neutral Scenarios and Run the Full Regression Suite

**Files:**
- Verify: all files listed in the File Structure Map.
- Do not modify product files unless a verified scenario exposes a contract gap.

**Interfaces:**
- Consumes: completed Markdown contracts and validators.
- Produces: final evidence that standalone and internal exploration are read-only, caller-owned, bounded, and consistent.

- [ ] **Step 1: Record pre-verification repository state and contract hashes**

Run:

```powershell
$beforeStatus = git status --porcelain=v1 -uall
$contractFiles = @(
    'commands/fp-explore.md',
    'skills/fp-explore/SKILL.md',
    'skills/fp-prd/SKILL.md',
    'skills/fp-start/SKILL.md',
    'skills/fp-propose/SKILL.md',
    'skills/fp-quick/SKILL.md',
    'scripts/test-explore-contract.ps1',
    'scripts/validate-plugin.ps1',
    'scripts/measure-context.ps1'
)
$beforeHashes = @{}
foreach ($path in $contractFiles) { $beforeHashes[$path] = (Get-FileHash $path -Algorithm SHA256).Hash }
$beforeStatus
```

Expected: only known implementation changes plus protected pre-existing changes appear.

- [ ] **Step 2: Exercise the nine contract scenarios**

Use a temporary conversation/test harness that reads the skill but does not edit the repository. For each scenario, record the returned mode/profile, status, inspected scope, and whether a user/caller decision is requested:

1. Empty public input — bounded orientation and one project-grounded question; no broad source scan.
2. Concrete public question — path-backed facts, separate inferences, no automatic implementation.
3. Existing-product PRD — behavior and constraints returned; Bucket C remains unanswered.
4. Greenfield PRD — `prd-facts` is skipped and interview starts without repository scanning.
5. Start quick candidate — advisory `quick` route evidence followed by `fp-start` user choice.
6. Start full flow — `start-reusable-context` reaches `fp-propose`; only uncovered gaps are inspected.
7. Quick local change — candidate files/patterns/verification without loading full `fp-propose`.
8. External knowledge gap — no network before the exact approval envelope; no silent source expansion.
9. Invalid internal call — `blocked` and `not-started-invalid-invocation`, no inferred defaults and no direct end-user question.

If the environment cannot execute prompt-level scenarios deterministically, use in-memory fixtures in `scripts/test-explore-contract.ps1` for each input/expected contract and report the manual behavior check as not executed; do not claim it passed.

- [ ] **Step 3: Verify pure exploration did not mutate state**

Run:

```powershell
$afterStatus = git status --porcelain=v1 -uall
foreach ($path in $contractFiles) {
    $after = (Get-FileHash $path -Algorithm SHA256).Hash
    if ($after -ne $beforeHashes[$path]) { throw "Pure exploration changed $path" }
}
if (($beforeStatus -join "`n") -ne ($afterStatus -join "`n")) {
    throw 'Pure exploration changed the observed repository status'
}
```

Expected: no hash or status difference from the pre-verification snapshot.

- [ ] **Step 4: Run all focused and existing regressions**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-explore-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-artifact-layout.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-sdd-benchmark-fixture.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\measure-context.ps1
git diff --check
```

Expected: every available script exits 0. If a listed existing script is absent, report it as skipped with the exact missing path; do not silently omit it.

- [ ] **Step 5: Audit protected pre-existing work and scope**

Run:

```powershell
git diff -- commands/fp-start.md scripts/validate-plugin.ps1 skills/fp-execute-sdd/SKILL.md skills/fp-prd/SKILL.md skills/fp-start/SKILL.md
git status --short
git diff --name-only
```

Confirm:

- `skills/fp-execute-sdd/SKILL.md` contains only the pre-existing continuation-mode diff;
- `fp-start` still contains direct-versus-SDD and SDD continuation gates;
- `fp-prd` still contains the pre-existing mandatory `/fp-start <slug>` successful-output contract;
- `scripts/validate-plugin.ps1` still contains all pre-existing execution-mode assertions;
- no parser, dispatcher, state JSON, service, dependency, or explore artifact was added;
- no unrelated file was modified.

- [ ] **Step 6: Produce the final implementation report**

Report:

- public `/fp-explore` behavior;
- all three integrated caller profiles;
- caller gates preserved;
- focused and full validation commands with actual results;
- context measurements, including `QuickWithExplore` versus `QuickLegacyWithPropose`;
- state-neutral scenario evidence or explicitly unexecuted manual checks;
- protected pre-existing changes left intact;
- residual risks or skipped checks.

- [ ] **Step 7: Conditional final commit**

Only if the user explicitly authorizes commits, the protected pre-existing edits in overlapping files have already been committed separately or the user explicitly authorizes combining them, and earlier task commits were skipped, stage the intended implementation files after reviewing the exact cached diff:

```powershell
git add -- commands/fp-explore.md commands/fp-prd.md commands/fp-start.md commands/fp-quick.md skills/fp-explore/SKILL.md skills/fp-prd/SKILL.md skills/fp-start/SKILL.md skills/fp-propose/SKILL.md skills/fp-quick/SKILL.md scripts/test-explore-contract.ps1 scripts/validate-plugin.ps1 scripts/measure-context.ps1 README.md AGENTS.md docs/user_guide/init-prd-start.md
git diff --cached --check
git diff --cached --stat
git diff --cached -- commands/fp-start.md skills/fp-start/SKILL.md skills/fp-prd/SKILL.md scripts/validate-plugin.ps1
git commit -m "feat: add shared exploration workflow"
```

Do not stage `skills/fp-execute-sdd/SKILL.md` or the unrelated execution-mode design/plan. If combining protected hunks is not explicitly authorized, skip the final commit and report the mixed working-tree boundary instead of attempting an interactive partial-stage operation.
