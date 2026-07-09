---
description: 归档已完成的变更
---
## FeaturePilot workspace and information layer

Before choosing output paths, commands, UI/backend rules, or workflow behavior:

1. Treat the target project repository root as the FeaturePilot project root, and look only for `fp-docs/` directly under that root.
2. If `fp-docs/manifest.md` exists, read it first.
3. Do **not** bulk-read all `fp-docs/settings/` or `fp-docs/intel/` files. Read only the smallest relevant subset for the current phase/question.
4. Treat generated intel as stale-prone navigation, not proof of current behavior. If intel is stale or broad, verify just-in-time from current source files.
5. Use two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, backend framework, API envelope, or workflow policy in public skills. Customer-specific rules belong in target-project settings.

Compatibility rule: if the project root has no `fp-docs/manifest.md`, continue from current code and existing settings when safe, recommend `/fp-init`, and do not force initialization. `fp-archive` must not create or repair manifest/settings/intel. Its only confirmed outputs are moving the selected change directory into `fp-docs/archive/` and updating `fp-docs/history/history.md`.
---

**现在开始：** 根据「$ARGUMENTS」调用 fp-archive skill。

## Hard gate

归档会移动 `fp-docs/changes/<slug>/` 并更新历史文件。即使命令参数里提供了 slug，也必须先展示源路径、目标归档路径、未完成任务检查摘要，并等待用户明确确认后才能移动目录或写 `history.md`。
