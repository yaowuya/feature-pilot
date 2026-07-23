# CodeGraph 可选代码地图契约

仅在当前任务需要代码定位、符号关系、调用链、数据流、影响范围或相关源码候选时按需读取本文件。CodeGraph 是 FeaturePilot 的可选本地导航层，不是运行前置条件，不负责证明当前实现或完成状态。

## 不变量

- 查询顺序固定为 `MCP -> CLI -> native search`，面向用户说明时表述为 `MCP → CLI → 原有搜索`。
- 所有图结果均为 `navigation-hint-only`；实际修改、精确契约和完成声明必须用当前源码、测试或命令输出复核。
- 每个 FeaturePilot 工作流在首次查询前 `at most one status check`；发现待同步变化时最多执行一次 `pre-query sync`，并且 `do not run status again after sync`。
- 任何源码写入都会把本工作流图状态改为 `dirty-after-write`；此后 `never query a dirty graph`，只能使用当前源码搜索，直到安全的结束同步完成。
- 代码修改流程在返回用户前可以执行 `at most one post-write sync`；该同步与查询前同步分开计数，且 `post-write sync must not block completion`。
- 任一检测、安装、配置、建图、同步或查询故障都 `must not block FeaturePilot`，只报告一次精简原因并回退。
- npm 不可用时 `must not auto-install Node.js`，也不得静默切换安装机制。

## CLI 检测和 npm-only 安装

先运行 `codegraph --version`。命令不可用时，如果 npm 可用，可以运行 `npm prefix -g` 检查已经安装但当前 `PATH` 尚未刷新的全局 launcher：

- Windows：`<npm-global-prefix>\codegraph.cmd`
- macOS/Linux：`<npm-global-prefix>/bin/codegraph`

只有 `fp-init` 可以在用户明确选择“自动安装”后安装 CodeGraph。执行前必须展示包名、全局安装影响和唯一允许的安装命令：

```text
npm install -g @colbymchenry/codegraph@latest
```

安装方式约束：

- `forbid: irm`
- `forbid: curl`
- `forbid: install.ps1`
- `forbid: install.sh`
- `forbid: npx`

自动安装前运行 `npm --version`。如果失败，不安装 Node.js，不尝试其他 CodeGraph 安装方式；说明 Node.js/npm 前置条件，展示上述 npm 命令和后续步骤，然后继续普通 FeaturePilot 流程或按用户选择跳过。

安装完成后再次验证版本。先尝试正常的 `codegraph --version`；当前进程尚未刷新 `PATH` 时，运行 `npm prefix -g` 并使用对应平台 launcher 验证。两种方式都失败时不得宣称安装成功，也不得继续 MCP 配置或建图。

联网下载、npm 全局写入和用户级配置仍须通过宿主环境的权限或审批机制。用户选择“展示安装步骤”或“跳过”不构成任何命令执行授权。

## fp-init 授权状态机

CLI 不可用时，一次只询问一个决定：

1. **自动安装（推荐）**：说明 npm 全局安装影响并执行唯一允许的 npm 命令；该选择同时授权为当前项目执行首次建图。
2. **展示安装步骤**：只展示 npm 前置条件、CLI 安装、可选 MCP 配置和项目建图命令，本轮不执行。
3. **跳过**：不安装、不配置、不建图，继续普通 init。

CLI 可用后，Agent MCP 配置使用独立确认门：

```text
codegraph install --target=auto --location=global --yes
```

该命令可能修改 Claude Code、Codex 等 Agent 的用户级 MCP 或 instructions 配置。只有明确确认后才执行；成功后提示重启相应 Agent。当前工作流不等待 MCP 热加载，继续使用 CLI。跳过 MCP 不影响 CLI 查询或建图。

目标项目根目录没有 `.codegraph/` 时：

- 本轮自动安装成功：自动安装选择已经授权首次建图，执行 `codegraph init <project-root>`。
- CLI 原本已安装：单独询问是否构建，明确同意后才执行 `codegraph init <project-root>`。
- 展示步骤或跳过：不构建。

不得在 `fp-init` 之外静默创建项目代码图。

## 项目图健康检查和工作流状态

`.codegraph/` 必须位于当前目标项目根目录；不得向上查找或复用父目录索引。目录存在本身不是健康证据。

首次建图完成或发现已有项目图时，用以下命令验证：

```text
codegraph status <project-root> --json
```

后续每个 FeaturePilot 工作流维护只存在于当前上下文的状态：

- `unchecked`：本工作流尚未检查。
- `ready-mcp`：当前会话的 MCP 查询能力可用且项目图可用。
- `ready-cli`：CLI 与项目图可用。
- `dirty-after-write`：本工作流已经写入源码，先前的图快照已失效，禁止继续查询。
- `unavailable`：未安装、未建图、用户跳过、语言不支持或检查失败。

