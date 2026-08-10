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

function Remove-FencedCode([string]$text) {
    $insideFence = $false
    $keptLines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in ($text -split "`r?`n")) {
        if ($line -match '^\s*(?:`{3,}|~{3,})') {
            $insideFence = -not $insideFence
            continue
        }
        if (-not $insideFence) {
            $keptLines.Add($line)
        }
    }
    return [string]::Join("`n", $keptLines.ToArray())
}

function Get-NonFencedMarkdownLines([string]$text) {
    return @((Remove-FencedCode $text) -split "`n")
}

function Test-DocumentTitleSchema([string]$text, [string]$documentTitle) {
    $h1Lines = @(
        Get-NonFencedMarkdownLines $text |
            Where-Object { $_ -match '^#(?!#)\s+' }
    )
    return $h1Lines.Count -eq 1 -and $h1Lines[0] -ceq $documentTitle
}

function Get-MarkdownSecondLevelSection([string]$text, [string]$heading) {
    $normalized = Remove-FencedCode $text
    $pattern = ('(?ms)^## {0}$\n(?<body>.*?)(?=^## |\z)' -f [regex]::Escape($heading))
    $matches = [regex]::Matches($normalized, $pattern)
    if ($matches.Count -ne 1) {
        return ''
    }
    return $matches[0].Groups['body'].Value
}

function Test-ExactOrderedSecondLevelHeadings([string]$text, [string[]]$headings) {
    $actualHeadings = @(
        Get-NonFencedMarkdownLines $text |
            Where-Object { $_ -match '^##(?!#)\s+' }
    )
    if ($actualHeadings.Count -ne $headings.Count) {
        return $false
    }
    for ($index = 0; $index -lt $headings.Count; $index++) {
        if ($actualHeadings[$index] -cne "## $($headings[$index])") {
            return $false
        }
    }
    return $true
}

function Test-LineHasPermissiveGrant([string]$line) {
    $affirmativeLine = [regex]::Replace(
        $line,
        '(?i)\b(?:may not|cannot|can''t|must not|do not|does not|never)\b[^.!?\r\n]{0,160}',
        ' NEGATED_CLAUSE '
    )
    return $affirmativeLine -match '(?i)\b(?:may|can|allow(?:s|ed|ing)?|permit(?:s|ted|ting)?|waiv(?:e|es|ed|ing))\b'
}

function Get-EffectiveSpecificationSentences([string]$section) {
    $sentences = [System.Collections.Generic.List[string]]::new()
    foreach ($line in ((Remove-FencedCode $section) -split "`n")) {
        $plainLine = [regex]::Replace($line, '[`*_>#]', '')
        foreach ($sentence in [regex]::Split($plainLine, '(?<=[.!?])\s+')) {
            if ($sentence.Trim()) {
                $sentences.Add($sentence.Trim())
            }
        }
    }
    return $sentences.ToArray()
}

function Test-SectionHasNoPermissiveGrant([string]$section, [string[]]$forbiddenTerms) {
    foreach ($plainLine in (Get-EffectiveSpecificationSentences $section)) {
        $hasForbiddenTerm = $false
        foreach ($term in $forbiddenTerms) {
            if ($plainLine.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $hasForbiddenTerm = $true
                break
            }
        }
        if ($hasForbiddenTerm -and (Test-LineHasPermissiveGrant $plainLine)) {
            return $false
        }
    }
    return $true
}

function Test-SectionHasNoArchiveWaiverGrant([string]$section) {
    foreach ($plainLine in (Get-EffectiveSpecificationSentences $section)) {
        $hasLifecycleEnd = $plainLine -match '(?i)\b(?:FINAL_REVIEW|ARCHIVE)\b'
        $hasBlocker = $plainLine -match '(?i)\bblockers?\b'
        if ($hasLifecycleEnd -and $hasBlocker -and (Test-LineHasPermissiveGrant $plainLine)) {
            return $false
        }
    }
    return $true
}

