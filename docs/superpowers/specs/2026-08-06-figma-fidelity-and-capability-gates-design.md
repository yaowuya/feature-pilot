# Figma 还原质量与功能完整性门禁设计

- 日期：2026-08-06
- 状态：已获用户确认，待评审
- 范围：增强 FeaturePilot 的 `fp-figma`，使其在直接按 Figma 改造现有 UI 时具备可复跑的视觉验收、既有功能保护和功能能力完整性验证。

## 1. 问题与目标

当前流程已要求记录 Figma node、版本、Frame/Variant、Auto Layout、variables、assets、`reference.png`、`current.png` 与 Visual Checks，但 `fp-figma` 的直接实现路径没有把它们收敛为必经的实现后质量门禁。因此出现三类问题：

1. UI 可被修改但没有可信、可复跑的 Figma 保真审查，导致还原度不足仍可能被称为完成。
2. 为贴近 Figma 而修改已有页面时，可能误删、隐藏或改变现有业务行为。
3. PRD、Figma 与任务都提到的功能可在实现中遗漏，页面或控件存在却被错误宣称为功能完成。

目标是在 `/fp-figma` 内嵌三道联动门禁：

- **Figma Fidelity Gate**：证明当前 UI 对应 Figma 核心视觉与状态已通过。
- **UI Change Preservation Gate**：证明既有功能没有在未批准情况下退化。
- **Capability Completion Gate**：证明每个原子功能均有任务、实现与真实运行时证据。

不新建一个容易被遗漏调用的独立命令；审查协议与工件保持可复用，以便未来扩展独立复审入口。

## 2. 设计源与基线的严格优先级

### 2.1 存在可信 Figma UI 设计

当前范围存在可信 Figma UI 设计时，优先级固定如下：

```text
UI 视觉目标、布局、尺寸、token、状态表现、交互呈现
  = Figma UI 设计（唯一来源）

既有功能保留、回归判断
  = 当前真实代码 + 已有可复跑验证 / 真实浏览器行为证据

目标业务功能
  = 已确认 PRD / proposal / 当前明确用户指令

原型
  = 禁止作为 UI 视觉、布局、呈现或还原判断的参考
```

`Figma 未画出已有功能 != 允许删除该功能`。Figma 与当前已有行为存在冲突，且 Figma 未明确批准对应业务变更时，流程必须询问客户，不得自行隐藏、删除或更改语义。

### 2.2 没有可信 Figma UI 设计

```text
原型 = FUNCTION_SCOPE_ONLY（仅辅助确认功能与交互范围）
当前代码 = 已有功能保护基线
视觉还原度 = CANNOT_VERIFY
```

原型不能被降级成视觉设计源，不能据此宣称字号、间距、颜色、布局或视觉还原通过。

## 3. 浏览器验证能力门禁

### 3.1 能力探测与复用顺序

按以下顺序发现并复用已经存在且可证明可用的能力：

1. 客户项目已有 browser runner；
2. 已可用的 Playwright 浏览器扩展；
3. 本机已经可用的 `playwright-cli`。

不得仅因需要视觉验证就替换客户项目现有工具链，也不得静默新增依赖、浏览器二进制、配置、CI、项目文件或全局工具。

### 3.2 能力缺失时的客户选择门禁

无可信、可复跑浏览器验证能力时，`fp-figma` 要说明发现的能力、缺失原因、Node.js 前提、浏览器下载/网络/磁盘影响、修改边界与拒绝后结果，并让客户选择：

```text
A. 安装 Playwright 浏览器扩展
   - 用于 FeaturePilot / Claude 环境中的真实浏览器交互和截图
   - 不修改客户项目文件

B. 本机全局安装 @playwright/cli
   - 安装目标：运行 FeaturePilot 的开发机
   - 不修改客户项目依赖、lockfile 或 CI
   - 子选项：
     B1. FeaturePilot 仅展示命令，客户自行安装
     B2. FeaturePilot 先展示精确命令、影响与回滚边界；
         客户明确授权后，仅执行本次已展示的全局安装命令

C. 暂不安装
   - 仅进行 Figma 映射与静态代码审查
   - 视觉验收为 CANNOT_VERIFY
   - 不得称“Figma 已还原完成”或“视觉验收通过”
```

