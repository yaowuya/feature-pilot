# Figma Capability Ledger

- Change: `<slug>`
- UI design source: `Figma only | no trustworthy Figma UI design`
- Prototype usage: `PROHIBITED_AS_UI_REFERENCE | FUNCTION_SCOPE_ONLY`

## Capability Ledger

| Capability ID | Atomic capability and acceptance result | Target feature source | Figma node / Frame / Variant | Current-code baseline | Implementation task / file | Preservation Case | Browser interaction evidence | Visual Case | Verification result | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `FIGCAP-001` (`FIGCAP-NNN` stable pattern) | `<actor/action/state -> observable result>` | `<PRD/proposal/current explicit instruction>` | `<node/frame/variant or N/A>` | `<path:line/test or N/A>` | `<task ID/path>` | `<PRES-NNN or N/A>` | `<replay command/artifact>` | `<case ID or N/A>` | `<exact result>` | `PENDING` |

## Preflight

| Check | Required result | Status | Evidence / blocker |
| --- | --- | --- | --- |
| Every required capability has an implementation owner | one task/file for every `FIGCAP-*` | `PASS | BLOCKED` | `<owner or gap>` |
| Every key Figma state has a behavior owner | component/variant/empty/error/permission/confirmation state maps to `FIGCAP-*` | `PASS | BLOCKED` | `<mapping or question>` |
| Existing behavior absent from Figma is preserved | mapped to `PRES-*` unless an approved exception exists | `PASS | BLOCKED` | `<PRES-* or EXC-*>` |

## Completion Rules

- A static control does not prove capability completion.
- `FIGCAP-*` 只有在真实运行态达到可观察验收结果后才可标记 `PASS`。
- `MISSING`、`PARTIAL`、`FAIL`、`CANNOT_VERIFY` 或 `BLOCKED` 的必需能力均阻止总体 `COMPLETE`。
- 有可信 Figma UI 设计时，Figma 是唯一 UI 呈现来源；原型不得填入 Figma node、Visual Case 或视觉验收理由。
