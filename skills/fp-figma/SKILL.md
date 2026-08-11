---
name: fp-figma
description: 根据 Figma 链接生成或完善项目当前前端框架的 UI 实现，遵循项目本地 `fp-docs/settings/frontend.md`、`prototype-style.md` 和通用 `agent.md` 中声明的 UI/UX 规范
---
## FeaturePilot workspace and information layer

If any anchored plugin resource is missing or unreadable, stop, report the exact resource and an incomplete FeaturePilot installation/cache, and never search the consumer repository for `skills/**` or continue without it.
下文以 `${CLAUDE_PLUGIN_ROOT}/...` 表示 Claude Code 安装后的插件资源。在 Codex/Markdown 中，从 available-skill 元数据提供的当前技能入口映射同一个 `skills/...` 插件相对路径。两端都不得在消费者项目中搜索插件文件。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership. Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` before resolving or writing design artifacts; it owns exclusive forms, manifests, hard limits, conversion, and historical-layout rejection.

When UI scope exists, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/ui-e2e-contract.md` before Figma mapping or evidence planning. It owns UI Delivery Level, staged lifecycle, real frontend E2E, coverage, bootstrap, blocking, final-review, and archive rules.
---

# FeaturePilot Figma

用于根据 Figma 链接生成或完善项目当前前端框架的 UI 实现。

**Figma 链接：** 用户在命令中提供的链接。

## 基本规则

- Figma 相关流程统一使用 `fp-figma`；禁止切换到全局 `figma-to-vue` 或其他同类 skill。
- 同时遵循 `fp-docs/settings/frontend.md`、`fp-docs/settings/prototype-style.md`（仅在没有可信 Figma UI 设计时用于功能范围）、`fp-docs/settings/agent.md` 中的通用策略、`fp-ui-spec`、`fp-ux-spec`。
- 优先使用项目 settings 或现有代码中确认的组件库；没有配置时使用中性组件映射，不假设任何客户专属前缀；确实无对应组件才允许自行封装，并写明原因。
- 遵循项目现有前端框架和脚本/状态管理写法；不得假设 Vue、React 或特定语法。
- 优先使用 Flex / Grid，避免滥用 `position: absolute`；Figma 里的绝对坐标只能作为测量参考，不能直接复制成脆弱布局。
- 只读取与当前任务相关的 Figma 页面、frame、component 和 variant；不要全量遍历无关设计稿。
- Figma 结果必须可被后续阶段延续：输出节点路径、区域拆解、项目组件映射、布局容器、token/尺寸和 Visual Checks，不只输出最终 UI 文件。
- 如需 local viewer / browser 预览，必须等页面可运行后 just-in-time 启动；只绑定 localhost，不服务无关目录，不读取 dotfile/symlink，不把预览截图当作 Figma 源事实。
- Figma 未呈现的既有功能默认保留；除非客户已明确批准，否则不得删除、隐藏或改变其语义。

## Design context and source evidence

- **Figma-only UI source:** 有可信 Figma UI 设计时，Figma UI 设计是唯一 UI/视觉/布局/尺寸/token/状态表现/交互呈现来源。当前真实代码、已有测试和真实浏览器行为仅用于既有功能保护基线；原型不得作为 UI 视觉、布局、呈现或还原判断的参考。prototype must not be a UI visual reference.
- 没有可信 Figma UI 设计时，prototype FUNCTION_SCOPE_ONLY：原型只可辅助确认功能与交互范围，不得作为像素级视觉来源；视觉还原只能是 `CANNOT_VERIFY`。
- 当 Figma MCP 可用时，before implementation 必须针对用户指定的 specified node 调用 `get_design_context`，并记录 Figma node、revision/time、frame/variant，以及可用的 variables、Auto Layout、assets 和组件信息；只读取当前范围。调用失败或信息不可得时如实标为 unavailable，do not fabricate。
- 当 Figma MCP 不可用时，只有用户或已批准产物中的 explicitly approved source（Figma 导出或其他静态设计源）才可继续；没有可信 source 是 blocker，不得从记忆、代码或本地 runtime screenshot 反推并冒充设计上下文。
- `reference.png` 只能来自 approved Figma/static design source；local runtime screenshot must not replace 它。`current.png` 只能来自 real target runtime 的实际 runtime route，使用 stable data 与 stable environment。`diff.png` 是 optional diff；missing diff 必须说明，且 must not hide 缺失 reference/current 的事实。
- Code Connect 只是 component mapping 的 optional enhancement，受能力与许可影响；must not auto-create `.figma.ts`，must not change tsconfig，must not install dependencies。Code Connect absence does not block ordinary UI。

## UI delivery and evidence mapping

