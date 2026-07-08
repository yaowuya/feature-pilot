# FeaturePilot PRD

**想法 / 用户故事 / 需求描述：** $ARGUMENTS

**如果输入为空**，请提示工程师给出一句想法、痛点、目标或用户故事即可；不要要求一次性提供完整 PRD。

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

调用 `fp-prd` skill，完成：
- 先加载 `fp-prd-grill-me` 完成必要提问与确认
- 生成 `fp-docs/changes/<slug>/prd.md`
- 如需要页面/交互原型，生成同级 `prototype.html`
- 停止在 PRD 交付阶段，不自动进入 proposal/design/plan/execute
- 下一步建议用户运行 `/fp-start <slug>` 接住 PRD 并进入开发链路
