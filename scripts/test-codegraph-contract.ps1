$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "CodeGraph contract validation failed: $message"
    }
}

function Read-Utf8([string]$path) {
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

$contractPath = Join-Path $root 'skills\_shared\codegraph.md'
Assert-Condition (Test-Path $contractPath) 'shared CodeGraph contract is missing'
$contract = Read-Utf8 $contractPath

foreach ($anchor in @(
    'npm install -g @colbymchenry/codegraph@latest',
    'npm prefix -g',
    '<npm-global-prefix>\codegraph.cmd',
    '<npm-global-prefix>/bin/codegraph',
    'codegraph install --target=auto --location=global --yes',
    'codegraph init <project-root>',
    'codegraph status <project-root> --json',
    'codegraph sync <project-root> --quiet',
    'MCP -> CLI -> native search',
    'navigation-hint-only'
)) {
    Assert-Condition ($contract.Contains($anchor)) "shared contract lost anchor: $anchor"
}

foreach ($forbidden in @('irm', 'curl', 'install.ps1', 'install.sh', 'npx')) {
    Assert-Condition ($contract.Contains("forbid: $forbidden")) "shared contract does not forbid $forbidden"
}

Assert-Condition ($contract.Contains('must not auto-install Node.js')) 'npm-missing fallback can install Node.js'
Assert-Condition ($contract.Contains('at most one status check')) 'workflow status check is not capped'
Assert-Condition ($contract.Contains('do not run status again after sync')) 'sync can trigger a second status check'
Assert-Condition ($contract.Contains('must not block FeaturePilot')) 'failure fallback is not explicit'

$init = Read-Utf8 (Join-Path $root 'skills\fp-init\SKILL.md')
$templates = Read-Utf8 (Join-Path $root 'skills\fp-init\templates.md')
$command = Read-Utf8 (Join-Path $root 'commands\fp-init.md')

foreach ($anchor in @(
    'skills/_shared/codegraph.md',
    'auto-install',
    'show-install-steps',
    'skip-codegraph',
    'npm install -g @colbymchenry/codegraph@latest',
    'npm prefix -g',
    'codegraph install --target=auto --location=global --yes',
    'codegraph init <project-root>',
    'codegraph status <project-root> --json',
    'auto-install includes first graph build',
    'preinstalled-cli-requires-build-confirmation'
)) {
    Assert-Condition ($init.Contains($anchor)) "fp-init lost anchor: $anchor"
}

Assert-Condition ($templates.Contains('## Code Map')) 'manifest template lacks Code Map'
Assert-Condition ($templates.Contains('navigation-hint-only')) 'manifest Code Map can be treated as current proof'
Assert-Condition ($command.Contains('npm')) 'Claude command checksum lacks npm-only install gate'
Assert-Condition ($command.Contains('MCP')) 'Claude command checksum lacks separate MCP gate'
Assert-Condition ($command.Contains('codegraph init')) 'Claude command checksum lacks graph-build gate'

$workspace = Read-Utf8 (Join-Path $root 'skills\_shared\workspace-rules.md')
$explore = Read-Utf8 (Join-Path $root 'skills\fp-explore\SKILL.md')

Assert-Condition ($workspace.Contains('skills/_shared/codegraph.md')) 'workspace contract does not route CodeGraph lazily'
foreach ($anchor in @(
    'Stage 0 - CodeGraph fast path',
    'codegraph_explore',
    'codegraph explore --path <project-root> --max-files <budget> <query>',
    'MCP -> CLI -> native search',
    'at most one status check',
    'do not run status again after sync',
    'candidate paths',
    'local read windows',
    'current source'
)) {
    Assert-Condition ($explore.Contains($anchor)) "fp-explore lost CodeGraph anchor: $anchor"
}
Assert-Condition ($explore.Contains('fall back to Stage A')) 'fp-explore can stop on CodeGraph failure'

$validator = Read-Utf8 (Join-Path $root 'scripts\validate-plugin.ps1')
$agents = Read-Utf8 (Join-Path $root 'AGENTS.md')
$claude = Read-Utf8 (Join-Path $root 'CLAUDE.md')
$readme = Read-Utf8 (Join-Path $root 'README.md')
$guide = Read-Utf8 (Join-Path $root 'docs\user_guide\init-prd-start.md')

Assert-Condition ($validator.Contains('test-codegraph-contract.ps1')) 'global validator does not invoke CodeGraph suite'
Assert-Condition ($validator.Contains('skills\_shared\codegraph.md')) 'global validator does not anchor shared CodeGraph resource'
foreach ($surface in @(
    @{ Name = 'AGENTS.md'; Text = $agents },
    @{ Name = 'CLAUDE.md'; Text = $claude },
    @{ Name = 'README.md'; Text = $readme },
    @{ Name = 'user guide'; Text = $guide }
)) {
    Assert-Condition ($surface.Text.Contains('CodeGraph')) "$($surface.Name) does not document CodeGraph"
    Assert-Condition ($surface.Text.Contains('npm install -g @colbymchenry/codegraph@latest')) "$($surface.Name) lacks npm-only install command"
}

Write-Output 'CodeGraph contract validation passed.'
