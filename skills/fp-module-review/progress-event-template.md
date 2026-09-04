# Module Review Progress

This ledger is append-only recovery evidence and never owns Finding state. Append events in chronological order; never rewrite prior evidence to match a later result.

## Event <timestamp>

- State: `<lifecycle state>`
- HEAD: `<SHA>`
- Worktree fingerprint: `<status plus content identity>`
- Scope/config fingerprints: `<scope, commands, test/config, environment identities>`
- Wave/finding: `<WNN / MR-FNNN / N/A>`
- Command/result: `<exact command, safety, exit code, counts, or not-run>`
- Changed/protected paths: `<before/after disposition>`
- Evidence freshness: `<fresh | stale | CANNOT_VERIFY and reason>`
- Next: `<earliest necessary state, exact recovery command, decision, or target>`
