# Figma Review: `<slug>`

- Reviewer: `independent read-only reviewer`
- Reviewed code revision: `<SHA>`
- Figma source/node/revision/frame/variant: `<evidence>`
- Browser capability: `project runner | Playwright browser extension | local playwright-cli | unavailable`
- Overall result: `PASS | FAIL | CANNOT_VERIFY | BLOCKED`

## Source and Capability Gate

| Gate | Result | Evidence |
| --- | --- | --- |
| Figma-only UI source respected | `PASS | FAIL | CANNOT_VERIFY | BLOCKED` | `<node/source and prototype exclusion>` |
| Browser capability resolution | `PASS | FAIL | CANNOT_VERIFY | BLOCKED` | `<reuse/customer choice/command authorization>` |
| Reference/runtime provenance | `PASS | FAIL | CANNOT_VERIFY | BLOCKED` | `<reference/current paths>` |

## Preservation Review

| Preservation ID | Before baseline | After replay | Approved exception | Result | Evidence |
| --- | --- | --- | --- | --- | --- |
| `PRES-001` | `<result>` | `<result>` | `None | EXC-NNN` | `PASS | FAIL | CANNOT_VERIFY | BLOCKED` | `<paths/commands>` |

## Capability Review

| Capability ID | Source and task/file mapping | Runtime observable result | Visual Case | Result | Evidence |
| --- | --- | --- | --- | --- | --- |
| `FIGCAP-001` | `<mapping>` | `<browser result>` | `<case or N/A>` | `PASS | FAIL | CANNOT_VERIFY | BLOCKED` | `<paths/commands>` |

## Visual Review

Visual evidence: PASS | FAIL | CANNOT_VERIFY

| Case ID | Figma node/variant | Reference/current/diff | Browser interaction evidence | Acceptance rule | Result |
| --- | --- | --- | --- | --- | --- |
| `VIS-001` | `<node>` | `<paths>` | `<replay evidence>` | `<case-specific rule>` | `PASS | FAIL | CANNOT_VERIFY` |

## Findings

| Finding ID | Severity | Requirement | Evidence | Failure scenario | Required fix |
| --- | --- | --- | --- | --- | --- |
| `FIGREV-001` | `Critical | Important | Minor` | `<FIGCAP/PRES/Visual Case>` | `<path:line/command>` | `<concrete state>` | `<direction>` |

## Completion Decision

- Code editing: `DONE | PARTIAL | NOT_STARTED`
- Capability completion: `PASS | FAIL | CANNOT_VERIFY | BLOCKED`
- Preservation: `PASS | FAIL | CANNOT_VERIFY | BLOCKED`
- Figma visual fidelity: `PASS | FAIL | CANNOT_VERIFY | BLOCKED`
- Overall: `COMPLETE | INCOMPLETE | BLOCKED`

Only `PASS` for every required `FIGCAP-*`, core `PRES-*`, and core Visual Case, with no unapproved behavioral change, permits “Figma change complete”.
