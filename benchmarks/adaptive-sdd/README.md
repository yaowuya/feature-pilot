# Adaptive SDD benchmark fixture

This directory contains fixed inputs for comparing baseline and candidate SDD decomposition/search behavior. The three corpus cases deliberately increase in scope while targeting the same project revision.

## Layout

- `schema.md` defines the required corpus fields.
- `corpus/` contains the small, medium, and large requirement inputs.
- `fixture/project/` is the resettable target project used by every case.
- `fixture-manifest.sha256` pins the exact fixture revision.

## Reproducibility

Manifest entries are ordered by ordinal repository-relative path. Each digest is SHA-256 over UTF-8 text after normalizing CRLF and CR line endings to LF. This makes the revision stable across Git line-ending settings.

Run the deterministic checks from the repository root:

```powershell
powershell -NoProfile -File .\scripts\test-sdd-benchmark-fixture.ps1
powershell -NoProfile -File .\benchmarks\adaptive-sdd\fixture\project\tests\catalog.Tests.ps1
```

Reset the target by replacing `fixture/project/` with the tracked files whose hashes match `fixture-manifest.sha256`. Baseline and candidate runs must start from that same revision and must not modify the corpus files.
