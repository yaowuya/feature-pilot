$ErrorActionPreference = 'Stop'

function Assert-Condition([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "Test failed: $Message" }
}

function Assert-ThrowsLike([scriptblock]$Action, [string]$Pattern) {
    $caught = $null
    try { & $Action }
    catch { $caught = $_ }
    Assert-Condition ($null -ne $caught) "Expected failure matching: $Pattern"
    Assert-Condition ($caught.Exception.Message -like "*$Pattern*") $caught.Exception.Message
}

function Assert-ThrowsContaining([scriptblock]$Action, [string[]]$Fragments) {
    $caught = $null
    try { & $Action }
    catch { $caught = $_ }
    Assert-Condition ($null -ne $caught) "Expected failure containing: $($Fragments -join ', ')"
    foreach ($fragment in $Fragments) {
        Assert-Condition ($caught.Exception.Message.Contains($fragment)) $caught.Exception.Message
    }
}

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Validator = Join-Path $ScriptRoot 'validate-artifact-layout.ps1'
if (-not (Test-Path -LiteralPath $Validator -PathType Leaf)) {
    throw "Validator does not exist: $Validator"
}

$SystemTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([IO.Path]::DirectorySeparatorChar)
$TempRoot = Join-Path $SystemTemp ("featurepilot-artifact-layout-tests-{0}" -f [guid]::NewGuid().ToString('N'))
$ResolvedTempRoot = [IO.Path]::GetFullPath($TempRoot)
Assert-Condition ((Split-Path -Parent $ResolvedTempRoot) -eq $SystemTemp) "fixture root must be a direct child of the system temporary directory"
Assert-Condition ((Split-Path -Leaf $ResolvedTempRoot) -like 'featurepilot-artifact-layout-tests-*') "fixture root has an unexpected name"
New-Item -ItemType Directory -Path $ResolvedTempRoot | Out-Null

function New-Fixture([string]$Name) {
    $path = Join-Path $ResolvedTempRoot $Name
    New-Item -ItemType Directory -Path $path | Out-Null
    return $path
}

function Write-FixtureFile([string]$Root, [string]$RelativePath, [string]$Content) {
    $path = Join-Path $Root $RelativePath
    $parent = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [IO.File]::WriteAllText($path, $Content, [Text.UTF8Encoding]::new($false))
}

function New-Manifest([object[]]$Rows) {
    $lines = @(
        '# Fragment Index'
        ''
        '## Fragment Manifest'
        ''
        '| Order | File | Kind | Owns |'
        '| ---: | --- | --- | --- |'
    )
    foreach ($row in $Rows) {
        $lines += "| $($row.Order) | ``$($row.File)`` | $($row.Kind) | $($row.Owns) |"
    }
    return ($lines -join "`n") + "`n"
}

function Add-SplitArtifact([string]$Root, [string]$RelativeDirectory, [object[]]$Rows) {
    Write-FixtureFile $Root "$RelativeDirectory/00-index.md" (New-Manifest $Rows)
    foreach ($row in $Rows) {
        $content = if ($row.Content) { [string]$row.Content } else { "# $($row.Owns)`n`nOwned content.`n" }
        Write-FixtureFile $Root "$RelativeDirectory/$($row.File)" $content
    }
}

function New-Task([string]$Id, [string]$DependsOn = 'None', [bool]$Complete = $false) {
    $marker = if ($Complete) { 'x' } else { ' ' }
    return "- [$marker] **Task ${Id}: Fixture task**`n`n**Depends on:** $DependsOn`n"
}

function New-ValidPrd {
    function U([string]$Escaped) { return ConvertFrom-Json ('"' + $Escaped + '"') }
    $userStories = U '\u7528\u6237\u6545\u4e8b'
    $businessGoal = U '\u4e1a\u52a1\u95ee\u9898\u4e0e\u9884\u671f\u76ee\u6807'
    $coreFlow = U '\u6838\u5fc3\u4e1a\u52a1\u6d41\u7a0b'
    $functional = U '\u529f\u80fd\u9700\u6c42'
    $featureName = U '\u7b56\u7565\u914d\u7f6e'
    $featureDescription = U '\u529f\u80fd\u8bf4\u660e'
    $interaction = U '\u4ea4\u4e92\u903b\u8f91'
    $exception = U '\u5f02\u5e38\u5904\u7406'
    $pageElements = U '\u9875\u9762\u5143\u7d20'
    $prototype = U '\u539f\u578b'
    $nonFunctional = U '\u975e\u529f\u80fd\u9700\u6c42'
    $performance = U '\u6027\u80fd\u9700\u6c42'
    $security = U '\u5b89\u5168\u9700\u6c42'
    $audit = U '\u64cd\u4f5c\u65e5\u5fd7\u8bb0\u5f55'
    $tests = U '\u6d4b\u8bd5\u5efa\u8bae'
    $questions = U '\u5f85\u786e\u8ba4\u95ee\u9898'
    $exceptionHeader = U '\u5f02\u5e38\u573a\u666f|\u89e6\u53d1\u6761\u4ef6|\u7cfb\u7edf\u5904\u7406\u65b9\u5f0f|\u7528\u6237\u63d0\u793a'
    $elementHeader = U '\u5143\u7d20\u540d|\u7c7b\u578b|\u8bf4\u660e|\u6821\u9a8c\u89c4\u5219'
    $auditHeader = U '\u64cd\u4f5c|\u662f\u5426\u8bb0\u5f55\u65e5\u5fd7|\u8bb0\u5f55\u4fe1\u606f'
    $testHeader = U '\u573a\u666f|\u524d\u7f6e\u6761\u4ef6|\u64cd\u4f5c|\u9884\u671f\u7ed3\u679c'
    return (@(
        '# Fixture PRD', '',
        "## $(U '\u4e00\u3001')$userStories", '', "### 1.1 $userStories", '', '- As an administrator, I want policy configuration.', '',
        "### 1.2 $businessGoal", '', 'The fixture defines a concrete goal.', '',
        "## $(U '\u4e8c\u3001')$coreFlow", '', 'Simple flow; no diagram required.', '',
        "## $(U '\u4e09\u3001')$functional", '', "### 3.1 $featureName", '',
        "#### 3.1.1 $featureDescription", '', 'Configure a policy.', '',
        "#### 3.1.2 $interaction", '', '- Submit, validate, and save.', '',
        "#### 3.1.3 $exception", '',
        "| $($exceptionHeader.Replace('|', ' | ')) |", '|---|---|---|---|', '| invalid | invalid input | reject | fix input |', '',
        "#### 3.1.4 $pageElements", '',
        "| $($elementHeader.Replace('|', ' | ')) |", '|---|---|---|---|', '| name | input | policy name | required |', '',
        "#### 3.1.5 $prototype", '', '- No prototype for this validator fixture.', '',
        "## $(U '\u56db\u3001')$nonFunctional", '', "### 4.1 $performance", '', '- P95 under two seconds.', '',
        "### 4.2 $security", '', '- Enforce authorization.', '',
        "### 4.3 $audit", '',
        "| $($auditHeader.Replace('|', ' | ')) |", '|---|---|---|', '| save | yes | actor and result |', '',
        "## $(U '\u4e94\u3001')$tests", '',
        "| $($testHeader.Replace('|', ' | ')) |", '|---|---|---|---|', '| save | authorized | submit | success |', '',
        "## $(U '\u516d\u3001')$questions", '', '- None.'
    ) -join "`n") + "`n"
}

