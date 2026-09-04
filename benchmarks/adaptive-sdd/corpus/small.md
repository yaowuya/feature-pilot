# Small case: literal name search

## Metadata

Case ID: `adaptive-sdd-small`

Size: `small`

Fixture manifest: `benchmarks/adaptive-sdd/fixture-manifest.sha256`

Fixture revision SHA-256: `b1e927835ee456a6da65b8adca0dfbc1c1af7f2c8176f929a1c207800598255d`

## Requirement

Change catalog search so wildcard characters in a query are treated as literal text. Add a focused regression check without changing catalog data or documentation.

## Expected coverage

- Locate the query-matching implementation in `src/search.ps1`.
- Preserve case-insensitive matching and stable item ordering.
- Cover a literal wildcard query in the adjacent behavior test.

## Allowed paths

- `fixture/project/src/search.ps1`
- `fixture/project/tests/catalog.Tests.ps1`

## Excluded paths

- `fixture/project/src/catalog.ps1`
- `fixture/project/README.md`
- `fixture/project/AGENTS.md`
- `corpus/`
- `fixture-manifest.sha256`

## Quality checks

- `powershell -NoProfile -File .\fixture\project\tests\catalog.Tests.ps1`
- Existing catalog count and category-filter behavior remain green.
