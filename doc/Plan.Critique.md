---
id:            COMPASS-DRAFT-critique
title:         Compass Critique — Adversarial Evaluation of a Project's Own Systems
genre:         Plan
scope:         program
program:       Compass
component:     standard
language:      en
status:        Draft
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-0001
  - COMPASS-DRAFT-secure-development
  - COMPASS-DRAFT-agent-workflow
  - COMPASS-DRAFT-authoring-assistance
  - COMPASS-DRAFT-toolchain
cites:
  - title:     "ATAM: Method for Architecture Evaluation"
    locator:   "Kazman, Klein, and Clements; SEI technical report CMU/SEI-2000-TR-004, 2000"
    external:  true
  - title:     "IEEE 1028-2008, Standard for Software Reviews and Audits"
    locator:   "technical reviews, inspections, and their anomaly lists"
    external:  true
  - title:     "Design and code inspections to reduce errors in program development"
    locator:   "M. E. Fagan, IBM Systems Journal 15(3), 1976"
    external:  true
  - title:     "Red Teaming Handbook, third edition"
    locator:   "UK Ministry of Defence, Development, Concepts and Doctrine Centre, 2021"
    external:  true
  - title:     "Performing a Project Premortem"
    locator:   "Gary Klein, Harvard Business Review, September 2007"
    external:  true
  - title:     "Intuition Pumps and Other Tools for Thinking"
    locator:   "Daniel C. Dennett, 2013; Rapoport's rules"
    external:  true
  - title:     "PEP 12, Sample reStructuredText PEP Template"
    locator:   "the Rejected Ideas section"
    external:  true
  - title:     "Rust RFC template"
    locator:   "rust-lang/rfcs, 0000-template.md; Drawbacks, and Rationale and alternatives"
    external:  true
  - title:     "Threat Modeling Manifesto"
    locator:   "threatmodelingmanifesto.org, 2020; the four questions"
    external:  true
decisions:
  - COMPASS-DRAFT-critique-D1
  - COMPASS-DRAFT-critique-D2
  - COMPASS-DRAFT-critique-D3
  - COMPASS-DRAFT-critique-D4
  - COMPASS-DRAFT-critique-D5
  - COMPASS-DRAFT-critique-D6
open-questions:
  - COMPASS-DRAFT-critique-O1
  - COMPASS-DRAFT-critique-O2
  - COMPASS-DRAFT-critique-O3
  - COMPASS-DRAFT-critique-O4
  - COMPASS-DRAFT-critique-O5
  - COMPASS-DRAFT-critique-O6
---

# Compass Critique: Development Plan

This plan gives **adversarial critique** a form in the Compass standard
([COMPASS-0001](../Compass.md)): a document that attacks a project's own system
or design, states the case for what it attacks before objecting, grounds each
objection in evidence a reader can check, and leaves each finding for a person
to accept or reject. The form is a new subtype of the `Eval` genre, `critique`,
rather than a new genre. Its findings are open-question records, resolved by
decisions in the documents that own the system criticised. The security
threat model proposed by
[COMPASS-DRAFT-secure-development](Survey.SecureDevelopment.md) becomes
critique's specialisation for security, keeping its own method. The plan
assumes the review gates and agent permissions of
[COMPASS-DRAFT-agent-workflow](Plan.AgentWorkflow.md), and the vocabulary
standings of [COMPASS-DRAFT-toolchain](Plan.Toolchain.md).

## Problem

Conversations that criticise a system's features, and seed ideas to improve
them, have been central to how Classic and Origin evolved. The standard has no
form for what such a conversation produces:

- **Critique lands in the wrong genres, or nowhere.** A `Survey` asks "should
  we?" about something not yet built. A `prior-art` or `comparison` Eval judges
  other systems in order to learn from them. A `Log` records its own pitfalls
  in passing. None is a critique of a project's own system, so critique either
  takes one of these shapes uneasily or stays in the conversation, which §2
  makes disposable scratch. Classic's `securityPoints.md`
  (`CLASSIC:securityPoints.md@be4fe84`), a list of what exists, what is missing,
  and what to do first, is a critique in all but form, and has no front-matter.
- **Objections are not tied to what they challenge.** A design choice in Compass
  is a decision record with its context and rejected alternatives (§8). An
  objection that does not cite the decision it attacks cannot show it has
  understood the choice, and the decision's owner cannot tell whether the
  objection is new.
