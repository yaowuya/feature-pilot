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
        ) "$surface lost visual-evidence anchor: $anchor"
    }
}

function Test-ContainsAnchors([string]$text, [string[]]$anchors) {
    foreach ($anchor in $anchors) {
        if ($text.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            return $false
        }
    }
    return $true
}

function Get-MarkdownSection([string]$text, [string]$headingPrefix, [string]$surface) {
    $pattern = "(?ms)^#{2,3} (?:\d+(?:\.\d+)*\s+)?$([regex]::Escape($headingPrefix))[^\r\n]*\r?\n(?<body>.*?)(?=^#{2,3} |\z)"
    $match = [regex]::Match($text, $pattern)
    Assert-Condition $match.Success "$surface is missing persisted output section: $headingPrefix"
    if (-not $match.Success) { return '' }
    return $match.Value
}

function Get-MarkdownTables([string]$section) {
    $lines = @($section -split '\r?\n')
    $tables = [System.Collections.Generic.List[hashtable]]::new()
    for ($index = 0; $index -lt ($lines.Count - 1); $index++) {
        if ($lines[$index].TrimStart().StartsWith('|') -and
            $lines[$index + 1].TrimStart().StartsWith('|')) {
            $rows = [System.Collections.Generic.List[string]]::new()
            $rowIndex = $index + 2
            while ($rowIndex -lt $lines.Count -and $lines[$rowIndex].TrimStart().StartsWith('|')) {
                $rows.Add($lines[$rowIndex].Trim())
                $rowIndex++
            }
            $tables.Add(@{
                Header = $lines[$index].Trim()
                Separator = $lines[$index + 1].Trim()
                Row = if ($rows.Count -gt 0) { $rows[0] } else { '' }
                Rows = $rows.ToArray()
            })
            $index = $rowIndex - 1
        }
    }
    return $tables.ToArray()
}

function Get-MarkdownCells([string]$line) {
    return @(
        $line.Trim().Trim('|').Split('|') |
            ForEach-Object { $_.Trim() }
    )
}

function Normalize-MarkdownCell([string]$cell) {
    return $cell.Trim().Trim('`')
}

