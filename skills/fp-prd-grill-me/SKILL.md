---
name: fp-prd-grill-me
description: Use with fp-prd to grill a product idea, pain point, user story, or rough requirement until PRD-blocking decisions are confirmed.
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

