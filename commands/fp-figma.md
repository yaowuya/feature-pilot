---
description: 根据 Figma 链接生成或完善项目当前前端框架的 UI 实现，遵循项目本地 `fp-docs/settings/agent.md` 中声明的 UI/UX 规范
---
## FeaturePilot workspace and information layer

Before choosing output paths, commands, UI/backend rules, or workflow behavior:

1. Treat the target project repository root as the FeaturePilot project root, and look only for `fp-docs/` directly under that root.
2. If `fp-docs/manifest.md` exists, read it first.
3. Do **not** bulk-read all `fp-docs/settings/` or `fp-docs/intel/` files. Read only the smallest relevant subset for the current phase/question.
4. If UI/frontend/prototype behavior is involved and `fp-docs/settings/frontend.md` or `fp-docs/settings/prototype-style.md` exists, read only the relevant sections as required sources.
5. If backend/API/data/security behavior is involved and `fp-docs/settings/backend.md` exists, read only the relevant sections as required sources.
6. Treat generated intel as stale-prone navigation, not proof of current behavior. If intel is stale or broad, verify just-in-time from current source files.
7. Use two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, backend framework, API envelope, or workflow policy in public skills. Customer-specific rules belong in target-project settings.

Compatibility rule: if the project root has no `fp-docs/manifest.md`, continue from current code and existing settings when safe, recommend `/fp-init`, and do not force initialization. If the current phase must write FeaturePilot artifacts, create only the necessary artifact directories under the project-root `fp-docs/`; do not create manifest/settings/intel except through `/fp-init`.
## 基本规则

- Figma 相关流程统一使用 `fp-figma`
- 读取 `fp-docs/manifest.md` 作为入口；按需读取 `fp-docs/settings/frontend.md`、`fp-docs/settings/prototype-style.md`，以及 `fp-docs/settings/agent.md` 中的通用策略。
- 优先使用 `settings/frontend.md`、`settings/prototype-style.md` 或现有代码中确认的组件库、token、布局和视觉规则；没有配置时使用中性组件映射，不假设任何客户专属前缀
- 遵循项目现有前端框架和脚本/状态管理写法；不得假设 Vue、React 或特定语法
- 优先使用 Flex / Grid，避免滥用 `position: absolute`

## 执行步骤

1. 读取 Figma 结构与关键样式，仅关注 content 区域和用户指定节点；截图只能作为截图事实，不能替代 Figma 源事实。
2. 分析页面结构、组件映射和布局方式，输出可延续的节点路径、区域拆解、组件映射、Flex/Grid 容器规划和 Visual Checks。
3. 若当前处于 brainstorm/design 阶段，只把映射和 Visual Checks 写入 `design-frontend.md`，不得直接写业务 UI 文件。
4. 若用户直接执行 Figma 还原或后续计划已确认实现目标，再按项目已确认的框架、组件文件类型、脚本/状态管理和样式约定生成目标文件；无法从 settings 或现有代码确认时，先向用户提问，不要猜测框架。
5. 写入目标文件并执行 Lint 修复。
6. 页面可运行后再按 Visual Checks 做 just-in-time 本地预览/浏览器验证；不得提前启动 local viewer。
