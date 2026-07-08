# FeaturePilot Brainstorm

**设计目标：** $ARGUMENTS

## FeaturePilot workspace and information layer

Before choosing output paths, commands, UI/backend rules, or workflow behavior:

1. Walk upward from the current working directory to find `fp-docs/`.
2. If `fp-docs/manifest.md` exists, read it first.
3. Read only relevant settings and intel listed by the manifest.
4. If UI/frontend is involved and `fp-docs/settings/frontend.md` exists, read it as a required source.
5. If backend/API/data/security behavior is involved and `fp-docs/settings/backend.md` exists, read it as a required source.
6. Treat settings/intel as navigation and constraints; verify exact implementation facts against current code.
7. Use two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, backend framework, API envelope, or workflow policy in public skills. Customer-specific rules belong in target-project settings.

Compatibility rule: if an older project has no `fp-docs/manifest.md`, continue from current code and existing settings when safe, and recommend `/fp-init` repair/refresh.

调用并严格遵守本插件内 `fp-brainstorm` skill：`skills/fp-brainstorm/SKILL.md`。

`fp-brainstorm` 在你已有一个已确认的 proposal（通过 `/fp-propose` 或 `/fp-start` 生成）时使用：

- 读取 `fp-docs/changes/<slug>/proposal.md` 确认范围。
- 通过一次一个问题的苏格拉底式提问，澄清架构决策。
- 根据实际涉及范围生成 `design-backend.md`、`design-frontend.md` 或两者。
- 不预建后续阶段的文件（`tasks/`、`.fp-execute/` 等）。
