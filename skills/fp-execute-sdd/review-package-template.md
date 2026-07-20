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

From implementer report and controller verification:

| Command | Result | Evidence |
| --- | --- | --- |
| `<command>` | `PASS/FAIL` | `<key output or report section>` |

## Information Layer Evidence

- Manifest read:
- Settings considered:
- Intel considered:
- Unknowns checked:
- Stale sections found:
- Source files re-opened:

## Known Concerns

- `<none or implementer/controller concern>`

## Full Diff With Context

```diff
<git diff <base>..<head> -- <relevant paths>>
```
```
