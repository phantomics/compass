---
id:            COMPASS-DRAFT-positioning
title:         Compass Among Agent-Memory Tools — Positioning the Engineering Record
genre:         Survey
scope:         program
program:       Compass
component:     standard
language:      en
status:        Draft
authors:
  - Andrew Sengul
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-0001
  - COMPASS-0004
  - COMPASS-0005
  - COMPASS-0006
  - COMPASS-0007
  - COMPASS-0008
  - COMPASS-0009
  - COMPASS-0010
  - COMPASS-0014
cites:
  - title:     "Building Up and Reasoning About Architectural Knowledge (Kruchten, Lago, van Vliet; QoSA 2006)"
    locator:   "LNCS 4214, pp. 43–58, abstract; doi:10.1007/11921998_8"
    external:  true
  - title:     "A Comparative Study of Architecture Knowledge Management Tools (Tang, Avgeriou, Jansen, Capilla, Ali Babar)"
    locator:   "Journal of Systems and Software 83(3), 2010, pp. 352–370, §1"
    external:  true
  - title:     "ISO 13485:2016 — Medical devices: Quality management systems, as incorporated by the FDA Quality Management System Regulation (21 CFR 820, effective 2026-02-02)"
    locator:   "Clause 7.3.10, Design and development files; 21 CFR 820.10(c)"
    external:  true
  - title:     "NIST SP 800-218A — Secure Software Development Practices for Generative AI and Dual-Use Foundation Models"
    locator:   "Table 1, SSDF Community Profile"
    external:  true
  - title:     "Coherence (PostHog/coherence)"
    locator:   "README.md, docs/tour.md, Coherence.spec.md, docs/journal.md@36c158f7370b"
    external:  true
  - title:     "LoreConvo (labyrinth-analytics/loreconvo), v0.10.20"
    locator:   "README.md@99114bdc3f67"
    external:  true
  - title:     "Ontology-Grounded Project Memory for Coding Agents (Adam; NeSy 2026)"
    locator:   "arXiv:2608.13662, abstract"
    external:  true
  - title:     "GitHub Spec Kit — Spec-Driven Development"
    locator:   "spec-driven.md; .specify/memory/constitution.md"
    external:  true
  - title:     "Mem0 (mem0ai/mem0)"
    locator:   "Repository description: a memory layer for AI agents"
    external:  true
  - title:     "Letta (letta-ai/letta)"
    locator:   "Repository description: a platform for stateful agents with memory"
    external:  true
  - title:     "Graphiti, by Zep (getzep/graphiti)"
    locator:   "Repository description: real-time knowledge graphs for AI agents"
    external:  true
open-questions:
  - COMPASS-DRAFT-positioning-O1
  - COMPASS-DRAFT-positioning-O2
  - COMPASS-DRAFT-positioning-O3
  - COMPASS-DRAFT-positioning-O4
  - COMPASS-DRAFT-positioning-O5
  - COMPASS-DRAFT-positioning-O6
---

# Compass Among Agent-Memory Tools: Positioning Survey

This survey asks where Compass stands in the crowded field of tools that give
coding agents memory, and how it should describe itself. Its argument is that
Compass is not primarily a memory tool. Its main use is to keep the record of
how software is designed and built, which would otherwise evaporate as agent
sessions turn over; memory for agents is one view of that record, a benefit
rather than the purpose. The survey maps the neighbouring categories, states
what distinguishes Compass today and where it is weak, summarises the planned
work and which of it waits on the evaluation, proposes competency questions
that make the queryable record concrete, and lists directions that would
distinguish Compass further. It draws on the prior art examined in
[COMPASS-0010](Eval.PriorArt.AgentContext.md), including its side-by-side
comparison of Coherence and LoreConvo, and on the agent-context work of
[COMPASS-0004](Plan.Toolchain.md), [COMPASS-0007](Plan.AgentWorkflow.md),
[COMPASS-0008](Spec.SemanticBinding.md), and
[COMPASS-0006](Eval.AgentContext.md). Like any Survey it is exploratory and
non-normative; each direction it recommends would arrive as a Plan decision or
an amendment (§13).

