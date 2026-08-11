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

function Get-EffectiveVerifierPrompt([string]$text) {
    $normalized = $text.Replace(([string][char]13) + $script:lf, $script:lf).Replace([string][char]13, $script:lf)
    $outer = Get-EffectiveNormativeText $normalized
    $promptFence = [regex]::Match($normalized, '(?ms)^ {0,3}\x60{3}text[ \t]*\n(?<body>.*?)^ {0,3}\x60{3,}[ \t]*$')
    if (-not $promptFence.Success) { return $outer }
    $promptBody = [regex]::Replace($promptFence.Groups['body'].Value, '(?s)<!--.*?-->', '')
    return $outer + $script:lf + $promptBody
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

function Test-NoForbiddenGrant([string]$section) {
    $mockAction = '(?:mock(?:\s+(?:data|module))?|page\.route|route\.fulfill|MSW|Cypress\s+stubs/intercepts|fixture\s+JSON|hard-coded\s+API\s+data|frontend\s+store/localStorage\s+business-data\s+injection|database\s+seed|direct\s+backend/API\s+writes)'
    $grantVerb = '(?:may|can|allow(?:s|ed|ing)?|permit(?:s|ted|ting)?)'
    $grantState = '(?:is|are)\s+(?:allowed|permitted|okay|fine|valid)'
    $skipAction = '(?:skip(?:ped|ping)?|manual\s+waiver|PASS_WITH_NOTES)'
    foreach ($line in ($section -split $script:lf)) {
        $plain = [regex]::Replace($line, '[\`*>#]', '')
        foreach ($clause in [regex]::Split($plain, '(?<=[.!?])\s+|(?i:\s*,?\s+but\s+|\s*;\s*)')) {
            $mockGrant = '(?i)(?:' + $mockAction + ').{0,36}(?:\b' + $grantVerb + '\b(?!\s+not\b)|\b' + $grantState + '\b)|\b' + $grantVerb + '\b(?!\s+not\b).{0,36}(?:' + $mockAction + ')'
            $globalGrant = '(?i)(?:(?:global\s+install|install\s+globally).{0,36}(?:\b' + $grantVerb + '\b(?!\s+not\b)|\b' + $grantState + '\b)|\b' + $grantVerb + '\b(?!\s+not\b).{0,36}(?:global\s+install|install\s+globally))'
            $requiredSkipGrant = '(?i)(?:required\s+E2E.{0,36}(?:\b' + $grantVerb + '\b(?!\s+not\b)|\b' + $grantState + '\b).{0,36}' + $skipAction + '|(?:\b' + $grantVerb + '\b(?!\s+not\b)|\b' + $grantState + '\b).{0,36}' + $skipAction + '.{0,36}required\s+E2E|' + $skipAction + '.{0,36}required\s+E2E.{0,36}(?:\b' + $grantVerb + '\b(?!\s+not\b)|\b' + $grantState + '\b))'
            $manualWaiverGrant = '(?i)(?:manual\s+waiver.{0,36}(?:\b' + $grantVerb + '\b(?!\s+not\b)|\b' + $grantState + '\b)|\b' + $grantVerb + '\b(?!\s+not\b).{0,36}manual\s+waiver)'
            $passWithNotesGrant = '(?i)(?:PASS_WITH_NOTES.{0,36}(?:\b' + $grantVerb + '\b(?!\s+not\b)|\b' + $grantState + '\b)|\b' + $grantVerb + '\b(?!\s+not\b).{0,36}PASS_WITH_NOTES)'
            if ($clause -match $mockGrant -or $clause -match $globalGrant -or $clause -match $requiredSkipGrant -or $clause -match $manualWaiverGrant -or $clause -match $passWithNotesGrant) { return $false }
        }
    }
    return $true
}

function Test-IsNestedInFunctionDefinition([System.Management.Automation.Language.Ast]$node) {
    $cursor = $node.Parent
    while ($null -ne $cursor) {
        if ($cursor -is [System.Management.Automation.Language.FunctionDefinitionAst]) { return $true }
        $cursor = $cursor.Parent
    }
    return $false
}

function Test-TopLevelStatementMayTerminate([System.Management.Automation.Language.StatementAst]$statement) {
    if ($statement -is [System.Management.Automation.Language.FunctionDefinitionAst]) { return $false }
    return @($statement.FindAll({
        param($node)
        ($node -is [System.Management.Automation.Language.ExitStatementAst] -or $node -is [System.Management.Automation.Language.ReturnStatementAst]) -and
            -not (Test-IsNestedInFunctionDefinition $node)
    }, $true)).Count -gt 0
}

function Test-ValidatorRegistration([string]$text, [string[]]$lines) {
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($text, [ref]$tokens, [ref]$errors)
    if ($errors.Count -ne 0) { return $false }
    $tryBlocks = @($ast.EndBlock.Statements | Where-Object { $_ -is [System.Management.Automation.Language.TryStatementAst] })
    if ($tryBlocks.Count -ne 1) { return $false }
    $statements = @($tryBlocks[0].Body.Statements)
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
            if (Test-TopLevelStatementMayTerminate $statements[$prior]) { return $false }
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
$normalizedBrief = $brief.Replace(([string][char]13) + $lf, $lf).Replace([string][char]13, $lf)
$effectiveSkill = Get-EffectiveNormativeText $skill
$effectiveVerifier = Get-EffectiveVerifierPrompt $verifier
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
$bootstrapAuthorityLine = 'Bootstrap is authorized only when controller and brief record the exact target frontend root, allowed bootstrap/test paths, current manifest/lockfile/config state, selected package manager, and the scoped real E2E case.'
$bootstrapScopeLine = 'Within that recorded root and allowed scope, you may create or adjust only necessary real E2E tests, project manifest/lockfile entries, Chromium installation, and minimal config only when no existing config exists; do not edit product code, overwrite existing config, or upgrade unrelated dependencies.'
$bootstrapEvidenceLine = 'Record the exact target root, allowed paths/scope, detected workspace/lockfile/package manager, commands, resolved version, and every manifest/lockfile/config/test/browser change in E2E evidence.'
$controllerAuthorityLine = 'Before every required E2E verifier launch, the controller must place the exact ' + $tick + 'Target frontend root' + $tick + ', ' + $tick + 'Allowed bootstrap / real E2E test paths and scope' + $tick + ', ' + $tick + 'Manifest / lockfile / config status' + $tick + ', and ' + $tick + 'Package manager' + $tick + ' in the matching Task ID + Case ID brief UI/E2E record. If any value is missing, unresolved, or outside the approved task scope, record ' + $tick + 'BLOCKED' + $tick + ' and do not dispatch the verifier.'
$briefAuthorityHeader = '| Case ID | Target frontend root | Allowed bootstrap / real E2E test paths and scope | Manifest / lockfile / config status | Package manager |'
$briefAuthorityLine = '- The controller fills this authority record before verifier dispatch. A missing, unresolved, or out-of-scope value is ' + $tick + 'BLOCKED' + $tick + '; the verifier must consume these values rather than infer them.'
$verifierAuthorityBlockedLine = 'If any authority input is missing, unresolved, or outside the recorded scope, return ' + $tick + 'BLOCKED' + $tick + ' without bootstrap or E2E execution.'
$evidenceLine = 'For each case record ' + $tick + 'Executed command' + $tick + ', ' + $tick + 'Environment identity' + $tick + ', ' + $tick + 'Destination' + $tick + ', ' + $tick + 'Start' + $tick + ', ' + $tick + 'End' + $tick + ', ' + $tick + 'Attempts' + $tick + ', ' + $tick + 'Test IDs' + $tick + ', ' + $tick + 'Artifacts' + $tick + ', ' + $tick + 'Coverage matrix reference' + $tick + ', ' + $tick + 'Cleanup' + $tick + ', and ' + $tick + 'Mocked Core API: false' + $tick + ' for business-flow.'
$blockedSourceLine = 'If a source-derived condition cannot be safely reached in the real environment, record its coverage entry as ' + $tick + 'BLOCKED' + $tick + ', never as ' + $tick + 'N/A' + $tick + ' or a mock fallback.'
$registration = @(
    '$executeSddUiE2EContractValidator = Join-Path $root ''scripts\test-execute-sdd-ui-e2e-contract.ps1''',
    'Assert-Condition (Test-Path $executeSddUiE2EContractValidator) ''focused SDD execution UI/E2E contract validator is missing''',
    '& powershell -NoProfile -ExecutionPolicy Bypass -File $executeSddUiE2EContractValidator',
    'Assert-Condition ($LASTEXITCODE -eq 0) ''focused SDD execution UI/E2E contract validator failed'''
)

Assert-Condition (Test-ExactLine $effectiveSkill $sharedLine) 'fp-execute-sdd does not load the shared staged UI/E2E contract'
Assert-Condition (Test-ExactSecondLevelHeading $effectiveSkill $gateHeading) 'fp-execute-sdd is missing one effective exact UI/E2E Delivery Gate heading'
$gate = Get-ExactSecondLevelSection $effectiveSkill $gateHeading
Assert-Condition (Test-ExactLine $gate $planLinkLine) 'SDD does not link UI/E2E contract and visual evidence by Task ID + Case ID without copying visual fields'
Assert-Condition (Test-ExactLine $effectiveSkill $ledgerLine) 'SDD does not keep UI/E2E progress evidence non-authoritative'
Assert-Condition ((Test-ExactLine $gate $stageLine) -and (Test-ExactLine $gate $staticLine) -and (Test-ExactLine $gate $interactiveLine)) 'SDD does not enforce the staged delivery-level lifecycle'
Assert-Condition ((Test-ExactLine $gate $dispatchLine) -and (Test-ExactLine $gate $reviewerLine) -and (Test-ExactLine $gate $retryLine)) 'SDD does not preserve independent E2E verification and non-waivable bounded blocking'
Assert-Condition (Test-ExactLine $gate $controllerAuthorityLine) 'SDD controller does not block verifier dispatch on exact brief-owned E2E authority'
Assert-Condition (Test-ExactSecondLevelHeading $effectiveVerifier $verifierHeading) 'SDD E2E verifier is missing its effective verification-rules section'
$verifierRules = Get-ExactSecondLevelSection $effectiveVerifier $verifierHeading
Assert-Condition ((Test-ExactLine $verifierRules $zeroMockLine) -and (Test-ExactLine $verifierRules $bootstrapLine) -and (Test-ExactLine $verifierRules $evidenceLine) -and (Test-ExactLine $verifierRules $blockedSourceLine)) 'SDD verifier lacks required zero-mock, bootstrap, evidence, or source-derived blocking rules'
Assert-Condition ((Test-NoForbiddenGrant $effectiveVerifier) -and (Test-NoForbiddenGrant $effectiveSkill)) 'SDD verifier or controller permits a mock, required-E2E waiver, or global-install exception'
Assert-Condition ((Test-ExactLine $verifierRules $bootstrapAuthorityLine) -and (Test-ExactLine $verifierRules $bootstrapScopeLine) -and (Test-ExactLine $verifierRules $bootstrapEvidenceLine)) 'SDD verifier lacks controller-scoped authority for project-local bootstrap and necessary real E2E tests'
Assert-Condition ((Test-ExactLine $effectiveVerifier 'Target frontend root: {TARGET_FRONTEND_ROOT}') -and (Test-ExactLine $effectiveVerifier 'Allowed bootstrap / real E2E test paths and scope: {ALLOWED_E2E_PATHS_AND_SCOPE}') -and (Test-ExactLine $effectiveVerifier 'Manifest / lockfile / config status: {MANIFEST_LOCKFILE_CONFIG_STATUS}') -and (Test-ExactLine $effectiveVerifier 'Package manager: {PACKAGE_MANAGER}') -and (Test-ExactLine $effectiveVerifier $verifierAuthorityBlockedLine) -and (Test-ExactLine $normalizedBrief $briefAuthorityHeader) -and (Test-ExactLine $normalizedBrief $briefAuthorityLine)) 'SDD controller, brief, and verifier do not share exact bootstrap authority fields'
Assert-Condition ($brief.Contains('## UI/E2E Delivery Contract (frontend/UI only)') -and $brief.Contains('Visual Evidence Manifest reference') -and $implementer.Contains('must never self-confirm ' + $tick + 'FRONTEND_E2E_PASS' + $tick) -and $reviewer.Contains('both the existing visual evidence and the independent E2E verifier evidence') -and $package.Contains('## UI/E2E Delivery Evidence (frontend/UI only)') -and $fix.Contains('must not be converted into review debt, ' + $tick + 'PASS_WITH_NOTES' + $tick + ', or a manual waiver')) 'SDD templates do not carry the independent staged UI/E2E gate'
Assert-Condition (Test-ValidatorRegistration $validator $registration) 'global validator does not invoke the focused SDD UI/E2E validator through the required AST registration chain'

Require-MutationBaseline (Test-ExactLine $verifierRules $zeroMockLine) 'zero-mock baseline'
$commentedZeroMock = Replace-Required $verifier $zeroMockLine ('<!-- ' + $zeroMockLine + ' -->') 'comment-only zero-mock rule'
Assert-Condition (-not (Test-ExactLine (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $commentedZeroMock) $verifierHeading) $zeroMockLine)) 'mutation survived: comment-only zero-mock rule'
$fencedZeroMock = Replace-Required $verifier $zeroMockLine ('~~~' + $lf + $zeroMockLine + $lf + '~~~') 'fenced zero-mock rule'
Assert-Condition (-not (Test-ExactLine (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $fencedZeroMock) $verifierHeading) $zeroMockLine)) 'mutation survived: fenced zero-mock rule'
$invalidBacktickOpening = [string]::new([char]96, 3) + 'text' + $tick
$invalidBacktickFixture = "## $verifierHeading" + $lf + $invalidBacktickOpening + $lf + 'Exception: mock data is fine.'
$invalidBacktickEffective = Get-EffectiveNormativeText $invalidBacktickFixture
Assert-Condition ($invalidBacktickEffective.Contains($invalidBacktickOpening)) 'invalid backtick-fence opening was removed from active normative text'
Assert-Condition (-not (Test-NoForbiddenGrant $invalidBacktickEffective)) 'invalid backtick-fence opening hid a following mock grant'
$mayUseMock = Replace-Required $verifier 'It must not use' 'It may use' 'may-use mock rule'
Assert-Condition (-not (Test-ExactLine (Get-ExactSecondLevelSection (Get-EffectiveNormativeText $mayUseMock) $verifierHeading) $zeroMockLine)) 'mutation survived: verifier may use mock data'
$mockException = Insert-AfterRequired $verifier $zeroMockLine ($lf + 'Exception: mock data is permitted.') 'mock exception'
Assert-Condition (-not (Test-NoForbiddenGrant (Get-EffectiveNormativeText $mockException))) 'mutation survived: verifier permits mock data'
$globalInstall = Insert-AfterRequired $verifier $bootstrapLine ($lf + 'Exception: global install is permitted.') 'global-install exception'
Assert-Condition (-not (Test-NoForbiddenGrant (Get-EffectiveNormativeText $globalInstall))) 'mutation survived: verifier permits global install'
$crossSectionMockFine = Insert-AfterRequired $verifier '## E2E Result File Format' ($lf + $lf + 'Exception: mock data is fine.') 'cross-section mock-fine exception'
Assert-Condition (-not (Test-NoForbiddenGrant (Get-EffectiveNormativeText $crossSectionMockFine))) 'mutation survived: verifier permits mock data in another section'
$crossSectionMockAllowed = Insert-AfterRequired $verifier '## E2E Result File Format' ($lf + $lf + 'Exception: mock data is allowed.') 'cross-section mock-allowed exception'
Assert-Condition (-not (Test-NoForbiddenGrant (Get-EffectiveNormativeText $crossSectionMockAllowed))) 'mutation survived: verifier allows mock data in another section'
$textFenceMockFine = Insert-AfterRequired $verifier '## Mission' ($lf + $lf + 'Exception: mock data is fine.') 'actionable text-fence mock-fine exception'
Assert-Condition (-not (Test-NoForbiddenGrant (Get-EffectiveVerifierPrompt $textFenceMockFine))) 'mutation survived: verifier permits mock data inside its actionable text fence'
$crlfVerifier = $verifier.Replace(([string][char]13) + $lf, $lf).Replace($lf, ([string][char]13) + $lf)
$crlfEffectiveVerifier = Get-EffectiveVerifierPrompt $crlfVerifier
Assert-Condition (Test-ExactLine $crlfEffectiveVerifier 'Target frontend root: {TARGET_FRONTEND_ROOT}') 'CRLF actionable text fence omits verifier bootstrap authority inputs'
$commentedMockGrant = Insert-AfterRequired $verifier '## E2E Result File Format' ($lf + '<!-- Exception: mock data is fine. -->') 'commented mock grant'
Assert-Condition (Test-NoForbiddenGrant (Get-EffectiveVerifierPrompt $commentedMockGrant)) 'mutation fixture is invalid: commented mock grant should be ignored'
$fencedMockGrant = Insert-AfterRequired $verifier '## E2E Result File Format' ($lf + '~~~text' + $lf + 'Exception: mock data is fine.' + $lf + '~~~') 'fenced mock grant'
Assert-Condition (Test-NoForbiddenGrant (Get-EffectiveVerifierPrompt $fencedMockGrant)) 'mutation fixture is invalid: fenced mock grant should be ignored'
foreach ($payload in @('Required E2E is okay to skip.', 'Required E2E is permitted to skip.', 'Required E2E is allowed to skip.', 'Skipping required E2E is fine.', 'Skip required E2E is permitted.', 'Skip required E2E is okay.')) {
    $skipWaiver = Insert-AfterRequired $skill '## Completion and Final Review' ($lf + $lf + $payload) 'cross-section required-E2E grant'
    Assert-Condition (-not (Test-NoForbiddenGrant (Get-EffectiveNormativeText $skipWaiver))) "mutation survived: $payload"
}
foreach ($termination in @('if (1 -eq 1) { exit }', 'if (1 -eq 1) { return }', 'if (2 -gt 1) { exit }', 'if (2 -gt 1) { return }')) {
    Assert-Condition (-not (Test-ValidatorRegistration (Insert-BeforeRequired $validator $registration[0] ($termination + $lf) 'unreachable registration') $registration)) "mutation survived: $termination before SDD validator registration"
}
$functionReturn = Insert-BeforeRequired $validator $registration[0] ('function Test-SafeReturn { return }' + $lf) 'function-local return'
Assert-Condition (Test-ValidatorRegistration $functionReturn $registration) 'function-local return should not make SDD validator registration unreachable'

if ($failures.Count -gt 0) { throw ('SDD execution UI/E2E contract validation failed:' + $lf + '- ' + ($failures -join ($lf + '- '))) }
Write-Output 'SDD execution UI/E2E contract validation passed.'
