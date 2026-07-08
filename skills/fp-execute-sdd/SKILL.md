---
name: fp-execute-sdd
description: Use when executing confirmed FeaturePilot implementation plans that need isolated task workers, fresh-context review, interruption recovery, or stricter quality gates than inline execution.
---


## FeaturePilot workspace and customer settings

Before choosing output paths, component-library guidance, test commands, or workflow rules, locate the target project's FeaturePilot workspace:

1. Walk upward from the current working directory to find `fp-docs/`.
2. If `fp-docs/` does not exist and this phase needs to create artifacts, create only the directories this phase actually writes to. Do not pre-create empty directories for other phases.
   - Most phases only need `fp-docs/changes/` for their artifacts.
   - Only the archive phase (`fp-archive`) creates `fp-docs/archive/` and `fp-docs/history/`.
   - `fp-init` only creates `fp-docs/settings/` and writes optional config files inside it.
3. Read any settings files that exist. Do not create or overwrite customer settings unless the user explicitly asks.

Settings are optional. If a file is missing, fall back to current project code, adjacent implementations, and public defaults only; never invent customer-specific conventions.

Recommended settings file:

- `fp-docs/settings/agent.md` — optional project-specific FeaturePilot rules, including workflow, paths, component library, design system, UI tokens, Figma mapping, and visual review requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, or workflow policy in public skills. Customer-specific rules may be described in optional `fp-docs/settings/agent.md`.

---

# FeaturePilot Subagent-Driven Execute

`fp-execute-sdd` executes an approved FeaturePilot change with Subagent-Driven Development. The controller stays in charge of sequencing, ledger updates, packages, and user-facing decisions; fresh subagents do one implementation task or one review at a time.

Core rule: **implementers are serial, reviewers are per task, fixes loop until reviewed clean, and the ledger is the source of truth.**

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
- The plan has `tasks/plan-backend.md` and/or `tasks/plan-frontend.md` with explicit TDD steps.
- You want fresh-context per-task implementation and review rather than one long inline context.
- You need recovery after compaction, restart, or a partially completed task chain.

Do not use it for:
- `fp-quick` changes.
- Unapproved proposal/design/plan.
- Plans whose tasks are too vague to brief and review independently.
- Parallel implementers writing the same worktree. This skill forbids parallel implementation in v1.

## Inputs

Immediately read with tools:
- `fp-docs/changes/<slug>/proposal.md`
- Existing design files: `design-backend.md`, `design-frontend.md`
- Existing task files: `tasks/plan-backend.md`, `tasks/plan-frontend.md`
- Project constraints if present: `CLAUDE.md`, `.claude/CLAUDE.md`, `AGENTS.md`
- Existing `fp-docs/changes/<slug>/.fp-execute/progress.md`, if any

If no task file exists, stop and report that execution cannot start without an approved plan.

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
9. Update checkbox, commit/commit-range evidence, and ledger only after review passes.
10. Continue to the next task only when the current task is reviewed clean or explicitly blocked.

The controller must not implement product code inline except to repair orchestration artifacts such as a malformed brief/package. If implementation is needed, dispatch the implementer or fixer.

## Pre-flight Plan Review

Before any implementation subagent, scan the approved plan files for contradictions:

- Proposal/design/tasks agree on scope; out-of-scope work is not planned.
- `Global Constraints` exist and are concrete.
- Every task has `Files`, `Reasoning`, `Interfaces`, failure test, expected failure, minimal implementation, pass validation, and commit step.
- Backend plans have `Backend Interface Ledger` and `Coverage Matrix` consistent with tasks.
- Frontend page/component tasks have structure/state/style outlines appropriate to the target framework plus `Visual Checks`; tasks must follow the project’s existing frontend framework and script/state patterns.
- Backend/frontend contract names match exactly: URL, method, fields, enums, error shape, permissions, pagination/filter/sort semantics.
- No placeholders: `TBD`, `TODO`, `按需处理`, `类似上面`, `补充样式`, `run tests`, `Add appropriate error handling`, or equivalent vague instructions.
- No plan-mandated behavior that would obviously fail review: tests without assertions, hardcoded secrets, missing permission negative tests, unverified UI visual claims.

If conflicts exist, list all conflicts with file/line evidence and pause. Do not let implementers guess.

## Progress Ledger

`progress.md` is the recovery source of truth. Read it before selecting the next task; create it if absent.

Minimum format:

```markdown
# fp-execute-sdd progress

Change: <slug>
Base SHA: <sha at execution start>
Plan files:
- tasks/plan-backend.md
- tasks/plan-frontend.md

## Completed
- <task-id>: complete; commits <base>..<head>; tests `<commands>`; review <review-path>

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
- Ledger complete beats unchecked checkboxes; reconcile and explain the mismatch.
- Checkbox progress is user-visible; ledger progress is recovery truth.
- Append an event for task start, implementer result, package creation, review result, fix attempt, blocked state, checkbox update, and final review.
- Do not repeat a task already marked complete unless the user explicitly asks to reopen it.
- If a task is blocked, record blocker, attempted commands, current HEAD, report/review paths, and the exact decision needed.

## Task ID and File Naming

Use stable task IDs derived from the plan file and task number:

```text
backend-task-001
frontend-task-003
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
- Task ID, plan path, task heading, and task checkbox text.
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

Every subagent dispatch must state a model expectation. If the environment supports exact model selection, use exact IDs; if not, put the expectation in the prompt.

Safe default:
- Default to `claude-opus-4-8` for controller-level orchestration, task review, final review, cross-end integration, security/permission/data changes, complex UI/visual work, and any uncertain task.

User-approved alternatives:
- `claude-sonnet-5`: balanced/faster implementation for well-scoped routine tasks after the user or project policy permits a non-Opus model.
- `claude-haiku-4-5`: only for trivial read-only summarization or mechanical single-file edits after the user or project policy permits it.

Do not silently downgrade for cost. Do not invent date-suffixed model IDs. Use `claude-fable-5` only if the user explicitly asks for Fable / most capable model and the environment supports it.

Recommended mapping:

| Work | Model expectation |
| --- | --- |
| Controller orchestration | `claude-opus-4-8` |
| Complex implementer | `claude-opus-4-8` |
| Routine implementer, user-approved faster mode | `claude-sonnet-5` |
| Task reviewer | `claude-opus-4-8` |
| Fixer for Critical/Important | `claude-opus-4-8` |
| Trivial read-only package summarization, user-approved | `claude-haiku-4-5` |

## Completion and Final Review

After all tasks are reviewed clean:
1. Ensure every completed task checkbox is checked.
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

## Common Mistakes

| Mistake | Correct behavior |
| --- | --- |
| Parallel implementers for speed | Forbidden. Serial implementers only in v1. |
| Reviewer edits code | Reviewer is read-only; use a fixer. |
| Mark checkbox before review | Mark complete only after review passes. |
| Trust chat after compaction | Trust ledger, git log, reports, reviews, and files. |
| Skip package because diff is small | Every task gets a package. |
| Treat `CANNOT VERIFY FROM DIFF` as pass | Controller verifies or fails the review. |
| Use vague model labels only | Use exact IDs when supported; otherwise state capability expectation. |
| Let implementer broaden scope | Stop and ask; one task means one task. |
