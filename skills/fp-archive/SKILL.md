---
name: fp-archive
description: 归档已完成的变更：移动变更目录，更新 history.md
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, stale-intel evidence, compatibility, and the archive-only ownership boundary.
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

1. 解析完整任务集：先读存在的 `tasks/00-overview.md`、`tasks/plan-backend.md`、`tasks/plan-frontend.md`；若存在 `tasks/backend/00-index.md` 或 `tasks/frontend/00-index.md`，必须按 index 顺序读取全部 fragments。这些 fragments 是拆分端的 task-owner files；未拆分端由稳定 plan 持有任务。不得依赖递归 glob、正文链接或文件系统顺序。
2. 校验任务完整性：indexed fragment 不得缺失，也不得存在未被 index 列出的 unindexed fragment；每个 `backend-NNN` / `frontend-NNN` task ID 和 checkbox 只能有一个 owner；`tasks/00-overview.md`、端内 index、拆分端稳定入口不得含 task checkbox；overview progress summary 必须等于 owner checkbox 派生计数。完整性失败时阻塞归档，不能用“强制归档未完成任务”绕过。
3. 只在解析出的 task-owner files 中检查未完成 checkbox。对 legacy plan，如果没有端内 index，则读取旧 `tasks/00-overview.md` 明确引用的根级 fragments；归属不明确时阻塞，不猜测。
4. 检查 `.fp-execute/progress.md` 是否存在未完成、blocked 或 failed 记录。ledger 只是恢复证据，不能覆盖 owner checkbox；两者不一致时先结合 git/实际文件/验证结果对账。
5. 检查目标归档目录 `fp-docs/archive/YYYY-MM-DD-<slug>/` 是否已存在。

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
