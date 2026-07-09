# FeaturePilot (`fp`)

FeaturePilot 是一个 AI 功能开发引导员，覆盖“需求 → 原型/设计 → 计划 → 执行 → 归档”的完整链路。

当前版本（`0.3.0`）提供 Claude Code 原生插件能力，并提供 Codex 可读的 Markdown/AGENTS.md 流程入口；统一使用 `fp-*` 命名。

## 0.3.0 发布重点

- **PRD interview gate 强化**：`fp-prd` 是需求澄清入口，不是一次性 PRD 生成器；写文件前必须完成确认摘要并获得用户明确批准。Bucket A/B 已确定项必须批量输出供用户审阅；Bucket C 待确认项必须逐个提问、一问一答；助手建议不等于用户确认，禁止自问自答或替用户确认 Bucket C。
- **Prototype-first PRD 流程**：UI-heavy 或明确要求“先看原型”的需求，可先确认 prototype-blocking 问题并生成 `prototype.html`，用户确认后再沉淀 PRD。
- **Lazy context 与 stale intel 规则**：默认只读 `fp-docs/manifest.md` 和最小相关 settings/intel；`fp-docs/intel/*` 只作为可能过期的导航线索，涉及当前实现时必须回到当前代码验证。
- **Claude Code + Codex 双入口**：Claude Code 使用插件清单、命令与 Skill tool；Codex 通过 `AGENTS.md` 和 `skills/*/SKILL.md` 读取同一套阶段门禁。

## Claude Code 插件结构

- `.claude-plugin/plugin.json`：Claude Code 插件清单。
- `.claude-plugin/marketplace.json`：本地开发插件市场。
- `commands/`：Claude Code 斜杠命令。
- `skills/`：FeaturePilot 流程技能。

## 核心命令

| 命令文件 | 用途 |
|---|---|
| `commands/fp-init.md` | 初始化 `fp-docs/` 信息层（`manifest.md`、可选 `settings/agent.md`/`frontend.md`/`backend.md`/`prototype-style.md`、`intel/`）；检测到 Canway/CW 项目且用户确认时，可采用标注示例规范 |
| `commands/fp-prd.md` | 将想法、用户故事或痛点澄清为 PRD；支持 Prototype-first 先出 `prototype.html` 再沉淀 PRD |
| `commands/fp-start.md` | 接住 PRD 或需求描述，启动“提案 → 设计 → 计划 → 执行 → 归档”完整链路 |
| `commands/fp-propose.md` | 仅生成并确认开发提案 `proposal.md` |
| `commands/fp-brainstorm.md` | 基于已确认提案生成技术设计 |
| `commands/fp-quick.md` | 快速处理无需完整文档链路的小型需求 |
| `commands/fp-review.md` | 归档前最终整分支只读审查 |
| `commands/fp-archive.md` | 归档已完成的变更 |
| `commands/fp-figma.md` | UI / Figma 设计稿分析入口 |

## 核心技能

- `fp-init`：初始化 `fp-docs/` 信息层，并可选引导生成 `fp-docs/settings/agent.md`、`frontend.md`、`backend.md`、`prototype-style.md`；检测到 Canway/CW 项目且用户确认时，可采用 `examples/canway-cw/fp-docs/settings/` 标注示例。
- `fp-prd` / `fp-prd-grill-me`：需求与 PRD 澄清；支持默认 PRD-first 与 Prototype-first（先生成 `prototype.html`，确认后再沉淀 PRD）。
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

FeaturePilot 的默认使用方式尽量轻量。完整用户指南见 [`docs/user_guide/init-prd-start.md`](docs/user_guide/init-prd-start.md)：

1. **可选初始化**：运行 `/fp-init`，创建 `fp-docs/`，并可选生成 `fp-docs/settings/agent.md`、`frontend.md`、`backend.md`、`prototype-style.md`；如检测到 Canway/CW 项目，只有在用户确认后才可采用 `examples/canway-cw/` 示例规范作为项目 settings 草稿。
2. **需求设计**：运行 `/fp-prd <想法>`，默认澄清产品需求并写入 `fp-docs/changes/<slug>/prd.md`；如果需求适合先看页面/交互，可走 Prototype-first，先生成并确认 `prototype.html` 后再沉淀 PRD。
3. **开发接续**：运行 `/fp-start <slug>`，读取 PRD，生成开发提案，然后继续进入设计、计划、执行、审查和归档。
4. **无配置也可运行**：如果没有 `agent.md`，FeaturePilot 会基于当前代码、相邻实现和用户回答继续工作。

