---
name: fp-brainstorm
description: 通过苏格拉底式提问，基于 proposal.md 和可选 delta spec 生成按实际范围拆分的技术设计文件
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership. Read `../_shared/artifact-layout.md` before resolving proposal or design artifacts; it owns canonical form selection, split manifests, hard limits, conversion, and historical-layout rejection.
---

# FeaturePilot Brainstorm

你正在帮助用户做技术方案设计。基于已确认的 proposal，以及可选的 delta spec，通过 Socratic 问答和方案探索，在 `fp-docs/changes/<slug>/design/` 下为每个实际涉及端生成一种互斥（mutually exclusive）形式：`backend.md` 或 `backend/00-index.md`，`frontend.md` 或 `frontend/00-index.md`。

## 流程

### 第一步：读取上下文

【立即用工具执行】读取以下文件，理解功能范围与行为契约：
- 按 `../_shared/artifact-layout.md` 解析已确认 proposal：检查 `fp-docs/changes/<slug>/proposal.md` 与 `proposal/00-index.md`；双形式直接阻塞，split form 严格按 manifest 顺序读取全部已列分片
- 读取与本次需求相关的真实代码、测试、路由、模型、组件和 API；以当前代码为准

读取 `fp-docs/settings/` 中与当前阶段相关的客户配置；不要读取历史 `fp-docs/changes/` 或 `fp-docs/archive/` 作为设计依据。当前代码仍是最终实现事实来源。

### 第二步：Socratic 问答 — 关键决策

**每次只问一个问题**，等待用户回答后再问下一个。每个问题提供 2-3 个选项 + "其他（请描述）"。

问题维度（根据功能范围选择，不必全问）：

**后端维度：**
- 数据存储方案（DB 结构、是否需要缓存）
- 关键算法 / 状态机 / 异步任务方案
- API 风格与鉴权方式
- 与现有模块的集成边界
- 性能与安全考量

**前端维度（如功能涉及 UI）：**

> **⚠️ 涉及前端 UI 时，必须加载并遵循以下 skill（作为设计约束）：**
> - **Figma 入口必须唯一**：凡是涉及 Figma 链接、截图还原、设计稿解析，**只允许使用本插件内的 `fp-figma` skill**；**禁止使用全局 `figma-to-vue` 或其他同类 skill**，避免规范分叉。
> - `fp-docs/settings/agent.md` — 可选项目配置；如其中声明组件库、设计系统或组件映射，必须优先遵循；确实无对应组件才允许自行封装，并在 design 文档中注明原因
> - `fp-ui-spec` skill — 色彩 token、排版字号、导航/表单组件视觉状态
> - `fp-ux-spec` skill — 表单校验时机、表格操作、按钮规则、删除确认、消息通知等
> canonical frontend design 的详细内容所有者中，所有颜色、尺寸、交互行为必须引用规范中的值，不得自行发明。
>
> **Just-in-time Visual 使用原则（只在需要时打开视觉链路）：**
> - 只有当本次需求实际涉及 UI、Figma、截图还原、视觉走查或用户明确要求视觉验收时，才进入 Figma / browser / local viewer / 截图链路；纯后端、纯接口、纯脚本任务不得为了“完整流程”启动视觉工具。
> - 设计阶段只提取视觉事实与约束：Figma 节点、截图事实、现有页面视觉模式、项目组件映射、布局策略和 Visual Checks；不得在 brainstorm 阶段直接修改业务 UI 代码。
> - 若没有 Figma 或截图，Visual Checks 必须来源于 `fp-ui-spec`、`fp-ux-spec` 和相邻真实页面，不允许凭感觉补颜色、间距、交互。
> - 若后续计划/执行需要本地预览，只允许在实现到可运行页面后按 Visual Checks 做最小必要验证；不要提前启动 local viewer。

- **【必问，且最先问】Figma 设计稿**：请问此功能是否有 Figma 设计稿(需依赖Figma MCP)？
  - 选项 A：有，链接是：\_\_\_\_\_（请粘贴链接）
  - 选项 B：没有，按 UI/UX 规范搭建
  - 选项 C：有截图，将在后续步骤中提供

  > **根据回答决定后续前端实现策略，并形成可延续的视觉契约：**
  > - **选 A（有设计稿）**：【立即用工具执行】调用 Figma MCP 工具并触发 **本插件内** `fp-figma` 的前两步（拉取数据与骨架剥离），在这个设计阶段提前输出 `Visual Source`、`Figma 节点/页面`、`UI 组件树与 Figma 解析映射`、项目组件映射、Flex/Grid 容器规划、不可用项目组件的自封装理由、`Visual Checks`。这些详细小节只写入选定 frontend form 的一个详细内容所有者。**不得改用全局 `figma-to-vue`**。
  > - **选 B（无设计稿或无Figma MCP）**：完全按照 `fp-ui-spec` + `fp-ux-spec` skill 的规范和相邻真实页面搭建；仍必须在选定 frontend form 的一个详细内容所有者中写 `Visual Source: UI/UX spec + existing code`、组件映射、布局规划和 Visual Checks，不得自行发明颜色、尺寸或交互行为。
  > - **选 C（有截图）**：以截图视觉事实为准，UI/UX 规范作为补充约束；如果截图来自用户提供的原始图片，优先读取原图事实，不用屏幕截图替代原图结论；在选定 frontend form 的一个详细内容所有者中写清截图来源、可确认/不可确认的视觉点、组件映射和 Visual Checks。

