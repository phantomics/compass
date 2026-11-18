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
cites:
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
open-questions:
  - COMPASS-DRAFT-migration-O1
  - COMPASS-DRAFT-migration-O2
  - COMPASS-DRAFT-migration-O3
  - COMPASS-DRAFT-migration-O4
  - COMPASS-DRAFT-migration-O5
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

All eight decisions are proposals for the steward.

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
accepting them).

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
- renaming and reordering sections to follow the genre's §14 shape, keeping
  their text;
- marking passages as records: a heading with a full identifier, and the
  original's sentences placed under the record's fields;
- writing "Not recorded in the original." where the shape requires a field or
  section the original lacks;
- rewriting links, identifiers, and the original's own numbering as full
  identifiers (COMPASS-DRAFT-migration-D6);
- pinning code references (COMPASS-DRAFT-migration-D5);
- moving and renaming the file (COMPASS-DRAFT-migration-D4).

Nothing else changes. Stale facts, gaps, errors, and unclear prose stay as they
are. The skill reports what it notices of them as notes, for the user to fix in
a separate, ordinary edit after the migration is accepted, which then carries
its own provenance.
**Alternatives:** Migrate and update in one pass (rejected: the reader cannot
tell the original's knowledge from the assistant's, and the review against the
original becomes a review of new content); allow updates when the user asks,
as a later step of the same workflow (rejected: an ordinary edit after
acceptance does the same thing with clearer provenance).

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
**Alternatives:** Set `provenance:` with only the assistant (rejected: claims
too much); describe the migration in `session:` (rejected: `session` names the
conversation that produced the document, and free text cannot be checked);
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
repository's Markdown files and the relative links inside it. It then stops,
and asks the user to commit the move before it reshapes the document. Several
documents' moves may share one commit. Links it cannot update, such as forge
URLs, links from other repositories, and references in source comments, are
listed in the report. Files that are not documents, such as `README.md`,
`CHANGELOG.md`, `CONTRIBUTING.md`, and licences, are never moved.
**Alternatives:** Leave documents in place and migrate only those already in
the document directory (rejected: most older documents are elsewhere); move
and reshape in one commit (rejected: loses the history Compass relies on); ask
for each file (rejected as the default, though the user may decline any
proposed move).

### COMPASS-DRAFT-migration-D5 — Code references are pinned to the original's revision

**Status:** Proposed
**Context:** Older documents cite code as `file:line`, `file`, or a function
name. §9 requires references in `Log` and `Plan` to be pinned to a revision,
and recommends it elsewhere. A line number means something only at the revision
the author was looking at, and the code has since moved.
**Decision:** Each code reference is pinned to the revision named in
`migrated-from`, the last commit that changed the original. A reference with a
line is anchored to the definition enclosing that line at that revision,
`path:symbol@revision`, if there is one, and otherwise to the line,
`path#L<n>@revision`. A reference whose file did not exist at that revision is
left as it was and reported, since pinning it would invent a meaning. The
report lists every pin, so that the user can correct one where the document
plainly meant an earlier state.
**Alternatives:** Pin to the current revision (rejected: changes what the
reference meant); pin to the commit that first added the document (rejected: a
document edited over years was usually kept true to the code until its last
change); leave references unpinned outside `Log` and `Plan` (rejected: the
revision is known now and lost later).

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
works"), and the steward sets them on accepting the document.
**Alternatives:** Let the skill set the statuses the original implies
(rejected: §6, and the original's wording is often ambiguous); leave statuses
out of the report (rejected: the steward would have to find the evidence
again).

### COMPASS-DRAFT-migration-D8 — A migration Log records the backlog

**Status:** Proposed
**Context:** Migration of a mature repository takes many sessions. Without a
record, it is unclear which unmarked files are waiting, which were left
deliberately, and why: an unmarked file looks neglected either way.
**Decision:** Each repository being migrated keeps one `Log`,
`Log.Migration.md`, created with the first migration. It lists each migrated
document with its original path and revision, each document left unmarked or
retired with the reason, and the notes the skill made about stale content. The
skill drafts an `## Update <date> — <title>` section after the user commits a
migration, pinned to that commit, as §9 requires of a Log. The Log is also the
record of the move commits.
**Alternatives:** No record, relying on `--skip-unmarked`'s count (rejected:
a count gives no reasons); a Memo host (rejected: the backlog is history and
progress, not durable properties of the system).

