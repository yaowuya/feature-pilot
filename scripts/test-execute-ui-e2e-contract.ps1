$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()
$lf = [string][char]10
$code = [string][char]96

function Read-Utf8([string]$relativePath) {
    return [System.IO.File]::ReadAllText((Join-Path $root $relativePath), [System.Text.Encoding]::UTF8)
}

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) { $script:failures.Add($message) }
}

function Require-MutationBaseline([bool]$condition, [string]$message) {
    if (-not $condition) { throw "Mutation baseline failed: $message" }
}

function Get-EffectiveNormativeText([string]$text) {
    $normalized = $text.Replace(([string][char]13) + $script:lf, $script:lf).Replace([string][char]13, $script:lf)
    $withoutComments = [regex]::Replace($normalized, '(?s)<!--.*?-->', '')
    $fenceCharacter = $null
    $minimumFenceLength = 0
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in ($withoutComments -split $script:lf)) {
        if ($null -eq $fenceCharacter) {
            $opening = [regex]::Match($line, '^ {0,3}(?<fence>\x60{3,}|~{3,})(?<info>.*)$')
            if ($opening.Success) {
                $fence = $opening.Groups['fence'].Value
                if ($fence.StartsWith([string][char]96) -and $opening.Groups['info'].Value.Contains([string][char]96)) {
                    $lines.Add($line)
                    continue
                }
                $fenceCharacter = $fence.Substring(0, 1)
                $minimumFenceLength = $fence.Length
                continue
            }
            $lines.Add($line)
            continue
        }
        $closing = [regex]::Match($line, '^ {0,3}(?<fence>\x60{3,}|~{3,})[ \t]*$')
        if ($closing.Success) {
            $fence = $closing.Groups['fence'].Value
            if ($fence.Substring(0, 1) -eq $fenceCharacter -and $fence.Length -ge $minimumFenceLength) {
                $fenceCharacter = $null
                $minimumFenceLength = 0
            }
        }
    }
    return [string]::Join($script:lf, $lines.ToArray())
}

function Test-ExactSecondLevelHeading([string]$effectiveText, [string]$heading) {
    return @($effectiveText -split $script:lf | Where-Object { $_ -ceq "## $heading" }).Count -eq 1
}

function Get-ExactSecondLevelSection([string]$effectiveText, [string]$heading) {
    $lines = @($effectiveText -split $script:lf)
    $positions = @()
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -ceq "## $heading") { $positions += $index }
    }
    if ($positions.Count -ne 1) { return '' }
    $body = [System.Collections.Generic.List[string]]::new()
    for ($index = $positions[0] + 1; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^ {0,3}##(?!#)\s+') { break }
        $body.Add($lines[$index])
    }
    return [string]::Join($script:lf, $body.ToArray())
}

function Test-ExactLine([string]$text, [string]$line) {
    return @($text -split $script:lf | Where-Object { $_ -ceq $line }).Count -eq 1
}

