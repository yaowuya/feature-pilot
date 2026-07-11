param(
    [Parameter(Mandatory)] [string]$ChangePath,
    [ValidateSet('Producer', 'Consumer')] [string]$Mode = 'Producer'
)

$ErrorActionPreference = 'Stop'

function Fail-Layout([string]$Message) {
    throw $Message
}

function Get-NormalizedPath([string]$Path) {
    return [IO.Path]::GetFullPath($Path).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
}

function Get-RelativeArtifactPath([string]$Path) {
    $fullPath = Get-NormalizedPath $Path
    $rootWithSeparator = $script:ResolvedChangePath + [IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($rootWithSeparator, [StringComparison]::OrdinalIgnoreCase)) {
        Fail-Layout "artifact path escapes change directory: $Path"
    }
    return $fullPath.Substring($rootWithSeparator.Length).Replace('\', '/')
}

function Add-SizeCandidate([string]$Path) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $key = Get-NormalizedPath $Path
        $script:SizeCandidates[$key] = $true
    }
}

function Get-TextMetrics([string]$Path) {
    $text = [IO.File]::ReadAllText($Path)
    $lineCount = [IO.File]::ReadAllLines($Path).Count
    return [pscustomobject]@{
        Lines = $lineCount
        Characters = $text.Length
    }
}

function Test-IndexMetadataOnly([string[]]$Lines, [int]$ManifestStart, [int]$ManifestEnd, [string]$IndexPath) {
    $allowedSections = @{
        'navigation' = $true
        'metadata' = $true
        'fragment manifest' = $true
        'canonical entrypoint' = $true
        'entrypoints' = $true
    }
    $headingOneCount = 0
    $currentSection = $null
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($i -ge $ManifestStart -and $i -le $ManifestEnd) { continue }
        $line = $Lines[$i].Trim()
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -match '^#\s+\S.*$') {
            if ($i -ge $ManifestStart) {
                Fail-Layout "split index requires exactly one H1 title before the manifest: $(Get-RelativeArtifactPath $IndexPath):$($i + 1)"
            }
            $headingOneCount++
            if ($headingOneCount -gt 1) {
                Fail-Layout "split index contains detailed body content outside the metadata/navigation recipe: $(Get-RelativeArtifactPath $IndexPath):$($i + 1)"
            }
            $currentSection = $null
            continue
        }
        if ($line -match '^##\s+(?<section>[^#].*?)\s*$') {
            if ($headingOneCount -ne 1) {
                Fail-Layout "split index H1 title must be the first non-empty line: $(Get-RelativeArtifactPath $IndexPath):$($i + 1)"
            }
            $section = ($Matches.section -replace '\s+', ' ').Trim().ToLowerInvariant()
            if (-not $allowedSections.ContainsKey($section)) {
                Fail-Layout "split index contains detailed body content outside the metadata/navigation recipe: $(Get-RelativeArtifactPath $IndexPath):$($i + 1)"
            }
            $currentSection = $section
            continue
        }
        if ($currentSection -and $line -match '^\s*-\s+(?:\[[^\]]+\]\([^)]+\)|(?:[^:]+:\s*)?`[^`]+`)\s*$') {
            continue
        }
        Fail-Layout "split index contains detailed body content outside the metadata/navigation recipe: $(Get-RelativeArtifactPath $IndexPath):$($i + 1)"
    }
    if ($headingOneCount -ne 1) {
        Fail-Layout "split index metadata/navigation recipe requires exactly one H1 title: $(Get-RelativeArtifactPath $IndexPath)"
    }
}

