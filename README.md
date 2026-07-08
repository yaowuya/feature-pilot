# FeaturePilot (`fp`)

FeaturePilot 是一个 AI 功能开发引导员，覆盖“需求 → 设计 → 计划 → 执行 → 归档”的完整链路。

第一版提供需求设计与完整启动链路能力，并统一使用 `fp-*` 命名。

## Claude Code 插件结构

- `.claude-plugin/plugin.json`：Claude Code 插件清单。
- `.claude-plugin/marketplace.json`：本地开发插件市场。
- `commands/`：Claude Code 斜杠命令。
- `skills/`：FeaturePilot 流程技能。

## 核心命令

| 命令文件 | 用途 |
|---|---|
| `commands/fp-init.md` | 初始化 `fp-docs/` 工作区，并可选生成 `settings/agent.md` |
| `commands/fp-prd.md` | 将想法、用户故事或痛点澄清为 PRD |
| `commands/fp-start.md` | 接住 PRD 或需求描述，启动“提案 → 设计 → 计划 → 执行 → 归档”完整链路 |
| `commands/fp-propose.md` | 仅生成并确认开发提案 `proposal.md` |
| `commands/fp-brainstorm.md` | 基于已确认提案生成技术设计 |
| `commands/fp-quick.md` | 快速处理无需完整文档链路的小型需求 |
| `commands/fp-review.md` | 归档前最终整分支只读审查 |
| `commands/fp-archive.md` | 归档已完成的变更 |
| `commands/fp-figma.md` | UI / Figma 设计稿分析入口 |

## 核心技能

- `fp-init`：初始化 `fp-docs/`，并可选引导生成 `fp-docs/settings/agent.md`。
- `fp-prd` / `fp-prd-grill-me`：需求与 PRD 澄清。
- `fp-start`：完整阶段门禁调度入口，可以接住 `fp-prd` 产出的 PRD。
- `fp-propose`：生成 `fp-docs/changes/<slug>/proposal.md`。
- `fp-brainstorm`：生成后端/前端技术设计。
- `fp-plan` / `fp-plan-backend` / `fp-plan-frontend`：生成细粒度 TDD 执行计划。
- `fp-execute`：按已确认计划执行任务。
- `fp-execute-sdd`：适合中大型或高风险计划的 SDD 执行模式。
- `fp-review`：最终整分支审查。
- `fp-archive`：归档变更。

## 借鉴 OpenSpec 的设计

FeaturePilot 吸收了 OpenSpec 中低仪式感、适合存量项目的设计，但把命令聚焦在 AI 功能开发流程上：

- **低成本初始化**：`/fp-init` 只创建最小 `fp-docs/` 目录；配置文件不是必须的。
- **以变更目录作为审查单元**：每个功能放在 `fp-docs/changes/<slug>/` 下，PRD、提案、设计、任务、执行记录和审查都在同一个目录中。
- **产物依赖图，而不是重流程**：推荐路径是 `PRD → 提案 → 设计 → 任务 → 执行`，但已有产物会被复用，不会强迫重复访谈。
- **归档保留历史**：完成后的变更移动到 `fp-docs/archive/YYYY-MM-DD-<slug>/`，并在 `fp-docs/history/history.md` 中记录为什么做、做了什么。

## 低成本使用流程

FeaturePilot 的默认使用方式尽量轻量：

1. **可选初始化**：运行 `/fp-init`，创建 `fp-docs/`，并可选生成 `fp-docs/settings/agent.md`。
2. **需求设计**：运行 `/fp-prd <想法>`，澄清产品需求并写入 `fp-docs/changes/<slug>/prd.md`。
3. **开发接续**：运行 `/fp-start <slug>`，读取 PRD，生成开发提案，然后继续进入设计、计划、执行、审查和归档。
4. **无配置也可运行**：如果没有 `agent.md`，FeaturePilot 会基于当前代码、相邻实现和用户回答继续工作。

当计划较大、跨模块、涉及权限/数据/接口/UI 契约或风险较高时，`fp-start` 可以转入 `fp-execute-sdd`。该模式会使用任务说明、全新上下文实现代理、逐任务审查、修复循环和最终整分支审查。

## 项目配置

FeaturePilot 是公共插件，不内置任何客户组件库、设计系统、仓库结构或审查策略。目标项目如需定制行为，可以在自己的 `fp-docs/settings/agent.md` 中声明。

```text
fp-docs/
  settings/
    agent.md       # 可选：项目级 FeaturePilot、工作流、路径、前端、设计系统规则
```

规则：

- 如果 `fp-docs/settings/agent.md` 存在，Agent 在选择组件库规则、输出路径、测试命令或工作流行为前必须先读取它。
- 如果没有配置文件，Agent 回退到当前代码、相邻实现和公共默认规则。
- 客户项目应通过 `fp-docs/settings/agent.md` 定制规则，而不是修改公共插件源码。
- 公共插件不得假设任何客户组件库、供应商、组件前缀、设计 token 或工作流策略。

## 输出目录

FeaturePilot 生成的文档统一放在目标项目的 `fp-docs/` 下。核心位置包括 `fp-docs/changes/<slug>/`，以及归档后生成的 `fp-docs/archive/` 和 `fp-docs/history/history.md`（由 `fp-archive` 自动创建）：

```text
fp-docs/
  settings/                     # 仅 fp-init 创建，非必须
    agent.md                    # 可选
    frontend_design.md          # 可选
  changes/<slug>/               # 按需由各阶段创建
    prd.md
    proposal.md
    design-backend.md
    design-frontend.md
    tasks/
      plan-backend.md
      plan-frontend.md
    .fp-execute/
      progress.md
      briefs/
      packages/
      reviews/
  archive/                      # 由 fp-archive 自动创建
  history/history.md             # 由 fp-archive 自动创建
```

## 本地安装测试（Claude Code）

在 Claude Code 中添加本仓库作为开发插件市场：

```text
/plugin marketplace add <path-to-feature-pilot>
/plugin install fp@fp-dev
```

重启 Claude Code 后使用命令，例如：

```text
/fp-init
/fp-prd 我想做一个批量审批体验优化
/fp-start <prd-slug 或 功能描述>
```

## Codex 使用方式

Codex 没有 Claude Code 插件运行时，但可以读取同一套文件作为流程约束：

1. 将本仓库放在目标项目旁边或作为子模块。
2. 在 Codex 会话中要求：
   - “读取 `feature-pilot/AGENTS.md`，按 `fp-start` 流程执行。”
   - 或直接指定某个技能文件，如 `feature-pilot/skills/fp-prd/SKILL.md`。
3. Codex 执行时应遵循与 Claude Code 相同的阶段门禁：
   - 提案确认后才能设计；
   - 设计确认后才能计划；
   - 计划确认后才能执行；
   - 完成后执行审查，再归档。

## 当前版本范围

已包含：

- 初始化：`fp-init`。
- 需求设计：`fp-prd`、`fp-prd-grill-me`、`fp-grill-me`、`fp-propose`、`fp-brainstorm`。
- 完整启动链路：`fp-start` 及其依赖的 `fp-plan`、`fp-execute`、`fp-execute-sdd`、`fp-review`、`fp-archive`。
- 前端设计辅助：`fp-figma`、`fp-ui-spec`、`fp-ux-spec`；客户组件库规则由目标项目的 `fp-docs/settings/agent.md` 提供。

未包含独立 TypeScript CLI；第一版优先交付 Claude Code 原生插件与 Codex 可读流程文档。
