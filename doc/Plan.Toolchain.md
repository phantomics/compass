---
id:            COMPASS-DRAFT-toolchain
title:         Compass Validation Toolchain
genre:         Plan
scope:         program
program:       Compass
component:     toolchain
language:      en
status:        Draft
authors:
  - Andrew Sengul
approved-by:   Andrew Sengul
reviewed:      2026-10-07
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-0001
  - COMPASS-DRAFT-authoring-assistance
  - COMPASS-DRAFT-operator-memory
  - COMPASS-DRAFT-source-headers
  - COMPASS-DRAFT-agent-workflow
  - COMPASS-DRAFT-agent-context-eval
  - COMPASS-DRAFT-semantic-binding
cites:
  - title:     ocicl README
    locator:   "Lisp Usage; ocicl Scope (Local-Only Mode)"
    external:  true
  - title:     PEP 1 — PEP Purpose and Guidelines
    locator:   "PEP Editor Responsibilities & Workflow"
    external:  true
  - title:     Django documentation — Migrations
    locator:   "Version control (conflicting migrations)"
    external:  true
  - title:     Rust RFCs process README
    locator:   "What the process is"
    external:  true
  - title:     Operator Memory repository (aerovato/operator-memory)
    locator:   "README.md; packages/core/src/preamble.ts:renderPreamble@e394f1c"
    external:  true
  - title:     SBCL User Manual
    locator:   "Saving a Core Image (save-lisp-and-die)"
    external:  true
  - title:     GitHub Docs — Using artifact attestations
    locator:   "Generating build provenance for binaries"
    external:  true
  - title:     ocicl repository (ocicl/ocicl)
    locator:   ".github/workflows/ci.yaml; ocicl.asd (program-op build)"
    external:  true
decisions:
  - COMPASS-DRAFT-toolchain-D1
  - COMPASS-DRAFT-toolchain-D2
  - COMPASS-DRAFT-toolchain-D3
  - COMPASS-DRAFT-toolchain-D4
  - COMPASS-DRAFT-toolchain-D5
  - COMPASS-DRAFT-toolchain-D6
  - COMPASS-DRAFT-toolchain-D7
  - COMPASS-DRAFT-toolchain-D8
  - COMPASS-DRAFT-toolchain-D9
  - COMPASS-DRAFT-toolchain-D10
  - COMPASS-DRAFT-toolchain-D11
  - COMPASS-DRAFT-toolchain-D12
  - COMPASS-DRAFT-toolchain-D13
  - COMPASS-DRAFT-toolchain-D14
  - COMPASS-DRAFT-toolchain-D15
  - COMPASS-DRAFT-toolchain-D16
  - COMPASS-DRAFT-toolchain-D17
  - COMPASS-DRAFT-toolchain-D18
  - COMPASS-DRAFT-toolchain-D19
  - COMPASS-DRAFT-toolchain-D20
  - COMPASS-DRAFT-toolchain-D21
  - COMPASS-DRAFT-toolchain-D22
  - COMPASS-DRAFT-toolchain-D23
  - COMPASS-DRAFT-toolchain-D24
  - COMPASS-DRAFT-toolchain-D25
  - COMPASS-DRAFT-toolchain-D26
  - COMPASS-DRAFT-toolchain-D27
  - COMPASS-DRAFT-toolchain-D28
  - COMPASS-DRAFT-toolchain-D29
open-questions:
  - COMPASS-DRAFT-toolchain-O1
  - COMPASS-DRAFT-toolchain-O2
  - COMPASS-DRAFT-toolchain-O3
  - COMPASS-DRAFT-toolchain-O4
  - COMPASS-DRAFT-toolchain-O5
  - COMPASS-DRAFT-toolchain-O6
  - COMPASS-DRAFT-toolchain-O7
---

# Compass Validation Toolchain: Development Plan

This plan covers the deterministic toolchain that `Compass.md` §22 describes and
§23 tracks as S1. The toolchain validates documents and corpora, hands out
identifiers that are guaranteed unique, and generates the namespace and
federated indexes. It will be a Common Lisp program. It builds under both
Quicklisp, which is in use today, and ocicl, the intended long-term dependency
manager. It assumes the standard
([COMPASS-0001](../Compass.md)) and the authoring-assistance layer
([COMPASS-DRAFT-authoring-assistance](Plan.AuthoringAssistance.md)). The skills
in that layer currently run in advisory-only mode for lack of this toolchain
(COMPASS-D2).

The plan also covers the toolchain outputs that give coding agents project
context: a session catalog, an authority ranking, and a source map. These
resolve open questions O1–O3 of
[COMPASS-DRAFT-operator-memory](Survey.OperatorMemory.md), and the source map
implements [COMPASS-DRAFT-source-headers](Spec.SourceHeaders.md).

## Problem

Conformance is currently upheld only by convention and editorial review (§13,
§22). The standard says it plainly: "an unenforced standard drifts." The
§22 checks need a program to run them: front-matter schema, controlled
vocabularies, identity, reference integrity, Git-derived fields, and author-time
accessibility.

The hardest of these requirements is **identity**. §5 and §13 require that every
`<NAMESPACE>-<NNNN>` identifier be allocated once and never reused. §8 gives the
same property to `<NAMESPACE>-D<n>` and `<NAMESPACE>-O<n>` register entries.
Serial numbers break under parallel work. Two contributors on separate branches
will both compute "the next number is 0007," and nothing in the standard today
detects the collision. Concurrency control does not exist inside a single
working copy, so no tool that runs on one machine can guarantee uniqueness by
itself. The guarantee has to be anchored at a point where all allocations are
put in sequence.

Writing the toolchain's requirements down also exposes defects in the standard
itself, recorded as decisions below:

- §6's `status: Superseded-by: <id>` is not valid YAML. The `: ` inside the
  value is parsed as a mapping.
- §13 defines provisional identifiers for documents, but none for `D`/`O`
  records.
- The format and contents of the §13 registry are unspecified.
- There is no file that declares which repository owns a namespace, and no
  federation manifest.
- Two of the §12 accessibility rules, table captions and diagram long
  descriptions, have no Markdown syntax, so they cannot be checked.

A separate problem is **delivery to agents**. The Operator Memory survey found
that Compass "is a content model with almost no delivery mechanism": an agent
consults the corpus only if it already suspects what is there, and it enters the
source tree with no map. The index the toolchain will generate is the natural
starting point, but it lists every document, carries no routing information, and
cannot tell current truth from history. Writing down the agent-facing outputs
exposes further gaps in the standard:

- §6 assigns no status vocabulary to `Glossary` or `Ideation`.
- A register entry's status and its host document's status can disagree, and
  nothing says which one governs. COMPASS-D1–D4 are `Accepted` inside a `Draft`
  Plan.
- The plan's strict front-matter typing says nothing about keys it does not
  recognise, although §18 requires extensions to degrade gracefully.

## Goals

- Implement the §22 conformance checks as named, individually testable rules.
  A MUST violation is an error and a SHOULD violation is a warning. Output is a
  human-readable report plus JSON.
- **Guarantee** that canonical identifiers and register numbers are unique. The
  guarantee should rest on mechanisms that hold however carefully contributors
  behave, and be proven by tests that simulate concurrent allocation.
- Make provisional-to-canonical assignment a single command, so that §13's
  "steward assigns at merge" is no longer a manual step (§23 O6).
- Generate the per-namespace index and the federated `compass/INDEX.md` from
  front-matter and the ledger. They are never hand-maintained (§13).
- Derive `authors`/`created`/`updated` from Git, honouring `.mailmap`, and
  verify commit-pinned code references (§7, §9).
- Ship a standalone executable and a GitHub Actions check. Build reproducibly
  under **both Quicklisp and ocicl**.
- Make the toolchain usable by projects in any language, with no Lisp
  installation: downloadable binaries for the common platforms, a setup action
  for CI, and a container image (COMPASS-DRAFT-toolchain-D19).
- Make the front-end reusable by the future Markdown→Lexis importer (S2, §16).
- Let the authoring-assistance skills call the toolchain instead of guessing,
  which lifts COMPASS-D2.
- Generate a compact, size-bounded, authority-ranked **session catalog** and a
  per-file **source map** as committed files, so that a harness adapter can put
  them in front of an agent without running the toolchain.

## Settled Decisions

All decisions are **Proposed** until this Plan is accepted. They use the
provisional register form that COMPASS-DRAFT-toolchain-D2 defines, and so serve
as its first worked example.

### COMPASS-DRAFT-toolchain-D1 — Merge-time ledger plus required CI as the uniqueness authority

**Status:** Accepted

**Context:** Uniqueness needs a single point where allocations are put in
sequence, one per namespace. A Git-based corpus has two candidates: (A) the
protected main branch, with numbers assigned at merge as §13 already specifies,
or (B) an atomic compare-and-swap on the remote, which reserves a number
eagerly by pushing to a dedicated ref. Git rejects pushes that are not
fast-forwards, which makes such a push atomic.

