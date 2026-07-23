# Final FeaturePilot Review: <slug>

Resolution follows the artifact-layout contract already loaded by `fp-review`. This report records canonical-first Consumer evidence in manifest order and rejects every historical or dual structural conflict before review.

叙述性内容默认使用中文；代码、命令、路径、技术标识符、API 字段以及契约要求精确匹配的英文 schema 标题保留必要英文。若用户或目标项目设置明确指定其他语言，按共享优先级执行。

**Verdict:** PASS | PASS_WITH_NOTES | FAIL | BLOCKED
**Reviewer:** read-only fp-review
**Review Time:** YYYY-MM-DD HH:MM
**Base Ref:** <baseRef>
**Head Ref:** <headRef or sha>
**Change Path:** fp-docs/changes/<slug>
**Review Depth:** standard | strict
**Focus:** <focus or none>
**reviewScopeId:** <stable scope id>
**reviewAttempt:** <1 | 2 | 3>
**maxReviewAttempts=3**
**priorReviewPath:** <path or N/A>
**priorFindingDispositions:** <finding-id -> disposition or N/A>
**finalReviewPackage:** <path or N/A>
**lastReviewedHead:** <sha or N/A>
**reviewedTargetHead:** <product/change target sha>
**packageParentHead:** <target sha>
**evidenceCommitHead:** <external sha or N/A>
**dispatchHead:** <external/current sha>
**reviewPhase:** pending-dispatch | review-completed | result-committed | fixing | complete | N/A-direct

## Inputs Reviewed

- Manifest/settings/intel: `<paths or N/A>`
- PRD: `<small entry or split index plus ordered fragments>`
- Proposal: `<small entry or split index plus ordered fragments>`
- Backend design: `<small entry or split index plus ordered fragments, or N/A>`
- Frontend design: `<small entry or split index plus ordered fragments, or N/A>`
- Resolved task plans / owner files: <small entry or split index, manifest order, `tasks`-kind fragments, unique task owner paths>
- Exact task-owner paths: `<exact resolved task-owner path>` (repeat for each unique owner)
- Resolution modes: `<canonical small / canonical split>`
- Structural conflict: `None` (otherwise review is blocked)
- Overview applicability: `<two-end overview and derived totals, or single-end/no overview>`
- Structural validation: `<missing index/manifest fragment, unindexed fragment, file-plus-directory conflict, duplicate content/task owner, invalid Kind/checkbox, invalid overview reference/cycle, and size-limit results>`
- Structural gate: `PASS | FAIL | BLOCKED` — `<exact rejected path/rule; PASS_WITH_NOTES is forbidden on any shared-contract rejection>`
- Progress ledger: `<path or missing>`
- Prior task reviews: `<paths or none>`
- Project constraints: `<paths or none>`
- Dynamic brief/package sources: `<manifest, settings, optional project facts, change artifacts, current source/config, CodeGraph/native-search candidates; N/A where absent>`
- `static handoff absence is not a blocker`: `<confirmed; completeness assessed from dynamic brief/package sources>`
- Target diff: `<baseRef>...<reviewedTargetHead>`
- Logical incremental target diff: `lastReviewedHead..HEAD` at checkpoint, or `N/A`
- Persisted incremental target diff: `lastReviewedHead..<reviewedTargetHead>`, or `N/A`
- Evidence-only diff: `<reviewedTargetHead>..<dispatchHead>`

## Branch State

- Working tree: clean | dirty
- Dirty files: <none or list>
- Base SHA: <sha>
- Merge base: <sha>
- reviewedTargetHead: <sha>
- packageParentHead: <sha; must equal reviewedTargetHead>
- evidenceCommitHead: <runtime external sha or N/A>
- dispatchHead: <runtime external/current sha>
- Last reviewed head: <sha or N/A>
- Target dirty fingerprint: CLEAN
- Evidence HEAD equality: <evidenceCommitHead == dispatchHead == current git HEAD, or direct-mode N/A>
- Evidence-only paths: <final package and allowed pending ledger evidence only>
- Product source unchanged: <PASS | FAIL>
- Dispatch tree clean: <PASS | FAIL>
- Commits reviewed: <count>
- Complete branch inventory/counts: <count and source ranges>

## Dispatch Commit and Phase-aware Resume

