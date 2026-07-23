# FeaturePilot Final Review Package Template

Use this template for `.fp-execute/packages/final-review-package.md` before dispatching `fp-review`. The package is deterministic review evidence, not completion authority: canonical task-owner checkboxes remain planned-completion authority and the progress ledger remains recovery/orchestration evidence.

```markdown
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

This avoids commit self-reference. The package must not embed its own exact evidenceCommitHead or dispatchHead because neither exists before the evidence-only commit. The controller resolves both externally after commit and passes them as fp-review runtime inputs. Use the sentinel exactly and never rewrite the package merely to insert either SHA.

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

At SDD dispatch, independently record the results of `git rev-parse <dispatchHead>^`, `git rev-list --count <packageParentHead>..<dispatchHead>`, and `git diff --name-only <packageParentHead>..<dispatchHead>`. Require `dispatchHead^ == packageParentHead`, `rev-list --count packageParentHead..dispatchHead == 1`, and only allowed package/pending-ledger paths.

- `pending-dispatch`: current clean HEAD is the unique direct child of packageParentHead; external runtime resolves `evidenceCommitHead=dispatchHead=current HEAD`.
- `review-completed`: historical dispatchHead remains the current committed HEAD; only final report/result-ledger paths may be uncommitted, and the controller must persist the result before advancing.
- `result-committed` or later: must not set dispatchHead=current HEAD. Record `git merge-base --is-ancestor <dispatchHead> HEAD` proving dispatchHead is an ancestor of current HEAD, repeat the parent/count/allowed-delta checks, then record `git diff --name-only <dispatchHead>..HEAD`. For successors after dispatchHead, result/complete allow final report/result-ledger evidence only; fixing additionally allows exact finding-authorized source/tests/fix evidence. Any other phase-allowed result evidence/fix paths violation is `BLOCKED`.

The result commit records the prior dispatchHead and does not record its own SHA; its current SHA is external. Direct mode sets `reviewPhase=N/A-direct` and all evidence-commit checks are `N/A`.

## Changed Paths

Record the sorted complete branch inventory/counts at reviewedTargetHead; do not silently drop an unowned diff. The runtime reviewer separately verifies the evidence-only delta after dispatch.

| Path | Source | Relevant change owner(s) | Review disposition |
| --- | --- | --- | --- |
| `<path>` | `<baseline target diff | incremental target diff>` | `<change contract(s) or unowned>` | `<mapped-current | cross-change-only | shared | unowned/unmapped; review reason>` |

## Scope Matrix

Base semantics remain `declared`, `observed`, `mapped`, `unmapped`, `missing`, `shared`, and `cross-change`. Add a verdict class: `mapped-current` has proven ownership by the current selected change and affects the current verdict. `cross-change-only` requires explicit artifact/owner evidence for another identified change, remains in branch inventory/counts, and is excluded from the current change verdict. If owner evidence is insufficient or cannot be proven, classify `unowned/unmapped`; its scope finding affects the current verdict. `shared` supports current and other changes, is reviewed against each relevant change contract, and affects the current verdict for selected-change obligations.

| Declared path/contract | Observed diff path | Mapping | Classification | Relevant change owner | Evidence |
| --- | --- | --- | --- | --- | --- |
| `<artifact item/path or N/A>` | `<changed path or N/A>` | `<declared | observed | mapped | unmapped | missing>` | `<mapped-current | cross-change-only | shared | unowned/unmapped | missing>` | `<selected slug, other proven slug(s), shared, or unowned>` | `<artifact/owner/diff/source/test proof>` |

Review the complete branch inventory first; compute the selected change verdict only from mapped-current, selected-change shared obligations, missing selected-change scope, and unowned/unmapped risk.

## Owner Discovery Evidence

Build the owner inventory from selected change canonical artifacts first: proposal/design scope, canonical task-owner `Files`/scope entries, and selected evidence package/ledger Scope Matrix. Only for selected-unmapped observed paths, derive the exact normalized path and perform one fixed-string candidate lookup across direct sibling active changes in `fp-docs/changes/`. Do not search archive/history and must not bulk-read all changes.

Search only canonical task-owner `Files`/scope entries and existing evidence package/ledger Scope Matrix rows. An exact hit identifies a candidate change; only then resolve canonical-first and read minimal proposal/design/task-owner excerpts. Lookup budget: one query, at most eight candidate changes, and one matching owner fragment plus relevant contract excerpts per candidate. If lookup budget or owner evidence is insufficient/cannot be proven, use `unowned/unmapped`.

| Path | Candidate lookup | Canonical owner proof | Resolved owners | Classification |
| --- | --- | --- | --- | --- |
| `<exact normalized path>` | `<query, matching sibling active changes, budget>` | `<canonical entry/excerpt or none>` | `<selected/other/shared/unowned>` | `<mapped-current/cross-change-only/shared/unowned-unmapped>` |

## Every-Attempt Gates

Rerun these gates on attempts 1, 2, and 3, even when the incremental review is otherwise limited to unresolved findings and `lastReviewedHead..HEAD`.

| Gate | Result | Evidence |
| --- | --- | --- |
| canonical structure | `<PASS | FAIL | BLOCKED>` | `<canonical small/split resolution>` |
| snapshot/working-tree | `<PASS | FAIL | BLOCKED>` | `<HEAD and dirty fingerprint>` |
| scope/out-of-scope | `<PASS | FAIL | BLOCKED>` | `<Scope Matrix and artifact evidence>` |
| task ownership/dependencies | `<PASS | FAIL | BLOCKED>` | `<unique owner and dependency evidence>` |
| evidence freshness | `<PASS | FAIL | BLOCKED>` | `<current source/config/test proof>` |
| command safety | `<PASS | FAIL | BLOCKED>` | `<classification table below>` |

Attempt 1 records complete baseline target evidence. Attempts 2/3 collect logical `lastReviewedHead..HEAD`, persist `lastReviewedHead..<reviewedTargetHead>`, and inspect every unresolved finding plus affected contracts/tests, this finalReviewPackage, and the progress ledger, in addition to the every-attempt gates.

## Command Safety

Classify every proposed validation command before execution. `SAFE` is executable only after its script, alias, and wrapper definitions have been inspected and shown to be read-only. `UNSAFE` and `UNKNOWN` must not run; record a safe variant or the resulting evidence gap.

| Command | Classification | Definition inspected | Mutation reason / safe proof | Result |
| --- | --- | --- | --- | --- |
| `<exact command>` | `SAFE | UNSAFE | UNKNOWN` | `<path/line or N/A>` | `<proof or reason>` | `<PASS | FAIL | SKIPPED>` |

Treat `--fix`, `--write`, snapshot update, migration, seed, formatter, generator, cache, coverage, dist, unknown wrapper, service startup, database mutation, and external mutation as `UNSAFE` or `UNKNOWN`; they must not run. Use a proven safe variant only after inspecting its definitions.

## CodeGraph Candidate Evidence

CodeGraph `explore`, `impact`, and `affected` helpers produce candidates only. They are never current proof and must not block review.

| Query/helper | Candidate paths/symbols | Current-source verification | Native search/test/command proof | Fallback |
| --- | --- | --- | --- | --- |
| `<query or N/A>` | `<candidates or N/A>` | `<current source/diff evidence>` | `<caller/import search, test, or command output>` | `<native search used when missing/stale/unavailable>` |

If the graph is missing, stale, unavailable, or dirty, use native search against current source and continue. Do not treat graph output as finding evidence without current-source verification.

## Prior Finding Dispositions

| Finding ID | Prior severity | Prior evidence | Current disposition | Fresh evidence |
| --- | --- | --- | --- | --- |
| `<stable id>` | `<severity>` | `<prior report path:line>` | `<unresolved | fixed | accepted non-blocking debt>` | `<current source/test/command>` |

## Validation Evidence

| Requirement / risk | Safe command or inspection | Result | Current evidence |
| --- | --- | --- | --- |
| `<contract>` | `<SAFE command or read-only inspection>` | `<PASS | FAIL | SKIPPED>` | `<output/path:line>` |

## Visual Evidence

For every planned frontend/UI Case ID, resolve the case manifest and carry its evidence into this deterministic package.

| Case ID | Approved design source | Figma node | revision/time | Frame/variant | variables / Auto Layout / assets | Runtime route | Scenario/state | Viewport | DPR | Locale | Theme | Deterministic non-sensitive fixture | Reference path | Current path | Diff path / missing diff | Mask | Acceptance rule | Command/tool | Failure class | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| <case-id> | <approved Figma/static design source> | <node or N/A> | <revision/time or approved-source time> | <frame/variant> | <available context or N/A> | <real target runtime route> | <scenario/state> | <viewport> | <DPR> | <locale> | <theme> | <stable fixture; no secrets or production/customer data> | .fp-execute/visual/<task-id>/<case-id>/reference.png | .fp-execute/visual/<task-id>/<case-id>/current.png | .fp-execute/visual/<task-id>/<case-id>/diff.png or N/A: <missing diff explanation> | <mask> | <case-specific rule> | <project-configured replay command/tool> | <core visual/non-core cosmetic> | <PASS/FAIL/CANNOT_VERIFY> |

- Case artifacts: .fp-execute/visual/<task-id>/<case-id>/manifest.md, reference.png, current.png, and optional diff.png.
- Provenance: reference.png -> approved Figma/static design source; current.png -> real target runtime.
- Local runtime screenshot must not replace reference.png. current.png requires stable data and stable environment. Optional diff/missing diff explanation must not hide absent core source/runtime evidence.
- Evidence channels: browser interaction evidence is separate from screenshot evidence; browser interaction evidence must exercise approved states, and screenshot evidence must record case artifacts.
Visual evidence: PASS | FAIL | CANNOT_VERIFY
- Core blocker/debt: Core source/runtime missing is CANNOT_VERIFY and a main-flow blocker; it never becomes review debt. At attempt 3, only a reproducible non-core cosmetic FAIL difference may become review debt; all other non-core FAIL/CANNOT_VERIFY cases are BLOCKER.

## Ledger Cross-check

- Progress ledger: `<path or N/A>`
- Owner-checkbox reconciliation: `<evidence>`
- Review attempt event: `<scope id, attempt, head, prior report, disposition>`
- Completion authority reminder: `<package does not determine completion>`
```