function New-ValidProposal {
    return (@(
        '# Fixture Proposal', '',
        '## Why', '', 'A concrete policy configuration is needed.', '',
        '## What Changes', '', '### 1. Add policy configuration', '', 'Provide validated policy configuration.', '',
        '## Capabilities', '', '### New Capabilities', '', '- `policy-config`: configure policy.', '',
        '### Modified Capabilities', '', '- `execution`: apply policy.', '',
        '## Out of Scope', '', '- Historical data migration.', '',
        '## Impact', '', '- `src/policy` - policy module.'
    ) -join "`n") + "`n"
}

function New-DesignIndex([object[]]$Rows) {
    $lines = @(
        '# Design Index'
        ''
        '## Canonical End Entrypoints'
        ''
        '| End | Canonical entrypoint | Mode |'
        '| --- | --- | --- |'
    )
    foreach ($row in $Rows) {
        $lines += "| $($row.End) | ``$($row.Entry)`` | $($row.Mode) |"
    }
    return ($lines -join "`n") + "`n"
}

function New-CanonicalOverview(
    [string]$BackendEntry,
    [string]$BackendMode,
    [string]$FrontendEntry,
    [string]$FrontendMode,
    [int]$BackendTotal,
    [int]$BackendComplete,
    [int]$FrontendTotal,
    [int]$FrontendComplete,
    [object[]]$Edges = @()
) {
    $lines = @(
        '# Task Plan Overview'
        ''
        '## Canonical End Entrypoints'
        ''
        '| End | Canonical entrypoint | Mode |'
        '| --- | --- | --- |'
        "| Backend | ``$BackendEntry`` | $BackendMode |"
        "| Frontend | ``$FrontendEntry`` | $FrontendMode |"
    )
    if ($Edges.Count -gt 0) {
        $lines += @(
            ''
            '## Cross-end Dependency Edges'
            ''
            '| From task | To task | Shared contract / gate |'
            '| --- | --- | --- |'
        )
        foreach ($edge in $Edges) {
            $lines += "| ``$($edge.From)`` | ``$($edge.To)`` | $($edge.Gate) |"
        }
    }
    $lines += @(
        ''
        '## Progress Totals'
        ''
        '| End | Total | Complete | Remaining |'
        '| --- | ---: | ---: | ---: |'
        "| Backend | $BackendTotal | $BackendComplete | $($BackendTotal - $BackendComplete) |"
        "| Frontend | $FrontendTotal | $FrontendComplete | $($FrontendTotal - $FrontendComplete) |"
    )
    return ($lines -join "`n") + "`n"
}

function New-Overview([object[]]$Rows) {
    $lines = @(
        '# Task Plan Overview'
        ''
        '## Cross-end Execution Order'
        ''
        '| Sequence | Task ID or range | Owner file | Depends on |'
        '| ---: | --- | --- | --- |'
    )
    foreach ($row in $Rows) {
        $lines += "| $($row.Sequence) | ``$($row.Id)`` | ``$($row.Owner)`` | $($row.DependsOn) |"
    }
    return ($lines -join "`n") + "`n"
}

function Invoke-Validation([string]$Path, [string]$Mode = 'Producer') {
    & $Validator -ChangePath $Path -Mode $Mode
}

$Tests = [Collections.Generic.List[object]]::new()
function Add-Test([string]$Name, [scriptblock]$Body, [object[]]$Arguments = @()) {
    $Tests.Add([pscustomobject]@{ Name = $Name; Body = $Body; Arguments = @($Arguments) })
}

Add-Test 'valid small forms' {
    $fixture = New-Fixture 'valid-small'
    Write-FixtureFile $fixture 'prd.md' (New-ValidPrd)
    Write-FixtureFile $fixture 'proposal.md' (New-ValidProposal)
    Write-FixtureFile $fixture 'design/backend.md' "# Backend design`n"
    Write-FixtureFile $fixture 'design/frontend.md' "# Frontend design`n"
    Write-FixtureFile $fixture 'design/00-index.md' (New-DesignIndex @(
        [pscustomobject]@{ End = 'Backend'; Entry = 'design/backend.md'; Mode = 'small' }
        [pscustomobject]@{ End = 'Frontend'; Entry = 'design/frontend.md'; Mode = 'small' }
    ))
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001' 'backend-001')
    Write-FixtureFile $fixture 'tasks/00-overview.md' (New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 1 0 1 0 @(
        [pscustomobject]@{ From = 'backend-001'; To = 'frontend-001'; Gate = 'API contract' }
    ))
    $output = Invoke-Validation $fixture
    Assert-Condition (($output -join "`n") -like '*Artifact layout valid:*') 'valid small forms should pass'
}