function Read-FragmentManifest([string]$IndexPath) {
    $lines = [IO.File]::ReadAllLines($IndexPath)
    $manifestHeadingIndexes = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '## Fragment Manifest') { $manifestHeadingIndexes += $i }
    }
    if ($manifestHeadingIndexes.Count -ne 1) {
        Fail-Layout "split index requires exactly one ## Fragment Manifest heading: $(Get-RelativeArtifactPath $IndexPath)"
    }
    $manifestHeadingIndex = $manifestHeadingIndexes[0]
    $headerIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '| Order | File | Kind | Owns |') {
            $headerIndex = $i
            break
        }
    }
    if ($headerIndex -lt 0) {
        Fail-Layout "fragment index must contain the exact '| Order | File | Kind | Owns |' table: $(Get-RelativeArtifactPath $IndexPath)"
    }
    if ($headerIndex -le $manifestHeadingIndex) {
        Fail-Layout "fragment manifest table must follow ## Fragment Manifest: $(Get-RelativeArtifactPath $IndexPath)"
    }
    for ($i = $manifestHeadingIndex + 1; $i -lt $headerIndex; $i++) {
        if (-not [string]::IsNullOrWhiteSpace($lines[$i])) {
            Fail-Layout "fragment manifest table must directly follow ## Fragment Manifest: $(Get-RelativeArtifactPath $IndexPath):$($i + 1)"
        }
    }
    if ($headerIndex + 1 -ge $lines.Count -or $lines[$headerIndex + 1].Trim() -notmatch '^\|\s*:?-{3,}:?\s*\|\s*:?-{3,}:?\s*\|\s*:?-{3,}:?\s*\|\s*:?-{3,}:?\s*\|$') {
        Fail-Layout "fragment index has an invalid manifest separator: $(Get-RelativeArtifactPath $IndexPath)"
    }

    $rows = [Collections.Generic.List[object]]::new()
    $manifestEndIndex = $headerIndex + 1
    for ($i = $headerIndex + 2; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].Trim()
        if (-not $line.StartsWith('|')) { break }
        $columns = $line.Trim('|').Split('|')
        if ($columns.Count -ne 4) {
            Fail-Layout "fragment manifest row must have four columns: $(Get-RelativeArtifactPath $IndexPath):$($i + 1)"
        }
        $order = 0
        if (-not [int]::TryParse($columns[0].Trim(), [ref]$order)) {
            Fail-Layout "fragment manifest order must be an integer: $(Get-RelativeArtifactPath $IndexPath):$($i + 1)"
        }
        $file = $columns[1].Trim().Trim('`').Trim()
        $kind = $columns[2].Trim().Trim('`').Trim()
        $owns = $columns[3].Trim().Trim('`').Trim()
        if ([string]::IsNullOrWhiteSpace($file) -or [string]::IsNullOrWhiteSpace($kind) -or [string]::IsNullOrWhiteSpace($owns)) {
            Fail-Layout "fragment manifest fields may not be empty: $(Get-RelativeArtifactPath $IndexPath):$($i + 1)"
        }
        $rows.Add([pscustomobject]@{
            Order = $order
            File = $file
            Kind = $kind
            Owns = $owns
            Path = $null
        })
        $manifestEndIndex = $i
    }
    if ($rows.Count -eq 0) {
        Fail-Layout "fragment manifest has no fragments: $(Get-RelativeArtifactPath $IndexPath)"
    }
    Test-IndexMetadataOnly $lines $headerIndex $manifestEndIndex $IndexPath

    $directory = Get-NormalizedPath (Split-Path -Parent $IndexPath)
    $seenFiles = @{}
    $seenOwnership = @{}
    for ($i = 0; $i -lt $rows.Count; $i++) {
        $row = $rows[$i]
        if ($row.Order -ne ($i + 1)) {
            Fail-Layout "fragment manifest order must be consecutive from 1: $(Get-RelativeArtifactPath $IndexPath)"
        }
        $resolvedFragment = Get-NormalizedPath (Join-Path $directory $row.File)
        if (-not ((Split-Path -Parent $resolvedFragment) -eq $directory)) {
            Fail-Layout "fragment path escapes split directory: $($row.File)"
        }
        if ([IO.Path]::GetExtension($resolvedFragment) -ine '.md' -or (Split-Path -Leaf $resolvedFragment) -ieq '00-index.md') {
            Fail-Layout "fragment must be a direct Markdown sibling other than 00-index.md: $($row.File)"
        }
        $fileKey = (Split-Path -Leaf $resolvedFragment).ToLowerInvariant()
        if ($seenFiles.ContainsKey($fileKey)) {
            Fail-Layout "fragment is listed more than once: $($row.File)"
        }
        $seenFiles[$fileKey] = $true
        $ownerKey = ($row.Owns -replace '\s+', ' ').Trim().ToLowerInvariant()
        if ($seenOwnership.ContainsKey($ownerKey)) {
            Fail-Layout "duplicate ownership '$($row.Owns)' in $(Get-RelativeArtifactPath $IndexPath)"
        }
        $seenOwnership[$ownerKey] = $true
        if (-not (Test-Path -LiteralPath $resolvedFragment -PathType Leaf)) {
            Fail-Layout "missing fragment '$($row.File)' listed by $(Get-RelativeArtifactPath $IndexPath)"
        }
        $row.Path = $resolvedFragment
    }

    $siblingFiles = @(Get-ChildItem -LiteralPath $directory -File -Filter '*.md' | Where-Object { $_.Name -ine '00-index.md' })
    foreach ($sibling in $siblingFiles) {
        if (-not $seenFiles.ContainsKey($sibling.Name.ToLowerInvariant())) {
            Fail-Layout "unindexed fragment '$($sibling.Name)' beside $(Get-RelativeArtifactPath $IndexPath)"
        }
    }
    if ($siblingFiles.Count -ne $rows.Count) {
        Fail-Layout "fragment manifest does not match direct Markdown siblings: $(Get-RelativeArtifactPath $IndexPath)"
    }
    return @($rows)
}

function Test-ExclusiveRepresentation([string]$FilePath, [string]$IndexPath, [string]$Label) {
    $directory = Split-Path -Parent $IndexPath
    $hasFile = Test-Path -LiteralPath $FilePath -PathType Leaf
    $hasDirectory = Test-Path -LiteralPath $directory -PathType Container
    if ($hasFile -and $hasDirectory) {
        Fail-Layout "$Label file and directory forms are mutually exclusive"
    }
    return [pscustomobject]@{
        HasFile = $hasFile
        HasDirectory = $hasDirectory
    }
}

function Test-StructuralConflicts([string]$ResolvedChangePath) {
    $conflicts = [Collections.Generic.List[string]]::new()
    foreach ($end in @('backend', 'frontend')) {
        $historical = "design-$end.md"
        if (Test-Path -LiteralPath (Join-Path $ResolvedChangePath $historical) -PathType Leaf) {
            $conflicts.Add("$historical is not a supported artifact layout")
        }
    }

    $pairs = @(
        [pscustomobject]@{ File = 'prd.md'; Directory = 'prd/' },
        [pscustomobject]@{ File = 'proposal.md'; Directory = 'proposal/' },
        [pscustomobject]@{ File = 'design/backend.md'; Directory = 'design/backend/' },
        [pscustomobject]@{ File = 'design/frontend.md'; Directory = 'design/frontend/' },
        [pscustomobject]@{ File = 'tasks/plan-backend.md'; Directory = 'tasks/backend/' },
        [pscustomobject]@{ File = 'tasks/plan-frontend.md'; Directory = 'tasks/frontend/' }
    )
    foreach ($pair in $pairs) {
        $filePath = Join-Path $ResolvedChangePath $pair.File
        $directoryPath = Join-Path $ResolvedChangePath $pair.Directory.TrimEnd('/')
        if ((Test-Path -LiteralPath $filePath -PathType Leaf) -and (Test-Path -LiteralPath $directoryPath -PathType Container)) {
            $conflicts.Add("$($pair.File) plus $($pair.Directory) are mutually exclusive forms")
        }
    }
    if ($conflicts.Count -gt 0) {
        Fail-Layout "structural conflicts: $($conflicts -join '; ')"
    }
}

function Test-SplitDirectory([string]$Directory, [string]$Label) {
    if (-not (Test-Path -LiteralPath $Directory -PathType Container)) {
        return @()
    }
    $indexPath = Join-Path $Directory '00-index.md'
    if (-not (Test-Path -LiteralPath $indexPath -PathType Leaf)) {
        Fail-Layout "$Label split directory is missing 00-index.md"
    }
    $rows = @(Read-FragmentManifest $indexPath)
    Add-SizeCandidate $indexPath
    foreach ($row in $rows) { Add-SizeCandidate $row.Path }
    return $rows
}

