---
id:            COMPASS-DRAFT-eval-snapshot
title:         Compass Snapshot Study — Planning Track 1 of the Agent-Context Evaluation
genre:         Plan
scope:         program
program:       Compass
component:     agent-context
language:      en
status:        Draft
provenance:
  assistant:   opencode
  session:     "Design conversation on Track 1, 2026-11-01 to 2026-11-05"
relates-to:
  - COMPASS-0006
  - COMPASS-0010
  - COMPASS-0004
  - COMPASS-0007
  - COMPASS-0002
  - COMPASS-0009
  - COMPASS-0001
  - COMPASS-DRAFT-positioning
cites:
  - title:     "Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents? (Gloaguen, Mündler, Müller, Raychev, Vechev; MemAgents @ ICLR 2026)"
    locator:   "arXiv:2602.11988v2, §3.2, §4.1, App. A–C"
    external:  true
  - title:     "Do Context Files Help Coding Agents? A Two-Agent Ablation Study on Real Repositories (Khatri, 2026)"
    locator:   "arXiv:2607.27250, §3.2–§3.6, §4.5, Limitations"
    external:  true
  - title:     "Handoff Debt: The Rediscovery Cost When Coding Agents Take Over Interrupted Tasks (KC, Budathoki; 2026)"
    locator:   "arXiv:2606.02875v2, §4, App. B"
    external:  true
  - title:     "EvoCode-Bench: Evaluating Coding Agents in Multi-Turn Iterative Interactions (2026)"
    locator:   "arXiv:2605.24110, §3.2, §5, App. D"
    external:  true
  - title:     "When and How Context Rot Appears in Coding Agents (Xue, 2026)"
    locator:   "arXiv:2607.17937v2, §2.3, §6.8–§6.9"
    external:  true
  - title:     "Ontology-Grounded Project Memory for Coding Agents (Adam; NeSy 2026)"
    locator:   "arXiv:2608.13662, §3–§4"
    external:  true
  - title:     "The Specification Gap: Coordination Failure Under Partial Knowledge in Code Agents (2026)"
    locator:   "arXiv:2603.24284v1, §3.6"
    external:  true
  - title:     "Grounding AI Agents in Contracts: An Empirical Evaluation of Spec-Driven Test Generation (Tufano et al.; SpecOps '26)"
    locator:   "arXiv:2608.17177v2, §4–§5"
    external:  true
  - title:     "Spec Kit Agents: Context-Grounded Agentic Workflows (2026)"
    locator:   "arXiv:2604.05278v1, §4"
    external:  true
  - title:     "Don't Blame the Large Language Model: How Agent Harness Evolution Shapes Coding Agent Quality (Ben Sghaier, Li, Adams, Hassan; 2026)"
    locator:   "arXiv:2607.03691v2, §3, §8"
    external:  true
  - title:     "SWE-smith: Scaling Data for Software Engineering Agents (Yang et al., 2025)"
    locator:   "arXiv:2504.21798v2, abstract (task synthesis by breaking existing tests)"
    external:  true
  - title:     "Empirical Standards for Software Engineering Research (Ralph et al., ACM SIGSOFT)"
    locator:   "arXiv:2010.03525v2; the Experiments and Registered Reports standards"
    external:  true
  - title:     "Which test is the best for equivalence? Two one-sided tests (Schuirmann, 1987)"
    locator:   "J. Pharmacokinetics and Biopharmaceutics 15(6)"
    external:  true
  - title:     "A simple sequentially rejective multiple test procedure (Holm, 1979)"
    locator:   "Scandinavian Journal of Statistics 6(2)"
    external:  true
  - title:     "Fitting Linear Mixed-Effects Models Using lme4 (Bates, Mächler, Bolker, Walker; 2015)"
    locator:   "Journal of Statistical Software 67(1)"
    external:  true
decisions:
  - COMPASS-DRAFT-eval-snapshot-D1
  - COMPASS-DRAFT-eval-snapshot-D2
  - COMPASS-DRAFT-eval-snapshot-D3
  - COMPASS-DRAFT-eval-snapshot-D4
  - COMPASS-DRAFT-eval-snapshot-D5
  - COMPASS-DRAFT-eval-snapshot-D6
  - COMPASS-DRAFT-eval-snapshot-D7
  - COMPASS-DRAFT-eval-snapshot-D8
  - COMPASS-DRAFT-eval-snapshot-D9
  - COMPASS-DRAFT-eval-snapshot-D10
  - COMPASS-DRAFT-eval-snapshot-D11
  - COMPASS-DRAFT-eval-snapshot-D12
  - COMPASS-DRAFT-eval-snapshot-D13
  - COMPASS-DRAFT-eval-snapshot-D14
  - COMPASS-DRAFT-eval-snapshot-D15
  - COMPASS-DRAFT-eval-snapshot-D16
open-questions:
  - COMPASS-DRAFT-eval-snapshot-O1
  - COMPASS-DRAFT-eval-snapshot-O2
  - COMPASS-DRAFT-eval-snapshot-O3
  - COMPASS-DRAFT-eval-snapshot-O4
  - COMPASS-DRAFT-eval-snapshot-O5
  - COMPASS-DRAFT-eval-snapshot-O6
  - COMPASS-DRAFT-eval-snapshot-O7
---

# Compass Snapshot Study: Development Plan

This plan turns Track 1 of [COMPASS-0006](Eval.AgentContext.md), the snapshot
tasks, into a study that can be built, frozen, run, and published. COMPASS-0006
fixes the hypotheses (T1-H1 to T1-H9), the setups (A1–A4 and the ablations
A2−S, A2−R, A2−L), the measures (G1–G11), and the decision rules; this plan
does not change them. It settles what the protocol left open or got wrong when
checked against Classic and against the published studies: the exact snapshot,
how the corpora are built, how tasks are made and accepted, how runs are
isolated and graded, how the data are analysed, and which documents and
publication record the work. The prior art it draws on is assessed in
[COMPASS-0010](Eval.PriorArt.AgentContext.md); the designs under test are
those of [COMPASS-0004](Plan.Toolchain.md) (COMPASS-D14 to COMPASS-D18),
[COMPASS-0002](Spec.SourceHeaders.md), and
[COMPASS-0007](Plan.AgentWorkflow.md).

## Problem

COMPASS-0006 was written before its scenario was examined closely. Checking it
against Classic and against the methods of the published studies turned up
problems of four kinds:

