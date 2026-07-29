# FeaturePilot Module Review Skill Design

**Date:** 2026-07-28
**Status:** Approved

## Goal

Add a reusable FeaturePilot workflow for evidence-driven review of one large functional module or several related modules. The workflow must preserve the proven properties of the SSH node channel review in `D:/02-canway/01-code/ops-node-server/fp-docs/changes/ssh-node-channel-review`: bounded scope, compatibility and test baselines, stable finding ownership, module waves, approval gates for observable behavior changes, minimal test-driven fixes, repeatable verification, and append-only recovery evidence.

Also rename the existing final whole-branch review skill from `fp-review` to the clearer `fp-final-review` so users can distinguish the two review workflows.

## Naming and Responsibilities

### `fp-module-review`

`fp-module-review` is the full-lifecycle workflow for a user-selected large module or related set of modules. It may review, triage, test, fix, and verify findings under explicit gates.

It is not a general repository audit, a small diff review, or an archive gate. The user supplies one or more module targets, and the skill expands scope only to direct integration points proven by current code or approved contracts.

### `fp-final-review`

`fp-final-review` is the renamed existing `fp-review`. It remains the read-only final whole-branch review for a completed FeaturePilot change before archive or merge.

The rename is complete rather than an alias:

- rename the command entry;
- rename the skill directory and frontmatter name;
- rename the focused contract validator;
- update all orchestrator, documentation, template, validator, and runtime references;
- reject unexplained remaining `fp-review` identifiers after migration.

Historical prose that explicitly explains the rename may mention `fp-review`; runtime paths, commands, skill names, and active workflow instructions may not.

## Inputs

`fp-module-review` accepts natural-language input and these explicit fields when present:

- `slug`: stable review workspace name. When absent, derive a deterministic kebab-case slug from the selected module names and state the choice.
- `targets`: one or more repository-relative directories, files, symbols, or named functional modules. At least one resolvable target is required.
- `focus`: optional dimensions such as correctness, contracts, security, lifecycle, concurrency, resource ownership, performance, tests, or production readiness.
- `mode`: `full` by default, `review-only` to prohibit implementation, or `resume` to continue an existing workspace.
- `baseRef`: optional diff navigation base. The current source remains the authority; a diff never defines the complete module scope.

If more than one existing workspace or target interpretation remains plausible, the skill asks one bounded question. It never silently broadens to the whole repository.

## Workspace and Artifact Ownership

The workspace is repository-owned and independent of FeaturePilot change artifacts:

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

Ownership rules:

- `review.md` is the stable entry and canonical manifest. It owns only quick status and the ordered artifact list.
- `scope.md` exclusively owns targets, direct integration boundaries, exclusions, constraints, and fact precedence.
- `baseline.md` exclusively owns observable compatibility contracts and the fresh existing-test baseline.
- `waves.md` exclusively owns wave definitions, dependencies, status, and evidence links.
- Each `findings/MR-FNNN.md` exclusively owns one finding's evidence and disposition. IDs are monotonically allocated, never reused, and never renamed because severity or status changes.
- `summary.md` exclusively owns reconciled counts, final verification, unresolved approval items, and delivery boundaries.
- `.fp-module-review/progress.md` is append-only recovery evidence. It never owns finding status or replaces artifact updates.

The skill uses the small fixed workspace above. Finding files are already isolated owner documents; no alternative monolithic/split representation is introduced.

## Lifecycle

The skill records exactly one current state:

```text
SCOPING
BASELINING
REVIEWING
TRIAGING
WAITING_APPROVAL
FIXING
VERIFYING
BLOCKED
COMPLETE_WITH_AWAITING
COMPLETE
```

Normal flow:

```text
SCOPING
→ BASELINING
→ REVIEWING
→ TRIAGING
→ WAITING_APPROVAL or FIXING
→ VERIFYING
→ COMPLETE_WITH_AWAITING or COMPLETE
```

`BLOCKED` may be entered from any state with a concrete recovery condition. `resume` validates current HEAD, working-tree inventory, scope, artifact manifest, finding owners, and last progress event before choosing the continuation point.

### Read/write isolation

