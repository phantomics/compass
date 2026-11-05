---
id:            COMPASS-DRAFT-eval-corpus-qa
title:         Compass Corpus Question-Answering Study — Does Project Knowledge Reach the Agent?
genre:         Plan
scope:         program
program:       Compass
component:     agent-context
language:      en
status:        Draft
provenance:
  assistant:   opencode
  session:     "Design conversation on Track 1 and peripheral studies, 2026-11-05"
relates-to:
  - COMPASS-0006
  - COMPASS-DRAFT-eval-snapshot
  - COMPASS-0010
  - COMPASS-0004
  - COMPASS-0008
  - COMPASS-DRAFT-positioning
cites:
  - title:     "Ontology-Grounded Project Memory for Coding Agents (Adam; NeSy 2026)"
    locator:   "arXiv:2608.13662, §3 (question classes, strict judge, currency trials) and §4 (lessons)"
    external:  true
  - title:     "When and How Context Rot Appears in Coding Agents (Xue, 2026)"
    locator:   "arXiv:2607.17937v2, §2.3 (stages from activation to verification)"
    external:  true
  - title:     "Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents? (Gloaguen, Mündler, Müller, Raychev, Vechev; MemAgents @ ICLR 2026)"
    locator:   "arXiv:2602.11988v2, App. B (documentation removed)"
    external:  true
  - title:     "Do Context Files Help Coding Agents? A Two-Agent Ablation Study on Real Repositories (Khatri, 2026)"
    locator:   "arXiv:2607.27250, §4.5 (power) and §5.2 (manipulation-validity probe)"
    external:  true
  - title:     "Grounding AI Agents in Contracts: An Empirical Evaluation of Spec-Driven Test Generation (Tufano et al.; SpecOps '26)"
    locator:   "arXiv:2608.17177v2, §4 (judge protocol)"
    external:  true
  - title:     "Empirical Standards for Software Engineering Research (Ralph et al., ACM SIGSOFT)"
    locator:   "arXiv:2010.03525v2; the Experiments and Registered Reports standards"
    external:  true
decisions:
  - COMPASS-DRAFT-eval-corpus-qa-D1
  - COMPASS-DRAFT-eval-corpus-qa-D2
  - COMPASS-DRAFT-eval-corpus-qa-D3
  - COMPASS-DRAFT-eval-corpus-qa-D4
  - COMPASS-DRAFT-eval-corpus-qa-D5
  - COMPASS-DRAFT-eval-corpus-qa-D6
  - COMPASS-DRAFT-eval-corpus-qa-D7
  - COMPASS-DRAFT-eval-corpus-qa-D8
  - COMPASS-DRAFT-eval-corpus-qa-D9
  - COMPASS-DRAFT-eval-corpus-qa-D10
open-questions:
  - COMPASS-DRAFT-eval-corpus-qa-O1
  - COMPASS-DRAFT-eval-corpus-qa-O2
  - COMPASS-DRAFT-eval-corpus-qa-O3
  - COMPASS-DRAFT-eval-corpus-qa-O4
  - COMPASS-DRAFT-eval-corpus-qa-O5
---

# Compass Corpus Question-Answering Study: Development Plan

This plan sets out a study that runs alongside Track 1 of
[COMPASS-0006](Eval.AgentContext.md). Agents answer questions about Classic
from the same workspaces Track 1 builds, and the answers show whether a
project's knowledge reaches the agent: whether it finds the guidance, reads
its status correctly, and can say what was rejected and why. Track 1 measures
whether agents *act* on that knowledge. Together the two separate knowledge
that never arrives from knowledge that arrives but does not change behaviour.
The study reuses the instruments designed in
[COMPASS-DRAFT-eval-snapshot](Plan.EvalSnapshot.md) and adds only what
answering questions needs. It is the first of the peripheral studies discussed
for COMPASS-0006's research agenda. Its question classes draw on MOOSEDev,
assessed in [COMPASS-0010](Eval.PriorArt.AgentContext.md), and on the
competency questions of [COMPASS-DRAFT-positioning](Survey.Positioning.md).

