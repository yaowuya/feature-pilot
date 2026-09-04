# fp-design-review skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增 `fp-design-review` skill，让 `review.md`（开发设计评审入口）在设计完成之后由 fp-start 阶段 2 生成或单独触发，并回滚 fp-brainstorm 上未提交的 review.md 职责。

**Architecture:** 新 skill（SKILL.md ＋ review-template.md）以 canonical-first Consumer 解析设计产物，从已落盘设计文档提炼导航摘要＋按章节评审关注点，写入 change 根唯一 `review.md`（仅 small form）。fp-start 阶段 2 写入后产物确认中调用它；fp-brainstorm 回滚到不感知 review.md 的状态；两个契约脚本与 measure-context 同步注册。

**Tech Stack:** Markdown skill 契约（本仓库全部是提示词契约）；PowerShell 契约脚本（`test-decision-gate-contract.ps1`、`validate-plugin.ps1`、`test-agents-router-contract.ps1`、`measure-context.ps1`）。

**Spec:** `docs/superpowers/specs/2026-09-02-fp-design-review-skill-design.md`

## Global Constraints

- `review.md` 位于 change 根（`fp-docs/changes/<slug>/review.md`），每个 change 恰一个，仅 small form，覆盖全部实际端。
- `review.md` 不复制 Decision Ledger 行或设计正文，不改变任何台账状态；素材只来自已落盘设计文档，不得编造。
- 模板 `<...>` 占位符在最终产物中无效（与设计正文同一规则）。
- 每个 SKILL.md：frontmatter 仅 `name` ＋ `description`；`name` 与目录名一致；正文必须包含 `插件资源锚定` 和 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md`；≤500 行。
- 每个命令适配器 ≤20 行、含 `Gate checksum`、经 `` `${CLAUDE_PLUGIN_ROOT}/skills/<name>/SKILL.md` `` 加载对应 skill；全部命令总字符 ≤ 命令数 × 480（12 命令 → 5760）。
- 全局禁止子串 `fp-review` 出现在 commands/skills/scripts/README/AGENTS.md/docs/user_guide/docs/release_notes（validate-plugin.ps1 旧标识扫描）；`fp-design-review` 不含该子串。
- `scripts/test-decision-gate-contract.ps1` 保留 WIP 引入的 UTF-8 BOM（含中文锚点；commit c0c3b42 先例）。
- 不把 `fp-design-review` 加入 validate-plugin.ps1 的 `$artifactConsumerContracts`：该映射要求 task-plan/overview 相关锚点，而本 skill 只消费设计产物、不消费 task 计划（注册走 `$skillAnchors` ＋ 专项断言）。
- 中文锚点是字面子串匹配，SKILL.md/模板中的措辞必须与契约脚本断言逐字一致。
- 提交信息用中文 conventional commits（`feat:`/`refactor:`/`test:`）。
- 运行命令统一用 `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/<脚本>`；断言失败抛异常非零退出，`test-decision-gate-contract.ps1` 成功时静默。

---

### Task 1: 创建 fp-design-review skill、模板、命令适配器与路由登记

**Files:**
- Create: `skills/fp-design-review/SKILL.md`
- Create: `skills/fp-design-review/review-template.md`
- Create: `commands/fp-design-review.md`
- Modify: `README.md`（命令表，`commands/fp-final-review.md` 行之前）
- Modify: `AGENTS.md`（Codex fallback router，`Technical design` 行之后）

**Interfaces:**
- Consumes: 现有共享契约 `skills/_shared/workspace-rules.md`、`skills/_shared/artifact-layout.md`；设计产物 canonical layout（`design/00-index.md`、`design/backend.md`、`design/backend/00-index.md`、`design/frontend.md`、`design/frontend/00-index.md`）。
- Produces: skill 名 `fp-design-review`；模板文件路径 `skills/fp-design-review/review-template.md`（Task 3 的契约锚点引用）；命令 `/fp-design-review <slug>`；产物 `fp-docs/changes/<slug>/review.md`。Task 2 的 fp-start 委托措辞引用 `fp-design-review` 这个名字。

- [ ] **Step 1: 创建 `skills/fp-design-review/SKILL.md`**

完整内容（逐字使用，中文锚点将来被契约脚本断言）：

```markdown
---
name: fp-design-review
description: Use when a resolved FeaturePilot design needs a development design review entry, whether invoked from fp-start stage-2 confirmation or standalone via /fp-design-review.
---
## FeaturePilot workspace and information layer

