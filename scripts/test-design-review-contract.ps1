$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "Design-review contract validation failed: $message"
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

function Assert-OrderedAnchors([string]$text, [string[]]$anchors, [string]$surface) {
    $previousIndex = -1
    foreach ($anchor in $anchors) {
        $index = $text.IndexOf($anchor, $previousIndex + 1, [System.StringComparison]::Ordinal)
        Assert-Condition ($index -ge 0) "$surface lost ordered anchor: $anchor"
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

function Assert-ReviewSkillContract([string]$text, [string]$surface) {
    $step2 = Get-UniqueMarkdownSectionMatch $text '### 第二步：确认设计门禁证据并提炼评审素材（只读）' $surface
    $step3 = Get-UniqueMarkdownSectionMatch $text '### 第三步：设计充分性检查' $surface
    $step4 = Get-UniqueMarkdownSectionMatch $text '### 第四步：生成 review.md' $surface
    $boundary = Get-UniqueMarkdownSectionMatch $text '## 边界与恢复' $surface

    Assert-Condition ($step2.Index -lt $step3.Index) "$surface must validate design evidence before sufficiency"
    Assert-Condition ($step3.Index -lt $step4.Index) "$surface must place sufficiency before generation"
    Assert-Condition ($step4.Index -lt $boundary.Index) "$surface must place generation before boundary handling"

    $step2Body = $step2.Groups['body'].Value
    Assert-OrderedAnchors $step2Body @(
        '${CLAUDE_PLUGIN_ROOT}/skills/_shared/decision-ledger.md'
        '每个 actual-end 的 unique detailed owner'
        'Decision Ledger'
        '精确表头'
        'concrete Source 与 Evidence'
        'Status 必须属于既定终态'
        'placeholder'
        'Pre-write Confirmation Evidence'
        '`Covered IDs` 必须与该 owner 的台账 ID 集合完全相等'
        '`Outstanding blocking decisions` 必须为 `none`'
        'Explicit user authorization to write'
        'globally unique D-NNN sequence'
        '门禁证据无效时不得生成、覆盖或删除 `review.md`'
        '保留任何已有 `review.md`'
        '返回 `fp-brainstorm`'
    ) "$surface Step 2 design evidence gate"
    Assert-Condition ($step2Body.Contains('Status 必须属于既定终态')) "$surface allows nonterminal design decisions"
    Assert-Condition ($step2Body.Contains('Source、Evidence 和授权不得包含 `placeholder`、`TBD`、`TODO`、`unknown`')) "$surface lost the placeholder rejection clause"
    Assert-Condition ($step2Body.Contains('`Outstanding blocking decisions` 必须为 `none`')) "$surface lost the exact no-outstanding-decisions clause"
    Assert-Condition ($step2Body.Contains('必须包含 concrete `Explicit user authorization to write`')) "$surface lost the positive explicit-authorization clause"
    Assert-Condition ($step2Body.Contains('门禁证据无效时不得生成、覆盖或删除 `review.md`，必须保留任何已有 `review.md`')) "$surface lost evidence-failure preservation"

    $step3Body = $step3.Groups['body'].Value
    Assert-OrderedAnchors $step3Body @(
        '生成前'
        '每个 actual-end 的 resolved logical design'
        '设计范围适用性'
        '架构主线、核心对象与职责、具体风险或有证据的无风险结论、验证方案属于必填范围'
        '数据模型、状态/并发、接口/权限/兼容和前端属于条件范围'
        '标记不适用时 owner 为 `N/A`'
        '由 inventory 行提供证据化理由'
        '每个 owner 只提供其范围事实'
        '不得为满足评审结构跨范围复制内容'
        '架构主线的触发、处理、状态变化、结果和失败收束'
        '核心对象的职责、非职责、协作关系和 design 锚点'
        '状态入口、并发控制、执行顺序、失败恢复和可观察结果'
        '接口资源与标识、权限、新旧入口的兼容或隔离边界'
        '前端页面、组件、状态、路由、视觉来源和可执行 Visual Checks'
        '具体失败场景与影响，以及已确认的迁移、发布、回滚、监控和验证安排'
        '数据模型范围至少包含：'
        '完整字段定义或接近实现的模型代码'
        '字段与存储取舍理由'
        '查询模式与索引映射'
        '继承字段和重复存储结论'
        '逻辑模型与物理表映射'
        '关联、索引、唯一约束和软删除规则'
        '项目规范证据'
        'migration 影响'
    ) "$surface Step 3 applicable/model scope"

    $insufficiencyContract = '若适用信息不足，不生成或覆盖 `review.md`。输出“无法生成 review.md”、逐项缺失内容、需要修订的精确 design 章节，以及“返回 `fp-brainstorm` 做定点修订并重新确认设计”。不得只写“设计不完整”或“请补充信息”，不得重新扫描代码库、修改设计或自行补齐字段。'
    Assert-Condition ($step3Body.Contains($insufficiencyContract)) "$surface Step 3 lost the exact insufficiency response"

    $step4Body = $step4.Groups['body'].Value
    Assert-OrderedAnchors $step4Body @(
        '设计充分性检查通过后'
        '${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md'
        '${CLAUDE_PLUGIN_ROOT}/skills/fp-design-review/review-template.md'
        '生成 change 根唯一的 small-form `review.md`'
        '按模板写入 `fp-docs/changes/<slug>/review.md`'
        '生成成功后报告实际 `review.md` 路径'
        '展示评审结论、业务和技术主线、主要风险与建议评审顺序'
    ) "$surface Step 4 generation order"
    Assert-Condition ($step4Body.Contains('不得复制台账行或机械复制叙述性设计正文')) "$surface lost the narrative no-copy boundary"
    Assert-Condition ($step4Body.Contains('模型代码或完整字段定义表可以从 canonical design 精确摘录一种')) "$surface lost the authorized exact field-carrier excerpt"
    Assert-Condition (-not $step4Body.Contains('不得复制决策正文或设计正文')) "$surface retains a blanket no-copy rule that contradicts exact excerpts"

    $boundaryBody = $boundary.Groups['body'].Value
    Assert-OrderedAnchors $boundaryBody @(
        '幂等刷新只在设计充分性检查通过后成立'
        '设计充分性检查失败时必须保留任何已有 `review.md`'
        '不得写入或覆盖部分评审'
    ) "$surface insufficiency preservation/no-partial-output path"
    Assert-OrderedAnchors $boundaryBody @(
        '若发现 `review.md`'
        '超出 500 lines / 30,000 characters'
        '则不得交付'
        '重新生成'
    ) "$surface post-generation limit rejection"
}

function Test-ReviewSkillContract([string]$text) {
    try {
        Assert-ReviewSkillContract $text 'review skill fixture'
        return $true
    } catch {
        return $false
    }
}

function Get-InnerReviewOutput([string]$text, [string]$surface) {
    $openCount = [regex]::Matches($text, '(?m)^````markdown[ \t]*\r?$').Count
    $closeCount = [regex]::Matches($text, '(?m)^````[ \t]*\r?$').Count
    Assert-Condition ($openCount -eq 1) "$surface must have exactly one four-backtick markdown opener; found $openCount"
    Assert-Condition ($closeCount -eq 1) "$surface must have exactly one four-backtick closer; found $closeCount"

    $blocks = @([regex]::Matches($text, '(?ms)^````markdown[ \t]*\r?\n(?<body>.*?)\r?\n^````[ \t]*\r?$'))
    Assert-Condition ($blocks.Count -eq 1) "$surface must contain one intact four-backtick output block"
    return $blocks[0].Groups['body'].Value
}

function Assert-ReviewTemplateContract([string]$text, [string]$surface) {
    $inner = Get-InnerReviewOutput $text $surface
    Assert-Condition ($text.Contains('Never omit the opening conclusion, business/technical mainline, core-object responsibilities, risks and validation')) "$surface allows mandatory global review sections to be omitted"
    $expectedHeadings = @(
        '## 评审结论'
        '## 业务和技术主线'
        '## 核心对象与职责'
        '## 数据模型评审'
        '### 接近实现的模型代码'
        '### 完整字段定义'
        '### 物理存储、继承与重复存储'
        '### 字段与存储取舍'
        '### 查询模式与索引映射、约束与迁移'
        '## 状态、并发和执行流程'
        '## 接口、权限和旧入口隔离'
        '## 前端方案'
        '## 主要风险、迁移、发布和验证'
        '### 主要风险'
        '### 迁移与发布'
        '### 验证清单'
        '## 评审顺序与抽查路径'
        '## 评审结论记录'
        '## 设计入口'
    )
    $actualHeadings = @([regex]::Matches($inner, '(?m)^#{2,3}[ \t]+[^\r\n]+\r?$') | ForEach-Object { $_.Value.Trim() })
    Assert-Condition ($actualHeadings.Count -eq $expectedHeadings.Count) "$surface has the wrong number of H2/H3 headings"
    for ($index = 0; $index -lt $expectedHeadings.Count; $index++) {
        Assert-Condition ($actualHeadings[$index] -ceq $expectedHeadings[$index]) "$surface heading order changed at position $($index + 1): expected $($expectedHeadings[$index]); found $($actualHeadings[$index])"
    }

    $innerFenceOpen = @([regex]::Matches($inner, '(?m)^```text[ \t]*\r?$'))
    $innerFenceClose = @([regex]::Matches($inner, '(?m)^```[ \t]*\r?$'))
    Assert-Condition ($innerFenceOpen.Count -eq 1) "$surface must preserve one inner triple-backtick model-code opener"
    Assert-Condition ($innerFenceClose.Count -eq 1) "$surface must preserve one inner triple-backtick model-code closer"
    Assert-Condition ($innerFenceOpen[0].Index -lt $innerFenceClose[0].Index) "$surface inner model-code fence is inverted"

    Assert-Condition ($text.Contains('数据模型适用时，只生成一种字段定义表示：canonical design 含接近实现的模型代码时精确摘录代码并省略“完整字段定义”；否则使用已确认的完整字段定义表并省略代码小节。不得从字段表推导或编造模型代码。')) "$surface lost the code-or-field-table rendering contract"
    Assert-Condition ($inner.Contains('| 字段 | 类型 | 必填/空值 | 默认值 | 关联/约束 | 设计依据 |')) "$surface lost the complete-field-definition alternative"
    $physicalHeader = '| 逻辑对象 | 物理表/存储 | 继承字段来源 | 主键与关联键 | 重复存储结论 |'
    Assert-Condition ($inner.Contains($physicalHeader)) "$surface lost the non-duplicating physical-storage table"
    Assert-Condition (-not $inner.Contains('| 逻辑对象 | 物理表/存储 | 显式字段 |')) "$surface physical mapping table repeats explicit field definitions"
    Assert-Condition ($inner.Contains('字段或存储选择')) "$surface lost field/storage choice rationale"
    Assert-Condition ($inner.Contains('查询模式与索引映射')) "$surface lost query-to-index review evidence"

    $validation = Get-UniqueMarkdownSectionMatch $inner '### 验证清单' $surface
    $verdict = Get-UniqueMarkdownSectionMatch $inner '## 评审结论记录' $surface
    $validationCheckboxes = @([regex]::Matches($validation.Groups['body'].Value, '(?m)^[ \t]*-[ \t]+\[[ xX]\][^\r\n]*\r?$'))
    $verdictCheckboxes = @([regex]::Matches($verdict.Groups['body'].Value, '(?m)^[ \t]*-[ \t]+\[[ xX]\][^\r\n]*\r?$'))
    $allCheckboxes = @([regex]::Matches($inner, '(?m)^[ \t]*-[ \t]+\[[ xX]\][^\r\n]*\r?$'))
    Assert-Condition ($validationCheckboxes.Count -ge 1) "$surface must include a validation checkbox"
    Assert-Condition ([regex]::Matches($validation.Groups['body'].Value, '(?m)^- \[ \] <可执行命令、测试或人工检查；写出预期结果和 design 锚点。>\r?$').Count -eq 1) "$surface lost the required validation checkbox syntax"
    Assert-Condition ([regex]::Matches($verdict.Groups['body'].Value, '(?m)^- \[ \] 通过：').Count -eq 1) "$surface lost the pass verdict checkbox"
    Assert-Condition ([regex]::Matches($verdict.Groups['body'].Value, '(?m)^- \[ \] 有条件通过：').Count -eq 1) "$surface lost the conditional-pass verdict checkbox"
    Assert-Condition ([regex]::Matches($verdict.Groups['body'].Value, '(?m)^- \[ \] 退回修改：').Count -eq 1) "$surface lost the return-for-revision verdict checkbox"
    Assert-Condition ($verdictCheckboxes.Count -eq 3) "$surface must contain exactly three final-verdict checkboxes"
    Assert-Condition ($allCheckboxes.Count -eq ($validationCheckboxes.Count + $verdictCheckboxes.Count)) "$surface has a checkbox outside 验证清单 or 评审结论记录"

    $allDesignEntryHeadings = [regex]::Matches($inner, '(?m)^#{2,6}[ \t]+[^\r\n]*设计入口[^\r\n]*\r?$').Count
    Assert-Condition ($allDesignEntryHeadings -eq 1) "$surface must have exactly one design-entry heading at any level"
    Assert-Condition ([regex]::Matches($inner, '(?m)^## 设计入口[ \t]*\r?$').Count -eq 1) "$surface design entry must be one H2 section"
    $designEntry = Get-UniqueMarkdownSectionMatch $inner '## 设计入口' $surface
    $designEntryLines = @($designEntry.Groups['body'].Value -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 })
    Assert-Condition ($designEntryLines.Count -eq 1) "$surface design entry must contain exactly one line"
    Assert-Condition ($designEntryLines[0] -ceq '- `design/00-index.md`') "$surface design entry must point only to design/00-index.md"
    $designPaths = @([regex]::Matches($inner, 'design/[A-Za-z0-9._/-]+') | ForEach-Object { $_.Value })
    Assert-Condition ($designPaths.Count -eq 1) "$surface must contain exactly one design path"
    Assert-Condition ($designPaths[0] -ceq 'design/00-index.md') "$surface contains an alternate design-entry path"

    $limitContract = 'The complete file must remain within 500 lines and 30,000 characters. If deduplication and links cannot keep it within both limits, block instead of truncating because `review.md` has no split form.'
    Assert-Condition ($text.Contains($limitContract)) "$surface lost the bounded complete-file/no-split/block-instead-of-truncate contract"
    Assert-Condition ($text.Contains('复选框只用于验证清单和最终评审结论')) "$surface lost the checkbox restriction"
    Assert-Condition ($text.Contains('不得复制 Decision Ledger rows')) "$surface may copy Decision Ledger rows"
    Assert-Condition ($text.Contains('不得自行补充字段')) "$surface may invent model fields"
    Assert-Condition ((Get-LineCount $text) -le 500) "$surface source exceeds 500 lines"
    Assert-Condition ($text.Length -le 30000) "$surface source exceeds 30,000 characters"
}

function Test-ReviewTemplateContract([string]$text) {
    try {
        Assert-ReviewTemplateContract $text 'review template fixture'
        return $true
    } catch {
        return $false
    }
}

function Assert-DesignProducerCoverageContract([string]$text, [string]$surface) {
    Assert-Anchors $text @(
        '### 设计范围适用性'
        '| 评审范围 | 要求 | Canonical owner section | 证据或不适用理由 |'
        '必填范围必须有 canonical owner 和证据'
        '条件适用范围只有标记为适用时才需要 owner section'
        '条件范围不适用时，owner 写 `N/A`'
        '### 架构主线'
        '### 核心对象与职责'
        '| 对象/模块 | 职责 | 不负责 | 协作对象 | 证据 |'
        '### 状态、并发与执行流程'
        '### 接口、权限与兼容边界'
        '### 风险、迁移、发布、回滚与监控'
        '### 验证方案'
        '数据模型适用时，字段定义只使用一种 canonical carrier'
        '#### 完整字段定义'
        '| 字段 | 类型 | 必填/空值 | 默认值 | 关联/约束 | 证据 |'
        '使用本表时省略代码小节，不得从字段表反推代码'
        '#### 字段与存储取舍'
        '#### 查询模式与索引映射'
        '| 查询模式 | 过滤/排序/关联字段 | 对应索引或访问路径 | 选择理由 | 证据 |'
    ) "$surface producer slots"

    $mandatoryOwners = [ordered]@{
        '架构主线' = '`#架构主线`'
        '核心对象与职责' = '`#核心对象与职责`'
        '风险、迁移、发布、回滚与监控' = '`#风险迁移发布回滚与监控`'
        '验证方案' = '`#验证方案`'
    }
    foreach ($entry in $mandatoryOwners.GetEnumerator()) {
        $pattern = '(?m)^\| ' + [regex]::Escape($entry.Key) + ' \| 必填 \| ' + [regex]::Escape($entry.Value) + ' \|'
        Assert-Condition ([regex]::Matches($text, $pattern).Count -eq 1) "$surface mandatory scope must have exactly one concrete owner: $($entry.Key)"
    }
    foreach ($scope in @('数据模型', '状态、并发与执行流程', '接口、权限与兼容边界', '前端方案')) {
        Assert-Condition ([regex]::Matches($text, '(?m)^\| ' + [regex]::Escape($scope) + ' \| 条件适用 \|').Count -eq 1) "$surface conditional scope must have exactly one row: $scope"
    }

    $completeFieldHeader = '| 字段 | 类型 | 必填/空值 | 默认值 | 关联/约束 | 证据 |'
    Assert-Condition ($text.Contains($completeFieldHeader)) "$surface complete-field table lost its definition-only schema"
    Assert-Condition (-not $text.Contains('| 字段 | 类型 | 必填/空值 | 默认值 | 关联/约束 | 选择理由 |')) "$surface complete-field table duplicates choice rationale"
}

function Test-DesignProducerCoverageContract([string]$text) {
    try {
        Assert-DesignProducerCoverageContract $text 'design producer fixture'
        return $true
    } catch {
        return $false
    }
}

function Assert-FpStartHandoffContract([string]$text, [string]$surface) {
    $postWrite = Get-UniqueMarkdownSectionMatch $text '### Post-write artifact confirmation' $surface
    $phase3Heading = '## 阶段 3：生成执行计划'
    $phase3Matches = @([regex]::Matches($text, '(?m)^' + [regex]::Escape($phase3Heading) + '[ \t]*\r?$'))
    Assert-Condition ($phase3Matches.Count -eq 1) "$surface must contain exactly one phase-3 heading"
    Assert-Condition ($postWrite.Index -lt $phase3Matches[0].Index) "$surface phase 3 must follow post-write confirmation"

    Assert-OrderedAnchors $postWrite.Groups['body'].Value @(
        '用工具确认 `design/00-index.md`'
        '解析 Decision Ledger 与 Pre-write Confirmation Evidence'
        'globally unique D-NNN sequence'
        '`Covered IDs` 恰好覆盖其台账行'
        '证据门禁全部通过后，才加载 `${CLAUDE_PLUGIN_ROOT}/skills/fp-design-review/SKILL.md`'
        '展示评审结论、业务和技术主线、主要风险、建议评审顺序与入口路径'
        '设计充分性检查失败时'
        '按其缺失清单返回 `fp-brainstorm` 定点修订并重新确认'
        '`fp-start` 和 `fp-design-review` 都不得编造缺失设计'
        '明确询问用户是否确认设计'
        '等待用户确认设计后'
        '然后才进入阶段 3'
    ) "$surface post-write handoff order"
}

function Assert-CommandChecksumContract([string]$text, [string]$surface) {
    Assert-Condition ($text.Contains('description: 从已确认设计生成开发设计评审入口 review.md')) "$surface lost its public purpose"
    Assert-Condition ($text.Contains('`${CLAUDE_PLUGIN_ROOT}/skills/fp-design-review/SKILL.md`')) "$surface lost its exact skill loader"
    Assert-Condition ($text.Contains('$ARGUMENTS')) "$surface no longer passes the slug input"

    $checksumMatches = @([regex]::Matches($text, '(?ms)^Gate checksum：[ \t]*\r?\n(?<body>.*)\z'))
    Assert-Condition ($checksumMatches.Count -eq 1) "$surface must contain exactly one Gate checksum section"
    $bullets = @([regex]::Matches($checksumMatches[0].Groups['body'].Value, '(?m)^-[ \t]+(?<text>[^\r\n]+)\r?$') | ForEach-Object { $_.Groups['text'].Value })
    Assert-Condition ($bullets.Count -eq 4) "$surface must contain exactly four checksum bullets"

    Assert-Anchors $bullets[0] @(
        '仅消费 canonical design'
        'dual form/historical path'
        '台账非终态'
        '凭据无效'
        '设计不足'
        '设计不足阻塞'
        '保留 review.md'
        '返回 `fp-brainstorm`'
    ) "$surface checksum bullet 1"
    Assert-Anchors $bullets[1] @(
        '只写 change根 review.md'
        'small form覆盖全端'
        '独立可读的完整评审文档'
        '不复制台账/叙述正文'
        '字段载体仅精确摘录一种'
        '不编造'
    ) "$surface checksum bullet 2"
    Assert-Anchors $bullets[2] @(
        '充分性通过后'
        '共享文档风格契约'
        'review模板'
        '结论/主线优先'
        '复选框仅验证/最终结论'
    ) "$surface checksum bullet 3"
    Assert-Anchors $bullets[3] @(
        '成功后报告 review.md 路径'
        '结论/主线/风险/评审顺序'
        '不改设计'
        'Decision Ledger/台账状态'
        '不推进阶段'
    ) "$surface checksum bullet 4"
    Assert-Condition ((Get-LineCount $text) -le 20) "$surface exceeds 20 lines"
}

function Test-CommandChecksumContract([string]$text) {
    try {
        Assert-CommandChecksumContract $text 'fp-design-review command fixture'
        return $true
    } catch {
        return $false
    }
}

$brainstorm = Read-Utf8 'skills\fp-brainstorm\SKILL.md'
$designTemplate = Read-Utf8 'skills\fp-brainstorm\design-template.md'
$reviewSkill = Read-Utf8 'skills\fp-design-review\SKILL.md'
$reviewTemplate = Read-Utf8 'skills\fp-design-review\review-template.md'
$startSkill = Read-Utf8 'skills\fp-start\SKILL.md'
$command = Read-Utf8 'commands\fp-design-review.md'

Assert-Anchors $brainstorm @(
    '项目模型规范调查'
    '逻辑模型与实际物理表'
    '软删除后的唯一性含义'
    'Django 条件化检查'
    '不得擅自统一选择'
) 'fp-brainstorm'
Assert-Anchors $designTemplate @(
    '接近实现的模型代码'
    '继承字段与重复存储结论'
    'Migration 影响'
) 'design template'
Assert-DesignProducerCoverageContract $designTemplate 'design template'

Assert-ReviewSkillContract $reviewSkill 'fp-design-review skill'
Assert-ReviewTemplateContract $reviewTemplate 'review template'
Assert-FpStartHandoffContract $startSkill 'fp-start'
Assert-CommandChecksumContract $command 'fp-design-review command'

$dependentReviewSummary = Replace-Required $command '独立可读的完整评审文档' '完整评审文档' 'the independently readable review requirement'
Assert-Condition (-not (Test-CommandChecksumContract $dependentReviewSummary)) 'mutation survived: review.md may become a design-dependent summary'

$invertedInsufficiency = Replace-Required $reviewSkill '若适用信息不足' '若适用信息充足' 'the insufficiency condition'
Assert-Condition (-not (Test-ReviewSkillContract $invertedInsufficiency)) 'mutation survived: an inverted sufficiency condition is accepted'
$removedApplicableScope = Replace-Required $reviewSkill '前端页面、组件、状态、路由、视觉来源和可执行 Visual Checks' '前端范围' 'an applicable-scope item'
Assert-Condition (-not (Test-ReviewSkillContract $removedApplicableScope)) 'mutation survived: an applicable-scope item may be removed'
$removedPreservation = Replace-Required $reviewSkill '设计充分性检查失败时必须保留任何已有 `review.md`' '设计充分性检查失败时可以删除任何已有 `review.md`' 'existing review preservation'
Assert-Condition (-not (Test-ReviewSkillContract $removedPreservation)) 'mutation survived: insufficiency may delete an existing review.md'
$allowedPartialOutput = Replace-Required $reviewSkill '不得写入或覆盖部分评审' '可以写入或覆盖部分评审' 'the no-partial-output rule'
Assert-Condition (-not (Test-ReviewSkillContract $allowedPartialOutput)) 'mutation survived: insufficiency may write a partial review.md'

$outOfScopeCheckbox = Replace-Required $reviewTemplate '<按触发、处理、状态变化、结果与失败收束说明完整主线；只提炼设计已有内容。>' '- [ ] 不应出现在业务和技术主线中的复选框。' 'the business-mainline placeholder'
Assert-Condition (-not (Test-ReviewTemplateContract $outOfScopeCheckbox)) 'mutation survived: a checkbox may appear outside validation or final verdict'
$mandatoryCoreOmitted = Replace-Required $reviewTemplate 'core-object responsibilities' 'optional core-object details' 'the mandatory core-object section'
Assert-Condition (-not (Test-ReviewTemplateContract $mandatoryCoreOmitted)) 'mutation survived: mandatory core-object responsibilities may be omitted'
$duplicateDesignEntry = Replace-Required $reviewTemplate '- `design/00-index.md`' "- ``design/00-index.md```r`n- ``design/backend.md``" 'the unique design entry'
Assert-Condition (-not (Test-ReviewTemplateContract $duplicateDesignEntry)) 'mutation survived: duplicate or alternate design entries are accepted'
$weakenedLimit = Replace-Required $reviewTemplate 'The complete file must remain within 500 lines and 30,000 characters.' 'The complete file may remain within 500 lines and 30,000 characters.' 'the mandatory output limit'
Assert-Condition (-not (Test-ReviewTemplateContract $weakenedLimit)) 'mutation survived: output limits may be optional'
$truncateAllowed = Replace-Required $reviewTemplate 'block instead of truncating' 'truncate instead of blocking' 'the block-instead-of-truncate rule'
Assert-Condition (-not (Test-ReviewTemplateContract $truncateAllowed)) 'mutation survived: oversized review output may be truncated'

$missingAuthorizationGate = Replace-Required $reviewSkill 'Explicit user authorization to write' 'write authorization if present' 'the explicit design authorization gate'
Assert-Condition (-not (Test-ReviewSkillContract $missingAuthorizationGate)) 'mutation survived: review may consume a design without explicit write authorization'
$mismatchedCoveredIdsGate = Replace-Required $reviewSkill '`Covered IDs` 必须与该 owner 的台账 ID 集合完全相等' '`Covered IDs` 仅供参考' 'the exact Covered IDs gate'
Assert-Condition (-not (Test-ReviewSkillContract $mismatchedCoveredIdsGate)) 'mutation survived: review may consume mismatched Covered IDs'
$duplicateIdsGate = Replace-Required $reviewSkill '所有 owner 合并后必须保持 globally unique D-NNN sequence' '各 owner 分别编号' 'the cross-owner unique-ID gate'
Assert-Condition (-not (Test-ReviewSkillContract $duplicateIdsGate)) 'mutation survived: review may consume duplicate cross-owner decision IDs'
$outstandingGate = Replace-Required $reviewSkill '`Outstanding blocking decisions` 必须为 `none`' '`Outstanding blocking decisions` 可以不是 `none`' 'the no-outstanding-decisions gate'
Assert-Condition (-not (Test-ReviewSkillContract $outstandingGate)) 'mutation survived: review may consume outstanding decisions'
$placeholderGate = Replace-Required $reviewSkill '`placeholder`、`TBD`、`TODO`、`unknown`' '`TBD`' 'the placeholder rejection set'
Assert-Condition (-not (Test-ReviewSkillContract $placeholderGate)) 'mutation survived: review may consume placeholder confirmation evidence'
$authorizationInversion = Replace-Required $reviewSkill '必须包含 concrete `Explicit user authorization to write`' '无需包含 concrete `Explicit user authorization to write`' 'the positive authorization requirement'
Assert-Condition (-not (Test-ReviewSkillContract $authorizationInversion)) 'mutation survived: explicit design authorization may be optional'
$placeholderPermission = Replace-Required $reviewSkill 'Source、Evidence 和授权不得包含 `placeholder`' 'Source、Evidence 和授权可以包含 `placeholder`' 'the placeholder prohibition'
Assert-Condition (-not (Test-ReviewSkillContract $placeholderPermission)) 'mutation survived: placeholder evidence may be permitted'
$nonterminalPermission = Replace-Required $reviewSkill 'Status 必须属于既定终态' 'Status 可以不属于既定终态' 'the terminal-status requirement'
Assert-Condition (-not (Test-ReviewSkillContract $nonterminalPermission)) 'mutation survived: nonterminal design rows may be accepted'
$evidenceFailureDeletesReview = Replace-Required $reviewSkill '门禁证据无效时不得生成、覆盖或删除 `review.md`，必须保留任何已有 `review.md`' '门禁证据无效时可以覆盖或删除 `review.md`' 'the evidence-failure preservation rule'
Assert-Condition (-not (Test-ReviewSkillContract $evidenceFailureDeletesReview)) 'mutation survived: invalid evidence may delete or overwrite review.md'

$missingApplicabilityScope = Replace-Required $designTemplate '| 状态、并发与执行流程 |' '| 状态流程 |' 'the state/concurrency applicability row'
Assert-Condition (-not (Test-DesignProducerCoverageContract $missingApplicabilityScope)) 'mutation survived: a review scope may have no producer applicability owner'
$missingValidationOwner = Replace-Required $designTemplate '### 验证方案' '### 验证备注' 'the executable validation owner'
Assert-Condition (-not (Test-DesignProducerCoverageContract $missingValidationOwner)) 'mutation survived: executable validation may have no canonical producer slot'
$mandatoryScopeMadeConditional = Replace-Required $designTemplate '| 架构主线 | 必填 |' '| 架构主线 | 条件适用 |' 'the mandatory architecture scope'
Assert-Condition (-not (Test-DesignProducerCoverageContract $mandatoryScopeMadeConditional)) 'mutation survived: architecture mainline may be marked inapplicable'
$requiredOwnerRemoved = Replace-Required $designTemplate '| 验证方案 | 必填 | `#验证方案` |' '| 验证方案 | 必填 | `N/A` |' 'the required validation owner'
Assert-Condition (-not (Test-DesignProducerCoverageContract $requiredOwnerRemoved)) 'mutation survived: a mandatory scope may use an N/A owner'
$conditionalOwnerRuleRemoved = Replace-Required $designTemplate '条件范围不适用时，owner 写 `N/A`' '条件范围始终省略 owner' 'the conditional owner rule'
Assert-Condition (-not (Test-DesignProducerCoverageContract $conditionalOwnerRuleRemoved)) 'mutation survived: conditional scope applicability may not own its N/A reason'
$producerFieldAlternativeRemoved = Replace-Required $designTemplate '#### 完整字段定义' '#### 字段摘要' 'the producer complete-field alternative'
Assert-Condition (-not (Test-DesignProducerCoverageContract $producerFieldAlternativeRemoved)) 'mutation survived: the producer may omit the table-only field representation'
$producerInferenceAllowed = Replace-Required $designTemplate '不得从字段表反推代码' '可以从字段表反推代码' 'the producer no-inference rule'
Assert-Condition (-not (Test-DesignProducerCoverageContract $producerInferenceAllowed)) 'mutation survived: the producer may infer code from a field table'
$producerDuplicateRationale = Replace-Required $designTemplate '| 字段 | 类型 | 必填/空值 | 默认值 | 关联/约束 | 证据 |' '| 字段 | 类型 | 必填/空值 | 默认值 | 关联/约束 | 选择理由 | 证据 |' 'the definition-only complete-field schema'
Assert-Condition (-not (Test-DesignProducerCoverageContract $producerDuplicateRationale)) 'mutation survived: complete-field and choice tables may both own rationale'

$missingFieldAlternative = Replace-Required $reviewTemplate '### 完整字段定义' '### 字段摘要' 'the complete-field-definition alternative'
Assert-Condition (-not (Test-ReviewTemplateContract $missingFieldAlternative)) 'mutation survived: table-only canonical designs cannot render review output'
$inventedCodeAllowed = Replace-Required $reviewTemplate '不得从字段表推导或编造模型代码。' '可以从字段表推导模型代码。' 'the no-invented-code rule'
Assert-Condition (-not (Test-ReviewTemplateContract $inventedCodeAllowed)) 'mutation survived: table-only model facts may be converted into invented code'
$blanketNoCopy = Replace-Required $reviewSkill '不得复制台账行或机械复制叙述性设计正文。只有 review template 授权的模型代码或完整字段定义表可以从 canonical design 精确摘录一种' '不得复制决策正文或设计正文' 'the exact-excerpt exception to narrative no-copy'
Assert-Condition (-not (Test-ReviewSkillContract $blanketNoCopy)) 'mutation survived: a blanket no-copy rule may prohibit required exact field excerpts'
$commandForbidsFieldExcerpt = Replace-Required $command '字段载体仅精确摘录一种' '不复制任何字段载体' 'the command field-carrier excerpt exception'
Assert-Condition (-not (Test-CommandChecksumContract $commandForbidsFieldExcerpt)) 'mutation survived: the command may forbid every exact field excerpt'
$duplicatedExplicitFields = Replace-Required $reviewTemplate '| 逻辑对象 | 物理表/存储 | 继承字段来源 | 主键与关联键 | 重复存储结论 |' '| 逻辑对象 | 物理表/存储 | 显式字段 | 继承字段来源 | 主键与关联键 | 重复存储结论 |' 'the non-duplicating physical table'
Assert-Condition (-not (Test-ReviewTemplateContract $duplicatedExplicitFields)) 'mutation survived: physical mapping may duplicate explicit field definitions'
$queryEvidenceRemoved = Replace-Required $reviewTemplate '查询模式与索引映射' '索引列表' 'the query-to-index evidence section'
Assert-Condition (-not (Test-ReviewTemplateContract $queryEvidenceRemoved)) 'mutation survived: review may omit query-to-index evidence'

$missingPublicPurpose = Replace-Required $command 'description: 从已确认设计生成开发设计评审入口 review.md' 'description: 生成评审' 'the public command purpose'
Assert-Condition (-not (Test-CommandChecksumContract $missingPublicPurpose)) 'mutation survived: design-review public metadata may become ambiguous'
$wrongReviewLoader = Replace-Required $command '${CLAUDE_PLUGIN_ROOT}/skills/fp-design-review/SKILL.md' '${CLAUDE_PLUGIN_ROOT}/skills/fp-start/SKILL.md' 'the exact design-review loader'
Assert-Condition (-not (Test-CommandChecksumContract $wrongReviewLoader)) 'mutation survived: fp-design-review may load the wrong skill'
$missingReviewArguments = Replace-Required $command '$ARGUMENTS' '$INPUT' 'the review slug input'
Assert-Condition (-not (Test-CommandChecksumContract $missingReviewArguments)) 'mutation survived: fp-design-review may drop the slug input'
$missingStructuralBlockers = Replace-Required $command 'dual form/historical path' '结构问题' 'the structural blocker checksum'
Assert-Condition (-not (Test-CommandChecksumContract $missingStructuralBlockers)) 'mutation survived: dual/historical design blockers may disappear from the command'
$missingCompletionReport = Replace-Required $command '成功后报告 review.md 路径' '成功后结束' 'the standalone completion report'
Assert-Condition (-not (Test-CommandChecksumContract $missingCompletionReport)) 'mutation survived: standalone review may omit its actual output path'

Write-Output 'Design-review contract validation passed.'
