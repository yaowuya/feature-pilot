---
name: fp-propose
description: 为新功能变更生成并确认 proposal.md 提案文档
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.

Read `../_shared/artifact-layout.md` before resolving PRD input or creating/revising the proposal. It owns canonical form selection, fragment manifest rules, size limits, conflict handling, and Producer/Consumer resolution.
---

# FeaturePilot Propose

你正在帮助工程师为功能「{{description}}」生成变更提案文档。

---

## PRD handoff input

If `fp-start` or the user provides a PRD slug, resolve `fp-docs/changes/<slug>/prd.md` or the mutually exclusive `fp-docs/changes/<slug>/prd/00-index.md` before asking requirement questions. For split form, parse the fragment manifest and read every listed fragment in exact order; reject a missing index, unindexed/missing fragment, duplicate owner, or simultaneous `prd.md` plus `prd/`. Use the confirmed logical PRD as the primary requirement source and generate a concise logical proposal. Ask only about gaps that block proposal scope, impact, or delivery strategy.

### Upstream start-routing context

When `fp-start` supplies `start-reusable-context`, reuse only its verified facts whose inspected scope still covers the proposal question and whose relevant files/worktree state have not changed. Preserve evidence paths, budget state, and uninspected areas. Treat inferences as inferences, never as reusable facts or user confirmation.

Perform gap-only exploration: inspect areas that were not covered, facts invalidated by relevant worktree changes, or evidence insufficient for proposal scope, impact, or delivery strategy. Direct `fp-propose` use without upstream context keeps the normal exploration phase.

## Proposal forms

One logical proposal selects exactly one form before writing:

- small: `fp-docs/changes/<slug>/proposal.md`;
- split: `fp-docs/changes/<slug>/proposal/00-index.md` plus indexed fragments.

`proposal.md` and `proposal/00-index.md` are mutually exclusive. Use split form when confirmed content has multiple independently readable change scopes, subsystems, or ownership domains, or when any Markdown file would exceed 500 lines or 30,000 characters. The split index owns only navigation and the authoritative `| Order | File | Kind | Owns |` fragment manifest. Logical concatenation in manifest order must pass logical template validation against the exact Why / What Changes / Capabilities / Out of Scope / Impact order.

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

**判断需求是否足够进入确认摘要：**
- 如果输入来自已确认的 `fp-docs/changes/<slug>/prd.md` 或 `fp-docs/changes/<slug>/prd/00-index.md`，可以把解析后的 logical PRD 作为已确认需求来源，只询问 proposal 范围、影响或交付策略的阻塞缺口。
- 如果用户明确提供了具体目标、范围边界、约束和优先级，可以跳过多轮问答，但必须先展示 proposal 确认摘要并等待用户批准，不能直接写文件。
- 如果描述模糊（如 "加个文件管理"、"优化审批流程"）或存在会改变范围/影响/交付策略的缺口，进入问答。

**问答规则：**
- 每次只问一个问题，给出 2-3 个选项 + "其他（请描述）"
- 结合项目现有架构和最佳实践，在选项中体现推荐做法
- 问题聚焦在影响提案范围的关键决策，不问可以设计阶段再决定的细节
- 问题维度（按重要性排序，不必全部问）：
  1. **核心目的**：解决什么痛点？谁在用？频率如何？
  2. **范围边界**：哪些子功能必须有，哪些明确不做？
  3. **关键约束**：与现有模块的集成方式？是否有性能/安全要求？
  4. **交付优先级**：是否分阶段交付？MVP 是什么？

收集足够信息后（通常 1-4 轮），停止问答，展示确认摘要。

**确认摘要硬门禁：**
- 写任一 proposal form 前必须展示 Why / What Changes / Out of Scope / Impact 的摘要。
- 展示摘要前生成 slug，检查 `proposal.md`、`proposal/` 和 `proposal/00-index.md`，选择 small 或 split form。摘要必须列出 canonical entrypoint、split fragment ownership（如适用）以及任何 overwrite、revision、conversion/removal 动作。
- 必须等待用户明确确认（如“确认”“继续”“按这个生成”）。
- 助手的推荐或代码探索结论不是用户确认。
- 未获确认前，不得创建 `fp-docs/changes/<slug>/` 或写任一 proposal form。

---

## 阶段 3：生成 proposal

1. 使用确认摘要中已批准的 kebab-case slug 和 proposal form（中文转英文语义缩写，例如 "新增文件库功能" → `file-library`）。
2. 【立即用工具执行】确认目标项目根目录，并把输出限定在项目根目录下的 `fp-docs/changes/<slug>/proposal.md` 或 `fp-docs/changes/<slug>/proposal/00-index.md`。
3. 如果项目根目录没有 `fp-docs/manifest.md`，只提示建议运行 `/fp-init`；不要强制初始化，也不要创建 manifest/settings/intel。
4. 【立即用工具执行】在用户确认摘要后，只创建已批准 form 所需的目录。
5. 【立即用工具执行】读取 `proposal-template.md`，填写完整后直接写入批准的最终结构；不要先生成 monolith 再机械拆分。

Split form requirements:

- `proposal/00-index.md` contains navigation and fragment manifest metadata only; every sibling Markdown fragment is listed exactly once.
- Keep each complete What Changes change point in one owner fragment. Why, Capabilities, Out of Scope, and Impact each have exactly one owner.
- Every Markdown file, including the index, is at most 500 lines and 30,000 characters.
- Read fragments in manifest order and run logical template validation before reporting the proposal.

Existing artifact handling:

- `proposal.md` plus `proposal/` is always a structural conflict; stop and request explicit migration approval rather than guessing.
- `proposal/` without `proposal/00-index.md` is incomplete and blocks writing.
- Preserve an existing canonical form unless confirmed scope requires conversion. State the conversion in the pre-write summary, transfer all unique content, validate the new form, and remove the obsolete path.
- For an existing canonical artifact, ask whether to revise, overwrite/replace, or cancel. Do not append outside the logical template.

只生成本阶段的一种 proposal form。不要预创建 `design.md`、`tasks.md`、`tasks/`；这些文件/目录只能由后续对应阶段在真正需要时创建。

Do not load `proposal-template.md` during exploration or questioning. Load it only after the pre-write confirmation gate, so early turns carry decisions rather than output boilerplate.

---

## 阶段 4：提案审查

写入后，必须展示 canonical entrypoint 和 Why / What Changes / Out of Scope / Impact 摘要，要求工程师 review 完整 logical proposal。Split form 必须按 fragment manifest 顺序读取全部 fragments 后再展示摘要。

这属于第二个确认门禁：写文件前的确认只授权创建/写入选定 proposal form；写入后仍必须等待用户明确确认该提案产物无误，才能输出 `✅ 提案已确认，进入设计阶段` 或进入设计。Handoff consumer 必须从 `proposal.md` 或 `proposal/00-index.md` 解析唯一 canonical form，并在 split form 下按 manifest 顺序读取。
