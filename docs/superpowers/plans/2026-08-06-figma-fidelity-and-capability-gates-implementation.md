# Figma 还原质量门禁 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 `fp-figma` 从“读取设计并修改 UI”升级为具备 Figma-only 视觉来源、浏览器验证能力选择、既有功能保护、原子能力追踪和独立审查结论的可复跑质量闭环。

**Architecture:** 以 `skills/fp-figma/` 的确定性模板承载 preservation、capability ledger 和只读审查报告；`fp-figma` 负责 source/capability/preservation/review 状态机并在直接 UI 改造中执行门禁。前端计划与 SDD/最终审查消费同一套 `FIGCAP-*`、`PRES-*` 与既有 Visual Evidence manifest，使任务级和变更级验收均无法把代码编辑或静态控件误判为功能、保护或视觉完成。

**Tech Stack:** Markdown FeaturePilot skills/commands/templates、PowerShell focused contract/mutation tests、项目已配置 browser runner 或已发现的 Playwright 浏览器扩展 / 本机全局 `@playwright/cli`。

## Global Constraints

- 有可信 Figma UI 设计时，Figma 是唯一 UI/视觉/布局/呈现设计源；原型不得参与该范围的 UI 还原判断。
- 无可信 Figma UI 设计时，原型仅为 `FUNCTION_SCOPE_ONLY`；视觉还原结论固定 `CANNOT_VERIFY`。
- 当前真实代码、已有测试及真实浏览器行为仅用于保护既有功能，不得反向替代 Figma 的目标视觉。
- 先复用已确认的项目 browser runner、Playwright 浏览器扩展或本机 `playwright-cli`；不得静默安装、替换客户工具链、修改项目依赖/lockfile/CI 或安装浏览器组件。
- 缺浏览器能力时必须让客户选择安装浏览器扩展、全局安装 `@playwright/cli`（客户自行执行或仅在展示精确命令后逐次授权执行）、或不安装；选择不安装时不得宣称视觉验收或 Figma 还原完成。
- `reference.png` 仅来自 Figma/approved static design source；`current.png` 仅来自稳定真实目标运行时；交互证据与截图证据必须分离。
- 既有行为没有客户明确例外时不得因 Figma 未呈现而删除、隐藏或更改语义；基线/重放失败为 `FAIL`，无法验证为 `CANNOT_VERIFY`。
- 每个 `FIGCAP-NNN` 必须有目标来源、Figma 呈现（有 Figma 时）、代码/任务归属和真实可观察验证；静态控件存在不等于能力通过。
- 实现者不能批准自己的 Figma 改造；独立只读审查必须输出 `PASS`、`FAIL`、`CANNOT_VERIFY` 或 `BLOCKED`。
- 只有所有必需 `FIGCAP-*`、核心 `PRES-*` 和核心 Visual Case 都为 `PASS`，且无未批准范围外行为变化时，才允许声明 `COMPLETE` 或“Figma 改造完成”。
- 所有 FeaturePilot 文档叙述使用中文；保留精确路径、命令、包名、状态值与 schema 字段英文。
- 不创建或修复项目级 `fp-docs/manifest.md` / settings；无安全可判定的 active change 时要求客户指定归属。

---

## File Structure

| Path | Action | Responsibility |
| --- | --- | --- |
| `commands/fp-figma.md` | Modify | 在薄命令适配器的 Gate checksum 声明 Figma-only、保留行为与浏览器能力选择门禁。 |
| `skills/fp-figma/SKILL.md` | Modify | 定义完整 source gate、browser capability gate、preservation/capability preflight、直接实现与独立 review 状态机。 |
| `skills/fp-figma/figma-preservation-template.md` | Create | 统一 `figma-preservation.md` 的范围、允许变更、保护行为、基线/重放证据与客户例外格式。 |
| `skills/fp-figma/figma-capabilities-template.md` | Create | 统一 `figma-capabilities.md` 的 `FIGCAP-*` 原子能力账本及预检/完成规则。 |
| `skills/fp-figma/figma-review-template.md` | Create | 统一独立只读 Figma review 的输入、双向覆盖审查、证据、Finding 与结论格式。 |
| `skills/fp-plan-frontend/SKILL.md` | Modify | 将 `FIGCAP-*`、`PRES-*`、browser capability 选择及完成语义纳入前端计划输入、自审和无效计划规则。 |
| `skills/fp-plan-frontend/plan-template.md` | Modify | 在计划产物加入 capability/preservation contracts、coverage mapping 和任务验证字段。 |
| `skills/fp-execute-sdd/SKILL.md` | Modify | 将 Figma 账本与保护证据纳入 task brief/package/review，并把它们作为 UI task 的 combined pass 条件。 |
| `skills/fp-execute-sdd/task-brief-template.md` | Modify | 将 relevant `FIGCAP-*`、`PRES-*` 和 browser capability resolution 传给 implementer。 |
| `skills/fp-execute-sdd/implementer-prompt.md` | Modify | 要求 implementer 重放能力/保护 case，禁止将代码改动或截图单独报告为完成。 |
| `skills/fp-execute-sdd/review-package-template.md` | Modify | 将 preservation/capability evidence 与 visual evidence 一起打包给只读 reviewer。 |
| `skills/fp-execute-sdd/task-reviewer-prompt.md` | Modify | 让独立 reviewer 对 `FIGCAP-*`、`PRES-*`、Visual Case 做三维结论并阻止伪完成。 |
| `skills/fp-final-review/SKILL.md` | Modify | 将 Figma preservation/capability artifacts 纳入 required reads、coverage table 和完成判定。 |
| `skills/fp-final-review/final-review-template.md` | Modify | 持久化 browser/source resolution、能力/保护覆盖和分维度 Figma 完成结论。 |
| `scripts/test-figma-evidence-contract.ps1` | Modify | 以 focused anchors 和 mutation fixtures 锁定新增门禁与跨模板传递。 |
| `README.md` | Modify | 将用户可见能力描述从单一截图证据升级为 Figma 还原质量闭环。 |

