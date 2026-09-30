<#
.SYNOPSIS
Checks Cursor package discovery and isolated sync-wrapper delegation.
.DESCRIPTION
Uses a recording installer stub and a failing validator in a temporary plugin
root. No real installer or user runtime configuration is accessed.
#>
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object Text.UTF8Encoding($false)

function Assert-Condition([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "Cursor plugin validation failed: $Message" }
}

function Expect-Failure([scriptblock]$Action, [string]$Message) {
    # Match the intended precondition failure, not an unrelated fixture error.
    $failure = $null
    try { & $Action | Out-Null } catch { $failure = $_ }
    Assert-Condition ($null -ne $failure) "expected rejection: $Message"
    Assert-Condition ($failure.Exception.Message.Contains($Message)) "unexpected rejection: $($failure.Exception.Message)"
}

$manifest = [IO.File]::ReadAllText((Join-Path $root '.cursor-plugin/plugin.json'), $utf8) | ConvertFrom-Json
$claude = [IO.File]::ReadAllText((Join-Path $root '.claude-plugin/plugin.json'), $utf8) | ConvertFrom-Json
$marketplace = [IO.File]::ReadAllText((Join-Path $root '.cursor-plugin/marketplace.json'), $utf8) | ConvertFrom-Json
Assert-Condition ($manifest.name -eq $claude.name -and $manifest.version -eq $claude.version) 'Cursor and Claude identities differ'
Assert-Condition ($manifest.skills -eq './skills/') 'Cursor must load the shared skills directory'
Assert-Condition ($manifest.rules -eq './adapters/cursor/rules/') 'Cursor must load its path adapter rules'
Assert-Condition ($manifest.commands -is [array] -and $manifest.commands.Count -eq 0) 'commands must be an explicit empty array'

$skillsRoot = Join-Path $root $manifest.skills
$rulesRoot = Join-Path $root $manifest.rules
Assert-Condition (Test-Path -LiteralPath $skillsRoot -PathType Container) 'skills directory is missing'
Assert-Condition (Test-Path -LiteralPath $rulesRoot -PathType Container) 'rules directory is missing'
$skills = @(Get-ChildItem -LiteralPath $skillsRoot -Directory | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf
})
$rules = @(Get-ChildItem -LiteralPath $rulesRoot -Filter '*.mdc' -File)
Assert-Condition ($skills.Count -gt 0 -and $rules.Count -gt 0) 'manifest paths do not contain skills and rules'
Assert-Condition (Test-Path -LiteralPath (Join-Path $skillsRoot '_shared/workspace-rules.md') -PathType Leaf) 'shared workspace contract is missing'
Assert-Condition (Test-Path -LiteralPath (Join-Path $skillsRoot '_shared/engineering-quality.md') -PathType Leaf) 'shared engineering contract is missing'
foreach ($rule in $rules) {
    $text = [IO.File]::ReadAllText($rule.FullName, $utf8)
    $frontmatter = [regex]::Match($text, '\A---\r?\n(?<body>.*?)\r?\n---', [Text.RegularExpressions.RegexOptions]::Singleline)
    Assert-Condition $frontmatter.Success "rule has no frontmatter: $($rule.Name)"
    Assert-Condition ($frontmatter.Groups['body'].Value -match '(?m)^description:\s*\S') "rule has no description: $($rule.Name)"
    Assert-Condition ($frontmatter.Groups['body'].Value -match '(?m)^alwaysApply:\s*true\s*$') "path rule is not always available: $($rule.Name)"
    Assert-Condition ($text.Contains('../_shared/workspace-rules.md') -and $text.Contains('${CLAUDE_PLUGIN_ROOT}')) "rule lacks shared-resource anchoring: $($rule.Name)"
}
Assert-Condition ($marketplace.plugins -is [array] -and $marketplace.plugins.Count -eq 1) 'marketplace must have one plugin'
$entry = $marketplace.plugins[0]
Assert-Condition ($entry.name -eq $manifest.name -and $entry.source -eq '.') 'marketplace must reference the root plugin'
$entryRoot = [IO.Path]::GetFullPath((Join-Path $root $entry.source))
Assert-Condition ($entryRoot -eq [IO.Path]::GetFullPath($root)) 'marketplace source does not resolve to the repository root'

