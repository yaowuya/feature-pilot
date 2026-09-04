# FeaturePilot Module Review Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the full-lifecycle `fp-module-review` skill and completely rename the existing final whole-branch review from `fp-review` to `fp-final-review`.

**Architecture:** `fp-module-review` is a self-contained controller whose main skill defines state, gates, and evidence rules while lazy-loaded templates define the stable workspace artifacts. The existing final reviewer keeps its behavior unchanged under new command, skill, template anchors, focused validator, and orchestrator references. PowerShell focused contract tests provide RED/GREEN gates before the global plugin validator is updated.

**Tech Stack:** Markdown Claude Code/Codex skills and commands, PowerShell contract validators, Git path moves, FeaturePilot shared workspace and CodeGraph contracts.

## Global Constraints

- Follow `docs/superpowers/specs/2026-07-28-fp-module-review-skill-design.md` exactly.
- `fp-module-review` owns large or multi-module review, controlled fixing, and verification; `fp-final-review` remains read-only final whole-branch review before archive or merge.
- The old `fp-review` command, skill path, validator name, and active workflow identifiers are removed rather than retained as aliases.
- Historical migration prose in this spec/plan may mention `fp-review`; active commands, runtime paths, skill metadata, templates, orchestrators, validators, and user guidance may not.
- Do not overwrite concurrent `fp-coverage` work. Re-read `AGENTS.md`, `README.md`, and `scripts/validate-plugin.ps1` immediately before editing and preserve all coverage additions.
- Do not alter `docs/superpowers/specs/2026-07-28-fp-coverage-skill-design.md`, `docs/superpowers/plans/2026-07-28-fp-coverage-skill-implementation.md`, `commands/fp-coverage.md`, `skills/fp-coverage/**`, or `scripts/test-coverage-contract.ps1`.
- Do not install dependencies, initialize CodeGraph, contact external systems, commit, push, or create a pull request without explicit authorization.
- Every `SKILL.md` must contain only `name` and `description` frontmatter keys, load `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md`, include the Codex installed-skill mapping sentence, and stay at or below 500 lines.
- Process artifact narrative defaults to Chinese under the shared process-language contract; exact states, IDs, paths, commands, schema fields, and technical identifiers remain English.

---

## File Structure

### New module-review surfaces

- `commands/fp-module-review.md`: thin user command and immutable gate checksum.
- `skills/fp-module-review/SKILL.md`: full lifecycle, scope, safety, finding, approval, fixing, resume, verification, and completion controller.
- `skills/fp-module-review/review-entry-template.md`: canonical `review.md` entry and manifest schema.
- `skills/fp-module-review/scope-template.md`: bounded scope and protected/write path schema.
- `skills/fp-module-review/baseline-template.md`: compatibility, test, environment, and command-safety evidence schema.
- `skills/fp-module-review/waves-template.md`: ownership-based wave plan and status schema.
- `skills/fp-module-review/finding-template.md`: one stable `MR-FNNN` owner schema.
- `skills/fp-module-review/summary-template.md`: final reconciliation and completion schema.
- `skills/fp-module-review/progress-event-template.md`: append-only resume event schema.
- `scripts/test-module-review-contract.ps1`: focused semantic contract with positive anchors and negative mutation fixtures.

### Renamed final-review surfaces

- `commands/fp-final-review.md`: renamed command; behavior unchanged.
- `skills/fp-final-review/SKILL.md`: renamed skill and all plugin-root anchors.
- `skills/fp-final-review/final-reviewer.md`: renamed delegation references.
- `skills/fp-final-review/final-review-template.md`: renamed report identity references.
- `skills/fp-final-review/final-review-package-template.md`: renamed dispatch references.
- `scripts/test-final-review-contract.ps1`: renamed focused validator and all expected paths/names.

### Integration surfaces

- `skills/fp-start/SKILL.md`, `commands/fp-start.md`: dispatch `fp-final-review` after direct execution.
- `skills/fp-execute/SKILL.md`, `skills/fp-execute-sdd/SKILL.md`: final-review name and dispatch wording only.
- `skills/fp-brainstorm/SKILL.md`, `skills/_shared/codegraph.md`: consumer name updates and module-review graph evidence rules.
- `scripts/test-figma-evidence-contract.ps1`, `scripts/test-init-information-layer-contract.ps1`: renamed final-review paths and labels.
- `scripts/measure-context.ps1`: renamed paths and `FinalReview` measurement key.
- `scripts/validate-plugin.ps1`: invoke both focused validators and update all final-review path/name contracts.
- `AGENTS.md`, `README.md`, `docs/user_guide/init-prd-start.md`, `docs/release_notes/1.0.0.md`: user-facing command table and terminology.