Add-Test 'valid split forms for all four stages' {
    $fixture = New-Fixture 'valid-split'
    Add-SplitArtifact $fixture 'prd' @([pscustomobject]@{ Order = 1; File = '01-requirements.md'; Kind = 'requirements'; Owns = 'logical PRD'; Content = (New-ValidPrd) })
    Add-SplitArtifact $fixture 'proposal' @([pscustomobject]@{ Order = 1; File = '01-proposal.md'; Kind = 'proposal'; Owns = 'logical proposal'; Content = (New-ValidProposal) })
    Add-SplitArtifact $fixture 'design/backend' @([pscustomobject]@{ Order = 1; File = '01-api.md'; Kind = 'contract'; Owns = 'backend API'; Content = $null })
    Add-SplitArtifact $fixture 'design/frontend' @([pscustomobject]@{ Order = 1; File = '01-ui.md'; Kind = 'contract'; Owns = 'frontend UI'; Content = $null })
    Write-FixtureFile $fixture 'design/00-index.md' (New-DesignIndex @(
        [pscustomobject]@{ End = 'Backend'; Entry = 'design/backend/00-index.md'; Mode = 'split' }
        [pscustomobject]@{ End = 'Frontend'; Entry = 'design/frontend/00-index.md'; Mode = 'split' }
    ))
    Add-SplitArtifact $fixture 'tasks/backend' @(
        [pscustomobject]@{ Order = 1; File = '01-context.md'; Kind = 'context'; Owns = 'backend context'; Content = "# Backend Context`n" }
        [pscustomobject]@{ Order = 2; File = '05-interface.md'; Kind = 'interface'; Owns = 'backend interfaces'; Content = "# Backend Interfaces`n" }
        [pscustomobject]@{ Order = 3; File = '10-domain.md'; Kind = 'tasks'; Owns = 'backend-001'; Content = (New-Task 'backend-001') }
        [pscustomobject]@{ Order = 4; File = '90-coverage.md'; Kind = 'coverage'; Owns = 'backend coverage'; Content = "# Backend Coverage`n" }
    )
    Add-SplitArtifact $fixture 'tasks/frontend' @(
        [pscustomobject]@{ Order = 1; File = '01-context.md'; Kind = 'context'; Owns = 'frontend context'; Content = "# Frontend Context`n" }
        [pscustomobject]@{ Order = 2; File = '05-interface.md'; Kind = 'interface'; Owns = 'frontend interfaces'; Content = "# Frontend Interfaces`n" }
        [pscustomobject]@{ Order = 3; File = '10-ui.md'; Kind = 'tasks'; Owns = 'frontend-001'; Content = (New-Task 'frontend-001' 'backend-001') }
        [pscustomobject]@{ Order = 4; File = '90-coverage.md'; Kind = 'coverage'; Owns = 'frontend coverage'; Content = "# Frontend Coverage`n" }
    )
    Write-FixtureFile $fixture 'tasks/00-overview.md' (New-CanonicalOverview 'tasks/backend/00-index.md' 'split' 'tasks/frontend/00-index.md' 'split' 1 0 1 0 @(
        [pscustomobject]@{ From = 'backend-001'; To = 'frontend-001'; Gate = 'API contract' }
    ))
    $output = Invoke-Validation $fixture
    Assert-Condition (($output -join "`n") -like '*Artifact layout valid:*') 'valid split forms should pass'
}

Add-Test 'valid template-shaped split forms in Consumer mode' {
    $fixture = New-Fixture 'valid-split-consumer'
    Add-SplitArtifact $fixture 'proposal' @([pscustomobject]@{ Order = 1; File = '01-proposal.md'; Kind = 'proposal'; Owns = 'logical proposal'; Content = (New-ValidProposal) })
    Add-SplitArtifact $fixture 'design/backend' @([pscustomobject]@{ Order = 1; File = '01-api.md'; Kind = 'contract'; Owns = 'backend API'; Content = "# Backend API`n" })
    Write-FixtureFile $fixture 'design/00-index.md' (New-DesignIndex @([pscustomobject]@{ End = 'Backend'; Entry = 'design/backend/00-index.md'; Mode = 'split' }))
    Add-SplitArtifact $fixture 'tasks/backend' @(
        [pscustomobject]@{ Order = 1; File = '01-context.md'; Kind = 'context'; Owns = 'backend context'; Content = "# Backend Context`n" }
        [pscustomobject]@{ Order = 2; File = '05-interface.md'; Kind = 'interface'; Owns = 'backend interface'; Content = "# Backend Interface`n" }
        [pscustomobject]@{ Order = 3; File = '10-tasks.md'; Kind = 'tasks'; Owns = 'backend-001'; Content = (New-Task 'backend-001') }
        [pscustomobject]@{ Order = 4; File = '90-coverage.md'; Kind = 'coverage'; Owns = 'backend coverage'; Content = "# Backend Coverage`n" }
    )
    $output = Invoke-Validation $fixture 'Consumer'
    Assert-Condition (($output -join "`n") -like '*Artifact layout valid:*') 'template-shaped split Consumer should pass'
}

Add-Test 'accepts canonical overview without cross-end dependencies' {
    $fixture = New-Fixture 'canonical-overview-no-cross-edge'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001')
    Write-FixtureFile $fixture 'tasks/00-overview.md' (New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 1 0 1 0)
    $output = Invoke-Validation $fixture
    Assert-Condition (($output -join "`n") -like '*Artifact layout valid:*') 'canonical overview without cross-end edges should pass'
}

Add-Test 'rejects overview progress not derived from owner checkboxes' {
    $fixture = New-Fixture 'overview-wrong-progress'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001' 'None' $true)
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001')
    $overview = (New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 1 1 1 0).Replace('| Backend | 1 | 1 | 0 |', '| Backend | 1 | 0 | 1 |')
    Write-FixtureFile $fixture 'tasks/00-overview.md' $overview
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*progress totals for Backend do not match owner checkboxes*'
}

Add-Test 'rejects same-end missing dependency from owner task file' {
    $fixture = New-Fixture 'same-end-missing-dependency'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001' 'backend-999')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001')
    Write-FixtureFile $fixture 'tasks/00-overview.md' (New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 1 0 1 0)
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*task backend-001 references unknown dependency backend-999*'
}

