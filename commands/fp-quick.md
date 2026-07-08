---
description: 快速处理小型开发需求、轻量功能、局部 bugfix 或微调优化
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
调用并严格遵守本插件内 `fp-quick` skill：`skills/fp-quick/SKILL.md`。

`fp-quick` 用于不适合走完整 proposal-design-plan 链路的小型需求：

- 先加载 `fp-propose` 并复用其项目探索与需求澄清规则，但不生成 proposal.md 或完整的 `fp-docs/changes/` 产物。
- 如果需求清晰可直接实施，输出内联实现计划并等待用户确认。
- 如果存在阻塞疑问，向用户提问澄清。
- 确认后按计划实现与验证。

完成后直接交付改动，不生成持久化流程文档。