- **Objections are not grounded.** A critic, and especially an assistant, can
  produce many plausible objections cheaply. Without a rule that each one names
  evidence, plausible and true objections look alike.
- **Dispositions are not recorded.** When an objection is answered, or set
  aside, the answer lives in a later conversation or in nobody's memory, so a
  rejected objection is raised again, and an accepted one is not traceable to
  the change it caused.
- **Agents cannot weigh an objection.** An agent reading a critique has no way
  to tell a standing objection from a decision in force, and could treat a
  critic's proposal as the system's design.

## Goals

- A home for adversarial critique of a project's own systems and designs,
  inside the existing genres, statuses, and registers.
- Findings that are fair: each states the case for what it attacks, citing the
  decision or document that made the choice.
- Findings that are grounded, to the standard a memo's `**Basis:**` meets
  ([COMPASS-DRAFT-agent-workflow-D3](Plan.AgentWorkflow.md#compass-draft-agent-workflow-d3--four-admission-tests-and-a-mandatory-basis)).
- A recorded disposition for every finding, set by a person: accepted findings
  change the system through its own documents, and rejected ones are not
  argued again without new evidence.
- Critique that assistants may draft and agents may read, without either
  mistaking an objection for authority.
- Nothing the toolchain cannot express: a new value takes the pending path of
  [COMPASS-DRAFT-toolchain-D20](Plan.Toolchain.md#compass-draft-toolchain-d20--vocabulary-values-carry-a-standing),
  and findings are records the scanner already reads.

## Settled Decisions

All six decisions are proposals for the steward.

### COMPASS-DRAFT-critique-D1 — Critique is a subtype of Eval

**Status:** Proposed

**Context:** A critique judges a system against criteria, under scenarios,
with evidence: the evidential analysis against a rubric that §4 gives the
`Eval` genre. It needs no status family, register, or place in the normativity
grid that `Eval` lacks. §13 admits a genre only by accepted amendment, and §23
P4 manages genre proliferation by preferring subtypes over new genres. The
`Eval` subtypes so far judge other systems (`prior-art`), several alternatives
(`comparison`), or options for a pending decision (`tradeoff`); none judges the
project's own system.

**Decision:**
- `Eval` gains the subtype `critique`: an adversarial evaluation of a system or
  design of the project's own, made to find its weaknesses and seed
  improvements.
- Its status follows the proposal family (§6). A critique is `Draft` while it is
  written and `Proposed` when complete. It is `Accepted` when a person has read
  it and records it as a fair critique, which is not acceptance of its
  objections. It is `Superseded` by a later critique of the same target, and
  `Rejected` if a person judges it unfounded as a whole.
- Under COMPASS-DRAFT-toolchain-D12 an accepted critique weighs Contextual: it
  explains, and never overrides an Authoritative document. An objection changes
  the system only when a decision in the system's own documents adopts it
  (COMPASS-DRAFT-critique-D4).
- File names follow §10; the convention `Eval.Critique.<Topic>.md` keeps
  critiques together, as `Eval.PriorArt.AgentContext.md` does for prior art.
  The generated index already shows the subtype, as `Eval (critique)`.
- §4's maturity ladder gains a sentence: a critique of what exists leads back
  from a `Ref` or `Log` to a `Survey` or `Plan`, so the ladder can be climbed
  again.

**Alternatives:**
- A `Critique` genre, with a `Critique.` prefix. Rejected: it would duplicate
  `Eval`'s status family, shape, and weight, and its only gain, finding
  critiques by file name, is had from the subtype in the index and the naming
  convention.
- A `Survey`. Rejected: a survey explores whether something should exist; a
  critique judges something that exists or has been designed.
- Open-question records in the criticised Plan alone. Rejected: a critique's
  method, scenarios, and rubric would be lost, and one critique often spans
  several documents.

### COMPASS-DRAFT-critique-D2 — A critique pins its target and declares its stance

**Status:** Proposed

**Context:** A critique of code goes stale when the code changes, and a
critique of a design when the design does. A reader also needs to know what
kind of attack was made: a red team looking for failure, a devil's advocate
arguing a rejected alternative, and a pre-mortem assuming failure find
different things, and each leaves different things unexamined.

**Decision:** A critique's Method section states:
- **the target**: the documents criticised, which `relates-to` also lists, and,
  for a critique of code, the revision, with commit-pinned code references
  (§9);
- **the stance**: the kind of attack, from the stances under
  [Stances](#stances) or another named one, and whether the critic is
  independent of the target's authors;
- **the evidence standard**: what counts as showing a weakness, such as a
  failing scenario, a test, a measurement, or a contradiction between
  documents;
- **what was left out**: parts of the target not examined, so that silence is
  not read as approval.

**Alternatives:**
- A free-form essay. Rejected: a reader cannot tell when it has gone stale, or
  check its objections.
- Require a critic independent of the authors, as a red team usually is.
  Rejected: in a solo namespace there is no one else. The stance declares
  independence where it exists, and the steward weighs it.

### COMPASS-DRAFT-critique-D3 — Each finding defends the choice before attacking it, and is grounded

**Status:** Proposed

**Context:** An objection that misstates what it attacks is a strawman, and one
that names no evidence cannot be checked. Rapoport's rules, as Dennett states
them, ask a critic to restate the target's position so fairly that its holder
would accept the restatement before rebutting it. Compass already has a
grounding rule: a memo's `**Basis:**` must name a commit-pinned code reference,
a Compass identifier, or a cited work
(`src/rules/memo.lisp:memo/basis@ccb28e9`).

**Decision:** Each finding carries the fields under
[Finding records](#finding-records). Two of them hold this decision:
- `**Rationale:**` states the target's own case for the choice, citing the
  decision record or document that made it. If no record states the choice,
  the rationale says so, and the missing record is itself part of the finding.
- `**Evidence:**` names at least one commit-pinned code reference, Compass
  identifier, or title of an entry in the critique's `cites:`, then how the
  weakness was shown.

An objection without evidence is not a finding. It may be kept in the
Synthesis as a seed, or proposed as a `Survey`.

**Alternatives:**
- Objections alone. Rejected: a reader cannot tell whether the critic
  understood the choice, and the target's owner must reconstruct its rationale
  to answer.
- Ungrounded findings marked as speculative. Rejected: they would look like
  findings to agents and in the index; a speculative idea is what a `Survey`
  is for.

### COMPASS-DRAFT-critique-D4 — Findings are open-question records, and a person disposes of each

**Status:** Proposed

**Context:** A finding is a known unresolved issue of the target, which is what
§8 defines an open-question record to be. Inspection practice, since Fagan,
records each anomaly with a disposition decided by someone other than its
finder. One status on the critique cannot describe many findings, each of
which may be accepted, rejected, or left open. §8 places open questions under
`## Open Questions`; in an `Eval` the findings take the place of the
renditions, between the Rubric and the Synthesis.

**Decision:**
- Each finding is an open-question record of the critique, defined under
  `## Findings` with the fields of [Finding records](#finding-records).
  `open-questions:` lists them. §8 is amended to allow this placement in a
  critique.
- A person adds the finding's `**Resolution:**`, dated: **accepted**, naming the
  decision record, plan, or change that answers it; or **rejected**, with the
  reason. A finding without one is open. See [Dispositions](#dispositions).
- An accepted objection changes the target through the target's own documents:
  a decision record in its `Plan` or `Arch`, whose Context cites the finding.
  The critique does not hold decisions about its target.
- A rejected finding stays in the critique with its reason, so that it is not
  raised again without new evidence, as a PEP's Rejected Ideas are kept.
- Writing a resolution is part of the acceptance gate of
  [COMPASS-DRAFT-agent-workflow-D5](Plan.AgentWorkflow.md#compass-draft-agent-workflow-d5--three-review-gates):
  an assistant never writes one.

**Alternatives:**
- Findings as rendition sections, each linked to an open-question record under
  `## Open Questions`. Rejected: each finding would be written twice, and the
  copies would drift.
- Findings under `## Open Questions` after the Synthesis, leaving §8 as it is.
  Rejected: the Synthesis would precede the evidence it summarises.
- A table of dispositions in the Synthesis. Rejected: a second place to keep in
  step; the disposition belongs with the finding.
- Dispositions by the critic. Rejected: the critic is a party to the dispute,
  and acceptance is a person's act (§6).

### COMPASS-DRAFT-critique-D5 — A threat model is a critique of security, with its own method

**Status:** Proposed

**Context:** [COMPASS-DRAFT-secure-development](Survey.SecureDevelopment.md)
proposes an `Eval` subtype `threat-model`, pending in the toolchain, following
the Threat Modeling Manifesto's four questions: what are we working on, what
can go wrong, what are we going to do about it, and did we do a good job. A
threat model attacks a project's own system, which makes it a critique, but
its method, of assets, data flows, trust boundaries, and threat categories such
as STRIDE, is a practice of its own.

**Decision:** `threat-model` stays a subtype of its own, specified by
COMPASS-DRAFT-secure-development, and is the security specialisation of
`critique`. The rules of COMPASS-DRAFT-critique-D2 to COMPASS-DRAFT-critique-D4
apply to it:
- its Method names the system, the revision, and the threat-modelling method;
- each threat is a finding record, whose `**Severity:**` follows the method's
  own measure, such as likelihood and impact;
- a mitigation or an accepted risk is a decision record in the system's own
  documents, which the threat's resolution names, as the survey's chain from
  threat to mitigation already describes.

Where the survey's questions remain open, such as where a small project's
threat model lives, this decision leaves them to it.

**Alternatives:**
- Fold `threat-model` into `critique` as a security stance. Rejected: the
  threat-modelling method has its own shape and community practice, which a
  stance would lose.
- Keep the two unrelated. Rejected: a threat model would then lack the rules
  that make a critique fair, grounded, and disposed of.

### COMPASS-DRAFT-critique-D6 — The conversation is scratch; the critique is its distillation

**Status:** Proposed

**Context:** Critique often arises in a conversation, with a person or an
assistant, that mixes good objections with weak ones and with ideas. §2 makes
routine transcripts disposable scratch, and `Ideation` is the rare exception
for a conversation that set a project's direction (§4). Assistants are apt
devil's advocates, and also produce plausible objections that do not survive a
check.

**Decision:**
- A critique conversation stays scratch. The critique `Eval` is its
  distillation: the findings that survive grounding, written to the rules
  above. `provenance.session` names the conversation where that is meaningful
  (§7).
- An assistant may draft a critique, at any scope, as `Draft`, as the
  permissions of [COMPASS-DRAFT-agent-workflow-D8](Plan.AgentWorkflow.md#compass-draft-agent-workflow-d8--what-an-agent-may-do-by-scope)
  allow for any document. It never writes a resolution, and never moves a
  critique to `Accepted`.
- The grounding rule of COMPASS-DRAFT-critique-D3 is the control on an
  assistant's objections: one it cannot ground is a seed, not a finding.
- A conversation is promoted to `Ideation` only when it set a project's
  direction, as a considered editorial act, never as the record of a critique.

**Alternatives:**
- Keep critique conversations as `Ideation` documents. Rejected: `Ideation` is
  deliberately rare, and a transcript mixes grounded and ungrounded objections.
- Forbid assistant-written critiques. Rejected: drafting is permitted for every
  document, and the grounding and disposition rules already keep an
  assistant's objections from standing unchecked.

## The critique subtype

### Section shape

A critique uses the `Eval` spine of §14, with findings in the place of the
renditions:

Table: The critique section shape, mapped onto the Eval spine.

| Eval section (§14) | Critique content |
|---|---|
| Method | The target (documents, and the revision of any code), the stance, the evidence standard, and what was left out (COMPASS-DRAFT-critique-D2) |
| The Shared Scenario | The use cases, workloads, failure modes, or adversaries the target is put through |
| The Rubric | The qualities assessed, as `C1`…`Cn`, each with what holding up means |
| Findings (the renditions) | One open-question record per finding, in order of severity, with the fields below |
| What Held Up (optional) | The parts of the target that survived the attack, as ATAM records non-risks, so they are not argued again |
| Synthesis | Themes ranked by severity, the seeds worth a `Survey` or `Plan`, and what the critique did not examine |

### Finding records

Table: The fields of a finding record.

| Field | Required | Value |
|---|---|---|
| `**Rationale:**` | yes | The target's own case for the choice, citing the decision record or document that made it, or saying that none did |
| `**Objection:**` | yes | What is wrong, under which scenario or rubric criterion |
| `**Evidence:**` | yes | At least one commit-pinned code reference, Compass identifier, or `cites:` title, then how the weakness was shown |
| `**Severity:**` | yes | `high`, `medium`, or `low`, by the consequence if the objection holds; a threat model uses its method's measure |
| `**Seed:**` | no | The improvement the objection suggests |
| `**Resolution:**` | added by a person | The date, then accepted, naming what answers it, or rejected, with the reason |

An illustrative finding, in a critique of the ledger:

```
### COMPASS-DRAFT-ledger-critique-O1 — One ledger serializes unrelated namespaces

**Rationale:** COMPASS-DRAFT-toolchain-D22 keeps one ledger per repository, so
that every allocation in the repository is in one sequence and two branches
that allocate anything conflict; it rejected a ledger per namespace for that
reason.
**Objection:** A repository owning several namespaces makes branches that
allocate in different namespaces conflict, under the scenario of two teams
sharing one repository.
**Evidence:** `tests/test-concurrency.lisp:different-kinds-still-conflict@ccb28e9`
shows that allocations of different kinds conflict; allocations in different
namespaces append to the same file in the same way.
**Severity:** low
**Seed:** a section per namespace in one file, if the conflicts prove costly.
```

### Stances

Table: Stances a critique may declare, and what each tends to find.

| Stance | The critic assumes | Tends to find |
|---|---|---|
| Red team | An adversary, or the world, will break the target | Failure modes, abuse, unhandled cases |
| Devil's advocate | A rejected alternative was right | Weak rationales, decisions taken by default |
| Pre-mortem | The target has already failed | Fragile assumptions, missing contingencies |
| Newcomer | Nothing beyond the documents | Undocumented assumptions, confusing interfaces |
| User advocate | The target serves its users poorly | Friction, misfit to the use cases |

### Dispositions

Table: The dispositions of a finding.

| Disposition | `**Resolution:**` | What follows |
|---|---|---|
| Open | none yet | The finding stands as a known issue of the target |
| Accepted | Names the decision record, plan, or change that answers it | The target changes through its own documents |
| Rejected | States why: the objection does not hold, or its cost exceeds its benefit | The finding stays, so it is not raised again without new evidence |

### Where a critique ends and other forms begin

Table: Documents close to a critique, and the form each takes.

| The document | Its form |
|---|---|
| Judges another project's design, to learn from it | A `prior-art` Eval |
| Compares several alternatives side by side | A `comparison` Eval |
| Weighs options for a decision not yet taken | A `tradeoff` Eval |
| Attacks a system's security with a threat-modelling method | A `threat-model` Eval (COMPASS-DRAFT-critique-D5) |
| States the weaknesses a design accepts, by its own authors | The design's Tensions and Risks section, or a decision's Alternatives, as a Rust RFC's Drawbacks do |
| Proposes an improvement with no weakness to show | A `Survey` |
| States a verified property of running software | A memo |
| Judges whether a document is ready for acceptance | A `compass-review` report, which is not a document |
| The conversation a critique came from | Scratch (§2), named in `provenance.session` |

## Amendments to the standard

Table: Changes to COMPASS-0001 that this plan proposes, with amendment class
under §13.

| Section | Change | Class | Decision |
|---|---|---|---|
| §4 | `critique` among the `Eval` subtypes; a sentence on critique leading back up the maturity ladder | minor | COMPASS-DRAFT-critique-D1 |
| §8 | Open-question records may appear under `## Findings` in a critique, with the finding fields | minor | COMPASS-DRAFT-critique-D3, COMPASS-DRAFT-critique-D4 |
| §14 | The critique section shape, under `Eval` | minor | COMPASS-DRAFT-critique-D2, COMPASS-DRAFT-critique-D4 |

Accepted together, the three would make `Compass.md` 0.4.0. The `threat-model`
subtype is amended into §4 by COMPASS-DRAFT-secure-development, not by this
plan.

## Open Questions

### COMPASS-DRAFT-critique-O1 — Toolchain checks for findings

Should the toolchain check finding records, as `memo/fields` and `memo/basis`
check memos: the required fields present, and `**Evidence:**` grounded? The
scanner already reads the bold-label fields of any record, so the checks are
cheap. The current thinking is an error for a missing field or ungrounded
evidence, as for memos, once the subtype is accepted, and a warning while it is
pending.

### COMPASS-DRAFT-critique-O2 — The severity scale

Is `high | medium | low`, by consequence, enough, or should severity weigh
likelihood as a threat model does? Should it be a controlled vocabulary the
toolchain checks, or prose?

### COMPASS-DRAFT-critique-O3 — Critique across namespaces

When a critique in one namespace attacks a system another namespace owns, the
finding lives in the critic's repository and its resolution is decided in the
target's. Should such a critique live in the target's repository instead, so
that its steward disposes of findings where they are recorded, or may it stay
with the critic, with the resolution naming the target's decision across the
federation?

### COMPASS-DRAFT-critique-O4 — Open findings and agents

Open-question records carry no weight, so the session catalog does not list
them (COMPASS-DRAFT-toolchain-D12). An agent about to change a system may not
learn of an open finding against it. Should the catalog list open findings
against the documents an agent is working from, or is `compass refs` on the
target, which lists the critique as a relation, enough?

### COMPASS-DRAFT-critique-O5 — Stale critiques

A critique pins the revision it examined. When the target has changed a great
deal since, its open findings may no longer hold. Is a later critique that
supersedes it the only remedy, or should the toolchain report a critique whose
pinned revision is far behind its target's code?

### COMPASS-DRAFT-critique-O6 — Critiques of the standard itself

§23 is the standard's standing record of its own limitations. Should an
accepted finding about the standard that is not resolved at once become a §23
row naming the finding, so that the two records cannot diverge?

## Prior Art

Table: Prior systems and what this plan draws from each.

| System | What to draw from |
|---|---|
| ATAM (SEI architecture tradeoff analysis) | Scenarios and a quality-attribute tree as the instruments of evaluation; risks, non-risks, and tradeoffs as its output: the Shared Scenario, the Rubric, Findings, and What Held Up |
| Fagan inspections; IEEE 1028 reviews and audits | Each anomaly recorded and dispositioned by someone other than its finder: COMPASS-DRAFT-critique-D4 |
| Red teaming (UK MoD Red Teaming Handbook) | A declared adversarial stance and scope, with findings reported to the decision-maker rather than acted on by the red team |
| Pre-mortem (Klein) | A stance: assume the target has failed, and explain why |
| Rapoport's rules (Dennett) | Restate the target's case fairly before objecting: the `**Rationale:**` field |
| PEP 12's Rejected Ideas; the Rust RFC template's Drawbacks and Rationale and alternatives | Rejected objections kept with their reasons; a design's self-critique inside the design itself |
| Threat Modeling Manifesto | The four questions behind the `threat-model` specialisation (COMPASS-DRAFT-critique-D5) |
| Compass memos (COMPASS-DRAFT-agent-workflow-D3) and §23 | The grounding rule of a memo's basis; a standard's standing record of its own limitations |

## Roadmap

1. **This plan (now).** The decisions, the section shape, and the amendments,
   for the steward's review.
2. **Acceptance.** The steward accepts, amends, or rejects
   COMPASS-DRAFT-critique-D1 to COMPASS-DRAFT-critique-D6.
3. **Toolchain and template.** `critique` becomes a pending `Eval` subtype
   naming this plan (COMPASS-DRAFT-toolchain-D20), so `vocab/pending` warns on
   it until the amendment lands. The `Eval` template's subtype comment lists
   it, with a commented block showing a finding record; the toolchain's tests
   cover both.
4. **Skills.** `compass-author` scaffolds a critique, with findings as records
   carrying the fields above and never a resolution; `compass-review` gains a
   critique dimension: target pinned, stance declared, rationale fair, evidence
   grounded; `section-shapes.md` gains the shape.
5. **Amendments.** On acceptance, §4, §8, and §14 are amended as
   `Compass.md` 0.4.0, the subtype's standing becomes accepted, and
   `vocabularies.md` lists it.
6. **Checks**, if COMPASS-DRAFT-critique-O1 settles on them.
7. **First critiques.** A critique of part of Compass, such as the ledger, as
   the worked example; and, at Classic's choice, its `securityPoints.md`
   rewritten as a `threat-model` Eval (COMPASS-DRAFT-secure-development-O6).
