# FeaturePilot `fp-explore` Shared Exploration Design

**Date:** 2026-07-12
**Status:** Approved design, pending implementation plan

## 1. Context

FeaturePilot currently repeats repository exploration across `fp-prd`, `fp-start`, and `fp-quick`:

- `fp-prd` performs bounded code-fact exploration before its product interview;
- `fp-start` performs PRD/stage resolution, small-request routing, and lightweight code discovery before loading `fp-propose`;
- `fp-quick` loads the larger `fp-propose` skill only to reuse exploration and clarification behavior.

This duplication increases prompt coupling, causes repeated repository scans, and makes it harder to enforce one evidence, budget, and safety policy.

The new `fp-explore` capability combines:

- **OpenSpec:** exploration is a flexible thinking stance rather than a persisted runtime state or rigid workflow; it is grounded in the current codebase and may end without an artifact;
- **GSD:** follow the user's thread naturally, reflect current understanding, ask at most one substantive question per turn, and request bounded consent before external research;
- **FeaturePilot:** remain strictly read-only, separate verified facts from inference and product decisions, preserve caller-owned confirmation gates, and validate internal contracts statically.

## 2. Goals and non-goals

### 2.1 Goals

1. Add a public `/fp-explore [topic-or-change]` command that accepts natural-language input.
2. Add three structured internal profiles used immediately by `fp-prd`, `fp-start`, and `fp-quick`.
3. Centralize repository investigation, evidence classification, budgets, research consent, and read-only boundaries.
4. Reduce duplicate exploration, especially between `fp-start` and `fp-propose` and between `fp-quick` and `fp-propose`.
5. Keep every product decision, confirmation gate, artifact write, stage transition, implementation action, and validation action with the owning caller.
6. Enforce the contract through PowerShell 5.1-compatible static validation and state-neutral scenario checks.

### 2.2 Non-goals

- adding an explore runtime state machine, parser, dispatcher, background service, or `/fp-explore-exit`;
- adding an exploration artifact, note format, durable session state, or new `fp-docs` lifecycle stage;
- allowing exploration to write code, tests, configuration, PRDs, proposals, designs, tasks, or notes;
- replacing `fp-prd-grill-me`, `fp-propose`, or caller-specific approval rules;
- importing OpenSpec CLI, store, status JSON, or artifact-graph dependencies;
- using exploration findings as evidence of user approval.

## 3. Architecture

### 3.1 Authoritative files

Add:

```text
commands/
└── fp-explore.md                 # thin public adapter

skills/
└── fp-explore/
    └── SKILL.md                  # sole authoritative explore contract
```

`skills/fp-explore/SKILL.md` is authoritative for:

- public standalone behavior;
- the three internal profiles;
- repository investigation and evidence classification;
- context budgets and stopping rules;
- read-only and sensitive-data boundaries;
- external-research consent;
- internal invocation and return shapes;
- handoff recommendations.

`commands/fp-explore.md` delegates `$ARGUMENTS` to `fp:fp-explore` and provides only the repository's normal Markdown-agent fallback. It must not duplicate profiles, budgets, result fields, safety rules, validation details, or migration policy.

No runtime machinery is introduced. The behavior remains a Markdown skill contract consumed by Claude Code and compatible Markdown agents.

### 3.2 Modes

#### Public `standalone`

A user invokes:

```text
/fp-explore [natural-language topic or change]
```

The input may be empty, vague, concrete, comparative, or an explicitly named active change. Public exploration is conversational and flexible: it may reframe the question, follow multiple relevant threads internally, compare alternatives, and draw ASCII diagrams. It asks at most one substantive question per turn, never forces an artifact, and remains strictly read-only.

#### Internal profiles

| Profile | Caller | Purpose |
|---|---|---|
| `prd-facts` | `fp-prd` | Establish existing user-visible behavior, implementation entrypoints, interface/data facts, adjacent product patterns, and technical constraints without deciding product requirements. |
| `start-routing` | `fp-start` | Resolve current PRD/stage evidence, quick-versus-full routing evidence, implementation boundaries, and minimum reusable context for the next phase. |
| `quick` | `fp-quick` | Locate candidate files, reusable code/test patterns, verification paths, implementation blockers, and quick-flow suitability evidence. |

