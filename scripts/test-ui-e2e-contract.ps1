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

function Get-EffectiveNormativeText([string]$text) {
    $normalizedLf = $text -replace "`r`n?", "`n"
    $withoutComments = [regex]::Replace($normalizedLf, '(?s)<!--.*?-->', '')
    $fenceCharacter = $null
    $minimumFenceLength = 0
    $keptLines = [System.Collections.Generic.List[string]]::new()

    foreach ($line in ($withoutComments -split "`r?`n")) {
        if ($null -eq $fenceCharacter) {
            $openingFence = [regex]::Match($line, '^ {0,3}(?<fence>`{3,}|~{3,})(?<info>.*)$')
            if ($openingFence.Success) {
                $openingValue = $openingFence.Groups['fence'].Value
                if ($openingValue.StartsWith('`') -and
                    $openingFence.Groups['info'].Value.Contains('`')) {
                    $keptLines.Add($line)
                    continue
                }
                $fenceCharacter = $openingValue.Substring(0, 1)
                $minimumFenceLength = $openingValue.Length
                continue
            }
            $keptLines.Add($line)
            continue
        }

        $closingFence = [regex]::Match($line, '^ {0,3}(?<fence>`{3,}|~{3,})\s*$')
        if ($closingFence.Success) {
            $closingValue = $closingFence.Groups['fence'].Value
            if ($closingValue.Substring(0, 1) -eq $fenceCharacter -and
                $closingValue.Length -ge $minimumFenceLength) {
                $fenceCharacter = $null
                $minimumFenceLength = 0
            }
        }
    }
    return [string]::Join("`n", $keptLines.ToArray())
}

function Get-EffectiveNormativeLines([string]$text) {
    return @((Get-EffectiveNormativeText $text) -split "`n")
}

function Get-NormalizedNormativeLineSequence([string]$text) {
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in (Get-EffectiveNormativeLines $text)) {
        $normalizedLine = [regex]::Replace($line.Trim(), '\s+', ' ')
        if ($normalizedLine) {
            $lines.Add($normalizedLine)
        }
    }
    return $lines.ToArray()
}

function Test-ClosedNormativeLineSequence([string]$text, [string[]]$canonicalLines) {
    $actualLines = @(Get-NormalizedNormativeLineSequence $text)
    if ($actualLines.Count -ne $canonicalLines.Count) {
        return $false
    }
    for ($index = 0; $index -lt $canonicalLines.Count; $index++) {
        $expectedLine = [regex]::Replace($canonicalLines[$index].Trim(), '\s+', ' ')
        if ($actualLines[$index] -cne $expectedLine) {
            return $false
        }
    }
    return $true
}

function Get-EffectiveMarkdownHeadings([string]$text) {
    $headings = [System.Collections.Generic.List[object]]::new()
    $lines = @(Get-EffectiveNormativeLines $text)
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $line = $lines[$index]
        $atxH1 = [regex]::Match($line, '^ {0,3}#(?!#)\s+(?<title>.*?)\s*$')
        if ($atxH1.Success) {
            $headings.Add([pscustomobject]@{ Level = 1; Raw = '# ' + $atxH1.Groups['title'].Value; Syntax = 'ATX' })
            continue
        }
        $atxH2 = [regex]::Match($line, '^ {0,3}##(?!#)\s+(?<title>.*?)\s*$')
        if ($atxH2.Success) {
            $headings.Add([pscustomobject]@{ Level = 2; Raw = '## ' + $atxH2.Groups['title'].Value; Syntax = 'ATX' })
            continue
        }
        if ($line.Trim() -and $index -lt ($lines.Count - 1)) {
            $setextUnderline = $lines[$index + 1]
            if ($setextUnderline -match '^ {0,3}=+\s*$') {
                $headings.Add([pscustomobject]@{ Level = 1; Raw = $line.Trim(); Syntax = 'Setext' })
                $index++
                continue
            }
            if ($setextUnderline -match '^ {0,3}-+\s*$') {
                $headings.Add([pscustomobject]@{ Level = 2; Raw = $line.Trim(); Syntax = 'Setext' })
                $index++
            }
        }
    }
    return $headings.ToArray()
}

function Test-DocumentTitleSchema([string]$text, [string]$documentTitle) {
    $h1Headings = @(Get-EffectiveMarkdownHeadings $text | Where-Object { $_.Level -eq 1 })
    return $h1Headings.Count -eq 1 -and
        $h1Headings[0].Syntax -ceq 'ATX' -and
        $h1Headings[0].Raw -ceq $documentTitle
}

