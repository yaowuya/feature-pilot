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

function Assert-Anchors([string]$text, [string[]]$anchors, [string]$surface) {
    foreach ($anchor in $anchors) {
        Assert-Condition (
            $text.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
        ) "$surface lost UI/E2E contract anchor: $anchor"
    }
}

function Test-ExactLine([string]$text, [string]$line) {
    $normalized = $text -replace "`r`n", "`n"
    $pattern = ('(?m)^{0}$' -f [regex]::Escape($line))
    return [regex]::Matches($normalized, $pattern).Count -eq 1
}

function Test-ExactSentence([string]$text, [string]$sentence) {
    return [regex]::Matches($text, [regex]::Escape($sentence)).Count -eq 1
}

function Test-ExactLines([string]$text, [string[]]$lines) {
    foreach ($line in $lines) {
        if (-not (Test-ExactLine $text $line)) {
            return $false
        }
    }
    return $true
}

function Test-ExactOrderedSecondLevelHeadings([string]$text, [string[]]$headings) {
    $normalized = $text -replace "`r`n", "`n"
    $previousPosition = -1
    foreach ($heading in $headings) {
        $pattern = ('(?m)^## {0}$' -f [regex]::Escape($heading))
        $matches = [regex]::Matches($normalized, $pattern)
        if ($matches.Count -ne 1 -or $matches[0].Index -le $previousPosition) {
            return $false
        }
        $previousPosition = $matches[0].Index
    }
    return $true
}

function Test-StateMachineContract(
    [string]$text,
    [string]$stateMachineLine,
    [string]$requiredE2ERule
) {
    return (Test-ExactLine $text $stateMachineLine) -and
        (Test-ExactSentence $text $requiredE2ERule)
}

function Test-ZeroMockContract(
    [string]$text,
    [string]$zeroMockRule,
    [string[]]$forbiddenTerms
) {
    if (-not (Test-ExactLine $text $zeroMockRule)) {
        return $false
    }
    foreach ($term in $forbiddenTerms) {
        if ($text.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            return $false
        }
    }
    return $true
}

function Test-ArchiveNoWaiverContract(
    [string]$text,
    [string]$blockerRule,
    [string]$noWaiverRule
) {
    return (Test-ExactSentence $text $blockerRule) -and
        (Test-ExactSentence $text $noWaiverRule)
}

function Replace-Required(
    [string]$text,
    [string]$oldValue,
    [string]$newValue,
    [string]$mutationName
) {
    if ($text.IndexOf($oldValue, [System.StringComparison]::Ordinal) -lt 0) {
        throw "Invalid mutation fixture; production text was not hit: $mutationName"
    }
    return [regex]::Replace($text, [regex]::Escape($oldValue), $newValue)
}

$contract = Read-Utf8 'skills\_shared\ui-e2e-contract.md'
$validator = Read-Utf8 'scripts\validate-plugin.ps1'

$requiredHeadings = @(
    'Applicability and UI Delivery Level',
    'Required State Machine',
    'Case Manifest and E2E Evidence',
    'Real Frontend E2E: No Mock Data or Requests',
    'Coverage Matrix',
    'Automatic Playwright Bootstrap',
    'Retry, Blocking, Final Review, and Archive'
)
$canonicalStateMachineLine = '`SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> INTERACTION_READY -> FRONTEND_E2E_PASS -> FINAL_REVIEW -> ARCHIVE`'
$canonicalRequiredE2ERule = 'Required E2E cannot be `SKIPPED` or manual-approved; an unmet requirement is `BLOCKED`.'
$canonicalZeroMockRule = 'Real E2E has an absolute zero-mock rule. It must not use `page.route`, `route.fulfill`, MSW, Cypress stubs/intercepts, fixture JSON, mock modules, hard-coded API data, frontend store/localStorage business-data injection, database seed, or direct backend/API writes that bypass the normal UI flow.'
$canonicalArchiveBlockerRule = 'Core visual/E2E gaps and any mock violation remain `BLOCKED` through 3 attempts.'
$canonicalArchiveNoWaiverRule = '`FINAL_REVIEW` and `ARCHIVE` cannot waive these blockers.'
$canonicalCoverageLines = @(
    'The canonical coverage-matrix relative path is `.fp-execute/e2e/<task-id>/<case-id>/coverage-matrix.md`.',
    'One coverage matrix covers exactly one `<task-id>/<case-id>` pair.',
    'Coverage entry status is exactly `covered | N/A | BLOCKED`.',
    'A `BLOCKED` coverage entry means required evidence is unresolved; the Gate/Task lifecycle remains `BLOCKED` until it is resolved.'
)
$deliveryTransitionTableLines = @(
    '| UI Delivery Level | Allowed lifecycle path | Transition requirement |',
    '| --- | --- | --- |',
    '| `static-only` | `SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> FINAL_REVIEW -> ARCHIVE` | After `VISUAL_REVIEW_PASS`, record a valid evidence-backed `E2E Applicability: N/A`; do not enter `INTERACTION_READY` or `FRONTEND_E2E_PASS`. |',
    '| `interactive` | `SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> INTERACTION_READY -> FRONTEND_E2E_PASS -> FINAL_REVIEW -> ARCHIVE` | Required real browser front-end E2E; `INTERACTION_READY` and `FRONTEND_E2E_PASS` are mandatory. |',
    '| `business-flow` | `SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> INTERACTION_READY -> FRONTEND_E2E_PASS -> FINAL_REVIEW -> ARCHIVE` | Required real browser front-end E2E plus real core API, `Mocked Core API: false`, real persistence/permission result, and cleanup. |'
)
$zeroMockForbiddenTerms = @(
    'page.route',
    'route.fulfill',
    'MSW',
    'Cypress stubs/intercepts',
    'fixture JSON',
    'mock modules',
    'hard-coded API data',
    'localStorage',
    'database seed',
    'direct backend/API writes that bypass the normal UI flow'
)

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

