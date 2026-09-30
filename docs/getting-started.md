# 开始使用 FeaturePilot

FeaturePilot 在 Claude Code、Codex、DeepSeek Harness 与 Cursor 中共享同一套 `skills/`。选择一个运行时完成安装，然后按对应的重启或新建会话要求开始使用。

## 文档怎么读

[项目首页](../README.md) 介绍使用场景；本文负责安装、更新和维护。专业内容按需查阅，不必从头读完：

| 你要解决的问题 | 对应文档 |
|---|---|
| 应该选哪个命令，普通执行与 SDD 有什么区别？ | [命令与技能参考](reference/commands-and-skills.md) |
| 配置放哪里，文档如何拆分，验证需要什么证据？ | [架构与产物参考](reference/architecture-and-artifacts.md) |
| 第一次如何从需求走到交付？ | [初始化、PRD 与完整开发主线](user_guide/init-prd-start.md) |
| 如何补测或审查大型模块？ | [覆盖率指南](user_guide/fp-coverage.md) / [模块审查指南](user_guide/fp-module-review.md) |

## 先选你的运行时

| 运行时 | 加载方式 | 更新后如何生效 |
|---|---|---|
| Claude Code | Claude plugin marketplace | 重启 Claude Code |
| Codex | personal plugin source/cache | 创建 new task |
| DeepSeek Harness | `~/.dsh/skills` 或 `$DSH_HOME/skills` | 新会话自动加载，无需重启 |
| Cursor | `.cursor-plugin/plugin.json` 加载共享 skills；本地目录或 CLI `--plugin-dir` | IDE reload 后检查 Customize；CLI 新建会话 |

## Claude Code

将当前仓库作为开发插件市场添加，再安装 FeaturePilot：

```text
/plugin marketplace add <path-to-feature-pilot>
/plugin install fp@fp-dev
```

重启 Claude Code 后，从最小工作区开始：

```text
/fp-init
```

然后按当前需要选择入口：

```text
/fp-explore 当前审批流的入口和权限边界是什么
/fp-prd 我想做一个批量审批体验优化
/fp-start <prd-slug 或 功能描述>
```

## Codex

Codex 从同一仓库的 `skills/` 加载 FeaturePilot。本地开发时，把插件源同步到 `~/plugins/fp`，确认 `~/.agents/plugins/marketplace.json` 包含 `fp` 的本地条目，然后执行：

```text
codex plugin add fp@personal
```

`/fp-*` 是 FeaturePilot 工作流标签。完成安装或更新后创建 **new task**，再要求 Codex 使用 `fp:fp-prd`、`fp:fp-start` 或其他对应 skill。

## DeepSeek Harness

DeepSeek Harness 不使用 plugin marketplace；它扫描用户技能根。运行同步脚本会把仓库中 `skills/` 的 `fp-*` 和 `_shared/` 同步到 `~/.dsh/skills`，若设置了 `$DSH_HOME` 则使用 `$DSH_HOME/skills`：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\skills\sync-plugin-runtimes\scripts\sync-plugin-runtimes.ps1
```

DSH 通过 Chokidar 监听技能根。同步后新开会话即可加载，无需重启。

## Cursor

Cursor 使用仓库的 `.cursor-plugin/plugin.json`，直接发现同一套 `skills/`，并加载 `adapters/cursor/rules/` 中的路径适配规则。manifest 显式设置 `commands: []`，不发现面向 Claude Code 的 `commands/`，避免同名入口重复加载。输入 `/` 选择 `fp-init`、`fp-quick` 等原生 skill，或直接说“使用 fp-quick 完成这个修改”。这遵循 Cursor 的 [组件发现规则](https://cursor.com/docs/reference/plugins#cursor-plugin-component-discovery) 与 [skill 调用方式](https://cursor.com/docs/skills#how-skills-work)。

### 本地安装与更新

在 FeaturePilot 仓库根目录使用 Windows PowerShell 5.1 或 `pwsh` 运行独立安装脚本；无需先安装或配置 Claude Code、Codex、DeepSeek Harness：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-cursor-plugin.ps1
```

