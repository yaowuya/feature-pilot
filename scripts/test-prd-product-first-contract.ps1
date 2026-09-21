$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "PRD product-first contract validation failed: $message"
    }
}

function Read-Utf8([string]$relativePath) {
    return [System.IO.File]::ReadAllText((Join-Path $root $relativePath), [System.Text.Encoding]::UTF8)
}

function Assert-Anchors([string]$text, [string[]]$anchors, [string]$surface) {
    foreach ($anchor in $anchors) {
        Assert-Condition ($text.Contains($anchor)) "$surface lost anchor: $anchor"
    }
}

function Test-UiHeavyAutoPrototype([string]$text) {
    $plain = [regex]::Replace($text, '[`*_]', '')
    # Mask only the negations that govern the same clause, so an unrelated
    # trailing negative sentence cannot hide an affirmative routing rule.
    $negated = '(?i)(?:does\s+not|do\s+not|never|not\s+by\s+itself|only\s+(?:recommend|makes?))[^;.!?。；！？]{0,80}'
    $negatedCn = '(?:不自动|不会自动|只(?:用于|作)推荐|只推荐|只会推荐|仅推荐|不直接)[^;.!?。；！？]{0,80}'
    $masked = [regex]::Replace($plain, $negated, ' NEGATED_UIHEAVY ')
    $masked = [regex]::Replace($masked, $negatedCn, ' NEGATED_UIHEAVY ')
    foreach ($clause in [regex]::Split($masked, '(?:\r?\n|[;.!?。；！？])')) {
        if ($clause -notmatch '(?i)UI-heavy|UI heavy') { continue }
        if ($clause -match '(?i)(?:use|run|enter|select|switch\s+to|triggers?|activates?)\b[^,]{0,60}(?:prototype-first|prototype\s+first|原型)') { return $true }
        if ($clause -match '(?i)(?:prototype-first|prototype\s+first)[^,]{0,60}\bwhen\b[^,]{0,60}UI-heavy') { return $true }
        if ($clause -match 'UI-heavy[^,]{0,40}(?:直接|自动|立即)[^,]{0,20}(?:进入|使用|采用|切换到|触发)') { return $true }
        if ($clause -match '(?:直接|自动|立即)[^,]{0,20}(?:进入|使用|采用|切换到|触发)[^,]{0,40}(?:prototype-first|原型优先)') { return $true }
        if ($clause -match 'UI-heavy[^,]{0,20}(?:时|则)?[^,]{0,20}(?:使用|采用|进入|切换到|触发|走|启用)[^,]{0,20}(?:prototype-first|原型优先|原型)') { return $true }
        if ($clause -match '(?:使用|采用|进入|切换到|触发|走|启用)[^,]{0,20}(?:prototype-first|原型优先)[^,]{0,40}UI-heavy') { return $true }
    }
    return $false
}

$skill = Read-Utf8 'skills\fp-prd\SKILL.md'
$grill = Read-Utf8 'skills\fp-prd-grill-me\SKILL.md'
$template = Read-Utf8 'skills\fp-prd\prd-template.md'
$explore = Read-Utf8 'skills\fp-explore\SKILL.md'
$prototypeContract = Read-Utf8 'skills\_shared\prototype-contract.md'
$command = Read-Utf8 'commands\fp-prd.md'
$guide = Read-Utf8 'docs\user_guide\init-prd-start.md'
$validator = Read-Utf8 'scripts\validate-plugin.ps1'

# --- P0: product-language gate -------------------------------------------------
$productFirst = [regex]::Match($skill, '(?ms)^## Product-first contract\s*\r?\n(?<body>.*?)(?=^## |\z)')
Assert-Condition $productFirst.Success 'fp-prd lacks the Product-first contract section'
$productFirstBody = $productFirst.Groups['body'].Value
Assert-Anchors $productFirstBody @(
    'PRD audience and product-language gate',
    'Code-fact consumption boundary',
    'Fact conversion',
    'Prototype selection gate',
    'Report layering'
) 'fp-prd product-first structure'
Assert-Anchors $productFirstBody @(
    'Who / Why / What / Rule / Outcome',
    '源码路径、文件名和行号',
    '类名、函数名、模型名、接口名和字段设计',
    '构建命令、端口、SHA、Git 状态和验证计数',
    '除非用户明确要求技术型 PRD'
) 'fp-prd product-language gate'
Assert-Anchors $template @(
    '## PRD audience and voice',
    '只描述 Who / Why / What / Rule / Outcome，不描述 How',
    '代码和实现证据不得直接复制到 PRD'
) 'prd-template audience and voice'
Assert-Anchors $template @(
    '## Product-language self-review',
    '正文不含源码路径、文件名、行号、类名、函数名、模型名、接口名和字段设计',
    '正文不含 SHA、端口、启动命令、Git 状态、构建日志、文件数或资源计数',
    '不懂代码的产品经理能否只看这份 PRD'
) 'prd-template product-language self-review'
Assert-Anchors $skill @('product-language gate', 'product-language leakage') 'fp-prd self-review wiring'

