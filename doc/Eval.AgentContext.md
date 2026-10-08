---
id:            COMPASS-DRAFT-agent-context-eval
title:         Compass as Agent Context — Evaluating Quality Over Time
genre:         Eval
subtype:       comparison
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
  - COMPASS-DRAFT-toolchain
  - COMPASS-DRAFT-agent-workflow
  - COMPASS-DRAFT-source-headers
  - COMPASS-DRAFT-authoring-assistance
  - COMPASS-DRAFT-secure-development
  - COMPASS-DRAFT-agent-context-prior-art
cites:
  - title:     "Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents? (Gloaguen, Mündler, Müller, Raychev, Vechev; MemAgents @ ICLR 2026)"
    locator:   "arXiv:2602.11988v2, §4 and abstract"
    external:  true
  - title:     "Do Context Files Help Coding Agents? A Two-Agent Ablation Study on Real Repositories (Khatri, 2026)"
    locator:   "arXiv:2607.27250, §3 and failure-mode triage"
    external:  true
  - title:     "Agent READMEs: An Empirical Study of Context Files for Agentic Coding (Chatlatanagulchai et al.)"
    locator:   "arXiv:2511.12884, abstract"
    external:  true
  - title:     "EvoCode-Bench: Evaluating Coding Agents in Multi-Turn Iterative Interactions (2026)"
    locator:   "arXiv:2605.24110, §3 and 'Implications for benchmark designers'"
    external:  true
  - title:     "When and How Context Rot Appears in Coding Agents (Xue, 2026)"
    locator:   "arXiv:2607.17937v2, §2 and RQ4"
    external:  true
  - title:     "ContextEcho: A Benchmark for Persona Drift in Long Agentic-Coding Sessions (2026)"
    locator:   "arXiv:2605.24279v1, §2"
    external:  true
  - title:     "LOCA-bench: Benchmarking Language Agents Under Controllable and Extreme Context Growth (ICML 2026)"
    locator:   "Poster abstract"
    external:  true
  - title:     "Don't Blame the Large Language Model: How Agent Harness Evolution Shapes Coding Agent Quality (Ben Sghaier, Li, Adams, Hassan; 2026)"
    locator:   "arXiv:2607.03691, results across 35 releases"
    external:  true
  - title:     "Handoff Debt: The Rediscovery Cost When Coding Agents Take Over Interrupted Tasks (KC, Budathoki; 2026)"
    locator:   "arXiv:2606.02875v2, abstract and handoff views"
    external:  true
  - title:     "Codified Context: Infrastructure for AI Agents in a Complex Codebase (2026)"
    locator:   "arXiv:2602.20478v1, abstract; 283 development sessions"
    external:  true
  - title:     "Ontology-Grounded Project Memory for Coding Agents (Adam; NeSy 2026)"
    locator:   "arXiv:2608.13662, abstract"
    external:  true
  - title:     "The Specification Gap: Coordination Failure Under Partial Knowledge in Code Agents (2026)"
    locator:   "arXiv:2603.24284v1, §3–§4 (specification levels L0–L3)"
    external:  true
  - title:     "Grounding AI Agents in Contracts: An Empirical Evaluation of Spec-Driven Test Generation (Tufano et al.; SpecOps '26)"
    locator:   "arXiv:2608.17177v2, abstract and §5"
    external:  true
  - title:     "Evaluating Large Language Models for Detecting Architectural Decision Violations (2026)"
    locator:   "arXiv:2602.07609v1, abstract"
    external:  true
  - title:     "Which test is the best for equivalence? Two one-sided tests (Schuirmann, 1987)"
    locator:   "J. Pharmacokinetics and Biopharmaceutics 15(6)"
    external:  true
open-questions:
  - COMPASS-DRAFT-agent-context-eval-O1
  - COMPASS-DRAFT-agent-context-eval-O2
  - COMPASS-DRAFT-agent-context-eval-O3
  - COMPASS-DRAFT-agent-context-eval-O4
  - COMPASS-DRAFT-agent-context-eval-O5
  - COMPASS-DRAFT-agent-context-eval-O6
---

# Compass as Agent Context: Evaluation Protocol

This evaluation asks whether a maintained, typed Compass corpus lets coding
agents produce consistently good work on a real codebase over time, across many
short sessions rather than one long one. It compares Compass's form and delivery
against untyped documentation, agent-maintained notes, no documentation, and a
single ever-growing session. It informs open question
COMPASS-DRAFT-agent-workflow-O1, carried forward from
COMPASS-DRAFT-operator-memory-O6, and it gates roadmap step 6 of
[COMPASS-DRAFT-toolchain](Plan.Toolchain.md): the session catalog, source map,
and authority weight are not built until the pilot reported here has run. The
designs under test are specified in
[COMPASS-DRAFT-toolchain](Plan.Toolchain.md) (COMPASS-DRAFT-toolchain-D10 to
COMPASS-DRAFT-toolchain-D15), [COMPASS-DRAFT-source-headers](Spec.SourceHeaders.md),
and [COMPASS-DRAFT-agent-workflow](Plan.AgentWorkflow.md). This document is
currently a **protocol**: it fixes the method before any run. Results will be
appended as `## Update <date> — <title>` sections, and the Synthesis written once
they exist.

## Method

### Thesis: sessions as an annual crop

Long agent sessions decay. As context accumulates, an agent drops requirements,
applies obsolete rules, and becomes slower and more expensive, until the session
is better replaced than continued. The working model behind Compass treats a
session like an annual crop: it is grown, harvested, and replaced when its yield
falls. What must survive the replacement is the project's *ethos*, meaning its
invariants, its decisions and the alternatives it rejected, its terminology, and
its design style. The thesis under test is that a corpus which is **typed** (so
an agent can tell current truth from history), **delivered** at session start,
and **maintained** as the code changes carries that ethos across session
replacements, so that the quality of output holds steady over time at a stable
cost.

