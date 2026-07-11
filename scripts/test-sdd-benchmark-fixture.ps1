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
$corpusCases = @(
    @{ Path = 'benchmarks/adaptive-sdd/corpus/small.md'; Size = 'small'; CaseId = 'adaptive-sdd-small' }
    @{ Path = 'benchmarks/adaptive-sdd/corpus/medium.md'; Size = 'medium'; CaseId = 'adaptive-sdd-medium' }
    @{ Path = 'benchmarks/adaptive-sdd/corpus/large.md'; Size = 'large'; CaseId = 'adaptive-sdd-large' }
)

function Read-StrictUtf8Text {
    param([Parameter(Mandatory = $true)][string]$LiteralPath)

    $rawBytes = [IO.File]::ReadAllBytes($LiteralPath)
    $strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
    try {
        $text = $strictUtf8.GetString($rawBytes)
    }
    catch [Text.DecoderFallbackException] {
        throw "Invalid UTF-8 text: $LiteralPath"
    }

    if ($text.Length -gt 0 -and $text[0] -eq [char]0xfeff) {
        return $text.Substring(1)
    }
    return $text
}

function Get-NormalizedTextSha256 {
    param([Parameter(Mandatory = $true)][string]$LiteralPath)

    $content = (Read-StrictUtf8Text -LiteralPath $LiteralPath) -replace "`r`n?", "`n"
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false, $true)
    $bytes = $utf8WithoutBom.GetBytes($content)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha256.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function Get-RepositoryRelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryRoot,
        [Parameter(Mandatory = $true)][string]$LiteralPath
    )

    $rootPath = [IO.Path]::GetFullPath($RepositoryRoot).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
    $rootPrefix = $rootPath + [IO.Path]::DirectorySeparatorChar
    $fullPath = [IO.Path]::GetFullPath($LiteralPath)
    if (-not $fullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Fixture path is outside repository root: $LiteralPath"
    }

    return $fullPath.Substring($rootPrefix.Length).Replace('\', '/')
}

function Get-OrdinalFixtureInputPaths {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryRoot,
        [Parameter(Mandatory = $true)][string]$FixtureProjectPath
    )

    $relativePaths = [string[]]@(
        Get-ChildItem -LiteralPath $FixtureProjectPath -File -Recurse | ForEach-Object {
            Get-RepositoryRelativePath -RepositoryRoot $RepositoryRoot -LiteralPath $_.FullName
        }
    )
    [Array]::Sort($relativePaths, [StringComparer]::Ordinal)
    return $relativePaths
}

function Test-FixtureManifest {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryRoot,
        [Parameter(Mandatory = $true)][string]$FixtureProjectPath,
        [Parameter(Mandatory = $true)][string]$ManifestPath
    )

    $fixtureInputPaths = @(Get-OrdinalFixtureInputPaths -RepositoryRoot $RepositoryRoot -FixtureProjectPath $FixtureProjectPath)
    $manifestContent = Read-StrictUtf8Text -LiteralPath $ManifestPath
    $manifestEntries = @($manifestContent -split "`n" | Where-Object { $_.Trim() })

    if ($manifestEntries.Count -ne $fixtureInputPaths.Count) {
        throw "Manifest entry count mismatch: expected $($fixtureInputPaths.Count) fixture files, found $($manifestEntries.Count) manifest entries"
    }

    for ($index = 0; $index -lt $fixtureInputPaths.Count; $index++) {
        $entry = $manifestEntries[$index]
        if ($entry -notmatch '^([0-9a-f]{64})  (.+)$') {
            throw "Invalid manifest entry: $entry"
        }

        $manifestHash = $Matches[1]
        $manifestRelativeInputPath = $Matches[2]
        $expectedRelativePath = $fixtureInputPaths[$index]
        if ($manifestRelativeInputPath -cne $expectedRelativePath) {
            throw "Manifest path ordering mismatch: expected $expectedRelativePath, found $manifestRelativeInputPath"
        }

        $inputPath = Join-Path $RepositoryRoot ($expectedRelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
        $actualHash = Get-NormalizedTextSha256 -LiteralPath $inputPath
        if ($manifestHash -cne $actualHash) {
            throw "Manifest hash mismatch: $expectedRelativePath"
        }
    }

    return Get-NormalizedTextSha256 -LiteralPath $ManifestPath
}

