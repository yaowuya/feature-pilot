# /fp-init Information Layer Design

## Summary

`/fp-init` should evolve from a minimal workspace initializer into the entry point for a FeaturePilot project information layer. The information layer gives downstream SDD phases enough stable, source-backed context to plan, brief, implement, and review safely without turning FeaturePilot into a stale project index.

The design uses four content areas:

1. `fp-docs/manifest.md` — the single global FeaturePilot entry point, read-order contract, precedence rules, artifact inventory, and freshness summary.
2. `fp-docs/settings/` — human-confirmed policy and domain settings, split by concern so `agent.md` stays small.
3. `fp-docs/intel/` — generated, source-backed project facts and discovery pointers.
4. `fp-docs/changes/<slug>/` — per-change context and execution artifacts created by later phases.

The init-owned information layer consists of the first three areas. `changes/<slug>/` consumes that layer and adds change-specific context later.

The current code and actual command output always remain the final truth for current-state facts. Approved change artifacts define target-state requirements. Generated intel is navigation, provenance, and constraint context; it is never proof of current behavior by itself.

## Goals

- Give fresh SDD implementer/reviewer subagents enough project context without relying on controller chat memory.
- Provide one canonical project entry point at `fp-docs/manifest.md`; avoid split `settings/manifest.md` and `intel/manifest.md` entry points.
- Normalize existing project guidance (`CLAUDE.md`, `AGENTS.md`, etc.) into a FeaturePilot read-order contract without duplicating large documents.
- Keep `settings/agent.md` lean by moving frontend-specific rules to `settings/frontend.md` and backend-specific rules to `settings/backend.md`.
- Persist stable command, architecture, contract, security, UI, backend, and unknowns information with source paths and freshness rules.
- Keep `/fp-init` low ceremony: default to a lightweight skeleton plus optional read-only discovery.
- Preserve public-plugin neutrality: no customer-specific component library, vendor, framework, path, or workflow assumptions.

## Non-goals

- Do not build a full code index.
- Do not list every route, component, model, endpoint, file, or dependency.
- Do not install dependencies, run tests, build the app, or call external services during init.
- Do not copy secrets, tokens, local credentials, private endpoint values, or data samples.
- Do not pre-create `fp-docs/changes/`, `fp-docs/archive/`, or `fp-docs/history/` during init.
- Do not keep multiple manifest entry points. `fp-docs/manifest.md` is the only manifest.

## Directory Contract

```text
fp-docs/
  manifest.md                # Single global entry point: read order, precedence, artifacts, freshness
  settings/
    agent.md                 # Optional lean FeaturePilot policy adapter
    frontend.md              # Optional UI/frontend/visual/design-system settings
    backend.md               # Optional backend/API/data/security settings
  intel/
    sources-and-provenance.md
    workspace-map.md
    tech-stack.md
    commands-and-quality-gates.md
    architecture-and-boundaries.md
    contracts.md
    security-data-and-ops.md
    unknowns-and-decisions.md
    refresh-policy.md
    sdd-handoff.md
  changes/<slug>/            # Created by later phases only
    context.md               # Per-change context packet, created by propose/brainstorm
    proposal.md
    design-backend.md
    design-frontend.md
    tasks/
    .fp-execute/
```

`/fp-init` owns `fp-docs/manifest.md`, `settings/`, and `intel/`. Later phases own `changes/<slug>/`.

## Single Manifest Contract

`fp-docs/manifest.md` is the only information-layer entry point. Every FeaturePilot skill should locate `fp-docs/` and read `fp-docs/manifest.md` first when it exists. From there it discovers the relevant settings and intel files.

### Required sections

