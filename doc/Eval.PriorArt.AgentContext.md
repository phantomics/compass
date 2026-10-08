---
id:            COMPASS-DRAFT-agent-context-prior-art
title:         Prior Art for Compass as Agent Context and Queryable Corpus
genre:         Eval
subtype:       prior-art
scope:         program
program:       Compass
component:     agent-context
language:      en
status:        Draft
authors:
  - Andrew Sengul
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-0001
  - COMPASS-DRAFT-operator-memory
  - COMPASS-DRAFT-agent-context-eval
  - COMPASS-DRAFT-agent-workflow
  - COMPASS-DRAFT-toolchain
  - COMPASS-DRAFT-semantic-binding
  - COMPASS-DRAFT-source-headers
cites:
  - title:     "Ontology-Grounded Project Memory for Coding Agents (Adam; NeSy 2026)"
    locator:   "arXiv:2608.13662, abstract and §2–§3"
    external:  true
  - title:     "Handoff Debt: The Rediscovery Cost When Coding Agents Take Over Interrupted Tasks (KC, Budathoki; 2026)"
    locator:   "arXiv:2606.02875v2, abstract"
    external:  true
  - title:     "Codified Context: Infrastructure for AI Agents in a Complex Codebase (2026)"
    locator:   "arXiv:2602.20478v1, abstract and §1"
    external:  true
  - title:     "ESAA-Conversational: An Event-Sourced Memory Layer for Continuity, Handoff, and Curation Across Heterogeneous LLM Coding Agents (Brito dos Santos Filho, 2026)"
    locator:   "arXiv:2606.23752v1, §2–§3"
    external:  true
  - title:     "Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents? (Gloaguen et al.; MemAgents @ ICLR 2026)"
    locator:   "arXiv:2602.11988v2, abstract"
    external:  true
  - title:     "Do Context Files Help Coding Agents? A Two-Agent Ablation Study on Real Repositories (Khatri, 2026)"
    locator:   "arXiv:2607.27250, abstract"
    external:  true
  - title:     "Agent READMEs: An Empirical Study of Context Files for Agentic Coding (Chatlatanagulchai et al.)"
    locator:   "arXiv:2511.12884, abstract"
    external:  true
  - title:     "EvoCode-Bench: Evaluating Coding Agents in Multi-Turn Iterative Interactions (2026)"
    locator:   "arXiv:2605.24110, §3"
    external:  true
  - title:     "When and How Context Rot Appears in Coding Agents (Xue, 2026)"
    locator:   "arXiv:2607.17937v2, abstract"
    external:  true
  - title:     "Agent Drift: Quantifying Behavioral Degradation in Multi-… (2026; full title not verified)"
    locator:   "arXiv:2601.04170v1, abstract"
    external:  true
  - title:     "Operator Memory repository (aerovato/operator-memory)"
    locator:   "README.md@e394f1c"
    external:  true
  - title:     "GitHub Spec Kit — Spec-Driven Development"
    locator:   "spec-driven.md; .specify/memory/constitution.md"
    external:  true
  - title:     "Kiro documentation — Specs"
    locator:   "kiro.dev/docs/specs"
    external:  true
  - title:     "Cline Memory Bank"
    locator:   "Memory Bank pattern"
    external:  true
  - title:     "OSLC Core Version 3.0 (OASIS Open Project)"
    locator:   "Part 1: Overview; Part 6: Resource Shape"
    external:  true
  - title:     "OpenMetadata — Knowledge Graph"
    locator:   "how-to-guides/ontology/knowledge-graph (RDF graph, SPARQL, MCP tools)"
    external:  true
  - title:     "Documenting Architecture Decisions (Nygard, 2011)"
    locator:   "Blog post introducing ADRs"
    external:  true
  - title:     "The Specification Gap: Coordination Failure Under Partial Knowledge in Code Agents (2026)"
    locator:   "arXiv:2603.24284v1, abstract and §4"
    external:  true
  - title:     "Grounding AI Agents in Contracts: An Empirical Evaluation of Spec-Driven Test Generation (Tufano et al.; SpecOps '26)"
    locator:   "arXiv:2608.17177v2, abstract"
    external:  true
  - title:     "Spec Kit Agents: Context-Grounded Agentic Workflows (2026)"
    locator:   "arXiv:2604.05278v1 (title and opening only; not yet read)"
    external:  true
  - title:     "Evaluating Large Language Models for Detecting Architectural Decision Violations (2026)"
    locator:   "arXiv:2602.07609v1, abstract"
    external:  true
  - title:     "Context Matters: Evaluating Context Strategies for Automated ADR Generation (2026)"
    locator:   "arXiv:2604.03826 (title and abstract opening only)"
    external:  true
  - title:     "Can LLMs Generate Architectural Design Decisions? An Exploratory Empirical Study (2024)"
    locator:   "arXiv:2403.01709, abstract"
    external:  true
  - title:     "Issues as Elements of Information Systems (Kunz, Rittel; 1970)"
    locator:   "IBIS"
    external:  true
