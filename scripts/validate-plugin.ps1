$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "Validation failed: $message"
    }
}

function Read-Utf8([string]$path) {
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

$plugin = Read-Utf8 (Join-Path $root '.claude-plugin\plugin.json') | ConvertFrom-Json
$marketplace = Read-Utf8 (Join-Path $root '.claude-plugin\marketplace.json') | ConvertFrom-Json
$marketplacePlugin = @($marketplace.plugins | Where-Object { $_.name -eq $plugin.name })[0]

Assert-Condition ($null -ne $marketplacePlugin) "marketplace entry for '$($plugin.name)' is missing"
Assert-Condition ($marketplacePlugin.version -eq $plugin.version) "plugin and marketplace versions differ"
Assert-Condition ($marketplacePlugin.source -eq './') "marketplace source must remain './'"

$commands = @(Get-ChildItem (Join-Path $root 'commands') -Filter 'fp-*.md' -File)
$skills = @(Get-ChildItem (Join-Path $root 'skills') -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') })

foreach ($command in $commands) {
    $skillName = $command.BaseName
    $skillPath = Join-Path $root "skills\$skillName\SKILL.md"
    Assert-Condition (Test-Path $skillPath) "$($command.Name) has no matching skills/$skillName/SKILL.md"
    $commandText = Read-Utf8 $command.FullName
    Assert-Condition ($commandText -match [regex]::Escape($skillName)) "$($command.Name) does not invoke or identify $skillName"
}

foreach ($skill in $skills) {
    $skillPath = Join-Path $skill.FullName 'SKILL.md'
    $skillText = Read-Utf8 $skillPath
    $lineCount = @($skillText -split "`r?`n").Count
    Assert-Condition ($lineCount -le 500) "$($skill.Name)/SKILL.md has $lineCount lines (limit: 500)"
    Assert-Condition ($skillText -match "(?m)^name:\s*$([regex]::Escape($skill.Name))\s*$") "$($skill.Name)/SKILL.md frontmatter name does not match its directory"
    Assert-Condition ($skillText.Contains('fp-docs/manifest.md')) "$($skill.Name)/SKILL.md is missing the manifest read-order contract"
}

$sddSkill = Read-Utf8 (Join-Path $root 'skills\fp-execute-sdd\SKILL.md')
Assert-Condition ($sddSkill.Contains('intel/sdd-handoff.md')) 'fp-execute-sdd is missing the SDD handoff preflight contract'
Assert-Condition ($sddSkill.Contains('unresolved Unknown')) 'fp-execute-sdd is missing unresolved Unknown handling'

$reviewSkill = Read-Utf8 (Join-Path $root 'skills\fp-review\SKILL.md')
Assert-Condition ($reviewSkill.Contains('stale intel')) 'fp-review is missing stale-intel review guidance'
Assert-Condition ($reviewSkill.Contains('information-layer process')) 'fp-review is missing information-layer process review guidance'

Write-Output "FeaturePilot plugin validation passed: $($commands.Count) commands, $($skills.Count) skills, all SKILL.md files <= 500 lines."