---

### Task 1: Add the failing module-review focused contract

**Files:**
- Create: `scripts/test-module-review-contract.ps1`
- Test: `scripts/test-module-review-contract.ps1`

**Interfaces:**
- Consumes: approved design path and repository root conventions used by other focused validators.
- Produces: a RED contract that requires the exact command, skill, templates, lifecycle, finding schema, approval gate, safe fixing loop, resume rules, and completion predicates.

- [ ] **Step 1: Create the focused validator with required paths and helpers**

Create `scripts/test-module-review-contract.ps1` with this structure:

```powershell
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) { throw "Module review contract validation failed: $message" }
}

function Read-Utf8([string]$relativePath) {
    return [System.IO.File]::ReadAllText((Join-Path $root $relativePath), [System.Text.Encoding]::UTF8)
}

function Assert-Anchors([string]$text, [string[]]$anchors, [string]$surface) {
    foreach ($anchor in $anchors) {
        Assert-Condition ($text.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "$surface lost anchor: $anchor"
    }
}

$required = @(
    'commands\fp-module-review.md',
    'skills\fp-module-review\SKILL.md',
    'skills\fp-module-review\review-entry-template.md',
    'skills\fp-module-review\scope-template.md',
    'skills\fp-module-review\baseline-template.md',
    'skills\fp-module-review\waves-template.md',
    'skills\fp-module-review\finding-template.md',
    'skills\fp-module-review\summary-template.md',
    'skills\fp-module-review\progress-event-template.md'
)
foreach ($path in $required) {
    Assert-Condition (Test-Path (Join-Path $root $path)) "required surface is missing: $path"
}
```

Then load all surfaces and assert these exact contract groups:

```powershell
$skill = Read-Utf8 'skills\fp-module-review\SKILL.md'
$command = Read-Utf8 'commands\fp-module-review.md'
$finding = Read-Utf8 'skills\fp-module-review\finding-template.md'
$summary = Read-Utf8 'skills\fp-module-review\summary-template.md'
$progress = Read-Utf8 'skills\fp-module-review\progress-event-template.md'

Assert-Anchors $skill @(
    'SCOPING', 'BASELINING', 'REVIEWING', 'TRIAGING', 'WAITING_APPROVAL',
    'FIXING', 'VERIFYING', 'BLOCKED', 'COMPLETE_WITH_AWAITING', 'COMPLETE'
) 'lifecycle'
Assert-Anchors $skill @(
    'read-only for product source and existing tests', 'observable behavior',
    'explicitly approves its stable ID', 'RED', 'GREEN', 'adjacent regression',
    'SAFE', 'UNSAFE', 'UNKNOWN', 'must not run', 'review-only', 'resume'
) 'controller gates'
Assert-Anchors $finding @(
    'MR-FNNN', 'candidate', 'confirmed', 'awaiting-user-confirmation', 'approved',
    'fixed', 'rejected', 'blocked', 'Trigger', 'Wrong result', 'Rollback', 'Residual risk'
) 'finding owner'
Assert-Anchors $summary @(
    'COMPLETE_WITH_AWAITING', 'exact IDs', 'CANNOT_VERIFY', 'current HEAD', 'working tree'
) 'completion summary'
Assert-Anchors $progress @('append-only', 'State', 'HEAD', 'worktree', 'Next') 'resume evidence'
Assert-Anchors $command @('fp-module-review', 'large module', 'multiple related modules', 'does not replace `fp-final-review`') 'command checksum'
```

Add semantic negative fixtures that mutate `explicitly approves its stable ID`, `read-only for product source and existing tests`, and `COMPLETE_WITH_AWAITING`; each helper assertion must reject its mutation. End with:

```powershell
Write-Output 'Module review contract validation passed.'
```