Add-Test 'rejects same-end dependency cycle from owner task files' {
    $fixture = New-Fixture 'same-end-dependency-cycle'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' ((New-Task 'backend-001' 'backend-002') + "`n" + (New-Task 'backend-002' 'backend-001'))
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001')
    Write-FixtureFile $fixture 'tasks/00-overview.md' (New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 2 0 1 0)
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*task dependency cycle detected*'
}

Add-Test 'rejects old all-task overview schema' {
    $fixture = New-Fixture 'old-overview-schema'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001' 'backend-001')
    Write-FixtureFile $fixture 'tasks/00-overview.md' (New-Overview @(
        [pscustomobject]@{ Sequence = 1; Id = 'backend-001'; Owner = 'tasks/plan-backend.md'; DependsOn = 'None' }
        [pscustomobject]@{ Sequence = 2; Id = 'frontend-001'; Owner = 'tasks/plan-frontend.md'; DependsOn = '`backend-001`' }
    ))
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*old all-task overview schema is not supported*'
}

Add-Test 'rejects design end without design index' {
    $fixture = New-Fixture 'design-index-missing'
    Write-FixtureFile $fixture 'design/backend.md' "# Backend design`n"
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*design artifacts require design/00-index.md*'
}

Add-Test 'rejects design index with wrong canonical entry' {
    $fixture = New-Fixture 'design-index-wrong-entry'
    Write-FixtureFile $fixture 'design/backend.md' "# Backend design`n"
    Write-FixtureFile $fixture 'design/00-index.md' (New-DesignIndex @([pscustomobject]@{ End = 'Backend'; Entry = 'design/frontend.md'; Mode = 'small' }))
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*design index entry for Backend*expected design/backend.md*'
}

Add-Test 'rejects design index with extra end' {
    $fixture = New-Fixture 'design-index-extra-end'
    Write-FixtureFile $fixture 'design/backend.md' "# Backend design`n"
    Write-FixtureFile $fixture 'design/00-index.md' (New-DesignIndex @(
        [pscustomobject]@{ End = 'Backend'; Entry = 'design/backend.md'; Mode = 'small' }
        [pscustomobject]@{ End = 'Frontend'; Entry = 'design/frontend.md'; Mode = 'small' }
    ))
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*design index contains extra end Frontend*'
}

Add-Test 'rejects split plan missing required kinds' {
    $fixture = New-Fixture 'split-plan-missing-kinds'
    Add-SplitArtifact $fixture 'tasks/backend' @([pscustomobject]@{ Order = 1; File = '10-tasks.md'; Kind = 'tasks'; Owns = 'backend-001'; Content = (New-Task 'backend-001') })
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*backend plan requires exactly one context fragment*'
}

Add-Test 'rejects split plan duplicate singleton kind' {
    $fixture = New-Fixture 'split-plan-duplicate-context'
    Add-SplitArtifact $fixture 'tasks/backend' @(
        [pscustomobject]@{ Order = 1; File = '01-context.md'; Kind = 'context'; Owns = 'context A'; Content = "# Context A`n" }
        [pscustomobject]@{ Order = 2; File = '02-context.md'; Kind = 'context'; Owns = 'context B'; Content = "# Context B`n" }
        [pscustomobject]@{ Order = 3; File = '05-interface.md'; Kind = 'interface'; Owns = 'interface'; Content = "# Interface`n" }
        [pscustomobject]@{ Order = 4; File = '10-tasks.md'; Kind = 'tasks'; Owns = 'backend-001'; Content = (New-Task 'backend-001') }
        [pscustomobject]@{ Order = 5; File = '90-coverage.md'; Kind = 'coverage'; Owns = 'coverage'; Content = "# Coverage`n" }
    )
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*backend plan requires exactly one context fragment*'
}

Add-Test 'rejects incomplete PRD logical template' {
    $fixture = New-Fixture 'prd-template-incomplete'
    Write-FixtureFile $fixture 'prd.md' "# PRD stub`n"
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*PRD logical template is missing*'
}

Add-Test 'rejects proposal logical section order' {
    $fixture = New-Fixture 'proposal-template-order'
    $proposal = (New-ValidProposal).Replace("## Why`n", "## Impact`n`nEarly impact.`n`n## Why`n")
    Write-FixtureFile $fixture 'proposal.md' $proposal
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*proposal logical headings must appear exactly once in canonical order*'
}

Add-Test 'rejects PRD feature block outside functional requirements bounds' {
    $fixture = New-Fixture 'prd-feature-outside-section-three'
    $prd = New-ValidPrd
    $sectionFour = ConvertFrom-Json '"## \u56db\u3001\u975e\u529f\u80fd\u9700\u6c42"'
    $featureStart = $prd.IndexOf('### 3.1 ', [StringComparison]::Ordinal)
    $featureEnd = $prd.IndexOf($sectionFour, [StringComparison]::Ordinal)
    $featureBlock = $prd.Substring($featureStart, $featureEnd - $featureStart)
    $prd = $prd.Remove($featureStart, $featureEnd - $featureStart).TrimEnd() + "`n`n" + $featureBlock
    Write-FixtureFile $fixture 'prd.md' $prd
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*PRD functional feature headings must stay between section three and section four*'
}

Add-Test 'rejects proposal numbered change outside What Changes bounds' {
    $fixture = New-Fixture 'proposal-change-outside-what-changes'
    $proposal = New-ValidProposal
    $changeStart = $proposal.IndexOf('### 1. ', [StringComparison]::Ordinal)
    $changeEnd = $proposal.IndexOf('## Capabilities', [StringComparison]::Ordinal)
    $changeBlock = $proposal.Substring($changeStart, $changeEnd - $changeStart)
    $proposal = $proposal.Remove($changeStart, $changeEnd - $changeStart).TrimEnd() + "`n`n" + $changeBlock
    Write-FixtureFile $fixture 'proposal.md' $proposal
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*proposal numbered changes must stay between What Changes and Capabilities*'
}

Add-Test 'rejects detailed design content in design index' {
    $fixture = New-Fixture 'design-index-detailed-content'
    Write-FixtureFile $fixture 'design/backend.md' "# Backend design`n"
    $index = (New-DesignIndex @([pscustomobject]@{ End = 'Backend'; Entry = 'design/backend.md'; Mode = 'small' })) + "`n## API Contract`n`nPOST /policies owns detailed request and response requirements.`n"
    Write-FixtureFile $fixture 'design/00-index.md' $index
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*design index contains detailed content outside its metadata-only recipe*'
}

