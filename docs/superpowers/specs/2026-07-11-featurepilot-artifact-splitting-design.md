# FeaturePilot Artifact Splitting and PRD Trigger Design

**Date:** 2026-07-11
**Status:** Confirmed design; implementation pending
**Scope:** FeaturePilot PRD, proposal, design, and task-plan artifacts; `fp-prd` discovery metadata

## 1. Context

FeaturePilot currently handles large design and task-plan outputs by keeping a stable Markdown entrypoint next to an indexed fragment directory. The resulting layout duplicates navigation, constraints, coverage, or other body content and forces every consumer to understand two sources for one logical artifact.

The observed `business-assurance-policy/tasks` example contains both `plan-backend.md` / `plan-frontend.md` and `backend/` / `frontend/`. The backend stable file alone is 151 lines and 16,948 characters even though executable tasks live in fragments. Some fragments also exceed the intended working size. PRD and proposal outputs have no split form at all.

Separately, the `fp-prd` skill description treats ordinary ideas, pain points, feature requests, and rough requirements as automatic triggers. Fresh-context baseline checks show that `/goal` repository maintenance and an ordinary implementation request both incorrectly enter the PRD interview, while explicit `/fp-prd` and explicit requests to write a PRD correctly enter it.

## 2. Goals

1. Give PRD, proposal, backend/frontend design, and backend/frontend plan artifacts one consistent file-or-directory model.
2. Make the two representations mutually exclusive so one logical artifact has one canonical entrypoint.
3. Split on semantic boundaries before size becomes a problem, with deterministic line and character safety limits.
4. Keep indexes small and non-duplicative while preserving complete ordering and ownership information.
5. Give every producer and consumer one shared resolution contract.
6. Reject historical and dual layouts in both read and write flows until they are migrated to one canonical form.
7. Restrict automatic `fp-prd` discovery to explicit commands or explicit PRD-authoring intent.
8. Add executable validation for layout, size, indexing, content ownership, task identity, and overview rules.

## 3. Non-goals

- Migrating the external `auto-ops-platform` example as part of this repository change.
- Changing FeaturePilot phase confirmation gates or execution semantics beyond artifact resolution.
- Splitting `prototype.html`; this design covers PRD, proposal, design, and task-plan Markdown artifacts.
- Introducing customer-specific frameworks, component libraries, or backend conventions.
- Automatically migrating historical or dual layouts without explicit approval.

## 4. Confirmed Decisions

### 4.1 File and directory forms are mutually exclusive

Each logical artifact selects exactly one canonical representation:

| Artifact | Small form | Split form |
| --- | --- | --- |
| PRD | `prd.md` | `prd/00-index.md` plus indexed fragments |
| Proposal | `proposal.md` | `proposal/00-index.md` plus indexed fragments |
| Backend design | `design/backend.md` | `design/backend/00-index.md` plus indexed fragments |
| Frontend design | `design/frontend.md` | `design/frontend/00-index.md` plus indexed fragments |
| Backend plan | `tasks/plan-backend.md` | `tasks/backend/00-index.md` plus indexed files |
| Frontend plan | `tasks/plan-frontend.md` | `tasks/frontend/00-index.md` plus indexed files |

New producers must never create both forms of the same logical artifact. In split form, the directory's `00-index.md` is the canonical entrypoint; there is no external surrogate summary file.

### 4.2 Semantic splitting is primary; size is a safety net

Producers choose split form before writing when confirmed content contains multiple independently readable features, subsystems, page areas, task groups, or ownership domains.

Every produced artifact file, including every fragment and index, has two hard fallback limits:

- no more than 500 lines; and
- no more than 30,000 characters.

Crossing either limit requires further semantic splitting. Producers write the final selected structure directly; they do not generate a large monolith and mechanically cut it afterward.

### 4.3 Change-level task overview exists only for two-end plans

`tasks/00-overview.md` exists exactly when both backend and frontend plans exist. It owns only:

- the backend and frontend canonical entrypoints;
- cross-end dependency edges or execution stages; and
- progress totals derived from the unique task-owner checkboxes.

It does not repeat end-local navigation, constraints, interface ledgers, coverage matrices, task details, or checkboxes. A single-end plan never creates `tasks/00-overview.md`, whether small or split.