function Test-StateMachineContract(
    [string]$section,
    [string]$stateMachineLine,
    [string]$requiredE2ERule
) {
    return (Test-ExactLine $section $stateMachineLine) -and
        (Test-ExactSentence $section $requiredE2ERule)
}

function Test-ZeroMockContract(
    [string]$section,
    [string]$zeroMockRule,
    [string[]]$forbiddenTerms
) {
    if (-not (Test-ExactLine $section $zeroMockRule)) {
        return $false
    }
    foreach ($term in $forbiddenTerms) {
        if ($section.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            return $false
        }
    }
    return Test-SectionHasNoPermissiveGrant $section $forbiddenTerms
}

function Test-RequiredE2EExceptionGuard(
    [string]$section,
    [string]$requiredE2ERule,
    [string[]]$contradictionTerms
) {
    return (Test-ExactSentence $section $requiredE2ERule) -and
        (Test-SectionHasNoPermissiveGrant $section $contradictionTerms)
}

function Test-RetryBlockingContract(
    [string]$section,
    [string[]]$retryLines,
    [string[]]$contradictionTerms
) {
    return (Test-ExactLines $section $retryLines) -and
        (Test-SectionHasNoPermissiveGrant $section $contradictionTerms)
}

function Test-ArchiveNoWaiverContract(
    [string]$section,
    [string]$blockerRule,
    [string]$noWaiverRule
) {
    return (Test-ExactSentence $section $blockerRule) -and
        (Test-ExactSentence $section $noWaiverRule) -and
        (Test-SectionHasNoArchiveWaiverGrant $section)
}

function Test-ValidatorRegistration([string]$text, [string[]]$registrationLines) {
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $text,
        [ref]$tokens,
        [ref]$parseErrors
    )
    if ($parseErrors.Count -ne 0) {
        return $false
    }

    $expectedTypes = @(
        'AssignmentStatementAst',
        'PipelineAst',
        'PipelineAst',
        'PipelineAst'
    )
    $statements = @($ast.EndBlock.Statements)
    for ($start = 0; $start -le ($statements.Count - $registrationLines.Count); $start++) {
        $matches = $true
        for ($offset = 0; $offset -lt $registrationLines.Count; $offset++) {
            $statement = $statements[$start + $offset]
            if ($statement.GetType().Name -cne $expectedTypes[$offset] -or
                $statement.Extent.Text.Trim() -cne $registrationLines[$offset]) {
                $matches = $false
                break
            }
        }
        if ($matches) {
            return $true
        }
    }
    return $false
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

function Insert-AfterRequired(
    [string]$text,
    [string]$marker,
    [string]$payload,
    [string]$mutationName
) {
    $index = $text.IndexOf($marker, [System.StringComparison]::Ordinal)
    if ($index -lt 0) {
        throw "Invalid mutation fixture; production text was not hit: $mutationName"
    }
    $insertAt = $index + $marker.Length
    return $text.Substring(0, $insertAt) + $payload + $text.Substring($insertAt)
}

$contract = Read-Utf8 'skills\_shared\ui-e2e-contract.md'
$validator = Read-Utf8 'scripts\validate-plugin.ps1'

