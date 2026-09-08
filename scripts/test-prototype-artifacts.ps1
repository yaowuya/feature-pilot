$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$validator = Join-Path $PSScriptRoot 'validate-prototype.ps1'
if (-not (Test-Path -LiteralPath $validator)) { throw 'Missing prototype artifact validator' }
$root = Join-Path ([IO.Path]::GetTempPath()) ('fp-prototype-' + [guid]::NewGuid().ToString('N'))
$utf8 = New-Object Text.UTF8Encoding($false)
$count = 0
function Put([string]$path, [string]$text) {
    $full = Join-Path $root $path
    [IO.Directory]::CreateDirectory((Split-Path -Parent $full)) | Out-Null
    [IO.File]::WriteAllText($full, $text, $utf8)
}
function Hash([string]$path) { return (Get-FileHash -LiteralPath (Join-Path $root $path) -Algorithm SHA256).Hash.ToLowerInvariant() }
function Check([string]$name, [string]$path, [bool]$fresh, [string]$errorText = '', [string]$projectRoot = $root) {
    $caught = ''
    try { & $validator -ProjectRoot $projectRoot -PrototypePath $path -CheckFreshness:$fresh | Out-Null }
    catch { $caught = $_.Exception.Message }
    if ($errorText) {
        if (-not $caught.Contains($errorText)) { throw "$name expected '$errorText', got '$caught'" }
    } elseif ($caught) { throw "$name unexpectedly failed: $caught" }
    $script:count++
    Write-Host "PASS $name"
}
function Save([string]$folder, [object]$value) { Put "$folder/manifest.json" ($value | ConvertTo-Json -Depth 15) }
function Manifest([string]$folder, [string]$kind) {
    Put "$folder/src/main.js" 'export const app = "fixture only";'
    Put "$folder/src/mock.js" 'export const rows = [];'
    Put "$folder/preview/index.html" '<!doctype html><title>Mock fixture</title>'
    return [ordered]@{
        schema = 'fp-prototype/v1'; kind = $kind; mode = 'project-native'; appId = 'web'; appRoot = 'app'
        framework = @{ name = 'vue'; version = '3.5.0' }
        sourceEntry = 'src/main.js'; mockEntry = 'src/mock.js'; previewEntry = 'preview/index.html'
        commands = @{
            build = @{ relativeTo = 'project'; cwd = 'app'; run = 'DO-NOT-EXECUTE build' }
            preview = @{ relativeTo = 'artifact'; cwd = '.'; run = 'DO-NOT-EXECUTE preview' }
        }
        sources = @(@{ path = 'app/Button.vue'; sha256 = (Hash 'app/Button.vue') })
        ownedFiles = @('src/main.js', 'src/mock.js', 'preview/index.html') | ForEach-Object { @{ path = $_; sha256 = (Hash "$folder/$_") } }
        baseReference = $null
        dataMode = 'mock-only'; networkPolicy = 'deny-business-network'
        scenarios = @('default', 'empty')
        verification = @{ build = 'not-run'; preview = 'not-run'; network = 'not-run'; visual = 'not-run'; evidence = $null }
    }
}

