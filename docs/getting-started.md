# 开始使用 FeaturePilot

FeaturePilot 在 Claude Code、Codex 与 DeepSeek Harness 中共享同一套 `skills/`。选择一个运行时完成安装，然后从新会话开始你的第一条开发流程。

## 先选你的运行时

| 运行时 | 加载方式 | 更新后如何生效 |
|---|---|---|
| Claude Code | Claude plugin marketplace | 重启 Claude Code |
| Codex | personal plugin source/cache | 创建 new task |
| DeepSeek Harness | `~/.dsh/skills` 或 `$DSH_HOME/skills` | 新会话自动加载，无需重启 |

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

## 可选 CodeGraph

CodeGraph 是代码定位和影响分析的可选导航层，不是 FeaturePilot 前置依赖。`fp-init` 未检测到 CLI 时会提供自动安装、展示步骤或跳过；对应当前 CLI 状态只询问一个决定，一次批准覆盖所选路径中的全局安装、可选用户级 Agent MCP 配置和当前项目首次建图，并按顺序逐步汇报。唯一允许的自动安装命令是：

```text
npm install -g @colbymchenry/codegraph@latest
```

FeaturePilot 不使用 `irm`、`curl`、远程安装脚本或 `npx` 安装 CodeGraph，也不会在缺少 npm 时自动安装 Node.js。CLI 已安装时，MCP 配置与尚缺的首次建图仍合并为一次确认；Agent MCP 配置会修改用户级配置，因此会在选项中明确说明。CodeGraph 的查询与写后新鲜度见 [架构与产物参考](reference/architecture-and-artifacts.md)。

## 一次同步三端

在维护 FeaturePilot 仓库时，使用同一脚本更新 Claude Code、Codex 和 DeepSeek Harness，并逐文件比较 SHA-256：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\skills\sync-plugin-runtimes\scripts\sync-plugin-runtimes.ps1
```

只检查当前安装，不写入任何 runtime：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\skills\sync-plugin-runtimes\scripts\sync-plugin-runtimes.ps1 -VerifyOnly
```

同步完成后：重启 Claude Code、在 Codex 创建 new task；DSH 直接开始新会话。

## 验证仓库插件

修改命令、skill 或文档契约后，运行仓库验证：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\validate-plugin.ps1
```

## 下一步

- 返回 [项目首页](../README.md)
- 阅读 [完整使用主线](user_guide/init-prd-start.md)
- 阅读 [1.0.0 release notes](release_notes/1.0.0.md)
