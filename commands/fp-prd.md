---
description: 将用户故事、想法或痛点澄清为 PRD 文档
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
---

**现在开始：** 根据「$ARGUMENTS」调用 `fp-prd` skill。

## Hard gate

`/fp-prd` 是需求澄清入口，不是一次性 PRD 生成器。

- 必须先加载并遵守 `fp-prd`，再由 `fp-prd` 加载 `fp-prd-grill-me`。
- 支持两种模式：默认 PRD-first；当用户明确想“先看原型/先做原型/先出交互稿”或需求明显 UI-heavy 时，进入 Prototype-first。
- PRD-first：写任何 PRD 文件前，必须完成 PRD interview gate：Phase 1 批量输出 Bucket A/B 已确定项供审阅 → Phase 2 逐个提问 Bucket C 待确认项（一问一答，不能自问自答）。
- Prototype-first：先通过 prototype-blocking 问题确认页面/交互/字段/状态/视觉来源，用户批准后先写 `fp-docs/changes/<slug>/prototype.html`；用户确认原型后，才能继续补问剩余 PRD-blocking Bucket C 问题并写 `prd.md`。
- 除非用户输入已经是完整 PRD 或明确授权“无需提问，按假设生成”，否则至少必须有 3-5 个 Bucket C 问题等待用户回答。
- 未获对应阶段确认前，不得创建目录、不得写 `prd.md`、不得写 `prototype.html`。
- PRD 只能写入 `fp-docs/changes/<slug>/prd.md`；禁止写入 `fp-docs/prd-*.md` 或 `fp-docs/*.prd.md`。
- 生成的 `prd.md` 内容结构必须严格使用 `fp-prd` skill 的 Mandatory PRD Structure：一级标题、二级标题、三级/四级小节、表格列名和顺序都不得擅自改名、合并、删除、重排或新增额外一级章节。
- `/fp-prd` 必须使用 lazy context：只读 `manifest.md` 作为索引，按当前需求读取最小相关 settings/intel；禁止全量读取 `fp-docs/settings/`、`fp-docs/intel/`、历史 `changes/archive/history`。
- `fp-docs/intel/*` 是会过期的导航线索，不是当前事实；涉及当前实现时必须用当前代码搜索/读取验证。
