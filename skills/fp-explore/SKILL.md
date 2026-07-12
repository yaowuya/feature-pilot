---
name: fp-explore
description: Explore repository facts, behavior, options, constraints, and risks without modifying files or advancing a FeaturePilot workflow.
---
## FeaturePilot workspace and information layer

Read `../_shared/workspace-rules.md` once before acting. It owns root resolution, manifest-first lazy context, stale-intel handling, evidence precedence, neutrality, compatibility, and artifact ownership.

Read `../_shared/artifact-layout.md` only when the objective names or depends on a current FeaturePilot artifact, change slug, stage, or canonical artifact path. Consume that contract only to resolve existing artifacts; never create, migrate, repair, split, finalize, or archive them.

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
4. Search before opening files; inspect implementation, interfaces, tests, configuration, and adjacent patterns only as needed.
5. Separate verified facts, inferences, risks, unknowns, stale navigation hints, and user-owned decisions.
6. Ask one question only when its answer materially changes scope, meaning, conclusions, or a safety boundary.
7. Synthesize when answered, budget-exhausted, blocked by a decision, awaiting research consent, or reaching mutation.

### Empty standalone input

Use the bounded orientation defined under public mode. Do not scan the whole repository. Name excluded/uninspected areas when a budget is reached.

### Internal one-pass flow

1. Validate the invocation.
2. Investigate the profile objective within scope and budget.
3. Return product ambiguity or missing permission as caller-owned questions.
4. Emit one deterministic return and stop.

A caller may reinvoke with a narrower objective and still-valid verified facts. Do not silently broaden the current call.

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
