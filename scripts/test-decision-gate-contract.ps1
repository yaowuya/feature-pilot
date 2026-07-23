$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "Decision-gate contract validation failed: $message"
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

function Assert-OrderedAnchors([string]$text, [string[]]$anchors, [string]$surface) {
    $previousIndex = -1
    foreach ($anchor in $anchors) {
        $index = $text.IndexOf($anchor, $previousIndex + 1, [System.StringComparison]::OrdinalIgnoreCase)
        Assert-Condition ($index -ge 0) "$surface lost ordered anchor: $anchor"
        Assert-Condition ($index -gt $previousIndex) "$surface has an invalid gate order at: $anchor"
        $previousIndex = $index
    }
}

function Get-MarkdownSection([string]$text, [string]$heading, [string]$surface) {
    $pattern = "(?ms)^###\s+" + [regex]::Escape($heading) + "\s*\r?\n(?<body>.*?)(?=^#{1,3}\s+|\z)"
    $match = [regex]::Match($text, $pattern)
    Assert-Condition $match.Success "$surface is missing ### $heading"
    return $match.Value
}

function Split-MarkdownCells([string]$line) {
    $trimmed = $line.Trim()
    Assert-Condition ($trimmed.StartsWith('|') -and $trimmed.EndsWith('|')) "malformed markdown table row: $line"
    return @($trimmed.Trim('|').Split('|') | ForEach-Object { $_.Trim() })
}

function Get-DecisionLedgerRows([string]$section, [string]$surface) {
    $expectedHeader = @('ID', 'Decision', 'Source', 'Blocking', 'Status', 'Evidence / explicit confirmation')
    $lines = @($section -split "`r?`n")
    $headerIndex = -1

    for ($index = 0; $index -lt $lines.Count; $index++) {
        if (-not $lines[$index].Trim().StartsWith('|')) { continue }
        $cells = Split-MarkdownCells $lines[$index]
        if ($cells.Count -ne $expectedHeader.Count) { continue }
        $matches = $true
        for ($cellIndex = 0; $cellIndex -lt $expectedHeader.Count; $cellIndex++) {
            if ($cells[$cellIndex] -cne $expectedHeader[$cellIndex]) {
                $matches = $false
                break
            }
        }
        if ($matches) {
            Assert-Condition ($headerIndex -eq -1) "$surface has more than one Decision Ledger table"
            $headerIndex = $index
        }
    }

    Assert-Condition ($headerIndex -ge 0) "$surface has no exact Decision Ledger table"
    Assert-Condition (($headerIndex + 1) -lt $lines.Count) "$surface Decision Ledger table has no separator"
    $separator = Split-MarkdownCells $lines[$headerIndex + 1]
    Assert-Condition ($separator.Count -eq $expectedHeader.Count) "$surface Decision Ledger separator has the wrong column count"
    foreach ($cell in $separator) {
        Assert-Condition ($cell -match '^:?-{3,}:?$') "$surface Decision Ledger separator is malformed: $cell"
    }

    $rows = @()
    for ($index = $headerIndex + 2; $index -lt $lines.Count; $index++) {
        if (-not $lines[$index].Trim().StartsWith('|')) { break }
        $cells = Split-MarkdownCells $lines[$index]
        Assert-Condition ($cells.Count -eq $expectedHeader.Count) "$surface Decision Ledger data row has the wrong column count"
        $rows += ,$cells
    }
    Assert-Condition ($rows.Count -gt 0) "$surface Decision Ledger has no data rows"
    return [pscustomobject]@{ Rows = @($rows) }
}

function Test-ConcreteConfirmationValue([string]$value) {
    $normalized = $value.Trim().Trim('`')
    if ([string]::IsNullOrWhiteSpace($normalized)) { return $false }
    if ($normalized -match '<[^>]+>') { return $false }
    if ($normalized -match '(?i)\b(?:tbd|todo|unknown|placeholder)\b') { return $false }
    if ($normalized -match '(?i)^confirmation record or code evidence$') { return $false }
    if ($normalized -match '(?i)\buser answer\b') { return $false }
    return $true
}

