---
description: 初始化 fp-docs 信息层（单一 manifest、可选 settings/intel 与项目族示例）
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-init/SKILL.md`，将「$ARGUMENTS」作为输入；该 skill 及其共享 workspace contract 是完整事实源。

Gate checksum：

- `fp-init` 是唯一可创建或修复项目级 manifest/settings/intel 的流程。
- 不创建 changes/archive/history。
- 可选 settings、discovery、项目族示例采用与任何覆盖操作都必须先确认。
- discovery 只读；Unknown 不得猜测。
