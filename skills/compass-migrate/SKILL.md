---
name: compass-migrate
description: Migrate one existing document, written before Compass, into a Compass corpus without changing its content — proposes its genre and title, moves it with git mv for the user to commit, then adds front-matter with provenance.migrated-from, the genre's section shape, decision records with provisional identifiers, and pinned code references, checks the result, and reports what it changed and what it noticed. Use when the user wants to "migrate", "convert", or "bring into Compass" a document that has no front-matter, in a repository already set up for Compass. It never revises the content, commits, splits a document, or sets an authoritative status.
---

# compass-migrate

Migration skill for the Compass documentation standard (the S9
authoring-assistance layer; see `Compass.md` §22 and §23 S9). It brings one
document written before Compass into the corpus, and changes only its form: the
content stays the original's, so that the document still records what its
author knew and decided at the time. It follows the decisions of
COMPASS-DRAFT-migration, the plan in the Compass repository
(`doc/Plan.Migration.md`), which are cited below by identifier.

## When to use

Use when the user asks to migrate, convert, or reshape an existing document
into Compass form: "migrate doc/spec.md", "bring the old design notes into
Compass", "what is left to migrate?". The repository must already be set up for
Compass, with a `compass.sexp`.

Do **not** use to set a repository up (`compass-adopt`), to write a new
document (`compass-author`), to review a document (`compass-review`), or to
update, correct, or split a document's content. Those come after the migration,
as ordinary edits (COMPASS-DRAFT-migration-D11).

## Using the toolchain

This skill runs the `compass` command; `../reference/toolchain.md` has the
details. In short:

