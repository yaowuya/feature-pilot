# Canway / CW Backend Settings Example

This file is a starter backend/API/data/security settings draft for Canway / CW-style projects. Verify every item against the target project before implementation.

## Backend Stack Signals

Common source-backed signals from the provided Canway materials:

- `auto-ops-platform` uses Python `>=3.11.10,<3.12`, Django 4.2, Django REST Framework 3.15.1, Celery 5.2.7, django-celery packages, and Pydantic 2.12.5.
- `cw-auto-ops` contains a BlueKing / Django-style application with `manage.py`, `requirements.txt`, and an `ui/` frontend package.
- `cw-auto-ops/requirements.txt` references `auto-ops-platform==1.0.0` from a Canway package index and includes gevent, jsonfield, croniter, PDF/Excel processing packages, and Jinja2.

Target projects may differ. Confirm stack from the current target project's manifests before editing.

## Backend Implementation Rules

When the target project confirms the same conventions, apply these rules:

- Business models use the project base model pattern, for example `TenantBaseModel` where present.
- Avoid introducing `ForeignKey` if the project convention prefers integer ID fields.
- Avoid introducing Django `choices=` if the project uses a dedicated enum pattern.
- User-visible backend strings should follow the project's i18n pattern, commonly `gettext_lazy as _()`.
- Write endpoints should validate input through the project's Pydantic/entity validation utilities where present.
- ViewSets should stay thin and delegate business logic to services.
- Prefer `get_queryset()` over class-level `queryset` when the project uses request/tenant/user-scoped filtering.
- Logging should follow the target project's logging style; in the source example this is `%`-style formatting.
- API responses may be wrapped by a project renderer/envelope; verify existing renderer behavior before designing response bodies.

## API / Service / Data Patterns

Before changing backend behavior, locate and verify:

- Controller/ViewSet/API route patterns.
- Service layer location and naming.
- Entity/schema/serializer/Pydantic validation patterns.
- Permission/action naming and enforcement locations.
- Tenant/workspace/project/account isolation fields.
- Operation log/audit log conventions.
- Migration policy and compatibility constraints.

Use adjacent current code as the final source of truth.

## Security and Permissions

- Frontend hidden/disabled controls are not sufficient; backend must reject unauthorized actions.
- Risky operations such as delete, disable, bulk update, credential/script execution, or policy changes require explicit permission and negative tests where practical.
- Validate tenant/project/account isolation for list, detail, create, update, delete, and bulk endpoints.
- Avoid exposing secrets, tokens, raw environment variables, or internal stack traces in API responses, logs, or FeaturePilot docs.

## Backend Validation Expectations

Example commands observed in source materials; verify availability in the target project:

- Backend tests: `.venv/Scripts/python.exe -m pytest tests/ -v`
- Single backend test file: `.venv/Scripts/python.exe -m pytest tests/<path> -v`
- Local Django commands: `python manage.py runserver`, `python manage.py makemigrations`, `python manage.py migrate`
- Formatting/checks: `black --line-length 120 <file> && isort <file> && flake8 <file>`

Do not run migrations, external service calls, or environment-dependent commands without user approval.

## Unknowns

- Target project database engine and required credentials: Unknown.
- Safe tenant/project/account IDs for local manual testing: Unknown.
- Exact API envelope and error format for the target project: Unknown until current code is verified.
- BlueKing / external Canway service availability in the current workspace: Unknown.
- Release-specific compatibility constraints: Unknown.
