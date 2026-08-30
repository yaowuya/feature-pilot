$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "Final review contract validation failed: $message"
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

function Test-SharedFinalReviewReference([string]$text) {
    $active = Get-ActiveMarkdown $text
    return $active.Contains('${CLAUDE_PLUGIN_ROOT}/skills/fp-final-review/final-review-contract.md')
}

function Test-NoLocalSharedInvariantDuplication([string]$text) {
    $active = Get-ActiveMarkdown $text
    foreach ($invariant in @(
        'Review the complete branch inventory first'
        '- Provenance: reference.png -> approved Figma/static design source; current.png -> real target runtime.'
        'Before emitting the UI/E2E gate, reconcile the reviewed target snapshot'
        '`N/A` is valid only with zero UI-bearing inventory rows'
        '- `N/A` means the UI Case Inventory has zero UI-bearing sources'
        'Write-mode and side-effect commands such as'
        'Treat `--fix`, `--write`'
        'CodeGraph `explore`, `impact`, and `affected`'
    )) {
        if ($active.Contains($invariant)) { return $false }
    }
    return $true
}

function Test-DirectModeDispatchBranch([string]$text) {
    $active = Get-ActiveMarkdown $text
    return $active.Contains('When `reviewPhase=N/A-direct`, record the SDD dispatch checks as `N/A-direct`.') -and
        $active.Contains('Require `reviewedTargetHead=packageParentHead=dispatchHead=HEAD` and `evidenceCommitHead=N/A`.') -and
        $active.Contains('Do not run the SDD parent/count/allowed-delta assertions in direct mode.')
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
    foreach ($anchor in @('capture reviewedTargetHead', 'generate the final package', 'evidence-only commit', 'resolve evidenceCommitHead', 'dispatch fp-final-review')) {
        $currentIndex = $text.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase)
        if ($currentIndex -le $previousIndex) { return $false }
        $previousIndex = $currentIndex
    }
    return $true
}

function Get-ActiveMarkdown([string]$text) {
    # Contract prose inside an HTML comment or a fenced example cannot satisfy a
    # live skill guard. Keep only active Markdown for every gate assertion.
    $withoutComments = [regex]::Replace($text, '(?s)<!--.*?-->', '')
    $activeLines = New-Object System.Collections.Generic.List[string]
    $openFence = $null
    foreach ($line in ($withoutComments -split "`r?`n")) {
        if ($null -eq $openFence) {
            $opening = [regex]::Match($line, '^ {0,3}(?<delimiter>\x60{3,}|~{3,})(?<info>.*)$')
            if ($opening.Success) {
                $delimiter = $opening.Groups['delimiter'].Value
                if ($delimiter.StartsWith([string][char]96) -and $opening.Groups['info'].Value.Contains([string][char]96)) {
                    [void]$activeLines.Add($line)
                    continue
                }
                $openFence = $delimiter
                continue
            }
            [void]$activeLines.Add($line)
            continue
        }

        $delimiterCharacter = [regex]::Escape([string]$openFence[0])
        $closingPattern = '^ {0,3}' + $delimiterCharacter + '{' + $openFence.Length + ',}[ \t]*$'
        if ($line -match $closingPattern) {
            $openFence = $null
        }
    }
    return [string]::Join("`n", $activeLines)
}

function Test-UiE2EFinalGate([string]$text) {
    $active = Get-ActiveMarkdown $text
    $section = [regex]::Match($active, '(?ms)^### 2\.2 UI/E2E Gate[ \t]*\r?\n(?<body>.*?)(?=^### |\z)')
    if (-not $section.Success) { return $false }
    $body = $section.Groups['body'].Value

    $checks = @(
        ($body -match '(?is)shared\s+UI/E2E\s+contract'),
        ($body -match '(?is)Task ID\s*\+\s*Case ID'),
        ($body -match '(?is)UI Delivery Level'),
        ($body -match '(?is)required.*actual.*stage'),
        ($body -match '(?is)VISUAL_REVIEW_PASS'),
        ($body -match '(?is)static-only.{0,220}E2E Applicability:\s*N/A.{0,220}(?:evidence-backed|reason)'),
        ($body -match '(?is)interactive.{0,160}(?:must|required).{0,160}FRONTEND_E2E_PASS'),
        ($body -match '(?is)business-flow.{0,160}(?:must|required).{0,160}FRONTEND_E2E_PASS'),
        ($body -match '(?is)\.fp-execute/e2e/<task-id>/<case-id>/coverage-matrix\.md'),
        ($body -match '(?is)business-flow.{0,240}(?:must|required).{0,240}Mocked Core API:\s*false'),
        ($body -match '(?is)cleanup'),
        ($body -match '(?is)(?:page\.route|route).{0,160}intercept.{0,160}MSW.{0,160}Cypress.{0,160}fixture.{0,160}hard-coded API.{0,160}mock module.{0,160}(?:store|localStorage).{0,160}seed.{0,160}direct backend/API write.{0,160}mock violation.{0,240}(?:block|FAIL|BLOCKED)'),
        ($body -notmatch '(?is)(?:page\.route|route).{0,160}intercept.{0,160}MSW.{0,160}Cypress.{0,160}fixture.{0,160}hard-coded API.{0,160}mock module.{0,160}(?:store|localStorage).{0,160}seed.{0,160}direct backend/API write.{0,240}(?:allowed|permitted)'),
        ($body -match '(?is)(?:core UI/E2E gap|mock violation|unsafe unverified|required E2E).{0,360}(?:FAIL|BLOCKED)'),
        ($body -match '(?is)(?:cannot|must not).{0,200}(?:PASS_WITH_NOTES|review debt|manual (?:override|approval)|waiv(?:e|ed))')
    )
    return -not ($checks -contains $false)
}

function Test-UiE2EReviewerGate([string]$text) {
    $active = Get-ActiveMarkdown $text
    return $active -match '(?is)UI/E2E Gate.{0,520}Task ID.{0,180}Case ID.{0,180}\.fp-execute/e2e/<task-id>/<case-id>/coverage-matrix\.md.{0,260}Mocked Core API.{0,180}Cleanup'
}

