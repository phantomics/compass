---
id:            COMPASS-DRAFT-emacs-review
title:         Compass Review in Emacs — Write Commands and an Emacs Package
genre:         Plan
scope:         program
program:       Compass
component:     authoring-assistance
language:      en
status:        Draft
authors:
  - Andrew Sengul
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-0001
  - COMPASS-0002
  - COMPASS-0003
  - COMPASS-0004
  - COMPASS-0007
  - COMPASS-0014
cites:
  - title:     "Transient — Transient Commands (magit/transient)"
    locator:   "README; manual, Introduction"
    external:  true
  - title:     "Magit manual"
    locator:   "Sections; the status buffer"
    external:  true
  - title:     "Forge (magit/forge)"
    locator:   "README: pull requests and reviews from Emacs"
    external:  true
  - title:     "markdown-mode (jrblevin/markdown-mode)"
    locator:   "README"
    external:  true
  - title:     "GNU Emacs manual (29.1)"
    locator:   "Flymake; Eglot; Fetching Package Sources (package-vc-install); Key Binding Conventions"
    external:  true
  - title:     "GNU Emacs Lisp Reference Manual (29.1)"
    locator:   "Library Headers (Conventional Headers for Emacs Libraries); Tabulated List Mode"
    external:  true
  - title:     "Denote manual"
    locator:   "Front matter"
    external:  true
  - title:     "ERT: Emacs Lisp Regression Testing"
    locator:   "Introduction"
    external:  true
  - title:     "setup-emacs (purcell/setup-emacs)"
    locator:   "README"
    external:  true
decisions:
  - COMPASS-DRAFT-emacs-review-D1
  - COMPASS-DRAFT-emacs-review-D2
  - COMPASS-DRAFT-emacs-review-D3
  - COMPASS-DRAFT-emacs-review-D4
  - COMPASS-DRAFT-emacs-review-D5
  - COMPASS-DRAFT-emacs-review-D6
  - COMPASS-DRAFT-emacs-review-D7
  - COMPASS-DRAFT-emacs-review-D8
  - COMPASS-DRAFT-emacs-review-D9
open-questions:
  - COMPASS-DRAFT-emacs-review-O1
  - COMPASS-DRAFT-emacs-review-O2
  - COMPASS-DRAFT-emacs-review-O3
  - COMPASS-DRAFT-emacs-review-O4
  - COMPASS-DRAFT-emacs-review-O5
---

# Compass Review in Emacs: Development Plan

This plan makes reviewing and approving Compass documents a matter of commands
rather than hand-editing. It adds write commands to the `compass` toolchain that
record a document's approval, accept or change the status of individual
records, and resolve critique findings, and it builds an Emacs package that
drives them: a status buffer of everything awaiting review, menus for each
action, actions on the document or record at point, batch review, and inline
diagnostics. The commands are the single place the review rules live, so a later
language server and a VS Code extension can use them unchanged. It is the first
editor-integration piece of the authoring-assistance layer (§22, §23 S9;
[COMPASS-0003](Plan.AuthoringAssistance.md)), it implements the human side of
the review gates of [COMPASS-0007](Plan.AgentWorkflow.md), and it builds on the
command conventions of [COMPASS-0004](Plan.Toolchain.md).

## Problem

Reviewing a Compass document means editing text by hand. To accept a document,
a reviewer opens the file, finds the front-matter, changes `status`, adds
`approved-by` and `reviewed` with the right name and date, and saves. To accept
a decision, they find its heading and change its `**Status:**` line. To accept a
memo, they change the memo's status and also update its host's `approved-by` and
`reviewed` (COMPASS-D44). To dispose of a critique finding, they write a dated
`**Resolution:**` line in the form [COMPASS-0014](Plan.Critique.md) prescribes.
Then they run `compass check` and regenerate the index.

Each step is easy to get slightly wrong: a status the genre does not allow, a
`Superseded` without `superseded-by`, a date in the wrong form, an approver
spelled differently from the `.mailmap` identity, a self-approval in a namespace
that does not permit it. The checker catches some of these afterwards; none of
them should be possible to write. And finding what needs review at all means
reading the index or searching the corpus.

