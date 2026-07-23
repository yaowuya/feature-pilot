---
name: fp-propose
description: 为新功能变更生成并确认 proposal.md 提案文档
---
## FeaturePilot workspace and information layer

If any anchored plugin resource is missing or unreadable, stop, report the exact resource and an incomplete FeaturePilot installation/cache, and never search the consumer repository for `skills/**` or continue without it.
下文以 `${CLAUDE_PLUGIN_ROOT}/...` 表示 Claude Code 安装后的插件资源。在 Codex/Markdown 中，从 available-skill 元数据提供的当前技能入口映射同一个 `skills/...` 插件相对路径。两端都不得在消费者项目中搜索插件文件。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` before resolving PRD input or creating/revising the proposal. It owns canonical form selection, fragment manifest rules, size limits, conflict handling, and Producer/Consumer resolution.

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/decision-ledger.md` before requirement clarification. It owns the Decision Ledger status set, per-item confirmation, separate write authorization, persisted terminal evidence, and recovery behavior.
---

# FeaturePilot Propose

你正在帮助工程师为功能「{{description}}」生成变更提案文档。

---

## PRD handoff input

If `fp-start` or the user provides a PRD slug, resolve `fp-docs/changes/<slug>/prd.md` or the mutually exclusive `fp-docs/changes/<slug>/prd/00-index.md` before asking requirement questions. For split form, parse the fragment manifest and read every listed fragment in exact order; reject a missing index, unindexed/missing fragment, duplicate owner, or simultaneous `prd.md` plus `prd/`. Use the confirmed logical PRD as the primary requirement source and generate a concise logical proposal. Put each exact inherited decision in the Decision Ledger as `PRD-confirmed` and do not repeat that interview. Ask only about gaps that block proposal scope, impact, or delivery strategy, and record each such gap before recommending a choice.

### Upstream start-routing context

When `fp-start` supplies `start-reusable-context`, reuse only its verified facts whose inspected scope still covers the proposal question and whose relevant files/worktree state have not changed. Preserve evidence paths, budget state, and uninspected areas. Treat inferences as inferences, never as reusable facts or user confirmation.

Perform gap-only exploration: inspect areas that were not covered, facts invalidated by relevant worktree changes, or evidence insufficient for proposal scope, impact, or delivery strategy. Direct `fp-propose` use without upstream context keeps the normal exploration phase.

## Proposal forms

One logical proposal selects exactly one form before writing:

- small: `fp-docs/changes/<slug>/proposal.md`;
- split: `fp-docs/changes/<slug>/proposal/00-index.md` plus indexed fragments.

`proposal.md` and `proposal/00-index.md` are mutually exclusive. For form selection, default to the small form when the complete logical artifact is expected to stay within 500 lines and 30,000 characters. Use split form only when the small form is expected to exceed either hard limit, the user explicitly approves split form, or an applicable target-project setting explicitly requires it. Multiple features, page areas, subsystems, change scopes, or ownership domains guide fragment boundaries after splitting; they do not trigger split form by themselves. The split index owns only navigation and the authoritative `| Order | File | Kind | Owns |` fragment manifest. Logical concatenation in manifest order must pass logical template validation against the exact Why / What Changes / Capabilities / Out of Scope / Impact order.

---

## 阶段 1：探索项目现状

必须以代码为最终事实来源。没有可复用的 `start-reusable-context` 时执行完整的本阶段探索；存在可复用上下文时，只执行上文定义的 gap-only 补查：
- 读取 `CLAUDE.md`（项目根目录或 `.claude/`）：了解架构、技术栈、代码规范
- 读取 `fp-docs/settings/` 中与当前阶段相关的客户配置；不要读取历史 `fp-docs/changes/` 或 `fp-docs/archive/` 作为功能背景；当前代码仍是最终实现事实来源
- 使用 `rg` / `rg --files` 搜索需求关键词、接口、模型、组件、路由、测试和相邻实现
- 根据功能描述，初步判断涉及哪些子系统/模块
- 如果文档和代码冲突，以当前代码为准

---

## 阶段 2：需求澄清（Socratic 问答）

**Decision Ledger 先于摘要：**
- 先为每个 proposal-required 的活动决策创建 `P-NNN` decision ID，记录 Decision、Source、Blocking、Status 和 Evidence / explicit confirmation。已确认 PRD 是 `PRD-confirmed`，当前代码能证明的既有约束才可标为 `code-verified`，用户明确选择为 `user-confirmed`，不适用项为 `not-applicable`。
- 对 every unresolved decision：凡会改变 proposal 的范围、影响、交付策略、form、目标路径或 conversion/removal 的项，都必须标为 `needs-user-confirmation`；不得省略、凭推荐补全或把推断升级为已确认。
- agent recommendation 是选项，不是确认；它 is not user confirmation。每次只问一个 `P-NNN`，给出 2-3 个选项和推荐理由，等待用户明确回答后更新该行。
- generic confirmation does not resolve `needs-user-confirmation`。用户可以一条消息确认多项，但必须逐一给出 decision ID 和选择。