### What the published studies do and do not show

Three 2026 studies found that repository context files (`AGENTS.md`,
`CLAUDE.md`) do not measurably improve task success:

- Gloaguen et al. found no improvement across several agents on SWE-bench Lite
  and on repositories with developer-written context files, and a cost increase
  of over 20%. Agents followed the files' instructions closely, but
  "repository overviews … are not helpful."
- Khatri bounded any correctness effect of three injection strategies to at most
  10–15 percentage points, and traced failures to implementation skill rather
  than missing repository knowledge.
- Chatlatanagulchai et al. found that context files grow by frequent small
  additions, like configuration code.

These are **snapshot** studies. Each runs a fresh session on one issue against a
fixed context file, mostly in popular public repositories whose knowledge sits
largely in the code, and scores one patch by hidden tests. None measures work
over time, maintenance of the context, decay within a session, or conformance to
a project's design intent. Their findings constrain this evaluation in three
ways: instructions are followed, so carrying an ethos forward has a working
mechanism; overviews did not help, so the catalog and source map must be shown
to help or be dropped; and the evaluation must count the cost of injected
context.

Work on multi-turn and long-context agents comes closer to the thesis.
EvoCode-Bench keeps one workspace and one session across 5–15 rounds of changing
requirements and concludes that "longer context helps only if the model can
identify active requirements, superseded requirements, and earlier
implementation choices that have become liabilities." Xue finds that context rot
in coding agents usually appears as a silently dropped requirement or "applying
an obsolete rule" inside otherwise plausible output. ContextEcho and LOCA-bench
measure drift and degradation as context grows. Together they support the
premise that sessions decay.

Three 2026 studies come closer still to the remedy. *Handoff Debt* (KC and
Budathoki) interrupts a coding agent partway through a task and hands it to a
successor, which receives the repository only, the predecessor's raw trace,
summary notes, or structured notes. Context-bearing handoffs cut the successor's
agent events by 20–59% and prompt tokens by 42–63%; effects on task success were
smaller and model-dependent. *Codified Context* reports a project knowledge base
of conventions, architectural decisions, and known failure modes used across 283
development sessions, observationally rather than as a controlled comparison.
*MOOSEDev* (Adam) gives agents an ontology-grounded store of decisions with
status and supersession, and shows that structured queries recover supersession
and completeness answers almost fully where vector retrieval recovers 6–27%; it
evaluates retrieval, not development outcomes. So the separate parts of the
remedy have been studied: one handoff at a time, observationally, or as
retrieval. What none of them measures, as far as the literature examined
(see [COMPASS-DRAFT-agent-context-prior-art](Eval.PriorArt.AgentContext.md))
shows, is whether output quality and conformance to design intent hold across a
long sequence of real development steps when each step is taken by a fresh
session carrying a maintained, typed corpus. That is the gap this evaluation
addresses. The search behind this claim has not been exhaustive.

One consequence for the standard: [COMPASS-0001](../Compass.md) §23 says that "no
rigorous account of 'documentation as LLM context' has yet been published." That
claim is now out of date and should be corrected by patch, citing the studies
above.

### Design overview

The evaluation has two tracks.

- **Track 2, the relay (primary).** A sequence of real development steps taken
  from a repository's Git history, worked through under four conditions that
  differ in how sessions are managed and what context carries between them.
  This tests the thesis directly.
- **Track 1, snapshot tasks (secondary).** Single-session tasks at one commit,
  under four documentation setups that differ only in form and delivery. This
  checks whether the published null results hold for typed documents, and
  isolates the contribution of each delivery mechanism. Three ablation setups
  each remove one feature of the scheme, and two task categories put the
  scheme's handling of superseded guidance and rejected alternatives under
  deliberate pressure.

The tracks share the repository, the models, the harness, the rubric, and the
grading procedure.

### Hypotheses

