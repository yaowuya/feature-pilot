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
        $covered = [regex]::Match($section, '(?m)^-[ \t]*Covered IDs:[ \t]*(?<value>[^\r\n]+)[ \t]*(?:\r(?=\n))?$')
        $outstanding = [regex]::Match($section, '(?m)^-[ \t]*Outstanding blocking decisions:[ \t]*(?<value>[^\r\n]+)[ \t]*(?:\r(?=\n))?$')
        $authorization = [regex]::Match($section, '(?m)^-[ \t]*Explicit user authorization to write:[ \t]*(?<value>[^\r\n]+)[ \t]*(?:\r(?=\n))?$')
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

function Get-LineCount([string]$text) {
    if ($text.Length -eq 0) { return 0 }
    $newlineCount = [regex]::Matches($text, '\r?\n').Count
    if ($text -match '\r?\n\z') { return $newlineCount }
    return $newlineCount + 1
}

function Get-CommandChecksumBullets([string]$text, [string]$surface) {
    $checksumMatches = @([regex]::Matches($text, '(?ms)^Gate checksum：[ \t]*\r?\n(?<body>.*)\z'))
    Assert-Condition ($checksumMatches.Count -eq 1) "$surface must contain exactly one Gate checksum section"
    return @([regex]::Matches($checksumMatches[0].Groups['body'].Value, '(?m)^-[ \t]+(?<text>[^\r\n]+)\r?$') | ForEach-Object { $_.Groups['text'].Value })
}

function Assert-FpStartCommandChecksumContract([string]$text, [string]$surface) {
    Assert-Condition ($text.Contains('description: 启动全流程开发向导')) "$surface lost its meaningful public description"
    Assert-Condition ($text.Contains('`${CLAUDE_PLUGIN_ROOT}/skills/fp-start/SKILL.md`')) "$surface lost its exact skill loader"
    Assert-Condition ($text.Contains('$ARGUMENTS')) "$surface no longer passes the command input"
    Assert-Condition ($text.Contains('`${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md`')) "$surface lost canonical artifact delegation"

    $bullets = @(Get-CommandChecksumBullets $text $surface)
    Assert-Condition ($bullets.Count -eq 8) "$surface must contain exactly eight checksum bullets"

    Assert-OrderedAnchors $bullets[0] @(
        '`fp-explore`'
        '用户确认'
        '`fp-quick`'
    ) "$surface checksum bullet 1 quick-route confirmation"
    Assert-OrderedAnchors $bullets[1] @(
        '`fp-propose`'
        '`fp-brainstorm`'
        '`fp-plan`'
        '逐阶段核验/确认'
        'proposal/design查'
        'Decision Ledger/per-item confirmation'
    ) "$surface checksum bullet 2 ordered stage gates"
    Assert-OrderedAnchors $bullets[2] @(
        'proposal/design 写门禁后加载共享文档风格契约'
        '禁改确认内容/Decision Ledger/canonical layout'
    ) "$surface checksum bullet 3 post-gate style contract"
    Assert-OrderedAnchors $bullets[3] @(
        '模型由 `fp-brainstorm` 核验'
        '真实基类'
        '继承字段'
        '物理存储'
        '约束'
        'migration'
        '评审禁重设计'
    ) "$surface checksum bullet 4 model ownership"
    Assert-OrderedAnchors $bullets[4] @(
        '计划确认前禁改业务代码'
        '执行仅用已确认 task 文件'
        '禁聊天摘要'
    ) "$surface checksum bullet 5 plan/execution-source boundary"
    Assert-OrderedAnchors $bullets[5] @(
        '默认加载 `fp-execute`'
        '仅用户明确要求逐任务确认才用 `semi`'
    ) "$surface checksum bullet 6 direct execution mode"
    Assert-OrderedAnchors $bullets[6] @(
        '只有用户明确要求'
        '`fp-execute-sdd`'
        '通用 `SDD`'
        'fresh implementer/reviewer isolation'
        '才进 SDD'
        '再选 SDD'
        'SDD 逐项确认'
        '自动连续'
    ) "$surface checksum bullet 7 SDD eligibility and mode"
    Assert-OrderedAnchors $bullets[7] @(
        '完成后由'
        '`fp-final-review`'
        '接管最终评审/交接'
    ) "$surface checksum bullet 8 final-review ownership"
    Assert-Condition ((Get-LineCount $text) -le 20) "$surface exceeds 20 lines"
}