**判断需求是否足够进入确认摘要：**
- 如果输入来自已确认的 `fp-docs/changes/<slug>/prd.md` 或 `fp-docs/changes/<slug>/prd/00-index.md`，可以把解析后的 logical PRD 作为已确认需求来源，只询问台账中 proposal 阶段的阻塞缺口。
- 如果用户明确提供了具体目标、范围边界、约束和优先级，可以跳过无关的多轮问答；仍必须建立台账、逐项解决 `needs-user-confirmation` 行，并展示确认摘要。
- 如果描述模糊（如 "加个文件管理"、"优化审批流程"）或存在会改变范围/影响/交付策略的缺口，进入问答。

**确认摘要硬门禁：**
- 写任一 proposal form 前必须展示 Why / What Changes / Out of Scope / Impact 的摘要，以及完整的 proposal Decision Ledger。
- 展示摘要前生成 slug，检查 `proposal.md`、`proposal/` 和 `proposal/00-index.md`，选择 small 或 split form。摘要必须列出 canonical entrypoint、split fragment ownership（如适用）以及任何 overwrite、revision、conversion/removal 动作；这些动作也是需确认的 `P-NNN` 行。
- `needs-user-confirmation blocks writing`：任一 proposal-required 行未终态、缺少来源/确认凭据，或只有 agent recommendation 时，不得创建目录、读取模板、写入、覆盖或删除。
- 台账终态后，仍必须等待用户对摘要和本次写入的明确授权（如“确认并按 P-001、P-002 写入”）。这是 separate write authorization，不能由泛化“确认/继续”替代未决行的逐项确认。

---

## 阶段 3：生成 proposal

1. 使用确认摘要中已批准的 kebab-case slug 和 proposal form（中文转英文语义缩写，例如 "新增文件库功能" → `file-library`）。
2. 【立即用工具执行】确认目标项目根目录，并把输出限定在项目根目录下的 `fp-docs/changes/<slug>/proposal.md` 或 `fp-docs/changes/<slug>/proposal/00-index.md`。
3. 如果项目根目录没有 `fp-docs/manifest.md`，只提示建议运行 `/fp-init`；不要强制初始化，也不要创建 manifest/settings/intel。
4. 【立即用工具执行】仅在所有 proposal-required 台账行终态且获得 separate write authorization 后，创建已批准 form 所需的目录。
5. 【立即用工具执行】读取 `${CLAUDE_PLUGIN_ROOT}/skills/fp-propose/proposal-template.md`，填写完整后直接写入批准的最终结构；不要先生成 monolith 再机械拆分。把终态 Decision Ledger 和 Pre-write Confirmation Evidence 写入 `Impact` 的 unique detailed owner；不得持久化 `needs-user-confirmation` 行。

Split form requirements:

- `proposal/00-index.md` contains navigation and fragment manifest metadata only; every sibling Markdown fragment is listed exactly once.
- Keep each complete What Changes change point in one owner fragment. Why, Capabilities, Out of Scope, and Impact each have exactly one owner. `Impact` 的 unique detailed owner 同时拥有 Handoff Decision Ledger 与 Pre-write Confirmation Evidence；index 只记录该 ownership，不复制台账正文。
- Every Markdown file, including the index, is at most 500 lines and 30,000 characters.
- Read fragments in manifest order and run logical template validation before reporting the proposal.

Existing artifact handling:

- `proposal.md` plus `proposal/` is always a structural conflict; stop and request explicit migration approval rather than guessing.
- `proposal/` without `proposal/00-index.md` is incomplete and blocks writing.
- Preserve an existing canonical form unless confirmed scope requires conversion. State the conversion in the pre-write summary, transfer all unique content, validate the new form, and remove the obsolete path.
- For an existing canonical artifact, ask whether to revise, overwrite/replace, or cancel. Do not append outside the logical template.
- For an existing canonical artifact, resolve `Impact`'s Handoff Decision Ledger and Pre-write Confirmation Evidence before treating it as confirmed. If either is missing or unresolved, it is recovery state rather than proof of a completed gate: request a recovery confirmation, rebuild only the affected `P-NNN` rows, obtain their per-item confirmation and a new separate write authorization, or let the user cancel. Do not infer historical confirmation from file existence.

只生成本阶段的一种 proposal form。不要预创建 `design.md`、`tasks.md`、`tasks/`；这些文件/目录只能由后续对应阶段在真正需要时创建。

Do not load `${CLAUDE_PLUGIN_ROOT}/skills/fp-propose/proposal-template.md` during exploration or questioning. Load it only after the pre-write confirmation gate, so early turns carry decisions rather than output boilerplate.

---

## 阶段 4：提案审查

写入后，必须展示 canonical entrypoint、Why / What Changes / Out of Scope / Impact 摘要，以及终态 Decision Ledger 的 ID 覆盖集，要求工程师 review 完整 logical proposal。Split form 必须按 fragment manifest 顺序读取全部 fragments 后再展示摘要。

这属于第二个确认门禁：写文件前的确认只授权创建/写入选定 proposal form；写入后仍必须等待用户明确确认该提案产物无误，才能输出 `✅ 提案已确认，进入设计阶段` 或进入设计。Handoff consumer 必须从 `proposal.md` 或 `proposal/00-index.md` 解析唯一 canonical form，并在 split form 下按 manifest 顺序读取。
