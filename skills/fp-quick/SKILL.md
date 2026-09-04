---
name: fp-quick
description: 快速处理小型开发需求、轻量功能、局部 bugfix 或微调优化；适用于不需要 fp-start / FeaturePilot proposal-design-plan 文档链路的场景。使用时必须先加载 fp-explore 的 quick profile 获取候选文件、复用模式、验证路径、风险和范围证据，不生成 proposal.md 或 fp-docs/changes；如有阻塞疑问则每轮最多问一个实质性问题，如无疑问则输出内联实现计划并等待用户确认，确认后按计划实现与验证。
---
## FeaturePilot workspace and information layer

If any anchored plugin resource is missing or unreadable, stop, report the exact resource and an incomplete FeaturePilot installation/cache, and never search the consumer repository for `skills/**` or continue without it.
下文以 `${CLAUDE_PLUGIN_ROOT}/...` 表示 Claude Code 安装后的插件资源。在 Codex/Markdown 中，从 available-skill 元数据提供的当前技能入口映射同一个 `skills/...` 插件相对路径。两端都不得在消费者项目中搜索插件文件。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.
If `<project-root>/.codegraph/` exists, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/codegraph.md` once and preserve its write-invalidation contract.
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

### 1. 用 fp-explore quick 探索项目背景

使用当前运行时原生技能机制加载一次 `fp:fp-explore`，然后向其 `quick` profile 提供下方结构化块。加载顺序如下：如果运行时提供可调用的 `Skill` tool，直接调用 `fp:fp-explore`；否则，如果运行时的 `available skills` 元数据列出了 `fp:fp-explore` 及其 `SKILL.md` 入口路径，就从该路径读取已安装的 FeaturePilot 分发目录中的完整技能说明并严格执行。只有两种机制都无法解析或读取 `fp:fp-explore` 时，才报告插件可用性或安装失败，并停止 quick 流程。不得搜索消费者项目来寻找回退，也不得直接读取消费者项目中的 `skills/fp-explore/SKILL.md`；不要为了探索而加载完整的 `fp-propose` skill；无产物和实现前确认门禁保持不变。

<!-- fp-explore-invoke
profile: quick
objective: Locate candidate files, module boundaries, reusable code and test patterns, verification paths, implementation blockers, and quick-flow suitability evidence for this requested small change.
caller: fp-quick
active-slug:
caller-owned-context:
  - current user request and already confirmed constraints
scope-include:
  - user-named files, symbols, routes, APIs, models, components, and tests
scope-exclude:
  - fp-docs/changes/, archive/, and history/
budget-profile: small
return-shape: profile-default
external-research: not-authorized
approved-research-boundary:
-->

Use `quick-candidate-files`, `quick-reusable-patterns`, and `quick-verification` to build the inline plan. Treat `quick-scope-assessment` as advisory evidence only; `fp-quick` retains the final suitability decision. Keep current source and tests as the implementation truth and preserve the no-FeaturePilot-artifact boundary.

读取 `fp-docs/settings/` 中与当前阶段相关的客户配置；不要读取历史 `fp-docs/changes/` 或 `fp-docs/archive/` 作为上下文依据。小需求必须以当前代码、测试和接口实现为准；若配置与代码冲突，以代码为准并向用户说明。

检索必须聚焦，搜索优先于整文件读取，不要为了小需求全量阅读仓库。

### 2. 判断是否需要澄清

只有存在会改变实现方向的阻塞疑问时才提问，例如：
- 多种用户可见行为都合理
- 数据来源或接口契约不清
- 权限、兼容性、迁移、性能或安全边界不清
- 现有代码存在互相冲突的模式

提问规则：
- Ask at most one substantive question per turn. If multiple decisions are genuinely inseparable, express them as one structured choice rather than a list of separate questions.
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

首次写入源码、测试、配置、schema 或生成器输入后，将当前图状态标记为 `dirty-after-write`，并 `never query a dirty graph`；剩余定位只使用当前源码搜索。项目在写入前已有 `.codegraph/` 时，在最终汇报或任何写入后的阻塞返回前执行一次 `post-write-sync`：

```text
codegraph sync <project-root> --quiet
```

不再运行 `status`，不提交索引变化。同步失败只记录一次原因，`must not block completion`、验证或汇报；项目原本没有图时不得隐式建图。

### 5. 验证并汇报

实现后运行与改动范围匹配的验证命令。最终汇报：
- 完成了什么
- 改了哪些关键文件
- 验证命令及结果
- CodeGraph `post-write-sync` 的执行、跳过或失败状态
- 未验证项或残余风险

如果验证失败，先按失败信息修复；同一问题连续失败多次或需要产品决策时，再请求用户介入。
