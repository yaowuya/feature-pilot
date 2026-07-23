---
description: 初始化或刷新 fp-docs v2 信息层（manifest-only、可选 settings/project facts、CodeGraph 与项目族示例）
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-init/SKILL.md`，将「$ARGUMENTS」作为输入；该 skill 及其共享 workspace contract 是完整事实源。

Gate checksum：

- `fp-init` 唯一拥有项目级信息层；`manifest-only default` 只创建 manifest，不预建可选目录或 changes/archive/history。
- settings、项目族示例、覆盖及 human-owned knowledge 均先批准；discovery 只读且只产出 `project-facts.md` + metadata-only `.freshness.json`。
- CodeGraph 可选；安装仅用 `npm install -g @colbymchenry/codegraph@latest`，MCP 与 `codegraph init` 分别遵守确认门，失败回退。
- `refresh-existing-information-layer` 实时计算 project facts 的 stale/conflict，确认后选择性刷新；人工/冲突内容不批量覆盖。
- 旧 unknown/refresh/handoff 文件仅作一版只读兼容，不创建、刷新或要求；Unknown 不猜测。
