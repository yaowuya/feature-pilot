# FeaturePilot Final Review Shared Contract

This file is the single source of truth for meanings and schemas shared by the SDD final-review package and the independent final-review report. Package creation collects deterministic evidence; report writing judges that evidence. Neither artifact is completion authority.

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` for project-root, resource, information-layer, language, and evidence precedence.

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` for canonical artifact resolution and structural rejection.

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/ui-e2e-contract.md` once when final review includes UI-bearing scope; it owns the UI lifecycle and non-waiver policy, while this file projects only final-review fields.

Local package/report templates retain their own headings, metadata, evidence rows, findings, and verdict output. Every local table shell below is a checked projection of this contract rather than an independent definition.

## Review Identity and Phase

One final-review scope has one stable `reviewScopeId`, `reviewAttempt` in `1..3`, and `maxReviewAttempts=3`. Reviewer, commit, session, compaction, restart, or finding identity never resets the scope; attempt 4 is invalid.

Shared HEAD meanings:

- `reviewedTargetHead`: committed clean product/change snapshot being reviewed.
- `packageParentHead`: parent of the SDD evidence-only package commit; in SDD it equals `reviewedTargetHead`.
- `evidenceCommitHead`: exact evidence-only commit resolved outside the package; direct mode uses `N/A`.
- `dispatchHead`: exact clean reviewer-dispatch commit; direct mode uses `HEAD`.
- `lastReviewedHead`: target of the completed prior attempt, or `N/A` for attempt 1.

When `reviewPhase=N/A-direct`, record the SDD dispatch checks as `N/A-direct`. Require `reviewedTargetHead=packageParentHead=dispatchHead=HEAD` and `evidenceCommitHead=N/A`. Do not run the SDD parent/count/allowed-delta assertions in direct mode. Use current working-tree evidence.

SDD phase values are `pending-dispatch`, `review-completed`, `result-committed`, optional `fixing`, and `complete`:

- `pending-dispatch`: current clean HEAD is the unique direct child of packageParentHead; externally resolve `evidenceCommitHead=dispatchHead=current HEAD`.
- `review-completed`: historical dispatchHead remains the current committed HEAD; only final report/result-ledger paths may be uncommitted; persist the result before advancing.
- `result-committed`, `fixing`, or `complete`: must not set dispatchHead=current HEAD. Retain historical `dispatchHead`, require dispatchHead is an ancestor of current HEAD, and verify successors after dispatchHead against phase-allowed result evidence/fix paths; any other path is `BLOCKED`.

For every SDD phase, verify `dispatchHead^ == packageParentHead`, `rev-list --count packageParentHead..dispatchHead == 1`, the original allowed package/pending-ledger paths, product source unchanged across that delta, and the clean dispatch checkpoint. At dispatch, run `git rev-parse <dispatchHead>^`, `git rev-list --count <packageParentHead>..<dispatchHead>`, and `git diff --name-only <packageParentHead>..<dispatchHead>` independently. The result commit records the prior dispatchHead and does not record its own SHA.

Attempt 1 establishes complete baseline evidence. Attempts 2/3 retain unresolved findings, logical `lastReviewedHead..HEAD`, persisted `lastReviewedHead..<reviewedTargetHead>`, affected contracts/tests/package/ledger, and all every-attempt gates.

## Scope and Ownership

Base inventory semantics are `declared`, `observed`, `mapped`, `unmapped`, and `missing`. Verdict classifications are:

- `mapped-current`: proven owner is the selected change; it affects the current verdict.
- `cross-change-only`: explicit artifact/owner evidence proves another change owns the path and it does not support the selected change; retain it in branch inventory/counts. It is excluded from the current change verdict.
- `shared`: selected and other proven changes own obligations; review against every relevant contract and include selected-change defects in the current verdict.
- `unowned/unmapped`: ownership cannot be proven; record a scope finding that affects the current verdict.
- `missing`: declared selected-change scope has no observed/current-source realization.

Review the complete branch inventory first. Compute the selected-change verdict from mapped-current scope, selected-change shared obligations, missing selected-change scope, and unowned/unmapped risk.

Canonical Scope Matrix projection:

| Declared path/contract | Observed diff path | Mapping | Classification | Relevant change owner | Evidence |
| --- | --- | --- | --- | --- | --- |
| `<artifact item/path or N/A>` | `<changed path or N/A>` | `declared / observed / mapped / unmapped / missing` | `mapped-current / cross-change-only / shared / unowned/unmapped / missing` | `<selected slug, other proven slug(s), shared, or unowned>` | `<artifact/owner/diff/current source/test>` |

### Owner Discovery Evidence

Build the owner inventory from selected change canonical artifacts: proposal/design scope, canonical task-owner `Files`/scope entries, and selected evidence package/ledger Scope Matrix. Only for selected-unmapped observed paths, derive the exact normalized path and perform one fixed-string candidate lookup across direct sibling active changes under `fp-docs/changes/`. Do not search archive/history and must not bulk-read all changes.

Search only canonical task-owner `Files`/scope entries and existing evidence package/ledger Scope Matrix rows. An exact hit creates a candidate change; only then resolve canonical-first and read minimal proposal/design/task-owner excerpts. Lookup budget: one query, at most eight candidate changes, and one matching owner fragment plus relevant contract excerpts per candidate. If lookup budget or owner evidence is insufficient/cannot be proven, use `unowned/unmapped`.

Canonical Owner Discovery projection:

| Path | Candidate lookup | Canonical owner proof | Resolved owners | Classification |
| --- | --- | --- | --- | --- |
| `<exact normalized path>` | `<query, hits, budget>` | `<canonical entry/excerpt or none>` | `<selected/other/shared/unowned>` | `<mapped-current/cross-change-only/shared/unowned-unmapped>` |

## Every-Attempt Gates

Every attempt reruns exactly these gates:

| Gate | Result | Evidence |
| --- | --- | --- |
| canonical structure | PASS / FAIL / BLOCKED | `<evidence>` |
| snapshot/working-tree | PASS / FAIL / BLOCKED | `<evidence>` |
| scope/out-of-scope | PASS / FAIL / BLOCKED | `<evidence>` |
| task ownership/dependencies | PASS / FAIL / BLOCKED | `<evidence>` |
| evidence freshness | PASS / FAIL / BLOCKED | `<evidence>` |
| command safety | PASS / FAIL / BLOCKED | `<evidence>` |

Package rows collect readiness evidence. Report rows contain the independent reviewer result. A package `PASS` value never supplies the report judgment.

## Command Safety

Classify every proposed command as `SAFE`, `UNSAFE`, or `UNKNOWN` after inspecting its script, alias, wrapper, and configuration. Run only a proven read-only `SAFE` variant. `UNSAFE` and `UNKNOWN` are `SKIPPED` with the resulting evidence gap.

Commands such as `--fix`, `--write`, snapshot update, migration, seed, formatter, generator, cache, coverage, dist, unknown wrapper, service startup, database mutation, and external mutation are `UNSAFE` or `UNKNOWN` and must not run until a non-mutating variant is proved. A dry-run label is not proof.

Canonical report projection:

| Command | Safety | Definition evidence | Result | Notes |
| --- | --- | --- | --- | --- |
| `<command>` | SAFE / UNSAFE / UNKNOWN | `<script/wrapper/config path or N/A>` | PASS / FAIL / SKIPPED | `<key output or reason>` |

Canonical package projection:

| Command | Classification | Definition inspected | Mutation reason / safe proof | Result |
| --- | --- | --- | --- | --- |
| `<exact command>` | `SAFE | UNSAFE | UNKNOWN` | `<path/line or N/A>` | `<proof or reason>` | `<PASS | FAIL | SKIPPED>` |

## CodeGraph Candidate Verification

Apply the `Review candidate-only contract` from `${CLAUDE_PLUGIN_ROOT}/skills/_shared/codegraph.md`; this section owns only the package/report projections below.

Canonical report projection:

| Query/helper | Candidates | Current-source verification | Native search / test / command evidence | Fallback |
| --- | --- | --- | --- | --- |
| `<query>` | `<candidate paths/symbols>` | `<verified lines or rejected>` | `<evidence>` | `<none or native fallback>` |

Canonical package projection:

| Query/helper | Candidate paths/symbols | Current-source verification | Native search/test/command proof | Fallback |
| --- | --- | --- | --- | --- |
| `<query>` | `<candidates>` | `<current-source lines or rejected>` | `<proof>` | `<none or native fallback>` |

## Figma Capability and Preservation

For Figma-derived UI scope, every required `FIGCAP-*` has source requirement, unique task/file owner, browser-observable result, and evidence. Every core `PRES-*` has before baseline, after replay under the same stable conditions, or an approved explicit exception.

Canonical coverage projection:

| ID | Source / required observable result | Owner task/file | Runtime evidence | Status | Review evidence |
| --- | --- | --- | --- | --- | --- |
| `FIGCAP-001` or `PRES-001` | `<contract>` | `<path/task>` | `<command/artifact>` | `PASS | FAIL | CANNOT_VERIFY | BLOCKED` | `<review path>` |

Canonical package projection:

| ID | Required observable result / existing behavior | Owner task/file | Before baseline | After replay | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `FIGCAP-001` or `PRES-001` | `<contract>` | `<task/path>` | `<N/A or command/result>` | `<command/result>` | `PASS | FAIL | CANNOT_VERIFY | BLOCKED` | `<artifact/review>` |

Figma Completion Status: `COMPLETE | INCOMPLETE | BLOCKED`. `COMPLETE` requires every required `FIGCAP-*`, core `PRES-*`, and core Visual Case to be `PASS` with no unapproved behavior change. Any required `FIGCAP-*`, core `PRES-*`, or core Visual Case status of `INCOMPLETE`, `CANNOT_VERIFY`, `FAIL`, or `BLOCKED` makes the final verdict `FAIL` or `BLOCKED`; it cannot become `PASS`, `PASS_WITH_NOTES`, review debt, manual approval, or waiver.

## Visual Evidence

Canonical Visual Evidence projection:

| Case ID | Approved design source | Figma node | revision/time | Frame/variant | variables / Auto Layout / assets | Runtime route | Scenario/state | Viewport | DPR | Locale | Theme | Deterministic non-sensitive fixture | Reference path | Current path | Diff path / missing diff | Mask | Acceptance rule | Command/tool | Failure class | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `<case-id>` | `<approved Figma/static design source>` | `<node or N/A>` | `<revision/time or approved-source time>` | `<frame/variant>` | `<available context or N/A>` | `<real target runtime route>` | `<scenario/state>` | `<viewport>` | `<DPR>` | `<locale>` | `<theme>` | `<stable fixture; no secrets or production/customer data>` | `.fp-execute/visual/<task-id>/<case-id>/reference.png` | `.fp-execute/visual/<task-id>/<case-id>/current.png` | `.fp-execute/visual/<task-id>/<case-id>/diff.png` or `N/A: <missing diff explanation>` | `<mask>` | `<case-specific rule>` | `<project-configured replay command/tool>` | `<core visual/non-core cosmetic>` | `<PASS/FAIL/CANNOT_VERIFY>` |

Provenance: reference.png -> approved Figma/static design source; current.png -> real target runtime.

Local runtime screenshot must not replace reference.png. current.png requires stable data and stable environment. Optional diff/missing diff explanation must not hide absent core source/runtime evidence.

Evidence channels: browser interaction evidence is separate from screenshot evidence; browser interaction evidence must exercise approved states, and screenshot evidence must record case artifacts.

Record exactly `Visual evidence: PASS | FAIL | CANNOT_VERIFY`. Core source/runtime missing is CANNOT_VERIFY and a main-flow blocker; it never becomes review debt. At attempt 3, only a reproducible non-core cosmetic FAIL difference may become review debt; all other non-core FAIL/CANNOT_VERIFY cases are BLOCKER.

## UI Case Inventory / N/A Reconciliation

Before the UI/E2E gate, reconcile the reviewed target snapshot against task-owner Files/task text, frontend design components/interactions/Visual Checks, Figma `FIGCAP-*`/`PRES-*` mappings, and mapped-current/shared/unowned frontend diff. Every UI-bearing source maps to one Task ID + Case ID + Delivery Contract; an unmapped source is `FAIL` or `BLOCKED`.

Canonical inventory projection:

| Source owner / diff evidence | UI classification | Task ID | Case ID | Disposition |
| --- | --- | --- | --- | --- |
| `<task/design/Figma/diff evidence>` | `UI-bearing / non-UI` | `<task-id or N/A>` | `<case-id or N/A>` | `<mapped / FAIL / BLOCKED>` |

`N/A` is valid only when the inventory proves zero UI-bearing sources, no Figma UI scope, no mapped-current or unowned frontend diff, and evidence covers the reviewed target snapshot.

## UI/E2E Gate

Resolve every UI case by exact Task ID + Case ID and reference the Visual Evidence Manifest without copying its fields.

Canonical gate projection:

| Task ID | Case ID | UI Delivery Level | Required stage | Actual stage | Visual evidence reference | E2E applicability / result | Matrix / evidence paths | Mocked Core API | Cleanup | Business result | Blocking condition |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `<task-id>` | `<case-id>` | `static-only / interactive / business-flow` | `<required lifecycle path>` | `<last completed stage>` | `<Visual Evidence row + manifest path>` | `<REQUIRED/N/A + PASS/FAIL/BLOCKED>` | `.fp-execute/e2e/<task-id>/<case-id>/coverage-matrix.md; <artifacts>` | `false / N/A` | `<result/path or N/A>` | `<real persistence/permission result or N/A>` | `<None or exact core gap + repair owner>` |

Apply delivery-level, real-browser, zero-mock, business-result, cleanup, retry, and non-waiver semantics from `${CLAUDE_PLUGIN_ROOT}/skills/_shared/ui-e2e-contract.md`; this section only projects final-review evidence and result fields.

UI/E2E Gate is exactly `UI/E2E Gate: PASS | N/A | FAIL | BLOCKED`. `N/A` remains governed by the reconciled inventory above. Any upstream core blocker maps to `FAIL` or `BLOCKED`, names its repair owner, and cannot become `PASS`, `PASS_WITH_NOTES`, review debt, manual override, or waiver.
