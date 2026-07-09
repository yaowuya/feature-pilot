---
description: 基于已确认的 PRD 或 proposal，通过苏格拉底式提问生成技术设计方案
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
调用并严格遵守本插件内 `fp-brainstorm` skill：`skills/fp-brainstorm/SKILL.md`。

`fp-brainstorm` 在你已有一个已确认的 proposal（通过 `/fp-propose` 或 `/fp-start` 生成）时使用：

- 读取 `fp-docs/changes/<slug>/proposal.md` 确认范围。
- 通过一次一个问题的苏格拉底式提问，澄清架构决策。
- 提出 2-3 个技术方案和 trade-off，等待用户确认方案。
- 按实际涉及端逐节展示设计内容，等待用户确认可以写入。
- 根据实际涉及范围生成 `design-backend.md`、`design-frontend.md` 或两者。
- 不预建后续阶段的文件（`tasks/`、`.fp-execute/` 等）。

未获得方案确认和写入确认前，不得创建或覆盖 `design-backend.md` / `design-frontend.md`。

完成后输出生成的设计文件路径；若这是独立设计流程，下一步通常是 `/fp-plan <slug>`，若已在 `/fp-start` 编排中则返回 `/fp-start` 阶段 3。