function Assert-NormalizedHashKnownVector {
    $tempDirectory = Join-Path ([IO.Path]::GetTempPath()) ('feature-pilot-sdd-utf8-' + [Guid]::NewGuid().ToString('N'))
    try {
        [void](New-Item -ItemType Directory -Path $tempDirectory)
        $vectorPath = Join-Path $tempDirectory 'non-ascii.txt'
        [IO.File]::WriteAllBytes(
            $vectorPath,
            [byte[]](0xc3, 0xa9, 0x0d, 0x0a, 0xe4, 0xb8, 0xad, 0x0d, 0x66, 0x69, 0x6e)
        )
        $expectedHash = '6e6962c9f976bd19d54a715486f7e88a20d23bfc1d7eb9180699b8eca6137485'
        $actualHash = Get-NormalizedTextSha256 -LiteralPath $vectorPath
        if ($actualHash -cne $expectedHash) {
            throw "Non-ASCII normalized-text hash mismatch: expected $expectedHash, found $actualHash"
        }

        $invalidPath = Join-Path $tempDirectory 'invalid-utf8.txt'
        [IO.File]::WriteAllBytes($invalidPath, [byte[]](0xc3, 0x28))
        $invalidUtf8Rejected = $false
        try {
            [void](Get-NormalizedTextSha256 -LiteralPath $invalidPath)
        }
        catch {
            if ($_.Exception.Message -notlike 'Invalid UTF-8 text:*') {
                throw
            }
            $invalidUtf8Rejected = $true
        }
        if (-not $invalidUtf8Rejected) {
            throw 'Invalid UTF-8 test vector was accepted.'
        }
    }
    finally {
        if (Test-Path -LiteralPath $tempDirectory) {
            Remove-Item -LiteralPath $tempDirectory -Recurse -Force
        }
    }
}

function Assert-UnmanifestedFixtureRejected {
    param(
        [Parameter(Mandatory = $true)][string]$SourceFixtureProjectPath,
        [Parameter(Mandatory = $true)][string]$SourceManifestPath
    )

    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('feature-pilot-sdd-fixture-' + [Guid]::NewGuid().ToString('N'))
    try {
        $tempBenchmarkPath = Join-Path $tempRoot 'benchmarks\adaptive-sdd'
        $tempFixtureProjectPath = Join-Path $tempBenchmarkPath 'fixture\project'
        $tempManifestPath = Join-Path $tempBenchmarkPath 'fixture-manifest.sha256'
        [void](New-Item -ItemType Directory -Path (Split-Path -Parent $tempFixtureProjectPath) -Force)
        Copy-Item -LiteralPath $SourceFixtureProjectPath -Destination $tempFixtureProjectPath -Recurse
        Copy-Item -LiteralPath $SourceManifestPath -Destination $tempManifestPath
        [IO.File]::WriteAllBytes(
            (Join-Path $tempFixtureProjectPath 'unmanifested.tmp'),
            [Text.Encoding]::ASCII.GetBytes('unmanifested fixture input')
        )

        $unmanifestedFileRejected = $false
        try {
            [void](Test-FixtureManifest -RepositoryRoot $tempRoot -FixtureProjectPath $tempFixtureProjectPath -ManifestPath $tempManifestPath)
        }
        catch {
            if ($_.Exception.Message -notlike 'Manifest entry count mismatch:*') {
                throw
            }
            $unmanifestedFileRejected = $true
        }
        if (-not $unmanifestedFileRejected) {
            throw 'Unmanifested fixture input was accepted.'
        }
    }
    finally {
        if (Test-Path -LiteralPath $tempRoot) {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force
        }
    }
}