$documentTitle = '# FeaturePilot UI/E2E Staged Contract'
$requiredHeadings = @(
    'Applicability and UI Delivery Level',
    'Required State Machine',
    'Case Manifest and E2E Evidence',
    'Real Frontend E2E: No Mock Data or Requests',
    'Coverage Matrix',
    'Automatic Playwright Bootstrap',
    'Retry, Blocking, Final Review, and Archive'
)
$canonicalExecutionBinding = 'This contract is mandatory for UI-bearing work in `fp-execute` and `fp-execute-sdd`.'
$canonicalStateMachineLine = '`SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> INTERACTION_READY -> FRONTEND_E2E_PASS -> FINAL_REVIEW -> ARCHIVE`'
$canonicalRequiredE2ERule = 'Required E2E cannot be `SKIPPED` or manual-approved; an unmet requirement is `BLOCKED`.'
$canonicalZeroMockRule = 'Real E2E has an absolute zero-mock rule. It must not use `page.route`, `route.fulfill`, MSW, Cypress stubs/intercepts, fixture JSON, mock modules, hard-coded API data, frontend store/localStorage business-data injection, database seed, or direct backend/API writes that bypass the normal UI flow.'
$canonicalArchiveBlockerRule = 'Core visual/E2E gaps and any mock violation remain `BLOCKED` through 3 attempts.'
$canonicalArchiveNoWaiverRule = '`FINAL_REVIEW` and `ARCHIVE` cannot waive these blockers.'
$canonicalEvidenceRecordLines = @(
    'For every E2E execution, record:',
    '- `Executed command`',
    '- `Environment identity`',
    '- `Destination`',
    '- `Start` timestamp',
    '- `End` timestamp',
    '- `Attempts`',
    '- `Test IDs`',
    '- `Artifacts`',
    '- `Coverage matrix reference`: `.fp-execute/e2e/<task-id>/<case-id>/coverage-matrix.md`',
    '- `Cleanup`'
)
$canonicalRetryLines = @(
    'After a failure, diagnostic retries may continue only through attempt 3.',
    'A third failed attempt is `BLOCKED`; a fourth attempt is forbidden.',
    'A core UI/E2E gap or any mock violation cannot become review debt, `N/A`, `PASS`, `PASS_WITH_NOTES`, a manual approval, or a waived check.'
)
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
$requiredE2EContradictionTerms = @(
    'SKIPPED',
    'manual waiver',
    'manual approval',
    'PASS_WITH_NOTES'
)
$canonicalValidatorRegistrationLines = @(
    '$uiE2EContractValidator = Join-Path $root ''scripts\test-ui-e2e-contract.ps1''',
    'Assert-Condition (Test-Path $uiE2EContractValidator) ''focused UI/E2E contract validator is missing''',
    '& powershell -NoProfile -ExecutionPolicy Bypass -File $uiE2EContractValidator',
    'Assert-Condition ($LASTEXITCODE -eq 0) ''focused UI/E2E contract validator failed'''
)

