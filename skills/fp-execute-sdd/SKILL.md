---
name: fp-execute-sdd
description: Use when executing confirmed FeaturePilot implementation plans that need isolated task workers, fresh-context review, interruption recovery, or stricter quality gates than inline execution.
---
## FeaturePilot workspace and information layer

If any anchored plugin resource is missing or unreadable, stop, report the exact resource and an incomplete FeaturePilot installation/cache, and never search the consumer repository for `skills/**` or continue without it.
下文以 `${CLAUDE_PLUGIN_ROOT}/...` 表示 Claude Code 安装后的插件资源。在 Codex/Markdown 中，从 available-skill 元数据提供的当前技能入口映射同一个 `skills/...` 插件相对路径。两端都不得在消费者项目中搜索插件文件。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.
Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` once before resolving execution inputs; it is the normative layout and validation contract.
If `<project-root>/.codegraph/` exists, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/codegraph.md` once and preserve its write-invalidation contract across controller and workers.
---

# FeaturePilot Subagent-Driven Execute

`fp-execute-sdd` executes an approved FeaturePilot change with Subagent-Driven Development. The controller stays in charge of sequencing, ledger updates, packages, and user-facing decisions; fresh subagents do one implementation task or one review at a time.

Core rule: **implementers are serial, reviewers are per task, every review scope is capped, the unique task-owner checkbox owns planned completion, and the ledger is recovery evidence.**

## SDD Continuation Mode

Before dispatching the first implementer, exactly one SDD continuation mode must be selected explicitly by the user or restored from `progress.md`. Never infer the mode from task count, plan complexity, risk, or a recommendation. If this skill is invoked directly and no valid mode is recorded, explain both choices below and wait for the user's explicit selection.

### Step-confirmation SDD

Complete exactly one task through implementation, review and any fix loop, checkbox reconciliation, derived overview update when applicable, and ledger update. Then report the task's files, commits, validation, report/review paths, and risks, and wait for explicit user confirmation before selecting or dispatching the next task. When the user replies “继续” or otherwise confirms, resume with the next eligible task without repeating completed work.

Choose this mode when the user wants to inspect every increment or control each task/commit boundary.

### Automatic-continuation SDD

Run the same complete per-task implementation, bounded review/fix, checkbox, overview, and ledger cycle. After a task passes review or reaches attempt 3 with only non-blocking review debt, and checkbox/overview/ledger state is synchronized, per-task reports are progress updates, not return points. The controller must immediately select and dispatch the next eligible task in the same run. Do not ask “continue to the next task?” and do not return merely because one task completed. Continue until every task and the final whole-change review complete.

Pause only for a genuine blocker that requires user input: a pre-flight or plan conflict; an unresolved product, architecture, security, scope, or data-safety decision; implementer status `BLOCKED` or `NEEDS_CONTEXT` that cannot be resolved from approved artifacts; or a main-flow blocker remaining after review attempt 3. Choose this mode for unattended execution without giving up SDD review rigor.

This skill is self-contained. Use only the templates in this directory:

```text
skills/fp-execute-sdd/
  SKILL.md
  task-brief-template.md
  implementer-prompt.md
  task-reviewer-prompt.md
  fix-prompt.md
  review-package-template.md
```

## When to Use

Use this skill for confirmed FeaturePilot plans when:
- The change is medium/large, cross-module, cross-end, permission-sensitive, data-sensitive, or UI/visual-sensitive.
- The plan resolves to a small `tasks/plan-backend.md` / `tasks/plan-frontend.md` or a split `tasks/backend/00-index.md` / `tasks/frontend/00-index.md`, with explicit TDD steps in its task owners.
- You want fresh-context per-task implementation and review rather than one long inline context.
- You need recovery after compaction, restart, or a partially completed task chain.

Do not use it for:
- `fp-quick` changes.
- Unapproved proposal/design/plan.
- Plans whose tasks are too vague to brief and review independently.
- Parallel implementers writing the same worktree. This skill forbids parallel implementation in v1.

## Shared canonical artifact resolution

Before preflight, briefing, or task selection, use canonical-first Consumer resolution for the complete approved artifact graph:

