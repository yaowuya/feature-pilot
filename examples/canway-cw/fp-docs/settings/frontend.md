# Canway / CW Frontend, UI, and UX Settings Example

This file is a starter frontend/UI/UX settings draft for Canway / CW-style projects. Verify exact component APIs, imports, slots, events, and local conventions against the target project's current code before implementation.

## Frontend Stack Signals

Common source-backed signals from the provided Canway materials:

- Frontend package location commonly uses `ui/package.json`.
- Vue stack observed: Vue 2.7, Vue Router 3, Vuex 2, Vue I18n 8, Vite 4.
- Common dependencies observed include `@canway/cw-magic-vue`, `@canway/cw-user-selector`, `element-ui`, `@antv/*`, `echarts`, `monaco-editor`, `tailwindcss`, `vee-validate`, and `dayjs`.
- `cw-auto-ops/ui/package.json` scripts include `npm run dev`, `npm run lint`, `npm run eslint`, `npm run stylelint`, and `npm run build`.

Target projects may differ. Confirm from the current target project's package manifests and existing `ui/src` files.

## Frontend Implementation Rules

- Preserve existing Vue 2 / Vite idioms unless an approved change artifact says otherwise.
- Inspect nearby `ui/src` pages/components before designing imports, state, route, API-client, component, CSS, and i18n patterns.
- Do not assume component behavior from dependency names alone; verify current usage or official/local docs.
- User-facing text should follow the target project's i18n/message pattern.
- All async operations need loading states and duplicate-submit protection.
- Success, failure, warning, and info feedback should use the project message component pattern, commonly `this.$bkMessage` or page-level `bk-alert`; do not use browser `alert` as product feedback.
- Destructive or bulk-risk operations need confirmation, preferably with the project's confirmation component (`bk-popconfirm`, `this.$bkInfo`, or `bk-dialog` where present).

## UI Component Preferences

When `@canway/cw-magic-vue` is present and nearby code does not establish a different pattern, prefer `bk-` components:

| Scenario | Preferred component |
|---|---|
| Button | `bk-button` |
| Text input / textarea | `bk-input` |
| Number input | `bk-input-number` |
| Select | `bk-select` + `bk-option` |
| Complex search | `bk-search-select` |
| Radio / checkbox | `bk-radio-group`, `bk-checkbox-group` |
| Switch | `bk-switcher` |
| Date/time | `bk-date-picker`, `bk-time-picker` |
| Form | `bk-form`, `bk-form-item` |
| Table | `bk-table`, `bk-table-column` |
| Pagination | `bk-pagination` |
| Status/tag | `bk-tag`, `bk-badge` |
| Dialog | `bk-dialog` |
| Right-side drawer | `bk-sideslider` |
| Inline alert | `bk-alert` |
| Empty/error state | `bk-exception` |
| Tooltip/popover | `v-bk-tooltips`, `bk-popover` |
| Overflow text | `v-bk-overflow-tips` |
| Copy | `v-bk-copy` |
| Navigation | `bk-navigation`, `bk-navigation-menu` |
| Breadcrumb | `bk-breadcrumb` |
| Tabs | `bk-tab`, `bk-tab-panel` |

## UI Visual Rules

- Use the target project's existing management-console layout as the source of truth.
- Common CW visual token examples:
  - Primary blue: `#1272FF`
  - Annotation orange: `#FF6633`
  - Main text: `#1E252E`
  - Secondary text: `#475468`
  - Disabled text: `#B2BDCC`
  - Border: `#D1D7E1`
  - Light background: `#F5F7FA`
  - Danger red: `#EA3636`
  - Success green: `#2DCB56`
  - Warning orange: `#FF9C01`
- Font family usually follows `PingFang SC`, `Microsoft YaHei`, `sans-serif`, or the target project's existing system font stack.
- Typical size hierarchy: 18px page title, 16px card/section title, 14px body/form/table text, 12px helper/error/badge text.
- Page content horizontal padding often uses 24px; card padding often uses 16px-24px; minimum component gap often uses 8px.

## UX Interaction Rules

### Forms

- Use `bk-form` + `bk-form-item` where available.
- Keep label width consistent within the same form; common values are 100px-120px.
- Required fields must show clear required indication and inline validation errors.
- Validate single fields on blur/change where appropriate and validate all fields on submit.
- On submit failure, focus or scroll to the first error when practical.
- Reset must clear both field values and validation errors.
- Submit buttons must expose loading and prevent duplicate submit.

### Tables

- Management pages default to table-first layouts unless the requirement explicitly calls for cards or dashboards.
- Tables need loading, empty state, filtering/search, pagination, and overflow handling.
- Search/filter no-results states should be distinguishable from normal empty data and offer a way to clear filters.
- Selected rows should show batch state such as `已选 N 项`.
- Operation columns should avoid overcrowding; if there are more than three actions, show the most common actions directly and move the rest under `更多`.
- Delete or dangerous row actions use danger color and confirmation.
- Time display should follow the target project format; source examples use `YYYY-MM-DD HH:mm:ss`.

### Dialogs, drawers, and confirmations

- Simple confirmation or small edit forms can use dialogs.
- Complex create/edit/detail forms should prefer right-side drawers (`bk-sideslider`) when this matches nearby pages.
- Common drawer width is 620px-720px, with header, scrollable body, and fixed footer actions.
- Button order: primary confirm/save first, secondary cancel second.
- Dangerous confirmation should clearly explain impact and avoid accidental mask-close where supported.

### Permissions and feedback

- Permission-denied controls should be disabled with tooltip reason when visible; hiding alone is often insufficient for review clarity.
- Backend must still enforce permissions.
- Empty, loading, error, disabled, success, warning, and no-permission states should be explicitly designed.
- Use concise, actionable copy: for example `请输入策略名称`, `请选择目标业务`, `请先选择策略`, `无操作权限`.

## FeaturePilot Design Output Requirements

When generating or reviewing frontend plans/designs, include:

- Component library and key components used.
- Layout structure, spacing, and key visual tokens.
- Form validation triggers and error display.
- Table loading, empty, filtering, sorting, pagination, batch state, and overflow behavior.
- Dialog/drawer/delete confirmation/danger operation behavior.
- Permission, disabled, and tooltip behavior.
- Success/failure/warning feedback.
- Time format and refresh behavior.
- Visual Checks and UX Checks for implementation verification.

## Commands

Run from `ui/` when present and approved:

- Dev server: `npm run dev`
- Build: `npm run build`
- Lint: `npm run lint`
- ESLint only: `npm run eslint`
- Stylelint only: `npm run stylelint`

## Unknowns

- Exact component import and registration pattern for the target project: Unknown.
- Canonical route/store/API-client structure: Unknown until current code is inspected.
- Browser support beyond the target project's `browserslist`: Unknown.
- Visual regression or E2E command: Unknown.
- Required locale key naming convention: Unknown.
