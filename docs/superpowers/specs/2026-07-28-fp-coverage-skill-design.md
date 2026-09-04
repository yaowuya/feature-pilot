# FeaturePilot 覆盖率提升技能设计

**日期：** 2026-07-28
**状态：** 已确认，coverage tooling bootstrap 增量待实施
**范围：** `/fp-coverage` / `fp:fp-coverage` 单元测试覆盖率专项，以及新项目缺少 coverage 工具时的受控依赖引导

## 1. 背景与事实基线

参考变更 `D:/02-canway/01-code/auto-ops/fp-docs/changes/unit-test-coverage-80` 证明了两类必须区分的结果：

- 2026-07-17 的 fresh full-suite 结果为 `5615 passed, 15 xfailed, 0 failed`、退出码 0，combined statement/branch coverage 为 `113813 / 141889 = 80.2127%`。这是完整成功闭环。
- 2026-07-28 的最新记录虽达到 `85.000687%`，但 pytest 退出码为 1，并保留约 82 个失败 node IDs；这不是完成状态。

因此，coverage 数字与测试套件成功是并列硬门。历史报告、局部模块达标和理论上界只能用于导航或中间决策，不能替代 fresh final gate。

对五个无专用 skill 的压力样本进行基线测试后，通用 Agent 通常会拒绝明显的扩大 omit、关闭 branch 和批量非 strict xfail，但输出并不一致：它们各自发明阶段、证据字段、恢复规则和完成措辞；部分答案仍允许在 coverage-only 任务中“最小调整 exclude”。新 skill 不重复一般测试诚信常识，而是提供统一的 FeaturePilot 执行合同并封闭口径漂移。

## 2. 已确认决策

1. 新 skill 命名为 `fp-coverage`，公开入口是 `/fp-coverage` 和 `fp:fp-coverage`。
2. 它是独立执行型专项流程，不自动并入 `/fp-start`；用户明确要求提高单元测试覆盖率时直接触发。
3. 技术栈中立：复用目标项目已有测试、coverage 配置和 CI 口径，不硬编码 pytest、Jest、JaCoCo、Go cover 或 coverlet。
4. 默认只允许修改测试、测试夹具和当前 change 的 coverage 证据；生产代码修复必须退出 coverage-only 边界或取得明确扩展授权。
5. source/include/omit/exclude、branch 开关、阈值统计维度和正式命令在 fresh baseline 前冻结。本流程不得为达标修改它们。
6. 流程主链为：解析边界 → 审计命令 → fresh baseline → 归因已有失败 → 缺口排序 → 分批 RED/GREEN → 周期全量刷新 → final gate → 副作用/issue 对账。
7. 最终完成必须同时满足：正式全量测试/coverage 命令退出成功、精确 numerator/denominator 达标、普通失败为零、意外 skip 为零、受管 strict xfail 与 issue 一一对应、配置口径未漂移、受保护路径无未解释 diff、证据匹配当前 HEAD 和工作树。
8. 工作流使用 `fp-docs/changes/<slug>-coverage/.fp-coverage/progress.md` 作为有界、可更新的恢复索引；详细证据按 `contract.md`、`baselines/`、`batches/` 和 `verifications/` 拆分。它们都不是第二套 FeaturePilot task completion authority。若在已有 change 内运行，它仍创建/复用独立的 `<slug>-coverage` change 根，但可以引用原 change 的 owner task，checkbox 仍是计划完成权威。
9. `fp-docs/changes/<slug>-coverage/` 是唯一 `coverage-change-root`：`issues.md` 只记录单元测试过程中发现的生产代码或测试代码问题；在 `FINAL_VERIFYING` completion boundary 生成并核对 `final-report.md` 后才进入 `COMPLETE`；`coverage.xml`、`htmlcov/` 和其他声明的机器可读或 HTML coverage 报告也写在该目录内，不得写项目根。测试源码和批准 fixture 仍保留在项目既有测试路径。
10. 任何测试/生产源码、coverage 配置、依赖锁、构建配置、测试选择、环境或 HEAD 变化都会使相关全量证据 stale；恢复时必须重新验证指纹。
11. 测试发现生产 bug 时，记录 issue 或外部 ticket；只有明确、单一、可追踪的问题可使用 `strict` xfail，不能批量弱化失败。
12. 不创建通用 coverage XML 解析器。skill 从项目正式工具的机器可读报告或精确输出读取计数；无法取得精确计数时报告 `CANNOT_VERIFY`，不从整数百分比反推。
13. 不升级插件版本、不提交、不推送；这些属于单独发布或 Git 授权范围。
14. 若项目能运行测试但缺少 coverage 工具，结果保持 `RESOLVING` 且 coverage 证据为 `CANNOT_VERIFY`；skill 必须提出可执行的 coverage tooling 建议和批准门禁，而不是只给终止型 `BLOCKED`。
15. 工具选择优先复用项目现有 runner、coverage 工具和 CI。只有没有现成 coverage 方案时才建议补充工具；Django 已使用 pytest 时优先推荐 `pytest-cov`，Django 尚未使用 pytest 时推荐 `pytest + pytest-cov`，仅在测试确实需要 Django pytest 集成时再建议 `pytest-django`。
16. 用户明确批准后，skill 可以执行范围严格的 `coverage-tooling-bootstrap`：使用现有包管理器安装已展示的依赖、更新相应依赖声明、写入最小必要 coverage 配置，并重新建立 fresh baseline。该授权不允许顺带升级其他依赖。
17. 批准前必须展示项目/runner 识别依据、推荐依赖、精确安装命令、将修改的依赖和配置文件、冻结的生产源码范围、baseline/final 命令、全部 coverage 输出路径及失败恢复方式。

