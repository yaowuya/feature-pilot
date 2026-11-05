# FeaturePilot Visual Evidence Reuse

Read when establishing a visual input snapshot or considering retention of an earlier `VISUAL_REVIEW_PASS`. This supplements `ui-e2e-contract.md`; lifecycle, zero-mock, independent review, and retry limits are unchanged. It applies to direct execution and SDD, including task/final review. It never carries forward an E2E verdict.

## One case, one original review

Reuse means retaining an existing independent PASS for the same `Task ID + Case ID`, not issuing a new verdict. No hash, implementer/controller statement, or unchanged HEAD can establish the first PASS. `FAIL` and `CANNOT_VERIFY` cannot be promoted by reuse.

Before the original independent review, record the following input snapshot in the existing Visual Evidence Manifest; keep the visual provenance and screenshot fields there, not in a new delivery table or sidecar:

- `Render inputs`: the complete relevant dependency inventory and SHA-256 of actual bytes: route/page/components, shared styles/tokens, fonts/icons/assets, runtime dependencies and configuration. Record how imports, asset resolution, and runtime/build identity establish this closure; a lockfile or chosen file subset alone is not proof. Use normalized resolved paths; missing inputs or paths/symlinks escaping the declared root are unresolved unless explicitly inventoried and verified.
- `Capture inputs`: actual capture tool/probe and configuration, approved visual fixture/state identity, runtime/deployment identity, route, role, viewport, DPR, locale, theme, browser/fonts, and other case-affecting environment values. Revalidate the real runtime state, not only Git or cached screenshots; record non-sensitive identity/proof rather than secrets.
- `Acceptance inputs`: approved source identity/version and content fingerprint, case scope, masks, and acceptance rules. A mutable URL or timestamp alone does not freeze the source.
- `Input fingerprint`: SHA-256 over the sorted complete input inventory, file-content hashes, and explicit capture/acceptance values. Audit records are outside render inputs only when proven not consumed by rendering/capture/acceptance. Dependency/input uncertainty disables reuse.

The independent reviewer verifies this snapshot against the actual reviewed case and records `Input snapshot reference / SHA-256` in its append-only review, alongside the original `Reviewed HEAD`, review start/end, and artifact hashes. Without a verified complete snapshot, an existing review remains valid only under its original snapshot checks; it cannot use the cross-HEAD reuse path.

In direct mode, the controller persists the returned read-only review output in the existing ledger; the separate reviewer itself writes no files. In SDD, the fresh reviewer writes only its designated attempt-specific review artifact.

## Revalidation, not a new visual PASS

Before E2E launch, at task review, and at final review, independently check the retained evidence binding. All of the following must hold:

1. The original independent `VISUAL_REVIEW_PASS` exists, its reviewer/attempt/timestamps and manifest/reference/current/optional-diff SHA-256 remain intact, and the review end precedes the required E2E start. Never overwrite or re-date the original review/manifest, rebind it to current HEAD, or substitute a controller-issued verdict.
2. Recompute the complete input inventory and fingerprint from current bytes and actual runtime/capture/acceptance facts. Verify the original snapshot, dependency closure, environment, and real route/state still apply. Identical HEAD with dirty source is not unchanged input; different HEAD with only proven audit changes is not changed rendering.
3. Inspect the complete changed-path inventory since `Reviewed HEAD`, plus staged, unstaged, untracked, deleted, and renamed inputs. Explain every exclusion using current dependency evidence. Progress/review/package-only changes can be excluded only when they are not consumed by the case; path names such as `docs/` are not an automatic allowlist. Unknown impact, missing/external inputs, changed dependencies, or an incomplete baseline requires a fresh visual capture/review rather than inferred reuse.
4. The independent E2E verifier/task/final reviewer can inspect this proof under its existing read-only boundary. The controller may collect proof but cannot independently approve its own visual result. Direct mode keeps its separate read-only visual pass; SDD keeps the original fresh reviewer's persisted verdict.

Append a `Visual revalidation` entry to the existing progress/review evidence, containing `Task ID + Case ID`, `Original review / attempt`, `Original Reviewed HEAD`, `Current HEAD / dirty paths`, `Input snapshot / current fingerprint`, `Changed paths / exclusion proof`, `Runtime state proof`, `Artifact hash checks`, `Checked at / checker`, and `Decision: retained | fresh-review-required | BLOCKED`. This entry is verification evidence, not a replacement manifest, new PASS, or plan completion authority. Each check is current; an older revalidation entry alone cannot authorize a later launch/review.

## Invalidation and retry accounting

- An affected render/capture/acceptance input requires recapture and fresh independent review of the affected case/state. Unknown impact or changed case scope requires reviewing the full possibly affected scope; unaffected cases need their own complete retention proof. Never broaden an old case's scope, acceptance, source, or fixture under its PASS.
- A failed eligibility check returns the case to `STATIC_UI_READY` for the next visual review. Preserve SDD `visualAttempt` across commits, sessions, recovery, and reuse checks; increment only immediately before an actual fresh review dispatch. Checking or retaining evidence does not consume or reset attempts. At attempt 3, failure to retain is `BLOCKED`; no fourth dispatch. Apply the existing direct-mode three-attempt limit as well.
- E2E remains a separate real-browser verification on the current implementation/environment, with its own required coverage, actors/resources, cleanup, and attempt count. Visual retention never inherits, re-dates, or substitutes an earlier E2E PASS, and never waives a required case or archive blocker.
