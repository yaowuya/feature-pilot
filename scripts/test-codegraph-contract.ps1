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

Write-Output 'CodeGraph contract validation passed.'