$applicabilitySection = Get-MarkdownSecondLevelSection $contract 'Applicability and UI Delivery Level'
$stateMachineSection = Get-MarkdownSecondLevelSection $contract 'Required State Machine'
$evidenceSection = Get-MarkdownSecondLevelSection $contract 'Case Manifest and E2E Evidence'
$zeroMockSection = Get-MarkdownSecondLevelSection $contract 'Real Frontend E2E: No Mock Data or Requests'
$coverageSection = Get-MarkdownSecondLevelSection $contract 'Coverage Matrix'
$retrySection = Get-MarkdownSecondLevelSection $contract 'Retry, Blocking, Final Review, and Archive'

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
    Test-DocumentTitleSchema $contract $documentTitle
) 'shared UI/E2E contract must have exactly one non-fenced H1 with its exact top-level title'
Assert-Condition (
    Test-ExactOrderedSecondLevelHeadings $contract $requiredHeadings
) 'shared UI/E2E contract is missing, duplicating, or reordering an exact required ## heading'
Assert-Condition (
    Test-ExactSentence $applicabilitySection $canonicalExecutionBinding
) 'shared UI/E2E contract does not bind applicability to fp-execute and fp-execute-sdd'
Assert-Condition (
    Test-StateMachineContract $stateMachineSection $canonicalStateMachineLine $canonicalRequiredE2ERule
) 'shared UI/E2E contract does not preserve the exact state machine and required-E2E no-skip rule'
Assert-Condition (
    Test-ExactLines $applicabilitySection $deliveryTransitionTableLines
) 'shared UI/E2E contract is missing the exact delivery-level transition table'
Assert-Condition (
    Test-ExactLines $evidenceSection $canonicalEvidenceRecordLines
) 'shared UI/E2E contract does not record the complete E2E evidence fields'
Assert-Condition (
    Test-ZeroMockContract $zeroMockSection $canonicalZeroMockRule $zeroMockForbiddenTerms
) 'shared UI/E2E contract does not preserve the absolute zero-mock rule'
Assert-Condition (
    Test-RequiredE2EExceptionGuard $stateMachineSection $canonicalRequiredE2ERule $requiredE2EContradictionTerms
) 'shared UI/E2E contract permits a required-E2E skip, manual waiver, or PASS_WITH_NOTES exception'
Assert-Condition (
    Test-ExactLines $coverageSection $canonicalCoverageLines
) 'shared UI/E2E contract does not preserve canonical coverage-matrix ownership and status semantics'
Assert-Condition (
    $contract -cnotmatch '(?<![A-Za-z])blocked(?![A-Za-z])'
) 'shared UI/E2E contract still uses ambiguous lowercase blocked'
Assert-Condition (
    Test-RetryBlockingContract $retrySection $canonicalRetryLines $requiredE2EContradictionTerms
) 'shared UI/E2E contract does not preserve the diagnostic retry ceiling and blocker disposition'
Assert-Condition (
    Test-ArchiveNoWaiverContract $retrySection $canonicalArchiveBlockerRule $canonicalArchiveNoWaiverRule
) 'shared UI/E2E contract does not preserve the archive no-waiver blocker rule'
Assert-Condition (
    Test-ValidatorRegistration $validator $canonicalValidatorRegistrationLines
) 'global validator does not contain the complete focused UI/E2E contract invocation chain'

Require-MutationBaseline (
    Test-DocumentTitleSchema $contract $documentTitle
) 'exact top-level title schema'
$mutatedTitle = Replace-Required $contract $documentTitle 'FeaturePilot UI/E2E Staged Contract' 'top-level title becomes ordinary text'
Assert-Condition (
    -not (Test-DocumentTitleSchema $mutatedTitle $documentTitle)
) 'mutation survived: the top-level title may become ordinary text'
$mutatedExtraH1 = Insert-AfterRequired $contract $documentTitle ([Environment]::NewLine + '# Extra UI/E2E Title') 'extra top-level title is added'
Assert-Condition (
    -not (Test-DocumentTitleSchema $mutatedExtraH1 $documentTitle)
) 'mutation survived: the UI/E2E contract may have an extra H1'

Require-MutationBaseline (
    Test-ExactOrderedSecondLevelHeadings $contract $requiredHeadings
) 'exact ordered UI/E2E headings'
$mutatedHeading = Replace-Required $contract '## Coverage Matrix' 'Coverage Matrix' 'heading becomes ordinary text'
Assert-Condition (
    -not (Test-ExactOrderedSecondLevelHeadings $mutatedHeading $requiredHeadings)
) 'mutation survived: a required ## heading may become ordinary text'
$mutatedExtraH2 = Insert-AfterRequired $contract '## Coverage Matrix' ([Environment]::NewLine + '## Extra UI/E2E Section') 'extra second-level title is added'
Assert-Condition (
    -not (Test-ExactOrderedSecondLevelHeadings $mutatedExtraH2 $requiredHeadings)
) 'mutation survived: the UI/E2E contract may have an extra H2'
$fencedPseudoHeadings = $contract + [Environment]::NewLine + '```markdown' + [Environment]::NewLine + '# Pseudo Title' + [Environment]::NewLine + '## Pseudo Section' + [Environment]::NewLine + '```'
Assert-Condition (
    Test-DocumentTitleSchema $fencedPseudoHeadings $documentTitle
) 'mutation fixture is invalid: fenced pseudo H1 should not alter the title schema'
Assert-Condition (
    Test-ExactOrderedSecondLevelHeadings $fencedPseudoHeadings $requiredHeadings
) 'mutation fixture is invalid: fenced pseudo H2 should not alter the second-level heading schema'