## 3. 触发与非触发

### 触发

- 将 unit test coverage、line coverage、branch coverage 或 combined coverage 提高到指定阈值；
- 按覆盖率缺口持续补测试；
- 恢复中断的覆盖率专项；
- 建立项目现有工具下的覆盖率质量门。

### 不触发

- 只查询当前覆盖率：使用只读探索；
- 为一个已完成 feature 补少量明确测试：使用普通执行流程；
- E2E、浏览器或视觉测试专项；
- 纯 coverage 配置调整；
- 生产 bug 修复。

## 4. 输入与状态模型

开始时解析：项目根、目标阈值、统计维度、全仓或 owner scope、测试根、源码范围、正式配置、正式命令、允许写入路径、受保护路径、测试发现 bug 的策略、临时产物策略和时间预算。能从当前项目配置与 CI 精确证明的输入无需重复询问；只有真正改变执行边界的未知项才阻塞。

状态固定为：

- `RESOLVING`：解析项目、口径和边界；缺少 coverage 工具但可以安全提出 bootstrap 时也保持此状态；
- `BASELINING`：运行 fresh baseline；
- `TRIAGING`：归因 baseline failures；
- `ITERATING`：执行 owner batch；
- `FINAL_VERIFYING`：运行 fresh full-suite final gate；
- `BLOCKED`：无法识别安全工具链/包管理命令、缺少必要授权、环境不可用或存在范围外生产缺陷；
- `COMPLETE`：全部 final gate 同时通过。

不得使用“coverage complete but tests failing”作为完成态。

## 5. 命令安全

运行任何项目命令前读取其 script、alias、wrapper 与配置，分类：

- `SAFE_WITH_DECLARED_OUTPUTS`：只执行测试/coverage，并且所有 cache、report、临时 DB、snapshot 或生成路径已列明；
- `UNSAFE`：安装、升级、迁移、seed、部署、真实外部服务、snapshot update、format/write、破坏性 Git/文件操作；
- `UNKNOWN`：wrapper 或副作用未能证明。

只运行 `SAFE_WITH_DECLARED_OUTPUTS`。测试命令通常不是纯只读，因此必须在运行前记录工作区和受保护路径指纹，并在运行后逐路径对账。

`coverage-tooling-bootstrap` 是单独的批准型安全类别，不把一般依赖安装重新分类为安全。未经用户明确批准时，安装、升级或配置写入仍为 `UNSAFE`；获批后只能执行批准清单中的 coverage 依赖、依赖声明和最小配置变更。安装前后必须记录依赖/锁文件与配置 diff，不得升级无关包。

## 6. 缺少 coverage 工具时的 bootstrap

当 fresh test-only 命令退出成功，但仓库没有可用 coverage 工具、机器可读报告或权威 coverage 命令时：