function Get-LogicalArtifactText([string]$FilePath, [object[]]$Rows) {
    if (Test-Path -LiteralPath $FilePath -PathType Leaf) {
        return [IO.File]::ReadAllText($FilePath)
    }
    return (@($Rows | Sort-Object Order | ForEach-Object { [IO.File]::ReadAllText($_.Path) }) -join "`n")
}

function Test-OrderedUniqueHeadings([string]$Text, [string[]]$Headings, [string]$FailureMessage) {
    $lastIndex = -1
    foreach ($heading in $Headings) {
        $needle = "`n$heading`n"
        $normalized = "`n" + $Text.Replace("`r`n", "`n").TrimEnd("`n") + "`n"
        $first = $normalized.IndexOf($needle, [StringComparison]::Ordinal)
        $last = $normalized.LastIndexOf($needle, [StringComparison]::Ordinal)
        if ($first -lt 0 -or $first -ne $last -or $first -le $lastIndex) { Fail-Layout "${FailureMessage}: $heading" }
        $lastIndex = $first
    }
}

function Test-PrdLogicalTemplate([string]$Text) {
    function U([string]$Escaped) { return ConvertFrom-Json ('"' + $Escaped + '"') }
    $headings = @(
        ('## ' + (U '\u4e00\u3001\u7528\u6237\u6545\u4e8b'))
        ('### 1.1 ' + (U '\u7528\u6237\u6545\u4e8b'))
        ('### 1.2 ' + (U '\u4e1a\u52a1\u95ee\u9898\u4e0e\u9884\u671f\u76ee\u6807'))
        ('## ' + (U '\u4e8c\u3001\u6838\u5fc3\u4e1a\u52a1\u6d41\u7a0b'))
        ('## ' + (U '\u4e09\u3001\u529f\u80fd\u9700\u6c42'))
        ('## ' + (U '\u56db\u3001\u975e\u529f\u80fd\u9700\u6c42'))
        ('### 4.1 ' + (U '\u6027\u80fd\u9700\u6c42'))
        ('### 4.2 ' + (U '\u5b89\u5168\u9700\u6c42'))
        ('### 4.3 ' + (U '\u64cd\u4f5c\u65e5\u5fd7\u8bb0\u5f55'))
        ('## ' + (U '\u4e94\u3001\u6d4b\u8bd5\u5efa\u8bae'))
        ('## ' + (U '\u516d\u3001\u5f85\u786e\u8ba4\u95ee\u9898'))
    )
    Test-OrderedUniqueHeadings $Text $headings 'PRD logical template is missing required headings or canonical order'
    $normalizedText = $Text.Replace("`r`n", "`n")
    $sectionThreeHeading = '## ' + (U '\u4e09\u3001\u529f\u80fd\u9700\u6c42')
    $sectionFourHeading = '## ' + (U '\u56db\u3001\u975e\u529f\u80fd\u9700\u6c42')
    $sectionThreeStart = $normalizedText.IndexOf($sectionThreeHeading, [StringComparison]::Ordinal)
    $sectionFourStart = $normalizedText.IndexOf($sectionFourHeading, [StringComparison]::Ordinal)
    $features = [regex]::Matches($normalizedText, '(?m)^### 3\.(?<number>\d+)\s+\S.*$')
    if ($features.Count -lt 1) { Fail-Layout 'PRD logical template is missing a functional feature section' }
    for ($featureIndex = 0; $featureIndex -lt $features.Count; $featureIndex++) {
        $feature = $features[$featureIndex]
        if ($feature.Index -le $sectionThreeStart -or $feature.Index -ge $sectionFourStart) {
            Fail-Layout 'PRD functional feature headings must stay between section three and section four'
        }
        $number = $feature.Groups['number'].Value
        $labels = @(
            (U '\u529f\u80fd\u8bf4\u660e')
            (U '\u4ea4\u4e92\u903b\u8f91')
            (U '\u5f02\u5e38\u5904\u7406')
            (U '\u9875\u9762\u5143\u7d20')
            (U '\u539f\u578b')
        )
        $required = for ($i = 1; $i -le 5; $i++) { "#### 3.$number.$i $($labels[$i - 1])" }
        $featureEnd = $sectionFourStart
        if ($featureIndex + 1 -lt $features.Count -and $features[$featureIndex + 1].Index -lt $sectionFourStart) {
            $featureEnd = $features[$featureIndex + 1].Index
        }
        $featureBlock = $normalizedText.Substring($feature.Index, $featureEnd - $feature.Index)
        Test-OrderedUniqueHeadings $featureBlock $required "PRD logical template is missing required feature fields for 3.$number"
    }
    $requiredTables = @(
        [pscustomobject]@{ Labels = @((U '\u5f02\u5e38\u573a\u666f'), (U '\u89e6\u53d1\u6761\u4ef6'), (U '\u7cfb\u7edf\u5904\u7406\u65b9\u5f0f'), (U '\u7528\u6237\u63d0\u793a')) }
        [pscustomobject]@{ Labels = @((U '\u5143\u7d20\u540d'), (U '\u7c7b\u578b'), (U '\u8bf4\u660e'), (U '\u6821\u9a8c\u89c4\u5219')) }
        [pscustomobject]@{ Labels = @((U '\u64cd\u4f5c'), (U '\u662f\u5426\u8bb0\u5f55\u65e5\u5fd7'), (U '\u8bb0\u5f55\u4fe1\u606f')) }
        [pscustomobject]@{ Labels = @((U '\u573a\u666f'), (U '\u524d\u7f6e\u6761\u4ef6'), (U '\u64cd\u4f5c'), (U '\u9884\u671f\u7ed3\u679c')) }
    )
    foreach ($table in $requiredTables) {
        $columns = @($table.Labels | ForEach-Object { [regex]::Escape($_) }) -join '\s*\|\s*'
        if ($Text -notmatch "(?m)^\|\s*$columns\s*\|\s*$") { Fail-Layout 'PRD logical template is missing a required table' }
    }
}

