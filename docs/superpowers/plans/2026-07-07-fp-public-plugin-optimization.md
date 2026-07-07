# FeaturePilot Public Plugin Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the `fp` plugin public and customer-agnostic by moving project-specific settings to `fp-docs/settings` and all generated artifacts to `fp-docs`.

**Architecture:** The plugin remains a Markdown-based Claude Code plugin. Skills and commands define a common FeaturePilot workspace contract: generated documents live under `fp-docs/`, while customer component libraries, UI tokens, workflow constraints, and path conventions are read from optional Markdown files under `fp-docs/settings/`. Public skills must not hardcode customer-specific component-library or vendor assumptions.

**Tech Stack:** Claude Code plugin manifests, Markdown slash commands, Markdown skills, Python text-migration scripts for repository-wide prompt updates.

---

## File Map

**Modify:**
- `README.md` — document public plugin model, settings, and output directory.
- `AGENTS.md` — Codex/agent rules for reading settings and using `fp-docs` paths.
- `commands/fp-*.md` — update paths and settings requirements.
- `skills/fp-*/**/*.md` — update paths, settings requirements, and remove customer hardcoding.

**Remove or deprecate from default flow:**
- Customer-specific component-library skill directories must not be part of public default guidance.

## Task 1: Workspace Path Migration

- [x] Replace generated artifact paths from the legacy workspace root to `fp-docs/...`.
- [x] Ensure `.fp-execute` lives under `fp-docs/changes/<slug>/.fp-execute/`.

## Task 2: Customer Settings Contract

- [x] Add public settings contract to README and AGENTS.
- [x] Add reusable settings-reading instructions to workflow skills.
- [x] Define fallback behavior when settings files are absent.

## Task 3: Remove Customer-Specific Frontend Defaults

- [x] Replace customer-specific frontend defaults with `fp-docs/settings/agent.md` and existing-code inference.
- [x] Remove customer-specific skill directory from public plugin default content.

## Task 4: Verify

- [x] Scan for legacy workspace paths and customer-specific frontend defaults.
- [ ] Validate required command and skill frontmatter still exists.
- [ ] Check git status and summarize modified files.
