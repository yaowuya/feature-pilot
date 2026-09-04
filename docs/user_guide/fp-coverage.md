# `fp-coverage` 用户指南

`fp-coverage` 用于在不改变统计口径、不隐藏测试失败的前提下，将项目的单元测试覆盖率提高到一个明确目标。它先执行 `metric freeze`，再建立 fresh baseline，按可恢复的 owner batch 补充行为测试，最后同时检查正式完整测试是否成功以及 exact coverage 是否达标。

## 什么时候使用

适合以下场景：

- 将 unit test 的 line、statement、branch、function、instruction 或 combined coverage 提高到明确目标；
- 根据机器可读报告持续关闭覆盖缺口；
- 使用项目已有 runner、coverage 工具和 CI 口径建立覆盖率门禁；
- 从中断的覆盖率专项继续执行。

以下场景不应使用：

- 只查询当前覆盖率：使用只读调查；
- 只为一个已明确范围的小功能补少量测试：使用普通执行流程；
- E2E、浏览器或视觉测试专项；
- 只想调整 coverage 配置；
- 修复生产缺陷。`fp-coverage` 默认是 coverage-only，不授权修改生产代码。

## 最短用法

Claude Code：

```text
/fp-coverage 将 line coverage 提高到 <明确目标>，使用项目现有正式测试与 coverage 口径
```

Codex：

```text
fp:fp-coverage 将 line coverage 提高到 <明确目标>，使用项目现有正式测试与 coverage 口径
```

目标必须由本次请求明确给出，或来自用户要求满足的当前权威项目门禁。流程不会根据历史报告、当前本地百分比或最高可见数字猜测 target。

## 开始前必须明确什么

流程首先解析并冻结以下合同：

- `target`：明确阈值；
- `metric`：line、branch、statement、combined 等具体维度；
- numerator / denominator 的精确定义；
- `source/include/omit/exclude` 和 branch mode；
- 正式 test selection、baseline command 与 final command；
- 可写测试/fixture 路径、受保护路径和所有命令副作用；
- `coverage-change-root` 与每个 coverage report 的输出路径；
- 生产缺陷、strict xfail 和外部 issue 的处理策略。

项目现有 test runner、coverage 工具、CI、包管理器、依赖声明和配置是事实源。能够从当前代码、配置或 CI 精确证明的信息不会重复询问；真正会改变统计口径、写入范围或最终验收的未知项才会阻塞。

## 缺少 coverage 工具时

测试能运行不代表 coverage 可以验证。如果 fresh test-only command 成功，但项目没有可信 coverage 工具、机器可读报告或权威 coverage command，流程会：

1. 保持 `RESOLVING`；
2. 将 coverage 结论记为 `CANNOT_VERIFY`；
3. 不进入 owner batch；
4. 按 `prefer-existing-coverage-toolchain` 形成受控建议；
5. 展示 approval-gated `coverage-tooling-bootstrap`，等待明确批准。

建议顺序固定为：

1. 复用已有权威 coverage 工具、CI wrapper 或命令；
2. 为已有 test runner 只补兼容的 coverage plugin；
3. 只有不存在兼容 runner 时，才提出新 runner 与 coverage 组合。

批准门禁必须一次性说明检测依据、精确依赖、安装命令、会修改的依赖/lock/config 路径、生产源码范围、冻结口径、baseline/final commands、报告路径和失败回退边界。未批准时不会安装依赖或写配置。

批准后的 `coverage-tooling-bootstrap` 只允许：

- 使用现有包管理器安装已展示的 coverage 依赖；
- 将它们持久化到项目既有开发/测试依赖声明；
- 只更新这次安装导致的 lock 变化；
- 写入最小必要 coverage 配置；
- 重新计算指纹并运行 fresh baseline。

它不允许升级无关依赖、替换正常工作的 runner、扩大 coverage 配置或顺带修改生产代码。

### Django fallback

只有已证明是 Django 项目且没有既有 coverage 方案时，才使用以下 fallback：

- 已有 pytest：只推荐 `pytest-cov`；
- 没有 pytest：推荐 `pytest + pytest-cov`；
- 只有测试确实需要 Django pytest 集成时才加入 `pytest-django`。

现有 `coverage.py`、tox、nox、CI wrapper 或其他权威方案优先，不能因为熟悉 Django fallback 就覆盖它们。pytest-cov 的跨平台命令语义类似：

```text
COVERAGE_FILE=<coverage-change-root>/.coverage
pytest --cov=<resolved-production-source>
  --cov-report=xml:<coverage-change-root>/coverage.xml
  --cov-report=html:<coverage-change-root>/htmlcov
```

