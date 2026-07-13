---
name: fp-figma
description: 根据 Figma 链接生成或完善项目当前前端框架的 UI 实现，遵循项目本地 `fp-docs/settings/frontend.md`、`prototype-style.md` 和通用 `agent.md` 中声明的 UI/UX 规范
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership. Read `../_shared/artifact-layout.md` before resolving or writing design artifacts; it owns exclusive forms, manifests, hard limits, conversion, and historical-layout rejection.
---

# FeaturePilot Figma

用于根据 Figma 链接生成或完善项目当前前端框架的 UI 实现。

**Figma 链接：** 用户在命令中提供的链接。

## 基本规则

- Figma 相关流程统一使用 `fp-figma`；禁止切换到全局 `figma-to-vue` 或其他同类 skill。
- 同时遵循 `fp-docs/settings/frontend.md`、`fp-docs/settings/prototype-style.md`（如与原型/视觉风格相关）、`fp-docs/settings/agent.md` 中的通用策略、`fp-ui-spec`、`fp-ux-spec`。
- 优先使用项目 settings 或现有代码中确认的组件库；没有配置时使用中性组件映射，不假设任何客户专属前缀；确实无对应组件才允许自行封装，并写明原因。
- 遵循项目现有前端框架和脚本/状态管理写法；不得假设 Vue、React 或特定语法。
- 优先使用 Flex / Grid，避免滥用 `position: absolute`；Figma 里的绝对坐标只能作为测量参考，不能直接复制成脆弱布局。
- 只读取与当前任务相关的 Figma 页面、frame、component 和 variant；不要全量遍历无关设计稿。
- Figma 结果必须可被后续阶段延续：输出节点路径、区域拆解、项目组件映射、布局容器、token/尺寸和 Visual Checks，不只输出最终 UI 文件。
- 如需 local viewer / browser 预览，必须等页面可运行后 just-in-time 启动；只绑定 localhost，不服务无关目录，不读取 dotfile/symlink，不把预览截图当作 Figma 源事实。

## Canonical design layout

处于 `fp-brainstorm` 阶段时，frontend design 使用 mutually exclusive form：small form 仅有 `design/frontend.md`；split form 仅有 `design/frontend/00-index.md` 与 manifest 列出的 `design/frontend/<number>-<area>.md`。`design/00-index.md` 必须直接链接已选择的 frontend entry，不经另一份摘要文件跳转。

Figma writes the chosen frontend file OR the frontend directory fragments and index, never both representations.

写入前沿用 `fp-brainstorm` 已确认的 form；若尚未选择，默认选择 small form。只有预计 small form 超过 500 行或 30,000 字符、用户明确批准 split form，或目标项目设置明确要求 split form 时才拆分；多个 feature、subsystem、page area 或 ownership domain 仅用于已选 split form 的分片边界，不单独触发拆分。任何 index 或 fragment 不得超过 **500 lines** 或 **30,000 characters**，越过任一 hard fallback limit 都必须继续按语义拆分，不得先写 monolith 再机械切割。

### No orphan fragment writes

不得单独写入分片。

- Split form 写入或更新 `design/frontend/<number>-<area>.md` 时，必须在同一次操作中确保 `design/frontend/00-index.md` 的 `| Order | File | Kind | Owns |` manifest 将每个 sibling Markdown fragment 列出恰好一次，并让 `design/00-index.md` 直接链接 `design/frontend/00-index.md`；split writes preserve both required indexes。
- Split form 不得创建或保留 `design/frontend.md`。
- Small form 只更新 `design/frontend.md`，让 change index 直接链接它，并且不创建 frontend directory。
- 若当前 `fp-brainstorm` 尚未通过包含 exact paths、所选 form 和转换移除项的写入前内容确认，不得提前创建、覆盖或移除任何设计产物。

创建或更新前只检查当前 slug 的 `design/frontend.md`、`design/frontend/00-index.md`、旧根目录 `design-frontend.md` 和 historical dual structure。已有单一 canonical form 时保持该 form；任何 historical path 或 dual form 都是 structural conflict，禁止读取正文或继续写入。迁移需要 explicit approval、转移全部 unique content、验证并移除 obsolete path；不得扫描历史 change/archive。

There is no read-only compatibility for historical files or pairs; Figma blocks until one canonical form has been validated.

## 执行步骤

1. 读取 Figma 结构与关键样式，仅关注 content 区域和用户指定节点；记录页面名、frame 名、node id、关键尺寸、颜色、字号、间距、状态和可复用组件。
2. 分析页面结构、组件映射和布局方式，生成 `UI 组件树与 Figma 解析映射`：每个设计区域对应目标 DOM 层级、项目组件、slot、Flex/Grid 容器、关键 token、需要自封装的原因。
3. 生成 `Visual Checks`：每项必须能在 local viewer / browser 里检查，且能追溯到具体 Figma 节点或 UI/UX 规范；避免“看起来一致”这种不可执行描述。`Visual Source`、组件映射和 `Visual Checks` 必须共同写入一个 detailed owner，且各出现恰好一次；split index 只记录 ownership metadata，不复制正文。
4. 若当前处于 `fp-brainstorm` 设计阶段，只把步骤 1-3 的结果写入 small form 的 `design/frontend.md`，或 split form 中一个由 `design/frontend/00-index.md` manifest 列出的 detail fragment，不得直接写业务 UI 文件。写后验证互斥 form、direct change-index link、manifest completeness、唯一 visual owner 和两项 hard limits。
5. 若用户直接执行 Figma 还原或后续计划已确认实现目标，再按项目已确认的框架、组件文件类型、脚本/状态管理和样式约定生成目标文件；无法从 settings 或现有代码确认时，先向用户提问，不要猜测框架。
6. 写入目标文件并执行 Lint 修复。
7. 如有需要，等页面可运行后再按 `Visual Checks` 启动本地预览/浏览器截图做 just-in-time 微调；不得提前启动 local viewer，也不得把截图当作 Figma 源事实替代。