```markdown
# FeaturePilot Manifest

Schema: fp-manifest/v1
Generated: <timestamp>
Project root: `<detected local path>`
FP docs root: `fp-docs/`
Git SHA: <sha or unavailable>
Working tree: clean | dirty | unavailable

## Precedence

<current-state and target-state precedence summary>

## Settings Files

| File | Role | Authoritative For | Status |
| --- | --- | --- | --- |
| `settings/agent.md` | Lean FeaturePilot policy adapter | workflow, constraints, external-doc pointers | present/missing/stale |
| `settings/frontend.md` | Frontend/UI/visual settings | UI implementation and visual acceptance | present/missing/stale/not-applicable |
| `settings/backend.md` | Backend/API/data/security settings | backend implementation and backend acceptance | present/missing/stale/not-applicable |

## Intel Artifacts

| File | Purpose | Freshness | Sources |
| --- | --- | --- | --- |

## External Project Docs

| File | Priority | Notes |
| --- | --- | --- |

## Critical Unknowns

- <unknowns that affect planning or SDD safety>

## Consumption Rules

- Read this manifest first.
- Pull only relevant settings and intel for the current phase.
- Current code and command output win for current-state facts.
- Approved change artifacts win for target-state requirements.
- Re-open referenced source files before editing.
- Re-run commands before claiming validation.
- Missing referenced paths make dependent sections stale.
- UI-related phases must read `settings/frontend.md` when present.
- Backend-related phases must read `settings/backend.md` when present.
```

`Project root` is local-machine context only. Cross-machine use should rediscover the root and refresh stale local paths where needed.

## Read Order and Precedence

Read order:

1. `fp-docs/manifest.md`
2. Relevant `fp-docs/settings/*.md` listed by the manifest
3. Relevant `fp-docs/intel/*.md` listed by the manifest
4. Current change artifacts under `fp-docs/changes/<slug>/`
5. Current source code, tests, configs, and command output

Truth precedence depends on the question being answered.

For current-state facts — what the system currently does, which files exist, which commands pass, which APIs are present — precedence is:

1. User's explicit instruction about how to inspect or constrain the work
2. Current code and actual command output
3. Human-confirmed settings
4. Generated intel
5. Historical archive/history

For target-state requirements — what this change must implement, what scope is approved, what acceptance criteria apply — precedence is:

1. User's explicit instruction
2. Approved active change artifacts under `fp-docs/changes/<slug>/`
3. Human-confirmed settings
4. Generated intel
5. Current code as evidence of the starting point
6. Historical archive/history

Change artifacts can define desired future behavior, but they cannot be used as proof that the current code already has that behavior. Current code can prove the starting state, but it cannot override an approved target requirement unless the conflict is surfaced to the user or the plan explicitly changes.

If settings or intel contradict current code, agents must report the contradiction and verify against current code. They must not silently implement from stale intel.

## Settings Layer

Settings are human-confirmed, editable policy/configuration files. They are not scan dumps. They should stay concise and point to intel/source files for details.

### `settings/agent.md`

Purpose: lean FeaturePilot policy adapter.