All hypotheses, measures, thresholds, and decision rules in this document are
fixed when the protocol is frozen (see [Execution plan](#execution-plan)) and are
not changed after any run.

Table: Track 2 (relay) hypotheses.

| # | Hypothesis | Primary measure |
|---|---|---|
| T2-H1 | Quality holds over the relay under R4 but declines under R1 (the crop thesis) | Slope of step correctness and ethos conformance across steps (G1, G3, G4) |
| T2-H2 | R4 conforms to the project's ethos better than R2 | G3–G6 |
| T2-H3 | Typing adds value beyond memory: R4 beats R3 on supersession errors and decision conformance | G7, G4 |
| T2-H4 | In later steps, R4 costs less per step than R1 | G8 |
| T2-H5 | The R4 corpus stays accurate as the code changes, and the maintenance protocol is followed | G9, G10 |

Table: Track 1 (snapshot) hypotheses.

| # | Hypothesis | Primary measure |
|---|---|---|
| T1-H1 | On knowledge-trap tasks, Compass setups (A2–A4) beat untyped documentation (A1) | G1, G3 on trap tasks |
| T1-H2 | Authority typing reduces reliance on superseded content (A2 vs A1) | G7 |
| T1-H3 | Session-start delivery of the catalog helps beyond having the corpus on disk (A3 vs A2), net of its cost | G1, G3, G8 |
| T1-H4 | Source headers and the map help beyond the catalog (A4 vs A3) | G1, G8 |
| T1-H5 | No harm on ordinary tasks: A2–A4 are equivalent to A1 on control tasks | G1 (equivalence test), G8 |
| T1-H6 | Typed context helps agents keep security invariants: A2–A4 trigger fewer security traps than A1 | G3 on security-invariant tasks |
| T1-H7 | Status typing protects against seeded supersession: A2–A4 rely less than A1 on a superseded document that contradicts its successor, and removing status and supersession (A2−S) loses the gain | G7 on seeded-supersession tasks |
| T1-H8 | Recorded rejected alternatives reduce design churn: A2 re-proposes a rejected design less often than A1 and than A2 with Alternatives sections removed (A2−R) | G11 on rejected-alternative tasks |
| T1-H9 | Each tested feature of the scheme contributes: removing status and supersession (A2−S), rejected alternatives (A2−R), or identifiers and typed links (A2−L) from A2 lowers trap-task performance | G1, G3, G7, G11 on trap tasks |

### Decision rules

Each rule maps an outcome to a change in a named decision. Thresholds are fixed
at protocol freeze; the values shown are the proposed defaults.

Table: Pre-registered decision rules and the decisions they act on.

| If… | Then… | Acts on |
|---|---|---|
| R4 shows no flatter quality slope than R1, and no ethos gain over R2 | Reopen the thesis; Compass's agent-context work (Toolchain step 6, the session adapter) is deferred indefinitely | COMPASS-DRAFT-toolchain-D10, COMPASS-DRAFT-agent-workflow-D10 |
| R4 does not beat R3 on supersession errors or decision conformance | Authority typing is not earning its cost for agents; simplify the weight function to an Excluded filter only | COMPASS-DRAFT-toolchain-D12 |
| A3 does not beat A2 on trap tasks, or adds more than 20% cost | Replace session-start injection with on-demand retrieval (`compass show`, `outline`) | COMPASS-DRAFT-toolchain-D10, COMPASS-DRAFT-toolchain-D11, COMPASS-DRAFT-agent-workflow-D10 |
| A4 does not beat A3 | Keep the source map for human navigation; remove its top level from the catalog | COMPASS-DRAFT-toolchain-D11, COMPASS-DRAFT-toolchain-D14 |
| A2–A4 are not equivalent to A1 on control tasks within ±10 points | Treat the corpus as harmful to ordinary work; reduce what the catalog carries | COMPASS-DRAFT-toolchain-D11 |
| R4 corpus accuracy falls below 80%, or agents set authoritative statuses | Revise `compass-maintain` and the protocol before any adoption | COMPASS-DRAFT-agent-workflow-D9 |
| A2−S is not worse than A2 on seeded-supersession tasks | Status typing does not help agents directly; as for R4 vs R3, simplify the weight function to an Excluded filter | COMPASS-DRAFT-toolchain-D12 |
| A2−R is not worse than A2 on rejected-alternative tasks | Recorded Alternatives do not reach agents; keep them for human review, but stop including them in agent-facing views and reconsider the maintenance skill's emphasis on them | COMPASS-0001 §8 record shape; COMPASS-DRAFT-agent-workflow-D9 |
| A2−L is not worse than A2 | Agents do not use identifiers and typed links directly; identity is unchanged, since the toolchain depends on it, but the catalog may drop identifier-heavy fields | COMPASS-DRAFT-toolchain-D11 |

### Models

Table: Models under test, chosen at matched intended tier across three labs.

| Model | OpenCode ID | Released | Tier within its lab |
|---|---|---|---|
| Claude Opus 5.5 | `opencode/claude-opus-5-5` | 2026-09-22 | Second tier, below Claude Fable 5.1 |
| GPT-6 Sol | `opencode/gpt-6-sol` | 2026-09-22 | Second tier, below GPT-6 Astra |
| GLM-5.3 | `opencode/glm-5.3` | 2026-08-14 | Zhipu's top tier; open weights |

Opus 5.5 and GPT-6 Sol occupy the same intended tier in their labs' lineups and
were released on the same day. GLM-5.3 is its lab's flagship but benchmarks
below the other two; this is stated as a limitation and used as a feature: it
lets the evaluation ask whether typed context helps a weaker model more. Each
model runs at a fixed reasoning effort recorded at protocol freeze, using the
same nominal level (high) wherever the provider offers one.

### Harness

Sessions run headlessly through OpenCode:

```text
opencode run --format json --pure --auto \
  --model <model-id> --dir <worktree> --title <run-id> "<task statement>"
opencode export <session-id> > runs/<run-id>/session.json
```

- `--pure` excludes external plugins, so only the context the condition supplies
  is present. `--auto` approves tool permissions; every run therefore executes in
  a disposable container with no network access beyond the model API and no
  credentials.
- Each session starts from a fresh Git worktree prepared by the harness.
- Until the session adapter (COMPASS-DRAFT-agent-workflow-D10) exists, the
  catalog is delivered through the worktree's `AGENTS.md`, which OpenCode loads
  at session start. The adapter, once built, is evaluated as a separate setup.
- Every run records the OpenCode version, model ID, reasoning effort, start and
  end time, token counts (input, cached input, output, and the tokens of injected
  context separately), tool calls, compaction events, and the final diff. The
  OpenCode version is pinned for the whole study, since harness changes alone
  shift agent quality (Ben Sghaier et al.).
- The catalog, source map, and source headers used in A3, A4, and R4 are produced
  by hand, or with the toolchain's v0.1 baseline where it suffices, following the
  formats of COMPASS-DRAFT-toolchain-D11 and D14. The evaluation thereby tests
  the delivery design before it is built.

### Grading

- **Automatic checks** grade correctness, regressions, and invariant traps
  (G1–G3) by running tests in a clean container.
- **Judged measures** (G4–G7, G9) are graded by an LLM judge working from a
  rubric and an answer key, with the condition label, the injected context, and
  any corpus changes removed from what it sees. Code diffs and corpus diffs are
  graded separately, so a corpus edit cannot reveal the condition to the code
  grader.
- **Human calibration.** Andrew Sengul blind-grades a stratified random sample of at
  least 10% of judged items. The judge is accepted only if its agreement with the
  human grades reaches Cohen's κ ≥ 0.6 per measure; otherwise that measure is
  graded by hand or dropped. Agreement is reported.

### Statistics

- **Five runs** per cell (task or relay × setup or condition × model).
- Comparisons are paired by task (Track 1) and by step (Track 2), with
  bootstrap confidence intervals over runs. Small cells use Fisher's exact test.
- **Quality over time** (T2-H1) is estimated as a per-condition slope of each
  measure across relay steps, using a mixed-effects logistic model with step,
  condition, their interaction, and model as fixed effects and run as a random
  effect. The hypothesis is about the condition × step interaction.
- **No-harm claims** (T1-H5) use two one-sided tests (TOST; Schuirmann) with an
  equivalence margin of ±10 percentage points, so that a null result can be read
  as evidence of no effect rather than absence of evidence.
- Effects are reported separately per model before any pooling.

### Execution plan

1. **Freeze the protocol.** Fix every threshold and margin above, record the
   protocol at a commit, and refer to that commit from every result.
2. **Prepare the snapshot.** Verify that each relay step's historical tests pass
   at its commit and fail at its parent; build the seed corpora (see
   [Seed corpora](#seed-corpora)); write the task statements.
3. **Contamination probe.** Ask each model, with no repository access, to
   describe Classic's API, and score recall of specific symbols. Report the
   result alongside every finding.
4. **Pilot** (gates Toolchain roadmap step 6):
   - Track 2: relay steps 1–5, conditions R1, R2, and R4, Claude Opus 5.5 only,
     anchored mode, 5 runs: 15 relays, 75 step sessions.
   - Track 1: 8 trap tasks, including at least 2 security-invariant, 1
     seeded-supersession, and 1 rejected-alternative task; setups A1 and A3,
     Claude Opus 5.5 only, 5 runs: 80 sessions.
   - Purpose: check the harness, the graders, and judge calibration; estimate
     tokens and cost per step; obtain first effect estimates.
5. **Full study, anchored mode.** All relay steps, R1–R4, all three models;
   Track 1 with all tasks, A1–A4, all three models; the ablation setups
   A2−S, A2−R, and A2−L on the trap tasks with Claude Opus 5.5 and GPT-6 Sol.
6. **Full study, free-running mode** (Track 2 only), after the anchored results.
7. **Python phase**, when a suitable Python project exists (see
   COMPASS-DRAFT-agent-context-eval-O5).

Table: Indicative run counts for the full study, before any reduction after the
pilot.

| Part | Cells | Runs per cell | Sessions |
|---|---|---|---|
| Track 2, anchored | 4 conditions × 3 models | 5 relays of 19 steps | 1,140 step sessions (R1: 15 long sessions) |
| Track 2, free-running | 4 conditions × 3 models | 5 relays of 19 steps | up to 1,140 |
| Track 1 | about 18 tasks × 4 setups × 3 models | 5 | 1,080 |
| Track 1 ablations | about 12 trap tasks × 3 ablation setups × 2 models | 5 | 360 |

## The Shared Scenario

### The repository: Classic

The scenario is a snapshot of **Classic**, the Common Lisp syndication and
publishing framework of the `CLASSIC` namespace. It was chosen over Origin
because a content-management system's domain is widely understood, so the
evaluation measures the use of project knowledge rather than of an unusual
domain, and because its history has finer-grained commits.

Facts about the snapshot, as surveyed for this protocol:

- 65 commits, 2026-05-15 to 2026-09-15; 67 Lisp files, about 15,400 lines; 18
  test files using FiveAM and hamcrest, run through `classic/tests`
  (`CLASSIC:classic.asd@6e4f02d`).
- Its development documents were written *during* development, alongside the
  code: a federation reference, development logs for each feature, schema and
  model references, and later surveys. There are 31 of them at the final commit.
  They were renamed to Compass genre prefixes in `1cabbcf`, but most still lack
  front-matter.
- The last commit that changes code is `bad2094`; later commits add documents
  only.

**Scope decision: core repository only.** Classic is implemented alongside
`classic.composer` and `lexis`, which provide document composition. The survey
found that no commit of Classic's build or test suite depends on either: all
subsystems the tests load (`classic.schema.alpha`, `classic.engine.ref`,
`classic.models.common`, `classic.dist.alpha`) live in Classic's own `mod/`
directory, Lexis appears only in docstrings, and the dependency runs one way
(`classic.composer` depends on `classic`). Every relay step can therefore run
on Classic alone, and the multi-repository snapshot is unnecessary. The cost is
that the cross-repository knowledge-trap category has no material in this
snapshot; see COMPASS-DRAFT-agent-context-eval-O6.

### Track 2: the relay sequence

The relay starts at `58452c7` (federation support and schema migration), the
first commit with substantial code, tests, and a design document. Each **build
step** asks for the work of one historical feature or fix; each **maintenance
step** covers a multi-commit refactor, which the harness applies to the code
itself, and asks the agent only to bring the corpus up to date with it.

Table: Relay steps, with the historical commits each reproduces and the
documents Classic's developers wrote for them.

| Step | Kind | Commits | Work | Historical documents (answer key) |
|---|---|---|---|---|
| 1 | build | `137cf8a` | Entity deletion; query-relation improvement | `DevLog.DeletionSupport` |
| 2 | build | `8d5cc1b` | Federation consistency, phase A | `DevLog.FederationConsistency` |
| 3 | build | `fb49791` | Federation consistency, phase B | (same, updated) |
| 4 | build | `99d050d` | Federation consistency, phase C | (same, updated) |
| 5 | build | `9a18222` | Fix stale relation indices and URI collisions | — |
| 6 | build | `9ee593a` | Slot validation for model classes | `DevLog.SlotValidation` |
| 7 | build | `31ee385` | `with-persistence` macro | `DevLog.WithPersistence` |
| 8 | build | `0e4c5bb` | Bulk-rename helper for the migration DSL | `DevLog.SchemaMigration` (updated) |
| 9 | build | `d20ec8c` | Theme model | `DevLog.ThemeOntology`, `Theme` |
| 10 | build | `8aea5f4` | Lens system for themes | `Theme` (updated) |
| 11 | build | `88a920b`, `88af7f2` | `create-class` operation for the migration DSL, with its bug fix | `Migration` (updated) |
| M1 | maintain | `e9f2af1`–`e0c3b72` | Schema refactor | `DevLog.SchemaFactorization`, `Schema`, `SchemaContract` |
| M2 | maintain | `c8c755e`–`2d99cf8` | Modularising refactor | `DevLog.DistFactorization` |
| 12 | build | `9626df5` | Theme capability exclusion | `DevLog.CapabilityExclusion` |
| 13 | build | `72b638c` | `:slot-types` and slot fills | `DevLog.SlotFills` |
| M3 | maintain | `dbde70e`–`5c4c9a8` | Model refactor | `DevLog.GeneralModel` |
| 14 | build | `c1df12c` | Forum demonstration | `DevLog.ForumDemo`, `Forum` |
| 15 | build | `ea32b9c` | Wiki demonstration | `DevLog.WikiDemo`, `Wiki` |
| 16 | build | `6e6a6a2` | Typed pages for the wiki | `DevLog.TypedPages` |

For each build step:

- **Starting code** is the parent of the step's first commit (anchored mode), or
  the previous step's result (free-running mode).
- **The task statement** is written as a developer's issue describing the
  step's intent. It names the public interface the hidden tests call (function
  and macro names, argument lists) but not the implementation. Statements are
  drafted by an LLM that sees only the commit's diff and tests, never the
  documents, and reviewed by Andrew Sengul for leaks of document content.
- **Hidden checks** are the tests the commit added or changed, withheld from the
  worktree; the full test suite of the parent commit, as a regression check; and
  the step's invariant checks, where it has them.
- **Answer key** for corpus accuracy: the facts recorded in the historical
  documents written for that step, extracted into a checklist.

For a maintenance step, the harness advances the code to the end of the refactor,
and the task is to update the context the condition carries (the corpus in R4,
the notes in R3) to match. R1 is told the code has changed; R2 has nothing to
update. Graded by G9 against the refactor's historical documents.

### Track 2: conditions

Table: Relay conditions.

| Condition | Sessions | Context carried between steps |
|---|---|---|
| R1 | One long session for the whole relay, compacted by OpenCode as it grows | The session's own history only |
| R2 | A fresh session per step | Nothing: each session starts from the code alone |
| R3 | A fresh session per step | Untyped notes, maintained by the agents under an Operator-style instruction ("consult before you build; update after you build"), seeded with Classic's historical documents in their original form; comparable to Handoff Debt's "summary notes" view, but accumulated across steps |
| R4 | A fresh session per step | The full Compass stack: a typed corpus, source headers, the session catalog and source map delivered at start, and the maintenance protocol with `compass-maintain`, seeded with the same documents migrated to Compass form |

In anchored mode, R1's code is reset to the historical state before each step,
and the session is told that the repository has been updated to the team's
current version. In R3 and R4 the notes or corpus carry over from the agents'
own previous step, not from history: what persists is what the agents
maintained. Between steps in R4, the harness regenerates the catalog and map as
the toolchain would (by hand or with v0.1 where it suffices), and records
whether the agent's proposals would pass `compass check`.

The conditions can be read against *Handoff Debt*'s four handoff views, which
are the nearest published reference point. R2 corresponds to its
"repository only" view and R3 to its "summary notes" view; R4 extends its
"structured notes" view from a fixed per-handoff contract to a typed corpus
maintained across many handoffs. Its "raw trace" view has no counterpart here,
since carrying the whole previous transcript is what the thesis proposes to
avoid; R1 is the limiting case of keeping the trace in a single session. Unlike
Handoff Debt, which hands over an interrupted task, each relay step here is a new
task, so the measure of interest is retained design intent rather than the cost
of resuming. Its efficiency measures (agent events and prompt tokens) are
nevertheless reported in G8 in comparable form.

### Track 1: snapshot tasks

Track 1 uses Classic at `bad2094`, the last commit that changes code, with the
corpus as it stands there.

Table: Track 1 task categories.

| Category | What the task tempts the agent to get wrong | Hidden check |
|---|---|---|
| Invariant | Breaking a rule the code relies on but does not state, such as a federation consistency guarantee | Negative tests |
| Supersession | Following an older document or design that a later decision replaced, such as a pre-refactor schema layout | Tests plus transcript check for reliance on superseded content |
| Seeded supersession | Following a superseded document placed in the corpus that directly contradicts its current successor (see below) | Tests that pass only under the current guidance; transcript check for which document was relied on |
| Rejected-alternative temptation | Implementing, or proposing, the design a recorded decision rejected, where that design is the most natural solution to the task as stated | Judge, blind, against the decision record; a test where the rejected design is observable in behaviour |
| System property | Ignoring a cross-file property, such as how deletion propagates to containers and peers | Targeted tests |
| Navigation | Finding the right place to change in a 67-file tree | Correct files changed; exploration cost |
| Security invariant | Weakening or bypassing an existing security check while adding a feature (see below) | Negative tests that attempt the bypass; diff check that the guard is still on the path |
| Control | Ordinary features and fixes where documentation should not matter | Tests |

Proposed mix: about 8 trap tasks (at least 2 of them seeded-supersession and 2
rejected-alternative tasks) and about 4 security-invariant tasks, at least
half of each written by Andrew Sengul, and about 6
control tasks written by an LLM that sees only the code. Each task consists of a
statement written as an issue; its category; where the needed knowledge lives
and whether it can be recovered from the code; hidden checks; and a reference
solution, verified to pass while a trap-violating solution and the untouched
snapshot fail. Task authors follow one rule above all: write the task from
development experience ("what would a capable new collaborator get wrong
here?") before re-reading how the corpus words it.

**Security-invariant tasks** test whether an agent preserves the security checks
Classic already has while extending the system near them. They were added at the
recommendation of [COMPASS-DRAFT-secure-development](Survey.SecureDevelopment.md).
Classic's security model is immature (its own analysis, `securityPoints.md`,
mostly lists what is missing), so these tasks test preservation rather than
construction. Illustrative candidates, to be confirmed against the code at
`bad2094`:
- a new content operation that must change state through `attempt-transition`,
  with its role check, rather than setting the state directly;
- a new account-facing operation that must call `account-has-permission-p`
  rather than assume the caller is permitted;
- an extension of federation receipt that must keep `receive-from-peer`'s
  requirement that the source be a registered peer;
- a convenience constructor for URIs that must keep the type validation of
  `make-classic-uri` and `parse-classic-uri`.

Each has a negative test that attempts the bypass, alongside the functional
tests. Where the guarding rule is documented only in `securityPoints.md` or a
development log, the task also measures whether the corpus delivered it. If
Classic's security analysis is migrated to Compass form before the protocol is
frozen (COMPASS-DRAFT-secure-development-O6), A1 carries the original and
A2–A4 the migrated form, as for every other document.

**Seeded-supersession tasks** test the claim that typing keeps history from
being treated as current truth, under deliberate pressure. Each places in the
corpus a pair of documents: an earlier one whose guidance the task would follow
naturally, and its successor, which reverses that guidance. Wherever Classic's
history contains a real superseded document (for example, schema documentation
written before the schema refactor of `e9f2af1`–`e0c3b72`), that document is
used; a document is constructed only where history offers none, and is written
as a plausible earlier version in the corpus's own voice. The pair is present in
every setup, with the same facts. In A1 both are ordinary untyped documents,
each carrying its date; in A2–A4 the earlier one has status `Superseded` and a
`superseded-by` link, and its decision records are marked accordingly; in A2−S
those markers are removed. This is the one place where Track 1's corpus departs
from the form-only rule of [Seed corpora](#seed-corpora): a constructed
document adds content, so it is identified as such in the protocol and its
results are reported separately from those using real history.

**Rejected-alternative tasks** test whether recorded alternatives prevent
design churn: an agent re-proposing, or implementing, a design the project
already considered and rejected. Each task is chosen so that the rejected
design is the most natural answer to the task as stated, and the decision
record's Alternatives section explains why it was rejected. Candidates come from
Classic's development logs, which record several considered-and-rejected
designs. The measure is G11, design churn.

Table: Track 1 setups.

| Setup | What the agent gets | What it isolates |
|---|---|---|
| A1 | The corpus's facts as untyped Markdown in `doc/`, history mixed in: Classic's documents in their pre-Compass form | Content without typing |
| A2 | The same facts as a Compass corpus in `doc/`, plus the Compass AGENTS snippet; nothing injected | Typing |
| A3 | A2 plus the session catalog delivered at start | Delivery |
| A4 | A3 plus source headers and the source map | Source map |

All four setups carry **the same facts**; only form and delivery change, so a
difference between setups is attributable to form and delivery, not content.
There is no code-only setup in Track 1; R2 supplies the code-only baseline in
Track 2. An Operator Memory setup is deferred.

**Ablation setups.** To learn *which* properties of the scheme matter, three
further setups each remove one feature from A2. A2 is used rather than A3 or A4
so that the result concerns the form of the corpus, not its delivery.

Table: Track 1 ablation setups.

| Setup | A2 with this removed | Tests |
|---|---|---|
| A2−S | Status and supersession: `status`, `supersedes`, and `superseded-by` fields, and the `**Status:**` lines of records | T1-H7, T1-H9 |
| A2−R | Rejected alternatives: the `**Alternatives:**` part of every decision record | T1-H8, T1-H9 |
| A2−L | Identity and typed links: `id` fields, record identifiers (headings keep their titles), `relates-to`, and identifier-keyed links, which become plain file-name links | T1-H9 |

Each ablation removes information that the corresponding Compass feature
carries, so a difference from A2 measures the effect of having that
information in typed form; it does not separate typing from content. The
ablations run on trap tasks only, since control tasks are not expected to
depend on any of these features.

### Seed corpora

Both R4 and Track 1's A2–A4 need Classic's documents in Compass form, as they
stood at a given commit. Migration reshapes form only: front-matter, genre and
status, decision records with full identifiers and statuses, commit-pinned code
references, source headers. It MUST NOT add facts that the historical document
did not contain at that commit, since knowledge of later development would leak
into earlier steps. The R3 and A1 seeds are the historical documents unchanged.
Each migrated document is checked against its original by a reviewer for added
content before the protocol is frozen.

## The Rubric

Table: Measures, how each is graded, and which hypotheses use it.

| # | Measure | Graded by | Used by |
|---|---|---|---|
| G1 | Step or task correctness: hidden tests pass | Tests | T2-H1, T1-H1, T1-H3–H5 |
| G2 | No regression: the parent commit's suite still passes | Tests | All |
| G3 | Invariant conformance: invariant traps, including security-invariant traps, not triggered | Negative tests | T2-H1, T2-H2, T1-H1, T1-H6 |
| G4 | Decision conformance: accepted decisions respected, rejected alternatives avoided | Judge, blind, against the decision records | T2-H1–H3 |
| G5 | Terminology: the project's terms used, not invented synonyms | Judge against the glossary and documents | T2-H2 |
| G6 | Design consistency with the codebase's conventions | Judge, blind | T2-H2 |
| G7 | Supersession errors: acting on superseded or historical content | Transcript and diff, judged | T2-H3, T1-H2, T1-H7, T1-H9 |
| G8 | Cost: steps, tool calls, input, cached and output tokens, wall time; injected tokens counted separately | Harness | T2-H4, T1-H3–H5 |
| G9 | Corpus accuracy: the maintained corpus or notes capture the step's answer-key facts and contain no false claims | Judge against the answer key; `compass check` for R4 | T2-H5 |
| G10 | Protocol compliance (R4): no authoritative status or `approved-by` set; new memos `Draft`; proposals included in the same change | Diff inspection, automatic | T2-H5 |
| G11 | Design churn: implementing, or proposing in the transcript, a design that a recorded decision rejected | Judge, blind, against the decision records; tests where observable | T1-H8, T1-H9 |

**Ethos conformance** is the composite of G3–G6. Each component is reported
separately as well as combined.

## Track 2 Conditions

The conditions, their hypotheses, and their expected outcomes under the thesis.

- **R1 — one long session.** The crop is never replaced. Expected: good early
  steps, declining G1, G3, and G4 as context grows and is compacted, and rising
  cost per step. R1 is the condition the thesis must beat on slope (T2-H1) and
  later-step cost (T2-H4).
- **R2 — fresh sessions, code only.** The crop is replaced but nothing carries
  over. Expected: flat but lower ethos conformance, and higher exploration cost
  every step. R2 is the baseline for what the corpus adds (T2-H2).
- **R3 — fresh sessions, untyped notes.** Memory without typing, in the manner of
  Operator Memory. Expected: better than R2, but vulnerable to acting on
  outdated notes as they accumulate, especially after the maintenance steps.
  R3 is the baseline for what typing adds (T2-H3).
- **R4 — fresh sessions, the Compass stack.** Expected under the thesis: flat
  quality across the relay, ethos conformance above R2 and R3, fewer
  supersession errors than R3, later-step cost below R1, and a corpus that stays
  accurate (T2-H1–H5).

## Track 1 Setups

- **A1 — untyped documentation.** The control for form. Expected to match the
  published studies: little effect on control tasks.
- **A2 — Compass corpus on disk.** Tests typing without delivery (T1-H1, T1-H2).
- **A3 — plus the session catalog.** Tests delivery, net of its token cost
  (T1-H3). The published finding that overviews do not help predicts no gain on
  control tasks; the thesis predicts a gain on trap tasks only.
- **A4 — plus source headers and the map.** Tests navigation support (T1-H4),
  the component closest to what the published studies found unhelpful.
- **A2−S, A2−R, A2−L — single-feature ablations.** Test which properties of the
  scheme carry its effect (T1-H7 to T1-H9). The closest published design varies
  only how complete a specification is (*The Specification Gap*, 2026); no study
  found ablates the features of a documentation scheme.

## Threats to Validity

- **Authorship bias.** The same person designed Compass, wrote much of Classic's
  corpus, and writes some of the tasks. Mitigations: pre-registration; control
  tasks written without access to the documents; relay tasks derived from
  history, with statements drafted by an LLM that sees only diffs; blind
  grading; reporting every result, including null ones.
- **Training-data exposure.** Classic has been public on GitHub since May 2026,
  and the models' training data may include it. The contamination probe
  measures this; results are reported per model alongside it.
- **Hindsight leakage in seed corpora.** Controlled by the form-only migration
  rule and a reviewer check (see [Seed corpora](#seed-corpora)).
- **Interface leakage in task statements.** Naming the interface the tests call
  reveals some design. Too little leads to false failures; too much hands over
  the design. See COMPASS-DRAFT-agent-context-eval-O1.
- **Unmatched models.** GLM-5.3 benchmarks below the other two; effects are
  reported per model.
- **Model and harness drift.** Models are pinned by ID and the OpenCode version
  for the study, but hosted models can change behind a stable ID. Runs for one
  comparison are interleaved in time rather than run condition by condition.
- **Hand-built delivery artefacts.** The catalog and map in A3, A4, and R4 are
  produced by hand or by a partial toolchain. Their quality is a confound for the
  design they stand in for; their generation procedure is recorded.
- **One language, one repository, one developer's style.** Results may not
  generalise. The Python phase and later repositories address this.
- **Constructed superseded documents.** A document written for the study may be
  easier, or harder, to recognise as outdated than a real one. Real superseded
  documents are preferred, and results from constructed ones are reported
  separately.
- **Anchored mode is artificial.** Resetting the code to history each step is
  not how development proceeds; it isolates the corpus's contribution at the cost
  of realism. Free-running mode follows to restore realism.

## Synthesis

*To be written once the pilot and the full study have run.* It will state, per
hypothesis, the estimated effect with its confidence interval per model; which
decision rules fired and the resulting changes to the named decisions; and a
resolution for COMPASS-DRAFT-agent-workflow-O1.

## Open Questions

### COMPASS-DRAFT-agent-context-eval-O1 — How much interface a task statement reveals

Hidden tests call specific names. A statement that names none produces false
failures from reasonable alternative designs; one that specifies everything
hands the design to the agent and erases the difference the corpus might make.
The proposal is to name the public entry points the tests call and nothing
else. Should a pilot compare two levels of disclosure on a few steps?

### COMPASS-DRAFT-agent-context-eval-O2 — Divergence in free-running mode

In free-running mode the agents' code drifts from history, and later historical
tests may stop applying, for reasons unrelated to quality. When does a relay
stop, how are inapplicable tests distinguished from failures, and should a
cumulative suite of the agents' own passing tests replace the historical ones
after divergence?

### COMPASS-DRAFT-agent-context-eval-O3 — The judge model

All three study models are subjects. Using one of them as judge risks favouring
its own outputs. Options: a model from a fourth lab, a rotating judge that never
grades its own family, or each item judged by two models with disagreements
sent to a human. Which, and does the κ ≥ 0.6 acceptance threshold suffice?

### COMPASS-DRAFT-agent-context-eval-O4 — Acting on contamination

If the probe shows that a model recalls Classic's API in detail, are that
model's results reported with a caveat, excluded, or rerun on a private
repository?

### COMPASS-DRAFT-agent-context-eval-O5 — The Python phase

No suitable Python project exists. Adding documents to an existing project after
the fact would bias the test, so a Python project must be developed under
Compass from its start, which takes months. Which project, started when, and how
large must its history be before it can carry a relay?

### COMPASS-DRAFT-agent-context-eval-O6 — Cross-repository knowledge

Classic is self-contained, so this snapshot cannot test federation: decisions in
one namespace constraining work in another. A later phase could use
`classic.composer`, which depends on Classic, with Classic's corpus as a
federated read-only namespace. Is that worth a separate relay, and when?

## Appendix — Research Agenda

The evaluation is one instance of a wider set of studies that a Compass corpus
makes possible, most with little published precedent (see
[COMPASS-DRAFT-agent-context-prior-art](Eval.PriorArt.AgentContext.md)). Listed
here so that the protocol's data can be planned to serve later studies.

Table: Studies a Compass corpus could support, their closest precedent, and
where this protocol covers them.

| # | Study | Question | Closest precedent found | Covered by |
|---|---|---|---|---|
| 1 | Relay over real history | Does a typed, maintained corpus keep quality and design intent steady across fresh sessions, against one long session? | Handoff Debt (one handoff); EvoCode-Bench (one session) | Track 2 |
| 2 | Feature ablation | Which properties of a documentation scheme help agents? | The Specification Gap (completeness only) | Track 1 ablations (T1-H9) |
| 3 | Supersession robustness | Does status typing stop agents acting on outdated guidance? | MOOSEDev (retrieval, not actions) | Track 1 seeded supersession (T1-H7) |
| 4 | Rejected-alternative recall | Do recorded alternatives prevent design churn? | None found | Track 1 rejected-alternative tasks (T1-H8) |
| 5 | Agent-maintained corpus accuracy | Does a corpus maintained by agents stay correct, and at what review cost? | Chatlatanagulchai et al. (observational) | Track 2 maintenance steps (G9, G10); review time not yet measured |
| 6 | Structured query versus search in tasks | Does SPARQL or structured lookup beat search or vector retrieval on development tasks? | MOOSEDev (retrieval only) | Not covered; needs the RDF export (COMPASS-DRAFT-toolchain-D17) |
| 7 | Cross-model corpus use | Does a corpus maintained with one model serve others equally? | Handoff Debt (cross-model, one handoff) | Not covered; a relay variant swapping models between steps |
| 8 | Security-invariant preservation | Does typed context reduce security regressions? | None found with documentation as the variable | Track 1 security tasks (T1-H6) |
| 9 | Coordination between parallel agents | Does a shared corpus reduce design-intent conflicts between parallel branches? | The Specification Gap (single task, docstrings) | Not covered |
| 10 | Cost-benefit of documentation | When does the cost of authoring pay off in agent performance? | None found | Derivable from studies 1–4 if authoring time is recorded |
| 11 | Federation | Do decisions recorded in another repository constrain agents correctly? | None found | Not covered; see COMPASS-DRAFT-agent-context-eval-O6 |

To keep studies 5 and 10 possible, the harness records the time humans spend
authoring and reviewing corpus changes during the study.

## Appendix — Source Map

Table: Sections of this evaluation and the primary sources each draws on.

| Section | Primary sources |
|---|---|
| Thesis | COMPASS-DRAFT-operator-memory; Xue (2026); ContextEcho; LOCA-bench |
| What the published studies do and do not show | Gloaguen et al. (2026); Khatri (2026); Chatlatanagulchai et al.; EvoCode-Bench; Xue (2026); Handoff Debt (2026); Codified Context (2026); MOOSEDev (2026); COMPASS-DRAFT-agent-context-prior-art |
| Decision rules | COMPASS-DRAFT-toolchain-D10 to D14; COMPASS-DRAFT-agent-workflow-D9, D10 |
| Harness | OpenCode CLI (`run`, `export`); Ben Sghaier et al. (2026) on harness drift |
| Statistics | Schuirmann (1987); Khatri (2026) on equivalence testing in this setting |
| The Shared Scenario | Classic repository history, surveyed at `6e4f02d` |
| Track 1 setups | Gloaguen et al. (2026) and Khatri (2026) settings, adapted |
| Security-invariant tasks | COMPASS-DRAFT-secure-development; Classic's `securityPoints.md` |
| Seeded-supersession and rejected-alternative tasks; ablation setups | The Specification Gap (2026); MOOSEDev (2026); ADR violation detection (2026); COMPASS-DRAFT-agent-context-prior-art |
| Research Agenda | COMPASS-DRAFT-agent-context-prior-art; Spec-Driven Test Generation (SpecOps '26) |
