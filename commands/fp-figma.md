---
description: 根据 Figma 链接生成或完善项目当前前端框架的 UI 实现，遵循项目本地前端/UI/UX 配置
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-figma/SKILL.md`，将「$ARGUMENTS」作为输入；该 skill 及其共享 workspace contract 是完整事实源。

Gate checksum：

- 只读当前 UI 范围需要的 Figma 节点、frontend/prototype settings 与相邻真实代码。
- 遵循项目当前框架、组件与状态模式，不假设供应商或组件前缀。
- 设计阶段只产出映射和 Visual Checks；进入实现阶段才修改业务 UI。
