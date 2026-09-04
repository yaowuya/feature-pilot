# FeaturePilot Final Review Package Template

Use this template for `.fp-execute/packages/final-review-package.md` before dispatching `fp-final-review`. The package is deterministic review evidence, not completion authority: canonical task-owner checkboxes remain planned-completion authority and the progress ledger remains recovery/orchestration evidence.

Before creating or resuming an SDD final-review package in `pending-dispatch`, `review-completed`, `result-committed`, `fixing`, or `complete`, read `${CLAUDE_PLUGIN_ROOT}/skills/fp-final-review/final-review-contract.md` once. It owns shared review identity, HEAD, resume, scope, gate, Figma/Visual, and UI/E2E schemas; this template owns package evidence.

# Final Review Package: <slug>

## Review Identity

- reviewScopeId: `<stable final scope id>`
- reviewAttempt: `<1 | 2 | 3>`
- maxReviewAttempts=3
- priorReviewPath: `<path or N/A>`
- priorFindingDispositions: `<finding id -> unresolved | fixed with evidence | accepted non-blocking debt>`
- finalReviewPackage: `<this exact path>`
- lastReviewedHead: `<reviewedTargetHead from the completed prior attempt or N/A for attempt 1>`
- reviewedTargetHead: `<committed clean product/change target SHA>`
- packageParentHead: `<same SHA as reviewedTargetHead>`
- evidenceCommitHead: `POST_COMMIT_EXTERNAL`
- dispatchHead: `POST_COMMIT_EXTERNAL`
- reviewPhase at package creation: `pending-dispatch`
- runtime reviewPhase: `<external pending-dispatch | review-completed | result-committed | fixing | complete>`
- Review mode: `<direct independent final scope | SDD-owned final scope>`

The same SDD final scope keeps one stable `reviewScopeId`; a new reviewer, new commit, new session, or new finding never resets `reviewAttempt`. Never dispatch attempt 4.

This avoids commit self-reference. The package must not embed its own exact evidenceCommitHead or dispatchHead because neither exists before the evidence-only commit. The controller resolves both externally after commit and passes them as fp-final-review runtime inputs. Use the sentinel exactly and never rewrite the package merely to insert either SHA.

## Deterministic Git Evidence

- Repository root: `<canonical root>`
- Change path: `<canonical change path>`
- Base ref: `<ref>`
- Base SHA: `<sha>`
- Merge base: `<sha>`
- Head ref: `reviewedTargetHead`
- reviewedTargetHead: `<sha>`
- packageParentHead: `<same sha; packageParentHead = reviewedTargetHead>`
- evidenceCommitHead: `POST_COMMIT_EXTERNAL`
- dispatchHead: `POST_COMMIT_EXTERNAL`
- Last reviewed head: `<sha or N/A>`
- Baseline target range: `<merge-base>...<reviewedTargetHead>`
- Logical incremental range at target checkpoint: `lastReviewedHead..HEAD` (`N/A` for attempt 1)
- Persisted incremental target range: `lastReviewedHead..<reviewedTargetHead>` (`N/A` for attempt 1)
- target dirty fingerprint: `CLEAN`
- Expected evidence-only paths: `<final package path; allowed pending ledger evidence path>`
- External runtime verification: `<reviewedTargetHead..dispatchHead; evidenceCommitHead == dispatchHead == current git HEAD; dispatch tree CLEAN>`

## Dispatch Commit and Phase-aware Resume

Apply `Review Identity and Phase` from `final-review-contract.md`. Record parent/count/allowed-delta, ancestry, phase-successor, and external-SHA evidence in `Deterministic Git Evidence`; the package keeps `POST_COMMIT_EXTERNAL` and never rewrites itself with its own SHA.

## Changed Paths

Record the sorted complete branch inventory/counts at reviewedTargetHead; do not silently drop an unowned diff. The runtime reviewer separately verifies the evidence-only delta after dispatch.

| Path | Source | Relevant change owner(s) | Review disposition |
| --- | --- | --- | --- |
| `<path>` | `<baseline target diff | incremental target diff>` | `<change contract(s) or unowned>` | `<mapped-current | cross-change-only | shared | unowned/unmapped; review reason>` |

## Scope Matrix

