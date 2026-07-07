# FeaturePilot SDD Task Brief Template

Use this template for `.fp-execute/briefs/<task-id>-brief.md` before dispatching an implementer.

```markdown
# Task Brief: <task-id>

## Identity

- Change slug: `<slug>`
- Plan file: `<fp-docs/changes/<slug>/tasks/plan-*.md>`
- Task heading: `<exact heading>`
- Task checkbox line: `<exact checkbox text>`
- Controller base SHA: `<sha before task starts>`

## Status

- Ledger status before dispatch: `not-started | reopened | retry`
- Prior attempts: `<none or report/review paths>`

## Applicable Global Constraints

Copy only the constraints that apply to this task, preserving exact values:

- `<constraint>`

## Proposal / Design Context

Relevant proposal excerpt:

> `<minimal exact excerpt>`

Relevant design excerpt:

> `<minimal exact excerpt>`

## Prior Interfaces Available

List only interfaces already produced by completed tasks or existing code that this task may consume:

| Interface | Source | Contract | Evidence |
| --- | --- | --- | --- |
| `<name>` | `<existing code or task-id>` | `<signature/field/URL/component contract>` | `<file/test/review path>` |

## Full Task Text

Paste the complete task from the approved plan here, including `Files`, `Reasoning`, `Interfaces`, TDD steps, validation commands, and commit step.

```text
<full task text>
```

## Allowed Scope

The implementer may edit only:

- `<path>`

The implementer must not edit:

- Neighboring tasks.
- Proposal/design/plan files.
- Unrelated refactors, formatting-only files, or dependency files unless explicitly named above.

## Required Evidence

The report must include:

- Failing test command and key failure output, unless the task explicitly uses alternative validation.
- Passing test/lint/build/visual command and key output.
- Interface/contract evidence.
- Commit SHA(s).
- Known concerns or blockers.
```