## Task 1: 为 Figma 质量门禁建立红色契约测试

**Files:**
- Modify: `scripts/test-figma-evidence-contract.ps1`
- Test: `scripts/test-figma-evidence-contract.ps1`

**Interfaces:**
- Consumes: `skills/fp-figma/SKILL.md`、三个尚待创建的 `skills/fp-figma/*-template.md`、frontend plan、SDD templates、final-review templates 与 `commands/fp-figma.md` 的 UTF-8 文本。
- Produces: focused PowerShell validator；它对每个新增跨文件契约输出稳定的失效消息，并仍由 `scripts/validate-plugin.ps1` 既有调用路径执行。

- [ ] **Step 1: 在 focused validator 中先写失败的新增 contract assertions**

在既有 `$figma = Read-Utf8 ...` 读取块旁，新增确定性的输入读取：

```powershell
$figmaCommand = Read-Utf8 'commands\fp-figma.md'
$preservationTemplate = Read-Utf8 'skills\fp-figma\figma-preservation-template.md'
$capabilitiesTemplate = Read-Utf8 'skills\fp-figma\figma-capabilities-template.md'
$figmaReviewTemplate = Read-Utf8 'skills\fp-figma\figma-review-template.md'
$finalReview = Read-Utf8 'skills\fp-final-review\SKILL.md'
```

紧随原有 `Assert-Anchors $figma ...` 增加四组断言，消息必须稳定且可被 mutation fixtures 验证：

```powershell
Assert-Anchors $figma @(
    'Figma UI 设计（唯一来源）',
    'FUNCTION_SCOPE_ONLY',
    'BROWSER_CAPABILITY_GATE',
    'Playwright 浏览器扩展',
    '@playwright/cli',
    '不得静默安装',
    'figma-preservation.md',
    'figma-capabilities.md',
    'FIGCAP-',
    'PRES-',
    '独立只读审查',
    'Figma 改造完成'
) 'fp-figma quality gates'

Assert-Anchors $figmaCommand @(
    'Figma UI 设计是唯一 UI 参考',
    '既有功能保护',
    '浏览器验证能力'
) 'fp-figma command quality checksum'

Assert-Anchors $preservationTemplate @(
    '# Figma Preservation Contract',
    'PRES-NNN',
    '允许变更',
    '保护行为',
    '修改前基线',
    '修改后重放',
    '客户明确批准的例外',
    'CANNOT_VERIFY'
) 'figma preservation template'

Assert-Anchors $capabilitiesTemplate @(
    '# Figma Capability Ledger',
    'FIGCAP-NNN',
    '原子能力与验收结果',
    'Figma 节点 / Frame / Variant',
    '浏览器操作证据',
    '静态控件存在不等于能力通过',
    'MISSING',
    'PARTIAL'
) 'figma capabilities template'
```

再为 review template、frontend planner、SDD implementer/reviewer/package、final reviewer 建立 anchor 断言。每一层必须出现完整的语义：`FIGCAP-*`、`PRES-*`、`PASS | FAIL | CANNOT_VERIFY | BLOCKED`、`实现者不能批准自己的` 或等价独立 read-only 审查、以及“不得宣称完成”的收敛规则。

- [ ] **Step 2: 运行 focused validator，确认它因新增模板/规则尚不存在而失败**

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-figma-evidence-contract.ps1
```

Expected: 非零退出，且错误含 `figma-preservation-template.md` 路径缺失或 `fp-figma quality gates lost visual-evidence anchor`；不得修改任何 skill 来让该失败被跳过。

- [ ] **Step 3: 为关键负向规则编写内存 mutation fixtures**

在 `# Mutation fixtures operate only in memory` 之后增加以下 mutation 模式；所有 mutation 都只能改变本地字符串，不得写入磁盘：

```powershell
$prototypeAsUiSource = Replace-Required $figma `
    '原型 = 禁止作为 UI 视觉、布局、呈现或还原判断的参考' `
    '原型 = 可作为 UI 视觉、布局、呈现或还原判断的参考' `
    'prototype becomes an allowed UI reference'
Assert-Condition (
    -not (Test-ContainsAnchors $prototypeAsUiSource @(
        '原型 = 禁止作为 UI 视觉、布局、呈现或还原判断的参考'
    ))
) 'mutation survived: prototype may become a Figma UI reference'

$implicitInstall = Replace-Required $figma '不得静默安装' '可自动安装' 'silent browser install'
Assert-Condition (
    -not (Test-ContainsAnchors $implicitInstall @('不得静默安装'))
) 'mutation survived: browser capability may install silently'

$prematureComplete = Replace-Required $figma '所有必需 FIGCAP-* = PASS' '任意 FIGCAP-* = PASS' 'partial capability completion'
Assert-Condition (
    -not (Test-ContainsAnchors $prematureComplete @('所有必需 FIGCAP-* = PASS'))
) 'mutation survived: partial capability completion may claim complete'
```

增加一个跨层 mutation：从 `$taskReviewer` 删除 `PRES-*`，从 `$finalReview` 删除 `figma-capabilities.md`，并断言各自的必需 anchor 检查失败。这样防止规则只停留在 `fp-figma` 而没有传到执行/最终审查。

- [ ] **Step 4: 运行 focused validator，确认红色 mutation baseline 仍稳定**

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-figma-evidence-contract.ps1
```