- [ ] **Step 2: Run the focused validator and confirm RED**

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-module-review-contract.ps1
```

Expected: FAIL with `required surface is missing: commands\fp-module-review.md` (or the first missing module-review surface). Do not weaken the validator.

- [ ] **Step 3: Record the RED result without committing**

Record the exact failure in the session/task evidence. Do not run `git add` or `git commit`; commit authorization is absent.

---

### Task 2: Implement the module-review command, controller, and artifact templates

**Files:**
- Create: `commands/fp-module-review.md`
- Create: `skills/fp-module-review/SKILL.md`
- Create: `skills/fp-module-review/review-entry-template.md`
- Create: `skills/fp-module-review/scope-template.md`
- Create: `skills/fp-module-review/baseline-template.md`
- Create: `skills/fp-module-review/waves-template.md`
- Create: `skills/fp-module-review/finding-template.md`
- Create: `skills/fp-module-review/summary-template.md`
- Create: `skills/fp-module-review/progress-event-template.md`
- Test: `scripts/test-module-review-contract.ps1`

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md`, `${CLAUDE_PLUGIN_ROOT}/skills/_shared/codegraph.md`, project instructions, optional information layer, current source, tests, and Git state.
- Produces: `fp-docs/module-reviews/<slug>/` with canonical artifacts and a controlled review/fix lifecycle.

- [ ] **Step 1: Create the command checksum**

Create `commands/fp-module-review.md`:

```markdown
---
description: 对一个大型功能模块或多个相关模块执行证据驱动的专项审查与受控修复
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-module-review/SKILL.md`，将「$ARGUMENTS」作为输入；该 skill、模板和共享 workspace contract 是完整事实源。

Gate checksum：

- 只接受一个 large module 或 multiple related modules 的有界目标；不静默扩为全仓审查。
- REVIEWING/TRIAGING 对产品源码和既有测试保持只读；Finding 确认后才允许进入受控修复。
- 外部可观察行为或安全策略变化必须按稳定 Finding ID 明确批准。
- 每项修复必须保留 RED、GREEN、owner scope 和 adjacent regression 证据。
- 本 skill does not replace `fp-final-review`；归档前整分支终审仍使用后者。
```

- [ ] **Step 2: Create the controller skill**

Create `skills/fp-module-review/SKILL.md` with frontmatter:

```markdown
---
name: fp-module-review
description: Use when reviewing one large functional module or several related modules through a persistent evidence-driven workflow that may baseline contracts, record stable findings, gate observable behavior changes, apply approved minimal fixes, and verify convergence.
---
```

Its body must implement, in order:

1. anchored workspace resource failure behavior;
2. the exact Codex mapping sentence required by `validate-plugin.ps1`;
3. one-time reads of `workspace-rules.md` and `codegraph.md`;
4. purpose and non-overlap with `fp-final-review`;
5. inputs and deterministic slug/target resolution;
6. canonical workspace ownership;
7. exact lifecycle states and allowed transitions;
8. read-only phase boundaries;
9. scope inventory and baseline contracts;
10. wave partition and controller-owned ID allocation;
11. finding proof threshold/schema/transitions;
12. observable-behavior approval gate;
13. safe command classification;
14. TDD fixing loop and strict expected-failure limitation;
15. resume invalidation/recovery;
16. verification and exact completion predicates;
17. template lazy-load order and concise completion response.

Use these normative statements verbatim because the focused validator depends on them:

```markdown
`SCOPING`, `BASELINING`, `REVIEWING`, and `TRIAGING` are read-only for product source and existing tests.
```

```markdown
A production fix is authorized only when observable behavior impact is `none`, or the user explicitly approves its stable ID and proposed behavior.
```

```markdown
Only `SAFE` commands may run. `UNSAFE` and `UNKNOWN` commands must not run.
```

Keep `SKILL.md` below 500 lines by referring to the seven templates rather than embedding their schemas.

- [ ] **Step 3: Create the artifact templates with unique owners**

Create each template with exact headings:

`review-entry-template.md`:

```markdown
# Module Review: <slug>

