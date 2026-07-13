# Proposal Output Template

Read this file only after the user approves the Why / What Changes / Out of Scope / Impact confirmation summary and immediately before writing `proposal.md` or `proposal/00-index.md` plus its fragments.

## Representation rules

- Small form is `fp-docs/changes/<slug>/proposal.md`; split form is `fp-docs/changes/<slug>/proposal/00-index.md` plus indexed fragments. `proposal.md` and `proposal/` are mutually exclusive.
- Select the form before writing. For form selection, default to the small form when the complete logical artifact is expected to stay within 500 lines and 30,000 characters. Use split form only when the small form is expected to exceed either hard limit, the user explicitly approves split form, or an applicable target-project setting explicitly requires it. Multiple features, page areas, subsystems, change scopes, or ownership domains guide fragment boundaries after splitting; they do not trigger split form by themselves.

叙述性内容默认使用中文；代码、命令、路径、技术标识符、API 字段以及本模板要求精确匹配的英文 schema 标题保留必要英文。若用户或目标项目设置明确指定其他语言，按共享优先级执行。

- In split form, `00-index.md` contains navigation and the authoritative fragment manifest only. Every sibling Markdown fragment is listed exactly once using this schema:

```markdown
| Order | File | Kind | Owns |
| ---: | --- | --- | --- |
| 1 | `01-why.md` | context | Why |
| 2 | `10-changes-core.md` | changes | What Changes points 1-2 |
```

- Write fragments directly on semantic boundaries. Logical concatenation in fragment manifest order must pass logical template validation against the exact heading order below, with every mandatory section owned exactly once.
- Keep each complete What Changes change point in one fragment. Why, Capabilities, Out of Scope, and Impact each have one detailed owner; other fragments link instead of duplicate.

```markdown
# <功能描述>

## Why

<!-- 当前痛点、动机、用户场景，以及为什么现在做。 -->

## What Changes

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

- <明确不做的内容>

## Impact

- `path/to/file.py` - <受影响模块和原因>
```

## Structure self-review

- Exactly one canonical form exists: `fp-docs/changes/<slug>/proposal.md` or `fp-docs/changes/<slug>/proposal/00-index.md` plus indexed fragments; the mutually exclusive pair never coexists.
- For split form, the fragment manifest lists every sibling Markdown fragment exactly once with unique Order/File values and unique detailed ownership; every listed file exists and no unindexed fragment exists.
- Every Markdown file, including `00-index.md`, has at most 500 lines and 30,000 characters.
- Logical template validation reads fragments in manifest order and preserves Why / What Changes / Capabilities / Out of Scope / Impact exactly once and in order.
- Every section is concrete, scope does not exceed approved requirements, and Impact is supported by current code exploration.
