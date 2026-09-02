# FeaturePilot (`fp`) for Codex and other agents

FeaturePilot is an AI feature-development guide for `需求 → 原型/设计 → 计划 → 执行 → 归档`. This repository ships the same `skills/` to Claude Code, Codex, and DeepSeek Harness. Current release: `1.0.0`.

`AGENTS.md` is a router, not a workflow contract cache. Resolve the current intent, read the matching skill completely, then read every conditional contract whose trigger matches before acting. Those files own the behavior; this file owns only discovery. If a routed resource is missing or unreadable, stop and report the incomplete plugin installation rather than searching the target repository for a substitute.

## Codex fallback router

Codex does not run Claude Code slash commands directly. Treat `/fp-*` names as workflow labels and load the matching installed skill:

| User intent | Read first |
|---|---|
| Initialize or refresh workspace/config | `skills/fp-init/SKILL.md` |
| Read-only repository exploration | `skills/fp-explore/SKILL.md` |
| Explicit zero-background visual explanation | `skills/fp-eli5/SKILL.md` |
| Full FeaturePilot workflow | `skills/fp-start/SKILL.md` |
| Explicit PRD authoring or revision | `skills/fp-prd/SKILL.md` |
| Small local change or bug fix without the full document chain | `skills/fp-quick/SKILL.md` |
| Implement or refine UI from a Figma node URL | `skills/fp-figma/SKILL.md` |
| Proposal only | `skills/fp-propose/SKILL.md` |
| Technical design | `skills/fp-brainstorm/SKILL.md` |
| Design review entry for a confirmed design | `skills/fp-design-review/SKILL.md` |
| Implementation plan | `skills/fp-plan/SKILL.md` |
| Execute a confirmed plan (default direct execution) | `skills/fp-execute/SKILL.md` |
| Execute a confirmed plan with explicitly requested SDD, or resume recorded SDD progress | `skills/fp-execute-sdd/SKILL.md` |
| Raise or recover unit-test coverage | `skills/fp-coverage/SKILL.md` |
| Review one large functional module or related modules | `skills/fp-module-review/SKILL.md` |
| Final whole-branch review before archive or merge | `skills/fp-final-review/SKILL.md` |
| Archive a completed change | `skills/fp-archive/SKILL.md` |

## Conditional contract router

| Trigger branch | Required read |
|---|---|
| Any FeaturePilot workflow, including initialization or an absent information layer | `skills/_shared/workspace-rules.md` |
| A PRD, proposal, design, task plan, overview, or archive artifact is read, written, converted, validated, reviewed, or archived | `skills/_shared/artifact-layout.md` |
| Requirement, proposal, or design questions can change scope, behavior, architecture, interfaces, or acceptance | `skills/_shared/decision-ledger.md` |
| Code location, symbols, call/data flow, impact, graph setup/refresh, or post-write graph state is involved | `skills/_shared/codegraph.md` |
| Figma, frontend/UI planning or implementation, visual evidence, browser E2E, final review, or archive has UI-bearing scope | `skills/_shared/ui-e2e-contract.md` |

When maintaining this repository itself, also follow root `CLAUDE.md`; it owns pull-request language and repository-specific CodeGraph integration constraints.
