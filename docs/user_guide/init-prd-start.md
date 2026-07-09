# FeaturePilot 用户指南：/fp-init、/fp-prd、/fp-start

本指南说明 FeaturePilot 的低成本主线：先用 `/fp-init` 建立项目级信息层，再用 `/fp-prd` 把想法澄清为 PRD，最后用 `/fp-start` 接住 PRD 进入提案、设计、计划、执行。

> 推荐路径：`/fp-init`（一次） → `/fp-prd <想法>` → `/fp-start <slug>`。

## 1. `/fp-init`：初始化项目信息层

### 什么时候用

在目标项目第一次接入 FeaturePilot，或希望补齐项目级 settings / intel 时运行：

```text
/fp-init
```

### 它会创建什么

`/fp-init` 只负责目标项目的信息层，默认只在项目根目录创建：

```text
fp-docs/
  manifest.md
  settings/
  intel/
```

`/fp-init` **不会**预创建这些目录：

- `fp-docs/changes/`：由 `/fp-prd`、`/fp-start` 等后续阶段按需创建。
- `fp-docs/archive/`：由 `/fp-archive` 归档时创建。
- `fp-docs/history/`：由 `/fp-archive` 记录历史时创建。

### 核心文件

| 文件 | 作用 | 什么时候读 |
|---|---|---|
| `fp-docs/manifest.md` | FeaturePilot 信息层唯一入口，记录 settings/intel 的索引、优先级、freshness 规则 | 每个 FeaturePilot 流程开始时先读 |
| `fp-docs/settings/agent.md` | 通用工作流与项目政策 adapter | 工作流/权限/验证策略相关时 |
| `fp-docs/settings/frontend.md` | 前端、UI、设计系统、视觉验收规则 | UI/页面/组件/前端实现相关时 |
| `fp-docs/settings/backend.md` | 后端、API、数据、安全、权限规则 | 后端/API/数据/安全相关时 |
| `fp-docs/settings/prototype-style.md` | HTML 原型视觉风格参考 | 生成或更新 `prototype.html` 时 |
| `fp-docs/intel/*` | 只读扫描生成的导航线索 | 只在当前问题相关时小范围读取 |

### 可选设置文件

`/fp-init` 会询问是否生成可选 settings。它们不是强制配置；跳过后 FeaturePilot 仍可基于当前代码、相邻实现和用户回答继续工作。

建议原则：

- 不确定就写 `Unknown`，不要猜测。
- 现有文件不覆盖，除非用户明确批准。
- 项目已有 `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` / `CURSOR.md` 时，只在 manifest 中记录引用，不复制大段内容到 `settings/agent.md`。
- 公共 FeaturePilot 插件不内置客户组件库、后端框架、API envelope 或设计 token；客户规则应落在目标项目自己的 `fp-docs/settings/*.md`。

### CW / 嘉为项目示例

FeaturePilot 可以携带明确标注的示例规范，例如本仓库的：

```text
examples/canway-cw/fp-docs/settings/
# Absolute path in this repository: D:/01-code/feature-pilot/examples/canway-cw/fp-docs/settings/
  agent.md
  backend.md
  frontend.md
  prototype-style.md
```

示例覆盖范围映射：

| 规范范围 | 示例文件 |
|---|---|
| 后端规范 | `backend.md` |
| 前端规范 | `frontend.md` |
| UI 规范 | `frontend.md` 的 UI/component/visual sections |
| UX 规范 | `frontend.md` 的 UX interaction sections |
| 原型视觉风格 | `prototype-style.md` |

当 `/fp-init` 通过只读启发式判断当前项目可能是 Canway / CW 项目时，它应主动询问是否采用这些示例规范作为 settings 初始草稿。采用行为必须满足：

- 只在用户确认后执行；不得自动写入。
- 只创建缺失文件；如目标项目已有同名 settings，必须再次询问是否跳过、查看差异或覆盖。
- 示例被复制到目标项目后就是可编辑的项目配置，不是公共插件全局默认规则。
- 检测不确定时不做特殊处理，继续普通 `/fp-init` 流程。

### 完成后你会得到什么

`/fp-init` 应报告：

- 工作区路径。
- `manifest.md` 创建/更新状态。
- `agent.md`、`frontend.md`、`backend.md`、`prototype-style.md` 创建/跳过状态。
- intel 是生成轻量扫描还是仅保留骨架。
- 检测到的外部项目文档。
- critical unknowns。
- 下一步建议：通常是 `/fp-prd <想法>` 或 `/fp-start <slug 或功能描述>`。

## 2. `/fp-prd`：把想法澄清为 PRD

### 什么时候用

当你有一个产品想法、用户故事、痛点或半成品需求时运行：

```text
/fp-prd 我想给告警列表增加负责人筛选
```

### 输出位置

`/fp-prd` 只创建需求产物：

```text
fp-docs/changes/<slug>/prd.md
fp-docs/changes/<slug>/prototype.html   # 仅在确认需要原型时生成
```

禁止把 PRD 写到 `fp-docs/prd-*.md` 或 `fp-docs/*.prd.md`。

### 关键门禁

`/fp-prd` 是访谈工作流，不是一句话生成器。写文件前必须完成确认：

1. 加载 `fp-prd-grill-me`。
2. 批量展示 Bucket A/B 已确定项，给用户一次性审阅和纠错。
3. Bucket C 待确认项必须一问一答逐个提问；助手不能自问自答。
4. 输出确认摘要：已确认决策、假设、非阻塞问题、是否生成原型、目标路径。
5. 等用户明确批准后，才创建目录和写入 `prd.md` / `prototype.html`。

例外只有三类：

