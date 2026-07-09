---
description: 快速处理小型开发需求、轻量功能、局部 bugfix 或微调优化
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
调用并严格遵守本插件内 `fp-quick` skill：`skills/fp-quick/SKILL.md`。

`fp-quick` 用于不适合走完整 proposal-design-plan 链路的小型需求：

- Claude Code 运行时必须加载 `fp-propose` skill；Codex/Markdown agents 必须读取 `skills/fp-propose/SKILL.md` 并只复用其中的探索与澄清规则，不生成 proposal.md 或完整的 `fp-docs/changes/` 产物。
- 如果需求清晰可直接实施，输出内联实现计划并等待用户确认。
- 如果存在阻塞疑问，向用户提问澄清。
- 确认后按计划实现与验证。

完成后直接交付改动，不生成持久化流程文档。