The overview uses the current template schema: required `Canonical End Entrypoints` and `Progress Totals`; `Cross-end Dependency Edges` required exactly when the task-owner graph has cross-end dependencies; and optional textual `Cross-end Execution Stages`, which never substitutes for or adds an edge. Every owner-declared cross-end edge appears exactly once in its declared direction, and no extra overview edge is permitted. Both cross-end sections are omitted when the task-owner dependency graph has no cross-end relationship. Old `Plan Entrypoints`, `Stable entrypoint`, `Cross-end Execution Order`, `Progress Summary`, and full all-task owner tables are rejected.

## 5. Canonical Layout

```text
fp-docs/changes/<slug>/
├── prd.md                         # small PRD
├── prd/                           # split PRD; mutually exclusive with prd.md
│   ├── 00-index.md
│   └── <number>-<topic>.md
├── proposal.md                    # small proposal
├── proposal/                      # split proposal; mutually exclusive with proposal.md
│   ├── 00-index.md
│   └── <number>-<topic>.md
├── design/
│   ├── 00-index.md                # actual ends and their canonical entries only
│   ├── backend.md                 # small backend design
│   ├── backend/                   # split backend design; mutually exclusive with backend.md
│   │   ├── 00-index.md
│   │   └── <number>-<subsystem>.md
│   ├── frontend.md                # small frontend design
│   └── frontend/                  # split frontend design; mutually exclusive with frontend.md
│       ├── 00-index.md
│       └── <number>-<area>.md
└── tasks/
    ├── 00-overview.md             # only when both ends exist
    ├── plan-backend.md            # small backend plan
    ├── backend/                   # split backend plan; mutually exclusive with plan-backend.md
    │   ├── 00-index.md
    │   └── <number>-<topic>.md
    ├── plan-frontend.md           # small frontend plan
    └── frontend/                  # split frontend plan; mutually exclusive with plan-frontend.md
        ├── 00-index.md
        └── <number>-<topic>.md
```

## 6. Shared Index Contract

All split directories use a concise `## Fragment Manifest` section in `00-index.md`:

```markdown
| Order | File | Kind | Owns |
| ---: | --- | --- | --- |
| 1 | `01-context.md` | context | global constraints |
| 2 | `10-domain-tasks.md` | tasks | `backend-001`–`backend-004` |
| 3 | `90-coverage.md` | coverage | proposal/design coverage |
```

The exact `## Fragment Manifest` heading and table are authoritative for fragment order and ownership. Every listed file must exist, and every Markdown fragment beside the index must be listed exactly once. Consumers must not use recursive glob order, filesystem order, or links embedded in body text to infer the artifact.

Indexes contain navigation and ownership metadata only. Detailed requirements, contracts, constraints, coverage rows, or task bodies live in one fragment owner and may only be linked from elsewhere.

## 7. Artifact-specific Semantic Boundaries

### 7.1 PRD

A representative split PRD is:

```text
prd/
├── 00-index.md
├── 01-user-stories-and-goals.md
├── 02-core-workflow.md
├── 10-feature-<name>.md
├── 11-feature-<name>.md
├── 90-non-functional.md
├── 91-test-suggestions.md
└── 99-open-questions.md
```

Each complete `3.N` feature block stays in one owner file, including 功能说明, 交互逻辑, 异常处理, 页面元素, and 原型. Every `3.N` heading and its five subheadings must occur after section three starts and before section four starts; a syntactically complete block after section six is invalid. The six mandatory PRD sections and required tables are validated over the indexed logical document. Every mandatory heading and table has exactly one owner and appears in canonical order after logical concatenation.

### 7.2 Proposal

A representative split proposal is:

```text
proposal/
├── 00-index.md
├── 01-why.md
├── 10-changes-<scope>.md
├── 50-capabilities.md
├── 80-out-of-scope.md
└── 90-impact.md
```

One complete numbered change point stays in one file and must occur between `## What Changes` and `## Capabilities`. Why, Capabilities, Out of Scope, and Impact each have one owner. Impact may group affected modules by end or subsystem but must not repeat What Changes content. The indexed logical proposal preserves the mandatory template order.

### 7.3 Design

