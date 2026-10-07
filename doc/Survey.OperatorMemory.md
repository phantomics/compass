---
id:            COMPASS-DRAFT-operator-memory
title:         Operator Memory and Compass as Agent Context
genre:         Survey
scope:         program
program:       Compass
component:     authoring-assistance
language:      en
status:        Draft
authors:
  - Sloane
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-0001
  - COMPASS-DRAFT-authoring-assistance
  - COMPASS-DRAFT-toolchain
  - COMPASS-DRAFT-source-headers
  - COMPASS-DRAFT-agent-workflow
  - COMPASS-DRAFT-agent-context-eval
cites:
  - title:     "Agents Don't Need Memory. They Need Documentation. (Kevin Liao, 2026-10-03)"
    locator:   https://liao.gg/blog/agents-dont-need-memory
    external:  true
  - title:     Operator Memory repository (aerovato/operator-memory)
    locator:   "README.md@e394f1c"
    external:  true
  - title:     Operator Memory injected preamble and tenets
    locator:   "packages/core/src/prompts/preamble.ts@e394f1c"
    external:  true
  - title:     Operator Memory preamble assembly
    locator:   "packages/core/src/preamble.ts:renderPreamble@e394f1c"
    external:  true
  - title:     Operator Memory OpenCode V2 adapter
    locator:   "packages/opencode-v2/src/index.ts@e394f1c"
    external:  true
  - title:     Operator Memory architecture and troubleshooting docs
    locator:   "docs/architecture.md, docs/troubleshooting.md@e394f1c"
    external:  true
open-questions:
  - COMPASS-DRAFT-operator-memory-O1
  - COMPASS-DRAFT-operator-memory-O2
  - COMPASS-DRAFT-operator-memory-O3
  - COMPASS-DRAFT-operator-memory-O4
  - COMPASS-DRAFT-operator-memory-O5
  - COMPASS-DRAFT-operator-memory-O6
---

# Operator Memory and Compass: Survey

This survey compares Operator Memory with Compass as ways of giving coding
agents durable project context. Operator Memory is a plugin that gives an agent
a "brain" of Markdown documents. Compass is the documentation standard defined
in [COMPASS-0001](../Compass.md). The survey asks which of Operator Memory's
features Compass should later import, in what form, and which it should
decline. It assumes the authoring-assistance layer
([COMPASS-DRAFT-authoring-assistance](Plan.AuthoringAssistance.md)) and the
validation toolchain ([COMPASS-DRAFT-toolchain](Plan.Toolchain.md)). The
findings come from reading the Operator Memory blog post, documentation, and
source at commit `e394f1c`. Operator Memory was not run, and no agent
behaviour was measured. Like any Survey, this document is exploratory and
non-normative. Each import it recommends would arrive as its own Plan or
amendment (§13).

## Motivation

Persistence of context across agent sessions is within Compass's mandate. §23
(prior-art notes for O3, pattern 5) names "LLM-as-consumer" as a real design
goal: a typed corpus serves end users, LLM coding assistants, and LLM user-task
assistants from a single source. So far Compass has addressed that consumer only
indirectly. It produces structure, stable identifiers, and typed metadata, all
of which help an agent, but it has no mechanism that puts the corpus in front of
an agent or keeps it current while the agent works.

Operator Memory is an independent, working answer to the same problem, and it
starts from the same premise: durable, readable documents rather than
retrieved snippets. It has been in daily use by its author for over a year and
supports six agent harnesses, OpenCode among them. Comparing the two now,
before the toolchain is built, lets anything Compass decides to import shape
the toolchain's outputs (the index generator in particular) rather than be
bolted on afterward.

## Operator Memory in brief

**Thesis.** The blog post argues that "memory" plugins are all the same RAG
pipeline. They capture snippets from transcripts, embed them, and inject the
top matches on each prompt. That pipeline fails for structural reasons:
- Similarity is not correctness or currency.
- Snippets lose context.
- Past conversation is treated as truth.
- Agents "can't search for what they don't know."
- The store cannot be audited.

