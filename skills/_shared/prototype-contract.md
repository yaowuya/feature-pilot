# FeaturePilot Prototype Contract

在识别前端/初始化基座，或创建、读取、修改、验证、归档任一原型时读取本文件。它是原型模式、来源、构建、数据隔离和产物所有权的唯一契约；普通无 UI 的需求无需加载。`${CLAUDE_PLUGIN_ROOT}` 的锚定规则由 workspace-rules 拥有。

## Capability and rendering mode

原型基座是与目标项目同技术栈、可独立运行的前端源码工程，数据为 **mock-only**。Vue 项目复用 Vue，React 项目复用 React；保留真实组件、布局、主题、字体、图标与必要 providers，不以纯 HTML 仿写替代原生复用。静态包是派生交付物，不是维护源。

有界检测：读取已有 manifest/settings 指针、候选 package/lockfile、构建配置以及实际页面/路由/模板入口；只查看少量相关源码。依赖中出现框架名不是充分证据；排除 node_modules、dist、示例与不属于目标应用的代码。复用已得到的事实，不再做全仓扫描。

| 能力 | 行为 |
|---|---|
| `no-frontend` | 已确认没有 Web 页面或模板：init 不提供 frontend/prototype-style 生成选项，不创建基座/空原型、不安装前端工具；保留已有人工文件 |
| Web frontend | 记录 appId、appRoot、实际框架/版本、构建器、组件/样式/资源入口，推荐 native 基座 |
| 多应用 | 按实际入口区分 app；选择目标，不合并依赖/主题/命令 cwd，不默认处理全部应用 |
| SSR / 服务端模板 | 属于有 UI，检查构建期与请求时依赖；不能仅凭框架名宣称可静态导出 |
| `unknown` / 非 Web 客户端 | 说明证据不足或能力边界，不等同于 no-frontend，不强装 Web 栈 |

渲染模式与 PRD-first/Prototype-first 顺序模式正交：

- **`project-native`（已有前端默认推荐）**：真实组件 + 隔离源码入口 + 场景 Mock + 独立构建/预览。已有合适 Storybook/stories 优先复用其实际版本和上下文；不强制安装 Storybook、不迁移构建器。
- **`standalone-html`**：已有 `prototype.html` 保持可读、可按批准修改；仅在用户明确选择轻量草图/降级时新建。无基座、构建失败不是自动降级许可。
- 无 UI 的需求默认不生成原型。以后明确新增前端时重新判断需求，不因初始化时 no-frontend 永久禁止原型；绿地框架及输出模式须先确认。

## Canonical artifacts and ownership

- 基座：`fp-docs/prototype-bases/<app-id>/manifest.json`，由 **fp-prototype-init** 按批准管理；fp-init 的可选阶段委托该技能，不维护第二套创建/刷新流程。`app-id` 为 kebab-case。
- Native change：`fp-docs/changes/<slug>/prototype/manifest.json`，由 **fp-prd** 按当前 change 的批准管理；同目录存源码、Mock、构建配置、`preview/index.html` 和本地 assets。
- Legacy change：`fp-docs/changes/<slug>/prototype.html`，仅 standalone-html。
- **`prototype-conflict`**：同一 change 同时存在 `prototype.html` 和 `prototype/` 就停止；`prototype/` 无 manifest 也是不完整产物，不能忽略后另写 HTML。目录不是 Markdown split form，不能当作 PRD fragment 遍历。
- 每个 feature 的 `3.N.4 原型` 指向解析出的权威原型与场景。PRD small/split、六章及四小节不变；其它文件链接而不复制细节。
- 修改/覆盖/转换必须先展示写入与移除范围，转移独有内容，验证新产物后才按批准删除旧形式。禁止破坏性复制、覆盖生产入口或修改共享基座来实现某个 change。

默认原型源码/配置位于所属基座或 change 原型目录。可以只读引用当前前端组件和样式，使用原包管理器/构建器；不复制整个仓库或 node_modules。不在生产目录新增文件来绕过路径限制：确有此需要时先报告明确额外范围，未批准就停止该基座构建，普通 PRD 可继续。

## Native manifest: fp-prototype/v1

以下是字段结构示例，不是可直接执行的模板。路径、命令、版本和 SHA256 都必须换成当前项目的验证值；无法确认时不伪造 ready manifest。