It should be created only with user approval. If project-level `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `CURSOR.md`, or `.cursorrules` exists, init should still create or update `fp-docs/manifest.md` and may offer to create a small `settings/agent.md` adapter pointing to the authoritative docs instead of skipping FeaturePilot normalization entirely. Creating or updating the adapter also requires explicit user approval.

Stable sections:

- Purpose
- Authoritative Project Docs
- Workflow Preferences
- General Allowed / Forbidden Areas
- General Validation Expectations
- General Security / Data Notes, limited to cross-domain policy; concrete API/auth/data/ops rules belong in `settings/backend.md`
- Unknowns

`agent.md` must not absorb frontend or backend domain detail when `frontend.md` or `backend.md` is a better home. It should link to those files instead.

### `settings/frontend.md`

Purpose: dedicated frontend/UI/visual settings.

It should contain:

- frontend framework and source locations, if confirmed
- component library sources
- component import/prefix patterns, if source-backed
- token/style source files
- route/state/API-client patterns
- layout/responsive rules
- Figma/screenshot handling rules
- local preview/browser verification expectations
- visual acceptance checklist format
- frontend-specific Unknowns

When this file exists and a change involves UI, `fp-brainstorm`, `fp-plan-frontend`, `fp-execute-sdd`, `fp-ui-spec`, `fp-ux-spec`, `fp-figma`, `fp-grill-me`, `fp-prd-grill-me`, and `fp-review` must treat it as a required settings source.

### `settings/backend.md`

Purpose: dedicated backend/API/data/security settings.

It should contain:

- backend framework and source locations, if confirmed
- API routing/controller/service patterns
- data model/schema/migration conventions
- request/response/error envelope conventions
- auth/session/permission rules
- multi-tenant / workspace / project / account isolation rules, if applicable
- background job or async processing conventions
- backend validation/test command expectations
- observability/audit/logging expectations
- backend-specific Unknowns

When this file exists and a change involves backend/API/data/security behavior, `fp-propose`, `fp-brainstorm`, `fp-plan-backend`, `fp-execute-sdd`, `fp-grill-me`, `fp-prd-grill-me`, and `fp-review` must treat it as a required settings source.

## Intel Layer

Intel artifacts are generated, source-backed project facts and discovery pointers. They are navigation and provenance, not user-confirmed policy.

### `intel/sources-and-provenance.md`

Records:

- files read during init
- config/package files inspected
- commands run, if any read-only commands are used
- facts inferred
- facts user-confirmed
- confidence per section
- facts that could not be confirmed
- freshness basis for every source-backed artifact:
  - source path
  - git blob SHA or content hash when available
  - generated-at Git SHA
  - artifact depends-on source list
  - dirty working tree caveat

Hard-stale checks compare the recorded freshness basis with the current source files. If a source path is missing, its content hash/blob SHA changed, or the recorded generated-at state cannot be compared safely, the dependent artifact is stale and must be verified just-in-time before use.

### `intel/workspace-map.md`

Records high-level navigation only:

- repo root
- monorepo/app/package boundaries
- source roots
- test roots
- backend entry points
- frontend entry points
- config roots
- migration locations
- asset/style/token locations
- generated/vendor/forbidden areas

It must not list every source file or every route/component/model/API.

### `intel/tech-stack.md`

Records source-backed tooling facts:

- languages
- frameworks detected from manifests/configs
- package managers and lockfiles
- test frameworks
- lint/type/build tools
- CI config locations
- app/runtime entry hints

Unknown or ambiguous stack facts must be written as Unknown, not guessed.

### `intel/commands-and-quality-gates.md`

Records command discovery and validation expectations:

- install/bootstrap command
- targeted unit test pattern
- backend test command/pattern
- frontend test command/pattern
- lint command
- typecheck command
- build command
- E2E/visual command
- local app start/preview command
- environment prerequisites
- read-only versus mutating command classification
- expected evidence format for pass/fail

If a command cannot be proven from project files, mark it Unknown. Do not invent commands.

### `intel/architecture-and-boundaries.md`

Records stable architecture and placement rules:

- backend framework and layering
- frontend framework and organization
- data layer
- service/business layer
- API layer
- routing
- state management
- component organization
- async/background job patterns
- external integration boundaries
- deployment/config boundaries
- where new functionality should usually go
- areas that require explicit plan approval before editing

### `intel/contracts.md`

Records baseline interface conventions:

- API URL/method naming
- request/response shape
- error envelope
- pagination/filter/sort semantics
- auth/session model
- permission/action naming
- multi-tenant / workspace / project / account isolation rules, if applicable
- frontend API client wrapper conventions
- state/store/action naming
- component prop/event conventions
- compatibility expectations

This is a convention map, not a complete API catalog.

### `intel/security-data-and-ops.md`

Records safety and production constraints:

- sensitive data handling
- secret/config policy
- audit/logging expectations
- permission negative-test expectations
- migration/rollback rules
- data retention
- external service failure behavior
- performance constraints
- deployment-order risks

### `intel/unknowns-and-decisions.md`

A living ledger for project-level unknowns and confirmations.

Format:

```markdown
# Unknowns and Decisions

## Unknowns

| Area | Unknown | Impact | Resolve By | Blocking For |
| --- | --- | --- | --- | --- |

## Decisions