## Motivation

Tools that give agents memory multiplied during 2026: conversational memory
layers such as Mem0, Letta, and Zep's Graphiti; session memory such as
LoreConvo; context files and memory banks; spec-driven development kits;
intent checkers such as Coherence; and typed project memory such as MOOSEDev.
Measured as a memory tool, Compass competes on the terms these tools set: how
little effort capture takes and how well recall works. On both it is weak. Its
capture requires writing typed documents and passing review, and its delivery
to agents (the session catalog) is not yet built.

That measure is the wrong one. Compass began as a standard for the documents a
project produces as it is conceived, decided, built, and maintained
([COMPASS-0001](../Compass.md) §1, §2), and its central value is that the
record survives the people, sessions, and tools that produce it. In
architecture research this loss has a name: architectural knowledge
*evaporates* when design decisions and their rationale stay in people's heads
(Tang et al., 2010). Agent sessions accelerate the evaporation. A session that
settles a design question hundreds of thousands of tokens in, and is then
replaced, takes the reasoning with it unless something records it. Compass is
that something, and agents' memory is one of the things the record serves.

## The neighbouring categories

Table: Categories of tools near Compass, what each keeps, for whom, and for how
long.

| Category | Examples | What it keeps | Main reader | Lifespan of what it keeps |
|---|---|---|---|---|
| Conversational and agent memory | Mem0, Letta, Graphiti (Zep), LoreConvo, Anthropic's memory tool | Facts and episodes extracted from sessions | The agent | As long as the product and its store |
| Context files and memory banks | AGENTS.md, Cline Memory Bank, Operator Memory | Standing instructions and working notes | The agent | Until rewritten |
| Spec-driven development | GitHub Spec Kit, Kiro | Feature specifications, plans, tasks, and a project constitution | The agent, during a feature | One feature |
| Intent checking | Coherence | Component invariants, a lexicon, a journal of agent decisions | The agent, with a human view | The repository |
| Typed project memory | MOOSEDev | Decisions, constraints, rationale in an OWL graph | The agent, through MCP | The graph store |
| Architecture knowledge management and docs-as-code | ADRs and MADR, arc42, research tools since IBIS | Design decisions and rationale | People | The project |
| **Compass** | — | The whole design process, typed and reviewed, as a federated corpus in Git, derivable to a graph | People, agents, and programs | The project, across tools and models |

The honest lineage is that Compass is architecture knowledge management (AKM)
and docs-as-code, rebuilt for the agent era. AKM is an established research
field: Kruchten, Lago, and van Vliet (2006) proposed an explicit, ontology-based
repository of architectural knowledge (design decisions, assumptions, context,
and the reasons a solution is as it is), and Tang et al. (2010) compared the
tools built for it. Agent-memory work rarely cites this field. Placing Compass
in it gives Compass a clearer category than "another memory layer", and a body
of earlier work to build on and be judged against.

## The engineering record

The thesis of this survey: **Compass keeps the engineering record of a
project, and memory is one view of it.** An engineering record, as the term is
used here, is the reviewed account of how a system came to be what it is: what
was explored, what was compared, what was decided and rejected and why, what
was built and verified, how the result works now, and what replaced what. It is
written for whoever works on the project next, whether a person joining it, a
reviewer, a program that queries it, or an agent in a fresh session.

Regulated device development offers an analogy. A medical-device manufacturer
must keep a design and development file for each device type, holding or
referring to the records that show the design was planned, reviewed, verified,
and changed under control (ISO 13485:2016, clause 7.3.10, which the US Food and
Drug Administration's Quality Management System Regulation incorporates from
2026-02-02, replacing the former "design history file"). Compass is a
lightweight, machine-readable counterpart for software. The analogy stops
there: Compass is not, and does not claim to be, a compliance system of record
(§2).