Apply `Scope and Ownership` from `final-review-contract.md`; the table below is the package evidence projection.

| Declared path/contract | Observed diff path | Mapping | Classification | Relevant change owner | Evidence |
| --- | --- | --- | --- | --- | --- |
| `<artifact item/path or N/A>` | `<changed path or N/A>` | `<declared | observed | mapped | unmapped | missing>` | `<mapped-current | cross-change-only | shared | unowned/unmapped | missing>` | `<selected slug, other proven slug(s), shared, or unowned>` | `<artifact/owner/diff/source/test proof>` |

Populate every branch-inventory row under the shared scope rule; this package does not decide the selected-change verdict.

## Owner Discovery Evidence

Apply the bounded lookup and ownership classification from `Scope and Ownership` in `final-review-contract.md`; record package inputs in the projection below.

| Path | Candidate lookup | Canonical owner proof | Resolved owners | Classification |
| --- | --- | --- | --- | --- |
| `<exact normalized path>` | `<query, matching sibling active changes, budget>` | `<canonical entry/excerpt or none>` | `<selected/other/shared/unowned>` | `<mapped-current/cross-change-only/shared/unowned-unmapped>` |

## Every-Attempt Gates

Apply `Every-Attempt Gates` from `final-review-contract.md`; package rows collect readiness evidence on attempts 1..3.

| Gate | Result | Evidence |
| --- | --- | --- |
| canonical structure | `<PASS | FAIL | BLOCKED>` | `<canonical small/split resolution>` |
| snapshot/working-tree | `<PASS | FAIL | BLOCKED>` | `<HEAD and dirty fingerprint>` |
| scope/out-of-scope | `<PASS | FAIL | BLOCKED>` | `<Scope Matrix and artifact evidence>` |
| task ownership/dependencies | `<PASS | FAIL | BLOCKED>` | `<unique owner and dependency evidence>` |
| evidence freshness | `<PASS | FAIL | BLOCKED>` | `<current source/config/test proof>` |
| command safety | `<PASS | FAIL | BLOCKED>` | `<classification table below>` |

Record baseline/incremental ranges and unresolved-finding inputs under the shared review identity contract; this package supplies evidence for, but never replaces, the independent gate results.

## Command Safety

Apply `Command Safety` from `final-review-contract.md`; populate the package projection without executing `UNSAFE` or `UNKNOWN` commands.

| Command | Classification | Definition inspected | Mutation reason / safe proof | Result |
| --- | --- | --- | --- | --- |
| `<exact command>` | `SAFE | UNSAFE | UNKNOWN` | `<path/line or N/A>` | `<proof or reason>` | `<PASS | FAIL | SKIPPED>` |

The package records definition evidence and the resulting `PASS | FAIL | SKIPPED`; command classification remains governed by the shared contract.

## CodeGraph Candidate Evidence

Apply `CodeGraph Candidate Verification` from `final-review-contract.md`; this table records candidate and current-source/native proof inputs.

| Query/helper | Candidate paths/symbols | Current-source verification | Native search/test/command proof | Fallback |
| --- | --- | --- | --- | --- |
| `<query or N/A>` | `<candidates or N/A>` | `<current source/diff evidence>` | `<caller/import search, test, or command output>` | `<native search used when missing/stale/unavailable>` |

Record the native fallback used when graph evidence is unavailable; the shared contract owns its non-blocking and proof semantics.

## Prior Finding Dispositions

| Finding ID | Prior severity | Prior evidence | Current disposition | Fresh evidence |
| --- | --- | --- | --- | --- |
| `<stable id>` | `<severity>` | `<prior report path:line>` | `<unresolved | fixed | accepted non-blocking debt>` | `<current source/test/command>` |

## Validation Evidence

| Requirement / risk | Safe command or inspection | Result | Current evidence |
| --- | --- | --- | --- |
| `<contract>` | `<SAFE command or read-only inspection>` | `<PASS | FAIL | SKIPPED>` | `<output/path:line>` |

## Figma Capability and Preservation Evidence

- Figma preservation contract: `<.fp-execute/figma-preservation.md or N/A>`
- Figma capability ledger: `<.fp-execute/figma-capabilities.md or N/A>`
- Figma independent review: `<.fp-execute/reviews/*-figma-review.md or N/A>`
- Browser capability resolution: `<project runner | Playwright browser extension | local playwright-cli | customer choice pending | unavailable>`

