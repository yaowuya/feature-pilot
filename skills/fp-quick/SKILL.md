---
name: fp-quick
description: 快速处理小型开发需求、轻量功能、局部 bugfix 或微调优化；适用于不需要 fp-start / FeaturePilot proposal-design-plan 文档链路的场景。使用时必须先加载 fp-propose 并复用其项目探索与需求澄清规则，但不生成 proposal.md 或 fp-docs/changes；如有阻塞疑问则向用户提问，如无疑问则直接输出内联实现计划并等待用户确认，确认后按计划实现与验证。
---
## FeaturePilot workspace and information layer

Before choosing output paths, commands, UI/backend rules, or workflow behavior:

1. Treat the target project repository root as the FeaturePilot project root, and look only for `fp-docs/` directly under that root.
2. If `fp-docs/manifest.md` exists, read it first.
3. Read only relevant settings and intel listed by the manifest.
4. If UI/frontend is involved and `fp-docs/settings/frontend.md` exists, read it as a required source.
5. If backend/API/data/security behavior is involved and `fp-docs/settings/backend.md` exists, read it as a required source.
6. Treat settings/intel as navigation and constraints; verify exact implementation facts against current code.
7. Use two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, backend framework, API envelope, or workflow policy in public skills. Customer-specific rules belong in target-project settings.

Compatibility rule: if the project root has no `fp-docs/manifest.md`, continue from current code and existing settings when safe, recommend `/fp-init`, and do not force initialization. If the current phase must write FeaturePilot artifacts, create only the necessary artifact directories under the project-root `fp-docs/`; do not create manifest/settings/intel except through `/fp-init`.
---

# FeaturePilot Quick

你正在处理一个小型开发需求。目标是在保持架构判断和代码质量的前提下，跳过 `fp-start` 的长文档流程，先摸清项目现状，再给出可执行计划，用户确认后实施。

## 适用边界

使用本 skill 处理：
- 局部页面/组件调整
- 小型接口、字段、校验、状态或文案变更
- 明确范围内的 bugfix
- 单一模块内的轻量能力补充

若需求涉及跨多个子系统的架构重塑、权限/数据模型大改、复杂异步流程、新业务域、长期规范沉淀，先说明风险并建议改走 `fp-start`。如果用户明确要求继续快速处理，则将范围收紧到可安全交付的最小切片。

## 工作流

### 1. 用 fp-propose 探索项目背景

不要先要求用户补充项目上下文。立即加载本插件内 `fp-propose` skill，并复用它的“探索项目现状”和“Socratic 需求澄清”规则来完成背景检索。

重要边界：
- 只使用 `fp-propose` 的探索和澄清部分。
- 不执行 `fp-propose` 的 proposal 生成阶段。
- 不创建 `fp-docs/changes/<slug>/`、`proposal.md`、`design.md` 或 `tasks.md`。

探索时至少完成：
1. 不检查、不生成项目索引；先读取 `fp-docs/settings/` 中存在的相关配置，小需求也必须以当前代码为实现事实来源。
2. 读取项目根目录或 `.claude/`、`.codex/`、`.agents/` 中的工程约束文件，例如 `CLAUDE.md`、`AGENTS.md`、`README.md`。
3. 使用 `rg` / `rg --files` 搜索需求关键词、页面文案、接口名、路由名、组件名、模型名、测试名。
4. 读取最可能相关的实现文件、测试文件和相邻同类代码，提炼现有模式。

读取 `fp-docs/settings/` 中与当前阶段相关的客户配置；不要读取历史 `fp-docs/changes/` 或 `fp-docs/archive/` 作为上下文依据。小需求必须以当前代码、测试和接口实现为准；若配置与代码冲突，以代码为准并向用户说明。

检索要聚焦，不要为了小需求全量阅读仓库。优先形成这些结论：
- 可能改动的文件和模块边界
- 已有可复用模式、组件、API 或测试写法
- 需求中仍不明确或可能有风险的点

### 2. 判断是否需要澄清

只有存在会改变实现方向的阻塞疑问时才提问，例如：
- 多种用户可见行为都合理
- 数据来源或接口契约不清
- 权限、兼容性、迁移、性能或安全边界不清
- 现有代码存在互相冲突的模式

提问规则：
- 每次最多问 1-3 个关键问题。
- 给出推荐选项和影响说明。
- 不问可以在实现中按现有模式自然决定的细节。

如果没有阻塞疑问，跳过提问，直接进入计划。

### 3. 输出内联实现计划

不要创建 `proposal.md`、`design.md`、`tasks.md`，也不要写入 `fp-docs/changes/`。

向用户输出简短实现计划并等待明确确认。计划必须包含：
- **背景判断**：从项目检索得出的关键事实。
- **改动范围**：预计修改/新增的文件。
- **实现步骤**：按可验证顺序列出。
- **验证方式**：测试、lint、构建、手工检查或浏览器验证。
- **风险与回退**：只列真实风险。

在用户确认前不要修改业务代码。用户回复“确认”“继续”“按这个来”等明确许可后再执行。

### 4. 按计划实现

执行时遵循项目现有模式：
- 优先补充或调整测试，再写实现；若需求不适合自动化测试，说明原因并提供替代验证。
- 后端按现有分层顺序修改：model/service/viewset/serializer/url/tests。
- 前端按现有工程约束修改；优先遵循项目现有前端框架、脚本/状态管理写法、项目配置的设计系统、组件和样式 token。
- 控制改动范围，不顺手重构无关代码。
- 遇到新阻塞时停下说明，不擅自扩大范围。

### 5. 验证并汇报

实现后运行与改动范围匹配的验证命令。最终汇报：
- 完成了什么
- 改了哪些关键文件
- 验证命令及结果
- 未验证项或残余风险

如果验证失败，先按失败信息修复；同一问题连续失败多次或需要产品决策时，再请求用户介入。
