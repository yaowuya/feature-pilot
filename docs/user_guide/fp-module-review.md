# `fp-module-review` 用户指南

`fp-module-review` 用于对一个大型功能模块或多个彼此相关的模块进行持久、证据驱动的专项审查。它先冻结 scope 和兼容性基线，再按 ownership 与 call flow 分 wave 审查，使用稳定 `MR-FNNN` 记录 Finding；只有授权明确的 Finding 才能进入最小 TDD 修复。

它不是整仓审计，也不替代 `fp-final-review`、Pull Request review 或小 diff review。

## 什么时候使用

适合以下场景：

- 一个功能模块横跨较多文件、入口、状态或资源生命周期，单次小 diff review 不足以覆盖；
- 用户明确把多个相关模块作为同一个功能边界审查；
- 审查需要跨会话恢复，并保留 scope、baseline、wave、Finding 和验证证据；
- Finding 可能需要用户逐项批准 observable behavior 变化，并在批准后修复；
- 只做专项 review 和 Finding 登记，不实施修复。

以下场景不应使用：

- 一个很小、边界明确的 diff：直接做小 diff review；
- Pull Request 的常规审查：使用 PR review；
- 合并或归档前对整个分支做最终只读门禁：使用 `fp-final-review`；
- 用户没有证明多个目标属于一个相关功能边界：应拆成独立 module-review workspace；
- 仓库级全量审计：本 skill 不会把模糊 target 静默扩大到全仓。

## 最短用法

Claude Code：

```text
/fp-module-review 审查 <模块目录、符号或功能边界>
```

Codex：

```text
fp:fp-module-review 审查 <模块目录、符号或功能边界>
```

如需明确模式和重点，可以写：

```text
/fp-module-review targets=<目标1,目标2> mode=review-only focus=correctness,concurrency baseRef=<ref>
```

## 输入与 target ambiguity

流程接受以下输入：

- `targets`：一个或多个仓库相对目录、文件、symbol 或命名功能模块；至少一个必须能解析；
- `slug`：`fp-docs/module-reviews/<slug>/` 下稳定 workspace 名称；
- `focus`：可选维度，例如 correctness、contracts、security、lifecycle、concurrency、resource ownership、performance、tests 或 production readiness；
- `mode`：`full`、`review-only` 或 `resume`；
- `baseRef`：可选 diff 导航基线；当前源码而不是 diff 定义模块行为。

没有 `slug` 时，流程从已解析 target 名称派生稳定 kebab-case slug，并在 resume 时复用。

如果存在多个可能 workspace 或 target 解释，流程只问一个会改变执行边界的 bounded question。用户暂时不在线、deadline 紧、管理者偏好或“两个都审查成本不高”都不是选择证据；不能把 ambiguity 静默扩大到两个候选、共享基础设施或整个仓库。

多个 targets 只有在用户明确一起指定，或当前源码证明它们构成一个相关功能边界时，才能共享一个 workspace。独立模块应分别审查。

## 三种 mode

| mode | 行为 |
| --- | --- |
| `full` | 默认模式；完成 scope、baseline、waves、triage，按批准门禁实施可授权的最小修复，并验证收敛。 |
| `review-only` | 完成调查、Finding、triage 和安全验证，但绝不进入 `FIXING`。 |
| `resume` | 读取 canonical workspace 和最后恢复证据，校验当前指纹，失效旧证据，并从最早必要状态继续。 |

`review-only` 并不降低证据标准。它仍需要如实记录 Finding 状态、无法验证的 claim 和 completion 限制。

## canonical workspace

使用固定布局：

```text
fp-docs/module-reviews/<slug>/
├── review.md
├── scope.md
├── baseline.md
├── waves.md
├── findings/
│   └── MR-FNNN.md
├── summary.md
└── .fp-module-review/
    └── progress.md
```

每个文件只有一个 owner 职责：

- `review.md`：稳定入口、quick status、Finding counts 和有序 canonical manifest；
- `scope.md`：targets、direct integrations、review dimensions、exclusions、precedence、allowed/protected paths 和外部授权；
- `baseline.md`：snapshot、observable compatibility contracts、existing test baseline、command safety ledger 和 evidence gaps；
- `waves.md`：ownership waves、依赖、状态和 candidate reconciliation；
- `findings/MR-FNNN.md`：一条 Finding 的完整证据和 disposition；
- `summary.md`：最终 scope/wave/Finding 对账和完成状态；
- `.fp-module-review/progress.md`：append-only recovery evidence；不拥有 Finding 状态。

