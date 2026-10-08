---
id:            COMPASS-DRAFT-source-headers
title:         Compass Source Headers and Source Map
genre:         Spec
scope:         program
program:       Compass
component:     source-map
language:      en
status:        Draft
schema-version: "0.1"
authors:
  - Andrew Sengul
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-0001
  - COMPASS-DRAFT-toolchain
  - COMPASS-DRAFT-operator-memory
  - COMPASS-DRAFT-agent-workflow
cites:
  - title:     RFC 2119 — Key words for use in RFCs to Indicate Requirement Levels
    locator:   "§1–§5"
    external:  true
  - title:     GNU Emacs Lisp Reference Manual — Library Headers
    locator:   "Appendix D.8, Conventional Headers for Emacs Libraries"
    external:  true
  - title:     REUSE Specification
    locator:   "Comment headers (SPDX-License-Identifier, SPDX-FileCopyrightText)"
    external:  true
  - title:     Operator Memory repository (aerovato/operator-memory)
    locator:   "docs/architecture.md (index tree)@e394f1c"
    external:  true
  - title:     PEP 257 — Docstring Conventions
    locator:   "Module docstrings"
    external:  true
---

# Source Headers and Source Map Specification

This specification defines a **source header**: a short, structured comment at
the top of each source file that states what the file is for, when to read it,
and the facts about it that the code does not make obvious. It also defines the
equivalent block for **directory READMEs**, and the **source map**: a per-file
navigation index that the Compass toolchain generates deterministically from
those headers. The map gives coding agents and human readers a primer on a
repository before they explore its source. It is the Compass form of candidate 7
in [COMPASS-DRAFT-operator-memory](Survey.OperatorMemory.md), and the toolchain
work that implements it is recorded in
[COMPASS-DRAFT-toolchain](Plan.Toolchain.md) as COMPASS-DRAFT-toolchain-D14.
The key words MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY are used as described
in RFC 2119.

## Overview

Compass documents describe a system at the altitude of designs, decisions, and
reference manuals. Below that altitude sits the source tree, which an agent
otherwise enters cold. A source header closes the gap at the cheapest possible
point: one comment per file, written once and edited rarely, from which a map is
compiled without any LLM involvement.

The contract has three parties:

- **Source files** carry a header in the grammar below.
- **Directory READMEs**, which are optional, describe a directory and may carry
  fields that apply to everything beneath it.
- **The map extractor** (part of the Compass toolchain) reads headers and
  READMEs, validates them, and emits the source map.

**Relationship to §2.** [COMPASS-0001](../Compass.md) §2 cedes auto-generated API
reference at scale to tools such as declt and mgl-pax. That cession stands. The
source map is not API reference: it has one entry per file and per directory,
never per symbol, and it is navigational rather than descriptive. A clarifying
patch to §2 recording this boundary accompanies the acceptance of this
specification.

**Not a Compass document.** A source header has no identifier, no genre, and no
status lifecycle, and it is not YAML. Its fields are deliberately distinct from
§7 front-matter so that neither can be mistaken for the other.

### Terms

Table: Terms used in this specification.

| Term | Meaning |
|---|---|
| Header block | The first comment block of a source file, after any permitted preamble |
| Summary line | The first line of the header block: file name, separator, one-line description |
| Field | A `Label: value` line in the field block, with any continuation lines |
| Field block | The paragraph of fields immediately following the summary line |
| Free prose | Everything in the header block after the field block; unconstrained |
| Directory README | A `README.md` in any directory other than the repository root |
| Effective header | A file's own fields combined with the fields it inherits from directory READMEs |
| Source map | The generated, committed navigation index (`doc/MAP.md`) |

## Required Placement

1. The header block MUST be the first comment block in the file.
2. Only the following MAY precede it, each on its own line, optionally separated
   by blank lines:
   - a shebang line (`#!…`);
   - an Emacs file-variables line (`-*- … -*-`);
   - a Python encoding declaration;
   - REUSE/SPDX lines (`SPDX-License-Identifier:`, `SPDX-FileCopyrightText:`).
3. No code, including `(in-package …)` or `package` declarations, MAY precede the
   header block.
4. SPDX lines are not fields. Compass does not define them and does not validate
   them; it permits them so that a file can conform to both REUSE and this
   specification.

## Required Header Grammar

A header block is the maximal run of consecutive lines that begin with the
file's comment prefix (see [Comment syntax by language](#comment-syntax-by-language)).
Each line is read after removing the prefix and then at most one following space.
A line consisting of the prefix alone is a **blank** line.

