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
