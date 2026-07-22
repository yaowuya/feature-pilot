# CodeGraph 可选代码地图集成 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 让 `fp-init` 在明确授权下通过 npm 安装 CodeGraph、配置可选 MCP 并构建项目代码图，同时让后续 FeaturePilot 调查优先使用代码图且在任何故障下安全回退。

**Architecture:** 新增 `skills/_shared/codegraph.md` 作为唯一 CodeGraph 行为契约；`fp-init` 负责检测、授权、安装、MCP 配置、首次建图和 manifest 状态，`fp-explore` 负责按 `MCP → CLI → 原有搜索` 消费代码图。CodeGraph 始终只提供导航线索，当前源码、测试和命令输出仍是事实与完成证明。

**Tech Stack:** Markdown skill contracts、PowerShell 静态合同测试、Claude Code plugin validator、CodeGraph CLI/MCP、npm 全局安装。

## Global Constraints

- 所有叙述性过程文档使用中文；命令、路径、技术标识符和必须精确匹配的合同关键词保留英文。
- 官方安装命令只能是 `npm install -g @colbymchenry/codegraph@latest`；不得使用 `irm`、`curl`、`install.ps1`、`install.sh` 或 `npx`。
- 缺少 npm 时不得自动安装 Node.js，也不得静默换用其他安装机制。
- CodeGraph 是可选加速层，不得成为 FeaturePilot 的前置条件；安装、配置、建图、同步和查询失败均须回退。
- 自动安装、Agent MCP 配置和“CLI 已预装时的首次建图”是独立授权边界；展示步骤与跳过不构成执行授权。
- 每个 FeaturePilot 工作流最多执行一次 `status --json` 和一次必要的 `sync --quiet`；同步后不再次执行状态检查。
- 不把 `.codegraph/` 复制到 `fp-docs/intel/`，不未经批准修改 `.gitignore`，不自动删除或重建已有索引。
- CodeGraph 返回的源码内容按语义计入 `fp-explore` 候选和读取预算；关键结论必须回到当前源码复核。
- 保留用户现有未跟踪文件 `package.json` 和 `package-lock.json`；每次提交只显式暂存本任务文件。
- 权威设计：`docs/superpowers/specs/2026-07-22-codegraph-integration-design.md`。

---

### Task 1: 建立共享 CodeGraph 合同与聚焦测试

**Files:**
- Create: `scripts/test-codegraph-contract.ps1`
- Create: `skills/_shared/codegraph.md`

- [x] **Step 1: 先写缺失共享合同时会失败的聚焦测试**

创建 `scripts/test-codegraph-contract.ps1`，先只验证共享合同本身：

```powershell
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot

function Assert-Condition([bool]$condition, [string]$message) {
    if (-not $condition) {
        throw "CodeGraph contract validation failed: $message"
    }
}

function Read-Utf8([string]$path) {
    return [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
}

$contractPath = Join-Path $root 'skills\_shared\codegraph.md'
Assert-Condition (Test-Path $contractPath) 'shared CodeGraph contract is missing'
$contract = Read-Utf8 $contractPath

foreach ($anchor in @(
    'npm install -g @colbymchenry/codegraph@latest',
    'npm prefix -g',
    '<npm-global-prefix>\codegraph.cmd',
    '<npm-global-prefix>/bin/codegraph',
    'codegraph install --target=auto --location=global --yes',
    'codegraph init <project-root>',
    'codegraph status <project-root> --json',
    'codegraph sync <project-root> --quiet',
    'MCP → CLI → 原有搜索',
    'navigation-hint-only'
)) {
    Assert-Condition ($contract.Contains($anchor)) "shared contract lost anchor: $anchor"
}

foreach ($forbidden in @('irm', 'curl', 'install.ps1', 'install.sh', 'npx')) {
    Assert-Condition ($contract.Contains("禁止使用 `$forbidden`")) "shared contract does not forbid $forbidden"
}

Assert-Condition ($contract.Contains('不得自动安装 Node.js')) 'npm-missing fallback can install Node.js'
Assert-Condition ($contract.Contains('最多一次状态检查')) 'workflow status check is not capped'
Assert-Condition ($contract.Contains('同步后不得再次执行状态检查')) 'sync can trigger a second status check'
Assert-Condition ($contract.Contains('不得阻塞 FeaturePilot')) 'failure fallback is not explicit'

Write-Output 'CodeGraph contract validation passed.'
```

