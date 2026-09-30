<#
.SYNOPSIS
Exercises Cursor installation against isolated temporary files, never user state.
#>
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$installer = Join-Path $PSScriptRoot 'install-cursor-plugin.ps1'
$tempParent = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd([char[]]'\/')
$fixtures = Join-Path $tempParent ('fp-cursor-tests-' + [guid]::NewGuid().ToString('N'))
$utf8 = New-Object Text.UTF8Encoding($false)
$passed = 0
$links = New-Object 'Collections.Generic.List[string]'

function Assert([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "Assertion failed: $Message" }
}

function Put([string]$Root, [string]$Relative, [string]$Text = 'fixture') {
    # Test data is always contained in this run's temporary fixture directory.
    $path = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
    Assert ($path.StartsWith($fixtures + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) 'fixture escaped temporary root'
    [IO.Directory]::CreateDirectory((Split-Path -Parent $path)) | Out-Null
    [IO.File]::WriteAllText($path, $Text, $utf8)
}

function New-Fixture([string]$Name) {
    $root = Join-Path $fixtures $Name
    $source = Join-Path $root 'source'
    $cursor = Join-Path $root 'cursor home'
    Put $source '.cursor-plugin/plugin.json' '{"name":"fp","skills":"./skills/","rules":"./adapters/cursor/rules/","commands":[]}'
    Put $source 'skills/fp-demo/SKILL.md' '# fixture skill'
    Put $source 'skills/_shared/workspace-rules.md' '# workspace contract'
    Put $source 'skills/_shared/engineering-quality.md' '# engineering contract'
    Put $source 'scripts/check.ps1' '# fixture script'
    Put $source 'adapters/cursor/rules/featurepilot.mdc' 'alwaysApply: true'
    return [pscustomobject]@{ Root = $root; Source = $source; Cursor = $cursor; Target = (Join-Path $cursor 'plugins/local/fp') }
}

function Snapshot([string]$Root) {
    # File hashes/times detect rewriting; directory membership detects creation.
    # NTFS can publish delayed directory timestamps after fixture construction.
    if (-not (Test-Path -LiteralPath $Root)) { return '<absent>' }
    $rows = @(Get-ChildItem -LiteralPath $Root -Force -Recurse | Sort-Object FullName | ForEach-Object {
        $hash = if ($_.PSIsContainer) { '<directory>' } else { (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
        $stamp = if ($_.PSIsContainer) { 0 } else { $_.LastWriteTimeUtc.Ticks }
        '{0}|{1}|{2}' -f $_.FullName, $hash, $stamp
    })
    return ($rows -join "`n")
}

function Expect-Failure([scriptblock]$Action, [string]$Pattern) {
    $failure = $null
    try { & $Action | Out-Null } catch { $failure = $_ }
    Assert ($null -ne $failure) "expected failure: $Pattern"
    Assert ($failure.Exception.Message -like "*$Pattern*") "unexpected error: $($failure.Exception.Message)"
}

function Run-Test([string]$Name, [scriptblock]$Action) {
    & $Action
    $script:passed++
    Write-Host "PASS $Name"
}

function New-TestJunction([string]$Path, [string]$Target) {
    # Junctions require no symlink privilege on Windows; remove links before cleanup.
    New-Item -ItemType Junction -Path $Path -Target $Target | Out-Null
    $script:links.Add($Path)
}

try {
    [IO.Directory]::CreateDirectory($fixtures) | Out-Null
    Run-Test 'VerifyOnly missing install makes no writes' {
        $f = New-Fixture 'verify-missing'
        $before = Snapshot $f.Root
        Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome $f.Cursor -VerifyOnly } 'missing:'
        $after = Snapshot $f.Root
        Assert ($after -eq $before) ('VerifyOnly wrote missing install: ' + ((Compare-Object ($before -split "`n") ($after -split "`n") | Format-List | Out-String)))
        Assert (-not (Test-Path -LiteralPath $f.Cursor)) 'VerifyOnly created CursorHome'
    }
    Run-Test 'initial install preserves resource bytes and excludes runtime caches' {
        $f = New-Fixture 'initial'
        foreach ($path in @('.git/private', '.agents/cache', '.claude/cache', 'adapters/codex/cache', 'skills/.claude/cache')) { Put $f.Source $path }
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor
        $state = Get-Content -LiteralPath (Join-Path $f.Target '.featurepilot-install.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        Assert ($state.files.Count -eq 6) 'wrong packaged file set'
        foreach ($entry in $state.files) {
            $sourceHash = (Get-FileHash -LiteralPath (Join-Path $f.Source $entry.path) -Algorithm SHA256).Hash
            $targetHash = (Get-FileHash -LiteralPath (Join-Path $f.Target $entry.path) -Algorithm SHA256).Hash
            Assert ($sourceHash -eq $targetHash -and $entry.sha256 -eq $targetHash) "hash mismatch: $($entry.path)"
        }
        Assert (@(Get-ChildItem -LiteralPath $f.Target -Force -Recurse -File).Count -eq 7) 'unexpected files copied'
        $before = Snapshot $f.Root
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor -VerifyOnly
        Assert ((Snapshot $f.Root) -eq $before) 'successful VerifyOnly wrote files'
    }
    Run-Test 'update removes stale managed files and preserves unknowns and other plugins' {
        $f = New-Fixture 'update'
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor
        Put $f.Target 'notes/keep.txt' 'human note'
        $other = Join-Path $f.Cursor 'plugins/local/other'
        Put $other 'keep.txt' 'other plugin'
        $otherBefore = Snapshot $other
        Remove-Item -LiteralPath (Join-Path $f.Source 'scripts/check.ps1')
        Put $f.Source 'scripts/new.ps1' '# new script'
        Put $f.Source 'skills/fp-demo/SKILL.md' '# changed skill'
        $before = Snapshot $f.Target
        Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome $f.Cursor -VerifyOnly } 'stale: scripts/check.ps1'
        Assert ((Snapshot $f.Target) -eq $before) 'stale verification wrote install'
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor
        Assert (-not (Test-Path -LiteralPath (Join-Path $f.Target 'scripts/check.ps1'))) 'stale file survived'
        Assert (Test-Path -LiteralPath (Join-Path $f.Target 'scripts/new.ps1')) 'new file missing'
        Assert ((Get-Content -LiteralPath (Join-Path $f.Target 'notes/keep.txt') -Raw -Encoding UTF8) -eq 'human note') 'unknown file changed'
        Assert ((Snapshot $other) -eq $otherBefore) 'other plugin changed'
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor -VerifyOnly
        Assert (@(Get-ChildItem -LiteralPath (Join-Path $f.Cursor 'plugins') -Force | Where-Object { $_.Name -like '.fp-*' }).Count -eq 0) 'temporary stage or backup survived'
    }
    Run-Test 'VerifyOnly detects drift without writing; update rejects manual edits' {
        $f = New-Fixture 'manual-edit'
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor
        Put $f.Target 'skills/fp-demo/SKILL.md' '# human edit'
        $before = Snapshot $f.Root
        Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome $f.Cursor -VerifyOnly } 'changed: skills/fp-demo/SKILL.md'
        Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome $f.Cursor } 'Managed file was changed or removed'
        Assert ((Snapshot $f.Root) -eq $before) 'manual edit was overwritten'
    }
    Run-Test 'removed managed files are protected' {
        $f = New-Fixture 'manual-remove'
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor
        Remove-Item -LiteralPath (Join-Path $f.Target 'scripts/check.ps1')
        Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome $f.Cursor -VerifyOnly } 'missing: scripts/check.ps1'
        Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome $f.Cursor } 'Managed file was changed or removed'
    }
    Run-Test 'unmanaged same-name install is never taken over' {
        $f = New-Fixture 'unmanaged'
        Put $f.Target '.cursor-plugin/plugin.json' (Get-Content -LiteralPath (Join-Path $f.Source '.cursor-plugin/plugin.json') -Raw -Encoding UTF8)
        $before = Snapshot $f.Root
        Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome $f.Cursor } 'without a management marker'
        Assert ((Snapshot $f.Root) -eq $before) 'unmanaged install changed'
    }
    Run-Test 'unknown file cannot be claimed by a later source version' {
        $f = New-Fixture 'unknown-conflict'
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor
        Put $f.Target 'scripts/local.ps1' '# human script'
        Put $f.Source 'scripts/local.ps1' '# new upstream script'
        $before = Snapshot $f.Root
        Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome $f.Cursor } 'conflicts with unknown file'
        Assert ((Snapshot $f.Root) -eq $before) 'unknown conflict overwrote content'
    }
    Run-Test 'invalid source identity and installed identity are rejected' {
        $f = New-Fixture 'bad-source-name'
        Put $f.Source '.cursor-plugin/plugin.json' '{"name":"other","skills":"./skills/","rules":"./adapters/cursor/rules/","commands":[]}'
        Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome $f.Cursor } 'Invalid Cursor manifest'
        Assert (-not (Test-Path -LiteralPath $f.Cursor)) 'invalid source created target'
        $f = New-Fixture 'bad-target-name'
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor
        Put $f.Target '.cursor-plugin/plugin.json' '{"name":"other","skills":"./skills/","rules":"./adapters/cursor/rules/","commands":[]}'
        Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome $f.Cursor } 'Invalid Cursor manifest'
    }
    Run-Test 'source and target overlaps are rejected' {
        $f = New-Fixture 'overlap'
        Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome (Join-Path $f.Source 'nested') } 'overlap'
        Assert (-not (Test-Path -LiteralPath (Join-Path $f.Source 'nested'))) 'overlap created nested target'
        Expect-Failure { & $installer -PluginRoot $f.Target -CursorHome $f.Cursor } 'overlap'
    }
    Run-Test 'missing manifest, skill, or required bootstrap resource rejects initial install' {
        foreach ($relative in @('.cursor-plugin/plugin.json', 'skills/fp-demo/SKILL.md', 'skills/_shared/workspace-rules.md', 'skills/_shared/engineering-quality.md', 'adapters/cursor/rules/featurepilot.mdc')) {
            $f = New-Fixture ('missing-' + [guid]::NewGuid().ToString('N'))
            Put $f.Source 'adapters/cursor/rules/other.mdc' '# not the bootstrap rule'
            Remove-Item -LiteralPath (Join-Path $f.Source $relative)
            Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome $f.Cursor } 'Missing'
            Assert (-not (Test-Path -LiteralPath $f.Cursor)) 'incomplete source created install'
        }
    }
    Run-Test 'missing required bootstrap resource rejects update and preserves the old install' {
        foreach ($relative in @('skills/_shared/workspace-rules.md', 'skills/_shared/engineering-quality.md', 'adapters/cursor/rules/featurepilot.mdc')) {
            $f = New-Fixture ('incomplete-update-' + [guid]::NewGuid().ToString('N'))
            & $installer -PluginRoot $f.Source -CursorHome $f.Cursor
            Put $f.Source 'adapters/cursor/rules/other.mdc' '# unrelated rule remains'
            Remove-Item -LiteralPath (Join-Path $f.Source $relative)
            $before = Snapshot $f.Cursor
            Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome $f.Cursor } "Missing required Cursor resource: $relative"
            Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome $f.Cursor -VerifyOnly } "Missing required Cursor resource: $relative"
            Assert ((Snapshot $f.Cursor) -eq $before) "incomplete update changed the prior install: $relative"
        }
    }
    Run-Test 'Unicode managed paths survive initial install, verification, and updates' {
        $f = New-Fixture 'unicode-path'
        # Escape the fixture name so this test script stays ASCII on PS 5.1.
        $name = ConvertFrom-Json '"\u4e2d\u6587"'
        $relative = "skills/fp-demo/$name.md"
        $newRelative = "scripts/$name.ps1"
        Put $f.Source $relative 'first version'
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor
        $marker = Join-Path $f.Target '.featurepilot-install.json'
        $state = Get-Content -LiteralPath $marker -Raw -Encoding UTF8 | ConvertFrom-Json
        Assert ($state.files.path -contains $relative) 'Unicode path was not recorded intact'
        $before = Snapshot $f.Cursor
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor -VerifyOnly
        Assert ((Snapshot $f.Cursor) -eq $before) 'Unicode verification wrote files'
        Put $f.Source $relative 'second version'
        Put $f.Source $newRelative '# another Unicode path'
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor
        Assert ((Get-Content -LiteralPath (Join-Path $f.Target $relative) -Raw -Encoding UTF8) -eq 'second version') 'Unicode resource was not updated'
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor -VerifyOnly
        Remove-Item -LiteralPath (Join-Path $f.Source $relative)
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor
        Assert (-not (Test-Path -LiteralPath (Join-Path $f.Target $relative))) 'stale Unicode resource survived'
        Assert (Test-Path -LiteralPath (Join-Path $f.Target $newRelative)) 'current Unicode resource was lost'
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor -VerifyOnly
    }
    Run-Test 'management path traversal is rejected before writes' {
        $f = New-Fixture 'traversal'
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor
        $state = Get-Content -LiteralPath (Join-Path $f.Target '.featurepilot-install.json') -Raw -Encoding UTF8 | ConvertFrom-Json
        $state.files[0].path = 'scripts/../../escape.txt'
        Put $f.Target '.featurepilot-install.json' ($state | ConvertTo-Json -Depth 5)
        $before = Snapshot $f.Root
        Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome $f.Cursor } 'Unsafe managed path'
        Assert ((Snapshot $f.Root) -eq $before) 'traversal mutated files'
    }
    Run-Test 'copy failure leaves the prior installation intact' {
        $f = New-Fixture 'copy-failure'
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor
        Put $f.Source 'scripts/new.ps1' '# new'
        $before = Snapshot $f.Target
        function Copy-Item { throw 'Injected copy failure' }
        Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome $f.Cursor } 'Injected copy failure'
        Assert ((Snapshot $f.Target) -eq $before) 'copy failure changed prior install'
    }
    Run-Test 'replacement failure restores the prior installation' {
        $f = New-Fixture 'move-failure'
        & $installer -PluginRoot $f.Source -CursorHome $f.Cursor
        Put $f.Source 'scripts/new.ps1' '# new'
        $before = Snapshot $f.Target
        function Move-Item([string]$LiteralPath, [string]$Destination) {
            if ((Split-Path -Leaf $LiteralPath) -like '.fp-stage-*') { throw 'Injected replacement failure' }
            Microsoft.PowerShell.Management\Move-Item -LiteralPath $LiteralPath -Destination $Destination
        }
        Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome $f.Cursor } 'Injected replacement failure'
        Assert ((Snapshot $f.Target) -eq $before) 'replacement failure did not roll back'
    }
    Run-Test 'source and destination junctions including ancestors are rejected' {
        $f = New-Fixture 'links'
        $outside = Join-Path $f.Root 'outside'
        Put $outside 'untouched.txt' 'outside data'
        $outsideBefore = Snapshot $outside
        New-TestJunction (Join-Path $f.Source 'scripts/link') $outside
        Expect-Failure { & $installer -PluginRoot $f.Source -CursorHome $f.Cursor } 'Reparse points'
        $f2 = New-Fixture 'ancestor-link'
        $alias = Join-Path $f2.Root 'source-alias'
        New-TestJunction $alias $f2.Source
        Expect-Failure { & $installer -PluginRoot $alias -CursorHome $f2.Cursor } 'Reparse points'
        New-TestJunction $f2.Cursor $outside
        Expect-Failure { & $installer -PluginRoot $f2.Source -CursorHome $f2.Cursor } 'Reparse points'
        Assert ((Snapshot $outside) -eq $outsideBefore) 'junction target was changed'
    }
    Write-Host "Cursor install fixture tests passed: $passed cases."
} finally {
    # Remove junction entries themselves first, never recursively traverse their targets.
    foreach ($link in $links) {
        $resolved = [IO.Path]::GetFullPath($link)
        if (-not $resolved.StartsWith($fixtures + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe junction cleanup path.' }
        if (Test-Path -LiteralPath $resolved) { [IO.Directory]::Delete($resolved) }
    }
    $resolved = [IO.Path]::GetFullPath($fixtures)
    if ((Split-Path -Parent $resolved) -ne $tempParent -or (Split-Path -Leaf $resolved) -notlike 'fp-cursor-tests-*') { throw 'Unsafe fixture cleanup path.' }
    if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
