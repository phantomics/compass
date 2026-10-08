# Compass

**Common Ontological Model for Prose Artifacts by Structural Standard**

Compass defines a small, rigorous vocabulary for the technical
documents that accompany a family of related software projects. It grew
out of an ad-hoc set of filename prefixes (`DevLog`, `DevPlan`, `Concept`,
`Eval`, and unprefixed reference docs) that had served a handful of Common
Lisp projects well but was never written down, never indexed, and never
consistent across repositories. This document is that scheme made explicit,
reconciled against established prior art, and generalized to span many
projects at once.

The name is deliberate. The *Compass* is a tool used to draw lines
containing defined regions on a tracing board. The standard's central goal
is to express the full range of documents to be produced in the course of
a technology development project. Read as an acronym it expands to
**C**ommon **O**ntological **M**odel for **P**rose **A**rtifacts by
**S**tructural **S**tandard, where the embedded `COM` is itself
*Common Ontological Model* and *Ontology* carries the semantic grounding.

The standard is deliberately **lightweight**: documents are authored as
Markdown with a YAML front-matter block, tracked in Git, and readable
without tooling. At the same time it is designed so that a document is
simultaneously a **semantic entity** — every metadata field maps onto a
Common Lisp CLOS slot and an RDF predicate — so that a corpus of Compass
documents can later be compiled into a wiki, a static site, a triplestore,
or a native publishing platform without redesign.


## 1. Purpose and Lineage

Compass is a synthesis, not an invention. It draws each of its ideas
from a mature source and keeps the pieces that fit:

- **DITA** (Darwin Information Typing Architecture — IBM, later OASIS).
  The principle of *information typing*: a document has a *type* that
  determines its shape and purpose, and new types are derived by
  *specialization* from base types. DITA's base types — Concept, Task,
  Reference — are the direct ancestors of several Compass genres.
- **Diátaxis** (Procida). The four-way split of documentation into
  Explanation, Reference, Tutorial, and How-to. This informs the
  reference-side genres (`Ref`, `Guide`) and the exploratory `Survey`.
- **ADR / MADR** (Architecture Decision Records; Nygard). The discipline
  of recording a single decision as Context / Decision / Alternatives /
  Status. Compass's decision registers (§8) are ADRs with stable IDs.
- **IETF RFC and Python PEP.** Numbered documents with a controlled
  status lifecycle and a master index. Compass's numbering (§5) and
  controlled `status` vocabulary (§6) follow this tradition.
- **ISO/IEC/IEEE 42010** (Architecture Description). The model of an
  architecture description as stakeholders, concerns, viewpoints, views,
  and decisions with rationale. This shapes the `Arch` genre (§14).
- **declt** and **mgl-pax** (Common Lisp). Reference documentation
  generated from source, so that `Ref` and `Spec` documents describing
  live code need not drift from it.

The result is a **maturity ladder crossed with an altitude axis**: a
document is placed both by *where it sits in a project's lifecycle*
(Survey → Eval → Plan → Log → Reference) and by *how much it spans*
(a single component, a whole project, or a program of many projects).


## 2. Scope and Non-Goals

Compass is a standard for **project and engineering documentation** — the
documents by which the developers of a federation of related software
projects conceive, decide, build, verify, and reference their systems. Its
center of gravity is the *development record*: exploration, evaluation,
design, decisions, work logs, and the reference material that describes the
resulting software to the people who build on it.

It is **not** a universal documentation system, and it does better by saying
so than by pretending to cover everything. The following are explicit
non-goals. In each case the recommended approach is to use the established
framework named and, where the two meet, to connect them through an
integration seam (a `Ref` or `Guide` that links out to the external
artifact) rather than to absorb the concern into Compass.

- **End-user and product documentation** — installation guides, user
  tutorials, help centers. Compass's `Ref`/`Guide` serve *developer-facing*
  reference and walkthroughs, not polished end-user manuals. Cede this to
  **Diátaxis** and **DITA** — though §21 shows how an end-user set may be
  *derived* from project docs.
- **Regulatory and compliance controlled-document regimes** — ISO 9001,
  IEC 62304, DO-178C, FDA 21 CFR Part 11, SOC 2. Compass is not a compliance
  system of record and provides none of the signature, effective-date, or
  audit-trail machinery those regimes require.
- **Localization and translation management** — as a *core* concern. An
  Compass document has a single authoritative source language; translation is
  handled as an opt-in extension (§19), not by the core.
- **Single-sourcing and content reuse** — DITA-style `conref`/`keyref`
  transclusion. Compass documents are whole files with no include mechanism;
  the audience projection of §21 provides a limited cross-audience reuse
  instead.
- **Auto-generated API reference at scale** — OpenAPI/Swagger, Javadoc,
  Doxygen, and the HTML output of declt/mgl-pax. These are treated as
  *inputs or derived artifacts* that a `Ref` links to or is generated
  alongside, not as documents Compass manages.
- **Release notes and changelogs** — Keep a Changelog, semver release logs.
  These are per-release, append-oriented artifacts with their own
  conventions; Compass has no changelog genre.
- **Runbooks, on-call, and incident postmortems** — operational/SRE formats
  with distinct lifecycles.
- **Requirements specification and traceability matrices** — IEEE 29148 and
  requirement-to-test traceability. Compass's decision and open-question
  registers (§8) are not a requirements register.
- **Knowledge-base, support, and FAQ content** — searchable help-center
  articles with their own categorization and feedback loops. This is distinct
  from the `Memo` genre (§4): a memo records a verified engineering property of
  a system for the people and agents who change it, not an answer for its
  users.
- **Disposable scratch** — routine assistant transcripts, working notes, and
  throwaway experiments. These are not Compass documents; see the `Ideation`
  genre (§4) for the narrow exception of a curated, foundational discussion
  worth preserving. A finding that outlives the session or branch it came from
  is not scratch: if it passes the admission tests of §4, it belongs in a
  `Memo`.

Finally, a note on honesty about value. In its **near term** Compass delivers
*disciplined, federated, semantically-typed Markdown* — a real but modest
benefit over ad-hoc prefixes. Its distinctive payoffs — wiki, triplestore,
faceted search, semantic linking — are **aspirational**, gated on tooling
and platform work described in §16 (and the validation toolchain of §22),
and should be evaluated as a roadmap, not a present capability.


## 3. The Two-Axis Model and Binding Independence

Every Compass document is classified along two independent axes:

1. **Genre** — the document's purpose and maturity (§4).
2. **Scope** — the document's altitude: `component`, `project`, or
   `program` (§5).

These axes were conflated in the original ad-hoc scheme, which assumed
every document concerned a single component of a single project. Separating
them is what lets the standard describe, in one vocabulary, both a terse log
of one bug fix and a program-spanning hardware architecture record.

### Binding independence

Compass defines a **binding-independent information model**. The
normative content of a document is its *information model*: its genre,
scope, status, metadata fields, decision, open-question, and memo registers,
body structure, and its typed relationships to other documents. That model can
be *serialized* in more than one way — each serialization is a **binding**.

- The **reference binding** is Markdown with a YAML front-matter block,
  tracked in a Git repository. It is the binding this document specifies in
  full, and the one all authoring uses today.
- Alternative bindings may exist. In particular, §16 sanctions a future
  **Classic-native binding**, in which documents live as first-class
  semantic entities in a Classic publishing store rather than as files.

The information model is primary; a binding is a way of writing it down.
Sections 3–12 describe the information model and its expression in the
reference binding; §§13–15 cover governance, templates, and rationale.


## 4. Genre Vocabulary

A document's genre is declared in front-matter and echoed in its filename
prefix. There are eleven genres, each with a two-letter code used as a short
mnemonic in indexes and tooling facets — not in the permanent identifier
(§5).

| Genre | Prefix | Code | Role |
|---|---|---|---|
| Survey | `Survey.` | SU | Exploratory "should we?" — aspirational, non-normative; surveys the territory before a Plan |
| Eval | `Eval.` | EV | Evaluative analysis; `subtype: prior-art \| comparison \| tradeoff` |
| Architecture | `Arch.` | AR | Comprehensive design record — aspirational and normative |
| Plan | `Plan.` | PL | Forward design plus roadmap for a buildable unit |
| Log | `Log.` | LG | Engineering journal of work done and verified |
| Ref | `Ref.` | RF | Reference manual for running software |
| Memo | `Memo.` | ME | Verified, present-tense properties of running software; numbered M-records (§8) |
| Guide | `Guide.` | GD | Task walkthrough or demonstration; `subtype: tutorial \| howto` |
| Spec | `Spec.` | SP | Normative contract for running software |
| Glossary | `Glossary.` | GL | Canonical terms and backronym registry |
| Ideation | `Ideation.` | ID | Curated foundational seed discussion (rare) |

`Log` and `Plan` were historically `DevLog` and `DevPlan`; the shorter forms
are canonical because the expanded forms were four letters where every other
prefix reduces cleanly to two.