Record `git rev-parse <dispatchHead>^`, `git rev-list --count <packageParentHead>..<dispatchHead>`, and `git diff --name-only <packageParentHead>..<dispatchHead>`. Require `dispatchHead^ == packageParentHead`, `rev-list --count packageParentHead..dispatchHead == 1`, and only allowed package/pending-ledger paths.

- `pending-dispatch`: current clean HEAD is the unique direct child of packageParentHead; `evidenceCommitHead=dispatchHead=current HEAD`.
- `review-completed`: historical dispatchHead remains the current committed HEAD; only final report/result-ledger paths may be uncommitted; persist the result before advancing.
- `result-committed` or later: must not set dispatchHead=current HEAD. Record `git merge-base --is-ancestor <dispatchHead> HEAD` proving dispatchHead is an ancestor of current HEAD; revalidate historical parent/count/allowed delta. Record `git diff --name-only <dispatchHead>..HEAD` for successors after dispatchHead: result/complete allow only final report/result-ledger evidence, while fixing may add exact finding-authorized source/tests/fix evidence. Any other phase-allowed result evidence/fix paths violation is `BLOCKED`.

The result commit records the prior dispatchHead and does not record its own SHA; record the externally resolved current result SHA separately.

## Scope Matrix

Base semantics: `declared`, `observed`, `mapped`, `unmapped`, `missing`, `shared`, and `cross-change`. Verdict classes are separate: `mapped-current` belongs to the current selected change and affects the current verdict. `cross-change-only` requires explicit artifact/owner evidence, stays in branch inventory/counts, and is excluded from the current change verdict. If owner evidence is insufficient or cannot be proven, use `unowned/unmapped`; record a scope finding that affects the current verdict. `shared` is reviewed against each relevant change contract and affects the current verdict for selected-change obligations.

| Declared path/contract | Observed diff path | Mapping | Classification | Relevant change owner | Evidence |
| --- | --- | --- | --- | --- | --- |
| `<artifact item/path or N/A>` | `<changed path or N/A>` | `declared / observed / mapped / unmapped / missing` | `mapped-current / cross-change-only / shared / unowned/unmapped / missing` | `<selected slug, other proven slug(s), shared, or unowned>` | `<artifact/owner/diff/current source/test>` |

Review the complete branch inventory first. The selected change verdict covers selected change + shared + unowned risk and missing selected-change scope; proven cross-change-only findings remain reported but do not contaminate it.

## Owner Discovery Evidence

Build owner inventory from selected change canonical artifacts: proposal/design scope, canonical task-owner `Files`/scope entries, and selected evidence package/ledger Scope Matrix. Only for selected-unmapped observed paths, derive the exact normalized path and run one fixed-string candidate lookup over direct sibling active changes under `fp-docs/changes/`. Do not search archive/history and must not bulk-read all changes.

Search only canonical task-owner `Files`/scope entries and existing evidence package/ledger Scope Matrix rows. An exact hit creates a candidate change; only then resolve canonical-first and read minimal proposal/design/task-owner excerpts. Lookup budget: one query, at most eight candidate changes, and one matching owner fragment plus relevant contract excerpts per candidate. Insufficient/cannot-be-proven owner evidence or exhausted lookup budget remains `unowned/unmapped`.

| Path | Candidate lookup | Canonical owner proof | Resolved owners | Classification |
| --- | --- | --- | --- | --- |
| `<exact normalized path>` | `<query, hits, budget>` | `<canonical entry/excerpt or none>` | `<selected/other/shared/unowned>` | `<mapped-current/cross-change-only/shared/unowned-unmapped>` |

## Every-Attempt Gates

| Gate | Result | Evidence |
| --- | --- | --- |
| canonical structure | PASS / FAIL / BLOCKED | <evidence> |
| snapshot/working-tree | PASS / FAIL / BLOCKED | <evidence> |
| scope/out-of-scope | PASS / FAIL / BLOCKED | <evidence> |
| task ownership/dependencies | PASS / FAIL / BLOCKED | <evidence> |
| evidence freshness | PASS / FAIL / BLOCKED | <evidence> |
| command safety | PASS / FAIL / BLOCKED | <evidence> |

## FeaturePilot Coverage

