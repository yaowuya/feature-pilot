---
name: fp-propose
description: 为新功能变更生成并确认 proposal.md 提案文档
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting; it owns root resolution, `fp-docs/manifest.md` read order, lazy context, stale-intel evidence, precedence, neutrality, compatibility, and artifact ownership.
---

# FeaturePilot Propose

你正在帮助工程师为功能「{{description}}」生成变更提案文档。

---

## PRD handoff input

If `fp-start` or the user provides a PRD slug and `fp-docs/changes/<slug>/prd.md` exists, read that PRD before asking requirement questions. Use confirmed PRD content as the primary requirement source and generate `proposal.md` as a concise development proposal. Ask only about gaps that block proposal scope, impact, or delivery strategy.

---

## 阶段 1：探索项目现状

必须以代码为最终事实来源：
- 读取 `CLAUDE.md`（项目根目录或 `.claude/`）：了解架构、技术栈、代码规范
- 读取 `fp-docs/settings/` 中与当前阶段相关的客户配置；不要读取历史 `fp-docs/changes/` 或 `fp-docs/archive/` 作为功能背景；当前代码仍是最终实现事实来源
- 使用 `rg` / `rg --files` 搜索需求关键词、接口、模型、组件、路由、测试和相邻实现
- 根据功能描述，初步判断涉及哪些子系统/模块
- 如果文档和代码冲突，以当前代码为准

---

## 阶段 2：需求澄清（Socratic 问答）

**判断需求是否足够进入确认摘要：**
- 如果输入来自已确认的 `fp-docs/changes/<slug>/prd.md`，可以把 PRD 作为已确认需求来源，只询问 proposal 范围、影响或交付策略的阻塞缺口。
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
- 写 `proposal.md` 前必须展示 Why / What Changes / Out of Scope / Impact 的摘要。
- 必须等待用户明确确认（如“确认”“继续”“按这个生成”）。
- 助手的推荐或代码探索结论不是用户确认。
- 未获确认前，不得创建 `fp-docs/changes/<slug>/` 或写 `proposal.md`。

---

## 阶段 3：生成 proposal.md

1. 根据功能描述生成 kebab-case slug（中文转英文语义缩写，例如 "新增文件库功能" → `file-library`）
2. 【立即用工具执行】确认目标项目根目录，并把输出限定在项目根目录下的 `fp-docs/changes/<slug>/proposal.md`。
3. 如果项目根目录没有 `fp-docs/manifest.md`，只提示建议运行 `/fp-init`；不要强制初始化，也不要创建 manifest/settings/intel。
4. 【立即用工具执行】在用户确认摘要后，创建必要的 `fp-docs/changes/<slug>/` 目录。
5. 【立即用工具执行】读取 `proposal-template.md`，填写完整后写入 `fp-docs/changes/<slug>/proposal.md`。

只生成本阶段产物 `proposal.md`。不要预创建 `design.md`、`tasks.md`、`tasks/`；这些文件/目录只能由后续对应阶段在真正需要时创建。

Do not load `proposal-template.md` during exploration or questioning. Load it only after the pre-write confirmation gate, so early turns carry decisions rather than output boilerplate.

---

## 阶段 4：提案审查

写入 `proposal.md` 后，必须展示生成路径和 Why / What Changes / Out of Scope / Impact 摘要，要求工程师 review 生成的 proposal.md。

这属于第二个确认门禁：写文件前的确认只授权创建/写入 `proposal.md`；写入后仍必须等待用户明确确认该提案产物无误，才能输出 `✅ 提案已确认，进入设计阶段` 或进入设计。