## Problem

- **Track 1 cannot say why typing fails, if it does.** A trap task fails
  whether the agent never found the guidance, misread its status, or read it
  correctly and ignored it. Xue locates failures at the stage where a
  requirement stops affecting behaviour. Track 1 observes only the last stage.
- **The supersession claim rests on retrieval evidence alone.** MOOSEDev
  showed that typed records answer supersession, completeness, and negation
  questions where vector retrieval fails. Its agents answered from the store
  alone, not from a repository with code and documents, and the documents
  were not in a standard form.
- **Statuses as practised make the question sharper.** Track 1 reproduces
  Classic's statuses at HEAD, where stale documents are `Current`
  (COMPASS-DRAFT-eval-snapshot-D3). Whether such labels mislead an agent is
  easiest to see when the agent is asked directly what the current guidance is.
- **Track 1 has few items.** Its trap hypotheses can detect only large
  effects. Questions are cheap to write and to run, so a study of knowledge can
  have many more items and far better power.
- **The harness has no shakedown.** Track 1's first real sessions are its
  pilot. A cheaper study run first would exercise the workspaces, the runner,
  the recorder, and the judge before any Track 1 data exist.

## Goals

- Pre-registered estimates, per model, of how the form and delivery of
  Classic's documents affect what agents know about the project, for each class
  of question.
- Single-feature ablation at the stage of knowledge, matching Track 1's at the
  stage of action.
- An item-by-item link to Track 1's trap tasks, so that each piece of knowledge
  can be classed as not reached, reached but not acted on, or acted on.
- A first use of the harness and judge that finds their faults before Track 1
  is frozen, without letting this study's results shape Track 1's design.
- A section of the Track 1 paper, written so that it can grow into a paper of
  its own.

## Settled Decisions

All ten decisions are proposals for the steward. Those agreed in the design
conversation of 2026-11-05 are marked so.

### COMPASS-DRAFT-eval-corpus-qa-D1 — A separate, pre-registered study on Track 1's instruments

**Status:** Proposed

**Context:** The study needs a snapshot, corpora, isolated workspaces, a judge,
a harness, and run records, all of which Track 1 designs. Restating them would
let the two studies drift apart. The study is not part of COMPASS-0006's
protocol, which is about to be frozen, and adding to that protocol now would
blur what it registers. The steward wants the study pre-registered.

**Decision:**
- **Reuse by reference.** The study uses these Track 1 decisions unchanged:
  - the snapshot (COMPASS-DRAFT-eval-snapshot-D2);
  - the corpora, with statuses as practised (COMPASS-DRAFT-eval-snapshot-D3);
  - overlays and ablations (COMPASS-DRAFT-eval-snapshot-D4);
  - `AGENTS.md` in every setup (COMPASS-DRAFT-eval-snapshot-D5);
  - isolation (COMPASS-DRAFT-eval-snapshot-D6);
  - the judge (COMPASS-DRAFT-eval-snapshot-D11);
  - the harness (COMPASS-DRAFT-eval-snapshot-D12);
  - run records (COMPASS-DRAFT-eval-snapshot-D13);
  - the Compass tools in every workspace (COMPASS-DRAFT-eval-snapshot-D16).

  A change to one of these applies to both studies, and is recorded in both.
- **Its own protocol and freeze.** Its hypotheses, measures, and analysis are
  frozen in a protocol Eval of its own (COMPASS-DRAFT-eval-corpus-qa-D10),
  separately from and earlier than Track 1's.
- **No decision rules of its own.** Its results are reported as evidence
  bearing on the decisions COMPASS-0006's rules act on, chiefly COMPASS-D15 and
  COMPASS-D16. Only COMPASS-0006's rules change those decisions.

*Pre-registration agreed in conversation.*

**Alternatives:**
- **A part of COMPASS-0006.** This blurs the frozen protocol.
- **A part of the Track 1 Plan.** This mixes two studies with different
  freezes and results in one Plan.
