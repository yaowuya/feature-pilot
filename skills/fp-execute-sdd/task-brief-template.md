# FeaturePilot SDD Task Brief Template

Use this template for `.fp-execute/briefs/<task-id>-brief.md` before dispatching an implementer.
Apply the artifact-layout contract already loaded by the owning `fp-execute-sdd` controller. The controller is a canonical-first Consumer: preserve manifest order and block every historical or dual structural conflict before creating a task brief.

```markdown
# Task Brief: <task-id>

## Identity

- Change slug: `<slug>`
- Task owner file: `<exact resolved task-owner path>`
- Resolved plan context: `<selected small plan OR split index plus manifest-ordered fragments; two-end overview only when applicable>`
- Task heading: `<exact heading>`
- Task checkbox line: `<exact checkbox text>`
- Declared dependencies: `<exact task IDs or None>`
- Controller base SHA: `<sha before task starts>`

## Resolved Artifact Contract

Record each logical artifact independently so mixed small/split changes remain explicit.

| Logical artifact | Canonical entry | Resolution mode | Ordered fragments |
| --- | --- | --- | --- |
| PRD | `<prd.md OR prd/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |
| Proposal | `<proposal.md OR proposal/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |
| Backend design | `<design/backend.md OR design/backend/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |
| Frontend design | `<design/frontend.md OR design/frontend/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |
| Backend plan | `<tasks/plan-backend.md OR tasks/backend/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |
| Frontend plan | `<tasks/plan-frontend.md OR tasks/frontend/00-index.md>` | `small | split | N/A` | `<manifest-ordered paths or N/A>` |

- Structural conflict: `None` (otherwise no brief may be dispatched)
- Task ownership proof: <manifest Kind=`tasks` row; `tasks`-kind owner; unique task owner path and checkbox>
- Overview applicability: `<two-end overview path and derived totals, or single-end/no overview>`
- Structural validation: `<missing/unindexed fragment, duplicate owner/ID/checkbox, forbidden checkbox, dependency/cycle checks>`

## Status

- Ledger status before dispatch: `not-started | reopened | retry`
- Prior attempts: `<none or report/review paths>`

## Applicable Global Constraints

Copy only the constraints that apply to this task, preserving exact values:

- `<constraint>`

## Relevant Project Information Layer

This section is the task's `dynamic task context`. Missing optional information-layer files are `N/A`, not blockers.

| Source class | Exact path/query | Relevant excerpt or result | Freshness/revalidation |
| --- | --- | --- | --- |
| Manifest | `<fp-docs/manifest.md or N/A>` | `<minimal relevant entry or N/A>` | `<current read or N/A>` |
| Settings | `<relevant settings path or N/A>` | `<minimal constraint or N/A>` | `<current read or N/A>` |
| Project facts | `<intel/project-facts.md section or N/A>` | `<navigation hint or N/A>` | `<source revalidation or N/A>` |
| Change artifacts | `<PRD/proposal/design/task paths>` | `<minimal approved contract>` | `current canonical artifact` |
| Current source/config | `<exact paths>` | `<current fact>` | `re-opened before dispatch` |
| CodeGraph/native search candidates | `<query/result paths or N/A>` | `<candidate only or N/A>` | `<verified in current source or N/A>` |
| Human-owned unknowns/decisions | `<intel/unknowns.md, intel/decisions.md, legacy hint, or N/A>` | `<relevant item or N/A>` | `<resolved status or N/A>` |

- Legacy compatibility hints used: `<manifest-listed legacy paths or N/A>`
- Staleness/conflict notes: `<live calculation or N/A>`

## Proposal / Design Context

Relevant proposal excerpt:

> `<minimal exact excerpt>`

Relevant design excerpt:

> `<minimal exact excerpt>`

## Visual Evidence Manifest (frontend/UI only)

Evidence root: `.fp-execute/visual/<task-id>/<case-id>/`. Each planned case owns `manifest.md`, `reference.png`, `current.png`, and optional `diff.png`.

| Case ID | Approved design source | Figma node | revision/time | Frame/variant | variables / Auto Layout / assets | Runtime route | Scenario/state | Viewport | DPR | Locale | Theme | Deterministic non-sensitive fixture | Reference path | Current path | Diff path / missing diff | Mask | Acceptance rule | Command/tool | Failure class | Result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `<case-id>` | `<approved Figma/static design source>` | `<node or N/A>` | `<revision/time or approved-source time>` | `<frame/variant>` | `<available context or N/A>` | `<real target runtime route>` | `<scenario/state>` | `<viewport>` | `<DPR>` | `<locale>` | `<theme>` | `<stable fixture; no secrets or production/customer data>` | `.fp-execute/visual/<task-id>/<case-id>/reference.png` | `.fp-execute/visual/<task-id>/<case-id>/current.png` | `.fp-execute/visual/<task-id>/<case-id>/diff.png` or `N/A: <missing diff explanation>` | `<masks or None>` | `<case-specific rule>` | `<project-configured replay command/tool>` | `<core visual/non-core cosmetic>` | `PENDING` |

- Source/runtime provenance: `reference.png` is from the approved Figma/static design source; a local runtime screenshot must not replace it. `current.png` is from the real target runtime/Runtime route with stable data and stable environment. The optional diff may be missing only with explanation and must not hide missing source/runtime.
- Browser interaction evidence is separate from screenshot evidence and must exercise the approved states.
- Figma design context: `<get_design_context record for specified node with revision/time, frame/variant, variables/Auto Layout/assets when Figma MCP is available; explicitly approved source or blocker when unavailable; do not fabricate>`

- Provenance: reference.png -> approved Figma/static design source; current.png -> real target runtime.
- Local runtime screenshot must not replace reference.png. current.png requires stable data and stable environment. Optional diff/missing diff explanation must not hide absent core source/runtime evidence.
- Evidence channels: browser interaction evidence is separate from screenshot evidence; browser interaction evidence must exercise approved states, and screenshot evidence must record case artifacts.

## Prior Interfaces Available

List only interfaces already produced by completed tasks or existing code that this task may consume:

| Interface | Source | Contract | Evidence |
| --- | --- | --- | --- |
| `<name>` | `<existing code or task-id>` | `<signature/field/URL/component contract>` | `<file/test/review path>` |

## Full Task Text

Paste the complete task from the approved plan here, including `Files`, `Reasoning`, `Depends on`, `Interfaces`, TDD steps, validation commands, and commit step.

```text
<full task text>
```

## Allowed Scope

The implementer may edit only:

- `<path>`

The implementer must not edit:

- Neighboring tasks.
- Proposal/design/plan files.
- Unrelated refactors, formatting-only files, or dependency files unless explicitly named above.

## Required Evidence

The report must include:

- Failing test command and key failure output, unless the task explicitly uses alternative validation.
- Passing test/lint/build/visual command and key output.
- Interface/contract evidence.
- Case-level Visual Evidence rows and `manifest.md`/`reference.png`/`current.png`/optional `diff.png` provenance, plus separate browser interaction evidence.
- Commit SHA(s).
- Known concerns or blockers.
```
