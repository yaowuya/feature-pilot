# FeaturePilot 六条简明写作规则实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将用户的六条原文逐字纳入 FeaturePilot 文风契约，并让所有面向人阅读的文档只在实际输出时按需应用。

**Architecture:** `skills/_shared/document-style.md` 是六条规则的唯一内容所有者。`skills/_shared/workspace-rules.md` 只保存短的按需加载指针；现有 PRD、proposal、design、review 的门禁后加载方式保持不变。使用现有专项 PowerShell 契约测试保护原文、层级、触发时机与例外。

**Tech Stack:** Markdown 技能契约与文档；PowerShell 5.1/7 契约测试。

## Global Constraints

- 批准规格：`docs/superpowers/specs/2026-10-16-featurepilot-six-writing-rules-design.md`。
- 六条规则必须与用户原文逐字一致，包括“日常英语”和“粗鄙不堪”；不得翻译、缩写或调整标点。
- 范围是 FeaturePilot 新产出的面向人阅读的叙述性文档与文字报告，不批量改写既有文档。
- **仅实际准备输出文档或报告且适用门禁已通过时**加载文风契约；启动、意图判断、探索、访谈、只读检查、等待授权和无文档产出流程不预加载。
- 现有 PRD、proposal、design、review 的 JIT 顺序、结构、事实依据及写入授权保持不变。
- 代码、JSON/YAML 字段、日志原文、固定标题/表格 schema、Decision Ledger、路径和技术标识符继续受精确内容例外保护。
- 第六条不是修改已确认事实、模板 schema、授权或安全门禁的许可。六条作为写作与自检指导，不新增机械字数硬门禁。
- 保持 `scripts/test-document-style-contract.ps1` 的 UTF-8 BOM；命令适配器本次不修改。
- 不提交、不推送、不创建 PR、不同步本机插件运行时。

## 文件职责

| 文件 | 职责 |
| --- | --- |
| `skills/_shared/document-style.md` | 六条原文唯一所有者及原有优先级/例外 |
| `skills/_shared/workspace-rules.md` | 所有技能共享的输出前 JIT 指针，不复制规则全文 |
| `scripts/test-document-style-contract.ps1` | 原文精确匹配、层级、变异和 JIT 加载契约 |
| `docs/reference/commands-and-skills.md` | 面向用户说明覆盖所有 FeaturePilot 叙述性文档 |

---

### Task 1: 六条原文与按需加载

**Files:**
- Modify: `skills/_shared/document-style.md:3-105`
- Modify: `skills/_shared/workspace-rules.md:26-32`
- Test: `scripts/test-document-style-contract.ps1:250-365`

**Interfaces:**
- Consumes: 已有 `document-style.md` 的“建议遵守/精确内容例外”分层和 `workspace-rules.md` 的文档语言优先级。
- Produces: 共享契约中按序出现一次的六条原文，以及只在实际输出文档时触发的全技能 JIT 指针。

- [ ] **Step 1: 为六条原文加入失败测试**

在 `scripts/test-document-style-contract.ps1` 的 `Assert-DocumentStyleRuleLayers` 中取得 `$recommendedBody` 后，增加以下块：

```powershell
    $sixRules = @(
        '1. 不用陈词滥调：别用那些你在书报上见惯了的比喻和修辞。'
        '2. 能短就别长：一个短词能说清，就别用长词。'
        '3. 能删就删：只要删掉不影响意思，就果断删掉。'
        '4. 多用主动句：能用主动语态，就别用被动语态。'
        '5. 说人话：能用日常英语表达，就别用外来词、科学术语或行话。'
        '6. 别死守规则：如果遵守规则会导致说出粗鄙不堪的话，那就打破它。'
    )
    $sixRuleSection = Get-UniqueMarkdownSectionMatch $text '### 六条简明写作规则' $surface
    Assert-Condition ($sixRuleSection.Index -gt $recommended.Index -and $sixRuleSection.Index -lt $exceptions.Index) "$surface six rules must belong to recommendations"
    $sixRuleBody = $sixRuleSection.Groups['body'].Value
    Assert-OrderedAnchors $sixRuleBody $sixRules "$surface verbatim six rules"
    foreach ($rule in $sixRules) {
        Assert-Condition ([regex]::Matches($text, [regex]::Escape($rule)).Count -eq 1) "$surface must contain each exact rule once: $rule"
    }
    Assert-Condition ($sixRuleBody.Contains('不改变已确认事实、精确内容或写入门禁')) "$surface sixth rule may override confirmed content"
```