function Replace-Required(
    [string]$text,
    [string]$oldValue,
    [string]$newValue,
    [string]$mutationName
) {
    if ($text.IndexOf($oldValue, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw "Invalid mutation fixture; production text was not hit: $mutationName"
    }
    return [regex]::Replace(
        $text,
        [regex]::Escape($oldValue),
        $newValue,
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
}

function Insert-AfterRequired(
    [string]$text,
    [string]$marker,
    [string]$payload,
    [string]$mutationName
) {
    $index = $text.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase)
    if ($index -lt 0) {
        throw "Invalid mutation fixture; production text was not hit: $mutationName"
    }
    $insertAt = $index + $marker.Length
    return $text.Substring(0, $insertAt) + $payload + $text.Substring($insertAt)
}

$canonicalHeader = '| Case ID | Approved design source | Figma node | revision/time | Frame/variant | variables / Auto Layout / assets | Runtime route | Scenario/state | Viewport | DPR | Locale | Theme | Deterministic non-sensitive fixture | Reference path | Current path | Diff path / missing diff | Mask | Acceptance rule | Command/tool | Failure class | Result |'
$canonicalSeparator = '| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |'
$canonicalColumns = Get-MarkdownCells $canonicalHeader
$canonicalVisualProvenance = 'Provenance: reference.png -> approved Figma/static design source; current.png -> real target runtime.'
$canonicalVisualGuardrails = 'Local runtime screenshot must not replace reference.png. current.png requires stable data and stable environment. Optional diff/missing diff explanation must not hide absent core source/runtime evidence.'
$canonicalBrowserScreenshotSeparation = 'Evidence channels: browser interaction evidence is separate from screenshot evidence; browser interaction evidence must exercise approved states, and screenshot evidence must record case artifacts.'
$canonicalCoreBlockerDebt = 'Core source/runtime missing is CANNOT_VERIFY and a main-flow blocker; it never becomes review debt. At attempt 3, only a reproducible non-core cosmetic FAIL difference may become review debt; all other non-core FAIL/CANNOT_VERIFY cases are BLOCKER.'
$visualDecisionHeader = '| Rule ID | Planned visual scope | Core source/runtime | Visual evidence verdict | Attempt | Reproducible non-core cosmetic FAIL | Disposition | Combined PASS eligible |'
$visualDecisionSeparator = '| --- | --- | --- | --- | --- | --- | --- | --- |'
$visualDecisionRows = @(
    '| NO_VISUAL | no | N/A | N/A | N/A | N/A | N/A | N/A |',
    '| CORE_GAP | yes | missing | any | 1..3 | any | BLOCKER | no |',
    '| VISUAL_PASS | yes | trustworthy | PASS | 1..3 | N/A | ELIGIBLE | yes |',
    '| RETRY_NONPASS | yes | trustworthy | FAIL or CANNOT_VERIFY | 1..2 | N/A | NON_PASS | no |',
    '| ATTEMPT3_COSMETIC | yes | trustworthy | FAIL | 3 | yes | DEBT | no |',
    '| ATTEMPT3_OTHER_FAIL | yes | trustworthy | FAIL | 3 | no | BLOCKER | no |',
    '| ATTEMPT3_OTHER_CANNOT_VERIFY | yes | trustworthy | CANNOT_VERIFY | 3 | N/A | BLOCKER | no |'
)
$canonicalDecisionExplanation = 'Apply exactly one Rule ID to every task review. The table is mutually exclusive and exhaustive; no prose exception is permitted.'

function Test-CanonicalVisualTable([string]$section) {
    $tables = @(Get-MarkdownTables $section)
    if ($tables.Count -ne 1) {
        return $false
    }
    $table = $tables[0]
    if (-not $table.Header.Equals($canonicalHeader, [System.StringComparison]::Ordinal)) {
        return $false
    }

    $separatorCells = Get-MarkdownCells $table.Separator
    if (-not $table.Separator.Equals($canonicalSeparator, [System.StringComparison]::Ordinal) -or
        $separatorCells.Count -ne $canonicalColumns.Count -or
        @($separatorCells | Where-Object { $_ -ne '---' }).Count -ne 0) {
        return $false
    }

    $rowCells = Get-MarkdownCells $table.Row
    if ($rowCells.Count -ne $canonicalColumns.Count) {
        return $false
    }

    $referenceIndex = [array]::IndexOf($canonicalColumns, 'Reference path')
    $currentIndex = [array]::IndexOf($canonicalColumns, 'Current path')
    $commandIndex = [array]::IndexOf($canonicalColumns, 'Command/tool')
    return (Normalize-MarkdownCell $rowCells[$referenceIndex]) -eq '.fp-execute/visual/<task-id>/<case-id>/reference.png' -and
        (Normalize-MarkdownCell $rowCells[$currentIndex]) -eq '.fp-execute/visual/<task-id>/<case-id>/current.png' -and
        $rowCells[$commandIndex].IndexOf('project-configured', [System.StringComparison]::OrdinalIgnoreCase) -ge 0
}

function Test-SourceRuntimeProvenance([string]$text) {
    return $text.IndexOf($canonicalVisualProvenance, [System.StringComparison]::Ordinal) -ge 0 -and
        $text.IndexOf($canonicalVisualGuardrails, [System.StringComparison]::Ordinal) -ge 0 -and
        [regex]::Matches($text, '(?m)^\s*(?:[-*]\s*)?Provenance:').Count -eq 1 -and
        $text -notmatch '(?i)reference\.png\s*->\s*real target runtime' -and
        $text -notmatch '(?i)current\.png\s*->\s*approved Figma/static design source'
}

function Test-DecisionField([string]$ruleValue, [string]$actualValue) {
    if ($ruleValue -eq 'any') {
        return $true
    }
    if ($ruleValue -match '^(\d+)\.\.(\d+)$') {
        return [int]$actualValue -ge [int]$matches[1] -and [int]$actualValue -le [int]$matches[2]
    }
    if ($ruleValue.Contains(' or ')) {
        return @($ruleValue -split ' or ') -contains $actualValue
    }
    return $ruleValue -eq $actualValue
}

function Test-DecisionRowMatches([string[]]$cells, [hashtable]$tuple) {
    return (Test-DecisionField $cells[1] $tuple.Scope) -and
        (Test-DecisionField $cells[2] $tuple.Core) -and
        (Test-DecisionField $cells[3] $tuple.Verdict) -and
        (Test-DecisionField $cells[4] $tuple.Attempt) -and
        (Test-DecisionField $cells[5] $tuple.Cosmetic)
}

function Test-DecisionTupleCoverage([object[]]$rows) {
    $tuples = [System.Collections.Generic.List[hashtable]]::new()
    $tuples.Add(@{ Scope = 'no'; Core = 'N/A'; Verdict = 'N/A'; Attempt = 'N/A'; Cosmetic = 'N/A'; Rule = 'NO_VISUAL' })

    foreach ($verdict in @('PASS', 'FAIL', 'CANNOT_VERIFY')) {
        foreach ($attempt in @('1', '2', '3')) {
            $tuples.Add(@{ Scope = 'yes'; Core = 'missing'; Verdict = $verdict; Attempt = $attempt; Cosmetic = 'N/A'; Rule = 'CORE_GAP' })
        }
    }

    foreach ($attempt in @('1', '2', '3')) {
        $tuples.Add(@{ Scope = 'yes'; Core = 'trustworthy'; Verdict = 'PASS'; Attempt = $attempt; Cosmetic = 'N/A'; Rule = 'VISUAL_PASS' })
    }

    foreach ($verdict in @('FAIL', 'CANNOT_VERIFY')) {
        foreach ($attempt in @('1', '2')) {
            $tuples.Add(@{ Scope = 'yes'; Core = 'trustworthy'; Verdict = $verdict; Attempt = $attempt; Cosmetic = 'N/A'; Rule = 'RETRY_NONPASS' })
        }
    }

    $tuples.Add(@{ Scope = 'yes'; Core = 'trustworthy'; Verdict = 'FAIL'; Attempt = '3'; Cosmetic = 'yes'; Rule = 'ATTEMPT3_COSMETIC' })
    $tuples.Add(@{ Scope = 'yes'; Core = 'trustworthy'; Verdict = 'FAIL'; Attempt = '3'; Cosmetic = 'no'; Rule = 'ATTEMPT3_OTHER_FAIL' })
    $tuples.Add(@{ Scope = 'yes'; Core = 'trustworthy'; Verdict = 'CANNOT_VERIFY'; Attempt = '3'; Cosmetic = 'N/A'; Rule = 'ATTEMPT3_OTHER_CANNOT_VERIFY' })

    foreach ($tuple in $tuples) {
        $matches = @(
            foreach ($row in $rows) {
                $cells = Get-MarkdownCells $row
                if (Test-DecisionRowMatches $cells $tuple) {
                    $cells[0]
                }
            }
        )
        if ($matches.Count -ne 1 -or $matches[0] -ne $tuple.Rule) {
            return $false
        }
    }
    return $true
}

function Test-VisualDecisionTable([string]$text) {
    $tables = @(Get-MarkdownTables $text)
    if ($tables.Count -ne 1) {
        return $false
    }
    $table = $tables[0]
    if (-not $table.Header.Equals($visualDecisionHeader, [System.StringComparison]::Ordinal) -or
        -not $table.Separator.Equals($visualDecisionSeparator, [System.StringComparison]::Ordinal) -or
        $table.Rows.Count -ne $visualDecisionRows.Count) {
        return $false
    }

    for ($index = 0; $index -lt $visualDecisionRows.Count; $index++) {
        if (-not $table.Rows[$index].Equals($visualDecisionRows[$index], [System.StringComparison]::Ordinal)) {
            return $false
        }
    }

    $nonTableLines = @(
        $text -split '\r?\n' |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -ne '' -and -not $_.StartsWith('|') }
    )
    $expectedNonTableLines = @(
        '### Visual review decision table',
        $canonicalDecisionExplanation
    )
    if ($nonTableLines.Count -ne $expectedNonTableLines.Count) {
        return $false
    }
    for ($index = 0; $index -lt $expectedNonTableLines.Count; $index++) {
        if ($nonTableLines[$index] -ne $expectedNonTableLines[$index]) {
            return $false
        }
    }
    return Test-DecisionTupleCoverage $table.Rows
}

