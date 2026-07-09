---
name: fp-archive
description: 归档已完成的变更：移动变更目录，更新 history.md
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

# fp-archive — 变更归档

## 目标

将已完成的变更 `<slug>` 归档，更新项目历史记录。

## 执行步骤

### Step 1: 确定归档目标

- 若调用时已有 slug 参数 → 读取并展示目标 `fp-docs/changes/<slug>/` 的摘要，要求用户确认后再继续。
- 若无参数 → 列出 `fp-docs/changes/` 下所有目录，让用户选择。

归档会移动目录并更新历史，属于不可轻易回滚的文件操作。无论 slug 来自参数还是选择，都必须在移动前展示源路径、目标归档路径和检查摘要，并等待用户明确确认。

### Step 2: 归档前检查

借鉴 OpenSpec 的归档安全设计，归档前必须检查：

1. `tasks/` 中是否仍有未完成 checkbox。
2. `.fp-execute/progress.md` 是否存在未完成、blocked 或 failed 记录。
3. 目标归档目录 `fp-docs/archive/YYYY-MM-DD-<slug>/` 是否已存在。

如果存在未完成任务或 blocked 记录，先展示摘要并询问是否继续归档；不得静默归档。

### Step 3: 归档文件

1. **移动目录**：将 `fp-docs/changes/<slug>/` 整体移动到：
   ```
   fp-docs/archive/YYYY-MM-DD-<slug>/
   ```

### Step 4: 更新 history.md

在 `fp-docs/history/history.md` 末尾追加：

```markdown

## YYYY-MM-DD: <slug>

**目标：** （来自 proposal.md 的 Why 章节，1-2 句话）

**变更点：**
- （来自 proposal.md 的 What Changes 列表）

**归档路径：** `fp-docs/archive/YYYY-MM-DD-<slug>/`
```

### Step 5: 完成

输出：`✅ 已归档：fp-docs/archive/YYYY-MM-DD-<slug>/`