脚本把受管插件文件复制到 `~/.cursor/plugins/local/fp/`，并逐文件校验 SHA-256；更新时重复运行即可。它会保护已有非托管内容和手动修改的受管文件，发现冲突时报告并停止，不直接覆盖。仅核对安装文件、不写入时运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\install-cursor-plugin.ps1 -VerifyOnly
```

| 参数 | 用途 |
|---|---|
| `-CursorHome <path>` | 指定 Cursor 配置根目录；安装位置为该目录下的 `plugins/local/fp` |
| `-PluginRoot <path>` | 指定 FeaturePilot 源码根目录，默认使用脚本所属仓库 |
| `-VerifyOnly` | 只比较受管安装文件与源码，不执行安装或更新 |

使用 `pwsh` 时只需替换上述命令中的 `powershell`。插件文件采用目录复制；Cursor 官方说明指向本地插件目录之外的 symlink 会被跳过，不要改成链接到外部源码仓库。[Cursor 本地测试说明](https://cursor.com/docs/plugins#test-plugins-locally)

安装或更新后，重启 Cursor，或执行 **Developer: Reload Window**。在 **Customize** 中检查 FeaturePilot 的 skills 和路径适配 rule，再用一个只读 `fp-explore` 请求确认能读取已安装插件内的共享契约。文件校验通过只证明安装内容一致，不能代替实际 IDE 加载和工作流验证。

同名 marketplace 插件已安装时，Cursor 会优先使用它；本地副本的更新可能不会成为当前加载版本。Teams/Enterprise 的 **Allow Local Plugin Imports** 也可能阻止本地加载，需按组织设置处理。[官方加载限制](https://cursor.com/docs/plugins#test-plugins-locally)

### CLI 与仓库导入

已安装支持该参数的 Cursor CLI 时，可以直接加载仓库绝对路径，无需先复制到本地插件目录：

```powershell
agent --plugin-dir "D:\01-code\feature-pilot"
```

把路径替换为自己的 checkout。CLI 启动后同样需核对 skill 发现与共享契约读取；`agent --plugin-dir` 是官方支持的本地加载方式，不是 marketplace 安装命令。[CLI 参数参考](https://cursor.com/docs/cli/reference/parameters)

仓库还提供 `.cursor-plugin/marketplace.json`，其中单个 `source: "."` 条目指向根插件，可用于 Cursor 的 **From GitHub Repository** 导入。导入前需把这些文件推送到所选远程版本；未推送的本地改动不会出现在 GitHub 导入中。此配置不代表 FeaturePilot 已在 Cursor 官方市场上架，是否能导入仍需实际验证。[仓库导入说明](https://cursor.com/docs/skills#installing-skills-from-a-repository)

## 可选 CodeGraph

CodeGraph 是代码定位和影响分析的可选导航层，不是 FeaturePilot 前置依赖。`fp-init` 未检测到 CLI 时会提供自动安装、展示步骤或跳过；对应当前 CLI 状态只询问一个决定，一次批准覆盖所选路径中的全局安装、可选用户级 Agent MCP 配置和当前项目首次建图，并按顺序逐步汇报。唯一允许的自动安装命令是：

```text
npm install -g @colbymchenry/codegraph@latest
```

FeaturePilot 不使用 `irm`、`curl`、远程安装脚本或 `npx` 安装 CodeGraph，也不会在缺少 npm 时自动安装 Node.js。CLI 已安装时，MCP 配置与尚缺的首次建图仍合并为一次确认；Agent MCP 配置会修改用户级配置，因此会在选项中明确说明。CodeGraph 的查询与写后新鲜度见 [架构与产物参考](reference/architecture-and-artifacts.md)。

## 维护时选择同步范围

在维护 FeaturePilot 仓库时，原同步脚本默认仍更新 Claude Code、Codex 和 DeepSeek Harness，并逐文件比较 SHA-256；默认范围不包含 Cursor：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\skills\sync-plugin-runtimes\scripts\sync-plugin-runtimes.ps1
```

只检查当前安装，不写入任何 runtime：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\skills\sync-plugin-runtimes\scripts\sync-plugin-runtimes.ps1 -VerifyOnly
```

同步完成后：重启 Claude Code、在 Codex 创建 new task；DSH 直接开始新会话。

仅同步 Cursor 时可用同一 wrapper 的 `-CursorOnly`，它委托上面的独立安装脚本；加上 `-VerifyOnly` 则只检查 Cursor：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\skills\sync-plugin-runtimes\scripts\sync-plugin-runtimes.ps1 -CursorOnly
```

`-CursorOnly` 与 `-ClaudeOnly` 互斥；后者只更新 Claude Code。Cursor 的独立安装不依赖该维护 wrapper，安装后仍需按上文执行 IDE/CLI 加载检查。

## 验证仓库插件

本节面向 FeaturePilot 维护者。在 **FeaturePilot 仓库根目录**运行以下命令，而不是在使用插件的业务项目里运行。

只检查 README 与配套文档的入口、结构和本地链接：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-readme-docs-contract.ps1
```

修改命令、skill 或文档契约后，再运行完整仓库验证（已包含上面的文档检查）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
```

仓库中的 `skills/` 是运行时事实源；README 和 `docs/` 是帮助读者理解、选择和上手的说明层。专业规则应链接到对应契约，避免在多个地方复制维护。

文档检查能发现入口遗漏、结构变化和本地文件链接失效，不替代对内容准确性、页面渲染或真实运行效果的核对。

## 下一步

- 返回 [项目首页](../README.md)
- 阅读 [完整使用主线](user_guide/init-prd-start.md)
- 阅读 [1.0.0 release notes](release_notes/1.0.0.md)
