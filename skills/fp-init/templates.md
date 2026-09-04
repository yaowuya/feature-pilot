# fp-init templates

Use these templates when `skills/fp-init/SKILL.md` instructs you to create the manifest or an explicitly approved optional file. `manifest-only default` applies to new projects. Substitute placeholders with confirmed values; do not guess unknown project facts.

## FeaturePilot Manifest

Target: `fp-docs/manifest.md`

```markdown
# FeaturePilot Manifest

Schema: fp-manifest/v2
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
| `intel/project-facts.md` | Optional generated facts cache | validation or non-obvious boundary lookup only | missing | approved discovery only |
| `intel/.freshness.json` | metadata-only freshness inputs for project facts | live refresh calculation only | missing | created with project facts only |
| `intel/unknowns.md` | Project-level unknowns | only when manifest lists relevant actual content | missing | human-owned, lazy, explicit approval |
| `intel/decisions.md` | Project-level decisions | only when manifest lists relevant actual content | missing | human-owned, lazy, explicit approval |

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
- Compute stale/conflict live from `.freshness.json`, current sources, and current generated body; never trust a stored verdict.
- UI-related phases must read `settings/frontend.md` when present.
- Prototype generation should read `settings/prototype-style.md` when present.
- Backend-related phases must read `settings/backend.md` when present.
```

## Project Facts

Target: `fp-docs/intel/project-facts.md`

```markdown
# Project Facts

Generated facts are `navigation-hint-only`; current source and command output win.

## Validation and Quality Gates

- <confirmed command or gate, source path, and confidence>

## Non-obvious Contracts and Architecture Boundaries

- <confirmed contract/boundary, source path, and confidence>

## Security and Data Boundaries

- <confirmed security/data boundary, source path, and confidence>
```

Contract: `no CodeGraph topology snapshots`. Do not include workspace trees, file inventories, symbol maps, callers/callees, dependency graphs, routes inferred only from topology, or other topology snapshots.

## Project Facts Freshness Metadata

Target: `fp-docs/intel/.freshness.json`

```json
{
  "schema": "fp-project-facts-freshness/v1",
  "generatorVersion": "<generator version>",
  "generatedTime": "<ISO-8601 timestamp>",
  "sections": [
    {
      "artifactSectionId": "<artifact/section id>",
      "bodyHash": "<sha256 body hash>",
      "sources": [
        {
          "relativePath": "<source relative path>",
          "fingerprint": "<git blob SHA or content hash>"
        }
      ]
    }
  ]
}
```

This file is `metadata-only`: schema, artifact/section id, source relative path + fingerprint, body hash, generated time, and generator version. `stale/conflict is computed live`; do not store freshness verdicts, project facts, CodeGraph state, or decisions here.

## Selective refresh

1. Compare current source fingerprints and body hash with metadata before reading the full cache.
2. Classify fresh/stale/user-edit-conflict in memory and show the proposed section-level write scope.
3. Refresh only approved stale sections without body conflicts; metadata is replaced with the new source fingerprints and body hash.
4. Never refresh settings, human-owned unknowns/decisions, active changes, archive, or history.

## Lazy Human-owned Unknowns

Target: `fp-docs/intel/unknowns.md` (human-owned, lazy, explicit approval and actual project-level content required)

```markdown
# Project Unknowns

| Area | Unknown | Impact | Resolve By | Blocking For |
| --- | --- | --- | --- | --- |
```

## Lazy Human-owned Decisions

Target: `fp-docs/intel/decisions.md` (human-owned, lazy, explicit approval and actual project-level content required)

```markdown
# Project Decisions

| Date | Decision | Source | Applies To |
| --- | --- | --- | --- |
```

## Legacy information-layer read compatibility

For one release, manifest-listed `unknowns-and-decisions.md`, `refresh-policy.md`, and `sdd-handoff.md` may be read as compatibility hints only. v2 does not create or refresh them; they are not required and are not auto-deleted. Older generated files may contain these historical freshness fields, which are read-only inputs and never v2 output:

```text
Refreshed: <timestamp or never>
Generated body hash: <sha256 or unavailable>
Refresh decision: keep | regenerate | conflict
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

- <cross-domain validation expectations only; confirmed exact commands may be cached in intel/project-facts.md after approved discovery>

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
