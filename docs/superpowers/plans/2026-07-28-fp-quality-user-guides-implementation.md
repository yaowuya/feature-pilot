# FeaturePilot 专项用户指南实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 `fp-coverage` 与 `fp-module-review` 创建两份独立、可执行、受 focused contracts 保护的中文用户指南，并接入 README 与主线用户指南。

**Architecture:** 两份用户指南分别以对应 `SKILL.md` 为事实源，不复制成新的流程权威。两个 focused PowerShell contract 负责验证指南存在、公共入口、关键合同锚点和文件预算；README 与 `init-prd-start.md` 只提供短入口，避免重复完整流程。

**Tech Stack:** Markdown、PowerShell 5 contract tests、Claude Code/Codex plugin runtime、Git。

## Global Constraints

- 创建 `docs/user_guide/fp-coverage.md` 与 `docs/user_guide/fp-module-review.md`，不得合并成一份长文。
- 中文叙述为主；命令、路径、状态、schema、Finding ID 和完成谓词保留必要英文。
- `SKILL.md` 是事实源；指南不得发明未实现的行为。
- 每份指南不超过 500 行和 30,000 字符，不含 placeholder、客户路径或固定默认覆盖率。
- README 必须显式链接两份指南；`docs/user_guide/init-prd-start.md` 只添加简短专项入口和链接。
- 先添加 focused contract 并观察指南缺失导致的 RED，再创建指南和入口使其 GREEN。
- 不修改插件版本，不 commit、不 push，不覆盖并行会话变更。

---

### Task 1: 锁定两份用户指南的失败合同

**Files:**
- Modify: `scripts/test-coverage-contract.ps1:161-177,420-451`
- Modify: `scripts/test-module-review-contract.ps1:34-59,132-154`
- Test: `scripts/test-coverage-contract.ps1`
- Test: `scripts/test-module-review-contract.ps1`

**Interfaces:**
- Consumes: 当前 coverage/module-review skill、README 与主线指南。
- Produces: `$coverageGuide` 与 `$moduleGuide` 文本面，以及指南存在、入口、语义锚点和 500 行/30,000 字符预算门禁。

- [ ] **Step 1: 为 coverage contract 添加指南路径、读取和存在性检查**

在 `$commandPath` 附近加入并读取：

```powershell
$coverageGuidePath = Join-Path $root 'docs\user_guide\fp-coverage.md'
$mainGuidePath = Join-Path $root 'docs\user_guide\init-prd-start.md'
Assert-Condition (Test-Path $coverageGuidePath) 'docs/user_guide/fp-coverage.md is missing'
$coverageGuide = Read-Utf8 $coverageGuidePath
$mainGuide = Read-Utf8 $mainGuidePath
```

在公共文档断言区加入：

```powershell
Assert-Condition ($readme.Contains('docs/user_guide/fp-coverage.md')) 'README lacks the fp-coverage user guide link'
Assert-Condition ($mainGuide.Contains('fp-coverage.md')) 'main user guide lacks the fp-coverage guide link'
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
Assert-Condition (-not ($coverageGuide -match '(?m)^/fp-coverage[^\r\n]*\b(?:80|85|90|100)%')) 'coverage guide hardcodes a default target percentage'
$coverageGuideLineCount = @($coverageGuide -split "`r?`n").Count
Assert-Condition ($coverageGuideLineCount -le 500) "coverage guide has $coverageGuideLineCount lines (limit: 500)"
Assert-Condition ($coverageGuide.Length -le 30000) "coverage guide has $($coverageGuide.Length) characters (limit: 30,000)"
```

- [ ] **Step 2: 为 module-review contract 添加指南路径、读取和语义门禁**

将指南加入 `$required` 并读取：

```powershell
'docs\user_guide\fp-module-review.md'
```

```powershell
$moduleGuide = Read-Utf8 'docs\user_guide\fp-module-review.md'
$readme = Read-Utf8 'README.md'
$mainGuide = Read-Utf8 'docs\user_guide\init-prd-start.md'
```

加入：