1. Detect both alternatives before reading either: `prd.md` or `prd/00-index.md`; `proposal.md` or `proposal/00-index.md`; `design/backend.md` or `design/backend/00-index.md`; `design/frontend.md` or `design/frontend/00-index.md`; `tasks/plan-backend.md` or `tasks/backend/00-index.md`; and `tasks/plan-frontend.md` or `tasks/frontend/00-index.md`.
2. Producer output has one canonical form. This Consumer rejects every indexless split, historical path, and dual form as a structural conflict. There is no read-only compatibility; migration must finish before dispatch.
3. A split `00-index.md` is the sole canonical entry. Parse its manifest and read every listed fragment in exact manifest order; reject a missing/duplicate entry, duplicate owner, or unindexed fragment. Never infer order from entrypoint links, recursive globs, or filesystem order.
4. In split plans, only manifest Kind=`tasks` rows create `tasks`-kind task-owner files. Every stable ID and checkbox has one unique task owner. Reject checkboxes in indexes/context/interface/coverage/overview, duplicate IDs/checkboxes, missing references, and dependency cycles.
5. `tasks/00-overview.md` exists exactly when both backend and frontend plans exist. A single-end plan never has an overview. Only a valid two-end overview supplies cross-end edges and derived progress; recompute its totals from owner checkboxes.

Record resolved canonical entries, ordered fragments, task owners, and structural conflicts in every brief/package and in `progress.md`. Only when an end's split directory is absent may the Consumer read its small plan file; if both exist, stop before reading either.

## Inputs

Immediately read with tools:
- Complete resolved PRD/proposal logical content (`prd.md` or `prd/00-index.md`; `proposal.md` or `proposal/00-index.md`)
- Resolved complete design artifacts using the canonical-first rule above
- Complete resolved task files: each selected small file or split index plus its manifest-ordered task-owner fragments, and the two-end `tasks/00-overview.md` only when applicable
- Project constraints if present: `CLAUDE.md`, `.claude/CLAUDE.md`, `AGENTS.md`
- Existing `fp-docs/changes/<slug>/.fp-execute/progress.md`, if any

If no task-owner file exists, stop and report that execution cannot start without an approved plan.

## Information-layer preflight

Before creating any task brief or dispatching an implementer:

1. If `fp-docs/manifest.md` exists, read it first and follow its read order.
2. Assemble `dynamic task context` for the selected task from: manifest; relevant existing settings; optional `intel/project-facts.md`; current change PRD/proposal/design/task artifacts; current source/config; and CodeGraph/native-search candidates. Copy only relevant excerpts into the brief/package.
3. Record every absent optional source as `N/A`. A manifest-only workspace is valid; no settings/intel file is required, and `static handoff absence is not a blocker` by itself.
4. Check manifest-listed `intel/unknowns.md` and `intel/decisions.md` when directly relevant. During one-release compatibility, manifest-listed `unknowns-and-decisions.md`, `refresh-policy.md`, `sdd-handoff.md`, or older generated intel may be read as hints, never required current proof.
5. If no manifest exists, continue under the compatibility rule and record `N/A` in the ledger/brief.
6. If an actual unresolved Unknown from approved artifacts, current code, or relevant human-owned knowledge can change scope, interfaces, permissions, data safety, or UI acceptance, stop and request the missing decision. File absence alone is not an unresolved Unknown.
7. Re-validate every referenced current source/config path before using generated facts or CodeGraph candidates as evidence.

## State Directory

Create and maintain:

```text
fp-docs/changes/<slug>/.fp-execute/
  progress.md
  briefs/
  reports/
  reviews/
  packages/
```

Do not write execution state under `.git/`. Do not rely on chat memory for recovery.

## Controller Responsibilities

The controller must:
1. Run pre-flight plan review before dispatching any implementer.
2. Select exactly one next task.
3. Create a task brief file.
4. Dispatch exactly one implementer subagent for that task.
5. Wait for the implementer to finish.
6. Create a review package from the actual diff and report.
7. Dispatch exactly one read-only task reviewer.
8. Run the bounded serial review/fix state machine for Critical/Important findings, with no more than three reviews in the task review scope.
9. Update the unique owner checkbox, recompute derived overview progress counts only for a valid two-end overview, and record commit/commit-range evidence in the ledger only after review passes or attempt 3 leaves only non-blocking review debt.
10. After a task passes review or is accepted with non-blocking review debt at attempt 3, branch only by the selected mode: `step-confirmation` reports evidence and waits for explicit confirmation; `automatic-continuation` must immediately select and dispatch the next eligible task without returning at the task boundary.
11. Record information-layer preflight, relevant Unknowns, and any stale/missing references in the progress ledger and review package.

The dynamic context assembled here replaces the old static handoff gate; the exact brief/package sources are review evidence.

The controller must not implement product code inline except to repair orchestration artifacts such as a malformed brief/package. If implementation is needed, dispatch the implementer or fixer.

## Pre-flight Plan Review

Before any implementation subagent, scan every resolved stable/index/task-owner file for contradictions:

