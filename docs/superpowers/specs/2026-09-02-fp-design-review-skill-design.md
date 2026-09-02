# fp-design-review skill 设计（设计评审入口）

## 背景与问题

当前分支 `feat/review-friendly-doc-workflow` 的未提交改动把 `review.md` 挂在 `fp-brainstorm`：随设计文件同批写入、内容取自 Socratic 问答记忆。用户反馈两点：

1. **时机错误**：评审文档应在设计完成之后生成，而不是头脑风暴阶段。
2. **内容错误**：评审文档是给研发经理和研发工程师做开发设计评审用的，应提炼 design 设计文档中要评审的内容，而不是问答过程的副产品。

## 目标

1. `review.md` 在设计完成（设计文件写入并核验通过）之后生成，素材永远来自已落盘的设计文档。
2. 内容形态为「导航摘要 ＋ 评审关注点」：按设计章节提炼需要评审者重点审视的具体问题，每条带 design 锚点。
3. 独立 skill `fp-design-review`：既由 `fp-start` 阶段 2 自动调用，也支持 `/fp-design-review <slug>` 单独触发与刷新。

## 非目标

- 不改 Decision Ledger、proposal、design 产物契约与台账状态集。
- 不改 `skills/_shared/artifact-layout.md`：`review.md` 是 change 根单文件（仅 small form），规则由本 skill 自持。
- 不改用户指南（现有指南未描述 review.md）。
- 不改 `commands/fp-start.md`（Gate checksum 不涉及 review.md）。

## 产物与所有权

| 动作 | 文件 | 说明 |
| --- | --- | --- |
| 新增 | `skills/fp-design-review/SKILL.md` | skill 行为契约 |
| 新增 | `skills/fp-design-review/review-template.md` | review.md 输出模板 |
| 新增 | `commands/fp-design-review.md` | thin command wrapper ＋ Gate checksum，仿 `commands/fp-start.md` 模式 |
| 修改 | `README.md` | 命令表登记 `commands/fp-design-review.md`（与既有命令行一致） |
| 修改 | `skills/fp-start/SKILL.md` | 阶段 2 写入后产物确认改为调用 `fp-design-review` |
| 回滚 | `skills/fp-brainstorm/SKILL.md` | 撤销 WIP 中 review 相关三处改动（风险清单素材行、`Pre-write gate includes review.md`、写入/核验 review.md） |
| 回滚 | `skills/fp-brainstorm/design-template.md` | 删除 WIP 新增的 `## Review Summary (review.md)` 章节 |
| 修改 | `scripts/test-decision-gate-contract.ps1` | 锚点迁移到新 skill（保留 WIP 的 UTF-8 BOM 修复） |
| 修改 | `scripts/validate-plugin.ps1` | brainstorm 锚点回滚；注册新 skill；fp-start 委托锚点 |
| 修改 | `scripts/measure-context.ps1` | `Start`/`StartWithExplore` 计入 `skills\fp-design-review\SKILL.md` |

模板归消费方所有是仓库既有模式（`fp-module-review/review-entry-template.md`、`fp-final-review/final-review-package-template.md`、`fp-figma/figma-review-template.md`），`review-template.md` 放在 `skills/fp-design-review/` 下。

## fp-design-review 行为契约

### 触发方式

- **fp-start 阶段 2**：设计文件与 Decision Ledger 写入后核验通过后、向用户询问设计确认之前，加载 `fp-design-review` 生成并展示 `review.md`。
- **单独触发**：`/fp-design-review <slug>`；无 slug 参数时，若 `fp-docs/changes/` 下只有一个进行中的 change 则直接使用，多个时向用户列出并等待选择，没有则报告无可评审变更。用于评审会前刷新或手动重建。

### 读取

- 按 `skills/_shared/workspace-rules.md` 与 `skills/_shared/artifact-layout.md` canonical-first 解析 `fp-docs/changes/<slug>/design/00-index.md` 与各端选定 entry；split form 按 manifest 顺序读取全部分片。
- 读取各端 unique detailed owner 的 `### Decision Ledger`（只做统计，不复制正文）。
- 通读设计正文的数据模型、API、业务逻辑、前端章节及其中引用的现有代码路径（抽查路径素材）。

### 生成规则（`fp-docs/changes/<slug>/review.md`）

每个 change 只有一个 `review.md`，位于 change 根，与 `proposal.md`、`design/` 同级，仅 small form，按模板输出：

