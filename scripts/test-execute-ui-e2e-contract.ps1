$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()

function Read-Utf8([string]$relativePath) {
    return [System.IO.File]::ReadAllText(
        (Join-Path $root $relativePath),
        [System.Text.Encoding]::UTF8
    )
}

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        $script:failures.Add($message)
    }
}

function Require-MutationBaseline([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "Mutation baseline failed: $message"
    }
}

function Get-Section([string]$text, [string]$heading) {
    $normalized = $text -replace "`r`n?", "`n"
    $headingLine = "## $heading"
    $start = $normalized.IndexOf($headingLine, [System.StringComparison]::Ordinal)
    if ($start -lt 0) { return '' }
    $bodyStart = $start + $headingLine.Length
    $nextHeading = $normalized.IndexOf("`n## ", $bodyStart, [System.StringComparison]::Ordinal)
    if ($nextHeading -lt 0) { return $normalized.Substring($bodyStart) }
    return $normalized.Substring($bodyStart, $nextHeading - $bodyStart)
}

function Has-All([string]$text, [string[]]$anchors) {
    foreach ($anchor in $anchors) {
        if ($text.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            return $false
        }
    }
    return $true
}

function Test-SharedContractBinding([string]$text) {
    return $text.Contains('`${CLAUDE_PLUGIN_ROOT}/skills/_shared/ui-e2e-contract.md`') -and
        $text -match '(?is)Read .*ui-e2e-contract\.md.*before executing UI-bearing work'
}

function Test-PlanCaseLinking([string]$text) {
    $section = Get-Section $text 'UI-bearing Task Gate'
    return (Has-All $section @(
        'UI/E2E Delivery Contract',
        'Visual Evidence Manifest',
        'Task ID + Case ID',
        'does not duplicate visual-manifest fields',
        'unique stable task owner'
    ))
}

function Test-StatePaths([string]$text) {
    $section = Get-Section $text 'UI-bearing Task Gate'
    return (Has-All $section @(
        'SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS',
        'INTERACTION_READY -> FRONTEND_E2E_PASS',
        'static-only',
        'interactive',
        'business-flow',
        'E2E Applicability: N/A',
        'E2E Applicability: REQUIRED',
        'Required E2E cannot be `SKIPPED` or manual-approved',
        'PASS_WITH_NOTES'
    ))
}

function Test-E2EEvidenceAndCoverage([string]$text) {
    $section = Get-Section $text 'UI-bearing Task Gate'
    return (Has-All $section @(
        '.fp-execute/e2e/<task-id>/<case-id>/',
        'coverage-matrix.md',
        'Executed command',
        'Environment identity',
        'Destination',
        'Start',
        'End',
        'Attempts',
        'Test IDs',
        'Artifacts',
        'Cleanup',
        'screenshot is not E2E evidence',
        'happy paths and branches',
        'validation and boundaries',
        'loading, empty, error, and retry states',
        'permissions and isolation',
        'persistence and navigation',
        'state transitions and concurrency',
        'pagination, filtering, sorting, and compatibility'
    ))
}

function Test-ZeroMockRule([string]$text) {
    $section = Get-Section $text 'UI-bearing Task Gate'
    return (Has-All $section @(
        'absolute zero-mock rule',
        'page.route',
        'route.fulfill',
        'MSW',
        'Cypress stubs/intercepts',
        'fixture JSON',
        'mock modules',
        'hard-coded API data',
        'store/localStorage business-data injection',
        'database seed',
        'direct backend/API writes that bypass the normal UI flow'
    )) -and $section -notmatch '(?i)(?:may|can|allow(?:s|ed|ing)?|permit(?:s|ted|ting)?)\s+(?:use\s+)?(?:mock|stub|intercept|fixture|seed|direct backend/API)'
}

function Test-AutoBootstrap([string]$text) {
    $section = Get-Section $text 'UI-bearing Task Gate'
    return (Has-All $section @(
        'target frontend root',
        'workspace',
        'lockfile',
        'package manager',
        'automatically install `@playwright/test` as a development dependency and Chromium only in that target project',
        'Never install globally',
        'overwrite existing configuration',
        'upgrade unrelated dependencies',
        'bootstrap failure',
        '`BLOCKED`'
    ))
}

