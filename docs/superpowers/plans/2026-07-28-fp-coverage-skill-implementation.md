# fp-coverage Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增技术栈中立的 `fp-coverage` skill，让 FeaturePilot 能以统一、可恢复且不可通过口径漂移作弊的流程提高单元测试覆盖率。

**Architecture:** 使用一个自包含的 `skills/fp-coverage/SKILL.md` 拥有阶段、证据、恢复和完成合同；`commands/fp-coverage.md` 仅作 Claude Code 薄适配器；`scripts/test-coverage-contract.ps1` 通过静态正例和防退化负例锁定关键纪律。README、AGENTS 与 `validate-plugin.ps1` 负责双运行时发现和持续验证，不引入 coverage 解析器或技术栈依赖。

**Tech Stack:** Markdown Agent Skills、PowerShell 合同测试、Claude Code plugin manifest、Codex shared skills、Git。

## Global Constraints

- skill 名称固定为 `fp-coverage`，公开入口固定为 `/fp-coverage` 和 `fp:fp-coverage`。
- 不硬编码 pytest/Jest/JaCoCo/Go cover/coverlet、80% 或任何客户路径。
- 不新增依赖，不更改插件版本，不提交或推送。
- `SKILL.md` 不超过 500 行或 30,000 字符，frontmatter 只有 `name` 和 `description`。
- source/include/omit/exclude/branch/metric 在 baseline 前冻结；coverage-only 流程不得为了达标修改。
- 完成必须同时满足正式命令退出码 0 和精确 coverage 达标，且证据匹配当前 HEAD/工作树。
- 过程文档叙述默认中文，精确技术标识保留英文。

---

### Task 1: 锁定失败合同

**Files:**
- Create: `scripts/test-coverage-contract.ps1`

**Interfaces:**
- Consumes: `skills/fp-coverage/SKILL.md`、`commands/fp-coverage.md`、`README.md`、`AGENTS.md`。
- Produces: 退出码 0/1 的 focused validator，供 `validate-plugin.ps1` 调用。

- [ ] **Step 1: 创建 focused test**

实现 PowerShell helper `Read-Utf8`、`Assert-Condition` 和字符串锚点检查。测试必须在 skill 尚不存在时因 `skills/fp-coverage/SKILL.md is missing` 失败，并覆盖：双入口、workspace contract、metric freeze、fresh baseline、failure triage、owner batch、periodic full refresh、exact numerator/denominator、exit-code/coverage 双门、stale fingerprint、strict xfail/issue、protected path reconciliation、progress 非 completion authority、CodeGraph dirty/post-write、公共文档锚点。

- [ ] **Step 2: 运行 focused test 验证 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-coverage-contract.ps1
```

Expected: FAIL，首个错误明确指出 `skills/fp-coverage/SKILL.md` 缺失，而不是 PowerShell 语法错误。

- [ ] **Step 3: 保持测试不变进入实现**

记录 RED 输出；后续只通过新增 skill/command/docs 和 validator wiring 使测试转绿，不削弱断言。

### Task 2: 实现 skill 与命令入口

**Files:**
- Create: `skills/fp-coverage/SKILL.md`
- Create: `commands/fp-coverage.md`

**Interfaces:**
- Consumes: `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md`，按需消费 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/codegraph.md`。
- Produces: Claude `/fp-coverage` 与 Codex `fp:fp-coverage` 的同一流程合同。

- [ ] **Step 1: 写 skill frontmatter 和触发边界**

使用：

```yaml
---
name: fp-coverage
description: Use when a user asks to raise unit-test, line, branch, statement, or combined coverage to a target, close coverage gaps, establish a coverage gate, or resume an interrupted coverage-improvement effort.
---
```

正文先加载 anchored workspace contract，并说明 missing resource、Codex path mapping、项目根和 manifest read order。

- [ ] **Step 2: 写阶段和状态合同**

加入 `RESOLVING`、`BASELINING`、`TRIAGING`、`ITERATING`、`FINAL_VERIFYING`、`BLOCKED`、`COMPLETE`；固定流程为 metric freeze、command safety、fresh baseline、failure triage、gap ranking、owner batch、periodic full refresh、final gate、reconciliation。

- [ ] **Step 3: 写 coverage change 产物与恢复合同**

定义唯一 `fp-docs/changes/<slug>-coverage/` 根：`fp-docs/changes/<slug>-coverage/.fp-coverage/progress.md` 使用 append-only schema，记录 HEAD/worktree/config fingerprint、命令、exit code、精确 numerator/denominator、测试计数、owner batch、diff、issue/xfail 和 freshness；`coverage.xml`、`htmlcov/` 与其他 coverage 工具报告也必须写在该根目录，不能写项目根。明确 ledger 不是第二 completion authority，测试源码和批准 fixture 仍在项目既有测试路径。

- [ ] **Step 4: 写完成门与反作弊规则**

