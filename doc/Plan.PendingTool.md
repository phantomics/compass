---
id:            COMPASS-DRAFT-pending-tool
title:         Compass Pending — Listing What Is Waiting for a Number
genre:         Plan
scope:         component
program:       Compass
component:     toolchain
language:      en
status:        Draft
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-0004
  - COMPASS-0013
  - COMPASS-0003
  - COMPASS-0016
decisions:
  - COMPASS-DRAFT-pending-tool-D1
  - COMPASS-DRAFT-pending-tool-D2
  - COMPASS-DRAFT-pending-tool-D3
  - COMPASS-DRAFT-pending-tool-D4
  - COMPASS-DRAFT-pending-tool-D5
open-questions:
  - COMPASS-DRAFT-pending-tool-O1
  - COMPASS-DRAFT-pending-tool-O2
  - COMPASS-DRAFT-pending-tool-O3
---

# Compass Pending: Development Plan

This plan builds `compass pending`, a read-only command that lists the
documents of a corpus still holding provisional identifiers, and says which of
them `compass assign` would number now, together with the files a migration
has still to reach. With it, `compass check` notes how many
documents are ready, and the `/orient` command reports the counts. What the
command does is decided in COMPASS-DRAFT-toolchain-D30, in
[COMPASS-0004](Plan.Toolchain.md#compass-draft-toolchain-d30--compass-pending-lists-what-is-waiting-for-a-number);
this plan records how it is built, in stages, for release with v0.2.1. It
builds on the ledger and allocation of v0.2
([COMPASS-0013](Log.Ledger.md)).

## Problem

Numbers are assigned one file at a time, when the steward runs `compass assign`
on a document they have accepted (COMPASS-D28). Nothing tracks what is left:

- **Accepted documents stay provisional unnoticed.** A steward who accepts a
  document and does not assign it at once has no reminder. `index` lists
  provisional identifiers beside numbered ones, without saying which could be
  numbered.
- **Records added to numbered documents are easy to miss.** A decision added to
  an accepted plan takes a provisional identifier under the plan's alias
  (COMPASS-D27). The document's own identifier is canonical, so nothing in the
  index marks it as unfinished. COMPASS-0003 holds such a record now.
- **Why a document cannot be assigned is learnt only by trying.** `assign`
  refuses for short references to the records, for a status not yet accepted,
  or for a damaged ledger, one document at a time.
- **The listing can be had only by parsing the index.** A pipeline over
  `compass index --stdout` finds the provisional identifiers, but depends on
  the index's table layout and cannot tell ready from blocked.
- **The migration backlog is only counted.** `check --skip-unmarked` reports
  how many files it skipped for having no front-matter, not which
  (COMPASS-O48).

## Goals

- One command that answers "what is waiting for a number, and what can I
  number now?" for the namespaces a repository owns, and "what is still to be
  migrated?" for the repository.
- Agreement with `assign` by construction: a document listed as ready is one
  `assign` accepts, and a blocked one is listed with the reason `assign` would
  give.
- A reminder where the steward already looks: a note from `compass check`, and
  a line from `/orient`.
- No new cost for `check` beyond what the note needs, and a listing fast enough
  to run often.
- Text for people and JSON for tools, like `refs` and `outline`.

## Settled Decisions

All five decisions are proposals for the steward. They concern how
COMPASS-DRAFT-toolchain-D30 is built; the command's behaviour is decided there.

### COMPASS-DRAFT-pending-tool-D1 — `assign`'s checks are factored out and shared

**Status:** Proposed
**Context:** `plan-assign` (`src/corpus/allocate.lisp:plan-assign@2e839c9`)
decides whether a document may be numbered inside one function, refusing at
the first failure: the document's identifier and namespace, its status, the
ledger's problems and duplicate numbers, identifiers already assigned, the
absence of anything provisional, and short references to the records it would
number. `pending` must reach the same verdict for every document, and must not
drift from `assign` when a check is added.
**Decision:** Split those checks out of `plan-assign` into two functions in
the same file: one returning the corpus-wide blockers (the ledger's problems
and duplicates), and one returning a document's blockers, each blocker a
structure with a kind and the message `assign` prints today. `plan-assign`
refuses with the first blocker, as now, so its messages and tests are
unchanged; `pending` reports all of them. A document's status not being
accepted is one blocker kind. A document whose status `assign` does not
accept is waiting, whatever else blocks it, and its other blockers are shown
as information; so is a document whose only provisional records are `Draft`
memos. Only a document whose status `assign` accepts is ever blocked.
**Alternatives:** Call `plan-assign` for each document and catch the refusal
(rejected: it consults the base revision's ledger through Git for every
document, reports only the first reason, and plans rewrites it then discards);
reimplement the checks in `pending` (rejected: the two would drift).

### COMPASS-DRAFT-pending-tool-D2 — Short references are found once per corpus

**Status:** Proposed
**Context:** The short-reference blocker searches the whole corpus
(`src/corpus/short.lisp:short-references-to@2e839c9`), and finding short
references is already the slowest part of `check` (about 210 ms of about
530 ms on this repository's 22 documents, measured on 2026-11-19). Asking it
once per pending document would multiply that cost by the number of
documents; `check`, which already finds every short reference for
`ref/short-record`, would find them all again for its note.
**Decision:** Cache each document's short references in the loaded corpus the
first time they are found, so that `ref/short-record`, `short-references-to`,
`pending`, and the note share one scan. The corpus already has a general
per-load cache,
`corpus-cached` (`src/corpus/corpus.lisp:corpus-cached@207b23c`), which code
references, revisions, and Git's state use; the short references are kept
there, keyed by document, and need no new slot. The cache lives as long as the
corpus object, which commands load once and never modify in place; `assign`
and `renumber` reload before checking their result, as they do now.
**Alternatives:** Pass a precomputed table to the blocker function (rejected:
every caller would have to build it, and `check` could not share its own scan
with the note); skip the short-reference blocker in the note (rejected: the
note would count as ready a document `assign` refuses).

### COMPASS-DRAFT-pending-tool-D3 — The note counts only the documents `check` checked

**Status:** Proposed
**Context:** `check` can be limited to paths, and is run so in hooks and on a
single file by the skills. A note counting the whole corpus there would
report documents the user did not ask about.
**Decision:** The note counts the ready documents among those checked: all of
them for a whole-corpus check, and those under the given paths otherwise. It is
added only when the count is at least one, through the corpus's existing notes,
so that it appears in the text report and in the JSON report's `notes`, and it
never changes the exit status, under `--strict` too. It is not added when the
ledger has problems, since `check` already reports those as errors.

Notes are redefined to match: a note either says what the check could not do,
such as a rule that needs Git when Git is missing, or gives information about
what it checked, such as this count. Only the first kind means the check
checked less. `skills/reference/toolchain.md` and Step 1 of `compass-review`,
which today read every note as a limitation, say so.
**Alternatives:** Always count the whole corpus (rejected: noise in a check of
one file); a separate summary line (rejected: notes are the existing channel,
which the skills and `/orient` already read); keep notes for limitations only
and give the count a channel of its own (rejected by the steward on
2026-11-19: a second channel for one line of information costs every reader of
the report, where redefining notes costs two paragraphs of the skills).

### COMPASS-DRAFT-pending-tool-D4 — `/orient` runs `pending` as a read-only step

**Status:** Proposed
**Context:** `/orient` (`commands/opencode/orient.md`) orients an agent in a
repository by running only commands that read; its step 4 already reports
`check`'s notes, so the note arrives there unaided. The note says only how many
documents are ready, not how many are waiting.
**Decision:** Step 3 of `/orient`, which summarises the index, also runs
`compass pending` and reports the ready, blocked, and waiting counts, and the
number of files not yet migrated (COMPASS-DRAFT-pending-tool-D5), in one line,
naming the ready documents. `pending` writes nothing, so `/orient`
remains read-only. Like the rest of `/orient`, the step is retired with it
when the session catalog exists.
**Alternatives:** Rely on the note alone (rejected: it says nothing about
waiting or blocked documents); a separate step (rejected: the counts belong
with the summary of the index).

### COMPASS-DRAFT-pending-tool-D5 — Files not yet migrated are listed as a fourth group

**Status:** Proposed
**Context:** COMPASS-O48 asked for a listing of the migration
backlog: the files without front-matter that `check --skip-unmarked` skips and
reports only by count. It was resolved on 2026-11-19 by placing the listing in
`compass pending`, since a file waiting for migration is at the step before a
document waiting for a number, and one command can show both. Such a file has
no identifier, no namespace, and no status, so none of the three groups fits
it.
**Decision:** `pending` lists a fourth group, **unmarked**, after the other
three: each file of the corpus that the loader skips for having no
front-matter, by path, in path order. The loader already records them, so
listing them costs nothing. Since they have no namespace, they are listed only
when `--namespace` is not given, and never with `--ready`; the summary line
counts them separately. `pending` does not read the backlog record of
COMPASS-D75, which is prose: it lists every unmarked file, and
the backlog record says which are left deliberately and why. Files outside the
document directory that the loader does not consider, such as `README.md`, are
not listed.
**Alternatives:** A separate command or a `check` option listing the skipped
files (rejected: two listings of one pipeline, and `check --format json`
already lists them for tools); leave out the files the backlog record calls
deliberate (rejected: the record is prose, and declaring them in
`compass.sexp` was rejected by COMPASS-O48's resolution); list
them under every `--namespace` (rejected: they belong to none).

## Design

### What is listed

Every document in a namespace the repository owns (the manifest's
`:namespaces`) whose identifier is provisional, or which defines a provisional
record. Documents of federated repositories, and documents in this repository
carrying another namespace, are not listed. A document whose front-matter
cannot be read has no identifier to list; `check` reports it under
`fm/syntax`. Each document is placed in one group, and the files not yet
migrated make a fourth (COMPASS-DRAFT-pending-tool-D5):

Table: The groups of `compass pending`, and what places a document in each.

| Group | When | What is shown |
|---|---|---|
| ready | `assign` would number it now | Records whose own status is not accepted, flagged |
| blocked | Its status allows `assign`, but a blocker remains | Each blocker's message, as `assign` would give it |
| waiting | Its status is not one `assign` accepts, whatever else blocks it, or its only provisional records are `Draft` memos | Its status, and any other blockers as information |
| unmarked | A file the loader skips for having no front-matter | Its path |

A corpus-wide blocker, such as a ledger with errors, is printed once before the
groups, and every document whose status allows `assign` is then counted as
blocked by it.

### Text output

```
Ready to assign (2):
  COMPASS-0003  doc/Plan.AuthoringAssistance.md  Implemented
    1 decision; COMPASS-DRAFT-authoring-assistance-D1 is Proposed
  COMPASS-DRAFT-example  doc/Plan.Example.md  Accepted
    the document, 3 decisions, 1 open question
Blocked (1):
  COMPASS-DRAFT-other  doc/Plan.Other.md  Accepted
    the document, 2 decisions
    2 short references would change meaning once these records are numbered;
    write them as full identifiers first
Waiting for acceptance (6):
  COMPASS-DRAFT-sample  doc/Plan.Sample.md  Draft
    the document, 4 decisions, 2 open questions
  ...
Not yet migrated (2):
  doc/Design.md
  doc/notes/Roadmap.md

9 documents hold provisional identifiers: 2 ready, 1 blocked, 6 waiting;
2 files are not yet migrated.
```

The identifiers and paths above are illustrative, apart from COMPASS-0003. With
`--ready`, only the first group and the summary line are printed. With nothing
pending, a single line says so.

### JSON output

An object with the tool's name and version, the corpus root, the namespaces
listed, any corpus-wide blockers, a `documents` array, and an `unmarked` array
of paths. Each entry has the
identifier, path, namespace, status, group, the counts of provisional records
by kind, the provisional records with their own statuses, and the blockers.
`--ready` filters the `documents` array the same way and leaves `unmarked`
empty.

### Where the code goes

Table: The files each part of the work touches.

| Part | File |
|---|---|
| Blockers shared with `assign` (COMPASS-DRAFT-pending-tool-D1) | `src/corpus/allocate.lisp` |
| Short-reference cache (COMPASS-DRAFT-pending-tool-D2) | `src/corpus/short.lisp`, through the existing `corpus-cached` |
| The listing, and the unmarked files the loader records (COMPASS-DRAFT-pending-tool-D5) | `src/corpus/pending.lisp` (new), in the corpus layer |
| The command, text and JSON | `src/cli.lisp`, beside `refs` |
| The note (COMPASS-DRAFT-pending-tool-D3) | the `check` command in `src/cli.lisp` |
| `/orient` (COMPASS-DRAFT-pending-tool-D4) | `commands/opencode/orient.md` |
| Skills' reference | `skills/reference/toolchain.md` |
| Tests | `tests/test-allocate.lisp`, `tests/test-pending.lisp` (new), `tests/test-cli.lisp`, `tests/test-skills.lisp` |

The new source file opens with a source header naming
COMPASS-DRAFT-toolchain-D30 and this plan's decisions, and is listed in
`compass.asd`, as are the new tests.

## Tensions and Risks

- **Readiness changes with the working tree.** A status edit not yet committed
  changes the listing. That is intended, since `assign` reads the working tree
  too, but a listing run on one branch says nothing of another.
- **The base ledger is not consulted.** `assign` reads the ledger at `--base`
  only to choose the next number, not to decide whether a document may be
  numbered, so `pending` does not need Git beyond what loading the corpus
  does. If a later check in `assign` depends on the base,
  COMPASS-DRAFT-pending-tool-D1 makes `pending` inherit it, with its cost.
- **Flagged records may be numbered by mistake.** A ready document's
  `Proposed` record is numbered by `assign` along with the rest. The flag
  makes this visible; whether `assign` should do more is
  COMPASS-DRAFT-pending-tool-O1.

## Open Questions

### COMPASS-DRAFT-pending-tool-O1 — Should `assign` warn about records not yet accepted?

`assign` numbers every provisional record of an accepted document, whatever
the record's own status, and `pending` only flags such records. Should
`assign` warn too, as it does for `--force`, or refuse unless the records are
accepted, which would change COMPASS-D28?

### COMPASS-DRAFT-pending-tool-O2 — The age of what is waiting

A draft untouched for months is a different kind of backlog from one written
yesterday. The Git-derived `updated` date would show it, at the cost of a Git
query per document. Is that worth showing, perhaps behind an option?

### COMPASS-DRAFT-pending-tool-O3 — Reminders beyond the note

`pending` exits 0 whatever it lists, so it cannot fail a hook or CI job.
Should the pre-commit script or the CI workflow print the ready list, as
information, when it is not empty?

## Prior Art

Table: Prior tools and what this plan draws from each.

| System | What to draw from |
|---|---|
| `git status` | A read-only listing grouped by what the user can do next, with the command that acts on each group |
| Django's `showmigrations` and `makemigrations --check` | Listing what is unapplied separately from the command that applies it, and the choice whether the listing gates CI |
| `compass refs` and `outline` | Text and JSON output from one model, and exit 1 only for a failed lookup |

## Roadmap

Each stage ends with `make test` passing and `bin/compass check` reporting no
errors.

1. **This plan (now).** For the steward's review, with
   COMPASS-DRAFT-toolchain-D30 in COMPASS-0004.
2. **Acceptance.** The steward accepts, amends, or rejects
   COMPASS-DRAFT-toolchain-D30 and COMPASS-DRAFT-pending-tool-D1 to
   COMPASS-DRAFT-pending-tool-D4.
3. **Shared blockers (COMPASS-DRAFT-pending-tool-D1).** Factor the checks out
   of `plan-assign`; its refusals and the allocation and concurrency tests stay
   unchanged. New tests cover each blocker kind and that all of a document's
   blockers are returned.
4. **Short-reference cache (COMPASS-DRAFT-pending-tool-D2).** Tests show that
   the rule's findings are unchanged and that a second request does not scan
   again; the time of `check` on this repository is recorded before and after.
5. **The listing.** `src/corpus/pending.lisp`, with tests in temporary Git
   repositories: a ready document; a numbered document with one provisional
   record; a document blocked by short references; a draft; a host whose only
   provisional records are `Draft` memos; a flagged `Proposed` record; a
   ledger with errors; a document in a namespace the repository does not own,
   which is not listed; and files without front-matter, listed as unmarked
   without `--namespace` and not with it (COMPASS-DRAFT-pending-tool-D5).
6. **The command.** `compass pending` with `--namespace`, `--ready`,
   `--format`, and `--root`; tests through `run-cli` of the text and JSON
   output and of the exit statuses, including a namespace not owned.
7. **The note (COMPASS-DRAFT-pending-tool-D3).** Tests that it appears only
   when a checked document is ready, counts only checked paths, appears in the
   JSON report's notes, and leaves the exit status alone under `--strict`.
8. **Skills and `/orient` (COMPASS-DRAFT-pending-tool-D4).** `toolchain.md`
   documents `pending`, as the skills tests require of every command, and,
   with Step 1 of `compass-review`, the two kinds of note
   (COMPASS-DRAFT-pending-tool-D3);
   `/orient` step 3 runs it;
   `compass-author`'s report and `compass-review`'s acceptance advice may
   point to it. The skills tests pass.
9. **Release.** With v0.2.1's binaries; a Log of the work, written after its
   commit; the README's description of the toolchain names the command.
