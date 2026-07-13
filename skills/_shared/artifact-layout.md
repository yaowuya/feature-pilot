# FeaturePilot Shared Artifact-Layout Contract

This file is the normative layout and resolution contract for artifacts under
`fp-docs/changes/<slug>/`. Every Producer and Consumer of PRD, proposal,
design, or task-plan artifacts must follow it.

## Canonical forms

Each logical artifact selects exactly one of the following forms. The small
file and split directory are mutually exclusive.

| Logical artifact | Small form | Split form |
| --- | --- | --- |
| PRD | `prd.md` | `prd/00-index.md` plus indexed fragments |
| Proposal | `proposal.md` | `proposal/00-index.md` plus indexed fragments |
| Backend design | `design/backend.md` | `design/backend/00-index.md` plus indexed fragments |
| Frontend design | `design/frontend.md` | `design/frontend/00-index.md` plus indexed fragments |
| Backend plan | `tasks/plan-backend.md` | `tasks/backend/00-index.md` plus indexed fragments |
| Frontend plan | `tasks/plan-frontend.md` | `tasks/frontend/00-index.md` plus indexed fragments |

Whenever any design end exists, `design/00-index.md` is required. Its exact
`End / Canonical entrypoint / Mode` rows list every and only the ends that
exist, and each row must match the actual small or split representation.
`tasks/00-overview.md` exists exactly when both backend and frontend
plans exist. A single-end plan never has an overview, whether small or split.

```text
fp-docs/changes/<slug>/
├── prd.md | prd/00-index.md
├── proposal.md | proposal/00-index.md
├── design/
│   ├── 00-index.md
│   ├── backend.md | backend/00-index.md
│   └── frontend.md | frontend/00-index.md
└── tasks/
    ├── 00-overview.md                 # both ends only
    ├── plan-backend.md | backend/00-index.md
    └── plan-frontend.md | frontend/00-index.md
```

The vertical bar above means “one form or the other”; it does not permit both.

## Split selection and safety limits

A Producer selects one form before writing. Default to the small form whenever the complete logical artifact is expected to fit within both hard limits below.

Select split form only when at least one of these conditions is true:

1. the complete small form is expected to exceed 500 lines or 30,000 characters;
2. the user explicitly approves split form; or
3. an applicable target-project setting explicitly requires split form.

The presence of multiple features, subsystems, page areas, task groups, or ownership domains does not by itself trigger split form. Once split form is selected, use those semantic boundaries to define fragments and write the final structure directly; do not generate a monolith and mechanically cut it later.

Every produced Markdown file, including an index or fragment, must contain no
more than 500 lines and no more than 30,000 characters. Crossing either limit
requires another semantic split. These are hard fallback limits, not targets.

Keep complete semantic units together. A PRD feature block, proposal change
point, model, API, permission, integration contract, UI mapping, visual
acceptance contract, interface ledger, task group, or coverage section has one
detailed owner. Other files link to that owner rather than copying its body.

## Split manifest

Every split directory has `00-index.md` as its canonical entrypoint. Its
authoritative fragment manifest uses an exact `## Fragment Manifest` section
and this schema:

| Order | File | Kind | Owns |
| ---: | --- | --- | --- |
| 1 | `01-context.md` | context | global constraints |
| 2 | `10-domain-tasks.md` | tasks | `backend-001`–`backend-004` |
| 3 | `90-coverage.md` | coverage | proposal/design coverage |

The manifest defines fragment order and ownership. Every listed file must
exist, and every sibling Markdown fragment must be listed exactly once. Order
values and file entries are unique. Indexes contain navigation and ownership
metadata only; detailed requirements, constraints, contracts, coverage rows,
and task bodies remain in their single owner fragment.

For a split PRD or proposal, logical concatenation in manifest order must
preserve the mandatory template headings, tables, and section order, each with
exactly one owner. For a split design, `design/00-index.md` remains a small
change-level end map and never substitutes for an end-specific manifest.

