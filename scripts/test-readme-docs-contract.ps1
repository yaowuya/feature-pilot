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

function ConvertFrom-Utf8Base64([string]$value) {
    return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($value))
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
    'fp-db-adapter'
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

$readme = Read-Utf8 'README.md'
$readmeLineCount = @($readme -split "`r?`n").Count
Assert-Condition ($readmeLineCount -ge 100 -and $readmeLineCount -le 170) "README line count is $readmeLineCount; expected 100..170"
$heroLine = ConvertFrom-Utf8Base64 'PiAqKuaKiuS4gOWPpemcgOaxgu+8jOeos+eos+W4puWIsOWPr+S6pOS7mOS7o+eggeOAgioq'
Assert-Condition ([regex]::Matches($readme, '(?m)^' + [regex]::Escape($heroLine) + '\r?$').Count -eq 1) 'README lost or duplicated the exact approved hero line'
foreach ($anchor in @(
    '# FeaturePilot'
    '1.0.0'
    'Claude Code'
    'Codex'
    'DeepSeek Harness'
    'fp-init'
    'fp-explore'
    'fp-eli5'
    'fp-prd'
    'fp-start'
    'fp-quick'
    'fp-figma'
    'fp-design-review'
    'fp-db-adapter'
    'fp-coverage'
    'fp-module-review'
    'fp-final-review'
    'fp-archive'
    'docs/getting-started.md'
    'docs/reference/commands-and-skills.md'
    'docs/reference/architecture-and-artifacts.md'
    'docs/user_guide/fp-coverage.md'
    'docs/user_guide/fp-module-review.md'
    'docs/release_notes/1.0.0.md'
)) {
    Assert-Condition ($readme.Contains($anchor)) "README lost landing-page anchor: $anchor"
}
foreach ($forbidden in @(
    '## Staged UI/E2E delivery'
    '## Claude Code'
    '## Codex'
    '## DeepSeek Harness'
    '.fp-coverage/contract.md'
    'coverage-tooling-bootstrap'
    'npm install -g @colbymchenry/codegraph@latest'
    'SOURCE_READY -> STATIC_UI_READY'
    '| Logical artifact | Small form | Split form |'
)) {
    Assert-Condition (-not $readme.Contains($forbidden)) "README still embeds technical-reference content: $forbidden"
}
$canonicalArtifactTableHeader = ConvertFrom-Utf8Base64 'fCDpgLvovpHkuqfniakgfCDlsI/lnovlvaLlvI8gfCDmi4bliIblvaLlvI8gfA=='
Assert-Condition (-not $readme.Contains($canonicalArtifactTableHeader)) 'README still embeds the Chinese canonical artifact table'

$orderedHeadings = @(
    (ConvertFrom-Utf8Base64 'IyMgQUkg5YaZ5b6X5b6I5b+r77yM5Li65LuA5LmI5byA5Y+R6L+Y5piv5Lya5aSx5o6n77yf')
    (ConvertFrom-Utf8Base64 'IyMgRmVhdHVyZVBpbG90IOaAjuS5iOaOpeS9j+W8gOWPkei/h+eoi++8nw==')
    (ConvertFrom-Utf8Base64 'IyMgMyDliIbpkp/lvIDlp4s=')
    (ConvertFrom-Utf8Base64 'IyMg5oyJ5Zy65pmv6YCJ5oup5YWl5Y+j')
    (ConvertFrom-Utf8Base64 'IyMg5a6D5Lya55WZ5LiL5LuA5LmI77yf')
    (ConvertFrom-Utf8Base64 'IyMg5Li65LuA5LmI5a6D6YCC5ZCI6ZW/5pyf5Y2P5L2c77yf')
    (ConvertFrom-Utf8Base64 'IyMg57un57ut5rex5YWl')
    (ConvertFrom-Utf8Base64 'IyMg57u05oqk5LiO6aqM6K+B')
)
$previousHeadingIndex = -1
foreach ($heading in $orderedHeadings) {
    $matches = [regex]::Matches($readme, '(?m)^' + [regex]::Escape($heading) + '\r?$')
    Assert-Condition ($matches.Count -eq 1) "README heading is missing or duplicated: $heading"
    Assert-Condition ($matches[0].Index -gt $previousHeadingIndex) "README heading is out of order: $heading"
    $previousHeadingIndex = $matches[0].Index
}
Assert-Condition ([regex]::Matches($readme, '(?m)^## ').Count -eq $orderedHeadings.Count) 'README contains an unapproved or duplicated H2 section'
Assert-Condition (Test-LocalMarkdownLinks 'README.md' $readme) 'README contains a broken local link'

Write-Output 'README/docs contract validation passed.'