**Decision:** Adopt (A). Every canonical identifier and register number must
appear in its namespace's append-only ledger
(COMPASS-DRAFT-toolchain-D3). Any change that introduces one must therefore
append to the ledger. Two branches that both append to the end of the same file
always produce a textual merge conflict, so concurrent allocations cannot merge
silently. A required `compass check` on the pull request's merge result covers
the remaining case, where a person resolves the conflict by keeping both lines:
the check then fails on the duplicate. Diffing the ledger against the base
revision enforces "never reused." The required repository settings are listed
under [The uniqueness guarantee](#the-uniqueness-guarantee).

**Alternatives:**
- (B) eager CAS reservation gives citable IDs before merge, but needs network
  access and push rights for every author and leaves gaps when drafts are
  abandoned. It is deferred, not rejected: a `compass reserve` command can be
  added later on the same ledger.
- Forge-assigned numbers, using the PR or issue number as the ID as Rust RFCs
  and Kubernetes KEPs do, were rejected. They tie identity to one forge, are not
  contiguous per namespace, and cannot survive the Tier-2 migration (§16).
- Hash or UUID identifiers were rejected because §5 wants short, human-citable
  serial numbers.

### COMPASS-DRAFT-toolchain-D2 — Provisional identifiers for register entries

**Status:** Accepted

**Context:** §13 gives documents a provisional `<NS>-DRAFT-<slug>` that needs no
coordination. `D`/`O` records have no equivalent, yet they are numbered across
the whole namespace and collide in exactly the same way.

**Decision:** A register entry in an unassigned document is written
`<NS>-DRAFT-<slug>-D<n>` or `<NS>-DRAFT-<slug>-O<n>`, where `<n>` counts within
that document. The slug grammar is `[a-z0-9]+(-[a-z0-9]+)*`, lowercase only,
which keeps the uppercase `-D`/`-O` suffix unambiguous. `compass assign` gives
the document its canonical number and each of its provisional register entries a
canonical `<NS>-D<n>`/`<NS>-O<n>`, in a single operation. Amends §8 and §13.
The same form applies to memo records (`<NS>-DRAFT-<slug>-M<n>`, assigned
`<NS>-M<n>`) introduced by COMPASS-DRAFT-agent-workflow-D2.

**Alternatives:**
- Allocate canonical `D`/`O` numbers while writing. Rejected: it reintroduces
  the collision.
- Scope register IDs permanently to their document (e.g. `ORIGIN-0012-D3`).
  This would remove namespace-wide register allocation entirely. Rejected for
  now because it is a breaking (major) amendment to §8 and changes existing
  citations such as `PSYCHE-D16`. It remains a candidate if register volume
  makes merge-time conflicts burdensome.

### COMPASS-DRAFT-toolchain-D3 — The allocation ledger holds immutable facts only

**Status:** Accepted

**Context:** §13 says the registry lists "every allocated identifier with its
current title, genre, scope, and status." All of those values except the
identifier already live in front-matter and change over time. Copying them into
the registry creates a second source of truth that will drift, and it produces
spurious merge conflicts whenever a status changes.

**Decision:** Each namespace keeps a ledger at `doc/REGISTRY.sexp`. It is
append-only, with one s-expression per line, and records only facts fixed at
allocation time: identifier, kind, provisional alias, original path, host
document (for register entries), date, and allocator. Current title, genre,
scope, and status stay in front-matter. The generated `INDEX.md` joins the two
(COMPASS-DRAFT-toolchain-D6). The provisional alias lets old `DRAFT` references
resolve, with a warning, so none ever dangles. Amends §13.

**Alternatives:**
- A ledger in YAML or CSV. Rejected: s-expressions read with the toolchain's
  restricted reader, as described under
  [The ledger and manifest](#the-ledger-and-manifest), and one-entry-per-line
  works in any format.
- No ledger, deriving the set of taken numbers by scanning front-matter.
  Rejected: without a shared file there is no textual conflict point, and
  numbers belonging to deleted documents could be reused.
- A registry with the mutable fields included, as §13 currently says. Rejected
  for the drift and conflict reasons above.

### COMPASS-DRAFT-toolchain-D4 — A project manifest declares namespace ownership and federation

**Status:** Accepted

**Context:** A namespace must be minted by exactly one repository (§5, §13). The
validator, `compass-lookup`, and the future site build (S8) all need a list of
the repositories that take part in a federation. Neither fact is written down
anywhere.

**Decision:** Each repository has a `compass.sexp` at its root. It declares the
namespaces the repository owns, its document directory, and optionally the local
paths of federated repositories. The validator rejects any ledger entry whose
namespace the repository does not own. Federation-level checks, such as two
repositories claiming one namespace or cross-namespace references, run when the
federation paths are available. `compass manifest --json` exports the same data
for non-Lisp consumers (the S8 Astro build, the skills).

**Alternatives:**
- Put the declaration in YAML. Rejected for consistency with the ledger, at no
  loss to other consumers thanks to the JSON export.
- Infer ownership from the namespaces in use. Rejected: inference is exactly
  what lets two repositories mint the same namespace.

### COMPASS-DRAFT-toolchain-D5 — Supersession uses a plain status plus the existing field

**Status:** Accepted

**Context:** `status: Superseded-by: PSYCHE-0002` fails to parse as YAML
("mapping values are not allowed here"). This was confirmed against a
conforming YAML parser. Any document that follows §6 literally cannot be read.

**Decision:** The status value becomes `Superseded`, and the successor is named
in the existing `superseded-by:` front-matter field. The validator requires the
two to agree: `Superseded` requires `superseded-by`, and `superseded-by`
requires `Superseded`. Amends §6 and §7. This is a breaking change, but no
conforming documents that use the old form exist yet.

**Alternatives:**
- Require quoting (`status: 'Superseded-by: X'`). Rejected: forgetting the
  quotes is too easy, the failure is a parse error rather than a validation
  finding, and the successor ID would be duplicated across two fields.
- `Superseded-by-<id>` as a single token. Rejected: it pushes free text into a
  controlled vocabulary.

### COMPASS-DRAFT-toolchain-D6 — Checkable conventions for §12, and generated indexes

**Status:** Accepted

**Context:** §12 requires a caption for every table and a text-equivalent long
description for every diagram. Markdown has no syntax for either, so a validator
cannot check the rules and an author cannot satisfy them unambiguously.

**Decision:**
- **Table caption:** a paragraph of the form `Table: <caption>` immediately
  before the table. This follows the pandoc convention.
- **Diagram long description:** a diagram is a fenced block tagged `mermaid`,
  `plantuml`, `dot`, `graphviz`, or `lexis`. It must be followed by a paragraph
  beginning `Description:`.
- **Images:** `![alt](…)` must have non-empty alt text.
- **Inline language spans:** not checked in v1.
- **Indexes:** each namespace's `INDEX.md` and the federated `compass/INDEX.md`
  are generated, carry a "generated — do not edit" banner, and are verified by
  `compass index --check` so that hand edits are detected.

Amends §11, §12, and §13.

**Alternatives:**
- HTML `<table><caption>`. Rejected: it gives up plain Markdown.
- Treat these rules as unenforceable. Rejected: they are MUST rules.

### COMPASS-DRAFT-toolchain-D7 — Common Lisp, with purpose-built parsers

**Status:** Accepted

**Context:** §22 intends a Common Lisp toolchain that shares its parsing front
end with the Markdown→Lexis importer (S2). Findings must cite line numbers.
3bmd, the obvious full Markdown parser, does not record source positions.

**Decision:**
- The program is a Common Lisp ASDF system for SBCL.
- Front-matter is parsed by the strict YAML-subset parser of
  COMPASS-DRAFT-toolchain-D18 and then type-checked against the field schema.
- The body is read by a line-oriented scanner written for this project. It
  produces headings, tables with their caption lines, fenced code, links,
  images, inline code, and HTML comments, each with its line number.
- A full CommonMark tree is left to S2, which extends this scanner rather than
  replacing it.

**Alternatives:**
- 3bmd. Rejected: no source positions, and a dependency on esrap.
- `cl-yaml` (libyaml through CFFI) for front-matter. Rejected by
  COMPASS-DRAFT-toolchain-D18.

### COMPASS-DRAFT-toolchain-D8 — Manager-agnostic system, first-class on both Quicklisp and ocicl

**Status:** Accepted

**Context:** Quicklisp is what is used today: `~/.sbclrc` loads it, and its
installed dist is 2023-06-18. ocicl is the way forward. It gives project-local
dependencies pinned in an `ocicl.csv` lockfile by OCI digest, sigstore-verified
artifacts, and an `OCICL_LOCAL_ONLY` mode intended for reproducible CI. The
uniqueness guarantee rests on a CI check (COMPASS-DRAFT-toolchain-D1), so that
check must run on dependencies that are pinned exactly.

**Decision:** `compass.asd` names only ASDF dependencies. It does not refer to
either manager, and runs unchanged under both. Dependencies are limited to
systems available in *both* ecosystems; their availability is listed under
[Dependency management](#dependency-management-quicklisp-and-ocicl).
`cl-hamcrest` is available only from Quicklisp, so tests use plain FiveAM.
CI runs a required matrix covering both managers. The ocicl job is the pinned,
reproducible build, and the Quicklisp job proves the system still works on the
dist in current use.

**Alternatives:**
- Quicklisp only. Rejected: it postpones the move the project intends to make.
- ocicl only. Rejected: it would break the working setup today.
- Keep `cl-hamcrest` by installing it into ocicl from a pinned Git source
  (`ocicl install git+URL@SHA`). Deferred: the locally installed ocicl, v2.6.6,
  predates `git+` sources, and the dependency is a convenience rather than a
  necessity.

### COMPASS-DRAFT-toolchain-D9 — Bootstrapping the COMPASS namespace

**Status:** Accepted

**Context:** The COMPASS namespace has no ledger. `Compass.md` has no
front-matter. The authoring-assistance Plan already uses canonical-looking
`COMPASS-D1`–`D4` and `COMPASS-O1`–`O3` that were never allocated. The §23
tables label rows `D1`–`D8` and `O1`–`O6`, which look like COMPASS register IDs
and would confuse lookup.

**Decision:** The first ledger records:
1. `COMPASS-0001` for `Compass.md`, which gains front-matter in the same change.
2. The existing `COMPASS-D1`–`D4` and `COMPASS-O1`–`O3` from
   [COMPASS-DRAFT-authoring-assistance](Plan.AuthoringAssistance.md), kept with
   their current numbers rather than renumbered.

After those entries, normal allocation applies, so this Plan's provisional IDs
are assigned on merge. The §23 row labels are renamed to prefixes that cannot be
read as register IDs (e.g. `ND1` for "non-goal by design", `GO1` for "genuinely
open").

**Alternatives:** Convert the authoring-assistance register entries to
provisional form and assign them normally. This is equally valid and purer, but
it rewrites citations already made from `skills/compass-derive/SKILL.md`.

### COMPASS-DRAFT-toolchain-D10 — Agent-context outputs are generated and committed

**Status:** Accepted

**Context:** The Operator Memory survey (COMPASS-DRAFT-operator-memory-O1)
resolved to import the useful parts of Operator Memory into Compass rather than
run the two systems side by side, which would let two models of project truth
diverge. Its delivery idea, a catalog injected at session start, needs a
concrete artifact. A harness adapter can either read a committed file or run the
toolchain at session start.

**Decision:** The toolchain generates three files into the namespace's document
directory and they are committed:
- `doc/INDEX.md`: the full namespace index (D6);
- `doc/CATALOG.md`: the session catalog (D11);
- `doc/MAP.md`: the source map (D14).

Each carries a "generated — do not edit" banner and has a `--check` mode that
regenerates it and fails on any difference. The checks run in the required CI
check. An optional pre-commit hook regenerates all three. The validator
recognises these files, and any `README.md` in the document directory, as
non-documents and skips the Compass-document rules for them. The catalog also
carries a digest of its inputs, so an adapter can tell whether it is stale
without running Lisp.

**Alternatives:**
- Generate at session start. Rejected: every session would need the binary
  (COMPASS-DRAFT-toolchain-D19), and session start would wait on Git.
- Generate inside each harness adapter. Rejected: a second implementation of the
  catalog logic would drift from the toolchain's.
- Run Operator Memory alongside Compass. Rejected by the survey (O1): two
  parallel models of project truth.

### COMPASS-DRAFT-toolchain-D11 — Catalog contents, scope, and budget

**Status:** Accepted

**Context:** An agent "can't search for what it doesn't know," so it needs a
compact list of what exists. Injecting every document, or even every index
entry, is unaffordable: some documents are large, and a federation is larger
still. COMPASS-DRAFT-operator-memory-O2 settled the entry fields and the
exclusion of non-current documents.

**Decision:** `compass catalog` writes `doc/CATALOG.md` (and `--json` the same
data), containing, in order:
1. a short fixed preamble: how to read the catalog, the weight legend (D12), and
   how to fetch more (`compass show ID#anchor`, `compass outline ID`);
2. the project commands from the manifest, if any (D15);
3. the top level of the source map (D14);
4. **Documents**, grouped by weight. Each entry gives the id, title, genre (with
   subtype), status, component, size, and the `read-if:` line if present;
5. **Accepted decisions**: one line per `D`-record of weight Authoritative,
   giving its id, title, and host document;
6. **Memos**: one line per M-record of weight Authoritative
   (COMPASS-DRAFT-agent-workflow-D4), giving its id, title, and `**Read-if:**`
   line. Memo host documents are not listed as documents.
7. **Unreviewed memos**: the same, for M-records of weight Provisional, under a
   heading that marks them as not yet reviewed
   (COMPASS-DRAFT-agent-workflow-D11). They are ordered last, so they are the
   first entries dropped when the budget is exceeded.

Scope and filtering:
- The catalog covers the repository's own namespaces, plus federated documents
  **one hop out**: those a local document names in `relates-to`, `supersedes`,
  `superseded-by`, `decisions`, a document link, or a source-header `See:` field.
- Documents of weight **Excluded** are left out. Provisional documents are kept
  and marked as such.
- The catalog lists metadata only. Bodies are never included; the size field
  tells the agent what opening a document costs.

Budget:
- The default budget is 8 KB, configurable in the manifest (D15).
- Entries are ordered by weight, then local before federated, then most recently
  updated. When the budget is exceeded, entries are dropped from the end, a
  "*n* more; run `compass catalog --all`" line is added, and the toolchain warns
  (`catalog/budget`).

**Alternatives:**
- Inject the full index. Rejected: unbounded, and it mixes current truth with
  history.
- Include document abstracts. Rejected for v1: the cost per entry roughly
  triples. `read-if:` carries the routing information more cheaply.
- Scope by the components named in the task. Deferred: the catalog is committed,
  so it cannot know the task. An adapter may filter the JSON form further.

### COMPASS-DRAFT-toolchain-D12 — Authority weight is derived from genre and status

**Status:** Accepted

**Context:** The blog post behind Operator Memory complains that "the past is
treated as truth." Operator Memory solves this by deleting the past. Compass
keeps history but needs to tell an agent how much each document counts for
current behaviour. The survey sketched a ranking. Making it computable exposes
the §6 gaps listed under [Problem](#problem).

**Decision:** Every document, `D`-record, and M-record
(COMPASS-DRAFT-agent-workflow-D2) has a derived **weight**: one of
Authoritative, Directive, Contextual, Provisional, or Excluded, defined in
[Authority weight](#authority-weight). Weight is computed, never written in
front-matter. Two rules close the §6 gaps:
- **Status sets for Glossary and Ideation.** `Glossary` uses the reference-genre
  statuses (`Current`, `Draft`, `Deprecated`). `Ideation` uses the
  proposal-and-record statuses. Amends §6 (patch).
- **Register entries.** A `D`- or M-record's weight comes from its own
  `**Status:**`.
  Its host document's *lifecycle* then caps it: if the host is Provisional, the
  record is at most Provisional, and if the host is Excluded, so is the record.
  The host's *genre* does not cap it, so a decision recorded in an `Accepted`
  `Log` or an `Implemented` `Plan` remains Authoritative. Amends §8.

The body scanner extracts each record's `**Status:**` line, and the rule
`register/status` requires one. The weight function lives with the
vocabularies, and the test that keeps them in step with
`skills/reference/vocabularies.md` covers it too.

**Alternatives:**
- A record's weight as the lower of its own and its host's weight. Rejected:
  decisions in Logs and implemented Plans would rank as mere context.
- An explicit `weight:` front-matter field. Rejected: it would duplicate what
  genre and status already say, and drift from them.

### COMPASS-DRAFT-toolchain-D13 — Unknown front-matter keys warn; `read-if:` is a registered extension

**Status:** Accepted

**Context:** Routing by condition ("read if changing the ledger format") serves
an agent better than routing by topic. The survey proposed a `read-if:` key,
introduced as a §18 extension first. The plan's `fm/types` rule types the core
fields strictly but does not say what happens to other keys.

**Decision:**
- A front-matter key that is neither core nor a registered extension produces a
  warning (`fm/unknown-key`), never an error, as §18's graceful-degradation rule
  requires.
- Registered extension keys are type-checked like core keys. The registry lives
  with the vocabularies.
- `read-if:` is registered as the first extension. Its value is a single-line
  string that should stay within 160 characters (`fm/read-if`, warning). Its
  CLOS slot is `read-if`, and its RDF predicate is `compass:readIf`.
- Promoting `read-if:` to a core optional field is a later minor amendment to §7,
  if it proves its worth.

**Alternatives:**
- Reject unknown keys. Rejected: it contradicts §18 and breaks every corpus that
  adopts an extension before the validator knows about it.
- Accept unknown keys silently. Rejected: typos such as `relates_to` would pass
  unnoticed.

### COMPASS-DRAFT-toolchain-D14 — The source map is extracted from source headers

**Status:** Accepted

**Context:** A repository documented with Compass still sends its agent into the
source cold. Operator Memory's answer is an agent-maintained index, which is
neither deterministic nor checked. COMPASS-DRAFT-operator-memory-O3 resolved
that a per-file map is in scope, that symbol-level API reference stays ceded
(§2), and that the map must be generated by a deterministic tool from a
standard header comment in each source file. The ancestor repositories already
open most files with a descriptive comment, in four different forms.

**Decision:** Implement [COMPASS-DRAFT-source-headers](Spec.SourceHeaders.md):
- an extractor per comment family (Lisp first), which reads only the header
  block of each file and the `compass:header` block of each directory README;
- `compass map`, which writes `doc/MAP.md` (D10), with `PATH`, `--file`,
  `--json`, and `--check` variants;
- directory descriptions taken from directory READMEs, falling back to ASDF
  `:description`, and Lisp load order taken from ASDF `:serial` components;
- the Spec's `header/*`, `dir/*`, and `map/current` rules.

The extractor needs no Git access and no full parse, so it stays fast. Amends §2
(patch) to state that a per-file navigation map is in scope while symbol-level
API reference remains ceded.

**Alternatives:**
- An agent-maintained index, as in Operator Memory. Rejected: the map is
  derivable, so generating it deterministically costs nothing and cannot drift
  from its inputs.
- Symbol-level generation in the manner of declt. Rejected: ceded by §2, and too
  large to deliver to an agent.
- YAML front-matter in source files. Rejected: easily confused with §7, and every
  language would need a YAML-aware extractor.

### COMPASS-DRAFT-toolchain-D15 — Manifest keys for commands, map, catalog, and stewards

**Status:** Accepted

**Context:** After the catalog itself, the facts agents need most often are how
to build and test a project. In Operator Memory they live in prose instructions.
Many Common Lisp projects have no shell command topology at all: they are built
and tested from the REPL. The map and catalog also need per-repository settings.
Solo-steward approval (COMPASS-DRAFT-agent-workflow-D6) needs each namespace's
steward and approval mode written down where the validator can read them.

**Decision:** The project manifest (D4) gains four optional keys:
- `:commands`: a list of named commands. Each is `:shell` (a command line) or
  `:repl` (a form to evaluate), with an optional `:doc`. The catalog lists them.
- `:map`: `:exclude`, a list of glob patterns for vendored or third-party code.
- `:catalog`: `:budget`, in bytes (default 8192).
- `:stewards`: one entry per owned namespace, giving `:steward` (the identity as
  it appears in `authors` and `approved-by`, canonicalised through `.mailmap`)
  and `:approval`, either `:second-reviewer` (the default, the §6 rule) or
  `:solo`. The rule `review/approver` reads it.

All four fit the restricted reader of [The ledger and manifest](#the-ledger-and-manifest)
without change; `:approval` takes keywords rather than `t` for that reason.

**Alternatives:**
- Commands as prose in `AGENTS.md`. Rejected: unchecked, and not reachable by
  the catalog generator.
- Shell commands only. Rejected: most of the federation's projects are
  REPL-driven.

### COMPASS-DRAFT-toolchain-D16 — Register record headings carry the full identifier

**Status:** Accepted

**Context:** The register scanner finds `D`, `O`, and M records by their
headings, so the heading form must be unambiguous. The corpus uses three forms.
§8's example uses a short form (`### D16 — …`), which names no namespace. This
Plan, COMPASS-DRAFT-agent-workflow, and the genre templates use the full
identifier (`### COMPASS-DRAFT-toolchain-D1 — …`). COMPASS-DRAFT-authoring-assistance
mixes the two, with short decision headings and full open-question headings. A
short heading cannot express a provisional identifier, cannot be found by a
corpus-wide search for its identifier, and leaves the scanner to guess the
namespace from the host.

**Decision:** A register record heading MUST be an H3 of the form
`### <ID> — <title>`, where `<ID>` is the record's full canonical or provisional
identifier and the separator is an em dash. The scanner recognises the short
form `### D<n> — …` / `### O<n> — …` only to report it (`register/heading-form`,
warning), and reads it as `<host namespace>-D<n>` meanwhile. Amends §8 (minor):
the §8 example changes to the full form. The headings of
COMPASS-DRAFT-authoring-assistance are corrected in the same change as this
decision.

**Alternatives:**
- Allow both forms permanently. Rejected: two forms double the scanner's
  grammar and the reviewer's burden, and only one works for provisional IDs.
- Require the short form, deriving the namespace from the host. Rejected: it
  breaks grep-based lookup and federated citation.

### COMPASS-DRAFT-toolchain-D17 — RDF export implements the semantic binding

**Status:** Proposed

**Context:** §7 and §17 promise that every front-matter field maps to an RDF
predicate and that a corpus can feed a triplestore, but the mapping they give
is incomplete, disagrees with the predicates Classic actually uses, and
provides no identity rule that yields valid IRIs.
[COMPASS-DRAFT-semantic-binding](Spec.SemanticBinding.md) now specifies the
binding: the `compass:` vocabulary under `https://w3id.org/compass/vocab#`,
`tag:` IRIs minted from a per-namespace authority, the mapping of front-matter,
registers, body structure, and source headers, and SHACL shapes. SPARQL over a
corpus, and later ingestion by Classic and a Classic-based forge, depend on a
toolchain that produces it.

**Decision:**
- `compass export --rdf FORMAT` writes the binding's triples, with N-Triples
  and Turtle required and N-Quads, TriG, and JSON-LD to follow. Output is
  deterministic and contains no blank nodes. `--derived`, `--history`,
  `--with-text`, and `--federation` are opt-ins, as the Spec defines.
- The exporter writes RDF text directly from the model; it needs no RDF library,
  and adds no dependency to the check path.
- The project manifest gains a key, `:authorities`, giving each owned
  namespace's RFC 4151 tagging authority. A new rule, `manifest/authority`
  (warning in `check`), reports a namespace without one; `export` refuses to run
  for it.
- The vocabulary file, the JSON-LD context, and the SHACL shapes are generated
  from the toolchain's vocabulary data (`compass export --vocab`), so the shapes
  cannot drift from the validator.
- Delivered in baseline v0.3, after v0.2, because identity needs the manifest
  and provisional aliases need the ledger.

**Alternatives:**
- Generate RDF through an RDF library (for example cl-rdfxml or a SPARQL client).
  Rejected for the exporter: serialising N-Triples and Turtle from a known model
  is simple, and the dependency would buy nothing. A library may still be used
  in tests to parse the output.
- Export JSON only and leave RDF to consumers. Rejected: each consumer would
  reinvent the mapping and the identity rule, which is the drift the Spec exists
  to prevent.
- Defer the export until Classic can ingest it. Rejected: any SPARQL store can
  use the export now, and Classic is one consumer among several.

### COMPASS-DRAFT-toolchain-D18 — A strict YAML-subset parser written in Lisp

**Status:** Proposed

**Context:** COMPASS-DRAFT-toolchain-O1 weighed `cl-yaml`, which parses full
YAML 1.1 through the native libyaml library, against a parser for only the YAML
that Compass front-matter uses. Three findings settle it:
- **The subset is small.** A survey of every front-matter block in this
  repository (documents, templates, and skills; 21 files) found only block
  mappings, one level of nested mapping, block sequences, sequences of
  mappings, double-quoted scalars, and trailing comments. There were no flow
  mappings, block scalars, anchors, aliases, or tags.
- **YAML 1.1 typing works against the validator.** It reads `language: no` as
  the boolean false and `schema-version: 0.10` as the number 0.1. The validator
  must then reject values it never wanted converted.
- **The native parser is a liability.** In CI the toolchain reads pull
  requests, including ones from forks. libyaml exposes a native parsing surface
  to that input ([COMPASS-DRAFT-secure-development](Survey.SecureDevelopment.md)).
  It also makes every binary depend on a shared library that must be bundled or
  installed on each platform (COMPASS-DRAFT-toolchain-D19).

**Decision:** Front-matter is parsed by a parser written for the toolchain, in
Lisp. It accepts:
- a top-level block mapping, with mappings nested to any depth that the field
  schema allows;
- block sequences of scalars or of mappings, and single-line flow sequences of
  scalars;
- plain, single-quoted, and double-quoted scalars;
- `#` comments, and the null forms `~`, `null`, and an empty value.

**Every scalar is kept as a string.** Types come from the field schema
(see [Front-matter types](#front-matter-types)), so YAML 1.1's conversions
cannot occur.

The parser reports anything else as an error with a line and column. That
includes tab indentation, duplicate keys, anchors, aliases, tags, block
scalars, flow mappings, explicit `?` keys, and multiple documents, and also
`: ` inside a plain scalar, as YAML itself does. Every value keeps its source
position, so `fm/types` can report each finding at the value it concerns.

Front-matter that uses YAML beyond the subset is non-conforming. Other YAML
consumers, such as the S8 Astro collections, accept a superset, so every
conforming document remains readable by them.

Resolves COMPASS-DRAFT-toolchain-O1. Amends §7 (minor) to state the subset.

**Alternatives:**
- `cl-yaml` with strict type checks (the original D7). Rejected for the native
  dependency, the parsing surface, and conversions that must then be undone.
- Both, with `cl-yaml` as an optional backend. Rejected: two parsers would
  disagree on edge cases, and the subset is the conformance definition either
  way.

### COMPASS-DRAFT-toolchain-D19 — Portable binary distribution

**Status:** Proposed

**Context:** Compass is meant for projects in any language. A project that is
not written in Lisp should be able to run `compass check` without installing a
Lisp, a dependency manager, or this repository. SBCL can save a complete image
as a standalone executable. ocicl is built this way and is distributed as Linux
packages, a Homebrew formula, and MacPorts. Its CI builds and tests on Linux,
macOS, and Windows. Measured locally, the ocicl executable needs only the C
library and its companions (`libc`, `libm`, `libdl`, `libpthread`) and answers
`ocicl version` in about 20 ms. SBCL cannot cross-compile, so each platform has
to be built on its own runner.

**Decision:**

Each release tag builds a standalone executable per target:

Table: Release targets for the `compass` executable.

| Target | Build environment | Note |
|---|---|---|
| Linux x86-64 (glibc) | A container with an old glibc, such as Debian 11 (glibc 2.31) or AlmaLinux 8 (2.28) | A binary runs on glibc versions at or after the one it was built against, so building on a current Ubuntu runner would exclude Debian 11 and RHEL 8 |
| Linux arm64 (glibc) | An arm64 runner, using the same container | |
| macOS arm64 | A macOS 14 or later runner | Intel macOS is optional |
| Windows x86-64 | A Windows runner | |

Each target job:
- builds the executable with `asdf:make`;
- runs the test suite;
- runs `compass check` on this repository using the executable it just built,
  not the development image;
- uploads an archive (`.tar.gz`, or `.zip` for Windows).

The release publishes the archives with a `SHA256SUMS` file and a GitHub build
provenance attestation for each archive.

Three distribution channels serve projects that are not written in Lisp, in
order of priority:
1. **A setup action** in this repository (`setup/action.yml`). It downloads the
   archive for the runner's platform at a version the caller pins and verifies
   it against `SHA256SUMS`. This answers COMPASS-DRAFT-toolchain-O2 for GitHub
   CI.
2. **A container image** on the GitHub container registry, built on a slim
   Debian base. It covers GitLab and other CI systems, musl-based systems such
   as Alpine, and platforms without a release binary.
3. **A `pre-commit` hook definition** (`.pre-commit-hooks.yaml`), the usual
   way projects in other languages run linters before commit.

A Homebrew tap may follow. Lisp projects keep the Quicklisp and ocicl routes of
COMPASS-DRAFT-toolchain-D8.

**Code signing and notarization are deferred.** The first releases ship
unsigned macOS and Windows executables. The release notes document installing
through the setup action, the container, or `curl`, which avoid the macOS
browser quarantine, and the Windows SmartScreen warning for downloaded
executables. Signing and notarization follow once the toolchain has had more
development and testing. Apple notarization needs a paid developer account.

**Constraints on the code, from v0.1:**
- **No native libraries.** All dependencies are pure Lisp; D18 removes the only
  native one.
- **Self-contained executable.** Nothing is loaded at run time from an init
  file, from ASDF, or from this repository. Vocabularies, templates of generated
  files, and the source-header registries are compiled into the image.
- **Explicit encoding and line endings.** All files are read and written as
  UTF-8, CRLF line endings are accepted on input, and paths are handled through
  `uiop`, never by string concatenation.
- **Git is optional.** Git is found on the `PATH` and invoked with an argument
  list, never through a shell. Commands that need Git fail with exit code 2 and
  a clear message when it is absent. v0.1 does not need Git.
- **Build identity.** `compass version` reports the toolchain version, the
  commit it was built from, and the target platform.
- **Portable code.** Implementation-specific calls go through `uiop`, so that
  ECL or CCL remain possible for platforms SBCL does not serve.

**Consequences for projects not written in Lisp:**
- **The manifest stays an s-expression** (D4). It is the one file such a
  project writes in Lisp syntax. To spare authors from writing it by hand,
  `compass init` writes a starting manifest from the repository's state and a
  few questions.
- **Some features are thinner outside Lisp:**
  - Symbol checks in `ref/code-exists` rely on per-language patterns
    (COMPASS-DRAFT-toolchain-O4).
  - `asdf:` test locators, ASDF load order, and the ASDF `:description`
    fallback have no equivalent in other build systems. The source map
    degrades to name order and directory READMEs.
  - `:repl` commands apply only to Lisp projects; `:shell` serves all others.
- **Custom rules require Lisp** and a source build. The JSON report and per-rule
  output let other tools consume findings without extending the toolchain.

**Alternatives:**
- Source builds only, through Quicklisp or ocicl. Rejected for projects not
  written in Lisp: it asks every adopter to install and configure a Lisp.
- Rewrite the toolchain in a language that ships binaries more easily (Go,
  Rust). Rejected: it abandons the shared front end with the S2 importer and
  Classic (§22), and SBCL's binaries are adequate, as ocicl and pgloader show.
- Build all targets on current runners. Rejected for Linux: the glibc floor
  would exclude long-term-support distributions still in wide use.
- Sign and notarize from the first release. Deferred, as above.

### COMPASS-DRAFT-toolchain-D20 — Vocabulary values carry a standing

**Status:** Proposed

**Context:** The toolchain must recognise vocabulary that decisions have
introduced but the standard has not yet adopted: the `Superseded` status (D5),
status sets for `Glossary` and `Ideation` (D12), the `threat-model` subtype
([COMPASS-DRAFT-secure-development](Survey.SecureDevelopment.md)), and the
`read-if:` extension key (D13). Rejecting these values would fail documents the
skills already write, since they write D5's form. Accepting them silently would
let the toolchain run ahead of the standard.

**Decision:** Every vocabulary value in the toolchain's data carries a
**standing**, `:accepted` or `:pending`, and the decision that introduces it.
A pending value validates, and produces a warning (`vocab/pending`) naming
that decision. Accepting an amendment changes one entry in the data. The test
that keeps the toolchain's vocabulary in step with
`skills/reference/vocabularies.md` covers accepted values only. The Memo genre,
its statuses, M-records, and the `memos:` field are accepted
(COMPASS-DRAFT-agent-workflow-D1 to D4).

**Alternatives:**
- Treat proposed values as accepted. Rejected: the toolchain would define the
  standard instead of checking it.
- Make pending values errors unless the manifest enables a named profile.
  Rejected: every repository would need the profile to accept documents the
  skills produce.

### COMPASS-DRAFT-toolchain-D21 — Implementation conventions for the baseline

**Status:** Proposed

**Context:** Building v0.1 requires several choices that the decisions above
leave open. Each affects more than one command, or a later release, so they are
recorded here rather than left to the code.

**Decision:**
- **Layered packages.** `compass.vocab`, `compass.model`, `compass.parse`,
  `compass.corpus`, `compass.rules`, `compass.report`, and `compass.cli`, in
  that order, each using only those before it. The `compass` package
  re-exports the public interface. The parser and model can therefore be
  reused by the Markdown→Lexis importer (S2) and the RDF exporter (D17) without
  the rules or the command line.
- **Heading anchors.** A heading's anchor follows GitHub's rule. The heading's
  inline markup is removed first: code-span backticks, link and image syntax,
  emphasis asterisks, and HTML tags. The text is then lowercased, every
  character other than a letter, a digit, an underscore, a hyphen, or a space
  is removed, and each space becomes a hyphen. A repeated anchor gets `-1`,
  `-2`, and so on. `compass show ID#anchor`, `ref/doc-resolves`, and the
  section IRIs of [COMPASS-DRAFT-semantic-binding](Spec.SemanticBinding.md) use
  this one rule.
- **Corpus discovery.** The corpus is every `.md` file under the document
  directory, except the non-documents of D10 (`README.md`, `INDEX.md`,
  `CATALOG.md`, `MAP.md`), plus every `.md` file at the repository root that
  opens with front-matter. Root fixtures such as `README.md` carry no
  front-matter (§10), so `Compass.md` (COMPASS-0001) is found without a
  manifest entry.
- **Repository root.** The nearest enclosing directory containing
  `compass.sexp`, else the nearest containing `.git`, else the working
  directory; `--root` overrides.
- **Syntax errors.** A front-matter block that the subset parser (D18) rejects
  is reported once, under `fm/syntax` (error), and its document receives no
  further front-matter checks.
- **Unloaded namespaces.** Before federation loading (v0.2), a reference into a
  namespace that no loaded document or manifest declares is counted as
  *unverified* in the summary, not reported as a finding.
- **`compass rules`.** Lists every rule with its severity, the section it
  enforces, and a one-line summary, as text or JSON, so that skills can explain
  findings without restating the rule set.
- **`compass outline` and `compass refs` in the baseline.** The skills of
  [COMPASS-DRAFT-authoring-assistance](Plan.AuthoringAssistance.md) need to
  open part of a large document and to find what refers to an identifier. A
  search with `grep` misses links whose text is not the identifier, so
  `outline` moves forward from roadmap step 6, and `refs` is added. `refs`
  reports each referring line once, under the most specific of five kinds:
  front-matter relation, register listing, link, memo basis, or prose
  mention. It does not search fenced code or HTML comments, which hold examples
  and guidance.
- **Paths given to `check`.** A path that is not a file of the corpus (or a
  directory containing one), or that lies outside the repository, is a usage
  error, so that a document written in the wrong place is not reported as
  passing. A corpus with no documents at all is reported on standard error.

**Alternatives:**
- A single package. Rejected: nothing would keep the parser free of the rules,
  which S2 and the exporter must not depend on.
- A manifest key listing documents outside the document directory. Rejected for
  v0.1: the front-matter test identifies them without configuration.

### COMPASS-DRAFT-toolchain-D22 — One ledger per repository, one entry per line

**Status:** Proposed

**Context:** D3 fixes what the ledger records but not its shape: whether a
repository that owns several namespaces keeps one ledger or several, how an
entry is written, how numbers are counted, and how a ledger that a pull request
has damaged is reported. The uniqueness guarantee (D1) depends on every
allocation being a line appended to one file, so that two concurrent
allocations always conflict.

**Decision:**
- **One file.** A repository keeps one ledger, `REGISTRY.sexp` in its document
  directory, for every namespace its manifest owns (D4). Allocations in all of
  them are therefore put in one sequence, and two branches that allocate
  anything at all conflict.
- **One entry per line**, as a property list read by the restricted reader:
  `:id` and `:kind` always; `:path` (the document's path at allocation) for a
  document; `:host` (its document's identifier at allocation) for a record;
  `:draft`, the provisional identifier it replaced, when there was one; `:date`
  and `:by` (the allocator, as Git and `.mailmap` name them). Blank lines and
  `;` comments are allowed, so the file can open with a header. An unknown key
  is a warning, so that a later toolchain may add one.
- **Four counters per namespace:** documents, `D`, `O`, and M records. The next
  number of a kind is one more than the highest found in the ledger, in the
  ledger at the base revision, and among the canonical identifiers the
  documents already use. Gaps are allowed; numbers never go down and are never
  reused.
- **Rules.** `ledger/valid` reports a line that is not a comment or one
  well-formed entry, including a merge-conflict marker; `ledger/unique` an
  identifier or alias listed twice; `ledger/coverage` a canonical identifier
  defined without an entry, or a provisional identifier still defined after the
  ledger assigned it; `ledger/owned-namespace` an entry or definition in a
  namespace the manifest does not own; `ledger/append-only` a ledger whose text
  at the base revision (`--base`, by default `HEAD`) is not a prefix of its
  current text; `ledger/no-union-merge` a merge driver that would hide a
  conflict; and `ref/stale-alias` (a warning) a reference written with an alias.
  Without a manifest that declares namespaces, no ledger rule runs; without Git,
  the last two report that they did not run.

**Alternatives:**
- One ledger per namespace. Rejected: allocations in different namespaces of
  one repository would merge without conflict, so the repository would no
  longer be one sequence; and nothing is gained, since the entry names its
  namespace.
- A ledger written as one list form. Rejected: an append would rewrite the
  closing parenthesis, so every allocation would touch the previous line.
- One counter for all kinds. Rejected: §8's record numbers would leap by the
  number of documents allocated in between.

### COMPASS-DRAFT-toolchain-D23 — Provisional records in a numbered document reuse its alias

**Status:** Proposed

**Context:** D2 forms a provisional record identifier from its document's
provisional identifier. Once the document has a number, a record added to it on
a branch has no provisional document identifier to borrow, and writing a
canonical number at once would bring back the collision D2 avoids.

**Decision:** A provisional record in a numbered document uses the document's
alias in the ledger: a decision added to `COMPASS-0003`, formerly
`COMPASS-DRAFT-toolchain`, is written `COMPASS-DRAFT-toolchain-D22`, numbered
past every record of that slug the document or the ledger already has. A
document that never had an alias, such as `COMPASS-0001`, uses any slug that
names no other document and is no other identifier's alias. `id/format` accepts
both; `compass next NS --kind K --in FILE` prints the next such identifier, and
`compass assign FILE` numbers it. Clarifies D2 and §13.

**Alternatives:**
- Number the record at once. Rejected: numbers would be taken on branches, not
  at acceptance (§13), and would collide.
- Any free slug, also for documents that have an alias. Rejected: the tie
  between a record and its document would be lost.

### COMPASS-DRAFT-toolchain-D24 — What `compass assign` does

**Status:** Proposed

**Context:** §13 has the steward assign numbers at acceptance. Done by hand, that
means choosing free numbers, rewriting every reference, renaming the anchors of
changed headings, and appending entries, without a mistake.

**Decision:** `compass assign FILE [--dry-run] [--force] [--base REV]`:
- refuses unless the document's status is an accepted one (`Accepted`,
  `Implemented`, `Design-Record`, or `Current`), or `--force` is given, and
  unless the ledger has no errors;
- numbers the document, if its identifier is provisional, and every provisional
  record it defines, in the order of their headings, except memo records still
  `Draft`, which are numbered when a person moves them to `Current` (§13);
- takes the next numbers as D22 describes, with the base revision's ledger
  included (`--base`, by default `origin/HEAD`, `origin/main`, or
  `origin/master`, whichever exists), which narrows the window for a
  collision;
- rewrites whole identifiers in **corpus documents only**: their front-matter,
  text, headings, code spans, and link text, but not fenced code or block HTML
  comments, which hold examples and guidance;
- renames the anchors of headings that change, and rewrites links and
  `ID#anchor` references to them;
- appends one ledger entry per number, with the provisional identifier as its
  alias, and regenerates `INDEX.md` where one exists;
- lists the other tracked files that still name an old identifier, such as
  source headers and tests. Those keep working, since an alias still resolves,
  with the `ref/stale-alias` warning in documents.

With `--dry-run` it prints the same report and writes nothing. It needs Git, to
name the allocator and to read the base revision.

**Alternatives:**
- Rewrite every tracked file. Rejected: tests and examples name provisional
  identifiers on purpose.
- Leave references to the alias. Rejected: documents would accumulate stale
  references; the alias is a safety net, not the normal form.

### COMPASS-DRAFT-toolchain-D25 — Concurrent allocations are recovered by keeping both and renumbering

**Status:** Proposed

**Context:** When two branches allocate, the second to merge meets a conflict
in the ledger (D1). The earlier plan had the author take the upstream ledger
and renumber. That loses the second branch's entries, and with them the aliases
that let references to its old provisional identifiers resolve.

**Decision:** The author keeps both sides of the conflict, in either order, or
leaves the conflict markers in place, and runs
`compass renumber [--base REV] [--dry-run]`. It:
- removes any conflict markers, keeping both sides;
- rewrites the ledger as the base revision's ledger followed by the entries
  this branch added, so that the base is a prefix again;
- moves each added entry whose identifier the base already allocated, or an
  earlier added entry took, to the next free number, and updates the `:host` of
  added entries that name it;
- gives an entry to a canonical identifier this branch defines on an added line
  with no entry at all (as after taking the upstream ledger), keeping its number
  if it is free; such an entry has no alias, and the command says so;
- rewrites the moved identifiers, and the anchors that change with them, **only
  on lines this branch added** (from `git diff` against the base), so that
  references to the other branch's allocation stay correct.

It prints every change; the author reviews them before committing.

**Alternatives:**
- Take the upstream ledger and renumber. Kept as a fallback, but it loses
  aliases.
- Rewrite every reference to a moved identifier. Rejected: after the merge the
  same identifier also names the other branch's document.

### COMPASS-DRAFT-toolchain-D26 — Records are referred to by full identifier; short forms are found, not rewritten

**Status:** Proposed

**Context:** Documents refer to records by short forms such as `D6`, `O4 and O5
of <document>`, or `<identifier>-D10 to D14`. A short form means whatever record
its reader takes it to mean, and that changes when records are numbered: after
`compass assign`, a `D6` written in a document whose decisions became
`COMPASS-D5` to `COMPASS-D15` reads as `COMPASS-D6`, which is another record.
Rewriting short forms automatically needs a guess at what each means (the
document's own record, a related document's, or one named by the words around
it), and a wrong guess silently changes a document's meaning. A trial
`assign` of a real Plan made such wrong guesses.

**Decision:**
- References to records are written with the full identifier, canonical or
  provisional. `compass assign` and `compass renumber` rewrite whole
  identifiers only.
- A new rule, `ref/short-record` (warning), finds short forms in text and
  headings, outside code spans, comments, and record headings, and suggests the
  identifier each probably means: the one the context names (a list continuing
  a full identifier, or `of`, `in`, or `from` followed by one, also across a
  line break), or else a record of the document itself, of a document it
  `relates-to`, or, last, of its namespace. A bare token that matches no record,
  such as a table label `M1`, is not reported.
- `compass assign` refuses while any short form in the corpus probably means a
  record it would number, listing each with its suggestion; `--force` assigns
  anyway and lists them as warnings. `compass renumber` lists the short forms
  that point at records it moved.

Converting the existing short forms is a one-time edit by an author, guided by
the warnings; the rule then keeps new ones from accumulating.

**Alternatives:**
- Rewrite short forms by the same guesses. Rejected for the silent errors
  described above.
- Make short forms an error. Rejected: in a document whose records are never
  renumbered they are harmless, and §8 does not forbid them; the warning and the
  refusal in `assign` cover the case where they do harm.

### COMPASS-DRAFT-toolchain-D27 — Git-derived fields, including for files not yet committed

**Status:** Proposed

**Context:** §7 lets `authors`, `created`, and `updated` be omitted and derived
from Git, and the rule table has `git/derivable` check that a required field is
present or derivable. Neither says what is derived for a file that has not been
committed, whose first check comes before its first commit, nor for a file
outside any repository, a renamed file, or a shallow clone.

**Decision:**
- **Derived values.** `authors` are the authors of the commits that touched the
  file, following renames (`git log --follow`), named as `.mailmap` names them,
  in order of first contribution. `created` is the author date of the first of
  those commits and `updated` of the last.
- **Work not yet committed.** A file that is untracked, or has uncommitted
  changes, adds the current Git user (`user.name`, through `.mailmap`) to its
  authors, and today's date as `updated`, and as `created` if it has no commit.
  A new document therefore checks clean before its first commit.
- **`git/derivable`** (error) reports a required field (`created`, `authors`)
  that is absent and cannot be derived: the file is outside any Git work tree,
  or it has no commit and Git has no `user.name`. Without Git, the rule records
  a note that it did not run.
- **Shallow clones.** The first commit present may not be the file's first, so
  a derived `created` there is marked as possibly late.
- A value written in front-matter always wins, and derived values are never
  written back into a file (§7). `compass outline` shows each of the three
  fields with its source.

**Alternatives:**
- Require the fields in front-matter. Rejected: §7 permits deriving them, and
  written copies go stale.
- Treat an uncommitted file as underivable. Rejected: every new document would
  fail its first check.
- Use committers rather than authors. Rejected: a steward who rebases or merges
  would be counted as an author of everything.

### COMPASS-DRAFT-toolchain-D28 — Which code references are checked, and how deeply

**Status:** Proposed

**Context:** §9 makes commit-pinned code references mandatory in `Log` and
`Plan` and recommended elsewhere. COMPASS-DRAFT-toolchain-O4 asks how deeply a
reference is verified. A checker must also tell a code reference from other
code spans: rule names such as `ledger/unique`, identifiers with anchors, and
examples of the grammar itself, such as `path:symbol@revision`.

**Decision:**
- **What is a code reference.** A code span in a text or heading line (not in
  fenced code or an HTML comment) of the form
  `[NS:]path[:symbol | #Lm[-Ln] | :line][@revision]`, whose path is a path: it
  has a namespace prefix, contains `/`, ends in a known file extension, or
  names a file in the working tree. A path with neither a location nor a
  revision, such as a bare file name, is not checked.
- **`ref/code-pinned`** reports a reference with a location and no
  `@revision`: an error in a `Log` or `Plan`, a warning elsewhere. A line written
  `:42` is reported in either case, with the advice to write `#L42`.
- **`ref/code-exists`** checks a pinned reference: the revision must name a
  commit or tag, and the path must exist at it (errors); the symbol must be
  defined there, and a line range must lie within the file (warnings).
  Paths are repository-relative, and a path prefixed with a namespace is read
  in that namespace's repository (COMPASS-DRAFT-toolchain-D29).
- **Finding a symbol.** In Lisp files, a definition form (`(def…` or
  `(define-…`, also with a quoted name, FiveAM's `(test …`, and slot readers
  and accessors). In Python, JavaScript and TypeScript, Go, Rust, C and C++,
  and shell, a small table of definition patterns. In any other file, the
  symbol as a whole token.
- **Unverified, not reported.** A reference into a namespace that is not loaded;
  a revision missing from a shallow clone. Without Git, the rule records a note
  that it did not run.
- **`memo/basis`** requires a pinned basis to name a revision that exists, where
  Git can tell; `ref/code-exists` leaves that one finding to it.
- Revisions and files are read with two Git processes per check, whatever the
  number of references.

Resolves COMPASS-DRAFT-toolchain-O4.

**Alternatives:**
- Read Lisp files with the Lisp reader. Rejected: it needs each file's packages
  and read-time environment, and still misses names that macros generate.
- Report a symbol that cannot be found as an error. Rejected: definition
  patterns are approximate, and a false error would block a merge.
- Check every code span that parses. Rejected: rule names and examples of the
  grammar parse too.

### COMPASS-DRAFT-toolchain-D29 — Federation checks are opt-in and one hop deep

**Status:** Proposed

**Context:** The manifests of COMPASS-DRAFT-toolchain-D4 list the local paths of
federated repositories, and that decision has federation-level checks run "when
the federation paths are available". Until now a reference into another
namespace has been counted as unverified (COMPASS-DRAFT-toolchain-D21). COMPASS-DRAFT-toolchain-O3 asks what stops two repositories from
claiming one namespace.

**Decision:**
- `compass check --federation` loads each repository listed under
  `:federation`, at its path relative to this repository's root: its manifest,
  its documents (skipping files without front-matter), and its ledger. The
  federated repositories' own `:federation` lists are not followed.
- References into a loaded namespace are then checked as local ones are:
  documents, records, anchors, ledger aliases, and code references prefixed
  with the namespace, against that repository's Git. Findings are reported only
  for this repository's files.
- **`federation/path`** (error) reports an entry whose path does not exist, has
  no `compass.sexp`, or whose manifest does not own the namespace the entry
  names.
- **`federation/namespace`** (error) reports a namespace that this repository
  and a federated one both own, or two federated ones.
- Without `--federation` nothing changes, so a repository's own CI does not
  depend on what is checked out beside it. `show`, `outline`, and `refs` keep
  `--root` for other repositories.

Partly answers COMPASS-DRAFT-toolchain-O3: a namespace claimed twice among the
federated repositories is found, but not one claimed by a repository outside
the federation.

**Alternatives:**
- Follow `:federation` lists transitively. Rejected: the cost grows with the
  whole federation, and cycles are the norm, since each repository lists the
  others.
- Load the federation whenever its paths exist. Rejected: a check's result would
  depend on what happens to be checked out next to the repository.

## The uniqueness guarantee

The guarantee is a set of invariants. The validator enforces them, and the
repository settings make it impossible to bypass the validator.

**Invariants checked by `compass check`:**

1. Every canonical `<NS>-<NNNN>`, `<NS>-D<n>`, `<NS>-O<n>`, and `<NS>-M<n>`
   that the repository defines appears in its ledger, in a namespace the
   repository owns (COMPASS-DRAFT-toolchain-D4, D22).
2. No identifier or alias appears twice in the ledger, and no two documents
   declare the same `id`.
3. The ledger at the base revision is a **byte-for-byte prefix** of the ledger
   at the head revision. Any deletion, edit, or renumbering is an error, which
   enforces "never reused."
4. `.gitattributes` does not apply `merge=union` (or any other custom merge
   driver) to a ledger. A union driver would silently suppress the conflict
   that invariant 3 depends on.
5. Every provisional ID either resolves within the repository or, through a
   ledger alias, to a canonical ID. In the second case the validator warns that
   the reference is stale.

**Required repository settings, documented as part of setup:**

- Protect the main branch. Merges happen only through pull requests.
- Make `compass check` a required status check. Also require branches to be up
  to date before merging, or use a merge queue, so the check always runs against
  the current tip.
- Add a `CODEOWNERS` entry assigning `doc/REGISTRY.sexp` to the namespace
  steward. This implements §13's steward-at-merge rule mechanically: no
  allocation merges without the steward's approval.

**Why concurrent allocation cannot succeed.** Two pull requests that each
allocate append after the same last line of the ledger, and Git reports a
conflict. If the second is resolved by keeping both lines and nothing else,
invariant 2 fails. If `compass renumber` is then run, the result is correct
(D25). If the ledger is not touched at all, invariant 1 fails. Each path to a duplicate is
blocked by either Git or the required check. The concurrency tests demonstrate
every case in temporary Git repositories.

## Identifier lifecycle

1. **Draft.** `compass-author` scaffolds `<NS>-DRAFT-<slug>`, with
   `<NS>-DRAFT-<slug>-D<n>`/`-O<n>`/`-M<n>` register entries. No coordination
   is needed. A record added to a document that already has a number reuses the
   document's alias (D23).
2. **Assign.** At acceptance, the steward (or the author, with the steward
   approving through `CODEOWNERS`) runs `compass assign <file>` (D24). The
   command:
   - computes the next numbers from the local ledger, the upstream ledger
     (`--base`), and the identifiers already in use, which keeps the race
     window small;
   - rewrites the provisional ID and its register entries in every corpus
     document, with the anchors that change;
   - appends the ledger entries, keeping each provisional ID as an alias.
3. **Merge.** The required check confirms the invariants.
4. **Conflict recovery.** If another allocation merged first, merge or rebase,
   keep both sides of the ledger's conflict, and run `compass renumber` to move
   this branch's colliding allocations to the next free numbers (D25).
5. **Retirement.** The ID is never reused. Documents become `Deprecated` or
   `Superseded` (COMPASS-DRAFT-toolchain-D5), and re-homing follows §13.

## The ledger and manifest

The ledger starts with a comment header, followed by one entry per line
(D22):

```lisp
;;; Compass allocation ledger for COMPASS. Append-only: one entry per line;
;;; never edit, reorder, or delete an entry (Compass §13). Maintained by
;;; compass assign, compass renumber, and compass init --ledger.
(:id "COMPASS-0001" :kind :document :path "Compass.md" :date "2026-10-09" :by "Andrew Sengul")
(:id "COMPASS-D1" :kind :decision :host "COMPASS-DRAFT-authoring-assistance" :date "2026-10-09" :by "Andrew Sengul")
(:id "COMPASS-0002" :kind :document :draft "COMPASS-DRAFT-toolchain" :path "doc/Plan.Toolchain.md" :date "2026-10-12" :by "Andrew Sengul")
(:id "COMPASS-D5" :kind :decision :draft "COMPASS-DRAFT-toolchain-D1" :host "COMPASS-0002" :date "2026-10-12" :by "Andrew Sengul")
```

Description: the example ledger shows four entries. The first two were seeded
from identifiers already in use, so they have no alias; the decision names the
provisional document that holds it. The last two were made by
`compass assign`: a document whose provisional ID `COMPASS-DRAFT-toolchain` is
kept as an alias, and one of its decision records, with its own alias and its
host's new number.

`:kind` is one of `:document`, `:decision`, `:open-question`, or `:memo`
(COMPASS-DRAFT-agent-workflow-D2). Register entries of every kind carry `:host`.

The project manifest:

```lisp
(:namespaces ("COMPASS")
 :doc-directory "doc/"
 :federation ((:namespace "ORIGIN"  :path "../origin")
              (:namespace "CLASSIC" :path "../classic"))
 :commands ((:name :test  :repl "(asdf:test-system \"compass\")")
            (:name :check :shell "make check DEPS=ocicl"
             :doc "Validate this repository's corpus"))
 :map (:exclude ("ocicl/**"))
 :catalog (:budget 8192)
 :stewards ((:namespace "COMPASS" :steward "Andrew Sengul" :approval :solo))
 :authorities ((:namespace "COMPASS" :authority "example.net,2026")))
```

Description: the manifest declares that this repository owns the COMPASS
namespace and keeps its documents in `doc/`. It lists two federated
repositories by local path. The optional keys of
COMPASS-DRAFT-toolchain-D15 add one REPL command and one shell command,
exclude the ocicl dependency directory from the source map, set the catalog
budget, and declare Andrew Sengul the solo steward of the COMPASS namespace. The
`:authorities` key of COMPASS-DRAFT-toolchain-D17 gives the namespace's tagging
authority for RDF export; the authority shown is illustrative.

Both files are read with `*read-eval*` bound to false and a reader restricted to
strings, integers, keywords, and lists. Reading them can neither run code nor
intern arbitrary symbols.

## Agent context

### Authority weight

Table: Authority weight by genre and status (COMPASS-DRAFT-toolchain-D12). Rows
are checked top to bottom; the first match applies.

| Weight | Documents and records | Agent treatment |
|---|---|---|
| Excluded | Any document or record with status `Deprecated`, `Superseded`, `Rejected`, or `Withdrawn` | Not used for current behaviour; follow `superseded-by` instead. Left out of the catalog |
| Provisional | Any document or record with status `Draft`, `Proposed`, or `In-Review`; any record whose host is Provisional | Work in progress; cite with caution |
| Authoritative | `Ref`, `Guide`, `Spec` with status `Current`; `Arch` with status `Accepted` or `Design-Record` (for design intent); `D`-records with status `Accepted` or `Implemented`; M-records with status `Current` | Present truth; the code should agree, and disagreement is a finding to raise |
| Directive | `Plan` with status `Accepted`; `Glossary` with status `Current` | Intended direction and binding terminology |
| Contextual | `Log`, `Eval`, `Survey`, `Ideation` with status `Accepted` or `Implemented`; `Plan` and `Arch` with status `Implemented` | History and rationale; explains *why*, never overrides an Authoritative document |

Any combination the table does not list is Contextual. A `Memo` host document
with status `Current` is therefore Contextual, but the catalog lists its
records rather than the host (COMPASS-DRAFT-agent-workflow-D4). `O`-records
carry no status (§8) and therefore no weight. The catalog does not list them;
`compass show` and `compass-lookup` resolve them on request.

### The session catalog

An excerpt of a generated catalog:

```markdown
<!-- Generated by `compass catalog` — do not edit. Inputs: sha256:3f9a… -->
# COMPASS catalog

Documents are ranked by authority weight. Open one with `compass show ID`,
one section with `compass show ID#anchor`, or list its sections with
`compass outline ID`.

## Commands
- test (REPL): `(asdf:test-system "compass")`
- check (shell): `make check DEPS=ocicl` — Validate this repository's corpus

## Source map (top level; full map in doc/MAP.md)
- `src/` — Toolchain sources (system `compass`)
- `skills/` — LLM authoring-assistance skills

## Authoritative
- COMPASS-0004  Spec/Current  [source-map]  Source Headers and Source Map (18 KB)
  Read-if: writing or checking file headers, or changing map generation

## Directive
- COMPASS-0003  Plan/Accepted  [toolchain]  Compass Validation Toolchain (52 KB)
  Read-if: changing validation rules, ID allocation, or the ledger format

## Accepted decisions
- COMPASS-D3   The allocation ledger holds immutable facts only (COMPASS-0003)
- COMPASS-D12  Authority weight is derived from genre and status (COMPASS-0003)

## Memos
- COMPASS-M1  The ledger is read with a restricted reader that interns no symbols
  Read-if: changing ledger or manifest parsing

## Unreviewed memos (recorded, not yet reviewed; verify against their Basis)
- COMPASS-M2  Scanner anchors follow GitHub's slug rules, including duplicate suffixes
  Read-if: changing heading anchors, `show ID#anchor`, or link resolution
```

Description: the excerpt shows a catalog in the order D11 fixes. A banner with
an input digest comes first, then a short preamble, the manifest's commands, the
top level of the source map, documents grouped by weight with their `read-if:`
lines, one line per accepted decision, one line per current memo, and, last,
one line per unreviewed memo under a heading that says so. The identifiers,
statuses, sizes, and the memos are illustrative, as if this Plan,
the source-header Spec, and a COMPASS memo host had been accepted and assigned
numbers.

## Architecture

Table: Toolchain components and their responsibilities.

| Component | Responsibility |
|---|---|
| Front-matter | Split the YAML block, parse it with the strict subset parser (D18), check types against the field schema, map it onto the model |
| Body scanner | Line-oriented scan into positioned nodes (headings, tables, captions, fences, links, images, code spans, comments) |
| Model | CLOS classes: `document`, `decision-record`, `open-question`, `memo-record`, `code-ref`, `citation`, `ledger-entry`, `namespace`, `corpus`, `federation` |
| Vocabularies | §4/§6 controlled values, the extension-key registry, the source-header label and value registries, and the weight function, as Lisp data. A test checks them against `skills/reference/vocabularies.md` so the skills cannot drift |
| Git layer | Run `git` through `uiop:run-program`. Derive authors and dates (`git log --follow`, `.mailmap`), read the ledger at a base revision, check commit-pinned references, collect `Assisted-by:` trailers into each document's assistance history (COMPASS-DRAFT-agent-workflow-D7), and classify changed documents as mechanical or substantive (COMPASS-DRAFT-agent-workflow-D5) |
| Rules | One named rule per check, each with a severity and the § it enforces |
| Ledger and allocation | Read and append the ledger; `next`, `assign`, `renumber`; rewrite provisional IDs across the repository |
| Index generation | Per-namespace and federated `INDEX.md`, with a drift check |
| Source headers | Per-comment-family extractors for file headers and directory README blocks; effective-header inheritance; ASDF `:description` and `:serial` reading |
| Agent context | The session catalog (D11) and source map (D14), as Markdown and JSON, with drift checks and the input digest |
| RDF export | The semantic binding (D17): IRI minting, triple generation, deterministic serialisation, and generation of the vocabulary, context, and shapes |
| Report | Human-readable text and JSON (`shasht`) with file, line, rule, severity, and message |
| CLI | Executable entry point, built with `asdf:make` |

Planned repository layout:

```
compass.asd          ; systems "compass" and "compass/tests"
compass.sexp         ; this repository's project manifest
ocicl.csv            ; ocicl lockfile (committed); ocicl/ is git-ignored
Makefile             ; deps / build / test / check, DEPS=ql|ocicl
src/                 ; package, frontmatter, scanner, model, vocab, git,
                     ; ledger, rules/, index, headers, catalog, map,
                     ; rdf, report, cli
vocab/               ; generated compass.ttl, compass-shapes.ttl,
                     ; context.jsonld (D17)
doc/                 ; COMPASS documents, plus generated INDEX.md,
                     ; CATALOG.md, and MAP.md (committed)
tests/               ; FiveAM suites, fixture corpora, git-repo harness
setup/action.yml     ; setup action: download and verify a release (D19)
Containerfile        ; container image for other CI systems (D19)
.pre-commit-hooks.yaml ; pre-commit hook definition (D19)
.github/workflows/   ; compass-check (QL + ocicl matrix); release (D19)
```

### Front-matter types

`fm/types` checks each field against the type below after YAML parsing. The
subset parser (D18) keeps every scalar as a string, quoted or not, so the types
below are the only interpretation a value receives: YAML 1.1's conversions
(`no` to false, `0.10` to 0.1, dates to timestamps) never occur.

Table: Front-matter field types checked by `fm/types`.

| Field | Type | Notes |
|---|---|---|
| `id` | string | Matches the canonical or provisional grammar (§5, §13; D2) |
| `title` | non-empty string | Single line |
| `genre`, `subtype`, `scope`, `status` | string from the controlled vocabulary | `status` vocabulary depends on the genre family (§6; D5, D12) |
| `program`, `project`, `component` | string | |
| `language` | string, BCP-47 | `no` is Norwegian, as written; it is never read as a boolean |
| `api-version`, `schema-version` | string | Kept exactly as written, so `0.10` stays `0.10`; quoting is optional |
| `created`, `updated`, `reviewed` | date, `YYYY-MM-DD` | A string of that form naming a real calendar date; anything else is an error |
| `authors`, `reviewers` | list of strings | A single string is an error, so that a second author cannot be added as a mistyped scalar |
| `approved-by` | string | |
| `provenance` | map | `assistant` (string) is required inside it; `session` (string) is optional; other keys warn |
| `supersedes` | identifier, or list of identifiers | |
| `superseded-by` | identifier | |
| `relates-to` | list of identifiers | |
| `cites` | list of maps | Each with `title` (string), `locator` (string), and `external: true` (`cite/well-formed`) |
| `decisions`, `open-questions`, `memos` | list of register identifiers | Kinds must match the field (`D`, `O`, M) |
| `glossary` | string | An identifier, or a document name pending migration (warning) |
| `read-if` | string | Registered extension (D13); single line, within 160 characters |

A field whose value is null (`~`, or empty) is treated as absent. A required
field that is absent and not Git-derivable is an error (`fm/required`,
`git/derivable`).

### Validation rules

Table: Initial rule set, with severity and the section each rule enforces.

| Rule | Severity | Enforces |
|---|---|---|
| `fm/present`, `fm/required`, `fm/types` | error | §7 required fields, well-typed values |
| `fm/language` | error | §7, §12 BCP-47 `language` |
| `vocab/genre`, `vocab/subtype`, `vocab/scope`, `vocab/status` | error | §4, §5, §6 controlled vocabularies |
| `status/superseded-agrees` | error | COMPASS-DRAFT-toolchain-D5 |
| `fm/genre-fields` | warning | §7 genre-conditional fields (e.g. `api-version` only on Ref/Guide) |
| `fm/unknown-key` | warning | §18; COMPASS-DRAFT-toolchain-D13 |
| `fm/read-if` | warning | COMPASS-DRAFT-toolchain-D13 single-line `read-if:` within 160 characters |
| `id/format`, `id/unique` | error | §5, §13 |
| `ledger/valid`, `ledger/unique`, `ledger/coverage`, `ledger/append-only`, `ledger/no-union-merge`, `ledger/owned-namespace` | error | COMPASS-DRAFT-toolchain-D1, D3, D4, D22 |
| `ref/stale-alias` | warning | COMPASS-DRAFT-toolchain-D22: a reference written with a provisional identifier the ledger has assigned |
| `ref/short-record` | warning | COMPASS-DRAFT-toolchain-D26: a record referred to by a short form such as D6 |
| `register/mirrored` | error | §8: every record defined in the body (by its heading) is listed in front-matter; every listed record is defined in the body or, for a record the document amends, defined elsewhere in the corpus |
| `register/unique` | error | §8, §13: no record identifier is defined by a heading in more than one place |
| `register/heading-form` | warning | COMPASS-DRAFT-toolchain-D16: record headings use the full identifier |
| `register/status` | error | §8; COMPASS-DRAFT-toolchain-D12: every `D`- and M-record has a `**Status:**` line with a controlled value |
| `memo/host` | error | COMPASS-DRAFT-agent-workflow-D2: M-records appear only in `Memo` documents, which hold only M-records |
| `memo/fields` | error | COMPASS-DRAFT-agent-workflow-D2, D4: every M-record has `**Read-if:**` and `**Basis:**`; `**Superseded-by:**` appears with, and only with, `Superseded` |
| `memo/basis` | error | COMPASS-DRAFT-agent-workflow-D3: `**Basis:**` holds a commit-pinned code reference, a resolving Compass identifier, or a `cites:` title |
| `review/approver` | error | §6; COMPASS-DRAFT-agent-workflow-D6: `approved-by` is never an assistant, and self-approval occurs only by the declared steward of a `:solo` namespace |
| `ref/doc-resolves` | error | §9 document links resolve to real IDs |
| `ref/prose-mention` | warning | §9 document named without a link |
| `ref/code-pinned` | error in Log/Plan, else warning | §9 commit-pinned code references (COMPASS-DRAFT-toolchain-D28) |
| `ref/code-exists` | error; a missing symbol or line, warning | §9 the revision, path, and symbol exist (COMPASS-DRAFT-toolchain-D28) |
| `cite/well-formed` | error | §9 `cites` entries have `title`, `locator`, `external: true` |
| `git/derivable` | error | §7 `authors`/`created`/`updated` present or derivable (COMPASS-DRAFT-toolchain-D27) |
| `shape/sections` | warning | §14 spine sections present and in order |
| `a11y/alt-text`, `a11y/table-caption`, `a11y/diagram-description`, `a11y/heading-nesting`, `a11y/link-text` | error | §12, COMPASS-DRAFT-toolchain-D6 |
| `index/current` | error | COMPASS-DRAFT-toolchain-D6 generated index matches |
| `federation/path`, `federation/namespace` | error | COMPASS-DRAFT-toolchain-D4 and COMPASS-DRAFT-toolchain-D29: federated repositories exist, own what they are listed for, and claim no namespace twice |
| `manifest/authority` | warning | COMPASS-DRAFT-toolchain-D17: every owned namespace declares a tagging authority |
| `catalog/current` | error | COMPASS-DRAFT-toolchain-D10 generated catalog matches |
| `catalog/budget` | warning | COMPASS-DRAFT-toolchain-D11 catalog fits its budget without truncation |
| `header/*`, `dir/header-syntax`, `map/current` | as specified | [COMPASS-DRAFT-source-headers](Spec.SourceHeaders.md#validation-rules); COMPASS-DRAFT-toolchain-D14 |

### Command-line interface

- `compass check [PATH…] [--base REV] [--federation] [--format text|json] [--strict]`
  returns 0 if clean (warnings allowed unless `--strict`), 1 if any error was
  found, and 2 for a usage or internal failure.
- `compass assign FILE [--dry-run] [--force] [--base REV]` numbers a document
  and its provisional records (D24), and refuses while short references to them
  remain (D26). `compass renumber [--base REV]
  [--dry-run]` recovers from concurrent allocations (D25).
- `compass init --ledger` creates the ledger, seeded with the canonical
  identifiers the documents already define (D9).
- `compass next NAMESPACE [--kind document|decision|open-question|memo]` previews
  the next number without allocating it, from the ledger here and at `--base`
  (D22); with `--in FILE`, it prints the next provisional record identifier for
  that document (D23). Before the ledger exists (baseline
  v0.1), it computes the preview from the highest number found by scanning the
  corpus, and says that the result is advisory.
- `compass index [--check]` writes the namespace index, or with `--check` exits
  1 if the committed one differs from what would be written (COMPASS-DRAFT-toolchain-D6).
- `compass show ID[#anchor]`, which
  `compass-lookup` uses. With an anchor, `show` prints one section. Given a
  register ID (`D`, `O`, or M), it prints that record alone. For a document it
  also reports the assistance history derived from `Assisted-by:` trailers.
- `compass diff [--base REV]` lists the documents changed since `REV`, each
  classified as mechanical or substantive, for the reviewer
  (COMPASS-DRAFT-agent-workflow-D5).
- `compass outline ID[#anchor] [--format text|json]` lists a document's
  headings with their anchors and line ranges, so an agent can open only the
  part it needs with `show ID#anchor`. A record identifier outlines its host;
  an anchor limits the outline to that section and its subsections (D21).
- `compass refs ID[#anchor] [--format text|json]` lists everything in the
  corpus that refers to an identifier or a section, grouped by kind, each with
  its path and line. It exits 1 only if the identifier is neither defined nor
  referenced, so that dangling references are still listed (D21).
- `compass catalog [--check] [--all] [--json]` writes the session catalog;
  `--all` ignores the budget.
- `compass map [PATH] [--file FILE] [--check] [--json]` writes the source map,
  prints one subtree, or prints one file's effective header.
- `compass manifest --json` prints the manifest as JSON, for consumers not
  written in Lisp (COMPASS-DRAFT-toolchain-D4).
- `compass init [--namespace NS]… [--doc-directory DIR] [--federation NS=PATH]…
  [--steward NAME] [--solo] [--dry-run]` writes a starting `compass.sexp` from
  the repository's state (the document directory found, the namespaces in use)
  and its flags, so that projects not written in Lisp need not write the
  manifest by hand (COMPASS-DRAFT-toolchain-D19). It refuses to overwrite an existing manifest.
- `compass version` reports the toolchain version, the commit it was built
  from, and the target platform (D19).
- `compass export --rdf ntriples|turtle|nquads|trig|jsonld [--derived]
  [--history] [--with-text] [--federation]` writes the semantic binding
  (D17); `compass export --vocab` writes the vocabulary, context, and shapes.

## Baseline releases

The full plan is large, and its agent-context half waits on an evaluation
([COMPASS-DRAFT-agent-context-eval](Eval.AgentContext.md)). A usable baseline
comes first, so that the toolchain can check the corpora of projects in
development now. Each release is a subset of the [Roadmap](#roadmap) and is
designed so that later steps extend it rather than rewrite it.

**v0.1 — corpus checking without a ledger** (from roadmap steps 2 and 3):
- Front-matter splitting, parsing, and the [type checks](#front-matter-types);
  the controlled vocabularies, implementing D5's `Superseded` form.
- The body scanner, including register headings (`D`, `O`, and M kinds from the
  start) and each record's `**Status:**` line.
- Rules: `fm/syntax` (D21), `fm/present`, `fm/required`, `fm/types`,
  `fm/language`, `vocab/*` (including `vocab/pending`, D20),
  `status/superseded-agrees`, `fm/unknown-key` (D13; a warning from the start),
  `id/format`, `id/unique`, `register/mirrored`, `register/unique`,
  `register/status`, `register/heading-form`, `ref/doc-resolves`,
  `cite/well-formed`.
- The memo rules `memo/host`, `memo/fields`, and `memo/basis`, now that the
  Memo genre is accepted. Without Git, `memo/basis` checks the form of a
  commit-pinned reference, not that its revision exists.
- Commands: `check` (text and JSON), `show ID[#anchor]`, `outline` and `refs`
  (D21), `index` (without `--check`), `next` in its advisory, scan-based form,
  `rules` (D21), and `version`; `make install` copies the executable to
  `~/.local/bin`, or to `PREFIX/bin`.
- A `--skip-unmarked` option that skips files without front-matter and reports
  how many it skipped, so the checker can run over partly migrated corpora. This
  is an interim answer to O5, not its resolution.
- Builds under `DEPS=ql`; FiveAM tests over fixture corpora.
- The code constraints of D19 hold from the first commit, so that the
  executable built in v0.1 is already the one that v0.2.1 releases.

**v0.2 — identity and CI** (roadmap step 4, part of step 7):
- The ledger reader and its rules; `assign` and `renumber`; the concurrency
  tests (COMPASS-DRAFT-toolchain-D22 to COMPASS-DRAFT-toolchain-D26).
- Git-derived fields (`git/derivable`, COMPASS-DRAFT-toolchain-D27) and commit-pinned
  reference checks (COMPASS-DRAFT-toolchain-D28).
- `index --check` and `index/current`; `check --base` and `check --federation`
  (COMPASS-DRAFT-toolchain-D29).
- `compass init` and `compass manifest --json`.
- The GitHub Actions job under Quicklisp and ocicl; `ocicl.csv`; `CODEOWNERS`
  for the ledger; a local `pre-commit` script.
- The bootstrap of this repository, and the amendments to `Compass.md` of the
  accepted COMPASS-DRAFT-toolchain-D2, COMPASS-DRAFT-toolchain-D3, COMPASS-DRAFT-toolchain-D5,
  COMPASS-DRAFT-toolchain-D6, and COMPASS-DRAFT-toolchain-D16.

**v0.2.1 — release binaries** (the rest of roadmap step 7):
- The release workflow for the D19 targets, unsigned; the setup action; the
  container image; the `pre-commit` hook definition
  (`.pre-commit-hooks.yaml`). A short spike on the macOS and Windows runners
  comes first (see the [Roadmap](#roadmap)).

**v0.3 — RDF export** (part of roadmap step 5):
- The `:authorities` manifest key and `manifest/authority`.
- `compass export --rdf` in N-Triples and Turtle, covering front-matter,
  registers, ledger facts and aliases, sections, links, and code references
  ([COMPASS-DRAFT-semantic-binding](Spec.SemanticBinding.md)).
- `compass export --vocab`: the vocabulary, JSON-LD context, and SHACL shapes,
  generated from the vocabulary data.
- Tests that parse the output with an independent RDF parser and run the shapes
  over fixture corpora.
- Source-map triples follow once source headers exist (gated on the
  evaluation); derived weight follows D12.

**Not in any of these:** the catalog, the weight function, source headers and the map
(gated on the evaluation), the §12 rules, and `shape/sections`,
which follow in the order of the roadmap.

## Dependency management: Quicklisp and ocicl

Table: Dependency availability, checked 2026-10-05 against the local Quicklisp
dist and the ocicl registry.

| System | Quicklisp (dist 2023-06-18) | ocicl registry (latest) | Role |
|---|---|---|---|
| `cl-ppcre` | available | 20250606-a2ea581 | ID and code-reference grammars |
| `alexandria` | available | 20260812-f283e25 | utilities |
| `shasht` | 20230618 | 20251015-40a4aee | JSON report and manifest output |
| `fiveam` | 20220331 | 20240928-e43d6c8 | tests |
| `cl-hamcrest` | 20230214 | not in registry | not used (COMPASS-DRAFT-toolchain-D8) |

Every dependency is pure Lisp. No native library is needed in either ecosystem,
in CI, or in the release binaries (COMPASS-DRAFT-toolchain-D18, D19).

**Quicklisp (today).**
- The repository is made visible to ASDF either through the source registry or
  by symlinking it into `~/quicklisp/local-projects/`.
- Development uses `(ql:quickload "compass")`.
- The CI job installs Quicklisp and pins the dist to the version in local use,
  so builds do not shift when Quicklisp publishes a new dist.

**ocicl (forward).**
- `ocicl.csv` is committed; the `ocicl/` directory is git-ignored, as ocicl's
  own documentation recommends.
- `ocicl install` restores exactly the pinned digests.
- The CI job sets `OCICL_LOCAL_ONLY=1` so that no globally installed or
  parent-directory systems leak into the build.
- Lockfile updates go through `ocicl latest` in a normal reviewed pull request.

**Shared tooling.**
- `make deps|build|test|check DEPS=ql|ocicl` gives one entry point. A small
  `build.lisp` loads whichever runtime is selected and then calls `asdf:make`.
- Locally, `~/.sbclrc` keeps loading Quicklisp. ocicl is invoked explicitly
  through `DEPS=ocicl`, so neither setup disturbs the other.

**Follow-ups that depend on newer ocicl.**
- Upgrade the local ocicl from v2.6.6. Current releases add `git+` installs and
  `ocicl lint`.
- Run `ocicl lint` over the toolchain's own Lisp sources in CI.
- Ask for `compass` to be added to the ocicl registry, so downstream Lisp
  repositories can `ocicl install compass`. Repositories in other languages use
  the release binaries (COMPASS-DRAFT-toolchain-D19).

## Scope and Non-Goals

- **In scope (v1):** everything above, plus integration with the authoring
  skills and the bootstrap of the COMPASS namespace.
- **Outside this plan, in the authoring-assistance layer (S9)**, planned in
  [COMPASS-DRAFT-agent-workflow](Plan.AgentWorkflow.md):
  - the harness adapter (an OpenCode plugin) that injects `doc/CATALOG.md` at
    session start;
  - the consult → build → update protocol text;
  - the `compass-maintain` skill, which proposes `Log` entries, memos, header
    updates, and `Ref`/`Spec` corrections after a change.

  This plan builds the toolchain support those depend on: M-records, memo
  rules, `review/approver`, the `:stewards` key, `compass diff`, and trailer
  derivation.
- **Gated on evaluation:** the session catalog (D11), the authority weight
  (D12), and source-header extraction with the source map (D14) are not built
  until the pilot of [COMPASS-DRAFT-agent-context-eval](Eval.AgentContext.md)
  has run. Its decision rules may change or remove them. Everything else in
  this plan proceeds independently.
- **Not in v1:**
  - the Markdown→Lexis importer (S2), which builds on the scanner;
  - ingestion into Classic, and the forge integration that would build on it
    (RDF export itself is in scope, D17);
  - eager reservation (`compass reserve`, option B of
    COMPASS-DRAFT-toolchain-D1);
  - fixture compilation (S7), audience projection (S5), and the site build (S8);
  - checking inline language spans (§12);
  - editor and language-server integration (S9);
  - code signing and notarization of the macOS and Windows executables,
    deferred until the toolchain has had more development and testing
    (COMPASS-DRAFT-toolchain-D19).

## Open Questions

### COMPASS-DRAFT-toolchain-O1 — Native YAML or a pure-Lisp subset parser

`cl-yaml` gives full YAML 1.1 at the cost of a native libyaml dependency through
CFFI. That makes standalone binaries harder to distribute and adds a system
package to every CI image. Compass front-matter uses a small subset of YAML:
scalars, lists, a list of maps, and one nested map. A strict pure-Lisp parser
for that subset would remove the native dependency and could reject YAML-1.1
surprises such as `no` meaning false by construction. It would also mean
accepting less than other YAML consumers do, such as the S8 Astro collections.
Which costs more?

**Resolution (2026-10-08):** The pure-Lisp subset parser. Every front-matter
block in this repository already fits the subset, the native parser exposes a
parsing surface to pull-request input, and removing libyaml leaves the release
binaries with no native dependencies. Recorded as COMPASS-DRAFT-toolchain-D18.

### COMPASS-DRAFT-toolchain-O2 — Distributing the checker to downstream repositories

The CI of other repositories (origin, classic, lexter, psyche) needs `compass`.
The options are:
- build it from source at a pinned tag in each job;
- publish release executables, which link libyaml dynamically (see O1);
- provide a reusable GitHub Action;
- publish to the ocicl registry, the Quicklisp dist, or both.

Which is the supported path, and how is the toolchain version pinned per
repository?

**Resolution (2026-10-08):** Release executables, built per platform with no
native dependencies, are the supported path for every repository. GitHub CI
uses the setup action, which pins the toolchain version as an input and
verifies the download against the release checksums. Other CI systems use the
container image at a pinned tag. Lisp repositories may also build from source
through Quicklisp or ocicl. Signing and notarization for macOS and Windows are
deferred. Recorded as COMPASS-DRAFT-toolchain-D19.

### COMPASS-DRAFT-toolchain-O3 — Where the namespace table is authoritative

The manifests of COMPASS-DRAFT-toolchain-D4 prevent a repository from minting a
namespace it has not declared. They do not stop two repositories from both
declaring the same one. The federated index build would detect that, but only
after the fact. Should the COMPASS repository keep an authoritative namespace
table, with new namespaces approved by the COMPASS steward, and should
repository checks consult it?

**Partly answered (2026-10-10):** `compass check --federation` reports a
namespace that two repositories of the federation both own
(COMPASS-DRAFT-toolchain-D29). A claim by a repository outside the federation
is still not found, so the question of an authoritative table remains open.

### COMPASS-DRAFT-toolchain-O4 — Depth of code-reference verification

Checking that a revision and path exist is cheap and exact. Checking that a
symbol exists is not. A regular expression for `(def… <symbol>` works for Lisp
and misses forms generated by macros. Reading the file with the Lisp reader is
more precise, but needs the right packages and read-time environment. Languages
other than Lisp need their own heuristics. How strict should `ref/code-exists`
be, and should a symbol it cannot find be an error or a warning?

Release binaries make the toolchain available to projects in any language
(COMPASS-DRAFT-toolchain-D19), which raises the stakes. A table of definition
patterns per language (`def`, `fn`, `func`, `class`, and so on) is cheap but
approximate. For a language with no patterns, the rule could check only the
revision and path and report the symbol as unverified.

**Resolution (2026-10-10):** The revision and path are checked exactly, and a
missing one is an error. A symbol is looked for with definition patterns: Lisp
forms, and a small table for other common languages; in any other file, as a
whole token. A symbol not found is a warning. Recorded as
COMPASS-DRAFT-toolchain-D28.

### COMPASS-DRAFT-toolchain-O5 — Treatment of pre-Compass documents

The ancestor corpora (classic, origin, lexter) have no front-matter and use
`file:line` references. Running `compass check` over them as they stand would
bury real findings under noise. Should the validator offer a legacy mode that
skips files without front-matter, or reports them as a migration backlog, or
should migration be a separate `compass migrate` assistant?

The same question applies to source headers: the ancestor repositories use four
header forms (see [COMPASS-DRAFT-source-headers](Spec.SourceHeaders.md#afterword-limits)),
and most of the reshaping is mechanical enough for an assistant to propose.

### COMPASS-DRAFT-toolchain-O6 — Detecting stale source headers

The source map is faithful to source headers, but nothing checks that a header
still describes its file. Candidate heuristics include:
- a file whose code has changed substantially over several commits while its
  header has not (from `git log -L` or diff statistics);
- `Co-change` partners that changed in different commits;
- a `See:` target that has become Excluded (D12);
- a `Tests:` path that no longer exercises the file.

Which of these are reliable enough to report, at what severity, and should they
run in `compass check` or only in `compass-review`?

### COMPASS-DRAFT-toolchain-O7 — Catalog freshness in a working tree

The catalog is committed (D10), so an adapter reading it at session start sees
the state of the last regeneration. Documents created or re-statused during a
session, or on an unmerged branch, are missing or misranked until someone runs
`compass catalog`. The input digest lets an adapter detect this. Should an
adapter that finds a stale catalog regenerate it when the binary is available,
warn the agent, or do nothing until commit time?

## Prior Art

Table: Prior systems and what this plan draws from each.

| System | What to draw from |
|---|---|
| IETF Internet-Drafts → RFCs | The slug-named draft that becomes a number only at publication is the model for `<NS>-DRAFT-<slug>` and assign-at-merge |
| PEP 1 | Numbers handed out by editors as a gate; a master index (PEP 0) generated from the documents |
| Django migrations | Sequential numbers that collide on parallel branches, detected by a check (`makemigrations --check`) and fixed by explicit renumbering or merging; the model for `compass renumber` |
| Rust RFCs, Kubernetes KEPs | Forge PR or issue number as the ID. Rejected (COMPASS-DRAFT-toolchain-D1), but evidence that a serialization point outside the branch is needed |
| Changelog fragment tools (e.g. towncrier) | The opposite design choice: they split entries into separate files to *avoid* conflicts, whereas the ledger keeps one file to *force* them |
| Git non-fast-forward rejection | The atomic compare-and-swap behind deferred option B |
| ocicl, Quicklisp | Dependency management (COMPASS-DRAFT-toolchain-D8); ocicl's lockfile and local-only mode for reproducible CI |
| ocicl, pgloader | Command-line tools built with SBCL and distributed as standalone executables to users who need not know Lisp; ocicl's per-platform CI matrix (COMPASS-DRAFT-toolchain-D19) |
| Linters distributed as binaries (e.g. ShellCheck, golangci-lint) | A setup action, a container image, and a `pre-commit` hook as the usual routes into other projects' CI (COMPASS-DRAFT-toolchain-D19) |
| Operator Memory | A catalog delivered at session start, `Read If` routing, and a codebase index (D10–D14). Its agent-maintained, untyped, present-tense-only model is not imported ([COMPASS-DRAFT-operator-memory](Survey.OperatorMemory.md)) |
| Emacs library headers | The `;;; file.el --- description` first line that the source-header summary line generalises (D14) |
| `llms.txt` | A compact, LLM-oriented summary of a site; a static precursor of the session catalog |
| DCTERMS, PROV-O, SKOS, SHACL, DOAP, SIOC | The vocabularies the semantic binding reuses (D17) |

## Roadmap

Steps 2 and 3 yield baseline v0.1, step 4 with the CI and distribution parts of
step 7 yields v0.2 and v0.2.1, and the export part of step 5 yields v0.3 (see
[Baseline releases](#baseline-releases)).

1. **This Plan.** Record the decisions and gaps. No change to `Compass.md` yet.
2. **Skeleton, front end, and model.**
   - `compass.asd`, `compass.sexp`, `ocicl.csv`, the `Makefile`, and `.gitignore`.
   - The strict YAML-subset parser (D18) and front-matter typing; the body
     scanner; the model.
   - Unit tests.
   - The project builds under both `DEPS=ql` and `DEPS=ocicl`.
   - The code constraints of D19 from the first commit: no native libraries, a
     self-contained executable, explicit UTF-8 and CRLF handling, Git invoked
     only with argument lists, and a `compass version` that reports the build.
3. **Validator.**
   - The schema, vocabulary, ID-format, reference, Git-derived-field, §12, and
     section-shape rules.
   - Text and JSON reports.
   - Fixture corpora covering valid and invalid documents.
   - Amend §11/§12 (D6) and §6/§7 (D5).
4. **Git layer, ledger, and allocation.**
   - Code-reference verification; the ledger reader and checks.
   - `next`, `assign`, `renumber`.
   - **Concurrency tests** in temporary Git repositories: both allocation
     orders, conflict on merge, the duplicate-keeping resolution failing
     `check`, and recovery through `renumber`.
   - Amend §8 and §13 (D2, D3, D4, D16).
5. **Index generation and RDF export.** Namespace and federated `INDEX.md`,
   with `index --check`; `compass export --rdf` and `--vocab` (D17), yielding
   baseline v0.3; amend §5, §7, and §17 as the semantic binding requires.
6. **Agent context.** Split by whether the evaluation gates it.
   - **Not gated:**
     - extension-key handling and `read-if:` (D13); the §18 registration;
     - `compass outline` and `show ID#anchor` (delivered in v0.1, with
       `compass refs`; D21);
     - manifest keys `:commands` and `:stewards` (D15);
     - agent-workflow support (COMPASS-DRAFT-agent-workflow): M-records in the
       ledger and `assign`; the `review/approver` rule (the `memo/*` rules
       land in v0.1); `compass diff`; `Assisted-by:` trailer derivation.
   - **Gated on the pilot of
     [COMPASS-DRAFT-agent-context-eval](Eval.AgentContext.md),** and subject to
     its decision rules:
     - the weight function (D12) and the §6 and §8 amendments it carries;
     - `compass catalog` and the manifest's `:catalog` key (D11);
     - the source-header extractor, `compass map`, the `:map` key, and the
       Spec's rules (D14); the §2 clarification.
   - Fixture repositories covering inheritance, ASDF load order, budget
     truncation, one-hop federation, memo hosts, and solo and second-reviewer
     namespaces.
7. **CLI, CI, hooks, and distribution.**
   - The executable, and `compass init`.
   - The GitHub Actions matrix (Quicklisp + ocicl, both required).
   - An optional pre-commit hook that regenerates the index, catalog, and map.
   - Documented branch-protection and `CODEOWNERS` settings.
   - **Distribution (D19)**, in this order:
     - a spike of about a day on the macOS and Windows runners, to confirm that
       an unsigned SBCL executable builds, runs, and invokes Git there, and to
       measure the archive sizes;
     - the release workflow for the four targets, with the old-glibc container
       for Linux, `SHA256SUMS`, and build provenance attestations;
     - the setup action, the container image, and the `pre-commit` hook
       definition;
     - installation instructions for unsigned executables on macOS and Windows.
       Signing and notarization follow later.
8. **Integration and bootstrap.**
   - Wire `compass-author` to `check`, `next`, and later `assign`;
     `compass-review` to `check` and `rules`; and `compass-lookup` to `show`,
     `outline`, `refs`, and `index --stdout`. Done for v0.1 (2026-10-08), in
     COMPASS-DRAFT-authoring-assistance's roadmap step 6; `assign` follows
     with v0.2.
   - Lift COMPASS-D2.
   - Seed the COMPASS ledger (D9), add front-matter to `Compass.md`, relabel the
     §23 rows, and run `compass check` on this repository in CI.
   - Give the toolchain's own sources conforming headers, and commit this
     repository's `CATALOG.md` and `MAP.md`.
