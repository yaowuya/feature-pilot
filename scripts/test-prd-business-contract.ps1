$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "PRD business contract validation failed: $message"
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

$skill = Read-Utf8 'skills\fp-prd\SKILL.md'
$grill = Read-Utf8 'skills\fp-prd-grill-me\SKILL.md'
$template = Read-Utf8 'skills\fp-prd\prd-template.md'
$command = Read-Utf8 'commands\fp-prd.md'
$guide = Read-Utf8 'docs\user_guide\init-prd-start.md'
$validator = Read-Utf8 'scripts\validate-plugin.ps1'

$businessAnalysis = [regex]::Match($grill, '(?ms)^## Business-first analysis\s*\r?\n(?<body>.*?)(?=^## |\z)')
Assert-Condition $businessAnalysis.Success 'interview lacks Business-first analysis'
$analysis = $businessAnalysis.Groups['body'].Value
$previous = -1
foreach ($anchor in @('现状流程', '目标流程', '变化与影响', '状态与规则', '异常闭环', '页面映射')) {
    $index = $analysis.IndexOf($anchor, [System.StringComparison]::Ordinal)
    Assert-Condition ($index -gt $previous) "business-analysis order is missing or invalid at $anchor"
    $previous = $index
}
Assert-Anchors $analysis @('新业务', '简单', '不适用', '后台无需修改', '证据', '未知', '业务状态', '页面状态') 'business analysis'
Assert-Anchors $grill @('not a cap or a quota', 'Never downgrade Bucket C', 'continue one at a time', 'Do not invent questions', 'Business-first analysis') 'interview question budget'
Assert-Condition (-not $grill.Contains('move the rest to Bucket B')) 'interview still downgrades unresolved decisions to meet a question cap'
Assert-Condition (-not $grill.Contains('select the highest-impact unresolved decisions as Bucket C')) 'zero-C branch still manufactures a question quota'
Assert-Anchors $skill @('Business-first analysis', '业务闭环', '原型确认只覆盖已演示', 'return to `fp-prd-grill-me`') 'PRD orchestration'
Assert-Anchors $command @('业务闭环', '不因数量降级') 'command checksum'

$bodyMatch = [regex]::Match($template, '(?ms)^````markdown\r?\n(?<body>.*?)^````\s*$')
Assert-Condition $bodyMatch.Success 'template body is missing'
$body = $bodyMatch.Groups['body'].Value
$headings = @([regex]::Matches($body, '(?m)^#{2,4} [^\r\n]+') | ForEach-Object { $_.Value })
$expectedHeadings = @(
    '## 一、用户故事', '### 1.1 用户故事', '### 1.2 业务问题与预期目标',
    '## 二、核心业务流程', '## 三、功能需求', '### 3.1 <功能名称>',
    '#### 3.1.1 功能说明', '#### 3.1.2 交互逻辑', '#### 3.1.3 异常处理', '#### 3.1.4 原型',
    '## 四、非功能需求', '### 4.1 性能要求', '### 4.2 安全需求', '### 4.3 操作日志记录',
    '## 五、测试建议', '## 六、待确认问题'
)
Assert-Condition (($headings -join "`n") -ceq ($expectedHeadings -join "`n")) 'mandatory headings or order changed'
Assert-Anchors $body @(
    '| 异常场景 | 触发条件 | 系统处理方式 | 用户提示 |',
    '| 操作 | 是否记录日志 | 记录信息 |',
    '| 场景 | 前置条件 | 操作 | 预期结果 |',
    '**本次范围**', '**现状流程**', '**目标流程**', '**变化与影响**',
    '**业务规则**', '**业务状态与流转**', '**页面与操作映射**',
    '触发条件', '执行角色', '退出条件', '允许操作', '结果可见位置',
    '补救责任', '跨角色', '不改链路'
) 'template content slots'
Assert-Anchors $template @('拿掉页面', '不改结论', '业务闭环', '无法自行补齐', '非阻塞') 'semantic self-review'
Assert-Anchors $guide @('先业务、后页面', '3–5', '不因数量降级', '后台无需修改', '原型确认') 'user guide'
Assert-Anchors $validator @(
    "`$prdBusinessContractValidator = Join-Path `$root 'scripts\test-prd-business-contract.ps1'",
    '& powershell -NoProfile -ExecutionPolicy Bypass -File $prdBusinessContractValidator',
    "Assert-Condition (`$LASTEXITCODE -eq 0) 'focused PRD business contract validator failed'"
) 'plugin validation entrypoint'

Write-Host 'PRD business contract checks passed (static contract coverage; agent behavior requires scenario testing).'