$Conflicts = @(
    @{ Name = 'PRD'; File = 'prd.md'; Directory = 'prd' },
    @{ Name = 'proposal'; File = 'proposal.md'; Directory = 'proposal' },
    @{ Name = 'backend design'; File = 'design/backend.md'; Directory = 'design/backend' },
    @{ Name = 'frontend design'; File = 'design/frontend.md'; Directory = 'design/frontend' },
    @{ Name = 'backend plan'; File = 'tasks/plan-backend.md'; Directory = 'tasks/backend' },
    @{ Name = 'frontend plan'; File = 'tasks/plan-frontend.md'; Directory = 'tasks/frontend' }
)
$ConflictTestBody = {
        param([string]$FixtureName, [string]$File, [string]$Directory, [string]$Mode)
        $fixture = New-Fixture $FixtureName
        Write-FixtureFile $fixture $File "# Small form`n"
        Add-SplitArtifact $fixture $Directory @([pscustomobject]@{ Order = 1; File = '01-detail.md'; Kind = 'detail'; Owns = 'detail'; Content = $null })
        Assert-ThrowsLike { Invoke-Validation $fixture $Mode } 'Artifact layout invalid:*mutually exclusive*'
}
foreach ($conflict in $Conflicts) {
    $slug = $conflict.Name -replace ' ', '-'
    Add-Test "rejects $($conflict.Name) file-directory conflict in producer mode" $ConflictTestBody @("conflict-$slug", $conflict.File, $conflict.Directory, 'Producer')
    Add-Test "rejects $($conflict.Name) file-directory conflict in consumer mode" $ConflictTestBody @("consumer-conflict-$slug", $conflict.File, $conflict.Directory, 'Consumer')
}

Add-Test 'rejects split directory with missing index' {
    $fixture = New-Fixture 'missing-index'
    Write-FixtureFile $fixture 'prd/01-requirements.md' "# Requirements`n"
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*missing 00-index.md*'
}

Add-Test 'rejects split index missing Fragment Manifest heading' {
    $fixture = New-Fixture 'missing-fragment-manifest-heading'
    $index = (New-Manifest @([pscustomobject]@{ Order = 1; File = '01-proposal.md'; Kind = 'proposal'; Owns = 'proposal' })).Replace("## Fragment Manifest`n`n", '')
    Write-FixtureFile $fixture 'proposal/00-index.md' $index
    Write-FixtureFile $fixture 'proposal/01-proposal.md' (New-ValidProposal)
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*requires exactly one ## Fragment Manifest heading*'
}

Add-Test 'rejects split index with incorrect manifest heading' {
    $fixture = New-Fixture 'wrong-fragment-manifest-heading'
    $index = (New-Manifest @([pscustomobject]@{ Order = 1; File = '01-proposal.md'; Kind = 'proposal'; Owns = 'proposal' })).Replace('## Fragment Manifest', '## Fragment Order')
    Write-FixtureFile $fixture 'proposal/00-index.md' $index
    Write-FixtureFile $fixture 'proposal/01-proposal.md' (New-ValidProposal)
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*requires exactly one ## Fragment Manifest heading*'
}

Add-Test 'rejects manifest with missing fragment' {
    $fixture = New-Fixture 'missing-fragment'
    Write-FixtureFile $fixture 'proposal/00-index.md' (New-Manifest @([pscustomobject]@{ Order = 1; File = '01-why.md'; Kind = 'rationale'; Owns = 'why' }))
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*missing fragment*'
}

Add-Test 'rejects unindexed fragment' {
    $fixture = New-Fixture 'unindexed-fragment'
    Add-SplitArtifact $fixture 'prd' @([pscustomobject]@{ Order = 1; File = '01-requirements.md'; Kind = 'requirements'; Owns = 'requirements'; Content = $null })
    Write-FixtureFile $fixture 'prd/02-hidden.md' "# Hidden`n"
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*unindexed fragment*'
}

Add-Test 'rejects fragment path escape' {
    $fixture = New-Fixture 'path-escape'
    Write-FixtureFile $fixture 'prd/00-index.md' (New-Manifest @([pscustomobject]@{ Order = 1; File = '../escaped.md'; Kind = 'requirements'; Owns = 'requirements' }))
    Write-FixtureFile $fixture 'escaped.md' "# Escaped`n"
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*escapes split directory*'
}

Add-Test 'rejects detailed body content before a split manifest' {
    $fixture = New-Fixture 'index-body-before-manifest'
    $index = "# Fragment Index`n`nUsers must receive an approval notification.`n`n" + (New-Manifest @([pscustomobject]@{ Order = 1; File = '01-requirements.md'; Kind = 'requirements'; Owns = 'requirements' }))
    Write-FixtureFile $fixture 'prd/00-index.md' $index
    Write-FixtureFile $fixture 'prd/01-requirements.md' "# Requirements`n"
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*detailed body content*'
}

Add-Test 'rejects detailed body content after a split manifest' {
    $fixture = New-Fixture 'index-body-after-manifest'
    $index = (New-Manifest @([pscustomobject]@{ Order = 1; File = '01-requirements.md'; Kind = 'requirements'; Owns = 'requirements' })) + "`n## Requirements`n`nUsers must receive an approval notification.`n"
    Write-FixtureFile $fixture 'prd/00-index.md' $index
    Write-FixtureFile $fixture 'prd/01-requirements.md' "# Requirements`n"
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*detailed body content*'
}

Add-Test 'accepts the positive index metadata and navigation recipe' {
    $fixture = New-Fixture 'valid-index-metadata-recipe'
    $index = @(
        '# PRD Fragment Index'
        ''
        '## Navigation'
        ''
        '- Canonical entrypoint: `prd/00-index.md`'
        ''
        '## Fragment Manifest'
        ''
        '| Order | File | Kind | Owns |'
        '| ---: | --- | --- | --- |'
        '| 1 | `01-requirements.md` | requirements | requirements |'
    ) -join "`n"
    Write-FixtureFile $fixture 'prd/00-index.md' $index
    Write-FixtureFile $fixture 'prd/01-requirements.md' (New-ValidPrd)
    $output = Invoke-Validation $fixture
    Assert-Condition (($output -join "`n") -like '*Artifact layout valid:*') 'positive index metadata/navigation recipe should pass'
}

