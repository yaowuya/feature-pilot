---
description: 对一个大型功能模块或多个相关模块执行证据驱动的专项审查与受控修复
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-module-review/SKILL.md`，将「$ARGUMENTS」作为输入；该 skill、模板和共享 workspace contract 是完整事实源。

Gate checksum：

- 只接受一个 large module 或 multiple related modules 的有界目标；不静默扩为全仓审查。
- `REVIEWING` / `TRIAGING` 对产品源码和既有测试保持只读；Finding 确认后才允许进入受控修复。
- 外部可观察行为或安全策略变化必须按稳定 Finding ID 明确批准。
- 每项修复必须保留 RED、GREEN、owner scope 和 adjacent regression 证据。
- 本 skill does not replace `fp-final-review`；归档前整分支终审仍使用后者。
