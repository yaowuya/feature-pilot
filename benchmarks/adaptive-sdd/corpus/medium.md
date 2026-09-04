# Medium case: multi-field catalog search

## Metadata

Case ID: `adaptive-sdd-medium`

Size: `medium`

Fixture manifest: `benchmarks/adaptive-sdd/fixture-manifest.sha256`

Fixture revision SHA-256: `b1e927835ee456a6da65b8adca0dfbc1c1af7f2c8176f929a1c207800598255d`

## Requirement

Extend catalog items with a short description and make search match names, descriptions, and tags. Keep category filtering composable with the expanded query behavior, document the supported fields, and add deterministic checks.

## Expected coverage

- Add a description to every item in `src/catalog.ps1`.
- Update `src/search.ps1` without duplicating catalog construction.
- Verify name, description, tag, and combined category filtering in `tests/catalog.Tests.ps1`.
- Update `README.md` with the public search behavior.

## Allowed paths

- `fixture/project/src/catalog.ps1`
- `fixture/project/src/search.ps1`
- `fixture/project/tests/catalog.Tests.ps1`
- `fixture/project/README.md`

## Excluded paths

- `fixture/project/AGENTS.md`
- `corpus/`
- `fixture-manifest.sha256`

## Quality checks

- `powershell -NoProfile -File .\fixture\project\tests\catalog.Tests.ps1`
- Every catalog item has a non-empty description.
- Search results remain ordered by item ID.
