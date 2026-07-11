# FeaturePilot Artifact Splitting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement mutually exclusive small/split artifact layouts for PRD, proposal, design, and task plans, plus explicit-only `fp-prd` discovery and deterministic validation.

**Architecture:** A new shared artifact-layout contract defines paths, semantic splitting, size limits, index manifests, ownership, resolution, and strict historical-layout rejection. Producers select one final representation before writing; consumers resolve through the shared contract; PowerShell validation proves layout invariants and repository prompt coverage.

**Tech Stack:** Markdown skills/templates, Claude/Codex plugin metadata, PowerShell 7-compatible validation scripts, Git-based verification.

## Global Constraints

- Semantic splitting is primary; every Markdown artifact file has a hard maximum of 500 lines or 30,000 characters.
- `prd.md`/`prd/`, `proposal.md`/`proposal/`, each design end file/directory, and each plan end file/directory are mutually exclusive for new output.
- Split form uses its directory `00-index.md` as the only canonical entrypoint; no external surrogate summary file is generated.
- `tasks/00-overview.md` exists only when both backend and frontend plans exist and owns only cross-end data.
- Indexes own order and ownership metadata, not detailed body content or executable task checkboxes.
- Historical and dual layouts are rejected in both Producer and Consumer modes until explicitly migrated to one canonical form.
- `fp-prd` discovery applies only to explicit `/fp-prd`, `$fp-prd`, or explicit PRD-authoring intent.
- Preserve the user's staged `scripts/test-sdd-benchmark-fixture.ps1` change; do not edit, unstage, or include it in commits.

---

### Task 1: Add deterministic artifact-layout validation

**Files:**
- Create: `scripts/validate-artifact-layout.ps1`
- Create: `scripts/test-artifact-layout.ps1`

**Interfaces:**
- Consumes: a change directory containing any in-progress subset of PRD, proposal, design, and tasks.
- Produces: `validate-artifact-layout.ps1 -ChangePath <path> -Mode Producer|Consumer`; exit zero with a summary for valid layouts and throw `Artifact layout invalid: ...` for every invalid layout in either mode.

- [ ] **Step 1: Write the failing test harness**

Create a table-driven PowerShell test script with helpers:

```powershell
function Assert-Condition([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "Test failed: $Message" }
}

function Assert-ThrowsLike([scriptblock]$Action, [string]$Pattern) {
    try { & $Action; throw "Expected failure matching: $Pattern" }
    catch { Assert-Condition ($_.Exception.Message -like "*$Pattern*") $_.Exception.Message }
}
```

The harness must create fixtures beneath one verified temporary root and cover: valid small forms, template-shaped split forms in Producer and Consumer modes, every file/directory conflict in both modes, missing/wrong `## Fragment Manifest`, missing/unindexed fragments, 501 lines, 30,001 characters, duplicate task identity/checkbox, forbidden checkbox locations, invalid overview applicability, missing same-end/cross-end task IDs, dependency cycles, current overview schema/derived totals, malformed/missing/reversed/duplicate/unknown/self/undeclared cross-end edges, stage-without-edge rejection, old overview rejection, exact metadata-only design index mapping, split plan Kind cardinality, bounded logical PRD/proposal template validation, root historical design rejection, and aggregated conflict reporting.

- [ ] **Step 2: Run the test to verify RED**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\test-artifact-layout.ps1`

Expected: FAIL because `scripts\validate-artifact-layout.ps1` does not exist.

- [ ] **Step 3: Implement the validator**

Use this public parameter contract and internal responsibility split:

```powershell
param(
    [Parameter(Mandatory)] [string]$ChangePath,
    [ValidateSet('Producer', 'Consumer')] [string]$Mode = 'Producer'
)

function Get-TextMetrics([string]$Path) { }
function Read-FragmentManifest([string]$IndexPath) { }
function Test-ExclusiveRepresentation([string]$FilePath, [string]$IndexPath, [string]$Label) { }
function Test-SplitDirectory([string]$Directory, [string]$Label) { }
function Get-TaskGraph([string[]]$Files) { }
function Test-TaskDependencyGraph([object]$Graph) { }
function Test-TaskOverview([string]$TasksDirectory, [object]$Graph, [hashtable]$Representations) { }
function Test-ChangeArtifacts([string]$ResolvedChangePath, [string]$ValidationMode) { }
```

Implement `Read-FragmentManifest` against the exact `## Fragment Manifest` plus `| Order | File | Kind | Owns |` table, resolve fragment paths relative to the index, reject path escape, and compare the manifest with direct sibling `*.md` files excluding `00-index.md`. Validate bounded logical PRD/proposal structure after manifest concatenation; require exact metadata-only design-index mappings; enforce one context/interface/coverage and one-or-more tasks rows; derive the complete dependency graph and progress from owner files; and require every owner-declared cross-end dependency as one exact overview edge. Avoid scalar `.Count` assumptions so singleton rows behave identically in pwsh and Windows PowerShell. In both Producer and Consumer modes, reject every mutually exclusive pair and every unsupported root historical design path before parsing artifact content. Do not parse old index/overview grammars or apply legacy size exceptions.

