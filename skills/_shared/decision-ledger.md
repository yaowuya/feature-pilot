# Decision Ledger Contract

本契约只用于 `fp-propose` 与 `fp-brainstorm` 的写入前决策门禁。它不要求重复访谈已确认 PRD，也不创建独立的 change-local 台账文件；最终终态记录写入对应产物的既有 detailed owner，供交接与恢复核验。

## 会话 Decision Ledger

在探索或问答开始时建立当前阶段的台账。每个会改变当前阶段范围、行为、接口、权限、数据、安全、交付策略、架构、form、目标路径或移除动作的活动项，必须有稳定的 `decision ID`：proposal 使用 `P-001` 起始编号，design 使用 `D-001` 起始编号。Each decision ID is unique within its current phase；不得复用 ID、跨阶段混用前缀，或把多个独立决策塞进同一 ID。All design end owners use one globally unique D-NNN sequence；跨端决策只由一个 detailed owner 持有，其他端只能链接。

```markdown
| ID | Decision | Source | Blocking | Status | Evidence / explicit confirmation |
| --- | --- | --- | --- | --- | --- |
| P-001 | <决策项> | `<PRD section>` / `<path:line>` / user answer | yes / no | `PRD-confirmed` | <精确来源或确认记录>
```

状态只能是：

- `PRD-confirmed`：从已确认的 canonical PRD 或上游已确认产物精确解析；不得重复提问。
- `code-verified`：仅表示当前代码可证明的既有事实或约束，不得把新的产品或架构选择伪装成代码事实。
- `user-confirmed`：用户明确选择了该 `decision ID` 的值或选项。
- `not-applicable`：有范围或证据说明该项不适用。
- `needs-user-confirmation`：任何新选择、冲突、歧义、缺失证据或仅有建议的活动项；它不可写入。

助手的 `agent recommendation` 只能作为某行的推荐选项，**not user confirmation**。用户回答后，先记录对应 ID 与所选值；只有明确确认该 ID 后才可将其设为 `user-confirmed`。可以在同一条消息确认多项，但必须逐一列出 ID 和选择；`generic confirmation does not resolve` 任一 `needs-user-confirmation` 行。

## 写入前门禁

1. 展示当前阶段完整的活动台账，以及每项的来源、状态和证据。
2. 对 `needs-user-confirmation` 行逐项提问或要求带 ID 的明确确认；每次只推进已回答的行。
3. 写入前，所有当前阶段必需的活动行必须是 `PRD-confirmed`、`code-verified`、`user-confirmed` 或 `not-applicable`，并具有 Source 与 Evidence / explicit confirmation。
4. 任何 `needs-user-confirmation` 行存在时，`needs-user-confirmation blocks writing`；不得创建目录、读取输出模板、创建/覆盖/删除产物或以假设补全内容。
5. 台账全部合格后，仍必须取得与既有内容、form、exact paths 和 conversion/removal 范围对应的 **separate write authorization**。该授权不是逐项确认的替代品。

## 持久化与恢复证据

新写入的 proposal/design 必须在其既有 detailed owner 中持久化终态台账和写入前确认记录。终态记录只能保留合格状态，`needs-user-confirmation` **must not persist**。`Covered IDs` 必须列出 every persisted decision ID exactly once，`Outstanding blocking decisions` 必须为 `none`，并记录用户对本次写入的明确授权。`placeholder`, `TBD`, `TODO`, or `unknown` 都不是有效 Source、Evidence 或授权；每条 Evidence 都必须带自己的 concrete decision ID，`user-confirmed` 行还必须带 user selection or message reference，`PRD-confirmed` / `code-verified` 行必须带精确的 canonical source 或 `path:line` 依据。单独的 `ID: user answer` 不是确认凭据；`user-confirmed` Evidence 必须写出 selected value and message reference（可引用本次会话中的精确用户回复）。

恢复时，缺少台账、确认记录、来源/证据，或发现未终态行，都表示写入前确认无法证明。不得把文件存在、旧摘要或助手推荐视为已完成门禁；返回所属阶段，仅补齐缺失 decision ID 的确认或进行用户授权的修订。
