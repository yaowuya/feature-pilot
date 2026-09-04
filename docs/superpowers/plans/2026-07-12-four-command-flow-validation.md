# FeaturePilot Four-Command Flow Validation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run `fp-init`, `fp-prd`, `fp-start`, and `fp-quick` to their natural code-generation endpoints against `cw-auto-ops`, preserve auditable evidence, and fix any confirmed FeaturePilot defects at their root cause.

**Architecture:** Use the live `feature-pilot` source through Claude Code's `--plugin-dir` option and persist one resumable Claude session per flow. A small evidence runner stores every raw JSON response, rendered response, and session ID under the target project; external git checks verify write gates independently of the model. The full flow uses a bounded Prometheus-label parsing requirement, while the quick flow uses a backward-compatible endpoint spelling fix.

**Tech Stack:** Claude Code CLI 2.1.207, FeaturePilot Markdown commands/skills, PowerShell 7/Windows PowerShell, Git, Django/DRF, Vue 2.7, existing PowerShell plugin validators.

## Global Constraints

- Keep `D:\01-code\feature-pilot` on its current `dev/1.0/zrf` branch.
- Create and switch only `D:\02-canway\01-code\cw-auto-ops` to `dev/1.0/ai` from its current clean `dev/1.0/zrf` commit.
- Retain all generated `fp-docs`, evidence, and business-code changes in `cw-auto-ops` for review.
- Do not commit or push either repository.
- Do not run `cw-auto-ops` tests, lint, build, migrations, services, browser checks, dependency installation, or report scripts.
- Run FeaturePilot's own `scripts/validate-plugin.ps1` before and after any plugin-source fix.
- Treat generated business code as unverified; this plan validates plugin flow and artifact behavior, not runtime correctness of `cw-auto-ops`.
- Never read or copy secrets; specifically avoid `config/settings/bkrepo.py`.
- Use narrow source searches because the target contains `.venv`, `node_modules`, generated static assets, and more than 80,000 paths.
- Do not weaken requirement confirmation, execution confirmation, overwrite protection, or risk-selection gates to reduce ceremony.

---

## File Structure

### Files created in `cw-auto-ops`

- `fp-e2e-evidence/claude-settings.json` — denies all Bash inside child Claude sessions so the generated flows cannot run target-project tests/builds.
- `fp-e2e-evidence/run-turn.ps1` — starts or resumes a named flow and records its response and session ID.
- `fp-e2e-evidence/flow-report.md` — human-readable observations, gate results, defects, and final scope disclaimer.
- `fp-e2e-evidence/<flow>-session.txt` — persisted Claude session ID for `init`, `prd`, `start`, and `quick`.
- `fp-e2e-evidence/<flow>-turn-NN.json` — raw Claude JSON result for each turn.
- `fp-e2e-evidence/<flow>-turn-NN.md` — assistant response text extracted from the same turn.
- `fp-docs/**` — normal artifacts produced by `fp-init`, `fp-prd`, and `fp-start`.

### Expected business files touched by the full flow

- `apps/check_app/service/metric_debug/parser.py` — parse quoted Prometheus label values while preserving current unquoted behavior.
- `tests/check_app/test_check_metric_debug_service.py` — generated focused cases may be added by the plugin, but they are not run in this validation.

### Expected business files touched by the quick flow

- `apps/check_app/views/check_metric_view.py` — add a correctly spelled DRF action while retaining the typoed compatibility action.
- `ui/src/modules/check-app/api/metric.js` — use the correctly spelled endpoint in the frontend wrapper.
- A focused existing test file may be modified if the plugin finds one; it remains unexecuted.

### Plugin files modified only if a defect is confirmed

- `commands/fp-init.md`, `commands/fp-prd.md`, `commands/fp-start.md`, or `commands/fp-quick.md` — only when the root cause is in the thin command adapter.
- `skills/fp-init/SKILL.md`, `skills/fp-prd/SKILL.md`, `skills/fp-start/SKILL.md`, or `skills/fp-quick/SKILL.md` — only when the root cause is command-specific workflow behavior.
- `skills/_shared/workspace-rules.md`, `skills/_shared/artifact-layout.md`, or `skills/fp-explore/SKILL.md` — only when evidence proves the defect is shared.
- `scripts/validate-plugin.ps1`, `scripts/test-explore-contract.ps1`, or `scripts/test-artifact-layout.ps1` — minimal regression coverage at the same contract layer as the root cause.

---

### Task 1: Establish the isolated target branch and plugin baseline

**Files:**
- Inspect: `D:\01-code\feature-pilot\scripts\validate-plugin.ps1`
- Create later in this task: `D:\02-canway\01-code\cw-auto-ops\fp-e2e-evidence\*`

