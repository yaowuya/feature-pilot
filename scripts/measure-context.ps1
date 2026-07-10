$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
$baseline = @{
    Core = 162239
    Prd = 36443
    Start = 72755
    Review = 22041
}

function Get-Chars([string[]]$relativePaths) {
    return ($relativePaths | ForEach-Object {
        [System.IO.File]::ReadAllText((Join-Path $root $_), [System.Text.Encoding]::UTF8).Length
    } | Measure-Object -Sum).Sum
}

$shared = Get-Chars @('skills\_shared\workspace-rules.md')
$skillPaths = @(Get-ChildItem (Join-Path $root 'skills') -Filter 'SKILL.md' -Recurse | ForEach-Object { $_.FullName.Substring($root.Length + 1) })
$commandPaths = @(Get-ChildItem (Join-Path $root 'commands') -Filter 'fp-*.md' | ForEach-Object { $_.FullName.Substring($root.Length + 1) })

$current = @{
    Core = $shared + (Get-Chars ($skillPaths + $commandPaths))
    Prd = $shared + (Get-Chars @('commands\fp-prd.md', 'skills\fp-prd\SKILL.md', 'skills\fp-prd-grill-me\SKILL.md', 'skills\fp-grill-me\SKILL.md'))
    Start = $shared + (Get-Chars @('commands\fp-start.md', 'skills\fp-start\SKILL.md', 'skills\fp-propose\SKILL.md', 'skills\fp-brainstorm\SKILL.md', 'skills\fp-plan\SKILL.md', 'skills\fp-plan-backend\SKILL.md', 'skills\fp-plan-frontend\SKILL.md', 'skills\fp-execute-sdd\SKILL.md', 'skills\fp-review\SKILL.md'))
    Review = $shared + (Get-Chars @('commands\fp-review.md', 'skills\fp-review\SKILL.md', 'skills\fp-review\final-reviewer.md'))
}

$rows = foreach ($name in @('Core', 'Prd', 'Start', 'Review')) {
    $saved = $baseline[$name] - $current[$name]
    [PSCustomObject]@{
        Scenario = $name
        BaselineChars = $baseline[$name]
        CurrentChars = $current[$name]
        SavedChars = $saved
        Reduction = '{0:N1}%' -f (100 * $saved / $baseline[$name])
    }
}

Write-Output 'Static prompt-character proxy (lazy output templates excluded until their write phase):'
$rows | Format-Table -AutoSize