- Proposal/design/tasks agree on scope; out-of-scope work is not planned.
- `Global Constraints` exist and are concrete.
- Every task has `Files`, `Reasoning`, `Interfaces`, failure test, expected failure, minimal implementation, pass validation, and commit step.
- Every task has `Depends on` with existing stable task IDs; per-task and per-end dependencies are acyclic, and for two-end plans they agree with the cross-end overview.
- Backend plans have `Backend Interface Ledger` and `Coverage Matrix` consistent with tasks.
- Frontend page/component tasks have structure/state/style outlines appropriate to the target framework plus `Visual Checks`; tasks must follow the project’s existing frontend framework and script/state patterns.
- Backend/frontend contract names match exactly: URL, method, fields, enums, error shape, permissions, pagination/filter/sort semantics.
- No placeholders: `TBD`, `TODO`, `按需处理`, `类似上面`, `补充样式`, `run tests`, `Add appropriate error handling`, or equivalent vague instructions.
- No plan-mandated behavior that would obviously fail review: tests without assertions, hardcoded secrets, missing permission negative tests, unverified UI visual claims.
- Information-layer Unknowns that affect task safety are resolved or explicitly blocked before dispatch.

If conflicts exist, list all conflicts with file/line evidence and pause. Do not let implementers guess.

## Progress Ledger

`progress.md` is an append-only recovery/evidence log, not a second completion authority. Read it before selecting the next task; create it if absent.

Minimum format:

```markdown
# fp-execute-sdd progress

Change: <slug>
Execution strategy: SDD
SDD continuation mode: step-confirmation | automatic-continuation
Base SHA: <sha at execution start>
Plan files:
- <tasks/00-overview.md only for a two-end plan>
- <tasks/plan-backend.md OR tasks/backend/00-index.md plus manifest-ordered fragments>
- <tasks/plan-frontend.md OR tasks/frontend/00-index.md plus manifest-ordered fragments>

## Completed Evidence
- <task-id>; owner <task-owner-path>; checkbox reconciled; commits <base>..<head>; tests `<commands>`; review <review-path>

## In Progress
- None

## Blocked
- None

## Minor Findings
- None

## Review Debt
- None

## Final Review Scope
- reviewScopeId: N/A until final review starts
- reviewAttempt: 0
- maxReviewAttempts=3
- priorReviewPath: N/A
- priorFindingDispositions: N/A
- finalReviewPackage: .fp-execute/packages/final-review-package.md
- lastReviewedHead: N/A
- reviewedTargetHead: N/A until clean target checkpoint
- packageParentHead: N/A until package generation
- evidenceCommitHead: N/A until resolved externally after commit
- dispatchHead: N/A until reviewer dispatch
- reviewPhase: pending-dispatch | review-completed | result-committed | fixing | complete

## Events
- <ISO time> plan_review pass
- <ISO time> review_attempt scope=<reviewScopeId> task=<task-id> attempt=1/3 head=<sha> verdict=PASS critical=0 important=0 minor=0 review=<review-path>
```

Ledger rules:
- Persist `Execution strategy: SDD` and exactly one `SDD continuation mode:` value: `step-confirmation` or `automatic-continuation`.
- On resume, reuse a valid recorded mode without asking again. If no mode is recorded or it is ambiguous, explain both modes and ask before dispatching. If a new explicit selection conflicts with the recorded mode, ask whether to switch and append that decision before continuing. Never silently switch modes.
- The unique checkbox in the task-owner file is the planned completion state; ledger entries are recovery evidence and never override it.
- When both ends exist, `tasks/00-overview.md` progress counts are derived from owner checkboxes; recompute them on mismatch instead of treating them as another state source. Never create or expect it for a single-end plan.
- On any mismatch, inspect the owner file, commits, actual implementation, tests, and review evidence; reconcile both records before selecting, repeating, or declaring the task complete.
- Append an event for task start, implementer result, package creation, review result, fix attempt, blocked state, checkbox update, and final review.
- Append one `review_attempt` event after every review with `reviewScopeId`, scope/task, attempt, `reviewedTargetHead`, runtime `evidenceCommitHead`/`dispatchHead`, verdict, Critical/Important/Minor counts, review path, exact findings, and disposition. Counts alone are insufficient evidence.
- On resume, restore the recorded review attempt for each task review scope and final review scope. A different finding, reviewer, fixer, commit, session, compaction, or restart never resets that scope's counter.
- Persist one stable reviewScopeId per task/final scope before its attempt 1. A new reviewer, new commit, new session, or new finding never resets `reviewAttempt`; identity changes update evidence inside the same scope.
- Do not repeat a task already marked complete unless the user explicitly asks to reopen it.
- If a task is blocked, record blocker, attempted commands, current HEAD, report/review paths, and the exact decision needed.
- If attempt 3 leaves only non-blocking findings, record them under `Review Debt`, reconcile the owner checkbox, and prevent task selection from reopening the task automatically.

