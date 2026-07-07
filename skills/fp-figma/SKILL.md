---
name: fp-figma
description: 根据 Figma 链接高保真还原 Vue 组件，遵循项目本地 `fp-docs/settings/agent.md` 中声明的 UI/UX 规范
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

# FeaturePilot Figma

用于根据 Figma 链接还原 Vue 组件。

**Figma 链接：** 用户在命令中提供的链接。

## 基本规则

- Figma 相关流程统一使用 `fp-figma`；禁止切换到全局 `figma-to-vue` 或其他同类 skill。
- 同时遵循 `fp-docs/settings/agent.md`、`fp-ui-spec`、`fp-ux-spec`。
- 优先使用项目 settings 或现有代码中确认的组件库；没有配置时使用中性组件映射，不假设任何客户专属前缀；确实无对应组件才允许自行封装，并写明原因。
- project frontend framework 统一使用 `the project-standard script pattern`。
- 优先使用 Flex / Grid，避免滥用 `position: absolute`；Figma 里的绝对坐标只能作为测量参考，不能直接复制成脆弱布局。
- 只读取与当前任务相关的 Figma 页面、frame、component 和 variant；不要全量遍历无关设计稿。
- Figma 结果必须可被后续阶段延续：输出节点路径、区域拆解、项目组件映射、布局容器、token/尺寸和 Visual Checks，不只输出最终 `.vue`。
- 如需 local viewer / browser 预览，必须等页面可运行后 just-in-time 启动；只绑定 localhost，不服务无关目录，不读取 dotfile/symlink，不把预览截图当作 Figma 源事实。

## 执行步骤

1. 读取 Figma 结构与关键样式，仅关注 content 区域和用户指定节点；记录页面名、frame 名、node id、关键尺寸、颜色、字号、间距、状态和可复用组件。
2. 分析页面结构、组件映射和布局方式，生成 `UI 组件树与 Figma 解析映射`：每个设计区域对应目标 DOM 层级、项目组件、slot、Flex/Grid 容器、关键 token、需要自封装的原因。
3. 生成 `Visual Checks`：每项必须能在 local viewer / browser 里检查，且能追溯到具体 Figma 节点或 UI/UX 规范；避免“看起来一致”这种不可执行描述。
4. 若当前处于 `fp-brainstorm` 设计阶段，只把步骤 1-3 的结果写入 `design-frontend.md`，不得直接写业务 `.vue` 文件。
5. 若用户直接执行 Figma 还原或后续计划已确认实现目标，再生成包含 `<template>`、`the project-standard script pattern`、`<style lang="scss" scoped>` 的 `.vue` 文件。
6. 写入目标文件并执行 Lint 修复。
7. 如有需要，等页面可运行后再按 `Visual Checks` 启动本地预览/浏览器截图做 just-in-time 微调；不得提前启动 local viewer，也不得把截图当作 Figma 源事实替代。
