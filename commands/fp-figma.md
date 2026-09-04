---
description: 根据 Figma 链接生成或完善项目当前前端框架的 UI 实现，遵循项目本地前端/UI/UX 配置
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-figma/SKILL.md`，将「$ARGUMENTS」作为输入；该 skill 及其共享 workspace contract 是完整事实源。

Gate checksum：

- Figma-only UI source；原型不参与视觉还原。
- `PRES-*` / `FIGCAP-*` 防止改坏或漏功能。
- 浏览器能力由客户选择，not install silently。
- independent review 通过才是 Figma change complete。