Three consequences follow from the thesis:
- Compass's costs are its features. Typing, review, permanent identifiers, and
  commit-pinned references are what make the record trustworthy and queryable;
  a memory tool would count them as friction.
- Delivery to agents is a derivation, like a README or a user guide (§16, §21).
  It is built from the record and never replaces it.
- Compass should be judged on what only a record can do (answer questions about
  the design process, survive changes of tool and model, serve people who never
  run an agent) as well as on how much it helps agents.

## What distinguishes Compass today

Each point below has partial precedents, recorded in
[COMPASS-0010](Eval.PriorArt.AgentContext.md); what distinguishes Compass is
the combination.

1. **A standard, not a product.** An open specification, versioned and amended
   under governance (§13), with a reference toolchain. Another implementation
   could conform to it. Memory tools are products, and their formats belong to
   them.
2. **A record of the process, not only of conclusions.** The maturity ladder
   runs from Survey through Eval, Plan, and Log to Ref and Spec, and a critique
   (an Eval of subtype `critique`; [COMPASS-0014](Plan.Critique.md)) climbs it
   again for something already built. Rejected alternatives and superseded
   decisions stay in the record, marked as history. Memory tools keep what was
   concluded, and most discard the rest.
3. **Documents that are deliverables.** A Ref, Guide, or Spec is useful to a
   reader who never uses an agent, and READMEs, user documentation, and sites
   can be derived from the corpus (§10, §16, §21). A memory store produces
   nothing but recall.
4. **The record lives in Git with the code.** It is versioned with the commits
   it describes, its code references are pinned to commits, and it outlives any
   harness, model, or vendor. Memory tools tie their content to their store,
   and often to one agent tool.
5. **People are accountable for what becomes authoritative.** Agents propose;
   people commit and accept (COMPASS-D38, COMPASS-D39); assistance is recorded
   per commit (COMPASS-D40). The record can say who decided what, with which
   assistant, approved by whom.
6. **Federation.** Permanent namespaced identifiers make decisions citable
   across a program of repositories. Memory tools are scoped to one person or
   one repository.
7. **Deterministic checking.** No language model sits in the checking path, so
   conformance is reproducible (§22).
8. **A queryable graph without a separately maintained graph.** The RDF binding
   ([COMPASS-0008](Spec.SemanticBinding.md)) derives a graph from documents
   people already write and review. Knowledge graphs maintained beside a
   project tend to decay; this one is regenerated from the record. Queryability
   itself is precedented (OSLC, MOOSEDev); its source is what is distinctive.

## Coherence and LoreConvo

The two tools examined in the third round of
[COMPASS-0010](Eval.PriorArt.AgentContext.md), where they are compared with
Compass side by side, show the range of the field.

- **LoreConvo** keeps episodes of conversation for one person: summaries
  extracted automatically at session end, loaded by score at session start, in
  a local database outside Git, with no review. Its design principle,
  "automation over discipline", is the opposite of Compass's. It operates a
  layer below Compass: what a person discussed, not what a project decided. It
  can coexist with Compass, with the same risk Operator Memory's private
  partition carried ([COMPASS-0005](Survey.OperatorMemory.md)): its decision
  items must not be treated as project truth.
- **Coherence** keeps and checks the intent built into the code: invariants
  verified through language-server references and a witnessed refutation, a
  lexicon of settled and rejected terms, a journal of the agent's decisions with
  their rejected alternatives, and practices delivered just before the act they
  govern. It goes beyond Compass in verifying code against intent, and Compass
  goes beyond it in documents above the code, review, authority, federation,
  and the graph. The two are complementary.

