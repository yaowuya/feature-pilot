<#
.SYNOPSIS
Installs the local FeaturePilot Cursor plugin without overwriting human edits.
.DESCRIPTION
Only the four packaged resource roots are managed. An existing managed install
must still match its recorded hashes before replacement; unknown files survive.
VerifyOnly performs no filesystem writes. Failed staging leaves the install intact.
#>
[CmdletBinding()]
param(
    [string]$PluginRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$CursorHome = (Join-Path ([Environment]::GetFolderPath('UserProfile')) '.cursor'),
    [switch]$VerifyOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$utf8 = New-Object Text.UTF8Encoding($false)
$markerName = '.featurepilot-install.json'
$packageRoots = @('.cursor-plugin', 'skills', 'scripts', 'adapters/cursor')
$requiredResources = @('skills/_shared/workspace-rules.md', 'skills/_shared/engineering-quality.md', 'adapters/cursor/rules/featurepilot.mdc')
$excludedDirectories = @('.git', '.agents', '.claude', '.codex', 'node_modules', '__pycache__', '.pytest_cache')

function Get-AbsolutePath([string]$Path) {
    # Normalize before containment checks, including paths not yet on disk.
    if ([string]::IsNullOrWhiteSpace($Path)) { throw 'A filesystem path is required.' }
    $full = [IO.Path]::GetFullPath($Path)
    if ($full -eq [IO.Path]::GetPathRoot($full)) { return $full }
    return $full.TrimEnd([char[]]'\/')
}

function Test-Within([string]$Path, [string]$Root) {
    return $Path.StartsWith($Root.TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)
}

function Assert-NoReparse([string]$Path) {
    # Check ancestors too: a safe-looking child can otherwise enter a junction.
    $current = Get-AbsolutePath $Path
    while ($current) {
        $item = Get-Item -LiteralPath $current -Force -ErrorAction SilentlyContinue
        if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Reparse points are not supported: $current"
        }
        $parent = Split-Path -Parent $current
        if ($parent -eq $current) { break }
        $current = $parent
    }
}

function Get-TreeFiles([string]$Root, [switch]$Package) {
    # Enumerate one directory at a time so links are rejected before traversal.
    Assert-NoReparse $Root
    $files = @{}
    $pending = New-Object 'Collections.Generic.Stack[string]'
    $pending.Push($Root)
    while ($pending.Count) {
        foreach ($item in Get-ChildItem -LiteralPath $pending.Pop() -Force) {
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Reparse points are not supported: $($item.FullName)"
            }
            if ($item.PSIsContainer) {
                if (-not $Package -or $excludedDirectories -notcontains $item.Name) { $pending.Push($item.FullName) }
            } else {
                $relative = $item.FullName.Substring($Root.Length + 1).Replace('\', '/')
                $files[$relative] = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
            }
        }
    }
    return $files
}

function Get-OwnedPath([string]$Root, [string]$Relative) {
    # Management metadata is untrusted input; never let it select another plugin.
    if ($Relative -notmatch '^(\.cursor-plugin|skills|scripts|adapters/cursor)/' -or
        $Relative -match '[\\:]' -or ($Relative.Split('/') | Where-Object { $_ -in @('', '.', '..') -or $_ -match '[. ]$' })) {
        throw "Unsafe managed path: $Relative"
    }
    $path = Get-AbsolutePath (Join-Path $Root $Relative)
    if (-not (Test-Within $path $Root)) { throw "Managed path escapes target: $Relative" }
    Assert-NoReparse $path
    return $path
}

function Assert-Manifest([string]$Path) {
    # Cursor's local package must identify fp and resolve only its bundled roots.
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing Cursor manifest: $Path" }
    # PS 5.1 otherwise reads BOM-less UTF-8 as ANSI, corrupting non-ASCII JSON.
    $manifest = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($name in @('name', 'skills', 'rules', 'commands')) {
        if ($manifest.PSObject.Properties.Name -notcontains $name) { throw "Invalid Cursor manifest: missing $name" }
    }
    if ($manifest.name -cne 'fp' -or $manifest.skills -cne './skills/' -or
        $manifest.rules -cne './adapters/cursor/rules/' -or $null -eq $manifest.commands -or
        $manifest.commands -isnot [Array] -or @($manifest.commands).Count -ne 0) {
        throw "Invalid Cursor manifest identity or resource paths: $Path"
    }
}

