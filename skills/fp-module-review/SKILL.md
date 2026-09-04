---
name: fp-module-review
description: Use when a user asks for an evidence-driven code review of one large functional module or several related modules, especially when the work must persist across sessions and may include findings, compatibility decisions, approved fixes, or convergence verification.
---

## FeaturePilot workspace and information layer

If any anchored plugin resource is missing or unreadable, stop, report the exact resource and an incomplete FeaturePilot installation/cache, and never search the consumer repository for `skills/**` or continue without it.
下文以 `${CLAUDE_PLUGIN_ROOT}/...` 表示 Claude Code 安装后的插件资源。在 Codex/Markdown 中，从 available-skill 元数据提供的当前技能入口映射同一个 `skills/...` 插件相对路径。两端都不得在消费者项目中搜索插件文件。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.
Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/codegraph.md` once before code navigation; CodeGraph remains optional and candidate-only.
Apply the shared `Process document language` contract to module-review artifacts.

---

# FeaturePilot Module Review

`fp-module-review` is the persistent, evidence-driven workflow for one large functional module or several related modules. It freezes scope and compatibility, reviews coherent ownership waves, records stable Findings, gates observable behavior changes, applies only authorized minimal fixes, and verifies convergence.

It does not replace `fp-final-review`, pull-request review, a small diff review, or a repository-wide audit. `fp-final-review` remains the read-only whole-branch gate before archive or merge.

## Inputs

Accept these inputs when provided:

- `slug`: stable workspace name under `fp-docs/module-reviews/<slug>/`.
- `targets`: one or more repository-relative directories, files, symbols, or named functional modules.
- `focus`: optional review dimensions such as correctness, contracts, security, lifecycle, concurrency, resource ownership, performance, tests, or production readiness.
- `mode`: `full` (default), `review-only`, or `resume`.
- `baseRef`: optional diff-navigation base; current source, not the diff, defines module behavior.

At least one target must resolve. If `slug` is absent, derive a deterministic kebab-case value from the resolved target names, state it, and reuse it on resume.

When more than one existing workspace or target interpretation remains plausible, ask one bounded question. Deadline, user absence, manager preference, or the apparent low cost of reviewing both are not selection evidence. You must not silently broaden ambiguous targets to both candidates, shared infrastructure, or the whole repository. If the question cannot be answered, write only the ambiguity and recovery condition when one workspace is already unambiguous; otherwise stop before creating a workspace.

Several targets are valid only when the user named them together or current source proves that they form one related functional boundary. Independent modules require independent review workspaces.

## Canonical workspace

Use exactly:

```text
fp-docs/module-reviews/<slug>/
├── review.md
├── scope.md
├── baseline.md
├── waves.md
├── findings/
│   └── MR-FNNN.md
├── summary.md
└── .fp-module-review/
    └── progress.md
