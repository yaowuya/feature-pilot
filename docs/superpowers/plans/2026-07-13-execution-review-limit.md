# FeaturePilot Execution Review Limit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将普通 `fp-execute`、`fp-execute-sdd` 和最终整体审查统一限制为每个 review scope 最多 3 次，并在达到上限后按主流程影响决定继续或阻塞。

**Architecture:** 用 `scripts/validate-plugin.ps1` 固定可搜索的审查契约锚点；普通执行在现有 TDD 流程中加入有限 inline review 状态机，SDD 控制器把无限 fix loop 改为按 scope 持久化的 `review_attempt = 1..3` 状态机。reviewer 只报告证据，controller 负责主流程阻断分类，append-only ledger 保存所有失败点与恢复计数。

**Tech Stack:** Markdown skill/prompt contracts、PowerShell validation、Codex fresh-context subagent evaluation、Git。

## Global Constraints

- 单个任务 review scope 最多 3 次 review，首次 review 计为第 1 次；不得产生第 4 次 review。
- task review scope 与 final review scope 分别计数；finding、reviewer、fixer、commit、会话切换或中断恢复不得重置计数。
- 每次未通过都必须在 `progress.md` 记录 attempt、verdict、Critical / Important / Minor finding、review 路径和处理结论。
- 第 3 次仍未通过时，非主流程问题记录为 `review debt` 并继续；主流程问题记录为 `BLOCKED` 并暂停。
- Critical、核心验收不可用、安全/权限/数据风险、阻断下游的外部契约、必需构建或核心测试失败、需要修改批准范围或新增产品/架构/安全决策，均属于主流程阻断。
- 非阻断 review debt 可以同步 task-owner checkbox；主流程阻断不得勾选 checkbox。
- task-owner checkbox 继续是计划完成权威；ledger 只保存恢复与证据，不成为第二完成权威。
- FeaturePilot 过程文档叙述性内容默认使用中文；代码、命令、路径、技术标识符和精确契约关键词保留必要英文。
- 不并行派发 implementer、fixer 或 reviewer。

## File Structure

- Modify: `scripts/validate-plugin.ps1` — 增加 ordinary/SDD/template review limit 回归断言，并禁止无限循环旧文案。
- Modify: `skills/fp-execute/SKILL.md` — 定义 inline review 次数、ledger 证据、review debt 与主流程阻断分支。
- Modify: `skills/fp-execute-sdd/SKILL.md` — 将 task/final fix loop 改为可恢复的最多 3 次有限状态机。
- Modify: `skills/fp-execute-sdd/task-reviewer-prompt.md` — 向 reviewer 提供当前 attempt，并要求报告主流程影响证据但不替 controller 决策。
- Modify: `skills/fp-execute-sdd/fix-prompt.md` — 只允许第 1、2 次 review 后派发 fixer，禁止暗示第 4 次 review。

---

### Task 1: 固定普通执行的审查上限

**Files:**
- Modify: `scripts/validate-plugin.ps1:878`
- Modify: `skills/fp-execute/SKILL.md:40`
- Modify: `skills/fp-execute/SKILL.md:61`
- Modify: `skills/fp-execute/SKILL.md:117`
- Test: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: 现有 `Read-Utf8`、`Assert-Condition`、`$executeSkill` 和 `progress.md` 契约。
- Produces: ordinary execution 的 `review_attempt = 1..3`、`review debt`、`main-flow blocker` 和 checkbox 处理规则；Task 2 使用同一术语对齐 SDD。

- [ ] **Step 1: 用现有 SDD skill 做五次 fresh-context 基线测试**

每次都使用全新 subagent，只给原始 skill 路径和以下场景，不告诉 agent 预期修复：

```text
Use the current skill at D:\01-code\feature-pilot\skills\fp-execute-sdd\SKILL.md to decide the controller's next action.

Execution mode is automatic-continuation. Task backend-001 has already received three reviews. Review 1 found one Important test-evidence issue and it was fixed. Review 2 found a different Important local error-handling issue and it was fixed. Review 3 found a different Important maintainability/test-edge issue that remains. The reviewer says Ready for next task: NO. None of the remaining issues affects core acceptance behavior, security, permissions, data integrity, external contracts, required build/core tests, or downstream dependencies. The user is unavailable.

State exactly whether the controller dispatches another fixer/reviewer, blocks, or continues to the next task, and cite the skill rule you used. Do not edit files.
```

