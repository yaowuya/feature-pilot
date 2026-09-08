# 前端原型基座优化方案与最佳实践调研

日期：2026-09-08。原始调研方案已由用户确认，并进一步明确为“同技术栈、可独立运行的前端源码工程，业务数据全 Mock”。插件工作流与校验实现见 [实施计划](../plans/2026-09-08-native-prototype-baseline.md) 和 [验证记录](../plans/2026-09-08-native-prototype-validation.md)；下文保留调研时的事实与分期，真实消费者项目试点尚未执行。

## 1. 结论

采纳“无前端不初始化原型、有前端初始化基座、需求阶段增量扩展”的方向，但将基座定义为：**可编辑的原型源码 + 复用真实组件/应用壳的隔离入口 + 场景数据 + 可静态预览的构建产物 + 来源与保真验证记录**。

不建议将整个应用简单复制为一份 HTML，再把这份构建结果作为长期维护源。静态预览应当不依赖真实业务后端，但不必限制为单个 HTML 或要求双击 `file://` 即可运行。源码是维护入口，静态包是评审交付物。

本方案是根据一手资料及插件现有契约作出的工程建议，不是官方统一推荐的现成架构，更不是已经验证的任意项目一键抽取能力。

## 2. 调研方法与证据边界

通过浏览器搜索发现实践方向，再核查官方正文。搜索摘要与搜索引擎 AI 概览不作证据。本次定向核对了 15 个官方文档/规范页面，不代表穷尽全网或进行了行业采用率调查。

检索主题包括组件驱动开发、Storybook/MSW/providers、静态构建、Next 导出限制、视觉回归、GOV.UK 原型实践与设计 tokens。

没有安装工具、运行消费者项目、制作基座或测量保真度提升；具体项目的可构建性、自动抽取范围、初始化耗时和收益仍需试点。源码调查使用主工作目录中的当前文件，包含前一轮尚未提交的 fp-prd 业务逻辑增强。

## 3. 一手来源与可采用的实践

