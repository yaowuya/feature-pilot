# FeaturePilot 紧凑产物与中文输出设计

## 背景

当前产物布局契约采用 semantic-first 选择：只要确认内容包含多个可独立阅读的功能、子系统、页面区域、任务组或 ownership domain，Producer 就选择 split form。`dangerous-script-detection` 的 proposal 虽然总计约 8 KB，但覆盖规则模型与 API、管理页面、快速执行、上线审批和安全审计，因此被拆成索引和五个分片。500 行与 30,000 字符仅作为继续拆分的硬上限，并不会阻止小文档提前拆分。

当前共享工作区契约也没有规定过程文档的默认语言。部分输出模板使用英文标题、表头和示例，目标项目设置没有补充语言要求，因此设计正文可能整体沿用英文。

## 目标

1. PRD、proposal、单端 design 和单端 plan 在未达到硬限制时默认保持单文件。
2. 只有预计单文件超过 500 行或 30,000 字符、用户明确要求拆分，或目标项目配置明确要求拆分时，才选择 split form。
3. FeaturePilot 生成的过程文档默认使用中文；代码、命令、文件路径、技术标识符、API 字段和规范要求保持原样的 schema 关键词可以使用英文。
4. 用插件验证脚本约束共享契约、生产者技能、模板和公开说明，避免规则再次漂移。

## 非目标

- 不迁移或重写已经生成的客户项目产物。
- 不改变 small form 与 split form 的互斥路径、manifest schema、Consumer 解析顺序或历史结构冲突规则。
- 不降低 500 行和 30,000 字符的文件硬上限。
- 不对 Markdown 正文进行机械翻译或语言比例检测。

## 方案

### 1. 紧凑优先的 form 选择

共享 `artifact-layout.md` 是唯一规范来源。Producer 在写入前先估算完整逻辑产物：

- 默认选择 small form。
- 预计 small form 会超过任一硬限制时，必须按语义边界选择 split form。
- 用户明确批准 split form 或目标项目设置明确要求拆分时，可以在硬限制以内选择 split form。
- “存在多个功能、子系统、页面区域、任务组或 ownership domain”只负责指导分片边界，不再单独触发拆分。

各阶段 skill、模板、命令摘要和公开文档必须引用或复述同一决策，不得继续声明 semantic-first 自动拆分。

### 2. 默认中文输出

共享 `workspace-rules.md` 增加过程文档语言契约，所有加载该共享规则的 FeaturePilot skill 都受其约束：

- 用户没有指定其他语言、目标项目设置也没有更高优先级要求时，过程文档的标题、说明、决策、需求、任务描述、验收说明和审查结论使用中文。
- 代码、命令、路径、包名、类名、函数名、变量名、API 字段、协议词、标准术语以及规范要求精确匹配的 schema 标题或枚举值保留必要英文。
- 用户的当前明确指令优先于默认语言；目标项目设置可以覆盖默认值，但不能覆盖当前用户指令。

PRD、proposal、design、plan 和 review 等直接生产过程文档的 skill/template 同时增加就近提醒，降低模型只看到局部模板时漏掉共享规则的风险。

### 3. 验证策略

先向 `scripts/validate-plugin.ps1` 增加失败断言，再修改契约：

- 共享工作区规则必须包含默认中文、覆盖优先级和必要英文例外。
- 共享布局规则必须包含 small form 默认、三种 split 触发条件，并明确多个语义域本身不触发拆分。
- PRD、proposal、design、backend plan 和 frontend plan 的主要生产者及模板必须包含紧凑优先锚点。
- 主要过程文档生产者必须包含中文输出锚点。
- 公开说明不得继续声称只要存在多个语义域就自动选择 split form。

运行 `scripts/validate-plugin.ps1`、`scripts/test-artifact-layout.ps1`、`scripts/test-explore-contract.ps1` 和 `scripts/test-sdd-benchmark-fixture.ps1`。结构验证器语义不变，因此其既有 small/split、互斥、manifest 和文件大小测试应全部继续通过。

## 风险与回退

- 接近 500 行的单文件可能较长，但比无条件拆成多个很小分片更容易浏览；用户和项目配置仍可明确选择拆分。
- 提示词契约无法保证任意模型输出百分之百符合中文要求，因此通过共享规则、就近模板和验证锚点三层约束降低漂移风险。
- 若新默认导致特定项目文档过长，可在该项目设置中明确要求 split form，无需恢复全局 semantic-first 行为。

## 验收标准

- 一个包含多个子系统但预计不超过硬限制的 proposal 默认写入 `proposal.md`。
- 后端或前端设计在预计不超过硬限制时分别默认写入 `design/backend.md` 或 `design/frontend.md`。
- 过程文档叙述性内容默认使用中文，必要代码和技术标识符保留英文。
- 所有插件和 artifact-layout 回归验证通过。