插件资源锚定、`${CLAUDE_PLUGIN_ROOT}` 路径映射与缺失即停止规则见 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md`；不要在消费者项目中搜索 `skills/**`。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting. Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` before resolving design artifacts; it owns canonical form selection, split manifests, hard limits, conversion, and historical-layout rejection.

---

# FeaturePilot Design Review

你正在为一份已写入的设计文档生成开发设计评审入口 `fp-docs/changes/<slug>/review.md`（与 `proposal.md`、`design/` 同级的 change 根文件）。它面向研发经理与研发工程师的设计评审：只提炼设计文档中要评审的内容，供评审者按章节逐项给出结论；它不是决策记录、确认证据或 PRD/proposal/design/task artifact。

## 触发方式

- **fp-start 阶段 2**：设计文件与 Decision Ledger 写入后核验通过后、设计确认询问之前，由 `fp-start` 调用本 skill 生成并展示评审入口。
- **单独触发**：`/fp-design-review <slug>`。无 slug 参数时：`fp-docs/changes/` 下只有一个进行中的 change 则直接使用；多个时列出并等待用户选择；没有时报告无可评审变更。用于评审会前刷新或手动重建。

## 流程

### 第一步：解析设计产物（canonical-first）

按 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` 以 canonical-first Consumer 解析当前 slug 的 `design/00-index.md` 与每个实际端的选定 entry；split form 严格按 manifest order 读取全部已列分片，出现 unindexed fragment、dual form 或 historical path 即阻塞。

### 第二步：提炼评审素材（只读）

- 从每个 actual-end 的 unique detailed owner 读取 `### Decision Ledger`，只做合并计数（共 N 项、阻塞 N / 非阻塞 N、全部终态），不复制台账行。任一行非终态即阻塞，不生成 review.md。
- 通读设计正文：数据模型、API 接口、业务逻辑、前端章节，以及其中引用的现有代码路径（抽查路径素材）。
- 全部素材来自已落盘设计文档，不得编造。设计缺失或阻塞时报告原因，不生成 review.md。

### 第三步：生成 review.md

【立即用工具执行】读取 `${CLAUDE_PLUGIN_ROOT}/skills/fp-design-review/review-template.md`，按模板写入 `fp-docs/changes/<slug>/review.md`：每个 change 只有一个 review.md，只允许 small form，覆盖全部实际端；模板含决策统计、数据变更、接口变更、评审关注点、建议评审顺序、建议抽查路径与设计入口。评审关注点按设计章节分组，每条带 design 锚点；不得复制决策正文或设计正文。

## 边界与恢复

- 本 skill 不是 second design finalizer：不重扫代码库、不重推导决策、不修改设计文件与 Decision Ledger、不推进任何阶段；fp-start 调用后继续其设计确认流程。
- 幂等刷新：重复运行按当前设计重新生成并覆盖 review.md；设计修订后由下一次触发（fp-start 或单独触发）刷新。
- fp-start 核验发现 review.md 复制台账/设计正文或残留 `<...>` 占位符时，按缺失处理，修复来源设计后重新生成。
```

- [ ] **Step 2: 创建 `skills/fp-design-review/review-template.md`**

完整内容（逐字使用；本计划中用四个反引号包住含内部代码块的正文，写入文件时正文本身以第一个 `# Technical Design Review Entry Template` 开始、以最后一段说明结束，不含外层围栏）：

````markdown
# Technical Design Review Entry Template

Read this file only after `fp-design-review` resolved the canonical design artifacts and every merged Decision Ledger row is terminal; blocking conditions are owned by `SKILL.md`.

写入 `fp-docs/changes/<slug>/review.md`：change 根唯一评审入口，仅 small form，覆盖全部实际端。叙述性内容默认使用中文；代码、命令、路径、技术标识符、API 字段保留必要英文。

```markdown
# <功能描述> — 开发设计评审

> 评审导航摘要：事实以 Decision Ledger 与设计正文为准；本文件不得复制决策正文。

- **决策统计**：共 <N> 项（阻塞 <N> / 非阻塞 <N>），全部终态
- **数据变更**：<计数与 `design/<端>.md#锚点` 引用，或 `无`>
- **接口变更**：<计数与 `design/<端>.md#锚点` 引用，或 `无`>

## 评审关注点（按章节）

### <设计章节名>（`design/<端>.md#锚点`）
- [ ] <可评审的具体问题，例如字段取舍与迁移、索引是否满足查询、接口幂等、组件复用兼容性>

## 建议评审顺序

- <高风险章节在前，逐项列出章节与锚点>

## 建议抽查路径

- `<path:line>`、`<path:line>`

## 设计入口

- `design/00-index.md`
```

`review.md` 是评审导航摘要，不是决策记录、确认证据或 PRD/proposal/design/task artifact；它不改变任何 Decision Ledger 状态，也不复制台账或设计正文。评审关注点必须引用设计章节锚点，只提炼设计文档已有内容，不得编造；设计未涉及数据或接口变更时对应行显示 `无`。模板占位符替换规则与设计正文相同：`<...>` 占位符在最终产物中无效。
````

- [ ] **Step 3: 创建 `commands/fp-design-review.md`**

完整内容（11 行，≤20 行约束内）：

```markdown
---
description: 从已确认设计生成开发设计评审入口 review.md
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-design-review/SKILL.md`，将「$ARGUMENTS」作为 slug 输入；该 skill 与其 review-template.md 是完整事实源。

Gate checksum：

- 只从已核验的 canonical design 生成；设计缺失、dual form/historical path 或台账存在未终态行时阻塞并报告，不生成。
- 只写 change 根 `fp-docs/changes/<slug>/review.md`，仅 small form，覆盖全部实际端；不得复制决策正文或设计正文，不得编造。
- 不修改设计文件、Decision Ledger 或任何台账状态；不推进任何阶段。
- 生成后报告实际路径并展示评审入口摘要。
```

- [ ] **Step 4: README 命令表与 AGENTS.md 路由登记**

`README.md`：在 `| \`commands/fp-final-review.md\` | 归档前最终整分支只读审查 |` 行之前插入：

```markdown
| `commands/fp-design-review.md` | 从已确认设计生成开发设计评审入口 review.md；可由 fp-start 阶段 2 自动触发或单独刷新 |
```

`AGENTS.md`：在 `| Technical design | \`skills/fp-brainstorm/SKILL.md\` |` 行之后插入：

```markdown
| Design review entry for a confirmed design | `skills/fp-design-review/SKILL.md` |
```

- [ ] **Step 5: 运行 validate-plugin 验证自动发现约束**

Run: `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1`
Expected: PASS，末行 `FeaturePilot plugin validation passed: 12 commands, 21 skills, all SKILL.md files <= 500 lines, core prompt chars ...`。若失败，按消息修正新文件（常见：frontmatter、锚定指针、命令行数）。此步同时运行 AGENTS router 等子验证器，Task 1 不改其断言列表，新行不会引发失败。

- [ ] **Step 6: 运行 decision-gate 契约确认既有锚点未破坏**

Run: `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-decision-gate-contract.ps1`
Expected: 退出码 0，静默（本任务未改其断言）。

- [ ] **Step 7: Commit**

```bash
git add skills/fp-design-review commands/fp-design-review.md README.md AGENTS.md
git commit -m "feat: 新增 fp-design-review 设计评审入口 skill"
```

---

### Task 2: review.md 所有权迁移（fp-start 集成 ＋ fp-brainstorm 回滚）

**Files:**
- Modify: `skills/fp-start/SKILL.md:159`（WIP 的 review.md 确认行）
- Modify: `skills/fp-brainstorm/SKILL.md`（回滚 4 处 WIP 改动：行 35、章节标题与正文、行 177、行 183）
- Modify: `skills/fp-brainstorm/design-template.md`（删除 WIP 新增的 `## Review Summary (review.md)` 章节，即 "For frontend work..." 段落之后的全部内容）
- Modify: `scripts/test-decision-gate-contract.ps1`（删除两块 WIP 锚点、改写 fp-start 锚点）
- Modify: `scripts/validate-plugin.ps1:805`（brainstorm 锚点列表回滚）

**Interfaces:**
- Consumes: Task 1 创建的 skill 名 `fp-design-review`。
- Produces: fp-start 阶段 2 的委托措辞（含锚点 `fp-design-review`、`review.md`、`评审入口摘要`、`未复制决策正文`、`重新生成`），Task 3 的契约断言依赖这些锚点存在。

- [ ] **Step 1: 修改 `scripts/test-decision-gate-contract.ps1` 的三处断言**

1a. 删除整个 `design template review entry` 断言块（old_string 精确匹配）：

```powershell
Assert-Anchors $designTemplate @(
    'review.md',
    '# <功能描述> — 评审入口',
    '评审导航摘要',
    '不得复制决策正文',
    '风险清单',
    '建议评审顺序',
    '建议抽查路径',
    '只允许 small form'
) 'design template review entry'
```

1b. 删除整个 `fp-brainstorm review entry` 断言块：

```powershell
Assert-Anchors $brainstormSkill @(
    'review.md',
    '写入 review.md',
    '问答中提出的风险',
    '核验 review.md'
) 'fp-brainstorm review entry'
```

1c. 将 fp-start 断言行：

```powershell
Assert-Anchors $startSkill @('review.md', '未复制决策正文') 'fp-start review entry'
```

替换为：

```powershell
Assert-Anchors $startSkill @('fp-design-review', 'review.md', '评审入口摘要', '未复制决策正文', '重新生成') 'fp-start review entry'```

- [ ] **Step 2: 运行 decision-gate 确认进入预期 RED**

Run: `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-decision-gate-contract.ps1`
Expected: FAIL，消息 `fp-start review entry lost anchor: fp-design-review`（fp-start 尚未委托）。若消息不同，先核对 Step 1 编辑是否遗漏。

- [ ] **Step 3: 修改 `skills/fp-start/SKILL.md` 阶段 2 委托行**

将（当前 WIP 状态）：

```markdown
- 用工具确认 change 根存在 `review.md`，并向用户展示其评审导航摘要（决策统计、风险清单、建议评审顺序）；发现它复制了台账或设计正文时按缺失处理，return to the owning phase `fp-brainstorm` 定点修正。review.md 是导航摘要：未复制决策正文，不改变任何台账状态。
```

替换为：

```markdown
- 加载 `${CLAUDE_PLUGIN_ROOT}/skills/fp-design-review/SKILL.md` 生成 `fp-docs/changes/<slug>/review.md` 并向用户展示其评审入口摘要（决策统计、评审关注点、建议评审顺序）；生成阻塞或发现 review.md 复制了台账或设计正文时，修复来源设计后重新生成，不得编造。review.md 是评审导航摘要：未复制决策正文，不改变任何台账状态；它是 fp-start 的写入后产物确认步骤，不属于 `fp-brainstorm`。
```

- [ ] **Step 4: 回滚 `skills/fp-brainstorm/SKILL.md` 的 4 处 WIP 改动**

4a. 行 35，将：

```markdown
- 每次用户回答后，记录对应 decision ID、选择、Source 和 Evidence / explicit confirmation。generic confirmation does not resolve `needs-user-confirmation`；同一条消息可以确认多项，但必须逐一列出 ID 与选择。问答中提出的风险与疑虑要记录为风险清单素材（含对应 `D-NNN` 或主题引用），供写入 review.md 使用；不得事后编造风险。
```

替换为：

```markdown
- 每次用户回答后，记录对应 decision ID、选择、Source 和 Evidence / explicit confirmation。generic confirmation does not resolve `needs-user-confirmation`；同一条消息可以确认多项，但必须逐一列出 ID 与选择。
```

4b. 将章节标题与正文（两段）：

```markdown
#### Pre-write gate includes review.md

The explicit pre-write gate covers the selected form, exact target paths, `design/00-index.md` direct entries, `review.md` at the change root, and any obsolete path approved for removal. `review.md` uses the Review Summary section of `design-template.md`: 只允许 small form，覆盖全部实际端，不得复制决策正文。

未满足这些条件时，不得创建、覆盖或移除 `design/00-index.md`、任一 end small file、split index、fragment、`review.md` 或 obsolete path。
```

替换为：

```markdown
#### Pre-write gate includes design index

The explicit pre-write gate covers the selected form, exact target paths, `design/00-index.md` direct entries, and any obsolete path approved for removal.

未满足这些条件时，不得创建、覆盖或移除 `design/00-index.md`、任一 end small file、split index、fragment 或 obsolete path。
```

4c. 将 `【立即用工具执行】读取 ...design-template.md` 段首句：

```markdown
【立即用工具执行】读取 `${CLAUDE_PLUGIN_ROOT}/skills/fp-brainstorm/design-template.md`，按实际涉及端写入设计文件，并按其 Review Summary 章节写入 review.md。
```

替换为：

```markdown
【立即用工具执行】读取 `${CLAUDE_PLUGIN_ROOT}/skills/fp-brainstorm/design-template.md`，按实际涉及端写入设计文件。
```

4d. 在 Post-write handoff 的写入后核验段中，将：

```markdown
；转换时 obsolete path 已移除；核验 review.md 存在于 change 根、只含导航摘要且未复制决策正文。然后报告实际写入路径
```

替换为：

```markdown
；转换时 obsolete path 已移除。然后报告实际写入路径
```

- [ ] **Step 5: 删除 `skills/fp-brainstorm/design-template.md` 的 Review Summary 章节**

删除从 `## Review Summary (`review.md`)` 标题开始到文件末尾的全部内容（含两个围栏代码块和尾段说明），即保留到 `For frontend work, place the exact Visual Source / component mapping / Visual Checks sections ...` 段落为止。删除后文件以该段落结尾并保留一个换行。

- [ ] **Step 6: 回滚 `scripts/validate-plugin.ps1:805` 的 brainstorm 锚点列表**

将：

```powershell
foreach ($anchor in @('design/backend.md', 'design/backend/00-index.md', 'design/frontend.md', 'design/frontend/00-index.md', 'mutually exclusive', 'canonical entry', 'Pre-write gate includes review.md', 'explicit pre-write gate', 'exact target paths', 'review.md', '写入 review.md', '问答中提出的风险', '核验 review.md', 'Post-write handoff', 'Post-write verification rejects', 'incomplete manifests', 'duplicate visual ownership', 'Resume boundary', 'partial conversion', 'current slug', 'exact paths', 'historical', 'explicit approval', 'obsolete path')) {
```

替换为：

```powershell
foreach ($anchor in @('design/backend.md', 'design/backend/00-index.md', 'design/frontend.md', 'design/frontend/00-index.md', 'mutually exclusive', 'canonical entry', 'Pre-write gate includes design index', 'explicit pre-write gate', 'exact target paths', 'Post-write handoff', 'Post-write verification rejects', 'incomplete manifests', 'duplicate visual ownership', 'Resume boundary', 'partial conversion', 'current slug', 'exact paths', 'historical', 'explicit approval', 'obsolete path')) {
```

- [ ] **Step 7: 运行两个契约脚本验证 GREEN**

Run: `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-decision-gate-contract.ps1`
Expected: 退出码 0，静默。

Run: `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1`
Expected: PASS，`FeaturePilot plugin validation passed: 12 commands, 21 skills, ...`。

- [ ] **Step 8: Commit**

```bash
git add skills/fp-start/SKILL.md skills/fp-brainstorm/SKILL.md skills/fp-brainstorm/design-template.md scripts/test-decision-gate-contract.ps1 scripts/validate-plugin.ps1
git commit -m "refactor: review.md 所有权从 fp-brainstorm 迁移到 fp-start 阶段 2"
```

---

### Task 3: fp-design-review 专项契约锚点、路由断言与上下文预算

**Files:**
- Modify: `scripts/test-decision-gate-contract.ps1`（必需文件清单、读取、三个新锚点块）
- Modify: `scripts/validate-plugin.ps1`（`$skillAnchors` 注册 ＋ fp-start 委托断言）
- Modify: `scripts/measure-context.ps1`（Start ＋ StartWithExplore 计入新 skill）

**Interfaces:**
- Consumes: Task 1 的文件内容（锚点已在其中逐字落位）、Task 2 的 fp-start 委托措辞。
- Produces: 无运行时接口；契约脚本成为这三个文件的回归防线。

- [ ] **Step 1: `scripts/test-decision-gate-contract.ps1` 注册三个新 surface**

1a. 在 `$validatorPath = Join-Path $root 'scripts\validate-plugin.ps1'` 之后添加：

```powershell
$designReviewSkillPath = Join-Path $root 'skills\fp-design-review\SKILL.md'
$reviewTemplatePath = Join-Path $root 'skills\fp-design-review\review-template.md'
$designReviewCommandPath = Join-Path $root 'commands\fp-design-review.md'
```

1b. 在必需文件循环的 `@(...)` 列表中，`$validatorPath` 之后追加三项：`$designReviewSkillPath`、`$reviewTemplatePath`、`$designReviewCommandPath`。

1c. 在 `$validator = Read-Utf8 $validatorPath` 之后添加：

```powershell
$designReviewSkill = Read-Utf8 $designReviewSkillPath
$reviewTemplate = Read-Utf8 $reviewTemplatePath
$designReviewCommand = Read-Utf8 $designReviewCommandPath
```

1d. 在 Task 2 保留的 `Assert-Anchors $startSkill @('fp-design-review', ...) 'fp-start review entry'` 行之后添加三个块：

```powershell
Assert-Anchors $designReviewSkill @(
    'review.md',
    'review-template.md',
    'fp-docs/changes/<slug>/review.md',
    '评审关注点',
    '决策统计',
    '建议评审顺序',
    '建议抽查路径',
    'design/00-index.md',
    'manifest order',
    'canonical-first',
    '不得复制决策正文',
    '不得编造',
    '阻塞'
) 'fp-design-review skill'
Assert-Anchors $reviewTemplate @(
    '# <功能描述> — 开发设计评审',
    '评审导航摘要',
    '决策统计',
    '数据变更',
    '接口变更',
    '评审关注点',
    '建议评审顺序',
    '建议抽查路径',
    '设计入口',
    '不得复制决策正文',
    '不得编造'
) 'design review template'
Assert-Anchors $designReviewCommand @('fp-design-review', 'review.md', 'Gate checksum', '不得复制决策正文') 'commands/fp-design-review.md'
```

- [ ] **Step 2: 运行 decision-gate 验证锚点与内容一致**

Run: `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-decision-gate-contract.ps1`
Expected: 退出码 0，静默（Task 1 内容已含全部锚点）。若报 `lost anchor`，以断言为准修正 SKILL.md/模板措辞后重跑，不得放宽断言。

- [ ] **Step 3: `scripts/validate-plugin.ps1` 注册能力锚点与委托断言**

3a. 在 `$skillAnchors` 映射的 `'fp-brainstorm' = @(...)` 行之后添加：

```powershell
    'fp-design-review' = @('review-template.md', 'review.md', '评审关注点', '决策统计', '不得复制决策正文', 'design/00-index.md', 'manifest order', 'canonical-first', '阻塞')
```

3b. 在 `Assert-Condition ($startSkill.Contains('design/00-index.md') -and $startSkill.Contains('fp-plan')) 'fp-start is missing the post-write artifact confirmation boundary'`（约 958 行）之后添加：

```powershell
$designReviewSkillText = Read-Utf8 (Join-Path $root 'skills\fp-design-review\SKILL.md')
Assert-Condition ($startSkill.Contains('fp-design-review') -and $startSkill.Contains('review.md')) 'fp-start is missing the fp-design-review delegation for the design review entry'
Assert-Condition ($designReviewSkillText.Contains('fp-start') -and $designReviewSkillText.Contains('review-template.md')) 'fp-design-review is missing its fp-start integration and template ownership'
```

- [ ] **Step 4: 运行 validate-plugin 验证**

Run: `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1`
Expected: PASS，`FeaturePilot plugin validation passed: 12 commands, 21 skills, ...`。

- [ ] **Step 5: `scripts/measure-context.ps1` 计入新 skill**

在 `Start = $shared + (Get-Chars @('commands\fp-start.md', 'skills\fp-start\SKILL.md', ...))` 与 `StartWithExplore = $shared + (Get-Chars @('commands\fp-start.md', 'skills\fp-start\SKILL.md', ...))` 两个列表中，`'skills\fp-start\SKILL.md'` 之后各插入 `'skills\fp-design-review\SKILL.md'`。

- [ ] **Step 6: 运行 measure-context 确认预算生效**

Run: `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/measure-context.ps1`
Expected: 表格正常输出，无 `fp-explore skill exceeds guard` / `ExplorePublic exceeds guard` 异常；Start 行 CurrentChars 相比修改前增加（新 skill 计入），SavedChars 相应减少——这是预期，baseline 是历史参考值不调整。

- [ ] **Step 7: 三脚本终验**

Run: `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-decision-gate-contract.ps1; pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1; pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/measure-context.ps1`
Expected: 前两者退出码 0（decision-gate 静默、validate-plugin 输出 passed 哨兵），measure-context 输出表格无异常。

- [ ] **Step 8: Commit**

```bash
git add scripts/test-decision-gate-contract.ps1 scripts/validate-plugin.ps1 scripts/measure-context.ps1
git commit -m "test: 注册 fp-design-review 契约锚点与上下文预算"
```

- [ ] **Step 9:（可选，需用户确认）同步本地插件运行时**

仓库技能改动只在本仓库生效；如需让本机已安装的 Claude Code / Codex / DeepSeek Harness 插件运行时获得 `fp-design-review`，调用 `sync-plugin-runtimes` skill 同步。默认不执行，向用户报告后按其指示进行。