The rules that govern these acts (COMPASS-D38, COMPASS-D39, COMPASS-D44,
COMPASS-D62) exist only as text and as checks after the fact. Nothing performs
the acts correctly.

## Goals

- Make each review act one command that cannot produce a non-conforming result:
  approve a document, accept a record, change a status, resolve a finding.
- Keep the review rules in one tested implementation that every editor and
  script shares.
- Show a reviewer, in one place, everything that awaits their decision.
- Let a reviewer act from Emacs on the document or record at point, or on many at
  once, without editing front-matter or record fields by hand.
- Keep agents out of the acts reserved for people: an assistant never approves,
  accepts, or resolves (COMPASS-D38).
- Prepare for a language server and a VS Code extension by putting nothing in
  Emacs Lisp that they would need to reimplement.

## Settled Decisions

All decisions are **Proposed** until this Plan is accepted.

### COMPASS-DRAFT-emacs-review-D1 — Writes live in the toolchain; editors drive them

**Status:** Proposed

**Context:** An editor package could edit the front-matter and record fields
itself. But the rules for those edits (which statuses a genre allows, who may
approve, what a resolution must say, which fields move together) are already the
toolchain's business: it parses the corpus, knows the vocabularies, and checks
the results. Emacs Lisp and Common Lisp cannot share code, and a VS Code
extension, a later goal, would need the same rules a third time.

**Decision:** Every write that a review performs is a `compass` subcommand. The
Emacs package calls the command-line program and reads its JSON output; it never
edits a document's front-matter or record fields itself. The commands are built
on the toolchain's existing write path: a write is planned without touching any
file, refused if the plan is invalid, and then executed, as `compass assign`
does (`src/cli.lisp:run-allocation@e18c8a5`), and files change only through the
line-preserving rewriter (`src/corpus/rewrite.lisp@e18c8a5`). A later language
server, written in Common Lisp under `src/mod/`, calls the same functions inside
its image rather than the program.

**Alternatives:**
- Edit the text in Emacs Lisp. Rejected: the rules would exist twice, and a third
  time for VS Code.
- Build the language server first and have every editor use it. Rejected for v1:
  the language-server protocol has no natural form for a review overview or for
  menu-driven acts, and it is the larger piece of work. It remains the route for
  editor language features (COMPASS-DRAFT-emacs-review-D8).

### COMPASS-DRAFT-emacs-review-D2 — Four write commands

**Status:** Proposed

**Context:** A reviewer performs four kinds of act. A document is accepted into
an authoritative status, with an approver and a date. A record (a decision or a
memo) is accepted into an authoritative status. A document or record moves
between non-authoritative statuses, or is retired. A critique finding is
disposed of. Earlier discussion named an `accept-memo` command; decisions are
accepted the same way, so one command serves both kinds of record.