function Test-UiE2EArtifactGate([string]$text) {
    $active = Get-ActiveMarkdown $text
    $section = [regex]::Match($active, '(?ms)^## UI/E2E Gate[ \t]*\r?\n(?<body>.*?)(?=^## |\z)')
    if (-not $section.Success) { return $false }
    $body = $section.Groups['body'].Value
    $checks = @(
        ($body -match '(?is)\| Task ID \| Case ID \| UI Delivery Level \| Required stage \| Actual stage \|'),
        ($body -match '(?is)\.fp-execute/e2e/<task-id>/<case-id>/coverage-matrix\.md'),
        ($body -match '(?is)Mocked Core API'),
        ($body -match '(?is)Cleanup')
    )
    return -not ($checks -contains $false)
}

function Test-ArchiveUiE2EHardGate([string]$text) {
    $active = Get-ActiveMarkdown $text
    $section = [regex]::Match($active, '(?ms)^### Step 2\.1: UI/E2E Final Gate[ \t]*\r?\n(?<body>.*?)(?=^### |\z)')
    if (-not $section.Success) { return $false }
    $body = $section.Groups['body'].Value
    $confirmation = [regex]::Match($active, '(?m)^### Step 3:')

    $checks = @(
        ($body -match '(?is)latest.{0,80}final review'),
        ($body -match '(?is)UI/E2E Gate'),
        ($body -match '(?is)(?:(?:FAIL|BLOCKED).{0,220}(?:must not|cannot).{0,220}archive|archive.{0,120}(?:must not|cannot).{0,220}(?:FAIL|BLOCKED))'),
        ($body -match '(?is)user confirmation.{0,220}(?:cannot|must not).{0,220}(?:override|waive)'),
        ($body -match '(?is)ordinary non-core.{0,220}incomplete task'),
        ($body -match '(?is)not a second completion authority')
    )
    return -not ($checks -contains $false) -and $section.Index -lt $confirmation.Index
}

function Test-UiCaseInventoryContract([string]$text) {
    $active = Get-ActiveMarkdown $text
    $hasRequiredInventory = $active -match '(?is)UI Case Inventory\s*/\s*N/A Reconciliation.{0,900}task-owner.{0,900}frontend design.{0,900}FIGCAP.{0,900}PRES.{0,900}(?:mapped-current|unowned).{0,900}Task ID.{0,240}Case ID.{0,360}(?:FAIL|BLOCKED).{0,320}N/A.{0,360}(?:zero|no) UI'
    foreach ($sentence in [regex]::Matches($active, '(?is)[^.]*N/A[^.]*\.')) {
        $value = $sentence.Value
        $grantsNa = $value -match '(?is)\b(?:may|can|allow(?:ed)?|permit(?:ted)?|valid|acceptable)\b'
        $isSafeNa = $value -match '(?is)\bonly\b.{0,180}(?:zero|no) UI-bearing.{0,180}no Figma UI scope.{0,180}no mapped-current or unowned frontend diff'
        if ($grantsNa -and -not $isSafeNa) { return $false }
    }
    return $hasRequiredInventory
}

function Test-UiCaseInventoryArtifact([string]$text) {
    $active = Get-ActiveMarkdown $text
    $section = [regex]::Match($active, '(?ms)^## UI Case Inventory / N/A Reconciliation[ \t]*\r?\n(?<body>.*?)(?=^## |\z)')
    if (-not $section.Success) { return $false }
    $body = $section.Groups['body'].Value
    return $body -match '(?is)\| Source owner / diff evidence \| UI classification \| Task ID \| Case ID \| Disposition \|'
}

function Test-NoPermissiveFinalDisposition([string]$text) {
    foreach ($sentence in [regex]::Split($text, '(?<=[.!?])\s+')) {
        $mentionsDisposition = $sentence -match '(?is)(?:PASS_WITH_NOTES|review debt|manual (?:override|approval)|user confirmation|\boverride\b|waiv(?:e|ed|er|ers))'
        $grantsDisposition = $sentence -match '(?is)\b(?:may|can|allow(?:ed)?|permit(?:ted)?|override|waiv(?:e|ed|er|ers)|valid|acceptable)\b'
        $deniesDisposition = $sentence -match '(?is)\b(?:cannot|must not|never|prohibit(?:ed)?|not (?:allowed|permitted|valid|acceptable))\b'
        if ($mentionsDisposition -and $grantsDisposition -and -not $deniesDisposition) { return $false }
    }
    return $true
}

function Test-FigmaFinalHardGate([string]$text) {
    $active = Get-ActiveMarkdown $text
    $block = [regex]::Match($active, '(?ms)Figma Completion Status:\s*`?COMPLETE \| INCOMPLETE \| BLOCKED`?.*?(?=^#{1,3} |\z)').Value
    return -not [string]::IsNullOrWhiteSpace($block) -and
        $block -match '(?is)(?:FIGCAP|PRES).{0,420}(?:INCOMPLETE|CANNOT_VERIFY|FAIL|BLOCKED).{0,420}(?:final verdict|verdict).{0,240}(?:FAIL|BLOCKED)' -and
        $block -match '(?is)(?:cannot|must not|never).{0,260}(?:PASS_WITH_NOTES|review debt|manual (?:override|approval)|waiv\w*)' -and
        (Test-NoPermissiveFinalDisposition $block)
}

function Test-FigmaFinalArtifact([string]$text) {
    $active = Get-ActiveMarkdown $text
    $section = [regex]::Match($active, '(?ms)^#{2,3} Figma Completion Gate[ \t]*\r?\n(?<body>.*?)(?=^## |\z)')
    if (-not $section.Success) { return $false }
    $body = $section.Groups['body'].Value
    return $body -match '(?is)Figma Completion Status.{0,120}COMPLETE.{0,120}INCOMPLETE.{0,120}BLOCKED'
}

