---
id:            COMPASS-0018
title:         Compass Pending Development Log
genre:         Log
scope:         component
program:       Compass
component:     toolchain
language:      en
status:        Implemented
authors:
  - Andrew Sengul
approved-by:   Andrew Sengul
reviewed:      2026-10-19
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-0017
  - COMPASS-0004
  - COMPASS-0013
  - COMPASS-0016
decisions:
  - COMPASS-D85
  - COMPASS-D86
  - COMPASS-D87
  - COMPASS-D88
---

# Compass Pending: Development Log

This document chronicles the building of `compass pending` on 2026-11-19, in
six commits from `1278fb3` to `6c2009c`: `assign`'s checks shared as blockers,
a cache of short references, the listing, the command, the note `compass check`
adds, and the skills and `/orient` that point to it. The plan is
[COMPASS-0017](Plan.PendingTool.md), its stages 3 to 8; the command's behaviour
is decided in COMPASS-DRAFT-toolchain-D30 of [COMPASS-0004](Plan.Toolchain.md).

## Problem

Numbers are assigned one document at a time, by `compass assign`, once a person
has accepted it, and nothing tracked what was left. A steward could not see
which documents were ready to number, why `assign` would refuse one without
running it, or which records added to numbered documents still held provisional
identifiers; and `check --skip-unmarked` counted the files a migration had not
reached without naming them (COMPASS-O48 of [COMPASS-0016](Plan.Migration.md)).
COMPASS-0017 planned a read-only command for all four. It was written in
`d9d09ba`, reviewed and revised in `f6cea01` and `d719336`, accepted in
`4b2634c`, and numbered in `0110e47`, before the work began.

## Design Decisions

The design is decided in COMPASS-0017 (COMPASS-D79 to COMPASS-D83). These are
the choices made while building it.

### COMPASS-D85 — Without Git, the `user.name` blocker says Git was not found

**Status:** Implemented
**Context:** COMPASS-D79 makes a Git without `user.name` a blocker of every
assignment, found by asking Git for the name. `assign` refuses before that
outside a Git repository, but `pending` lists without needing Git, as the
plan's Tensions say, and `check` adds its note everywhere; asking Git for a
name where Git cannot be run signals an error.
**Decision:** `src/corpus/allocate.lisp:corpus-git-name@e9d379e` returns no
name when Git cannot be run, and
`src/corpus/allocate.lisp:git-name-blocker@e9d379e` then says "Git was not
found; assign needs it to record who allocated each number", in place of the
advice about `user.name`. The blocker's kind is the same, so every document
`assign` would accept is listed as blocked.
**Alternatives:** A blocker kind of its own (rejected: it blocks for the same
reason, that the ledger cannot record who allocated a number, and would add a
kind COMPASS-D79 does not list); let `pending` fail without Git (rejected: the
listing needs nothing of Git but the name, and `check` would fail with it).

### COMPASS-D86 — The missing `user.name` message names `.mailmap`

**Status:** Implemented
**Context:** COMPASS-D79 keeps the messages `assign` refuses with unchanged,
and also asks that the `user.name` blocker say that the repository's `.mailmap`
maps the name to the one the ledger records. The blocker's message is the one
`assign` refuses with, so the two cannot both hold.
**Decision:** The message gains the clause "(the repository's .mailmap, if it
has one, maps it to the name recorded)", for `assign` and `pending` alike. No
test had checked the message before; one now does.
**Alternatives:** A separate remedy for `pending` alone (rejected: the two would
give different advice for one problem, against the purpose of COMPASS-D79).

### COMPASS-D87 — The summary counts the whole listing, even with `--ready`

**Status:** Implemented
**Context:** With `--ready`, COMPASS-0017 prints only the ready group and the
summary line, and filters the JSON's documents, but does not say what the
summary counts. `/orient` reports the ready, blocked, and waiting counts
(COMPASS-D82), which a filtered listing no longer holds.
**Decision:** The summary line, and a `summary` object added to the JSON
(`src/cli.lisp:pending-json@a0b6dee`), always count the whole listing: the
documents in each group, and the files not yet migrated.
**Alternatives:** Count only what is listed (rejected: "2 ready, 0 blocked, 0
waiting" would be untrue); leave the JSON without a summary (rejected: a tool
would have to count the groups itself, and could not with `--ready`).

### COMPASS-D88 — The note is skipped when no checked document could be ready

**Status:** Implemented
**Context:** The note shares the scan for short references with
`ref/short-record` (COMPASS-D80), so a full check cost no more with it. But a
check that excludes that rule, or is limited to one file that cannot be ready,
then paid for the scan anyway: 561 ms in place of 333 on this repository.
**Decision:** `src/cli.lisp:note-ready-documents@3c9d767` builds the listing
only when some checked document could be ready: one whose status `assign`
accepts and that holds something to number. Otherwise no note is possible, and
nothing is scanned.
**Alternatives:** Leave out the short-reference blocker from the note (rejected
by COMPASS-D80: the note would count documents `assign` refuses); accept the
cost (rejected: it falls on the hooks and single-file checks the note is least
needed in).