function Test-CoreBlockerDebt([string]$text) {
    return $text.IndexOf($canonicalCoreBlockerDebt, [System.StringComparison]::Ordinal) -ge 0
}

function Test-PublicNeutrality([string]$text) {
    return $text -notmatch '(?i)Required:\s*Vue' -and
        $text -notmatch '(?i)Vite\s+dev\s+server' -and
        $text -notmatch '(?i)\b(?:npx|npm\s+exec|pnpm\s+exec|yarn(?:\s+dlx)?|bunx)\b[^\r\n]{0,80}\bplaywright\b' -and
        $text -notmatch '(?i)https://(?:www\.)?figma\.com/' -and
        $text -notmatch '(?i)https://customer\.' -and
        $text -notmatch '(?i)(?:C:\\visual-evidence|/opt/customer/visual|s3://customer-visual)' -and
        $text -notmatch '(?i)--customer-(?:token|color)' -and
        $text -notmatch '(?i)Use fixture:\s*production database dump'
}

function Test-CodeConnectBoundary([string]$text) {
    return (Test-ContainsAnchors $text @(
        'Code Connect',
        'optional enhancement',
        'absence does not block ordinary UI',
        'must not auto-create',
        '.figma.ts',
        'must not change tsconfig',
        'must not install dependencies',
        'ordinary UI'
    )) -and
        ($text -notmatch '(?i)Code Connect[^\r\n]{0,100}\b(?:required|mandatory|blocker)\b')
}