A division of labour between Compass and Coherence suggests itself. Coherence
checks code-level invariants and journals agents' decisions as they work;
Compass holds the reviewed decisions, memos, and documents those invariants
derive from; Coherence's records and specs cite Compass identifiers. The one
point of overlap is the record of decisions. If both are kept without a rule, a
decision can live in two places that disagree. The rule proposed here: an
agent's journal is working evidence, and a decision meant to last is promoted to
a Compass decision record, through `compass-maintain` (COMPASS-D42) and the
acceptance gate (COMPASS-D38). See COMPASS-DRAFT-positioning-O3.

## Where Compass is weak as a memory tool

- **Capture takes discipline.** LoreConvo's premise, that people will not
  maintain a memory, is true of many people. Compass depends on
  `compass-maintain` proposing the updates a change implies, and that skill is
  not built yet.
- **Delivery is not built.** The session catalog and adapter wait on the
  evaluation (see the next section), so the memory benefit is still a design.
- **No verification of code.** Compass checks the structure of its documents.
  Coherence checks code against stated intent; Compass's source-header
  invariants are prose.
- **One adopter.** The standard has one steward and one user so far (§23, GO2).

None of these weakens the argument for the record; each is an argument against
competing on recall.

## Planned work, and what waits on the evaluation

Much of what would make Compass useful to agents is planned but deliberately
not built until the evaluation's pilot ([COMPASS-0006](Eval.AgentContext.md))
has run, because the 2026 studies of context files found that delivering
context did not reliably improve task success
([COMPASS-0010](Eval.PriorArt.AgentContext.md)). The pilot's decision rules can
change or remove the gated items. Other work proceeds independently, and some
of it must exist before the pilot can run.

Table: State of the planned agent-facing work, with the decisions that define it.

| Item | Defined by | State |
|---|---|---|
| Allocation ledger, `compass assign` and `renumber`, provisional records in numbered documents | COMPASS-D5 to COMPASS-D7, COMPASS-D26 to COMPASS-D29 | Built (v0.2) |
| `compass show`, `outline`, `refs`; memo record rules; the critique subtype; the `compass-adopt` skill | COMPASS-D25, COMPASS-D35, COMPASS-0014 | Built |
| RDF export of the corpus, with vocabulary and shapes | COMPASS-D21 | Planned for v0.3; not gated |
| Change classification (`compass diff`), assistance history from commit trailers, the approver rule | COMPASS-D38 to COMPASS-D40 | Planned; not gated |
| The `compass-maintain` skill and the consult → build → update protocol | COMPASS-D42 | Planned; **needed by the pilot**, whose fourth relay condition uses it |
| Seed corpora and the evaluation harness | COMPASS-0006 | Planned; **needed by the pilot** |
| The session catalog, including unreviewed memos | COMPASS-D15, COMPASS-D44 | **Gated on the pilot** |
| Authority weight by genre and status | COMPASS-D16 | **Gated on the pilot** |
| Source-header extraction and the source map | COMPASS-D18 | **Gated on the pilot** |
| The session adapter that delivers the catalog | COMPASS-D43 | **Gated on the pilot**; built after it |
| Resolving whether the workflow helps | COMPASS-O23 | After the full evaluation |

For positioning, the table says this: the parts of Compass that serve the
engineering record are largely built or not gated, while the parts that serve
agent memory are mostly gated. Compass can describe itself honestly today as a
record with a planned, evaluated memory view, and should not describe itself as
a memory tool until the evaluation has spoken.

## The queryable design record

Ontology engineering defines a vocabulary by the questions it must answer, its
*competency questions*. The questions below are ones a typed design record can
answer and similarity retrieval cannot, because they turn on status,
supersession, negation, completeness, provenance, or federation. They are
proposed as the acceptance test for the RDF export (COMPASS-D21): each should
be answerable by a published SPARQL query over an exported corpus.

Table: Competency questions for the queryable design record, with the data each
needs.

