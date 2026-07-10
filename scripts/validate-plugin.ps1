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
$sharedPath = Join-Path $root 'skills\_shared\workspace-rules.md'

Assert-Condition (Test-Path $sharedPath) 'shared workspace contract is missing'
$sharedText = Read-Utf8 $sharedPath
foreach ($anchor in @('target repository root', 'fp-docs/manifest.md', 'smallest relevant', 'stale-prone', 'Current code', 'Approved PRD', 'Only `fp-init`', '`fp-archive`')) {
    Assert-Condition ($sharedText.Contains($anchor)) "shared workspace contract is missing: $anchor"
}

foreach ($command in $commands) {
    $skillName = $command.BaseName
    $skillPath = Join-Path $root "skills\$skillName\SKILL.md"
    Assert-Condition (Test-Path $skillPath) "$($command.Name) has no matching skills/$skillName/SKILL.md"
    $commandText = Read-Utf8 $command.FullName
    $commandFrontmatter = [regex]::Match($commandText, '(?s)\A---\r?\n(?<body>.*?)\r?\n---')
    Assert-Condition ($commandFrontmatter.Success) "$($command.Name) has invalid frontmatter boundaries"
    Assert-Condition ($commandFrontmatter.Groups['body'].Value -match '(?m)^description:\s*\S') "$($command.Name) has no description"
    Assert-Condition ($commandText -match [regex]::Escape($skillName)) "$($command.Name) does not invoke or identify $skillName"
    Assert-Condition ($commandText.Contains('Gate checksum')) "$($command.Name) is missing its gate checksum"
    $commandLines = @($commandText -split "`r?`n").Count
    Assert-Condition ($commandLines -le 20) "$($command.Name) is no longer a thin adapter ($commandLines lines)"
}

foreach ($skill in $skills) {
    $skillPath = Join-Path $skill.FullName 'SKILL.md'
    $skillText = Read-Utf8 $skillPath
    $frontmatter = [regex]::Match($skillText, '(?s)\A---\r?\n(?<body>.*?)\r?\n---')
    Assert-Condition ($frontmatter.Success) "$($skill.Name)/SKILL.md has invalid frontmatter boundaries"
    $frontmatterKeys = @([regex]::Matches($frontmatter.Groups['body'].Value, '(?m)^([a-zA-Z0-9_-]+):') | ForEach-Object { $_.Groups[1].Value })
    Assert-Condition ($frontmatterKeys.Count -eq 2 -and $frontmatterKeys -contains 'name' -and $frontmatterKeys -contains 'description') "$($skill.Name)/SKILL.md frontmatter must contain only name and description"
    Assert-Condition ($frontmatter.Groups['body'].Value -match '(?m)^description:\s*\S') "$($skill.Name)/SKILL.md has no description"
    $lineCount = @($skillText -split "`r?`n").Count
    Assert-Condition ($lineCount -le 500) "$($skill.Name)/SKILL.md has $lineCount lines (limit: 500)"
    Assert-Condition ($skillText -match "(?m)^name:\s*$([regex]::Escape($skill.Name))\s*$") "$($skill.Name)/SKILL.md frontmatter name does not match its directory"
    Assert-Condition ($skillText.Contains('../_shared/workspace-rules.md')) "$($skill.Name)/SKILL.md does not load the shared workspace contract"
}

Assert-Condition (-not ((Read-Utf8 (Join-Path $root 'skills\fp-prd\SKILL.md')).Contains('# <产品/功能名称> PRD'))) 'fp-prd embeds its output template instead of lazy-loading it'

$lazyResources = @{
    'skills\fp-prd\SKILL.md' = 'prd-template.md'
    'skills\fp-propose\SKILL.md' = 'proposal-template.md'
    'skills\fp-brainstorm\SKILL.md' = 'design-template.md'
    'skills\fp-plan-backend\SKILL.md' = 'plan-template.md'
    'skills\fp-plan-frontend\SKILL.md' = 'plan-template.md'
    'skills\fp-review\SKILL.md' = 'final-review-template.md'
    'skills\fp-init\SKILL.md' = 'project-family-examples.md'
}

foreach ($entry in $lazyResources.GetEnumerator()) {
    $skillPath = Join-Path $root $entry.Key
    $resourcePath = Join-Path (Split-Path -Parent $skillPath) $entry.Value
    Assert-Condition (Test-Path $resourcePath) "$($entry.Key) references missing resource $($entry.Value)"
    Assert-Condition ((Read-Utf8 $skillPath).Contains($entry.Value)) "$($entry.Key) does not route to $($entry.Value)"
}

