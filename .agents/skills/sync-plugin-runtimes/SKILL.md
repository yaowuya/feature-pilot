---
name: sync-plugin-runtimes
description: Use when the current FeaturePilot repository must be synchronized to its locally installed Claude Code and Codex plugin runtimes, including unchanged-version cache refresh or installation verification.
---

# Sync Plugin Runtimes

## Overview

这是当前仓库专用的本地同步流程，不是 FeaturePilot 插件能力。唯一执行入口是 `scripts/sync-plugin-runtimes.ps1`；它根据本机 marketplace 与安装元数据识别目标，同步 Codex 插件源，并验证 Claude Code、Codex 的实际 cache。

## When to use

在用户要求“把当前插件同步/更新到 Codex 和 Claude Code”、检查两端安装是否与当前源码一致，或遇到 same-version 更新显示 latest 但 cache 仍旧时使用。

不要用于发布远程 marketplace、修改版本号或同步其他仓库。

## Execute

从仓库根目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\skills\sync-plugin-runtimes\scripts\sync-plugin-runtimes.ps1
```

只验证、不写入：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\skills\sync-plugin-runtimes\scripts\sync-plugin-runtimes.ps1 -VerifyOnly
```

用户明确要求同步时，直接执行正常模式；不增加第二次业务确认。运行环境要求批准用户目录写入时，按工具权限流程申请。若 target identity 不唯一或不匹配，必须停止，不能猜测。

## Required behavior

- 先运行仓库插件校验，再读取两个插件清单；Claude 与 Codex 的插件名和基础版本必须一致。
- 从 marketplace 配置、Claude 安装元数据和 Codex cache 约定解析路径；禁止写死用户名、仓库绝对路径或按目录时间猜目标。
- 同步 Codex 源时排除 `.agents`、`.claude`、`.git` 和 `.worktrees`。不得把本项目 Skill 复制进插件源。
- Claude `plugin update` 后比较 SHA-256；same-version cache 不一致时，使用原 scope 执行 uninstall/install。
- Codex 只替换已验证插件源中由当前源码拥有的顶层条目，然后执行 remove/add 刷新 cache；不清理未被配置引用的目录。
- update/install 命令成功不是完成证据。源码、Codex 源、Codex cache、Claude cache 的核心文件哈希必须一致。
- 输出插件版本、解析出的路径和验证结论；最后提示重启 Claude Code，并在 Codex 中创建 new task 以加载最新 Skill。

## Completion contract

只有以下条件全部满足才能报告完成：

1. 仓库验证和 Claude 插件验证通过。
2. `.claude-plugin/plugin.json`、`.codex-plugin/plugin.json`、`commands/`、`skills/` 的 SHA-256 在四个位置完全一致。
3. 两端安装状态为 enabled，且 cache 路径来自当前配置和安装元数据。
4. 没有向 Codex 插件源复制 `.agents/`、`.claude/` 或 `.git/`。

## Common failures

| Symptom | Action |
| --- | --- |
| 同版本 update 显示 latest，但哈希不同 | 不提升版本；按脚本执行同版本重装 |
| marketplace 有多个同名候选 | 停止并报告候选，不选择最新目录 |
| 目标 manifest 与当前插件名不一致 | 停止，不覆盖或删除目标 |
| `-VerifyOnly` 发现任一哈希差异 | 报告具体差异，不声称已同步 |
| CLI 提示需要重启 | 完成校验后明确提示 restart/new task |