| # | Question | Needs |
|---|---|---|
| CQ1 | Which accepted decisions are hosted by, or relate to, a document that has since been superseded? | v0.3 export |
| CQ2 | What is the full supersession chain behind a given decision or document? | v0.3 export |
| CQ3 | Which open questions are unresolved, in which namespace, and how long since their host last changed? | v0.3 export |
| CQ4 | Which designs were rejected, in which decisions, and has a later decision adopted one of them? | Record text (`--with-text`) |
| CQ5 | Which accepted decisions record no alternatives at all? | Record text; sharper with the "nothing rejected" convention (candidate 9) |
| CQ6 | Which source files cite a decision that is no longer current? | Source-map triples (gated) |
| CQ7 | Which security-boundary files name no tests? | Source-map triples (gated) |
| CQ8 | Which current memos rest on evidence pinned to a revision more than a given number of commits old? | v0.3 export, with Git |
| CQ9 | Which documents were revised with AI assistance, and who approved them? | History export (`--history`); trailer derivation (COMPASS-D40) |
| CQ10 | Which documents were approved by their sole author under solo approval? | v0.3 export |
| CQ11 | Which decisions in one namespace are cited by documents in another? | Federated export |
| CQ12 | Which Plans are marked Implemented but have no related Log? | v0.3 export |
| CQ13 | Which critique findings are still open, at which severity? | Binding extension for critiques (see below) |
| CQ14 | Which external works are cited, and by which documents? | v0.3 export |
| CQ15 | Which accepted documents relate to documents that are still drafts? | v0.3 export |
| CQ16 | What has the project decided about a component, in order, including what each decision replaced? | v0.3 export |

Two of them as queries over the binding's vocabulary:

```sparql
PREFIX compass: <https://w3id.org/compass/vocab#>
PREFIX cstatus: <https://w3id.org/compass/status#>
PREFIX dcterms: <http://purl.org/dc/terms/>

# CQ12: Plans marked Implemented with no related Log
SELECT ?plan WHERE {
  ?plan a compass:Plan ; compass:status cstatus:Implemented .
  FILTER NOT EXISTS { ?log a compass:Log ; dcterms:relation ?plan }
  FILTER NOT EXISTS { ?plan dcterms:relation ?other . ?other a compass:Log }
}
```

```sparql
PREFIX compass: <https://w3id.org/compass/vocab#>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX prov:    <http://www.w3.org/ns/prov#>

# CQ10: documents approved by their sole author under solo approval
SELECT ?doc ?approver WHERE {
  ?doc compass:acceptance ?act ; dcterms:creator ?approver .
  ?act compass:approvalMode compass:SoloApproval ;
       prov:wasAssociatedWith ?approver .
  FILTER NOT EXISTS { ?doc dcterms:creator ?other . FILTER (?other != ?approver) }
}
```

Description: the first query lists Plans whose status is Implemented and which
no Log relates to in either direction. The second lists documents accepted under
solo approval whose approver is also their only author.

CQ13 exposes a gap. The binding predates the critique subtype: its subtype
scheme has no `critique` value, and it maps none of a finding's fields
(`**Severity:**`, `**Resolution:**`), so whether a finding is open cannot yet be
queried. Extending COMPASS-0008 for critiques, and for the Memo genre's fields
where they are missing, is a prerequisite of the export.

**Process analytics.** Once the record is a graph with history, the design
process itself becomes measurable, a capability for people (engineering leads,
reviewers, researchers) that no memory tool targets:
- the lifetime of decisions, from allocation to supersession;
- the age of open questions and of critique findings, and how they are resolved;
- the share of source files whose headers cite a rationale;
- the share of changes made with recorded AI assistance, and how they were
  reviewed;
- how often Plans are revised or superseded after Logs report on them. Whether a
  Log *contradicts* its Plan is a judgement, not a query, and belongs to review.

## Candidate directions

