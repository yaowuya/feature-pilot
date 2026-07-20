# Task Layout Templates

Apply the artifact-layout contract already loaded by `fp-plan`. Read this file only when `fp-plan` has selected a split form for an end or needs the two-end plan overview. Indexes and overviews are navigation/coordination artifacts, never executable task owners, so they must not contain `- [ ] **Task ...**` or `- [x] **Task ...**` markers.

## Change-level overview

Create `fp-docs/changes/<slug>/tasks/00-overview.md` for a two-end plan only. A single-end plan never has an overview, whether small or split. Include only canonical entrypoints for ends actually in scope, real cross-end dependency edges or execution stages, and progress totals derived from the unique owner checkboxes. Do not copy end-local navigation, constraints, interfaces, coverage, task bodies, or checkboxes.

```markdown
# <Feature> Task Plan Overview

## Canonical End Entrypoints

| End | Canonical entrypoint | Mode |
| --- | --- | --- |
| Backend | `tasks/backend/00-index.md` | split |
| Frontend | `tasks/plan-frontend.md` | small |

## Cross-end Dependency Edges

Include every dependency that crosses from one end to the other. Same-end dependencies remain in the unique task owner files and end-local manifest ownership. When the owner graph has any cross-end dependency, the edge section is required and must match that graph exactly; omit it only when the graph has no cross-end edge. The optional stage section adds textual coordination and never substitutes for, reverses, or adds an edge.

| From task | To task | Shared contract / gate |
| --- | --- | --- |
| `backend-004` | `frontend-002` | `<API response contract verified by exact command>` |

## Cross-end Execution Stages

| Stage | Ends / cross-end gate | Exit condition |
| ---: | --- | --- |
| 1 | Backend contract provider | `<backend-004 verification passes>` |
| 2 | Frontend contract consumer | `<frontend-002 verification passes against the confirmed contract>` |

## Progress Totals

Progress totals derived from the unique owner checkboxes are read-only roll-ups, never an independent completion authority.

| End | Total | Complete | Remaining |
| --- | ---: | ---: | ---: |
| Backend | `<derived total>` | `<derived checked>` | `<derived remaining>` |
| Frontend | `<derived total>` | `<derived checked>` | `<derived remaining>` |
```

## Per-end split manifest

Create `tasks/backend/00-index.md` or `tasks/frontend/00-index.md` only for the selected split form. The corresponding `tasks/plan-<end>.md` must not exist. In the manifest `File` column, use split-directory-relative fragment basenames such as `01-context.md`, never repository-relative paths. List them in deterministic logical order, and list every sibling Markdown fragment exactly once.

Each split end has exactly one `context`, exactly one `interface`, exactly one `coverage`, and one or more `tasks` rows. No other Kind is valid.

```markdown
# <Backend / Frontend> Task Plan Index

## Fragment Manifest

| Order | File | Kind | Owns |
| ---: | --- | --- | --- |
| 1 | `01-context.md` | context | plan header, goal, architecture, stack, global constraints, file structure |
| 2 | `05-interfaces.md` | interface | end-local interface ledger and contract checks |
| 3 | `10-<topic>-tasks.md` | tasks | `<end>-001`–`<end>-003` executable task bodies |
| 4 | `20-<topic>-tasks.md` | tasks | `<end>-004`–`<end>-006` executable task bodies |
| 5 | `90-coverage.md` | coverage | proposal/design/boundary coverage and verification mapping |
```

Only `tasks`-kind fragments may contain executable task checkboxes. IDs increase across all task fragments and never restart per file. `00-index.md`, `context`, `interface`, and `coverage` files contain no task checkboxes. Each constraint, interface, task body, and coverage row has exactly one detailed owner; other files link to that owner rather than copy its body.