- [x] **Step 2: 运行聚焦测试并确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-codegraph-contract.ps1
```

Expected: FAIL，错误包含 `shared CodeGraph contract is missing`。

- [x] **Step 3: 写入最小但完整的共享合同**

创建 `skills/_shared/codegraph.md`，必须包含以下结构和确定性规则：

```markdown
# CodeGraph 可选代码地图契约

仅在当前任务需要代码定位、符号关系、调用链、数据流或影响范围时加载本文件。CodeGraph 是可选导航层，不是 FeaturePilot 的运行前置条件。

## 安装与授权

- 检测顺序：`codegraph --version`，必要时再检查 npm 全局 launcher。
- 自动安装前先运行 `npm --version`，并明确展示全局安装影响；唯一允许的安装命令是 `npm install -g @colbymchenry/codegraph@latest`。
- 禁止使用 `irm`。
- 禁止使用 `curl`。
- 禁止使用 `install.ps1`。
- 禁止使用 `install.sh`。
- 禁止使用 `npx`。
- npm 不可用时不得自动安装 Node.js；只说明前置条件、展示 npm 步骤或跳过，并继续 FeaturePilot。
- “展示安装步骤”和“跳过”都不是安装、配置或建图授权。
- 自动安装的明确选择同时授权当前项目首次建图；CLI 原本已安装且项目没有 `.codegraph/` 时，必须另行确认建图。

安装后先尝试正常的 `codegraph` 命令；PATH 尚未刷新时运行 `npm prefix -g` 并解析：

- Windows：`<npm-global-prefix>\codegraph.cmd`
- macOS/Linux：`<npm-global-prefix>/bin/codegraph`

Agent MCP 配置必须独立确认；获准后才运行 `codegraph install --target=auto --location=global --yes`。配置完成后提示重启 Agent，当前工作流继续使用 CLI。

## 建图与健康状态

- 首次建图使用 `codegraph init <project-root>`。
- 已有图与首次建图均用 `codegraph status <project-root> --json` 验证；仅存在 `.codegraph/` 目录不代表健康。
- 每个 FeaturePilot 工作流最多一次状态检查；发现待同步变化时最多运行一次 `codegraph sync <project-root> --quiet`，同步后不得再次执行状态检查。
- 状态检查、同步或查询失败后，本工作流不重复重试，不删除索引，不修改 `.gitignore`，只报告一次精简原因。

## 查询与证据

- 查询优先级固定为 `MCP → CLI → 原有搜索`。
- MCP 使用当前会话暴露的 `codegraph_explore`；CLI 使用 `codegraph explore --path <project-root> --max-files <budget> <query>`。
- CodeGraph 返回内容按语义计入候选路径、本地读取窗口和整文件读取预算。
- 所有图结果标记为 `navigation-hint-only`；实际修改、精确契约和完成声明必须用当前源码、测试或命令输出复核。
- CLI、MCP、索引、语言支持、同步或查询不可用时不得阻塞 FeaturePilot，立即回退到 `Glob → Grep → ranged Read`。
```

- [x] **Step 4: 运行聚焦测试并确认 GREEN**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-codegraph-contract.ps1`

Expected: PASS，输出 `CodeGraph contract validation passed.`。

- [x] **Step 5: 提交共享合同**

```powershell
git add scripts/test-codegraph-contract.ps1 skills/_shared/codegraph.md
git commit -m "test: define CodeGraph integration contract"
```

---

### Task 2: 将检测、npm 安装、MCP 配置和建图接入 fp-init

**Files:**
- Modify: `scripts/test-codegraph-contract.ps1`
- Modify: `skills/fp-init/SKILL.md`
- Modify: `skills/fp-init/templates.md`
- Modify: `commands/fp-init.md`

