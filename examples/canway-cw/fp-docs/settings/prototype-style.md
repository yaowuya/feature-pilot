# Canway / CW Prototype Style Example

Use this file when generating or updating `fp-docs/changes/<change-slug>/prototype.html` for Canway / CW-style management-console pages.

This is an editable starter draft distilled from provided Canway project prototypes and settings. Verify target-project screenshots, Figma, existing pages, and `frontend.md` before treating it as authoritative.

## Design Positioning

- Style keywords: enterprise management console, compact information density, blue-gray admin UI, table-first content, drawer-based editing.
- Target feeling: real product page, not a marketing page or generic demo.
- Page focus: data tables, filters, batch operations, permission states, right-side drawer forms.
- Motion: restrained and state-oriented; avoid decorative large-scale animation.

## Page Skeleton

### Top navigation

- Height around `56px`-`60px`.
- Background often uses dark blue-gray, e.g. `#242b3d`.
- Left brand area keeps product identity; source examples preserve an AOC4-style brand feel.
- Primary navigation is horizontal, with current item highlighted by subtle light overlay or active indicator.

### Left sidebar

- Width around `200px`-`240px`; source prototype uses `220px`.
- Background often light gray-blue, e.g. `#f3f6fa`.
- Separate sidebar from content with a 1px light border.
- Active menu item uses light blue background and primary blue text.
- Show realistic menu hierarchy for management/security pages; do not create disconnected fake group headings.

### Content area

Prefer this order for console list pages:

1. Breadcrumb / page header.
2. Page info alert or risk hint when helpful.
3. Toolbar with primary actions, batch actions, and search/filter controls.
4. Table body.
5. Pagination.

Use a minimum content width around 1200px for table-heavy prototypes when possible. Do not replace list-management pages with marketing cards unless the requirement explicitly asks for that.

## Color Tokens

| Token | Suggested value | Use |
|---|---:|---|
| `--topbar` | `#242b3d` | Top navigation background |
| `--sidebar` | `#f3f6fa` | Sidebar background |
| `--sidebar-active` | `#d7e8ff` | Active sidebar item |
| `--primary` | `#1682e6` | Main actions, focus, links |
| `--primary-hover` | `#0f6fd0` | Primary hover |
| `--info-bg` | `#eaf6ff` | Page info alert background |
| `--info-text` | `#31445f` | Info alert text |
| `--border` | `#e5eaf1` | Default border |
| `--border-dark` | `#d5dce7` | Input border |
| `--text` | `#263238` | Main text |
| `--muted` | `#7b8794` | Secondary text |
| `--table-head` | `#f5f7fb` | Table header background |
| `--danger` | `#e34d59` | Delete/error/danger |
| `--success` | `#2ba471` | Success state |
| `--warning` | `#ed7b2f` | Warning state |
| `--shadow` | `0 8px 28px rgba(15, 23, 42, 0.18)` | Drawer/dialog shadow |

## Typography and Spacing

- Font stack: `-apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Microsoft YaHei", Arial, sans-serif` or the target project's existing stack.
- Base font size: 14px.
- Brand/title: 18px-20px, bold.
- Drawer/dialog title: 16px-17px, bold.
- Helper text: 12px, muted color.
- Table header text is bold; table body uses regular weight.
- Form field vertical spacing around 16px-20px.

## Component Patterns

### Page info alert

- Place below breadcrumb/header.
- Use light-blue background and concise explanatory copy.
- Avoid long multi-line business essays; link or fold details if needed.

### Toolbar

- Left side: primary action and batch actions.
- Right side: search box and filters.
- Use only real product operations; avoid `Demo`, `示例`, or review-helper buttons in product toolbar.
- Primary button uses blue background and white text; secondary button uses white background and gray border.

### Table

- Header height around 48px; row height around 52px.
- Header background uses `--table-head`.
- Common column order: checkbox, ID, name, target object, status/switch, scope, time, owner/user, operations.
- Long content uses ellipsis with title/tooltip for full text.
- Row actions use text buttons; common order is `编辑 / 删除`.

### Switches and permissions

- Compact switches are preferred for enable/disable.
- Enabled state uses primary blue; disabled/off state uses gray.
- No-permission state should disable or hide actions visibly and still mention backend enforcement in PRD/design.

### Right-side drawer

- Use create/edit/detail forms with right-side drawer.
- Width around 620px-720px.
- Structure: header, scrollable form body, fixed footer.
- Required fields use red asterisk.
- Footer buttons: primary `保存` / `确定`, secondary `取消`.

### Delete confirmation

- Use centered dialog or popconfirm.
- Title clearly states `删除确认` or equivalent.
- Body explains impact and whether history/logs remain.
- Confirm action uses danger visual style when available.

### User/person picker

- For selecting users, use a person selector rather than plain username textarea when the target product has one.
- Recommended prototype structure: selected-user tags, organization tree, search box, checkbox user list.
- Batch user-setting copy should clarify append vs overwrite; source examples use append + dedupe semantics.

## Interaction Rules

- Search boxes should filter table data in the prototype.
- Create/edit should open drawer instead of full-page navigation unless the requirement says otherwise.
- Delete requires second confirmation.
- Batch operation requires selected rows; no selection should show an actionable message.
- Loading, empty, success, error, disabled, no-permission, and no-result states should be demonstrable when they are part of the requirement.
- If the prototype has a permission toggle for reviewers, label it clearly as prototype helper and visually separate it from product UI.
- If a PRD submit/confirm action exists, the prototype must show resulting state change or message.

## Copy Rules

- Use real product copy, not `测试按钮`, `示例按钮`, or `Demo`.
- Error messages should be short and actionable, for example:
  - `请输入策略名称`
  - `请选择目标业务`
  - `请先选择策略`
  - `无操作权限`
- Risk copy for batch operations should clearly state whether data is appended, overwritten, deleted, or deduplicated.

## HTML Prototype Implementation

- Single-file HTML/CSS/JS.
- No external CDN.
- CSS variables in `:root`.
- JS only simulates necessary interactions; do not call backend APIs.
- Mock data should look like real business data: IDs, business names, users, periodic times, status, permission states.
- Prefer semantic HTML and accessible labels where practical.

## Reusable CSS Variable Snippet

```css
:root {
  --topbar: #242b3d;
  --sidebar: #f3f6fa;
  --sidebar-active: #d7e8ff;
  --primary: #1682e6;
  --primary-hover: #0f6fd0;
  --info-bg: #eaf6ff;
  --info-text: #31445f;
  --border: #e5eaf1;
  --border-dark: #d5dce7;
  --text: #263238;
  --muted: #7b8794;
  --table-head: #f5f7fb;
  --danger: #e34d59;
  --success: #2ba471;
  --warning: #ed7b2f;
  --shadow: 0 8px 28px rgba(15, 23, 42, 0.18);
}
```

## Unknowns

- Target project's exact brand/menu/product naming: Unknown.
- Exact Figma or screenshot source for a specific feature: Unknown.
- Whether a target project uses AOC4-style navigation or another Canway console shell: Unknown until verified.