try {
    Put 'app/Button.vue' '<template><button>Fixture</button></template>'
    $base = 'fp-docs/prototype-bases/web'
    $m = Manifest $base 'base'
    Save $base $m
    Check 'valid base' "$base/manifest.json" $true
    Push-Location $root
    try { Check 'relative project follows PowerShell location' "$base/manifest.json" $true '' '.' }
    finally { Pop-Location }
    foreach ($field in @('schema', 'mode', 'kind', 'dataMode', 'networkPolicy')) {
        $original = $m[$field]
        $m[$field] = $true; Save $base $m
        Check "boolean $field rejected" "$base/manifest.json" $false "invalid $field"
        $m[$field] = $original
    }
    Save $base $m
    $upperPath = "$base/src/Main.js"
    $caseSensitive = -not (Test-Path -LiteralPath (Join-Path $root $upperPath))
    if ($caseSensitive) { Put $upperPath 'export const app = "fixture only";' }
    $m.ownedFiles[0].path = 'src/Main.js'; Save $base $m
    Check 'ownership preserves exact path case' "$base/manifest.json" $false 'ownedFiles missing entry'
    $m.ownedFiles[0].path = 'src/main.js'
    if ($caseSensitive) { Remove-Item -LiteralPath (Join-Path $root $upperPath) }
    Save $base $m
    Put "$base/preview/unlisted.js" 'export const unlisted = true;'
    Check 'unlisted asset rejected' "$base/manifest.json" $false 'unindexed owned file'
    Remove-Item -LiteralPath (Join-Path $root "$base/preview/unlisted.js")
    $m.sourceEntry = 'src/main.js. '; Save $base $m
    Check 'Windows alias rejected' "$base/manifest.json" $false 'unsafe path'
    $m.sourceEntry = 'src/main.js'
    $m.sources[0].path = 'app/.env'; Save $base $m
    Check 'protected data rejected' "$base/manifest.json" $false 'protected data'
    $m.sources[0].path = 'app/Button.vue'
    Put 'outside/entry.js' 'fixture outside artifact'
    $junction = Join-Path $root "$base/src/linked"
    $linkType = if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { 'Junction' } else { 'SymbolicLink' }
    New-Item -ItemType $linkType -Path $junction -Target (Join-Path $root 'outside') | Out-Null
    try {
        $m.sourceEntry = 'src/linked/entry.js'; Save $base $m
        Check 'link escape rejected' "$base/manifest.json" $false 'reparse-point'
    } finally { [IO.Directory]::Delete($junction) }
    $m.sourceEntry = 'src/main.js'; Save $base $m
    $change = 'fp-docs/changes/filter/prototype'
    $c = Manifest $change 'change'
    $c.baseReference = @{ path = "$base/manifest.json"; sha256 = (Hash "$base/manifest.json") }
    Save $change $c
    Check 'valid change' "$change/manifest.json" $true
    Put 'fp-docs/changes/filter/prototype.html' '<!doctype html><title>Legacy</title>'
    Check 'dual native' "$change/manifest.json" $false 'prototype-conflict'
    Check 'dual legacy' 'fp-docs/changes/filter/prototype.html' $false 'prototype-conflict'
    Remove-Item -LiteralPath (Join-Path $root 'fp-docs/changes/filter/prototype.html')
    Put 'fp-docs/changes/legacy/prototype.html' '<!doctype html><title>Legacy</title>'
    Check 'legacy preserved' 'fp-docs/changes/legacy/prototype.html' $false

    $m.schema = 'unknown'; Save $base $m
    Check 'schema rejected' "$base/manifest.json" $false 'schema'
    $m.schema = 'fp-prototype/v1'
    $m.sourceEntry = '../../outside.js'; Save $base $m
    Check 'traversal rejected' "$base/manifest.json" $false 'unsafe path'
    $m.sourceEntry = 'src/missing.js'; Save $base $m
    Check 'missing source rejected' "$base/manifest.json" $false 'missing file'
    $m.sourceEntry = 'src/main.js'
    $m.commands.build.cwd = 'C:/outside'; Save $base $m
    Check 'absolute cwd rejected' "$base/manifest.json" $false 'unsafe path'
    $m.commands.build.cwd = 'app'
    $m.dataMode = 'real'; Save $base $m
    Check 'real data rejected' "$base/manifest.json" $false 'mock-only'
    $m.dataMode = 'mock-only'
    $m.ownedFiles = @($m.ownedFiles[0]); Save $base $m
    Check 'missing ownership rejected' "$base/manifest.json" $false 'ownedFiles'
    $m = Manifest $base 'base'; Save $base $m
    $m.verification.build = 'passed'; Save $base $m
    Check 'evidence required' "$base/manifest.json" $false 'evidence'
    $m.verification.build = 'not-run'; Save $base $m

    Put 'app/Button.vue' '<template><button>Changed</button></template>'
    Check 'stale source rejected' "$base/manifest.json" $true 'stale source'
    Check 'structure alone is not freshness' "$base/manifest.json" $false
    $m.sources[0].sha256 = Hash 'app/Button.vue'; Save $base $m
    Put "$base/src/main.js" 'user edit'
    Check 'manual edit rejected' "$base/manifest.json" $true 'owned file changed'
    Check 'changed baseline rejected' "$change/manifest.json" $true 'base revision'

    $archive = 'fp-docs/archive/2026-09-filter/prototype'
    [IO.Directory]::CreateDirectory((Split-Path -Parent (Join-Path $root $archive))) | Out-Null
    Copy-Item -LiteralPath (Join-Path $root $change) -Destination (Join-Path $root $archive) -Recurse
    Remove-Item -LiteralPath (Join-Path $root 'app') -Recurse -Force
    Check 'archive static structure survives missing source' "$archive/manifest.json" $false
    Check 'archive cannot claim rebuild freshness' "$archive/manifest.json" $true 'missing command cwd'
    Write-Host "Prototype artifact checks passed: $count cases. Fixtures do not prove Vue rendering or browser isolation."
} finally {
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