function Test-ClosedNormativeLineSequence([string]$text, [string[]]$canonicalLines) {
    $actual = @($text -split $script:lf | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($actual.Count -ne $canonicalLines.Count) { return $false }
    for ($index = 0; $index -lt $canonicalLines.Count; $index++) {
        if ($actual[$index] -cne $canonicalLines[$index]) { return $false }
    }
    return $true
}

function Test-SectionHasLineWithAll([string]$section, [string[]]$anchors) {
    foreach ($line in ($section -split $script:lf)) {
        $matches = $true
        foreach ($anchor in $anchors) {
            if ($line.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
                $matches = $false
                break
            }
        }
        if ($matches) { return $true }
    }
    return $false
}

function Test-ClauseHasPermissiveGrant([string]$clause) {
    foreach ($match in [regex]::Matches($clause, '(?i)\b(?:may|can|allow(?:s|ed|ing)?|permit|permits|permitted|permitting)\b')) {
        if ($clause.Substring($match.Index + $match.Length) -notmatch '^\s+not\b') { return $true }
    }
    return $false
}

function Test-SectionHasNoPermissiveGrant([string]$section, [string[]]$forbiddenTerms) {
    foreach ($line in ($section -split $script:lf)) {
        $plain = [regex]::Replace($line, '[\`*>#]', '')
        foreach ($clause in [regex]::Split($plain, '(?<=[.!?])\s+|(?i:\s*,?\s+but\s+|\s*;\s*)')) {
            if (-not $clause.Trim()) { continue }
            $hasForbidden = $false
            foreach ($term in $forbiddenTerms) {
                if ($clause.IndexOf($term, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                    $hasForbidden = $true
                    break
                }
            }
            if ($hasForbidden -and (Test-ClauseHasPermissiveGrant $clause)) { return $false }
        }
    }
    return $true
}

function Test-StatePaths([string]$gate, [string]$staticLine, [string]$interactiveLine, [string]$noSkipLine) {
    return (Test-ExactLine $gate $staticLine) -and
        (Test-ExactLine $gate $interactiveLine) -and
        (Test-ExactLine $gate $noSkipLine) -and
        (Test-SectionHasNoPermissiveGrant $gate @('SKIPPED', 'manual-approved', 'manual approval', 'waived check'))
}

function Test-ZeroMockRule(
    [string]$gate,
    [string]$canonicalLine,
    [string[]]$forbiddenTerms,
    [string[]]$canonicalGateLines
) {
    return (Test-ExactLine $gate $canonicalLine) -and
        (Test-ClosedNormativeLineSequence $gate $canonicalGateLines) -and
        (Test-SectionHasNoPermissiveGrant $gate $forbiddenTerms) -and
        ($gate -notmatch '(?i)\b(?:mock|stub|intercept|fixture|seed|direct backend/API)\b.{0,160}\b(?:may|can|allow(?:s|ed|ing)?|permit|permits|permitted|permitting)\b')
}

function Test-BrowserCapability([string]$gate, [string]$canonicalLine) {
    return (Test-ExactLine $gate $canonicalLine) -and
        (Test-SectionHasNoPermissiveGrant $gate @('global', 'overwrite existing configuration', 'upgrade unrelated dependencies'))
}

function Test-SyntacticallyDefiniteTrueCondition([System.Management.Automation.Language.Ast]$condition) {
    $text = $condition.Extent.Text.Trim()
    while ($text.StartsWith('(') -and $text.EndsWith(')') -and $text.Length -ge 2) {
        $text = $text.Substring(1, $text.Length - 2).Trim()
    }
    return $text -ceq '$true' -or $text -match '^1\s*-eq\s*1$'
}

function Test-TopLevelStatementTerminatesBeforeRegistration([System.Management.Automation.Language.StatementAst]$statement) {
    if ($statement -is [System.Management.Automation.Language.ExitStatementAst] -or
        $statement -is [System.Management.Automation.Language.ReturnStatementAst] -or
        $statement.Extent.Text.Trim() -match '^(?i)(?:exit|return)(?:\s|$)') {
        return $true
    }
    if ($statement -isnot [System.Management.Automation.Language.IfStatementAst]) { return $false }
    $ifStatement = [System.Management.Automation.Language.IfStatementAst]$statement
    if ($ifStatement.Clauses.Count -ne 1 -or -not (Test-SyntacticallyDefiniteTrueCondition $ifStatement.Clauses[0].Item1)) {
        return $false
    }
    return @($ifStatement.Clauses[0].Item2.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.ExitStatementAst] -or
            $node -is [System.Management.Automation.Language.ReturnStatementAst]
    }, $true)).Count -gt 0
}

function Test-ValidatorRegistration([string]$text, [string[]]$expectedLines) {
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($text, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -ne 0) { return $false }
    $expectedTypes = @('AssignmentStatementAst', 'PipelineAst', 'PipelineAst', 'PipelineAst')
    $tryBlocks = @($ast.EndBlock.Statements | Where-Object { $_ -is [System.Management.Automation.Language.TryStatementAst] })
    if ($tryBlocks.Count -ne 1) { return $false }
    $statements = @($tryBlocks[0].Body.Statements)
    for ($start = 0; $start -le ($statements.Count - $expectedLines.Count); $start++) {
        $matches = $true
        for ($offset = 0; $offset -lt $expectedLines.Count; $offset++) {
            if ($statements[$start + $offset].GetType().Name -cne $expectedTypes[$offset] -or
                $statements[$start + $offset].Extent.Text.Trim() -cne $expectedLines[$offset]) {
                $matches = $false
                break
            }
        }
        if (-not $matches) { continue }
        for ($prior = 0; $prior -lt $start; $prior++) {
            if (Test-TopLevelStatementTerminatesBeforeRegistration $statements[$prior]) { return $false }
        }
        return $true
    }
    return $false
}