$resourceAnchors = @{
    'skills\fp-prd\prd-template.md' = @('### 1.1 ', '### 3.1 ', '#### 3.1.1 ', '#### 3.1.5 ', '### 4.1 ', '### 4.3 ', 'flowchart TD')
    'skills\fp-propose\proposal-template.md' = @('## Why', '## What Changes', '## Capabilities', '## Out of Scope', '## Impact')
    'skills\fp-brainstorm\design-template.md' = @('# <', '## ', '### API ', '#### API ')
    'skills\fp-plan-backend\plan-template.md' = @('## Global Constraints', '## Backend Interface Ledger', '### Task N:', '## Coverage Matrix')
    'skills\fp-plan-frontend\plan-template.md' = @('## Global Constraints', '**Template Outline:**', '**Script/State Outline:**', '**Style Outline:**', '**Visual / UX Checks:**')
    'skills\fp-review\final-review-template.md' = @('**Verdict:**', '## Inputs Reviewed', '## Branch State', '## FeaturePilot Coverage', '## Verification Commands', '## Findings', '## Blocking Items Before Archive', '## Final Verdict Rationale')
}

foreach ($entry in $resourceAnchors.GetEnumerator()) {
    $resourceText = Read-Utf8 (Join-Path $root $entry.Key)
    foreach ($anchor in $entry.Value) {
        Assert-Condition ($resourceText.Contains($anchor)) "$($entry.Key) lost output-contract anchor: $anchor"
    }
}

$skillAnchors = @{
    'fp-init' = @('templates.md', 'project-family-examples.md', 'Lightweight discovery boundaries', 'Never overwrite')
    'fp-prd' = @('Bucket A/B', 'Bucket C', 'Prototype-first', 'explicitly approved', 'prd-template.md')
    'fp-prd-grill-me' = @('one question per turn', 'MUST NOT decide Bucket C', 'Minimal Fact Exploration')
    'fp-propose' = @('proposal-template.md', 'Why / What Changes / Out of Scope / Impact', 'fp-docs/changes/<slug>/proposal.md')
    'fp-brainstorm' = @('2-3', 'design-template.md', 'Visual Checks', 'design-backend.md', 'design-frontend.md')
    'fp-plan' = @('fp-plan-backend', 'fp-plan-frontend', 'plan-backend.md', 'plan-frontend.md')
    'fp-plan-backend' = @('Global Constraints', 'Backend Interface Ledger', 'Coverage Matrix', 'plan-template.md')
    'fp-plan-frontend' = @('Global Constraints', 'Interfaces', 'Visual Checks', 'plan-template.md')
    'fp-execute' = @('semi', 'full', 'Pre-flight Plan Review', 'TDD')
    'fp-start' = @('fp-propose', 'fp-brainstorm', 'fp-plan', 'fp-execute-sdd', 'fp-review')
    'fp-execute-sdd' = @('No parallel implementers', 'progress.md', 'task-brief-template.md', 'task-reviewer-prompt.md', 'Fix Loop')
    'fp-review' = @('read-only final reviewer', 'PASS_WITH_NOTES', 'stale intel', 'final-review-template.md')
    'fp-quick' = @('fp-propose', 'proposal.md', 'fp-docs/changes/', 'rg --files')
    'fp-archive' = @('history/history.md', 'blocked', 'proposal.md')
    'fp-figma' = @('Figma', 'Flex / Grid', 'Visual Checks', 'settings/frontend.md')
    'fp-ui-spec' = @('settings/frontend.md', 'existing code', 'Public-plugin constraints')
    'fp-ux-spec' = @('settings/frontend.md', 'existing code', 'Public-plugin constraints')
    'fp-grill-me' = @('recommendation is not', 'codebase', 'explicit user confirmation')
}

foreach ($entry in $skillAnchors.GetEnumerator()) {
    $skillText = Read-Utf8 (Join-Path $root "skills\$($entry.Key)\SKILL.md")
    foreach ($anchor in $entry.Value) {
        Assert-Condition ($skillText.Contains($anchor)) "$($entry.Key) lost capability anchor: $anchor"
    }
}

$sddSkill = Read-Utf8 (Join-Path $root 'skills\fp-execute-sdd\SKILL.md')
Assert-Condition ($sddSkill.Contains('intel/sdd-handoff.md')) 'fp-execute-sdd is missing the SDD handoff preflight contract'
Assert-Condition ($sddSkill.Contains('unresolved Unknown')) 'fp-execute-sdd is missing unresolved Unknown handling'

$reviewSkill = Read-Utf8 (Join-Path $root 'skills\fp-review\SKILL.md')
Assert-Condition ($reviewSkill.Contains('stale intel')) 'fp-review is missing stale-intel review guidance'
Assert-Condition ($reviewSkill.Contains('information-layer process')) 'fp-review is missing information-layer process review guidance'

$commandChars = ($commands | ForEach-Object { (Read-Utf8 $_.FullName).Length } | Measure-Object -Sum).Sum
Assert-Condition ($commandChars -le 5000) "command adapters exceed the 5000-character budget: $commandChars"

$skillChars = ($skills | ForEach-Object { (Read-Utf8 (Join-Path $_.FullName 'SKILL.md')).Length } | Measure-Object -Sum).Sum
$coreChars = $commandChars + $skillChars + $sharedText.Length
Write-Output "FeaturePilot plugin validation passed: $($commands.Count) commands, $($skills.Count) skills, all SKILL.md files <= 500 lines, core prompt chars $coreChars."