function Test-ProposalLogicalTemplate([string]$Text) {
    Test-OrderedUniqueHeadings $Text @(
        '## Why', '## What Changes', '## Capabilities', '### New Capabilities',
        '### Modified Capabilities', '## Out of Scope', '## Impact'
    ) 'proposal logical headings must appear exactly once in canonical order'
    $normalizedText = $Text.Replace("`r`n", "`n")
    $whatChangesStart = $normalizedText.IndexOf('## What Changes', [StringComparison]::Ordinal)
    $capabilitiesStart = $normalizedText.IndexOf('## Capabilities', [StringComparison]::Ordinal)
    $changes = [regex]::Matches($normalizedText, '(?m)^### (?<number>\d+)\.\s+\S.*$')
    if ($changes.Count -lt 1) { Fail-Layout 'proposal logical template requires at least one numbered change' }
    foreach ($change in $changes) {
        if ($change.Index -le $whatChangesStart -or $change.Index -ge $capabilitiesStart) {
            Fail-Layout 'proposal numbered changes must stay between What Changes and Capabilities'
        }
    }
}

function Test-PlanManifestKinds([object[]]$Rows, [string]$End) {
    $counts = @{}
    foreach ($row in $Rows) {
        $kind = $row.Kind.ToLowerInvariant()
        if ($kind -notin @('context', 'interface', 'tasks', 'coverage')) { Fail-Layout "$End plan contains unsupported fragment kind '$kind'" }
        if (-not $counts.ContainsKey($kind)) { $counts[$kind] = 0 }
        $counts[$kind]++
    }
    foreach ($kind in @('context', 'interface', 'coverage')) {
        $count = if ($counts.ContainsKey($kind)) { $counts[$kind] } else { 0 }
        if ($count -ne 1) { Fail-Layout "$End plan requires exactly one $kind fragment" }
    }
    $taskCount = if ($counts.ContainsKey('tasks')) { $counts['tasks'] } else { 0 }
    if ($taskCount -lt 1) { Fail-Layout "$End plan requires one or more tasks fragments" }
}

function Test-DesignIndex([string]$IndexPath, [hashtable]$Representations) {
    $actualEnds = @($Representations.Keys)
    $hasIndex = Test-Path -LiteralPath $IndexPath -PathType Leaf
    if ($actualEnds.Count -gt 0 -and -not $hasIndex) { Fail-Layout 'design artifacts require design/00-index.md' }
    if (-not $hasIndex) { return }
    if ($actualEnds.Count -eq 0) { Fail-Layout 'design/00-index.md exists without design artifacts' }
    Add-SizeCandidate $IndexPath
    $lines = [IO.File]::ReadAllLines($IndexPath)
    $nonEmpty = @($lines | ForEach-Object -Begin { $lineNumber = 0 } -Process { $lineNumber++; if (-not [string]::IsNullOrWhiteSpace($_)) { [pscustomobject]@{ Text = $_.Trim(); Line = $lineNumber } } })
    if ($nonEmpty.Count -eq 0 -or $nonEmpty[0].Text -notmatch '^#\s+\S') {
        Fail-Layout 'design index contains detailed content outside its metadata-only recipe: H1 title must be first'
    }
    $h1Rows = @($nonEmpty | Where-Object { $_.Text -match '^#\s+\S' })
    $endMapHeadings = @($nonEmpty | Where-Object { $_.Text -eq '## Canonical End Entrypoints' })
    if ($h1Rows.Count -ne 1 -or $endMapHeadings.Count -ne 1) {
        Fail-Layout 'design index contains detailed content outside its metadata-only recipe: exact H1 and end-map section required'
    }
    $header = [Array]::IndexOf($lines, '| End | Canonical entrypoint | Mode |')
    if ($header -lt 0 -or $header + 1 -ge $lines.Count -or $lines[$header + 1].Trim() -notmatch '^\|\s*:?-{3,}:?\s*\|\s*:?-{3,}:?\s*\|\s*:?-{3,}:?\s*\|$') {
        Fail-Layout 'design index requires the exact End, Canonical entrypoint, Mode table'
    }
    if (($header + 1) -le $endMapHeadings[0].Line) {
        Fail-Layout 'design index contains detailed content outside its metadata-only recipe: end-map table must follow its section'
    }
    $seen = @{}
    $tableEnd = $header + 1
    for ($i = $header + 2; $i -lt $lines.Count -and $lines[$i].Trim().StartsWith('|'); $i++) {
        $cells = @($lines[$i].Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
        if ($cells.Count -ne 3) { Fail-Layout 'design index row must have three columns' }
        $end = $cells[0]
        if ($end -notin @('Backend', 'Frontend')) { Fail-Layout "design index contains extra end $end" }
        if ($seen.ContainsKey($end)) { Fail-Layout "design index duplicates end $end" }
        $seen[$end] = $true
        $key = $end.ToLowerInvariant()
        if (-not $Representations.ContainsKey($key)) { Fail-Layout "design index contains extra end $end" }
        $entry = $cells[1].Trim('`')
        $expected = $Representations[$key]
        if ($entry -ne $expected.Entry -or $cells[2] -ne $expected.Mode) {
            Fail-Layout "design index entry for $end is '$entry' ($($cells[2])), expected $($expected.Entry) ($($expected.Mode))"
        }
        $tableEnd = $i
    }
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].Trim()
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($i -eq ($h1Rows[0].Line - 1) -or $i -eq ($endMapHeadings[0].Line - 1) -or ($i -ge $header -and $i -le $tableEnd)) { continue }
        if ($i -lt ($endMapHeadings[0].Line - 1) -and $line -match '^\s*-\s+(?:\[[^\]]+\]\([^)]+\)|[^`]*`design/[^`]+`[^`]*)\s*$') { continue }
        Fail-Layout "design index contains detailed content outside its metadata-only recipe: $(Get-RelativeArtifactPath $IndexPath):$($i + 1)"
    }
    foreach ($end in $actualEnds) {
        $display = (Get-Culture).TextInfo.ToTitleCase($end)
        if (-not $seen.ContainsKey($display)) { Fail-Layout "design index is missing end $display" }
    }
}

function ConvertTo-TaskDependencyIds([string]$Value, [string]$TaskId) {
    $trimmed = $Value.Trim()
    if ($trimmed -ieq 'None') { return @() }
    if ($trimmed -notmatch '^`?(?:backend|frontend)-\d{3}`?(?:\s*,\s*`?(?:backend|frontend)-\d{3}`?)*$') {
        Fail-Layout "task $TaskId has invalid Depends on syntax: '$Value'"
    }
    $ids = @([regex]::Matches($trimmed, '(?i)(?:backend|frontend)-\d{3}') | ForEach-Object { $_.Value.ToLowerInvariant() })
    if (@($ids | Select-Object -Unique).Count -ne $ids.Count) {
        Fail-Layout "task $TaskId declares a duplicate dependency"
    }
    return $ids
}

