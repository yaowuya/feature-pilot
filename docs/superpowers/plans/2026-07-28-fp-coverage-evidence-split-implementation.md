# fp-coverage Evidence Split and Code-Issue Reporting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 `fp-coverage` 的单一 progress 事件日志拆成有界恢复索引和分类型 evidence，并为单元测试发现的生产/测试代码问题及完成总结提供独立开发者文档。

**Architecture:** `SKILL.md` 拥有 evidence routing、恢复、问题收录和完成门；`issues-template.md` 与 `final-report-template.md` 只在首次代码问题和 `COMPLETE` 时加载。focused PowerShell contract 以正向 anchors 和 semantic mutations 禁止 progress 膨胀、issues 范围漂移、人工审查自判和 premature final report；README、AGENTS 与薄 command 对齐公共合同。

**Tech Stack:** Markdown Agent Skills、PowerShell 5 contract tests、Claude Code/Codex shared plugin runtime、Git。

## Global Constraints

- `issues.md` 只记录在单元测试执行、失败归因或补测中发现，并有可复现测试/源码证据的 `production-code` 或 `test-code` 问题。
- tooling、dependency、environment、CI、coverage config、普通 missing elements、批准等待、stale evidence、未知副作用和无测试证据建议不得进入 `issues.md`。
- `issues.md` 首个符合条件的问题出现时才创建；稳定 ID 为 `COV-ISSUE-NNN`；Agent 不得自行标记 `Developer review: REVIEWED`。
- `progress.md` 是有界、可更新的恢复索引，不是 append-only 全量事件日志或 completion authority。
- `contract.md` 保存稳定合同；`baselines/<run-id>.md`、`batches/<batch-id>.md`、`verifications/<run-id>.md` 保存详细 evidence。失败 run 使用新文件，不覆盖或删除。
- `final-report.md` 只在所有技术 predicate 已由 fresh verification 证明、流程仍处于 `FINAL_VERIFYING` completion boundary 时生成；核对其 fresh final verification 引用后才进入 `COMPLETE`，未完成状态不得生成伪 final report。
- coverage reports 继续直接写 `fp-docs/changes/<slug>-coverage/`，不改变 metric freeze、bootstrap、owner batch、双门或 CodeGraph 合同。
- 不修改插件版本，不 commit、不 push，不覆盖并行 module/final review 改动。
- `SKILL.md` 与每个模板都必须小于 500 行和 30,000 字符。

---

### Task 1: 锁定 evidence split 的失败合同

**Files:**
- Modify: `scripts/test-coverage-contract.ps1`
- Test: `scripts/test-coverage-contract.ps1`

**Interfaces:**
- Consumes: 当前 skill/command/docs。
- Produces: 对 evidence tree、issues scope/schema、bounded progress 和 final report timing 的 focused RED/GREEN gate。

- [ ] **Step 1: 添加资源与正向 anchors**

断言存在并读取：

```powershell
skills/fp-coverage/issues-template.md
skills/fp-coverage/final-report-template.md
```

skill anchors 至少包含：

```text
bounded recovery index
.fp-coverage/contract.md
.fp-coverage/baselines/<run-id>.md
.fp-coverage/batches/<batch-id>.md
.fp-coverage/verifications/<run-id>.md
unit-test-discovered-code-issues-only
production-code
test-code
COV-ISSUE-NNN
Developer review
final-report-only-at-completion-boundary
completion boundary
final_report_references_fresh_final_verification
```

- [ ] **Step 2: 添加 issues template schema checks**

要求模板包含：Category、Status、Blocking、Developer review、Severity、First seen、Last verified、Affected code、Observed/Expected/Actual、Reproduction、Code evidence、Related evidence、Impact、Recommended action、External issue、Disposition；状态包含 `OPEN | RESOLVED | EXTERNALIZED | ACCEPTED_RISK | INVALID`，review 包含 `PENDING | REVIEWED`。

- [ ] **Step 3: 添加 final report template checks**

要求 Result、Test results、Measurement contract、Work completed、Code issues discovered、Changed paths、Managed xfails、Side-effect reconciliation、Completion predicates、Remaining risks、Evidence index，并包含 final verification 引用字段。

- [ ] **Step 4: 添加 semantic mutations**

固定检测并测试以下反例：

```text
progress.md must append every command and full result forever.
issues.md may include dependency, environment, coverage config, and ordinary uncovered-line problems.
The agent may mark Developer review as REVIEWED after reproducing the issue.
Generate final-report.md while state is BLOCKED or CANNOT_VERIFY.
A final report may rely on a stale or local verification.
```

同时检查正确 skill 不触发 detector。

