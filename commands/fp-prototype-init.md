---
description: 单独初始化或刷新项目原型基座，无需重新运行 fp-init
---

读取并严格执行 `${CLAUDE_PLUGIN_ROOT}/skills/fp-prototype-init/SKILL.md`，将「$ARGUMENTS」作为输入；技能及共享 prototype/workspace contract 是完整事实源。

Gate checksum：

- no-full-init：只处理原型基座，不重跑信息层、CodeGraph 安装/MCP、settings 或 discovery。
- no-manifest-required：没有主 manifest 也能运行，不创建它或 settings/intel；无前端跳过。
- 创建/刷新前展示准确 app、路径、命令/cwd、依赖与覆盖影响并批准；fresh-reuse 不冒充重新构建。
- manifest-section-only：只有精确 diff 获批时才更新已有主 manifest 的 Prototype Bases 小节，其余内容不变。
- 同技术栈独立源码、全 Mock、静态预览；真实后端/E2E 与原型证据保持分离。
