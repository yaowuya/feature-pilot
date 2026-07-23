# FeaturePilot 用户指南：/fp-explore、/fp-init、/fp-prd、/fp-start

本指南说明 FeaturePilot 的低成本主线：可先用 `/fp-explore` 只读调查；再按需用 `/fp-init` 建立项目级信息层；只有确实要编写 PRD 时才显式调用 `/fp-prd`；最后可用 `/fp-start` 接住已确认 PRD，或直接从清晰功能描述进入提案、设计、计划、执行。

> 推荐路径：`/fp-explore <问题>`（可选） → `/fp-init`（一次，可选） → `/fp-prd <想法>` → `/fp-start <slug>`。

## 可选：先用 `/fp-explore` 调查

`/fp-explore <问题>` 用于只读调查当前代码、测试、接口、行为、约束、风险和可选方案。空输入只做有界项目概览，然后询问你想深入的方向。它不会创建 PRD/proposal/design/tasks，不会修改代码，也不会自动切换到其他流程。

`fp-prd`、`fp-start` 和 `fp-quick` 会在内部复用相同探索能力：PRD 只消费代码事实且仍由 `fp-prd-grill-me` 确认产品决策；start 仍由用户选择 quick/full；quick 仍须先确认内联计划才能实现。

## 1. `/fp-init`：初始化项目信息层

### 什么时候用

在目标项目第一次接入 FeaturePilot，或希望按需补齐项目级 settings / facts 时运行：

```text
/fp-init
```

### 它会创建什么

`/fp-init` 只负责目标项目的信息层。v2 的 `manifest-only default` 默认只在项目根目录创建：

```text
fp-docs/
  manifest.md
```

它不预建空 `settings/`/`intel/`、Unknown/Decision、refresh policy 或 SDD handoff。可选目录随已批准文件按需出现。

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
| `fp-docs/intel/project-facts.md` | 可选生成事实缓存，只含质量门禁与非显而易见的契约/架构/安全边界 | 仅相关时读取并回到当前源码复核 |
| `fp-docs/intel/.freshness.json` | metadata-only：source fingerprint、body hash、生成时间/版本 | `/fp-init` 实时计算 stale/conflict 时 |
| `fp-docs/intel/unknowns.md` / `decisions.md` | 可选 human-owned 项目知识 | 仅有实际内容、已批准且当前问题相关时 |

### 可选 CodeGraph 代码地图

`/fp-init` 在确定项目根目录后检测 CodeGraph。未检测到可用 CLI 时会让你选择：

1. **自动安装（推荐）**：说明 npm 全局安装影响后执行安装；该选择也授权为当前项目执行首次建图。
2. **展示安装步骤**：只显示前置条件、安装、可选 MCP 配置和建图命令，本轮不执行。
3. **跳过**：不安装、不配置、不建图，继续普通初始化。

唯一允许的自动安装命令是：

```text
npm install -g @colbymchenry/codegraph@latest
```

FeaturePilot 不使用 `irm`、`curl`、`install.ps1`、`install.sh` 或 `npx` 安装 CodeGraph。系统缺少 npm 时，它不会自动安装 Node.js，也不会切换安装方式；会说明前置条件并继续普通初始化。

CLI 可用后，`/fp-init` 会单独询问是否配置 Claude Code/Codex MCP。MCP 配置可能修改用户级配置，成功后通常需要重启相应 Agent；跳过 MCP 不影响 CLI 建图和查询。

项目根目录没有 `.codegraph/` 时：本轮自动安装已包含首次建图授权；如果 CLI 原本已安装，则会再次询问是否为当前项目建图。已有图和新图都必须通过 `codegraph status <project-root> --json` 验证，不能只凭目录存在判断可用。FeaturePilot 不会未经允许修改 `.gitignore` 或删除失败索引。

后续代码调查按 `MCP → CLI → 原有搜索` 使用代码图。每个 FeaturePilot 工作流最多执行一次健康检查和一次必要同步；失败会自动回退，不影响主流程。代码图只提供 `navigation-hint-only`，修改范围、精确契约和完成结论仍以当前源码、测试和命令输出为准。

#### 已有信息层如何刷新

项目已有 `fp-docs/manifest.md` 时，再次运行 `/fp-init` 会进入 `refresh-existing-information-layer`。它只读取 manifest、可选 `project-facts.md`、`.freshness.json` 以及 metadata 中列出的源路径，用当前 source fingerprint/body hash 实时计算 section 的 stale/conflict；这些 verdict 不写回 metadata 充当项目事实。

发现 stale 文件后会先展示文件级清单，再提供：

1. `refresh-stale-intel`：只重建清单中已批准且没有用户编辑冲突的 project-facts section，并更新 metadata。
2. 仅报告：不写入，后续继续实时检查当前源码。
3. 跳过：不做更多 freshness 检查。