```text
header        = summary-line [ blank field-block ] [ blank prose ]
summary-line  = filename SP sep SP description
sep           = "—" / "---" / "--"          ; "—" (U+2014) is canonical
field-block   = field-line *( field-line / continuation )
field-line    = label ":" SP value
label         = core-label / local-label
core-label    = UPPER 1*LOWER *( "-" 1*LOWER ) ; Read-if, Co-change, Generated-by
local-label   = "X-" 1*ALPHA *( "-" 1*ALPHA )
continuation  = 2*SP value                     ; extends the preceding field-line
list          = item *( "," SP item )
prose         = *line                          ; unconstrained
```

The following rules complete the grammar:

- **Summary line.** `filename` MUST equal the file's base name, which catches a
  header copied from another file. The description MUST fit on the one line and
  SHOULD keep the whole summary line within 100 characters. It SHOULD be a noun
  phrase stating the file's role, and SHOULD NOT end with a full stop.
- **Field block.** If the first paragraph after the summary line begins with a
  `label:` line, that paragraph is the field block, and every line in it MUST be
  a field line or a continuation. A prose paragraph that happens to begin with a
  `Word:` line is therefore read as fields; the unknown-label warning makes the
  mistake visible.
- **Labels** are case-sensitive and written exactly as registered.
- **Repetition.** A label MAY repeat only where the
  [field table](#required-fields) allows it.
- **Paths** in field values are repository-relative (relative to the repository
  root, not to the file). A directory path ends in `/`.
- **Free prose** after the field block is unconstrained and is never read by the
  extractor. Existing descriptive headers remain valid as free prose.

## Required Fields

Fields fall into two tiers. **Core** fields are the ones an author SHOULD
consider for every file. **Optional** fields apply only to some files.

Table: Header fields, with tier, cardinality, value form, and whether the source
map shows them.

| Label | Tier | Cardinality | Value | In map |
|---|---|---|---|---|
| *(summary line)* | Core | exactly 1 | `filename — description` | yes |
| `Read-if` | Core | 0..1 | a condition | yes |
| `See` | Core | 0..n | list of Compass identifiers | no |
| `Invariant` | Core | 0..n | one rule per field | no |
| `Tests` | Core | 0..n | list of test locators | no |
| `Status` | Optional | 0..1 | `experimental \| stable \| deprecated` | when not `stable` |
| `Generated-by` | Optional | 0..1 | generator path, optionally `from` inputs | yes, as a marker |
| `Concerns` | Optional | 0..n | list from the Concerns registry | yes, as flags |
| `Co-change` | Optional | 0..n | list of paths | no |

### Core fields

- **Summary line** (MUST). See the grammar above.
- **`Read-if`** (SHOULD). The condition under which a reader needs this file,
  phrased as a task or situation, for example "changing the message grammar or
  anything that reads peer input". It SHOULD stay within 160 characters. It
  answers *when* the file matters; the summary line already says *what* it is.
  It is the source-file counterpart of the `read-if:` front-matter extension
  (COMPASS-DRAFT-toolchain-D13); the capitalisation differs only to match each
  syntax's conventions.
- **`See`** (SHOULD, where applicable). Compass identifiers for the documents and
  register entries behind this file: the Plan or Spec it implements, the
  `D`-records whose decisions it embodies, the `O`-records for known gaps in it,
  and the memo records (`<NS>-M<n>`, COMPASS-DRAFT-agent-workflow-D2) for the
  system properties it relies on. An item is `<ID>` or `<ID>#<anchor>`, where
  `<ID>` is any canonical,
  register, or provisional identifier (§5, §8, §13). This is the link from code to
  rationale, and the only field that connects the source tree to the corpus.
- **`Invariant`** (SHOULD, where applicable). A rule the file's code must keep
  that the code alone does not make evident: a trust boundary, a thread-safety
  or lock-ordering rule, an ordering or idempotence guarantee, a "never X". One
  rule per field; repeat the label for more. An invariant with a recorded
  rationale SHOULD have that rationale's `D`-record in `See`. An invariant MUST
  NOT merely restate what the code plainly shows.
- **`Tests`** (SHOULD, where applicable). Where to verify a change to this file.
  A locator is a repository-relative path to a test file or directory, or, for
  Lisp, `asdf:<system-name>` naming a test system defined in the repository.

### Optional fields

- **`Status`**. The file's stability, from the
  [Status registry](#status-registry). Absence makes no claim. A `deprecated`
  file SHOULD name its replacement in `See` or in free prose.
- **`Generated-by`**. Marks the file as generated output. The value is the
  repository-relative path of the generator, optionally followed by `from` and a
  list of input paths. A reader MUST NOT edit a generated file by hand; changes
  belong in the generator or its inputs. The generator SHOULD emit the header
  itself.
- **`Concerns`**. Values from the [Concerns registry](#concerns-registry),
  flagging code that warrants extra scrutiny or specific testing.
- **`Co-change`**. Files that must change together with this one, such as the
  two sides of a wire format. The relation SHOULD be declared on both files.

### Concerns registry

Table: Registered `Concerns` values and what each implies for someone changing
the file.

| Value | Applies to | Implication for a change |
|---|---|---|
| `security-boundary` | Code that handles untrusted input, authentication, authorisation, or sandboxing | Review for attacker-controlled input; add negative tests |
| `concurrency` | Shared mutable state, locks, threads, or asynchronous callbacks | Check lock ordering and races; state assumptions as `Invariant` |
| `wire-format` | Bytes exchanged with another process or host | Preserve compatibility; update both ends (`Co-change`) |
| `persistent-format` | Data written to disk or a database | Preserve readability of existing data; consider a migration |
| `public-api` | Interface consumed by other systems or repositories | Treat signature changes as breaking; update `Ref`/`Spec` |
| `ffi` | Foreign-function boundaries | Check memory ownership, lifetimes, and type widths |
| `hot-path` | Performance-critical code | Measure before and after |

### Status registry

Table: Registered `Status` values.

| Value | Meaning |
|---|---|
| `experimental` | May change or disappear without notice; do not build on it elsewhere |
| `stable` | In normal use; changes follow the project's ordinary care |
| `deprecated` | Being retired; do not add new uses; follow the named replacement |

There is no `generated` status, because `Generated-by` already says so.

### Extension and change

- A label in the `local-label` form (`X-…`) is a local extension. The extractor
  ignores it silently and the map never shows it.
- Any other unregistered label produces a warning, never an error (§18).
- Adding a label, a `Concerns` value, or a `Status` value requires an accepted
  amendment to this specification and increments the minor part of its
  `schema-version`.

## Comment Syntax by Language

Table: Normative header comment forms for v1.

| File types | Prefix | Notes |
|---|---|---|
| Common Lisp, Scheme (`.lisp`, `.lsp`, `.cl`, `.scm`, `.ros`) | `;;;;` | The conventional Lisp file-header level |
| Emacs Lisp (`.el`) | `;;;` | Matches the Emacs library-header convention `;;; foo.el --- desc` |
| `#`-comment languages (shell, Python, Ruby, Perl, Makefile, YAML, TOML, Dockerfile) | `#` | |
| `//`-comment languages (C, C++, Rust, Go, Java, JavaScript, TypeScript, Zig) | `//` | Line comments only |
| `--`-comment languages (SQL, Lua, Haskell) | `--` | |
| Directory README (`README.md`) | `<!-- compass:header … -->` | See [Directory READMEs](#directory-readmes) |

The extractor maps file types by extension (and, for extension-less files, by
shebang or well-known name such as `Makefile`). Block comments (`/* … */`) are
not header blocks in v1.

Several languages already have a module-level documentation convention. The
extractor MAY read the same grammar from these locations instead. They are
non-normative in v1, and a file using one SHOULD NOT also carry a comment header.

Table: Non-normative module documentation locations.

| Language | Location |
|---|---|
| Python | The module docstring (PEP 257), first statement of the file |
| Rust | Inner doc comments `//!` at the top of a crate root or module file |
| Go | The package comment preceding `package` |

## Which Files Carry a Header

A file is **in scope** when all of the following hold:

1. it is tracked by Git;
2. its type appears in the normative comment-syntax table;
3. it matches no pattern in the manifest's `:map :exclude` list (for vendored or
   third-party code);
4. it is not exempt.

These files are **exempt**:

- ASDF system definitions (`.asd`), whose description comes from `:description`;
- Compass documents, which carry §7 front-matter instead;
- repository-root fixtures (§10: `README.md`, `LICENSE`, `CONTRIBUTING.md`, and
  the like);
- the toolchain's own generated outputs (`doc/INDEX.md`, `doc/CATALOG.md`,
  `doc/MAP.md`);
- files beneath a directory whose README declares `Generated-by`.

An in-scope file without a header is reported as a warning. Missing core fields
other than the summary line are not findings; they are counted in the coverage
summary that `compass map --check` prints.

## Directory READMEs

A directory README describes a directory both for people browsing the repository
on a forge, which displays it in the directory view, and for the source map. It
is OPTIONAL.

- It is a **fixture** in the sense of §10: it has no front-matter and no
  identifier, and does not take part in the identifier or federation system.
  A `README.md` inside the document directory (for example `doc/README.md`) is
  likewise a fixture and MUST be skipped by the Compass-document checks.
- Its **H1** names the directory. Its **first paragraph** is the directory's
  description; the map shows the first sentence of it.
- It MAY carry one `compass:header` block, which SHOULD immediately follow the
  first paragraph. The block contains a field block in the grammar above, with no
  summary line and no comment prefix. More than one block is an error.
- It SHOULD NOT enumerate the files in the directory. The map already does, and a
  hand-written list goes stale.
- The repository-root `README.md` MAY carry a `compass:header` block too. Its
  inheritable fields then apply to the whole repository.

Example:

```markdown
# Validation rules

One file per rule family; each rule declares its severity and the section it
enforces.

<!-- compass:header
Read-if: adding or changing a validation rule
Invariant: rules never call git directly; they use the git layer
Tests: tests/rules/
See: COMPASS-DRAFT-toolchain
-->
```

When a directory has no README, the map takes its description from the
`:description` of the ASDF system whose `:pathname` (or `.asd` location) is that
directory. Failing that, the directory has no description.

### Inheritance

A file's **effective header** combines its own fields with those of the READMEs
in every enclosing directory, up to the repository root.

Table: How each field propagates from a directory README to the files beneath it.

| Field | Propagation |
|---|---|
| `Invariant` | Accumulates: a file is bound by its own invariants and all enclosing ones |
| `Concerns` | Union of the file's values and all enclosing values |
| `Status` | Inherited; the nearest declaration wins, and a file's own value overrides |
| `Generated-by` | Inherited; every file beneath is generated and exempt from needing its own header |
| `Read-if`, `See`, `Tests`, `Co-change` | Not inherited; they describe the directory itself |

## The Source Map

The source map is produced by the toolchain (`compass map`) and committed as
`doc/MAP.md`, with a "generated — do not edit" banner. It is deterministic: the
same headers and READMEs always yield the same map, and no LLM takes part.

### Contents

- One section per directory that contains in-scope files, in path order, headed
  by the directory path and its description.
- For a directory that is an ASDF system's `:pathname` with `:serial t`, files
  are listed in load order and the section says so; otherwise, in name order.
- One entry per in-scope file: path, summary description, `Concerns` flags,
  `Status` when not `stable`, a generated marker when `Generated-by` is present,
  and the `Read-if` line.
- Files without a header appear with their path only, so the map is complete
  even where headers are not.

Example excerpt:

```markdown
## src/ — Toolchain sources (system `compass`, load order)

- `frontmatter.lisp` — Front-matter splitter, YAML parse, and strict typing
  Read-if: changing front-matter fields or their types
- `ledger.lisp` — Allocation ledger: read, verify, and append entries [persistent-format]
  Read-if: changing ID allocation, the ledger format, or renumbering

### src/rules/ — Validation rules

- `a11y.lisp` — Author-time accessibility rules (§12)
```

### Layers

The map is consumed in layers so that a session pays only for what it uses:

1. The **top level** (repository root, first-level directories, and ASDF
   systems, with descriptions only) is embedded in the session catalog
   (COMPASS-DRAFT-toolchain-D11).
2. The **full map** is `doc/MAP.md`, opened when the task needs it.
3. **`compass map PATH`** prints the map of one subtree.
4. **`compass map --file FILE`** prints a file's effective header, including
   inherited invariants and concerns.
5. **`compass map --json`** emits the same data for harness adapters.

### Refresh

The map changes when, and only when, a header, a directory README, or the set of
in-scope files changes (addition, removal, or rename). A code edit that does not
touch a header leaves the map unchanged. `compass map --check` regenerates the
map and fails if it differs from the committed file; it runs in the required CI
check alongside `compass check`. An optional pre-commit hook regenerates the map
so that the committed file is current before CI sees it.

## Validation Rules

Table: Validation rules for source headers, directory READMEs, and the map.

| Rule | Severity | Check |
|---|---|---|
| `header/present` | warning | An in-scope file has a header block |
| `header/placement` | warning | No summary-line pattern appears in a comment block after the first |
| `header/summary` | error | The summary line matches the grammar and names the file |
| `header/field-syntax` | error | Every line of the field block is a field line or a continuation |
| `header/cardinality` | error | Single-valued fields (`Read-if`, `Status`, `Generated-by`) appear at most once |
| `header/unknown-label` | warning | Every non-`X-` label is registered |
| `header/vocab` | error | `Concerns` and `Status` values are registered |
| `header/see-resolves` | error | Every `See` identifier resolves (as `ref/doc-resolves`; a provisional alias warns) |
| `header/path-exists` | error | `Tests`, `Co-change`, and `Generated-by` paths exist; `asdf:` test systems are defined |
| `header/co-change-symmetric` | warning | A `Co-change` target names this file in return |
| `header/deprecated-successor` | warning | A `deprecated` file has a `See` item or prose naming a replacement |
| `dir/header-syntax` | error | A README's `compass:header` block parses, and there is at most one |
| `map/current` | error | The committed `doc/MAP.md` matches what the extractor produces |

## Conformance Walkthrough

This walkthrough brings one existing file and its directory into conformance.
The file is `impulse-src/codec.lisp` from the Origin repository, whose current
header is descriptive prose. The `D`/`O` identifiers and the transport and test
paths below are illustrative.

1. **Write the summary line.** The current first line is `;;;; codec.lisp`
   alone, with the description on line 3. Merge them:
   `;;;; codec.lisp — Wire codec: hardened reader and validator for Impulse frames`.
2. **Add `Read-if`.** State when the file matters, not what it is: "changing the
   message grammar, framing, or anything that reads peer input".
3. **Lift invariants out of the prose.** The existing prose describes five layers
   of defence. Two of them are rules any editor must keep, so they become
   `Invariant` fields. The full explanation stays in the prose.
4. **Flag concerns and partners.** The file is a trust boundary and defines a
   wire format; its encoder counterpart lives elsewhere.
5. **Link tests and rationale.** Name the test file and the decision and open
   question behind the design.
6. **Keep the prose.** Everything after the field block is unchanged.

The result:

```lisp
;;;; codec.lisp — Wire codec: hardened reader and validator for Impulse frames
;;;;
;;;; Read-if: changing the message grammar, framing, or anything that reads peer input
;;;; Concerns: security-boundary, wire-format
;;;; Invariant: input is data, never code; *READ-EVAL* is NIL and VALIDATE-DATUM
;;;;   runs on every read
;;;; Invariant: frames are length-prefixed and byte-bounded
;;;; Co-change: impulse-src/transport.lisp
;;;; Tests: tests/codec-tests.lisp
;;;; See: ORIGIN-D30, ORIGIN-O9
;;;;
;;;; Impulse messages are S-expression data, never code. This file enforces
;;;; that at the boundary, with defense in depth:
;;;; …
```

7. **Optionally, describe the directory.** Add `impulse-src/README.md` with an H1,
   a one-paragraph description, and, if every file beneath shares a rule, a
   `compass:header` block carrying it as an `Invariant`.
8. **Regenerate and check.** Run `compass map`, review the diff to `doc/MAP.md`,
   and commit it with the header change. `compass map --check` then passes in CI.

The resulting map entry:

```markdown
- `codec.lisp` — Wire codec: hardened reader and validator for Impulse frames [security-boundary, wire-format]
  Read-if: changing the message grammar, framing, or anything that reads peer input
```

## Afterword: Limits

- **Faithful to headers, not to code.** Generation guarantees that the map
  matches the headers. It cannot guarantee that the headers match the code. A
  file can be rewritten while its header stays the same. Heuristics for
  detecting a stale header are an open question
  (COMPASS-DRAFT-toolchain-O6).
- **Judgment fields are unverifiable.** `Read-if` and `Invariant` are checked
  for form only. Their quality is a matter for review (`compass-review`) and for
  the author.
- **A new kind of governance.** This is the first Compass convention that lives
  inside source files rather than documents. The two registries (`Concerns`,
  `Status`) and the label set must be held to the same amendment discipline as
  the §4 and §6 vocabularies, or they will drift.
- **Migration cost.** The four ancestor repositories use four header forms.
  Classic and Lexis are closest (summary line already present). Origin needs its
  summary lines merged. Lexter's headers follow `(in-package …)` and must move
  up. Classic's `;;;` banner files need rewriting. None of this needs new
  content, only reshaping, but it touches many files.
- **Language coverage.** Only line-comment forms are normative. Block comments
  and module docstrings are recognised informally or not at all in v1.
- **Not API reference.** Symbol-level documentation remains ceded to declt,
  mgl-pax, and their peers (§2). The map tells a reader which file to open, not
  what each definition in it does.
- **No evidence yet.** Whether the map measurably improves agent behaviour is
  untested; see COMPASS-DRAFT-operator-memory-O6.