- **The scenario.**
  - Classic's code at `bad2094` did not load correctly. The `in-package` form
    of `blog.lisp` sat inside a `#| … |#` comment, so `make-blog` was never
    defined, and five test files depended on it. The steward fixed this in
    `807640b` (`CLASSIC:mod/classic.models.common/blog.lisp:make-blog@807640b`),
    which also adds a test of package integrity
    (`CLASSIC:test/test-packages.lisp@807640b`).
  - Two of the four illustrative security tasks rely on checks Classic does
    not have. `receive-from-peer` stores whatever any peer sends
    (`CLASSIC:mod/classic.engine.ref/federation/protocol.lisp:receive-from-peer@bad2094`),
    and `make-classic-uri` checks only that its arguments are strings
    (`CLASSIC:src/uri.lisp:make-classic-uri@bad2094`).
- **The corpora.**
  - At `bad2094`, Classic's 24 documents, its README, and `securityPoints.md`
    have no front-matter.
  - The Compass form of the same documents at HEAD was produced in October
    2026 (CLASSIC-0032) and adds facts the earlier documents lacked: staleness
    notes, a split of the schema contract that includes a new Survey, and ten
    later surveys. HEAD's corpus therefore cannot simply be used as A2.
  - HEAD's statuses mark no document `Superseded`. Documents the later work
    contradicts, such as the schema contract and the workflow reference, are
    `Current`, despite CLASSIC-D98's intention that they stay `Draft`.
- **Power.**
  - Khatri estimates that bounding a 10-point effect needs about 120–200 tasks.
    The protocol's equivalence test (T1-H5) has about 6 control tasks, so it
    cannot support an equivalence claim.
  - Trap tasks rest on distinct pieces of project knowledge and cannot be
    generated. Classic probably yields 15–25, which detects only large effects.
- **Method.**
  - The protocol bootstraps over runs and uses Fisher's exact test for small
    cells. Runs within a task are not independent, and the comparisons are
    paired, so the task must be the unit of analysis.
  - Nine hypotheses across three models need multiple-comparison control.
  - The judge (COMPASS-O19) is unresolved.
  - The worktree's Git history would let an agent read later documents.
  - A2 adds an instruction to consult documents that A1 lacks. Khatri found
    that a difference in the channel that delivers context confounds its
    comparisons.
  - A2's instructions direct the agent to the `compass` toolchain and skills,
    but the protocol does not say whether they are present in any workspace.
  - The assistant that helped design the study, Claude Opus 5.5, is also the
    pilot's subject model.

## Goals

- A Track 1 study that can be run without waiting for Track 2 or for
  `compass-maintain`, and whose pilot answers the questions the Toolchain
  roadmap's step 6 waits on.
- A snapshot that builds and passes its own test suite, with documents in a form
  that leaks nothing the agents could not have known.
- Setups that differ only in the form and delivery of the same facts, as
  COMPASS-0006 requires, and ablations that differ from A2 only in the feature
  removed.
- Tasks that each pass explicit gates, with difficulty that leaves room to
  detect an effect, and controls in numbers that can grow.
- An analysis that reviewers will recognise, with the smallest detectable effect
  of each test recorded before any run.
- A harness built for one repository now and several later.
- A record of the study in the corpus, and a paper derived from it.

## Settled Decisions

All sixteen decisions are proposals for the steward. Several were agreed in
the design conversation of 2026-11-01 to 2026-11-05 and are marked so; the
steward accepts them.

### COMPASS-DRAFT-eval-snapshot-D1 — Track 1 runs and reports ahead of Track 2

**Status:** Proposed

**Context:** COMPASS-0006 plans one pilot covering both tracks. Track 2's R4
condition needs `compass-maintain` (COMPASS-D42), which is not built, and its
relay needs task statements and answer keys for 19 steps. Track 1 needs neither.
Of the decisions gated on the pilot, those about delivery and the source map
(COMPASS-D15, COMPASS-D18, and the injection part of COMPASS-D43) are acted on
by Track 1's rules alone; COMPASS-D16 is acted on by both tracks.

**Decision:** Track 1 has its own pilot, run and reported first, as a separate
part of the protocol's execution plan. Its decision rules may fire on its own
results. The rules shared with Track 2 (those acting on COMPASS-D16) wait for
both tracks before the steward acts on them. Track 2 keeps its pilot, run
when its prerequisites exist. *Agreed in conversation.*

**Alternatives:** One joint pilot, as written. It delays every Track 1
result until `compass-maintain` and the relay material exist, for no gain in
validity. Running Track 1 to completion before piloting Track 2 at all was
also rejected: Track 2 is the primary track, and its pilot should not wait on
Track 1's full study.

### COMPASS-DRAFT-eval-snapshot-D2 — The snapshot is Classic's code at 807640b with its documents at bad2094

**Status:** Proposed

**Context:** `bad2094` is the last commit that changed code before the
documents were migrated, and its code did not load correctly. Classic's `src/`, `mod/`, and
`test/` are identical from `bad2094` to `9361be1`; `807640b` changes only
`blog.lisp`, `classic.asd`, `test/helpers.lisp`, and adds
`test/test-packages.lisp`. The documents changed heavily after `bad2094`.

**Decision:** The snapshot's code tree is Classic's at `807640b`; its
documents, for every setup, derive from Classic's at `bad2094`. The new package
test is part of the visible suite. The full suite is run 20 times at the
snapshot in the study's container:
- a test that fails on some runs but not all is recorded as flaky and excluded
  from every oracle (COMPASS-DRAFT-eval-snapshot-D7);
- a test that fails on every run blocks acceptance until the snapshot is
  corrected;
- the snapshot is accepted when every test not recorded as flaky passes on all
  20 runs.

*Wording agreed in conversation.*

**Alternatives:** The parent of `bad2094` (`2e6e88c`), the last commit whose
code was probably sound, loses `bad2094`'s document changes and requires a
second reconciliation of code and documents. Leaving the defect in place and
making it a task would put a failing suite in front of every agent in every
task.

### COMPASS-DRAFT-eval-snapshot-D3 — One set of documents, in two forms, with statuses as practised

**Status:** Proposed

**Context:** COMPASS-0006 requires every setup to carry the same facts. HEAD's
Compass corpus adds facts; the `bad2094` documents are the content baseline.
The steward chose to reproduce the statuses Classic's documents actually
received at HEAD, rather than statuses an ideal maintainer would assign, so
that A2 tests Compass as practised.

**Decision:**
- **The baseline** is the 24 documents under `doc/` at `bad2094`, with
  `README.md` and `securityPoints.md`.
- **A1** is the baseline unchanged.
- **A2** is a form-only conversion of the baseline:
  - front-matter, genre, status, and identifiers;
  - decision records with full identifiers and the statuses they carry at HEAD;
  - commit-pinned code references.
- **Statuses.** Each document takes the status of its HEAD counterpart. A
  document split at HEAD stays whole and takes the status of its principal
  successor; for `CLASSIC:doc/SchemaContract.md@bad2094`, that is the Spec,
  `Current`.