详细 Finding 状态不能复制到 `review.md`、`waves.md`、`summary.md`、task checkbox 或 progress event。唯一 owner 是对应 `findings/MR-FNNN.md`。

## lifecycle states

流程只记录一个当前状态：

```text
SCOPING
BASELINING
REVIEWING
TRIAGING
WAITING_APPROVAL
FIXING
VERIFYING
BLOCKED
COMPLETE_WITH_AWAITING
COMPLETE
```

正常主链为：

```text
SCOPING → BASELINING → REVIEWING → TRIAGING
→ WAITING_APPROVAL | FIXING
→ VERIFYING
→ COMPLETE_WITH_AWAITING | COMPLETE
```

`BLOCKED` 可以从任一状态进入，但必须提供具体证据和精确 recovery condition。

`SCOPING`、`BASELINING`、`REVIEWING` 与 `TRIAGING` 对产品源码和现有测试是只读的。这些阶段只能创建或更新当前 module-review workspace；发现 candidate 不等于获得修改授权。

## SCOPING 与 BASELINING

`SCOPING` 读取当前项目规则、可用的 `fp-docs/manifest.md` 及相关信息层、目标当前源码、direct callers/imports/registrations/routes/config/storage/lifecycle owners、相邻测试，以及当前 Git HEAD、status 和可选 `baseRef` diff。

范围清单必须包含：

- 明确 targets；
- 有当前证据支持的 direct integration points；
- 相关 tests/configuration；
- review dimensions 和 exclusions；
- allowed artifact/test/source write paths；
- protected paths；
- 不可用或未授权的外部系统。

无关 caller 和共享基础设施不会自动进 scope。只有当前证据证明某个 integration 可以改变或破坏目标模块行为时才纳入，并记录原因。

`BASELINING` 在任何可能改变 observable behavior 的 Finding 获得修复授权前，记录适用的兼容合同：API/method/path、schema/default/limits、response/error/status、timing/order、logging/callbacks、storage/retention、permissions/security、configuration/deployment、resource lifecycle 和 user-visible behavior。

### command safety

所有命令必须在读取 script、alias、wrapper、config 和 flags 后分类：

- `SAFE`：只读，或只写已枚举的隔离 test/report/cache/temp outputs；
- `UNSAFE`：安装/升级、迁移、seed、deploy、格式化/写产品代码、更新 snapshot/golden、修改 Git、接触真实 service/database/external system 或执行破坏性文件操作；
- `UNKNOWN`：wrapper 行为或副作用无法证明。

只运行 `SAFE`。`UNSAFE` 与 `UNKNOWN` must not run；命令名称、团队口头说明或 dry-run 标签不能作为安全证明。不能执行的验证要写入 evidence gap 和最终限制。

## ownership 与 call-flow waves

审查按 ownership 和 call flow 划分 coherent waves，而不是平均按文件数量切块。适用维度包括：

- public API、schema 与 contracts；
- domain/service correctness 和 error handling；
- state、queue、scheduler、concurrency 与 ordering；
- lifecycle、cleanup、cancellation 与 resource ownership；
- storage、transfer、cache 与 external integration；
- logging、callbacks、configuration、security 与 production readiness；
- tests 与 final reconciliation。

每个 wave 记录 owned targets/integrations、dimensions、dependencies、verification candidates 和 completion evidence。只有每个 owner/dimension 都有证据支持的 disposition，包括适用时的明确 `no finding`，wave 才完成。

独立 wave 可以并行做只读调查，但代理只返回 candidate。主控制器负责验证当前源码、去重、分配稳定 ID 和写 owner 文档；代理不能分配最终 Finding ID 或修改源码。

## Finding 证据与稳定 ID

Finding 使用单调递增的 `MR-FNNN`，从 canonical manifest 中最高 ID 继续。ID 不能因 severity 或状态变化而重排、重命名或复用。

candidate 只有在当前源码与至少一项补充 proof 共同证明具体失败或重大风险时，才能变为 `confirmed`。补充 proof 可以是：

