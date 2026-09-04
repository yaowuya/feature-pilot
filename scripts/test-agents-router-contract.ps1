$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
$agentsPath = Join-Path $root 'AGENTS.md'

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "AGENTS router contract validation failed: $message"
    }
}

function Read-Utf8([string]$path) {
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Test-TwoColumnRoute([string]$text, [string]$targetCell) {
    $pattern = '(?m)^\|\s*[^|\r\n]+\s*\|\s*' + [regex]::Escape($targetCell) + '\s*\|\s*$'
    return [regex]::Matches($text, $pattern).Count -eq 1
}

Assert-Condition (Test-Path -LiteralPath $agentsPath -PathType Leaf) 'AGENTS.md is missing'
$agents = Read-Utf8 $agentsPath

Assert-Condition (@($agents -split "`r?`n").Count -le 60) 'AGENTS.md is not a low-context router'
Assert-Condition ($agents.Contains('`AGENTS.md` is a router, not a workflow contract cache.')) 'AGENTS.md does not declare router-only ownership'
Assert-Condition ($agents.Contains('## Codex fallback router')) 'AGENTS.md lacks the Codex fallback router'
Assert-Condition ($agents.Contains('## Conditional contract router')) 'AGENTS.md lacks the conditional contract router'
Assert-Condition ($agents.Contains('| User intent | Read first |')) 'AGENTS.md intent router must be a two-column interface'
Assert-Condition ($agents.Contains('| Trigger branch | Required read |')) 'AGENTS.md contract router must be a two-column interface'
Assert-Condition (-not $agents.Contains('| Owns |')) 'AGENTS.md caches owner summaries instead of routing to them'

$intentTargets = @(
    '`skills/fp-init/SKILL.md`'
    '`skills/fp-explore/SKILL.md`'
    '`skills/fp-eli5/SKILL.md`'
    '`skills/fp-start/SKILL.md`'
    '`skills/fp-prd/SKILL.md`'
    '`skills/fp-quick/SKILL.md`'
    '`skills/fp-figma/SKILL.md`'
    '`skills/fp-propose/SKILL.md`'
    '`skills/fp-brainstorm/SKILL.md`'
    '`skills/fp-plan/SKILL.md`'
    '`skills/fp-execute/SKILL.md`'
    '`skills/fp-execute-sdd/SKILL.md`'
    '`skills/fp-coverage/SKILL.md`'
    '`skills/fp-module-review/SKILL.md`'
    '`skills/fp-final-review/SKILL.md`'
    '`skills/fp-archive/SKILL.md`'
)
foreach ($target in $intentTargets) {
    Assert-Condition (Test-TwoColumnRoute $agents $target) "missing or duplicated intent route: $target"
}
$directExecutionRow = '| Execute a confirmed plan (default direct execution) | `skills/fp-execute/SKILL.md` |'
$sddExecutionRow = '| Execute a confirmed plan with explicitly requested SDD, or resume recorded SDD progress | `skills/fp-execute-sdd/SKILL.md` |'
Assert-Condition ($agents.Contains($directExecutionRow) -and $agents.Contains($sddExecutionRow)) 'execution routing predicates do not map to their required skills'
$swappedExecutionMutation = $agents.Replace($directExecutionRow, '__DIRECT_ROUTE__').Replace($sddExecutionRow, '| Execute a confirmed plan (default direct execution) | `skills/fp-execute-sdd/SKILL.md` |').Replace('__DIRECT_ROUTE__', '| Execute a confirmed plan with explicitly requested SDD, or resume recorded SDD progress | `skills/fp-execute/SKILL.md` |')
Assert-Condition (-not ($swappedExecutionMutation.Contains($directExecutionRow) -and $swappedExecutionMutation.Contains($sddExecutionRow))) 'router test accepts swapped direct and SDD destinations'

$contractTargets = @(
    '`skills/_shared/workspace-rules.md`'
    '`skills/_shared/artifact-layout.md`'
    '`skills/_shared/decision-ledger.md`'
    '`skills/_shared/codegraph.md`'
    '`skills/_shared/ui-e2e-contract.md`'
)
foreach ($target in $contractTargets) {
    Assert-Condition (Test-TwoColumnRoute $agents $target) "missing or duplicated conditional contract route: $target"
}

foreach ($forbidden in @(
    '## 1.0.0 release behavior'
    '## UI/E2E execution and archive gates'
    '## Workspace and settings'
    '## Optional CodeGraph acceleration'
    '## OpenSpec-inspired artifact model'
    '## Low-cost flow'
    '## Mandatory gates'
    '## Naming'
    'npm install -g @colbymchenry/codegraph@latest'
    'coverage-tooling-bootstrap'
    'manifest-only default'
    'dirty-after-write'
    'post-write-sync'
    'SOURCE_READY -> STATIC_UI_READY'
    'Mocked Core API: false'
    '500 lines'
    '30,000 characters'
    'fp-docs/archive/YYYY-MM-DD-<slug>/'
)) {
    Assert-Condition (-not $agents.Contains($forbidden)) "AGENTS.md duplicates owner detail: $forbidden"
}

$missingRouteMutation = $agents.Replace('`skills/fp-explore/SKILL.md`', '`skills/removed/SKILL.md`')
Assert-Condition (-not (Test-TwoColumnRoute $missingRouteMutation '`skills/fp-explore/SKILL.md`')) 'router test accepts a missing intent route'
$duplicateRouteMutation = $agents + [Environment]::NewLine + '| Duplicate | `skills/_shared/codegraph.md` |'
Assert-Condition (-not (Test-TwoColumnRoute $duplicateRouteMutation '`skills/_shared/codegraph.md`')) 'router test accepts a duplicated contract route'

Write-Output 'AGENTS router contract validation passed.'