## Task ID and File Naming

Use the stable task ID written in the unique checkbox marker; never derive or renumber it from a fragment filename:

```text
backend-001
frontend-003
```

Write all task artifacts:

```text
.fp-execute/briefs/<task-id>-brief.md
.fp-execute/reports/<task-id>-report.md
.fp-execute/packages/<task-id>-review-package.md
.fp-execute/reviews/<task-id>-review.md
```

Use `-fix-<n>` sections inside the same report for fix attempts; do not scatter fix evidence across unnamed files.

## Visual Evidence Contract

For every frontend/UI task with planned visual cases, carry the same case-level Visual Evidence Manifest through the plan, task brief, implementer report, review package, task review, progress evidence, final package, and final review. The standard case root is `.fp-execute/visual/<task-id>/<case-id>/`; it contains `manifest.md`, `reference.png`, `current.png`, and optional `diff.png`.

Each Case ID records Approved design source/Figma node plus revision/time, Frame/variant, available variables / Auto Layout / assets, Runtime route, Scenario/state, Viewport, DPR, Locale, Theme, Deterministic non-sensitive fixture, Reference path, Current path, Diff path, Mask, Acceptance rule, Command/tool, and Failure class. Fixtures contain no secrets or production/customer data.

`reference.png` must come from an approved Figma/static design source; a local runtime screenshot must not replace it. `current.png` must come from the real target runtime and runtime route with stable data and stable environment. The optional diff may be absent only with a missing diff explanation and must not hide absent core source/runtime evidence. Browser interaction evidence is separate from screenshot evidence and must exercise the approved states.

Use the project-configured browser runner/tool and inspected replay command. Never hard-code a framework, runner, storage root, URL, or global pixel threshold, and never silently install dependencies. A missing runner requires an explicit planned task and authorization. Code Connect is optional enhancement only; never auto-create `.figma.ts`, alter tsconfig, or install dependencies.

Core visual acceptance without trustworthy source or trustworthy runtime evidence is `CANNOT_VERIFY` and a main-flow blocker. Missing evidence must not become review debt. At attempt 3 only reproducible non-core cosmetic differences may become review debt; core visual evidence gaps remain blocked.

Provenance: reference.png -> approved Figma/static design source; current.png -> real target runtime.
Local runtime screenshot must not replace reference.png. current.png requires stable data and stable environment. Optional diff/missing diff explanation must not hide absent core source/runtime evidence.
Evidence channels: browser interaction evidence is separate from screenshot evidence; browser interaction evidence must exercise approved states, and screenshot evidence must record case artifacts.

## Task Brief Package

Before dispatching an implementer, write a brief using `${CLAUDE_PLUGIN_ROOT}/skills/fp-execute-sdd/task-brief-template.md`. It must include:
- Task ID, unique task-owner path, declared dependencies, task heading, and task checkbox text.
- Full task text from the plan, not a summary.
- Applicable `Global Constraints`.
- Relevant proposal/design excerpts.
- Relevant prior interface outputs from completed tasks.
- Exact allowed file paths from the plan.
- Required TDD commands and expected failure/pass evidence.
- Required commit behavior.
- Explicit scope exclusions.
- For every planned visual case, the complete Visual Evidence Manifest row, replay command/tool, source/runtime provenance, and expected evidence paths.

The implementer receives the brief path, not the full controller chat.

## Implementer Dispatch

Use `${CLAUDE_PLUGIN_ROOT}/skills/fp-execute-sdd/implementer-prompt.md` for each task.

Rules:
- One fresh implementer subagent per task.
- **No parallel implementers.** Dispatch the next implementer only after the current task is implemented, reviewed, fixed if needed, ledgered, and either completed or blocked.
- The implementer may edit files, run tests, and commit only the current task.
- The implementer must write the full report to `.fp-execute/reports/<task-id>-report.md`.
- For a visual task, the implementer must write each case `manifest.md` and report case-level reference/current/optional diff provenance plus separate browser interaction evidence.
- The implementer final chat response must be short: status, commits, tests, report path, concerns.

Allowed implementer statuses:
- `DONE`: implemented, validated, committed, no known concerns.
- `DONE_WITH_CONCERNS`: implemented but has non-blocking uncertainty for reviewer/controller.
- `NEEDS_CONTEXT`: cannot proceed because brief/plan is incomplete or contradictory.
- `BLOCKED`: tried and cannot complete without user/project decision.

## Review Package

