---
description: 根据 Figma 链接生成或完善项目当前前端框架的 UI 实现，遵循项目本地 `fp-docs/settings/agent.md` 中声明的 UI/UX 规范
---
## FeaturePilot workspace and information layer

Before choosing output paths, commands, UI/backend rules, or workflow behavior:

1. Treat the target project repository root as the FeaturePilot project root, and look only for `fp-docs/` directly under that root.
2. If `fp-docs/manifest.md` exists, read it first.
3. Read only relevant settings and intel listed by the manifest.
4. If UI/frontend is involved and `fp-docs/settings/frontend.md` exists, read it as a required source.
5. If backend/API/data/security behavior is involved and `fp-docs/settings/backend.md` exists, read it as a required source.
6. Treat settings/intel as navigation and constraints; verify exact implementation facts against current code.
7. Use two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, backend framework, API envelope, or workflow policy in public skills. Customer-specific rules belong in target-project settings.

Compatibility rule: if the project root has no `fp-docs/manifest.md`, continue from current code and existing settings when safe, recommend `/fp-init`, and do not force initialization. If the current phase must write FeaturePilot artifacts, create only the necessary artifact directories under the project-root `fp-docs/`; do not create manifest/settings/intel except through `/fp-init`.
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