# --- P0: code facts cannot decide product scope --------------------------------
Assert-Anchors $productFirstBody @(
    '代码探索结果只能回答',
    '当前用户能做什么、不能做什么',
    '代码探索结果不能回答',
    '目标用户要什么、MVP 含哪些新能力',
    '禁止用现有枚举、模块或字段决定 MVP 边界'
) 'fp-prd code-fact boundary'
Assert-Anchors $grill @(
    'whether an existing module should be split, merged, or replaced by a new one',
    'lifecycle, version, or reference semantics',
    'A high-confidence code fact is not a high-confidence product decision'
) 'interview code-fact boundary'
Assert-Anchors $explore @(
    'prd-product-surface-facts',
    'prd-implementation-evidence',
    'PRD writers must not copy it into PRD prose',
    'do not promote an implementation capability into target product scope'
) 'prd-facts three-layer return'

# --- P0: object, relation and lifecycle before pages ---------------------------
$objectPhases = [regex]::Match($grill, '(?ms)^## Business-object and relation phases\s*\r?\n(?<body>.*?)(?=^## |\z)')
Assert-Condition $objectPhases.Success 'interview lacks the business-object and relation phases'
$phasesBody = $objectPhases.Groups['body'].Value
$previous = -1
foreach ($anchor in @('对象清单', '关系消歧', '生命周期与引用语义', '内容模型审阅')) {
    $index = $phasesBody.IndexOf($anchor, [System.StringComparison]::Ordinal)
    Assert-Condition ($index -gt $previous) "business-object phase order is missing or invalid at $anchor"
    $previous = $index
}
Assert-Anchors $phasesBody @(
    '归属、绑定、引用、筛选条件、数据来源、使用限制或无关系',
    '关系类型确认前不得询问一对一、一对多或多对多',
    '引用方绑定对象本身还是具体版本',
    '新版本是否自动生效',
    '旧版本失效后既有引用如何处理',
    '历史结果是否冻结',
    '当前代码枚举不作为目标内容模型',
    '版本触发器',
    '两者没有业务关系'
) 'business-object and relation phases'
Assert-Condition (-not $phasesBody.Contains('是关联一个还是多个')) 'interview still presupposes an existing relation'

# --- P0: Bucket A/B tightening --------------------------------------------------
Assert-Anchors $grill @(
    'Bucket A contains only:',
    'decisions the user already stated explicitly',
    'current product behavior verified in this session',
    'changes no scope, risk, or behavior',
    'changes no data boundary, permission, lifecycle, or acceptance criteria',
    '**Always Bucket C:**'
) 'interview bucket tightening'
Assert-Anchors $grill @(
    'deployment and isolation boundary',
    'the relationship between two business objects',
    'how existing references behave after a version is deactivated',
    'the main delivery experience and secondary output scope',
    'new content blocks absent from current implementation',
    'any new business object'
) 'interview forced Bucket C set'
Assert-Anchors $grill @('Deployment and isolation boundary: single instance or multi-tenant') 'interview deployment-boundary blocking decision'
Assert-Condition (-not $grill.Contains('### 已确定')) 'interview Phase 1 still labels inferences as 已确定'
Assert-Anchors $grill @('建议采用的默认项（待批量确认）') 'interview Phase 1 relabel'
Assert-Anchors $skill @('Bucket A holds only user-stated decisions') 'fp-prd hard-gate bucket tightening'

# --- P1: prototype requires an explicit user choice ----------------------------
Assert-Anchors $productFirstBody @(
    '`UI-heavy` 只用于推荐原型，不切换模式',
    '用户明确要求先看原型',
    '未获用户选择前不创建任何原型工程、不安装依赖、不运行构建或预览'
) 'prototype selection gate'
Assert-Anchors $skill @(
    'A UI-heavy idea never selects this mode by itself',
    'present the three options (直接写 PRD / 先做轻量产品线框 / 先做可运行交互原型)'
) 'mode routing'
Assert-Condition (-not (Test-UiHeavyAutoPrototype $skill)) 'fp-prd routes UI-heavy straight into Prototype-first'
Assert-Condition (-not (Test-UiHeavyAutoPrototype $grill)) 'interview routes UI-heavy straight into Prototype-first'
Assert-Condition (-not (Test-UiHeavyAutoPrototype $guide)) 'user guide routes UI-heavy straight into Prototype-first'
Assert-Condition (-not $skill.Contains('or when the idea is UI-heavy and a prototype would clarify the requirement faster')) 'fp-prd retains the former UI-heavy mode trigger'

