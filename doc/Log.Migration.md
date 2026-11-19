---
id:            COMPASS-DRAFT-migration-log
title:         Compass Migration Skill Development Log
genre:         Log
scope:         component
program:       Compass
component:     authoring-assistance
language:      en
status:        Draft
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-DRAFT-migration
  - COMPASS-0001
  - COMPASS-0003
  - COMPASS-0004
  - COMPASS-DRAFT-pending-tool
  - COMPASS-0008
  - CLASSIC-0032
  - LEXIS-0001
decisions:
  - COMPASS-DRAFT-migration-log-D1
  - COMPASS-DRAFT-migration-log-D2
  - COMPASS-DRAFT-migration-log-D3
---

# Compass Migration Skill: Development Log

This document chronicles the building of the `compass-migrate` skill, from
2026-11-18 to 2026-11-19, in eight commits from `6a7c860` to `5d746f3`: the
toolchain's support for `provenance.migrated-from`, the skill and the review
dimension that checks its work, two trials against migrations done by hand,
the amendments to [COMPASS-DRAFT-migration](Plan.Migration.md) they led to,
and `Compass.md` 0.5.0, which defines the new keys.

## Problem

[COMPASS-DRAFT-migration](Plan.Migration.md), written on 2026-11-17 and
committed at `c7e88a7`, planned a sixth skill to bring documents written
before Compass into a corpus without changing their content. The skill did not
exist, and the toolchain treated the plan's `provenance.migrated-from` as an
unknown key, warning on it and checking nothing. Two migrations had meanwhile
been done without the skill: Lexis's two documents, one at a time by the plan's
rules ([LEXIS-0001](../../lexis/doc/Spec.Lexis.md) among them), and Classic's
twenty-six, in batches, by its own plan,
[CLASSIC-0032](../../classic/doc/Plan.CompassMigration.md). Both were evidence
the plan had not yet used.

## Design Decisions

These are the choices made while building; the skill's behaviour is decided in
COMPASS-DRAFT-migration.

### COMPASS-DRAFT-migration-log-D1 — `migrated-from` is checked by a rule of its own

**Status:** Proposed
**Context:** A `migrated-from` value is a path at a revision, as a pinned code
reference is, and `ref/code-exists` already resolves those against Git in one
batched process per repository. But the value lives in front-matter, not in a
code span of the body, and what it names is a whole original document, not a
place in code, so the messages a reader needs differ.
**Decision:** A new rule, `ref/migrated-from`
(`src/rules/code.lisp:ref/migrated-from@6a7c860`), reports a revision that
names no commit, a path that did not exist at it, and a path that was a
directory. It shares the code-reference layer's revision lookup through
`src/corpus/code.lisp:resolve-migrated-from@6a7c860`, which resolves every
document's value in one more Git process, and like `ref/code-exists` it counts
a revision a shallow clone lacks as unverified and notes when Git is missing.
The form of the value, `<path>@<commit>`, is checked earlier, under `fm/types`,
by `src/model/fields.lisp:parse-migrated-from@6a7c860`.
**Alternatives:** Extend `ref/code-exists` to front-matter (rejected: its
findings speak of symbols and lines, and its exclusion would also exclude the
pin check); check only the form (rejected: the Lexis history rewrite changed
every hash, and only a check against Git finds a pin left stale).

### COMPASS-DRAFT-migration-log-D2 — The revision is a commit's hash, never a branch or tag

**Status:** Proposed
**Context:** A code reference may be pinned to `HEAD` or a tag, which move, or
are moved. `migrated-from` states what the original was when it was reshaped,
and must keep meaning that.
**Decision:** `parse-migrated-from` accepts only 7 to 40 hexadecimal digits
after the last `@`, and a relative path without spaces or backslashes before
it; anything else is an `fm/types` error, and `ref/migrated-from` does not run
on it.
**Alternatives:** Accept any revision Git resolves (rejected: a branch name
would pin nothing); accept tags (rejected: COMPASS-DRAFT-migration-D3 pins
the last commit that changed the original, which is a commit).

### COMPASS-DRAFT-migration-log-D3 — The pending check for `provenance` keys keeps a test after both keys are accepted

