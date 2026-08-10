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

function Get-EffectiveNormativeText([string]$text) {
    $normalizedLf = $text -replace "`r`n?", "`n"
    $withoutComments = [regex]::Replace($normalizedLf, '(?s)<!--.*?-->', '')
    $fenceCharacter = $null
    $minimumFenceLength = 0
    $keptLines = [System.Collections.Generic.List[string]]::new()

    foreach ($line in ($withoutComments -split "`n")) {
        if ($null -eq $fenceCharacter) {
            $openingFence = [regex]::Match($line, '^ {0,3}(?<fence>`{3,}|~{3,})(?<info>.*)$')
            if ($openingFence.Success) {
                $openingValue = $openingFence.Groups['fence'].Value
                if ($openingValue.StartsWith('`') -and $openingFence.Groups['info'].Value.Contains('`')) {
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
            if ($closingValue.Substring(0, 1) -eq $fenceCharacter -and $closingValue.Length -ge $minimumFenceLength) {
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

function Test-EffectiveLineRegex([string]$text, [string]$pattern) {
    foreach ($line in (Get-EffectiveNormativeLines $text)) {
        if ($line -match $pattern) {
            return $true
        }
    }
    return $false
}

function Test-EffectiveTextRegex([string]$text, [string]$pattern) {
    return [regex]::IsMatch((Get-EffectiveNormativeText $text), $pattern)
}

function Get-CanonicalTemplateBody([string]$text) {
    $matches = [regex]::Matches($text, '(?ms)^````markdown\r?\n(?<body>.*?)^````\s*$')
    if ($matches.Count -ne 1) {
        return ''
    }
    return $matches[0].Groups['body'].Value
}

function Test-SharedContractReference([string]$text) {
    return Test-EffectiveLineRegex $text '(?i)^\s*(?:When UI scope exists, )?Read `?\$\{CLAUDE_PLUGIN_ROOT\}/skills/_shared/ui-e2e-contract\.md`?.*$'
}

function Test-ValidatorRegistration([string]$validatorText, [string[]]$registrationLines) {
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $validatorText,
        [ref]$tokens,
        [ref]$parseErrors
    )
    if ($parseErrors.Count -ne 0) {
        return $false
    }

    $expectedTypes = @('AssignmentStatementAst', 'PipelineAst', 'PipelineAst', 'PipelineAst')
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

function Test-NoPermissiveArchiveWaiver([string]$text) {
    $effectiveText = Get-EffectiveNormativeText $text
    foreach ($sentence in [regex]::Split($effectiveText, '(?<=[.!?])\s+')) {
        if ($sentence -match '(?i)\b(?:archive|final review)\b' -and
            $sentence -match '(?i)\b(?:FRONTEND_E2E_PASS|core UI/E2E|required E2E|mock violation|BLOCKED)\b' -and
            $sentence -match '(?i)\b(?:may|can|allow(?:s|ed|ing)?|permit(?:s|ted|ting)?)\b(?!\s+not)') {
            return $false
        }
    }
    return $true
}

function Replace-Required([string]$text, [string]$oldValue, [string]$newValue, [string]$mutationName) {
    if ($text.IndexOf($oldValue, [System.StringComparison]::Ordinal) -lt 0) {
        throw "Invalid mutation fixture; production text was not hit: $mutationName"
    }
    return [regex]::Replace($text, [regex]::Escape($oldValue), $newValue)
}

$shared = Read-Utf8 'skills\_shared\ui-e2e-contract.md'
$figma = Read-Utf8 'skills\fp-figma\SKILL.md'
$plan = Read-Utf8 'skills\fp-plan-frontend\SKILL.md'
$planTemplate = Read-Utf8 'skills\fp-plan-frontend\plan-template.md'
$planTemplateBody = Get-CanonicalTemplateBody $planTemplate
$execute = Read-Utf8 'skills\fp-execute\SKILL.md'
$executeSdd = Read-Utf8 'skills\fp-execute-sdd\SKILL.md'
$finalReview = Read-Utf8 'skills\fp-final-review\SKILL.md'
$archive = Read-Utf8 'skills\fp-archive\SKILL.md'
$validator = Read-Utf8 'scripts\validate-plugin.ps1'
$readme = Read-Utf8 'README.md'
$agents = Read-Utf8 'AGENTS.md'
$userGuide = Read-Utf8 'docs\user_guide\init-prd-start.md'

$consumers = @{
    'fp-figma' = $figma
    'fp-plan-frontend' = $plan
    'fp-execute' = $execute
    'fp-execute-sdd' = $executeSdd
    'fp-final-review' = $finalReview
    'fp-archive' = $archive
}
foreach ($consumer in $consumers.GetEnumerator()) {
    Assert-Condition (Test-SharedContractReference $consumer.Value) "$($consumer.Key) must consume the effective shared UI/E2E contract reference"
}

Assert-Condition (Test-EffectiveTextRegex $shared '(?s)SOURCE_READY\s*->\s*STATIC_UI_READY\s*->\s*VISUAL_REVIEW_PASS.*?FRONTEND_E2E_PASS.*?FINAL_REVIEW\s*->\s*ARCHIVE') 'shared contract lost the required staged lifecycle'
Assert-Condition (Test-EffectiveTextRegex $shared '(?i)absolute zero-mock rule') 'shared contract lost the zero-mock rule'
Assert-Condition (Test-EffectiveTextRegex $shared '(?i)@playwright/test.*?Chromium') 'shared contract lost project-local Playwright bootstrap'
Assert-Condition (Test-EffectiveTextRegex $shared '(?i)Mocked Core API: false.*?real persistence or permission result.*?cleanup') 'shared contract lost business-flow closure'

Assert-Condition (Test-EffectiveTextRegex $figma '(?i)Visual and E2E evidence are distinct channels') 'fp-figma must keep visual and E2E evidence distinct'
Assert-Condition (Test-EffectiveTextRegex $figma '(?i)Task ID \+ Case ID.*?does not duplicate visual-manifest fields') 'fp-figma must link evidence only by Task ID + Case ID'
Assert-Condition (-not [string]::IsNullOrWhiteSpace($planTemplateBody)) 'frontend plan template must contain exactly one canonical markdown template body'
Assert-Condition (Test-EffectiveLineRegex $planTemplateBody '^ {0,3}###\s+2\.5 Visual Evidence Manifest\s*$') 'frontend plan template lost the Visual Evidence Manifest heading'
Assert-Condition (Test-EffectiveLineRegex $planTemplateBody '^ {0,3}###\s+2\.6 UI/E2E Delivery Contract\s*$') 'frontend plan template lost the separate UI/E2E Delivery Contract heading'
Assert-Condition (Test-EffectiveTextRegex $planTemplateBody '(?i)Task ID \+ Case ID.*?does not duplicate visual-manifest fields') 'frontend plan template must link rather than duplicate visual evidence'
Assert-Condition (Test-EffectiveTextRegex $plan '(?i)static-only.*?N/A.*?interactive.*?business-flow.*?REQUIRED') 'frontend planning must preserve level-specific E2E applicability'
Assert-Condition (Test-EffectiveTextRegex $execute '(?i)static-only.*?VISUAL_REVIEW_PASS.*?E2E Applicability: N/A') 'direct execution must retain the static-only evidence boundary'
Assert-Condition (Test-EffectiveTextRegex $execute '(?i)interactive.*?business-flow.*?FRONTEND_E2E_PASS') 'direct execution must require real E2E for interactive and business-flow work'
Assert-Condition (Test-EffectiveTextRegex $executeSdd '(?i)fresh independent `e2e-verifier`.*?FRONTEND_E2E_PASS') 'SDD execution must retain an independent real-E2E verifier'
Assert-Condition (Test-EffectiveTextRegex $finalReview '(?i)UI/E2E Gate.*?PASS_WITH_NOTES.*?forbidden') 'final review must prohibit a PASS_WITH_NOTES UI/E2E bypass'
Assert-Condition (Test-EffectiveTextRegex $archive '(?i)user confirmation cannot override or waive this gate') 'archive must prohibit a manual UI/E2E waiver'
Assert-Condition (Test-NoPermissiveArchiveWaiver $finalReview) 'final-review effective text permits a core UI/E2E archive waiver'
Assert-Condition (Test-NoPermissiveArchiveWaiver $archive) 'archive effective text permits a core UI/E2E archive waiver'

$expectedValidatorBlocks = @(
    @(
        "`$uiE2EContractValidator = Join-Path `$root 'scripts\test-ui-e2e-contract.ps1'",
        "Assert-Condition (Test-Path `$uiE2EContractValidator) 'focused UI/E2E contract validator is missing'",
        '& powershell -NoProfile -ExecutionPolicy Bypass -File $uiE2EContractValidator',
        "Assert-Condition (`$LASTEXITCODE -eq 0) 'focused UI/E2E contract validator failed'"
    ),
    @(
        "`$executeUiE2EContractValidator = Join-Path `$root 'scripts\test-execute-ui-e2e-contract.ps1'",
        "Assert-Condition (Test-Path `$executeUiE2EContractValidator) 'focused direct-execution UI/E2E contract validator is missing'",
        '& powershell -NoProfile -ExecutionPolicy Bypass -File $executeUiE2EContractValidator',
        "Assert-Condition (`$LASTEXITCODE -eq 0) 'focused direct-execution UI/E2E contract validator failed'"
    ),
    @(
        "`$executeSddUiE2EContractValidator = Join-Path `$root 'scripts\test-execute-sdd-ui-e2e-contract.ps1'",
        "Assert-Condition (Test-Path `$executeSddUiE2EContractValidator) 'focused SDD execution UI/E2E contract validator is missing'",
        '& powershell -NoProfile -ExecutionPolicy Bypass -File $executeSddUiE2EContractValidator',
        "Assert-Condition (`$LASTEXITCODE -eq 0) 'focused SDD execution UI/E2E contract validator failed'"
    ),
    @(
        "`$finalReviewContractValidator = Join-Path `$root 'scripts\test-final-review-contract.ps1'",
        "Assert-Condition (Test-Path `$finalReviewContractValidator) 'focused fp-final-review contract validator is missing'",
        '& powershell -NoProfile -ExecutionPolicy Bypass -File $finalReviewContractValidator',
        "Assert-Condition (`$LASTEXITCODE -eq 0) 'focused fp-final-review contract validator failed'"
    ),
    @(
        "`$uiE2EIntegrationValidator = Join-Path `$root 'scripts\test-ui-e2e-integration-contract.ps1'",
        "Assert-Condition (Test-Path `$uiE2EIntegrationValidator) 'focused UI/E2E cross-flow integration validator is missing'",
        '& powershell -NoProfile -ExecutionPolicy Bypass -File $uiE2EIntegrationValidator',
        "Assert-Condition (`$LASTEXITCODE -eq 0) 'focused UI/E2E cross-flow integration validator failed'"
    )
)
foreach ($block in $expectedValidatorBlocks) {
    Assert-Condition (Test-ValidatorRegistration $validator $block) "validate-plugin must execute the UI/E2E focused validator block beginning: $($block[0])"
}

Assert-Condition (Test-EffectiveLineRegex $readme '^ {0,3}##\s+Staged UI/E2E delivery\s*$') 'README must document the staged UI/E2E delivery gate'
Assert-Condition (Test-EffectiveLineRegex $agents '^ {0,3}##\s+UI/E2E execution and archive gates\s*$') 'AGENTS.md must document the UI/E2E fallback gate'
Assert-Condition (Test-EffectiveLineRegex $userGuide '^ {0,3}###\s+UI/E2E delivery gate\s*$') 'user guide must document the UI/E2E delivery gate'
foreach ($documentation in @($readme, $agents, $userGuide)) {
    Assert-Condition (Test-EffectiveTextRegex $documentation '(?i)interactive.*?business-flow.*?real browser.*?(?:no.mock|zero.mock)') 'public documentation must require real no-mock browser E2E for interactive/business work'
    Assert-Condition (Test-EffectiveTextRegex $documentation '(?i)@playwright/test.*?Chromium.*?target frontend project') 'public documentation must describe project-local automatic Playwright bootstrap'
    Assert-Condition (Test-EffectiveLineRegex $documentation '(?i)^(?=.*static-only)(?=.*N/A)(?=.*(?:reason|evidence)).*$') 'public documentation must limit static-only E2E N/A to a recorded reason'
    Assert-Condition (Test-EffectiveTextRegex $documentation '(?i)cannot.*?(?:waive|override).*?(?:archive|core UI/E2E)') 'public documentation must make UI/E2E blockers non-waivable before archive'
}

$sharedReferenceLine = 'Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/ui-e2e-contract.md` once before executing UI-bearing work; it owns delivery levels, allowed lifecycle paths, real-E2E evidence, zero-mock rules, coverage status semantics, bootstrap, retry, and non-waivable blocking.'
$executeWithoutReference = Replace-Required $execute $sharedReferenceLine 'Read the shared contract from a prose summary only.' 'remove direct shared reference'
$executeWithCommentAndFenceFake = $executeWithoutReference + "`n<!-- $sharedReferenceLine -->`n~~~text`n$sharedReferenceLine`n~~~"
Require-MutationBaseline (Test-SharedContractReference $execute) 'direct execution shared reference baseline'
Assert-Condition (-not (Test-SharedContractReference $executeWithCommentAndFenceFake)) 'comment/fence-only shared reference must not satisfy integration validation'

Require-MutationBaseline (Test-ValidatorRegistration $validator $expectedValidatorBlocks[0]) 'shared validator registration baseline'
$hasIntegrationRegistration = Test-ValidatorRegistration $validator $expectedValidatorBlocks[4]
if ($hasIntegrationRegistration) {
    $registrationStart = "`$uiE2EIntegrationValidator = Join-Path `$root 'scripts\test-ui-e2e-integration-contract.ps1'"
    $validatorWithoutIntegration = Replace-Required $validator $registrationStart '$removedUiE2EIntegrationValidator = $null' 'remove integration validator registration'
    Assert-Condition (-not (Test-ValidatorRegistration $validatorWithoutIntegration $expectedValidatorBlocks[4])) 'removed integration validator registration must fail validation'
}

$archiveWithManualWaiver = $archive + "`nThe archive may continue after missing FRONTEND_E2E_PASS."
Require-MutationBaseline (Test-NoPermissiveArchiveWaiver $archive) 'archive no-waiver baseline'
Assert-Condition (-not (Test-NoPermissiveArchiveWaiver $archiveWithManualWaiver)) 'manual archive waiver after missing FRONTEND_E2E_PASS must fail validation'

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Output 'UI/E2E cross-flow integration validation passed.'
