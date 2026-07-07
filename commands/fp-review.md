---
description: 对已完成的 FeaturePilot 变更执行归档前最终整分支只读审查
---

# FeaturePilot Review


## FeaturePilot workspace

执行命令前，先遵守目标项目的 `fp-docs` 契约：如需生成产物，使用 `fp-docs/changes/`、`fp-docs/archive/`；如存在 `fp-docs/settings/agent.md`，先读取与当前阶段相关的配置。不要创建或覆盖客户 settings，除非用户明确要求。
**变更 slug（可选）：** $ARGUMENTS

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
