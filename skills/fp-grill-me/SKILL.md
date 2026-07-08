---
name: fp-grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

## FeaturePilot workspace and information layer

Before asking questions or making recommendations, locate the target project's FeaturePilot workspace:

1. Walk upward from the current working directory to find `fp-docs/`.
2. If `fp-docs/manifest.md` exists, read it first.
3. Read only relevant settings and intel listed by the manifest.
4. If UI/frontend is involved and `fp-docs/settings/frontend.md` exists, read it as a required source.
5. If backend/API/data/security behavior is involved and `fp-docs/settings/backend.md` exists, read it as a required source.
6. Treat settings/intel as navigation and constraints; verify exact implementation facts against current code.
7. Use two precedence modes: current code/command output wins for current-state facts; approved change artifacts win for target-state requirements.

If settings are absent, use current project code and adjacent implementations only. Do not assume any customer component library, vendor, component prefix, design token, or workflow policy.

# FeaturePilot workspace and customer settings

When a question can be answered by project configuration, first read relevant target-project files under `fp-docs/settings/`:

- `fp-docs/settings/agent.md` for project-specific FeaturePilot rules.
- `fp-docs/settings/agent.md` for UI/component/design-system rules.
- `fp-docs/settings/agent.md` for review and execution rules.
- `fp-docs/settings/agent.md` for project path conventions.

If settings are absent, use current project code and adjacent implementations only. Do not assume any customer component library, vendor, component prefix, design token, or workflow policy.

Interview me relentlessly about every aspect of this plan until
we reach a shared understanding. Walk down each branch of the design
tree resolving dependencies between decisions one by one.

If a question can be answered by exploring the codebase, explore
the codebase instead.

For each question, provide your recommended answer.