Expected: 仍然失败在生产文本缺少新规则/模板；不应出现 `Invalid mutation fixture`，这证明 fixture 命中了当前生产字符串而不是无效文本。

- [ ] **Step 5: Commit 红色契约测试**

```bash
git add scripts/test-figma-evidence-contract.ps1
git commit -m "test: define figma quality gate contract"
```

Expected: commit 只包含 focused Figma contract test 改动；此时仓库总体验证可以失败，原因必须是尚未实现的新增 contract。

## Task 2: 创建 Figma 质量工件模板并实现直接 `fp-figma` 门禁

**Files:**
- Create: `skills/fp-figma/figma-preservation-template.md`
- Create: `skills/fp-figma/figma-capabilities-template.md`
- Create: `skills/fp-figma/figma-review-template.md`
- Modify: `skills/fp-figma/SKILL.md:18-65`
- Modify: `commands/fp-figma.md:6-10`
- Test: `scripts/test-figma-evidence-contract.ps1`

**Interfaces:**
- Consumes: 用户提供的 Figma node/source、当前代码与既有可复跑验证、已确认 PRD/proposal/当前指令、当前 active change path、browser capability resolution。
- Produces: `.fp-execute/figma-preservation.md`、`.fp-execute/figma-capabilities.md`、`.fp-execute/reviews/<timestamp>-figma-review.md`；每项以 `PRES-NNN`、`FIGCAP-NNN`、Visual Case 关联，但不创建项目级信息层或把原型混入有 Figma 的 UI 来源。

- [ ] **Step 1: 创建 preservation 模板，先定义既有功能保护的唯一 owner**

创建 `skills/fp-figma/figma-preservation-template.md`，使用下面的完整结构：

```markdown
# Figma Preservation Contract

- Change: `<slug>`
- Figma scope: `<file/page/node IDs and frame/variant>`
- Current-code baseline revision: `<HEAD or explicit baseline>`
- UI design source: `Figma only | no trustworthy Figma UI design`
- Prototype usage: `PROHIBITED_AS_UI_REFERENCE | FUNCTION_SCOPE_ONLY`

## Allowed Changes

| Change ID | Allowed UI/behavior change | Source approval | Affected route/component/files |
| --- | --- | --- | --- |
| `ALLOW-001` | `<Figma-explicit visual/layout/token/responsive change>` | `<Figma node or explicit customer approval>` | `<exact paths>` |

## Protected Behaviors

| Preservation ID | Existing observable behavior | Current-code/test evidence | Stable fixture and precondition | Before-baseline command/result | After-replay command/result | Approved exception | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `PRES-001` | `<user action -> externally observable result>` | `<path:line/test>` | `<non-sensitive stable state>` | `<PASS/CANNOT_VERIFY evidence>` | `<PASS/FAIL/CANNOT_VERIFY evidence>` | `None` | `PENDING` |

## Customer-Approved Exceptions

| Exception ID | Changed or removed behavior | Explicit customer approval | Affected `PRES-*` | Result |
| --- | --- | --- | --- | --- |
| `EXC-001` | `<behavior>` | `<verbatim decision/reference>` | `PRES-001` | `APPROVED` |

## Rules

- Figma 未呈现既有行为不等于允许删除、隐藏或改变其语义。
- 有可信 Figma UI 设计时，原型不得作为 UI 视觉、布局、呈现或还原判断的参考。
- 没有可信 Figma UI 设计时，原型只能是 `FUNCTION_SCOPE_ONLY`，不能使视觉还原结论通过。
- 所有核心 `PRES-*` 必须在相同 fixture、路由、用户状态、viewport、locale 和 theme 下重放。
- 任意核心 `PRES-*` 为 `FAIL` 或 `CANNOT_VERIFY` 时，Figma 改造不得为 `COMPLETE`。
```

- [ ] **Step 2: 创建 capability ledger 模板，禁止静态 UI 冒充功能完成**

创建 `skills/fp-figma/figma-capabilities-template.md`，写入以下完整 schema 和规则：

```markdown
# Figma Capability Ledger

- Change: `<slug>`
- UI design source: `Figma only | no trustworthy Figma UI design`
- Prototype usage: `PROHIBITED_AS_UI_REFERENCE | FUNCTION_SCOPE_ONLY`

## Capability Ledger

| Capability ID | 原子能力与验收结果 | 目标功能来源 | Figma 节点 / Frame / Variant | 当前代码基线 | 实现任务 / 文件 | Preservation Case | 浏览器操作证据 | Visual Case | 验证结果 | 状态 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `FIGCAP-001` | `<actor/action/state -> observable result>` | `<PRD/proposal/current explicit instruction>` | `<node/frame/variant or N/A>` | `<path:line/test or N/A>` | `<task ID/path>` | `<PRES-NNN or N/A>` | `<replay command/artifact>` | `<case ID or N/A>` | `<exact result>` | `PENDING` |

## Preflight

| Check | Required result | Status | Evidence / blocker |
| --- | --- | --- | --- |
| Every required capability has an implementation owner | one task/file for every `FIGCAP-*` | `PASS | BLOCKED` | `<owner or gap>` |
| Every key Figma state has a behavior owner | component/variant/empty/error/permission/confirmation state maps to `FIGCAP-*` | `PASS | BLOCKED` | `<mapping or question>` |
| Existing behavior absent from Figma is preserved | mapped to `PRES-*` unless an approved exception exists | `PASS | BLOCKED` | `<PRES-* or EXC-*>` |

## Completion Rules

- 静态控件存在不等于能力通过。
- `FIGCAP-*` 只有在真实运行态达到可观察验收结果后才可标记 `PASS`。
- `MISSING`、`PARTIAL`、`FAIL`、`CANNOT_VERIFY` 或 `BLOCKED` 的必需能力均阻止总体 `COMPLETE`。
- 有可信 Figma UI 设计时，Figma 是唯一 UI 呈现来源；原型不得填入 Figma node、Visual Case 或视觉验收理由。
```

