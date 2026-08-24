---
name: compass-derive
description: Invoke Compass derivation pipelines with LLM curation where required — compile a project README from its template, produce a static-site build, or draft a Diátaxis-shaped end-user doc set from typed project docs. Use to generate derived artifacts from a Compass corpus. Deferred stub — its deterministic backends are not yet built, so see the Status section before relying on it.
---

# compass-derive

Derivation-driver skill for the Compass documentation standard (the S9
authoring-assistance layer; see `Compass.md` §22 and §23 S9, tracked as
`doc/Plan.AuthoringAssistance.md`, decision COMPASS-D3).

## Status: deferred forward stub

This skill is intentionally **not yet built**. It wraps deterministic backends
that do not exist, so there is nothing for it to drive:

- **S1/S2** — the validation toolchain and Markdown→Lexis importer
  (`COMPASS-DRAFT-toolchain`, §16, §22).
- **S5** — audience projection / end-user derivation
  (`COMPASS-DRAFT-user-doc-derivation`, §21).
- **S7** — fixture compilation / bounded README transclusion
  (`COMPASS-DRAFT-fixture-compilation`, §10).
- **S8** — the federated static-site build
  (`COMPASS-DRAFT-federated-site`, §16).

Per `Plan.AuthoringAssistance.md` (COMPASS-D3), `compass-author`,
`compass-review`, and `compass-lookup` are built now; `compass-derive` is the
last to complete, once the backends above land in their own Plans.

## Intended behavior (to be built)

- Run the README/fixture compiler with transclusion resolution (§10, S7).
- Drive a federated static-site build (§16 Astro target, S8).
- Seed an end-user doc set via audience projection, then assist curation
  (§21, S5) — derivation seeds, a writer finishes.
- Wrap the deterministic derivation tooling (§16 pipeline, §22 toolchain) behind
  a conversational interface, adding LLM curation only where the pipeline
  requires human/assistant judgment.

## Interim (advisory-only) behavior

Until the backends exist, if invoked this skill should **not fabricate a
pipeline run**. It may instead:

- explain what derivation *would* do for the requested artifact and which
  backend (S5/S7/S8) it depends on;
- for a README, describe the intended transclusion (`<!-- compass:include
  <id>#<anchor> -->`, §10) and point at the source documents via
  `compass-lookup`, without emitting a "compiled" file as if validated;
- hand off drafting to `compass-author` and checking to `compass-review`.

## Invariants

- This skill **proposes** derived drafts; the authoritative source remains the
  project docs, and derived artifacts are **never edited in place** (§16,
  one-way derivation).
- Do not claim a derived artifact is validated/conformant while the §22 toolchain
  and the relevant backend do not exist.