- **No new text.** The conversion adds no prose. The HEAD annotations that
  record later knowledge, such as migration notes and staleness remarks, are
  not carried over.
- **No dates in the base corpus.** Workspaces have no history
  (COMPASS-DRAFT-eval-snapshot-D6), so Git can supply no dates or authors, and
  explicit `created` or `updated` fields in A2 alone would give it facts A1
  lacks. No setup's base corpus carries dates. Seeded pairs carry the same
  explicit dates in every setup (COMPASS-DRAFT-eval-snapshot-D4).
- **Files at the root.** `securityPoints.md` stays outside the corpus at HEAD
  by Classic's own decision (CLASSIC-0032, Scope and Non-Goals), so it has no
  HEAD status to reproduce. It is unchanged and untyped in every setup, unless
  COMPASS-O37 is resolved and the analysis migrated before the freeze, in which
  case A2–A4 carry the migrated form, as COMPASS-0006 provides. `README.md` is
  unchanged in every setup.
- **The manifest and ledger.** A2–A4 carry a `compass.sexp` that declares the
  CLASSIC namespace with no federation, and a ledger holding only the
  baseline's documents and records, so that it names no later document.
  Before the freeze, `compass check` (COMPASS-DRAFT-eval-snapshot-D16) must
  report no errors on the A2 workspace.
- **Records of the conversion.**
  - A conversion table lists each document, its HEAD counterpart, and the
    fields set.
  - A reviewer other than the converter checks each converted document against
    its original for added content, and the check is recorded.
  - Because real stale documents are `Current` in A2, its typing points away
    from the guidance that corrects them. Supersession tasks drawn from real
    history therefore test Compass as practised, and their results are
    reported apart from the seeded-supersession tasks, whose typing follows
    the protocol (see COMPASS-DRAFT-eval-snapshot-O3).

*Statuses as practised agreed in conversation.*

**Alternatives:**
- **HEAD's corpus as A2** adds facts.
- **Statuses an ideal maintainer would assign** test the mechanism rather than
  the practice. That is an honest variant, but not the one chosen, and it
  remains open as a later addition.
- **A1 made by stripping the typing from A2** would match content most
  exactly, but A1 would no longer be the documents as their authors wrote them.

### COMPASS-DRAFT-eval-snapshot-D4 — Seeded pairs and ablations are generated overlays of the A2 corpus

**Status:** Proposed

**Context:** Each ablation must differ from A2 only in the feature it removes,
and each seeded-supersession task places a pair of documents in every setup.
Hand-editing several corpora invites unrecorded differences.

**Decision:**
- **Ablations by program.** A2−S, A2−R, and A2−L are produced from A2 by
  programs in the harness, never by hand:
  - A2−S removes `status`, `supersedes`, `superseded-by`, and the
    `**Status:**` lines of records.
  - A2−R removes every `**Alternatives:**` paragraph.
  - A2−L removes `id`, record identifiers in headings (keeping the titles),
    and `relates-to`, and turns identifier links into file-name links.
- **Tests of each transform.** Each transform has tests showing that it
  removes its feature and leaves every other byte unchanged.
- **Seeded pairs.** A pair is an overlay applied to a task's workspace in
  every setup, and each of its documents carries its date explicitly and
  identically in every setup. A1 carries both documents untyped. A2–A4 mark
  the earlier one `Superseded`, with a `superseded-by` link. A2−S drops those
  markers.
- **Catalog and map follow the overlay.** Where a task has an overlay, A3's
  catalog and A4's catalog and map are rebuilt for that task's corpus, by the
  same procedure as the base catalog, so that the catalog never omits a
  document the corpus holds.
- **Real pairs first.** A pair is taken from Classic's history where a later
  version of a document reverses an earlier one. Otherwise it is written for
  the study, identified as constructed, and reported separately.

**Alternatives:** Hand-built ablation corpora, which cannot be shown to differ
only in the feature; or seeded documents written into the base corpus for all
tasks, which would let one task's pair affect another's.

### COMPASS-DRAFT-eval-snapshot-D5 — Every setup carries an AGENTS.md in the same place

**Status:** Proposed

**Context:** A2 adds the Compass AGENTS snippet, which tells the agent to
consult the documents; A1 as written has no `AGENTS.md`. A2 against A1 would
then compare typing plus an instruction. Khatri found that a difference in
the channel delivering context confounded his comparisons.

**Decision:**
- **Every setup has a root `AGENTS.md`.**
  - In A1 it says where the documents are and asks the agent to consult them
    before changing code, at roughly the snippet's length.
  - In A2 it is the Compass snippet, filled for Classic, including the same
    sentence asking the agent to consult the documents before changing code.
  - In A3 it is the snippet followed by the catalog.
  - In A4 it is A3's, with the source map's top level.
  - The screening setup A0 (COMPASS-DRAFT-eval-snapshot-D7) gets a neutral
    file of the same length that names no documents.
  - Only the snippet names the Compass toolchain and skills. They are present
    in every setup (COMPASS-DRAFT-eval-snapshot-D16), but A0's and A1's files
    do not mention them.
- **The files are fixed at freeze.** Their texts are recorded, and their token
  counts are reported as the injected context of each setup (G8).

**Alternatives:** No `AGENTS.md` in A1, which confounds instruction with form.
An identical generic instruction in every setup was also rejected: A2's
snippet, which explains the corpus's typing, is part of the design under
test.

### COMPASS-DRAFT-eval-snapshot-D6 — Workspaces are isolated single-commit repositories

**Status:** Proposed

**Context:** `git log` in a worktree of Classic shows every later document and
commit. Classic is public on GitHub, so network access would expose HEAD. The
local Quicklisp configuration indexes Classic's working tree, so a snapshot
could silently load HEAD's code. The protocol's runs use `--auto`, which
approves every tool call.

**Decision:**
- **The workspace.** Each session starts from a fresh repository whose single
  commit holds the snapshot tree and the setup's documents, with no remotes.
- **The container.** It holds that repository, a pinned SBCL, and the
  Quicklisp dist of 2023-06-18, with Classic's systems registered explicitly
  through an ASDF source registry that excludes every other location.
- **The network.** The container has no network access except to a proxy
  outside it, which forwards model requests and holds the API credentials, so
  the container holds none.
- **The OpenCode version is pinned** for the whole study (Ben Sghaier et al.).
- **Checks before use.** Before a container image is used, a check confirms
  that the history is absent, that there is no route to GitHub, and that the
  loaded `classic` system's files lie inside the workspace.

**Alternatives:** Worktrees of Classic's repository, which expose history;
pruning history in place, which leaves reflogs and objects to find; and
credentials inside the container, which `--auto` puts in reach of the agent.

