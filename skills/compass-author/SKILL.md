---
name: compass-author
description: Scaffold and draft Compass documents. Use when creating a new Survey, Eval, Plan, Log, Ref, Guide, Spec, Arch, Glossary, or Memo document in a Compass corpus — prompts for genre, scope, and namespace, generates the YAML front-matter block and per-genre section skeleton from templates/, and assigns a provisional DRAFT identifier.
---

# compass-author

Drafting and scaffolding skill for the Compass documentation standard (the S9
authoring-assistance layer; see `Compass.md` §22 and §23 S9, tracked as
`doc/Plan.AuthoringAssistance.md`). It turns a request like "start a Log for the
stop-flag work" into a conformant document skeleton the author then fills in.

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

## Reference material

Read these from the shared bundle as needed; do not re-derive rules from memory:

- `../reference/vocabularies.md` — genres, subtypes, scopes, statuses (§4/§5/§6).
- `../reference/frontmatter.md` — the §7 schema, required fields, id allocation.
- `../reference/section-shapes.md` — the §14 spine + optional ancestral sections.
- `../reference/references.md` — §8 `D`/`O` records, §9 reference rules, §12 a11y.

The per-genre templates live in `../../templates/<Genre>.template.md`.

## Workflow

1. **Determine the genre.** Ask, or infer from the request, then confirm. Map to
   the `genre:` value and file prefix in `vocabularies.md`. If the content does
   not clearly fit one genre, name the closest two and let the user choose
   (the maturity ladder in §4 helps: Survey → Eval → Plan → Log → Ref/Guide/Spec).

2. **Gather the required facets.** You need: `genre`, `scope`
   (`component|project|program`), `namespace` (e.g. `ORIGIN`, `PSYCHE`,
   `COMPASS` — ask if unknown; see `frontmatter.md`), `title`, and a short
   `slug` for the provisional id. For `Eval`/`Guide`, also get the `subtype`.
   For reference genres, get `api-version` (`Ref`/`Guide`) or `schema-version`
   (`Spec`).

3. **Copy the template.** Start from `../../templates/<Genre>.template.md`. Keep
   the §14 section spine and its order. Offer the optional (ancestral) sections
   where they fit the work; delete unused optional sections and their
   `<!-- optional -->` guidance comments.

4. **Fill the front-matter (§7).**
   - `id: <NAMESPACE>-DRAFT-<slug>` (provisional; the steward assigns the
     canonical `<NAMESPACE>-<NNNN>` at merge — never invent a serial number).
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
     rather than leaving `~`.
   - **Never set `approved-by`, `reviewers`, or `reviewed`, and never set an
     authoritative status** (`Accepted`, `Design-Record`, `Current` on a
     record or reference document). A person does that (§6).

5. **Seed genre-specific content.**
   - `Log` — seed the Files table from `git diff --stat` (or `git status`) of
     the work in progress, mapping added files to `**New**` and changed files to
     `Modified`. Remind the author that code references in a Log MUST be
     commit-pinned (§9): `path:symbol@revision`.
   - `Survey`/`Plan` — seed a Prior Art / Relationship-to-Other-Work stub and,
     if the user names comparable systems, list them; suggest running
     `compass-lookup` to find related in-corpus documents to link by id.
   - `Plan`/`Arch`/`Log` — scaffold any `D`-records in the §8 ADR shape
     (`Status`/`Context`/`Decision`/`Alternatives`) and mirror their ids into
     `decisions:`. Scaffold `O`-records for `Plan`/`Arch` and mirror into
     `open-questions:`. Use provisional `<NAMESPACE>-D<n>`/`-O<n>` numbers and
     flag that final numbers come from the registry (§13).
   - `Eval` — set `subtype`; scaffold Method / Shared Scenario / Rubric.
   - `Memo` — add one M-record per durable property under `## Memos`, with
     status `Draft` and a provisional `<host-id>-M<n>` (next unused `<n>` in the
     host), and mirror it into `memos:`. Before writing, check the four
     admission tests (§4) and tell the user which each memo passes and why:
     durable, consequential, not evident from the code or an existing document,
     and grounded. Write a `**Basis:**` with a commit-pinned reference
     (`path:symbol@revision`), a Compass id, or a `cites:` title, then how the
     property was established; without one, do not propose the memo. Write the
     heading as a claim and the body in the present tense, under about 200
     words. If the knowledge is a single file's rule, suggest a source-header
     `Invariant:` instead; if it is a choice between alternatives, a `D`-record.
   - `Ref`/`Guide`/`Spec`/`Glossary` — follow the attested shapes in
     `section-shapes.md` (Ref: layered API + Project Structure; Guide: choose
     tutorial vs howto body; Spec: Required… + Afterword, RFC-2119 uppercase;
     Glossary: Canonical Terms + Backronym Registry).

6. **Apply author-time accessibility (§12).** Any table gets header cells and a
   caption; any diagram gets a text-equivalent description; headings nest
   without skipping; links use id or descriptive text, never bare URLs.

7. **Place the file.** Name it `<Genre-Prefix><Topic>.md` in the corpus's flat
   `doc/` directory (§10). Confirm the path with the user before writing.

8. **Report advisory status.** State that the scaffold is unvalidated (see
   Invariants) and suggest `compass-review` before acceptance and, once it
   exists, the §22 toolchain.

9. **Offer the AGENTS snippet (first document in a corpus).** When scaffolding a
   project's *first* Compass document, offer to install
   `../../templates/AGENTS.snippet.md` (the Compass documentation block) into the
   project's root `AGENTS.md`, so a fresh OpenCode session routes doc work to the
   `compass-*` skills. If the project has no `AGENTS.md`, create it from the
   snippet; if one exists, **append** the Compass section rather than
   overwriting. Fill the project-specific facts (namespace, `doc/` location,
   federation index). If the project also uses the Square testing standard,
   `square-author` installs the matching testing block; the two sections
   concatenate in one `AGENTS.md`.

## Invariants

- This skill **proposes**; the §22 toolchain **disposes**. Until
  `COMPASS-DRAFT-toolchain` exists, operate in **advisory-only mode**: apply the
  standard as best-effort guidance and tell the user the output is not yet
  validated for conformance. Do not claim a document "conforms".
- Never invent a canonical `<NAMESPACE>-<NNNN>` identifier or a registry entry;
  provisional `DRAFT` ids only (§13).
- Never write derived Git fields back into the file (§7).
- Always set `provenance:` when you author or modify a document (§7, §22).
- `Ideation` documents are authored by hand with no template and only as a
  considered editorial act (§4); do not scaffold routine transcripts as Compass
  documents (§2).
