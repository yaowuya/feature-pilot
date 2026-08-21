# UI/E2E Staged Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将已确认的 UI/E2E 原生分阶段契约接入 FeaturePilot 的规划、两种执行模式、终审和归档，并用插件级 PowerShell 契约测试阻止回归。

**Architecture:** 新建唯一的 `skills/_shared/ui-e2e-contract.md`，让 Figma、前端计划、直接执行、SDD 执行、终审和归档共同读取。每个已计划 UI Case 先完成静态视觉，再完成交互和零 mock 的真实前端 E2E；终审与归档从 Case manifest、E2E evidence 和覆盖矩阵回查，不依赖聊天结论。

**Tech Stack:** Markdown Agent Skills、PowerShell 5 契约测试、客户选择的既有 runner / browser extension / 本机 `playwright-cli`、Git。

---

## File structure

| Path | Action | Responsibility |
| --- | --- | --- |
| `skills/_shared/ui-e2e-contract.md` | Create | UI Case 级别、状态机、零 mock、真实 E2E、覆盖矩阵和客户选择浏览器能力的唯一规则来源。 |
| `skills/fp-figma/SKILL.md` | Modify | 将设计源和 Visual Checks 交给后续 UI/E2E 契约。 |
| `skills/fp-plan-frontend/SKILL.md` | Modify | 要求每个视觉 Case 选择交付级别并计划 E2E 覆盖。 |
| `skills/fp-plan-frontend/plan-template.md` | Modify | 增加独立的 UI/E2E Delivery Contract 表，不改变既有视觉表的列。 |
| `skills/fp-execute/SKILL.md` | Modify | 直接执行模式的静态、视觉复核、交互、E2E 阶段门禁。 |
| `skills/fp-execute-sdd/SKILL.md` | Modify | SDD 模式的 stage dispatch、回退和完成条件。 |
| `skills/fp-execute-sdd/{task-brief-template,implementer-prompt,task-reviewer-prompt,review-package-template,fix-prompt,e2e-verifier-prompt}.md` | Modify/Create | 传递阶段、证据、零 mock 规则和 fresh E2E verifier 输出。 |
| `skills/fp-final-review/{SKILL,final-reviewer,final-review-template,final-review-package-template}.md` | Modify | 对每个 UI Case 强制回查 E2E 和覆盖矩阵。 |
| `skills/fp-archive/SKILL.md` | Modify | 禁止确认绕过未通过的核心 UI/E2E Gate。 |
| `scripts/test-ui-e2e-contract.ps1` | Create | 新共享契约、状态、零 mock、覆盖、终审和归档的 focused regression test。 |
| `scripts/test-figma-evidence-contract.ps1` | Modify | 保留客户选择的浏览器能力、禁止静默安装与 runner 中立性。 |
| `scripts/test-final-review-contract.ps1` | Modify | 锁定最终审查的 UI/E2E 硬门禁。 |
| `scripts/validate-plugin.ps1` | Modify | 运行新的 focused UI/E2E 契约测试。 |
| `README.md`, `AGENTS.md` | Modify | 对齐插件公开流程和 Markdown fallback 规则。 |

## Global constraints

- 不新增用户可见 command；用户仍从 `fp-execute` 或 `fp-execute-sdd` 进入。
- 既有 Visual Evidence Manifest 的列和 source/runtime provenance 保持不变；UI/E2E 字段放在独立 section，避免破坏已有 canonical table。
- `interactive` 与 `business-flow` 的真实前端 E2E 禁止任何 mock、stub、fixture JSON、route/intercept、mock module、store 注入、localStorage 伪造业务数据和数据库 seed。
- 视觉证据的稳定非敏感 fixture 与真实 E2E 数据严格分离，不能互相替代。
- 没有 E2E runner 时必须进入 `BROWSER_CAPABILITY_GATE`：优先复用 existing runner / extension / local CLI；三者缺失时仅在客户选择并批准后才按展示的精确全局命令使用 local CLI，绝不修改项目依赖、lockfile、配置、CI 或浏览器组件。
- 每个仍在范围内但无法在真实环境安全触发的边界条件必须写为 `blocked`，不能伪装为 `N/A` 或 `PASS_WITH_NOTES`。
- 所有修改后的 `SKILL.md` 保持在 500 行和 30,000 字符以内；不修改插件版本。

