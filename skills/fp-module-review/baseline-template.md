# Baseline

## Snapshot

- HEAD: `<SHA>`
- Branch: `<name>`
- Working-tree fingerprint: `<status plus content identity>`
- Scope/config fingerprints: `<identities>`
- Environment: `<runtime/tool versions and relevant variables>`
- Captured at: `<timestamp>`

## Observable Compatibility Contracts

| Contract | Current behavior | Source/test evidence | Consumers/impact |
| --- | --- | --- | --- |
| `<API/schema/status/error/timing/log/callback/storage/security/config/UI>` | `<exact current behavior>` | `<path:line, symbol, or command>` | `<affected consumers>` |

## Existing Test Baseline

- Command: `<exact command | not-run>`
- Environment: `<interpreter/runtime>`
- Exit code: `<integer | N/A>`
- Results: `passed=<n>, failed=<n>, skipped=<n>, xfailed=<n>, xpassed=<n>, errors=<n>`
- Warnings/background errors: `<exact summary | none>`
- Freshness: `<fresh | stale | CANNOT_VERIFY>`

## Command Safety Ledger

| Command | Definition inspected | Class | Declared outputs | Result |
| --- | --- | --- | --- | --- |
| `<exact command>` | `<script/alias/wrapper/config/flags>` | `<SAFE | UNSAFE | UNKNOWN>` | `<paths | none>` | `<PASS | FAIL | SKIPPED and reason>` |

## Evidence Gaps

- `<claim>`: `<CANNOT_VERIFY reason, risk, and recovery command/decision>`
