---
name: fp-archive
description: 归档已完成的变更：移动变更目录，更新 history.md
---
## FeaturePilot workspace and information layer

插件资源锚定、`${CLAUDE_PLUGIN_ROOT}` 路径映射与缺失即停止规则见 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md`；不要在消费者项目中搜索 `skills/**`。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, stale-intel evidence, compatibility, and the archive-only ownership boundary.
Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` once before resolving the archive candidate; it is the normative layout and validation contract.
Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/ui-e2e-contract.md` once before checking a UI-bearing archive candidate; it owns the non-waivable UI/E2E archive boundary.

叙述性内容默认使用中文；代码、命令、路径、技术标识符、API 字段以及契约要求精确匹配的英文 schema 标题保留必要英文。若用户或目标项目设置明确指定其他语言，按共享优先级执行。
---

# fp-archive — 变更归档

## 目标

将已完成的变更 `<slug>` 归档，更新项目历史记录。

## 执行步骤

### Step 1: 确定归档目标

- 若调用时已有 slug 参数 → 确定目标 `fp-docs/changes/<slug>/`；先完成归档前检查，再展示摘要并要求用户确认。
- 若无参数 → 列出 `fp-docs/changes/` 下所有目录，让用户选择。

归档会移动目录并更新历史，属于不可轻易回滚的文件操作。无论 slug 来自参数还是选择，都必须在移动前完成所有归档前检查（包括 UI/E2E Final Gate），再展示源路径、目标归档路径和检查摘要，并等待用户明确确认。

### Step 2: 归档前检查

借鉴 OpenSpec 的归档安全设计，归档前必须检查：

1. canonical-first Consumer: Detect both alternatives before reading either: `prd.md` or `prd/00-index.md`; `proposal.md` or `proposal/00-index.md`; `design/backend.md` or `design/backend/00-index.md`; `design/frontend.md` or `design/frontend/00-index.md`; `tasks/plan-backend.md` or `tasks/backend/00-index.md`; `tasks/plan-frontend.md` or `tasks/frontend/00-index.md`。
2. Producer output 应只有一种 canonical form。归档 Consumer 把 indexless split、任何 historical path 和任何 dual form 都作为 structural conflict 阻塞。There is no read-only compatibility；必须先迁移为唯一 canonical form 并删除 obsolete paths。
3. Split `00-index.md` 是 sole canonical entry；解析 manifest 并按 exact manifest order 读取所有 listed fragments。缺失/重复 entry、duplicate owner 或 unindexed fragment 都阻塞；不得使用 recursive glob、正文链接或文件系统顺序。
4. Split plan 只有 manifest Kind=`tasks` 的 `tasks`-kind fragments 是 task-owner files。每个 ID/checkbox 必须有一个 unique task owner；index、context/interface/coverage 和 overview 禁止 executable checkbox。Missing reference、duplicate ID/checkbox 或 dependency cycle 都阻塞。
5. `tasks/00-overview.md` exists exactly when both backend and frontend plans exist. A single-end plan never has an overview. 仅两端 overview 才校验 cross-end edges/cycles，并从 owner checkbox 重算 derived progress；single-end 不创建、不要求、不重算 overview。
6. 只在解析出的 task-owner files 中检查未完成 checkbox；再检查 `.fp-execute/progress.md` 的 unfinished/blocked/failed 记录。ledger 只是恢复证据，冲突时结合 git、实际文件和验证结果对账。
7. 检查目标归档目录 `fp-docs/archive/YYYY-MM-DD-<slug>/` 是否已存在。

### Step 2.1: UI/E2E Final Gate

在展示移动摘要或请求用户确认前，读取当前 change 的最新（latest）final review 报告及其 `UI/E2E Gate`，并核对该 gate 引用的 task/case evidence、coverage matrix 与 cleanup 记录。报告必须能证明它覆盖当前目标快照；报告或 gate 缺失、过期、歧义，或引用证据缺失，都使归档 `BLOCKED`。

`UI/E2E Gate: FAIL` 或 `BLOCKED` 时，任何 core UI/E2E gap、mock violation、unsafe unverified real-environment condition、missing required E2E/matrix、`Mocked Core API` 非 `false`、cleanup 缺失或 lifecycle `BLOCKED` 都必须阻止归档；不得展示“继续归档”的确认选项。The archive must not proceed on `FAIL` or `BLOCKED`. A user confirmation cannot override or waive this gate. 该读取只消费 final review/evidence，not a second completion authority。

只有通过的 `UI/E2E Gate: PASS`，或最新报告的 `UI Case Inventory / N/A Reconciliation` 已证明当前快照零 UI-bearing source、无 Figma UI scope、无 mapped-current/unowned frontend diff 的 `N/A`，才能继续普通归档检查。漏登记 UI-bearing source 是 `FAIL` 或 `BLOCKED`，不得用 `N/A` 继续。若仍有 ordinary non-core incomplete task 或普通非核心 blocked 记录，才展示摘要并询问是否继续归档；必须先确认它不属于 UI/E2E core gate，且不得静默归档。

### Step 2.2: Figma Completion Gate

在展示移动摘要或请求用户确认前，当当前 scope 使用 `fp-figma` 时，读取覆盖当前快照的 latest final review、`Figma Completion Status: COMPLETE`、每项 required `FIGCAP-*`、core `PRES-*`、core Visual Case 结果，以及 independent Figma review。报告、状态、证据或审查缺失、过期或歧义都使归档 `BLOCKED`。

任一 `FAIL`、`CANNOT_VERIFY`、`BLOCKED` 或 `INCOMPLETE` 都必须阻止归档；只有每项 required `FIGCAP-*`、core `PRES-*`、core Visual Case 为 `PASS` 且 Figma Completion Status 为 `COMPLETE` 才能继续。The archive must not proceed on `FAIL`, `CANNOT_VERIFY`, `BLOCKED`, or `INCOMPLETE`. A user confirmation cannot override or waive this gate. 该读取只消费 final review/evidence，not a second completion authority。

### Step 3: 展示并确认

仅在 Step 2、Step 2.1 和适用的 Step 2.2 通过后，展示源路径、目标归档路径、结构检查摘要、UI/E2E Gate/Figma Completion 结果，以及 ordinary non-core 未完成项；等待用户明确确认后才继续。

### Step 4: 归档文件

1. **移动目录**：将 `fp-docs/changes/<slug>/` 整体移动到：
   ```
   fp-docs/archive/YYYY-MM-DD-<slug>/
   ```

### Step 5: 更新 history.md

在 `fp-docs/history/history.md` 末尾追加：

```markdown

## YYYY-MM-DD: <slug>

**目标：** （来自 resolved proposal logical content 的 Why 章节，可能在 `proposal.md` 或 manifest-ordered split fragment，1-2 句话）

**变更点：**
- （来自 resolved proposal logical content 的 What Changes 列表）

**结构冲突：** （canonical resolution 拒绝的 exact historical/dual paths；没有则写 None）

**归档路径：** `fp-docs/archive/YYYY-MM-DD-<slug>/`
```

### Step 6: 完成

输出：`✅ 已归档：fp-docs/archive/YYYY-MM-DD-<slug>/`