After `DONE` or `DONE_WITH_CONCERNS`, create a package using `${CLAUDE_PLUGIN_ROOT}/skills/fp-execute-sdd/review-package-template.md`:
- brief path
- implementer report path
- base/head SHA for this task
- commit list
- diff stat
- full diff with context
- test command evidence
- case-level Visual Evidence Manifest, source/runtime provenance, replay command, artifact paths, and browser interaction evidence
- controller notes and known concerns

Write it to `.fp-execute/packages/<task-id>-review-package.md`. Do not paste large diffs into chat.

## Per-task Reviewer

Use `${CLAUDE_PLUGIN_ROOT}/skills/fp-execute-sdd/task-reviewer-prompt.md` for a fresh read-only reviewer after every implemented task.

Reviewer must verify two gates:
1. **Spec Compliance:** task brief, interfaces, constraints, visual checks, and validation evidence.
2. **Code Quality:** correctness bugs, contract bugs, test adequacy, maintainability, scope creep, production readiness.

For frontend/UI tasks the reviewer also emits exactly `Visual evidence: PASS | FAIL | CANNOT_VERIFY`, verifies every planned case against its manifest and real artifacts, and keeps browser interaction evidence separate from screenshot evidence.

Reviewer output goes to `.fp-execute/reviews/<task-id>-review.md` and must include:
- `Spec Compliance: PASS | FAIL | CANNOT VERIFY FROM DIFF`
- `Code Quality: APPROVED | NEEDS FIXES`
- Critical / Important / Minor findings with file:line evidence
- Test evidence assessment
- Interface/contract assessment
- `Ready for next task: YES | NO`
- `Visual evidence: PASS | FAIL | CANNOT_VERIFY`

Reviewer rules:
- Read-only only. No edits, no commits, no index changes, no generated artifacts.
- Do not suppress findings because the plan asked for bad behavior. Report plan-mandated defects as plan-mandated.
- `CANNOT VERIFY FROM DIFF` is not a pass. The controller must inspect the relevant files/evidence and either resolve it or treat it as failed.
- The reviewer reports finding severity and main-flow impact evidence; the controller owns continuation and blocker classification and must not rely only on `Ready for next task`.
- Missing core visual source/runtime evidence is `CANNOT_VERIFY`, never PASS and never review debt.

## Fix Loop

Each task review scope has a maximum of three reviews. The initial review is attempt 1. A failed attempt 1 or 2 may dispatch one fresh serial fixer followed by the next review. After failed attempt 3, the controller must not dispatch a fourth review or another automatic fixer.

### Visual review decision table

| Rule ID | Planned visual scope | Core source/runtime | Visual evidence verdict | Attempt | Reproducible non-core cosmetic FAIL | Disposition | Combined PASS eligible |
| --- | --- | --- | --- | --- | --- | --- | --- |
| NO_VISUAL | no | N/A | N/A | N/A | N/A | N/A | N/A |
| CORE_GAP | yes | missing | any | 1..3 | any | BLOCKER | no |
| VISUAL_PASS | yes | trustworthy | PASS | 1..3 | N/A | ELIGIBLE | yes |
| RETRY_NONPASS | yes | trustworthy | FAIL or CANNOT_VERIFY | 1..2 | N/A | NON_PASS | no |
| ATTEMPT3_COSMETIC | yes | trustworthy | FAIL | 3 | yes | DEBT | no |
| ATTEMPT3_OTHER_FAIL | yes | trustworthy | FAIL | 3 | no | BLOCKER | no |
| ATTEMPT3_OTHER_CANNOT_VERIFY | yes | trustworthy | CANNOT_VERIFY | 3 | N/A | BLOCKER | no |

Apply exactly one Rule ID to every task review. The table is mutually exclusive and exhaustive; no prose exception is permitted.

## Visual decision application

Combined task review verdict is PASS only when Spec Compliance is PASS, Code Quality is APPROVED, no Critical/Important finding remains, and every planned visual scope resolves to VISUAL_PASS. A planned visual FAIL or CANNOT_VERIFY cannot merge into PASS merely because severity buckets are empty. CORE_GAP is always a main-flow blocker. Minor findings may be recorded without making the combined verdict fail. Any other combination is non-pass and must follow the Rule ID table.