**Status:** Proposed
**Context:** `migrated-from` was first pending, naming
COMPASS-DRAFT-migration-D3, and `vocab/pending` learned to report a pending
key of `provenance` (`src/rules/frontmatter.lisp@6a7c860`). With `Compass.md`
0.5.0 both keys are accepted, so no real key exercises that branch of the rule.
**Decision:** The branch stays, for keys pending in future, and its test
binds a temporary pending key for the duration of the check
(`tests/test-rules.lisp:vocab-pending@f6cea01`).
**Alternatives:** Remove the branch with the pending key (rejected: the next
pending key would have to rebuild it); leave it untested (rejected: AGENTS.md
asks that every rule be tested).

## Implementation

The plan's roadmap divided the work into stages, each ending with `make test`
passing and `compass check` reporting no errors in this repository. The
steward made every commit; the trials made commits only in scratch clones
under `/tmp`, standing in for the steward.

### The plan amended from the case studies (`6a7c860`)

Before any code, the plan was amended from the two migrations:

- a "Case studies" section, with a table for each, mapping every finding to the
  decision it bears on;
- COMPASS-DRAFT-migration-D2, COMPASS-DRAFT-migration-D3,
  COMPASS-DRAFT-migration-D4, COMPASS-DRAFT-migration-D5,
  COMPASS-DRAFT-migration-D7, and COMPASS-DRAFT-migration-D8 amended, among
  them Log pins to the commit of the work, as Classic's plan had them, and a
  migration Log only for more than three documents;
- three decisions added: COMPASS-DRAFT-migration-D9 (cited section numbers
  are kept), COMPASS-DRAFT-migration-D10 (a repository's own plan takes
  precedence, within limits), and COMPASS-DRAFT-migration-D11 (the skill ends
  at the reshape).

### `provenance.migrated-from` in the toolchain (`6a7c860`)

- **The vocabulary.** `src/vocab.lisp:*provenance-keys*@6a7c860` lists the keys
  of `provenance` with a standing, as other vocabularies have, replacing the
  hard-coded pair `assistant` and `session` that
  `src/model/fields.lisp:convert-field@6a7c860` had checked against.
  `migrated-from` entered pending.
- **The form,** under `fm/types` (COMPASS-DRAFT-migration-log-D2), and the
  pending warning, under `vocab/pending`.
- **The pin,** under the new rule (COMPASS-DRAFT-migration-log-D1), with
  `src/corpus/code.lisp:document-migrated-from@6a7c860` reading the value.
- **Tests** of the parser, the types, the pending warning, a migrated original
  that resolves, one that does not in each of three ways, a shallow clone, and a
  repository without Git
  (`tests/test-code-refs.lisp:migrated-from-resolves@6a7c860` and those after
  it).
- **The skills' reference,** `frontmatter.md`, `vocabularies.md`, and
  `toolchain.md`, describing the key.

Run on Lexis, whose two migrated documents carried the key, the check replaced
the "unrecognised key" warning with the pending one, verified both pins, and,
in a scratch clone, reported the revision `85fb9b4` that the Lexis history
rewrite had replaced.

### The skill (`6a7c860`)

`skills/compass-migrate/SKILL.md@6a7c860`: five checks before starting, seven
steps (choose, classify, move and stop for the user's commit, reshape, check,
report, then update the backlog record), a table for choosing the genre,
work without the toolchain, and its invariants: one document per request, form
only, no commits, and no authoritative status. COMPASS-0003's skill set and
roadmap, `compass-adopt`, the AGENTS snippet, and the README name it. The
skills tests scan it, so it names only commands, options, and rules that exist.

### The review dimension (`50c15c4`)

COMPASS-DRAFT-migration-O3 was resolved as a `compass-review` dimension,
"Migration fidelity" (`skills/compass-review/SKILL.md@50c15c4`), with no
mechanical aid for now. It finds the reshape commit from Git, the oldest commit
to add the `migrated-from:` line, which on Lexis found `c471246` and `aea04fd`,
and compares the original at `migrated-from` with that commit, not with the
text revised since.

### The trials (`50c15c4`, `2e839c9`)

The assistant followed the skill as written, step by step, in scratch clones.

- **Lexis,** from `cf1147b`, the state its migration began from: both
  documents, in six commits, compared with the steward's results. They agreed
  on genre, identifier, `migrated-from`, headings, and records. Four
  differences favoured the steward's choices and were accepted into the plan:
  pointers in place of "Not recorded" where the original gives a field
  elsewhere, pinned references to the symbols the original names, moving only
  sections out of the spine's order, and deciding a Spec's normative chapters
  with the user.