在 `$contract` 的现有变异测试后新增：

```powershell
$sixthRuleRemoved = Replace-Required $contract '6. 别死守规则：如果遵守规则会导致说出粗鄙不堪的话，那就打破它。' '6. 别死守规则。' 'sixth writing rule'
Assert-Condition (-not (Test-DocumentStyleRuleLayers $sixthRuleRemoved)) 'mutation survived: a six-rule sentence may be shortened'
$englishChanged = Replace-Required $contract '日常英语' '日常中文' 'the fifth rule original language'
Assert-Condition (-not (Test-DocumentStyleRuleLayers $englishChanged)) 'mutation survived: the fifth rule may be translated'
$rulesReordered = Replace-Required $contract '1. 不用陈词滥调：别用那些你在书报上见惯了的比喻和修辞。' '0. 不用陈词滥调：别用那些你在书报上见惯了的比喻和修辞。' 'the first rule numbering'
Assert-Condition (-not (Test-DocumentStyleRuleLayers $rulesReordered)) 'mutation survived: the six-rule order may change'
```

- [ ] **Step 2: 为 JIT 指针加入失败测试**

在 `Assert-DocumentStyleRuleLayers` 定义后添加：

```powershell
function Assert-DocumentOutputRoute([string]$text, [string]$surface) {
    $language = Get-UniqueMarkdownSectionMatch $text '## Process document language' $surface
    $jit = Get-UniqueMarkdownSectionMatch $text '## Document-style on-demand route' $surface
    Assert-Condition ($jit.Index -gt $language.Index) "$surface JIT route must follow document language"
    Assert-Anchors $jit.Groups['body'].Value @(
        '仅在实际准备输出面向人阅读的叙述性文档或文字报告时'
        '适用写入门禁通过后'
        '${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md'
        '读取输出模板前'
        '不在启动、意图判断、探索、访谈、只读检查或等待授权时预加载'
        '无文档产出时不读取'
        '同一工作流已加载时复用，不重复读取'
    ) "$surface JIT route"
}

function Test-DocumentOutputRoute([string]$text) {
    try {
        Assert-DocumentOutputRoute $text 'workspace route fixture'
        return $true
    } catch {
        return $false
    }
}
```

在 `$contract = Read-Utf8 $contractPath` 后读取并校验共享路由，并加负向变异：

```powershell
$workspace = Read-Utf8 'skills\_shared\workspace-rules.md'
Assert-DocumentOutputRoute $workspace 'shared workspace rules'
$earlyStyleLoad = Replace-Required $workspace '不在启动、意图判断、探索、访谈、只读检查或等待授权时预加载' '启动时预加载' 'the no-preload route'
Assert-Condition (-not (Test-DocumentOutputRoute $earlyStyleLoad)) 'mutation survived: style may load during startup'
$noGate = Replace-Required $workspace '适用写入门禁通过后' '写入门禁前' 'the write-gate route'
Assert-Condition (-not (Test-DocumentOutputRoute $noGate)) 'mutation survived: style may load before authorization'
```

- [ ] **Step 3: 确认新增测试先失败**

运行：

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-document-style-contract.ps1
```

预期：非零退出，明确指出缺少 `### 六条简明写作规则` 或 `## Document-style on-demand route`。

- [ ] **Step 4: 扩大共享契约范围，并逐字写入六条**

在 `skills/_shared/document-style.md` 中，将“本契约只适用于以下 logical artifact”及“不扩展到 task plan”替换为：

```markdown
本契约适用于 FeaturePilot 新输出的、面向人阅读的叙述性文档与文字报告，包括 PRD、proposal、design、review、task plan、执行记录、审查报告和项目信息文档。既有文档不批量改写。代码、结构化数据字段、日志原文和固定 schema 仍按下方的精确内容例外处理。
```

在 `## 建议遵守` 原有数字/排版建议后、`## 精确内容例外` 前新增：