Task non-pass transition table:
- **Critical/Important finding:** append exact findings; at attempt 1 or 2 use the serial fixer flow below, regenerate the package, increment exactly once, and re-review.
- **Evidence-only failure:** for `CANNOT VERIFY FROM DIFF` without a Critical/Important code finding, append the exact missing evidence, repair the code, review package, or missing evidence as applicable, regenerate the package, increment exactly once, and dispatch the next reviewer. Use a fixer only when source or test changes are required.
- **Visual evidence decision:** apply exactly one Rule ID. RETRY_NONPASS at attempt 1/2 repairs or recollects the exact case evidence and consumes the next attempt. CORE_GAP, ATTEMPT3_OTHER_FAIL, and ATTEMPT3_OTHER_CANNOT_VERIFY are BLOCKER outcomes. Only ATTEMPT3_COSMETIC records review debt.
- **Schema-inconsistent result:** `NEEDS FIXES` with only Minor findings, or `Spec Compliance: FAIL` with no severity-bucket finding, is invalid reviewer output. Append the raw verdict and findings, normalize the brief/package/reviewer evidence, regenerate the package, increment exactly once, and dispatch a corrected fresh reviewer without a fixer unless inspection proves a code change is required.
- **Malformed or unclassified combination:** append the raw verdict and all available evidence, inspect the brief/diff/package to classify the actual defect, repair or normalize the responsible code/package/reviewer input, regenerate as applicable, increment exactly once, and dispatch a corrected fresh reviewer. Never invent PASS or reuse the same attempt.

Every non-pass result at attempt 1 or 2 must transition through exactly one table row to the next attempt only when that row is RETRY_NONPASS. BLOCKER outcomes stop and wait for the required user decision. The controller must not repeat the same attempt, accept the task prematurely, or defer a non-pass as review debt before attempt 3. At attempt 3, only ATTEMPT3_COSMETIC is review debt; every other non-pass visual Rule ID remains BLOCKER and never dispatches a fourth review.

For attempt 1 or 2 with any Critical or Important finding:
1. Append a ledger `review_attempt` event with the exact findings, counts, review path, and failed disposition.
2. Dispatch one fresh serial fixer with `${CLAUDE_PLUGIN_ROOT}/skills/fp-execute-sdd/fix-prompt.md` for only those findings.
3. Fixer reads the brief, report, package, review, and exact findings; edits only files needed for them; runs required tests; commits when appropriate; and appends a numbered fix section to the same report.
4. Controller regenerates the review package from the new diff/HEAD.
5. Increment the same scope's attempt and dispatch one fresh read-only reviewer with the same task-reviewer template.

At failed attempt 3, record every remaining finding and classify it with evidence. For a planned visual scope, only ATTEMPT3_COSMETIC may be review debt; every other non-pass Rule ID is BLOCKER. For non-visual findings, if no finding is a main-flow blocker, record review debt, reconcile the task-owner checkbox, and continue according to the selected continuation mode. If any finding is a main-flow blocker, record BLOCKED, leave the checkbox unchecked, and pause for the exact user decision required.

A finding is a main-flow blocker when any of these observable conditions holds:
- It is Critical, including data loss, a security issue, permission bypass, destructive production behavior, or migration risk that can corrupt data.
- The approved core acceptance behavior is unavailable or the task has not delivered its primary goal.
- A required build, core test, or required alternative validation fails, leaving this delivery unusable or preventing reliable downstream work.
- An external API, field, route, event, permission action, or other declared interface contract is broken and blocks a dependent task.
- Fixing it requires changing approved proposal/design/plan scope.
- Fixing it requires a product, architecture, security, permission, or data-safety decision absent from the brief.

CANNOT VERIFY FROM DIFF is a failed attempt. This generic evidence-only route never reclassifies a planned visual result; planned visual cases use exactly one Rule ID. At attempt 3 for non-visual findings, classify whether the missing evidence meets a main-flow blocker condition. Important or Minor findings that meet none of the conditions become review debt; record each with review path, classification rationale, and whether deferred or fixed. The controller must restore the recorded review attempt after interruption and must not reset it for a new finding, reviewer, fixer, commit, session, compaction, or restart.

## Model Selection

Every dispatch states a capability expectation, not a guessed model ID. Use the user/project-configured default unless policy explicitly selects another available model.

- Use the highest available reasoning/capability tier for controller decisions, uncertain or cross-end work, permissions/security/data/migrations, complex UI, task review, fixes for blocking findings, and final review.
- A balanced tier may implement a well-scoped routine task only when user/project policy permits it.
- A lightweight tier is limited to trivial read-only or mechanical work when policy permits it.
- Never silently downgrade for cost, invent model IDs, or claim an unavailable model. If exact selection is unsupported, put the capability expectation in the prompt.

## Completion and Final Review

