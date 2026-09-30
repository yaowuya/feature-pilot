# FeaturePilot 研发评审文档质量改进设计

## 背景

当前 `fp-design-review` 只要求生成“导航摘要＋评审关注点”。模板主要是复选框清单，无法稳定产出研发工程师可独立阅读的评审文档。

本次在真实报告插件设计评审中暴露了以下问题：

1. 评审者需要先阅读完整设计，才能理解方案主线。
2. 数据模型只有字段清单时，无法直观看到最终库表结构。
3. 设计没有充分核验目标项目的公共基类、字段常量、索引、软删除和审计惯例。
4. 评审阶段补充设计事实，会造成 `review.md` 与 canonical design 不一致。
5. 抽象选项缺少背景和后果说明，用户无法判断每个选择会改变什么。
6. 复选框过多、术语过多和内容重复会降低评审效率。
7. PRD、proposal、design 和 review 尚未共享一套可执行的中文技术文档写作契约。现有规则分散在各模板中，难以稳定保证文档易懂、易读和易扫读。

## 已确认决策

1. 采用全链路改进：同时完善提问规范、设计阶段、评审阶段和契约测试。
2. 数据模型的项目规范调查由 `fp-brainstorm` 在设计阶段完成。
3. `fp-design-review` 只核对 canonical design 是否足够生成评审文档，不重新设计或修改设计。
4. 通用规则适用于所有技术栈；Django 等技术栈使用条件化专项检查。
5. “需求文档”同时包含 `fp-prd` 生成的 PRD 和 `fp-propose` 生成的 proposal；统一写作契约还适用于 design 和 review。
6. 新增仓库内共享写作契约，由 PRD、proposal、design 和 review 的 skill 与模板共同消费，避免在各处复制整套规则。
7. 写作要求分为“必须遵守”“建议遵守”和“精确内容例外”。结构、语义清晰和基础排版属于必须项；句长等数值目标不实现为脆弱的逐字计数门禁。
8. 共享契约以 [ruanyf/document-style-guide](https://github.com/ruanyf/document-style-guide) 的本地基线 `5719517` 为来源。上游 README 标明其内容属于 public domain。FeaturePilot 只保留适合研发文档的自包含规则快照，不在运行时读取 `D:\01-code\document-style-guide`，也不自动跟随上游变化。
9. 不同步本机已安装插件运行时，不执行 Git 提交，除非用户后续明确要求。

## 目标

1. 让 `review.md` 成为研发经理和研发工程师可以独立阅读的技术评审文档。
2. 在设计阶段完成项目规范核验，避免评审阶段才发现模型字段遗漏。
3. 让数据模型通过接近实现的代码、物理存储和约束说明直接可评审。
4. 保持 `fp-brainstorm` 是唯一设计所有者，避免 `fp-design-review` 成为第二个设计器。
5. 让 FeaturePilot 的决策问题说明背景、实际影响和选项后果。
6. 让 PRD、proposal、design 和 review 使用同一套读者优先、层次清楚、表达简洁的中文技术文档规则。
7. 在不改变已确认事实、技术契约和固定 schema 的前提下，减少长句、重复表达、模糊指代和无必要术语。
8. 用契约测试防止技能、模板和共享写作契约退化。

## 非目标

- 不改变 Decision Ledger 的状态集合或逐项确认门禁。
- 不让 `fp-design-review` 修改 `proposal.md`、`design/` 或 Decision Ledger。
- 不让评审阶段重新扫描整个代码库或重新做架构设计。
- 不把 Django 专项规则强制应用到其他技术栈。
- 不改变 canonical artifact layout。
- 不增加 `review.md` split form；它仍是 change 根单文件。
- 不把共享写作契约扩展到 tasks、执行进度、原型 evidence 或其他未明确纳入的产物。
- 不完整镜像上游文档手册，也不引入本机绝对路径或网络运行时依赖。
- 不用机械句长、字数或标点计数替代语义审阅。
- 不为改善文风而改写代码、命令、路径、URL、API 字段、固定模板 schema 或用户原文。

## 职责与数据流

### 共享文档风格契约

新增 `skills/_shared/document-style.md`，作为 PRD、proposal、design 和 review 的共享表达与排版契约。该文件记录上游来源、基线、适用范围、强制规则、建议规则、精确内容例外和统一自检流程。

四个产物 skill 都在各自已有的访谈、Decision Ledger、设计充分性或写入授权门禁通过后，读取输出模板之前按需加载该契约。访谈和架构问答阶段不提前加载整份写作规则，以免挤占决策上下文。

共享契约只规范表达，不拥有以下内容：

- 产品范围、业务规则和验收标准。
- proposal、design 或 review 的技术结论。
- 固定章节、表格列、Decision Ledger 和 canonical artifact layout。
- 现有产物的创建、覆盖、转换或删除授权。

当写作规则与精确语义或固定 schema 冲突时，保留精确语义和 schema，并只对周围说明文字应用写作规则。

**必须遵守：**

1. 文档开头先说明目的、范围、方案主线或结论，再展开细节。
2. 标题不得跳级，也不得与直接上级重名。标题最多四级，并优先控制在三级以内；固定模板要求的四级标题可以保留。
3. 除固定 schema 外，避免创建只有一个子标题的孤立层级。
4. 一个段落只表达一个主题，中心句尽量放在段首。每段不超过 7 行，段落之间保留一个空行。
5. 优先使用短句、简单句、主动语态和肯定表达。避免双重否定、“一逗到底”和指代不明。
6. 必要术语第一次出现时使用直白中文解释。不使用冷僻、生造或只有作者能理解的缩写。
7. 中文与英文或技术标识符之间保留一个半角空格。中文句子使用全角标点，完整英文句子使用半角标点。
8. 标题末尾不使用句号、逗号、分号或冒号。同一 logical artifact 内的中文与数字空格、数值、单位、百分比和范围写法保持一致。
9. 正文解释原因与结论，表格承载结构化比较，列表承载并列事项，代码块保留精确实现或示例。同一事实不得在多种载体中重复描述。
10. 引用第三方文字、图片或规范时标明来源。

**建议遵守：**

- 普通叙述句优先控制在约 20 个汉字；超过 40 个汉字时优先拆句。
- 优先使用三级以内标题和 4 行以内段落。
- 4 位以上数值优先使用千分位；数值范围两端都写单位或百分号。
- 中文并列项的最后一项优先使用“和”连接，使句子更自然。

这些数值是生成与人工自检目标，不作为逐字计数失败条件。

**精确内容例外：**

以下内容不得为满足写作规则而改写：

- 代码、命令、路径、URL、哈希和 API 字段。
- 类名、函数名、数据库字段和其他精确技术标识符。
- 固定模板标题、表格列名和 Decision Ledger schema。
- 用户原文、错误消息和需要精确引用的第三方内容。

例外只豁免精确片段，不豁免周围解释文字。样式修复不得改变已确认需求、技术结论、字段含义或决策状态。

### 各产物适配

**PRD：**

- 保持 product-first 契约和固定六章结构。
- 每个功能先说明用户、问题、价值和业务结果，再说明规则、交互与异常。
- 固定四级标题属于明确例外。
- 不因追求短句而拆散完整业务规则或引入实现语言。

**Proposal：**

- `Why` 先说明痛点、目标和现在为什么要做。
- 每个 `What Changes` 小节只承载一个变更主题。
- `Impact` 中的精确路径和技术标识符不得中文化或模糊化。

**Design：**

- 先给出架构主线和已确认决策，再展开数据、接口、状态与前端细节。
- 首次出现的必要术语附直白解释。
- 模型代码、表格和正文不得重复表达同一事实。
- 精确契约、字段、代码和 Decision Ledger 不因样式规则而变形。

**Review：**

- 第一段直接给出评审结论。
- 先展示业务与技术主线，再展示局部评审细节。
- 复选框只用于验证项和最终结论。
- 继续执行 `500` 行和 `30,000` 字符限制。

### 决策问题

`skills/_shared/decision-ledger.md` 增加“可理解的决策问题”契约。每个需要用户选择的问题必须包含：

1. 为什么现在需要这个决定。
2. 该决定会影响哪些产物或运行行为。
3. 每个选项采用后的实际行为。
4. 每个选项的主要代价或风险。
5. 推荐选项及推荐理由。
6. 以业务或行为结果命名的选项标签。

禁止只提供“方案 A”“双层核验”“职责边界”等需要用户自行解码的标签。用户表示不理解时，必须先用直白语言解释，再重新提问；不得把未理解的回答视为确认。

### 设计阶段

`fp-brainstorm` 是技术设计的唯一所有者。变更涉及数据库模型时，它必须先读取目标项目的真实代码，再展示和确认模型设计。

设计调查至少覆盖：

- 目标模型、公共基类、manager、mixin 和相邻版本模型。
- 字段长度常量、字段类型和序列化惯例。
- 显式字段与继承字段，避免重复存储。
- 逻辑模型与实际物理表。
- `null`、`blank`、默认值、索引、联合约束和排序。
- 审计、软删除和软删除后的唯一性含义。
- 发布、下线、调试等生命周期数据的归属。
- 模型元数据变化是否产生没有实际数据库收益的迁移。

字段级数据库设计优先给出接近实现的模型代码。代码、表格和说明各自承担不同职责，不能重复描述同一内容。

设计正文必须记录当前项目证据路径和最终结论。任何无法由当前代码证明的新选择仍进入 Decision Ledger，并由用户确认。

### 评审阶段

`fp-design-review` 仍是 canonical design 的只读消费者。它不读取代码来重新判断模型，也不直接修改设计。

生成前先执行设计充分性检查。数据模型范围至少应包含：

- 完整字段定义或接近实现的模型代码。
- 继承字段和重复存储结论。
- 逻辑模型与物理表映射。
- 关联、索引、唯一约束和软删除规则。
- 项目规范证据。
- migration 影响。

若信息不足，技能不生成或覆盖 `review.md`。它输出缺失项、需要修订的精确设计章节，以及返回 `fp-brainstorm` 的说明。设计定点修订并重新确认后，才重新生成评审文档。

## review.md 输出契约

### 固定主线

以下章节按实际范围生成；不适用章节直接省略：

1. **评审结论**：首段给出建议结论，并用短表格展示决策、数据、接口、前端与不做事项。
2. **业务和技术主线**：展示完整流程、核心对象及各自职责。
3. **数据模型评审**：展示模型代码、物理表、继承字段、逻辑关联、约束和字段取舍。
4. **状态、并发和执行流程**：仅在设计涉及这些内容时生成。
5. **接口、权限和旧入口隔离**：按职责分组，说明主键、权限和兼容边界。
6. **前端方案**：仅在存在前端范围时生成。
7. **主要风险、迁移、发布和验证**：风险必须给出具体失败场景与处理方式；验证项必须可执行。
8. **评审顺序、抽查代码和结论记录**：高风险优先，路径可定位，结论包含通过、有条件通过和退回修改。

### 写作规则

`review.md` 先遵守 `skills/_shared/document-style.md`，再遵守以下评审专项规则：

- 第一段直接给出结果，主线先于细节。
- 使用完整、简短的中文句子；中文与英文之间保留空格。
- 避免无必要的新术语；第一次出现的必要术语给出直白解释。
- 标题最多三级；段落不超过 7 行。
- 复选框只用于验证项和最终评审结论，不把正文写成复选框清单。
- Decision Ledger 只统计，不复制任何台账行。
- 不机械照抄设计正文。
- 模型代码等最适合直接评审的内容可以从已确认设计精确摘录，但不得改变或补充字段。
- 数据表格、代码和解释不得重复表达同一事实。
- 设计入口只保留一处。
- `review.md` 不超过 500 行或 30,000 字符。超限时先去重并链接设计细节；仍超限则阻塞，不生成截断文档。

## 技术栈专项检查

### 通用检查

任何持久化技术都检查：

- 字段、继承内容和物理存储。
- 关联、约束、索引和查询模式。
- 审计、软删除和生命周期数据。
- schema 或 migration 影响。
- 目标项目已有惯例与证据路径。

### Django 条件化检查

仅在目标项目使用 Django 且本次涉及模型时检查：

- 公共 `Model`、manager 和 mixin 已提供的字段与查询行为。
- abstract、proxy 和 multi-table inheritance 创建的物理表。
- `verbose_name` 是否符合当前项目惯例。
- `choices` 是否进入 migration state。选项经常变化时，设计必须明确是在模型层接受迁移，还是由 serializer/service 校验；技能不得擅自统一选择。
- `JSONField`、文本字段或压缩字段是否符合数据体积与读取方式。
- 联合索引左前缀是否已覆盖单列查询，避免重复索引。
- 软删除记录是否继续占用唯一约束，以及该行为是否符合业务含义。

非 Django 项目只执行对应 ORM 与 schema migration 检查，不生成 Django 专属内容。

## 失败处理

### 设计充分性不足

设计信息不足时，`fp-design-review` 输出具体缺口，不写入半成品。例如：

```text
无法生成 review.md：后端数据模型设计信息不足。

缺失内容：
1. ReportPluginVersion 的完整字段定义。
2. 代理模型对应的物理表说明。
3. 公共 Model 继承字段及是否重复存储的结论。
4. choices 变化的 migration 影响与最终校验层选择。

应修订：
- design/backend.md#数据模型

返回：
- fp-brainstorm，对上述章节做定点修订并重新确认设计。
```

禁止只输出“设计不完整”或“请补充信息”。

### 文档可读性自检失败

每个产物模板增加统一的 `Document readability self-review`，对按 manifest 顺序解析的完整 logical artifact 执行结构、语言、排版和例外检查。

- 拆分长句、补空格、明确指代、解释术语和删除重复说明等纯表达问题，可以依据已确认内容直接修复。
- 修复可能改变范围、业务规则、技术结论、字段含义、固定 schema 或 Decision Ledger 时，不得自动改写。
- 精确内容只需记录适用例外；原文自身存在语义歧义时，返回对应内容所有者重新确认。
- 样式检查不得绕过写入授权，也不得成为覆盖现有产物的额外授权。
- split form 同时检查每个文件的局部结构和 manifest 顺序下的完整 logical artifact。

## 文件改动

| 文件 | 改动 |
| --- | --- |
| `skills/_shared/document-style.md` | 新增共享写作契约、来源基线、规则分层、精确内容例外与统一自检 |
| `skills/_shared/decision-ledger.md` | 增加可理解问题契约 |
| `skills/fp-prd/SKILL.md` | 在写入门禁后、读取模板前按需加载共享写作契约 |
| `skills/fp-prd/prd-template.md` | 增加 PRD 可读性要求和 `Document readability self-review`，不改变固定六章结构 |
| `skills/fp-propose/SKILL.md` | 在写入门禁后、读取模板前按需加载共享写作契约 |
| `skills/fp-propose/proposal-template.md` | 增加 proposal 可读性要求和统一自检 |
| `skills/fp-brainstorm/SKILL.md` | 增加项目模型规范调查，并在写入门禁后按需加载共享写作契约 |
| `skills/fp-brainstorm/design-template.md` | 增加模型代码、物理存储、继承字段、约束、迁移要求和统一自检 |
| `skills/fp-design-review/SKILL.md` | 增加充分性门禁、完整评审输出、失败恢复和共享写作契约加载 |
| `skills/fp-design-review/review-template.md` | 改为独立可读、按范围生成的完整模板，并增加统一自检 |
| `commands/fp-prd.md` | 更新共享写作契约 Gate checksum |
| `commands/fp-start.md` | 更新 proposal、design 和 review 路由的 Gate checksum |
| `commands/fp-design-review.md` | 更新评审质量与共享写作契约 Gate checksum |
| `scripts/test-document-style-contract.ps1` | 新增共享写作契约专项测试 |
| `scripts/test-decision-gate-contract.ps1` | 更新共享提问、设计与评审锚点 |
| `scripts/validate-plugin.ps1` | 更新能力锚点并调用新增专项测试 |
| `scripts/test-design-review-contract.ps1` | 新增设计评审专项契约测试 |
| `docs/reference/commands-and-skills.md` | 更新用户可见说明，说明四类文档统一遵循可读性契约 |

如 README 只有简短命令索引且现有说明仍准确，则不修改 README。

## 契约测试

### 共享文档风格契约

新增 `scripts/test-document-style-contract.ps1`，至少验证：

- 共享契约包含上游 URL、public-domain 说明和基线 commit。
- 共享契约明确区分“必须遵守”“建议遵守”和“精确内容例外”。
- 共享契约包含结构、段落、句子、术语、空格、标点、数字、信息载体和来源规则。
- `fp-prd`、`fp-propose`、`fp-brainstorm` 和 `fp-design-review` 都在各自门禁通过后、读取模板前加载共享契约。
- 四个输出模板都包含 `Document readability self-review`。
- PRD 固定六章、必需四级标题和表格列不被样式规则破坏。
- Proposal、design 和 review 的既有 schema、Decision Ledger 与 canonical layout 不被样式规则改变。
- 代码、命令、路径、URL、API 字段和精确技术标识符属于明确例外。
- split form 按 manifest 顺序检查完整 logical artifact。
- 句长建议没有变成逐字计数硬门禁。
- 运行时 skill、模板和 command 不包含 `D:\01-code\document-style-guide` 绝对路径依赖。
- `validate-plugin.ps1` 调用该专项测试。

### 设计评审契约

新增 `scripts/test-design-review-contract.ps1`，至少验证：

- `fp-brainstorm` 包含项目模型规范调查规则。
- `design-template.md` 要求模型代码、物理存储、继承字段和迁移影响。
- `fp-design-review` 包含设计充分性门禁和明确返回格式。
- `review-template.md` 包含评审结论、主线、核心对象、模型代码、物理表、状态、接口、权限、风险、迁移、验证、评审顺序、抽查路径和结论记录。
- 模板没有把整个正文设计成复选框清单。
- 模板只有一个设计入口。
- 模板明确禁止复制 Decision Ledger。
- 模板允许精确摘录已确认模型代码，但禁止自行补字段。
- skill 与模板满足 500 行限制。
- 命令适配器满足 20 行限制。

更新现有契约脚本，使新增规则成为插件全量验证的一部分。

## 验证

实施后运行：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-document-style-contract.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-design-review-contract.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-decision-gate-contract.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-prd-business-contract.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-prd-product-first-contract.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/test-readme-docs-contract.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/measure-context.ps1
```

每条命令必须报告实际退出状态。任何失败都在报告中保留，不得宣称验证通过。

## 成功标准

1. 决策问题不再使用无法理解实际后果的抽象标签。
2. PRD、proposal、design 和 review 统一消费仓库内共享写作契约，不依赖本机绝对路径。
3. 非研发读者可以只看 PRD，说明用户、问题、范围、业务流程、规则、异常和结果。
4. 研发读者可以独立阅读 proposal、design 和 review，先理解主线与结论，再进入实现细节。
5. 四类文档的段落主题单一，术语和指代清楚，普通叙述以短句、主动语态和肯定表达为主。
6. 标题、空格、标点、数字和单位风格一致；正文、表格、列表与代码各自承担不同职责。
7. 风格优化不改变已确认事实、业务规则、技术契约、固定 schema、Decision Ledger 或 canonical layout。
8. 涉及数据模型的设计包含项目规范证据、模型草图、物理存储和迁移影响。
9. 设计信息不足时，`fp-design-review` 明确阻塞并返回设计阶段。
10. `review.md` 可以独立说明方案主线，并提供可直接评审的模型代码和风险结论。
11. Django 专项检查只在适用时启用，且不擅自规定所有项目都禁用 `choices`。
12. 全部契约测试、插件验证和上下文预算检查通过。
13. 未经用户明确要求，不提交 Git、不推送、不同步本地插件运行时。