The proposed replacement is "document-based memory". It changes the agent loop
from *prompt → build → forget* to *prompt → consult → build → update*.

**Layout.** The "brain" lives in three partitions:
- `.operator/`: private project knowledge, git-ignored globally.
- `.operator-shared/`: committed project knowledge for the team.
- `~/.operator/user/`: personal and cross-project knowledge.

Each partition has an `operator.md` of standing instructions (described as "a
more sophisticated `AGENTS.md`") and a `catalog.md` listing its documents.
Project partitions also have an `index/` tree that maps the codebase. All other
documents are freeform; `specs/`, `guides/`, and `product/` are suggested but
not enforced.

**Metadata.** Only index files carry front-matter, and it has two fields:
`description` and `read_if`. Catalog entries carry the same two fields as
bullets. Freeform documents have no schema, identifier, status, or date.
Code references are plain paths.

**Delivery.** At session start each harness adapter injects a fixed preamble.
The preamble consists of:
- roughly 16 KB of protocol text;
- every partition's `operator.md`;
- every `catalog.md`;
- the main project index body;
- a listing of the subindexes with their `description`/`read_if` lines;
- the tenets.

Nothing else is loaded automatically. The agent opens a document when its
"Read If" matches the task. The OpenCode V2 adapter does this through a session
`context` hook that pushes the text into the system prompt. The preamble is
cached for the session. If any partition fails to load, Operator Memory loads
no memory at all and injects a diagnostic in its place.

**Maintenance.** Keeping the brain current is the agent's job, driven entirely
by the preamble's instructions:
- "Consult before you build; update after you build."
- "Do not document anything already evident from the code."
- Rewrite the canonical document "in the present tense", and delete or convert
  plans when they are done.

Precedence on conflict is "Project Private > User > Project Shared." No hook
checks whether an update actually happened, and the README roadmap still lists
"Reliable Brain Updates" as unbuilt.

**Enforcement.** Enforcement is narrow:
- An index linter checks front-matter presence and private-path leaks.
- A load check covers the files the preamble requires.

The troubleshooting guide is explicit that "structural checks confirm format
only — they do not judge whether an index is accurate or current."

## The shared thesis

Both systems hold that agent context should be **curated documents under
version control, readable by humans**, not an opaque store of recalled
fragments. Both reject vector stores and similarity retrieval as the primary
mechanism. Both treat Git as the medium for sharing knowledge with a team. The
blog post amounts to an independent, practitioner-side statement of Compass's
§23 pattern 5. That agreement is the main finding of this survey: the two
projects are not rival philosophies.

## Where the approaches diverge

Table: Operator Memory and Compass compared along the dimensions that matter
for agent context.

| Dimension | Operator Memory | Compass |
|---|---|---|
| Primary concern | Delivery and upkeep: what the agent sees, when it reads, when it writes | Content model: what documents are, how they relate, how they mature |
| Document typing | Implied by location; freeform documents untyped | Ten genres with subtypes, scope axis, controlled status (§4–§6) |
| Identity | File path | Permanent `<NS>-<NNNN>`, stable across renames and genre changes (§5) |
| Treatment of time | Present tense only; superseded content is rewritten or deleted | Typed history: Logs, ADR-shaped decision records with alternatives, `Superseded`, identifiers never reused (§6, §8, §13) |
| Code references | Plain paths, which go stale silently | Commit-pinned `path:symbol@revision` (§9) |
| Session-start context | Instructions, catalogs, and main index injected deterministically | None; the corpus is consulted only if the agent thinks to |
| Relevance routing | `Read If` condition on every catalog and index entry | No routing field; title, genre, component, and status are available |
| Codebase map | Hierarchical, agent-maintained index | `Project Structure` section of a `Ref`; otherwise out of scope |
| Who writes, who approves | The agent writes freely; private by default | Human editorial review for project and program scope (§6) |
| Validation | Index front-matter lint and load checks | Full §22 rule set (planned in [COMPASS-DRAFT-toolchain](Plan.Toolchain.md)) |
| Cross-repository knowledge | Per repository; cross-project knowledge only in a private per-machine partition | Federation of namespaced repositories is a core design goal (§10) |
| Harness support | Six adapters, shipping today | OpenCode skills shipping; other harnesses planned (§23 S9) |

The short version: **Operator Memory is a delivery and upkeep mechanism with
almost no content model, and Compass is a content model with almost no delivery
mechanism.**

## What Operator Memory does better

1. **It answers "agents can't search for what they don't know."** This is the
   blog post's sharpest point, and it applies directly to Compass.
   `compass-lookup` resolves `PSYCHE-D16` only if the agent already suspects
   such a record exists. Operator Memory puts a compact catalog in front of
   every session, so the agent knows what exists before it begins. Compass
   plans a federated `INDEX.md` (§13) but has no way to deliver it.
2. **It makes the loop explicit and mandatory.** Consult → build → update is
   written into the injected protocol as a required workflow. Compass's
   maturity ladder implies the same loop:
   - consult the `Plan`, `Spec`, `Ref`, and accepted decisions;
   - build;
   - record the work in a `Log` and revise the `Ref` or `Spec`.

   Nothing instructs an agent to follow that loop. `compass-author` scaffolds
   new documents but does not maintain existing ones.
3. **It keeps documentation cheap.** "Do not document anything already evident
   from the code," keep documents lean, and prefer editing sentences to adding
   paragraphs. Compass's ceremony suits a durable record: front-matter,
   decision records, review. It is too heavy for the small durable facts an
   agent learns each session, and those facts are currently lost.
4. **It routes by condition rather than by topic.** A `Read If` line ("Working
   in packages/core or changing memory loading") tells an agent *when* a
   document matters. A title tells it only what the document is about. The
   first is what routing actually needs.
5. **It provides a codebase map.** The agent-maintained hierarchical index
   (path, role, "Read If") gives an agent a navigational primer before it
   explores. A repository documented with Compass still sends its agent into
   the source cold.
6. **It fails loudly when memory cannot load.** If memory fails to load, the
   agent is told so and directed to fix it. It does not quietly proceed with a
   partial view.

## Where Compass is stronger

1. **Typed history versus deletion.** The blog post's complaint that "the past
   is treated as truth" is real. Operator Memory resolves it by deleting the
   past. Compass resolves it by labelling the past:
   - a `Log` is explicitly history;
   - a `Ref` with status `Current` is present truth;
   - a `Superseded` document names its successor.

   Rationale, rejected alternatives, and lineage survive, which present-tense
   rewriting throws away. The condition is that an agent must be told how much
   weight each genre and status carries; see
   [Candidate imports](#candidate-imports).
2. **Federation.** Operator Memory cannot express "`PSYCHE-D16` constrains
   Origin's orbital design". Its knowledge is scoped to one repository, plus one
   private machine. Namespaced identifiers and a federated index are what a
   multi-project program (classic, origin, lexter, lexis, psyche) needs.
3. **Durable references.** Commit-pinned code references remain verifiable.
   Path references rot without any signal.
4. **Deterministic conformance.** Once the §22 toolchain exists, Compass will
   check structure, vocabulary, identity, and reference integrity across the
   whole corpus. Operator Memory checks index front-matter only.
5. **Metadata that enables ranking.** Operator Memory cannot rank documents by
   authority or filter out stale ones, because it records no status. Compass's
   genre × status matrix makes both possible, which matters for the imports
   below.

## Ontology sketch

Table: Operator Memory concepts mapped onto their nearest Compass analogues,
with the gap each mapping exposes.

| Operator Memory concept | Nearest Compass analogue | Gap |
|---|---|---|
| `operator.md` (standing instructions) | Root `AGENTS.md` with `templates/AGENTS.snippet.md` | Compass covers documentation conventions only, not general working rules; arguably correct (§2) |
| `catalog.md` (brain map with Read If) | Generated namespace and federated `INDEX.md` (§13, planned) | No routing field; not delivered at session start |
| `index/` (codebase map) | `Ref` `Project Structure` section | No agent-maintained, navigation-oriented map |
| `specs/` (system truth) | `Spec` and `Ref` with status `Current`; accepted decision records | None; Compass is richer here |
| `guides/` (third-party knowledge, how-tos) | `Guide` (`tutorial`/`howto`) | Compass `Guide` targets the project's own software, not research notes on foreign libraries |
| Research notes | `Eval` (prior-art) and `Survey` | Compass versions are heavier; no lightweight research note |
| Plans ("delete when done") | `Plan` that becomes `Implemented`, with a `Log` | Compass keeps the plan; correct for the record |
| Private partition (`.operator/`) | None; disposable scratch is a §2 non-goal | Durable but unpublished knowledge has no home |
| User partition (`~/.operator/user/`) | None | Cross-project personal conventions have no home (arguably correct) |
| Precedence rule (Private > User > Shared) | None | No authority model for agent consumption |
| Load diagnostic | `compass check` findings (planned) | Findings are not surfaced to the agent at session start |

## Candidate imports

These are candidates only. Each is listed with the form it would take in
Compass, the work it depends on, and its likely amendment class under §13
(patch = editorial, minor = additive, major = breaking). The order is the
suggested order of import.

Table: Candidate imports from Operator Memory, with Compass form, dependency,
and amendment class.

| # | Candidate | Compass form | Depends on | Amendment class |
|---|---|---|---|---|
| 1 | Session-start catalog | A compact catalog generated from front-matter and the ledger, injected by a harness adapter (an OpenCode plugin using the session `context` hook) | Toolchain index generation; manifest for federation scope | None to core; an S9 deliverable |
| 2 | Relevance routing field | Optional `read-if:` front-matter key, as a §18 extension first and promoted to core if it proves its worth | Validator support for extension keys | Extension, then minor |
| 3 | Authority ranking | A normative table of how much weight each genre × status combination carries for current behaviour, used by the catalog and the skills | None | Patch or minor |
| 4 | Consult → build → update loop | Protocol text in the injected catalog and the AGENTS snippet; a maintenance skill (or an extended `compass-author`) that, after work, proposes the `Log` and the `Ref`/`Spec` revisions it implies | Candidates 1 and 3 | None to core; S9 |
| 5 | Lean-writing discipline | "Do not restate what the code shows" guidance in templates, the `compass-review` rubric, and §14 | None | Patch |
| 6 | Load and conformance diagnostics | The injected catalog carries a summary of `compass check` errors, and refuses to present a corpus as authoritative if it cannot be read | Toolchain check and JSON report | None to core |
| 7 | Codebase map | Either a navigation-oriented `Ref` subtype or a ceded, Operator-style index outside Compass | Decision on O3 | Minor (new subtype) or none |
| 8 | Unpublished working knowledge | Either coexistence (Operator Memory's private partition beside Compass's published `doc/`) or a lightweight Compass note genre | Decision on O4 | None, or minor/major (new genre) |

### The authority ranking (candidate 3), sketched

Table: A first sketch of how much weight each genre and status carries when an
agent reasons about current behaviour.

| Weight | Documents | Agent treatment |
|---|---|---|
| Authoritative | `Spec`, `Ref`, `Guide` with status `Current`; decision records with status `Accepted`; `Arch` with status `Design-Record` (for design intent) | Present truth; the code should agree, and disagreement is a finding to raise |
| Directive | `Plan` with status `Accepted`; `Glossary` with status `Current` | Intended direction and binding terminology |
| Contextual | `Log`, `Eval`, `Survey`, `Plan` with status `Implemented`, `Ideation` | History and rationale; explains *why*, never overrides authoritative documents |
| Provisional | Any document with status `Draft`, `Proposed`, or `In-Review` | Work in progress; cite with caution |
| Excluded | `Deprecated`, `Superseded`, `Rejected`, `Withdrawn` | Not used for current behaviour; follow `superseded-by` instead |

This ranking is what lets Compass keep its history *and* avoid the "past
treated as truth" failure. It is also what a status-filtered session catalog
would use to stay small. Excluded documents can be left out of the injected
catalog entirely, which bounds one of Operator Memory's open scaling problems.

### What not to import

- **Present-tense-only rewriting and deletion of plans.** It destroys rationale
  and contradicts §13's never-reuse, never-delete discipline. Typed status
  achieves the same currency without the loss.
- **Untyped freeform documents.** Typing is what makes ranking, filtering,
  validation, and derivation possible.
- **Unbounded, flat catalog injection.** Operator Memory injects every catalog
  in full with no cap, and "No catalog subindexes." A Compass catalog should be
  filtered by authority and scoped by namespace and component.
- **Path-only references.** They are superseded by §9's commit-pinned form.
- **Agent self-approval of shared truth.** Operator Memory's agent writes
  shared documents directly. Compass keeps human editorial review (§6) for
  project and program scope. The agent proposes and the human disposes,
  consistent with §22.

## What would be new work

- A **catalog renderer** in the toolchain: a compact, size-bounded, ranked view
  of one namespace or a federation, emitted as Markdown for injection and as
  JSON for adapters. It is a natural sibling of `compass index`.
- An **OpenCode adapter** (a plugin) that injects the catalog at session start,
  with the same deterministic, cached-per-session behaviour as Operator
  Memory's, plus adapters for other harnesses later (§23 S9).
- **Protocol text** for the consult → build → update loop, written for
  Compass's typed corpus and placed in the catalog preamble and the AGENTS
  snippet.
- A **maintenance skill** that turns a finished change into a proposed `Log`
  and proposed `Ref`/`Spec` revisions, for human review.
- **Standard amendments:** the authority table, the `read-if:` extension, and
  lean-writing guidance in §14.
- An **evaluation** of whether the injected catalog changes agent behaviour
  (see O6). Neither project has one.

## The deeper claim

A corpus is memory only if it is *delivered* and *maintained*. Delivery is
reliable only if the content is *typed*. Operator Memory has the first half:
deterministic delivery and an explicit upkeep loop. Because its documents carry
no status, it cannot tell current truth from history except by deleting
history. Compass has the second half: genre, status, identity, and lineage. It
has no path into an agent's context. Importing Operator Memory's delivery and
loop into Compass produces something neither has alone: a status-filtered,
authority-ranked, federated catalog delivered at session start, over a corpus
that keeps its history without letting history masquerade as present truth.
The typing Compass already pays for is what makes the delivery affordable and
correct.

## Honest Limits

- **No empirical basis.** Every comparative claim here comes from reading code
  and documentation at one commit. Neither system has published measurements of
  agent behaviour. Operator Memory's evidence is one author's year of use, and
  its tests verify prompt assembly, not agent conduct.
- **Compass's delivery side is hypothetical.** The toolchain, index generator,
  and adapters these imports depend on do not exist yet.
- **Ceremony may suppress updates.** Operator Memory's authors report that
  agents already "prefer the status quo" and must be steered to create or split
  documents. Compass's heavier front-matter and review requirements may make
  agents even less willing to update. Candidate 4 must keep the update path
  cheap, or it will not be used.
- **Context cost.** Any session-start injection spends tokens on every session,
  relevant or not. Operator Memory's roughly 16 KB protocol plus catalogs is the
  reference point. A Compass catalog must stay within a stated budget.
- **Overlap risk under coexistence.** Running Operator Memory's committed
  `.operator-shared/` beside Compass's `doc/` would create two sources of
  project truth. That violates Operator Memory's own rule ("DO NOT create
  multiple sources of truth") as much as Compass's.
- **Snapshot.** Operator Memory is under active development. Its roadmap
  ("Reliable Brain Updates", context management) may close some of the gaps
  noted here.

## Relationship to Other Work

- [COMPASS-0001](../Compass.md):
  - §2 declares disposable scratch a non-goal; candidate 8 revisits where
    durable-but-unpublished knowledge belongs.
  - §18 is the mechanism for the `read-if:` extension.
  - §22 frames assistance as proposing while the toolchain disposes.
  - The §23 prior-art notes (pattern 5) anticipated this survey's subject.
- [COMPASS-DRAFT-authoring-assistance](Plan.AuthoringAssistance.md):
  - The catalog adapter and maintenance skill extend this S9 layer.
  - COMPASS-O1 (advisory-mode signalling) and COMPASS-O3 (provenance depth)
    bear directly on agent-written updates.
- [COMPASS-DRAFT-toolchain](Plan.Toolchain.md):
  - Index generation is the natural home for the catalog renderer.
  - The project manifest supplies federation scope.
  - The JSON report supplies the diagnostics for candidate 6.
- `templates/AGENTS.snippet.md` is Compass's current, static analogue of
  `operator.md`. It routes documentation work to the skills but delivers no
  corpus content.
- External work:
  - `AGENTS.md` and Cursor rules (static instruction files).
  - `llms.txt` (LLM-oriented site summaries).
  - The RAG memory plugins that the blog post argues against.

## Open Questions

### COMPASS-DRAFT-operator-memory-O1 — Import, coexist, or both

Should Compass import Operator Memory's delivery and loop natively (candidates
1–6)? Should it instead recommend running Operator Memory alongside, with a
defined boundary: private partition for working knowledge, Compass `doc/` for
the published record, no `.operator-shared/`? Or both, with coexistence as the
interim arrangement until native delivery exists?

**Resolution (2026-10-07):** Import only. Compass adopts the parts of Operator
Memory that serve its goals, in Compass's own form, and does not recommend
running the two side by side, since parallel models of project truth would
diverge. No `.operator*` directories or `operator.md` are adopted. Recorded in
[COMPASS-DRAFT-toolchain](Plan.Toolchain.md) as COMPASS-DRAFT-toolchain-D10.
One consequence: O4 can no longer be answered by deferring to Operator Memory's
private partition, and needs an answer inside Compass.

### COMPASS-DRAFT-operator-memory-O2 — Shape and budget of the session catalog

What does each catalog entry contain (id, title, genre, status, component, a
`read-if:` line)? What is the size budget? How is a federation scoped down to
what a given session needs: by the current repository's namespace, by
components named in the task, or by authority level? Excluding `Excluded`
documents is the obvious first cut.

**Resolution (2026-10-07):** Entries carry id, title, genre, status, component,
size, and a `read-if:` line. The catalog lists metadata only, never document
bodies. It covers the current namespace plus documents one hop out, leaves out
Excluded documents, has a compact section of accepted decisions, and has a
default budget of 8 KB. It is generated and committed rather than built at
session start. Recorded in [COMPASS-DRAFT-toolchain](Plan.Toolchain.md) as
COMPASS-DRAFT-toolchain-D10 to COMPASS-DRAFT-toolchain-D13 and
COMPASS-DRAFT-toolchain-D15.

### COMPASS-DRAFT-operator-memory-O3 — Is a codebase map a Compass concern?

A navigational map of the source tree is high value for agents. It is also
close to "auto-generated API reference", which §2 cedes. Should Compass add a
navigation-oriented `Ref` subtype (agent-maintained, validated against the file
tree)? Or should it treat the map as out of scope and point to tools such as
Operator Memory's index?

**Resolution (2026-10-07):** A per-file navigation map is in scope;
symbol-level API reference stays ceded (§2). The map is generated
deterministically, never by an LLM, from a standard header comment in each
source file and optional directory READMEs. It is not a `Ref` subtype. The
header convention is specified in
[COMPASS-DRAFT-source-headers](Spec.SourceHeaders.md), and its implementation is
recorded in [COMPASS-DRAFT-toolchain](Plan.Toolchain.md) as
COMPASS-DRAFT-toolchain-D14.

### COMPASS-DRAFT-operator-memory-O4 — A home for durable but unpublished knowledge

Agents learn durable facts that do not merit a reviewed Compass document, such
as a library quirk, an environment detail, or a debugging lesson. §2 calls this
"disposable scratch", but much of it is neither disposable nor scratch. Should
Compass define a lightweight, unreviewed, private note genre? Should it cede
the layer entirely to an Operator-style private partition? Or should it let
such notes accumulate and be promoted into typed documents through the
maturity ladder?

**Resolution (2026-10-07):** Add a **Memo** genre (prefix `Memo.`, code `ME`)
for verified, present-tense properties of existing software whose understanding
is key to working on it. It is not a scratchpad: a memo must be durable,
consequential, not evident from the code, and grounded in checkable evidence.
Memos are numbered records (`<NS>-M<n>`) in a host document, normally one per
component, so each keeps its own identity, status, routing line, catalog entry,
and supersession without one file per memo. A `Current` memo is Authoritative,
and memos may later be folded into a `Ref`. Recorded in
[COMPASS-DRAFT-agent-workflow](Plan.AgentWorkflow.md) as
COMPASS-DRAFT-agent-workflow-D1 to COMPASS-DRAFT-agent-workflow-D4.

### COMPASS-DRAFT-operator-memory-O5 — Agent authority to update typed documents

If an agent proposes revisions to a `Ref` with status `Current` or a `Spec`
after its work, who applies them? A component-scope `Log` may be self-accepted
(§6). Project- and program-scope documents need a second reviewer. Is
there a lighter review path for agent-proposed corrections to reference
documents? And how does `provenance:` record per-edit assistance (cf. §23 P2)?

**Resolution (2026-10-07):** No lighter path. Changes to project- and
program-scope documents are always reviewed by a human: an agent proposes, and a
human commits or approves the change. Moving any document or memo into an
authoritative status needs a human `approved-by`, and an agent never sets it.
Purely mechanical rewrites (identifier assignment, link repair) pass review
without reopening acceptance. A namespace's steward, declared in the manifest as
a solo maintainer, may approve their own documents. Per-edit assistance is
recorded in `Assisted-by:` commit trailers and derived from Git, leaving
`provenance:` to record a document's origin. Agents' permissions are tabulated
by scope, and a `compass-maintain` skill proposes the updates a change implies.
Recorded in [COMPASS-DRAFT-agent-workflow](Plan.AgentWorkflow.md) as
COMPASS-DRAFT-agent-workflow-D5 to COMPASS-DRAFT-agent-workflow-D9.

### COMPASS-DRAFT-operator-memory-O6 — Measuring whether any of this works

Neither project has evaluated agent behaviour. What would a minimal evaluation
look like? For example: a fixed set of tasks run against a repository with and
without the injected catalog, measuring exploration cost, decision-record
consultation, correctness with respect to superseded documents, and whether
updates were made. Could that evaluation be the first rigorous account of
"documentation as LLM context" that §23 says does not yet exist?

**Status (2026-10-07):** Open. Carried forward as
COMPASS-DRAFT-agent-workflow-O1 in
[COMPASS-DRAFT-agent-workflow](Plan.AgentWorkflow.md), as a documented,
repeatable test to be committed to the Compass repository. The protocol is
[COMPASS-DRAFT-agent-context-eval](Eval.AgentContext.md). Since this survey was
written, three 2026 studies have evaluated repository context files
(Gloaguen et al.; Khatri; Chatlatanagulchai et al.) and found no measurable gain
in task success, at over 20% added cost. The premise that no rigorous account
exists, here and in §23, is therefore out of date. Those studies are snapshot
studies of single sessions; the evaluation's primary track tests quality over
many sessions, which they do not measure.