**Interfaces:**
- Consumes: clean target worktree at commit `f7e92459f6732b74521f78f6797cfec29d2f858d`; plugin source on `dev/1.0/zrf`.
- Produces: target branch `dev/1.0/ai`, passing plugin baseline, and a recorded pre-flow status.

- [ ] **Step 1: Reconfirm both worktrees before changing branches**

Run:

```bash
git -C 'D:/01-code/feature-pilot' status --short --branch
git -C 'D:/02-canway/01-code/cw-auto-ops' status --short --branch
git -C 'D:/02-canway/01-code/cw-auto-ops' rev-parse HEAD
```

Expected:

```text
feature-pilot: branch dev/1.0/zrf; only the approved uncommitted design/plan documents may be present
cw-auto-ops: branch dev/1.0/zrf with no changed files
cw-auto-ops HEAD: f7e92459f6732b74521f78f6797cfec29d2f858d
```

If `cw-auto-ops` is dirty, stop and report the exact paths; do not switch or discard anything.

- [ ] **Step 2: Create the requested target test branch**

Run:

```bash
git -C 'D:/02-canway/01-code/cw-auto-ops' switch -c dev/1.0/ai
```

Expected: `Switched to a new branch 'dev/1.0/ai'`.

- [ ] **Step 3: Run the plugin's static baseline**

Run from `D:\01-code\feature-pilot`:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './scripts/validate-plugin.ps1'
```

Expected:

```text
FeaturePilot fp-explore contract validation passed.
FeaturePilot plugin validation passed: 10 commands, 19 skills, ...
```

- [ ] **Step 4: Record the exact baseline without committing**

Run:

```bash
git -C 'D:/02-canway/01-code/cw-auto-ops' status --short --branch
git -C 'D:/01-code/feature-pilot' status --short --branch
```

Expected: target branch is `dev/1.0/ai`; no target files have been created yet. Do not commit.

---

### Task 2: Build the reproducible multi-turn evidence runner

**Files:**
- Create: `D:\02-canway\01-code\cw-auto-ops\fp-e2e-evidence\claude-settings.json`
- Create: `D:\02-canway\01-code\cw-auto-ops\fp-e2e-evidence\run-turn.ps1`
- Create: `D:\02-canway\01-code\cw-auto-ops\fp-e2e-evidence\flow-report.md`

**Interfaces:**
- Consumes: a flow name in `{init, prd, start, quick}`, a prompt string, and optional `-New`.
- Produces: `<flow>-session.txt`, `<flow>-turn-NN.json`, `<flow>-turn-NN.md`; exits nonzero if Claude returns invalid JSON or no session ID.

- [ ] **Step 1: Create settings that prohibit target-project command execution**

Write `fp-e2e-evidence/claude-settings.json`:

```json
{
  "permissions": {
    "deny": [
      "Bash"
    ]
  }
}
```

This allows file exploration and code generation while making tests, builds, migrations, service startup, and dependency installation impossible inside the child flow.

- [ ] **Step 2: Create the session runner**

Write `fp-e2e-evidence/run-turn.ps1`:

```powershell
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("init", "prd", "start", "quick")]
    [string]$Flow,

    [Parameter(Mandatory = $true)]
    [string]$Prompt,

    [switch]$New
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$PluginRoot = "D:\01-code\feature-pilot"
$SettingsPath = Join-Path $PSScriptRoot "claude-settings.json"
$SessionPath = Join-Path $PSScriptRoot "$Flow-session.txt"

Remove-Item Env:CLAUDECODE -ErrorAction SilentlyContinue
Remove-Item Env:CLAUDE_CODE_ENTRYPOINT -ErrorAction SilentlyContinue

if ((Get-Location).Path -ne $ProjectRoot) {
    Set-Location $ProjectRoot
}

$turnCount = @(Get-ChildItem -Path $PSScriptRoot -Filter "$Flow-turn-*.json" -ErrorAction SilentlyContinue).Count
$turnNumber = $turnCount + 1
$turnStem = Join-Path $PSScriptRoot ("{0}-turn-{1:D2}" -f $Flow, $turnNumber)

$claudeArgs = @(
    "--print",
    "--plugin-dir", $PluginRoot,
    "--permission-mode", "acceptEdits",
    "--settings", $SettingsPath,
    "--output-format", "json"
)

