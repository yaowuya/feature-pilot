---
name: fp-brainstorm
description: 通过苏格拉底式提问，基于 proposal.md 和可选 delta spec 生成 design.md
---


## FeaturePilot workspace and customer settings

Before choosing output paths, component-library guidance, test commands, or workflow rules, locate the target project's FeaturePilot workspace:

1. Walk upward from the current working directory to find `fp-docs/`.
2. If `fp-docs/` does not exist and this phase needs to create artifacts, create only the directories this phase actually writes to. Do not pre-create empty directories for other phases.
   - Most phases only need `fp-docs/changes/` for their artifacts.
   - Only the archive phase (`fp-archive`) creates `fp-docs/archive/` and `fp-docs/history/`.
   - `fp-init` only creates `fp-docs/settings/` and writes optional config files inside it.
3. Read any settings files that exist. Do not create or overwrite customer settings unless the user explicitly asks.

Settings are optional. If a file is missing, fall back to current project code, adjacent implementations, and public defaults only; never invent customer-specific conventions.

Recommended settings file:

- `fp-docs/settings/agent.md` — optional project-specific FeaturePilot rules, including workflow, paths, component library, design system, UI tokens, Figma mapping, and visual review requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, or workflow policy in public skills. Customer-specific rules may be described in optional `fp-docs/settings/agent.md`.

---

# FeaturePilot Brainstorm

你正在帮助用户做技术方案设计。基于已确认的 `proposal.md`，以及可选的 delta spec，通过 Socratic 问答和方案探索，生成完整的 `design.md`。

## 流程

### 第一步：读取上下文

【立即用工具执行】读取以下文件，理解功能范围与行为契约：
- `fp-docs/changes/<slug>/proposal.md`
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
> 生成的 design.md 中的前端设计章节，所有颜色、尺寸、交互行为必须引用规范中的值，不得自行发明。
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
  > - **选 A（有设计稿）**：【立即用工具执行】调用 Figma MCP 工具并触发 **本插件内** `fp-figma` 的前两步（拉取数据与骨架剥离），在这个设计阶段提前输出并写入 `design-frontend.md`：`Visual Source`、`Figma 节点/页面`、`UI 组件树与 Figma 解析映射`、项目组件映射、Flex/Grid 容器规划、不可用 项目组件的自封装理由、`Visual Checks`。**不得改用全局 `figma-to-vue`**。
  > - **选 B（无设计稿或无Figma MCP）**：完全按照 `fp-ui-spec` + `fp-ux-spec` skill 的规范和相邻真实页面搭建；仍必须在 `design-frontend.md` 写 `Visual Source: UI/UX spec + existing code`、组件映射、布局规划和 Visual Checks，不得自行发明颜色、尺寸或交互行为。
  > - **选 C（有截图）**：以截图视觉事实为准，UI/UX 规范作为补充约束；如果截图来自用户提供的原始图片，优先读取原图事实，不用屏幕截图替代原图结论；在 `design-frontend.md` 写清截图来源、可确认/不可确认的视觉点、组件映射和 Visual Checks。

- 页面/视图：新增哪些页面？菜单入口在哪里？
- 组件复用：复用现有组件还是新建？是否需要参考现有页面/组件文件骨架？
- 状态管理：沿用项目现有全局状态/数据获取方案，还是使用局部状态？
- 路由与权限守卫

**用户每次回答后**，立即将决策追加写入文档的【第一部分：架构决策】。

### 第三步：提出方案与 trade-off

收集足够决策后（通常 3-5 轮），针对核心架构提出 **2-3 个方案**，说明各自 trade-off，并给出推荐理由。等待用户确认方案后继续。

### 第四步：展示与分离技术设计 (前后端分离)

因为完整的全栈系统设计文档极易过载，涉及多个端时应拆分；但必须按实际范围生成：
1. **涉及后端时才构建 `fp-docs/changes/<slug>/design-backend.md`**：记录 DB 模型、API 契约、底层服务逻辑。
2. **涉及前端/UI 时才构建 `fp-docs/changes/<slug>/design-frontend.md`**：记录路由表、状态管理方案，**最重要的是：如果提供了 Figma，必须在这里用文字写清楚对应每一个设计区域准备使用的 项目组件映射和流式布局容器规划（取代绝对定位的 flex/grid 方案）**。

`design-frontend.md` 必须包含以下视觉连续性小节，后续 `fp-plan-frontend`、`fp-execute`、`fp-execute-sdd`、`fp-review` 都以它们为事实来源：

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

如果 proposal 和代码探索都没有前端/UI 范围，不要生成 `design-frontend.md`、前端章节或空占位文件。

按下方"设计文档格式"逐节展开，**每节展示后等待用户确认**，确认后再写入文件。

### 第五步：写入设计文件

【立即用工具执行】按实际涉及端写入设计文件，然后输出：`✅ 设计已完成，进入计划阶段`

---

## 设计文档格式

design.md 分为两部分，合并在同一文件：

```markdown
# <功能描述> — 技术方案设计

## 第一部分：架构决策

> 记录 Socratic 问答过程中的关键决策。

### 决策 1：[主题]
- **选择**：[用户的选择]
- **理由**：[用户说明的原因]

### 决策 2：[主题]
...

---

## 第二部分：技术方案详述

> 基于上述决策，展开完整的技术设计。内容和深度根据功能复杂度自由展开。
> 通常覆盖：模块/目录结构、数据模型、API 接口、业务逻辑要点、前端设计（如涉及）。

### 后端模块设计

（新建/修改的 App 目录结构，精确到文件级别）

### 数据模型

（每个 Model 的关键字段，注明类型、用途，强调 项目现有模型基类和关联规则）

### API 接口

（按项目现有 API 框架记录路由/endpoint、HTTP 方法、主要请求/响应字段）

### 业务逻辑要点

（关键算法、状态机、联动机制、异步任务等）

### 前端设计（如涉及 UI）

#### 页面/视图
（新增页面/视图路径 + 菜单入口）

#### 组件
（新建组件 + 复用现有组件清单）

#### API 模块
（按项目现有 API 客户端/请求封装位置记录文件和主要接口列表）

#### 路由
（路由定义，权限要求）

#### 状态管理
（按项目现有状态管理方案记录 store/composable/hook/context 或说明仅用局部状态）
```

---

## 提问原则

- 每次只问一个问题，等待回答后再问下一个
- 提供 2-3 个选项，同时允许自由回答
- 不要一次性抛出所有问题
- 关注 proposal 的 In Scope 范围，不扩展到 Out of Scope
- 结合当前代码中的现有架构给出有依据的选项和推荐

## 完成标准

所有 In Scope 功能的关键架构决策已记录，且仅生成实际涉及端的设计文件。