function Test-ArchiveFigmaHardGate([string]$text) {
    $active = Get-ActiveMarkdown $text
    $section = [regex]::Match($active, '(?ms)^### Step 2\.2: Figma Completion Gate[ \t]*\r?\n(?<body>.*?)(?=^### |\z)')
    if (-not $section.Success) { return $false }
    $body = $section.Groups['body'].Value
    $confirmation = [regex]::Match($active, '(?m)^### Step 3:')
    $checks = @(
        ($body -match '(?is)latest.{0,100}final review'),
        ($body -match '(?is)Figma Completion Status:\s*COMPLETE'),
        ($body -match '(?is)(?:required FIGCAP|core PRES|core Visual).{0,280}(?:PASS|independent Figma review)'),
        ($body -match '(?is)(?:FAIL|CANNOT_VERIFY|BLOCKED|INCOMPLETE).{0,260}(?:must not|cannot).{0,260}archive'),
        ($body -match '(?is)user confirmation.{0,220}(?:cannot|must not).{0,220}(?:override|waive)')
    )
    return -not ($checks -contains $false) -and $section.Index -lt $confirmation.Index -and (Test-NoPermissiveFinalDisposition $active)
}

$reviewSkillPath = Join-Path $root 'skills\fp-final-review\SKILL.md'
$reviewerPath = Join-Path $root 'skills\fp-final-review\final-reviewer.md'
$reportTemplatePath = Join-Path $root 'skills\fp-final-review\final-review-template.md'
$finalPackagePath = Join-Path $root 'skills\fp-final-review\final-review-package-template.md'
$sharedReviewContractPath = Join-Path $root 'skills\fp-final-review\final-review-contract.md'
$sddSkillPath = Join-Path $root 'skills\fp-execute-sdd\SKILL.md'
$sddPackagePath = Join-Path $root 'skills\fp-execute-sdd\review-package-template.md'
$codeGraphPath = Join-Path $root 'skills\_shared\codegraph.md'
$commandPath = Join-Path $root 'commands\fp-final-review.md'
$validatorPath = Join-Path $root 'scripts\validate-plugin.ps1'
$archiveSkillPath = Join-Path $root 'skills\fp-archive\SKILL.md'

foreach ($requiredPath in @(
    $reviewSkillPath,
    $reviewerPath,
    $reportTemplatePath,
    $finalPackagePath,
    $sharedReviewContractPath,
    $sddSkillPath,
    $sddPackagePath,
    $codeGraphPath,
    $commandPath,
    $validatorPath,
    $archiveSkillPath
)) {
    Assert-Condition (Test-Path $requiredPath) "required review surface is missing: $requiredPath"
}

$reviewSkill = Read-Utf8 $reviewSkillPath
$reviewer = Read-Utf8 $reviewerPath
$reportTemplate = Read-Utf8 $reportTemplatePath
$finalPackage = Read-Utf8 $finalPackagePath
$sharedReviewContract = Read-Utf8 $sharedReviewContractPath
$sddSkill = Read-Utf8 $sddSkillPath
$sddPackage = Read-Utf8 $sddPackagePath
$codeGraph = Read-Utf8 $codeGraphPath
$command = Read-Utf8 $commandPath
$validator = Read-Utf8 $validatorPath
$archiveSkill = Read-Utf8 $archiveSkillPath
$activeReviewer = Get-ActiveMarkdown $reviewer
$activeReportTemplate = Get-ActiveMarkdown $reportTemplate
$activeFinalPackage = Get-ActiveMarkdown $finalPackage

Assert-Condition (@($sharedReviewContract -split "`r?`n").Count -le 500) 'shared final-review contract exceeds 500 lines'
Assert-Condition ($sharedReviewContract.Length -le 30000) 'shared final-review contract exceeds 30,000 characters'
foreach ($heading in @(
    '# FeaturePilot Final Review Shared Contract'
    '## Review Identity and Phase'
    '## Scope and Ownership'
    '## Every-Attempt Gates'
    '## Command Safety'
    '## CodeGraph Candidate Verification'
    '## Figma Capability and Preservation'
    '## Visual Evidence'
    '## UI Case Inventory / N/A Reconciliation'
    '## UI/E2E Gate'
)) {
    Assert-Condition ($sharedReviewContract.Contains($heading)) "shared final-review contract lost heading: $heading"
}
foreach ($anchor in @(
    'reviewScopeId'
    'reviewAttempt'
    'maxReviewAttempts=3'
    'reviewedTargetHead'
    'packageParentHead'
    'evidenceCommitHead'
    'dispatchHead'
    'N/A-direct'
    'pending-dispatch'
    'review-completed'
    'result-committed'
    'mapped-current'
    'cross-change-only'
    'shared'
    'unowned/unmapped'
    'SAFE | UNSAFE | UNKNOWN'
    'FIGCAP-*'
    'PRES-*'
    'Visual evidence: PASS | FAIL | CANNOT_VERIFY'
    'Task ID + Case ID'
    'UI/E2E Gate: PASS | N/A | FAIL | BLOCKED'
)) {
    Assert-Condition ($sharedReviewContract.Contains($anchor)) "shared final-review contract lost invariant: $anchor"
}