if ($New) {
    if (Test-Path $SessionPath) {
        throw "Flow '$Flow' already has a session file: $SessionPath"
    }
} else {
    if (-not (Test-Path $SessionPath)) {
        throw "Flow '$Flow' has no session file. Start it with -New."
    }
    $sessionId = (Get-Content -Raw $SessionPath).Trim()
    $claudeArgs += @("--resume", $sessionId)
}

$claudeArgs += $Prompt
$rawLines = & claude @claudeArgs 2>&1
$exitCode = $LASTEXITCODE
$raw = ($rawLines -join [Environment]::NewLine)
Set-Content -Path "$turnStem.json" -Value $raw -Encoding UTF8

if ($exitCode -ne 0) {
    throw "Claude exited with code $exitCode. See $turnStem.json"
}

try {
    $result = $raw | ConvertFrom-Json
} catch {
    throw "Claude output is not valid JSON. See $turnStem.json"
}

if (-not $result.session_id) {
    throw "Claude JSON did not contain session_id. See $turnStem.json"
}

if ($New) {
    Set-Content -Path $SessionPath -Value $result.session_id -Encoding ASCII
} elseif ($result.session_id -ne $sessionId) {
    throw "Resumed flow returned a different session ID. See $turnStem.json"
}

Set-Content -Path "$turnStem.md" -Value ([string]$result.result) -Encoding UTF8
Write-Output "$turnStem.md"
```

- [ ] **Step 3: Create the flow report skeleton**

Write `fp-e2e-evidence/flow-report.md`:

```markdown
# FeaturePilot Four-Command Flow Report

## Scope

- Plugin source: `D:\01-code\feature-pilot`
- Target project: `D:\02-canway\01-code\cw-auto-ops`
- Target branch: `dev/1.0/ai`
- Target tests/build/lint/services: intentionally not run
- Business-code correctness: not asserted

## Baseline

- Plugin validator before flows: PASS
- Target start commit: `f7e92459f6732b74521f78f6797cfec29d2f858d`

## fp-init

| Check | Result | Evidence |
|---|---|---|
| Correct project-root skeleton | Not run | |
| Canway/CW consent gate | Not run | |
| Optional settings flow | Not run | |
| Lightweight intel flow | Not run | |
| Re-run overwrite safety | Not run | |

## fp-prd

| Check | Result | Evidence |
|---|---|---|
| Existing-product exploration | Not run | |
| Bucket A/B review | Not run | |
| Bucket C one question per turn | Not run | |
| No PRD write before summary approval | Not run | |
| Canonical PRD and required next step | Not run | |

## fp-start

| Check | Result | Evidence |
|---|---|---|
| Reuses resolved PRD | Not run | |
| Proposal gate | Not run | |
| Design gate and single finalizer | Not run | |
| Plan gate and no early business mutation | Not run | |
| Explicit execution-mode choice | Not run | |
| Code generation and final review | Not run | |

## fp-quick

| Check | Result | Evidence |
|---|---|---|
| Focused exploration | Not run | |
| Inline plan and no early mutation | Not run | |
| No new FeaturePilot change directory | Not run | |
| Code generation | Not run | |

## Findings

| ID | Severity | Flow | Actual | Expected | Root cause | Resolution |
|---|---|---|---|---|---|---|

## Final Validation

- Plugin validator after flows/fixes: Not run
- Unverified target-project risks: generated code was not executed or tested
```

- [ ] **Step 4: Verify the runner rejects resume without a session**

Run from `cw-auto-ops`:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow init -Prompt '继续'
```

Expected: nonzero exit with `Flow 'init' has no session file. Start it with -New.` No Claude request is sent.

- [ ] **Step 5: Check the harness-only diff**

Run:

```bash
git status --short
git diff --check
```

Expected: only `fp-e2e-evidence/` is new and `git diff --check` prints nothing. Do not commit.

---

### Task 3: Run and audit `fp-init`, including overwrite safety

**Files:**
- Create/modify through plugin: `fp-docs/manifest.md`
- Create/modify through plugin: `fp-docs/settings/agent.md`
- Create/modify through plugin: `fp-docs/settings/frontend.md`
- Create/modify through plugin: `fp-docs/settings/backend.md`
- Create/modify through plugin: `fp-docs/settings/prototype-style.md`
- Create/modify through plugin: `fp-docs/intel/*.md`
- Modify manually for evidence only: `fp-e2e-evidence/flow-report.md`

**Interfaces:**
- Consumes: `/fp-init` and explicit choices to adopt Canway/CW examples, generate all optional settings, and generate lightweight intel.
- Produces: initialized information layer with no `changes`, `archive`, or `history`, plus re-run evidence that existing files are not overwritten without consent.

- [ ] **Step 1: Start the real init command**

