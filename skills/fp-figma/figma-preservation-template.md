# Figma Preservation Contract

- Change: `<slug>`
- Figma scope: `<file/page/node IDs and frame/variant>`
- Current-code baseline revision: `<HEAD or explicit baseline>`
- UI design source: `Figma only | no trustworthy Figma UI design`
- Prototype usage: `PROHIBITED_AS_UI_REFERENCE | FUNCTION_SCOPE_ONLY`

## Allowed Changes

| Change ID | Allowed UI/behavior change | Source approval | Affected route/component/files |
| --- | --- | --- | --- |
| `ALLOW-001` | `<Figma-explicit visual/layout/token/responsive change>` | `<Figma node or explicit customer approval>` | `<exact paths>` |

## Protected Behaviors

| Preservation ID | Existing observable behavior | Current-code/test evidence | Stable fixture and precondition | Before Baseline command/result | After Replay command/result | Approved exception | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `PRES-001` (`PRES-NNN` stable pattern) | `<user action -> externally observable result>` | `<path:line/test>` | `<non-sensitive stable state>` | `<PASS/CANNOT_VERIFY evidence>` | `<PASS/FAIL/CANNOT_VERIFY evidence>` | `None` | `PENDING` |

## Customer-Approved Exceptions

| Exception ID | Changed or removed behavior | Explicit customer approval | Affected `PRES-*` | Result |
| --- | --- | --- | --- | --- |
| `EXC-001` | `<behavior>` | `<verbatim decision/reference>` | `PRES-001` | `APPROVED` |

## Rules

- Figma 未呈现既有行为不等于允许删除、隐藏或改变其语义。
- 有可信 Figma UI 设计时，原型不得作为 UI 视觉、布局、呈现或还原判断的参考。
- 没有可信 Figma UI 设计时，原型只能是 `FUNCTION_SCOPE_ONLY`，不能使视觉还原结论通过。
- 所有核心 `PRES-*` 必须在相同 fixture、路由、用户状态、viewport、locale 和 theme 下重放。
- 任意核心 `PRES-*` 为 `FAIL` 或 `CANNOT_VERIFY` 时，Figma 改造不得为 `COMPLETE`。
