---
id:            COMPASS-DRAFT-eval-defect-detection
title:         Compass Defect-Detection Study — Does Review Find What Is Wrong with a Document?
genre:         Plan
scope:         program
program:       Compass
component:     authoring-assistance
language:      en
status:        Draft
provenance:
  assistant:   opencode
  session:     "Design conversation on peripheral studies, 2026-11-05 to 2026-11-08"
relates-to:
  - COMPASS-0003
  - COMPASS-0012
  - COMPASS-0004
  - COMPASS-0014
  - COMPASS-0006
  - COMPASS-DRAFT-eval-snapshot
  - COMPASS-DRAFT-eval-corpus-qa
cites:
  - title:     "Hints on Test Data Selection: Help for the Practicing Programmer (DeMillo, Lipton, Sayward; 1978)"
    locator:   "IEEE Computer 11(4); the competent-programmer and coupling hypotheses behind mutation testing"
    external:  true
  - title:     "SWE-smith: Scaling Data for Software Engineering Agents (Yang et al., 2025)"
    locator:   "arXiv:2504.21798v2, abstract (tasks made by breaking a repository's tests)"
    external:  true
  - title:     "Evaluating Large Language Models for Detecting Architectural Decision Violations (2026)"
    locator:   "arXiv:2602.07609v1, §III–§IV"
    external:  true
  - title:     "Grounding AI Agents in Contracts: An Empirical Evaluation of Spec-Driven Test Generation (Tufano et al.; SpecOps '26)"
    locator:   "arXiv:2608.17177v2, §4 (judge protocol)"
    external:  true
  - title:     "Ontology-Grounded Project Memory for Coding Agents (Adam; NeSy 2026)"
    locator:   "arXiv:2608.13662, §4 (lessons on grading artefacts)"
    external:  true
  - title:     "Empirical Standards for Software Engineering Research (Ralph et al., ACM SIGSOFT)"
    locator:   "arXiv:2010.03525v2; the Experiments and Registered Reports standards"
    external:  true
decisions:
  - COMPASS-DRAFT-eval-defect-detection-D1
  - COMPASS-DRAFT-eval-defect-detection-D2
  - COMPASS-DRAFT-eval-defect-detection-D3
  - COMPASS-DRAFT-eval-defect-detection-D4
  - COMPASS-DRAFT-eval-defect-detection-D5
  - COMPASS-DRAFT-eval-defect-detection-D6
  - COMPASS-DRAFT-eval-defect-detection-D7
  - COMPASS-DRAFT-eval-defect-detection-D8
  - COMPASS-DRAFT-eval-defect-detection-D9
  - COMPASS-DRAFT-eval-defect-detection-D10
  - COMPASS-DRAFT-eval-defect-detection-D11
  - COMPASS-DRAFT-eval-defect-detection-D12
open-questions:
  - COMPASS-DRAFT-eval-defect-detection-O1
  - COMPASS-DRAFT-eval-defect-detection-O2
  - COMPASS-DRAFT-eval-defect-detection-O3
  - COMPASS-DRAFT-eval-defect-detection-O4
  - COMPASS-DRAFT-eval-defect-detection-O5
---

# Compass Defect-Detection Study: Development Plan

This plan sets out a small study of Compass's review layer. Known defects are
seeded into real Compass documents from four repositories, and reviewers are
asked to review each document before it is accepted:
- the toolchain alone;
- an agent with the `compass-review` skill and the toolchain;
- an agent with the toolchain but no skill;
- an agent with the skill but no toolchain.

The study measures which defects each reviewer finds and how many false alarms
it raises on documents left unchanged. It evaluates the authoring-assistance
layer of [COMPASS-0003](Plan.AuthoringAssistance.md), the review behaviour
recorded in [COMPASS-0012](Log.AuthoringAssistance.md), and the division of
labour between the toolchain of [COMPASS-0004](Plan.Toolchain.md) and the
skill. It is also the first Compass study to run. It goes through the whole
process (Plan, protocol, freeze, runs, results) before the question-answering
study ([COMPASS-DRAFT-eval-corpus-qa](Plan.EvalCorpusQA.md)) and Track 1
([COMPASS-DRAFT-eval-snapshot](Plan.EvalSnapshot.md)) depend on it, so that
what it teaches can be applied to them before they are frozen.