Run from `cw-auto-ops`:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow init -New -Prompt '/fp-init'
```

Expected: `fp-e2e-evidence/init-turn-01.md` exists. The response either asks the first consent question or reports skeleton creation before asking; it must not create `fp-docs/changes`, `fp-docs/archive`, or `fp-docs/history`.

- [ ] **Step 2: Record the first gate's filesystem boundary**

Run:

```bash
git status --short
```

Expected: only evidence plus allowed init-owned `fp-docs/manifest.md`, `fp-docs/settings/`, and `fp-docs/intel/` paths. Record exact paths in the report.

- [ ] **Step 3: Approve project-family examples when offered**

Resume with this exact answer when the Canway/CW adoption question appears:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow init -Prompt '确认采用 Canway/CW 项目族示例。只复制与当前仓库源码事实一致的设置；不确定项保留 Unknown，不读取 secrets。'
```

Expected: the same session ID is retained, and the response proceeds to optional settings or another required consent gate.

- [ ] **Step 4: Generate each optional setting without authorizing overwrites**

For each optional settings question, resume with the matching exact answer:

```text
生成 agent.md；保持轻量，只引用现有项目文档，不复制前后端细节。
生成 frontend.md；依据当前 Vue 2.7 与 Canway 代码事实，不确定项写 Unknown。
生成 backend.md；依据当前 Django/DRF 分层事实，不确定项写 Unknown。
生成 prototype-style.md；只依据现有前端视觉事实，不确定项写 Unknown。
```

Run one `run-turn.ps1 -Flow init -Prompt '<matching answer>'` call per question. Expected: one decision is processed per turn when the workflow asks separately; no unrelated change artifacts appear.

- [ ] **Step 5: Approve lightweight discovery**

Run when prompted:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow init -Prompt '选择 1，生成轻量 intel。只读扫描，不安装依赖、不运行测试或构建、不读取 secrets。'
```

Expected: init reaches its final report and recommends `/fp-prd <idea>` and `/fp-start <slug or feature description>`.

- [ ] **Step 6: Validate init-owned paths and content boundaries**

Run:

```bash
test -f fp-docs/manifest.md
test -f fp-docs/intel/unknowns-and-decisions.md
test -f fp-docs/intel/refresh-policy.md
test -f fp-docs/intel/sdd-handoff.md
test ! -e fp-docs/changes
test ! -e fp-docs/archive
test ! -e fp-docs/history
git diff --check
```

Expected: all commands exit zero. Inspect `manifest.md` and confirm it references `.claude/CLAUDE.md` rather than duplicating it.

- [ ] **Step 7: Start a separate re-run session against existing files**

Run:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow init -Prompt '/fp-init 再次检查现有 FeaturePilot 信息层；未经我明确批准不得覆盖任何现有文件。'
```

Expected: because this is the same command session, it inspects existing files and asks before any overwrite/refresh action; it must not silently replace them.

- [ ] **Step 8: Decline every overwrite/refresh action and finish**

Resume with:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow init -Prompt '不覆盖、不刷新任何现有 manifest、settings 或 intel；仅报告当前状态并结束。'
```

Expected: no existing init file content changes after this turn. Confirm with `git diff --stat` before and after, and mark each init report row PASS/FAIL with turn-file evidence.

---

### Task 4: Run `fp-prd` through a real interview and canonical write

**Files:**
- Create through plugin: `fp-docs/changes/prometheus-label-parser/prd.md` or `fp-docs/changes/prometheus-label-parser/prd/00-index.md` plus listed fragments
- Modify manually for evidence only: `fp-e2e-evidence/flow-report.md`

**Interfaces:**
- Consumes: existing parser facts from `apps/check_app/service/metric_debug/parser.py` and tests from `tests/check_app/test_check_metric_debug_service.py`.
- Produces: one canonical PRD for slug `prometheus-label-parser`, with no prototype, covering quoted/unquoted Prometheus labels and compatibility boundaries.

- [ ] **Step 1: Capture the no-PRD baseline**

Run:

```bash
test ! -e fp-docs/changes/prometheus-label-parser
git status --short
```

Expected: the candidate change directory does not exist.

- [ ] **Step 2: Start `fp-prd` with a bounded existing-product request**

Run:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow prd -New -Prompt '/fp-prd 为自动巡检的标准输出指标调试支持真实 Prometheus 标签语法。当前 cpu_usage{bk_host_id=1} 88 可解析；需要支持 cpu_usage{bk_host_id="1",mount="/data"} 88，并保持未加引号格式兼容。忽略 # HELP、# TYPE、空行和畸形注释行，不改变非标准自定义输出路径。请按正常访谈门禁生成 PRD，不生成原型。'
```