function Assert-CorpusSchema {
    param(
        [Parameter(Mandatory = $true)][string]$LiteralPath,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$ExpectedCaseId,
        [Parameter(Mandatory = $true)][string]$ExpectedSize,
        [Parameter(Mandatory = $true)][string]$ExpectedManifestHash,
        [Parameter(Mandatory = $true)]$CaseIds
    )

    $content = (Read-StrictUtf8Text -LiteralPath $LiteralPath) -replace "`r`n?", "`n"
    foreach ($heading in @('Metadata', 'Requirement', 'Expected coverage', 'Allowed paths', 'Excluded paths', 'Quality checks')) {
        $sectionPattern = '(?ms)^## ' + [Regex]::Escape($heading) + "`n(?<Body>.*?)(?=^## |\z)"
        $section = [Regex]::Match($content, $sectionPattern)
        if (-not $section.Success -or -not $section.Groups['Body'].Value.Trim()) {
            throw "Missing or empty corpus section '$heading': $RelativePath"
        }
    }

    if ($content -notmatch '(?m)^Case ID: `([^`]+)`$') {
        throw "Missing Case ID: $RelativePath"
    }
    $caseId = $Matches[1]
    if ($caseId -cne $ExpectedCaseId) {
        throw "Corpus Case ID mismatch: expected $ExpectedCaseId, found $caseId"
    }
    if (-not $CaseIds.Add($caseId)) {
        throw "Duplicate corpus Case ID: $caseId"
    }

    if ($content -notmatch '(?m)^Size: `([^`]+)`$') {
        throw "Missing Size: $RelativePath"
    }
    $size = $Matches[1]
    if ($size -cne $ExpectedSize) {
        throw "Corpus Size mismatch: expected $ExpectedSize, found $size"
    }

    if ($content -notmatch '(?m)^Fixture manifest: `([^`]+)`$') {
        throw "Missing Fixture manifest: $RelativePath"
    }
    $fixtureManifest = $Matches[1]
    if ($fixtureManifest -cne 'benchmarks/adaptive-sdd/fixture-manifest.sha256') {
        throw "Corpus fixture manifest mismatch: $RelativePath"
    }

    if ($content -notmatch '(?m)^Fixture revision SHA-256: `([0-9a-f]{64})`$') {
        throw "Missing fixture revision SHA-256: $RelativePath"
    }
    $fixtureRevision = $Matches[1]
    if ($fixtureRevision -cne $ExpectedManifestHash) {
        throw "Corpus fixture revision mismatch: $RelativePath"
    }
}

foreach ($relativePath in $expectedPaths) {
    $fullPath = Join-Path $root ($relativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Missing expected benchmark path: $relativePath"
    }
}

$manifestRelativePath = 'benchmarks/adaptive-sdd/fixture-manifest.sha256'
$fixtureProjectRelativePath = 'benchmarks/adaptive-sdd/fixture/project'
$manifestPath = Join-Path $root ($manifestRelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
$fixtureProjectPath = Join-Path $root ($fixtureProjectRelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)

Assert-NormalizedHashKnownVector
$manifestHash = Test-FixtureManifest -RepositoryRoot $root -FixtureProjectPath $fixtureProjectPath -ManifestPath $manifestPath
Assert-UnmanifestedFixtureRejected -SourceFixtureProjectPath $fixtureProjectPath -SourceManifestPath $manifestPath

$caseIds = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach ($corpusCase in $corpusCases) {
    $corpusPath = Join-Path $root ($corpusCase.Path -replace '/', [IO.Path]::DirectorySeparatorChar)
    Assert-CorpusSchema -LiteralPath $corpusPath -RelativePath $corpusCase.Path -ExpectedCaseId $corpusCase.CaseId -ExpectedSize $corpusCase.Size -ExpectedManifestHash $manifestHash -CaseIds $caseIds
}

Write-Output 'PASS: fixed SDD benchmark paths and manifest are valid.'