### COMPASS-DRAFT-eval-snapshot-D7 — Tasks pass three gates and are screened on a code-only setup

**Status:** Proposed

**Context:** A task that every setup passes, or every setup fails, cannot show
an effect, and a task whose trap can be avoided without the knowledge it
tests measures nothing. EvoCode-Bench cross-validates every test against the
current requirements and tries shortcut strategies on it. Xue requires a gate
showing that each task is solvable in clean conditions. Khatri screens tasks
for each agent separately. Selecting tasks on the pass rates of a setup that
is later compared would bias that comparison through regression to the mean.

**Decision:**
- **Each task is recorded with:**
  - its category;
  - an issue-style statement;
  - where the needed knowledge lives, and whether it can be recovered from
    the code;
  - its hidden checks;
  - a reference solution;
  - for trap tasks, a trap-violating solution.
- **Three gates.** A task enters the bank only when:
  1. the reference solution passes its hidden checks;
  2. the untouched snapshot fails them;
  3. for a trap task, the trap-violating solution fails at least one check
     that names the trap. A reviewer also confirms that no hidden test asserts
     anything beyond the statement and the current guidance.
- **Who writes the statements.** They are drafted by a model from none of the
  three subject labs and not the judge, named at freeze, and reviewed by the
  steward for leaks of document content.
- **Who writes the trap tasks.** At least half are written by the steward,
  from development experience before re-reading the corpus.
- **Screening.**
  - Tasks are screened on A0, a setup used only for screening: the code with
    no documents and the neutral `AGENTS.md`. It is never analysed.
  - Each model runs each task 3 times on A0.
  - A control task is kept for a model only if it is neither always passed nor
    always failed there.
  - A trap task is kept if its trap is triggered at least once on A0. A trap
    no one falls into without documents does not test them. Traps graded by
    the judge, such as design churn (G11), need judge passes on the screening
    runs, which adds to the screening cost.
  - Because tasks are kept per model, the models' task sets may differ. This
    is intended; comparisons between models use only the tasks they share.
  - Screening runs are never pooled into the study.

**Alternatives:** Screening on A1, which biases the A1 comparisons; no
screening, which spends runs on inert tasks; and statements written by a
subject model, which may favour that model.

### COMPASS-DRAFT-eval-snapshot-D8 — Control tasks come from injected bugs, hollowed features, and written features

**Status:** Proposed

**Context:** T1-H5 needs many control tasks to support an equivalence claim,
and the cost rules need control tasks in every setup. Written features are the
most realistic and the most expensive. SWE-smith generates tasks at scale by
breaking a repository's existing tests. A no-harm test is informative only
where documents could plausibly mislead, and tasks clustered in one file are
not independent.

**Decision:** The control bank draws on three sources:
1. **Injected bugs.** A function covered by tests is modified, by
   hand-coded mutation operators or by a non-subject model's rewrite, until it
   breaks between one and five tests and leaves the rest of the suite passing.
   The issue text describes the symptom, and the broken tests are withheld
   from the workspace.
2. **Hollowed features.** A function the documents do not describe is
   removed with its tests, and the task asks for it back.
3. **Written features.** These are drafted from the code alone.

The bank is stratified by subsystem (URIs, metaclass, persistence, migration,
federation, theme, wiki, forum, articles, accounts) and by whether the
documents cover the area. It allows at most two tasks per function and four
per file. The full study's default is about 24 control tasks: 16 injected,
4 hollowed, and 4 written. The final number is set at freeze from the power
simulation and the budget. The pipeline is built so that the bank can grow
without a change of design (COMPASS-DRAFT-eval-snapshot-O1).

**Alternatives:** Only written features, which caps the bank at about 20. Only
injected bugs, which are cheap but artificial and narrow in kind. More runs per
task instead of more tasks, which Khatri shows buys little power.

### COMPASS-DRAFT-eval-snapshot-D9 — Security-invariant tasks preserve checks that exist

**Status:** Proposed

**Context:** COMPASS-0006 tests the preservation of Classic's security checks,
not their construction. Two of its illustrative candidates name checks that do
not exist, and preserving an absent check cannot be tested. Classic does have
enforced checks:
- role checks on workflow transitions
  (`CLASSIC:mod/classic.engine.ref/workflow-engine.lisp:attempt-transition@bad2094`);
- per-role permissions
  (`CLASSIC:mod/classic.models.common/accounts.lisp:account-has-permission-p@bad2094`),
  used by articles, the forum, and the wiki;
- the forum's moderation guard
  (`CLASSIC:mod/classic.models.common/forum.lisp:%require-permission@bad2094`).

**Decision:** Security-invariant tasks are drawn from operations guarded by
existing checks, for example:
- a new state-changing content operation that must go through
  `attempt-transition`;
- a new article operation that must check the `:write` permission;
- a new forum moderation operation that must pass the moderation guard;
- a new wiki operation that keeps the wiki's permission checks.

The two candidates without a check are dropped. Each task keeps its negative
test that attempts the bypass. The missing peer check in `receive-from-peer`,
and the absence of validation in `make-classic-uri` and `parse-classic-uri`,
are reported to the steward as findings about Classic; this study changes
nothing in Classic.

**Alternatives:** Adding the missing checks to the snapshot so that they can be
preserved, which alters the code under study. Keeping the candidates as
"construction" tasks, which changes what T1-H6 asks.

### COMPASS-DRAFT-eval-snapshot-D10 — The task is the unit of analysis, and T1-H5 is descriptive

**Status:** Proposed

**Context:** Runs of one task share its difficulty, and every comparison is
paired by task. Khatri, Handoff Debt, and Tufano all analyse at the task level
with paired tests. T1-H5 cannot be powered on Classic's control tasks. The
steward chose to report it descriptively for now and keep the confirmatory
form possible later.

**Decision:**
- **Primary model.** For each model separately, a mixed-effects logistic
  model of each binary measure, with setup as a fixed effect and a random
  intercept per task, fitted with `lme4`.
- **Paired contrasts.** Each pair of setups is compared with a task-clustered
  bootstrap (10,000 resamples) of the difference in pass rates, and a Monte
  Carlo permutation test that permutes setup labels within tasks. Fisher's
  exact test is not used.
- **Primary endpoints, by hypothesis.**
  - T1-H1 and T1-H6: a *clean pass*, meaning G1, G2, and G3 all hold.
  - T1-H2 and T1-H7: supersession errors (G7).
  - T1-H8: design churn (G11).
  - T1-H9: the endpoint of the task's category, as above.

  Each component of a clean pass is reported as well.
- **Partial credit.** The share of hidden tests passed is a secondary measure,
  as in *The Specification Gap*.