Add-Test 'rejects an index title placed after the manifest' {
    $fixture = New-Fixture 'index-title-after-manifest'
    $index = @(
        '## Fragment Manifest'
        ''
        '| Order | File | Kind | Owns |'
        '| ---: | --- | --- | --- |'
        '| 1 | `01-requirements.md` | requirements | requirements |'
        ''
        '# Late Fragment Index'
    ) -join "`n"
    Write-FixtureFile $fixture 'prd/00-index.md' $index
    Write-FixtureFile $fixture 'prd/01-requirements.md' "# Requirements`n"
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*H1 title must be the first non-empty line*'
}

Add-Test 'rejects index metadata before the H1 title' {
    $fixture = New-Fixture 'index-metadata-before-title'
    $index = @(
        '## Navigation'
        ''
        '- Canonical entrypoint: `prd/00-index.md`'
        ''
        '# PRD Fragment Index'
        ''
        '## Fragment Manifest'
        ''
        '| Order | File | Kind | Owns |'
        '| ---: | --- | --- | --- |'
        '| 1 | `01-requirements.md` | requirements | requirements |'
    ) -join "`n"
    Write-FixtureFile $fixture 'prd/00-index.md' $index
    Write-FixtureFile $fixture 'prd/01-requirements.md' "# Requirements`n"
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*H1 title must be the first non-empty line*'
}

Add-Test 'rejects 501-line artifact' {
    $fixture = New-Fixture 'too-many-lines'
    $base = @((New-ValidPrd).TrimEnd() -split "`n")
    Write-FixtureFile $fixture 'prd.md' (($base + @(1..(501 - $base.Count) | ForEach-Object { "padding $_" })) -join "`n")
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*501 lines*'
}

Add-Test 'rejects 30001-character artifact' {
    $fixture = New-Fixture 'too-many-characters'
    $base = New-ValidProposal
    Write-FixtureFile $fixture 'proposal.md' ($base + ('x' * (30001 - $base.Length)))
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*30001 characters*'
}

$ExtraMarkdownScopes = @(
    @{ Name = 'root'; Path = 'notes.md' },
    @{ Name = 'design'; Path = 'design/notes.md' },
    @{ Name = 'tasks'; Path = 'tasks/notes.md' }
)
$ExtraMarkdownTestBody = {
        param([string]$FixtureName, [string]$Path, [bool]$Characters)
        $fixture = New-Fixture $FixtureName
        $content = if ($Characters) { 'x' * 30001 } else { (1..501 | ForEach-Object { "line $_" }) -join "`n" }
        Write-FixtureFile $fixture $Path $content
        $expected = if ($Characters) { 'Artifact layout invalid:*30001 characters*' } else { 'Artifact layout invalid:*501 lines*' }
        Assert-ThrowsLike { Invoke-Validation $fixture } $expected
}
foreach ($scope in $ExtraMarkdownScopes) {
    Add-Test "rejects otherwise extra $($scope.Name) Markdown over 500 lines" $ExtraMarkdownTestBody @("extra-$($scope.Name)-lines", $scope.Path, $false)
    Add-Test "rejects otherwise extra $($scope.Name) Markdown over 30000 characters" $ExtraMarkdownTestBody @("extra-$($scope.Name)-characters", $scope.Path, $true)
}

Add-Test 'rejects duplicate content ownership' {
    $fixture = New-Fixture 'duplicate-content-owner'
    Add-SplitArtifact $fixture 'design/backend' @(
        [pscustomobject]@{ Order = 1; File = '01-api.md'; Kind = 'contract'; Owns = 'API contract'; Content = $null }
        [pscustomobject]@{ Order = 2; File = '02-api-copy.md'; Kind = 'contract'; Owns = 'API contract'; Content = $null }
    )
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*duplicate ownership*'
}

Add-Test 'rejects duplicate task ID' {
    $fixture = New-Fixture 'duplicate-task-id'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' ((New-Task 'backend-001') + "`n## Task backend-001: repeated declaration`n")
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*duplicate task ID*'
}

Add-Test 'rejects duplicate task checkbox' {
    $fixture = New-Fixture 'duplicate-task-checkbox'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' ((New-Task 'backend-001') + "`n" + (New-Task 'backend-001'))
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*duplicate task checkbox*'
}

Add-Test 'rejects checkbox in non-task fragment' {
    $fixture = New-Fixture 'checkbox-in-non-task'
    Add-SplitArtifact $fixture 'tasks/backend' @(
        [pscustomobject]@{ Order = 1; File = '01-context.md'; Kind = 'context'; Owns = 'constraints'; Content = (New-Task 'backend-001') }
        [pscustomobject]@{ Order = 2; File = '05-interface.md'; Kind = 'interface'; Owns = 'interfaces'; Content = "# Interface`n" }
        [pscustomobject]@{ Order = 3; File = '10-tasks.md'; Kind = 'tasks'; Owns = 'backend-002'; Content = (New-Task 'backend-002') }
        [pscustomobject]@{ Order = 4; File = '90-coverage.md'; Kind = 'coverage'; Owns = 'coverage'; Content = "# Coverage`n" }
    )
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*checkbox in non-task file*'
}

