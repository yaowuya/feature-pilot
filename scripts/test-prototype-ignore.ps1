$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = Split-Path -Parent $PSScriptRoot
$templatePath = Join-Path $repo 'skills/_shared/prototype.gitignore'
if (-not (Test-Path -LiteralPath $templatePath -PathType Leaf)) { throw 'Missing prototype gitignore template' }
$template = [IO.File]::ReadAllText($templatePath, [Text.Encoding]::UTF8)
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('fp-prototype-ignore-' + [guid]::NewGuid().ToString('N'))
$utf8 = New-Object Text.UTF8Encoding($false)
$count = 0
function Put([string]$path, [string]$body = 'fixture') {
    $full = Join-Path $fixture $path
    [IO.Directory]::CreateDirectory((Split-Path -Parent $full)) | Out-Null
    [IO.File]::WriteAllText($full, $body, $utf8)
}
function Invoke-FixtureGit([string[]]$Arguments) {
    $previous = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& git -c "core.excludesFile=$fixture/empty-excludes" -C $fixture @Arguments 2>&1)
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previous }
    return [pscustomobject]@{ Code = $code; Text = ($output -join "`n") }
}
function Check-Code([string]$name, [object]$result, [int]$expected) {
    if ($result.Code -ne $expected) { throw "$name expected $expected, got $($result.Code): $($result.Text)" }
    $script:count++
    Write-Host "PASS $name"
}
try {
    Put 'empty-excludes' ''
    Check-Code 'initialize isolated Git fixture' (Invoke-FixtureGit @('init', '-q')) 0
    $tracked = 'fp-docs/prototype-bases/tracked/src/App.vue'
    Put $tracked
    Check-Code 'stage legacy tracked prototype before ignore' (Invoke-FixtureGit @('add', '--', $tracked)) 0
    Put 'fp-docs/.gitignore' ("# Existing user rule`n/user-note.md`n`n" + $template)

    $ignored = @(
        'fp-docs/prototype-bases/web/manifest.json',
        'fp-docs/prototype-bases/web/src/App.vue',
        'fp-docs/prototype-bases/web/preview/assets/app.js',
        'fp-docs/changes/demo/prototype/manifest.json',
        'fp-docs/changes/demo/prototype/src/main.ts',
        'fp-docs/changes/demo/prototype/fixtures/data.json',
        'fp-docs/changes/demo/prototype/verification.md',
        'fp-docs/changes/legacy/prototype.html',
        'fp-docs/archive/2026-09-demo/prototype/preview/index.html',
        'fp-docs/archive/2026-09-demo/prototype/src/App.tsx',
        'fp-docs/archive/2026-09-legacy/prototype.html',
        'fp-docs/user-note.md'
    )
    foreach ($path in $ignored) {
        Put $path
        Check-Code "ignored $path" (Invoke-FixtureGit @('check-ignore', '--quiet', '--no-index', '--', $path)) 0
    }
    foreach ($path in @(
        'fp-docs/.gitignore', 'fp-docs/manifest.md',
        'fp-docs/settings/frontend.md', 'fp-docs/intel/project-facts.md',
        'fp-docs/changes/demo/prd.md', 'fp-docs/changes/demo/proposal.md',
        'fp-docs/changes/demo/design/frontend.md', 'fp-docs/changes/demo/tasks/plan-frontend.md',
        'fp-docs/changes/demo/.fp-execute/e2e/case/coverage-matrix.md',
        'fp-docs/archive/2026-09-demo/prd.md',
        'fp-docs/archive/2026-09-demo/.fp-execute/visual/case/result.md',
        'src/prototype/App.vue', 'docs/prototype.html'
    )) {
        if ($path -ne 'fp-docs/.gitignore') { Put $path }
        Check-Code "preserved $path" (Invoke-FixtureGit @('check-ignore', '--quiet', '--no-index', '--', $path)) 1
    }

    Check-Code 'batch success is not proof that every path is ignored' (Invoke-FixtureGit @('check-ignore', '--no-index', '--', $ignored[0], 'fp-docs/manifest.md')) 0
    Check-Code 'ignore pattern matches even when tracked' (Invoke-FixtureGit @('check-ignore', '--quiet', '--no-index', '--', $tracked)) 0
    Check-Code 'ordinary check does not hide tracked prototype' (Invoke-FixtureGit @('check-ignore', '--quiet', '--', $tracked)) 1
    Check-Code 'tracked prototype remains in index' (Invoke-FixtureGit @('ls-files', '--error-unmatch', '--', $tracked)) 0
    Check-Code 'untrack fixture without deleting local file' (Invoke-FixtureGit @('rm', '--cached', '-q', '--', $tracked)) 0
    if (-not (Test-Path -LiteralPath (Join-Path $fixture $tracked))) { throw 'Untracking deleted the local prototype' }
    Check-Code 'untracked prototype is now ignored' (Invoke-FixtureGit @('check-ignore', '--quiet', '--', $tracked)) 0

    Check-Code 'normal add respects prototype exclusion' (Invoke-FixtureGit @('add', '--', 'fp-docs')) 0
    $indexed = Invoke-FixtureGit @('ls-files', '--', 'fp-docs')
    if ($indexed.Code -ne 0 -or $indexed.Text -match '(?m)^fp-docs/(prototype-bases/|(?:changes|archive)/[^/]+/prototype(?:/|\.html$))') {
        throw "Prototype entered Git index: $($indexed.Text)"
    }

    Put 'fp-docs/changes/override/.gitignore' "!prototype/`n!prototype/**`n"
    Put 'fp-docs/changes/override/prototype/src/app.js'
    Check-Code 'nested negation is detectable, not silently safe' (Invoke-FixtureGit @('check-ignore', '--quiet', '--no-index', '--', 'fp-docs/changes/override/prototype/src/app.js')) 1
    Write-Host "Prototype gitignore checks passed: $count cases."
} finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
