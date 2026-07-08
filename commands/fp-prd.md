---
description: 将用户故事、想法或痛点澄清为 PRD 文档
---
## FeaturePilot workspace and information layer

Before choosing output paths, commands, UI/backend rules, or workflow behavior:

1. Treat the target project repository root as the FeaturePilot project root, and look only for `fp-docs/` directly under that root.
2. If `fp-docs/manifest.md` exists, read it first.
3. Read only relevant settings and intel listed by the manifest.
4. If UI/frontend is involved and `fp-docs/settings/frontend.md` exists, read it as a required source.
5. If backend/API/data/security behavior is involved and `fp-docs/settings/backend.md` exists, read it as a required source.
6. Treat settings/intel as navigation and constraints; verify exact implementation facts against current code.
7. Use two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, backend framework, API envelope, or workflow policy in public skills. Customer-specific rules belong in target-project settings.

Compatibility rule: if the project root has no `fp-docs/manifest.md`, continue from current code and existing settings when safe, recommend `/fp-init`, and do not force initialization. If the current phase must write FeaturePilot artifacts, create only the necessary artifact directories under the project-root `fp-docs/`; do not create manifest/settings/intel except through `/fp-init`.
---

**现在开始：** 根据「$ARGUMENTS」调用 `fp-prd` skill。

## Hard gate

`/fp-prd` 是需求澄清入口，不是一次性 PRD 生成器。

- 必须先加载并遵守 `fp-prd`，再由 `fp-prd` 加载 `fp-prd-grill-me`。
- 写任何 PRD 文件前，必须完成 PRD interview gate：提问、记录用户回答、展示确认摘要，并等待用户明确批准。
- `fp-prd-grill-me` 使用批量确认模式：梳理 Bucket A/B 已确定项 + 最多 3-5 个 Bucket C 待确认问题，**所有 C 问题在一轮内发完**；等待用户一次性回答全部。不得逐题追问、不得逐题反复确认。
- 除非用户输入已经是完整 PRD 或明确授权”无需提问，按假设生成”，否则至少必须问一轮 PRD-blocking 问题。
- 未获确认前，不得创建目录、不得写 `prd.md`、不得写 `prototype.html`。
- PRD 只能写入 `fp-docs/changes/<slug>/prd.md`；禁止写入 `fp-docs/prd-*.md` 或 `fp-docs/*.prd.md`。
- 生成的 `prd.md` 内容结构必须严格使用 `fp-prd` skill 的 Mandatory PRD Structure：一级标题、二级标题、三级/四级小节、表格列名和顺序都不得擅自改名、合并、删除、重排或新增额外一级章节。
