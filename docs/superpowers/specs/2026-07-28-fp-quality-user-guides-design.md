# FeaturePilot 专项用户指南设计

**日期：** 2026-07-28
**状态：** 已确认，待实施
**范围：** 为 `fp-coverage` 与 `fp-module-review` 新增独立中文用户指南，并接入 README、主线指南和 focused contracts

## 已确认决策

1. 创建两份独立指南：`docs/user_guide/fp-coverage.md` 与 `docs/user_guide/fp-module-review.md`，不合并到一份长文，也不把完整内容塞入 `init-prd-start.md`。
2. 两份指南延续现有 `init-prd-start.md` 风格：面向实际使用者，先给最短命令，再解释适用场景、准备、流程、产物、门禁、恢复、结果和常见误区。
3. `README.md` 提供两份指南的显式链接；`docs/user_guide/init-prd-start.md` 只增加简短专项入口和链接，不复制完整合同。
4. `fp-coverage` 指南必须覆盖：明确 target、metric freeze、缺工具 approval-gated bootstrap、Django fallback、状态流、owner batch、split evidence、code-only `issues.md`、bounded `progress.md`、completion-boundary `final-report.md`、双门和常见结果解释。
5. `fp-module-review` 指南必须覆盖：targets/slug/focus/mode/baseRef、canonical workspace、状态流、scope/baseline/waves、stable `MR-FNNN`、Finding transitions、observable behavior approval、review-only/fix/resume、verification、`COMPLETE_WITH_AWAITING` 与 `fp-final-review` 区别。
6. 叙述默认中文；命令、路径、状态、schema、Finding ID 和完成谓词保留必要英文。
7. 指南不得发明超出当前 skill 的行为；skill 是事实源。后续 skill 合同变化必须通过 focused test 使指南断言失败。
8. 每份 Markdown 不超过 500 行和 30,000 字符；无 placeholder、无客户路径、无固定默认覆盖率。
9. 不修改插件版本，不 commit、不 push，不覆盖并行会话变更。

## `fp-coverage.md` 结构

1. 作用与适用/不适用场景；
2. Claude Code 与 Codex 最短用法；
3. 开始前的 target/metric/toolchain 要求；
4. 缺工具 bootstrap 与 Django fallback；
5. `RESOLVING → BASELINING → TRIAGING → ITERATING → FINAL_VERIFYING → COMPLETE/BLOCKED`；
6. metric freeze 和禁止捷径；
7. coverage change artifact tree；
8. `progress.md`、`contract.md`、baselines/batches/verifications 的职责；
9. `issues.md` 只收 unit-test-discovered production/test code；
10. 中断恢复和 evidence invalidation；
11. completion boundary final report 与 exact coverage/full-suite 双门；
12. 常见结果和误区；
13. 与 `fp-start`、普通执行、生产缺陷修复的关系。

## `fp-module-review.md` 结构

1. 作用与适用/不适用场景；
2. Claude Code 与 Codex 最短用法；
3. 输入与 target ambiguity；
4. `full | review-only | resume`；
5. canonical workspace 和文件 owner；
6. lifecycle states；
7. scoping/baselining 与 command safety；
8. ownership/call-flow waves；
9. stable `MR-FNNN`、proof、severity 与 transitions；
10. observable behavior approval gate；
11. authorized TDD fixing；
12. resume/invalidation；
13. `COMPLETE | COMPLETE_WITH_AWAITING | BLOCKED | CANNOT_VERIFY`；
14. 与 `fp-final-review`、PR review、小 diff review 的关系；
15. full/review-only/resume/多相关目标示例；
16. 常见误区。

## 验证合同

- `scripts/test-coverage-contract.ps1` 读取 coverage guide，检查文件、README/主线指南入口、关键路径/状态/工具/问题/final report 锚点，并拒绝旧 append-only progress、after-COMPLETE report 和默认百分比。
- `scripts/test-module-review-contract.ps1` 读取 module guide，检查文件、README/主线指南入口、canonical workspace、三个 mode、状态、Finding ID/transitions、approval gate、completion states、final-review 区别。
- 两个 focused contracts 检查指南行数/字符数。
- 完成后运行 focused、完整 plugin validator、Claude plugin validation、diff check、独立文档审查和运行时同步。
