# Coverage Code Issues

> Create this file as `fp-docs/changes/<slug>-coverage/issues.md` only when the first qualifying unit-test-discovered code issue appears. Copy each issue section; do not retain instructional text.

## Scope

Only record reproducible code problems discovered while running, triaging, or adding unit tests:

- `production-code`: defects in tested runtime behavior, validation, state, errors, concurrency, or resource cleanup;
- `test-code`: defects in assertions, mocks/patches, fixtures/helpers, cleanup, or test isolation/order.

Do not record dependency, environment, CI, coverage configuration, ordinary uncovered elements, approval waits, stale evidence, unknown side effects, or unproven refactoring suggestions.

## COV-ISSUE-NNN: <concise title>

- Category: `production-code | test-code`
- Status: `OPEN | RESOLVED | EXTERNALIZED | ACCEPTED_RISK | INVALID`
- Blocking: `YES | NO`
- Developer review: `PENDING | REVIEWED`
- Severity: `CRITICAL | HIGH | MEDIUM | LOW`
- First seen: `<timestamp>`
- Last verified: `<timestamp>`
- Affected code: `<path:symbol-or-line>`
- External issue: `<URL-or-ID | N/A>`

### Observed behavior

<Externally observable behavior found by the unit test.>

### Expected behavior

<Current authoritative expected behavior.>

### Actual behavior

<What the production or test code does instead.>

### Reproduction

```text
<exact narrow safe command or test node ID>
```

### Code evidence

- Source: `<path:line-or-symbol>`
- Test: `<path:test-node>`
- HEAD: `<commit>`
- Worktree fingerprint: `<fingerprint>`

### Related evidence

- Baseline / batch / verification: `<relative evidence path>`
- Exit code and test result: `<exact result>`

### Impact

<Effect on production behavior, test trustworthiness, or final coverage evidence.>

### Recommended action

<Smallest developer action or decision.>

### Disposition

<Developer decision, fresh resolution evidence, externalization, accepted-risk rationale, or invalidation reason.>
