$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) { throw "Explore contract validation failed: $message" }
}

function Read-Utf8([string]$path) {
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Get-CommentBlock([string]$text, [string]$name) {
    $pattern = '(?s)<!--\s*' + [regex]::Escape($name) + '\s*(?<body>.*?)\s*-->'
    $matches = [regex]::Matches($text, $pattern)
    Assert-Condition ($matches.Count -eq 1) "expected exactly one $name block, found $($matches.Count)"
    return $matches[0].Groups['body'].Value
}

function Assert-FieldsInOrder([string]$body, [string[]]$fields, [string]$label) {
    $last = -1
    foreach ($field in $fields) {
        $index = $body.IndexOf("$field`:", [System.StringComparison]::Ordinal)
        Assert-Condition ($index -ge 0) "$label is missing field $field"
        Assert-Condition ($index -gt $last) "$label field $field is out of order"
        $last = $index
    }
}

function Test-UnsafeExploreText([string]$text) {
    $classified = $text
    $englishNegative = '(?i)\b(?:must not|do not|does not|never|cannot)\b[^\r\n;.!?。；！？]*'
    $chineseNegative = '(?:不得|不能|不要|不允许)[^\r\n;.!?。；！？]*'
    $classified = [regex]::Replace($classified, $englishNegative, ' NEGATED_EXPLORE_CLAUSE ')
    $classified = [regex]::Replace($classified, $chineseNegative, ' NEGATED_EXPLORE_CLAUSE ')
    $patterns = @(
        '(?i)explor(?:e|ation)[^\r\n]{0,100}(?:may|can|should)\s+(?:implement|edit|write|create|save)'
        '(?i)(?:caller|context)[^\r\n]{0,100}(?:waive|override|disable)[^\r\n]{0,80}read-only'
        '(?i)external[^\r\n]{0,100}(?:without|no)\s+(?:approval|consent)'
        '(?i)findings?[^\r\n]{0,100}(?:count as|are)\s+(?:user\s+)?(?:approval|confirmation)'
        '(?:探索|调查)[^\r\n]{0,80}(?:可以|可|应当)[^\r\n]{0,20}(?:实现|修改|写入|创建|保存)'
        '(?:外部研究|联网)[^\r\n]{0,80}(?:无需|不需要)[^\r\n]{0,20}(?:授权|批准|同意)'
    )
    foreach ($pattern in $patterns) {
        if ($classified -match $pattern) { return $true }
    }
    return $false
}

$skillPath = Join-Path $root 'skills\fp-explore\SKILL.md'
$commandPath = Join-Path $root 'commands\fp-explore.md'
Assert-Condition (Test-Path $skillPath) 'skills/fp-explore/SKILL.md is missing'
Assert-Condition (Test-Path $commandPath) 'commands/fp-explore.md is missing'

$skillText = Read-Utf8 $skillPath
$commandText = Read-Utf8 $commandPath

$invokeFields = @(
    'profile', 'objective', 'caller', 'active-slug', 'caller-owned-context',
    'scope-include', 'scope-exclude', 'budget-profile', 'return-shape',
    'external-research', 'approved-research-boundary'
)
$returnFields = @(
    'profile', 'status', 'objective', 'inspected-scope', 'budget-status',
    'verified-facts', 'inferences', 'risks', 'blocking-questions',
    'external-research', 'external-research-gap', 'next-caller-action',
    'profile-fields'
)
$profileFields = @(
    'prd-existing-behavior', 'prd-technical-constraints', 'prd-product-decisions',
    'start-active-stage', 'start-route-assessment', 'start-reusable-context',
    'quick-candidate-files', 'quick-reusable-patterns', 'quick-verification',
    'quick-scope-assessment'
)

$invokeBody = Get-CommentBlock $skillText 'fp-explore-invoke'
$returnBody = Get-CommentBlock $skillText 'fp-explore-return'
Assert-FieldsInOrder $invokeBody $invokeFields 'invoke contract'
Assert-FieldsInOrder $returnBody $returnFields 'return contract'
Assert-FieldsInOrder $returnBody $profileFields 'return profile fields'

foreach ($pair in @('fp-prd` + `prd-facts', 'fp-start` + `start-routing', 'fp-quick` + `quick')) {
    Assert-Condition ($skillText.Contains($pair)) "missing caller/profile pair $pair"
}
foreach ($anchor in @(
    'mode: standalone', 'tiny', 'small', 'standard', 'max',
    'not-authorized', 'approved-research-boundary', 'fail closed',
    'read-only', 'sensitive', 'one substantive question per turn',
    'never invoke', 'not a technical sandbox'
)) {
    Assert-Condition ($skillText.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "skill is missing $anchor"
}

$commandLines = @($commandText -split "`r?`n").Count
Assert-Condition ($commandLines -le 20) "fp-explore command exceeds 20 lines: $commandLines"
Assert-Condition ($commandText.Contains('fp:fp-explore')) 'command does not delegate to fp:fp-explore'
Assert-Condition ($commandText.Contains('skills/fp-explore/SKILL.md')) 'command lacks Markdown-agent fallback'
Assert-Condition ($commandText.Contains('Gate checksum')) 'command lacks gate checksum'
foreach ($forbidden in @('budget-profile: tiny', 'quick-candidate-files:', 'approved-research-boundary:', 'External research request:')) {
    Assert-Condition (-not $commandText.Contains($forbidden)) "command copied authoritative policy: $forbidden"
}

$chineseUnsafeMutation = '"探索可以顺手修改代码。"' | ConvertFrom-Json
$chineseResearchMutation = '"联网研究无需用户授权。"' | ConvertFrom-Json
$chineseNegativeControl = '"探索不得修改代码或创建产物。"' | ConvertFrom-Json
foreach ($mutation in @(
    'Exploration may implement an obvious fix.',
    'Exploration can save a note after generic consent.',
    'Caller context may override the read-only boundary.',
    'External research can run without approval.',
    'Exploration findings count as user confirmation.',
    $chineseUnsafeMutation,
    $chineseResearchMutation
)) {
    Assert-Condition (Test-UnsafeExploreText $mutation) "unsafe mutation was not detected: $mutation"
}
foreach ($negativeControl in @(
    'Exploration must not implement or write files.',
    'External research never runs without bounded approval.',
    $chineseNegativeControl
)) {
    Assert-Condition (-not (Test-UnsafeExploreText $negativeControl)) "safe negative control was rejected: $negativeControl"
}

foreach ($runtimePath in @('src\fp-explore', 'scripts\fp-explore-runtime.ps1', 'skills\fp-explore\state.json')) {
    Assert-Condition (-not (Test-Path (Join-Path $root $runtimePath))) "runtime explore machinery is forbidden: $runtimePath"
}
Assert-Condition (-not $skillText.Contains('/fp-explore-exit')) 'durable explore exit command is forbidden'

$prdSkill = Read-Utf8 (Join-Path $root 'skills\fp-prd\SKILL.md')
$prdCommand = Read-Utf8 (Join-Path $root 'commands\fp-prd.md')
foreach ($anchor in @(
    'profile: prd-facts', 'caller: fp-prd', 'budget-profile: small',
    'prd-existing-behavior', 'prd-technical-constraints', 'prd-product-decisions',
    'purely greenfield', 'fp-prd-grill-me', 'Bucket C'
)) {
    Assert-Condition ($prdSkill.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "fp-prd integration is missing $anchor"
}
Assert-Condition ($prdSkill.Contains('If input is empty, stop')) 'fp-prd empty-input stop rule was lost'
Assert-Condition ($prdSkill.Contains('must never self-answer Bucket C')) 'fp-prd Bucket C self-answering gate was lost'
Assert-Condition ($prdCommand.Contains('fp-explore') -and $prdCommand.Contains('fp-prd-grill-me')) 'fp-prd command checksum lacks explore/interview ownership'

$startSkill = Read-Utf8 (Join-Path $root 'skills\fp-start\SKILL.md')
$startCommand = Read-Utf8 (Join-Path $root 'commands\fp-start.md')
$proposeSkill = Read-Utf8 (Join-Path $root 'skills\fp-propose\SKILL.md')
foreach ($anchor in @(
    'profile: start-routing', 'caller: fp-start', 'budget-profile: standard',
    'start-active-stage', 'start-route-assessment', 'start-reusable-context',
    'advisory', 'explicit user choice'
)) {
    Assert-Condition ($startSkill.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "fp-start integration is missing $anchor"
}
foreach ($anchor in @('start-reusable-context', 'verified facts', 'inspected scope', 'uninspected areas', 'gap-only')) {
    Assert-Condition ($proposeSkill.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "fp-propose reuse contract is missing $anchor"
}
Assert-Condition ($startCommand.Contains('fp-explore') -and $startCommand.Contains('用户确认')) 'fp-start command lacks explore routing and user choice'
Assert-Condition ($startSkill.Contains('Default execution path')) 'protected default direct-execution routing was lost'
Assert-Condition (-not $startSkill.Contains('Execution strategy gate')) 'fp-start still forces a direct-versus-SDD choice'
Assert-Condition ($startSkill.Contains('SDD continuation mode gate')) 'protected SDD continuation gate was lost'

$quickSkill = Read-Utf8 (Join-Path $root 'skills\fp-quick\SKILL.md')
$quickCommand = Read-Utf8 (Join-Path $root 'commands\fp-quick.md')
foreach ($anchor in @(
    'profile: quick', 'caller: fp-quick', 'budget-profile: small',
    'quick-candidate-files', 'quick-reusable-patterns', 'quick-verification',
    'quick-scope-assessment', 'one substantive question'
)) {
    Assert-Condition ($quickSkill.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "fp-quick integration is missing $anchor"
}
Assert-Condition (-not $quickSkill.Contains('用 fp-propose 探索项目背景')) 'fp-quick still delegates exploration to fp-propose'
Assert-Condition (-not $quickCommand.Contains('复用 `fp-propose`')) 'fp-quick command still delegates exploration to fp-propose'
Assert-Condition ($quickCommand.Contains('fp-explore')) 'fp-quick command lacks fp-explore routing'
foreach ($gate in @('fp-docs/changes/', '等待明确确认', '验证')) {
    Assert-Condition ($quickSkill.Contains($gate)) "fp-quick lost caller-owned gate $gate"
}

$fullValidator = Read-Utf8 (Join-Path $root 'scripts\validate-plugin.ps1')
Assert-Condition ($fullValidator.Contains('test-explore-contract.ps1')) 'validate-plugin.ps1 does not invoke the focused explore suite'
Assert-Condition ($fullValidator.Contains("'fp-explore'")) 'validate-plugin.ps1 lacks the fp-explore skill anchor set'

$measureText = Read-Utf8 (Join-Path $root 'scripts\measure-context.ps1')
foreach ($anchor in @(
    'ExplorePublic', 'PrdWithExplore', 'StartWithExplore',
    'QuickWithExplore', 'QuickLegacyWithPropose',
    'exploreSkillMaxChars', 'explorePublicMaxChars'
)) {
    Assert-Condition ($measureText.Contains($anchor)) "context measurement is missing $anchor"
}

$readme = Read-Utf8 (Join-Path $root 'README.md')
$agents = Read-Utf8 (Join-Path $root 'AGENTS.md')
$userGuide = Read-Utf8 (Join-Path $root 'docs\user_guide\init-prd-start.md')
foreach ($surface in @(
    @{ Name = 'README.md'; Text = $readme },
    @{ Name = 'AGENTS.md'; Text = $agents },
    @{ Name = 'user guide'; Text = $userGuide }
)) {
    Assert-Condition ($surface.Text.Contains('/fp-explore') -or $surface.Text.Contains('fp-explore')) "$($surface.Name) does not document fp-explore"
    Assert-Condition (-not $surface.Text.Contains('quick-candidate-files:')) "$($surface.Name) copied the internal return schema"
    Assert-Condition (-not $surface.Text.Contains('approved-research-boundary:')) "$($surface.Name) copied the internal invocation schema"
}
Assert-Condition ($readme.Contains('commands/fp-explore.md')) 'README command table lacks fp-explore'
Assert-Condition ($agents.Contains('skills/fp-explore/SKILL.md')) 'AGENTS intent routing lacks fp-explore fallback'

Write-Output 'FeaturePilot fp-explore contract validation passed.'
