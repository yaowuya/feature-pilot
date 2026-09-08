param(
    [Parameter(Mandatory = $true)][string]$ProjectRoot,
    [Parameter(Mandatory = $true)][string]$PrototypePath,
    [switch]$CheckFreshness
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Require([bool]$condition, [string]$message) {
    if (-not $condition) { throw "Prototype validation failed: $message" }
}
function Value([object]$object, [string]$name) {
    Require ($null -ne $object) "missing object for $name"
    $property = $object.PSObject.Properties[$name]
    Require ($null -ne $property) "missing property $name"
    return $property.Value
}
function Text([object]$value, [string]$name) {
    Require (($value -is [string]) -and -not [string]::IsNullOrWhiteSpace($value)) "invalid $name"
    return $value
}
function Safe-Path([string]$root, [object]$relative, [bool]$allowRoot = $false) {
    $p = Text $relative 'path'
    if ($allowRoot -and $p -ceq '.') { return $root }
    Require (-not [IO.Path]::IsPathRooted($p) -and $p -notmatch '[\\:*?"<>|\x00-\x1f]' -and -not $p.StartsWith('/')) "unsafe path: $p"
    $parts = $p.Split('/')
    foreach ($part in $parts) {
        Require ($part -ne '' -and $part -ne '.' -and $part -ne '..' -and $part -notmatch '[. ]$') "unsafe path: $p"
        Require ($part -notmatch '^(?i:\.env(?:\..*)?|\.git|\.ssh|\.auth)$') "unsafe path: protected data $p"
    }
    $path = $root
    foreach ($part in $parts) {
        $path = Join-Path $path $part
        if (Test-Path -LiteralPath $path) {
            $item = Get-Item -LiteralPath $path -Force
            Require (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) "unsafe path: reparse-point $p"
        }
    }
    return [IO.Path]::GetFullPath($path)
}
function File-Path([string]$root, [object]$relative) {
    $path = Safe-Path $root $relative
    Require (Test-Path -LiteralPath $path -PathType Leaf) "missing file: $relative"
    return $path
}
function Digest([object]$value) {
    Require (($value -is [string]) -and $value -cmatch '^[a-fA-F0-9]{64}$') 'invalid sha256'
    return $value.ToLowerInvariant()
}
function Read-Json([string]$path) {
    try { return [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8) | ConvertFrom-Json }
    catch { throw "Prototype validation failed: invalid JSON: $($_.Exception.Message)" }
}
function Match-Hash([string]$path, [string]$expected, [string]$message) {
    Require (Test-Path -LiteralPath $path -PathType Leaf) "$message (missing file)"
    Require ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ceq $expected) $message
}