| 来源 | 可核实事实 | 对本方案的启示 |
|---|---|---|
| [S1 Storybook stories](https://storybook.js.org/docs/writing-stories) | Story 可导入实际组件，通过参数描述渲染状态 | 优先复用组件与已有 stories，不重新猜组件外观 |
| [S2 Storybook 发布](https://storybook.js.org/docs/sharing/publish-storybook) | Storybook 能构建为可静态托管的网站 | 静态原型可以是资源目录；静态构建不自动消除业务请求 |
| [S3 Storybook 网络模拟](https://storybook.js.org/docs/writing-stories/mocking-data-and-modules/mocking-network-requests) | MSW 支持 HTTP/GraphQL 及分 story 的成功、失败、延迟等响应 | 将需求相关场景与模拟入口纳入产物；不能仅接入 addon 就宣称所有真实请求已隔离 |
| [S4 Storybook providers](https://storybook.js.org/docs/writing-stories/mocking-data-and-modules/mocking-providers) | decorators 可显式提供主题等上下文 | 组件隔离需要接入依赖上下文，不会自动继承整个应用 |
| [S5 Storybook 框架支持](https://storybook.js.org/docs/get-started/frameworks) | React、Vue、Angular 等有不同框架/构建器组合 | 统一能力协议，而不是强制统一 UI 框架或构建器 |
| [S6 Storybook 样式](https://storybook.js.org/docs/configure/styling-and-css) | preview 可导入全局 CSS，预览内容有自己的渲染环境 | 样式入口、预处理器、主题和 providers 都是基座依赖 |
| [S7 Vite 构建](https://vite.dev/guide/build) | 构建生成静态资源包，支持多 HTML 入口及 base 配置 | 沿用现有构建能力；运行时拼接 URL 与路由刷新仍需验证 |
| [S8 Vite 资源](https://vite.dev/guide/assets) | 构建器处理导入资源及 CSS URL，public 资源可原样复制 | 保留真实字体、图标、图片及资源路径，不用近似物替换 |
| [S9 Next 静态导出](https://nextjs.org/docs/app/guides/static-exports) | 支持构建期 Server Components；动态服务端能力有明确限制 | 按页面依赖选择可静态导出或客户端隔离，不一刀切认定所有 SSR 都不支持或都能导出 |
| [S10 Playwright 视觉比较](https://playwright.dev/docs/test-snapshots) | 截图比较受系统、浏览器、字体等环境影响，需要审查基准更新 | 必须对照原项目，不能用原型与自身基准一致冒充保真 |
| [S11 GOV.UK Prototype Kit](https://prototype-kit.service.gov.uk/docs/) | 复用设计系统样式、组件、页面模式构建可交互服务原型 | 原型应承载用户任务；此来源不证明任意应用可自动导出静态基座 |
| [S12 DTCG Format](https://www.designtokens.org/tr/2025.10/format/) | 标准化设计值、类型及引用表达 | 消费已有 tokens，不把 tokens 当成完整布局与交互；这是 Community Group 报告，不是 W3C Recommendation |
| [S13 Playwright 认证状态](https://playwright.dev/docs/auth) | 认证状态可能含可用于冒充账号的敏感 cookies/headers，强烈不建议提交仓库 | 原型不得复制真实登录状态；验证环境与原型产物隔离 |
| [S14 MDN 本地文件 CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/CORS/Errors/CORSRequestNotHttp) | file URL 存在 opaque-origin/CORS 限制，推荐本地服务器测试 | 默认通过 localhost 静态服务预览，不承诺任意多文件包可双击运行 |
| [S15 MDN cloneNode](https://developer.mozilla.org/en-US/docs/Web/API/Node/cloneNode) | DOM 克隆不复制 addEventListener/属性赋值事件处理器及 canvas 已绘制内容 | 简单 DOM 复制不等于交互复用；不能把此限制扩大成所有导出工具都无法补足 |

版本注意：本次 S3 页面针对 addon v3；S9 正文标注 Next.js 16.3.4、2026-08-25 更新。实施时以目标项目实际版本为准，不照搬最新版本配置。

## 4. 当前插件已经有的能力与缺口

### 已有能力

- `skills/fp-init/templates.md:215-240` 已有框架、源码位置、组件导入、tokens、预览命令等字段。
- 同文件 `288-335` 已有原型页面骨架、颜色、字体、间距、组件和交互风格。
- `skills/fp-frontend-spec/SKILL.md:18-48` 已要求查验当前组件与 API 并优先复用。
- `skills/fp-prd/SKILL.md:207-221` 已要求真实可操作交互、本地模拟数据、不调用后端，并参考已有页面或规范。
- 前一轮 PRD 增强已把业务流程、状态、规则和异常确认放到页面设计之前；此方向应保留。

### 实际缺口

- PRD 原型交付限定单文件 HTML/CSS/JS，缺少源码入口、依赖、构建、场景和资产清单协议。
- 单文件规则并不禁止打包真实组件，禁 CDN 也不禁止本地依赖；问题是没有明确的复用与构建路径，容易退回仿写。
- 风格提炼是文本描述，不是可运行页面骨架；识别“Vue + 某组件库”不等于加载了项目主题、业务封装、providers 和布局。
- 缺少原项目与原型同条件对照的基座验收、相关源码变更后的刷新机制，以及每个需求绑定哪一版基座的记录。

### 不能绕过的现行边界

- `skills/fp-init/SKILL.md:138` 默认只创建 manifest；`187-208` 的 settings 按选择批准。
- `215-244` 的 discovery 只读，不能借机安装依赖、运行构建或复制真实数据。
- `skills/_shared/workspace-rules.md:38-42` 没有把任意源码脚手架写入权授给 init。
- `skills/_shared/ui-e2e-contract.md:61-67` 的真实 E2E 禁止 mock；原型测试必须是独立证据通道，不改变真实 E2E 门禁。

因此，本功能必须成为**明示的可选基座构建阶段**，不能偷偷塞进现有 discovery 或借用 CodeGraph 安装授权。

## 5. 推荐技术路线

| 路线 | 合适场景 | 主要限制 | 定位 |
|---|---|---|---|
| 项目原生组件/应用壳 + 隔离场景 + 静态构建 | 已有前端，需求应延续现有产品外观与流程 | 需要适配构建器、上下文、路由与数据边界 | 推荐主路线 |
| 复用已有 Storybook | 已有 stories，组件或页面可以隔离 | 不自动保留整站 router/layout/providers | 主路线的一种适配器，不强制安装 |
| 独立单 HTML 仿写 | 极轻量草图、用户明确选择、已有旧原型 | 容易与真实组件实现分叉 | 保留兼容/降级模式 |
| 页面截图或 HTML 快照 | 视觉参考、不能运行源码时收集依据 | 单纯快照不保证交互可维护 | 参考资产，不作为默认源码基座 |

优先级是：现有合适的原型/stories 入口 → 可复用原应用壳的薄隔离入口 → 可隔离的真实组件页面 → 明示降级。采用哪条由具体需求和依赖决定，不为统一格式迁移技术栈。

两种轴必须分开：PRD-first/Prototype-first 仍决定产物顺序；新增的 `project-native`/`standalone-html` 只决定原型渲染与交付方式。

## 6. fp-init 的建议流程

### 6.1 有界识别前端能力

综合依赖/lockfile、构建配置、实际页面或模板入口、路由、组件源码确认应用存在，不只查 React/Vue 依赖。排除依赖目录、构建产物和不属于当前应用的示例。

结果区分：客户端 Web 前端、服务端模板/SSR Web、非 Web 客户端、无前端、无法确定。多应用仓库记录各自 app root；消费者项目根与命令 cwd 不混淆。

- 明确无前端：跳过原型设置推荐及基座创建，不安装 Node，不生成空原型文件；已有人工设置不删除。
- 检测不确定：报告依据并确认目标应用，不把 Unknown 当成无前端。
- 有 Web 前端：推荐初始化基座；多应用由用户选择目标，不默认合并。
- 原本无前端、以后新需求明确要新增前端：允许届时显式采用绿地原型，不受初始化时跳过限制。

### 6.2 一次清楚的基座授权

保留 manifest-only 基础流程。在识别前端后增加单独的可选 provisioning 决策，列明：目标应用、参考页面、复用方式、新增文件、构建/预览命令及 cwd、依赖/lockfile/配置影响、截图与数据范围。

用户可选择初始化、仅记录事实或跳过。授权只覆盖列出的基座相关操作，不延伸为 settings 覆盖、真实数据访问、CodeGraph 配置或生产代码改写许可。缺工具时不静默安装；新增依赖与项目配置修改必须出现在批准清单。

### 6.3 初始化最小可用基座

提取并复用：框架及版本、组件库/业务组件、真实 tokens/CSS、字体与图标、导航壳、页面容器、必要主题/国际化/路由等 providers、构建器与资源路径配置。

首轮只选择一个有代表性的现有页面，保留真实壳与该页面必要组件，再按实际需要补一个交互场景。不遍历和静态化整站，也不预先复制所有表单、表格、弹窗。

应用根组件如果同时启动鉴权、轮询、埋点或真实 API，不直接整体挂载；先找到可隔离 UI 边界，使用薄包装入口与受控场景。

### 6.4 输出静态预览并验证

保留源码及构建配置；静态预览包包含 HTML、JS、CSS、字体、图片等必要本地资产。默认 localhost 预览，无真实业务后端、无外部 CDN 依赖。

init 报告区分可用、降级、阻塞或不适用，并给出验证过的入口和限制。基座失败不阻塞基本信息层初始化，也不能宣称高保真基座已就绪。

## 7. 产物与所有权建议

以下为新增协议的建议布局，不是当前插件已经支持的目录：

```text
fp-docs/
  manifest.md
  settings/
    frontend.md
    prototype-style.md
  prototype-bases/
    admin-web/
      manifest.json
      src/
      fixtures/
      preview/
        index.html
        assets/
      reference/
  changes/
    add-owner-filter/
      prd.md
      prototype/
        manifest.json
        src/
        fixtures/
        preview/
          index.html
          assets/
```

- `frontend.md` 继续拥有人工前端约束，只引用基座；`prototype-style.md` 保留人工视觉/交互偏好，不能被自动提取覆盖。
- 基座 manifest 记录 appRoot、适配器、sourceRefs、源 fingerprint、依赖/lockfile 引用、源码位置、实际构建/预览命令、cwd、入口、场景及验证来源，不保存 secrets。
- `src/` 是最小原型入口/包装与场景源码，优先引用当前组件，不复制整个项目或 node_modules。现有 stories 可以直接被引用。
- 上图 src 位置是默认值。若原构建器要求源码位于前端包内，适配器须在授权前声明确切 sourceRoot 和新增范围；不得靠隐藏复制或悄悄改生产入口解决。
- `preview/` 是可再生静态结果，需求迭代修改源码，不直接修改构建后的 JS/HTML。
- `reference/` 仅在有批准的视觉参考采集时创建，保存脱敏截图与 viewport/主题/来源说明，不是永远必建的空目录。
- init 拥有项目级基座；prd 拥有 change 级原型。需求变更不能覆盖共享基座。
- legacy `prototype.html` 保持可读；新模式用 `prototype/` 的显式 manifest 和入口。两种模式不能同时充当同一 change 的权威原型。
- 原型资产不是 Markdown 分片，另定义解析协议；不套用 `Order/File/Kind/Owns` 分片规则，也不因为外层文件名保留就声称无痛兼容。

## 8. fp-prd 如何在基座上增加功能

1. 完成已有业务分析与相关产品决策确认，确定目标前端应用、最接近的原页面及本次改动范围。
2. 读取对应基座 manifest，实时比较相关源码/样式/配置/lockfile fingerprint；过期或来源不明时说明影响，按批准刷新或显式采用受限旧基线，不能默默更新。
3. 为 change 创建隔离源码和场景数据，记录 baseRevision 与 sourceFingerprint；布局、导航和不相关区域默认保持基座表现。
4. 新功能优先由项目已有组件组合；只新增本需求需要的表单、动作、状态或页面区域，不重新仿写整页。
5. 在独立原型环境模拟业务数据与必要权限表现；未知业务策略仍返回访谈，不让 mock 自动决定产品规则。
6. 构建静态预览，展示改变的区域、可操作场景、与参考页面的差异及尚未验证内容。
7. 用户确认后，PRD 的现有 `3.N.4 原型` 内记录模式、源码、入口、基座版本与已确认场景。保留六章、原表头及四段 feature block。

原型代码属于隔离评审资产，不等于生产实现；不能将模拟鉴权或数据处理直接带入正式交付。原型通过只确认被演示内容，不替代后台业务或真实 E2E 验收。

## 9. 防止基座过期与需求互相污染

只跟踪实际消费的 layout、组件、样式/tokens、providers、资源和构建配置，不在每次 PRD 时全仓扫描。

- source fingerprint 变化只触发实时检查，不能自动覆盖人工设置或历史需求原型。
- 基座刷新由 `/fp-init` 的新增可选分支承接；不宣传目前不存在的 `--refresh` 命令。
- 每个需求绑定自己的基座与构建记录；基座升级后，已有需求是否迁移单独确认。
- 已评审静态包不因源引用改变而自动重写。需要重建时重新核对输入与批准范围。
- 归档验证相对资产、深链接/刷新策略和移动后的 localhost 可预览性。源码重建与静态查看分开记录；仅静态包可打开不能冒充历史环境完全可重建。

## 10. 保真与安全验收

### 保真不是只比较颜色

对相同页面/状态固定 viewport、缩放、主题、字体、内容和浏览器/系统环境，再比较原项目与基座。参考可来自脱敏的实际页面或明确标注的受控视觉场景，必须记录来源。

核对布局、字号/行高、组件密度、图标、长文本、滚动、浮层挂载位置及需求相关状态。原型自身快照稳定不能证明对原项目保真；基准更新不能自动接受。

不预设“95% 相似度”等未经项目验证的统一阈值。首版采用真实组件复用清单、受控截图差异及人工确认；后续再按具体页面设置容差。

### 数据与网络隔离

- 不复制 `.env` 值、真实 cookies、认证 storageState、客户数据或完整敏感截图到基座。
- 只使用合成或明确批准且脱敏的数据；原型显示“模拟环境”标识。
- 默认不连接真实业务 API、WebSocket、埋点或支付渠道；构建期的数据获取也须隔离。
- MSW 是适配选项，不是完整安全边界。必须检查未覆盖请求，验证发现真实业务请求时阻断验收；静态资源、模块加载及本地预览服务使用明确允许范围。
- 模拟原型的交互/视觉验证单独记录，不能填入插件的真实 E2E 覆盖矩阵。

## 11. 框架与降级边界

- **已有 Storybook**：复用实际版本与配置，不升级、不默认重装；补齐必要 providers、样式和场景。
- **React/Vue 客户端项目**：优先原构建器；已有 Vite 可评估专用隔离入口，不要求 Webpack 项目迁移 Vite。
- **Angular**：保留其编译与 provider/module 规则，单独适配，不转写成 React。
- **Next/SSR**：可静态计算的 Server Components 不必否定；Server Actions、请求 cookies、动态路由等依赖必须逐项识别。浏览器 MSW 不负责构建时 fetch，不能把二者混为一谈。
- **服务端模板项目**：识别为有 Web UI，但不承诺仅凭模板文件就能静态化；需隔离样本渲染/数据的适配器。
- **无法安全隔离或构建**：明确报告缺失能力，允许只完成信息层、采用已批准的参考/低保真模式或停止基座生成，不伪装成等价高保真结果。

## 12. 插件改动范围与分期

| 位置 | 建议变更 |
|---|---|
| `skills/fp-init/SKILL.md`、`templates.md` | 前端能力识别、可选 provisioning、应用选择、基座入口、受控刷新 |
| 新增 `skills/_shared/prototype-contract.md` | 渲染模式、source/build/preview、资产解析、所有权、刷新、兼容与证据边界的唯一契约 |
| `skills/fp-frontend-spec/SKILL.md` | 结合基座来源验证组件/主题/providers，保留项目规则权威性 |
| `skills/fp-prd/SKILL.md`、`fp-prd-grill-me/SKILL.md`、`prd-template.md` | 选择目标基座、隔离增量、预览与交互确认、记录来源；保持业务访谈门禁 |
| `_shared/workspace-rules.md`、`artifact-layout.md`、`fp-archive` | 新资产的授权、解析与可移动归档；不改真实 E2E 零 mock 原则 |
| commands、指南、项目族示例、校验脚本 | 消除所有“原型必须单文件”的无条件指令，保留旧模式，增加新模式验证 |

**第一阶段：一个真实前端的完整闭环。** 无前端跳过；选择一个应用；复用一个已有页面壳和真实组件；隔离数据；静态预览；原项目对照；基于基座增加一个小功能。支持范围只列实测过的框架/构建器组合。

**第二阶段：扩展适配与维护。** 按实际项目需求增加多应用、更多框架、SSR/模板方案、版本刷新与归档回放。不承诺首版自动抽取任意整站，也不统一安装 Storybook。

## 13. 建议验收用例

以下是实施后的验收要求，本轮未执行：

1. 纯后端项目不创建 prototype-style/基座/空原型，也不安装前端依赖。
2. 服务端模板能被识别为有 UI，能力不确定时不误判为无前端。
3. 有前端但用户跳过时，保持 manifest-only 或原有已批准信息层，不额外写文件。
4. 单应用能用真实组件、字体、主题和页面壳构建、预览并演示相关交互。
5. 多应用仓库不混用 appRoot、依赖和构建 cwd。
6. 既有 Storybook 按项目实际版本工作，不擅自升级或污染原故事。
7. 构建期和浏览器运行期都不访问未批准的真实业务服务。
8. 新需求只改变目标区域，两个需求原型之间互不污染，共享基座不被覆写。
9. 空数据、失败、权限、长文本等适用状态与页面约束一致。
10. 指纹变化能发现基座过期，人工修改和历史需求不被自动覆盖。
11. 单 HTML 旧原型继续可读，新模式入口/资源缺失明确失败，双权威表示被拒绝。
12. 静态包移动到归档后仍能经声明的本地服务打开，资源、深层导航及刷新策略有效。
13. 无法构建、字体/资源缺失或无法获取参考时，如实标注降级/阻塞，不报已验证高保真。
14. 原型 mock 验证不被记作真实 E2E 已覆盖。

## 14. 本轮交付范围

本轮只完成调研和方案文档；没有修改任何技能、构建配置、依赖或插件缓存，没有提交、推送或发布。前一轮 fp-prd 未提交修改保持原状。是否采用、首个试点项目以及正式支持矩阵需要后续实施范围确认。
