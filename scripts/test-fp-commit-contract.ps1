$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) { throw "fp-commit contract validation failed: $message" }
}

function Read-Utf8([string]$relativePath) {
    $path = Join-Path $root $relativePath
    Assert-Condition (Test-Path -LiteralPath $path -PathType Leaf) "missing resource: $relativePath"
    return [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
}

function Assert-Anchors([string]$text, [string[]]$anchors, [string]$label) {
    foreach ($anchor in $anchors) {
        Assert-Condition ($text.Contains($anchor)) "$label is missing $anchor"
    }
}

function Get-Section([string]$text, [string]$heading, [string]$nextHeading) {
    $start = $text.IndexOf($heading, [StringComparison]::Ordinal)
    $end = $text.IndexOf($nextHeading, [StringComparison]::Ordinal)
    Assert-Condition ($start -ge 0 -and $end -gt $start) "missing or unordered section: $heading"
    return $text.Substring($start, $end - $start)
}

function Test-UnsafeCommitPolicy([string]$text) {
    foreach ($pattern in @(
        '(?i)git\s+add\s+-A|git\s+push\s+--force|git\s+commit\s+--no-verify',
        '(?im)^\s*(?:-\s*)?Host permission(?: mode)? Auto automatically enables fp-commit auto',
        '(?im)^\s*(?:-\s*)?Auto mode uses [`]?main[`]? without remote verification',
        '(?im)^\s*(?:-\s*)?In auto mode, use [`]?main[`]? as the default target without remote verification',
        '(?im)^\s*(?:-\s*)?Missing required validation still permits committing and pushing',
        '(?im)^\s*(?:-\s*)?When required validation is unavailable, continue committing and pushing',
        '(?im)^\s*(?:-\s*)?Missing initialized standards still permits committing',
        '(?im)^\s*(?:-\s*)?Auto mode automatically merges',
        '(?m)^\s*(?:-\s*)?宿主权限.*自动启用.*fp-commit auto',
        '(?m)^\s*(?:-\s*)?自动模式.*无需远端核实.*main',
        '(?m)^\s*(?:-\s*)?缺少必要验证仍可提交并推送',
        '(?m)^\s*(?:-\s*)?自动模式创建 PR/MR 后直接合并',
        '(?im)^\s*(?:-\s*)?In ordinary mode, ask whether to push after committing',
        '(?im)^\s*(?:-\s*)?Ask whether to create a PR/MR only after pushing',
        '(?im)^\s*(?:-\s*)?An upfront merge preference authorizes merging without final confirmation',
        '(?m)^\s*(?:-\s*)?普通模式在提交后询问是否推送',
        '(?m)^\s*(?:-\s*)?普通模式推送后询问是否创建 PR/MR',
        '(?m)^\s*(?:-\s*)?入口合并意向直接授权最终合并'
    )) {
        if ($text -match $pattern) { return $true }
    }
    return $false
}

function Assert-CommitSafetyPolicy([string]$text) {
    Assert-Condition ($text.Contains('## 0. 入口一次性选择')) 'missing upfront-selection section'
    $mode = Get-Section $text '## 输入和授权' '## 0. 入口一次性选择'
    Assert-Anchors $mode @(
        '仅本轮用户显式选择 `fp-commit auto` 或明确要求本技能的 `auto` 模式，才启用自动模式',
        '不能从宿主权限的 Auto/Bypass、历史选择或配置推断',
        '创建 PR/MR 后停止，**不自动合并**，也不启用平台 auto-merge'
    ) 'mode safety invariants'
    $intake = Get-Section $text '## 0. 入口一次性选择' '## 1. 只读预检与代码规范初始化'
    Assert-Anchors $intake @(
        '在 review、修复和任何 Git 写入前完成入口选择',
        '本轮已明确的选项直接复用，不重复询问',
        '一次收齐所有未明确的选项',
        '模式', '执行终点', '推送目的地', 'PR/MR 目标', '合并意向',
        '仅本地提交时远端字段记为 N/A，不要求远端查询或 PR/MR 鉴权',
        '入口选择仅授权所选阶段及目的地，未选阶段不执行',
        'commit 后不再询问是否 push，push 后不再询问是否创建 PR/MR',
        '目的地、源分支、目标分支或变更范围变化时停止，仅重新确认变化项',
        '入口合并意向不等于最终合并授权'
    ) 'upfront selection and authorization'
    $standards = Get-Section $text '## 1. 只读预检与代码规范初始化' '### 普通模式本地提交'
    Assert-Anchors $standards @('此时停止并要求运行 `/fp-init` 创建/更新相关 settings', '`fp-init` 的逐文件批准不能由 `auto` 代替') 'standards stop invariant'
    $localPreflight = Get-Section $text '### 普通模式本地提交' '### 自动模式远端预检'
    Assert-Anchors $localPreflight @('本地 review、修复、验证和 commit 不需要远端配置或 PR/MR 鉴权', '选定推送阶段', '选定 PR/MR 阶段') 'local-only preflight'
    $autoPreflight = Get-Section $text '### 自动模式远端预检' '## 2. 双轨 review'
    Assert-Anchors $autoPreflight @(
        'branch.<branch>.pushRemote', 'remote.pushDefault', 'branch.<branch>.remote', 'git remote get-url --push --all',
        '实际 push URL', 'git ls-remote --symref <push-url> HEAD',
        '必须唯一。多个 push URL、无法解析或指向不同仓库时停止',
        '核实 PR/MR 宿主识别的仓库与该目的地是**同一仓库**',
        '无法确定默认分支、当前就在默认分支、目的地不明或目标不存在时停止，不能猜 `main` / `master`'
    ) 'auto destination preflight'
    Assert-Condition (-not $autoPreflight.Contains('git ls-remote --symref <remote> HEAD')) 'default lookup still uses a fetch remote alias'
    $review = Get-Section $text '## 2. 双轨 review、修复与项目规范沉淀' '## 3. 精确暂存、commit 和 push'
    Assert-Anchors $review @('必要验证缺失时普通模式需用户明确接受具体缺口；自动模式以**检查失败**处理并停止，不把未验证冒充通过。') 'required verification stop invariant'
    $push = Get-Section $text '## 3. 精确暂存、commit 和 push' '## 4. PR/MR 与合并'
    Assert-Anchors $push @('推送前', '按入口已确认的推送授权执行，不再提问', 'refs/heads/<source>:refs/heads/<source>') 'push authorization and refspec'
    Assert-Condition (-not $push.Contains('单独确认后再推送')) 'push still asks for duplicate approval'
    $merge = Get-Section $text '## 4. PR/MR 与合并' '## 完成报告'
    Assert-Anchors $merge @('按入口选定的执行终点、仓库和**目标分支**创建或复用 PR/MR，不再询问是否创建或目标', '创建 PR/MR 后停止', '再次取得**确认合并**授权') 'PR and merge authorization'
    Assert-Condition (-not $merge.Contains('普通模式推送后询问')) 'PR selection still happens after pushing'
    Assert-Condition (-not (Test-UnsafeCommitPolicy $text)) 'skill contains an unsafe authorization or stop policy'
    Assert-Condition (-not ($text -match '(?m)^.*(?:默认目标分支[：:]\s*`?main`?|自动合并[：:]\s*是).*$')) 'skill guesses main or allows automatic merge'
}

function Test-PolicyRejected([string]$text) {
    try {
        Assert-CommitSafetyPolicy $text
        return $false
    } catch {
        if ($_.Exception.Message.StartsWith('fp-commit contract validation failed:')) { return $true }
        throw
    }
}

$command = Read-Utf8 'commands/fp-commit.md'
$skill = Read-Utf8 'skills/fp-commit/SKILL.md'
$workspace = Read-Utf8 'skills/_shared/workspace-rules.md'
$stackSelection = Read-Utf8 'skills/fp-init/stack-standards.md'
$engineering = Read-Utf8 'skills/_shared/engineering-quality.md'
$validator = Read-Utf8 'scripts/validate-plugin.ps1'
$guide = Read-Utf8 'docs/user_guide/fp-commit.md'
$reference = Read-Utf8 'docs/reference/commands-and-skills.md'

Assert-Anchors $command @('${CLAUDE_PLUGIN_ROOT}/skills/fp-commit/SKILL.md', '$ARGUMENTS', 'Gate checksum') 'command adapter'
Assert-Condition (@($command -split "`r?`n").Count -le 20) 'command adapter is not thin'
Assert-Anchors $skill @(
    'name: fp-commit', '插件资源锚定', '${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md',
    'Code Standards', 'Project rule sources', 'fp-init', 'appRoot',
    '规范符合性', '代码缺陷', '修复', '验证',
    'git diff --cached --stat', 'git diff --cached --check',
    'auto', '显式选择', '宿主权限', '远端默认分支', 'git ls-remote --symref',
    'PR/MR', '不自动合并', '已存在', '阻塞'
) 'skill workflow'
Assert-Anchors $skill @('settings/code-standards.md', '只维护', '已登记', '证据', '不创建') 'project rules scope'
Assert-CommitSafetyPolicy $skill
$livePolicies = @(
    @{ Original = '自动模式以**检查失败**处理并停止'; Inverted = '自动模式以**检查失败**记入报告但继续提交并推送' },
    @{ Original = '不能从宿主权限的 Auto/Bypass、历史选择或配置推断'; Inverted = '可以从宿主权限的 Auto/Bypass 自动启用' },
    @{ Original = '创建 PR/MR 后停止，**不自动合并**，也不启用平台 auto-merge'; Inverted = '创建 PR/MR 后继续合并，并启用平台 auto-merge' },
    @{ Original = '此时停止并要求运行 `/fp-init` 创建/更新相关 settings'; Inverted = '此时继续提交，不需要初始化 settings' },
    @{ Original = '必须唯一。多个 push URL、无法解析或指向不同仓库时停止'; Inverted = '有多个 push URL 时选第一个继续' },
    @{ Original = '核实 PR/MR 宿主识别的仓库与该目的地是**同一仓库**'; Inverted = 'PR/MR 使用 fetch URL 的仓库而非 push 目的地' },
    @{ Original = '无法确定默认分支、当前就在默认分支、目的地不明或目标不存在时停止，不能猜 `main` / `master`'; Inverted = '无法确定默认分支时猜 `main` 并继续' },
    @{ Original = '本地 review、修复、验证和 commit 不需要远端配置或 PR/MR 鉴权'; Inverted = '本地 commit 之前必须先通过 PR/MR 鉴权' },
    @{ Original = '在 review、修复和任何 Git 写入前完成入口选择'; Inverted = '在 commit 完成后再开始入口选择' },
    @{ Original = '本轮已明确的选项直接复用，不重复询问'; Inverted = '本轮已明确的选项也必须逐阶段重新询问' },
    @{ Original = '一次收齐所有未明确的选项'; Inverted = '每次只问一个选项，其余留到对应阶段再问' },
    @{ Original = '仅本地提交时远端字段记为 N/A，不要求远端查询或 PR/MR 鉴权'; Inverted = '仅本地提交也必须填写并查询远端目标' },
    @{ Original = '入口选择仅授权所选阶段及目的地，未选阶段不执行'; Inverted = '入口选择默认授权全部远端阶段' },
    @{ Original = 'commit 后不再询问是否 push，push 后不再询问是否创建 PR/MR'; Inverted = 'commit 后询问是否 push，push 后询问是否创建 PR/MR' },
    @{ Original = '目的地、源分支、目标分支或变更范围变化时停止，仅重新确认变化项'; Inverted = '目的地变化也沿用原授权继续推送' },
    @{ Original = '入口合并意向不等于最终合并授权'; Inverted = '入口合并意向直接授权最终合并' },
    @{ Original = '按入口已确认的推送授权执行，不再提问'; Inverted = '单独确认后再推送' },
    @{ Original = '按入口选定的执行终点、仓库和**目标分支**创建或复用 PR/MR，不再询问是否创建或目标'; Inverted = '普通模式推送后询问是否创建 PR/MR、目标分支和仓库' },
    @{ Original = '再次取得**确认合并**授权'; Inverted = '无需最终确认即可合并' }
)
foreach ($policy in $livePolicies) {
    Assert-Condition ($skill.Contains($policy.Original)) "live policy clause is missing: $($policy.Original)"
    foreach ($replacement in @('', $policy.Inverted)) {
        $mutated = $skill.Replace($policy.Original, $replacement)
        Assert-Condition (Test-PolicyRejected $mutated) "live policy removal or inversion was accepted: $($policy.Original)"
    }
}
foreach ($mutation in @(
    'Host permission Auto automatically enables fp-commit auto.',
    'Auto mode uses main without remote verification.',
    'In auto mode, use main as the default target without remote verification.',
    'Missing required validation still permits committing and pushing.',
    'When required validation is unavailable, continue committing and pushing.',
    'Missing initialized standards still permits committing.',
    'Auto mode automatically merges the created PR.',
    'git add -A',
    'git push --force',
    'git commit --no-verify',
    '宿主权限 Auto 自动启用 fp-commit auto。',
    '自动模式无需远端核实就使用 main。',
    '缺少必要验证仍可提交并推送。',
    '自动模式创建 PR/MR 后直接合并。',
    'In ordinary mode, ask whether to push after committing.',
    'Ask whether to create a PR/MR only after pushing.',
    'An upfront merge preference authorizes merging without final confirmation.',
    '普通模式在提交后询问是否推送。',
    '普通模式推送后询问是否创建 PR/MR。',
    '入口合并意向直接授权最终合并。'
)) {
    Assert-Condition (Test-PolicyRejected ($skill + "`n" + $mutation)) "unsafe mutation was accepted: $mutation"
}
foreach ($control in @(
    'Host permission Auto does not enable fp-commit auto.',
    'Auto mode uses the verified default branch and does not merge.',
    'Missing required validation blocks committing and pushing.',
    'Missing initialized standards blocks committing.',
    '自动模式只创建 PR/MR，不执行最终合并。',
    '普通模式按入口授权推送，实际目的地变化时停止。',
    '入口合并意向不代替检查通过后的最终确认。'
)) {
    Assert-Condition (-not (Test-PolicyRejected ($skill + "`n" + $control))) "safe control was rejected: $control"
}
Assert-Anchors $guide @('入口一次性选择', '执行终点', '推送目的地', '目标分支', '合并意向', '不重复询问', '最终合并授权') 'guide upfront choices'
Assert-Anchors $reference @('入口一次性选择', '最终合并') 'reference upfront choices'
Assert-Condition (-not $guide.Contains('提交后，技能展示')) 'guide still describes late push selection'
Assert-Condition (-not $reference.Contains('普通模式分别确认推送与合并')) 'reference still describes staged selection'
Assert-Anchors $workspace @('fp-commit', 'settings/code-standards.md', '已登记') 'workspace ownership'
Assert-Anchors $stackSelection @('settings/code-standards.md', 'Project rule sources:') 'init registration'
Assert-Anchors $engineering @('Code Standards', 'Project rule sources', 'Confirmed overrides') 'rule consumption'
Assert-Condition ($validator.Contains('test-fp-commit-contract.ps1')) 'full plugin validator does not invoke fp-commit contract checks'

Write-Output 'fp-commit contract checks passed (static coverage; no Git or remote operations).'
