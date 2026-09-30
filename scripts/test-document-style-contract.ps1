$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "Document-style contract validation failed: $message"
    }
}

function Read-Utf8([string]$relativePath) {
    $path = Join-Path $root $relativePath
    Assert-Condition (Test-Path -LiteralPath $path -PathType Leaf) "missing file: $relativePath"
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Assert-Anchors([string]$text, [string[]]$anchors, [string]$surface) {
    foreach ($anchor in $anchors) {
        Assert-Condition ($text.Contains($anchor)) "$surface lost anchor: $anchor"
    }
}

function Get-MarkdownSection([string]$text, [string]$heading, [string]$surface) {
    $pattern = '(?ms)^' + [regex]::Escape($heading) + '[ \t]*\r?\n(?<body>.*?)(?=^## |\z)'
    $match = [regex]::Match($text, $pattern)
    Assert-Condition ($match.Success) "$surface is missing section: $heading"
    return $match.Groups['body'].Value
}

function Get-UniqueMarkdownSectionMatch([string]$text, [string]$heading, [string]$surface) {
    $headingInfo = [regex]::Match($heading, '^(?<marks>#{1,6})[ \t]+')
    Assert-Condition ($headingInfo.Success) "$surface requested an invalid heading: $heading"
    $level = $headingInfo.Groups['marks'].Value.Length
    $pattern = '(?ms)^' + [regex]::Escape($heading) + '[ \t]*\r?\n(?<body>.*?)(?=^#{1,' + $level + '}[ \t]+|\z)'
    $matches = @([regex]::Matches($text, $pattern))
    Assert-Condition ($matches.Count -eq 1) "$surface must contain exactly one section: $heading; found $($matches.Count)"
    return $matches[0]
}

function Replace-Required([string]$text, [string]$oldValue, [string]$newValue, [string]$description) {
    $index = $text.IndexOf($oldValue, [System.StringComparison]::Ordinal)
    Assert-Condition ($index -ge 0) "mutation fixture cannot find $description"
    return $text.Substring(0, $index) + $newValue + $text.Substring($index + $oldValue.Length)
}

function Assert-OrderedAnchors([string]$text, [string[]]$anchors, [string]$surface) {
    $previousIndex = -1
    foreach ($anchor in $anchors) {
        $index = $text.IndexOf($anchor, [System.StringComparison]::Ordinal)
        Assert-Condition ($index -ge 0) "$surface lost anchor: $anchor"
        Assert-Condition ($index -gt $previousIndex) "$surface has an out-of-order anchor: $anchor"
        $previousIndex = $index
    }
}

function Get-LineCount([string]$text) {
    if ($text.Length -eq 0) {
        return 0
    }

    $newlineCount = [regex]::Matches($text, '\r?\n').Count
    if ($text -match '\r?\n\z') {
        return $newlineCount
    }

    return $newlineCount + 1
}

function Get-CommandChecksumBullets([string]$text, [string]$surface) {
    $checksumMatches = @([regex]::Matches($text, '(?ms)^Gate checksum：[ \t]*\r?\n(?<body>.*)\z'))
    Assert-Condition ($checksumMatches.Count -eq 1) "$surface must contain exactly one Gate checksum section"
    return @([regex]::Matches($checksumMatches[0].Groups['body'].Value, '(?m)^-[ \t]+(?<text>[^\r\n]+)\r?$') | ForEach-Object { $_.Groups['text'].Value })
}

function Assert-PrdCommandChecksumContract([string]$text, [string]$surface) {
    $expectedDescription = 'description: Use when a user explicitly invokes /fp-prd or $fp-prd, or explicitly asks to create, write, revise, or complete a PRD or product requirements document.'
    Assert-Condition ($text.Contains($expectedDescription)) "$surface lost the explicit-only discovery description"
    Assert-Condition ($text.Contains('`${CLAUDE_PLUGIN_ROOT}/skills/fp-prd/SKILL.md`')) "$surface lost its exact skill loader"
    Assert-Condition ($text.Contains('$ARGUMENTS')) "$surface no longer passes the command input"

    $bullets = @(Get-CommandChecksumBullets $text $surface)
    Assert-Condition ($bullets.Count -eq 7) "$surface must contain exactly seven checksum bullets"

    Assert-OrderedAnchors $bullets[0] @(
        '默认 PRD-first'
        'UI-heavy 只推荐'
        '未选不建原型'
    ) "$surface checksum bullet 1"
    Assert-OrderedAnchors $bullets[1] @(
        '`fp-explore`=代码事实'
        '`product-surface-facts`→产品语言'
        '`fp-prd-grill-me` 独占决策/禁代答'
    ) "$surface checksum bullet 2"
    Assert-OrderedAnchors $bullets[2] @(
        '业务闭环'
        '对象/关系/生命周期/版本语义'
        '页面'
    ) "$surface checksum bullet 3"
    Assert-OrderedAnchors $bullets[3] @(
        '产品语言禁'
        '源码路径'
        '类名'
        '函数名'
        '模型名'
        '接口名'
        '构建命令'
        '端口'
        'SHA'
        'Git 状态'
        '验证计数'
    ) "$surface checksum bullet 4"
    Assert-Condition (-not $bullets[4].Contains('Bucket A/B')) "$surface merges Bucket A and Bucket B eligibility"
    Assert-OrderedAnchors $bullets[4] @(
        'Bucket A=用户决定/已验证现状/零影响措辞'
        'Bucket B=易撤销展示默认'
        '其余 Bucket C 逐项问'
        '不因数量降级'
    ) "$surface checksum bullet 5"
    Assert-OrderedAnchors $bullets[5] @(
        '批准前不写 PRD/原型源码、不构建'
        'PRD form互斥'
        'prototype-contract'
        '现有前端默认 `static-modular`'
        '`project-native`/`standalone-html` 须确认'
    ) "$surface checksum bullet 6"
    Assert-OrderedAnchors $bullets[6] @(
        '写门禁后'
        '共享文档风格契约'
        'PRD 模板'
        '只改表达'
        '固定六章/产品事实/确认结果不变'
    ) "$surface checksum bullet 7"
    Assert-Condition ((Get-LineCount $text) -le 20) "$surface exceeds 20 lines"
}

function Test-PrdCommandChecksumContract([string]$text) {
    try {
        Assert-PrdCommandChecksumContract $text 'fp-prd command fixture'
        return $true
    } catch {
        return $false
    }
}

$decisionGateValidatorAssignment = '$decisionGateContractValidator = Join-Path $root ''scripts\test-decision-gate-contract.ps1'''
$documentStyleValidatorAssignment = '$documentStyleContractValidator = Join-Path $root ''scripts\test-document-style-contract.ps1'''
$documentStyleValidatorExistence = 'Assert-Condition (Test-Path $documentStyleContractValidator) ''focused document-style contract validator is missing'''
$documentStyleValidatorInvocation = '& powershell -NoProfile -ExecutionPolicy Bypass -File $documentStyleContractValidator'
$documentStyleValidatorExit = 'Assert-Condition ($LASTEXITCODE -eq 0) ''focused document-style contract validator failed'''
$designReviewValidatorAssignment = '$designReviewContractValidator = Join-Path $root ''scripts\test-design-review-contract.ps1'''
$designReviewValidatorExistence = 'Assert-Condition (Test-Path $designReviewContractValidator) ''focused design-review contract validator is missing'''
$designReviewValidatorInvocation = '& powershell -NoProfile -ExecutionPolicy Bypass -File $designReviewContractValidator'
$designReviewValidatorExit = 'Assert-Condition ($LASTEXITCODE -eq 0) ''focused design-review contract validator failed'''
$prdBusinessValidatorAssignment = '$prdBusinessContractValidator = Join-Path $root ''scripts\test-prd-business-contract.ps1'''

function Assert-LiteralOccursExactlyOnce([string]$text, [string]$literal, [string]$surface) {
    $count = [regex]::Matches($text, [regex]::Escape($literal)).Count
    Assert-Condition ($count -eq 1) "$surface must contain exactly one occurrence of: $literal; found $count"
}

function Assert-ValidatorWiringContract([string]$text, [string]$surface) {
    foreach ($literal in @(
        $decisionGateValidatorAssignment
        $documentStyleValidatorAssignment
        $documentStyleValidatorInvocation
        $documentStyleValidatorExit
        $designReviewValidatorAssignment
        $designReviewValidatorInvocation
        $designReviewValidatorExit
        $prdBusinessValidatorAssignment
    )) {
        Assert-LiteralOccursExactlyOnce $text $literal $surface
    }

    Assert-OrderedAnchors $text @(
        $documentStyleValidatorAssignment
        $documentStyleValidatorInvocation
        $documentStyleValidatorExit
    ) "$surface document-style block"
    Assert-OrderedAnchors $text @(
        $designReviewValidatorAssignment
        $designReviewValidatorInvocation
        $designReviewValidatorExit
    ) "$surface design-review block"
    Assert-OrderedAnchors $text @(
        $decisionGateValidatorAssignment
        $documentStyleValidatorAssignment
        $documentStyleValidatorInvocation
        $documentStyleValidatorExit
        $designReviewValidatorAssignment
        $designReviewValidatorInvocation
        $designReviewValidatorExit
        $prdBusinessValidatorAssignment
    ) "$surface focused-validator placement"
}

function Test-ValidatorWiringContract([string]$text) {
    try {
        Assert-ValidatorWiringContract $text 'global validator fixture'
        return $true
    } catch {
        return $false
    }
}

$canonicalDocumentStylePath = '${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md'
$canonicalDocumentStyleAttribution = 'https://github.com/ruanyf/document-style-guide'
$machineAbsoluteDocumentStyleGuidePatterns = @(
    '(?i)(?<![A-Za-z0-9_])[A-Za-z]:/[^\s`"<>]*document-style-guide(?:/[^\s`"<>]*)?'
    '(?i)(?<![:/])//[^\s`"<>]*document-style-guide(?:/[^\s`"<>]*)?'
    '(?i)(?<![A-Za-z0-9_.$}~:/-])/[^\s`"<>]*document-style-guide(?:/[^\s`"<>]*)?'
    '(?i)(?<![A-Za-z0-9_.-])(?:~(?:[A-Za-z0-9._-]+)?/|\$HOME/|\$\{HOME\}/|%USERPROFILE%/)[^\s`"<>]*document-style-guide(?:/[^\s`"<>]*)?'
    '(?i)file:/+[^\s`"<>]*document-style-guide(?:/[^\s`"<>]*)?'
)

function Assert-PortableDocumentStyleSurface([string]$text, [string]$surface, [bool]$requiresCanonicalReference) {
    $normalized = $text.Replace('\', '/')
    $canonicalReferencePattern = '(?<![A-Za-z0-9_./~:-])' + [regex]::Escape($canonicalDocumentStylePath) + '(?![A-Za-z0-9_./-])'
    $canonicalReferenceCount = [regex]::Matches(
        $normalized,
        $canonicalReferencePattern
    ).Count
    if ($requiresCanonicalReference) {
        Assert-Condition ($canonicalReferenceCount -ge 1) "$surface must load document style through $canonicalDocumentStylePath"
    }

    $withoutCanonicalReferences = [regex]::Replace($normalized, $canonicalReferencePattern, '')
    Assert-Condition (
        -not [regex]::IsMatch($withoutCanonicalReferences, '(?i)document-style\.md')
    ) "$surface contains a noncanonical document-style.md reference"

    $withoutCanonicalAttribution = $normalized.Replace($canonicalDocumentStyleAttribution, '')
    foreach ($pattern in $machineAbsoluteDocumentStyleGuidePatterns) {
        Assert-Condition (
            -not [regex]::IsMatch($withoutCanonicalAttribution, $pattern)
        ) "$surface contains a machine-absolute document-style-guide reference"
    }
}

function Test-PortableDocumentStyleSurface([string]$text, [bool]$requiresCanonicalReference) {
    try {
        Assert-PortableDocumentStyleSurface $text 'document-style portability fixture' $requiresCanonicalReference
        return $true
    } catch {
        return $false
    }
}

function Assert-DocumentStyleRuleLayers([string]$text, [string]$surface) {
    $required = Get-UniqueMarkdownSectionMatch $text '## 必须遵守' $surface
    $recommended = Get-UniqueMarkdownSectionMatch $text '## 建议遵守' $surface
    $exceptions = Get-UniqueMarkdownSectionMatch $text '## 精确内容例外' $surface

    $requiredBody = $required.Groups['body'].Value
    $recommendedBody = $recommended.Groups['body'].Value
    $exceptionBody = $exceptions.Groups['body'].Value

    Assert-Anchors $requiredBody @(
        '文档开头先说明目的、范围、方案主线或结论，再展开细节。'
        '标题不得跳级，也不得与直接上级重名。'
        '标题最多四级，并优先控制在三级以内。固定模板要求的四级标题可以保留。'
        '一个段落只表达一个主题，中心句尽量放在段首。'
        '每段不超过 7 行，并优先控制在 4 行以内。段落之间保留一个空行。'
        '优先使用短句、简单句、主动语态和肯定表达。'
        '必要术语第一次出现时使用直白中文解释。'
        '中文与英文或技术标识符之间保留一个半角空格。'
        '中文句子使用全角标点；完整英文句子使用半角标点。'
        '数值、单位、百分比和范围写法在同一 logical artifact 内保持一致。'
        '同一事实不得在正文、表格、列表和代码块中重复描述。'
        '引用第三方文字、图片或规范时标明来源。'
    ) "$surface required rules"
    Assert-Condition (-not $requiredBody.Contains('普通叙述句优先控制在约 20 个汉字')) "$surface moved advisory sentence length into required rules"

    Assert-Anchors $recommendedBody @(
        '普通叙述句优先控制在约 20 个汉字；超过 40 个汉字时优先拆句。'
        '优先使用三级以内标题和 4 行以内段落。'
        '4 位以上数值优先使用千分位。'
        '数值范围两端都写单位或百分号。'
        '这些数值是生成与人工自检目标，不作为逐字计数失败条件。'
    ) "$surface recommended rules"

    $exceptionClauses = @(
        '代码、命令、路径、URL、哈希和 API 字段'
        '类名、函数名、数据库字段和其他精确技术标识符'
        '固定模板标题、表格列名和 Decision Ledger schema'
        '用户原文、错误消息和需要精确引用的第三方内容'
    )
    Assert-Anchors $exceptionBody ($exceptionClauses + @(
        '例外只豁免精确片段，不豁免周围解释文字。'
        '样式修复不得改变已确认需求、技术结论、字段含义或决策状态。'
    )) "$surface exact-content exceptions"
    foreach ($clause in $exceptionClauses) {
        Assert-Condition (-not $requiredBody.Contains($clause)) "$surface copied an exact-content exception into required rules: $clause"
        Assert-Condition (-not $recommendedBody.Contains($clause)) "$surface copied an exact-content exception into recommendations: $clause"
    }
}

function Test-DocumentStyleRuleLayers([string]$text) {
    try {
        Assert-DocumentStyleRuleLayers $text 'document-style fixture'
        return $true
    } catch {
        return $false
    }
}

$contractPath = 'skills\_shared\document-style.md'
$contract = Read-Utf8 $contractPath

Assert-Anchors $contract @(
    'https://github.com/ruanyf/document-style-guide'
    '5719517'
    'public domain'
    '## 必须遵守'
    '## 建议遵守'
    '## 精确内容例外'
    '## Document readability self-review'
    'PRD'
    'proposal'
    'design'
    'review.md'
    'manifest order'
    '一个段落只表达一个主题'
    '主动语态'
    '肯定表达'
    '中文与英文或技术标识符之间保留一个半角空格'
    '标题末尾不使用句号、逗号、分号或冒号'
    '正文'
    '表格'
    '列表'
    '代码块'
    '引用第三方'
    '普通叙述句优先控制在约 20 个汉字'
    '不作为逐字计数失败条件'
    'Decision Ledger schema'
    '样式修复不得改变已确认需求、技术结论、字段含义或决策状态'
) 'shared document-style contract'
Assert-DocumentStyleRuleLayers $contract 'shared document-style contract'

$attributionInversion = Replace-Required $contract '引用第三方文字、图片或规范时标明来源。' '引用第三方文字、图片或规范时无需标明来源。' 'the source-attribution rule'
Assert-Condition (-not (Test-DocumentStyleRuleLayers $attributionInversion)) 'mutation survived: third-party sources need not be attributed'
$headingWeakening = Replace-Required $contract '标题最多四级，并优先控制在三级以内。固定模板要求的四级标题可以保留。' '标题层级按需增加。' 'the heading-level rule'
Assert-Condition (-not (Test-DocumentStyleRuleLayers $headingWeakening)) 'mutation survived: heading depth may be unbounded'
$terminologyRemoved = Replace-Required $contract '必要术语第一次出现时使用直白中文解释。' '必要术语可以直接使用。' 'the terminology explanation rule'
Assert-Condition (-not (Test-DocumentStyleRuleLayers $terminologyRemoved)) 'mutation survived: necessary terms need not be explained'
$numericRuleRemoved = Replace-Required $contract '数值、单位、百分比和范围写法在同一 logical artifact 内保持一致。' '数值写法可自由变化。' 'the numeric/unit consistency rule'
Assert-Condition (-not (Test-DocumentStyleRuleLayers $numericRuleRemoved)) 'mutation survived: numeric and unit style may drift'
$duplicationAllowed = Replace-Required $contract '同一事实不得在正文、表格、列表和代码块中重复描述。' '同一事实可以在不同载体重复描述。' 'the carrier-separation rule'
Assert-Condition (-not (Test-DocumentStyleRuleLayers $duplicationAllowed)) 'mutation survived: carriers may duplicate one fact'
$exceptionDeleted = Replace-Required $contract '用户原文、错误消息和需要精确引用的第三方内容' '普通叙述内容' 'the user/error/exact-quote exception'
Assert-Condition (-not (Test-DocumentStyleRuleLayers $exceptionDeleted)) 'mutation survived: exact user and error text may be rewritten'
$codeExceptionCopied = Replace-Required $contract '### 读者与结构' "### 读者与结构`n`n- 代码、命令、路径、URL、哈希和 API 字段必须改写。" 'the required-rules heading'
Assert-Condition (-not (Test-DocumentStyleRuleLayers $codeExceptionCopied)) 'mutation survived: code/path/API exceptions may also appear as mandatory rewrite rules'
$identifierExceptionCopied = Replace-Required $contract '### 读者与结构' "### 读者与结构`n`n- 类名、函数名、数据库字段和其他精确技术标识符必须改写。" 'the required-rules heading'
Assert-Condition (-not (Test-DocumentStyleRuleLayers $identifierExceptionCopied)) 'mutation survived: identifier exceptions may also appear as mandatory rewrite rules'
$schemaExceptionCopied = Replace-Required $contract '## 建议遵守' "## 建议遵守`n`n- 固定模板标题、表格列名和 Decision Ledger schema 可以改写。" 'the recommendation-layer heading'
Assert-Condition (-not (Test-DocumentStyleRuleLayers $schemaExceptionCopied)) 'mutation survived: fixed-schema exceptions may also appear as recommendations'
$userExceptionCopied = Replace-Required $contract '## 建议遵守' "## 建议遵守`n`n- 用户原文、错误消息和需要精确引用的第三方内容可以改写。" 'the recommendation-layer heading'
Assert-Condition (-not (Test-DocumentStyleRuleLayers $userExceptionCopied)) 'mutation survived: user/error/quote exceptions may also appear as recommendations'
$advisoryMoved = Replace-Required $contract '## 建议遵守' '## 必须遵守' 'the recommendation-layer heading'
Assert-Condition (-not (Test-DocumentStyleRuleLayers $advisoryMoved)) 'mutation survived: recommendations may move into mandatory rules'

Assert-Condition (@($contract -split "`r?`n").Count -le 500) 'shared contract exceeds 500 lines'
Assert-Condition ($contract.Length -le 30000) 'shared contract exceeds 30,000 characters'

$prdSkill = Read-Utf8 'skills\fp-prd\SKILL.md'
$prdTemplate = Read-Utf8 'skills\fp-prd\prd-template.md'
$proposalSkill = Read-Utf8 'skills\fp-propose\SKILL.md'
$proposalTemplate = Read-Utf8 'skills\fp-propose\proposal-template.md'
$prdCommand = Read-Utf8 'commands\fp-prd.md'
$startCommand = Read-Utf8 'commands\fp-start.md'

$sharedStylePath = '${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md'
$prdTemplatePath = '${CLAUDE_PLUGIN_ROOT}/skills/fp-prd/prd-template.md'
$proposalTemplatePath = '${CLAUDE_PLUGIN_ROOT}/skills/fp-propose/proposal-template.md'
$prdLoadContract = 'read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md` completely, then read `${CLAUDE_PLUGIN_ROOT}/skills/fp-prd/prd-template.md` completely'
$proposalLoadContract = '读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md`，再读取 `${CLAUDE_PLUGIN_ROOT}/skills/fp-propose/proposal-template.md`'

Assert-Condition ($prdSkill.Contains($prdLoadContract)) 'fp-prd does not load document style before its template'
Assert-Condition ($proposalSkill.Contains($proposalLoadContract)) 'fp-propose does not load document style before its template'

$prdOutputHeading = '## PRD output contract'
$prdOutputStart = $prdSkill.IndexOf($prdOutputHeading, [System.StringComparison]::Ordinal)
Assert-Condition ($prdOutputStart -ge 0) 'fp-prd is missing the PRD output contract section'
Assert-Condition (-not $prdSkill.Substring(0, $prdOutputStart).Contains($sharedStylePath)) 'fp-prd loads document style before the PRD output contract gate'
$prdOutputContract = Get-MarkdownSection $prdSkill $prdOutputHeading 'fp-prd'
Assert-OrderedAnchors $prdOutputContract @(
    'final PRD confirmation summary is explicitly approved'
    $sharedStylePath
    $prdTemplatePath
) 'fp-prd output contract gate/load order'

$prdSelfReview = Get-MarkdownSection $prdSkill '## Self-Review' 'fp-prd'
$prdChecklistInvocation = [regex]::Match($prdSelfReview, '(?m)^Run the (?<checklists>[^.\r\n]+) checklists in ')
Assert-Condition ($prdChecklistInvocation.Success) 'fp-prd Self-Review does not invoke its checklists'
Assert-Anchors ($prdChecklistInvocation.Groups['checklists'].Value) @(
    'structure'
    'product-language'
    'business-closure'
    'document-readability'
) 'fp-prd Self-Review checklist invocation'

$proposalStage3Heading = '## 阶段 3：生成 proposal'
$proposalStage3Start = $proposalSkill.IndexOf($proposalStage3Heading, [System.StringComparison]::Ordinal)
Assert-Condition ($proposalStage3Start -ge 0) 'fp-propose is missing stage 3'
Assert-Condition (-not $proposalSkill.Substring(0, $proposalStage3Start).Contains($sharedStylePath)) 'fp-propose loads document style before stage 3'
$proposalStage3 = Get-MarkdownSection $proposalSkill $proposalStage3Heading 'fp-propose'
Assert-OrderedAnchors $proposalStage3 @(
    'proposal-required 台账行终态'
    'separate write authorization'
    $sharedStylePath
    $proposalTemplatePath
) 'fp-propose stage-3 gate/load order'
Assert-Anchors $prdTemplate @(
    '## Document readability self-review'
    '固定六章结构和必需四级标题保持不变'
    '先说明用户、问题、价值和业务结果'
    '不得引入实现语言'
    '按 fragment manifest 顺序检查完整 logical PRD'
) 'PRD template readability review'
Assert-Anchors $proposalTemplate @(
    '## Document readability self-review'
    '`Why` 先说明痛点、目标和现在为什么做'
    '每个 `What Changes` 小节只承载一个变更主题'
    '`Impact` 中的路径和技术标识符保持精确'
    '按 fragment manifest 顺序检查完整 logical proposal'
) 'proposal template readability review'
Assert-PrdCommandChecksumContract $prdCommand 'fp-prd command'

$collapsedFactBoundary = Replace-Required $prdCommand '`fp-explore`=代码事实；`product-surface-facts`→产品语言' '`fp-explore`/`product-surface-facts`=产品事实' 'the code-fact conversion boundary'
Assert-Condition (-not (Test-PrdCommandChecksumContract $collapsedFactBoundary)) 'mutation survived: raw code facts may be treated as product-language facts'
$surrogateProductDecision = Replace-Required $prdCommand '`fp-prd-grill-me` 独占决策/禁代答' '`fp-prd-grill-me` 协助决策' 'the no-surrogate-answer rule'
Assert-Condition (-not (Test-PrdCommandChecksumContract $surrogateProductDecision)) 'mutation survived: fp-prd-grill-me may answer product decisions by proxy'
$mergedBuckets = Replace-Required $prdCommand 'Bucket A=用户决定/已验证现状/零影响措辞；Bucket B=易撤销展示默认' 'Bucket A/B=用户决定/已验证现状/零影响措辞/易撤销展示默认' 'the disjoint Bucket A/B eligibility rules'
Assert-Condition (-not (Test-PrdCommandChecksumContract $mergedBuckets)) 'mutation survived: Bucket A and Bucket B eligibility may be merged'
$downgradedBucketC = Replace-Required $prdCommand '其余 Bucket C 逐项问，不因数量降级' '其余按影响选择' 'the one-at-a-time no-downgrade rule'
Assert-Condition (-not (Test-PrdCommandChecksumContract $downgradedBucketC)) 'mutation survived: Bucket C items may be downgraded for count'
$missingProductExclusion = Replace-Required $prdCommand '/接口名' '' 'the interface-name product-language exclusion'
Assert-Condition (-not (Test-PrdCommandChecksumContract $missingProductExclusion)) 'mutation survived: an implementation-language exclusion may be removed'
$mutablePrdSchema = Replace-Required $prdCommand '固定六章' '建议六章' 'the fixed six-section PRD schema'
Assert-Condition (-not (Test-PrdCommandChecksumContract $mutablePrdSchema)) 'mutation survived: style normalization may change the fixed six-section PRD schema'
$missingStaticModular = Replace-Required $prdCommand '现有前端默认 `static-modular`' '现有前端选择原型模式' 'the static-modular default'
Assert-Condition (-not (Test-PrdCommandChecksumContract $missingStaticModular)) 'mutation survived: prototype routing may omit static-modular as the existing-frontend default'
$ambiguousPrdDescription = Replace-Required $prdCommand 'description: Use when a user explicitly invokes /fp-prd or $fp-prd, or explicitly asks to create, write, revise, or complete a PRD or product requirements document.' 'description: 生成 PRD' 'the explicit-only public description'
Assert-Condition (-not (Test-PrdCommandChecksumContract $ambiguousPrdDescription)) 'mutation survived: fp-prd discovery metadata may become implicit'
$wrongPrdLoader = Replace-Required $prdCommand '${CLAUDE_PLUGIN_ROOT}/skills/fp-prd/SKILL.md' '${CLAUDE_PLUGIN_ROOT}/skills/fp-start/SKILL.md' 'the exact fp-prd loader'
Assert-Condition (-not (Test-PrdCommandChecksumContract $wrongPrdLoader)) 'mutation survived: fp-prd may load the wrong skill'
$missingPrdArguments = Replace-Required $prdCommand '$ARGUMENTS' '$INPUT' 'the fp-prd command input'
Assert-Condition (-not (Test-PrdCommandChecksumContract $missingPrdArguments)) 'mutation survived: fp-prd may drop its command input'

$startCommandBullets = @(Get-CommandChecksumBullets $startCommand 'fp-start command')
Assert-Condition ($startCommandBullets.Count -eq 8) 'fp-start command must contain exactly eight checksum bullets'
Assert-OrderedAnchors $startCommandBullets[2] @(
    'proposal/design 写门禁后加载共享文档风格契约'
    '禁改确认内容/Decision Ledger/canonical layout'
) 'fp-start Task 3 style checksum bullet'
Assert-OrderedAnchors $startCommandBullets[3] @(
    '模型由 `fp-brainstorm` 核验'
    '真实基类'
    '继承字段'
    '物理存储'
    '约束'
    'migration'
    '评审禁重设计'
) 'fp-start Task 3 model checksum bullet'
$startCommandLineCount = Get-LineCount $startCommand
Assert-Condition ($startCommandLineCount -le 20) "fp-start command exceeds 20 lines: $startCommandLineCount"

$brainstormSkill = Read-Utf8 'skills\fp-brainstorm\SKILL.md'
$designTemplate = Read-Utf8 'skills\fp-brainstorm\design-template.md'
$brainstormTemplatePath = '${CLAUDE_PLUGIN_ROOT}/skills/fp-brainstorm/design-template.md'
$brainstormLoadContract = '读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md`，再读取 `${CLAUDE_PLUGIN_ROOT}/skills/fp-brainstorm/design-template.md`'
Assert-Condition ($brainstormSkill.Contains($brainstormLoadContract)) 'fp-brainstorm does not load document style before its template'
$brainstormStage5Heading = '### 第五步：写入设计文件'
$brainstormStage5Start = $brainstormSkill.IndexOf($brainstormStage5Heading, [System.StringComparison]::Ordinal)
Assert-Condition ($brainstormStage5Start -ge 0) 'fp-brainstorm is missing the design write stage'
Assert-Condition (-not $brainstormSkill.Substring(0, $brainstormStage5Start).Contains($sharedStylePath)) 'fp-brainstorm positively loads document style before the design write stage'
$brainstormStage5 = Get-MarkdownSection $brainstormSkill $brainstormStage5Heading 'fp-brainstorm'
Assert-OrderedAnchors $brainstormStage5 @(
    '每个 design-required decision ID 都是'
    'separate write authorization'
    $sharedStylePath
    $brainstormTemplatePath
) 'fp-brainstorm stage-5 gate/load order'
Assert-Anchors $designTemplate @(
    '## Document readability self-review'
    '先给出架构主线和已确认决策'
    '数据模型的字段定义只由模型代码或完整字段表之一拥有'
    '物理映射、字段/存储取舍、查询/索引映射不重复字段事实'
    '按 fragment manifest 顺序检查完整 logical design'
) 'design template readability review'

function Assert-ReviewJitLoadContract([string]$text, [string]$stylePath, [string]$templatePath, [string]$surface) {
    $step3 = Get-UniqueMarkdownSectionMatch $text '### 第三步：设计充分性检查' $surface
    $step4 = Get-UniqueMarkdownSectionMatch $text '### 第四步：生成 review.md' $surface
    Assert-Condition ($step3.Index -lt $step4.Index) "$surface must place design sufficiency before generation"

    $beforeStep4 = $text.Substring(0, $step4.Index)
    Assert-Condition (-not $beforeStep4.Contains($stylePath)) "$surface loads the shared style contract before Step 4"
    Assert-Condition (-not $beforeStep4.Contains($templatePath)) "$surface loads the review template before Step 4"

    Assert-OrderedAnchors $step4.Groups['body'].Value @(
        '设计充分性检查通过后'
        $stylePath
        $templatePath
        '生成 change 根唯一的 small-form `review.md`'
        '按模板写入 `fp-docs/changes/<slug>/review.md`'
    ) "$surface Step 4 JIT resource order"
}

function Test-ReviewJitLoadContract([string]$text, [string]$stylePath, [string]$templatePath) {
    try {
        Assert-ReviewJitLoadContract $text $stylePath $templatePath 'fp-design-review fixture'
        return $true
    } catch {
        return $false
    }
}

$reviewSkill = Read-Utf8 'skills\fp-design-review\SKILL.md'
$reviewTemplate = Read-Utf8 'skills\fp-design-review\review-template.md'
$reviewStylePath = '${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md'
$reviewTemplatePath = '${CLAUDE_PLUGIN_ROOT}/skills/fp-design-review/review-template.md'
Assert-ReviewJitLoadContract $reviewSkill $reviewStylePath $reviewTemplatePath 'fp-design-review'

$earlyReviewLoad = @'
## 流程

【禁止的提前加载变体】读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md`，再读取 `${CLAUDE_PLUGIN_ROOT}/skills/fp-design-review/review-template.md`。
'@
$earlyLoadMutation = Replace-Required $reviewSkill '## 流程' $earlyReviewLoad 'the review flow heading'
Assert-Condition (-not (Test-ReviewJitLoadContract $earlyLoadMutation $reviewStylePath $reviewTemplatePath)) 'mutation survived: fp-design-review may load style/template before sufficiency passes'

Assert-Anchors $reviewTemplate @(
    '## Document readability self-review'
    '第一段直接给出结果'
    '标题最多三级'
    '复选框只用于验证清单和最终评审结论'
) 'review template readability review'

$validator = Read-Utf8 'scripts\validate-plugin.ps1'
$commandsReference = Read-Utf8 'docs\reference\commands-and-skills.md'

Assert-ValidatorWiringContract $validator 'global validator wiring'

$documentStyleValidatorBlock = @(
    $documentStyleValidatorAssignment
    $documentStyleValidatorExistence
    $documentStyleValidatorInvocation
    $documentStyleValidatorExit
) -join "`n"
$duplicateDocumentStyleWiring = $validator + "`n" + $documentStyleValidatorBlock
Assert-Condition (-not (Test-ValidatorWiringContract $duplicateDocumentStyleWiring)) 'mutation survived: the document-style validator block may be registered twice'

$withoutDesignReviewAssignment = Replace-Required $validator $designReviewValidatorAssignment '' 'the design-review validator assignment'
$outOfOrderValidatorWiring = Replace-Required $withoutDesignReviewAssignment $documentStyleValidatorAssignment ($designReviewValidatorAssignment + "`n" + $documentStyleValidatorAssignment) 'the document-style validator assignment'
Assert-Condition (-not (Test-ValidatorWiringContract $outOfOrderValidatorWiring)) 'mutation survived: focused validators may be registered outside the required order'
Assert-Anchors $commandsReference @(
    'PRD、proposal、design 和 review'
    '共享文档风格契约'
    '独立可读的完整评审文档'
) 'commands and skills reference'

$runtimeSurfaces = @(
    'skills\_shared\document-style.md'
    'skills\fp-prd\SKILL.md'
    'skills\fp-prd\prd-template.md'
    'skills\fp-propose\SKILL.md'
    'skills\fp-propose\proposal-template.md'
    'skills\fp-brainstorm\SKILL.md'
    'skills\fp-brainstorm\design-template.md'
    'skills\fp-design-review\SKILL.md'
    'skills\fp-design-review\review-template.md'
    'commands\fp-prd.md'
    'commands\fp-start.md'
    'commands\fp-design-review.md'
)
$canonicalStyleReferenceSurfaces = @(
    'skills\fp-prd\SKILL.md'
    'skills\fp-prd\prd-template.md'
    'skills\fp-propose\SKILL.md'
    'skills\fp-propose\proposal-template.md'
    'skills\fp-brainstorm\SKILL.md'
    'skills\fp-brainstorm\design-template.md'
    'skills\fp-design-review\SKILL.md'
    'skills\fp-design-review\review-template.md'
)
foreach ($surface in $runtimeSurfaces) {
    $surfaceText = Read-Utf8 $surface
    $requiresCanonicalReference = $canonicalStyleReferenceSurfaces -contains $surface
    Assert-PortableDocumentStyleSurface $surfaceText $surface $requiresCanonicalReference
}

$noncanonicalLoader = Replace-Required $prdSkill $canonicalDocumentStylePath 'skills/_shared/document-style.md' 'the canonical document-style loader'
Assert-Condition (-not (Test-PortableDocumentStyleSurface $noncanonicalLoader $true)) 'mutation survived: document style may load through a noncanonical relative path'
$prefixedCanonicalLoader = Replace-Required $prdSkill $canonicalDocumentStylePath ('/tmp/' + $canonicalDocumentStylePath) 'the canonical document-style loader'
Assert-Condition (-not (Test-PortableDocumentStyleSurface $prefixedCanonicalLoader $true)) 'mutation survived: an embedded canonical substring may masquerade as the canonical loader'
$alternateDriveLoader = Replace-Required $prdSkill $canonicalDocumentStylePath 'E:\Users\writer\document-style-guide\document-style.md' 'the canonical document-style loader'
Assert-Condition (-not (Test-PortableDocumentStyleSurface $alternateDriveLoader $true)) 'mutation survived: document style may load from an alternate drive'
$forwardSlashDriveFixture = 'Read F:/workspace/document-style-guide/rules.txt before writing.'
Assert-Condition (-not (Test-PortableDocumentStyleSurface $forwardSlashDriveFixture $false)) 'mutation survived: a forward-slash drive path may reference document-style-guide'
$uncPathFixture = 'Read \\fileserver\shared\document-style-guide\rules.txt before writing.'
Assert-Condition (-not (Test-PortableDocumentStyleSurface $uncPathFixture $false)) 'mutation survived: a UNC path may reference document-style-guide'
$unixPathFixture = 'Read /opt/writing/document-style-guide/rules.txt before writing.'
Assert-Condition (-not (Test-PortableDocumentStyleSurface $unixPathFixture $false)) 'mutation survived: a Unix-root path may reference document-style-guide'
$homePathFixture = 'Read ~/src/document-style-guide/rules.txt before writing.'
Assert-Condition (-not (Test-PortableDocumentStyleSurface $homePathFixture $false)) 'mutation survived: a home-relative absolute path may reference document-style-guide'
Assert-Condition (Test-PortableDocumentStyleSurface ("Source: $canonicalDocumentStyleAttribution") $false) 'canonical document-style attribution is incorrectly rejected as a runtime dependency'

Write-Output 'Document-style contract validation passed.'
