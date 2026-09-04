# fp-coverage Coverage Tooling Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 `fp-coverage` 在新项目缺少 coverage 工具时提出可执行的批准门禁，并在用户批准后受控安装和配置工具链；Django 无既有 coverage 方案时推荐 `pytest + pytest-cov`。

**Architecture:** 保留 `fp-coverage` 的技术栈中立和 metric-freeze 主合同，在 `RESOLVING` 中增加 approval-gated `coverage-tooling-bootstrap` 子范围。`scripts/test-coverage-contract.ps1` 先以正向锚点和语义 mutation 锁定缺工具时的状态、推荐优先级、批准边界与 fresh-baseline 失效规则，再最小修改 skill、command、README 和 AGENTS 使合同转绿。

**Tech Stack:** Markdown Agent Skills、PowerShell 5 合同测试、Claude Code/Codex plugin runtime、Git。

## Global Constraints

- 优先复用项目现有 test runner、coverage 工具、包管理器和 CI 口径，不覆盖可用方案。
- 只有项目缺少 coverage 能力时才提出 bootstrap；Django fallback 为：已有 pytest 时推荐 `pytest-cov`，没有 pytest 时推荐 `pytest + pytest-cov`，`pytest-django` 仅按实际测试集成需要建议。
- 未经明确批准，不安装依赖、不改依赖声明、不写 coverage 配置；此时保持 `RESOLVING` + `CANNOT_VERIFY`，不进入 owner batch。
- 用户批准只授权已展示的 coverage 依赖、依赖声明和最小配置，不允许升级无关依赖。
- bootstrap 必须持久化到项目既有依赖声明，不能只改临时环境。
- bootstrap 后旧证据 stale，必须重新执行 fresh full baseline。
- coverage 原始数据、XML、HTML 和其他报告必须在执行前直接定向到 `fp-docs/changes/<slug>-coverage/`，禁止 run-then-move。
- 不修改插件版本，不 commit、不 push，不覆盖其他会话的 module/final review 变更。
- `skills/fp-coverage/SKILL.md` 继续满足 500 行和 30,000 字符硬上限。

---

### Task 1: 用语义合同锁定缺依赖引导

**Files:**
- Modify: `scripts/test-coverage-contract.ps1`
- Test: `scripts/test-coverage-contract.ps1`

**Interfaces:**
- Consumes: 当前 `skills/fp-coverage/SKILL.md`、`commands/fp-coverage.md`、`README.md`、`AGENTS.md`。
- Produces: 能拒绝终止型缺工具阻塞、无批准安装、Django 错误 fallback、临时环境安装和 bootstrap 后复用旧 baseline 的 focused contract。

- [ ] **Step 1: 添加正向合同锚点**

在 skill anchors 中加入以下精确术语：

```powershell
'coverage-tooling-bootstrap'
'approval gate'
'RESOLVING'
'CANNOT_VERIFY'
'prefer-existing-coverage-toolchain'
'Django'
'pytest-cov'
'pytest-django'
'persist dependency declaration'
'fresh baseline after bootstrap'
```

在 command、README 和 AGENTS 的断言中分别要求 `coverage-tooling-bootstrap` 或等价公开说明存在。

- [ ] **Step 2: 添加语义 mutation detectors**

新增以下 PowerShell 函数：

```powershell
function Test-TerminalMissingToolBlock([string]$text) {
    return $text -match '(?is)(?:missing|lacks?|without)[^\r\n.]{0,80}(?:coverage tool|coverage dependency)[^\r\n.]{0,120}(?:must|only|always)[^\r\n.]{0,40}(?:BLOCKED|stop)' \
        -and $text -notmatch '(?is)(?:recommend|proposal|approval gate|bootstrap)'
}

function Test-UnapprovedCoverageInstall([string]$text) {
    return $text -match '(?is)(?:may|can|should)[^\r\n.]{0,100}(?:install|add)[^\r\n.]{0,80}(?:coverage|pytest-cov)[^\r\n.]{0,100}(?:without|before)[^\r\n.]{0,40}(?:approval|consent)'
}

function Test-TemporaryOnlyBootstrap([string]$text) {
    return $text -match '(?is)(?:install|add)[^\r\n.]{0,100}(?:coverage|pytest-cov)[^\r\n.]{0,100}(?:environment only|without updating|do not update)[^\r\n.]{0,80}(?:requirements|dependency declaration|pyproject)'
}

function Test-ReuseBaselineAfterBootstrap([string]$text) {
    return $text -match '(?is)(?:after bootstrap|after installing)[^\r\n.]{0,120}(?:reuse|keep|retain)[^\r\n.]{0,80}(?:baseline|coverage evidence)'
}
```

