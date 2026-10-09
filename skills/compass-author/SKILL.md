---
name: compass-author
description: Scaffold and draft Compass documents. Use when creating a new Survey, Eval, Plan, Log, Ref, Guide, Spec, Arch, Glossary, or Memo document in a Compass corpus — determines genre, scope, and namespace, generates the YAML front-matter block and per-genre section skeleton from templates/, assigns provisional DRAFT identifiers, and checks the draft with the compass toolchain.
---

# compass-author

Drafting and scaffolding skill for the Compass documentation standard (the S9
authoring-assistance layer; see `Compass.md` §22 and §23 S9, tracked as
`doc/Plan.AuthoringAssistance.md`). It turns a request like "start a Log for the
stop-flag work" into a document skeleton the author then fills in, and checks
the result with `compass check`.

## When to use

Use when the user wants to **create a new Compass document** — any of the
eleven genres (§4) — or convert notes into one. Triggers include "new
Log/Plan/Survey…", "scaffold a Compass doc", "start an ADR/decision record",
"write up this work as a Log", "record this as a memo".

For a **memo**, first look for the component's existing `Memo.<Topic>.md` host
(hosts are divided by the project's major components) and add a record to it;
scaffold a new host only when the component has none.

Do **not** use to review an existing document (that is `compass-review`), to look
up ids or cross-references (that is `compass-lookup`), or to run derivation
pipelines (that is `compass-derive`).

## Using the toolchain

This skill runs the `compass` command; `../reference/toolchain.md` has the
details. In short:

1. **Find it:** `compass` on the `PATH`, else `../../bin/compass` from this
   skill's directory. If neither exists, say the toolchain is unavailable, name
   the fix (`make install` in the Compass repository), and continue without it
   as described under [Without the toolchain](#without-the-toolchain).
2. **Once per session**, run `compass help` and use only the commands it lists.
3. **Exit codes:** 0 is clean; 1 means findings, or an identifier that is not
   defined; 2 is a usage or internal error to report, not to retry unchanged;
   141 means the output was cut off by a pipe.
4. **Fix findings only in files this task created or changed**; report the
   rest.

## Reference material

Read these from the shared bundle as needed; do not re-derive rules from memory:

- `../reference/toolchain.md` — running `compass`, reading its findings, and
  what it does not check.
- `../reference/vocabularies.md` — genres, subtypes, scopes, statuses (§4/§5/§6).
- `../reference/frontmatter.md` — the §7 schema, required fields, id allocation.
- `../reference/section-shapes.md` — the §14 spine + optional ancestral sections.
- `../reference/references.md` — §8 `D`/`O`/M records, §9 reference rules, §12
  a11y.

The per-genre templates live in `../../templates/<Genre>.template.md`.

## Workflow

1. **Determine the genre.** Ask, or infer from the request, then confirm. Map to
   the `genre:` value and file prefix in `vocabularies.md`. If the content does
   not clearly fit one genre, name the closest two and let the user choose
   (the maturity ladder in §4 helps: Survey → Eval → Plan → Log → Ref/Guide/Spec).

2. **Gather the facets.**
   - **Namespace and document directory:** read the repository's `compass.sexp`.
     The namespace is the first entry of `:namespaces`; the document directory is
     `:doc-directory`, or `doc/` if absent. Without a manifest, ask for the
     namespace (e.g. `ORIGIN`, `PSYCHE`, `COMPASS`).
   - `scope` (`component|project|program`), `title`, and a short lowercase
     `slug` for the provisional id (letters and digits, single hyphens).
   - For `Eval`/`Guide`, the `subtype`. For reference genres, `api-version`
     (`Ref`/`Guide`) or `schema-version` (`Spec`).
   - Check that the slug is free: `compass show <NS>-DRAFT-<slug>` should exit 1.

3. **Copy the template.** Start from `../../templates/<Genre>.template.md`. Keep
   the §14 section spine and its order. Offer the optional (ancestral) sections
   where they fit the work; delete unused optional sections and their
   `<!-- optional -->` guidance comments.

4. **Fill the front-matter (§7).**
   - `id: <NAMESPACE>-DRAFT-<slug>`. It stays provisional; the steward assigns
     the canonical `<NAMESPACE>-<NNNN>` at merge (§13). Never write a canonical
     number, including one `compass next` suggests.
   - Set `title`, `genre`, `scope`, `language` (default `en`), `status`
     (`Draft` for new proposal/record genres; `Draft` for reference genres
     and new memo records; a new Memo host is `Current` while it is
     maintained), and the program/project/component grouping fields.
   - **Omit `authors`, `created`, `updated`** and let them derive from Git
     (§7), unless the user wants explicit values.
   - Set `provenance: { assistant: <this assistant> }` — required for
     LLM-assisted authoring (§7). Add `session:` if meaningful.
   - Only include optional fields (`relates-to`, `decisions`, `open-questions`,
     `memos`, `cites`, `glossary`) when they have real values; remove empty ones
     rather than leaving `~`. Relations and `glossary` name documents by id.
   - **Never set `approved-by`, `reviewers`, or `reviewed`, and never set an
     authoritative status** (`Accepted`, `Design-Record`, `Current` on a
     record or reference document). A person does that (§6).

5. **Seed genre-specific content.**
   - `Log` — seed the Files table from `git diff --stat` (or `git status`) of
     the work in progress, mapping added files to `**New**` and changed files to
     `Modified`. Remind the author that code references in a Log MUST be
     commit-pinned (§9): `path:symbol@revision`.
   - `Survey`/`Plan` — seed a Prior Art / Relationship-to-Other-Work stub and,
     if the user names comparable systems, list them. Find related documents in
     the corpus with `compass index --stdout` and `compass refs <ID>`, and link
     them by id.
   - `Plan`/`Arch`/`Log` — scaffold `D`-records in the §8 ADR shape
     (`Status`/`Context`/`Decision`/`Alternatives`), with status `Proposed`,
     and `O`-records for `Plan`/`Arch`. Give each a provisional identifier formed from the
     document's: `<NAMESPACE>-DRAFT-<slug>-D1`, `-D2`, …, and `-O1`, … (§13),
     with the full identifier in the heading (`### <ID> — <title>`). Mirror them
     into `decisions:` and `open-questions:`.
   - `Eval` — set `subtype`; scaffold Method / Shared Scenario / Rubric.
   - `Memo` — find the component's host among the documents of genre `Memo` in
     `compass index --stdout`, then read its records with
     `compass outline <host-id>` and `compass show <host-id>#memos`. Add one
     M-record per durable property under `## Memos`, with status `Draft` and the
     next unused provisional identifier in the host (`<host-id>-M<n>`), and
     mirror it into `memos:`. Recording a `Draft` memo needs no review: it
     reaches later sessions through the catalog, marked unreviewed. Leave it
     `Draft`; a person moves it to `Current`. Before writing, check the four
     admission tests (§4) and tell the user which each memo passes and why:
     durable, consequential, not evident from the code or an existing document,
     and grounded. Write a `**Basis:**` with a commit-pinned reference
     (`path:symbol@revision`), a Compass id, or a `cites:` title, then how the
     property was established; without one, do not propose the memo
     (`memo/basis` rejects it). Write the heading as a claim and the body in the
     present tense, under about 200 words. If the knowledge is a single file's
     rule, suggest a source-header `Invariant:` instead; if it is a choice
     between alternatives, a `D`-record.
   - `Ref`/`Guide`/`Spec`/`Glossary` — follow the attested shapes in
     `section-shapes.md` (Ref: layered API + Project Structure; Guide: choose
     tutorial vs howto body; Spec: Required… + Afterword, RFC-2119 uppercase;
     Glossary: Canonical Terms + Backronym Registry).

6. **Apply author-time accessibility (§12).** Any table gets header cells and a
   `Table:` caption line before it; any diagram gets a `Description:` paragraph
   after it; headings nest without skipping; links use id or descriptive text,
   never bare URLs. The toolchain does not check these yet.

7. **Place the file.** Name it `<Genre-Prefix><Topic>.md` in the document
   directory (§10). Confirm the path with the user before writing.

8. **Check it.**
   - First search the file for leftover `<…>` placeholders and fill or remove
     them. The toolchain does not flag placeholder text, and Markdown reads a
     placeholder such as `<decision title>` as an HTML tag: a record heading
     whose title is still a placeholder has no title, so the record is not
     recognised.
   - Run `compass check <path>`. Fix every error in the new file (or the host
     you added a memo to) and run the check again until it reports none. Typical
     causes are a placeholder left in front-matter (`fm/types`), a record listed
     but not defined or the reverse (`register/mirrored`), and a link whose file
     or anchor does not exist (`ref/doc-resolves`).
   - Fix warnings that point at mistakes, such as `fm/unknown-key` (a misspelt
     field) or `register/heading-form`. Leave `vocab/pending` warnings and
     report them (`../reference/toolchain.md`).
   - If the check exits 2 because the path "is not a document of this corpus",
     the file is in the wrong place: move it into the document directory.

9. **Regenerate the index.** If the document directory already has an
   `INDEX.md`, run `compass index` to regenerate it. Do not create one where
   none exists.

10. **Report.** Give the path and provisional id, the `compass check` result
    (errors and warnings for the new file, and the toolchain version), and what
    the toolchain does not check yet (`../reference/toolchain.md`). Suggest
    `compass-review` before acceptance.

11. **Offer the AGENTS snippet (first document in a corpus).** When scaffolding
    a project's *first* Compass document, offer to install
    `../../templates/AGENTS.snippet.md` (the Compass documentation block) into
    the project's root `AGENTS.md`, so a fresh OpenCode session routes doc work
    to the `compass-*` skills. If the project has no `AGENTS.md`, create it from
    the snippet; if one exists, **append** the Compass section rather than
    overwriting. Fill the project-specific facts (namespace, document
    directory, where `compass` is installed, federated repositories). If the
    project also uses the Square testing standard, `square-author` installs the
    matching testing block; the two sections concatenate in one `AGENTS.md`.

## Without the toolchain

If no executable is found, do steps 1–7 and 11, then:

- read the namespace and document directory from `compass.sexp` yourself, and
  find existing documents and memo hosts by searching front-matter
  (`grep -l "^genre: *Memo" <doc-dir>/*.md`);
- check the draft against `frontmatter.md` and `references.md` by hand;
- tell the user the draft has **not** been checked by the toolchain, and how to
  install it.

## Invariants

- This skill **proposes**; the §22 toolchain **disposes**, and a person accepts.
  Report what `compass check` found, never that a document "conforms" beyond
  it, and never that it is accepted.
- Never invent a canonical `<NAMESPACE>-<NNNN>`, `-D<n>`, `-O<n>`, or `-M<n>`
  identifier; provisional `DRAFT` ids only (§13).
- Never write derived Git fields back into the file (§7), and never edit a
  generated `INDEX.md` by hand.
- Always set `provenance:` when you author or modify a document (§7, §22).
- `Ideation` documents are authored by hand with no template and only as a
  considered editorial act (§4); do not scaffold routine transcripts as Compass
  documents (§2).