function Test-FpStartCommandChecksumContract([string]$text) {
    try {
        Assert-FpStartCommandChecksumContract $text 'fp-start command fixture'
        return $true
    } catch {
        return $false
    }
}

$proposalSkillPath = Join-Path $root 'skills\fp-propose\SKILL.md'
$proposalTemplatePath = Join-Path $root 'skills\fp-propose\proposal-template.md'
$brainstormSkillPath = Join-Path $root 'skills\fp-brainstorm\SKILL.md'
$designTemplatePath = Join-Path $root 'skills\fp-brainstorm\design-template.md'
$startSkillPath = Join-Path $root 'skills\fp-start\SKILL.md'
$decisionLedgerPath = Join-Path $root 'skills\_shared\decision-ledger.md'
$startCommandPath = Join-Path $root 'commands\fp-start.md'
$validatorPath = Join-Path $root 'scripts\validate-plugin.ps1'
$designReviewSkillPath = Join-Path $root 'skills\fp-design-review\SKILL.md'
$reviewTemplatePath = Join-Path $root 'skills\fp-design-review\review-template.md'
$designReviewCommandPath = Join-Path $root 'commands\fp-design-review.md'

foreach ($path in @(
    $proposalSkillPath,
    $proposalTemplatePath,
    $brainstormSkillPath,
    $designTemplatePath,
    $startSkillPath,
    $decisionLedgerPath,
    $startCommandPath,
    $validatorPath,
    $designReviewSkillPath,
    $reviewTemplatePath,
    $designReviewCommandPath
)) {
    Assert-Condition (Test-Path $path) "required decision-gate surface is missing: $path"
}

$proposalSkill = Read-Utf8 $proposalSkillPath
$proposalTemplate = Read-Utf8 $proposalTemplatePath
$brainstormSkill = Read-Utf8 $brainstormSkillPath
$designTemplate = Read-Utf8 $designTemplatePath
$startSkill = Read-Utf8 $startSkillPath
$decisionLedger = Read-Utf8 $decisionLedgerPath
$startCommand = Read-Utf8 $startCommandPath
$validator = Read-Utf8 $validatorPath
$designReviewSkill = Read-Utf8 $designReviewSkillPath
$reviewTemplate = Read-Utf8 $reviewTemplatePath
$designReviewCommand = Read-Utf8 $designReviewCommandPath

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
    'selected value and message reference',
    '可理解的决策问题',
    '为什么现在需要这个决定',
    '会影响哪些产物或运行行为',
    '每个选项采用后的实际行为',
    '主要代价或风险',
    '推荐选项及推荐理由',
    '以业务或行为结果命名',
    '必须先用直白语言解释'
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

$brainstormContext = Get-MarkdownSection $brainstormSkill '第一步：读取上下文' 'fp-brainstorm'
$modelInvestigationHeading = '#### 项目模型规范调查'
$djangoChecksHeading = '#### Django 条件化检查'
$modelInvestigationStart = $brainstormContext.IndexOf($modelInvestigationHeading, [System.StringComparison]::Ordinal)
$djangoChecksStart = $brainstormContext.IndexOf($djangoChecksHeading, [System.StringComparison]::Ordinal)
Assert-Condition ($modelInvestigationStart -ge 0) 'fp-brainstorm context is missing the project model investigation section'
Assert-Condition ($djangoChecksStart -gt $modelInvestigationStart) 'fp-brainstorm context is missing the scoped Django checks after model investigation'
$modelInvestigation = $brainstormContext.Substring($modelInvestigationStart, $djangoChecksStart - $modelInvestigationStart)
$djangoChecks = $brainstormContext.Substring($djangoChecksStart)

