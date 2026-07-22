$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "Validation failed: $message"
    }
}

function Read-Utf8([string]$path) {
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

function Test-ForbiddenDesignDualRecipe([string]$text) {
    $classifiedText = $text
    $negatedKeepClause = '(?i)\b(?:do not|does not|never)\s+keep\b[^\r\n;.!?\u3002\uFF1B\uFF01\uFF1F]*'
    $negatedRelationClause = '(?i)\b(?:do not|does not|never)\s+(?:links?|linked|linking|points?|pointed|pointing|references?|referenced|referencing)\b[^\r\n;.!?\u3002\uFF1B\uFF01\uFF1F]*'
    $affirmativeText = [regex]::Replace($classifiedText, $negatedKeepClause, ' NEGATED_KEEP_CLAUSE ')
    $affirmativeText = [regex]::Replace($affirmativeText, $negatedRelationClause, ' NEGATED_RELATION_CLAUSE ')
    $patterns = @(
        '(?im)^[^\r\n]*(?:stable\s+(?:file|entrypoint)|\u7A33\u5B9A\u5165\u53E3)[^\r\n]{0,200}(?:summary|\u6458\u8981)[^\r\n]{0,400}design/(?:backend|frontend)/00-index\.md'
        '(?im)^[^\r\n]*design/(?<end>backend|frontend)/00-index\.md[^\r\n]{0,400}design/\k<end>\.md[^\r\n]{0,120}(?:links?|linking|\u94FE\u63A5)'
        '(?im)^[^\r\n]*design/(?<end>backend|frontend)\.md[^\r\n]{0,160}(?:summary|navigation|links?|\u6458\u8981|\u5BFC\u822A|\u94FE\u63A5)[^\r\n]{0,400}design/\k<end>/00-index\.md'
    )
    foreach ($pattern in $patterns) {
        if ($affirmativeText -match $pattern) { return $true }
    }
    $normalizedAffirmativeText = [regex]::Replace($affirmativeText, '\s+', ' ').Trim()
    $affirmativeSummaryChain = '(?i)\bkeep\s+`?design/(?<chainEnd>backend|frontend)\.md`?\s+as\s+(?:a\s+)?summary\b.{0,320}?\b(?:links?|linking|points?|pointing|references?|referencing|(?:is\s+)?(?:a\s+)?reference)\s+(?:(?:to|at)\s+)?`?design/\k<chainEnd>/00-index\.md`?'
    if ($normalizedAffirmativeText -match $affirmativeSummaryChain) { return $true }
    return $false
}

function Test-ForbiddenPlanDualRecipe([string]$text) {
    $classifiedText = $text

    # Mask only explicitly negated, sentence-bounded clauses that govern a
    # relevant retention or relation verb. A preceding negated sentence or
    # semicolon clause cannot hide a later affirmative recipe.
    $relevantVerb = 'keep|retain|preserve|maintain|leave|create|link|point|reference|store|place|write|move|split'
    $negatedClause = "(?i)\b(?:do not|does not|must not|cannot|never)\s+(?=[^\r\n;.!?\u3002\uFF1B\uFF01\uFF1F]{0,120}\b(?:$relevantVerb)(?:s|ed|ing)?\b)[^\r\n;.!?\u3002\uFF1B\uFF01\uFF1F]*"
    $affirmativeText = [regex]::Replace($classifiedText, $negatedClause, ' NEGATED_PLAN_CLAUSE ')
    $chineseNegatedClause = '(?:\u4E0D\u5F97|\u4E0D\u80FD|\u4E0D\u5141\u8BB8|\u7981\u6B62|\u7EDD\u4E0D\u80FD|\u4E0D\u8981)\s*(?=[^\r\n;.!?\u3002\uFF1B\uFF01\uFF1F]{0,80}(?:\u4FDD\u7559|\u4FDD\u5B58|\u7EF4\u6301|\u7559\u4E0B|\u521B\u5EFA|\u94FE\u63A5|\u5F15\u7528|\u5B58\u50A8|\u653E\u5165|\u5199\u5165|\u79FB\u5165|\u62C6\u5206))[^\r\n;.!?\u3002\uFF1B\uFF01\uFF1F]*'
    $affirmativeText = [regex]::Replace($affirmativeText, $chineseNegatedClause, ' NEGATED_CHINESE_PLAN_CLAUSE ')
    $markdownNormalized = [regex]::Replace($affirmativeText, '[`*_]', '')
    $normalized = [regex]::Replace($markdownNormalized, '\s+', ' ').Trim()

    # Build semantic segments rather than correlating paths by character
    # distance. Explicit small/split markers scope only their clause; text
    # without a marker remains unscoped and is evaluated conservatively.
    $smallMarker = '(?:\bsmall\s+form\b|\bsmall\s+mode\b|\u5C0F\u578B(?:\u5F62\u5F0F|\u6A21\u5F0F)|\u5C0F\u8BA1\u5212(?:\u5F62\u5F0F|\u6A21\u5F0F))'
    $splitMarker = '(?:\bsplit\s+form\b|\bsplit\s+mode\b|\u62C6\u5206(?:\u5F62\u5F0F|\u6A21\u5F0F)|\u5206\u7247(?:\u5F62\u5F0F|\u6A21\u5F0F))'
    $modeMarker = "(?i)(?<small>$smallMarker)|(?<split>$splitMarker)"
    $segments = @()
    $clauseBoundary = '(?i)(?<=[;!?\u3002\uFF1B\uFF01\uFF1F])\s*|(?<!\.md)(?<=\.)\s+'
    foreach ($clause in [regex]::Split($normalized, $clauseBoundary)) {
        $trimmedClause = $clause.Trim()
        if (-not $trimmedClause) { continue }
        $markers = [regex]::Matches($trimmedClause, $modeMarker)
        if ($markers.Count -eq 0) {
            $segments += [pscustomobject]@{ Mode = 'unscoped'; Text = $trimmedClause }
            continue
        }
        if ($markers[0].Index -gt 0) {
            $prefix = $trimmedClause.Substring(0, $markers[0].Index).Trim()
            if ($prefix) { $segments += [pscustomobject]@{ Mode = 'unscoped'; Text = $prefix } }
        }
        for ($i = 0; $i -lt $markers.Count; $i++) {
            $start = $markers[$i].Index
            $end = if ($i + 1 -lt $markers.Count) { $markers[$i + 1].Index } else { $trimmedClause.Length }
            $mode = if ($markers[$i].Groups['small'].Success) { 'small' } else { 'split' }
            $segments += [pscustomobject]@{ Mode = $mode; Text = $trimmedClause.Substring($start, $end - $start).Trim() }
        }
    }

    $splitText = (($segments | Where-Object Mode -eq 'split' | ForEach-Object Text) -join ' ')
    $unscopedText = (($segments | Where-Object Mode -eq 'unscoped' | ForEach-Object Text) -join ' ')
    $role = '(?:summary|navigation|constraints?|interface\s+ledger|header|coverage(?:\s+owner)?|canonical\s+entrypoint|stable\s+entrypoint|index|\u7A33\u5B9A\u6458\u8981|\u6458\u8981|\u5BFC\u822A|\u7EA6\u675F|\u63A5\u53E3\u53F0\u8D26|\u5934\u90E8|\u8986\u76D6|\u89C4\u8303\u5165\u53E3|\u7A33\u5B9A\u5165\u53E3|\u7D22\u5F15)'

    foreach ($end in @('backend', 'frontend')) {
        $stablePath = [regex]::Escape("tasks/plan-$end.md")
        $splitPrefix = [regex]::Escape("tasks/$end/") + '(?:00-index\.md|[A-Za-z0-9][A-Za-z0-9._<>-]*\.md)?'
        $hasStableRole = {
            param([string]$segmentText)
            if (-not $segmentText) { return $false }
            $patterns = @(
                "(?i)\b(?:keep|retain|preserve|maintain|leave)\s+$stablePath(?:\s+(?:as|for)\s+(?:a\s+|the\s+)?)?[^;.!?\u3002\uFF1B\uFF01\uFF1F]{0,160}$role"
                "(?i)$stablePath[^;.!?\u3002\uFF1B\uFF01\uFF1F]{0,120}\b(?:keeps?|is\s+(?:kept|retained|preserved|maintained|left)|remains?|serves?|acts?|becomes?)\b[^;.!?\u3002\uFF1B\uFF01\uFF1F]{0,140}$role"
                "(?i)\bstable\s+(?:file|entrypoint)\b[^;.!?\u3002\uFF1B\uFF01\uFF1F]{0,100}\b(?:keeps?|is\s+(?:kept|retained|preserved|maintained|left)|remains?|serves?|acts?|becomes?)\b[^;.!?\u3002\uFF1B\uFF01\uFF1F]{0,140}$role"
                "(?:\u4FDD\u7559|\u4FDD\u5B58|\u7EF4\u6301|\u7559\u4E0B)\s+$stablePath[^;.!?\u3002\uFF1B\uFF01\uFF1F]{0,160}$role"
                "$stablePath[^;.!?\u3002\uFF1B\uFF01\uFF1F]{0,120}(?:\u4FDD\u7559|\u7EF4\u6301|\u4F5C\u4E3A|\u7528\u4F5C|\u4ECD\u662F|\u53D8\u6210)[^;.!?\u3002\uFF1B\uFF01\uFF1F]{0,120}$role"
            )
            foreach ($pattern in $patterns) { if ($segmentText -match $pattern) { return $true } }
            return $false
        }
        $hasSplitDetail = {
            param([string]$segmentText)
            if (-not $segmentText -or -not ($segmentText -match "(?i)$splitPrefix")) { return $false }
            $signals = @(
                '(?i)\b(?:links?|linked|linking|points?|pointed|pointing|references?|referenced|referencing)\b'
                '(?i)\b(?:store|stores|stored|storing|place|places|placed|placing|write|writes|writing|move|moves|moved|moving|split)\b'
                '(?:\u94FE\u63A5|\u5F15\u7528|\u5B58\u50A8|\u653E\u5165|\u5199\u5165|\u79FB\u5165|\u62C6\u5206\u5230|\u5F52\u5165)'
                '(?i)\b(?:details?|executable\s+tasks?|task\s+(?:groups?|bodies)|detailed\s+(?:tasks?|task\s+groups?))\b[^;.!?\u3002\uFF1B\uFF01\uFF1F]{0,160}\b(?:live|lives|move|moves|are\s+stored|must\s+be\s+split|are\s+split|go|goes)\b'
                "(?i)$splitPrefix[^;.!?\u3002\uFF1B\uFF01\uFF1F]{0,140}\b(?:stores?|owns?|contains?|holds?)\b[^;.!?\u3002\uFF1B\uFF01\uFF1F]{0,120}\b(?:details?|tasks?|task\s+groups?|task\s+bodies)\b"
                "(?:\u8BE6\u7EC6\u4EFB\u52A1|\u53EF\u6267\u884C\u4EFB\u52A1|\u4EFB\u52A1\u7EC4|\u4EFB\u52A1\u6B63\u6587)[^;.!?\u3002\uFF1B\uFF01\uFF1F]{0,120}(?:\u5199\u5165|\u5B58\u50A8|\u653E\u5165|\u4F4D\u4E8E|\u62C6\u5206\u5230)"
            )
            foreach ($signal in $signals) { if ($segmentText -match $signal) { return $true } }
            return $false
        }

        $splitHasStableRole = & $hasStableRole $splitText
        $unscopedHasStableRole = & $hasStableRole $unscopedText
        $splitHasDetails = & $hasSplitDetail $splitText
        $unscopedHasDetails = & $hasSplitDetail $unscopedText

        # Stable roles scoped to small form are valid and deliberately absent
        # from these correlations. Split-scoped or unscoped stable roles are
        # forbidden when the same end also owns split details.
        if ($splitHasStableRole -and ($splitHasDetails -or $unscopedHasDetails)) { return $true }
        if ($unscopedHasStableRole -and ($unscopedHasDetails -or $splitHasDetails)) { return $true }
    }
    return $false
}

function Test-UnconditionalStablePlanFirstRead([string]$text) {
    foreach ($line in ($text -split "`r?`n")) {
        $plain = [regex]::Replace($line, '[`*_]', '')
        if ($plain -notmatch '(?i)(?:\bread(?:s|ing)?\s|\u8BFB\u53D6|\u5148\u8BFB|\u5148\u8BFB\u53D6)') { continue }
        if ($plain -notmatch '(?i)tasks/plan-(?:backend|frontend)\.md') { continue }
        if ($plain -match '(?i)detect both alternatives before reading either') { continue }
        if ($plain -match '(?i)(?:only when|only if|if no|when no|unless).{0,180}tasks/(?:backend|frontend)/00-index\.md') { continue }
        if ($plain -match '(?:\u4EC5\u5F53|\u53EA\u6709|\u4E0D\u5B58\u5728|\u7F3A\u5931).{0,180}tasks/(?:backend|frontend)/00-index\.md') { continue }
        return $true
    }
    return $false
}

function Test-MalformedTasksKindInlineCode([string]$text) {
    return $text -match '(?m)`<[^\r\n`]*tasks`-kind[^\r\n]*>`'
}

function Test-SemanticAutoSplitTrigger([string]$text) {
    $plain = [regex]::Replace($text, '[`*_]', '')
    $semanticScope = '(?i)(?:\b(?:(?:multiple|several|independently\s+readable|more\s+than\s+one)|(?:(?:two|three|four|five|six|seven|eight|nine|\d+)(?:\s+or\s+more)?))\s+(?:features?|modules?|components?|subsystems?|page\s+areas?|task\s+groups?|ownership\s+domains?|change\s+scopes?)\b|\bmulti[- ](?:feature|module|component|subsystem|page|area|task|domain|scope)s?\b|(?:多个|多项|若干|两个以上)[^;.!?\u3002\uFF1B\uFF01\uFF1F]{0,32}(?:features?|modules?|components?|subsystems?|page\s+areas?|task\s+groups?|ownership\s+domains?|change\s+scopes?|功能|模块|组件|子系统|页面区域|任务组|所有权域|变更范围))'
    $affirmativeSplit = '(?i)(?:\b(?:automatically\s+|directly\s+)?(?:select|choose|use|adopt|switch\s+to|require)\s+(?:the\s+)?split\s+form\b|\bdefault(?:s|ed|ing)?\s+to\s+(?:the\s+)?split\s+(?:form|mode)\b|\b(?:triggers?|forces?|requires?)\b[^;.!?\u3002\uFF1B\uFF01\uFF1F]{0,40}\bsplit\s+form\b|\b(?:should|must|needs?\s+to|has\s+to)\s+be\s+split\b|\bsplit\b(?=\s*(?:$|,|\b(?:whenever|when|if|the|this|that|into|across)\b))|(?:自动|直接|立即)?(?:选择|使用|采用|切换到)\s*split\s+form|(?:触发|强制|要求)[^;.!?\u3002\uFF1B\uFF01\uFF1F]{0,20}(?:split\s+form|拆分|分片)|拆分|分片)'
    $allowedCondition = '(?i)(?:(?:the\s+)?user\s+explicitly\s+approves(?:\s+(?:it|split\s+form))?|(?:an\s+)?applicable\s+target-project\s+setting\s+explicitly\s+requires(?:\s+(?:it|split\s+form))?|(?:the\s+)?small\s+(?:form|plan)[^;.!?\u3002\uFF1B\uFF01\uFF1F]{0,80}(?:exceed(?:s)?\s+(?:either\s+(?:hard\s+)?limit|500\s+lines[^;.!?\u3002\uFF1B\uFF01\uFF1F]{0,40}30,000\s+characters)))'
    $allowedSplitGate = "(?i)\b(?:can\s+)?(?:select|choose|use|adopt|switch\s+to|require)\s+(?:the\s+)?split\s+form\s+only\s+(?:when|if)\s+$allowedCondition"
    $negatedSplit = '(?i)(?:\b(?:do\s+not|does\s+not|must\s+not|never)\b[^,;.!?\u3002\uFF0C\uFF1B\uFF01\uFF1F]{0,100}(?:split\s+form|trigger|force|require|select|choose|use)|\bonly\s+after\s+split\s+form\s+has\s+been\s+selected\b|(?:不|不会|不得|不能|无需|不应)[^,;.!?\u3002\uFF0C\uFF1B\uFF01\uFF1F]{0,40}(?:触发|强制|要求|选择|使用|拆分|分片)|仅用于[^,;.!?\u3002\uFF0C\uFF1B\uFF01\uFF1F]{0,40}(?:已选\s*split\s+form|分片边界))'
    $chinesePostSplitNonTrigger = '(?:多个)?功能、子系统、页面区域、任务组或\s+ownership\s+domain\s+只用于拆分后的语义边界[，,]\s*不单独触发拆分'
    $plain = [regex]::Replace($plain, $chinesePostSplitNonTrigger, ' NEGATED_SPLIT_CLAUSE ')

    foreach ($clause in [regex]::Split($plain, '(?:\r?\n|[;.!?\u3002\uFF1B\uFF01\uFF1F])')) {
        $affirmativeClause = [regex]::Replace($clause, $allowedSplitGate, ' ALLOWED_SPLIT_GATE ')
        $affirmativeClause = [regex]::Replace($affirmativeClause, $negatedSplit, ' NEGATED_SPLIT_CLAUSE ')
        if ($affirmativeClause -match $semanticScope -and $affirmativeClause -match $affirmativeSplit) {
            return $true
        }
    }
    return $false
}

function Test-ContainsEveryAnchor([string]$text, [string[]]$anchors) {
    foreach ($anchor in $anchors) {
        if (-not $text.Contains($anchor)) {
            return $false
        }
    }
    return $true
}

function Test-ObsoleteSemanticFirstGuidance([string]$text) {
    return $text -match '(?i)semantic-first' -or $text.Contains('语义优先')
}

function Test-ForbiddenBroadPrdAutoTrigger([string]$text) {
    $plain = [regex]::Replace($text, '[`*_]', '')
    $broadIntent = '(?i)(?:rough\s+(?:idea|requirement)|product\s+idea|pain\s+point|feature\s+request|user\s+story|\u4EA7\u54C1\u60F3\u6CD5|\u529F\u80FD\u8BF7\u6C42|\u7528\u6237\u6545\u4E8B|\u75DB\u70B9|\u7C97\u7565\u9700\u6C42|\u534A\u6210\u54C1\u9700\u6C42)'
    foreach ($clause in [regex]::Split($plain, '(?:\r?\n|[;!?\u3002\uFF1B\uFF01\uFF1F])')) {
        if ($clause -notmatch '(?i)fp-prd' -or $clause -notmatch $broadIntent) { continue }
        if ($clause -match '(?i)(?:does\s+not|do\s+not|\bnever\b|not\s+(?:automatically\s+)?trigger|only\s+(?:when|for)\b|\u4E0D\u4F1A\u81EA\u52A8\u89E6\u53D1|\u4E0D\u81EA\u52A8\u89E6\u53D1|\u53EA\u6709[^,\uFF0C]{0,160}\u660E\u786E)') { continue }
        $positivePatterns = @(
            '(?i)\bPRD\s+from\s+(?:a\s+)?rough\s+idea\b'
            "(?i)$broadIntent.{0,180}\b(?:automatically\s+)?(?:triggers?|activates?|invokes?|discovers?|routes?)\b.{0,120}\bfp-prd\b"
            "(?i)\bfp-prd\b.{0,160}\b(?:triggers?|activates?|invokes?|discovers?|routes?)\b.{0,160}$broadIntent"
            "(?i)\b(?:use|run|invoke)\s+fp-prd\b.{0,80}\b(?:whenever|when)\b.{0,160}$broadIntent"
            "(?i)\bfp-prd\b.{0,100}\buse\s+when\b.{0,160}$broadIntent"
            "$broadIntent[^\r\n;.!?\u3002\uFF1B\uFF01\uFF1F]{0,120}(?:\u65F6\s*)?(?:\u8FD0\u884C|\u8C03\u7528|\u89E6\u53D1|\u4F7F\u7528|\u8FDB\u5165)[^\r\n;.!?\u3002\uFF1B\uFF01\uFF1F]{0,80}\bfp-prd\b"
            "(?:\u8FD0\u884C|\u8C03\u7528|\u89E6\u53D1|\u4F7F\u7528|\u8FDB\u5165)[^\r\n;.!?\u3002\uFF1B\uFF01\uFF1F]{0,40}\bfp-prd\b[^\r\n;.!?\u3002\uFF1B\uFF01\uFF1F]{0,160}$broadIntent"
            "\bfp-prd\b[^\r\n;.!?\u3002\uFF1B\uFF01\uFF1F]{0,120}$broadIntent[^\r\n;.!?\u3002\uFF1B\uFF01\uFF1F]{0,80}(?:\u65F6\s*)?(?:\u8FD0\u884C|\u8C03\u7528|\u89E6\u53D1|\u4F7F\u7528|\u8FDB\u5165)"
        )
        foreach ($pattern in $positivePatterns) {
            if ($clause -match $pattern) { return $true }
        }
    }
    return $false
}

function Test-ProposalMdOnlyOutputSummary([string]$text) {
    $plain = [regex]::Replace($text, '[`*_]', '')
    foreach ($line in ($plain -split "`r?`n")) {
        $hasBothForms = $line -match '(?i)(?:^|[^A-Za-z0-9_-])proposal\.md\b' -and $line -match '(?i)proposal/00-index\.md'
        $explicitAlternative = $line -match '(?i)(?:\bOR\b|\bsmall\s+form\b|\bsplit\s+form\b|\bmutually\s+exclusive\b|\u6216|\u5C0F\u578B\u5F62\u5F0F|\u62C6\u5206\u5F62\u5F0F|\u4E92\u65A5|\u4E8C\u9009\u4E00)'
        if ($hasBothForms -and $explicitAlternative) { continue }
        foreach ($clause in [regex]::Split($line, '(?:[;!?\u3002\uFF1B\uFF01\uFF1F])')) {
            if ($clause -notmatch '(?i)(?:^|[^A-Za-z0-9_-])proposal\.md\b') { continue }
            $outputVerb = '(?i)(?:\bgenerate(?:s|d|ing)?\b|\bcreate(?:s|d|ing)?\b|\bwrite(?:s|written|writing)?\b|\boutput(?:s|ted|ting)?\b|\bproduce(?:s|d|ing)?\b|\u751F\u6210|\u521B\u5EFA|\u5199\u5165|\u8F93\u51FA|\u4EA7\u51FA)'
            if ($clause -notmatch $outputVerb) { continue }
            $directNegation = "(?i)(?:\bnever\b|\bdo\s+not\b|\bmust\s+not\b|\bcannot\b|\u4E0D\u80FD|\u4E0D\u5F97|\u7981\u6B62|\u4E0D\u5141\u8BB8|\u7EDD\u4E0D\u80FD)\s*(?:\u53EA\s*)?(?:$outputVerb)[^;!?\u3002\uFF1B\uFF01\uFF1F]{0,120}proposal\.md"
            if ($clause -match $directNegation) { continue }
            return $true
        }
    }
    return $false
}

$plugin = Read-Utf8 (Join-Path $root '.claude-plugin\plugin.json') | ConvertFrom-Json
$codexPlugin = Read-Utf8 (Join-Path $root '.codex-plugin\plugin.json') | ConvertFrom-Json
$marketplace = Read-Utf8 (Join-Path $root '.claude-plugin\marketplace.json') | ConvertFrom-Json
$marketplacePlugin = @($marketplace.plugins | Where-Object { $_.name -eq $plugin.name })[0]

Assert-Condition ($null -ne $marketplacePlugin) "marketplace entry for '$($plugin.name)' is missing"
Assert-Condition ($marketplacePlugin.version -eq $plugin.version) "plugin and marketplace versions differ"
Assert-Condition ($marketplacePlugin.source -eq './') "marketplace source must remain './'"
Assert-Condition ($codexPlugin.name -eq $plugin.name) 'Claude Code and Codex plugin names differ'
$codexBaseVersion = @($codexPlugin.version -split '\+', 2)[0]
Assert-Condition ($codexBaseVersion -eq $plugin.version) 'Codex plugin base version must match the Claude Code plugin version'
Assert-Condition ($codexPlugin.skills -eq './skills/') 'Codex plugin must expose the repository skills directory'
Assert-Condition ($codexPlugin.interface.displayName -and $codexPlugin.interface.shortDescription -and $codexPlugin.interface.longDescription) 'Codex plugin interface metadata is incomplete'

$commands = @(Get-ChildItem (Join-Path $root 'commands') -Filter 'fp-*.md' -File)
$skills = @(Get-ChildItem (Join-Path $root 'skills') -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') })
$sharedPath = Join-Path $root 'skills\_shared\workspace-rules.md'
$artifactLayoutPath = Join-Path $root 'skills\_shared\artifact-layout.md'
$codeGraphPath = Join-Path $root 'skills\_shared\codegraph.md'

Assert-Condition (Test-Path $sharedPath) 'shared workspace contract is missing'
$sharedText = Read-Utf8 $sharedPath
foreach ($anchor in @('target repository root', 'fp-docs/manifest.md', 'smallest relevant', 'stale-prone', 'Current code', 'Approved PRD', 'Only `fp-init`', '`fp-archive`')) {
    Assert-Condition ($sharedText.Contains($anchor)) "shared workspace contract is missing: $anchor"
}
foreach ($anchor in @('Process document language', 'Chinese by default', 'current explicit user instruction', 'target-project setting', 'necessary English')) {
    Assert-Condition ($sharedText.Contains($anchor)) "shared workspace contract is missing process-document language rule: $anchor"
}

Assert-Condition (Test-Path $codeGraphPath) 'shared CodeGraph contract is missing'
$codeGraphText = Read-Utf8 $codeGraphPath
Assert-Condition (@($codeGraphText -split "`r?`n").Count -le 500) 'shared CodeGraph contract exceeds 500 lines'
Assert-Condition ($codeGraphText.Length -le 30000) 'shared CodeGraph contract exceeds 30,000 characters'
foreach ($anchor in @(
    'npm install -g @colbymchenry/codegraph@latest',
    'npm prefix -g',
    'codegraph install --target=auto --location=global --yes',
    'codegraph init <project-root>',
    'codegraph status <project-root> --json',
    'codegraph sync <project-root> --quiet',
    'MCP -> CLI -> native search',
    'navigation-hint-only',
    'must not auto-install Node.js',
    'must not block FeaturePilot',
    'dirty-after-write',
    'never query a dirty graph',
    'pre-query sync',
    'post-write sync',
    'at most one post-write sync'
)) {
    Assert-Condition ($codeGraphText.Contains($anchor)) "shared CodeGraph contract is missing: $anchor"
}

Assert-Condition (Test-Path $artifactLayoutPath) 'shared artifact-layout contract is missing'
$artifactLayoutText = Read-Utf8 $artifactLayoutPath
foreach ($anchor in @('500 lines', '30,000 characters', 'mutually exclusive', '| Order | File | Kind | Owns |', 'prd/00-index.md', 'proposal/00-index.md', 'design/backend/00-index.md', 'design/frontend/00-index.md', 'tasks/backend/00-index.md', 'tasks/frontend/00-index.md', 'Producer', 'Consumer')) {
    Assert-Condition ($artifactLayoutText.Contains($anchor)) "shared artifact-layout contract is missing: $anchor"
}
foreach ($anchor in @('Default to the small form', 'user explicitly approves split form', 'target-project setting explicitly requires split form', 'does not by itself trigger split form')) {
    Assert-Condition ($artifactLayoutText.Contains($anchor)) "shared artifact-layout contract is missing compact-first selection rule: $anchor"
}
Assert-Condition ($artifactLayoutText.Contains('Reject every dual-form combination')) 'shared artifact-layout contract is missing absolute dual-form rejection'
Assert-Condition ($artifactLayoutText.Contains('There is no read-only compatibility mode')) 'shared artifact-layout contract must reject historical compatibility reads'
Assert-Condition (-not $artifactLayoutText.Contains('Classify recognized historical design/task stable-file-plus-directory pairs')) 'shared artifact-layout contract still classifies legacy pairs for compatibility'
Assert-Condition ($artifactLayoutText.Contains('exact `## Fragment Manifest` section')) 'shared artifact-layout contract is missing the exact split-index section heading'
Assert-Condition ($artifactLayoutText.Contains('must declare every such edge exactly once') -and $artifactLayoutText.Contains('never substitutes for or adds an edge')) 'shared artifact-layout contract does not require exact owner-graph edge declarations'

$publicSurfaces = @(
    [pscustomobject]@{ Name = 'AGENTS.md'; Text = Read-Utf8 (Join-Path $root 'AGENTS.md') }
    [pscustomobject]@{ Name = 'README.md'; Text = Read-Utf8 (Join-Path $root 'README.md') }
    [pscustomobject]@{ Name = 'docs\user_guide\init-prd-start.md'; Text = Read-Utf8 (Join-Path $root 'docs\user_guide\init-prd-start.md') }
    [pscustomobject]@{ Name = '.codex-plugin\plugin.json interface.longDescription'; Text = [string]$codexPlugin.interface.longDescription }
)
$publicContractExpectations = @{
    'AGENTS.md' = @(
        '预计完整逻辑产物不超过 500 行和 30,000 字符时默认使用 small form'
        '只有预计超过任一硬限制、用户明确批准 split form，或目标项目设置明确要求 split form 时才拆分'
        '功能、子系统、页面区域、任务组或 ownership domain 只用于拆分后的语义边界，不单独触发拆分'
        '过程文档的叙述性内容默认使用中文'
        '保留必要英文'
        '当前用户明确语言指令优先于目标项目设置'
    )
    'README.md' = @(
        '预计完整逻辑产物不超过 500 行和 30,000 字符时默认使用 small form'
        '只有预计超过任一硬限制、用户明确批准 split form，或目标项目设置明确要求 split form 时才拆分'
        '功能、子系统、页面区域、任务组或 ownership domain 只用于拆分后的语义边界，不单独触发拆分'
        '过程文档的叙述性内容默认使用中文'
        '保留必要英文'
        '当前用户明确语言指令优先于目标项目设置'
    )
    'docs\user_guide\init-prd-start.md' = @(
        '预计完整逻辑产物不超过 500 行和 30,000 字符时默认使用 small form'
        '只有预计超过任一硬限制、用户明确批准 split form，或目标项目设置明确要求 split form 时才拆分'
        '功能、子系统、页面区域、任务组或 ownership domain 只用于拆分后的语义边界，不单独触发拆分'
        '过程文档的叙述性内容默认使用中文'
        '保留必要英文'
        '当前用户明确语言指令优先于目标项目设置'
    )
    '.codex-plugin\plugin.json interface.longDescription' = @(
        'small is the default within 500 lines and 30,000 characters'
        'split requires an expected hard-limit overflow, explicit user approval, or an explicit target-project setting'
        'Process-document prose is Chinese by default'
        'necessary code and exact technical/schema terms'
        'A current explicit user language instruction overrides the target-project setting'
    )
}
$publicArtifactAnchors = @(
    'compact-first'
    'mutually exclusive'
    '500'
    '30,000'
    'prd/00-index.md'
    'proposal/00-index.md'
    'design/backend/00-index.md'
    'design/frontend/00-index.md'
    'tasks/backend/00-index.md'
    'tasks/frontend/00-index.md'
    'two-end-only'
    'no read-only compatibility'
)
$fullAnchorPublicAutoSplitMutation = $publicSurfaces[0].Text + "`nMultiple subsystems default to split form."
Assert-Condition (Test-ContainsEveryAnchor $fullAnchorPublicAutoSplitMutation $publicContractExpectations['AGENTS.md']) 'public auto-split mutation fixture lost a per-surface contract anchor'
Assert-Condition (Test-ContainsEveryAnchor $fullAnchorPublicAutoSplitMutation $publicArtifactAnchors) 'public auto-split mutation fixture lost a shared public artifact anchor'
$fullAnchorPublicContractAccepted = (Test-ContainsEveryAnchor $fullAnchorPublicAutoSplitMutation $publicContractExpectations['AGENTS.md']) -and (Test-ContainsEveryAnchor $fullAnchorPublicAutoSplitMutation $publicArtifactAnchors) -and (-not (Test-SemanticAutoSplitTrigger $fullAnchorPublicAutoSplitMutation)) -and (-not (Test-ObsoleteSemanticFirstGuidance $fullAnchorPublicAutoSplitMutation))
Assert-Condition (-not $fullAnchorPublicContractAccepted) 'public validation predicate accepts a full-anchor surface with appended `Multiple subsystems default to split form.`'
$missingSemanticScopesMutation = $publicSurfaces[0].Text.Replace('功能、子系统、页面区域、任务组或 ', '')
Assert-Condition (-not (Test-ContainsEveryAnchor $missingSemanticScopesMutation $publicContractExpectations['AGENTS.md'])) 'public contract accepts removal of the feature/subsystem/page-area/task-group non-trigger scopes'
Assert-Condition (Test-ObsoleteSemanticFirstGuidance ($publicSurfaces[0].Text + "`nSemantic-first")) 'obsolete guidance detector misses case-variant Semantic-first wording'
Assert-Condition (Test-ObsoleteSemanticFirstGuidance ($publicSurfaces[0].Text + "`n语义优先")) 'obsolete guidance detector misses Chinese 语义优先 wording'
foreach ($surface in $publicSurfaces) {
    foreach ($anchor in $publicContractExpectations[$surface.Name]) {
        Assert-Condition ($surface.Text.Contains($anchor)) "$($surface.Name) is missing the public compact-first/process-language contract: $anchor"
    }
    Assert-Condition (-not (Test-SemanticAutoSplitTrigger $surface.Text)) "$($surface.Name) retains a semantic auto-split trigger"
    Assert-Condition (-not (Test-ObsoleteSemanticFirstGuidance $surface.Text)) "$($surface.Name) retains obsolete semantic-first/语义优先 public guidance"
}
Assert-Condition (Test-ForbiddenBroadPrdAutoTrigger 'A rough idea automatically triggers fp-prd.') 'broad PRD auto-trigger detector misses rough ideas'
Assert-Condition (Test-ForbiddenBroadPrdAutoTrigger 'Use fp-prd whenever the user provides a product idea, pain point, or feature request.') 'broad PRD auto-trigger detector misses product/pain/feature intent'
Assert-Condition (-not (Test-ForbiddenBroadPrdAutoTrigger 'An ordinary product idea or pain point does not automatically trigger fp-prd; use it only for explicit PRD-authoring intent.')) 'broad PRD auto-trigger detector rejects an explicit negative contract'
Assert-Condition (Test-ProposalMdOnlyOutputSummary 'fp-propose generates fp-docs/changes/<slug>/proposal.md.') 'proposal-only detector misses a stable-only output summary'
Assert-Condition (-not (Test-ProposalMdOnlyOutputSummary 'fp-propose generates proposal.md OR proposal/00-index.md plus fragments.')) 'proposal-only detector rejects an explicit small-or-split summary'
$chineseBroadAutoTriggerMutation = '"\u6709\u4EA7\u54C1\u60F3\u6CD5\u3001\u75DB\u70B9\u6216\u529F\u80FD\u8BF7\u6C42\u65F6\u8FD0\u884C fp-prd"' | ConvertFrom-Json
$chineseProposalOnlyMutation = '"fp-propose \u751F\u6210 proposal.md\uFF1B\u4E0D\u80FD\u8DF3\u8FC7\u786E\u8BA4"' | ConvertFrom-Json
$chineseProposalUnrelatedSplitMutation = '"fp-propose \u751F\u6210 proposal.md\uFF1B\u53E6\u4E00\u4E2A\u793A\u4F8B\u63D0\u5230 proposal/00-index.md"' | ConvertFrom-Json
$chineseBackendPlanDualMutation = '"\u62C6\u5206\u5F62\u5F0F\u4FDD\u7559 tasks/plan-backend.md \u4F5C\u4E3A\u7A33\u5B9A\u6458\u8981\uFF0C\u5E76\u5C06\u4EFB\u52A1\u5199\u5165 tasks/backend/"' | ConvertFrom-Json
$chineseFrontendPlanDualMutation = '"\u62C6\u5206\u5F62\u5F0F\u4FDD\u7559 tasks/plan-frontend.md \u4F5C\u4E3A\u7A33\u5B9A\u6458\u8981\uFF0C\u5E76\u5C06\u4EFB\u52A1\u5199\u5165 tasks/frontend/"' | ConvertFrom-Json
$chineseBroadNegativeControl = '"\u4EA7\u54C1\u60F3\u6CD5\u3001\u75DB\u70B9\u6216\u529F\u80FD\u8BF7\u6C42\u4E0D\u4F1A\u81EA\u52A8\u89E6\u53D1 fp-prd\uFF1B\u53EA\u6709\u660E\u786E\u7F16\u5199 PRD \u610F\u56FE\u624D\u4F7F\u7528\u3002"' | ConvertFrom-Json
$chineseProposalNegativeControl = '"\u4E0D\u80FD\u53EA\u751F\u6210 proposal.md\uFF1B\u5FC5\u987B\u751F\u6210 proposal.md \u6216 proposal/00-index.md\u3002"' | ConvertFrom-Json
$chineseBackendPlanExclusiveControl = '"\u540E\u7AEF\u5C0F\u578B\u5F62\u5F0F\u53EA\u4F7F\u7528 tasks/plan-backend.md\uFF1B\u62C6\u5206\u5F62\u5F0F\u53EA\u4F7F\u7528 tasks/backend/00-index.md\uFF1B\u4E24\u8005\u4E0D\u5F97\u5E76\u5B58\u3002"' | ConvertFrom-Json
$chineseFrontendPlanExclusiveControl = '"\u524D\u7AEF\u5C0F\u578B\u5F62\u5F0F\u53EA\u4F7F\u7528 tasks/plan-frontend.md\uFF1B\u62C6\u5206\u5F62\u5F0F\u53EA\u4F7F\u7528 tasks/frontend/00-index.md\uFF1B\u4E24\u8005\u4E0D\u5F97\u5E76\u5B58\u3002"' | ConvertFrom-Json
$chineseBackendLegacyReadControl = '"Consumer \u53EA\u8BFB\u517C\u5BB9\u53EF\u68C0\u67E5\u5386\u53F2 tasks/plan-backend.md \u4F5C\u4E3A\u6458\u8981\u5E76\u8BFB\u53D6 tasks/backend/\uFF0C\u4F46\u4E0D\u5F97\u5199\u5165\u4EFB\u4E00\u8DEF\u5F84\u3002"' | ConvertFrom-Json
$chineseFrontendLegacyReadControl = '"Consumer \u53EA\u8BFB\u517C\u5BB9\u53EF\u68C0\u67E5\u5386\u53F2 tasks/plan-frontend.md \u4F5C\u4E3A\u6458\u8981\u5E76\u8BFB\u53D6 tasks/frontend/\uFF0C\u4F46\u4E0D\u5F97\u5199\u5165\u4EFB\u4E00\u8DEF\u5F84\u3002"' | ConvertFrom-Json
$chineseBroadVerbMutations = @(
    ('"\u6709\u4EA7\u54C1\u60F3\u6CD5\u65F6\u8C03\u7528 fp-prd"' | ConvertFrom-Json)
    ('"\u75DB\u70B9\u89E6\u53D1 fp-prd"' | ConvertFrom-Json)
    ('"\u529F\u80FD\u8BF7\u6C42\u65F6\u4F7F\u7528 fp-prd"' | ConvertFrom-Json)
    ('"\u6709\u7528\u6237\u6545\u4E8B\u65F6\u8FDB\u5165 fp-prd"' | ConvertFrom-Json)
)
Assert-Condition (Test-ForbiddenBroadPrdAutoTrigger $chineseBroadAutoTriggerMutation) 'broad PRD auto-trigger detector misses the exact Chinese run-on-intent mutation'
foreach ($mutation in $chineseBroadVerbMutations) {
    Assert-Condition (Test-ForbiddenBroadPrdAutoTrigger $mutation) 'broad PRD auto-trigger detector misses a Chinese call/trigger/use/enter verb form'
}
Assert-Condition (Test-ProposalMdOnlyOutputSummary $chineseProposalOnlyMutation) 'proposal-only detector lets unrelated Chinese negation hide stable-only output'
Assert-Condition (Test-ProposalMdOnlyOutputSummary $chineseProposalUnrelatedSplitMutation) 'proposal-only detector lets an unrelated split-path mention hide stable-only output'
Assert-Condition (Test-ForbiddenPlanDualRecipe $chineseBackendPlanDualMutation) 'plan dual-recipe detector misses the exact Chinese backend split/stable mutation'
Assert-Condition (Test-ForbiddenPlanDualRecipe $chineseFrontendPlanDualMutation) 'plan dual-recipe detector misses the Chinese frontend split/stable mutation'
Assert-Condition (-not (Test-ForbiddenBroadPrdAutoTrigger $chineseBroadNegativeControl)) 'broad PRD auto-trigger detector rejects the Chinese explicit-negative contract'
Assert-Condition (-not (Test-ProposalMdOnlyOutputSummary $chineseProposalNegativeControl)) 'proposal-only detector rejects Chinese direct negation with both forms'
Assert-Condition (-not (Test-ProposalMdOnlyOutputSummary ('"\u4E0D\u80FD\u53EA\u751F\u6210 proposal.md\u3002"' | ConvertFrom-Json))) 'proposal-only detector rejects Chinese direct negation of stable-only output'
Assert-Condition (-not (Test-ProposalMdOnlyOutputSummary 'Do not generate proposal.md only.')) 'proposal-only detector rejects English direct negation of stable-only output'
Assert-Condition (-not (Test-ForbiddenPlanDualRecipe $chineseBackendPlanExclusiveControl)) 'plan dual-recipe detector rejects Chinese backend mutual exclusion'
Assert-Condition (-not (Test-ForbiddenPlanDualRecipe $chineseFrontendPlanExclusiveControl)) 'plan dual-recipe detector rejects Chinese frontend mutual exclusion'

foreach ($surface in $publicSurfaces) {
    Assert-Condition (-not (Test-ForbiddenBroadPrdAutoTrigger $surface.Text)) "$($surface.Name) advertises a broad rough/product/pain/feature intent as an automatic fp-prd trigger"
    Assert-Condition (-not (Test-ProposalMdOnlyOutputSummary $surface.Text)) "$($surface.Name) contains a proposal.md-only output summary"
    Assert-Condition (-not (Test-ForbiddenPlanDualRecipe $surface.Text)) "$($surface.Name) retains a forbidden stable-plan-plus-split-directory recipe"
}
$exactPublicPrdTrigger = 'Use fp-prd only when the user explicitly invokes /fp-prd or $fp-prd, or explicitly asks to create, write, revise, or complete a PRD or product requirements document.'
$obsoleteChineseDiscoveryTrigger = '"\u53EA\u6709\u5728\u7528\u6237\u660E\u786E\u8C03\u7528 `/fp-prd`\uFF0C\u6216\u660E\u786E\u8981\u6C42\u521B\u5EFA\u3001\u7F16\u5199\u3001\u4FEE\u8BA2\u6216\u8865\u5168 PRD \u65F6\uFF0C\u624D\u53D1\u73B0\u5E76\u4F7F\u7528 `fp-prd`"' | ConvertFrom-Json
$obsoleteChineseStartTrigger = '"\u53EA\u6709\u5728\u7528\u6237\u660E\u786E\u8C03\u7528 `/fp-prd`\uFF0C\u6216\u660E\u786E\u8981\u6C42\u521B\u5EFA\u3001\u7F16\u5199\u3001\u4FEE\u8BA2\u6216\u8865\u5168 PRD \u65F6\uFF0C\u624D\u542F\u52A8\u8BE5 skill"' | ConvertFrom-Json
foreach ($surface in $publicSurfaces) {
    $exactTriggerCount = [regex]::Matches($surface.Text, [regex]::Escape($exactPublicPrdTrigger)).Count
    Assert-Condition ($exactTriggerCount -eq 1) "$($surface.Name) must contain the exact public fp-prd trigger contract exactly once"
    foreach ($obsoleteTrigger in @(
        'Discover `fp-prd` only when the user explicitly invokes `/fp-prd` or explicitly asks to create, write, revise, or complete a PRD.'
        'fp-prd activates only for an explicit /fp-prd command or explicit PRD-authoring intent.'
        $obsoleteChineseDiscoveryTrigger
        $obsoleteChineseStartTrigger
    )) {
        Assert-Condition (-not $surface.Text.Contains($obsoleteTrigger)) "$($surface.Name) still contains an obsolete adjacent fp-prd trigger sentence"
    }
}
$agentsText = Read-Utf8 (Join-Path $root 'AGENTS.md')
$expectedAgentsPrdIntentRow = '| Explicit `/fp-prd`, `$fp-prd`, or explicit request to create, write, revise, or complete a PRD or product requirements document | `skills/fp-prd/SKILL.md` |'
$agentsPrdIntentRows = @([regex]::Matches($agentsText, '(?m)^\|[^\r\n]*`skills/fp-prd/SKILL\.md`\s*\|\s*$') | ForEach-Object { $_.Value.Trim() })
Assert-Condition ($agentsPrdIntentRows.Count -eq 1 -and $agentsPrdIntentRows[0] -ceq $expectedAgentsPrdIntentRow) 'AGENTS.md fp-prd intent row must use the exact canonical positive trigger set'
foreach ($surface in $publicSurfaces) {
    foreach ($anchor in $publicArtifactAnchors) {
        Assert-Condition ($surface.Text.Contains($anchor)) "$($surface.Name) is missing the public artifact/discovery contract: $anchor"
    }
}

foreach ($command in $commands) {
    $skillName = $command.BaseName
    $skillPath = Join-Path $root "skills\$skillName\SKILL.md"
    Assert-Condition (Test-Path $skillPath) "$($command.Name) has no matching skills/$skillName/SKILL.md"
    $commandText = Read-Utf8 $command.FullName
    $commandFrontmatter = [regex]::Match($commandText, '(?s)\A---\r?\n(?<body>.*?)\r?\n---')
    Assert-Condition ($commandFrontmatter.Success) "$($command.Name) has invalid frontmatter boundaries"
    Assert-Condition ($commandFrontmatter.Groups['body'].Value -match '(?m)^description:\s*\S') "$($command.Name) has no description"
    Assert-Condition ($commandText -match [regex]::Escape($skillName)) "$($command.Name) does not invoke or identify $skillName"
    $expectedCommandSkillAnchor = '`${CLAUDE_PLUGIN_ROOT}/skills/' + $skillName + '/SKILL.md`'
    Assert-Condition ($commandText.Contains($expectedCommandSkillAnchor)) "$($command.Name) does not load its matching skill from the official Claude plugin root"
    $backtick = [char]96
    $recursiveShortName = "调用并严格执行 $backtick$skillName$backtick skill"
    $recursiveNamespacedName = "调用并严格执行 $backtick" + 'fp:' + "$skillName$backtick skill"
    Assert-Condition (-not ($commandText.Contains($recursiveShortName) -or $commandText.Contains($recursiveNamespacedName))) "$($command.Name) recursively invokes its own registered command/skill name"
    $consumerRelativeFallback = 'Codex fallback：读取 `skills/' + $skillName + '/SKILL.md`'
    Assert-Condition (-not $commandText.Contains($consumerRelativeFallback)) "$($command.Name) retains a consumer-relative Codex fallback"
    Assert-Condition ($commandText.Contains('Gate checksum')) "$($command.Name) is missing its gate checksum"
    $commandLines = @($commandText -split "`r?`n").Count
    Assert-Condition ($commandLines -le 20) "$($command.Name) is no longer a thin adapter ($commandLines lines)"
}

foreach ($skill in $skills) {
    $skillPath = Join-Path $skill.FullName 'SKILL.md'
    $skillText = Read-Utf8 $skillPath
    $frontmatter = [regex]::Match($skillText, '(?s)\A---\r?\n(?<body>.*?)\r?\n---')
    Assert-Condition ($frontmatter.Success) "$($skill.Name)/SKILL.md has invalid frontmatter boundaries"
    $frontmatterKeys = @([regex]::Matches($frontmatter.Groups['body'].Value, '(?m)^([a-zA-Z0-9_-]+):') | ForEach-Object { $_.Groups[1].Value })
    Assert-Condition ($frontmatterKeys.Count -eq 2 -and $frontmatterKeys -contains 'name' -and $frontmatterKeys -contains 'description') "$($skill.Name)/SKILL.md frontmatter must contain only name and description"
    Assert-Condition ($frontmatter.Groups['body'].Value -match '(?m)^description:\s*\S') "$($skill.Name)/SKILL.md has no description"
    $lineCount = @($skillText -split "`r?`n").Count
    Assert-Condition ($lineCount -le 500) "$($skill.Name)/SKILL.md has $lineCount lines (limit: 500)"
    Assert-Condition ($skillText -match "(?m)^name:\s*$([regex]::Escape($skill.Name))\s*$") "$($skill.Name)/SKILL.md frontmatter name does not match its directory"
    Assert-Condition (-not $skillText.Contains('${CLAUDE_SKILL_DIR}')) "$($skill.Name)/SKILL.md uses unsupported CLAUDE_SKILL_DIR instead of an official plugin root"
    Assert-Condition ($skillText.Contains('在 Codex/Markdown 中，从 available-skill 元数据提供的当前技能入口映射同一个 `skills/...` 插件相对路径')) "$($skill.Name)/SKILL.md lacks the Codex installed-skill path mapping"
    $anchoredWorkspaceContract = '`${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md`'
    Assert-Condition ($skillText.Contains($anchoredWorkspaceContract)) "$($skill.Name)/SKILL.md does not load the anchored shared workspace contract"
}

$codeGraphContractValidator = Join-Path $root 'scripts\test-codegraph-contract.ps1'
Assert-Condition (Test-Path $codeGraphContractValidator) 'focused CodeGraph contract validator is missing'
& powershell -NoProfile -ExecutionPolicy Bypass -File $codeGraphContractValidator
Assert-Condition ($LASTEXITCODE -eq 0) 'focused CodeGraph contract validator failed'

$exploreContractValidator = Join-Path $root 'scripts\test-explore-contract.ps1'
Assert-Condition (Test-Path $exploreContractValidator) 'focused fp-explore contract validator is missing'
& powershell -NoProfile -ExecutionPolicy Bypass -File $exploreContractValidator
Assert-Condition ($LASTEXITCODE -eq 0) 'focused fp-explore contract validator failed'

$prdSkillPath = Join-Path $root 'skills\fp-prd\SKILL.md'
$prdSkillText = Read-Utf8 $prdSkillPath
$prdFrontmatter = [regex]::Match($prdSkillText, '(?s)\A---\r?\n(?<body>.*?)\r?\n---')
$prdDescriptionMatch = [regex]::Match($prdFrontmatter.Groups['body'].Value, '(?m)^description:\s*(?<value>.+?)\s*$')
$expectedPrdDescription = 'Use when a user explicitly invokes /fp-prd or $fp-prd, or explicitly asks to create, write, revise, or complete a PRD or product requirements document.'
Assert-Condition ($prdDescriptionMatch.Success -and $prdDescriptionMatch.Groups['value'].Value -ceq $expectedPrdDescription) 'fp-prd discovery description must be the explicit-only trigger contract'
Assert-Condition (-not ($prdFrontmatter.Groups['body'].Value.Contains('provides a product idea, feature request, user story, pain point, rough requirement'))) 'fp-prd discovery metadata still advertises ordinary rough requirements as triggers'
$prdOutputContract = [regex]::Match($prdSkillText, '(?s)## Output\s*(?<body>.*)\z').Groups['body'].Value
Assert-Condition ($prdOutputContract -match '(?i)every successful.*(?:MUST|required|always)') 'fp-prd output contract must require the next-step prompt after every successful completion'
Assert-Condition ($prdOutputContract.Contains('`/fp-start <slug>`')) 'fp-prd output contract must include the exact copyable /fp-start <slug> command'

$startSkillText = Read-Utf8 (Join-Path $root 'skills\fp-start\SKILL.md')
$sddSkillText = Read-Utf8 (Join-Path $root 'skills\fp-execute-sdd\SKILL.md')
$startCommandText = Read-Utf8 (Join-Path $root 'commands\fp-start.md')

Assert-Condition (-not $sddSkillText.Contains('fixes loop until reviewed clean')) 'fp-execute-sdd still promises an unbounded clean-review loop'
Assert-Condition (-not $sddSkillText.Contains('Repeat until `Spec Compliance: PASS`')) 'fp-execute-sdd still repeats review until clean without a total cap'
$sddFixLoopSection = [regex]::Match($sddSkillText, '(?s)## Fix Loop\s*(?<body>.*?)\s*## Model Selection')
Assert-Condition ($sddFixLoopSection.Success) 'fp-execute-sdd Fix Loop section is missing'
foreach ($anchor in @(
    'Each task review scope has a maximum of three reviews'
    'The initial review is attempt 1'
    'must not dispatch a fourth review'
    'review debt'
    'main-flow blocker'
    'restore the recorded review attempt'
    'Every non-pass result at attempt 1 or 2 must transition through exactly one table row to the next attempt'
    'repair the code, review package, or missing evidence'
    'regenerate the package'
    'dispatch the next reviewer'
    'must not repeat the same attempt'
    'Combined task review verdict'
    'Task non-pass transition table'
    '`Spec Compliance: FAIL` with no severity-bucket finding'
    'Malformed or unclassified combination'
    'append the raw verdict'
    'increment exactly once'
    'dispatch a corrected fresh reviewer without a fixer'
)) {
    Assert-Condition ($sddFixLoopSection.Groups['body'].Value.Contains($anchor)) "fp-execute-sdd is missing an evidence-only failure transition: $anchor"
}

$taskReviewerPrompt = Read-Utf8 (Join-Path $root 'skills\fp-execute-sdd\task-reviewer-prompt.md')
$fixPrompt = Read-Utf8 (Join-Path $root 'skills\fp-execute-sdd\fix-prompt.md')
$taskReviewerInputs = [regex]::Match($taskReviewerPrompt, '(?s)## Inputs\s*(?<body>.*?)\s*## Review Method')
$taskReviewerMethodAndRules = [regex]::Match($taskReviewerPrompt, '(?s)## Review Method\s*(?<body>.*?)\s*## Required Output File Format')
$taskReviewerSeverity = [regex]::Match($taskReviewerPrompt, '(?s)## Severity Calibration\s*(?<body>.*?)\s*Do not pre-dismiss')
Assert-Condition ($taskReviewerInputs.Success -and $taskReviewerMethodAndRules.Success -and $taskReviewerSeverity.Success) 'task reviewer prompt sections are missing'
Assert-Condition ($taskReviewerInputs.Groups['body'].Value.Contains('Review attempt: {REVIEW_ATTEMPT} of {MAX_REVIEW_ATTEMPTS}')) 'task reviewer inputs are missing bounded review attempt context'
foreach ($anchor in @(
    'Potential main-flow impact evidence'
    'The controller, not the reviewer, decides whether a failed finding blocks the main flow'
)) {
    Assert-Condition ($taskReviewerMethodAndRules.Groups['body'].Value.Contains($anchor)) "task reviewer method/rules are missing bounded review context: $anchor"
}
Assert-Condition ($taskReviewerSeverity.Groups['body'].Value.Contains('Minor findings alone require `Code Quality: APPROVED`')) 'task reviewer severity section allows Minor-only NEEDS FIXES'

$fixPromptContext = [regex]::Match($fixPrompt, '(?s)Model expectation:.*?(?<body>.*?)\s*## Mission')
$fixPromptMission = [regex]::Match($fixPrompt, '(?s)## Mission\s*(?<body>.*?)\s*## Required Reading')
$fixPromptReading = [regex]::Match($fixPrompt, '(?s)## Required Reading\s*(?<body>.*?)\s*## Required Behavior')
$fixPromptBehavior = [regex]::Match($fixPrompt, '(?s)## Required Behavior\s*(?<body>.*?)\s*## Report Append Format')
Assert-Condition ($fixPromptContext.Success -and $fixPromptMission.Success -and $fixPromptReading.Success -and $fixPromptBehavior.Success) 'fix prompt bounded-review sections are missing'
foreach ($anchor in @('Review scope: {REVIEW_SCOPE}', 'Review attempt that produced these findings: {LAST_COMPLETED_REVIEW_ATTEMPT} of {MAX_REVIEW_ATTEMPTS}')) {
    Assert-Condition ($fixPromptContext.Groups['body'].Value.Contains($anchor)) "fix prompt context is missing bounded review value: $anchor"
}
foreach ($anchor in @('For final review scope', 'may touch multiple completed-task files')) {
    Assert-Condition ($fixPromptMission.Groups['body'].Value.Contains($anchor)) "fix prompt mission is missing final-scope behavior: $anchor"
}
foreach ($anchor in @('Task brief (task scope; controller must pass `N/A` for final scope):', 'Latest task/final review:')) {
    Assert-Condition ($fixPromptReading.Groups['body'].Value.Contains($anchor)) "fix prompt reading section is incomplete: $anchor"
}
foreach ($anchor in @('A fixer may be dispatched only after review attempt 1 or 2 of 3', 'Do not request or imply a fourth review')) {
    Assert-Condition ($fixPromptBehavior.Groups['body'].Value.Contains($anchor)) "fix prompt behavior is missing bounded review guard: $anchor"
}

$sddFinalReviewSection = [regex]::Match($sddSkillText, '(?s)## Completion and Final Review\s*(?<body>.*?)\s*## Invariant recap')
Assert-Condition ($sddFinalReviewSection.Success) 'fp-execute-sdd final review section is missing'
foreach ($anchor in @(
    'Final verdict mapping'
    '`PASS_WITH_NOTES` ends the final review scope with non-blocking review debt'
    '`FAIL` is a failed final review attempt'
    '`BLOCKED` is a main-flow blocker'
    'Final severity mapping'
    '`Critical` stays Critical; `High` maps to Important and is a main-flow blocker; `Medium` maps to Important; `Low` maps to Minor'
    'restore the recorded final review attempt'
    'Review scope: final'
    '`BRIEF_PATH=N/A`'
    'fp-review is required for final review scope'
    'clean-snapshot checkpoint before consuming each final review attempt'
    'commit authorized implementation and execution artifacts'
    '`git status --short` is empty'
    'A failed clean-snapshot checkpoint does not consume a review attempt'
    'commit the final review report and ledger evidence without rerunning review'
    'A final `BLOCKED` verdict consumes its current attempt'
    'increment exactly once before the next final review'
    'explicit user authorization may open a new final review scope'
)) {
    Assert-Condition ($sddFinalReviewSection.Groups['body'].Value.Contains($anchor)) "fp-execute-sdd final review mapping is incomplete: $anchor"
}
Assert-Condition (-not $sddFinalReviewSection.Groups['body'].Value.Contains('Otherwise dispatch `task-reviewer-prompt.md` at whole-change scope')) 'fp-execute-sdd still uses a task-schema fallback for final review'

foreach ($anchor in @(
    'Default execution path'
    'Load `fp-execute` by default'
    'Only use `fp-execute-sdd` when the user explicitly requests it'
    'SDD continuation mode gate'
    'Step-confirmation SDD'
    'Automatic-continuation SDD'
)) {
    Assert-Condition ($startSkillText.Contains($anchor)) "fp-start is missing default direct-execution contract: $anchor"
}
Assert-Condition (-not $startSkillText.Contains('Execution strategy gate')) 'fp-start must not force a direct-versus-SDD choice after plan confirmation'
Assert-Condition ($startSkillText.Contains('Ask this gate only after the user explicitly requests SDD')) 'fp-start must not ask the SDD continuation gate before SDD is explicitly requested'
$startExecutionSection = [regex]::Match($startSkillText, '(?s)## 阶段 4：执行任务\s*(?<body>.*?)\s*## 最终汇报')
Assert-Condition ($startExecutionSection.Success) 'fp-start execution section is missing'
foreach ($anchor in @(
    '一次 inline 自审'
    'Direct execution does not own a final review scope'
    'load `fp-review` once after `fp-execute` returns'
)) {
    Assert-Condition ($startExecutionSection.Groups['body'].Value.Contains($anchor)) "fp-start is missing lightweight direct-execution integration: $anchor"
}

foreach ($anchor in @(
    'Step-confirmation SDD'
    'Automatic-continuation SDD'
    'progress updates, not return points'
    'immediately select and dispatch the next eligible task'
    'Execution strategy: SDD'
    'SDD continuation mode:'
    'Never silently switch modes'
)) {
    Assert-Condition ($sddSkillText.Contains($anchor)) "fp-execute-sdd is missing continuation contract: $anchor"
}

Assert-Condition ($startCommandText.Contains('默认加载 `fp-execute`')) 'fp-start command checksum is missing default direct execution'
Assert-Condition ($startCommandText.Contains('只有用户明确要求 `fp-execute-sdd`')) 'fp-start command checksum is missing explicit SDD opt-in'
Assert-Condition ($startCommandText.Contains('SDD 逐项确认或自动连续')) 'fp-start command checksum is missing SDD continuation selection'

foreach ($publicExecutionDoc in @(
    @{ Path = 'README.md'; Text = Read-Utf8 (Join-Path $root 'README.md') }
    @{ Path = 'docs\user_guide\init-prd-start.md'; Text = Read-Utf8 (Join-Path $root 'docs\user_guide\init-prd-start.md') }
)) {
    Assert-Condition ($publicExecutionDoc.Text.Contains('默认执行入口是 `fp-execute`')) "$($publicExecutionDoc.Path) is missing the default direct executor"
    Assert-Condition ($publicExecutionDoc.Text.Contains('只有用户明确要求 `fp-execute-sdd`')) "$($publicExecutionDoc.Path) is missing explicit SDD opt-in"
}

$requirementProducerContracts = @{
    'skills\fp-prd\SKILL.md' = @('prd.md', 'prd/00-index.md', 'fragment manifest', 'logical template', 'mutually exclusive')
    'skills\fp-prd\prd-template.md' = @('prd.md', 'prd/00-index.md', 'fragment manifest', 'logical template', 'mutually exclusive')
    'skills\fp-propose\SKILL.md' = @('proposal.md', 'proposal/00-index.md', 'fragment manifest', 'logical template', 'mutually exclusive')
    'skills\fp-propose\proposal-template.md' = @('proposal.md', 'proposal/00-index.md', 'fragment manifest', 'logical template', 'mutually exclusive')
}

foreach ($entry in $requirementProducerContracts.GetEnumerator()) {
    $producerText = Read-Utf8 (Join-Path $root $entry.Key)
    foreach ($anchor in $entry.Value) {
        Assert-Condition ($producerText.Contains($anchor)) "$($entry.Key) is missing small-or-split producer contract: $anchor"
    }
}

$compactFirstContracts = @{
    'skills\fp-prd\SKILL.md' = @('default to the small form', '500 lines', '30,000 characters', 'user explicitly approves split form', 'applicable target-project setting explicitly requires it', 'do not trigger split form by themselves')
    'skills\fp-prd\prd-template.md' = @('default to the small form', '500 lines', '30,000 characters', 'user explicitly approves split form', 'applicable target-project setting explicitly requires it', 'do not trigger split form by themselves')
    'skills\fp-prd-grill-me\SKILL.md' = @('default to the small form', '500 lines', '30,000 characters', 'user explicitly approves split form', 'applicable target-project setting explicitly requires it', 'do not trigger split form by themselves')
    'skills\fp-propose\SKILL.md' = @('default to the small form', '500 lines', '30,000 characters', 'user explicitly approves split form', 'applicable target-project setting explicitly requires it', 'do not trigger split form by themselves')
    'skills\fp-propose\proposal-template.md' = @('default to the small form', '500 lines', '30,000 characters', 'user explicitly approves split form', 'applicable target-project setting explicitly requires it', 'do not trigger split form by themselves')
    'skills\fp-brainstorm\SKILL.md' = @('默认选择 small form', '500 行', '30,000 字符', '用户明确批准 split form', '目标项目设置明确要求 split form', '不单独触发拆分')
    'skills\fp-brainstorm\design-template.md' = @('默认选择 small form', '500 行', '30,000 字符', '用户明确批准 split form', '目标项目设置明确要求 split form', '不单独触发拆分')
    'skills\fp-figma\SKILL.md' = @('默认选择 small form', '500 行', '30,000 字符', '用户明确批准 split form', '目标项目设置明确要求 split form', '不单独触发拆分')
    'skills\fp-plan\SKILL.md' = @('default to the small form', '500 lines', '30,000 characters', 'user explicitly approves split form', 'applicable target-project setting explicitly requires it', 'only after split form has been selected')
    'skills\fp-plan-backend\SKILL.md' = @('default to the small form', '500 lines', '30,000 characters', 'user explicitly approves split form', 'applicable target-project setting explicitly requires it', 'only after split form has been selected')
    'skills\fp-plan-frontend\SKILL.md' = @('default to the small form', '500 lines', '30,000 characters', 'user explicitly approves split form', 'applicable target-project setting explicitly requires it', 'only after split form has been selected')
}
$compactFirstFiles = @($compactFirstContracts.Keys)
foreach ($relativePath in $compactFirstFiles) {
    $text = Read-Utf8 (Join-Path $root $relativePath)
    foreach ($anchor in $compactFirstContracts[$relativePath]) {
        Assert-Condition ($text.Contains($anchor)) "$relativePath is missing compact-first contract anchor: $anchor"
    }
}

$processLanguageContracts = @{
    'skills\fp-prd\prd-template.md' = '叙述性内容默认使用中文'
    'skills\fp-propose\proposal-template.md' = '叙述性内容默认使用中文'
    'skills\fp-brainstorm\design-template.md' = '叙述性内容默认使用中文'
    'skills\fp-plan-backend\plan-template.md' = '叙述性内容默认使用中文'
    'skills\fp-plan-frontend\plan-template.md' = '叙述性内容默认使用中文'
    'skills\fp-review\SKILL.md' = 'Process document language'
    'skills\fp-review\final-review-template.md' = '叙述性内容默认使用中文'
    'skills\fp-archive\SKILL.md' = '叙述性内容默认使用中文'
}
foreach ($relativePath in $processLanguageContracts.Keys) {
    $text = Read-Utf8 (Join-Path $root $relativePath)
    $anchor = $processLanguageContracts[$relativePath]
    Assert-Condition ($text.Contains($anchor)) "$relativePath is missing the shared process-language reminder: $anchor"
}

$obsoleteAutoSplitPatterns = @(
    'Use split form for multiple independently readable',
    'Select split form directly when independently readable',
    '内容有多个可独立阅读的 feature',
    'confirmed content has multiple independently readable'
)
$plausibleAutoSplitMutation = 'For form selection, default to the small form within 500 lines and 30,000 characters. Automatically select split form whenever multiple modules are present.'
Assert-Condition (Test-SemanticAutoSplitTrigger $plausibleAutoSplitMutation) 'semantic auto-split detector accepts a differently worded multi-module mutation'
Assert-Condition (Test-SemanticAutoSplitTrigger 'Multiple subsystems default to split form.') 'semantic auto-split detector misses exact default-to-split-form mutation'
Assert-Condition (Test-SemanticAutoSplitTrigger 'Multiple subsystems default to split mode.') 'semantic auto-split detector misses exact default-to-split-mode mutation'
$completeContractAutoSplitMutation = 'For form selection, default to the small form within 500 lines and 30,000 characters. Use split form only when the small form exceeds either hard limit, the user explicitly approves split form, or an applicable target-project setting explicitly requires it. Multiple features do not trigger split form by themselves. Split whenever there are two features.'
Assert-Condition (Test-SemanticAutoSplitTrigger $completeContractAutoSplitMutation) 'semantic auto-split detector accepts a complete contract with an appended two-feature split rule'
Assert-Condition (Test-SemanticAutoSplitTrigger 'Multiple page areas mean the document should be split.') 'semantic auto-split detector accepts a should-be-split page-area mutation'
Assert-Condition (Test-SemanticAutoSplitTrigger 'More than one subsystem means the document should be split.') 'semantic auto-split detector accepts a more-than-one subsystem mutation'
Assert-Condition (Test-SemanticAutoSplitTrigger '多个模块时拆分。') 'semantic auto-split detector accepts a plain Chinese split mutation'
Assert-Condition (-not (Test-SemanticAutoSplitTrigger 'Multiple modules do not trigger split form by themselves.')) 'semantic auto-split detector rejects valid negative trigger wording'
Assert-Condition (-not (Test-SemanticAutoSplitTrigger 'Task groups define fragments only after split form has been selected.')) 'semantic auto-split detector rejects valid post-selection fragment wording'
Assert-Condition (-not (Test-SemanticAutoSplitTrigger 'Multiple modules can use split form only when the user explicitly approves it.')) 'semantic auto-split detector rejects the explicit user-approval gate'
Assert-Condition (-not (Test-SemanticAutoSplitTrigger 'Multiple modules can use split form only when an applicable target-project setting explicitly requires it.')) 'semantic auto-split detector rejects the explicit target-project-setting gate'
Assert-Condition (-not (Test-SemanticAutoSplitTrigger 'Multiple modules can use split form only when the small form is expected to exceed 500 lines or 30,000 characters.')) 'semantic auto-split detector rejects the hard-limit overflow gate'
Assert-Condition (-not (Test-SemanticAutoSplitTrigger '多个功能、子系统、页面区域、任务组或 ownership domain 只用于拆分后的语义边界，不单独触发拆分。')) 'semantic auto-split detector rejects the complete Chinese post-split/non-trigger control'

foreach ($relativePath in $compactFirstFiles) {
    $text = Read-Utf8 (Join-Path $root $relativePath)
    foreach ($pattern in $obsoleteAutoSplitPatterns) {
        Assert-Condition (-not $text.Contains($pattern)) "$relativePath retains obsolete semantic auto-split wording: $pattern"
    }
    Assert-Condition (-not (Test-SemanticAutoSplitTrigger $text)) "$relativePath retains a semantic auto-split trigger"
}

$designArtifactContracts = @{
    'skills\fp-brainstorm\SKILL.md' = '${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md'
    'skills\fp-brainstorm\design-template.md' = 'artifact-layout contract already loaded by `fp-brainstorm`'
    'skills\fp-figma\SKILL.md' = '${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md'
    'skills\fp-ui-spec\SKILL.md' = '${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md'
    'skills\fp-ux-spec\SKILL.md' = '${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md'
    'commands\fp-brainstorm.md' = '${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md'
}

foreach ($entry in $designArtifactContracts.GetEnumerator()) {
    $designArtifactText = Read-Utf8 (Join-Path $root $entry.Key)
    Assert-Condition ($designArtifactText.Contains($entry.Value)) "$($entry.Key) is missing its artifact-layout contract anchor: $($entry.Value)"
    Assert-Condition ($designArtifactText.Contains('500') -and $designArtifactText.Contains('30,000')) "$($entry.Key) must select design form before writing and enforce both hard file limits"
}

$brainstormSkillText = Read-Utf8 (Join-Path $root 'skills\fp-brainstorm\SKILL.md')
$brainstormTemplate = Read-Utf8 (Join-Path $root 'skills\fp-brainstorm\design-template.md')
$figmaDesignSkill = Read-Utf8 (Join-Path $root 'skills\fp-figma\SKILL.md')
$uiSpecSkill = Read-Utf8 (Join-Path $root 'skills\fp-ui-spec\SKILL.md')
$uxSpecSkill = Read-Utf8 (Join-Path $root 'skills\fp-ux-spec\SKILL.md')
$brainstormCommand = Read-Utf8 (Join-Path $root 'commands\fp-brainstorm.md')

foreach ($anchor in @('design/backend.md', 'design/backend/00-index.md', 'design/frontend.md', 'design/frontend/00-index.md', 'mutually exclusive', 'canonical entry', 'Pre-write gate includes design index', 'explicit pre-write gate', 'exact target paths', 'Post-write handoff', 'Post-write verification rejects', 'incomplete manifests', 'duplicate visual ownership', 'Resume boundary', 'partial conversion', 'current slug', 'exact paths', 'historical', 'explicit approval', 'obsolete path')) {
    Assert-Condition ($brainstormSkillText.Contains($anchor)) "fp-brainstorm is missing its per-file design producer contract: $anchor"
}
foreach ($anchor in @('design/backend.md', 'design/backend/00-index.md', 'design/frontend.md', 'design/frontend/00-index.md', 'mutually exclusive', 'links directly', 'The chosen end entry directly owns', 'do not create the corresponding end `.md` file', 'exactly one detailed owner')) {
    Assert-Condition ($brainstormTemplate.Contains($anchor)) "design-template is missing its exclusive form or direct ownership contract: $anchor"
}
foreach ($anchor in @('metadata-only', '## Canonical End Entrypoints', '| End | Canonical entrypoint | Mode |', 'requirements, contracts, decisions, or design body sections')) {
    Assert-Condition ($brainstormTemplate.Contains($anchor)) "design-template is missing the metadata-only change index recipe: $anchor"
}
foreach ($anchor in @('design/frontend.md', 'design/frontend/00-index.md', 'design/frontend/<number>-<area>.md', 'design/00-index.md', 'mutually exclusive form', 'writes the chosen frontend file OR the frontend directory', 'both required indexes', 'detailed owner', 'historical')) {
    Assert-Condition ($figmaDesignSkill.Contains($anchor)) "fp-figma is missing its chosen-form write or bounded compatibility contract: $anchor"
}
foreach ($entry in @(
    @{ Name = 'fp-ui-spec'; Text = $uiSpecSkill; Owner = 'unique visual owner' }
    @{ Name = 'fp-ux-spec'; Text = $uxSpecSkill; Owner = 'unique visual/interaction owner' }
)) {
    foreach ($anchor in @('Resolve the chosen canonical frontend representation', 'design/frontend.md', 'design/frontend/00-index.md', 'design/00-index.md', 'Producer dual-form input is a structural conflict and must be rejected', 'exactly one detailed owner', $entry.Owner)) {
        Assert-Condition ($entry.Text.Contains($anchor)) "$($entry.Name) is missing its canonical frontend resolution or unique-owner contract: $anchor"
    }
}
$brainstormCommandContractAnchors = @(
    'mutually exclusive form'
    'backend.md'
    'backend/00-index.md'
    'frontend.md'
    'frontend/00-index.md'
    '默认预选 small form'
    '500 lines'
    '30,000 characters'
    '用户明确批准'
    '目标项目设置明确要求'
    '语义边界仅用于拆分后的分片'
    '过程文档叙述性内容默认使用中文'
    '保留必要英文'
)
foreach ($anchor in $brainstormCommandContractAnchors) {
    Assert-Condition ($brainstormCommand.Contains($anchor)) "fp-brainstorm command checksum is missing: $anchor"
}
$regressedBrainstormCommand = $brainstormCommand.Replace('用户明确批准', '')
Assert-Condition (-not (Test-ContainsEveryAnchor $regressedBrainstormCommand $brainstormCommandContractAnchors)) 'fp-brainstorm regression fixture without the explicit user split gate still satisfies the command contract'
Assert-Condition (-not (Test-SemanticAutoSplitTrigger $brainstormCommand)) 'fp-brainstorm command retains a semantic auto-split trigger'
Assert-Condition (-not (Test-ObsoleteSemanticFirstGuidance $brainstormCommand)) 'fp-brainstorm command retains obsolete semantic-first/语义优先 guidance'

Assert-Condition (Test-ForbiddenDesignDualRecipe 'Keep the stable entrypoint summary and write details to design/frontend/00-index.md.') 'dual-form recipe detector misses the former stable-summary split recipe'
Assert-Condition (Test-ForbiddenDesignDualRecipe 'design/frontend/00-index.md lists fragments; design/frontend.md links the end-local index.') 'dual-form recipe detector misses the former index-linking recipe'
Assert-Condition (Test-ForbiddenDesignDualRecipe 'Do not omit details; keep design/frontend.md as a summary linking design/frontend/00-index.md.') 'dual-form recipe detector lets a broad do-not clause hide a forbidden stable-summary recipe'
Assert-Condition (Test-ForbiddenDesignDualRecipe 'Small form exists; in split mode keep design/frontend.md as a summary linking design/frontend/00-index.md.') 'dual-form recipe detector lets a broad small-form clause hide a forbidden stable-summary recipe'
Assert-Condition (Test-ForbiddenDesignDualRecipe 'Do not link design/frontend/00-index.md. Keep design/frontend.md as a summary linking design/frontend/00-index.md.') 'dual-form recipe detector lets an earlier period-bounded negation hide a later affirmative recipe'
Assert-Condition (Test-ForbiddenDesignDualRecipe 'Do not link design/frontend/00-index.md; Keep design/frontend.md as a summary linking design/frontend/00-index.md.') 'dual-form recipe detector lets an earlier semicolon-bounded negation hide a later affirmative recipe'
Assert-Condition (Test-ForbiddenDesignDualRecipe ('Do not link design/frontend/00-index.md' + [char]0x3002 + 'Keep design/frontend.md as a summary linking design/frontend/00-index.md.')) 'dual-form recipe detector lets an earlier Chinese-period negation hide a later affirmative recipe'
Assert-Condition (Test-ForbiddenDesignDualRecipe "Keep design/frontend.md as a summary.`nIt links design/frontend/00-index.md.") 'dual-form recipe detector misses a multiline affirmative stable-summary link chain'
Assert-Condition (Test-ForbiddenDesignDualRecipe "Keep design/backend.md as a summary.`nIt points to design/backend/00-index.md.") 'dual-form recipe detector misses a multiline affirmative summary pointer chain'
Assert-Condition (Test-ForbiddenDesignDualRecipe "Keep design/backend.md as a summary.`nIt is a reference to design/backend/00-index.md.") 'dual-form recipe detector misses a multiline affirmative summary reference chain'
Assert-Condition (-not (Test-ForbiddenDesignDualRecipe 'Small form uses design/frontend.md only; split form uses design/frontend/00-index.md only; never both.')) 'dual-form recipe detector rejects valid mutually-exclusive wording'
Assert-Condition (-not (Test-ForbiddenDesignDualRecipe 'Split form writes design/frontend/00-index.md and design/00-index.md; do not create design/frontend.md.')) 'dual-form recipe detector rejects a valid split write preserving both indexes'
Assert-Condition (-not (Test-ForbiddenDesignDualRecipe 'In small form, design/00-index.md links design/frontend.md directly; it does not link design/frontend/00-index.md.')) 'dual-form recipe detector treats an explicitly negated split-index link as affirmative'
Assert-Condition (-not (Test-ForbiddenDesignDualRecipe 'Do not keep design/frontend.md as a summary linking design/frontend/00-index.md.')) 'dual-form recipe detector treats a do-not-keep clause as affirmative'
Assert-Condition (-not (Test-ForbiddenDesignDualRecipe 'Never keep design/frontend.md as a summary; it links design/frontend/00-index.md.')) 'dual-form recipe detector treats a never-keep clause as affirmative'
Assert-Condition (-not (Test-ForbiddenDesignDualRecipe 'Mutually exclusive direct entry: design/00-index.md links design/frontend.md directly; never link design/frontend/00-index.md.')) 'dual-form recipe detector rejects mutually-exclusive direct-entry wording'
foreach ($entry in $designArtifactContracts.GetEnumerator()) {
    $designArtifactText = Read-Utf8 (Join-Path $root $entry.Key)
    Assert-Condition (-not (Test-ForbiddenDesignDualRecipe $designArtifactText)) "$($entry.Key) retains a forbidden stable-summary-plus-split-directory recipe"
}

Assert-Condition (-not ($brainstormSkillText.Contains('stable entrypoint summary'))) 'fp-brainstorm must not retain an end .md summary beside its split directory'
Assert-Condition (-not ($brainstormTemplate.Contains('keep its stable entrypoint concise'))) 'design-template must not retain an end .md summary beside its split directory'
Assert-Condition (-not ($figmaDesignSkill.Contains('design/frontend.md links the end-local index'))) 'fp-figma must not retain design/frontend.md beside design/frontend/'

$embeddedPrdTemplateHeading = '"# <\u4EA7\u54C1/\u529F\u80FD\u540D\u79F0> PRD"' | ConvertFrom-Json
Assert-Condition (-not ((Read-Utf8 (Join-Path $root 'skills\fp-prd\SKILL.md')).Contains($embeddedPrdTemplateHeading))) 'fp-prd embeds its output template instead of lazy-loading it'

$lazyResources = @{
    'skills\fp-prd\SKILL.md' = 'prd-template.md'
    'skills\fp-propose\SKILL.md' = 'proposal-template.md'
    'skills\fp-brainstorm\SKILL.md' = 'design-template.md'
    'skills\fp-plan\SKILL.md' = 'task-layout-template.md'
    'skills\fp-plan-backend\SKILL.md' = 'plan-template.md'
    'skills\fp-plan-frontend\SKILL.md' = 'plan-template.md'
    'skills\fp-review\SKILL.md' = 'final-review-template.md'
    'skills\fp-init\SKILL.md' = 'project-family-examples.md'
}

foreach ($entry in $lazyResources.GetEnumerator()) {
    $skillPath = Join-Path $root $entry.Key
    $resourcePath = Join-Path (Split-Path -Parent $skillPath) $entry.Value
    Assert-Condition (Test-Path $resourcePath) "$($entry.Key) references missing resource $($entry.Value)"
    Assert-Condition ((Read-Utf8 $skillPath).Contains($entry.Value)) "$($entry.Key) does not route to $($entry.Value)"
}

$resourceAnchors = @{
    'skills\_shared\codegraph.md' = @('npm install -g @colbymchenry/codegraph@latest', 'npm prefix -g', 'MCP -> CLI -> native search', 'navigation-hint-only', 'dirty-after-write', 'post-write sync')
    'skills\fp-init\templates.md' = @('Refreshed: <timestamp or never>', 'Generated body hash:', 'Refresh decision: keep | regenerate | conflict', '## Selective refresh')
    'skills\fp-prd\prd-template.md' = @('### 1.1 ', '### 3.1 ', '#### 3.1.1 ', '#### 3.1.5 ', '### 4.1 ', '### 4.3 ', 'flowchart TD')
    'skills\fp-propose\proposal-template.md' = @('## Why', '## What Changes', '## Capabilities', '## Out of Scope', '## Impact')
    'skills\fp-brainstorm\design-template.md' = @('# <', '## ', '### API ', '#### API ')
    'skills\fp-plan\task-layout-template.md' = @('## Change-level overview', 'tasks/00-overview.md', '## Cross-end Dependency Edges', '## Progress Totals', 'derived from the unique owner checkboxes', '## Per-end split manifest', '## Fragment Manifest', '| Order | File | Kind | Owns |')
    'skills\fp-plan-backend\plan-template.md' = @('## Global Constraints', '## Backend Interface Ledger', '- [ ] **Task backend-NNN:', '**Depends on:**', '## Coverage Matrix')
    'skills\fp-plan-frontend\plan-template.md' = @('## Global Constraints', '- [ ] **Task frontend-NNN:', '**Depends on:**', '**Template Outline:**', '**Script/State Outline:**', '**Style Outline:**', '**Visual / UX Checks:**')
    'skills\fp-review\final-review-template.md' = @('**Verdict:**', '## Inputs Reviewed', '## Branch State', '## FeaturePilot Coverage', '## Verification Commands', '## Findings', '## Blocking Items Before Archive', '## Final Verdict Rationale')
}

foreach ($entry in $resourceAnchors.GetEnumerator()) {
    $resourceText = Read-Utf8 (Join-Path $root $entry.Key)
    foreach ($anchor in $entry.Value) {
        Assert-Condition ($resourceText.Contains($anchor)) "$($entry.Key) lost output-contract anchor: $anchor"
    }
}

$backendPlanTemplate = Read-Utf8 (Join-Path $root 'skills\fp-plan-backend\plan-template.md')
$frontendPlanTemplate = Read-Utf8 (Join-Path $root 'skills\fp-plan-frontend\plan-template.md')
Assert-Condition (-not ($backendPlanTemplate -match '(?m)^\s*- \[ \] \*\*Step ')) 'backend plan substeps must not create competing checkboxes'
Assert-Condition (-not ($frontendPlanTemplate -match '(?m)^\s*- \[ \] (?!\*\*Task frontend-)')) 'frontend plan details must not create competing checkboxes'
Assert-Condition (-not ($backendPlanTemplate.Contains('### - [ ]')) -and -not ($frontendPlanTemplate.Contains('### - [ ]'))) 'task checkbox markers must be real Markdown task-list items, not heading text'
Assert-Condition ([regex]::Matches($backendPlanTemplate, '(?m)^- \[ \] \*\*Task backend-NNN:').Count -eq 1) 'backend task template must have exactly one executable checkbox marker'
Assert-Condition ([regex]::Matches($frontendPlanTemplate, '(?m)^- \[ \] \*\*Task frontend-NNN:').Count -eq 1) 'frontend task template must have exactly one executable checkbox marker'
$taskLayoutTemplate = Read-Utf8 (Join-Path $root 'skills\fp-plan\task-layout-template.md')
foreach ($example in [regex]::Matches($taskLayoutTemplate, '(?s)```markdown\r?\n(?<body>.*?)\r?\n```')) {
    Assert-Condition (-not ($example.Groups['body'].Value -match '(?m)^- \[[ xX]\] \*\*Task ')) 'task overview/index examples must not own executable checkboxes'
}

$skillAnchors = @{
    'fp-init' = @('templates.md', 'project-family-examples.md', 'Lightweight discovery boundaries', 'Never overwrite', 'auto-install', 'show-install-steps', 'skip-codegraph', 'npm install -g @colbymchenry/codegraph@latest', 'codegraph install --target=auto --location=global --yes', 'codegraph init <project-root>', 'refresh-existing-information-layer', 'stale-generated-intel', 'refresh-stale-intel', 'preserve-manual-settings', 'user-edit-conflict')
    'fp-prd' = @('Bucket A/B', 'Bucket C', 'Prototype-first', 'explicitly approved', 'prd-template.md')
    'fp-prd-grill-me' = @('one question per turn', 'MUST NOT decide Bucket C', 'Minimal Fact Exploration')
    'fp-propose' = @('proposal-template.md', 'Why / What Changes / Out of Scope / Impact', 'fp-docs/changes/<slug>/proposal.md')
    'fp-brainstorm' = @('2-3', 'design-template.md', 'Visual Checks', 'design/00-index.md', 'design/backend.md', 'design/frontend.md')
    'fp-plan' = @('fp-plan-backend', 'fp-plan-frontend', 'plan-backend.md', 'plan-frontend.md')
    'fp-plan-backend' = @('Global Constraints', 'Backend Interface Ledger', 'Coverage Matrix', 'plan-template.md')
    'fp-plan-frontend' = @('Global Constraints', 'Interfaces', 'Visual Checks', 'plan-template.md')
    'fp-execute' = @('semi', 'full', 'Pre-flight Plan Review', 'TDD', 'dirty-after-write', 'post-write-sync', 'must not block completion')
    'fp-start' = @('fp-propose', 'fp-brainstorm', 'fp-plan', 'fp-execute-sdd', 'fp-review')
    'fp-execute-sdd' = @('No parallel implementers', 'progress.md', 'task-brief-template.md', 'task-reviewer-prompt.md', 'Fix Loop', 'dirty-after-write', 'post-write-sync', 'must not block completion')
    'fp-review' = @('read-only final reviewer', 'PASS_WITH_NOTES', 'stale intel', 'final-review-template.md')
    'fp-explore' = @('mode: standalone', 'prd-facts', 'start-routing', 'quick', 'fp-explore-invoke', 'fp-explore-return', 'read-only', 'Stage 0 - CodeGraph fast path', 'MCP -> CLI -> native search', 'candidate paths', 'local read windows', 'current source')
    'fp-quick' = @('fp-explore', 'quick-candidate-files', 'quick-reusable-patterns', 'quick-verification', 'quick-scope-assessment', 'fp-docs/changes/', 'dirty-after-write', 'post-write-sync', 'must not block completion')
    'fp-archive' = @('history/history.md', 'blocked', 'proposal.md')
    'fp-figma' = @('Figma', 'Flex / Grid', 'Visual Checks', 'settings/frontend.md')
    'fp-ui-spec' = @('settings/frontend.md', 'existing code', 'Public-plugin constraints')
    'fp-ux-spec' = @('settings/frontend.md', 'existing code', 'Public-plugin constraints')
    'fp-grill-me' = @('recommendation is not', 'codebase', 'explicit user confirmation')
}

foreach ($entry in $skillAnchors.GetEnumerator()) {
    $skillText = Read-Utf8 (Join-Path $root "skills\$($entry.Key)\SKILL.md")
    foreach ($anchor in $entry.Value) {
        Assert-Condition ($skillText.Contains($anchor)) "$($entry.Key) lost capability anchor: $anchor"
    }
}

$quickSkillText = Read-Utf8 (Join-Path $root 'skills\fp-quick\SKILL.md')
Assert-Condition (-not $quickSkillText.Contains('用 fp-propose 探索项目背景')) 'fp-quick still uses fp-propose as exploration authority'
Assert-Condition (-not $quickSkillText.Contains('每次最多问 1-3 个关键问题')) 'fp-quick still batches separate clarification questions'

$prdExploreText = Read-Utf8 (Join-Path $root 'skills\fp-prd\SKILL.md')
Assert-Condition ($prdExploreText.Contains('fp-prd-grill-me') -and $prdExploreText.Contains('must never self-answer Bucket C')) 'prd-facts weakened the PRD interview gate'

$startExploreText = Read-Utf8 (Join-Path $root 'skills\fp-start\SKILL.md')
Assert-Condition ($startExploreText.Contains('profile: start-routing') -and $startExploreText.Contains('explicit user choice')) 'start-routing lacks caller-owned routing choice'
Assert-Condition ($startExploreText.Contains('Default execution path') -and $startExploreText.Contains('SDD continuation mode gate')) 'start-routing edit removed protected execution routing'

$sddSkill = Read-Utf8 (Join-Path $root 'skills\fp-execute-sdd\SKILL.md')
Assert-Condition ($sddSkill.Contains('intel/sdd-handoff.md')) 'fp-execute-sdd is missing the SDD handoff preflight contract'
Assert-Condition ($sddSkill.Contains('unresolved Unknown')) 'fp-execute-sdd is missing unresolved Unknown handling'

$reviewSkill = Read-Utf8 (Join-Path $root 'skills\fp-review\SKILL.md')
Assert-Condition ($reviewSkill.Contains('stale intel')) 'fp-review is missing stale-intel review guidance'
Assert-Condition ($reviewSkill.Contains('information-layer process')) 'fp-review is missing information-layer process review guidance'

$brainstormSkill = Read-Utf8 (Join-Path $root 'skills\fp-brainstorm\SKILL.md')
$startSkill = Read-Utf8 (Join-Path $root 'skills\fp-start\SKILL.md')
Assert-Condition ($brainstormSkill.Contains('fp-start') -and $brainstormSkill.Contains('`fp-plan`')) 'fp-brainstorm must return written design artifacts to fp-start instead of entering planning'
Assert-Condition ($brainstormSkill.Contains('design-template.md') -and $brainstormSkill.Contains('design/00-index.md')) 'fp-brainstorm is missing the pre-write content confirmation boundary'
Assert-Condition ($brainstormSkill.Contains('Agent') -and $brainstormSkill.Contains('Workflow')) 'fp-brainstorm is missing the single-owner finalization boundary'
Assert-Condition ($brainstormSkill.Contains('fp-start') -and $brainstormSkill.Contains('design/00-index.md')) 'fp-brainstorm is missing its post-write handoff to fp-start'
Assert-Condition ($startSkill.Contains('design/00-index.md') -and $startSkill.Contains('fp-plan')) 'fp-start is missing the post-write artifact confirmation boundary'
Assert-Condition ($startSkill.Contains('Agent') -and $startSkill.Contains('Workflow')) 'fp-start is missing the no-second-finalizer boundary'
Assert-Condition ($startSkill.Contains('Resume boundary')) 'fp-start is missing bounded resume behavior'
Assert-Condition ($startSkill.Contains('Task/Todo')) 'fp-start is missing non-authoritative bookkeeping failure handling'

Assert-Condition ($brainstormSkill.Contains('fp-docs/changes/<slug>/design/00-index.md')) 'fp-brainstorm must create the canonical design directory index'
Assert-Condition ($brainstormSkill.Contains('design/backend.md') -and $brainstormSkill.Contains('design/frontend.md') -and $brainstormSkill.Contains('design/backend/00-index.md') -and $brainstormSkill.Contains('design/frontend/00-index.md')) 'fp-brainstorm must expose both exclusive form choices for each design end'
Assert-Condition ($brainstormSkill.Contains('mutually exclusive') -and $brainstormSkill.Contains('500 lines') -and $brainstormSkill.Contains('30,000 characters')) 'fp-brainstorm is missing exclusive form selection or hard design limits'
Assert-Condition ($brainstormSkill.Contains('canonical entry') -and $brainstormSkill.Contains('design/00-index.md')) 'fp-brainstorm change index must point directly to each selected end entry'
Assert-Condition (-not ($brainstormSkill.Contains('fp-docs/changes/<slug>/design-backend.md'))) 'fp-brainstorm must not produce legacy root-level backend design files'
Assert-Condition (-not ($brainstormSkill.Contains('fp-docs/changes/<slug>/design-frontend.md'))) 'fp-brainstorm must not produce legacy root-level frontend design files'
Assert-Condition ($brainstormSkill.Contains('design-template.md') -and $brainstormSkill.Contains('design/00-index.md')) 'fp-brainstorm must gate the design index behind pre-write approval'
Assert-Condition ($brainstormSkill.Contains('detailed owner') -and $brainstormSkill.Contains('ownership metadata')) 'fp-brainstorm must assign unique ownership for frontend visual contracts'

$planSkill = Read-Utf8 (Join-Path $root 'skills\fp-plan\SKILL.md')
Assert-Condition ($planSkill.Contains('design/00-index.md') -and $planSkill.Contains('historical')) 'fp-plan must reject historical design paths through canonical resolution'

$figmaSkill = Read-Utf8 (Join-Path $root 'skills\fp-figma\SKILL.md')
Assert-Condition ($figmaSkill.Contains('design/00-index.md') -and $figmaSkill.Contains('design/frontend.md')) 'fp-figma is missing the canonical design path contract'
Assert-Condition ($figmaSkill.Contains('design/frontend/00-index.md') -and $figmaSkill.Contains('design/frontend/<number>-<area>.md')) 'fp-figma must not create unreachable frontend design fragments'
Assert-Condition ($figmaSkill.Contains('mutually exclusive form') -and $figmaSkill.Contains('design/frontend.md')) 'fp-figma must preserve exactly one canonical frontend form when writing fragments'
Assert-Condition ($figmaSkill.Contains('detailed owner') -and $figmaSkill.Contains('ownership metadata')) 'fp-figma must keep Visual Source, mapping, and Visual Checks under unique ownership'

$backendPlanSkill = Read-Utf8 (Join-Path $root 'skills\fp-plan-backend\SKILL.md')
$frontendPlanSkill = Read-Utf8 (Join-Path $root 'skills\fp-plan-frontend\SKILL.md')
Assert-Condition ($backendPlanSkill.Contains('design/backend/00-index.md') -and $backendPlanSkill.Contains('canonical-first')) 'fp-plan-backend must resolve an existing canonical fragment index independently of entrypoint links'
Assert-Condition ($frontendPlanSkill.Contains('design/frontend/00-index.md') -and $frontendPlanSkill.Contains('canonical-first')) 'fp-plan-frontend must resolve an existing canonical fragment index independently of entrypoint links'

Assert-Condition (Test-ForbiddenPlanDualRecipe 'Keep tasks/plan-backend.md as a summary linking tasks/backend/00-index.md.') 'plan dual-recipe detector misses the former stable-summary/index recipe'
Assert-Condition (Test-ForbiddenPlanDualRecipe 'Retain tasks/plan-frontend.md for navigation; store executable tasks under tasks/frontend/10-ui-tasks.md.') 'plan dual-recipe detector misses retain/navigation/store synonyms'
Assert-Condition (Test-ForbiddenPlanDualRecipe "Preserve tasks/plan-backend.md for constraints and navigation.`nDetailed task groups live under tasks/backend/20-api-tasks.md.") 'plan dual-recipe detector misses a multiline constraints/details recipe'
Assert-Condition (Test-ForbiddenPlanDualRecipe 'Store detailed tasks under tasks/frontend/10-ui-tasks.md while tasks/plan-frontend.md remains the navigation summary.') 'plan dual-recipe detector misses a directory-first stable-navigation recipe'
Assert-Condition (Test-ForbiddenPlanDualRecipe 'Do not link tasks/backend/00-index.md. Keep tasks/plan-backend.md as a summary linking tasks/backend/00-index.md.') 'plan dual-recipe detector lets an earlier negated sentence hide a later affirmative recipe'
Assert-Condition (Test-ForbiddenPlanDualRecipe 'Do not link tasks/frontend/00-index.md; Retain tasks/plan-frontend.md for navigation and store tasks under tasks/frontend/10-ui-tasks.md.') 'plan dual-recipe detector lets an earlier negated clause hide a later affirmative recipe'
Assert-Condition (Test-ForbiddenPlanDualRecipe 'Do not omit details; keep tasks/plan-backend.md as a summary linking tasks/backend/00-index.md.') 'plan dual-recipe detector lets an unrelated negative prefix hide an affirmative recipe'
Assert-Condition (Test-ForbiddenPlanDualRecipe 'Small form exists; in split mode keep tasks/plan-frontend.md as navigation and store details under tasks/frontend/.') 'plan dual-recipe detector lets a broad small-form prefix hide an affirmative recipe'
Assert-Condition (-not (Test-ForbiddenPlanDualRecipe 'In small form, keep tasks/plan-backend.md as the complete header and coverage owner only. In split form, store executable tasks under tasks/backend/10-domain-tasks.md; never both.')) 'plan dual-recipe detector correlates valid mutually exclusive small/split segments by proximity'
Assert-Condition (Test-ForbiddenPlanDualRecipe 'In split form, tasks/plan-backend.md remains the canonical entrypoint while tasks/backend/10-domain-tasks.md contains executable task bodies.') 'plan dual-recipe detector misses a stable plan role retained inside split form'
Assert-Condition (-not (Test-ForbiddenPlanDualRecipe 'Backend small form uses tasks/plan-backend.md only; split form uses tasks/backend/00-index.md only; never both.')) 'plan dual-recipe detector rejects explicit mutual exclusion'
Assert-Condition (-not (Test-ForbiddenPlanDualRecipe 'Do not keep tasks/plan-backend.md as a summary linking tasks/backend/00-index.md.')) 'plan dual-recipe detector treats an explicitly negated recipe as affirmative'
Assert-Condition (-not (Test-ForbiddenPlanDualRecipe 'Never retain tasks/plan-frontend.md for navigation while storing details under tasks/frontend/.')) 'plan dual-recipe detector treats a never-retain clause as affirmative'

$planArtifactContracts = @(
    'skills\fp-plan\SKILL.md'
    'skills\fp-plan\task-layout-template.md'
    'skills\fp-plan-backend\SKILL.md'
    'skills\fp-plan-backend\plan-template.md'
    'skills\fp-plan-frontend\SKILL.md'
    'skills\fp-plan-frontend\plan-template.md'
)
foreach ($planArtifactContract in $planArtifactContracts) {
    $planArtifactText = Read-Utf8 (Join-Path $root $planArtifactContract)
    Assert-Condition (-not (Test-ForbiddenPlanDualRecipe $planArtifactText)) "$planArtifactContract retains a forbidden stable-plan-plus-split-directory recipe"
}
foreach ($mutation in @(
    'Keep tasks/plan-backend.md as a constraints summary and move executable tasks to tasks/backend/10-domain-tasks.md.'
    "Preserve tasks/plan-frontend.md for navigation.`nDetailed task groups live under tasks/frontend/20-ui-tasks.md."
)) {
    Assert-Condition (Test-ForbiddenPlanDualRecipe $mutation) 'plan dual-recipe mutation audit failed to detect an injected recipe'
}
Assert-Condition ($planSkill.Contains('Backend: small `tasks/plan-backend.md` **or** split `tasks/backend/00-index.md` plus its indexed fragments.')) 'fp-plan is missing the exact exclusive backend plan pair'
Assert-Condition ($planSkill.Contains('Frontend: small `tasks/plan-frontend.md` **or** split `tasks/frontend/00-index.md` plus its indexed fragments.')) 'fp-plan is missing the exact exclusive frontend plan pair'
Assert-Condition ($backendPlanSkill.Contains('Small form: fp-docs/changes/<slug>/tasks/plan-backend.md') -and $backendPlanSkill.Contains('Split form: fp-docs/changes/<slug>/tasks/backend/00-index.md plus indexed fragments') -and $backendPlanSkill.Contains('must not create or retain `plan-backend.md`')) 'fp-plan-backend is missing its exact exclusive small/split outputs'
Assert-Condition ($frontendPlanSkill.Contains('Small form: fp-docs/changes/<slug>/tasks/plan-frontend.md') -and $frontendPlanSkill.Contains('Split form: fp-docs/changes/<slug>/tasks/frontend/00-index.md plus indexed fragments') -and $frontendPlanSkill.Contains('must not create or retain `plan-frontend.md`')) 'fp-plan-frontend is missing its exact exclusive small/split outputs'

foreach ($planner in @(
    @{ Name = 'fp-plan'; Text = $planSkill }
    @{ Name = 'fp-plan-backend'; Text = $backendPlanSkill }
    @{ Name = 'fp-plan-frontend'; Text = $frontendPlanSkill }
)) {
    foreach ($anchor in @('Resolve the proposal representation before reading either form', 'proposal.md', 'proposal/00-index.md', 'complete manifest order', 'structural conflict')) {
        Assert-Condition ($planner.Text.Contains($anchor)) "$($planner.Name) is missing canonical proposal resolution: $anchor"
    }
    Assert-Condition ($planner.Text -notmatch '(?i)stable entrypoint.{0,160}(?:linked fragments|index fragments)|linked fragments.{0,160}stable entrypoint') "$($planner.Name) still relies on stable-entrypoint linked-fragment hints"
}
Assert-Condition ($planSkill.Contains('Pass the resolved logical proposal content, resolved logical design content, canonical entrypoint, mode, and ordered fragment paths to each child planner.')) 'fp-plan is missing the resolved logical-content child handoff'
foreach ($child in @(
    @{ Name = 'fp-plan-backend'; Text = $backendPlanSkill; End = 'backend' }
    @{ Name = 'fp-plan-frontend'; Text = $frontendPlanSkill; End = 'frontend' }
)) {
    Assert-Condition ($child.Text.Contains("Resolve the $($child.End) design representation before reading either form")) "$($child.Name) is missing end design XOR resolution"
    Assert-Condition ($child.Text.Contains("design/$($child.End).md") -and $child.Text.Contains("design/$($child.End)/00-index.md")) "$($child.Name) is missing both canonical design alternatives"
}

$planLayoutContracts = @{
    'skills\fp-plan\SKILL.md' = @('tasks/plan-backend.md', 'tasks/backend/00-index.md', 'tasks/plan-frontend.md', 'tasks/frontend/00-index.md', 'mutually exclusive', '500 lines', '30,000 characters')
    'skills\fp-plan\task-layout-template.md' = @('| Order | File | Kind | Owns |', 'context', 'interface', 'tasks', 'coverage', 'two-end plan', 'single-end plan')
    'skills\fp-plan-backend\SKILL.md' = @('tasks/plan-backend.md', 'tasks/backend/00-index.md', 'mutually exclusive', '500 lines', '30,000 characters', 'context', 'interface', 'tasks', 'coverage')
    'skills\fp-plan-backend\plan-template.md' = @('Small form', 'Split form', 'context', 'interface', 'tasks', 'coverage')
    'skills\fp-plan-frontend\SKILL.md' = @('tasks/plan-frontend.md', 'tasks/frontend/00-index.md', 'mutually exclusive', '500 lines', '30,000 characters', 'context', 'interface', 'tasks', 'coverage')
    'skills\fp-plan-frontend\plan-template.md' = @('Small form', 'Split form', 'context', 'interface', 'tasks', 'coverage')
}
foreach ($entry in $planLayoutContracts.GetEnumerator()) {
    $planContractText = Read-Utf8 (Join-Path $root $entry.Key)
    foreach ($anchor in $entry.Value) {
        Assert-Condition ($planContractText.Contains($anchor)) "$($entry.Key) is missing the exclusive plan layout contract: $anchor"
    }
}

Assert-Condition ($planSkill.Contains('exists exactly when both backend and frontend plans exist')) 'fp-plan must make the overview a two-end-only artifact'
Assert-Condition ($planSkill.Contains('A single-end plan never has an overview')) 'fp-plan must forbid overviews for all single-end plans'
Assert-Condition ($taskLayoutTemplate.Contains('canonical entrypoints') -and $taskLayoutTemplate.Contains('cross-end dependency edges or execution stages') -and $taskLayoutTemplate.Contains('progress totals derived from the unique owner checkboxes')) 'task overview must own only end entries, cross-end coordination, and derived totals'
Assert-Condition ($taskLayoutTemplate.Contains('edge section is required and must match that graph exactly') -and $taskLayoutTemplate.Contains('stage section adds textual coordination and never substitutes')) 'task overview template must require exact owner-graph edges and forbid stage substitution'
Assert-Condition (-not ($taskLayoutTemplate.Contains('Cover every task ID exactly once'))) 'task overview must not duplicate the end-local task graph'
Assert-Condition ($taskLayoutTemplate.Contains('Only `tasks`-kind fragments may contain executable task checkboxes')) 'split task ownership must be restricted to tasks-kind fragments'
Assert-Condition ($taskLayoutTemplate.Contains('split-directory-relative fragment basenames') -and -not ($taskLayoutTemplate.Contains('Use repository-relative fragment names'))) 'task split manifest File entries must be split-directory-relative basenames'
Assert-Condition ($taskLayoutTemplate.Contains('exactly one `context`, exactly one `interface`, exactly one `coverage`, and one or more `tasks` rows')) 'task split manifest is missing exact kind cardinality'
foreach ($manifestRow in @(
    '| 1 | `01-context.md` | context | plan header, goal, architecture, stack, global constraints, file structure |'
    '| 2 | `05-interfaces.md` | interface | end-local interface ledger and contract checks |'
    '| 3 | `10-<topic>-tasks.md` | tasks |'
    '| 5 | `90-coverage.md` | coverage | proposal/design/boundary coverage and verification mapping |'
)) {
    Assert-Condition ($taskLayoutTemplate.Contains($manifestRow)) "task split manifest is missing exact kind/owner row: $manifestRow"
}
foreach ($producerContract in @(
    @{ Name = 'fp-plan-backend'; Text = $backendPlanSkill; Context = 'The `context` fragment uniquely owns'; Interface = 'The `interface` fragment uniquely owns the Backend Interface Ledger.'; Coverage = 'The `coverage` fragment uniquely owns the Coverage Matrix.' }
    @{ Name = 'fp-plan-frontend'; Text = $frontendPlanSkill; Context = 'The `context` fragment uniquely owns'; Interface = 'The `interface` fragment uniquely owns component, state, API, route, interaction, style, responsive, and Visual / UX contracts.'; Coverage = 'The `coverage` fragment uniquely owns proposal/design/visual coverage and verification mapping.' }
)) {
    Assert-Condition ($producerContract.Text.Contains($producerContract.Context) -and $producerContract.Text.Contains($producerContract.Interface) -and $producerContract.Text.Contains($producerContract.Coverage)) "$($producerContract.Name) is missing unique context/interface/coverage ownership"
    Assert-Condition ($producerContract.Text.Contains('Each executable task checkbox exists exactly once') -and $producerContract.Text.Contains('one `tasks`-kind fragment')) "$($producerContract.Name) is missing unique task checkbox ownership"
}

foreach ($consumer in @('fp-start', 'fp-plan', 'fp-execute', 'fp-execute-sdd', 'fp-review')) {
    $consumerText = Read-Utf8 (Join-Path $root "skills\$consumer\SKILL.md")
    Assert-Condition ($consumerText.Contains('design/')) "$consumer is missing canonical design paths"
    Assert-Condition ($consumerText.IndexOf('historical', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "$consumer is missing historical-layout rejection"
}

$executeSkill = Read-Utf8 (Join-Path $root 'skills\fp-execute\SKILL.md')
$archiveSkill = Read-Utf8 (Join-Path $root 'skills\fp-archive\SKILL.md')
$executeDirectSection = [regex]::Match($executeSkill, '(?s)## 直接执行契约\s*(?<body>.*?)\s*## 执行模式')
Assert-Condition ($executeDirectSection.Success) 'fp-execute direct execution contract is missing'
foreach ($anchor in @(
    '当前执行上下文直接完成'
    '过程产物集合仅包含'
    '一次 inline 自审'
    '不拥有 final review scope'
    '只提示运行独立的 `fp-review`'
)) {
    Assert-Condition ($executeDirectSection.Groups['body'].Value.Contains($anchor)) "fp-execute direct execution contract is incomplete: $anchor"
}
foreach ($forbidden in @(
    '## Review 次数与上限'
    '## Final Review Scope'
    'review attempt'
    'review debt'
    'clean-snapshot checkpoint'
    'task-reviewer-prompt.md'
    'review-package-template.md'
)) {
    Assert-Condition (-not $executeSkill.Contains($forbidden)) "fp-execute still contains SDD-style review orchestration: $forbidden"
}
$executeLines = @($executeSkill -split "`r?`n").Count
Assert-Condition ($executeLines -le 150) "fp-execute should stay lightweight (found $executeLines lines, maximum 150)"
$planSkill = Read-Utf8 (Join-Path $root 'skills\fp-plan\SKILL.md')
Assert-Condition ($planSkill.Contains('推荐使用 `fp-execute`') -and $planSkill.Contains('只有用户明确要求 `fp-execute-sdd`')) 'fp-plan must recommend direct execution and keep SDD opt-in'
$backendPlanTemplate = Read-Utf8 (Join-Path $root 'skills\fp-plan-backend\plan-template.md')
$frontendPlanTemplate = Read-Utf8 (Join-Path $root 'skills\fp-plan-frontend\plan-template.md')
foreach ($planTemplate in @(
    @{ Name = 'backend'; Text = $backendPlanTemplate }
    @{ Name = 'frontend'; Text = $frontendPlanTemplate }
)) {
    Assert-Condition ($planTemplate.Text.Contains('Use `fp-execute` to implement this plan task-by-task')) "fp-plan-$($planTemplate.Name) template must hand off to fp-execute"
}
Assert-Condition ($backendPlanSkill.Contains('tasks/backend/00-index.md') -and $backendPlanSkill.Contains('exceeds 500 lines')) 'fp-plan-backend is missing indexed large-plan splitting'
Assert-Condition ($frontendPlanSkill.Contains('tasks/frontend/00-index.md') -and $frontendPlanSkill.Contains('exceeds 500 lines')) 'fp-plan-frontend is missing indexed large-plan splitting'
Assert-Condition ($backendPlanSkill.Contains('exactly once') -and $frontendPlanSkill.Contains('exactly once')) 'task plan producers must own each executable task checkbox exactly once'
Assert-Condition ($backendPlanSkill.Contains('backend-001') -and $frontendPlanSkill.Contains('frontend-001') -and $backendPlanSkill.Contains('never resets per file') -and $frontendPlanSkill.Contains('never resets per file')) 'split task IDs must remain stable and unique across fragments'
Assert-Condition ($planSkill.Contains('tasks/00-overview.md') -and $planSkill.Contains('task-layout-template.md') -and $planSkill.Contains('exists exactly when both backend and frontend plans exist') -and $planSkill.Contains('A single-end plan never has an overview')) 'fp-plan is missing the exact two-end-only task overview condition'
foreach ($taskConsumer in @('fp-execute', 'fp-execute-sdd', 'fp-review', 'fp-archive')) {
    $taskConsumerText = Read-Utf8 (Join-Path $root "skills\$taskConsumer\SKILL.md")
    Assert-Condition ($taskConsumerText.Contains('tasks/backend/00-index.md') -and $taskConsumerText.Contains('tasks/frontend/00-index.md')) "$taskConsumer must resolve all indexed task fragments"
    Assert-Condition ($taskConsumerText.Contains('tasks/00-overview.md')) "$taskConsumer is missing cross-end task overview handling"
    Assert-Condition ($taskConsumerText.Contains('unindexed fragment')) "$taskConsumer must reject fragments outside the authoritative index"
}
Assert-Condition ($executeSkill.Contains('not a second completion authority') -and $sddSkill.Contains('not a second completion authority')) 'execution ledgers must remain recovery evidence rather than competing task state'
Assert-Condition ($executeSkill.Contains('derived progress summary') -and $sddSkill.Contains('derived overview progress counts')) 'executors must recompute overview progress from owner checkboxes'
Assert-Condition ($archiveSkill.Contains('task-owner files') -and $reviewSkill.Contains('task-owner files')) 'review and archive must inspect only resolved checkbox owner files for completion'

Assert-Condition (Test-UnconditionalStablePlanFirstRead 'Read stable entrypoints tasks/plan-backend.md, then inspect tasks/backend/00-index.md.') 'stable-plan-first detector misses an unconditional read'
Assert-Condition (-not (Test-UnconditionalStablePlanFirstRead 'Only when tasks/backend/00-index.md is absent, read tasks/plan-backend.md as the small form.')) 'stable-plan-first detector rejects a canonical-first conditional read'

$artifactConsumerContracts = @{
    'skills\fp-start\SKILL.md' = '${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md'
    'skills\fp-execute\SKILL.md' = '${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md'
    'skills\fp-execute-sdd\SKILL.md' = '${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md'
    'skills\fp-review\SKILL.md' = '${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md'
    'skills\fp-archive\SKILL.md' = '${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md'
}
foreach ($entry in $artifactConsumerContracts.GetEnumerator()) {
    $consumerText = Read-Utf8 (Join-Path $root $entry.Key)
    Assert-Condition ($consumerText.Contains($entry.Value)) "$($entry.Key) is missing its anchored artifact-layout contract: $($entry.Value)"
    foreach ($anchor in @(
        'canonical-first'
        'prd.md'
        'prd/00-index.md'
        'proposal.md'
        'proposal/00-index.md'
        'design/backend.md'
        'design/backend/00-index.md'
        'design/frontend.md'
        'design/frontend/00-index.md'
        'tasks/plan-backend.md'
        'tasks/backend/00-index.md'
        'tasks/plan-frontend.md'
        'tasks/frontend/00-index.md'
        'manifest order'
        'Producer'
        'Consumer'
        'unindexed fragment'
        'tasks`-kind'
        'unique task owner'
        'exactly when both backend and frontend plans exist'
        'A single-end plan never has an overview'
        'historical'
        'structural conflict'
    )) {
        Assert-Condition ($consumerText.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "$($entry.Key) is missing canonical Consumer contract: $anchor"
    }
    Assert-Condition ($consumerText -notmatch '(?i)recognized legacy|compatibility warning|bounded fallback|legacy pair read-only') "$($entry.Key) still permits historical compatibility"
    Assert-Condition (-not (Test-UnconditionalStablePlanFirstRead $consumerText)) "$($entry.Key) reads a stable task plan before resolving the split directory"
    Assert-Condition (-not (Test-ForbiddenPlanDualRecipe $consumerText)) "$($entry.Key) contains a Producer-like stable-plan-plus-split rewrite recipe"
    Assert-Condition (-not (Test-ForbiddenDesignDualRecipe $consumerText)) "$($entry.Key) contains a Producer-like stable-design-plus-split rewrite recipe"
}

$artifactHandoffContracts = @{
    'skills\fp-execute-sdd\task-brief-template.md' = 'artifact-layout contract already loaded by the owning `fp-execute-sdd` controller'
    'skills\fp-execute-sdd\review-package-template.md' = 'artifact-layout contract already loaded by the owning `fp-execute-sdd` controller'
    'skills\fp-review\final-reviewer.md' = 'artifact-layout contract already loaded by `fp-review`'
    'skills\fp-review\final-review-template.md' = 'artifact-layout contract already loaded by `fp-review`'
}
foreach ($entry in $artifactHandoffContracts.GetEnumerator()) {
    $handoffPath = $entry.Key
    $handoffText = Read-Utf8 (Join-Path $root $handoffPath)
    foreach ($anchor in @($entry.Value, 'canonical-first', 'manifest order', 'Consumer', 'structural conflict', 'unique task owner', 'tasks`-kind', 'two-end overview')) {
        Assert-Condition ($handoffText.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "$handoffPath is missing resolved artifact handoff evidence: $anchor"
    }
    Assert-Condition (-not (Test-UnconditionalStablePlanFirstRead $handoffText)) "$handoffPath instructs an unconditional stable-plan-first read"
}
$sddArtifactResolutionTemplates = @(
    'skills\fp-execute-sdd\task-brief-template.md'
    'skills\fp-execute-sdd\review-package-template.md'
)
foreach ($templatePath in $sddArtifactResolutionTemplates) {
    $templateText = Read-Utf8 (Join-Path $root $templatePath)
    foreach ($anchor in @('| Logical artifact | Canonical entry | Resolution mode | Ordered fragments |', 'PRD', 'Proposal', 'Backend design', 'Frontend design', 'Backend plan', 'Frontend plan', 'small | split | N/A')) {
        Assert-Condition ($templateText.Contains($anchor)) "$templatePath is missing per-logical-artifact resolution evidence: $anchor"
    }
    Assert-Condition (-not ($templateText.Contains('- Resolution mode: `canonical small | canonical split`'))) "$templatePath still has a singular resolution mode"
}

$startCommand = Read-Utf8 (Join-Path $root 'commands\fp-start.md')
Assert-Condition ($startCommand.Contains('${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md') -and $startCommand.Contains('canonical-first Consumer')) 'fp-start command adapter must delegate canonical artifact resolution to the shared contract'

foreach ($anchor in @('resolved logical PRD content', 'resolved logical proposal content', 'small file OR split index/fragments', '`fp-propose` preserves the resolved proposal form')) {
    Assert-Condition ($startSkill.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "fp-start is missing split requirement handoff wording: $anchor"
}
Assert-Condition (-not ($startSkill.Contains('summarize from the PRD into `proposal.md`'))) 'fp-start still steers fp-propose back to the stable proposal file'

$structuralReviewBlockers = @(
    'Any structural rejection from `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` makes `PASS` and `PASS_WITH_NOTES` impossible'
    'missing split index'
    'missing manifest fragment'
    'unindexed fragment'
    'file-plus-directory conflict'
    'duplicate content owner'
    'duplicate task owner'
    'invalid manifest Kind'
    'forbidden checkbox location'
    'invalid overview reference'
    'dependency cycle'
    'size-limit violation'
    'continue collecting findings'
)
foreach ($anchor in $structuralReviewBlockers) {
    Assert-Condition ($reviewSkill.IndexOf($anchor, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "fp-review is missing blocking structural verdict contract: $anchor"
}

foreach ($templatePath in @(
    'skills\fp-execute-sdd\task-brief-template.md'
    'skills\fp-execute-sdd\review-package-template.md'
    'skills\fp-review\final-review-template.md'
)) {
    $templateText = Read-Utf8 (Join-Path $root $templatePath)
    Assert-Condition (-not (Test-MalformedTasksKindInlineCode $templateText)) "$templatePath has malformed inline code around tasks-kind"
    Assert-Condition (-not ($templateText.Contains('tasks/plan-*.md'))) "$templatePath uses an inexact wildcard task-owner placeholder"
    Assert-Condition ($templateText.Contains('<exact resolved task-owner path>')) "$templatePath is missing the explicit exact-owner-path placeholder"
}

$strictPlanFiles = @(
    'skills\fp-plan\SKILL.md'
    'skills\fp-plan-backend\SKILL.md'
    'skills\fp-plan-frontend\SKILL.md'
)
foreach ($strictPlanPath in $strictPlanFiles) {
    $strictPlanText = Read-Utf8 (Join-Path $root $strictPlanPath)
    Assert-Condition ($strictPlanText.IndexOf('structural conflict', [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "$strictPlanPath is missing the historical structural-conflict blocker"
    Assert-Condition ($strictPlanText -notmatch '(?im)^#{1,6}\s+Legacy read compatibility\s*$') "$strictPlanPath still advertises Legacy read compatibility"
    Assert-Condition ($strictPlanText -notmatch '(?i)(?:fallback|\u56DE\u9000|\u53EA\u8BFB\u56DE\u9000)[^\r\n]*(?:design-backend\.md|design-frontend\.md)') "$strictPlanPath still permits a root-design fallback"
    Assert-Condition ($strictPlanText -notmatch '(?i)canonical[^\r\n]*(?:legacy|historical)[^\r\n]*(?:entrypoint|\u8BBE\u8BA1\u4EA7\u7269)[^\r\n]*(?:exists|\u5B58\u5728|\u6CA1\u6709)') "$strictPlanPath still treats a historical entrypoint as usable input state"
}

$reviewContractText = Read-Utf8 (Join-Path $root 'skills\fp-review\SKILL.md')
Assert-Condition (-not $reviewContractText.Contains('outside a valid unambiguous legacy Consumer mode')) 'fp-review still exempts a legacy Consumer mode from file-plus-directory conflicts'
$finalReviewerText = Read-Utf8 (Join-Path $root 'skills\fp-review\final-reviewer.md')
Assert-Condition (-not $finalReviewerText.Contains('{CANONICAL_SMALL_SPLIT_OR_LEGACY_READ_ONLY}')) 'final-reviewer still exposes a legacy resolution placeholder'
Assert-Condition (-not $finalReviewerText.Contains('Compatibility warning / migration debt')) 'final-reviewer still exposes compatibility warning or migration debt'
Assert-Condition ($finalReviewerText.Contains('{CANONICAL_SMALL_OR_SPLIT}')) 'final-reviewer is missing its canonical-only resolution placeholder'

foreach ($noCompatibilityPath in @(
    'skills\fp-brainstorm\SKILL.md'
    'skills\fp-plan\SKILL.md'
    'skills\fp-plan-backend\SKILL.md'
    'skills\fp-plan-frontend\SKILL.md'
    'skills\_shared\workspace-rules.md'
    'skills\fp-ui-spec\SKILL.md'
    'skills\fp-ux-spec\SKILL.md'
)) {
    $noCompatibilityText = Read-Utf8 (Join-Path $root $noCompatibilityPath)
    Assert-Condition ($noCompatibilityText -notmatch '(?i)\blegacy compatibility\b') "$noCompatibilityPath still advertises legacy compatibility"
    Assert-Condition ($noCompatibilityText -notmatch '(?im)^#{1,6}\s+Legacy read compatibility\s*$') "$noCompatibilityPath still has a Legacy read compatibility heading"
}

$commandChars = ($commands | ForEach-Object { (Read-Utf8 $_.FullName).Length } | Measure-Object -Sum).Sum
Assert-Condition ($commandChars -le 5000) "command adapters exceed the 5000-character budget: $commandChars"

$skillChars = ($skills | ForEach-Object { (Read-Utf8 (Join-Path $_.FullName 'SKILL.md')).Length } | Measure-Object -Sum).Sum
$coreChars = $commandChars + $skillChars + $sharedText.Length
Write-Output "FeaturePilot plugin validation passed: $($commands.Count) commands, $($skills.Count) skills, all SKILL.md files <= 500 lines, core prompt chars $coreChars."
