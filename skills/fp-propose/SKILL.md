---
name: fp-propose
description: 为新功能变更生成并确认 proposal.md 提案文档
---


## FeaturePilot workspace and customer settings

Before choosing output paths, component-library guidance, test commands, or workflow rules, locate the target project's FeaturePilot workspace:

1. Walk upward from the current working directory to find `fp-docs/`.
2. If it does not exist and this phase needs to create artifacts, initialize the minimal tree:
   - `fp-docs/settings/`
   - `fp-docs/changes/`
   - `fp-docs/archive/`
   - `fp-docs/agents/`
3. Read any settings files that exist. Do not create or overwrite customer settings unless the user explicitly asks.

Settings are optional. If a file is missing, fall back to current project code, adjacent implementations, and public defaults only; never invent customer-specific conventions.

Recommended settings file:

- `fp-docs/settings/agent.md` — optional project-specific FeaturePilot rules, including workflow, paths, component library, design system, UI tokens, Figma mapping, and visual review requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, or workflow policy in public skills. Customer-specific rules may be described in optional `fp-docs/settings/agent.md`.

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

**判断需求是否清晰：**
- 描述 ≥ 2 句话、包含具体目标和约束 → 跳过问答，直接生成草稿
- 描述模糊（如 "加个文件管理"、"优化审批流程"）→ 进入问答

**问答规则：**
- 每次只问一个问题，给出 2-3 个选项 + "其他（请描述）"
- 结合项目现有架构和最佳实践，在选项中体现推荐做法
- 问题聚焦在影响提案范围的关键决策，不问可以设计阶段再决定的细节
- 问题维度（按重要性排序，不必全部问）：
  1. **核心目的**：解决什么痛点？谁在用？频率如何？
  2. **范围边界**：哪些子功能必须有，哪些明确不做？
  3. **关键约束**：与现有模块的集成方式？是否有性能/安全要求？
  4. **交付优先级**：是否分阶段交付？MVP 是什么？

收集足够信息后（通常 2-4 轮），停止问答，进入起草阶段。

---

## 阶段 3：生成 proposal.md

1. 根据功能描述生成 kebab-case slug（中文转英文语义缩写，例如 "新增文件库功能" → `file-library`）
2. 【立即用工具执行】在当前目录向上查找 `fp-docs/` 目录；若不存在，在 cwd 初始化 `fp-docs/` 基础目录。
3. 【立即用工具执行】创建 `fp-docs/changes/<slug>/` 目录。
4. 【立即用工具执行】将下方模板填写完整后，写入 `fp-docs/changes/<slug>/proposal.md`

只生成本阶段产物 `proposal.md`。不要预创建 `design.md`、`tasks.md`、`tasks/`；这些文件/目录只能由后续对应阶段在真正需要时创建。

根据问答结论和项目现状，生成填写完整的 proposal.md：

```markdown
# <功能描述>

## Why

<!-- 描述当前痛点、动机、用户场景。结合项目现状说明为什么现在做。 -->

## What Changes

<!-- 具体变更内容，每条独立小节，描述要足够让研发理解范围 -->

### 1. <变更点1>

<!-- 描述 -->

### 2. <变更点2>（如有）

<!-- 描述 -->

## Capabilities

### New Capabilities

- `<capability-slug>`: 一句话描述新增能力

### Modified Capabilities

- `<existing-capability>`: 描述对现有能力的扩展

## Out of Scope

<!-- 明确列出本次不做的内容，防止范围蔓延 -->
-
-

## Impact

<!-- 受影响的文件/模块，结合项目架构填写 -->
- `path/to/file.py` - 说明
```

---

## 阶段 4：提案审查

提示工程师自行 review 生成的 proposal.md，确认内容无误后告知继续。

输出：`✅ 提案已确认，进入设计阶段`