All three profiles are implemented and integrated in this release.

### 3.3 Ownership boundary

```text
fp-explore owns:
  investigation, search, evidence collection, fact classification,
  inference, uncertainty, technical risks, option comparison,
  diagrams, and handoff recommendations

caller workflows own:
  user questioning, product decisions, scope convergence,
  confirmation gates, artifact writes, stage transitions,
  implementation, testing, validation, and recovery
```

Specific boundaries:

- `prd-facts` never answers Bucket C questions and never replaces `fp-prd-grill-me`.
- `start-routing` supplies routing evidence but never chooses `fp-quick` or advances the full flow.
- `quick` supplies an advisory scope assessment; `fp-quick` makes the final suitability decision and owns its plan and execution.
- An internal profile returns control to the caller and does not address the end user directly.
- Exploration findings and recommendations never count as user confirmation.

## 4. Internal invocation contract

A caller supplies exactly one block with this shape:

```markdown
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
```

### 4.1 Field rules

| Field | Requirement |
|---|---|
| `profile` | Required; exactly one of `prd-facts`, `start-routing`, or `quick`. |
| `objective` | Required; non-empty, bounded to investigation, and must not request mutation or a user-owned decision. |
| `caller` | Required; exactly one of `fp-prd`, `fp-start`, or `fp-quick`. |
| `active-slug` | Optional value; empty or already resolved by the caller. `fp-explore` never generates or normalizes a slug. |
| `caller-owned-context` | Required list; contains only user-confirmed facts or facts the caller is authorized to consume. |
| `scope-include` | Required list; may be empty when the objective itself is sufficiently bounded. |
| `scope-exclude` | Required list; may be empty. |
| `budget-profile` | Required; exactly one of `tiny`, `small`, `standard`, or `max`. |
| `return-shape` | Required; the initial implementation accepts only `profile-default`. |
| `external-research` | Required; defaults to `not-authorized` at the caller. |
| `approved-research-boundary` | Empty when research is not authorized; complete and exact when approved. |

Allowed caller/profile pairs are exact:

- `fp-prd` + `prd-facts`;
- `fp-start` + `start-routing`;
- `fp-quick` + `quick`.

Missing required fields, unknown fields, invalid enum values, invalid caller/profile pairs, mutation objectives, and malformed research authorization fail closed before investigation.

Fail-closed behavior means:

- do not investigate;
- do not infer missing values;
- do not choose a default profile;
- do not fall back to `standalone`;
- do not ask the end user directly;
- return a blocked result naming the invalid field and the caller action required.

## 5. Internal return contract

Every valid internal invocation returns this deterministic shape:

```markdown
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
```

Rules:

- `profile: invalid` is used only for a fail-closed return when the invocation profile is missing or unknown; a recognized profile remains unchanged even when another field is invalid;
- an invalid invocation uses `status: blocked`, `budget-status: not-started-invalid-invocation`, and `n/a` for all profile-specific fields that cannot be safely determined;
- verified facts, inferences, risks, unknowns, and product decisions remain distinct;
- stale intel is a navigation hint, not a verified fact;
- repository evidence uses `path:line` where available;
- inference records confidence and supporting evidence;
- non-applicable profile fields remain present as `n/a`;
- budget exhaustion names uninspected areas;
- recommendations do not dispatch another workflow.

Public standalone output is human-readable and may be lighter while conversation continues. A terminal public result should include objective, status, inspected scope, budget status, verified facts, inferences, useful architecture/behavior diagrams, risks, uncertainties, external-research state, and suggested next actions.

## 6. Exploration flow

### 6.1 Non-empty public input