| ID | Required observable result / existing behavior | Owner task/file | Before baseline | After replay | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| `FIGCAP-001` or `PRES-001` | `<contract>` | `<task/path>` | `<N/A or command/result>` | `<command/result>` | `PASS | FAIL | CANNOT_VERIFY | BLOCKED` | `<artifact/review>` |

## Figma Completion Gate

Figma Completion Status: `COMPLETE | INCOMPLETE | BLOCKED`

Apply `Figma Capability and Preservation` from `final-review-contract.md`; record package readiness evidence without issuing the independent final verdict.

## Visual Evidence

For every planned frontend/UI Case ID, resolve the case manifest and carry its evidence into this deterministic package.

| Case ID | Approved design source | Figma node | revision/time | Frame/variant | variables / Auto Layout / assets | Runtime route | Scenario/state | Viewport | DPR | Locale | Theme | Deterministic non-sensitive fixture | Reference path | Current path | Diff path / missing diff | Mask | Acceptance rule | Command/tool | Failure class | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| <case-id> | <approved Figma/static design source> | <node or N/A> | <revision/time or approved-source time> | <frame/variant> | <available context or N/A> | <real target runtime route> | <scenario/state> | <viewport> | <DPR> | <locale> | <theme> | <stable fixture; no secrets or production/customer data> | .fp-execute/visual/<task-id>/<case-id>/reference.png | .fp-execute/visual/<task-id>/<case-id>/current.png | .fp-execute/visual/<task-id>/<case-id>/diff.png or N/A: <missing diff explanation> | <mask> | <case-specific rule> | <project-configured replay command/tool> | <core visual/non-core cosmetic> | <PASS/FAIL/CANNOT_VERIFY> |

- Case artifacts: .fp-execute/visual/<task-id>/<case-id>/manifest.md, reference.png, current.png, and optional diff.png.
- Apply `Visual Evidence` from `final-review-contract.md` for provenance, channel separation, verdict, and blocker/debt semantics.
Visual evidence: PASS | FAIL | CANNOT_VERIFY

## UI Case Inventory / N/A Reconciliation

Apply `UI Case Inventory / N/A Reconciliation` from `final-review-contract.md`; the table below records package reconciliation inputs.

| Source owner / diff evidence | UI classification | Task ID | Case ID | Disposition |
| --- | --- | --- | --- | --- |
| `<task/design/Figma/diff evidence>` | `UI-bearing / non-UI` | `<task-id or N/A>` | `<case-id or N/A>` | `<mapped / FAIL / BLOCKED>` |

Record the inventory evidence needed for the shared `N/A` predicate; the package does not decide that predicate.

## UI/E2E Gate

Apply `UI/E2E Gate` from `final-review-contract.md`; join package evidence by exact Task ID + Case ID and reference, rather than copy, Visual Evidence fields.

**UI/E2E Gate:** PASS | N/A | FAIL | BLOCKED

| Task ID | Case ID | UI Delivery Level | Required stage | Actual stage | Visual evidence reference | E2E applicability / result | Matrix / evidence paths | Mocked Core API | Cleanup | Business result | Blocking condition |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `<task-id>` | `<case-id>` | `static-only / interactive / business-flow` | `<required lifecycle path>` | `<last completed stage>` | `<Visual Evidence row + manifest path>` | `<REQUIRED/N/A + PASS/FAIL/BLOCKED>` | `.fp-execute/e2e/<task-id>/<case-id>/coverage-matrix.md; <artifacts>` | `false / N/A` | `<result/path or N/A>` | `<real persistence/permission result or N/A>` | `<None or exact core gap + repair owner>` |

- Record level-specific readiness, real-browser evidence, zero-mock proof, cleanup/business result, and repair owner under the shared gate; the package cannot grant `PASS`, `N/A`, debt, approval, or waiver.

## Ledger Cross-check

- Progress ledger: `<path or N/A>`
- Owner-checkbox reconciliation: `<evidence>`
- Review attempt event: `<scope id, attempt, head, prior report, disposition>`
- Completion authority reminder: `<package does not determine completion>`