加入固定 mutation fixtures，证明 detector 能捕获：缺工具只能 `BLOCKED`、未经批准安装、只改临时环境、安装后复用旧 baseline。

- [ ] **Step 3: 运行 focused test 验证 RED**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-coverage-contract.ps1
```

Expected: FAIL，原因是当前 skill 缺少 `coverage-tooling-bootstrap` 等新锚点或仍包含 `missing tooling is BLOCKED` 旧合同；不得因 PowerShell 语法错误失败。

### Task 2: 实现 approval-gated bootstrap 主合同

**Files:**
- Modify: `skills/fp-coverage/SKILL.md`
- Modify: `commands/fp-coverage.md`
- Test: `scripts/test-coverage-contract.ps1`

**Interfaces:**
- Consumes: Task 1 的 focused RED 合同和已确认设计规格。
- Produces: 缺工具识别、推荐、批准、安装、配置、重新 baseline 的完整执行合同。

- [ ] **Step 1: 修订不可协商原则与状态语义**

明确：

```text
missing coverage tooling + safe recommendation possible
=> state RESOLVING
=> coverage evidence CANNOT_VERIFY
=> show approval gate
=> do not enter owner batch
```

`BLOCKED` 只用于无法识别安全包管理命令、缺少用户批准、环境失败或无法安全恢复；“等待批准”本身表述为 approval gate，而不是终止型 blocker。

- [ ] **Step 2: 增加工具选择优先级**

使用精确锚点 `prefer-existing-coverage-toolchain`，顺序固定为：

```text
existing authoritative coverage tool/CI
-> coverage plugin matching existing runner
-> new runner + coverage combination only when no compatible runner exists
```

Django fallback 写成：已有 pytest 只补 `pytest-cov`；没有 pytest 推荐 `pytest + pytest-cov`；`pytest-django` 只在测试需要 Django pytest 集成时加入。不得覆盖现有 coverage.py、tox、nox、CI wrapper 或其他权威方案。

- [ ] **Step 3: 定义批准前展示 schema**

一次性展示并记录：项目/框架/runner/包管理器识别依据、缺失能力、推荐依赖及理由、精确安装命令、将修改的依赖/锁/配置文件、冻结的生产 source、baseline/final 命令、全部输出路径、失败恢复方式。

- [ ] **Step 4: 定义批准后最小授权**

增加 `coverage-tooling-bootstrap`：只允许使用现有包管理器安装已批准依赖，`persist dependency declaration` 到项目既有依赖文件，并写最小 coverage 配置。禁止无关升级、临时环境-only 安装和隐式工具替换。

- [ ] **Step 5: 定义 freshness 和输出规则**

依赖或配置写入立即使旧证据 stale；记录新指纹并执行 `fresh baseline after bootstrap`。所有 coverage 原始数据和报告必须直接写入 coverage change root；pytest-cov 示例包含 XML、HTML 及 `.coverage` 数据位置，不硬编码生产 source。

- [ ] **Step 6: 更新薄 command checksum**

在 20 行限制内加入：

```text
- 缺工具：`RESOLVING` + `CANNOT_VERIFY` + approval-gated `coverage-tooling-bootstrap`。
```

保留 metric-freeze、owner batch、final 双门、no-production-write 和 post-write-sync。

- [ ] **Step 7: 运行 focused test**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-coverage-contract.ps1
```

Expected: skill/command 断言通过；如果公共文档断言尚未满足，失败必须指向 README 或 AGENTS。