### Task 1: 建立共享规则与 focused RED/GREEN 测试

**Files:**
- Create: `scripts/test-ui-e2e-contract.ps1`
- Create: `skills/_shared/ui-e2e-contract.md`

**Interfaces:**
- Consumes: `docs/superpowers/specs/2026-08-10-ui-e2e-staged-contract-design.md`。
- Produces: 可被所有入口引用的唯一 UI/E2E 规则和可独立运行的 PowerShell baseline test。

- [ ] **Step 1: 写入最小的 failing contract test**

创建 `scripts/test-ui-e2e-contract.ps1`，使用仓库既有的 `Read-Utf8`、`Assert-Condition` 和 failure-list 风格。先只要求共享文件存在，并要求下列锚点同时出现：

```powershell
$sharedPath = Join-Path $root 'skills\_shared\ui-e2e-contract.md'
Assert-Condition (Test-Path $sharedPath) 'shared UI/E2E contract is missing'
$shared = if (Test-Path $sharedPath) { Read-Utf8 $sharedPath } else { '' }
Assert-Anchors $shared @(
    'UI Delivery Level', 'static-only', 'interactive', 'business-flow',
    'SOURCE_READY', 'STATIC_UI_READY', 'VISUAL_REVIEW_PASS',
    'INTERACTION_READY', 'FRONTEND_E2E_PASS',
    'E2E Applicability: REQUIRED | N/A',
    'Mocked Core API: false', 'BROWSER_CAPABILITY_GATE', 'playwright-cli',
    'coverage-matrix.md', 'BLOCKED'
) 'shared UI/E2E contract'
```

- [ ] **Step 2: 运行 focused RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-ui-e2e-contract.ps1
```

Expected: FAIL，包含 `shared UI/E2E contract is missing`，而不是 PowerShell 语法错误。

- [ ] **Step 3: 创建共享契约**

创建 `skills/_shared/ui-e2e-contract.md`，按以下固定 section 顺序写入：

```text
# FeaturePilot UI/E2E Staged Contract
## Applicability and UI Delivery Level
## Required State Machine
## Case Manifest and E2E Evidence
## Real Frontend E2E: No Mock Data or Requests
## Coverage Matrix
## Browser capability gate
## Retry, Blocking, Final Review, and Archive
```

规则必须明确：`static-only` 只有视觉通过且有范围依据才能使用 `N/A`；`interactive` 和 `business-flow` 都要求真实浏览器 E2E；业务链路额外要求真实核心 API、`Mocked Core API: false`、持久化/权限结果和真实清理。列举并禁止 `page.route`、`route.fulfill`、MSW、Cypress stub/intercept、fixture JSON、mock module、store/localStorage 注入、硬编码接口数据、数据库 seed，以及绕过正常页面流程的直接 backend/API 写入。异常路径只允许由真实环境条件触发，无法安全触发的在 coverage matrix 中为 `blocked`。

- [ ] **Step 4: 定义项目内 Playwright bootstrap**

在共享契约中规定：优先复用 existing project runner、已安装 browser extension 或本机已有 `playwright-cli`。三者缺失时进入 `BROWSER_CAPABILITY_GATE`，展示精确命令与影响；客户自行执行或一次性明确授权后才能执行全局 local CLI 安装。不得创建或改写项目依赖、lockfile、配置、CI 或浏览器组件；无获批准可用能力时为 `BLOCKED`。

- [ ] **Step 5: 运行 focused GREEN**

Run the same command from Step 2.

Expected: `UI/E2E contract validation passed.`

- [ ] **Step 6: 提交共享基础**

```bash
git add skills/_shared/ui-e2e-contract.md scripts/test-ui-e2e-contract.ps1
git commit -m "feat: add shared UI E2E contract"
```

### Task 2: 将 Figma 和前端计划接入 UI/E2E 契约

**Files:**
- Modify: `skills/fp-figma/SKILL.md`
- Modify: `skills/fp-plan-frontend/SKILL.md`
- Modify: `skills/fp-plan-frontend/plan-template.md`
- Modify: `scripts/test-ui-e2e-contract.ps1`
- Modify: `scripts/test-figma-evidence-contract.ps1`

**Interfaces:**
- Consumes: 共享契约、现有 Visual Evidence Manifest。
- Produces: 可执行 UI Case 的交付级别、E2E evidence root 和覆盖矩阵计划。

- [ ] **Step 1: 扩展 focused test 并确认 RED**

让 `test-ui-e2e-contract.ps1` 读取三个 planning surface，并要求它们都锚定 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/ui-e2e-contract.md`；计划模板必须包含标题 `### 2.6 UI/E2E Delivery Contract`、`UI Delivery Level`、`E2E Applicability`、`Coverage Matrix`、`E2E Evidence root`、`Mocked Core API` 和 `Playwright bootstrap`。

