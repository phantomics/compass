---
id:            COMPASS-DRAFT-authoring-assistance
title:         Compass Authoring-Assistance Layer
genre:         Plan
scope:         program
program:       Compass
project:       ~
component:     authoring-assistance
language:      en
status:        Draft
created:       2026-08-24
authors:
  - Sloane
provenance:
  assistant:  opencode
relates-to:
  - COMPASS-0001
decisions:
  - COMPASS-D1
  - COMPASS-D2
  - COMPASS-D3
  - COMPASS-D4
open-questions:
  - COMPASS-O1
  - COMPASS-O2
  - COMPASS-O3
---

# Compass Authoring-Assistance Layer: Development Plan

This document plans the S9 authoring-assistance layer of the Compass standard
(`Compass.md` §22, §23 S9): a set of LLM-assisted skills that help authors
draft, review, look up, and derive Compass documents. It records what the layer
is, how it is split for portability across agent harnesses, which skills are
built now and which are deferred, and the invariant that keeps assistance
subordinate to the deterministic toolchain and human editorial review.

## Problem

Compass is a documentation standard whose payoff depends on documents actually
conforming to it — correct front-matter (§7), controlled vocabularies (§4, §6),
ADR-shaped decision records (§8), commit-pinned references (§9), and the
per-genre section shapes (§14). Two enforcement layers are described in the
standard: the deterministic validation toolchain (§22, `COMPASS-DRAFT-toolchain`)
and human editorial review (§6). Neither exists in automated form yet, and even
once the toolchain lands, a large class of quality concerns — genre fit,
section-shape judgment, decision-record quality, prior-art coverage,
cross-reference plausibility — is **structurally beyond** what deterministic
checks can assess (§22, "Complementary authoring assistance").

Authors also face friction the standard's discipline creates but does not
remove: producing a correct §7 front-matter block by hand, remembering the
per-genre §14 skeleton, allocating a provisional `DRAFT` identifier (§13), and
resolving cross-references across a federated corpus (§9, §10).

## Goals

- Provide **drafting** help that scaffolds conformant documents from the §14
  templates with a correct §7 front-matter block and a provisional identifier.
- Provide **judgment-level review** of the concerns deterministic checks cannot
  make, producing a report for a human editor (§6).
- Provide **corpus-aware lookup** of identifiers, `D`/`O` registers, and
  cross-references across the federation (§9, §10).
- Provide a **derivation driver** that wraps the derivation pipeline (§16) and
  adds LLM curation only where the pipeline requires human judgment (§21).
- Keep a **harness-neutral core** so the same behaviour ports across OpenCode,
  Claude Code, Cursor/Copilot, and MCP with only an envelope change (§23 S9).
- Never let assistance become an authority for conformance: skills **propose**;
  the §22 toolchain and §6 review **dispose**.

## Settled Decisions

### COMPASS-D1 — Four skills, split by shape

**Status:** Accepted
**Context:** The layer must serve drafting, review, retrieval, and derivation.
These have different interaction shapes (agent-shaped vs. tool-shaped) and
different dependency profiles.
**Decision:** Ship four skills — `compass-author`, `compass-review`,
`compass-lookup`, `compass-derive` — matching the §23 S9 naming.
`compass-author` and `compass-review` are agent/prompt-shaped; `compass-lookup`
and `compass-derive` are tool-shaped (portable to MCP).
**Alternatives:** A single monolithic "compass" skill (rejected: conflates
distinct trigger conditions and dependency profiles, and the §23 S9 harness
mapping already assumes the four-way split).

### COMPASS-D2 — Advisory-only until the toolchain exists

**Status:** Accepted
**Context:** The §22 toolchain (`COMPASS-DRAFT-toolchain`) is the deterministic
backstop the skills defer to, and it is not yet built.
**Decision:** Skills operate in **advisory-only mode** in the toolchain's
absence: they apply the standard's rules as best-effort guidance and state
plainly that output is unverified. When the toolchain exists, skills call it
rather than reimplement its checks.
**Alternatives:** Block skills until the toolchain lands (rejected: forfeits
the near-term drafting/review value that needs no deterministic backstop);
reimplement validation inside the skills (rejected: duplicates the §22 authority
and invites drift).

### COMPASS-D3 — Build author/review/lookup now; defer derive

**Status:** Accepted
**Context:** `compass-derive` wraps deterministic backends — the toolchain and
importer (S1/S2), audience projection (S5), fixture compilation (S7), and the
site build (S8) — none of which exist. The other three skills either need no
backend (`compass-review`) or degrade cleanly to `grep`/`glob`/`read`
(`compass-lookup`) or to template copying (`compass-author`).
**Decision:** Fully build `compass-author`, `compass-review`, and
`compass-lookup` now. Keep `compass-derive` a sharpened forward stub that names
its blocking dependencies and describes advisory-only interim behaviour.
**Alternatives:** Build all four now (rejected: `compass-derive` has no backends
to wrap and would be hollow); build only `compass-author` (rejected:
`compass-review` and `compass-lookup` are viable today and independently
useful).

