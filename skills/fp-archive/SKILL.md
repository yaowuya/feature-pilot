---
name: fp-archive
description: 归档已完成的变更：移动变更目录，更新 history.md
---
## FeaturePilot workspace and information layer

Before choosing output paths, commands, UI/backend rules, or workflow behavior:

1. Walk upward from the current working directory to find `fp-docs/`.
2. If `fp-docs/manifest.md` exists, read it first.
3. Read only relevant settings and intel listed by the manifest.
4. Treat settings/intel as navigation and constraints; verify exact implementation facts against current code.
5. Use two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, backend framework, API envelope, or workflow policy in public skills. Customer-specific rules belong in target-project settings.
---

# fp-archive — 变更归档

## 目标

将已完成的变更 `<slug>` 归档，更新项目历史记录。

## 执行步骤

### Step 1: 确定归档目标

- 若调用时已有 slug 参数 → 直接使用
- 若无参数 → 列出 `fp-docs/changes/` 下所有目录，让用户选择

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