function Replace-Required([string]$text, [string]$oldValue, [string]$newValue, [string]$name) {
    if ($text.IndexOf($oldValue, [System.StringComparison]::Ordinal) -lt 0) { throw "Mutation baseline failed: $name" }
    return $text.Replace($oldValue, $newValue)
}

function Insert-BeforeRequired([string]$text, [string]$marker, [string]$payload, [string]$name) {
    $index = $text.IndexOf($marker, [System.StringComparison]::Ordinal)
    if ($index -lt 0) { throw "Mutation baseline failed: $name" }
    return $text.Substring(0, $index) + $payload + $text.Substring($index)
}

function Insert-AfterRequired([string]$text, [string]$marker, [string]$payload, [string]$name) {
    $index = $text.IndexOf($marker, [System.StringComparison]::Ordinal)
    if ($index -lt 0) { throw "Mutation baseline failed: $name" }
    $afterMarker = $index + $marker.Length
    return $text.Substring(0, $afterMarker) + $payload + $text.Substring($afterMarker)
}

$skill = Read-Utf8 'skills\fp-execute\SKILL.md'
$validator = Read-Utf8 'scripts\validate-plugin.ps1'
$effectiveSkill = Get-EffectiveNormativeText $skill
$gateHeading = 'UI-bearing Task Gate'
$completionHeading = ([string][char]0x5B8C) + ([string][char]0x6210) + ([string][char]0x6C47) + ([string][char]0x62A5)
$gate = Get-ExactSecondLevelSection $effectiveSkill $gateHeading
$completion = Get-ExactSecondLevelSection $effectiveSkill $completionHeading