$ArtifactCheckboxTestBody = {
        param([string]$FixtureName, [string]$Path, [string]$Name)
        $fixture = New-Fixture $FixtureName
        if ($Name -eq 'PRD') { Write-FixtureFile $fixture $Path ((New-ValidPrd) + "`n" + (New-Task 'backend-001')) }
        elseif ($Name -eq 'proposal') { Write-FixtureFile $fixture $Path ((New-ValidProposal) + "`n" + (New-Task 'backend-001')) }
        else {
            Write-FixtureFile $fixture $Path (New-Task 'backend-001')
            Write-FixtureFile $fixture 'design/00-index.md' (New-DesignIndex @([pscustomobject]@{ End = 'Backend'; Entry = 'design/backend.md'; Mode = 'small' }))
        }
        Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*task checkbox in non-task file*'
}
foreach ($artifact in @(
    @{ Name = 'PRD'; Path = 'prd.md' },
    @{ Name = 'proposal'; Path = 'proposal.md' },
    @{ Name = 'design'; Path = 'design/backend.md' }
)) {
    Add-Test "rejects executable task checkbox in $($artifact.Name)" $ArtifactCheckboxTestBody @("checkbox-in-$($artifact.Name.ToLowerInvariant())", $artifact.Path, $artifact.Name)
}

Add-Test 'rejects overview for a single-end plan' {
    $fixture = New-Fixture 'single-end-overview'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001')
    Write-FixtureFile $fixture 'tasks/00-overview.md' (New-Overview @([pscustomobject]@{ Sequence = 1; Id = 'backend-001'; Owner = 'tasks/plan-backend.md'; DependsOn = 'None' }))
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*single-end plan*'
}

Add-Test 'rejects missing overview for a two-end plan' {
    $fixture = New-Fixture 'missing-two-end-overview'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001')
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*two-end plan requires*'
}

Add-Test 'rejects missing cross-end task ID' {
    $fixture = New-Fixture 'missing-cross-end-id'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001' 'backend-999')
    Write-FixtureFile $fixture 'tasks/00-overview.md' (New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 1 0 1 0)
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*unknown dependency backend-999*'
}

Add-Test 'rejects arbitrary text in overview dependency edge' {
    $fixture = New-Fixture 'invalid-dependency-edge-syntax'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001' 'backend-001')
    $overview = New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 1 0 1 0 @(
        [pscustomobject]@{ From = 'backend-001'; To = 'frontend-001'; Gate = 'API contract' }
    )
    Write-FixtureFile $fixture 'tasks/00-overview.md' $overview.Replace('`backend-001`', 'run after backend review')
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*invalid dependency edge task ID*'
}

Add-Test 'rejects missing cross-end dependency edge' {
    $fixture = New-Fixture 'missing-cross-end-edge'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001' 'backend-001')
    Write-FixtureFile $fixture 'tasks/00-overview.md' (New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 1 0 1 0)
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*missing cross-end dependency edge backend-001->frontend-001*'
}

Add-Test 'rejects reversed cross-end dependency edge' {
    $fixture = New-Fixture 'reversed-cross-end-edge'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001' 'backend-001')
    Write-FixtureFile $fixture 'tasks/00-overview.md' (New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 1 0 1 0 @(
        [pscustomobject]@{ From = 'frontend-001'; To = 'backend-001'; Gate = 'reversed' }
    ))
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*missing cross-end dependency edge backend-001->frontend-001*'
}

Add-Test 'rejects duplicate cross-end dependency edge' {
    $fixture = New-Fixture 'duplicate-cross-end-edge'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001' 'backend-001')
    Write-FixtureFile $fixture 'tasks/00-overview.md' (New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 1 0 1 0 @(
        [pscustomobject]@{ From = 'backend-001'; To = 'frontend-001'; Gate = 'first' }
        [pscustomobject]@{ From = 'backend-001'; To = 'frontend-001'; Gate = 'duplicate' }
    ))
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*duplicates cross-end dependency edge backend-001->frontend-001*'
}

Add-Test 'rejects overview edge absent from owner dependency graph' {
    $fixture = New-Fixture 'undeclared-cross-end-edge'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001')
    Write-FixtureFile $fixture 'tasks/00-overview.md' (New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 1 0 1 0 @(
        [pscustomobject]@{ From = 'backend-001'; To = 'frontend-001'; Gate = 'not declared by owner' }
    ))
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*declares invalid cross-end dependency edge backend-001->frontend-001*'
}

Add-Test 'rejects unknown task ID in cross-end dependency edge' {
    $fixture = New-Fixture 'unknown-cross-end-edge-id'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001' 'backend-001')
    Write-FixtureFile $fixture 'tasks/00-overview.md' (New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 1 0 1 0 @(
        [pscustomobject]@{ From = 'backend-999'; To = 'frontend-001'; Gate = 'unknown provider' }
    ))
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*edge references unknown task ID backend-999*'
}

Add-Test 'rejects same-end or self dependency edge' {
    $fixture = New-Fixture 'same-end-overview-edge'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001')
    Write-FixtureFile $fixture 'tasks/00-overview.md' (New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 1 0 1 0 @(
        [pscustomobject]@{ From = 'backend-001'; To = 'backend-001'; Gate = 'self' }
    ))
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*dependency edge must connect different tasks from different ends*'
}

Add-Test 'rejects stages that omit required cross-end edge declaration' {
    $fixture = New-Fixture 'stage-does-not-replace-edge'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001' 'backend-001')
    $stages = @(
        '## Cross-end Execution Stages', '',
        '| Stage | Ends / cross-end gate | Exit condition |',
        '| ---: | --- | --- |',
        '| 1 | Backend provider | `backend-001` ready |',
        '| 2 | Frontend consumer | `frontend-001` ready |', ''
    ) -join "`n"
    $overview = (New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 1 0 1 0).Replace('## Progress Totals', "$stages`n## Progress Totals")
    Write-FixtureFile $fixture 'tasks/00-overview.md' $overview
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*missing cross-end dependency edge backend-001->frontend-001*'
}

Add-Test 'accepts the cross-end-only overview recipe' {
    $fixture = New-Fixture 'valid-cross-end-overview-recipe'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001' 'backend-001')
    $overview = New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 1 0 1 0 @(
        [pscustomobject]@{ From = 'backend-001'; To = 'frontend-001'; Gate = 'API contract' }
    )
    Write-FixtureFile $fixture 'tasks/00-overview.md' $overview
    $output = Invoke-Validation $fixture
    Assert-Condition (($output -join "`n") -like '*Artifact layout valid:*') 'cross-end-only overview recipe should pass'
}