- 页面/视图：新增哪些页面？菜单入口在哪里？
- 组件复用：复用现有组件还是新建？是否需要参考现有页面/组件文件骨架？
- 状态管理：沿用项目现有全局状态/数据获取方案，还是使用局部状态？
- 路由与权限守卫

**用户每次回答后**，先在会话中的“待确认架构决策摘要”记录该决策；不要立刻写文件。只有在方案、设计章节和所选 small/split form 都获得用户确认后，才写入设计文件。

### 第三步：提出方案与 trade-off

收集足够决策后（通常 3-5 轮），针对核心架构提出 **2-3 个方案**，说明各自 trade-off，并给出推荐理由。等待用户确认方案后继续。

### 第四步：展示与分离技术设计 (前后端分离)

因为完整的全栈系统设计文档极易过载，涉及多个端时应拆分；但必须按实际范围生成：
1. **涉及后端时才构建 backend design**：记录 DB 模型、API 契约、底层服务逻辑，并选择 `design/backend.md` 或 `design/backend/00-index.md`。
2. **涉及前端/UI 时才构建 frontend design**：记录路由表、状态管理方案，并选择 `design/frontend.md` 或 `design/frontend/00-index.md`；如果提供了 Figma，必须写清设计区域对应的项目组件映射和流式布局容器规划（取代绝对定位的 flex/grid 方案）。
3. **始终创建 `fp-docs/changes/<slug>/design/00-index.md`**：只列出实际存在的端，并直接链接该端选定的 canonical entry；不得让 change index 经由另一份摘要文件间接跳转。

#### Canonical design layout

新设计产物只允许写入 `fp-docs/changes/<slug>/design/`，不得创建或更新变更根目录下的旧 `design-backend.md` / `design-frontend.md`。

- 写入前选择 form。内容有多个可独立阅读的 feature、subsystem、page area 或 ownership domain 时直接选择 split form；否则选择 small form。不要先生成 monolith 再机械切割。
- Small form：后端完整内容只写入 `design/backend.md`；前端完整内容只写入 `design/frontend.md`，且不得同时创建同名目录。
- Split form：后端只写 `design/backend/00-index.md` 和 manifest 列出的编号分片，不写 `design/backend.md`；前端只写 `design/frontend/00-index.md` 和 manifest 列出的编号分片，不写 `design/frontend.md`。
- 每个文件（包括 index 和 fragment）不得超过 **500 lines** 或 **30,000 characters**；任一硬限制将被越过时必须按语义边界继续拆分。这是 fallback limit，不是拆分目标。
- 每个 end-local `00-index.md` 使用 `| Order | File | Kind | Owns |` manifest，列出每个 sibling Markdown fragment 恰好一次；index 只负责导航和 ownership metadata，禁止让下游靠 glob、目录顺序或正文链接猜测顺序。
- 详细 contract、mapping、acceptance check 各有一个 owner；其他文件只链接，不复制正文。

#### Historical layout blocker

本 skill 是 Producer，不得产出旧根目录路径或 stable-file-plus-directory 组合。创建或续写前，只检查当前 slug、当前端的 exact paths：small file、split `00-index.md`、旧根目录 `design-backend.md` / `design-frontend.md` 和任何 historical dual structure；不得递归扫描历史 change/archive。

Historical checks inspect the current slug at exact paths only. Historical files and dual structures are structural conflicts in Producer and Consumer modes; there is no compatibility read. Migration requires explicit approval, validates all transferred content, and removes every obsolete path before work continues.

- 已有单一 canonical form 时保持该 form，除非已确认内容要求转换。
- historical file 或 dual structure 立即阻塞，不读取其正文、不猜测 ownership。
- 转换或迁移必须得到 explicit approval，把全部 unique content 转入一种 canonical form，验证后移除 obsolete path；不得在原 historical dual structure 上继续更新。