Expected: the response reports code-fact exploration and begins Bucket A/B review or asks the first Bucket C question. It must not write the candidate PRD directory.

- [ ] **Step 3: Verify the pre-confirmation write gate after every interview turn**

After every PRD turn before the final summary approval, run:

```bash
test ! -e fp-docs/changes/prometheus-label-parser
```

Expected: exit zero. Any directory or PRD written before summary approval is a P1 defect.

- [ ] **Step 4: Confirm the Bucket A/B batch without expanding scope**

When the batch review appears, resume with:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow prd -Prompt '确认 Bucket A/B，补充边界：仅标准输出解析；非标准 custom 路径不变；不做前端页面、数据迁移或外部服务变更；不需要 prototype。继续逐个询问 Bucket C。'
```

Expected: the next response contains at most one substantive Bucket C question.

- [ ] **Step 5: Answer Bucket C one question per turn using the approved decision table**

Use the exact matching answer for each question, one runner call per response:

| Decision | Exact answer |
|---|---|
| Primary user/value | `主要用户是配置和调试巡检指标的运维工程师；目标是让真实 Prometheus 标准输出可以直接完成调试解析。` |
| Quoted label behavior | `双引号只作为标签值定界符，写入 dimensions 时去掉外层双引号；多个标签按逗号分隔并保留各自字符串值。` |
| Compatibility | `必须继续支持现有未加引号格式 cpu_usage{bk_host_id=1} 88；非标准 custom 输出解析完全不变。` |
| Invalid/comment lines | `# HELP、# TYPE、空行和无法解析的注释或畸形行应被安全忽略，不得导致整次调试崩溃。` |
| Acceptance evidence | `验收以聚焦单元测试用例为准：quoted 多标签、unquoted 兼容、注释/空行/畸形行安全忽略、custom 路径不变。` |

Expected for each non-final answer: the next response asks at most one substantive question. Record the number of Bucket C turns; more than five without a concrete missing decision is a P2 finding.

- [ ] **Step 6: Approve the final summary and fixed slug**

When the final confirmation summary appears, resume with:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow prd -Prompt '确认摘要。slug 使用 prometheus-label-parser；按你选择的 canonical form 写入。不得生成 prototype、proposal、design、tasks 或业务代码。'
```

Expected: exactly one PRD canonical form is written and the response ends with `/fp-start prometheus-label-parser`.

- [ ] **Step 7: Validate the PRD artifact and ownership boundary**

Run from `feature-pilot`:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './scripts/validate-artifact-layout.ps1' -ChangeRoot 'D:\02-canway\01-code\cw-auto-ops\fp-docs\changes\prometheus-label-parser'
```

Expected: validation passes. Then run in `cw-auto-ops`:

```bash
test ! -e fp-docs/changes/prometheus-label-parser/proposal.md
test ! -e fp-docs/changes/prometheus-label-parser/proposal
test ! -e fp-docs/changes/prometheus-label-parser/design
test ! -e fp-docs/changes/prometheus-label-parser/tasks
git diff --check
```

Expected: all commands exit zero. Mark PRD checks PASS/FAIL with exact turn and artifact paths.

---

### Task 5: Run `fp-start` through proposal, design, plan, direct execution, and review

**Files:**
- Create through plugin: `fp-docs/changes/prometheus-label-parser/proposal.md` or split proposal form
- Create through plugin: `fp-docs/changes/prometheus-label-parser/design/00-index.md` and backend design form
- Create through plugin: `fp-docs/changes/prometheus-label-parser/tasks/plan-backend.md` or split backend plan form
- Modify through plugin: `apps/check_app/service/metric_debug/parser.py`
- Modify through plugin: `tests/check_app/test_check_metric_debug_service.py`
- Create through plugin as applicable: `fp-docs/changes/prometheus-label-parser/.fp-execute/**`
- Modify manually for evidence only: `fp-e2e-evidence/flow-report.md`

**Interfaces:**
- Consumes: resolved PRD for `prometheus-label-parser`.
- Produces: proposal, backend design, backend plan, explicit direct-execution selection, generated parser/test changes, and final review report without running tests.

- [ ] **Step 1: Start the full flow from the exact slug**

