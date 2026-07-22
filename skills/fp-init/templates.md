# fp-init templates

Use these templates when `skills/fp-init/SKILL.md` instructs you to create skeleton or optional settings files. Substitute placeholders such as `<timestamp>` and `<detected local path>` with confirmed values. Do not guess unknown project facts; write `Unknown`.

## FeaturePilot Manifest

Target: `fp-docs/manifest.md`

```markdown
# FeaturePilot Manifest

Schema: fp-manifest/v1
Generated: <timestamp>
Project root: `<detected local path>`
FP docs root: `fp-docs/`
Git SHA: <sha or unavailable>
Working tree: clean | dirty | unavailable

## Precedence

For current-state facts, current code and command output win over settings and intel.
For target-state requirements, user instructions and approved active change artifacts win.

## Settings Files

| File | Role | Authoritative For | When To Read | Status |
| --- | --- | --- | --- | --- |
| `settings/agent.md` | Lean FeaturePilot policy adapter | workflow, constraints, external-doc pointers | workflow/policy questions only | missing |
| `settings/frontend.md` | Frontend/UI/visual settings | UI implementation and visual acceptance | UI/page/prototype work only | missing/not-applicable |
| `settings/backend.md` | Backend/API/data/security settings | backend implementation and backend acceptance | backend/API/data/security/permission work only | missing/not-applicable |
| `settings/prototype-style.md` | Prototype visual style reference | prototype generation consistency | prototype generation only | missing/not-applicable |

## Code Map

| Provider | Status | Version | Index Path | Last Checked | Use As |
| --- | --- | --- | --- | --- | --- |
| CodeGraph | <ready \| skipped \| failed \| unavailable> | <version or unavailable> | `.codegraph/` | <timestamp or not-checked> | navigation-hint-only |

## Intel Artifacts

| File | Purpose | When To Read | Freshness | Sources |
| --- | --- | --- | --- | --- |
| `intel/unknowns-and-decisions.md` | Project-level unknowns and confirmations | requirement/design questions affected by known unknowns | fresh | init skeleton |
| `intel/refresh-policy.md` | Freshness and staleness rules | when deciding whether intel can be trusted | fresh | init skeleton |
| `intel/sdd-handoff.md` | SDD handoff contract | SDD execution only | fresh | init skeleton |

## External Project Docs

| File | Priority | Notes |
| --- | --- | --- |

## Critical Unknowns

- None recorded yet.

## Consumption Rules

- Read this manifest first as an index, not as permission to read everything.
- Do **not** bulk-read all settings or intel files.
- Use `When To Read` to pull only the smallest relevant settings/intel set for the current phase and question.
- Treat generated intel as navigation and stale-prone hints, not proof of current behavior.
- Treat the Code Map row as discovery metadata only; live CodeGraph detection and current source win over its recorded state.
- Current code and command output win for current-state facts.
- Approved change artifacts win for target-state requirements.
- Re-open referenced source files before editing.
- Re-run commands before claiming validation.
- Missing referenced paths make dependent sections stale.
- If an intel artifact is hard-stale or soft-stale, verify just-in-time from current source before using it.
- UI-related phases must read `settings/frontend.md` when present.
- Prototype generation should read `settings/prototype-style.md` when present.
- Backend-related phases must read `settings/backend.md` when present.
```

## Unknowns and Decisions

Target: `fp-docs/intel/unknowns-and-decisions.md`

```markdown
# Unknowns and Decisions

## Unknowns

| Area | Unknown | Impact | Resolve By | Blocking For |
| --- | --- | --- | --- | --- |

## Decisions

| Date | Decision | Source | Applies To |
| --- | --- | --- | --- |
```

## Refresh Policy

Target: `fp-docs/intel/refresh-policy.md`

````markdown
# Refresh Policy

Generated intel is navigation, not proof of current behavior.

Every generated intel artifact should include a small freshness block near the top:

```markdown
Generated: <timestamp>
Generated from Git SHA: <sha or unavailable>
Working tree: clean | dirty | unavailable
Depends on:
- <source path> @ <git blob sha or content hash or unavailable>
Freshness: fresh | soft-stale | hard-stale | unknown
Use as: navigation-hint-only
```

## Hard-stale