- `SCOPING`, `BASELINING`, `REVIEWING`, and `TRIAGING` are read-only for product source and existing tests. They may create or update only module-review artifacts.
- Candidate discovery never edits implementation.
- `FIXING` may edit the exact source/test paths authorized by confirmed finding owners.
- `review-only` never enters `FIXING`; it concludes with verified findings and explicit unresolved dispositions.
- The skill does not commit unless the user separately authorizes Git commits.

## Scope and Baselines

### Scope inventory

`SCOPING` resolves the project root and reads project instructions, `fp-docs/manifest.md` and relevant information-layer files when present, selected targets, direct imports/callers/registrations/configuration, adjacent tests, and the current Git state.

The scope contains:

- declared targets;
- proven direct integration points;
- relevant tests and configuration;
- explicit exclusions;
- allowed write paths;
- protected paths;
- unavailable or unauthorized external systems.

CodeGraph follows the project `MCP → CLI → native search` rule and is navigation only. Every scope edge and later finding is verified against current source or command output.

### Compatibility baseline

Before findings can authorize behavior changes, `BASELINING` records externally observable contracts relevant to the targets, including API/schema, status, error, timing, logging, callback, persistence, configuration, resource lifecycle, or UI behavior as applicable.

### Test baseline

The skill inspects command definitions before execution. It records the exact safe command, environment, exit code, passed/failed/skipped/expected-failure counts, warnings or background errors, and known gaps. A failing baseline is evidence to triage, not permission to rewrite assertions or hide failures.

Commands are classified as:

- `SAFE`: proven read-only or writes only declared isolated test/report/cache outputs;
- `UNSAFE`: installs, deploys, migrates, seeds, formats production code, updates snapshots, mutates external systems, or performs destructive Git/file operations;
- `UNKNOWN`: side effects cannot be proved.

Only `SAFE` commands run automatically. `UNSAFE` and `UNKNOWN` commands are skipped with the evidence gap recorded.

## Review Waves

The controller partitions work by coherent ownership and call flow, not arbitrary file counts. Typical dimensions are:

- public API, schema, and contracts;
- core domain/service behavior;
- state, queue, scheduler, and concurrency;
- lifecycle, cleanup, cancellation, and resource ownership;
- storage, transfer, cache, and external integration;
- logging, callbacks, configuration, security, and production readiness;
- tests and final reconciliation.

Each wave names its owned targets, direct integration points, review dimensions, dependencies, verification candidates, and completion evidence. Independent waves may use parallel read-only agents, but the main controller must verify candidates against current source, deduplicate them, assign stable IDs, and write owner documents. Agents never allocate final IDs independently.

A wave is complete when every owned path and review dimension has an evidence-backed disposition, including an explicit `no finding` result where applicable.

## Finding Contract

A candidate becomes a confirmed finding only when current source plus at least one supplementary proof demonstrates a concrete failure or material risk. Supplementary proof may be a deterministic failing test, reproduction, call path, contract contradiction, resource-lifecycle violation, or safe command output.

Every finding owner records:

- stable ID and title;
- source wave;
- evidence with repository-relative path and line or symbol;
- trigger condition;
- wrong result or risk;
- supplementary proof;
- severity;
- observable behavior impact;
- state;
- disposition;
- test mapping;
- RED evidence;
- GREEN evidence;
- adjacent/full regression evidence;
- rollback direction;
- residual risk.

Allowed transitions:

| State | Allowed next states |
| --- | --- |
| `candidate` | `confirmed`, `rejected` |
| `confirmed` | `awaiting-user-confirmation`, `fixed`, `blocked` |
| `awaiting-user-confirmation` | `approved`, `blocked` |
| `approved` | `fixed`, `blocked` |
| `fixed` | terminal |
| `rejected` | terminal |
| `blocked` | `approved`, `fixed` |

Severity uses `Critical`, `High`, `Medium`, and `Low` for concrete impact, not style preferences.

Observable behavior includes accepted inputs, API and schema, responses, errors, status, timing, logs, callbacks, storage/retention, permissions, security policy, deployment compatibility, and user-visible behavior. Any confirmed finding with non-`none` observable impact enters `awaiting-user-confirmation`. Production code for that finding cannot change until the user explicitly approves its stable ID and proposed behavior.

## Controlled Fixing

A finding may enter `FIXING` when either:

1. it is confirmed and the observable impact is `none`; or
2. the user explicitly approved its stable ID and proposed change.