Backend design fragments follow independently readable contract or subsystem boundaries, such as architecture decisions, data model, services/domain logic, API/permissions, and testing/rollout. Frontend design fragments follow page structure, component tree, state/API, style, interaction, and Visual Checks boundaries.

One model, API, permission, integration contract, UI mapping, or visual acceptance contract has one detailed owner. Other fragments reference that owner rather than copying the definition. `design/00-index.md` is metadata-only: one H1, optional short canonical-entry navigation links, the exact `## Canonical End Entrypoints` section/table, and no requirements, contracts, decisions, or detailed design sections.

Whenever at least one design end exists, `design/00-index.md` is required and its `End / Canonical entrypoint / Mode` rows must exactly match every and only the actual end representations.

### 7.4 Plan

A representative split backend plan is:

```text
tasks/backend/
├── 00-index.md
├── 01-context-and-constraints.md
├── 02-interface-ledger.md
├── 10-domain-tasks.md
├── 20-api-tasks.md
├── 30-integration-tasks.md
└── 90-coverage.md
```

Context, interface ledger, task groups, and coverage each have one owner. Every executable task has one stable `backend-NNN` or `frontend-NNN` ID and exactly one checkbox in one task-kind fragment. IDs continue across fragments and do not restart. Index, context, interface-ledger, coverage, and overview files contain no executable task checkbox.

Every split plan manifest has exactly one `context`, exactly one `interface`, exactly one `coverage`, and one or more `tasks` rows; other Kind values are invalid.

The end-local index owns end-local file order and task ranges. Every task block owns exactly one `Depends on` declaration. Consumers derive the full same-end and cross-end graph from task-owner files, reject every missing ID or cycle, then validate any overview edges/stages against that graph. Overview progress totals are recomputed from owner checkboxes.

## 8. Resolution and Historical Layout Rejection

The shared resolver contract lives in `skills/_shared/artifact-layout.md` and is referenced by every relevant producer and consumer.

Resolution for a logical artifact is:

1. Detect the small file and split-directory index.
2. If exactly one canonical form exists, resolve it.
3. For split form, read `00-index.md` and all manifest fragments in exact order.
4. Reject missing indexes, missing listed fragments, unindexed Markdown fragments, duplicate ownership, or size-limit violations.
5. Reject every historical or dual layout before reading artifact content.

`fp-plan` applies this resolver to proposal and each design end before reading either alternative. Split input is the complete manifest-ordered logical content, never a stable-file hint or body link. It passes resolved logical content, canonical entrypoint, mode, and ordered fragment paths to the backend/frontend child planner, which verifies the handoff against disk.

SDD task briefs and review packages record resolution per logical artifact in a map/table (`PRD`, `Proposal`, both design ends, and both plan ends), so mixed small/split changes never collapse into one singular resolution mode.

Unsupported layouts include:

- root-level `design-backend.md` / `design-frontend.md`;
- the former stable-file-plus-directory split form, such as `tasks/plan-backend.md` plus `tasks/backend/`, or `design/backend.md` plus `design/backend/`.
- simultaneous `prd.md` plus `prd/`, or `proposal.md` plus `proposal/`.

Consumers and Producers apply the same absolute mutual-exclusion rule and do not parse old index or overview grammars. Revising an unsupported artifact requires an explicitly approved migration that merges or transfers required content into exactly one canonical form, deletes every obsolete path, and validates the result before work continues.

## 9. `fp-prd` Trigger Contract

The `fp-prd` discovery description becomes:

```yaml
description: Use when a user explicitly invokes /fp-prd or $fp-prd, or explicitly asks to create, write, revise, or complete a PRD or product requirements document.
```

Repository guidance and command metadata must agree:

`Use fp-prd only when the user explicitly invokes /fp-prd or $fp-prd, or explicitly asks to create, write, revise, or complete a PRD or product requirements document.` is the exact public cross-surface trigger sentence used by AGENTS, README, the user guide, and Codex `longDescription`.

- explicit `/fp-prd` and `$fp-prd` trigger the skill;
- explicit natural-language requests to create, write, revise, or complete a PRD/product requirements document trigger the skill; and
- ordinary ideas, pain points, feature requests, development goals, bug fixes, repository maintenance, and `/goal` do not trigger it merely because they contain a rough requirement.