function Get-TaskGraph([string[]]$Files) {
    $ownership = @{}
    $declarations = @{}
    $checkboxCounts = @{}
    $dependencies = @{}
    $states = @{}
    foreach ($file in $Files | Select-Object -Unique) {
        $text = [IO.File]::ReadAllText($file)
        $kind = $script:TaskFileKinds[(Get-NormalizedPath $file)]
        $checkboxMatches = [regex]::Matches($text, '(?im)^\s*-\s*\[(?<state> |x|X)\]\s+\*\*Task\s+(?<id>(?:backend|frontend)-\d{3})\b')
        if ($checkboxMatches.Count -gt 0 -and $kind -ne 'tasks') {
            Fail-Layout "task checkbox in non-task file: $(Get-RelativeArtifactPath $file)"
        }
        for ($matchIndex = 0; $matchIndex -lt $checkboxMatches.Count; $matchIndex++) {
            $match = $checkboxMatches[$matchIndex]
            $id = $match.Groups['id'].Value.ToLowerInvariant()
            if (-not $checkboxCounts.ContainsKey($id)) { $checkboxCounts[$id] = 0 }
            $checkboxCounts[$id]++
            if ($checkboxCounts[$id] -gt 1) {
                Fail-Layout "duplicate task checkbox for $id"
            }
            $ownership[$id] = Get-NormalizedPath $file
            $states[$id] = $match.Groups['state'].Value -match '^(?:x|X)$'
            $blockStart = $match.Index
            $blockEnd = if ($matchIndex + 1 -lt $checkboxMatches.Count) { $checkboxMatches[$matchIndex + 1].Index } else { $text.Length }
            $block = $text.Substring($blockStart, $blockEnd - $blockStart)
            $dependencyMatches = [regex]::Matches($block, '(?im)^\s*(?:\*\*Depends on:\*\*|Depends on:)\s*(?<value>[^\r\n]+)\s*$')
            if ($dependencyMatches.Count -ne 1) {
                Fail-Layout "task $id must declare exactly one Depends on field"
            }
            $dependencies[$id] = @(ConvertTo-TaskDependencyIds $dependencyMatches[0].Groups['value'].Value $id)
        }

        $declarationMatches = [regex]::Matches($text, '(?im)^\s*(?:#{1,6}\s+|-\s*\[(?: |x|X)\]\s+\*\*)Task\s+(?<id>(?:backend|frontend)-\d{3})\b')
        foreach ($match in $declarationMatches) {
            $id = $match.Groups['id'].Value.ToLowerInvariant()
            if (-not $declarations.ContainsKey($id)) { $declarations[$id] = 0 }
            $declarations[$id]++
            if ($declarations[$id] -gt 1) {
                Fail-Layout "duplicate task ID $id"
            }
        }
    }

    foreach ($id in $declarations.Keys) {
        if (-not $checkboxCounts.ContainsKey($id)) {
            Fail-Layout "task ID $id has no owner checkbox"
        }
    }
    foreach ($id in $ownership.Keys) {
        $relative = (Get-RelativeArtifactPath $ownership[$id]).ToLowerInvariant()
        if ($relative -match '^tasks/(?:plan-)?backend(?:\.md|/)' -and -not $id.StartsWith('backend-')) {
            Fail-Layout "task ID $id is owned by a backend plan file"
        }
        if ($relative -match '^tasks/(?:plan-)?frontend(?:\.md|/)' -and -not $id.StartsWith('frontend-')) {
            Fail-Layout "task ID $id is owned by a frontend plan file"
        }
    }
    return [pscustomobject]@{
        Ownership = $ownership
        Dependencies = $dependencies
        States = $states
    }
}

function Test-TaskDependencyGraph([object]$Graph) {
    foreach ($id in $Graph.Dependencies.Keys) {
        foreach ($dependency in $Graph.Dependencies[$id]) {
            if (-not $Graph.Ownership.ContainsKey($dependency)) {
                Fail-Layout "task $id references unknown dependency $dependency"
            }
        }
    }
    $remaining = @{}
    foreach ($id in $Graph.Ownership.Keys) { $remaining[$id] = @($Graph.Dependencies[$id]) }
    while ($remaining.Count -gt 0) {
        $ready = @($remaining.Keys | Where-Object { $remaining[$_].Count -eq 0 })
        if ($ready.Count -eq 0) { Fail-Layout 'task dependency cycle detected' }
        foreach ($id in $ready) {
            $remaining.Remove($id)
            foreach ($other in @($remaining.Keys)) {
                $remaining[$other] = @($remaining[$other] | Where-Object { $_ -ne $id })
            }
        }
    }
}

function Expand-TaskReference([string]$Reference) {
    $value = $Reference.Trim().Trim('`').Trim()
    $value = $value.Replace(([string][char]0x2013), '-').Replace(([string][char]0x2014), '-')
    if ($value -match '^(?<end>backend|frontend)-(?<number>\d{3})$') {
        return @($value.ToLowerInvariant())
    }
    if ($value -match '^(?<end>backend|frontend)-(?<start>\d{3})\s*-\s*(?:(?<end2>backend|frontend)-)?(?<finish>\d{3})$') {
        if ($Matches.end2 -and $Matches.end2 -ne $Matches.end) {
            Fail-Layout "cross-end task range is invalid: $Reference"
        }
        $start = [int]$Matches.start
        $finish = [int]$Matches.finish
        if ($finish -lt $start) { Fail-Layout "descending task range is invalid: $Reference" }
        $ids = [Collections.Generic.List[string]]::new()
        for ($number = $start; $number -le $finish; $number++) {
            $ids.Add(('{0}-{1:D3}' -f $Matches.end, $number))
        }
        return @($ids)
    }
    Fail-Layout "invalid task ID or range in overview: $Reference"
}