1. Resolve the project root and applicable root/scoped engineering instructions.
2. Read `fp-docs/manifest.md` first when present, as an index only.
3. Translate the objective into searchable terms, strings, routes, APIs, models, components, symbols, configuration, and tests.
4. Search before reading and inspect the smallest useful set of implementation, interface, test, configuration, and neighboring-pattern files.
5. Establish current entrypoints, behavior, interfaces, module boundaries, adjacent patterns, verification paths, and directly relevant constraints.
6. Classify verified facts, inferences, risks, unknowns, and user-owned decisions separately.
7. Ask one substantive question only when different answers materially change the exploration direction, conclusion, scope, or safety boundary.
8. Synthesize when the objective is answered, a decision is required, the budget is reached, external research needs consent, or further progress would require mutation.

### 6.2 Empty public input

An empty `/fp-explore` performs a bounded project orientation before asking what to explore. It may inspect:

- root engineering instructions such as `README.md`, `AGENTS.md`, and `CLAUDE.md`;
- `fp-docs/manifest.md` as an index;
- a shallow directory overview;
- package, build, run, and test entry configuration;
- primary application or module entrypoints;
- current local Git branch and working-tree status;
- at most five recent commits.

It excludes broad business-source or test-tree reads, dependencies, generated output, caches, build artifacts, large fixtures, binaries, lockfile contents beyond tool identification, secrets, customer data, historical changes, archives, and unrelated Git history.

The result is a concise project portrait followed by one open-ended, project-grounded question.

### 6.3 Internal flow

1. Validate the invocation block.
2. Determine the investigation emphasis from the profile.
3. Search and inspect within the caller scope and selected budget.
4. Return user-owned decisions and ambiguities as caller-owned blocking questions.
5. Produce one structured return.
6. Return control to the caller.

Internal profiles normally complete in one investigation pass. A caller that needs more evidence submits a narrower follow-up invocation carrying still-valid verified facts as caller-owned context.

### 6.4 Efficiency rules

- Search before opening full files.
- Prefer exact paths, symbols, interfaces, strings, and tests over broad keywords.
- Do not reread the same file range.
- Never read the whole `fp-docs` tree.
- Do not use unrelated historical changes, archives, or history as implementation context.
- Use intel only to locate current evidence; verify material facts against current code, tests, interfaces, or local command output.
- Exclude dependencies, generated files, caches, build output, large fixtures, binaries, and lockfile bodies unless explicitly necessary and safe.
- Stop after sufficient evidence exists rather than expanding for completeness alone.
- Reuse valid upstream findings and inspect only uncovered or invalidated areas.

## 7. Budgets and stopping rules

### 7.1 Internal budget profiles

| Budget | File reads | Searches/static inspections | Local Git inspections | External sources | Typical use |
|---|---:|---:|---:|---:|---|
| `tiny` | 6 | 4 | 1 | 0 unless approved | Known file or symbol verification |
| `small` | 12 | 8 | 2 | 0 unless approved | `quick` and simple `prd-facts` |
| `standard` | 24 | 14 | 3 | 0 unless approved | Normal `start-routing` and cross-layer fact discovery |
| `max` | 40 | 20 | 5 | 0 unless approved | Largest allowed cross-module investigation |

Default mappings:

- `fp-prd` uses `small`;
- `fp-start` uses `standard`;
- `fp-quick` uses `small`.

A caller may choose a smaller budget for a narrower objective. `max` requires a concrete cross-module reason in the objective or caller-owned context. Budgets are maxima, not quotas.

A distinct file opened for content counts as one read. A filename/content search, directory listing, static configuration query, or observational command counts as one search/inspection. Each local read-only Git command counts as one Git inspection. Each fetched external source counts against the separately approved source limit.

On budget exhaustion:

- return `complete` if inspected evidence already answers the objective;
- return `partial` if only part is supported;
- return `blocked` if no reliable conclusion is possible;
- list uninspected areas instead of filling gaps with inference.

### 7.2 Natural stopping conditions

Exploration stops naturally when:

- the objective is answered;
- a user-owned decision is required;
- external research requires approval;
- the budget is exhausted;
- further work requires mutation;
- the user changes topics or selects another workflow.

There is no durable mode and no exit command.

## 8. Read-only and sensitive-data boundaries

### 8.1 Allowed operations

`fp-explore` may:

- read files and directory structures;
- search filenames, content, and symbols;
- inspect local Git branch, status, diff, and necessary local history;
- read relevant FeaturePilot artifacts, configuration, interfaces, and tests;
- run observational commands whose expected behavior is read-only and state-neutral;
- compare alternatives and draw diagrams;
- ask a public blocking question or return an internal caller-owned question;
- perform explicitly approved bounded external research;
- return findings and suggested handoffs.

### 8.2 Prohibited operations

All modes and profiles must not:

- create, edit, move, or delete files;
- modify code, tests, configuration, dependencies, settings, intel, manifests, archives, or history;
- create PRDs, proposals, designs, tasks, plans, notes, exploration artifacts, or `fp-docs/changes/` directories;
- run formatters, generators, migrations, installers, package updates, or write-mode tools;
- run builds, tests, servers, bundlers, previews, or commands expected to produce caches, coverage, snapshots, compiled output, service state, or other files;
- perform database writes or mutate local/remote services;
- run Git operations that modify the index, worktree, refs, remotes, submodules, stash, worktrees, or configuration;
- implement a fix or start another workflow;
- claim findings satisfy a confirmation gate.

If command side effects are uncertain, inspect source files directly or report the limitation. This is a semantic skill contract, not a claim of operating-system sandbox enforcement.

### 8.3 Sensitive information

By default, exclude `.env` files, credentials, tokens, cookies, private keys, credential stores, customer data, production exports, backups, private user directories, and unrelated logs or dumps.

When the user explicitly identifies a sensitive local scope as necessary, inspect only the minimum required content. Never reproduce secret values or transmit private source, customer data, or credentials to an external service. Return `blocked` when safe investigation is not possible.

## 9. External research

Local repository inspection is authorized by invoking `fp-explore`. Web search, URL fetching, package-registry lookup, remote Git access, network documentation tools, and commands that download metadata require separate, explicit, bounded approval.

Before public research, present:

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

Approval for one envelope does not authorize a different question, source type, domain, source count, later invocation, remote Git access, package-registry access, or transmission of private code or secrets.

Internal profiles default to `external-research: not-authorized`. When local evidence is insufficient, they return `external-research: proposed` with a precise gap and suggested envelope. The caller obtains consent and reinvokes the same profile with a complete approved boundary. The reinvocation remains limited to that external gap and must not expand into mutation or product decisions.

External results cite URLs and access dates and remain separate from repository evidence and synthesis. Conflicts, stale versions, and uncertainty are reported. When the approved envelope is insufficient, stop and propose a new envelope rather than expanding silently.

## 10. Context precedence and conflict handling

Use this precedence order:

1. current explicit user instructions;
2. the caller invocation block and user-confirmed caller-owned context;
3. current source code, tests, interfaces, and local Git evidence;
4. current-slug FeaturePilot artifacts allowed by shared workspace and artifact-layout rules;
5. shared FeaturePilot contracts and this skill contract;
6. stale intel, historical documentation, comments, and naming hints.

Current code may disprove stale intel or a caller assumption, but it does not override a user-confirmed target requirement. Return conflicts explicitly. When repository evidence cannot determine the intended target behavior, return a caller-owned product question rather than silently choosing an interpretation.

## 11. Caller integration

### 11.1 `fp-prd`

Both PRD-first and Prototype-first paths use `prd-facts` before `fp-prd-grill-me` classifies facts and questions when all of these apply:

- input is non-empty;
- the request concerns an existing product, page, API, model, permission, or compatibility behavior;
- current repository facts can reduce technical uncertainty;
- the idea is not purely greenfield.

The default invocation uses `budget-profile: small` and `external-research: not-authorized`.

Consumption rules:

- pass verified behavior and constraints into `fp-prd-grill-me` as code facts;
- keep `prd-product-decisions` as unanswered Bucket C decisions or explicit confirmation-summary items;
- do not infer that the user wants to preserve an existing UI, enum, permission, API, or workflow merely because it exists;
- retain `fp-prd-grill-me` as the only interview and confirmation authority;
- preserve the current empty-input behavior: ask for one sentence and do not scan.

### 11.2 `fp-start`

Replace the separate PRD handoff resolution, small-request routing scan, and pre-stage code-context scan with one `start-routing` call using `budget-profile: standard` by default.

The profile investigates:

- whether the argument matches a current active slug or canonical PRD;
- which valid canonical artifacts exist for the active slug;
- the current FeaturePilot stage;
- quick-flow evidence and obvious cross-module boundaries;
- current implementation scope;
- the minimum verified context needed by the next phase.

Consumption rules:

- route assessment remains advisory;
- `fp-start` presents quick/full reasons and waits for the user's choice;
- a full-flow choice passes `start-reusable-context`, evidence paths, inspected scope, budget state, and uninspected areas to `fp-propose`;
- `fp-propose` reuses fresh, scope-matching verified facts and investigates only uncovered, changed, or insufficient areas;
- neither `fp-explore` nor `fp-start` automatically advances a stage.

### 11.3 `fp-quick`

Replace the current dependency on `fp-propose` exploration with one `quick` call using `budget-profile: small` by default.

`fp-quick` consumes candidate files, module boundaries, reusable functions/components/APIs/tests, verification suggestions, risks, blocking questions, and advisory scope assessment.

`fp-quick` retains:

- final suitability judgment;
- user clarification;
- inline implementation planning;
- explicit plan/scope approval;
- implementation and verification;
- the no-FeaturePilot-artifact rule.

Clarification cadence becomes at most one substantive question per turn. Multiple inseparable decisions may be represented as one structured choice, but separate questions are not batched.

### 11.4 Reuse and invalidation

Internal returns remain in the active invocation chain and are not written to disk. Downstream reuse preserves:

- objective;
- actual inspected scope;
- evidence paths and line numbers;
- observed worktree state relevant to the result;
- uninspected areas;
- inference confidence;
- budget state.

Reuse is allowed only when the same conversation/workflow continues, the objective has not materially changed, the relevant worktree content has not changed, and the inspected scope covers the downstream question. Otherwise, revalidate only affected facts instead of rerunning the full exploration.

## 12. Public handoffs

Public `fp-explore` may recommend but never invoke:

| Situation | Suggested action |
|---|---|
| More understanding is needed | Run a narrower `/fp-explore`. |
| The user wants a PRD | Use `/fp-prd`. |
| Full staged delivery is appropriate | Use `/fp-start`. |
| A small bounded implementation is ready | Use `/fp-quick`. |
| An existing caller encountered uncertainty | Return to that caller. |

A handoff states the evidence, reason, and remaining user decision. It does not create artifacts, preload the next workflow, write a plan, or treat ambiguous continuation language as permission.

## 13. Files changed by implementation

### 13.1 New files

- `commands/fp-explore.md`
- `skills/fp-explore/SKILL.md`
- `scripts/test-explore-contract.ps1`

### 13.2 Modified files

- `skills/fp-prd/SKILL.md`
- `skills/fp-start/SKILL.md`
- `skills/fp-quick/SKILL.md`
- `skills/fp-propose/SKILL.md` for downstream reuse of `start-reusable-context`
- `commands/fp-prd.md`
- `commands/fp-start.md`
- `commands/fp-quick.md`
- `scripts/validate-plugin.ps1`
- `scripts/measure-context.ps1` when required by current context-budget reporting
- `README.md`
- `AGENTS.md`
- `docs/user_guide/init-prd-start.md`

Plugin manifests change only if their current schema requires explicit per-skill registration. The current repository uses filesystem discovery for Claude and directory exposure for compatible agents.

## 14. Testing and validation