Frontend design 必须让以下三个视觉连续性小节各出现恰好一次，并共同归属于一个 detailed owner：small form 时归 `design/frontend.md`；split form 时归 manifest 中一个明确的 detail fragment。`design/frontend/00-index.md` 只记录该 fragment 的 ownership，不复制正文。后续 `fp-plan-frontend`、`fp-execute`、`fp-execute-sdd`、`fp-review` 都以该唯一 owner 为事实来源：

```markdown
#### Visual Source
- 类型：Figma / 截图原图 / UI-UX spec + existing page
- 来源：Figma URL + node/page 名称，或截图/customer issue system 图片路径，或相邻页面路径
- 可信边界：哪些视觉点已确认，哪些仍需后续 local viewer 验证

#### UI 组件树与 Figma 解析映射
| 设计区域/节点 | 目标 DOM/组件层级 | 项目组件 | 布局策略 | 关键 token/尺寸 | 备注 |
|---|---|---|---|---|---|

#### Visual Checks
- [ ] <检查点必须可执行，例如：工具栏高度、输入框/按钮对齐、表格空态、主次按钮颜色、页面 padding>
- [ ] <每项注明来源：Figma node / UI spec / UX spec / existing page>
```

若没有可确认视觉来源，不得生成空泛 `Visual Checks`；必须先向用户说明缺口并提问或标记设计阻塞。

如果 proposal 和代码探索都没有前端/UI 范围，不要生成任何 frontend design form、前端章节或空占位文件。

按下方"设计文档格式"逐节展开，**每节展示后等待用户确认**，确认后再写入文件。

#### Pre-write content confirmation

这里的确认是**写入前内容确认**：用户确认推荐方案和逐节设计内容后，当前这一次 `fp-brainstorm` 调用继续完成模板读取与设计文件写入。它不是 `fp-start` 的写入后产物确认，也不授权进入计划阶段。

#### No second design finalizer

`fp-brainstorm` 是设计内容生成与设计文件写入的唯一所有者；Socratic 问答结束不是返回点。不得把已确认决策交给额外的设计收尾 Agent 或 Workflow，不得再执行全仓扫描、重新起草、契约统一、重写或多轮交叉验证。确需核验时，只对当前 slug 的 proposal、已确认设计内容和目标设计文件做一次有界一致性检查；发现阻塞则向用户说明，不得自行启动递归修订流程。

### 第五步：写入设计文件

写入设计文件前必须满足全部条件：

- 已提出 2-3 个方案和 trade-off。
- 用户已明确确认推荐方案或给出替代方案。
- 设计章节已按实际涉及端逐节展示。
- 用户已明确确认可以写入列出的设计文件、选定的 small/split form，以及转换时要移除的 obsolete path。

#### Pre-write gate includes design index

The explicit pre-write gate covers the selected form, exact target paths, `design/00-index.md` direct entries, and any obsolete path approved for removal.

未满足这些条件时，不得创建、覆盖或移除 `design/00-index.md`、任一 end small file、split index、fragment 或 obsolete path。

【立即用工具执行】读取 `design-template.md`，按实际涉及端写入设计文件。

#### Post-write handoff

Post-write verification rejects dual forms, indirect change-index links, incomplete manifests, duplicate visual ownership, hard-limit violations, and residual obsolete paths.

写入后用工具做一次有界核验：`design/00-index.md` 直接链接每个实际端的选定 entry；每端恰有 small 或 split 一种 form；split manifest 中每个 listed fragment 存在且每个 sibling Markdown 被列出一次；所有文件满足 500 lines 与 30,000 characters；视觉三小节各有唯一 owner；转换时 obsolete path 已移除。然后报告实际写入路径并输出：`✅ 设计文件已写入，返回 fp-start 进行产物核验与确认`。不得输出或暗示“进入计划阶段”，不得启动 `fp-plan`；只有外层 `fp-start` 获得写入后产物确认后才能推进阶段。

#### Resume boundary

恢复中断的 brainstorm 时，只解析当前 slug 的 proposal、`design/00-index.md`、每端 exact small/split path 和已确认的会话决策。若已有 canonical form，先验证其结构并继续该 form；若发现未获确认的 dual form、historical path 或 partial conversion，停止写入并请求用户确认迁移，不通过递归扫描或重写来“修复”。

---

## 设计文档格式

不要在 Socratic 问答期间加载输出模板。写入门禁通过后再完整读取 `design-template.md`；前端范围还必须保留上文定义的 Visual Source、组件映射和 Visual Checks 契约。

## 提问原则

- 每次只问一个问题，等待回答后再问下一个
- 提供 2-3 个选项，同时允许自由回答
- 不要一次性抛出所有问题
- 关注 proposal 的 In Scope 范围，不扩展到 Out of Scope
- 结合当前代码中的现有架构给出有依据的选项和推荐

## 完成标准

所有 In Scope 功能的关键架构决策已记录，且仅生成实际涉及端的设计文件。