- [x] **Step 1: 扩展测试，锁定 fp-init 三选项和 manifest 状态**

在测试输出前加入：

```powershell
$init = Read-Utf8 (Join-Path $root 'skills\fp-init\SKILL.md')
$templates = Read-Utf8 (Join-Path $root 'skills\fp-init\templates.md')
$command = Read-Utf8 (Join-Path $root 'commands\fp-init.md')

foreach ($anchor in @(
    'skills/_shared/codegraph.md',
    '自动安装（推荐）',
    '展示安装步骤',
    '跳过',
    'npm install -g @colbymchenry/codegraph@latest',
    'npm prefix -g',
    'codegraph install --target=auto --location=global --yes',
    'codegraph init <project-root>',
    'codegraph status <project-root> --json',
    '选择自动安装即同时授权当前项目首次建图',
    'CLI 原本已安装'
)) {
    Assert-Condition ($init.Contains($anchor)) "fp-init lost anchor: $anchor"
}

Assert-Condition ($templates.Contains('## Code Map')) 'manifest template lacks Code Map'
Assert-Condition ($templates.Contains('navigation-hint-only')) 'manifest Code Map can be treated as current proof'
Assert-Condition ($command.Contains('npm')) 'Claude command checksum lacks npm-only install gate'
Assert-Condition ($command.Contains('MCP')) 'Claude command checksum lacks separate MCP gate'
Assert-Condition ($command.Contains('建图')) 'Claude command checksum lacks graph-build gate'
```

- [x] **Step 2: 运行测试并确认 RED**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-codegraph-contract.ps1`

Expected: FAIL，首个缺失锚点来自 `fp-init` 或 manifest 模板。

- [x] **Step 3: 在 fp-init 根目录解析后加入 CodeGraph 步骤**

在 `skills/fp-init/SKILL.md` 的目标根解析之后、轻量 discovery 之前加载共享合同并执行以下状态机；后续章节顺延编号：

```markdown
### 2. Offer optional CodeGraph setup

仅此步骤允许按用户明确授权安装 CodeGraph 或构建代码图。先按 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/codegraph.md` 检测 CLI、npm launcher 和 `<project-root>/.codegraph/`。

CLI 不可用时，一次只询问一个决定：

1. 自动安装（推荐）— 展示 npm 包名、`npm install -g @colbymchenry/codegraph@latest` 和全局安装影响；选择自动安装即同时授权当前项目首次建图。
2. 展示安装步骤 — 只展示 npm 前置条件、安装、可选 MCP 配置和建图命令，不执行。
3. 跳过 — 本轮不安装、不配置、不建图，继续普通 init。

自动安装前验证 `npm --version`。npm 不可用时不得自动安装 Node.js 或切换安装方式；说明前置条件后继续普通 init。安装后验证版本；PATH 未刷新时用 `npm prefix -g` 解析平台 launcher。

CLI 可用后，单独询问是否配置检测到的 Claude Code/Codex MCP。只有再次确认后才运行 `codegraph install --target=auto --location=global --yes`；该选择可能修改用户级配置，成功后提示重启 Agent，当前流程继续使用 CLI。

项目没有 `.codegraph/` 时：本轮自动安装后直接运行 `codegraph init <project-root>`；CLI 原本已安装则先单独确认是否建图。项目已有图或首次建图完成后，只用一次 `codegraph status <project-root> --json` 验证；待同步时运行一次 `codegraph sync <project-root> --quiet`，同步后不再次检查状态。

任何失败都只报告一次原因并继续普通 init。不得自动删除 `.codegraph/`、修改 `.gitignore`，或把图数据复制进 `fp-docs/intel/`。
```

同时把原 “Lightweight discovery boundaries” 中的禁止项限定为：安装包和穷举索引仍默认禁止，只有上述已确认 CodeGraph 步骤可执行 npm 全局安装和 CodeGraph 项目建图。

- [x] **Step 4: 更新 manifest 模板和最终报告**