- **Classic,** from `dfeb862`: five documents chosen to cover the genres and
  the hard cases, one at a time, with Classic's own plan in force; at
  `55c2390`, before Classic's baseline, the skill refused to start. Eight
  findings followed, all accepted, among them the definition of the
  `migrated-from` revision, checking the whole corpus after regenerating the
  index, and rewriting later mentions of a document once it is migrated.

### Resolutions and the plan's review (`892a18e`, `207b23c`)

The Classic findings were written into COMPASS-DRAFT-migration-D2,
COMPASS-DRAFT-migration-D3, COMPASS-DRAFT-migration-D4,
COMPASS-DRAFT-migration-D5, and COMPASS-DRAFT-migration-D8 and into both
skills. A `compass-review` of the plan then found five warnings and nine
notes; the steward's answers produced, among other changes, the federation of
Lexis in `compass.sexp`, a retitled COMPASS-DRAFT-migration-D4, and a
refinement found while testing the steward's rule for migration moves: only a
rename made after the repository adopted Compass is one, since Classic's own
`1cabbcf` renamed fourteen documents before.

### The pending tool's review (`f6cea01`)

A review of the steward's [COMPASS-DRAFT-pending-tool](Plan.PendingTool.md)
found that COMPASS-DRAFT-migration-O2's resolution relied on a group it did
not plan. The steward chose to add it: COMPASS-DRAFT-pending-tool-D5 lists the
files not yet migrated, and COMPASS-DRAFT-toolchain-D30 was amended to match.

### `Compass.md` 0.5.0 (`f6cea01`)

With the plan accepted by the steward, §7 of
[COMPASS-0001](../Compass.md) defines `migrated-from` and `original-assistant`
(`Compass.md@f6cea01`), and §22 mentions them; `schema-version` went from 0.4.0
to 0.5.0, a minor change. Both keys are accepted in
`src/vocab.lisp:*provenance-keys*@f6cea01`, `original-assistant` is checked as a
single value, the semantic binding maps them, and the skills ask for the new
key. COMPASS-O8 was resolved for documents, and COMPASS-DRAFT-migration-O1,
COMPASS-DRAFT-migration-O5, and COMPASS-DRAFT-migration-O6 were resolved.

### Dates, and a check of the new rules (`5d746f3`)

COMPASS-DRAFT-migration-O4 was resolved: a bulk addition is recognised by its
commit, not its date, and the skill always proposes an earlier `created:` it
has evidence for. The rules added after the trials were then exercised in the
Classic clone: the `migrated-from` revision, the later-mention rewrite, the
dating signals over every document at `dfeb862`, and `original-assistant`.
`ref/migrated-from` gained its row in COMPASS-0004's rule table.

## Pitfalls Encountered

- **A value cannot begin with `@`.** A test of `migrated-from: @abc1234` met
  `fm/syntax`, not `fm/types`, since the YAML subset rejects it; the test now
  quotes the value.
- **`git show --stat -- <path>` shows only that path,** so a first version of
  the skill's command for finding migration moves could never see the rename of
  another document. Tested on the Classic clone before release.
- **Earlier moves change documents not yet migrated.** In the Classic trial,
  `git log -1 -- <path>` gave the move of another document as the
  `migrated-from` revision of `Survey.TTRPGHost.md`; COMPASS-DRAFT-migration-D3
  now defines the revision to exclude them.
- **Renames before adoption look like migration moves.** The rule "a commit
  that renamed another document" would have passed over Classic's `1cabbcf`;
  only renames after the commit that added `compass.sexp` are migration moves.
- **Checking one path hides findings elsewhere.** In the Classic trial,
  `compass check <path>` did not show a stale `INDEX.md` for three migrations;
  the skill now regenerates the index and checks the whole corpus.
- **The trial's operator missed steps the skill states:** identifier links and
  `relates-to` entries for two documents already migrated. Both went into the
  skill's own self-check.

## Verification

Run via `make test`. At `c7e88a7`, before the work, the suite ran 1241 checks
and failed one, an open question of
[COMPASS-DRAFT-eval-defect-detection](Plan.EvalDefectDetection.md) not yet
listed in its front-matter, outside this work; the steward's fix rode in
`6a7c860`. At `5d746f3` it runs 1316 checks, all passing. `compass check
--federation` reports no errors and no warnings over the 22 documents, and
`compass index --check` finds the index current. Each stage ended with the
same three results; the check counts at each commit were 1313 at `6a7c860`,
1315 at `50c15c4` and `2e839c9`, 1316 at `892a18e`, 1317 at `207b23c`, and 1316
at `f6cea01` and `5d746f3`, where the provenance tests were consolidated.