function Fail-OverviewRecipe([string]$OverviewPath, [int]$LineNumber, [string]$Reason) {
    Fail-Layout "overview contains same-end implementation details or prose outside the cross-end metadata/navigation/table recipe: $(Get-RelativeArtifactPath $OverviewPath):$LineNumber ($Reason)"
}

function Read-OverviewTables([string[]]$Lines, [string]$OverviewPath) {
    $allowedHeaders = @{
        'canonical end entrypoints' = 'End|Canonical entrypoint|Mode'
        'cross-end dependency edges' = 'From task|To task|Shared contract / gate'
        'cross-end execution stages' = 'Stage|Ends / cross-end gate|Exit condition'
        'progress totals' = 'End|Total|Complete|Remaining'
    }
    $legacy = '(?i)^(?:Plan Entrypoints|Cross-end Execution Order|Progress Summary)$'
    $seenSections = @{}
    $tables = @{}
    $headingOneSeen = $false
    $firstNonEmptySeen = $false
    $currentSection = $null
    $currentSectionHasTable = $false

    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i].Trim()
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if (-not $firstNonEmptySeen) {
            $firstNonEmptySeen = $true
            if ($line -notmatch '^#\s+\S.*$') { Fail-OverviewRecipe $OverviewPath ($i + 1) 'H1 title must be first' }
        }
        if ($line -match '^#\s+\S.*$') {
            if ($headingOneSeen) { Fail-OverviewRecipe $OverviewPath ($i + 1) 'multiple H1 titles' }
            $headingOneSeen = $true
            continue
        }
        if ($line -match '^##\s+(?<section>[^#].*?)\s*$') {
            if ($currentSection -and -not $currentSectionHasTable) { Fail-OverviewRecipe $OverviewPath ($i + 1) "section '$currentSection' has no table" }
            $section = ($Matches.section -replace '\s+', ' ').Trim().ToLowerInvariant()
            if ($Matches.section.Trim() -match $legacy) { Fail-Layout 'old all-task overview schema is not supported' }
            if (-not $allowedHeaders.ContainsKey($section)) { Fail-OverviewRecipe $OverviewPath ($i + 1) "section '$section' is not cross-end metadata" }
            if ($seenSections.ContainsKey($section)) { Fail-OverviewRecipe $OverviewPath ($i + 1) "duplicate section '$section'" }
            $seenSections[$section] = $true
            $currentSection = $section
            $currentSectionHasTable = $false
            continue
        }
        if ($line.StartsWith('|')) {
            if (-not $currentSection -or $currentSectionHasTable) { Fail-OverviewRecipe $OverviewPath ($i + 1) 'table is outside its permitted section' }
            $headerCells = @($line.Trim('|').Split('|') | ForEach-Object { $_.Trim() })
            $normalizedHeader = $headerCells -join '|'
            if ($normalizedHeader -ne $allowedHeaders[$currentSection]) { Fail-OverviewRecipe $OverviewPath ($i + 1) "table header is invalid for '$currentSection'" }
            if ($i + 1 -ge $Lines.Count) { Fail-OverviewRecipe $OverviewPath ($i + 1) 'table separator is missing' }
            $separatorCells = @($Lines[$i + 1].Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
            if ($separatorCells.Count -ne $headerCells.Count -or @($separatorCells | Where-Object { $_ -notmatch '^:?-{3,}:?$' }).Count -gt 0) {
                Fail-OverviewRecipe $OverviewPath ($i + 2) 'table separator is invalid'
            }
            $i += 2
            $rowCount = 0
            [object[]]$rows = @()
            while ($i -lt $Lines.Count -and $Lines[$i].Trim().StartsWith('|')) {
                $cells = @($Lines[$i].Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
                if ($cells.Count -ne $headerCells.Count -or @($cells | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -gt 0) {
                    Fail-OverviewRecipe $OverviewPath ($i + 1) 'table row shape is invalid'
                }
                $rows += [pscustomobject]@{ Cells = [string[]]$cells; Line = $i + 1 }
                $rowCount++
                $i++
            }
            if ($rowCount -eq 0) { Fail-OverviewRecipe $OverviewPath ($i + 1) 'table has no rows' }
            $tables[$currentSection] = [object[]]$rows
            $currentSectionHasTable = $true
            $i--
            continue
        }
        Fail-OverviewRecipe $OverviewPath ($i + 1) 'free-form content is not permitted'
    }
    if (-not $headingOneSeen) { Fail-OverviewRecipe $OverviewPath 1 'H1 title is missing' }
    if ($currentSection -and -not $currentSectionHasTable) { Fail-OverviewRecipe $OverviewPath $Lines.Count "section '$currentSection' has no table" }
    foreach ($required in @('canonical end entrypoints', 'progress totals')) {
        if (-not $tables.ContainsKey($required)) { Fail-Layout "tasks/00-overview.md is missing required section '$required'" }
    }
    return $tables
}

function Test-TaskOverview([string]$TasksDirectory, [object]$Graph, [hashtable]$Representations) {
    $overviewPath = Join-Path $TasksDirectory '00-overview.md'
    $hasOverview = Test-Path -LiteralPath $overviewPath -PathType Leaf
    if ($script:TaskEnds.Count -eq 2 -and -not $hasOverview) {
        Fail-Layout 'two-end plan requires tasks/00-overview.md'
    }
    if ($script:TaskEnds.Count -ne 2 -and $hasOverview) {
        Fail-Layout 'tasks/00-overview.md is invalid for a single-end plan or a change without task plans'
    }
    if (-not $hasOverview) { return }

    Add-SizeCandidate $overviewPath
    $text = [IO.File]::ReadAllText($overviewPath)
    if ($text -match '(?im)^\s*-\s*\[(?: |x|X)\]') {
        Fail-Layout 'tasks/00-overview.md contains a task checkbox'
    }
    $lines = [IO.File]::ReadAllLines($overviewPath)
    $tables = Read-OverviewTables $lines $overviewPath

    $seenEnds = @{}
    foreach ($row in $tables['canonical end entrypoints']) {
        $cells = $row.Cells
        if ($cells[0] -notin @('Backend', 'Frontend')) { Fail-OverviewRecipe $overviewPath $row.Line 'invalid end entrypoint row' }
        $end = $cells[0].ToLowerInvariant()
        if ($seenEnds.ContainsKey($end)) { Fail-Layout "overview duplicates end $($cells[0])" }
        $seenEnds[$end] = $true
        if (-not $Representations.ContainsKey($end)) { Fail-Layout "overview contains extra end $($cells[0])" }
        $entry = $cells[1].Trim('`')
        $expected = $Representations[$end]
        if ($entry -ne $expected.Entry -or $cells[2] -ne $expected.Mode) {
            Fail-Layout "overview entry for $($cells[0]) is '$entry' ($($cells[2])), expected $($expected.Entry) ($($expected.Mode))"
        }
    }
    foreach ($end in $Representations.Keys) {
        if (-not $seenEnds.ContainsKey($end)) { Fail-Layout "overview is missing end $end" }
    }

    $progressSeen = @{}
    foreach ($row in $tables['progress totals']) {
        $cells = $row.Cells
        if ($cells[0] -notin @('Backend', 'Frontend') -or @($cells[1..3] | Where-Object { $_ -notmatch '^\d+$' }).Count -gt 0) {
            Fail-OverviewRecipe $overviewPath $row.Line 'invalid progress row'
        }
        $end = $cells[0].ToLowerInvariant()
        if ($progressSeen.ContainsKey($end)) { Fail-Layout "overview duplicates progress for $($cells[0])" }
        $progressSeen[$end] = $true
        $ids = @($Graph.Ownership.Keys | Where-Object { $_.StartsWith("$end-") })
        $complete = @($ids | Where-Object { $Graph.States[$_] }).Count
        if ([int]$cells[1] -ne $ids.Count -or [int]$cells[2] -ne $complete -or [int]$cells[3] -ne ($ids.Count - $complete)) {
            Fail-Layout "progress totals for $($cells[0]) do not match owner checkboxes"
        }
    }
    foreach ($end in $Representations.Keys) {
        if (-not $progressSeen.ContainsKey($end)) { Fail-Layout "overview is missing progress totals for $end" }
    }

    $derivedEdges = @{}
    foreach ($to in $Graph.Dependencies.Keys) {
        foreach ($from in $Graph.Dependencies[$to]) {
            if ($from.Split('-')[0] -ne $to.Split('-')[0]) { $derivedEdges["$from->$to"] = $true }
        }
    }
    $hasEdgeSection = $tables.ContainsKey('cross-end dependency edges')
    $hasStageSection = $tables.ContainsKey('cross-end execution stages')
    [object[]]$edgeRows = if ($hasEdgeSection) { @($tables['cross-end dependency edges']) } else { @() }
    [object[]]$stageRows = if ($hasStageSection) { @($tables['cross-end execution stages']) } else { @() }
    $declared = @{}
    foreach ($row in $edgeRows) {
        $from = $row.Cells[0].Trim('`').ToLowerInvariant()
        $to = $row.Cells[1].Trim('`').ToLowerInvariant()
        if ($from -notmatch '^(backend|frontend)-\d{3}$' -or $to -notmatch '^(backend|frontend)-\d{3}$') { Fail-OverviewRecipe $overviewPath $row.Line 'invalid dependency edge task ID' }
        foreach ($id in @($from, $to)) {
            if (-not $Graph.Ownership.ContainsKey($id)) { Fail-Layout "overview edge references unknown task ID $id" }
        }
        if ($from -eq $to -or $from.Split('-')[0] -eq $to.Split('-')[0]) {
            Fail-Layout 'overview dependency edge must connect different tasks from different ends'
        }
        $key = "$from->$to"
        if ($declared.ContainsKey($key)) { Fail-Layout "overview duplicates cross-end dependency edge $key" }
        $declared[$key] = $true
    }
    foreach ($key in $derivedEdges.Keys) { if (-not $declared.ContainsKey($key)) { Fail-Layout "overview is missing cross-end dependency edge $key" } }
    foreach ($key in $declared.Keys) { if (-not $derivedEdges.ContainsKey($key)) { Fail-Layout "overview declares invalid cross-end dependency edge $key" } }
    if ($derivedEdges.Count -eq 0 -and $hasStageSection) {
        Fail-Layout 'overview declares cross-end execution stages without an owner-file cross-end dependency'
    }
    if ($hasStageSection) {
        $taskStage = @{}
        foreach ($row in $stageRows) {
            if ($row.Cells[0] -notmatch '^\d+$') { Fail-OverviewRecipe $overviewPath $row.Line 'stage must be numeric' }
            $stage = [int]$row.Cells[0]
            $stageEvidence = "$($row.Cells[1]) $($row.Cells[2])"
            $ids = @([regex]::Matches($stageEvidence, '(?i)(?:backend|frontend)-\d{3}') | ForEach-Object { $_.Value.ToLowerInvariant() })
            if ($ids.Count -eq 0) { Fail-OverviewRecipe $overviewPath $row.Line 'stage must name task IDs for a cross-end gate' }
            foreach ($id in $ids) {
                if (-not $Graph.Ownership.ContainsKey($id)) { Fail-Layout "overview stage references unknown task ID $id" }
                if ($taskStage.ContainsKey($id)) { Fail-Layout "overview stage repeats task ID $id" }
                $taskStage[$id] = $stage
            }
        }
        foreach ($key in $derivedEdges.Keys) {
            $parts = $key.Split(@('->'), [StringSplitOptions]::None)
            if (-not $taskStage.ContainsKey($parts[0]) -or -not $taskStage.ContainsKey($parts[1]) -or $taskStage[$parts[0]] -ge $taskStage[$parts[1]]) {
                Fail-Layout "overview stages do not order cross-end dependency $key"
            }
        }
    }
}

function Test-ChangeArtifacts([string]$ResolvedChangePath, [string]$ValidationMode) {
    $script:ResolvedChangePath = $ResolvedChangePath
    $script:CurrentValidationMode = $ValidationMode
    $script:SizeCandidates = @{}
    $script:TaskFileKinds = @{}
    $script:TaskEnds = [Collections.Generic.List[string]]::new()
    $script:PlanRepresentations = @{}

    Test-StructuralConflicts $ResolvedChangePath

    $definitions = @(
        [pscustomobject]@{ Key = 'prd'; Label = 'PRD'; File = (Join-Path $ResolvedChangePath 'prd.md'); Directory = (Join-Path $ResolvedChangePath 'prd') },
        [pscustomobject]@{ Key = 'proposal'; Label = 'proposal'; File = (Join-Path $ResolvedChangePath 'proposal.md'); Directory = (Join-Path $ResolvedChangePath 'proposal') },
        [pscustomobject]@{ Key = 'backend'; Label = 'backend design'; File = (Join-Path $ResolvedChangePath 'design/backend.md'); Directory = (Join-Path $ResolvedChangePath 'design/backend') },
        [pscustomobject]@{ Key = 'frontend'; Label = 'frontend design'; File = (Join-Path $ResolvedChangePath 'design/frontend.md'); Directory = (Join-Path $ResolvedChangePath 'design/frontend') }
    )
    $designRepresentations = @{}
    foreach ($definition in $definitions) {
        $index = Join-Path $definition.Directory '00-index.md'
        $representation = Test-ExclusiveRepresentation $definition.File $index $definition.Label
        $rows = @()
        if ($representation.HasDirectory) { $rows = @(Test-SplitDirectory $definition.Directory $definition.Label) }
        if ($representation.HasFile) { Add-SizeCandidate $definition.File }
        if (($representation.HasFile -or $representation.HasDirectory) -and $definition.Key -eq 'prd') {
            Test-PrdLogicalTemplate (Get-LogicalArtifactText $definition.File $rows)
        }
        if (($representation.HasFile -or $representation.HasDirectory) -and $definition.Key -eq 'proposal') {
            Test-ProposalLogicalTemplate (Get-LogicalArtifactText $definition.File $rows)
        }
        if (($representation.HasFile -or $representation.HasDirectory) -and $definition.Key -in @('backend', 'frontend')) {
            $mode = if ($representation.HasFile) { 'small' } else { 'split' }
            $entry = if ($representation.HasFile) { "design/$($definition.Key).md" } else { "design/$($definition.Key)/00-index.md" }
            $designRepresentations[$definition.Key] = [pscustomobject]@{ Entry = $entry; Mode = $mode }
        }
    }
    $designIndex = Join-Path $ResolvedChangePath 'design/00-index.md'
    Test-DesignIndex $designIndex $designRepresentations

    $taskFiles = [Collections.Generic.List[string]]::new()
    $tasksDirectory = Join-Path $ResolvedChangePath 'tasks'
    foreach ($end in @('backend', 'frontend')) {
        $stable = Join-Path $tasksDirectory "plan-$end.md"
        $split = Join-Path $tasksDirectory $end
        $index = Join-Path $split '00-index.md'
        $representation = Test-ExclusiveRepresentation $stable $index "$end plan"
        $rows = @()
        if ($representation.HasDirectory) {
            $rows = @(Test-SplitDirectory $split "$end plan")
            Test-PlanManifestKinds $rows $end
        }
        if ($representation.HasFile -or $representation.HasDirectory) { $script:TaskEnds.Add($end) }
        if ($representation.HasFile) { $script:PlanRepresentations[$end] = [pscustomobject]@{ Entry = "tasks/plan-$end.md"; Mode = 'small' } }
        if ($representation.HasDirectory) { $script:PlanRepresentations[$end] = [pscustomobject]@{ Entry = "tasks/$end/00-index.md"; Mode = 'split' } }

        if ($representation.HasFile) {
            $taskFiles.Add($stable)
            $script:TaskFileKinds[(Get-NormalizedPath $stable)] = 'tasks'
            Add-SizeCandidate $stable
        }
        if ($representation.HasDirectory) {
            $taskFiles.Add($index)
            $script:TaskFileKinds[(Get-NormalizedPath $index)] = 'index'
            foreach ($row in $rows) {
                $taskFiles.Add($row.Path)
                $script:TaskFileKinds[(Get-NormalizedPath $row.Path)] = $row.Kind.ToLowerInvariant()
            }
        }
    }

    $graph = Get-TaskGraph @($taskFiles)
    Test-TaskDependencyGraph $graph
    Test-TaskOverview $tasksDirectory $graph $script:PlanRepresentations

    $allMarkdownFiles = @(Get-ChildItem -LiteralPath $ResolvedChangePath -Recurse -File -Filter '*.md')
    foreach ($artifact in $allMarkdownFiles) {
        $artifactPath = Get-NormalizedPath $artifact.FullName
        if (-not $script:SizeCandidates.ContainsKey($artifactPath)) {
            $script:SizeCandidates[$artifactPath] = $true
        }
        $text = [IO.File]::ReadAllText($artifactPath)
        if ([regex]::IsMatch($text, '(?im)^\s*-\s*\[(?: |x|X)\]\s+\*\*Task\s+(?:backend|frontend)-\d{3}\b')) {
            $kind = if ($script:TaskFileKinds.ContainsKey($artifactPath)) { $script:TaskFileKinds[$artifactPath] } else { $null }
            if ($kind -ne 'tasks') {
                Fail-Layout "task checkbox in non-task file: $(Get-RelativeArtifactPath $artifactPath)"
            }
        }
    }

    foreach ($path in $script:SizeCandidates.Keys) {
        $metrics = Get-TextMetrics $path
        $relative = Get-RelativeArtifactPath $path
        if ($metrics.Lines -gt 500) {
            Fail-Layout "$relative has $($metrics.Lines) lines; maximum is 500"
        }
        if ($metrics.Characters -gt 30000) {
            Fail-Layout "$relative has $($metrics.Characters) characters; maximum is 30000"
        }
    }

    return [pscustomobject]@{
        Files = $script:SizeCandidates.Count
        Tasks = $graph.Ownership.Count
    }
}

try {
    if (-not (Test-Path -LiteralPath $ChangePath -PathType Container)) {
        throw "change directory does not exist: $ChangePath"
    }
    $resolved = Get-NormalizedPath (Resolve-Path -LiteralPath $ChangePath).Path
    $result = Test-ChangeArtifacts $resolved $Mode
    Write-Output "Artifact layout valid: mode=$Mode; files=$($result.Files); tasks=$($result.Tasks)."
}
catch {
    if ($_.Exception.Message -like 'Artifact layout invalid:*') { throw }
    throw "Artifact layout invalid: $($_.Exception.Message)"
}
