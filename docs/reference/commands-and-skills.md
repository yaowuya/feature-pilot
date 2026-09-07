# FeaturePilot 命令与技能参考

FeaturePilot 的公开入口按“你现在要解决什么问题”组织。Claude Code 使用 `/fp-*` 命令；Codex 与 DeepSeek Harness 把这些名称当作工作流标签，并加载对应的 `fp:*` skill。

命令文件是薄入口，真正的流程、门禁和恢复规则由 `skills/` 中的同名 skill 负责。本文帮助人选择入口，不替代运行时契约。

## 从你的问题出发

| 我现在需要…… | 推荐入口 | 结果 |
|---|---|---|
| 快速了解仓库现状、调用链或方案差异 | `fp-explore` | 只读事实与选项，不推进开发流程 |
| 把复杂概念讲给零基础读者 | `fp-eli5` | 直接展示中文图解，默认不写仓库 |
| 初始化或刷新 FeaturePilot 工作区 | `fp-init` | 最小 `fp-docs/manifest.md`，其他信息按批准创建 |
| 把模糊想法澄清成 PRD | `fp-prd` | 经访谈和确认的 PRD；UI-heavy 场景可先做原型 |
| 从 PRD 或需求启动完整开发 | `fp-start` | 提案、设计、计划、执行、终审与归档主线 |
| 快速完成一个小而明确的修改 | `fp-quick` | 跳过完整文档链，但保留探索、确认与验证 |
| 根据 Figma 改造 UI | `fp-figma` | 设计映射、实现、视觉与能力证据 |
| 从已确认设计准备开发评审 | `fp-design-review` | 可评审的 `review.md` 入口 |
| 审计或实施达梦、OceanBase 适配 | `fp-db-adapter` skill | 两阶段数据库适配方案、确认、实施与验证 |
| 提升单元测试覆盖率 | `fp-coverage` | 冻结口径、分批补测、完整验证 |
| 审查大型模块并受控修复 | `fp-module-review` | 稳定 Finding、分 wave 审查与批准后修复 |
| 做归档前整分支终审 | `fp-final-review` | 只读覆盖、范围、证据和风险判定 |
| 归档已完成变更 | `fp-archive` | 移动完整变更目录并更新历史 |

## 完整命令表

| Claude Code 命令 | 对应 skill | 何时使用 |
|---|---|---|
| `/fp-init` | `fp-init` | 第一次采用 FeaturePilot，或刷新已有信息层与可选 CodeGraph |
| `/fp-explore <问题>` | `fp-explore` | 在选择流程或修改代码前调查事实、行为、约束、风险与方案 |
| `/fp-eli5 <主题>` | `fp-eli5` | 明确需要零基础专业图解时；默认直接展示，不依赖原始 HTML 标签或 Mermaid，默认不写仓库；只有显式要求且宿主支持时才使用专用网页图解 |
| `/fp-prd <想法>` | `fp-prd`、`fp-prd-grill-me` | 明确要创建、编写、修订或补全 PRD 时 |
| `/fp-start <slug 或需求>` | `fp-start` | 执行从提案到归档的完整主线，或恢复中段产物 |
| `/fp-quick <需求>` | `fp-quick` | 单一模块内的小功能、局部 bugfix、文案或状态微调 |
| `/fp-figma <Figma node URL>` | `fp-figma` | 从可信 Figma 节点实现或完善当前项目 UI |
| `/fp-design-review <slug>` | `fp-design-review` | 从已确认设计生成或刷新开发设计评审入口 |
| `/fp-coverage <目标>` | `fp-coverage` | 提升 line、branch、function、statement 或组合覆盖率 |
| `/fp-module-review <范围>` | `fp-module-review` | 持续审查一个大型功能模块或多个相关模块 |
| `/fp-final-review <slug>` | `fp-final-review` | 实现完成后、归档或合并前进行整分支只读审查 |
| `/fp-archive <slug>` | `fp-archive` | 所有适用门禁通过后归档变更并更新 history |

`fp-db-adapter` 当前是 model-discoverable 专项 skill，不提供独立 `commands/fp-db-adapter.md`。直接说明“审计/规划/实施达梦或 OceanBase 数据库适配”即可触发；它始终先输出完整方案，再等待确认实施。

## 命令与技能如何配合

### Claude Code

`commands/fp-*.md` 只负责接收参数、加载同名 skill 和保留必要 gate checksum。不要把 command 文件当作完整手册；skill 才拥有实际步骤与完成条件。

### Codex 与 DeepSeek Harness

`/fp-*` 是工作流标签，而不是 Claude Code 风格的斜杠命令实现。安装后可以直接要求运行时使用 `fp:fp-start`、`fp:fp-prd` 等 skill。根目录 `AGENTS.md` 是 Codex fallback router，会把意图映射到同一套 `skills/`。

### 内部子技能

以下 skill 通常由主流程按需加载，而不是用户直接选择：

- `fp-propose`：生成并确认 proposal；
- `fp-brainstorm`：生成后端或前端技术设计；
- `fp-plan`、`fp-plan-backend`、`fp-plan-frontend`：生成细粒度执行计划；
- `fp-frontend-spec`：加载目标项目的前端视觉和交互规则。

它们保留独立职责，但完整流程统一从 `fp-start` 进入和恢复。

## 默认 direct 与显式 SDD

计划确认后，默认执行入口是 `fp-execute`：在当前上下文按任务执行 TDD，并做一次 inline 自审。

只有出现以下任一明确条件时，才选择 `fp-execute-sdd`：

1. 用户明确要求 SDD、fresh implementer/reviewer 或任务隔离；
2. 已有 `.fp-execute/progress.md` 记录需要恢复的 SDD 执行。

任务数量、改动规模、模块跨度或风险本身不会自动切换到 SDD。SDD 模式提供 serial implementer、fresh review、证据包、有界修复和中断恢复，但仍执行同一份已确认计划。

## 专项流程

### 需求与完整开发

阅读 [初始化、PRD 与完整主线](../user_guide/init-prd-start.md)，了解 `fp-init → fp-prd → fp-start` 的使用方式、Prototype-first 和阶段确认。

### 覆盖率提升

`fp-coverage` 会先冻结项目现有统计口径，再按 owner batch 补测；完成需要 fresh full-suite 成功和 exact coverage 达标。详细状态、证据目录、bootstrap 与恢复规则见 [覆盖率用户指南](../user_guide/fp-coverage.md)。

### 大型模块审查

`fp-module-review` 使用稳定 Finding ID 和分 wave 进度；行为变化必须逐项批准后才能修复。详见 [模块专项审查指南](../user_guide/fp-module-review.md)。

### Figma 与设计评审

- `fp-figma` 面向可信 Figma node，保留既有行为并建立视觉、能力和 E2E 证据；
- `fp-design-review` 把已确认设计整理成开发者可评审的入口，不代替设计确认；
- UI/E2E 与 Figma 的专业证据边界由架构与产物参考集中说明。

### 数据库适配

`fp-db-adapter` 支持 Django/Python SaaS 的达梦与 OceanBase 审计。阶段一只读扫描并输出文件级方案，阶段二仅在用户确认当前完整方案后实施；静态检查不会被描述为目标数据库实连通过。

### 最终审查与归档

`fp-final-review` 检查完整分支、canonical artifact、任务 owner、命令安全和适用的 UI/Figma 证据。`fp-archive` 只消费已通过且覆盖当前快照的终审结果，再请求移动确认。

## 下一步

- [3 分钟安装与更新](../getting-started.md)
- [返回项目首页](../../README.md)
