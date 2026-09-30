---
description: Use when a user explicitly invokes /fp-prd or $fp-prd, or explicitly asks to create, write, revise, or complete a PRD or product requirements document.
---
用 `${CLAUDE_PLUGIN_ROOT}/skills/fp-prd/SKILL.md` `$ARGUMENTS`
Gate checksum：
- 默认 PRD-first；UI-heavy 只推荐；未选不建原型
- `fp-explore`=代码事实；`product-surface-facts`→产品语言；`fp-prd-grill-me` 独占决策/禁代答
- 业务闭环→对象/关系/生命周期/版本语义→页面
- 产品语言禁源码路径、类名/函数名/模型名/接口名、构建命令、端口、SHA、Git 状态/验证计数
- Bucket A=用户决定/已验证现状/零影响措辞；Bucket B=易撤销展示默认；其余 Bucket C 逐项问，不因数量降级
- 批准前不写 PRD/原型源码、不构建；PRD form互斥；prototype-contract：现有前端默认 `static-modular`，`project-native`/`standalone-html` 须确认
- 写门禁后加载共享文档风格契约→PRD 模板；只改表达，固定六章/产品事实/确认结果不变
