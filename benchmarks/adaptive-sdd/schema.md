# Corpus schema

Every corpus file is a fixed benchmark requirement and must contain the following headings and fields.

## Metadata

- `Case ID`: stable case name.
- `Size`: one of `small`, `medium`, or `large`.
- `Fixture manifest`: repository-relative manifest path.
- `Fixture revision SHA-256`: normalized-text SHA-256 of that manifest.

## Requirement

The exact user request presented to the system under test. It must not contain generated performance results or implementation claims.

## Expected coverage

The behaviors and source areas a satisfactory decomposition must cover. These are quality expectations, not an answer key for task wording.

## Allowed paths

The only target-project paths that an implementation may change.

## Excluded paths

Paths that must remain unchanged, including the benchmark inputs and fixture metadata.

## Quality checks

Deterministic checks that must remain or become green. Baseline and candidate runs use the same checks and fixture revision.
