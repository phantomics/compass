# Compass per-genre section shapes

The **normative spine** is `Compass.md` §14. The **optional** sections below the
spine for each genre are drawn from the ancestor corpora (classic, origin,
lexter) that Compass was derived from; they are recurring, well-attested
patterns an author MAY use, not requirements. A conforming document keeps the
§14 section names and order; optional sections slot in where noted.

Conventions common to the ancestor corpora, normalized to Compass:
- An opening one-paragraph abstract after the H1. `Log` abstracts conventionally
  open "This document chronicles …".
- H1 title form is `<Topic>: <Genre Noun>` (e.g. `…: Development Log`,
  `…: Development Plan`, `…: Prior-Art Evaluation`). Genre/scope come from
  front-matter, not the title.
- Decisions use the §8 ADR shape with namespaced `D`-IDs (NOT the ancestral
  bold-lead numbered prose). Open questions use §8 `O`-IDs.
- Code references use §9 commit-pinned `path[:symbol]@revision` (NOT bare
  `file:line`). Links are id-keyed (§9).
- The Files table is `File | Action | Description`; add a `Repo` column only for
  cross-repo work. `Action` ∈ `New` / `Modified` (bold `**New**` optional).

---

## Log (§14)

**Spine (required order):**
```
# <Topic>: Development Log
<abstract: "This document chronicles …">
## Problem
## Design Decisions            (D-records, §8: Status/Context/Decision/Alternatives)
## Implementation              (### subsections per component/file; commit-pinned refs §9)
## Verification                (state the test-run command and pass count)
## Files                       (table: File | Action | Description)
## Outstanding Work
```

**Optional (attested):**
- A background section between Problem and Design Decisions —
  e.g. `## Investigation`, `## Starting point`, `## How real terminals do this`.
- `## Design Properties` (or `## Design Properties Preserved`) between
  Implementation and Verification — invariants the change preserves.
- A "meaning" section after Verification — `## What This Enables`,
  `## What This Demonstrates`, `## The Principle That Emerged`,
  `## Weaknesses Addressed`.
- `## Metrics` (optional per §14) — defined counters (checks added, regressions,
  total checks). Ancestors often fold metrics into Verification prose instead.
- `## Prior-art lineage` — table `Implemented feature | Reference lineage | Note`.

**Installments:** append follow-up work as `## Update <date> — <title>`
(canonical §14 form; ancestors used `## Addendum:` / `# Appendix:`). Larger
follow-ups become new `Log` documents linked via `relates-to`. Phased logs may
use `## Phase N — <title>` with the skeleton repeated at H3.

---

## Plan (§14)

**Spine:**
```
## Problem
## Goals
## Settled Decisions            (D-records, §8)
## <design sections>
## Open Questions               (O-records, §8)
## Prior Art
## Roadmap                      (ordered, indicative milestones)
```

**Optional (attested):** `## Thesis` (after Problem); `## Tradeoffs and
Non-Goals` / `## Scope and Non-Goals` / `## Tensions and Risks` /
`## Barriers` (before Open Questions). `Prior Art` is conventionally a table
`System | What to draw from`.

---

## Survey (§14)

**Spine:**
```
## Motivation
## <exploration sections>
## Honest Limits
## Relationship to Other Work
## Open Questions
```

**Optional (attested, the near-frozen ancestral spine):** after Motivation —
`## Why the substrate fits` (why-fit); `## Ontology sketch`;
`## Deployment modes`; `## What would be new work`; `## The deeper claim`
(a synthesis before Relationship to Other Work). Survey may close on a numbered
list of named design principles instead of, or alongside, Open Questions.

---

## Eval (§14)

**Spine:**
```
## Method
## The Shared Scenario
## The Rubric
## <renditions / comparisons>
## Synthesis
## Appendix — Source Map        (program-scope; §9)
```

