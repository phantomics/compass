---
id:            <NAMESPACE>-DRAFT-<slug>
title:         <Topic> Evaluation
genre:         Eval
subtype:       comparison           # prior-art | comparison | tradeoff (§4)
scope:         project              # component | project | program
project:       <project>
component:     <component>          # omit if not applicable
language:      en
status:        Draft
provenance:
  assistant:   <assistant>
relates-to:
  - <ID>
cites:
  - title:     <external source>
    locator:   <section/page>
    external:  true
---

# <Topic>: Prior-Art Evaluation

<One-paragraph abstract: what is being evaluated and to inform which decision.
Eval is the sharper evidential companion to a Survey — it compares alternatives
against a rubric (§4).>

## Method

<How the evaluation was conducted; what counts as evidence.>

## The Shared Scenario

<The common scenario each alternative is run against, so comparison is fair.>

## The Rubric

<The criteria (e.g. G1…Gn) each alternative is scored against.>

## <Rendition / comparison>

<One section per alternative evaluated against the rubric.>

<!-- optional attested per-rendition patterns:
- score against each rubric criterion as bold-lead bullets (G1 …: verdict)
- close with a one-line lesson: **Steal:** … **Reject:** …
- per-installment `## Comparison — <N>` tables
-->

<!-- for subtype: critique (§4, §8, §14), name the file Eval.Critique.<Topic>.md,
     list the documents criticised in relates-to, and shape the document so:
## Method
  the target (documents, and the revision of any code, pinned), the stance
  (red team, devil's advocate, pre-mortem, newcomer, user advocate), whether the
  critic is independent of the target's authors, the evidence standard, and
  what was left unexamined
## The Shared Scenario      (use cases, workloads, failure modes, adversaries)
## The Rubric               (qualities C1…Cn, each with what holding up means)
## Findings                 (in place of the renditions; one record per finding,
                             most severe first, each listed in open-questions:)
### <NAMESPACE>-DRAFT-<slug>-O1 — <the weakness, stated as a claim>
**Rationale:** <the target's own case, citing the decision that made the choice>
**Objection:** <what is wrong, under which scenario or criterion>
**Evidence:** <a pinned code reference, identifier, or cites title; how it was shown>
**Severity:** high | medium | low
**Seed:** <optional: the improvement it suggests>
  (a person adds **Resolution:** — never the critic or an assistant)
## What Held Up             (optional: parts that survived the attack)
## Synthesis                (themes by severity; seeds; what was not examined)
-->

## Synthesis

<What the comparison settles; the recommendation it supports.>

<!-- program-scope evals leaning on many foreign sources SHOULD add: -->
## Appendix — Source Map

Table: The primary sources behind each section.

| Section | Primary sources |
|---|---|
| <section> | <sources> |
