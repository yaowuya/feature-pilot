# Explicit Execution Mode Gates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Require users to choose direct execution versus SDD, then—only for SDD—choose step-confirmation versus automatic continuation with clearly explained effects.

**Architecture:** `fp-start` owns both user-facing selection gates and passes the chosen strategy/mode to exactly one execution skill. `fp-execute-sdd` owns SDD continuation semantics and persists the selected mode in its recovery ledger. `validate-plugin.ps1` protects the required choices, explanations, persistence, and automatic no-stop invariant.

**Tech Stack:** Markdown skill contracts, PowerShell validation (`scripts/validate-plugin.ps1`), Git diff validation.

## Global Constraints

- Never infer or auto-select SDD solely from plan size, complexity, module count, or risk.
- The assistant may recommend an execution option, but a recommendation is not user selection.
- Gate 2 is shown only after the user explicitly selects SDD.
- Each option must explain execution behavior, pause behavior, and suitable use cases.
- Automatic SDD retains every per-task implementation, review, fix, checkbox, and ledger gate.
- In automatic SDD, a clean task boundary is progress, not a return point; continue until all tasks and final review complete unless genuinely blocked.
- Persist the selected strategy and SDD continuation mode in `.fp-execute/progress.md`; reuse it on resume and never switch silently.
- Do not alter artifact layout, TDD rules, reviewer rules, or final `fp-review` behavior.

---

## File Map

- Modify `scripts/validate-plugin.ps1`: add static regression assertions for the two gates and SDD continuation invariants.
- Modify `skills/fp-start/SKILL.md`: replace automatic executor selection with the two-level explicit user gate and clear option copy.
- Modify `skills/fp-execute-sdd/SKILL.md`: define `step-confirmation` and `automatic-continuation`, their loop/stop rules, ledger persistence, and resume behavior.
- Modify `commands/fp-start.md`: update the thin-adapter gate checksum so public command routing does not advertise automatic SDD preference.
- Reference `docs/superpowers/specs/2026-07-12-execution-mode-selection-design.md`: approved design; no further content changes required.

### Task 1: Protect the execution-selection contract with failing validation

**Files:**
- Modify: `scripts/validate-plugin.ps1` immediately after existing `$prdSkillText`/skill-specific assertions or near `$skillAnchors`
- Test: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: UTF-8 text from `skills/fp-start/SKILL.md`, `skills/fp-execute-sdd/SKILL.md`, and `commands/fp-start.md`.
- Produces: validation failures when either explicit gate, option explanation, persistence rule, or automatic-continuation invariant is missing.

- [ ] **Step 1: Add focused failing assertions**

Add exact anchors that require:

```powershell
$startSkillText = Read-Utf8 (Join-Path $root 'skills\fp-start\SKILL.md')
$sddSkillText = Read-Utf8 (Join-Path $root 'skills\fp-execute-sdd\SKILL.md')
$startCommandText = Read-Utf8 (Join-Path $root 'commands\fp-start.md')

foreach ($anchor in @(
    'Execution strategy gate'
    'Direct task execution (non-SDD)'
    'SDD execution'
    'recommendation is not selection'
    'wait for the user''s explicit choice'
    'SDD continuation mode gate'
    'Step-confirmation SDD'
    'Automatic-continuation SDD'
)) {
    Assert-Condition ($startSkillText.Contains($anchor)) "fp-start is missing explicit execution gate contract: $anchor"
}
Assert-Condition ($startSkillText.Contains('Ask this gate only after the user explicitly selects SDD')) 'fp-start must not ask the SDD continuation gate before SDD is selected'
Assert-Condition (-not ($startSkillText.Contains('根据计划规模选择执行 skill'))) 'fp-start must not auto-select an executor from plan size'

foreach ($anchor in @(
    'Step-confirmation SDD'
    'Automatic-continuation SDD'
    'progress updates, not return points'
    'immediately select and dispatch the next eligible task'
    'Execution strategy: SDD'
    'SDD continuation mode:'
    'Never silently switch modes'
)) {
    Assert-Condition ($sddSkillText.Contains($anchor)) "fp-execute-sdd is missing continuation contract: $anchor"
}

Assert-Condition ($startCommandText.Contains('必须由用户明确选择直接执行或 SDD')) 'fp-start command checksum is missing explicit executor selection'
Assert-Condition ($startCommandText.Contains('SDD 逐项确认或自动连续')) 'fp-start command checksum is missing SDD continuation selection'
```

