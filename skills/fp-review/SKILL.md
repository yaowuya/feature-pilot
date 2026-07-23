---
name: fp-review
description: Use when performing a final whole-branch review of an implemented FeaturePilot change before archive or merge, especially after fp-execute finishes and the reviewer must verify proposal, design, tasks, progress ledger, validation evidence, and branch diff without editing files.
---
## FeaturePilot workspace and information layer

If any anchored plugin resource is missing or unreadable, stop, report the exact resource and an incomplete FeaturePilot installation/cache, and never search the consumer repository for `skills/**` or continue without it.
下文以 `${CLAUDE_PLUGIN_ROOT}/...` 表示 Claude Code 安装后的插件资源。在 Codex/Markdown 中，从 available-skill 元数据提供的当前技能入口映射同一个 `skills/...` 插件相对路径。两端都不得在消费者项目中搜索插件文件。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.
Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` once before resolving review inputs; it is the normative layout and validation contract.
Apply the shared `Process document language` contract when writing the final review report. This reminder does not alter the exact `PASS`, `PASS_WITH_NOTES`, `FAIL`, or `BLOCKED` verdict semantics.
---

# FeaturePilot Final Whole-Branch Review

`fp-review` is the read-only final reviewer for a completed FeaturePilot change. It reviews the whole branch against `proposal.md`, design files, task plans, progress ledger, validation evidence, and the final branch diff, then writes the review under `.fp-execute/reviews/`.

This skill is self-contained. It may read optional `fp-docs/settings/agent.md` as customer configuration, but must not depend on global code-review skills, external agents, prior archived changes, or local absolute paths. Current code, current FeaturePilot artifacts, customer settings, and the branch diff are the facts.

## Read-Only Reviewer Contract

You are a reviewer, not an implementer.

Allowed:
- Read files, search code, inspect git history/diff, and run read-only verification commands.
- Create only the final review report under `.fp-execute/reviews/`.

Forbidden:
- Do not edit implementation files, tests, FeaturePilot proposal/design/tasks, task checkboxes, progress ledger, or git history.
- Do not run `git add`, `git commit`, `git reset`, `git rebase`, formatters with write mode, migrations that create files, snapshot updates, autofix commands, or database-mutating commands.
- Do not fix findings during review. Record evidence and required remediation instead.

If a useful verification command would mutate the working tree, skip it and record why. `fp-review` does not auto-fix and does not auto-retry.

## Inputs

Accept these inputs when provided:
- `slug`: FeaturePilot change directory name under `fp-docs/changes/<slug>`.
- `baseRef`: diff base. If absent, try in order: Base SHA from `.fp-execute/progress.md`, `origin/master`, `origin/main`, `master`, `main`.
- `headRef`: default `HEAD`.
- `reviewDepth`: `standard` or `strict`; default `standard`.
- `focus`: optional focus area such as backend, frontend, permissions, security, migration, visual, tests, or contracts.
- `reviewScopeId`: stable identity for one bounded final review scope. SDD creates and persists it once; it must not contain reviewer, session, finding, or mutable HEAD identity.
- `reviewAttempt`: integer `1..3` within that scope.
- `maxReviewAttempts`: must be `maxReviewAttempts=3`; reject any other value.
- `priorReviewPath`: completed prior-attempt report path, or `N/A` for attempt 1.
- `priorFindingDispositions`: every prior finding's stable ID and `unresolved | fixed with evidence | accepted non-blocking debt` disposition.
- `finalReviewPackage`: deterministic package path created from `${CLAUDE_PLUGIN_ROOT}/skills/fp-review/final-review-package-template.md`, or `N/A` in direct mode.
- `lastReviewedHead`: exact `reviewedTargetHead` covered by the completed prior attempt, or `N/A` for attempt 1.
- `reviewedTargetHead`: committed clean product/change snapshot that is actually under review.
- `packageParentHead`: parent of the evidence-only package commit; for SDD it must equal `reviewedTargetHead`.
- `evidenceCommitHead`: exact post-commit SHA resolved by the controller outside the package, or `N/A` in direct mode.
- `dispatchHead`: exact clean HEAD at reviewer dispatch, resolved outside the package.
- `reviewPhase`: SDD recovery phase: `pending-dispatch`, `review-completed`, `result-committed`, optional `fixing`, or `complete`; direct mode uses `N/A-direct`.

When these orchestration inputs are absent, direct `fp-review` creates one independent final scope, uses attempt 1 with `maxReviewAttempts=3`, sets `reviewPhase=N/A-direct`, `reviewedTargetHead=dispatchHead=HEAD`, `packageParentHead=HEAD`, and `evidenceCommitHead=N/A`, collects the same package evidence in memory, and writes the report. That direct independent final scope does not auto-fix and does not auto-retry; another direct invocation is a new explicitly requested scope, not attempt 2.

For an SDD-owned scope, the controller must pass all review state, `reviewPhase`, and four HEAD fields; `headRef resolves to reviewedTargetHead`, not the evidence commit. Reject `reviewAttempt` outside `1..3`, an attempt 2/3 without prior state, a changed `reviewScopeId`, or mismatch in package-known identity (`reviewedTargetHead`, `packageParentHead`, scope/attempt/prior state). The package deliberately contains `POST_COMMIT_EXTERNAL` rather than its own exact `evidenceCommitHead`/`dispatchHead`; never demand that it embed current dispatch SHA. A new reviewer, commit, session, or finding never resets the counter. There is no attempt 4.

If `slug` is missing, list `fp-docs/changes/` directories and ask the user to choose; if exactly one exists, use it and state the choice. If `baseRef` cannot be determined, ask the user before continuing.

## Shared canonical artifact resolution

Resolve the approved artifact graph canonical-first before reviewing scope or completion:

1. Detect both alternatives before reading either: `prd.md` or `prd/00-index.md`; `proposal.md` or `proposal/00-index.md`; `design/backend.md` or `design/backend/00-index.md`; `design/frontend.md` or `design/frontend/00-index.md`; `tasks/plan-backend.md` or `tasks/backend/00-index.md`; and `tasks/plan-frontend.md` or `tasks/frontend/00-index.md`.
2. Producer output must contain one canonical form. This read-only Consumer rejects every indexless split, historical path, and dual form as a structural conflict. There is no read-only compatibility; migration must finish before review.
3. A split `00-index.md` is the sole canonical entry. Parse its manifest and read all listed fragments in exact manifest order. Missing/duplicate entries, duplicate owners, or an unindexed fragment are structural findings; never rely on body links, recursive globs, or filesystem order.
4. In split plans, only manifest Kind=`tasks` rows produce `tasks`-kind task-owner files. Each stable ID/checkbox has one unique task owner. Reject forbidden checkbox locations, duplicate IDs/checkboxes, missing references, and dependency cycles rather than guessing coverage.
5. `tasks/00-overview.md` exists exactly when both backend and frontend plans exist. A single-end plan never has an overview. Only a valid two-end overview owns cross-end edges/stages and derived totals; recompute those totals from owner checkboxes before judging completion.

Record each logical artifact's resolved mode, canonical entry, manifest-ordered fragments, task owners, and structural conflicts in the final report. Inspect both alternatives before reading either; use a small plan file only when its corresponding split directory is absent.

## Blocking structural validity gate

Any structural rejection from `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` makes `PASS` and `PASS_WITH_NOTES` impossible. Use `BLOCKED` when invalid structure prevents complete, trustworthy input resolution; use `FAIL` when the complete evidence can still be resolved and the structural defect is concrete. The reviewer may continue collecting findings after detecting a rejection, but those additional findings cannot clear the structural gate.

Treat every shared-contract rejection as blocking, including:

- missing split index or missing manifest fragment;
- unindexed fragment, duplicate manifest order/file entry, or any file-plus-directory conflict;
- duplicate content owner, duplicate task owner, duplicate task ID, or duplicate checkbox;
- invalid manifest Kind, a task checkbox outside a small plan or `tasks`-kind fragment, or any other forbidden checkbox location;
- invalid overview condition, invalid overview reference, missing task reference, or dependency cycle;
- any per-file size-limit violation over 500 lines or 30,000 characters.

Record the exact rejected path/rule under structural validation and continue collecting findings when safe. Never reinterpret a structural conflict as a Low/Medium note.

## Required Reads

Immediately read the actual files that exist for the selected change:
1. `fp-docs/manifest.md` if present
2. relevant existing settings, optional project facts, and human-owned knowledge listed by the manifest; absent optional files are `N/A`
3. complete resolved PRD and proposal logical content, whether small files or split manifests/fragments
4. complete backend design resolved canonical-first, if present
5. complete frontend design resolved canonical-first, if present
6. the complete resolved task set: each selected small plan or split index plus all manifest-ordered owner fragments, and the two-end overview only when applicable
7. `fp-docs/changes/<slug>/.fp-execute/progress.md` if present
8. existing `fp-docs/changes/<slug>/.fp-execute/reviews/*.md` task reviews if present
9. `finalReviewPackage`, `priorReviewPath`, and progress-ledger attempt state when provided
10. project/customer constraint files if present: `fp-docs/settings/agent.md`, `CLAUDE.md`, `.claude/CLAUDE.md`, `AGENTS.md`, `.agents/AGENTS.md`

From these selected change canonical artifacts, build the initial owner inventory before any sibling lookup. Include declared file/scope ownership from the selected proposal/design, canonical task-owner `Files`/scope entries, and the selected evidence package/ledger Scope Matrix. Do not read sibling change bodies during Required Reads; bounded discovery occurs only for selected-unmapped observed paths after the branch inventory exists.

Then inspect the whole branch with read-only commands:
- `git status --short`
- `git rev-parse <headRef>`
- `git merge-base <baseRef> <headRef>` when using branch refs
- `git log --oneline <baseRef>..<headRef>`
- `git diff --stat <baseRef>...<headRef>`
- `git diff --name-only <baseRef>...<headRef>`
- targeted `git diff <baseRef>...<headRef> -- <path>` for changed files

Do not paste full diffs into chat. Use the diff to drive findings and coverage.

## Bounded Attempt Evidence

Attempt 1 establishes complete baseline evidence from the merge base through `reviewedTargetHead`, all resolved contracts, the full Scope Matrix, and every required gate. At the clean target checkpoint, attempts 2/3 collect the logical `lastReviewedHead..HEAD`; after capturing the target SHA, persist and review the immutable `lastReviewedHead..<reviewedTargetHead>` range, affected contracts/tests/package/ledger, all unresolved findings, and any freshly disproven disposition.

Incremental review never means incremental trust. On every attempt, rerun and name these gates exactly:

1. `canonical structure`
2. `snapshot/working-tree`
3. `scope/out-of-scope`
4. `task ownership/dependencies`
5. `evidence freshness`
6. `command safety`

The report must retain the baseline, logical `lastReviewedHead..HEAD`, and persisted `lastReviewedHead..<reviewedTargetHead>` ranges. Recompute target evidence (target SHA, target dirty fingerprint, product paths, Scope Matrix) separately from dispatch evidence (`evidenceCommitHead`, `dispatchHead`, dispatch tree, and `reviewedTargetHead..dispatchHead` evidence-only delta). A prior report or final package is navigation and recovery evidence, never completion authority or proof that current code still satisfies a finding.

## SDD Dispatch Commit and Phase-aware Resume

The SDD caller passes `reviewPhase`; direct mode records `N/A-direct` and skips this state machine.

- `pending-dispatch`: current clean HEAD is the unique direct child of packageParentHead. Resolve `evidenceCommitHead=dispatchHead=current HEAD`, then independently run `git rev-parse <dispatchHead>^`, `git rev-list --count <packageParentHead>..<dispatchHead>`, and `git diff --name-only <packageParentHead>..<dispatchHead>`. Require `dispatchHead^ == packageParentHead`, `rev-list --count packageParentHead..dispatchHead == 1`, and only allowed package/pending-ledger paths; otherwise return `BLOCKED`.
- `review-completed`: historical dispatchHead remains the current committed HEAD. Only final report/result-ledger paths may be uncommitted; inspect them, reject every other dirty path, and persist the result before advancing.
- `result-committed` (and later `fixing`/`complete`): must not set dispatchHead=current HEAD. Recover the historical dispatchHead from the later result event; run `git merge-base --is-ancestor <dispatchHead> HEAD` and require dispatchHead is an ancestor of current HEAD, then re-run the parent/count/name-only commands against that historical commit. Require `dispatchHead^ == packageParentHead`, `rev-list --count packageParentHead..dispatchHead == 1`, and the original allowed package/pending-ledger paths. Run `git diff --name-only <dispatchHead>..HEAD` for successors after dispatchHead: `result-committed`/`complete` allow only final report/result-ledger evidence; `fixing` additionally allows exact fixer-authorized finding paths, related tests, and fix report/package evidence. Any other phase-allowed result evidence/fix paths violation returns `BLOCKED`.

The result commit records the prior dispatchHead and does not record its own SHA. Its current result commit SHA is always resolved externally. Package/runtime equality alone is never sufficient without parent, count, allowed-delta, ancestry, and phase-successor checks.

## Review Procedure

### 1. State and Input Validation

Verify:
- The change directory exists and has a structurally valid resolved proposal.
- At least one design file, task plan, progress ledger entry, commit, or diff provides implementation evidence.
- Task checkboxes, progress ledger, commits, and actual files do not contradict each other.
- Every executable task ID and checkbox has exactly one owner file; progress ledger entries are recovery evidence and do not replace unchecked owner state.
- When and only when both ends exist, `tasks/00-overview.md` cross-end edges are acyclic and its derived progress counts equal the resolved owner checkboxes.
- Working tree state is known. Dirty working tree is allowed to be reviewed, but final verdict cannot be `PASS`.
- In SDD mode, `packageParentHead == reviewedTargetHead`; package `evidenceCommitHead` and `dispatchHead` are the `POST_COMMIT_EXTERNAL` sentinel. At `pending-dispatch`, runtime inputs satisfy `evidenceCommitHead == dispatchHead == current git HEAD`; later phases retain the historical dispatch values.
- `reviewedTargetHead..dispatchHead` contains only allowed evidence paths: the final package and pending ledger evidence. Verify product source unchanged across that delta and verify the dispatch tree clean at its checkpoint. Any product/change implementation path in the evidence commit makes the package invalid and review `BLOCKED`.
- In direct mode, require `reviewedTargetHead=dispatchHead=HEAD`, `evidenceCommitHead=N/A`, and current working-tree evidence; no evidence-only commit is implied.

If required inputs are missing so badly that review cannot proceed, write a `BLOCKED` report.

Also review information-layer process compliance:

- When `fp-docs/manifest.md` exists, verify the implementation phase read it and consumed only relevant settings/intel.
- When the change is SDD-executed, verify the `dynamic brief/package sources`: manifest, relevant settings, optional project facts, current change artifacts, current source/config, and CodeGraph/native-search candidates. `static handoff absence is not a blocker`; judge completeness from the actual brief/package and current evidence.
- Verify relevant Unknowns were resolved before planning/execution, and that stale intel was not used as proof of current behavior.
- Manifest-listed legacy `unknowns-and-decisions.md`, `refresh-policy.md`, `sdd-handoff.md`, and old generated intel may be read for one release as compatibility hints only; they are not required current proof.
- When the manifest is absent for a legacy or uninitialized project, report this as a process risk only when it materially limits review confidence; do not treat it as an automatic product defect.

### 2. FeaturePilot Coverage Review

Build a coverage table from source artifacts:
- Every resolved proposal logical `What Changes` and `Capabilities` item, across its small file or manifest-ordered fragments.
- Every explicit `Out of Scope` item.
- Every backend design contract, permission, migration, provider, API, and validation requirement.
- Every frontend design contract, route/store/API, component mapping, project frontend framework and script/state pattern, project-configured components, style token, and Visual Check requirement.
- Every completed task in the resolved task-owner files, cross-checked against progress ledger evidence.

For each item, mark `Covered`, `Partial`, `Missing`, `Violated`, or `N/A`, with file/test/commit evidence.

### 2.1 Visual Evidence Gate

For every planned frontend/UI Case ID, resolve `.fp-execute/visual/<task-id>/<case-id>/manifest.md` and verify its Approved design source/Figma node plus revision/time, Frame/variant, available variables / Auto Layout / assets, Runtime route, Scenario/state, Viewport, DPR, Locale, Theme, Deterministic non-sensitive fixture, Reference path, Current path, Diff path, Mask, Acceptance rule, Command/tool, and Failure class.

`reference.png` must come from an approved Figma/static design source; a local runtime screenshot must not replace it. `current.png` must come from the real target runtime and runtime route with stable data and stable environment. `diff.png` is optional diff; a missing diff explanation must not hide absent core source/runtime evidence. Browser interaction evidence is separate from screenshot evidence and must show the approved states were exercised.

Record `Visual evidence: PASS | FAIL | CANNOT_VERIFY`. Core visual acceptance without trustworthy source or trustworthy runtime is `CANNOT_VERIFY` and a main-flow blocker. Missing evidence must not become review debt. At attempt 3 only reproducible non-core cosmetic differences may become review debt; core visual evidence gaps remain blocked.

Use only the project-configured browser runner/tool and case-specific Acceptance rule. Do not assume a framework, command, URL, storage root, or global pixel threshold; do not silently install dependencies. Code Connect is an optional enhancement and absence does not block ordinary UI review.

Provenance: reference.png -> approved Figma/static design source; current.png -> real target runtime.
Local runtime screenshot must not replace reference.png. current.png requires stable data and stable environment. Optional diff/missing diff explanation must not hide absent core source/runtime evidence.
Evidence channels: browser interaction evidence is separate from screenshot evidence; browser interaction evidence must exercise approved states, and screenshot evidence must record case artifacts.

### 3. Scope Matrix

Build a complete branch inventory before excluding anything: every declared path/contract from resolved artifacts and every observed path from the baseline diff, the persisted incremental target range when applicable, and dirty working tree. `declared`, `observed`, `mapped`, `unmapped`, `missing`, `shared`, and `cross-change` remain the base semantics; then assign one verdict class with proven ownership:

- `declared`: contract/path inventory item from the approved change.
- `observed`: current diff or dirty path inventory item.
- `mapped`: declared and observed evidence have one supported relation; classify it further below.
- `unmapped`: observed diff has no supported owner relation.
- `missing`: declared implementation or evidence has no observed/current-source realization.
- `mapped-current`: artifact/owner evidence maps the path to the current selected change; it affects the current verdict.
- `cross-change-only`: explicit artifact/owner evidence maps the path to another identified change and proves it does not support the current change. Retain it in branch inventory/counts and report/package; it is excluded from the current change verdict. If ownership evidence is insufficient or cannot be proven, never guess another owner: classify it `unowned/unmapped`.
- `shared`: evidence maps the path to the selected change and one or more other changes. Review it against each relevant change contract; selected-change/shared defects affect the current verdict.
- `unowned/unmapped`: no owner can be proven. Keep the unowned diff as a current scope finding; it affects the current verdict according to severity and is never silently excluded.

Use the exact Scope Matrix schema from the package/report template: `Declared path/contract`, `Observed diff path`, `Mapping`, `Classification`, `Relevant change owner`, `Evidence`. First review the complete branch inventory, then issue the selected change + shared + unowned risk verdict. Whole-branch review means inventory and ownership accounting across the branch; verdict evidence is change-scoped to mapped-current, shared obligations relevant to the selected change, missing declared scope, and unowned/unmapped risk. Cross-change-only defects are reported under their proven owner but do not alter the selected change verdict.

#### Bounded Owner Discovery

Run this only for selected-unmapped observed paths. For each path, derive one exact normalized path (repository-relative, slash-normalized, no `.`/`..`, exact tracked-path casing) and perform one fixed-string candidate lookup across direct sibling active changes under `fp-docs/changes/`. Do not search archive/history, and must not bulk-read all changes.

The lookup is bounded to canonical task-owner `Files`/scope entries and existing evidence package/ledger Scope Matrix rows. Search may return candidate change paths, but only a hit on the exact normalized path authorizes reading that candidate change. For each hit, resolve canonical-first and read only minimal proposal/design/task-owner excerpts needed to verify ownership; do not read unrelated fragments. The default lookup budget is one exact-path search, at most eight matched sibling changes per observed path, and at most one matching owner fragment plus relevant contract excerpts per candidate. If the lookup budget is exhausted or owner evidence cannot be proven, classify `unowned/unmapped` rather than guessing.

Resolve classification from proof: exactly one other owner and no selected-change relation is `cross-change-only`; selected plus any proven other owner is `shared`; ambiguous, conflicting, or absent proof is `unowned/unmapped`. For `shared`, read only relevant contract excerpts for each proven owner.

Record an `Owner Discovery Evidence` row for every selected-unmapped path:

| Path | Candidate lookup | Canonical owner proof | Resolved owners | Classification |
| --- | --- | --- | --- | --- |
| `<exact normalized path>` | `<bounded query, hits, budget>` | `<canonical-first entry/excerpt or none>` | `<selected/other/shared/unowned>` | `<mapped-current/cross-change-only/shared/unowned-unmapped>` |

### 4. Whole-Branch Diff Review

Review all changed files first as one complete branch inventory, not as isolated tasks. Then assess the selected change, shared paths, and unowned risk for the current verdict; do not let unrelated but proven cross-change-only work contaminate that verdict.

Check relevant areas:
- Backend: model, migration, service, serializer/schema, ViewSet/API, URL/router, IAM/permission, provider/registry, async jobs, external calls, tenant isolation, error handling, backward compatibility.
- Frontend: API wrapper, state management/composable/hook/context, route, project frontend framework and script/state pattern, project-configured components, state transitions, loading/empty/error states, styles, design tokens, Figma/Visual Checks.
- Contracts: URL, HTTP method, request/response fields, enums, error shape, pagination/filter/sort, permission states, route names, store actions, component props/events.
- Tests: meaningful assertions, negative paths, permissions, boundary cases, migration/compatibility, frontend contract and visual checks where applicable.
- Production readiness: deployment order, migrations, config, feature flags, logging, security leakage, performance, rollback implications.

### 5. Command Safety and Verification

Before executing validation, classify every proposed command `SAFE`, `UNSAFE`, or `UNKNOWN` and record the exact command plus inspected definition. `SAFE` means its script, alias, wrapper, and configuration were inspected and the selected variant has no repository, cache, service, database, or external side effect. Only then may it run.

`UNSAFE` and `UNKNOWN` commands must not run. This includes `--fix`, `--write`, snapshot update, migration, seed, formatter, generator, cache, coverage, or dist writes; unknown wrapper behavior; service startup; database mutation; and external mutation. A dry-run label alone is not proof. Find a safe variant only after inspecting its definitions; otherwise record `SKIPPED`, the reason, and the resulting evidence gap.

Prefer commands recorded in task plans and `.fp-execute/progress.md`. Run only variants proven read-only after definition inspection, such as tests with cache/coverage/snapshot writes disabled, lint check without autofix or cache, and typecheck with no emit. A build or dry-run name is not safe by itself.

For each command record:
- command text
- result: `PASS`, `FAIL`, or `SKIPPED`
- key output or skip reason

A required verification command that fails usually forces `FAIL`. A skipped command may force `PASS_WITH_NOTES`, `FAIL`, or `BLOCKED` depending on risk.

### 6. CodeGraph Candidate Verification

When `.codegraph/` exists and `${CLAUDE_PLUGIN_ROOT}/skills/_shared/codegraph.md` permits a healthy query, CodeGraph `explore`, `impact`, and `affected` helpers may identify candidates only. Every candidate used in reasoning must be verified against the current diff, current source, native caller/import search, tests, or command output. Graph results alone cannot prove a finding, absence, scope mapping, or fix.

If CodeGraph is missing, stale, dirty, or unavailable, fall back to native search against current source without blocking review. Record the query, candidates, verification, and fallback. CodeGraph failure must not block; only missing current evidence may affect the verdict.

## Severity Rubric

Report only concrete defects or material unverified risks. Do not report style preferences.

| Severity | Definition | Verdict impact |
| --- | --- | --- |
| `Critical` | Data loss, security bypass, tenant/permission isolation break, production crash, irreversible migration failure, or core FeaturePilot goal unusable | Always `FAIL` |
| `High` | Major required behavior missing, backend/frontend contract incompatible, deployment likely fails, important permission/migration path broken, or critical validation absent | Normally `FAIL` |
| `Medium` | Secondary requirement partial/missing, boundary behavior wrong, loading/empty/error/visual state materially incomplete, tests insufficient for changed risk, or progress/tasks conflict with implementation | `PASS_WITH_NOTES` or `FAIL` based on risk/count |
| `Low` | Non-blocking maintainability, minor doc mismatch, small visual/text polish, or low-risk validation gap | Does not block alone |

Each finding must include:
- stable finding ID retained across attempts
- severity
- title
- evidence with path and line number, or command output
- failure scenario: concrete input/state leading to wrong result or risk
- source requirement: proposal/design/task/progress/diff item
- suggested fix direction

## Final Verdict

Choose exactly one:

Apply these verdicts only to mapped-current scope, relevant shared contracts, missing selected-change scope, and unowned/unmapped risk. Proven cross-change-only findings remain visible in branch inventory/counts and handoff notes but are excluded from the current change verdict.

- `PASS`: structural gate passed; no Critical/High/Medium findings; working tree clean; required verification passed; FeaturePilot scope is fully covered.
- `PASS_WITH_NOTES`: structural gate passed; no Critical/High findings; only Low or explicitly acceptable Medium findings; working tree clean; core verification passed; archive/merge may proceed with notes.
- `FAIL`: a resolvable shared-contract structural rejection, any Critical/High finding, blocking Medium risk, failed key verification, dirty working tree, implemented Out of Scope behavior, or missing core FeaturePilot scope.
- `BLOCKED`: an unresolved structural rejection prevents trustworthy artifact resolution, or review cannot complete because required inputs, base ref, diff, or safe verification are unavailable.

At Attempt 3, mapped non-blocking findings may be recorded as non-blocking debt with evidence. Main-flow blockers remain blocked and prevent completion/archive. A new reviewer, commit, session, or finding never creates a fresh attempt counter for the same `reviewScopeId`.

If verdict is not `PASS`, list exact blocking items before archive.

## Output Location

Create the review directory if needed:

```text
fp-docs/changes/<slug>/.fp-execute/reviews/
```

Write exactly one final review report:

```text
fp-docs/changes/<slug>/.fp-execute/reviews/YYYYMMDD-HHMM-final-review.md
```

If the reviewed task is outside `fp-docs/changes/<slug>/`, write to the nearest task directory instead:

```text
.fp-execute/reviews/YYYYMMDD-HHMM-final-review.md
```

Do not write review reports anywhere else.

## Final Review Report Template

Use `${CLAUDE_PLUGIN_ROOT}/skills/fp-review/final-review-package-template.md` as the deterministic input schema when SDD supplies `finalReviewPackage`; it is not completion authority. Read `${CLAUDE_PLUGIN_ROOT}/skills/fp-review/final-review-template.md` only after evidence collection is complete and immediately before writing the report. Preserve its headings and tables exactly; add coverage rows and findings without changing the schema.

## Completion Response

After writing the report, respond with only:
- review report path
- final verdict
- finding counts by severity
- verification summary
- blocking items before archive

Do not paste the full report unless the user asks.