For every UI-bearing Figma mapping case, record the approved design source/Figma node and the source-derived condition or branch it represents, then associate its stable task ID, case ID, UI Delivery Level, runtime route, Visual Evidence case, and E2E case. A Figma node or approved static design source establishes visual provenance only; it is never real frontend E2E evidence. The later UI/E2E Delivery Contract links the existing Visual Evidence Manifest by `Task ID + Case ID` and does not duplicate visual-manifest fields.

Derive `static-only`, `interactive`, or `business-flow` from the source-backed user-visible behavior rather than from implementation convenience. Preserve the shared contract's lifecycle and case rules: static-only maps to an evidence-backed E2E `N/A`, while interactive and business-flow map to required real browser E2E. A business-flow mapping identifies the real core API boundary, persistence/permission outcome, and cleanup expectation for the later plan; it must retain `Mocked Core API: false` in E2E evidence.

Visual and E2E evidence are distinct channels. Continue to record approved source, component mapping, and Visual Checks for the visual channel; carry the route and source-derived condition forward so the frontend plan can create the UI/E2E Delivery Contract and canonical per-case coverage matrix. Do not derive E2E success from Figma data, an export, a reference image, or a local runtime screenshot.
## Browser capability gate

状态名为 `BROWSER_CAPABILITY_GATE`。在需要真实运行时视觉或行为验证时，按以下顺序探测并复用可证明可用的能力：项目已有 browser runner、Playwright browser extension、本机已有 `playwright-cli`。不得因熟悉某个工具而替换客户现有 runner。

三者都不可用时，在写入任何环境前向客户报告已发现能力、缺失原因、Node.js 前提、可能的浏览器下载/网络/磁盘影响和项目文件影响，并让客户选择：

1. 安装 Playwright browser extension，不修改客户项目文件；
2. 本机全局安装 `@playwright/cli`：客户自行执行展示的精确命令，或在展示同一命令、影响与回滚边界后明确授权本次由 FeaturePilot 执行；
3. 暂不安装，只做 Figma 映射和静态代码审查。

必须 not install silently。客户的安装授权只覆盖本次展示的命令，不能延伸到其他工具、浏览器组件、项目依赖、lockfile、配置或 CI。客户选择暂不安装时，视觉结论为 `CANNOT_VERIFY`，不得称 Figma change complete 或视觉验收通过。

`BROWSER_CAPABILITY_GATE` 的 extension/CLI 选择只可支撑 Figma 映射、能力或保全复核。若 UI/E2E Delivery Level 是 `interactive` 或 `business-flow`，必须改按共享 UI/E2E 契约在目标前端项目内自动 bootstrap `@playwright/test` 和 Chromium；全局 `@playwright/cli` 不能替代 required real E2E，也不能产生跳过、降级或 mock 例外。

## Existing-function preservation and capability preflight

当任务在既有页面或组件上按 Figma 改造时，任何业务 UI 写入前必须完成以下 preflight。只有当前 active change 可安全确定时才写入其 `.fp-execute/`；无法确定 slug 时询问客户，不得把证据散落在仓库根目录，也不得创建项目级 `manifest.md`、settings 或 intel。

1. 加载 `figma-preservation-template.md`，创建 `.fp-execute/figma-preservation.md`。列出路由、组件、Figma 节点、受影响文件、允许视觉变更、所有保护行为、稳定 fixture、修改前基线、修改后重放和客户明确例外。每项保护行为使用稳定 `PRES-NNN` ID。
2. 加载 `figma-capabilities-template.md`，创建 `.fp-execute/figma-capabilities.md`。将每个用户可观察的原子能力用稳定 `FIGCAP-NNN` ID 关联到目标来源、Figma node/variant（有 Figma 时）、当前代码、唯一任务或文件、PRES case、浏览器操作证据和 Visual Case。
3. 在写入前完成能力预检：每个必需 `FIGCAP-*` 必须有唯一实现 owner；每个关键 Figma component/variant/empty/error/permission/confirmation state 必须有行为 owner；Figma 未展示的现有行为必须被映射为 `PRES-*` 或客户批准例外。任一缺失、不明状态或未批准删除风险均为 `BLOCKED`，不得猜测。
4. 先运行现有相关验证或记录真实浏览器修改前基线；如果无法建立可信基线，则对应核心 `PRES-*` 为 `CANNOT_VERIFY`，不得伪造通过证据。修改后必须以相同 fixture、route、用户状态、viewport、locale 和 theme 重放。

静态控件、handler、截图或已修改文件本身都不证明能力 `PASS`；必须有真实运行态的可观察验收结果。

## Direct implementation and independent review

直接 UI 实现使用下列状态机：

```text
RESOLVING -> DESIGN_SOURCE_GATE -> BROWSER_CAPABILITY_GATE -> PRESERVATION_BASELINE -> CAPABILITY_PREFLIGHT -> IMPLEMENTING -> INDEPENDENT_REVIEW -> COMPLETE | INCOMPLETE | BLOCKED
```