Each is listed with its form, what it depends on, and its likely amendment class
under §13. The first eight distinguish Compass as a record; the rest are ideas
taken from Coherence and LoreConvo.

Table: Candidate directions, with form, dependency, and amendment class.

| # | Direction | Form | Depends on | Class |
|---|---|---|---|---|
| 1 | Competency questions as the export's acceptance test | A query set published with the toolchain; a test per question | COMPASS-D21 | None to core |
| 2 | Process analytics | Documented queries over an export with history | COMPASS-D21, COMPASS-D40 | None to core |
| 3 | Capture adapters: "capture automatically, accept deliberately" | Importers that turn Coherence journal decisions, LoreConvo memory items, and existing ADR folders (MADR, log4brains) into *draft* Compass records for review | COMPASS-D38 | None to core |
| 4 | An MCP server over the record | `show`, `refs`, `outline`, and later SPARQL, for any agent tool | COMPASS-D21 for SPARQL | None to core |
| 5 | Derivations people use | README compilation (§23 S7), user documentation (S5), the federated site (S8) | Existing plans | None to core |
| 6 | Accountability for AI-assisted work | Queries over acceptance activities and assistance history, presented as supporting material in the sense of SP 800-218A, never as a compliance record (§2) | COMPASS-D40, COMPASS-D21 | None to core |
| 7 | Evidence | The pilot and full study of COMPASS-0006, published with null results | The harness | None |
| 8 | Maturity as a standard | The vocabulary registered at w3id, a conformance test suite, a second adopter or implementation | — | Patch at most |
| 9 | "Nothing rejected" kept apart from "never examined" | A decision record's Alternatives section either lists alternatives or states that none were considered; a missing section means the question was not examined. Checked by `compass-review` | — | Minor (§8) |
| 10 | Rejected terms in the Glossary | Each term may list rejected names with reasons; a rule warns where a rejected name appears in documents or source headers | — | Minor (§14) |
| 11 | Invariants that name their enforcement | A source-header field naming the test, check, or Coherence chokepoint that enforces an invariant | COMPASS-0002 | Minor to the Spec |
| 12 | Methods delivered at their trigger | `howto` Guides offered by the adapter just before the act they describe | COMPASS-D43 (gated) | None to core |
| 13 | A calibrated catalog budget | Compare what the catalog predicts a session needs with what sessions read | COMPASS-D15 (gated) | None to core |
| 14 | Open questions first | Rank unresolved questions above other entries in the catalog | COMPASS-D15 (gated) | None to core |
| 15 | Attributed human words | An optional field on records for words an agent attributes to a person, labelled as attribution, not proof | COMPASS-O3 | Minor (§8) |

## Ways to describe Compass

Candidate statements, for the README and for any public description:
- "Agent memory remembers for the agent. Compass keeps the record for the
  project."
- "The design history of your software: typed, reviewed, versioned with the
  code, and queryable."
- "Architecture knowledge management for the agent era: what your sessions
  decided, why, and what replaced it, kept after the session ends."

## Risks to the positioning

- **Spec-driven development** is the closest crowded neighbour by feel. The
  distinction to stress is lifespan: a feature specification serves one
  feature; the record serves the life of the project.
- **MOOSEDev and Coherence** are close in substance, on typed decisions and on
  checked intent. The distinctions are a standard first, the record as the
  source of truth, human review, federation, and plain files.
- **Ceremony** remains the main barrier to adoption. Capture adapters
  (candidate 3) and `compass-maintain` are the answers, and both are unbuilt.
- **One steward, one user.** A standard needs adopters to be one (§23, GO2).
- **Overclaiming.** This survey is an argument, not evidence. The record's
  value to agents is a hypothesis under test (COMPASS-0006), and its value to
  people is asserted from experience, not measured.

## Honest Limits

