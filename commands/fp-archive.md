# FeaturePilot Archive

**变更 slug（可选）：** $ARGUMENTS

## FeaturePilot workspace and information layer

Before choosing output paths, commands, UI/backend rules, or workflow behavior:

1. Walk upward from the current working directory to find `fp-docs/`.
2. If `fp-docs/manifest.md` exists, read it first.
3. Read only relevant settings and intel listed by the manifest.
4. Treat settings/intel as navigation and constraints; verify exact implementation facts against current code.
5. Use two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, backend framework, API envelope, or workflow policy in public skills. Customer-specific rules belong in target-project settings.

调用 `fp-archive` skill，完成：
- 确认归档目标（slug 或从列表选择）
- 移动变更目录并更新历史记录
- 更新 `fp-docs/history/history.md` 和 `AGENTS.md`
- 不将历史 archive 用作实现背景

等待执行完成后，输出 `✅ 已归档`。

---