$sharedLine = 'Read ' + $code + '$' + '{CLAUDE_PLUGIN_ROOT}/skills/_shared/ui-e2e-contract.md' + $code + ' once before executing UI-bearing work; it owns delivery levels, allowed lifecycle paths, real-E2E evidence, zero-mock rules, coverage status semantics, customer-selected browser capability, retry, and non-waivable blocking.'
$planLine = 'Before each UI-bearing confirmed task, resolve its unique stable task owner and read the matching ' + $code + 'UI/E2E Delivery Contract' + $code + ' and ' + $code + 'Visual Evidence Manifest' + $code + ' rows by ' + $code + 'Task ID + Case ID' + $code + ' from the canonical frontend plan. The UI/E2E contract links existing visual evidence and does not duplicate visual-manifest fields: approved-design provenance, Figma mapping, viewport/fixture, reference/current/diff, mask, visual acceptance, and visual command remain the Visual Evidence Manifest''s only fields.'
$sourceReadyLine = 'For every matched case, record lifecycle-gate evidence under the existing task ledger and canonical case directories; this is recovery/verification evidence only, and the unique task-owner checkbox remains the sole plan-completion authority. First prove ' + $code + 'SOURCE_READY' + $code + ' from the source-derived condition / requirement reference, route, and real test account or role. Implement the case as ' + $code + 'STATIC_UI_READY' + $code + ', then require the existing Visual Evidence Manifest to pass as ' + $code + 'VISUAL_REVIEW_PASS' + $code + '.'
$visualReviewLine = 'After ' + $code + 'STATIC_UI_READY' + $code + ', direct execution must run its separate visual-review pass before any case advances. It is independent of implementation, read-only, must not modify files, and checks only the Visual Evidence Manifest ' + $code + 'reference' + $code + ', ' + $code + 'current' + $code + ', and ' + $code + 'diff' + $code + ' artifacts against the real runtime route/state. Direct execution records exactly ' + $code + 'VISUAL_REVIEW_PASS' + $code + ', ' + $code + 'CANNOT_VERIFY' + $code + ', or ' + $code + 'FAIL' + $code + '; only ' + $code + 'VISUAL_REVIEW_PASS' + $code + ' may continue, and only then may an ' + $code + 'interactive' + $code + ' or ' + $code + 'business-flow' + $code + ' case enter ' + $code + 'INTERACTION_READY' + $code + '. ' + $code + 'CANNOT_VERIFY' + $code + ' is ' + $code + 'BLOCKED' + $code + '. On visual ' + $code + 'FAIL' + $code + ', return only to ' + $code + 'STATIC_UI_READY' + $code + '; on interaction or required-E2E ' + $code + 'FAIL' + $code + ', return only to ' + $code + 'INTERACTION_READY' + $code + '. Preserve prior visual-pass evidence only while current source and real runtime state still match it; otherwise run the separate visual-review pass again.'
$staticLine = '- ' + $code + 'static-only' + $code + ' follows ' + $code + 'SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> FINAL_REVIEW -> ARCHIVE' + $code + ' only after its visual pass and evidence-backed ' + $code + 'E2E Applicability: N/A' + $code + ' reason. It must not enter ' + $code + 'INTERACTION_READY' + $code + ' or ' + $code + 'FRONTEND_E2E_PASS' + $code + '.'
$interactiveLine = '- ' + $code + 'interactive' + $code + ' and ' + $code + 'business-flow' + $code + ' follow ' + $code + 'SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> INTERACTION_READY -> FRONTEND_E2E_PASS -> FINAL_REVIEW -> ARCHIVE' + $code + '. At ' + $code + 'INTERACTION_READY' + $code + ', prove the real target browser can operate the required controls; at ' + $code + 'FRONTEND_E2E_PASS' + $code + ', run real browser E2E and record ' + $code + 'E2E Applicability: REQUIRED' + $code + '.'
$noSkipLine = '- Required E2E cannot be ' + $code + 'SKIPPED' + $code + ' or manual-approved, and a screenshot is not E2E evidence. A required UI/E2E gap cannot become non-blocking debt, ' + $code + 'N/A' + $code + ', ' + $code + 'PASS' + $code + ', ' + $code + 'PASS_WITH_NOTES' + $code + ', a manual approval, or a waived check; it is ' + $code + 'BLOCKED' + $code + '.'
$evidenceLine = 'For each required E2E case, create and maintain ' + $code + '.fp-execute/e2e/<task-id>/<case-id>/' + $code + ', including ' + $code + 'coverage-matrix.md' + $code + '. Record ' + $code + 'Executed command' + $code + ', ' + $code + 'Environment identity' + $code + ', ' + $code + 'Destination' + $code + ', ' + $code + 'Start' + $code + ', ' + $code + 'End' + $code + ', ' + $code + 'Attempts' + $code + ', ' + $code + 'Test IDs' + $code + ', ' + $code + 'Artifacts' + $code + ', and ' + $code + 'Cleanup' + $code + '; link the real-browser result and the Visual Evidence Manifest separately. Derive coverage from source and confirmed requirements: happy paths and branches; validation and boundaries; loading, empty, error, and retry states; permissions and isolation; persistence and navigation; state transitions and concurrency; and applicable API pagination, filtering, sorting, and compatibility. A real environment condition that cannot safely be verified is ' + $code + 'BLOCKED' + $code + ', never a mock or an E2E ' + $code + 'N/A' + $code + '.'
$zeroMockLine = 'Real E2E has an absolute zero-mock rule. It must not use ' + $code + 'page.route' + $code + ', ' + $code + 'route.fulfill' + $code + ', MSW, Cypress stubs/intercepts, fixture JSON, mock modules, hard-coded API data, frontend store/localStorage business-data injection, database seed, or direct backend/API writes that bypass the normal UI flow. For ' + $code + 'business-flow' + $code + ', prove the browser reaches the real core API, record ' + $code + 'Mocked Core API: false' + $code + ', observe the real persistence or permission result, and perform cleanup of test-created data through an approved normal flow or documented real-environment cleanup mechanism that does not replace the tested UI flow.'
$browserCapabilityLine = 'Prefer a verified existing project runner, installed browser extension, or existing local ' + $code + 'playwright-cli' + $code + '. If none is available, stop at ' + $code + 'BROWSER_CAPABILITY_GATE' + $code + ': report the discovered capabilities and impacts, then let the customer choose an extension, a global local-CLI installation, or no installation. The customer must run the displayed exact command or explicitly authorize FeaturePilot to run that exact command for this occasion. Never silently install a tool or browser component, add/update project dependencies, alter a lockfile, overwrite/create project configuration, change CI, or upgrade unrelated dependencies. Record the selected capability, customer choice, command, resolved version, and artifacts in case evidence. No approved usable capability is ' + $code + 'BLOCKED' + $code + ', never a mock fallback.'
$retryLine = 'After a UI/E2E failure, diagnostic retries may continue only through attempt 3. A third failed attempt is ' + $code + 'BLOCKED' + $code + '; a fourth attempt is forbidden. Do not update the unique task-owner checkbox as complete or continue that task to final handoff while any required lifecycle gate, coverage condition, real-E2E result, cleanup, or mock check is ' + $code + 'BLOCKED' + $code + '.'
$canonicalGateLines = @($planLine, $sourceReadyLine, $visualReviewLine, $staticLine, $interactiveLine, $noSkipLine, $evidenceLine, $zeroMockLine, $browserCapabilityLine, $retryLine)
$registrationLines = @(
    '$executeUiE2EContractValidator = Join-Path $root ''scripts\test-execute-ui-e2e-contract.ps1''',
    'Assert-Condition (Test-Path $executeUiE2EContractValidator) ''focused direct-execution UI/E2E contract validator is missing''',
    '& powershell -NoProfile -ExecutionPolicy Bypass -File $executeUiE2EContractValidator',
    'Assert-Condition ($LASTEXITCODE -eq 0) ''focused direct-execution UI/E2E contract validator failed'''
)
$mockTerms = @('page.route', 'route.fulfill', 'MSW', 'Cypress stubs/intercepts', 'fixture JSON', 'mock modules', 'hard-coded API data', 'store/localStorage business-data injection', 'database seed', 'direct backend/API writes')

