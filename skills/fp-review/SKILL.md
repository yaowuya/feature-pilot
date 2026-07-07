---
name: fp-review
description: Use when performing a final whole-branch review of an implemented FeaturePilot change before archive or merge, especially after fp-execute finishes and the reviewer must verify proposal, design, tasks, progress ledger, validation evidence, and branch diff without editing files.
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

# FeaturePilot Final Whole-Branch Review

`fp-review` is the read-only final reviewer for a completed FeaturePilot change. It reviews the whole branch against `proposal.md`, design files, task plans, progress ledger, validation evidence, and the final branch diff, then writes the review under `.fp-execute/reviews/`.

This skill is self-contained. It may read optional `fp-docs/settings/agent.md` as customer configuration, but must not depend on global code-review skills, external agents, prior archived changes, or local absolute paths. Current code, current FeaturePilot artifacts, customer settings, and the branch diff are the facts.

## Read-Only Reviewer Contract

You are a reviewer, not an implementer.

Allowed:
- Read files, search code, inspect git history/diff, and run read-only verification commands.
- Create only the final review report under `.fp-execute/reviews/`.

Forbidden:
- Do not edit implementation files, tests, FeaturePilot proposal/design/tasks, task checkboxes, progress ledger, or git history.
- Do not run `git add`, `git commit`, `git reset`, `git rebase`, formatters with write mode, migrations that create files, snapshot updates, autofix commands, or database-mutating commands.
- Do not fix findings during review. Record evidence and required remediation instead.

If a useful verification command would mutate the working tree, skip it and record why.

## Inputs

Accept these inputs when provided:
- `slug`: FeaturePilot change directory name under `fp-docs/changes/<slug>`.
- `baseRef`: diff base. If absent, try in order: Base SHA from `.fp-execute/progress.md`, `origin/master`, `origin/main`, `master`, `main`.
- `headRef`: default `HEAD`.
- `reviewDepth`: `standard` or `strict`; default `standard`.
- `focus`: optional focus area such as backend, frontend, permissions, security, migration, visual, tests, or contracts.

If `slug` is missing, list `fp-docs/changes/` directories and ask the user to choose; if exactly one exists, use it and state the choice. If `baseRef` cannot be determined, ask the user before continuing.

## Required Reads

Immediately read the actual files that exist for the selected change:
1. `fp-docs/changes/<slug>/proposal.md`
2. `fp-docs/changes/<slug>/design-backend.md` if present
3. `fp-docs/changes/<slug>/design-frontend.md` if present
4. all `fp-docs/changes/<slug>/tasks/*.md` files if present
5. `fp-docs/changes/<slug>/.fp-execute/progress.md` if present
6. existing `fp-docs/changes/<slug>/.fp-execute/reviews/*.md` task reviews if present
7. project/customer constraint files if present: `fp-docs/settings/agent.md`, `CLAUDE.md`, `.claude/CLAUDE.md`, `AGENTS.md`, `.agents/AGENTS.md`

Then inspect the whole branch with read-only commands:
- `git status --short`
- `git rev-parse <headRef>`
- `git merge-base <baseRef> <headRef>` when using branch refs
- `git log --oneline <baseRef>..<headRef>`
- `git diff --stat <baseRef>...<headRef>`
- `git diff --name-only <baseRef>...<headRef>`
- targeted `git diff <baseRef>...<headRef> -- <path>` for changed files

Do not paste full diffs into chat. Use the diff to drive findings and coverage.

## Review Procedure

### 1. State and Input Validation

Verify:
- The change directory exists and has a proposal.
- At least one design file, task plan, progress ledger entry, commit, or diff provides implementation evidence.
- Task checkboxes, progress ledger, commits, and actual files do not contradict each other.
- Working tree state is known. Dirty working tree is allowed to be reviewed, but final verdict cannot be `PASS`.

If required inputs are missing so badly that review cannot proceed, write a `BLOCKED` report.

### 2. FeaturePilot Coverage Review

Build a coverage table from source artifacts:
- Every `proposal.md` `What Changes` and `Capabilities` item.
- Every explicit `Out of Scope` item.
- Every backend design contract, permission, migration, provider, API, and validation requirement.
- Every frontend design contract, route/store/API, component mapping, project frontend framework `the project-standard script pattern`, `project-configured components`, style token, and Visual Check requirement.
- Every completed task in task plans and progress ledger.

For each item, mark `Covered`, `Partial`, `Missing`, `Violated`, or `N/A`, with file/test/commit evidence.

### 3. Whole-Branch Diff Review

Review changed files as one integrated change, not as isolated tasks.

Check relevant areas:
- Backend: model, migration, service, serializer/schema, ViewSet/API, URL/router, IAM/permission, provider/registry, async jobs, external calls, tenant isolation, error handling, backward compatibility.
- Frontend: API wrapper, store/composable, route, project frontend framework `the project-standard script pattern`, project-configured components, state transitions, loading/empty/error states, styles, design tokens, Figma/Visual Checks.
- Contracts: URL, HTTP method, request/response fields, enums, error shape, pagination/filter/sort, permission states, route names, store actions, component props/events.
- Tests: meaningful assertions, negative paths, permissions, boundary cases, migration/compatibility, frontend contract and visual checks where applicable.
- Production readiness: deployment order, migrations, config, feature flags, logging, security leakage, performance, rollback implications.