Run the focused test. Expected: FAIL，逐一列出尚未接入的 Figma/plan surface。

- [ ] **Step 2: 修改 Figma handoff 规则**

在 `fp-figma` 的 shared-resource 读取段加入 UI/E2E contract。保留它只负责可信设计源、节点、Visual Checks 和组件映射；增加 handoff 说明：后续计划必须为每个设计驱动 UI Case 选择 delivery level，Figma/static source 不能替代真实 E2E 证据，也不能生成或认可 mock E2E 数据。

- [ ] **Step 3: 修改前端计划规则和模板**

在 `fp-plan-frontend/SKILL.md` 加入共享契约读取、case 分类和覆盖要求。模板保留既有 `### 2.5 Visual Evidence Manifest` 表原样，紧接着增加 `### 2.6 UI/E2E Delivery Contract`，使用以下列：

```markdown
| Case ID | UI Delivery Level | E2E Applicability | Real runtime route/state | E2E scenarios and boundary categories | Coverage Matrix | E2E Evidence root | Core API mode | Mocked Core API | Playwright bootstrap | Completion Gate |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
```

规则要求每行唯一对应一个 Visual Case：`static-only` 必须写 `N/A` 理由；`interactive` 和 `business-flow` 写 `REQUIRED`；`business-flow` 固定 `real` / `false`；覆盖矩阵路径为 `.fp-execute/e2e/<task-id>/<case-id>/coverage-matrix.md`，证据根为 `.fp-execute/e2e/<task-id>/<case-id>/`。

- [ ] **Step 4: 更新既有视觉契约测试的 runner 预期**

在 `test-figma-evidence-contract.ps1` 中保留 `do not silently install`、`explicit task` 与 `authorization` anchors，并要求 existing project runner、browser extension、local `playwright-cli`、`BROWSER_CAPABILITY_GATE`、客户选择和无项目依赖/配置改写。保留 `Test-PublicNeutrality` 对具体包管理器命令、客户 URL、存储路径和生产数据 fixture 的拒绝；不要在公共规则中硬编码 `npm`、`pnpm`、`yarn` 或 `npx` 命令。

- [ ] **Step 5: 运行 planning GREEN**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-ui-e2e-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-figma-evidence-contract.ps1
```

Expected: 两个测试均输出 `passed`，且既有 Visual Evidence Manifest canonical table 未改变。

- [ ] **Step 6: 提交 planning integration**

```bash
git add skills/fp-figma/SKILL.md skills/fp-plan-frontend/SKILL.md skills/fp-plan-frontend/plan-template.md scripts/test-ui-e2e-contract.ps1 scripts/test-figma-evidence-contract.ps1
git commit -m "feat: plan staged UI E2E delivery"
```

### Task 3: 在直接执行模式加入阶段门禁

**Files:**
- Modify: `skills/fp-execute/SKILL.md`
- Modify: `scripts/test-ui-e2e-contract.ps1`

**Interfaces:**
- Consumes: 前端计划的 UI/E2E Delivery Contract 和共享状态机。
- Produces: direct mode 中每个 UI Case 的阶段记录、真实 E2E evidence 和准确 blocker。

- [ ] **Step 1: 扩展 direct-mode test 并确认 RED**

让 focused test 断言 `fp-execute` 读取共享契约，并包含 `STATIC_UI_READY`、`VISUAL_REVIEW_PASS`、`INTERACTION_READY`、`FRONTEND_E2E_PASS`、`direct-read-only`、`E2E N/A Reason`、自动 Playwright bootstrap 和 `BLOCKED`。

Run the focused test. Expected: FAIL，只报告 direct execution surface 缺少的 anchors。

- [ ] **Step 2: 修改 pre-flight 和进度账本**

在 `fp-execute` 的 anchored-resource 读取段加入共享契约。Pre-flight 对每个 planned UI Case 校验 delivery level、coverage matrix 路径、E2E applicability 和业务 Case 的 `real`/`false` 声明。将 progress 记录扩展为每个 UI Case 的 `Gate State`、视觉复核证据、E2E evidence root、coverage matrix 和 blocker；强调 checkbox 仍是完成 authority，ledger 只保存恢复证据。

- [ ] **Step 3: 替换直接执行的 UI Case 流程**

在既有 TDD 流程后增加固定顺序：静态 UI 与 `current.png` → 不改文件的 `direct-read-only` 视觉复核 → 交互/API 实现 → 真实浏览器 E2E → 更新 checkbox/ledger。视觉未通过不得开始交互；required E2E 没有项目 runner 输出不得完成；E2E 失败只回到交互/API 阶段；`static-only` 必须记录 `E2E N/A Reason`。

- [ ] **Step 4: 加入真实数据和安装处理**

直接执行规则引用共享零 mock contract，并要求在实际运行前检查目标项目 runner。runner 缺失时自动执行共享契约的 Playwright bootstrap；安装的 package/lock/config 路径加入当前任务 Files 和 ledger。真实环境、账号、可清理数据或真实异常条件缺失时记录已尝试命令和 `BLOCKED`，绝不使用 mock 继续。

- [ ] **Step 5: 运行 direct GREEN 并提交**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-ui-e2e-contract.ps1
git diff --check
git add skills/fp-execute/SKILL.md scripts/test-ui-e2e-contract.ps1
git commit -m "feat: gate direct UI execution with real E2E"
```

