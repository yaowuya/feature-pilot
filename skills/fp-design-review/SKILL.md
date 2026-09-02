---
name: fp-design-review
description: Use when a resolved FeaturePilot design needs a development design review entry, whether invoked from fp-start stage-2 confirmation or standalone via /fp-design-review.
---
## FeaturePilot workspace and information layer

插件资源锚定、`${CLAUDE_PLUGIN_ROOT}` 路径映射与缺失即停止规则见 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md`；不要在消费者项目中搜索 `skills/**`。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting. Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` before resolving design artifacts; it owns canonical form selection, split manifests, hard limits, conversion, and historical-layout rejection.

---

# FeaturePilot Design Review

你正在为一份已写入的设计文档生成开发设计评审入口 `fp-docs/changes/<slug>/review.md`（与 `proposal.md`、`design/` 同级的 change 根文件）。它面向研发经理与研发工程师的设计评审：只提炼设计文档中要评审的内容，供评审者按章节逐项给出结论；它不是决策记录、确认证据或 PRD/proposal/design/task artifact。

## 触发方式

- **fp-start 阶段 2**：设计文件与 Decision Ledger 写入后核验通过后、设计确认询问之前，由 `fp-start` 调用本 skill 生成并展示评审入口。
- **单独触发**：`/fp-design-review <slug>`。无 slug 参数时：`fp-docs/changes/` 下只有一个进行中的 change 则直接使用；多个时列出并等待用户选择；没有时报告无可评审变更。用于评审会前刷新或手动重建。

## 流程

### 第一步：解析设计产物（canonical-first）

按 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` 以 canonical-first Consumer 解析当前 slug 的 `design/00-index.md` 与每个实际端的选定 entry；split form 严格按 manifest order 读取全部已列分片，出现 unindexed fragment、dual form 或 historical path 即阻塞。

### 第二步：提炼评审素材（只读）

- 从每个 actual-end 的 unique detailed owner 读取 `### Decision Ledger`，只做合并计数（共 N 项、阻塞 N / 非阻塞 N、全部终态），不复制台账行。任一行非终态即阻塞，不生成 review.md。
- 通读设计正文：数据模型、API 接口、业务逻辑、前端章节，以及其中引用的现有代码路径（抽查路径素材）。
- 全部素材来自已落盘设计文档，不得编造。设计缺失或阻塞时报告原因，不生成 review.md。

### 第三步：生成 review.md

【立即用工具执行】读取 `${CLAUDE_PLUGIN_ROOT}/skills/fp-design-review/review-template.md`，按模板写入 `fp-docs/changes/<slug>/review.md`：每个 change 只有一个 review.md，只允许 small form，覆盖全部实际端；模板含决策统计、数据变更、接口变更、评审关注点、建议评审顺序、建议抽查路径与设计入口。评审关注点按设计章节分组，每条带 design 锚点；不得复制决策正文或设计正文。

## 边界与恢复

- 本 skill 不是 second design finalizer：不重扫代码库、不重推导决策、不修改设计文件与 Decision Ledger、不推进任何阶段；fp-start 调用后继续其设计确认流程。
- 幂等刷新：重复运行按当前设计重新生成并覆盖 review.md；设计修订后由下一次触发（fp-start 或单独触发）刷新。
- fp-start 核验发现 review.md 复制台账/设计正文或残留 `<...>` 占位符时，按缺失处理，修复来源设计后重新生成。
