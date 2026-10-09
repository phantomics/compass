---
id:            COMPASS-DRAFT-toolchain-log
title:         Compass Toolchain Development Log
genre:         Log
scope:         component
program:       Compass
component:     toolchain
language:      en
status:        Accepted
authors:
  - Andrew Sengul
approved-by:   Andrew Sengul
reviewed:      2026-10-07
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-DRAFT-toolchain
  - COMPASS-0001
  - COMPASS-DRAFT-authoring-assistance
  - COMPASS-DRAFT-agent-workflow
  - COMPASS-DRAFT-authoring-assistance-log
decisions:
  - COMPASS-DRAFT-toolchain-log-D1
  - COMPASS-DRAFT-toolchain-log-D2
  - COMPASS-DRAFT-toolchain-log-D3
  - COMPASS-DRAFT-toolchain-log-D4
---

# Compass Toolchain: Development Log

This document chronicles the construction of version 0.1 of the Compass
toolchain, the `compass` command that checks a repository's documents against
the standard ([COMPASS-0001](../Compass.md)), and the commands added the same
day so that the authoring skills could use it. It records the decisions made
while coding that the plan left open, what each part of the code does, what
went wrong along the way, and how the result was verified. The plan it carries
out is [COMPASS-DRAFT-toolchain](Plan.Toolchain.md); version 0.1 is that
plan's first baseline release, "corpus checking without a ledger".

## Problem

The standard was checked only by convention and editorial review (§13, §22).
While its documents were being written, conformance was tested with throwaway
scripts, each covering a few rules and none kept. Three things depended on a
real checker:

- **The authoring skills.** They ran in advisory-only mode for lack of a
  toolchain ([COMPASS-D2](Plan.AuthoringAssistance.md#compass-d2--advisory-only-until-the-toolchain-exists)),
  so a skill could not tell an author whether a document conformed.
- **The agent-context evaluation.** It grades the proposals of its
  full-Compass condition with `compass check`, run over corpora that are only
  partly migrated
  ([COMPASS-DRAFT-agent-context-eval](Eval.AgentContext.md)).
- **The standard's own corpus.** Several thousand lines of Plans, Specs, and
  Surveys had accumulated in `doc/`, with cross-references and decision records
  that nothing had verified.

## Design Decisions

The build carried out these decisions of the plan:

- [COMPASS-DRAFT-toolchain-D7](Plan.Toolchain.md#compass-draft-toolchain-d7--common-lisp-with-purpose-built-parsers):
  Common Lisp, with purpose-built parsers.
- [COMPASS-DRAFT-toolchain-D18](Plan.Toolchain.md#compass-draft-toolchain-d18--a-strict-yaml-subset-parser-written-in-lisp):
  front-matter is read by a strict YAML-subset parser that keeps every scalar
  a string.
- [COMPASS-DRAFT-toolchain-D19](Plan.Toolchain.md#compass-draft-toolchain-d19--portable-binary-distribution):
  the constraints on the code that keep a portable executable possible. The
  distribution itself belongs to v0.2.
- [COMPASS-DRAFT-toolchain-D20](Plan.Toolchain.md#compass-draft-toolchain-d20--vocabulary-values-carry-a-standing):
  every vocabulary value carries a standing, accepted or pending.
- [COMPASS-DRAFT-toolchain-D21](Plan.Toolchain.md#compass-draft-toolchain-d21--implementation-conventions-for-the-baseline):
  layered packages, the heading-anchor rule, corpus discovery, the repository
  root, syntax errors, unverified references, and `compass rules`.

Several other decisions shape individual rules: the `Superseded` status form
([COMPASS-DRAFT-toolchain-D5](Plan.Toolchain.md#compass-draft-toolchain-d5--supersession-uses-a-plain-status-plus-the-existing-field)),
provisional record identifiers
([COMPASS-DRAFT-toolchain-D2](Plan.Toolchain.md#compass-draft-toolchain-d2--provisional-identifiers-for-register-entries)),
warnings for unknown keys
([COMPASS-DRAFT-toolchain-D13](Plan.Toolchain.md#compass-draft-toolchain-d13--unknown-front-matter-keys-warn-read-if-is-a-registered-extension)),
and the full-identifier record heading
([COMPASS-DRAFT-toolchain-D16](Plan.Toolchain.md#compass-draft-toolchain-d16--register-record-headings-carry-the-full-identifier)).

Four further decisions were made while coding. They are recorded here as
proposals for the steward.

### COMPASS-DRAFT-toolchain-log-D1 — The manifest reader never creates symbols

**Status:** Proposed

**Context:** The plan says the manifest and ledger are read "with
`*read-eval*` bound to false and a reader restricted to strings, integers,
keywords, and lists." The Lisp reader with `*read-eval*` off still interns
every symbol it reads, still accepts reader macros such as `#p` and `#+`, and
is a large surface for input that arrives in pull requests from forks.

**Decision:** A tokenizer written for the purpose,
`src/model/sexp.lisp:read-restricted-sexps@4e4549a`, accepts strings (with
only the `\"` and `\\` escapes), integers of up to 18 digits, keywords, proper
lists, and `;` comments, nested at most 32 deep. A keyword that is already
interned is returned as that symbol; any other keyword is returned as a
`foreign-keyword` holding its name, so an unknown manifest key can be reported
without being created. Everything else is a syntax error with a line and
column.

**Alternatives:**
- The Lisp reader with `*read-eval*` off, in a scratch package. Rejected: it
  still interns, and still runs reader macros.
- A manifest in YAML or JSON. Rejected by COMPASS-DRAFT-toolchain-D4; the
  restricted reader keeps the s-expression without its risks.

### COMPASS-DRAFT-toolchain-log-D2 — Problems found while loading are rules too

**Status:** Proposed

**Context:** Some problems are found before any rule can run: a file that
cannot be read as UTF-8, a malformed manifest, front-matter outside the YAML
subset, and a file in the document directory without front-matter. Reported
outside the rule engine, they would be invisible to `--rule`, `--exclude`, and
`compass rules`, and a skill could not explain them.

**Decision:** They are registered as rules whose findings the loader produces:
`file/read`, `manifest/valid`, `fm/syntax`, and `fm/present`
(`src/rules/engine.lisp:define-rule@4e4549a`, with scope `:load`). The check
selects and filters them like every other rule. A document whose front-matter
does not parse receives one `fm/syntax` finding and no front-matter checks,
as COMPASS-DRAFT-toolchain-D21 requires, but its body is still scanned and its
links still checked.

**Alternatives:**
- A separate list of load errors. Rejected: two ways of reporting the same kind
  of thing.
- Reporting a syntax error as errors in each field. Rejected: one mistake would
  produce a screenful of findings.

### COMPASS-DRAFT-toolchain-log-D3 — Checking one path still checks the whole corpus

**Status:** Proposed

**Context:** `compass check PATH` is how an author or a skill checks one
document. Several rules concern the corpus as a whole: `id/unique`,
`register/unique`, `register/mirrored` for records a document amends, and every
reference rule. Checking only the named file would miss a duplicate
identifier, and would report every reference to another document as unresolved.

**Decision:** The whole corpus is always loaded and checked;
`src/rules/engine.lisp:check-corpus@4e4549a` then keeps only the findings for
the named paths. A directory stands for every file beneath it.

**Alternatives:**
- Load only the named files. Rejected: the corpus-wide rules would be wrong.
- Load the named files and what they reference. Rejected: a duplicate is found
  only from the other side.

The cost is that a check takes as long as the whole corpus does: about 75 ms
for this repository's ten documents.

### COMPASS-DRAFT-toolchain-log-D4 — A closed output stream ends the command quietly

**Status:** Proposed

**Context:** People and agents pipe `compass` into `head`, `jq`, or a pager.
When the reader stops reading, the next write fails. Unhandled, SBCL printed a
backtrace and the command exited 2, an internal error.

**Decision:** `src/cli.lisp:main@4e4549a` treats a stream error on standard
output (`src/cli.lisp:output-closed-p@4e4549a`) as the reader having finished,
and exits 141 without printing anything, as a Unix tool terminated by SIGPIPE
would. Standard output is flushed inside the handler, so that a failure on the
final flush is caught too.

**Alternatives:**
- Exit 0. Rejected: a caller checking the status would not know its JSON was
  cut short.
- Exit 2. Rejected: a closed pipe is not an internal error.

## Implementation

Code references below are pinned to `4e4549a`, the v0.1 commit. Work added
later the same day is described in
[Update 2026-10-08](#update-2026-10-08--outline-refs-and-check-paths).

### Build and packages

- `compass.asd@4e4549a` defines the systems `compass` and `compass/tests`. The
  first builds the executable `bin/compass` through ASDF's `program-op`, with
  the entry point `compass.cli:main`.
- `build.lisp:stamp-build@4e4549a` loads Quicklisp or ocicl, chosen by the
  `DEPS` environment variable, and records the commit being built, with
  `-dirty` when tracked files differ, for `compass version` to print. Builds run
  with `--no-userinit`, so `~/.sbclrc` cannot affect them.
- `Makefile@4e4549a` provides `make build`, `make test`, and `make check`.
- `src/packages.lisp@4e4549a` defines eight packages, from `compass.util` and
  `compass.vocab` up to `compass.cli`, each using only those defined before it,
  beneath a `compass` package that re-exports their interfaces (D21).
- The runtime dependencies are `alexandria`, `cl-ppcre`, and `shasht`; the tests
  add `fiveam`. None needs a native library.

### Vocabulary

- `src/vocab.lisp:*genres*@4e4549a` holds the eleven genres, each with its
  filename prefix, code, status family, subtypes, section spine, and standing.
- `src/vocab.lisp:*status-families*@4e4549a` holds the three status families:
  proposal and record genres, reference genres, and Memo. The pending values
  are `Superseded` in the proposal family (D5), the assignment of Glossary and
  Ideation to families (D12), and the `threat-model` subtype.
- `src/vocab.lisp:*field-specs*@4e4549a` gives each §7 field its type, whether
  it is required or derivable from Git, and the genres it applies to.
  `read-if:` is registered as a pending extension (D13).
- `src/vocab.lisp:well-formed-language-tag-p@4e4549a` is the BCP 47 grammar as
  one regular expression.

### Identifiers and the document model

- `src/model/identifier.lisp:parse-identifier@4e4549a` recognises canonical
  document identifiers (at least four digits), canonical `D`, `O`, and M
  records, and their provisional forms. Slugs are lowercase, so the `-D1` of a
  provisional record cannot be mistaken for part of its slug.
  `src/model/identifier.lisp:diagnose-identifier@4e4549a` says why a string is
  not a document identifier, for the `id/format` message.
- `src/model/document.lisp:document@4e4549a` is the document class. Every
  section, record, link, table, and code span records its line, and most
  record a column.
- `src/model/fields.lisp:convert-field@4e4549a` reads a field against its
  schema type. Dates must name real calendar days; `authors` must be a list,
  so a second author cannot be added as a mistyped scalar; relation fields must
  name documents, not records; register fields must list records of their kind.
- `src/model/manifest.lisp:read-manifest@4e4549a` reads `compass.sexp` with the
  restricted reader (D1). An unknown key is a warning; a malformed manifest
  yields defaults and `manifest/valid` findings, never a crash.

### Front-matter

- `src/parse/document.lisp:split-front-matter@4e4549a` finds the block between
  the `---` lines. A block that is opened and never closed is an `fm/syntax`
  error.
- `src/parse/yaml.lisp:parse-yaml-subset@4e4549a` parses the subset of D18 by
  recursive descent over the block's lines, after
  `src/parse/yaml.lisp:prepare-lines@4e4549a` has dropped blank and comment
  lines and rejected tab indentation. A sequence item may begin a mapping on
  the dash's own line, as `cites:` entries do.
- `src/parse/yaml.lisp:check-plain@4e4549a` rejects `: ` inside an unquoted
  value, as YAML does. The §6 form `status: Superseded-by: <id>` is therefore
  an `fm/syntax` error; quoted, it parses, and `vocab/status` warns that D5
  replaces it.
- Every error names the construct and a remedy ("a quoted value must close on
  the same line", "block scalars (| and >) are not supported; keep the value on
  one line").

### Body scanner

- `src/parse/scanner.lisp:classify-lines@4e4549a` gives each body line a kind:
  fenced code (with the closing rule of CommonMark), block HTML comment,
  heading, text, or blank. Nothing inside a fence or comment is read as
  structure, so the example records in the Plans are not taken for real ones.
- `src/parse/inline.lisp:find-code-spans@4e4549a` matches backtick runs as
  CommonMark does, across the lines of a paragraph.
  `src/parse/inline.lisp:find-links@4e4549a` finds inline links and images
  outside code spans and comments, including an image inside a link.
- `src/parse/inline.lisp:heading-anchor@4e4549a` implements the anchor rule of
  D21, and `src/parse/scanner.lisp:build-sections@4e4549a` adds `-1`, `-2`, and
  so on for repeats and records each section's line range.
- `src/parse/scanner.lisp:build-records@4e4549a` reads record headings of the
  form `<ID> — <title>` at levels 2 to 4. A short heading such as `D16 — …` is
  read with the host's namespace, so that `register/heading-form` can report
  it. `src/parse/scanner.lisp:record-fields-in@4e4549a` collects the bold-label
  fields of a record, joining continuation lines and removing HTML comments.
- `src/parse/scanner.lisp:build-tables@4e4549a` records each table's header
  cells and the `Table:` caption before it (D6), ready for the §12 rules.
- `src/parse/inline.lisp:parse-code-reference@4e4549a` parses the §9 grammar,
  `[NS:]path[:symbol | #Lstart[-Lend]]@revision`.

### Corpus

- `src/corpus/corpus.lisp:find-repository-root@4e4549a` looks upward for
  `compass.sexp`, then for `.git`.
- `src/corpus/corpus.lisp:discover-files@4e4549a` finds the documents as D21
  describes, in path order. `src/corpus/corpus.lisp:load-corpus@4e4549a`
  indexes them by identifier and their records by record identifier. With
  `--skip-unmarked`, files without front-matter are counted instead of
  reported.
- `src/corpus/corpus.lisp:resolve@4e4549a` resolves `ID`, `ID#anchor`, and
  record identifiers; `src/corpus/show.lisp:show@4e4549a` prints what they
  name, with the source lines it came from.
- `src/corpus/index.lisp:generate-index@4e4549a` writes `INDEX.md`: a banner,
  then for each namespace a captioned table of documents and one of records,
  linked relative to the document directory, canonical identifiers before
  provisional ones.
- `src/corpus/index.lisp:next-identifier@4e4549a` previews the next number from
  the highest one in the working tree, and says the answer is advisory.

### Rules

- `src/rules/engine.lisp:define-rule@4e4549a` defines a rule with its name,
  severity, section of the standard, scope, and summary.
  `src/rules/engine.lisp:rule-selected-p@4e4549a` lets `--rule` and `--exclude`
  name a rule or a group (`fm`, `fm/`, or `fm/*`).
- Twenty-five rules: the four load rules (D2) in `src/rules/engine.lisp`, and
  front-matter and vocabulary, identity, register, memo, and reference rules in
  one file each. Errors come from MUST rules and warnings from SHOULD rules,
  as §22 requires.
- Messages suggest the fix where one is likely: `vocab/genre` maps the prefix
  `Arch` to `Architecture`, and `fm/unknown-key` offers the nearest field name
  (`relates_to` to `relates-to`).
- `src/rules/references.lisp:check-link@4e4549a` checks that a relative link's
  file exists, that its anchor exists in a Markdown target, and that link text
  which is an identifier names what the target declares.
- `src/rules/memo.lisp:memo/basis@4e4549a` accepts a pinned code reference, an
  identifier that resolves, or the title of an entry in the host's `cites:`,
  and names an unpinned path when that is the problem. Without Git it checks the
  form of a reference, not that its revision exists.
- A reference into a namespace that no loaded document declares is counted as
  unverified and listed in the JSON report, never reported as a finding (D21).

### Report and command line

- `src/report.lisp:write-findings@4e4549a` writes findings as
  `path:line:column: severity rule: message` lines with a summary, or as JSON
  with the summary, findings, skipped files, and unverified references.
  `src/report.lisp:exit-code@4e4549a` returns 0 without errors (and, with
  `--strict`, without warnings) and 1 otherwise.
- `src/cli.lisp:parse-arguments@4e4549a` parses options by hand
  (`--name value`, `--name=value`, and comma-separated lists), so the command
  line adds no dependency.
- `src/cli.lisp:main@4e4549a` runs a command and exits 0 on success, 1 on
  findings or a failed lookup, 2 on a usage or internal error, 130 when
  interrupted, and 141 when its output is closed (D4).
- The commands are `check`, `show`, `index`, `next`, `rules`, `version`, and
  `help`.

### Changes to this repository

- **`Compass.md` gained front-matter:** `COMPASS-0001`, genre `Spec`,
  `schema-version: "0.2.0"`, status `Draft`. This brings forward part of
  [COMPASS-DRAFT-toolchain-D9](Plan.Toolchain.md#compass-draft-toolchain-d9--bootstrapping-the-compass-namespace):
  without it, nineteen references to `COMPASS-0001` across the corpus failed
  `ref/doc-resolves`.
- **`compass.sexp`** declares the `COMPASS` namespace, the document directory,
  three shell commands, and the steward's solo approval.
- **`doc/INDEX.md`** is the first generated index: ten documents and 76
  records.
- **`README.md`** gained a section on building and using the toolchain.
- **`doc/Plan.Toolchain.md`** gained D20 and D21, and its v0.1 scope gained the
  memo rules once the Memo genre was accepted
  ([COMPASS-DRAFT-agent-workflow](Plan.AgentWorkflow.md), D1 to D4), along with
  `fm/syntax`, `vocab/pending`, anchors in `show`, `rules`, and `version`.

## Design Properties

- Every finding has a path and a line, and most have a column.
- No scalar in front-matter is ever converted; its type comes only from the
  schema (D18).
- Reading the manifest neither runs code nor creates symbols (D1).
- Output is deterministic: files load in path order; findings sort by path,
  line, column, and rule; the index sorts by identifier.
- A reference into a namespace that is not loaded is counted, never failed.
- Each package uses only the packages beneath it, so the parser and model can
  serve the Markdown→Lexis importer and the RDF exporter without the rules.

## Pitfalls Encountered

1. **Values lost through `or`.** `build-records` first tried the full and short
   heading patterns as `(or (register-groups-bind …) …)`. `or` passes on only
   the first value of each form but the last, so the separator and title of a
   match were lost. Every record heading was reported as separating "its
   identifier and title with NIL": 76 false warnings on the first full run over
   the corpus. The function now uses `scan-to-strings` and returns its values
   explicitly.
2. **Format directives outside a format string.** Rule summaries were written
   with `~` and a newline to continue a line, which only works in a `format`
   control string. `compass rules` printed them literally. `define-rule` now
   removes them when the rule is defined.
3. **A command listed twice.** `help` is a registered command and was also
   printed explicitly in the help text.
4. **A backtrace on a closed pipe.** `compass check --format json | head`
   printed an SBCL backtrace (D4).
5. **`english` is a well-formed language tag.** A test expected `fm/language`
   to reject it, but BCP 47 allows language subtags of five to eight letters.
   The rule checks the form of a tag, not the IANA registry; the test now uses
   `en_US`.
6. **Type declarations and regular-expression bindings.** Structure slots
   declared as `string` drew compiler warnings, because
   `register-groups-bind` can bind `NIL`. The declarations were removed.

## Verification

- **Tests.** `make test` at `4e4549a`: **446 checks, 100% pass.** Re-run for
  this Log from a separate worktree of that commit. The suite covers each rule
  on violating and conforming input, every construct the YAML subset rejects,
  the scanner, the restricted reader with hostile input, the command line's
  exit codes and JSON, and this repository (`tests/test-repository.lisp`), whose
  front-matter blocks in `doc/`, `templates/`, `skills/`, and `Compass.md` must
  all parse and whose corpus must have no errors.
- **Self-check.** `bin/compass check`, built from `4e4549a`: "Checked 10
  documents: 0 errors, 0 warnings."
- **The executable.** 48,470,920 bytes (46.2 MiB), or 11.8 MiB with
  `gzip -9`. It links only `libc`, `libm`, `libdl`, and `libpthread`. It runs
  with an empty environment (`env -i LANG=C`) and still prints `—` and `§`
  correctly. It checks this repository in about 75 ms; `compass version` takes
  about 5 ms.
- **Corpora written before Compass**, checked with `--skip-unmarked`:

  Table: Results of `compass check --skip-unmarked` on the ancestor repositories.

  | Repository | Commit | Documents | Skipped | Errors |
  |---|---|---|---|---|
  | classic | `6e4f02d` | 5 | 26 | 23, all `register/unique` |
  | origin | `fcd57f8` | 1 | 15 | 0 |
  | lexter | `4d6a89d` | 0 | 11 | 0 |

  Classic's errors are real: four migrated Surveys each define their own
  `CLASSIC-O1` to `CLASSIC-O5`, and three of them a `CLASSIC-O6`.
- **Not verified.** The `DEPS=ocicl` build; any platform but Linux x86-64
  (Debian 11, glibc 2.31); and every rule that needs Git, none of which exists
  yet.

## Files

Table: Files added or changed in commit `4e4549a`.

| File | Action | Description |
|------|--------|-------------|
| `compass.asd` | **New** | Systems `compass` and `compass/tests`; executable build |
| `build.lisp` | **New** | Loads Quicklisp or ocicl; stamps the build commit; builds and tests |
| `Makefile` | **New** | `build`, `test`, and `check` targets |
| `compass.sexp` | **New** | This repository's manifest |
| `.gitignore` | **New** | Ignores `bin/`, fasls, and ocicl's dependency tree |
| `src/packages.lisp` | **New** | The layered packages and the `compass` facade |
| `src/util.lisp` | **New** | UTF-8 files, strings, dates, paths, edit distance |
| `src/vocab.lisp` | **New** | Genres, statuses, subtypes, scopes, register kinds, field schema |
| `src/model/identifier.lisp` | **New** | Identifier grammar, diagnosis, and search in text |
| `src/model/sexp.lisp` | **New** | Restricted s-expression reader (D1) |
| `src/model/document.lisp` | **New** | YAML nodes, body elements, documents, findings |
| `src/model/fields.lisp` | **New** | Typed reading of front-matter fields |
| `src/model/manifest.lisp` | **New** | The project manifest |
| `src/parse/yaml.lisp` | **New** | The strict YAML-subset parser (D18) |
| `src/parse/inline.lisp` | **New** | Code spans, links, anchors, code references |
| `src/parse/scanner.lisp` | **New** | Line kinds, sections, records, tables, fences |
| `src/parse/document.lisp` | **New** | From a file to a document |
| `src/corpus/corpus.lisp` | **New** | Root, discovery, loading, lookup, resolution |
| `src/corpus/show.lisp` | **New** | `compass show` |
| `src/corpus/index.lisp` | **New** | `compass index` and `compass next` |
| `src/rules/engine.lisp` | **New** | Rule registry, selection, the check, load rules (D2) |
| `src/rules/frontmatter.lisp` | **New** | Front-matter, vocabulary, supersession, and citation rules |
| `src/rules/identity.lisp` | **New** | `id/format`, `id/unique` |
| `src/rules/registers.lisp` | **New** | `register/*` |
| `src/rules/memo.lisp` | **New** | `memo/host`, `memo/fields`, `memo/basis` |
| `src/rules/references.lisp` | **New** | `ref/doc-resolves` |
| `src/report.lisp` | **New** | Text and JSON reports, exit codes |
| `src/cli.lisp` | **New** | Arguments, commands, entry point |
| `tests/*.lisp` | **New** | Twelve files: the package, helpers, and ten suites |
| `Compass.md` | Modified | Front-matter: `COMPASS-0001` |
| `README.md` | Modified | Building and using the toolchain |
| `doc/INDEX.md` | **New** | Generated namespace index |
| `doc/Plan.Toolchain.md` | Modified | D20, D21, and the v0.1 scope |

## Metrics

- Test checks: 446 at `4e4549a`; 527 after the update below.
- Regressions: 0.
- Rules: 25.
- Commands: 7 at `4e4549a`; 9 after the update.
- Source files: 23 (3,955 lines) at `4e4549a`; 25 (4,437 lines) after.
- Test files: 12 (1,013 lines) at `4e4549a`; 12 (1,220 lines) after.
- Runtime dependencies: 3 Lisp systems; 0 native libraries.

## Outstanding Work

- **Wire the skills to the toolchain.** Roadmap step 6 of
  [COMPASS-DRAFT-authoring-assistance](Plan.AuthoringAssistance.md#roadmap):
  the four skills still describe advisory-only mode. *Done in `07b9643`; see
  [Update 2026-10-08 — fresh executables and federation](#update-2026-10-08--fresh-executables-and-federation).*
- **Baseline v0.2.** The ledger and its rules, `assign` and `renumber` with the
  concurrency tests, Git-derived fields, code-reference checks, `index --check`,
  CI, the `DEPS=ocicl` build (no `ocicl.csv` is committed yet), `compass init`,
  and release executables (see the plan's
  [Baseline releases](Plan.Toolchain.md#baseline-releases)).
- **A stale build stamp.** `make build` reuses `bin/compass` when no source
  file has changed, even if the commit has, so the executable can report the
  wrong commit (see the update below). The build should remove the old
  executable first, or depend on the commit. *Fixed in `fcdec0c`; see
  [Update 2026-10-08 — fresh executables and federation](#update-2026-10-08--fresh-executables-and-federation).*
- **Language tags are checked for form only.** Checking against the IANA
  subtag registry would need the registry's data in the executable.
- **Classic's duplicate open questions.** The four Surveys should use
  provisional identifiers, `CLASSIC-DRAFT-<slug>-O<n>`.
- **Acceptance.** `COMPASS-0001` and this Log are `Draft`, and the four
  decisions above are `Proposed`.
- **Open questions** O3 to O7 of the plan, and the features that wait on the
  agent-context pilot: the catalog, the authority weight, and the source map.

## Update 2026-10-08 — outline, refs, and check paths

Commit `ee5f765` added the commands the skills need and fixed what running v0.1
the way a skill would had exposed. Code references in this section are pinned
to `ee5f765`.

### Problem

Running the v0.1 executable the way the skills would showed four gaps:

- `compass check templates/Log.template.md` reported "0 errors" and exited 0,
  because the file is not part of the corpus. An agent that wrote a draft in
  the wrong place would have been told it passed.
- Outside any repository, `compass check` reported "Checked 0 documents" and
  exited 0, with no warning.
- `compass show COMPASS-0001` printed all 1,588 lines of the standard. There was
  no way to see a document's sections before opening one.
- There was no way to ask what refers to an identifier. Searching for it with
  `grep` misses links whose text is not the identifier.

### Implementation

- `src/corpus/outline.lisp:document-outline@ee5f765` lists a document's
  headings with their levels, anchors, and line ranges. A record identifier
  outlines its host and names the record's anchor; an anchor limits the
  outline to one section and its subsections. Ranges are trimmed with
  `src/corpus/show.lisp:trim-trailing-blank-lines@ee5f765`, the same function
  `show` uses, so the two always agree.
- `src/corpus/refs.lisp:find-references@ee5f765` finds every reference to an
  identifier or section and reports each referring line once, under the most
  specific of five kinds: front-matter relation, register listing, link, memo
  basis, or prose mention. It reads line kinds from
  `src/parse/document.lisp:document-line-kinds@ee5f765` to skip fenced code and
  comments. It leaves out a record's own heading, its host's own listing of it,
  and, for a whole document, the document's links to its own sections. A
  reference in a front-matter list points at the line of the list item.
- `src/corpus/corpus.lisp:link-destination@ee5f765` works out where a link
  points. `ref/doc-resolves` (`src/rules/references.lisp:check-link@ee5f765`)
  and `refs` both use it, so they cannot disagree about a link.
- `src/cli.lisp:repository-path@ee5f765` rejects a path outside the
  repository, and `src/cli.lisp:check-selected-paths@ee5f765` rejects one that
  is not a file of the corpus (`src/corpus/corpus.lisp:corpus-paths@ee5f765`),
  saying where documents live. Both are usage errors, exit 2.
- `src/cli.lisp:load-corpus-for-command@ee5f765` warns on standard error when a
  repository has no documents, and `compass index` then refuses to write one.
- `src/report.lisp:summarize@ee5f765` counts only the documents a check was
  limited to: "Checked 1 document of 10". The JSON summary gains `loaded`.
- `Makefile@ee5f765` adds `make install`, to `PREFIX/bin` with `PREFIX`
  defaulting to `~/.local`, and `make uninstall`.
- The plan's D21 records that `outline` moved forward from roadmap step 6 and
  that `refs` was added.

### Pitfalls Encountered

1. **A conditional that left its argument behind.** The summary format
   `~:[~; of ~d~]` printed "Checked 10 documents: 10, 0 errors" when the check
   was not limited: the false branch did not consume the count, which then
   filled the next directive. The branch now skips it with `~*`.
2. **A stale build stamp.** While writing this Log, the executable built after
   the commit still reported `bc50318484da-dirty`: `make build` had kept the
   executable from before the commit, since no source file had changed. A
   forced rebuild reports `ee5f7655e52d`. The fix is listed under Outstanding
   Work.

### Verification

- **Tests.** `make test` at `ee5f765`: **527 checks, 100% pass**, 81 of them
  new, covering `outline`, `refs`, the path checks, the empty corpus, and the
  help listing.
- **On this repository**, at `ee5f765`: `compass refs COMPASS-DRAFT-toolchain`
  found 31 references in 9 documents, and
  `compass refs COMPASS-DRAFT-operator-memory` found 6 relations, 8 links, and
  1 mention.
- **Installation.** `make install` into a temporary prefix; the installed copy
  ran `check`, `outline`, and `refs`, and exited 141 when piped into `head`.
- **The executable**, rebuilt: 48,569,232 bytes (46.3 MiB), or 11.9 MiB with
  `gzip -9`; "Checked 10 documents: 0 errors, 0 warnings."

### Files

Table: Files added or changed in commit `ee5f765`.

| File | Action | Description |
|------|--------|-------------|
| `src/corpus/outline.lisp` | **New** | `compass outline` |
| `src/corpus/refs.lisp` | **New** | `compass refs` |
| `src/corpus/corpus.lisp` | Modified | Corpus paths, empty corpus, `link-destination` |
| `src/corpus/show.lisp` | Modified | Trimming shared with `outline` |
| `src/parse/document.lisp` | Modified | `document-line-kinds` |
| `src/rules/references.lisp` | Modified | Uses `link-destination` |
| `src/report.lisp` | Modified | Counts the documents checked |
| `src/cli.lisp` | Modified | `outline`, `refs`, path checks, empty-corpus warning |
| `src/packages.lisp` | Modified | New exports |
| `compass.asd` | Modified | The two new files |
| `Makefile` | Modified | `install` and `uninstall` |
| `tests/test-cli.lisp` | Modified | Commands, paths, empty corpus |
| `tests/test-corpus.lisp` | Modified | Outlines and references |
| `doc/Plan.Toolchain.md` | Modified | D21, the command list, and roadmap steps 6 and 8 |

## Update 2026-10-08 — fresh executables and federation

The skills were wired to the toolchain in commit `07b9643`, which
[COMPASS-DRAFT-authoring-assistance-log](Log.AuthoringAssistance.md)
chronicles. This update records the toolchain's part of that work and of the
follow-up commit `fcdec0c`, and closes two items of the Outstanding Work above.
Code references in this section are pinned to the commit named with each.

### Problem

- **A stale build stamp.** `make build` kept the old executable whenever no
  source file had changed, so `compass version` could name the commit before
  the one built. The skills now copy that string into review reports ("Checked
  with"), so a wrong stamp would mislead a reader about which toolchain checked
  a document.
- **No federation.** This repository's manifest listed no other repository, so
  a skill could not find Classic, Origin, or Lexter, which had no manifests of
  their own either.
- **The skills' tests needed the command line's own description of itself:**
  which commands exist, and which options each accepts.

### Implementation

- `build.lisp:build@fcdec0c` deletes `bin/compass` before calling `asdf:make`,
  so every build writes a fresh executable stamped with the current commit.
- `src/cli.lisp:command-names@07b9643` lists the subcommands in the order
  `compass help` gives them, and `src/cli.lisp:command-option-names@fcdec0c`
  the options a subcommand accepts. Both are exported for the tests in
  `tests/test-skills.lisp`.
- `compass.sexp@fcdec0c` lists Classic (`../classic`), Origin (`../origin`), and
  Lexter (`../../chat/lexter`) under `:federation`. Their own manifests,
  written at the same time, are not committed in their repositories.

### Verification

- **The build stamp.** Two successive builds in a clean worktree of `fcdec0c`
  each wrote a new executable, and both reported
  `compass 0.1.0 (commit fcdec0c9b062, SBCL 2.3.4, linux x86-64)`, with no
  `-dirty` suffix.
- **Tests.** `make test` at `fcdec0c`: **625 checks, 100% pass.**
- **Federation.** `compass show CLASSIC-DRAFT-x400 --root ../classic` from this
  repository resolved, as did lookups between the other three repositories.

### Files

Table: Toolchain files changed in commits `07b9643` and `fcdec0c`.

| File | Action | Description |
|------|--------|-------------|
| `build.lisp` | Modified | Deletes the old executable before building (`fcdec0c`) |
| `src/cli.lisp` | Modified | `command-names` (`07b9643`), `command-option-names` (`fcdec0c`) |
| `src/packages.lisp` | Modified | Exports both (`07b9643`, `fcdec0c`) |
| `compass.sexp` | Modified | `:federation` entries (`fcdec0c`) |