- [ ] **Step 3: 创建独立 read-only Figma review 模板**

创建 `skills/fp-figma/figma-review-template.md`，令它明确要求新的 reviewer context，不得由 implementer 自审批准：

```markdown
# Figma Review: `<slug>`

- Reviewer: `independent read-only reviewer`
- Reviewed code revision: `<SHA>`
- Figma source/node/revision/frame/variant: `<evidence>`
- Browser capability: `project runner | Playwright browser extension | local playwright-cli | unavailable`
- Overall result: `PASS | FAIL | CANNOT_VERIFY | BLOCKED`

## Source and Capability Gate

| Gate | Result | Evidence |
| --- | --- | --- |
| Figma-only UI source respected | `PASS | FAIL | CANNOT_VERIFY | BLOCKED` | `<node/source and prototype exclusion>` |
| Browser capability resolution | `PASS | FAIL | CANNOT_VERIFY | BLOCKED` | `<reuse/customer choice/command authorization>` |
| Reference/runtime provenance | `PASS | FAIL | CANNOT_VERIFY | BLOCKED` | `<reference/current paths>` |

## Preservation Review

| Preservation ID | Before baseline | After replay | Approved exception | Result | Evidence |
| --- | --- | --- | --- | --- | --- |
| `PRES-001` | `<result>` | `<result>` | `None | EXC-NNN` | `PASS | FAIL | CANNOT_VERIFY | BLOCKED` | `<paths/commands>` |

## Capability Review

| Capability ID | Source and task/file mapping | Runtime observable result | Visual Case | Result | Evidence |
| --- | --- | --- | --- | --- | --- |
| `FIGCAP-001` | `<mapping>` | `<browser result>` | `<case or N/A>` | `PASS | FAIL | CANNOT_VERIFY | BLOCKED` | `<paths/commands>` |

## Visual Review

| Case ID | Figma node/variant | Reference/current/diff | Browser interaction evidence | Acceptance rule | Result |
| --- | --- | --- | --- | --- | --- |
| `VIS-001` | `<node>` | `<paths>` | `<replay evidence>` | `<case-specific rule>` | `PASS | FAIL | CANNOT_VERIFY` |

## Findings

| Finding ID | Severity | Requirement | Evidence | Failure scenario | Required fix |
| --- | --- | --- | --- | --- | --- |
| `FIGREV-001` | `Critical | Important | Minor` | `<FIGCAP/PRES/Visual Case>` | `<path:line/command>` | `<concrete state>` | `<direction>` |

## Completion Decision

- Code editing: `DONE | PARTIAL | NOT_STARTED`
- Capability completion: `PASS | FAIL | CANNOT_VERIFY | BLOCKED`
- Preservation: `PASS | FAIL | CANNOT_VERIFY | BLOCKED`
- Figma visual fidelity: `PASS | FAIL | CANNOT_VERIFY | BLOCKED`
- Overall: `COMPLETE | INCOMPLETE | BLOCKED`

Only `PASS` for every required `FIGCAP-*`, core `PRES-*`, and core Visual Case, with no unapproved behavioral change, permits “Figma 改造完成”.
```

- [ ] **Step 4: 重写 `fp-figma` 的规则和执行步骤，接入状态机与选择式 browser gate**

在 `skills/fp-figma/SKILL.md` 中保留现有 artifact-layout 与 Figma evidence rules，新增以下四个明确标题：`## Design-source precedence`、`## Browser capability gate`、`## Existing-function preservation and capability preflight`、`## Direct implementation and independent review`。

`Design-source precedence` 必须原样包含：

```text
有可信 Figma UI 设计时，Figma UI 设计（唯一来源）决定 UI 视觉、布局、尺寸、token、状态表现和交互呈现；当前真实代码与已有验证只作为既有功能保护基线；原型 = 禁止作为 UI 视觉、布局、呈现或还原判断的参考。

没有可信 Figma UI 设计时，原型 = FUNCTION_SCOPE_ONLY；视觉还原 = CANNOT_VERIFY。不得把原型降级为像素级视觉来源。
```

`Browser capability gate` 必须按顺序探测并复用 `项目已有 browser runner`、`Playwright 浏览器扩展`、`本机已有 playwright-cli`。三者均不可用时，在不写入任何环境前展示 A/B/C 客户选择；B 的精确包名为 `@playwright/cli`，分成“仅展示命令，客户自行执行”和“展示本次精确命令/影响/回滚边界后，等待客户明确授权执行”。明确 `不得静默安装`，客户选择 C 时停留 `CANNOT_VERIFY`，不得宣称完成。

`Existing-function preservation and capability preflight` 要求：在任何业务 UI 写入前，若存在 active change，加载三个新模板并创建 `.fp-execute/figma-preservation.md` 与 `.fp-execute/figma-capabilities.md`；若没有可安全确定的 change，询问用户选择 slug，不得在根目录散写证据。先完成 `PRES-*` 基线、`FIGCAP-*` 预检；任何没有 owner 的必需能力或不明状态为 `BLOCKED`。

`Direct implementation and independent review` 将原有第 5–7 步替换为顺序状态机：

```text
RESOLVING -> DESIGN_SOURCE_GATE -> BROWSER_CAPABILITY_GATE -> PRESERVATION_BASELINE -> CAPABILITY_PREFLIGHT -> IMPLEMENTING -> INDEPENDENT_REVIEW -> COMPLETE | INCOMPLETE | BLOCKED
```