## Implementation

Stages 1 and 2 of COMPASS-0017, its writing and acceptance, came before. Each
of stages 3 to 8 ended with `make test` passing and `compass check` reporting
no errors, and was committed by the steward.

### Stage 3: `assign`'s checks as blockers (`1278fb3`)

`plan-assign` had decided in one function, refusing at the first failure.
Its checks became blockers, each a structure with a kind, the message `assign`
refuses with, whether `--force` passes it, and its data
(`src/corpus/allocate.lisp:new-blocker@1278fb3`):

- `src/corpus/allocate.lisp:corpus-blockers@1278fb3` returns those of every
  assignment: a manifest without `:namespaces`, errors and duplicate numbers in
  the ledger, and a Git without `user.name`;
- `src/corpus/allocate.lisp:document-blockers@1278fb3` returns a document's: a
  status `assign` does not accept, identifiers already assigned, nothing to
  number, and short references to what it would number;
- `src/corpus/allocate.lisp:identifiers-to-number@1278fb3` lists what `assign`
  numbers, Draft memos left out, and both the numbering loop and the blockers
  use it, so the checks for identifiers already assigned and for short
  references no longer run inside the loop.

`plan-assign` refuses with the first blocker `--force` does not pass, in the
order it refused before, and its own tests and those of concurrent allocation
passed unchanged. Six tests were added, among them the first of the refusals
for an identifier already assigned and for a Git without `user.name`.

### Stage 4: short references found once (`be934c5`)

`src/corpus/short.lisp:document-short-references@be934c5` keeps each
document's short references in the corpus's cache the first time they are
found, and returns the same list after; the scan itself became
`scan-short-references`, unchanged. `ref/short-record`, `short-references-to`,
and the blockers share it with no change of their own
(`tests/test-allocate.lisp:short-references-are-found-once-per-corpus@be934c5`).

### Stage 5: the listing (`e9d379e`)

`src/corpus/pending.lisp:list-pending@e9d379e` lists every document of the
repository in an owned namespace that holds a provisional identifier, Draft
memos included, and places each in one group from the blockers: waiting for its
status, or for its memos when its only provisional records are Draft memos;
blocked; or ready, with the records `assign` would number whose own status is
not accepted flagged. The files skipped for having no front-matter follow,
unless a namespace or `:ready` is given (COMPASS-D83). A test checks that
`plan-assign` numbers every document the listing calls ready and refuses every
blocked one with the first blocker listed
(`tests/test-pending.lisp:pending-agrees-with-assign@e9d379e`). The same commit
made the `user.name` blocker safe without Git
(COMPASS-D85).

### Stage 6: the command (`a0b6dee`)

`compass pending [--namespace NS] [--ready] [--format text|json] [--root DIR]`,
after `refs` in `compass help`, prints the groups as COMPASS-0017's design shows
(`src/cli.lisp:write-pending-text@a0b6dee`) or their JSON
(COMPASS-D87). A namespace the repository does not own is
a failed lookup, exit 1. `skills/reference/toolchain.md` describes the command
in the same commit, since the skills tests require it of every command. Its
tests went into `tests/test-pending.lisp`, beside the repository they share,
not into `tests/test-cli.lisp` as the plan's table of files first had it; the
table was corrected after this Log was written.

### Stage 7: the note (`3c9d767`)

`compass check` notes how many of the documents it checked are ready to be
numbered with `compass assign`, and that `compass pending --ready` lists them,
counting only the paths given
(`src/cli.lisp:document-selected-p@3c9d767`); the note never changes the exit
status (COMPASS-D81), and is skipped when no checked document could be ready
(COMPASS-D88). `toolchain.md` and Step 1 of
`compass-review` now describe two kinds of note: those that say what the check
could not do, and those that give information about what it checked.

### Stage 8: the skills and `/orient` (`6c2009c`)

Step 3 of `/orient` runs `compass pending`, where `compass help` lists it, and
reports the counts in one line, naming the ready documents (COMPASS-D82).
`compass-author`'s report, where it hands a document over for acceptance, and
`compass-review`, where it recommends Accept, name `compass pending --ready` as
the step after acceptance, leaving `assign` to the person.

### Stage 9: the README

The README's description of the toolchain, its list of commands, its account of
migration, and its account of `/orient` name `compass pending`, in the commit
that holds this Log. The release binaries of v0.2.1 are not yet built.

## Pitfalls Encountered

- **The guard against stray format strings knows only the operators it
  lists.** `new-blocker` takes a format control as its second argument, which
  `no-stray-format-strings` would have reported; it was added to the guard's
  table (`tests/test-repository.lisp@1278fb3`).
