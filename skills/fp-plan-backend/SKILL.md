---
name: fp-plan-backend
description: Use when generating backend FeaturePilot task plans from proposal.md and design-backend.md, especially for server-side model, service, API, serializer, IAM, provider, URL, and test changes.
---


## FeaturePilot workspace and customer settings

Before choosing output paths, component-library guidance, test commands, or workflow rules, locate the target project's FeaturePilot workspace:

1. Walk upward from the current working directory to find `fp-docs/`.
2. If `fp-docs/` does not exist and this phase needs to create artifacts, create only the directories this phase actually writes to. Do not pre-create empty directories for other phases.
   - Most phases only need `fp-docs/changes/` for their artifacts.
   - Only the archive phase (`fp-archive`) creates `fp-docs/archive/` and `fp-docs/history/`.
   - `fp-init` only creates `fp-docs/settings/` and writes optional config files inside it.
3. Read any settings files that exist. Do not create or overwrite customer settings unless the user explicitly asks.

Settings are optional. If a file is missing, fall back to current project code, adjacent implementations, and public defaults only; never invent customer-specific conventions.

Recommended settings file:

- `fp-docs/settings/agent.md` — optional project-specific FeaturePilot rules, including workflow, paths, component library, design system, UI tokens, Figma mapping, and visual review requirements.

Public plugin rule: do not hardcode any customer component library, vendor, component prefix, design token, or workflow policy in public skills. Customer-specific rules may be described in optional `fp-docs/settings/agent.md`.

---

# FeaturePilot Backend Plan

后端计划 skill 必须自包含。不要依赖外部 skill 目录、外部 `writing-plans` 文件或本机绝对路径。

本 skill 已融合 `writing-plans` 的核心方法：先锁定文件结构，再拆成小粒度 TDD 任务；每个任务必须给出精确文件、测试代码、运行命令、最小实现、通过验证和提交步骤。

## 输入

【立即用工具执行】读取：
- `fp-docs/changes/<slug>/proposal.md`
- `fp-docs/changes/<slug>/design-backend.md`

不要读取 `design-frontend.md` 来生成后端任务。

## 输出

固定写入：

```text
fp-docs/changes/<slug>/tasks/plan-backend.md
```

不要写入其它计划目录。不要输出 subagent/inline execution 选择；`fp-start` 会在用户确认计划后进入 `fp-execute`。

## Scope Check

生成计划前先检查 `proposal.md` 和 `design-backend.md`：

- 如果后端设计覆盖多个互相独立的子系统，先提示应拆成多个后端计划；不要把无关子系统塞进一个任务链。
- 每个计划必须能独立产出可测试的软件增量。
- 如果某个需求点只在 proposal 中出现、未在 design-backend 中设计，标记为设计缺口，不要自行补设计后继续生成任务。

## File Structure

定义任务前，先写“文件结构规划”章节，列出将创建或修改的文件，以及每个文件的职责。

要求：

- 文件职责必须清晰，避免一个任务同时堆模型、服务、接口、权限、测试等无关改动。
- 按现有项目模式组织文件；不要为了计划而引入全新分层。
- 如果现有文件过大且本次必须修改，可在计划中加入小范围拆分任务，但必须说明拆分服务于当前需求。
- 文件结构规划决定后续任务拆分；后续任务不得凭空新增未规划文件，除非在任务中先说明原因并更新规划。

## Plan Header

`plan-backend.md` 必须以如下 header 开头：

```markdown
# <功能名> Backend Implementation Plan

> **For agentic workers:** REQUIRED FLOW: Use `fp-execute` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** <一句话说明本计划交付什么后端能力>

**Architecture:** <2-3 句话说明后端实现策略、边界和关键依赖>

**Tech Stack:** <涉及的后端框架、测试框架、权限/IAM/任务/数据库等关键技术>

## Global Constraints

从 `proposal.md`、`design-backend.md`、项目约束文件（如 `CLAUDE.md`）中提取对所有任务都生效的硬约束。必须写精确值，不要泛泛而谈：
- 版本/框架/依赖限制。
- API 返回结构、错误码、权限 action、命名约定。
- 数据迁移、兼容性、安全、性能或审计要求。
- 明确禁止的做法，例如不得新增第三方依赖、不得跳过权限负向测试。

这些约束默认约束每个任务，后续任务不得与之冲突。

---
```

## Task Granularity

每个任务必须足够小，通常 2-5 分钟可完成。任务边界以“能独立经历一次测试与 review”为准：脚手架、配置、文档和注册步骤应并入真正需要它们的交付任务；只有当 reviewer 可以合理地批准一个任务、拒绝另一个任务时，才拆成两个任务。

一个任务内的每个步骤只能做一件事：

- 写失败测试。
- 运行测试确认失败。
- 写最小实现。
- 运行测试确认通过。
- 提交本任务变更。

超过该粒度时继续拆分。

## Backend Task Order

按真实设计范围和项目现有分层拆任务。常见边界包括：

```text
Data/schema changes → business/service logic → request/response contracts → API handlers/routes → permissions/integration points → tests
```

但不要机械生成不存在的层：

- 没有模型变更，不要创建 Model 任务。
- 没有序列化器变更，不要创建 Serializer 任务。
- 权限、provider、注册入口、异步任务、数据迁移等边界必须独立成可验证任务。

## Backend Interface Ledger

生成任务前必须先在 `plan-backend.md` 中建立后端接口账本；每个任务的 `**Interfaces:**` 必须与账本一致。