```

Ownership is exclusive:

- `review.md`: stable entry, quick status, counts, and ordered canonical manifest only.
- `scope.md`: targets, direct integrations, dimensions, exclusions, precedence, write/protected paths, and external authorization.
- `baseline.md`: snapshot, observable contracts, existing-test baseline, command-safety ledger, and evidence gaps.
- `waves.md`: ownership waves, dependencies, status, and candidate reconciliation.
- `findings/MR-FNNN.md`: one Finding's complete evidence and disposition.
- `summary.md`: final scope/wave/finding reconciliation and completion status.
- `.fp-module-review/progress.md`: append-only recovery evidence; it never owns Finding state.

Never duplicate detailed Finding state into `review.md`, `waves.md`, `summary.md`, task checkboxes, or progress events. Use the templates named in `Template loading`.

## Exact lifecycle

Record exactly one current state:

- `SCOPING`
- `BASELINING`
- `REVIEWING`
- `TRIAGING`
- `WAITING_APPROVAL`
- `FIXING`
- `VERIFYING`
- `BLOCKED`
- `COMPLETE_WITH_AWAITING`
- `COMPLETE`

Normal flow is `SCOPING → BASELINING → REVIEWING → TRIAGING → WAITING_APPROVAL | FIXING → VERIFYING → COMPLETE_WITH_AWAITING | COMPLETE`. `BLOCKED` may be entered from any state only with concrete evidence and an exact recovery condition.

`SCOPING`, `BASELINING`, `REVIEWING`, and `TRIAGING` are read-only for product source and existing tests. These states may create or update only this module-review workspace. Candidate discovery never authorizes implementation.

`review-only` never enters `FIXING`. It still completes scope, baseline, waves, triage, safe verification, and truthful Finding dispositions.

## SCOPING

Resolve project root and read, in order:

1. current project instructions;
2. `fp-docs/manifest.md` when present, then only relevant listed settings, current project facts, and human-owned knowledge;
3. resolved targets and their current source;
4. direct imports, callers, registrations, routes, configuration, persistence, lifecycle owners, and adjacent tests;
5. Git HEAD, status, changed paths, and optional `baseRef` diff navigation.

Create a complete inventory of declared targets, proven direct integration points, relevant tests/configuration, explicit exclusions, allowed artifact/test/source write paths, protected paths, and unavailable or unauthorized external systems.

CodeGraph is navigation only. Follow `MCP → CLI → native search`; every selected edge must be verified against current source plus native search, tests, or command output. A stale, unavailable, missing, or dirty graph never blocks native investigation and never proves a Finding or absence.

A target's unrelated callers and shared infrastructure are not automatically in scope. Include an integration only when current evidence proves it can change or invalidate the selected module behavior; record why.

## BASELINING

Before a Finding can authorize an observable behavior change, record all applicable current compatibility contracts: API/method/path, schema/default/limits, response/error/status, timing/order, logging, callbacks, storage/retention, permissions/security policy, configuration, deployment compatibility, resource lifecycle, and user-visible UI behavior.

Inspect adjacent test and command definitions before execution. Record the exact environment, command, selected scope, declared outputs, exit code, passed/failed/skipped/expected-failure counts, warnings/background errors, and evidence gaps. A failing baseline becomes triage evidence; do not weaken assertions, update snapshots, or hide failures.

### Command safety

Classify every proposed command after inspecting its script, alias, wrapper, configuration, and selected flags:

- `SAFE`: read-only, or writes only enumerated isolated test/report/cache/temp outputs.
- `UNSAFE`: installs/upgrades, migrates, seeds, deploys, formats/writes product code, updates snapshots/goldens, mutates Git, touches real services/databases/external systems, or performs destructive file actions.
- `UNKNOWN`: wrapper behavior or side effects cannot be proved.

Only `SAFE` commands may run. `UNSAFE` and `UNKNOWN` commands must not run. A teammate assertion, command name such as `verify-all`, or dry-run label is not proof. Record skipped evidence and resulting verification limits.

## REVIEWING waves

Partition the inventory into coherent ownership and call-flow waves, not arbitrary file counts. Cover applicable dimensions:

- public API, schema, and contracts;
- domain/service correctness and error handling;
- state, queue, scheduler, concurrency, and ordering;
- lifecycle, cleanup, cancellation, and resource ownership;
- storage, transfer, cache, and external integration;
- logging, callbacks, configuration, security, and production readiness;
- tests and final reconciliation.

Each wave names owned targets/integrations, dimensions, dependencies, verification candidates, and completion evidence. A wave is complete only when every owner/dimension has an evidence-backed disposition, including explicit `no finding` where applicable.

Independent waves may use parallel read-only agents. Agents return candidates only. The main controller verifies current source, deduplicates candidates, allocates stable IDs, and writes owner documents. Agents must not allocate final IDs or edit source.

## TRIAGING and Finding proof

Allocate `MR-FNNN` monotonically from the highest ID in the canonical manifest. Never reuse an ID, renumber for severity, or rename because status changes.

A candidate becomes `confirmed` only when current source and at least one supplementary proof demonstrate a concrete failure or material risk. Proof may be a deterministic failing test, reproduction, verified call path, contract contradiction, resource/lifecycle violation, or safe command output. CodeGraph, style preference, hypothetical misuse, or historical prose alone is insufficient; use `rejected` when counterevidence wins.

Each Finding records every field in `finding-template.md`, including stable ID, evidence, trigger, wrong result/risk, supplementary proof, severity, observable behavior impact, state, disposition, test mapping, RED/GREEN/adjacent regression, rollback, and residual risk.

Allowed transitions:

- `candidate → confirmed | rejected`
- `confirmed → awaiting-user-confirmation | fixed | blocked`
- `awaiting-user-confirmation → approved | blocked`
- `approved → fixed | blocked`
- `blocked → approved | fixed`
- `fixed` and `rejected` are terminal.

Use severity `Critical`, `High`, `Medium`, or `Low` only for concrete impact. Do not report style preferences as Findings.

## Observable behavior approval gate

Observable behavior includes accepted inputs, API/schema, response/error/status, timing/order, logs/callbacks, persistence/retention, permissions, security policy, deployment compatibility, and user-visible behavior.

A production fix is authorized only when observable behavior impact is `none`, or the user explicitly approves its stable ID and proposed behavior. Team role, severity, release deadline, generic permission to fix security, or approval of another Finding does not satisfy this gate.

For non-`none` impact, set `awaiting-user-confirmation`, record current/proposed behavior, affected consumers, rollback, and the exact decision. Enter `WAITING_APPROVAL`; continue independent read-only waves, but do not edit production code for that Finding.

## FIXING

Before each authorized fix, freeze exact allowed source/test paths and protected paths from the Finding owner. Then execute one bounded TDD loop:

1. write or identify the narrow deterministic behavior test;
2. run it and verify RED for this Finding's intended reason;
3. apply the minimum production change;
4. run the target test and verify GREEN;
5. run the complete owner scope and adjacent regression;
6. inspect unexpected skips, xfails/XPASS, warnings, background errors, declared outputs, and protected-path diffs;
7. update the Finding owner and append one progress event.

Never refactor unrelated code, broaden scope to make a fix easier, install dependencies without explicit authorization, contact real external systems without explicit authorization, weaken assertions, or mark a Finding fixed from code inspection alone.

An awaiting or approved-but-unimplemented test may be part of the ordinary suite only when the framework guarantees a strict expected failure whose unexpected pass fails the suite, and the test maps to exactly one Finding. Otherwise keep the deterministic reproduction outside the ordinary green suite and record why. Expected failures never count as fixed.

After any product-source write, mark graph evidence `dirty-after-write` and stop querying the old graph. Before returning, run at most one `post-write-sync` against an existing graph; failure does not block the main workflow and must be recorded.

## Resume and invalidation

`resume` reads `review.md`, the canonical manifest, all listed owner artifacts in order, and the last progress event. Compare current HEAD, working-tree fingerprint, scope/config fingerprints, target existence, test/command definitions, environment, report identity, and Finding owners.

Invalidate affected evidence when production code, tests, configuration, dependencies/lockfiles, command selection, environment, HEAD/branch, unexplained worktree state, target scope, or reports changed. Never trust yesterday's `passed` label after its fingerprint changes.

Resume from the earliest necessary state:

- target/ownership/exclusion change → `SCOPING`;
- compatibility, test command, environment, or baseline invalidation → `BASELINING`;
- source change in a completed wave → `REVIEWING` for that wave, then `TRIAGING`;
- authorized fix interrupted with intact RED evidence → `FIXING`;
- only final evidence stale → `VERIFYING`.

If the worktree contains unexplained edits, preserve them, mark affected evidence invalid, and do not restore, delete, stash, or overwrite them. Enter `BLOCKED` when ownership/safety cannot be established.

## VERIFYING and completion

Reconcile targets/integrations, all wave dimensions, the monotonic ID sequence and unique owners, every state count, RED/GREEN/regression freshness, command safety/skips, current HEAD/worktree, and changed/allowed/protected/unexplained paths.

`COMPLETE` requires all of these simultaneously:

- every wave is complete;
- no Finding remains `candidate`, `confirmed`, `approved`, `awaiting-user-confirmation`, or `blocked`;
- every fixed Finding has fresh RED, GREEN, owner-scope, and adjacent regression evidence;
- all required `SAFE` verification passed;
- there is no unexplained protected or out-of-scope change;
- summary evidence matches current HEAD and working-tree fingerprint.

`COMPLETE_WITH_AWAITING` requires the same predicates except that one or more Findings remain exactly `awaiting-user-confirmation`; their production behavior is unchanged, deterministic evidence is preserved, and the summary lists exact Finding IDs and decisions. It must not claim all defects are fixed or the module is fully remediated.

Use `CANNOT_VERIFY` for each affected claim when evidence is unavailable but review can still truthfully conclude. If missing safe baseline/final verification prevents a trustworthy conclusion, use `BLOCKED`, not a completion state.

## Template loading

Create directories only after target/workspace resolution is unambiguous. Read each template immediately before creating or updating its owner:

- `${CLAUDE_PLUGIN_ROOT}/skills/fp-module-review/review-entry-template.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/fp-module-review/scope-template.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/fp-module-review/baseline-template.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/fp-module-review/waves-template.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/fp-module-review/finding-template.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/fp-module-review/summary-template.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/fp-module-review/progress-event-template.md`

Preserve headings and tables exactly. Replace placeholders with current evidence; do not leave placeholder text in successful artifacts.

## Completion response

Respond with only the workspace path, state, targets/waves reviewed, Finding counts by state/severity, fixed and awaiting exact IDs, verification summary, `CANNOT_VERIFY` claims, blockers, and next required decision/action. Do not paste full artifacts unless requested. Do not commit, push, open a pull request, or invoke `fp-final-review` unless separately requested.