- **`~:p` looks back at the argument before it,** which in
  `(format nil "~d ~a~:p" n name n)` was the name, not the count. The build's
  style warning caught it before any output was wrong; the directive is now
  `~p`, with the count passed again.
- **The `lines` helper of the tests ends every line with a newline,** so an
  expected block whose last line is partial never matched; such blocks are
  built with a helper that leaves the last newline out.
- **A binary built before a commit names the earlier commit.** The timings of
  stage 4 were first taken with an executable reporting `a54ff53-dirty`; it was
  rebuilt so that the figures before the change belong to `1278fb3`.
- **Sharing a scan moves its cost.** The note made a check that excludes
  `ref/short-record` scan anyway, which only measuring found
  (COMPASS-D88).

## Verification

Run via `make test`. Before the work, at `a54ff53`, the suite ran 1317 checks,
all passing; at `6c2009c` it runs 1458, all passing, under `DEPS=ql` and, from
a clean clone with the pinned `ocicl.csv`, under `DEPS=ocicl`. Each commit was
run again from a clean clone: 1339 checks at `1278fb3`, 1347 at `be934c5`, 1388
at `e9d379e`, 1441 at `a0b6dee`, 1453 at `3c9d767`, and 1458 at `6c2009c`, every
one passing. `compass check --federation` reports no errors and no warnings,
and `compass index --check` finds the index current. Once this Log is
committed, the suite runs one check more, since
`tests/test-repository.lisp:every-front-matter-block-parses@6c2009c` makes one
for each document.

Table: The time of `bin/compass check` on this repository's 23 documents, the median of seven runs.

| Run | Before (`1278fb3`) | After stage 4 | After stage 7 |
|---|---|---|---|
| Whole corpus | 547 ms | 551 ms | 552 ms |
| Without `ref/short-record` | 334 ms | 333 ms | 560 ms |
| Without `ref/short-record`, one file that cannot be ready | | | 339 ms |
| `--federation` | 823 ms | 829 ms | |

On this repository's corpus, the first search for short references in every
document took 212 ms, a second 0 ms, and every document's blockers after it
0 ms. Run on this repository, `compass pending` lists COMPASS-0003 and
COMPASS-0004 as ready, each with one `Proposed` decision flagged, and six
drafts as waiting; `compass assign --dry-run` accepts both ready documents.

## Files

Table: Files added or changed in commits `1278fb3` to `6c2009c`, and with this Log.

| File | Action | Description |
|------|--------|-------------|
| `src/corpus/allocate.lisp` | Modified | Blockers shared with `assign`; the Git name without Git |
| `src/corpus/short.lisp` | Modified | Short references cached per corpus |
| `src/corpus/pending.lisp` | **New** | The listing |
| `src/cli.lisp` | Modified | `compass pending`, its text and JSON; the note in `check` |
| `src/packages.lisp` | Modified | Exports |
| `compass.asd` | Modified | The new source and test files |
| `tests/test-allocate.lisp` | Modified | Tests of the blockers and the cache |
| `tests/test-pending.lisp` | **New** | Tests of the listing, the command, and the note |
| `tests/test-repository.lisp` | Modified | `new-blocker` among the formatting operators |
| `skills/reference/toolchain.md` | Modified | The command, its exit code, and the two kinds of note |
| `skills/compass-review/SKILL.md` | Modified | The two kinds of note; the step after Accept |
| `skills/compass-author/SKILL.md` | Modified | The step after acceptance |
| `commands/opencode/orient.md` | Modified | Step 3 runs `compass pending` |
| `README.md` | Modified | The command, in four places |
| `doc/Log.PendingTool.md` | **New** | This document |
| `doc/INDEX.md` | Modified | Regenerated |

## Metrics

- Test checks: 1317 → 1458 (141 added); regressions: 0.
- New command: 1 (`compass pending`); new note: 1; new rules: 0.
- New source files: 1; new test files: 1; skills changed: 2; commands
  changed: 1.
- Time of a whole-corpus `check`: unchanged within the variation of the runs.

## Outstanding Work

- **The release.** Stage 9 ships `compass pending` with v0.2.1's binaries,
  which COMPASS-0004's roadmap step 7 begins with a spike on the macOS and
  Windows runners; neither the binaries nor the version, still 0.2.0, is done.
- **Statuses and numbers.** COMPASS-D79 to COMPASS-D83 are still `Proposed`,
  in an accepted plan, as are this Log's records. COMPASS-DRAFT-toolchain-D30
  is `Proposed` and provisional in COMPASS-0004, and
  COMPASS-D84 in COMPASS-0003; `compass pending`
  lists both documents as ready, with those records flagged.
- **The open questions** of COMPASS-0017: COMPASS-O53, whether `assign` should
  warn about records not yet accepted; COMPASS-O54, the age of what is waiting;
  and COMPASS-O55, reminders beyond the note.
