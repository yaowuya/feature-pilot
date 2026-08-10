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

function Assert-Anchors([string]$text, [string[]]$anchors, [string]$surface) {
    foreach ($anchor in $anchors) {
        Assert-Condition (
            $text.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
        ) "$surface lost UI/E2E contract anchor: $anchor"
    }
}

function Get-HeadingPosition([string]$text, [string]$heading) {
    return $text.IndexOf($heading, [System.StringComparison]::Ordinal)
}

$contract = Read-Utf8 'skills\_shared\ui-e2e-contract.md'

Assert-Anchors $contract @(
    'UI Delivery Level',
    'static-only',
    'interactive',
    'business-flow',
    'SOURCE_READY',
    'STATIC_UI_READY',
    'VISUAL_REVIEW_PASS',
    'INTERACTION_READY',
    'FRONTEND_E2E_PASS',
    'E2E Applicability: REQUIRED | N/A',
    'Mocked Core API: false',
    '@playwright/test',
    'Chromium',
    'coverage-matrix.md',
    'BLOCKED'
) 'shared UI/E2E contract'

$requiredHeadings = @(
    '# FeaturePilot UI/E2E Staged Contract',
    '## Applicability and UI Delivery Level',
    '## Required State Machine',
    '## Case Manifest and E2E Evidence',
    '## Real Frontend E2E: No Mock Data or Requests',
    '## Coverage Matrix',
    '## Automatic Playwright Bootstrap',
    '## Retry, Blocking, Final Review, and Archive'
)

$previousHeadingPosition = -1
foreach ($heading in $requiredHeadings) {
    $headingPosition = Get-HeadingPosition $contract $heading
    Assert-Condition ($headingPosition -ge 0) "shared UI/E2E contract is missing required heading: $heading"
    Assert-Condition ($headingPosition -gt $previousHeadingPosition) "shared UI/E2E contract headings are out of order at: $heading"
    $previousHeadingPosition = $headingPosition
}

Assert-Anchors $contract @(
    'SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> INTERACTION_READY -> FRONTEND_E2E_PASS -> FINAL_REVIEW -> ARCHIVE',
    '.fp-execute/e2e/<task-id>/<case-id>/',
    '.fp-execute/visual/<task-id>/<case-id>/',
    'page.route',
    'route.fulfill',
    'MSW',
    'Cypress stubs/intercepts',
    'fixture JSON',
    'mock modules',
    'hard-coded API data',
    'localStorage',
    'database seed',
    'blocked',
    '3 attempts'
) 'shared UI/E2E contract semantics'

if ($failures.Count -gt 0) {
    throw "UI/E2E contract validation failed:`n- $($failures -join "`n- ")"
}

Write-Output 'UI/E2E contract validation passed.'