function Test-UserConfirmedEvidence([string]$value) {
    if (-not (Test-ConcreteConfirmationValue $value)) { return $false }
    $hasSelectedValue = $value -match '(?i)\b(?:selected|selection|option|choice)\b'
    $hasMessageReference = $value -match '(?i)\b(?:message|record|reference)\b'
    return $hasSelectedValue -and $hasMessageReference
}

function Test-ExplicitWriteAuthorization([string]$value) {
    if (-not (Test-ConcreteConfirmationValue $value)) { return $false }
    $hasApproval = $value -match '(?i)\b(?:approv(?:e|es|ed|al)|authori[sz](?:e|es|ed|ation))\b'
    $hasMessageReference = $value -match '(?i)\b(?:message|record|reference)\b'
    return $hasApproval -and $hasMessageReference
}

function Test-PersistedDecisionLedger([string]$section, [string]$requiredPrefix) {
    try {
        $rows = (Get-DecisionLedgerRows $section 'mutation fixture').Rows
        $terminalStatuses = @('PRD-confirmed', 'code-verified', 'user-confirmed', 'not-applicable')
        $seenIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
        foreach ($row in $rows) {
            $id = $row[0].Trim('`')
            if ($id -notmatch ('^{0}-[0-9]{{3}}$' -f [regex]::Escape($requiredPrefix))) { return $false }
            if (-not $seenIds.Add($id)) { return $false }
            if ([string]::IsNullOrWhiteSpace($row[1])) { return $false }
            if (-not (Test-ConcreteConfirmationValue $row[2])) { return $false }
            if ($row[3].Trim('`') -notin @('yes', 'no')) { return $false }
            if (-not (Test-ConcreteConfirmationValue $row[5])) { return $false }
            if ($row[5].IndexOf($id, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) { return $false }
            $status = $row[4].Trim('`')
            if ($terminalStatuses -notcontains $status) { return $false }
            if ($status -eq 'user-confirmed' -and -not (Test-UserConfirmedEvidence $row[5])) { return $false }
        }
        return $true
    } catch {
        return $false
    }
}

function Test-DecisionLedgerSet([string[]]$sections, [string]$requiredPrefix) {
    try {
        $seenIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
        foreach ($section in $sections) {
            if (-not (Test-PersistedDecisionLedger $section $requiredPrefix)) { return $false }
            foreach ($row in (Get-DecisionLedgerRows $section 'multi-owner mutation fixture').Rows) {
                if (-not $seenIds.Add($row[0].Trim('`'))) { return $false }
            }
        }
        return $true
    } catch {
        return $false
    }
}

function Test-PreWriteConfirmationEvidence([string]$section, [string[]]$requiredIds) {
    try {
        $covered = [regex]::Match($section, '(?m)^-[ \t]*Covered IDs:[ \t]*(?<value>[^\r\n]+)[ \t]*$')
        $outstanding = [regex]::Match($section, '(?m)^-[ \t]*Outstanding blocking decisions:[ \t]*(?<value>[^\r\n]+)[ \t]*$')
        $authorization = [regex]::Match($section, '(?m)^-[ \t]*Explicit user authorization to write:[ \t]*(?<value>[^\r\n]+)[ \t]*$')
        if (-not $covered.Success -or -not $outstanding.Success -or -not $authorization.Success) { return $false }

        foreach ($id in $requiredIds) {
            if ($covered.Groups['value'].Value -notmatch ('(?<![A-Z0-9-]){0}(?![A-Z0-9-])' -f [regex]::Escape($id))) { return $false }
        }
        $coveredIds = @([regex]::Matches($covered.Groups['value'].Value, '[A-Z]+-[0-9]{3}') | ForEach-Object { $_.Value })
        if ($coveredIds.Count -ne $requiredIds.Count) { return $false }
        if (@($coveredIds | Select-Object -Unique).Count -ne $coveredIds.Count) { return $false }
        if ($outstanding.Groups['value'].Value.Trim().Trim('`').ToLowerInvariant() -ne 'none') { return $false }
        if (-not (Test-ExplicitWriteAuthorization $authorization.Groups['value'].Value)) { return $false }
        return $true
    } catch {
        return $false
    }
}

function Replace-Required([string]$text, [string]$oldValue, [string]$newValue, [string]$description) {
    $index = $text.IndexOf($oldValue, [System.StringComparison]::Ordinal)
    Assert-Condition ($index -ge 0) "mutation fixture cannot find $description"
    return $text.Substring(0, $index) + $newValue + $text.Substring($index + $oldValue.Length)
}

$proposalSkillPath = Join-Path $root 'skills\fp-propose\SKILL.md'
$proposalTemplatePath = Join-Path $root 'skills\fp-propose\proposal-template.md'
$brainstormSkillPath = Join-Path $root 'skills\fp-brainstorm\SKILL.md'
$designTemplatePath = Join-Path $root 'skills\fp-brainstorm\design-template.md'
$startSkillPath = Join-Path $root 'skills\fp-start\SKILL.md'
$decisionLedgerPath = Join-Path $root 'skills\_shared\decision-ledger.md'
$proposeCommandPath = Join-Path $root 'commands\fp-propose.md'
$brainstormCommandPath = Join-Path $root 'commands\fp-brainstorm.md'
$startCommandPath = Join-Path $root 'commands\fp-start.md'
$validatorPath = Join-Path $root 'scripts\validate-plugin.ps1'

foreach ($path in @(
    $proposalSkillPath,
    $proposalTemplatePath,
    $brainstormSkillPath,
    $designTemplatePath,
    $startSkillPath,
    $decisionLedgerPath,
    $proposeCommandPath,
    $brainstormCommandPath,
    $startCommandPath,
    $validatorPath
)) {
    Assert-Condition (Test-Path $path) "required decision-gate surface is missing: $path"
}

$proposalSkill = Read-Utf8 $proposalSkillPath
$proposalTemplate = Read-Utf8 $proposalTemplatePath
$brainstormSkill = Read-Utf8 $brainstormSkillPath
$designTemplate = Read-Utf8 $designTemplatePath
$startSkill = Read-Utf8 $startSkillPath
$decisionLedger = Read-Utf8 $decisionLedgerPath
$proposeCommand = Read-Utf8 $proposeCommandPath
$brainstormCommand = Read-Utf8 $brainstormCommandPath
$startCommand = Read-Utf8 $startCommandPath
$validator = Read-Utf8 $validatorPath

$statusAnchors = @('PRD-confirmed', 'code-verified', 'user-confirmed', 'not-applicable', 'needs-user-confirmation')

Assert-Anchors $decisionLedger @(
    'Decision Ledger',
    'decision ID',
    'agent recommendation',
    'not user confirmation',
    'generic confirmation does not resolve',
    'separate write authorization',
    'must not persist',
    'Each decision ID is unique within its current phase',
    'every persisted decision ID exactly once',
    'All design end owners use one globally unique D-NNN sequence',
    '`placeholder`',
    '`TBD`',
    '`TODO`',
    '`unknown`',
    'concrete decision ID',
    'user selection or message reference',
    'ID: user answer',
    'selected value and message reference'
) 'shared decision ledger contract'
Assert-Anchors $decisionLedger $statusAnchors 'shared decision ledger status set'

Assert-Anchors $proposalSkill @(
    'Decision Ledger',
    'decision-ledger.md',
    'Handoff Decision Ledger',
    'missing or unresolved',
    'recovery confirmation',
    'decision ID',
    'agent recommendation',
    'not user confirmation',
    'needs-user-confirmation blocks writing',
    'generic confirmation does not resolve',
    'every unresolved decision'
) 'fp-propose'
Assert-Anchors $proposalSkill $statusAnchors 'fp-propose status set'

Assert-Anchors $brainstormSkill @(
    'Decision Ledger',
    'decision-ledger.md',
    'Handoff Decision Ledger',
    'missing or unresolved',
    'return to `fp-propose`',
    'decision ID',
    'agent recommendation',
    'not user confirmation',
    'needs-user-confirmation blocks writing',
    'generic confirmation does not resolve',
    'every unresolved architecture decision'
) 'fp-brainstorm'
Assert-Anchors $brainstormSkill $statusAnchors 'fp-brainstorm status set'

Assert-Anchors $proposalTemplate @(
    '### Handoff Decision Ledger',
    '### Pre-write Confirmation Evidence',
    '| ID | Decision | Source | Blocking | Status | Evidence / explicit confirmation |',
    'needs-user-confirmation',
    'unique detailed owner',
    'must not persist',
    'placeholder'
) 'proposal template'
Assert-Anchors $designTemplate @(
    '### Decision Ledger',
    '### Pre-write Confirmation Evidence',
    '| ID | Decision | Source | Blocking | Status | Evidence / explicit confirmation |',
    'needs-user-confirmation',
    'unique detailed owner',
    'must not persist',
    'placeholder'
) 'design template'

$proposalLedger = Get-MarkdownSection $proposalTemplate 'Handoff Decision Ledger' 'proposal template'
$designLedger = Get-MarkdownSection $designTemplate 'Decision Ledger' 'design template'
$proposalEvidence = Get-MarkdownSection $proposalTemplate 'Pre-write Confirmation Evidence' 'proposal template'
$designEvidence = Get-MarkdownSection $designTemplate 'Pre-write Confirmation Evidence' 'design template'
Assert-Condition (-not (Test-PersistedDecisionLedger $proposalLedger 'P')) 'proposal template placeholders are being accepted as concrete proposal evidence'
Assert-Condition (-not (Test-PersistedDecisionLedger $designLedger 'D')) 'design template placeholders are being accepted as concrete design evidence'
Assert-Condition (-not (Test-PreWriteConfirmationEvidence $proposalEvidence @('P-001'))) 'proposal template placeholder authorization is being accepted'
Assert-Condition (-not (Test-PreWriteConfirmationEvidence $designEvidence @('D-001'))) 'design template placeholder authorization is being accepted'

$proposalLedgerFixture = [regex]::Replace($proposalLedger, '(?m)^\| P-001 \|.*$', '| P-001 | agreed proposal scope | `prd.md#scope` | yes | `PRD-confirmed` | P-001: prd.md#scope confirmed in user message 42 |')
$designLedgerFixture = [regex]::Replace($designLedger, '(?m)^\| D-001 \|.*$', '| D-001 | agreed API contract | `proposal.md#impact` | yes | `user-confirmed` | D-001: user selected option A in message 42 |')
$proposalEvidenceFixture = [regex]::Replace($proposalEvidence, '(?m)(^-\s*Explicit user authorization to write:\s*).+$', '$1P-001: user message 42 approves proposal.md and target paths')
$designEvidenceFixture = [regex]::Replace($designEvidence, '(?m)(^-\s*Explicit user authorization to write:\s*).+$', '$1D-001: user message 42 approves design files and target paths')
Assert-Condition (Test-PersistedDecisionLedger $proposalLedgerFixture 'P') 'concrete proposal Decision Ledger fixture is invalid'
Assert-Condition (Test-PersistedDecisionLedger $designLedgerFixture 'D') 'concrete design Decision Ledger fixture is invalid'
Assert-Condition (Test-PreWriteConfirmationEvidence $proposalEvidenceFixture @('P-001')) 'concrete proposal pre-write confirmation evidence is invalid'
Assert-Condition (Test-PreWriteConfirmationEvidence $designEvidenceFixture @('D-001')) 'concrete design pre-write confirmation evidence is invalid'

$proposalPendingMutation = Replace-Required $proposalLedgerFixture 'PRD-confirmed' 'needs-user-confirmation' 'proposal terminal status'
Assert-Condition (-not (Test-PersistedDecisionLedger $proposalPendingMutation 'P')) 'mutation survived: a pending proposal decision may be persisted'
$designMissingEvidenceMutation = Replace-Required $designLedgerFixture 'D-001: user selected option A in message 42' '' 'design evidence record'
Assert-Condition (-not (Test-PersistedDecisionLedger $designMissingEvidenceMutation 'D')) 'mutation survived: a design decision may omit confirmation evidence'
$designGenericUserAnswerMutation = Replace-Required $designLedgerFixture 'D-001: user selected option A in message 42' 'D-001: user answer' 'design generic user answer'
Assert-Condition (-not (Test-PersistedDecisionLedger $designGenericUserAnswerMutation 'D')) 'mutation survived: a user-confirmed decision may retain a generic answer without selection or message reference'
$designMissingMessageReferenceMutation = Replace-Required $designLedgerFixture 'D-001: user selected option A in message 42' 'D-001: user selected option A' 'design missing message reference'
Assert-Condition (-not (Test-PersistedDecisionLedger $designMissingMessageReferenceMutation 'D')) 'mutation survived: a user-confirmed decision may omit its message reference'
$proposalWrongPrefixMutation = Replace-Required $proposalLedgerFixture 'P-001' 'D-001' 'proposal ID prefix'
Assert-Condition (-not (Test-PersistedDecisionLedger $proposalWrongPrefixMutation 'P')) 'mutation survived: proposal may persist a design decision ID'
$duplicateDesignLedgerMutation = $designLedgerFixture.TrimEnd() + "`r`n| D-001 | duplicate | user-message-43 | no | user-confirmed | D-001: user selected duplicate in message 43 |"
Assert-Condition (-not (Test-PersistedDecisionLedger $duplicateDesignLedgerMutation 'D')) 'mutation survived: design may persist duplicate decision IDs'
$secondDesignOwnerLedger = [regex]::Replace($designLedgerFixture, 'D-001', 'D-002')
$secondDesignOwnerEvidence = [regex]::Replace($designEvidenceFixture, 'D-001', 'D-002')
Assert-Condition (Test-DecisionLedgerSet @($designLedgerFixture, $secondDesignOwnerLedger) 'D') 'distinct design owners may not share one globally unique D-NNN sequence'
Assert-Condition (Test-PreWriteConfirmationEvidence $secondDesignOwnerEvidence @('D-002')) 'second design owner evidence fixture is invalid'
Assert-Condition (-not (Test-DecisionLedgerSet @($designLedgerFixture, $designLedgerFixture) 'D')) 'mutation survived: two design owners may persist the same D-NNN ID'
$secondDesignOwnerCoveredIdMutation = Replace-Required $secondDesignOwnerEvidence 'Covered IDs: `D-002`' 'Covered IDs: `D-001`' 'second design owner covered ID'
Assert-Condition (-not (Test-PreWriteConfirmationEvidence $secondDesignOwnerCoveredIdMutation @('D-002'))) 'mutation survived: a second design owner may report the wrong covered ID'
$proposalMissingAuthorizationMutation = [regex]::Replace($proposalEvidenceFixture, '(?m)(^-\s*Explicit user authorization to write:\s*).+$', '$1')
Assert-Condition (-not (Test-PreWriteConfirmationEvidence $proposalMissingAuthorizationMutation @('P-001'))) 'mutation survived: proposal may omit explicit write authorization'
$proposalPlaceholderAuthorizationMutation = Replace-Required $proposalEvidenceFixture 'P-001: user message 42 approves proposal.md and target paths' '<placeholder>' 'proposal placeholder authorization'
Assert-Condition (-not (Test-PreWriteConfirmationEvidence $proposalPlaceholderAuthorizationMutation @('P-001'))) 'mutation survived: proposal may retain placeholder authorization'
$proposalGenericUserAnswerAuthorizationMutation = Replace-Required $proposalEvidenceFixture 'P-001: user message 42 approves proposal.md and target paths' 'P-001: user answer' 'proposal generic user-answer authorization'
Assert-Condition (-not (Test-PreWriteConfirmationEvidence $proposalGenericUserAnswerAuthorizationMutation @('P-001'))) 'mutation survived: proposal may retain generic user-answer authorization'
$proposalMissingMessageReferenceAuthorizationMutation = Replace-Required $proposalEvidenceFixture 'P-001: user message 42 approves proposal.md and target paths' 'P-001: approves proposal.md and target paths' 'proposal missing authorization message reference'
Assert-Condition (-not (Test-PreWriteConfirmationEvidence $proposalMissingMessageReferenceAuthorizationMutation @('P-001'))) 'mutation survived: proposal authorization may omit its message reference'
$designOutstandingMutation = Replace-Required $designEvidenceFixture 'Outstanding blocking decisions: `none`' 'Outstanding blocking decisions: `D-999`' 'design outstanding decision marker'
Assert-Condition (-not (Test-PreWriteConfirmationEvidence $designOutstandingMutation @('D-001'))) 'mutation survived: design may persist outstanding blocking decisions'
$designCoveredIdMutation = Replace-Required $designEvidenceFixture 'Covered IDs: `D-001`' 'Covered IDs: `D-999`' 'design covered ID'
Assert-Condition (-not (Test-PreWriteConfirmationEvidence $designCoveredIdMutation @('D-001'))) 'mutation survived: design may omit a ledger ID from confirmation evidence'
$designExtraCoveredIdMutation = Replace-Required $designEvidenceFixture 'Covered IDs: `D-001`' 'Covered IDs: `D-001`, `D-999`' 'design extra covered ID'
Assert-Condition (-not (Test-PreWriteConfirmationEvidence $designExtraCoveredIdMutation @('D-001'))) 'mutation survived: design may report an unowned covered ID'

Assert-Anchors $startSkill @(
    'Decision Ledger',
    'pre-write confirmation evidence',
    'missing or unresolved',
    'return to the owning phase',
    'must not assume the gate completed',
    'proposal',
    'design',
    'design-not-started',
    'proposal post-write artifact confirmation',
    'placeholder',
    'ID: user answer'
) 'fp-start resume gate'
Assert-OrderedAnchors $startSkill @(
    'proposal post-write artifact confirmation',
    'design-prewrite-proven-in-session',
    'design-not-started'
) 'fp-start resume state routing'

Assert-Anchors $brainstormSkill @(
    'inherited visual source is absent, conflicting, or ambiguous',
    'do not repeat the Figma question'
) 'fp-brainstorm inherited visual-source gate'
Assert-Anchors $brainstormSkill @('globally unique D-NNN sequence') 'fp-brainstorm cross-end decision ownership'
Assert-Anchors $startSkill @('globally unique D-NNN sequence', 'Covered IDs') 'fp-start cross-end decision recovery'

foreach ($surface in @(
    @{ Name = 'commands/fp-propose.md'; Text = $proposeCommand },
    @{ Name = 'commands/fp-brainstorm.md'; Text = $brainstormCommand },
    @{ Name = 'commands/fp-start.md'; Text = $startCommand }
)) {
    Assert-Anchors $surface.Text @('Decision Ledger', 'per-item confirmation') $surface.Name
}

Assert-Anchors $startCommand @('fresh implementer/reviewer isolation') 'commands/fp-start.md SDD trigger'
Assert-Anchors $validator @(
    "`$decisionGateContractValidator = Join-Path `$root 'scripts\test-decision-gate-contract.ps1'",
    '& powershell -NoProfile -ExecutionPolicy Bypass -File $decisionGateContractValidator'
) 'global validator decision-gate invocation'

Write-Output 'Decision-gate contract validation passed.'
