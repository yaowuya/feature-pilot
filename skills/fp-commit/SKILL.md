---
name: fp-commit
description: Use when a user asks to 提交代码, commit reviewed changes, or explicitly invokes fp-commit auto on a Git branch.
---

## FeaturePilot workspace and information layer

插件资源锚定、`${CLAUDE_PLUGIN_ROOT}` 路径映射与缺失即停止规则见 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md`；不要在消费者项目中搜索 `skills/**`。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting. Before code review or repair, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/engineering-quality.md`; its registered `Code Standards` section is the only built-in rule-consumption entry. If this project already has `.codegraph/` and code location or source writes are involved, read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/codegraph.md` and follow its dirty-after-write/post-write-sync rules; never create an index for this workflow.

# FeaturePilot Commit

本技能按“规范门禁 → 规范符合性与代码缺陷 review → 修复和验证 → commit → push → PR/MR”执行。用户的提交请求授权当前范围的审查、修复与提交，不自动授权普通模式的推送、PR/MR 创建或最终合并。`fp-final-review` 的整分支归档门禁仍由它自己负责，本技能不冒充终审。

## 输入和授权

- **普通模式**为默认。仅本轮用户显式选择 `fp-commit auto` 或明确要求本技能的 `auto` 模式，才启用自动模式；不能从宿主权限的 Auto/Bypass、历史选择或配置推断。保留宿主工具的审批和安全限制，技能本身不能绕过。
- **自动模式**不逐步询问：预检通过后自行完成 review、必要修复、验证、commit、push 和 PR/MR 创建。创建 PR/MR 后停止，**不自动合并**，也不启用平台 auto-merge。步骤中遇到阻塞时立即停止，报告已发生的写入/远端动作，不降级为跳过门禁。
- 普通模式按本文件的推送、PR/MR 和确认合并门禁提问。用户明确说“只提交”“不推送”“不建 PR”时，遵守当前更窄授权；普通模式的拒绝不改变后续阶段的真实性报告。

## 1. 只读预检与代码规范初始化

1. 从 Git 仓库根定位 `fp-docs/manifest.md`，先按索引读取当前变更涉及的 `fp-docs/settings/backend.md` 或 `frontend.md` 的 `Code Standards`，分端/按 appRoot 核对 `Built-in preset`、`Rule resources`、`Applies to`、`Project rule sources` 和 `Confirmed overrides`。读取客户已登记的实际规则路径与插件已安装资源，不把消费项目的 `skills/**` 当插件副本。
2. 当前应用须有可核实、可读取的 `django` / `vue` 已登记 preset，或有明确的已登记项目规则来源。仅有 manifest、`Unknown`、占位内容、`none` 且没有项目来源均表示规范未初始化。此时停止并要求运行 `/fp-init` 创建/更新相关 settings；`fp-init` 的逐文件批准不能由 `auto` 代替。已登记资源不可读或互相冲突也停止，不以源码习惯私自补写设置。
3. 读取共享工程质量契约、当前端内置规范及已登记项目规范，按 appRoot/版本限制适用；客户明确规范和本轮用户指令优先。规范登记只由 `fp-init` 更新，本技能不能创建或修改 manifest、backend/frontend settings、`Confirmed overrides` 或插件内置规则正文。
4. 核对 `git status`、已暂存和未暂存 diff、未跟踪文件、当前分支、上游远端、目标宿主与本轮改动范围。只选用户请求相关文件，保留其他暂存和工作区内容；若无法区分或已暂存内容含范围外文件，普通模式先澄清，自动模式报阻塞。凭据、本地原型资产、生成产物、CodeGraph 索引与私有数据不能纳入提交。

### 普通模式本地提交

本地 review、修复、验证和 commit 不需要远端配置或 PR/MR 鉴权；用户要求“只提交”时完成本地步骤后结束。只有选定推送阶段才解析并确认实际推送目的地，只有选定 PR/MR 阶段才核对宿主能力、目标仓库和用户确认的目标分支。远端步骤不可用不撤销已完成的本地提交。

### 自动模式远端预检

自动模式在任何 Git 写入前完成下列预检；普通模式仅在用户选定对应远端阶段时复用相关检查。

1. 按 Git 的有效推送配置解析 remote：依次核对 `branch.<branch>.pushRemote`、`remote.pushDefault`、`branch.<branch>.remote` 及已确认的选择。配置缺失或多个候选无法唯一确定时停止，不拿 fetch 上游代替推送目的地。
2. 用 `git remote get-url --push --all <remote>` 取得 Git 已处理 `pushurl`、`pushInsteadOf` / URL rewriting 的**实际 push URL**；必须唯一。多个 push URL、无法解析或指向不同仓库时停止。用 `git ls-remote --symref <push-url> HEAD` 查询这个确切目的地的远端默认分支，不通过 remote 别名查询 fetch URL。核实 PR/MR 宿主识别的仓库与该目的地是**同一仓库**，后续请求固定该仓库标识；输出 URL 时脱敏，凭据不进入日志/正文。
3. 确认当前分支是可发 PR/MR 的 topic 分支、源/目标不同、远端目标存在，且宿主有可用并已认证的 GitHub/GitLab 创建能力。无法确定默认分支、当前就在默认分支、目的地不明或目标不存在时停止，不能猜 `main` / `master`。普通模式的目标分支仍由用户在创建 PR/MR 前确认。

## 2. 双轨 review、修复与项目规范沉淀

1. 按本次改动的完整 diff、受影响调用链及必要测试检查，分别报告 **规范符合性**（规则编号、`path:line`、偏差）和 **代码缺陷**（具体输入/状态、错误结果、根因及证据）。已确认问题先在本轮范围内修复；涉及新需求、越权文件或无法安全验证的阻塞项不继续提交。修复后重新审查实际 diff，运行项目已有的相关测试/静态检查及必要负向用例，逐项记录通过、失败、未验证。
2. 只有显式项目约定或多个独立的当前源码/测试证据支持、且无相反约定时，才把尚未记录的可执行项目规则视为“新规范”。单个文件的偶然命名或单次缺陷只报告为候选，不升级为强制规则。对确定的新规范检查重复/冲突及适用端，在 `fp-docs/settings/code-standards.md` 的 `## Rules` 中按递增 `P001` 等 Rule ID 写入 Rule、Applies to（appRoot、端、版本）和 Evidence；移除空状态行。只维护已存在、已获批准且列于当前应用 `Project rule sources` 的该文件，不创建或更新其他规则源。
3. 若已经确认需要沉淀新规范，但上述文档缺失、未登记或只读，先停止并引导 `/fp-init` 完成逐文件批准与登记；自动模式同样停止。尚不成立的候选只在报告中说明，不阻塞已验证代码的提交。规范沉淀本身进入本次审查、验证及暂存范围，不能在提交后悄悄补写。
4. 检查本次新/改变行为对象的契约说明、非显然约束注释和复杂度依据；无依据新增复杂度或失效说明按共享工程质量契约修复。必要验证缺失时普通模式需用户明确接受具体缺口；自动模式以**检查失败**处理并停止，不把未验证冒充通过。

## 3. 精确暂存、commit 和 push

1. 审查完成后只用精确路径暂存本轮文件；核对最终 `git diff --cached --stat`、完整 `git diff --cached` 与 `git diff --cached --check`，检查敏感内容、生成物和用户范围外暂存。部分暂存时验证实际提交组合。格式化、hook 或再编辑改变快照后，重审 diff 并重跑受影响验证。无可提交内容就报告，不创建空 commit。
2. 提交信息按目标项目约定生成；在已获提交授权的本轮范围内提交。hook 失败先调查，不能绕过；提交失败不推送。提交后核实实际 SHA、提交包含的文件与工作区剩余变更，如与已审快照不一致则停止。
3. 普通模式在**推送前**解析并展示当前分支、脱敏的实际目的地、上游和提交 SHA，单独确认后再推送。显式自动模式在预检范围内推送该 topic 分支，无逐步询问；宿主权限审批仍然有效。推送固定已核实的实际 push URL 和 `refs/heads/<source>:refs/heads/<source>` 单一 refspec；若使用 remote 名，先复核其解析结果仍与预检一致，不依赖隐式 `push.default` 或 `remote.<name>.push` 扩大范围。不强推、不推送目标默认分支。推送失败就停止，不能继续创建 PR/MR。

## 4. PR/MR 与合并

- 普通模式推送后询问是否创建 PR/MR、**目标分支**和仓库；用户不创建则到此结束。用户选择目标后核实远端目标存在、源分支不同，使用适用的已认证 GitHub/GitLab 能力创建请求；当前宿主不支持时报告阻塞，不为此安装 CLI。自动模式使用预检中核实的远端默认分支，**创建 PR/MR 后停止**。
- 创建前查找同仓同源同目标的开放 PR/MR：**已存在**时复用链接并核对当前 push 是否属于它，不创建重复请求；目标不一致或现有状态冲突时停止。标题和正文遵守目标仓库语言/模板要求，Summary、测试结果、未验证项、冲突和阻塞如实填写。当前仓库若要求中文则中文，精确技术标识符保留英文。
- 创建后读取宿主提供的 PR/MR 状态；在 Claude Desktop 有绑定状态工具时按宿主流程绑定并读取 CI，不自行轮询。自动模式报告链接、目标与当前检查状态，**不自动合并**。普通模式只有在用户询问或明确选择合并时，才核实当前检查、冲突、保护规则和目标；条件满足后再次取得**确认合并**授权，才执行平台 merge。检查未完成、失败、冲突或权限不足时停止并说明，不启用平台 auto-merge。

## 完成报告

分别列出规范初始化状态、review 发现及修复、项目新规则是否沉淀、实际执行的检查、提交 SHA、push 的远端/源分支、PR/MR 链接与目标，以及是否合并。每个未执行阶段和阻塞原因都写明；创建请求不等于已合并或 CI 通过。已有 CodeGraph 在源码写后按共享契约做一次 `post-write-sync`；它的派生索引不进入暂存范围。
