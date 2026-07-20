[CmdletBinding()]
param(
    [string]$PluginRoot,
    [string]$CodexMarketplace = 'personal',
    [string]$ClaudeMarketplace = 'fp-dev',
    [switch]$VerifyOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$excludedTopLevelNames = @('.git', '.agents', '.claude', '.worktrees')
$coreFiles = @('.claude-plugin\plugin.json', '.codex-plugin\plugin.json')
$coreDirectories = @('commands', 'skills')

function Get-FullPath {
    param([Parameter(Mandatory)][string]$Path)
    return [System.IO.Path]::GetFullPath($Path).TrimEnd([char[]]'\/')
}

function Test-SamePath {
    param(
        [Parameter(Mandatory)][string]$Left,
        [Parameter(Mandatory)][string]$Right
    )

    return [string]::Equals((Get-FullPath $Left), (Get-FullPath $Right), [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-ChildPath {
    param(
        [Parameter(Mandatory)][string]$Parent,
        [Parameter(Mandatory)][string]$Child
    )

    $parentPath = (Get-FullPath $Parent) + [System.IO.Path]::DirectorySeparatorChar
    $childPath = Get-FullPath $Child
    return $childPath.StartsWith($parentPath, [System.StringComparison]::OrdinalIgnoreCase)
}

function Read-JsonFile {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required JSON file is missing: $Path"
    }

    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
}

function Invoke-ExternalCommand {
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    if (-not (Get-Command $FilePath -ErrorAction SilentlyContinue)) {
        throw "Required command is unavailable: $FilePath"
    }

    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $captured = @(& $FilePath @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $text = ($captured | ForEach-Object { $_.ToString() }) -join "`n"
    if ($exitCode -ne 0) {
        throw "Command failed ($exitCode): $FilePath $($Arguments -join ' ')`n$text"
    }

    if ($text) {
        Write-Verbose $text
    }
    return $text
}

function Get-CoreFileMap {
    param([Parameter(Mandatory)][string]$Root)

    $resolvedRoot = Get-FullPath $Root
    $paths = New-Object System.Collections.Generic.List[string]

    foreach ($relativePath in $coreFiles) {
        $path = Join-Path $resolvedRoot $relativePath
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "Core plugin file is missing: $path"
        }
        $paths.Add((Get-FullPath $path))
    }

    foreach ($relativeDirectory in $coreDirectories) {
        $directory = Join-Path $resolvedRoot $relativeDirectory
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
            throw "Core plugin directory is missing: $directory"
        }
        foreach ($file in Get-ChildItem -LiteralPath $directory -Recurse -File) {
            $paths.Add((Get-FullPath $file.FullName))
        }
    }

    $map = @{}
    foreach ($path in $paths) {
        $relative = $path.Substring($resolvedRoot.Length).TrimStart([char[]]'\/').Replace('\', '/')
        $map[$relative] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    return $map
}

function Get-CoreDifferences {
    param(
        [Parameter(Mandatory)][hashtable]$Expected,
        [Parameter(Mandatory)][hashtable]$Actual
    )

    $differences = New-Object System.Collections.Generic.List[string]
    foreach ($key in @($Expected.Keys | Sort-Object)) {
        if (-not $Actual.ContainsKey($key)) {
            $differences.Add("missing: $key")
        }
        elseif ($Expected[$key] -ne $Actual[$key]) {
            $differences.Add("hash mismatch: $key")
        }
    }
    foreach ($key in @($Actual.Keys | Sort-Object)) {
        if (-not $Expected.ContainsKey($key)) {
            $differences.Add("unexpected: $key")
        }
    }
    return $differences.ToArray()
}

function Assert-CoreMatches {
    param(
        [Parameter(Mandatory)][hashtable]$Expected,
        [Parameter(Mandatory)][string]$ActualRoot,
        [Parameter(Mandatory)][string]$Label
    )

    $actual = Get-CoreFileMap $ActualRoot
    $differences = @(Get-CoreDifferences -Expected $Expected -Actual $actual)
    if ($differences.Count -gt 0) {
        throw "$Label does not match the repository:`n - $($differences -join "`n - ")"
    }
}

function Get-PluginIdentity {
    param([Parameter(Mandatory)][string]$Root)

    $claudeManifest = Read-JsonFile (Join-Path $Root '.claude-plugin\plugin.json')
    $codexManifest = Read-JsonFile (Join-Path $Root '.codex-plugin\plugin.json')
    $codexBaseVersion = ([string]$codexManifest.version -split '\+', 2)[0]
    if ([string]$claudeManifest.name -ne [string]$codexManifest.name) {
        throw 'Claude Code and Codex plugin names differ.'
    }
    if ([string]$claudeManifest.version -ne $codexBaseVersion) {
        throw 'Claude Code and Codex base versions differ.'
    }

    return [pscustomobject]@{
        Name = [string]$claudeManifest.name
        ClaudeVersion = [string]$claudeManifest.version
        CodexVersion = [string]$codexManifest.version
    }
}

function Assert-PluginRootIdentity {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$ExpectedName,
        [Parameter(Mandatory)][string]$ManifestRelativePath
    )

    $manifestPath = Join-Path $Root $ManifestRelativePath
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        return $false
    }
    $manifest = Read-JsonFile $manifestPath
    return [string]$manifest.name -eq $ExpectedName
}

function Resolve-CodexSource {
    param(
        [Parameter(Mandatory)][string]$MarketplaceFile,
        [Parameter(Mandatory)][string]$MarketplaceName,
        [Parameter(Mandatory)][string]$PluginName,
        [Parameter(Mandatory)][string]$RepositoryRoot
    )

    $marketplace = Read-JsonFile $MarketplaceFile
    if ([string]$marketplace.name -ne $MarketplaceName) {
        throw "Codex marketplace name mismatch in $MarketplaceFile"
    }
    $matches = @($marketplace.plugins | Where-Object { [string]$_.name -eq $PluginName })
    if ($matches.Count -ne 1) {
        throw "Codex target identity is ambiguous for $PluginName@$MarketplaceName"
    }
    if ([string]$matches[0].source.source -ne 'local') {
        throw 'Codex plugin source is not local.'
    }

    $configuredPath = [string]$matches[0].source.path
    $candidates = New-Object System.Collections.Generic.List[string]
    if ([System.IO.Path]::IsPathRooted($configuredPath)) {
        $candidates.Add((Get-FullPath $configuredPath))
    }
    else {
        $trimmed = $configuredPath -replace '^[.][\\/]', ''
        $candidates.Add((Get-FullPath (Join-Path $HOME $trimmed)))
        $candidates.Add((Get-FullPath (Join-Path (Split-Path -Parent $MarketplaceFile) $trimmed)))
    }

    $valid = @($candidates | Select-Object -Unique | Where-Object {
        (Test-Path -LiteralPath $_ -PathType Container) -and
        (Assert-PluginRootIdentity -Root $_ -ExpectedName $PluginName -ManifestRelativePath '.codex-plugin\plugin.json')
    })
    if ($valid.Count -ne 1) {
        throw "Codex target identity cannot be resolved uniquely from marketplace path: $configuredPath"
    }

    $target = Get-FullPath $valid[0]
    if ((Test-SamePath $target $RepositoryRoot) -or (Test-ChildPath $target $RepositoryRoot) -or (Test-ChildPath $RepositoryRoot $target)) {
        throw "Unsafe Codex source relationship: repository=$RepositoryRoot target=$target"
    }
    return $target
}

function Assert-NoProjectSkillLeak {
    param([Parameter(Mandatory)][string]$CodexSource)

    foreach ($relativePath in @(
        '.agents\skills\sync-plugin-runtimes'
        '.claude\skills\sync-plugin-runtimes'
    )) {
        if (Test-Path -LiteralPath (Join-Path $CodexSource $relativePath)) {
            throw "Project-local sync skill leaked into Codex plugin source; refusing to delete it automatically: $relativePath"
        }
    }
}

function Sync-CodexSource {
    param(
        [Parameter(Mandatory)][string]$RepositoryRoot,
        [Parameter(Mandatory)][string]$CodexSource,
        [Parameter(Mandatory)][string]$PluginName
    )

    if (-not (Assert-PluginRootIdentity -Root $CodexSource -ExpectedName $PluginName -ManifestRelativePath '.codex-plugin\plugin.json')) {
        throw "Codex target identity changed before synchronization: $CodexSource"
    }
    Assert-NoProjectSkillLeak $CodexSource

    $entries = @(Get-ChildItem -LiteralPath $RepositoryRoot -Force | Where-Object { $_.Name -notin $excludedTopLevelNames })
    foreach ($entry in $entries) {
        $destination = Join-Path $CodexSource $entry.Name
        if (-not (Test-ChildPath $CodexSource $destination)) {
            throw "Refusing to write outside Codex source: $destination"
        }
        if (Test-Path -LiteralPath $destination) {
            Remove-Item -LiteralPath $destination -Recurse -Force
        }
        Copy-Item -LiteralPath $entry.FullName -Destination $destination -Recurse -Force
    }
    Assert-NoProjectSkillLeak $CodexSource
}

function Resolve-ClaudeInstallation {
    param(
        [Parameter(Mandatory)][string]$MarketplaceFile,
        [Parameter(Mandatory)][string]$InstalledFile,
        [Parameter(Mandatory)][string]$MarketplaceName,
        [Parameter(Mandatory)][string]$PluginName,
        [Parameter(Mandatory)][string]$RepositoryRoot
    )

    $marketplaces = Read-JsonFile $MarketplaceFile
    $marketplaceProperty = $marketplaces.PSObject.Properties[$MarketplaceName]
    if ($null -eq $marketplaceProperty) {
        throw "Claude marketplace is missing: $MarketplaceName"
    }
    $source = $marketplaceProperty.Value.source
    if ([string]$source.source -ne 'directory') {
        throw "Claude marketplace is not a directory source: $MarketplaceName"
    }
    if (-not (Test-SamePath ([string]$source.path) $RepositoryRoot)) {
        throw "Claude target identity does not point to this repository: $MarketplaceName"
    }

    $selector = "$PluginName@$MarketplaceName"
    $installed = Read-JsonFile $InstalledFile
    $installedProperty = $installed.plugins.PSObject.Properties[$selector]
    if ($null -eq $installedProperty) {
        throw "Claude plugin is not installed: $selector"
    }
    $records = @($installedProperty.Value)
    if ($records.Count -ne 1) {
        throw "Claude target identity is ambiguous across installation scopes: $selector"
    }
    $record = $records[0]
    $installPath = Get-FullPath ([string]$record.installPath)
    if (-not (Assert-PluginRootIdentity -Root $installPath -ExpectedName $PluginName -ManifestRelativePath '.claude-plugin\plugin.json')) {
        throw "Claude cache identity mismatch: $installPath"
    }

    return [pscustomobject]@{
        Selector = $selector
        Scope = [string]$record.scope
        InstallPath = $installPath
        Version = [string]$record.version
        GitCommitSha = [string]$record.gitCommitSha
    }
}

function Get-ClaudeStatus {
    param([Parameter(Mandatory)][string]$Selector)

    $output = Invoke-ExternalCommand -FilePath 'claude' -Arguments @('plugin', 'list')
    $blockPattern = '(?ms)^\s*[^\r\nA-Za-z0-9._-]*(?<selector>[A-Za-z0-9._-]+@[A-Za-z0-9._-]+)\s*\r?\n(?<body>.*?)(?=^\s*[^\r\nA-Za-z0-9._-]*[A-Za-z0-9._-]+@[A-Za-z0-9._-]+\s*\r?$|\z)'
    $matches = @([regex]::Matches($output, $blockPattern) | Where-Object {
        $_.Groups['selector'].Value.Trim() -eq $Selector
    })
    if ($matches.Count -ne 1) {
        throw "Claude plugin status is missing or ambiguous: $Selector"
    }
    $statusMatch = [regex]::Match($matches[0].Groups['body'].Value, '(?m)^\s*Status:\s+.*?\b(?<status>enabled|disabled)\s*$')
    if (-not $statusMatch.Success) {
        throw "Claude plugin enabled state is missing: $Selector"
    }
    return $statusMatch.Groups['status'].Value
}

function Get-CodexStatus {
    param([Parameter(Mandatory)][string]$Selector)

    $output = Invoke-ExternalCommand -FilePath 'codex' -Arguments @('plugin', 'list')
    $pattern = '(?m)^\s*' + [regex]::Escape($Selector) + '\s+(?<status>installed,\s+(?:enabled|disabled)|not installed)\b'
    $match = [regex]::Match($output, $pattern)
    if (-not $match.Success) {
        throw "Codex plugin status is missing or ambiguous: $Selector"
    }
    return $match.Groups['status'].Value
}

function Get-CodexCachePath {
    param(
        [Parameter(Mandatory)][string]$MarketplaceName,
        [Parameter(Mandatory)][string]$PluginName,
        [Parameter(Mandatory)][string]$Version
    )

    $codexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
    $path = Get-FullPath (Join-Path $codexHome "plugins\cache\$MarketplaceName\$PluginName\$Version")
    if (-not (Assert-PluginRootIdentity -Root $path -ExpectedName $PluginName -ManifestRelativePath '.codex-plugin\plugin.json')) {
        throw "Codex cache identity mismatch or cache is missing: $path"
    }
    return $path
}

$repositoryRoot = if ($PluginRoot) {
    Get-FullPath $PluginRoot
}
else {
    Get-FullPath (Join-Path $PSScriptRoot '..\..\..\..')
}

$identity = Get-PluginIdentity $repositoryRoot
$repoMap = Get-CoreFileMap $repositoryRoot
$codexMarketplaceFile = Join-Path $HOME '.agents\plugins\marketplace.json'
$claudeMarketplaceFile = Join-Path $HOME '.claude\plugins\known_marketplaces.json'
$claudeInstalledFile = Join-Path $HOME '.claude\plugins\installed_plugins.json'
$codexSelector = "$($identity.Name)@$CodexMarketplace"

# Preflight every target identity before any mutation.
$codexSource = Resolve-CodexSource -MarketplaceFile $codexMarketplaceFile -MarketplaceName $CodexMarketplace -PluginName $identity.Name -RepositoryRoot $repositoryRoot
$claudeState = Resolve-ClaudeInstallation -MarketplaceFile $claudeMarketplaceFile -InstalledFile $claudeInstalledFile -MarketplaceName $ClaudeMarketplace -PluginName $identity.Name -RepositoryRoot $repositoryRoot
Assert-NoProjectSkillLeak $codexSource
if ((Get-ClaudeStatus $claudeState.Selector) -ne 'enabled') {
    throw "Claude plugin is disabled; refusing to change its enabled state implicitly: $($claudeState.Selector)"
}

Invoke-ExternalCommand -FilePath 'powershell' -Arguments @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $repositoryRoot 'scripts\validate-plugin.ps1')) | Out-Null
Invoke-ExternalCommand -FilePath 'claude' -Arguments @('plugin', 'validate', $repositoryRoot) | Out-Null

if ($VerifyOnly) {
    Assert-CoreMatches -Expected $repoMap -ActualRoot $codexSource -Label 'Codex plugin source'
    $codexCache = Get-CodexCachePath -MarketplaceName $CodexMarketplace -PluginName $identity.Name -Version $identity.CodexVersion
    Assert-CoreMatches -Expected $repoMap -ActualRoot $codexCache -Label 'Codex cache'
    Assert-CoreMatches -Expected $repoMap -ActualRoot $claudeState.InstallPath -Label 'Claude cache'
    if ((Get-CodexStatus $codexSelector) -ne 'installed, enabled') {
        throw "Codex plugin is not enabled: $codexSelector"
    }
}
else {
    # claude plugin marketplace update
    Invoke-ExternalCommand -FilePath 'claude' -Arguments @('plugin', 'marketplace', 'update', $ClaudeMarketplace) | Out-Null
    # claude plugin update
    Invoke-ExternalCommand -FilePath 'claude' -Arguments @('plugin', 'update', $claudeState.Selector, '--scope', $claudeState.Scope) | Out-Null
    $claudeState = Resolve-ClaudeInstallation -MarketplaceFile $claudeMarketplaceFile -InstalledFile $claudeInstalledFile -MarketplaceName $ClaudeMarketplace -PluginName $identity.Name -RepositoryRoot $repositoryRoot
    $claudeDifferences = @(Get-CoreDifferences -Expected $repoMap -Actual (Get-CoreFileMap $claudeState.InstallPath))
    if ($claudeDifferences.Count -gt 0) {
        # claude plugin uninstall / claude plugin install (same-version cache refresh)
        Invoke-ExternalCommand -FilePath 'claude' -Arguments @('plugin', 'uninstall', $claudeState.Selector, '--scope', $claudeState.Scope) | Out-Null
        Invoke-ExternalCommand -FilePath 'claude' -Arguments @('plugin', 'install', $claudeState.Selector, '--scope', $claudeState.Scope) | Out-Null
        $claudeState = Resolve-ClaudeInstallation -MarketplaceFile $claudeMarketplaceFile -InstalledFile $claudeInstalledFile -MarketplaceName $ClaudeMarketplace -PluginName $identity.Name -RepositoryRoot $repositoryRoot
    }
    Assert-CoreMatches -Expected $repoMap -ActualRoot $claudeState.InstallPath -Label 'Claude cache'

    Sync-CodexSource -RepositoryRoot $repositoryRoot -CodexSource $codexSource -PluginName $identity.Name
    Assert-CoreMatches -Expected $repoMap -ActualRoot $codexSource -Label 'Codex plugin source'
    $codexStatus = Get-CodexStatus $codexSelector
    if ($codexStatus -eq 'installed, disabled') {
        throw "Codex plugin is disabled; refusing to change its enabled state implicitly: $codexSelector"
    }
    if ($codexStatus -eq 'installed, enabled') {
        # codex plugin remove
        Invoke-ExternalCommand -FilePath 'codex' -Arguments @('plugin', 'remove', $codexSelector) | Out-Null
    }
    # codex plugin add
    Invoke-ExternalCommand -FilePath 'codex' -Arguments @('plugin', 'add', $codexSelector) | Out-Null
    if ((Get-CodexStatus $codexSelector) -ne 'installed, enabled') {
        throw "Codex plugin did not return to enabled state: $codexSelector"
    }
    $codexCache = Get-CodexCachePath -MarketplaceName $CodexMarketplace -PluginName $identity.Name -Version $identity.CodexVersion
    Assert-CoreMatches -Expected $repoMap -ActualRoot $codexCache -Label 'Codex cache'
}

if ((Get-ClaudeStatus $claudeState.Selector) -ne 'enabled') {
    throw "Claude plugin did not remain enabled: $($claudeState.Selector)"
}

Write-Output "Plugin: $($identity.Name)"
Write-Output "Claude version: $($identity.ClaudeVersion)"
Write-Output "Codex version: $($identity.CodexVersion)"
Write-Output "Claude cache: $($claudeState.InstallPath)"
Write-Output "Codex source: $codexSource"
Write-Output "Codex cache: $codexCache"
Write-Output 'Verification: repository, Codex source, Codex cache, and Claude cache match.'
Write-Output 'Restart Claude Code and start a new Codex task to load the updated plugin skills.'