当计划较大、跨模块、涉及权限/数据/接口/UI 契约或风险较高时，`fp-start` 可以转入 `fp-execute-sdd`。该模式会使用任务说明、全新上下文实现代理、逐任务审查、修复循环和最终整分支审查。

## 项目配置

FeaturePilot 是公共插件，不内置任何客户组件库、设计系统、仓库结构或审查策略。目标项目如需定制行为，可以在自己的 `fp-docs/settings/agent.md`、`fp-docs/settings/frontend.md`、`fp-docs/settings/backend.md`、`fp-docs/settings/prototype-style.md` 中声明。

```text
fp-docs/
  manifest.md                 # FeaturePilot 信息层唯一入口
  settings/
    agent.md                  # 可选：轻量 FeaturePilot policy adapter
    frontend.md               # 可选：前端/UI/视觉/设计系统规则
    backend.md                # 可选：后端/API/数据/安全规则
    prototype-style.md        # 可选：原型视觉风格参考
  intel/                      # 生成的 source-backed 但 stale-prone 的导航线索
```

规则：

- 如果 `fp-docs/manifest.md` 存在，Agent 必须先读取它，再按 manifest 发现相关 settings 和 intel。
- 如果没有配置文件，Agent 回退到当前代码、相邻实现和公共默认规则。
- 客户项目应通过 `fp-docs/settings/` 定制规则，而不是修改公共插件源码。
- 公共插件不得假设任何客户组件库、供应商、组件前缀、设计 token、后端框架或工作流策略。

## 输出目录

FeaturePilot 生成的文档统一放在目标项目的 `fp-docs/` 下。核心位置包括 `fp-docs/changes/<slug>/`，以及归档后生成的 `fp-docs/archive/` 和 `fp-docs/history/history.md`（由 `fp-archive` 自动创建）：

```text
fp-docs/
  manifest.md                     # FeaturePilot 信息层唯一入口
  settings/                       # 仅 fp-init 创建，非必须
    agent.md                      # 可选：轻量 FeaturePilot policy adapter
    frontend.md                   # 可选：前端/UI/视觉/设计系统规则
    backend.md                    # 可选：后端/API/数据/安全规则
    prototype-style.md            # 可选：原型视觉风格参考
  intel/                          # 仅 fp-init 创建，source-backed 但 stale-prone 的导航线索
  changes/<slug>/                 # 按需由各阶段创建
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

Codex 没有 Claude Code 插件运行时，`/fp-*` 在 Codex 中不是可执行斜杠命令，而是映射到同名 Markdown 技能文件的流程标签。Codex 可以读取同一套文件作为流程约束：

1. 将本仓库放在目标项目旁边或作为子模块。
2. 在 Codex 会话中要求：
   - “读取 `feature-pilot/AGENTS.md`，按 `fp-start` 流程执行。”
   - 或直接指定某个技能文件，如 `feature-pilot/skills/fp-prd/SKILL.md`。
3. Codex 执行时应先读取匹配 skill，再遵循与 Claude Code 相同的阶段门禁：
   - `fp-prd` 必须先完成 PRD interview gate；Prototype-first 必须先确认原型再写 PRD；
   - 提案确认后才能设计；
   - 设计确认后才能计划；
   - 计划确认后才能执行；
   - 完成后执行审查，再归档。
4. Codex 同样必须使用 lazy context：不要批量读取 `fp-docs/settings/`、`fp-docs/intel/`、历史 changes/archive/history；generated intel 只是导航线索，不是当前事实来源。

## 当前版本范围

已包含（`0.3.0`）：

- 初始化：`fp-init`。
- 需求设计：`fp-prd`、`fp-prd-grill-me`、`fp-grill-me`、`fp-propose`、`fp-brainstorm`；包含 PRD-first、Prototype-first、PRD interview gate、mandatory PRD template、prototype style extraction/lazy consumption。
- 完整启动链路：`fp-start` 及其依赖的 `fp-plan`、`fp-execute`、`fp-execute-sdd`、`fp-review`、`fp-archive`。
- 信息层规则：`fp-docs/manifest.md` 作为索引入口；settings/intel 按需最小读取；generated intel 视为 stale-prone navigation，当前事实必须用当前代码验证。
- Claude Code / Codex 双入口：插件运行时与 Markdown 技能说明保持同一套阶段门禁。

未包含独立 TypeScript CLI；第一版优先交付 Claude Code 原生插件与 Codex 可读流程文档。