Assert-Condition (Test-ExactSecondLevelHeading $effectiveSkill $gateHeading) 'fp-execute is missing one effective exact UI-bearing Task Gate heading'
Assert-Condition (Test-ExactSecondLevelHeading $effectiveSkill $completionHeading) 'fp-execute is missing one effective exact completion-report heading'
Assert-Condition (Test-ExactLine $effectiveSkill $sharedLine) 'fp-execute does not load the shared UI/E2E staged contract before UI-bearing work'
Assert-Condition (Test-ExactLine $gate $planLine) 'fp-execute does not link UI/E2E Delivery Contract to Visual Evidence Manifest by Task ID + Case ID'
Assert-Condition (Test-ExactLine $gate $visualReviewLine) 'fp-execute does not independently perform the read-only visual review or keep failures in their responsible stage'
Assert-Condition (Test-StatePaths $gate $staticLine $interactiveLine $noSkipLine) 'fp-execute does not enforce exact delivery-level UI/E2E state paths'
Assert-Condition (Test-ExactLine $gate $evidenceLine) 'fp-execute lacks canonical real E2E evidence and source-derived coverage requirements'
Assert-Condition (Test-ZeroMockRule $gate $zeroMockLine $mockTerms $canonicalGateLines) 'fp-execute allows or omits the closed real-E2E zero-mock prohibition'
Assert-Condition (Test-BrowserCapability $gate $browserCapabilityLine) 'fp-execute lacks a closed customer-selected browser capability gate'
Assert-Condition (Test-ExactLine $gate $zeroMockLine) 'fp-execute lacks real business-flow closure requirements'
Assert-Condition ((Test-ExactLine $gate $retryLine) -and (Test-SectionHasNoPermissiveGrant $gate @('BLOCKED', 'non-blocking debt', 'manual approval', 'waived check')) -and (Test-SectionHasLineWithAll $completion @('unresolved UI core gap', 'must not hand off to', '.fp-execute/e2e/<task-id>/<case-id>/', 'BLOCKED'))) 'fp-execute lacks bounded UI/E2E retries or blocks final handoff insufficiently'
Assert-Condition (Test-ValidatorRegistration $validator $registrationLines) 'global validator does not invoke the focused direct-execution UI/E2E contract through the required AST registration chain'