Assert-Condition (
    (Test-ExactOrderedSecondLevelHeadings $contract $requiredHeadings)
) 'shared UI/E2E contract is missing, duplicating, or reordering an exact required ## heading'
Assert-Condition (
    (Test-StateMachineContract $contract $canonicalStateMachineLine $canonicalRequiredE2ERule)
) 'shared UI/E2E contract does not preserve the exact state machine and required-E2E no-skip rule'
Assert-Condition (
    (Test-ExactLines $contract $deliveryTransitionTableLines)
) 'shared UI/E2E contract is missing the exact delivery-level transition table'
Assert-Condition (
    (Test-ZeroMockContract $contract $canonicalZeroMockRule $zeroMockForbiddenTerms)
) 'shared UI/E2E contract does not preserve the absolute zero-mock rule'
Assert-Condition (
    (Test-ExactLines $contract $canonicalCoverageLines)
) 'shared UI/E2E contract does not preserve canonical coverage-matrix ownership and status semantics'
Assert-Condition (
    $contract -cnotmatch '(?<![A-Za-z])blocked(?![A-Za-z])'
) 'shared UI/E2E contract still uses ambiguous lowercase blocked'
Assert-Condition (
    (Test-ArchiveNoWaiverContract $contract $canonicalArchiveBlockerRule $canonicalArchiveNoWaiverRule)
) 'shared UI/E2E contract does not preserve the archive no-waiver blocker rule'
Assert-Condition (
    $validator.IndexOf('test-ui-e2e-contract.ps1', [System.StringComparison]::OrdinalIgnoreCase) -ge 0
) 'global validator does not invoke the focused UI/E2E contract'

Require-MutationBaseline (
    Test-ExactOrderedSecondLevelHeadings $contract $requiredHeadings
) 'exact ordered UI/E2E headings'
$mutatedHeading = Replace-Required $contract '## Coverage Matrix' 'Coverage Matrix' 'heading becomes ordinary text'
Assert-Condition (
    -not (Test-ExactOrderedSecondLevelHeadings $mutatedHeading $requiredHeadings)
) 'mutation survived: a required ## heading may become ordinary text'

Require-MutationBaseline (
    Test-StateMachineContract $contract $canonicalStateMachineLine $canonicalRequiredE2ERule
) 'state machine and required-E2E no-skip rule'
$mutatedStateMachine = Replace-Required $contract $canonicalStateMachineLine '`SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> FRONTEND_E2E_PASS -> INTERACTION_READY -> FINAL_REVIEW -> ARCHIVE`' 'state order is reversed'
Assert-Condition (
    -not (Test-StateMachineContract $mutatedStateMachine $canonicalStateMachineLine $canonicalRequiredE2ERule)
) 'mutation survived: state machine may reorder interaction and frontend E2E'
$mutatedRequiredE2E = Replace-Required $contract $canonicalRequiredE2ERule 'Required E2E may be `SKIPPED` with a manual waiver.' 'required E2E is skipped or manually waived'
Assert-Condition (
    -not (Test-StateMachineContract $mutatedRequiredE2E $canonicalStateMachineLine $canonicalRequiredE2ERule)
) 'mutation survived: required E2E may be SKIPPED or manually waived'

Require-MutationBaseline (
    Test-ZeroMockContract $contract $canonicalZeroMockRule $zeroMockForbiddenTerms
) 'absolute zero-mock rule'
$mutatedZeroMock = Replace-Required $contract $canonicalZeroMockRule 'Real E2E may use mocks when convenient.' 'zero-mock rule permits mocks'
Assert-Condition (
    -not (Test-ZeroMockContract $mutatedZeroMock $canonicalZeroMockRule $zeroMockForbiddenTerms)
) 'mutation survived: zero-mock rule may permit mocks'

Require-MutationBaseline (
    Test-ArchiveNoWaiverContract $contract $canonicalArchiveBlockerRule $canonicalArchiveNoWaiverRule
) 'archive no-waiver blocker rule'
$mutatedArchiveWaiver = Replace-Required $contract $canonicalArchiveNoWaiverRule '`FINAL_REVIEW` and `ARCHIVE` may waive these blockers.' 'archive waives blockers'
Assert-Condition (
    -not (Test-ArchiveNoWaiverContract $mutatedArchiveWaiver $canonicalArchiveBlockerRule $canonicalArchiveNoWaiverRule)
) 'mutation survived: final review or archive may waive blockers'

if ($failures.Count -gt 0) {
    throw "UI/E2E contract validation failed:`n- $($failures -join "`n- ")"
}

Write-Output 'UI/E2E contract validation passed.'