Run:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow start -New -Prompt '/fp-start prometheus-label-parser。完整复用已确认 PRD。允许生成文档、实现代码和测试代码，但本轮禁止运行目标项目的测试、lint、构建、迁移、服务或安装命令；所有未执行验证必须如实报告为风险。'
```

Expected: it resolves the existing PRD, performs start-routing exploration, stays on full flow, and enters proposal work without recreating the PRD interview.

- [ ] **Step 2: Answer only genuine proposal blockers**

If a proposal question appears, answer with:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow start -Prompt '保持 PRD 最小范围：只调整标准输出 parser 并补聚焦测试代码；不改 custom provider、不改 API 和前端、不引入依赖。其余技术细节遵循现有相邻模式。'
```

Expected: proposal is written and the response asks for explicit proposal confirmation.

- [ ] **Step 3: Confirm the proposal gate**

Before confirmation, verify business files are unchanged:

```bash
git diff --quiet -- apps/check_app/service/metric_debug/parser.py tests/check_app/test_check_metric_debug_service.py
```

Expected: exit zero. Then resume:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow start -Prompt '确认 proposal，进入设计阶段。'
```

Expected: response enters one `fp-brainstorm` design flow.

- [ ] **Step 4: Resolve design questions without broadening architecture**

For a design decision prompt, resume with:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow start -Prompt '采用最小后端方案：在现有 parser 内解析 quoted/unquoted label pairs，复用当前 provider 调用边界，不增加依赖、不改变 custom 输出路径。测试沿用现有 metric debug service 测试文件。'
```

Expected: the same design context writes and verifies `design/00-index.md` plus backend design, then asks for post-write design confirmation. It must not run a second design-finalizer workflow.

- [ ] **Step 5: Confirm the design gate**

Run:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow start -Prompt '确认设计，进入计划阶段。'
```

Expected: it loads `fp-plan`, produces only a backend plan, and asks for explicit plan confirmation. There must be no frontend plan or single-end `tasks/00-overview.md`.

- [ ] **Step 6: Validate the plan before allowing execution**

Run:

```bash
test -e fp-docs/changes/prometheus-label-parser/tasks/plan-backend.md -o -e fp-docs/changes/prometheus-label-parser/tasks/backend/00-index.md
test ! -e fp-docs/changes/prometheus-label-parser/tasks/plan-frontend.md
test ! -e fp-docs/changes/prometheus-label-parser/tasks/frontend
test ! -e fp-docs/changes/prometheus-label-parser/tasks/00-overview.md
git diff --quiet -- apps/check_app/service/metric_debug/parser.py tests/check_app/test_check_metric_debug_service.py
```

Expected: all commands exit zero. A business-code diff before plan confirmation is P1.

- [ ] **Step 7: Confirm the plan and verify the execution-mode gate**

Resume:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow start -Prompt '确认计划，进入执行阶段。仍然禁止运行目标项目验证命令。'
```

Expected: the response explains Direct and SDD execution, their pause behavior and suitable scenarios, and waits for an explicit selection. It must not modify business files yet.

- [ ] **Step 8: Select direct execution explicitly**

Run:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow start -Prompt '选择 1：Direct task execution，automationMode=full。按已确认计划连续生成实现和测试代码；不要运行任何目标项目测试、lint、构建或服务命令，把这些验证标记为未执行。'
```

Expected: it loads `fp-execute`, reads task-owner files, performs pre-flight review, generates code, updates task ownership/progress, and continues to final review unless a genuine blocker appears.

- [ ] **Step 9: Handle only contract-consistent execution blockers**

If execution pauses solely because Bash is denied, resume with:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow start -Prompt '按本轮已确认范围继续：只生成代码并进行只读源码审查；目标项目命令验证明确跳过并记录为未验证风险，不得伪造通过。'
```

If it reports a plan conflict, unsafe code decision, or missing user-owned product decision, stop and record the blocker instead of authorizing scope expansion.

- [ ] **Step 10: Confirm completion and final review evidence**

Expected final response:

```text
- states generated capability and key files
- states target-project validation commands were not run
- does not claim tests passed
- includes final review result or unresolved findings
- suggests archive only after review criteria are satisfied
```

Run:

```bash
git diff -- apps/check_app/service/metric_debug/parser.py tests/check_app/test_check_metric_debug_service.py
git diff --check
```

Inspect only; do not execute tests. Run the artifact validator against the change root and mark all `fp-start` checks in the report.

---

### Task 6: Run `fp-quick` for a separate backward-compatible endpoint correction

**Files:**
- Modify through plugin: `apps/check_app/views/check_metric_view.py`
- Modify through plugin: `ui/src/modules/check-app/api/metric.js`
- May modify through plugin: one existing focused test file discovered by the quick flow
- Modify manually for evidence only: `fp-e2e-evidence/flow-report.md`

