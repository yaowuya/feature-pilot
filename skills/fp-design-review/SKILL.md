---
name: fp-design-review
description: Use when a resolved FeaturePilot design needs a development design review entry, whether invoked from fp-start stage-2 confirmation or standalone via /fp-design-review.
---
## FeaturePilot workspace and information layer

插件资源锚定、`${CLAUDE_PLUGIN_ROOT}` 路径映射与缺失即停止规则见 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md`；不要在消费者项目中搜索 `skills/**`。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting. Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` before resolving design artifacts; it owns canonical form selection, split manifests, hard limits, conversion, and historical-layout rejection. Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/decision-ledger.md` before validating design owners; it owns the exact ledger schema, terminal evidence, Covered IDs, and explicit write authorization.

---

# FeaturePilot Design Review

你正在为一份已写入的设计文档生成开发设计评审入口 `fp-docs/changes/<slug>/review.md`（与 `proposal.md`、`design/` 同级的 change 根文件）。它面向研发经理与研发工程师的设计评审：只提炼设计文档中要评审的内容，供评审者按章节逐项给出结论；它不是决策记录、确认证据或 PRD/proposal/design/task artifact。

## 触发方式

- **fp-start 阶段 2**：设计文件与 Decision Ledger 写入后核验通过后、设计确认询问之前，由 `fp-start` 调用本 skill 生成并展示评审入口。
- **单独触发**：`/fp-design-review <slug>`。无 slug 参数时：`fp-docs/changes/` 下只有一个进行中的 change 则直接使用；多个时列出并等待用户选择；没有时报告无可评审变更。用于评审会前刷新或手动重建。

## 流程

### 第一步：解析设计产物（canonical-first）

按 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` 以 canonical-first Consumer 解析当前 slug 的 `design/00-index.md` 与每个实际端的选定 entry；split form 严格按 manifest order 读取全部已列分片，出现 unindexed fragment、dual form 或 historical path 即阻塞。

### 第二步：确认设计门禁证据并提炼评审素材（只读）

在读取设计正文或执行充分性检查前，按 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/decision-ledger.md` 验证每个 actual-end 的 unique detailed owner：

- `### Decision Ledger` 必须使用精确表头；每行 ID、Decision、Blocking、Status、concrete Source 与 Evidence / explicit confirmation 均有效，且 Status 必须属于既定终态。
- Source、Evidence 和授权不得包含 `placeholder`、`TBD`、`TODO`、`unknown`、generic `user answer`、bare `ID: user answer` 或 sample authorization。
- `### Pre-write Confirmation Evidence` 必须与同一 owner 的台账逐项对应。
- `Covered IDs` 必须与该 owner 的台账 ID 集合完全相等；`Outstanding blocking decisions` 必须为 `none`；必须包含 concrete `Explicit user authorization to write`。
- 所有 owner 合并后必须保持 globally unique D-NNN sequence；跨端决策只能由一个 owner 持有。

门禁证据无效时不得生成、覆盖或删除 `review.md`，必须保留任何已有 `review.md`。输出具体 owner、无效字段和需恢复的 `D-NNN`，返回 `fp-brainstorm` 做 targeted recovery confirmation；不得继续充分性检查或生成部分评审。

门禁证据全部有效后：

- 合并统计 Decision Ledger（共 N 项、阻塞 N / 非阻塞 N、全部终态），不复制台账行。
- 通读 canonical design 正文，提取业务和技术主线、核心对象、数据模型、状态与并发、API 与权限、前端方案、风险、迁移、发布、验证，以及正文已引用的现有代码路径。
- 全部素材只来自已落盘、已确认的 canonical design，不得编造设计事实。

### 第三步：设计充分性检查

生成前，按每个 actual-end 的 resolved logical design 读取 `设计范围适用性`。架构主线、核心对象与职责、具体风险或有证据的无风险结论、验证方案属于必填范围，必须有 canonical owner section 与证据。数据模型、状态/并发、接口/权限/兼容和前端属于条件范围：标记适用时必须有 owner section；标记不适用时 owner 为 `N/A`，由 inventory 行提供证据化理由，并允许省略对应正文。缺少 inventory、必填 owner、适用条件范围 owner 或证据化理由即视为设计不足。每个 owner 只提供其范围事实，不得为满足评审结构跨范围复制内容。

除数据模型外，按适用范围检查：

- 架构主线的触发、处理、状态变化、结果和失败收束；
- 按 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/engineering-quality.md` 检查设计是否说明满足当前验收的最简单可行方案、既有代码与框架复用，以及新增抽象、层、组件、依赖、缓存、异步或配置的当前必要性证据；未来可能需要不能单独成立；
- 已记录的简化取舍是否保留当前验收、安全、权限隔离和数据一致性；有意延后项是否在唯一决策或风险 owner 说明内容与原因、适用上限、可验证升级触发条件及升级方向，无延后项是否明确写“无”；
- 设计代码草图是否包含共享契约要求的 docstring/必要注释，验证安排是否覆盖简化边界和实现时的注释自审；
- 核心对象的职责、非职责、协作关系和 design 锚点；
- 状态入口、并发控制、执行顺序、失败恢复和可观察结果；
- 接口资源与标识、权限、新旧入口的兼容或隔离边界；
- 前端页面、组件、状态、路由、视觉来源和可执行 Visual Checks；
- 具体失败场景与影响，以及已确认的迁移、发布、回滚、监控和验证安排。

数据模型范围至少包含：

- 完整字段定义或接近实现的模型代码；
- 字段与存储取舍理由；
- 查询模式与索引映射；
- 继承字段和重复存储结论；
- 逻辑模型与物理表映射；
- 关联、索引、唯一约束和软删除规则；
- 项目规范证据；
- migration 影响。

若适用信息不足，不生成或覆盖 `review.md`。输出“无法生成 review.md”、逐项缺失内容、需要修订的精确 design 章节，以及“返回 `fp-brainstorm` 做定点修订并重新确认设计”。不得只写“设计不完整”或“请补充信息”，不得重新扫描代码库、修改设计或自行补齐字段。

适用的复杂度依据、简化取舍或代码草图必要说明缺失时，沿用上述 targeted revision；只依据 canonical design 评审，不扫描源码补证，不编造精简方案，不新增 debt 产物。

### 第四步：生成 review.md

【立即用工具执行】设计充分性检查通过后，读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/document-style.md`，再读取 `${CLAUDE_PLUGIN_ROOT}/skills/fp-design-review/review-template.md`，生成 change 根唯一的 small-form `review.md`。

按模板写入 `fp-docs/changes/<slug>/review.md`，覆盖全部实际端。生成独立可读的完整评审文档，将决策统计、评审关注点、建议评审顺序和建议抽查路径组织进完整主线；不得复制台账行或机械复制叙述性设计正文。只有 review template 授权的模型代码或完整字段定义表可以从 canonical design 精确摘录一种，不得重复字段事实或编造设计事实。

生成成功后报告实际 `review.md` 路径，并展示评审结论、业务和技术主线、主要风险与建议评审顺序。单独触发时在此结束；`fp-start` 调用时返回其写入后设计确认步骤。

## 边界与恢复

- 本 skill 是只读 canonical-design Consumer，不是 second design finalizer：不得重新扫描代码库，不得重推导决策，不得修改设计文件或 Decision Ledger，不得改变台账状态或推进任何阶段；`fp-start` 调用后继续其设计确认流程。
- 幂等刷新只在设计充分性检查通过后成立：重复运行可按当前 canonical design 重新生成并覆盖唯一 `review.md`。设计充分性检查失败时必须保留任何已有 `review.md`，不得写入或覆盖部分评审。
- 若发现 `review.md` 复制台账行、机械复制设计正文、残留 `<...>` 占位符、产生第二个设计入口，或超出 500 lines / 30,000 characters，则不得交付；在不修改设计事实的前提下重新生成。若根因是 canonical design 信息不足，按缺失清单返回 `fp-brainstorm` 定点修订并重新确认。