Add-Test 'accepts cross-end execution stages with the required edge table' {
    $fixture = New-Fixture 'valid-overview-stages-and-edges'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' ((New-Task 'backend-001') + "`n" + (New-Task 'backend-002' 'backend-001'))
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001' 'backend-002')
    $stages = @(
        '## Cross-end Execution Stages', '',
        '| Stage | Ends / cross-end gate | Exit condition |',
        '| ---: | --- | --- |',
        '| 1 | Backend contract provider | `backend-001` and `backend-002` API ready |',
        '| 2 | Frontend contract consumer | `frontend-001` UI ready |', ''
    ) -join "`n"
    $overview = (New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 2 0 1 0 @(
        [pscustomobject]@{ From = 'backend-002'; To = 'frontend-001'; Gate = 'API contract' }
    )).Replace('## Progress Totals', "$stages`n## Progress Totals")
    Write-FixtureFile $fixture 'tasks/00-overview.md' $overview
    $output = Invoke-Validation $fixture
    Assert-Condition (($output -join "`n") -like '*Artifact layout valid:*') 'edge plus stage cross-end relationship should pass'
}

Add-Test 'rejects detailed prose before the overview execution table' {
    $fixture = New-Fixture 'overview-detail-before-table'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001')
    $overview = (New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 1 0 1 0).Replace('| End | Canonical entrypoint | Mode |', "Backend service implementation must persist the policy before UI work starts.`n`n| End | Canonical entrypoint | Mode |")
    Write-FixtureFile $fixture 'tasks/00-overview.md' $overview
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*overview contains same-end implementation details or prose*'
}

Add-Test 'rejects detailed prose after the overview execution table' {
    $fixture = New-Fixture 'overview-detail-after-table'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001')
    $overview = (New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 1 0 1 0) + "`n## Backend Implementation Details`n`nPersist the policy through the repository service.`n"
    Write-FixtureFile $fixture 'tasks/00-overview.md' $overview
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*overview contains same-end implementation details or prose*'
}

Add-Test 'rejects dependency cycle' {
    $fixture = New-Fixture 'dependency-cycle'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' (New-Task 'backend-001' 'frontend-001')
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' (New-Task 'frontend-001' 'backend-001')
    Write-FixtureFile $fixture 'tasks/00-overview.md' (New-CanonicalOverview 'tasks/plan-backend.md' 'small' 'tasks/plan-frontend.md' 'small' 1 0 1 0)
    Assert-ThrowsLike { Invoke-Validation $fixture } 'Artifact layout invalid:*dependency cycle*'
}

Add-Test 'consumer reports every combined plan conflict' {
    $fixture = New-Fixture 'consumer-all-plan-conflicts'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' "# Backend plan`n`nObsolete summary and navigation.`n"
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' "# Frontend plan`n`nObsolete summary and navigation.`n"
    Add-SplitArtifact $fixture 'tasks/backend' @([pscustomobject]@{ Order = 1; File = '10-tasks.md'; Kind = 'tasks'; Owns = 'backend-001'; Content = (New-Task 'backend-001') })
    Add-SplitArtifact $fixture 'tasks/frontend' @([pscustomobject]@{ Order = 1; File = '10-tasks.md'; Kind = 'tasks'; Owns = 'frontend-001'; Content = (New-Task 'frontend-001' 'backend-001') })
    Assert-ThrowsContaining { Invoke-Validation $fixture 'Consumer' } @(
        'tasks/plan-backend.md plus tasks/backend/'
        'tasks/plan-frontend.md plus tasks/frontend/'
    )
}

Add-Test 'producer reports every combined plan conflict' {
    $fixture = New-Fixture 'producer-all-plan-conflicts'
    Write-FixtureFile $fixture 'tasks/plan-backend.md' "# Backend plan`n"
    Write-FixtureFile $fixture 'tasks/plan-frontend.md' "# Frontend plan`n"
    Add-SplitArtifact $fixture 'tasks/backend' @([pscustomobject]@{ Order = 1; File = '10-tasks.md'; Kind = 'tasks'; Owns = 'backend-001'; Content = (New-Task 'backend-001') })
    Add-SplitArtifact $fixture 'tasks/frontend' @([pscustomobject]@{ Order = 1; File = '10-tasks.md'; Kind = 'tasks'; Owns = 'frontend-001'; Content = (New-Task 'frontend-001' 'backend-001') })
    Assert-ThrowsContaining { Invoke-Validation $fixture 'Producer' } @(
        'tasks/plan-backend.md plus tasks/backend/'
        'tasks/plan-frontend.md plus tasks/frontend/'
    )
}

$HistoricalDesignTestBody = {
        param([string]$Mode)
        $fixture = New-Fixture ("historical-root-design-" + $Mode.ToLowerInvariant())
        Write-FixtureFile $fixture 'design-backend.md' "# Historical backend design`n"
        Assert-ThrowsLike { Invoke-Validation $fixture $Mode } 'Artifact layout invalid:*design-backend.md is not a supported artifact layout*'
}
foreach ($mode in @('Producer', 'Consumer')) {
    Add-Test "rejects historical root design in $($mode.ToLowerInvariant()) mode" $HistoricalDesignTestBody @($mode)
}

$Passed = 0
$Failures = [Collections.Generic.List[string]]::new()
try {
    foreach ($test in $Tests) {
        try {
            $testArguments = @($test.Arguments)
            & $test.Body @testArguments
            $Passed++
            Write-Host "PASS: $($test.Name)"
        }
        catch {
            Write-Host "FAIL: $($test.Name)"
            Write-Host $_.Exception.Message
            $Failures.Add($test.Name)
        }
    }
    if ($Failures.Count -gt 0) {
        throw "Artifact layout tests failed: $($Failures.Count)/$($Tests.Count) fixture classes: $($Failures -join ', ')"
    }
    Write-Host "Artifact layout tests passed: $Passed/$($Tests.Count) fixture classes."
}
finally {
    if (Test-Path -LiteralPath $ResolvedTempRoot) {
        $candidate = [IO.Path]::GetFullPath($ResolvedTempRoot)
        if ((Split-Path -Parent $candidate) -eq $SystemTemp -and (Split-Path -Leaf $candidate) -like 'featurepilot-artifact-layout-tests-*') {
            Remove-Item -LiteralPath $candidate -Recurse -Force
        }
    }
}
