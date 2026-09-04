# FeaturePilot 执行审查限次设计

## 背景

当前 `fp-execute-sdd` 要求任务在 Critical / Important 问题修复后持续重新审查，直到审查干净；已有规则只在“同一阻断问题经历三次修复仍存在”时暂停。这个口径没有限制单个步骤的审查总次数，也没有覆盖每轮出现不同问题的情况，因此可能产生过多 reviewer/fixer 循环。普通 `fp-execute` 也没有明确规定 inline 自审的重审上限。

## 目标

1. 单个任务步骤的 review 总次数最多为 3 次，首次 review 计为第 1 次。
2. 前两次未通过时允许定向修复并重新 review；第 3 次 review 后不再为该步骤启动新的 review。
3. 达到上限仍未通过时，完整记录未通过点；非主流程问题作为 review debt 继续后续任务，主流程问题才阻塞执行。
4. 普通执行、SDD 执行和最终整体 review 使用一致的计数与阻断语义。
5. 用插件验证脚本固定该契约，防止以后重新出现无限 review 循环。

## 非目标

- 不降低 reviewer 对真实 Critical / Important 问题的报告要求。
- 不把 Critical 问题、核心行为不可用或安全风险自动降级为非阻断事项。
- 不允许通过拆分 finding、替换 reviewer 或重新生成 package 来重置同一 review scope 的计数。
- 不改变 task-owner checkbox 作为计划完成状态、`progress.md` 作为恢复证据的既有职责。
- 不并行派发 implementer、fixer 或 reviewer。

## 核心模型

### Review scope

每个任务是一个独立的 task review scope；最终整体审查是另一个独立的 final review scope。每个 scope 都维护 `review_attempt`，合法值为 1、2、3：

- 首次 review：`review_attempt = 1`。
- 第 1 或第 2 次 review 未通过：记录 findings，执行一次定向修复，然后将 attempt 加 1。
- 第 3 次 review 未通过：停止该 scope 的 review/fix 循环，进入阻断分类。
- 任何一轮通过：立即结束该 scope，不消耗剩余次数。

次数按 scope 累计，而不是按 finding、reviewer、fixer、提交或会话累计。中断恢复时必须从 `progress.md` 恢复已有次数，不能重新从 1 开始。

### 审查结果处理

每轮 review 都必须把 attempt、verdict、Critical / Important / Minor findings、review 路径和处理结论追加到 ledger。`CANNOT VERIFY FROM DIFF` 按未通过处理，先补充证据；达到第 3 次时再根据缺失证据是否影响主流程进行分类。

第 3 次仍未通过时：

- 若不存在主流程阻断项，记录 `review_debt`，将任务标记为“带审查遗留项完成”，同步 task-owner checkbox 和两端 overview 派生进度，然后继续下一任务。
- 若存在主流程阻断项，记录 `BLOCKED`，不勾选 task-owner checkbox，并暂停执行，向用户给出精确问题、已有尝试、review 证据和需要的决定。

最终整体 review 也最多 3 次。达到上限后的非阻断 findings 进入最终报告；主流程阻断项继续阻止完成或归档。

## 主流程阻断判定

满足以下任一可观察条件时视为影响主流程：

1. 存在 Critical finding，包括数据丢失、安全漏洞、权限绕过、生产破坏或可能破坏数据的迁移风险。
2. 已确认的核心验收行为不可用，当前任务没有交付其主要目标。
3. 必需构建、核心测试或关键替代验证失败，使当前交付不可运行或后续任务无法可靠执行。
4. 对外 API、字段、路由、事件、权限 action 或其他明确接口契约损坏，并阻塞依赖该契约的后续任务。
5. 修复必须改变已批准的 proposal/design/plan 范围。
6. 修复需要 brief 中不存在的产品、架构、安全、权限或数据安全决策。

不满足以上条件的 Important / Minor finding 可作为 review debt，例如局部可维护性、非核心边界行为、不会阻塞依赖链的测试补强或视觉微调。控制器必须基于证据分类，不能只按 reviewer 的 `Ready for next task` 字段机械暂停。

## 产物与状态

`progress.md` 增加明确的审查证据：

```markdown
## Review Debt
- <task-id>: attempt 3/3; <finding>; review <path>; disposition deferred

## Events
- <ISO time> review_attempt task=<task-id> attempt=1/3 verdict=FAIL critical=0 important=2 minor=0 review=<path>
- <ISO time> fix_attempt task=<task-id> after_review=1
- <ISO time> review_attempt task=<task-id> attempt=2/3 verdict=PASS critical=0 important=0 minor=1 review=<path>
```

同一任务的历史未通过点必须保留在 append-only ledger 中，即使最新 review 文件沿用固定路径也不能覆盖审查历史。恢复、任务选择和最终汇报都必须读取 `Review Debt` 与 review attempt events。

## 技能修改范围

- `skills/fp-execute/SKILL.md`：为 inline 自审增加总计 3 次上限、计数规则、review debt 和主流程阻断处理。
- `skills/fp-execute-sdd/SKILL.md`：把“直到 reviewed clean”改为有限状态机；首次加两次重审构成最多 3 次，并同步任务级与最终级处理。
- `skills/fp-execute-sdd/task-reviewer-prompt.md`：注入当前 attempt 和最大 attempt，保持 reviewer 只负责报告事实，阻断分类由 controller 完成。
- `skills/fp-execute-sdd/fix-prompt.md`：明确 fixer 只处理当前 findings，达到 review 上限后不得触发新的 fixer/reviewer 循环。
- `scripts/validate-plugin.ps1`：增加 review 上限、首次计数、上限后债务/阻断分支、恢复不重置和最终 review 上限的回归锚点。

## 验证策略

先修改验证脚本并运行，确认它因现有无限循环文案和缺失限次契约而失败；再修改技能和模板使其通过。至少覆盖：

1. `fp-execute` 与 `fp-execute-sdd` 都声明首次计入、总计最多 3 次。
2. SDD 不再包含“持续修复直到审查干净”的无限循环契约。
3. 第 3 次未通过后不会产生第 4 次 review。
4. 非阻断 finding 进入 review debt 并继续下一任务。
5. 主流程 finding 进入 `BLOCKED`，保持 checkbox 未完成。
6. ledger 恢复时沿用已有 attempt，不重置计数。
7. 最终整体 review 使用独立 scope，但同样最多 3 次。

完成后运行 `scripts/validate-plugin.ps1` 以及仓库已有的 artifact、explore 和 SDD fixture 回归脚本。

## 风险与控制

- “带审查遗留项完成”可能留下质量债务，因此 ledger 与最终报告必须逐项列出，不得只写数量。
- reviewer 的严重级别可能误判；controller 必须使用上述可观察条件判断是否阻断，并保留分类理由。
- 达到第 3 次后不再自动修复，可能错过一次简单修正；这是限制循环成本的明确取舍，用户仍可在后续任务中显式要求重新打开该任务。
- final review 可能再次发现已有 review debt，但不得借此重置原 task review scope；只按 final review scope 的独立 3 次上限处理。

## 验收标准

- 任一任务最多产生 3 次 review，包含首次 review。
- 第 3 次未通过时，所有未通过点和处理结论都保存在 `progress.md`。
- 非主流程问题不会阻止选择下一任务；主流程问题会暂停并请求用户决策。
- 中断恢复后 review 次数连续累计，不会重新开始循环。
- 最终整体 review 最多 3 次，非阻断遗留项进入最终报告。
- 插件完整验证与相关回归脚本全部通过。
