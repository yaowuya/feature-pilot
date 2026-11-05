# ub-mode

改编自 [unclebob/ub-mode](https://github.com/unclebob/ub-mode)。本文件是这些原则在 FeaturePilot 中的唯一规则来源。按当前阶段只读对应分支。

优先级：当前用户指令，然后是已确认的 proposal 与 design，然后是本契约。[engineering-quality.md](engineering-quality.md) 仍拥有 docstring、新增复杂度的当前证据和 `fp-debt`。本契约不把这些说明当成重复删掉，也不另建决策日志、术语表或债务文件。

## Boundaries

- Design does not run crapper, dryer, or mutator.
- A missing crapper, dryer, or mutator does not block task completion.
- This contract does not authorize a push and does not move the destination onto the main line.
- This contract does not delete a worktree or uncommitted work.

## Design

`fp-brainstorm` 比较方案并写入技术设计时读本分支，`fp-design-review` 检查该设计时读本分支。`fp-start` 阶段 2 加载这两个 skill，不另写一份原则。

在已确认 proposal 内按顺序做 Make it Work，然后 Make it Right：

1. 一个决策只放一处。Decision Ledger 持有选择，其他章节只链接。
2. 先写下数据形状，再写使用它的行为。
3. 先写下复用当前代码和框架能力、并能满足已确认验收的最小方案。
4. 再写下「这个需求从一开始就存在时会采用的结构」，并拆成能够核验终态的交付单元。该结构改变已确认 proposal 的行为、接口、架构或验收时，记入 Decision Ledger 并等待确认，再写入设计。
5. 两个方案因同一个前提失败时，先用一句话写下该前提，并写明失衡落在哪一方，然后再给下一个方案。
6. 先去掉复杂度，再增加抽象、层、依赖、缓存或异步路径。新增项写明它现在解决的具体需求。
7. 领域模型使非法状态无法表示。设计中的核心对象就是术语表。
8. 在数据进入的边界校验；边界内部信任它。当前技术栈放得下纯函数时，业务规则放在纯函数中。
9. 重试或中途崩溃后必须落到同一状态时，把操作设计成幂等。并发写入会互相影响时，各自持有自己的状态，或只允许一个写入者，并把这个约束体现在结构里。
10. 验证写明调用方能看到的结果，以及实现前应当失败的测试。新行为被拿掉后仍然会通过的测试，不能当作验证。
11. 只有变更本身是重复的机械工作时才设计杠杆：先手工定一个单位，再让杠杆与该单位一致。杠杆留在本次变更内，不新增项目依赖。

质量工具、提交和远端发布见 Boundaries。设计把可核验的行为写进验证方案。

## Implementation

`fp-execute`、`fp-execute-sdd` 的 implementer 与 fixer、用户已确认后的 `fp-quick` 实现，以及 `fp-commit` 的代码修复，读本分支。

### Make it Work

- 一个决策只放一处。只做能完成已确认任务的最小改动。
- 先把数据形状定对，再写逻辑。
- 先写失败测试，并看到它因为目标行为不存在而失败。再用最小改动让它通过。诚实测试不现实时，记录替代验证。
- 本次改动的代码同时满足 Design 第 6–9 条。改动保持在已批准任务内。更干净的结构会改变已批准的行为、接口、架构或验收时，回到现有决策流程。
- 同一任务的两次修复带着同一个前提、又没过同一道门时，先用一句话写下该前提，再做下一次修复。这仍在现有三次尝试上限内。
- 重复的机械工作先手工完成一个单位，再做与之对齐的杠杆，不新增项目依赖或生成器。

### Make it Right

目标测试通过之后、勾选任务之前：

- 复现缺陷并修复原因。只掩盖崩溃的守卫不算修复。
- 测试按调用方的方式调用代码，并检查调用方会看到的结果。新行为被拿掉后仍然通过的测试，删掉或改写。
- 先用现有测试钉住行为，再只在本任务 diff 内调整结构，然后证明行为没有变化。
- 本任务新增或修改的每个函数，通过拆分、补测试或两者一起，降到 CRAP < 10。去掉本 diff 中相似度达到 0.8 或以上的重复。删除本次变更引入的死代码。
- `crapper`、`dryer` 或 `mutator` 已在 PATH 上，且本次调用不会安装包、修改 lockfile 或写入项目配置时，对变更文件运行并记录结果。工具缺失、文件类型不支持，或运行会改动项目依赖时，记录为跳过。does not block task completion。任务完成状态仍由 task-owner checkbox 持有。

### Practice

- 把每一步动作和原因写入已有的 `.fp-execute/progress.md`、implementer report，或 `fp-quick` / `fp-commit` 的最终汇报。
- 给用户的汇报保持简短，diff 和日志留在上述已有文件。`fp-execute` 留在当前上下文。`fp-execute-sdd` 继续把大段实现和审查放在现有子代理里。
- 拥有提交权的 skill 按它已有的规则提交。提交说明写清原因、改动和验证。远端发布见 Boundaries；拥有 skill 自己已经授权的推送仍由该 skill 执行。