授权不跨范围：客户选择 B2 只授权当前展示过的全局安装命令，不能延伸到其他工具、依赖、浏览器组件、项目配置或 CI 改动。

### 3.3 视觉证据要求

浏览器交互证据和截图证据独立，不能互相替代。每个核心 Visual Case 必须记录：

- Figma/static `reference.png`；
- 真实目标路由、稳定 fixture 与稳定环境生成的 `current.png`；
- 可选 `diff.png` 或缺失原因；
- 真实浏览器操作至目标状态的交互证据；
- viewport、DPR、locale、theme、mask、case-specific acceptance rule 与命令/工具；
- Figma node、revision/time、Frame/Variant、variables、Auto Layout、assets。

视觉状态未通过、缺核心证据或无法复跑时，结论只能是 `FAIL`、`CANNOT_VERIFY` 或 `BLOCKED`。

## 4. UI Change Preservation Gate

### 4.1 修改前的保护契约

对既有页面/组件进行 Figma 改造时，编辑前创建：

```text
fp-docs/changes/<slug>/.fp-execute/figma-preservation.md
```

该工件唯一负责以下内容：

| 字段 | 要求 |
| --- | --- |
| 改造范围 | 路由、组件、Figma 节点、受影响文件 |
| 允许变更 | 布局、视觉层级、token、文案、响应式和 Figma 明确指定、已批准的交互改变 |
| 保护行为 | 操作、路由语义、接口调用、状态流转、权限、校验、加载/空态/错误态、键盘与焦点行为 |
| 证据来源 | 当前代码、已有测试、用户指令、Figma 节点；有 Figma 时不引用原型作为 UI 依据 |
| 基线场景 | 保护行为的稳定数据、操作步骤与可观察预期 |
| 例外 | 客户明确批准删除或改变的行为；未确认即不允许 |

### 4.2 修改前后基线重放

对每个关键保护场景：

1. 修改前优先执行已有相关验证；有浏览器能力时记录真实浏览器操作与结果。
2. 没有可执行验证时，记录可复现待验证清单并标记 `CANNOT_VERIFY`，不得伪造已通过的基线。
3. 修改后在相同 fixture、路由、用户状态、viewport、locale 与 theme 下重放。
4. 视觉允许变化，但未列为例外的业务外部结果必须一致。

任一关键保护行为回归为 `FAIL`；基线无法建立或无法重放为 `CANNOT_VERIFY`；二者均不得通过完成门禁。

### 4.3 独立只读审查

实现者不能批准自己的 UI 改动。实现后由新的、只读上下文审查者读取 Figma 设计上下文、映射、Visual Cases、Preservation Contract、能力账本和实际 diff，并：

1. 检查每项逻辑改动均有 Figma 或客户批准理由；
2. 重放 Preservation Cases；
3. 重放能力验证 Cases；
4. 重放核心 Visual Cases；
5. 输出 `PASS`、`FAIL`、`CANNOT_VERIFY` 或 `BLOCKED`。

报告路径：

```text
fp-docs/changes/<slug>/.fp-execute/reviews/<timestamp>-figma-review.md
```

它必须列出 Figma source/node/revision/Frame/Variant、每类 case 的证据、按严重度记录的缺陷、文件行号、复现步骤、影响与修复方向，及所有阻止“Figma 还原完成”的原因。

## 5. Capability Completion Gate

### 5.1 原子能力账本

在代码编辑前建立：

```text
fp-docs/changes/<slug>/.fp-execute/figma-capabilities.md
```

每个能力是稳定、不可复用的 `FIGCAP-NNN`，回答：用户可以做什么、在什么状态下做、结果如何观察、哪个 Figma 节点呈现、关联哪些代码和验证。

