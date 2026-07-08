# FeaturePilot Propose

**功能描述：** $ARGUMENTS

**如果功能描述为空**，请提示工程师提供详细的需求说明：背景与目标、具体需求、约束与边界。

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

调用 `fp-propose` skill，完成：
- 探索项目现状（以 `fp-docs/manifest.md` 为导航入口，不读取历史 changes/archive；必须以真实代码、测试、路由、模型、组件和 API 为实现事实依据）
- Socratic 需求澄清（如需要，2-4 轮）
- 生成 `fp-docs/changes/<slug>/proposal.md`
- 引导工程师逐节确认提案
