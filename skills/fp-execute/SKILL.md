---
name: fp-execute
description: Use when an approved FeaturePilot task plan should be implemented directly in the current context without SDD orchestration.
---

## FeaturePilot workspace and information layer

If any anchored plugin resource is missing or unreadable, stop, report the exact resource and an incomplete FeaturePilot installation/cache, and never search the consumer repository for `skills/**` or continue without it.
下文以 `${CLAUDE_PLUGIN_ROOT}/...` 表示 Claude Code 安装后的插件资源。在 Codex/Markdown 中，从 available-skill 元数据提供的当前技能入口映射同一个 `skills/...` 插件相对路径。两端都不得在消费者项目中搜索插件文件。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.
Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` once before resolving execution inputs; it owns canonical small/split paths, manifests, task ownership, historical-layout rejection, and Consumer validation.
If `<project-root>/.codegraph/` exists, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/codegraph.md` once and preserve its write-invalidation contract.

---

# FeaturePilot Execute

直接执行已确认的 `{{tasksPath}}` 任务清单。

**自动化模式：`{{automationMode}}`**
**任务状态：{{tasksSummary}}**

## 直接执行契约

- 在当前执行上下文直接完成任务，不派发 fresh implementer、独立 task reviewer 或 fixer。
- 过程产物集合仅包含 `.fp-execute/progress.md`、task-owner file 中的唯一 checkbox，以及双端计划已有 `tasks/00-overview.md` 的派生进度。
- 每个任务执行 TDD、必要验证和一次 inline 自审；发现问题就在当前任务内修复并重新验证，不建立独立 review/fix 状态机。
- `fp-execute` 不拥有 final review scope。全部任务完成后输出执行报告，只提示运行独立的 `fp-review`。
- 只有用户明确要求 `fp-execute-sdd` 时才切换到 SDD；不要根据任务数量、模块跨度或风险自行切换。

## 执行模式

### 半自动模式（semi）

1. 展示解析后的待完成任务及其 owner path。
2. 读取或初始化 `.fp-execute/progress.md`，核对 checkbox、提交和验证证据。
3. 询问用户从哪个任务开始。
4. 按下方 TDD 流程完成一个任务。
5. 更新唯一 owner checkbox、ledger 和必要的 overview 派生进度。
6. 汇报结果并等待用户确认是否继续下一任务。

### 全自动模式（full，默认）

1. 按依赖顺序获取全部未完成任务。
2. 读取或初始化 `.fp-execute/progress.md` 并完成状态对账。
3. 在当前上下文逐个执行任务，不在正常任务边界停下。
4. 目标测试或验证失败时最多修复并重试 3 次；仍失败则记录 `BLOCKED`，暂停并说明需要的人工决策。
5. 全部任务完成后输出执行报告，提示运行独立的 `fp-review`；不要在本 skill 内执行最终审查。

## Canonical 输入解析

1. 作为 canonical-first Consumer 而不是 Producer，先检测每个 small/split 候选，再读取唯一 canonical form：`prd.md` 或 `prd/00-index.md`；`proposal.md` 或 `proposal/00-index.md`；`design/backend.md` 或 `design/backend/00-index.md`；`design/frontend.md` 或 `design/frontend/00-index.md`。
2. Detect both alternatives before reading either: `tasks/backend/00-index.md` or `tasks/plan-backend.md`; `tasks/frontend/00-index.md` or `tasks/plan-frontend.md`. Split form 按 manifest order 读取全部 fragments；missing、duplicate 或 unindexed fragment 都是 structural conflict。
3. 只有 `tasks`-kind fragment 可以拥有 checkbox；每个 task ID 使用一个 unique task owner。验证端内与跨端依赖存在且无环。
4. `tasks/00-overview.md` exists exactly when both backend and frontend plans exist；A single-end plan never has an overview。双端 overview 的进度是从 owner checkboxes 计算的 derived progress summary。
5. Root-level `design-backend.md` / `design-frontend.md`、indexless split、historical path 或 small/split dual form 都必须在执行前阻塞；`fp-execute` 不迁移需求、设计或计划产物。

