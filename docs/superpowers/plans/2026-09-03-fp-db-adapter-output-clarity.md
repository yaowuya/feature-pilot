# fp-db-adapter Output Clarity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the default adaptation proposal concise and approval-oriented while reporting phase-two success and failure item by item against the confirmed adaptation list.

**Architecture:** Keep all behavior guarantees in `SKILL.md`, retain the ten-group inspection matrix as the internal scan source, and add only presentation guidance to `adaptation-scope.md`. Update the default prompt, validate the source skill, synchronize it to the installed Codex copy, and compare both directories.

**Tech Stack:** Markdown skill instructions, YAML metadata, Codex `quick_validate.py`, textual contract checks, and recursive directory comparison.

---

## File Structure

- Modify `skills/fp-db-adapter/SKILL.md`: six-section default proposal, `A/V/Q` list, compact skipped summary, optional audit table, phase-two item states, success/failure details, and final result tables.
- Modify `skills/fp-db-adapter/references/adaptation-scope.md`: clarify that all ten groups are checked internally but compacted by default.
- Modify `skills/fp-db-adapter/agents/openai.yaml`: request concise approval-oriented output and itemized execution results.
- Synchronize the source directory to `/Users/sancifang/.codex/skills/fp-db-adapter`.

### Task 1: Establish the output contract

**Files:**
- Test: `skills/fp-db-adapter/SKILL.md`

- [ ] **Step 1: Run the pre-change contract check**

Run `rg -n "适配列表|已适配与跳过|改动明细|执行与验证|A1.*成功|失败步骤|实际适配内容或失败原因" skills/fp-db-adapter/SKILL.md`.

Expected: the complete concise-output and execution-result contract is absent.

- [ ] **Step 2: Fix the acceptance terms**

Require these concepts: six fixed proposal sections, `A/V/Q` identifiers, grouped skipped results, optional complete audit table, success/failure item states, actual adaptations, failure reason and impact, execution result table, and file result table.

### Task 2: Replace the phase-one output contract

**Files:**
- Modify: `skills/fp-db-adapter/SKILL.md`

- [ ] **Step 1: Define six fixed proposal headings**

Use exactly `适配结论`, `适配列表`, `已适配与跳过`, `改动明细`, `执行与验证`, and `方案汇总与确认` in that order.

Expected: the default output reads as one approval document rather than a scan transcript.

- [ ] **Step 2: Add the compact conclusion and adaptation list**

Require a small conclusion table and an adaptation-list table with columns `编号`, `适配内容`, `数据库`, `文件位置`, and `处理方式`. Define `A` as modifications, `V` as verification, and `Q` as missing information.

Expected: every `A/V/Q` row has one corresponding detail entry and no planned file is hidden.

- [ ] **Step 3: Compact adapted and non-applicable checks**

Require one short row per inspection group, combining adapted and non-applicable results without paths, anchors, or code blocks by default.

Expected: no needed, verification, or unknown item is hidden by compaction.

- [ ] **Step 4: Limit expanded details**

Expand only `A/V/Q` entries with reason, database, file, line, anchor, current state/code, planned state/code, risk, and verification. Merge repeated file context while preserving item identifiers.

Expected: each fact is fully stated once and referenced by identifier elsewhere.

- [ ] **Step 5: Add optional complete audit output**

Require a full table with columns `分组`, `检查内容`, `状态`, `结论`, and `证据位置` only when requested or needed for disputed, conflicting, high-risk, or unknown findings.

Expected: the optional table appears between compact skipped results and modification details without changing the six-section structure.

- [ ] **Step 6: Add concise execution and confirmation sections**

Require implementation order, separate Dameng and OceanBase verification, unavailable verification reasons, compact counts, unchanged-file statement, and `等待用户确认方案`.

Expected: the proposal stops after one confirmation request.

### Task 3: Add phase-two itemized outcome reporting

**Files:**
- Modify: `skills/fp-db-adapter/SKILL.md`

- [ ] **Step 1: Define item states**

Require `[A1 实施中]`, `[A1 成功]`, `[A1 失败]`, `[A1 跳过]`, `[V1 验证中]`, `[V1 验证通过]`, and `[V1 验证失败]` as applicable.

Expected: generic “completed” or “partially failed” output is prohibited.

- [ ] **Step 2: Define success output**

Every success must show actual file and location, actual adapted configuration/code/Migration/dependency, verification result, and deviation from plan.

- [ ] **Step 3: Define failure output**

Every failure must show failed step, concise accurate reason, produced modifications and their state, impact on later items, and next action.

Expected: related later work stops on material plan drift; independent work follows declared dependencies, and user changes are not automatically reverted.

- [ ] **Step 4: Define final result tables**

Require an execution table (`编号`, `适配项`, `结果`, `实际适配内容或失败原因`) and file table (`文件`, `对应编号`, `实际改动`, `验证结果`), followed by counts and separate database verification conclusions.

### Task 4: Update reference presentation and metadata

**Files:**
- Modify: `skills/fp-db-adapter/references/adaptation-scope.md`
- Modify: `skills/fp-db-adapter/agents/openai.yaml`

- [ ] **Step 1: Clarify internal scan versus default display**

State that all ten groups and items are still checked and retained internally, while default output compresses adapted/non-applicable items by group and expands only `A/V/Q` items.

- [ ] **Step 2: Update the default prompt**

Request an approval-summary-first proposal, table adaptation list, grouped skipped summary, and list-correlated success/failure reporting after confirmation.

- [ ] **Step 3: Run the complete textual contract check**

Run `rg -n "适配列表|已适配与跳过|改动明细|执行与验证|A1.*成功|失败步骤|实际适配内容或失败原因|完整检查明细" skills/fp-db-adapter/SKILL.md skills/fp-db-adapter/references/adaptation-scope.md`.

Expected: all output and implementation-result guarantees are present.

### Task 5: Validate, commit, install, and verify

**Files:**
- Validate: `skills/fp-db-adapter`
- Replace installed copy: `/Users/sancifang/.codex/skills/fp-db-adapter`

- [ ] **Step 1: Validate source**

Run `python3 /Users/sancifang/.codex/skills/.system/skill-creator/scripts/quick_validate.py skills/fp-db-adapter`.

Expected: `Skill is valid!`

- [ ] **Step 2: Review and commit source changes**

Run `git diff --check` and inspect `git diff -- skills/fp-db-adapter`. Stage only the three source files and commit with `feat: clarify database adaptation output`.

Expected: existing `.DS_Store` files remain untracked.

- [ ] **Step 3: Synchronize the installed copy**

Copy the validated source directory contents to `/Users/sancifang/.codex/skills/fp-db-adapter`.

- [ ] **Step 4: Validate and compare the installed copy**

Run `python3 /Users/sancifang/.codex/skills/.system/skill-creator/scripts/quick_validate.py /Users/sancifang/.codex/skills/fp-db-adapter`, then `diff -ru --exclude=.DS_Store skills/fp-db-adapter /Users/sancifang/.codex/skills/fp-db-adapter`.

Expected: validation succeeds and directory comparison produces no output.

- [ ] **Step 5: Verify repository state**

Run `git status --short --branch` and `git log -3 --oneline`.

Expected: the implementation commit follows this plan and the design commit; only pre-existing `.DS_Store` files remain untracked.