function Test-ExactVisualVerdict([string]$section) {
    $matches = [regex]::Matches(
        $section,
        '(?m)^Visual evidence:\s*(?<value>[^\r\n]*)\r?$'
    )
    return $matches.Count -eq 1 -and
        $matches[0].Groups['value'].Value -eq 'PASS | FAIL | CANNOT_VERIFY'
}

function Test-BrowserScreenshotSeparation([string]$text) {
    return $text.IndexOf($canonicalBrowserScreenshotSeparation, [System.StringComparison]::Ordinal) -ge 0 -and
        [regex]::Matches($text, '(?mi)^\s*(?:[-*]\s*)?Evidence channels:').Count -eq 1 -and
        $text -notmatch '(?i)browser interaction evidence\s+is\s+not\s+separate\s+from\s+screenshot evidence'
}

$figma = Read-Utf8 'skills\fp-figma\SKILL.md'
$planSkill = Read-Utf8 'skills\fp-plan-frontend\SKILL.md'
$planTemplate = Read-Utf8 'skills\fp-plan-frontend\plan-template.md'
$executeSkill = Read-Utf8 'skills\fp-execute-sdd\SKILL.md'
$brief = Read-Utf8 'skills\fp-execute-sdd\task-brief-template.md'
$implementer = Read-Utf8 'skills\fp-execute-sdd\implementer-prompt.md'
$package = Read-Utf8 'skills\fp-execute-sdd\review-package-template.md'
$taskReviewer = Read-Utf8 'skills\fp-execute-sdd\task-reviewer-prompt.md'
$reviewSkill = Read-Utf8 'skills\fp-review\SKILL.md'
$finalReviewer = Read-Utf8 'skills\fp-review\final-reviewer.md'
$finalTemplate = Read-Utf8 'skills\fp-review\final-review-template.md'
$finalPackage = Read-Utf8 'skills\fp-review\final-review-package-template.md'
$validator = Read-Utf8 'scripts\validate-plugin.ps1'
$focusedValidatorSource = Read-Utf8 'scripts\test-figma-evidence-contract.ps1'
$mutationFixtureMarker = '# Mutation fixtures operate only in memory'
$mutationFixtureStart = $focusedValidatorSource.IndexOf($mutationFixtureMarker, [System.StringComparison]::Ordinal)
$mutationFixtureSource = if ($mutationFixtureStart -ge 0) {
    $focusedValidatorSource.Substring($mutationFixtureStart)
} else {
    ''
}
$conditionalMutationFixtures = @(
    'if (' + 'Test-CanonicalVisualTable $packageOutput)',
    'if (' + 'Test-BrowserScreenshotSeparation $briefOutput)',
    'if (' + 'Test-ExactVisualVerdict $finalPackageOutput)',
    'if (' + 'Test-VisualDecisionTable $decisionOutput)',
    'if (' + 'Test-SourceRuntimeProvenance $briefOutput)',
    'if (' + 'Test-SourceRuntimeProvenance $packageOutput)',
    'if (' + 'Test-CoreBlockerDebt $finalPackageOutput)'
)
Assert-Condition (
    $mutationFixtureStart -ge 0
) 'focused validator is missing its mutation fixture boundary marker'
foreach ($conditionalMutationFixture in $conditionalMutationFixtures) {
    Assert-Condition (
        $mutationFixtureSource.IndexOf($conditionalMutationFixture, [System.StringComparison]::Ordinal) -lt 0
    ) "mutation fixture must fail fast instead of being conditionally skipped: $conditionalMutationFixture"
}