### Task 3: 对齐公共文档与双运行时 fallback

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`
- Test: `scripts/test-coverage-contract.ps1`

**Interfaces:**
- Consumes: Task 2 的 skill 事实源。
- Produces: Claude Code 与 Codex 都能得出相同缺依赖引导，不把 pytest+pytest-cov 误写成所有技术栈默认值。

- [ ] **Step 1: 更新 README 核心技能与使用流程**

补充：新项目缺少 coverage 工具时先展示受控 bootstrap；Django 无既有方案时推荐 `pytest + pytest-cov`；用户批准后才安装、持久化依赖和配置，并立即重新 fresh baseline。

- [ ] **Step 2: 更新 AGENTS release behavior**

加入相同的 fallback 优先级、批准边界、依赖声明持久化和 fresh-baseline 规则，使未安装插件时的 Markdown fallback 不会复现终止型 `BLOCKED`。

- [ ] **Step 3: 运行 focused test 验证 GREEN**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-coverage-contract.ps1
```

Expected: PASS，输出 `fp-coverage contract validation passed.`。

- [ ] **Step 4: 运行完整插件验证**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
```

Expected: PASS，所有 focused contract validators 和结构预算通过。

### Task 4: 压力复测、独立复审与运行时同步

**Files:**
- Modify if a new failing mutation is found: `scripts/test-coverage-contract.ps1`
- Modify if required by that test: `skills/fp-coverage/SKILL.md`

**Interfaces:**
- Consumes: 完整 bootstrap 合同。
- Produces: 用户示例场景不再卡死、无安全边界回退，以及本地 Claude Code/Codex 一致运行时证据。

- [ ] **Step 1: 运行缺工具压力场景**

验证 Django + pytest + 无 coverage 工具、测试结果 `54 collected / 36 passed / 18 strict xfailed / exit 0` 的场景。Expected：状态为 `RESOLVING`、coverage 为 `CANNOT_VERIFY`；推荐 `pytest-cov`（不重复推荐 pytest），展示依赖文件/命令/source/报告路径，等待批准；不进入 owner batch，不宣告 coverage baseline 或 COMPLETE。

- [ ] **Step 2: 运行反向边界场景**

至少验证：已有权威 coverage.py/CI 时不推荐 pytest-cov；非 Django 项目不硬编码 pytest；用户未批准时不安装；批准后不升级其他包；安装成功后不复用旧 baseline；安装失败不宽泛恢复工作树。

- [ ] **Step 3: 对新漏洞执行 RED/GREEN**

若压力场景发现新 loophole，先加入固定 semantic mutation 并运行 focused RED，再最小修改 skill 使 GREEN；不得只改措辞而不加回归合同。

- [ ] **Step 4: 独立代码审查**

请求 reviewer 核对：终止型阻塞是否消除、批准边界是否可执行、Django fallback 是否只在无既有方案时触发、PowerShell mutation 是否能识别相反语义、公共文档是否一致。修复所有 Critical/Important 后重新验证。

- [ ] **Step 5: 验证预算、格式和插件结构**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\measure-context.ps1
```

```bash
claude plugin validate .
```

```bash
git diff --check
```

Expected: context/文件硬限制通过、plugin validation 成功、无 whitespace error。

- [ ] **Step 6: 同步本地插件运行时**

调用 `sync-plugin-runtimes` skill，以不变版本执行 cache refresh，并验证 repository、Codex source/cache、Claude cache 中的 `fp-coverage` 文件一致。不得提交仓库。

- [ ] **Step 7: 最终 fresh 回归**

依次重新运行 focused contract、`validate-plugin.ps1`、`git diff --check`，并检查 `git status --short`。Expected：所有命令退出 0；状态中允许保留本会话和其他会话已知未提交文件，不允许出现临时报告、测试 fixture 或运行时缓存。

## Self-Review

- Spec coverage：Task 1 锁定缺工具状态与反例；Task 2 覆盖选择、批准、安装、持久化、freshness 和输出；Task 3 覆盖双入口文档；Task 4 覆盖行为、复审和部署。
- Placeholder scan：没有 `TBD`、`TODO`、`implement later` 或未定义步骤。
- Naming consistency：全计划统一使用 `coverage-tooling-bootstrap`、`prefer-existing-coverage-toolchain`、`RESOLVING`、`CANNOT_VERIFY` 和 `fresh baseline after bootstrap`。
- Scope：不新增通用 installer 或 coverage parser；实现只扩展现有 Markdown workflow 和 PowerShell contract，符合 YAGNI。
