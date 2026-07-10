# Frontend Plan Output Template

Read this file only after current framework/components/state conventions, design contracts, and source-backed Visual Checks are known.

```markdown
# <Feature> Frontend Plan

## Global Constraints
- Framework/runtime: <source>
- Component library/design system: <source>
- Script/style conventions: <source>
- Visual source: <Figma / screenshot / existing page / settings>
- Verification commands: <source>

## 1. Page goal and visual contract
## 2. Component tree and template outline
## 3. State/API/interaction design
## 4. Style and responsive design
## 5. Visual and UX checks
## 6. Task breakdown

- [ ] **Task frontend-NNN: <component or behavior>**

**Files:**
- Create: `exact/path/to/new-file`
- Modify: `exact/path/to/existing-file`
- Test: `exact/path/to/test-file`

**Reasoning:**
- <independent boundary, source requirement, observable result>

**Depends on:** <None or exact existing task IDs>

**Interfaces:**
- Consumes: <existing/prior API/state/route/component/visual contract>
- Produces: <new API/state/route/component/classes/events/visual structure>
- Contract checks: <exact verification>

**Template Outline:**
- <source-backed container hierarchy, project components, slots, props, events>

**Script/State Outline:**
- <existing project pattern, state, derived values, loading, handlers>

**Style Outline:**
- <source-backed tokens/classes/layout/spacing>

**Visual / UX Checks:**
- <check traceable to design/settings/Figma/screenshot/current code>
```
