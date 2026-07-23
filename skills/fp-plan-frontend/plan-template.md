# Frontend Plan Output Template

Read this file only after current framework/components/state conventions, design contracts, and source-backed Visual Checks are known.

Apply the artifact-layout contract already loaded by `fp-plan-frontend` before writing. Select one mutually exclusive output representation:

- **Small form:** `tasks/plan-frontend.md` owns the complete logical template below in section order.
- **Split form:** `tasks/frontend/00-index.md` owns only the `Order / File / Kind / Owns` manifest. A `context` fragment owns the header, Global Constraints, file structure, and page goal; an `interface` fragment owns component/state/API/route/interaction/style/visual contracts; one or more `tasks` fragments own the executable TDD tasks; a `coverage` fragment owns proposal/design/visual coverage and verification mapping. Do not create `tasks/plan-frontend.md` in split form.

叙述性内容默认使用中文；代码、命令、路径、技术标识符、API 字段以及本模板要求精确匹配的英文 schema 标题保留必要英文。若用户或目标项目设置明确指定其他语言，按共享优先级执行。

Every output file stays within 500 lines and 30,000 characters. Only a `tasks`-kind fragment may contain the task checkbox from the Task section; index, context, interface, and coverage files never contain executable task checkboxes. Across task fragments, `frontend-NNN` IDs remain unique and continue without resetting.

````markdown
# <Feature> Frontend Plan

> **For agentic workers:** REQUIRED FLOW: Use `fp-execute` to implement this plan task-by-task. Only task markers use checkbox (`- [ ] **Task frontend-NNN: ...**`) syntax for tracking; substeps are plain ordered instructions.

## Global Constraints
- Framework/runtime: <source>
- Component library/design system: <source>
- Script/style conventions: <source>
- Visual source: <Figma / screenshot / existing page / settings>
- Visual evidence runner: <project-configured browser runner/tool, or explicit authorized setup task>
- Verification commands: <source>

## File Structure

| Path | Action | Responsibility |
| --- | --- | --- |
| `<exact/path>` | create / modify / test | `<single responsibility in this change>` |

## 1. Page goal and visual contract

## 2. Frontend Interface and Visual Contract

| Contract | Owner Task | Exact shape / behavior | Consumers | Verification |
| --- | --- | --- | --- | --- |
| `<API/state/route/component/event/style/visual contract>` | `frontend-NNN` | `<source-backed contract>` | `<consumer>` | `<exact check>` |

### 2.1 Component tree and template outline
### 2.2 State/API/interaction design
### 2.3 Style and responsive design
### 2.4 Visual and UX checks

### 2.5 Visual Evidence Manifest

Evidence root: `.fp-execute/visual/<task-id>/<case-id>/`. Each case writes `manifest.md`, `reference.png`, `current.png`, and optional `diff.png`.

| Case ID | Approved design source | Figma node | revision/time | Frame/variant | variables / Auto Layout / assets | Runtime route | Scenario/state | Viewport | DPR | Locale | Theme | Deterministic non-sensitive fixture | Reference path | Current path | Diff path / missing diff | Mask | Acceptance rule | Command/tool | Failure class | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `<case-id>` | `<approved Figma/static design source>` | `<node or N/A>` | `<revision/time or approved-source time>` | `<frame/variant>` | `<available context or N/A>` | `<real target runtime route>` | `<scenario/state>` | `<viewport>` | `<DPR>` | `<locale>` | `<theme>` | `<deterministic fixture; no secrets or production/customer data>` | `.fp-execute/visual/<task-id>/<case-id>/reference.png` | `.fp-execute/visual/<task-id>/<case-id>/current.png` | `.fp-execute/visual/<task-id>/<case-id>/diff.png` or `N/A: <missing diff explanation>` | `<dynamic-region masks or None>` | `<case-specific measurable rule; no global pixel threshold>` | `<project-configured runner/tool and replay command>` | `<core visual/non-core cosmetic>` | `PENDING` |

`reference.png` comes only from the approved Figma/static design source; a local runtime screenshot must not replace it. `current.png` comes from the real target runtime and Runtime route with stable data and stable environment. The optional diff may be absent only with an explicit missing diff explanation and must not hide missing core source/runtime evidence. Browser interaction evidence is separate from screenshot evidence and exercises all approved states.

- Provenance: reference.png -> approved Figma/static design source; current.png -> real target runtime.
- Local runtime screenshot must not replace reference.png. current.png requires stable data and stable environment. Optional diff/missing diff explanation must not hide absent core source/runtime evidence.
- Evidence channels: browser interaction evidence is separate from screenshot evidence; browser interaction evidence must exercise approved states, and screenshot evidence must record case artifacts.

## 3. Task breakdown

- [ ] **Task frontend-NNN: <component or behavior>**

**Files:**
- Create: `exact/path/to/new-file`
- Modify: `exact/path/to/existing-file`
- Test: `exact/path/to/test-file`

**Reasoning:**
- <independent boundary, source requirement, observable result>

**Depends on:** <None or exact existing task IDs>

**Interfaces:**
- Consumes: <existing/prior API/state/route/component/visual contract>
- Produces: <new API/state/route/component/classes/events/visual structure>
- Contract checks: <exact verification>

**Step 1: Write the failing test**

```<project test language>
<focused test for the observable component/state/interaction contract>
```

**Step 2: Run test to verify it fails**

Run: `<exact focused test command>`
Expected: FAIL with `<specific missing behavior>`

**Step 3: Write minimal implementation**

**Template Outline:**
- <source-backed container hierarchy, project components, slots, props, events>

**Script/State Outline:**
- <existing project pattern, state, derived values, loading, handlers>

**Style Outline:**
- <source-backed tokens/classes/layout/spacing>

**Visual / UX Checks:**
- <check traceable to design/settings/Figma/screenshot/current code>
- Visual Evidence cases: <Case IDs owned by this task; core cases require both trustworthy reference.png and real-runtime current.png>

**Step 4: Run test to verify it passes**

Run: `<exact focused test command>`
Expected: PASS

Run: `<exact lint/build/visual verification when required>`
Expected: `<specific success result>`

**Step 5: Commit**

```bash
git add <exact changed and test files>
git commit -m "feat: add specific frontend behavior"
```

## Coverage Matrix

| Source | Requirement / Visual boundary | Tasks | Verification |
| --- | --- | --- | --- |
| proposal.md | `<frontend requirement>` | `frontend-NNN` | `<exact command/check>` |
| design/frontend.md or indexed fragment | `<component/interaction/visual contract>` | `frontend-NNN` | `<exact command/check>` |
| Frontend boundary | `<actual route/state/style/visual boundary>` | `frontend-NNN` | `<exact command/check>` |
````

The logical order is Header and Global Constraints → File Structure and Page Goal → Frontend Interface and Visual Contract → Task bodies → Coverage Matrix. Splitting changes file ownership, not this content order or the TDD and visual detail required by each task.