**Interfaces:**
- Consumes: typoed backend action `get_scrip_result` and frontend URL `/get_scrip_result/`.
- Produces: new `get_script_result` endpoint, retained old compatibility endpoint, frontend use of the corrected URL, and no new FeaturePilot change directory.

- [ ] **Step 1: Record the pre-quick change directories and business diff**

Run:

```bash
ls -1 fp-docs/changes > fp-e2e-evidence/quick-change-dirs-before.txt
git diff -- apps/check_app/views/check_metric_view.py ui/src/modules/check-app/api/metric.js > fp-e2e-evidence/quick-business-before.diff
```

Expected: baseline files are recorded; the quick target files have no changes from the earlier full flow.

- [ ] **Step 2: Start the real quick command**

Run:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow quick -New -Prompt '/fp-quick 修正指标调试结果接口拼写：新增 POST /check/metric/get_script_result/ 并复用当前服务逻辑；保留旧的 /get_scrip_result/ 兼容已有调用；前端 metric API wrapper 改用正确拼写。只做这个向后兼容的小改动。允许生成代码和必要测试代码，但禁止运行目标项目测试、lint、构建或服务。'
```

Expected: focused exploration identifies `check_metric_view.py` and `metric.js`, then either asks at most one blocker or presents an inline plan. It must not create a new change directory.

- [ ] **Step 3: Answer the only expected compatibility question if asked**

Resume with:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow quick -Prompt '保留旧 typo endpoint 作为兼容别名；新旧 endpoint 必须调用同一实现，前端只切到正确拼写；不改响应结构、权限、service 或其他 API。'
```

Expected: an inline plan follows; no business file has changed yet.

- [ ] **Step 4: Verify the quick confirmation gate and artifact boundary**

Run:

```bash
git diff --quiet -- apps/check_app/views/check_metric_view.py ui/src/modules/check-app/api/metric.js
ls -1 fp-docs/changes > fp-e2e-evidence/quick-change-dirs-preconfirm.txt
diff -u fp-e2e-evidence/quick-change-dirs-before.txt fp-e2e-evidence/quick-change-dirs-preconfirm.txt
```

Expected: all commands exit zero. Any target-file mutation or added change directory is P1.

- [ ] **Step 5: Approve the inline plan**

Run:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './fp-e2e-evidence/run-turn.ps1' -Flow quick -Prompt '确认内联计划，按最小向后兼容方案生成代码。不要运行目标项目验证命令；在最终报告中明确列出未执行验证。'
```

Expected: code is generated, no FeaturePilot proposal/design/tasks are created, and final response distinguishes generated code from unrun validation.

- [ ] **Step 6: Audit the quick diff without executing it**

Run:

```bash
git diff -- apps/check_app/views/check_metric_view.py ui/src/modules/check-app/api/metric.js
ls -1 fp-docs/changes > fp-e2e-evidence/quick-change-dirs-after.txt
diff -u fp-e2e-evidence/quick-change-dirs-before.txt fp-e2e-evidence/quick-change-dirs-after.txt
git diff --check
```

Expected:

```text
new backend action path is get_script_result
old get_scrip_result action remains
frontend wrapper calls get_script_result
change-directory listings are identical
git diff --check prints nothing
```

Do not run `pytest`, `node --check`, `npm`, lint, build, or service commands. Mark quick report rows PASS/FAIL.

---

### Task 7: Investigate and fix each confirmed plugin defect with a regression check

**Files:**
- Modify only the root-cause plugin Skill/command/shared contract file identified by evidence
- Modify the nearest existing validator: `scripts/validate-plugin.ps1`, `scripts/test-explore-contract.ps1`, or `scripts/test-artifact-layout.ps1`
- Modify: `D:\02-canway\01-code\cw-auto-ops\fp-e2e-evidence\flow-report.md`

**Interfaces:**
- Consumes: one report finding with exact turn file, workspace state, actual behavior, and expected contract.
- Produces: confirmed root cause, pre-fix failing regression, one minimal plugin fix, passing validator, and a clean rerun of the affected flow boundary.

- [ ] **Step 1: Triage findings by severity and avoid speculative fixes**

Use these exact definitions in the report:

```text
P1: wrong route/path, write before approval, skipped mandatory gate, illegal artifact, no explicit execution choice, failed resume, or quick/full boundary violation
P2: repeated confirmed question, unnecessary scan, more than five nonessential Bucket C turns, redundant finalizer, or ceremony not justified by risk
P3: unclear next step, incomplete status/path report, unsupported recommendation, or duplicated output
```

If no finding survives evidence review, skip Steps 2–7 and proceed to Task 8. Do not change plugin text merely to make the transcript more aesthetically pleasing.

- [ ] **Step 2: Trace one finding backward to its owner**

For one finding at a time, document:

```markdown
- Reproduction: exact `<flow>-turn-NN.md` and preceding user turn
- Filesystem before/after: exact `git status`/path evidence
- Expected contract: exact command/Skill/shared-contract path and line
- Data flow: command adapter → command Skill → shared rule/explore profile → write or response
- Root-cause hypothesis: one owner and one violated condition
```

Do not propose a fix until the transcript and source jointly prove the owner.

- [ ] **Step 3: Add the smallest deterministic failing regression**

Choose exactly one test layer:

```text
command/Skill gate text or ownership defect → scripts/validate-plugin.ps1
shared explore invocation/caller responsibility defect → scripts/test-explore-contract.ps1
canonical artifact production/consumption defect → scripts/test-artifact-layout.ps1
```

The assertion must target the missing or contradictory contract condition demonstrated by the transcript, not the model's prose wording. Run only that plugin validator and confirm it fails for the demonstrated reason.

- [ ] **Step 4: Make one root-cause change**

Edit only the owning command/Skill/shared file. Preserve thin command adapters, one-question PRD behavior, explicit stage and execution gates, quick-flow no-artifact behavior, and canonical artifact rules. Do not bundle unrelated wording cleanup.

- [ ] **Step 5: Verify the focused and full plugin validators**

Run the focused script selected in Step 3, then:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './scripts/validate-plugin.ps1'
```