要求实现者只做写入/验证；随后由 fresh independent read-only reviewer 用 `figma-review-template.md` 在 `.fp-execute/reviews/<timestamp>-figma-review.md` 写结论。核心 `PRES-*`、`FIGCAP-*`、Visual Case 任一非 `PASS` 时不得称“Figma 改造完成”；只可如实区分 `代码编辑`、`功能能力`、`既有功能保护`、`Figma 视觉还原` 和 `总体`。

- [ ] **Step 5: 更新 command 的 Gate checksum，使入口无法绕过核心约束**

将 `commands/fp-figma.md` 的 three bullets 改成不超过 20 行的四个 checksum bullets，至少精确出现：

```markdown
- 有可信 Figma UI 设计时，Figma UI 设计是唯一 UI 参考；原型不得参与视觉还原，当前代码只作为既有功能基线。
- 在业务 UI 写入前建立 `PRES-*` 保护契约与 `FIGCAP-*` 能力账本；未批准行为不得因 Figma 未呈现而删除。
- 复用现有 browser runner、Playwright 浏览器扩展或本机 `playwright-cli`；缺能力时由客户选择，不得静默安装。
- 只有独立只读审查确认核心能力、保护与视觉 case 全部 `PASS`，才可称 Figma 改造完成。
```

- [ ] **Step 6: 运行 focused contract test，使新增约束首次变绿**

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-figma-evidence-contract.ps1
```

Expected: `Figma evidence contract validation passed.`；同时所有新增 mutation fixture 都通过，说明删除 Figma-only、静默安装禁令、PRES/FIGCAP 传递或完整完成规则会立即被拒绝。

- [ ] **Step 7: Commit Figma skill、模板和入口**

```bash
git add commands/fp-figma.md skills/fp-figma/SKILL.md skills/fp-figma/figma-preservation-template.md skills/fp-figma/figma-capabilities-template.md skills/fp-figma/figma-review-template.md scripts/test-figma-evidence-contract.ps1
git commit -m "feat: gate figma fidelity and preservation"
```

Expected: commit 将直接 `/fp-figma` 的实施后审查闭环和模板作为一个可验证单元落地。

## Task 3: 使前端规划与 SDD 任务审查传递能力、保护和视觉门禁

**Files:**
- Modify: `skills/fp-plan-frontend/SKILL.md:70-120`
- Modify: `skills/fp-plan-frontend/plan-template.md:18-125`
- Modify: `skills/fp-execute-sdd/SKILL.md:234-373`
- Modify: `skills/fp-execute-sdd/task-brief-template.md:64-127`
- Modify: `skills/fp-execute-sdd/implementer-prompt.md:38-102`
- Modify: `skills/fp-execute-sdd/review-package-template.md`
- Modify: `skills/fp-execute-sdd/task-reviewer-prompt.md:32-145`
- Test: `scripts/test-figma-evidence-contract.ps1`

**Interfaces:**
- Consumes: `figma-preservation.md` 的 `PRES-NNN`、`figma-capabilities.md` 的 `FIGCAP-NNN` 和既有 Visual Evidence Manifest；无该工件时明确 `N/A` 或 block，不得凭空产生能力通过。
- Produces: 每个 frontend task 唯一拥有的 capability/preservation/visual verification mapping、implementer evidence、review package 和 reviewer verdict；combined task pass 不会覆盖任何必需的能力/保护非通过。

- [ ] **Step 1: 在 frontend planner 中定义可消费工件和规划失败条件**

在 `skills/fp-plan-frontend/SKILL.md` 的 Inputs 增加：

```markdown
- `fp-docs/changes/<slug>/.fp-execute/figma-capabilities.md` when the approved UI scope originated from `fp-figma`
- `fp-docs/changes/<slug>/.fp-execute/figma-preservation.md` when the approved UI scope modifies existing behavior
```

紧接 planning rules 增加：

```markdown
- Every required `FIGCAP-*` maps to exactly one frontend task or an explicit backend dependency; a visual control alone never satisfies it.
- Every required `PRES-*` maps to the task that may affect the behavior and declares before/after replay evidence.
- A Figma-derived plan carries `Figma only` as the visual source. Prototype is `FUNCTION_SCOPE_ONLY` only when no trustworthy Figma UI design exists; in that mode Visual Evidence is `CANNOT_VERIFY` rather than `PASS`.
- Browser capability resolution is a plan fact: reuse project runner, Playwright browser extension, or local `playwright-cli`; absence produces the customer-choice gate, never an implicit install task.
```

在 Self-review 增加两个编号检查：所有必需 `FIGCAP-*` 与 `PRES-*` 都有唯一 task owner/verification；没有 Figma 时没有 task 可把视觉判为 PASS。

- [ ] **Step 2: 扩展 frontend plan template，以真实映射替代泛化的视觉检查**

在 `plan-template.md` 的 `## 1. Page goal and visual contract` 后添加以下 section：

```markdown
## 1.1 Figma source and browser capability resolution

- UI design source: `Figma only | no trustworthy Figma UI design`
- Prototype usage: `PROHIBITED_AS_UI_REFERENCE | FUNCTION_SCOPE_ONLY`
- Browser capability: `project runner | Playwright browser extension | local playwright-cli | customer choice pending | unavailable`
- Completion vocabulary: Visual evidence is `CANNOT_VERIFY` when no trustworthy Figma UI source or real-runtime case evidence exists.

## 1.2 Capability and preservation mapping

| Capability / Preservation ID | Required observable result | Owner task | Runtime replay / visual case | Completion rule |
| --- | --- | --- | --- | --- |
| `FIGCAP-001` | `<result from capability ledger>` | `frontend-NNN` | `<browser replay and VIS-NNN>` | `PASS only after observable runtime result` |
| `PRES-001` | `<existing behavior from preservation contract>` | `frontend-NNN` | `<before/after replay>` | `PASS only when non-exception behavior is preserved` |
```