```powershell
Assert-Anchors $moduleGuide @(
    '/fp-module-review',
    'fp:fp-module-review',
    'targets',
    'slug',
    'focus',
    'mode',
    'baseRef',
    'full',
    'review-only',
    'resume',
    'fp-docs/module-reviews/<slug>/',
    'review.md',
    'scope.md',
    'baseline.md',
    'waves.md',
    'findings/MR-FNNN.md',
    'summary.md',
    '.fp-module-review/progress.md',
    'SCOPING',
    'WAITING_APPROVAL',
    'VERIFYING',
    'COMPLETE_WITH_AWAITING',
    'CANNOT_VERIFY',
    'candidate',
    'confirmed',
    'awaiting-user-confirmation',
    'approved',
    'fixed',
    'rejected',
    'blocked',
    'observable behavior',
    'fp-final-review'
) 'module-review guide'
Assert-Condition ($readme.Contains('docs/user_guide/fp-module-review.md')) 'README lacks the fp-module-review user guide link'
Assert-Condition ($mainGuide.Contains('fp-module-review.md')) 'main user guide lacks the fp-module-review guide link'
$moduleGuideLineCount = @($moduleGuide -split "`r?`n").Count
Assert-Condition ($moduleGuideLineCount -le 500) "module-review guide has $moduleGuideLineCount lines (limit: 500)"
Assert-Condition ($moduleGuide.Length -le 30000) "module-review guide has $($moduleGuide.Length) characters (limit: 30,000)"
```

- [ ] **Step 3: 运行 coverage focused RED**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-coverage-contract.ps1
```

Expected: FAIL，消息为 `docs/user_guide/fp-coverage.md is missing`，不是 PowerShell parser error。

- [ ] **Step 4: 运行 module-review focused RED**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-module-review-contract.ps1
```

Expected: FAIL，消息为 `required surface is missing: docs\user_guide\fp-module-review.md`，不是现有 skill 合同失败。

### Task 2: 编写两份独立用户指南并接入公共入口

**Files:**
- Create: `docs/user_guide/fp-coverage.md`
- Create: `docs/user_guide/fp-module-review.md`
- Modify: `README.md`
- Modify: `docs/user_guide/init-prd-start.md`
- Test: `scripts/test-coverage-contract.ps1`
- Test: `scripts/test-module-review-contract.ps1`

**Interfaces:**
- Consumes: Task 1 的指南 contracts；`skills/fp-coverage/SKILL.md` 与 `skills/fp-module-review/SKILL.md` 的现行事实。
- Produces: 两份面向用户的专项指南和两个短导航入口。

- [ ] **Step 1: 创建 `fp-coverage.md`**

按以下顺序写完整中文内容：

```text
# fp-coverage 用户指南
作用与适用场景
不适用场景
最短用法（Claude Code 与 Codex）
开始前必须明确的 target、metric 与 toolchain
缺少 coverage 工具：RESOLVING + CANNOT_VERIFY + approval-gated coverage-tooling-bootstrap
Django fallback：已有 pytest 只补 pytest-cov；无 pytest 才用 pytest + pytest-cov；pytest-django 按需
状态流：RESOLVING → BASELINING → TRIAGING → ITERATING → FINAL_VERIFYING → COMPLETE/BLOCKED
metric freeze 与禁止捷径
owner batch 循环
coverage change artifact tree
split evidence 文件职责与 bounded progress
issues.md 只记录 unit-test-discovered production-code/test-code 问题
中断恢复与 stale evidence
completion boundary 生成 final-report.md
双门与完整完成谓词
常见结果解释、误区及与 fp-start/普通执行/生产缺陷修复的关系
```

命令示例使用显式、非固定百分比目标：

```text
/fp-coverage 将 line coverage 提高到 <明确目标>，使用项目现有正式测试与 coverage 口径
fp:fp-coverage 将 line coverage 提高到 <明确目标>，使用项目现有正式测试与 coverage 口径
```

完整完成谓词至少原样包含：

```text
full_command_exit_code == 0
AND exact_coverage >= target
```

- [ ] **Step 2: 创建 `fp-module-review.md`**

按以下顺序写完整中文内容：

```text
# fp-module-review 用户指南
作用、适用与不适用场景
最短用法（Claude Code 与 Codex）
输入：targets、slug、focus、mode、baseRef 与 target ambiguity
三种 mode：full、review-only、resume
canonical workspace 与文件 owner
lifecycle states
SCOPING/BASELINING 与 SAFE/UNSAFE/UNKNOWN command safety
ownership/call-flow waves
stable MR-FNNN、proof、severity 与 Finding transitions
observable behavior approval gate
approved Finding 的 TDD fixing 与 verification
resume、fingerprint 与 invalidation
COMPLETE、COMPLETE_WITH_AWAITING、BLOCKED、CANNOT_VERIFY
与 fp-final-review、PR review、小 diff review 的区别
full/review-only/resume/多目标示例和常见误区
```