$sharedProjectionHeaders = @(
    '| Declared path/contract | Observed diff path | Mapping | Classification | Relevant change owner | Evidence |'
    '| Path | Candidate lookup | Canonical owner proof | Resolved owners | Classification |'
    '| Gate | Result | Evidence |'
    '| Command | Safety | Definition evidence | Result | Notes |'
    '| Query/helper | Candidates | Current-source verification | Native search / test / command evidence | Fallback |'
    '| Source owner / diff evidence | UI classification | Task ID | Case ID | Disposition |'
    '| Task ID | Case ID | UI Delivery Level | Required stage | Actual stage | Visual evidence reference | E2E applicability / result | Matrix / evidence paths | Mocked Core API | Cleanup | Business result | Blocking condition |'
)
foreach ($header in $sharedProjectionHeaders) {
    Assert-Condition ($sharedReviewContract.Contains($header)) "shared final-review contract lost projection header: $header"
}
$surfaceSpecificProjections = @(
    @{ Name = 'package command'; Surface = $finalPackage; Header = '| Command | Classification | Definition inspected | Mutation reason / safe proof | Result |' }
    @{ Name = 'report command'; Surface = $reportTemplate; Header = '| Command | Safety | Definition evidence | Result | Notes |' }
    @{ Name = 'package CodeGraph'; Surface = $finalPackage; Header = '| Query/helper | Candidate paths/symbols | Current-source verification | Native search/test/command proof | Fallback |' }
    @{ Name = 'report CodeGraph'; Surface = $reportTemplate; Header = '| Query/helper | Candidates | Current-source verification | Native search / test / command evidence | Fallback |' }
    @{ Name = 'package Figma'; Surface = $finalPackage; Header = '| ID | Required observable result / existing behavior | Owner task/file | Before baseline | After replay | Status | Evidence |' }
    @{ Name = 'report Figma'; Surface = $reportTemplate; Header = '| ID | Source / required observable result | Owner task/file | Runtime evidence | Status | Review evidence |' }
)
foreach ($projection in $surfaceSpecificProjections) {
    Assert-Condition ($sharedReviewContract.Contains($projection.Header)) "shared final-review contract lost $($projection.Name) projection"
    Assert-Condition ($projection.Surface.Contains($projection.Header)) "$($projection.Name) projection drifted from the shared contract"
}
$packageCommandHeader = '| Command | Classification | Definition inspected | Mutation reason / safe proof | Result |'
$packageCommandDrift = $finalPackage.Replace($packageCommandHeader, '| Command | Classification | Drifted | Result |')
Assert-Condition ($packageCommandDrift -ne $finalPackage -and -not $packageCommandDrift.Contains($packageCommandHeader)) 'projection-drift mutation did not invalidate the package command projection'
foreach ($surface in @(
    @{ Name = 'fp-final-review'; Text = $reviewSkill }
    @{ Name = 'final reviewer'; Text = $reviewer }
    @{ Name = 'final package template'; Text = $finalPackage }
    @{ Name = 'final report template'; Text = $reportTemplate }
    @{ Name = 'fp-execute-sdd'; Text = $sddSkill }
    @{ Name = 'fp-archive'; Text = $archiveSkill }
)) {
    Assert-Condition (Test-SharedFinalReviewReference $surface.Text) "$($surface.Name) does not actively load the shared final-review contract"
}
Assert-Condition ($finalPackage.Contains('creating or resuming an SDD final-review package') -and $finalPackage.Contains('pending-dispatch') -and $finalPackage.Contains('review-completed') -and $finalPackage.Contains('result-committed') -and $finalPackage.Contains('fixing') -and $finalPackage.Contains('complete')) 'final package pointer is not branch-complete across SDD phases'
Assert-Condition ($reportTemplate.Contains('writing or resuming a final-review report') -and $reportTemplate.Contains('N/A-direct') -and $reportTemplate.Contains('SDD')) 'final report pointer is not branch-complete across direct and SDD modes'

foreach ($surface in @(
    @{ Name = 'final package template'; Text = $finalPackage }
    @{ Name = 'final report template'; Text = $reportTemplate }
)) {
    Assert-Condition (Test-NoLocalSharedInvariantDuplication $surface.Text) "$($surface.Name) still duplicates a shared invariant"
}
$localInvariantMutation = $reportTemplate + "`n- Provenance: reference.png -> approved Figma/static design source; current.png -> real target runtime."
Assert-Condition (-not (Test-NoLocalSharedInvariantDuplication $localInvariantMutation)) 'local-duplication detector accepted a copied shared visual invariant'

foreach ($surface in @(
    @{ Name = 'final package template'; Text = $finalPackage }
    @{ Name = 'final report template'; Text = $reportTemplate }
)) {
    foreach ($header in @(
        '| Declared path/contract | Observed diff path | Mapping | Classification | Relevant change owner | Evidence |'
        '| Path | Candidate lookup | Canonical owner proof | Resolved owners | Classification |'
        '| Gate | Result | Evidence |'
        '| Source owner / diff evidence | UI classification | Task ID | Case ID | Disposition |'
        '| Task ID | Case ID | UI Delivery Level | Required stage | Actual stage | Visual evidence reference | E2E applicability / result | Matrix / evidence paths | Mocked Core API | Cleanup | Business result | Blocking condition |'
    )) {
        Assert-Condition ($surface.Text.Contains($header)) "$($surface.Name) lost local projection header: $header"
    }
}

Assert-Condition (-not (Test-Path (Join-Path $root 'commands\fp-review.md'))) 'old fp-review command still exists'
Assert-Condition (-not (Test-Path (Join-Path $root 'skills\fp-review'))) 'old fp-review skill directory still exists'
Assert-Condition (-not (Test-Path (Join-Path $root 'scripts\test-review-contract.ps1'))) 'old review validator still exists'

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
Assert-Anchors $reviewSkill $reviewInputs 'fp-final-review input contract'
Assert-Anchors $reviewer $reviewInputs 'final reviewer input contract'
Assert-Condition ($reviewer.Contains('- reviewPhase: {PENDING_DISPATCH_OR_REVIEW_COMPLETED_OR_RESULT_COMMITTED_OR_FIXING_OR_COMPLETE_OR_NA_DIRECT}')) 'final reviewer input contract omits a valid review phase'
Assert-Anchors $finalPackage $reviewInputs 'final review package'
Assert-Condition ($reviewSkill.Contains('maxReviewAttempts=3') -and $reviewer.Contains('maxReviewAttempts=3')) 'review attempt ceiling is not fixed at 3'
Assert-Anchors $reviewSkill @('independent final scope', 'attempt 1', 'does not auto-fix', 'does not auto-retry') 'direct fp-final-review defaults'
Assert-Anchors $command @('independent final scope', 'attempt 1', 'does not auto-fix', 'does not auto-retry') 'fp-final-review command checksum'