接口包括：
- Python 函数、类、方法、构造参数、返回值。
- service 层输入/输出对象和错误类型。
- serializer/schema 字段、校验规则、只读/必填规则。
- ViewSet/API action、HTTP method、URL name、request body、query params、response shape、status code。
- URL/router 注册名称。
- IAM/permission action mapping。
- provider / registry / hook 的注册 key、调用签名和生命周期。
- 异步任务、定时任务、外部服务 client 的调用契约。

格式：

```markdown
## Backend Interface Ledger

| Interface | Owner Task | Contract | Consumers | Verification |
| --- | --- | --- | --- | --- |
| `<具体接口名>` | Task N | `<签名、payload、字段或 action mapping>` | `<后续任务或现有调用方>` | `<测试文件::测试名>` |
```

后续任务只能消费账本中已经存在的接口、现有代码中的接口，或本任务明确创建的接口；不得临时发明未声明的函数、字段、action、route 或 provider key。

## Task Format

每个任务必须使用以下格式：

````markdown
### Task N: <组件或行为名称>

**Files:**
- Create: `exact/path/to/new_file.py`
- Modify: `exact/path/to/existing_file.py:123-145`
- Test: `tests/exact/path/to/test_file.py`

**Reasoning:**
- 为什么这个任务独立。
- 它覆盖 proposal/design-backend 中的哪个需求点。
- 它完成后系统行为有什么可验证变化。

**Interfaces:**
- Consumes: <本任务依赖的现有模型/service/API/权限 action，或前序任务产出的函数、类、字段、路径；写出精确签名/字段名/URL>
- Produces: <后续任务、前端或外部调用方会依赖的函数、类、字段、URL、返回结构、权限 action；写出精确契约>
- Contract checks: <如何验证 consumes/produces 的契约一致，例如 serializer 字段、API schema、权限映射或导入路径>

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test_file.py::test_specific_behavior -v`
Expected: FAIL with `<具体失败信息>`

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test_file.py::test_specific_behavior -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test_file.py exact/path/to/changed_file.py
git commit -m "feat: add specific behavior"
```
````

## No Placeholders

计划中禁止出现以下失败写法：

- `TBD`、`TODO`、`implement later`、`fill in details`
- `后续实现`、`按需处理`、`类似上面`
- `Add appropriate error handling`
- `Write tests for the above`
- 只描述“做什么”，不给测试代码、实现片段或精确命令
- 后续任务引用前面没有定义、也不是现有代码里的函数、类、字段、路径

如果代码片段过长，仍需给出关键函数、类、字段和调用结构；不能用一句“按设计实现”替代。

## Backend Boundary Checks

后端计划必须显式覆盖这些边界中实际涉及的部分：

- 数据模型和迁移。
- service/business logic。
- serializer/schema。
- ViewSet/API action。
- URL/router。
- IAM/permission/action mapping。
- resource provider / registry / hooks。
- 异步任务、定时任务、外部服务调用。
- 单元测试、集成测试、导入验证、权限负向测试。

不涉及的边界不要生成空任务。

## Coverage Matrix

`plan-backend.md` 必须在任务列表之后包含覆盖矩阵，用来证明 proposal 和 design-backend 的后端范围都被任务覆盖。

格式：

```markdown
## Coverage Matrix

| Source | Requirement / Boundary | Tasks | Verification |
| --- | --- | --- | --- |
| proposal.md | `<具体需求点>` | Task N | `pytest ...::test_name -v` |
| design-backend.md | `<具体设计点>` | Task N, Task M | `pytest ...::test_name -v` |
| Backend boundary | `<IAM/permission/provider/migration/API 等实际涉及边界>` | Task N | `pytest ...::test_name -v` |
```

规则：
- 每个 proposal 后端需求点必须映射到至少一个任务，或明确标记为 `Design gap — not planned`。
- 每个 design-backend 设计点必须映射到至少一个任务和一个验证命令。
- `Backend Boundary Checks` 中实际涉及的边界必须在矩阵中出现。
- 不涉及的边界不要写占位行。

## Self-Review

写入 `plan-backend.md` 后，必须自审并直接修正问题：

1. **Spec coverage:** 逐条检查 proposal 和 design-backend 的后端范围点，确认每一点都能指向 Coverage Matrix 中的具体任务；未设计点只能标记为设计缺口。
2. **Global constraints coverage:** 确认所有跨任务硬约束都进入 `Global Constraints`，且没有任务违反这些约束。
3. **Interface ledger consistency:** 确认 `Backend Interface Ledger`、每个任务的 `Consumes` / `Produces` / `Contract checks`、代码片段、测试代码和后续消费者使用同一组函数、类、字段、URL、权限 action、provider key。
4. **Placeholder scan:** 搜索 No Placeholders 中的红旗词。发现后直接改掉。
5. **Type consistency:** 后续任务使用的函数、类、字段、路径必须和前序任务或现有代码一致。
6. **Task independence:** 每个任务必须能独立执行、独立验证、独立提交，并且小到值得一次独立 review。
7. **Backend boundary coverage:** 检查模型/迁移、service、serializer/schema、ViewSet/API、URL/router、IAM/permission、provider/registry/hooks、异步任务、外部服务调用中实际涉及的部分都有任务和验证。
8. **Command validity:** 测试命令必须是项目中可执行的真实命令，不要写泛泛的 `run tests`。

自审完成后，向 `fp-plan` 返回计划路径、任务摘要、Coverage Matrix 摘要和设计缺口列表（如有）。