`fp-docs/settings/*`、human-owned `intel/unknowns.md`/`decisions.md`、PRD/proposal/design/tasks、archive/history 不在批量刷新范围。旧 `unknowns-and-decisions.md`、`refresh-policy.md`、`sdd-handoff.md` 在一个发布周期内只能作为 manifest-listed 只读提示，不创建、刷新、要求或自动删除。

#### 代码写入后的索引更新

`fp-execute`、`fp-execute-sdd` 或 `fp-quick` 首次修改源码后，会把当前图标记为 `dirty-after-write`，本轮不再查询写入前的旧图。它们在写入后的用户可见返回前，对原本已存在的图执行一次 `post-write-sync`：

```text
codegraph sync <project-root> --quiet
```

同步后不重复运行 `status`，下一工作流仍会做正常健康检查，以捕获外部新增修改。同步失败只会记录原因并回退原有搜索，不阻塞测试、审查或完成；项目原本没有 `.codegraph/` 时不会在执行结束时隐式建图。

### 可选设置文件

`/fp-init` 会逐项询问是否生成可选 settings，只有批准后才创建对应目录/文件。批准 discovery 后也只创建 `project-facts.md` 和 `.freshness.json`，不保存 CodeGraph 拓扑。项目级 unknowns/decisions 仅在确有内容并单独批准写入范围后懒创建；它们缺失不是阻塞。

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
- 是否保持 manifest-only，或生成 project facts/freshness metadata；是否经单独批准写入 human-owned knowledge。
- CodeGraph CLI、MCP、项目图和必要重启/回退状态。
- 检测到的外部项目文档。
- critical unknowns。
- 下一步建议：通常是 `/fp-prd <想法>` 或 `/fp-start <slug 或功能描述>`。

## 2. `/fp-prd`：把想法澄清为 PRD

### 什么时候用

普通产品想法、功能请求、用户故事、痛点或半成品需求本身不会自动触发 PRD 编写。

Use fp-prd only when the user explicitly invokes /fp-prd or $fp-prd, or explicitly asks to create, write, revise, or complete a PRD or product requirements document.

需要 PRD 时可运行：

```text
/fp-prd 我想给告警列表增加负责人筛选
```

### 输出位置

`/fp-prd` 只创建需求产物。PRD 根据已确认内容选择且只选择一种互斥形式：

```text
fp-docs/changes/<slug>/prd.md                    # 小型形式
fp-docs/changes/<slug>/prd/00-index.md           # 拆分形式的唯一入口
fp-docs/changes/<slug>/prototype.html   # 仅在确认需要原型时生成
```

上面两个 PRD 路径是二选一，不允许并存；拆分形式还包含 `00-index.md` manifest 列出的编号分片。

禁止把 PRD 写到 `fp-docs/prd-*.md` 或 `fp-docs/*.prd.md`。

### 关键门禁

`/fp-prd` 是访谈工作流，不是一句话生成器。写文件前必须完成确认：

1. 加载 `fp-prd-grill-me`。
2. 批量展示 Bucket A/B 已确定项，给用户一次性审阅和纠错。
3. Bucket C 待确认项必须一问一答逐个提问；助手不能自问自答。
4. 输出确认摘要：已确认决策、假设、非阻塞问题、是否生成原型、目标路径。
5. 等用户明确批准后，才创建目录和写入 PRD 的小型或拆分形式，以及获批的 `prototype.html`。

例外只有三类：

- 用户提供了完整 PRD，并明确批准标准化到模板。
- 用户明确说“无需提问，按以下假设生成”。
- 已有访谈答案和确认摘要获得用户批准。

### PRD-first 与 Prototype-first

| 模式 | 适用场景 | 产物顺序 |
|---|---|---|
| PRD-first（默认） | 普通需求、后端/API/流程需求、已有明确业务目标 | 先确认 PRD 决策 → 写入 PRD 的 canonical 小型或拆分形式 → 如需要再写 `prototype.html` |
| Prototype-first | 用户说“先看原型/先出页面/先做交互稿”，或需求 UI-heavy | 先确认 prototype-blocking 决策 → 写 `prototype.html` → 用户确认原型 → 补齐 PRD 决策 → 写入 PRD 的 canonical 小型或拆分形式 |

生成原型时，如果存在 `fp-docs/settings/prototype-style.md`，必须先读取并应用；没有则使用中性默认样式，并建议在首个原型确认后提取项目原型风格。

### PRD 模板要求

逻辑 PRD 必须使用 `fp-prd` skill 的 Mandatory PRD Structure；无论小型文件还是 manifest 顺序拼接后的拆分分片，都要保留固定章节：

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