在每个 Task 的 `Interfaces` 后添加字段：

```markdown
**Capability / Preservation Ownership:**
- `FIGCAP-*`: `<exact IDs or None>`
- `PRES-*`: `<exact IDs or None>`
- Browser replay: `<exact case-specific command/tool or CANNOT_VERIFY reason>`
```

将 Coverage Matrix 的表头改为 `| Source | Requirement / capability / preservation / visual boundary | Tasks | Verification |`，令 planner 为 PRD/design/Figma 状态、`FIGCAP-*` 和 `PRES-*` 写独立行。

- [ ] **Step 3: 在 SDD brief、implementer report 和 package 中传递工件，而不是只传 Visual Case**

在 `task-brief-template.md` 的 Design Context 后添加：

```markdown
## Figma Capability and Preservation Context (when applicable)

- Capability ledger: `<path or N/A>`
- Preservation contract: `<path or N/A>`
- Required `FIGCAP-*`: `<exact IDs or None>`
- Required `PRES-*`: `<exact IDs or None>`
- Browser capability resolution: `<reused runner/extension/local CLI/customer choice/unavailable>`
- UI source rule: `Figma only | no trustworthy Figma UI design; prototype FUNCTION_SCOPE_ONLY`
```

在 Required Evidence 增加三行：每个 `FIGCAP-*` 的 browser-visible result、每个 `PRES-*` 的 before/after replay result、当前总体不能宣称 `COMPLETE` 的非 PASS 条件。

在 `implementer-prompt.md` 的 Implementation Contract 中，紧接视觉 case replay 后加入：

```text
For each required FIGCAP-* and PRES-* in the brief, collect the declared runtime replay evidence. A rendered control, handler, screenshot, or changed file alone is not PASS. Do not mark the Figma change COMPLETE; report code-editing, capability, preservation, and visual results separately.
```

在其 report format 的 Visual Evidence 前增加 `## Capability and Preservation Evidence` 两张表，列分别为 `ID | Required observable result | Replay command/result | Status | Evidence` 与 `ID | Before baseline | After replay | Approved exception | Status | Evidence`。

在 `review-package-template.md` 紧接 Visual Evidence Manifest section 增加同样两张表并附 source paths，确保 reviewer 不须从聊天补猜 required IDs。

- [ ] **Step 4: 将 task reviewer 的独立审查扩展为三维非替代结论**

在 `task-reviewer-prompt.md` Review Method 的 visual steps 后加入：

```text
For every required FIGCAP-*, verify task/file mapping and a real browser-observable result; a static control is insufficient. For every required PRES-*, compare the before baseline and after replay under the declared stable conditions. Figma only governs UI presentation when trustworthy Figma design exists; prototype must not be used as a visual substitute. Report Capability completion and Preservation verdicts separately from Visual evidence.
```

在 Required Output Format 的 Frontend Visual Review 之前加入：

```markdown
## Capability and Preservation Review (if applicable)

Capability completion: PASS | FAIL | CANNOT_VERIFY | BLOCKED
Preservation: PASS | FAIL | CANNOT_VERIFY | BLOCKED

| ID | Required result / existing behavior | Runtime evidence | Verdict | Missing evidence or finding |
| --- | --- | --- | --- | --- |
| `FIGCAP-001` or `PRES-001` | `<brief contract>` | `<command/path>` | `PASS | FAIL | CANNOT_VERIFY | BLOCKED` | `<none or detail>` |
```

将 combined task review verdict 规则扩展为：任意必需 `FIGCAP-*` 或核心 `PRES-*` 非 PASS 都不可 combined PASS，且 `CANNOT_VERIFY` 不能以 Minor/review debt 绕过。保持现有“仅 attempt 3 的可复现非核心装饰差异可成为 debt”规则不变。

- [ ] **Step 5: 增强 SDD controller 的视觉证据 contract 和 review decision**

在 `fp-execute-sdd/SKILL.md` 的 `## Visual Evidence Contract` 开头插入：当 task brief 声明 `FIGCAP-*`/`PRES-*` 时，controller 必须把相应 ledger/contract 路径、IDs、before/after replay 和 browser capability resolution 跨 brief/report/package/review 转递；Visual `PASS` 不能覆盖 capability 或 preservation non-pass。

在 `## Visual decision application` 的 combined task review verdict 段落改为：

```text
Combined task review verdict is PASS only when Spec Compliance is PASS, Code Quality is APPROVED, no Critical/Important finding remains, every planned visual scope resolves to VISUAL_PASS, every required FIGCAP-* is PASS, and every core PRES-* is PASS. A planned visual FAIL/CANNOT_VERIFY, capability non-pass, or preservation non-pass cannot merge into PASS merely because severity buckets are empty.
```