function Test-BusinessClosure([string]$text) {
    $section = Get-Section $text 'UI-bearing Task Gate'
    return (Has-All $section @(
        'business-flow',
        'real core API',
        'Mocked Core API: false',
        'real persistence or permission result',
        'cleanup of test-created data'
    ))
}

function Test-RetryAndHandoff([string]$text) {
    $section = Get-Section $text 'UI-bearing Task Gate'
    return (Has-All $section @(
        'diagnostic retries may continue only through attempt 3',
        'third failed attempt is `BLOCKED`',
        'fourth attempt is forbidden',
        'cannot become non-blocking debt',
        'cannot become non-blocking debt, `N/A`, `PASS`, `PASS_WITH_NOTES`, a manual approval, or a waived check'
    )) -and (Has-All $text @(
        'unresolved UI core gap',
        'must not hand off to `fp-final-review`',
        '.fp-execute/e2e/<task-id>/<case-id>/'
    ))
}

function Replace-Required([string]$text, [string]$oldValue, [string]$newValue, [string]$name) {
    if ($text.IndexOf($oldValue, [System.StringComparison]::Ordinal) -lt 0) {
        throw "Mutation baseline failed: $name"
    }
    return $text.Replace($oldValue, $newValue)
}

$skill = Read-Utf8 'skills\fp-execute\SKILL.md'
$validator = Read-Utf8 'scripts\validate-plugin.ps1'

Assert-Condition (Test-SharedContractBinding $skill) 'fp-execute does not load the shared UI/E2E staged contract before UI-bearing work'
Assert-Condition (Test-PlanCaseLinking $skill) 'fp-execute does not link UI/E2E Delivery Contract to Visual Evidence Manifest by Task ID + Case ID'
Assert-Condition (Test-StatePaths $skill) 'fp-execute does not enforce delivery-level UI/E2E state paths'
Assert-Condition (Test-E2EEvidenceAndCoverage $skill) 'fp-execute lacks canonical real E2E evidence and source-derived coverage requirements'
Assert-Condition (Test-ZeroMockRule $skill) 'fp-execute allows or omits a real E2E zero-mock prohibition'
Assert-Condition (Test-AutoBootstrap $skill) 'fp-execute lacks automatic project-local Playwright bootstrap'
Assert-Condition (Test-BusinessClosure $skill) 'fp-execute lacks real business-flow closure requirements'
Assert-Condition (Test-RetryAndHandoff $skill) 'fp-execute lacks bounded UI/E2E retries or blocks final handoff insufficiently'
Assert-Condition ($validator.Contains('test-execute-ui-e2e-contract.ps1')) 'global validator does not invoke the focused direct-execution UI/E2E contract'

if (Test-StatePaths $skill) {
    $skipMutation = Replace-Required $skill 'Required E2E cannot be `SKIPPED` or manual-approved' 'Required E2E may be `SKIPPED` or manual-approved' 'required E2E skip rule'
    Assert-Condition (-not (Test-StatePaths $skipMutation)) 'mutation survived: fp-execute may skip required E2E'
}

if (Test-ZeroMockRule $skill) {
    $mockMutation = Replace-Required $skill 'absolute zero-mock rule' 'mock fallback is allowed' 'zero-mock rule'
    Assert-Condition (-not (Test-ZeroMockRule $mockMutation)) 'mutation survived: fp-execute allows mock E2E data'
}

if (Test-AutoBootstrap $skill) {
    $globalInstallMutation = Replace-Required $skill 'Never install globally' 'Install globally when convenient' 'project-local bootstrap rule'
    Assert-Condition (-not (Test-AutoBootstrap $globalInstallMutation)) 'mutation survived: fp-execute allows a global Playwright install'
}

if ($failures.Count -gt 0) {
    throw "Direct execution UI/E2E contract validation failed:`n- $($failures -join "`n- ")"
}

Write-Output 'Direct execution UI/E2E contract validation passed.'
