---
id:            COMPASS-DRAFT-migration
title:         Compass Migration — Bringing Existing Documents into a Compass Corpus
genre:         Plan
scope:         program
program:       Compass
component:     authoring-assistance
language:      en
status:        Draft
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-0001
  - COMPASS-0003
  - COMPASS-0004
  - COMPASS-0006
  - COMPASS-0002
  - CLASSIC-0032
  - CLASSIC-0036
cites:
  - title:     "Lexis repository: the migration of doc/DevLog.Passthrough.md and doc/spec.md"
    locator:   "github.com/phantomics/lexis, commits cf1147b to 0efe8a8 (2026-11-15 to 2026-11-17)"
    external:  true
  - title:     "OpenCode session ses_8258e2e3 (the Lexis migrations)"
    locator:   "session-8258e2e3-339a-40cf-9441-2cb54611fd7a.md, from line 5769 (the Log) and line 9734 (the Spec)"
    external:  true
  - title:     "StranglerFigApplication"
    locator:   "Martin Fowler, martinfowler.com, 2004"
    external:  true
  - title:     "Diátaxis"
    locator:   "Daniele Procida, diataxis.fr; the advice to improve documentation one step at a time"
    external:  true
  - title:     "PROV-O: The PROV Ontology"
    locator:   "W3C Recommendation, 30 April 2013; prov:wasDerivedFrom"
    external:  true
  - title:     "git-log documentation"
    locator:   "the --follow option and rename detection by similarity"
    external:  true
decisions:
  - COMPASS-DRAFT-migration-D1
  - COMPASS-DRAFT-migration-D2
  - COMPASS-DRAFT-migration-D3
  - COMPASS-DRAFT-migration-D4
  - COMPASS-DRAFT-migration-D5
  - COMPASS-DRAFT-migration-D6
  - COMPASS-DRAFT-migration-D7
  - COMPASS-DRAFT-migration-D8
  - COMPASS-DRAFT-migration-D9
  - COMPASS-DRAFT-migration-D10
  - COMPASS-DRAFT-migration-D11
open-questions:
  - COMPASS-DRAFT-migration-O1
  - COMPASS-DRAFT-migration-O2
  - COMPASS-DRAFT-migration-O3
  - COMPASS-DRAFT-migration-O4
  - COMPASS-DRAFT-migration-O5
  - COMPASS-DRAFT-migration-O6
---

# Compass Migration: Development Plan