function Copy-Resource([string]$From, [string]$To) {
    # Preserve bytes; do not rewrite shared skills for a particular runtime.
    Assert-NoReparse $From
    Assert-NoReparse $To
    [IO.Directory]::CreateDirectory((Split-Path -Parent $To)) | Out-Null
    Copy-Item -LiteralPath $From -Destination $To -Force
}

$source = Get-AbsolutePath $PluginRoot
$cursor = Get-AbsolutePath $CursorHome
$plugins = Get-AbsolutePath (Join-Path $cursor 'plugins')
$local = Get-AbsolutePath (Join-Path $plugins 'local')
$target = Get-AbsolutePath (Join-Path $local 'fp')
if ($source -eq $plugins -or (Test-Within $source $plugins) -or (Test-Within $plugins $source)) {
    throw 'Source and Cursor plugin paths overlap.'
}
Assert-NoReparse $source
Assert-NoReparse $target
Assert-Manifest (Join-Path $source '.cursor-plugin/plugin.json')
$desired = @{}
foreach ($root in $packageRoots) {
    $path = Join-Path $source $root
    if (-not (Test-Path -LiteralPath $path -PathType Container)) { throw "Missing package directory: $root" }
    $files = Get-TreeFiles $path -Package
    foreach ($relative in $files.Keys) {
        $key = "$root/$relative"
        $null = Get-OwnedPath $source $key
        $desired[$key] = $files[$relative]
    }
}
if (-not @($desired.Keys | Where-Object { $_ -match '^skills/[^/]+/SKILL\.md$' }).Count) { throw 'Missing skill entrypoint.' }
# Bootstrap references are fixed: an incomplete update must not remove contracts
# from a working install merely because some unrelated skill or rule still exists.
foreach ($relative in $requiredResources) {
    if (-not $desired.ContainsKey($relative)) { throw "Missing required Cursor resource: $relative" }
}

$installed = @{}
$owned = @{}
$marker = Join-Path $target $markerName
if (Test-Path -LiteralPath $target) {
    if (-not (Test-Path -LiteralPath $target -PathType Container)) { throw 'Cursor fp target is not a directory.' }
    $installed = Get-TreeFiles $target
    if (Test-Path -LiteralPath $marker -PathType Leaf) {
        # The marker is written as UTF-8 without BOM; preserve Unicode owned paths.
        $state = Get-Content -LiteralPath $marker -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($state.schemaVersion -ne 1 -or $state.plugin -cne 'fp' -or -not @($state.files).Count) { throw 'Invalid install management marker.' }
        foreach ($file in $state.files) {
            $null = Get-OwnedPath $target $file.path
            if ($owned.ContainsKey($file.path) -or $file.sha256 -notmatch '^[a-fA-F0-9]{64}$') { throw 'Invalid managed file record.' }
            $owned[$file.path] = $file.sha256
        }
        if (-not $owned.ContainsKey('.cursor-plugin/plugin.json')) { throw 'Management marker does not own the Cursor manifest.' }
        if ($installed.ContainsKey('.cursor-plugin/plugin.json')) { Assert-Manifest (Join-Path $target '.cursor-plugin/plugin.json') }
    } elseif (@(Get-ChildItem -LiteralPath $target -Force).Count) {
        throw 'Refusing to take over a nonempty fp directory without a management marker.'
    }
}

$differences = New-Object 'Collections.Generic.List[string]'
foreach ($relative in ($desired.Keys | Sort-Object)) {
    if (-not $installed.ContainsKey($relative)) { $differences.Add("missing: $relative") }
    elseif ($installed[$relative] -ne $desired[$relative]) { $differences.Add("changed: $relative") }
    elseif (-not $owned.ContainsKey($relative)) { $differences.Add("unmanaged: $relative") }
}
foreach ($relative in ($owned.Keys | Sort-Object)) {
    if (-not $desired.ContainsKey($relative)) { $differences.Add("stale: $relative") }
    if (-not $installed.ContainsKey($relative) -or $installed[$relative] -ne $owned[$relative]) {
        if (-not $VerifyOnly) { throw "Managed file was changed or removed; refusing overwrite: $relative" }
        $differences.Add("changed managed record: $relative")
    }
}
if ($VerifyOnly) {
    if (-not (Test-Path -LiteralPath $marker -PathType Leaf)) { $differences.Add("missing: $markerName") }
    if ($differences.Count) { throw ("Cursor fp verification failed:`n" + ($differences -join "`n")) }
    Write-Host "Cursor fp verified: $target ($($desired.Count) managed files)."
    return
}

