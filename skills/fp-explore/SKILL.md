---
name: fp-explore
description: Explore repository facts, behavior, options, constraints, and risks without modifying files or advancing a FeaturePilot workflow.
---
## FeaturePilot workspace and information layer

If any anchored plugin resource is missing or unreadable, stop, report the exact resource and an incomplete FeaturePilot installation/cache, and never search the consumer repository for `skills/**` or continue without it.
下文以 `${CLAUDE_PLUGIN_ROOT}/...` 表示 Claude Code 安装后的插件资源。在 Codex/Markdown 中，从 available-skill 元数据提供的当前技能入口映射同一个 `skills/...` 插件相对路径。两端都不得在消费者项目中搜索插件文件。

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/workspace-rules.md` once before acting. It owns root resolution, manifest-first lazy context, stale-intel handling, evidence precedence, neutrality, compatibility, and artifact ownership.

Read `${CLAUDE_PLUGIN_ROOT}/skills/_shared/artifact-layout.md` only when the objective names or depends on a current FeaturePilot artifact, change slug, stage, or canonical artifact path. Consume that contract only to resolve existing artifacts; never create, migrate, repair, split, finalize, or archive them.

# FeaturePilot Explore

`fp-explore` is a read-only thinking and investigation capability. It supports a public natural-language `mode: standalone` and exact structured internal profiles. It does not implement, write artifacts, advance stages, or provide confirmation.

## Authority and ownership

This file is the sole authority for standalone behavior, profiles, budgets, evidence, safety, external research, result shape, and handoffs. The public command only delegates here.

`fp-explore` owns investigation, search, evidence collection, verified-fact classification, inference, uncertainty, technical risk, option comparison, diagrams, and handoff recommendations.

Callers own user questioning, product decisions, scope convergence, confirmations, artifact writes, stage transitions, implementation, testing, validation, and recovery. Internal profiles return caller-owned blocking questions and then return control to the caller. Exploration findings and recommendations never count as user approval or confirmation.

## Modes

### Public mode: standalone

`/fp-explore [topic-or-change]` accepts empty input, a vague idea, a repository question, a problem, an option comparison, or an explicitly named active change. Follow relevant threads naturally; do not force a questionnaire or mandatory artifact. Reflect current understanding and ask at most one substantive question per turn.

For non-empty input, ground conclusions in the current repository. Search before reading, inspect the smallest useful source/interface/test/configuration set, separate facts from inference and decisions, and synthesize when the objective is answered or a boundary is reached.

For empty input, perform only bounded orientation: applicable root instructions, `fp-docs/manifest.md` as an index, a shallow directory view, build/run/test entry configuration, primary entrypoints, local branch/status, and at most five recent commits. Exclude broad business/test trees, dependencies, generated output, caches, build output, lockfile bodies, large fixtures, binaries, secrets, customer data, historical changes, archives, and unrelated history. Return a concise project portrait and one project-grounded open question.

### Internal profiles

Allowed pairs are exact: `fp-prd` + `prd-facts`, `fp-start` + `start-routing`, and `fp-quick` + `quick`.

- `prd-facts`: existing user-visible behavior, implementation entrypoints, interface/data facts, adjacent product patterns, and technical constraints. It never answers product scope, goals, acceptance criteria, permissions policy, or prototype decisions.
- `start-routing`: current PRD/stage evidence, quick-versus-full evidence, implementation boundaries, and minimum reusable next-phase context. It never selects the route or advances a stage.
- `quick`: candidate files, reusable code/test patterns, verification paths, blockers, and advisory quick suitability. It never plans, approves, implements, or validates the change.

## Internal invocation contract

A caller supplies exactly one block. Unknown fields, missing fields, invalid enums, invalid pairs, mutation objectives, or malformed research authorization fail closed.

<!-- fp-explore-invoke
profile: prd-facts|start-routing|quick
objective: <bounded investigation question>
caller: fp-prd|fp-start|fp-quick
active-slug: <caller-resolved slug or empty>
caller-owned-context:
  - <zero or more user-confirmed or caller-authorized facts>
scope-include:
  - <zero or more paths, modules, symbols, interfaces, commands, or tests>
scope-exclude:
  - <zero or more explicit exclusions>
budget-profile: tiny|small|standard|max
return-shape: profile-default
external-research: not-authorized|approved
approved-research-boundary: <complete approved boundary or empty>
-->

`active-slug` is caller-owned; `fp-explore` never generates or normalizes it. Caller context may narrow scope but cannot weaken read-only, research, artifact-ownership, validation, or confirmation rules.

Invalid internal input must fail closed before investigation: do not infer missing values, select a default profile, fall back to standalone, or ask the end user directly. Return `profile: invalid` only when the supplied profile is missing or unknown; otherwise preserve the recognized profile and identify the invalid field in `next-caller-action`.

## Internal return contract

Every internal invocation returns exactly one block. Use `none` for empty common fields and `n/a` for non-applicable profile fields.

<!-- fp-explore-return
profile: prd-facts|start-routing|quick|invalid
status: complete|partial|blocked
objective: <original objective or concise restatement>
inspected-scope: <files, symbols, artifacts, and commands actually inspected>
budget-status: within-budget|budget-exhausted:<counter>|not-started-invalid-invocation
verified-facts: <facts with path:line evidence where available>
inferences: <inferences with high|medium|low confidence and supporting evidence>
risks: <risks, conflicts, or none>
blocking-questions: <caller-owned questions or none>
external-research: not-needed|not-authorized|proposed|completed
external-research-gap: <bounded local-evidence gap or none>
next-caller-action: <recommended caller action>
profile-fields:
  prd-existing-behavior: <required for prd-facts, otherwise n/a>
  prd-technical-constraints: <required for prd-facts, otherwise n/a>
  prd-product-decisions: <questions for the user, never answers; otherwise n/a>
  start-active-stage: <required for start-routing, otherwise n/a>
  start-route-assessment: quick|full|needs-prd|needs-proposal|blocked|n/a
  start-reusable-context: <verified facts safe to pass downstream; otherwise n/a>
  quick-candidate-files: <required for quick, otherwise n/a>
  quick-reusable-patterns: <required for quick, otherwise n/a>
  quick-verification: <required for quick, otherwise n/a>
  quick-scope-assessment: fits-quick|fits-minimal-slice|recommend-fp-start|blocked|n/a
-->

A recognized profile keeps its profile-specific fields even when blocked. Invalid invocation uses `status: blocked`, `budget-status: not-started-invalid-invocation`, and `n/a` where a profile field cannot be determined.

## Repository investigation flow

### Non-empty standalone input

1. Resolve the target root and applicable engineering instructions.
2. Read `fp-docs/manifest.md` first when present, as an index only.
3. Translate the objective into exact terms, strings, routes, APIs, models, components, symbols, configuration, and tests.
4. Decide whether the CodeGraph Stage 0 fast path applies; it never installs CodeGraph or creates a project graph.
5. Search before opening files; inspect implementation, interfaces, tests, configuration, and adjacent patterns only as needed.
6. Separate verified facts, inferences, risks, unknowns, stale navigation hints, and user-owned decisions.
7. Ask one question only when its answer materially changes scope, meaning, conclusions, or a safety boundary.
8. Synthesize when answered, budget-exhausted, blocked by a decision, awaiting research consent, or reaching mutation.

### Empty standalone input

Use the bounded orientation defined under public mode. Do not scan the whole repository. Name excluded/uninspected areas when a budget is reached.

### Internal one-pass flow

1. Validate the invocation.
2. Investigate the profile objective within scope and budget.
3. Return product ambiguity or missing permission as caller-owned questions.
4. Emit one deterministic return and stop.

A caller may reinvoke with a narrower objective and still-valid verified facts. Do not silently broaden the current call.

## Progressive low-context inspection

Apply this contract to every non-empty standalone exploration and every internal profile. Empty standalone orientation keeps its existing bounded scope and reads only the smallest necessary range; it does not inherit the `quick` numeric limits below. Non-empty standalone uses `standard` as its default budget unless the user explicitly narrows the investigation. Broad permission such as “read whatever you need” permits relevant local inspection but is not an explicit request for comprehensive full-file review.

### Stage 0 - CodeGraph fast path

仅当问题涉及代码位置、符号关系、调用链、数据流、影响范围或相关源码候选时启用。按需读取 `${CLAUDE_PLUGIN_ROOT}/skills/_shared/codegraph.md`；空输入 orientation、纯文档事实或精确非代码字符串搜索不主动触发本阶段。

路由标识固定为 `MCP -> CLI -> native search`，面向用户说明为 `MCP → CLI → 原有搜索`：

1. 只检查当前目标项目根目录的 `.codegraph/`。不存在时将本工作流状态记为 `unavailable`，可建议之后运行 `/fp-init`，然后 `fall back to Stage A`。
2. 第一次需要代码图时解析一次工作流状态。当前会话暴露 CodeGraph MCP 时优先使用 `codegraph_explore`；需要且可用的健康能力优先由 MCP 提供，否则使用 CLI。
3. CLI 与项目图可用时，本工作流 `at most one status check`，运行 `codegraph status <project-root> --json`。待同步时最多运行一次 `codegraph sync <project-root> --quiet`，并且 `do not run status again after sync`。
4. 状态为 `ready-mcp` 时调用 `codegraph_explore`；状态为 `ready-cli` 时调用 `codegraph explore --path <project-root> --max-files <budget> <query>`。
5. MCP、CLI、索引、同步、查询或语言支持失败时，只记录一次精简降级原因，将状态记为 `unavailable`，并 `fall back to Stage A`。同一工作流不重复重试。

`fp-explore` 不安装 CLI、不配置 Agent，也不执行首次建图。增量 `sync` 只能更新现有 `.codegraph/` 派生缓存，不得修改源码或 FeaturePilot 产物；宿主只读权限不允许缓存更新时，跳过同步并回退，不请求扩大写权限来维持探索。

`<budget>` 使用当前 profile 剩余的候选路径上限；剩余预算为零时跳过查询。CodeGraph 返回的路径计入 `candidate paths`，有界源码摘录计入 `local read windows`，整文件内容计入 `unbounded application-file reads`，相应文件也计入 distinct-file budget。CodeGraph 查询本身计入一次 search/static inspection。不得把 `--max-files` 当成必须耗尽的配额，也不得绕过 quick `8 / 8 / 1` 上限。

所有图结果均为 `navigation-hint-only`。候选定位后必须用 `current source`、测试或命令输出复核会影响范围、契约、修改或结论的事实；图结果本身不能成为完成证明。证据充分时可直接进入 Stage C，候选不充分或需要精确匹配时从 Stage A/B 继续。

### Stage A - Glob candidate paths

1. Translate the objective into exact filenames, directories, symbols, routes, APIs, models, components, configuration keys, error text, and test names.
2. Use `Glob` or an equivalent path search before reading application files. Rank candidate paths by direct relevance instead of promoting every match into the read set.
3. Exclude dependencies, generated files, caches, build output, binaries, large fixtures, historical archives, and unauthorized sensitive scope.
4. When path evidence already answers whether or where something exists, cite the path and stop; do not open the file to repeat the same fact.

### Stage B - Grep symbols and hit lines

1. Use `Grep` or an equivalent content/symbol search within candidate paths or a bounded directory before opening application files.
2. Search exact symbols, imports, call sites, routes, fields, component names, and test names before broadening keywords. If an exact search has no result, make at most one evidence-based expansion by synonym, naming convention, or path.
3. Prefer results that include paths, line numbers, and only the context needed to choose a read window.
4. When search evidence is sufficient, cite it directly. Never full-file read every file returned by a broad search.

### Stage C - ranged Read around evidence

1. After a relevant hit, use `Read(offset, limit)` or an equivalent range read. The default window is **80-160 lines**.
2. Align a window to a complete function, class, component section, serializer, route group, configuration block, or test case rather than mechanically centering a fixed number of lines.
3. A hit near a file boundary may use a shorter window. A semantic unit slightly larger than 160 lines may use one adjacent focused window.
4. Do not reread an already covered range without new evidence. Record each actual range in `inspected-scope`.
5. If a window ends inside the relevant semantic unit, read one adjacent window; do not jump directly to an unbounded read.

### Stage D - justified full-file Read

Escalate in this order: read the adjacent portion of the same semantic unit, search the missing definition/reference/test, read a second directly relevant local window, and only then consider an unbounded full-file Read.

For application source, test, or configuration files known or state-neutrally confirmed to be **over 300 lines**, an unbounded Read is prohibited by default. A line-count or structure check counts as a search/static inspection; do not full-read first and justify it afterward.

An unbounded Read is allowed only when at least one observable condition holds:

- the file is at most 300 lines and its whole structure is directly relevant;
- control flow or data flow spans multiple non-adjacent regions that focused windows cannot reconstruct reliably;
- registration, import side effects, lifecycle behavior, route aggregation, or configuration precedence requires global ordering;
- a single-file component has tightly coupled template, script, state, and methods that lose a material interaction when separated;
- two directly relevant local windows still expose conflicting patterns or a conclusion-changing evidence gap;
- the user explicitly requests a comprehensive review of that file, within all safety and budget boundaries.

Before any unbounded Read, state the missing evidence, why search or ranged windows cannot resolve it, and why that file's global structure is directly relevant. “Need more context,” “the file is important,” and “for complete understanding” are not sufficient reasons.

Do not use Bash to dump a whole file or otherwise bypass the ranged-Read threshold. When the available tool cannot read a range safely, use a dedicated search/structure tool or report the limitation.

### Supplemental read counters

Every non-empty exploration tracks these counters in addition to the existing budget profile:

- `candidate paths`: paths promoted from search results into further content investigation;
- `local read windows`: explicit ranged reads;
- `unbounded application-file reads`: unbounded reads of application source, tests, or configuration.

Different ranges in one file are separate local read windows. Overlapping ranges without new evidence are forbidden. A ranged read followed by an unbounded read increments both supplemental counters. Any tool that returns application-file content follows the same accounting by semantic effect: a bounded excerpt is a local read window and a whole-file dump is an unbounded application-file read. Root instructions, a short manifest/index, and an explicitly short FeaturePilot contract do not increment `unbounded application-file reads`, but still count under the existing distinct-file budget and follow smallest-necessary reading. Any ranged read also makes that file count once under the existing distinct-file budget.

The `quick` profile has these additional hard maxima:

- initial candidate paths: 8
- local read windows: 8
- unbounded application-file reads: 1

Keep only the eight most directly relevant initial candidates and list the remainder as uninspected. The unbounded read is not a quota; it still requires the Stage D conditions and reason. At any `quick` supplemental maximum, return `complete`, `partial`, or `blocked` from the available evidence instead of widening the search or bypassing the counter. When multiple supplemental maxima are reached, report the counter that blocks the immediate next evidence-gathering action; use the precedence `quick-local-read-windows`, then `quick-candidate-paths`, then `quick-unbounded-application-file-reads` when more than one would block that same action. Use the existing `budget-exhausted:<counter>` form, including `budget-exhausted:quick-candidate-paths`, `budget-exhausted:quick-local-read-windows`, or `budget-exhausted:quick-unbounded-application-file-reads`, and list uninspected areas for the caller.

Other profiles and non-empty standalone follow the same stages, threshold, and counters without the fixed `8 / 8 / 1` maxima. They remain bounded by their current budget and stop as soon as sufficient evidence exists; a budget is never a quota to consume.

### Parallelism and boundaries

Known-scope, independent `Glob`, `Grep`, and ranged `Read` operations may run in parallel. Never parallelize multiple unknown-scope unbounded reads. A standalone cross-module investigation may use read-only subagents only for genuinely independent scopes; each subagent follows this same contract and returns a summary, paths, lines, ranges, counters, and uninspected areas. The rule is: quick does not spawn subagents for a single search problem. Evident independent workstreams are scope evidence for `fp-quick`, not permission to expand the quick investigation.

If candidates conflict, search callers and tests before widening reads. If targeted evidence remains insufficient, return the uncertainty, risk, or caller-owned question rather than guessing.

## Budget profiles

| Budget | File reads | Searches/static inspections | Local Git inspections | External sources |
|---|---:|---:|---:|---:|
| `tiny` | 6 | 4 | 1 | 0 unless approved |
| `small` | 12 | 8 | 2 | 0 unless approved |
| `standard` | 24 | 14 | 3 | 0 unless approved |
| `max` | 40 | 20 | 5 | 0 unless approved |

Defaults are `small` for `prd-facts`, `standard` for `start-routing`, and `small` for `quick`. `max` requires a concrete cross-module reason. Budgets are maxima, not quotas.

A distinct file content read counts once. A filename/content search, directory listing, static config query, or observational command counts as one inspection. Each local read-only Git command counts once. Each fetched external source counts against the approved source maximum.

On exhaustion, return `complete` only if evidence answers the objective, `partial` if only part is supported, or `blocked` if no reliable conclusion is possible. List uninspected areas; never fill gaps by guessing.

## Evidence classification and context precedence

Keep facts, inferences, risks, unknowns, and decisions distinct. Cite repository facts as `path:line` where available. Give every inference high/medium/low confidence and supporting evidence. Intel and historical text are navigation hints until current evidence verifies them.

Precedence:

1. current explicit user instructions;
2. the invocation and user-confirmed caller context;
3. current code, tests, interfaces, and local Git evidence;
4. allowed current-slug FeaturePilot artifacts;
5. shared FeaturePilot contracts and this skill;
6. stale intel, historical docs, comments, and names.

Current code may disprove a stale assumption but cannot override a user-confirmed target requirement. Return the conflict. When evidence cannot decide intended behavior, return a caller-owned question.

## Read-only and sensitive-data boundary

Allowed: file/directory reads, content/symbol search, local read-only Git inspection, relevant current artifact/config/interface/test reads, demonstrably state-neutral observational commands, diagrams, option comparison, blocking questions, bounded approved external research, and handoff recommendations.

Prohibited:

- create, edit, move, or delete any file;
- modify code, tests, configuration, dependencies, settings, intel, manifests, archives, or history;
- create PRD, proposal, design, task, plan, note, exploration artifact, or `fp-docs/changes/` content;
- run formatters, generators, migrations, installers, updates, or write-mode tools;
- run builds, tests, servers, bundlers, or previews expected to create caches, coverage, snapshots, compiled output, or service state;
- write databases or mutate local/remote services;
- mutate Git index, worktree, refs, remotes, submodules, stash, worktrees, or configuration;
- implement a fix, start another workflow, or claim a confirmation gate passed.

When side effects are uncertain, inspect source directly or report the limitation. The read-only boundary is a semantic prompt contract, not a technical sandbox.

Exclude `.env`, credentials, tokens, cookies, private keys, credential stores, customer data, production exports, backups, unrelated private directories, and sensitive logs by default. If an explicitly named sensitive local scope is necessary, inspect the minimum, never reproduce secrets, and never transmit private source, customer data, or credentials externally. Return blocked when safe investigation is impossible.

## External research approval envelope

Local repository inspection is authorized by invocation. Web search, URL fetches, registries, remote Git, network documentation tools, and metadata downloads require separate bounded approval.

Present this exact envelope before public research:

```markdown
External research request:
- Exact question:
- Why local evidence is insufficient:
- Allowed sources or domains:
- Maximum sources: 1-5, default 3
- Version or recency requirement:
- Repository terms allowed in queries:
- Expiration: this turn only | until this question is answered
```

One envelope authorizes only that question, domains/source types, count, recency, query terms, and expiration. Do not expand it to later calls, package registries, remote Git, or private content.

Internal profiles default to `not-authorized`. Return `external-research: proposed` and a precise gap. After the caller obtains approval, it may reinvoke the same profile with a complete `approved-research-boundary`; the reinvocation is limited to that gap. External results cite URLs and access dates and remain separate from repository evidence and synthesis.

## Caller profile responsibilities

### prd-facts

Return `prd-existing-behavior`, `prd-technical-constraints`, and unanswered `prd-product-decisions`. Do not infer preservation from current UI, enums, routes, APIs, or permissions. `fp-prd-grill-me` owns interview classification and confirmation.

### start-routing

Return `start-active-stage`, advisory `start-route-assessment`, and verified `start-reusable-context`. Report candidate paths, but leave slug resolution and quick/full selection to `fp-start`. Downstream reuse includes objective, inspected scope, evidence, budget, relevant worktree state, uninspected areas, and separately labeled inference.

### quick

Return `quick-candidate-files`, `quick-reusable-patterns`, `quick-verification`, and advisory `quick-scope-assessment`. `fp-quick` owns final suitability, clarification, inline plan approval, implementation, and verification.

## Stopping and handoff rules

Stop when the objective is answered, a decision or research approval is needed, budget is exhausted, mutation would be required, or the user changes workflow. There is no durable mode or exit command.

Handoffs recommend but never invoke another workflow:

- more understanding: narrower `/fp-explore`;
- product requirements: `/fp-prd`;
- staged delivery: `/fp-start`;
- small bounded implementation: `/fp-quick`;
- internal uncertainty: return to the same caller.

State the evidence, reason, and remaining user decision. Do not preload the destination, create artifacts, write a plan, or treat ambiguous continuation as permission.