Assert-Anchors $figma @(
    'get_design_context',
    'before implementation',
    'Figma MCP',
    'specified node',
    'revision/time',
    'frame/variant',
    'variables',
    'Auto Layout',
    'assets',
    'explicitly approved source',
    'blocker',
    'do not fabricate',
    'Code Connect',
    'optional enhancement',
    '.figma.ts',
    'tsconfig',
    'install dependencies'
) 'fp-figma'

$plannedCaseAnchors = @(
    'Visual Evidence Manifest',
    '.fp-execute/visual/<task-id>/<case-id>/',
    'manifest.md',
    'reference.png',
    'current.png',
    'diff.png'
)
Assert-Anchors $planSkill $plannedCaseAnchors 'frontend plan skill'
Assert-Anchors $planTemplate $plannedCaseAnchors 'frontend plan template'

$planSkillOutput = Get-MarkdownSection $planSkill 'Planning rules' 'frontend plan skill'
$planOutput = Get-MarkdownSection $planTemplate 'Visual Evidence Manifest' 'frontend plan template'
$executeVisualOutput = Get-MarkdownSection $executeSkill 'Visual Evidence Contract' 'execute skill'
$briefOutput = Get-MarkdownSection $brief 'Visual Evidence Manifest' 'task brief'
$implementerOutput = Get-MarkdownSection $implementer 'Visual Evidence' 'implementer report'
$packageOutput = Get-MarkdownSection $package 'Visual Evidence Manifest' 'review package'
$reviewerOutput = Get-MarkdownSection $taskReviewer 'Frontend Visual Review' 'task reviewer persisted output'
$reviewVisualOutput = Get-MarkdownSection $reviewSkill '2.1 Visual Evidence Gate' 'final review skill'
$finalReviewerOutput = Get-MarkdownSection $finalReviewer 'Required Method' 'final reviewer'
$finalOutput = Get-MarkdownSection $finalTemplate 'Visual Evidence' 'final report'
$finalPackageOutput = Get-MarkdownSection $finalPackage 'Visual Evidence' 'final review package'
$decisionOutput = Get-MarkdownSection $executeSkill 'Visual review decision table' 'visual decision table'

foreach ($surface in @(
    @{ Name = 'frontend plan table'; Text = $planOutput }
    @{ Name = 'task brief table'; Text = $briefOutput }
    @{ Name = 'implementer report table'; Text = $implementerOutput }
    @{ Name = 'review package table'; Text = $packageOutput }
    @{ Name = 'task reviewer table'; Text = $reviewerOutput }
    @{ Name = 'final report table'; Text = $finalOutput }
    @{ Name = 'final review package table'; Text = $finalPackageOutput }
)) {
    Assert-Condition (Test-CanonicalVisualTable $surface.Text) "$($surface.Name) is not the canonical parsed Visual Evidence table"
}

foreach ($surface in @(
    @{ Name = 'frontend plan skill'; Text = $planSkillOutput }
    @{ Name = 'frontend plan template'; Text = $planOutput }
    @{ Name = 'execute skill'; Text = $executeVisualOutput }
    @{ Name = 'task brief'; Text = $briefOutput }
    @{ Name = 'implementer report'; Text = $implementerOutput }
    @{ Name = 'review package'; Text = $packageOutput }
    @{ Name = 'task reviewer'; Text = $reviewerOutput }
    @{ Name = 'final review skill'; Text = $reviewVisualOutput }
    @{ Name = 'final reviewer'; Text = $finalReviewerOutput }
    @{ Name = 'final report'; Text = $finalOutput }
    @{ Name = 'final review package'; Text = $finalPackageOutput }
)) {
    Assert-Condition (Test-SourceRuntimeProvenance $surface.Text) "$($surface.Name) lost independent source/runtime provenance"
    Assert-Condition (Test-BrowserScreenshotSeparation $surface.Text) "$($surface.Name) lost browser/screenshot separation"
}