- **Cost (G8).** Analysed on log scale, with ratios and task-clustered
  intervals. COMPASS-0006's rule that A3 must not add more than 20% cost names
  no baseline. This plan reads it as A3 against A2, the setup A3 extends; the
  steward confirms that reading in the update to COMPASS-0006.
- **Families.** Holm's correction is applied within each family, for each
  model:
  - trap tasks: T1-H1, T1-H6, T1-H7, T1-H8;
  - delivery: T1-H3, T1-H4;
  - ablation: T1-H9.
- **Exploratory and descriptive.** T1-H2 on real history is exploratory, given
  the statuses as practised. T1-H5 is descriptive: equivalence intervals are
  reported for A2, A3, and A4 against A1, with the smallest effect each could
  detect, and no equivalence is claimed.
- **Before the freeze.** A power simulation (with `simr` or an equivalent)
  computes the smallest detectable effect of every confirmatory test from
  assumed parameters. It is recomputed from the pilot's pass rates and the
  spread of effects between tasks.

*T1-H5 as descriptive agreed in conversation.*

**Alternatives:**
- **Run-level bootstrap and Fisher's exact test, as written.** These treat
  dependent runs as independent.
- **A confirmatory equivalence claim with about 6 control tasks.** It cannot
  succeed.
- **A pooled analysis across models as the primary result.** COMPASS-0006
  reports per model first.

### COMPASS-DRAFT-eval-snapshot-D11 — Gemini 4 Argon judges blinded, content-keyed transcripts

**Status:** Proposed

**Context:** COMPASS-O19 asks who judges, since all three study models are
subjects. Transcripts reveal the setup: file names carry genre prefixes, and
tool output shows front-matter. MOOSEDev nearly published a 20-point effect
that was an artefact of grading, and recommends keeping transcripts unaltered
so that they can be re-graded and validating the judge against cases whose
answer is known. Tufano randomises and anonymises the material judged, takes
a majority over several judge passes, and lets the judge see the ground truth.

**Decision:**
- **The judge** is Gemini 4 Argon (`opencode/gemini-4-argon`), from a lab
  none of the subject models comes from, pinned for the study.
- **Redaction.** It sees a redacted copy of each transcript and diff:
  - document paths mapped to neutral labels;
  - front-matter and record identifiers removed from tool output;
  - the setup label absent.
- **Content-keyed grading.** Supersession (G7) and design churn (G11) are
  graded against an answer key that states the superseded guidance or rejected
  design by its content, not by its status.
- **Passes.** Each item is judged three times, in random order, and the
  majority verdict stands.
- **Validation.** The judge is validated on a set of constructed items with
  known verdicts.
- **Human calibration.** The steward blind-grades a stratified sample of at
  least 10% of judged items. A measure is accepted for the judge only at
  Cohen's κ ≥ 0.6; otherwise the steward grades it, or it is dropped.
- **Unaltered transcripts.** The original transcripts are kept unchanged.

This proposes a resolution of COMPASS-O19 for Track 1; the steward resolves
it. *Judge model agreed in conversation.*

**Alternatives:** A subject model as judge, which risks favouring its own
outputs. Two judges with a human adjudicating every disagreement, which costs
more human time than the calibration sample already takes.

### COMPASS-DRAFT-eval-snapshot-D12 — A Lisp harness in eval/, driven by snapshot descriptors, with the analysis in R

**Status:** Proposed

**Context:** The steward chose a Lisp runner that drives the shell, and an
analysis system reviewers know. Common Lisp has no mature equivalent of
`lme4`. A second repository may join the study later
(COMPASS-DRAFT-eval-snapshot-O2), and the harness should not need rewriting
when it does.

**Decision:**
- **Location.** The harness lives in `eval/` as its own ASDF system,
  `compass-eval`, outside `compass.asd`, with FiveAM tests in a
  `compass-eval/tests` system and source headers as in `src/`. It runs
  OpenCode, the container runtime, and Git as external programs, always with
  argument lists. The repository's own guards, such as
  `no-stray-format-strings`, scan only `src/`; `compass-eval/tests` carries
  its own where they apply.
- **Snapshot descriptors.** Each repository is described by a descriptor
  under `eval/snapshots/` that names:
  - the code and document revisions;
  - the test command and the flaky tests;
  - the corpora of each setup;
  - its tasks.

  Classic's is the first.
- **Layout.**
  - `eval/src/`: descriptors, workspaces, setups and overlays, the runner, the
    recorder, grading, redaction, the judge, and the contamination probe.
  - `eval/corpora/` and `eval/tasks/`: the frozen inputs.
  - `eval/container/`: the image definitions.
  - `eval/analysis/`: R scripts with a locked package environment (`renv`).
    They read the run records and write tables and figures for the paper.
- **Run data.** Transcripts and run records are kept outside Git in an archive
  directory. A manifest of their checksums is committed, and the archive is
  deposited with the paper.

*Lisp runner, R analysis, and `eval/` agreed in conversation.*

**Alternatives:**
- **Shell scripts** are hard to test.
- **A Python harness** departs from the repository's language.
- **An analysis in Lisp** would replace the mixed-effects model with bootstrap
  tests alone, a change to the protocol.
- **A separate repository** was the earlier proposal. Keeping the harness in
  `eval/`, beside the toolchain and the corpus, keeps the protocol, its inputs,
  the harness, and the record of the study in one versioned place, frozen by
  one commit.

### COMPASS-DRAFT-eval-snapshot-D13 — What each run records, and when a run counts

**Status:** Proposed

**Context:** COMPASS-0006 lists what each run records. MOOSEDev found a memory
server that had silently failed while agents fell back on grep, and recommends
verifying in each run that the context mechanism actually fired. Xue gives
runs that produce no result their own denominator. Khatri recommends cost
metrics that mean the same across agents, rather than turns.

**Decision:**
- **What each run records,** in addition to COMPASS-0006's list:
  - the setup's injected context, as text and as tokens, measured by one
    probe request per setup;
  - every document the agent read, from its tool calls;
  - whether the setup's `AGENTS.md` appears in the session's first request,
    and whether the Compass skills are listed there (manipulation checks);
  - every `compass` command and skill the agent invoked;
  - the container image digest;
  - the harness commit.
- **Order.** Runs are interleaved in a random order, blocked by task, so that
  drift over time falls evenly on the setups.
- **Failed runs.** A run whose manipulation check fails, or which ends in an
  infrastructure error (model API failure, container fault), is rerun at most
  twice. Each such run is counted in its own reported denominator.
- **Limits.** A run that reaches its wall-clock or token limit counts as a
  failure, with limits fixed at freeze.
- **Cost.** Reported as tool calls, input, cached, and output tokens, and wall
  time; turns are not reported.
