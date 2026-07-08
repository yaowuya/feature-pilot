# FeaturePilot SDD Review Package Template

Use this template for `.fp-execute/packages/<task-id>-review-package.md` after an implementer reports `DONE` or `DONE_WITH_CONCERNS`.

```markdown
# Review Package: <task-id>

## Inputs

- Task brief: `<.fp-execute/briefs/<task-id>-brief.md>`
- Implementer report: `<.fp-execute/reports/<task-id>-report.md>`
- Plan file: `<fp-docs/changes/<slug>/tasks/plan-*.md>`
- Progress ledger: `<fp-docs/changes/<slug>/.fp-execute/progress.md>`

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
