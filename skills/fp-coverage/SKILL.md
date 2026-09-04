---
name: fp-coverage
description: Use when a user asks to raise unit-test, line, branch, statement, function, instruction, or combined coverage to an explicit target, close measured coverage gaps through behavior tests, or resume an interrupted coverage-improvement effort.
---

## FeaturePilot workspace

插件资源锚定、`${CLAUDE_PLUGIN_ROOT}` 路径映射与缺失即停止规则见 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md`；不要在消费者项目中搜索 `skills/**`。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting. It owns project-root resolution, manifest read order, lazy context, evidence precedence, process-document language, customer neutrality, and CodeGraph routing.

# FeaturePilot Coverage Improvement

`fp-coverage` is the technology-neutral execution workflow for raising unit-test coverage without changing the measurement contract or hiding failures. Its core loop is `freeze metric -> fresh baseline -> triage -> ranked owner batch -> periodic full refresh -> fresh final gate`.

## When to use

Use this skill for:

- raising unit-test, line, statement, branch, function, instruction, or combined coverage to a target;
- closing machine-readable coverage gaps through behavior tests;
- establishing a gate with the project's existing test/coverage tools;
- resuming an interrupted coverage-improvement effort.

Do not use it for a read-only coverage query, an ordinary small set of already-scoped tests, E2E/browser/visual coverage, a coverage-config-only change, or a production bug fix.

## Non-negotiable invariants

1. The target project's existing test runner, coverage tool, CI definition, source scope, configuration, package manager, and dependency declarations are the facts. `prefer-existing-coverage-toolchain`: reuse them before proposing any missing coverage capability; do not hardcode a replacement framework.
2. Freeze `source/include/omit/exclude`, branch mode, metric, target, test selection, and official final command before the fresh baseline. This is `metric-freeze`.
3. Coverage-only mode writes tests, approved test fixtures, declared coverage outputs, and current-change evidence only. `coverage-only-no-production-write` applies unless the user explicitly expands scope. An approved `coverage-tooling-bootstrap` is a separate narrow write scope for named coverage dependencies, their existing dependency declaration, and minimum coverage configuration; it is not production-write permission.
4. Coverage percentage and suite success are independent gates. A passing number with a non-zero command is not completion.
5. Historical, local, estimated, rounded, or stale evidence can rank work but cannot prove the final result.
6. `fp-docs/changes/<slug>-coverage/.fp-coverage/progress.md` is a `bounded recovery index`, not an append-only command history and not a second completion authority. Detailed evidence belongs in the split files below. A canonical FeaturePilot task-owner checkbox remains the planned completion authority when one exists.
7. All coverage process evidence and tool reports belong under the same `coverage-change-root`: `fp-docs/changes/<slug>-coverage/`. Do not write coverage reports at the project root.
8. Do not overwrite user changes or broadly clean the working tree. Reconcile only outputs proven to originate from the current run.

## State model

Use exactly one current state:

| State | Meaning |
| --- | --- |
| `RESOLVING` | Resolve project rules, metric, scope, target, commands, write boundary, protected paths, existing evidence, and any missing-tool approval gate. |
| `BASELINING` | Capture fingerprints and run the fresh official baseline. |
| `TRIAGING` | Reproduce and classify every baseline failure before adding broad coverage batches. |
| `ITERATING` | Execute one ranked owner batch through RED, target GREEN, owner GREEN, and reconciliation. |
| `FINAL_VERIFYING` | Run the fresh repository-wide or explicitly contracted final gate. |
| `BLOCKED` | No safe recommendation/command can be proved, required authorization was declined or unavailable, bootstrap/environment failed, an out-of-scope production defect exists, or trustworthy evidence is unavailable. |
| `COMPLETE` | Every completion predicate is simultaneously true. |

Never invent an intermediate completed state such as “coverage complete, tests pending.”

## Coverage change identity and artifact root

Resolve one filesystem-safe base slug from the user's explicit slug, an existing related FeaturePilot change, or the project/coverage scope. Normalize the final change directory as `fp-docs/changes/<slug>-coverage/`:

- append `-coverage` exactly once;
- if that exact directory already exists, treat it as the resume target rather than creating a duplicate;
- if multiple plausible existing coverage changes match, remain `RESOLVING` and ask the user to choose;
- create no root-level `.fp-coverage/`, `coverage.xml`, `htmlcov/`, or equivalent coverage report path.

This directory is the `coverage-change-root` and owns all process evidence and coverage-tool reports:

```text
fp-docs/changes/<slug>-coverage/
├── issues.md                                  # lazy: first qualifying code issue
├── final-report.md                            # completion boundary, before COMPLETE
├── .fp-coverage/
│   ├── progress.md                            # bounded current state/index
│   ├── contract.md                            # frozen contract and approvals
│   ├── baselines/<run-id>.md                  # initial/periodic full evidence
│   ├── batches/<batch-id>.md                  # owner RED/GREEN evidence
│   └── verifications/<run-id>.md              # final-gate attempts
├── .coverage
├── coverage.xml
├── htmlcov/
└── <other-declared-coverage-reports>
```

`coverage.xml` and `htmlcov/` are conventional examples, not required formats. If the project's official tool emits LCOV, JSON, JaCoCo XML, Cobertura XML, binary coverage data, or another HTML directory, redirect that declared output beneath `coverage-change-root`. Before execution, every coverage report/output/artifact path must be explicitly redirected beneath `coverage-change-root`. If any selected command or wrapper would first write a coverage output at the project/repository root, classify it `UNKNOWN` or `BLOCKED` and do not run it. Run-then-move is forbidden even when provenance could be proved; provenance is only for reconciling unexpected side effects after an otherwise authorized run.

Tests and approved fixtures remain in the target project's established test paths so its runner and CI can discover them. Only FeaturePilot process state and coverage-tool outputs move under the coverage change root.

## Phase 1: Resolve and freeze

Read the smallest relevant current sources:

1. `fp-docs/manifest.md` when present, then relevant settings/project facts as navigation only;
2. current change proposal/design/tasks/progress when this effort belongs to a FeaturePilot change;
3. project instructions, CI jobs, test/coverage scripts, wrappers, aliases, configuration, source/test layout, and adjacent tests;
4. current `git status --short`, HEAD, and relevant diff.

Resolve or confirm:

- exact target and metric;
- repository-wide versus explicit owner scope;
- exact numerator and denominator semantics;
- source/include/omit/exclude and branch mode;
- official baseline/final command and narrower target/owner commands;
- writable test/fixture paths, the `coverage-change-root`, and protected runtime paths;
- coverage reports, cache/temp/snapshot/database outputs, with every coverage report redirected beneath `coverage-change-root`;
- policy for production bugs and managed xfails;
- runtime and time/batch budget.

Do not re-ask facts proven by current configuration or CI. `target-must-be-explicit-or-proven`: the target must come from the user's current request or one current authoritative project gate that the user asked this workflow to satisfy. If neither exists, remain `RESOLVING` and ask for the target. You `must not infer target from historical or local coverage`, a prior result, an owner heuristic, or the highest visible percentage. Ask only when a decision changes the metric, write boundary, external-resource use, or final acceptance.

### Metric freeze

Persist the resolved contract before running the baseline. From that point, this workflow must not change it to raise the number.

Use these exact anti-regression anchors:

- `forbid-expand-omit-exclude`: do not expand `omit`/`exclude`;
- `forbid-shrink-source-include`: do not shrink `source`/`include`;
- `forbid-disable-branch`: do not disable branch measurement;
- `forbid-change-metric`: do not replace the agreed metric or denominator.

A legitimate measurement-contract change is a separate, explicitly approved scope. It invalidates prior evidence and requires a new baseline; it is never an in-loop optimization.

## Phase 2: Classify command safety

Inspect every script, alias, wrapper, configuration, and selected variant before execution:

- `SAFE_WITH_DECLARED_OUTPUTS`: runs tests/coverage and writes only enumerated cache, temporary DB, snapshot, generated paths, and coverage reports beneath `coverage-change-root`;
- `APPROVED_COVERAGE_TOOLING_BOOTSTRAP`: after the approval gate, installs only the named coverage dependencies with the existing package manager, updates their existing dependency declaration/lock as declared, and writes only the reviewed minimum coverage configuration;
- `UNSAFE`: unapproved install/upgrade, migration, seed, deploy, snapshot/golden update, production-file format/write, real external service, or destructive Git/file action;
- `UNKNOWN`: side effects or wrapper behavior cannot be proved.

Run only `SAFE_WITH_DECLARED_OUTPUTS`, or the exact `APPROVED_COVERAGE_TOOLING_BOOTSTRAP` that the user approved. Before the first run record current HEAD, `worktree fingerprint`, protected path state, coverage/config/dependency fingerprints, and declared outputs. Coverage-only mode `must not install or upgrade dependencies` outside that narrow approval; missing tooling triggers the workflow below rather than permission to alter the environment silently.

### Missing coverage tooling: approval-gated bootstrap

If a fresh test-only command succeeds but no trustworthy coverage tool, machine-readable report, or authoritative coverage command exists, remain `RESOLVING`, record coverage as `CANNOT_VERIFY`, and do not start an owner batch. This is not a terminal missing-tool block when a safe recommendation can be formed.

Apply `prefer-existing-coverage-toolchain` in this order:

1. reuse an existing authoritative coverage tool, wrapper, or CI command;
2. add only the coverage plugin compatible with the established test runner;
3. propose a new runner-plus-coverage combination only when no compatible runner exists.

`django-fallback-only-without-existing-coverage`: for a proven Django project with no existing coverage solution, when pytest is already established, recommend only `pytest-cov`; when pytest is absent, recommend `pytest + pytest-cov`. Recommend `pytest-django` only when the tests actually require Django's pytest integration. Do not override an existing coverage.py, tox, nox, CI wrapper, or other authoritative solution merely because the Django fallback is familiar.

Before requesting approval, present one `approval gate` containing:

- evidence for project/framework, test runner, package manager, and missing capability;
- the exact dependencies and why each is needed;
- the exact install command and every dependency declaration, lock, and coverage-config path to change;
- the resolved production source, frozen metric/branch/omit rules, and baseline/final commands;
- every raw-data/XML/HTML output beneath `coverage-change-root`;
- the exact rollback boundary if installation or configuration fails.

Without explicit approval, do not install, write configuration, or enter owner batches. If package-manager behavior, dependency persistence, or safe outputs cannot be proved, enter `BLOCKED` with the missing evidence rather than guessing.

After approval, execute only the reviewed `coverage-tooling-bootstrap` with the existing package manager. `persist dependency declaration` in the project's established development/test dependency file and update only the lock data caused by that exact operation; an environment-only install is insufficient. `forbid-bootstrap-scope-expansion`: do not upgrade unrelated packages, replace a working runner, broaden coverage configuration, or change paths outside the approved dependency/declaration/minimum-config list.

Direct coverage raw data and every report beneath `coverage-change-root` before execution. For pytest-cov, the command semantics are:

```text
COVERAGE_FILE=<coverage-change-root>/.coverage
pytest --cov=<resolved-production-source>
  --cov-report=xml:<coverage-change-root>/coverage.xml
  --cov-report=html:<coverage-change-root>/htmlcov
```

Set `COVERAGE_FILE` with the target shell/process environment syntax before launching pytest; the block specifies required command semantics rather than one OS-specific assignment syntax. Never use the repository root as a vague production source or as an intermediate output location.

Dependency/config writes invalidate the earlier test-only result and all coverage evidence. Capture new dependency/config/worktree fingerprints and run a `fresh baseline after bootstrap`; only exact numerator/denominator evidence from that run can move the workflow to `TRIAGING` or `ITERATING`. On failure, record the exact command, exit code, and diff; restore only paths proved to be created or changed by this bootstrap, otherwise preserve them and enter `BLOCKED`.

## Phase 3: Fresh baseline

Run the official full scope with threshold disabled only when that preserves the frozen measurement population and is necessary to measure a sub-target baseline. Record:

- exact command and exit code;
- runtime/tool versions and environment identity;
- current HEAD and worktree/config fingerprints;
- exact `numerator`, `denominator`, and percentage for the frozen metric;
- collected/passed/failed/xfailed/skipped counts;
- report paths beneath `fp-docs/changes/<slug>-coverage/` and other declared side effects;
- per-file/per-module missing elements from the project's machine-readable output.

If the official tool exposes only a rounded percentage and no exact counters or precise value, record `CANNOT_VERIFY`; do not reverse-engineer an exact result from the rounded display.

### Baseline failure triage

If baseline tests fail, enter `TRIAGING`. Re-run the narrowest safe test or node and classify each failure as production behavior, stale expectation, fixture/setup, wrong patch location/substitute, environment/dependency, order pollution, background work, or unknown.

Do not make broad batches until the baseline failure set has dispositions. A production defect remains outside coverage-only writes: record an issue/ticket and enter `BLOCKED`, unless the user explicitly opens a separate production-fix scope.

A managed xfail is allowed only for one reproducible known production defect with exactly `one issue`, a narrow test, an explicit reason, and the framework's strict mode. `forbid-bulk-skip-xfail` applies. Never use `strict=False`.

## Phase 4: Rank gaps

Rank candidates using:

```text
expected coverable elements * behavior risk/value * isolation confidence / test cost
```

Prefer pure logic, validation/error branches, state transitions, services and stable adapters before database, async, network, filesystem, clock, randomness, concurrency, and UI boundaries. Patch where a dependency is looked up, not where originally defined.

Local or owner thresholds are batch heuristics unless explicitly frozen as final acceptance. `local coverage` and a `theoretical upper bound` never prove repository-wide completion.

## Phase 5: Owner-batch RED/GREEN loop

Each `owner batch` has one owner scope and stable batch ID:

1. write/update `.fp-coverage/batches/<batch-id>.md` with the target, fingerprints, last fresh full result, selected gaps, and ranking rationale;
2. run the narrowest gate and observe RED for the intended missing behavior or threshold;
3. add behavior tests with externally observable assertions; mock-call assertions may be secondary, never the only proof;
4. run the target test GREEN;
5. run the complete owner scope suite/coverage GREEN;
6. inspect ordinary failures, unexpected skips, strict xfails/XPASS, warnings, background-thread/process errors, and order pollution;
7. compare protected paths and declared outputs with the pre-run fingerprints;
8. finish the batch evidence with exact results and related `COV-ISSUE-*` IDs, then update only the bounded progress index and next candidate.

Use the project's established test style. Mock real network, brokers, caches, files, clocks, randomness, and external databases unless the project provides an authorized isolated test resource. Use a test database only when the behavior under test requires real persistence semantics.

After enough batches to change the weighted result materially, after any source/test/config/HEAD change outside the current batch, or before a prior full result is cited, perform a `periodic full refresh`. Recompute gaps from fresh output rather than following a stale queue.

## Evidence routing, code issues, and recovery

The following invalidate affected coverage evidence: production or test changes, coverage/test/build config changes, dependency or lock changes, command/test-selection changes, runtime/environment changes, branch/merge/rebase/HEAD changes, unexplained worktree changes, invalid assertions/mocks, and deleted/replaced reports.

Use one file per responsibility:

- `.fp-coverage/contract.md`: frozen target/metric/population, commands, tooling approvals, dependency/config/protected paths, declared outputs, and a contract revision;
- `.fp-coverage/baselines/<run-id>.md`: immutable initial or periodic full evidence;
- `.fp-coverage/batches/<batch-id>.md`: stable owner-batch RED/GREEN evidence, updated only for that batch;
- `.fp-coverage/verifications/<run-id>.md`: immutable final-verification attempt, including failures;
- `.fp-coverage/progress.md`: bounded current state/index only.

Detailed evidence files record the exact command/safety class, fingerprints, test counts, numerator/denominator/percentage, report identity, changed/protected paths, side-effect reconciliation, freshness, and related code-issue IDs. Never overwrite or delete a failed baseline/verification attempt; use a new `run-id`.

The bounded progress index contains only current state/active batch, HEAD/worktree/config/environment fingerprints, contract revision, latest fresh baseline/verification links, batch and issue summary/index, next action, and active blockers. It must not append every command, event, or full result. On resume, read progress first, then only its directly referenced contract, latest fresh evidence, active batch, and issues; do not bulk-read historical evidence.

### Unit-test-discovered code issues

`unit-test-discovered-code-issues-only`: lazily create `issues.md` only when running, triaging, or adding unit tests reveals a reproducible code problem with test/source evidence:

- `production-code`: tested runtime behavior, validation, state, error, concurrency, or resource-cleanup defect;
- `test-code`: assertion, mock/patch, fixture/helper, cleanup, isolation, or test-order defect.

Do not put dependency, environment, CI, coverage config, ordinary uncovered elements, owner candidates, approval waits, stale evidence, unknown side effects, or unproven refactoring suggestions in `issues.md`; route them to contract, evidence, or progress blockers instead.

Use stable `COV-ISSUE-NNN` IDs and deduplicate by category + affected symbol/path + normalized observed behavior + root-cause identity. Repeated evidence updates `Last verified` and links without overwriting human review/disposition. Each issue includes Category, Status, Blocking, Developer review, Severity, first/last dates, affected code, observed/expected/actual behavior, reproduction, code/evidence links, impact, recommendation, external issue, and disposition.

Status is `OPEN | RESOLVED | EXTERNALIZED | ACCEPTED_RISK | INVALID`; Developer review is `PENDING | REVIEWED`. The agent must not mark `Developer review: REVIEWED`; only an explicit developer decision can do so. Do not delete invalid findings: retain `INVALID` with fresh reason. Load `${CLAUDE_PLUGIN_ROOT}/skills/fp-coverage/issues-template.md` only when the first qualifying issue must be written.

A managed strict xfail links one stable `COV-ISSUE-*` and one external issue. `OPEN + Blocking: YES` prevents completion; `RESOLVED` requires fresh test evidence; `EXTERNALIZED`, `ACCEPTED_RISK`, and `INVALID` require developer disposition and must not break another final predicate. Non-blocking pending-review issues may remain only when listed as remaining risks.

## Test side effects and protected paths

After every command, classify changes as intended test edits, approved fixtures, declared outputs, or unexplained/protected changes. To restore a path, prove it was unchanged before the run and changed by that run, then restore only the exact path. If provenance is unknown, preserve it and enter `BLOCKED`.

Never use `git reset --hard`, `git clean`, broad `git restore .`, broad checkout, stash, or deletion of user-owned reports/caches. Never accept snapshot/golden updates merely because the test runner produced them.

## Final verification

Enter `FINAL_VERIFYING` only after owner batches and failure dispositions are reconciled. Run a fresh full-suite official command for the frozen scope and metric. Completion requires all predicates:

```text
full_command_exit_code == 0
AND exact_coverage >= target
AND ordinary_failures == 0
AND unexpected_skips == 0
AND every_managed_xfail_is_strict_and_has_one_issue
AND coverage_scope_and_config_match_frozen_baseline
AND protected_paths_have_no_unexplained_diff
AND evidence_matches_current_HEAD_and_worktree
AND every_blocking_code_issue_has_valid_disposition
AND final_report_references_fresh_final_verification
```

`final-report-only-at-completion-boundary`: while still `FINAL_VERIFYING`, first prove every technical predicate except report existence from the fresh verification. At that `completion boundary`, load `${CLAUDE_PLUGIN_ROOT}/skills/fp-coverage/final-report-template.md`, generate `final-report.md`, link that exact verification, and validate the report fields. Only then satisfy `final_report_references_fresh_final_verification` and transition to `COMPLETE`. Do not create a final report while `BLOCKED`, `CANNOT_VERIFY`, `ITERATING`, interrupted, or before the technical predicates pass. A later HEAD/worktree/config change makes the report stale and requires a new final verification and rewritten report.

If coverage reaches the target while the command exits non-zero, remain `ITERATING` or `BLOCKED`. If exact counters are unavailable, report `CANNOT_VERIFY`. A `stale historical report`, rounded display, `local coverage`, or `theoretical upper bound` cannot satisfy the final gate.

## Forbidden shortcuts and red flags

Stop and correct course when anyone proposes:

- `forbid-expand-omit-exclude`, `forbid-shrink-source-include`, `forbid-disable-branch`, or `forbid-change-metric`;
- `forbid-bulk-skip-xfail`, `strict=False`, hidden skips, weakened assertions, or tests that only verify mocks;
- copying production logic into tests, instrumenting the coverage tracer, deleting difficult runtime code, or excluding newly changed code;
- reusing a stale historical report, local percentage, estimate, rounded integer, or theoretical upper bound as final proof;
- coverage reports outside `fp-docs/changes/<slug>-coverage/`, including project-root `coverage.xml` or `htmlcov/` (`forbid-project-root-coverage-output`);
- broad cleanup (`git reset --hard`, `git clean`, `git restore .`) or deletion without provenance;
- coverage-only production writes, unapproved dependency installation/upgrade, bootstrap changes outside the approved coverage dependencies/declarations/minimum config, real external services, commit, push, rebase, or force push without explicit authorization.

The deadline, a manager request, an expensive full suite, or a number already above target does not change these gates.

## CodeGraph lifecycle

When code localization or impact analysis is useful, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/codegraph.md` and follow `MCP -> CLI -> native search`. Graph results only rank candidates; verify current source/tests before acting.

The first test, fixture, configuration, schema, generator input, or source write marks the graph `dirty-after-write`. From then on, `never query a dirty graph`; use current native search. If `.codegraph/` existed before writes, perform at most one `post-write-sync` before each user-visible return:

```text
codegraph sync <project-root> --quiet
```

The sync `must not block completion`; do not query again afterward or initialize a missing graph.

## Output contract

At each user-visible checkpoint report, in this order:

1. current state and batch;
2. frozen metric and target;
3. fresh evidence snapshot and exact counters;
4. test result counts and command exit code;
5. changed/protected paths and side-effect disposition;
6. issues/strict xfails/blockers;
7. freshness status;
8. next batch or exact final-gate gap.

Only report `COMPLETE` when the final predicate is fully proven. Otherwise lead with `BLOCKED`, `CANNOT_VERIFY`, or the active state and the missing evidence.
