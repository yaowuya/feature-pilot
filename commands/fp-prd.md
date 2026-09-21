---
description: Use when a user explicitly invokes /fp-prd or $fp-prd, or explicitly asks to create, write, revise, or complete a PRD or product requirements document.
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-prd/SKILL.md`，将「$ARGUMENTS」作为输入，再按其要求加载 `fp-prd-grill-me`；skill 链及共享 workspace contract 是完整事实源。

Gate checksum：

- 默认 PRD-first；UI-heavy 只作推荐，不自动切换；未获用户选择不创建原型工程。
- `fp-explore` 只给代码事实，`product-surface-facts` 须先转产品语言；`fp-prd-grill-me` 独占产品决策确认。
- 先业务闭环，再对象、关系、生命周期和版本语义，最后落页面。
- 产品语言门禁：PRD 不写源码路径、类名/函数名/模型名/接口名、构建命令、端口、SHA、Git 状态和验证计数。
- Bucket A 只含用户决定、验证过的现状和零影响措辞；Bucket B 只含易撤销展示默认；其余强制 Bucket C，一问一答不得代答，不因数量降级凑数。
- 确认摘要获批前不写 PRD/原型源码、不运行构建；PRD 在互斥的 `prd.md` / `prd/00-index.md` 预选一种；原型按 prototype-contract 选模式，前端用 `project-native` 或 `standalone-html`。