## Current Status
## Quick Summary
## Canonical Artifact Manifest
| Order | File | Owner |
## Finding Counts
## Resume Entry
```

`scope-template.md`:

```markdown
# Scope
## Targets
## Direct Integration Points
## Review Dimensions
## Exclusions
## Fact Precedence
## Allowed Write Paths
## Protected Paths
## External-System Authorization
```

`baseline-template.md`:

```markdown
# Baseline
## Snapshot
## Observable Compatibility Contracts
## Existing Test Baseline
## Command Safety Ledger
| Command | Definition inspected | Class | Declared outputs | Result |
## Evidence Gaps
```

`waves-template.md`:

```markdown
# Review Waves
| Wave | Owned targets/integrations | Dimensions | Depends on | Status | Evidence |
## Candidate Reconciliation
```

`finding-template.md`:

```markdown
# MR-FNNN — <title>
- Wave:
- Evidence:
- Trigger:
- Wrong result or risk:
- Supplementary proof:
- Severity:
- Observable behavior impact:
- State:
- Disposition:
- Test mapping:
- RED:
- GREEN:
- Adjacent regression:
- Rollback:
- Residual risk:
```

`summary-template.md`:

```markdown
# Module Review Summary
## Scope Reconciliation
## Wave Reconciliation
## Finding Reconciliation
## Verification Commands
## Changed and Protected Paths
## Awaiting Approval
## Completion Status
## CANNOT_VERIFY Claims
## Delivery Boundaries
```

`progress-event-template.md` must state `This ledger is append-only recovery evidence and never owns Finding state.` and provide:

```markdown
## Event <timestamp>
- State:
- HEAD:
- Worktree fingerprint:
- Scope/config fingerprints:
- Wave/finding:
- Command/result:
- Changed/protected paths:
- Evidence freshness:
- Next:
```

- [ ] **Step 4: Run the module-review validator and confirm GREEN**

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-module-review-contract.ps1
```

Expected: `Module review contract validation passed.`

- [ ] **Step 5: Check skill size and whitespace**

Run:

```bash
powershell -NoProfile -Command "$n=(Get-Content 'skills/fp-module-review/SKILL.md').Count; if($n -gt 500){throw \"$n lines\"}; Write-Output \"$n lines\""
```

Expected: an integer at or below `500` followed by `lines`.

Run:

```bash
git diff --check -- commands/fp-module-review.md skills/fp-module-review scripts/test-module-review-contract.ps1
```

Expected: no whitespace errors.

---

### Task 3: Write the final-review rename contract and move the core surfaces

**Files:**
- Rename: `commands/fp-review.md` → `commands/fp-final-review.md`
- Rename: `skills/fp-review/` → `skills/fp-final-review/`
- Rename: `scripts/test-review-contract.ps1` → `scripts/test-final-review-contract.ps1`
- Modify: all renamed files
- Test: `scripts/test-final-review-contract.ps1`

**Interfaces:**
- Consumes: the current final-review behavior and focused semantic helpers without changing verdict, attempt, HEAD, scope-matrix, command-safety, or recovery semantics.
- Produces: the identical read-only final reviewer under the sole active identifier `fp-final-review`.

- [ ] **Step 1: Copy the focused contract to its new name and change expected paths/names before moving implementation**

Use a filesystem copy, then update the new file only:

```bash
cp scripts/test-review-contract.ps1 scripts/test-final-review-contract.ps1
```

In `scripts/test-final-review-contract.ps1`, replace active identifiers:

- error prefix `Review contract validation failed` → `Final review contract validation failed`;
- `dispatch fp-review` → `dispatch fp-final-review`;
- `skills\fp-review\` → `skills\fp-final-review\`;
- `commands\fp-review.md` → `commands\fp-final-review.md`;
- labels and messages `fp-review` → `fp-final-review`;
- validator anchor `test-review-contract.ps1` → `test-final-review-contract.ps1`;
- success output → `Final review contract validation passed.`.

Add path absence assertions:

```powershell
Assert-Condition (-not (Test-Path (Join-Path $root 'commands\fp-review.md'))) 'old fp-review command still exists'
Assert-Condition (-not (Test-Path (Join-Path $root 'skills\fp-review'))) 'old fp-review skill directory still exists'
Assert-Condition (-not (Test-Path (Join-Path $root 'scripts\test-review-contract.ps1'))) 'old review validator still exists'
```

- [ ] **Step 2: Run the renamed contract and confirm RED**

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-final-review-contract.ps1
```

Expected: FAIL because `skills\fp-final-review\SKILL.md` or `commands\fp-final-review.md` is missing.

- [ ] **Step 3: Move the command, skill directory, and remove the old validator**

Run:

```bash
git mv commands/fp-review.md commands/fp-final-review.md
```

Run:

```bash
git mv skills/fp-review skills/fp-final-review
```

Delete the old validator only after the renamed copy exists:

