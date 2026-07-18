# FeaturePilot SDD Task Brief Template

Use this template for `.fp-execute/briefs/<task-id>-brief.md` before dispatching an implementer.
Apply the artifact-layout contract already loaded by the owning `fp-execute-sdd` controller. The controller is a canonical-first Consumer: preserve manifest order and block every historical or dual structural conflict before creating a task brief.

```markdown
# Task Brief: <task-id>

## Identity

- Change slug: `<slug>`
- Task owner file: `<exact resolved task-owner path>`
- Resolved plan context: `<selected small plan OR split index plus manifest-ordered fragments; two-end overview only when applicable>`
- Task heading: `<exact heading>`
- Task checkbox line: `<exact checkbox text>`
- Declared dependencies: `<exact task IDs or None>`
- Controller base SHA: `<sha before task starts>`

## Resolved Artifact Contract

Record each logical artifact independently so mixed small/split changes remain explicit.

| Logical artifact | Canonical entry | Resolution mode | Ordered fragments |
| --- | --- | --- | --- |
| PRD | `<prd.md OR prd/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |
| Proposal | `<proposal.md OR proposal/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |
| Backend design | `<design/backend.md OR design/backend/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |
| Frontend design | `<design/frontend.md OR design/frontend/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |
| Backend plan | `<tasks/plan-backend.md OR tasks/backend/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |
| Frontend plan | `<tasks/plan-frontend.md OR tasks/frontend/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |

- Structural conflict: `None` (otherwise no brief may be dispatched)
- Task ownership proof: <manifest Kind=`tasks` row; `tasks`-kind owner; unique task owner path and checkbox>
- Overview applicability: `<two-end overview path and derived totals, or single-end/no overview>`
- Structural validation: `<missing/unindexed fragment, duplicate owner/ID/checkbox, forbidden checkbox, dependency/cycle checks>`

## Status

- Ledger status before dispatch: `not-started | reopened | retry`
- Prior attempts: `<none or report/review paths>`

## Applicable Global Constraints

Copy only the constraints that apply to this task, preserving exact values:

- `<constraint>`

## Relevant Project Information Layer

- FeaturePilot manifest:
- Relevant settings excerpts:
- Relevant workspace-map excerpts:
- Relevant commands/quality-gates excerpts:
- Relevant architecture/contracts excerpts:
- Relevant security/data excerpts:
- Relevant frontend settings excerpts:
- Relevant backend settings excerpts:
- Unknowns checked:
- Staleness notes:

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

Paste the complete task from the approved plan here, including `Files`, `Reasoning`, `Depends on`, `Interfaces`, TDD steps, validation commands, and commit step.

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