Expected: focused test and whitespace check exit 0；commit 只包含 direct execution 与其 focused test。

### Task 4: 在 SDD 执行模式加入静态、视觉、交互和 E2E 阶段

**Files:**
- Modify: `skills/fp-execute-sdd/SKILL.md`
- Modify: `skills/fp-execute-sdd/task-brief-template.md`
- Modify: `skills/fp-execute-sdd/implementer-prompt.md`
- Modify: `skills/fp-execute-sdd/task-reviewer-prompt.md`
- Modify: `skills/fp-execute-sdd/review-package-template.md`
- Modify: `skills/fp-execute-sdd/fix-prompt.md`
- Create: `skills/fp-execute-sdd/e2e-verifier-prompt.md`
- Modify: `scripts/test-ui-e2e-contract.ps1`

**Interfaces:**
- Consumes: 同一 task 的 UI Delivery Contract、视觉 evidence、coverage matrix。
- Produces: fresh static implementer/visual reviewer/interaction implementer/E2E verifier 的可追溯 stage evidence。

- [ ] **Step 1: 扩展 SDD focused test 并确认 RED**

让 focused test 要求 SDD skill、brief、implementer、review package、reviewer、fix prompt 和新 verifier prompt 都读取或引用共享契约。测试必须要求 `Execution Stage: static-ui | interaction-api`、`UI-VisualReviewer`、`UI-E2EVerifier`、`FRONTEND_E2E_PASS`、`Mocked Core API: false`、`coverage-matrix.md`、三次上限和未通过时 `BLOCKED`。

Run the focused test. Expected: FAIL，指出每个尚未改造的 SDD surface。

- [ ] **Step 2: 改造 SDD controller state machine**

在 `fp-execute-sdd/SKILL.md` 加入共享契约读取及 UI task 的四阶段 dispatch：fresh static implementer 只能交付静态 UI；fresh `UI-VisualReviewer` 只读比较证据；只有视觉 PASS 后才 dispatch fresh interaction/API implementer；最后 dispatch fresh `UI-E2EVerifier`，仅运行项目 runner、审查 coverage matrix 和写 E2E report。UI task 的 checkbox 只能在 required E2E PASS 后更新。

- [ ] **Step 3: 改造 task brief、implementer 与 package**

brief 增加 `Execution Stage`、Case delivery table、E2E evidence root、coverage matrix、真实环境/账号/清理约束和 bootstrap 记录。implementer prompt 禁止在 `static-ui` stage 修改交互/API 行为，禁止所有 mock；`interaction-api` stage 必须保留 visual PASS 并实现真实数据链路。review package 按 stage 记录 manifest、视觉 verdict、E2E 证据/缺失原因和 stage-specific diff。

- [ ] **Step 4: 改造 reviewer、fixer 与 E2E verifier**