`Guide` carries a `subtype` distinguishing the two Diátaxis task genres:
`tutorial` (learning-oriented — a guided walkthrough for a newcomer) and
`howto` (task-oriented — steps to accomplish a specific goal for someone who
already knows the domain). This split is *cross-audience*: it applies to
developer-facing guides as much as to end-user ones, and it pre-shapes the
Diátaxis quadrants that the end-user derivation of §21 targets.

The `Ideation` genre is deliberately narrow. It is for the *exceptional* seed
discussion whose high-level framing is worth preserving as part of the record
— a foundational design conversation that shaped a project's direction.
Routine assistant transcripts, working notes, and throwaway experiments are
disposable scratch and are **not** Compass documents (§2); promoting one to
`Ideation` is a considered editorial act, not a default.

The `Memo` genre records durable knowledge about existing software: properties
whose understanding is key to working on a system, observed and verified rather
than designed. A memo records a lasting property of a system; it is not a dated
message to a reader. Memos are short, so they are kept as numbered **M-records**
in a host document (§8), normally one host per major component, named
`Memo.<Topic>.md`. A memo is admitted only if it passes four tests:

1. **Durable** — it should remain true for the expected life of the code it
   concerns, not only for one session or one branch;
2. **Consequential** — misunderstanding it leads to wrong code or wasted work;
3. **Not evident** — it cannot be read from the code, a source header, or an
   existing document;
4. **Grounded** — it states how it is known, in a form a reader could check.

Tests 1–3 are editorial judgment. Test 4 is checked: every M-record's
`**Basis:**` names at least one commit-pinned code reference (§9), a Compass
identifier, or the title of an entry in the host's `cites:`. A memo is not a
scratchpad (§2) and not a substitute for a `Ref`: when a component's memos
amount to a comprehensive description, they are folded into a `Ref` or `Spec`
and marked `Superseded`.

### The normativity grid

Four genres describe systems rather than journal work, and they divide
along two lines — whether the system yet exists, and whether the document
is normative about it:

|  | Non-normative | Normative |
|---|---|---|
| **Aspirational** (not yet built) | `Survey` | `Arch` |
| **Existing** (running code) | `Memo` | `Ref` / `Spec` |

`Survey` assesses whether something *should* exist by mapping the design
territory; `Arch` specifies, comprehensively and normatively, a system that
*does not yet* exist (a hardware architecture, a system-of-systems); `Ref`
and `Spec` describe software that *does* exist, normatively and
comprehensively; `Memo` records individual properties of existing software as
they are observed, without prescribing them. `Eval` sits beside `Survey`
as its sharper evidential companion — Survey maps the territory broadly,
while Eval systematically compares alternatives against a rubric to inform
a design.

### The maturity ladder

For a single unit of work, genres typically progress:

`Survey` (should we?) → `Eval` (what does prior art teach?) →
`Plan` (how will we build it, with a roadmap?) →
`Log` (what we built and verified) →
`Ref` / `Guide` / `Spec` (how it works now).

Not every unit visits every rung; a small bug fix may produce only a `Log`,
and a stable subsystem only a `Ref`. Because the permanent identifier does
not encode genre (§5), a document may change genre as it matures — a
`Survey` promoted to a `Plan` — without breaking its identity or any
inbound reference.

`Memo` stands beside the later rungs rather than on the ladder: memos
accumulate while a system is built and used, and the memos of a component are
eventually folded into its `Ref` or `Spec`.


## 5. Identity, Scope, and Numbering

### Scope

`scope` records a document's altitude:

- **`component`** — concerns one subsystem of one project (e.g. a single
  feature of a terminal emulator).
- **`project`** — concerns a whole project (e.g. an entire library's
  ontological model).
- **`program`** — spans several projects: a system-of-systems architecture,
  or a comparison positioning a whole stack against a peer.

Scope is orthogonal to genre: a `Log` may be `component`-scope, an `Arch`
`program`-scope, and so on.

### Identifiers

Every document carries a permanent identifier of the form:

```
<NAMESPACE>-<NNNN>
```

- **`<NAMESPACE>`** is the short name of the project or program that mints
  the document: `CLASSIC`, `ORIGIN`, `LEXTER`, `LEXIS` for projects,
  `PSYCHE` for a program, `COMPASS` for this standard.
- **`<NNNN>`** is a zero-padded serial number, allocated once within the
  namespace and never reused (§13).

Examples: `PSYCHE-0001`, `ORIGIN-0012`, `LEXTER-0007`, `CLASSIC-0003`.

**The identifier encodes only the minting authority and a serial number — it
deliberately does *not* encode the genre or the scope.** Genre and scope are
*classifications* of a document's content and altitude, and both are
mutable: a `Survey` may mature into a `Plan`, and a `component` document may
be re-scoped to `project`. A permanent identifier must survive such
reclassification, so the mutable facets live only in front-matter (§7) and,
for genre, in the filename prefix (§10). The namespace, by contrast, is an
*identity* fact — who mints and owns the document — not a content
classification; the rare case of a document genuinely changing owners is
handled by re-minting with a redirect (§13).

The identifier is the anchor for all cross-references (§9) and is identical
to the document's Classic URI (§7), so a document's identity is stable across
bindings and across a migration between source-of-truth tiers (§16).


## 6. Controlled Status and Editorial Review

The `status` field replaces the free prose that the ad-hoc scheme used
("Planning", "Conceptual", "Design record — synthesized from…"). It draws
from a controlled vocabulary so that a corpus can be filtered and a
document's lifecycle position is unambiguous.

### Proposal and record genres (`Survey`, `Eval`, `Plan`, `Arch`, `Log`)

- **`Draft`** — being written; not yet complete.
- **`Proposed`** — complete and under consideration.
- **`In-Review`** — submitted for editorial or peer review; not yet
  authoritative.
- **`Accepted`** — the design or plan is adopted (recorded by `approved-by`).
- **`Implemented`** — the described work has been built (a `Plan` whose work
  is done, typically alongside a `Log` and a `Ref`).
- **`Design-Record`** — comprehensive and settled, but describing a system
  not yet built. The characteristic status of an `Arch`.
- **`Deprecated`** — no longer current, retained for history.
- **`Superseded-by: <id>`** — replaced by another document; names it.
- **`Rejected`** — considered and declined.
- **`Withdrawn`** — retracted by its author before resolution.

`Log` documents, being journals of completed work, are ordinarily `Accepted`
or `Implemented`; they use `Draft` only while in progress.

### Reference genres (`Ref`, `Guide`, `Spec`)

Reference documents track the software they describe rather than a proposal
lifecycle:

- **`Current`** — describes the present state of the code.
- **`Draft`** — describes code still in flux.
- **`Deprecated`** — describes a component being retired.

They additionally carry an `api-version` (for `Ref`/`Guide`) or
`schema-version` (for `Spec`) recording the software version described.

### The memo genre (`Memo`) and its records

A `Memo` host document and each of its M-records (§8) carry one of four
statuses:

- **`Draft`** — recorded, not yet accepted.
- **`Current`** — accepted, and still holds.
- **`Deprecated`** — no longer true or no longer relevant.
- **`Superseded`** — replaced by another record or document. The successor is
  named in `superseded-by:` (for a host) or `**Superseded-by:**` (for a
  record), which is required with, and only with, this status.

A host is `Current` while it is maintained, however many of its records are
still drafts. Records are recorded, accepted, and retired independently of one
another; a retired record keeps its place and its identifier (§13).

### Editorial review

`status` records a document's *authorial* lifecycle. Editorial review is a
distinct concern, tracked by three front-matter fields and the one added
state above:

- **`In-Review`** — the status that marks a document as under review.
- **`reviewers:`** — the people or roles who reviewed the document.
- **`approved-by:`** — the reviewer who authorized the transition into an
  authoritative status — `Accepted`, `Design-Record`, or `Current` — with
  `reviewed` recording the date.

For `project`- and `program`-scope documents the approver MUST NOT be the
sole author: review is a genuine second pair of eyes. `component`-scope
`Log`s, being lightweight records of completed work, MAY be self-accepted
(`approved-by` the author). This maps directly onto Classic's editorial
workflow of writer and editor roles.

**Solo stewards.** In a namespace with a single maintainer, the second-reviewer
rule cannot be met. The namespace steward (§13) MAY therefore declare the
namespace's approval mode *solo*, in the repository's project configuration;
in a solo namespace the steward MAY be the `approved-by` of a document they
also authored. The declaration is visible and reversible: when a second
maintainer joins, the mode reverts and the second-reviewer rule applies to new
acceptances. In every namespace, `approved-by` names a person, never an
assistant: not the assistant recorded in `provenance:`, and not any tool that
assisted the change.

### Review gates

Review covers three distinct acts, with different rules:

1. **The change gate.** A change to a `project`- or `program`-scope document
   reaches the main branch only in a commit made by a person, or through a pull
   request a person approves. An assistant never makes the final commit to the
   main branch by itself. For `component`-scope documents the gate is
   RECOMMENDED.