Assert-Anchors $modelInvestigation @(
    '仅当本次变更涉及数据库模型时执行'
    '目标模型、公共基类、manager、mixin 和相邻版本模型'
    '字段长度常量'
    '字段与存储选择理由'
    '显式字段与继承字段'
    '逻辑模型与实际物理表'
    '主要查询模式'
    '查询模式与索引映射'
    '软删除后的唯一性含义'
    '没有实际数据库收益的迁移'
    '任何持久化技术都必须把主要查询模式映射到索引或访问路径'
) 'fp-brainstorm bounded project model investigation'
Assert-Anchors $djangoChecks @(
    '仅当目标项目使用 Django 且本次涉及模型时'
    'abstract、proxy 和 multi-table inheritance'
    '`choices` 是否进入 migration state'
    '联合索引左前缀'
    '不得擅自统一选择'
    '非 Django 项目只执行对应 ORM 与 schema migration 检查'
    '设计正文必须记录证据路径和最终结论'
    '当前代码无法证明的新选择仍进入 Decision Ledger'
    '不得把推荐写成 `code-verified`'
) 'fp-brainstorm conditional Django model investigation'

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
Assert-Anchors $designTemplate @(
    '接近实现的模型代码'
    '逻辑模型与物理存储'
    '继承字段与重复存储结论'
    '索引、约束与软删除'
    'Migration 影响'
    '技术栈专项结论'
) 'design template model review contract'

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

$proposalEvidenceNoFinalNewlineFixture = @(
    '- Covered IDs: `P-001`'
    '- Outstanding blocking decisions: `none`'
    '- Explicit user authorization to write: P-001: user message 42 approves proposal.md and target paths'
) -join "`n"
$proposalEvidenceLfFixture = $proposalEvidenceNoFinalNewlineFixture + "`n"
$proposalEvidenceCrlfFixture = $proposalEvidenceLfFixture.Replace("`n", "`r`n")
$proposalEvidenceBareCrFixture = $proposalEvidenceNoFinalNewlineFixture + "`r"
Assert-Condition (Test-PreWriteConfirmationEvidence $proposalEvidenceLfFixture @('P-001')) 'LF pre-write confirmation evidence fixture is invalid'
Assert-Condition (Test-PreWriteConfirmationEvidence $proposalEvidenceCrlfFixture @('P-001')) 'CRLF pre-write confirmation evidence fixture is invalid'
Assert-Condition (Test-PreWriteConfirmationEvidence $proposalEvidenceNoFinalNewlineFixture @('P-001')) 'pre-write confirmation evidence fixture without a final newline is invalid'
Assert-Condition (-not (Test-PreWriteConfirmationEvidence $proposalEvidenceBareCrFixture @('P-001'))) 'mutation survived: pre-write confirmation evidence may end with a bare CR'

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

$visualSourceQuestionHeading = '- **【仅在视觉来源未确认时必问，且最先问】视觉来源决策**'
$visualSourceQuestionStart = $brainstormSkill.IndexOf($visualSourceQuestionHeading, [System.StringComparison]::Ordinal)
Assert-Condition ($visualSourceQuestionStart -ge 0) 'fp-brainstorm is missing the concrete visual-source decision question'
$visualSourceQuestionEnd = $brainstormSkill.IndexOf('- 页面/视图：', $visualSourceQuestionStart, [System.StringComparison]::Ordinal)
Assert-Condition ($visualSourceQuestionEnd -gt $visualSourceQuestionStart) 'fp-brainstorm visual-source decision question has no bounded end before the next frontend topic'
$visualSourceQuestion = $brainstormSkill.Substring($visualSourceQuestionStart, $visualSourceQuestionEnd - $visualSourceQuestionStart)
Assert-Anchors $visualSourceQuestion @(
    '创建或定位“视觉来源”对应的实际 `D-NNN`'
    '`needs-user-confirmation`'
    '为什么现在需要这个决定'
    '会影响哪些设计产物或运行行为'
    '`Visual Source`'
    '`Figma 节点/页面`'
    '`UI 组件树与 Figma 解析映射`'
    'Flex/Grid 容器规划'
    '`Visual Checks`'
    '运行时视觉一致性'
    '以 Figma 作为视觉来源'
    '以用户提供截图作为视觉来源'
    '按 UI/UX 规则和相邻页面推导'
    '推荐依据只使用已确认且可访问的证据'
    '其他（请描述）'
    '采用“以 Figma 作为视觉来源”'
    '采用“以用户提供截图作为视觉来源”'
    '采用“按 UI/UX 规则和相邻页面推导”'
) 'fp-brainstorm concrete visual-source decision question'
Assert-OrderedAnchors $visualSourceQuestion @(
    '为什么现在需要这个决定'
    '会影响哪些设计产物或运行行为'
    '以 Figma 作为视觉来源'
    '以用户提供截图作为视觉来源'
    '按 UI/UX 规则和相邻页面推导'
    '推荐依据只使用已确认且可访问的证据'
    '请按实际 `D-NNN` 确认一个结果标签'
) 'fp-brainstorm visual-source question explanation/recommendation/confirmation order'
$visualSourceBehaviorCount = [regex]::Matches($visualSourceQuestion, '实际行为：').Count
$visualSourceRiskCount = [regex]::Matches($visualSourceQuestion, '主要代价或风险：').Count
Assert-Condition ($visualSourceBehaviorCount -eq 3) "fp-brainstorm visual-source question must explain exactly three option behaviors; found $visualSourceBehaviorCount"
Assert-Condition ($visualSourceRiskCount -eq 3) "fp-brainstorm visual-source question must explain exactly three option risks; found $visualSourceRiskCount"
Assert-Condition (-not [regex]::IsMatch($visualSourceQuestion, '(?m)(?:选项\s*[ABC]|选\s*[ABC])')) 'fp-brainstorm visual-source question still uses generic A/B/C labels'

