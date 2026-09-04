# Coverage Improvement Final Report

> Generate `fp-docs/changes/<slug>-coverage/final-report.md` at the `FINAL_VERIFYING` completion boundary, after all technical predicates pass and before transitioning to `COMPLETE`. Replace every placeholder with fresh evidence; validate the report, then enter `COMPLETE`. Do not retain instructional text.

## Result

- Status: `COMPLETE`
- Target: `<metric and threshold>`
- Baseline: `<exact numerator / denominator = percentage>`
- Final: `<exact numerator / denominator = percentage>`
- Delta: `<percentage-point and counter delta>`
- Final command exit code: `0`
- Final verification: `.fp-coverage/verifications/<run-id>.md`

## Test results

- Collected: `<count>`
- Passed: `<count>`
- Failed: `0`
- Strict xfailed: `<count>`
- Skipped: `<count>`
- Unexpected skips: `0` (`<disposition for expected skips or none>`)
- Warnings / background errors: `<none or exact disposition>`

## Measurement contract

- Contract revision: `<revision>`
- Metric and target: `<value>`
- Numerator / denominator semantics: `<value>`
- Source / include: `<value>`
- Omit / exclude: `<value>`
- Branch mode: `<value>`
- Test selection: `<value>`
- Official final command: `<exact command>`
- Report paths: `<coverage-change-root paths>`

## Work completed

| Owner batch | Scope | Test behavior added or corrected | Coverage delta | Evidence |
| --- | --- | --- | --- | --- |
| `<batch-id>` | `<scope>` | `<summary>` | `<exact delta>` | `.fp-coverage/batches/<batch-id>.md` |

## Code issues discovered

- Total: `<count>`
- Production-code: `<count>`
- Test-code: `<count>`
- Resolved: `<count>`
- Externalized: `<count>`
- Accepted risk: `<count>`
- Invalid: `<count>`
- Pending developer review: `<count>`
- Blocking remaining: `0`
- Ledger: `issues.md | N/A (none discovered)`

## Changed paths

- Production code: `<paths or none>`
- Test code: `<paths or none>`
- Fixtures: `<paths or none>`
- Dependency / configuration: `<paths or none>`
- Coverage evidence: `<paths>`

## Managed xfails

| Test | COV-ISSUE ID | External issue | Strict | Reason |
| --- | --- | --- | --- | --- |
| `<node or none>` | `<ID>` | `<URL/ID>` | `true` | `<reason>` |

## Side-effect reconciliation

- Protected paths: `<result>`
- Declared outputs: `<result>`
- Unexplained diff: `none`

## Completion predicates

| Predicate | Result | Fresh evidence |
| --- | --- | --- |
| Full command exit code is zero | `PASS` | `.fp-coverage/verifications/<run-id>.md` |
| Exact coverage reaches target | `PASS` | `.fp-coverage/verifications/<run-id>.md` |
| Ordinary failures are zero | `PASS` | `.fp-coverage/verifications/<run-id>.md` |
| Unexpected skips are zero | `PASS` | `.fp-coverage/verifications/<run-id>.md` |
| Managed xfails have strict issue mapping | `PASS` | `<evidence>` |
| Measurement contract matches baseline | `PASS` | `.fp-coverage/contract.md` |
| Protected paths have no unexplained diff | `PASS` | `.fp-coverage/verifications/<run-id>.md` |
| Evidence matches current HEAD/worktree | `PASS` | `.fp-coverage/verifications/<run-id>.md` |
| Blocking code issues have valid disposition | `PASS` | `issues.md | N/A` |

## Remaining risks

<List every non-blocking unresolved, externalized, accepted-risk, or pending-review code issue; use `none` only when proven.>

## Evidence index

- Contract: `.fp-coverage/contract.md`
- Initial / latest baseline: `.fp-coverage/baselines/<run-id>.md`
- Final verification: `.fp-coverage/verifications/<run-id>.md`
- Coverage XML: `coverage.xml | project-equivalent`
- HTML report: `htmlcov/ | project-equivalent`
- Code issues: `issues.md | N/A`
