# Task Layout Templates

Read this file only when `fp-plan` needs a change-level overview or an end-specific plan is split. These files are indexes and summaries, never executable task owners, so they must not contain `- [ ] **Task ...**` or `- [x] **Task ...**` markers.

## Change-level overview

Create `fp-docs/changes/<slug>/tasks/00-overview.md` when both ends are planned or either end is split:

Include only ends and rows that are actually in scope; do not emit placeholder plan entries for an absent end.

```markdown
# <Feature> Task Plan Overview

## Plan Entrypoints

| End | Stable entrypoint | Mode | Executable task source |
| --- | --- | --- | --- |
| Backend | `tasks/plan-backend.md` | small / split | stable entrypoint / `tasks/backend/00-index.md` |
| Frontend | `tasks/plan-frontend.md` | small / split | stable entrypoint / `tasks/frontend/00-index.md` |

## Cross-end Execution Order

Cover every task ID exactly once. A range is allowed only for contiguous tasks in the same owner file with identical external dependencies; otherwise list tasks separately so cross-end boundaries remain explicit.

| Sequence | Task ID or range | Owner file | Depends on |
| --- | --- | --- | --- |
| 1 | `backend-001` | `tasks/backend/01-domain.md` | None |
| 2 | `frontend-001` | `tasks/plan-frontend.md` | `backend-001` |

## Coverage Summary

| Proposal / design area | Owning task IDs | Verification |
| --- | --- | --- |
| `<scope>` | `<end-NNN>` | `<exact command/check>` |

## Progress Summary

Derived from the unique owner checkboxes; never treat these counts as independent completion state.

| End | Total | Complete | Remaining |
| --- | ---: | ---: | ---: |
| Backend | `<derived total>` | `<derived checked>` | `<derived remaining>` |
| Frontend | `<derived total>` | `<derived checked>` | `<derived remaining>` |
```

## Per-end fragment index

Create `tasks/backend/00-index.md` or `tasks/frontend/00-index.md` only for a split end:

```markdown
# <Backend / Frontend> Task Fragment Index

## Stable Entrypoint

- Summary and constraints: `tasks/plan-<end>.md`
- Task IDs are globally increasing within this end and do not restart in each fragment.

## Fragment Order

| Sequence | Fragment | Task IDs | Depends on |
| --- | --- | --- | --- |
| 1 | `tasks/<end>/01-<topic>.md` | `<end>-001`–`<end>-003` | None |
| 2 | `tasks/<end>/02-<topic>.md` | `<end>-004`–`<end>-006` | `<end>-003` |

## Coverage Summary

| Requirement / boundary | Task IDs | Fragment |
| --- | --- | --- |
| `<scope>` | `<end>-NNN` | `tasks/<end>/<number>-<topic>.md` |
```
