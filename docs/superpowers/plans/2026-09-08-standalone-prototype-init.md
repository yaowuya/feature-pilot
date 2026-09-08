# 独立原型初始化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 新增 /fp-prototype-init，允许已有项目只建立/复用/刷新原型基座。

**Architecture:** 将基座执行所有权从 fp-init 的内联阶段交给新技能；fp-init 调用它，fp-prd 缺基座时指向它。共享 prototype-contract 仍是产物/审批/验证的唯一契约；仅允许按批准更新已有主 manifest 的 Prototype Bases 小节。

**Tech Stack:** Markdown skills/commands、PowerShell 契约与产物测试。

**Status:** 已完成并同步 Claude Code 的 fp@fp-dev（user scope，版本 1.0.0）；-ClaudeOnly -VerifyOnly 复核清单/commands/skills/scripts 的 SHA-256 一致且 enabled，未更新 Codex/DSH，未提交/推送。

**验证记录（2026-09-08）：**

- 新增入口的测试先因缺少 SKILL.md 失败，再实现并通过。
- 完整插件校验通过：13 commands、23 skills，全部 SKILL.md 不超过 500 行。
- 29 个原型产物用例及 79/79 既有产物 fixture 通过；git diff --check 通过。
- 独立只读回放已有信息层、无主 manifest、fresh 仅缺索引、只有 CodeGraph 许可四种情形，未见重跑 init、越权或重复构建问题。
- 修正全局校验要求的资源锚定标记，并将新技能登记为无自动 ELI5 JIT 集成；既有真实 E2E 与信息层门禁保持。
- 本轮为技能/契约和回放验证，没有运行真实消费者前端构建或视觉对照；当前会话需重启以加载新入口。

## Global Constraints

- 不改变 fp-prototype/v1、PRD 六章/四小节、mock-only、真实 E2E 零 Mock。
- 新技能不执行完整 fp-init、不初始化 CodeGraph/MCP、不创建主 manifest/settings/intel。
- 主 manifest 缺失不阻塞独立基座；已有主 manifest 只允许精确批准的 Prototype Bases diff。
- 保留所有现有未提交修改，不提交/推送；不改其它运行时。

## Task 1: 独立入口及回归

Files: `skills/fp-prototype-init/SKILL.md`、`commands/fp-prototype-init.md`、`scripts/test-prototype-contract.ps1`、`scripts/test-agents-router-contract.ps1`。

- [x] 扩展现有测试：新 skill/command 必须存在，约束 no-full-init、no-manifest-required、manifest-section-only、fresh-reuse、调用方返回及独立审批。
- [x] 执行测试，确认缺少新文件的 RED。
- [x] 实现新技能的有界检测、目标身份、fresh/stale/人工冲突判断、精确审批、共享构建流程和输出；薄 command 只转交参数。

```powershell
$prototypeInit = Read-Utf8 'skills/fp-prototype-init/SKILL.md'
Assert-Contains $prototypeInit @('no-full-init', 'no-manifest-required', 'manifest-section-only', 'fresh-reuse', 'approved-prototype-provisioning') 'standalone prototype init'
```

## Task 2: 委托与所有权

Files: `skills/fp-init/SKILL.md`、`templates.md`、`skills/fp-prd/SKILL.md`、`skills/fp-frontend-spec/SKILL.md`、`skills/_shared/prototype-contract.md`、`workspace-rules.md`、`ui-e2e-contract.md`、`scripts/test-ui-e2e-contract.ps1`、`commands/fp-init.md`。

- [x] fp-init Stage 7a 改为原生 Skill 调用，只传递已确认事实/精确scope，不保留第二份初始化流程。
- [x] 新技能拥有项目基座和窄范围既有索引更新；fp-prd 仍只拥有 change，过期基座转新命令。
- [x] 更新 UI/E2E 的原型所有者名称及封闭规范行，保持反绕过断言。

## Task 3: 可发现性、验证与交付

Files: `AGENTS.md`、`scripts/validate-plugin.ps1`、`docs/reference/commands-and-skills.md`、`docs/reference/architecture-and-artifacts.md`、`docs/user_guide/init-prd-start.md`。

- [x] 注册意图路由、新 skill capability anchors 与用户命令示例；清理当前文档中的旧基座owner，不改历史设计记录。
- [x] 跑完整插件校验和原型/既有产物回归，独立回放已有manifest、无manifest、no-frontend与fp-init委托场景。
- [x] 记录实际通过项及未进行的真实前端构建/视觉实测；按已选 Claude-only 本地开发安装范围刷新并核对哈希，不更新其它端。

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
```

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-artifact-layout.ps1
```

```bash
git diff --check
```
