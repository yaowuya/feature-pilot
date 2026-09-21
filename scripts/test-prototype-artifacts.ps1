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
function StaticManifest([string]$folder, [string]$kind, [string]$appId = 'static-app') {
    Put "$folder/css/tokens.css" ':root { --fixture: 1; }'
    Put "$folder/js/guard.js" 'window.__FP_PROTOTYPE__ = { dataMode: "mock-only" };'
    Put "$folder/js/components.js" 'window.render = function () { return "fixture"; };'
    Put "$folder/examples/index.html" '<!doctype html><title>Fixture</title><script src="../js/guard.js"></script><script src="../js/components.js"></script>'
    Put "$folder/evidence/verification.md" '# Fixture verification'
    $owned = @('css/tokens.css', 'js/guard.js', 'js/components.js', 'examples/index.html', 'evidence/verification.md')
    return [ordered]@{
        schema = 'fp-prototype/v1'; kind = $kind; mode = 'static-modular'; appId = $appId; appRoot = 'app'
        delivery = 'no-build'; entry = 'examples/index.html'
        commands = @{ build = $null; preview = @{ relativeTo = 'artifact'; cwd = '.'; run = 'DO-NOT-EXECUTE preview' } }
        componentMap = @(@{ source = 'bk-button'; static = '.fixture-button' })
        sources = @(@{ path = 'app/Button.vue'; sha256 = (Hash 'app/Button.vue') })
        ownedFiles = $owned | ForEach-Object { @{ path = $_; sha256 = (Hash "$folder/$_") } }
        dataMode = 'mock-only'; networkPolicy = 'deny-business-network'
        scenarios = @('default')
        verification = @{ structure = 'not-run'; preview = 'not-run'; network = 'not-run'; visual = 'not-run'; evidence = 'evidence/verification.md' }
        directOpen = @{ relativeTo = 'artifact'; path = 'examples/index.html'; protocol = 'file' }
        scriptOrder = @('js/guard.js', 'js/components.js')
    }
}
function StaticChange([string]$folder, [string]$baseRelative, [string]$appId = 'static-app') {
    $manifest = StaticManifest $folder 'change' $appId
    Put "$folder/src/app.js" 'window.renderPage = function () { return "fixture"; };'
    Put "$folder/mocks/data.js" 'window.MOCKS = [];'
    Put "$folder/preview/index.html" '<!doctype html><title>Fixture change</title><script src="../js/guard.js"></script><script src="../js/components.js"></script><script src="../src/app.js"></script>'
    $manifest.entry = 'preview/index.html'
    $manifest.sourceEntry = 'src/app.js'
    $manifest.mockEntry = 'mocks/data.js'
    $manifest.previewEntry = 'preview/index.html'
    $manifest.baseReference = @{ path = $baseRelative; sha256 = (Hash $baseRelative) }
    $manifest.scriptOrder = @('js/guard.js', 'js/components.js', 'src/app.js')
    $extra = @('src/app.js', 'mocks/data.js', 'preview/index.html')
    $manifest.ownedFiles = @($manifest.ownedFiles) + @($extra | ForEach-Object { @{ path = $_; sha256 = (Hash "$folder/$_") } })
    $manifest.directOpen = @{ relativeTo = 'artifact'; path = 'preview/index.html'; protocol = 'file' }
    return $manifest
}
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

    $sbase = 'fp-docs/prototype-bases/static-app'
    $sm = StaticManifest $sbase 'base'
    Save $sbase $sm
    Check 'valid static base with no baseReference key' "$sbase/manifest.json" $true
    $sm.schema = 'fp-static-prototype/v1'; Save $sbase $sm
    Check 'unmigrated static schema rejected' "$sbase/manifest.json" $false 'unsupported schema'
    $sm.schema = 'fp-prototype/v1'
    $sm.delivery = 'build'; Save $sbase $sm
    Check 'built static mode rejected' "$sbase/manifest.json" $false 'delivery must be no-build'
    $sm.delivery = 'no-build'
    $sm.commands.build = @{ relativeTo = 'artifact'; cwd = '.'; run = 'DO-NOT-EXECUTE build' }; Save $sbase $sm
    Check 'static build command rejected' "$sbase/manifest.json" $false 'build command must be null'
    $sm.commands.build = $null
    $sm.framework = @{ name = 'vue'; version = '3.5.0' }; Save $sbase $sm
    Check 'static base tolerates framework absence check' "$sbase/manifest.json" $true
    $sm.Remove('framework')
    $compact = $sm.scriptOrder
    $sm.scriptOrder = @('js/components.js', 'js/guard.js'); Save $sbase $sm
    Check 'network guard must load first' "$sbase/manifest.json" $false 'network guard must be the first scriptOrder entry'
    $sm.scriptOrder = $compact
    $sm.scriptOrder = @('js/guard.js', 'js/guard.js'); Save $sbase $sm
    Check 'duplicate scriptOrder rejected' "$sbase/manifest.json" $false 'duplicate scriptOrder entry'
    $sm.scriptOrder = $compact
    Put "$sbase/js/loose.js" 'window.loose = true;'
    $sm.scriptOrder = @('js/guard.js', 'js/loose.js'); Save $sbase $sm
    Check 'unowned scriptOrder entry rejected' "$sbase/manifest.json" $false 'ownedFiles missing entry: js/loose.js'
    Remove-Item -LiteralPath (Join-Path $root "$sbase/js/loose.js")
    $sm.scriptOrder = $compact
    Save $sbase $sm
    $guardBackup = [IO.File]::ReadAllText((Join-Path $root "$sbase/js/components.js"))
    Put "$sbase/js/components.js" 'import { x } from "./guard.js";'
    Check 'module syntax breaks direct open' "$sbase/manifest.json" $false 'module syntax breaks direct file open'
    [IO.File]::WriteAllText((Join-Path $root "$sbase/js/components.js"), $guardBackup, $utf8)
    $entryBackup = [IO.File]::ReadAllText((Join-Path $root "$sbase/examples/index.html"))
    Put "$sbase/examples/index.html" '<!doctype html><script type="module" src="../js/guard.js"></script>'
    Check 'module script tag breaks direct open' "$sbase/manifest.json" $false 'module script breaks direct file open'
    [IO.File]::WriteAllText((Join-Path $root "$sbase/examples/index.html"), $entryBackup, $utf8)
    $sm.directOpen.protocol = 'http'; Save $sbase $sm
    Check 'non-file directOpen rejected' "$sbase/manifest.json" $false 'invalid directOpen protocol'
    $sm.directOpen.protocol = 'file'
    $sm.directOpen.path = 'examples/missing.html'; Save $sbase $sm
    Check 'missing directOpen path rejected' "$sbase/manifest.json" $false 'missing file'
    $sm.directOpen.path = 'examples/index.html'
    $sm.entry = 'examples/missing.html'; Save $sbase $sm
    Check 'missing static entry rejected' "$sbase/manifest.json" $false 'missing file'
    $sm.entry = 'examples/index.html'
    $componentBackup = $sm.componentMap
    $sm.Remove('componentMap'); Save $sbase $sm
    Check 'static base without componentMap rejected' "$sbase/manifest.json" $false 'missing property componentMap'
    $sm.componentMap = @(@{ source = ''; static = '.x' }); Save $sbase $sm
    Check 'empty componentMap source rejected' "$sbase/manifest.json" $false 'invalid componentMap source'
    $sm.componentMap = $componentBackup
    Save $sbase $sm
    Check 'static base restored' "$sbase/manifest.json" $true

    $schange = 'fp-docs/changes/static-filter/prototype'
    $sc = StaticChange $schange "$sbase/manifest.json"
    Save $schange $sc
    Check 'valid static change' "$schange/manifest.json" $true
    $sc.Remove('baseReference'); Save $schange $sc
    Check 'static change without baseReference rejected' "$schange/manifest.json" $false 'missing property baseReference'
    $sc.baseReference = @{ path = "$sbase/manifest.json"; sha256 = (Hash "$sbase/manifest.json") }
    $sc.Remove('sourceEntry'); Save $schange $sc
    Check 'static change without sourceEntry rejected' "$schange/manifest.json" $false 'missing property sourceEntry'
    $sc.sourceEntry = 'src/app.js'
    Save $schange $sc
    Check 'static change restored' "$schange/manifest.json" $true
    $sm.entry = 'examples/index.html. '; Save $sbase $sm
    Check 'static entry alias rejected' "$sbase/manifest.json" $false 'unsafe path'
    $sm.entry = 'examples/index.html'; Save $sbase $sm
    [IO.File]::AppendAllText((Join-Path $root "$sbase/js/guard.js"), "`n// drift", $utf8)
    Check 'static owned drift rejected' "$sbase/manifest.json" $true 'owned file changed'
    $sm.scenarios = @('default', 'empty'); Save $sbase $sm
    Check 'static base revision changed' "$schange/manifest.json" $true 'base revision changed'

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