```bash
rm scripts/test-review-contract.ps1
```

- [ ] **Step 4: Update all moved runtime identities**

In `commands/fp-final-review.md`, change the plugin root to `${CLAUDE_PLUGIN_ROOT}/skills/fp-final-review/SKILL.md` and change the checksum label/wording to `fp-final-review` without altering read-only semantics.

In `skills/fp-final-review/SKILL.md`:

- set frontmatter `name: fp-final-review`;
- change self references from `fp-review` to `fp-final-review`;
- change both `${CLAUDE_PLUGIN_ROOT}/skills/fp-review/...` anchors to `skills/fp-final-review/...`.

In all three companion templates, change active `fp-review` identity references to `fp-final-review` and the phrase `artifact-layout contract already loaded by` accordingly. Do not change report headings, verdicts, schema, attempts, or HEAD semantics.

- [ ] **Step 5: Run the renamed focused contract to expose integration references**

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-final-review-contract.ps1
```

Expected: FAIL at the global-validator anchor or SDD dispatch order because integration files still say `fp-review`. This is the intended RED for Task 4; all required renamed core paths must already exist.

---

### Task 4: Migrate final-review orchestrators and cross-contract consumers

**Files:**
- Modify: `skills/fp-start/SKILL.md`
- Modify: `commands/fp-start.md`
- Modify: `skills/fp-execute/SKILL.md`
- Modify: `skills/fp-execute-sdd/SKILL.md`
- Modify: `skills/fp-brainstorm/SKILL.md`
- Modify: `skills/_shared/codegraph.md`
- Modify: `scripts/test-figma-evidence-contract.ps1`
- Modify: `scripts/test-init-information-layer-contract.ps1`
- Modify: `scripts/measure-context.ps1`
- Test: `scripts/test-final-review-contract.ps1`
- Test: `scripts/test-figma-evidence-contract.ps1`
- Test: `scripts/test-init-information-layer-contract.ps1`

**Interfaces:**
- Consumes: renamed final-review core surfaces from Task 3.
- Produces: every active workflow dispatches/loads `fp-final-review`; CodeGraph guidance covers both final and module review without changing candidate-only semantics.

- [ ] **Step 1: Replace final-review runtime names in orchestrators**

Perform bounded replacements only in the listed files:

- `fp-review` → `fp-final-review`;
- `skills/fp-review/` → `skills/fp-final-review/`;
- `commands/fp-review.md` → `commands/fp-final-review.md`.

In `skills/fp-execute-sdd/SKILL.md`, preserve the required order string as:

```text
capture reviewedTargetHead → generate the final package → evidence-only commit → resolve evidenceCommitHead → dispatch fp-final-review
```

Do not alter attempt limits, evidence commit logic, or phase recovery.

- [ ] **Step 2: Extend the shared CodeGraph contract for module review**

Keep the renamed final-review paragraph and add:

```markdown
在 `fp-module-review` 中，CodeGraph 也只用于 target integration、wave ownership、caller/import/reference 和影响范围候选。任何候选 Finding、缺失关系或修复完成结论都必须由 current source、native search、tests 或 command output 复核；源码写入后遵守 `dirty-after-write`，返回前仅对已有图执行一次 `post-write-sync`，失败不阻塞主流程。
```

- [ ] **Step 3: Update cross-contract path readers and labels**

In `scripts/test-figma-evidence-contract.ps1` and `scripts/test-init-information-layer-contract.ps1`, update only the final-review path and label strings. Preserve all semantic assertions.

In `scripts/measure-context.ps1`, update paths to `fp-final-review` and rename the measurement key from `Review` to `FinalReview`; do not change other measured bundles.

- [ ] **Step 4: Run the focused final-review contract to GREEN**

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-final-review-contract.ps1
```

Expected: `Final review contract validation passed.`

- [ ] **Step 5: Run the affected cross-contract validators**

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-init-information-layer-contract.ps1
```

Expected: its existing success message and exit code `0`.

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-figma-evidence-contract.ps1
```

Expected: its existing success message and exit code `0`.

---

### Task 5: Integrate validators without overwriting concurrent coverage work

**Files:**
- Modify: `scripts/validate-plugin.ps1`
- Test: `scripts/test-module-review-contract.ps1`
- Test: `scripts/test-final-review-contract.ps1`
- Test: `scripts/test-coverage-contract.ps1`
- Test: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: both new focused validators and the concurrent coverage validator already registered in the latest file.
- Produces: global plugin validation that fails if either review contract regresses.

