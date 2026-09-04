$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) { throw "ELI5 contract validation failed: $message" }
}

function Read-Utf8([string]$path) {
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Get-CommentBlock([string]$text, [string]$name, [string]$label) {
    $pattern = '(?s)<!--\s*' + [regex]::Escape($name) + '\s*(?<body>.*?)\s*-->'
    $matches = [regex]::Matches($text, $pattern)
    Assert-Condition ($matches.Count -eq 1) "$label must contain exactly one $name block"
    return $matches[0].Groups['body'].Value
}

function Get-Section([string]$text, [string]$startHeading, [string]$endHeading, [string]$label) {
    $pattern = '(?s)' + [regex]::Escape($startHeading) + '\s*(?<body>.*?)\s*' + [regex]::Escape($endHeading)
    $match = [regex]::Match($text, $pattern)
    Assert-Condition $match.Success "$label section is missing or malformed"
    return $match.Groups['body'].Value
}

function Test-DisallowedEli5Integration([string]$text) {
    return $text.Contains('eli5-handoff.md') -or $text.Contains('fp:fp-eli5')
}

$paths = [ordered]@{
    Skill = 'skills\fp-eli5\SKILL.md'
    Command = 'commands\fp-eli5.md'
    Template = 'skills\fp-eli5\output-template.md'
    Handoff = 'skills\_shared\eli5-handoff.md'
}

foreach ($entry in $paths.GetEnumerator()) {
    Assert-Condition (Test-Path (Join-Path $root $entry.Value)) "$($entry.Value) is missing"
}

$skill = Read-Utf8 (Join-Path $root $paths.Skill)
$command = Read-Utf8 (Join-Path $root $paths.Command)
$template = Read-Utf8 (Join-Path $root $paths.Template)
$handoff = Read-Utf8 (Join-Path $root $paths.Handoff)
$exploreSkill = Read-Utf8 (Join-Path $root 'skills\fp-explore\SKILL.md')
$exploreCommand = Read-Utf8 (Join-Path $root 'commands\fp-explore.md')

$frontmatter = [regex]::Match($skill, '(?s)\A---\r?\n(?<body>.*?)\r?\n---')
Assert-Condition $frontmatter.Success 'fp-eli5 frontmatter is invalid'
$keys = @([regex]::Matches($frontmatter.Groups['body'].Value, '(?m)^([a-zA-Z0-9_-]+):') | ForEach-Object { $_.Groups[1].Value })
Assert-Condition ($keys.Count -eq 2 -and $keys -contains 'name' -and $keys -contains 'description') 'frontmatter must contain only name and description'
Assert-Condition ($skill -match '(?m)^name:\s*fp-eli5\s*$') 'skill name must match its directory'
Assert-Condition ($frontmatter.Groups['body'].Value.Contains('Use only when a user explicitly invokes /fp-eli5 or $fp-eli5')) 'skill discovery must be explicit-only'
Assert-Condition ((@($skill -split "`r?`n").Count) -le 500) 'SKILL.md exceeds 500 lines'
Assert-Condition ((@($command -split "`r?`n").Count) -le 20) 'command exceeds 20 lines'
Assert-Condition ($command.Contains('$ARGUMENTS')) 'command must forward $ARGUMENTS'
Assert-Condition ($command.Contains('Gate checksum')) 'command is missing its gate checksum'
Assert-Condition ($command.Contains('直接展示中文图解')) 'command must promise direct Chinese output'
Assert-Condition ($command.Contains('原始 HTML 标签')) 'command must forbid raw HTML in direct output'

foreach ($anchor in @(
    '`${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md`',
    'available-skill', 'DeepSeek Harness', '`${CLAUDE_PLUGIN_ROOT}/skills`',
    'generic', 'repository-grounded', 'external-current', 'fp:fp-explore', 'public standalone',
    'CANNOT_EXPLAIN_WITH_EVIDENCE', 'RENDERED_HTML_ARTIFACT', 'RENDERED_MARKDOWN_FALLBACK',
    'RENDERED_TEXT_FALLBACK', '默认不写入仓库', '直接图解（默认）', '只使用中文标签',
    '不依赖原始 HTML 标签', '不依赖 Mermaid', '技术标识只放在末尾的“真实依据”区域',
    '用户可见的状态说明使用中文'
)) {
    Assert-Condition ($skill.Contains($anchor)) "fp-eli5 is missing $anchor"
}

Assert-Condition (-not $skill.Contains('eli5-facts')) 'fp-eli5 must not invent an fp-explore profile'
Assert-Condition (-not $exploreSkill.Contains('fp-eli5')) 'fp-explore skill must remain unaware of fp-eli5'
Assert-Condition (-not $exploreCommand.Contains('fp-eli5')) 'fp-explore command must remain unaware of fp-eli5'

$genericSection = Get-Section $skill '### `generic`' '### `repository-grounded`' 'generic topic'
Assert-Condition (-not $genericSection.Contains('fp:fp-explore')) 'generic mode must not call fp-explore'
Assert-Condition ($genericSection.Contains('Generic mode never calls fp-explore.')) 'generic mode needs an explicit no-explore contract'
Assert-Condition ($skill.Contains('prototype.html is not an fp-eli5 output')) 'fp-eli5 must explicitly reject prototype equivalence'
Assert-Condition ($skill.Contains('Severity preservation applies to every rendering path.')) 'fp-eli5 must preserve severity across every renderer'

foreach ($anchor in @(
    'FACT', 'INFERENCE', 'RISK', 'UNKNOWN', 'ANALOGY', 'one-line conclusion',
    'failure', 'remember', 'evidence', '直接图解（默认）', '纯文字降级'
)) {
    Assert-Condition ($template.Contains($anchor)) "output template is missing $anchor"
}
Assert-Condition ($template -notmatch '(?i)<script\s+src|<link\s+[^>]*href|@import|https?://') 'output template permits an external resource'
Assert-Condition ($template.Contains('data-evidence="FACT"')) 'dedicated HTML artifact must retain stable internal evidence data'
Assert-Condition (-not $template.Contains('<span class="label">FACT</span>')) 'visible HTML artifact labels must use Chinese'

$directDiagram = Get-Section $template '## 直接图解（默认）' '## 纯文字降级' 'direct visual output'
foreach ($anchor in @('一句话结论', '一条主线', '哪里会出错', '只需记住什么', '真实依据（需要时再看）', '事实', '推断', '风险', '未知', '类比')) {
    Assert-Condition ($directDiagram.Contains($anchor)) "direct visual output is missing $anchor"
}
Assert-Condition ($directDiagram.Contains('→')) 'direct visual output must use a readable Chinese arrow flow'
Assert-Condition ($directDiagram.Contains('---')) 'direct visual output must separate the evidence area'
Assert-Condition (-not ($directDiagram -match '(?is)<\s*/?\s*[a-z][a-z0-9-]*\b[^>]*>')) 'direct visual output must not contain raw HTML tags'
Assert-Condition (-not $directDiagram.Contains('```mermaid')) 'direct visual output must not require Mermaid'
Assert-Condition (-not ($directDiagram -match '(?<![A-Za-z])(?:FACT|INFERENCE|RISK|UNKNOWN|ANALOGY)(?![A-Za-z])')) 'direct visual output must not expose English evidence labels'

$textFallbackStart = $template.IndexOf('## 纯文字降级', [System.StringComparison]::Ordinal)
Assert-Condition ($textFallbackStart -ge 0) 'plain-text fallback section is missing'
$textFallbackSection = $template.Substring($textFallbackStart)
Assert-Condition ($textFallbackSection -match '【事实：[^】]+】\s*→\s*【事实：[^】]+】\s*→\s*【推断：[^】]+】') 'plain-text flow must preserve Chinese evidence labels'
Assert-Condition (-not ($textFallbackSection -match '(?is)<\s*/?\s*[a-z][a-z0-9-]*\b[^>]*>')) 'plain-text fallback must not contain raw HTML tags'
Assert-Condition (-not ($textFallbackSection -match '(?<![A-Za-z])(?:FACT|INFERENCE|RISK|UNKNOWN|ANALOGY)(?![A-Za-z])')) 'plain-text fallback must not expose English evidence labels'

foreach ($field in @('caller:', 'topic:', 'active-slug:', 'pending-gate:', 'allowed-sources:', 'return-to:')) {
    Assert-Condition ($handoff.Contains($field)) "handoff is missing $field"
}
foreach ($caller in @('fp-init', 'fp-prd-grill-me', 'fp-brainstorm', 'fp-plan', 'fp-start')) {
    Assert-Condition ($handoff.Contains($caller)) "handoff is missing allowed caller $caller"
}
foreach ($anchor in @('Decision Ledger', 'task checkbox', 'coverage state', 'review verdict', 'write authorization', 'pending-gate')) {
    Assert-Condition ($handoff.Contains($anchor)) "handoff is missing non-authority anchor $anchor"
}

$sharedHandoffAnchor = '`${CLAUDE_PLUGIN_ROOT}/skills/_shared/eli5-handoff.md`'
$callerContracts = @(
    @{ Name = 'fp-init'; Path = 'skills\fp-init\SKILL.md'; Caller = 'caller: fp-init'; Resume = 'return-to: <fp-init + exact same pending-gate>' },
    @{ Name = 'fp-prd-grill-me'; Path = 'skills\fp-prd-grill-me\SKILL.md'; Caller = 'caller: fp-prd-grill-me'; Resume = 'return-to: <fp-prd-grill-me + same review item/question>' },
    @{ Name = 'fp-brainstorm'; Path = 'skills\fp-brainstorm\SKILL.md'; Caller = 'caller: fp-brainstorm'; Resume = 'return-to: <fp-brainstorm + same D-NNN/checkpoint>' },
    @{ Name = 'fp-plan'; Path = 'skills\fp-plan\SKILL.md'; Caller = 'caller: fp-plan'; Resume = 'return-to: <fp-plan + explicit plan confirmation>' },
    @{ Name = 'fp-start'; Path = 'skills\fp-start\SKILL.md'; Caller = 'caller: fp-start'; Resume = 'return-to: <fp-start + same stage gate>' }
)
foreach ($contract in $callerContracts) {
    $text = Read-Utf8 (Join-Path $root $contract.Path)
    Assert-Condition ($text.Contains($sharedHandoffAnchor)) "$($contract.Name) is missing the shared handoff anchor"
    Assert-Condition ($text.Contains('fp:fp-eli5')) "$($contract.Name) is missing the fp-eli5 invocation"
    Assert-Condition ($text.Contains('explicit-only JIT')) "$($contract.Name) is missing the explicit-only trigger"
    Assert-Condition ($text.Contains('replace every <...> metavariable')) "$($contract.Name) must require exact metavariable substitution"
    Assert-Condition ($text.Contains($contract.Caller)) "$($contract.Name) is missing its caller field"
    Assert-Condition ($text.Contains($contract.Resume)) "$($contract.Name) is missing its return-to field"
    $block = Get-CommentBlock $text 'fp-eli5-handoff' $contract.Name
    foreach ($prefix in @('topic: <', 'pending-gate: <', 'return-to: <')) {
        Assert-Condition ($block.Contains($prefix)) "$($contract.Name) must mark $prefix as a metavariable"
    }
    if ($contract.Name -eq 'fp-init') {
        Assert-Condition ($block.Contains('active-slug: N/A')) 'fp-init active-slug must remain N/A'
    } else {
        Assert-Condition ($block.Contains('active-slug: <')) "$($contract.Name) active-slug must be a metavariable"
    }
    foreach ($field in @('allowed-sources:')) {
        Assert-Condition ($block.Contains($field)) "$($contract.Name) is missing handoff field $field"
    }
}

$disallowedPaths = @(
    'skills\fp-execute\SKILL.md', 'skills\fp-execute-sdd\SKILL.md', 'skills\fp-archive\SKILL.md',
    'skills\fp-quick\SKILL.md', 'skills\fp-plan-backend\SKILL.md', 'skills\fp-plan-frontend\SKILL.md',
    'skills\fp-figma\SKILL.md', 'skills\fp-frontend-spec\SKILL.md',
    'skills\fp-propose\SKILL.md', 'skills\fp-prd\SKILL.md', 'skills\fp-final-review\SKILL.md',
    'skills\fp-module-review\SKILL.md', 'skills\fp-coverage\SKILL.md',
    'skills\fp-design-review\SKILL.md', 'skills\fp-db-adapter\SKILL.md'
)
$allSkillPaths = @(Get-ChildItem (Join-Path $root 'skills') -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } | ForEach-Object { 'skills\' + $_.Name + '\SKILL.md' })
$coveredSkillPaths = @($callerContracts.Path) + $disallowedPaths + @('skills\fp-eli5\SKILL.md', 'skills\fp-explore\SKILL.md')
$missingCallerCoverage = @($allSkillPaths | Where-Object { $coveredSkillPaths -notcontains $_ })
Assert-Condition ($missingCallerCoverage.Count -eq 0) "caller coverage is missing: $($missingCallerCoverage -join ', ')"

foreach ($path in $disallowedPaths) {
    $text = Read-Utf8 (Join-Path $root $path)
    Assert-Condition (-not (Test-DisallowedEli5Integration $text)) "$path must not integrate or invoke fp-eli5"
    Assert-Condition (Test-DisallowedEli5Integration ($text + "`nfp:fp-eli5")) "disallowed integration detector misses fp:fp-eli5 in $path"
    Assert-Condition (Test-DisallowedEli5Integration ($text + "`neli5-handoff.md")) "disallowed integration detector misses eli5-handoff.md in $path"
}

$readme = Read-Utf8 (Join-Path $root 'README.md')
$codexPlugin = Read-Utf8 (Join-Path $root '.codex-plugin\plugin.json') | ConvertFrom-Json
foreach ($anchor in @('commands/fp-eli5.md', '`fp-eli5`', '/fp-eli5', '直接展示中文图解', '原始 HTML 标签', '专用网页图解', '默认不写仓库')) {
    Assert-Condition ($readme.Contains($anchor)) "README.md is missing public anchor $anchor"
}
foreach ($surface in @($readme)) {
    foreach ($field in @('active-slug:', 'pending-gate:', 'allowed-sources:', 'return-to:')) {
        Assert-Condition (-not $surface.Contains($field)) "public docs must not copy internal field $field"
    }
}
Assert-Condition ($codexPlugin.skills -eq './skills/') 'Codex plugin must continue to expose ./skills/'

$eli5Design = Read-Utf8 (Join-Path $root 'docs\superpowers\specs\2026-08-24-fp-eli5-design.md')
foreach ($anchor in @(
    '### 8.3 专用网页图解', '### 8.4 直接中文图解', '默认直接展示中文图解',
    '不依赖原始 HTML 标签', '不依赖 Mermaid', '只有用户明确要求且宿主提供专用网页图解能力时',
    'RENDERED_MARKDOWN_FALLBACK`：直接中文图解已生成'
)) {
    Assert-Condition ($eli5Design.Contains($anchor)) "fp-eli5 design is missing $anchor"
}
Assert-Condition (-not $eli5Design.Contains('优先临时 HTML artifact')) 'fp-eli5 design must not advertise HTML-first output'
Assert-Condition (-not $eli5Design.Contains('Markdown + Mermaid')) 'fp-eli5 design must not advertise Mermaid as the direct fallback'

$validatePlugin = Read-Utf8 (Join-Path $root 'scripts\validate-plugin.ps1')
foreach ($anchor in @(
    'scripts\test-eli5-contract.ps1',
    'focused fp-eli5 contract validator is missing',
    'focused fp-eli5 contract validator must use UTF-8 BOM',
    'ReadAllBytes($eli5ContractValidator)',
    'focused fp-eli5 contract validator failed'
)) {
    Assert-Condition ($validatePlugin.Contains($anchor)) "validate-plugin.ps1 is missing aggregate anchor $anchor"
}

Write-Output 'FeaturePilot fp-eli5 contract validation passed.'
