---
name: fp-prototype-init
description: Use when a project needs its reusable frontend prototype base initialized or refreshed independently, including projects that already use FeaturePilot or have no fp-docs manifest yet.
---

# FeaturePilot Prototype Init

单独创建、复用或刷新同技术栈、可独立运行、业务数据全 Mock 的项目原型基座。既可由用户直接调用，也可作为 fp-init 的可选阶段；不生成某个需求的 PRD 或 change 原型。

## Required context and ownership

插件资源锚定、路径映射与缺失停止规则由 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` 拥有。先读取它，再读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/prototype-contract.md`；资源缺失即停止，不在消费者项目搜索替代技能。共享契约拥有能力检测、schema、构建、Mock、新鲜度及验证规则，本技能拥有基座执行流程。

- **no-full-init**：不得调用完整 fp-init，不运行其 CodeGraph 安装/MCP 配置、settings 生成或 discovery。已有项目不需要重新初始化信息层。
- **no-manifest-required**：主 `fp-docs/manifest.md` 不存在也可运行；只在批准后创建基座和必要父目录，不创建主 manifest、settings 或 intel。
- 基座写入范围仅为 `fp-docs/prototype-bases/<app-id>/`，不修改生产入口、其它 app、现有 change 原型或人工设置。
- **manifest-section-only**：主 manifest 已存在时，可在精确 diff 获批后仅登记/更新它的 `Prototype Bases` 小节。其余内容必须保持不变；不能把基座批准当成整个信息层的修改权。
- 来自 fp-init 的 caller context 可复用已验证前端事实、选定 app 和精确批准范围；不能凭“init 已批准”推断安装、覆盖或索引编辑也已批准。

## Input and target selection

`/fp-prototype-init` 可无参数，也可提供已知 app-id 或项目内 app-root；参数是定位意图，不作为 shell 命令或目录写入授权。

1. 定位项目根；若有主 manifest，作为索引读取，只读与目标 app 有关的 frontend/prototype-style 设置。
2. 按共享契约有界核实实际 Web/模板入口、框架/版本、组件/样式及构建配置。复用 caller 已核实事实，不重复全仓调查。
3. `no-frontend`：报告不适用后结束，不生成原型文件、不提供前端安装。SSR/服务端模板属于有 UI；unknown 不等于无前端，先确认实际入口。
4. 单 app 可自动选择并说明；多个 app 或参数不能唯一匹配时，只询问目标 app。appRoot 必须位于当前项目内，不能把示例、构建产物或路径越界当成目标。
5. 已有基座从主索引、用户给出的精确路径或明确 app-id 解析；没有索引且 app-id 未知时只列基座目录的一层名称供选择，不读取所有基座源码。新基座提出 kebab-case app-id，并检查与已有 appRoot 的身份冲突。

## Existing base and write decision

先检查目标目录、manifest、sourceEntry、mockEntry、previewEntry 和来源记录。目录已存在但缺少有效 manifest 时报告不完整状态，先确认恢复/替换范围，不覆盖成新项目。

- **fresh-reuse**：来源及 ownedFiles 指纹未变、没有人工冲突且没有明确重建请求时，默认复用并跳过源码修改/重建。若仅缺验证或索引，单独提出补验证/登记的最小批准范围，不重跑构建全流程。区分“本轮检查结构/指纹”与“本轮重新构建/视觉验证”，不伪称做过后者；未完成的验证仍如实保留。
- 来源变化：展示 source 指纹差异及受影响的基座文件。
- 人工修改：展示 ownedFiles 差异及保留/合并/替换建议，逐文件取得明确批准；不通过更新 hash 掩盖修改。
- app-id、appRoot、框架或来源身份不一致：停止并澄清目标/迁移，不自动覆盖另一个应用。

按共享契约 **approved-prototype-provisioning** 展示一次审批摘要：目标 app 与代表性页面、真实组件/主题复用、新增或修改路径、Mock 场景、构建/预览命令及 cwd、依赖/lockfile/配置/截图影响。提供创建/选择性刷新、仅报告、跳过；需要恢复人工内容时把该文件的明确处置纳入批准范围。

若主 manifest 已存在，读取 `${CLAUDE_PLUGIN_ROOT}/skills/fp-init/templates.md` 的 Prototype Base Registration 片段，提出仅 `Prototype Bases` 的精确 diff。用户可以批准基座但不登记索引；此时不写主 manifest，完成后报告精确基座路径。没有主 manifest 时直接略过此登记，不要求先运行 fp-init。

## Build, verify and register

取得相关明确批准后，执行共享 prototype-contract 的 Init provisioning and refresh；不复制另一套构建规则。fresh-reuse 时只执行已批准的缺项验证/索引登记，若没有缺项直接报告复用，不进入下面的源码修改与构建步骤：

1. 创建/更新本基座的原生源码入口、必要组件/布局包装、配置和 Mock 场景；沿用当前框架，不改写为纯 HTML 冒充原生复用。
2. Mock/网络隔离先于 UI 加载，检查 build-time 和 browser-time 业务请求；不连接真实后端，不复制会话、密钥或真实客户数据。
3. 执行获批构建、独立 localhost 预览、网络和视觉对照；使用 `CheckFreshness` 或等价校验核对实际来源/自有文件。命令/JSON 校验通过不等于运行或还原度通过。
4. 写入真实的 fp-prototype/v1 metadata 和证据。只有对应基座产物已存在且结构有效后，才按已获批 diff 更新已有主 manifest 的 Prototype Bases 引用；索引不写长期 ready/stale 结论。
5. 若构建或浏览器条件不足，报告 blocked/未验证及实际已写文件，不发布虚假成功引用，不自动安装或降级；不影响已有信息层和旧需求原型。
6. 若写入原型源码/配置，对已有图执行共享契约的 dirty-after-write/post-write-sync；无图不建图，失败不阻塞主流程。

## Output and caller return

简洁报告：app-id/appRoot、created/refreshed/reused/skipped/no-frontend/blocked、基座 manifest 与源码/预览入口、实际验证及限制、主索引已更新或未修改。仅执行过的构建/预览命令才报告为已验证。

独立调用完成后，可给出 `/fp-prd <需求>` 作为后续入口，不自动进入需求编写或生产实现。若由 fp-init 调用，return 给 caller 同一结果及实际写入/审批状态，只继续其尚未完成的信息层步骤；不得重跑本技能、重复询问或由 fp-init 再写一次基座/索引。
