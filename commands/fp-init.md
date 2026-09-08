---
description: 初始化或刷新 fp-docs 信息层，并按批准建立同技术栈、独立运行、全 Mock 的前端原型基座
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-init/SKILL.md`，将「$ARGUMENTS」作为输入；该 skill 及其共享 workspace contract 是完整事实源。

Gate checksum：

- `fp-init` 负责完整项目级信息层；`manifest-only default` 只创建 manifest，不预建可选目录或 changes/archive/history。
- settings、项目族示例、覆盖及 human-owned knowledge 均先批准；discovery 只读且只产出 `project-facts.md` + metadata-only `.freshness.json`。
- CodeGraph 可选；安装仅用 `npm install -g @colbymchenry/codegraph@latest`，对应当前 CLI 状态，安装/MCP/建图（含 `codegraph init <project-root>`）一次批准并逐步汇报，失败回退。
- `refresh-existing-information-layer` 实时计算 project facts 的 stale/conflict，确认后选择性刷新；人工/冲突内容不批量覆盖。
- `no-frontend` 跳过前端/原型设置及基座；有 Web 前端时委托 `fp:fp-prototype-init`，由其独立 `approved-prototype-provisioning` 批准建立同技术栈、全 Mock 基座。已有项目只补原型时直接用 `/fp-prototype-init`；不借用 discovery/CodeGraph 授权。
- 旧 unknown/refresh/handoff 文件仅作一版只读兼容，不创建、刷新或要求；Unknown 不猜测。
