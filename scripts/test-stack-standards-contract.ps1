$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) { throw "Stack standards contract validation failed: $message" }
}

function Read-Utf8([string]$relativePath) {
    $path = Join-Path $root $relativePath
    Assert-Condition (Test-Path -LiteralPath $path -PathType Leaf) "missing resource: $relativePath"
    return [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
}

function Assert-Anchors([string]$text, [string[]]$anchors, [string]$label) {
    foreach ($anchor in $anchors) {
        Assert-Condition ($text.Contains($anchor)) "$label is missing $anchor"
    }
}

function Test-UnsafePresetText([string]$text) {
    $classified = [regex]::Replace($text, '(?i)\b(?:must not|do not|never|cannot)\b[^\r\n;.!?。；！？]*', ' NEGATED_CLAUSE ')
    $classified = [regex]::Replace($classified, '(?:不得|不要|禁止|不能)[^\r\n;.!?。；！？]*', ' NEGATED_CLAUSE ')
    foreach ($pattern in @(
        '(?i)all Django projects must use[^\r\n]*(?:Pydantic v1|TenantBaseModel)',
        '(?i)all Vue projects must use[^\r\n]*(?:Vue 2\.7|bk-)',
        '(?i)(?:stack detection|preset matching)[^\r\n]*(?:authorizes|automatically overwrites)[^\r\n]*(?:settings|rules)',
        '(?i)README alone[^\r\n]*(?:proves|confirms)[^\r\n]*(?:Django|Vue)',
        '(?i)(?:backend-only|frontend-only)[^\r\n]*loads all presets',
        '(?i)preset adoption[^\r\n]*installs dependencies',
        '所有 Django 项目必须使用[^\r\n]*(?:Pydantic v1|TenantBaseModel)',
        '所有 Vue 项目必须使用[^\r\n]*(?:Vue 2\.7|bk-)',
        '技术栈匹配后自动覆盖[^\r\n]*(?:settings|规范)'
    )) {
        if ($classified -match $pattern) { return $true }
    }
    return $false
}

$init = Read-Utf8 'skills/fp-init/SKILL.md'
Assert-Condition ($init.Contains('stack-standards.md')) 'fp-init does not select built-in stack standards'
$selection = Read-Utf8 'skills/fp-init/stack-standards.md'
$templates = Read-Utf8 'skills/fp-init/templates.md'
$workspace = Read-Utf8 'skills/_shared/workspace-rules.md'
$engineering = Read-Utf8 'skills/_shared/engineering-quality.md'
$common = Read-Utf8 'skills/_shared/code-standards/common.md'
$django = Read-Utf8 'skills/_shared/code-standards/django.md'
$vue = Read-Utf8 'skills/_shared/code-standards/vue.md'

Assert-Anchors $selection @(
    'independent-end-matching', 'direct-dependency-and-entry-evidence',
    'appRoot', 'Django', 'Vue 2.6', 'Vue 2.7', 'Vue 3', 'Pydantic v1', 'Pydantic v2',
    'unknown-is-not-a-match', 'existing-rules-first',
    'selection-is-not-write-approval', 'manifest-only default',
    'no-second-preset-choice', 'no-example-derived-facts',
    'Built-in preset:', 'Rule resources:', 'Applies to:', 'Project rule sources:', 'Confirmed overrides:',
    'skills/_shared/code-standards/common.md',
    'skills/_shared/code-standards/django.md', 'skills/_shared/code-standards/vue.md',
    'preserved', 'registered', 'skipped', 'unknown'
) 'stack selection'
Assert-Anchors $init @('stack-standards.md', 'settings-created-only-after-explicit-approval', 'Never overwrite', '规范') 'init'
Assert-Anchors $workspace @('engineering-quality.md', '已登记技术栈规范') 'workspace route'
Assert-Anchors $engineering @(
    '已登记技术栈规范', 'Code Standards', 'Built-in preset',
    'skills/_shared/code-standards/common.md', 'skills/_shared/code-standards/django.md', 'skills/_shared/code-standards/vue.md',
    'backend-only', 'frontend-only', 'none', 'Unknown',
    '同一工作流', '独立', 'Applicable Global Constraints', '客户', '缺失'
) 'consumption route'
Assert-Condition ($engineering.Contains('无登记记 N/A')) 'entering an unregistered app must stay read-only and use N/A'
Assert-Condition ($engineering.Contains('新增或更新登记须转 fp-init')) 'consumers must route registration writes back to fp-init'
Assert-Condition (-not $engineering.Contains('补齐该应用的登记')) 'consumers still appear authorized to fill missing registrations'

Assert-Condition ([regex]::Matches($templates, '(?m)^Target: `fp-docs/settings/code-standards\.md`\s*$').Count -eq 1) 'project standards template is missing or duplicated'
Assert-Anchors $templates @('# FeaturePilot Project Code Standards', 'Rule ID:', 'Applies to:', 'Rule:', 'Evidence:', 'No project-specific rules confirmed yet.') 'project standards template'
Assert-Anchors $init @('settings/code-standards.md', 'Project rule sources', '逐文件') 'init project standards route'
Assert-Anchors $selection @('settings/code-standards.md', 'Project rule sources:', '批准') 'project standards registration'
Assert-Anchors $workspace @('fp-commit', 'settings/code-standards.md', '已登记') 'narrow project standards owner'

Assert-Condition ([regex]::Matches($templates, '(?m)^## Code Standards\s*$').Count -eq 2) 'backend and frontend templates must each own one Code Standards section'
foreach ($heading in @('FeaturePilot Backend Settings', 'FeaturePilot Frontend Settings')) {
    $pattern = '(?ms)^## ' + [regex]::Escape($heading) + '\s*\r?\n(?<body>.*?)(?=^## FeaturePilot |\z)'
    $section = [regex]::Match($templates, $pattern)
    Assert-Condition $section.Success "missing settings template: $heading"
    Assert-Anchors $section.Groups['body'].Value @(
        '## Code Standards', 'Built-in preset:', 'Rule resources:', 'Applies to:',
        'Project rule sources:', 'Confirmed overrides:'
    ) $heading
}

foreach ($entry in @(
    @{ Text = $common; Prefix = 'Q'; Count = 5; Name = 'common' },
    @{ Text = $django; Prefix = 'B'; Count = 9; Name = 'django' },
    @{ Text = $vue; Prefix = 'F'; Count = 7; Name = 'vue' }
)) {
    $ids = [regex]::Matches($entry.Text, '(?m)^## ' + $entry.Prefix + '(?<id>\d{2})\b')
    Assert-Condition ($ids.Count -eq $entry.Count) "$($entry.Name) rule count changed"
    for ($i = 1; $i -le $entry.Count; $i++) {
        Assert-Condition ($ids[$i - 1].Groups['id'].Value -eq ('{0:D2}' -f $i)) "$($entry.Name) rule IDs must be unique and ordered"
    }
    Assert-Condition (-not (Test-UnsafePresetText $entry.Text)) "$($entry.Name) contains unsafe unconditional adoption"
    foreach ($forbidden in @('D:\02-canway', 'D:/02-canway', 'auto-ops', '@canway/', 'commons.custom_enum', 'packages.drf', '../skills/git-commit', '../skills/code-review', 'openapi-docs', 'superpowers-artifacts')) {
        Assert-Condition (-not $entry.Text.Contains($forbidden)) "$($entry.Name) leaks a customer-specific source: $forbidden"
    }
    foreach ($link in [regex]::Matches($entry.Text, '\]\((?<path>[^)]+\.md)\)')) {
        $file = Join-Path $root "skills/_shared/code-standards/$($link.Groups['path'].Value)"
        Assert-Condition (Test-Path -LiteralPath $file -PathType Leaf) "$($entry.Name) contains a broken local resource link"
    }
}
Assert-Anchors $common @('规范符合性', '代码缺陷', 'git diff --cached', '未验证', '不是 Git 自动门禁') 'common rules'
Assert-Anchors $django @('Pydantic v1', 'Pydantic v2', 'ForeignKey', 'choices', 'transaction.on_commit', 'IntegrityError', '历史模型', 'engineering-quality.md') 'Django rules'
Assert-Anchors $vue @('Vue 2.6', 'Vue 2.7', 'Vue 3', '<script setup>', 'Vuex', 'Pinia', 'finally', 'token', 'Vue.set', '未验证') 'Vue rules'

$brief = Read-Utf8 'skills/fp-execute-sdd/task-brief-template.md'
$package = Read-Utf8 'skills/fp-execute-sdd/review-package-template.md'
foreach ($surface in @(@{ Name = 'task brief'; Text = $brief }, @{ Name = 'review package'; Text = $package })) {
    Assert-Anchors $surface.Text @('Code standards', 'resolved', 'overrides', 'N/A') $surface.Name
}
$guide = Read-Utf8 'docs/user_guide/init-prd-start.md'
Assert-Anchors $guide @('Django', 'Vue', 'Code Standards', 'manifest-only', '已有') 'user guide'
$validator = Read-Utf8 'scripts/validate-plugin.ps1'
Assert-Condition ($validator.Contains('test-stack-standards-contract.ps1')) 'full validator does not invoke the stack standards suite'

foreach ($mutation in @(
    'All Django projects must use Pydantic v1.',
    'All Django projects must use TenantBaseModel.',
    'All Vue projects must use Vue 2.7 and bk- components.',
    'Stack detection authorizes writing settings.',
    'Preset matching automatically overwrites project rules.',
    'README alone confirms Django.',
    'Backend-only work loads all presets.',
    'Frontend-only work loads all presets.',
    'Preset adoption installs dependencies.',
    '所有 Django 项目必须使用 Pydantic v1。',
    '所有 Vue 项目必须使用 bk- 组件。',
    '技术栈匹配后自动覆盖已有 settings。'
)) {
    Assert-Condition (Test-UnsafePresetText $mutation) "unsafe mutation was not detected: $mutation"
}
foreach ($control in @(
    'Do not require all Django projects must use Pydantic v1.',
    'Never claim README alone confirms Django.',
    'Preset matching must not automatically overwrite existing settings.',
    'Backend-only work loads the registered Django preset.',
    'Frontend-only work loads the registered Vue preset.',
    '不要在技术栈匹配后自动覆盖已有 settings。'
)) {
    Assert-Condition (-not (Test-UnsafePresetText $control)) "safe control was rejected: $control"
}

Write-Output 'Stack standards contract checks passed (static coverage; agent scenarios verify selection and consumption behavior).'
