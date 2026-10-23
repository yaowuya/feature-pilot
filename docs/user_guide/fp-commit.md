# fp-commit 用户指南

`fp-commit` 用于当前 Git 分支的代码审查、修复、验证与提交。普通模式把推送、PR/MR 和最终合并分别交给你确认。显式 `auto` 模式会推送并创建 PR/MR，**不会自动合并**。

## 使用前提

当前应用需要在 `fp-docs/settings/backend.md` 或 `frontend.md` 的 `Code Standards` 中登记可用的内置规范或项目规范来源。只有 `fp-docs/manifest.md`、占位值、`Unknown`，或 `none` 且没有项目来源时，不算已初始化。技能会停止并提示运行 `/fp-init`，不会替你写入 settings。

Django、Vue 规范正文保留在插件中。项目专属规范可由 `/fp-init` 逐文件批准创建 `fp-docs/settings/code-standards.md`，并在适用端的 `Project rule sources` 中登记。已有 settings 的修改需要确认精确 diff；跳过专属文档不影响已登记内置规范的 review，但若本次发现确实需要沉淀的新规则，必须先完成专属文档登记。

## 普通模式

运行 `/fp-commit`，或明确要求 FeaturePilot 提交当前代码。技能先核对适用规范和本次改动，分别检查规范偏差与可复现的缺陷。范围内的问题修复并验证后，只暂存已审文件并核对暂存 diff，再提交。

提交后，技能展示实际推送目的地、当前分支和提交 SHA，询问是否推送。推送成功后，再询问是否创建 PR/MR 及目标分支。如果你要最终合并，它会核对当前检查、冲突和保护规则，并再次取得合并授权。单纯请求提交不意味着授权推送或合并；如果你只要本地提交，不需要配置远端或完成 PR/MR 鉴权。

## 显式 auto 模式

运行 `/fp-commit auto`。本轮有效的显式选择允许技能在门禁都通过后，不逐步询问地完成 review、必要修复、验证、commit、push，以及向**实际推送目的地的默认分支**创建 PR/MR。它先解析有效 push remote、pushurl 和 URL rewriting，再向唯一的实际 push URL 查询远端 HEAD；fetch 地址与 push 地址不同时，不能混用两个仓库。它不根据本地分支名称猜 `main` 或 `master`。创建请求后立即停止，不执行 merge，也不启用平台 auto-merge。

`auto` 不是 Claude/Codex/Cursor 的权限模式，不能绕过宿主工具审批。规范未初始化、必要验证失败、改动范围不明、默认分支无法核实、远端能力不可用或请求冲突时，技能会停下说明已完成的步骤，不以猜测代替确认。

## 规范沉淀与结果

只有明确项目约定或多个独立源码/测试证据支持的新规则，才会写入**已存在且已登记**的项目规范文档，标注规则 ID、appRoot、适用端和依据。单个文件的偶然写法只是候选，不会变成全项目或插件通用规则。`fp-commit` 不能创建规范文件、改写登记或修改插件内置 Django/Vue 规则。

每次结果分别说明规范状态、review 与修复、测试及未验证项、实际提交和推送状态、PR/MR 链接与目标，以及是否真正合并。创建 PR/MR 不等于 CI 通过或已合并。命令本身不是 Git Hook；手工 Git 操作不会被它自动拦截。
