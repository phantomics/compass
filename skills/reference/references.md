# Compass references, registers, and accessibility rules

Extracted from `Compass.md` §8 (registers), §9 (references/citations), §12
(author-time accessibility), §13 (allocation). Derived reference data;
`Compass.md` is the source of truth.

## Cross-cutting registers (§8)

A record is defined by a level-3 heading, `### <ID> — <title>`: the full
identifier, an em dash, and the title. In a document without a number, records
carry provisional identifiers formed from the host's,
`<NAMESPACE>-DRAFT-<slug>-D<n>` (§13). Never write a short heading such as
`### D16 — …`; `compass check` warns on it (`register/heading-form`).

Refer to a record by its full identifier everywhere, never by a short form
such as `D6`: a short form changes meaning when the records are numbered, and
`compass check` warns on one (`ref/short-record`).

### Decision records (`D`)

One architectural/design decision, ADR-shaped, with a namespaced id
`<NAMESPACE>-D<n>` (e.g. `PSYCHE-D16`). Shape wherever it appears (in a `Plan`,
`Arch`, or `Log`):

```
### PSYCHE-D16 — 64-bit datapath with 8-bit shadow tags

**Status:** Accepted
**Context:** …the problem and forces…
**Decision:** …what was chosen…
**Alternatives:** …what was rejected, and why…
```

The `decisions:` front-matter field lists the IDs a document introduces or
amends. IDs are stable and namespaced, so one document may cite another's `D`.

### Open-question records (`O`)

A known unresolved issue, id `<NAMESPACE>-O<n>` (e.g. `ORIGIN-O9`). Appears under
`## Open Questions` and is listed in `open-questions:`. Cross-referable across
repositories.

### Memo records (`M`)

One durable, verified property of existing software, id `<NAMESPACE>-M<n>`
(e.g. `CLASSIC-M3`). M-records appear **only** in `Memo` documents, which hold
**only** M-records, under a single `## Memos` section in identifier order. The
host lists them in `memos:`, mirrored against the body.

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
| `**Status:**` | yes | `Draft`, `Current`, `Deprecated`, or `Superseded` |
| `**Read-if:**` | yes | When the memo matters, within 160 characters |
| `**Basis:**` | yes | A commit-pinned code reference, Compass identifier, or `cites:` title, then how it was established |
| `**Recorded:**` | no | `YYYY-MM-DD` |
| `**Superseded-by:**` | with `Superseded` only | The successor's identifier |

Keep the heading a claim about the system and the body under about 200 words,
in the present tense.

## Document-to-document references (§9)

Use a Markdown link keyed on the target's `id`:

```markdown
See [PSYCHE-0002](../psyche/Eval.AetherOS-Psyche.md) for the comparison.
```

Mirror the relationship in front-matter (`relates-to`, `supersedes`,
`superseded-by`). **Prose-only mentions of another document (naming it without a
link) are not conformant references.** Ancestor corpora link to old prefixes
(`DevLog.`/`DevPlan.`); normalize to current filenames and id-keyed links.

## Code references (§9)

Must be **pinned to an immutable revision**. A bare line number as the sole
anchor is prohibited. Form:

```
`[<NAMESPACE>:]<path>[:<symbol> | #L<start>[-L<end>]]@<revision>`
```

- `<path>` — repository-relative path.
- `<symbol>` — function/class/definition name; **preferred** anchor (survives
  line drift).
- `#L<start>-L<end>` — optional line range for extra precision.
- `<revision>` — REQUIRED: an immutable commit SHA (short or full), or a release
  tag for a `Ref`/`Spec` describing a shipped version.
- `<NAMESPACE>:` — prepend for a cross-repository reference.

Examples:
```markdown
The stop protocol lives in `src/managed-process.lisp:stop-process@a1b3f9c`.
See `ORIGIN:src/managed-process.lisp#L233-L248@a1b3f9c`.
```

Prefer a symbol anchor; add a line range only for precision. Commit-pinned
references are **mandatory in `Log` and `Plan`**, recommended elsewhere. A
renderer MAY expand a code reference into a forge permalink at that commit.

## Foreign citations (§9)

References to material outside the corpus go in `cites:`, each with `title`,
`locator`, and `external: true`. They are NOT Markdown links into the repository.
Program-altitude `Eval`/`Arch` documents leaning on many foreign sources SHOULD
carry a **source-map appendix** (a table pairing each section with its primary
sources).

## Author-time accessibility (§12) — MUST rules

An Compass document MUST:
- provide non-empty **alt text** for every image (`![alt text](…)`);
- provide a **text-equivalent long description** for every diagram: a
  paragraph beginning `Description:` immediately after it. A diagram is a
  fenced block tagged `mermaid`, `plantuml`, `dot`, `graphviz`, or `lexis` (§11);
- give every table **header cells and a caption**: a paragraph
  `Table: <caption>` immediately before the table;
- use **heading levels that nest without skipping** (no h2 → h4 jump);
- use **meaningful link text** — the linked `id` or a descriptive phrase, never
  "click here" or a bare URL;
- declare a **`language`** (BCP-47) in front-matter, and mark inline spans in
  another language.

## ID allocation discipline (§13)

- Each namespace's allocations are recorded in an append-only **ledger**,
  `REGISTRY.sexp` in the document directory of the repository that owns it. It
  holds only facts fixed at allocation (identifier, kind, the provisional
  identifier replaced, path or host, date, allocator), and is the authority
  for which numbers are taken. Titles and statuses stay in front-matter; the
  generated `INDEX.md` joins the two. Never edit the ledger by hand.
- A document under construction uses a **provisional** `<NAMESPACE>-DRAFT-<slug>`
  identifier (no coordination needed). Its records use
  `<NAMESPACE>-DRAFT-<slug>-D<n>`, `-O<n>`, `-M<n>`, with `<n>` counting within
  the host.
- The namespace steward assigns the canonical numbers at acceptance/merge, in
  one change: the document's `<NAMESPACE>-<NNNN>` and each provisional record's
  `<NAMESPACE>-D<n>`/`-O<n>`/`-M<n>`, with references rewritten and the ledger
  appended (`compass assign`; see `toolchain.md`). A memo record still `Draft`
  keeps its provisional identifier until a person moves it to `Current`.
- The ledger keeps each provisional identifier as an alias, so a reference
  still written with it resolves, with a `ref/stale-alias` warning.
- Identifiers are permanent and never reused. A re-homed document is re-minted in
  the new namespace with a `superseded-by` redirect from the old id. Retired
  records keep their identifier and their place.

## Naming and layout (§10)

Files are `<Genre-Prefix><Topic>.md` (e.g. `Log.StopFlag.md`, `Arch.Psyche.md`).
Within a repo the `doc/` directory is **flat**; grouping is expressed by the
`component:` front-matter field (the single source of truth for grouping), not by
subdirectory. Subdirectories, if present, are convenience only. Each
repository's generated `INDEX.md` is verified by `compass index --check`; the
federated `compass/INDEX.md` aggregates the namespaces' indexes.
