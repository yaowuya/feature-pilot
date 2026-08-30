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

## Figma Capability and Preservation Context (when applicable)

- Capability ledger: `<.fp-execute/figma-capabilities.md or N/A>`
- Preservation contract: `<.fp-execute/figma-preservation.md or N/A>`
- Required `FIGCAP-*`: `<exact IDs or None>`
- Required `PRES-*`: `<exact IDs or None>`
- Browser capability resolution: `<project runner | Playwright browser extension | local playwright-cli | customer choice pending | unavailable>`
- UI source rule: `Figma only | no trustworthy Figma UI design; prototype FUNCTION_SCOPE_ONLY`

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

## UI/E2E Delivery Contract (frontend/UI only)

Read the shared staged contract and resolve this table by the same stable Task ID + Case ID as the Visual Evidence Manifest. Do not copy visual-manifest fields: reference the visual row instead.

| Case ID | Visual Evidence Manifest reference | UI Delivery Level | Source-derived condition / requirement | E2E Applicability | Lifecycle stage | Visual reviewer handoff | E2E evidence root | Coverage matrix | E2E verifier handoff | Cleanup / blocker |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `<case-id>` | `<canonical plan row and .fp-execute/visual/<task-id>/<case-id>/manifest.md>` | `static-only | interactive | business-flow` | `<source/requirement reference>` | `REQUIRED | N/A with rationale` | `SOURCE_READY | STATIC_UI_READY | VISUAL_REVIEW_PASS | INTERACTION_READY | FRONTEND_E2E_PASS | BLOCKED` | `.fp-execute/reviews/<task-id>-<case-id>-visual-review-<visual-attempt>.md` / `<pending or verdict>` | `.fp-execute/e2e/<task-id>/<case-id>/` or `N/A` | `.fp-execute/e2e/<task-id>/<case-id>/coverage-matrix.md` or `N/A` | `<independent verifier path/status or N/A>` | `<cleanup result or BLOCKED rationale>` |

- The controller persists `<visual-attempt>` per Task ID + Case ID independently from task-review `reviewAttempt` / `reviewScopeId`, initializes it to 0, increments it immediately before each visual dispatch, and permits dispatched values 1..3 only. It passes current reviewed HEAD to the visual reviewer. Each visual review artifact records start/end plus SHA-256 for manifest/reference/current/optional diff and is never overwritten; visual retries do not consume task-review attempts. Freshness failure after visual attempt 3 is `BLOCKED` and never creates attempt 4.
- `static-only` records both E2E path fields as `N/A` and creates no E2E scaffolding; this is valid only after visual pass and an evidence-backed reason. `interactive` and `business-flow` need the independent verifier's real-browser `FRONTEND_E2E_PASS`.
- The implementer produces `STATIC_UI_READY` evidence but never self-confirms `VISUAL_REVIEW_PASS`; the controller dispatches the fresh visual reviewer and persists its case-level artifact first. The implementer may prepare `INTERACTION_READY`, but never self-confirm `FRONTEND_E2E_PASS`; the controller dispatches the E2E verifier only after `VISUAL_REVIEW_PASS`.
- This is recovery/verification evidence only. The task-owner checkbox remains the sole plan-completion authority.

### Browser Capability Authority (interactive/business-flow only)

| Case ID | Target frontend root | Browser capability | Customer approval / choice | Allowed real E2E test paths and scope | Runner/config status |
| --- | --- | --- | --- | --- | --- |
| `<case-id>` | `<exact frontend root>` | `<existing project runner / browser extension / local playwright-cli>` | `<reuse / customer-runs exact command / one-time FeaturePilot authorization / unavailable>` | `<exact allowed real-E2E test paths and task scope>` | `<existing runner/config path and preservation status>` |

- The controller fills this authority record before verifier dispatch. A missing, unresolved, unavailable, or out-of-scope value is `BLOCKED`; the verifier must consume these values rather than infer them. The record never authorizes a project dependency, lockfile, configuration, CI, or browser-component change.

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
- Required `FIGCAP-*` browser-visible results and required `PRES-*` before/after replay results.
- Browser capability resolution and any non-PASS reason that prevents overall Figma completion.
- Case-level Visual Evidence rows and `manifest.md`/`reference.png`/`current.png`/optional `diff.png` provenance, plus separate browser interaction evidence.
- Separate UI/E2E Delivery Contract rows with lifecycle, fresh visual-review handoff/result, independent E2E verifier handoff/result, E2E/coverage evidence paths, cleanup, and `BLOCKED` rationale.
- Commit SHA(s).
- Known concerns or blockers.
```