1. 保持 `RESOLVING`，把 coverage 证据记录为 `CANNOT_VERIFY`；测试成功仅证明 suite 可运行，不能证明 coverage。
2. 检测现有语言、框架、test runner、包管理器、依赖声明和 CI 约定；不得仅凭目录名猜测。
3. 按“复用现有 coverage 方案 → 为现有 runner 补 coverage 插件 → 最后才建议新组合”的顺序形成建议。
4. Django 无既有 coverage 方案时：已有 pytest 则推荐 `pytest-cov`；没有 pytest 则推荐 `pytest + pytest-cov`；只有测试需要 Django pytest 集成时才加入 `pytest-django`。
5. 向用户一次性展示检测依据、推荐依赖和理由、精确安装命令、计划修改的依赖/锁/配置文件、生产源码范围、正式 baseline/final 命令、输出路径和失败恢复方式。
6. 未获批准时停止在批准门禁，不进入 owner batch；无法形成安全且可复现的建议时才进入 `BLOCKED`。
7. 获批后使用项目现有包管理器执行 `coverage-tooling-bootstrap`，只安装已批准依赖并持久化到项目既有依赖声明；禁止仅修改当前临时环境而不更新可复现声明。
8. coverage 原始数据、XML、HTML 和其他报告在命令执行前全部重定向到 `coverage-change-root`。任何先写项目根再移动的方案仍然禁止。
9. bootstrap 修改依赖或配置后，旧证据立即 stale；重新计算 HEAD、工作树、依赖和配置指纹，执行 fresh full baseline。取得精确 numerator/denominator 后才进入 `TRIAGING` 或 `ITERATING`。
10. 安装或配置失败时，保留精确命令、exit code 和 diff，恢复范围仅限本次可证明产生的路径；无法安全恢复则保持 `BLOCKED`，不得宽泛清理工作树。

Django + pytest-cov 的命令语义应等价于：

```text
COVERAGE_FILE=<coverage-change-root>/.coverage
pytest
--cov=<resolved-production-source>
--cov-report=xml:<coverage-change-root>/coverage.xml
--cov-report=html:<coverage-change-root>/htmlcov
```

`COVERAGE_FILE` 使用目标 shell/process environment 的实际语法设置；以上表达跨平台命令语义，不暗示只支持 POSIX。source、omit/exclude、branch mode、metric 和 target 仍须在 baseline 前冻结，不能使用模糊的项目根作为默认生产源码范围。

## 7. 缺口排序与批次循环

缺口候选按“可新增覆盖元素 × 风险/业务价值 × 可隔离性 ÷ 测试成本”排序，不按文件平均分配。优先覆盖纯逻辑、错误分支、服务编排和稳定边界，再处理 DB、异步、网络和并发。

每个 batch 有一个 owner scope，固定循环：

1. 记录目标、HEAD、工作区指纹和最新 fresh 全量证据；
2. 运行最窄 owner gate，证明当前缺口或行为测试为 RED；
3. 添加行为测试，断言可观察结果；mock 调用只能作为辅助断言；
4. 运行目标测试 GREEN；
5. 运行 owner scope suite/coverage GREEN；
6. 检查新增失败、后台线程错误和测试顺序污染；
7. 对账受保护路径与声明产物；
8. 写入或更新 `.fp-coverage/batches/<batch-id>.md`，将发现的生产/测试代码问题去重写入 `issues.md`，再更新有界 `progress.md` 索引。

局部目标只是分解启发式，除非用户明确将其定义为正式验收；它不能替代全仓 final gate。

## 8. 证据、代码问题与恢复

Coverage change 使用以下职责拆分：

```text
fp-docs/changes/<slug>-coverage/
├── issues.md                                  # 首个代码问题出现时懒创建
├── final-report.md                            # completion boundary 生成，核对后进入 COMPLETE
├── .fp-coverage/
│   ├── progress.md                            # 有界当前状态与证据索引
│   ├── contract.md                            # 冻结口径、命令、批准和路径合同
│   ├── baselines/<run-id>.md                  # initial/periodic full evidence
│   ├── batches/<batch-id>.md                  # owner batch RED/GREEN evidence
│   └── verifications/<run-id>.md              # final verification attempts
├── .coverage
├── coverage.xml
└── htmlcov/
```

`progress.md` 不再保存完整事件历史或每条命令输出，只维护当前 state/active batch、HEAD/worktree/config fingerprints、当前 contract revision、latest fresh baseline/final verification、batch/issue 索引和 next action。它必须保持有界、可更新，并且不是 completion authority。恢复时先读 progress，再只加载其直接引用的 contract、最新 fresh evidence、active batch 和 issues；不得为恢复批量读取全部历史 evidence。

`contract.md` 保存 target、metric、numerator/denominator semantics、source/include/omit/exclude、branch mode、test selection、official commands、tooling bootstrap 批准、dependency/config/protected paths 和 declared outputs。合法合同变更增加 revision 并使受影响证据 stale。

