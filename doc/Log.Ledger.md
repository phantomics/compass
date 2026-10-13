---
id:            COMPASS-DRAFT-ledger-log
title:         Compass Ledger Development Log
genre:         Log
scope:         component
program:       Compass
component:     toolchain
language:      en
status:        Draft
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-0004
  - COMPASS-DRAFT-toolchain-log
  - COMPASS-0003
  - COMPASS-0001
decisions:
  - COMPASS-DRAFT-ledger-log-D1
  - COMPASS-DRAFT-ledger-log-D2
  - COMPASS-DRAFT-ledger-log-D3
  - COMPASS-DRAFT-ledger-log-D4
  - COMPASS-DRAFT-ledger-log-D5
  - COMPASS-DRAFT-ledger-log-D6
---

# Compass Ledger: Development Log

This document chronicles the allocation ledger of the Compass toolchain. The
ledger is the file that records every number a repository has allocated; the
work also covers the rules that check it, and the commands that allocate
numbers and recover when two branches allocate at once. The work is stages 0 to 4
of version 0.2 of [COMPASS-0004](Plan.Toolchain.md), committed as
`a12a31c`. The Log records the decisions made while coding, what each part of the
code does, what went wrong, and how the result was verified. Later work on the
ledger, and the remaining stages of version 0.2, are appended as
`## Update <date> — <title>` sections.

## Problem

Version 0.1 checked a corpus but could not allocate a number
([COMPASS-DRAFT-toolchain-log](Log.Toolchain.md)). The standard has the steward
assign canonical identifiers at acceptance and never reuse one (§13). Without a
ledger:

- **Nothing recorded which numbers were taken.** `compass next` previewed one
  more than the highest number in the working tree and called the answer
  advisory. Two branches that each took that number would both merge, and the
  corpus would define one identifier twice. Making that impossible is the
  purpose of
  [COMPASS-D5](Plan.Toolchain.md#compass-d5--merge-time-ledger-plus-required-ci-as-the-uniqueness-authority).
- **Assigning by hand was impractical.** Numbering one accepted plan,
  [COMPASS-0007](Plan.AgentWorkflow.md), takes sixteen free
  numbers and 96 rewritten lines in 10 documents, including the anchors of the
  renamed headings and the links to them (see [Verification](#verification)).
- **Accepted documents were waiting.** Four documents are accepted but keep
  their provisional identifiers: that plan,
  [COMPASS-0005](Survey.OperatorMemory.md), and the two Logs
  that precede this one.

## Design Decisions

The work carried out these decisions of the plan:

- [COMPASS-D5](Plan.Toolchain.md#compass-d5--merge-time-ledger-plus-required-ci-as-the-uniqueness-authority):
  the uniqueness guarantee, a ledger checked at merge by a required check.
- [COMPASS-D6](Plan.Toolchain.md#compass-d6--provisional-identifiers-for-register-entries)
  and
  [COMPASS-D7](Plan.Toolchain.md#compass-d7--the-allocation-ledger-holds-immutable-facts-only):
  provisional record identifiers, and a ledger that holds immutable facts only.
- [COMPASS-D13](Plan.Toolchain.md#compass-d13--bootstrapping-the-compass-namespace):
  bootstrapping the `COMPASS` namespace by seeding the ledger with the numbers
  already in use.
- Five decisions recorded in stage 0, all `Proposed`:
  - [COMPASS-D26](Plan.Toolchain.md#compass-d26--one-ledger-per-repository-one-entry-per-line):
    one ledger per repository, one entry per line, four counters per
    namespace, and the ledger rules;
  - [COMPASS-D27](Plan.Toolchain.md#compass-d27--provisional-records-in-a-numbered-document-reuse-its-alias):
    a provisional record in a numbered document reuses the document's alias;
  - [COMPASS-D28](Plan.Toolchain.md#compass-d28--what-compass-assign-does):
    what `compass assign` does;
  - [COMPASS-D29](Plan.Toolchain.md#compass-d29--concurrent-allocations-are-recovered-by-keeping-both-and-renumbering):
    concurrent allocations are recovered by keeping both sides of the conflict
    and renumbering;
  - [COMPASS-D30](Plan.Toolchain.md#compass-d30--records-are-referred-to-by-full-identifier-short-forms-are-found-not-rewritten):
    records are referred to by full identifier; short forms are found, not
    rewritten.

COMPASS-D30 was not in the plan for this round. A trial
`assign` of a real plan showed that short references such as `D6` change
meaning when records are numbered (see [Pitfalls Encountered](#pitfalls-encountered)).
The steward then asked whether short references were a one-time cleanup. They
are: once written as full identifiers, they are rewritten exactly by `assign`
and `renumber`, and they recur only if someone writes new ones. So the toolchain
finds short forms, and leaves rewriting them to an author. Because this decision took the next number, the decisions the plan
had drafted for Git-derived fields, code references, and federation will be
recorded as `COMPASS-D31`, `COMPASS-D32`, and
`COMPASS-D33`.

Two further decisions were made while coding. They are recorded here as
proposals for the steward.

### COMPASS-DRAFT-ledger-log-D1 — Seeding refuses a number defined twice

**Status:** Proposed

**Context:** COMPASS-D13 has `compass init --ledger` record the
canonical identifiers a repository already uses. Classic's four migrated Surveys
each define their own `CLASSIC-O1` to `CLASSIC-O5`, and three of them a
`CLASSIC-O6`. A ledger lists each number once (`ledger/unique`), so a seed must
either choose one definition of each or refuse.

**Decision:** `src/corpus/allocate.lisp:plan-seed@a12a31c` refuses when a
canonical identifier in a namespace the repository owns is defined in more than
one place. The refusal names each such identifier and asks for the copies to be
given provisional identifiers (`<NS>-DRAFT-<slug>-O<n>`) first. Nothing is
written.

**Alternatives:**
- Seed the first definition in path order. Rejected: the ledger would record
  an arbitrary document as the host, as an immutable fact, and the other
  definitions would still be `register/unique` errors.
- Seed every definition. Rejected: the new ledger would fail `ledger/unique`
  at once.

### COMPASS-DRAFT-ledger-log-D2 — The check after an allocation uses the allocation's base

**Status:** Proposed

**Context:** After writing, `assign`, `renumber`, and `init --ledger` run the
check and say whether it finds errors. `ledger/append-only` compares the ledger
with a base revision, by default `HEAD` (COMPASS-D26). During a
merge, `HEAD` is the branch's own tip. `renumber` rebuilds the ledger as the base
revision's ledger followed by the branch's entries (COMPASS-D29),
so the branch's committed lines move. The check therefore reported an error
about the recovery it had just made.

**Decision:** `src/cli.lisp:write-allocation-report@a12a31c` checks against the
revision the allocation consulted: the `--base` given, otherwise the remote's
default branch, and `HEAD` only when there is neither. That is the comparison the
required check makes against a pull request's base.

**Alternatives:**
- Keep `HEAD`. Rejected: every recovery from a conflict would report a false
  error until the merge was committed.
- Leave `ledger/append-only` out of that check. Rejected: when the remote branch
  has moved past a ledger line this branch changed, the error is real, and
  should be seen before the branch is pushed.

## Implementation

Code references below are pinned to `a12a31c`, the commit of stages 0 to 4. The
work began from `f0b03b4`.

### Stage 0: the plan

- **[COMPASS-0004](Plan.Toolchain.md)** gained
  COMPASS-D26 through COMPASS-D30, and its
  front-matter lists them.
- **Other sections of the plan** were updated to match:
  [the uniqueness guarantee](Plan.Toolchain.md#the-uniqueness-guarantee) now
  recovers by keeping both sides, and the
  [identifier lifecycle](Plan.Toolchain.md#identifier-lifecycle), the ledger
  example in [the ledger and manifest](Plan.Toolchain.md#the-ledger-and-manifest),
  and the command list follow the new decisions.
- **The rule table** gained rows for the six ledger rules, `ref/stale-alias`,
  and `ref/short-record`.

Two parts of stage 0 are not done yet; see [Outstanding Work](#outstanding-work).

### Git layer

- **Running Git.** `src/git.lisp:run-git@a12a31c` runs Git with an argument list,
  never through a shell, as `git -C <root> -c core.quotepath=false …`. It
  decodes output as UTF-8 and gives Git no standard input. If Git cannot be
  started, it signals `git-unavailable`; a non-zero exit signals `git-error`,
  unless the caller asks for the status instead. `src/git.lisp:git-available-p@a12a31c`
  caches its answer.
- **Reading files at a revision.** `src/git.lisp:object-name@a12a31c` writes
  object names as `rev:./path`, so that a path is read relative to the corpus
  root, which may be a subdirectory of the repository, rather than the top
  level. `src/git.lisp:git-file-at@a12a31c` returns a file's text at a revision,
  or NIL when the file does not exist there.
- **Added lines.** `src/git.lisp:git-added-lines@a12a31c` lists the lines of a
  file that differ from a base revision, from `git diff` against the working
  tree; a file absent at the base counts as entirely added.
- **The allocator.** `src/git.lisp:git-identity@a12a31c` names the allocator from
  `user.name`, canonicalised by `git check-mailmap`, so this repository's
  ledger records "Andrew Sengul" and not the Git user `phantomics`.
- **The default base.** `src/git.lisp:git-default-base@a12a31c` tries
  `origin/HEAD`, `origin/main`, and `origin/master`, in that order.
- **Other queries.** `src/git.lisp:git-attribute@a12a31c`,
  `src/git.lisp:git-tracked-files@a12a31c`, `src/git.lisp:git-resolve@a12a31c`,
  and `src/git.lisp:git-shallow-p@a12a31c`. The last is not used yet.
- **Not built yet.** The plan's stage 1 also listed `log --follow` and `grep`.
  Nothing in stages 2 to 4 needs them; the Git-derived fields of stage 5 do.

### The ledger

- **Reading a line.** `src/model/ledger.lisp:parse-ledger-line@a12a31c` reads one
  line with v0.1's restricted reader
  ([COMPASS-DRAFT-toolchain-log-D1](Log.Toolchain.md#compass-draft-toolchain-log-d1--the-manifest-reader-never-creates-symbols)),
  so reading a ledger from a pull request runs no code and creates no symbols.
  It reports:
  - a merge-conflict marker, with the advice to run `compass renumber`;
  - a line that holds anything but one property list;
  - an `:id` that is not canonical, or a `:kind` that does not match it;
  - a `:draft` that is not provisional, or not of the same kind;
  - a document entry without `:path`, or with a `:host`;
  - a record entry without a `:host` that names a document, or with a `:path`;
  - a `:date` that is not a calendar day;
  - a blank `:by`.

  An unknown key is a warning.
- **Reading the file.** `src/model/ledger.lisp:parse-ledger-text@a12a31c` skips
  blank and `;` lines and returns the well-formed entries, with `ledger/valid`
  findings for the rest. `src/model/ledger.lisp:ledger@a12a31c` indexes the
  entries by identifier and by alias, keeping duplicates for `ledger/unique` to
  report.
- **Writing.** `src/model/ledger.lisp:format-ledger-entry@a12a31c` writes an entry
  on one line with its keys in a fixed order.
  `src/model/ledger.lisp:ledger-text-with-entries@a12a31c` appends, first adding
  a final newline if the file lacks one. `src/model/ledger.lisp:ledger-header@a12a31c`
  opens a new ledger with three comment lines saying it is append-only and which
  commands maintain it.

### Corpus and lookups

- **Loading.** `src/corpus/corpus.lisp:load-corpus@a12a31c` loads `REGISTRY.sexp`
  from the document directory when it exists, and adds its findings to the load
  findings.
- **Aliases.** `src/corpus/corpus.lisp:corpus-alias-target@a12a31c` gives the
  canonical identifier the ledger assigned to a provisional one.
  `src/corpus/corpus.lisp:corpus-names-of@a12a31c` lists every name of a target:
  its canonical identifier and its aliases.
- **Following aliases.** When nothing is defined under an identifier,
  `src/corpus/corpus.lisp:resolve@a12a31c` follows its alias and returns the
  canonical identifier as a third value. `src/corpus/show.lisp:show@a12a31c`
  and `src/corpus/outline.lisp:document-outline@a12a31c` say so
  (`an alias of COMPASS-D8`). `src/corpus/refs.lisp:find-references@a12a31c` counts a
  reference written with any name of the target, and records the name it used.
- **Definitions.** `src/corpus/corpus.lisp:canonical-definitions@a12a31c` and
  `src/corpus/corpus.lisp:provisional-definitions@a12a31c` list what the
  documents define, for coverage and seeding.
- **Notes.** `src/corpus/corpus.lisp:note@a12a31c` records a note: something the
  check could not do, such as a rule that needs Git. The text report prints notes
  as "Note: …" (`src/report.lisp:write-text@a12a31c`), and the JSON report lists
  them under `notes` (`src/report.lisp:write-json@a12a31c`).

### Rules

- **When they run.** `src/rules/ledger.lisp:ledger-rules-apply-p@a12a31c`: no
  ledger rule runs unless `compass.sexp` declares the namespaces the repository
  owns.
- **`src/rules/ledger.lisp:ledger/unique@a12a31c`** reports an identifier, or an
  alias, that the ledger lists twice.
- **`src/rules/ledger.lisp:ledger/coverage@a12a31c`** reports a canonical
  identifier in an owned namespace that has no entry. Without a ledger, the
  message says to create one with `compass init --ledger`. The rule also reports
  a provisional identifier still defined after the ledger assigned it a number.
- **`src/rules/ledger.lisp:ledger/owned-namespace@a12a31c`** reports a ledger
  entry, or a canonical definition, in a namespace the manifest does not own.
- **`src/rules/ledger.lisp:ledger/append-only@a12a31c`** reports a ledger whose
  text at the base revision is not a prefix of its text now. It names the first
  line that changed (`src/rules/ledger.lisp:first-difference@a12a31c`), and
  reports a deleted ledger with the number of identifiers it allocated.
- **`src/rules/ledger.lisp:ledger/no-union-merge@a12a31c`** reports a `merge`
  attribute on the ledger other than unspecified, unset, set, `text`, or
  `binary`.
- **Without Git.** `src/rules/ledger.lisp:git-rules-root@a12a31c` makes the two
  Git rules record a note instead of a finding when Git is missing or the root
  is not a repository.
- **`src/rules/ledger.lisp:ref/stale-alias@a12a31c`** warns where a document's
  front-matter or text uses an identifier the ledger has assigned.
- **The base revision.** `src/rules/engine.lisp:check-corpus@a12a31c` takes
  `:base` and binds it as `*check-base*` for the rules; `compass check --base REV`
  sets it. `ledger/valid` is a load rule, registered in `src/rules/engine.lisp`.
- **Provisional records in numbered documents.**
  `src/rules/identity.lisp:record-slug-acceptable-p@a12a31c` lets `id/format`
  accept the provisional records of COMPASS-D27. A record in a
  numbered document must use the document's alias, or a slug that names no
  document and is no identifier's alias. One formed from another document's
  identifier is still an error.

### Allocation

- **Counting.** `src/corpus/allocate.lisp:make-counter@a12a31c` returns the next
  free number of a kind. It takes one more than the highest number in three
  places: the ledger, the ledger at the base revision, and the identifiers the
  documents use. `src/corpus/allocate.lisp:corpus-used-identifiers@a12a31c`
  includes identifiers named in front-matter relations and register lists, so a
  number that is mentioned but not defined is not reused.
- **Previewing.** `src/corpus/allocate.lisp:next-identifier@a12a31c` previews a
  number with the same counter and says whether there is a ledger. `compass next`
  says where the number came from ("a preview, from the ledger here and at
  origin/HEAD"), and no longer calls it advisory.
- **`src/corpus/allocate.lisp:plan-assign@a12a31c`** refuses, in this order, when:
  - the manifest declares no namespaces;
  - the file is not a corpus document, its front-matter cannot be read, or its
    identifier is not a valid document identifier;
  - the namespace is not owned;
  - the status is not accepted, unless `--force` is given;
  - the ledger has errors, or allocates a number twice (the advice is
    `compass renumber`);
  - the document or one of its records has already been assigned;
  - there is nothing to number;
  - short references point at the records it would number, unless `--force` is
    given.

  Otherwise it numbers the document, and then its provisional records in heading
  order, skipping memo records still `Draft`. It warns when no base revision was
  found, and lists what `--force` overrode: the status, the short references, or
  both.
- **Seeding.** `src/corpus/allocate.lisp:plan-seed@a12a31c` lists documents first,
  then each kind of record, by namespace and number; it refuses as
  [COMPASS-DRAFT-ledger-log-D1](#compass-draft-ledger-log-d1--seeding-refuses-a-number-defined-twice)
  describes.
- **`src/corpus/allocate.lisp:plan-renumber@a12a31c`** needs a base revision.
  1. `src/corpus/allocate.lisp:strip-conflict-markers@a12a31c` removes the
     markers, keeping both sides and dropping the common-ancestor section of the
     diff3 style. Any line that is still not an entry is a refusal.
  2. This branch's entries are the lines the base revision's ledger does not
     have. Each one whose number is already taken moves to the next free number,
     and the `:host` of entries that name a moved document follows it.
  3. An identifier this branch defines with no entry, as after taking the
     upstream ledger, gets an entry. It keeps its number if that is free, or
     moves if another document defines the same number; either way it has lost
     its alias, and the command says so.
     `src/corpus/allocate.lisp:base-definition-ids@a12a31c` decides what this
     branch defines: what the base revision's version of the same file does not.
     COMPASS-D29 speaks of definitions on added lines; comparing
     the file's definitions gives the same answer without depending on line
     positions.
  4. Moved identifiers are rewritten only on lines this branch added
     (`git-added-lines`). The command warns when it removed conflict markers,
     restored entries without aliases, or moved records that short references
     point at.
- **Stale mentions.** `src/corpus/allocate.lisp:stale-mentions@a12a31c` lists the
  lines of tracked files outside the corpus that name an old identifier. It skips
  the ledger, the index, files over 2 MiB, and files that are not UTF-8 text.
- **Writing.** `src/corpus/allocate.lisp:execute-allocation@a12a31c` writes the
  rewritten documents and the ledger, regenerates `INDEX.md` if one exists, and
  returns the corpus loaded afresh. Planning never writes; this function writes
  only what was planned.
- **The next provisional record.** `src/corpus/allocate.lisp:next-provisional-record@a12a31c`
  implements COMPASS-D27. A provisional document uses its own
  identifier, and a numbered one its alias; a numbered document with no alias
  gets a slug from its file name
  (`src/corpus/allocate.lisp:slug-from-path@a12a31c`: `Plan.AgentWorkflow.md`
  gives `agent-workflow`), with `-2`, `-3`, … added while that slug is taken.
  The number follows every record of that prefix in the document and in the
  ledger's aliases.

### Rewriting

- **Whole identifiers.** `src/corpus/rewrite.lisp:rewrite-line@a12a31c` replaces
  whole identifiers through `src/model/identifier.lisp:replace-identifiers-in-text@a12a31c`.
  The scanner's lookahead keeps `COMPASS-0004` from matching inside
  `COMPASS-D22` or `COMPASS-DRAFT-toolchain-log`.
- **Three passes.** `src/corpus/rewrite.lisp:plan-rewrites@a12a31c` works in
  three passes:
  1. It rewrites identifiers on front-matter, text, and heading lines, never in
     fenced code or block comments.
  2. It reparses each changed document and finds the heading anchors that
     changed (`src/corpus/rewrite.lisp:section-anchor-changes@a12a31c`).
  3. It rewrites links to those anchors at the positions the parser recorded,
     right to left (`src/corpus/rewrite.lisp:replace-fragment@a12a31c`), and
     `ID#anchor` written in text
     (`src/corpus/rewrite.lisp:replace-reference-anchors@a12a31c`), where a
     trailing full stop or colon is not part of the anchor.

  An `eligible` function limits which lines may change; `renumber` passes one
  built from the added lines.
- **Line endings.** `src/corpus/rewrite.lisp:lines-to-text@a12a31c` keeps each
  document's line ending, and its final newline or the lack of one.

### Short references

- **In a line.** `src/corpus/short.lisp:line-short-references@a12a31c` finds short
  forms outside code spans and inline comments, in three ways:
  - lists continuing a full identifier, such as `, D10`, ` to D14`, or `–D4`,
    also after a link's destination;
  - bare tokens such as `D6`;
  - tokens followed by `of`, `in`, or `from` and an identifier, which ties them
    to it.
- **In a document.**
  `src/corpus/short.lisp:document-short-references@a12a31c` joins each text line
  with its neighbours in the paragraph, so that `O4 and O5 of` followed by an
  identifier on the next line is attributed to it, and it skips record headings.
  A bare token is reported only when it matches a record of a likely owner,
  tried in the order `src/corpus/short.lisp:document-own-prefixes@a12a31c` gives:
  1. the document itself and its aliases;
  2. the documents it `relates-to`, and their aliases;
  3. its namespace.

  So a table label such as `M1` is left alone.
- **Who uses it.** `src/corpus/short.lisp:short-references-to@a12a31c` serves
  `assign` and `renumber`; the rule is
  `src/rules/references.lisp:ref/short-record@a12a31c`.

### Command line

- **New commands and options:** `assign`, `renumber`, and `init`. `init` accepts
  only `--ledger` for now; plain `init` is a usage error that says to write
  `compass.sexp` by hand. `next` gained `--in` and `--base`, and `check` gained
  `--base`.
- **Base revisions.** `src/cli.lisp:base-revision@a12a31c` checks a `--base`
  value: it is a usage error if Git is missing, the root is not in a repository,
  or the revision names no commit.
- **Git is required.** `src/cli.lisp:require-git@a12a31c` makes `assign`,
  `renumber`, and `init` usage errors without Git, exit 2.
- **Running an allocation.** `src/cli.lisp:run-allocation@a12a31c` loads the
  corpus, plans, and writes unless `--dry-run` is given. A refusal exits 1, with
  the reason on standard error.
- **The report.** `src/cli.lisp:write-allocation-report@a12a31c` prints:
  - each old identifier with its new one;
  - the lines rewritten, by document;
  - the entries appended;
  - the stale mentions, cut to 100 characters;
  - the warnings;
  - what the check now finds
    ([COMPASS-DRAFT-ledger-log-D2](#compass-draft-ledger-log-d2--the-check-after-an-allocation-uses-the-allocations-base)).

### Tests

- **Git repositories.** `tests/helpers.lisp:call-with-git-repository@a12a31c`
  makes a temporary repository on the branch `main`, with a configured
  identity, whose first commit holds the fixture files. `run-cli` and the ledger
  fixtures moved into the helpers, so that every suite can use them.
- **Four new suites:** `git` (30 checks), `ledger` (66), `allocate` (124), and
  `concurrency` (87).

### Changes to this repository

- **`doc/REGISTRY.sexp`** was created by `compass init --ledger`, with eight
  entries allocated on 2026-10-09 by Andrew Sengul: `COMPASS-0001`,
  `COMPASS-D1` to `COMPASS-D4`, and `COMPASS-O1` to `COMPASS-O3`. The seven
  records name `COMPASS-0003` as their host, since that
  provisional document defines them and the ledger records the host at
  allocation.
- **`skills/reference/toolchain.md`** describes version 0.2:
  - its command table lists `next --in`, `assign`, `renumber`, and
    `init --ledger`, and the commands that take `--base`;
  - a new section, "Numbers and the ledger", tells an agent never to edit the
    ledger; to run `assign` only when the user asks, with `--dry-run` first and
    never `--force` unless asked; to fix short references as the warnings
    suggest; and to run `renumber` after a conflict in the ledger;
  - the list of what is not checked yet no longer mentions the ledger.

  The drift test `every-command-is-documented-for-the-skills` requires the
  command table.
- **`doc/INDEX.md`** was regenerated.

## Design Properties

- **Planning writes nothing.** Every planner returns an allocation;
  `execute-allocation` writes it, and `--dry-run` prints the same report without
  writing.
- **No number is chosen twice.** A number in the ledger, in the ledger at the
  base revision, or among the identifiers the documents use is never chosen
  again.
- **Reading is safe.** Reading a ledger runs no code and creates no symbols, and
  Git is always run with an argument list.
- **Rewriting is narrow.** Only corpus documents are rewritten, never their
  fenced code or block comments; line endings and final newlines are kept; a
  short reference is never rewritten.
- **The ledger rules are opt-in.** None runs without declared namespaces, and
  without Git the rules that need it record a note rather than a finding.
- **Output is deterministic.** A seed is sorted by kind, namespace, and number;
  `assign` numbers records in heading order.

## Pitfalls Encountered

1. **An unexported variable.** `src/corpus/rewrite.lisp` named
   `*identifier-in-text-scanner*`, which `compass.model` did not export. The
   reference created an unbound symbol of the same name in `compass.corpus`, and
   `assign` failed when it ran, as an internal error with exit 2. The variable is
   now exported.
2. **Whole identifiers, wrong meanings.** The first trial `assign` of
   [COMPASS-0007](Plan.AgentWorkflow.md), in a scratch clone,
   rewrote every full identifier correctly, but the short forms after them kept
   their old numbers. `COMPASS-D34 to D4` became
   `COMPASS-D5 to D4`, and `…-D5 to D9` became `COMPASS-D9 to D9`. The rewriter
   was then taught to rewrite short forms too, guessing what each meant from the
   text around it. The second trial showed the guesses going wrong: `O4 and O5`
   of [COMPASS-0005](Survey.OperatorMemory.md) were taken for
   the plan's own questions, and a `D1 to D4` in another document was left
   unchanged. A wrong guess changes a document's meaning silently, so the
   guessing was removed and the short forms are reported instead
   (COMPASS-D30).
3. **A function that replaced an accessor.** A helper named `allocation-base`,
   taking the corpus and a revision, was defined after the `allocation`
   structure, whose `base` slot has an accessor of the same name. The helper
   replaced the accessor, and the report after `renumber`, which reads that
   slot, failed with "invalid number of arguments: 1". The build printed no
   warning. The helper is now `base-or-default`. The concurrency tests found
   this; no earlier test reported a `renumber`.
4. **Format directives outside a format string, again.** Two warnings of
   `assign` and `renumber`, and the `fm/present` message from v0.1, continued
   their lines with `~` and a newline in a string never passed to `format`, so
   the tilde and the indentation were printed. This is v0.1's
   [second pitfall](Log.Toolchain.md#pitfalls-encountered) in another place:
   that fix covered only rule summaries. The three strings now go through
   `format`, and a test checks the `fm/present` message.
5. **A directive that read past the last argument.** The warning about an entry
   restored without its alias used `~:[…~;it becomes ~:*~a~*~]`. The final `~*`
   skipped past the only argument, so `renumber` failed after the upstream
   ledger had been taken, the very case the warning exists for.
6. **A check against the wrong revision mid-merge.** The check after `renumber`
   compared the ledger with `HEAD`, the branch's own tip, and reported an error
   about the recovery it had just made
   ([COMPASS-DRAFT-ledger-log-D2](#compass-draft-ledger-log-d2--the-check-after-an-allocation-uses-the-allocations-base)).
7. **Paths and `--root`.** In the trials, `compass assign doc/Plan.AgentWorkflow.md --root <clone>`
   refused the file as outside the repository: paths on the command line are
   relative to the current directory, not to `--root`, as in v0.1. The trials
   used absolute paths; see [Outstanding Work](#outstanding-work).

## Verification

- **Tests.** `make test` at `a12a31c`, run from a separate worktree of that
  commit: **953 checks, 100% pass.** At `f0b03b4`, the same way: 626 checks. The
  four new suites hold 307 of the 327 new checks; the rest are in the existing
  suites. Stage 1 alone ended at 656 checks.
- **The concurrency scenarios** of the plan, each run in temporary Git
  repositories, where two branches assign from `main` and one merges first:

  Table: The concurrency scenarios, the tests in `tests/test-concurrency.lisp` that run them, and their results at `a12a31c`.

  | Scenario | Expected | Test | Result |
  |---|---|---|---|
  | 1. Two branches allocate | A conflict | `concurrent-allocations-conflict` | Only the ledger conflicts; `ledger/valid` reports the markers |
  | 2. Both sides kept by hand | `ledger/unique` and `id/unique` fail | `keeping-both-sides-is-caught` | Both fail, and `register/unique` |
  | 3. Both sides kept, or the markers left, then `renumber` | Clean | `renumber-recovers-from-markers` (diff3 markers), `renumber-recovers-from-both-sides-kept` | The second branch's numbers move up by one, with the host; clean against `main`; a second `renumber` has nothing to do |
  | 3b. The upstream ledger taken, then `renumber` | Clean, without aliases | `renumber-after-taking-upstream` | Entries restored without `:draft`, with a warning; clean |
  | Only the branch's own lines are rewritten | The other branch's references kept | `renumber-rewrites-only-this-branchs-lines` | The other branch's line keeps its number; the short form after it is warned about |
  | 4. A number typed by hand | `ledger/coverage` fails | `hand-typed-numbers-are-caught` | Only `ledger/coverage` fails |
  | 5. A ledger line upstream wrote is changed | `ledger/append-only` fails | `resolving-with-ours-is-caught` | It fails at line 6 against `main`, and `id/unique` |
  | 6. `merge=union` configured | Merges silently; the check fails | `union-merge-is-caught` | The merge succeeds; `ledger/no-union-merge`, `ledger/unique`, `id/unique`, and `register/unique` fail |
  | 7. Allocations of different kinds | Still conflict | `different-kinds-still-conflict` | They conflict; `renumber` moves nothing and removes the markers; clean |
  | 8. An old provisional identifier still used | A warning | `old-provisional-references-are-flagged` | `ref/stale-alias` warns; no errors |

  The plan first had scenario 3 take the upstream ledger.
  COMPASS-D29 made keeping both sides the recovery, and taking
  upstream became the fallback, 3b.
- **Self-check.** `bin/compass check`, built from `a12a31c`: "Checked 12
  documents: 0 errors, 235 warnings", all `ref/short-record`, with no notes.

  Table: `ref/short-record` warnings in this repository at `a12a31c`, by document.

  | Document | Warnings |
  |---|---|
  | `doc/Plan.Toolchain.md` | 103 |
  | `doc/Plan.AgentWorkflow.md` | 54 |
  | `doc/Log.Toolchain.md` | 29 |
  | `doc/Log.AuthoringAssistance.md` | 14 |
  | `Compass.md` | 8 |
  | `doc/Survey.SecureDevelopment.md` | 8 |
  | `doc/Plan.AuthoringAssistance.md` | 5 |
  | `doc/Survey.OperatorMemory.md` | 5 |
  | `doc/Eval.PriorArt.AgentContext.md` | 5 |
  | `doc/Eval.AgentContext.md` | 3 |
  | `doc/Spec.SemanticBinding.md` | 1 |

- **A real assignment, in a scratch clone** of `f0b03b4` with a seeded ledger,
  using the executable built from the code of `a12a31c`:
  - `compass assign --dry-run` of [COMPASS-0007](Plan.AgentWorkflow.md)
    refuses: 57 short references would change meaning.
  - With `--force`, the plan becomes `COMPASS-0002`, its eleven decisions
    `COMPASS-D5` to `COMPASS-D15`, and its four open questions `COMPASS-O4` to
    `COMPASS-O7`. It rewrites 96 lines in 10 documents and appends 16 ledger
    entries. It lists stale mentions in `doc/README.md`,
    `skills/reference/section-shapes.md`, `src/rules/memo.lisp`,
    `src/vocab.lisp`, and `tests/test-identifier.lisp`, and gives the 57 short references as one
    warning.
  - Afterwards `compass check` found 0 errors and no `ref/stale-alias`
    warnings. The `ref/short-record` warnings rose from 235 to 240, presumably
    because five bare short forms now matched one of the new records.
  - `compass show COMPASS-D37` printed the record
    `COMPASS-D8`, saying it had followed an alias. The clone was then reset.
- **Seeding this repository.** `compass init --ledger --dry-run` listed the
  eight entries, and the real run reported "compass check finds no errors."
- **The other repositories**, checked with `--skip-unmarked` by the executable
  of `a12a31c`:

  Table: Results of `compass check --skip-unmarked` on the ancestor repositories.

  | Repository | Commit | Documents | Errors |
  |---|---|---|---|
  | classic | `e8e9b3e` | 5 | 24 `ledger/coverage`; 23 `register/unique` |
  | origin | `fcd57f8`, manifest uncommitted | 1 | 5 `ledger/coverage` |
  | lexter | `4d6a89d`, manifest uncommitted | 0 | 0 |

  The `register/unique` errors are those v0.1 found. The `ledger/coverage`
  errors are new: both manifests declare their namespaces, and neither
  repository has a ledger yet.
- **The executable**, built from `a12a31c`: 48,995,272 bytes (46.7 MiB), or
  12.0 MiB with `gzip -9`. `compass check` of this repository takes about
  270 ms, against about 95 ms at `f0b03b4`. About 125 ms of that is
  `ref/short-record`, and about 30 ms the two ledger rules that run Git.
- **Not verified:**
  - the `DEPS=ocicl` build;
  - platforms other than Linux x86-64 with Git 2.30;
  - a shallow clone;
  - a corpus in a subdirectory of its repository;
  - the default base in the tests, whose repositories have no remote. It was
    seen to work in the scratch clone (`origin/HEAD`).

## Files

Table: Files added or changed in commit `a12a31c`.

| File | Action | Description |
|------|--------|-------------|
| `src/git.lisp` | **New** | The Git layer, package `compass.git` |
| `src/model/ledger.lisp` | **New** | Ledger entries: reading, validating, formatting, appending |
| `src/rules/ledger.lisp` | **New** | The ledger rules and `ref/stale-alias` |
| `src/corpus/allocate.lisp` | **New** | `assign`, `renumber`, seeding, `next`, the next provisional record |
| `src/corpus/rewrite.lisp` | **New** | Rewriting identifiers and the anchors that change with them |
| `src/corpus/short.lisp` | **New** | Finding short references and suggesting what each means |
| `src/corpus/corpus.lisp` | Modified | Loads the ledger; aliases; definitions; notes; formatted `fm/present` message |
| `src/corpus/show.lisp` | Modified | Follows aliases |
| `src/corpus/outline.lisp` | Modified | Follows aliases |
| `src/corpus/refs.lisp` | Modified | Counts references written with an alias |
| `src/corpus/index.lisp` | Modified | `next-identifier` moved to `allocate.lisp` |
| `src/model/identifier.lisp` | Modified | `replace-identifiers-in-text` |
| `src/rules/engine.lisp` | Modified | `ledger/valid`; `*check-base*`; notes reset per check |
| `src/rules/identity.lisp` | Modified | `id/format` accepts the provisional records of COMPASS-D27 |
| `src/rules/references.lisp` | Modified | `ref/short-record` |
| `src/report.lisp` | Modified | Notes in the text and JSON reports |
| `src/cli.lisp` | Modified | `assign`, `renumber`, `init`, `next --in`, `--base` |
| `src/packages.lisp` | Modified | `compass.git`, and the new exports, including the identifier scanner |
| `compass.asd` | Modified | The new source files and test suites |
| `tests/helpers.lisp` | Modified | Git repositories, `run-cli`, ledger fixtures |
| `tests/test-git.lisp` | **New** | The Git layer |
| `tests/test-ledger.lisp` | **New** | The ledger's format and rules, and aliases |
| `tests/test-allocate.lisp` | **New** | Seeding, `assign`, `next --in`, rewriting, short references |
| `tests/test-concurrency.lisp` | **New** | The concurrency scenarios |
| `tests/test-cli.lisp` | Modified | `next` says "a preview"; `run-cli` moved to the helpers |
| `tests/test-corpus.lisp` | Modified | `next-identifier` without a ledger |
| `tests/test-rules.lisp` | Modified | The `fm/present` message is formatted |
| `doc/REGISTRY.sexp` | **New** | This repository's ledger, seeded |
| `doc/Plan.Toolchain.md` | Modified | COMPASS-D26 through COMPASS-D30, and the sections they change |
| `doc/INDEX.md` | Modified | Regenerated |
| `skills/reference/toolchain.md` | Modified | Version 0.2 commands; "Numbers and the ledger" |

## Metrics

- Test checks: 626 at `f0b03b4`; 953 at `a12a31c`.
- Regressions: 0.
- Rules: 25 at `f0b03b4`; 33 at `a12a31c`.
- Commands: 9 at `f0b03b4`; 12 at `a12a31c`.
- Source files: 25 at `f0b03b4`; 31 (6,396 lines) at `a12a31c`, of which the six
  new files hold 1,556 lines.
- Test files: 13 at `f0b03b4`; 17 (2,510 lines) at `a12a31c`, of which the four
  new suites hold 1,009 lines.

## Outstanding Work

The remaining stages of version 0.2, as planned, adjusted for what stages 0 to
4 already did. Each stage ends with the tests passing. Throughout, verification
is `make test` under both Quicklisp and ocicl, `compass check` on all four
repositories, the concurrency tests, and a dry-run `assign` of a real document in
a scratch clone.

- **Stage 0, the rest.** Record `COMPASS-D31` (Git-derived
  fields: a document not yet committed derives its authors and dates from the
  working tree; a file outside any repository is an error),
  `COMPASS-D32` (code references, resolving
  COMPASS-O7), and `COMPASS-D33` (federation). Split the plan's
  [baseline releases](Plan.Toolchain.md#baseline-releases): v0.2 is this round,
  and v0.2.1 the release binaries. *Done in `a9c6dd9`; see
  [Update 2026-10-10 — Git-derived fields, code references, federation, and CI](#update-2026-10-10--git-derived-fields-code-references-federation-and-ci).*
- **Stage 5: Git-derived fields and code references.** `git/derivable`,
  `ref/code-pinned`, and `ref/code-exists`; `memo/basis` then checks that the
  revision exists.
  - `ref/code-pinned` reports a path with a location (`:symbol`, `#L`, or `:42`)
    and no `@revision`; a bare file name does not count.
  - `ref/code-exists` reports a missing revision or path as an error, and a
    missing symbol as a warning. Symbols are found by Lisp definition patterns,
    a small table of patterns for other languages, and a plain-text fallback.
  - References into other repositories are checked through `--federation`, and
    a shallow clone reports them as unverified.
  - The Git layer gains `log --follow` with `.mailmap`, and `grep`.

  *Done in `a9c6dd9`, without `grep`, which nothing needed; see
  [Update 2026-10-10 — Git-derived fields, code references, federation, and CI](#update-2026-10-10--git-derived-fields-code-references-federation-and-ci).*
- **Stage 6: remaining checks.** `index --check` and the `index/current` rule;
  `check --federation`, which loads each repository listed under
  `:federation` and reports a namespace claimed by two of them
  (`COMPASS-D33`, which partly answers
  COMPASS-O6).
  `check --base` was done in stage 2. *Done in `a9c6dd9`; see
  [Update 2026-10-10 — Git-derived fields, code references, federation, and CI](#update-2026-10-10--git-derived-fields-code-references-federation-and-ci).*
- **Stage 7: new commands.** `compass init`, with non-interactive flags, writes
  a starting manifest, and `compass manifest --json`. `compass init --ledger`
  was done in stage 3. *Done in `a9c6dd9`; see
  [Update 2026-10-10 — Git-derived fields, code references, federation, and CI](#update-2026-10-10--git-derived-fields-code-references-federation-and-ci).*
- **Stage 8: CI and dependencies.**
  - `ocicl.csv`, with `make test DEPS=ocicl` verified locally;
  - `.github/workflows/compass-check.yml`, run on pull requests and pushes under
    both Quicklisp and ocicl, with full history, running
    `compass check --base <pull request base>`, `index --check`, and
    `make test`. The workflow file is checked to be valid YAML; it first truly
    runs when pushed;
  - `.github/CODEOWNERS`, assigning the ledger to `@phantomics`;
  - `scripts/pre-commit` and `make hooks`.

  *Done in `a9c6dd9`, except that the workflow has not yet run; see
  [Update 2026-10-10 — Git-derived fields, code references, federation, and CI](#update-2026-10-10--git-derived-fields-code-references-federation-and-ci).*
- **Stage 9: bootstrap.** The ledger was seeded in stage 3. What remains:
  - relabel the rows of the §23 table, as `ND1`… and `GO1`…, per
    COMPASS-D13;
  - amend `Compass.md` for the accepted decisions due in v0.2: §13 for
    COMPASS-D6 and COMPASS-D7 (the ledger
    replaces the "registry"; provisional identifiers for records); and the
    amendments of COMPASS-D9 (§6, §7),
    COMPASS-D10 (§11 to §13), and COMPASS-D20
    (the §8 example);
  - update the vocabulary standings, and the skills' reference notes that still
    describe those amendments as pending;
  - this repository must then check clean, including the code-reference and
    Git rules.

  *Done in `ccb28e9`; see [Update 2026-10-10 — Bootstrap, the amended standard, skills, and version 0.2.0](#update-2026-10-10--bootstrap-the-amended-standard-skills-and-version-020).*
- **Stage 10: skills.**
  - `toolchain.md`: the exit codes, and a shorter list of what is not checked
    yet. The command table was done in stage 3.
  - `compass-author`: `next --in`, and `assign` only when the user asks.
  - `compass-review`: `check --base` for branches, and the ledger findings.
  - `compass-lookup`: following aliases.

  The version becomes 0.2.0, with README updates.

  *Done in `ccb28e9`; see [Update 2026-10-10 — Bootstrap, the amended standard, skills, and version 0.2.0](#update-2026-10-10--bootstrap-the-amended-standard-skills-and-version-020).*
- **Stage 11: a checkpoint commit**, then an update to this Log, with
  references pinned to that commit. *Done: the checkpoint is `ccb28e9`, and the
  update is [Update 2026-10-10 — Bootstrap, the amended standard, skills, and version 0.2.0](#update-2026-10-10--bootstrap-the-amended-standard-skills-and-version-020).*

Other work found along the way:

- **Short references.** This repository has 235 `ref/short-record` warnings,
  listed in [Verification](#verification). They are the steward's to rewrite
  by hand, guided by the suggestions; until those in and around
  [COMPASS-0007](Plan.AgentWorkflow.md) are rewritten, `assign`
  refuses it.
- **Assigning the accepted documents.** The four documents listed under
  [Problem](#problem) can be numbered once their short references are
  rewritten.
- **The other repositories' ledgers.** Origin can be seeded with
  `compass init --ledger`. Classic must first give the duplicated open
  questions of its Surveys provisional identifiers
  ([COMPASS-DRAFT-ledger-log-D1](#compass-draft-ledger-log-d1--seeding-refuses-a-number-defined-twice)),
  and the note in its `AGENTS.md` should say so. *Origin's ledger was seeded in
  its commit `7ef2f48`, and Classic's note updated in its commit `be4fe84`; see
  [Update 2026-10-10 — Bootstrap, the amended standard, skills, and version 0.2.0](#update-2026-10-10--bootstrap-the-amended-standard-skills-and-version-020).*
- **`compass check` during a merge.** Without `--base`, the check compares with
  `HEAD`. After `renumber` and before the merge is committed, it therefore
  reports `ledger/append-only`, as the report after `renumber` did before
  [COMPASS-DRAFT-ledger-log-D2](#compass-draft-ledger-log-d2--the-check-after-an-allocation-uses-the-allocations-base).
  While a merge is in progress, the default could be the commit being merged
  in.
- **Paths and `--root`.** Paths on the command line are relative to the current
  directory even with `--root`. Resolving them against `--root`, as `git -C`
  does, would match what users expect. *Done in `a9c6dd9`: a relative path that
  names nothing in the current directory is tried under `--root`; see
  [Update 2026-10-10 — Git-derived fields, code references, federation, and CI](#update-2026-10-10--git-derived-fields-code-references-federation-and-ci).*
- **Guards against two recurring mistakes.** A test that no message contains a
  `~` followed by a newline, and a build that fails when a definition replaces
  another (pitfalls 3 and 4). *Done in `ccb28e9`; see [Update 2026-10-10 — Bootstrap, the amended standard, skills, and version 0.2.0](#update-2026-10-10--bootstrap-the-amended-standard-skills-and-version-020).*
- **The speed of `ref/short-record`.** It nearly tripled the time of a check. It
  could skip lines that contain no capital `D`, `O`, or `M` followed by a digit.
- **Acceptance.** This Log is `Draft`, and its two decisions, like
  COMPASS-D26 through COMPASS-D30, are
  `Proposed`.

## Update 2026-10-10 — Git-derived fields, code references, federation, and CI

Commit `a9c6dd9` carried out the rest of stage 0 and stages 5 to 8 of version
0.2: Git-derived fields, the checking of code references, the generated index's
check, federation, `compass init` and `compass manifest`, and the CI workflow,
lockfile, and hooks. Code references in this section are pinned to `a9c6dd9`.

### Problem

After `a12a31c` the ledger kept numbers unique, but three other kinds of claim
in a document were still unchecked, and nothing yet ran the checks on every
change:

- **Fields left to Git.** §7 lets `authors`, `created`, and `updated` be
  omitted and derived from Git. Twelve of this repository's thirteen documents
  omit `created`, and the toolchain could neither derive it nor say when it
  could not be derived.
- **Code references.** §9 makes commit-pinned references mandatory in a `Log`
  and a `Plan`. The 160 in this repository's documents, 71 of them in this Log,
  had been verified only by hand, and only `memo/basis` looked at their form.
- **Other repositories.** References into Classic were counted as unverified,
  and nothing could tell whether the repositories listed under `:federation`
  existed or owned what they were listed for.
- **The index and the ledger in CI.** `compass index` wrote `INDEX.md`, but
  nothing reported a stale one, and no workflow ran `compass check` against the
  branch a pull request merges into, on which `ledger/append-only` depends.
- **Adoption.** A repository not written in Lisp had to write its manifest by
  hand, and a program reading it had to parse an s-expression.

### Design Decisions

The work carried out the three decisions recorded in the plan as the rest of
stage 0, all `Proposed`:

- [COMPASS-D31](Plan.Toolchain.md#compass-d31--git-derived-fields-including-for-files-not-yet-committed):
  Git-derived fields, including for files not yet committed;
- [COMPASS-D32](Plan.Toolchain.md#compass-d32--which-code-references-are-checked-and-how-deeply):
  which code references are checked, and how deeply. It resolves
  COMPASS-O7;
- [COMPASS-D33](Plan.Toolchain.md#compass-d33--federation-checks-are-opt-in-and-one-hop-deep):
  federation checks are opt-in and one hop deep. It partly answers
  COMPASS-O6.

The plan's [baseline releases](Plan.Toolchain.md#baseline-releases) now split
version 0.2 from version 0.2.1, which holds the release binaries, the setup
action, the container image, and the `.pre-commit-hooks.yaml` definition.

Two further decisions were made while coding. They are recorded here as
proposals for the steward, as records at the same level as this section, the
level §8 gives a record's heading.

### COMPASS-DRAFT-ledger-log-D3 — An uppercase prefix in a code span is a namespace only when known, or when a path follows

**Status:** Proposed

**Context:** In the §9 grammar a code reference into another repository starts
with its namespace and a colon. A file whose name is uppercase, such as a
`README` or a `Makefile`, followed by a colon and a symbol has the same shape.
Read as a namespace, the file name would make the reference unverifiable
forever; read as a path, a real reference into a namespace this repository
does not list would be reported as a missing file.

**Decision:** `src/corpus/code.lisp:parse-code-mention@a9c6dd9` reads the prefix
as a namespace if this repository owns it, lists it under `:federation`, or has
documents in it (`src/corpus/code.lisp:known-namespace-p@a9c6dd9`), or if what
follows the colon is itself a path
(`src/corpus/code.lisp:path-like-p@a9c6dd9`: it contains `/`, ends in a known
extension, or names a file in the working tree). Otherwise the prefix is the
path and what follows is the symbol. A reference into an unknown namespace is
then counted as unverified, never reported.

**Alternatives:**
- Always read an uppercase prefix as a namespace. Rejected: a reference to a
  symbol in a `Makefile` could never be checked.
- Read it as a namespace only when known. Rejected: a pinned reference into a
  repository not yet listed under `:federation` would become an error about a
  missing file, where §9 asks only that it be pinned.

### COMPASS-DRAFT-ledger-log-D4 — The index is checked only where one exists, and line endings do not count

**Status:** Proposed

**Context:** COMPASS-D10 has each namespace's `INDEX.md`
generated and verified with `compass index --check`. Classic and Origin have no
index yet, nor has a corpus whose first document is still being written. A
clone made with Git's `core.autocrlf` converts the committed index to CRLF line
endings on checkout, though its content is current.

**Decision:** The rule `src/rules/federation.lisp:index/current@a9c6dd9` runs
only when `INDEX.md` exists; `compass index --check`, which a person or a
workflow asks for explicitly, reports a missing index and exits 1. Both compare
the index line by line (`src/rules/federation.lisp:index-difference@a9c6dd9`),
so line endings do not count, and both name the first line that differs.

**Alternatives:**
- Require an index in every repository. Rejected: every new corpus would fail
  its first check, before it had anything to index.
- Compare the files byte for byte. Rejected: a checkout on Windows would report
  a stale index that is not.

### Implementation

#### Git layer

- **Input.** `src/git.lisp:run-git@a9c6dd9` accepts a string for Git's
  standard input, and an external format, so that the batch commands below can
  read file contents as bytes.
- **Many objects in one process.** `src/git.lisp:git-object-types@a9c6dd9` asks
  `git cat-file --batch-check` the type of every object name at once: a
  revision's commit, or a path at a revision. `src/git.lisp:git-read-objects@a9c6dd9`
  reads the contents of many files at once with `git cat-file --batch`, splitting
  the output by the byte sizes Git reports, and decodes each file that is UTF-8
  text (`src/git.lisp:octet-string-text@a9c6dd9`).
- **The history of one file.** `src/git.lisp:git-log-follow@a9c6dd9` lists the
  commits that touched a file, following renames, oldest first, each with its
  author as `.mailmap` names them and its author date.
  `src/git.lisp:git-file-status@a9c6dd9` says whether a file is untracked,
  modified, or clean, and `src/git.lisp:git-committed-files@a9c6dd9` lists the
  files in `HEAD`.

The plan's stage 1 also listed `git grep`; nothing needed it.

#### Git-derived fields

- **What Git can say, asked once.** `src/corpus/corpus.lisp:corpus-cached@a9c6dd9`
  keeps values for the life of a loaded corpus.
  `src/corpus/history.lisp:corpus-git-state@a9c6dd9` asks once whether Git runs,
  whether the root is in a work tree, who the current user is, which files are
  committed, and whether the clone is shallow.
  `src/corpus/history.lisp:repository-usable-p@a9c6dd9` caches the first two
  answers for each repository root; the ledger rules use it too.
- **Derivable or not.** `src/corpus/history.lisp:underivable-reason@a9c6dd9`
  says why a document's fields cannot be derived: the file is outside a work
  tree, or it has no commit and Git has no `user.name` to credit. The rule
  `src/rules/frontmatter.lisp:git/derivable@a9c6dd9` reports that for the
  required fields left out, `created` and `authors`; without Git it records a
  note. It runs no `git log`: what it needs takes a fixed handful of Git
  processes per check, however many documents there are.
- **The values.** `src/corpus/history.lisp:document-derived-fields@a9c6dd9`
  computes `authors`, `created`, and `updated` from the file's history, and
  adds the current user and today's date for work not yet committed. A value in
  front-matter wins. Each value carries its source, and in a shallow clone
  `created` carries a note that it may be late.
- **Shown in `outline`.** `src/corpus/outline.lisp:document-outline@a9c6dd9`
  attaches the three fields, and `src/cli.lisp:write-outline-fields@a9c6dd9`
  prints them under the document's title, as in "Created: 2026-10-10 (Git)".
  The JSON outline (`src/cli.lisp:outline-json@a9c6dd9`) gains `fields`.

#### Code references

- **Finding them.** `src/corpus/code.lisp:document-code-mentions@a9c6dd9` reads
  each code span of a document's text and headings with
  `src/corpus/code.lisp:parse-code-mention@a9c6dd9`, and keeps those that are
  pinned or name a place in a file. A bare file name, a rule name such as
  `ledger/unique`, and an example of the grammar are left out
  ([COMPASS-DRAFT-ledger-log-D3](#compass-draft-ledger-log-d3--an-uppercase-prefix-in-a-code-span-is-a-namespace-only-when-known-or-when-a-path-follows)).
- **`ref/code-pinned`.** `src/rules/code.lisp:ref/code-pinned@a9c6dd9` reports a
  reference that names a symbol or lines without a revision, at the severity
  `src/rules/code.lisp:pinning-severity@a9c6dd9` gives: an error in a `Log` or
  `Plan`, a warning elsewhere. A line written as a colon and a number is
  reported in either case, with `#L` and the number as the form to write.
- **Resolving them.** `src/corpus/code.lisp:resolve-code-mentions@a9c6dd9` groups
  the pinned references by the repository they are read in
  (`src/corpus/code.lisp:code-mention-root@a9c6dd9`). For each, one Git process
  finds every revision, and the path of every reference that names no place in
  its file (`src/corpus/code.lisp:ensure-revisions@a9c6dd9`); a second reads
  only the files whose symbols or lines are to be found.
  `src/corpus/code.lisp:check-code-object@a9c6dd9` then classifies each
  reference: resolved, a missing revision or path, a directory where a file was
  meant, lines past the end of the file, or a symbol not found. A revision
  missing from a shallow clone, and a reference into a namespace that is not
  loaded, are unverified.
- **`ref/code-exists`.** `src/rules/code.lisp:ref/code-exists@a9c6dd9` reports
  a missing revision or path as an error, and a missing symbol, lines past the
  end, or a directory as a warning. It leaves a revision in a memo's
  `**Basis:**` to `src/rules/memo.lisp:memo/basis@a9c6dd9`, which now requires a
  pinned revision to exist where Git can tell
  (`src/corpus/code.lisp:revision-status@a9c6dd9`).
- **Finding a symbol.** `src/corpus/code.lisp:symbol-defined-p@a9c6dd9` scans
  only the lines that contain the symbol
  (`src/corpus/code.lisp:occurrences@a9c6dd9`), and accepts a line where a
  definition pattern captures exactly that name
  (`src/corpus/code.lisp:line-defines-p@a9c6dd9`):
  - in Lisp files, the forms of `src/corpus/code.lisp:*lisp-definition-scanners*@a9c6dd9`:
    a `(def…` or `(define-…` form, also with a quoted name, FiveAM's
    `(test …`, and slot readers and accessors, compared without regard to case
    and with any package prefix removed;
  - in Python, JavaScript and TypeScript, Go, Rust, C and C++, and shell, the
    patterns of `src/corpus/code.lisp:*definition-scanners*@a9c6dd9`;
  - in any other file, the symbol as a whole token
    (`src/corpus/code.lisp:token-at-p@a9c6dd9`).

#### Federation and the index

- **Loading.** `src/corpus/federation.lisp:load-federation@a9c6dd9` loads each
  repository listed under `:federation`, at its path relative to this
  repository's root (`src/corpus/federation.lisp:federation-directory@a9c6dd9`),
  with files lacking front-matter skipped, and records a repository that is
  missing, has no manifest, or does not own the namespace it is listed for.
- **Resolving into it.** Once the federation is loaded,
  `src/corpus/corpus.lisp:find-document@a9c6dd9`,
  `src/corpus/corpus.lisp:find-record@a9c6dd9`,
  `src/corpus/corpus.lisp:namespace-loaded-p@a9c6dd9`, and
  `src/corpus/corpus.lisp:corpus-alias-target@a9c6dd9` also look in the
  federated corpora and ledgers
  (`src/corpus/corpus.lisp:federated-corpora@a9c6dd9`). A link that leaves the
  repository is followed into the federated repository it lands in
  (`src/corpus/federation.lisp:federated-location@a9c6dd9`) and checked there
  for its file, anchor, and link text
  (`src/rules/references.lisp:check-federated-link@a9c6dd9`). A code reference
  prefixed with a federated namespace is read in that repository's Git
  (`src/corpus/federation.lisp:namespace-root@a9c6dd9`).
- **The rules.** `src/rules/federation.lisp:federation/path@a9c6dd9` reports
  the federated repositories found missing, without a manifest, or not owning
  their namespace, at the line of `compass.sexp` that lists them
  (`src/rules/federation.lisp:manifest-entry-line@a9c6dd9`).
  `src/rules/federation.lisp:federation/namespace@a9c6dd9` reports a namespace
  owned both here and by a federated repository, or by two federated ones.
  Neither runs without `--federation`.
- **Aliases in front-matter.** `src/rules/references.lisp:check-identifier-reference@a9c6dd9`
  accepts a `relates-to` written with an alias the ledger records; before, it
  was reported as undefined on top of the `ref/stale-alias` warning, a gap left
  by stage 2.
- **The index.** `src/rules/federation.lisp:index/current@a9c6dd9`, and the new
  `--check` of `compass index`, compare the index with what would be written
  ([COMPASS-DRAFT-ledger-log-D4](#compass-draft-ledger-log-d4--the-index-is-checked-only-where-one-exists-and-line-endings-do-not-count)).
  `src/util.lisp:first-difference@a9c6dd9`, which `ledger/append-only` already
  used, moved to the utilities to name the first line that differs.

#### Command line

- **`compass check --federation`** loads the federation before checking, and
  notes when `compass.sexp` lists none.
- **`compass init`** without `--ledger` now writes a starting manifest
  (`src/cli.lisp:init-manifest@a9c6dd9`). It infers the document directory, `doc/`
  or `docs/` (`src/cli.lisp:infer-doc-directory@a9c6dd9`); the namespaces the
  documents use, unless `--namespace` names them; and the steward, as the Git
  user, unless `--steward` names one. `--federation NS=PATH`
  (`src/cli.lisp:parse-federation-option@a9c6dd9`) adds federated repositories,
  and `--solo` declares the steward's solo approval. The text comes from
  `src/model/manifest.lisp:manifest-text@a9c6dd9`, and is read back before the
  command reports success. It refuses to overwrite a manifest, and
  `init --ledger` refuses the manifest's flags.
- **`compass manifest --json`** prints the manifest's namespaces, document
  directory, ledger path, federation, commands, stewards, and authorities
  (`src/cli.lisp:manifest-json@a9c6dd9`), and reports a malformed manifest's
  findings on standard error with exit 1.
- **Paths and `--root`.** `src/cli.lisp:repository-path@a9c6dd9` takes a
  relative path from the current directory when it names something there, and
  otherwise from `--root`.

#### CI, dependencies, and hooks

- **`ocicl.csv@a9c6dd9`** pins, by digest, the four dependencies and the four
  packages they depend on (ten systems in eight packages), as the local ocicl
  v2.6.6 installed them.
  `Makefile@a9c6dd9` gains `make deps`, which runs `ocicl install` under
  `DEPS=ocicl`, and `make hooks`.
- **`.github/workflows/compass-check.yml@a9c6dd9`** runs on pull requests and on
  pushes to the default branch, in a matrix of Quicklisp (pinned to the
  2023-06-18 dist) and ocicl (v2.6.6, built from source, with
  `OCICL_LOCAL_ONLY=1`), with the full history checked out. It builds the
  executable, runs `compass check --base` against the pull request's base
  branch (or the commit a push replaced), then `compass index --check`, then
  `make test`.
- **`.github/CODEOWNERS@a9c6dd9`** assigns the ledger to `@phantomics`, so that
  the steward approves every allocation once code-owner review is required.
- **`scripts/pre-commit@a9c6dd9`** regenerates a stale `INDEX.md` and stages it,
  then refuses the commit if `compass check` finds errors. It uses
  `bin/compass`, a `compass` on the `PATH`, or the one `$COMPASS` names.
- **`README.md`** describes the dependencies, the workflow, the branch-protection
  settings the uniqueness guarantee depends on, and the hook.
- **`skills/reference/toolchain.md`** lists `check --federation`,
  `index --check`, `init`, and `manifest --json`, explains federation, and no
  longer lists Git-derived fields and code references as unchecked.

#### Tests

- **Two new suites.** `tests/test-code-refs.lisp@a9c6dd9` (98 checks) covers the
  Git queries, derived fields, `git/derivable`, what is and is not a code
  reference, references that resolve and do not, pinning, unverified
  references, memo bases, a shallow clone made with `git clone --depth 1`, and
  symbol patterns. `tests/test-federation.lisp@a9c6dd9` (41 checks) covers
  federated references, the two federation rules, federated code references,
  `check --federation`, and the index check, in sibling temporary
  repositories.
- **Fixtures.** `tests/helpers.lisp:doc@a9c6dd9` writes `created` only when
  asked, and `tests/helpers.lisp:check-files@a9c6dd9` can make its repository a
  Git repository. The test of the genre templates commits a real file for the
  Memo template's basis to cite.

### Pitfalls Encountered

1. **Fixtures outside Git.** Once the new rules existed, twelve checks in eight
   tests failed. Most failed because the test document builder omits `created`,
   and most fixtures are plain temporary directories, where nothing can be
   derived. The rule was right. The tests that run every rule now give
   `created`, or commit their files.
2. **A revision that never existed.** The rest failed because the memo
   fixtures, and the Memo template filled in by the skills test, cited code at a
   made-up revision, which `memo/basis` now looks up. The template test now
   commits a file and cites its real revision.
3. **A note that vanished.** `compass check --federation` noted when the
   manifest lists no federation, but before the check; the check begins by
   clearing the notes (`src/rules/engine.lisp:check-corpus@a9c6dd9`), so the note
   never appeared. It is now made after the check.
4. **A function replaced, again.** The manifest's commands had an accessor named
   `command-name`, and the command line's own `command` structure defines an
   accessor of the same name in a package that uses the manifest's. Since v0.1
   the second had silently replaced the first; nothing had read a manifest
   command's name until `manifest --json`. This is the mistake of
   [pitfall 3](#pitfalls-encountered) above, in another place; the manifest's
   accessor was removed in favour of `manifest-command-name`. Neither the build
   nor the tests had reported it.
5. **A slow first version.** `ref/code-exists` first added about 135 ms to a
   check of this repository. Profiling showed most of it in searching whole
   files case-insensitively, decoding every file read through a vector of
   bytes, and counting lines by splitting each file. It now reads only the files
   whose symbols or lines are wanted, decodes UTF-8 in one pass, counts lines in
   place, and runs patterns only over lines that contain the symbol: about 50 to
   75 ms.
6. **Edits by text substitution.** Twice a scripted edit left a form unbalanced
   (`src/corpus/code.lisp`, then `src/corpus/federation.lisp`). The reader
   reported the form's first line, so each was found by reading the form, not
   the message.
7. **Paths in two forms.** The manifest records its own location as a pathname,
   and `federation/path` first passed it where a repository-relative string was
   expected, failing with a type error in the first federation test.

### Verification

- **Tests.** `make test` at `a9c6dd9`, run from a separate worktree of that
  commit: **1142 checks, 100% pass**, under both `DEPS=ql` and `DEPS=ocicl`
  (with `OCICL_LOCAL_ONLY=1` and the dependencies of `ocicl.csv`).
- **The executable**, built from that worktree, reports
  `compass 0.1.0 (commit a9c6dd96e2ce, SBCL 2.3.4, linux x86-64)`, without
  `-dirty`. It is 49,257,440 bytes (47.0 MiB), or 12.0 MiB with `gzip -9`.
- **Self-check.** `compass check` of this repository at `a9c6dd9`: "Checked 13
  documents: 0 errors, 234 warnings", all `ref/short-record`, with 3
  references unverified. `compass index --check`: current.
- **Code references.** The documents hold 160 pinned references, and no
  located reference without a revision:

  Table: Pinned code references in this repository's documents at `a9c6dd9`, by revision.

  | Revision | References | Resolved |
  |---|---|---|
  | `a12a31c` | 71 | 71 |
  | `4e4549a` | 46 | 46 |
  | `07b9643` | 20 | 20 |
  | `ee5f765` | 12 | 12 |
  | `fcdec0c` | 8 | 8 |
  | `6e4f02d`, in Classic | 3 | unverified; 3 with `--federation` |

  They are in this Log (71), [COMPASS-DRAFT-toolchain-log](Log.Toolchain.md)
  (62), [COMPASS-DRAFT-authoring-assistance-log](Log.AuthoringAssistance.md)
  (24), and one each in three other documents. Every reference that names a
  symbol or lines names a Lisp file, and every symbol was found by a definition
  form; the patterns for other languages are so far exercised only by the
  tests.
- **Federation.** With `--federation`, from this repository's place beside
  Classic, Origin, and Lexter: 0 errors, and no reference left unverified. From
  the worktree, whose siblings do not exist, `--federation` reports the three
  repositories under `federation/path`, as it should; CI therefore checks
  without it.
- **Derived fields.** Every document derives `created` and `updated` from Git;
  this Log, which omits `authors`, derives "Andrew Sengul" from commits made as
  `phantomics`, through `.mailmap`.
- **The other repositories**, with `--skip-unmarked`, with and without
  `--federation`: unchanged from [Verification](#verification) above. Classic
  has 24 `ledger/coverage` and 23 `register/unique` errors, Origin 5
  `ledger/coverage`, and Lexter none. None of the new rules adds a finding.
- **A real assignment**, in the scratch clone with the executable of this
  batch: the result of stage 3 is unchanged, with 16 numbers, 96 lines rewritten
  in 10 documents, and no errors afterwards.
- **The hook**, run in a temporary repository: it regenerated and staged a stale
  `INDEX.md` and let the commit proceed, then refused one with a `vocab/genre`
  error.
- **The workflow** parses as YAML, and the ocicl tag it builds, `v2.6.6`,
  exists, with `setup.lisp` building the executable into `~/.local/bin` as the
  workflow expects.
- **Speed.** A check of this repository takes about 390 ms, against about 270 ms
  at `a12a31c`; with `--federation`, about 540 ms. Excluding a rule saves about
  145 ms for `ref/short-record` and about 45 ms for `ref/code-exists`; the other
  new rules cost little.
- **Not verified:**
  - the workflow itself, which first runs when pushed;
  - `make hooks`, which installs into this clone's `.git/hooks`;
  - the symbol patterns of languages other than Lisp against real code;
  - a federated repository that is itself shallow.

### Files

Table: Files added or changed in commit `a9c6dd9`.

| File | Action | Description |
|------|--------|-------------|
| `src/corpus/history.lisp` | **New** | Git-derived fields; what Git can say about the repository |
| `src/corpus/code.lisp` | **New** | Finding code references and resolving them against Git; symbol patterns |
| `src/corpus/federation.lisp` | **New** | Loading the federation, one hop deep |
| `src/rules/code.lisp` | **New** | `ref/code-pinned`, `ref/code-exists` |
| `src/rules/federation.lisp` | **New** | `federation/path`, `federation/namespace`, `index/current` |
| `src/git.lisp` | Modified | Standard input; batch object queries; `log --follow`; file status |
| `src/corpus/corpus.lisp` | Modified | A per-load cache; lookups that reach into the federation |
| `src/corpus/outline.lisp` | Modified | Derived fields in the outline |
| `src/rules/frontmatter.lisp` | Modified | `git/derivable` |
| `src/rules/memo.lisp` | Modified | A pinned basis must name a revision that exists |
| `src/rules/references.lisp` | Modified | Federated links; aliases in front-matter resolve |
| `src/rules/ledger.lisp` | Modified | Uses the shared Git and line-difference helpers |
| `src/model/manifest.lisp` | Modified | Writing a starting manifest; the replaced accessor removed |
| `src/util.lisp` | Modified | `first-difference` |
| `src/cli.lisp` | Modified | `check --federation`, `index --check`, `init`, `manifest --json`, derived fields in `outline`, paths under `--root` |
| `src/packages.lisp` | Modified | The new exports |
| `compass.asd` | Modified | The new source files and test suites |
| `tests/test-code-refs.lisp` | **New** | Git queries, derived fields, code references |
| `tests/test-federation.lisp` | **New** | Federation and the index check |
| `tests/helpers.lisp` | Modified | `created` on request; Git repositories in `check-files` |
| `tests/test-cli.lisp` | Modified | `init`, `manifest --json`, paths under `--root` |
| `tests/test-rules.lisp`, `tests/test-corpus.lisp`, `tests/test-allocate.lisp`, `tests/test-skills.lisp` | Modified | Fixtures for `git/derivable` and real revisions |
| `ocicl.csv` | **New** | The ocicl lockfile |
| `.github/workflows/compass-check.yml` | **New** | The CI workflow |
| `.github/CODEOWNERS` | **New** | The steward owns the ledger |
| `scripts/pre-commit` | **New** | The pre-commit hook |
| `Makefile` | Modified | `deps` and `hooks` |
| `README.md` | Modified | Dependencies, CI, branch protection, the hook |
| `doc/Plan.Toolchain.md` | Modified | COMPASS-D31 to COMPASS-D33; COMPASS-O6 and COMPASS-O7; rule table, commands, and releases |
| `doc/Log.Ledger.md` | **New** | This Log |
| `doc/INDEX.md` | Modified | Regenerated |
| `skills/reference/toolchain.md` | Modified | The new commands; federation; what is not checked yet |

### Metrics

- Test checks: 953 at `a12a31c`; 1142 at `a9c6dd9`, of which the two new suites
  hold 139.
- Regressions: 0.
- Rules: 33 at `a12a31c`; 39 at `a9c6dd9`.
- Commands: 12 at `a12a31c`; 13 at `a9c6dd9`.
- Source files: 31 (6,396 lines) at `a12a31c`; 36 (7,598 lines) at `a9c6dd9`, of
  which the five new files hold 719 lines.
- Test files: 17 (2,510 lines) at `a12a31c`; 19 (3,096 lines) at `a9c6dd9`, of
  which the two new suites hold 496 lines.

### Outstanding Work

Stages 9 to 11 remain as [Outstanding Work](#outstanding-work) above lists
them: the bootstrap and the amendments to `Compass.md`, the skills and version
0.2.0, and the final checkpoint. In addition:

- **Run the workflow.** It first runs when pushed. The ocicl job builds ocicl
  from source with Ubuntu's SBCL, which has not been tried. Then make both jobs
  required checks, and require code-owner review, as `README.md` describes.
  *It ran on the push of `342b414`, and both jobs passed; see [Update 2026-10-10 — Bootstrap, the amended standard, skills, and version 0.2.0](#update-2026-10-10--bootstrap-the-amended-standard-skills-and-version-020).
  The repository settings remain the steward's.*
- **Install the hook** with `make hooks`, if wanted. It checks the working tree,
  so it also indexes and checks changes not staged for the commit.
- **A guard against replaced definitions.** Pitfall 4 is the second instance;
  the build should fail when a definition replaces another. *Done in
  `ccb28e9`; see [Update 2026-10-10 — Bootstrap, the amended standard, skills, and version 0.2.0](#update-2026-10-10--bootstrap-the-amended-standard-skills-and-version-020).*
- **Speed.** A check now takes about 390 ms; `ref/short-record` remains the
  largest cost.
- **Unverified references in CI.** CI checks without `--federation`, so the
  three references into Classic stay unverified there; a workflow that checks
  out the federation beside this repository would verify them.
- **Uses of the derived fields.** Only `outline` shows them so far; the
  `review/approver` rule and the RDF export are their next users.
- **Acceptance.** COMPASS-D31 to COMPASS-D33
  and this Log's decisions COMPASS-DRAFT-ledger-log-D3 and
  COMPASS-DRAFT-ledger-log-D4 are `Proposed`.

## Update 2026-10-10 — Bootstrap, the amended standard, skills, and version 0.2.0

Commit `ccb28e9` carried out stages 9 and 10 of version 0.2: the standard's
amendments for the decisions accepted so far, as `Compass.md` 0.3.0, the
toolchain and skills brought into line with it, two guards against mistakes
this Log has recorded twice each, and version 0.2.0. Stage 11 is this update.
Code references in this section are pinned to `ccb28e9`, except one into
Classic, pinned to the Classic commit it describes. A few edits made with this
update, after `ccb28e9`, are listed under
[Made with this update](#made-with-this-update).

### Problem

At `a9c6dd9` the toolchain enforced decisions the standard did not yet state:

- **The standard lagged its accepted decisions.**
  [COMPASS-0001](../Compass.md) still had a "registry" listing titles and
  statuses (§13), where the ledger records immutable facts only
  ([COMPASS-D7](Plan.Toolchain.md#compass-d7--the-allocation-ledger-holds-immutable-facts-only));
  it gave records no provisional identifiers
  ([COMPASS-D6](Plan.Toolchain.md#compass-d6--provisional-identifiers-for-register-entries));
  its §8 example used the short heading
  ([COMPASS-D20](Plan.Toolchain.md#compass-d20--register-record-headings-carry-the-full-identifier));
  its §6 status `Superseded-by: <id>` was not valid YAML
  ([COMPASS-D9](Plan.Toolchain.md#compass-d9--supersession-uses-a-plain-status-plus-the-existing-field));
  and §11 and §12 required table captions and diagram descriptions that
  Markdown cannot express
  ([COMPASS-D10](Plan.Toolchain.md#compass-d10--checkable-conventions-for-12-and-generated-indexes)).
  All five decisions are accepted.
- **The §23 tables used labels that read as records.** Rows `D1` to `D8` and
  `O1` to `O6` looked like `COMPASS` register identifiers, and accounted for 8
  of this repository's `ref/short-record` warnings
  ([COMPASS-D13](Plan.Toolchain.md#compass-d13--bootstrapping-the-compass-namespace)).
- **§22 described a toolchain "not yet built"**, with 3bmd and cl-yaml as its
  parsers.
- **The skills described the ledger as future work**, and the reference bundle
  carried notes calling the amendments pending.
- **Two kinds of mistake had each happened twice**: a definition that silently
  replaced another (pitfall 3 of the first section, and pitfall 4 of the
  previous update), and a message whose line continuation was printed because
  its string never reached `format` (pitfall 4 of the first section, and the
  `fm/present` message before it).

### Design Decisions

The work carried out the amendments of COMPASS-D6,
COMPASS-D7, COMPASS-D9,
COMPASS-D10, COMPASS-D13, and
COMPASS-D20. The steward accepted
[COMPASS-D22](Plan.Toolchain.md#compass-d22--a-strict-yaml-subset-parser-written-in-lisp)
during the round, so its §7 amendment, the YAML subset, landed too. The
amendments of COMPASS-D16 and COMPASS-D17 wait
on the agent-context evaluation and on roadmap step 6, and those of the
proposed decisions on their acceptance.

Two further decisions were made while coding. They are recorded here as
proposals for the steward.

### COMPASS-DRAFT-ledger-log-D5 — The status form that COMPASS-D9 replaced is an error

**Status:** Proposed

**Context:** Before `Compass.md` 0.3.0 the toolchain warned on a quoted
`status: "Superseded-by: <id>"`, because the standard still prescribed that
form and COMPASS-D9 only proposed its replacement. With the
amendment in the standard the old form names a status that no longer exists.
COMPASS-D9 calls itself breaking, and no document uses the old
form.

**Decision:** `src/rules/frontmatter.lisp:vocab/status@ccb28e9` reports the old
form as an error, with a message that names the replacement: `status:
Superseded`, with the successor, read from the old value, in `superseded-by:`.
`src/vocab.lisp:legacy-superseded-target@ccb28e9` still recognises the form, so
that the message can be specific.

**Alternatives:**
- Keep the warning. Rejected: a document could then carry a status the
  standard no longer has and still pass the required check.
- Treat it as any unknown status. Rejected: the generic message would list the
  statuses without saying which one replaces this.

### COMPASS-DRAFT-ledger-log-D6 — The build fails when a compass function replaces another

**Status:** Proposed

**Context:** Twice a definition silently replaced another of the same name: a
helper replaced a structure's accessor, and a structure's accessor replaced a
function exported from a package it used. SBCL warns in both cases, but
Quicklisp muffles every warning while it loads a system, so neither warning was
ever seen, and each surfaced as a wrong result at run time.

**Decision:** `build.lisp:load-system@ccb28e9` loads only the systems outside
compass through the selected dependency manager
(`build.lisp:external-dependencies@ccb28e9`), then loads the compass systems
with ASDF inside `build.lisp:call-guarding-redefinitions@ccb28e9`. That handler
fails the build when a function or generic function whose name belongs to a
compass package is replaced, as SBCL reports it: a definition replacing one
from another file, or two definitions in one file
(`build.lisp:redefinition-name@ccb28e9`). A function and a structure accessor
of the same name are caught either way. Macros and methods are left out,
because compiling a file and then loading it redefines each of them with the
same definition. On other implementations the
handler finds nothing to report. `make build` and `make test` both load this
way.

**Alternatives:**
- Treat every warning as an error. Rejected: dependencies warn, and so does
  every macro redefined by loading a file just compiled.
- A test comparing definitions after loading. Rejected: by then the replaced
  definition is gone.
- Review alone. Rejected: review missed both.

### Implementation

Code references below are pinned to `ccb28e9`.

#### The amended standard, `Compass.md` 0.3.0

`schema-version` went from 0.2.0 to 0.3.0: one minor increment for all of the
round's amendments, since before 1.0 a breaking change, such as
COMPASS-D9's, increments the minor number. Section by section:

- **§6 and §7** ([§6](../Compass.md#6-controlled-status-and-editorial-review)):
  the status `Superseded`, with the successor in `superseded-by:`, each
  requiring the other. §7's annotated example and its notes follow, and §7
  gained [the YAML subset](../Compass.md#the-yaml-subset) of
  COMPASS-D22: what front-matter may use, and that every scalar
  is a string typed by the schema.
- **§8** ([§8](../Compass.md#8-cross-cutting-registers)): a record is defined by
  a level-3 heading with its full identifier and an em dash; a record in an
  unnumbered document carries a provisional identifier; the example is now
  `### PSYCHE-D16 — …`.
- **§13** ([ID allocation](../Compass.md#id-allocation)): rewritten around the
  ledger, `REGISTRY.sexp` in the document directory of the repository that owns
  the namespace, holding only facts fixed at allocation; provisional
  identifiers for documents and their records; assignment of every number in
  one change at acceptance, with references rewritten and the ledger appended;
  aliases that keep old provisional identifiers resolving. The wording "the
  repository that owns the namespace" fits COMPASS-D7, which
  speaks of a ledger per namespace, and the proposed COMPASS-D26,
  which keeps one per repository. The proposed COMPASS-D27 is
  not written into the standard. The master index is generated, carries a
  banner, and is verified in CI, and §13's paragraph on conformance now names
  the toolchain.
- **§10**: the repository layout shows `compass.sexp`, `INDEX.md`, and
  `REGISTRY.sexp`, and the federation text speaks of ledgers and indexes rather
  than registries.
- **§11 and §12** ([§12](../Compass.md#12-accessibility)): a table's caption is
  a paragraph `Table: <caption>` immediately before it; a diagram is a fenced
  `mermaid`, `plantuml`, `dot`, `graphviz`, or `lexis` block followed by a
  paragraph beginning `Description:`; alt text must not be empty.
- **§22**
  ([§22](../Compass.md#22-appendix--conformance-and-the-validation-toolchain)):
  describes the toolchain of version 0.2, its purpose-built parsers
  ([COMPASS-D11](Plan.Toolchain.md#compass-d11--common-lisp-with-purpose-built-parsers)),
  its Git integration, and its commands; the list of checks gains the ledger,
  registers, code references, the index, and federation, with the §12 rules
  marked planned. It remains non-normative; the change is a patch.
- **§23**:
  - rows are labelled `R`, `S`, `P`, `ND` (open by design), and `GO` (genuinely
    open), with a note that the labels cannot be read as records and that an
    item that migrates takes a new label naming its old one;
  - §23 S1, the toolchain, moved to Partially resolved as P5, and GO6,
    draft-to-canonical assignment, as P6, each with its residue named
    ([Partially resolved](../Compass.md#partially-resolved));
  - R4 and P3 follow the ledger and the `Superseded` status.

  Two references to the old labels, in
  [COMPASS-0004](Plan.Toolchain.md) and
  [COMPASS-DRAFT-secure-development](Survey.SecureDevelopment.md), and the
  listing in `doc/README.md`, follow.
- **Captions.** Compass.md's nine tables and the templates' eight gained
  `Table:` captions; every other document already had them.

#### The toolchain

- **`Superseded` is accepted**
  (`src/vocab.lisp:*status-families*@ccb28e9`), so `vocab/pending` no longer
  warns on it, and the old form is an error
  ([COMPASS-DRAFT-ledger-log-D5](#compass-draft-ledger-log-d5--the-status-form-that-compass-d9-replaced-is-an-error)).
- **`vocab/pending`'s messages** say a value "is not yet adopted into the
  standard" (`src/rules/frontmatter.lisp:note-pending@ccb28e9`), where they said
  its decision "has not been accepted". That was false for the values of
  COMPASS-D16 and COMPASS-D17, whose decisions
  are accepted though their amendments have not landed
  ([COMPASS-D24](Plan.Toolchain.md#compass-d24--vocabulary-values-carry-a-standing)).
- **The version is 0.2.0**, in `compass.asd` and in the executable.

#### The skills and their reference bundle

- **`skills/reference/`**: the notes calling the amendments pending are gone.
  `references.md` states the heading rule and the rule against short forms,
  describes allocation through the ledger, and gives the caption and
  description conventions; `vocabularies.md` lists `Superseded`;
  `frontmatter.md` states the YAML subset; `toolchain.md` describes notes and
  the fields derived from Git.
- **`compass-author`** runs `assign` only when the user asks, gives records
  added to a numbered document the identifier `next --in` prints (memos
  included), writes full identifiers, and pins a Log's code references to the
  commit of its work.
- **`compass-review`** checks a branch with `--base` and, where the federation
  is present, `--federation`; reads the ledger, alias, and short-reference
  findings; leaves to the toolchain what `ref/code-pinned` and
  `ref/code-exists` now check; and takes derived authors from `outline` for
  the approver check.
- **`compass-lookup`** follows aliases, reads authors and dates from `outline`,
  treats `next` as a preview, and reads the manifest with `manifest --json`.
- **`compass-derive`** names version 0.2, and the AGENTS snippet asks that
  numbers be assigned only when a person asks.
- **`README.md`** describes version 0.2, with an example of each new command.
- **[COMPASS-0004](Plan.Toolchain.md)**: roadmap steps 3, 4, 5, 6,
  7, and 8 mark what version 0.2 finished.

#### The guards

- **Replaced definitions.** See
  [COMPASS-DRAFT-ledger-log-D6](#compass-draft-ledger-log-d6--the-build-fails-when-a-compass-function-replaces-another).
  A replacement within one file is a full warning, on which ASDF stops
  compiling, so the handler reports each replacement as it happens rather than
  in a summary at the end.
- **Stray line continuations.**
  `tests/test-repository.lisp:no-stray-format-strings@ccb28e9` reads every
  source file under `src/` and fails on a string that continues a line with a
  tilde and a newline anywhere but in a format-control position:
  `tests/test-repository.lisp:*format-control-positions*@ccb28e9` lists the
  operators and argument positions, the branches of an `if` in such a position
  count, and so does a rule's `:summary`, which `define-rule` formats
  (`tests/test-repository.lisp:stray-format-strings@ccb28e9`).

#### Other repositories

- **Origin**, commit `7ef2f48`: a `.mailmap` like this repository's, so that
  the ledger names the allocator as "Andrew Sengul" rather than the Git user
  `phantomics`, and then a ledger seeded by `compass init --ledger` with
  ORIGIN-O5 to ORIGIN-O9, hosted by its Survey of the browser as an orbital.
- **Classic**, commit `be4fe84`: its `AGENTS.md` says that the duplicated
  CLASSIC-O1 to CLASSIC-O6 also block `compass init --ledger`, and should become
  provisional identifiers formed from each Survey's own. The same commit adds
  [CLASSIC-DRAFT-compass-integration](../../classic/doc/survey/Survey.CompassIntegration.md),
  a Survey of how a Compass corpus could be composed from Classic's base schema
  rather than its wiki preset, and of the extensions Classic needs for it. Its
  findings bear on the RDF export of COMPASS-D21: §17's
  mapping and the binding's alignment table compare with the wiki preset, and
  the binding maps `created` and `updated` to the predicates Classic uses for
  record timestamps rather than authorial dates. It also found that Classic's
  URI parser (`CLASSIC:src/uri.lisp:parse-classic-uri@e8e9b3e`) truncates every
  `COMPASS` and `CLASSIC` identifier to six characters.

#### Made with this update

These edits follow `ccb28e9` and are committed with this update:

- **Statuses**, set by the steward:
  [COMPASS-D2](Plan.AuthoringAssistance.md#compass-d2--advisory-only-until-the-toolchain-exists)
  and COMPASS-D6 are `Implemented`. COMPASS-D2's decision
  provided for the toolchain's arrival, so nothing replaced it; the skills
  call the toolchain and keep advisory mode as their fallback.
- **[COMPASS-0003](Plan.AuthoringAssistance.md)**: roadmap
  step 6 is done for version 0.2, COMPASS-O2 is resolved by the manifest and
  the ledger, and its Outstanding Work follows.
- **[COMPASS-0004](Plan.Toolchain.md)**: its introduction says the
  skills call the toolchain, and roadmap step 8's "Lift COMPASS-D2" is done.
- **`Compass.md` §7**: the sentence on `superseded-by` is a paragraph of its own
  again (pitfall 4 below).
- **`build.lisp`**: the guard's third test, for SBCL's plain warning that a
  function "clobbers" a structure accessor, now matches that warning
  (pitfall 6 below).

### Pitfalls Encountered

1. **A count that missed captions.** A scan for tables without a caption
   reported 31, which shaped the plan for stage 9. It looked only at the line
   before each table, and the captions of the corpus documents run over two
   lines. The true count was 17, all in `Compass.md` and the templates, so no
   accepted document needed an edit.
2. **Warnings that were never seen.** Neither earlier replacement was
   reported because Quicklisp's `quickload` muffles every warning while it
   loads, so the guard loads compass with ASDF instead. Its first version then
   failed the clean build: it counted the macros `define-rule` and
   `define-command`, which loading a just-compiled file redefines with the same
   definition. Limited to functions, it missed a replacement within one file,
   which SBCL reports under another condition and ASDF treats as a failed
   compilation; the guard now reads that condition too, and reports each
   replacement as it happens. Each step was checked by putting back the two
   historic mistakes until the build failed on both.
3. **A bug found by the new test.** The first run of the stray-continuation
   test found a fourth instance, from v0.1: the `fm/syntax` message for a
   front-matter block never closed printed its tilde and indentation
   (`src/parse/document.lisp:parse-document@ccb28e9`). The same run flagged
   strings passed to the YAML parser's error function and to local helpers
   named `problem`, which do format their controls; the list of positions
   grew to include them.
4. **A paragraph joined in an edit.** The stage 9 edit of §7 appended the
   sentence on `superseded-by` to the paragraph on required fields, joining the
   two mid-line. It was found on review and split again with this update.
5. **Two records called `D2`.** The status meant for COMPASS-D2 was first set on
   COMPASS-D6, whose short form is also `D2`. The steward kept
   both as `Implemented`, since provisional record identifiers are implemented
   too. It is the ambiguity
   [COMPASS-D30](Plan.Toolchain.md#compass-d30--records-are-referred-to-by-full-identifier-short-forms-are-found-not-rewritten)
   describes, met by a person rather than a rewriter.
6. **A test that never matched.** While this update was written, the guard's
   third test, for the plain warning that a function "clobbers structure
   accessor", turned out never to match: it searched the warning's format
   control for those words, but the control holds a directive
   (`clobbers structure ~:[accessor~;…~]`). Both historic mistakes were caught
   regardless, by the other two conditions, which SBCL signals in the same
   cases. The test now searches for "clobbers structure", and matches.

### Verification

- **Tests.** `make test` at `ccb28e9`, run from a separate worktree of that
  commit: **1182 checks, 100% pass**, under both `DEPS=ql` and `DEPS=ocicl`
  (with `OCICL_LOCAL_ONLY=1`).
- **The executable**, built from that worktree, reports
  `compass 0.2.0 (commit ccb28e932238, SBCL 2.3.4, linux x86-64)`, without
  `-dirty`: 49,257,440 bytes, or 12.1 MiB with `gzip -9`.
- **Self-check** at `ccb28e9`: "Checked 13 documents: 0 errors, 224 warnings",
  all `ref/short-record`, with 3 references unverified; the same with
  `--base 342b414`, as the workflow's push job will run it; `compass index
  --check`: current. With this update's edits, 222 warnings, and 5 references
  unverified: the 2 new ones point into Classic, and `--federation` resolves
  all 5.
- **The index check at work.** When the steward accepted
  COMPASS-D22 during the round, `index/current` reported the
  committed index stale, at the line of that record, until it was regenerated.
- **CI.** The workflow first ran on the push of `342b414` (the code of
  `a9c6dd9`), run 38079521930: both jobs passed every step, the Quicklisp job in
  28 seconds and the ocicl job, which builds ocicl v2.6.6 from source with
  Ubuntu's SBCL, in 56 seconds. `ccb28e9` was not pushed when this update was
  written, so its run follows the push.
- **The guards.** With the helper `allocation-base` put back into
  `src/corpus/allocate.lisp`, the build failed with "ALLOCATION-BASE is defined
  twice"; with the manifest's `command-name` put back and exported, it failed
  with "COMMAND-NAME is defined twice" and "1 definition replaced another". The
  clean tree builds. Both results hold at `ccb28e9` and with this update's fix
  to the guard. The stray-continuation test failed on the `fm/syntax`
  message until it was fixed.
- **Short references** fell from 234 at `a9c6dd9` to 224 at `ccb28e9`: the 8 in
  `Compass.md`'s §23 tables, and the 2 in the references to them elsewhere.

  Table: `ref/short-record` warnings in this repository at `ccb28e9`, by document.

  | Document | Warnings |
  |---|---|
  | `doc/Plan.Toolchain.md` | 101 |
  | `doc/Plan.AgentWorkflow.md` | 54 |
  | `doc/Log.Toolchain.md` | 29 |
  | `doc/Log.AuthoringAssistance.md` | 14 |
  | `doc/Survey.SecureDevelopment.md` | 7 |
  | `doc/Survey.OperatorMemory.md` | 5 |
  | `doc/Plan.AuthoringAssistance.md` | 5 |
  | `doc/Eval.PriorArt.AgentContext.md` | 5 |
  | `doc/Eval.AgentContext.md` | 3 |
  | `doc/Spec.SemanticBinding.md` | 1 |

- **The other repositories**, at their commits, with `--skip-unmarked`:

  Table: Results of `compass check --skip-unmarked` on the other repositories, by the executable of `ccb28e9`.

  | Repository | Commit | Documents | Errors | Without `--federation` |
  |---|---|---|---|---|
  | classic | `be4fe84` | 6 | 24 `ledger/coverage`; 23 `register/unique` | 12 references unverified; none with it |
  | origin | `7ef2f48` | 1 | 0 | — |
  | lexter | `4d6a89d`, manifest uncommitted | 0 | 0 | — |

  Classic's errors are its duplicated open questions; Origin's five
  `ledger/coverage` errors are gone with its ledger.
- **The Classic Survey** checks clean in Classic; with `--federation` its links
  into this repository resolve, and its 20 code references, pinned to
  Classic's `e8e9b3e`, all resolve. Its table of truncated identifiers comes
  from running Classic's own URI parser at that commit.
- **A real assignment.** `compass assign --dry-run` of
  [COMPASS-0007](Plan.AgentWorkflow.md) still refuses, on 57
  short references. With `--force` it would rewrite 102 lines in 11 documents,
  this Log now among them, and append 16 ledger entries.
- **Speed.** A check takes about 405 ms, or about 265 ms without
  `ref/short-record`.
- **Not verified:**
  - the workflow's run on `ccb28e9`;
  - the repository settings `README.md` asks for: required checks, and review
    by code owners;
  - `make hooks`;
  - the redefinition guard on an implementation other than SBCL, where it
    reports nothing.

### Files

Table: Files added or changed in commit `ccb28e9`.

| File | Action | Description |
|------|--------|-------------|
| `Compass.md` | Modified | Version 0.3.0: §6, §7, §8, §10 to §13, §22, §23; captions |
| `build.lisp` | Modified | Loads compass with ASDF and fails on a replaced definition |
| `src/vocab.lisp` | Modified | `Superseded` accepted |
| `src/rules/frontmatter.lisp` | Modified | The old status form is an error; `vocab/pending`'s wording |
| `src/parse/document.lisp` | Modified | The `fm/syntax` message for an unclosed block is formatted |
| `src/cli.lisp`, `compass.asd` | Modified | Version 0.2.0 |
| `src/model/manifest.lisp` | Modified | A comment |
| `tests/test-repository.lisp` | Modified | The stray-continuation test |
| `tests/test-rules.lisp`, `tests/test-vocab.lisp` | Modified | `Superseded` accepted; the old form an error |
| `skills/compass-author/SKILL.md`, `skills/compass-review/SKILL.md`, `skills/compass-lookup/SKILL.md`, `skills/compass-derive/SKILL.md` | Modified | Version 0.2: numbers, aliases, `--base`, `--federation`, derived fields |
| `skills/reference/references.md`, `vocabularies.md`, `frontmatter.md`, `toolchain.md` | Modified | The amended standard; notes; derived fields |
| `templates/*.template.md` (six) | Modified | Table captions |
| `templates/AGENTS.snippet.md` | Modified | Numbers only when a person asks |
| `README.md` | Modified | Version 0.2 and its commands |
| `doc/Plan.Toolchain.md` | Modified | The roadmap; the §23 labels; COMPASS-D22 accepted |
| `doc/README.md`, `doc/Survey.SecureDevelopment.md` | Modified | The §23 labels |
| `doc/INDEX.md` | Modified | Regenerated |

Table: Files changed in the other repositories.

| Repo | File | Action | Description |
|------|------|--------|-------------|
| origin | `.mailmap` | **New** | Canonical name of the allocator |
| origin | `doc/REGISTRY.sexp` | **New** | Origin's ledger, seeded |
| classic | `AGENTS.md` | Modified | The duplicated open questions and the ledger |
| classic | `doc/survey/Survey.CompassIntegration.md` | **New** | Compass on Classic's base schema |

### Metrics

- Test checks: 1142 at `a9c6dd9`; 1182 at `ccb28e9`.
- Regressions: 0.
- Rules: 39. Commands: 13.
- Source files: 36 (7,599 lines) at `ccb28e9`. Test files: 19 (3,179 lines).
- `Compass.md`: 190 lines added and 93 removed.

### Version 0.2 in summary

Version 0.2 took four commits, from the v0.1 toolchain of `f0b03b4`:

Table: The commits of version 0.2, with the toolchain's size at each.

| Commit | Work | Checks | Rules | Commands |
|---|---|---|---|---|
| `f0b03b4` | Version 0.1, with the skills wired to it | 626 | 25 | 9 |
| `a12a31c` | Stages 0 to 4: the Git layer, the ledger and its rules, allocation, the concurrency tests | 953 | 33 | 12 |
| `a9c6dd9` | Stages 5 to 8: derived fields, code references, the index check, federation, `init`, `manifest`, CI | 1142 | 39 | 13 |
| `342b414` | This Log's first update | 1142 | 39 | 13 |
| `ccb28e9` | Stages 9 and 10: `Compass.md` 0.3.0, the skills, the guards, version 0.2.0 | 1182 | 39 | 13 |

Its decisions: COMPASS-D26 to COMPASS-D33,
recorded in the plan, and COMPASS-DRAFT-ledger-log-D1 to
COMPASS-DRAFT-ledger-log-D6, recorded here, all `Proposed`. Version 0.2.1 holds
the release binaries.

### Outstanding Work

What remains after version 0.2:

- **Short references.** 222 `ref/short-record` warnings remain, the steward's to
  rewrite by hand; until those in and around COMPASS-0007 are
  rewritten, `assign` refuses it.
- **Assigning the accepted documents**: COMPASS-0007,
  COMPASS-0005, COMPASS-DRAFT-toolchain-log, and
  COMPASS-DRAFT-authoring-assistance-log, and later this Log and the plans once
  accepted.
- **Classic's duplicated open questions**, as its `AGENTS.md` now describes.
- **Speed.** A check takes about 405 ms; `ref/short-record` is about 140 ms of
  it, and could skip lines with no `D`, `O`, or `M` followed by a digit.
- **`compass check` during a merge**, which compares with `HEAD` without
  `--base` and so reports `ledger/append-only` after `renumber` until the merge
  is committed.
- **§7 and COMPASS-D31.** §7 says the toolchain errors on an
  untracked file; the proposed COMPASS-D31, which the toolchain
  implements, derives such a file's fields from the working tree. Accepting the
  decision would amend §7.
- **The semantic binding.** Revise the alignment of
  [COMPASS-DRAFT-semantic-binding](Spec.SemanticBinding.md) with Classic, as the
  Classic Survey describes, before the RDF export of
  COMPASS-D21 in version 0.3. The Classic side of that work is
  Classic's.
- **Repository settings and the hook**: both workflow jobs required, review by
  code owners, and `make hooks` where wanted.
- **The checks still planned**: the §12 accessibility rules, the §14 section
  shapes, and `review/approver`.
- **Version 0.2.1**, the release binaries, and a `v0.2.0` tag if wanted.
- **Acceptance**: this Log is `Draft`; COMPASS-D21 and
  COMPASS-D23 to COMPASS-D33, this Log's six
  decisions, and the toolchain Log's four are `Proposed`.
