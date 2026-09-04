# Catalog fixture

This small PowerShell project supplies deterministic source and tests for the adaptive SDD benchmark.

`Get-CatalogItems` returns the fixed catalog. `Search-Catalog` performs a case-insensitive literal query across item names and tags, optionally constrained to an exact category. Results are ordered by item ID.

Run its adjacent test from the repository root:

```powershell
powershell -NoProfile -File .\benchmarks\adaptive-sdd\fixture\project\tests\catalog.Tests.ps1
```