- [ ] **Step 2: Run validation and confirm RED**

Run:

```bash
pwsh -NoProfile -File scripts/validate-plugin.ps1
```

Expected: FAIL on the first new missing gate anchor, demonstrating that current `fp-start` still auto-selects by plan size.

- [ ] **Step 3: Do not weaken assertions to fit current wording**

Confirm the failure is caused by absent behavior rather than a PowerShell syntax error. If syntax fails, repair only the test syntax and rerun until the failure says `fp-start is missing explicit execution gate contract` or equivalent.

### Task 2: Implement both user-facing gates in fp-start

**Files:**
- Modify: `skills/fp-start/SKILL.md:198-214`
- Modify: `commands/fp-start.md:8-14`
- Test: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: an approved plan and the user's explicit Gate 1 selection; Gate 2 consumes an explicit SDD selection.
- Produces: exactly one route—`fp-execute` for direct execution, or `fp-execute-sdd` with `step-confirmation`/`automatic-continuation`.

- [ ] **Step 1: Replace plan-size executor selection with Gate 1**

In `skills/fp-start/SKILL.md`, replace `根据计划规模选择执行 skill` and its two automatic-selection bullets with an `Execution strategy gate` requiring these explained choices:

```markdown
### Execution strategy gate

Before loading either execution skill, stop and ask the user to choose one option. You may recommend one with a concrete reason, but a recommendation is not selection; wait for the user's explicit choice.

1. **Direct task execution (non-SDD)** — Load `fp-execute` and implement the approved task-owner files directly in the current execution context. It does not create per-task SDD briefs, fresh implementers, review packages, or per-task reviewer agents. Continue through the task list and pause only for a blocking plan conflict, an unsafe/unrecoverable validation failure, or a decision only the user can make. Choose this for smaller plans or lower orchestration overhead.
2. **SDD execution** — Load `fp-execute-sdd`. Every task gets a fresh implementer, review package, read-only reviewer, and blocking-finding fix loop, providing stronger isolation, recovery evidence, and quality gates with more orchestration/artifacts. Choose this for medium/large, cross-module, permission/data-sensitive, migration, or UI-contract work.
```

State explicitly that task count and risk can influence a recommendation but never authorize selection.

- [ ] **Step 2: Add Gate 2 only inside the SDD branch**

Add:

```markdown
### SDD continuation mode gate

Ask this gate only after the user explicitly selects SDD. Explain and wait for one choice:

1. **Step-confirmation SDD** — Complete one task through implementation, review/fix, checkbox reconciliation, and ledger update; report its evidence and wait for explicit user confirmation before dispatching the next task. Choose this when the user wants to inspect each increment or control every task/commit boundary.
2. **Automatic-continuation SDD** — Run the same complete per-task SDD quality cycle, but after a clean task immediately continue to the next eligible task without asking. Per-task reports are progress updates, not return points. Continue through all tasks and final review; pause only for a genuine blocker, unresolved user decision, plan conflict, blocked implementation, or exhausted fix loop. Choose this for unattended execution without giving up SDD review rigor.
```

Then route the exact selected mode into `fp-execute-sdd`.

- [ ] **Step 3: Define direct execution continuation clearly**

Require the direct route to load `fp-execute` with `automationMode=full` unless the user explicitly asks for per-task confirmation. This keeps “直接执行 task，生成代码” from stopping after every task while preserving `fp-execute`'s existing `semi` option on explicit request.

- [ ] **Step 4: Update the command checksum**

Replace the current automatic-preference checksum in `commands/fp-start.md` with:

```markdown
- 执行前必须由用户明确选择直接执行或 SDD，不得仅根据任务规模自动选择；每个选项必须说明执行方式、暂停条件和适用场景。
- 仅当用户选择 SDD 后，再让用户选择 SDD 逐项确认或自动连续；自动连续模式在正常任务边界不得停住。
```

- [ ] **Step 5: Run validation to identify the remaining SDD failure**

Run:

```bash
pwsh -NoProfile -File scripts/validate-plugin.ps1
```

Expected: Gate 1/Gate 2 assertions for `fp-start` pass; validation still FAILS because `fp-execute-sdd` lacks the continuation mode contract.

### Task 3: Implement SDD continuation semantics and persistence

**Files:**
- Modify: `skills/fp-execute-sdd/SKILL.md:12-15,75-104,124-162,278-299`
- Test: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: `SDD continuation mode: step-confirmation | automatic-continuation` selected by the user through `fp-start`, or restored from `progress.md`.
- Produces: deterministic next-task behavior and persisted lines `Execution strategy: SDD` and `SDD continuation mode: <mode>`.

