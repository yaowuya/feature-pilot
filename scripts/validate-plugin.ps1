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
$codexPlugin = Read-Utf8 (Join-Path $root '.codex-plugin\plugin.json') | ConvertFrom-Json
$marketplace = Read-Utf8 (Join-Path $root '.claude-plugin\marketplace.json') | ConvertFrom-Json
$marketplacePlugin = @($marketplace.plugins | Where-Object { $_.name -eq $plugin.name })[0]

Assert-Condition ($null -ne $marketplacePlugin) "marketplace entry for '$($plugin.name)' is missing"
Assert-Condition ($marketplacePlugin.version -eq $plugin.version) "plugin and marketplace versions differ"
Assert-Condition ($marketplacePlugin.source -eq './') "marketplace source must remain './'"
Assert-Condition ($codexPlugin.name -eq $plugin.name) 'Claude Code and Codex plugin names differ'
$codexBaseVersion = @($codexPlugin.version -split '\+', 2)[0]
Assert-Condition ($codexBaseVersion -eq $plugin.version) 'Codex plugin base version must match the Claude Code plugin version'
Assert-Condition ($codexPlugin.skills -eq './skills/') 'Codex plugin must expose the repository skills directory'
Assert-Condition ($codexPlugin.interface.displayName -and $codexPlugin.interface.shortDescription -and $codexPlugin.interface.longDescription) 'Codex plugin interface metadata is incomplete'

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
    'skills\fp-plan\SKILL.md' = 'task-layout-template.md'
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
    'skills\fp-plan\task-layout-template.md' = @('## Change-level overview', 'tasks/00-overview.md', '## Cross-end Execution Order', 'Cover every task ID exactly once', '## Progress Summary', 'Derived from the unique owner checkboxes', '## Per-end fragment index', '## Fragment Order')
    'skills\fp-plan-backend\plan-template.md' = @('## Global Constraints', '## Backend Interface Ledger', '- [ ] **Task backend-NNN:', '**Depends on:**', '## Coverage Matrix')
    'skills\fp-plan-frontend\plan-template.md' = @('## Global Constraints', '- [ ] **Task frontend-NNN:', '**Depends on:**', '**Template Outline:**', '**Script/State Outline:**', '**Style Outline:**', '**Visual / UX Checks:**')
    'skills\fp-review\final-review-template.md' = @('**Verdict:**', '## Inputs Reviewed', '## Branch State', '## FeaturePilot Coverage', '## Verification Commands', '## Findings', '## Blocking Items Before Archive', '## Final Verdict Rationale')
}

foreach ($entry in $resourceAnchors.GetEnumerator()) {
    $resourceText = Read-Utf8 (Join-Path $root $entry.Key)
    foreach ($anchor in $entry.Value) {
        Assert-Condition ($resourceText.Contains($anchor)) "$($entry.Key) lost output-contract anchor: $anchor"
    }
}

$backendPlanTemplate = Read-Utf8 (Join-Path $root 'skills\fp-plan-backend\plan-template.md')
$frontendPlanTemplate = Read-Utf8 (Join-Path $root 'skills\fp-plan-frontend\plan-template.md')
Assert-Condition (-not ($backendPlanTemplate -match '(?m)^\s*- \[ \] \*\*Step ')) 'backend plan substeps must not create competing checkboxes'
Assert-Condition (-not ($frontendPlanTemplate -match '(?m)^\s*- \[ \] (?!\*\*Task frontend-)')) 'frontend plan details must not create competing checkboxes'
Assert-Condition (-not ($backendPlanTemplate.Contains('### - [ ]')) -and -not ($frontendPlanTemplate.Contains('### - [ ]'))) 'task checkbox markers must be real Markdown task-list items, not heading text'
Assert-Condition ([regex]::Matches($backendPlanTemplate, '(?m)^- \[ \] \*\*Task backend-NNN:').Count -eq 1) 'backend task template must have exactly one executable checkbox marker'
Assert-Condition ([regex]::Matches($frontendPlanTemplate, '(?m)^- \[ \] \*\*Task frontend-NNN:').Count -eq 1) 'frontend task template must have exactly one executable checkbox marker'
$taskLayoutTemplate = Read-Utf8 (Join-Path $root 'skills\fp-plan\task-layout-template.md')
foreach ($example in [regex]::Matches($taskLayoutTemplate, '(?s)```markdown\r?\n(?<body>.*?)\r?\n```')) {
    Assert-Condition (-not ($example.Groups['body'].Value -match '(?m)^- \[[ xX]\] \*\*Task ')) 'task overview/index examples must not own executable checkboxes'
}

