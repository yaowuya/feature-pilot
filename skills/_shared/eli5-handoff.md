# `fp-eli5` JIT Handoff Contract

本契约只用于 FeaturePilot 阶段 skill 在用户显式要求零基础图解时，临时调用 `fp-eli5` 并恢复原门禁。它不是持久化 artifact，不创建新的阶段、状态或确认来源。

## 延迟加载

Caller 只有在用户显式调用 `/fp-eli5`、`$fp-eli5`、明确要求“讲简单点/画图解释”，或明确接受一次图解建议后，才读取本文件并调用 `fp:fp-eli5`。普通问题、阶段完成、复杂度或 agent 判断不得自动触发。

允许的 caller 只有：

- `fp-init`
- `fp-prd-grill-me`
- `fp-brainstorm`
- `fp-plan`
- `fp-start`

## 调用块

Caller 传入恰好一个块，字段和顺序固定。下面的 `<...>` 都是 schema metavariable；调用前必须替换为当前会话的精确值，发送未解析 metavariable 属于无效调用：

```markdown
<!-- fp-eli5-handoff
caller: fp-init|fp-prd-grill-me|fp-brainstorm|fp-plan|fp-start
topic: <用户明确要求解释的当前主题>
active-slug: <caller 已解析的精确 slug 或 N/A>
pending-gate: <当前精确 decision/checkpoint>
allowed-sources:
  - <caller 已确认并允许复用的上下文、路径或证据>
return-to: <原 caller 与同一 pending-gate>
-->
```

未知字段、缺失字段、字段乱序、非法 caller、多于一个块、空 topic、空 pending-gate、空 return-to、未解析 metavariable 或扩大 source scope 都必须 fail closed：返回原 caller，说明无效字段，不生成图解，也不自行补全。

`allowed-sources` 只限定 caller 已有上下文，不能弱化 `fp-eli5` 的仓库取证、外部研究、敏感数据或 no-write 边界。若主题涉及当前仓库事实，`fp-eli5` 仍按其权威合同单向调用现有 `fp-explore` public standalone。

## Non-authority boundary

`fp-eli5` 只负责解释。其输出：

- 不更新 Decision Ledger；
- 不更新 task checkbox；
- 不改变 coverage state；
- 不改变 review verdict；
- 不产生 write authorization；
- 不把 recommendation 当作用户答案；
- 不证明 proposal、design、plan、review、verification 或 archive gate 已通过；
- 不加载或推进下一阶段。

解释完成后，caller 必须保持状态不变，重新呈现完全相同的 `pending-gate`，并等待用户显式答复。HTML artifact 的查看、关闭或交互不是 gate 回答。

## Caller-specific restoration

- `fp-init`：恢复同一个安装、MCP、建图、刷新、manifest、settings、discovery 或 write-scope 问题。
- `fp-prd-grill-me`：恢复同一个 Phase 1 review item 或当前唯一 Bucket C `N/Total` 问题；不得提前显示下一题。
- `fp-brainstorm`：恢复同一个 `D-NNN`、章节审阅或 pre-write gate，Decision Ledger status 不变。
- `fp-plan`：恢复 explicit plan confirmation；不得改写计划、勾选任务或选择执行方式。
- `fp-start`：恢复同一个 quick/full、proposal、design、plan 或 SDD-mode stage gate；不得推断 resume 完成。