- **Decision rules of its own.** These could fire on knowledge alone, before
  anything is known about behaviour, which is the measure the decisions care
  about.

### COMPASS-DRAFT-eval-corpus-qa-D2 — It runs before Track 1's pilot, with its effects sealed until Track 1 is frozen

**Status:** Proposed

**Context:** The study needs Track 1's corpora, workspaces, runner, recorder,
and judge, but not its test grading, so it can run as soon as those exist. Run
early, it shakes down the harness. But if its results by setup were seen
before Track 1 is frozen, they could shape Track 1's tasks, sizes, or
analysis: an undeclared choice made after seeing data.

**Decision:**
- **When it runs.** After its own freeze, between Track 1's roadmap stage 3
  (corpora) and stage 7 (Track 1's freeze).
- **What is seen at once.** Operational data are examined immediately:
  - failed and rerun sessions;
  - cost and duration;
  - manipulation checks;
  - redaction;
  - the judge's validation and the steward's calibration grades.

  Faults they reveal in the shared instruments are fixed before Track 1's
  freeze and recorded in both studies' Logs.
- **What is sealed.** Results broken down by setup are not computed or shown
  to the steward until Track 1 is frozen. Calibration grading is blind to
  setup, as in Track 1.
- **After Track 1's freeze,** the analysis is run and reported.

*Running before the pilot agreed in conversation.*

**Alternatives:**
- **Run it after Track 1's freeze.** This loses the shakedown: a fault found
  then would change a frozen harness.
- **Run it before the freeze and look at its results.** This lets them inform
  Track 1's design without that being declared.

### COMPASS-DRAFT-eval-corpus-qa-D3 — Seven setups, each a full workspace

**Status:** Proposed

**Context:** Track 1's setups differ in the form and delivery of the same
facts. A setup without documents shows which answers can be recovered from the
code. A3's catalog may answer some questions outright, which measures delivery
directly. MOOSEDev's agents read a store, not a repository; an agent at work has
code and documents both.

**Decision:**
- **The setups:** A0 (the code, no documents), A1, A2, A3, A2−S, A2−R, and
  A2−L, as Track 1 defines them. A4 is optional and included if the budget
  allows (COMPASS-DRAFT-eval-corpus-qa-O1).
- **The workspace.** Every session gets the full workspace of its setup: code,
  documents, `AGENTS.md`, and the Compass tools.
- **Seeded supersession.** Questions use the overlays of the linked Track 1
  tasks.
- **Real-history supersession** is answered under statuses as practised and
  reported separately, as in Track 1.

**Alternatives:** Documents only, which tests retrieval rather than the agent's
working situation and is left as an open question
(COMPASS-DRAFT-eval-corpus-qa-O2). A1 and A2 only, which loses the floor A0
gives, the delivery comparison, and the ablations.

### COMPASS-DRAFT-eval-corpus-qa-D4 — About 120 questions in eight classes, linked to Track 1's traps

**Status:** Proposed

**Context:** Each class tests a different property the typed corpus claims to
provide. MOOSEDev's classes (completeness, negation, supersession) are the ones
similarity retrieval fails on. A question that A1's workspace cannot answer
measures content, not form. Wording in Compass's own terms favours the setups
that use them.

**Decision:**
- **The classes.** About 120 questions, roughly 15 per class:

Table: Question classes, with an example of each and what it tests.

| Class | Example | What it tests |
|---|---|---|
| Current truth | How must a new schema's package be named? | Whether the agent gives present guidance |
| Supersession | What replaced the global table of federation provenance? | Whether the agent tells history from current truth |
| Rejected alternative | What other ways of validating slot values were considered, and why were they not used? | Whether recorded alternatives are found, with their reasons |
| Completeness | List every design decision made about deleting entities. | Whether the agent finds all of a set, not some |
| Negation | Was automatic persistence after a workflow transition ever adopted? | Whether the agent can establish an absence |
| Location | Which file enforces the moderation permission on forum posts? | Navigation |
| Rationale | Why does federation receipt not use `attempt-transition` for retractions? | Whether reasons are found, not only outcomes |
| False premise | Why did the project choose to sign federation messages with a key per peer? | Whether the agent rejects a false premise rather than inventing an answer; no such decision was made |

- **Linked items.** Each Track 1 trap task has one linked question about the
  knowledge its trap turns on. These count within the 120.
- **Gates.** A question enters the bank only when:
  - its answer can be established from A1's workspace;
  - its answer key was written from primary sources (the `bad2094`
    documents, the code at the snapshot, and Classic's Git history) without
    consulting the typed corpus;
  - its wording uses no Compass vocabulary (no "decision record", no
    "superseded", no identifiers), checked by a scan and by review;
  - the steward has verified its answer key.
- **Answer-key fields.** Each key records the answer, its sources, and, where
  relevant, the superseded guidance or rejected design an incorrect answer
  would give.

*Steward verification of every answer key agreed in conversation.*

**Alternatives:**
- **Fewer, broader questions.** These lose power and make grading harder.
- **Questions only about the trap tasks.** These lose the classes that have
  no trap.
- **Answer keys written from A2.** These would let the typed form define what
  counts as correct.

### COMPASS-DRAFT-eval-corpus-qa-D5 — Trap tasks first, then questions drafted by a non-subject model

**Status:** Proposed

**Context:** Track 1 asks the steward to write trap tasks from development
experience before re-reading the corpus (COMPASS-DRAFT-eval-snapshot-D7).
Writing questions means reading the corpus closely, and the linked questions
need the trap tasks to exist. A question drafted by a subject model may favour
that model.

**Decision:**
- **Order.** Questions are written after Track 1's trap tasks.
- **Drafting.** They are drafted by the model that drafts Track 1's task
  statements: one from none of the subject labs, and not the judge. The
  drafting model works from A1's documents and the code, so that its wording
  owes nothing to the typed form.
- **Review.** The steward reviews every question and verifies every answer
  key.

*Agreed in conversation.*

**Alternatives:** The steward writing the questions before the trap tasks,
which breaks Track 1's rule. Drafting from A2, which risks Compass vocabulary
in the questions.

### COMPASS-DRAFT-eval-corpus-qa-D6 — Answers are structured and written to a file

**Status:** Proposed

**Context:** Free answers are graded only by a judge. A list answer can be
scored mechanically if it is a list. Which source an agent relied on shows, on
a supersession question, whether it trusted the stale document or its
successor, but sources name paths and identifiers that reveal the setup to a
judge. A final chat message is awkward to parse reliably.

**Decision:**
- **The answer file.** The agent writes `answer.json` at the workspace root,
  outside `doc/`. It holds:
  - a short answer;
  - a list of items, for completeness and location questions;
  - the files relied on;
  - a confidence between 0 and 1.
- **The schema** is given in the session's prompt, identically in every
  setup.
- **Invalid answers.** A missing or malformed file scores as wrong and is
  counted in its own denominator. It is not rerun.

**Alternatives:** Free answers in the final message, which cannot be scored
mechanically. Sources left out, which loses the attribution measure.

### COMPASS-DRAFT-eval-corpus-qa-D7 — Mechanical scoring where possible, a strict blinded judge elsewhere

**Status:** Proposed

**Context:** MOOSEDev's judge accepted paraphrase but rejected answers on the
right topic with the wrong facts. It warns that grading artefacts can produce
large false effects. Answers are short, so a larger human sample costs little.
Tufano randomises and anonymises what the judge sees.

**Decision:**
- **Mechanical scoring.**
  - Location, negation, and false-premise answers are scored against the key.
  - Completeness answers are scored by set overlap (F1), with full credit at
    an F1 of 1 and the F1 itself as a secondary measure.
- **The judge.** Current truth, supersession, rejected-alternative, and
  rationale answers are graded by Gemini 4 Argon (COMPASS-DRAFT-eval-snapshot-D11).
  - It grades against the key, strictly.
  - It sees the question, the key, and the short answer only: no sources and
    no paths.
  - Each answer is judged three times in random order, and the majority stands.
- **Coded errors.** Two kinds of wrong answer are coded:
  - a *supersession error*, where the answer gives the superseded guidance the
    key names;
  - a *confabulation*, where the answer accepts a false premise.
- **Attribution.** The cited sources are compared mechanically with the key's
  sources, to classify which document the agent relied on.
- **Human calibration.** The steward blind-grades a stratified sample of 20%
  of judged answers. A measure is accepted for the judge at Cohen's κ ≥ 0.6;
  otherwise the steward grades it.

**Alternatives:** A judge for every answer, which spends judgement on what can
be counted. A judge that sees sources, which reveals the setup.

### COMPASS-DRAFT-eval-corpus-qa-D8 — One question per session, two runs, three models

**Status:** Proposed

**Context:** Several questions in one session cost less, but an earlier answer
can inform a later one, and their order then matters. Khatri finds that more
items buy more power than more repeats. The models are those of COMPASS-0006.

**Decision:**
- **Sessions.** Each session asks one question, in a fresh workspace, with a
  wall-clock limit of 15 minutes and a token limit fixed at freeze.
- **Runs.** Each question runs twice per setup and model, for all three
  models, interleaved in a random order blocked by question. That is about
  5,000 sessions (120 × 7 × 3 × 2), or about 5,800 with A4.
- **Dry run.** A run of 10 questions kept out of the bank, on A1 and A2 with
  Claude Opus 5.5, checks the answer format and the scorer before the freeze.
  It is not analysed.

**Alternatives:** Batches of five questions per session, which are cheaper but
confounded by order and carry-over (COMPASS-DRAFT-eval-corpus-qa-O1). Five runs
per cell, as in Track 1, which spends the budget on repeats rather than items.

### COMPASS-DRAFT-eval-corpus-qa-D9 — Hypotheses by class, a model per family, and a linkage analysis

**Status:** Proposed

**Context:** Each hypothesis mirrors one of Track 1's, at the stage of
knowledge. Classes that turn on what the typed form claims to provide are
confirmatory; classes the code can answer are descriptive against the floor
A0 sets. Statuses as practised make real-history supersession a test of
practice, not of the mechanism.

**Decision:** The proposed hypotheses, to be fixed in the protocol Eval at
freeze:

Table: Proposed hypotheses of the question-answering study and their Track 1
counterparts.

| # | Hypothesis | Measure | Track 1 counterpart |
|---|---|---|---|
| QA-H1 | A2 answers rejected-alternative questions better than A1 | Accuracy on the class | T1-H8 |
| QA-H2 | A2 and A3 make fewer supersession errors than A1 on seeded pairs, and A2−S loses the gain | Supersession errors | T1-H7 |
| QA-H3 | A2 answers completeness and negation questions better than A1 | Accuracy; F1 | T1-H1 |
| QA-H4 | A2 confabulates less than A1 on false-premise questions | Confabulations | — |
| QA-H5 | Each ablation lowers accuracy on its classes: A2−S on supersession, A2−R on rejected alternatives and rationale, A2−L on completeness and location | Accuracy by class | T1-H9 |
| QA-H6 | A3 answers more accurately than A2, or at a lower cost per correct answer | Accuracy; cost | T1-H3 |

- **Exploratory and descriptive.**
  - Real-history supersession under statuses as practised is exploratory and
    tested two-sided.
  - Current truth, location, and rationale are reported descriptively against
    A0.
- **Model.** For each model separately, a mixed-effects logistic model with
  setup as a fixed effect and a random intercept per question, fitted with
  `lme4`. Pairs of setups are compared with question-clustered bootstrap
  intervals.
- **Families.** Holm's correction is applied within each family, for each
  model: knowledge (QA-H1 to QA-H4), ablation (QA-H5), and delivery (QA-H6).
- **Power.** A power simulation before the freeze gives the smallest
  detectable effect of each confirmatory test.
- **Linkage analysis.** This is specified at freeze and run after Track 1's
  full study.
  - For each trap task, setup, and model, the linked question's accuracy is
    set against the trap task's clean-pass rate.
  - Each piece of knowledge is then classed as not reached, reached but not
    acted on, or acted on, with thresholds fixed at freeze.
  - The analysis is descriptive.

**Alternatives:** Every class confirmatory, which spends the correction on
classes the code answers. A pooled model across models as the primary result,
which COMPASS-0006 rejects for Track 1.

### COMPASS-DRAFT-eval-corpus-qa-D10 — A protocol Eval, a Log, and a section of the Track 1 paper

**Status:** Proposed

**Context:** Track 1 keeps its protocol and results in COMPASS-0006 and its
build in a Plan and a Log. This study is not part of COMPASS-0006, so its
results need their own home. The steward chose to write the study first as a
section of the Track 1 paper, which can grow into a paper of its own if the
results are strong.

**Decision:**
- **The protocol Eval.** At freeze, a protocol Eval, `doc/Eval.CorpusQA.md`
  (subtype `comparison`), is written from this Plan:
  - Method;
  - the Shared Scenario, by reference to Track 1's snapshot;
  - the Rubric, with the hypotheses of COMPASS-DRAFT-eval-corpus-qa-D9.

  The steward freezes it with a commit and tag. Results are appended to it as
  dated updates, and its Synthesis is written from them.
- **The Log.** `doc/Log.EvalCorpusQA.md` records the question bank, the dry
  run, the runs, and deviations, written after the commits that hold them.
  Changes to the shared harness stay in Track 1's Log.
- **COMPASS-0006.** It gets a row in its Research Agenda appendix, and later a
  short dated update that points to the results.
- **The paper.** The study is written as a section of the Track 1 paper, in
  `pub/snapshot-study/`, on the mechanism behind Track 1's results. It moves
  to `pub/corpus-qa/` as a paper of its own if the steward judges the results
  strong enough (COMPASS-DRAFT-eval-corpus-qa-O4).

*Paper section first, with the option to stand alone, agreed in conversation.*

**Alternatives:**
- **Results in this Plan.** This puts evidence in a design document.
- **Results appended to COMPASS-0006.** These were never part of its protocol.
- **A standalone paper from the start.** This commits to a paper before it is
  known whether the results carry one.

## Workflow of a Session

1. The harness assembles the workspace of the setup, applies the overlay of
   the question's linked Track 1 task if it has one, and starts a session in an
   isolated container.
2. The prompt gives the question and the schema of `answer.json`, and asks the
   agent to answer from the repository. It is identical in every setup.
3. The agent explores and writes `answer.json`. The harness records the run
   (COMPASS-DRAFT-eval-snapshot-D13).
4. The harness scores the mechanical classes. It strips the sources from
   answers in the other classes and queues them for the judge.

## Tensions and Risks

- **Knowing is not doing.** A gain here does not show a gain in behaviour,
  and the study must not be reported as if it did. The linkage analysis is
  what connects the two.
- **Questions written by people who know the answers.** Answer keys from
  primary sources, neutral wording, and drafting by a non-subject model reduce,
  but do not remove, a bias towards questions the typed form answers well.
  False-premise and location questions, which typing should not help much,
  serve partly as a check on this.
- **The steward's time.** Verifying about 120 answer keys and grading a 20%
  sample is substantial (COMPASS-DRAFT-eval-corpus-qa-O5).
- **The seal.** It relies on the harness not computing results by setup
  before Track 1 is frozen. The analysis scripts refuse to run before a flag
  that records the date of Track 1's freeze is set.
- **Shared instruments.** A fault found here changes Track 1's harness before
  its freeze. It must be recorded in both Logs, and any sessions it affected
  are rerun.

## Open Questions

### COMPASS-DRAFT-eval-corpus-qa-O1 — Batching and A4, if the budget is short

About 5,000 sessions is the default. If the budget is short, the candidates are
batching questions five to a session in random order, dropping a model, and
leaving out A4. Which comes first, and should a small batched arm be run anyway
to measure the effect of order?

### COMPASS-DRAFT-eval-corpus-qa-O2 — A documents-only arm

A setup in which the agent sees only the documents would test retrieval as
MOOSEDev did, and make the two studies comparable. It would add about 700
sessions. Is the comparison worth it, and in which setups?

### COMPASS-DRAFT-eval-corpus-qa-O3 — A structured-query arm

When the RDF export (COMPASS-D21) exists, an arm in which agents may query the
corpus with SPARQL would turn this study into study 6 of COMPASS-0006's
research agenda (structured query against search). Should the question bank be
written so that it can be reused for that arm, with each key also stating the
query that answers it?

### COMPASS-DRAFT-eval-corpus-qa-O4 — When the section becomes a paper

The study begins as a section of the Track 1 paper. What would make it strong
enough to stand alone: effects of a stated size on the confirmatory classes, a
clear result from the linkage analysis, or a workshop whose deadline falls
before Track 1 ends? And which workshop?

### COMPASS-DRAFT-eval-corpus-qa-O5 — The steward's time, and a second verifier

The steward verifies every answer key and grades a 20% sample of judged
answers. Should a second person verify a sample of the keys, which would allow
agreement on the keys to be reported, and should the time spent be recorded
for study 10 of COMPASS-0006's research agenda?

## Prior Art

Table: Prior work and what this plan takes from each.

| Work | What to draw from |
|---|---|
| MOOSEDev (Adam, 2026) | The classes of completeness, negation, and supersession; a strict judge; answer keys from primary sources; currency trials with real reversals of decisions |
| Xue (2026) | The stages at which a requirement is lost, and the separation of acquiring a requirement from carrying it out |
| Gloaguen et al. (2026) | The finding that context helps most when no other documentation supplies the knowledge, which A0 tests directly |
| Khatri (2026) | More items rather than more repeats; a probe of whether the manipulation took effect |
| Tufano et al. (2026) | Randomised, anonymised judging with a majority over passes |
| COMPASS-DRAFT-positioning | The competency questions, whose classes this bank shares |
| ACM SIGSOFT Empirical Standards | The reporting checklist |

## Roadmap

1. **This Plan.** The steward accepts its decisions and adds its row to
   COMPASS-0006's Research Agenda appendix.
2. **Question bank,** after Track 1's corpora (its stage 3) and trap tasks
   (part of its stage 4).
   - The drafting model drafts from A1 and the code.
   - The steward reviews each question and verifies each answer key.
   - The gates of COMPASS-DRAFT-eval-corpus-qa-D4 are applied, with the scan
     for Compass vocabulary.
3. **Harness additions,** with tests in `compass-eval/tests`:
   - a question as a kind of task in the snapshot descriptor;
   - collection and validation of `answer.json`;
   - the mechanical scorer;
   - the judge's rubric for answers;
   - the seal on the analysis.
4. **Dry run** on 10 questions kept out of the bank.
5. **Freeze.**
   - The power simulation and the table of smallest detectable effects.
   - The protocol Eval written.
   - The steward's commit and tag.
6. **Runs:** about 5,000 sessions, interleaved.
7. **Operational review:**
   - failures, cost, and manipulation checks;
   - the judge's validation;
   - the steward's calibration sample;
   - any faults in the shared instruments fixed and recorded, with affected
     sessions rerun.

   Results by setup stay sealed.
8. **Unsealing,** after Track 1's freeze.
   - The analysis, appended to the protocol Eval as a dated update.
   - A short dated update to COMPASS-0006.
   - The Log brought up to date.
9. **Linkage analysis,** after Track 1's full study, and the section of the
   Track 1 paper. A decision on COMPASS-DRAFT-eval-corpus-qa-O4.
