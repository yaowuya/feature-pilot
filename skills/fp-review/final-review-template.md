# Final FeaturePilot Review: <slug>

Resolution follows `../_shared/artifact-layout.md`. This report records canonical-first Consumer evidence in manifest order and rejects every historical or dual structural conflict before review.

叙述性内容默认使用中文；代码、命令、路径、技术标识符、API 字段以及契约要求精确匹配的英文 schema 标题保留必要英文。若用户或目标项目设置明确指定其他语言，按共享优先级执行。

**Verdict:** PASS | PASS_WITH_NOTES | FAIL | BLOCKED
**Reviewer:** read-only fp-review
**Review Time:** YYYY-MM-DD HH:MM
**Base Ref:** <baseRef>
**Head Ref:** <headRef or sha>
**Change Path:** fp-docs/changes/<slug>
**Review Depth:** standard | strict
**Focus:** <focus or none>

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
- Diff: `<baseRef>...<headRef>`

## Branch State

- Working tree: clean | dirty
- Dirty files: <none or list>
- Commits reviewed: <count>
- Changed files reviewed: <count>

## FeaturePilot Coverage

| Source | Requirement / Task | Status | Evidence |
| --- | --- | --- | --- |
| `manifest/settings/intel` | Read order, relevant settings, SDD handoff, Unknowns, freshness | Covered / Partial / Missing / N/A | `<brief/package/progress/source>` |
| proposal/design/tasks | <requirement> | Covered / Partial / Missing / Violated / N/A | <file/test/commit> |

## Verification Commands

| Command | Result | Notes |
| --- | --- | --- |
| `<command>` | PASS / FAIL / SKIPPED | <key output or reason> |

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
