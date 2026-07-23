# FeaturePilot SDD Review Package Template

Use this template for `.fp-execute/packages/<task-id>-review-package.md` after an implementer reports `DONE` or `DONE_WITH_CONCERNS`.
Resolve and record inputs under the artifact-layout contract already loaded by the owning `fp-execute-sdd` controller. The package is canonical-first Consumer evidence, never a Producer rewrite or migration.

```markdown
# Review Package: <task-id>

## Inputs

- Task brief: `<.fp-execute/briefs/<task-id>-brief.md>`
- Implementer report: `<.fp-execute/reports/<task-id>-report.md>`
- Task owner file: `<exact resolved task-owner path>`
- Resolved plan context: `<selected small plan OR split index plus manifest-ordered fragments; two-end overview only when applicable>`
- Progress ledger: `<fp-docs/changes/<slug>/.fp-execute/progress.md>`
- reviewScopeId: `<stable task review scope id>`
- reviewAttempt: `<1 | 2 | 3>`
- maxReviewAttempts=3
- priorReviewPath: `<path or N/A>`
- priorFindingDispositions: `<finding-id -> disposition or N/A>`
- lastReviewedHead: `<prior completed attempt HEAD or N/A>`
- finalReviewPackage: `N/A` for a task review package

The controller restores the same scope and attempt after interruption; reviewer, commit, session, or finding identity never resets it, and attempt 4 is forbidden.

## Artifact Resolution Evidence

Record split entries in complete manifest order and record `N/A` for small or absent artifacts.

| Logical artifact | Canonical entry | Resolution mode | Ordered fragments |
| --- | --- | --- | --- |
| PRD | `<prd.md OR prd/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |
| Proposal | `<proposal.md OR proposal/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |
| Backend design | `<design/backend.md OR design/backend/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |
| Frontend design | `<design/frontend.md OR design/frontend/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |
| Backend plan | `<tasks/plan-backend.md OR tasks/backend/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |
| Frontend plan | `<tasks/plan-frontend.md OR tasks/frontend/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |

- Structural conflict: `None` (otherwise no review package may be dispatched)
- Ownership proof: <manifest Kind=`tasks`; `tasks`-kind fragment; unique task owner checkbox/path>
- Overview proof: `<two-end overview cross-end edges and derived totals, or single-end/no overview>`
- Rejections checked: `<indexless split, missing/unindexed fragment, duplicate owner/ID/checkbox, forbidden checkbox, missing reference, cycle>`

## Git Range

- Base SHA before task: `<sha>`
- Head SHA after task/fix: `<sha>`
- Diff command: `git diff <base>..<head> -- <relevant paths>`

## Commits

```text
<git log --oneline <base>..<head>>
```

## Diff Stat

```text
<git diff --stat <base>..<head> -- <relevant paths>>
```

## Test and Validation Evidence

From implementer report and controller verification. Classify every proposed command before execution; only a `SAFE` variant whose definitions were inspected may run. `UNSAFE` and `UNKNOWN` must not run.

| Command | Safety | Definition evidence | Result | Evidence |
| --- | --- | --- | --- | --- |
| `<command>` | `SAFE / UNSAFE / UNKNOWN` | `<script/wrapper/config path or N/A>` | `PASS / FAIL / SKIPPED` | `<key output or report section>` |

Treat `--fix`, `--write`, snapshot update, migration, seed, formatter, generator, cache, coverage, dist, unknown wrapper, service startup, database mutation, and external mutation as `UNSAFE` or `UNKNOWN`; they must not run during review. Record a proven safe variant or the evidence gap.

## Information Layer Evidence

Review the task's `dynamic task context`; absent optional sources are `N/A`.

| Dynamic brief/package source | Path/query or N/A | Used for | Current-source proof |
| --- | --- | --- | --- |
| Manifest | `<path or N/A>` | `<index/precedence or N/A>` | `<evidence or N/A>` |
| Relevant settings | `<paths or N/A>` | `<constraints or N/A>` | `<evidence or N/A>` |
| Optional project facts | `<path/section or N/A>` | `<navigation hint or N/A>` | `<re-opened source or N/A>` |
| Current change artifacts | `<paths>` | `<target contract>` | `<canonical resolution evidence>` |
| Current source/config | `<paths>` | `<current behavior>` | `<line/command evidence>` |
| CodeGraph/native search candidates | `<query/paths or N/A>` | `<candidate scope or N/A>` | `<verified path or N/A>` |
| Human-owned/legacy knowledge | `<paths or N/A>` | `<unknown/decision hint or N/A>` | `<resolution evidence or N/A>` |

- Static handoff absence is not a blocker; completeness is judged from these `dynamic brief/package sources`.
- Stale/conflict sections found: `<live result or N/A>`
- CodeGraph `explore`, `impact`, and `affected` results are candidates only; verify with current source/diff, native search, tests, or command output. Missing/stale/unavailable graph uses native fallback and must not block review.

## Known Concerns

- `<none or implementer/controller concern>`

## Visual Evidence Manifest (frontend/UI only)

Evidence root: `.fp-execute/visual/<task-id>/<case-id>/`.

| Case ID | Approved design source | Figma node | revision/time | Frame/variant | variables / Auto Layout / assets | Runtime route | Scenario/state | Viewport | DPR | Locale | Theme | Deterministic non-sensitive fixture | Reference path | Current path | Diff path / missing diff | Mask | Acceptance rule | Command/tool | Failure class | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `<case-id>` | `<approved Figma/static design source>` | `<node or N/A>` | `<revision/time or approved-source time>` | `<frame/variant>` | `<available context or N/A>` | `<real target runtime route>` | `<scenario/state>` | `<viewport>` | `<DPR>` | `<locale>` | `<theme>` | `<stable fixture; no secrets or production/customer data>` | `.fp-execute/visual/<task-id>/<case-id>/reference.png` | `.fp-execute/visual/<task-id>/<case-id>/current.png` | `.fp-execute/visual/<task-id>/<case-id>/diff.png` or `N/A: <missing diff explanation>` | `<mask>` | `<case-specific rule>` | `<project-configured replay command/tool>` | `<core visual/non-core cosmetic>` | `<PASS/FAIL/CANNOT_VERIFY>` |

- Provenance check: approved-source `reference.png`; local runtime screenshot must not replace it. Real target runtime `current.png` with stable data and stable environment. An optional diff or missing diff explanation must not hide missing core source/runtime evidence.
- Browser interaction evidence: `<separate paths/results exercising approved states>`
- Screenshot evidence: `<manifest/reference/current/optional diff paths and hashes/times>`

- Provenance: reference.png -> approved Figma/static design source; current.png -> real target runtime.
- Local runtime screenshot must not replace reference.png. current.png requires stable data and stable environment. Optional diff/missing diff explanation must not hide absent core source/runtime evidence.
- Evidence channels: browser interaction evidence is separate from screenshot evidence; browser interaction evidence must exercise approved states, and screenshot evidence must record case artifacts.

## Full Diff With Context

```diff
<git diff <base>..<head> -- <relevant paths>>
```
```
