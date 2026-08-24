---
name: compass-lookup
description: Resolve identifiers, decisions, open questions, and cross-references across a federated Compass corpus. Use to answer "show me PSYCHE-D16", "what cites CLASSIC-0003?", "list ORIGIN open questions", or "give me the current LEXTER index" during authoring or review.
---

# compass-lookup

Corpus-aware retrieval skill for the Compass documentation standard (the S9
authoring-assistance layer; see `Compass.md` §22 and §23 S9, tracked as
`doc/Plan.AuthoringAssistance.md`). It answers questions about a Compass corpus
by reading front-matter and body structure — read-only, making no changes. It is
the retrieval companion `compass-author` and `compass-review` lean on to link and
verify cross-references.

## When to use

Use to **resolve or search** within one or more Compass corpora:
- resolve a document `id` or a section anchor to its content (§5, §9);
- resolve a `D`/`O` register entry by id to its host document (§8);
- relationship queries: what a document `relates-to`/`supersedes`/`cites`, and
  inbound backlinks (what points *at* a given id) (§9, §10);
- list a namespace's registry/INDEX or the federated master `INDEX.md` (§13, §10).

Do **not** use to create (`compass-author`), review (`compass-review`), or derive
(`compass-derive`) documents.

## Reference material

- `../reference/frontmatter.md` — the §7 fields you parse (`id`, `relates-to`,
  `supersedes`, `superseded-by`, `cites`, `decisions`, `open-questions`, …) and
  the identifier format (§5, §13).
- `../reference/references.md` — the §8 `D`/`O` record shape, the §9 link and
  code-reference grammar, and the §10 flat-`doc/` layout.
- `../reference/vocabularies.md` — for filtering/faceting by genre, scope, status.

## The corpus and federation manifest

A Compass corpus is one or more repositories, each with a flat `doc/` directory
(§10) and a local registry/index; `compass/INDEX.md` federates them (§10, §13).

To span repositories, honour a **federation manifest** — the same input an S8
site build would use — if one is present (e.g. `compass/INDEX.md`, or a
`compass.federation` / `.compass/federation.*` file listing participating repo
paths). If no manifest exists, fall back to the current repository's `doc/`
directory, and ask the user for the paths of other repositories when a query
plainly needs them. State which scope you searched.

## How to resolve (no toolchain required)

Operate directly over files with `grep`/`glob`/`read`:

1. **Build the id→file map.** `grep` for `^id:` across `**/doc/*.md` (and any
   federated repos). Each match gives `id` → path. Cache within the session.
   Documents use provisional `<NS>-DRAFT-<slug>` ids until a steward assigns
   `<NS>-<NNNN>` (§13); resolve both forms.

2. **Resolve a document id.** Look it up in the map; `read` the file. For a
   section anchor (`<id>#<anchor>`), find the heading whose GitHub-style slug
   matches and return that section.

3. **Resolve a `D`/`O` id** (e.g. `PSYCHE-D16`, `ORIGIN-O9`). First check
   `decisions:`/`open-questions:` front-matter across the map to find the host
   document, then locate the `### <ID> — …` heading (§8) and return the record.

4. **Relationship queries.**
   - *Outbound:* read the subject's `relates-to`/`supersedes`/`superseded-by`/
     `cites` and its inline id-links.
   - *Inbound (backlinks):* `grep` the corpus for the target id in other
     documents' front-matter and body links.
   - Report `cites` entries (foreign, `external: true`) separately from in-corpus
     links (§9).

5. **List a registry / index.** Summarize a namespace by collecting every
   document whose id has that namespace prefix, with `title`, `genre`, `scope`,
   `status`. Present it as the registry view (§13). For the federated view,
   aggregate across the manifest, or read `compass/INDEX.md` if present.

6. **Faceted search.** Filter/group by any front-matter facet (genre, scope,
   status, component, project, author, date) per the search targets in §16.

## Output

- Lead with a direct answer (the resolved content, record, or list).
- Cite each result by `id` and file path so the user can navigate (§9).
- For relationship/backlink queries, group results by relationship type.
- State the search scope (this repo vs. federated) and note anything unresolved
  (dangling ids, missing manifest, empty namespace).

## Invariants

- **Read-only** over the corpus; make no changes.
- Prefer the same front-matter parsing the §22 toolchain performs; once the
  toolchain/importer exists, call it rather than reimplement parsing. Until then,
  `grep`/`glob`/`read` is the sanctioned fallback.
- Report honestly when data is absent: many namespaces have no registry or
  `INDEX.md` yet, and most current documents predate id assignment. Say so
  rather than fabricating ids or entries.
