$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
$failures = [System.Collections.Generic.List[string]]::new()
$lf = [string][char]10
$tick = [string][char]96

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
    $insideFence = $false
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in ($withoutComments -split $script:lf)) {
        if ($line -match '^ {0,3}(?:\`{3,}|~{3,})') {
            $insideFence = -not $insideFence
            continue
        }
        if (-not $insideFence) { $lines.Add($line) }
    }
    return [string]::Join($script:lf, $lines.ToArray())
}

function Test-ExactSecondLevelHeading([string]$text, [string]$heading) {
    return @($text -split $script:lf | Where-Object { $_ -ceq "## $heading" }).Count -eq 1
}

function Get-ExactSecondLevelSection([string]$text, [string]$heading) {
    $lines = @($text -split $script:lf)
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

function Test-NoPermissiveException([string]$section, [string[]]$terms) {
    foreach ($line in ($section -split $script:lf)) {
        $plain = [regex]::Replace($line, '[\`*>#]', '')
        foreach ($clause in [regex]::Split($plain, '(?<=[.!?])\s+|(?i:\s*,?\s+but\s+|\s*;\s*)')) {
            $forbidden = @($terms | Where-Object { $clause.IndexOf($_, [System.StringComparison]::OrdinalIgnoreCase) -ge 0 })
            $grant = $clause -match '(?i)\b(?:may|can|allow(?:s|ed|ing)?|permit|permits|permitted|permitting)\b(?!\s+not\b)'
            if ($forbidden.Count -gt 0 -and $grant) { return $false }
        }
    }
    return $true
}

function Test-TrueExitOrReturn([System.Management.Automation.Language.StatementAst]$statement) {
    if ($statement -is [System.Management.Automation.Language.ExitStatementAst] -or $statement -is [System.Management.Automation.Language.ReturnStatementAst]) { return $true }
    if ($statement -isnot [System.Management.Automation.Language.IfStatementAst]) { return $false }
    $ifStatement = [System.Management.Automation.Language.IfStatementAst]$statement
    if ($ifStatement.Clauses.Count -ne 1) { return $false }
    $condition = $ifStatement.Clauses[0].Item1.Extent.Text.Trim('(', ')', ' ')
    if ($condition -cne '$true' -and $condition -notmatch '^1\s*-eq\s*1$') { return $false }
    return @($ifStatement.Clauses[0].Item2.FindAll({
        param($node)
        $node -is [System.Management.Automation.Language.ExitStatementAst] -or $node -is [System.Management.Automation.Language.ReturnStatementAst]
    }, $true)).Count -gt 0
}

function Test-ValidatorRegistration([string]$text, [string[]]$lines) {
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($text, [ref]$tokens, [ref]$errors)
    if ($errors.Count -ne 0) { return $false }
    $statements = @($ast.EndBlock.Statements)
    for ($start = 0; $start -le ($statements.Count - $lines.Count); $start++) {
        $matches = $true
        for ($offset = 0; $offset -lt $lines.Count; $offset++) {
            if ($statements[$start + $offset].Extent.Text.Trim() -cne $lines[$offset]) {
                $matches = $false
                break
            }
        }
        if (-not $matches) { continue }
        for ($prior = 0; $prior -lt $start; $prior++) {
            if (Test-TrueExitOrReturn $statements[$prior]) { return $false }
        }
        return $true
    }
    return $false
}

function Replace-Required([string]$text, [string]$old, [string]$new, [string]$name) {
    if ($text.IndexOf($old, [System.StringComparison]::Ordinal) -lt 0) { throw "Mutation baseline failed: $name" }
    return $text.Replace($old, $new)
}

function Insert-AfterRequired([string]$text, [string]$marker, [string]$payload, [string]$name) {
    $index = $text.IndexOf($marker, [System.StringComparison]::Ordinal)
    if ($index -lt 0) { throw "Mutation baseline failed: $name" }
    return $text.Substring(0, $index + $marker.Length) + $payload + $text.Substring($index + $marker.Length)
}

function Insert-BeforeRequired([string]$text, [string]$marker, [string]$payload, [string]$name) {
    $index = $text.IndexOf($marker, [System.StringComparison]::Ordinal)
    if ($index -lt 0) { throw "Mutation baseline failed: $name" }
    return $text.Substring(0, $index) + $payload + $text.Substring($index)
}

$skill = Read-Utf8 'skills\fp-execute-sdd\SKILL.md'
$brief = Read-Utf8 'skills\fp-execute-sdd\task-brief-template.md'
$implementer = Read-Utf8 'skills\fp-execute-sdd\implementer-prompt.md'
$reviewer = Read-Utf8 'skills\fp-execute-sdd\task-reviewer-prompt.md'
$package = Read-Utf8 'skills\fp-execute-sdd\review-package-template.md'
$fix = Read-Utf8 'skills\fp-execute-sdd\fix-prompt.md'
$verifier = Read-Utf8 'skills\fp-execute-sdd\e2e-verifier-prompt.md'
$validator = Read-Utf8 'scripts\validate-plugin.ps1'
$effectiveSkill = Get-EffectiveNormativeText $skill
$effectiveVerifier = Get-EffectiveNormativeText $verifier
$gateHeading = 'UI/E2E Delivery Gate'
$verifierHeading = 'Real Browser Verification Rules'
$pluginRoot = '$' + '{CLAUDE_PLUGIN_ROOT}'
$sharedLine = 'Read ' + $tick + $pluginRoot + '/skills/_shared/ui-e2e-contract.md' + $tick + ' once before executing UI-bearing work; it owns delivery levels, allowed lifecycle paths, real-E2E evidence, zero-mock rules, coverage status semantics, bootstrap, retry, and non-waivable blocking.'
$planLinkLine = 'For a UI-bearing task, resolve the matching ' + $tick + 'UI/E2E Delivery Contract' + $tick + ' and ' + $tick + 'Visual Evidence Manifest' + $tick + ' by stable ' + $tick + 'Task ID + Case ID' + $tick + ' from the canonical frontend plan. Link the manifest by reference only: visual provenance, Figma mapping, viewport/fixture, reference/current/diff, mask, visual acceptance, and visual command remain Visual Evidence Manifest fields.'
$ledgerLine = '- For each UI case, record its delivery level, current lifecycle stage, manifest reference, E2E evidence root, coverage-matrix result, attempts, cleanup, and any ' + $tick + 'BLOCKED' + $tick + ' rationale in progress/review package evidence only; do not copy Visual Evidence Manifest fields or replace the unique task-owner checkbox as the sole completion authority.'
$stageLine = 'The controller records ' + $tick + 'SOURCE_READY' + $tick + ' from the source-derived condition/requirement, route, and real account/role; then ' + $tick + 'STATIC_UI_READY' + $tick + '; then applies the existing visual decision table to record ' + $tick + 'VISUAL_REVIEW_PASS' + $tick + ' before E2E dispatch.'
$staticLine = '- ' + $tick + 'static-only' + $tick + ' may proceed from ' + $tick + 'VISUAL_REVIEW_PASS' + $tick + ' to final review only with the evidence-backed ' + $tick + 'E2E Applicability: N/A' + $tick + ' record; it must not enter ' + $tick + 'INTERACTION_READY' + $tick + ' or ' + $tick + 'FRONTEND_E2E_PASS' + $tick + '.'
$interactiveLine = '- ' + $tick + 'interactive' + $tick + ' and ' + $tick + 'business-flow' + $tick + ' must progress ' + $tick + 'VISUAL_REVIEW_PASS -> INTERACTION_READY -> FRONTEND_E2E_PASS' + $tick + ' with independent real-browser E2E evidence; required E2E cannot be skipped, manually waived, or satisfied by a screenshot.'
$dispatchLine = 'For every required E2E case, dispatch one fresh independent ' + $tick + 'e2e-verifier' + $tick + ' using ' + $tick + $pluginRoot + '/skills/fp-execute-sdd/e2e-verifier-prompt.md' + $tick + '. The implementer may prepare ' + $tick + 'INTERACTION_READY' + $tick + ' but must never self-confirm ' + $tick + 'FRONTEND_E2E_PASS' + $tick + '; the verifier runs only the real browser UI and records case evidence.'
$reviewerLine = 'The task reviewer must verify both the existing visual evidence and the independent E2E verifier evidence; a screenshot is never a substitute for E2E, and a visual/E2E core gap or mock violation cannot be ' + $tick + 'PASS_WITH_NOTES' + $tick + ', review debt, or a manual waiver.'
$retryLine = 'Any required lifecycle/E2E/coverage/cleanup/mock failure consumes the bounded diagnostic retry: attempt 1 or 2 returns through the serial fix loop, a third failure is ' + $tick + 'BLOCKED' + $tick + ', and a fourth attempt is forbidden. The controller must not reconcile the owner checkbox or dispatch final review while one remains ' + $tick + 'BLOCKED' + $tick + '.'
$zeroMockLine = 'Real E2E has an absolute zero-mock rule. It must not use ' + $tick + 'page.route' + $tick + ', ' + $tick + 'route.fulfill' + $tick + ', MSW, Cypress stubs/intercepts, fixture JSON, mock modules, hard-coded API data, frontend store/localStorage business-data injection, database seed, or direct backend/API writes that bypass the normal UI flow.'
$bootstrapLine = 'Prefer the existing runner. If it is missing, detect target frontend root, workspace, lockfile, and package manager, then automatically install ' + $tick + '@playwright/test' + $tick + ' as a development dependency and Chromium only in that target project. Never install globally, overwrite existing configuration, or upgrade unrelated dependencies; bootstrap failure is ' + $tick + 'BLOCKED' + $tick + '.'
$evidenceLine = 'For each case record ' + $tick + 'Executed command' + $tick + ', ' + $tick + 'Environment identity' + $tick + ', ' + $tick + 'Destination' + $tick + ', ' + $tick + 'Start' + $tick + ', ' + $tick + 'End' + $tick + ', ' + $tick + 'Attempts' + $tick + ', ' + $tick + 'Test IDs' + $tick + ', ' + $tick + 'Artifacts' + $tick + ', ' + $tick + 'Coverage matrix reference' + $tick + ', ' + $tick + 'Cleanup' + $tick + ', and ' + $tick + 'Mocked Core API: false' + $tick + ' for business-flow.'
$blockedSourceLine = 'If a source-derived condition cannot be safely reached in the real environment, record its coverage entry as ' + $tick + 'BLOCKED' + $tick + ', never as ' + $tick + 'N/A' + $tick + ' or a mock fallback.'
$registration = @(
    '$executeSddUiE2EContractValidator = Join-Path $root ''scripts\test-execute-sdd-ui-e2e-contract.ps1''',
    'Assert-Condition (Test-Path $executeSddUiE2EContractValidator) ''focused SDD execution UI/E2E contract validator is missing''',
    '& powershell -NoProfile -ExecutionPolicy Bypass -File $executeSddUiE2EContractValidator',
    'Assert-Condition ($LASTEXITCODE -eq 0) ''focused SDD execution UI/E2E contract validator failed'''
)
$mockTerms = @('mock', 'page.route', 'route.fulfill', 'MSW', 'Cypress stubs/intercepts', 'fixture JSON', 'mock modules', 'hard-coded API data', 'store/localStorage business-data injection', 'database seed', 'direct backend/API writes')

Assert-Condition (Test-ExactLine $effectiveSkill $sharedLine) 'fp-execute-sdd does not load the shared staged UI/E2E contract'
Assert-Condition (Test-ExactSecondLevelHeading $effectiveSkill $gateHeading) 'fp-execute-sdd is missing one effective exact UI/E2E Delivery Gate heading'
$gate = Get-ExactSecondLevelSection $effectiveSkill $gateHeading
Assert-Condition (Test-ExactLine $gate $planLinkLine) 'SDD does not link UI/E2E contract and visual evidence by Task ID + Case ID without copying visual fields'
Assert-Condition (Test-ExactLine $effectiveSkill $ledgerLine) 'SDD does not keep UI/E2E progress evidence non-authoritative'
Assert-Condition ((Test-ExactLine $gate $stageLine) -and (Test-ExactLine $gate $staticLine) -and (Test-ExactLine $gate $interactiveLine)) 'SDD does not enforce the staged delivery-level lifecycle'
Assert-Condition ((Test-ExactLine $gate $dispatchLine) -and (Test-ExactLine $gate $reviewerLine) -and (Test-ExactLine $gate $retryLine)) 'SDD does not preserve independent E2E verification and non-waivable bounded blocking'
Assert-Condition (Test-ExactSecondLevelHeading $effectiveVerifier $verifierHeading) 'SDD E2E verifier is missing its effective verification-rules section'
$verifierRules = Get-ExactSecondLevelSection $effectiveVerifier $verifierHeading
Assert-Condition ((Test-ExactLine $verifierRules $zeroMockLine) -and (Test-ExactLine $verifierRules $bootstrapLine) -and (Test-ExactLine $verifierRules $evidenceLine) -and (Test-ExactLine $verifierRules $blockedSourceLine)) 'SDD verifier lacks required zero-mock, bootstrap, evidence, or source-derived blocking rules'
Assert-Condition (Test-NoPermissiveException $verifierRules ($mockTerms + @('global', 'SKIPPED', 'manual waiver', 'PASS_WITH_NOTES'))) 'SDD verifier permits a mock, waiver, or global-install exception'
Assert-Condition ($brief.Contains('## UI/E2E Delivery Contract (frontend/UI only)') -and $brief.Contains('Visual Evidence Manifest reference') -and $implementer.Contains('must never self-confirm ' + $tick + 'FRONTEND_E2E_PASS' + $tick) -and $reviewer.Contains('both the existing visual evidence and the independent E2E verifier evidence') -and $package.Contains('## UI/E2E Delivery Evidence (frontend/UI only)') -and $fix.Contains('must not be converted into review debt, ' + $tick + 'PASS_WITH_NOTES' + $tick + ', or a manual waiver')) 'SDD templates do not carry the independent staged UI/E2E gate'
Assert-Condition (Test-ValidatorRegistration $validator $registration) 'global validator does not invoke the focused SDD UI/E2E validator through the required AST registration chain'

Require-MutationBaseline (Test-ExactLine $verifierRules $zeroMockLine) 'zero-mock baseline'
$commentedZeroMock = Replace-Required $verifier $zeroMockLine ('<!-- ' + $zeroMockLine + ' -->') 'comment-only zero-mock rule'
Assert-Condition (-not (Test-ExactLine (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $commentedZeroMock) $verifierHeading) $zeroMockLine)) 'mutation survived: comment-only zero-mock rule'
$fencedZeroMock = Replace-Required $verifier $zeroMockLine ('~~~' + $lf + $zeroMockLine + $lf + '~~~') 'fenced zero-mock rule'
Assert-Condition (-not (Test-ExactLine (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $fencedZeroMock) $verifierHeading) $zeroMockLine)) 'mutation survived: fenced zero-mock rule'
$mayUseMock = Replace-Required $verifier 'It must not use' 'It may use' 'may-use mock rule'
Assert-Condition (-not (Test-ExactLine (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $mayUseMock) $verifierHeading) $zeroMockLine)) 'mutation survived: verifier may use mock data'
$mockException = Insert-AfterRequired $verifier $zeroMockLine ($lf + 'Exception: mock data is permitted.') 'mock exception'
Assert-Condition (-not (Test-NoPermissiveException (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $mockException) $verifierHeading) $mockTerms)) 'mutation survived: verifier permits mock data'
$globalInstall = Insert-AfterRequired $verifier $bootstrapLine ($lf + 'Exception: global install is permitted.') 'global-install exception'
Assert-Condition (-not (Test-NoPermissiveException (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $globalInstall) $verifierHeading) @('global'))) 'mutation survived: verifier permits global install'
$skipWaiver = Insert-AfterRequired $skill $interactiveLine ($lf + 'Exception: required E2E may be SKIPPED with a manual waiver.') 'required E2E skip waiver'
Assert-Condition (-not (Test-NoPermissiveException (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $skipWaiver) $gateHeading) @('SKIPPED', 'manual waiver'))) 'mutation survived: SDD permits required-E2E skip/waiver'
foreach ($termination in @('if (1 -eq 1) { exit }', 'if (1 -eq 1) { return }')) {
    Assert-Condition (-not (Test-ValidatorRegistration (Insert-BeforeRequired $validator $registration[0] ($termination + $lf) 'unreachable registration') $registration)) "mutation survived: $termination before SDD validator registration"
}

if ($failures.Count -gt 0) { throw ('SDD execution UI/E2E contract validation failed:' + $lf + '- ' + ($failures -join ($lf + '- '))) }
Write-Output 'SDD execution UI/E2E contract validation passed.'