Assert-Anchors $brainstormSkill @('globally unique D-NNN sequence') 'fp-brainstorm cross-end decision ownership'
Assert-Anchors $startSkill @(
    'fp-design-review'
    'review.md'
    '评审结论'
    '业务和技术主线'
    '主要风险'
    '定点修订并重新确认'
    '不得编造缺失设计'
) 'fp-start complete review handoff'
Assert-Anchors $designReviewSkill @(
    'review.md'
    'review-template.md'
    'fp-docs/changes/<slug>/review.md'
    '设计充分性检查'
    '独立可读的完整评审文档'
    '建议评审顺序'
    '建议抽查路径'
    'design/00-index.md'
    'manifest order'
    'canonical-first'
    '不得复制台账行或机械复制叙述性设计正文'
    '不得编造'
    '阻塞'
) 'fp-design-review skill'
Assert-Anchors $reviewTemplate @(
    '# <功能描述> — 开发设计评审'
    '## 评审结论'
    '## 业务和技术主线'
    '## 核心对象与职责'
    '## 主要风险、迁移、发布和验证'
    '## 评审顺序与抽查路径'
    '## 设计入口'
    '不得复制 Decision Ledger rows'
    '不得编造设计事实'
) 'design review template'
Assert-Anchors $designReviewCommand @('fp-design-review', 'review.md', 'Gate checksum', '不复制台账/叙述正文') 'commands/fp-design-review.md'
Assert-Anchors $startSkill @('globally unique D-NNN sequence', 'Covered IDs') 'fp-start cross-end decision recovery'

Assert-FpStartCommandChecksumContract $startCommand 'commands/fp-start.md'