This plan covers bringing documents written before Compass into a Compass
corpus, one document at a time, with an assistant's help and a person's
acceptance. It assumes a repository already set up by the `compass-adopt` skill
([COMPASS-0003](Plan.AuthoringAssistance.md)), in which `compass check
--skip-unmarked` passes with the older documents skipped. It proposes a
sixth skill, `compass-migrate`, which reshapes a document's form and never its
content, following the rule that
[COMPASS-0006](Eval.AgentContext.md#seed-corpora) set for its seed corpora. It
gives a partial answer to COMPASS-O8, the treatment of pre-Compass documents,
in [COMPASS-0004](Plan.Toolchain.md). Source headers, which COMPASS-O8 also
covers ([COMPASS-0002](Spec.SourceHeaders.md)), are left to a later stage.

Two migrations done before the skill existed test the plan: Lexis's, two
documents migrated one at a time by these rules, and Classic's, twenty-six
documents migrated in batches by its own plan,
[CLASSIC-0032](../../classic/doc/Plan.CompassMigration.md). What they showed is
under [Case studies](#case-studies); the decisions were amended to match on
2026-11-18.

## Problem

Many repositories worth documenting with Compass were documented long before
it, some over years and without any LLM assistance. Their documents hold real
decisions and history, but:

- **They are invisible to the toolchain.** Without front-matter they are
  skipped (`--skip-unmarked`) or reported as errors, so they are not in the
  index, their decisions cannot be looked up, and agents reading the corpus
  through the `compass-*` skills do not find them.
- **Converting them by hand is tedious and error-prone.** Each needs a genre,
  front-matter, decision records with full identifiers, and code references
  pinned to the revision they meant. Done in bulk, this is never finished; done
  carelessly, it loses the meaning of old line references.
- **An assistant's help has a cost.** An assistant asked to "convert" a
  document tends to improve it: it updates stale facts, fills gaps, and
  smooths prose. The result no longer records what the author knew and decided
  at the time, and a document written entirely by its author would carry the
  assistant's words without saying where they came from.
- **Moving files loses history and breaks links.** Compass derives `authors` and
  `created` from Git. A document moved and rewritten in one commit may no longer
  be recognised as a rename, so its history appears to start at the
  migration, and links to its old path break.

## Goals

- A repeatable, per-document workflow that brings an existing document into
  the corpus with its content unchanged.
- An honest record: a migrated document says that an assistant reshaped it, and
  which original, at which revision, it was reshaped from.
- History preserved: authors and dates derived from Git stay those of the
  original's history.
- Old code references keep the meaning they had when the document was written.
- Every choice a person should make — genre, status, what counts as a
  decision — is proposed, never made, by the assistant.
- A visible backlog: what has been migrated, what is left unmarked, and why.

## Settled Decisions

All eleven decisions are proposals for the steward.
COMPASS-DRAFT-migration-D2, COMPASS-DRAFT-migration-D3,
COMPASS-DRAFT-migration-D4, COMPASS-DRAFT-migration-D5,
COMPASS-DRAFT-migration-D7, and COMPASS-DRAFT-migration-D8 were amended on
2026-11-18 from the [Case studies](#case-studies), and
COMPASS-DRAFT-migration-D9 to COMPASS-DRAFT-migration-D11 were added then.

### COMPASS-DRAFT-migration-D1 — Migration is a skill, one document at a time

**Status:** Proposed
**Context:** COMPASS-O8 asks whether pre-Compass documents should get a legacy
mode in the validator, a migration backlog report, or a `compass migrate`
assistant. The legacy mode exists: `--skip-unmarked` skips files without
front-matter and reports how many it skipped. What remains is the conversion
itself, which needs judgment for each document: choosing its genre, telling a
decision from a passing remark, and finding the definition an old line number
pointed at.
**Decision:** Migration is done by a skill, `compass-migrate`, agent-shaped
like `compass-author` and `compass-adopt`, and not by a toolchain command. It
works on one document per request, which the user names or chooses from a list
the skill proposes, and never on a whole directory at once. It proposes every
change, makes them once the user confirms, and checks the result with
`compass check`. It never commits. This adds a sixth skill to the five of
COMPASS-D1 and COMPASS-DRAFT-authoring-assistance-D1 in COMPASS-0003.
**Alternatives:** A `compass migrate` command (rejected: genre, records, and
symbol anchors are judgments, and a command that guesses them would write
plausible but wrong documents with the toolchain's authority); bulk migration
of a directory by the skill (rejected: too large to review against the
originals, and it would leave many documents in Draft at once with no one
accepting them); batches of one component's documents, as Classic migrated
(rejected by the steward on 2026-11-18: Classic's batches worked, but its
front-matter commit `56d400a` changed 39 files at once, the review this
decision exists to avoid). A repository's own migration plan does not override
this rule (COMPASS-DRAFT-migration-D10).

### COMPASS-DRAFT-migration-D2 — Migration reshapes form only

**Status:** Proposed
**Context:** COMPASS-0006 needed Classic's documents in Compass form for its
seed corpora, and ruled that migration "reshapes form only" and "MUST NOT add
facts that the historical document did not contain". The same rule protects
any migrated document: its value is that it records what its author knew and
decided at the time.
**Decision:** Migration changes only the form of a document. The permitted
changes are:

- adding front-matter;
- removing lines that state only what the front-matter now holds: a title line
  the new heading replaces, a version line (`schema-version` or
  `api-version`), and a status line, which would otherwise be a second,
  uncontrolled status beside the controlled one. A line giving the author's own
  date stays, since it records when the author dated the work, which can differ
  from the dates Git derives (CLASSIC-D109);
- renaming and reordering sections to follow the genre's §14 shape, keeping
  their text, and keeping section numbers that are cited elsewhere
  (COMPASS-DRAFT-migration-D9). Text a renamed heading displaces, such as the
  expansion of a name, stays as a line under the new heading;
- marking passages as records: a heading with a full identifier, and the
  original's sentences placed under the record's fields;
- writing "Not recorded in the original." where the shape requires a field or
  section the original lacks;
- adding what §12 requires: a `Table:` caption before each table and a
  `Description:` after each diagram. Where the original introduces a table with
  a lead-in such as "Tag mappings:", the lead-in becomes the caption;
- rewriting links, identifiers, and the original's own numbering as full
  identifiers (COMPASS-DRAFT-migration-D6);
- pinning code references (COMPASS-DRAFT-migration-D5);
- moving and renaming the file (COMPASS-DRAFT-migration-D4).

Nothing else changes. Stale facts, gaps, errors, and unclear prose stay as they
are. The skill reports what it notices of them as notes, for the user to fix in
a separate, ordinary edit after the reshape is committed, which then carries
its own provenance (COMPASS-DRAFT-migration-D11).
**Alternatives:** Migrate and update in one pass (rejected: the reader cannot
tell the original's knowledge from the assistant's, and the review against the
original becomes a review of new content); allow updates when the user asks,
as a later step of the same workflow (rejected: an ordinary edit after the
reshape commit does the same thing with clearer provenance); remove date lines
too, as the Lexis Spec's migration did (rejected: the author's date is lost
from the document when it differs from Git's, as the Spec's 2026-05-22 did
from Git's 2026-05-23).

### COMPASS-DRAFT-migration-D3 — A migrated document names its original in `provenance`

**Status:** Proposed
**Context:** §22 requires `provenance:` on any document authored or reviewed
with LLM help, and a migration is assisted. But `provenance: { assistant: ... }`
alone says the assistant may have written the content, which is false for a
form-only migration and misleading for a document its author wrote without
assistance. `provenance` accepts only `assistant` and `session` today; other
keys draw a warning.
**Decision:** A migrated document carries `provenance:` with its `assistant`
and a new key, `migrated-from`, whose value pins the original:
`<path>@<revision>`, the original's path and the last commit that changed it
before migration. The key states that the assistant reshaped the form of that
original and that the content is the original's, and it gives a reviewer
exactly what to compare against. It maps to PROV-O's `prov:wasDerivedFrom`,
as the rest of `provenance` maps to PROV-O (§7). If the content is later
edited with an assistant's help, `migrated-from` stays, and the edit's history
is in Git. §7 is amended to define the key; until then, the toolchain accepts it
as pending.

`session` names the session that wrote the original, when the original was
written with an assistant and the session is verified: its transcript shows the
original being written, not merely read or extended. Otherwise `session` is
left out. The migration's own session is not recorded in the front-matter; the
reshape commit records it. The Lexis Spec's migration first named the session
that had only added one section to the original; its review found the session
that wrote it, and the field was dropped as unverifiable
([Case studies](#case-studies)).
**Alternatives:** Set `provenance:` with only the assistant (rejected: claims
too much); describe the migration in `session:` (rejected: `session` names the
conversation that produced the document, and free text cannot be checked);
name the migration's session in `session` (rejected: the conversation that
produced the content is the original's, and a reader looking for its source
would be sent to the reshape);
omit `provenance:` for form-only changes (rejected: needs a weaker §22, and the
reader could not tell a migrated document from one written in Compass form);
a top-level field (rejected: the fact belongs with the record of the assisted
process).

### COMPASS-DRAFT-migration-D4 — Move and rename first, in a commit of its own

**Status:** Proposed
**Context:** Older documents often live outside the document directory, or
are named without a genre prefix (§10), so the toolchain does not check them in
place. The toolchain derives `authors` and `created` with `git log --follow`,
which follows a rename only when Git detects it by similarity; a file moved and
heavily rewritten in one commit may not be detected, and its history then
starts at the migration.
**Decision:** The skill moves the document into the document directory with
`git mv`, under its genre-prefixed name, and updates the links to it in the
repository's Markdown files and the relative links inside it. A document
already in a subdirectory of the document directory, such as Classic's
`doc/<component>/`, stays in that subdirectory, renamed in place
(CLASSIC-D93). A document already in place with a genre-prefixed name is not
moved. The skill then stops, and asks the user to commit the move before it
reshapes the document. Where the user has already made the rename, staged or
committed, as in both Lexis migrations, the skill checks that Git records it as
a rename and uses it.

A path that records what a commit changed, such as a row of a Log's Files
table or a Log's account of a moved file, is history, not a link, and keeps the
name the file had then (CLASSIC-D98). The skill may add "(now `<new path>`)"
after it, as the Lexis Log's Files row has. Links it cannot update, such as
forge URLs, links from other repositories, and references in source comments,
are listed in the report. Files that are not documents, such as `README.md`,
`CHANGELOG.md`, `CONTRIBUTING.md`, and licences, are never moved.
**Alternatives:** Leave documents in place and migrate only those already in
the document directory (rejected: most older documents are elsewhere); move
and reshape in one commit (rejected: loses the history Compass relies on); ask
for each file (rejected as the default, though the user may decline any
proposed move); flatten subdirectories into the document directory (rejected:
the toolchain accepts them, and they are the repository's convention); rewrite
historical paths to the new names (rejected: the Log would then say a commit
changed a file it did not).

### COMPASS-DRAFT-migration-D5 — Code references are pinned to the revision the document describes

**Status:** Proposed
**Context:** Older documents cite code as `file:line`, `file`, or a function
name. §9 requires references in `Log` and `Plan` to be pinned to a revision,
and recommends it elsewhere. A line number means something only at the revision
the author was looking at, and the code has since moved. Which revision that
is depends on the genre: a reference or design document is usually kept true to
the code until its last change, but a Log describes the work it records, and is
often written or edited after that work, once the code has moved on.
**Decision:** A Log's references are pinned to the commit that holds the work
it records, with the paths as they were at that commit; a reference to code as
it stood before the work, such as a file the work moved, is pinned to the
commit before the work began, written as its own abbreviated hash
(CLASSIC-D96). The work commit is found from the Log's own account and the
history, and the report gives the evidence. Every other genre's references are
pinned to the revision named in `migrated-from`, the last commit that changed
the original. In the Lexis Log the two were the same commit; in several of
Classic's Logs they were not.

A reference with a line is anchored to the definition enclosing that line at
its revision, `path:symbol@revision`, if there is one, and otherwise to the
line, `path#L<n>@revision`. A reference whose file did not exist at its
revision is left as it was and reported, since pinning it would invent a
meaning. The report lists every pin, so that the user can correct one where the
document plainly meant another state.
**Alternatives:** Pin to the current revision (rejected: changes what the
reference meant); pin to the commit that first added the document (rejected: a
document edited over years was usually kept true to the code until its last
change, and several of Classic's Logs were added after further changes); pin
every genre to `migrated-from` (rejected: a Log edited after its work would
point at code the work did not touch); leave references unpinned outside `Log`
and `Plan` (rejected: the revision is known now and lost later).

### COMPASS-DRAFT-migration-D6 — Records take provisional identifiers, keeping the original's numbering

**Status:** Proposed
**Context:** Older documents number their decisions informally ("Decision 3",
or a bare letter and number) or not at all, and refer to them by those numbers. Some, like four of
Classic's Surveys, use identifiers that look canonical but were assigned
without a ledger and collide.
**Decision:** A migrated document gets a provisional identifier,
`<NS>-DRAFT-<slug>`, and its records provisional ones under it. Where the
original numbers its decisions or questions, the provisional numbers keep
them, so that "Decision 3" becomes `<NS>-DRAFT-<slug>-D3`. Every reference to
them in the document is rewritten as the full identifier (`ref/short-record`),
and the report lists the mapping. Identifiers that look canonical but are not
in the ledger become provisional, and the report names the collisions. Numbers
are assigned with `compass assign` when the steward accepts the document.
**Alternatives:** Renumber records from 1 in order (rejected: breaks the link
between the original's references and its records, and between the document
and anything outside it that cites "Decision 3"); keep canonical-looking
identifiers that do not collide (rejected: only the ledger allocates numbers,
§13).

### COMPASS-DRAFT-migration-D7 — The assistant proposes statuses; the steward sets them

**Status:** Proposed
**Context:** An older document often describes settled work: decisions in
force, a design that matches the code, a finished piece of work. Its Compass
statuses would be authoritative (`Accepted`, `Implemented`, `Current`), which
an assistant never sets (§6).
**Decision:** A migrated document is written with status `Draft` and its
decision records `Proposed`. The report proposes the status for each, quoting
the original's wording that supports it ("we decided", "this is how it
works"), and the steward sets them on accepting the document. Each proposal is
a value from the genre's own vocabulary (§6), named with the family it belongs
to: a Log becomes `Implemented`, a Spec or Ref becomes `Current`, and a Plan
becomes `Accepted` or `Implemented`. `Accepted` is not a Spec status: the Lexis
Spec was first set to it and corrected to `Current` (`0efe8a8`). For a
reference genre, the report also says whether the document matches the code
as it is now, since `Current` claims that it does; where it does not, the
proposal is to keep `Draft` until the revision of COMPASS-DRAFT-migration-D11
is done.
**Alternatives:** Let the skill set the statuses the original implies
(rejected: §6, and the original's wording is often ambiguous); leave statuses
out of the report (rejected: the steward would have to find the evidence
again); propose `Accepted` for every genre and let the toolchain object
(rejected: `vocab/status` reports the error only after the steward has set
it).

### COMPASS-DRAFT-migration-D8 — A migration Log records a large backlog; `AGENTS.md` records a small one

**Status:** Proposed
**Context:** Migration of a mature repository takes many sessions. Without a
record, it is unclear which unmarked files are waiting, which were left
deliberately, and why: an unmarked file looks neglected either way. For a
handful of documents a Log costs more than it records: Lexis migrated two, and
the migration line `compass-adopt` writes in `AGENTS.md` was record enough.
Classic migrated twenty-six, and its Log,
[CLASSIC-0036](../../classic/doc/Log.CompassMigration.md), holds the move and
reshape commits of each batch and the reasons for what it left.
**Decision:** Where more than three documents are unmarked when the first
migration begins, the repository keeps one `Log`, `Log.Migration.md`, created
with that migration. It lists each migrated document with its original path,
its `migrated-from` revision, and its move and reshape commits; each document
left unmarked or retired, with the reason; and the notes the skill made about
stale content. The skill drafts an `## Update <date> — <title>` section after
the user commits a reshape, pinned to that commit, as §9 requires of a Log.

Where three or fewer are unmarked, the migration line in `AGENTS.md` is the
record: it names the documents still unmarked and says that checks run with
`--skip-unmarked`. The skill updates it with each move, and removes it, with
the advice to use `--skip-unmarked`, when no unmarked document remains, as the
Lexis Spec's reshape did. A repository whose own migration plan keeps a Log
under another name, such as Classic's `Log.CompassMigration.md`, uses that one
(COMPASS-DRAFT-migration-D10).
**Alternatives:** No record, relying on `--skip-unmarked`'s count (rejected:
a count gives no reasons); a Log for every migration, however small
(rejected: for two documents it records less than the `AGENTS.md` line and Git
already do); a Memo host (rejected: the backlog is history and progress, not
durable properties of the system).

### COMPASS-DRAFT-migration-D9 — Section numbers that are cited elsewhere are kept

**Status:** Proposed
**Context:** Older documents often number their sections, and other documents,
source comments, and commit messages cite them by number: "§4.3", "per spec
Section 3.3". The Lexis Spec was cited by section number from a Log, a Plan, and
`src/text-processing.lisp`. A §14 heading such as "Required Tag Vocabulary"
carries no number, and renaming a heading changes its anchor.
**Decision:** Before renaming headings, the skill searches the repository, and
the federated repositories that are checked out, for citations of the
document's section numbers. Where any exist, the numbers are kept and the
genre's heading is written after them, as the Lexis Spec's "4. Required Tag
Vocabulary" is. The report lists the citations found and every anchor that
changed, and the skill rewrites links to the changed anchors in the
repository's Markdown files. Where none exist, the numbers are kept if the
document's own text cites them, and otherwise follow the user's choice.
**Alternatives:** Drop the numbers for Compass-style headings and rewrite each
citation (rejected: citations in source comments and other repositories cannot
all be found or rewritten, and the rewrite is not form-only); keep the
original headings (rejected: the genre's shape is part of the form the
migration exists to give).

### COMPASS-DRAFT-migration-D10 — A repository's own migration plan takes precedence

**Status:** Proposed
**Context:** A repository may plan its migration itself before the skill is
used, as Classic did in [CLASSIC-0032](../../classic/doc/Plan.CompassMigration.md).
Such a plan records the steward's choices for that repository: Classic keeps its
component subdirectories (CLASSIC-D93), pins its Logs to their work commits
(CLASSIC-D96), and keeps historical paths (CLASSIC-D98). Defaults that ignored
it would undo decisions the steward has made.
**Decision:** Before its first proposal, the skill looks for the repository's
own migration plan: a Plan, or a document the `AGENTS.md` migration line names,
whose subject is the migration to Compass. Where the plan and these decisions
differ, the plan's decision applies, and the report names each difference with
both decisions' identifiers. The plan cannot relax what makes the skill safe:
one document per request (COMPASS-DRAFT-migration-D1), form only
(COMPASS-DRAFT-migration-D2), never committing, and never setting an
authoritative status or `approved-by` (§6). Where the plan calls for one of
those, as Classic's batches did, the skill says so and keeps its own rule.
**Alternatives:** The skill's decisions always apply (rejected: the
repository's steward has already decided); the repository's plan always
applies (rejected: a plan written before the skill may call for bulk changes or
for an assistant to set statuses, which the skill must not do).

### COMPASS-DRAFT-migration-D11 — The skill ends at the reshape; revision is a separate edit, before acceptance where it matters

**Status:** Proposed
**Context:** Both Lexis migrations were followed by review and revision before
acceptance. The Spec's reshape was form-only (`c471246`), but its content
described tags the code did not implement, so accepting it as `Current` straight
after the reshape would have claimed it matched the code. Its revision
(`69f7748` to `9a25a96`) added the RFC 2119 keywords, a conformance walkthrough,
and an afterword on what was implemented, by tables of numbered proposals the
steward decided one by one. The review after it found what such a revision
risks: a keyword search that missed a capitalised "Required.", a resolution the
assistant itself had proposed that contradicted another section, and an example
calling a macro that does not exist.
**Decision:** `compass-migrate` ends when the reshape is checked and reported.
Its report hands off: to `compass-review` for a review against the original,
and, for content changes, to an ordinary assisted edit, with
`compass-author` for any new document such as a split part or the migration
Log. The report lists the notes on stale content as the starting point for that
edit. For a reference genre whose content does not match the code, the report
advises that the revision come after the reshape is committed and before the
steward sets `Current` (COMPASS-DRAFT-migration-D7), so that the reshape commit
remains the form-only state a reviewer compares with the original
(COMPASS-DRAFT-migration-O3).
**Alternatives:** The skill also revises content, as a second stage (rejected
by the steward on 2026-11-18: content changes need the judgment
`compass-review` and an ordinary edit already bring, and a migration skill that
revises invites the improving that COMPASS-DRAFT-migration-D2 forbids);
revision only after acceptance, as COMPASS-DRAFT-migration-D2 first said
(rejected: a reference document would be accepted as `Current` while known to
be wrong).

## The `compass-migrate` skill

### Prerequisites

- The repository has been set up by `compass-adopt`: `compass.sexp`, a
  `.mailmap` mapping every identity in the history, the document directory, and
  its ledger.
- `compass check --skip-unmarked` reports no errors, so that new errors belong
  to the migration. Classic at `55c2390`, before its baseline commit, fails
  this with 47 errors and has no ledger; at `dfeb862` it passes.
- The working tree is clean, or holds only a rename of the document to be
  migrated, so that the move commit holds only the move.
- If the repository has its own migration plan, the skill has read it
  (COMPASS-DRAFT-migration-D10).

### Workflow for one document

Table: The steps of migrating one document, and who acts at each.

| Step | The skill | The user |
|---|---|---|
| 1. Choose | Lists candidate files without front-matter, current documents first, and proposes one | Names the document to migrate |
| 2. Classify | Proposes a genre, subtype, scope, slug, and title, giving the reasons; for a document mixing genres, names the closest two; finds citations of its section numbers | Confirms or corrects |
| 3. Move | `git mv` to `<doc-dir>/<Genre>.<Topic>.md`, or in place in its subdirectory; updates links but not historical paths; updates the `AGENTS.md` migration line; lists the links it could not update | Commits the move |
| 4. Reshape | Adds front-matter with `provenance.migrated-from`; arranges the §14 shape, keeping cited section numbers; adds §12 captions; marks records; rewrites numbering and links; pins code references | Reviews the diff |
| 5. Check | Runs `compass check` on the document and fixes errors it introduced | — |
| 6. Report | Lists the record mapping, every pin with its evidence, every link and anchor changed or left, differences from the repository's own plan, proposed statuses from the genre's vocabulary with their evidence, and notes on stale content | Reviews against the original, perhaps with `compass-review` |
| 7. Hand off | After the commit, drafts the migration Log's update, or removes the `AGENTS.md` line when none remain; points to `compass-review` and to a revision edit | Commits, revises where needed, sets statuses, and runs `compass assign` when ready |

### Choosing the genre

The skill proposes from the document's role, not its filename:

- a design that still matches the code: `Ref`, `Spec`, or `Arch`;
- an account of a piece of work done: `Log`;
- a plan for work, done or not: `Plan`, with status proposed from what was
  built;
- an exploration of whether to build something: `Survey`;
- a comparison or assessment: `Eval` with its subtype;
- instructions for users: `Guide`;
- an abandoned idea: the genre it would have had, proposed as `Rejected` or
  `Withdrawn`, or left unmarked and recorded as such in the migration Log.

### Order of migration

Documents that describe the current system come first, since agents and
readers rely on them most; then documents of past work, as Logs; then the
rest, or none of the rest. A repository need not migrate everything: a file
left unmarked and recorded in the migration Log with its reason is a decision,
not a backlog item.

## Case studies

Two migrations were done before the skill existed. Lexis's followed this
plan's decisions by hand; Classic's preceded the plan and followed its own.
Between them they confirmed most of the decisions and changed six. Commit
hashes are those of each repository.

### Lexis: two documents, one at a time

On 2026-11-15 and 2026-11-16 an assistant migrated Lexis's two older
documents, a Log and a Spec, in the session recorded in this plan's `cites:`.
Lexis had been adopted at `cf1147b`, and `compass check --skip-unmarked`
passed there.

- **`doc/DevLog.Passthrough.md` → `doc/Log.Passthrough.md`** (`LEXIS-DRAFT-passthrough`):
  the steward committed the rename himself (`836f386`); then came the reshape
  (`aea04fd`), and a `compass-review` and its fixes (`27f21c3`). The
  original's five numbered decisions became records
  `LEXIS-DRAFT-passthrough-D1` to `LEXIS-DRAFT-passthrough-D5`, keeping their
  numbers; missing fields read "Not recorded in the original."; the code
  references were pinned to the commit of the work, which was also the
  original's last change.
- **`doc/spec.md` → `doc/Spec.Lexis.md`** (`LEXIS-0001`): the move (`8d7bae4`),
  then a form-only reshape (`c471246`, 36 lines added and 17 removed), then a
  revision of its content (`69f7748` to `9a25a96`), a review, numbering
  (`0f4a92d`), and the status `Current` (`0efe8a8`).

Table: What the Lexis migrations showed, and the decision each bears on.

| Finding | Decision |
|---|---|
| Moving first, then reshaping, kept the history: `git log --follow` traced the Spec through two renames to its first commit | COMPASS-DRAFT-migration-D4, confirmed |
| Both times the steward made the rename before the skill's step, once committed and once only staged | COMPASS-DRAFT-migration-D4, amended to use such a rename |
| The Spec's chapters are cited by number from a Log, a Plan, and a source comment, so their numbers were kept with "Required" headings | COMPASS-DRAFT-migration-D9, added |
| Header lines for version, date, and status were removed; the Spec's author's date, a day before Git's, was lost with them | COMPASS-DRAFT-migration-D2, amended to keep date lines |
| A table's lead-in became its `Table:` caption, and the old title's expansion stayed as a subtitle | COMPASS-DRAFT-migration-D2, amended |
| The Spec could not be `Current` before its content was revised; the revision came after the reshape and before acceptance | COMPASS-DRAFT-migration-D11, added |
| The Spec's `provenance.session` first named a session that had only extended it; the review found the one that wrote it | COMPASS-DRAFT-migration-D3, amended |
| The Spec was first given the status `Accepted`, which is not in its genre's vocabulary | COMPASS-DRAFT-migration-D7, amended |
| A migration Log for two documents would have recorded less than the `AGENTS.md` line did | COMPASS-DRAFT-migration-D8, amended |
| Rewriting history to remove a committed transcript changed every hash, and each `migrated-from` and pin had to be re-pinned by hand | Roadmap step 2: check the pin |
| The only link from outside, Seed's `SEED-0011` citing the old path, was reported and fixed in Seed after numbering | COMPASS-DRAFT-migration-O5 |

### Classic: twenty-six documents in batches

Classic planned its migration in [CLASSIC-0032](../../classic/doc/Plan.CompassMigration.md)
(`55c2390`, 2026-10-11) and recorded it in
[CLASSIC-0036](../../classic/doc/Log.CompassMigration.md). A baseline commit
(`dfeb862`) added the ledger, the `.mailmap`, and CI, and gave colliding
Survey records provisional identifiers. Ten renames came in a commit of their
own (`fdad517`). Front-matter, two splits, and links followed for 39 files in
one commit (`56d400a`), and decision records and pins in five component
batches. The steward set statuses and numbered every document by 2026-10-14.

Table: What the Classic migration showed, and the decision each bears on.

| Finding | Decision |
|---|---|
| Renames committed alone, with no content change, kept every document's history | COMPASS-DRAFT-migration-D4, confirmed |
| Documents stayed in `doc/<component>/` subdirectories, renamed in place (CLASSIC-D93) | COMPASS-DRAFT-migration-D4, amended |
| Paths in a Log's Files table were kept as records of their commits (CLASSIC-D98) | COMPASS-DRAFT-migration-D4, amended |
| Logs were pinned to the commit of their work and its parent, which differs from their last change for several Logs (CLASSIC-D96) | COMPASS-DRAFT-migration-D5, amended |
| About 95 decisions in four styles became records with no invented alternatives (CLASSIC-D95) | COMPASS-DRAFT-migration-D6, confirmed |
| Every document was migrated as `Draft` and the steward set statuses (CLASSIC-D94) | COMPASS-DRAFT-migration-D7, confirmed |
| In-body status lines were removed, but dates kept (CLASSIC-D109) | COMPASS-DRAFT-migration-D2, amended |
| Its own plan made choices this plan's defaults would have undone | COMPASS-DRAFT-migration-D10, added |
| Batches by component worked, but one commit changed 39 files | COMPASS-DRAFT-migration-D1, kept: the steward chose one at a time |
| Two originals were split during migration (CLASSIC-D101, CLASSIC-D102), and the pieces do not record what they came from | COMPASS-DRAFT-migration-O1 |
| A Log, CLASSIC-0036, recorded each batch's commits and what was left | COMPASS-DRAFT-migration-D8, confirmed for a large backlog |

### Trial: Lexis replayed with the skill

On 2026-11-18 the drafted `compass-migrate` skill was followed, step by step,
in a scratch clone of Lexis at `cf1147b`, the state the steward's migration
began from, with the Compass toolchain at `6a7c860`. It migrated the Log, then
the Spec, in six commits: a move, a reshape, and an update of the `AGENTS.md`
line for each. The result checks with no errors and one `vocab/pending`
warning per document, and Git still derives each document's authors and
creation date through its rename. The reshape of the Spec added 36 lines and
removed 12, against the steward's 36 and 17 (`c471246`).

The two results agree on the genre, scope, identifier, title,
`migrated-from`, heading spine, and records of both documents. The table lists
where they differ.

Table: Where the skill's migration of Lexis differed from the steward's, and what each difference suggests.

| Difference | Suggests |
|---|---|
| The skill left out the Log's `session:`: the transcript of that session ends at the plan for the work, before the Log was written. The steward's Log names it | COMPASS-DRAFT-migration-D3 working as intended |
| The skill named the session that wrote the Spec, found in its transcript; the steward's reshape named one that had only extended it, which its review caught | COMPASS-DRAFT-migration-D3 working as intended |
| The skill kept both date lines; the steward removed them | COMPASS-DRAFT-migration-D2 as amended |
| The skill's search for cited section numbers also found citations in `README.md` and `examples/demo.lisp`, which the steward's plan had not listed | COMPASS-DRAFT-migration-D9 working as intended |
| Where a decision's context or alternatives are given elsewhere in the original, the skill wrote "Not recorded in the original."; the steward wrote "See [Problem](#problem).", and in Outstanding Work, "Deferred; see" the record of the deferral | A pointer to where the original records it, rather than "Not recorded", which is untrue there |
| The skill pinned only the paths the original names; the steward also added a pinned reference to each symbol the original names in a named file | Adding a pinned reference beside a symbol the original names, as a permitted addition |
| Both moved sections the original already had in an order the Log spine accepts | Reordering only where the original's order breaks the spine |
| The skill marked a Spec chapter "Required" only where its text states requirements, leaving chapters 3 and 7 unmarked; the steward marked both, and the review later found chapter 7 was not normative | Proposing each chapter's normativity, with its evidence, for the user to decide |
| The skill kept the words of a heading and of a table's lead-in, such as "Core" and "Tag mappings."; the steward dropped "Core" and expanded the captions | COMPASS-DRAFT-migration-D2 working as intended |
| The skill proposed the Spec first, as the order of migration says; the steward chose the Log first | The order is a proposal; the user names the document |

The four differences in the middle of the table are open for the steward's
decision; until then the skill and COMPASS-DRAFT-migration-D2 stand as they
are.

## Tradeoffs and Non-Goals

- **Not an editor.** Migration never makes a document more correct. A migrated
  document may be accepted while stale; its staleness is then visible, in the
  report and the migration Log, rather than hidden in a rewrite.
- **Two commits per document.** Committing the move before the reshape costs
  the steward an extra commit, in exchange for history that `--follow` can
  trace. One document at a time makes this slower than Classic's batches,
  in exchange for reviews of a size a person can check against the original.
- **Source headers are out of scope here.** COMPASS-O8 also covers reshaping
  the ancestor repositories' source headers into the form of COMPASS-0002;
  that is a later stage of this plan, under the same form-only rule.
- **No translation between corpora.** A document that belongs to another
  project's namespace stays there; the skill does not move documents between
  repositories.

## Open Questions

### COMPASS-DRAFT-migration-O1 — Documents that mix genres

A long-lived design document often holds a plan, a log of what was built, and
reference material. The skill names the closest two genres and the user
chooses one, so the others' content sits in the wrong shape. Should migration
ever split one original into two documents, both with `migrated-from` naming
it, or is splitting an edit for after acceptance?

Classic split two originals during its migration: its schema contract into a
Spec, a Guide, and a Survey (CLASSIC-D101), and the planned persistence
backends out of its persistence reference into an Arch (CLASSIC-D102). None of
the new pieces records what it came from; each has only `provenance:
assistant` and `relates-to`. Under COMPASS-DRAFT-migration-D11 the skill does
not split, and reports the mix instead. If a split is made in the edit that
follows, should each new piece carry `migrated-from` naming the original, as
the piece that keeps the original's history does?

### COMPASS-DRAFT-migration-O2 — Listing the backlog

`--skip-unmarked` reports only a count. The skill can find files without
front-matter itself, but a toolchain option listing them, and which of them the
migration Log records as deliberately unmarked, would let `compass check`
report the backlog. Is that worth a toolchain change, and should a file left
deliberately unmarked be declared in `compass.sexp` instead?

### COMPASS-DRAFT-migration-O3 — Checking that a migration is form-only

A reviewer compares the migrated document with its original at
`migrated-from`. A mechanical aid could compare the two texts with front-matter,
headings, field labels, identifiers, and code references removed, and report
words added. Should this be a toolchain rule, a `compass-review` dimension
applied whenever `migrated-from` is present, or both?

The Lexis Spec narrows the question. Its form-only state is the reshape commit
`c471246`; the revision after it (COMPASS-DRAFT-migration-D11) differs from the
original by design. So the comparison is between the original at
`migrated-from` and the reshape commit, not the current text. The migration
Log records that commit (COMPASS-DRAFT-migration-D8); where there is no Log,
should the reshape commit be found from Git, as the first commit to give the
file front-matter, or recorded in the front-matter beside `migrated-from`?

**Resolved (2026-11-18):** the comparison is a `compass-review` dimension,
"Migration fidelity", applied whenever `migrated-from` is present; a
mechanical aid may extend it later, but is not built now. The reshape commit is
found from Git, with no new field: it is the oldest commit that added the
`migrated-from:` line, `git log --follow -S'migrated-from:' -- <path>`, or the
one a migration Log records. In Lexis this finds `c471246` for the Spec and
`aea04fd` for the Log, and `git log -1 <move commit>^ -- <old path>` confirms
both `migrated-from` revisions.

### COMPASS-DRAFT-migration-O4 — Dates older than the repository

When a document was written long before it was committed, or was imported from
another repository without its history, Git dates it from the commit. Should
the skill ask for an explicit `created` whenever the first commit is a bulk
import, and how is it to recognise one?

**Partly resolved (2026-11-18):** in both Lexis migrations the steward chose
Git's date over an explicit `created`, though the Spec's own date line was a
day earlier, and COMPASS-DRAFT-migration-D2 now keeps such date lines in the
body. The skill therefore leaves `created` to Git and reports any date line
that differs from it. A bulk import, where Git's date may be years late, is
still open.

### COMPASS-DRAFT-migration-O5 — Links from outside the repository

A move breaks links the skill cannot update: forge URLs, published sites, and
other repositories' documents. Should the skill leave a stub at the old path
pointing to the new one, and for how long, or only report the breakage?

In Lexis, the one such link was Seed's `SEED-0011`, which cited the Spec's old
path. Reporting it was enough: once the Spec was numbered, Seed replaced the
path with a `relates-to` entry. Neither case study left a stub.

### COMPASS-DRAFT-migration-O6 — Two assistants in one `provenance`

When the original was itself written with an assistant, a migrated document
involves two: the one that wrote the original and the one that reshaped it.
`assistant` names the second, and `session`, by COMPASS-DRAFT-migration-D3,
the first's conversation. The Lexis Log carries both: `assistant:
claude-opus-5-5` for the migration, and the session of the Claude Opus 4.6
conversation that wrote the original. A reader may take the two fields to
describe one process. Should `provenance` also name the original's assistant,
with a key such as `original-assistant`, or is the session, which names it,
enough?

## Prior Art

Table: Prior systems and practices and what this plan draws from each.

| System | What to draw from |
|---|---|
| Strangler fig application (Fowler) | Replace a legacy system piece by piece beside it, never all at once: migration one document at a time, with `--skip-unmarked` as the boundary |
| Diátaxis | Improve documentation in small, complete steps rather than a planned restructure |
| COMPASS-0006's seed corpora | The form-only rule, and a review of each migrated document against its original |
| PROV-O | `prov:wasDerivedFrom` as the meaning of `migrated-from` |
| Git rename detection (`git log --follow`) | The constraint behind moving in a commit of its own |
| Lint baselines (detekt, Android Lint) | Adopt a checker on an old codebase by recording the existing state and holding new work to the rule: the migration Log as the record of what is deliberately left |
| Lexis's migration ([Case studies](#case-studies)) | One document at a time under these rules; a form-only reshape commit followed by revision before acceptance |
| Classic's migration, CLASSIC-0032 and CLASSIC-0036 | Work-commit pins for Logs, historical paths kept, dates kept, subdirectories kept; batches, not adopted |

## Roadmap

1. **This plan (done, 2026-11-17; amended 2026-11-18).** The decisions and the
   workflow, then the amendments from the [Case studies](#case-studies), for
   the steward's review.
2. **Provenance key (done, 2026-11-18).** The toolchain accepts
   `provenance.migrated-from` as pending, naming COMPASS-DRAFT-migration-D3
   (`vocab/pending`); `fm/types` checks that it is `<path>@<commit>`, and a new
   rule, `ref/migrated-from`, that the commit exists and that the path was a
   file there; `skills/reference/frontmatter.md`, `vocabularies.md`, and
   `toolchain.md` describe it; tests cover each. On acceptance, §7 is amended
   to define it.
3. **The skill (drafted, 2026-11-18).** `skills/compass-migrate/SKILL.md`;
   COMPASS-0003's skill set and roadmap list it; `compass-adopt`, the AGENTS
   snippet, and the README's note on mature codebases name it. The §23 S9 row
   of COMPASS-0001 is unchanged, since it names the skills it lists without
   excluding others, as COMPASS-0003 found for `compass-adopt`.
4. **Review (done, 2026-11-18).** `compass-review` gains a "Migration
   fidelity" dimension, which compares a migrated document at its reshape
   commit with its original at `migrated-from`, as COMPASS-DRAFT-migration-O3
   was resolved.
5. **Trials (now).** In scratch clones, so that neither repository changes:
   - Lexis from `cf1147b`, migrating both documents, compared with the
     steward's results (`836f386` and `aea04fd`; `8d7bae4` and `c471246`);
   - Classic from `dfeb862`, migrating five documents one at a time (a Ref in a
     subdirectory, a refactoring Log, the Spec that was split, a Guide, and a
     Survey that needs no move), with its own plan in force, compared with
     `56d400a` and the Phase 3 batches; and a check that the skill refuses to
     start at `55c2390`.

   What they teach is recorded as updates to this plan.
6. **Acceptance.** The steward accepts, amends, or rejects
   COMPASS-DRAFT-migration-D1 to COMPASS-DRAFT-migration-D11.
7. **COMPASS-O8.** The steward records this plan as its answer for documents,
   in COMPASS-0004.
8. **Source headers (later).** Reshaping older source headers into the form of
   COMPASS-0002, under the same form-only rule.