- deterministic failing test；
- reproduction；
- verified call path；
- contract contradiction；
- resource/lifecycle violation；
- safe command output。

CodeGraph、style preference、hypothetical misuse 或历史说明单独都不够；反证成立时使用 `rejected`。

每条 Finding 至少记录 stable ID、evidence、trigger、wrong result/risk、supplementary proof、severity、observable behavior impact、state、disposition、test mapping、RED/GREEN/adjacent regression、rollback 和 residual risk。severity 只使用 `Critical | High | Medium | Low`，纯风格偏好不作为 Finding。

允许的 Finding transitions：

```text
candidate → confirmed | rejected
confirmed → awaiting-user-confirmation | fixed | blocked
awaiting-user-confirmation → approved | blocked
approved → fixed | blocked
blocked → approved | fixed
fixed 和 rejected 为 terminal
```

对应稳定状态词为：

```text
candidate
confirmed
awaiting-user-confirmation
approved
fixed
rejected
blocked
```

## observable behavior approval gate

observable behavior 包括 accepted inputs、API/schema、response/error/status、timing/order、logs/callbacks、persistence/retention、permissions、security policy、deployment compatibility 和 user-visible behavior。

生产修复只有在以下任一条件成立时才授权：

1. Finding 的 observable behavior impact 为 `none`；
2. 用户明确批准该 stable ID 及其 proposed behavior。

团队角色、severity、release deadline、泛化的“修复安全问题”授权，或对另一个 Finding 的批准都不能满足门禁。

对非 `none` 影响，Finding 进入 `awaiting-user-confirmation`，记录 current/proposed behavior、affected consumers、rollback 和精确决策，控制器进入 `WAITING_APPROVAL`。此时可以继续独立只读 waves，但不能修改该 Finding 的生产行为。

## 批准后的 TDD 修复

每个已授权 Finding 只执行一个 bounded TDD loop：

1. 冻结该 Finding 的 allowed source/test paths 和 protected paths；
2. 编写或识别最窄 deterministic behavior test；
3. 运行并证明 RED 是该 Finding 的预期原因；
4. 应用最小 production change；
5. 运行目标测试并证明 GREEN；
6. 运行完整 owner scope 与 adjacent regression；
7. 检查 unexpected skips、xfails/XPASS、warnings、background errors、declared outputs 和 protected-path diffs；
8. 更新 Finding owner，并追加一个 progress event。

不能为了修复一个 Finding 重构无关代码、扩大 scope、未经明确授权安装依赖或访问真实外部系统、弱化断言，或仅凭代码阅读标记 `fixed`。

若 approved 或 awaiting Finding 的 reproduction 需要留在普通 suite，只有框架能保证 strict expected failure 且 unexpected pass 会使 suite 失败时才允许，并且一条测试只映射一个 Finding。expected failure 永远不等于 fixed。

首次写产品源码后，CodeGraph evidence 标记为 `dirty-after-write`，不能继续查询旧图。若写前已有图，返回前最多执行一次 non-blocking `post-write-sync`；不会为缺图项目隐式初始化。

## resume 与 invalidation

`resume` 读取 `review.md`、canonical manifest、manifest 中列出的 owner artifacts 和最后 progress event，然后比较：

- 当前 HEAD 与 working-tree fingerprint；
- scope/config fingerprints；
- target 是否仍存在；
- test/command definitions；
- environment；
- report identity；
- Finding owners。

生产代码、测试、config、dependency/lockfile、command selection、environment、HEAD/branch、无法解释的 worktree、target scope 或 report 发生变化时，相关 evidence 必须 invalidate。

从最早必要状态恢复：

- target/ownership/exclusion 变化 → `SCOPING`；
- compatibility、test command、environment 或 baseline 失效 → `BASELINING`；
- 已完成 wave 的源码变化 → 该 wave 的 `REVIEWING`，再进入 `TRIAGING`；
- 已授权修复中断且 RED evidence 完整 → `FIXING`；
- 只有最终证据 stale → `VERIFYING`。

无法解释的用户修改必须保留，不能 restore、delete、stash 或覆盖；若 ownership/safety 无法确定，进入 `BLOCKED`。

## VERIFYING 与完成结果