## 执行状态

在 `fp-docs/changes/<slug>/.fp-execute/progress.md` 维护简单的恢复证据。如果任务文件不在标准 change 目录，则在任务文件同级创建 `.fp-execute/progress.md`。

```markdown
# Execution Progress

Plan files:
- <canonical task entrypoints and ordered owner files>

Base SHA: <执行开始时的 git sha>

## Completed
- <task-id> (owner: <path>): commits <base>..<head>; tests `<command>`; inline review clean

## Blocked
- None

## Notes
- <残余风险或人工跟进项>
```

规则：

- 启动时先读取 ledger；不存在则创建。
- Task-owner checkbox 是计划完成状态；ledger is recovery evidence, not a second completion authority。
- Ledger 与 checkbox 不一致时检查 owner file、`git log`、实际实现和验证结果，再修正状态；不要盲目重做。
- 每个任务完成时一起更新 checkbox、ledger、验证命令和 commit 范围；双端计划再从 owner checkboxes 重算 overview。
- 阻塞时记录原因、已尝试命令和需要的人工决策。

## Pre-flight Plan Review

执行业务代码前一次性检查：

1. 任务范围与已确认 proposal/design 一致，Out of Scope 未进入计划。
2. `Global Constraints`、项目设置和当前代码约束没有冲突。
3. `Interfaces`、API 字段、权限、route、store、props/events 和跨任务依赖一致。
4. 每个任务有可执行的测试或替代验证步骤，没有 `TBD`、`TODO`、`按需处理` 等占位内容。
5. 前端任务包含需要的 template/script/style/visual 骨架，并符合项目当前框架与组件惯例。
6. 计划冲突一次性汇总并暂停；扫描通过后直接开始执行。

## TDD 执行流程（每个任务）

1. 从唯一 task-owner file 读取任务、Files、Reasoning、Depends on、Interfaces 和验收标准。
2. 核对 checkbox、ledger、git 和实际文件，确认任务尚未完成。
3. 先写失败测试并运行，确认因缺少目标行为而失败；不适合自动测试时记录原因和替代验证。
4. 编写让测试通过的最小实现，不顺手重构无关范围。
5. 运行目标测试，并按任务要求运行相关 lint、typecheck、build 或视觉验证。
6. 做一次 inline 自审，检查正确性、命名、结构、契约、安全和前端视觉约束；发现问题立即修复并重跑受影响验证。
7. 验证通过后更新唯一 owner checkbox；双端计划同步派生进度。
8. 按任务提交代码，提交信息与交付行为一致。
9. 在 ledger 记录 commit 范围、验证命令、结果和残余风险。

## CodeGraph 写后刷新

首次创建、修改、移动或删除源码、测试、配置、schema 或生成器输入时，立即把本工作流代码图状态标记为 `dirty-after-write`。此后 `never query a dirty graph`：本轮剩余定位全部使用当前源码的 `Glob/Grep/ranged Read`，不得继续使用写入前的 CodeGraph 结果。

如果写入开始前项目已有 `.codegraph/`，在半自动任务汇报、全自动最终汇报或任何写入后的阻塞返回之前执行一次 `post-write-sync`：

```text
codegraph sync <project-root> --quiet
```

每次用户可见返回前最多执行一次，不再运行 `status`，不把 `.codegraph/` 混入任务提交。成功时记录已刷新；失败时记录一次降级原因并继续当前验证、checkbox/ledger 更新和汇报，`must not block completion`。项目原本没有图时不得隐式执行 `init`。

## 完成汇报

半自动模式每个任务汇报：任务、文件、验证、commit、ledger 和未解决风险。

全自动模式全部完成后汇报：

- 已完成及未执行任务。
- 关键修改文件。
- 所有验证命令与结果。
- progress ledger 路径和残余风险。
- CodeGraph `post-write-sync` 的执行、跳过或失败状态。
- 下一步：运行独立的 `fp-review`；通过后再执行 `/fp-archive`。