task reviewer 在静态阶段只发 `Visual evidence: PASS | FAIL | CANNOT_VERIFY`；在 interaction/API 阶段检查代码是否保持真实数据边界。fix prompt 明确修复不能清空既有 Gate History，也不能把 required E2E 改成 `N/A`。新 `e2e-verifier-prompt.md` 必须只读业务代码、运行项目配置的真实浏览器 E2E、拒绝 mock/fixture/stub/intercept/seed、核对 coverage matrix 的每个 `covered`/`N/A`/`blocked` 项，并在 `.fp-execute/reviews/<task-id>-e2e.md` 输出 `PASS | FAIL | BLOCKED` 与实际产物路径。

- [ ] **Step 5: 运行 SDD GREEN 并提交**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-ui-e2e-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-figma-evidence-contract.ps1
git diff --check
```

Expected: 两个 focused contract test 与 whitespace check 通过。

```bash
git add skills/fp-execute-sdd scripts/test-ui-e2e-contract.ps1
git commit -m "feat: stage SDD UI delivery and E2E verification"
```

### Task 5: 把 UI/E2E Gate 接入最终审查和归档

**Files:**
- Modify: `skills/fp-final-review/SKILL.md`
- Modify: `skills/fp-final-review/final-reviewer.md`
- Modify: `skills/fp-final-review/final-review-template.md`
- Modify: `skills/fp-final-review/final-review-package-template.md`
- Modify: `skills/fp-archive/SKILL.md`
- Modify: `scripts/test-ui-e2e-contract.ps1`
- Modify: `scripts/test-final-review-contract.ps1`

**Interfaces:**
- Consumes: Case manifest、E2E report、coverage matrix、task owner checkbox 和最终 review package。
- Produces: 无法被 `PASS_WITH_NOTES` 或归档确认绕过的最终 UI/E2E 决定。

- [ ] **Step 1: 扩展 final-gate tests 并确认 RED**

让 `test-ui-e2e-contract.ps1` 要求终审/归档均引用共享契约；让 `test-final-review-contract.ps1` 要求 final skill、reviewer、report template 和 package template 都包含 `UI/E2E Evidence`、`FRONTEND_E2E_PASS`、`Mocked Core API: false`、`coverage matrix`、`PASS_WITH_NOTES` 不可绕过 core E2E、以及 `static-only` 的合法 `N/A` 条件。

Run both tests. Expected: FAIL，只缺 final-review/archive anchors。

- [ ] **Step 2: 修改终审 skill 与 reviewer**

在 `fp-final-review/SKILL.md` 增加 `UI/E2E Evidence Gate`：逐 Case 回读 delivery level、Gate History、visual evidence、E2E runner output、coverage matrix、真实 API mode 和 mock flag。要求 `interactive`/`business-flow` 的 `FRONTEND_E2E_PASS`；`business-flow` 还要求真实持久化/权限结果；对 core E2E 缺口、任何 mock 或仍在范围内的 `blocked` 覆盖项输出 `FAIL` 或 `BLOCKED`，绝不能输出 `PASS_WITH_NOTES`。

- [ ] **Step 3: 修改 final package 和 report schema**

在两个 final template 增加 `## UI/E2E Evidence`。每个 Case 记录 delivery level、Gate State、visual verdict、E2E applicability/reason、runner/runtime/scenario、coverage matrix、real/mock mode、真实数据生命周期/权限证明、结果、产物路径和 blocker。复用现有 Scope Matrix，不为 E2E 创建第二个完成 authority。

- [ ] **Step 4: 修改归档 hard gate**

在 `fp-archive` 的归档前检查增加：先解析所有 planned UI Case；只有 `static-only` 合法 `N/A` 或 required E2E 有 `FRONTEND_E2E_PASS` 才能继续。普通未完成任务仍可按现有规则展示确认，但核心 UI/E2E 失败、缺证据、mock 或 coverage `blocked` 不提供确认绕过路径。