- **Human time.** The time people spend authoring and reviewing tasks and
  corpora is recorded, for studies 5 and 10 of COMPASS-0006's research agenda.

**Alternatives:** Discarding failed runs silently, which hides failures that
differ by setup; and turns as the measure of cost, which do not mean the same
across agents.

### COMPASS-DRAFT-eval-snapshot-D14 — The study is chronicled in this Plan, a Log, and updates to COMPASS-0006

**Status:** Proposed

**Context:** COMPASS-0006 is `Accepted` and says that its results are appended
as dated updates. The corrections this plan makes to Track 1 must reach the
protocol before it is frozen, and the work of building and running the study
needs a record that is pinned to its commits.

**Decision:**
- **This Plan** holds the design of Track 1 and its roadmap.
- **COMPASS-0006 is revised before the freeze.** The steward adds an
  `## Update <date> — Track 1 protocol revisions` section that applies:
  - COMPASS-DRAFT-eval-snapshot-D1 to COMPASS-DRAFT-eval-snapshot-D11,
    COMPASS-DRAFT-eval-snapshot-D13, and COMPASS-DRAFT-eval-snapshot-D16;
  - the reading of the 20% cost rule (COMPASS-DRAFT-eval-snapshot-D10);
  - the dropped security candidates;
  - the corrected statistics;
  - the resolution of COMPASS-O19 for Track 1.
- **The freeze** is a commit and tag made by the steward, cited by every
  result.
- **A Log,** `doc/Log.EvalSnapshot.md`, is written after the commit that holds
  each stage of the harness. Its code references are pinned to that commit,
  and later stages are appended as dated updates. It records deviations, the
  inventory of runs, cost, and human time.
- **Results** are appended to COMPASS-0006 as dated updates: the pilot report,
  then the full study. COMPASS-0006's Synthesis is written from them. Each
  decision rule that fires leads the steward to amend the decision it names.

**Alternatives:** A separate Eval for Track 1's results, which splits the
protocol from its results. Recording results only in the paper, outside the
corpus.

### COMPASS-DRAFT-eval-snapshot-D15 — The paper lives in pub/, as an ACM preprint derived from the record

**Status:** Proposed

**Context:** The steward plans an arXiv preprint followed by a conference
submission. A paper is not a Compass genre; it is a derivation of the record
plus curation, in the sense of §21. Reviewers in empirical software
engineering expect the ACM SIGSOFT Empirical Standards. The design used an
assistant from one of the subject models' labs. Major software-engineering
conferences review double-blind, and a paper about Compass by its designer,
with a preprint already public, is hard to anonymise.

**Decision:**
- **Location and format.** The paper lives in `pub/snapshot-study/`, outside
  the corpus, as LaTeX in the ACM `acmart` class (`sigconf`), with
  `refs.bib` and figures generated by `eval/analysis/`.
- **The outline below** is followed, and the Experiments and Registered
  Reports standards serve as the reporting checklist.
- **Disclosures.** The paper states:
  - that the steward designed Compass, wrote much of Classic's corpus, and
    wrote some of the tasks;
  - that an assistant from a subject model's lab helped design the study;
  - every result, null results included.
- **Release.** The harness, corpora, tasks, redacted transcripts, and analysis
  are deposited with a DOI when the preprint is posted.
- **Double-blind review.** The conference is chosen with its anonymity and
  preprint policies in view. The submitted version refers to Compass, Classic,
  and the steward in the third person and points to an anonymised copy of the
  deposit, as the venue's policy allows (COMPASS-DRAFT-eval-snapshot-O7).

*arXiv preprint then conference, and `pub/`, agreed in conversation.*

**Alternatives:** The paper as a Compass document, which would bind a
venue's format to the corpus's rules. A journal first, which delays the
preprint.

### COMPASS-DRAFT-eval-snapshot-D16 — The Compass toolchain and skills are present in every workspace

**Status:** Proposed

**Context:** A2's Compass snippet tells the agent to use the `compass-*`
skills and to run `compass` commands such as `check`, `show`, and `outline`.
If they are absent, A2's instructions point at tools that do not exist, and
the study does not test Compass as it is meant to be used. If they are present
only in A2–A4, those setups differ from A1 in the tools available as well as
in typing. `compass show` and `outline` are navigation aids in their own right.
The toolchain and skills are part of what the study evaluates.

**Decision:**
- **Every workspace,** in every setup including A0 and the ablations, has the
  same Compass installation:
  - the `compass` executable, built at the freeze commit, on the path;
  - the `compass-*` skills with their reference bundle and the standard,
    installed where OpenCode discovers skills, outside the workspace.
- **What differs between setups** is only the corpus and `AGENTS.md`
  (COMPASS-DRAFT-eval-snapshot-D5). A2–A4 also carry the manifest and ledger
  (COMPASS-DRAFT-eval-snapshot-D3), without which the toolchain cannot read a
  corpus.
- **Consequences.**
  - A2 against A1 measures typing and the snippet with the tools held constant.
  - In A1 the tools are available, but neither `AGENTS.md` nor the untyped
    documents point to them.
  - Each run records which commands and skills were used
    (COMPASS-DRAFT-eval-snapshot-D13). Use of the tools by setup is reported
    as a mechanism measure.

*Agreed in conversation.*

**Alternatives:**
- **No tools in any workspace.** This leaves the snippet's instructions
  pointing at nothing, and tests a reduced Compass.
- **Tools only in A2–A4.** This is closer to how an adopting project looks,
  but it confounds typing with tooling, and the comparison of A2 with A1 could
  no longer be attributed to the form of the documents.

## The Snapshot and Its Corpora

Table: What each Track 1 setup receives, and how it is produced.

| Setup | Documents | `AGENTS.md` | Produced by |
|---|---|---|---|
| A0 (screening only) | None | Neutral, same length | Harness |
| A1 | Baseline unchanged | Pointer to `doc/` and an instruction to consult it | Extraction at `bad2094` |
| A2 | Baseline in Compass form, statuses as practised | Compass snippet | Hand conversion, reviewed |
| A3 | As A2 | Snippet and catalog | Catalog by hand, to COMPASS-D15 |
| A4 | As A2, with source headers in Classic's files | Snippet, catalog, and map | Headers and map by hand, to COMPASS-0002 and COMPASS-D18 |
| A2−S, A2−R, A2−L | A2 with one feature removed | Compass snippet | Transform programs |

- The catalog applies COMPASS-D16's weights by hand. Given the statuses as
  practised, stale `Current` references rank high in it, as they would in
  practice.
- A4's source headers may state only what the baseline states, each citing the
  document it comes from. A4 thus changes Classic's source files, which the
  other setups leave untouched; grading applies the agent's diff to the
  workspace it was made in.
