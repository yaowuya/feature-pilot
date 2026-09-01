$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "fp-coverage contract validation failed: $message"
    }
}

function Read-Utf8([string]$path) {
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Test-CompletionShortcut([string]$text) {
    foreach ($line in @($text -split "`r?`n")) {
        $hasPermission = $line -match '(?i)\b(?:may|can|is allowed to)\b'
        $hasCompletionClaim = $line -match '(?i)(?:\bcomplete\b|\bcompletion\b|final proof|prove completion|proof of completion)'
        if (-not ($hasPermission -and $hasCompletionClaim)) { continue }

        $hasWeakEvidence = $line -match '(?i)\b(?:local|rounded|historical|stale|estimated|theoretical)\b'
        $hasNonZeroCommand = $line -match '(?i)(?:non-zero|nonzero|exit code\s*!=\s*0|exits?\s+non-zero)'
        if ($hasWeakEvidence -or $hasNonZeroCommand) { return $true }
    }
    return $false
}

function Test-MetricDriftPermission([string]$text) {
    return $text -match '(?is)(?:may|can|is allowed to)[^\r\n.]{0,100}(?:expand (?:omit|exclude)|shrink (?:source|include)|disable branch|change metric)[^\r\n.]{0,100}(?:target|coverage)'
}

function Test-XfailShortcut([string]$text) {
    return $text -match '(?is)(?:bulk|batch)[^\r\n.]{0,60}(?:skip|xfail)[^\r\n.]{0,80}(?:may|can|allowed)' -or $text -match '(?is)strict=False[^\r\n.]{0,80}(?:may|can|allowed)'
}

function Test-ProgressAuthorityContradiction([string]$text) {
    foreach ($line in @($text -split "`r?`n")) {
        if ($line -notmatch '(?i)\.fp-coverage/progress\.md') { continue }
        if ($line -match '(?i)\b(?:not|never|no)\b[^.]{0,60}(?:completion authority|proof of completion)') { continue }
        if ($line -match '(?i)(?:is|becomes|serves as)[^.]{0,60}(?:completion authority|proof of completion)') { return $true }
    }
    return $false
}

function Test-DirtyGraphPermission([string]$text) {
    return $text -match '(?is)(?:may|can|is allowed to)[^\r\n.]{0,100}(?:query|use)[^\r\n.]{0,80}(?:dirty graph|graph after write)'
}

function Test-ProjectRootCoverageOutputPermission([string]$text) {
    $lines = @($text -split "`r?`n")
    for ($index = 0; $index -lt $lines.Count; $index++) {
        $windowEnd = [Math]::Min($index + 1, $lines.Count - 1)
        $window = ($lines[$index..$windowEnd] -join ' ')
        $hasCoverageOutput = $window -match '(?i)(?:coverage\.xml|htmlcov/|coverage[- ](?:reports?|outputs?|artifacts?)|declared coverage reports?)'
        $hasRoot = $window -match '(?i)(?:(?:project|repository|repo)[- ]root|root[- ]level)'
        if (-not ($hasCoverageOutput -and $hasRoot)) { continue }
        if ($window -match '(?i)\b(?:must not|never|forbid|forbidden|prohibit|do not|cannot|can not)\b') { continue }
        $hasPermission = $window -match '(?i)\b(?:may|can|is allowed to|write|store|output|generate|generated|move|moved)\b'
        $hasRunThenMove = $window -match '(?i)(?:afterward|afterwards|then move|moved? into)'
        if ($hasPermission -or $hasRunThenMove) { return $true }
    }
    return $false
}

function Test-TerminalMissingToolBlock([string]$text) {
    foreach ($line in @($text -split "`r?`n")) {
        $hasMissingTool = $line -match '(?i)(?:missing|lacks?|without|no)[^.]{0,100}(?:coverage tool|coverage dependency|coverage plugin|coverage capability|tooling)'
        $hasTerminalBlock = $line -match '(?i)(?:only|always|immediately|must|is)[^.]{0,60}(?:BLOCKED|stop|terminate)'
        $hasContinuation = $line -match '(?i)(?:recommend|proposal|approval gate|bootstrap|install suggestion)'
        if ($hasMissingTool -and $hasTerminalBlock -and -not $hasContinuation) { return $true }
    }
    return $false
}

function Test-UnapprovedCoverageInstall([string]$text) {
    return $text -match '(?is)(?:may|can|should|will)[^\r\n.]{0,100}(?:install|add)[^\r\n.]{0,80}(?:coverage|pytest-cov)[^\r\n.]{0,100}(?:without|before)[^\r\n.]{0,40}(?:approval|consent)'
}

function Test-TemporaryOnlyBootstrap([string]$text) {
    return $text -match '(?is)(?:install|add)[^\r\n.]{0,100}(?:coverage|pytest-cov)[^\r\n.]{0,120}(?:environment only|without updating|do not update)[^\r\n.]{0,80}(?:requirements|dependency declaration|pyproject)'
}

function Test-ReuseBaselineAfterBootstrap([string]$text) {
    return $text -match '(?is)(?:after bootstrap|after installing)[^\r\n.]{0,120}(?:reuse|keep|retain)[^\r\n.]{0,80}(?:baseline|coverage evidence)'
}

function Test-BootstrapScopeExpansion([string]$text) {
    foreach ($line in @($text -split "`r?`n")) {
        $hasBootstrapContext = $line -match '(?i)(?:coverage-tooling-bootstrap|after approval|approved bootstrap)'
        $hasPermission = $line -match '(?i)\b(?:may|can|is allowed to|permits?)\b'
        $hasExpansion = $line -match '(?i)(?:upgrade unrelated|upgrade other|broaden (?:the )?(?:coverage )?config|expand (?:the )?(?:coverage )?config|change unrelated)'
        if ($hasBootstrapContext -and $hasPermission -and $hasExpansion) { return $true }
    }
    return $false
}

function Test-DjangoFallbackOverride([string]$text) {
    foreach ($line in @($text -split "`r?`n")) {
        if ($line -notmatch '(?i)Django') { continue }

        $forcesBundle = $line -match '(?i)(?:always|every|regardless)[^.]{0,100}(?:install|recommend)[^.]{0,100}pytest[^.]{0,60}pytest-cov[^.]{0,60}pytest-django'
        $duplicatesPytest = $line -match '(?i)(?:install|recommend)[^.]{0,80}pytest\s*\+\s*pytest-cov[^.]{0,100}(?:even (?:if|when)|although)[^.]{0,60}pytest[^.]{0,40}(?:exists|established|already)'
        $overridesExisting = $line -match '(?i)\b(?:may|can|should|always)\b[^.]{0,80}(?:replace|override)[^.]{0,80}(?:existing|authoritative)[^.]{0,80}(?:coverage\.py|coverage solution|tox|nox|CI)'
        if ($forcesBundle -or $duplicatesPytest -or $overridesExisting) { return $true }
    }
    return $false
}

function Test-UnboundedProgressPermission([string]$text) {
    foreach ($line in @($text -split "`r?`n")) {
        if ($line -notmatch '(?i)progress\.md') { continue }
        $hasAllHistory = $line -match '(?i)(?:every|all)[^.]{0,80}(?:command|event|full result|complete output|history)'
        $hasAppendOrStore = $line -match '(?i)(?:append|store|record|contain|keep)'
        $hasUnbounded = $line -match '(?i)(?:forever|append-only|full|complete|entire|without limit)'
        $hasProhibition = $line -match '(?i)(?:must not|never|do not|instead of|not an?)'
        if ($hasAllHistory -and $hasAppendOrStore -and $hasUnbounded -and -not $hasProhibition) { return $true }
    }
    return $false
}

function Test-OverbroadCodeIssueScope([string]$text) {
    foreach ($line in @($text -split "`r?`n")) {
        if ($line -notmatch '(?i)issues\.md') { continue }
        $hasPermission = $line -match '(?i)\b(?:may|can|should|must|includes?|records?|stores?)\b'
        $hasNonCodeIssue = $line -match '(?i)(?:dependency|environment|coverage config|ordinary uncovered|missing line|approval wait|stale evidence|unknown side effect)'
        $hasProhibition = $line -match '(?i)(?:must not|never|do not|exclude|not record)'
        if ($hasPermission -and $hasNonCodeIssue -and -not $hasProhibition) { return $true }
    }
    return $false
}

function Test-AgentSelfReviewPermission([string]$text) {
    return $text -match '(?is)(?:agent|workflow)[^\r\n.]{0,100}(?:may|can|is allowed to)[^\r\n.]{0,100}(?:Developer review|review status)[^\r\n.]{0,60}REVIEWED'
}

function Test-PrematureFinalReportPermission([string]$text) {
    foreach ($line in @($text -split "`r?`n")) {
        if ($line -notmatch '(?i)final-report\.md') { continue }
        $hasGeneration = $line -match '(?i)(?:generate|create|write|produce)'
        $hasIncompleteState = $line -match '(?i)(?:BLOCKED|CANNOT_VERIFY|ITERATING|before COMPLETE|incomplete|interrupted)'
        $hasProhibition = $line -match '(?i)\b(?:must not|never|do not|only after|cannot)\b'
        if ($hasGeneration -and $hasIncompleteState -and -not $hasProhibition) { return $true }
    }
    return $false
}

function Test-StaleFinalReportPermission([string]$text) {
    return $text -match '(?is)final[- ]report[^\r\n.]{0,120}(?:may|can|is allowed to)[^\r\n.]{0,100}(?:stale|local|historical)[^\r\n.]{0,60}(?:verification|evidence)'
}

function Test-FinalReportCompletionCycle([string]$skillText, [string]$templateText) {
    $reportIsPredicate = $skillText -match '(?i)final_report_references_fresh_final_verification'
    $templateRequiresComplete = $templateText -match '(?is)(?:only after|after)[^\r\n.]{0,80}(?:enters?|state is|is)[^\r\n.]{0,30}COMPLETE'
    return $reportIsPredicate -and $templateRequiresComplete
}

function Test-FinalReportForcesZeroSkipped([string]$text) {
    return $text -match '(?im)^-\s*Skipped:\s*`?0`?\s*$'
}

function Test-HardcodedCoverageTarget([string]$text) {
    $commandExample = $text -match '(?im)^.*(?:/fp-coverage|fp:fp-coverage)[^\r\n]*\b\d+(?:\.\d+)?%'
    $englishDefaultClaim = $text -match '(?im)^.*\bdefault\b[^\r\n]{0,100}(?:\btarget\b|\bcoverage\b)[^\r\n]{0,100}\b\d+(?:\.\d+)?%'
    $defaultWord = ([string][char]0x9ED8) + [char]0x8BA4
    $targetWords = '(?:target|coverage|' + ([regex]::Escape(([string][char]0x9608) + [char]0x503C)) + '|' + ([regex]::Escape(([string][char]0x8986) + [char]0x76D6 + [char]0x7387)) + ')'
    $chineseDefaultPattern = '(?im)^.*' + [regex]::Escape($defaultWord) + '[^\r\n]{0,100}' + $targetWords + '[^\r\n]{0,100}\b\d+(?:\.\d+)?%'
    $chineseDefaultClaim = $text -match $chineseDefaultPattern
    return $commandExample -or $englishDefaultClaim -or $chineseDefaultClaim
}

function Test-SpecialtyGraphLifecycle([string]$text, [string]$skillName) {
    foreach ($line in @($text -split "`r?`n")) {
        if ($line -notmatch '(?i)dirty-after-write') { continue }
        if ($line -match [regex]::Escape("``$skillName``") -and $line -match '(?i)post-write-sync') { return $true }
    }
    return $false
}

$skillPath = Join-Path $root 'skills\fp-coverage\SKILL.md'
$issuesTemplatePath = Join-Path $root 'skills\fp-coverage\issues-template.md'
$finalReportTemplatePath = Join-Path $root 'skills\fp-coverage\final-report-template.md'
$commandPath = Join-Path $root 'commands\fp-coverage.md'
$coverageGuidePath = Join-Path $root 'docs\user_guide\fp-coverage.md'
$mainGuidePath = Join-Path $root 'docs\user_guide\init-prd-start.md'
Assert-Condition (Test-Path $skillPath) 'skills/fp-coverage/SKILL.md is missing'
Assert-Condition (Test-Path $issuesTemplatePath) 'skills/fp-coverage/issues-template.md is missing'
Assert-Condition (Test-Path $finalReportTemplatePath) 'skills/fp-coverage/final-report-template.md is missing'
Assert-Condition (Test-Path $commandPath) 'commands/fp-coverage.md is missing'
Assert-Condition (Test-Path $coverageGuidePath) 'docs/user_guide/fp-coverage.md is missing'

$skill = Read-Utf8 $skillPath
$issuesTemplate = Read-Utf8 $issuesTemplatePath
$finalReportTemplate = Read-Utf8 $finalReportTemplatePath
$command = Read-Utf8 $commandPath
$coverageGuide = Read-Utf8 $coverageGuidePath
$mainGuide = Read-Utf8 $mainGuidePath
$readme = Read-Utf8 (Join-Path $root 'README.md')
$validator = Read-Utf8 (Join-Path $root 'scripts\validate-plugin.ps1')

$expectedDescription = 'description: Use when a user asks to raise unit-test, line, branch, statement, function, instruction, or combined coverage to an explicit target, close measured coverage gaps through behavior tests, or resume an interrupted coverage-improvement effort.'
Assert-Condition ($skill.Contains($expectedDescription)) 'skill discovery pointer advertises an unsupported coverage-config-only gate branch'
Assert-Condition ($command.Contains('Read and strictly execute `${CLAUDE_PLUGIN_ROOT}/skills/fp-coverage/SKILL.md` before acting.')) 'command does not require retrieval and execution of the authoritative coverage skill'

foreach ($anchor in @(
    'name: fp-coverage',
    'Use when',
    '`${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md`',
    '插件资源锚定',
    'RESOLVING',
    'BASELINING',
    'TRIAGING',
    'ITERATING',
    'FINAL_VERIFYING',
    'BLOCKED',
    'COMPLETE',
    'SAFE_WITH_DECLARED_OUTPUTS',
    'fp-docs/changes/<slug>-coverage/',
    'coverage-change-root',
    '.fp-coverage/progress.md',
    'bounded recovery index',
    '.fp-coverage/contract.md',
    '.fp-coverage/baselines/<run-id>.md',
    '.fp-coverage/batches/<batch-id>.md',
    '.fp-coverage/verifications/<run-id>.md',
    'issues-template.md',
    'final-report-template.md',
    'unit-test-discovered-code-issues-only',
    'production-code',
    'test-code',
    'COV-ISSUE-NNN',
    'Developer review',
    'final-report-only-at-completion-boundary',
    'completion boundary',
    'coverage.xml',
    'htmlcov/',
    'not a second completion authority',
    'fresh baseline',
    'failure triage',
    'owner batch',
    'periodic full refresh',
    'numerator',
    'denominator',
    'CANNOT_VERIFY',
    'current HEAD',
    'worktree fingerprint',
    'dirty-after-write',
    'never query a dirty graph',
    'post-write-sync',
    'codegraph sync <project-root> --quiet',
    'must not block completion',
    'coverage-tooling-bootstrap',
    'approval gate',
    'prefer-existing-coverage-toolchain',
    'forbid-bootstrap-scope-expansion',
    'django-fallback-only-without-existing-coverage',
    'Django',
    'pytest-cov',
    'pytest-django',
    'COVERAGE_FILE=<coverage-change-root>/.coverage',
    'persist dependency declaration',
    'fresh baseline after bootstrap'
)) {
    Assert-Condition ($skill.Contains($anchor)) "skill lost anchor: $anchor"
}

foreach ($anchor in @(
    'source/include/omit/exclude',
    'target-must-be-explicit-or-proven',
    'must not infer target from historical or local coverage',
    'branch',
    'metric',
    'freeze',
    'full_command_exit_code == 0',
    'exact_coverage >= target',
    'ordinary_failures == 0',
    'unexpected_skips == 0',
    'strict',
    'one issue',
    'protected paths',
    'evidence_matches_current_HEAD_and_worktree',
    'every_blocking_code_issue_has_valid_disposition',
    'final_report_references_fresh_final_verification'
)) {
    Assert-Condition ($skill.Contains($anchor)) "completion contract lost anchor: $anchor"
}

foreach ($forbidden in @(
    'forbid-expand-omit-exclude',
    'forbid-shrink-source-include',
    'forbid-disable-branch',
    'forbid-change-metric',
    'forbid-bulk-skip-xfail',
    'strict=False',
    'stale historical report',
    'local coverage',
    'theoretical upper bound',
    'git reset --hard',
    'git clean',
    'git restore .',
    'must not install or upgrade dependencies'
)) {
    Assert-Condition ($skill.Contains($forbidden)) "skill does not forbid shortcut: $forbidden"
}

foreach ($anchor in @(
    'Category',
    'Status',
    'Blocking',
    'Developer review',
    'Severity',
    'First seen',
    'Last verified',
    'Affected code',
    'Observed behavior',
    'Expected behavior',
    'Actual behavior',
    'Reproduction',
    'Code evidence',
    'Related evidence',
    'Impact',
    'Recommended action',
    'External issue',
    'Disposition',
    'production-code',
    'test-code',
    'OPEN',
    'RESOLVED',
    'EXTERNALIZED',
    'ACCEPTED_RISK',
    'INVALID',
    'PENDING',
    'REVIEWED'
)) {
    Assert-Condition ($issuesTemplate.Contains($anchor)) "issues template lost anchor: $anchor"
}

foreach ($anchor in @(
    'Result',
    'Final verification',
    'Test results',
    'Skipped',
    'Unexpected skips',
    'Measurement contract',
    'Work completed',
    'Code issues discovered',
    'Changed paths',
    'Managed xfails',
    'Side-effect reconciliation',
    'Completion predicates',
    'Remaining risks',
    'Evidence index',
    '.fp-coverage/verifications/<run-id>.md'
)) {
    Assert-Condition ($finalReportTemplate.Contains($anchor)) "final report template lost anchor: $anchor"
}

foreach ($anchor in @(
    '`${CLAUDE_PLUGIN_ROOT}/skills/fp-coverage/SKILL.md`',
    'Gate checksum',
    'metric-freeze',
    'owner batch',
    '.fp-coverage/progress.md',
    'not completion authority',
    'fresh full-suite',
    'exit code',
    'exact coverage',
    'coverage-only-no-production-write',
    'coverage-tooling-bootstrap',
    'RESOLVING',
    'CANNOT_VERIFY',
    'split evidence',
    'post-write-sync'
)) {
    Assert-Condition ($command.Contains($anchor)) "command lost anchor: $anchor"
}

$completionMutation = $skill + "`nFor expediency, local rounded coverage alone may also prove completion even when the full command exits non-zero."
Assert-Condition (Test-CompletionShortcut $completionMutation) 'completion shortcut detector misses a contradictory local/non-zero completion permission'
Assert-Condition (-not (Test-CompletionShortcut $skill)) 'skill contains a contradictory completion shortcut'
$metricMutation = $skill + "`nThe workflow may expand omit to reach the coverage target."
Assert-Condition (Test-MetricDriftPermission $metricMutation) 'metric-drift detector misses an explicit omit expansion permission'
Assert-Condition (-not (Test-MetricDriftPermission $skill)) 'skill contains a metric-drift permission'
$xfailMutation = $skill + "`nBulk xfail may be allowed when the deadline is close."
Assert-Condition (Test-XfailShortcut $xfailMutation) 'xfail shortcut detector misses a bulk-xfail permission'
Assert-Condition (-not (Test-XfailShortcut $skill)) 'skill contains an xfail shortcut'
$progressMutation = $skill + "`n.fp-coverage/progress.md is the completion authority."
Assert-Condition (Test-ProgressAuthorityContradiction $progressMutation) 'progress-authority detector misses a contradiction'
Assert-Condition (-not (Test-ProgressAuthorityContradiction $skill)) 'skill promotes progress to completion authority'
$dirtyGraphMutation = $skill + "`nThe workflow may query the dirty graph after write."
Assert-Condition (Test-DirtyGraphPermission $dirtyGraphMutation) 'dirty-graph detector misses a post-write query permission'
Assert-Condition (-not (Test-DirtyGraphPermission $skill)) 'skill permits querying a dirty graph'
$rootOutputMutation = $skill + "`nFor convenience, coverage.xml and htmlcov/ may be written to the project root."
Assert-Condition (Test-ProjectRootCoverageOutputPermission $rootOutputMutation) 'coverage-output detector misses a concrete project-root output permission'
$genericRootOutputMutation = $skill + "`nOther declared coverage reports may be written at the repo root."
Assert-Condition (Test-ProjectRootCoverageOutputPermission $genericRootOutputMutation) 'coverage-output detector misses a generic other-report root permission'
$splitRootOutputMutation = $skill + "`nCoverage outputs may be written temporarily.`nDestination: repository root."
Assert-Condition (Test-ProjectRootCoverageOutputPermission $splitRootOutputMutation) 'coverage-output detector misses a bounded multiline root permission'
$runThenMoveMutation = $skill + "`nCoverage artifacts can be generated at the project root and moved into coverage-change-root afterward."
Assert-Condition (Test-ProjectRootCoverageOutputPermission $runThenMoveMutation) 'coverage-output detector misses a run-then-move permission'
Assert-Condition (-not (Test-ProjectRootCoverageOutputPermission $skill)) 'skill permits coverage reports at the project root'
$terminalMissingToolMutation = $skill + "`nA project without a coverage tool must immediately stop as BLOCKED."
Assert-Condition (Test-TerminalMissingToolBlock $terminalMissingToolMutation) 'missing-tool detector misses a terminal BLOCKED-only rule'
$legacyMissingToolMutation = $skill + "`nCoverage-only mode must not install or upgrade dependencies; missing tooling is BLOCKED, not authorization to change the environment."
Assert-Condition (Test-TerminalMissingToolBlock $legacyMissingToolMutation) 'missing-tool detector misses the former terminal BLOCKED wording'
Assert-Condition (-not (Test-TerminalMissingToolBlock $skill)) 'skill makes missing coverage tooling a terminal block without a recommendation path'
$unapprovedInstallMutation = $skill + "`nThe workflow may install pytest-cov without user approval."
Assert-Condition (Test-UnapprovedCoverageInstall $unapprovedInstallMutation) 'approval detector misses an unapproved coverage install'
Assert-Condition (-not (Test-UnapprovedCoverageInstall $skill)) 'skill permits coverage dependency installation without approval'
$temporaryOnlyMutation = $skill + "`nInstall pytest-cov in the environment only without updating the dependency declaration."
Assert-Condition (Test-TemporaryOnlyBootstrap $temporaryOnlyMutation) 'dependency-persistence detector misses a temporary-only install'
Assert-Condition (-not (Test-TemporaryOnlyBootstrap $skill)) 'skill permits temporary-only coverage tooling installation'
$reuseBaselineMutation = $skill + "`nAfter bootstrap, reuse the previous coverage baseline."
Assert-Condition (Test-ReuseBaselineAfterBootstrap $reuseBaselineMutation) 'freshness detector misses baseline reuse after bootstrap'
Assert-Condition (-not (Test-ReuseBaselineAfterBootstrap $skill)) 'skill permits reusing stale baseline evidence after bootstrap'
$bootstrapScopeMutation = $skill + "`nThe approved coverage-tooling-bootstrap may upgrade unrelated packages and broaden the coverage config."
Assert-Condition (Test-BootstrapScopeExpansion $bootstrapScopeMutation) 'bootstrap-scope detector misses unrelated upgrades or config expansion'
Assert-Condition (-not (Test-BootstrapScopeExpansion $skill)) 'skill permits bootstrap scope expansion'
$djangoBundleMutation = $skill + "`nDjango projects should always install pytest + pytest-cov + pytest-django regardless of the existing runner."
Assert-Condition (Test-DjangoFallbackOverride $djangoBundleMutation) 'Django fallback detector misses an unconditional three-package bundle'
$djangoExistingMutation = $skill + "`nDjango bootstrap may override an existing coverage.py or tox coverage solution."
Assert-Condition (Test-DjangoFallbackOverride $djangoExistingMutation) 'Django fallback detector misses overriding an existing coverage solution'
Assert-Condition (-not (Test-DjangoFallbackOverride $skill)) 'skill contains an unconditional or overriding Django fallback'
$unboundedProgressMutation = $skill + "`nprogress.md must append every command and full result forever."
Assert-Condition (Test-UnboundedProgressPermission $unboundedProgressMutation) 'bounded-progress detector misses an append-all-history rule'
Assert-Condition (-not (Test-UnboundedProgressPermission $skill)) 'skill permits unbounded command history in progress.md'
$overbroadIssuesMutation = $skill + "`nissues.md may include dependency, environment, coverage config, and ordinary uncovered-line problems."
Assert-Condition (Test-OverbroadCodeIssueScope $overbroadIssuesMutation) 'code-issue scope detector misses non-code issues'
Assert-Condition (-not (Test-OverbroadCodeIssueScope $skill)) 'skill permits non-code problems in issues.md'
$selfReviewMutation = $skill + "`nThe agent may set Developer review to REVIEWED after reproducing the issue."
Assert-Condition (Test-AgentSelfReviewPermission $selfReviewMutation) 'developer-review detector misses agent self-review permission'
Assert-Condition (-not (Test-AgentSelfReviewPermission $skill)) 'skill permits the agent to self-approve developer review'
$prematureFinalMutation = $skill + "`nGenerate final-report.md while state is BLOCKED or CANNOT_VERIFY."
Assert-Condition (Test-PrematureFinalReportPermission $prematureFinalMutation) 'final-report timing detector misses incomplete-state generation'
Assert-Condition (-not (Test-PrematureFinalReportPermission $skill)) 'skill permits final report generation before COMPLETE'
$staleFinalMutation = $skill + "`nThe final report may rely on stale local verification evidence."
Assert-Condition (Test-StaleFinalReportPermission $staleFinalMutation) 'final-report freshness detector misses stale verification permission'
Assert-Condition (-not (Test-StaleFinalReportPermission $skill)) 'skill permits stale final-report evidence'
$completionCycleTemplateMutation = $finalReportTemplate + "`nGenerate final-report.md only after the workflow enters COMPLETE."
Assert-Condition (Test-FinalReportCompletionCycle $skill $completionCycleTemplateMutation) 'completion-cycle detector misses report-after-COMPLETE circularity'
Assert-Condition (-not (Test-FinalReportCompletionCycle $skill $finalReportTemplate)) 'skill and final report template create a COMPLETE/report circular dependency'
$zeroSkippedTemplateMutation = $finalReportTemplate + "`n- Skipped: ``0``"
Assert-Condition (Test-FinalReportForcesZeroSkipped $zeroSkippedTemplateMutation) 'final-report skip detector misses a forced zero fact count'
Assert-Condition (-not (Test-FinalReportForcesZeroSkipped $finalReportTemplate)) 'final report forces factual skipped count to zero instead of checking unexpected skips'

Assert-Condition ($command.Contains('fp-docs/changes/<slug>-coverage/')) 'command lacks the coverage change root'
Assert-Condition ($readme.Contains('commands/fp-coverage.md')) 'README lacks fp-coverage command'
Assert-Condition ($readme.Contains('`fp-coverage`')) 'README lacks fp-coverage skill'
Assert-Condition ($readme.Contains('docs/user_guide/fp-coverage.md')) 'README lacks the fp-coverage user guide link'
Assert-Condition ($mainGuide.Contains('fp-coverage.md')) 'main user guide lacks the fp-coverage guide link'
Assert-Condition (Test-SpecialtyGraphLifecycle $mainGuide 'fp-coverage') 'main user guide lacks fp-coverage dirty-after-write/post-write-sync lifecycle'
Assert-Condition (Test-SpecialtyGraphLifecycle $mainGuide 'fp-module-review') 'main user guide lacks fp-module-review dirty-after-write/post-write-sync lifecycle'
Assert-Condition ($readme.Contains('fresh full-suite')) 'README lacks fresh full-suite gate'
Assert-Condition ($readme.Contains('exact coverage')) 'README lacks exact coverage gate'
Assert-Condition ($readme.Contains('fp-docs/changes/<slug>-coverage/')) 'README lacks the coverage change artifact root'
Assert-Condition ($readme.Contains('coverage.xml') -and $readme.Contains('htmlcov/')) 'README lacks coverage report placement examples'
Assert-Condition ($readme.Contains('coverage-tooling-bootstrap') -and $readme.Contains('pytest-cov')) 'README lacks the approved missing-tool bootstrap and Django fallback'
Assert-Condition ($readme.Contains('issues.md') -and $readme.Contains('final-report.md')) 'README lacks code issues and final report artifacts'
Assert-Condition ($readme.Contains('.fp-coverage/contract.md') -and $readme.Contains('baselines/') -and $readme.Contains('batches/') -and $readme.Contains('verifications/')) 'README lacks split evidence paths'
Assert-Condition (-not (Test-HardcodedCoverageTarget $readme)) 'README coverage example or prose hardcodes a default target percentage'
Assert-Condition ($validator.Contains('test-coverage-contract.ps1')) 'global validator does not invoke fp-coverage suite'

foreach ($anchor in @(
    '/fp-coverage',
    'fp:fp-coverage',
    'target',
    'metric freeze',
    'coverage-tooling-bootstrap',
    'pytest-cov',
    'RESOLVING',
    'BASELINING',
    'TRIAGING',
    'ITERATING',
    'FINAL_VERIFYING',
    'fp-docs/changes/<slug>-coverage/',
    '.fp-coverage/progress.md',
    '.fp-coverage/contract.md',
    'baselines/',
    'batches/',
    'verifications/',
    'issues.md',
    'final-report.md',
    'full_command_exit_code == 0',
    'exact_coverage >= target'
)) {
    Assert-Condition ($coverageGuide.Contains($anchor)) "coverage guide lost anchor: $anchor"
}
Assert-Condition (-not ($coverageGuide -match '(?i)progress\.md[^\r\n]{0,120}(?:append-only|append every command|full command history)')) 'coverage guide restores unbounded progress history'
Assert-Condition (-not ($coverageGuide -match '(?is)final-report\.md[^.]{0,160}(?:after entering|only after)[^.]{0,40}COMPLETE')) 'coverage guide creates report-after-COMPLETE circularity'

foreach ($surface in @(
    @{ Name = 'coverage guide'; Text = $coverageGuide },
    @{ Name = 'README'; Text = $readme },
    @{ Name = 'main guide'; Text = $mainGuide }
)) {
    Assert-Condition (-not (Test-CompletionShortcut $surface.Text)) "$($surface.Name) permits weak or non-zero-exit completion evidence"
    Assert-Condition (-not (Test-MetricDriftPermission $surface.Text)) "$($surface.Name) permits metric drift"
    Assert-Condition (-not (Test-XfailShortcut $surface.Text)) "$($surface.Name) permits an xfail shortcut"
    Assert-Condition (-not (Test-ProgressAuthorityContradiction $surface.Text)) "$($surface.Name) promotes progress to completion authority"
    Assert-Condition (-not (Test-ProjectRootCoverageOutputPermission $surface.Text)) "$($surface.Name) permits coverage outputs at the project root"
    Assert-Condition (-not (Test-TerminalMissingToolBlock $surface.Text)) "$($surface.Name) makes missing coverage tooling a terminal block"
    Assert-Condition (-not (Test-UnapprovedCoverageInstall $surface.Text)) "$($surface.Name) permits unapproved coverage installation"
    Assert-Condition (-not (Test-UnboundedProgressPermission $surface.Text)) "$($surface.Name) permits unbounded progress history"
    Assert-Condition (-not (Test-OverbroadCodeIssueScope $surface.Text)) "$($surface.Name) permits non-code issues in issues.md"
    Assert-Condition (-not (Test-AgentSelfReviewPermission $surface.Text)) "$($surface.Name) permits agent self-review"
    Assert-Condition (-not (Test-PrematureFinalReportPermission $surface.Text)) "$($surface.Name) permits premature final-report generation"
    Assert-Condition (-not (Test-StaleFinalReportPermission $surface.Text)) "$($surface.Name) permits stale final-report evidence"
    Assert-Condition (-not (Test-FinalReportCompletionCycle $skill $surface.Text)) "$($surface.Name) creates report-after-COMPLETE circularity"
    Assert-Condition (-not (Test-HardcodedCoverageTarget $surface.Text)) "$($surface.Name) hardcodes a default target percentage"
}

$publicCoverageSurfaces = $coverageGuide + "`n" + $readme + "`n" + $mainGuide
foreach ($mutation in @(
    @{ Text = $publicCoverageSurfaces + "`nLocal rounded coverage may prove completion even when the final command exits non-zero."; Detector = { param($text) Test-CompletionShortcut $text }; Name = 'completion shortcut' },
    @{ Text = $publicCoverageSurfaces + "`nCoverage artifacts can be generated at the project root and moved into coverage-change-root afterward."; Detector = { param($text) Test-ProjectRootCoverageOutputPermission $text }; Name = 'run-then-move' },
    @{ Text = $publicCoverageSurfaces + "`nA project without a coverage tool must immediately stop as BLOCKED."; Detector = { param($text) Test-TerminalMissingToolBlock $text }; Name = 'terminal missing-tool block' },
    @{ Text = $publicCoverageSurfaces + "`nissues.md may include dependency, environment, coverage config, and ordinary uncovered-line problems."; Detector = { param($text) Test-OverbroadCodeIssueScope $text }; Name = 'overbroad issues scope' },
    @{ Text = $publicCoverageSurfaces + "`nGenerate final-report.md while state is BLOCKED or CANNOT_VERIFY."; Detector = { param($text) Test-PrematureFinalReportPermission $text }; Name = 'premature final report' },
    @{ Text = $publicCoverageSurfaces + "`nfp:fp-coverage raise coverage to 85%."; Detector = { param($text) Test-HardcodedCoverageTarget $text }; Name = 'Codex hardcoded target' },
    @{ Text = $publicCoverageSurfaces + "`nDefault coverage target is 85%."; Detector = { param($text) Test-HardcodedCoverageTarget $text }; Name = 'prose hardcoded target' }
)) {
    $detector = $mutation.Detector
    $mutationText = $mutation.Text
    $mutationName = $mutation.Name
    $detected = & $detector $mutationText
    Assert-Condition $detected "public-doc detector misses mutation: $mutationName"
}

$lineCount = @($skill -split "`r?`n").Count
Assert-Condition ($lineCount -le 500) "skill has $lineCount lines (limit: 500)"
Assert-Condition ($skill.Length -le 30000) "skill has $($skill.Length) characters (limit: 30,000)"
foreach ($template in @(
    @{ Name = 'issues template'; Text = $issuesTemplate },
    @{ Name = 'final report template'; Text = $finalReportTemplate },
    @{ Name = 'coverage guide'; Text = $coverageGuide }
)) {
    $templateLineCount = @($template.Text -split "`r?`n").Count
    Assert-Condition ($templateLineCount -le 500) "$($template.Name) has $templateLineCount lines (limit: 500)"
    Assert-Condition ($template.Text.Length -le 30000) "$($template.Name) has $($template.Text.Length) characters (limit: 30,000)"
}

Write-Output 'fp-coverage contract validation passed.'