加入 exact completion predicate，禁止扩大 omit/exclude、缩小 source/include、关闭 branch、换 metric、批量 skip/xfail、strict false、弱断言、stale/局部/估算 final proof 和宽泛 Git 恢复。

- [ ] **Step 5: 写 CodeGraph 生命周期**

调查阶段遵守 MCP → CLI → 原有搜索；首次写测试/fixture/config 后标记 `dirty-after-write`，禁止继续查询旧图；返回前对开始时已有图最多一次 non-blocking post-write sync。

- [ ] **Step 6: 写薄 command adapter**

`commands/fp-coverage.md` 不超过 20 行，加载 anchored skill 并在 Gate checksum 重述 metric freeze、批次证据、final 双门、no production/config cheating 和 recovery ledger 边界。

- [ ] **Step 7: 运行 focused test**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-coverage-contract.ps1
```

Expected: 可能仍因公共文档或 validate wiring 缺失而 FAIL，但 skill/command 相关断言通过。

### Task 3: 接入公共文档和全量验证

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: Task 1 validator 和 Task 2 skill/command。
- Produces: Claude/Codex 发现入口以及主 validator 自动执行。

- [ ] **Step 1: 更新 README**

在核心命令表加入 `commands/fp-coverage.md`；核心技能加入 `fp-coverage`；低成本 flow/示例中说明它是独立覆盖率专项，冻结现有统计口径并以 fresh full-suite exit 0 + exact coverage 为完成门。

- [ ] **Step 2: 更新 AGENTS intent routing**

加入“raise unit-test/line/branch/combined coverage or resume coverage effort → `skills/fp-coverage/SKILL.md`”；将 post-write CodeGraph sync 列表加入 `fp-coverage`。

- [ ] **Step 3: 接入 validate-plugin**

在 focused validators 区域添加：

```powershell
$coverageContractValidator = Join-Path $root 'scripts\test-coverage-contract.ps1'
Assert-Condition (Test-Path $coverageContractValidator) 'focused fp-coverage contract validator is missing'
& powershell -NoProfile -ExecutionPolicy Bypass -File $coverageContractValidator
Assert-Condition ($LASTEXITCODE -eq 0) 'focused fp-coverage contract validator failed'
```

- [ ] **Step 4: 运行 focused test 验证 GREEN**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-coverage-contract.ps1
```

Expected: PASS，输出 `fp-coverage contract validation passed.`。

- [ ] **Step 5: 运行完整插件验证**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
```

Expected: PASS，且内部 focused validators 全部通过。

### Task 4: 压力复测、收口和部署验证

**Files:**
- Modify if needed: `skills/fp-coverage/SKILL.md`
- Modify if needed: `scripts/test-coverage-contract.ps1`

**Interfaces:**
- Consumes: 完整 skill 合同。
- Produces: 对高压覆盖率场景的一致响应和本地插件运行时同步证据。

- [ ] **Step 1: 用相同压力类型运行有 skill 场景**

至少验证：coverage 达标但命令非零；历史/局部证据代替 full gate；负责人要求扩大 omit/关闭 branch/批量 non-strict xfail；测试改写受保护路径且原状态未知；未知技术栈不得硬编码命令。

Expected: 每个样本都输出固定状态、证据缺口、禁止动作、最小下一步；不得宣告完成。

- [ ] **Step 2: 将新 rationalization 转成明确规则和负例**

若样本出现新的口径漂移、弱断言、stale proof 或宽泛恢复措辞，先在 focused test 加失败断言，观察 RED，再最小修改 skill 使 GREEN。

- [ ] **Step 3: 检查文件约束和上下文**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\measure-context.ps1
```

Expected: PASS；新 `SKILL.md` 小于 500 行和 30,000 字符。

- [ ] **Step 4: 验证 Claude plugin**

Run:

```bash
claude plugin validate .
```

Expected: 插件结构验证成功。

- [ ] **Step 5: 检查 diff 格式和状态**

Run:

```bash
git diff --check
```

Expected: 无 whitespace error。

Run:

```bash
git status --short
```

Expected: 只有本计划声明的新增/修改文件；无临时测试或运行时缓存。

- [ ] **Step 6: 同步本地插件运行时**

使用 `sync-plugin-runtimes` skill。Expected: Claude Code 和 Codex 本地运行时均包含相同 `fp-coverage` skill；版本不变时仍完成 cache refresh/安装验证。

- [ ] **Step 7: 最终回归**

再次运行 focused test、`validate-plugin.ps1` 和 `git diff --check`。Expected: 全部 PASS，且同步没有改写仓库业务文件。

## Self-Review

- Spec coverage：四个任务覆盖 RED、skill/command、文档/validator、压力复测/部署，无遗漏。
- Placeholder scan：没有 `TBD`、`TODO`、`implement later` 或未定义接口。
- Type consistency：本实现无程序类型；路径、skill 名称、validator 变量和完成 predicate 在所有任务中一致。
- Scope：只有一个公开 skill，不引入解析器、版本发布或 Git 提交，符合 YAGNI。