# --- P1: prototype metadata ownership ------------------------------------------
Assert-Anchors $template @(
    '- 原型入口：',
    '- 演示范围：',
    '- 已确认结论：',
    '- 未覆盖范围：'
) 'prd-template product prototype slots'
foreach ($removed in @(
    '- 原型模式：',
    '- 源码与基座：',
    '- 预览与验证：',
    '- 原型依据：',
    'baseReference 版本',
    'Mock 不等于真实 E2E'
)) {
    Assert-Condition (-not $template.Contains($removed)) "prd-template still duplicates prototype technical metadata: $removed"
}
Assert-Anchors $prototypeContract @(
    '### 两种原型用途',
    '产品评审原型',
    '技术可运行原型',
    '默认不要求完整网络隔离证明',
    '两种用途都必须登记 manifest 与 evidence',
    '### 元数据归属',
    '原型技术元数据不得复制进 PRD 正文'
) 'prototype contract prototype kinds and metadata ownership'
Assert-Anchors $productFirstBody @(
    '原型技术信息由 `prototype/manifest.json` 与原型 evidence 独占'
) 'fp-prd metadata ownership'

# --- P1: product-facing completion report --------------------------------------
Assert-Anchors $productFirstBody @(
    '默认完成汇报只面向产品读者',
    '原型技术元数据、构建/浏览器/视觉检查与 Git 状态保留在 manifest/evidence'
) 'report layering'
Assert-Anchors $skill @(
    'Report through the Report layering contract, by default only:',
    'Keep build commands, ports, base versions, hashes, Git state, verification counters, and browser/visual logs in prototype manifest/evidence'
) 'fp-prd output layering'
Assert-Condition (-not ($skill -match '(?m)^- Prototype mode, source/manifest and preview paths, verified local preview command/URL, base version, actual checks and limitations')) 'fp-prd Output still lists raw prototype technical metadata by default'

# --- P2: decision-source and relation-semantics checks -------------------------
Assert-Anchors $template @(
    '“关联、绑定、归属、同步、继承、自动升级”等关系词都有用户明确确认的来源'
) 'prd-template relation-semantics self-review'
Assert-Anchors $grill @(
    'never present an assistant recommendation as a user decision'
) 'interview decision-source labeling'

# --- Public surfaces -----------------------------------------------------------
Assert-Anchors $command @(
    'UI-heavy 只作推荐，不自动切换',
    '产品语言门禁',
    'product-surface-facts',
    '未获用户选择不创建原型工程'
) 'commands/fp-prd.md gate checksum'
Assert-Anchors $guide @(
    'PRD 的默认读者是产品经理、业务方、设计师和研发评审者',
    '页面或交互较多的需求只会**推荐**原型',
    '未获得你的选择前，不会创建原型源码、安装依赖或运行构建/预览',
    '产品评审原型'
) 'user guide product-first workflow'
Assert-Condition (-not (Test-UiHeavyAutoPrototype $guide)) 'user guide retains a UI-heavy auto-prototype trigger'

# --- Mutation controls ---------------------------------------------------------
Assert-Condition (Test-UiHeavyAutoPrototype $guide.Replace('页面或交互较多的需求只会**推荐**原型', 'UI-heavy 需求直接进入 prototype-first')) 'ui-heavy auto-prototype detector misses an affirmative replacement'
Assert-Condition (Test-UiHeavyAutoPrototype 'UI-heavy requirements use Prototype-first mode.') 'ui-heavy auto-prototype detector misses plain English wording'
Assert-Condition (Test-UiHeavyAutoPrototype 'UI-heavy 时使用 Prototype-first。') 'ui-heavy auto-prototype detector misses plain Chinese wording'
Assert-Condition (-not (Test-UiHeavyAutoPrototype 'A UI-heavy idea never selects this mode by itself.')) 'ui-heavy auto-prototype detector rejects the negative control'
Assert-Condition (-not (Test-UiHeavyAutoPrototype '`UI-heavy` 只用于推荐原型，不切换模式。')) 'ui-heavy auto-prototype detector rejects the Chinese recommendation control'

Assert-Anchors $validator @(
    "`$prdProductFirstValidator = Join-Path `$root 'scripts\test-prd-product-first-contract.ps1'",
    '& powershell -NoProfile -ExecutionPolicy Bypass -File $prdProductFirstValidator',
    "Assert-Condition (`$LASTEXITCODE -eq 0) 'focused PRD product-first contract validator failed'"
) 'plugin validation entrypoint'

Write-Host 'PRD product-first contract checks passed (static contract coverage; agent behavior requires scenario testing).'