$commentedZeroMock = Replace-Required $skill $zeroMockLine ('<!-- ' + $zeroMockLine + ' -->') 'comment-only zero-mock rule'
Assert-Condition (-not (Test-ZeroMockRule (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $commentedZeroMock) $gateHeading) $zeroMockLine $mockTerms $canonicalGateLines)) 'mutation survived: comment-only zero-mock rule'
$fencedZeroMock = Replace-Required $skill $zeroMockLine ('~~~' + $lf + $zeroMockLine + $lf + '~~~') 'fenced-code zero-mock rule'
Assert-Condition (-not (Test-ZeroMockRule (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $fencedZeroMock) $gateHeading) $zeroMockLine $mockTerms $canonicalGateLines)) 'mutation survived: fenced-code zero-mock rule'
$commentedVisualReview = Replace-Required $skill $visualReviewLine ('<!-- ' + $visualReviewLine + ' -->') 'comment-only direct visual review rule'
Assert-Condition (-not (Test-ExactLine (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $commentedVisualReview) $gateHeading) $visualReviewLine)) 'mutation survived: comment-only direct visual review rule'
$fencedVisualReview = Replace-Required $skill $visualReviewLine ('~~~' + $lf + $visualReviewLine + $lf + '~~~') 'fenced direct visual review rule'
Assert-Condition (-not (Test-ExactLine (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $fencedVisualReview) $gateHeading) $visualReviewLine)) 'mutation survived: fenced direct visual review rule'
$visualReviewMayWrite = Replace-Required $skill 'must not modify files' 'may modify files' 'direct visual review may modify files'
Assert-Condition (-not (Test-ExactLine (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $visualReviewMayWrite) $gateHeading) $visualReviewLine)) 'mutation survived: direct visual review may modify files'
$cannotVerifySource = 'CANNOT_VERIFY' + $code + ' is ' + $code + 'BLOCKED' + $code + '.'
$cannotVerifyCounterexample = 'CANNOT_VERIFY' + $code + ' may enter ' + $code + 'INTERACTION_READY' + $code + '.'
$cannotVerifyMayAdvance = Replace-Required $skill $cannotVerifySource $cannotVerifyCounterexample 'direct cannot-verify may advance'
Assert-Condition ($cannotVerifyMayAdvance -ceq $skill.Replace($cannotVerifySource, $cannotVerifyCounterexample)) 'mutation fixture must replace the complete CANNOT_VERIFY status counterexample'
Assert-Condition (-not (Test-ExactLine (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $cannotVerifyMayAdvance) $gateHeading) $visualReviewLine)) 'mutation survived: direct CANNOT_VERIFY may enter interaction'
$visualFailureSource = 'return only to ' + $code + 'STATIC_UI_READY' + $code
$visualFailureCounterexample = 'may return to ' + $code + 'INTERACTION_READY' + $code
$visualFailureMaySkipStatic = Replace-Required $skill $visualFailureSource $visualFailureCounterexample 'direct visual failure skips static UI recovery'
Assert-Condition ($visualFailureMaySkipStatic -ceq $skill.Replace($visualFailureSource, $visualFailureCounterexample)) 'mutation fixture must replace the complete visual-failure rollback counterexample'
Assert-Condition (-not (Test-ExactLine (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $visualFailureMaySkipStatic) $gateHeading) $visualReviewLine)) 'mutation survived: direct visual failure may skip STATIC_UI_READY recovery'
$invalidBacktickOpening = [string]::new([char]96, 3) + 'text' + $code
$invalidBacktickFixture = "## $gateHeading" + $lf + $invalidBacktickOpening + $lf + 'Exception: mock data is permitted.'
$invalidBacktickEffective = Get-EffectiveNormativeText $invalidBacktickFixture
Assert-Condition ($invalidBacktickEffective.Contains($invalidBacktickOpening)) 'invalid backtick-fence opening was removed from active normative text'
Assert-Condition (-not (Test-SectionHasNoPermissiveGrant $invalidBacktickEffective @('mock data'))) 'invalid backtick-fence opening hid a following mock grant'
$mayUseMock = Replace-Required $skill 'It must not use' 'It may use' 'may-use mock rule'
Assert-Condition (-not (Test-ZeroMockRule (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $mayUseMock) $gateHeading) $zeroMockLine $mockTerms $canonicalGateLines)) 'mutation survived: fp-execute may use mock E2E data'
$permittedMock = Insert-AfterRequired $skill $zeroMockLine ($lf + 'Exception: mock is permitted.') 'permitted mock exception'
Assert-Condition (-not (Test-ZeroMockRule (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $permittedMock) $gateHeading) $zeroMockLine $mockTerms $canonicalGateLines)) 'mutation survived: fp-execute permits mock E2E data'
$validFixture = Insert-AfterRequired $skill $zeroMockLine ($lf + 'Exception: fixture JSON is valid for real E2E.') 'valid fixture exception'
Assert-Condition (-not (Test-ZeroMockRule (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $validFixture) $gateHeading) $zeroMockLine $mockTerms $canonicalGateLines)) 'mutation survived: fixture JSON is valid for real E2E'
$mayEnterStatic = Replace-Required $skill 'It must not enter' 'It may enter' 'static-only interaction exception'
Assert-Condition (-not (Test-StatePaths (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $mayEnterStatic) $gateHeading) $staticLine $interactiveLine $noSkipLine)) 'mutation survived: static-only may enter interaction/E2E gates'
$maySkipRequired = Insert-AfterRequired $skill $noSkipLine ($lf + 'Exception: required E2E may be SKIPPED.') 'required E2E skip exception'
Assert-Condition (-not (Test-StatePaths (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $maySkipRequired) $gateHeading) $staticLine $interactiveLine $noSkipLine)) 'mutation survived: required E2E may be skipped'
$globalInstallPermitted = Insert-AfterRequired $skill $browserCapabilityLine ($lf + 'Exception: global install is permitted.') 'global install exception'
Assert-Condition (-not (Test-BrowserCapability (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $globalInstallPermitted) $gateHeading) $browserCapabilityLine)) 'mutation survived: unapproved global installation is permitted'
$commentedRegistration = Replace-Required $validator $registrationLines[0] ('<# ' + $registrationLines[0] + ' #>') 'commented validator registration'
Assert-Condition (-not (Test-ValidatorRegistration $commentedRegistration $registrationLines)) 'mutation survived: block-commented global validator registration'
$hereStringRegistration = Replace-Required $validator $registrationLines[0] ("@'" + $lf + $registrationLines[0] + $lf + "'@") 'here-string validator registration'
Assert-Condition (-not (Test-ValidatorRegistration $hereStringRegistration $registrationLines)) 'mutation survived: here-string global validator registration'
foreach ($termination in @(
    @{ Name = 'direct exit'; Payload = 'exit' + $lf }
    @{ Name = 'direct return'; Payload = 'return' + $lf }
    @{ Name = 'if true exit'; Payload = 'if ($true) { exit }' + $lf }
    @{ Name = 'if true return'; Payload = 'if ($true) { return }' + $lf }
    @{ Name = 'if one equals one exit'; Payload = 'if (1 -eq 1) { exit }' + $lf }
    @{ Name = 'if one equals one return'; Payload = 'if (1 -eq 1) { return }' + $lf }
)) {
    Assert-Condition (-not (Test-ValidatorRegistration (Insert-BeforeRequired $validator $registrationLines[0] $termination.Payload $termination.Name) $registrationLines)) "mutation survived: $($termination.Name) before global validator registration"
}

if ($failures.Count -gt 0) { throw ('Direct execution UI/E2E contract validation failed:' + $lf + '- ' + ($failures -join ($lf + '- '))) }
Write-Output 'Direct execution UI/E2E contract validation passed.'