Assert-Anchors $taskReviewer @(
    'Visual evidence: PASS | FAIL | CANNOT_VERIFY',
    'trustworthy source',
    'trustworthy runtime',
    'CANNOT_VERIFY',
    'main-flow blocker',
    'Missing evidence',
    'must not become review debt'
) 'task reviewer verdict'

Assert-Condition (Test-ExactVisualVerdict $reviewerOutput) 'task reviewer visual verdict is not exactly one canonical line'
Assert-Condition (Test-ExactVisualVerdict $finalOutput) 'final report visual verdict is not exactly one canonical line'
Assert-Condition (Test-ExactVisualVerdict $finalPackageOutput) 'final review package visual verdict is not exactly one canonical line'
Assert-Condition (Test-VisualDecisionTable $decisionOutput) 'visual decision table is not the ordered, exhaustive canonical classifier'
Assert-Condition (Test-CoreBlockerDebt $finalPackageOutput) 'final review package does not preserve core visual blocker/debt rules'
Assert-Anchors $finalPackageOutput @(
    'Case artifacts',
    'manifest.md',
    'reference.png',
    'current.png',
    'diff.png',
    'Visual evidence: PASS | FAIL | CANNOT_VERIFY'
) 'final review package visual evidence'

foreach ($surface in @(
    @{ Name = 'execute'; Text = $executeSkill }
    @{ Name = 'task reviewer'; Text = $taskReviewer }
    @{ Name = 'final review'; Text = $reviewSkill + $finalReviewer }
)) {
    Assert-Anchors $surface.Text @(
        'attempt 3',
        'reproducible non-core cosmetic differences',
        'review debt',
        'core visual',
        'main-flow blocker'
    ) $surface.Name
}

Assert-Anchors $finalTemplate @(
    '## Visual Evidence',
    'Visual evidence: PASS | FAIL | CANNOT_VERIFY'
) 'final report Visual Evidence section'

Assert-Anchors $finalPackage @(
    '## Visual Evidence',
    'Visual evidence: PASS | FAIL | CANNOT_VERIFY'
) 'final review package Visual Evidence section'

$allPublicContracts = @(
    $figma,
    $planSkill,
    $planTemplate,
    $executeSkill,
    $brief,
    $implementer,
    $package,
    $taskReviewer,
    $reviewSkill,
    $finalReviewer,
    $finalTemplate,
    $finalPackage
) -join "`n"

Assert-Condition (
    $allPublicContracts.IndexOf(
        'screenshot/browser/manual check path or reason',
        [System.StringComparison]::OrdinalIgnoreCase
    ) -lt 0
) 'generic screenshot/browser/manual-check path-or-reason escape hatch is still present'

Assert-Anchors $planSkill @(
    'project-configured',
    'browser runner',
    'do not silently install',
    'explicit task',
    'authorization',
    'do not define a global pixel threshold'
) 'runner-neutral frontend planning'

Assert-Condition (Test-CodeConnectBoundary $figma) 'optional Code Connect boundary is incomplete'
Assert-Condition (Test-PublicNeutrality $allPublicContracts) 'public visual-evidence contract contains a framework/runner/URL/storage/customer/fixture assumption'

# Mutation fixtures operate only in memory and are intentionally excluded from
# $allPublicContracts, so their forbidden examples cannot self-trigger checks.
$mutatedImplementer = Replace-Required $implementerOutput 'Approved design source' '' 'implementer drops approved source'
Assert-Condition (-not (Test-CanonicalVisualTable $mutatedImplementer)) 'mutation survived: implementer may drop a schema field'

$mutatedReviewer = Replace-Required $reviewerOutput 'Figma node' '' 'reviewer drops Figma node'
Assert-Condition (-not (Test-CanonicalVisualTable $mutatedReviewer)) 'mutation survived: reviewer may drop a schema field'

$swappedImplementer = Replace-Required $implementerOutput '.fp-execute/visual/<task-id>/<case-id>/reference.png' '__VISUAL_REFERENCE_SENTINEL__' 'implementer reference/current swap step 1'
$swappedImplementer = Replace-Required $swappedImplementer '.fp-execute/visual/<task-id>/<case-id>/current.png' '.fp-execute/visual/<task-id>/<case-id>/reference.png' 'implementer reference/current swap step 2'
$swappedImplementer = Replace-Required $swappedImplementer '__VISUAL_REFERENCE_SENTINEL__' '.fp-execute/visual/<task-id>/<case-id>/current.png' 'implementer reference/current swap step 3'
Assert-Condition (-not (Test-CanonicalVisualTable $swappedImplementer)) 'mutation survived: implementer may swap reference/current columns'