其中 `<slug>` 对应 `fp-docs/changes/<slug>/prd.md` 或 `fp-docs/changes/<slug>/prd/00-index.md`，但不能同时对应两者。

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
- 如果用户继续，只能按需创建本次变更产物，例如 proposal 的小型 `fp-docs/changes/<slug>/proposal.md` 或拆分 `fp-docs/changes/<slug>/proposal/00-index.md` form。

### PRD handoff

如果参数 `<slug>` 能唯一解析到下列一种 canonical PRD form：

```text
fp-docs/changes/<slug>/prd.md
fp-docs/changes/<slug>/prd/00-index.md
```

`/fp-start` 必须读取小型文件，或严格按 split manifest 顺序读取全部 PRD 分片，并把解析后的逻辑 PRD 作为需求来源交给后续 `fp-propose`，避免重复访谈已确认的 PRD 决策。

如果参数是功能描述，且存在唯一明显相关的近期 PRD，应询问用户是否使用该 PRD，或从当前描述重新开始。

### 产物布局契约

PRD、proposal、单端 design 与单端 plan 都采用 compact-first、mutually exclusive 的小型/拆分二选一规则：

| 逻辑产物 | 小型形式 | 拆分形式 |
|---|---|---|
| PRD | `prd.md` | `prd/00-index.md` 加 manifest 中列出的分片 |
| Proposal | `proposal.md` | `proposal/00-index.md` 加 manifest 中列出的分片 |
| Backend design | `design/backend.md` | `design/backend/00-index.md` 加 manifest 中列出的分片 |
| Frontend design | `design/frontend.md` | `design/frontend/00-index.md` 加 manifest 中列出的分片 |
| Backend plan | `tasks/plan-backend.md` | `tasks/backend/00-index.md` 加 manifest 中列出的分片 |
| Frontend plan | `tasks/plan-frontend.md` | `tasks/frontend/00-index.md` 加 manifest 中列出的分片 |

产物形式采用紧凑优先（compact-first）且 small/split 互斥：预计完整逻辑产物不超过 500 行和 30,000 字符时默认使用 small form；只有预计超过任一硬限制、用户明确批准 split form，或目标项目设置明确要求 split form 时才拆分。功能、子系统、页面区域、任务组或 ownership domain 只用于拆分后的语义边界，不单独触发拆分。

FeaturePilot 过程文档的叙述性内容默认使用中文；代码、命令、路径、技术标识符、API 字段和契约要求精确匹配的 schema 关键词保留必要英文。当前用户明确语言指令优先于目标项目设置。

每个 Markdown 文件（包括 `00-index.md` 和分片）继续执行 500 行和 30,000 字符双重硬上限；超过任一硬限制就继续按语义拆分。

`design/00-index.md` 只列实际存在的端及其 canonical entrypoint。`tasks/00-overview.md` 是 two-end-only overview：只在 backend 和 frontend 两端计划都存在时生成；任何单端计划都不能生成 overview。双端 overview 只保存两端 canonical entrypoint、跨端依赖/执行阶段和从唯一 owner checkbox 派生的进度，不复制 task body 或 checkbox。

Consumer 先检测 canonical small file 与 split directory 的 `00-index.md`，再按 manifest 顺序读取，不能从 recursive glob、文件系统顺序或正文链接猜测分片。There is no read-only compatibility：根级 `design-backend.md` / `design-frontend.md`、任何 design/task stable-file-plus-directory pair、`prd.md` 与 `prd/` 并存、`proposal.md` 与 `proposal/` 并存，在 Producer 和 Consumer 中都直接阻塞。继续前必须明确批准迁移、合并或转移必要内容到唯一 canonical form，并删除 obsolete paths。

### 完整开发链路

`/fp-start` 执行阶段：

1. `fp-propose`：生成并确认 proposal 的小型 `proposal.md` 或拆分 `proposal/00-index.md` form。
2. `fp-brainstorm`：生成并确认技术设计；`design/00-index.md` 映射实际存在的端，每端直接选择 `design/<end>.md` 或 `design/<end>/00-index.md`。
3. `fp-plan`：生成并确认细粒度执行计划；每端直接选择 `tasks/plan-<end>.md` 或 `tasks/<end>/00-index.md`。只有双端计划才生成无 checkbox 的 `tasks/00-overview.md`；每个可执行任务的 checkbox 只存在于一个 owner file。
4. `fp-execute`：默认在当前上下文按 TDD 直接执行已确认任务，每个任务完成一次 inline 自审。
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

### 执行模式

计划确认后的默认执行入口是 `fp-execute`，它只维护简单 progress ledger，在当前上下文连续完成任务，随后运行一次独立 `fp-review`。

只有用户明确要求 `fp-execute-sdd`、SDD 或 fresh implementer/reviewer 隔离时，才使用复杂执行模式，以获得任务 brief、逐任务独立审查、修复循环和 SDD final review；不要仅根据任务规模或风险自动切换。
