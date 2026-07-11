# Large case: saved catalog queries

## Metadata

Case ID: `adaptive-sdd-large`

Size: `large`

Fixture manifest: `benchmarks/adaptive-sdd/fixture-manifest.sha256`

Fixture revision SHA-256: `b1e927835ee456a6da65b8adca0dfbc1c1af7f2c8176f929a1c207800598255d`

## Requirement

Add saved queries to the fixture project. A saved query has a unique name, query text, and optional category; it can be created, listed in name order, and executed through the existing catalog search. Persist saved queries as JSON beneath a caller-supplied data directory, reject duplicate names case-insensitively, document usage and storage, and add deterministic tests that clean up their temporary data.

## Expected coverage

- Keep catalog data and search behavior backward compatible.
- Introduce one focused source file for saved-query persistence and orchestration.
- Validate names and categories before writing data.
- Use atomic replacement so a failed write does not corrupt existing saved queries.
- Test create, duplicate rejection, stable listing, execution, persistence reload, and cleanup.
- Document the API, JSON location, and failure behavior.

## Allowed paths

- `fixture/project/src/catalog.ps1`
- `fixture/project/src/search.ps1`
- `fixture/project/src/saved-queries.ps1`
- `fixture/project/tests/catalog.Tests.ps1`
- `fixture/project/tests/saved-queries.Tests.ps1`
- `fixture/project/README.md`

## Excluded paths

- `fixture/project/AGENTS.md`
- Any path outside `fixture/project/`
- `corpus/`
- `fixture-manifest.sha256`

## Quality checks

- `powershell -NoProfile -File .\fixture\project\tests\catalog.Tests.ps1`
- `powershell -NoProfile -File .\fixture\project\tests\saved-queries.Tests.ps1`
- Tests use a unique temporary directory and remove it in a `finally` block.
- No persisted test data remains beneath `fixture/project/`.