实际执行时使用目标 shell/process environment 的正确语法设置 `COVERAGE_FILE`。

## 状态流

正常主链为：

```text
RESOLVING → BASELINING → TRIAGING → ITERATING → FINAL_VERIFYING → COMPLETE
```

各状态含义：

| 状态 | 含义 |
| --- | --- |
| `RESOLVING` | 解析项目规则、target、metric、范围、命令、写边界和缺工具批准门禁。 |
| `BASELINING` | 记录 HEAD、工作树、配置和环境指纹，运行 fresh 正式 baseline。 |
| `TRIAGING` | 复现并归因 baseline 中的已有失败。 |
| `ITERATING` | 按一个稳定 owner batch 执行 RED、target GREEN、owner GREEN 和副作用对账。 |
| `FINAL_VERIFYING` | 运行冻结口径下的 fresh full-suite final gate。 |
| `BLOCKED` | 安全命令/建议无法证明、授权或环境不可用、存在范围外生产缺陷，或可信证据无法取得。 |
| `COMPLETE` | 全部完成谓词同时成立。 |

`CANNOT_VERIFY` 是对某项证据或结论的判定，不是“测试已成功”的替代完成态。不存在“coverage complete but tests pending”之类的中间完成状态。

## metric freeze 与禁止捷径

fresh baseline 前冻结：

- source/include/omit/exclude；
- branch mode；
- metric 与 target；
- test selection；
- 正式 final command。

流程不能为了提高数字而：

- 扩大 omit/exclude；
- 缩小 source/include；
- 关闭 branch measurement；
- 更换 metric 或 denominator；
- 批量 skip/xfail，或使用 `strict=False`；
- 弱化断言、只验证 mock 调用、复制生产逻辑到测试；
- 使用 stale report、rounded display、local coverage 或 theoretical upper bound 作为最终证明；
- 将 coverage 报告先写项目根再移动。

合法的统计合同变更属于独立、明确批准的范围。变更后旧证据立即 stale，必须重新 baseline，不能作为本轮达标技巧。

## baseline、triage 与 owner batch

fresh baseline 记录精确命令、exit code、工具/环境身份、HEAD 和工作树指纹、test counts、numerator、denominator、percentage、报告身份和副作用。

如果 baseline 有测试失败，先进入 `TRIAGING`。每个失败都要缩小复现并分类，例如生产行为、旧 expectation、fixture/setup、patch 位置、环境依赖、顺序污染、后台任务或 unknown。未完成归因前不能用大批补测掩盖失败。

每个 `owner batch` 只负责一个稳定 owner scope：

1. 记录 batch ID、目标、指纹、最新 fresh 全量证据和缺口排序理由；
2. 运行最窄 gate，观察预期 RED；
3. 添加验证可观察行为的测试；
4. 运行目标测试 GREEN；
5. 运行完整 owner scope GREEN；
6. 检查普通失败、unexpected skips、xfail/XPASS、warning、后台错误和顺序污染；
7. 对账受保护路径与声明输出；
8. 写入 batch evidence，并更新有界恢复索引。

发生足以改变全量结果的多批修改、外部 source/test/config/HEAD 变化，或准备引用旧全量结果时，执行 `periodic full refresh`，重新根据 fresh 报告排序缺口。

## 过程产物

所有过程证据和 coverage 工具报告都位于：

```text
fp-docs/changes/<slug>-coverage/
├── issues.md
├── final-report.md
├── .fp-coverage/
│   ├── progress.md
│   ├── contract.md
│   ├── baselines/<run-id>.md
│   ├── batches/<batch-id>.md
│   └── verifications/<run-id>.md
├── .coverage
├── coverage.xml
├── htmlcov/
└── <other-declared-coverage-reports>
```

其中 `coverage.xml`、`htmlcov/` 和 `.coverage` 只是常见示例。项目使用 LCOV、JSON、JaCoCo XML、Cobertura XML 或其他格式时，也必须在运行前直接重定向到同一个 coverage change 根，禁止 run-then-move。

测试源码和批准 fixture 仍写在项目原有测试路径，以便 runner 和 CI 正常发现。

### split evidence 的职责

- `.fp-coverage/contract.md`：冻结 target、metric、统计 population、命令、批准、依赖/config、受保护路径和声明输出；
- `baselines/`：每次 initial 或 periodic full baseline 的 immutable evidence；
- `batches/`：每个稳定 owner batch 的 RED/GREEN 与对账证据；
- `verifications/`：每次 final verification 尝试，包括失败尝试；
- `.fp-coverage/progress.md`：当前 state、active batch、指纹、contract revision、最新 fresh evidence 链接、batch/issue 摘要、blocker 和 next action。