- [ ] **Step 4: Run the validator tests to verify GREEN**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\test-artifact-layout.ps1`

Expected: PASS with a final count covering every listed fixture class under both pwsh and Windows PowerShell, repeated to prove deterministic singleton-edge parsing.

- [ ] **Step 5: Commit the isolated validator task when authorized**

Stage only the two new script paths and commit with `test: add artifact layout validator`; never include the pre-staged benchmark fixture.

---

### Task 2: Establish the shared artifact-layout contract

**Files:**
- Create: `skills/_shared/artifact-layout.md`
- Modify: `skills/_shared/workspace-rules.md`
- Modify: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: confirmed design at `docs/superpowers/specs/2026-07-11-featurepilot-artifact-splitting-design.md`.
- Produces: one normative shared contract referenced by producers and consumers; repository validation anchors for its paths, limits, manifest, mutual exclusion, and historical-layout rejection.

- [ ] **Step 1: Add failing shared-contract assertions**

Extend `scripts/validate-plugin.ps1` to require `skills/_shared/artifact-layout.md` and these exact anchors: `500 lines`, `30,000 characters`, `mutually exclusive`, `| Order | File | Kind | Owns |`, `prd/00-index.md`, `proposal/00-index.md`, `design/backend/00-index.md`, `design/frontend/00-index.md`, `tasks/backend/00-index.md`, `tasks/frontend/00-index.md`, `Producer`, and `Consumer`.

- [ ] **Step 2: Run repository validation to verify RED**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate-plugin.ps1`

Expected: FAIL because the shared artifact-layout file is missing.

- [ ] **Step 3: Write the shared contract and route workspace rules to it**

Write the confirmed canonical layout, semantic split selection, dual safety limits, manifest schema, unique ownership rules, task overview condition, producer resolution, consumer resolution, and absolute rejection of historical/dual layouts. Keep `workspace-rules.md` concise by replacing its duplicated design/task layout paragraphs with a mandatory reference to `artifact-layout.md`.

- [ ] **Step 4: Run repository and artifact validation**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate-plugin.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\test-artifact-layout.ps1
```

Expected: both PASS.

- [ ] **Step 5: Commit the isolated shared-contract task when authorized**

Commit only the three task paths with `docs: define canonical artifact layout`.

---

### Task 3: Update PRD and proposal producers and fix PRD discovery

**Files:**
- Modify: `skills/fp-prd/SKILL.md`
- Modify: `skills/fp-prd/prd-template.md`
- Modify: `skills/fp-prd-grill-me/SKILL.md`
- Modify: `skills/fp-propose/SKILL.md`
- Modify: `skills/fp-propose/proposal-template.md`
- Modify: `commands/fp-prd.md`
- Modify: `commands/fp-propose.md`
- Modify: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: shared artifact-layout contract and existing PRD/proposal confirmation gates.
- Produces: small-or-split PRD/proposal output contracts and explicit-only `fp-prd` discovery metadata.

- [ ] **Step 1: Add failing producer and trigger assertions**

Extract `fp-prd` frontmatter in `validate-plugin.ps1` and assert the exact description:

```text
Use when a user explicitly invokes /fp-prd or $fp-prd, or explicitly asks to create, write, revise, or complete a PRD or product requirements document.
```

Also require both PRD/proposal skills and templates to mention their file/directory pairs, fragment manifest, logical template validation, and mutual exclusion. Reject the old `provides a product idea, feature request, user story, pain point, rough requirement` trigger text.

- [ ] **Step 2: Run repository validation to verify RED**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate-plugin.ps1`

Expected: FAIL on the old broad `fp-prd` description and missing split contracts.

- [ ] **Step 3: Implement PRD and proposal split production**

Update output-path summaries, pre-write selection, overwrite/conflict handling, write confirmation, self-review, and handoff reads. Preserve the exact mandatory PRD and proposal logical section order across indexed fragments. Keep prototype output at `prototype.html` and reference it from the unique PRD owner fragment.