open-questions:
  - COMPASS-DRAFT-agent-context-prior-art-O1
  - COMPASS-DRAFT-agent-context-prior-art-O2
  - COMPASS-DRAFT-agent-context-prior-art-O3
---

# Compass as Agent Context: Prior-Art Evaluation

This evaluation compares the ideas developed for Compass's agent-context work
against the prior art found so far, to establish which of them are new, which
are refinements, and which are already established. It covers the work recorded
in [COMPASS-DRAFT-operator-memory](Survey.OperatorMemory.md),
[COMPASS-DRAFT-agent-workflow](Plan.AgentWorkflow.md),
[COMPASS-DRAFT-toolchain](Plan.Toolchain.md) (COMPASS-DRAFT-toolchain-D10 to
COMPASS-DRAFT-toolchain-D17), [COMPASS-DRAFT-source-headers](Spec.SourceHeaders.md),
[COMPASS-DRAFT-semantic-binding](Spec.SemanticBinding.md), and
[COMPASS-DRAFT-agent-context-eval](Eval.AgentContext.md). Its findings inform
how Compass describes itself and which of its claims the evaluation must
support.

**This is not a systematic literature review.** It rests on a small number of
web searches made during one design discussion on 2026-10-07, read mostly at
the level of abstracts and excerpts. Closer work may well exist, particularly in
design-rationale research, in OSLC-adjacent tooling, and in the many agent-memory
tools published in 2026. Every novelty judgement below is therefore provisional:
"no prior art found" means not found in this search, not shown to be absent.
This document is meant to be revised as the search is extended
(COMPASS-DRAFT-agent-context-prior-art-O1).

## Method

- **Search.** Web searches on: repository context files and their evaluation;
  multi-session and long-context degradation of coding agents; handoff and
  continuity across agent sessions; spec-driven development tools; project
  memory for coding agents; linked data for software lifecycle artefacts; and
  ontologies or knowledge graphs for design decisions. A second round searched
  for evaluations of structured documentation and specification formats, and
  for studies of agents and architecture decision records. Results were read at the
  level of abstracts, documentation excerpts, and, where available, project
  READMEs. Operator Memory was read at source level for
  [COMPASS-DRAFT-operator-memory](Survey.OperatorMemory.md).
- **Unit of comparison.** Compass's work is split into the seven elements listed
  in the rubric. Each prior system is assessed against the elements it touches.
- **What counts as prior art.** A published system, specification, or study that
  implements or evaluates the same idea, whether or not it uses the same terms.
  A partial match counts and is described as partial.
- **Limits of the method.** No citation chasing, no database searches (ACM,
  IEEE, Scopus), no full-text reading of most papers, and no contact with
  authors. Each is a planned extension under O1.

## The Shared Scenario

The scenario against which prior art is compared is the one Compass is designed
for: a small team, or a single developer, building a federation of related
projects over months with coding agents doing much of the implementation. Agent
sessions decay and are replaced; several people and several agent tools work on
the same code. The project's design intent (its decisions, rejected
alternatives, invariants, terminology, and security properties) must survive
every replacement, and must be queryable across repositories by people and
programs.

## The Rubric

Table: Elements of the Compass agent-context work assessed in this evaluation.

| # | Element | Where it is defined |
|---|---|---|
| E1 | Typed records of design knowledge (decisions, open questions, memos) with permanent identifiers, lifecycle status, and supersession | §5, §8; COMPASS-DRAFT-agent-workflow-D1 to D4 |
| E2 | Status-based authority weighting, so history stays in the record without being treated as current truth | COMPASS-DRAFT-toolchain-D12 |
| E3 | Delivery of a compact, ranked catalog to agents at session start, generated deterministically and committed | COMPASS-DRAFT-toolchain-D10, D11; COMPASS-DRAFT-agent-workflow-D10 |
| E4 | A maintenance loop with human-gated acceptance, solo-steward approval, and per-commit assistance trailers | COMPASS-DRAFT-agent-workflow-D5 to D9 |
| E5 | Source headers whose typed fields link files to decisions, memos, and tests, compiled into a source map | COMPASS-DRAFT-source-headers |
| E6 | A derived RDF binding of the corpus, with an open vocabulary, `tag:` identity, SHACL shapes, and federation | COMPASS-DRAFT-semantic-binding |
| E7 | Evaluation of quality and design-intent conformance across a relay of fresh sessions over real development history (the "annual crop" thesis), with single-feature ablation of the scheme and tasks that put supersession and rejected alternatives under pressure | COMPASS-DRAFT-agent-context-eval |