```json
{
  "schema": "fp-prototype/v1",
  "kind": "base",
  "mode": "project-native",
  "appId": "admin-web",
  "appRoot": "apps/admin",
  "framework": { "name": "vue", "version": "<actual-version>" },
  "sourceEntry": "src/main.ts",
  "mockEntry": "src/mocks.ts",
  "previewEntry": "preview/index.html",
  "commands": {
    "build": { "relativeTo": "project", "cwd": "apps/admin", "run": "<verified-build-command>" },
    "preview": { "relativeTo": "artifact", "cwd": ".", "run": "<verified-local-preview-command>" }
  },
  "sources": [{ "path": "apps/admin/src/AppLayout.vue", "sha256": "<actual-sha256>" }],
  "ownedFiles": [
    { "path": "src/main.ts", "sha256": "<actual-sha256>" },
    { "path": "src/mocks.ts", "sha256": "<actual-sha256>" },
    { "path": "preview/index.html", "sha256": "<actual-sha256>" }
  ],
  "baseReference": null,
  "dataMode": "mock-only",
  "networkPolicy": "deny-business-network",
  "scenarios": ["default", "empty"],
  "verification": {
    "build": "not-run", "preview": "not-run", "network": "not-run", "visual": "not-run",
    "evidence": null
  }
}
```

- `kind` 为 `base` 或 `change`。change 的 `baseReference` 必须含项目根相对 `path`（所选 app 的基座 manifest）及其创建该 change 时的 `sha256`。不能将不存在的基座冒充引用；无基座时由 fp-prototype-init 构建/确认后继续，或明确选择 standalone-html。
- `appRoot`、`sources[].path` 和 baseReference 相对项目根；sourceEntry/mockEntry/previewEntry/ownedFiles/evidence 相对所在原型 manifest 目录。commands 的 relativeTo 只能是 `project` 或 `artifact`，cwd 按该根解析；`.` 仅作为根目录值。
- 所有路径使用 `/`，禁止绝对路径、`..`、URL、越界及通过 symlink/reparse-point 逃逸。命令字符串是**数据，不是执行许可**；先核对当前脚本内容、副作用、cwd 与批准范围，不能直接执行陌生 manifest 的命令。
- `sources` 记录实际消费的组件、样式、资源、providers、构建配置及 lockfile 等项目输入；`ownedFiles` 覆盖原型入口、Mock、配置、fixtures、静态资源和证据文件，排除 manifest 自身。路径采用实际文件的精确大小写，所有权按大小写精确匹配，避免跨平台别名漏检。SHA256 是文件内容摘要。
- node_modules、`.cache`、`.vite` 是可再生依赖/缓存，不是交付资产，不收录其树；运行所需内容必须构建进 preview 并列入 ownedFiles。归档前清楚列出这些缓存的处置并按批准排除，不能因目录整体移动把依赖缓存当成必要源码。
- verification 四项仅可为 `not-run | passed | blocked`；有执行记录时 evidence 指向实际证据文件，记录命令/cwd、环境、来源版本、时间、结果及限制。写出 passed 字段不是已验证证明，消费者必须读证据并实时核对。
- 修改源码、Mock、配置、依赖或资产后，失效相关旧验证结论并重新构建/验证，再更新 hashes。不得只刷新 hash 把人工改动当成生成内容接受。

可运行只读结构校验器：`${CLAUDE_PLUGIN_ROOT}/scripts/validate-prototype.ps1 -ProjectRoot <root> -PrototypePath <relative-manifest-or-prototype.html> [-CheckFreshness]`。它不执行构建、预览或网络测试；非 PowerShell 运行时按相同 schema/路径/摘要规则检查，不安装 PowerShell 作为运行门槛。

## Init provisioning and refresh

**fp-prototype-init** 是此流程的执行入口，既可单独触发也可由 fp-init 调用；不要求重新运行完整 init。主 manifest 缺失时不创建它，仍可按批准建立基座。**manifest-section-only**：仅对已有主 manifest 的 `Prototype Bases` 小节按精确批准 diff 登记/更新，其余信息层内容不变。

**`approved-prototype-provisioning`** 是独立可选阶段，不属于 discovery、CodeGraph 或 settings 创建授权。先展示目标 app、参考页面、复用入口、新增/覆盖路径、实际安装/构建/预览命令及 cwd、依赖/lockfile/配置影响、Mock/截图范围，再让用户选择构建、仅报告或跳过。任何未列明副作用须重新取得授权；缺少环境不能静默安装或升级。

批准后依次执行：

1. 选择一个代表性现有页面，读取它的组件导入、布局、CSS/tokens、资源与所需上下文，限定复用范围。
2. 在基座目录创建同框架独立入口和构建配置，优先复用原配置可安全共享的部分。不要直接挂载会启动真实鉴权/轮询/埋点的应用根；先隔离 UI 壳。
3. 创建必要的本地 Mock 与明确命名的场景。Mock 初始化完成后才动态加载应用入口，避免应用模块先发请求。
4. 运行已批准的构建并生成 `preview/index.html` 及本地资源；缺少文件/构建失败时报告阻塞，不创建假成功文件。
5. 按下节进行预览、网络及视觉验证，记录证据与 metadata。manifest 主索引的基座引用必须在此次明确批准的写入范围内；settings 仍逐文件批准。
6. 报告基座路径、源码、构建/预览方式、实际验证结果与限制。未完成视觉验证可报告可运行草稿，但不能说高保真就绪；失败/跳过不阻塞 manifest-only 信息层。