- 用户提供了完整 PRD，并明确批准标准化到模板。
- 用户明确说“无需提问，按以下假设生成”。
- 已有访谈答案和确认摘要获得用户批准。

### PRD-first 与 Prototype-first

| 模式 | 适用场景 | 产物顺序 |
|---|---|---|
| PRD-first（默认） | 普通需求、后端/API/流程需求、已有明确业务目标 | 先确认 PRD 决策 → 写 `prd.md` → 如需要再写 `prototype.html` |
| Prototype-first | 用户说“先看原型/先出页面/先做交互稿”，或需求 UI-heavy | 先确认 prototype-blocking 决策 → 写 `prototype.html` → 用户确认原型 → 补齐 PRD 决策 → 写 `prd.md` |

生成原型时，如果存在 `fp-docs/settings/prototype-style.md`，必须先读取并应用；没有则使用中性默认样式，并建议在首个原型确认后提取项目原型风格。

### PRD 模板要求

`prd.md` 必须使用 `fp-prd` skill 的 Mandatory PRD Structure，保留固定章节：

1. 用户故事
2. 核心业务流程
3. 功能需求
4. 非功能需求
5. 测试建议
6. 待确认问题

不能重命名、合并、删除、重排这些顶级章节；表格列名和功能小节也必须保持模板约定。

### 上下文读取规则

`/fp-prd` 应保持 lazy context：

- 先读 `fp-docs/manifest.md`（如果存在），只作为索引。
- UI/原型相关才读 `settings/frontend.md` / `settings/prototype-style.md`。
- 后端/API/权限/数据会影响产品决策时才读 `settings/backend.md`。
- 不批量读取 `fp-docs/intel/*`、历史 changes、archive、history。
- 当前实现事实以当前代码和命令输出为准；generated intel 只是可能过期的导航线索。

### 下一步

完成后通常运行：

```text
/fp-start <slug>
```

其中 `<slug>` 对应 `fp-docs/changes/<slug>/prd.md`。

## 3. `/fp-start`：接住 PRD 进入开发链路

### 什么时候用

当 PRD 已经确认，或你已经有清晰的功能描述并希望进入开发流程时运行：

```text
/fp-start <slug>
/fp-start 给告警列表增加负责人筛选并支持保存筛选条件
```

### 缺少 `/fp-init` 时怎么办

`/fp-start` 启动时只检查项目根目录下的 `fp-docs/manifest.md`。

如果缺失，它应提示：

```text
未检测到项目根目录下的 fp-docs/manifest.md。建议先运行 /fp-init 初始化 FeaturePilot 信息层，以便记录 settings/intel；这不是强制要求。
```

然后继续遵守这些规则：

- 不因此停止。
- 不自动运行 `/fp-init`。
- 不从 `/fp-start` 创建 `manifest.md`、`settings/` 或 `intel/`。
- 如果用户继续，只能按需创建本次变更产物，例如 `fp-docs/changes/<slug>/proposal.md`。

### PRD handoff

如果参数 `<slug>` 能匹配：

```text
fp-docs/changes/<slug>/prd.md
```

`/fp-start` 必须读取该 PRD，并把它作为需求来源交给后续 `fp-propose`，避免重复访谈已确认的 PRD 决策。

如果参数是功能描述，且存在唯一明显相关的近期 PRD，应询问用户是否使用该 PRD，或从当前描述重新开始。

### 完整开发链路

`/fp-start` 执行阶段：

1. `fp-propose`：生成并确认 `proposal.md`。
2. `fp-brainstorm`：生成并确认技术设计；按实际范围输出 `design-backend.md` 和/或 `design-frontend.md`。
3. `fp-plan`：生成并确认细粒度执行计划；按实际范围输出 `tasks/plan-backend.md` 和/或 `tasks/plan-frontend.md`。
4. `fp-execute` 或 `fp-execute-sdd`：按已确认任务执行。
5. `fp-review`：最终整分支审查。
6. 建议 `/fp-archive`：归档完成的变更。

阶段 1、2、3 完成后都必须停下等待用户确认；没有确认不得进入下一阶段。

### 小需求分流

`/fp-start` 在阶段 1 前会做轻量判断。如果需求明显是局部页面/组件调整、小接口/字段/文案变更、明确范围 bugfix，且不需要完整 FeaturePilot 留痕，它应询问是否改走 `fp-quick`。

用户确认后才切换；否则继续完整 `/fp-start`。

### 上下文读取规则

- `fp-docs/manifest.md` 存在时先读。
- 只读取当前阶段需要的 settings/intel，不批量读取整个 `fp-docs/`。
- 不读取历史 `changes/`、`archive/`、`history/` 作为实现背景。
- 当前代码、测试、路由、模型、组件和 API 是实现事实来源。
- 已批准的 PRD、proposal、design、tasks 是本次目标状态来源。

## 4. 推荐工作方式

### 新项目或首次接入

```text
/fp-init
/fp-prd <一句话想法>
/fp-start <prd-slug>
```

### 已有 PRD

```text
/fp-start <slug>
```

### 没有时间初始化

```text
/fp-prd <想法>
/fp-start <slug>
```

FeaturePilot 会提示建议 `/fp-init`，但不会强制停止。后续如需要长期复用项目规范，再补跑 `/fp-init`。

### UI-heavy 需求

```text
/fp-prd 先给我出一个 <页面/交互> 原型
# 原型确认后
/fp-start <slug>
```

### 大型或高风险需求

使用 `/fp-start` 完整链路，并在执行阶段优先考虑 `fp-execute-sdd`，以获得任务 brief、fresh implementer、逐任务审查、修复循环和最终 review。
