# fp-db-adapter Planning Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `fp-db-adapter` automatically classify adaptation stage and database scope, require a detailed file-and-code-level plan before editing, and summarize verified implementation after explicit user approval.

**Architecture:** Keep routing, classification, and the confirmation gate in `SKILL.md`; keep project-wide scan criteria in `references/adaptation-scope.md`; keep migration safety and verification details in `references/compatibility-checklist.md`; preserve `references/autoops-patterns.md` as a conditional AutoOps/BlueKing reference. Update UI metadata so discovery describes the new workflow without loading implementation detail into frontmatter.

**Tech Stack:** Codex skill Markdown, YAML UI metadata, `quick_validate.py`, `rg`, Git.

---

### Task 1: Replace the entry workflow with classification and confirmation gates

**Files:**
- Modify: `skills/fp-db-adapter/SKILL.md:1-90`

- [ ] **Step 1: Record the missing-contract baseline**

Run:

```bash
rg -n "全新适配|增量适配|阶段一|明确确认|实质性.*漂移|全量.*达梦.*OceanBase" skills/fp-db-adapter/SKILL.md
```

Expected: no complete two-stage contract is found; the current file only routes between migration errors and generic adaptation.

- [ ] **Step 2: Replace the frontmatter and task-routing introduction**

Use this concise frontmatter:

```yaml
---
name: fp-db-adapter
description: 为 Django/Python SaaS 项目审计、规划和实施达梦及 OceanBase 数据库适配，自动判断全新或增量适配以及单库或全量范围。适用于首次信创接入、已有适配补全、migration 报错定位和兼容性验证；任何项目修改前必须先输出详细方案并获得用户确认。
---
```

Replace the old “迁移报错定位 / 单纯适配” top-level split with these sections:

```markdown
## 不可跳过的两阶段门禁

每次任务都从阶段一开始。即使用户在首次请求中说“直接修改”或“自动执行”，也先完成扫描、输出方案并停止；只有用户看到当前方案后明确确认，才能进入阶段二。

### 阶段一：扫描与方案

- 只读取和分析项目、Git 状态及用户日志；不编辑、创建、删除或格式化项目文件。
- 自动判断适配类型、数据库范围和项目类型，并列出证据。
- 按实际项目结构扫描配置、依赖、migration、补丁、SQL/ORM 和部署描述。
- 输出文件级详细方案和总结，然后明确请求确认并结束当前轮。

### 阶段二：实施与验证

- “确认”“按方案执行”“确认实施”等对当前完整方案的明确授权才可进入本阶段。
- 提问、补充日志、修改要求、只认可局部内容或首次请求中的预授权均不视为确认。
- 只实施已确认的文件和数据库范围，并执行方案中的验证。
- 出现实质性方案漂移时立即停止，输出补充方案并重新确认。
```

Define material drift exactly as: touching an unlisted project file; removing a business constraint; modifying an already-applied original migration instead of an accepted patch/follow-up mechanism; changing database scope; changing a dependency major version or database infrastructure; or invalidating the core approach/risk assessment. State that line-number movement alone is not material drift.

- [ ] **Step 3: Add deterministic adaptation-stage classification**

Add rules with these outcomes:

```text
全新适配：项目整体缺少目标数据库配置、依赖和迁移补丁能力，且任务是首次接入。
增量适配：存在任一目标数据库配置、补丁机制、补丁文件，或用户正在修复/补全已有适配。
冲突规则：有增量强证据时优先判为增量，保护已有迁移历史。
不确定规则：只询问一个决定分支的关键问题，不把推断写成确定事实。
```

Require the conclusion to cite concrete file, configuration, and log evidence.

- [ ] **Step 4: Add deterministic database-scope classification**

Define only these supported scopes:

```text
dameng：仅达梦
oceanbase：仅 OceanBase
all：达梦 + OceanBase
```

Apply this priority: explicit user scope; single-database error log; “全量/全部/全库” means `all`; otherwise recommend from project gaps. State that inferred scope remains a proposal until confirmed and must never expand to unsupported databases.

- [ ] **Step 5: Add the exact planning output contract**

Require these top-level sections in every phase-one response:

```text
适配结论
当前状态总结
文件级修改方案
迁移补丁方案（存在 migration 改动时）
验证方案
方案总结与确认
```

For every planned file require: path; create/modify/delete action; current real line number plus stable anchor; relevant current code; planned code or deterministic generation rule; reason and target database; impact/risk; verification. For absent files require “文件不存在，计划新建” and forbid invented line numbers.

- [ ] **Step 6: Add the implementation summary contract and reference routing**

Require final stage-two output to report: final classification and scope; actual files with final line numbers and anchors; migration compatibility points; plan/implementation differences; exact verification commands and outcomes; explicit separation of static and live-database verification; remaining risks and release notes.

Route references as follows:

```markdown
- 全新或增量适配审计时，读取 `references/adaptation-scope.md`。
- 涉及 migration 扫描、报错或补丁时，读取 `references/compatibility-checklist.md`。
- 仅在确认是 AutoOps、蓝鲸项目或使用其同类约定时，读取 `references/autoops-patterns.md`；普通 Django 项目不得套用其中固定版本和平台变量。
```

- [ ] **Step 7: Verify the entry contract is present**

Run:

```bash
rg -n "全新适配|增量适配|阶段一：扫描与方案|阶段二：实施与验证|全量.*达梦.*OceanBase|文件级修改方案|实质性方案漂移|未做目标库实连验证" skills/fp-db-adapter/SKILL.md
```

Expected: every contract is present, with both stages and all three supported scopes discoverable in the entry file.

- [ ] **Step 8: Commit the entry workflow**

```bash
git add skills/fp-db-adapter/SKILL.md
git commit -m "feat: gate database adaptation behind confirmed plans"
```

### Task 2: Add project classification and scope-aware scan guidance

**Files:**
- Modify: `skills/fp-db-adapter/references/adaptation-scope.md:1-145`

- [ ] **Step 1: Record the scan-guidance baseline**

Run:

```bash
rg -n "判定证据|全新适配|增量适配|通用 Django|依赖管理入口|Git" skills/fp-db-adapter/references/adaptation-scope.md
```

Expected: the reference lists fixed example paths but has no complete classification or project-discovery matrix.

- [ ] **Step 2: Replace the fixed-path introduction with project discovery**

State that paths are examples, not requirements. Require discovery of:

```text
Python/Django version
settings and environment-loading entrypoints
dependency manifest and lock files
current database backends and DATABASE_TYPE selection
INSTALLED_APPS and DEFAULT_AUTO_FIELD
migration and patch directories
deployment descriptors
Git changes that affect scanned files
available target-database connections
```

Require classification as general Django, BlueKing SaaS, AutoOps, or another evidenced project type.

- [ ] **Step 3: Add the new-versus-incremental evidence matrix**

Create a compact table with rows for database branches, patch registration, patch directories, target drivers/backends, user intent, and migration-error evidence. Columns must explain what each observation means for full-new versus incremental classification. Add the conflict rule that existing target support or repair language is strong incremental evidence.

- [ ] **Step 4: Make every scan domain scope-aware**

For configuration, dependencies, migrations, SQL/ORM, and deployment descriptors, state:

- inspect only Dameng for `dameng`;
- inspect only OceanBase for `oceanbase`;
- inspect both independently for `all`, without assuming one database's success covers the other;
- preserve MySQL fallback unless the user explicitly requests otherwise;
- do not add target-specific dependencies or files without evidence that the selected scope needs them.

- [ ] **Step 5: Add evidence classifications for findings**

Require each finding to be labelled:

```text
明确需要修改：project fact or verified incompatibility directly supports the change.
高风险待验证：credible target-database risk exists but needs a live database.
暂不修改：no evidence supports changing it.
```

This prevents creating patches for every keyword match.

- [ ] **Step 6: Verify the scan matrix**

Run:

```bash
rg -n "全新适配|增量适配|通用 Django|蓝鲸 SaaS|AutoOps|明确需要修改|高风险待验证|暂不修改|dameng|oceanbase|all" skills/fp-db-adapter/references/adaptation-scope.md
```

Expected: all project types, both adaptation stages, all scopes, and all three finding labels are present.

- [ ] **Step 7: Commit the scan guidance**

```bash
git add skills/fp-db-adapter/references/adaptation-scope.md
git commit -m "docs: add database adaptation scan matrix"
```

### Task 3: Strengthen migration safety and verification boundaries

**Files:**
- Modify: `skills/fp-db-adapter/references/compatibility-checklist.md:1-97`

- [ ] **Step 1: Record the migration-safety baseline**

Run:

```bash
rg -n "已执行|回滚|reverse_code|atomic|锁表|空库|增量迁移|实连" skills/fp-db-adapter/references/compatibility-checklist.md
```

Expected: live verification is mentioned, but already-applied migration, rollback, transaction, and large-table rules are absent or incomplete.

- [ ] **Step 2: Add migration-history safety rules**

Require the plan to determine whether each original migration may already be applied. Add these rules:

```text
- Do not directly edit an already-applied original migration unless the project's accepted replacement mechanism explicitly requires it and the plan explains the compatibility effect.
- Prefer the established migrate_patch replacement mechanism or a new follow-up migration according to project behavior.
- Preserve dependencies and business semantics.
- Evaluate RunPython reversibility, idempotency, historical models, atomic behavior, data volume, and lock duration.
- Removing a constraint is a material plan change requiring renewed approval.
```

- [ ] **Step 3: Make log diagnosis obey the planning gate**

Change language that currently says to copy and modify a patch immediately. Diagnosis must locate the failure and propose the smallest patch first; it may only create or modify that patch after explicit confirmation of the current plan.

- [ ] **Step 4: Expand verification into explicit levels**

Define:

```text
L1: syntax/import and Django system check
L2: migration graph, makemigrations --check, and migrate --plan
L3: selected database empty-schema full migration for new adaptation
L4: selected database existing-schema incremental migration for incremental adaptation
L5: core CRUD, constraints, Unicode/long text/time/JSON, and critical jobs
L6: failure recovery or rollback where supported
```

For `all`, require separate Dameng and OceanBase outcomes. State that unavailable levels remain explicitly unverified.

- [ ] **Step 5: Verify the safety and validation contract**

Run:

```bash
rg -n "已执行.*migration|补丁机制|后续 migration|reverse_code|幂等|atomic|锁表|L1|L2|L3|L4|L5|L6|重新确认" skills/fp-db-adapter/references/compatibility-checklist.md
```

Expected: migration-history protections and all six verification levels are present.

- [ ] **Step 6: Commit migration safety guidance**

```bash
git add skills/fp-db-adapter/references/compatibility-checklist.md
git commit -m "docs: strengthen database migration safety checks"
```

### Task 4: Clarify AutoOps conditional applicability and UI discovery

**Files:**
- Modify: `skills/fp-db-adapter/references/autoops-patterns.md:1-7`
- Modify: `skills/fp-db-adapter/agents/openai.yaml:1-4`

- [ ] **Step 1: Add an AutoOps applicability boundary**

At the top of `autoops-patterns.md`, state:

```markdown
仅在项目可由代码或用户信息确认是 AutoOps、蓝鲸 SaaS，或明确采用本参考中的 `cw_cornerstone` 约定时读取本文。固定依赖版本、配置路径、`BKAPP_*` 变量和 YAML 规则都是项目模式，不得无条件应用到普通 Django 项目；若目标项目已有不同约定，优先沿用项目事实并在方案中说明差异。
```

- [ ] **Step 2: Update UI metadata**

Set:

```yaml
interface:
  display_name: "信创数据库适配"
  short_description: "先规划确认，再适配达梦与 OceanBase"
  default_prompt: "使用 $fp-db-adapter，自动判断当前项目属于全新或增量适配，以及需要适配达梦、OceanBase 或两者；先输出精确到文件和代码位置的详细方案，等待我确认后再实施。"
```

- [ ] **Step 3: Validate metadata and conditional routing**

Run:

```bash
rg -n "仅在项目.*确认|不得无条件应用|先规划确认|等待我确认后再实施" skills/fp-db-adapter/references/autoops-patterns.md skills/fp-db-adapter/agents/openai.yaml
```

Expected: AutoOps has a clear applicability boundary and UI metadata advertises the confirmation gate.

- [ ] **Step 4: Commit metadata and routing changes**

```bash
git add skills/fp-db-adapter/references/autoops-patterns.md skills/fp-db-adapter/agents/openai.yaml
git commit -m "docs: clarify fp-db-adapter discovery and scope"
```

### Task 5: Validate the complete skill against the approved design

**Files:**
- Verify: `skills/fp-db-adapter/SKILL.md`
- Verify: `skills/fp-db-adapter/agents/openai.yaml`
- Verify: `skills/fp-db-adapter/references/adaptation-scope.md`
- Verify: `skills/fp-db-adapter/references/compatibility-checklist.md`
- Verify: `skills/fp-db-adapter/references/autoops-patterns.md`

- [ ] **Step 1: Run structural validation**

```bash
python3 /Users/sancifang/.codex/skills/.system/skill-creator/scripts/quick_validate.py skills/fp-db-adapter
```

Expected: `Skill is valid!`

- [ ] **Step 2: Check for stale behavior and names**

```bash
rg -n "fp-xinchuang-db-adapter|先把用户任务分成两类|直接生成补丁|直接修改|单纯适配" skills/fp-db-adapter
```

Expected: no stale skill name or instruction that bypasses the phase-one plan gate. Contextual mentions may remain only if they explicitly describe classification history rather than current workflow.

- [ ] **Step 3: Check complete design coverage**

```bash
rg -n "全新适配|增量适配|达梦 \+ OceanBase|阶段一|阶段二|当前行号|稳定.*锚点|当前代码|计划代码|重新确认|静态验证|实连验证" skills/fp-db-adapter
```

Expected: every approved design concept appears in the skill package.

- [ ] **Step 4: Review the final diff**

```bash
git diff --check
git diff -- skills/fp-db-adapter
```

Expected: no whitespace errors; diff is limited to the skill package and matches the approved design.

- [ ] **Step 5: Inspect repository status without staging unrelated files**

```bash
git status --short
```

Expected: unrelated `.DS_Store` files remain unstaged. Only intended skill files are committed or ready for the final commit.

- [ ] **Step 6: Commit any final consistency corrections**

If validation required corrections:

```bash
git add skills/fp-db-adapter/SKILL.md skills/fp-db-adapter/agents/openai.yaml skills/fp-db-adapter/references/adaptation-scope.md skills/fp-db-adapter/references/compatibility-checklist.md skills/fp-db-adapter/references/autoops-patterns.md
git commit -m "fix: align fp-db-adapter planning contract"
```

Expected: no commit is created when validation required no changes.