实现者只按已确认 Figma mapping 写入业务 UI 并收集 case evidence，不得批准自己的结果。实现后必须由 fresh independent read-only review 加载 `figma-review-template.md`，读取 Figma source、`figma-preservation.md`、`figma-capabilities.md`、Visual Cases 与实际 diff，并写入 `.fp-execute/reviews/<timestamp>-figma-review.md`。

审查分别报告 Code editing、Capability completion、Preservation、Figma visual fidelity 与 Overall。任一必需 `FIGCAP-*`、核心 `PRES-*` 或核心 Visual Case 非 `PASS` 时，总体只能为 `INCOMPLETE` 或 `BLOCKED`；不能把代码编辑、静态 UI 或截图单独称为 Figma change complete。Only all required FIGCAP-* = PASS, core PRES-* = PASS, and core Visual Cases = PASS, with no unapproved behavior change, permits Figma change complete。

## Canonical design layout

处于 `fp-brainstorm` 阶段时，frontend design 使用 mutually exclusive form：small form 仅有 `design/frontend.md`；split form 仅有 `design/frontend/00-index.md` 与 manifest 列出的 `design/frontend/<number>-<area>.md`。`design/00-index.md` 必须直接链接已选择的 frontend entry，不经另一份摘要文件跳转。

Figma writes the chosen frontend file OR the frontend directory fragments and index, never both representations.

写入前沿用 `fp-brainstorm` 已确认的 form；若尚未选择，默认选择 small form。只有预计 small form 超过 500 行或 30,000 字符、用户明确批准 split form，或目标项目设置明确要求 split form 时才拆分；多个 feature、subsystem、page area 或 ownership domain 仅用于已选 split form 的分片边界，不单独触发拆分。任何 index 或 fragment 不得超过 **500 lines** 或 **30,000 characters**，越过任一 hard fallback limit 都必须继续按语义拆分，不得先写 monolith 再机械切割。

### No orphan fragment writes

不得单独写入分片。

- Split form 写入或更新 `design/frontend/<number>-<area>.md` 时，必须在同一次操作中确保 `design/frontend/00-index.md` 的 `| Order | File | Kind | Owns |` manifest 将每个 sibling Markdown fragment 列出恰好一次，并让 `design/00-index.md` 直接链接 `design/frontend/00-index.md`；split writes preserve both required indexes。
- Split form 不得创建或保留 `design/frontend.md`。
- Small form 只更新 `design/frontend.md`，让 change index 直接链接它，并且不创建 frontend directory。
- 若当前 `fp-brainstorm` 尚未通过包含 exact paths、所选 form 和转换移除项的写入前内容确认，不得提前创建、覆盖或移除任何设计产物。

创建或更新前只检查当前 slug 的 `design/frontend.md`、`design/frontend/00-index.md`、旧根目录 `design-frontend.md` 和 historical dual structure。已有单一 canonical form 时保持该 form；任何 historical path 或 dual form 都是 structural conflict，禁止读取正文或继续写入。迁移需要 explicit approval、转移全部 unique content、验证并移除 obsolete path；不得扫描历史 change/archive。

There is no read-only compatibility for historical files or pairs; Figma blocks until one canonical form has been validated.

## 执行步骤

1. 按上述 Figma MCP/source gate 获取并记录 design context；读取 Figma 结构与关键样式，仅关注 content 区域和用户指定节点，记录页面名、frame 名、node id、revision/time、关键尺寸、颜色、字号、间距、状态和可复用组件。
2. 分析页面结构、组件映射和布局方式，生成 `UI 组件树与 Figma 解析映射`：每个设计区域对应目标 DOM 层级、项目组件、slot、Flex/Grid 容器、关键 token、需要自封装的原因。
3. 生成 `Visual Checks`：每项必须能在 local viewer / browser 里检查，且能追溯到具体 Figma 节点或 UI/UX 规范；避免“看起来一致”这种不可执行描述。`Visual Source`、组件映射和 `Visual Checks` 必须共同写入一个 detailed owner，且各出现恰好一次；split index 只记录 ownership metadata，不复制正文。
4. 若当前处于 `fp-brainstorm` 设计阶段，只把步骤 1-3 的结果写入 small form 的 `design/frontend.md`，或 split form 中一个由 `design/frontend/00-index.md` manifest 列出的 detail fragment，不得直接写业务 UI 文件。写后验证互斥 form、direct change-index link、manifest completeness、唯一 visual owner 和两项 hard limits。
5. 若用户直接执行 Figma 还原或后续计划已确认实现目标，再按项目已确认的框架、组件文件类型、脚本/状态管理和样式约定生成目标文件；无法从 settings 或现有代码确认时，先向用户提问，不要猜测框架。
6. 写入目标文件并执行 Lint 修复。
7. 如有需要，等页面可运行后再按 `Visual Checks` 启动本地预览/浏览器截图做 just-in-time 微调；不得提前启动 local viewer，也不得把截图当作 Figma 源事实替代。