在 `skills/fp-init/templates.md` 的 manifest 模板中加入：

```markdown
## Code Map

| Provider | Status | Version | Index Path | Last Checked | Use As |
| --- | --- | --- | --- | --- | --- |
| CodeGraph | unknown | unavailable | `.codegraph/` | not-checked | navigation-hint-only |
```

在 `fp-init` 最终报告中明确列出 CLI 状态、MCP 配置/重启状态、索引状态、是否降级以及 manifest 是否获准更新。现有 manifest 不得未经批准覆盖；实时检测优先于表中历史状态。

- [x] **Step 5: 更新 Claude Code 薄命令校验摘要**

在 `commands/fp-init.md` 的 Gate checksum 追加：

```markdown
- CodeGraph 是可选加速层；自动安装只使用 npm，MCP 配置独立确认，建图和失败回退遵循共享合同。
```

- [x] **Step 6: 运行聚焦与全局回归**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-codegraph-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
```

Expected: 聚焦测试 PASS；全局校验 PASS，或只因尚未登记新测试而在 Task 4 前保持现状。

- [x] **Step 7: 提交 fp-init 接入**

```powershell
git add scripts/test-codegraph-contract.ps1 skills/fp-init/SKILL.md skills/fp-init/templates.md commands/fp-init.md
git commit -m "feat: add CodeGraph setup to fp-init"
```

---

### Task 3: 为 fp-explore 增加代码图快速路径和预算约束

**Files:**
- Modify: `scripts/test-codegraph-contract.ps1`
- Modify: `scripts/test-explore-contract.ps1`
- Modify: `skills/_shared/workspace-rules.md`
- Modify: `skills/fp-explore/SKILL.md`

- [x] **Step 1: 先锁定路由顺序、单工作流健康检查和证据降级**

在 `scripts/test-codegraph-contract.ps1` 输出前加入：

```powershell
$workspace = Read-Utf8 (Join-Path $root 'skills\_shared\workspace-rules.md')
$explore = Read-Utf8 (Join-Path $root 'skills\fp-explore\SKILL.md')

Assert-Condition ($workspace.Contains('skills/_shared/codegraph.md')) 'workspace contract does not route CodeGraph lazily'
foreach ($anchor in @(
    'Stage 0 - CodeGraph fast path',
    'codegraph_explore',
    'codegraph explore --path <project-root> --max-files <budget> <query>',
    'MCP → CLI → 原有搜索',
    '最多一次状态检查',
    '同步后不得再次执行状态检查',
    'candidate paths',
    'local read windows',
    '当前源码'
)) {
    Assert-Condition ($explore.Contains($anchor)) "fp-explore lost CodeGraph anchor: $anchor"
}
Assert-Condition ($explore.Contains('回退到 Stage A')) 'fp-explore can stop on CodeGraph failure'
```

在 `scripts/test-explore-contract.ps1` 的 progressive inspection 锚点集合加入：

```powershell
'Stage 0 - CodeGraph fast path',
'MCP → CLI → 原有搜索',
'回退到 Stage A',
'navigation-hint-only'
```

- [x] **Step 2: 运行两个测试并确认 RED**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-codegraph-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-explore-contract.ps1
```

Expected: 两者至少一个因 `Stage 0 - CodeGraph fast path` 缺失而 FAIL。

- [x] **Step 3: 在 workspace contract 中加入按需加载路由**

在 `skills/_shared/workspace-rules.md` 加入：

```markdown
## Optional code map

需要定位代码、符号、调用链、数据流或影响范围时，按需读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/codegraph.md`。CodeGraph 只加速候选定位；不可用时继续现有搜索，不降低当前源码验证、读取预算、只读和授权边界。
```

- [x] **Step 4: 在 fp-explore 中加入 Stage 0**

在现有 Stage A 之前加入：

```markdown
### Stage 0 - CodeGraph fast path

仅当问题涉及代码位置、符号关系、调用链、数据流、影响范围或相关源码候选时启用。按共享合同为当前工作流解析一次状态：有 MCP 时优先 `codegraph_explore`；否则在 CLI 和健康项目图可用时运行 `codegraph explore --path <project-root> --max-files <budget> <query>`；否则回退到 Stage A。

