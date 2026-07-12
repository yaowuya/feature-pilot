---
name: fp-execute-sdd
description: Use when executing confirmed FeaturePilot implementation plans that need isolated task workers, fresh-context review, interruption recovery, or stricter quality gates than inline execution.
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.
Read `../_shared/artifact-layout.md` once before resolving execution inputs; it is the normative layout and validation contract.
---

# FeaturePilot Subagent-Driven Execute

`fp-execute-sdd` executes an approved FeaturePilot change with Subagent-Driven Development. The controller stays in charge of sequencing, ledger updates, packages, and user-facing decisions; fresh subagents do one implementation task or one review at a time.

Core rule: **implementers are serial, reviewers are per task, fixes loop until reviewed clean, the unique task-owner checkbox owns planned completion, and the ledger is recovery evidence.**

## SDD Continuation Mode

Before dispatching the first implementer, exactly one SDD continuation mode must be selected explicitly by the user or restored from `progress.md`. Never infer the mode from task count, plan complexity, risk, or a recommendation. If this skill is invoked directly and no valid mode is recorded, explain both choices below and wait for the user's explicit selection.

### Step-confirmation SDD

Complete exactly one task through implementation, review and any fix loop, checkbox reconciliation, derived overview update when applicable, and ledger update. Then report the task's files, commits, validation, report/review paths, and risks, and wait for explicit user confirmation before selecting or dispatching the next task. When the user replies “继续” or otherwise confirms, resume with the next eligible task without repeating completed work.

Choose this mode when the user wants to inspect every increment or control each task/commit boundary.

### Automatic-continuation SDD

Run the same complete per-task implementation, review/fix, checkbox, overview, and ledger cycle. After a task is reviewed clean and checkbox/overview/ledger state is synchronized, per-task reports are progress updates, not return points. The controller must immediately select and dispatch the next eligible task in the same run. Do not ask “continue to the next task?” and do not return merely because one task completed. Continue until every task and the final whole-change review complete.

Pause only for a genuine blocker that requires user input: a pre-flight or plan conflict; an unresolved product, architecture, security, scope, or data-safety decision; implementer status `BLOCKED` or `NEEDS_CONTEXT` that cannot be resolved from approved artifacts; or the same blocking review finding surviving three fix attempts. Choose this mode for unattended execution without giving up SDD review rigor.

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
2. If a manifest exists, `fp-docs/intel/sdd-handoff.md` is required for SDD execution. Read it and the relevant settings/intel entries before dispatching. If it is missing, stop and instruct the user to run `/fp-init` or repair the information layer; do not dispatch a fresh implementer with an incomplete handoff.
3. If no manifest exists, continue under the compatibility rule, but record the missing information layer in the progress ledger and task briefs.
4. Check relevant Unknowns before dispatch. If an unresolved Unknown can change task scope, interfaces, permissions, data safety, or UI acceptance, stop and request the missing decision.
5. Re-validate every referenced current source/config path before using generated intel as evidence. Generated intel is navigation, not proof of current behavior.

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
8. Run a serial fix loop for Critical/Important findings.
9. Update the unique owner checkbox, recompute derived overview progress counts only for a valid two-end overview, and record commit/commit-range evidence in the ledger only after review passes.
10. After a reviewed-clean task, branch only by the selected mode: `step-confirmation` reports evidence and waits for explicit confirmation; `automatic-continuation` must immediately select and dispatch the next eligible task without returning at the task boundary.
11. Record information-layer preflight, relevant Unknowns, and any stale/missing references in the progress ledger and review package.

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