- [ ] **Step 1: Re-read and fingerprint the concurrent validator before editing**

Run:

```bash
git diff -- scripts/validate-plugin.ps1
```

Expected: coverage integration is visible and preserved. Specifically retain the `test-coverage-contract.ps1` block.

- [ ] **Step 2: Add module and renamed final review focused invocations**

Replace only the old review block with:

```powershell
$moduleReviewContractValidator = Join-Path $root 'scripts\test-module-review-contract.ps1'
Assert-Condition (Test-Path $moduleReviewContractValidator) 'focused fp-module-review contract validator is missing'
& powershell -NoProfile -ExecutionPolicy Bypass -File $moduleReviewContractValidator
Assert-Condition ($LASTEXITCODE -eq 0) 'focused fp-module-review contract validator failed'

$finalReviewContractValidator = Join-Path $root 'scripts\test-final-review-contract.ps1'
Assert-Condition (Test-Path $finalReviewContractValidator) 'focused fp-final-review contract validator is missing'
& powershell -NoProfile -ExecutionPolicy Bypass -File $finalReviewContractValidator
Assert-Condition ($LASTEXITCODE -eq 0) 'focused fp-final-review contract validator failed'
```

Update every remaining final-review expected map, path, label, anchor, consumer list, and message in `validate-plugin.ps1` from old name/path to `fp-final-review`. Add a module-review skill contract entry:

```powershell
'fp-module-review' = @('large functional module', 'COMPLETE_WITH_AWAITING', 'awaiting-user-confirmation', 'review-entry-template.md')
```

Add template anchor checks for all seven module-review templates, and preserve every coverage-specific line from the pre-edit diff.

- [ ] **Step 3: Add active old-name rejection**

Build a bounded scan over active plugin/runtime surfaces, excluding `docs/superpowers/specs/**` and `docs/superpowers/plans/**`, and fail on `fp-review`, `skills/fp-review`, `commands/fp-review`, or `test-review-contract.ps1`. Include commands, skills, scripts, README, AGENTS, user guide, and release notes. The failure message must print the offending relative path.

- [ ] **Step 4: Run all three focused contracts**

Run each separately:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-module-review-contract.ps1
```

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-final-review-contract.ps1
```

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-coverage-contract.ps1
```

Expected: all exit `0` with their success messages.

- [ ] **Step 5: Run global validation and use failures as the RED list for Task 6**

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
```

Expected at this stage: FAIL only on user-facing old-name references or missing new documentation registrations. Any coverage failure means the shared edit overwrote concurrent work and must be restored before continuing.

---

### Task 6: Update user-facing documentation and complete old-name migration

**Files:**
- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `docs/user_guide/init-prd-start.md`
- Modify: `docs/release_notes/1.0.0.md`
- Test: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: final command names and responsibilities.
- Produces: discoverable user guidance with separate “module专项审查” and “归档前最终审查” entries and no active old identifier.

- [ ] **Step 1: Re-read concurrent documentation diffs before editing**

Run:

```bash
git diff -- AGENTS.md README.md
```

Expected: current `fp-coverage` additions are visible. Preserve them byte-for-byte except unavoidable neighboring table formatting.

- [ ] **Step 2: Update command/skill tables and workflow prose**

Apply these exact concepts:

- `AGENTS.md`: replace `Final review | skills/fp-review/SKILL.md` with `Final whole-branch review | skills/fp-final-review/SKILL.md`; add `Large or multi-module review | skills/fp-module-review/SKILL.md`.
- `README.md`: add `commands/fp-module-review.md | 大型或多模块专项审查、Finding 门禁与受控修复`; rename the final command row to `commands/fp-final-review.md | 归档前最终整分支只读审查`; change workflow references to `fp-final-review`; add a concise distinction paragraph.
- `docs/user_guide/init-prd-start.md`: rename final-review steps and add a standalone module-review usage section explaining it is not automatically part of `fp-start`.
- `docs/release_notes/1.0.0.md`: describe the final-review rename and new module-review workflow in current release notes; do not claim unrun validation.

Use this distinction consistently:

```markdown
- `fp-module-review`：针对一个大型功能模块或多个相关模块的持续专项审查，可在 Finding 门禁下执行受控修复。
- `fp-final-review`：FeaturePilot 变更归档或合并前的最终整分支只读审查。
```