Each fix follows a bounded TDD loop:

1. write or identify the narrow deterministic failing behavior test;
2. run it and verify it fails for the finding's intended reason;
3. apply the minimum production change;
4. run the target test to GREEN;
5. run the complete owner scope and adjacent regression;
6. inspect unexpected skips, expected failures, warnings, background errors, and protected-path changes;
7. update the finding owner and append a progress event.

The skill must not refactor unrelated code, broaden scope to make a fix easier, install dependencies without authorization, contact real external systems without authorization, or weaken/remove assertions to obtain green output.

For approved-but-unimplemented or awaiting findings, deterministic tests may be retained as strict expected failures only when the test framework makes unexpected pass fail the suite and the test points to exactly one finding. Otherwise, keep the reproduction outside the ordinary green suite and record the limitation. Expected failures never count as fixed.

## Verification and Completion

`VERIFYING` reconciles:

- every declared target and direct integration point;
- every wave and review dimension;
- every allocated finding ID and unique owner;
- candidate/confirmed/approved/fixed/rejected/blocked/awaiting counts;
- RED/GREEN/regression evidence freshness;
- command safety and skipped evidence;
- current HEAD and working-tree scope;
- changed, allowed, protected, and unexplained paths;
- optional CodeGraph post-write sync after source writes.

`COMPLETE` requires:

- all waves completed;
- no `candidate`, `confirmed`, `approved`, or `blocked` finding remains;
- all fixed findings have fresh RED/GREEN/adjacent regression evidence;
- required safe verification passes;
- no unexplained protected or out-of-scope changes;
- summary evidence matches current HEAD and working tree.

`COMPLETE_WITH_AWAITING` requires the same conditions except one or more findings remain `awaiting-user-confirmation`, with production behavior unchanged and their deterministic evidence preserved. It must report exact IDs and cannot claim all defects are fixed.

A required baseline or verification that cannot safely run may force `BLOCKED`; otherwise the summary states `CANNOT_VERIFY` for the affected claim and cannot overstate completion.

## Command and Skill Packaging

Add:

- `commands/fp-module-review.md`;
- `skills/fp-module-review/SKILL.md`;
- lazy-loaded artifact templates or contract references needed to keep the main skill under repository limits;
- `scripts/test-module-review-contract.ps1`.

Rename:

- `commands/fp-review.md` → `commands/fp-final-review.md`;
- `skills/fp-review/` → `skills/fp-final-review/`;
- `scripts/test-review-contract.ps1` → `scripts/test-final-review-contract.ps1`;
- all active references and expected skill maps from `fp-review` to `fp-final-review`.

Update user-facing documentation and plugin validation without overwriting concurrent `fp-coverage` work. Shared files are edited only after reading their latest content, and edits are limited to the review rename and module-review registration/contract.

## Testing Strategy

### Focused module-review contract

The focused validator checks:

- command-to-skill anchor and frontmatter;
- distinct responsibility from `fp-final-review`;
- workspace paths and unique artifact ownership;
- fixed lifecycle states;
- read-only discovery/triage gates;
- stable finding IDs and schema;
- observable behavior approval gate;
- TDD fix loop and strict expected-failure rule;
- command safety classification;
- `COMPLETE` and `COMPLETE_WITH_AWAITING` predicates;
- resume and append-only progress semantics;
- CodeGraph navigation-only and post-write behavior.

### Final-review rename contract

The renamed focused validator checks the same behavior as the current validator under new paths and identifiers. A repository scan rejects active old identifiers except the design/plan migration record.

### Full validation

Run:

- module-review focused contract;
- final-review focused contract;
- existing focused contracts, including concurrent coverage when present;
- `scripts/validate-plugin.ps1`;
- `git diff --check`;
- targeted search for active `fp-review` references;
- Git status review proving unrelated concurrent files were not overwritten.

## Non-goals

- Automatically reviewing the whole repository when module targets are absent.
- Replacing pull-request review, `fp-final-review`, or generic security audit skills.
- Creating a separate fix skill.
- Automatically accepting observable behavior changes.
- Automatically installing test, lint, graph, or coverage tooling.
- Requiring CodeGraph.
- Committing, pushing, opening pull requests, or archiving without explicit authorization.