```markdown
### 六条简明写作规则

1. 不用陈词滥调：别用那些你在书报上见惯了的比喻和修辞。
2. 能短就别长：一个短词能说清，就别用长词。
3. 能删就删：只要删掉不影响意思，就果断删掉。
4. 多用主动句：能用主动语态，就别用被动语态。
5. 说人话：能用日常英语表达，就别用外来词、科学术语或行话。
6. 别死守规则：如果遵守规则会导致说出粗鄙不堪的话，那就打破它。

六条规则作为叙述文字的写作和自检指导，原文不改写。第 5 条保留“日常英语”的原文，不改变既有中文默认语言规则；第 6 条不改变已确认事实、精确内容或写入门禁。
```

在 `## Document readability self-review` 的列表中将“语言”项扩展为：

```markdown
2. **语言**：按六条简明写作规则检查套话、词语长度、赘词、被动句与行话；段落主题、必要术语和指代是否清楚。只优化表达，遵守精确内容例外。
```

- [ ] **Step 5: 在共享工作区契约中加入 JIT 指针**

在 `skills/_shared/workspace-rules.md` 的 `## Process document language` 后、`## Evidence and precedence` 前加入：

```markdown
## Document-style on-demand route

仅在实际准备输出面向人阅读的叙述性文档或文字报告时，才按 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md` 加载共享写作规则。适用写入门禁通过后、读取输出模板前加载；直接展示的文字报告在形成内容前加载。同一工作流已加载时复用，不重复读取。不在启动、意图判断、探索、访谈、只读检查或等待授权时预加载；无文档产出时不读取。已具备 JIT 加载的 PRD、proposal、design 和 review 保留原顺序，不另行提前加载。
```

- [ ] **Step 6: 验证绿灯与负向变异**

运行：

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-document-style-contract.ps1
```

预期：退出码 `0`，输出 `Document-style contract validation passed.`；新增漏句、改词、改序、提前加载与未过门禁变异均被拒绝。

---

### Task 2: 用户说明与全量回归

**Files:**
- Modify: `docs/reference/commands-and-skills.md:93-99`
- Test: `scripts/test-document-style-contract.ps1:559-563`

**Interfaces:**
- Consumes: Task 1 的共享文风契约和 JIT 指针。
- Produces: 用户可见的适用范围说明，以及全量验证证据。

- [ ] **Step 1: 先更新用户说明测试**

将 `scripts/test-document-style-contract.ps1` 的 `$commandsReference` anchor 列表替换为：

```powershell
Assert-Anchors $commandsReference @(
    'FeaturePilot 生成面向人阅读的叙述性文档和文字报告'
    '六条简明写作规则'
    '仅在实际准备输出文档时按需加载'
    '共享文档风格契约'
) 'commands and skills reference'
```

- [ ] **Step 2: 确认文档测试先失败**

运行：

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-document-style-contract.ps1
```

预期：非零退出，指出 `commands and skills reference lost anchor`。

- [ ] **Step 3: 更新用户可见说明**

在 `docs/reference/commands-and-skills.md` 的“Figma 与设计评审”段落后，用以下完整文字替换旧的四类文档描述：

```markdown
FeaturePilot 生成面向人阅读的叙述性文档和文字报告时，统一遵循仓库内共享文档风格契约，包含用户给出的六条简明写作规则。仅在实际准备输出文档时按需加载，不在探索、访谈或只读检查阶段预读；既有事实、精确技术内容和固定 schema 不因文风而改变。
```

- [ ] **Step 4: 运行专项与相关回归**

分别运行并记录退出码与末行：

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-document-style-contract.ps1
```

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-prd-business-contract.ps1
```

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-prd-product-first-contract.ps1
```

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-design-review-contract.ps1
```

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-readme-docs-contract.ps1
```

每项预期退出码 `0`，末行分别含有自身的 `passed` 消息。

- [ ] **Step 5: 运行全量与预算检查**

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
```

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/measure-context.ps1
```

预期均退出 `0`；`validate-plugin.ps1` 输出 `FeaturePilot plugin validation passed`。`measure-context.ps1` 的历史对比行是信息性指标；`fp-explore` 和 `ExplorePublic` 的两个守卫必须通过。

- [ ] **Step 6: 核对差异与范围**

```bash
git diff --check
```

```bash
git status --short
```

预期没有空白错误，改动只涉及规格、计划和本计划列出的四个实施/测试文件。不得提交、推送、创建 PR 或同步已安装插件运行时。