| Date | Decision | Source | Applies To |
| --- | --- | --- | --- |
```

Downstream behavior:

- `fp-propose` turns relevant unknowns into scope or requirement questions.
- `fp-brainstorm` turns relevant unknowns into architecture decisions.
- `fp-plan` blocks when unknowns affect exact files, contracts, security, UI tokens, backend contracts, or validation commands.
- `fp-execute-sdd` must not dispatch implementers when unresolved unknowns affect task safety.
- `fp-review` can report ignored unknowns as process or correctness findings.

### `intel/refresh-policy.md`

Defines staleness and refresh triggers.

Hard-stale when:

- referenced paths disappear
- package manifests/config files change
- test/build/lint config changes
- route/API framework config changes
- auth/permission files change
- component library/theme/token files change
- any depends-on source recorded in `sources-and-provenance.md` has a changed git blob SHA or content hash

Soft-stale when:

- git SHA differs from recorded SHA
- working tree was dirty during generation
- profile is old
- current change touches an area covered by an intel artifact

On stale intel, agents verify just-in-time. They do not silently rewrite settings or proceed from stale facts.

### `intel/sdd-handoff.md`

Purpose: project-level context contract for `fp-execute-sdd`.

Required sections:

- mandatory context files
- Global Constraints sources
- allowed edit-scope rules
- validation evidence requirements
- commit policy
- review severity policy
- visual evidence requirements
- backend evidence requirements
- security/data constraints
- common project pitfalls
- stale intel handling

## Init Flow

### Step 1: Locate or create workspace

Walk upward from the current directory to find `fp-docs/`. If absent, create:

```text
fp-docs/
fp-docs/settings/
fp-docs/intel/
```

Do not create `changes/`, `archive/`, or `history/`.

### Step 2: Create skeleton information layer

If missing, create:

- `fp-docs/manifest.md`
- `fp-docs/intel/unknowns-and-decisions.md`
- `fp-docs/intel/refresh-policy.md`
- `fp-docs/intel/sdd-handoff.md`

Existing files are never overwritten without explicit user approval. Skeleton `sdd-handoff.md` may contain Unknown placeholders, but it must include the required sections and links to `fp-docs/manifest.md` so `fp-execute-sdd` has a stable handoff contract even before full discovery. If `sdd-handoff.md` is missing when SDD execution starts, `fp-execute-sdd` must block and ask the user to generate or repair the information layer before dispatching fresh implementers.

### Step 3: Detect external project docs

Check for:

- `CLAUDE.md`
- `.claude/CLAUDE.md`
- `AGENTS.md`
- `.agents/AGENTS.md`
- `GEMINI.md`
- `CURSOR.md`
- `.cursorrules`

Record discovered docs in `fp-docs/manifest.md`. Do not duplicate large docs into `settings/agent.md`.

### Step 4: Ask about optional settings

Ask whether to create or update:

- `settings/agent.md`
- `settings/frontend.md`, if UI/frontend is detected or user expects UI work
- `settings/backend.md`, if backend/API/data/security behavior is detected or user expects backend work

Generated settings must be concise, editable, and use Unknowns instead of guesses.

### Step 5: Ask about lightweight discovery

Recommended default prompt:

```markdown
FeaturePilot can build a lightweight, read-only project information layer for SDD.
It records source roots, validation command discovery, architecture boundaries, contracts, security/data notes, frontend/backend settings pointers, provenance, and Unknowns.
It does not install dependencies, run tests, build, index every file, or copy secrets.

Generate this information layer now?

