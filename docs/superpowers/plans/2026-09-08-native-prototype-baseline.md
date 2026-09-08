# 原生前端原型基座 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** fp-init 为已确认的 Web 前端建立同技术栈、独立运行、mock-only 的可编辑基座；fp-prd 在 change 内增量生成源码和静态预览，无前端跳过初始化。

**Architecture:** 在现有 Markdown 技能体系内增加唯一 prototype-contract，分离 PRD 顺序模式和原型渲染模式。基座与 change 都携带 fp-prototype/v1 元数据；独立 PowerShell 校验器只校验结构/路径及可选新鲜度，不执行 manifest 命令、不把静态通过当运行通过。

**Tech Stack:** Markdown skills、JSON manifest、PowerShell 5.1 兼容校验与 fixture 测试；消费者沿用实际 Vue/React 等框架，不在插件仓库搭建虚构业务前端。

**Status:** 插件工作流、产物校验及回归已完成；完整插件校验与 79/79 既有产物 fixture 通过，新原型 fixture 为 29 cases。独立审查问题已逐项复现并修复；行为回放和未实测项见 [验证记录](2026-09-08-native-prototype-validation.md)。真实消费者框架构建与保真试点未执行。

## Global Constraints

- 用户已确认原生框架独立运行、全 mock 方案；本轮自主实施，不提交、不推送、不同步已安装插件缓存。
- 保留现有未提交的 PRD business-first 修改与 manifest-only default、settings 逐文件批准、真实 E2E 零 mock。
- 新 `project-native` 使用 `prototype/manifest.json`；旧 `standalone-html` 使用 `prototype.html`；同一 change 禁止双权威。
- 项目级基座只能由 fp-init 按独立批准写入；fp-prd 只写当前 change，不修改生产入口、共享基座或人工 settings。
- 无 CodeGraph 索引，不创建、不查询、不同步图。

## Task 1: 定义并验证原型产物

**Files:** 新增 `skills/_shared/prototype-contract.md`、`scripts/validate-prototype.ps1`、`scripts/test-prototype-artifacts.ps1`、`scripts/test-prototype-contract.ps1`。

**Interfaces:** 校验器参数为 `-ProjectRoot <root> -PrototypePath <repo-relative manifest.json or prototype.html> [-CheckFreshness]`。fp-prototype/v1 字段为 schema、kind、mode、appId、appRoot、framework(name/version)、sourceEntry、mockEntry、previewEntry、commands(build/preview 各含 relativeTo/cwd/run)、sources(path/sha256)、ownedFiles(path/sha256)、baseReference(null 或 path/sha256)、dataMode、networkPolicy、scenarios、verification。

- [x] 先写 fixture 和静态契约测试，运行并确认因缺少 prototype-contract/validator 而失败。
- [x] 实现 native/legacy 互斥、路径边界、必需文件、声明字段校验；CheckFreshness 对 sources/ownedFiles/baseReference 实算 SHA256。
- [x] 校验器不执行 commands；默认结构校验不宣称构建、隔离、视觉已验证，也不要求归档原型的旧源项目仍存在。
- [x] fixture 覆盖：有效base/change/legacy、dual mode、缺入口、错误schema、目录穿越、symlink/reparse-point、失效源指纹、人工修改、base版本变化、静态归档与命令不执行。

静态门禁以可检查的稳定标记约束分支，例如：

```powershell
Assert-Contains $contract @('project-native', 'standalone-html', 'mock-only', 'no-frontend', 'baseReference', 'CheckFreshness') 'prototype contract'
Assert-Condition (-not $prd.Contains('- Single-file HTML/CSS/JS.')) 'PRD still forces single HTML globally'
```

验证命令：

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-prototype-artifacts.ps1
```

预期：fixture 全通过；缺文件/路径逃逸/旧指纹为预期失败。

## Task 2: 接入 init 与 PRD

**Files:** 修改 `skills/fp-init/SKILL.md`、`templates.md`、`skills/fp-prd/SKILL.md`、`prd-template.md`、`skills/fp-prd-grill-me/SKILL.md`、`commands/fp-init.md`、`commands/fp-prd.md`。

**Interfaces:** init 在原 settings 阶段前有界识别 frontend；新增批准的 prototype provisioning，不借用 discovery/CodeGraph 授权。PRD 独立选择 rendering mode，消费已确认app的基座、验证新鲜度并生成change源码及preview。

- [x] 明确 no-frontend 跳过原型选项、文件、安装；SSR/模板/多应用/unknown 不伪装成无前端。
- [x] 添加基座读取条件与一次明示的新增文件/命令/cwd/依赖/配置批准，保留其它各自门禁。
- [x] 同框架真实组件/样式/providers复用，mock启动早于应用模块，检查构建期及浏览器期网络，localhost静态预览。
- [x] 将原型步骤改为解析后路径，不把 prototype.html 硬编码为唯一输出；已存在legacy保留，迁移单独批准。
- [x] 保留六章和四个功能小节，在原型小节增加模式/源码/入口/基座/场景信息。

验证命令：

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-prd-business-contract.ps1
```

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-init-information-layer-contract.ps1
```

预期：原有业务门禁与信息层门禁不回退。

## Task 3: 消费者、文档与整体验证

**Files:** 修改 `skills/_shared/workspace-rules.md`、`artifact-layout.md`、`skills/fp-frontend-spec/SKILL.md`、`skills/fp-archive/SKILL.md`、`scripts/validate-plugin.ps1` 以及当前用户指南/产物参考中无条件的单HTML说明；按实际引用更新项目族示例的适用范围。

- [x] 下游通过 artifact-layout 条件指针读取 prototype-contract；新原型源码/fixtures不是PRD Markdown分片，也不是生产实现或真实E2E证据。
- [x] 归档整包检查相对资源/入口；静态可查看与可重建分开报告，不盲目执行记录的命令。
- [x] 总校验接入两个新测试脚本；不改与新功能无关的历史设计/计划。
- [x] 运行全部校验、审阅diff，回放无前端/原生前端/失效基座/未知SSR/旧HTML场景。
- [x] 记录实际验证与未进行的消费者项目构建；完成状态更新到本计划。

验证命令：

```bash
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1
```

```bash
git diff --check
```

预期：全套契约与fixture通过。技能行为回放另记录，不以字符串测试证明真实 Vue/React 构建或视觉保真。
