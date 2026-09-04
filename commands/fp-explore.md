---
description: 只读探索当前项目的事实、行为、方案、约束与风险
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-explore/SKILL.md`，将自然语言输入「$ARGUMENTS」作为 standalone 输入。

Gate checksum：

- 本命令只负责转发；standalone 行为、内部 profiles、预算、返回结构、只读/研究边界、验证和调用方迁移全部以已加载的 `fp-explore` skill 为唯一权威。
- 探索不创建产物、不实现、不自动进入其他 FeaturePilot workflow。
