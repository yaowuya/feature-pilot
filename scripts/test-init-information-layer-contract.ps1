$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "Init information-layer contract validation failed: $message"
    }
}

function Read-Utf8([string]$relativePath) {
    $path = Join-Path $root $relativePath
    Assert-Condition (Test-Path -LiteralPath $path) "missing contract surface: $relativePath"
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Get-MarkdownSection([string]$text, [string]$heading) {
    $match = [regex]::Match($text, "(?ms)^#{2,6}\s+$([regex]::Escape($heading))\s*`r?`n(?<body>.*?)(?=^#{2,6}\s+|\z)")
    Assert-Condition $match.Success "missing Markdown section: $heading"
    return $match
}

function Assert-ExactPropertySet([object]$value, [string[]]$expected, [string]$scope) {
    $actual = @($value.PSObject.Properties.Name | Sort-Object)
    $wanted = @($expected | Sort-Object)
    Assert-Condition (($actual -join '|') -ceq ($wanted -join '|')) "$scope property set is not exact; actual=$($actual -join ',') expected=$($wanted -join ',')"
}

$init = Read-Utf8 'skills\fp-init\SKILL.md'
$templates = Read-Utf8 'skills\fp-init\templates.md'
$workspace = Read-Utf8 'skills\_shared\workspace-rules.md'
$executeSdd = Read-Utf8 'skills\fp-execute-sdd\SKILL.md'
$taskBrief = Read-Utf8 'skills\fp-execute-sdd\task-brief-template.md'
$reviewPackage = Read-Utf8 'skills\fp-execute-sdd\review-package-template.md'
$prd = Read-Utf8 'skills\fp-prd\SKILL.md'
$prdGrill = Read-Utf8 'skills\fp-prd-grill-me\SKILL.md'
$review = Read-Utf8 'skills\fp-review\SKILL.md'
$finalReviewer = Read-Utf8 'skills\fp-review\final-reviewer.md'
$finalReviewTemplate = Read-Utf8 'skills\fp-review\final-review-template.md'
$command = Read-Utf8 'commands\fp-init.md'
$readme = Read-Utf8 'README.md'
$guide = Read-Utf8 'docs\user_guide\init-prd-start.md'
$agents = Read-Utf8 'AGENTS.md'
$claude = Read-Utf8 'CLAUDE.md'
$validator = Read-Utf8 'scripts\validate-plugin.ps1'

foreach ($surface in @(
    @{ Name = 'fp-init'; Text = $init }
    @{ Name = 'fp-init templates'; Text = $templates }
    @{ Name = 'fp-init command'; Text = $command }
    @{ Name = 'README'; Text = $readme }
    @{ Name = 'user guide'; Text = $guide }
    @{ Name = 'AGENTS'; Text = $agents }
    @{ Name = 'CLAUDE'; Text = $claude }
)) {
    Assert-Condition ($surface.Text.Contains('manifest-only default')) "$($surface.Name) does not state the manifest-only default"
}

foreach ($anchor in @(
    'new-project-manifest-only'
    'fp-docs/manifest.md'
    'settings-created-only-after-explicit-approval'
    'approved-discovery-project-facts-only'
    'intel/project-facts.md'
    'intel/.freshness.json'
    'metadata-only'
    'unknowns-and-decisions-human-owned-lazy'
    'legacy-information-layer-read-compatibility'
)) {
    Assert-Condition ($init.Contains($anchor)) "fp-init lost v2 anchor: $anchor"
}

foreach ($anchor in @(
    'schema'
    'artifact/section id'
    'source relative path'
    'fingerprint'
    'body hash'
    'generated time'
    'generator version'
    'stale/conflict is computed live'
    'no CodeGraph topology snapshots'
)) {
    Assert-Condition ($templates.Contains($anchor)) "fp-init templates lost project-facts metadata contract: $anchor"
}

$metadataSection = Get-MarkdownSection $templates 'Project Facts Freshness Metadata'
$jsonFence = [regex]::Match($metadataSection.Groups['body'].Value, '(?s)```json\s*(?<json>\{.*?\})\s*```')
Assert-Condition $jsonFence.Success 'Project Facts Freshness Metadata lacks a JSON code fence'
try {
    $metadata = $jsonFence.Groups['json'].Value | ConvertFrom-Json
} catch {
    throw "Init information-layer contract validation failed: freshness metadata JSON is invalid: $($_.Exception.Message)"
}

Assert-ExactPropertySet $metadata @('schema', 'generatorVersion', 'generatedTime', 'sections') 'freshness metadata root'
Assert-Condition (@($metadata.sections).Count -gt 0) 'freshness metadata requires at least one section example'
foreach ($section in @($metadata.sections)) {
    Assert-ExactPropertySet $section @('artifactSectionId', 'bodyHash', 'sources') 'freshness metadata section'
    Assert-Condition (@($section.sources).Count -gt 0) 'freshness metadata section requires at least one source example'
    foreach ($source in @($section.sources)) {
        Assert-ExactPropertySet $source @('relativePath', 'fingerprint') 'freshness metadata source'
    }
}

$metadataJsonNormalized = $metadata | ConvertTo-Json -Depth 20 -Compress
foreach ($forbiddenField in @('stale', 'conflict', 'freshness', 'verdict', 'projectFacts', 'project_facts', 'decision', 'unknowns')) {
    Assert-Condition (-not ($metadataJsonNormalized -match ('(?i)"' + [regex]::Escape($forbiddenField) + '"\s*:'))) "freshness metadata persists forbidden field: $forbiddenField"
}

Assert-Condition ($templates.Contains('intel/unknowns.md') -and $templates.Contains('intel/decisions.md')) 'templates do not define lazy human-owned knowledge files'
Assert-Condition ($templates.Contains('human-owned') -and $templates.Contains('lazy')) 'templates do not label unknowns/decisions as human-owned and lazy'

$legacyNames = @('unknowns-and-decisions.md', 'refresh-policy.md', 'sdd-handoff.md')
$initLegacy = Get-MarkdownSection $init 'Compatibility'
$initV2Main = $init.Remove($initLegacy.Index, $initLegacy.Length)
$templateLegacy = Get-MarkdownSection $templates 'Legacy information-layer read compatibility'
$templatesV2Main = $templates.Remove($templateLegacy.Index, $templateLegacy.Length)
foreach ($legacyName in $legacyNames) {
    Assert-Condition (-not $initV2Main.Contains($legacyName)) "fp-init v2 main flow mentions legacy producer/handoff file: $legacyName"
    Assert-Condition (-not $templatesV2Main.Contains($legacyName)) "fp-init v2 template main flow mentions legacy producer/handoff file: $legacyName"
    Assert-Condition ($initLegacy.Groups['body'].Value.Contains($legacyName)) "fp-init compatibility section lost legacy read hint: $legacyName"
    Assert-Condition ($templateLegacy.Groups['body'].Value.Contains($legacyName)) "template compatibility section lost legacy read hint: $legacyName"
}
foreach ($legacyField in @('Refreshed:', 'Generated body hash:', 'Refresh decision:')) {
    Assert-Condition (-not $templatesV2Main.Contains($legacyField)) "v2 template main flow still emits legacy freshness field: $legacyField"
    Assert-Condition ($templateLegacy.Groups['body'].Value.Contains($legacyField)) "legacy read-only section lost historical field example: $legacyField"
}
foreach ($surface in @(
    @{ Name = 'fp-init compatibility'; Text = $initLegacy.Groups['body'].Value }
    @{ Name = 'template compatibility'; Text = $templateLegacy.Groups['body'].Value }
)) {
    Assert-Condition ($surface.Text -match '(?i)read[- ]only') "$($surface.Name) is not explicitly read-only"
    Assert-Condition ($surface.Text -match '(?i)does not create or refresh') "$($surface.Name) does not forbid legacy creation/refresh"
    Assert-Condition ($surface.Text -match '(?i)not required') "$($surface.Name) does not forbid legacy requirement/blocking"
}

$externalDocsSection = Get-MarkdownSection $init '5. Check existing project-level agent/docs'
Assert-Condition ($externalDocsSection.Groups['body'].Value.Contains('first-time-manifest-external-doc-fill')) 'fp-init does not distinguish first-time external-doc manifest population'
Assert-Condition ($externalDocsSection.Groups['body'].Value.Contains('existing-manifest-external-doc-write-gate')) 'fp-init does not gate existing-manifest external-doc writes'
Assert-Condition ($externalDocsSection.Groups['body'].Value.Contains('report-only-or-skip-means-no-write')) 'fp-init does not preserve no-write refresh choices'
Assert-Condition (-not $externalDocsSection.Groups['body'].Value.Contains('always created or updated')) 'fp-init still says an existing manifest is always updated'

$reportSection = Get-MarkdownSection $init '10. Report next steps'
Assert-Condition (-not $reportSection.Groups['body'].Value.Contains('External docs detected and recorded in manifest.')) 'fp-init final report still unconditionally claims external docs were recorded'
Assert-Condition ($reportSection.Groups['body'].Value.Contains('external-doc-manifest-disposition')) 'fp-init final report lacks external-doc manifest disposition'
foreach ($disposition in @('first-time-recorded', 'approved-update', 'not-modified')) {
    Assert-Condition ($reportSection.Groups['body'].Value.Contains($disposition)) "fp-init final report lacks external-doc disposition: $disposition"
}
Assert-Condition (-not $init.Contains('After updating the manifest')) 'fp-init assumes an existing manifest was updated before optional settings'
Assert-Condition ($init.Contains('after-resolving-manifest-disposition')) 'fp-init lacks a neutral transition after manifest handling'

foreach ($surface in @(
    @{ Name = 'workspace rules'; Text = $workspace }
    @{ Name = 'fp-execute-sdd'; Text = $executeSdd }
    @{ Name = 'task brief'; Text = $taskBrief }
    @{ Name = 'review package'; Text = $reviewPackage }
)) {
    Assert-Condition ($surface.Text.Contains('dynamic task context')) "$($surface.Name) lacks dynamic task context"
    Assert-Condition ($surface.Text.Contains('N/A')) "$($surface.Name) lacks optional-file N/A fallback"
}
Assert-Condition ($workspace.Contains('manifest-only workspace is valid')) 'workspace rules do not accept manifest-only workspaces'
Assert-Condition ($workspace.Contains('v2 never creates or refreshes legacy files')) 'workspace rules do not forbid legacy-file production in v2'

foreach ($surface in @(
    @{ Name = 'fp-execute-sdd'; Text = $executeSdd }
    @{ Name = 'task brief'; Text = $taskBrief }
    @{ Name = 'review package'; Text = $reviewPackage }
    @{ Name = 'fp-review'; Text = $review }
    @{ Name = 'final reviewer'; Text = $finalReviewer }
    @{ Name = 'final review template'; Text = $finalReviewTemplate }
)) {
    Assert-Condition (-not $surface.Text.Contains('sdd-handoff.md is required')) "$($surface.Name) still requires static sdd-handoff.md"
}

Assert-Condition (-not $prd.Contains('/fp-init --refresh')) 'fp-prd recommends an undefined fp-init --refresh command'
Assert-Condition ($prd.Contains('supported-init-rerun') -and $prd.Contains('`/fp-init`')) 'fp-prd does not route stale intel to the supported fp-init command'

foreach ($surface in @(
    @{ Name = 'fp-review'; Text = $review }
    @{ Name = 'final reviewer'; Text = $finalReviewer }
    @{ Name = 'final review template'; Text = $finalReviewTemplate }
)) {
    Assert-Condition ($surface.Text.Contains('dynamic brief/package sources')) "$($surface.Name) does not review dynamic brief/package sources"
    Assert-Condition ($surface.Text.Contains('static handoff absence is not a blocker')) "$($surface.Name) can still block on absent static handoff"
}

foreach ($surface in @(
    @{ Name = 'fp-prd'; Text = $prd }
    @{ Name = 'fp-prd-grill-me'; Text = $prdGrill }
)) {
    Assert-Condition ($surface.Text.Contains('intel/unknowns.md')) "$($surface.Name) does not recognize lazy project unknowns"
    Assert-Condition ($surface.Text.Contains('absence is not a blocker')) "$($surface.Name) blocks on absent project unknowns"
    Assert-Condition ($surface.Text.Contains('change-local unknowns')) "$($surface.Name) does not keep ordinary unknowns change-local"
}

Assert-Condition ($validator.Contains('test-init-information-layer-contract.ps1')) 'global validator does not invoke the focused init information-layer suite'

Write-Output 'Init information-layer contract validation passed.'
