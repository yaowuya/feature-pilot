# Scope

## Targets

| Target | Type | Resolution evidence | Included behavior |
| --- | --- | --- | --- |
| `<path/symbol/module>` | `<directory/file/symbol/module>` | `<current-source evidence>` | `<behavior boundary>` |

## Direct Integration Points

| Integration | Relation to target | Current-source proof | In-scope reason |
| --- | --- | --- | --- |
| `<path/symbol>` | `<caller/import/registration/config/persistence/lifecycle>` | `<path:line or symbol>` | `<effect on target>` |

## Review Dimensions

- `<correctness/contracts/security/lifecycle/concurrency/resource ownership/performance/tests/production readiness>`

## Exclusions

- `<explicit exclusion and reason>`

## Fact Precedence

1. Current source and safe command output.
2. Approved current contracts and human-owned decisions.
3. Tests and current configuration.
4. Fresh project facts.
5. CodeGraph and generated/historical material as navigation only.

## Allowed Write Paths

- Review artifacts: `fp-docs/module-reviews/<slug>/**`
- Finding-authorized tests: `<paths | none>`
- Finding-authorized production paths: `<paths | none before FIXING>`

## Protected Paths

- `<runtime/config/data/fixture/source paths that must not change without Finding authorization>`

## External-System Authorization

| System | Allowed action | Authorization evidence | Otherwise |
| --- | --- | --- | --- |
| `<service/database/network>` | `<read/write/test | none>` | `<explicit authorization | absent>` | `not-run` |
