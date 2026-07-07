---
name: fp-figma
description: 根据 Figma 链接高保真还原 Vue 组件，遵循项目本地 `fp-docs/settings/agent.md` 中声明的 UI/UX 规范
---

# FeaturePilot Figma


## FeaturePilot workspace

执行命令前，先遵守目标项目的 `fp-docs` 契约：如需生成产物，使用 `fp-docs/changes/`、`fp-docs/archive/`；如存在 `fp-docs/settings/agent.md`，先读取与当前阶段相关的配置。不要创建或覆盖客户 settings，除非用户明确要求。
用于根据 Figma 链接还原 Vue 组件。

**Figma 链接：** 用户在命令中提供的链接。

## 基本规则

- Figma 相关流程统一使用 `fp-figma`
- 先读取 `fp-docs/settings/agent.md`；如其中声明组件库、UI token、UX 规则或 Figma 映射规则，必须遵循
- 优先使用项目 settings 或现有代码中确认的组件库；没有配置时使用中性组件映射，不假设任何客户专属前缀
- project frontend framework 统一使用 `the project-standard script pattern`
- 优先使用 Flex / Grid，避免滥用 `position: absolute`

## 执行步骤

1. 读取 Figma 结构与关键样式，仅关注 content 区域。
2. 分析页面结构、组件映射和布局方式。
3. 生成包含 `<template>`、`the project-standard script pattern`、`<style lang="scss" scoped>` 的 `.vue` 文件。
4. 写入目标文件并执行 Lint 修复。
5. 如有需要，结合设计稿与页面截图继续微调。