- **决策统计**：合并全部 owner 台账计数（共 N 项，阻塞 N / 非阻塞 N，全部终态）。
- **数据变更 / 接口变更**：计数 ＋ `design/<端>#锚点` 引用，或 `无`。
- **评审关注点（按章节）**：从设计章节提炼可评审的具体问题（checkbox 列表），每条带 design 锚点；例如字段取舍与迁移、索引是否满足查询、接口幂等、组件复用兼容性。只提炼设计文档已有内容，不得编造。
- **建议评审顺序**：高风险章节在前，逐项列出。
- **建议抽查路径**：设计中引用的现有代码 `path:line`。
- **设计入口**：`design/00-index.md`。

红线：

- 不复制 Decision Ledger 行或设计正文；不改变任何台账状态。
- 模板 `<...>` 占位符在最终产物中无效（与设计正文同一规则）。
- 设计缺失、非 canonical form 或台账存在未终态行时：阻塞并报告，不生成 review.md，不猜测内容。

### 幂等与恢复

- 重复运行按当前设计重新生成并覆盖 `review.md`；设计未变时内容稳定。
- 设计修订后由下一次触发（fp-start 或手动）刷新。
- fp-start 写入后核验发现 `review.md` 复制台账/设计正文或残留占位符时，按缺失处理：重新调用 `fp-design-review` 生成，而不是回退 fp-brainstorm。
- `review.md` 不参与 fp-start 的 Decision Ledger 门禁；它的存在性核验只属于阶段 2 写入后产物确认。

## fp-start 集成

阶段 2 写入后产物确认顺序调整为：

1. 核验 `design/00-index.md`、各端 entry、split fragments 存在（现状不变）。
2. 解析台账与 Pre-write Confirmation Evidence（现状不变）。
3. 加载 `fp-design-review` 生成 `review.md`，并向用户展示评审入口摘要（决策统计、评审关注点、建议评审顺序）。
4. 展示关键架构决策、改动模块、前端映射，询问设计确认（现状不变）。

`fp-design-review` 不是 second design finalizer：它不重扫代码库、不重推导决策、不修改设计文件与台账，只做读取→提炼→写一个 change 根文件，与 fp-start 的 No second design finalizer 边界兼容。

Resume boundary 不新增状态机：`review.md` 生成是写入后产物确认的一个步骤，恢复时按该步骤重入；设计已确认后进入阶段 3 的会话无需重新生成。

## 契约脚本

### scripts/test-decision-gate-contract.ps1

- 保留 WIP 的 UTF-8 BOM 修复（commit c0c3b42 先例：含中文锚点的契约脚本需要 BOM）。
- 移除 `design template review entry` 锚点块与 `fp-brainstorm review entry` 锚点块；`$designTemplate` 断言回到 WIP 之前的集合。
- `$startSkill` 的 review 锚点（`review.md`、`未复制决策正文`）改为 fp-start 委托 `fp-design-review` 的措辞锚点。
- 新增：`$designReviewSkill`（`skills/fp-design-review/SKILL.md`）锚点——change 根路径、模板加载、`不得复制决策正文`、`评审关注点`、阻塞规则、幂等刷新；`$reviewTemplate`（`skills/fp-design-review/review-template.md`）锚点——`评审入口` 标题、决策统计、数据变更、接口变更、评审关注点、建议评审顺序、建议抽查路径、设计入口、`不得复制决策正文`。
- 新增 `commands/fp-design-review.md` 读取与 checksum 锚点。

### scripts/validate-plugin.ps1

- brainstorm anchor 列表回滚为 WIP 之前（`Pre-write gate includes design index`，移除四个 review 锚点）。
- 注册 `fp-design-review`：skill 描述 map、`$skillAnchors` 能力锚点、必需文件清单、`skills\fp-design-review\SKILL.md` → `_shared/artifact-layout.md` 共享读取映射。
- fp-start 增加委托 `fp-design-review` 的锚点。
- 注意全局禁令扫描：`fp-review` 子串在 commands/skills/scripts/README/user_guide 全域禁止（validate-plugin.ps1:1281），`fp-design-review` 不含该子串，安全；新命令保持 ≤20 行且命令适配器总字符预算（均摊 480/命令）内。

### scripts/measure-context.ps1

- `Start` 与 `StartWithExplore` 行计入 `skills\fp-design-review\SKILL.md`（阶段 2 无条件加载）；`review-template.md` 不计（写入时 JIT 读取，与 `design-template.md` 同理）。

## commands/fp-design-review.md Gate checksum 要点

- 只从已核验的 canonical design 生成；设计缺失、dual form/historical path 或台账未终态 → 阻塞，不生成。
- 只写 change 根 `review.md`，仅 small form；不复制决策正文。
- 不修改设计文件与台账；不推进任何阶段；单独触发后报告生成路径与摘要。

## 验证

- `pwsh -File scripts/test-decision-gate-contract.ps1`
- `pwsh -File scripts/validate-plugin.ps1`
- `pwsh -File scripts/measure-context.ps1`（确认 Start 预算更新生效）