foreach ($surface in @(
    @{ Name = 'fp-final-review'; Text = $reviewSkill },
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
    @{ Name = 'fp-final-review'; Text = $reviewSkill },
    @{ Name = 'final reviewer'; Text = $reviewer }
)) {
    Assert-Anchors $surface.Text @('Scope Matrix', 'declared', 'observed', 'mapped', 'unmapped', 'missing', 'mapped-current', 'cross-change-only', 'shared', 'unowned/unmapped', 'branch inventory/counts', 'selected change', 'each relevant change contract', 'current verdict') $surface.Name
    Assert-Condition ($surface.Text -match '(?is)mapped-current.{0,260}(?:selected change|current change).{0,260}(?:affects|impact)[^\r\n]{0,80}(?:current )?verdict') "$($surface.Name) does not make mapped-current affect the selected-change verdict"
    Assert-Condition ($surface.Text -match '(?is)cross-change-only.{0,360}(?:explicit|proven)[^\r\n]{0,100}(?:artifact|owner).{0,360}(?:exclude|excluded)[^\r\n]{0,120}(?:current change|current-change)[^\r\n]{0,80}verdict') "$($surface.Name) does not isolate proven cross-change-only paths from the current verdict"
    Assert-Condition ($surface.Text -match '(?is)cross-change-only.{0,420}branch inventory/counts') "$($surface.Name) drops cross-change-only paths from branch inventory/counts"
    Assert-Condition ($surface.Text -match '(?is)(?:owner evidence|ownership evidence).{0,200}(?:insufficient|missing|cannot be proven).{0,220}unowned/unmapped') "$($surface.Name) may guess a cross-change owner"
    Assert-Condition ($surface.Text -match '(?is)shared.{0,300}each relevant change contract.{0,260}(?:affects|impact)[^\r\n]{0,80}(?:current )?verdict') "$($surface.Name) does not review shared paths against every relevant contract/current verdict"
    Assert-Condition ($surface.Text -match '(?is)unowned/unmapped.{0,300}(?:scope finding|finding).{0,220}(?:affects|impact)[^\r\n]{0,80}(?:current )?verdict') "$($surface.Name) does not keep unowned risk in the current verdict"
}
Assert-Condition (Test-OwnerDiscoveryContract $sharedReviewContract) 'shared final-review contract is missing bounded sibling owner discovery'
Assert-Condition (Test-CrossChangeIsolationContract $sharedReviewContract) 'shared final-review contract does not isolate cross-change-only paths'
Assert-Anchors $reviewSkill @('complete branch inventory', 'selected change + shared + unowned') 'change-scoped verdict boundary'
foreach ($surface in @(
    @{ Name = 'fp-final-review'; Text = $reviewSkill },
    @{ Name = 'final reviewer'; Text = $reviewer }
)) {
    Assert-Condition (Test-OwnerDiscoveryContract $surface.Text) "$($surface.Name) is missing bounded sibling owner discovery"
    Assert-Condition (Test-CrossChangeIsolationContract $surface.Text) "$($surface.Name) does not isolate proven cross-change-only paths"
}

$headInputs = @('reviewedTargetHead', 'packageParentHead', 'evidenceCommitHead', 'dispatchHead')
foreach ($surface in @(
    @{ Name = 'fp-final-review'; Text = $reviewSkill },
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
) 'fp-final-review target/evidence/dispatch validation'
Assert-Anchors $reviewer @('packageParentHead == reviewedTargetHead', 'evidenceCommitHead == dispatchHead == current git HEAD', 'reviewedTargetHead..dispatchHead', 'allowed evidence paths', 'product source unchanged', 'dispatch tree clean') 'final reviewer HEAD validation'
foreach ($surface in @(
    @{ Name = 'fp-final-review'; Text = $reviewSkill },
    @{ Name = 'final reviewer'; Text = $reviewer },
    @{ Name = 'shared final-review contract'; Text = $sharedReviewContract }
)) {
    Assert-Condition (Test-DispatchCommitContract $surface.Text) "$($surface.Name) is missing parent/count/allowed-delta verification"
}
Assert-Condition (Test-DirectModeDispatchBranch $sharedReviewContract) 'shared final-review contract does not make the SDD one-commit checks conditional in direct mode'

Assert-Condition ($finalPackage.Contains('- evidenceCommitHead: `POST_COMMIT_EXTERNAL`')) 'final package must use an external evidence-commit sentinel'
Assert-Condition ($finalPackage.Contains('- dispatchHead: `POST_COMMIT_EXTERNAL`')) 'final package must use an external dispatch-head sentinel'
Assert-Anchors $finalPackage @('self-reference', 'must not embed', 'never rewrite the package', 'packageParentHead = reviewedTargetHead', 'target dirty fingerprint: `CLEAN`') 'final package self-reference prohibition'

$finalFlow = [regex]::Match($sddSkill, '(?s)## Completion and Final Review\s*(?<body>.*?)\s*## CodeGraph write freshness')
Assert-Condition $finalFlow.Success 'fp-execute-sdd final-review flow is missing'
$flowText = $finalFlow.Groups['body'].Value
$resumeBranch = [regex]::Match($flowText, '(?s)Branch by phase:\s*(?<body>.*?)(?=\s*A result commit records)')
Assert-Condition ($resumeBranch.Success -and $resumeBranch.Groups['body'].Value.Contains('- `result-committed`, `fixing`, or `complete`:')) 'fp-execute-sdd resume router omits the complete phase'
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
    @{ Name = 'fp-final-review'; Text = $reviewSkill },
    @{ Name = 'final reviewer'; Text = $reviewer },
    @{ Name = 'shared final-review contract'; Text = $sharedReviewContract },
    @{ Name = 'fp-execute-sdd'; Text = $sddSkill }
)) {
    Assert-Condition (Test-PhaseResumeContract $surface.Text) "$($surface.Name) is missing phase-aware resume semantics"
}