| 能力 ID | 原子能力与验收结果 | 目标功能来源 | Figma 节点 / Frame / Variant | 当前代码基线 | 实现任务 / 文件 | Preservation Case | 浏览器操作证据 | Visual Case | 验证结果 | 状态 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `FIGCAP-001` | 用户点击“新增”后打开表单，提交后列表出现新项 | PRD §… / 用户指令 | `123:456` / `CreateDialog` / `default` | 现有新增流程 | `frontend-003` / `…` | `PRES-002` | `…` | `VIS-003` | 命令、截图、断言 | `PASS` |

静态控件存在不等于对应能力完成。例如，渲染筛选框不代表输入更新条件、请求携带条件、列表刷新、清空、空态、错误态和刷新后状态都正确。

### 5.2 实施前完整性预检

建立账本时必须检测：

| 检测 | 处理 |
| --- | --- |
| 已确认功能没有实现任务或目标文件 | `BLOCKED`，先补齐实施范围 |
| Figma 状态没有行为或数据归属 | 询问客户或显式标记未实现范围，不能猜测 |
| 当前代码存在但 Figma 未呈现的功能 | 加入 Preservation Contract，禁止未批准删除 |

有 Figma 时，Figma 当前范围内的关键交互组件、状态 Variant、空态、错误态、权限态、确认态都必须关联至少一个 `FIGCAP-*`。没有 Figma 时，原型最多协助识别功能范围，不能变成视觉证明。

### 5.3 实现后的双向校验

独立审查同时执行：

- **账本 → 代码/运行态**：每个 `FIGCAP-*` 必须有完成任务、存在的实现、可达的浏览器状态和符合验收描述的外部可观察结果；若有视觉范围还须符合对应 Figma node/variant。
- **代码/Figma → 账本**：每个关键 Figma 状态和每个新增/修改的用户可见行为，都必须有能力来源或 Preservation Contract 映射。

标为完成的任务但关联能力仍是 `MISSING`、`PARTIAL`、`FAIL` 或 `CANNOT_VERIFY` 时，总体不得完成。

## 6. 状态与完成声明

流程分别报告，不再把“代码已编辑”冒充“功能完成”：

| 维度 | 状态 |
| --- | --- |
| 代码编辑 | `DONE` / `PARTIAL` / `NOT_STARTED` |
| 功能能力 | `PASS` / `FAIL` / `CANNOT_VERIFY` / `BLOCKED` |
| 既有功能保护 | `PASS` / `FAIL` / `CANNOT_VERIFY` / `BLOCKED` |
| Figma 视觉还原 | `PASS` / `FAIL` / `CANNOT_VERIFY` / `BLOCKED` |
| 总体 | `COMPLETE` / `INCOMPLETE` / `BLOCKED` |

只有同时满足以下条件，才允许说“Figma 改造完成”：

```text
所有必需 FIGCAP-* = PASS
AND 所有核心 Preservation Case = PASS
AND 所有核心 Visual Case = PASS
AND 不存在未批准的范围外行为变化
AND 证据均对应当前代码版本与稳定运行环境
```

若没有 UI 设计，视觉维度固定 `CANNOT_VERIFY`；因此总体不得因视觉还原而声明完成。应如实分开报告已完成代码编辑、功能能力、功能保护、视觉证据缺口与下一步。

## 7. 状态机

```text
RESOLVING
  -> DESIGN_SOURCE_GATE
  -> BROWSER_CAPABILITY_GATE
  -> PRESERVATION_BASELINE
  -> CAPABILITY_PREFLIGHT
  -> IMPLEMENTING
  -> INDEPENDENT_REVIEW
  -> COMPLETE | INCOMPLETE | BLOCKED
```

`DESIGN_SOURCE_GATE` 中，有可信 Figma UI 时它是唯一 UI 呈现源；无可信 Figma 时原型只能作为 `FUNCTION_SCOPE_ONLY`。`BROWSER_CAPABILITY_GATE` 中客户选择不安装则保留视觉 `CANNOT_VERIFY`，不能发布还原完成结论。

## 8. 工件布局与兼容策略

有当前 FeaturePilot change 时，证据只写入该 change：