## The `compass-migrate` skill

### Prerequisites

- The repository has been set up by `compass-adopt`: `compass.sexp`, a
  `.mailmap` mapping every identity in the history, the document directory, and
  its ledger.
- `compass check --skip-unmarked` reports no errors, so that new errors belong
  to the migration.
- The working tree is clean, so that the move commit holds only the move.

### Workflow for one document

Table: The steps of migrating one document, and who acts at each.

| Step | The skill | The user |
|---|---|---|
| 1. Choose | Lists candidate files without front-matter, current documents first, and proposes one | Names the document to migrate |
| 2. Classify | Proposes a genre, subtype, scope, slug, and title, giving the reasons; for a document mixing genres, names the closest two | Confirms or corrects |
| 3. Move | `git mv` to `<doc-dir>/<Genre>.<Topic>.md`; updates links; lists the links it could not update | Commits the move |
| 4. Reshape | Adds front-matter with `provenance.migrated-from`; arranges the §14 shape; marks records; rewrites numbering and links; pins code references | Reviews the diff |
| 5. Check | Runs `compass check` on the document and fixes errors it introduced | — |
| 6. Report | Lists the record mapping, every pin, every link changed or left, proposed statuses with their evidence, and notes on stale content | Reviews against the original, perhaps with `compass-review` |
| 7. Accept | Drafts the migration Log's update after the commit | Commits, sets statuses, and runs `compass assign` when ready |

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

## Tradeoffs and Non-Goals

- **Not an editor.** Migration never makes a document more correct. A migrated
  document may be accepted while stale; its staleness is then visible, in the
  report and the migration Log, rather than hidden in a rewrite.
- **Two commits per batch.** Committing moves before reshapes costs the
  steward an extra commit, in exchange for history that `--follow` can trace.
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

### COMPASS-DRAFT-migration-O4 — Dates older than the repository

When a document was written long before it was committed, or was imported from
another repository without its history, Git dates it from the commit. Should
the skill ask for an explicit `created` whenever the first commit is a bulk
import, and how is it to recognise one?

### COMPASS-DRAFT-migration-O5 — Links from outside the repository

A move breaks links the skill cannot update: forge URLs, published sites, and
other repositories' documents. Should the skill leave a stub at the old path
pointing to the new one, and for how long, or only report the breakage?

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

## Roadmap

1. **This plan (now).** The decisions and the workflow, for the steward's
   review.
2. **Acceptance.** The steward accepts, amends, or rejects
   COMPASS-DRAFT-migration-D1 to COMPASS-DRAFT-migration-D8.
3. **Provenance key.** The toolchain accepts `provenance.migrated-from` as
   pending, naming this plan, and checks that it pins a path at a revision
   that exists; `frontmatter.md` describes it; tests cover both. On
   acceptance, §7 is amended to define it.
4. **The skill.** `skills/compass-migrate/SKILL.md`, tried on scratch
   repositories with older documents, as `compass-adopt` was; COMPASS-0003's
   skill set and roadmap list it; the README's note on mature codebases names
   it.
5. **Review.** `compass-review` checks a migrated document against its
   original, by the answer to COMPASS-DRAFT-migration-O3.
6. **First migration.** One of the steward's pre-Compass repositories, to be
   chosen, migrated in part, with its migration Log; what it teaches is
   recorded as updates to this plan.
7. **COMPASS-O8.** The steward records this plan as its answer for documents,
   in COMPASS-0004.
8. **Source headers (later).** Reshaping older source headers into the form of
   COMPASS-0002, under the same form-only rule.