每次 initial baseline 或 periodic full refresh 写一个 immutable `baselines/<run-id>.md`；每个稳定 owner batch 写一个 `batches/<batch-id>.md`；每次 final verification 尝试写一个 immutable `verifications/<run-id>.md`。这些文件保存精确命令、安全分类、指纹、test counts、numerator/denominator/percentage、报告 identity、changed/protected paths、side-effect reconciliation 和相关代码问题 ID。失败 evidence 不得删除或覆盖，新的尝试使用新 run ID。

### `issues.md`: unit-test-discovered code issues only

`issues.md` 只记录在单元测试执行、失败归因或补测过程中发现，并有可复现测试/源码证据的代码问题：

- `production-code`：被测生产代码的行为、边界、状态、异常、并发或资源清理缺陷；
- `test-code`：测试 assertion、mock/patch、fixture/helper、清理或顺序隔离代码缺陷。

不得记录 tooling/dependency/environment/CI/coverage-config 问题、普通未覆盖行/branch、owner batch 候选、stale evidence、批准等待、未知副作用或无测试证据的重构建议；这些进入 contract、对应 evidence 或 progress blocker。

首个符合条件的问题出现时才创建 `issues.md`。每条使用稳定 ID `COV-ISSUE-NNN`，字段至少包含 title、Category、Status、Blocking、Developer review、Severity、First seen、Last verified、affected code/symbol、Observation、Expected、Actual/Reproduction、source/test/HEAD evidence、related baseline/batch/verification、Impact、Recommended action、External issue 和 Disposition。

状态固定为 `OPEN | RESOLVED | EXTERNALIZED | ACCEPTED_RISK | INVALID`；开发者审查固定为 `PENDING | REVIEWED`。Agent 不得自行把 `Developer review` 改为 `REVIEWED`，不得删除问题制造干净结果；误报保留为 `INVALID` 并记录 fresh reason。去重键为 `category + affected symbol/path + normalized observed behavior + root-cause identity`；重复发现更新 `Last verified` 和 evidence links，但保留人工 review/disposition。

受管 strict xfail 必须同时关联一个稳定 `COV-ISSUE-*`、一个外部 issue、narrow test、explicit reason 和 strict mode。`OPEN + Blocking: YES` 阻止完成；`RESOLVED` 必须有 fresh test evidence；`EXTERNALIZED`/`ACCEPTED_RISK`/`INVALID` 必须有开发者 disposition，且不能破坏其他 final predicate。非 blocking 的 `PENDING` 问题可以保留，但必须在 final report 的 remaining risks 中显式列出。

### `final-report.md`

只有除报告存在性外的所有技术谓词已由 fresh final verification 证明、流程仍处于 `FINAL_VERIFYING` 的 completion boundary 时，才生成并核对 `final-report.md`；报告成功引用该 verification 后满足最后谓词，再转换为 `COMPLETE`。它是面向开发者的最终总结，不是 completion authority。至少汇总：最终状态、目标/baseline/final/delta、test counts（事实 skipped count 与 unexpected skips disposition 分开）和 exit code、冻结统计合同、owner batches 与工作内容、生产/测试代码问题统计及链接、changed paths、managed xfails、side-effect reconciliation、逐项 completion predicates、remaining risks 和 evidence index。

`BLOCKED`、`CANNOT_VERIFY`、中断或尚未完成时不得生成伪 final report；只更新 progress 和相应 evidence。最终报告生成后如 HEAD/worktree/config 再变化，报告立即 stale，必须重新 final verify 后重写。

恢复时只信任当前 HEAD、工作树和配置指纹仍匹配的证据。任何 evidence 文件和 final report 都不能覆盖 canonical task owner checkbox。

## 9. 完成合同

只有以下条件全部为真才进入 `COMPLETE`：

```text
full_command_exit_code == 0
AND exact_coverage >= target
AND ordinary_failures == 0
AND unexpected_skips == 0
AND every_managed_xfail_is_strict_and_has_one_issue
AND coverage_scope_and_config_match_frozen_baseline
AND protected_paths_have_no_unexplained_diff
AND evidence_matches_current_HEAD_and_worktree
AND every_blocking_code_issue_has_valid_disposition
AND final_report_references_fresh_final_verification
```

若正式工具不能提供精确 numerator/denominator，结果为 `CANNOT_VERIFY`。若 coverage 达标但命令非零，结果为 `BLOCKED` 或 `ITERATING`，绝不宣告完成。