1. Generate lightweight intel (recommended)
2. Skeleton only
```

If approved, perform a read-only discovery pass.

### Step 6: Discovery boundaries

Allowed:

- read project docs and manifests
- inspect package/build/test/lint/config files
- inspect obvious source/test root structure
- inspect a small number of representative adjacent files only when needed to identify conventions
- record sources, confidence, hashes/blob SHAs where available, and unknowns

Forbidden:

- installing packages
- running test/build/lint commands unless explicitly approved
- exhaustive repository indexing
- reading secrets or env values
- copying credentials or data samples
- guessing unsupported frameworks, design systems, tokens, backend frameworks, API envelopes, or command names

### Step 7: Report result

After init, report:

- workspace path
- global manifest path
- settings created/skipped
- intel artifacts created/skipped
- external docs detected
- discovery mode used
- critical unknowns
- next commands: `/fp-prd <idea>` or `/fp-start <feature>`

## Downstream Skill Changes

### Shared header for all workflow skills

Replace “read any settings files that exist” with:

1. Locate `fp-docs/`.
2. If `fp-docs/manifest.md` exists, read it first.
3. Read relevant settings and intel listed there.
4. If UI/frontend is involved and `settings/frontend.md` exists, read it as a required source.
5. If backend/API/data/security behavior is involved and `settings/backend.md` exists, read it as a required source.
6. Treat settings/intel as navigation and constraints; verify exact implementation facts against current code.
7. Use the two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.

### Skill update matrix

| Skill / command | Must read | May write | Project-level intel update allowed? | Notes |
| --- | --- | --- | --- | --- |
| `fp-init` | existing `fp-docs/manifest.md`, external project docs, existing settings/intel | `fp-docs/manifest.md`, `settings/`, `intel/` | yes, with overwrite approval | Owns information-layer creation and refresh. |
| `fp-prd` | manifest, relevant settings/intel, unknowns | `changes/<slug>/prd.md` | no | Uses unknowns to ask requirement questions. |
| `fp-prd-grill-me` | manifest, relevant settings/intel, unknowns | PRD critique output or PRD updates with approval | no | Pressure-tests requirements against project constraints and unresolved unknowns. |
| `fp-start` | manifest, relevant settings/intel | active change artifacts | no | Orchestrates read order for the full chain. |
| `fp-quick` | manifest, relevant settings/intel, unknowns, `settings/frontend.md` for UI work, `settings/backend.md` for backend/API/data/security work | product code only after user approval; no `changes/` artifacts | no | Uses intel as discovery pointers, still verifies current code and obeys required domain settings. |
| `fp-propose` | manifest, workspace map, architecture, contracts, frontend/backend settings, unknowns | `changes/<slug>/proposal.md`, optional `context.md` | no | Turns relevant unknowns into proposal questions or assumptions. |
| `fp-brainstorm` | manifest, architecture, contracts, security/data, frontend/backend settings as relevant | `design-backend.md`, `design-frontend.md`, optional context updates | no by default | Project-level decisions require explicit user approval. |
| `fp-grill-me` | manifest, relevant settings/intel, unknowns, frontend/backend settings as relevant | design/assumption critique output or artifact updates with approval | no | Pressure-tests design assumptions against current-state facts, target requirements, and unknowns. |
| `fp-ui-spec` | manifest, `settings/frontend.md`, UI-related intel | UI spec artifacts only when invoked | no | Must not ignore generated frontend settings. |
| `fp-ux-spec` | manifest, `settings/frontend.md`, UX-related intel | UX spec artifacts only when invoked | no | Must not invent UX rules when settings say Unknown. |
| `fp-figma` | manifest, `settings/frontend.md`, workspace map, command gates | design excerpts or UI files depending on phase | no | Must verify current framework and file conventions. |
| `fp-plan` | manifest, relevant settings/intel, active proposal/design | task plans | no | Blocks on unknowns that affect exact tasks. |
| `fp-plan-backend` | manifest, `settings/backend.md`, backend architecture/contracts/security/commands | `tasks/plan-backend.md` | no | Exact contracts must be reverified from current code. |
| `fp-plan-frontend` | manifest, `settings/frontend.md`, frontend architecture/contracts/commands | `tasks/plan-frontend.md` | no | UI tokens/components must be source-backed. |
| `fp-execute` | manifest, relevant settings/intel, task plan | code, progress ledger if applicable | no | Inline execution still respects info-layer gates. |
| `fp-execute-sdd` | manifest, `sdd-handoff.md`, relevant settings/intel, task plan | `.fp-execute/*`, code via subagents | no | Must brief fresh subagents with relevant info-layer excerpts. |
| `fp-review` | manifest, relevant settings/intel, active artifacts, diff | review report | no | Reviews product correctness and process drift. |
| `fp-archive` | manifest for archive policy, active artifacts | archive/history | no | Does not use historical archive as implementation context. |

### `fp-propose`

Use intel to frame exploration, but still search current code for feature-specific facts. Relevant unknowns become proposal questions or assumptions.

### `fp-brainstorm`

Use intel contracts, architecture, security, frontend settings, and backend settings to shape Socratic questions and options. Decisions made here should update change-level artifacts, not project intel unless the user explicitly wants to update project rules.

### `fp-plan` / `fp-plan-backend` / `fp-plan-frontend`

Use intel for Global Constraints and discovery pointers. Exact files, APIs, components, permissions, and test commands must be verified against current code. Blocking unknowns must stop the plan.

### `fp-execute-sdd`

Before dispatching an implementer, the controller must read relevant settings/intel and copy task-relevant excerpts into the task brief.

Add to task brief template:

```markdown
## Relevant Project Information Layer

- FeaturePilot manifest:
- Relevant settings excerpts:
- Relevant workspace-map excerpts:
- Relevant commands/quality-gates excerpts:
- Relevant architecture/contracts excerpts:
- Relevant security/data excerpts:
- Relevant frontend settings excerpts:
- Relevant backend settings excerpts:
- Unknowns checked:
- Staleness notes:
```

Implementers must re-open referenced source files before editing. Reviewers must check whether stale or missing information affected the task.

### `fp-review`

Review should check both product correctness and process drift:

- Was `fp-docs/manifest.md` read?
- Were required settings/intel files read?
- Were relevant unknowns resolved before plan/execution?
- Were validation commands source-backed and actually run?
- Did implementation violate workspace boundaries or contracts?
- Did UI work use `settings/frontend.md` when present?
- Did backend/API/data/security work use `settings/backend.md` when present?
- Did any task rely on stale intel instead of current code?

## Freshness and Conflict Rules

- Generated intel is never authoritative proof of current behavior.
- Approved change artifacts define target behavior and acceptance criteria, but not current-state facts.
- Missing referenced paths mark the section stale.
- Stale sections require just-in-time verification.
- Contradictions between settings and code must be surfaced when they affect implementation choices.
- Settings are only overwritten with explicit approval.
- Project-level decisions belong in settings or `unknowns-and-decisions.md`; change-specific decisions belong in `changes/<slug>/`.
- Downstream skills may propose project-level decisions or ask the user to confirm them, but they must not silently write project-level decisions or update settings/intel without explicit user approval.

## Migration Path

1. Update `fp-init` command and skill to create `fp-docs/manifest.md`, `settings/`, `intel/` skeleton, and optional lightweight discovery.
2. Remove the old split-entrypoint design from docs: no `settings/manifest.md`, no `intel/manifest.md`, no `frontend_design.md`.
3. Add templates for `fp-docs/manifest.md`, `settings/agent.md`, `settings/frontend.md`, `settings/backend.md`, and intel files in the skill text.
4. Update README and AGENTS to document the information layer.
5. Update shared workflow headers to read `fp-docs/manifest.md` first.
6. Update all references from `frontend_design.md` to `frontend.md`.
7. Update backend-related workflows to read `settings/backend.md` when present.
8. Update `fp-execute-sdd/task-brief-template.md` with the Relevant Project Information Layer section.
9. Update implementer/reviewer prompts to require source-file reopening and stale-intel handling.
10. Update `fp-review` to review information-layer consumption.
11. Verify with metadata checks and grep for old assumptions.

## Acceptance Criteria

- `/fp-init` creates `fp-docs/manifest.md`, `fp-docs/settings/`, and `fp-docs/intel/` skeleton without creating change/archive/history directories.
- There is exactly one manifest entry point: `fp-docs/manifest.md`.
- Existing manifest/settings/intel files are not overwritten without approval.
- `fp-docs/manifest.md` defines read order, precedence, artifact inventory, freshness, and consumption rules.
- `settings/agent.md` is lean and does not absorb frontend/backend domain details.
- `settings/frontend.md` replaces `settings/frontend_design.md`.
- `settings/backend.md` exists as the backend-specific settings home.
- Lightweight discovery writes source-backed facts and Unknowns, not guesses.
- Downstream skills read `fp-docs/manifest.md` first when present.
- UI flows explicitly consume `settings/frontend.md` when present.
- Backend/API/data/security flows explicitly consume `settings/backend.md` when present.
- `fp-execute-sdd` task briefs include relevant information-layer excerpts.
- `fp-review` can detect ignored/stale information-layer issues.
- The plugin remains customer-agnostic and does not hardcode framework/vendor/component assumptions.