$wrapper = Join-Path $root '.agents/skills/sync-plugin-runtimes/scripts/sync-plugin-runtimes.ps1'
$tempParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')
$fixtureName = 'fp-cursor-wrapper-' + [guid]::NewGuid().ToString('N')
$fixtureRoot = [IO.Path]::GetFullPath((Join-Path $tempParent $fixtureName))
Assert-Condition ((Split-Path -Parent $fixtureRoot) -eq $tempParent) 'unsafe temporary fixture root'
$fixtureScripts = [IO.Path]::GetFullPath((Join-Path $fixtureRoot 'scripts'))
$cursorFixture = [IO.Path]::GetFullPath((Join-Path $fixtureRoot 'cursor home'))
foreach ($path in @($fixtureScripts, $cursorFixture)) {
    Assert-Condition ($path.StartsWith($fixtureRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) 'fixture path escaped temporary root'
}

try {
    [IO.Directory]::CreateDirectory($fixtureScripts) | Out-Null
    # Any fall-through into legacy runtime validation fails before user discovery.
    [IO.File]::WriteAllText((Join-Path $fixtureScripts 'validate-plugin.ps1'), "throw 'Unexpected full-repository validation.'", $utf8)
    $stub = @'
param([string]$PluginRoot, [string]$CursorHome, [switch]$VerifyOnly)
$record = [ordered]@{
    PluginRoot = $PluginRoot
    CursorHome = $CursorHome
    CursorHomeBound = $PSBoundParameters.ContainsKey('CursorHome')
    VerifyOnly = [bool]$VerifyOnly
}
$line = ($record | ConvertTo-Json -Compress) + [Environment]::NewLine
[IO.File]::AppendAllText((Join-Path $PSScriptRoot 'calls.jsonl'), $line, (New-Object Text.UTF8Encoding($false)))
'@
    [IO.File]::WriteAllText((Join-Path $fixtureScripts 'install-cursor-plugin.ps1'), $stub, $utf8)

    # Exercise both switch values and both optional-home cases through the real wrapper.
    foreach ($verify in @($false, $true)) {
        foreach ($customHome in @($false, $true)) {
            $arguments = @{ PluginRoot = $fixtureRoot; CursorOnly = $true }
            if ($verify) { $arguments.VerifyOnly = $true }
            if ($customHome) { $arguments.CursorHome = $cursorFixture }
            & $wrapper @arguments | Out-Null
            $records = @(Get-Content -LiteralPath (Join-Path $fixtureScripts 'calls.jsonl') | ForEach-Object { $_ | ConvertFrom-Json })
            $record = $records[-1]
            Assert-Condition ($record.PluginRoot -eq $fixtureRoot) 'PluginRoot was not forwarded'
            Assert-Condition ($record.VerifyOnly -eq $verify) 'VerifyOnly was not forwarded'
            Assert-Condition ($record.CursorHomeBound -eq $customHome) 'CursorHome binding changed'
            if ($customHome) {
                Assert-Condition ($record.CursorHome -eq $cursorFixture) 'CursorHome was not forwarded'
            } else {
                Assert-Condition ([string]::IsNullOrEmpty($record.CursorHome)) 'wrapper supplied an unexpected default CursorHome'
            }
        }
    }
    Expect-Failure { & $wrapper -PluginRoot $fixtureRoot -CursorOnly -ClaudeOnly } '-ClaudeOnly and -CursorOnly are mutually exclusive.'
    Expect-Failure { & $wrapper -PluginRoot $fixtureRoot -CursorHome $cursorFixture } '-CursorHome requires -CursorOnly.'
    $calls = @(Get-Content -LiteralPath (Join-Path $fixtureScripts 'calls.jsonl'))
    Assert-Condition ($calls.Count -eq 4) 'invalid arguments reached the installer, or delegation did not happen exactly once'
    Assert-Condition (-not (Test-Path -LiteralPath $cursorFixture)) 'wrapper created a runtime home instead of delegating'
} finally {
    # Delete only this run's exact temporary root, never a caller-provided directory.
    $cleanup = [IO.Path]::GetFullPath($fixtureRoot)
    Assert-Condition ((Split-Path -Parent $cleanup) -eq $tempParent -and (Split-Path -Leaf $cleanup) -eq $fixtureName) 'unsafe fixture cleanup path'
    if (Test-Path -LiteralPath $cleanup) { Remove-Item -LiteralPath $cleanup -Recurse -Force }
}

Write-Output 'Cursor plugin structure and wrapper delegation validation passed.'