Each element is scored on one scale:
- **Established:** the idea is in common use or standardised.
- **Precedented:** at least one system implements substantially the same idea.
- **Refinement:** prior systems implement the core idea; Compass's version adds a
  distinct feature.
- **No prior art found:** nothing found in this search, which is not exhaustive.

## Prior Systems and Studies

### Agent memory and context systems

- **MOOSEDev** (Adam, NeSy 2026). The closest system found. Coding agents get a
  project knowledge graph of decisions, lessons, constraints, rationales, and
  anti-patterns, grounded in two small OWL ontologies with SHACL shapes, carrying
  lifecycle status, provenance, and supersession links, and exposed through MCP.
  When an agent asks for guidance, the engine filters superseded records and
  ranks the rest deterministically. On 835 typed records it recovered
  supersession, completeness, and negation answers at 0.98–1.00, where a
  vector-memory baseline recovered 6–27%. **Touches E1, E2, E6.** It differs from
  Compass in holding the graph as the source of truth, in a proprietary engine,
  for one project; in having no human editorial gate described; and in
  evaluating retrieval rather than development outcomes.
- **Operator Memory** (2026). Markdown "brain" with catalogs and an index,
  injected at session start; consult → build → update loop driven by protocol
  text; agent-maintained and untyped. **Touches E3, E4, E5.** Examined in full in
  [COMPASS-DRAFT-operator-memory](Survey.OperatorMemory.md).
- **GitHub Spec Kit** and **Kiro specs**. A project constitution plus
  per-feature specification, plan, and task files that guide agents across
  sessions; Spec Kit supports 38 agent tools. **Touches E1, E3** partially:
  documents carry intent forward but have no permanent identifiers, per-document
  status, or authority ranking, and are scoped to features rather than a
  long-lived record.
- **Cline Memory Bank** and similar context-file patterns. A fixed set of files
  the agent reads at session start and updates. **Touches E3, E4** partially.
- **ESAA-Conversational** (2026). An append-only event log of conversation,
  projected into handoff, state, decision, and task files for the next agent,
  across different agent tools; distinguishes durable decisions from turn-level
  evidence. **Touches E1, E3** partially.
- **Codified Context** (2026). A project knowledge base of conventions,
  architectural decisions, and known failure modes used across 283 development
  sessions, retrieved through MCP; observational evaluation. **Touches E1, E3,
  E7** partially.
- **OpenMetadata knowledge graph.** A data catalog exported as an RDF graph with
  SPARQL, SHACL, and MCP tools for agents, including an ontology-description
  call so agents learn the vocabulary before querying. **Touches E6** in a
  different domain (data assets, not design knowledge).

### Studies of context and sessions

- **Gloaguen et al.; Khatri; Chatlatanagulchai et al.** (2026). Snapshot studies
  of repository context files: no measurable gain in task success, at over 20%
  added cost; instructions are followed; overviews do not help. **Touch E3, E5**
  as cautions.
- **Handoff Debt** (KC and Budathoki, 2026). Interrupts a coding agent and hands
  the task to a successor with the repository only, a raw trace, summary notes,
  or structured notes. Context-bearing handoffs reduce effort by 20–63%; effects
  on success are small. **Touches E7**: one handoff, task resumption.
- **EvoCode-Bench, Xue, Agent Drift, LOCA-bench, ContextEcho** (2026). Measure
  degradation as sessions and context grow. **Touch E7** as evidence for the
  premise, not the remedy.

### Studies of documentation structure

These are the studies found that vary the *structure or form* of what agents
are given, rather than only its presence. They were found in a second round of
searching, after the first version of this evaluation.

Table: Studies that vary the structure of documentation given to agents.