Require-MutationBaseline (Test-CanonicalVisualTable $packageOutput) 'review package canonical visual table'
$malformedSeparator = Replace-Required $packageOutput $canonicalSeparator '| --- | --- |' 'review package shortens separator'
Assert-Condition (-not (Test-CanonicalVisualTable $malformedSeparator)) 'mutation survived: visual table separator may lose columns'

$duplicatedVisualTable = $packageOutput + [Environment]::NewLine + $packageOutput
Assert-Condition (-not (Test-CanonicalVisualTable $duplicatedVisualTable)) 'mutation survived: visual section may contain a second table'

Require-MutationBaseline (Test-BrowserScreenshotSeparation $briefOutput) 'task brief browser/screenshot separation'
$notSeparate = 'Evidence channels: browser interaction evidence is not separate from screenshot evidence; browser interaction evidence must exercise approved states, and screenshot evidence must record case artifacts.'
$mutatedBriefSeparation = Replace-Required $briefOutput $canonicalBrowserScreenshotSeparation $notSeparate 'task brief reverses browser/screenshot separation'
Assert-Condition (-not (Test-BrowserScreenshotSeparation $mutatedBriefSeparation)) 'mutation survived: browser/screenshot separation may be negated'

$mutatedReviewerVerdict = Insert-AfterRequired $reviewerOutput 'Visual evidence: PASS | FAIL | CANNOT_VERIFY' ([Environment]::NewLine + 'Visual evidence: SKIPPED') 'task reviewer appends fourth visual verdict'
Assert-Condition (-not (Test-ExactVisualVerdict $mutatedReviewerVerdict)) 'mutation survived: task reviewer may append a fourth visual verdict'

$mutatedFinalVerdict = Insert-AfterRequired $finalOutput 'Visual evidence: PASS | FAIL | CANNOT_VERIFY' ([Environment]::NewLine + 'Visual evidence: SKIPPED') 'final report appends fourth visual verdict'
Assert-Condition (-not (Test-ExactVisualVerdict $mutatedFinalVerdict)) 'mutation survived: final report may append a fourth visual verdict'

Require-MutationBaseline (Test-ExactVisualVerdict $finalPackageOutput) 'final package canonical visual verdict'
$mutatedFinalPackageVerdict = Insert-AfterRequired $finalPackageOutput 'Visual evidence: PASS | FAIL | CANNOT_VERIFY' ([Environment]::NewLine + 'Visual evidence: SKIPPED') 'final package appends fourth visual verdict'
Assert-Condition (-not (Test-ExactVisualVerdict $mutatedFinalPackageVerdict)) 'mutation survived: final review package may append a fourth visual verdict'

Require-MutationBaseline (Test-VisualDecisionTable $decisionOutput) 'visual decision table'
$contradictoryDecisionRow = [Environment]::NewLine + '| UNSAFE_EXTRA | yes | trustworthy | CANNOT_VERIFY | 3 | N/A | ELIGIBLE | yes |'
$mutatedDecisionRows = Insert-AfterRequired $decisionOutput $visualDecisionRows[-1] $contradictoryDecisionRow 'visual decision table adds contradictory row'
Assert-Condition (-not (Test-VisualDecisionTable $mutatedDecisionRows)) 'mutation survived: visual decision table may add a contradictory row'

$eligibleCannotVerify = '| RETRY_NONPASS | yes | trustworthy | FAIL or CANNOT_VERIFY | 1..2 | N/A | ELIGIBLE | yes |'
$mutatedCannotVerifyEligible = Replace-Required $decisionOutput $visualDecisionRows[3] $eligibleCannotVerify 'CANNOT_VERIFY becomes eligible'
Assert-Condition (-not (Test-VisualDecisionTable $mutatedCannotVerifyEligible)) 'mutation survived: CANNOT_VERIFY may become eligible'

$mutatedDecisionException = Insert-AfterRequired $decisionOutput $canonicalDecisionExplanation ' Exception: CANNOT_VERIFY may PASS.' 'visual decision prose exception'
Assert-Condition (-not (Test-VisualDecisionTable $mutatedDecisionException)) 'mutation survived: visual decision prose exception may grant PASS'

