---
description: 初始化或刷新 fp-docs 信息层（CodeGraph、单一 manifest、可选 settings/intel 与项目族示例）
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-init/SKILL.md`，将「$ARGUMENTS」作为输入；该 skill 及其共享 workspace contract 是完整事实源。

Gate checksum：

- `fp-init` 是唯一可创建或修复项目级 manifest/settings/intel 的流程。
- 不创建 changes/archive/history。
- 可选 settings、discovery、项目族示例采用与任何覆盖操作都必须先确认。
- CodeGraph 是可选加速层；自动安装只使用 `npm install -g @colbymchenry/codegraph@latest`，MCP 配置独立确认，首次建图使用 `codegraph init`，失败必须回退。
- 已有信息层进入 `refresh-existing-information-layer`；只在确认后选择性刷新 stale generated intel，人工 settings 和冲突文件不得批量覆盖。
- discovery 只读；Unknown 不得猜测。