function Get-MarkdownSecondLevelSection([string]$text, [string]$heading) {
    $normalized = Get-EffectiveNormativeText $text
    $pattern = ('(?ms)^## {0}$\n(?<body>.*?)(?=^## |\z)' -f [regex]::Escape($heading))
    $matches = [regex]::Matches($normalized, $pattern)
    if ($matches.Count -ne 1) {
        return ''
    }
    return $matches[0].Groups['body'].Value
}

function Test-ExactOrderedSecondLevelHeadings([string]$text, [string[]]$headings) {
    $actualHeadings = @(Get-EffectiveMarkdownHeadings $text | Where-Object { $_.Level -eq 2 })
    if ($actualHeadings.Count -ne $headings.Count) {
        return $false
    }
    for ($index = 0; $index -lt $headings.Count; $index++) {
        if ($actualHeadings[$index].Syntax -cne 'ATX' -or
            $actualHeadings[$index].Raw -cne "## $($headings[$index])") {
            return $false
        }
    }
    return $true
}

function Test-ClauseHasPermissiveGrant([string]$clause) {
    $modalMatches = [regex]::Matches($clause, '(?i)\b(?:may|can|allow(?:s|ed|ing)?|permit(?:s|ted|ting)?)\b')
    foreach ($modal in $modalMatches) {
        $afterModal = $clause.Substring($modal.Index + $modal.Length)
        if ($afterModal -notmatch '^\s+not\b') {
            return $true
        }
    }
    $waiver = [regex]::Match($clause, '(?i)\bwaiv(?:e|es|ed|ing)\b')
    if (-not $waiver.Success) {
        return $false
    }
    return $clause -notmatch '(?i)\b(?:may not|cannot|can''t|must not|do not|does not|never)\b.*\bwaiv(?:e|es|ed|ing)\b'
}

function Get-EffectiveSpecificationClauses([string]$section) {
    $clauses = [System.Collections.Generic.List[string]]::new()
    foreach ($line in ((Get-EffectiveNormativeText $section) -split "`n")) {
        $plainLine = [regex]::Replace($line, '[`*>#]', '')
        foreach ($sentence in [regex]::Split($plainLine, '(?<=[.!?])\s+')) {
            foreach ($clause in [regex]::Split($sentence, '(?i)(?:\s*,?\s+but\s+|\s*;\s*)')) {
                if ($clause.Trim()) {
                    $clauses.Add($clause.Trim())
                }
            }
        }
    }
    return $clauses.ToArray()
}

function Test-SectionHasNoPermissiveGrant([string]$section, [string[]]$forbiddenTerms) {
    foreach ($plainLine in (Get-EffectiveSpecificationClauses $section)) {
        $hasForbiddenTerm = $false
        foreach ($term in $forbiddenTerms) {
            if ($plainLine.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                $hasForbiddenTerm = $true
                break
            }
        }
        if ($hasForbiddenTerm -and (Test-ClauseHasPermissiveGrant $plainLine)) {
            return $false
        }
    }
    return $true
}