Require-MutationBaseline (
    Test-StateMachineContract $stateMachineSection $canonicalStateMachineLine $canonicalRequiredE2ERule
) 'state machine and required-E2E no-skip rule'
$mutatedStateMachine = Replace-Required $contract $canonicalStateMachineLine '`SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> FRONTEND_E2E_PASS -> INTERACTION_READY -> FINAL_REVIEW -> ARCHIVE`' 'state order is reversed'
$mutatedStateMachineSection = Get-MarkdownSecondLevelSection $mutatedStateMachine 'Required State Machine'
Assert-Condition (
    -not (Test-StateMachineContract $mutatedStateMachineSection $canonicalStateMachineLine $canonicalRequiredE2ERule)
) 'mutation survived: state machine may reorder interaction and frontend E2E'
$mutatedRequiredE2E = Replace-Required $contract $canonicalRequiredE2ERule 'Required E2E may be `SKIPPED` with a manual waiver.' 'required E2E is skipped or manually waived'
$mutatedRequiredE2ESection = Get-MarkdownSecondLevelSection $mutatedRequiredE2E 'Required State Machine'
Assert-Condition (
    -not (Test-StateMachineContract $mutatedRequiredE2ESection $canonicalStateMachineLine $canonicalRequiredE2ERule)
) 'mutation survived: required E2E may be SKIPPED or manually waived'

Require-MutationBaseline (
    Test-RequiredE2EExceptionGuard $stateMachineSection $canonicalRequiredE2ERule $requiredE2EContradictionTerms
) 'required-E2E exception guard'
$mutatedRequiredE2EException = Insert-AfterRequired $contract $canonicalRequiredE2ERule ([Environment]::NewLine + 'Exception: Required E2E may be `SKIPPED` with a manual waiver and `PASS_WITH_NOTES`.') 'required E2E exception permits skip'
$mutatedRequiredE2EExceptionSection = Get-MarkdownSecondLevelSection $mutatedRequiredE2EException 'Required State Machine'
Assert-Condition (
    -not (Test-RequiredE2EExceptionGuard $mutatedRequiredE2EExceptionSection $canonicalRequiredE2ERule $requiredE2EContradictionTerms)
) 'mutation survived: a required-E2E exception may allow SKIPPED, manual waiver, or PASS_WITH_NOTES'
$mutatedRequiredE2EQuote = Insert-AfterRequired $contract $canonicalRequiredE2ERule ([Environment]::NewLine + '> A required E2E may be `SKIPPED` with a manual approval and `PASS_WITH_NOTES`.') 'required E2E quote permits skip'
$mutatedRequiredE2EQuoteSection = Get-MarkdownSecondLevelSection $mutatedRequiredE2EQuote 'Required State Machine'
Assert-Condition (
    -not (Test-RequiredE2EExceptionGuard $mutatedRequiredE2EQuoteSection $canonicalRequiredE2ERule $requiredE2EContradictionTerms)
) 'mutation survived: a required-E2E quote may allow SKIPPED, manual approval, or PASS_WITH_NOTES'
$fencedRequiredE2EGrant = Insert-AfterRequired $contract $canonicalRequiredE2ERule ([Environment]::NewLine + '```text' + [Environment]::NewLine + '> A required E2E may be `SKIPPED` with a manual approval and `PASS_WITH_NOTES`.' + [Environment]::NewLine + '```') 'fenced required-E2E grant is ignored'
$fencedRequiredE2EGrantSection = Get-MarkdownSecondLevelSection $fencedRequiredE2EGrant 'Required State Machine'
Assert-Condition (
    Test-RequiredE2EExceptionGuard $fencedRequiredE2EGrantSection $canonicalRequiredE2ERule $requiredE2EContradictionTerms
) 'mutation fixture is invalid: fenced required-E2E grant should not alter the contract'

