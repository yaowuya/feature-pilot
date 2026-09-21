$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) { throw "Prototype contract validation failed: $message" }
}
function Read-Utf8([string]$path) {
    $full = Join-Path $root $path
    Assert-Condition (Test-Path -LiteralPath $full -PathType Leaf) "missing $path"
    return [IO.File]::ReadAllText($full, [Text.Encoding]::UTF8)
}
function Assert-Contains([string]$text, [string[]]$values, [string]$name) {
    foreach ($value in $values) { Assert-Condition ($text.Contains($value)) "$name lost $value" }
}

$contract = Read-Utf8 'skills/_shared/prototype-contract.md'
$init = Read-Utf8 'skills/fp-init/SKILL.md'
$prd = Read-Utf8 'skills/fp-prd/SKILL.md'
$grill = Read-Utf8 'skills/fp-prd-grill-me/SKILL.md'
$template = Read-Utf8 'skills/fp-prd/prd-template.md'
$templates = Read-Utf8 'skills/fp-init/templates.md'
$workspace = Read-Utf8 'skills/_shared/workspace-rules.md'
$layout = Read-Utf8 'skills/_shared/artifact-layout.md'
$archive = Read-Utf8 'skills/fp-archive/SKILL.md'
$frontend = Read-Utf8 'skills/fp-frontend-spec/SKILL.md'
$validator = Read-Utf8 'scripts/validate-plugin.ps1'

$prototypeInit = Read-Utf8 'skills/fp-prototype-init/SKILL.md'
$prototypeCommand = Read-Utf8 'commands/fp-prototype-init.md'
Assert-Contains $prototypeInit @('no-full-init', 'no-manifest-required', 'manifest-section-only', 'fresh-reuse', 'approved-prototype-provisioning', 'prototype-contract.md', 'appRoot', 'CheckFreshness') 'standalone prototype init'
Assert-Contains $prototypeCommand @('skills/fp-prototype-init/SKILL.md', '$ARGUMENTS', 'manifest-section-only') 'prototype init command'
$delegation = [regex]::Match($init, '(?ms)^### 7a\. Optional project-native prototype base\s*(?<body>.*?)(?=^### |\z)').Groups['body'].Value
Assert-Contains $delegation @('fp:fp-prototype-init', 'caller', 'return') 'init delegation'
Assert-Condition (-not $delegation.Contains('1. ')) 'init still duplicates the prototype provisioning menu'
Assert-Contains $workspace @('fp-prototype-init', 'Prototype Bases') 'prototype ownership'
Assert-Condition (-not $workspace.Contains("Only init's separately approved provisioning")) 'workspace retains the old exclusive base owner'
Assert-Contains $prd @('Missing or stale bases route to `/fp-prototype-init`') 'PRD base recovery'
Assert-Contains $contract @('**fp-prototype-init**', 'manifest-section-only') 'shared base owner'

Assert-Contains $contract @('project-native', 'standalone-html', 'static-modular', 'mock-only', 'no-frontend', 'unknown', 'SSR', 'Storybook', 'baseReference', 'CheckFreshness', 'prototype/manifest.json', 'prototype-bases/<app-id>/manifest.json', 'build-time', 'browser-time', 'not real E2E', 'sourceEntry', 'ownedFiles', 'prototype-conflict') 'shared contract'
Assert-Contains $contract @('delivery', 'no-build', 'componentMap', 'scriptOrder', 'directOpen', 'network-guard.js', 'type="module"', 'classic script') 'static-modular contract'
Assert-Contains $contract @('static-modular` 与 `project-native` 共用同一 `schema`', 'commands.build` 必须为 `null`', '没有 `framework` 字段') 'static-modular unified schema'
Assert-Contains $contract @('static-modular`（已有前端默认推荐）', 'project-native`（需要真实组件运行时才选）', '不是失败后的自动降级') 'static-modular default mode'
Assert-Contains $contract @('它按 `mode` 分派两种字段规则') 'validator mode dispatch'
Assert-Contains $init @('prototype-contract.md', 'no-frontend', 'approved-prototype-provisioning', 'manifest-only default', 'prototype-bases/', 'prototype-provisioning is not discovery', 'static-modular') 'init'
Assert-Contains $prd @('prototype-contract.md', 'static-modular', 'project-native', 'standalone-html', 'prototype/manifest.json', 'baseReference', 'CheckFreshness') 'PRD'
Assert-Contains $prototypeInit @('static-modular', 'project-native', 'componentMap', 'scriptOrder', 'no-build') 'prototype init mode selection'
Assert-Contains $templates @('| App | App Root | Mode | Manifest | When To Read |', 'static-modular') 'init templates mode column'
Assert-Condition (-not $prd.Contains('- Single-file HTML/CSS/JS.')) 'PRD still forces single HTML globally'
Assert-Condition (-not $prd.Contains('`prototype.html` remains a single sibling file in either form.')) 'PRD still assumes one prototype path'
Assert-Contains $grill @('prototype-contract.md', 'project-native', 'baseReference') 'interview'
Assert-Contains $template @('prototype/manifest.json', 'prototype.html') 'PRD template'
Assert-Contains $templates @('Prototype Bases', 'prototype-bases/', 'prototype-contract.md') 'init templates'
foreach ($surface in @($workspace, $layout, $archive, $frontend)) {
    Assert-Contains $surface @('prototype-contract.md') 'consumer'
}
foreach ($test in @('test-prototype-contract.ps1', 'test-prototype-artifacts.ps1')) {
    Assert-Contains $validator @($test) 'plugin validator'
}
Assert-Contains (Read-Utf8 'commands/fp-init.md') @('no-frontend', 'approved-prototype-provisioning') 'init command'
Assert-Contains (Read-Utf8 'commands/fp-prd.md') @('project-native', 'standalone-html') 'PRD command'
Assert-Contains (Read-Utf8 'docs/user_guide/init-prd-start.md') @('prototype-bases/', 'project-native', 'Mock') 'guide'
Assert-Contains $contract @('prototype.gitignore', 'prototype-gitignore-guard', 'git check-ignore --no-index', 'git ls-files', 'git rm --cached', 'managed block', 'local-only') 'Git protection'
foreach ($surface in @($prototypeInit, $prd, $archive, $workspace)) {
    Assert-Contains $surface @('prototype-gitignore-guard', 'fp-docs/.gitignore') 'prototype writer Git protection'
}
Assert-Contains $validator @('test-prototype-ignore.ps1') 'Git ignore test registration'
Write-Host 'Prototype contract checks passed (static coverage, not runtime or fidelity proof).'
