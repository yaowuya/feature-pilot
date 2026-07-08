---
description: 根据 Figma 链接生成或完善项目当前前端框架的 UI 实现，遵循项目本地 `fp-docs/settings/agent.md` 中声明的 UI/UX 规范
---

# FeaturePilot Figma


## FeaturePilot workspace

执行命令前，先遵守目标项目的 `fp-docs` 契约：如需生成产物，使用 `fp-docs/changes/`、`fp-docs/archive/`；如存在 `fp-docs/settings/agent.md`，先读取与当前阶段相关的配置。不要创建或覆盖客户 settings，除非用户明确要求。
用于根据 Figma 链接生成或完善项目当前前端框架的 UI 实现。

**Figma 链接：** 用户在命令中提供的链接。

## 基本规则

- Figma 相关流程统一使用 `fp-figma`
- 先读取 `fp-docs/settings/agent.md`；如其中声明组件库、UI token、UX 规则或 Figma 映射规则，必须遵循
- 优先使用项目 settings 或现有代码中确认的组件库；没有配置时使用中性组件映射，不假设任何客户专属前缀
- 遵循项目现有前端框架和脚本/状态管理写法；不得假设 Vue、React 或特定语法
- 优先使用 Flex / Grid，避免滥用 `position: absolute`

## 执行步骤

1. 读取 Figma 结构与关键样式，仅关注 content 区域。
2. 分析页面结构、组件映射和布局方式。
3. 按项目已确认的框架、组件文件类型、脚本/状态管理和样式约定生成目标文件；无法从 settings 或现有代码确认时，先向用户提问，不要猜测框架。
4. 写入目标文件并执行 Lint 修复。
5. 如有需要，结合设计稿与页面截图继续微调。