After every task has either passed review or reached attempt 3 with only recorded non-blocking review debt:
1. Ensure every completed task's unique owner checkbox is checked and no summary/index file contains a task checkbox.
2. Ensure ledger has no unresolved `BLOCKED` or main-flow blocker; every other unresolved finding must appear under `Review Debt`.
3. Ensure Minor findings are fixed or explicitly deferred.
4. Before final attempt 1, create and persist one opaque stable reviewScopeId from immutable scope identity (change slug plus execution-start Base SHA and a ledger nonce); never derive it from HEAD, reviewer, session, or finding. Initialize `reviewAttempt=1`, `maxReviewAttempts=3`, `priorReviewPath=N/A`, `priorFindingDispositions=N/A`, and `lastReviewedHead=N/A`.
5. Run the clean-snapshot checkpoint before consuming each final review attempt: reconcile and commit authorized implementation and execution artifacts, including owner checkboxes, valid overview progress, prior ledger/brief/report/package/review evidence; never absorb unrelated user changes. Verify `git status --short` is empty. A failed clean-snapshot checkpoint does not consume a review attempt. When clean, capture reviewedTargetHead from HEAD; this is the committed product/change snapshot actually reviewed, and its target dirty fingerprint is `CLEAN`.
6. Set `reviewPhase=pending-dispatch` and `packageParentHead=reviewedTargetHead`, then generate the final package at `finalReviewPackage=.fp-execute/packages/final-review-package.md` using `${CLAUDE_PLUGIN_ROOT}/skills/fp-review/final-review-package-template.md`. Embed the target/base/ranges, complete branch inventory/counts, Scope Matrix, safety/CodeGraph/validation evidence, and literal `POST_COMMIT_EXTERNAL` sentinels for `evidenceCommitHead` and `dispatchHead`; append only the pending ledger event that uses the same sentinels. The package is deterministic evidence, not completion authority.
7. Create exactly one evidence-only commit whose diff from reviewedTargetHead contains only the final package and allowed pending ledger evidence. No product source, task checkbox, overview, requirement, design, plan, or prior evidence rewrite is permitted. The commit's parent must equal packageParentHead=reviewedTargetHead.
8. After that commit, resolve evidenceCommitHead from current HEAD outside the package, set `dispatchHead=evidenceCommitHead`, and verify `evidenceCommitHead=dispatchHead=current HEAD`. Run `git rev-parse <dispatchHead>^`, `git rev-list --count <packageParentHead>..<dispatchHead>`, and `git diff --name-only <packageParentHead>..<dispatchHead>`; require `dispatchHead^ == packageParentHead`, `rev-list --count packageParentHead..dispatchHead == 1`, only allowed package/pending-ledger paths, product source unchanged, and tree CLEAN. Because exact post-commit SHA is external state, never rewrite the package or pending event to insert it.
9. fp-review is required for final review scope. Then dispatch fp-review with `reviewScopeId`, `reviewAttempt`, `maxReviewAttempts=3`, `priorReviewPath`, `priorFindingDispositions`, `finalReviewPackage`, `lastReviewedHead`, `reviewedTargetHead`, `packageParentHead`, runtime `evidenceCommitHead`, runtime `dispatchHead`, and `reviewPhase=pending-dispatch`; headRef resolves to reviewedTargetHead. If fp-review is unavailable, record `BLOCKED` and repair/reinstall FeaturePilot instead of substituting the task-schema reviewer.
10. When fp-review returns, set `reviewPhase=review-completed`: historical dispatchHead remains the current committed HEAD and only final report/result-ledger paths may be uncommitted. Reject any other dirty path, then persist the result before advancing. Write `reviewPhase=result-committed` into the result ledger event as the post-commit recovery state. The result commit records the prior dispatchHead, verdict, report, dispositions, and runtime evidence; it does not record its own SHA; then commit the final review report and ledger evidence without rerunning review. Externally resolve the new current HEAD and set the same phase in controller state. No commit self-reference occurs.
11. Final verdict mapping: `PASS` ends the scope successfully. `PASS_WITH_NOTES` ends the final review scope with non-blocking review debt and requires every note to be recorded. `FAIL` is a failed final review attempt. `BLOCKED` is a main-flow blocker and pauses without another automatic fixer/reviewer until its missing decision or unsafe prerequisite is resolved.
   A final `BLOCKED` verdict consumes its current attempt. After its prerequisite is resolved, restore that completed attempt: when it is below 3, run the clean-snapshot checkpoint, increment exactly once before the next final review, and continue; at attempt 3, remain `BLOCKED` because the same scope cannot review again. Only explicit user authorization may open a new final review scope after the blocker is resolved, and that decision must be appended to the ledger; never disguise it as attempt 4.