The trials are recorded in the plan's case studies. Run on Lexis itself,
`compass check` reports no errors and, since 0.5.0, no warnings.

## Files

Table: Files added or changed in commits `6a7c860` to `5d746f3`.

| File | Action | Description |
|------|--------|-------------|
| `skills/compass-migrate/SKILL.md` | **New** | The skill |
| `skills/compass-review/SKILL.md` | Modified | The "Migration fidelity" dimension, and the note on pending keys |
| `skills/compass-author/SKILL.md` | Modified | Split parts carry `migrated-from` |
| `skills/compass-adopt/SKILL.md` | Modified | Points to `compass-migrate` |
| `skills/reference/frontmatter.md`, `vocabularies.md`, `toolchain.md` | Modified | `migrated-from` and `original-assistant`; what the toolchain does not check |
| `templates/AGENTS.snippet.md` | Modified | Names `compass-migrate`, and the migration line |
| `src/vocab.lisp` | Modified | The keys of `provenance`, with standings |
| `src/model/fields.lisp` | Modified | `parse-migrated-from`; the keys' types |
| `src/rules/frontmatter.lisp` | Modified | `vocab/pending` for `provenance` keys |
| `src/corpus/code.lisp` | Modified | Resolving `migrated-from` against Git |
| `src/rules/code.lisp` | Modified | `ref/migrated-from` |
| `src/packages.lisp` | Modified | Exports |
| `tests/test-vocab.lisp`, `test-rules.lisp`, `test-code-refs.lisp` | Modified | Tests of the keys, their types, the pending warning, and the rule |
| `Compass.md` | Modified | Version 0.5.0: §7 and §22 |
| `doc/Plan.Migration.md` | Modified | Case studies, trials, amendments, resolutions |
| `doc/Plan.PendingTool.md` | Modified | Review fixes; COMPASS-DRAFT-pending-tool-D5 |
| `doc/Plan.Toolchain.md` | Modified | COMPASS-DRAFT-toolchain-D30 amended; COMPASS-O8 resolved; the rule's row |
| `doc/Plan.AuthoringAssistance.md` | Modified | The skill set and roadmap name `compass-migrate` |
| `doc/Spec.SemanticBinding.md` | Modified | Mappings of the two keys |
| `compass.sexp`, `AGENTS.md` | Modified | Lexis federated |
| `README.md` | Modified | The skill, for mature codebases |
| `doc/INDEX.md` | Modified | Regenerated |
| `doc/Log.Migration.md` | **New** | This document |

## Metrics

- Test checks: 1241 → 1316 (75 added, net of consolidation); regressions: 0.
- New rules: 1 (`ref/migrated-from`); new accepted vocabulary: 2 `provenance`
  keys.
- New skill: 1, of 6 that work with the toolchain; skills changed: 3.
- Documents migrated in trials: 7, in scratch clones of 2 repositories.
- Plan decisions: 8 → 11; open questions resolved: 6 of 6.

## Outstanding Work

- **Acceptance and numbers.** The plan's acceptance is to be recorded by the
  steward: its status, `approved-by`, and the statuses of
  COMPASS-DRAFT-migration-D1 to COMPASS-DRAFT-migration-D11; `compass assign`
  follows. The skills then cite provisional identifiers that have become
  aliases, to be updated to the canonical ones.
- **A fresh session's trial.** Every trial was run by the assistant that wrote
  the skill. A migration by a new session, given only the skill, would test
  whether the text alone is enough.
- **The pending tool.** `compass pending`, its group of files not yet migrated
  (COMPASS-DRAFT-pending-tool-D5), and the redefinition of notes in the skills
  (COMPASS-DRAFT-pending-tool-D3) are built by
  [COMPASS-DRAFT-pending-tool](Plan.PendingTool.md).
- **Follow-ups in other repositories,** for their stewards: Classic's
  `Survey.TTRPGHost.md` and `Survey.MusicPublishing.md` say 2026-07-04 but are
  dated 2026-08-24 by Git; Lexis's Log names a session its transcript does not
  show writing it, and neither Lexis document names its `original-assistant`.
- **Source headers,** the plan's last stage, are deferred.
- **A mechanical aid for the form-only comparison,** left for later by
  COMPASS-DRAFT-migration-O3.
