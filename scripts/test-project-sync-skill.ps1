$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
$canonicalSkillPath = Join-Path $root '.agents\skills\sync-plugin-runtimes\SKILL.md'
$claudeAdapterPath = Join-Path $root '.claude\skills\sync-plugin-runtimes\SKILL.md'
$syncScriptPath = Join-Path $root '.agents\skills\sync-plugin-runtimes\scripts\sync-plugin-runtimes.ps1'

function Assert-Condition {
    param(
        [Parameter(Mandatory)]
        [bool]$Condition,

        [Parameter(Mandatory)]
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Read-Utf8 {
    param([Parameter(Mandatory)][string]$Path)
    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}

Assert-Condition (Test-Path -LiteralPath $canonicalSkillPath -PathType Leaf) 'Codex project skill is missing'
Assert-Condition (Test-Path -LiteralPath $claudeAdapterPath -PathType Leaf) 'Claude Code project skill adapter is missing'
Assert-Condition (Test-Path -LiteralPath $syncScriptPath -PathType Leaf) 'Shared PowerShell sync script is missing'

foreach ($forbiddenPath in @(
    'skills\sync-plugin-runtimes\SKILL.md'
    'skills\fp-sync-plugin\SKILL.md'
    'commands\sync-plugin-runtimes.md'
    'commands\fp-sync-plugin.md'
)) {
    Assert-Condition (-not (Test-Path -LiteralPath (Join-Path $root $forbiddenPath))) "Project-only skill leaked into plugin surface: $forbiddenPath"
}

$canonical = Read-Utf8 $canonicalSkillPath
$adapter = Read-Utf8 $claudeAdapterPath
$script = Read-Utf8 $syncScriptPath

$frontmatter = [regex]::Match($canonical, '(?s)\A---\r?\n(?<body>.*?)\r?\n---')
Assert-Condition $frontmatter.Success 'Canonical skill has invalid frontmatter'
$frontmatterKeys = @([regex]::Matches($frontmatter.Groups['body'].Value, '(?m)^([a-zA-Z0-9_-]+):') | ForEach-Object { $_.Groups[1].Value })
Assert-Condition ($frontmatterKeys.Count -eq 2 -and $frontmatterKeys -contains 'name' -and $frontmatterKeys -contains 'description') 'Canonical skill frontmatter must contain only name and description'
Assert-Condition ($canonical -match '(?m)^name:\s*sync-plugin-runtimes\s*$') 'Canonical skill name does not match its directory'
Assert-Condition ($canonical -match '(?m)^description:\s*Use when .+') 'Canonical skill description must be trigger-only and start with Use when'

foreach ($anchor in @(
    'scripts/sync-plugin-runtimes.ps1'
    '-VerifyOnly'
    'same-version'
    'SHA-256'
    'marketplace'
    'cache'
    'target identity'
    'new task'
)) {
    Assert-Condition ($canonical.Contains($anchor)) "Canonical skill is missing required behavior: $anchor"
}

Assert-Condition ($adapter.Contains('../../../.agents/skills/sync-plugin-runtimes/SKILL.md')) 'Claude adapter does not delegate to the canonical project skill'
Assert-Condition ($adapter.Contains('single source of truth')) 'Claude adapter does not declare the canonical skill as the single source of truth'
Assert-Condition ((@($adapter -split "`r?`n").Count) -le 20) 'Claude adapter is not thin enough'
Assert-Condition (-not ((Get-Item -LiteralPath (Split-Path -Parent $claudeAdapterPath)).Attributes -band [System.IO.FileAttributes]::ReparsePoint)) 'Claude adapter must not be a symlink or junction'

foreach ($anchor in @(
    '[switch]$VerifyOnly'
    '$ErrorActionPreference = ''Continue'''
    'function Get-ClaudeStatus'
    'Get-FileHash'
    'SHA256'
    '.agents'
    '.claude'
    '.git'
    'plugin marketplace update'
    'plugin update'
    'plugin uninstall'
    'plugin install'
    'plugin remove'
    'plugin add'
)) {
    Assert-Condition ($script.Contains($anchor)) "Sync script is missing required contract: $anchor"
}

$blockPatternSource = [regex]::Match($script, '(?m)^\s*\$blockPattern\s*=\s*''(?<pattern>[^'']+)''\s*$')
Assert-Condition $blockPatternSource.Success 'Sync script Claude plugin block pattern could not be extracted'
$currentListMarker = [char]0x276F
$mojibakeListMarker = ([char]37442).ToString() + '?'
foreach ($listMarker in @($currentListMarker, $mojibakeListMarker)) {
    $claudeListFixture = @"
Installed plugins:

  $listMarker fp@fp-dev
    Version: 0.3.0
    Scope: user
    Status: ✔ enabled
"@
    $claudeBlocks = @([regex]::Matches($claudeListFixture, $blockPatternSource.Groups['pattern'].Value))
    Assert-Condition ($claudeBlocks.Count -eq 1) 'Claude plugin parser does not accept a current or PowerShell-mojibake list marker'
    Assert-Condition ($claudeBlocks[0].Groups['selector'].Value.Trim() -eq 'fp@fp-dev') 'Claude plugin parser did not preserve the selector'
}

Assert-Condition (-not ($script -match '(?i)C:\\Users\\Lenovo|D:\\01-code\\feature-pilot')) 'Sync script contains a machine-specific absolute path'

$tokens = $null
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile($syncScriptPath, [ref]$tokens, [ref]$parseErrors) | Out-Null
$parseErrorMessage = if ($parseErrors.Count -gt 0) {
    ($parseErrors | ForEach-Object { $_.Message }) -join '; '
}
else {
    'none'
}
Assert-Condition ($parseErrors.Count -eq 0) ("Sync script has PowerShell parse errors: $parseErrorMessage")

Write-Output 'Project sync skill contract passed.'