### 4. Verification Commands

Prefer commands recorded in task plans and `.fp-execute/progress.md`. Run only read-only commands appropriate to the change, such as unit tests, lint check without autofix, typecheck, build, or dry-run validation.

For each command record:
- command text
- result: `PASS`, `FAIL`, or `SKIPPED`
- key output or skip reason

A required verification command that fails usually forces `FAIL`. A skipped command may force `PASS_WITH_NOTES`, `FAIL`, or `BLOCKED` depending on risk.

## Severity Rubric

Report only concrete defects or material unverified risks. Do not report style preferences.

| Severity | Definition | Verdict impact |
| --- | --- | --- |
| `Critical` | Data loss, security bypass, tenant/permission isolation break, production crash, irreversible migration failure, or core FeaturePilot goal unusable | Always `FAIL` |
| `High` | Major required behavior missing, backend/frontend contract incompatible, deployment likely fails, important permission/migration path broken, or critical validation absent | Normally `FAIL` |
| `Medium` | Secondary requirement partial/missing, boundary behavior wrong, loading/empty/error/visual state materially incomplete, tests insufficient for changed risk, or progress/tasks conflict with implementation | `PASS_WITH_NOTES` or `FAIL` based on risk/count |
| `Low` | Non-blocking maintainability, minor doc mismatch, small visual/text polish, or low-risk validation gap | Does not block alone |

Each finding must include:
- severity
- title
- evidence with path and line number, or command output
- failure scenario: concrete input/state leading to wrong result or risk
- source requirement: proposal/design/task/progress/diff item
- suggested fix direction

## Final Verdict

Choose exactly one:

- `PASS`: no Critical/High/Medium findings; working tree clean; required verification passed; FeaturePilot scope is fully covered.
- `PASS_WITH_NOTES`: no Critical/High findings; only Low or explicitly acceptable Medium findings; working tree clean; core verification passed; archive/merge may proceed with notes.
- `FAIL`: any Critical/High finding, blocking Medium risk, failed key verification, dirty working tree, implemented Out of Scope behavior, or missing core FeaturePilot scope.
- `BLOCKED`: review cannot complete because required inputs, base ref, diff, or safe verification are unavailable.

If verdict is not `PASS`, list exact blocking items before archive.

## Output Location

Create the review directory if needed:

```text
fp-docs/changes/<slug>/.fp-execute/reviews/
```

Write exactly one final review report:

```text
fp-docs/changes/<slug>/.fp-execute/reviews/YYYYMMDD-HHMM-final-review.md
```

If the reviewed task is outside `fp-docs/changes/<slug>/`, write to the nearest task directory instead:

```text
.fp-execute/reviews/YYYYMMDD-HHMM-final-review.md
```

Do not write review reports anywhere else.

## Final Review Report Template

```markdown
# Final FeaturePilot Review: <slug>

**Verdict:** PASS | PASS_WITH_NOTES | FAIL | BLOCKED
**Reviewer:** read-only fp-review
**Review Time:** YYYY-MM-DD HH:MM
**Base Ref:** <baseRef>
**Head Ref:** <headRef or sha>
**Change Path:** fp-docs/changes/<slug>
**Review Depth:** standard | strict
**Focus:** <focus or none>

## Inputs Reviewed

- Proposal: `<path>`
- Backend design: `<path or N/A>`
- Frontend design: `<path or N/A>`
- Task plans: `<paths or N/A>`
- Progress ledger: `<path or missing>`
- Prior task reviews: `<paths or none>`
- Project constraints: `<paths or none>`
- Diff: `<baseRef>...<headRef>`

## Branch State

- Working tree: clean | dirty
- Dirty files: <none or list>
- Commits reviewed: <count>
- Changed files reviewed: <count>

## FeaturePilot Coverage

| Source | Requirement / Task | Status | Evidence |
| --- | --- | --- | --- |
| proposal.md | <requirement> | Covered / Partial / Missing / Violated / N/A | <file/test/commit> |

## Verification Commands

| Command | Result | Notes |
| --- | --- | --- |
| `<command>` | PASS / FAIL / SKIPPED | <key output or reason> |

## Findings Summary

| Severity | Count |
| --- | ---: |
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low | 0 |

## Findings

### Critical
- None

### High
- None

### Medium
- None

### Low
- None

<!-- Finding format:
- **[Severity] Title**
  - Evidence: `path:line` or command output
  - Failure scenario: <concrete input/state -> wrong result/risk>
  - Source requirement: <proposal/design/task/progress/diff>
  - Suggested fix: <direction, not implementation patch>
-->

## Blocking Items Before Archive

- None, or exact required fixes.

## Residual Risks / Notes

- <non-blocking risk or note>

## Final Verdict Rationale

<Concise explanation tying FeaturePilot coverage, diff review, verification, findings, and branch state to the verdict.>
```

## Completion Response

After writing the report, respond with only:
- review report path
- final verdict
- finding counts by severity
- verification summary
- blocking items before archive

Do not paste the full report unless the user asks.
