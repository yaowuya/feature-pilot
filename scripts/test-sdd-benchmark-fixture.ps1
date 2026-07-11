$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$expectedPaths = @(
    'benchmarks/adaptive-sdd/README.md'
    'benchmarks/adaptive-sdd/schema.md'
    'benchmarks/adaptive-sdd/corpus/small.md'
    'benchmarks/adaptive-sdd/corpus/medium.md'
    'benchmarks/adaptive-sdd/corpus/large.md'
    'benchmarks/adaptive-sdd/fixture/project/AGENTS.md'
    'benchmarks/adaptive-sdd/fixture/project/README.md'
    'benchmarks/adaptive-sdd/fixture/project/src/catalog.ps1'
    'benchmarks/adaptive-sdd/fixture/project/src/search.ps1'
    'benchmarks/adaptive-sdd/fixture/project/tests/catalog.Tests.ps1'
    'benchmarks/adaptive-sdd/fixture-manifest.sha256'
)
$fixtureInputPaths = @(
    'benchmarks/adaptive-sdd/fixture/project/AGENTS.md'
    'benchmarks/adaptive-sdd/fixture/project/README.md'
    'benchmarks/adaptive-sdd/fixture/project/src/catalog.ps1'
    'benchmarks/adaptive-sdd/fixture/project/src/search.ps1'
    'benchmarks/adaptive-sdd/fixture/project/tests/catalog.Tests.ps1'
)
$corpusPaths = @(
    'benchmarks/adaptive-sdd/corpus/small.md'
    'benchmarks/adaptive-sdd/corpus/medium.md'
    'benchmarks/adaptive-sdd/corpus/large.md'
)

function Get-NormalizedTextSha256 {
    param([Parameter(Mandatory = $true)][string]$LiteralPath)

    $content = (Get-Content -LiteralPath $LiteralPath -Raw) -replace "`r`n?", "`n"
    $bytes = [Text.Encoding]::UTF8.GetBytes($content)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha256.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

foreach ($relativePath in $expectedPaths) {
    $fullPath = Join-Path $root ($relativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Missing expected benchmark path: $relativePath"
    }
}

$manifestRelativePath = 'benchmarks/adaptive-sdd/fixture-manifest.sha256'
$manifestPath = Join-Path $root ($manifestRelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
$manifestEntries = @(Get-Content -LiteralPath $manifestPath | Where-Object { $_.Trim() })

if ($manifestEntries.Count -ne $fixtureInputPaths.Count) {
    throw "Manifest entry count mismatch: expected $($fixtureInputPaths.Count), found $($manifestEntries.Count)"
}

for ($index = 0; $index -lt $fixtureInputPaths.Count; $index++) {
    $entry = $manifestEntries[$index]
    if ($entry -notmatch '^([0-9a-f]{64})  (.+)$') {
        throw "Invalid manifest entry: $entry"
    }

    $expectedRelativePath = $fixtureInputPaths[$index]
    $manifestRelativeInputPath = $Matches[2]
    if ($manifestRelativeInputPath -cne $expectedRelativePath) {
        throw "Manifest path ordering mismatch: expected $expectedRelativePath, found $manifestRelativeInputPath"
    }

    $inputPath = Join-Path $root ($expectedRelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    $actualHash = Get-NormalizedTextSha256 -LiteralPath $inputPath
    if ($Matches[1] -cne $actualHash) {
        throw "Manifest hash mismatch: $expectedRelativePath"
    }
}

$manifestHash = Get-NormalizedTextSha256 -LiteralPath $manifestPath
foreach ($corpusRelativePath in $corpusPaths) {
    $corpusPath = Join-Path $root ($corpusRelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    $corpusContent = Get-Content -LiteralPath $corpusPath -Raw
    if ($corpusContent -notmatch '(?m)^Fixture revision SHA-256: `([0-9a-f]{64})`$') {
        throw "Missing fixture revision SHA-256: $corpusRelativePath"
    }
    if ($Matches[1] -cne $manifestHash) {
        throw "Corpus fixture revision mismatch: $corpusRelativePath"
    }
}

Write-Output 'PASS: fixed SDD benchmark paths and manifest are valid.'