| Source | Requirement / Task | Status | Evidence |
| --- | --- | --- | --- |
| `manifest/settings/intel` | Dynamic task context, relevant settings/project facts, Unknowns, live freshness; optional files may be N/A | Covered / Partial / Missing / N/A | `<dynamic brief/package sources and current proof>` |
| proposal/design/tasks | <requirement> | Covered / Partial / Missing / Violated / N/A | <file/test/commit> |

## Visual Evidence

Visual evidence: PASS | FAIL | CANNOT_VERIFY

| Case ID | Approved design source | Figma node | revision/time | Frame/variant | variables / Auto Layout / assets | Runtime route | Scenario/state | Viewport | DPR | Locale | Theme | Deterministic non-sensitive fixture | Reference path | Current path | Diff path / missing diff | Mask | Acceptance rule | Command/tool | Failure class | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `<case-id>` | `<approved Figma/static design source>` | `<node or N/A>` | `<revision/time or approved-source time>` | `<frame/variant>` | `<available context or N/A>` | `<real target runtime route>` | `<scenario/state>` | `<viewport>` | `<DPR>` | `<locale>` | `<theme>` | `<stable fixture; no secrets or production/customer data>` | `.fp-execute/visual/<task-id>/<case-id>/reference.png` | `.fp-execute/visual/<task-id>/<case-id>/current.png` | `.fp-execute/visual/<task-id>/<case-id>/diff.png` or `N/A: <missing diff explanation>` | `<mask>` | `<case-specific rule>` | `<project-configured replay command/tool>` | `<core visual/non-core cosmetic>` | `<PASS/FAIL/CANNOT_VERIFY>` |

- Source/runtime provenance: `reference.png` comes from the approved Figma/static design source; a local runtime screenshot must not replace it. `current.png` comes from the real target runtime/Runtime route with stable data and stable environment. The optional diff or missing diff explanation must not hide missing source/runtime.
- Browser interaction evidence: `<separate evidence exercising approved states>`
- Screenshot evidence: `<manifest/reference/current/optional diff evidence>`
- Core blocker/debt: `<core visual without trustworthy source/runtime is CANNOT_VERIFY and main-flow blocker; missing evidence must not become review debt; at attempt 3 only reproducible non-core cosmetic differences may become review debt>`

- Provenance: reference.png -> approved Figma/static design source; current.png -> real target runtime.
- Local runtime screenshot must not replace reference.png. current.png requires stable data and stable environment. Optional diff/missing diff explanation must not hide absent core source/runtime evidence.
- Evidence channels: browser interaction evidence is separate from screenshot evidence; browser interaction evidence must exercise approved states, and screenshot evidence must record case artifacts.

## Verification Commands

Classify before execution: `SAFE` may run only after inspecting definitions; `UNSAFE` and `UNKNOWN` must not run.

| Command | Safety | Definition evidence | Result | Notes |
| --- | --- | --- | --- | --- |
| `<command>` | SAFE / UNSAFE / UNKNOWN | `<script/wrapper/config path or N/A>` | PASS / FAIL / SKIPPED | <key output or reason> |

Write-mode and side-effect commands such as `--fix`, `--write`, snapshot update, migration, seed, formatter, generator, cache, coverage, dist, unknown wrapper, service, database, or external mutation are skipped.

## CodeGraph Candidate Evidence

CodeGraph `explore`, `impact`, and `affected` results are candidate-only. Verify them with current source/diff plus native search, tests, or command output. Missing/stale/unavailable graph uses native search fallback and must not block.

| Query/helper | Candidates | Current-source verification | Native search / test / command evidence | Fallback |
| --- | --- | --- | --- | --- |
| `<query or N/A>` | `<paths/symbols or N/A>` | `<path:line>` | `<evidence>` | `<native search or N/A>` |

## Prior Finding Dispositions

| Finding ID | Prior severity | Prior report evidence | Disposition | Fresh evidence |
| --- | --- | --- | --- | --- |
| `<stable id>` | `<severity>` | `<path:line or N/A>` | unresolved / fixed / accepted non-blocking debt | `<current evidence>` |

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

Each finding must include title, `path:line` or command evidence, concrete failure scenario, source requirement, and suggested fix direction.

## Blocking Items Before Archive

- None, or exact required fixes.

## Residual Risks / Notes

- <non-blocking risk or note>

## Final Verdict Rationale

<Tie coverage, diff review, verification, findings, information-layer evidence, and branch state to the verdict.>