2. **The acceptance gate.** A transition into an authoritative status
   (`Accepted`, `Design-Record`, `Current`, including an M-record's `Current`)
   requires a person's `approved-by`, at every scope. An assistant never sets
   `approved-by` or `reviewers`. An M-record has no approval field of its own:
   its host's `approved-by` and `reviewed` record the most recent acceptance of
   any of the host's records, and the change that accepts a record passes the
   change gate.
3. **Mechanical changes.** A change consisting only of identifier rewrites,
   link-target updates, supersession mirroring, and regenerated outputs passes
   the change gate without reopening acceptance. The toolchain (§22) classifies
   changed documents as mechanical or substantive, so that review effort goes
   to the substantive ones.

A substantive edit to an accepted document passes through the change gate and
keeps its status; the person who approves the change is reviewing it.

### The `external` flag

Material cited from outside the corpus — a peer system's specification, a
published paper — is marked `external: true` where it appears as a source
(§9). This preserves the epistemic distinction, familiar from comparison
documents, between "implemented and verifiable here" and
"presented-as-implemented elsewhere."


## 7. YAML Front-Matter Schema

Every document in the reference binding opens with a YAML front-matter
block. Each field maps to a `classic-class` slot and an RDF predicate, and
to the `:classic:*` attribute it compiles to on the Lexis `document` node
(§16); these mappings are what make an eventual semantic-store binding
lossless.

```yaml
---
id:            PSYCHE-0001             # → classic:uri; the permanent identifier (§5)
title:         The Psyche Architecture # → rdfs:label / dc:title
genre:         Architecture            # → classic:type / rdf:type (§4)
subtype:       ~                       # Eval: prior-art|comparison|tradeoff; Guide: tutorial|howto
scope:         program                 # → federation altitude (§5)
program:       Psyche                  # → sioc:Space  (program-scope docs)
project:       ~                       # → sioc:Space  (project/component docs)
component:     ~                       # → dc:subject / SKOS concept (source of truth for grouping)
language:      en                      # → dc:language (BCP-47; §12)
status:        Design-Record           # → classic:workflow-state (§6)
api-version:   ~                       # Ref/Guide only
schema-version: ~                      # Spec only
created:       2026-06-19              # → schema:dateCreated (PROV)
updated:       2026-06-29              # → schema:dateModified (PROV)
authors:                               # → dc:creator / schema:author
  - Andrew Sengul
reviewers:                             # → schema:reviewedBy (§6)
  - Ada
approved-by:   Ada                     # → approver authorizing Accepted (§6)
reviewed:      2026-06-28              # → review date
provenance:                            # → PROV-O; records the assisted process
  assistant:  claude
  session:    Ideation.PsycheGenesis
supersedes:    ~                       # → prov:wasRevisionOf (inverse of superseded-by)
superseded-by: ~                       # → status Superseded-by mirror
relates-to:                            # → typed internal links (§9)
  - PSYCHE-0002
cites:                                 # → foreign / out-of-corpus references (§9)
  - title:   AetherOS Specification
    locator: SPEC §7
    external: true
decisions:                             # → D-register (§8)
  - PSYCHE-D16
  - PSYCHE-D23
open-questions:                        # → O-register (§8)
  - PSYCHE-O1
memos:         ~                       # → M-register (§8); Memo genre only
glossary:      Glossary.PsycheTerms    # → term definitions consulted
---
```

Fields that do not apply to a genre are omitted (shown as `~` above for
illustration only). `id`, `title`, `genre`, `scope`, `language`, `status`,
`created`, and `authors` are required on every document; the rest are
optional and genre-dependent. Three of the required fields — `authors`,
`created`, `updated` — MAY be omitted from the file when derivable from Git
history, per the rules below.

### Git-derived fields

Author and date metadata duplicate what Git already knows. Rather than
hand-maintain (and let drift) values that `git log` supplies authoritatively,
Compass permits three fields to be **derived from Git history**:

- **`authors`** — from `git log --follow` over the file's history.
- **`created`** — the first commit that added the file.
- **`updated`** — the most recent commit touching the file.

The rule is symmetric with how the rest of the standard treats source of
truth: **absence in front-matter means derive from Git; presence means use
the written value as an override.** An explicit value wins whenever history
would mislead — imported files, batched commits, contributors under multiple
identities, files predating the corpus. For consistent author identity when
deriving, the toolchain SHOULD honour a repository's **`.mailmap`** file
(Git's standard canonicalization mechanism).

Derivation happens **at build and validation time**; the toolchain does not
write the derived values back into source files. Files remain the single
source of truth and stay clean; Git remains the authority for the derived
values.

The remaining front-matter fields are editorial or asserted acts that Git
cannot supply — `reviewers`, `approved-by`, `reviewed`, `provenance`,
`decisions`, `open-questions`, `memos`, `relates-to`, `cites`, `supersedes`,
`superseded-by`, `glossary`, and the classification fields — and remain
hand-maintained.

The effective conformance rule for the three Git-derivable fields: a
conforming document MUST have a value known to the toolchain, either present
in front-matter or derivable from Git; the validator (§22) errors only when
neither is available (an untracked file, an empty history).


## 8. Cross-Cutting Registers

Three kinds of numbered record cross document boundaries and are referenced
by stable ID from anywhere in the corpus: decisions (`D`), open questions
(`O`), and memos (`M`).

### Decision records (`D`)

A decision record captures one architectural or design decision. It follows
the ADR shape and is assigned a namespaced identifier `<NAMESPACE>-D<n>`
(e.g. `PSYCHE-D16`). A decision entry, wherever it appears (in a `Plan`,
`Arch`, or `Log`), has this shape:

```
### D16 — 64-bit datapath with 8-bit shadow tags

**Status:** Accepted
**Context:** …the problem and forces…
**Decision:** …what was chosen…
**Alternatives:** …what was rejected, and why…
```

The `decisions:` front-matter field lists the IDs a document introduces or
amends. Because IDs are stable and namespaced, one document may cite
another's decision (e.g. a comparison referencing `ORIGIN-D30`).

### Open-question records (`O`)

An open question is a known unresolved issue, assigned `<NAMESPACE>-O<n>`
(e.g. `ORIGIN-O9`). Open questions appear under a `## Open Questions`
section and are listed in the `open-questions:` field. They are
cross-referable across repositories, so a `program`-scope document may cite
a `project`-scope open question by ID.

### Memo records (`M`)

A memo record states one durable, verified property of existing software
(§4), assigned `<NAMESPACE>-M<n>` (e.g. `CLASSIC-M3`). M-records appear only in
`Memo` documents, and a `Memo` document holds only M-records, under a single
`## Memos` section in identifier order. The host lists its records in the
`memos:` front-matter field, mirrored against the body. A record has a heading
naming the property as a claim, a fixed set of bold-label fields, and a short
body in the present tense:

```
### CLASSIC-M3 — Federation outbox delivery is at-least-once

**Status:** Current
**Read-if:** writing a federation receiver, or changing outbox flush or retry
**Basis:** `mod/classic.engine.ref/federation/delivery.lisp:receive@a1b3f9c`; duplicate delivery reproduced after a forced retry

A batch can be delivered more than once after a timeout. Receivers must be
idempotent; the stale-content check in `delivery.lisp` is the current guard.
```

Table: M-record fields.

| Field | Required | Value |
|---|---|---|
| `**Status:**` | yes | `Draft`, `Current`, `Deprecated`, or `Superseded` (§6) |
| `**Read-if:**` | yes | The task or situation in which the memo matters, within 160 characters |
| `**Basis:**` | yes | At least one commit-pinned code reference (§9), Compass identifier, or title of an entry in the host's `cites:`, then how the property was established |
| `**Recorded:**` | no | The date the record was written (`YYYY-MM-DD`), which Git cannot supply per record |
| `**Superseded-by:**` | with `Superseded` | The successor's identifier; required with, and only with, that status |

The body should stay under about 200 words. A memo that grows larger is
superseded by a document of its own.


## 9. Reference and Citation Rules

The corpus has, historically, used incompatible cross-reference cultures:
Markdown links (Origin), prose backtick mentions (Classic), and bare
`file:line` code anchoring (Lexter). Compass unifies them.

### Document-to-document references

Use a Markdown link keyed on the target's `id`:

```markdown
See [PSYCHE-0002](../psyche/Eval.AetherOS-Psyche.md) for the comparison.
```

The relationship is mirrored in front-matter (`relates-to`, `supersedes`,
`superseded-by`). Prose-only mentions of another document (naming it without
a link) are not conformant references.

### Code references

A code reference identifies a location in source and MUST be **pinned to an
immutable revision**, so that it stays valid and verifiable as the code
evolves. A bare line number is prohibited as the sole anchor: line numbers
rot at the next edit, and with source-of-truth in Git they are the least
stable thing to cite. A reference is therefore an association between a path,
an anchor, and a commit — not a mutable coordinate into the working tree.

A code reference has the form:

```
`[<NAMESPACE>:]<path>[:<symbol> | #L<start>[-L<end>]]@<revision>`
```

- **`<path>`** — repository-relative path to the file.
- **`<symbol>`** — a function, class, or definition name. The **preferred**
  anchor: it survives reformatting and line drift.
- **`#L<start>-L<end>`** — an optional line or range, for precision where a
  symbol is insufficient.
- **`<revision>`** — REQUIRED: an immutable Git commit SHA (short or full),
  or, for a `Ref`/`Spec` describing a shipped version, a release tag.
- **`<NAMESPACE>:`** — prepended for a cross-repository reference (§5).

Examples:

```markdown
The stop protocol lives in `src/managed-process.lisp:stop-process@a1b3f9c`.
See `ORIGIN:src/managed-process.lisp#L233-L248@a1b3f9c`.
```

Prefer a symbol anchor to a line anchor; add a line range only for extra
precision. A renderer MAY expand a code reference into a forge permalink
(a GitHub/GitLab blob URL at that commit), which encodes exactly this
information and is guaranteed stable because it is pinned to the revision.

Commit-pinned references are **mandatory in `Log` and `Plan`** documents,
whose claims are implementation-anchored, and **recommended** elsewhere. A
living `Ref` that tracks current code SHOULD pin to a release tag and advance
the tag as it follows new versions (§6).

### Foreign citations

References to material outside the corpus go in the `cites:` field, each
with a `title`, a `locator`, and `external: true`. They are *not* Markdown
links into the repository. Program-altitude `Eval` and `Arch` documents that
lean on many foreign sources SHOULD carry a **source-map appendix**: a table
pairing each section with the primary sources it draws on.


## 10. Naming and Federated Layout

### On-disk naming

Files are named `<Genre-Prefix><Topic>.md`, e.g. `Log.StopFlag.md`,
`Arch.Psyche.md`, `Eval.AetherOS-Psyche.md`. Within a repository the `doc/`
directory is **flat**: files are distinguished by prefix, not by
subdirectory. Grouping by component is expressed in the `component`
front-matter field, which is the single source of truth for grouping;
generated indexes use it to organize views. Subdirectories, if present, are
a convenience only and never load-bearing.

### The three-tier federation

A program of related projects is documented across three tiers of
repository:

```
compass/                      # this standard + templates + master INDEX
  Compass.md
  templates/
  INDEX.md                    # federated aggregate of all repos

<program>/  (e.g. psyche/)    # program-scope documents
  doc/
    Arch.Psyche.md
    Eval.AetherOS-Psyche.md
    Glossary.PsycheTerms.md

<project>/  (classic/, origin/, lexter/, lexis/)
  doc/                        # project- and component-scope documents
    Log.*.md  Plan.*.md  Survey.*.md  Ref.*.md  ...
```

Each repository keeps a local registry / index of its allocated identifiers
(§13); the `compass/INDEX.md` federates these into one catalogue — the analogue
of a PEP-0 index, a DITA map, and a Classic federation space.

### The repository README

Each repository's `README.md` is a **fixture**, not an Compass document: it
lives at repo root (not `doc/`), carries no front-matter, does not
participate in the identifier or federation system, and follows ecosystem
convention — project identity, badges, install summary, quick example, and
links to the corpus, `LICENSE`, and `CONTRIBUTING`.

A README may be authored in either of two modes:

- **Direct-authored** — the README is a hand-written file at repo root.
  Where its sections cover material that also exists as a typed document
  under `doc/`, the README SHOULD link to that document by `id` rather than
  duplicate its content.
- **Compiled from a template** — for larger READMEs whose *marketing
  surface* is load-bearing (a project's public-facing pitch, feature
  showcase, in-depth quick start), the file at repo root is a compiled
  output. A `README.md.compass` template alongside it carries the
  hand-authored material (identity, motivation, community links, badges)
  interleaved with transclusion directives that pull named sections from
  Compass documents. The compiled `README.md` is committed so that GitHub
  and similar forges render it without a build step; the §22 validator
  checks that the committed file matches what the template would
  currently produce.

Transclusion directives use an HTML-comment form so they are invisible to
plain Markdown renderers and unambiguously delimited:

```markdown
<!-- compass:include APRIL-0007#getting-to-know-apl -->
…content pulled from the named section of APRIL-0007…
<!-- /compass:include -->
```

The target is an Compass `id` plus a Markdown section anchor; the pulled
content lives once in its authoritative typed document and is composed into
the README at build time. This is the closest Compass comes to DITA-style
transclusion, and it is bounded to fixture targets — it is not a general
document-to-document include mechanism (§2).

Compiled READMEs are the recommended pattern for projects whose README is a
substantial, multi-genre document; small READMEs are better direct-authored.
The same compilation mechanism MAY be applied to other repo-root fixtures
such as `CONTRIBUTING.md` and `CHANGELOG.md` where duplication with typed
docs would otherwise occur; `LICENSE` remains outside the genre and
compilation systems entirely. Other repo-root fixtures such as `LICENSE` 
that carry no doc-derived material remain simple fixtures with no 
compilation involvement.

The detailed specification of the transclusion directive, section-anchor
grammar, and validation rules is tracked as a follow-on Plan (§23, S7).


## 11. Diagrams and Media

*This section is intentionally a **stub**. It reserves a permanent home for
diagram and media conventions so that later detail can be filled in by
amendment (§13) without renumbering the document.*

The normative kernel that holds today:

- **Diagrams as code.** A diagram SHOULD be authored as text-based source
  (Mermaid, PlantUML, Graphviz DOT, or a Lexis figure) committed to the
  repository, so it diffs, reviews, and renders across targets. A rendered
  raster or vector image is a **derived artifact** (§16), never the source of
  truth.
- **Media assets.** Binary media (screenshots, photographs) are stored as
  referenced files with stable paths; they are referenced, not treated as
  the source of truth for any textual content.
- **Text equivalents.** Every diagram MUST carry a text-equivalent long
  description, per the accessibility rules of §12.

Deferred to a later amendment: preferred diagram languages and their
precedence, the asset-directory layout, figure numbering and caption format,
and the handling of large or interactive media.


## 12. Accessibility

Accessibility divides into rules an author can satisfy at write time — which
are **normative now** — and rules a renderer must satisfy, which are
described as a forward-looking extension in §20. This section states the
author-time rules. They map onto existing Lexis node slots and are checked by
the validation toolchain (§22).

An Compass document MUST:

- provide **alt text** for every image;
- provide a **text-equivalent long description** for every diagram (§11);
- give every table **header cells and a caption**;
- use **heading levels that nest without skipping** (no h2 → h4 jump);
- use **meaningful link text** — the linked `id` or a descriptive phrase,
  never "click here" or a bare URL (this reinforces the id-keyed link rule of
  §9);
- declare a **`language`** (BCP-47) in front-matter (§7), and mark inline
  spans in another language where they occur.

These rules cost little at authoring time, deliver value immediately without
waiting on tooling, and are the foundation the render-time WCAG conformance
of §20 builds upon.


## 13. Governance, Change Process, and ID Allocation

A standard needs a way to evolve and a way to hand out identifiers without
collision. Both are defined here.

### Stewardship

Compass is itself an Compass document — `program`-scope, identifier `COMPASS-0001`
— and is maintained under the same discipline it imposes. A named **steward**
owns each namespace: the steward of the `COMPASS` namespace owns this standard
and its controlled vocabularies (the genre set of §4, the status vocabulary
of §6); the steward of a project or program namespace (e.g. `ORIGIN`,
`PSYCHE`) owns that corpus's index and identifier allocation.

### Changing the standard

Compass carries a semantic version and a changelog expressed as decision
records (§8) in the `COMPASS` namespace. A change is proposed as a `Plan` (or,
for a single narrow decision, a `D`-record) against `COMPASS`, reviewed under
§6, and on acceptance the version is incremented:

- **patch** — clarifications and editorial fixes (including filling a stub
  section such as §11);
- **minor** — additive, backward-compatible changes (a new optional field, a
  new status value);
- **major** — changes that can invalidate existing conformant documents (a
  new required field, a removed genre).

The controlled vocabularies are deliberately small; adding a genre or a
status value REQUIRES an accepted amendment, so the taxonomy grows only by
conscious decision rather than by drift.

### ID allocation

Identifiers are `<NAMESPACE>-<NNNN>` (§5), monotonic within a namespace and
never reused. Because sequential numbers collide when several contributors
allocate on parallel branches, allocation follows one discipline:

- Each namespace keeps a checked-in **registry** (its local `INDEX`) listing
  every allocated identifier with its current title, genre, scope, and
  status. The registry is the authority for which numbers are taken.
- A document under construction carries a **provisional** identifier of the
  form `<NAMESPACE>-DRAFT-<slug>` (e.g. `ORIGIN-DRAFT-foreign-orbitals`),
  which needs no coordination.
- The namespace steward assigns the canonical `<NAMESPACE>-<NNNN>` at
  acceptance/merge time, updating the registry in the same change. This
  serializes number assignment at the one point — merge — where collisions
  can be resolved deterministically.

**Memo records** follow the same discipline. An M-record is numbered
`<NAMESPACE>-M<n>`, monotonic within the namespace and never reused. A record
in a host that has not yet been assigned carries a provisional identifier
formed from its host's, `<NAMESPACE>-DRAFT-<slug>-M<n>` (e.g.
`CLASSIC-DRAFT-federation-M2`), where `<n>` counts within the host; the
steward assigns the canonical `<NAMESPACE>-M<n>` in the same change that
assigns the host, or that accepts the record into an assigned host.

An identifier, once assigned, is permanent. A retired document is marked
`Deprecated` or `Superseded-by` (§6) but keeps its identifier, and a retired
M-record keeps both its identifier and its place in its host; a document
that genuinely migrates between namespaces (a rare re-homing, e.g. a
component document promoted to a program) is re-minted in the new namespace
with a `superseded-by` redirect from the old identifier, so no
cross-reference ever dangles.

### The master index

The `COMPASS` steward maintains `compass/INDEX.md`, which federates the
per-namespace registries into one catalogue (§10). It is generated from
front-matter and the registries, never hand-maintained as a parallel source.

### Conformance

Conformance is presently upheld by convention and editorial review (§6). The
definition of a conforming document and corpus, and the automated validator
that will enforce it in CI, are described in §22.


## 14. Per-Genre Templates

Each genre has a canonical section skeleton. Templates codify the
resolutions in §15; authors adapt them but keep the section names and order.

### Log

```
# <Topic>: Development Log        (H1; front-matter above)

<one-paragraph abstract: "This document chronicles …">

## Problem
## Design Decisions               (D-records, §8; Question/Decision/Alternatives)
## Implementation                 (subsections per component, with commit-pinned refs §9)
## Verification                   (state the test-run command and pass count)
## Files                          (table: File | Action | Description)
## Outstanding Work
```

`## Metrics` is optional; if present it uses defined counters (checks added,
regressions, total checks). Follow-up work on the same topic is appended as
`## Update <date> — <title>` sections; larger follow-ups become new `Log`
documents linked via `relates-to`.

### Plan

```
## Problem
## Goals
## Settled Decisions              (D-records, §8)
## <design sections>
## Open Questions                 (O-records, §8)
## Prior Art
## Roadmap                        (ordered, indicative milestones)
```

### Survey

```
## Motivation
## <exploration sections>
## Honest Limits
## Relationship to Other Work
## Open Questions
```

### Eval

```
## Method
## The Shared Scenario
## The Rubric
## <renditions / comparisons>
## Synthesis
## Appendix — Source Map          (for program-scope; §9)
```

### Architecture

Derived from ISO/IEC/IEEE 42010:

```
## Canonical Terms                (glossary table)
## Thesis / Concerns
## Influences                     (what each contributes and what is rejected)
## Settled Decisions              (D-records, §8)
## <per-viewpoint design>         (e.g. CPU, memory, I/O, boards)
## Open Questions                 (O-records, §8)
## Roadmap                        (staged path)
## Appendices                     (worked scenarios)
```

### Ref, Guide, Spec

- **Ref** — overview abstract, then API/protocol sections (classes, slots,
  generic-function signatures), then a Project Structure section.
- **Guide** — prerequisites, then the body. A `tutorial` runs as a guided,
  narrated walkthrough (the REPL-walkthrough style); a `howto` is a terse,
  numbered task procedure ending in the achieved result.
- **Spec** — normative "Required …" sections using RFC 2119 language (MUST /
  SHOULD / MAY).

### Memo

```
# <Component>: Memos              (H1; front-matter above, with memos:)

<one paragraph: the system or component the memos concern, and where its
 normative documentation lives (link the Ref/Spec by id)>

## Memos                          (M-records, §8, in identifier order)
### <ID> — <the property, stated as a claim>
```

A host holds only M-records. Hosts are divided by the major components of a
project, one host per component, named `Memo.<Topic>.md`.


## 15. Inconsistency-Resolution Reference

This table records the concrete inconsistencies observed across the existing
corpora (Classic, Origin, Lexter) and the resolution each receives above. It
is the rationale companion to the rules in §§4–14.

| # | Area | Observed variants | Resolution |
|---|---|---|---|
| 1 | Doc-to-doc references | Origin: Markdown links; Classic: prose mentions; Lexter: filesystem paths | Markdown links keyed on `id`; front-matter mirrors (§9) |
| 2 | Code references | Lexter: bare `file:line`; Classic/Origin: file name or prose | Commit-pinned `path[:symbol]@revision`; mandatory in Log/Plan (§9) |
| 3 | Foreign references | Ad-hoc inline only | `cites:` + source-map appendix (§9) |
| 4 | Front-matter format | None / `Date` / `Date+Status` / prose bold-label lines | Uniform YAML block (§7) |
| 5 | Status values | Free prose | Controlled vocabulary + editorial review (§6) |
| 6 | Log trailer sections | `Tests/Files/Metrics` vs `Verification/Files/Outstanding` vs `Future work` | Fixed `Verification → Files → Outstanding Work`; Metrics optional (§14) |
| 7 | Decision sub-format | `Question/Decision` vs Adopted/Rejected prose vs numbered vs `D`-IDs | ADR shape + namespaced `D`-IDs (§8) |
| 8 | Open questions | "Open Questions" vs "Open Design Questions"; numbered vs bullets | `## Open Questions` + `O`-IDs (§8) |
| 9 | `Files` table | `Repo/File/Action/Description` vs `File/Action/Description` vs bullets | Canonical table; `Repo` column only when cross-repo (§14) |
| 10 | Title / H1 form | Varies widely by document | Per-genre title template; genre/scope from front-matter (§14) |
| 11 | Installments / appendices | Ad-hoc dated phases; inconsistent depth | `## Update <date> — <title>`, or new linked document (§14) |
| 12 | Reference sub-roles | Unprefixed bucket mixes manual / demo / contract | Split into `Ref` / `Guide` / `Spec` (§4) |
| 13 | Directory layout | Classic subdirs vs Origin/Lexter flat | Flat `doc/`; `component` front-matter is truth (§10) |
| 14 | Provenance disclosure | Some state it, most silent | `provenance:` front-matter (§7) |
| 15 | Scope declaration | Explicit in Psyche, implicit elsewhere | `scope:` axis + optional in-body Scope/Out-of-scope (§5) |
| 16 | Metrics / test reporting | `## Metrics` counts vs prose vs omitted | Verification states run command + pass count; Metrics optional (§14) |
| 17 | Author/date metadata | Hand-maintained; drifts from Git | MAY be Git-derived (§7, §22) |


## 16. Appendix — Derivation and Rendering Targets

An Compass corpus is a **source of truth** from which every other form is
**derived one-way**. The reference binding keeps that source in Git as
Markdown+YAML; all rendered forms are compiled from it and never edited
directly.

### The pipeline

```
Compass .md + YAML                  (Git = source of truth)
        │  Markdown→Lexis importer
        ▼
Lexis IR (body tree)  +  Classic metadata / RDF   (front-matter → :classic:*)
        │  Lexis renderers (one-way projections)
        ├── HTML       ─────► Antora / Sphinx / MkDocs / Backstage TechDocs
        ├── Markdown   ─────► interchange / any Markdown-based site
        ├── plain text ─────► Meilisearch / Typesense (faceted search), RSS
        ├── JSON-LD    ─────► triplestore (Classic RDF, or Apache Jena) + SEO
        └── Classic wiki  ─── Lexis render + triplestore resolution + genre lenses
```

**Lexis** ("Lisp EXpressions as Interchange Syntax") is the canonical
intermediate representation for the document *body*: a semantic
s-expression document model parsed into an extensible CLOS node tree, with a
per-node-per-medium rendering generic function. Front-matter supplies the
*metadata*, mapped onto Lexis `:classic:*` attributes and the RDF graph.
**JSON-LD is an output of this pipeline, not the IR** — it is one Lexis
render target (Schema.org structured data driven by Classic metadata), used
for search and SEO.

The only new component the pipeline requires is a **Markdown→Lexis
importer** (front-matter → `:classic:*` document attributes; CommonMark
blocks → Lexis nodes). It keeps authoring in portable Markdown while
unlocking the whole Lexis fan-out, and it shares its Markdown+YAML parsing
front-end with the validation toolchain (§22). Genre-specific rendering — a
`Log` or `Arch` rendering its front-matter as a typed infobox — plugs in via
Lexis's tag-extension mechanism and Classic's `:infobox`/`:label` lenses; the
concrete tag and lens registry is deferred to a follow-on Plan.

### Named targets

- **Classic wiki** and the **triplestore** are the always-present semantic
  endpoints; the wiki resolves cross-references and renders genre infoboxes
  via lenses, with revision history mapped from Git commits.
- **Antora** — native multi-repository aggregation; its component/version
  model maps directly onto Compass `scope`/`project`. Best fit for the
  federated corpus.
- **Sphinx + MyST** — `intersphinx` gives cross-project referenceable
  objects that mirror the federated `id` graph; strong for Common Lisp
  reference material fed from declt/mgl-pax.
- **Backstage TechDocs** — docs-as-code aggregated into a catalogue of
  entities; front-matter maps to catalogue metadata. The enterprise story.
- **Astro (and Astro-family static generators)** — component-oriented static
  generation with typed content collections; a good fit for a *federated*
  multi-project doc-and-marketing site drawing from many repositories at
  once. Its Zod-typed content collections consume the same front-matter as
  the RDF/JSON-LD binding, and its component model suits genre-specific
  rendering and project landing pages. Distinct from Antora (component-
  oriented vs. AsciiDoc-native); both remain valid. The full scope —
  federation resolver, Astro-target Lexis renderer, content gating, and
  README integration — is tracked as S8 (§23).
- **Meilisearch / Typesense** — faceted full-text search indexed on genre,
  scope, status, component, project, author, and date.

### Bindings and source-of-truth tiers

Per §3 the standard is binding-independent. Two source-of-truth **tiers**
are recognized:

- **Tier 1 — file-based (available now).** Markdown+YAML in Git is
  authoritative; Classic and all other forms are derived. This is the
  reference binding and the default.
- **Tier 2 — Classic-native (future).** Documents live as first-class
  semantic entities in a Classic publishing store, which is authoritative
  and versioned by Classic's own revision and journaling machinery. Markdown,
  HTML, and JSON-LD become exports. This is the "Classic-as-Git-host →
  semantic project wiki" form: a project's documentation as a Classic
  publication with richer structure than a conventional wiki. Tier 2 is
  gated on Classic's maturation into a comprehensive publishing system with
  a scalable persistence backend, revision/versioning, and host-level
  version-control functions.

**The invariant that keeps this safe:** *there is exactly one source of
truth per corpus, all other forms are derived one-way, and the direction of
derivation is set by the active binding — the two tiers are never
concurrent for the same corpus.* Dual authority (files and Classic entities
both editable at once) is prohibited, as it reintroduces the
divergence/merge hazard the one-way design exists to avoid.

- **Promotion** (Tier 1 → Tier 2) is a one-time import: the Markdown→Lexis→
  Classic pipeline run to *persist* its output as the authoritative store,
  after which files become exports.
- **Export** (Tier 2 → Markdown+YAML) is the Git, offline, and non-Classic
  fallback.

**Conformance of the textual binding.** The Markdown+YAML binding MUST
round-trip the **core information model** — everything defined in §§3–12 —
**losslessly**. A Tier-2 corpus MAY carry extensions beyond what Markdown
can express (typed relationship graphs, embedded resources, richer
provenance); on export these MAY degrade, but the exporter MUST signal the
loss rather than discard content silently, following Lexis's renderer
principle. This guarantees that a Classic-native corpus can always be
exported to a portable, non-proprietary form — preserving the simple
migration story and preventing lock-in.

**Identity across bindings.** A document's `id` (its Classic URI, §5) is
stable across bindings and across a tier migration, so the federated
cross-reference graph (§9) survives promotion and export intact.


## 17. Appendix — Classic-as-Platform Mapping

For implementers targeting Classic (as a render target in Tier 1 or as the
store in Tier 2), the Compass information model maps onto Classic's
semantic model as follows. This table doubles as the ingestion specification.

| Compass concept | Classic mapping |
|---|---|
| `genre` | `classic:type` / `rdf:type` (a `doc-<genre>` subclass of `wiki-page`) |
| `scope` | Federation altitude / enclosing `sioc:Space` |
| `id` | `classic:uri` — the entity's canonical URI |
| `status` | `classic-stateful` workflow state |
| `reviewers` / `approved-by` | Editorial-workflow role relations |
| `language` / translations | `dc:language` + locale-qualified entities (§19) |
| Front-matter fields | `classic-class` slot annotations with `:predicate` |
| `relates-to` / `supersedes` | Typed relationship slots (page links / `prov:wasRevisionOf`) |
| `cites` (external) | Foreign-reference entities flagged non-corpus |
| `D` decision records | `doc-decision` entities, individually addressable |
| `O` open questions | `doc-open-question` entities, individually addressable |
| `M` memo records | `doc-memo` entities, individually addressable |
| Body | Lexis document tree (`:classic:*`-annotated) |
| Master `INDEX` | A Classic federation space aggregating the corpus |
| Genre infobox rendering | `:infobox` / `:label` lens specs per `doc-<genre>` class |

Under Tier 2 these mappings are the *storage* model directly; under Tier 1
they are the *derivation* target that the pipeline (§16) produces.


## 18. Appendix — Extension Mechanism

*Non-normative; forward-looking.*

The core of Compass is deliberately small. Capabilities beyond it attach as
**extensions**, so the core need not grow to accommodate every concern. An
extension is defined by the same principle that governs the whole standard:
add without disturbing what is already there.

- **Attachment points.** An extension MAY add namespaced front-matter keys
  (e.g. `l10n:`, `a11y:`, `audience:`), optional Lexis tags or attributes,
  and named conformance profiles. It MUST NOT redefine core fields or change
  core semantics.
- **Graceful degradation.** A processor that does not understand an extension
  MUST still process the core correctly by ignoring the extension — the same
  discipline Lexis applies to unknown tags (its "never silently discard,
  approximate or degrade" renderer principle) and that DITA applies to
  specialization.
- **Layering.** Extensions are opt-in per corpus and compose: a corpus may
  enable localization (§19), accessibility profiles (§20), and audience
  projection (§21) independently.

Prior art: DITA specialization and conditional-processing (profiling); the
RDF/OWL practice of additive vocabularies.

The following appendices define three extensions in this shape.


## 19. Appendix — Localization Extension

*Non-normative; forward-looking.*

Localization is modelled the way everything else in Compass is: one
authoritative source, everything else derived one-way.

- **Source language.** Each document declares an authoritative `language`
  (§7). There is exactly one source language per document.
- **Translations are derived and revision-pinned.** A translation records the
  source **revision** it was translated from (a commit SHA — the same
  commit-pinning mechanism as §9). When the source advances past that
  revision, the translation is automatically flagged **stale**, exactly as a
  code reference would be.
- **Identity.** A translation shares the source document's `id` with a locale
  qualifier — `ORIGIN-0012@fr` — and never receives a new id, so the
  federated cross-reference graph (§9) is unaffected and a reader may resolve
  any locale of a referenced document.
- **Front-matter.** A translation carries `translation-of: <id>`,
  `source-revision: <sha>`, `locale: <BCP-47>`, and
  `translation-status: untranslated | translated | stale | reviewed`.
- **Interchange.** Because the body is a Lexis tree of text nodes, the
  pipeline can emit **XLIFF** for translators and re-import their work,
  keeping translators out of Markdown structure.

Prior art: XLIFF, the DITA translation model, gettext PO, Mozilla Fluent.


## 20. Appendix — Accessibility Extension (Render-Time and Profiles)

*Non-normative; forward-looking. Complements the normative author-time rules
of §12.*

Where §12 governs what an author must put *into* a document, this extension
governs what a renderer must produce *from* it.

- **Render-time conformance.** The Lexis HTML renderer and Classic themes
  SHOULD target **WCAG 2.x AA**: semantic HTML, ARIA roles where semantics
  are otherwise lost, sufficient colour contrast in themes, a sensible focus
  order, and a reading order that matches the document order.
- **Conformance profiles.** A corpus MAY declare a target level (e.g.
  `a11y: wcag-2.2-AA`) as a profile; the validator (§22) checks the
  author-time rules of §12 and a conforming renderer certifies the
  render-time half.
- **Language and pronunciation.** The `language` tag and inline
  language-span marks (§12) feed screen-reader pronunciation, so this
  extension and localization (§19) reinforce each other.

Prior art: WCAG 2.x, WAI-ARIA, EPUB Accessibility.


## 21. Appendix — Audience Projection and End-User Derivation

*Non-normative; forward-looking.*

End-user documentation is not a genre in Compass; it is a **derivation** of the
project docs, produced by projecting audience-appropriate content and
re-shaping it into the Diátaxis quadrants.

- **Audience tagging.** Documents and, via Lexis attributes, individual
  blocks carry an `audience` designator — `developer | end-user | both`.
- **Projection.** The end-user set is produced by selecting end-user-
  applicable content and re-sequencing it into Diátaxis quadrants
  (Tutorial / How-to / Reference / Explanation), reusing the `Guide`
  `tutorial|howto` subtype (§4) for the two task genres.
- **Derivation *plus* curation — the honest part.** Projection **seeds** the
  end-user set; it does not finish it. End-user docs need framing, tone, and
  screenshots that development docs lack, so a technical writer curates and
  augments the projected material. This is cross-audience *reuse*, not full
  automation, and it is the closest Compass comes to single-sourcing (§2).
- **One-way.** The project docs remain the source of truth; the end-user set
  is a derived corpus (itself potentially an Compass corpus in a product
  namespace, or an external Diátaxis/DITA site).

Prior art: DITA `@audience` conditional processing (ditaval); Diátaxis.

Full scope-out of the projection rules, curation refresh semantics,
terminology mapping, product-namespace governance, and product-release
versioning is tracked as the follow-on Plan `COMPASS-DRAFT-user-doc-derivation`.
This appendix remains a sketch; the Plan will carry the detail and is
recorded in §23 as one of the standard's specified-but-deferred items.


## 22. Appendix — Conformance and the Validation Toolchain

*Non-normative; describes intended tooling, not yet built. Tracked as the
`COMPASS-DRAFT-toolchain` Plan.*

Until this toolchain exists, conformance is upheld by convention and
editorial review (§6, §13); an unenforced standard drifts, so the toolchain
is the priority follow-on.

### Conformance definitions

- A **conforming document** has all required front-matter fields (§7), uses
  only controlled-vocabulary values (genre, subtype, scope, status), carries
  a well-formed unique `id`, resolves all of its document references, pins
  every code reference to a revision where required (§9), and satisfies the
  author-time accessibility rules (§12).
- A **conforming corpus** additionally has a consistent registry (§13): every
  `id` unique within its namespace, every `relates-to` / `supersedes` /
  inbound link resolving, and no dangling `superseded-by` redirect.

### What the validator checks

- **Front-matter schema** — required fields present; values well-typed.
- **Controlled vocabularies** — `genre`, `subtype`, `scope`, `status`
  drawn from §4/§6; `Superseded-by` names a real id.
- **Identity and registry** — id format (§5), uniqueness, registry agreement.
- **Reference integrity** — document links resolve to real ids; code
  references are commit-pinned in `Log`/`Plan` (§9); foreign `cites` are
  well-formed.
- **Git-derived fields** — when `authors`, `created`, or `updated` are
  omitted from front-matter, derives them from Git history (§7); errors
  only if underivable (untracked file, empty history). An explicit value in
  the file overrides derivation.
- **Accessibility (author-time)** — the §12 MUST rules.

Severity maps to CI outcome: a **MUST** violation is an error that blocks
merge; a **SHOULD** violation is a warning. The validator complements, and
does not replace, the human editorial review of §6.

### Implementation in Common Lisp (description)

The toolchain is intended to be a Common Lisp program — a fitting choice, as
the corpus and its target platform (Classic) are Lisp, and the validator can
share code with the Markdown→Lexis importer (§16).

- A **Markdown parser** (e.g. `3bmd` or a CommonMark binding) reads the body;
  a **YAML parser** (e.g. `cl-yaml`) reads the front-matter block. This
  parsing front-end is the *same* one the §16 importer uses — one front-end
  serving both validation and derivation.
- A **Git integration** shells out to `git log --follow` (respecting
  `.mailmap`) as the source for derived `authors`/`created`/`updated` fields
  (§7); the same integration verifies commit-pinned code references from §9.
- The checks above run over the parsed front-matter and body tree, emitting a
  report (human-readable and machine-readable) with per-finding severity.
- As a side output the tool can regenerate each namespace's registry and the
  federated `compass/INDEX.md` (§13, §10) from front-matter, keeping the index
  from being a hand-maintained parallel source.
- It runs locally and in CI (on pull request), gating merges on errors.

The concrete design and code belong in a separate effort; this appendix fixes
only what the toolchain must guarantee and how it fits the pipeline.

### Complementary authoring assistance

Additional layers of assistance may complement the deterministic toolchain
without replacing it. **Editor / language-server integration** provides live
front-matter completion, id lookup, section-anchor selection, and template
scaffolds during authoring. **LLM-assisted skills** (e.g. an OpenCode skill
package) provide drafting help and judgment-level review — genre fit,
section-shape adherence, decision-record quality, cross-reference
plausibility — that deterministic checks structurally cannot make.

Both layers **propose**; the §22 toolchain **disposes**. Neither is an
authority for conformance: a document is conformant only when the toolchain
says so, and human editorial review (§6) remains the approval gate. LLM
assistance is subject to the standard's provenance discipline — a document
authored or reviewed with LLM help carries `provenance:` in front-matter
(§7). These layers are tracked as S9 (§23).


## 23. Appendix — Known Limitations and Outstanding Issues

*Non-normative; a durable record of the standard's known gaps and how each
is being addressed. Entries are never deleted; they migrate between
categories as amendments (§13) land, so the history of what changed and why
is legible without excavating the change log. This appendix is prospective
(what Compass itself still lacks); it complements §15, which is retrospective
(what the ad-hoc corpora did and how Compass fixes them).*

### Resolved

Closed items, retained as history.

| # | Area | Where addressed |
|---|---|---|
| R1 | `Concept` genre collided with DITA/Diátaxis "concept/explanation" | Renamed to `Survey` (§4) |
| R2 | Mandatory `file:line` code refs institutionalized rot | Commit-pinned `path[:symbol]@revision` (§9) |
| R3 | Identifier encoded mutable classification (genre, scope) | Decoupled to `<NAMESPACE>-<NNNN>` (§5) |
| R4 | No governance, change process, or ID allocation mechanism | §13 (stewardship, amendment process, registry-based allocation) |
| R5 | No editorial review workflow | `In-Review` status + `reviewers`/`approved-by`/`reviewed` (§6) |
| R6 | Scope creep / over-claiming as universal doc system | Explicit non-goals (§2) |
| R7 | `Ideation` genre canonized raw AI transcripts | Tightened to rare curated cases (§4); routine transcripts declared disposable (§2) |
| R8 | Tutorial vs. How-to collapsed in `Guide` | `Guide` `subtype: tutorial \| howto` (§4) |
| R9 | Localization absent from the model | Extension appendix (§19) |
| R10 | Accessibility unaddressed | Author-time rules normative (§12); render-time extension (§20) |
| R11 | `authors` / `created` / `updated` duplicated Git metadata | MAY be Git-derived (§7); validator derives with `.mailmap` (§22) |
| R12 | No home for durable, verified knowledge about running software; agents' findings lost between sessions | `Memo` genre (§4) with M-records (§8); admission tests keep it from becoming scratch (§2) |
| R13 | Second-reviewer rule impossible to meet in a one-maintainer namespace | Solo-steward approval (§6) |
| R14 | "Review" conflated committing, accepting, and mechanical rewrites | Three review gates (§6) |

### Specified, tooling deferred

Described in the standard but not yet built. Each has a tracking Plan
identifier in the `COMPASS` namespace.

| # | Area | Tracked as |
|---|---|---|
| S1 | Validation toolchain (Common Lisp; front-end shared with the importer) | `COMPASS-DRAFT-toolchain` (§22) |
| S2 | Markdown→Lexis importer | Part of `COMPASS-DRAFT-toolchain` (§16) |
| S3 | Diagrams and media detailed conventions | §11 stub, to be filled by amendment |
| S4 | Classic-native Tier-2 binding | §16; gated on Classic maturation |
| S5 | User-doc derivation (audience projection, curation refresh, terminology mapping) | `COMPASS-DRAFT-user-doc-derivation` (§21) |
| S6 | Genre-specific Lexis tags and Classic infobox/label lens registry | Follow-on Plan (§16) |
| S7 | Fixture compilation / bounded transclusion (README, CONTRIBUTING, CHANGELOG) | `COMPASS-DRAFT-fixture-compilation` (§10) |
| S8 | Federated multi-project static site (Astro or equivalent): federation resolver, Astro-target renderer, content gating, README integration | `COMPASS-DRAFT-federated-site` (§16) |
| S9 | Authoring assistance layer: editor/language-server integration and LLM skills across harnesses (compass-author, -review, -lookup, -derive), with a harness-neutral core and per-harness adapters | `COMPASS-DRAFT-authoring-assistance` (§22) |

**Note on S9 — harness portability.** The four skills separate cleanly into
a **harness-neutral core** (each skill's behaviour, invariants, and
dependencies — the substance already stubbed in `skills/*/SKILL.md`) and a
**harness-specific envelope** (the front-matter schema, file layout, and
discovery mechanism a given agent harness expects). Only the envelope changes
between harnesses, so the plan is to author the core once and adapt outward:

- **OpenCode** — the primary/reference implementation; `skills/*/SKILL.md`
  with OpenCode skill front-matter (already scaffolded).
- **Claude Code** — near-mechanical port: subagents (`.claude/agents/*.md`)
  for the agent-shaped skills (`compass-author`, `compass-review`) and slash
  commands (`.claude/commands/*.md`) for the command-shaped ones
  (`compass-lookup`), differing from OpenCode only in front-matter keys and
  directory location.
- **Cursor / Copilot** — the prompt-shaped harnesses: an Compass ruleset
  (`.cursor/rules/*.mdc`) or instructions file injects the standard's
  conventions as context; the callable-helper behaviours are reshaped to
  each harness's model.
- **MCP (Model Context Protocol)** — the portable layer for the *tool-shaped*
  skills (`compass-lookup`, `compass-derive`), exposed as an MCP server so any
  MCP-compatible host consumes them uniformly; the *prompt-shaped* skills
  (`compass-author`, `compass-review`) stay harness-specific.

The Plan owns the neutral core plus adapters (or generators) per target;
adaptation cost is low for Claude Code, moderate for Cursor/Copilot and for
the MCP tool server. The "propose vs. dispose" invariant (§22) holds across
all harnesses: each envelope calls the same §22 toolchain for conformance.

### Partially resolved

Addressed to some degree, with residue explicitly named.

| # | Area | Residue |
|---|---|---|
| P1 | Maturity-ladder genre ambiguity | Identity is now stable across genre changes (§5), but the "which genre?" choice at authoring time can still bikeshed |
| P2 | Provenance disclosure depth | `provenance` (§7) and `approved-by` (§6) cover the basics; model-version, prompt captures, and human-review attestation are not specified |
| P3 | Retention and archival policy | `Deprecated` / `Superseded-by` exist (§6); no explicit pruning or cold-storage policy |
| P4 | Genre proliferation | Managed by the §13 amendment gate and by preferring subtypes over new genres; not actively shrunk |

### Open by design

Accepted non-goals; recorded here so their status is not forgotten and so a
future proposal to bring them in-scope has a clear starting point.

| # | Area | Rationale |
|---|---|---|
| D1 | Regulatory / compliance controlled-document regimes | §2 non-goal; use domain frameworks |
| D2 | Auto-generated API reference at scale | §2 non-goal; integration seam via `Ref` |
| D3 | Release notes and changelogs | §2 non-goal; per-release append artifacts |
| D4 | Runbooks, on-call, incident postmortems | §2 non-goal; distinct operational lifecycles |
| D5 | Requirements specification and traceability matrices | §2 non-goal; `D`/`O` registers are not a requirements register |
| D6 | Knowledge-base / support / FAQ content | §2 non-goal |
| D7 | DITA-style single-sourcing / transclusion | §2 non-goal; §21 gives limited cross-audience reuse |
| D8 | Three-tier scope (`component`/`project`/`program`) rigidity | Accepted simplification; larger organizations may need extension |

### Genuinely open

Real gaps not yet addressed. These are the candidate inputs for future
Plans, in priority order.

| # | Area | Note |
|---|---|---|
| O1 | Monolithic document granularity vs. modular authoring | Docs are whole files; no include mechanism for source documents; hard to reuse and hard to review in small diffs. Fixture compilation (S7) partially addresses this for derived fixtures like READMEs, but not for source-to-source transclusion, which remains a non-goal per §2. |
| O2 | Bus factor / niche-tech adoption risk | Inherent to a bespoke standard bound to a Common Lisp platform; mitigable only by ecosystem uptake and honest disclosure |
| O3 | End-user documentation as a first-class output | Seamed by §21 and tracked as S5, but not solved: user-doc derivation is a large body of work. Prior-art notes to seed the Plan appear after this table. |
| O4 | Reviewer capture from forge PR data | `reviewers` is currently hand-maintained; harvesting from GitHub/GitLab PR review data is a plausible extension, unspecified |
| O5 | Multi-persona audience axis | `audience: developer \| end-user \| both` (§21) may need to become a small vocabulary (administrator, integrator, end-user) rather than three fixed values |
| O6 | Draft-to-canonical ID assignment ergonomics | §13 specifies steward-at-merge; needs a tooling ergonomic that isn't friction at the moment of accept |

### Prior-art notes for O3 (user-doc derivation)

Non-normative context for the future `COMPASS-DRAFT-user-doc-derivation` Plan
(§21, S5). The pattern of *developer-authored source → derived end-user
output* has recurring prior art in five traditions; the Plan should draw
from all of them rather than reinvent any.

**Filtering from a structured source.** The most mature line. **DITA** with
**ditaval** conditional filtering (`@audience`, `@product`, `@platform`) is
the industry reference at enterprise scale (IBM, Oracle, Cisco). **Doxygen**
`\internal` and Linux kernel-doc gate blocks by build. **Sphinx** `only::`
directives with tagged builds are the mid-scale open-source equivalent (Read
the Docs, OpenStack). **Antora**'s component/version/role model is the
closest off-the-shelf tool to the §21 sketch. The recurring lesson: filtering
belongs at *build* time driven by *declarative* metadata, never by branching
source files.

**Structured source with heavy transformation.** Cases where derivation is
real but the writer-in-the-loop is explicit. **Kubernetes** — KEPs (roughly
`Plan` + `Arch` in Compass terms) plus auto-generated API reference feed
writer-curated concept/task/tutorial pages under a formal Diátaxis split.
**Rust** — `rustdoc` reference is generated; the *Book* and *Rust by Example*
are hand-authored but rely on `rustdoc`-linkable ids for cross-references.
**Django** — the project that motivated **Diátaxis** as an articulated
framework (Procida works there); partial reference generation with
hand-authored quadrants. **PostgreSQL** — one repository, developer-authored
DocBook, tutorial/admin/reference living side by side with shared internal
ids.

**Literate programming and one-source-many-audiences.** Knuth's **WEB** and
**CWEB** (compiled program plus typeset book from one source). **Docco** and
its descendants (side-by-side prose-and-code). **Jupyter Book** and
**org-mode Babel** (executable notebooks rendered to both reference and
tutorial). Directly relevant in the Lisp lineage: **mgl-pax** — docstrings +
narrative, cross-referenceable, in one image — architecturally the same
"one source, multiple readerships" move Classic and Lexis assume.

**Docs-as-code with explicit curation.** The framing closest to §21's
"derivation plus curation." **GitLab**'s Handbook and product docs — engineering
material curated by writers into user-facing pages, Markdown in Git
throughout. **Stripe** — API reference generated from an internal spec;
tutorials and guides hand-authored against a shared terminology dictionary
and code-sample snippet library. **Divio**'s Diátaxis-in-practice writeups —
not a system but a documented workflow of the same reshaping. The lesson
across these: a shared terminology map is the single most load-bearing piece
of infrastructure, and it must be first-class rather than an afterthought.

**LLM-adjacent (emerging, thinly-formalized).** Documentation increasingly
serves two audiences at once: human readers and LLM assistants consuming it
as context. **Retrieval-augmented** docs from LangChain, Anthropic, and the
OpenAI cookbook are authored with ingestion in mind; consistent structure,
stable ids, cross-references, and typed metadata materially improve LLM
behaviour — exactly what Compass produces as a byproduct of §§5–9. Nascent
conventions such as **`llms.txt`** surface LLM-friendly summaries. IDE-side
tooling (**Cursor Rules**, **Continue.dev**) consumes project docs as
context, with anecdotal evidence that well-structured corpora yield
substantially better assistant behaviour. No rigorous account of
"documentation as LLM context" has yet been published; the Plan is
well-positioned to be one.

**Cross-cutting patterns worth naming in the Plan.**

1. **Metadata-driven filtering beats source branching** — DITA, Doxygen,
   Sphinx, and Antora converged here independently.
2. **A shared terminology map is load-bearing** — Stripe, Kubernetes, and
   PostgreSQL all treat glossaries as first-class infrastructure; Compass's
   `Glossary` genre is positioned for this role.
3. **Derivation seeds, writers finish** — every successful example
   acknowledges the writer in the loop; the ones that attempted full
   automation failed on register and voice.
4. **Cross-reference stability is what enables multi-audience output** —
   KEP ids, `rustdoc` anchors, Stripe operation ids all play the role of
   Compass's permanent `<NAMESPACE>-<NNNN>` (§5).
5. **LLM-as-consumer is a real design goal, not an afterthought.** A typed
   corpus serves *three* consumers of one well-typed source: end users, LLM
   coding assistants, and LLM user-task assistants. Designing for
   derivation designs for all three simultaneously; designing for
   independent authoring designs against LLM consumption by default. The
   semantic grounding of §17 was already designed for machine consumption
   (by Classic) and generalizes cleanly to LLM consumption. Prior art here
   is thin; this is the frontier the Plan is positioned to articulate.

**Derivation vs. independent authoring: when each wins.** Independent
authoring is dominant across the industry — Microsoft, Apple, and most SaaS
companies with dedicated writer teams treat user docs as an independent
track. Partial derivation is nearly universal at the reference layer
(rustdoc, Javadoc, Doxygen, OpenAPI generators); almost no serious project
hand-writes an API reference. Full audience-projection derivation is
uncommon — DITA-ditaval enterprise shops and Kubernetes-shaped KEP+writer
workflows are the notable examples. Docs-as-code with light derivation
(GitLab, Stripe) is the modern trend. LLM-shaped derivation is emerging and
largely uncodified.

*Derivation wins for:* small and medium teams without dedicated writers;
rapidly-evolving APIs where drift risk is highest; teams using LLM
assistance in development or documentation; projects where a single
semantic graph across readerships is valuable (Classic's target case).

*Independent authoring still wins for:* consumer products with heavy
voice/UX requirements; regulated environments where user docs are audited
artifacts; large writer organizations with independent editorial
infrastructure; heavy-localization workflows where an intermediate
normalized form is needed anyway.

The honest bottom line: derivation from typed dev docs is undervalued today
mainly because typed dev docs are themselves rare. Compass changes the
calculus — once dev docs are structured, derivation becomes cheap enough
that independent authoring becomes hard to justify for the small-to-medium
team case, especially under LLM-assisted development.

These notes are context for the Plan, not the Plan itself. The concrete
projection rules, curation refresh semantics, terminology mapping, and
product-namespace governance remain the subject of `COMPASS-DRAFT-user-doc-
derivation` (§21).


---

*Compass is itself a `program`-scope document and should carry front-matter
and the identifier `COMPASS-0001` once the standard is adopted; it is
presented here without front-matter as the defining instance of the scheme
it describes.*
