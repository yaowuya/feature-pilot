# MR-FNNN — <title>

- Wave: `<WNN — owner boundary>`
- Evidence: `<repository-relative path:line or symbol>`
- Trigger: `<concrete input/state/order>`
- Wrong result or risk: `<observable wrong output/failure/material risk>`
- Supplementary proof: `<deterministic test, reproduction, verified call path, contract contradiction, lifecycle/resource violation, or safe command output>`
- Severity: `<Critical | High | Medium | Low>`
- Observable behavior impact: `<none | exact current → proposed change and affected consumers>`
- State: `<candidate | confirmed | awaiting-user-confirmation | approved | fixed | rejected | blocked>`
- Disposition: `<decision, approver evidence when required, and exact authorized paths>`
- Test mapping: `<test ID/path | external reproduction path | not-yet-created>`
- RED: `<exact command and expected Finding-specific failure | not-run with reason>`
- GREEN: `<exact command and result | not-run until fixed>`
- Adjacent regression: `<owner-scope/full command and result | not-run until fixed>`
- Rollback: `<minimal rollback direction>`
- Residual risk: `<remaining risk, awaiting decision, skipped evidence, or none>`

## State History

| Timestamp | From | To | Evidence/decision |
| --- | --- | --- | --- |
| `<time>` | `<none/state>` | `<state>` | `<current evidence or explicit stable-ID approval>` |

IDs are monotonic and never reused. Expected failures map to exactly one Finding and never count as `fixed`.
