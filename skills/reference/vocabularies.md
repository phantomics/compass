# Compass controlled vocabularies

Extracted from `Compass.md` §4, §5, §6. This is derived reference data for the
Compass skills; `Compass.md` is the source of truth. Skills MUST treat these as
closed vocabularies — adding a value requires an accepted amendment (§13).

## Genres (§4)

Ten genres. The `genre` field carries the full name; the prefix names the file
(§10); the code is a two-letter mnemonic for indexes/facets only (never in the
identifier).

| Genre | `genre:` value | Prefix | Code | Role |
|---|---|---|---|---|
| Survey | `Survey` | `Survey.` | SU | Exploratory "should we?" — aspirational, non-normative; surveys the territory before a Plan |
| Eval | `Eval` | `Eval.` | EV | Evaluative analysis against a rubric |
| Architecture | `Architecture` | `Arch.` | AR | Comprehensive design record — aspirational and normative |
| Plan | `Plan` | `Plan.` | PL | Forward design plus roadmap for a buildable unit |
| Log | `Log` | `Log.` | LG | Engineering journal of work done and verified |
| Ref | `Ref` | `Ref.` | RF | Reference manual for running software |
| Guide | `Guide` | `Guide.` | GD | Task walkthrough or demonstration |
| Spec | `Spec` | `Spec.` | SP | Normative contract for running software |
| Glossary | `Glossary` | `Glossary.` | GL | Canonical terms and backronym registry |
| Ideation | `Ideation` | `Ideation.` | ID | Curated foundational seed discussion (rare) |

Notes:
- `Log`/`Plan` were historically `DevLog`/`DevPlan`; the short forms are
  canonical. Ancestor corpora still link to the old names — normalize to the
  current prefixes and to id-keyed links (§9).
- `Ideation` is for the *exceptional* curated seed discussion only; routine
  transcripts and scratch are **not** Compass documents (§2, §4).

## Subtypes (§4)

Only two genres take a `subtype`:

- **`Eval`** — `subtype: prior-art | comparison | tradeoff`
- **`Guide`** — `subtype: tutorial | howto`
  - `tutorial` — learning-oriented, guided walkthrough for a newcomer
    (the REPL-walkthrough style).
  - `howto` — task-oriented, terse numbered procedure ending in the result.

All other genres omit `subtype`.

## Scope (§5)

The `scope` axis records altitude and is orthogonal to genre.

| `scope:` value | Meaning |
|---|---|
| `component` | One subsystem of one project |
| `project` | A whole project |
| `program` | Spans several projects (system-of-systems, cross-stack comparison) |

## Status vocabularies (§6)

Status is genre-family dependent. Use exactly one value (except the
`Superseded-by: <id>` form, which names its successor).

### Proposal / record genres (`Survey`, `Eval`, `Plan`, `Arch`, `Log`)

| Status | Meaning |
|---|---|
| `Draft` | Being written; not yet complete |
| `Proposed` | Complete and under consideration |
| `In-Review` | Submitted for editorial/peer review; not yet authoritative |
| `Accepted` | Design/plan adopted (recorded by `approved-by`) |
| `Implemented` | The described work has been built |
| `Design-Record` | Comprehensive and settled, but not yet built (the characteristic `Arch` status) |
| `Deprecated` | No longer current, retained for history |
| `Superseded-by: <id>` | Replaced by another document; names it |
| `Rejected` | Considered and declined |
| `Withdrawn` | Retracted by its author before resolution |

`Log` documents are ordinarily `Accepted` or `Implemented`; `Draft` only while
in progress.

### Reference genres (`Ref`, `Guide`, `Spec`)

| Status | Meaning |
|---|---|
| `Current` | Describes the present state of the code |
| `Draft` | Describes code still in flux |
| `Deprecated` | Describes a component being retired |

Reference genres additionally carry `api-version` (`Ref`/`Guide`) or
`schema-version` (`Spec`) recording the software version described.

## The normativity grid (§4)

|  | Non-normative | Normative |
|---|---|---|
| **Aspirational** (not yet built) | `Survey` | `Arch` |
| **Existing** (running code) | — | `Ref` / `Spec` |

`Eval` sits beside `Survey` as its sharper evidential companion.

## The maturity ladder (§4)

`Survey` (should we?) → `Eval` (what does prior art teach?) →
`Plan` (how will we build it?) → `Log` (what we built and verified) →
`Ref` / `Guide` / `Spec` (how it works now).

Not every unit visits every rung. Because the identifier does not encode genre
(§5), a document may change genre as it matures without breaking its identity.

## Editorial review (§6)

- `In-Review` is the status marking a document under review.
- `reviewers:` lists who reviewed it; `approved-by:` names the reviewer who
  authorized `Accepted` (or `Design-Record` for an `Arch`); `reviewed:` records
  the date.
- For `project`- and `program`-scope documents the approver MUST NOT be the sole
  author. `component`-scope `Log`s MAY be self-accepted.

## The `external` flag (§6)

Material cited from outside the corpus is marked `external: true` where it
appears as a source (in `cites:`, §9).