- Per-task overlays (seeded pairs, withheld tests) are applied after the setup
  is assembled. Where an overlay adds documents, A3's catalog and A4's catalog
  and map are rebuilt for the task (COMPASS-DRAFT-eval-snapshot-D4).
- Every setup, A0 included, has the same Compass toolchain and skills
  installed (COMPASS-DRAFT-eval-snapshot-D16). A2–A4 also carry Classic's
  manifest and a ledger limited to the baseline.

## Tasks

Table: Indicative task bank for the full study, before screening.

| Category | Target | Main source | Illustrative candidates at `bad2094` |
|---|---|---|---|
| Rejected alternative | 3–5 | Development logs | Slot validation in `(setf slot-value-using-class)`, rejected in `CLASSIC:doc/model/DevLog.SlotValidation.md@bad2094`; persisting inside `attempt-transition`, rejected in `CLASSIC:doc/persistence/DevLog.WithPersistence.md@bad2094`; a required role on moderation transitions, rejected in `CLASSIC:doc/forum/DevLog.ForumDemo.md@bad2094` |
| Supersession (real history) | 2–4 | Documents stale at `bad2094` | Naming a new schema's package, where `CLASSIC:doc/SchemaContract.md@bad2094` contradicts `CLASSIC:doc/DevLog.DistFactorization.md@bad2094`; workflow code following `CLASSIC:doc/model/Workflow.md@bad2094` |
| Seeded supersession | 2–3 | Real pairs from history, else constructed | Per COMPASS-DRAFT-eval-snapshot-D4 |
| Invariant and system property | 3–5 | Logs and references | Re-persisting after mutation to keep the relation index; deletion reaching containers and peers; schema load order |
| Security invariant | 4 | Existing checks | Per COMPASS-DRAFT-eval-snapshot-D9 |
| Navigation | 1–2 | Steward | Finding the right place in the 67-file tree |
| Control | about 24 | Pipeline | Per COMPASS-DRAFT-eval-snapshot-D8 |

The pilot uses 8 trap tasks, including at least 2 security-invariant, 1
seeded-supersession, and 1 rejected-alternative task, as COMPASS-0006 states.
Interface disclosure in statements follows the proposal of COMPASS-O17: name
the public entry points the hidden tests call, and nothing else.

## Runs

Table: Indicative sessions for Track 1, before revision after the pilot.

| Part | Cells | Runs per cell | Sessions |
|---|---|---|---|
| Screening (A0) | about 44 tasks × 3 models | 3 | about 400 |
| Pilot | 8 trap tasks × A1, A3 × Claude Opus 5.5 | 5 | 80 |
| Full: trap tasks | about 20 × A1–A4 × 3 models | 5 | about 1,200 |
| Full: control tasks | about 24 × A1–A4 × 3 models | 5 | about 1,440 |
| Full: ablations | about 20 trap tasks × 3 ablations × Claude Opus 5.5 and GPT-6 Sol | 5 | about 600 |

The models are those of COMPASS-0006, at the reasoning effort recorded at
freeze. Pilot runs are not pooled into the full study; the pilot's tasks stay
in the bank. After the pilot, only parameters named in advance may change:
the numbers of tasks and runs, time and token limits, and the budget. The
hypotheses, measures, margins, and decision rules do not.

## The Paper

Working title: *Do Typed Project Records Keep Coding Agents Off Superseded and
Rejected Designs? An Ablation Study.* The title adds "Pre-registered" only if
the protocol is registered outside this repository before the runs
(COMPASS-DRAFT-eval-snapshot-O5).

Table: Outline of the paper and the record each part is derived from.

| Section | Content | Derived from |
|---|---|---|
| 1 Introduction | The problem; contributions: pressure tasks (seeded supersession, rejected alternatives, security invariants), single-feature ablation of a documentation scheme, the delivery decomposition A1–A4, an open harness | COMPASS-0006 Method; COMPASS-0010 Synthesis |
| 2 Background and Related Work | Context-file studies; multi-turn and context-rot studies; studies of documentation structure; architecture knowledge and decision records | COMPASS-0010; COMPASS-DRAFT-positioning |
| 3 Compass in Brief | Genres, statuses, records, catalog, source headers | COMPASS-0001; COMPASS-0004; COMPASS-0002 |
| 4 Study Design | Hypotheses; the Classic snapshot; tasks and gates; setups and ablations; harness and isolation; grading and judge; statistics and pre-registration | COMPASS-0006 as frozen; this Plan |
| 5 Results | Per hypothesis and per model; cost; smallest detectable effects; manipulation checks | COMPASS-0006 updates; `eval/analysis/` |
| 6 Discussion | What typing and delivery do; the decision rules that fired; statuses as practised | COMPASS-0006 Synthesis |
| 7 Threats to Validity | Internal, construct, external, and conclusion validity | COMPASS-0006 Threats; this Plan |
| 8 Conclusion | | |
| Data availability; Ethics and AI-use statement | Deposit and DOI; the disclosures of COMPASS-DRAFT-eval-snapshot-D15 | |
| Appendices | Task bank summary; prompts and `AGENTS.md` texts; judge rubric; per-task results; the power simulation | `eval/` |

## Tensions and Risks

- **Small numbers.** Trap tasks are limited by Classic's distinct knowledge,
  so the confirmatory tests detect only large effects. The smallest detectable
  effects are published before the runs, and results are reported as
  intervals rather than as significance alone.
- **Statuses as practised.** A null or negative result on real supersession
  may reflect Classic's maintenance rather than Compass's design. The seeded
  tasks separate the two, and the paper must say so.
- **One developer, one language.** A second repository would reduce the
  dependence on one repository but not on one developer or language.
- **Imperfect blinding.** Redaction may miss cues to the setup, such as an
  agent naming a document's genre. A sample of redacted items is checked by
  hand for remaining cues.
- **Cost.** About 3,700 sessions in all. The pilot's cost estimate decides
  whether the full study runs at the indicative sizes; what is cut first is a
  question for the steward (COMPASS-DRAFT-eval-snapshot-O6).
- **Contamination.** Classic, including its HEAD corpus, is public. What
  happens when the probe finds strong recall is still COMPASS-O20, which must
  be answered before the freeze.

## Open Questions

### COMPASS-DRAFT-eval-snapshot-O1 — Making the no-harm test confirmatory

Option (c) reports T1-H5 descriptively and runs the control tasks in all four
setups, so the cost rules have their data. A confirmatory version, option (a),
needs about 50 informative control tasks per model at a ±15-point margin, or
80–100 at ±10, from the injected-bug pipeline. The proposal is that only A1
against A3 and A1 against A4 become confirmatory, with Holm's correction
across the two, since those are the setups the decision rules could leave in
use, while A2 against A1 stays descriptive. Is that the scope, and what budget
would justify it after the pilot?

