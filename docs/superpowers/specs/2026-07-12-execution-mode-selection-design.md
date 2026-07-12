# Execution Mode Selection Design

## Goal

Make execution behavior an explicit user decision after the implementation plan is confirmed. Never infer SDD solely from task count or complexity.

## Two-level gate

### Gate 1: execution strategy

Before loading an execution skill, show two clearly explained choices:

1. **Direct task execution (non-SDD)**
   - Load `fp-execute` and implement the approved task plan directly in the current execution context.
   - Do not create per-task SDD briefs, fresh implementers, review packages, or per-task reviewer agents.
   - Continue through the task list; pause only for a blocking plan conflict, failed validation that cannot be repaired safely, or a decision only the user can make.
   - Best for smaller plans or when lower orchestration overhead is preferred.

2. **SDD execution**
   - Load `fp-execute-sdd` and use a fresh implementer, per-task review package, read-only reviewer, and fix loop for every task.
   - Provides stronger task isolation, recovery evidence, and review gates at the cost of more orchestration and artifacts.
   - Best for medium/large, cross-module, permission/data-sensitive, migration, or UI-contract work.

The assistant may recommend one option with reasons, but a recommendation is not selection. It must wait for the user's explicit choice.

### Gate 2: SDD continuation mode

Ask this gate only after the user selects SDD:

1. **Step-confirmation SDD**
   - Complete one task through implementation, review/fix, checkbox update, and ledger update.
   - Report that task's evidence and wait for explicit confirmation before dispatching the next task.
   - Best when the user wants to inspect every increment or control commits/task boundaries.

2. **Automatic-continuation SDD**
   - Execute the same full per-task SDD quality cycle.
   - After a task is reviewed clean and state is synchronized, immediately dispatch the next eligible task without asking for confirmation.
   - Per-task reports are progress updates, not return points.
   - Continue through all tasks and final whole-change review. Pause only for a true blocker: unresolved product/architecture/security decision, plan conflict, blocked implementation, or exhausted fix loop.
   - Best when the approved plan can run unattended while retaining SDD review rigor.

## Persistence and resume

Record the chosen execution strategy and, for SDD, continuation mode in `.fp-execute/progress.md`. On resume, reuse the recorded choices. Do not ask again unless the record is missing/ambiguous or the user asks to switch modes. Never silently switch modes.

## Validation

Plugin validation must assert that:

- `fp-start` requires an explicit non-SDD versus SDD choice and explains both effects.
- `fp-start` asks for SDD continuation mode only after SDD is selected and explains both effects.
- `fp-execute-sdd` defines both modes.
- Automatic SDD explicitly treats task reports as progress rather than stop/confirmation boundaries and continues until completion unless blocked.
- SDD mode is persisted for resume.