- [ ] **Step 4: Run repository validation**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate-plugin.ps1`

Expected: PASS through PRD/proposal and discovery assertions.

- [ ] **Step 5: Commit the isolated producer task when authorized**

Commit only the listed PRD/proposal paths and validation changes with `feat: split large requirement artifacts`.

---

### Task 4: Replace design stable-entrypoint splitting with exclusive forms

**Files:**
- Modify: `skills/fp-brainstorm/SKILL.md`
- Modify: `skills/fp-brainstorm/design-template.md`
- Modify: `skills/fp-figma/SKILL.md`
- Modify: `skills/fp-ui-spec/SKILL.md`
- Modify: `skills/fp-ux-spec/SKILL.md`
- Modify: `commands/fp-brainstorm.md`
- Modify: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: proposal resolver and shared artifact-layout contract.
- Produces: `design/backend.md` or `design/backend/00-index.md`, and `design/frontend.md` or `design/frontend/00-index.md`, never both for new output.

- [ ] **Step 1: Add failing design assertions**

Require every design producer/helper to reference `../_shared/artifact-layout.md` through its correct relative route, require `500` and `30,000` selection, and reject wording that keeps an end `.md` summary next to its split directory.

- [ ] **Step 2: Run repository validation to verify RED**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate-plugin.ps1`

Expected: FAIL because current design rules retain the stable entrypoint in split mode.

- [ ] **Step 3: Implement exclusive design forms**

Update pre-write approval scope, output verification, resume behavior, frontend Visual Source/component mapping/Visual Checks ownership, Figma writes, and historical-layout rejection. `design/00-index.md` points directly to either the end file or the end directory index.

- [ ] **Step 4: Run repository validation**

Expected command: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate-plugin.ps1`

Expected: PASS through design producer/helper assertions.

- [ ] **Step 5: Commit the isolated design task when authorized**

Commit only the listed paths with `feat: use exclusive design artifact forms`.

---

### Task 5: Replace plan stable-entrypoint splitting with exclusive end directories

**Files:**
- Modify: `skills/fp-plan/SKILL.md`
- Modify: `skills/fp-plan/task-layout-template.md`
- Modify: `skills/fp-plan-backend/SKILL.md`
- Modify: `skills/fp-plan-backend/plan-template.md`
- Modify: `skills/fp-plan-frontend/SKILL.md`
- Modify: `skills/fp-plan-frontend/plan-template.md`
- Modify: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: proposal/design resolvers and shared artifact-layout contract.
- Produces: one small file or one split directory per end, task-kind fragments with unique IDs/checkboxes, and a two-end-only overview.

- [ ] **Step 1: Add failing plan assertions**

Require the exact exclusive pairs, proposal/design XOR-before-read resolution, complete manifest-ordered logical handoff to child planners, directory manifest Kind cardinality, context/interface/coverage ownership, two-end-only current overview condition, unique task ownership, and absence of stable-entrypoint/body-link fragment hints or the old `stable file becomes concise ... and executable tasks move` rule.

- [ ] **Step 2: Run repository validation to verify RED**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate-plugin.ps1`

Expected: FAIL on current stable-file-plus-directory plan wording.

- [ ] **Step 3: Implement the plan layouts**

Update backend/frontend input resolution so proposal and the selected design end are resolved as small XOR split before any content read; split content comes from the complete manifest, and the parent passes logical content plus canonical entry/mode/ordered paths to children. Update output contracts so split plans write all constraints, ledgers, task groups, and coverage into indexed end directories. Change `task-layout-template.md` to the `Order/File/Kind/Owns` manifest with exact Kind cardinality and make `tasks/00-overview.md` contain only required end entries/totals and optional real cross-end edges/stages.

- [ ] **Step 4: Run repository and artifact tests**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate-plugin.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\test-artifact-layout.ps1
```

Expected: both PASS.

- [ ] **Step 5: Commit the isolated plan task when authorized**

Commit only the listed paths with `feat: simplify split task plan layout`.

---

### Task 6: Update orchestration and downstream consumers

**Files:**
- Modify: `skills/fp-start/SKILL.md`
- Modify: `skills/fp-execute/SKILL.md`
- Modify: `skills/fp-execute-sdd/SKILL.md`
- Modify: `skills/fp-execute-sdd/task-brief-template.md`
- Modify: `skills/fp-execute-sdd/review-package-template.md`
- Modify: `skills/fp-review/SKILL.md`
- Modify: `skills/fp-review/final-reviewer.md`
- Modify: `skills/fp-review/final-review-template.md`
- Modify: `skills/fp-archive/SKILL.md`
- Modify: `commands/fp-start.md`
- Modify: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: shared resolver, canonical layouts, historical-layout rejection, unique task ownership, and two-end overview semantics.
- Produces: consistent resume, execution, review, and archive behavior for canonical small or split artifacts only.

- [ ] **Step 1: Add failing consumer assertions**

For each consumer, require the shared contract, canonical file/directory alternatives, manifest order, producer/consumer distinction, unindexed-fragment rejection, unique task owner, and two-end overview semantics. Reject unconditional reads of `plan-backend.md` or `plan-frontend.md` before checking the split directory.

- [ ] **Step 2: Run repository validation to verify RED**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate-plugin.ps1`