### COMPASS-DRAFT-eval-snapshot-O2 — A second repository

Origin (about 9,300 lines, 257 tests, documents written alongside the code)
could roughly double the trap tasks, as a separately pre-registered replication
on the same harness. Lexter has too few tests and needs a GPU; Lightdrive's
documents were written after its code. Should Study 2 on Origin follow the
pilot, and what pilot result would call for it?

### COMPASS-DRAFT-eval-snapshot-O3 — Statuses as practised and what they can show

With HEAD's statuses, A2's typing points away from the guidance that corrects
stale documents. That makes real-history supersession a test of maintenance
rather than of the mechanism. Should a later variant run the same tasks with
statuses an ideal maintainer would assign, so that the two can be compared?
Should Classic's stale `Current` documents, contrary to CLASSIC-D98, be
corrected after the study?

### COMPASS-DRAFT-eval-snapshot-O4 — A pinned model retired during the study

GPT-6.1 Sol was released a week after GPT-6 Sol. If a pinned model is retired
or changed behind its identifier before the full study ends, is that model's
incomplete data reported as it stands, or are its cells rerun on the
successor and reported as a separate model?

### COMPASS-DRAFT-eval-snapshot-O5 — Pre-registration and the release of tasks

The freeze is a commit and tag in this repository. If the repository is public
when the freeze is pushed, the protocol and tasks are public from then on;
that does not affect the pinned models, whose training predates them, but it
does affect anyone replicating the study on later models. Should the frozen
protocol also be registered externally (for example with OSF), and should the
task bank's hidden tests be held back from the public repository until the
preprint?

### COMPASS-DRAFT-eval-snapshot-O6 — The budget and what is cut first

If the pilot's cost estimate exceeds the budget for the indicative sizes, the
candidates for reduction are the third model, the ablations' second model, the
number of control tasks, and runs per cell (5 to 3). What is the budget, and in
which order are these cut?

### COMPASS-DRAFT-eval-snapshot-O7 — The conference and anonymity

The steward plans an arXiv preprint, then a conference. Venues differ in
whether they review double-blind and whether they accept papers whose preprint
is public. Compass's name, Classic's history, and the deposit all identify the
author. Which conference is the target? Is the preprint posted before
submission, or held until the venue's policy allows it? Is an anonymised
version of the deposit enough, or should the conference be chosen among those
that review single-blind?

## Prior Art

Table: Prior studies and what this plan takes from each.

| Study | What to draw from |
|---|---|
| Gloaguen et al. (2026) | Task statements rewritten by a model and checked for leaks; Git history and remotes removed; contamination split by knowledge cutoff |
| Khatri (2026) | Per-agent screening; the task as the unit of analysis; TOST on a task-clustered bootstrap; Monte Carlo power and the smallest detectable effect; cost metrics that mean the same across agents; the confound of the delivery channel |
| Handoff Debt (2026) | Paired, exact McNemar and bootstrap analysis; prompt tokens and agent events as cost; note-generation cost kept apart |
| EvoCode-Bench (2026) | Behaviour-only tests; a review that no test asserts superseded guidance; shortcut attempts on each task; failure labels audited by people |
| Xue (2026) | A clean-capability gate per task; a separate denominator for runs without a result; the stage at which a requirement is lost |
| MOOSEDev (2026) | Unaltered transcripts that can be re-graded; a check that the mechanism fired; gold answers from primary sources; a judge validated on known answers |
| *The Specification Gap* (2026) | The share of tests passed as a graded outcome; a layered ablation design |
| Tufano et al. (2026) | Task-level bootstrap; randomised, anonymised judging with a majority over passes |
| *Spec Kit Agents* (2026) | A caution: one run per cell, a judge-only outcome, and a small human check whose votes, on our reading of its Table 2, leaned the other way from the judge |
| Ben Sghaier et al. (2026) | The harness version pinned, since it alone moves results |
| SWE-smith (2025) | Tasks synthesised by breaking a repository's existing tests |
| ACM SIGSOFT Empirical Standards | The reporting checklist for the paper |

## Roadmap

Each stage that builds harness code ends with `compass-eval/tests` passing.

1. **This Plan.** The steward reviews and accepts its decisions. The steward
   then adds the Track 1 revisions to COMPASS-0006 as a dated update, and
   resolves COMPASS-O17 and COMPASS-O20 for Track 1.
2. **Harness skeleton and snapshot.**
   - The `compass-eval` system and descriptor reader; Classic's descriptor.
   - The container images, with the Compass toolchain and skills installed
     (COMPASS-DRAFT-eval-snapshot-D16); workspace construction with the
     isolation checks of COMPASS-DRAFT-eval-snapshot-D6.
   - Twenty consecutive runs of the full suite at the snapshot, with any
     flaky tests recorded.
   - `AGENTS.md` is updated with the facts of `eval/` and `pub/`.
   - The first part of `doc/Log.EvalSnapshot.md` is written after the
     commit.
3. **Corpora.**
   - A1 extracted; A2 converted, with its conversion table and review, its
     manifest, and its ledger; `compass check` reporting no errors on the A2
     workspace.
   - The A3 catalog; A4's headers and map.
   - The transform and overlay programs, with their tests.
4. **Task bank.**
   - Trap and security tasks written; the control pipeline built and run.
   - Statements drafted and reviewed.
   - The three gates applied, with their results recorded.
5. **Runner, recorder, grader, redaction, and judge.** Dry runs against a stub
   agent, then a handful of real sessions to check the records.
6. **Analysis and probe.**
   - The R scripts, run on simulated data.
   - The power simulation from assumed parameters, and the table of smallest
     detectable effects.
   - The contamination probe for each model.
7. **Freeze.** The steward commits and tags the protocol, the corpora, the task
   bank, the harness, and the table of smallest detectable effects.
8. **Pilot.**
   - Screening on A0 for the pilot's tasks.
   - The 80 pilot sessions.
   - The judge's validation and the steward's calibration sample.
9. **Pilot report.**
   - A dated update to COMPASS-0006, and an update to the Log.
   - The power simulation recomputed.
   - Sizes for the full study set within the parameters named in advance.
   - Decisions on COMPASS-DRAFT-eval-snapshot-O1, COMPASS-DRAFT-eval-snapshot-O2,
     and COMPASS-DRAFT-eval-snapshot-O6.
10. **Full study.** Screening for every task, then the trap, control, and
    ablation runs, interleaved.
11. **Analysis and publication.**
    - The results update and the Synthesis of COMPASS-0006.
    - The steward amends the decisions whose rules fired.
    - The paper is written in `pub/snapshot-study/` and the deposit made.
    - The preprint is posted.