12. Final severity mapping: `Critical` stays Critical; `High` maps to Important and is a main-flow blocker; `Medium` maps to Important; `Low` maps to Minor. A mapped Medium is blocking only when it meets the same observable main-flow conditions used for task review; otherwise it may become final review debt. A mapped Low never blocks alone.
13. After `FAIL` at attempt 1 or 2, set `reviewPhase=fixing` and dispatch `${CLAUDE_PLUGIN_ROOT}/skills/fp-execute-sdd/fix-prompt.md` with `Review scope: final`, `BRIEF_PATH=N/A`, the completed attempt, final package, final review report, resolved proposal/design/plan context, exact mapped findings, and `.fp-execute/reports/final-review-fixes.md`. For final review scope the fixer may touch multiple completed-task files only when required by those exact findings.
14. After the fixer, preserve the same reviewScopeId, set `priorReviewPath` to the completed report, retain all `priorFindingDispositions`, set `lastReviewedHead` to that attempt's reviewedTargetHead, and increment `reviewAttempt` exactly once. Reconcile/commit fixes, then repeat steps 5-9: at the new clean target checkpoint collect logical `lastReviewedHead..HEAD`, capture the new reviewedTargetHead, persist `lastReviewedHead..<reviewedTargetHead>`, generate a new package with packageParentHead=reviewedTargetHead and external sentinels, make one allowed evidence-only commit, resolve the external heads, and dispatch. Attempts 2/3 also recheck affected contracts/tests/package/ledger and every standard gate.
15. The final review scope has a maximum of three reviews. The initial review is attempt 1. At failed attempt 3, record mapped non-blocking findings as final review debt, but keep any main-flow blocker `BLOCKED` and prevent completion or archive. Never dispatch attempt 4.
16. On resume, restore the recorded final review attempt, `reviewPhase`, scope/prior finding state, packageParentHead, and historical runtime evidence. Branch by phase:
    - `pending-dispatch`: current clean HEAD is the unique direct child of packageParentHead. Re-run parent/count/name-only checks for the allowed evidence-only delta, then reconstruct `evidenceCommitHead=dispatchHead=current HEAD` without relying on a ledger self-recorded commit SHA.
    - `review-completed`: historical dispatchHead remains the current committed HEAD; only final report/result-ledger paths may be uncommitted. Validate them and persist the result before advancing.
    - `result-committed` or `fixing`: must not set dispatchHead=current HEAD. Recover historical dispatchHead from the later result event, run `git merge-base --is-ancestor <dispatchHead> HEAD`, and verify dispatchHead is an ancestor of current HEAD, `dispatchHead^ == packageParentHead`, `rev-list --count packageParentHead..dispatchHead == 1`, and original allowed package/pending-ledger paths. Run `git diff --name-only <dispatchHead>..HEAD` for successors after dispatchHead: result/complete permit only final report/result-ledger evidence; fixing additionally permits exact finding-authorized source/tests/fix evidence. Any other phase-allowed result evidence/fix paths violation records `BLOCKED`.
    A result commit records the prior dispatchHead and does not record its own SHA; resolve its current SHA externally. A new reviewer, new commit, new session, or new finding never resets the final scope.
17. After a `PASS` or `PASS_WITH_NOTES` result is committed and the phase checks pass, set `reviewPhase=complete` without rerunning review. Any successor evidence update must contain only permitted final result/report paths; otherwise the verdict is stale and follows the bounded non-pass transition.
18. Final review never resets or reopens a completed task review scope merely because it reports an existing review debt item.
19. Only then produce the final execution report.

## CodeGraph write freshness

After any implementer/fixer writes source, tests, config, schema, or generator inputs, mark the graph `dirty-after-write`; controller and workers `never query a dirty graph` and use current-source search. If `.codegraph/` existed before writes, run one `post-write-sync` before each mutated step-confirmation, final, or blocker return:

```text
codegraph sync <project-root> --quiet
```

Do not rerun `status`, commit `.codegraph/`, or initialize a missing graph. Record success/skip/one failure; sync `must not block completion`, review transitions, or blocker reporting.

Final report must include:
- Completed tasks.
- Key commits / commit ranges.
- Validation commands and results.
- Brief/report/review/package paths.
- Minor findings and review debt fixed or deferred, with exact findings and rationale.
- Final review result.
- CodeGraph `post-write-sync` execution, skip, or failure state.
- Whether `/fp-archive` is recommended.

Only `step-confirmation` produces a user confirmation prompt after an individual task passes review or is accepted with non-blocking review debt at attempt 3. In `automatic-continuation`, concise per-task status is progress only; the controller's user-facing return occurs after all tasks and final review complete or when a genuine blocker requires user input.

## Invariant recap

Serial implementers only; reviewer stays read-only; every task gets a package; each task and final review scope has a maximum of three reviews per review scope; owner checkbox plus verified evidence beats chat memory while the ledger supports recovery; `CANNOT VERIFY FROM DIFF` is not pass; one task never broadens scope; no controller may dispatch review attempt 4.