Require-MutationBaseline (
    Test-ZeroMockContract $zeroMockSection $canonicalZeroMockRule $zeroMockForbiddenTerms
) 'absolute zero-mock rule'
$mutatedZeroMock = Replace-Required $contract $canonicalZeroMockRule 'Real E2E may use mocks when convenient.' 'zero-mock rule permits mocks'
$mutatedZeroMockSection = Get-MarkdownSecondLevelSection $mutatedZeroMock 'Real Frontend E2E: No Mock Data or Requests'
Assert-Condition (
    -not (Test-ZeroMockContract $mutatedZeroMockSection $canonicalZeroMockRule $zeroMockForbiddenTerms)
) 'mutation survived: zero-mock rule may permit mocks'
$mutatedZeroMockException = Insert-AfterRequired $contract $canonicalZeroMockRule ([Environment]::NewLine + 'Exception: Real E2E may use `page.route` and mocks.') 'zero-mock exception permits route and mocks'
$mutatedZeroMockExceptionSection = Get-MarkdownSecondLevelSection $mutatedZeroMockException 'Real Frontend E2E: No Mock Data or Requests'
Assert-Condition (
    -not (Test-ZeroMockContract $mutatedZeroMockExceptionSection $canonicalZeroMockRule $zeroMockForbiddenTerms)
) 'mutation survived: a zero-mock exception may allow page.route or mocks'
$mutatedZeroMockNote = Insert-AfterRequired $contract $canonicalZeroMockRule ([Environment]::NewLine + 'Note: Real E2E may use `page.route` and mocks.') 'zero-mock note permits route and mocks'
$mutatedZeroMockNoteSection = Get-MarkdownSecondLevelSection $mutatedZeroMockNote 'Real Frontend E2E: No Mock Data or Requests'
Assert-Condition (
    -not (Test-ZeroMockContract $mutatedZeroMockNoteSection $canonicalZeroMockRule $zeroMockForbiddenTerms)
) 'mutation survived: a zero-mock note may allow page.route or mocks'
$fencedZeroMockGrant = Insert-AfterRequired $contract $canonicalZeroMockRule ([Environment]::NewLine + '```text' + [Environment]::NewLine + 'Note: Real E2E may use `page.route` and mocks.' + [Environment]::NewLine + '```') 'fenced zero-mock grant is ignored'
$fencedZeroMockGrantSection = Get-MarkdownSecondLevelSection $fencedZeroMockGrant 'Real Frontend E2E: No Mock Data or Requests'
Assert-Condition (
    Test-ZeroMockContract $fencedZeroMockGrantSection $canonicalZeroMockRule $zeroMockForbiddenTerms
) 'mutation fixture is invalid: fenced zero-mock grant should not alter the contract'

