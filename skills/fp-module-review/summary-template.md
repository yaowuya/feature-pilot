# Module Review Summary

## Scope Reconciliation

| Target/integration | Planned dimensions | Reviewed evidence | Result |
| --- | --- | --- | --- |
| `<owner>` | `<dimensions>` | `<source/tests/commands>` | `<covered | partial | blocked>` |

## Wave Reconciliation

| Wave | Status | Findings/no-finding evidence | Verification |
| --- | --- | --- | --- |
| `<WNN>` | `<complete/status>` | `<IDs or explicit evidence>` | `<commands/results>` |

## Finding Reconciliation

| State | Critical | High | Medium | Low | Exact IDs | Total |
| --- | ---: | ---: | ---: | ---: | --- | ---: |
| candidate | 0 | 0 | 0 | 0 | `none` | 0 |
| confirmed | 0 | 0 | 0 | 0 | `none` | 0 |
| awaiting-user-confirmation | 0 | 0 | 0 | 0 | `none` | 0 |
| approved | 0 | 0 | 0 | 0 | `none` | 0 |
| fixed | 0 | 0 | 0 | 0 | `none` | 0 |
| rejected | 0 | 0 | 0 | 0 | `none` | 0 |
| blocked | 0 | 0 | 0 | 0 | `none` | 0 |

## Verification Commands

| Command | Safety | Result | Key evidence |
| --- | --- | --- | --- |
| `<exact command>` | `<SAFE>` | `<PASS | FAIL | SKIPPED>` | `<counts/output>` |

## Changed and Protected Paths

| Path | Classification | Finding authorization | Disposition |
| --- | --- | --- | --- |
| `<path>` | `<review artifact | allowed test/source | protected | unexplained>` | `<MR-FNNN | N/A>` | `<accepted | blocked>` |

## Awaiting Approval

- Exact IDs: `<MR-FNNN list | none>`
- Decisions: `<current behavior, proposed behavior, impact, rollback>`

## Completion Status

- State: `<BLOCKED | COMPLETE_WITH_AWAITING | COMPLETE>`
- Current HEAD: `<SHA>`
- Current working tree fingerprint: `<identity>`
- Rationale: `<all predicates and exceptions>`

`COMPLETE_WITH_AWAITING` lists exact IDs, keeps production behavior unchanged, and must not claim all defects are fixed or the module is fully remediated.

## CANNOT_VERIFY Claims

- `<claim>`: `<missing/unsafe/stale evidence and recovery>`

## Delivery Boundaries

- `<not-run external systems, dependency/tool gaps, uncommitted state, and next action>`