## 10. 禁止的捷径

- 扩大 omit/exclude、缩小 source/include、关闭 branch 或更换 metric 来提高数字；
- 批量 skip/xfail，使用 `strict=False` 隐藏回归，或无 issue 的 xfail；
- 只断言 mock、自我复制生产逻辑、注入 coverage tracer 或删除难测生产代码；
- 复用 stale XML、历史报告、局部结果或理论上界作为 final proof；
- `git reset --hard`、`git clean`、宽泛 `git restore .`、删除来源不明的缓存/报告或覆盖用户修改；
- 未经授权安装或升级依赖；获批的 `coverage-tooling-bootstrap` 也不得超出已展示的 coverage 依赖、声明和最小配置范围；
- 启动真实外部服务、修改生产代码、commit 或 push。

## 11. 文件与集成

新增：

- `skills/fp-coverage/SKILL.md`：完整流程合同；
- `skills/fp-coverage/issues-template.md`：首个单元测试发现的生产/测试代码问题出现时按需加载的问题台账模板；
- `skills/fp-coverage/final-report-template.md`：`FINAL_VERIFYING` completion boundary 按需加载、核对后进入 `COMPLETE` 的最终总结模板；
- `commands/fp-coverage.md`：Claude Code 薄入口；
- `scripts/test-coverage-contract.ps1`：focused 静态合同和防退化测试。

修改：

- `scripts/validate-plugin.ps1`：运行 focused test；
- `README.md`：命令、技能、示例与执行行为；
- `AGENTS.md`：Codex intent 路由和 post-write CodeGraph 同步范围。

不修改插件版本。Codex 从同一 `skills/` 自动发现，不需要单独注册 skill 名单。

## 12. 测试设计

focused contract test 必须验证：

1. skill/command 双入口和共享 workspace 锚点；
2. 技术栈中立，未经批准不得安装依赖；
3. 缺少 coverage 工具时保持 `RESOLVING` + `CANNOT_VERIFY`，输出受控 bootstrap 建议而非终止型 `BLOCKED`；
4. Django fallback 推荐遵循“现有 pytest → `pytest-cov`；无 pytest → `pytest + pytest-cov`；`pytest-django` 按需”；
5. bootstrap 必须展示精确依赖、命令、文件、源码范围和输出路径，且只有明确批准后才能执行；
6. 获批安装只影响 coverage 工具链，不升级无关依赖，并在修改后强制 fresh baseline；
7. 冻结 coverage 口径；
8. fresh baseline、failure triage、owner batch 和 periodic full refresh；
9. final exit code 与 exact coverage 双门；
10. 精确 numerator/denominator，不接受整数或局部估算；
11. stale evidence 和恢复指纹；
12. strict xfail 与 issue 一一对应；
13. 受保护路径副作用对账，禁止宽泛恢复；
14. `progress.md` 是有界恢复索引，不保存完整历史，也不是第二 completion authority；
15. `contract.md`、`baselines/`、`batches/`、`verifications/` 的职责、immutable evidence 和 lazy recovery；
16. `issues.md` 只记录 unit-test-discovered production/test code issues，并锁定 schema、去重、人工 review 和 blocking disposition；
17. `final-report.md` 只在 `FINAL_VERIFYING` completion boundary 生成，核对其 fresh final verification 引用后才进入 `COMPLETE`；
18. `dirty-after-write` 后停止查询旧图，并执行 non-blocking post-write sync；
19. README、AGENTS 和 command checksum 对外合同一致。

完成后运行 focused test、完整插件验证、context 测量、Claude plugin validate、Git diff check，并用同类压力场景验证有 skill 时输出收敛到固定合同。

## 13. 完成标准

- `/fp-coverage` 和 `fp:fp-coverage` 可发现并加载同一 skill；
- skill 在 500 行、30,000 字符限制内；
- 跨技术栈、无硬编码项目阈值；框架推荐只在无既有方案时作为 fallback，Django fallback 明确为 `pytest + pytest-cov` 组合；
- 缺少 coverage 依赖的场景不会只停在终止型 `BLOCKED`：未批准时输出完整 bootstrap 门禁，批准后可受控安装并强制重新 baseline；
- 所有 focused 和全量静态验证通过；
- 压力复测不接受 coverage-only 作弊、不误用 stale evidence、不错误恢复用户文件，并输出固定状态/证据/最终判定；
- 本地 Claude Code 与 Codex 插件运行时同步验证成功；同步失败时如实报告，不影响仓库实现结论。
