$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "Module review contract validation failed: $message"
    }
}

function Read-Utf8([string]$relativePath) {
    return [System.IO.File]::ReadAllText((Join-Path $root $relativePath), [System.Text.Encoding]::UTF8)
}

function Assert-Anchors([string]$text, [string[]]$anchors, [string]$surface) {
    foreach ($anchor in $anchors) {
        Assert-Condition ($text.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "$surface lost anchor: $anchor"
    }
}

function Test-ReadOnlyPhases([string]$text) {
    return $text.IndexOf('`SCOPING`, `BASELINING`, `REVIEWING`, and `TRIAGING` are read-only for product source and existing tests.', [System.StringComparison]::OrdinalIgnoreCase) -ge 0
}

function Test-ApprovalGate([string]$text) {
    return $text.IndexOf('observable behavior impact is `none`', [System.StringComparison]::OrdinalIgnoreCase) -ge 0 -and
        $text.IndexOf('user explicitly approves its stable ID and proposed behavior', [System.StringComparison]::OrdinalIgnoreCase) -ge 0
}

function Test-AwaitingCompletion([string]$text) {
    return $text -match '(?is)COMPLETE_WITH_AWAITING.{0,900}(?:their production behavior is unchanged|keeps production behavior unchanged).{0,900}(?:exact IDs|exact finding IDs).{0,900}(?:must not|cannot)[^\r\n]{0,120}(?:all defects|fully fixed|all findings)[^\r\n]{0,80}(?:fixed|complete)'
}

function Test-ReviewOnlyFixPermission([string]$text) {
    return $text -match '(?is)review-only[^\r\n.]{0,120}(?:may|can|is allowed to)[^\r\n.]{0,80}(?:enter `?FIXING`?|edit|modify|fix)[^\r\n.]{0,80}(?:product|production|source|Finding)?'
}

function Test-NonIdBehaviorApproval([string]$text) {
    return $text -match '(?is)observable behavior[^\r\n.]{0,160}(?:may|can|is allowed to)[^\r\n.]{0,120}(?:team|lead|manager|category|generic)[^\r\n.]{0,80}approv'
}

function Test-FixBeforeApproval([string]$text) {
    return $text -match '(?is)(?:TDD|FIXING|production fix)[^\r\n.]{0,100}(?:may|can|is allowed to)[^\r\n.]{0,100}(?:before|without)[^\r\n.]{0,60}(?:approval|approved)'
}

function Test-ProgressOwnsFinding([string]$text) {
    return $text -match '(?is)progress\.md[^\r\n.]{0,100}(?:owns?|is the owner of|authoritative for)[^\r\n.]{0,80}Finding'
}

function Test-AwaitingOverclaim([string]$text) {
    return $text -match '(?is)COMPLETE_WITH_AWAITING[^\r\n.]{0,140}(?:means|proves|may claim|can claim)[^\r\n.]{0,100}(?:all defects are fixed|fully fixed|fully remediated)'
}

function Test-CannotVerifyAsLifecycle([string]$text) {
    return $text -match '(?is)CANNOT_VERIFY[^\r\n.]{0,100}(?:is|becomes|serves as)[^\r\n.]{0,80}(?:a |an )?(?:lifecycle|workflow) state'
}

function Test-ReplacesFinalReview([string]$text) {
    return $text -match '(?is)fp-module-review[^\r\n.]{0,120}(?:replaces?|may replace|can replace)[^\r\n.]{0,80}fp-final-review'
}

$required = @(
    'commands\fp-module-review.md',
    'skills\fp-module-review\SKILL.md',
    'skills\fp-module-review\review-entry-template.md',
    'skills\fp-module-review\scope-template.md',
    'skills\fp-module-review\baseline-template.md',
    'skills\fp-module-review\waves-template.md',
    'skills\fp-module-review\finding-template.md',
    'skills\fp-module-review\summary-template.md',
    'skills\fp-module-review\progress-event-template.md',
    'docs\user_guide\fp-module-review.md'
)

foreach ($path in $required) {
    Assert-Condition (Test-Path (Join-Path $root $path)) "required surface is missing: $path"
}

$skill = Read-Utf8 'skills\fp-module-review\SKILL.md'
$command = Read-Utf8 'commands\fp-module-review.md'
$entry = Read-Utf8 'skills\fp-module-review\review-entry-template.md'
$scope = Read-Utf8 'skills\fp-module-review\scope-template.md'
$baseline = Read-Utf8 'skills\fp-module-review\baseline-template.md'
$waves = Read-Utf8 'skills\fp-module-review\waves-template.md'
$finding = Read-Utf8 'skills\fp-module-review\finding-template.md'
$summary = Read-Utf8 'skills\fp-module-review\summary-template.md'
$progress = Read-Utf8 'skills\fp-module-review\progress-event-template.md'
$moduleGuide = Read-Utf8 'docs\user_guide\fp-module-review.md'
$readme = Read-Utf8 'README.md'
$mainGuide = Read-Utf8 'docs\user_guide\init-prd-start.md'

Assert-Anchors $skill @(
    'SCOPING',
    'BASELINING',
    'REVIEWING',
    'TRIAGING',
    'WAITING_APPROVAL',
    'FIXING',
    'VERIFYING',
    'BLOCKED',
    'COMPLETE_WITH_AWAITING',
    'COMPLETE'
) 'lifecycle'

Assert-Anchors $skill @(
    'read-only for product source and existing tests',
    'observable behavior',
    'explicitly approves its stable ID',
    'RED',
    'GREEN',
    'adjacent regression',
    'SAFE',
    'UNSAFE',
    'UNKNOWN',
    'must not run',
    'review-only',
    'resume'
) 'controller gates'

Assert-Anchors $skill @(
    'one bounded question',
    'must not silently broaden',
    'CodeGraph',
    'navigation only',
    'current source',
    'native search',
    'dirty-after-write',
    'post-write-sync',
    'append-only',
    'working-tree fingerprint',
    'invalidate',
    'earliest necessary state'
) 'scope and resume safety'

Assert-Anchors $entry @('Current Status', 'Quick Summary', 'Canonical Artifact Manifest', 'Finding Counts', 'Resume Entry') 'review entry'
Assert-Anchors $scope @('Targets', 'Direct Integration Points', 'Review Dimensions', 'Exclusions', 'Allowed Write Paths', 'Protected Paths', 'External-System Authorization') 'scope owner'
Assert-Anchors $baseline @('Snapshot', 'Observable Compatibility Contracts', 'Existing Test Baseline', 'Command Safety Ledger', 'Evidence Gaps') 'baseline owner'
Assert-Anchors $waves @('Owned targets/integrations', 'Dimensions', 'Depends on', 'Status', 'Evidence', 'Candidate Reconciliation') 'waves owner'

Assert-Anchors $finding @(
    'MR-FNNN',
    'candidate',
    'confirmed',
    'awaiting-user-confirmation',
    'approved',
    'fixed',
    'rejected',
    'blocked',
    'Trigger',
    'Wrong result',
    'Rollback',
    'Residual risk'
) 'finding owner'

Assert-Anchors $summary @(
    'COMPLETE_WITH_AWAITING',
    'exact IDs',
    'CANNOT_VERIFY',
    'current HEAD',
    'working tree',
    'Changed and Protected Paths'
) 'completion summary'
Assert-Anchors $progress @('append-only', 'State', 'HEAD', 'worktree', 'Next') 'resume evidence'
Assert-Anchors $command @('fp-module-review', 'large module', 'multiple related modules', 'does not replace `fp-final-review`') 'command checksum'

Assert-Anchors $moduleGuide @(
    '/fp-module-review',
    'fp:fp-module-review',
    'targets',
    'slug',
    'focus',
    'mode',
    'baseRef',
    'full',
    'review-only',
    'resume',
    'fp-docs/module-reviews/<slug>/',
    'review.md',
    'scope.md',
    'baseline.md',
    'waves.md',
    'findings/MR-FNNN.md',
    'summary.md',
    '.fp-module-review/progress.md',
    'SCOPING',
    'WAITING_APPROVAL',
    'VERIFYING',
    'COMPLETE_WITH_AWAITING',
    'CANNOT_VERIFY',
    'candidate',
    'confirmed',
    'awaiting-user-confirmation',
    'approved',
    'fixed',
    'rejected',
    'blocked',
    'observable behavior',
    'fp-final-review'
) 'module-review guide'
Assert-Condition ($readme.Contains('docs/user_guide/fp-module-review.md')) 'README lacks the fp-module-review user guide link'
Assert-Condition ($mainGuide.Contains('fp-module-review.md')) 'main user guide lacks the fp-module-review guide link'

foreach ($surface in @(
    @{ Name = 'module-review guide'; Text = $moduleGuide },
    @{ Name = 'README'; Text = $readme },
    @{ Name = 'main guide'; Text = $mainGuide }
)) {
    Assert-Condition (-not (Test-ReviewOnlyFixPermission $surface.Text)) "$($surface.Name) permits fixing in review-only mode"
    Assert-Condition (-not (Test-NonIdBehaviorApproval $surface.Text)) "$($surface.Name) permits non-ID behavior approval"
    Assert-Condition (-not (Test-FixBeforeApproval $surface.Text)) "$($surface.Name) permits fixing before approval"
    Assert-Condition (-not (Test-ProgressOwnsFinding $surface.Text)) "$($surface.Name) makes progress.md own Finding state"
    Assert-Condition (-not (Test-AwaitingOverclaim $surface.Text)) "$($surface.Name) overclaims COMPLETE_WITH_AWAITING"
    Assert-Condition (-not (Test-CannotVerifyAsLifecycle $surface.Text)) "$($surface.Name) makes CANNOT_VERIFY a lifecycle state"
    Assert-Condition (-not (Test-ReplacesFinalReview $surface.Text)) "$($surface.Name) says module review replaces fp-final-review"
}

$publicModuleSurfaces = $moduleGuide + "`n" + $readme + "`n" + $mainGuide
foreach ($mutation in @(
    @{ Text = $publicModuleSurfaces + "`nreview-only may enter FIXING and edit production source."; Detector = { param($text) Test-ReviewOnlyFixPermission $text }; Name = 'review-only fixing' },
    @{ Text = $publicModuleSurfaces + "`nAn observable behavior change may use manager approval instead of a stable Finding ID."; Detector = { param($text) Test-NonIdBehaviorApproval $text }; Name = 'non-ID approval' },
    @{ Text = $publicModuleSurfaces + "`nTDD FIXING may start before approval."; Detector = { param($text) Test-FixBeforeApproval $text }; Name = 'fix before approval' },
    @{ Text = $publicModuleSurfaces + "`n.fp-module-review/progress.md owns Finding state."; Detector = { param($text) Test-ProgressOwnsFinding $text }; Name = 'progress Finding owner' },
    @{ Text = $publicModuleSurfaces + "`nCOMPLETE_WITH_AWAITING means all defects are fixed."; Detector = { param($text) Test-AwaitingOverclaim $text }; Name = 'awaiting overclaim' },
    @{ Text = $publicModuleSurfaces + "`nCANNOT_VERIFY is a lifecycle state."; Detector = { param($text) Test-CannotVerifyAsLifecycle $text }; Name = 'CANNOT_VERIFY lifecycle' },
    @{ Text = $publicModuleSurfaces + "`nfp-module-review replaces fp-final-review."; Detector = { param($text) Test-ReplacesFinalReview $text }; Name = 'final-review replacement' }
)) {
    $detector = $mutation.Detector
    $mutationText = $mutation.Text
    $mutationName = $mutation.Name
    $detected = & $detector $mutationText
    Assert-Condition $detected "public-doc detector misses mutation: $mutationName"
}

$moduleGuideLineCount = @($moduleGuide -split "`r?`n").Count
Assert-Condition ($moduleGuideLineCount -le 500) "module-review guide has $moduleGuideLineCount lines (limit: 500)"
Assert-Condition ($moduleGuide.Length -le 30000) "module-review guide has $($moduleGuide.Length) characters (limit: 30,000)"

Assert-Condition (Test-ReadOnlyPhases $skill) 'read-only phase boundary is not explicit'
Assert-Condition (Test-ApprovalGate $skill) 'observable-behavior approval gate is incomplete'
Assert-Condition (Test-AwaitingCompletion ($skill + "`n" + $summary)) 'awaiting completion may overstate fixed findings'

$readOnlyMutation = $skill.Replace('are read-only for product source and existing tests', 'may edit product source and existing tests')
Assert-Condition ($readOnlyMutation -ne $skill) 'read-only mutation fixture did not mutate the skill'
Assert-Condition (-not (Test-ReadOnlyPhases $readOnlyMutation)) 'read-only helper accepted source edits during discovery'

$approvalMutation = $skill.Replace('user explicitly approves its stable ID and proposed behavior', 'engineering lead approves the category')
Assert-Condition ($approvalMutation -ne $skill) 'approval mutation fixture did not mutate the skill'
Assert-Condition (-not (Test-ApprovalGate $approvalMutation)) 'approval helper accepted non-user or non-ID approval'

$awaitingMutation = ($skill + "`n" + $summary).Replace('must not claim all defects are fixed', 'may claim all defects are fixed')
Assert-Condition ($awaitingMutation -ne ($skill + "`n" + $summary)) 'awaiting mutation fixture did not mutate the surface'
Assert-Condition (-not (Test-AwaitingCompletion $awaitingMutation)) 'completion helper accepted all-fixed claim with awaiting findings'

$changedBehaviorMutation = ($skill + "`n" + $summary).Replace('their production behavior is unchanged', 'their production behavior may change')
Assert-Condition ($changedBehaviorMutation -ne ($skill + "`n" + $summary)) 'unchanged-behavior mutation fixture did not mutate the surface'
Assert-Condition (-not (Test-AwaitingCompletion $changedBehaviorMutation)) 'completion helper accepted changed production behavior with awaiting findings'

Write-Output 'Module review contract validation passed.'