Expected: focused regression passes and full output ends with `FeaturePilot plugin validation passed`.

- [ ] **Step 6: Rerun the affected E2E boundary in a fresh flow session**

Archive the affected session evidence by renaming its session and turn files with `-pre-fix`, then invoke the same initial command with `-New` and replay only the turns necessary to reach the prior failure. Expected: the old failure no longer occurs and protected gates remain intact.

- [ ] **Step 7: Stop after three failed fixes to the same issue**

If three minimal root-cause attempts fail, make no fourth patch. Record `architecture review required`, explain the coupling revealed by each attempt, and ask the user before redesigning the workflow.

Repeat Tasks 7.2–7.7 independently for each confirmed defect.

---

### Task 8: Complete the evidence report and final plugin verification

**Files:**
- Modify: `D:\02-canway\01-code\cw-auto-ops\fp-e2e-evidence\flow-report.md`
- Inspect: all target changes and FeaturePilot changes

**Interfaces:**
- Consumes: all flow transcripts, artifacts, source diffs, and defect resolutions.
- Produces: final auditable report, passing plugin validation, retained target branch, and explicit unverified-risk statement.

- [ ] **Step 1: Replace every `Not run` report cell**

Each cell must become one of:

```text
PASS — with exact turn/artifact evidence
FAIL — with finding ID
NOT REACHED — with the blocking finding ID
```

Do not use a generic “works” statement.

- [ ] **Step 2: Record flow-efficiency observations**

For each flow, record:

```text
number of user turns
number of required confirmation gates
repeated questions, if any
evidence of broad/unrelated scanning, if any
whether upstream decisions were reused
whether final next step/status was clear
```

Classify only evidence-backed issues as P2/P3.

- [ ] **Step 3: Run final plugin validation**

Run from `feature-pilot`:

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File './scripts/validate-plugin.ps1'
git diff --check
git status --short --branch
```

Expected: validator passes, diff check is clean, branch remains `dev/1.0/zrf`, and only approved design/plan plus confirmed plugin fixes are present.

- [ ] **Step 4: Inspect final target status without testing business code**

Run from `cw-auto-ops`:

```bash
git status --short --branch
git diff --stat
git diff --check
```

Expected: branch is `dev/1.0/ai`; evidence, `fp-docs`, and generated business-code changes remain; diff check passes.

- [ ] **Step 5: Write the final scope disclaimer verbatim**

End `flow-report.md` with:

```markdown
## Verification Boundary

The FeaturePilot command flows, confirmation gates, artifact boundaries, and code-generation behavior were exercised with the live plugin source. The generated `cw-auto-ops` business code was not executed: no target-project tests, lint, build, migrations, services, browser checks, or dependency installation ran. Therefore this report does not claim runtime correctness of the generated business changes; those changes remain on `dev/1.0/ai` for separate review and verification.
```

- [ ] **Step 6: Report results without committing or pushing**

Final response must list:

```text
four flow outcomes
generated artifact and business-code paths
confirmed defects and fixes
FeaturePilot validator result
all target-project validations intentionally skipped
residual risks
both repositories' final branches and dirty status
```

Do not commit, push, archive the FeaturePilot change, or clean the retained target artifacts.