- [ ] **Step 3: Scan active surfaces for old names**

Run:

```bash
git grep -n -E 'fp-review|skills[/\\]fp-review|commands[/\\]fp-review|test-review-contract' -- ':!docs/superpowers/specs/**' ':!docs/superpowers/plans/**'
```

Expected: no output. If output remains, classify it before editing; active runtime or user guidance must migrate, while this approved design/plan is intentionally excluded migration history.

- [ ] **Step 4: Run global plugin validation to GREEN**

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
```

Expected: final output reports plugin validation passed and every focused contract exits `0`.

---

### Task 7: Pressure-test the new skill and verify the complete change

**Files:**
- Modify if pressure tests expose a contract gap: `skills/fp-module-review/SKILL.md`
- Modify if pressure tests expose a schema gap: `skills/fp-module-review/*.md`
- Modify corresponding assertion first: `scripts/test-module-review-contract.ps1`
- Test: all changed files and validators

**Interfaces:**
- Consumes: finished module-review and final-review surfaces.
- Produces: evidence that the new skill resists scope expansion, unauthorized behavior changes, weak findings, unsafe commands, stale resume evidence, and false completion.

- [ ] **Step 1: Invoke the skill against five adversarial text fixtures without editing a consumer repository**

Use fresh read-only agents or direct skill reasoning for these fixtures:

1. targets absent and two plausible modules;
2. candidate supported only by CodeGraph, with current source contradicting it;
3. confirmed security-policy change without Finding-ID approval;
4. baseline command wrapper with unknown side effects;
5. resumed workspace whose HEAD/worktree differs from the last progress event.

Expected dispositions:

1. request one bounded target choice and do not broaden to the repository;
2. reject or keep candidate unconfirmed;
3. `WAITING_APPROVAL`, no production edit;
4. `UNKNOWN`, command must not run;
5. invalidate affected evidence and return to the earliest necessary state.

- [ ] **Step 2: Add a failing focused assertion before any pressure-test fix**

For each observed gap, add one exact anchor or semantic helper mutation to `scripts/test-module-review-contract.ps1`, run it to confirm FAIL, then apply the minimum skill/template wording fix and rerun to PASS. If all five fixtures already conform, make no edits.

- [ ] **Step 3: Run final focused validation**

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-module-review-contract.ps1
```

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-final-review-contract.ps1
```

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-coverage-contract.ps1
```

Expected: all pass.

- [ ] **Step 4: Run full validation and whitespace checks**

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
```

Expected: pass.

Run:

```bash
git diff --check
```

Expected: no whitespace errors; existing line-ending warnings may be reported separately but are not called passes if the command exits non-zero.

- [ ] **Step 5: Review final Git scope and concurrent-file preservation**

Run:

```bash
git status --short
```

Run:

```bash
git diff --stat
```

Run:

```bash
git diff -- AGENTS.md README.md scripts/validate-plugin.ps1
```

Expected:

- module-review files are new;
- final-review paths show renames rather than deletion plus unrelated rewrite where Git can detect them;
- coverage skill/command/contract/design/plan remain present;
- coverage additions in the three shared files remain intact;
- no unrelated implementation files changed.

- [ ] **Step 6: Report without committing**

Report created/renamed files, focused/global validator results, pressure-test outcomes, old-name scan result, concurrent coverage preservation, and any skipped verification. Do not commit because the user has not authorized Git commits.

---

## Plan Self-Review

- Spec coverage: every design section maps to Tasks 1–7: packaging, workspace ownership, lifecycle, safety, Finding states, approval gates, TDD fixing, expected-failure restrictions, resume, completion, rename, documentation, and validation.
- Placeholder scan: no unresolved markers or unspecified test steps remain.
- Name consistency: new identities are exactly `fp-module-review`, `fp-final-review`, `test-module-review-contract.ps1`, and `test-final-review-contract.ps1`; workspace root is exactly `fp-docs/module-reviews/<slug>/`; Finding IDs are exactly `MR-FNNN`.
- Scope consistency: `fp-module-review` is not wired into `fp-start`; `fp-final-review` replaces the old final-review identity everywhere active.
- Concurrent-change safety: Task 5 and Task 6 explicitly re-read and preserve current `fp-coverage` edits before touching shared files.
