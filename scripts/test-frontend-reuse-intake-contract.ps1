$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Read-Contract([string]$path) {
    return [IO.File]::ReadAllText((Join-Path $root $path), [Text.Encoding]::UTF8)
}

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) { throw "Frontend reuse/intake validation failed: $message" }
}

function Get-ActiveMarkdown([string]$text) {
    $withoutComments = [regex]::Replace($text, '(?s)<!--.*?-->', '')
    $active = [Collections.Generic.List[string]]::new()
    $fenceChar = ''
    $fenceLength = 0
    foreach ($line in ($withoutComments -split '\r?\n')) {
        if ($line -match '^ {0,3}(?<fence>`{3,}|~{3,})(?<tail>.*)$') {
            $token = $Matches['fence']
            if (-not $fenceChar) {
                $fenceChar = $token.Substring(0, 1)
                $fenceLength = $token.Length
            }
            elseif ($token.StartsWith($fenceChar) -and $token.Length -ge $fenceLength -and -not $Matches['tail'].Trim()) {
                $fenceChar = ''
                $fenceLength = 0
            }
            continue
        }
        if (-not $fenceChar) { $active.Add($line) }
    }
    return $active -join "`n"
}

function Test-ReuseReference([string]$text) {
    return (Get-ActiveMarkdown $text).Contains('${CLAUDE_PLUGIN_ROOT}/skills/_shared/frontend-reuse-contract.md')
}

function Test-SourceInventory([string]$text) {
    $active = Get-ActiveMarkdown $text
    $section = [regex]::Match($active, '(?ms)^## Figma Source Intake\s*\n(?<body>.*?)(?=^## |\z)')
    if (-not $section.Success) { return $false }
    foreach ($field in @('Source node / revision', 'UI unit / state', 'Scope / exclusion reason', 'Visual Check / Task ID + Case ID', 'Annotation status / source', 'ownerNodeId', 'not-applicable', 'pending', 'resolved')) {
        if (-not $section.Groups['body'].Value.Contains($field)) { return $false }
    }
    return $true
}

$reusePath = 'skills\_shared\frontend-reuse-contract.md'
$reuse = Get-ActiveMarkdown (Read-Contract $reusePath)
$scopeRows = @([regex]::Matches($reuse, '(?m)^\| `(?<scope>new-module|refactor|new-files|not-applicable)` \| (?<investigation>required|not-required) \| (?<confirmation>[^\r\n|]+)\|\s*$'))
Assert-Condition ($scopeRows.Count -eq 4) 'scope table must cover exactly four frontend applicability branches'
Assert-Condition (@($scopeRows | ForEach-Object { $_.Groups['scope'].Value } | Sort-Object -Unique).Count -eq 4) 'frontend scopes are duplicated'
foreach ($row in $scopeRows) {
    $expected = if ($row.Groups['scope'].Value -eq 'not-applicable') { 'not-required' } else { 'required' }
    Assert-Condition ($row.Groups['investigation'].Value -eq $expected) "wrong reuse applicability: $($row.Groups['scope'].Value)"
}

foreach ($field in @('Capability', 'Reference', 'Reuse Decision', 'Gap / Deviation', 'Verification', 'Frontend Scope', 'Reference Modules', 'Reuse Decisions', 'Directory Proposal', 'Directory Confirmation', 'Confirmation Source')) {
    Assert-Condition ($reuse.Contains($field)) "reuse contract lost field: $field"
}

$consumers = @(
    'skills\fp-brainstorm\SKILL.md'
    'skills\fp-plan-frontend\SKILL.md'
    'skills\fp-quick\SKILL.md'
    'skills\fp-figma\SKILL.md'
    'skills\fp-execute\SKILL.md'
    'skills\fp-execute-sdd\SKILL.md'
    'skills\fp-final-review\final-review-contract.md'
)
foreach ($path in $consumers) {
    $body = Read-Contract $path
    Assert-Condition (Test-ReuseReference $body) "missing active shared-contract reference: $path"
    $noReference = $body.Replace('${CLAUDE_PLUGIN_ROOT}/skills/_shared/frontend-reuse-contract.md', 'removed-reuse-contract')
    $fakeReference = $noReference + "`n<!-- " + '${CLAUDE_PLUGIN_ROOT}/skills/_shared/frontend-reuse-contract.md' + " -->`n~~~text`n" + '${CLAUDE_PLUGIN_ROOT}/skills/_shared/frontend-reuse-contract.md' + "`n~~~"
    Assert-Condition (-not (Test-ReuseReference $fakeReference)) "comment/fence-only reference accepted: $path"
}

foreach ($path in @('skills\fp-plan\SKILL.md', 'skills\fp-start\SKILL.md')) {
    $body = Get-ActiveMarkdown (Read-Contract $path)
    Assert-Condition ($body.Contains('new-module') -and $body.Contains('Plan') -and $body.Contains('目录树') -and $body.Contains('同一次')) "outer planner lost the concrete Plan confirmation handoff: $path"
}
$plan = Read-Contract 'skills\fp-plan-frontend\plan-template.md'
foreach ($field in @('Frontend Scope', 'Reference Modules', 'Reuse Decisions', 'Directory Proposal', 'Directory Confirmation', 'Confirmation Source', '[new]', '[modify]', '[reuse]')) {
    Assert-Condition ($plan.Contains($field)) "frontend plan template lost confirmation evidence: $field"
}
Assert-Condition ($plan.IndexOf('## Frontend Reuse And Directory Confirmation') -lt $plan.IndexOf('## File Structure')) 'directory decision context is not at Plan delivery'

foreach ($path in @('skills\fp-execute-sdd\task-brief-template.md', 'skills\fp-execute-sdd\implementer-prompt.md', 'skills\fp-execute-sdd\task-reviewer-prompt.md')) {
    $body = Read-Contract $path
    Assert-Condition ($body.Contains('frontend-reuse-contract.md') -and $body.Contains('Plan') -and $body -match '(?i)responsibilit') "delegated task lost reuse/Plan responsibilities: $path"
}

$figma = Read-Contract 'skills\fp-figma\SKILL.md'
Assert-Condition (Test-SourceInventory $figma) 'full-source intake lost unit, case, or annotation ownership'
foreach ($field in @('Visual Check / Task ID + Case ID', 'ownerNodeId', 'Annotation status / source')) {
    $mutated = $figma.Replace($field, 'REMOVED_INTAKE_FIELD')
    Assert-Condition ($mutated -ne $figma -and -not (Test-SourceInventory $mutated)) "intake mutation escaped validation: $field"
}
foreach ($path in @('skills\fp-brainstorm\design-template.md', 'skills\fp-plan-frontend\SKILL.md', 'skills\fp-final-review\final-review-contract.md', 'skills\fp-figma\figma-review-template.md')) {
    Assert-Condition ((Read-Contract $path).Contains('Figma Source Scope')) "source inventory is not carried into design/plan/review: $path"
}

Write-Output 'Frontend reuse and Figma source-intake contract validation passed.'
