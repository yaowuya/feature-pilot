$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "ub-mode contract validation failed: $message"
    }
}

function Read-Utf8([string]$relativePath) {
    $path = Join-Path $root $relativePath
    Assert-Condition (Test-Path -LiteralPath $path -PathType Leaf) "missing file: $relativePath"
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

$contract = Read-Utf8 'skills/_shared/ub-mode.md'
foreach ($anchor in @(
    'https://github.com/unclebob/ub-mode'
    '## Boundaries'
    '## Design'
    '## Implementation'
    'Make it Work'
    'Make it Right'
    'CRAP < 10'
    'Design does not run crapper, dryer, or mutator.'
    'A missing crapper, dryer, or mutator does not block task completion.'
    'This contract does not authorize a push and does not move the destination onto the main line.'
    'This contract does not delete a worktree or uncommitted work.'
)) {
    Assert-Condition ($contract.Contains($anchor)) "ub-mode contract lost anchor: $anchor"
}

$design = [regex]::Match($contract, '(?s)## Design\s*(?<body>.*?)\s*## Implementation')
$implementation = [regex]::Match($contract, '(?s)## Implementation\s*(?<body>.*)\z')
Assert-Condition ($design.Success -and $implementation.Success) 'ub-mode branches are missing'
Assert-Condition ($design.Groups['body'].Value.Contains('Decision Ledger')) 'Design branch lost the single decision owner'
Assert-Condition ($implementation.Groups['body'].Value.Contains('fp-execute')) 'Implementation branch lost its execution entry'

$consumers = @(
    'commands/fp-start.md'
    'skills/fp-start/SKILL.md'
    'skills/fp-brainstorm/SKILL.md'
    'skills/fp-brainstorm/design-template.md'
    'skills/fp-design-review/SKILL.md'
    'skills/fp-execute/SKILL.md'
    'skills/fp-execute-sdd/SKILL.md'
    'skills/fp-execute-sdd/implementer-prompt.md'
    'skills/fp-execute-sdd/fix-prompt.md'
    'skills/fp-execute-sdd/task-reviewer-prompt.md'
    'skills/fp-execute-sdd/task-brief-template.md'
    'skills/fp-quick/SKILL.md'
    'skills/fp-commit/SKILL.md'
    'skills/_shared/workspace-rules.md'
    'AGENTS.md'
)
foreach ($relativePath in $consumers) {
    $text = Read-Utf8 $relativePath
    Assert-Condition ($text.Contains('skills/_shared/ub-mode.md')) "$relativePath does not point at ub-mode"
}

$brainstorm = Read-Utf8 'skills/fp-brainstorm/SKILL.md'
$designReview = Read-Utf8 'skills/fp-design-review/SKILL.md'
$execute = Read-Utf8 'skills/fp-execute/SKILL.md'
Assert-Condition ($brainstorm.Contains('Design branch')) 'fp-brainstorm does not read the Design branch'
Assert-Condition ($designReview.Contains('Design branch')) 'fp-design-review does not check the Design branch'
Assert-Condition ($execute.Contains('Implementation branch')) 'fp-execute does not read the Implementation branch'
Assert-Condition ($execute.Contains('Make it Work') -and $execute.Contains('Make it Right')) 'fp-execute lost the work-then-right order'

Write-Output 'ub-mode contract validation passed.'