## Problem

- **The review layer's claims are untested.** `compass-review` claims to judge
  what the toolchain cannot: genre fit, decision-record quality, the
  plausibility of cross-references, memo admission, critique quality,
  accessibility, and approval. COMPASS-D1 split the skills by shape, and
  COMPASS-D50 has review check the whole corpus and separate the change's
  findings. No one has measured whether the skill finds the defects it
  describes, how often it raises false alarms, or whether it adds anything an
  agent without the skill would not find.
- **The division of labour is unmeasured.** The skill defers mechanical
  conformance to the toolchain (§22) and spends its judgement on the rest.
  Whether an agent relays the toolchain's findings faithfully, and how much it
  loses when the toolchain is absent (the skill's fallback path), is unknown.
- **The study process is untried.** Three studies are planned, with
  pre-registration, a shared harness, a blinded judge, and analysis in R. None
  has been run. A small, cheap study run first would find the faults in that
  process before larger studies rely on it.
- **Workspaces need a design that does not mislead.** A first check on Classic
  found that a workspace whose history is a single commit makes every
  commit-pinned code reference fail `ref/code-exists`: 162 errors, where the
  real repository has none. A reviewer would report errors the original does
  not have. Full history would expose the original text of a mutated document.

## Goals

- Pre-registered estimates, per model, of how many seeded defects each
  reviewer finds, by kind, and how many false alarms it raises.
- A measure of what the skill adds over an agent without it, and of what the
  toolchain adds to the skill.
- Evidence for revising the skill, the toolchain's rules, and their severities.
- A first run of the harness, the judge, the analysis, and the process of
  pre-registration, with the lessons recorded and applied to the next two
  studies before they are frozen.

## Settled Decisions

All twelve decisions are proposals for the steward. Those agreed in the design
conversation of 2026-11-08 are marked so.

### COMPASS-DRAFT-eval-defect-detection-D1 — The first study, run as a pathfinder for the harness and the process

**Status:** Proposed

**Context:** The question-answering study and Track 1 share a harness, a judge,
an analysis in R, and a process of pre-registration that has never been run.
This study needs no Classic snapshot, no corpora built for setups, and no test
grading, so it needs the least of the harness. It can run first and teach what
the other two need.

**Decision:**
- **Order.** This study runs before the question-answering study and before
  Track 1's freeze. The parts of the harness it needs are built first:
  - the workspace builder;
  - the runner and recorder;
  - the judge's pipeline;
  - the R scripts.
- **Lessons.** Its Log records what it teaches about the harness, the judge,
  the analysis, and the process. After its operational review, those lessons
  are proposed as revisions to the plans of the question-answering study and
  of Track 1, which are not yet frozen.
- **A Guide later.** Whether the process is also written down as a how-to
  Guide for running a Compass study is decided after this study
  (COMPASS-DRAFT-eval-defect-detection-O2).

*Running first agreed in conversation.*

**Alternatives:** Running it alongside the others, which loses its value as a
pathfinder. Not running it, which leaves the review layer unmeasured and the
process untried until a larger study depends on it.

### COMPASS-DRAFT-eval-defect-detection-D2 — Pre-registered, with a protocol Eval and no decision rules

**Status:** Proposed

**Context:** Rehearsing the process is part of the study's purpose, so it
should be run in full even though the study is small. Its results bear on the
skill and the rules, not on decisions COMPASS-0006's rules act on.

**Decision:**
- **The protocol.** The study is frozen in a protocol Eval,
  `doc/Eval.DefectDetection.md` (subtype `comparison`), written from this Plan
  at the freeze, which the steward commits and tags. Results are appended to it
  as dated updates.
- **No decision rules.** Its results are reported as evidence for revising
  `compass-review`, the toolchain's rules and their severities, and COMPASS-0003.
  The steward decides on those revisions.
- **Frozen tools.** The skill and the toolchain are frozen at the freeze
  commit, and any revision to them waits until the results are in.

*Agreed in conversation.*

**Alternatives:** An informal run with no protocol, which saves a little effort
and loses the rehearsal. Decision rules acting on the skill, which would bind
the steward to change a skill on the strength of one small study.

### COMPASS-DRAFT-eval-defect-detection-D3 — Four reviewers that differ in what is installed, not in what is asked

**Status:** Proposed

**Context:** To measure what the skill adds, an agent with the skill must be
compared with one without it. To measure what the toolchain adds, the skill
must be compared with and without the toolchain. If the skill is installed in
the comparison condition, the agent may load it unprompted, since the skill
describes itself as the way to review a Compass document. If the conditions
differ in their instructions, instruction and installation are confounded.
Each repository's own `AGENTS.md` names the skills and the toolchain.

**Decision:** The reviewers:

Table: Reviewers compared in the defect-detection study.

| Reviewer | Installed | Models |
|---|---|---|
| V0 | The toolchain alone: `compass check` run by the harness, no agent | — |
| V1 | An agent with the `compass-*` skills and the toolchain | All three |
| V2 | An agent with the toolchain, without the skills | All three |
| V3 | An agent with the skills, without the toolchain (the skill's fallback path) | Claude Opus 5.5 |
| V4 | The steward, on the calibration sample | — |

- **The same prompt.** V1, V2, and V3 receive the same prompt: review the
  named document before it is accepted, and write the findings to
  `review.json` (COMPASS-DRAFT-eval-defect-detection-D8).
- **The repository's own `AGENTS.md`.** It stays in the workspace in every
  condition, so V2 and V3 meet the realistic case of a repository whose
  instructions name a tool that is missing.
- **Recorded use.** Whether the agent loaded the skill, and which `compass`
  commands it ran, are recorded as manipulation checks.
- **The models** are those of COMPASS-0006, at the reasoning effort fixed for
  Track 1. The judge is Gemini 4 Argon (COMPASS-DRAFT-eval-snapshot-D11).

*Conditions agreed in conversation.*

**Alternatives:** A generic instruction ("review this document") for V2 and
the skill's own invocation for V1, which confounds instruction with the
skill. The skill installed in every condition, as Track 1 does
(COMPASS-DRAFT-eval-snapshot-D16), which lets V2 become V1.

### COMPASS-DRAFT-eval-defect-detection-D4 — Documents from four corpora, pinned before the study's plans

**Status:** Proposed

**Context:** Reviewers should face real documents of every genre, written by
several hands and assistants, in more than one project. The Compass corpus at
HEAD contains this study's own Plan, which describes the kinds of defect
seeded. Lightdrive's documents were written after its code, and are less
typical of how Compass is used.

**Decision:**
- **The corpora.**

Table: Corpora from which documents are drawn.

| Corpus | Revision | Documents |
|---|---|---|
| Compass | `8716fc9`, before any of the evaluation plans | about 16, and the standard |
| Classic | `807640b` | 42 |
| Origin | `8bfc394` | 19 |
| Lexter | `4dcb194` | 21 |

- **Sampling.** Documents are sampled across genres and corpora, and each
  hosts at most two mutants.
- **Clean documents.** About 40 documents are left unmutated, sampled across
  genres and corpora.
- **The workspace** for a document is its whole repository at the pinned
  revision, prepared as COMPASS-DRAFT-eval-defect-detection-D7 describes.

*Agreed in conversation.*

**Alternatives:** The Compass corpus at HEAD, which describes the study.
Documents from one repository, which tests one style of writing. Lightdrive,
whose documents were written after its code.

### COMPASS-DRAFT-eval-defect-detection-D5 — Fifteen kinds of defect, eight of each, and forty clean documents

**Status:** Proposed

**Context:** Mutation testing seeds small, plausible faults of known kinds and
counts how many are found (DeMillo et al.). The kinds should cover what
`compass-review` claims to judge, plus a few mechanical faults the toolchain
must catch, as controls.

**Decision:** About 120 mutants, eight of each of fifteen kinds, and about 40
clean documents, about 160 documents in all:

Table: Kinds of defect seeded, with the review dimension each tests.

| Kind | Example | Dimension |
|---|---|---|
| Genre misfit | A Survey's section rewritten to decide rather than explore | Genre fit |
| Strawman alternatives | A decision's alternatives reduced to options no one would choose | Decision-record quality |
| Restated context | A decision's context replaced by a restatement of the decision | Decision-record quality |
| Wrong document | A link to a real document that does not concern what the text claims | Cross-reference plausibility |
| Wrong symbol | A code reference to a symbol that exists but is not the code described | Code-reference discipline |
| Contradicted claim | A statement about the code that the code at the pinned revision contradicts | Code-reference discipline |
| Memo admission | A memo whose claim is evident from the code, or is a design choice | Memo admission |
| Critique strawman | A finding's rationale that misstates the decision it attacks | Critique quality |
| Written resolution | A critique finding given a resolution by its critic | Critique quality |
| Accessibility | A table without a caption, or a skipped heading level | Accessibility |
| Assistant approval | `approved-by` naming the provenance assistant | Provenance and approval |
| Empty verification | A Log whose Verification names no command or count | Section shape |
| Thin prior art | A Survey's prior art cut to one weak comparison | Prior-art coverage |
| Unpinned reference | A code reference in a Log without a revision (mechanical) | Toolchain control |
| Unlisted record | A decision record missing from front-matter (mechanical) | Toolchain control |

- **Mutant specifications.** Each mutant is specified by its document, its
  kind, the original passage, the mutated passage, and a description of the
  defect for the judge.
- **Kinds without hosts.** A kind for which the corpora have too few hosts,
  such as critique findings, is seeded as often as its hosts allow, and its
  results are reported as descriptive.

*Agreed in conversation.*

**Alternatives:** Mechanical faults only, which tests the toolchain and not the
skill. Defects of one kind, which says little about the dimensions. Defects
written into documents made for the study, which would not be real Compass
documents.

### COMPASS-DRAFT-eval-defect-detection-D6 — Mutants are drafted by a non-subject model, reviewed by the steward, and leave the toolchain unchanged

**Status:** Proposed

**Context:** Mutants written by the people who know the skill may be the kind it
finds. A mutant drafted by a subject model may favour that model. A
judgement-level mutant that changes what `compass check` reports gives the
reviewer a clue no real defect would.

**Decision:**
- **Who writes them.** The steward writes some mutants. The rest are drafted
  by the model that drafts the other studies' material, from none of the
  subject labs and not the judge. The steward reviews every mutant for
  plausibility: would a competent author plausibly write it?
- **The gate for judgement-level mutants.** `compass check` must report
  exactly the same findings for the mutant as for its original, in the
  workspace of COMPASS-DRAFT-eval-defect-detection-D7.
- **The gate for mechanical mutants.** `compass check` must report exactly one
  new finding, from the intended rule.
- **The gate for clean documents.** The steward confirms that each clean
  document has no defect of the fifteen kinds that he knows of.

*Agreed in conversation.*

**Alternatives:** Every mutant written by the steward, which costs more of his
time and narrows the kinds of writing. Mutants drafted by a subject model.
Mutants that change the toolchain's findings, which tests the toolchain under a
judgement label.

### COMPASS-DRAFT-eval-defect-detection-D7 — Workspaces without Git, with derived fields written out

**Status:** Proposed

**Context:** A trial on Classic at `807640b` compared three workspaces:
- **Full history:** the original document is in the history, and a reviewer
  who runs `git log -p` on it sees the mutation as a change.
- **A single commit:** every commit-pinned code reference fails
  `ref/code-exists`, because the commits they name are absent. Classic reported
  162 errors there and none in its real repository. Those errors would be
  reported against every document, the original and the clean alike.
- **No Git:** `ref/code-exists` and the ledger rules do not run, and the
  toolchain reports a note saying so, the same for every document. But `authors`,
  `created`, and `updated`, which the corpora leave to Git, cannot be derived,
  and the review's approver check depends on `authors`.

A single commit with the pinned commits' objects added was also considered: those
commits can contain earlier versions of the document under review, which a
reviewer checking a reference would see.

**Decision:**
- **No Git in the workspace.** Each workspace is the repository's tree at the
  pinned revision, without `.git`.
- **Derived fields written out.** For every document of the corpus, the
  harness writes `authors`, `created`, and `updated` into front-matter, with
  the values `compass outline` derives in the real repository. This is the
  same for every document, mutated or not, and in every condition.
- **The mutant** is then applied to the document under review.
- **Expected notes.** The notes the toolchain reports in this workspace are
  expected and the same for every document. The prompt does not mention them.
- **Before the freeze,** the harness confirms for each corpus that
  `compass check` reports the same findings in the prepared workspace as in the
  real repository, apart from those notes.

**Alternatives:** Full history, which exposes the original. A single commit,
which reports false errors. A single commit with the pinned commits added,
which can expose the original. A wrapper that runs `compass check` with
`--exclude ref/code-exists`, which alters the tool under study.

### COMPASS-DRAFT-eval-defect-detection-D8 — Findings are written to a file and matched blind

**Status:** Proposed

**Context:** The skill writes a report in its own format, and an agent without
it writes whatever it likes. A judge that sees the report's format can tell the
conditions apart. A finding should count only if it identifies the defect, not
if it merely points at the right section.

**Decision:**
- **The findings file.** The prompt asks every reviewer to write
  `review.json`, with:
  - a list of findings, each with its location (file, section, or line), a
    description, and a severity of error, warning, or note;
  - a recommendation: accept, revise, reconsider genre, or needs a person's
    decision.

  Whatever else the reviewer writes is kept but not graded.
- **Matching.**
  - A toolchain finding is matched to a mechanical mutant by its rule and
    location, mechanically.
  - Other findings are matched to the mutant by Gemini 4 Argon. It sees the
    mutant's specification and the findings' locations and descriptions,
    without severities, recommendations, or any other text. A finding matches
    only if it names both the location and the nature of the defect.
- **Severity.** The severity of a matched finding is graded against the
  skill's guidance on what each severity means.
- **Recommendation.** A recommendation is correct if it is to revise for a
  mutant, and to accept for a clean document, unless a defect already in that
  document is confirmed (COMPASS-DRAFT-eval-defect-detection-D11).
- **Human calibration.** The steward blind-grades a stratified sample of 20%
  of the judge's matches. A measure is accepted for the judge at Cohen's
  κ ≥ 0.6; otherwise the steward grades it.
- **Read-only.** After each session, the harness compares the workspace with
  its prepared state. Any change, other than `review.json`, is recorded as a
  breach of the skill's rule that review only reads.

*Grading agreed in conversation.*

**Alternatives:** Grading the skill's report directly, which shows the judge
which condition it is. Matching by location alone, which credits a finding that
points at the right place for the wrong reason.

### COMPASS-DRAFT-eval-defect-detection-D9 — One run, with the dry run deciding how many documents a session reviews

**Status:** Proposed

**Context:** One document per session, with one run, is about 1,120 sessions:
160 documents × (two conditions × three models + one). Each session loads the
skill and its reference bundle and runs `compass check` over the corpus, which
is the larger part of its cost. A reviewer often reviews several documents at
once, as in a pull request, which shares that cost. Reviewing several documents
together correlates their findings. The budget is set in tokens.

**Decision:**
- **One run per cell.** Power comes from the number of mutants, not from
  repeats.
- **The dry run.** Eight documents kept out of the bank (four mutants and four
  clean) are reviewed by V1 and V2 with Claude Opus 5.5:
  - singly;
  - as two batches of four reviewed together, as in a pull request.

  It checks the workspace, the findings file, the matching, and the judge. It
  measures r, the tokens per document reviewed in a batch against singly.
- **The rule.** Batches of four are used only if r is at most 0.8 of
  1/(1 + 3ρ), where ρ is the correlation of outcomes within a batch, taken as
  0.2 unless the dry run estimates it (a bound of about 0.5). Otherwise each
  document is reviewed alone. If the chosen design is over budget, V3 is
  dropped first, and then the mutants per kind are cut from eight to six. The
  design chosen, with r, ρ, and the projected cost, is recorded before the
  freeze.
- **Batch composition.** A batch holds documents from one corpus, at most two
  of them mutants, of different kinds. The batches are the same in every
  condition and model.
- **Order.** Sessions are interleaved in a random order, blocked by document
  or batch.

*A dry run to decide the documents per session agreed in conversation.*

**Alternatives:** Two runs, which spends the budget on repeats. Always batching,
which saves tokens but correlates findings without first measuring the saving.

### COMPASS-DRAFT-eval-defect-detection-D10 — Hypotheses, measures, and analysis

**Status:** Proposed

**Context:** The comparisons that matter are the skill against no skill (V1
against V2), and the toolchain against none (V1 against V3). Each needs to be
stated before the runs. Saying that the skill raises no more false alarms is a
claim of non-inferiority, and needs a margin.

**Decision:** The proposed hypotheses, to be fixed in the protocol Eval at the
freeze:

Table: Proposed hypotheses of the defect-detection study.

| # | Hypothesis | Measure |
|---|---|---|
| DD-H1 | V1 finds more judgement-level defects than V2 | Recall of the thirteen judgement-level kinds |
| DD-H2 | V1 raises no more false alarms on clean documents than V2, within a margin of 0.5 per document | False alarms per clean document, from the adjudicated sample |
| DD-H3 | V1 finds more mechanical defects than V3 | Recall of the two mechanical kinds |

- **Descriptive measures:**
  - recall by kind, for every reviewer;
  - whether V1 reports every finding the toolchain reports, expected to be all
    of them, with every miss examined;
  - V0's recall, which is near zero for judgement-level kinds by construction
    (COMPASS-DRAFT-eval-defect-detection-D6), and complete for mechanical ones;
  - whether severities and recommendations fit;
  - breaches of the read-only rule;
  - whether the skill was loaded in V1 and V3, and the `compass` commands run;
  - cost per document;
  - all of these by model, by corpus, and by whether a document's
    provenance records an assistant, as a check on lenience towards text like
    the reviewer's own.
- **Analysis.**
  - For each model separately, a mixed-effects logistic model of detection,
    with reviewer as a fixed effect and random intercepts per mutant and per
    document, fitted with `lme4`. If the study is batched, a random intercept
    per batch is added.
  - False alarms are modelled as counts per clean document.
  - DD-H2 is tested by whether the upper bound of a one-sided 95% interval,
    from a bootstrap clustered by document, lies below the margin.
  - Holm's correction is applied across DD-H1 to DD-H3 for each model. DD-H3
    is tested on Claude Opus 5.5 only.
- **Power.** A power simulation before the freeze gives the smallest
  detectable difference in recall for DD-H1 and DD-H3.

**Alternatives:** Only descriptive results, which gives up the rehearsal of
confirmatory analysis. A hypothesis for each kind, which spends the correction
on kinds with eight instances.

### COMPASS-DRAFT-eval-defect-detection-D11 — Findings beyond the seeded defect are adjudicated by sample, and reported, not fixed

**Status:** Proposed

**Context:** Unmutated documents are not free of defects. Classic's stale
`Current` references are one example (COMPASS-DRAFT-eval-snapshot-D3). A
finding that does not match a mutant may be true. Counting every such finding
as a false alarm would penalise a careful reviewer, and adjudicating every one
would cost too much of the steward's time.

**Decision:**
- **Adjudication.** The steward adjudicates a stratified sample of findings
  that match no mutant, as true or false. Precision and false-alarm rates are
  estimated from the sample, with intervals.
- **Real defects.** Defects confirmed in a document are reported to the
  steward for the repository they belong to. They are not fixed during the
  study, which would change its inputs.
- **Recommendations.** A clean document with a confirmed defect is scored as
  a document needing revision.

*Agreed in conversation.*

**Alternatives:** Counting every unmatched finding as false, which penalises
true findings. Adjudicating every finding, which costs too much. Fixing defects
as they are found, which changes the documents mid-study.

### COMPASS-DRAFT-eval-defect-detection-D12 — A protocol Eval and a Log, published internally first

**Status:** Proposed

**Context:** The study needs a record of its protocol and results, a record of
its work, and a place in the harness. The steward chose to keep its results
internal at first, and to consider them later as part of a wider paper on
Compass.

**Decision:**
- **Documents.**
  - This Plan, in the `authoring-assistance` component.
  - The protocol Eval, `doc/Eval.DefectDetection.md`
    (COMPASS-DRAFT-eval-defect-detection-D2), with its results appended.
  - A Log, `doc/Log.EvalDefectDetection.md`, written after the commits that
    hold each stage. It records the mutant bank, the dry run, the runs,
    deviations, and the lessons for the other studies.
- **The harness** gains a review as a kind of task, with a descriptor for each
  corpus in `eval/`. The mutant bank lives in `eval/tasks/defect-detection/`.
- **Publication.** The results are internal at first: the protocol Eval and
  the Log. Whether and where they are published, for example as part of a
  later paper on Compass as a whole, is decided after the study
  (COMPASS-DRAFT-eval-defect-detection-O3).

*Names and publication agreed in conversation.*

**Alternatives:** Results only in the Log, which mixes evidence with the
account of the work. A paper of its own at once, which commits to publication
before the results are known.

## Workflow of a Session

1. The harness prepares the workspace: the repository's tree at the pinned
   revision, without Git, with derived fields written out, the mutant applied
   if there is one, and the tools installed for the condition.
2. The prompt names the document, or the documents of a batch, and asks for a
   review before acceptance, with the findings written to `review.json`. It is
   the same in V1, V2, and V3.
3. The agent reviews. The harness records the session
   (COMPASS-DRAFT-eval-snapshot-D13), including whether the skill was loaded
   and which commands ran.
4. The harness checks that the workspace is unchanged apart from
   `review.json`, matches toolchain findings mechanically, and queues the other
   findings for the judge.

## Tensions and Risks

- **Mutants are not real defects.** Seeded defects may be easier, or harder,
  to find than the ones authors actually make. The steward's review of every
  mutant for plausibility reduces this. The real defects found in clean documents
  (COMPASS-DRAFT-eval-defect-detection-D11) give some evidence of the gap.
- **The workspace is not a real repository.** Without Git, a reviewer cannot
  see a document's history, which a person reviewing it might use, and
  `ref/code-exists` does not run. The study measures review of a document as it
  stands.
- **Public documents.** Classic, Origin, and Lexter are public. A model that
  has seen a document may recognise a change to it. The corpora pinned are
  recent, mostly from after the models' release, but some documents predate
  it.
- **The skill and toolchain change.** The study measures the versions frozen at
  its freeze. Its results inform revisions, after which the skill measured is
  no longer the skill in use.
- **Small numbers per kind.** Eight mutants per kind gives wide intervals for
  each kind. Only the pooled comparisons are confirmatory.

## Open Questions

### COMPASS-DRAFT-eval-defect-detection-O1 — The token budget

The dry run's rule (COMPASS-DRAFT-eval-defect-detection-D9) needs the token
budget stated before it runs. What is it? If batching is used, should a batch
size other than four be tried?

### COMPASS-DRAFT-eval-defect-detection-O2 — A Guide for running Compass studies

This study is the first to go through the whole process. Should that process
(Plan, protocol Eval, freeze, seal, runs, Log, results) be written down
afterwards as a how-to Guide, so that later studies, including ones run by
others, follow it?

### COMPASS-DRAFT-eval-defect-detection-O3 — Publication

The results are internal at first. Should they later form part of a wider paper
on Compass, on its standard, toolchain, and review, rather than a paper of their
own? Which paper, and when?

### COMPASS-DRAFT-eval-defect-detection-O4 — The same workspace problem in Track 1

Track 1 isolates its workspaces as single-commit repositories
(COMPASS-DRAFT-eval-snapshot-D6), and requires `compass check` to report no
errors in the A2 workspace (COMPASS-DRAFT-eval-snapshot-D3). In such a
workspace, every commit-pinned code reference in A2's corpus fails
`ref/code-exists`. A2–A4 agents that run the toolchain would then see errors
A1 agents cannot. The question-answering study inherits this. Should Track 1
use workspaces without Git, as this study does, or history up to `bad2094` and
no later, or another remedy? The question belongs to Track 1's Plan, and is
recorded here because this study found it.

### COMPASS-DRAFT-eval-defect-detection-O5 — How many mutants the steward writes

The steward writes some mutants and reviews all of them. How many should he
write himself, so that both sources are represented in every kind, and should
results be reported by source?

## Prior Art

Table: Prior work and what this plan takes from each.

| Work | What to draw from |
|---|---|
| Mutation testing (DeMillo et al., 1978) | Seeding small, plausible faults of known kinds, and measuring what is found |
| SWE-smith (2025) | Defects made by changing real artefacts, and kept only if a check confirms them |
| ADR violation detection (2026) | The closest study found: language models judging whether code violates a recorded decision, with human ground truth on a sample |
| Tufano et al. (2026) | A judge that sees anonymised material, with a majority over passes |
| MOOSEDev (2026) | A warning that grading artefacts can produce large false effects |
| ACM SIGSOFT Empirical Standards | The reporting checklist |

## Roadmap

1. **This Plan.** The steward accepts its decisions and states the token budget
   (COMPASS-DRAFT-eval-defect-detection-O1).
2. **Harness, first part,** with tests in `compass-eval/tests`:
   - the `compass-eval` system and descriptors for the four corpora;
   - workspace preparation without Git, with derived fields written out, and
     the check that the toolchain's findings match the real repository's;
   - the runner, recorder, and installation of each condition;
   - `review.json` collection and the read-only check;
   - the judge's pipeline for matching.

   The first part of `doc/Log.EvalDefectDetection.md` is written after the
   commit. Track 1's Log records the shared parts when its own work begins.
3. **Mutant bank.**
   - Documents and clean documents sampled.
   - Mutants written by the steward and drafted by the drafting model.
   - The steward's plausibility review, and the toolchain gates.
   - Batches built, if they are needed.
4. **Dry run** on eight documents kept out of the bank. Apply the rule of
   COMPASS-DRAFT-eval-defect-detection-D9 and record the design chosen.
5. **Analysis and freeze.**
   - The R scripts, run on simulated data.
   - The power simulation.
   - The protocol Eval written.
   - The steward's commit and tag.
6. **Runs,** interleaved.
7. **Operational review and grading.**
   - Failures, cost, and manipulation checks.
   - The judge's validation and the steward's calibration sample.
   - Adjudication of the sample of unmatched findings.
8. **Results.**
   - The analysis appended to the protocol Eval as a dated update.
   - Real defects reported to the steward.
   - The lessons for the question-answering study and Track 1 proposed as
     revisions to their Plans.
   - Decisions on COMPASS-DRAFT-eval-defect-detection-O2 and
     COMPASS-DRAFT-eval-defect-detection-O3.