Require-MutationBaseline (Test-SourceRuntimeProvenance $briefOutput) 'task brief source/runtime provenance'
$swappedProvenance = 'Provenance: reference.png -> real target runtime; current.png -> approved Figma/static design source.'
$mutatedProvenance = Replace-Required $briefOutput $canonicalVisualProvenance $swappedProvenance 'reference/current provenance swapped'
Assert-Condition (-not (Test-SourceRuntimeProvenance $mutatedProvenance)) 'mutation survived: source/runtime provenance may be swapped while retaining all words'

Require-MutationBaseline (Test-SourceRuntimeProvenance $packageOutput) 'review package source/runtime provenance'
$deletedRuntimeProvenance = Replace-Required $packageOutput $canonicalVisualProvenance '' 'runtime provenance deleted'
Assert-Condition (-not (Test-SourceRuntimeProvenance $deletedRuntimeProvenance)) 'mutation survived: runtime provenance may be deleted'

Require-MutationBaseline (Test-CoreBlockerDebt $finalPackageOutput) 'final package core blocker/debt rule'
$mutatedCoreDebt = Replace-Required $finalPackageOutput $canonicalCoreBlockerDebt 'At attempt 3 core source/runtime missing may become debt.' 'core gap attempt-3 debt exception'
Assert-Condition (-not (Test-CoreBlockerDebt $mutatedCoreDebt)) 'mutation survived: core visual gap may become debt'

foreach ($fixture in @(
    @{ Name = 'Vue assumption'; Payload = ' Required: Vue.' }
    @{ Name = 'Vite assumption'; Payload = ' Vite dev server is mandatory.' }
    @{ Name = 'Playwright command'; Payload = ' Run npx playwright test.' }
    @{ Name = 'pnpm Playwright command'; Payload = ' Run pnpm exec playwright test.' }
    @{ Name = 'Figma URL'; Payload = ' Source https://www.figma.com/file/customer.' }
    @{ Name = 'customer URL'; Payload = ' Runtime https://customer.example.invalid.' }
    @{ Name = 'storage root'; Payload = ' Store at C:\visual-evidence.' }
    @{ Name = 'customer token'; Payload = ' Use --customer-token.' }
    @{ Name = 'unsafe fixture'; Payload = ' Use fixture: production database dump.' }
)) {
    $mutatedNeutrality = Insert-AfterRequired $planSkill 'project-configured Playwright/browser runner' $fixture.Payload $fixture.Name
    Assert-Condition (-not (Test-PublicNeutrality $mutatedNeutrality)) "mutation survived public neutrality: $($fixture.Name)"
}

$mutatedCodeConnectCreate = Replace-Required $figma 'must not auto-create' 'auto-create' 'Code Connect auto-generates mapping'
Assert-Condition (-not (Test-CodeConnectBoundary $mutatedCodeConnectCreate)) 'mutation survived: Code Connect may auto-generate .figma.ts'

$mutatedCodeConnectConfig = Replace-Required $figma 'must not change tsconfig' 'change tsconfig' 'Code Connect changes tsconfig'
Assert-Condition (-not (Test-CodeConnectBoundary $mutatedCodeConnectConfig)) 'mutation survived: Code Connect may change tsconfig'

$mutatedCodeConnectInstall = Replace-Required $figma 'must not install dependencies' 'install dependencies' 'Code Connect installs dependencies'
Assert-Condition (-not (Test-CodeConnectBoundary $mutatedCodeConnectInstall)) 'mutation survived: Code Connect may install dependencies'

$mutatedCodeConnectBlocker = Insert-AfterRequired $figma 'ordinary UI' ' Code Connect absence is an ordinary UI blocker.' 'Code Connect absence blocks ordinary UI'
Assert-Condition (-not (Test-CodeConnectBoundary $mutatedCodeConnectBlocker)) 'mutation survived: Code Connect absence may block ordinary UI'

Assert-Condition (
    $validator.IndexOf(
        "test-figma-evidence-contract.ps1",
        [System.StringComparison]::OrdinalIgnoreCase
    ) -ge 0
) 'global validator does not invoke the focused Figma evidence contract'

if ($failures.Count -gt 0) {
    throw "Figma evidence contract validation failed:`n- $($failures -join "`n- ")"
}

Write-Output 'Figma evidence contract validation passed.'