foreach ($surface in @(
    @{ Name = 'fp-final-review'; Text = $reviewSkill },
    @{ Name = 'final reviewer'; Text = $reviewer },
    @{ Name = 'shared final-review contract'; Text = $sharedReviewContract },
    @{ Name = 'SDD review package'; Text = $sddPackage }
)) {
    Assert-Anchors $surface.Text @('SAFE', 'UNSAFE', 'UNKNOWN', '--fix', '--write', 'snapshot update', 'migration', 'seed', 'formatter', 'generator', 'cache', 'coverage', 'dist', 'unknown wrapper', 'service', 'database', 'external mutation', 'must not run') $surface.Name
}

foreach ($surface in @(
    @{ Name = 'fp-final-review'; Text = $reviewSkill },
    @{ Name = 'final reviewer'; Text = $reviewer },
    @{ Name = 'CodeGraph shared contract'; Text = $codeGraph }
)) {
    Assert-Anchors $surface.Text @('explore', 'impact', 'affected', 'candidate', 'current source', 'native search', 'fallback', 'must not block') $surface.Name
}
Assert-Anchors $reviewSkill @('current diff', 'tests', 'command output') 'source verification contract'

Assert-Anchors $sddSkill $reviewInputs 'SDD final-review dispatch inputs'
Assert-Anchors $sddPackage @('reviewScopeId', 'reviewAttempt', 'lastReviewedHead', 'priorFindingDispositions') 'SDD review package state'
Assert-Anchors $sddSkill @('stable reviewScopeId', 'never resets', 'new reviewer', 'new commit', 'new session', 'new finding', 'never dispatch attempt 4') 'SDD bounded attempt orchestration'
Assert-Anchors $reviewSkill @('Attempt 3', 'non-blocking debt', 'main-flow blockers', 'blocked') 'attempt 3 verdict handling'

# The UI/E2E gate is independent from (but cross-references) Visual Evidence.
# It carries lifecycle/E2E closure instead of duplicating the visual table fields.
Assert-Condition (Test-UiE2EFinalGate $reviewSkill) 'fp-final-review is missing the non-waivable UI/E2E final gate'
Assert-Condition (Test-UiE2EReviewerGate $reviewer) 'final reviewer prompt is missing active UI/E2E gate verification fields'
Assert-Condition (Test-UiE2EArtifactGate $reportTemplate) 'final report must keep an active dedicated UI/E2E Gate table and matrix path'
Assert-Condition (Test-UiE2EArtifactGate $finalPackage) 'final package must keep an active dedicated UI/E2E Gate table and matrix path'
Assert-Condition ($sharedReviewContract.Contains('UI/E2E Gate: PASS | N/A | FAIL | BLOCKED') -and $sharedReviewContract.Contains('cannot become `PASS`, `PASS_WITH_NOTES`, review debt, manual override, or waiver')) 'shared final-review contract permits a UI/E2E non-pass bypass'
Assert-Condition (Test-ArchiveUiE2EHardGate $archiveSkill) 'fp-archive must reject non-waivable UI/E2E core gaps before confirmation'
Assert-Condition (Test-UiCaseInventoryContract $reviewSkill) 'fp-final-review must reconcile every UI-bearing source before it can issue E2E N/A'
Assert-Condition (Test-UiCaseInventoryContract $reviewer) 'final reviewer must reconcile every UI-bearing source before it can issue E2E N/A'
Assert-Condition (Test-UiCaseInventoryArtifact $reportTemplate) 'final report must keep an active UI Case Inventory / N/A Reconciliation table'
Assert-Condition (Test-UiCaseInventoryArtifact $finalPackage) 'final package must keep an active UI Case Inventory / N/A Reconciliation table'
Assert-Condition ($sharedReviewContract.Contains('`N/A` is valid only when the inventory proves zero UI-bearing sources, no Figma UI scope, no mapped-current or unowned frontend diff, and evidence covers the reviewed target snapshot.')) 'shared final-review contract lost the UI inventory N/A predicate'
Assert-Condition (Test-FigmaFinalHardGate $reviewSkill) 'fp-final-review must make Figma capability/preservation non-pass a final blocker'
Assert-Condition (Test-FigmaFinalHardGate $reviewer) 'final reviewer must make Figma capability/preservation non-pass a final blocker'
Assert-Condition (Test-FigmaFinalHardGate $sharedReviewContract) 'shared final-review contract must make Figma capability/preservation non-pass a final blocker'
Assert-Condition (Test-FigmaFinalArtifact $reportTemplate) 'final report must keep an active Figma Completion Gate'
Assert-Condition (Test-FigmaFinalArtifact $finalPackage) 'final package must keep an active Figma Completion Gate'
Assert-Condition (Test-ArchiveFigmaHardGate $archiveSkill) 'fp-archive must reject incomplete Figma capability/preservation evidence before confirmation'

$inventoryHeadingMutation = [regex]::Replace($reviewSkill, [regex]::Escape('UI Case Inventory / N/A Reconciliation'), 'Removed UI Case Inventory', 1)
Assert-Condition ($inventoryHeadingMutation -ne $reviewSkill) 'UI Case Inventory heading mutation fixture did not mutate the review skill'
Assert-Condition (-not (Test-UiCaseInventoryContract $inventoryHeadingMutation)) 'inventory helper accepted a missing reconciliation requirement'
$inventoryShortcutMutation = $reviewSkill + "`nN/A may be issued whenever a reviewer judges a UI scope absent, notwithstanding any source inventory."
Assert-Condition (-not (Test-UiCaseInventoryContract $inventoryShortcutMutation)) 'inventory helper accepted an omitted UI-bearing source as N/A'

