# init 技术栈规范选用与登记

本文件只负责 `fp-init` 的检测、自动选用和 settings 登记。规范正文由 `skills/_shared/code-standards/` 维护，后续消费由共享 `engineering-quality.md` 的“已登记技术栈规范”维护。插件资源路径按 workspace contract 解析，不在客户仓库查找插件文件。

## 1. 有界确认实际应用

`direct-dependency-and-entry-evidence`：复用已读事实，只补查候选应用的依赖声明和必要入口，不全仓扫描。

| 端 | 必要证据 | 选中 preset | 规则资源（插件相对路径） |
| --- | --- | --- | --- |
| Backend | `requirements*.txt` / `pyproject.toml` 等直接声明 Django，且 `manage.py` / settings / 启动入口证明该 app 实际使用 | `django` | `skills/_shared/code-standards/common.md` + `skills/_shared/code-standards/django.md` |
| Frontend | 当前 app 的 `package.json` 直接声明 Vue，且构建/组件/入口证明实际使用 | `vue` | `skills/_shared/code-standards/common.md` + `skills/_shared/code-standards/vue.md` |

- `independent-end-matching`：Django / Vue 分端独立匹配，Django-only 只选后端，Vue-only 只选前端，双端选两份；React、Flask 等非匹配端用通用 settings，preset=`none`，不泄漏无关端规范。
- 保留每个应用的 `appRoot`、框架/版本和证据路径。多应用逐 app 记录，明确选中的资源适用根，不把同仓 Vue 规范施加给 React 应用。
- `unknown-is-not-a-match`：只有 README、目录名、间接 lockfile 依赖、测试工具依赖、历史设置或示例时不足以确认实际框架，记 `Unknown`，不自动选栈；框架已证实但版本未明时可选框架通用规则，把版本细则留为 Unknown，相关实现前核实。
- 根依赖/workspace 模式只沿显式配置定位真实 app；manifest-only 初始化不为识别规范运行程序、安装依赖、建图或读取 secrets。

## 2. 保留客户来源并适配版本

`existing-rules-first`：在已有项目文档引用和已知规则目录中，按本次端/应用有界定位相关 `.claude/rules/`、`.cursor/rules/` 或其他明确引用的规范。显式读取适用文件，不把目录存在当已检查，不递归搜索所有私有配置。已有手工 settings 与规范只读保留。

- `no-example-derived-facts`：Canway 项目族示例仍须独立 opt-in；Django/Vue 命中不是项目族信号或采用示例的许可。示例正文只作待适配草稿，不能用其中固定版本、组件库、基类或路径覆盖当前依赖。
- Pydantic v1 / Pydantic v2 按已确认的依赖启用对应校验 API；未用 Pydantic 则使用现有 Form/Serializer 等入口，不引入依赖。DRF、Celery、软删除和租户隔离同理按实际能力适用。
- Vue 2.6 沿用受支持的组件/响应式写法；Vue 2.7 / Vue 3 按真实工具链支持使用 `<script setup>`，不强制升级。Vuex/Pinia、i18n、HTTP client、样式 token 和组件库从当前配置取值，不预设库或目录。
- FK/逻辑 ID、choices/枚举、行长、目录、公共基类等依客户已确认政策。记录明确覆盖的规则编号/范围/原因；没有明确政策时采用规范的条件化默认，不从一处存量写法推导全局规范；未决冲突写 Unknown，并在相关技术决策前澄清。

## 3. 自动选用，按批准登记

`no-second-preset-choice`：匹配证据成立后直接选对应 preset，不再询问“要用哪套代码规范”。在现有 Section 7 settings 多选问题中简要说明该文件将引用的 preset、应用根和已知适配项。

`selection-is-not-write-approval`：选用只产生当前上下文中的候选，仍遵守 `manifest-only default` 和每个 settings 的明确批准：

- 仅在对应 `backend.md` / `frontend.md` 创建获批时，以 templates.md 的 `Code Standards` 槽位登记引用。保持原环境、API、UI、预览与验证设置；不复制规范正文，不新增规范副本或第二份 manifest。
- 已有 settings 不自动补写/迁移；用户明确要求更新时先展示该文件精确 diff 和写入范围，批准后才写。框架检测、项目族批准、discovery 或 CodeGraph 批准均不授权覆盖。
- 项目族模板获准作为缺失 settings 的草稿时，在同一次已批准的新文件创建中填入经实时证据选定的 Code Standards；已经存在或已经写好的 settings 不借此回补，另走更新批准。
- 没有批准、选择跳过或仅报告时，不写 settings/manifest/规则目录。已有 manifest 的引用更新仍需其独立精确批准；不声称规范已登记。
- 不写 `.claude/rules` / `.cursor/rules` / AGENTS 自动加载文件，不修改宿主配置、不安装依赖。

每个已批准 settings 的 `Code Standards` 使用同一形状；多应用逐 app 使用这五个字段作为一组，保持 preset 与适用范围对应：

- `Built-in preset:` `django` / `vue` / `none` / `Unknown`。
- `Rule resources:` 匹配时仅登记表中公共 + 对应端插件相对路径；`none` / `Unknown` 为 `N/A`。使用逻辑插件路径，不固化当前机器安装目录或外部规范源绝对路径。
- `Applies to:` appRoot、框架版本和直接依赖/入口证据；版本/附加能力未知如实标记。
- `Project rule sources:` 已读取的客户项目相对规范路径及适用范围；没有则 `none`，不得猜测。
- `Confirmed overrides:` 已确认的规则 ID、范围和原因；没有则 `none`，未决项单列 Unknown，不把未知事实写成已确认例外。

## 4. 如实汇报

按端/应用报告 `registered`（实际写入获批 settings）、`preserved`（已有人工设置保留）、`skipped`（未批准/跳过）或 `unknown`（证据不足）。选择候选不等于 registered，也不代表测试、构建或适配验证通过。用简明中文交代 preset、重要适配和未决项，不展示中间字段转储。
