---
id:            COMPASS-DRAFT-authoring-assistance-log
title:         Compass Authoring-Assistance Development Log
genre:         Log
scope:         component
program:       Compass
component:     authoring-assistance
language:      en
status:        Accepted
authors:
  - Andrew Sengul
approved-by:   Andrew Sengul
reviewed:      2026-10-08
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-DRAFT-authoring-assistance
  - COMPASS-DRAFT-toolchain
  - COMPASS-DRAFT-toolchain-log
  - COMPASS-DRAFT-agent-workflow
decisions:
  - COMPASS-DRAFT-authoring-assistance-log-D1
  - COMPASS-DRAFT-authoring-assistance-log-D2
  - COMPASS-DRAFT-authoring-assistance-log-D3
  - COMPASS-DRAFT-authoring-assistance-log-D4
---

# Compass Authoring-Assistance: Development Log

This document chronicles the wiring of the Compass skills (`compass-author`,
`compass-review`, `compass-lookup`, and the `compass-derive` stub) to the
`compass` command, version 0.1 of the toolchain described in
[COMPASS-DRAFT-toolchain-log](Log.Toolchain.md). It records the decisions made
while doing so, the changes to the skills, templates, and AGENTS snippet, the
tests that keep the skills in step with the toolchain, the adoption of Compass
in the Classic, Origin, and Lexter repositories, and a smoke test in which an
agent used each working skill on its own. The plan it carries out is roadmap
step 6 of [COMPASS-DRAFT-authoring-assistance](Plan.AuthoringAssistance.md#roadmap).

## Problem

The skills were written before the toolchain existed, and ran in advisory-only
mode
([COMPASS-D2](Plan.AuthoringAssistance.md#compass-d2--advisory-only-until-the-toolchain-exists)):
each checked a document by hand against the reference bundle, searched the
corpus with `grep`, and told the user its output was unverified. With version
0.1 built, that mode had become a liability:

- A skill could not say whether a document passed the checks the standard's
  own repository now enforces, so an agent could hand over a draft that
  `compass check` would reject.
- `compass-lookup` reimplemented in prose what `compass show`, `outline`, and
  `refs` now do exactly, and its search missed links whose text is not an
  identifier.
- The genre templates contradicted the standard in two ways the toolchain
  would expose: they numbered records `<NAMESPACE>-D<n>`, which is neither a
  canonical nor a provisional identifier
  ([COMPASS-DRAFT-toolchain-D2](Plan.Toolchain.md#compass-draft-toolchain-d2--provisional-identifiers-for-register-entries)),
  and they gave every new decision the status `Accepted`, which an assistant
  must never set
  ([COMPASS-DRAFT-agent-workflow-D5](Plan.AgentWorkflow.md#compass-draft-agent-workflow-d5--three-review-gates)).
- Nothing would notice if a skill named a command, option, or rule the
  toolchain does not have, and the skills would be read by agents that act on
  every instruction they contain.

## Design Decisions

The work carried out these existing decisions:

- [COMPASS-D2](Plan.AuthoringAssistance.md#compass-d2--advisory-only-until-the-toolchain-exists):
  when the toolchain exists, the skills call it rather than reimplement its
  checks. Advisory mode remains as the fallback when no executable is found.
- [COMPASS-D4](Plan.AuthoringAssistance.md#compass-d4--harness-neutral-core-plus-shared-reference-bundle):
  shared reference material lives in `skills/reference/`.
- [COMPASS-DRAFT-agent-workflow-D5](Plan.AgentWorkflow.md#compass-draft-agent-workflow-d5--three-review-gates)
  and
  [COMPASS-DRAFT-agent-workflow-D8](Plan.AgentWorkflow.md#compass-draft-agent-workflow-d8--what-an-agent-may-do-by-scope):
  an agent never sets `approved-by`, `reviewers`, or an authoritative status,
  and may run `compass index`.
- [COMPASS-DRAFT-toolchain-D4](Plan.Toolchain.md#compass-draft-toolchain-d4--a-project-manifest-declares-namespace-ownership-and-federation):
  the skills read the namespace, document directory, and federated
  repositories from `compass.sexp`.
- [COMPASS-DRAFT-toolchain-D21](Plan.Toolchain.md#compass-draft-toolchain-d21--implementation-conventions-for-the-baseline):
  the commands `outline` and `refs`, and the rejection of `check` paths outside
  the corpus, which were added to the toolchain for the skills.

Four further decisions were made in the work. They are proposals for the
steward.

### COMPASS-DRAFT-authoring-assistance-log-D1 — One shared toolchain guide, and a short summary in each skill

**Status:** Proposed

**Context:** Three skills run `compass` and need the same facts: where the
executable is, which commands it has, what each exit code means, how to read
its findings, which findings to fix, and what to do without it. Written out in
each skill, the four copies would drift apart; kept only in a reference file,
they depend on an agent choosing to open it.

**Decision:** The full guide is `skills/reference/toolchain.md`. Each working
skill carries a four-point "Using the toolchain" section (find the executable,
run `compass help` once, the exit codes, which findings to fix) and a "Without
the toolchain" section, and points to the guide for the rest. The tests check
that every skill points to the guide and that the three working skills have
both sections.

**Alternatives:**
- The full guidance in every skill. Rejected: four copies to keep in step,
  and long skills that bury their workflow.
- The guide only. Rejected: an agent that does not open it would miss the exit
  codes and the rule about whose findings to fix. The smoke test bore this
  out: none of the three agents opened the guide, and all three acted on the
  summary in their skill.

### COMPASS-DRAFT-authoring-assistance-log-D2 — Review checks the whole corpus and separates the change's findings

**Status:** Proposed

**Context:** A review concerns the documents a change touches, but a
repository that is migrating to Compass may have many errors elsewhere: Classic
has 23. Reporting them all would make every review there recommend against
acceptance; reporting only the changed files would hide errors the change
causes in other documents, such as a duplicated identifier.

**Decision:** `compass-review` runs `compass check --format json` over the
whole corpus, so that the cross-document rules judge the change correctly
([COMPASS-DRAFT-toolchain-log-D3](Log.Toolchain.md#compass-draft-toolchain-log-d3--checking-one-path-still-checks-the-whole-corpus)).
It reports the findings in the changed files as the review's, and counts the
rest as pre-existing. It never recommends acceptance while the changed files
have a toolchain error. A changed Markdown file that is not a document of the
corpus is reported, since the toolchain did not check it.

**Alternatives:**
- `compass check PATH` with the changed paths. Rejected as the only check: it
  reports nothing for a misplaced file except a usage error, and the review
  could not say how many errors the corpus already had.
- All findings, unseparated. Rejected for the reason above.

### COMPASS-DRAFT-authoring-assistance-log-D3 — Drift tests accept what exists or what the plan lists

**Status:** Proposed

**Context:** The skills name commands, options, and rules. Some are planned
but not built: `compass assign` is named so that an agent will use it once
`compass help` lists it. A test that accepted only what exists would forbid
those mentions; a hand-kept allow list would drift as the plan changes.

**Decision:** A command or rule named in the skills must either exist in the
toolchain or be named in the plan's
[Command-line interface](Plan.Toolchain.md#command-line-interface) or
[Validation rules](Plan.Toolchain.md#validation-rules) sections, which the
tests read through `compass show`. Options are checked only for commands that
exist, against the options the command accepts. Every command that exists must
be described in the guide.

**Alternatives:**
- Accept only what exists. Rejected: the skills could not prepare for version
  0.2.
- A list of allowed names in the tests. Rejected: a second copy of the plan.

### COMPASS-DRAFT-authoring-assistance-log-D4 — Templates give new decisions the status Proposed

**Status:** Proposed

**Context:** The Plan, Log, and Architecture templates set `**Status:**
Accepted` on their decision record. An agent filling in a template would set
an authoritative status, which the acceptance gate reserves for a person
([COMPASS-DRAFT-agent-workflow-D5](Plan.AgentWorkflow.md#compass-draft-agent-workflow-d5--three-review-gates)).

**Decision:** The templates write `**Status:** Proposed`, with a comment that a
person sets `Accepted`, and `compass-author` says to scaffold decisions as
`Proposed`.

**Alternatives:**
- `Draft`. Rejected: a scaffolded decision is complete enough to consider,
  which is what `Proposed` means (§6).
- No status. Rejected: `register/status` requires one.

## Implementation

The wiring is in commit `07b9643`. Follow-ups, including the changes prompted
by the smoke test, are in `fcdec0c`. Code references are pinned to the commit
in which the code appeared.

### The shared guide

`skills/reference/toolchain.md@07b9643` covers:

- **finding the executable:** `compass` on the `PATH`, then `../../bin/compass`
  from a skill's directory, then advisory mode with the fix named
  (`make install`);
- **the commands of version 0.1**, as a table saying which ones change files;
- **the exit codes**: 0, 1, 2, and 141, with what to do for each;
- **reading `compass check`**: the text and JSON forms, errors and warnings,
  `vocab/pending`, unverified references, `--skip-unmarked`, and why checking a
  path still loads the whole corpus;
- **fixing findings:** only in files the task changed; never editing
  `INDEX.md` by hand; never writing a number from `compass next`;
- **what the toolchain does not check yet:** Git-derived fields, pinned code
  references outside memo bases, the §12 rules, section shape, approval, the
  ledger, and the judgments of genre, quality, and prior art;
- **other repositories:** running a command with `--root`, taking the path
  from `:federation` in `compass.sexp`.

`skills/reference/README.md@07b9643` names `compass rules` as the authority on
what is checked automatically. In `fcdec0c`,
`skills/reference/references.md@fcdec0c` gained a note that no namespace has a
registry until version 0.2, and what to use until then.

### compass-author

`skills/compass-author/SKILL.md@07b9643`:

- reads the namespace and document directory from `compass.sexp`, and checks
  with `compass show` that a provisional identifier is free;
- gives records provisional identifiers formed from the document's
  (`<NS>-DRAFT-<slug>-D1`), and new decisions the status `Proposed` (D4);
- finds a component's memo host through `compass index --stdout`, and reads its
  records with `outline` and `show`;
- removes leftover placeholders, then runs `compass check <path>` and fixes
  every error until none remain, leaving `vocab/pending` warnings to report;
- regenerates `INDEX.md` only where one already exists;
- reports the check's result and the toolchain version, and what the
  toolchain does not check.

### compass-review

`skills/compass-review/SKILL.md@07b9643` begins with a toolchain step (D2): the
changed Markdown files from `git diff --name-only`, a whole-corpus `compass
check --format json`, findings split between the change and the rest, skipped
files and unverified references noted, and `compass rules` and `compass
version` recorded. The judgment step covers what `compass rules` does not list;
it uses `compass outline` for section shape, and `compass show` and `compass
refs` for cross-reference plausibility. The report gains "Checked with" and
"Toolchain findings".

### compass-lookup

`skills/compass-lookup/SKILL.md@07b9643` answers with `compass outline` before
opening a long document, `compass show ID#anchor` for one section,
`compass show` for a record, `compass refs` for inbound references, and
`compass index --stdout --namespace NS` for a namespace's documents and
records. Other repositories are found through `:federation` in `compass.sexp`,
replacing a federation file the skill had invented. Searching with `grep` is the
fallback when no executable is found.

### compass-derive

`skills/compass-derive/SKILL.md@07b9643` records that the toolchain exists and
that its one derivation is the namespace index. The skill remains a stub.

### Templates and the AGENTS snippet

- `templates/Plan.template.md@07b9643` and the Log, Architecture, and Survey
  templates write records as `<NAMESPACE>-DRAFT-<slug>-D1` and `-O1`, and
  decisions as `Proposed` (D4). Filled in, the old form `<NAMESPACE>-D<n>`
  produced `TEST-Dsample`, which `fm/types` rejects.
- The Reference and Architecture templates give `glossary:` an identifier
  placeholder, since a document name draws an `fm/types` warning.
- `templates/AGENTS.snippet.md@07b9643` asks for `compass check` before
  finishing documentation work and names the other commands; it gained a line
  for the command's location and, in `fcdec0c`, one for migration.

### Tests

`tests/test-skills.lisp@fcdec0c` holds seven tests (D3):

- `tests/test-skills.lisp:skills-name-only-known-commands@07b9643` and
  `tests/test-skills.lisp:skills-name-only-known-rules@07b9643` compare the
  code in the skills, the guide, and the AGENTS snippet against the toolchain
  and the plan, read by
  `tests/test-skills.lisp:planned-commands@07b9643` and
  `tests/test-skills.lisp:planned-rules@07b9643`.
- `tests/test-skills.lisp:every-command-is-documented-for-the-skills@07b9643`
  requires the guide to describe every command, using
  `src/cli.lisp:command-names@07b9643`.
- `tests/test-skills.lisp:skills-use-the-toolchain@07b9643` requires each
  skill to point to the guide (D1).
- `tests/test-skills.lisp:filled-templates-pass-check@07b9643` fills in all
  ten templates with
  `tests/test-skills.lisp:fill-template@07b9643` and requires them to pass
  `compass check` with no errors and no warnings except `vocab/pending`.
- `tests/test-skills.lisp:skills-use-only-real-options@fcdec0c` requires every
  option passed to an implemented command to be one it accepts, using
  `src/cli.lisp:command-option-names@fcdec0c`. It checks fourteen invocations.

### Adoption in Classic, Origin, and Lexter

None of these files is committed in its repository.

- **`compass.sexp` in each:** the namespace (`CLASSIC`, `ORIGIN`, or
  `LEXTER`), the document directory, the steward with solo approval, the other
  three repositories under `:federation`, and the test commands as `:repl`
  forms.
- **This repository's `compass.sexp`** (`compass.sexp@fcdec0c`) lists Classic,
  Origin, and Lexter under `:federation`.
- **`AGENTS.md`:** Classic's Compass section was replaced with the current
  snippet, filled in; Origin and Lexter received one. Each says where `compass`
  is, that checks use `--skip-unmarked` while older documents are migrated, and,
  for Classic, that the duplicate open-question numbers will be reported.

### The plans

`doc/Plan.AuthoringAssistance.md@07b9643` describes the skills as they now are,
marks roadmap step 6 done for version 0.1, and records
[COMPASS-O1](Plan.AuthoringAssistance.md#compass-o1--advisory-mode-conformance-signalling)
and
[COMPASS-O2](Plan.AuthoringAssistance.md#compass-o2--registry-access-before-the-toolchain-exists)
as partly resolved. `doc/Plan.Toolchain.md@07b9643` marks the integration in
roadmap step 8 done for version 0.1.

## Pitfalls Encountered

1. **A skill description that was not YAML.** Rewriting the description of
   `compass-review` produced "… the judgment-level conformance it cannot
   check: genre fit …", and `: ` inside an unquoted value is not valid YAML. The
   repository test that parses every front-matter block failed before the
   commit. Whether OpenCode's skill loader would have rejected the skill was not
   tested.
2. **A placeholder that hides a record.** A record heading still reading
   `### DEMO-DRAFT-widget-D1 — <decision title>` is not recognised as a record:
   Markdown reads `<decision title>` as an HTML tag, the heading is left with no
   title, and `register/mirrored` reports the record as listed but defined
   nowhere. `compass-author` now removes placeholders before running the
   check.
3. **Templates that set `Accepted`.** Found by reading the templates while
   running the author workflow by hand on a scratch repository (D4).
4. **An invented federation file.** `compass-lookup` told agents to look for a
   `compass.federation` file that no part of Compass defines; `compass.sexp`
   already holds the federation.

## Verification

- **Tests.** `make test` at `07b9643`: **604 checks, 100% pass**, 76 more than
  the 528 at `40d6749`, before the wiring. At `fcdec0c`: **625 checks, 100%
  pass.** Both were re-run for this Log from separate worktrees of each commit.
- **Self-check.** `compass check` on this repository at `fcdec0c`: 11
  documents, no errors, no warnings.
- **By hand.** Before `07b9643`, each skill's sequence of commands was run on
  a scratch repository: scaffolding and checking a Plan and a memo host,
  regenerating an index, a review that separated a pre-existing error, and a
  lookup in this repository through `--root`.
- **Adoption.** `compass check --skip-unmarked` in each repository:

  Table: Checks of the repositories that adopted Compass, with their manifests.

  | Repository | Documents | Skipped | Findings |
  |---|---|---|---|
  | compass | 11 | 0 | none |
  | classic | 5 | 26 | 23 errors, all `register/unique` |
  | origin | 1 | 15 | none |
  | lexter | 0 | 11 | none |

  No manifest drew a `manifest/valid` finding. `compass show COMPASS-0001
  --root ../compass` from Classic, `compass outline` of an Origin document from
  Classic, and `compass refs` of a Classic document from Lexter all resolved.

### The smoke test

Each working skill was given to an agent: OpenCode 1.18.35 with its default
model, run as `opencode run --auto --format json`, with the skills read from
this repository's working tree as committed in `fcdec0c` less the two
clarifications described below. `--auto` approves every tool call, so the runs
were made only in throwaway repositories: a scratch repository, and a clone of
Classic at `6e4f02d` holding copies of its new `compass.sexp` and `AGENTS.md`.
The executable was installed into a temporary prefix. The prompts did not name
the skills.

Table: The three smoke-test runs.

| Skill | Repository | `compass` on the `PATH` | Time | Tool calls | Result |
|---|---|---|---|---|---|
| compass-author | scratch: a Plan, an index, uncommitted code | no | 45 s | 7 | A Log, clean under `compass check`; index regenerated |
| compass-lookup | Classic clone | yes | 21 s | 4 | References and open questions answered; nothing changed |
| compass-review | Classic clone | yes | 88 s | 13 | A report recommending revision; nothing changed |

What each agent did:

- **Author.** Loaded `compass-author` unprompted, found the executable through
  the skill's directory, ran `compass help` and checked that its provisional
  identifier was free. It wrote a Log with the decision as a `Proposed`
  record, a pinned code reference to the only commit, and `provenance:`, and no
  `approved-by` or authoritative status. Its check was clean, and it
  regenerated the existing `INDEX.md`. It reported, unasked, that the code it
  was documenting did not yet evict anything and that its cache's docstring
  claimed an order a hash table does not keep.
- **Lookup.** Answered "what refers to CLASSIC-DRAFT-archival?" with
  `compass refs` (one link) and added, labelled as informal, the mentions of
  "the archival survey" that a text search found. It found the Usenet survey
  through `compass index --stdout`, its sections through `compass outline`, and
  printed its open questions with
  `compass show CLASSIC-DRAFT-usenet#open-questions` rather than by identifier, because it had noticed that four Classic surveys
  share CLASSIC-O1 to O6.
- **Review.** Ran the whole-corpus check, separated its own document's
  findings (none) from the 23 pre-existing errors, and reported 26 skipped
  files and the toolchain version. Its judgment found two claims in
  Classic's X.400 evaluation that are false at `6e4f02d`, both since confirmed:
  no `trust-anchors` slot exists on `classic-instance-descriptor`, and the
  receiver already acknowledges a retraction with `:retract-response`. It
  recommended revision and changed nothing.

The repositories were compared before and after: `git status` and the diff of
this repository, Classic, Origin, Lexter, and the clone were unchanged, except
for the two files placed in the clone for the test.

## What This Demonstrates

- **The skills are found and followed without being named.** Ordinary requests
  loaded the right skill in every run, and each agent ran the documented
  commands, read their exit codes correctly, and stayed within its permissions.
- **The summary in each skill carried the rules (D1).** No agent opened
  `skills/reference/toolchain.md`; each worked from its skill's own section.
- **Agents still make small errors.** The reviewer reported "all 28 rules
  passed" (there are 25), and tried `rg`, which is not installed, before
  falling back to `grep`.
- **Two instructions were narrower than intended.** The review agent saved
  JSON to a scratch file in `/tmp`, and the lookup agent added a text search.
  Both were reasonable, so `fcdec0c` clarified that "read only" concerns the
  repository and that labelled informal mentions may supplement `refs`.

## Files

Table: Files added or changed. Those in `compass` are in commits `07b9643` and
`fcdec0c`; those in the other repositories are not committed.

| Repo | File | Action | Description |
|------|------|--------|-------------|
| compass | `skills/reference/toolchain.md` | **New** | The shared guide to running `compass` (D1) |
| compass | `skills/reference/README.md` | Modified | Names the guide and `compass rules` |
| compass | `skills/reference/references.md` | Modified | No registry before version 0.2 |
| compass | `skills/compass-author/SKILL.md` | Modified | Checks its drafts; provisional record identifiers |
| compass | `skills/compass-review/SKILL.md` | Modified | Toolchain findings first (D2) |
| compass | `skills/compass-lookup/SKILL.md` | Modified | `show`, `outline`, `refs`, `index --stdout` |
| compass | `skills/compass-derive/SKILL.md` | Modified | Records the namespace index |
| compass | `templates/Plan.template.md`, `Log`, `Arch`, `Survey` | Modified | Provisional record identifiers; `Proposed` (D4) |
| compass | `templates/Ref.template.md` | Modified | `glossary:` takes an identifier |
| compass | `templates/README.md` | Modified | Record placeholders; templates must pass the check |
| compass | `templates/AGENTS.snippet.md` | Modified | `compass check`; command location; migration |
| compass | `tests/test-skills.lisp` | **New** | Seven tests (D3) |
| compass | `src/cli.lisp`, `src/packages.lisp` | Modified | `command-names`, `command-option-names` |
| compass | `compass.asd` | Modified | The new test file |
| compass | `compass.sexp` | Modified | Federation with Classic, Origin, and Lexter |
| compass | `README.md` | Modified | `outline`, `refs`, `make install` |
| compass | `doc/Plan.AuthoringAssistance.md` | Modified | The skills as they are; step 6; O1 and O2 |
| compass | `doc/Plan.Toolchain.md` | Modified | Step 8 |
| classic | `compass.sexp` | **New** | Manifest |
| classic | `AGENTS.md` | Modified | Current Compass section |
| origin | `compass.sexp`, `AGENTS.md` | **New** | Manifest and agent guide |
| lexter | `compass.sexp`, `AGENTS.md` | **New** | Manifest and agent guide |

The build-stamp fix in `fcdec0c` belongs to the toolchain and is recorded in
[COMPASS-DRAFT-toolchain-log](Log.Toolchain.md).

## Metrics

- Test checks: 528 at `40d6749`, before the work; 604 at `07b9643`; 625 at
  `fcdec0c`.
- Regressions: 0.
- Skill tests: 7, over 4 skills, 6 reference files, the AGENTS snippet, and
  10 templates.
- Smoke-test runs: 3; files changed outside the throwaway repositories: 0.

## Outstanding Work

- **Commit the adoption files** in Classic, Origin, and Lexter. The clone at
  `~/src/chat/classic` still holds the copies used for the smoke test.
- **Install `compass` on the `PATH`** (`make install`), for the skills to work
  outside this repository without the skill-directory fallback.
- **Restart OpenCode** so that interactive sessions load the rewired skills.
- **Classic's documents.** The duplicate open-question numbers, and the two
  false claims the review found in its X.400 evaluation.
- **A repeatable smoke test.** The runs were made by hand; a script with fixed
  prompts and checks on the JSON events could run whenever the skills change,
  and could feed the agent-context evaluation
  ([COMPASS-DRAFT-agent-context-eval](Eval.AgentContext.md)).
- **Version 0.2.** `compass-author` should use `compass assign`, and
  `compass-review`'s list of unchecked concerns shrinks as the ledger,
  Git-derived fields, and code-reference rules arrive.
- **Cross-harness adapters**, roadmap step 7 of the plan.
- **Acceptance.** This Log is `Draft`, and its four decisions are `Proposed`.