1. **Find it:** `compass` on the `PATH`, else `../../bin/compass` from this
   skill's directory. If neither exists, say the toolchain is unavailable, name
   the fix (`make install` in the Compass repository), and continue without it
   as described under [Without the toolchain](#without-the-toolchain).
2. **Once per session**, run `compass help` and use only the commands it lists.
3. **Exit codes:** 0 is clean; 1 means findings, a refusal, or an identifier
   that is not defined; 2 is a usage or internal error to report, not to retry
   unchanged; 141 means the output was cut off by a pipe.
4. **Pass `--root <folder>`** when the repository is not the current directory,
   and add `--federation` to `compass check` when the document cites another
   repository.

## Reference material

Read these from the shared bundle as needed; do not re-derive rules from memory:

- `../reference/toolchain.md` — running `compass`, reading its findings, and
  the rules for numbers.
- `../reference/frontmatter.md` — the §7 fields, and `provenance.migrated-from`.
- `../reference/vocabularies.md` — genres, subtypes, scopes, and each genre's
  statuses (§4, §5, §6).
- `../reference/section-shapes.md` — each genre's §14 section spine.
- `../reference/references.md` — §8 records and §9 links and code references.
- `../../templates/<Genre>.template.md` — the spine and field order of each
  genre, as `compass-author` uses them.

## Before starting

Check each of these, and stop at the first that fails, saying why:

1. **The repository is set up.** `compass.sexp` exists. If not, the repository
   needs `compass-adopt` first.
2. **The baseline is clean.** `compass check --skip-unmarked` reports no errors,
   so that the errors after the migration are the migration's. If it reports
   errors, list them and stop: fixing them, such as giving colliding records
   provisional identifiers, is the steward's work before migration.
3. **The working tree is clean,** or holds only a rename of the document to be
   migrated. Check with `git status --short`. Ask the user to commit or set
   aside anything else, so that the move commit holds only the move.
4. **The repository's own migration plan.** Look for one: a Plan whose subject
   is the migration to Compass, or a document the `AGENTS.md` migration line
   names. If there is one, read its decisions. Where they differ from
   COMPASS-DRAFT-migration, the repository's decision applies (directory
   layout, pins, naming, statuses it leaves to the steward), and the report
   names each difference with both identifiers. It cannot relax this skill's
   [Invariants](#invariants): one document per request, form only, no commits,
   and no authoritative statuses. Where it calls for one of those, as a plan
   for batches would, say so and keep the invariant
   (COMPASS-DRAFT-migration-D10).
5. **The backlog record** (COMPASS-DRAFT-migration-D8). Count the documents
   still unmarked: `compass check --skip-unmarked --format json` lists them
   under `skipped`, and Markdown files outside the document directory may be
   more. If the repository keeps a migration Log, that Log is the record. If it
   does not, and more than three documents were unmarked when the first
   migration began, the record is a new `Log.CompassMigration.md`, which
   `compass-author` writes after the first reshape is committed, naming the
   commit the migration began from. Otherwise the record is the migration line
   in `AGENTS.md`.

## Workflow

One document per request (COMPASS-DRAFT-migration-D1). Propose each step's
changes, make them once the user confirms, and stop where the user must
commit.

### 1. Choose

- List the candidates: the files `compass check --skip-unmarked --format json`
  skipped, and Markdown documents elsewhere in the repository without
  front-matter. Leave out files that are not documents: `README.md`,
  `CHANGELOG.md`, `CONTRIBUTING.md`, `AGENTS.md`, licences, and generated files.
- Order them as COMPASS-DRAFT-migration suggests: documents that describe the
  current system first, then documents of past work, then the rest. Propose
  one, and let the user name the document.
- Read the whole original before proposing anything.

### 2. Classify

Propose, giving the reasons, and let the user confirm or correct:

- **Genre** from the document's role, not its filename (see
  [Choosing the genre](#choosing-the-genre)), with its subtype for an `Eval` or
  `Guide`. For a document that mixes genres, name the closest two; the user
  chooses one. Do not split it: report the mix, for an edit after the migration
  (COMPASS-DRAFT-migration-O1).
- **Scope**, **title**, the **namespace** (the first of `:namespaces` in
  `compass.sexp`), and a **slug** for the provisional identifier
  `<NS>-DRAFT-<slug>`. `compass show <NS>-DRAFT-<slug>` must exit 1, meaning
  the slug is free.
- **The original's revision**, for `migrated-from`: the last commit that changed
  it before the migration touched it (COMPASS-DRAFT-migration-D3). An earlier
  document's move may have updated a link in this one, and that commit does
  not count. Where the migration Log names the commit the migration began
  from, use `git log -1 --format=%h <that commit> -- <path>`. Otherwise list
  `git log --format=%h -- <path>`, newest first, and take the first commit that
  is not a migration move: one later than the commit that added `compass.sexp`
  (`git log --diff-filter=A --format=%h -- compass.sexp`) whose
  `git show --stat -M <commit>` shows another document renamed. Renames before
  adoption are the author's own, and count. If the user has already
  renamed it, read it through the rename, with `git log --follow`.
- **Records.** The original's decisions, numbered or not, and its open
  questions, with the identifiers they will take. Numbered ones keep their
  numbers: "Decision 3" becomes `<NS>-DRAFT-<slug>-D3`
  (COMPASS-DRAFT-migration-D6).
- **For a Spec, which chapters are normative.** For each chapter, give the
  evidence: the requirements its own text states (search for "must", "should",
  "may", "required", and "shall", ignoring case), or its role, such as defining
  conformance or a syntax. Chapters of guidance, examples, or description, and
  chapters that say a step may be skipped, are informative. The user decides
  which chapters are "Required" (COMPASS-DRAFT-migration-D2).
- **Cited section numbers** (COMPASS-DRAFT-migration-D9). Search the
  repository, and the federated repositories that are checked out, for
  citations of the document's sections by number, such as "§4.3" or "Section
  3.3" in documents, source comments, and tests. If any exist, the numbers stay.
- **The pin revision for code references** (COMPASS-DRAFT-migration-D5). For a
  Log, the commit that holds the work it records, found from its own account
  (commits, dates, and files it names) and the history of those files, and the
  commit before the work for code it describes as it was before. For every
  other genre, the `migrated-from` revision. Give the evidence.
- **Provenance** (COMPASS-DRAFT-migration-D3). Ask whether the original was
  written with an assistant, which one, and in which session. Record the
  assistant as `original-assistant:` (COMPASS-DRAFT-migration-O6), taking it
  from the transcript where there is one, and `session:` only when its
  transcript shows the original being written, not merely read or extended;
  otherwise leave each out.

### 3. Move

(COMPASS-DRAFT-migration-D4.)

- **The new path:** `<doc-dir>/<Genre-prefix><Topic>.md`. A document already in
  a subdirectory of the document directory stays in that subdirectory, renamed
  in place. A document already in place with a genre-prefixed name is not
  moved: go to step 4.
- **If the user has already renamed it,** staged or committed, check that
  `git status` shows a rename (`R`), and use it.
- **Otherwise move it** with `git mv <old> <new>`.
- **Update the links to it** in the repository's Markdown files, and the
  relative links inside it to match its new place. Leave paths that record
  history, such as a row of a Log's Files table or a Log's account of what a
  commit changed; "(now `<new path>`)" may follow such a path.
- **Update the `AGENTS.md` migration line** when it is the backlog record (see
  [Before starting](#before-starting)), and do not yet remove it.
- **List what you cannot update:** links from other repositories, forge and
  site URLs, and references in source comments.
- Run `compass check --skip-unmarked`, then **stop**: ask the user to commit the
  move alone, for example `git commit -m "rename <old> to <new>"`, before the
  reshape. A rename committed with a rewrite may not be followed by
  `git log --follow`, and the derived authors and dates would then be lost.

### 4. Reshape

Confirm that the move is committed (`git log -1 --stat` shows the rename, and
the tree is clean). Then make only these changes (COMPASS-DRAFT-migration-D2),
following any differences the repository's own plan makes:

- **Front-matter,** in the field order of the genre's template:
  - `id: <NS>-DRAFT-<slug>`, `title`, `genre`, `subtype` where it applies,
    `scope`, `program`/`project`/`component`, and `language`.
  - `status: Draft`, whatever the original implies (COMPASS-DRAFT-migration-D7).
  - `schema-version` or `api-version` from the original's version line, for a
    Spec or for a Ref or Guide.
  - `decisions:` and `open-questions:`, mirroring the records in the body.
  - `relates-to:` only for documents of the corpus the original names, and
    `cites:` only for outside sources the original cites.
  - `provenance:` with `assistant:` (this assistant), `original-assistant:`
    where the original was written with an assistant and the user or its
    transcript says which, `session:` only if verified, and
    `migrated-from: <old path>@<revision>` (§7).
  - Leave out `authors`, `created`, and `updated`, which come from Git. Never
    write `approved-by`, `reviewers`, or `reviewed`.
- **Header lines:** remove the lines that only state what the front-matter now
  holds: a title line the new heading replaces, a version line, and a status
  line. Where a status line also states a fact, as "**Status:** Conceptual. No
  implementation has begun." does, remove only the status and keep the fact as
  a line. Keep a line giving the author's date. Remove a genre marker from the
  title, such as "Concept:" or "DevLog", since the `genre` field now says it.
- **Sections:** rename them to follow the genre's §14 spine, keeping their text
  and any cited numbers, as in "4. Required Core Tag Vocabulary". Text a renamed
  heading displaces, such as the expansion of a name, stays as a line under the
  new heading. Move a section only where the original's order breaks the
  spine; sections already in an order it accepts, optional ones included, stay
  where they are. In a Spec, add "Required" only to the chapters the user
  decided in step 2.
- **Gaps:** where the spine requires a section or field the original fills
  elsewhere, point to that place with a link or a full identifier: "See
  [Problem](#problem).", or "Deferred; see `<record>`." in Outstanding Work.
  Where a decision's own sentence names the option it rejects ("Rather than
  discrete … systems, …"), its Alternatives field is "See the Decision.".
  Where the original lacks it altogether, write "Not recorded in the
  original."
- **Records:** each decision becomes
  `### <NS>-DRAFT-<slug>-D<n> — <title>`, with `**Status:** Proposed` and
  `**Context:**`, `**Decision:**`, and `**Alternatives:**` filled only with the
  original's own sentences, or with a pointer to the section of the original
  that gives them, such as "See [Problem](#problem).". An alternative the
  original does not give anywhere is "Not recorded in the original.", never
  one reconstructed from the code or history. Open questions become `-O<n>`
  records the same way. Explanatory text that fits no field stays after the
  fields. Rewrite every reference to them in the document as the full
  identifier. An identifier that looks canonical but is not in the ledger
  becomes provisional, and the report names the collision.
- **Accessibility (§12):** a `Table:` caption before each table and a
  `Description:` paragraph after each diagram. Where a lead-in such as "Tag
  mappings:" introduces a table, the lead-in becomes its caption.
- **Links:** a link to, or a backticked path or file name of, another document
  already in the corpus is written as a link with its identifier as the text
  and its path as the target, and the identifier goes in `relates-to`. A
  document not yet migrated keeps its path; it becomes a link when that
  document is migrated (step 7).
- **Code references:** pin each to the revision chosen in step 2
  (COMPASS-DRAFT-migration-D5).
  - A file and line become `path:symbol@revision`, naming the definition that
    encloses the line at that revision (read it with
    `git show <revision>:<path>`), or `path#L<n>@revision` where none does.
  - A file the original names is pinned in place, `path@revision`.
  - Where a passage names a symbol together with the file that defines it at
    that revision, add `path:symbol@revision` in that passage, in parentheses,
    or in place of a bare symbol name such as the head of a list item. Do not
    pin a symbol the text says was removed or replaced, even if the file still
    defines one by that name; note it instead.
  - A reference whose file did not exist at that revision stays as it was, and
    goes in the report.
  - Paths that record history, such as a Log's Files table, are not pinned.

Change nothing else. Stale facts, gaps, errors, and unclear prose stay as they
are; write down what you notice for the report.

### 5. Check

- If the document directory has an `INDEX.md`, regenerate it first, with
  `compass index`.
- Then check the whole corpus, not only the new path: `compass check`, with
  `--skip-unmarked` while other documents remain unmarked and `--federation`
  when the document cites other repositories. Checking one path hides findings
  in other files, such as `index/current` on `INDEX.md`. Fix every error the
  migration introduced, such as `register/mirrored`, `ref/doc-resolves`,
  `ref/code-exists`, `fm/types`, or `index/current`, and run it again until
  there are none.
- Fix `ref/short-record` warnings by writing the full identifier, and check each
  `ref/code-exists` warning against the history. `ref/migrated-from` must
  report nothing: if it does, the original's path or revision is wrong.
- Check your own links and relations: every document of the corpus that the
  original names, by link, backticked path, or file name, is a link with its
  identifier as the text and is listed in `relates-to`.
- Read your own diff against the original (`git diff`). Every word removed must
  now be in the front-matter, a heading, or a field label, and every word added
  must be front-matter, a heading, a field label, an identifier, a pin, a
  caption, a pointer, or "Not recorded in the original." List anything else,
  and undo it unless it is a link or an identifier.

### 6. Report

Lead with the path, the provisional identifier, and the check result (errors,
warnings, files skipped, references unverified, notes, and the toolchain
version). Then:

- **Records:** a table mapping the original's numbering to the records.
- **Pins:** every code reference pinned, with its revision and the evidence for
  that revision, and every reference left as it was.
- **Links and anchors:** each changed, each left as history, and each this
  skill could not update, including links from other repositories.
- **Differences from the repository's own plan,** each with both decisions'
  identifiers.
- **Proposed statuses** for the document and each record, from the genre's own
  vocabulary (`../reference/vocabularies.md`): a Log `Implemented`, a Spec or
  Ref `Current`, a Plan `Accepted` or `Implemented`, decisions `Accepted` or
  `Implemented`. Quote the original's words that support each. For a Spec,
  Ref, or Guide, say whether it matches the code as it is now; if not, propose
  keeping `Draft` until it is revised (COMPASS-DRAFT-migration-D7).
- **Notes on content,** for the edit that follows: stale facts, gaps, errors,
  contradictions, examples that do not work, and a mix of genres.

Then hand off (COMPASS-DRAFT-migration-D11):

1. The user commits the reshape **alone**. That commit is the form-only state a
   reviewer compares with the original at `migrated-from`.
2. `compass-review` reviews the document against its original.
3. The content is revised, where the notes call for it, in an ordinary assisted
   edit, after the reshape commit, and for a Spec, Ref, or Guide before the
   steward sets `Current`. A new document such as a split part is written with
   `compass-author`, and carries `provenance.migrated-from` naming the same
   original (COMPASS-DRAFT-migration-O1).
4. The steward sets the statuses and `approved-by`, and asks for
   `compass assign` when ready, which runs with `--dry-run` first.

### 7. After the reshape is committed

Update the mentions of it, then the backlog record:

- **Mentions in documents already migrated** (COMPASS-DRAFT-migration-D4).
  Search them for this document's old and new paths, as links, backticked
  paths, and file names. Rewrite each as a link with its identifier as the
  text, `[<ID>](<path>)`, and add the identifier to that document's
  `relates-to`. Leave mentions that record history, such as a Log's Files
  table. Regenerate the index and check the corpus again.
- **A migration Log** (COMPASS-DRAFT-migration-D8): draft an
  `## Update <date> — <title>` section naming the document, its original path
  and `migrated-from` revision, its move and reshape commits, and the notes on
  stale content, with code references pinned to the reshape commit. The first
  time, write `Log.CompassMigration.md` with `compass-author`, naming the
  commit the migration began from.
- **The `AGENTS.md` line:** name the documents still unmarked. When none remain,
  remove the line and its advice to use `--skip-unmarked`.

Then offer the next document.

## Choosing the genre

Propose from the document's role, not its filename:

Table: The genre a document's role suggests.

| The document is | Genre |
|---|---|
| A description of software as it runs: its API, structure, or behaviour | `Ref` |
| A normative contract for a format, protocol, or interface | `Spec` |
| A comprehensive design, with its decisions | `Arch` |
| An account of a piece of work done, with its decisions | `Log` |
| A plan for work, done or not | `Plan` |
| An exploration of whether to build something | `Survey` |
| A comparison or assessment against criteria | `Eval`, with its subtype |
| Instructions for users or developers | `Guide`, `tutorial` or `howto` |
| Verified properties of running code, each a short claim | `Memo` |

An abandoned idea takes the genre it would have had, with `Rejected` or
`Withdrawn` proposed, or stays unmarked, recorded as such in the backlog
record. Leaving a document unmarked, with a reason, is a decision, not a
backlog item.

## Without the toolchain

If no executable is found, do the steps by hand and say so in the report:

- Read the namespace and document directory from `compass.sexp`, and find the
  unmarked documents by looking for `.md` files that do not open with `---`.
- Check the front-matter against `../reference/frontmatter.md` and the records
  against `../reference/references.md`.
- Check each pin with `git show <revision>:<path>` and the `migrated-from`
  revision with `git cat-file -e <revision>:<path>`.
- Tell the user that the migration has **not** been checked by the toolchain,
  and how to install it.

## Invariants

- **One document per request** (COMPASS-DRAFT-migration-D1), whatever a
  repository's plan says.
- **Form only** (COMPASS-DRAFT-migration-D2). Never add a fact the original does
  not contain, update a stale one, fill a gap other than with a pointer to where
  the original fills it or "Not recorded in the original.", reconstruct an
  alternative, or improve the prose. Never split
  or merge documents.
- **Never commit,** push, rewrite history, or change Git configuration. The move
  and the reshape are committed separately, by the user.
- **Never set an authoritative status** or `approved-by`, `reviewers`, or
  `reviewed`; propose statuses only (§6, COMPASS-DRAFT-migration-D7).
- **Never invent a canonical identifier;** provisional ones only. Run
  `compass assign` only when the user asks.
- **Never record a session that is not verified** (COMPASS-DRAFT-migration-D3).
- **Change only** the document, the links to it in this repository's Markdown
  files, the `AGENTS.md` migration line, the generated index, and, after the
  reshape commit, the mentions of it in documents already migrated and the
  migration Log. Never move a file that is not a document.
- This skill **proposes**; the toolchain checks, and a person accepts. Report
  what `compass check` found, never that the migration is correct beyond it.