- The survey of the field rests on the informal search of COMPASS-0010, which
  is not a systematic review, and on documentation rather than use: neither
  Coherence nor LoreConvo was run, and the general memory tools (Mem0, Letta,
  Graphiti) are named from their repositories' descriptions, not examined.
- The field changes within months; a positioning written in October 2026 will
  need revising.
- The engineering-record thesis is an interpretation of Compass's purpose by its
  steward and assistant. Whether others recognise the category, or care about
  it, is untested.
- The competency questions are proposals; none has yet been run against an
  export, because the export does not exist.

## Relationship to Other Work

- [COMPASS-0001](../Compass.md):
  - §1 and §2 state the standard's purpose and non-goals; this survey proposes
    stating its positioning there (COMPASS-DRAFT-positioning-O6).
  - §16 and §21 treat rendered forms as derivations, the frame in which agent
    delivery is one more derivation.
  - §23, GO2 names the bus-factor risk.
- [COMPASS-0010](Eval.PriorArt.AgentContext.md) holds the prior art, the
  assessment of each element, and the side-by-side comparison with Coherence and
  LoreConvo.
- [COMPASS-0006](Eval.AgentContext.md) is the evaluation that gates the memory
  view, and the source of the evidence candidate 7 calls for.
- [COMPASS-0004](Plan.Toolchain.md) and [COMPASS-0007](Plan.AgentWorkflow.md)
  define the planned work summarised above.
- [COMPASS-0008](Spec.SemanticBinding.md) defines the graph; it needs extending
  for critiques before CQ13 can be answered.
- [COMPASS-0009](Survey.SecureDevelopment.md) proposed the accountability and
  security queries that CQ7 and candidate 6 continue.
- [COMPASS-0005](Survey.OperatorMemory.md) set the import-not-coexist precedent
  that the Coherence authority rule follows.
- [COMPASS-0014](Plan.Critique.md) defines the critique, the part of the
  process record with the least precedent elsewhere.
- External: architecture knowledge management research (Kruchten, Lago, and van
  Vliet; Tang et al.); the design and development file of ISO 13485, as an
  analogy only.

## Open Questions

### COMPASS-DRAFT-positioning-O1 — Which name to lead with

Compass could present itself as an "engineering record", a "design history",
or "architecture knowledge management for the agent era". The first is plain
but new; the second borrows a regulated term with connotations of compliance;
the third claims a research lineage that practitioners may not know. Which leads,
and which are used only in explanation?

### COMPASS-DRAFT-positioning-O2 — Integrate with memory tools, or compete

Compass could make itself the source that memory tools index and query (an MCP
server, capture adapters, an export they consume), or build its own delivery to
agents (the catalog and adapter), or both in turn. The evaluation will say
whether its own delivery helps; should integration proceed first regardless,
since it does not depend on that answer?

### COMPASS-DRAFT-positioning-O3 — Agent journals and decision records

When a project uses Coherence, LoreConvo, or another tool that records agents'
decisions, which record is authoritative? The proposal is that journals are
working evidence and lasting decisions are promoted to Compass records through
review. What happens to a journal entry that contradicts an accepted decision,
and should the toolchain detect it?

### COMPASS-DRAFT-positioning-O4 — The first proof of the record's value

Which derivation or query would best show, to someone who does not use agents,
that the record is worth its cost: a compiled README, a user guide derived from
the corpus, the federated site, or a published set of answered competency
questions?

### COMPASS-DRAFT-positioning-O5 — Becoming a standard in fact

A conformance test suite, a registered vocabulary, and a second adopter or
implementation would make Compass a standard in more than name. Which comes
first, what would count as a second adopter, and when should they be pursued
relative to the evaluation?

### COMPASS-DRAFT-positioning-O6 — Stating the positioning in the standard

Should COMPASS-0001 §1 and §2 be amended to place Compass in the AKM and
docs-as-code lineage and to name memory for agents as a derived benefit rather
than a purpose? Or should positioning stay in the README and this survey, outside
the normative text?
