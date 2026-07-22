# FeaturePilot CodeGraph 代码地图集成设计

**日期：** 2026-07-22
**状态：** 已确认，待实施
**范围：** `fp-init` 安装与建图、FeaturePilot 后续代码调查加速、失败回退与合同验证

## 1. 背景

FeaturePilot 当前依赖 `Glob → Grep → 局部读取 → 必要时整读` 的渐进式代码调查。该流程安全且证据边界明确，但每次解决问题或实现需求时都需要重新定位文件、符号和调用关系，在大型项目中耗时较长。

本设计引入 [colbymchenry/codegraph](https://github.com/colbymchenry/codegraph) 作为可选的本地代码地图。CodeGraph 在项目根目录生成 `.codegraph/` 索引，通过 MCP 或等价 CLI 提供符号、调用链、影响范围和相关源码上下文。FeaturePilot 使用它缩短候选定位过程，但不把图结果提升为当前代码事实或完成证据。

CodeGraph 官方把接入分为三个独立步骤：

1. 安装 CodeGraph CLI；
2. 可选配置 Claude Code、Codex 等 Agent 的 MCP；
3. 对每个项目执行 `codegraph init` 创建并构建 `.codegraph/`。

FeaturePilot 保留这三个边界，不把全局 Agent 配置和项目建图隐式绑定。

## 2. 已确认决策

1. 采用“共享 CodeGraph 契约 + `fp-init` 集成 + `fp-explore` 快速路径”的方案。
2. CodeGraph 是可选加速层，不是 FeaturePilot 强依赖。
3. 未安装 CodeGraph 时，`fp-init` 提供三种行为：自动安装、展示安装步骤、跳过。
4. 自动安装 CLI 后，必须单独询问是否配置检测到的 Claude Code/Codex MCP。
5. 选择自动安装即同时授权为当前项目执行首次建图。
6. CLI 已预装但当前项目没有 `.codegraph/` 时，`fp-init` 必须单独询问是否建图。
7. 每个 FeaturePilot 工作流第一次需要代码调查时，最多执行一次 CodeGraph 健康检查；发现待同步变化时最多执行一次增量同步。
8. 查询优先级固定为 MCP → CLI → 原有渐进式搜索。
9. 安装、配置、建图、同步或查询失败时，只报告一次精简原因并自动回退，不阻塞 FeaturePilot。
10. CodeGraph 结果只作为导航和候选证据；实际修改、精确契约和完成声明必须回到当前源码、测试及命令输出验证。

## 3. 目标

- 在 `/fp-init` 中以明确授权完成 CodeGraph CLI 检测、可选安装、可选 Agent MCP 配置和项目首次建图。
- 让后续 FeaturePilot 命令真正消费代码地图，而不是只生成未使用的索引。
- 对符号、调用链、影响范围和代码结构问题优先使用 CodeGraph，降低重复搜索和文件读取数量。
- 保持当前渐进读取预算、只读边界、源码验证和用户确认门禁。
- 支持 Windows、macOS 和 Linux，并在当前 shell 尚未刷新 `PATH` 时仍可完成首次建图。
- 对未安装、用户跳过、语言不支持、索引损坏和查询失败提供无阻塞回退。

## 4. 非目标

- 不把 CodeGraph 设为运行 FeaturePilot 的前置条件。
- 不内嵌或分叉 CodeGraph 实现。
- 不由 FeaturePilot 管理 CodeGraph 升级、卸载或发布版本生命周期。
- 不在 `fp-init` 之外静默创建项目代码图。
- 不把 `.codegraph/` 数据复制进 `fp-docs/intel/` 或 FeaturePilot 变更产物。
- 不用代码图替代精确字符串、配置、文档、生成文件、未支持语言或当前源码验证。
- 不未经许可修改目标项目 `.gitignore`、用户级 Agent 配置或已有 `fp-docs/manifest.md` 内容。

## 5. 架构

### 5.1 共享 CodeGraph 契约

新增 `skills/_shared/codegraph.md`，集中定义：

- CLI、项目索引和 MCP 能力检测；
- 跨平台安装命令与安装后可执行文件解析；
- `fp-init` 安装、Agent 配置和建图确认门禁；
- 单工作流健康检查与同步规则；
- MCP、CLI 和原有搜索的选择顺序；
- CodeGraph 查询结果的预算计数和源码复核要求；
- 错误、隐私、安全、回退和报告格式。

该文件是按需资源。`skills/_shared/workspace-rules.md` 只保留简短路由规则：需要安装、建图、状态检查或代码结构调查时才读取 CodeGraph 契约。同一 FeaturePilot 工作流只读取一次，不让所有 skills 固定承担完整 CodeGraph 上下文。

### 5.2 `fp-init` 接入层

`skills/fp-init/SKILL.md` 在定位目标项目根目录后、轻量 discovery 之前执行 CodeGraph 阶段。这样刚生成的代码图可以加速后续可选 intel discovery。

`fp-init` 负责：

- 检测 `codegraph --version`；
- 未安装时展示三种选择；
- 自动安装后验证可执行文件和版本；
- 单独确认是否配置 Agent MCP；
- 根据用户授权创建或复用项目代码图；
- 用 `codegraph status <project-root> --json` 验证代码图；
- 将 Code Map 状态写入新建 manifest，或在获准后更新已有 manifest；
- 在最终报告中说明 CLI、MCP、索引、回退和重启状态。

### 5.3 `fp-explore` 快速路径

`skills/fp-explore/SKILL.md` 在现有 Stage A 之前新增 Stage 0：

1. 判断目标是否适合代码图：符号定位、调用关系、结构、数据流、影响范围或相关源码候选。
2. 解析本工作流 CodeGraph 状态。
3. 优先调用当前会话暴露的 `codegraph_explore` MCP。
4. MCP 不可用而 CLI 与索引可用时，调用：

   ```text
   codegraph explore --path <project-root> --max-files <budget> <query>
   ```

5. 对关键路径和结论执行精确 Grep 或局部读取，从当前源码复核。
6. CodeGraph 不适合、不可用或证据不足时，进入原有 Stage A-D。

`fp-prd`、`fp-start` 和 `fp-quick` 已通过内部 profile 复用 `fp-explore`，因此自动获得快速路径。其他 FeaturePilot skills 通过共享 workspace contract 使用相同选择和回退规则。

### 5.4 Manifest Code Map 状态

`skills/fp-init/templates.md` 的 manifest 模板增加：

```markdown
## Code Map

| Provider | Status | Version | Index Path | Last Checked | Use As |
| --- | --- | --- | --- | --- | --- |
| CodeGraph | ready/skipped/failed/unavailable | <version or unavailable> | `.codegraph/` | <timestamp> | navigation-hint-only |
```

消费规则明确要求实时检测优先于 manifest 记录。该表只用于发现代码图，不证明索引当前健康或源码事实正确。

## 6. `fp-init` 状态机

### 6.1 检测 CLI

在目标项目根目录执行状态中立的版本检查：

```text
codegraph --version
```

成功则记录版本并进入 Agent 配置/建图判断。命令不存在或不可执行视为未安装。

### 6.2 未安装时的用户选择

`fp-init` 一次只询问一个决定，提供：

- **自动安装：** 展示来源、命令和影响，取得明确选择后执行；选择本项同时授权当前项目首次建图。
- **展示安装步骤：** 只展示适合当前操作系统的 CLI 安装、Agent MCP 配置和项目建图步骤，不执行任何命令；本轮继续普通 init。
- **跳过：** 不安装、不配置、不建图，继续普通 init。

Windows 官方安装命令：

```powershell
irm https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.ps1 | iex
```

macOS/Linux 官方安装命令：

```sh
curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh
```

联网下载和用户级安装仍须遵守宿主工具的权限/审批机制。不得把用户选择“展示步骤”或“跳过”解释为安装授权。

### 6.3 安装后解析可执行文件

安装成功不能只根据安装脚本退出码判断，必须重新执行版本检查。

- Windows 当前 shell 若尚未刷新 `PATH`，使用官方默认路径：

  ```text
  %LOCALAPPDATA%\codegraph\current\bin\codegraph.cmd
  ```

- macOS/Linux 若 `$HOME/.local/bin` 尚未进入 `PATH`，使用：

  ```text
  $HOME/.local/bin/codegraph
  ```

如果默认路径也不存在或版本检查失败，报告安装未验证，跳过 MCP 配置和建图并回退；不得宣称安装成功。

### 6.4 Agent MCP 分层确认

CLI 可用后，`fp-init` 单独询问是否让 CodeGraph 配置检测到的 Agent。获准后运行：

```text
codegraph install --target=auto --location=global --yes
```

该步骤可能修改 Claude Code/Codex 用户级 MCP 和 instructions 配置。跳过不会影响 CLI 查询。配置成功后提示用户重启相应 Agent；当前工作流继续使用 CLI，不等待 MCP 热加载。

### 6.5 首次建图

项目根目录不存在 `.codegraph/` 时：

- 本轮自动安装 CLI：直接执行首次建图，因为选择自动安装已包含该授权；
- CLI 原本已安装：询问是否构建；只有明确同意后执行；
- 用户展示步骤或跳过：不构建。

执行命令：

```text
codegraph init <project-root>
```

只允许目标项目根目录作为 path，不向上继承父目录索引。

### 6.6 复用已有代码图

存在 `.codegraph/` 时，执行：

```text
codegraph status <project-root> --json
```

- 健康且无待同步变更：直接复用；
- 报告待同步变更：本工作流执行一次 `codegraph sync <project-root> --quiet`，以同步命令的成功退出作为本轮刷新证据，不再次运行 `status`；
- 状态检查、同步或复查失败：标记 `failed`，继续普通 init。

目录存在本身不是成功证据。只有 `status --json` 成功且返回可用索引状态才记为 `ready`。

## 7. 后续工作流消费协议

### 7.1 工作流内状态

每个 FeaturePilot 工作流维护一个仅存在于当前上下文的状态：

- `unchecked`：尚未检查；
- `ready-mcp`：当前会话 MCP 可用且项目图健康；
- `ready-cli`：CLI 与项目图可用；
- `unavailable`：未安装、未建图、用户跳过或检查失败。

第一次需要代码调查时从 `unchecked` 解析一次，之后复用。不得在每个查询前重复运行 `status`。

### 7.2 健康检查和同步

解析顺序：

1. 查找目标项目根目录下的 `.codegraph/`；没有则记为 `unavailable`，建议后续运行 `/fp-init`，但继续当前工作流。
2. 如果当前会话提供 CodeGraph MCP，优先使用 MCP 状态能力；否则检查 CLI。
3. CLI 可用时执行一次 `codegraph status --json`。
4. 状态显示待同步变化时执行一次 `codegraph sync --quiet`；同步成功后继续使用，同一工作流不再次运行 `status`。
5. 任一步失败即记为 `unavailable`，本工作流不重复重试。

### 7.3 查询选择

适合 CodeGraph：

- 符号或实现位置；
- 调用方、被调用方和跨文件路径；
- 变更影响范围；
- 模块结构和相关源码候选；
- “X 如何到达 Y”类代码流问题。

直接使用原有搜索：

- 精确错误文本、配置 key、文档和 Markdown；
- 生成文件、二进制、数据样本和未支持语言；
- 文件是否存在、固定路径或 Git 状态；
- CodeGraph 结果已经指出路径后的精确复核。

### 7.4 预算与证据

CodeGraph 不能绕过 `fp-explore` 预算：

- 返回并进入调查的文件计入 `candidate paths`；
- 返回的每个相关源码片段按语义计入 `local read windows`；
- CLI 的 `--max-files` 不得超过当前 profile 的候选路径上限；`quick` 最高为 8；
- CodeGraph 查询计入一次 search/static inspection；
- 后续源码复核继续计入原有 Grep/Read 预算。

关键结论至少使用一次当前源码证据复核。CodeGraph 提供的调用关系可作为高价值导航，但启发式或动态边界必须明确标注，不得把它单独用作权限、安全、接口契约或完成结论。

## 8. 错误、安全与隐私

- 安装和 Agent 配置必须有独立、明确的用户授权。
- 不读取或传输 `.env`、凭据、客户数据和未授权敏感范围。
- CodeGraph 是本地索引，但是否索引特定源码仍受当前用户授权和项目边界约束。
- 安装失败不自动重试不同安装机制，不自动清理已有安装。
- 建图失败不自动执行 `codegraph uninit` 或删除 `.codegraph/`。
- MCP 配置成功但当前会话未暴露工具时，使用 CLI 并报告需要重启。
- `.codegraph/` 若可能被 Git 跟踪，只警告用户；不得未经批准修改 `.gitignore`。
- 一个工作流只报告一次 CodeGraph 降级原因，避免重复噪声。
- fallback 后不得降低现有渐进读取、预算、外部研究和只读安全规则。

## 9. 预期文件改动

### 9.1 新增

- `skills/_shared/codegraph.md`：完整共享合同。
- `scripts/test-codegraph-contract.ps1`：CodeGraph 静态合同与防退化测试。

### 9.2 修改

- `skills/_shared/workspace-rules.md`：加入按需 CodeGraph 路由。
- `skills/fp-init/SKILL.md`：加入分层安装、MCP 配置、建图和报告流程。
- `skills/fp-init/templates.md`：manifest Code Map 区域。
- `commands/fp-init.md`：补充 CodeGraph gate checksum。
- `skills/fp-explore/SKILL.md`：加入 Stage 0 和预算映射。
- `scripts/test-explore-contract.ps1`：验证快速路径不绕过现有合同。
- `scripts/validate-plugin.ps1`：验证共享资源、引用、文档和能力锚点。
- `AGENTS.md`、`CLAUDE.md`、`README.md`：公共行为和消费规则。
- `docs/user_guide/init-prd-start.md`：用户安装、跳过、建图和重启说明。

实施时如果当前文件结构证明某个文档无需修改，可以保留不动，但不得省略用户可见行为和两端运行时合同。

## 10. 测试设计

### 10.1 CodeGraph 合同测试

`scripts/test-codegraph-contract.ps1` 必须验证：

1. 共享合同存在，并被 `fp-init`、`fp-explore` 和 workspace contract 正确路由；
2. 未安装时存在自动安装、展示步骤和跳过三条互斥路径；
3. Windows 与 macOS/Linux 官方安装命令和安装后默认绝对路径存在；
4. 自动安装与 Agent MCP 配置采用分层确认；
5. 自动安装授权包含首次建图，预装 CLI 的首次建图需要确认；
6. 建图成功必须由 `status --json` 验证；
7. 每个工作流最多一次状态检查和一次必要同步；同步后不得再次运行状态检查；
8. 查询顺序为 MCP → CLI → 原有搜索；
9. CodeGraph 失败不阻塞 FeaturePilot；
10. 图结果是 `navigation-hint-only`，关键结论必须复核当前源码；
11. 现有 manifest 覆盖规则、敏感数据规则和项目根目录边界未减弱。

### 10.2 防退化负例

测试必须拒绝与以下含义等价的合同：

- CodeGraph 是运行 FeaturePilot 的强依赖；
- 未确认即安装、配置 Agent 或为预装 CLI 项目建图；
- 用户选择展示步骤或跳过后仍执行安装；
- 仅凭 `.codegraph/` 存在即宣称索引健康；
- 每次查询都执行 `status` 或 `sync`；
- CodeGraph 失败后阻塞工作流或无限重试；
- CodeGraph 返回内容不计入探索预算；
- 图结果可以替代当前源码、测试或命令输出；
- 未经批准修改 `.gitignore` 或删除索引。

### 10.3 回归与完整验证

实施完成后运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-codegraph-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-explore-contract.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\measure-context.ps1
claude plugin validate .
git diff --check
```

如果本机 CodeGraph 可用，可以额外在临时 fixture 中验证 `init → status → explore`，但该可选集成检查不能成为插件合同测试在无 CodeGraph 环境中的前置条件。

## 11. 完成标准

只有以下条件全部满足才算完成：

- `/fp-init` 能检测 CodeGraph，并在未安装时提供自动安装、展示步骤和跳过；
- 自动安装后能在当前 shell 未刷新 PATH 的情况下解析官方默认可执行路径；
- Agent MCP 配置有独立确认，跳过后 CLI 仍可工作；
- 用户授权后能构建项目代码图，并以 `status --json` 验证；
- 已有图能被复用，并按每工作流一次规则处理同步；
- 后续 FeaturePilot 代码调查按 MCP → CLI → 原有搜索使用代码图；
- `fp-explore` 预算、源码复核和只读边界保持有效；
- 任一 CodeGraph 故障都能无阻塞回退；
- 用户文档、Claude Code 与 Codex 合同一致；
- focused tests、完整插件验证、上下文测量、Claude 插件验证和 diff 检查全部通过。

## 12. 参考资料

- [CodeGraph GitHub README](https://github.com/colbymchenry/codegraph)
- [CodeGraph CLI Reference](https://colbymchenry.github.io/codegraph/reference/cli/)
- [CodeGraph MCP Server](https://colbymchenry.github.io/codegraph/reference/mcp-server/)
- [CodeGraph Integrations](https://colbymchenry.github.io/codegraph/reference/integrations/)
- [Windows installer](https://github.com/colbymchenry/codegraph/blob/main/install.ps1)
- [macOS/Linux installer](https://github.com/colbymchenry/codegraph/blob/main/install.sh)