## Events
- <ISO time> plan_review pass
```

Ledger rules:
- Persist `Execution strategy: SDD` and exactly one `SDD continuation mode:` value: `step-confirmation` or `automatic-continuation`.
- On resume, reuse a valid recorded mode without asking again. If no mode is recorded or it is ambiguous, explain both modes and ask before dispatching. If a new explicit selection conflicts with the recorded mode, ask whether to switch and append that decision before continuing. Never silently switch modes.
- The unique checkbox in the task-owner file is the planned completion state; ledger entries are recovery evidence and never override it.
- When both ends exist, `tasks/00-overview.md` progress counts are derived from owner checkboxes; recompute them on mismatch instead of treating them as another state source. Never create or expect it for a single-end plan.
- On any mismatch, inspect the owner file, commits, actual implementation, tests, and review evidence; reconcile both records before selecting, repeating, or declaring the task complete.
- Append an event for task start, implementer result, package creation, review result, fix attempt, blocked state, checkbox update, and final review.
- Do not repeat a task already marked complete unless the user explicitly asks to reopen it.
- If a task is blocked, record blocker, attempted commands, current HEAD, report/review paths, and the exact decision needed.

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

## Task Brief Package

Before dispatching an implementer, write a brief using `task-brief-template.md`. It must include:
- Task ID, unique task-owner path, declared dependencies, task heading, and task checkbox text.
- Full task text from the plan, not a summary.
- Applicable `Global Constraints`.
- Relevant proposal/design excerpts.
- Relevant prior interface outputs from completed tasks.
- Exact allowed file paths from the plan.
- Required TDD commands and expected failure/pass evidence.
- Required commit behavior.
- Explicit scope exclusions.

The implementer receives the brief path, not the full controller chat.

## Implementer Dispatch

Use `implementer-prompt.md` for each task.

Rules:
- One fresh implementer subagent per task.
- **No parallel implementers.** Dispatch the next implementer only after the current task is implemented, reviewed, fixed if needed, ledgered, and either completed or blocked.
- The implementer may edit files, run tests, and commit only the current task.
- The implementer must write the full report to `.fp-execute/reports/<task-id>-report.md`.
- The implementer final chat response must be short: status, commits, tests, report path, concerns.

Allowed implementer statuses:
- `DONE`: implemented, validated, committed, no known concerns.
- `DONE_WITH_CONCERNS`: implemented but has non-blocking uncertainty for reviewer/controller.
- `NEEDS_CONTEXT`: cannot proceed because brief/plan is incomplete or contradictory.
- `BLOCKED`: tried and cannot complete without user/project decision.

## Review Package

After `DONE` or `DONE_WITH_CONCERNS`, create a package using `review-package-template.md`:
- brief path
- implementer report path
- base/head SHA for this task
- commit list
- diff stat
- full diff with context
- test command evidence
- controller notes and known concerns

Write it to `.fp-execute/packages/<task-id>-review-package.md`. Do not paste large diffs into chat.

## Per-task Reviewer

Use `task-reviewer-prompt.md` for a fresh read-only reviewer after every implemented task.

Reviewer must verify two gates:
1. **Spec Compliance:** task brief, interfaces, constraints, visual checks, and validation evidence.
2. **Code Quality:** correctness bugs, contract bugs, test adequacy, maintainability, scope creep, production readiness.

Reviewer output goes to `.fp-execute/reviews/<task-id>-review.md` and must include:
- `Spec Compliance: PASS | FAIL | CANNOT VERIFY FROM DIFF`
- `Code Quality: APPROVED | NEEDS FIXES`
- Critical / Important / Minor findings with file:line evidence
- Test evidence assessment
- Interface/contract assessment
- `Ready for next task: YES | NO`

Reviewer rules:
- Read-only only. No edits, no commits, no index changes, no generated artifacts.
- Do not suppress findings because the plan asked for bad behavior. Report plan-mandated defects as plan-mandated.
- `CANNOT VERIFY FROM DIFF` is not a pass. The controller must inspect the relevant files/evidence and either resolve it or treat it as failed.

## Fix Loop

If reviewer reports any Critical or Important finding:
1. Append ledger event `review_failed` with finding count and review path.
2. Dispatch a fresh serial fixer with `fix-prompt.md`.
3. Fixer reads the brief, report, package, review, and exact findings.
4. Fixer edits only files needed for the findings, runs required tests, commits the fix if appropriate, and appends a fix section to the same report file.
5. Controller regenerates the review package from the new diff/HEAD.
6. Dispatch a fresh read-only reviewer with the same task-reviewer template.
7. Repeat until `Spec Compliance: PASS`, `Code Quality: APPROVED`, and no Critical/Important findings remain.

Escalate to the user and mark `BLOCKED` if:
- The same Critical/Important finding survives three fix attempts.
- Fixing requires changing approved proposal/design/plan scope.
- Fixing requires a product/architecture/security decision not present in the brief.

Minor findings do not block the next task, but record them in ledger `Minor Findings` with review path and whether deferred or fixed.

## Model Selection

Every dispatch states a capability expectation, not a guessed model ID. Use the user/project-configured default unless policy explicitly selects another available model.

- Use the highest available reasoning/capability tier for controller decisions, uncertain or cross-end work, permissions/security/data/migrations, complex UI, task review, fixes for blocking findings, and final review.
- A balanced tier may implement a well-scoped routine task only when user/project policy permits it.
- A lightweight tier is limited to trivial read-only or mechanical work when policy permits it.
- Never silently downgrade for cost, invent model IDs, or claim an unavailable model. If exact selection is unsupported, put the capability expectation in the prompt.

## Completion and Final Review

After all tasks are reviewed clean:
1. Ensure every completed task's unique owner checkbox is checked and no summary/index file contains a task checkbox.
2. Ensure ledger has no unresolved Blocked, Critical, or Important items.
3. Ensure Minor findings are fixed or explicitly deferred.
4. Run a final whole-change review. If `fp-review` exists, use it. If not, create a final review package in `.fp-execute/packages/final-review-package.md` and dispatch `task-reviewer-prompt.md` at whole-change scope with the same read-only rules.
5. If final review has Critical/Important findings, run the same serial fix loop. Do not dispatch parallel fixers.
6. Only then produce the final execution report.

Final report must include:
- Completed tasks.
- Key commits / commit ranges.
- Validation commands and results.
- Brief/report/review/package paths.
- Minor findings fixed or deferred.
- Final review result.
- Whether `/fp-archive` is recommended.

Only `step-confirmation` produces a user confirmation prompt after a clean individual task. In `automatic-continuation`, concise per-task status is progress only; the controller's user-facing return occurs after all tasks and final review complete or when a genuine blocker requires user input.

## Invariant recap

Serial implementers only; reviewer stays read-only; every task gets a package; completion follows review; owner checkbox plus verified evidence beats chat memory while the ledger supports recovery; `CANNOT VERIFY FROM DIFF` is not pass; one task never broadens scope.