Expected: FAIL on current stable-entrypoint-first consumer logic.

- [ ] **Step 3: Implement shared resolution across consumers**

Make start/resume, execute, SDD briefs/packages, final review, and archive all use the same canonical-first resolution. SDD briefs/packages record canonical entry, resolution mode, and ordered fragments independently for PRD, proposal, both design ends, and both plan ends so mixed small/split state is explicit. In Consumer mode, reject old combined layouts and root historical designs; require an explicitly approved migration to merge or transfer required content, delete obsolete paths, and validate one canonical form before continuing. Recompute overview progress only when both ends exist.

- [ ] **Step 4: Run all deterministic tests**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate-plugin.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\test-artifact-layout.ps1
```

Expected: both PASS.

- [ ] **Step 5: Commit the isolated consumer task when authorized**

Commit only the listed paths with `refactor: resolve canonical artifact layouts`.

---

### Task 7: Align repository contracts and user documentation

**Files:**
- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `docs/user_guide/init-prd-start.md`
- Modify: `.codex-plugin/plugin.json`
- Modify: `scripts/validate-plugin.ps1`

**Interfaces:**
- Consumes: implemented producer/consumer behavior.
- Produces: public documentation and Codex interface metadata that describe explicit PRD invocation and the exclusive split layout.

- [ ] **Step 1: Add failing documentation assertions**

Require all public docs to contain `500`, `30,000`, `prd/00-index.md`, `proposal/00-index.md`, direct design/task directory entrypoints, explicit PRD-authoring intent, and the same exact `/fp-prd` / `$fp-prd` / create-write-revise-complete public trigger sentence. Reject claims that rough ideas automatically invoke `fp-prd` and claims that split plans retain stable plan files.

- [ ] **Step 2: Run repository validation to verify RED**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate-plugin.ps1`

Expected: FAIL on stale public layout and trigger guidance.

- [ ] **Step 3: Update public docs and interface metadata**

Document the small/split table, semantic-first rule, dual safety limits, two-end overview, strict historical-layout rejection, and explicit `fp-prd` discovery. Update the Codex long description only where it describes split behavior; preserve plugin name, base version compatibility, and unrelated interface fields.

- [ ] **Step 4: Run repository validation**

Run: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate-plugin.ps1`

Expected: PASS.

- [ ] **Step 5: Commit the isolated documentation task when authorized**

Commit only the listed paths with `docs: explain exclusive artifact splitting`.

---

### Task 8: Run integration, external compatibility, and trigger regression

**Files:**
- Modify if gaps are found: only files already listed in Tasks 1–7
- Verify: `docs/superpowers/specs/2026-07-11-featurepilot-artifact-splitting-design.md`
- Verify: `docs/superpowers/plans/2026-07-11-featurepilot-artifact-splitting-implementation.md`

**Interfaces:**
- Consumes: completed implementation and read-only external example.
- Produces: final evidence for every acceptance criterion, including fresh-context discovery behavior.

- [ ] **Step 1: Run full deterministic validation**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate-plugin.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\test-artifact-layout.ps1
git diff --check
```

Expected: both scripts PASS and `git diff --check` prints no errors.

- [ ] **Step 2: Validate the cited external example in consumer mode**

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\validate-artifact-layout.ps1 -ChangePath 'D:\02-canway\01-code\auto-ops-platform\fp-docs\changes\business-assurance-policy' -Mode Consumer
```

Expected: FAIL identifying `plan-backend.md` plus `tasks/backend/` and `plan-frontend.md` plus `tasks/frontend/` as mutually exclusive conflicts; no external files are modified.

- [ ] **Step 3: Prove producer mode rejects the cited layout**

Run the same validator with `-Mode Producer`.

Expected: FAIL identifying `plan-backend.md` plus `tasks/backend/` and `plan-frontend.md` plus `tasks/frontend/` as mutually exclusive conflicts.

- [ ] **Step 4: Run fresh-context trigger tests**

Use fresh agents with only the updated `fp-prd` frontmatter description and one user request per sample. Run at least five negative samples across ordinary feature work, bugfix, repository maintenance, `/goal`, and a plain product idea; all must decline `fp-prd`. Run positive controls for `/fp-prd`, `$fp-prd`, and explicit “编写正式 PRD”; all must select it and then load `fp-prd-grill-me`.

- [ ] **Step 5: Audit the final diff against the design**

Map each of the 11 acceptance criteria to a current file, deterministic command output, or fresh-context trigger result. Confirm `git status --short` still shows the user's pre-existing staged benchmark fixture unchanged and excludes it from this work's diff summary.

- [ ] **Step 6: Commit or hand off when authorized**

If commits were authorized, create the final integration commit from only this change's paths. Otherwise leave changes uncommitted and provide exact paths and validation output for user review.