`fp-prd-grill-me` remains a required dependency after `fp-prd` is selected; it does not independently broaden discovery.

## 10. Validation Strategy

### 10.1 Repository contract validation

`scripts/validate-plugin.ps1` verifies that:

- all relevant skills reference the shared artifact-layout contract;
- producer rules contain file-or-directory mutual exclusion;
- no producer retains the stable-file-plus-split-directory output rule;
- task consumers resolve both canonical forms and reject every historical or dual layout;
- the `fp-prd` frontmatter uses the explicit trigger contract and no longer advertises ordinary ideas, pain points, feature requests, or rough requirements as triggers; and
- command adapters and user documentation use the new paths and limits.

### 10.2 Artifact layout validation

A deterministic validator and test script cover:

- valid small and valid split forms for all four stages;
- conflicting file and directory forms;
- missing `00-index.md`;
- missing listed fragments and unindexed fragments;
- files above 500 lines or 30,000 characters;
- duplicate content owners;
- duplicate task IDs or checkboxes;
- task checkboxes in index, context, interface-ledger, coverage, or overview files;
- incomplete or misordered logical PRD/proposal template structure in either small or manifest-concatenated split form;
- missing, extra, or mismatched `design/00-index.md` end mappings;
- detailed requirements, contracts, decisions, or design sections inside the metadata-only `design/00-index.md`;
- split plan Kind cardinality other than exactly one context/interface/coverage and one-or-more tasks rows;
- single-end plans with an invalid overview;
- two-end plans missing an overview;
- incorrect overview end entries or derived progress, old all-task overview schemas, invalid same-end/cross-end references, or dependency cycles; and
- missing, reversed, duplicate, unknown, same-end/self, or owner-graph-absent cross-end edges, including a stage section used without the required edge declarations; and
- historical and dual layouts rejected in both Consumer and Producer modes, with all conflicting paths reported.

The validator is stage-aware: it validates only artifact stages that currently exist and does not require later phases in an in-progress change.

### 10.3 Fresh-context trigger regression

Post-change forward tests use fresh contexts for three cases:

1. `/fp-prd ...` must select the PRD skill chain.
2. “请编写正式 PRD” must select the PRD skill chain.
3. An ordinary implementation request or repository-maintenance `/goal` must not select `fp-prd`.

The pre-change baseline already proves case 3 fails under the current description while cases 1 and 2 select the intended chain.

## 11. Implementation Surface

The implementation updates:

- `skills/_shared/workspace-rules.md` and a new shared artifact-layout reference;
- PRD, proposal, brainstorm, plan, backend-plan, and frontend-plan producer skills and templates;
- start orchestration and all design/task consumers;
- execute, execute-sdd, review, and archive resolution rules;
- Figma, UI-spec, and UX-spec design path rules;
- thin command adapters;
- `AGENTS.md`, `README.md`, and the user guide;
- plugin validation; and
- deterministic artifact-layout validation and tests.

Existing unrelated worktree changes are preserved. The external example is evidence for the design, not an implementation target of this repository change.

## 12. Acceptance Criteria

1. New large backend/frontend plans use only `tasks/backend/` and/or `tasks/frontend/`; they do not create the corresponding `plan-*.md` files.
2. New large designs use only the end directory; they do not create the corresponding end `.md` file.
3. Large PRD and proposal artifacts have indexed directory forms and retain their mandatory logical template structures.
4. All four stages split semantically and enforce the 500-line / 30,000-character fallback limits on every file.
5. `tasks/00-overview.md` exists only for two-end plans and contains no end-local duplication or task checkbox.
6. Every indexed artifact has complete, deterministic, non-duplicative fragment ownership.
7. All downstream skills resolve small and split canonical layouts through one shared contract.
8. Historical and dual layouts are unreadable in both Consumer and Producer modes until migrated to exactly one canonical form.
9. Ordinary feature, bugfix, repository-maintenance, and `/goal` requests no longer auto-trigger `fp-prd`.
10. Explicit command and explicit PRD-authoring requests still trigger `fp-prd`.
11. Repository and artifact-layout validation tests pass without modifying the user's existing staged change.
