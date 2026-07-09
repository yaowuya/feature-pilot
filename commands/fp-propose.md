---
description: 仅生成变更提案文档，不进入后续阶段
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
---

**现在开始：** 根据「$ARGUMENTS」调用 fp-propose skill。

## Hard gate

`/fp-propose` 只能在用户确认 proposal 摘要后写入 `proposal.md`。

- 如果需求不完整，先按 `fp-propose` 的 Socratic 规则提问。
- 如果需求看似完整，也必须先展示 Why / What Changes / Out of Scope / Impact 摘要并等待用户明确确认。
- 未确认前，不得创建 `fp-docs/changes/<slug>/`，不得写 `proposal.md`。
- 输出只能位于项目根目录下的 `fp-docs/changes/<slug>/proposal.md`。