查询顺序固定为 `MCP → CLI → 原有搜索`。每个工作流最多一次状态检查和一次必要同步；同步后不得再次执行状态检查，失败后不得在同一工作流重复重试。

CodeGraph 结果是 `navigation-hint-only`：返回的路径计入 `candidate paths`，有界源码摘录计入 `local read windows`，整文件内容计入 `unbounded application-file reads`。保留最相关候选，不把 `--max-files` 当成必须耗尽的配额。修改范围、精确契约和结论必须回到当前源码、测试或命令输出复核。

MCP、CLI、索引、同步、查询或语言支持失败时只记录一次精简降级原因并回退到 Stage A，不阻塞 standalone 或内部 profile。
```

同步调整 Repository investigation flow：在“Search before opening files”之前先判断 Stage 0 是否适用；空输入的 bounded orientation 不主动触发建图或安装。

- [x] **Step 5: 运行聚焦回归并确认 GREEN**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-codegraph-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-explore-contract.ps1
```

Expected: 两个测试均 PASS，且 quick 的 `8 / 8 / 1` 上限与原有 budget profiles 未改变。

- [x] **Step 6: 提交消费路径**

```powershell
git add scripts/test-codegraph-contract.ps1 scripts/test-explore-contract.ps1 skills/_shared/workspace-rules.md skills/fp-explore/SKILL.md
git commit -m "feat: use CodeGraph in fp-explore"
```

---

### Task 4: 接入全局验证并同步 Codex、Claude Code 和用户文档

**Files:**
- Modify: `scripts/test-codegraph-contract.ps1`
- Modify: `scripts/validate-plugin.ps1`
- Modify: `AGENTS.md`
- Modify: `CLAUDE.md`
- Modify: `README.md`
- Modify: `docs/user_guide/init-prd-start.md`

- [ ] **Step 1: 扩展聚焦测试，要求所有公共入口一致**

在 `scripts/test-codegraph-contract.ps1` 输出前加入：

```powershell
$validator = Read-Utf8 (Join-Path $root 'scripts\validate-plugin.ps1')
$agents = Read-Utf8 (Join-Path $root 'AGENTS.md')
$claude = Read-Utf8 (Join-Path $root 'CLAUDE.md')
$readme = Read-Utf8 (Join-Path $root 'README.md')
$guide = Read-Utf8 (Join-Path $root 'docs\user_guide\init-prd-start.md')

Assert-Condition ($validator.Contains('test-codegraph-contract.ps1')) 'global validator does not invoke CodeGraph suite'
Assert-Condition ($validator.Contains('skills\_shared\codegraph.md')) 'global validator does not anchor shared CodeGraph resource'
foreach ($surface in @(
    @{ Name = 'AGENTS.md'; Text = $agents },
    @{ Name = 'CLAUDE.md'; Text = $claude },
    @{ Name = 'README.md'; Text = $readme },
    @{ Name = 'user guide'; Text = $guide }
)) {
    Assert-Condition ($surface.Text.Contains('CodeGraph')) "$($surface.Name) does not document CodeGraph"
    Assert-Condition ($surface.Text.Contains('npm install -g @colbymchenry/codegraph@latest')) "$($surface.Name) lacks npm-only install command"
}
```

