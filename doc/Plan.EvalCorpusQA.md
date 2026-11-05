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
  questions where vector memory and flat notes fail. Its records were typed by
  the project's own ontologies and held in its own graph store, not written as
  documents under a published standard, and its questions tested what the
  memory could answer, not how agents fare in a repository whose documents are
  typed.
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
  A change made after this study's freeze, such as a fault fixed during its
  operational review (COMPASS-DRAFT-eval-corpus-qa-D2), is recorded as a
  deviation in its protocol Eval, and the sessions it affected are rerun
  under the corrected version.
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

**Context:** The study needs Track 1's corpora, its trap tasks (for the linked
questions), and its workspaces, runner, recorder, and judge, but not its test
grading, so it can run as soon as those exist. Run early, it shakes down the
harness. But if its results by setup were seen before Track 1 is frozen, they
could shape Track 1's tasks, sizes, or analysis: an undeclared choice made
after seeing data. Cost by setup is such a result: it is this study's measure
for QA-H7 and bears on Track 1's rule about the cost of the catalog.

**Decision:**
- **When it runs.** After its own freeze, between Track 1's roadmap stage 5
  (runner, recorder, grader, and judge) and stage 7 (Track 1's freeze). It is
  on Track 1's critical path, and Track 1's roadmap records it.
- **What is seen at once.** Operational data are examined immediately, pooled
  across setups:
  - cost, duration, and tokens;
  - manipulation checks and redaction;
  - the judge's validation and the steward's calibration grades.

  Only counts of failed, invalid, and rerun sessions are shown by setup, so
  that a setup the harness handles badly is found. Faults these data reveal in
  the shared instruments are fixed before Track 1's freeze and recorded in both
  studies' Logs (COMPASS-DRAFT-eval-corpus-qa-D1).
- **What is sealed.** Every other result broken down by setup, cost included,
  is not computed or shown to the steward until Track 1 is frozen. Calibration
  grading is blind to setup, as in Track 1.
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
- **A0 is analysed here.** In Track 1, A0 is used only to screen tasks and is
  never analysed (COMPASS-DRAFT-eval-snapshot-D7). In this study it is a setup
  like the others, the floor against which the classes the code can answer are
  reported.
- **The workspace.** Every session gets the full workspace of its setup: code,
  documents, `AGENTS.md`, and the Compass tools.
- **Seeded supersession.** Questions use the overlays of the linked Track 1
  tasks, and the further seeded pairs this study adds
  (COMPASS-DRAFT-eval-corpus-qa-D4), built and applied in the same way
  (COMPASS-DRAFT-eval-snapshot-D4). Overlays apply in the setups that have
  documents, not in A0.
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

- **Classing a question.** A question about current guidance that a stale
  document in the baseline contradicts is classed as supersession (real
  history), not current truth, so that the cases statuses as practised make
  hardest are analysed as such. The current-truth example above is one.
- **Linked items.** Each Track 1 trap task has one linked question about the
  knowledge its trap turns on. These count within the 120.
- **Seeded pairs used only by this study.** Track 1 plans 2–3 seeded pairs,
  too few for QA-H2 to be tested. This study adds about 8 more, each with one
  question, so that seeded-supersession questions number about 10–12 in all.
  - They follow Track 1's rules (COMPASS-DRAFT-eval-snapshot-D4): a pair is
    taken from Classic's history where a later version of a document reverses
    an earlier one, and is otherwise written for the study and identified as
    constructed.
  - Results on historical and on constructed pairs are reported separately as
    well as together.
  - The pairs are not used in Track 1, so that its tasks are unchanged.
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
- **Only Track 1's seeded pairs.** These leave QA-H2 with 2–3 items, too few
  to test.
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

**Context:** Free answers are graded only by a judge. A list answer, or a yes
or no, can be scored mechanically if it is given in a field of its own. Which
source an agent relied on shows, on a supersession question, whether it
trusted the stale document or its successor, but sources name paths and
identifiers that reveal the setup to a judge. A final chat message is awkward
to parse reliably. A field asking whether a question's premise is false would
tell the agent that some premises are, and prime it to doubt every question.

**Decision:**
- **The answer file.** The agent writes `answer.json` at the workspace root,
  outside `doc/`. It holds:
  - a short answer;
  - a yes or no, filled only when the question is put as a yes-or-no question;
  - a list of items, for completeness and location questions;
  - the files relied on;
  - a confidence between 0 and 1, used for a descriptive measure of
    calibration (COMPASS-DRAFT-eval-corpus-qa-D9).

  It has no field about the question's premise.
- **One file per turn.** In a batched session (COMPASS-DRAFT-eval-corpus-qa-D8)
  each question is its own turn. The harness collects `answer.json` when the
  turn ends and removes it before the next turn, so that a file left from one
  question is never collected as the answer to the next. The earlier answer
  stays in the session's context; that is carry-over, which
  COMPASS-DRAFT-eval-corpus-qa-D8 and COMPASS-DRAFT-eval-corpus-qa-D9 deal
  with.
- **No other changes to the repository.** The prompt asks the agent not to
  change the repository. Between turns, the harness records and reverts every
  change other than `answer.json`, so that notes or files written for one
  question are not there for the next. The changes are recorded per turn.
- **The schema** is given in each question's prompt, identically in every
  setup.
- **Invalid answers.** A missing or malformed file scores as wrong and is
  counted in its own denominator. It is not rerun. The batch continues with its
  next question.

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
  - Negation answers are scored from the yes-or-no field, and location answers
    from the list of items, against the key.
  - Completeness answers are scored by set overlap (F1), with full credit at
    an F1 of 1 and the F1 itself as a secondary measure.
- **The judge.** Current truth, supersession, rejected-alternative, rationale,
  and false-premise answers are graded by Gemini 4 Argon
  (COMPASS-DRAFT-eval-snapshot-D11). A false-premise answer is correct when
  it rejects the premise or says the decision was never made.
  - It grades against the key, strictly.
  - It sees the question, the key, and the short answer only: no sources and
    no paths.
  - Each answer is judged three times in random order, and the majority stands.
- **Coded errors.** Two kinds of wrong answer are coded:
  - a *supersession error*, where the answer gives the superseded guidance the
    key names;
  - a *confabulation*, where the answer accepts a false premise.
- **Attribution.** The sources an agent cites are its own report. They are
  compared mechanically with the key's sources, to classify which document the
  agent relied on, and with the documents it actually read in that turn
  (COMPASS-DRAFT-eval-snapshot-D13). Answers that cite a document they never
  read are counted and reported.
- **Human calibration.** The steward blind-grades a stratified sample of 20%
  of judged answers. A measure is accepted for the judge at Cohen's κ ≥ 0.6;
  otherwise the steward grades it.

**Alternatives:** A judge for every answer, which spends judgement on what can
be counted. A judge that sees sources, which reveals the setup.

### COMPASS-DRAFT-eval-corpus-qa-D8 — Batches of five questions, asked in turns, two runs, three models

**Status:** Proposed

**Context:** One question per session, with two runs on seven setups and three
models, is about 5,000 sessions. The budget is set in tokens, and this is over
it. Each session spends tokens orienting itself before it answers. Asking
several questions in one session shares that cost, but brings three problems:
- **Carry-over.** Exploring for one question teaches the agent things it uses
  on the next, and a question's wording can give away another's answer. If
  carry-over differs by setup (a typed corpus may make one exploration more
  reusable), it biases the comparison of setups rather than only adding noise.
- **Correlated answers.** Answers in one session share an exploration.
- **Attribution.** If all questions arrive at once, cost and documents read can
  no longer be assigned to a question.

Khatri finds that more items buy more power than more repeats. The models are
those of COMPASS-0006. Track 2's R1 condition needs the harness to continue one
session across turns; this study would build and test that first.

**Decision:**
- **Turns.** A session asks up to five questions, one per turn. The harness
  waits for each answer (COMPASS-DRAFT-eval-corpus-qa-D6) before it continues
  the session with the next question. The first question is therefore asked
  with no knowledge of the later ones. Tokens, tool calls, and documents read
  are recorded per turn.
- **Composition of batches.** Batches are built once, before the freeze, and
  are the same in every setup:
  - their questions come from different subsystems and share no source file
    in their answer keys, which the harness checks from the keys;
  - no question's wording reveals another's answer, which the steward checks
    when reviewing batches;
  - each batch mixes classes and holds at most one false-premise question.
- **Order.** Each batch gets six random orders, one for each combination of
  model and run, drawn so that every question comes first at least once.
  Random orders, unlike cyclic rotations, vary which question follows which,
  so that no pair's carry-over is repeated in every order. A given model and
  run uses the same order in every setup, so comparisons between setups stay
  paired. The orders are drawn before the freeze, from a recorded seed.
- **Questions with overlays run alone.** A seeded-supersession question, from
  Track 1's pairs or this study's, adds documents that could affect the rest
  of a batch. It runs one per session, in the setups that have documents.
- **Between turns,** the harness reverts any change to the repository other
  than the answer file (COMPASS-DRAFT-eval-corpus-qa-D6).
- **Limits.** 15 minutes of wall-clock time per turn, and a token limit per
  session, both fixed at freeze.
- **Runs.** Each batch, and each question that runs alone, runs twice per setup
  and model, for all three models, interleaved in a random order blocked by
  batch. With about 22 batches and 10–12 questions that run alone, that is
  about 1,300 sessions holding about 5,000 answers.
- **The dry run decides the design before the freeze.**
  - Ten questions kept out of the bank are run on A1 and A2 with Claude Opus
    5.5, twice: as two batches of five in turns, and singly. That is about 50
    sessions.
  - It checks the answer format, collection between turns, and the scorer.
  - It measures tokens per answer batched against single (the ratio r), and
    the difference in accuracy between first and later positions.
  - r is measured with one model on two setups. It is taken to hold for the
    others, and is measured again for every model and setup in the
    operational review, pooled across setups.
- **The rule applied to the dry run's results.** Answers in a batch share an
  exploration, so batches of five give about 1/(1 + 4ρ) of their answers'
  worth in independent observations, where ρ is the correlation of answers
  within a session. ρ is taken as 0.2, the value the power simulation assumes,
  unless the dry run estimates it more precisely.
  - Batching is more efficient than single-question sessions only if
    r < 1/(1 + 4ρ), about 0.56 at ρ = 0.2. Because batching also risks bias
    from carry-over, it is used only if r is at most 0.8 of that bound, about
    0.45 at ρ = 0.2.
  - Among the designs within the token budget (batches or single questions;
    one run or two; the ablations on all three models or on Claude Opus 5.5
    and GPT-6 Sol only, as in Track 1), the study uses the one with the most
    effective answers that the first bullet allows.
  - If none is within the budget, the steward reduces the bank or the setups
    before the freeze (COMPASS-DRAFT-eval-corpus-qa-O1).

  The design chosen, with r, ρ, and the projected cost, is recorded before the
  freeze. The dry run is not otherwise analysed.

**Alternatives:**
- **One question per session, as first proposed.** This is the cleanest
  design, but over budget.
- **All five questions in one prompt.** This is cheaper still, but loses the
  clean first answer and the attribution of cost.
- **One unbatched run.** This halves cost and keeps answers independent, but
  gives about half the answer observations. It stays as the fallback if
  batching saves too little.
- **Batches of fewer or more than five.** These were not examined: five keeps
  sessions short enough that compaction is unlikely and context growth is
  small.

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
| QA-H2 | A2 and A3 make fewer supersession errors than A1 on seeded pairs, and A2−S loses the gain | Supersession errors, on Track 1's pairs and this study's together | T1-H7 |
| QA-H3 | A2 answers completeness and negation questions better than A1 | Accuracy (full credit); F1 is secondary | T1-H1 |
| QA-H4 | A2 confabulates less than A1 on false-premise questions | Confabulations | — |
| QA-H5 | Each ablation lowers accuracy on its classes: A2−S on supersession, A2−R on rejected alternatives and rationale, A2−L on completeness and location | Accuracy by class | T1-H9 |
| QA-H6 | A3 answers more accurately than A2 | Accuracy, all classes | T1-H3 |
| QA-H7 | A3 costs less per correct answer than A2 | Tokens per correct answer | T1-H3 |

- **Exploratory and descriptive.**
  - Real-history supersession under statuses as practised is exploratory and
    tested two-sided. It includes the questions about current guidance that a
    stale document contradicts (COMPASS-DRAFT-eval-corpus-qa-D4).
  - QA-H2 is also reported separately for historical and for constructed pairs.
  - Current truth, location, and rationale are reported descriptively against
    A0.
  - Calibration: the Brier score of the agents' stated confidence, by setup
    and model.
- **Model.** For each model separately, a mixed-effects logistic model fitted
  with `lme4`:
  - setup as a fixed effect;
  - a random intercept per question;
  - when the study is batched (COMPASS-DRAFT-eval-corpus-qa-D8), position in
    the batch as a fixed effect and a random intercept per session.

  Pairs of setups are compared with question-clustered bootstrap intervals,
  resampling whole batches together with their questions.
- **Carry-over checks,** pre-registered when the study is batched.
  - *A sensitivity analysis* repeats each confirmatory test on first-position
    answers only, about a fifth of the data, which no earlier question in the
    session can have informed. A confirmatory result is reported as robust
    only if this analysis agrees with it in direction. For each model the
    first-position answers cover only about two of each batch's five
    questions, so this check has little power and is read as a check of
    direction, not as a test in its own right.
  - *The interaction of position and setup* is estimated and reported. It is
    the term that would show carry-over differing between setups, and so
    biasing their comparison.
- **Cost.** QA-H7's cost per correct answer is computed per turn, from the
  tokens recorded for each question. In a batch, A3's catalog is delivered once
  for up to five questions, so its cost per answer depends on the design. QA-H7
  is reported within the design chosen (COMPASS-DRAFT-eval-corpus-qa-D8), and
  is not taken to carry over to Track 1's single-task sessions.
- **Families.** Holm's correction is applied within each family, for each
  model: knowledge (QA-H1 to QA-H4), ablation (QA-H5), and delivery (QA-H6
  and QA-H7).
- **Power.** A power simulation before the freeze gives the smallest
  detectable effect of each confirmatory test. It allows for the correlation of
  answers within a session (a design effect of 1 + 4ρ for batches of five),
  taking ρ from the dry run where it can be estimated and otherwise assuming
  0.2.
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

1. The harness assembles the workspace of the setup. For a question that runs
   alone, it applies the overlay of the linked Track 1 task. It then starts a
   session in an isolated container.
2. The first turn gives the first question of the batch, in the order assigned
   to this model and run, with the schema of `answer.json`, and asks the agent
   to answer from the repository. The prompt is identical in every setup.
3. The agent explores and writes `answer.json`. When the turn ends, the harness
   collects the file, records the turn (COMPASS-DRAFT-eval-snapshot-D13), and
   removes the file from the workspace. It records and reverts any other change
   the agent made to the repository.
4. The harness continues the same session with the next question, and repeats
   step 3 until the batch is done or a limit is reached.
5. The harness scores the mechanical classes. It strips the sources from
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
- **Carry-over in batches.** Despite disjoint batches, turns, and rotated
  orders, what an agent learns on one question may help it on the next, and
  may help more in some setups than others. The first-position analysis and
  the interaction of position and setup (COMPASS-DRAFT-eval-corpus-qa-D9) detect
  it but cannot remove it. If carry-over is strong and differs by setup, the
  confirmatory claims rest on first-position answers alone, and detect only
  larger effects.
- **The steward's time.** Verifying about 120 answer keys, checking about 22
  batches for revealing wording, and grading a 20% sample is substantial
  (COMPASS-DRAFT-eval-corpus-qa-O5).
- **The seal.** It relies on the harness not computing results by setup
  before Track 1 is frozen. The analysis scripts refuse to run before a flag
  that records the date of Track 1's freeze is set. The operational reports
  pool every measure across setups except counts of failed and rerun sessions.
- **Shared instruments.** A fault found here changes Track 1's harness before
  its freeze. It must be recorded in both Logs, and any sessions it affected
  are rerun.

## Open Questions

### COMPASS-DRAFT-eval-corpus-qa-O1 — The token budget, and A4

The budget is set in tokens. COMPASS-DRAFT-eval-corpus-qa-D8 chooses between
batched and single-question designs from the dry run's ratio r and the budget,
so the budget must be stated, as a number of tokens or a sum per model, before
the dry run. What is it? Is A4, which adds a seventh of the cost, included if
the chosen design leaves room?

### COMPASS-DRAFT-eval-corpus-qa-O2 — A documents-only arm

A setup in which the agent sees only the documents would test retrieval as
MOOSEDev did, and make the two studies comparable. It would add about a sixth
to the cost for each setup it covers. Is the comparison worth it, and in which
setups?

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

The steward verifies every answer key (about 120), checks the wording of about
22 batches, and grades a 20% sample of judged answers. Five of the eight
classes go to the judge, so with about 5,000 answers the sample is roughly 600.
Should a second person verify a sample of the keys, which would allow agreement
on the keys to be reported? Should the sample be smaller for classes where the
judge's agreement is high early on? Should the time spent be recorded for
study 10 of COMPASS-0006's research agenda?

## Prior Art

Table: Prior work and what this plan takes from each.

| Work | What to draw from |
|---|---|
| MOOSEDev (Adam, 2026) | The classes of completeness, negation, and supersession; a strict judge; answer keys from primary sources; currency trials with real reversals of decisions |
| Xue (2026) | The stages at which a requirement is lost, and the separation of acquiring a requirement from carrying it out |
| Gloaguen et al. (2026) | The finding that context files helped only when the repository's other documentation was removed, a reason to measure what the code alone answers; A0 gives that floor |
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
   - The further seeded pairs are built, historical where possible, with their
     overlays and questions (COMPASS-DRAFT-eval-corpus-qa-D4).
   - The batches are built: the harness checks their answer keys for shared
     sources, and the steward checks their wording.
   - The random orders are drawn, from a recorded seed, for each combination
     of model and run.
3. **Harness additions,** with tests in `compass-eval/tests`:
   - a question as a kind of task in the snapshot descriptor;
   - sessions continued across turns, with `answer.json` collected, validated,
     and removed after each turn, other changes to the repository reverted,
     and cost recorded per turn;
   - the mechanical scorer;
   - the judge's rubric for answers;
   - the seal on the analysis.
4. **Dry run,** on 10 questions kept out of the bank, with Claude Opus 5.5 on
   A1 and A2.
   - Run twice: as two batches of five in turns, and singly, about 50 sessions
     in all.
   - Check the answer format, the collection between turns, and the scorer.
   - Measure the ratio r of tokens per answer batched to single, the
     difference in accuracy between first and later positions, and, where the
     data allow, the correlation of answers within a session.
   - Before the freeze, with the token budget stated
     (COMPASS-DRAFT-eval-corpus-qa-O1), apply the rule of
     COMPASS-DRAFT-eval-corpus-qa-D8 and record the design chosen, with r, ρ,
     and the projected cost, in the Log.
5. **Freeze.**
   - The power simulation, for the design chosen, and the table of smallest
     detectable effects.
   - The protocol Eval written.
   - The steward's commit and tag.
6. **Runs,** interleaved, after Track 1's stage 5 and before its freeze: for
   the batched design with two runs, about 1,300 sessions holding about 5,000
   answers.
7. **Operational review** (COMPASS-DRAFT-eval-corpus-qa-D2):
   - cost, tokens, and manipulation checks, pooled across setups, with r
     measured again for every model;
   - counts of failed, invalid, and rerun sessions by setup;
   - the judge's validation;
   - the steward's calibration sample;
   - any faults in the shared instruments fixed and recorded as deviations,
     with affected sessions rerun.

   Every other result by setup, cost included, stays sealed.
8. **Unsealing,** after Track 1's freeze.
   - The analysis, appended to the protocol Eval as a dated update.
   - A short dated update to COMPASS-0006.
   - The Log brought up to date.
9. **Linkage analysis,** after Track 1's full study, and the section of the
   Track 1 paper. A decision on COMPASS-DRAFT-eval-corpus-qa-O4.
