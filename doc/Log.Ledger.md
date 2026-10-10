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
  - COMPASS-DRAFT-toolchain
  - COMPASS-DRAFT-toolchain-log
  - COMPASS-0001
decisions:
  - COMPASS-DRAFT-ledger-log-D1
  - COMPASS-DRAFT-ledger-log-D2
---

# Compass Ledger: Development Log

This document chronicles the allocation ledger of the Compass toolchain. The
ledger is the file that records every number a repository has allocated; the
work also covers the rules that check it, and the commands that allocate
numbers and recover when two branches allocate at once. The work is stages 0 to 4
of version 0.2 of [COMPASS-DRAFT-toolchain](Plan.Toolchain.md), committed as
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
  [COMPASS-DRAFT-toolchain-D1](Plan.Toolchain.md#compass-draft-toolchain-d1--merge-time-ledger-plus-required-ci-as-the-uniqueness-authority).
- **Assigning by hand was impractical.** Numbering one accepted plan,
  [COMPASS-DRAFT-agent-workflow](Plan.AgentWorkflow.md), takes sixteen free
  numbers and 96 rewritten lines in 10 documents, including the anchors of the
  renamed headings and the links to them (see [Verification](#verification)).
- **Accepted documents were waiting.** Four documents are accepted but keep
  their provisional identifiers: that plan,
  [COMPASS-DRAFT-operator-memory](Survey.OperatorMemory.md), and the two Logs
  that precede this one.

## Design Decisions

The work carried out these decisions of the plan:

- [COMPASS-DRAFT-toolchain-D1](Plan.Toolchain.md#compass-draft-toolchain-d1--merge-time-ledger-plus-required-ci-as-the-uniqueness-authority):
  the uniqueness guarantee, a ledger checked at merge by a required check.
- [COMPASS-DRAFT-toolchain-D2](Plan.Toolchain.md#compass-draft-toolchain-d2--provisional-identifiers-for-register-entries)
  and
  [COMPASS-DRAFT-toolchain-D3](Plan.Toolchain.md#compass-draft-toolchain-d3--the-allocation-ledger-holds-immutable-facts-only):
  provisional record identifiers, and a ledger that holds immutable facts only.
- [COMPASS-DRAFT-toolchain-D9](Plan.Toolchain.md#compass-draft-toolchain-d9--bootstrapping-the-compass-namespace):
  bootstrapping the `COMPASS` namespace by seeding the ledger with the numbers
  already in use.
- Five decisions recorded in stage 0, all `Proposed`:
  - [COMPASS-DRAFT-toolchain-D22](Plan.Toolchain.md#compass-draft-toolchain-d22--one-ledger-per-repository-one-entry-per-line):
    one ledger per repository, one entry per line, four counters per
    namespace, and the ledger rules;
  - [COMPASS-DRAFT-toolchain-D23](Plan.Toolchain.md#compass-draft-toolchain-d23--provisional-records-in-a-numbered-document-reuse-its-alias):
    a provisional record in a numbered document reuses the document's alias;
  - [COMPASS-DRAFT-toolchain-D24](Plan.Toolchain.md#compass-draft-toolchain-d24--what-compass-assign-does):
    what `compass assign` does;
  - [COMPASS-DRAFT-toolchain-D25](Plan.Toolchain.md#compass-draft-toolchain-d25--concurrent-allocations-are-recovered-by-keeping-both-and-renumbering):
    concurrent allocations are recovered by keeping both sides of the conflict
    and renumbering;
  - [COMPASS-DRAFT-toolchain-D26](Plan.Toolchain.md#compass-draft-toolchain-d26--records-are-referred-to-by-full-identifier-short-forms-are-found-not-rewritten):
    records are referred to by full identifier; short forms are found, not
    rewritten.

COMPASS-DRAFT-toolchain-D26 was not in the plan for this round. A trial
`assign` of a real plan showed that short references such as `D6` change
meaning when records are numbered (see [Pitfalls Encountered](#pitfalls-encountered)).
The steward then asked whether short references were a one-time cleanup. They
are: once written as full identifiers, they are rewritten exactly by `assign`
and `renumber`, and they recur only if someone writes new ones. So the toolchain
finds short forms, and leaves rewriting them to an author. Because this decision took the next number, the decisions the plan
had drafted for Git-derived fields, code references, and federation will be
recorded as `COMPASS-DRAFT-toolchain-D27`, `COMPASS-DRAFT-toolchain-D28`, and
`COMPASS-DRAFT-toolchain-D29`.

Two further decisions were made while coding. They are recorded here as
proposals for the steward.

### COMPASS-DRAFT-ledger-log-D1 — Seeding refuses a number defined twice

**Status:** Proposed

**Context:** COMPASS-DRAFT-toolchain-D9 has `compass init --ledger` record the
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
with a base revision, by default `HEAD` (COMPASS-DRAFT-toolchain-D22). During a
merge, `HEAD` is the branch's own tip. `renumber` rebuilds the ledger as the base
revision's ledger followed by the branch's entries (COMPASS-DRAFT-toolchain-D25),
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

- **[COMPASS-DRAFT-toolchain](Plan.Toolchain.md)** gained
  COMPASS-DRAFT-toolchain-D22 through COMPASS-DRAFT-toolchain-D26, and its
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
  accept the provisional records of COMPASS-DRAFT-toolchain-D23. A record in a
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
     COMPASS-DRAFT-toolchain-D25 speaks of definitions on added lines; comparing
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
  implements COMPASS-DRAFT-toolchain-D23. A provisional document uses its own
  identifier, and a numbered one its alias; a numbered document with no alias
  gets a slug from its file name
  (`src/corpus/allocate.lisp:slug-from-path@a12a31c`: `Plan.AgentWorkflow.md`
  gives `agent-workflow`), with `-2`, `-3`, … added while that slug is taken.
  The number follows every record of that prefix in the document and in the
  ledger's aliases.

### Rewriting

- **Whole identifiers.** `src/corpus/rewrite.lisp:rewrite-line@a12a31c` replaces
  whole identifiers through `src/model/identifier.lisp:replace-identifiers-in-text@a12a31c`.
  The scanner's lookahead keeps `COMPASS-DRAFT-toolchain` from matching inside
  `COMPASS-DRAFT-toolchain-D18` or `COMPASS-DRAFT-toolchain-log`.
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
  records name `COMPASS-DRAFT-authoring-assistance` as their host, since that
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
   [COMPASS-DRAFT-agent-workflow](Plan.AgentWorkflow.md), in a scratch clone,
   rewrote every full identifier correctly, but the short forms after them kept
   their old numbers. `COMPASS-DRAFT-agent-workflow-D1 to D4` became
   `COMPASS-D5 to D4`, and `…-D5 to D9` became `COMPASS-D9 to D9`. The rewriter
   was then taught to rewrite short forms too, guessing what each meant from the
   text around it. The second trial showed the guesses going wrong: `O4 and O5`
   of [COMPASS-DRAFT-operator-memory](Survey.OperatorMemory.md) were taken for
   the plan's own questions, and a `D1 to D4` in another document was left
   unchanged. A wrong guess changes a document's meaning silently, so the
   guessing was removed and the short forms are reported instead
   (COMPASS-DRAFT-toolchain-D26).
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
  COMPASS-DRAFT-toolchain-D25 made keeping both sides the recovery, and taking
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
  - `compass assign --dry-run` of [COMPASS-DRAFT-agent-workflow](Plan.AgentWorkflow.md)
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
  - `compass show COMPASS-DRAFT-agent-workflow-D4` printed the record
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
| `src/rules/identity.lisp` | Modified | `id/format` accepts the provisional records of COMPASS-DRAFT-toolchain-D23 |
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
| `doc/Plan.Toolchain.md` | Modified | COMPASS-DRAFT-toolchain-D22 through COMPASS-DRAFT-toolchain-D26, and the sections they change |
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

- **Stage 0, the rest.** Record `COMPASS-DRAFT-toolchain-D27` (Git-derived
  fields: a document not yet committed derives its authors and dates from the
  working tree; a file outside any repository is an error),
  `COMPASS-DRAFT-toolchain-D28` (code references, resolving
  COMPASS-DRAFT-toolchain-O4), and `COMPASS-DRAFT-toolchain-D29` (federation). Split the plan's
  [baseline releases](Plan.Toolchain.md#baseline-releases): v0.2 is this round,
  and v0.2.1 the release binaries.
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
- **Stage 6: remaining checks.** `index --check` and the `index/current` rule;
  `check --federation`, which loads each repository listed under
  `:federation` and reports a namespace claimed by two of them
  (`COMPASS-DRAFT-toolchain-D29`, which partly answers
  COMPASS-DRAFT-toolchain-O3).
  `check --base` was done in stage 2.
- **Stage 7: new commands.** `compass init`, with non-interactive flags, writes
  a starting manifest, and `compass manifest --json`. `compass init --ledger`
  was done in stage 3.
- **Stage 8: CI and dependencies.**
  - `ocicl.csv`, with `make test DEPS=ocicl` verified locally;
  - `.github/workflows/compass-check.yml`, run on pull requests and pushes under
    both Quicklisp and ocicl, with full history, running
    `compass check --base <pull request base>`, `index --check`, and
    `make test`. The workflow file is checked to be valid YAML; it first truly
    runs when pushed;
  - `.github/CODEOWNERS`, assigning the ledger to `@phantomics`;
  - `scripts/pre-commit` and `make hooks`.
- **Stage 9: bootstrap.** The ledger was seeded in stage 3. What remains:
  - relabel the rows of the §23 table, as `ND1`… and `GO1`…, per
    COMPASS-DRAFT-toolchain-D9;
  - amend `Compass.md` for the accepted decisions due in v0.2: §13 for
    COMPASS-DRAFT-toolchain-D2 and COMPASS-DRAFT-toolchain-D3 (the ledger
    replaces the "registry"; provisional identifiers for records); and the
    amendments of COMPASS-DRAFT-toolchain-D5 (§6, §7),
    COMPASS-DRAFT-toolchain-D6 (§11 to §13), and COMPASS-DRAFT-toolchain-D16
    (the §8 example);
  - update the vocabulary standings, and the skills' reference notes that still
    describe those amendments as pending;
  - this repository must then check clean, including the code-reference and
    Git rules.
- **Stage 10: skills.**
  - `toolchain.md`: the exit codes, and a shorter list of what is not checked
    yet. The command table was done in stage 3.
  - `compass-author`: `next --in`, and `assign` only when the user asks.
  - `compass-review`: `check --base` for branches, and the ledger findings.
  - `compass-lookup`: following aliases.

  The version becomes 0.2.0, with README updates.
- **Stage 11: a checkpoint commit**, then an update to this Log, with
  references pinned to that commit.

Other work found along the way:

- **Short references.** This repository has 235 `ref/short-record` warnings,
  listed in [Verification](#verification). They are the steward's to rewrite
  by hand, guided by the suggestions; until those in and around
  [COMPASS-DRAFT-agent-workflow](Plan.AgentWorkflow.md) are rewritten, `assign`
  refuses it.
- **Assigning the accepted documents.** The four documents listed under
  [Problem](#problem) can be numbered once their short references are
  rewritten.
- **The other repositories' ledgers.** Origin can be seeded with
  `compass init --ledger`. Classic must first give the duplicated open
  questions of its Surveys provisional identifiers
  ([COMPASS-DRAFT-ledger-log-D1](#compass-draft-ledger-log-d1--seeding-refuses-a-number-defined-twice)),
  and the note in its `AGENTS.md` should say so.
- **`compass check` during a merge.** Without `--base`, the check compares with
  `HEAD`. After `renumber` and before the merge is committed, it therefore
  reports `ledger/append-only`, as the report after `renumber` did before
  [COMPASS-DRAFT-ledger-log-D2](#compass-draft-ledger-log-d2--the-check-after-an-allocation-uses-the-allocations-base).
  While a merge is in progress, the default could be the commit being merged
  in.
- **Paths and `--root`.** Paths on the command line are relative to the current
  directory even with `--root`. Resolving them against `--root`, as `git -C`
  does, would match what users expect.
- **Guards against two recurring mistakes.** A test that no message contains a
  `~` followed by a newline, and a build that fails when a definition replaces
  another (pitfalls 3 and 4).
- **The speed of `ref/short-record`.** It nearly tripled the time of a check. It
  could skip lines that contain no capital `D`, `O`, or `M` followed by a digit.
- **Acceptance.** This Log is `Draft`, and its two decisions, like
  COMPASS-DRAFT-toolchain-D22 through COMPASS-DRAFT-toolchain-D26, are
  `Proposed`.