`VERIFYING` 对账 targets/integrations、全部 wave dimensions、稳定 ID 顺序和唯一 owner、所有 Finding counts、RED/GREEN/regression freshness、command safety、当前 HEAD/worktree，以及 changed/allowed/protected/unexplained paths。

### `COMPLETE`

以下条件必须同时成立：

- 每个 wave 完成；
- 没有 Finding 处于 `candidate`、`confirmed`、`approved`、`awaiting-user-confirmation` 或 `blocked`；
- 每个 fixed Finding 都有 fresh RED、GREEN、owner-scope 和 adjacent regression evidence；
- 所有 required `SAFE` verification 通过；
- 没有无法解释的 protected 或 out-of-scope change；
- summary evidence 匹配当前 HEAD 与 working-tree fingerprint。

### `COMPLETE_WITH_AWAITING`

除一个或多个 Finding 精确处于 `awaiting-user-confirmation` 外，其他完成谓词与 `COMPLETE` 相同。这些 Finding 的生产行为必须保持不变，deterministic evidence 被保留，summary 列出 exact IDs 和待决 decision。

该状态不能声称“所有缺陷已修复”或“模块已完全修复”。

### `BLOCKED` 与 `CANNOT_VERIFY`

- `BLOCKED`：缺少安全 baseline/final verification、scope/ownership 无法确定，或其他条件阻止可信结论；必须给出 exact recovery condition。
- `CANNOT_VERIFY`：某个 claim 的证据不可获得，但仍能如实给出其他 review 结论。它按 claim 记录，不是 Finding transition，也不是独立 lifecycle state。

如果缺失证据使整体结论不可信，应使用 `BLOCKED`，不能伪装成 completion state。

## 与其他 review 的区别

| 场景 | 使用方式 |
| --- | --- |
| 大型模块或多个相关模块，需要持久 workspace、waves、stable Finding 或批准后修复 | `fp-module-review` |
| FeaturePilot change 合并/归档前，对整个当前分支做最终只读审查 | `fp-final-review` |
| Pull Request 的常规增量评审 | PR review |
| 一个边界清晰的小 diff | 小 diff review |
| 整个仓库的无边界审计 | 另行定义仓库审计，不要把 module target 静默扩大 |

`fp-module-review` 可以在批准后修复其 Finding；`fp-final-review` 保持只读 whole-branch gate。模块审查完成也不能跳过另行要求的最终分支审查。

## 使用示例

### full：单个大型模块

```text
/fp-module-review targets=src/orders focus=correctness,lifecycle mode=full
```

建立或恢复一个 module workspace，完成 waves、Findings、批准门禁、授权修复和验证。

### review-only：只登记 Finding

```text
/fp-module-review targets=src/billing mode=review-only focus=security,contracts
```

不进入 `FIXING`，但仍完成 baseline、wave reconciliation、Finding disposition 和安全 verification。

### resume：恢复中断审查

```text
/fp-module-review slug=orders-processing mode=resume
```

读取 canonical artifacts，校验当前指纹并从最早失效状态恢复，而不是从上次文字状态盲目继续。

### 多个相关 targets

```text
/fp-module-review targets=src/jobs,src/scheduler focus=concurrency,resource-ownership mode=full
```

只有当前源码证明两个 target 属于同一个调度功能边界时才共用 workspace；否则拆分为两个独立审查。

## 常见误区

- **给一个模糊模块名后自动审查全仓**：禁止；先解析 target，ambiguity 无法消除时询问或停止。
- **把所有 caller 都纳入 scope**：禁止；只纳入能由当前证据证明会改变或破坏目标行为的 direct integration。
- **candidate 一出现就修改代码**：禁止；调查阶段只写 review workspace。
- **高 severity 自动授权行为变化**：禁止；非 `none` observable behavior 必须按 stable ID 获得用户批准。
- **只用 CodeGraph 证明 Finding**：不够；图只做 navigation，Finding 必须由当前源码和补充 proof 共同证明。
- **`review-only` 可以少做验证**：不可以；只是不进入 `FIXING`。
- **`COMPLETE_WITH_AWAITING` 等于全部修复**：不等于；必须列出 exact awaiting IDs，且生产行为未改变。
- **progress event 可以代替 Finding owner**：不可以；`.fp-module-review/progress.md` 只保存恢复证据。
- **模块审查完成后不需要 `fp-final-review`**：错误；两者 scope 和职责不同。
