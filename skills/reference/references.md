# Compass references, registers, and accessibility rules

Extracted from `Compass.md` §8 (registers), §9 (references/citations), §12
(author-time accessibility), §13 (allocation). Derived reference data;
`Compass.md` is the source of truth.

## Cross-cutting registers (§8)

### Decision records (`D`)

One architectural/design decision, ADR-shaped, with a namespaced id
`<NAMESPACE>-D<n>` (e.g. `PSYCHE-D16`). Shape wherever it appears (in a `Plan`,
`Arch`, or `Log`):

```
### D16 — 64-bit datapath with 8-bit shadow tags

**Status:** Accepted
**Context:** …the problem and forces…
**Decision:** …what was chosen…
**Alternatives:** …what was rejected, and why…
```

> **Pending amendment — heading form.** §8's example uses the short heading
> `### D16 — …`. COMPASS-DRAFT-toolchain-D16 requires the full identifier,
> `### PSYCHE-D16 — …` (or a provisional `### <NS>-DRAFT-<slug>-D<n> — …`), and
> the toolchain warns on the short form. The genre templates already use the
> full form; skills write it.

The `decisions:` front-matter field lists the IDs a document introduces or
amends. IDs are stable and namespaced, so one document may cite another's `D`.

### Open-question records (`O`)

A known unresolved issue, id `<NAMESPACE>-O<n>` (e.g. `ORIGIN-O9`). Appears under
`## Open Questions` and is listed in `open-questions:`. Cross-referable across
repositories.

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
- provide **alt text** for every image;
- provide a **text-equivalent long description** for every diagram (§11);
- give every table **header cells and a caption**;
- use **heading levels that nest without skipping** (no h2 → h4 jump);
- use **meaningful link text** — the linked `id` or a descriptive phrase, never
  "click here" or a bare URL;
- declare a **`language`** (BCP-47) in front-matter, and mark inline spans in
  another language.

## ID allocation discipline (§13)

- Each namespace keeps a checked-in **registry** (its local `INDEX`) listing
  every allocated id with current title, genre, scope, status. The registry is
  the authority for which numbers are taken.
- A document under construction uses a **provisional** `<NAMESPACE>-DRAFT-<slug>`
  identifier (no coordination needed).
- The namespace steward assigns the canonical `<NAMESPACE>-<NNNN>` at
  acceptance/merge, updating the registry in the same change.
- Identifiers are permanent and never reused. A re-homed document is re-minted in
  the new namespace with a `superseded-by` redirect from the old id.

## Naming and layout (§10)

Files are `<Genre-Prefix><Topic>.md` (e.g. `Log.StopFlag.md`, `Arch.Psyche.md`).
Within a repo the `doc/` directory is **flat**; grouping is expressed by the
`component:` front-matter field (the single source of truth for grouping), not by
subdirectory. Subdirectories, if present, are convenience only. The federated
`compass/INDEX.md` aggregates per-namespace registries.
