$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "README/docs contract validation failed: $message"
    }
}

function Read-Utf8([string]$relativePath) {
    $path = Join-Path $root $relativePath
    Assert-Condition (Test-Path -LiteralPath $path -PathType Leaf) "missing document: $relativePath"
    return [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
}

function Test-LocalMarkdownLinks([string]$relativePath, [string]$text) {
    $sourceDirectory = Split-Path -Parent (Join-Path $root $relativePath)
    foreach ($match in [regex]::Matches($text, '\[[^\]]+\]\((?<target>[^)]+)\)')) {
        $target = $match.Groups['target'].Value.Split('#')[0]
        if (-not $target -or $target -match '^(?:https?://|mailto:|#)') { continue }
        $decodedTarget = [Uri]::UnescapeDataString($target)
        $resolved = [IO.Path]::GetFullPath((Join-Path $sourceDirectory $decodedTarget))
        if (-not (Test-Path -LiteralPath $resolved)) { return $false }
    }
    return $true
}

$gettingStarted = Read-Utf8 'docs\getting-started.md'
foreach ($anchor in @(
    'FeaturePilot'
    '## Claude Code'
    '## Codex'
    '## DeepSeek Harness'
    'sync-plugin-runtimes.ps1'
    '-VerifyOnly'
    'validate-plugin.ps1'
    'new task'
    'Chokidar'
)) {
    Assert-Condition ($gettingStarted.Contains($anchor)) "getting-started lost anchor: $anchor"
}
Assert-Condition (Test-LocalMarkdownLinks 'docs\getting-started.md' $gettingStarted) 'getting-started contains a broken local link'

$commandsReference = Read-Utf8 'docs\reference\commands-and-skills.md'
foreach ($command in @(Get-ChildItem (Join-Path $root 'commands') -Filter 'fp-*.md' -File)) {
    Assert-Condition (
        [regex]::Matches($commandsReference, '(?<![A-Za-z0-9-])' + [regex]::Escape($command.BaseName) + '(?![A-Za-z0-9-])').Count -ge 1
    ) "commands reference omits $($command.BaseName)"
}
foreach ($anchor in @(
    '# FeaturePilot'
    'fp-execute'
    'fp-execute-sdd'
    '../user_guide/fp-coverage.md'
    '../user_guide/fp-module-review.md'
    '../getting-started.md'
)) {
    Assert-Condition ($commandsReference.Contains($anchor)) "commands reference lost anchor: $anchor"
}
Assert-Condition (Test-LocalMarkdownLinks 'docs\reference\commands-and-skills.md' $commandsReference) 'commands reference contains a broken local link'

$architectureReference = Read-Utf8 'docs\reference\architecture-and-artifacts.md'
foreach ($anchor in @(
    '# FeaturePilot'
    'skills/_shared/workspace-rules.md'
    'skills/_shared/artifact-layout.md'
    'skills/_shared/decision-ledger.md'
    'skills/_shared/codegraph.md'
    'skills/_shared/ui-e2e-contract.md'
    'manifest-only default'
    'compact-first'
    '500 lines'
    '30,000 characters'
    'BROWSER_CAPABILITY_GATE'
    'dirty-after-write'
    'post-write-sync'
    'fp-docs/archive/'
)) {
    Assert-Condition ($architectureReference.Contains($anchor)) "architecture reference lost anchor: $anchor"
}
Assert-Condition ($commandsReference.Contains('architecture-and-artifacts.md')) 'commands reference does not link the architecture reference'
Assert-Condition (Test-LocalMarkdownLinks 'docs\reference\architecture-and-artifacts.md' $architectureReference) 'architecture reference contains a broken local link'

Write-Output 'README/docs contract validation passed.'