- [ ] **Step 5: 运行 final-gate GREEN 并提交**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-ui-e2e-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-final-review-contract.ps1
git diff --check
```

Expected: 三个命令均 exit 0。

```bash
git add skills/fp-final-review skills/fp-archive/SKILL.md scripts/test-ui-e2e-contract.ps1 scripts/test-final-review-contract.ps1
git commit -m "feat: enforce UI E2E final and archive gates"
```

### Task 6: 接入全局校验并同步公开说明

**Files:**
- Modify: `scripts/validate-plugin.ps1`
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `scripts/test-ui-e2e-contract.ps1`

**Interfaces:**
- Consumes: 已完成的 shared/plan/execute/review/archive contracts。
- Produces: 全量验证入口和与实际行为一致的用户/Markdown fallback 文档。

- [ ] **Step 1: 将 focused test 接入全量验证器**

在 `validate-plugin.ps1` 的 focused validator block 中按现有 `Test-Path`、PowerShell invocation、`$LASTEXITCODE` 三步模式加入 `scripts\test-ui-e2e-contract.ps1`。错误文本固定为 `focused UI/E2E contract validator is missing` 和 `focused UI/E2E contract validator failed`。

- [ ] **Step 2: 更新 README 和 AGENTS**

README 的执行/终审说明增加：视觉任务按静态→视觉复核→交互→真实前端 E2E 收口；缺 runner 自动 bootstrap Playwright；`interactive`/`business-flow` 零 mock；E2E 覆盖不局限主流程。根 `AGENTS.md` 的 1.0.0 release behavior 增加相同的执行、终审和归档硬门禁，明确 `static-only` 合法 `N/A` 的限制。

- [ ] **Step 3: 添加 semantic mutation tests**

在 `test-ui-e2e-contract.ps1` 使用内存 mutation 验证以下反例均被拒绝：

```text
E2E Result: SKIPPED
Mocked Core API: true
page.route may simulate a backend response
fixture JSON may supply E2E business data
direct API write may prepare E2E business data
blocked coverage may become PASS_WITH_NOTES
archive may continue after missing FRONTEND_E2E_PASS
```

同时对未改动的真实 shared contract 运行相同 helper，确认不会 false positive。

- [ ] **Step 4: 运行完整 GREEN**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-ui-e2e-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-figma-evidence-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-final-review-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
```

Expected: 每个 focused test 输出 `passed`，全量校验输出 `FeaturePilot plugin validation passed`。

- [ ] **Step 5: 提交公开合同与验证接入**

```bash
git add scripts/validate-plugin.ps1 scripts/test-ui-e2e-contract.ps1 README.md AGENTS.md
git commit -m "docs: document staged UI E2E delivery"
```

### Task 7: 执行后自审与交付验证

**Files:**
- Modify only if a named focused test exposes a contract gap: the minimal owning skill, template, or test script.

**Interfaces:**
- Consumes: 所有提交后的 plugin source 和测试结果。
- Produces: 可重复、无 mock 漏洞、无未跟踪证据文件的交付快照。

- [ ] **Step 1: 按设计逐项回查覆盖**

将设计第 2–10 节分别映射到 Task 1–6：共享规则、等级状态、case evidence、零 mock、异常/边界覆盖、bootstrap、两种执行模式、终审归档和 mutation tests。发现无 owner 的设计要求时，先为该要求补充 focused RED，再最小修复。

- [ ] **Step 2: 审查文件预算和公开中立性**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
```

Expected: validator 同时确认所有 `SKILL.md` 低于 500 行、所有 focused contracts 通过，并未在公共规则中写死包管理器、URL、账号、存储路径或生产数据。

- [ ] **Step 3: 检查 Git 交付状态**

```bash
git diff --check
git status --short --untracked-files=all
git log --oneline -6
```

Expected: whitespace check 无输出；工作树没有临时 Playwright、trace、screenshot、coverage 或 cache 产物；最近提交按共享契约、planning、direct、SDD、final/archive、docs/validator 的逻辑顺序可追溯。

## Self-review

- Spec coverage：Task 1–6 分别覆盖共享契约、Figma/计划、两种执行模式、终审/归档、自动 Playwright、零 mock、完整边界 coverage 和插件级回归测试。
- Placeholder scan：没有占位标记、未命名文件或“按需处理”步骤；所有新增/修改文件和验证命令均已列出。
- Consistency：统一使用 `UI Delivery Level`、`FRONTEND_E2E_PASS`、`E2E Applicability`、`Mocked Core API: false`、`coverage-matrix.md` 与 `.fp-execute/e2e/<task-id>/<case-id>/`。
- Scope：不复制 SDD-RIPER CLI/签名运行时，不新增用户命令，不改变业务项目代码；仅让 FeaturePilot 的现有入口贯彻已批准的门禁。
