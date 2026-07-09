# Canway / CW Agent Settings Example

This file is a lightweight FeaturePilot policy adapter for Canway / CW-style projects.

## Purpose

- Provide a starter policy adapter for projects that follow Canway / CW delivery conventions.
- Keep general workflow guidance here; put frontend/UI/UX rules in `frontend.md`, backend/API/data/security rules in `backend.md`, and prototype visual rules in `prototype-style.md`.

## Authoritative Project Docs

Before planning or implementing, check for target-project instructions such as:

- `AGENTS.md`
- `CLAUDE.md`
- `.claude/CLAUDE.md`
- `GEMINI.md`
- `CURSOR.md` / `.cursorrules`

Do not copy large instruction blocks into this file. Use this file as an index and verify current implementation details in the target project code.

## Workflow Preferences

- Use `fp-docs/manifest.md` as the FeaturePilot navigation entry point.
- Read only the settings and intel relevant to the current task.
- For backend/API/data/security work, read `fp-docs/settings/backend.md`.
- For frontend/UI/UX/prototype work, read `fp-docs/settings/frontend.md` and, when generating HTML prototypes, `fp-docs/settings/prototype-style.md`.
- Current code and command output win for current-state facts.
- Approved PRD/spec/change artifacts win for target-state requirements.

## General Validation Expectations

- Prefer project-provided commands from `README.md`, package manifests, CI config, or existing docs.
- If validation commands are unknown or unsafe locally, record `Unknown` and ask before running destructive, external, or environment-dependent commands.
- Do not claim validation success without command output or observed behavior.

## General Safety Rules

- Do not overwrite existing settings/intel/change artifacts without explicit approval.
- Do not copy secrets, environment values, production data, or customer-specific credentials into FeaturePilot artifacts.
- Treat this Canway / CW example as an editable starting point, not as a guaranteed fact about every target project.

## Related Domain Settings

- Backend/API/Data/Security: `fp-docs/settings/backend.md`
- Frontend/UI/UX: `fp-docs/settings/frontend.md`
- Prototype visual style: `fp-docs/settings/prototype-style.md`

## Unknowns

- Exact branch, commit, and release policy: Unknown.
- Required approval checkpoints beyond target-project instructions: Unknown.
- Environment-specific validation commands and safe test data: Unknown.