**Decision:** The toolchain gains `compass approve`, `compass accept`,
`compass set-status`, and `compass resolve`, specified under
[The write commands](#the-write-commands). They share these properties:
- Each plans first and writes nothing until the plan is valid; `--dry-run`
  prints the plan.
- Each leaves every document it touches conforming: a write that would produce a
  `compass check` error is refused instead.
- Each prints what it changed, as text or, with `--format json`, as the files and
  lines changed, so that an editor can refresh exactly those buffers.
- None commits. Committing remains the reviewer's act, and the commit is what
  passes the change gate (COMPASS-D38).
- Exit codes follow the toolchain's convention: 0 on success, 1 when the write is
  refused, 2 on a usage or internal error.

**Alternatives:**
- One general command that sets any field (`compass set FIELD VALUE`).
  Rejected: it could write anything, so it could not enforce the rules that make
  each act correct.
- A separate `accept-memo` command. Rejected: accepting a memo and accepting a
  decision are the same act on a record; the command applies the memo-specific
  rule of COMPASS-D44 when the record is a memo.

### COMPASS-DRAFT-emacs-review-D3 — Acts reserved for people are enforced by the commands

**Status:** Proposed

**Context:** COMPASS-D38 reserves acceptance, and COMPASS-D62 reserves the
resolution of findings, for people; COMPASS-D39 allows self-approval only to the
declared steward of a solo namespace. The rule `review/approver`, which checks
approvals after the fact, is planned but not yet built. A command that writes
`approved-by` is exactly what an agent must not run, and a program cannot tell
whether a person is at the keyboard.

**Decision:**
- `approve`, `accept`, and `resolve` take the approver with `--by`, defaulting to
  the Git identity (`user.name`) canonicalised through `.mailmap` (§7). They
  refuse when the approver is an assistant (named in the document's
  `provenance: assistant`, or as a tool in an `Assisted-by:` trailer on a commit
  that touched it), and refuse self-approval unless the manifest declares the
  approver the steward of a solo namespace (COMPASS-D39).
- The `review/approver` rule is built in the same release, so that approvals
  written by hand are held to the same rules.
- The `compass-*` skills never call these three commands. The skills test
  (`tests/test-skills.lisp`) gains a check that no skill or command file
  instructs an agent to run them.
- These are safeguards, not proof. The real gate remains the person who commits
  or approves the change under branch protection (COMPASS-D38). The commands
  state this in their help.

**Alternatives:**
- Leave enforcement to `compass check` alone. Rejected: a refused write is better
  than a finding after the fact, and the checker cannot see who ran a command.
- Require an interactive confirmation. Rejected: it adds friction for people and
  stops no agent that can answer a prompt.

### COMPASS-DRAFT-emacs-review-D4 — A read command reports review state as JSON

**Status:** Proposed

**Context:** A status buffer, a batch list, a language server, and a VS Code view
all need the same thing: the documents and records of the corpus with their
statuses and approvals, and which of them await a person's decision. The index
holds most of this as Markdown for reading, not as data.

**Decision:** The toolchain gains `compass list`, which reports documents and
records with their kind, genre or record kind, status, component, approver and
review date, host, and whether they await review. `--pending` limits the output
to what awaits a person: documents in `Proposed` or `In-Review`, decision
records in `Proposed`, memos in `Draft`, and critique findings without a
resolution. `--kind`, `--status`, and `--component` filter it further, and
`--format json` gives the data. Its shape is sketched under
[The review state](#the-review-state).

**Alternatives:**
- Parse `doc/INDEX.md` in the editor. Rejected: it is a rendering for people, and
  it omits review fields.
- Give `compass check` a review mode. Rejected: review state is not a conformance
  finding.

### COMPASS-DRAFT-emacs-review-D5 — Emacs 29.1, with transient, magit-section, and Eglot

**Status:** Proposed

**Context:** The package needs a structured overview with actions on each item
and menus that collect arguments. Magit's two libraries, `magit-section`
(collapsible sections tied to objects) and `transient` (menus of commands with
arguments), are the established way to build both. Their current releases
require Emacs 28.1. Emacs 29.1 adds Eglot (a language-server client), which the
later language features use (COMPASS-DRAFT-emacs-review-D8), and
`package-vc-install`, which installs a package from a directory of a Git
repository. Three baselines were compared: 27.1 with built-in widgets only,
28.1, and 29.1. The steward's Emacs was 27.1 when this Plan was written, so it
must be upgraded before the package can be used.

**Decision:** The package requires Emacs 29.1, and depends on current releases
of `transient` (from GNU ELPA, not the older copy bundled with Emacs),
`magit-section`, `markdown-mode`, and `compat`. It uses the built-in Flymake,
Eglot, `tabulated-list-mode`, and `package-vc`.

**Alternatives:**
- Emacs 27.1 with built-in widgets only (`tabulated-list-mode`,
  `completing-read`, a status buffer of headings and buttons). Rejected: it runs
  on the steward's present Emacs, but gives a plainer interface and would need a
  rewrite of the view layer later.
- Emacs 27.1 with pinned old releases (`transient` 0.10, `magit-section` 4.3).
  Rejected: frozen dependencies that receive no fixes.
- Emacs 28.1. Rejected: current libraries, but no built-in Eglot or
  `package-vc-install`.

### COMPASS-DRAFT-emacs-review-D6 — The package lives in src/mod/emacs, in three layers

**Status:** Proposed

**Context:** `src/mod/` holds modular extensions to the toolchain; the language
server will live there too. The package should keep its command-line plumbing,
its actions, and its interface apart, so that a change of interface, or a second
front end, does not touch the rest.

**Decision:** The package lives in `src/mod/emacs/`, with `compass.el` as its
main file. Its files form three layers, each using only those before it:
1. **`compass-cli`:** runs `compass`, parses its JSON, reports its errors, and
   checks that the program's version is one the package supports.
2. **`compass-actions`:** each act as a function with explicit arguments
   (`compass-approve`, `compass-accept`, `compass-set-status`,
   `compass-resolve`), plus the refresh that follows an act.
3. **The interface:** the status buffer (`compass-status`), the menus
   (`compass-menus`), the batch list (`compass-review-list`), the minor mode for
   Markdown buffers, and the Flymake backend (`compass-flymake`).

The files are listed under [The Emacs package](#the-emacs-package). Tests live
in `src/mod/emacs/test/` and run with ERT.

**Alternatives:**
- A separate repository. Rejected for now: the package and the commands it calls
  change together, and one repository versions them together.
- A single file. Rejected: the layers would blur, and the interface could not be
  replaced without touching the plumbing.

### COMPASS-DRAFT-emacs-review-D7 — Emacs Lisp source headers follow the Emacs library-header convention

**Status:** Proposed

**Context:** [COMPASS-0002](Spec.SourceHeaders.md) gives Emacs Lisp the prefix
`;;;` and reads the header block as the run of lines with that prefix. Emacs's
own library-header convention, which `package.el` and the Emacs Lisp tools rely
on, differs. The first line is `;;; compass.el --- summary` and carries the
`-*- lexical-binding: t -*-` cookie at its end. Keyword lines such as
`;; Author:`, `;; Version:`, and `;; Package-Requires:` follow with a two-semicolon
prefix, and the header ends at `;;; Commentary:`. Under the Spec as written, the
cookie would be read as part of the summary, and fields on `;;` lines would not
be read at all.

**Decision:** For Emacs Lisp, the source header is the library header. The
summary line keeps the `;;;` prefix, and a trailing `-*- … -*-` cookie on it is
not part of the description. Compass's fields (`Read-if:`, `See:`, `Invariant:`,
`Concerns:`, `Tests:`) are written as `;;`-prefixed keyword lines among the
library's own, which Emacs's header reader accepts. The block ends at
`;;; Commentary:` or `;;; Code:`. Amends COMPASS-0002 (minor; its
`schema-version` advances).

**Alternatives:**
- Follow COMPASS-0002 literally, with Compass fields on `;;;` lines. Rejected: it
  breaks the convention `package.el`, `checkdoc`, and other Emacs Lisp tools
  expect.
- Put Compass fields in the Commentary section. Rejected: the commentary is free
  prose that Emacs renders as the package description.

### COMPASS-DRAFT-emacs-review-D8 — Editor language features come from a language server, through Eglot

**Status:** Proposed

**Context:** Beyond review, an editor can help with Compass documents in the way
it helps with code: diagnostics as one types, jumping from an identifier to its
document or record, completing identifiers, and showing a record's title when
point is on its identifier. Written in Emacs Lisp, these would need writing again
for VS Code. A language server written once, under `src/mod/`, serves both:
Emacs through the built-in Eglot, VS Code through a thin extension.

**Decision:** Editor language features (diagnostics, definitions, completion,
hover) come from a Compass language server, used in Emacs through Eglot. Until
that server exists, v1 provides diagnostics alone through a Flymake backend that
runs `compass check --format json` on save. The review interface (status buffer,
menus, batch list, actions at point) stays in Emacs Lisp, because the protocol
offers no good form for it; the language server may later expose the same acts
as code actions for VS Code.

**Alternatives:**
- Write definitions, completion, and hover in Emacs Lisp now. Deferred: see
  COMPASS-DRAFT-emacs-review-O3.
- Provide no diagnostics until the server exists. Rejected: inline findings are
  cheap with the JSON report and useful at once.

### COMPASS-DRAFT-emacs-review-D9 — Installation from the repository, tests in CI, a version handshake

**Status:** Proposed

**Context:** The package must be installable before it is published to a package
archive, it must be tested against the Emacs versions it supports, and it must
not run against a `compass` program too old for the commands it calls.

**Decision:**
- **Installation.** `package-vc-install` from the Compass repository, naming
  `src/mod/emacs` as the package's directory. Publication to MELPA or NonGNU
  ELPA follows later (COMPASS-DRAFT-emacs-review-O5).
- **Tests.** ERT tests for each layer. The command-line and action layers are
  tested against temporary Git repositories holding small corpora, using the real
  `compass` program built by `make build`, as the toolchain's own tests use
  temporary repositories (`tests/helpers.lisp`). Interface tests check the
  contents of the status buffer and the commands its keys run. A CI job runs them
  on Emacs 29 and 30; `make test-emacs` runs them locally.
- **Handshake.** On first use the package runs `compass version` and refuses,
  with a message naming the minimum version, if the program is older than the
  package requires. The JSON reports carry a format version, so the package can
  tell a change of shape from a change of content.

**Alternatives:**
- Mock the program in tests. Rejected for the command and action layers: the
  point of COMPASS-DRAFT-emacs-review-D1 is that the program holds the rules,
  so tests must exercise it.
- Publish to an archive first. Deferred: the commands it needs do not yet exist
  in a released toolchain.

## The write commands

Table: The four write commands, what each changes, and when each refuses.

| Command | Changes | Refuses when |
|---|---|---|
| `compass approve FILE [--status S] [--by NAME] [--date D]` | The document's `status` to an authoritative value; `approved-by`; `reviewed` (default today). `--status` defaults by genre family: `Accepted` for proposal and record genres, `Current` for reference genres; an `Arch` needs `--status Accepted` or `Design-Record` | The status is not authoritative for the genre; the approver is an assistant; self-approval outside a solo namespace; the document has check errors |
| `compass accept ID [--by NAME] [--date D]` | A decision record's `**Status:**` to `Accepted`; a memo's `**Status:**` to `Current`, and the memo host's `approved-by` and `reviewed` (COMPASS-D44) | The record is already authoritative; its host is a draft whose own status caps it (COMPASS-D16); the approver rules above |
| `compass set-status FILE-OR-ID STATUS [--superseded-by ID]` | A non-authoritative status of a document or record: `Draft`, `Proposed`, `In-Review`, `Implemented`, `Deprecated`, `Rejected`, `Withdrawn`, or `Superseded`. `Superseded` requires `--superseded-by` and writes both fields together (COMPASS-D9) | The status is authoritative (use `approve` or `accept`); the genre or record kind does not allow it; the successor does not resolve |
| `compass resolve FINDING (--accepted ID-OR-CHANGE \| --rejected REASON) [--by NAME] [--date D]` | Adds the finding's `**Resolution:**`: the date, then `accepted`, naming the decision record, plan, or change that answers it, or `rejected`, with the reason (COMPASS-D62) | The record is not a finding of a critique; it is already resolved; an accepted resolution names nothing that resolves; the approver rules above |

`Implemented` is listed under `set-status` because it reports that work was
built, not that a design was accepted; it carries no `approved-by`.

Each command, with `--format json`, prints an object of this shape:

```json
{ "format": 1,
  "command": "accept",
  "changed": [ { "path": "doc/Memo.Federation.md", "lines": [9, 10, 31] } ],
  "summary": "CLASSIC-M3 accepted (Current) by Andrew Sengul, 2026-10-30" }
```

Description: a write reports a format version, the command, each file it
changed with the line numbers that changed, and a one-line summary for display.

## The review state

`compass list --format json` prints the corpus's documents and records as data.
A sketch of one entry of each kind:

```json
{ "format": 1,
  "documents": [
    { "id": "COMPASS-0007", "path": "doc/Plan.AgentWorkflow.md",
      "genre": "Plan", "status": "Accepted", "component": "authoring-assistance",
      "approved-by": "Andrew Sengul", "reviewed": "2026-10-13", "pending": false } ],
  "records": [
    { "id": "COMPASS-DRAFT-emacs-review-D1", "kind": "decision",
      "host": "COMPASS-DRAFT-emacs-review", "status": "Proposed",
      "line": 120, "pending": true },
    { "id": "COMPASS-DRAFT-ledger-critique-O1", "kind": "finding",
      "host": "COMPASS-DRAFT-ledger-critique", "severity": "medium",
      "resolution": null, "line": 160, "pending": true } ] }
```

Description: documents carry their identifier, path, genre, status, component,
approval fields, and whether they await review; records carry their identifier,
kind, host, status or, for a finding, severity and resolution, their line, and
whether they await review.

## The Emacs package

### Files

Table: Files of the Emacs package, by layer.

| Layer | File | Contents |
|---|---|---|
| — | `compass.el` | Package header, customisation group, autoloads, `compass-mode` (the minor mode for Markdown buffers in a Compass repository) |
| 1 | `compass-cli.el` | Locating and running `compass`; JSON parsing; error reporting; the version handshake |
| 2 | `compass-actions.el` | `compass-approve`, `compass-accept`, `compass-set-status`, `compass-resolve` as functions of explicit arguments; the refresh after an act |
| 3 | `compass-status.el` | The status buffer, built with `magit-section` |
| 3 | `compass-menus.el` | The `transient` menus |
| 3 | `compass-review-list.el` | The batch list, built on `tabulated-list-mode` |
| 3 | `compass-flymake.el` | The Flymake backend |
| — | `test/*.el` | ERT tests |

### The status buffer

`M-x compass-status` opens a buffer for the repository at point, in the manner of
`magit-status`. It is built from `compass list --pending` and
`compass check --format json`, with one collapsible section per group:
- **Documents awaiting review:** `Proposed` and `In-Review` documents.
- **Decisions to accept:** decision records in `Proposed`, under their hosts.
- **Unreviewed memos:** memos in `Draft`, under their hosts, with their
  `**Read-if:**` lines.
- **Open findings:** critique findings without a resolution, by severity.
- **Check findings:** errors first, then warnings.

`RET` visits the item at its line. A key on an item opens the menu for the act
that suits it. `g` refreshes. With a prefix argument, the buffer covers the
federated repositories too (COMPASS-DRAFT-emacs-review-O4).

### Menus

Each act has a `transient` menu that collects its arguments, prefilled and
remembered across uses:
- **Approve:** status (offered from the genre's authoritative values), approver
  (default: the Git identity, or the manifest's steward), date (default today);
  `--dry-run` as a switch.
- **Accept:** approver and date; shows, before confirming, the host fields a memo
  acceptance will change.
- **Set status:** the statuses the item allows; for `Superseded`, a successor
  read with completion over the corpus's identifiers.
- **Resolve:** accepted or rejected; for accepted, the answering decision record
  or plan, read with completion; for rejected, the reason.
- **Review:** a top-level menu reaching the four acts, the status buffer, the
  batch list, `compass check`, and `compass index`.

### Actions at point

In a Markdown buffer of a Compass repository, `compass-mode` binds the menus
under one prefix key, chosen within Emacs's conventions for minor modes and
customisable. The act applies to what point is in: the record whose heading or
body contains point, else the document. A buffer with unsaved changes is offered
for saving before any act, since the command rewrites the file on disk.

### Batch review

`M-x compass-review-list` lists pending records in a sortable table, in the
manner of `list-packages` and Dired: `m` marks a row, `u` unmarks, and `x` runs a
chosen act (accept, or set status) over all marked rows, one command per row, and
reports each result. Resolutions are not batched; each finding needs its own
reason or answer.

### After an act

The package reverts each buffer the command changed, re-runs the check for those
files, regenerates the index with `compass index`, refreshes the status buffer,
and, where Magit is installed, offers to stage the changed files. It does not
commit.

### Diagnostics

The Flymake backend runs `compass check --format json` on the file when it is
saved and shows each finding at its line, with its rule and severity. It is
replaced by the language server's diagnostics once that exists
(COMPASS-DRAFT-emacs-review-D8).

## Later priorities

Recorded here so that v1 is built with room for them:
- **The language server** under `src/mod/lsp/`, giving diagnostics, definitions,
  completion of identifiers, and hover (COMPASS-DRAFT-emacs-review-D8); Eglot
  configuration in the package; the four acts offered as code actions.
- **A VS Code extension** using the same server and the same write commands.
- **Federated review:** pending items across the repositories of a federation
  (COMPASS-DRAFT-emacs-review-O4).
- **Authoring help** beyond review: scaffolding a document from a template,
  inserting the next provisional record (`compass next --in`), and assigning
  numbers with `compass assign` from the status buffer.

## Open Questions

### COMPASS-DRAFT-emacs-review-O1 — Should accepting a decision update its host's approval?

COMPASS-D44 makes a memo's host record the latest acceptance of any of its memos
in `approved-by` and `reviewed`. Decision records have no such rule: accepting
one changes only its `**Status:**`, and the commit is the record of who did it.
Should `compass accept` treat decisions as it treats memos, which would need an
amendment to §8, or leave the host alone?

### COMPASS-DRAFT-emacs-review-O2 — Should approval also record the approver as a reviewer?

`reviewers:` lists who reviewed a document (§6). Should `compass approve` add the
approver to `reviewers:` when absent, or is `approved-by` enough, leaving
`reviewers:` for people who reviewed without approving?

### COMPASS-DRAFT-emacs-review-O3 — Interim language features in Emacs Lisp

If the language server is far off, should v2 add definitions, completion, and
hover in Emacs Lisp, built on `compass show`, `compass refs`, and `compass list`,
to be retired when the server arrives? The cost is code written twice; the
benefit is having them sooner.

### COMPASS-DRAFT-emacs-review-O4 — Review across a federation

`compass check --federation` reads federated repositories where they are checked
out. Should the status buffer show their pending items too, given that acting on
them writes into another repository, whose steward may differ and whose commits
are separate?

### COMPASS-DRAFT-emacs-review-O5 — Publishing the package

When the commands are released, should the package be published to MELPA, to
NonGNU ELPA, or neither, leaving installation from the repository? Publication
needs a version scheme for the package apart from the toolchain's, or a rule
tying the two.

## Prior Art

Table: Prior systems and what this plan draws from each.

| System | What to draw from |
|---|---|
| Magit | The status buffer as the centre of a workflow; `magit-section` for its structure and `transient` for its menus |
| Forge | Reviewing pull requests from Emacs: the review act kept in the editor, the record kept in the forge |
| Dired, `list-packages` | Marking rows and running one act over all marked rows |
| `markdown-mode` | The major mode the minor mode extends |
| Denote | Managing YAML front-matter in Markdown files by command rather than by hand |
| Flymake, Eglot | Diagnostics from an external program now; language features from a server later |
| `compass assign` | A write that is planned before it is executed, refused when invalid, and previewed with `--dry-run` (COMPASS-D28) |

## Roadmap

1. **This Plan.** Record the decisions.
2. **Toolchain write commands.** `approve`, `accept`, `set-status`, `resolve`,
   and `list`, with JSON output; the `review/approver` rule; the skills check of
   COMPASS-DRAFT-emacs-review-D3; FiveAM tests for each, including every refusal.
   Amend COMPASS-0002 for Emacs Lisp headers (COMPASS-DRAFT-emacs-review-D7).
   Released as a toolchain version, at the steward's choice of number.
3. **Package plumbing.** `compass.el`, `compass-cli.el`, `compass-actions.el`;
   the version handshake; ERT tests against temporary repositories;
   `make test-emacs` and the CI job on Emacs 29 and 30. The steward upgrades to
   Emacs 29.1 or later before this step.
4. **Package interface.** The status buffer, the menus, `compass-mode` with
   actions at point, and the batch list.
5. **Diagnostics.** The Flymake backend.
6. **Documentation.** A `howto` Guide for installing and using the package, and a
   section in the toolchain's documentation for the write commands.
7. **Later priorities,** as listed above, beginning with the language server.
