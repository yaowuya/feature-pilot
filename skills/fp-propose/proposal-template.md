# Proposal Output Template

Read this file only after the user approves the Why / What Changes / Out of Scope / Impact confirmation summary and immediately before writing `proposal.md`.

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

Before returning, confirm every section is concrete, scope does not exceed approved requirements, and Impact is supported by current code exploration.