A split plan manifest permits only these cardinalities: exactly one `context`,
exactly one `interface`, exactly one `coverage`, and one or more `tasks` rows.

## Task ownership and overview

Every executable task has one stable `backend-NNN` or `frontend-NNN` ID and
exactly one checkbox in one small plan or one `tasks`-kind fragment. IDs remain
unique across fragments and never restart per file. Index, context,
interface-ledger, coverage, and overview files contain no executable task
checkboxes.

Every task owner block declares exactly one `Depends on` field. Consumers build
the complete dependency graph from those owner files, validate every same-end
and cross-end reference, and reject cycles before interpreting overview
coordination.

An end-local manifest owns file order and task ranges. When both ends exist,
`tasks/00-overview.md` requires `Canonical End Entrypoints` and `Progress
Totals`. `Cross-end Dependency Edges` is required exactly when the owner-file
graph has cross-end dependencies and must declare every such edge exactly once,
in the owner-declared direction. `Cross-end Execution Stages` is optional
textual coordination and never substitutes for or adds an edge. Omit both
cross-end sections when no cross-end relationship exists. Progress is recomputed from the unique
owner checkboxes. The overview does not repeat an all-task owner table,
end-local navigation, constraints, interfaces, coverage, task details, or
checkboxes. Old `Plan Entrypoints`, `Stable entrypoint`, `Cross-end Execution
Order`, and `Progress Summary` schemas are invalid.

## Producer resolution

Before creating or revising an artifact, a Producer checks for the small form,
the split `00-index.md`, and any unsupported historical paths.

1. For a new artifact, choose one canonical form from the table and write only
   that form.
2. For an existing canonical artifact, preserve its resolved form unless the
   confirmed change requires conversion. A conversion removes the old form so
   the result still has exactly one canonical entrypoint.
3. Never create or continue a stable-file-plus-directory combination.
4. Historical combined layouts and root-level `design-backend.md` /
   `design-frontend.md` are invalid. Migration requires explicit approval,
   transfer or merge of all required content into one canonical form,
   validation, and deletion of every obsolete path before work continues.

## Consumer resolution

For each logical artifact, a Consumer resolves paths in this order:

1. Detect the canonical small file, split directory and its `00-index.md`, and
   unsupported historical paths.
2. If a split directory lacks its index, reject it.
3. Reject every dual-form combination. `prd.md` plus `prd/`, `proposal.md` plus
   `proposal/`, either design end file plus its directory, and either plan end
   file plus its directory are absolute structural conflicts in both Producer
   and Consumer modes.
4. Reject root-level `design-backend.md` and `design-frontend.md`; they are not
   canonical design entrypoints.
5. If exactly one canonical form exists, use it. For split form, parse the
   manifest and read every listed fragment in exact order. Never infer order
   from recursive globs, filesystem order, or body links.
6. For every resolved form, reject a missing listed file, unindexed Markdown
   fragment, duplicate manifest entry, duplicate content owner, duplicate task
   ID or checkbox, forbidden checkbox location, size-limit violation, invalid
   task overview condition, missing task reference, or dependency cycle.
7. Validate the logical PRD and proposal after manifest-order concatenation:
   all mandatory headings, feature fields, required tables, and canonical
   section order must be complete for either small or split form.

## Unsupported historical layouts

There is no read-only compatibility mode for historical artifact layouts.
Consumers and Producers reject:

- root-level `design-backend.md` or `design-frontend.md`;
- the former stable-file-plus-directory form for design or tasks, such as
  `design/backend.md` plus `design/backend/`, or `tasks/plan-backend.md` plus
  `tasks/backend/` and the corresponding frontend forms; and
- simultaneous `prd.md` plus `prd/`, or `proposal.md` plus `proposal/`.

Before any phase can continue, an explicitly approved migration must merge or
transfer required content into exactly one canonical form, delete the obsolete
file or directory, and pass artifact-layout validation.