### 14.1 Focused contract suite

Add `scripts/test-explore-contract.ps1` with three validation layers:

1. **Synthetic fixtures:** valid/invalid invocation and return blocks, profile/caller pairs, budgets, research envelopes, and bilingual unsafe clauses.
2. **Live repository text:** actual skill, command, caller, documentation, and validator integration.
3. **In-memory negative mutations:** remove or weaken mandatory clauses and assert rejection without writing fixtures to the worktree.

### 14.2 Required assertions

Validate:

- `skills/fp-explore/SKILL.md` is the sole detailed policy authority;
- `commands/fp-explore.md` stays thin and contains no copied budgets, schemas, or safety policy;
- only the three exact caller/profile pairs are valid;
- invocation fields, return fields, enums, and conditional research fields are complete;
- invalid internal invocations fail before investigation and never fall back to public mode;
- facts, inference, risks, and product decisions remain separate;
- non-applicable return fields use `n/a`;
- public mode accepts natural language while internal mode requires structured blocks;
- no runtime parser, dispatcher, durable explore state, or exit command is introduced;
- no profile can weaken read-only, sensitive-data, external-research, artifact-ownership, or confirmation rules;
- `fp-prd-grill-me` remains the product interview authority;
- `fp-start` retains routing choice and stage gates;
- `fp-quick` retains suitability, plan approval, implementation, and validation;
- `fp-propose` treats only upstream verified facts as reusable and inspects gaps rather than trusting inference;
- documentation and command checksums match implementation.

Reject text equivalent to:

- exploration may implement an obvious fix;
- exploration may save a note or update a workflow artifact;
- caller context can waive the read-only contract;
- external access can occur without separate bounded approval;
- one research approval covers another question, source, or later invocation;
- exploration findings are user confirmation;
- a profile may advance its caller's stage;
- empty public input scans the entire repository;
- an internal profile may ask the end user directly;
- malformed internal input may use inferred defaults or standalone fallback.

### 14.3 Validator integration

Update `scripts/validate-plugin.ps1` to discover the new command/skill, run the focused contract suite, and retain all existing artifact-layout, PRD, SDD, and context assertions.

Update `scripts/measure-context.ps1` when necessary to report:

- public `/fp-explore` context size;
- exploration-related context changes for the three migrated callers;
- the reduction achieved by removing `fp-quick`'s dependency on full `fp-propose` exploration;
- a guard against making `fp-explore` itself unbounded.

### 14.4 Scenario verification

Exercise at least:

1. empty public input: bounded orientation, no broad scan, one question;
2. concrete public question: cited local facts, separated inference, no writes or automatic implementation;
3. existing-product PRD: behavior/constraint facts without self-answering product decisions;
4. greenfield PRD: no unnecessary repository scan;
5. start quick candidate: route evidence followed by caller-owned user choice;
6. start full flow: verified context reaches `fp-propose`, which inspects only gaps;
7. quick local change: candidate files/patterns/verification without loading full `fp-propose`;
8. external gap: no network before approval and no expansion beyond the envelope;
9. invalid internal call: blocked before investigation, no defaults and no direct user question.

For every pure exploration scenario, compare `git status --porcelain=v1 -uall`, relevant file hashes, generated/cache directories, and FeaturePilot artifact paths before and after. Observed project state must remain unchanged.

## 15. Completion criteria

Implementation is complete only when:

- `/fp-explore` accepts natural-language input and remains strictly read-only;
- all three internal profiles are integrated with their owning callers;
- `fp-prd` product-decision and confirmation gates are not weakened;
- `fp-start` uses one routing exploration and passes reusable evidence downstream;
- `fp-propose` performs gap-only follow-up exploration when upstream evidence remains valid;
- `fp-quick` no longer loads full `fp-propose` for exploration;
- internal contracts, budgets, fail-closed behavior, and research envelopes are statically validated;
- focused and existing regression suites pass;
- scenario verification causes no observed project-state change;
- public documentation and actual behavior agree.