```text
fp-docs/changes/<slug>/
└── .fp-execute/
    ├── figma-preservation.md
    ├── figma-capabilities.md
    ├── visual/
    │   └── <task-id>/<case-id>/
    │       ├── manifest.md
    │       ├── reference.png
    │       ├── current.png
    │       └── diff.png                 # 可选
    └── reviews/
        └── <timestamp>-figma-review.md
```

没有当前 change 时，不得伪造或创建项目级 `manifest.md` 或 settings。依现有 FeaturePilot 执行状态约定定位最近的 `.fp-execute/`；若无法安全确定归属，要求客户指定当前 change，不将证据散落在仓库根目录。

每项能力、保护场景与视觉 case 都有一个唯一详细 owner。沿用现有 visual-evidence manifest 的字段与目录，不另起不兼容的截图模式。

## 9. 计划中的实现表面

| 文件 | 计划调整 |
| --- | --- |
| `skills/fp-figma/SKILL.md` | 加入 Figma-only UI source 规则、原型限制、浏览器能力选择、无声安装禁止、Preservation Contract、Capability Ledger、独立审查、严格完成用语与状态机。 |
| `commands/fp-figma.md` | 扩展入口 Gate checksum，体现设计源优先级、功能保护与浏览器验证门禁。 |
| `skills/fp-plan-frontend/SKILL.md` | 计划任务消费 `FIGCAP-*`、Preservation Cases、Visual Cases，要求唯一任务/验证归属。 |
| `skills/fp-figma/` 的新增模板 | 增加 preservation、capabilities、独立 review 报告的确定性字段。 |
| `scripts/test-figma-evidence-contract.ps1` | 以正向与变异测试锁定设计源优先级、原型限制、浏览器能力选择、安装授权、`CANNOT_VERIFY` 完成禁令、能力账本与 preservation 约束。 |
| `scripts/validate-plugin.ps1` | 保持并验证 focused contract test 的接入。 |

## 10. 验收策略

实现必须至少用契约/变异测试证明：

1. 有 Figma 时，原型不能成为 UI/视觉参考；无 Figma 时原型只能是 `FUNCTION_SCOPE_ONLY`，视觉不能 `PASS`。
2. 已有 runner、浏览器扩展或本机 CLI 时复用；能力缺失时出现客户选择，不得静默安装；选择不安装则不能输出完成。
3. Figma 未呈现的现有操作，未经批准不得删除；缺修改前基线或无法重放保护场景时不能通过；视觉通过不能覆盖 Preservation `FAIL`。
4. 每个 `FIGCAP-*` 具有来源、实现/任务归属与可观察验证；静态控件不能视为功能通过；关联能力未通过时任务或总体均不能完成。
5. 实现者报告不能替代独立只读 review；缺可信 Figma reference、真实运行 `current.png` 或核心交互证据时，review 只能是 `CANNOT_VERIFY`；只有非核心、可复现的装饰差异可以作为 debt，不能掩盖功能或核心视觉问题。

## 11. 非目标

- 不替换客户已有浏览器验证方案。
- 不静默安装任何全局工具、浏览器组件、项目依赖或 CI 配置。
- 不把原型与 Figma 混合成视觉来源。
- 不创建/修复项目级 `fp-docs` 信息层；这仍是 `fp-init` 的职责。
- 不替换 `fp-final-review` 的全分支审查；新门禁在每一次 Figma UI 改造完成前生效。

## 实现确认

- 本机 CLI 只使用 `@playwright/cli`；不引入或提及其他测试包。
- 安装浏览器扩展或本机全局 CLI 均由客户选择；仅当客户选择由 FeaturePilot 执行且明确授权本次展示的精确命令时才可执行，授权不扩展到其他工具、浏览器组件、项目依赖、lockfile、配置或 CI。
- 有可信 Figma UI 设计时，Figma 是唯一 UI 参考，原型不得参与 UI 视觉/布局/呈现/还原判断；无 Figma 时原型仅为 `FUNCTION_SCOPE_ONLY`。
- 代码编辑、功能能力、既有功能保护、Figma 视觉还原和总体状态必须分开报告；任何 required `FIGCAP-*`、核心 `PRES-*` 或核心 Visual Case 非 `PASS` 都禁止宣称 Figma 改造完成。
