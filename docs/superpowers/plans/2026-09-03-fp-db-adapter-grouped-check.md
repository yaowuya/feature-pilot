# fp-db-adapter Grouped Check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `fp-db-adapter` inspect database adaptation work in fixed groups, report every item with evidence and a fixed status, then present one consolidated plan for confirmation before implementation.

**Architecture:** Keep workflow and output guarantees in `SKILL.md`, and place the reusable ten-group inspection matrix in `references/adaptation-scope.md`. Update the default prompt, validate the source skill, synchronize it to the installed Codex directory, and verify both copies are identical.

**Tech Stack:** Markdown skill instructions, YAML metadata, Codex `quick_validate.py`, text contract checks, and directory comparison.

---

## File Structure

- Modify `skills/fp-db-adapter/SKILL.md`: grouped workflow, statuses, output contract, confirmation gate, and implementation progress.
- Modify `skills/fp-db-adapter/references/adaptation-scope.md`: ten-group inspection matrix for Dameng and OceanBase.
- Modify `skills/fp-db-adapter/agents/openai.yaml`: grouped-flow default invocation.
- Synchronize to `/Users/sancifang/.codex/skills/fp-db-adapter`: installed Codex copy.

### Task 1: Establish the textual contract

**Files:**
- Test: `skills/fp-db-adapter/SKILL.md`
- Test: `skills/fp-db-adapter/references/adaptation-scope.md`

- [ ] **Step 1: Run the pre-change check**

Run `rg -n "固定检查分组|已适配，跳过|检查项总数|项目与适配模式识别|测试和验证能力" skills/fp-db-adapter/SKILL.md skills/fp-db-adapter/references/adaptation-scope.md`.

Expected: the complete contract is absent, especially the fixed status phrase and ten group boundaries.

- [ ] **Step 2: Fix the acceptance terms**

Require these exact concepts: `固定检查分组`, `[已适配，跳过]`, `[需要适配]`, `[待验证]`, `[不适用，跳过]`, `[无法判断]`, `检查项总数`, `项目与适配模式识别`, and `测试和验证能力`.

Expected: Tasks 2 and 3 make every concept discoverable in the source files.

### Task 2: Implement grouped workflow and output rules

**Files:**
- Modify: `skills/fp-db-adapter/SKILL.md`

- [ ] **Step 1: Require one uninterrupted read-only scan**

Add rules to inspect `references/adaptation-scope.md` in fixed order, finish all groups without intermediate confirmation, retain non-applicable groups, and request one confirmation only after the complete plan.

Expected: project edits remain prohibited before confirmation.

- [ ] **Step 2: Define the five statuses**

Use these exact semantics:

```markdown
- `[已适配，跳过]`：证据充分，输出“<检查项> 已适配，跳过”。
- `[需要适配]`：确认缺失或不兼容，纳入适配方案。
- `[待验证]`：静态扫描无法证明兼容或风险较高，纳入验证方案。
- `[不适用，跳过]`：不属于当前项目或数据库范围，说明原因后跳过。
- `[无法判断]`：缺少必要信息，列出需要补充的内容。
```

Expected: filenames, comments, or declarations alone are not proof of adaptation.

- [ ] **Step 3: Require evidence for every item**

Every item must contain its number and name, status, explicit conclusion, path and current line when available, stable anchor when available, reasoning, and disposition.

Expected: adapted and skipped items remain visible.

- [ ] **Step 4: Extend plans and summary**

For `[需要适配]` and `[待验证]`, require file, line, anchor, current code, planned code, risk, dependency, order, and verification. The summary must count every status and state adaptation mode, database scope, execution order, and `等待用户确认方案`.

Expected: `[无法判断]` blocks confirmation when missing information can alter the plan.

- [ ] **Step 5: Reuse item numbers in phase two**

Require progress such as `[3.2 实施中]`, `[3.2 已完成]`, and `[5.3 验证失败]`.

Expected: implementation maps to confirmed entries and does not modify adapted or non-applicable items.

### Task 3: Build the ten-group matrix

**Files:**
- Modify: `skills/fp-db-adapter/references/adaptation-scope.md`

- [ ] **Step 1: Define exact group boundaries**

Use: project/mode identification; Python/system dependencies; drivers/backends; connection configuration; Migration mechanism; existing Migration files; ORM/raw SQL; initialization/upgrade/operations scripts; deployment/images/environment; tests/verification.

Expected: all ten numbered groups always appear.

- [ ] **Step 2: Populate concrete checks**

Cover project type and Git state; mode/scope evidence; Python, Django, `cw-cornerstone`, drivers and system packages; backend registration; connection branches, ports, schema, charset, credentials and fallbacks; patch registration/routing; original and third-party migrations; SQL and ORM operations; operational scripts; deployment variants; static, migration-plan, real-connection, and business read/write verification.

Expected: scope `all` evaluates Dameng and OceanBase independently.

- [ ] **Step 3: Preserve safeguards**

Keep AutoOps/BlueKing conventions conditional, preserve MySQL fallback unless removal is requested, and do not expand to unrelated databases.

Expected: generic Django projects do not inherit platform-specific paths or versions.

### Task 4: Update metadata, validate, and commit

**Files:**
- Modify: `skills/fp-db-adapter/agents/openai.yaml`

- [ ] **Step 1: Update `default_prompt`**

Set it to request automatic mode/scope detection, fixed grouped checks, visible `已适配，跳过` output, detailed location-aware plans for gaps, and one consolidated confirmation.

Expected: the skill name stays `fp-db-adapter`.

- [ ] **Step 2: Run the contract check again**

Run `rg -n "固定检查分组|已适配，跳过|检查项总数|项目与适配模式识别|测试和验证能力" skills/fp-db-adapter/SKILL.md skills/fp-db-adapter/references/adaptation-scope.md`.

Expected: every contract concept is present.

- [ ] **Step 3: Validate the source skill**

Run `python /Users/sancifang/.codex/skills/.system/skill-creator/scripts/quick_validate.py skills/fp-db-adapter`.

Expected: `Skill is valid!`

- [ ] **Step 4: Inspect changes**

Run `git diff --check`, then `git diff -- skills/fp-db-adapter`.

Expected: no whitespace errors and no unrelated changes.

- [ ] **Step 5: Commit only the three source files**

Stage `SKILL.md`, `adaptation-scope.md`, and `openai.yaml`; commit with `feat: add grouped database adaptation checks`.

Expected: `.DS_Store` remains untracked.

### Task 5: Load into Codex and verify parity

**Files:**
- Replace installed copy: `/Users/sancifang/.codex/skills/fp-db-adapter`

- [ ] **Step 1: Synchronize the complete source directory**

Replace stale installed contents with the validated source directory, including `SKILL.md`, `agents/openai.yaml`, and all three reference files.

Expected: no obsolete files remain in the installed copy.

- [ ] **Step 2: Validate the installed skill**

Run `python /Users/sancifang/.codex/skills/.system/skill-creator/scripts/quick_validate.py /Users/sancifang/.codex/skills/fp-db-adapter`.

Expected: `Skill is valid!`

- [ ] **Step 3: Compare both copies**

Run `diff -ru --exclude=.DS_Store skills/fp-db-adapter /Users/sancifang/.codex/skills/fp-db-adapter`.

Expected: no output and exit status `0`.

- [ ] **Step 4: Verify repository state**

Run `git status --short --branch` and `git log -2 --oneline`.

Expected: the feature commit follows the design commit; only pre-existing `.DS_Store` files remain untracked.
