# Module Review: <slug>

## Current Status

- State: `<SCOPING | BASELINING | REVIEWING | TRIAGING | WAITING_APPROVAL | FIXING | VERIFYING | BLOCKED | COMPLETE_WITH_AWAITING | COMPLETE>`
- Mode: `<full | review-only | resume>`
- Current wave: `<wave ID | N/A>`
- Snapshot: `<HEAD and working-tree fingerprint>`

## Quick Summary

- Targets: `<bounded targets>`
- Scope: `<short boundary>`
- Findings: `<counts by state and severity>`
- Next: `<one exact decision or action>`

## Canonical Artifact Manifest

Read these owners in `Order`; no unlisted Markdown file owns review state.

| Order | File | Owner |
| ---: | --- | --- |
| 1 | `scope.md` | Targets, integrations, dimensions, exclusions, precedence, write/protected paths, external authorization |
| 2 | `baseline.md` | Snapshot, observable contracts, test baseline, command safety, evidence gaps |
| 3 | `waves.md` | Review waves, dependencies, status, candidate reconciliation |
| 4..N | `findings/MR-FNNN.md` | Exactly one stable Finding per listed file |
| N+1 | `summary.md` | Final reconciliation, verification, awaiting decisions, completion status |
| N+2 | `.fp-module-review/progress.md` | Append-only recovery evidence; never Finding status authority |

## Finding Counts

| State | Critical | High | Medium | Low | Total |
| --- | ---: | ---: | ---: | ---: | ---: |
| candidate | 0 | 0 | 0 | 0 | 0 |
| confirmed | 0 | 0 | 0 | 0 | 0 |
| awaiting-user-confirmation | 0 | 0 | 0 | 0 | 0 |
| approved | 0 | 0 | 0 | 0 | 0 |
| fixed | 0 | 0 | 0 | 0 | 0 |
| rejected | 0 | 0 | 0 | 0 | 0 |
| blocked | 0 | 0 | 0 | 0 | 0 |

## Resume Entry

Start with `review.md`, verify every manifest owner and uniqueness rule, then read the last `.fp-module-review/progress.md` event and apply the skill's invalidation contract.
