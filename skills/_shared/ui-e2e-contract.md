# FeaturePilot UI/E2E Staged Contract

## Applicability and UI Delivery Level

Every UI-bearing task declares one `UI Delivery Level` and records why that level applies:

This contract is mandatory for UI-bearing work in `fp-execute` and `fp-execute-sdd`.

- `static-only`: only static presentation is in scope. It needs visual `PASS` / `VISUAL_REVIEW_PASS` evidence and an evidence-backed `E2E Applicability: N/A` reason.
- `interactive`: user interaction is in scope. It requires real browser front-end E2E and `E2E Applicability: REQUIRED`.
- `business-flow`: a user-visible flow crosses a real business boundary. It requires real browser front-end E2E, proof of the real core API, `Mocked Core API: false`, the real persistence or permission result, and cleanup of test-created data.

`E2E Applicability: REQUIRED | N/A` is a case-manifest field. `N/A` is permitted only for a genuinely `static-only` case with its recorded evidence-backed reason; it is never a substitute for an unresolved required E2E case.

### Allowed delivery-level transition table

| UI Delivery Level | Allowed lifecycle path | Transition requirement |
| --- | --- | --- |
| `static-only` | `SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> FINAL_REVIEW -> ARCHIVE` | After `VISUAL_REVIEW_PASS`, record a valid evidence-backed `E2E Applicability: N/A`; do not enter `INTERACTION_READY` or `FRONTEND_E2E_PASS`. |
| `interactive` | `SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> INTERACTION_READY -> FRONTEND_E2E_PASS -> FINAL_REVIEW -> ARCHIVE` | Required real browser front-end E2E; `INTERACTION_READY` and `FRONTEND_E2E_PASS` are mandatory. |
| `business-flow` | `SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> INTERACTION_READY -> FRONTEND_E2E_PASS -> FINAL_REVIEW -> ARCHIVE` | Required real browser front-end E2E plus real core API, `Mocked Core API: false`, real persistence/permission result, and cleanup. |

## Required State Machine

The state order is exact:

`SOURCE_READY -> STATIC_UI_READY -> VISUAL_REVIEW_PASS -> INTERACTION_READY -> FRONTEND_E2E_PASS -> FINAL_REVIEW -> ARCHIVE`

Tasks may progress only from left to right. A `static-only` task reaches `FINAL_REVIEW` only after its visual pass and justified E2E N/A record. `interactive` and `business-flow` tasks must reach `FRONTEND_E2E_PASS` with real browser evidence before final review. Required E2E cannot be `SKIPPED` or manual-approved; an unmet requirement is `BLOCKED`.

## Case Manifest and E2E Evidence

Each case manifest records its task and case ID, source-derived condition, UI delivery level, runtime route, real test account/role, `E2E Applicability: REQUIRED | N/A`, E2E result, `Mocked Core API: false` when E2E is required, cleanup result, evidence paths, and rationale for any `N/A` or `BLOCKED` status.

Visual and E2E evidence are distinct channels:

- Visual evidence uses `.fp-execute/visual/<task-id>/<case-id>/`.
- E2E evidence uses `.fp-execute/e2e/<task-id>/<case-id>/`.

For every E2E execution, record:

- `Executed command`
- `Environment identity`
- `Destination`
- `Start` timestamp
- `End` timestamp
- `Attempts`
- `Test IDs`
- `Artifacts`
- `Coverage matrix reference`: `.fp-execute/e2e/<task-id>/<case-id>/coverage-matrix.md`
- `Cleanup`

E2E evidence may additionally record runner/version, browser, and result; artifacts include trace/video/screenshots when available. Visual fixtures are separate and never E2E evidence.

## Real Frontend E2E: No Mock Data or Requests

Real E2E has an absolute zero-mock rule. It must not use `page.route`, `route.fulfill`, MSW, Cypress stubs/intercepts, fixture JSON, mock modules, hard-coded API data, frontend store/localStorage business-data injection, database seed, or direct backend/API writes that bypass the normal UI flow.

Real test accounts are permitted, but their authentication, role, and business data cannot be forged. A `business-flow` case proves the browser reached the real core API and the real persistence or permission outcome, then cleans up through an approved normal flow or a documented real-environment cleanup mechanism that does not replace the tested UI flow.

Real error and exception paths may be exercised only with real environment, permission, or service conditions. If an in-scope condition cannot be safely triggered, its coverage entry must be `BLOCKED`, never `N/A` or `covered`.

## Coverage Matrix

E2E coverage is source-derived.

The canonical coverage-matrix relative path is `.fp-execute/e2e/<task-id>/<case-id>/coverage-matrix.md`.
One coverage matrix covers exactly one `<task-id>/<case-id>` pair.
Coverage entry status is exactly `covered | N/A | BLOCKED`.
A `BLOCKED` coverage entry means required evidence is unresolved; the Gate/Task lifecycle remains `BLOCKED` until it is resolved.

Store that matrix with the case evidence, source/requirement reference, applicability, result, and rationale for every condition. It checks:

- happy paths and branches;
- validation and boundaries;
- loading, empty, error, and retry states;
- permissions and isolation;
- persistence and navigation;
- state transitions and concurrency; and
- applicable API pagination, filtering, sorting, and compatibility.

Each applicable condition must be `covered` or explicitly `N/A` / `BLOCKED` with rationale. `covered` records real evidence, `N/A` means the condition is not applicable, and `BLOCKED` means a required condition could not receive safe real-environment evidence.

## Automatic Playwright Bootstrap

Prefer the existing project runner. If it is missing, detect the target frontend root, workspace, lockfile, and package manager, then install `@playwright/test` as a development dependency and Chromium only in that target project. Reuse an existing configuration; create a minimal configuration and current-task skeleton only when none exists.

Never install globally, overwrite existing configuration, or upgrade unrelated dependencies. Record the commands, resolved version, and changed files in the E2E evidence. A bootstrap failure or no valid frontend root is `BLOCKED`, never a mock fallback.

## Retry, Blocking, Final Review, and Archive

Core visual/E2E gaps and any mock violation remain `BLOCKED` through 3 attempts. They cannot be converted into review debt, `N/A`, `PASS`, a manual approval, or a waived check. `FINAL_REVIEW` and `ARCHIVE` cannot waive these blockers.

After a failure, diagnostic retries may continue only through attempt 3.
A third failed attempt is `BLOCKED`; a fourth attempt is forbidden.
A core UI/E2E gap or any mock violation cannot become review debt, `N/A`, `PASS`, `PASS_WITH_NOTES`, a manual approval, or a waived check.