| Study | What it varies | Finding | Difference from what Compass needs |
|---|---|---|---|
| *The Specification Gap* (2026) | Completeness of a specification, in four levels from full docstrings with data structures (L0) to bare signatures (L3) | Integration success of two agents' outputs falls steadily from 58% to 25% as detail is removed; a merging agent given the full specification restores 89% | Single tasks; documentation inside the code; the variable is how much, not what kind |
| *Handoff Debt* (2026) | Summary notes against structured notes in a handoff | Both reduce effort; small effects on success | One handoff; a fixed note format; resumption cost |
| *Spec-Driven Test Generation* (Google; SpecOps '26) | An agent first writes a semi-formal contract specification, then tests, against writing tests directly | +9.8 percentage points in bug detection (p = 0.035) | The specification is written by the agent within the task, not a maintained project record |
| *Spec Kit Agents* (2026) | Spec-driven workflow artefacts | Not yet read beyond the title and opening | Possibly the closest evaluation of a named scheme; must be read (O1) |
| ADR studies (2024–2026) | LLMs generating architecture decision records, choosing context for generation, or detecting violations of them | Violation detection works for decisions visible in code | The record is the output under study, not the context that helps an agent develop |
| Gloaguen et al. (2026), with other documentation removed | Context file present or absent when no other documentation exists | Generated context files then help by about 2.7% | Supports the view that context helps when it supplies knowledge not available elsewhere |

A workshop devoted to this area now exists: SpecOps '26, the 1st International
Workshop on Specification-Driven Development Life Cycle (ACM, October 2026).

What none of these does, as far as found: treat a named, multi-genre
documentation scheme with stated design goals as the independent variable;
ablate the scheme's features one at a time; measure conformance to design intent
rather than task success alone; or include a time dimension.

### Standards and older traditions

- **OSLC** (IBM, then OASIS). Lifecycle artefacts (requirements, changes, tests,
  architecture) as linked data with resource shapes and query. **Touches E6**:
  the established standard for lifecycle data as RDF, though aimed at tool
  integration rather than documentation or agents.
- **Architecture Decision Records** (Nygard, 2011; MADR). **Touches E1**: the
  record shape Compass adopts.
- **Design-rationale research** (IBIS, 1970; QOC; DRL; SEURAT). **Touches E1, E5**:
  decades of work on capturing and linking design rationale to artefacts.
- **Emacs library headers, `CODEOWNERS`, REUSE/SPDX.** **Touch E5**: structured
  file-level comments and path-based review routing.

## Element-by-element Comparison

Table: Assessment of each element against the prior art found.

| # | Element | Closest prior art | Assessment |
|---|---|---|---|
| E1 | Typed records with identity, status, supersession | ADRs; design-rationale research; MOOSEDev | **Established** for the record shape; **Precedented** (MOOSEDev) for typed, status-carrying records offered to agents. Compass's distinct features are permanent federated identifiers, merge-time allocation, and memos as a separate record kind |
| E2 | Authority weighting by status | MOOSEDev's supersession filtering and deterministic ranking | **Refinement.** The core idea (exclude superseded, rank the rest) is precedented; grading by genre and status into five weights, with host documents capping their records, is the addition |
| E3 | Committed, ranked session catalog | Operator Memory; Spec Kit constitution; Memory Bank; llms.txt | **Refinement.** Session-start delivery is established practice; a deterministic, size-bounded catalog ranked by authority and scoped by federation is the addition. The snapshot studies caution that delivery alone may not help |
| E4 | Human-gated maintenance loop with assistance trailers | Operator Memory's loop; Spec Kit's review checkpoints; Git trailers (DCO) | **Refinement.** The loop is precedented; separating change, acceptance, and mechanical gates, solo-steward approval, and derived assistance history are the additions |
| E5 | Typed source headers linked to records and tests | Emacs headers; design-rationale traceability; CODEOWNERS | **No direct prior art found** for the specific combination of typed header fields, identifier links to decision and memo records, and a compiled, checked map. Each component is old. This was not searched specifically, so the finding is weak |
| E6 | Derived, open, federated RDF binding | OSLC; MOOSEDev; OpenMetadata | **Precedented** for lifecycle data as RDF (OSLC) and for agent-queryable design knowledge graphs (MOOSEDev). **Refinement**: one-way derivation from human-reviewed Markdown in Git, `tag:` identity across a federation of repositories, and an open vocabulary |
| E7 | Relay evaluation of the "annual crop" thesis, with feature ablation and pressure tasks | Handoff Debt; Codified Context; EvoCode-Bench; the snapshot studies; The Specification Gap | **No prior art found** for a controlled comparison, over a sequence of real historical development steps, of one long session against fresh sessions carrying nothing, untyped notes, or a typed and maintained corpus, measured on design-intent conformance. Handoff Debt is the nearest (single handoff, resumption cost). **No prior art found** for ablating the features of a documentation scheme; The Specification Gap is the nearest (completeness levels only). Seeded supersession and rejected-alternative recall have no direct precedent found; MOOSEDev tests supersession for retrieval only |

## Synthesis

1. **Most individual ideas are established or precedented.** Typed decision
   records, status and supersession, session-start context, maintenance loops,
   lifecycle data as RDF, and SHACL validation all have prior art, some of it
   decades old and some published within months of this work.
2. **MOOSEDev is the closest system and should be cited wherever Compass makes
   claims about typed, queryable design knowledge for agents.** Its retrieval
   results are also the best external evidence so far that the queries Compass
   enables (supersession, completeness, negation) are ones similarity retrieval
   cannot answer.
3. **The defensible novelty claims, provisional on a fuller search, are three:**
   - the **combination**, as an open standard: typed genres on a maturity
     ladder, permanent federated identifiers, human-gated governance, reviewed
     Markdown in Git as the single source of truth, and deterministic derivation
     to both an agent catalog and an RDF graph;
   - the **evaluation design** (E7), which no prior study found matches. Three
     parts of it look individually publishable: the relay over real history,
     single-feature ablation of a documentation scheme, and the supersession
     and rejected-alternative pressure tasks. The research agenda appended to
     [COMPASS-DRAFT-agent-context-eval](Eval.AgentContext.md) lists these and
     eight further studies;
   - the **source-header chain** (E5), weakly, pending a targeted search.
4. **Queryability is distinctive in its source, not in itself.** SPARQL over
   lifecycle and design data exists (OSLC, MOOSEDev, OpenMetadata). What Compass
   adds is that the graph is a by-product of documentation people already write
   and review, so it does not decay the way separately maintained knowledge
   graphs tend to.
5. **Positioning.** Compass should describe itself as an open, documentation-
   first synthesis that makes established ideas work together for agents and
   people, with an evaluation designed to test whether the synthesis earns its
   cost; not as the originator of typed agent memory or semantic lifecycle data.
6. **Consequences already applied.** [COMPASS-DRAFT-agent-context-eval](Eval.AgentContext.md)
   now cites Handoff Debt, Codified Context, and MOOSEDev and states its gap
   narrowly; [COMPASS-DRAFT-operator-memory](Survey.OperatorMemory.md) and
   [COMPASS-DRAFT-semantic-binding](Spec.SemanticBinding.md) record the further
   prior art.

## Open Questions

### COMPASS-DRAFT-agent-context-prior-art-O1 — A systematic search

This evaluation rests on an informal search. A systematic one would define
search strings and databases (ACM Digital Library, IEEE Xplore, arXiv cs.SE and
cs.AI, Semantic Scholar), follow citations forward and backward from MOOSEDev,
Handoff Debt, and Codified Context, survey design-rationale research since IBIS,
and inventory agent-memory tools released in 2026. Several items found but not
yet read must be read in full first: *Spec Kit Agents* (arXiv 2604.05278), which
may evaluate a named documentation scheme directly; *Context Matters* on ADR
generation (2604.03826); and the papers of the SpecOps '26 workshop. Who
undertakes the search, and should it be complete before any public claim of
novelty is made?

### COMPASS-DRAFT-agent-context-prior-art-O2 — Contact with closest work

MOOSEDev and Handoff Debt are close enough that their authors may know of work
this search missed, and their benchmark artefacts may be reusable (MOOSEDev
publishes a corpus of 835 typed records; Handoff Debt publishes its takeover
protocol). Should Compass's evaluation reuse either, and should their authors be
contacted?

### COMPASS-DRAFT-agent-context-prior-art-O3 — Keeping this evaluation current

The field moved quickly during 2026: three of the closest works appeared between
February and August. How is this document kept current: revised before each
public release of Compass, on a fixed schedule, or whenever a new close match is
found?

## Appendix — Source Map

Table: Sections of this evaluation and the primary sources each draws on.

| Section | Primary sources |
|---|---|
| Agent memory and context systems | MOOSEDev; Operator Memory; Spec Kit; Kiro; Cline Memory Bank; ESAA-Conversational; Codified Context; OpenMetadata |
| Studies of context and sessions | Gloaguen et al.; Khatri; Chatlatanagulchai et al.; Handoff Debt; EvoCode-Bench; Xue; Agent Drift |
| Studies of documentation structure | The Specification Gap; Handoff Debt; Spec-Driven Test Generation; Spec Kit Agents; ADR studies (2403.01709, 2602.07609, 2604.03826); Gloaguen et al. |
| Standards and older traditions | OSLC Core 3.0; Nygard (2011); Kunz and Rittel (1970) |
| Element-by-element comparison | All of the above |