**Optional (attested):** score each rendition against fixed rubric criteria
(`G1…Gn`) as bold-lead bullets; close each rendition with a one-line
`**Steal:** … **Reject:** …` lesson; per-installment `## Comparison — <N>`
tables and `## Synthesis for <project> — <N>`. Large evals are written in
`# Installment I…N` banners. Recall `subtype: prior-art | comparison | tradeoff`.

---

## Architecture (§14, from ISO/IEC/IEEE 42010)

**Spine:**
```
## Canonical Terms              (glossary table)
## Thesis / Concerns
## Influences                   (what each contributes and what is rejected)
## Settled Decisions            (D-records, §8)
## <per-viewpoint design>       (e.g. CPU, memory, I/O, boards)
## Open Questions               (O-records, §8)
## Roadmap                      (staged path)
## Appendices                   (worked scenarios)
```
Characteristic status: `Design-Record` (§6). Ancestor architecture-flavoured
docs (classic `Schema.md`, `Persistence.md`) add ASCII diagrams, `## Why …?`
rationale sections, definitional `## What Makes a X a Y?` sections, and a file
tree — all admissible as viewpoint/appendix content.

---

## Ref (§14)

Overview abstract, then API/protocol sections (classes, slots,
generic-function signatures), then a `## Project Structure` section.

**Attested shape (classic `Model.md`):** group H2 by ontology/subsystem layer;
under each, an H3 per class with a bulleted slot list annotated with persistence
strategy and RDF predicate. Close with `## Project Structure` (an ASCII file
tree mirroring code onto docs) and cross-reference lines. Living `Ref` pins
code references to a release tag and advances it (§6, §9). Carries `api-version`.

---

## Guide (§14)

Prerequisites, then the body.
- `subtype: tutorial` — a guided, narrated walkthrough. Attested style: a
  `## Design Goals` framing, a primitives section, then a REPL walkthrough with
  `### <step>` headings and `lisp` blocks carrying inline `;; =>`
  expected-output comments.
- `subtype: howto` — a terse, numbered task procedure ending in the achieved
  result. Attested style: `## Quick Start` with numbered `### 1. …` steps.

Carries `api-version`.

---

## Spec (§14)

Normative "Required …" sections using RFC 2119 language (MUST / SHOULD / MAY).

**Attested shape (classic `SchemaContract.md`):** an `## Overview`, then a
sequence of `## Required <Thing>` sections (each often a requirement table, e.g.
`Slot | Initarg | Persistence | Predicate`), then a numbered conformance
walkthrough (`Step 1 … Step N`), then a candid `## Afterword: Limits …` stating
what works, what does not yet, and what would close the gap. Note: the ancestor
used lowercase "must"; Compass Spec MUST use RFC-2119 uppercase. Carries
`schema-version`.

---

## Memo (§4, §8, §14)

**Spine:**
```
# <Component>: Memos
<one paragraph: the component the memos concern; link its Ref/Spec by id>
## Memos                        (M-records only, in identifier order)
### <ID> — <the property, stated as a claim>
**Status:** … / **Read-if:** … / **Basis:** … [/ **Recorded:** …] [/ **Superseded-by:** …]
<present-tense body, under about 200 words>
```

One host per major component of a project (`Memo.<Topic>.md`); a host holds
nothing but M-records. No ancestor corpus has this genre; it was added by
amendment (COMPASS-DRAFT-agent-workflow-D1–D4).

---

## Glossary (§4; net-new — no direct ancestor)

No ancestor Glossary exists; the closest precedent is classic `Model.md`'s
layer→class→vocabulary grounding table. Suggested shape:
```
## Canonical Terms              (table: Term | Definition | Notes/Source)
## Backronym Registry           (expansions of project/program backronyms; §1)
## Grounding                    (optional: term → external vocabulary/predicate map)
```
Referenced by other documents via the `glossary:` front-matter field (§7).

---

## Ideation (§4; rare)

No fixed skeleton. A curated, lightly-edited foundational discussion preserved
because it shaped a project's direction. Use only as a considered editorial act
(§2, §4); routine transcripts are disposable scratch and are not Compass
documents.