- [ ] **Step 6: 运行 focused validator，确认跨层 contracts 为绿**

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-figma-evidence-contract.ps1
```

Expected: `Figma evidence contract validation passed.`；新增 SDD/planner anchor assertions 与删除 `PRES-*` / `FIGCAP-*` 的 mutation fixtures 全部通过。

- [ ] **Step 7: Commit planner/SDD contract propagation**

```bash
git add skills/fp-plan-frontend/SKILL.md skills/fp-plan-frontend/plan-template.md skills/fp-execute-sdd/SKILL.md skills/fp-execute-sdd/task-brief-template.md skills/fp-execute-sdd/implementer-prompt.md skills/fp-execute-sdd/review-package-template.md skills/fp-execute-sdd/task-reviewer-prompt.md scripts/test-figma-evidence-contract.ps1
git commit -m "feat: trace figma capabilities through review"
```

Expected: commit 只包含 planner 和 SDD 对新 Figma quality contract 的消费与传递。

## Task 4: 将 Figma 质量工件纳入最终分支审查并完成公开说明

**Files:**
- Modify: `skills/fp-final-review/SKILL.md:89-189`
- Modify: `skills/fp-final-review/final-review-template.md:27-194`
- Modify: `README.md:13-18,43,53-58`
- Modify: `scripts/test-figma-evidence-contract.ps1`
- Test: `scripts/test-figma-evidence-contract.ps1`
- Test: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: change-local `figma-preservation.md`、`figma-capabilities.md`、Visual Evidence artifacts、Figma review reports 和当前 branch diff。
- Produces: final review coverage/finding evidence that distinguishes code editing from capability, preservation and visual completeness; public documentation accurately advertises the new gate without claiming automated installation.

- [ ] **Step 1: 将 Figma 工件加入 final reviewer 的 required reads 和 coverage table**

在 `skills/fp-final-review/SKILL.md` 的 Required Reads 列表中，紧接 progress/reviews 之后加入：当存在时读取 `figma-preservation.md`、`figma-capabilities.md`、`visual/` case manifests 与 `*-figma-review.md`，并要求缺失的计划 required artifact 标记为 `Missing`，不以聊天或 implementer self-report 代替。

在 FeaturePilot Coverage Review 中加入这四类 row：

```markdown
- Every required `FIGCAP-*`: source requirement, task/file owner, browser-observable result, status and evidence.
- Every core `PRES-*`: before baseline, after replay, approved exception and status.
- Figma UI source precedence: Figma-only evidence or `FUNCTION_SCOPE_ONLY` with forced visual `CANNOT_VERIFY`.
- Browser capability resolution: reused runner/extension/local CLI or explicit customer choice; never inferred installation.
```

在 Visual Evidence Gate 后明确：overall Figma completion is impossible when required capability/preservation is `FAIL`/`CANNOT_VERIFY`/`BLOCKED`, even if all screenshots pass; `PASS` requires every required capability, core preservation and core visual case `PASS`.

- [ ] **Step 2: 扩展 final review report schema 以持久化分维度结论**

在 `final-review-template.md` 的 Inputs Reviewed 添加：

```markdown
- Figma preservation contract: `<path or N/A>`
- Figma capability ledger: `<path or N/A>`
- Figma independent reviews: `<paths or N/A>`
- Browser capability resolution: `<project runner / Playwright browser extension / local playwright-cli / unavailable>`
```

在 `## FeaturePilot Coverage` 表之后插入以下 sections：

```markdown
## Figma Capability and Preservation Coverage

| ID | Source / required observable result | Owner task/file | Runtime evidence | Status | Review evidence |
| --- | --- | --- | --- | --- | --- |
| `FIGCAP-001` or `PRES-001` | `<contract>` | `<path/task>` | `<command/artifact>` | `PASS | FAIL | CANNOT_VERIFY | BLOCKED` | `<review path>` |

## Figma Completion Status

- Code editing: `DONE | PARTIAL | NOT_STARTED`
- Capability completion: `PASS | FAIL | CANNOT_VERIFY | BLOCKED`
- Preservation: `PASS | FAIL | CANNOT_VERIFY | BLOCKED`
- Figma visual fidelity: `PASS | FAIL | CANNOT_VERIFY | BLOCKED`
- Overall Figma result: `COMPLETE | INCOMPLETE | BLOCKED`

A Figma `COMPLETE` result requires every required `FIGCAP-*`, core `PRES-*`, and core Visual Case to be `PASS`, with no unapproved behavior change.
```

- [ ] **Step 3: 调整 focused test，验证最终审查与直接 Figma review 闭环**

在 `scripts/test-figma-evidence-contract.ps1` 的 final-review assertion group 中增加 `figma-preservation.md`、`figma-capabilities.md`、`FUNCTION_SCOPE_ONLY`、`Overall Figma result`、`every required FIGCAP-*` 与 `core PRES-*` anchors。增加 mutation：将 final template 中 `Overall Figma result` 改成 `Overall Figma note`，并断言 `Test-ContainsAnchors` 失败；将 final skill 中 `never inferred installation` 改为 `implicit installation allowed`，并断言 browser capability guard 消失。

在 test 结尾增加直接测试 `scripts/validate-plugin.ps1` 的 existing invocation anchor 不被移除：

```powershell
Assert-Condition (
    $validator.IndexOf('test-figma-evidence-contract.ps1', [System.StringComparison]::OrdinalIgnoreCase) -ge 0
) 'global validator does not invoke the expanded Figma quality contract'
```

- [ ] **Step 4: 更新 README 的用户可见能力描述**

将 README 的 Figma bullet 更新为：

```markdown
- **Figma 真实运行时质量门禁**：Figma 是有设计稿范围的唯一 UI 参考；以 `FIGCAP-*` 功能账本、`PRES-*` 既有功能保护、独立只读审查和 real-runtime visual case 联合判定。缺可信浏览器能力时由客户选择复用/安装方式，未验证只可报告 `CANNOT_VERIFY`，不得宣称 Figma 改造完成。
```

将 `commands/fp-figma.md` 的用途说明改成“Figma UI 分析、改造与质量审查入口”，并在核心技能列表新增一句：`fp-figma` 使用 Figma-only source、能力账本、既有功能保护和独立视觉/功能 review，不静默安装浏览器工具。

- [ ] **Step 5: 运行 focused validator 和完整插件验证**

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-figma-evidence-contract.ps1
```

Expected: `Figma evidence contract validation passed.`

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
```

