---
name: compass-lookup
description: Resolve identifiers, sections, decisions, open questions, memos, and cross-references across a federated Compass corpus with the compass toolchain. Use to answer "show me PSYCHE-D16", "what refers to CLASSIC-0003?", "list ORIGIN open questions", or "give me the current LEXTER index" during authoring or review.
---

# compass-lookup

Corpus-aware retrieval skill for the Compass documentation standard (the S9
authoring-assistance layer; see `Compass.md` §22 and §23 S9, tracked as
`doc/Plan.AuthoringAssistance.md`). It answers questions about a Compass corpus
with the `compass` command — read-only, making no changes. It is the retrieval
companion `compass-author` and `compass-review` lean on to link and verify
cross-references.

## When to use

Use to **resolve or search** within one or more Compass corpora:
- resolve a document `id` or a section anchor to its content (§5, §9);
- resolve a `D`, `O`, or M record by id, with its host document (§8);
- relationship queries: what a document `relates-to`/`supersedes`/`cites`, and
  inbound references (what points *at* a given id) (§9, §10);
- list a namespace's documents and records (§13, §10).

Do **not** use to create (`compass-author`), review (`compass-review`), or derive
(`compass-derive`) documents.

## Using the toolchain

This skill runs the `compass` command; `../reference/toolchain.md` has the
details. In short:

1. **Find it:** `compass` on the `PATH`, else `../../bin/compass` from this
   skill's directory. If neither exists, say the toolchain is unavailable, name
   the fix (`make install` in the Compass repository), and continue without it
   as described under [Without the toolchain](#without-the-toolchain).
2. **Once per session**, run `compass help` and use only the commands it lists.
3. **Exit codes:** 0 is success; 1 means the identifier is not defined (for
   `refs`, neither defined nor referenced); 2 is a usage or internal error to
   report, not to retry unchanged; 141 means the output was cut off by a pipe.
4. **Read only.** Never run a command that writes; preview the index with
   `compass index --stdout`.

## Reference material

- `../reference/toolchain.md` — the commands, their output, and other
  repositories.
- `../reference/frontmatter.md` — the §7 fields (`id`, `relates-to`,
  `supersedes`, `superseded-by`, `cites`, `decisions`, `open-questions`, `memos`)
  and the identifier format (§5, §13).
- `../reference/references.md` — the §8 record shapes and the §9 link and
  code-reference grammar.
- `../reference/vocabularies.md` — for filtering by genre, scope, status.

## How to resolve

Identifiers may be canonical (`ORIGIN-0012`, `ORIGIN-D30`) or provisional
(`ORIGIN-DRAFT-foreign-orbitals`, `ORIGIN-DRAFT-foreign-orbitals-D2`) (§13);
every command takes both.

1. **A document.** For anything long, start with `compass outline <ID>`: it
   gives the path, title, genre, status, the front-matter's line range, and each
   section's anchor and line range. Then print only what is needed with
   `compass show <ID>#<anchor>`, or the whole document with `compass show <ID>`.
2. **A section.** `compass show <ID>#<anchor>`. `compass outline <ID>#<anchor>`
   lists its subsections.
3. **A record** (`D`, `O`, or M). `compass show <RECORD-ID>` prints the record
   alone; `compass outline <RECORD-ID>` outlines its host and names the
   record's anchor.
4. **Outbound relations.** Read the subject's front-matter (the first lines of
   `compass show <ID>`, up to the line `outline` gives as its end):
   `relates-to`, `supersedes`, `superseded-by`, `glossary`, `decisions`,
   `open-questions`, `memos`, and `cites`. Report `cites` entries (external,
   outside the corpus) separately from in-corpus references (§9). Body links
   are in the document's text.
5. **Inbound references.** `compass refs <ID>` (or `<ID>#<anchor>` for a
   section) lists, grouped by kind, every front-matter relation, register
   listing, link, memo basis, and prose mention that points at it, each with
   its path and line. Use `--format json` to process the results.
6. **A namespace.** `compass index --stdout --namespace <NS>` prints its
   documents (id, title, genre, scope, status, component) and its records (id,
   kind, title, status, host). Filter those tables to answer faceted questions,
   such as all open questions, or all `Draft` Plans of a component. For facets
   the index does not carry (authors, dates), read the documents' front-matter.
7. **"What number comes next?"** `compass next <NS> --kind <kind>` answers, but
   only as an estimate: until the ledger exists (toolchain version 0.2), it
   cannot see numbers allocated on other branches. Say so.

## Other repositories

A repository's `compass.sexp` lists the repositories it federates with:

```lisp
:federation ((:namespace "ORIGIN" :path "../origin"))
```

For an identifier in another namespace, run the same command in the
repository that owns it: `compass show ORIGIN-0012 --root <path>`, with the
path taken relative to the directory holding `compass.sexp`. For inbound
references across repositories, run `compass refs <ID> --root <path>` in each
federated repository and combine the results. If no entry names the namespace,
ask the user where its repository is.

## Output

- Lead with a direct answer: the resolved content, record, or list.
- Cite each result by `id` and by `path:line`, so the user can navigate (§9).
- For relationship queries, group results by kind, as `refs` does.
- State the scope searched (this repository, or which federated repositories)
  and anything unresolved: an identifier that is not defined, a namespace with
  no repository, references `compass check` counts as unverified.

## Without the toolchain

If no executable is found, work from the files and say the answer was not
produced by the toolchain:

1. Find the document directory in `compass.sexp` (`:doc-directory`, default
   `doc/`). Map identifiers to files by searching for `^id:` in the front-matter
   of its `.md` files and of `.md` files at the repository root.
2. Find a record by its heading, `### <ID> — <title>`, outside fenced code.
3. Find a section by its heading, computing GitHub's anchor (lowercase; keep
   letters, digits, hyphens, underscores, and spaces; spaces become hyphens).
4. Find inbound references by searching for the identifier, and for links to
   the target's file; a search misses links whose text is not the identifier.

## Invariants

- **Read-only** over the corpus; make no changes.
- Use the toolchain's answers rather than reparsing documents; fall back to
  searching only when no executable is found.
- Report honestly when data is absent: many namespaces have no repository on
  this machine, and most documents still carry provisional identifiers. Never
  invent an identifier or an entry.
