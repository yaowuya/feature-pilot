# README 公众号式重构设计

**日期：** 2026-09-06
**状态：** 已确认，等待书面设计复核
**范围：** README 与面向开发者的 docs 信息架构；不改变 FeaturePilot 运行时行为、命令语义或 canonical artifact contract

## 1. 背景

当前 `README.md` 同时承担项目首页、版本说明、命令手册、技能清单、架构文档、安装手册、产物规范和专项契约说明，全文约 327 行。信息完整，但首屏价值不突出，同一能力在“发布重点、核心命令、核心技能、低成本流程、版本范围”中重复出现；coverage、CodeGraph、UI/E2E、small/split 等专业规则也压过了首次使用路径。

本次重构面向开发者用户，以“故事化但克制”的公众号阅读节奏优化首页，同时把专业内容下沉到职责明确的 docs。`skills/` 与 `skills/_shared/` 继续是 Agent 运行时规范 owner；docs 只是面向人的解释层。

## 2. 目标与非目标

### 2.1 目标

1. 开发者在三分钟内理解 FeaturePilot 解决什么问题、如何开始、该选择哪个入口。
2. README 形成清晰节奏：开发痛点 → 核心价值 → 工作方式 → 快速开始 → 场景入口 → 产物价值 → 文档导航。
3. 安装、命令与技能、架构与产物分别进入独立专业文档。
4. 每类专业信息只有一个面向人的主要解释位置，README 使用精确链接，不复制正文。
5. 保留 Claude Code、Codex、DeepSeek Harness、全部公开命令、专项指南和 `1.0.0` release notes 的可发现性。
6. 更新文档契约测试，使其检查新的信息层级，而不是强迫 README 保留技术手册正文。

### 2.2 非目标

- 不修改 `commands/`、`skills/`、shared contracts 或插件 manifest 的行为。
- 不更改任何命令名、skill 名、触发条件、状态机、证据 schema、目录 contract 或安装机制。
- 不重写现有 `docs/user_guide/`、`docs/release_notes/`、历史 specs/plans。
- 不把 README 改成夸张营销页，不加入无法验证的数据或承诺。

## 3. README 设计

README 目标长度为 120–150 行，采用以下固定叙事顺序。

### 3.1 首屏

标题建议：

> FeaturePilot：把一句需求，稳稳带到可交付代码

副标题用一段话说明：FeaturePilot 不是另一个代码生成器，而是把需求、设计、计划、执行、审查和归档串成可恢复、可验证的 AI 开发流程。

首屏保留：

- 当前版本 `1.0.0`；
- Claude Code、Codex、DeepSeek Harness 三运行时；
- release notes 链接；
- 快速开始入口。

### 3.2 痛点开场

用三个真实开发现场短句建立共鸣：

- AI 写得很快，但需求和边界留在聊天里；
- 会话一换，关键决策和实现上下文需要重讲；
- 测试通过后，仍缺少“是否真的完成”的可追溯证据。

随后说明 FeaturePilot 的价值不是让模型“更激进地写”，而是让开发过程可追溯、可恢复、可审查。

### 3.3 工作方式

用一条轻量链路表达：

`想清楚 → 设计清楚 → 拆成任务 → 验证着做 → 留下证据`

首页不展开状态机、schema、small/split 表或 hard gate；这些链接到架构与产物参考。

### 3.4 三分钟开始

1. 选择运行时并跳转安装指南。
2. 使用 `/fp-init` 建立最小工作区。
3. 根据任务选择：
   - 小而明确：`/fp-quick`
   - 需要需求澄清：`/fp-prd`
   - 已有 PRD 或需要完整链路：`/fp-start`
4. 给出一个简短、可复制的示例，不展开内部实现细节。

### 3.5 场景入口

用面向问题的短表代替重复的 command/skill 清单：

- 看懂项目或比较方案 → `fp-explore`
- 零基础图解 → `fp-eli5`
- 小改动 → `fp-quick`
- PRD 与完整开发 → `fp-prd` / `fp-start`
- Figma、设计评审、数据库适配 → 对应专项入口
- 覆盖率、模块审查、最终审查与归档 → 对应质量入口

完整职责跳转 `docs/reference/commands-and-skills.md`。

### 3.6 留下什么

首页只保留精简产物示意：

```text
fp-docs/
├── manifest.md
├── changes/<slug>/
│   ├── prd / proposal / design / tasks
│   └── .fp-execute/
└── archive/ + history/
```

解释三个价值：需求可追溯、任务可恢复、审查有证据。完整目录和 canonical 规则跳转架构参考。