- [ ] **Step 2: 运行聚焦测试并确认 RED**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-codegraph-contract.ps1`

Expected: FAIL，指出全局 validator 或公共文档尚未接入。

- [ ] **Step 3: 将聚焦测试接入全局 validator**

在 `scripts/validate-plugin.ps1` 调用 explore 聚焦测试的位置前加入：

```powershell
$codeGraphContractValidator = Join-Path $root 'scripts\test-codegraph-contract.ps1'
Assert-Condition (Test-Path $codeGraphContractValidator) 'focused CodeGraph contract validator is missing'
& powershell -NoProfile -ExecutionPolicy Bypass -File $codeGraphContractValidator
Assert-Condition ($LASTEXITCODE -eq 0) 'focused CodeGraph contract validator failed'
```

把 `skills\_shared\codegraph.md` 纳入共享资源存在性、行数、字符数和必要锚点校验；把 `fp-init` 锚点补为 npm-only、独立 MCP、首次建图和回退，把 `fp-explore` 锚点补为 Stage 0、预算计数和源码复核。

- [ ] **Step 4: 同步公共合同与用户指南**

在四个文档中使用一致表述：

```markdown
CodeGraph 是可选的本地代码地图。`fp-init` 检测到未安装时提供“自动安装、展示安装步骤、跳过”；自动安装只使用 `npm install -g @colbymchenry/codegraph@latest`。Agent MCP 配置单独确认，建图或查询失败会回退到原有搜索，不影响 FeaturePilot 主流程。代码图只用于导航，关键结论仍须验证当前源码、测试和命令输出。
```

具体落点：

- `AGENTS.md`：在 Workspace/settings 读取规则附近说明按需加载共享 CodeGraph 合同和 `MCP → CLI → 原有搜索`。
- `CLAUDE.md`：新增 `## CodeGraph 可选加速`，让 Claude Code 入口与技能合同一致。
- `README.md`：更新架构/低成本流程/项目配置，写明 npm 安装、独立 MCP 授权与非阻塞回退。
- `docs/user_guide/init-prd-start.md`：在 `/fp-init` 部分增加三选项、npm 缺失处理、MCP 重启提示、首次建图授权和 `.codegraph/` 说明。

- [ ] **Step 5: 运行全套静态验证**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-codegraph-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-explore-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
```

Expected: 三个命令均 PASS；命令适配器仍在 5,000 字符预算内，所有 `SKILL.md` 仍不超过 500 行。

- [ ] **Step 6: 提交验证与文档**

```powershell
git add scripts/test-codegraph-contract.ps1 scripts/validate-plugin.ps1 AGENTS.md CLAUDE.md README.md docs/user_guide/init-prd-start.md
git commit -m "docs: document optional CodeGraph acceleration"
```

---

### Task 5: 完整验证与交付检查

**Files:**
- Verify only; do not modify `package.json` or `package-lock.json`

- [ ] **Step 1: 运行全部合同与插件验证**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-codegraph-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-explore-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\measure-context.ps1
claude plugin validate .
```

Expected: 所有命令退出码为 0；context measurement 只报告测量值，不出现合同缺失。

- [ ] **Step 2: 检查 npm-only 和授权边界没有被弱化**

```powershell
rg -n "npm install -g @colbymchenry/codegraph@latest|npm prefix -g|自动安装（推荐）|展示安装步骤|MCP → CLI → 原有搜索|navigation-hint-only" skills commands scripts AGENTS.md CLAUDE.md README.md docs/user_guide/init-prd-start.md
rg -n "(?:irm|curl|install\.ps1|install\.sh|npx).*codegraph|codegraph.*(?:irm|curl|install\.ps1|install\.sh|npx)" skills commands AGENTS.md CLAUDE.md README.md docs/user_guide/init-prd-start.md
```

Expected: 第一条覆盖共享合同、init、explore、测试和文档；第二条只命中明确的禁止性说明，不出现可执行安装示例。

- [ ] **Step 3: 检查差异、提交范围和用户文件**

```powershell
git diff --check
git status --short --branch
git log -5 --oneline
```

Expected: `git diff --check` PASS；工作树中若仍有 `package.json`、`package-lock.json`，它们保持未跟踪且未进入任何任务提交；最新四个实施提交分别只覆盖其列出的文件。

- [ ] **Step 4: 汇报交付结果**

汇报必须包含：npm-only 安装契约、三选项与独立 MCP 授权、首次建图规则、后续 `MCP → CLI → 原有搜索` 路由、一次健康检查/同步上限、源码复核边界、全部验证结果和任何未跟踪用户文件。不要在没有实际运行 CodeGraph 项目建图的情况下宣称真实项目索引已验证。
