# /fp-init Information Layer Design

## Summary

`/fp-init` should evolve from a minimal workspace initializer into the entry point for a FeaturePilot project information layer. The information layer gives downstream SDD phases enough stable, source-backed context to plan, brief, implement, and review safely without turning FeaturePilot into a stale project index.

The design uses three layers:

1. `fp-docs/settings/` — human-confirmed policy and settings.
2. `fp-docs/intel/` — generated, source-backed project facts and discovery pointers.
3. `fp-docs/changes/<slug>/` — per-change context and execution artifacts created by later phases.

The current code and actual command output always remain the final truth. Generated intel is navigation, provenance, and constraint context; it is never proof of current behavior by itself.

## Goals

- Give fresh SDD implementer/reviewer subagents enough project context without relying on controller chat memory.
- Normalize existing project guidance (`CLAUDE.md`, `AGENTS.md`, etc.) into a FeaturePilot read-order contract without duplicating large documents.
- Persist stable command, architecture, contract, security, UI, and unknowns information with source paths and freshness rules.
- Keep `/fp-init` low ceremony: default to a lightweight skeleton plus optional read-only discovery.
- Preserve public-plugin neutrality: no customer-specific component library, vendor, framework, path, or workflow assumptions.

## Non-goals

- Do not build a full code index.
- Do not list every route, component, model, endpoint, file, or dependency.
- Do not install dependencies, run tests, build the app, or call external services during init.
- Do not copy secrets, tokens, local credentials, private endpoint values, or data samples.
- Do not pre-create `fp-docs/changes/`, `fp-docs/archive/`, or `fp-docs/history/` during init.

## Directory Contract