Require-MutationBaseline (
    Test-ArchiveNoWaiverContract $retrySection $canonicalArchiveBlockerRule $canonicalArchiveNoWaiverRule
) 'archive no-waiver blocker rule'
$mutatedArchiveWaiver = Replace-Required $contract $canonicalArchiveNoWaiverRule '`FINAL_REVIEW` and `ARCHIVE` may waive these blockers.' 'archive waives blockers'
$mutatedArchiveWaiverSection = Get-MarkdownSecondLevelSection $mutatedArchiveWaiver 'Retry, Blocking, Final Review, and Archive'
Assert-Condition (
    -not (Test-ArchiveNoWaiverContract $mutatedArchiveWaiverSection $canonicalArchiveBlockerRule $canonicalArchiveNoWaiverRule)
) 'mutation survived: final review or archive may waive blockers'
$mutatedArchiveHeading = Insert-AfterRequired $contract $canonicalArchiveNoWaiverRule ([Environment]::NewLine + '### Waiver' + [Environment]::NewLine + 'FINAL_REVIEW and ARCHIVE may waive blockers.') 'archive waiver heading permits blockers'
$mutatedArchiveHeadingSection = Get-MarkdownSecondLevelSection $mutatedArchiveHeading 'Retry, Blocking, Final Review, and Archive'
Assert-Condition (
    -not (Test-ArchiveNoWaiverContract $mutatedArchiveHeadingSection $canonicalArchiveBlockerRule $canonicalArchiveNoWaiverRule)
) 'mutation survived: an archive waiver heading may allow blockers'
$fencedArchiveWaiver = Insert-AfterRequired $contract $canonicalArchiveNoWaiverRule ([Environment]::NewLine + '```text' + [Environment]::NewLine + '### Waiver' + [Environment]::NewLine + 'FINAL_REVIEW and ARCHIVE may waive blockers.' + [Environment]::NewLine + '```') 'fenced archive waiver is ignored'
$fencedArchiveWaiverSection = Get-MarkdownSecondLevelSection $fencedArchiveWaiver 'Retry, Blocking, Final Review, and Archive'
Assert-Condition (
    Test-ArchiveNoWaiverContract $fencedArchiveWaiverSection $canonicalArchiveBlockerRule $canonicalArchiveNoWaiverRule
) 'mutation fixture is invalid: fenced archive waiver should not alter the contract'

Require-MutationBaseline (
    Test-ValidatorRegistration $validator $canonicalValidatorRegistrationLines
) 'complete focused UI/E2E validator registration'
$mutatedValidator = Replace-Required $validator $canonicalValidatorRegistrationLines[2] '# focused UI/E2E invocation deleted' 'focused UI/E2E invocation is deleted'
Assert-Condition (
    -not (Test-ValidatorRegistration $mutatedValidator $canonicalValidatorRegistrationLines)
) 'mutation survived: global validator may retain a name or variable while omitting the UI/E2E invocation'
$validatorRegistrationStart = $validator.IndexOf($canonicalValidatorRegistrationLines[0], [System.StringComparison]::Ordinal)
if ($validatorRegistrationStart -lt 0) {
    throw 'Invalid mutation fixture; production text was not hit: focused UI/E2E registration start'
}
$validatorLineEndStart = $validatorRegistrationStart + $canonicalValidatorRegistrationLines[0].Length
$validatorNewLine = if (
    $validator.Length -ge ($validatorLineEndStart + 2) -and
    $validator.Substring($validatorLineEndStart, 2) -eq "`r`n"
) { "`r`n" } else { "`n" }
$validatorRegistrationBlock = [string]::Join($validatorNewLine, $canonicalValidatorRegistrationLines)
$mutatedValidatorBlockComment = Replace-Required $validator $validatorRegistrationBlock ('<#' + $validatorNewLine + $validatorRegistrationBlock + $validatorNewLine + '#>') 'focused UI/E2E chain becomes a block comment'
Assert-Condition (
    -not (Test-ValidatorRegistration $mutatedValidatorBlockComment $canonicalValidatorRegistrationLines)
) 'mutation survived: a block comment may impersonate the focused UI/E2E validator chain'
$mutatedValidatorHereString = Replace-Required $validator $validatorRegistrationBlock ("@'" + $validatorNewLine + $validatorRegistrationBlock + $validatorNewLine + "'@") 'focused UI/E2E chain becomes a here-string'
Assert-Condition (
    -not (Test-ValidatorRegistration $mutatedValidatorHereString $canonicalValidatorRegistrationLines)
) 'mutation survived: a here-string may impersonate the focused UI/E2E validator chain'

if ($failures.Count -gt 0) {
    throw "UI/E2E contract validation failed:`n- $($failures -join "`n- ")"
}

Write-Output 'UI/E2E contract validation passed.'