$figmaVerdictSource = 'any required `FIGCAP-*`, core `PRES-*`, or core visual Case that is `INCOMPLETE`, `CANNOT_VERIFY`, `FAIL`, or `BLOCKED` makes the final verdict `FAIL` or `BLOCKED`'
$figmaVerdictMutation = $reviewSkill.Replace($figmaVerdictSource, 'a failed FIGCAP may be accepted as `PASS_WITH_NOTES` after manual approval')
Assert-Condition ($figmaVerdictMutation -ne $reviewSkill) 'Figma non-pass verdict mutation fixture did not mutate the review skill'
Assert-Condition (-not (Test-FigmaFinalHardGate $figmaVerdictMutation)) 'Figma final helper accepted a non-pass PASS_WITH_NOTES/manual-approval bypass'
$figmaAppendMutation = $reviewSkill.Replace('Provenance: reference.png', 'Exception: a failed FIGCAP may be converted to PASS_WITH_NOTES after manual approval; this is not recommended.`n`nProvenance: reference.png')
Assert-Condition ($figmaAppendMutation -ne $reviewSkill) 'Figma permission mutation fixture did not mutate the review skill'
Assert-Condition (-not (Test-FigmaFinalHardGate $figmaAppendMutation)) 'Figma final helper accepted an appended permission bypass'
$figmaArtifactMutation = $sharedReviewContract.Replace('it cannot become `PASS`, `PASS_WITH_NOTES`, review debt, manual approval, or waiver', 'it may become `PASS_WITH_NOTES` after manual approval')
Assert-Condition ($figmaArtifactMutation -ne $sharedReviewContract) 'Figma shared-contract mutation fixture did not mutate the owner'
Assert-Condition (-not (Test-FigmaFinalHardGate $figmaArtifactMutation)) 'Figma shared contract accepted a permission bypass'

$archiveFigmaGateRemoved = $archiveSkill.Replace('### Step 2.2: Figma Completion Gate', '### Removed Figma Completion Gate')
Assert-Condition ($archiveFigmaGateRemoved -ne $archiveSkill) 'archive Figma heading mutation fixture did not mutate the archive skill'
Assert-Condition (-not (Test-ArchiveFigmaHardGate $archiveFigmaGateRemoved)) 'archive Figma helper accepted a missing Figma completion gate'
$archiveFigmaOverrideMutation = $archiveSkill.Replace('A user confirmation cannot override or waive this gate', 'A user confirmation may override a failed FIGCAP; this is not recommended')
Assert-Condition ($archiveFigmaOverrideMutation -ne $archiveSkill) 'archive Figma override mutation fixture did not mutate the archive skill'
Assert-Condition (-not (Test-ArchiveFigmaHardGate $archiveFigmaOverrideMutation)) 'archive Figma helper accepted a user-confirmation override'
$archiveFigmaAppendMutation = $archiveSkill + "`nA user confirmation may override a failed FIGCAP; this is not recommended."
Assert-Condition ($archiveFigmaAppendMutation -ne $archiveSkill) 'archive Figma appended-override mutation fixture did not mutate the archive skill'
Assert-Condition (-not (Test-ArchiveFigmaHardGate $archiveFigmaAppendMutation)) 'archive Figma helper accepted an appended user-confirmation override'
$archiveFigmaGateText = [regex]::Match((Get-ActiveMarkdown $archiveSkill), '(?ms)^### Step 2\.2: Figma Completion Gate[ \t]*\r?\n.*?(?=^### Step 3:|\z)').Value
$archiveFigmaGateMoved = [regex]::Replace($archiveSkill, '(?ms)^### Step 2\.2: Figma Completion Gate[ \t]*\r?\n.*?(?=^### Step 3:)', '') + "`n" + $archiveFigmaGateText
Assert-Condition ($archiveFigmaGateMoved -ne $archiveSkill) 'archive Figma gate move mutation fixture did not mutate the archive skill'
Assert-Condition (-not (Test-ArchiveFigmaHardGate $archiveFigmaGateMoved)) 'archive Figma helper accepted a Figma gate after user confirmation'

$uiE2ESkillMutation = $reviewSkill.Replace('### 2.2 UI/E2E Gate', '### Removed UI/E2E Gate')
Assert-Condition ($uiE2ESkillMutation -ne $reviewSkill) 'UI/E2E heading mutation fixture did not mutate the review skill'
Assert-Condition (-not (Test-UiE2EFinalGate $uiE2ESkillMutation)) 'UI/E2E helper accepted a missing dedicated gate'

$uiE2EPassNotesMutation = $reviewSkill.Replace('cannot be converted into `PASS`, `PASS_WITH_NOTES`, review debt, a manual approval, or a waived check', 'prohibition removed') + "`nPASS_WITH_NOTES and manual approval are allowed."
Assert-Condition ($uiE2EPassNotesMutation -ne $reviewSkill) 'PASS_WITH_NOTES mutation fixture did not mutate the review skill'
Assert-Condition (-not (Test-UiE2EFinalGate $uiE2EPassNotesMutation)) 'UI/E2E helper accepted a PASS_WITH_NOTES/manual-waiver bypass'

$uiE2EMockMutation = $reviewSkill.Replace('is a mock violation and blocks the gate with `FAIL` or `BLOCKED`', 'is allowed') + "`nMocked Core API: false"
Assert-Condition ($uiE2EMockMutation -ne $reviewSkill) 'mock-core-API mutation fixture did not mutate the review skill'
Assert-Condition (-not (Test-UiE2EFinalGate $uiE2EMockMutation)) 'UI/E2E helper accepted a prohibited mock route/intercept/data path'

$uiE2ESkipMutation = $reviewSkill.Replace('case must reach `FRONTEND_E2E_PASS`', 'case may skip real E2E') + "`nFRONTEND_E2E_PASS"
Assert-Condition ($uiE2ESkipMutation -ne $reviewSkill) 'required-E2E skip mutation fixture did not mutate the review skill'
Assert-Condition (-not (Test-UiE2EFinalGate $uiE2ESkipMutation)) 'UI/E2E helper accepted a may-skip required E2E path'