function Test-SectionHasNoArchiveWaiverGrant([string]$section) {
    foreach ($plainLine in (Get-EffectiveSpecificationClauses $section)) {
        $hasLifecycleEnd = $plainLine -match '(?i)\b(?:FINAL_REVIEW|ARCHIVE)\b'
        $hasBlocker = $plainLine -match '(?i)\bblockers?\b'
        $hasCoreGap = $plainLine -match '(?i)\bcore\s+(?:visual|UI)/E2E\s+gaps?\b'
        if ($hasLifecycleEnd -and ($hasBlocker -or $hasCoreGap) -and
            (Test-ClauseHasPermissiveGrant $plainLine)) {
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

function Test-TopLevelStatementTerminatesBeforeRegistration([System.Management.Automation.Language.StatementAst]$statement) {
    if ($statement -is [System.Management.Automation.Language.ExitStatementAst] -or
        $statement -is [System.Management.Automation.Language.ReturnStatementAst] -or
        $statement.Extent.Text.Trim() -match '^(?i)(?:exit|return)(?:\s|$)') {
        return $true
    }
    if ($statement -isnot [System.Management.Automation.Language.IfStatementAst]) {
        return $false
    }

    $ifStatement = [System.Management.Automation.Language.IfStatementAst]$statement
    if ($ifStatement.Clauses.Count -ne 1 -or
        $ifStatement.Clauses[0].Item1.Extent.Text.Trim() -cnotmatch '^\$true$') {
        return $false
    }
    foreach ($bodyStatement in $ifStatement.Clauses[0].Item2.Statements) {
        if ($bodyStatement -is [System.Management.Automation.Language.ExitStatementAst] -or
            $bodyStatement -is [System.Management.Automation.Language.ReturnStatementAst] -or
            $bodyStatement.Extent.Text.Trim() -match '^(?i)(?:exit|return)(?:\s|$)') {
            return $true
        }
    }
    return $false
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
    $tryBlocks = @($ast.EndBlock.Statements | Where-Object { $_ -is [System.Management.Automation.Language.TryStatementAst] })
    if ($tryBlocks.Count -ne 1) { return $false }
    $statements = @($tryBlocks[0].Body.Statements)
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
            for ($preceding = 0; $preceding -lt $start; $preceding++) {
                if (Test-TopLevelStatementTerminatesBeforeRegistration $statements[$preceding]) {
                    return $false
                }
            }
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
    'Browser Capability Gate',
    'Retry, Blocking, Final Review, and Archive'
)
$canonicalExecutionBinding = 'This contract is mandatory for UI-bearing work in `fp-figma`, `fp-execute`, `fp-execute-sdd`, and `fp-final-review`.'
$canonicalStateMachineLine = '`SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> INTERACTION_READY -> FRONTEND_E2E_PASS -> FINAL_REVIEW -> ARCHIVE`'
$canonicalRequiredE2ERule = 'Required E2E cannot be `SKIPPED` or manual-approved; an unmet requirement is `BLOCKED`.'
$canonicalVisualReviewLine = '`VISUAL_REVIEW_PASS` is issued only by a separate, independent, read-only visual-review stage: it may write only its review artifact and must not modify implementation, source-evidence, or lifecycle files; it checks only the existing Visual Evidence Manifest `reference`, `current`, and `diff` artifacts against the real runtime route/state; SDD uses a fresh reviewer.'
$canonicalVisualReviewResultLine = 'The visual-review stage records exactly `VISUAL_REVIEW_PASS`, `CANNOT_VERIFY`, or `FAIL`; only `VISUAL_REVIEW_PASS` can advance. `CANNOT_VERIFY` is `BLOCKED`.'
$canonicalStageRollbackLine = 'On visual `FAIL`, return only to `STATIC_UI_READY`; on interaction or required-E2E `FAIL`, return only to `INTERACTION_READY`. Preserve prior visual-pass evidence only while current source and real runtime state still match it; otherwise run visual review again.'
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
$canonicalNormativeLines = @(
    '# FeaturePilot UI/E2E Staged Contract',
    '## Applicability and UI Delivery Level',
    'Every UI-bearing task declares one `UI Delivery Level` and records why that level applies:',
    'This contract is mandatory for UI-bearing work in `fp-figma`, `fp-execute`, `fp-execute-sdd`, and `fp-final-review`.',
    '- `static-only`: only static presentation is in scope. It needs visual `PASS` / `VISUAL_REVIEW_PASS` evidence and an evidence-backed `E2E Applicability: N/A` reason.',
    '- `interactive`: user interaction is in scope. It requires real browser front-end E2E and `E2E Applicability: REQUIRED`.',
    '- `business-flow`: a user-visible flow crosses a real business boundary. It requires real browser front-end E2E, proof of the real core API, `Mocked Core API: false`, the real persistence or permission result, and cleanup of test-created data.',
    '`E2E Applicability: REQUIRED | N/A` is a case-manifest field. `N/A` is permitted only for a genuinely `static-only` case with its recorded evidence-backed reason; it is never a substitute for an unresolved required E2E case.',
    '### Allowed delivery-level transition table',
    '| UI Delivery Level | Allowed lifecycle path | Transition requirement |',
    '| --- | --- | --- |',
    '| `static-only` | `SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> FINAL_REVIEW -> ARCHIVE` | After `VISUAL_REVIEW_PASS`, record a valid evidence-backed `E2E Applicability: N/A`; do not enter `INTERACTION_READY` or `FRONTEND_E2E_PASS`. |',
    '| `interactive` | `SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> INTERACTION_READY -> FRONTEND_E2E_PASS -> FINAL_REVIEW -> ARCHIVE` | Required real browser front-end E2E; `INTERACTION_READY` and `FRONTEND_E2E_PASS` are mandatory. |',
    '| `business-flow` | `SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> INTERACTION_READY -> FRONTEND_E2E_PASS -> FINAL_REVIEW -> ARCHIVE` | Required real browser front-end E2E plus real core API, `Mocked Core API: false`, real persistence/permission result, and cleanup. |',
    '## Required State Machine',
    'The state order is exact:',
    '`SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> INTERACTION_READY -> FRONTEND_E2E_PASS -> FINAL_REVIEW -> ARCHIVE`',
    'Tasks may progress only from left to right. A `static-only` task reaches `FINAL_REVIEW` only after its visual pass and justified E2E N/A record. `interactive` and `business-flow` tasks must reach `FRONTEND_E2E_PASS` with real browser evidence before final review. Required E2E cannot be `SKIPPED` or manual-approved; an unmet requirement is `BLOCKED`.',
    '`VISUAL_REVIEW_PASS` is issued only by a separate, independent, read-only visual-review stage: it may write only its review artifact and must not modify implementation, source-evidence, or lifecycle files; it checks only the existing Visual Evidence Manifest `reference`, `current`, and `diff` artifacts against the real runtime route/state; SDD uses a fresh reviewer.',
    'The visual-review stage records exactly `VISUAL_REVIEW_PASS`, `CANNOT_VERIFY`, or `FAIL`; only `VISUAL_REVIEW_PASS` can advance. `CANNOT_VERIFY` is `BLOCKED`.',
    'On visual `FAIL`, return only to `STATIC_UI_READY`; on interaction or required-E2E `FAIL`, return only to `INTERACTION_READY`. Preserve prior visual-pass evidence only while current source and real runtime state still match it; otherwise run visual review again.',
    '## Case Manifest and E2E Evidence',
    'Each case manifest records its task and case ID, source-derived condition, UI delivery level, runtime route, real test account/role, `E2E Applicability: REQUIRED | N/A`, E2E result, `Mocked Core API: false` when E2E is required, cleanup result, evidence paths, and rationale for any `N/A` or `BLOCKED` status.',
    'Visual and E2E evidence are distinct channels:',
    '- Visual evidence uses `.fp-execute/visual/<task-id>/<case-id>/`.',
    '- E2E evidence uses `.fp-execute/e2e/<task-id>/<case-id>/`.',
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
    '- `Cleanup`',
    'E2E evidence may additionally record runner/version, browser, and result; artifacts include trace/video/screenshots when available. Visual fixtures are separate and never E2E evidence.',
    '## Real Frontend E2E: No Mock Data or Requests',
    'Real E2E has an absolute zero-mock rule. It must not use `page.route`, `route.fulfill`, MSW, Cypress stubs/intercepts, fixture JSON, mock modules, hard-coded API data, frontend store/localStorage business-data injection, database seed, or direct backend/API writes that bypass the normal UI flow.',
    'Real test accounts are permitted, but their authentication, role, and business data cannot be forged. A `business-flow` case proves the browser reached the real core API and the real persistence or permission outcome, then cleans up through an approved normal flow or a documented real-environment cleanup mechanism that does not replace the tested UI flow.',
    'Real error and exception paths may be exercised only with real environment, permission, or service conditions. If an in-scope condition cannot be safely triggered, its coverage entry must be `BLOCKED`, never `N/A` or `covered`.',
    '## Coverage Matrix',
    'E2E coverage is source-derived.',
    'The canonical coverage-matrix relative path is `.fp-execute/e2e/<task-id>/<case-id>/coverage-matrix.md`.',
    'One coverage matrix covers exactly one `<task-id>/<case-id>` pair.',
    'Coverage entry status is exactly `covered | N/A | BLOCKED`.',
    'A `BLOCKED` coverage entry means required evidence is unresolved; the Gate/Task lifecycle remains `BLOCKED` until it is resolved.',
    'Store that matrix with the case evidence, source/requirement reference, applicability, result, and rationale for every condition. It checks:',
    '- happy paths and branches;',
    '- validation and boundaries;',
    '- loading, empty, error, and retry states;',
    '- permissions and isolation;',
    '- persistence and navigation;',
    '- state transitions and concurrency; and',
    '- applicable API pagination, filtering, sorting, and compatibility.',
    'Each applicable condition must be `covered` or explicitly `N/A` / `BLOCKED` with rationale. `covered` records real evidence, `N/A` means the condition is not applicable, and `BLOCKED` means a required condition could not receive safe real-environment evidence.',
    '## Browser Capability Gate',
    'Prefer a verified existing project runner, then an installed browser extension, then an existing local `playwright-cli`. If none is available, enter `BROWSER_CAPABILITY_GATE`: report the discovered capabilities, missing prerequisite, browser download/network/disk impact, and project-file impact, then let the customer choose an extension, a global local-CLI installation, or no installation. Display the exact global-install command before it is run; the customer either runs it or explicitly authorizes FeaturePilot to run that exact command for this occasion.',
    'Never silently install a tool or browser component, add or update project dependencies, alter a lockfile, overwrite/create project browser configuration, change CI, or upgrade unrelated dependencies. Record the selected capability, customer authorization when applicable, executed command, version, and resulting artifacts in E2E evidence. If a required E2E has no approved usable capability, it is `BLOCKED`, never a mock fallback.',
    '## Retry, Blocking, Final Review, and Archive',
    'Core visual/E2E gaps and any mock violation remain `BLOCKED` through 3 attempts. They cannot be converted into review debt, `N/A`, `PASS`, a manual approval, or a waived check. `FINAL_REVIEW` and `ARCHIVE` cannot waive these blockers.',
    'After a failure, diagnostic retries may continue only through attempt 3.',
    'A third failed attempt is `BLOCKED`; a fourth attempt is forbidden.',
    'A core UI/E2E gap or any mock violation cannot become review debt, `N/A`, `PASS`, `PASS_WITH_NOTES`, a manual approval, or a waived check.'
)
$zeroMockForbiddenTerms = @(
    'mock',
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
    'E2E requirement',
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
    'BROWSER_CAPABILITY_GATE',
    'playwright-cli',
    'coverage-matrix.md',
    'BLOCKED'
) 'shared UI/E2E contract'

Assert-Condition (
    Test-ClosedNormativeLineSequence $contract $canonicalNormativeLines
) 'shared UI/E2E contract has drifted from its closed effective normative line sequence'
Assert-Condition (
    Test-DocumentTitleSchema $contract $documentTitle
) 'shared UI/E2E contract must have exactly one non-fenced H1 with its exact top-level title'
Assert-Condition (
    Test-ExactOrderedSecondLevelHeadings $contract $requiredHeadings
) 'shared UI/E2E contract is missing, duplicating, or reordering an exact required ## heading'
Assert-Condition (
    Test-ExactSentence $applicabilitySection $canonicalExecutionBinding
) 'shared UI/E2E contract does not bind applicability to every normative consumer'
Assert-Condition (
    (Test-StateMachineContract $stateMachineSection $canonicalStateMachineLine $canonicalRequiredE2ERule) -and
    (Test-ExactLines $stateMachineSection @($canonicalVisualReviewLine, $canonicalVisualReviewResultLine, $canonicalStageRollbackLine))
) 'shared UI/E2E contract does not preserve the exact state machine, independent visual review, and stage-local rollback rules'
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
    (Get-EffectiveNormativeText $contract) -cnotmatch '(?<![A-Za-z])blocked(?![A-Za-z])'
) 'shared UI/E2E contract still uses ambiguous lowercase blocked'
$commentedLowercaseBlocked = $contract + [Environment]::NewLine + '<!--' + [Environment]::NewLine + 'blocked' + [Environment]::NewLine + '-->'
Assert-Condition (
    (Get-EffectiveNormativeText $commentedLowercaseBlocked) -cnotmatch '(?<![A-Za-z])blocked(?![A-Za-z])'
) 'mutation fixture is invalid: lowercase blocked inside an HTML comment should not be normative text'
$fencedLowercaseBlocked = $contract + [Environment]::NewLine + '```text' + [Environment]::NewLine + 'blocked' + [Environment]::NewLine + '```'
Assert-Condition (
    (Get-EffectiveNormativeText $fencedLowercaseBlocked) -cnotmatch '(?<![A-Za-z])blocked(?![A-Za-z])'
) 'mutation fixture is invalid: lowercase blocked inside a valid fence should not be normative text'
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
$mutatedIndentedExtraH1 = Insert-AfterRequired $contract $documentTitle ([Environment]::NewLine + '  # Indented Extra UI/E2E Title') 'indented extra top-level title is added'
Assert-Condition (
    -not (Test-DocumentTitleSchema $mutatedIndentedExtraH1 $documentTitle)
) 'mutation survived: the UI/E2E contract may have an indented extra H1'
$mutatedSetextExtraH1 = $contract + [Environment]::NewLine + 'Extra UI/E2E Title' + [Environment]::NewLine + '==='
Assert-Condition (
    -not (Test-DocumentTitleSchema $mutatedSetextExtraH1 $documentTitle)
) 'mutation survived: the UI/E2E contract may have an extra Setext H1'

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
$mutatedIndentedExtraH2 = Insert-AfterRequired $contract '## Coverage Matrix' ([Environment]::NewLine + '  ## Indented Extra UI/E2E Section') 'indented extra second-level title is added'
Assert-Condition (
    -not (Test-ExactOrderedSecondLevelHeadings $mutatedIndentedExtraH2 $requiredHeadings)
) 'mutation survived: the UI/E2E contract may have an indented extra H2'
$mutatedSetextExtraH2 = $contract + [Environment]::NewLine + 'Extra UI/E2E Section' + [Environment]::NewLine + '---'
Assert-Condition (
    -not (Test-ExactOrderedSecondLevelHeadings $mutatedSetextExtraH2 $requiredHeadings)
) 'mutation survived: the UI/E2E contract may have an extra Setext H2'
$fencedPseudoHeadings = $contract + [Environment]::NewLine + '```markdown' + [Environment]::NewLine + '# Pseudo Title' + [Environment]::NewLine + '## Pseudo Section' + [Environment]::NewLine + '```'
Assert-Condition (
    Test-DocumentTitleSchema $fencedPseudoHeadings $documentTitle
) 'mutation fixture is invalid: fenced pseudo H1 should not alter the title schema'
Assert-Condition (
    Test-ExactOrderedSecondLevelHeadings $fencedPseudoHeadings $requiredHeadings
) 'mutation fixture is invalid: fenced pseudo H2 should not alter the second-level heading schema'
$commentedPseudoHeadings = $contract + [Environment]::NewLine + '<!--' + [Environment]::NewLine + '  # Pseudo Title' + [Environment]::NewLine + '  ## Pseudo Section' + [Environment]::NewLine + '-->'
Assert-Condition (
    Test-DocumentTitleSchema $commentedPseudoHeadings $documentTitle
) 'mutation fixture is invalid: HTML-comment pseudo H1 should not alter the title schema'
Assert-Condition (
    Test-ExactOrderedSecondLevelHeadings $commentedPseudoHeadings $requiredHeadings
) 'mutation fixture is invalid: HTML-comment pseudo H2 should not alter the second-level heading schema'
$tildeFencedPseudoHeadings = $contract + [Environment]::NewLine + '~~~~' + [Environment]::NewLine + '```' + [Environment]::NewLine + '  # Pseudo Title' + [Environment]::NewLine + '  ## Pseudo Section' + [Environment]::NewLine + '```' + [Environment]::NewLine + '~~~~'
Assert-Condition (
    Test-DocumentTitleSchema $tildeFencedPseudoHeadings $documentTitle
) 'mutation fixture is invalid: nested backticks in a tilde fence should not alter the title schema'
Assert-Condition (
    Test-ExactOrderedSecondLevelHeadings $tildeFencedPseudoHeadings $requiredHeadings
) 'mutation fixture is invalid: nested backticks in a tilde fence should not alter the second-level heading schema'
Assert-Condition (
    Test-ClosedNormativeLineSequence $commentedPseudoHeadings $canonicalNormativeLines
) 'mutation fixture is invalid: HTML-comment text should not alter the closed normative sequence'
Assert-Condition (
    Test-ClosedNormativeLineSequence $tildeFencedPseudoHeadings $canonicalNormativeLines
) 'mutation fixture is invalid: a proper tilde fence should not alter the closed normative sequence'
$invalidBacktickInfoFence = $contract + [Environment]::NewLine + '```text`' + [Environment]::NewLine + '# Extra UI/E2E Title' + [Environment]::NewLine + '```'
Assert-Condition (
    -not (Test-ClosedNormativeLineSequence $invalidBacktickInfoFence $canonicalNormativeLines)
) 'mutation survived: a backtick fence with a backtick in its info string may hide normative text'
$mutatedClosedMockAcceptance = $contract + [Environment]::NewLine + 'Mock data is acceptable for an E2E run.'
Assert-Condition (
    -not (Test-ClosedNormativeLineSequence $mutatedClosedMockAcceptance $canonicalNormativeLines)
) 'mutation survived: the closed normative sequence may accept mock E2E data'
$mutatedClosedE2EOptional = $contract + [Environment]::NewLine + 'The E2E requirement is optional.'
Assert-Condition (
    -not (Test-ClosedNormativeLineSequence $mutatedClosedE2EOptional $canonicalNormativeLines)
) 'mutation survived: the closed normative sequence may make E2E optional'
$mutatedClosedArchivePermission = $contract + [Environment]::NewLine + 'A waiver grants ARCHIVE permission for a core UI/E2E gap.'
Assert-Condition (
    -not (Test-ClosedNormativeLineSequence $mutatedClosedArchivePermission $canonicalNormativeLines)
) 'mutation survived: the closed normative sequence may grant ARCHIVE permission for a core gap'

Require-MutationBaseline (
    (Test-StateMachineContract $stateMachineSection $canonicalStateMachineLine $canonicalRequiredE2ERule) -and
    (Test-ExactLines $stateMachineSection @($canonicalVisualReviewLine, $canonicalVisualReviewResultLine, $canonicalStageRollbackLine))
) 'state machine, independent visual review, and stage-local rollback rules'
$mutatedStateMachine = Replace-Required $contract $canonicalStateMachineLine '`SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> FRONTEND_E2E_PASS -> INTERACTION_READY -> FINAL_REVIEW -> ARCHIVE`' 'state order is reversed'
$mutatedStateMachineSection = Get-MarkdownSecondLevelSection $mutatedStateMachine 'Required State Machine'
Assert-Condition (
    -not (Test-StateMachineContract $mutatedStateMachineSection $canonicalStateMachineLine $canonicalRequiredE2ERule)
) 'mutation survived: state machine may reorder interaction and frontend E2E'
$commentedVisualReview = Replace-Required $contract $canonicalVisualReviewLine ('<!-- ' + $canonicalVisualReviewLine + ' -->') 'comment-only visual review rule'
$commentedVisualReviewSection = Get-MarkdownSecondLevelSection (Get-EffectiveNormativeText $commentedVisualReview) 'Required State Machine'
Assert-Condition (
    -not (Test-ExactLines $commentedVisualReviewSection @($canonicalVisualReviewLine, $canonicalVisualReviewResultLine, $canonicalStageRollbackLine))
) 'mutation survived: comment-only independent visual review rule'
$fencedVisualReview = Replace-Required $contract $canonicalVisualReviewLine ('~~~' + [Environment]::NewLine + $canonicalVisualReviewLine + [Environment]::NewLine + '~~~') 'fenced visual review rule'
$fencedVisualReviewSection = Get-MarkdownSecondLevelSection (Get-EffectiveNormativeText $fencedVisualReview) 'Required State Machine'
Assert-Condition (
    -not (Test-ExactLines $fencedVisualReviewSection @($canonicalVisualReviewLine, $canonicalVisualReviewResultLine, $canonicalStageRollbackLine))
) 'mutation survived: fenced independent visual review rule'
$mutatedVisualReviewWrite = Replace-Required $contract 'must not modify implementation, source-evidence, or lifecycle files' 'may modify implementation, source-evidence, and lifecycle files' 'visual review may modify files'
$mutatedVisualReviewWriteSection = Get-MarkdownSecondLevelSection $mutatedVisualReviewWrite 'Required State Machine'
Assert-Condition (
    -not (Test-ExactLines $mutatedVisualReviewWriteSection @($canonicalVisualReviewLine, $canonicalVisualReviewResultLine, $canonicalStageRollbackLine))
) 'mutation survived: visual review may modify files'
$mutatedCannotVerifyAdvance = Replace-Required $contract '`CANNOT_VERIFY` is `BLOCKED`.' '`CANNOT_VERIFY` may advance to `INTERACTION_READY`.' 'cannot-verify may advance'
$mutatedCannotVerifyAdvanceSection = Get-MarkdownSecondLevelSection $mutatedCannotVerifyAdvance 'Required State Machine'
Assert-Condition (
    -not (Test-ExactLines $mutatedCannotVerifyAdvanceSection @($canonicalVisualReviewLine, $canonicalVisualReviewResultLine, $canonicalStageRollbackLine))
) 'mutation survived: CANNOT_VERIFY may enter interaction'
$mutatedRollbackScope = Replace-Required $contract 'return only to `STATIC_UI_READY`' 'may return to `INTERACTION_READY`' 'visual failure skips static UI recovery'
$mutatedRollbackScopeSection = Get-MarkdownSecondLevelSection $mutatedRollbackScope 'Required State Machine'
Assert-Condition (
    -not (Test-ExactLines $mutatedRollbackScopeSection @($canonicalVisualReviewLine, $canonicalVisualReviewResultLine, $canonicalStageRollbackLine))
) 'mutation survived: visual failure may skip STATIC_UI_READY recovery'
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
$mutatedRequiredE2ENote = Insert-AfterRequired $contract $canonicalRequiredE2ERule ([Environment]::NewLine + 'Note: An operator may waive the E2E requirement.') 'required E2E note waives the requirement'
$mutatedRequiredE2ENoteSection = Get-MarkdownSecondLevelSection $mutatedRequiredE2ENote 'Required State Machine'
Assert-Condition (
    -not (Test-RequiredE2EExceptionGuard $mutatedRequiredE2ENoteSection $canonicalRequiredE2ERule $requiredE2EContradictionTerms)
) 'mutation survived: a required-E2E note may waive the E2E requirement'
$mutatedRequiredE2EButGrant = Insert-AfterRequired $contract $canonicalRequiredE2ERule ([Environment]::NewLine + 'Required E2E cannot be `SKIPPED`, but manual approval may permit it.') 'required E2E negation is followed by manual approval'
$mutatedRequiredE2EButGrantSection = Get-MarkdownSecondLevelSection $mutatedRequiredE2EButGrant 'Required State Machine'
Assert-Condition (
    -not (Test-RequiredE2EExceptionGuard $mutatedRequiredE2EButGrantSection $canonicalRequiredE2ERule $requiredE2EContradictionTerms)
) 'mutation survived: a required-E2E negation may hide a later manual-approval grant'
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
$mutatedZeroMockBareNote = Insert-AfterRequired $contract $canonicalZeroMockRule ([Environment]::NewLine + 'Note: Real E2E may use mocks.') 'zero-mock note permits mocks'
$mutatedZeroMockBareNoteSection = Get-MarkdownSecondLevelSection $mutatedZeroMockBareNote 'Real Frontend E2E: No Mock Data or Requests'
Assert-Condition (
    -not (Test-ZeroMockContract $mutatedZeroMockBareNoteSection $canonicalZeroMockRule $zeroMockForbiddenTerms)
) 'mutation survived: a zero-mock note may allow mocks'
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
$mutatedArchiveCoreGapNote = Insert-AfterRequired $contract $canonicalArchiveNoWaiverRule ([Environment]::NewLine + 'Note: FINAL_REVIEW may proceed despite a core visual/E2E gap.') 'final review note permits a core gap'
$mutatedArchiveCoreGapNoteSection = Get-MarkdownSecondLevelSection $mutatedArchiveCoreGapNote 'Retry, Blocking, Final Review, and Archive'
Assert-Condition (
    -not (Test-ArchiveNoWaiverContract $mutatedArchiveCoreGapNoteSection $canonicalArchiveBlockerRule $canonicalArchiveNoWaiverRule)
) 'mutation survived: a final-review note may proceed despite a core visual/E2E gap'
$mutatedArchiveButGrant = Insert-AfterRequired $contract $canonicalArchiveNoWaiverRule ([Environment]::NewLine + 'FINAL_REVIEW cannot waive blockers, but ARCHIVE may waive blockers.') 'archive negation is followed by a waiver'
$mutatedArchiveButGrantSection = Get-MarkdownSecondLevelSection $mutatedArchiveButGrant 'Retry, Blocking, Final Review, and Archive'
Assert-Condition (
    -not (Test-ArchiveNoWaiverContract $mutatedArchiveButGrantSection $canonicalArchiveBlockerRule $canonicalArchiveNoWaiverRule)
) 'mutation survived: an archive negation may hide a later waiver grant'
$fencedArchiveWaiver = Insert-AfterRequired $contract $canonicalArchiveNoWaiverRule ([Environment]::NewLine + '```text' + [Environment]::NewLine + '### Waiver' + [Environment]::NewLine + 'FINAL_REVIEW and ARCHIVE may waive blockers.' + [Environment]::NewLine + '```') 'fenced archive waiver is ignored'
$fencedArchiveWaiverSection = Get-MarkdownSecondLevelSection $fencedArchiveWaiver 'Retry, Blocking, Final Review, and Archive'
Assert-Condition (
    Test-ArchiveNoWaiverContract $fencedArchiveWaiverSection $canonicalArchiveBlockerRule $canonicalArchiveNoWaiverRule
) 'mutation fixture is invalid: fenced archive waiver should not alter the contract'

Require-MutationBaseline (
    Test-ValidatorRegistration $validator $canonicalValidatorRegistrationLines
) 'complete focused UI/E2E validator registration'
$mutatedValidatorExitBeforeChain = Replace-Required $validator $canonicalValidatorRegistrationLines[0] ('exit' + [Environment]::NewLine + $canonicalValidatorRegistrationLines[0]) 'top-level exit precedes focused UI/E2E registration'
Assert-Condition (
    -not (Test-ValidatorRegistration $mutatedValidatorExitBeforeChain $canonicalValidatorRegistrationLines)
) 'mutation survived: a top-level exit may make the focused UI/E2E validator chain unreachable'
$mutatedValidatorReturnBeforeChain = Replace-Required $validator $canonicalValidatorRegistrationLines[0] ('return' + [Environment]::NewLine + $canonicalValidatorRegistrationLines[0]) 'top-level return precedes focused UI/E2E registration'
Assert-Condition (
    -not (Test-ValidatorRegistration $mutatedValidatorReturnBeforeChain $canonicalValidatorRegistrationLines)
) 'mutation survived: a top-level return may make the focused UI/E2E validator chain unreachable'
$mutatedValidatorIfTrueExitBeforeChain = Replace-Required $validator $canonicalValidatorRegistrationLines[0] ('if ($true) { exit }' + [Environment]::NewLine + $canonicalValidatorRegistrationLines[0]) 'literal-true if exits before focused UI/E2E registration'
Assert-Condition (
    -not (Test-ValidatorRegistration $mutatedValidatorIfTrueExitBeforeChain $canonicalValidatorRegistrationLines)
) 'mutation survived: a literal-true if may exit before the focused UI/E2E validator chain'
$mutatedValidatorIfTrueReturnBeforeChain = Replace-Required $validator $canonicalValidatorRegistrationLines[0] ('if ($true) { return }' + [Environment]::NewLine + $canonicalValidatorRegistrationLines[0]) 'literal-true if returns before focused UI/E2E registration'
Assert-Condition (
    -not (Test-ValidatorRegistration $mutatedValidatorIfTrueReturnBeforeChain $canonicalValidatorRegistrationLines)
) 'mutation survived: a literal-true if may return before the focused UI/E2E validator chain'
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