逐个阅读五份输出并记录其实际选择和理由。基线至少应出现一次继续 fix/review 或口径不一致；如果五次都稳定禁止第 4 次 review，则停止实施并重新检查需求与基线场景。

- [ ] **Step 2: 写入 ordinary execution 的失败断言**

在 `$executeSkill` 读取后加入：

```powershell
$executeReviewAnchors = @(
    '单个任务步骤最多执行 3 次 review'
    '首次 review 计为第 1 次'
    '不得执行第 4 次 review'
    'review debt'
    '主流程阻断'
    '恢复已有 review attempt'
)
foreach ($anchor in $executeReviewAnchors) {
    Assert-Condition ($executeSkill.Contains($anchor)) "fp-execute is missing bounded review contract: $anchor"
}
```

- [ ] **Step 3: 运行验证并确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
```

Expected: FAIL，首个错误包含 `fp-execute is missing bounded review contract` 和 `单个任务步骤最多执行 3 次 review`。

- [ ] **Step 4: 在普通执行 skill 中加入最小有限 review 状态机**

在 `## TDD 执行流程（每个任务）` 前加入以下规则，并同步 ledger 示例、checkbox 步骤和完成汇报：

```markdown
## Review 次数与上限（每个任务）

- 单个任务步骤最多执行 3 次 review，首次 review 计为第 1 次。
- 第 1 或第 2 次 review 未通过时，先把 Critical / Important 未通过点追加到 ledger，再做一次定向修复并进入下一次 review。
- 第 3 次 review 仍未通过时，停止该任务的 review/fix 循环，不得执行第 4 次 review。
- 达到上限后，把所有未通过点、严重级别、review 路径和处理结论记录为 review debt；不影响主流程时允许同步 task-owner checkbox 并继续下一任务。
- Critical、核心验收不可用、安全/权限/数据风险、阻断下游的外部契约、必需构建或核心测试失败、需要修改批准范围或新增产品/架构/安全决策，均属于主流程阻断；此时记录 BLOCKED，不勾选 checkbox，并暂停请求用户决策。
- 从 progress.md 恢复已有 review attempt；不得因换 finding、reviewer、fixer、commit、会话或恢复执行而重置计数。
```

将 ledger 示例补充 `## Review Debt` 和 `review_attempt` event；把原“发现 Critical/Important 问题必须先修复”改为按 attempt 分支；把 checkbox 更新条件改为“review 通过，或第 3 次后仅剩非阻断 review debt”。

- [ ] **Step 5: 运行验证并确认 GREEN**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
```

Expected: PASS，并输出 `FeaturePilot plugin validation passed`。

- [ ] **Step 6: 提交 ordinary execution 契约**

```powershell
git add scripts/validate-plugin.ps1 skills/fp-execute/SKILL.md
git commit -m "fix: bound inline execution reviews"
```

---

### Task 2: 将 SDD task/final review 改为有限状态机

**Files:**
- Modify: `scripts/validate-plugin.ps1:441`
- Modify: `skills/fp-execute-sdd/SKILL.md:15`
- Modify: `skills/fp-execute-sdd/SKILL.md:27`
- Modify: `skills/fp-execute-sdd/SKILL.md:107`
- Modify: `skills/fp-execute-sdd/SKILL.md:141`
- Modify: `skills/fp-execute-sdd/SKILL.md:251`
- Modify: `skills/fp-execute-sdd/SKILL.md:272`
- Modify: `skills/fp-execute-sdd/SKILL.md:299`
- Test: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: Task 1 的 `review attempt`、`review debt`、`主流程阻断` 语义。
- Produces: SDD controller 的 task review scope、final review scope、ledger 恢复和最多两次 fix 派发规则；Task 3 的 prompt placeholders 从这里取得当前 attempt。

- [ ] **Step 1: 写入 SDD 失败断言和旧无限循环禁令**

在 `$sddSkillText` 读取后加入：

```powershell
$sddReviewAnchors = @(
    'maximum of three reviews per review scope'
    'The initial review is attempt 1'
    'must not dispatch a fourth review'
    'review debt'
    'main-flow blocker'
    'restore the recorded review attempt'
    'final review scope'
)
foreach ($anchor in $sddReviewAnchors) {
    Assert-Condition ($sddSkillText.Contains($anchor)) "fp-execute-sdd is missing bounded review contract: $anchor"
}
Assert-Condition (-not $sddSkillText.Contains('fixes loop until reviewed clean')) 'fp-execute-sdd still promises an unbounded clean-review loop'
Assert-Condition (-not $sddSkillText.Contains('Repeat until `Spec Compliance: PASS`')) 'fp-execute-sdd still repeats review until clean without a total cap'
```

- [ ] **Step 2: 运行验证并确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
```