第一次需要代码图时才解析状态。当前会话暴露 CodeGraph MCP 健康能力时优先使用；否则 CLI 可用时执行一次 `codegraph status <project-root> --json`。状态显示待同步变化时最多执行一次：

```text
codegraph sync <project-root> --quiet
```

查询前同步命令成功退出就是本轮刷新证据，不再次运行 `status`。任一步失败即记为 `unavailable`，同一工作流不重试查询前检查。

## 查询路由和预算

适合代码图的问题包括符号定位、调用关系、结构、数据流、影响范围和相关源码候选。精确字符串、非代码配置、生成文件、未支持语言或图无法回答的问题直接使用原有搜索。

当前会话暴露 `codegraph_explore` 时优先调用 MCP。MCP 不可用而 CLI 与健康项目图可用时调用：

```text
codegraph explore --path <project-root> --max-files <budget> <query>
```

`<budget>` 不得超过当前探索 profile 剩余的候选路径预算。CodeGraph 返回的路径计入 `candidate paths`，有界源码摘录计入 `local read windows`，整文件内容计入 `unbounded application-file reads`。不得通过 CodeGraph 绕过 distinct-file、搜索、读取窗口或 quick `8 / 8 / 1` 上限。

只保留与目标最相关的候选并回到当前源码小范围复核。CodeGraph 不充分或不可用时立即回退到 `Glob → Grep → ranged Read`，不降低原有只读、敏感数据、外部研究和授权边界。

### Review candidate-only contract

在 `fp-review` 或 SDD final review 中，任何 CodeGraph `explore`、`impact`、`affected` helper/query 都只返回 candidate paths/symbols，不是 finding、scope、absence、fix 或完成证据。每个采用的 candidate 必须回到 current source 和 current diff，并至少使用 native search（caller/import/reference）、tests 或 command output 之一复核；报告同时记录 query、candidate、current-source verification 与原生证据。

图缺失、stale、dirty-after-write、MCP/CLI unavailable 或结果不充分时，立即 `fallback to native search against current source`。CodeGraph failure must not block FeaturePilot review；只有原生当前证据本身缺失时才按 review 风险影响 verdict。不得用 `explore`、`impact` 或 `affected` 绕过 working-tree snapshot、scope matrix、artifact ownership、evidence freshness 或 command-safety gate。

## 源码写入后的失效和结束同步

任一 FeaturePilot 流程首次创建、修改、移动或删除源码、测试、配置、schema 或生成器输入后，立即把当前图状态设为 `dirty-after-write`。从该时刻起 `never query a dirty graph`：不得继续调用 `codegraph_explore` 或 `codegraph explore`，也不得引用写入前的图结果证明写入后的事实；剩余调查使用原有当前源码搜索。

如果目标项目在本工作流开始写入前已经有 `.codegraph/`，代码修改流程在每次用户可见的终止返回前执行一次 `post-write-sync`：

```text
codegraph sync <project-root> --quiet
```

规则如下：

- 每次工作流返回前 `at most one post-write sync`，无论此前是否执行过一次 `pre-query sync`。
- 不在结束同步后再次运行 `status`，以同步命令成功退出作为当前工作树的刷新证据。
- 结束同步成功后状态可记为 `ready-cli`，但本轮不再查询；下一工作流仍按正常健康检查处理外部变化。
- CLI、索引或同步不可用时只记录一次降级原因；`post-write sync must not block completion`、任务状态更新、验证、审查或用户汇报。
- 工作流开始时没有 `.codegraph/`，或用户此前跳过建图时，不得在执行结束时隐式运行 `init`。
- `.codegraph/` 被 Git 跟踪时只警告，不把索引变化混入业务提交或 FeaturePilot 产物。

## Manifest、Git 和报告

`fp-docs/manifest.md` 的 Code Map 记录仅用于发现，实时检测优先于历史记录。创建 manifest 时可以写入当前检测结果；更新已有 manifest 仍遵守“不经确认不覆盖”。不得把 `.codegraph/` 内容复制到 `fp-docs/intel/` 或变更产物。

若 `.codegraph/` 可能被 Git 跟踪，只警告用户；不得未经批准修改 `.gitignore`。建图失败不得自动执行 `codegraph uninit`、删除或重建索引。

最终报告只说明本轮实际验证的 CLI 版本、MCP 配置与重启状态、索引状态、是否执行同步、回退原因和 manifest 更新状态。未运行的步骤标记为未执行，不得根据目录存在或安装命令退出就推断全部能力可用。