Require (Test-Path -LiteralPath $ProjectRoot -PathType Container) 'missing project root'
$resolvedProject = Resolve-Path -LiteralPath $ProjectRoot
Require ($resolvedProject.Provider.Name -eq 'FileSystem') 'project root must be a filesystem directory'
$project = [IO.Path]::GetFullPath($resolvedProject.ProviderPath)
$path = File-Path $project $PrototypePath
if ($PrototypePath -cmatch '^fp-docs/(changes|archive)/[^/]+/prototype\.html$') {
    Require (-not (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $path) 'prototype'))) 'prototype-conflict: legacy HTML and native directory coexist'
    Write-Output 'Legacy prototype structure valid; runtime and fidelity not verified.'
    return
}
$isBase = $PrototypePath -cmatch '^fp-docs/prototype-bases/([a-z0-9]+(?:-[a-z0-9]+)*)/manifest\.json$'
$baseId = if ($isBase) { $Matches[1] } else { '' }
$isChange = $PrototypePath -cmatch '^fp-docs/(changes|archive)/[^/]+/prototype/manifest\.json$'
Require ($isBase -or $isChange) 'non-canonical prototype path'
$artifact = Split-Path -Parent $path
if ($isChange) {
    Require (-not (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $artifact) 'prototype.html'))) 'prototype-conflict: native directory and legacy HTML coexist'
}
$m = Read-Json $path
Require ((Text (Value $m 'schema') 'schema') -ceq 'fp-prototype/v1') 'unsupported schema'
Require ((Text (Value $m 'mode') 'mode') -ceq 'project-native') 'invalid mode'
$kind = Text (Value $m 'kind') 'kind'
Require (($isBase -and $kind -ceq 'base') -or ($isChange -and $kind -ceq 'change')) 'kind does not match path'
$appId = Text (Value $m 'appId') 'appId'
Require ($appId -cmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') 'invalid appId'
if ($isBase) { Require ($appId -ceq $baseId) 'appId does not match base path' }
$appRoot = Safe-Path $project (Value $m 'appRoot') $true
$framework = Value $m 'framework'
[void](Text (Value $framework 'name') 'framework name')
[void](Text (Value $framework 'version') 'framework version')
Require ((Text (Value $m 'dataMode') 'dataMode') -ceq 'mock-only') 'dataMode must be mock-only'
Require ((Text (Value $m 'networkPolicy') 'networkPolicy') -ceq 'deny-business-network') 'invalid networkPolicy'
$entries = @((Value $m 'sourceEntry'), (Value $m 'mockEntry'), (Value $m 'previewEntry'))
Require ($entries[2] -ceq 'preview/index.html') 'previewEntry must be preview/index.html'
foreach ($entry in $entries) { [void](File-Path $artifact $entry) }
$commands = Value $m 'commands'
foreach ($name in @('build', 'preview')) {
    $command = Value $commands $name
    $relativeTo = Text (Value $command 'relativeTo') 'command relativeTo'
    Require ($relativeTo -cin @('project', 'artifact')) 'invalid command relativeTo'
    $commandRoot = if ($relativeTo -ceq 'project') { $project } else { $artifact }
    $cwd = Safe-Path $commandRoot (Value $command 'cwd') $true
    [void](Text (Value $command 'run') 'command run')
    if ($CheckFreshness) { Require (Test-Path -LiteralPath $cwd -PathType Container) 'missing command cwd' }
}
$sourceRows = @(Value $m 'sources')
Require ($sourceRows.Count -gt 0) 'sources required'
$sourcePaths = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
foreach ($source in $sourceRows) {
    $sourcePath = Text (Value $source 'path') 'source path'
    Require (-not $sourcePaths.ContainsKey($sourcePath)) 'duplicate source path'
    $sourcePaths[$sourcePath] = Safe-Path $project $sourcePath
    [void](Digest (Value $source 'sha256'))
}
$owned = @(Value $m 'ownedFiles')
$ownedPaths = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
foreach ($file in $owned) {
    $relative = Text (Value $file 'path') 'owned file path'
    Require ($relative -cne 'manifest.json' -and -not $ownedPaths.ContainsKey($relative)) 'invalid ownedFiles: self or duplicate'
    $ownedPaths[$relative] = File-Path $artifact $relative
    [void](Digest (Value $file 'sha256'))
}
foreach ($entry in $entries) { Require ($ownedPaths.ContainsKey($entry)) "ownedFiles missing entry: $entry" }
$pendingDirectories = New-Object 'System.Collections.Generic.Stack[string]'
$pendingDirectories.Push($artifact)
while ($pendingDirectories.Count -gt 0) {
    foreach ($item in Get-ChildItem -LiteralPath $pendingDirectories.Pop() -Force) {
        Require (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -eq 0) 'unsafe path: reparse-point in artifact'
        if ($item.PSIsContainer) {
            if ($item.Name -notin @('node_modules', '.cache', '.vite')) { $pendingDirectories.Push($item.FullName) }
        } elseif ($item.FullName -cne $path) {
            $relative = $item.FullName.Substring($artifact.Length + 1).Replace('\', '/')
            Require ($ownedPaths.ContainsKey($relative)) "unindexed owned file: $relative"
        }
    }
}
$scenarios = @(Value $m 'scenarios')
Require ($scenarios.Count -gt 0) 'scenarios required'
$seenScenarios = @{}
foreach ($scenario in $scenarios) {
    $id = Text $scenario 'scenario'
    Require (-not $seenScenarios.ContainsKey($id)) 'duplicate scenario'
    $seenScenarios[$id] = $true
}
$verification = Value $m 'verification'
$needsEvidence = $false
foreach ($name in @('build', 'preview', 'network', 'visual')) {
    $result = Text (Value $verification $name) "verification $name"
    Require ($result -cin @('not-run', 'passed', 'blocked')) "invalid verification $name"
    if ($result -cne 'not-run') { $needsEvidence = $true }
}
$evidence = Value $verification 'evidence'
if ($needsEvidence -or $null -ne $evidence) {
    Require (-not [string]::IsNullOrWhiteSpace($evidence)) 'verification evidence required'
    [void](File-Path $artifact $evidence)
    Require ($ownedPaths.ContainsKey($evidence)) 'ownedFiles missing evidence'
}
$base = Value $m 'baseReference'
if ($isBase) { Require ($null -eq $base) 'baseReference must be null for base' }
else {
    $basePath = Value $base 'path'
    Require ($basePath -ceq "fp-docs/prototype-bases/$appId/manifest.json") 'invalid baseReference path'
    $baseFullPath = Safe-Path $project $basePath
    $baseHash = Digest (Value $base 'sha256')
    if ($CheckFreshness) { Match-Hash $baseFullPath $baseHash 'base revision changed' }
}
if ($CheckFreshness) {
    Require (Test-Path -LiteralPath $appRoot -PathType Container) 'missing appRoot'
    foreach ($source in $sourceRows) { Match-Hash $sourcePaths[$source.path] (Digest $source.sha256) "stale source: $($source.path)" }
    foreach ($file in $owned) { Match-Hash $ownedPaths[$file.path] (Digest $file.sha256) "owned file changed: $($file.path)" }
}
Write-Output 'Native prototype structure valid; commands not executed; build, network isolation and fidelity require separate evidence.'