Expected: FAIL，错误包含 `fp-execute-sdd is missing bounded review contract` 或 `still promises an unbounded clean-review loop`。

- [ ] **Step 3: 替换 task review/fix 无限循环**

在 `fp-execute-sdd/SKILL.md` 中使用以下状态机替换 core rule、automatic continuation pause rule、controller responsibilities、Fix Loop 和 invariant recap 的无限循环语义：

```markdown
Each task review scope has a maximum of three reviews. The initial review is attempt 1. A failed attempt 1 or 2 may dispatch one serial fixer followed by the next review. After failed attempt 3, the controller must not dispatch a fourth review or another automatic fixer.

At failed attempt 3, record every remaining finding and classify it with evidence. If no finding is a main-flow blocker, record review debt, reconcile the task-owner checkbox, and continue according to the selected continuation mode. If any finding is a main-flow blocker, record BLOCKED, leave the checkbox unchecked, and pause for the exact user decision required.
```

主流程阻断定义必须逐项覆盖 Global Constraints 中的六类条件。把 `progress.md` 示例增加 `## Review Debt`，并要求每轮追加：

```markdown
- 2026-07-13T08:00:00+08:00 review_attempt task=backend-001 attempt=2/3 verdict=FAIL critical=0 important=1 minor=0 review=.fp-execute/reviews/backend-001-review.md
```

恢复规则必须包含 `restore the recorded review attempt`，并明确换 finding/reviewer/fixer/commit/session 不能重置。

- [ ] **Step 4: 限制 final review scope**

把 `Completion and Final Review` 中的无限 serial fix loop 改为：final review scope 独立从 attempt 1 开始、总计最多 3 次；第 3 次后非阻断项进入最终 `review debt` 报告，主流程阻断项阻止完成/归档；已有 task scope 不因 final review 重置或重新开启。

- [ ] **Step 5: 运行验证并确认 GREEN**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
```

Expected: PASS，并且以下搜索无匹配：

```powershell
rg -n "fixes loop until reviewed clean|Repeat until `Spec Compliance: PASS`" skills/fp-execute-sdd/SKILL.md
```

- [ ] **Step 6: 提交 SDD controller 契约**

```powershell
git add scripts/validate-plugin.ps1 skills/fp-execute-sdd/SKILL.md
git commit -m "fix: cap SDD review loops at three"
```

---

### Task 3: 向 reviewer/fixer 传递 attempt 并固定职责边界

**Files:**
- Modify: `scripts/validate-plugin.ps1:735`
- Modify: `skills/fp-execute-sdd/task-reviewer-prompt.md:12`
- Modify: `skills/fp-execute-sdd/task-reviewer-prompt.md:103`
- Modify: `skills/fp-execute-sdd/fix-prompt.md:15`
- Modify: `skills/fp-execute-sdd/fix-prompt.md:31`
- Test: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: Task 2 controller 保存的 `{REVIEW_ATTEMPT}` 和固定 `{MAX_REVIEW_ATTEMPTS}` 值 `3`。
- Produces: reviewer 的事实证据字段、fixer 的合法派发前置条件，以及 controller 独占的阻断分类职责。

- [ ] **Step 1: 写入 prompt 模板失败断言**

在 validator 中读取两个模板并加入：

```powershell
$taskReviewerPrompt = Read-Utf8 (Join-Path $root 'skills\fp-execute-sdd\task-reviewer-prompt.md')
$fixPrompt = Read-Utf8 (Join-Path $root 'skills\fp-execute-sdd\fix-prompt.md')
foreach ($anchor in @(
    'Review attempt: {REVIEW_ATTEMPT} of {MAX_REVIEW_ATTEMPTS}'
    'Potential main-flow impact evidence'
    'The controller, not the reviewer, decides whether a failed finding blocks the main flow'
)) {
    Assert-Condition ($taskReviewerPrompt.Contains($anchor)) "task reviewer prompt is missing bounded review context: $anchor"
}
foreach ($anchor in @(
    'Review attempt that produced these findings: {LAST_COMPLETED_REVIEW_ATTEMPT} of {MAX_REVIEW_ATTEMPTS}'
    'A fixer may be dispatched only after review attempt 1 or 2 of 3'
    'Do not request or imply a fourth review'
)) {
    Assert-Condition ($fixPrompt.Contains($anchor)) "fix prompt is missing bounded review context: $anchor"
}
```

- [ ] **Step 2: 运行验证并确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
```