Finding transitions 原样列出：

```text
candidate
confirmed
awaiting-user-confirmation
approved
fixed
rejected
blocked
```

- [ ] **Step 3: 在 README 添加显式链接**

在命令/技能表或用户文档入口中添加两个相对链接：

```markdown
- [`fp-coverage` 用户指南](docs/user_guide/fp-coverage.md)
- [`fp-module-review` 用户指南](docs/user_guide/fp-module-review.md)
```

只加链接和一句适用说明，不复制指南正文。

- [ ] **Step 4: 在主线指南添加专项入口**

在 `init-prd-start.md` 的专项流程/后续工作区域加入：

```markdown
### 覆盖率专项

当目标是先冻结统计口径，再按可恢复 owner batch 补充测试，并以 fresh full-suite 与 exact coverage 双门验收时，使用 [`fp-coverage`](fp-coverage.md)。

### 模块专项审查

当目标是按显式 scope 对大型或多个相关模块分 wave 审查、登记稳定 Finding，并在批准后执行修复时，使用 [`fp-module-review`](fp-module-review.md)。它不替代最终独立审查 `fp-final-review`。
```

若已有“模块专项审查”段落，则最小改写并添加链接，不创建重复标题。

- [ ] **Step 5: 运行两个 focused GREEN**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-coverage-contract.ps1
```

Expected: `fp-coverage contract validation passed.`

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-module-review-contract.ps1
```

Expected: `Module review contract validation passed.`

### Task 3: 全量验证、独立审查与运行时同步

**Files:**
- Modify only if a verified review finding requires it: the two guides, README, main guide, or focused contracts.
- Test: all FeaturePilot validators and plugin runtime verification.

**Interfaces:**
- Consumes: Task 2 的 GREEN 文档面。
- Produces: fresh validator evidence、独立审查结论和四方运行时哈希一致性。

- [ ] **Step 1: 运行全量插件验证**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
```

Expected: 所有 focused contracts 通过，12 commands、21 skills、所有 `SKILL.md` 文件预算通过。

- [ ] **Step 2: 独立文档审查**

派发只读 reviewer，要求仅报告 Critical/Important，并核对：指南与 skill 事实一致、无默认阈值、coverage report timing 无循环、progress 边界正确、module Finding/approval/completion 语义正确、链接可达、无大段重复。对确认的问题先补 focused RED，再最小修复并复跑。

- [ ] **Step 3: 运行 fresh 静态验证**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\measure-context.ps1
```

```bash
claude plugin validate .
```

```bash
git diff --check
```

Expected: 三条命令 exit 0；指南与 skill/template 均满足文件预算。

- [ ] **Step 4: 重跑 focused 与 full validator**

依次重跑两个 focused contracts 和 `scripts/validate-plugin.ps1`，以修复后的 fresh 输出作为最终测试证据。

- [ ] **Step 5: 同步本地运行时**

调用项目 `sync-plugin-runtimes` skill，保持插件版本不变，执行正常同步和 `-VerifyOnly`。Expected：repository、Codex source、Codex cache、Claude cache hashes 一致。

- [ ] **Step 6: 检查最终工作树**

```bash
git status --short --untracked-files=all
```

Expected: 只包含已知共享改动、本计划、两份指南及 focused/public-doc 增量；无临时测试、coverage report 或 cache。不得 commit、push 或创建 PR。

## Self-Review

- Spec coverage：Task 1 覆盖双 focused RED 和指南预算；Task 2 覆盖两份独立指南、README 与主线入口；Task 3 覆盖 focused/full/plugin/diff、独立审查和运行时同步。
- Placeholder scan：计划没有 `TBD`、`TODO` 或未定义实现步骤；指南示例中的 `<明确目标>` 是用户运行时必须提供的显式参数，不是未完成设计。
- Naming consistency：统一使用 `fp-coverage.md`、`fp-module-review.md`、`coverage-tooling-bootstrap`、`MR-FNNN`、`COMPLETE_WITH_AWAITING` 和 `final-report.md` completion boundary。
- Scope：只新增文档、导航和文档合同，不修改 skill 行为、插件版本或 Git 历史。
