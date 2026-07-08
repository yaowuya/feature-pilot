# FeaturePilot Review

**变更 slug（可选）：** $ARGUMENTS

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

调用并严格遵守本插件内 `fp-review` skill：`skills/fp-review/SKILL.md`。

执行归档前最终 review：
- 确认 `fp-docs/changes/<slug>/`、proposal、design、tasks、`.fp-execute/progress.md` 和既有 task reviews。
- 以 read-only reviewer 身份审查整个 branch 相对 base 的最终 diff；不得修改业务代码、测试、FeaturePilot 文件、任务 checkbox、progress ledger 或 git history。
- 检查 proposal/design/tasks/progress 与实现是否一致，覆盖后端、前端、权限、安全、迁移、视觉、测试、前后端契约和 production readiness。
- 检查信息层使用情况：manifest 是否读取、required settings/intel 是否参考、unknowns 是否在 plan/execution 前解决、UI 工作是否使用 `settings/frontend.md`、backend/API/data/security 工作是否使用 `settings/backend.md`、是否存在依赖 stale intel 而非当前代码的情况。
- 按 Critical / High / Medium / Low 记录 findings。
- 给出 `PASS` / `PASS_WITH_NOTES` / `FAIL` / `BLOCKED` final verdict。
