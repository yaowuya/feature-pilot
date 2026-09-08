# 独立原型基座初始化设计

日期：2026-09-08。目标：已运行 fp-init 的项目可以只初始化或刷新原型基座，不重跑信息层、CodeGraph 配置、settings 或 discovery。

## 决策

新增公开技能与命令 `fp-prototype-init`，支持无参数或指定 app-id/app-root。它是项目级基座创建/复用/刷新流程的唯一执行所有者；fp-init 只在可选阶段调用它。fp-prd 遇到缺失/过期基座时指向该命令，仍只负责 change 内的原型增量。

不采用复制一份 fp-init 步骤的方案，也不让新入口重新调用完整 fp-init。

## 边界

- 复用 prototype-contract 的能力检测、同技术栈/Mock、指纹、审批和验证，不更改 fp-prototype/v1 产物 schema。
- 单独运行不要求主 manifest 存在；缺失时不创建主 manifest、settings 或 intel，只在批准后创建基座及必要父目录。
- 主 manifest 已存在时，只能在精确 diff 获批后登记/更新 `Prototype Bases` 小节，不修改其余人工内容；这是一项狭窄的既有文件写入例外。
- fresh 基座默认复用并明确本轮没有重建；stale/人工冲突先显示差异再刷新；无前端不生成任何原型，unknown 不当作无前端。
- 多 app 或 app-id/appRoot 身份冲突必须澄清，不能覆盖错误应用。
- fp-init 调用时传递已验证事实与精确批准范围；不重复询问已确认事实，不额外运行第二套 provisioning。返回后只继续未完成的信息层流程。
- 默认不执行 CodeGraph 安装/MCP 配置、项目 discovery 或全量 init；已有图的代码导航及写后同步仍遵循原合同。

## 验收

1. 新 command/skill、路由和参考文档可发现，全部插件校验通过。
2. 已有信息层独立调用只影响批准的基座和可选 Prototype Bases 行。
3. 没有主 manifest 仍可单独建立基座，不强制先 init。
4. fp-init/fp-prd 和共享所有权指向新技能，没有相反的旧基座 owner 指令。
5. 原生原型 29 个产物用例、既有 PRD/信息层/真实 E2E 约束保持。
6. 静态/模型回放不冒充真实前端构建和视觉实测；不提交或推送。