### COMPASS-D4 — Harness-neutral core plus shared reference bundle

**Status:** Accepted
**Context:** §23 S9 requires the skills' substance to be authored once and
adapted per harness. Each skill also needs the same extracted slices of the
1400-line standard (vocabularies, front-matter schema, section shapes,
reference rules).
**Decision:** Each `SKILL.md` carries the harness-neutral behaviour; a shared
`skills/reference/` bundle holds the extracted standard data that all skills
read on demand. The OpenCode `SKILL.md` layout is the reference implementation
(§23 S9); other harnesses re-envelope the same core.
**Alternatives:** Inline the standard data in every skill (rejected:
duplication drifts); one reference file (rejected: coarse; four focused files
map to the concerns skills actually query).

## The skill set

- **`compass-author`** — scaffolds a new document: gathers `genre`/`scope`/
  `namespace`/`title`, validates against the controlled vocabularies, copies the
  matching `templates/` skeleton, fills the §7 front-matter, assigns a
  `<NAMESPACE>-DRAFT-<slug>` identifier (§13), records `provenance` (§7), and
  seeds genre-specific content (prior-art notes for `Survey`/`Plan`; a Files
  table from `git diff --stat` for `Log`).
- **`compass-review`** — assesses genre fit (§4), §14 section-shape adherence,
  `D`-record quality (§8), cross-reference plausibility (§9), and prior-art
  coverage; emits a report for the §6 editor. Never sets `approved-by`.
- **`compass-lookup`** — read-only retrieval across the federation: resolve an
  `id` or section anchor, a `D`/`O` record, relationship queries
  (`relates-to`/`supersedes`/`cites` and inbound backlinks), and namespace or
  federated `INDEX` listings (§9, §10, §13).
- **`compass-derive`** — deferred (D3). Wraps the derivation pipeline (§16) with
  LLM curation where required (§21); tracked as blocked on S1/S2/S5/S7/S8.

## Harness portability

Per §23 S9 each skill separates a harness-neutral core from a harness-specific
envelope. OpenCode is the reference envelope (`skills/*/SKILL.md` with OpenCode
front-matter, registered via `opencode.json` `skills.paths`). Claude Code,
Cursor/Copilot, and MCP re-envelope the same core; only front-matter keys, file
layout, and the discovery mechanism change. The propose-vs-dispose invariant
(D2) holds across every harness.

## Open Questions

### COMPASS-O1 — Advisory-mode conformance signalling

How should a skill mark output produced without the deterministic backstop so a
downstream reader does not mistake advisory scaffolding for validated
conformance? A front-matter marker, a review-report banner, or convention only?

### COMPASS-O2 — Registry access before the toolchain exists

`compass-lookup` and `compass-author` (identifier allocation) want a registry
(§13) that is presently unbuilt and, for most namespaces, has no entries yet.
What is the minimum registry/manifest shape the skills should assume, and how do
they degrade when it is absent?

### COMPASS-O3 — Provenance depth for LLM assistance

The standard requires `provenance:` when a document is authored or reviewed with
LLM help (§7, §22). What granularity should the skills record — assistant name
only, model version, session id, per-section attribution (cf. §23 P2)?

## Prior Art

Table: Prior systems and what this plan draws from each.

| System | What to draw from |
|---|---|
| Compass §22 | The propose-vs-dispose invariant; the deterministic checks the skills must not duplicate |
| DITA specialization | Additive extension without disturbing the core (§18) — the model for harness envelopes over a neutral core |
| Language servers (LSP) | Live completion/scaffolding as the non-LLM sibling of the authoring skill (§22) |
| Ancestor corpora (classic, origin, lexter) | The real per-genre section conventions the templates and review rubric encode |

## Roadmap

1. **Registration + tracking (now).** `opencode.json`; this Plan.
2. **Shared reference bundle (now).** `skills/reference/` extracted from the
   standard.
3. **Genre templates (now).** The nine §14 templates in `templates/`.
4. **Author / review / lookup skills (now).** Full `SKILL.md` for each.
5. **Derive skill (deferred).** Sharpen the stub; build when S1/S2/S5/S7/S8 land.
6. **Toolchain integration (future).** When `COMPASS-DRAFT-toolchain` exists,
   wire each skill to call it (D2) instead of best-effort checking.
7. **Cross-harness adapters (future).** Re-envelope the neutral core for Claude
   Code, Cursor/Copilot, and MCP (§23 S9).

## Outstanding Work

- Assign the canonical `COMPASS-<NNNN>` identifier at merge, replacing the
  provisional `COMPASS-DRAFT-authoring-assistance` (§13).
- Resolve COMPASS-O1..O3.
- Author the cross-harness adapters once the OpenCode reference set is proven.