`progress.md` 是 bounded recovery index，不保存每条命令和完整执行历史，也不是第二个 completion authority。失败 baseline 或 verification 不得覆盖或删除；新尝试使用新的 run ID。

## `issues.md` 记录什么

`issues.md` 在第一个符合条件的问题出现时才创建，只记录单元测试执行、失败归因或补测过程中发现，并有可复现 test/source evidence 的代码问题：

- `production-code`：生产行为、边界、状态、异常、并发或资源清理缺陷；
- `test-code`：assertion、mock/patch、fixture/helper、清理、隔离或测试顺序缺陷。

依赖、环境、CI、coverage config、普通未覆盖行/branch、候选 batch、批准等待、stale evidence、未知副作用和无测试证据的重构建议不进入 `issues.md`。

问题使用稳定 `COV-ISSUE-NNN`，状态为 `OPEN | RESOLVED | EXTERNALIZED | ACCEPTED_RISK | INVALID`。`Developer review` 为 `PENDING | REVIEWED`，Agent 不能自行设置 `REVIEWED`。误报改为 `INVALID` 并保留原因，不能删除以制造干净结果。

## 中断恢复与证据失效

恢复时先读 `.fp-coverage/progress.md`，再只加载它直接引用的 contract、最新 fresh baseline/verification、active batch 和 issues，不批量读取全部历史文件。

以下变化会使相关证据 stale：

- 生产或测试源码；
- coverage/test/build 配置；
- dependency 或 lockfile；
- command 或 test selection；
- runtime/environment；
- branch、merge、rebase、HEAD；
- 无法解释的工作树变化；
- 报告被删除、替换或身份改变。

恢复只信任仍与当前 HEAD、工作树、配置和环境指纹匹配的证据。无法证明归属的用户修改必须保留；不能使用 `git reset --hard`、`git clean`、宽泛 `git restore .` 或 stash 清理。

## 最终双门与 `final-report.md`

进入 `FINAL_VERIFYING` 后，运行冻结范围和 metric 的 fresh full-suite 正式命令。技术谓词先由本次 fresh verification 证明；仍处于 `FINAL_VERIFYING` 的 completion boundary 时，才生成并校验 `final-report.md`，让它引用本次 `.fp-coverage/verifications/<run-id>.md`。报告字段校验通过后，流程才能转换为 `COMPLETE`。

`BLOCKED`、`CANNOT_VERIFY`、`ITERATING`、中断或技术谓词未通过时不生成伪 final report。报告生成后如果 HEAD、工作树或配置再变化，报告立即 stale，必须重新 final verify 并重写。

最低双门是：

```text
full_command_exit_code == 0
AND exact_coverage >= target
```

完整完成谓词为：

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

coverage 达标但命令 exit code 非零时仍是 `ITERATING` 或 `BLOCKED`。正式工具只能给 rounded percentage 而没有精确 counters 时是 `CANNOT_VERIFY`，不能从整数反推精确覆盖率。

## 常见结果如何解释

- **测试通过但没有 coverage 工具**：只证明 suite 可运行；保持 `RESOLVING` + `CANNOT_VERIFY`，等待 bootstrap 决策。
- **coverage 达标但有普通失败**：没有完成，继续 triage 或进入 `BLOCKED`。
- **owner scope 达标**：只是 batch 证据，不能替代 fresh full-suite。
- **存在预期 skip**：事实 `Skipped` 可以非零，但 `unexpected_skips` 必须为零，并记录预期 skip 的 disposition。
- **存在 strict xfail**：必须一条测试对应一个稳定代码问题和一个外部 issue，unexpected pass 必须使 suite 失败。
- **仅剩非 blocking 的 `PENDING` developer review**：可以在其他谓词满足时完成，但必须在 final report 的 remaining risks 中列出。

## 与其他 FeaturePilot 流程的关系

- `fp-start` 不会自动触发覆盖率专项；需要提高覆盖率时单独调用 `fp-coverage`。
- 普通 feature 只缺少少量明确测试时，使用该 feature 的正常执行流程，不必创建覆盖率专项。
- `fp-coverage` 发现生产缺陷时只记录问题并停止相应 coverage-only 工作；修复生产行为需要单独明确授权和合适的执行流程。
- coverage change 根可以引用现有 FeaturePilot change 的 owner task，但 `.fp-coverage/progress.md` 不会替代 canonical task checkbox。
