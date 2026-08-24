# Compass front-matter schema

Extracted from `Compass.md` §7 (with §5 identity and §13 allocation). Derived
reference data; `Compass.md` is the source of truth.

Every document in the reference binding opens with a YAML front-matter block.
Each field maps to a `classic-class` slot and an RDF predicate (§17); those
mappings are omitted here and kept in the standard.

## The block

```yaml
---
id:            PSYCHE-0001             # permanent identifier (§5)
title:         The Psyche Architecture
genre:         Architecture            # controlled (§4)
subtype:       ~                       # Eval: prior-art|comparison|tradeoff; Guide: tutorial|howto
scope:         program                 # component|project|program (§5)
program:       Psyche                  # program-scope docs
project:       ~                       # project/component docs
component:     ~                       # source of truth for grouping (§10)
language:      en                      # BCP-47 (§12)
status:        Design-Record           # controlled (§6)
api-version:   ~                       # Ref/Guide only
schema-version: ~                      # Spec only
created:       2026-06-19
updated:       2026-06-29
authors:
  - Sloane
reviewers:
  - Ada
approved-by:   Ada
reviewed:      2026-06-28
provenance:
  assistant:  claude
  session:    Ideation.PsycheGenesis
supersedes:    ~
superseded-by: ~
relates-to:
  - PSYCHE-0002
cites:
  - title:   AetherOS Specification
    locator: SPEC §7
    external: true
decisions:
  - PSYCHE-D16
  - PSYCHE-O1                          # (open-questions listed under open-questions:)
open-questions:
  - PSYCHE-O1
glossary:      Glossary.PsycheTerms
---
```

## Required on every document (§7)

`id`, `title`, `genre`, `scope`, `language`, `status`, `created`, `authors`.

Of these, `authors`, `created`, and `updated` MAY be omitted when derivable from
Git (see below). All other listed fields are optional and genre-dependent; omit
fields that do not apply (do not write `~` in real documents — that is
illustration only).

## Genre-conditional fields

| Field | Applies to |
|---|---|
| `subtype` | `Eval`, `Guide` only |
| `program` | program-scope documents |
| `project` | project/component-scope documents |
| `api-version` | `Ref`, `Guide` |
| `schema-version` | `Spec` |
| `approved-by`, `reviewers`, `reviewed` | any under editorial review (§6) |

## Git-derived fields (§7, §22)

`authors`, `created`, `updated` may be omitted and derived at build/validation
time:

- `authors` — from `git log --follow` over the file (honouring `.mailmap`).
- `created` — first commit that added the file.
- `updated` — most recent commit touching the file.

Rule: **absence means derive from Git; presence means use the written value as
an override.** Derivation never writes back into the file. A conforming document
MUST have each of these either present or derivable; the validator errors only
when neither is available.

## Hand-maintained (never Git-derived)

`reviewers`, `approved-by`, `reviewed`, `provenance`, `decisions`,
`open-questions`, `relates-to`, `cites`, `supersedes`, `superseded-by`,
`glossary`, and all classification fields (`genre`, `subtype`, `scope`,
`program`, `project`, `component`).

## Identifiers (§5, §13)

Form: `<NAMESPACE>-<NNNN>` — namespace short name plus a zero-padded serial,
allocated once and never reused. The identifier encodes **only** minting
authority and serial — never genre or scope (both are mutable).

Known namespaces: `CLASSIC`, `ORIGIN`, `LEXTER`, `LEXIS` (projects), `PSYCHE`
(program), `COMPASS` (this standard). Ask the user for the namespace of any
corpus not listed.

**Provisional identifiers:** a document under construction carries
`<NAMESPACE>-DRAFT-<slug>` (e.g. `ORIGIN-DRAFT-foreign-orbitals`), needing no
coordination. The namespace steward assigns the canonical `<NAMESPACE>-<NNNN>`
at acceptance/merge, updating the registry in the same change (§13).

## Provenance discipline (§7, §22)

A document authored or reviewed with LLM help MUST carry `provenance:` (at
minimum `assistant:`; `session:` where meaningful). The Compass skills always
set or preserve this when they touch a document.
