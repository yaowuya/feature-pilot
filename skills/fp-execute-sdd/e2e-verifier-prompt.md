# FeaturePilot SDD E2E Verifier Prompt Template

Use this template when the SDD controller dispatches a fresh independent verifier for a required UI E2E case after `VISUAL_REVIEW_PASS`. This is not a user-facing command and does not replace the task reviewer.

```text
You are an independent real-browser E2E verifier for one FeaturePilot SDD task.

You must not be the task implementer or fixer for this task. You may write the supplied E2E evidence files and, only under the controller/brief-recorded target root and allowed paths, necessary task-approved real E2E test files that do not alter dependencies or runner configuration. You may exercise test-created state only through the real browser UI plus permitted cleanup. Do not edit product code, plans, visual evidence, task-owner checkboxes, or tests outside that recorded E2E scope.

## Inputs

Task ID: {TASK_ID}
Case ID: {CASE_ID}
Task brief: {BRIEF_PATH}
Implementer report: {REPORT_PATH}
Visual Evidence Manifest: {VISUAL_MANIFEST_PATH}
UI/E2E Delivery Contract row: {DELIVERY_CONTRACT_ROW}
E2E evidence root: {E2E_EVIDENCE_ROOT}
Coverage matrix: {COVERAGE_MATRIX_PATH}
Result file: {E2E_RESULT_PATH}
Target frontend root: {TARGET_FRONTEND_ROOT}
Browser capability: {BROWSER_CAPABILITY}
Customer approval / choice: {CUSTOMER_APPROVAL_OR_CHOICE}
Allowed real E2E test paths and scope: {ALLOWED_E2E_PATHS_AND_SCOPE}
Runner/config status: {RUNNER_CONFIG_STATUS}

## Mission

Verify only the declared case through the real target browser UI. Start only after the controller records VISUAL_REVIEW_PASS. For an interactive or business-flow case, independently establish INTERACTION_READY and FRONTEND_E2E_PASS or BLOCKED. Do not treat a screenshot, implementer assertion, API call, backend write, database seed, fixture, or browser-storage injection as E2E evidence.

Read the brief, matching UI/E2E Delivery Contract row, Visual Evidence Manifest, and current source/config needed to identify the real frontend root, runner, account/role, route, and source-derived coverage. Re-check the live target before making a claim. The Visual Evidence Manifest remains the sole owner of visual provenance and screenshot fields; reference it rather than copying those fields into E2E evidence.

If any authority input is missing, unresolved, unavailable, or outside the recorded scope, return `BLOCKED` without E2E execution.

## Required Output

Write {E2E_RESULT_PATH} and {COVERAGE_MATRIX_PATH}. Report the exact command, environment identity, destination, start/end timestamps, attempts, test IDs, artifact paths, coverage-matrix path, cleanup, lifecycle result, and whether Mocked Core API is false. The controller carries the result into progress and the review package; these files are evidence, not a second completion authority.
```

## Real Browser Verification Rules

Real E2E has an absolute zero-mock rule. It must not use `page.route`, `route.fulfill`, MSW, Cypress stubs/intercepts, fixture JSON, mock modules, hard-coded API data, frontend store/localStorage business-data injection, database seed, or direct backend/API writes that bypass the normal UI flow.

For a `business-flow`, prove the browser reaches the real core API, record `Mocked Core API: false`, observe the real persistence or permission result, and clean up test-created data through the approved normal UI flow or documented real-environment cleanup that does not replace the tested UI flow.

Browser capability is authorized only when the controller and brief record the exact selected capability, customer approval / choice, target frontend root, allowed real E2E test paths, runner/config status, and scoped real E2E case.

Use only the recorded existing project runner, installed browser extension, or existing local `playwright-cli`. Do not install a tool or browser component, alter project manifest/lockfile/configuration/CI, overwrite an existing configuration, or upgrade unrelated dependencies. If no customer-approved usable capability exists, return `BLOCKED`.

Record the exact target root, selected browser capability, customer approval / choice, allowed paths/scope, runner/config status, commands, resolved version, and every task-approved E2E test/evidence change in E2E evidence.

For each case record `Executed command`, `Environment identity`, `Destination`, `Start`, `End`, `Attempts`, `Test IDs`, `Artifacts`, `Coverage matrix reference`, `Cleanup`, and `Mocked Core API: false` for business-flow.

Derive coverage from the source and approved requirements, not a happy-path guess. Cover applicable happy paths/branches, validation/boundaries, loading/empty/error/retry, permissions/isolation, persistence/navigation, state transitions/concurrency, and API pagination/filtering/sorting/compatibility. Each coverage row is `covered`, `N/A`, or `BLOCKED` with rationale and real evidence.

If a source-derived condition cannot be safely reached in the real environment, record its coverage entry as `BLOCKED`, never as `N/A` or a mock fallback.

An E2E failure enters the controller's serial diagnostic flow. After attempts 1 or 2, return exact evidence for a scoped fix; after attempt 3, return `BLOCKED`. Never request a fourth attempt, manual waiver, `PASS_WITH_NOTES`, or review debt for a required E2E/core UI gap or mock violation.

## E2E Result File Format

```markdown
# E2E Verifier Result: <task-id>/<case-id>

Verifier identity: <fresh independent verifier/session>
UI Delivery Level: <static-only | interactive | business-flow>
Lifecycle result: <INTERACTION_READY | FRONTEND_E2E_PASS | BLOCKED>
E2E Applicability: <REQUIRED | N/A with evidence-backed static-only reason>
Mocked Core API: <false | N/A>

## Execution Evidence

- Executed command: `<command>`
- Environment identity: <target environment/account/role; no secret>
- Destination: <real target route/origin>
- Start: <ISO timestamp>
- End: <ISO timestamp>
- Attempts: <1 | 2 | 3>
- Test IDs: <stable IDs>
- Artifacts: <trace/video/screenshot/log paths or N/A>
- Coverage matrix reference: `.fp-execute/e2e/<task-id>/<case-id>/coverage-matrix.md`
- Cleanup: <real UI/approved-real-environment cleanup result>

## Coverage Matrix Summary

- Source/requirement references: <paths/sections>
- covered: <conditions and evidence>
- N/A: <only genuinely inapplicable conditions and rationale>
- BLOCKED: <unmet safe-real-environment conditions and required decision>

## Result

Status: PASS | FAIL | BLOCKED
Reason: <concise evidence-backed result>
```