运行 `/fp-prototype-init`（或由 fp-init 委托）时仅检查选定基座：实时比较 sources、ownedFiles 和现有 metadata，区分源变化与人工修改，先展示差异和刷新范围，批准后刷新。已评审的 change 不自动迁移、不改旧 preview；其它 app 不批量刷新。信息层 `.freshness.json` 仍只管 project facts，不承载基座状态。

## Change-local incremental generation

1. 解析已有原型并保留既有模式；新原型在已有前端选择 project-native，读取当前 app 的基座。有索引/明确 app-id 时只检查精确基座路径；无索引且 app-id 未知时，仅列基座目录的一层名称供选择，再核对选中 manifest 的 appRoot，不读取所有基座源码。找不到就交给 `/fp-prototype-init`，不要求重跑完整 init，不在 PRD 中偷偷创建项目基座。
2. 用 `CheckFreshness` 或等价检查核对项目输入、基座自有文件和引用版本。源过期/人工冲突不得自动覆盖；可经确认仅查看旧静态结果，但新源码增量必须先解决与当前依赖的不匹配。
3. 展示 change 原型路径、基座引用、输入来源、增量范围、Mock 场景、命令/cwd 和副作用；写入门禁仍由 fp-prd/grill-me 拥有。初始化基座的批准不授权任何新需求。
4. 在 change 的 `prototype/` 中复制必要的自有原型源码/配置/fixtures快照，并记录 baseReference；不直接依赖共享基座里可变的运行时代码，也不复制依赖目录。对项目组件的只读引用仍记录到 sources。
5. 修改本需求相关的源码，保持其它区域不变。路径/构建输出重新绑定到 change，不沿用指向基座的 outDir；禁止直接补丁修改 preview 的压缩 JS/HTML。
6. 运行已批准构建及下节检查，更新本 change 的 manifest/证据。最终报告源码入口、预览 URL/命令、基座版本、已确认场景和实际限制。

原型源码/配置写入同样遵循 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/codegraph.md`：已有图标记 dirty-after-write 后停止查询旧图，返回前执行一次 post-write-sync；失败不阻塞主流程，无图不建图。

## Mock, preview and fidelity gate

- 全部业务数据/状态仅由本地合成或明确批准脱敏的 fixtures/Mock 驱动；预览显示模拟环境标识。保留真实 UI 组件，不复制真实账号会话、cookies、storageState、`.env` 值或客户数据。
- **build-time** 与 **browser-time** 都不能访问真实业务服务。SSR/Server Components 的构建期 fetch 不会被浏览器 MSW 自动接管；请求时动态功能须有显式隔离方案，做不到就报告不支持，不改变原项目技术栈强行导出。
- `deny-business-network`：默认阻止未模拟的业务 API、WebSocket、EventSource、埋点/支付等访问；只允许本地预览所需的模块/静态资源/开发服务。MSW 接入本身不是隔离证明；未覆盖请求必须报错并阻断验收，不能静默透传。先启用拦截再加载 UI，检查网络记录。
- 不依赖真实后端或外部 CDN。生产构建资源本地化；需要授权的外部字体/素材先说明，缺失时标注限制。单独使用 localhost 静态服务/项目已验证预览器，不承诺任意包可双击 `file://`；确认端口、资源 base、导航与深链刷新策略。
- 构建检查：命令退出成功、preview 入口/引用资源存在。预览检查：独立启动、控制台无阻塞错误、目标场景及关键交互可操作。网络检查：包括加载/提交/错误路径，无真实业务请求。
- 视觉检查：与原项目代表性页面/明确标注的受控视觉参考对照，固定 viewport、主题、字体、内容及浏览器环境；核对布局、字号/密度、资源、滚动和浮层。不能拿原型自身截图通过证明还原，也不能自报未经测量的相似度。
- 需要浏览器但不可用时走既有能力/安装批准路径，报告未验证，不将静态校验冒充视觉成功。
- **not real E2E**：原型 Mock/交互/视觉证据保存在原型自己的 evidence 文件，不填入 `.fp-execute/e2e` 真实覆盖矩阵；不替代生产权限、后端业务或 Figma 专属证据。原型确认只涵盖演示内容。

## Consumer and archive resolution

读取原型前检查互斥/不完整状态。native 读取 manifest、相关场景源码和证据，静态 preview 用于交互/视觉参考；不能把源码/fixtures 当成批准的业务规则或生产实现。legacy 保持原单文件规则：内联 HTML/CSS/JS、本地模拟、无 CDN/业务后端。

归档时整个 change 原型目录一起移动，不删除基座或重写其它 change。先检查相对资源/入口和实际本地预览能否在目标归档路径工作；artifact-relative 命令 cwd 随位置解析，project-relative 的旧源/命令可过期，不自动改写执行。静态可查看与源码可重建分开报告；缺旧源可保留静态查看，但不能声称可重建。重建仍须核对 sources/baseReference、新鲜度和命令授权。
