# fp-prd Business-first Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan inline. Track steps with checkboxes; do not commit or push without an explicit user request.

**Goal:** Make PRD interviews and output explain business behavior before page changes, without changing the canonical PRD schema.

**Architecture:** `fp-prd-grill-me` owns business analysis and decisions, `prd-template.md` owns output slots and review, and `fp-prd` owns mode selection and write gates. A focused PowerShell contract test joins the existing plugin validation entrypoint.

**Tech Stack:** Markdown skills, PowerShell contract checks, read-only agent pressure scenarios.

## Global Constraints

- Preserve six top-level PRD headings, existing nested headings/table columns and complete four-subsection feature blocks.
- Preserve mutually exclusive small/split forms, 500-line / 30,000-character limits, explicit write approval and `/fp-start <slug>` handoff.
- Do not create consumer PRDs, change plugin version, sync installed runtimes, commit or push.
- Do not invent existing behavior or turn recommendations into confirmed product decisions.

## Task 1: Establish the regression

**Files:** Create `scripts/test-prd-business-contract.ps1`; record behavioral evidence in the validation report next to this plan.

- [x] Read the article, the three PRD skill/template files and artifact-layout contract.
- [x] Run the old skill with seven unresolved high-impact decisions and five-question pressure. Observed: duplicate-submission handling and acceptance criteria were downgraded to Bucket B.
- [x] Add focused checks for business-analysis order, evidence-based no-change decisions, question-budget safety, prototype limits, template content slots and unchanged headings/tables.
- [x] Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-prd-business-contract.ps1`; confirm failure because the old skill lacks the new business-analysis contract.

## Task 2: Implement the business-first contract

**Files:** Modify `skills/fp-prd-grill-me/SKILL.md`, `skills/fp-prd/SKILL.md`, `skills/fp-prd/prd-template.md`, `commands/fp-prd.md`, `docs/user_guide/init-prd-start.md`, `scripts/validate-plugin.ps1`.

**Consumes:** Confirmed facts, user decisions and the existing PRD/prototype mode.
**Produces:** Business-closed requirements in the unchanged logical PRD schema; unresolved risks stay in the interview.

- [x] Insert Business-first analysis before decision classification: current flow, target flow, change/actor/system impact, state/rule/exception closure, then page mapping. Include greenfield/simple-flow applicability and evidence requirements.
- [x] Replace the five-question downgrade rule with prioritization and continuation; zero unresolved decisions do not require fabricated questions.
- [x] Require prototype-visible business decisions first, preserve unseen business unknowns until PRD confirmation.
- [x] Replace the page-click example in chapter two with a business-oriented generic flow. Add bold content slots inside existing headings; keep all table headers unchanged.
- [x] Add remove-the-pages, state/rule/exception closure and no-change-evidence self-review. Product ambiguities return to interview; the agent may repair formatting independently.
- [x] Update the short command checksum and the user guide, then wire the focused script into `validate-plugin.ps1` with the existing existence/exit-code pattern.
- [x] Run the focused script and confirm it passes.

## Task 3: Verify compatibility and behavior

**Files:** Create `docs/superpowers/plans/2026-09-08-fp-prd-business-first-validation.md`.

- [x] Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/validate-plugin.ps1` and record the actual exit/result.
- [x] Run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/test-artifact-layout.ps1` to exercise small/split PRD compatibility.
- [x] Re-run a fresh agent on the seven-decision pressure scenario and prototype scenario. Also test greenfield and simple copy/filter applicability; report observed behavior, not statistical reliability.
- [x] Review the diff for duplicated authority, scope creep, heading/table drift and unresolved-business self-answering shortcuts.
- [x] Run `git diff --check`; record tests and limitations. Mark the plan complete only for work actually performed.