- Referenced paths disappear.
- Package manifests/config files change.
- Test/build/lint config changes.
- Route/API framework config changes.
- Auth/permission files change.
- Component library/theme/token files change.
- Any depends-on source recorded in `sources-and-provenance.md` has a changed git blob SHA or content hash.

## Soft-stale

- Git SHA differs from recorded SHA.
- Working tree was dirty during generation.
- Profile is old.
- Current change touches an area covered by an intel artifact.

On stale intel, verify just-in-time.
````

## SDD Handoff

Target: `fp-docs/intel/sdd-handoff.md`

```markdown
# SDD Handoff

## Mandatory Context Files

- `fp-docs/manifest.md`

## Global Constraints Sources

- Unknown

## Allowed Edit Scope Rules

- Unknown

## Validation Evidence Requirements

- Unknown

## Commit Policy

- Unknown

## Review Severity Policy

- Unknown

## Visual Evidence Requirements

- Unknown

## Backend Evidence Requirements

- Unknown

## Security/Data Constraints

- Unknown

## Common Project Pitfalls

- Unknown

## Stale Intel Handling

- Re-open source files before editing.
- Re-run commands before claiming validation.
- If a referenced path is missing, treat the dependent section as stale.
```

## FeaturePilot Agent Settings

Target: `fp-docs/settings/agent.md`

```markdown
# FeaturePilot Agent Settings

## Purpose

- <why FeaturePilot settings exist for this project>

## Authoritative Project Docs

- <CLAUDE.md / AGENTS.md / other docs, or Unknown>

## Workflow Preferences

- Branching:
- Commit style:
- Review expectations:

## General Allowed / Forbidden Areas

- Allowed:
- Forbidden:

## General Validation Expectations

- <cross-domain validation expectations only; exact commands belong in intel/commands-and-quality-gates.md>

## General Security / Data Notes

- <cross-domain policy only; concrete API/auth/data/ops rules belong in settings/backend.md>

## Related Domain Settings

- Frontend/UI: `fp-docs/settings/frontend.md` if present
- Backend/API/Data/Security: `fp-docs/settings/backend.md` if present

## Unknowns

- <unknown general policy items>
```

## FeaturePilot Frontend Settings

Target: `fp-docs/settings/frontend.md`

```markdown
# FeaturePilot Frontend Settings

## Frontend Framework and Source Locations

- Framework:
- Source roots:
- Route locations:

## Component Library and Imports

- Library:
- Import patterns:
- Component prefix:

## Design Tokens and Styling

- Token/style sources:
- Layout/responsive rules:

## Figma / Screenshot Handling

- Design sources:
- Mapping rules:

## Preview and Visual Verification

- Local preview command:
- Browser/visual checks:

## Unknowns

- <unknown frontend/UI/visual items>
```

## FeaturePilot Backend Settings

Target: `fp-docs/settings/backend.md`

```markdown
# FeaturePilot Backend Settings

## Backend Framework and Source Locations

- Framework:
- Source roots:
- API/router locations:

## API / Service / Data Patterns

- Controller/service patterns:
- Data model/schema/migration conventions:
- Request/response/error envelope:

## Auth / Permissions / Isolation

- Auth/session model:
- Permission/action naming:
- Multi-tenant / workspace / project / account isolation:

## Jobs / Operations / Observability

- Background job patterns:
- Audit/logging expectations:
- Deployment/migration notes:

## Backend Validation Expectations

- Backend test command/pattern:
- Data/security negative-test expectations:

## Unknowns

- <unknown backend/API/data/security items>
```

## FeaturePilot Prototype Style

Target: `fp-docs/settings/prototype-style.md`

```markdown
# FeaturePilot Prototype Style

## Usage

- Use when creating or updating `fp-docs/changes/<slug>/prototype.html`.

## Visual Sources

- Existing prototype/page/Figma/screenshot sources:
- Confidence:

## Page Skeleton and Layout

- Shell/navigation:
- Content layout:
- Responsive/min-width rules:

## Color, Typography, and Spacing

- Primary colors:
- Text colors:
- Backgrounds/borders:
- Font stack:
- Spacing scale:

## Component Patterns

- Buttons:
- Forms:
- Tables:
- Dialogs/drawers:
- Empty/loading/error states:

## Interaction and Copy Rules

- Required prototype interactions:
- Validation/error behavior:
- Permission/disabled behavior:
- Copy tone/examples:

## Unknowns

- <unknown prototype style items>
```