# Unknown content is retained, but may not be silently claimed by a new version.
foreach ($relative in $desired.Keys) {
    foreach ($unknown in @($installed.Keys | Where-Object { $_ -ne $markerName -and -not $owned.ContainsKey($_) })) {
        if ($relative -eq $unknown -or $relative.StartsWith($unknown + '/', [StringComparison]::OrdinalIgnoreCase) -or
            $unknown.StartsWith($relative + '/', [StringComparison]::OrdinalIgnoreCase)) { throw "New resource conflicts with unknown file: $unknown" }
    }
    if (Test-Path -LiteralPath (Get-OwnedPath $target $relative) -PathType Container) { throw "Resource conflicts with existing directory: $relative" }
}

$stage = Join-Path $plugins ('.fp-stage-' + [guid]::NewGuid().ToString('N'))
$backup = Join-Path $plugins ('.fp-backup-' + [guid]::NewGuid().ToString('N'))
function Assert-ManagedLocation([string]$Path) {
    # Restrict recursive moves/removals to the exact fp target and this run's temps.
    $resolved = Get-AbsolutePath $Path
    if ($resolved -notin @($target, $stage, $backup) -or -not (Test-Within $resolved $plugins)) { throw "Unsafe operation path: $resolved" }
    Assert-NoReparse $resolved
    if (Test-Path -LiteralPath $resolved -PathType Container) { $null = Get-TreeFiles $resolved }
}

$moved = $false
$published = $false
try {
    Assert-NoReparse $plugins
    [IO.Directory]::CreateDirectory($plugins) | Out-Null
    [IO.Directory]::CreateDirectory($stage) | Out-Null
    foreach ($relative in $installed.Keys) {
        if ($relative -ne $markerName -and -not $owned.ContainsKey($relative)) {
            Copy-Resource (Join-Path $target $relative) (Join-Path $stage $relative)
        }
    }
    foreach ($relative in $desired.Keys) {
        $destination = Get-OwnedPath $stage $relative
        Copy-Resource (Get-OwnedPath $source $relative) $destination
        if ((Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne $desired[$relative]) { throw "Source changed while staging: $relative" }
    }
    $records = @($desired.Keys | Sort-Object | ForEach-Object { [ordered]@{ path = $_; sha256 = $desired[$_] } })
    $state = [ordered]@{ schemaVersion = 1; plugin = 'fp'; files = $records }
    [IO.File]::WriteAllText((Join-Path $stage $markerName), ($state | ConvertTo-Json -Depth 5), $utf8)
    Assert-Manifest (Join-Path $stage '.cursor-plugin/plugin.json')
    # Recheck the original snapshot immediately before swapping, including unknown files.
    if (Test-Path -LiteralPath $target) {
        $current = Get-TreeFiles $target
        if ($current.Count -ne $installed.Count) { throw 'Install changed during staging.' }
        foreach ($relative in $installed.Keys) {
            if (-not $current.ContainsKey($relative) -or $current[$relative] -ne $installed[$relative]) { throw "Install changed during staging: $relative" }
        }
        Assert-ManagedLocation $target
        Assert-ManagedLocation $backup
        Move-Item -LiteralPath $target -Destination $backup
        $moved = $true
    }
    Assert-NoReparse $local
    [IO.Directory]::CreateDirectory($local) | Out-Null
    Assert-ManagedLocation $stage
    Assert-ManagedLocation $target
    Move-Item -LiteralPath $stage -Destination $target
    $published = $true
} catch {
    if ($moved -and -not $published -and -not (Test-Path -LiteralPath $target)) {
        Assert-ManagedLocation $backup
        Assert-ManagedLocation $target
        Move-Item -LiteralPath $backup -Destination $target
    }
    throw
} finally {
    if (Test-Path -LiteralPath $stage) {
        Assert-ManagedLocation $stage
        Remove-Item -LiteralPath $stage -Recurse -Force
    }
    if ($published -and (Test-Path -LiteralPath $backup)) {
        Assert-ManagedLocation $backup
        Remove-Item -LiteralPath $backup -Recurse -Force
    }
}
Write-Host "Cursor fp installed: $target ($($desired.Count) managed files). Restart Cursor to reload the local plugin."
