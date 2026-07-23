$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "Review contract validation failed: $message"
    }
}

function Read-Utf8([string]$path) {
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Assert-Anchors([string]$text, [string[]]$anchors, [string]$surface) {
    foreach ($anchor in $anchors) {
        Assert-Condition ($text.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "$surface lost anchor: $anchor"
    }
}

function Test-OwnerDiscoveryContract([string]$text) {
    foreach ($anchor in @(
        'selected change canonical artifacts',
        'owner inventory',
        'selected-unmapped observed paths',
        'exact normalized path',
        'fp-docs/changes/',
        'sibling active changes',
        'do not search archive/history',
        'must not bulk-read all changes',
        'canonical task-owner `Files`/scope entries',
        'evidence package/ledger Scope Matrix',
        'candidate change',
        'canonical-first',
        'minimal proposal/design/task-owner excerpts',
        'Owner Discovery Evidence',
        'Candidate lookup',
        'Canonical owner proof',
        'Resolved owners',
        'Classification',
        'lookup budget',
        'relevant contract excerpts'
    )) {
        if ($text.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) { return $false }
    }
    return $text -match '(?is)selected-unmapped observed paths.{0,420}exact normalized path.{0,620}sibling active changes' -and
        $text -match '(?is)(?:lookup budget|owner evidence).{0,300}(?:insufficient|cannot be proven).{0,260}unowned/unmapped'
}

function Test-CrossChangeIsolationContract([string]$text) {
    return $text -match '(?is)cross-change-only.{0,520}(?:explicit|proven)[^\r\n]{0,140}(?:artifact|owner).{0,520}excluded from the current change verdict'
}

function Test-DispatchCommitContract([string]$text) {
    foreach ($anchor in @(
        'git rev-parse <dispatchHead>^',
        'git rev-list --count <packageParentHead>..<dispatchHead>',
        'git diff --name-only <packageParentHead>..<dispatchHead>',
        'dispatchHead^ == packageParentHead',
        'rev-list --count packageParentHead..dispatchHead == 1',
        'allowed package/pending-ledger paths'
    )) {
        if ($text.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) { return $false }
    }
    return $true
}

function Test-PhaseResumeContract([string]$text) {
    foreach ($anchor in @(
        'reviewPhase',
        'pending-dispatch',
        'review-completed',
        'result-committed',
        'current clean HEAD is the unique direct child of packageParentHead',
        'evidenceCommitHead=dispatchHead=current HEAD',
        'historical dispatchHead remains the current committed HEAD',
        'only final report/result-ledger paths may be uncommitted',
        'persist the result before advancing',
        'must not set dispatchHead=current HEAD',
        'dispatchHead is an ancestor of current HEAD',
        'dispatchHead^ == packageParentHead',
        'successors after dispatchHead',
        'phase-allowed result evidence/fix paths',
        'result commit records the prior dispatchHead',
        'does not record its own SHA'
    )) {
        if ($text.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) { return $false }
    }
    return $true
}

function Test-FinalFlowOrder([string]$text) {
    $previousIndex = -1
    foreach ($anchor in @('capture reviewedTargetHead', 'generate the final package', 'evidence-only commit', 'resolve evidenceCommitHead', 'dispatch fp-review')) {
        $currentIndex = $text.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase)
        if ($currentIndex -le $previousIndex) { return $false }
        $previousIndex = $currentIndex
    }
    return $true
}

$reviewSkillPath = Join-Path $root 'skills\fp-review\SKILL.md'
$reviewerPath = Join-Path $root 'skills\fp-review\final-reviewer.md'
$reportTemplatePath = Join-Path $root 'skills\fp-review\final-review-template.md'
$finalPackagePath = Join-Path $root 'skills\fp-review\final-review-package-template.md'
$sddSkillPath = Join-Path $root 'skills\fp-execute-sdd\SKILL.md'
$sddPackagePath = Join-Path $root 'skills\fp-execute-sdd\review-package-template.md'
$codeGraphPath = Join-Path $root 'skills\_shared\codegraph.md'
$commandPath = Join-Path $root 'commands\fp-review.md'
$validatorPath = Join-Path $root 'scripts\validate-plugin.ps1'

foreach ($requiredPath in @(
    $reviewSkillPath,
    $reviewerPath,
    $reportTemplatePath,
    $finalPackagePath,
    $sddSkillPath,
    $sddPackagePath,
    $codeGraphPath,
    $commandPath,
    $validatorPath
)) {
    Assert-Condition (Test-Path $requiredPath) "required review surface is missing: $requiredPath"
}

$reviewSkill = Read-Utf8 $reviewSkillPath
$reviewer = Read-Utf8 $reviewerPath
$reportTemplate = Read-Utf8 $reportTemplatePath
$finalPackage = Read-Utf8 $finalPackagePath
$sddSkill = Read-Utf8 $sddSkillPath
$sddPackage = Read-Utf8 $sddPackagePath
$codeGraph = Read-Utf8 $codeGraphPath
$command = Read-Utf8 $commandPath
$validator = Read-Utf8 $validatorPath

$reviewInputs = @(
    'reviewScopeId',
    'reviewAttempt',
    'maxReviewAttempts',
    'priorReviewPath',
    'priorFindingDispositions',
    'finalReviewPackage',
    'lastReviewedHead',
    'reviewPhase'
)
Assert-Anchors $reviewSkill $reviewInputs 'fp-review input contract'
Assert-Anchors $reviewer $reviewInputs 'final reviewer input contract'
Assert-Anchors $finalPackage $reviewInputs 'final review package'
Assert-Condition ($reviewSkill.Contains('maxReviewAttempts=3') -and $reviewer.Contains('maxReviewAttempts=3')) 'review attempt ceiling is not fixed at 3'
Assert-Anchors $reviewSkill @('independent final scope', 'attempt 1', 'does not auto-fix', 'does not auto-retry') 'direct fp-review defaults'
Assert-Anchors $command @('independent final scope', 'attempt 1', 'does not auto-fix', 'does not auto-retry') 'fp-review command checksum'

foreach ($surface in @(
    @{ Name = 'fp-review'; Text = $reviewSkill },
    @{ Name = 'final reviewer'; Text = $reviewer },
    @{ Name = 'final package'; Text = $finalPackage }
)) {
    Assert-Anchors $surface.Text @(
        'lastReviewedHead..HEAD',
        'canonical structure',
        'snapshot/working-tree',
        'scope/out-of-scope',
        'task ownership/dependencies',
        'evidence freshness',
        'command safety'
    ) $surface.Name
}
Assert-Anchors $reviewSkill @('Attempt 1', 'complete baseline evidence', 'Attempts 2/3', 'unresolved findings') 'incremental review method'

$scopeColumns = @('Declared path/contract', 'Observed diff path', 'Mapping', 'Classification', 'Relevant change owner', 'Evidence')
Assert-Anchors $finalPackage $scopeColumns 'final package Scope Matrix schema'
Assert-Anchors $reportTemplate $scopeColumns 'final report Scope Matrix schema'
foreach ($surface in @(
    @{ Name = 'fp-review'; Text = $reviewSkill },
    @{ Name = 'final reviewer'; Text = $reviewer },
    @{ Name = 'final package'; Text = $finalPackage },
    @{ Name = 'final report'; Text = $reportTemplate }
)) {
    Assert-Anchors $surface.Text @('Scope Matrix', 'declared', 'observed', 'mapped', 'unmapped', 'missing', 'mapped-current', 'cross-change-only', 'shared', 'unowned/unmapped', 'branch inventory/counts', 'selected change', 'each relevant change contract', 'current verdict') $surface.Name
    Assert-Condition ($surface.Text -match '(?is)mapped-current.{0,260}(?:selected change|current change).{0,260}(?:affects|impact)[^\r\n]{0,80}(?:current )?verdict') "$($surface.Name) does not make mapped-current affect the selected-change verdict"
    Assert-Condition ($surface.Text -match '(?is)cross-change-only.{0,360}(?:explicit|proven)[^\r\n]{0,100}(?:artifact|owner).{0,360}(?:exclude|excluded)[^\r\n]{0,120}(?:current change|current-change)[^\r\n]{0,80}verdict') "$($surface.Name) does not isolate proven cross-change-only paths from the current verdict"
    Assert-Condition ($surface.Text -match '(?is)cross-change-only.{0,420}branch inventory/counts') "$($surface.Name) drops cross-change-only paths from branch inventory/counts"
    Assert-Condition ($surface.Text -match '(?is)(?:owner evidence|ownership evidence).{0,200}(?:insufficient|missing|cannot be proven).{0,220}unowned/unmapped') "$($surface.Name) may guess a cross-change owner"
    Assert-Condition ($surface.Text -match '(?is)shared.{0,300}each relevant change contract.{0,260}(?:affects|impact)[^\r\n]{0,80}(?:current )?verdict') "$($surface.Name) does not review shared paths against every relevant contract/current verdict"
    Assert-Condition ($surface.Text -match '(?is)unowned/unmapped.{0,300}(?:scope finding|finding).{0,220}(?:affects|impact)[^\r\n]{0,80}(?:current )?verdict') "$($surface.Name) does not keep unowned risk in the current verdict"
}
Assert-Anchors $reviewSkill @('complete branch inventory', 'selected change + shared + unowned') 'change-scoped verdict boundary'
foreach ($surface in @(
    @{ Name = 'fp-review'; Text = $reviewSkill },
    @{ Name = 'final reviewer'; Text = $reviewer },
    @{ Name = 'final package'; Text = $finalPackage },
    @{ Name = 'final report'; Text = $reportTemplate }
)) {
    Assert-Condition (Test-OwnerDiscoveryContract $surface.Text) "$($surface.Name) is missing bounded sibling owner discovery"
    Assert-Condition (Test-CrossChangeIsolationContract $surface.Text) "$($surface.Name) does not isolate proven cross-change-only paths"
}

$headInputs = @('reviewedTargetHead', 'packageParentHead', 'evidenceCommitHead', 'dispatchHead')
foreach ($surface in @(
    @{ Name = 'fp-review'; Text = $reviewSkill },
    @{ Name = 'final reviewer'; Text = $reviewer },
    @{ Name = 'final package'; Text = $finalPackage },
    @{ Name = 'final report'; Text = $reportTemplate },
    @{ Name = 'fp-execute-sdd'; Text = $sddSkill }
)) {
    Assert-Anchors $surface.Text $headInputs "$($surface.Name) HEAD model"
}
Assert-Anchors $reviewSkill @(
    'lastReviewedHead..<reviewedTargetHead>',
    'headRef resolves to reviewedTargetHead',
    'packageParentHead == reviewedTargetHead',
    'evidenceCommitHead == dispatchHead == current git HEAD',
    'reviewedTargetHead..dispatchHead',
    'allowed evidence paths',
    'product source unchanged',
    'dispatch tree clean',
    'reviewedTargetHead=dispatchHead=HEAD',
    'evidenceCommitHead=N/A'
) 'fp-review target/evidence/dispatch validation'
Assert-Anchors $reviewer @('packageParentHead == reviewedTargetHead', 'evidenceCommitHead == dispatchHead == current git HEAD', 'reviewedTargetHead..dispatchHead', 'allowed evidence paths', 'product source unchanged', 'dispatch tree clean') 'final reviewer HEAD validation'
foreach ($surface in @(
    @{ Name = 'fp-review'; Text = $reviewSkill },
    @{ Name = 'final reviewer'; Text = $reviewer },
    @{ Name = 'final package'; Text = $finalPackage },
    @{ Name = 'final report'; Text = $reportTemplate }
)) {
    Assert-Condition (Test-DispatchCommitContract $surface.Text) "$($surface.Name) is missing parent/count/allowed-delta verification"
}
Assert-Condition ($finalPackage.Contains('- evidenceCommitHead: `POST_COMMIT_EXTERNAL`')) 'final package must use an external evidence-commit sentinel'
Assert-Condition ($finalPackage.Contains('- dispatchHead: `POST_COMMIT_EXTERNAL`')) 'final package must use an external dispatch-head sentinel'
Assert-Anchors $finalPackage @('self-reference', 'must not embed', 'never rewrite the package', 'packageParentHead = reviewedTargetHead', 'target dirty fingerprint: `CLEAN`') 'final package self-reference prohibition'

$finalFlow = [regex]::Match($sddSkill, '(?s)## Completion and Final Review\s*(?<body>.*?)\s*## CodeGraph write freshness')
Assert-Condition $finalFlow.Success 'fp-execute-sdd final-review flow is missing'
$flowText = $finalFlow.Groups['body'].Value
Assert-Condition (Test-FinalFlowOrder $flowText) 'fp-execute-sdd final-review order is invalid'
Assert-Anchors $flowText @(
    'packageParentHead=reviewedTargetHead',
    'evidenceCommitHead=dispatchHead',
    'tree CLEAN',
    'only the final package and allowed pending ledger evidence',
    'POST_COMMIT_EXTERNAL',
    'never rewrite the package',
    'current clean HEAD',
    'allowed evidence-only delta',
    'without relying on a ledger self-recorded commit SHA'
) 'fp-execute-sdd non-self-referential evidence commit'

foreach ($surface in @(
    @{ Name = 'fp-review'; Text = $reviewSkill },
    @{ Name = 'final reviewer'; Text = $reviewer },
    @{ Name = 'final package'; Text = $finalPackage },
    @{ Name = 'final report'; Text = $reportTemplate },
    @{ Name = 'fp-execute-sdd'; Text = $sddSkill }
)) {
    Assert-Condition (Test-PhaseResumeContract $surface.Text) "$($surface.Name) is missing phase-aware resume semantics"
}

foreach ($surface in @(
    @{ Name = 'fp-review'; Text = $reviewSkill },
    @{ Name = 'final reviewer'; Text = $reviewer },
    @{ Name = 'final package'; Text = $finalPackage },
    @{ Name = 'SDD review package'; Text = $sddPackage }
)) {
    Assert-Anchors $surface.Text @('SAFE', 'UNSAFE', 'UNKNOWN', '--fix', '--write', 'snapshot update', 'migration', 'seed', 'formatter', 'generator', 'cache', 'coverage', 'dist', 'unknown wrapper', 'service', 'database', 'external mutation', 'must not run') $surface.Name
}

foreach ($surface in @(
    @{ Name = 'fp-review'; Text = $reviewSkill },
    @{ Name = 'final reviewer'; Text = $reviewer },
    @{ Name = 'final package'; Text = $finalPackage },
    @{ Name = 'CodeGraph shared contract'; Text = $codeGraph }
)) {
    Assert-Anchors $surface.Text @('explore', 'impact', 'affected', 'candidate', 'current source', 'native search', 'fallback', 'must not block') $surface.Name
}
Assert-Anchors $reviewSkill @('current diff', 'tests', 'command output') 'source verification contract'

Assert-Anchors $sddSkill $reviewInputs 'SDD final-review dispatch inputs'
Assert-Anchors $sddPackage @('reviewScopeId', 'reviewAttempt', 'lastReviewedHead', 'priorFindingDispositions') 'SDD review package state'
Assert-Anchors $sddSkill @('stable reviewScopeId', 'never resets', 'new reviewer', 'new commit', 'new session', 'new finding', 'never dispatch attempt 4') 'SDD bounded attempt orchestration'
Assert-Anchors $reviewSkill @('Attempt 3', 'non-blocking debt', 'main-flow blockers', 'blocked') 'attempt 3 verdict handling'

# Negative in-memory fixtures prove the semantic helpers reject regressions,
# rather than merely finding an unrelated combined anchor elsewhere.
$ownerLookupMutation = $reviewSkill.Replace('Owner Discovery Evidence', 'Owner Discovery Removed')
Assert-Condition ($ownerLookupMutation -ne $reviewSkill) 'owner-discovery mutation fixture did not mutate the surface'
Assert-Condition (-not (Test-OwnerDiscoveryContract $ownerLookupMutation)) 'owner-discovery helper accepted a surface with discovery evidence removed'

$crossVerdictMutation = $reviewSkill.Replace('excluded from the current change verdict', 'affects the current verdict')
Assert-Condition ($crossVerdictMutation -ne $reviewSkill) 'cross-change verdict mutation fixture did not mutate the surface'
Assert-Condition (-not (Test-CrossChangeIsolationContract $crossVerdictMutation)) 'cross-change helper accepted verdict contamination'

$parentCountMutation = $reviewSkill.Replace('git rev-parse <dispatchHead>^', 'REMOVED_PARENT_COMMAND').Replace('git rev-list --count <packageParentHead>..<dispatchHead>', 'REMOVED_COUNT_COMMAND')
Assert-Condition ($parentCountMutation -ne $reviewSkill) 'parent/count mutation fixture did not mutate the surface'
Assert-Condition (-not (Test-DispatchCommitContract $parentCountMutation)) 'dispatch helper accepted missing parent/count proof'

$resultResumeMutation = $sddSkill.Replace('must not set dispatchHead=current HEAD', 'set dispatchHead=current HEAD')
Assert-Condition ($resultResumeMutation -ne $sddSkill) 'result-committed mutation fixture did not mutate the surface'
Assert-Condition (-not (Test-PhaseResumeContract $resultResumeMutation)) 'phase helper accepted dispatchHead=current HEAD after result commit'

$orderMutation = $flowText.Replace('capture reviewedTargetHead', '__CAPTURE_TARGET__').Replace('generate the final package', 'capture reviewedTargetHead').Replace('__CAPTURE_TARGET__', 'generate the final package')
Assert-Condition ($orderMutation -ne $flowText) 'flow-order mutation fixture did not mutate the surface'
Assert-Condition (-not (Test-FinalFlowOrder $orderMutation)) 'flow-order helper accepted package generation before target capture'

Assert-Condition ($validator.Contains('test-review-contract.ps1')) 'global validator does not invoke the focused review contract'

Write-Output 'Review contract validation passed.'