$skillAnchors = @{
    'fp-init' = @('templates.md', 'project-family-examples.md', 'Lightweight discovery boundaries', 'Never overwrite')
    'fp-prd' = @('Bucket A/B', 'Bucket C', 'Prototype-first', 'explicitly approved', 'prd-template.md')
    'fp-prd-grill-me' = @('one question per turn', 'MUST NOT decide Bucket C', 'Minimal Fact Exploration')
    'fp-propose' = @('proposal-template.md', 'Why / What Changes / Out of Scope / Impact', 'fp-docs/changes/<slug>/proposal.md')
    'fp-brainstorm' = @('2-3', 'design-template.md', 'Visual Checks', 'design/00-index.md', 'design/backend.md', 'design/frontend.md')
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

$brainstormSkill = Read-Utf8 (Join-Path $root 'skills\fp-brainstorm\SKILL.md')
$startSkill = Read-Utf8 (Join-Path $root 'skills\fp-start\SKILL.md')
Assert-Condition ($brainstormSkill.Contains('fp-start') -and $brainstormSkill.Contains('`fp-plan`')) 'fp-brainstorm must return written design artifacts to fp-start instead of entering planning'
Assert-Condition ($brainstormSkill.Contains('design-template.md') -and $brainstormSkill.Contains('design/00-index.md')) 'fp-brainstorm is missing the pre-write content confirmation boundary'
Assert-Condition ($brainstormSkill.Contains('Agent') -and $brainstormSkill.Contains('Workflow')) 'fp-brainstorm is missing the single-owner finalization boundary'
Assert-Condition ($brainstormSkill.Contains('fp-start') -and $brainstormSkill.Contains('design/00-index.md')) 'fp-brainstorm is missing its post-write handoff to fp-start'
Assert-Condition ($startSkill.Contains('design/00-index.md') -and $startSkill.Contains('fp-plan')) 'fp-start is missing the post-write artifact confirmation boundary'
Assert-Condition ($startSkill.Contains('Agent') -and $startSkill.Contains('Workflow')) 'fp-start is missing the no-second-finalizer boundary'
Assert-Condition ($startSkill.Contains('Resume boundary')) 'fp-start is missing bounded resume behavior'
Assert-Condition ($startSkill.Contains('Task/Todo')) 'fp-start is missing non-authoritative bookkeeping failure handling'

Assert-Condition ($brainstormSkill.Contains('fp-docs/changes/<slug>/design/00-index.md')) 'fp-brainstorm must create the canonical design directory index'
Assert-Condition ($brainstormSkill.Contains('design/backend.md') -and $brainstormSkill.Contains('design/frontend.md')) 'fp-brainstorm must write stable per-end design entrypoints'
Assert-Condition ($brainstormSkill.Contains('> 500') -and $brainstormSkill.Contains('design/backend/00-index.md') -and $brainstormSkill.Contains('design/frontend/00-index.md')) 'fp-brainstorm is missing indexed large-design splitting'
Assert-Condition (-not ($brainstormSkill.Contains('fp-docs/changes/<slug>/design-backend.md'))) 'fp-brainstorm must not produce legacy root-level backend design files'
Assert-Condition (-not ($brainstormSkill.Contains('fp-docs/changes/<slug>/design-frontend.md'))) 'fp-brainstorm must not produce legacy root-level frontend design files'
Assert-Condition ($brainstormSkill.Contains('design-template.md') -and $brainstormSkill.Contains('design/00-index.md')) 'fp-brainstorm must gate the design index behind pre-write approval'

$planSkill = Read-Utf8 (Join-Path $root 'skills\fp-plan\SKILL.md')
Assert-Condition ($planSkill.Contains('design/00-index.md') -and $planSkill.Contains('legacy fallback')) 'fp-plan must condition canonical index reads so legacy-only changes can fall back'

$figmaSkill = Read-Utf8 (Join-Path $root 'skills\fp-figma\SKILL.md')
Assert-Condition ($figmaSkill.Contains('design/00-index.md') -and $figmaSkill.Contains('design/frontend.md')) 'fp-figma is missing the canonical design path contract'
Assert-Condition ($figmaSkill.Contains('design/frontend/00-index.md') -and $figmaSkill.Contains('design/frontend/<number>-<area>.md')) 'fp-figma must not create unreachable frontend design fragments'
Assert-Condition ($figmaSkill.Contains('design/frontend/00-index.md')) 'fp-figma must preserve both canonical indexes when writing fragments'

$backendPlanSkill = Read-Utf8 (Join-Path $root 'skills\fp-plan-backend\SKILL.md')
$frontendPlanSkill = Read-Utf8 (Join-Path $root 'skills\fp-plan-frontend\SKILL.md')
Assert-Condition ($backendPlanSkill.Contains('design/backend/00-index.md') -and $backendPlanSkill.Contains('canonical-first')) 'fp-plan-backend must resolve an existing canonical fragment index independently of entrypoint links'
Assert-Condition ($frontendPlanSkill.Contains('design/frontend/00-index.md') -and $frontendPlanSkill.Contains('canonical-first')) 'fp-plan-frontend must resolve an existing canonical fragment index independently of entrypoint links'

foreach ($consumer in @('fp-start', 'fp-plan', 'fp-execute', 'fp-execute-sdd', 'fp-review')) {
    $consumerText = Read-Utf8 (Join-Path $root "skills\$consumer\SKILL.md")
    Assert-Condition ($consumerText.Contains('design/')) "$consumer is missing canonical design paths"
    Assert-Condition ($consumerText.Contains('design-backend.md') -and $consumerText.Contains('design-frontend.md')) "$consumer is missing read-only compatibility for legacy root design files"
}
Assert-Condition ($backendPlanSkill.Contains('design-backend.md')) 'fp-plan-backend is missing read-only compatibility for the legacy backend design file'
Assert-Condition ($frontendPlanSkill.Contains('design-frontend.md')) 'fp-plan-frontend is missing read-only compatibility for the legacy frontend design file'

$executeSkill = Read-Utf8 (Join-Path $root 'skills\fp-execute\SKILL.md')
$archiveSkill = Read-Utf8 (Join-Path $root 'skills\fp-archive\SKILL.md')
Assert-Condition ($backendPlanSkill.Contains('tasks/backend/00-index.md') -and $backendPlanSkill.Contains('exceeds 500 lines')) 'fp-plan-backend is missing indexed large-plan splitting'
Assert-Condition ($frontendPlanSkill.Contains('tasks/frontend/00-index.md') -and $frontendPlanSkill.Contains('exceeds 500 lines')) 'fp-plan-frontend is missing indexed large-plan splitting'
Assert-Condition ($backendPlanSkill.Contains('exactly once') -and $frontendPlanSkill.Contains('exactly once')) 'task plan producers must own each executable task checkbox exactly once'
Assert-Condition ($backendPlanSkill.Contains('backend-001') -and $frontendPlanSkill.Contains('frontend-001') -and $backendPlanSkill.Contains('never resets per file') -and $frontendPlanSkill.Contains('never resets per file')) 'split task IDs must remain stable and unique across fragments'
Assert-Condition ($planSkill.Contains('tasks/00-overview.md') -and $planSkill.Contains('task-layout-template.md') -and $planSkill.Contains('both ends are planned or either end is split')) 'fp-plan is missing the conditional change-level task overview'
foreach ($taskConsumer in @('fp-execute', 'fp-execute-sdd', 'fp-review', 'fp-archive')) {
    $taskConsumerText = Read-Utf8 (Join-Path $root "skills\$taskConsumer\SKILL.md")
    Assert-Condition ($taskConsumerText.Contains('tasks/backend/00-index.md') -and $taskConsumerText.Contains('tasks/frontend/00-index.md')) "$taskConsumer must resolve all indexed task fragments"
    Assert-Condition ($taskConsumerText.Contains('tasks/00-overview.md')) "$taskConsumer is missing cross-end task overview handling"
    Assert-Condition ($taskConsumerText.Contains('unindexed fragment')) "$taskConsumer must reject fragments outside the authoritative index"
}
Assert-Condition ($executeSkill.Contains('not a second completion authority') -and $sddSkill.Contains('not a second completion authority')) 'execution ledgers must remain recovery evidence rather than competing task state'
Assert-Condition ($executeSkill.Contains('derived progress summary') -and $sddSkill.Contains('derived overview progress counts')) 'executors must recompute overview progress from owner checkboxes'
Assert-Condition ($archiveSkill.Contains('task-owner files') -and $reviewSkill.Contains('task-owner files')) 'review and archive must inspect only resolved checkbox owner files for completion'

$commandChars = ($commands | ForEach-Object { (Read-Utf8 $_.FullName).Length } | Measure-Object -Sum).Sum
Assert-Condition ($commandChars -le 5000) "command adapters exceed the 5000-character budget: $commandChars"

$skillChars = ($skills | ForEach-Object { (Read-Utf8 (Join-Path $_.FullName 'SKILL.md')).Length } | Measure-Object -Sum).Sum
$coreChars = $commandChars + $skillChars + $sharedText.Length
Write-Output "FeaturePilot plugin validation passed: $($commands.Count) commands, $($skills.Count) skills, all SKILL.md files <= 500 lines, core prompt chars $coreChars."