### 3.7 文档导航

必须包含：

- `docs/getting-started.md`
- `docs/reference/commands-and-skills.md`
- `docs/reference/architecture-and-artifacts.md`
- `docs/user_guide/init-prd-start.md`
- `docs/user_guide/fp-coverage.md`
- `docs/user_guide/fp-module-review.md`
- `docs/release_notes/1.0.0.md`

## 4. 专业文档设计

### 4.1 `docs/getting-started.md`

职责：安装、加载、更新和验证。

内容：

- 三运行时能力概览；
- Claude Code 本地 marketplace 安装与重启；
- Codex personal marketplace/source/cache 与 new task；
- DeepSeek Harness 技能根、Chokidar 与新会话；
- `sync-plugin-runtimes` 正常模式与 `-VerifyOnly`；
- `validate-plugin.ps1`；
- 常见缓存未刷新问题。

该文档不解释 workflow、artifact schema 或质量状态机。

### 4.2 `docs/reference/commands-and-skills.md`

职责：从用户意图映射到公开入口，并解释 command 与 skill 的关系。

内容：

- 全部 `commands/fp-*.md` 的用途；
- 公开命令与内部 skill 的映射；
- `fp-quick`、完整流程、direct、显式 SDD 的选择边界；
- `fp-design-review`、`fp-db-adapter`、`fp-figma`；
- coverage、module review、final review、archive；
- 指向专项用户指南。

该文档不复制每个 skill 的完整运行时契约。

### 4.3 `docs/reference/architecture-and-artifacts.md`

职责：解释系统结构和专业契约。

内容：

- 三运行时与共享 skills 架构图；
- command adapter、skill、shared contract 的职责；
- `fp-docs/manifest.md`、settings、intel；
- change、execution evidence、archive/history；
- canonical small/split 形式、互斥、500 行/30,000 字符 hard limits；
- CodeGraph 可选导航与写后 freshness；
- UI/E2E、Figma、final-review 证据边界；
- OpenSpec 借鉴点和过程文档语言规则。

该文档是面向人的解释，不替代 `skills/_shared/*.md` 的运行时权威。

## 5. 信息迁移映射

| README 现有内容 | 新位置 |
|---|---|
| 版本重点 | 首页摘要 + release notes 链接 |
| Staged UI/E2E delivery | architecture-and-artifacts |
| 插件结构与架构图 | architecture-and-artifacts |
| 核心命令与核心技能 | commands-and-skills |
| CodeGraph 安装与生命周期 | getting-started + architecture-and-artifacts |
| OpenSpec 设计、项目配置、输出目录 | architecture-and-artifacts |
| 低成本使用流程 | 首页三分钟开始 + init-prd-start 指针 |
| coverage 目录和 bootstrap 细节 | fp-coverage 用户指南；commands 参考只保留摘要 |
| Claude/Codex/DSH 安装与更新 | getting-started |
| 1.0.0 完整范围 | release notes |

## 6. 测试与验证

新增聚焦 README/docs 契约测试，验证：

1. README 受控在目标长度附近，包含三运行时、三分钟开始、场景入口和 release notes。
2. README 链接三份新专业文档及现有专项指南。
3. README 不再包含完整 coverage 目录、small/split 全表、CodeGraph 安装细节和 UI/E2E 长契约。
4. 三份新文档存在，职责标题和关键入口完整。
5. commands 参考覆盖当前全部公开 `commands/fp-*.md`。
6. architecture 参考覆盖所有 shared contract 入口及关键专业主题。
7. getting-started 覆盖三运行时、同步和只读验证。
8. README 与新 docs 中的本地 Markdown 链接可以解析。

现有测试迁移原则：

- coverage、CodeGraph、ELI5、UI/E2E、module review 的详细断言改为检查对应专业 docs 或现有专项指南；
- README 只保留发现入口、价值摘要和链接断言；
- Agent runtime contract 测试继续直接检查 `skills/`，不改行为预期。

最终运行：

- `scripts/validate-plugin.ps1`
- 所有 `scripts/test-*.ps1`
- `git diff --check`
- Markdown 本地链接检查

## 7. 完成标准

- README 为故事化但克制的开发者首页，约 120–150 行。
- 开发者可从首页完成“理解价值 → 选择入口 → 开始使用”。
- 三份专业文档职责互斥、链接完整。
- 所有公开命令和三运行时仍可发现。
- 没有改变 command、skill、runtime、artifact 或质量门禁行为。
- 插件 validator、全部契约测试和链接检查通过。
- 变更仅涉及 README、docs 与相关文档契约测试。
