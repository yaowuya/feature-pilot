---
name: sync-plugin-runtimes
description: Use when the current FeaturePilot repository must be synchronized to its locally installed Claude Code and Codex plugin runtimes, including unchanged-version cache refresh or installation verification.
---

# Sync Plugin Runtimes

读取并严格执行 `../../../.agents/skills/sync-plugin-runtimes/SKILL.md`。该文件是此项目同步流程的 single source of truth。

本入口只负责 Claude Code 项目级发现；不要在这里复制同步步骤，不要修改插件自身的 `skills/`、`commands/` 或清单。