Expected: FAIL，错误包含 `task reviewer prompt is missing bounded review context`。

- [ ] **Step 3: 更新 reviewer prompt**

在 Inputs 中加入：

```text
Review attempt: {REVIEW_ATTEMPT} of {MAX_REVIEW_ATTEMPTS}
```

在 Review Method 和 Final Assessment 中加入 `Potential main-flow impact evidence`，要求 reviewer 只报告该 finding 是否影响核心验收、安全/权限/数据、外部契约、必需构建/核心测试、下游依赖或已批准范围。加入精确职责句：

```text
The controller, not the reviewer, decides whether a failed finding blocks the main flow.
```

reviewer 仍必须如实输出 Critical / Important / Minor 和 `Ready for next task`，controller 不得仅凭该布尔值跳过证据分类。

- [ ] **Step 4: 更新 fixer prompt**

在 Required Reading 前加入：

```text
Review attempt that produced these findings: {LAST_COMPLETED_REVIEW_ATTEMPT} of {MAX_REVIEW_ATTEMPTS}
```

在 Required Behavior 加入：

```text
A fixer may be dispatched only after review attempt 1 or 2 of 3. If the supplied attempt is 3 of 3, stop and report BLOCKED because the controller must classify the remaining findings instead. Do not request or imply a fourth review.
```

- [ ] **Step 5: 运行验证并确认 GREEN**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
```

Expected: PASS，并输出 `FeaturePilot plugin validation passed`。

- [ ] **Step 6: 提交 prompt 契约**

```powershell
git add scripts/validate-plugin.ps1 skills/fp-execute-sdd/task-reviewer-prompt.md skills/fp-execute-sdd/fix-prompt.md
git commit -m "fix: pass bounded review context to SDD agents"
```

---

### Task 4: Forward-test 与完整回归

**Files:**
- Verify: `skills/fp-execute/SKILL.md`
- Verify: `skills/fp-execute-sdd/SKILL.md`
- Verify: `skills/fp-execute-sdd/task-reviewer-prompt.md`
- Verify: `skills/fp-execute-sdd/fix-prompt.md`
- Verify: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: Tasks 1–3 的完整有限 review 契约。
- Produces: 五次 fresh-context 一致性证据、完整插件回归证据和最终差异审计。

- [ ] **Step 1: 用修改后的 skill 重跑五次相同 fresh-context 场景**

逐份人工读取输出。Expected: 五次都明确禁止第 4 次 review；该场景无主流程阻断，因此都记录 review debt 并继续下一任务。任何一次继续 fix/review、重置 attempt 或仅因 `Ready for next task: NO` 而 BLOCKED，都视为失败并返回 Task 2 收紧契约。

- [ ] **Step 2: 运行完整插件验证**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
```

Expected: PASS，输出 `FeaturePilot plugin validation passed`。

- [ ] **Step 3: 运行相关回归脚本**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-artifact-layout.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-explore-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-sdd-benchmark-fixture.ps1
```

Expected: 三条命令均以 exit code 0 完成，并分别输出其通过摘要。

- [ ] **Step 4: 审计旧循环文案、格式和工作区差异**

```powershell
rg -n "fixes loop until reviewed clean|Repeat until `Spec Compliance: PASS`|same blocking review finding surviving three fix attempts" skills/fp-execute-sdd
git diff --check
git status -sb
```

Expected: `rg` 无匹配，`git diff --check` 无输出，`git status -sb` 只显示本计划中的预期文件修改或已提交后的干净状态。

- [ ] **Step 5: 对照设计逐项复核**

重新读取 `docs/superpowers/specs/2026-07-13-execution-review-limit-design.md`，确认 task/final scope、3 次总上限、失败点记录、非阻断继续、主流程阻断、恢复不重置、checkbox 权威和最终报告全部有对应实现与验证证据。