$startCommandMutations = @(
    @{ Name = 'public description may become ambiguous'; Old = 'description: 启动全流程开发向导'; New = 'description: 启动' }
    @{ Name = 'loader may stop targeting fp-start'; Old = '${CLAUDE_PLUGIN_ROOT}/skills/fp-start/SKILL.md'; New = '${CLAUDE_PLUGIN_ROOT}/skills/fp-route/SKILL.md' }
    @{ Name = 'loader may drop command input'; Old = '$ARGUMENTS'; New = '$INPUT' }
    @{ Name = 'loader may drop artifact-layout delegation'; Old = '${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md'; New = '${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md' }
    @{ Name = 'quick route may omit fp-explore'; Old = '`fp-explore`'; New = '`fp-route`' }
    @{ Name = 'quick route may omit user confirmation'; Old = '→用户确认→'; New = '→自动→' }
    @{ Name = 'quick route may omit fp-quick'; Old = '`fp-quick`'; New = '`quick-mode`' }
    @{ Name = 'full flow may omit fp-propose'; Old = '`fp-propose`→'; New = '`fp-scope`→' }
    @{ Name = 'full flow may omit fp-brainstorm'; Old = '`fp-brainstorm`→'; New = '`fp-design`→' }
    @{ Name = 'full flow may omit fp-plan'; Old = '`fp-plan` 逐阶段'; New = '`fp-tasks` 逐阶段' }
    @{ Name = 'full-flow stages may be reordered'; Old = '`fp-propose`→`fp-brainstorm`→`fp-plan`'; New = '`fp-brainstorm`→`fp-propose`→`fp-plan`' }
    @{ Name = 'a stage may skip verification or confirmation'; Old = '逐阶段核验/确认'; New = '阶段完成后继续' }
    @{ Name = 'proposal/design may skip its Decision Ledger scope'; Old = 'proposal/design查'; New = '全程查' }
    @{ Name = 'proposal/design may skip Decision Ledger verification'; Old = 'Decision Ledger/per-item confirmation'; New = 'decision notes/per-item confirmation' }
    @{ Name = 'proposal/design may skip per-item confirmation'; Old = 'per-item confirmation'; New = 'summary confirmation' }
    @{ Name = 'proposal/design may load style before its write gate'; Old = 'proposal/design 写门禁后加载共享文档风格契约'; New = 'proposal/design 加载共享文档风格契约' }
    @{ Name = 'style repair may change confirmed semantics'; Old = '禁改确认内容'; New = '可改确认内容' }
    @{ Name = 'model investigation may lose its conditional owner'; Old = '模型由 `fp-brainstorm`'; New = '模型由评审阶段' }
    @{ Name = 'model investigation may omit real-base verification'; Old = '真实基类'; New = '模型结构' }
    @{ Name = 'review may redesign the model'; Old = '评审禁重设计'; New = '评审可重设计' }
    @{ Name = 'business code may change before plan confirmation'; Old = '计划确认前禁改业务代码'; New = '计划形成后可改业务代码' }
    @{ Name = 'execution may consume unconfirmed or non-task input'; Old = '执行仅用已确认 task 文件'; New = '执行读取可用输入' }
    @{ Name = 'execution may consume a chat summary'; Old = '禁聊天摘要'; New = '可用聊天摘要' }
    @{ Name = 'fp-execute may stop being the default'; Old = '默认加载 `fp-execute`'; New = '可选 `fp-execute`' }
    @{ Name = 'semi may be selected without an explicit user request'; Old = '仅用户明确要求逐任务确认才用 `semi`'; New = '逐任务确认时可用 `semi`' }
    @{ Name = 'SDD routing may omit explicit fp-execute-sdd'; Old = '`fp-execute-sdd`/通用'; New = '`sdd-runner`/通用' }
    @{ Name = 'SDD routing may omit a generic SDD request'; Old = '通用 `SDD`'; New = '专用模式' }
    @{ Name = 'SDD routing may omit fresh implementer/reviewer isolation'; Old = 'fresh implementer/reviewer isolation'; New = 'isolated execution' }
    @{ Name = 'SDD may be entered without an explicit user request'; Old = '只有用户明确要求 `fp-execute-sdd`'; New = '检测到 `fp-execute-sdd`' }
    @{ Name = 'SDD may skip continuation-mode selection'; Old = '再选 SDD'; New = '直接 SDD' }
    @{ Name = 'SDD may omit per-item confirmation mode'; Old = 'SDD 逐项确认'; New = 'SDD 手动模式' }
    @{ Name = 'SDD may omit automatic continuous mode'; Old = '自动连续'; New = '批量模式' }
    @{ Name = 'execution may omit the final-review handoff'; Old = '完成后由'; New = '完成后记录' }
    @{ Name = 'final handoff may omit fp-final-review'; Old = '`fp-final-review`'; New = '`review-summary`' }
    @{ Name = 'fp-final-review may not own final review and handoff'; Old = '接管最终评审/交接'; New = '生成摘要' }
)
foreach ($mutation in $startCommandMutations) {
    $mutatedStartCommand = Replace-Required $startCommand $mutation.Old $mutation.New $mutation.Name
    Assert-Condition (-not (Test-FpStartCommandChecksumContract $mutatedStartCommand)) "mutation survived: $($mutation.Name)"
}

Assert-Anchors $validator @(
    "`$decisionGateContractValidator = Join-Path `$root 'scripts\test-decision-gate-contract.ps1'",
    '& powershell -NoProfile -ExecutionPolicy Bypass -File $decisionGateContractValidator'
) 'global validator decision-gate invocation'

Write-Output 'Decision-gate contract validation passed.'
