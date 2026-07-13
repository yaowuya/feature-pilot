---
name: fp-archive
description: 归档已完成的变更：移动变更目录，更新 history.md
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, stale-intel evidence, compatibility, and the archive-only ownership boundary.
Read `../_shared/artifact-layout.md` once before resolving the archive candidate; it is the normative layout and validation contract.

叙述性内容默认使用中文；代码、命令、路径、技术标识符、API 字段以及契约要求精确匹配的英文 schema 标题保留必要英文。若用户或目标项目设置明确指定其他语言，按共享优先级执行。
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

1. canonical-first Consumer: Detect both alternatives before reading either: `prd.md` or `prd/00-index.md`; `proposal.md` or `proposal/00-index.md`; `design/backend.md` or `design/backend/00-index.md`; `design/frontend.md` or `design/frontend/00-index.md`; `tasks/plan-backend.md` or `tasks/backend/00-index.md`; `tasks/plan-frontend.md` or `tasks/frontend/00-index.md`。
2. Producer output 应只有一种 canonical form。归档 Consumer 把 indexless split、任何 historical path 和任何 dual form 都作为 structural conflict 阻塞。There is no read-only compatibility；必须先迁移为唯一 canonical form 并删除 obsolete paths。
3. Split `00-index.md` 是 sole canonical entry；解析 manifest 并按 exact manifest order 读取所有 listed fragments。缺失/重复 entry、duplicate owner 或 unindexed fragment 都阻塞；不得使用 recursive glob、正文链接或文件系统顺序。
4. Split plan 只有 manifest Kind=`tasks` 的 `tasks`-kind fragments 是 task-owner files。每个 ID/checkbox 必须有一个 unique task owner；index、context/interface/coverage 和 overview 禁止 executable checkbox。Missing reference、duplicate ID/checkbox 或 dependency cycle 都阻塞。
5. `tasks/00-overview.md` exists exactly when both backend and frontend plans exist. A single-end plan never has an overview. 仅两端 overview 才校验 cross-end edges/cycles，并从 owner checkbox 重算 derived progress；single-end 不创建、不要求、不重算 overview。
6. 只在解析出的 task-owner files 中检查未完成 checkbox；再检查 `.fp-execute/progress.md` 的 unfinished/blocked/failed 记录。ledger 只是恢复证据，冲突时结合 git、实际文件和验证结果对账。
7. 检查目标归档目录 `fp-docs/archive/YYYY-MM-DD-<slug>/` 是否已存在。

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

**目标：** （来自 resolved proposal logical content 的 Why 章节，可能在 `proposal.md` 或 manifest-ordered split fragment，1-2 句话）

**变更点：**
- （来自 resolved proposal logical content 的 What Changes 列表）

**结构冲突：** （canonical resolution 拒绝的 exact historical/dual paths；没有则写 None）

**归档路径：** `fp-docs/archive/YYYY-MM-DD-<slug>/`
```

### Step 5: 完成

输出：`✅ 已归档：fp-docs/archive/YYYY-MM-DD-<slug>/`