```text
fp-docs/
  settings/
    manifest.md              # Settings entry point and precedence rules
    agent.md                 # Optional human-editable FeaturePilot policy adapter
    frontend_design.md       # Optional UI/visual/design-system rules
  intel/
    manifest.md              # Intel entry point and freshness summary
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

`/fp-init` owns `settings/` and `intel/`. Later phases own `changes/<slug>/`.

## Read Order and Precedence

Every FeaturePilot skill should locate `fp-docs/` and read `fp-docs/settings/manifest.md` first when it exists. From there it discovers the relevant settings and intel files.

Read order:

1. `fp-docs/settings/manifest.md`
2. `fp-docs/intel/manifest.md`
3. Relevant `fp-docs/settings/*.md`
4. Relevant `fp-docs/intel/*.md`
5. Current change artifacts under `fp-docs/changes/<slug>/`
6. Current source code, tests, configs, and command output

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

### `settings/manifest.md`

Purpose: canonical entry point for settings and intel.

Required sections:

```markdown
# FeaturePilot Settings Manifest

Schema: fp-settings-manifest/v1
Generated: <timestamp>
Project root: `<detected local path>`
FP docs root: `fp-docs/`

`Project root` is local-machine context only. Cross-machine use should rediscover the root and refresh stale local paths where needed.

## Precedence

<truth precedence summary>

## Settings Files

| File | Role | Authoritative For | Status |
| --- | --- | --- | --- |

## Intel Entry

- `fp-docs/intel/manifest.md`

## External Project Docs

| File | Priority | Notes |
| --- | --- | --- |

## Consumption Rules

- Current code and command output always win over generated intel.
- Missing referenced paths make that section stale.
- UI-related phases must read `frontend_design.md` when present.
```

### `settings/agent.md`

Purpose: human-editable FeaturePilot policy adapter.

It should be created only with user approval. If project-level `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `CURSOR.md`, or `.cursorrules` exists, init should still create or update the manifest and may offer to create a small adapter pointing to the authoritative docs instead of skipping FeaturePilot normalization entirely. Creating or updating the adapter also requires explicit user approval.

Stable sections:

- Purpose
- Authoritative Project Docs
- Workflow Preferences
- Allowed / Forbidden Areas
- Validation Expectations
- Security / Data Notes
- Unknowns

### `settings/frontend_design.md`

Purpose: dedicated UI/visual settings.

It should contain:

- component library sources
- component import/prefix patterns, if source-backed
- token/style source files
- route/state/API-client patterns
- layout/responsive rules
- Figma/screenshot handling rules
- local preview/browser verification expectations
- visual acceptance checklist format
- Unknowns

When this file exists and a change involves UI, `fp-brainstorm`, `fp-plan-frontend`, `fp-execute-sdd`, `fp-ui-spec`, `fp-ux-spec`, `fp-figma`, `fp-grill-me`, `fp-prd-grill-me`, and `fp-review` must treat it as a required settings source.

## Intel Layer

### `intel/manifest.md`

Purpose: entry point and status table for generated intel.

Required sections:

```markdown
# FeaturePilot Intel Manifest

Schema: fp-intel/v1
Generated: <timestamp>
Git SHA: <sha or unavailable>
Working tree: clean | dirty | unavailable

## Artifacts

| File | Purpose | Freshness | Sources |
| --- | --- | --- | --- |

## Critical Unknowns

- <unknowns that affect SDD safety>

## Consumption Rules

- Use intel as navigation and constraints.
- Re-open referenced source files before editing.
- Re-run commands before claiming validation.
- Do not use intel as proof of current behavior.
```

### `sources-and-provenance.md`

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

### `workspace-map.md`

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

### `tech-stack.md`

Records source-backed tooling facts:

- languages
- frameworks detected from manifests/configs
- package managers and lockfiles
- test frameworks
- lint/type/build tools
- CI config locations
- app/runtime entry hints

Unknown or ambiguous stack facts must be written as Unknown, not guessed.

### `commands-and-quality-gates.md`

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

### `architecture-and-boundaries.md`

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

### `contracts.md`

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

### `security-data-and-ops.md`

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

### `unknowns-and-decisions.md`

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
- `fp-plan` blocks when unknowns affect exact files, contracts, security, UI tokens, or validation commands.
- `fp-execute-sdd` must not dispatch implementers when unresolved unknowns affect task safety.
- `fp-review` can report ignored unknowns as process or correctness findings.

### `refresh-policy.md`

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

### `sdd-handoff.md`

Purpose: project-level context contract for `fp-execute-sdd`.

Required sections:

- mandatory context files
- Global Constraints sources
- allowed edit-scope rules
- validation evidence requirements
- commit policy
- review severity policy
- visual evidence requirements
- security/data constraints
- common project pitfalls
- stale intel handling

## Init Flow

### Step 1: Locate or create workspace

Walk upward from the current directory to find `fp-docs/`. If absent, create:

```text
fp-docs/settings/
fp-docs/intel/
```

Do not create `changes/`, `archive/`, or `history/`.

### Step 2: Create skeleton information layer

If missing, create:

- `fp-docs/settings/manifest.md`
- `fp-docs/intel/manifest.md`
- `fp-docs/intel/unknowns-and-decisions.md`
- `fp-docs/intel/refresh-policy.md`
- `fp-docs/intel/sdd-handoff.md`

Existing files are never overwritten without explicit user approval. Skeleton `sdd-handoff.md` may contain Unknown placeholders, but it must include the required sections and links to both manifests so `fp-execute-sdd` has a stable handoff contract even before full discovery. If `sdd-handoff.md` is missing when SDD execution starts, `fp-execute-sdd` must block and ask the user to generate or repair the information layer before dispatching fresh implementers.

### Step 3: Detect external project docs

Check for:

- `CLAUDE.md`
- `.claude/CLAUDE.md`
- `AGENTS.md`
- `.agents/AGENTS.md`
- `GEMINI.md`
- `CURSOR.md`
- `.cursorrules`

Record discovered docs in `settings/manifest.md`. Do not duplicate large docs into `agent.md`.

### Step 4: Ask about optional settings

Ask whether to create or update:

- `settings/agent.md`
- `settings/frontend_design.md`, if UI is detected or user expects UI work

Generated settings must be concise, editable, and use Unknowns instead of guesses.

### Step 5: Ask about lightweight discovery

Recommended default prompt:

```markdown
FeaturePilot can build a lightweight, read-only project information layer for SDD.
It records source roots, validation command discovery, architecture boundaries, contracts, security/data notes, UI settings pointers, provenance, and Unknowns.
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
- record sources, confidence, and unknowns

Forbidden:

- installing packages
- running test/build/lint commands unless explicitly approved
- exhaustive repository indexing
- reading secrets or env values
- copying credentials or data samples
- guessing unsupported frameworks, design systems, tokens, or command names

### Step 7: Report result

After init, report:

- workspace path
- settings manifest path
- intel manifest path
- settings created/skipped
- external docs detected
- discovery mode used
- critical unknowns
- next commands: `/fp-prd <idea>` or `/fp-start <feature>`

## Downstream Skill Changes

### Shared header for all workflow skills

Replace “read any settings files that exist” with:

1. Locate `fp-docs/`.
2. If `fp-docs/settings/manifest.md` exists, read it first.
3. If `fp-docs/intel/manifest.md` exists, read relevant intel listed there.
4. If UI is involved and `settings/frontend_design.md` exists, read it.
5. Treat settings/intel as navigation and constraints; verify exact implementation facts against current code.
6. Use the two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.

### Skill update matrix

| Skill / command | Must read | May write | Project-level intel update allowed? | Notes |
| --- | --- | --- | --- | --- |
| `fp-init` | existing `settings/manifest.md`, `intel/manifest.md`, external project docs | `settings/`, `intel/` | yes, with overwrite approval | Owns information-layer creation and refresh. |
| `fp-prd` | settings manifest, relevant settings/intel, unknowns | `changes/<slug>/prd.md` | no | Uses unknowns to ask requirement questions. |
| `fp-prd-grill-me` | settings manifest, relevant settings/intel, unknowns | PRD critique output or PRD updates with approval | no | Pressure-tests requirements against project constraints and unresolved unknowns. |
| `fp-start` | settings manifest, intel manifest, relevant settings/intel | active change artifacts | no | Orchestrates read order for the full chain. |
| `fp-quick` | settings manifest, relevant settings/intel, unknowns | product code only after user approval; no `changes/` artifacts | no | Uses intel as discovery pointers, still verifies current code. |
| `fp-propose` | manifests, workspace map, architecture, contracts, unknowns | `changes/<slug>/proposal.md`, optional `context.md` | no | Turns relevant unknowns into proposal questions or assumptions. |
| `fp-brainstorm` | manifests, architecture, contracts, security/data, frontend settings when UI | `design-backend.md`, `design-frontend.md`, optional context updates | no by default | Project-level decisions require explicit user approval. |
| `fp-grill-me` | manifests, relevant settings/intel, unknowns, frontend settings when UI | design/assumption critique output or artifact updates with approval | no | Pressure-tests design assumptions against current-state facts, target requirements, and unknowns. |
| `fp-ui-spec` | manifests, `frontend_design.md`, UI-related intel | UI spec artifacts only when invoked | no | Must not ignore generated frontend settings. |
| `fp-ux-spec` | manifests, `frontend_design.md`, UX-related intel | UX spec artifacts only when invoked | no | Must not invent UX rules when settings say Unknown. |
| `fp-figma` | manifests, `frontend_design.md`, workspace map, command gates | design excerpts or UI files depending on phase | no | Must verify current framework and file conventions. |
| `fp-plan` | manifests, relevant settings/intel, active proposal/design | task plans | no | Blocks on unknowns that affect exact tasks. |
| `fp-plan-backend` | manifests, backend architecture/contracts/security/commands | `tasks/plan-backend.md` | no | Exact contracts must be reverified from current code. |
| `fp-plan-frontend` | manifests, `frontend_design.md`, frontend architecture/contracts/commands | `tasks/plan-frontend.md` | no | UI tokens/components must be source-backed. |
| `fp-execute` | manifests, relevant settings/intel, task plan | code, progress ledger if applicable | no | Inline execution still respects info-layer gates. |
| `fp-execute-sdd` | manifests, `sdd-handoff.md`, relevant settings/intel, task plan | `.fp-execute/*`, code via subagents | no | Must brief fresh subagents with relevant info-layer excerpts. |
| `fp-review` | manifests, relevant settings/intel, active artifacts, diff | review report | no | Reviews product correctness and process drift. |
| `fp-archive` | manifests for archive policy, active artifacts | archive/history | no | Does not use historical archive as implementation context. |

### `fp-propose`

Use intel to frame exploration, but still search current code for feature-specific facts. Relevant unknowns become proposal questions or assumptions.

### `fp-brainstorm`

Use intel contracts, architecture, security, and frontend design settings to shape Socratic questions and options. Decisions made here should update change-level artifacts, not project intel unless the user explicitly wants to update project rules.

### `fp-plan` / `fp-plan-backend` / `fp-plan-frontend`

Use intel for Global Constraints and discovery pointers. Exact files, APIs, components, permissions, and test commands must be verified against current code. Blocking unknowns must stop the plan.

### `fp-execute-sdd`

Before dispatching an implementer, the controller must read relevant settings/intel and copy task-relevant excerpts into the task brief.

Add to task brief template:

```markdown
## Relevant Project Information Layer

- Settings manifest:
- Intel manifest:
- Relevant settings excerpts:
- Relevant workspace-map excerpts:
- Relevant commands/quality-gates excerpts:
- Relevant architecture/contracts excerpts:
- Relevant security/data excerpts:
- Relevant frontend design excerpts:
- Unknowns checked:
- Staleness notes:
```

Implementers must re-open referenced source files before editing. Reviewers must check whether stale or missing information affected the task.

### `fp-review`

Review should check both product correctness and process drift:

- Were required settings/intel files read?
- Were relevant unknowns resolved before plan/execution?
- Were validation commands source-backed and actually run?
- Did implementation violate workspace boundaries or contracts?
- Did UI work use `frontend_design.md` when present?
- Did any task rely on stale intel instead of current code?

## Freshness and Conflict Rules

- Generated intel is never authoritative proof of current behavior.
- Approved change artifacts define target behavior and acceptance criteria, but not current-state facts.
- Missing referenced paths mark the section stale.
- Stale sections require just-in-time verification.
- Contradictions between settings and code must be surfaced when they affect implementation choices.
- Settings are only overwritten with explicit approval.
- Project-level decisions belong in settings or `unknowns-and-decisions.md`; change-specific decisions belong in `changes/<slug>/`.

## Migration Path

1. Update `fp-init` command and skill to create `settings/` + `intel/` skeleton and optional lightweight discovery.
2. Add templates for settings/intel files in the skill text.
3. Update README and AGENTS to document the information layer.
4. Update shared workflow headers to read `settings/manifest.md` and `intel/manifest.md`.
5. Update `fp-execute-sdd/task-brief-template.md` with the Relevant Project Information Layer section.
6. Update implementer/reviewer prompts to require source-file reopening and stale-intel handling.
7. Update `fp-review` to review information-layer consumption.
8. Verify with metadata checks and grep for old assumptions.

## Acceptance Criteria

- `/fp-init` creates `fp-docs/settings/` and `fp-docs/intel/` skeleton without creating change/archive/history directories.
- Existing settings/intel files are not overwritten without approval.
- `settings/manifest.md` and `intel/manifest.md` define read order, precedence, freshness, and consumption rules.
- Lightweight discovery writes source-backed facts and Unknowns, not guesses.
- Downstream skills read manifests first when present.
- UI flows explicitly consume `frontend_design.md` when present.
- `fp-execute-sdd` task briefs include relevant information-layer excerpts.
- `fp-review` can detect ignored/stale information-layer issues.
- The plugin remains customer-agnostic and does not hardcode framework/vendor/component assumptions.
