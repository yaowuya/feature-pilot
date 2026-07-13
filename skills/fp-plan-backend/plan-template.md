# Backend Plan Output Template

Read this file only after scope, file structure, constraints, interfaces, task order, and coverage have been derived from current evidence.

Read `../_shared/artifact-layout.md` before writing. Select one mutually exclusive output representation:

- **Small form:** `tasks/plan-backend.md` owns the complete logical template below in section order.
- **Split form:** `tasks/backend/00-index.md` owns only the `Order / File / Kind / Owns` manifest. A `context` fragment owns Header, Global Constraints, and file structure; an `interface` fragment owns Backend Interface Ledger; one or more `tasks` fragments own the executable TDD tasks; a `coverage` fragment owns Coverage Matrix. Do not create `tasks/plan-backend.md` in split form.

叙述性内容默认使用中文；代码、命令、路径、技术标识符、API 字段以及本模板要求精确匹配的英文 schema 标题保留必要英文。若用户或目标项目设置明确指定其他语言，按共享优先级执行。

Every output file stays within 500 lines and 30,000 characters. Only a `tasks`-kind fragment may contain the task checkbox from the Task section; index, context, interface, and coverage files never contain executable task checkboxes. Across task fragments, `backend-NNN` IDs remain unique and continue without resetting.

## Header

```markdown
# <功能名> Backend Implementation Plan

> **For agentic workers:** REQUIRED FLOW: Use `fp-execute` to implement this plan task-by-task. Only task markers use checkbox (`- [ ] **Task backend-NNN: ...**`) syntax for tracking; substeps are plain ordered instructions.

**Goal:** <交付能力>

**Architecture:** <实现策略、边界、关键依赖>

**Tech Stack:** <source-backed technologies>

## Global Constraints

- <exact version/dependency/contract/permission/migration/security/performance constraint>

## File Structure

| Path | Action | Responsibility |
| --- | --- | --- |
| `<exact/path>` | create / modify / test | `<single responsibility in this change>` |
```

## Backend Interface Ledger

```markdown
## Backend Interface Ledger

| Interface | Owner Task | Contract | Consumers | Verification |
| --- | --- | --- | --- | --- |
| `<name>` | `backend-NNN` | `<signature/payload/fields/action>` | `<consumer>` | `<test::name>` |
```

## Task

````markdown
- [ ] **Task backend-NNN: <组件或行为名称>**

**Files:**
- Create: `exact/path/to/new_file.py`
- Modify: `exact/path/to/existing_file.py:123-145`
- Test: `tests/exact/path/to/test_file.py`

**Reasoning:**
- <independent boundary, source requirement, observable result>

**Depends on:** <None or exact existing task IDs>

**Interfaces:**
- Consumes: <exact existing/prior contract>
- Produces: <exact contract for later consumers>
- Contract checks: <exact verification>

**Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/path/test_file.py::test_specific_behavior -v`
Expected: FAIL with `<specific reason>`

**Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/path/test_file.py::test_specific_behavior -v`
Expected: PASS

**Step 5: Commit**

```bash
git add tests/path/test_file.py exact/path/to/changed_file.py
git commit -m "feat: add specific behavior"
```
````

## Coverage Matrix

```markdown
## Coverage Matrix

| Source | Requirement / Boundary | Tasks | Verification |
| --- | --- | --- | --- |
| proposal.md | `<requirement>` | `backend-NNN` | `<exact command/test>` |
| design/backend.md or indexed fragment | `<design contract>` | `backend-NNN`, `backend-MMM` | `<exact command/test>` |
| Backend boundary | `<actual boundary>` | `backend-NNN` | `<exact command/test>` |
```

The logical order is Header and Global Constraints → File Structure → Backend Interface Ledger → Task bodies → Coverage Matrix. Splitting changes file ownership, not this content order or the TDD detail required by each task.