$uiE2EActiveGate = [regex]::Match((Get-ActiveMarkdown $reviewSkill), '(?ms)^### 2\.2 UI/E2E Gate[ \t]*\r?\n.*?(?=^### |\z)').Value
Assert-Condition (-not [string]::IsNullOrWhiteSpace($uiE2EActiveGate)) 'active UI/E2E gate fixture is missing'
$backtickFence = [string]::new([char]96, 3)
$tildeFence = '~~~'
$invalidBacktickOpening = $backtickFence + 'text' + [string][char]96
$uiE2EPlainPseudo = $uiE2ESkillMutation + "`n" + $uiE2EActiveGate
Assert-Condition (Test-UiE2EFinalGate $uiE2EPlainPseudo) 'active UI/E2E pseudo gate fixture is not valid'
$uiE2ECommentPseudo = $uiE2ESkillMutation + "`n<!--`n" + $uiE2EActiveGate + "`n-->"
$uiE2EBacktickPseudo = $uiE2ESkillMutation + "`n" + $backtickFence + "text`n" + $uiE2EActiveGate + "`n" + $backtickFence
$uiE2ETildePseudo = $uiE2ESkillMutation + "`n" + $tildeFence + "text`n" + $uiE2EActiveGate + "`n" + $tildeFence
Assert-Condition (-not (Test-UiE2EFinalGate $uiE2ECommentPseudo)) 'UI/E2E helper accepted commented fake gate text'
Assert-Condition (-not (Test-UiE2EFinalGate $uiE2EBacktickPseudo)) 'UI/E2E helper accepted backtick-fenced fake gate text'
Assert-Condition (-not (Test-UiE2EFinalGate $uiE2ETildePseudo)) 'UI/E2E helper accepted tilde-fenced fake gate text'
$invalidBacktickGrant = $invalidBacktickOpening + "`nException: mock data is permitted."
$invalidBacktickActive = Get-ActiveMarkdown $invalidBacktickGrant
Assert-Condition ($invalidBacktickActive.Contains($invalidBacktickOpening)) 'invalid backtick-fence opening was removed from active Markdown'
Assert-Condition ($invalidBacktickActive.Contains('Exception: mock data is permitted.')) 'invalid backtick-fence opening hid a following mock grant'

$legalFenceExample = "visible`n" + $tildeFence + "text`n" + $backtickFence + " is not a closing tilde fence`n" + $tildeFence + "`nvisible"
$activeLegalFenceExample = Get-ActiveMarkdown $legalFenceExample
Assert-Condition ($activeLegalFenceExample -notmatch 'not a closing tilde fence') 'active Markdown helper accepted text inside a paired tilde fence'
Assert-Condition ([regex]::Matches($activeLegalFenceExample, '(?m)^visible$').Count -eq 2) 'active Markdown helper did not preserve legal text around a paired tilde fence'

$reportGate = [regex]::Match($activeReportTemplate, '(?ms)^## UI/E2E Gate[ \t]*\r?\n.*?(?=^## |\z)').Value
$reportGateRemoved = $reportTemplate.Replace('## UI/E2E Gate', '## Removed UI/E2E Gate')
Assert-Condition (Test-UiE2EArtifactGate ($reportGateRemoved + "`n" + $reportGate)) 'active report pseudo gate fixture is not valid'
Assert-Condition (-not (Test-UiE2EArtifactGate ($reportGateRemoved + "`n<!--`n" + $reportGate + "`n-->"))) 'artifact gate accepted commented pseudo table/matrix/waiver'
Assert-Condition (-not (Test-UiE2EArtifactGate ($reportGateRemoved + "`n" + $backtickFence + "text`n" + $reportGate + "`n" + $backtickFence))) 'artifact gate accepted fenced pseudo table/matrix/waiver'

$packageGate = [regex]::Match($activeFinalPackage, '(?ms)^## UI/E2E Gate[ \t]*\r?\n.*?(?=^## |\z)').Value
$packageGateRemoved = $finalPackage.Replace('## UI/E2E Gate', '## Removed UI/E2E Gate')
Assert-Condition (Test-UiE2EArtifactGate ($packageGateRemoved + "`n" + $packageGate)) 'active package pseudo gate fixture is not valid'
Assert-Condition (-not (Test-UiE2EArtifactGate ($packageGateRemoved + "`n" + $tildeFence + "text`n" + $packageGate + "`n" + $tildeFence))) 'artifact gate accepted tilde-fenced pseudo table/matrix/waiver'

$archiveOverrideMutation = $archiveSkill.Replace('A user confirmation cannot override or waive this gate', 'A user confirmation may override this gate')
Assert-Condition ($archiveOverrideMutation -ne $archiveSkill) 'archive override mutation fixture did not mutate the archive skill'
Assert-Condition (-not (Test-ArchiveUiE2EHardGate $archiveOverrideMutation)) 'archive helper accepted a user-confirmation override'

$archiveGateRemoved = $archiveSkill.Replace('### Step 2.1: UI/E2E Final Gate', '### Removed UI/E2E Final Gate')
$archivePermissionMutation = $archiveGateRemoved + "`n<!-- ### Step 2.1: UI/E2E Final Gate`nRead the latest final review UI/E2E Gate. FAIL or BLOCKED must not archive. user confirmation cannot override or waive. ordinary non-core incomplete task. not a second completion authority.`n-->"
Assert-Condition ($archivePermissionMutation -ne $archiveSkill) 'archive permission mutation fixture did not mutate the archive skill'
Assert-Condition (-not (Test-ArchiveUiE2EHardGate $archivePermissionMutation)) 'archive helper accepted an appended permission-style UI/E2E gate'

$archiveGateText = [regex]::Match((Get-ActiveMarkdown $archiveSkill), '(?ms)^### Step 2\.1: UI/E2E Final Gate[ \t]*\r?\n.*?(?=^### Step 3:|\z)').Value
$archiveGateMoved = [regex]::Replace($archiveSkill, '(?ms)^### Step 2\.1: UI/E2E Final Gate[ \t]*\r?\n.*?(?=^### Step 3:)', '') + "`n" + $archiveGateText
Assert-Condition ($archiveGateMoved -ne $archiveSkill) 'archive gate move mutation fixture did not mutate the archive skill'
Assert-Condition (-not (Test-ArchiveUiE2EHardGate $archiveGateMoved)) 'archive helper accepted a UI/E2E gate after user confirmation'

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

Assert-Condition ($validator.Contains('test-final-review-contract.ps1')) 'global validator does not invoke the focused review contract'

Write-Output 'Final review contract validation passed.'
