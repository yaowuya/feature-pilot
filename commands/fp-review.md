---
description: 对已完成的 FeaturePilot 变更执行归档前最终整分支只读审查
---
## FeaturePilot workspace and information layer

Before choosing output paths, commands, UI/backend rules, or workflow behavior:

1. Treat the target project repository root as the FeaturePilot project root, and look only for `fp-docs/` directly under that root.
2. If `fp-docs/manifest.md` exists, read it first.
3. Do **not** bulk-read all `fp-docs/settings/` or `fp-docs/intel/` files. Read only the smallest relevant subset for the current phase/question.
4. If UI/frontend/prototype behavior is involved and `fp-docs/settings/frontend.md` or `fp-docs/settings/prototype-style.md` exists, read only the relevant sections as required sources.
5. If backend/API/data/security behavior is involved and `fp-docs/settings/backend.md` exists, read only the relevant sections as required sources.
6. Treat generated intel as stale-prone navigation, not proof of current behavior. If intel is stale or broad, verify just-in-time from current source files.
7. Use two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, backend framework, API envelope, or workflow policy in public skills. Customer-specific rules belong in target-project settings.

Compatibility rule: if the project root has no `fp-docs/manifest.md`, continue from current code and existing settings when safe, recommend `/fp-init`, and do not force initialization. If the current phase must write FeaturePilot artifacts, create only the necessary artifact directories under the project-root `fp-docs/`; do not create manifest/settings/intel except through `/fp-init`.
调用并严格遵守本插件内 `fp-review` skill：`skills/fp-review/SKILL.md`。

执行归档前最终 review：
- 确认 `fp-docs/changes/<slug>/`、proposal、design、tasks、`.fp-execute/progress.md` 和既有 task reviews。
- 以 read-only reviewer 身份审查整个 branch 相对 base 的最终 diff；不得修改业务代码、测试、FeaturePilot 文件、任务 checkbox、progress ledger 或 git history。
- 检查 proposal/design/tasks/progress 与实现是否一致，覆盖后端、前端、权限、安全、迁移、视觉、测试、前后端契约和 production readiness。
- 按 Critical / High / Medium / Low 记录 findings。
- 给出 `PASS` / `PASS_WITH_NOTES` / `FAIL` / `BLOCKED` final verdict。
- 将报告写入 `fp-docs/changes/<slug>/.fp-execute/reviews/YYYYMMDD-HHMM-final-review.md`。

如果 `$ARGUMENTS` 为空，按 `fp-review` skill 的规则选择或询问 slug。若无法确定 baseRef，先询问用户，不要猜测。

完成后只汇报：报告路径、final verdict、各 severity 数量、验证摘要、归档前 blocking items。