- [ ] **Step 1: Add the continuation mode input contract**

Near the core rule, require exactly one selected mode before task dispatch. If invoked directly without a recorded/explicit mode, show both explained options and wait; do not infer from plan size.

- [ ] **Step 2: Define Step-confirmation SDD**

Add a mode section requiring the controller to complete the entire current task cycle, synchronize checkbox/overview/ledger, report evidence, and then stop for explicit confirmation before selecting the next task. A response such as “继续” resumes the next eligible task without rerunning completed work.

- [ ] **Step 3: Define Automatic-continuation SDD**

Add a mode section with the exact invariant:

```markdown
After a task is reviewed clean and checkbox/overview/ledger state is synchronized, per-task reports are progress updates, not return points. Immediately select and dispatch the next eligible task in the same controller run. Do not ask “continue to the next task?” and do not return merely because one task completed. Continue until every task and final whole-change review completes, unless a genuine blocker requires user input.
```

List genuine blockers: preflight/plan conflict, unresolved product/architecture/security decision, implementer `BLOCKED`/`NEEDS_CONTEXT` requiring user input, or three failed fix attempts.

- [ ] **Step 4: Persist and restore selection**

Extend the minimum ledger format with:

```markdown
Execution strategy: SDD
SDD continuation mode: step-confirmation | automatic-continuation
```

Add resume rules:

- Explicit user selection and recorded mode must agree; if they conflict, ask whether to switch and record the decision.
- If a valid mode is recorded, reuse it without asking again.
- If mode is absent/ambiguous, ask Gate 2 before dispatch.
- Never silently switch modes.

- [ ] **Step 5: Make controller responsibilities mode-aware**

Change the generic next-task rule so clean completion branches by selected mode: stop for confirmation in `step-confirmation`; immediately continue in `automatic-continuation`. Blocking behavior remains identical.

- [ ] **Step 6: Make completion text mode-safe**

Clarify that only step-confirmation produces a per-task user confirmation prompt. Automatic mode may emit concise progress, but its user-facing final response occurs after all tasks and final review or at a genuine blocker.

- [ ] **Step 7: Run validation and confirm GREEN**

Run:

```bash
pwsh -NoProfile -File scripts/validate-plugin.ps1
```

Expected: PASS with the FeaturePilot plugin validation summary.

### Task 4: Verify the complete contract and focused diff

**Files:**
- Verify: `skills/fp-start/SKILL.md`
- Verify: `skills/fp-execute-sdd/SKILL.md`
- Verify: `commands/fp-start.md`
- Verify: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: final working tree.
- Produces: fresh evidence that the explicit gates and auto-continuation contract are present without unrelated changes.

- [ ] **Step 1: Run full validation and whitespace checks**

Run:

```bash
pwsh -NoProfile -File scripts/validate-plugin.ps1
git diff --check
```

Expected: plugin validation PASS and `git diff --check` exits 0. Line-ending warnings are informational; whitespace errors are not.

- [ ] **Step 2: Inspect the focused diff**

Run:

```bash
git diff -- scripts/validate-plugin.ps1 skills/fp-start/SKILL.md skills/fp-execute-sdd/SKILL.md commands/fp-start.md docs/superpowers/specs/2026-07-12-execution-mode-selection-design.md docs/superpowers/plans/2026-07-12-explicit-execution-mode-gates.md
```

Confirm all of the following from the diff:

- No plan-size auto-selection remains.
- Gate 1 explains direct and SDD effects.
- Gate 2 occurs only under SDD and explains both continuation effects.
- Automatic SDD cannot stop at a clean task boundary.
- The selected SDD mode persists and resumes.
- No unrelated skill behavior changed.

- [ ] **Step 3: Report verification without committing**

Report the RED failure observed before implementation, final PASS output, changed files, and any warnings. Do not commit unless the user explicitly requests it.

## Self-Review

- Spec coverage: Gate 1, Gate 2, option effects, pause semantics, suitability guidance, persistence, resume, no silent switching, and regression validation are all mapped to Tasks 1–4.
- Placeholder scan: no implementation placeholders remain; angle-bracket examples are not used as unspecified work.
- Interface consistency: `step-confirmation` and `automatic-continuation` are the only SDD mode identifiers throughout; ledger and routing use the same names.
