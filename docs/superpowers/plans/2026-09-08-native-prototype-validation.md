# 原生原型基座验证记录

日期：2026-09-08。实现计划：`2026-09-08-native-prototype-baseline.md`。本轮未提交、推送或同步已安装插件缓存。

## 变更范围

- 新共享 prototype-contract：前端能力检测、同框架独立基座、全业务 Mock、change 隔离源码与静态 preview、授权/来源/新鲜度/归档。
- fp-init 无前端跳过，有前端按独立批准 provisioning；fp-prd 默认推荐 project-native，保留明确的 standalone-html。
- PowerShell 只读原型校验器、29 个产物 fixture 与静态跨技能契约测试；UI/E2E 保持真实业务零 Mock，新增原型证据隔离及反绕过测试。
- 之前尚未提交的 PRD business-first 变更保持并通过回归。

## 基线与行为回放

修改前的独立场景回放观察到：

1. 纯 Python API 项目仍被展示 frontend/prototype-style 设置选项，因为旧 init 要求列出全部选项。
2. Vue3/Vite 项目被限制为 prototype.html，只转换组件外观与样式，不生成 Vue 源码或构建入口。

新测试首次执行分别因缺少 prototype-contract 和 validate-prototype 而失败。补充未索引资产场景后，旧校验器错误接受额外文件，修复后拒绝。

修改后的独立只读审查/场景回放符合：

- API-only 项目省略前端/原型设置及基座；保留已有人工内容。
- Vue 项目无基座时交由 init 单独批准，不因已批准原型就偷偷建基座或降级为 HTML。
- 旧 HTML 小改保留原模式，不强制迁移或创建基座。

这些是模型行为回放及文档审查，不是执行真实消费者项目的 fp-init/fp-prd。

## 独立审查后的复现与修复

| 问题 | 复现 | 修复/回归 |
|---|---|---|
| PowerShell 枚举比较隐式类型转换 | schema=true 被当成合法 schema | schema/mode/kind/dataMode/networkPolicy 先验证字符串；5 个布尔值用例均拒绝 |
| 相对项目根采用进程目录而非 PowerShell 当前目录 | Set-Location 后 ProjectRoot=. 仍定位原仓库 | 用 Resolve-Path 的 FileSystem ProviderPath；相对位置 fixture 通过 |
| 路径所有权字典忽略大小写 | src/Main.js 记录被当成 src/main.js 所有权 | 使用 Ordinal 字典，精确大小写回归通过 |

首次完整回归还发现 UI/E2E 的封闭规范快照未包含新增原型隔离段。已同步精确规范行，并增加禁止“仅凭目录豁免”和“Mock 替代真实 E2E”的 mutation 断言，原零 Mock/状态机/不可豁免门禁保持。

## 最终运行结果

- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1`：exit 0；12 commands、22 skills，所有 SKILL.md 不超过 500 行，全部集成契约通过。
- 集成的新 `test-prototype-artifacts.ps1`：29 cases passed，覆盖 base/change/legacy、互斥、schema/类型、路径/受保护数据/junction、源/人工/基座指纹、归档静态与重建区分；manifest 命令未执行。
- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-artifact-layout.ps1`：79/79 fixture classes passed，现有 PRD 和其它产物表示兼容。
- `git diff --check`：通过。Git 仅提示既有换行策略将 docs/reference/architecture-and-artifacts.md 的 LF 转为 CRLF，不是 diff 错误。

## 尚未验证与边界

- 没有选择或运行真实消费者 Vue/React/Storybook/SSR 项目；没有实测框架抽取成功率、实际构建、浏览器 Mock 隔离或视觉保真度。
- 产物 fixture 是模拟目录/文件，不是 Vue 运行示例；JSON/路径验证通过不能代表运行成功。
- 命令在当前 Windows PowerShell 环境运行，未进行 Linux/macOS 运行验证；路径大小写规则有独立回归，但不冒充跨平台实测。
- 未安装依赖、未变更生产前端、未新建 CodeGraph；本仓库无图，未执行 post-write sync。
- 本地已安装的插件缓存未更新，运行时需要加载更新后的仓库版本才能使用新流程。