- [ ] **Step 5: 运行 focused RED**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-coverage-contract.ps1
```

Expected: FAIL，首先指出 template 缺失或 bounded evidence anchor 缺失，而不是 PowerShell 语法错误。

### Task 2: 实现 evidence routing 与模板

**Files:**
- Modify: `skills/fp-coverage/SKILL.md`
- Create: `skills/fp-coverage/issues-template.md`
- Create: `skills/fp-coverage/final-report-template.md`
- Modify: `commands/fp-coverage.md`
- Test: `scripts/test-coverage-contract.ps1`

**Interfaces:**
- Consumes: Task 1 RED 和设计规格。
- Produces: 主流程证据路由、问题台账形状、最终总结形状和薄入口 checksum。

- [ ] **Step 1: 替换 artifact tree 与 progress invariant**

将 artifact tree 改为 issues/final-report + `.fp-coverage/{progress,contract,baselines,batches,verifications}` + coverage reports。删除 `append-only progress` 合同，改为 `bounded recovery index`，只存 current state/fingerprints/contract revision/latest evidence/index/next action。

- [ ] **Step 2: 定义 evidence 文件职责和恢复读序**

`contract.md` 保存冻结合同和批准；baseline/batch/verification 文件保存详细精确证据且使用稳定 run/batch ID。恢复先读 progress，再只读直接引用的 contract、latest fresh evidence、active batch、issues，不批量加载历史。

- [ ] **Step 3: 定义 issues 收录、去重和人工状态**

加入 `unit-test-discovered-code-issues-only`：只收 production/test code；首问题懒创建；dedup key 为 category + affected symbol/path + normalized observed behavior + root cause；自动更新不得覆盖人工 review/disposition；blocking issue disposition 纳入 completion。

- [ ] **Step 4: 创建 issues template**

使用完整字段、固定状态和 `COV-ISSUE-NNN` 示例；明确 `Developer review: PENDING` 为默认，只有开发者明确审查才能设为 REVIEWED；误报改 `INVALID` 不删除。

- [ ] **Step 5: 创建 final report template**

覆盖目标/baseline/final/delta、测试计数、冻结合同、batches、issues 汇总、changed paths、xfails、side effects、predicates、remaining risks 和 evidence links；Result 固定引用 `.fp-coverage/verifications/<run-id>.md`。

- [ ] **Step 6: 增加 final report timing**

`final-report-only-at-completion-boundary`：技术 predicates 通过且仍处于 `FINAL_VERIFYING` 时生成并核对，随后才进入 `COMPLETE`；`BLOCKED`/`CANNOT_VERIFY`/中断不生成；生成后工作树/HEAD/config 变化使其 stale，重新 final verify 后重写。completion predicate 增加 blocking issue disposition 与 fresh final report reference。

- [ ] **Step 7: 压缩 command checksum**

在 20 行和共享字符预算内加入 split evidence 总括锚点；保留 bootstrap、metric、owner batch、双门和 sync anchors。

- [ ] **Step 8: 运行 focused test**

Expected: template/skill/command 相关断言通过；公共文档尚未更新时只因 README/AGENTS 失败。

### Task 3: 对齐 README 与 AGENTS

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`
- Test: `scripts/test-coverage-contract.ps1`

**Interfaces:**
- Consumes: Task 2 事实源。
- Produces: Claude/Codex 公共 artifact contract。

- [ ] **Step 1: 更新 README artifact tree 与说明**

展示 issues.md、final-report.md、bounded progress、contract/baselines/batches/verifications；说明 issues 只收 unit-test-discovered production/test code，final report 在 completion boundary 生成并核对后才进入 COMPLETE。

- [ ] **Step 2: 更新 AGENTS release behavior**

加入相同职责拆分、lazy recovery、人工 review 禁止自判和 completion timing，使 Markdown fallback 不再把所有内容写入 progress。

- [ ] **Step 3: focused GREEN**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-coverage-contract.ps1
```

Expected: `fp-coverage contract validation passed.`

- [ ] **Step 4: full validator**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
```

Expected: PASS；若 command budget 超限，只压缩本次 command 文案，不改动态预算或其他命令。

### Task 4: 行为压力测试、审查与部署

**Files:**
- Modify if RED reveals loophole: `scripts/test-coverage-contract.ps1`
- Modify minimally after RED: `skills/fp-coverage/SKILL.md` or templates

**Interfaces:**
- Consumes: 完整 split-evidence contract。
- Produces: 新项目和长流程下的有界恢复、开发者问题审查与最终总结证据。

- [ ] **Step 1: 压力测试长执行流程**

模拟 20 个 owner batches、多次 periodic baseline 和两次失败 final verification。Expected：progress 只含当前索引，不累积完整事件；详细 evidence 分文件；失败 verification 保留独立 run 文件。

- [ ] **Step 2: 压力测试 issue routing**

至少包含生产代码 bug、测试 assertion bug、缺 pytest-cov、coverage config 问题、普通 missing line、未知副作用。Expected：前两类进入 issues；其余进入 contract/evidence/progress blocker，不进入 issues；重复代码问题复用稳定 ID。

- [ ] **Step 3: 压力测试 final report**

BLOCKED/CANNOT_VERIFY 时不生成；COMPLETE 时生成并引用 fresh verification，列出 unresolved non-blocking pending developer review issues 和 remaining risks。

- [ ] **Step 4: 将新漏洞做 semantic RED/GREEN**

任何新 loophole 先加入 mutation 并观察 RED，再最小修复，不能只凭代理报告改文档。

- [ ] **Step 5: 独立审查**

Reviewer 只报告 Critical/Important，核对 issues 范围、人工状态、证据 immutability/lazy recovery、progress 有界性、final timing/freshness、template schema 和 public docs；修复后窄复核。

- [ ] **Step 6: fresh 验证**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\measure-context.ps1
```

```bash
claude plugin validate .
```

```bash
git diff --check
```

再运行 focused 和 full validator。Expected：全部 exit 0，文件预算通过。

- [ ] **Step 7: 同步运行时**

使用 `sync-plugin-runtimes` 正常模式与 `-VerifyOnly`；版本不变，repository/Codex source/cache/Claude cache hashes 一致。

- [ ] **Step 8: 最终状态检查**

`git status --short --untracked-files=all` 只允许已知共享改动与本计划文件，无临时 coverage/report/cache；不 commit、不 push。

## Self-Review

- Spec coverage：四个 task 覆盖 RED、evidence routing/templates、public docs、behavior/review/deployment。
- Placeholder scan：没有 TBD/TODO/未定义步骤。
- Naming consistency：统一使用 `issues.md`、`final-report.md`、`bounded recovery index`、`COV-ISSUE-NNN`、`final-report-only-at-completion-boundary
completion boundary`。
- Scope：不实现代码解析器或 issue tracker 集成，只规范 Markdown workflow 与模板，符合 YAGNI。