Expected: 所有 focused contract validator 输出 passed，最终插件验证以 exit code `0` 结束；若任何 unrelated existing validator 失败，保留其完整输出并报告为非本任务引入的 blocker，而不是弱化本任务规则。

- [ ] **Step 6: 检查格式、diff 与公共术语禁止项**

Run:

```bash
git diff --check
```

Expected: 无 trailing whitespace、无 conflict marker。

Run:

```bash
git diff --check && git diff -- skills/fp-figma commands/fp-figma.md skills/fp-plan-frontend skills/fp-execute-sdd skills/fp-final-review scripts/test-figma-evidence-contract.ps1 README.md
```

Expected: 每一处新增 UI 参考规则都将有 Figma 的范围与原型禁令表达；所有 browser install 路径都包含客户选择与不得静默安装；不出现将原型称为 Figma visual reference 的正向表述。

- [ ] **Step 7: Commit final review integration and documentation**

```bash
git add skills/fp-final-review/SKILL.md skills/fp-final-review/final-review-template.md README.md scripts/test-figma-evidence-contract.ps1
git commit -m "feat: verify figma completion in final review"
```

Expected: final reviewer 和 public documentation 与直接 Figma/SDD contracts 一致；完整测试已经在 commit 前通过。

## Task 5: 完成设计与计划文档提交并做变更级验收

**Files:**
- Modify: `docs/superpowers/specs/2026-08-06-figma-fidelity-and-capability-gates-design.md`
- Create: `docs/superpowers/plans/2026-08-06-figma-fidelity-and-capability-gates-implementation.md`
- Test: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: 已确认设计、完成的 implementation commits、focused/full validation output。
- Produces: 与实际交付、精确验证和非目标一致的设计/实施记录。

- [ ] **Step 1: 将确认的设计文档纳入变更并记录实现决策**

在设计文档最后增加一个 `## 实现确认` 小节，逐条写明：只使用 `@playwright/cli` 的本机全局选择，不提及其他测试包；任何安装均由客户选择并在 B2 模式下逐次授权；Figma-only 规则；无 Figma 时原型仅 `FUNCTION_SCOPE_ONLY`；三个完成维度必须分开报告。

- [ ] **Step 2: 运行最终完整插件验证**

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
```

Expected: exit code `0`，并有 `Figma evidence contract validation passed.`；没有 validator 通过“跳过”新增 Figma quality contract。

- [ ] **Step 3: 进行变更范围和文档状态检查**

Run:

```bash
git status --short && git log --oneline -5 && git diff --check HEAD~4..HEAD
```

Expected: 变更只涉及本计划 File Structure 表列出的设计/计划、Figma skill/命令/模板、planner/execution/reviewer contracts、focused validation、README；若有用户已有未跟踪文档，保留并在提交前明确纳入或与用户确认，不得删除。

- [ ] **Step 4: Commit design and implementation plan documentation**

```bash
git add docs/superpowers/specs/2026-08-06-figma-fidelity-and-capability-gates-design.md docs/superpowers/plans/2026-08-06-figma-fidelity-and-capability-gates-implementation.md
git commit -m "docs: plan figma quality gates"
```

Expected: 最终文档记录与实现、验证和客户确认的安装边界完全一致。

## Plan Self-Review

### Spec coverage

| Confirmed design requirement | Plan task |
| --- | --- |
| Figma-only UI source；有 Figma 时原型不得参与视觉判断 | Task 1 anchors/mutations；Task 2 source gate/templates；Task 3 planner/SDD propagation；Task 4 final review |
| 无 Figma 时原型仅 `FUNCTION_SCOPE_ONLY`，视觉为 `CANNOT_VERIFY` | Tasks 1–4 |
| browser runner / extension / local CLI 探测和客户选择式安装 | Tasks 1–2；Task 3 browser capability resolution；Task 4 final verification/public docs |
| 不静默安装、B1/B2 客户自行或逐次授权 | Tasks 1–2；Task 4 mutations |
| 既有功能保护与 before/after baseline | Task 2 preservation template/skill；Task 3 task evidence/reviewer；Task 4 final coverage |
| `FIGCAP-*` 原子能力、preflight、双向审查 | Task 2 ledger/skill；Task 3 planner/SDD；Task 4 final reviewer |
| 实现者不能批准自己，独立只读 review | Task 2 review template/direct flow；Task 3 SDD reviewer；Task 4 final reviewer |
| 仅全部 capability/preservation/visual core PASS 才能声明完成 | Tasks 1–4 assertions/implementation |
| 不打破既有 visual evidence schema 与 review-debt 约束 | Tasks 1–4 preserve existing manifests/decision rules and extend them |

### Placeholder scan

本计划中的 Markdown code fences 展示的是需要被 skill 模板保留的 runtime placeholders（例如 `<slug>`、`<case-id>`），而非实施步骤中的未决工作。每个实施步骤给出了确切文件、文本结构、命令和预期结果；没有 `TBD`、`TODO`、`implement later` 或“类似前一任务”的执行指令。

### Type and contract consistency

- `FIGCAP-NNN` 是能力账本、planner、brief、implementer、package、reviewer、final reviewer 一致使用的稳定 ID。
- `PRES-NNN` 是 preservation contract、planner、brief、implementer、package、reviewer、final reviewer 一致使用的稳定 ID。
- browser capability 值固定为 `project runner | Playwright browser extension | local playwright-cli | customer choice pending | unavailable`。
- 功能、保护和视觉 verdict 均使用 `PASS | FAIL | CANNOT_VERIFY | BLOCKED`；仅 Figma overall 使用 `COMPLETE | INCOMPLETE | BLOCKED`，代码编辑使用 `DONE | PARTIAL | NOT_STARTED`。
