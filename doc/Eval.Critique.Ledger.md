---
id:            COMPASS-DRAFT-ledger-critique
title:         The Allocation Ledger — Critique
genre:         Eval
subtype:       critique
scope:         component
program:       Compass
component:     toolchain
language:      en
status:        Draft
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-0004
  - COMPASS-0013
  - COMPASS-0001
---

# The Allocation Ledger: Critique

This document is an adversarial evaluation of the Compass allocation ledger: the
append-only file that records every number a repository allocates, the rules
that check it, and the commands that allocate numbers and recover from
concurrent allocations. It is the first critique written to the form of
[COMPASS-0014](Plan.Critique.md), and serves as its worked example. This version
sets the target, the stance, the scenarios, and the rubric; it records no
findings yet. Findings are added as they are grounded, and a person disposes of
each (§8).

## Method

**Target.** The ledger as designed and as built:

- the decisions of [COMPASS-0004](Plan.Toolchain.md) that define it:
  [COMPASS-D5](Plan.Toolchain.md#compass-d5--merge-time-ledger-plus-required-ci-as-the-uniqueness-authority)
  (a merge-time ledger and a required check as the uniqueness authority),
  [COMPASS-D6](Plan.Toolchain.md#compass-d6--provisional-identifiers-for-register-entries)
  (provisional record identifiers),
  [COMPASS-D7](Plan.Toolchain.md#compass-d7--the-allocation-ledger-holds-immutable-facts-only)
  (immutable facts only),
  [COMPASS-D13](Plan.Toolchain.md#compass-d13--bootstrapping-the-compass-namespace)
  (bootstrapping by seeding), and
  [COMPASS-D26](Plan.Toolchain.md#compass-d26--one-ledger-per-repository-one-entry-per-line)
  to
  [COMPASS-D30](Plan.Toolchain.md#compass-d30--records-are-referred-to-by-full-identifier-short-forms-are-found-not-rewritten)
  (the file's shape, provisional records in numbered documents, `assign`,
  `renumber`, and short references), with the plan's sections
  [The uniqueness guarantee](Plan.Toolchain.md#the-uniqueness-guarantee) and
  [Identifier lifecycle](Plan.Toolchain.md#identifier-lifecycle);
- the standard's [ID allocation](../Compass.md#id-allocation) (§13);
- the decisions of [COMPASS-0013](Log.Ledger.md) made while building it:
  [COMPASS-D53](Log.Ledger.md#compass-d53--seeding-refuses-a-number-defined-twice)
  and
  [COMPASS-D54](Log.Ledger.md#compass-d54--the-check-after-an-allocation-uses-the-allocations-base);
- the code at `4ec6121`: the reader
  (`src/model/ledger.lisp:parse-ledger-text@4ec6121`), the rules
  (`src/rules/ledger.lisp:ledger/append-only@4ec6121` and the others in that
  file), allocation (`src/corpus/allocate.lisp:plan-assign@4ec6121`,
  `src/corpus/allocate.lisp:plan-renumber@4ec6121`), the concurrency tests
  (`tests/test-concurrency.lisp:concurrent-allocations-conflict@4ec6121` and
  the others in that file), and the repository settings it relies on
  (`.github/workflows/compass-check.yml@4ec6121`,
  `.github/CODEOWNERS@4ec6121`).

**Stance.** Red team, joined with a pre-mortem: assume that within a year a
number was allocated twice, reused, or lost from the record, by accident or by
intent, and look for the paths by which that could happen and for the costs the
design imposes on the way.

**Independence.** The critic is not independent: this critique is drafted by the
assistant that helped build the ledger, under the steward's direction. Findings
written by an author of the target deserve the steward's particular scrutiny
for blind spots, and an independent critique of the same target would
supersede this one if one is written.

**Evidence standard.** A weakness is shown by one of:

- a scenario run in a temporary Git repository, as the concurrency tests run
  theirs, with the commands and their output;
- a commit-pinned reference to code that behaves as the objection says;
- a contradiction between two of the target's documents, or between a document
  and the code.

A scenario reasoned about but not run is a hypothesis: it is recorded in the
Synthesis as a seed, not as a finding.

**Left unexamined.** The RDF export of ledger facts and aliases
(COMPASS-D21, toolchain version 0.3); eager reservation of numbers before merge,
which [COMPASS-D5](Plan.Toolchain.md#compass-d5--merge-time-ledger-plus-required-ci-as-the-uniqueness-authority)
defers; allocation in a Classic-native corpus (Tier 2, §16); the ledger's
behaviour on platforms other than Linux; and the speed of the checks beyond
this repository's size.

## The Shared Scenario

The target is put through these scenarios, each stated as what happens, so that
a finding can name the one under which it occurs:

1. **Concurrent allocation.** Two branches each assign numbers from the same
   main branch, and merge in either order, including when both merge within
   minutes through a merge queue.
2. **The careless resolution.** A contributor meets a conflict in the ledger
   and resolves it by hand: keeping both sides, taking one side, or editing a
   line, then committing.
3. **Working without the toolchain.** A contributor writes a canonical number
   by hand, edits a document in a forge's web editor, or copies a document
   between repositories, never running `compass`.
4. **History rewritten.** A branch is rebased, squash-merged, or cherry-picked;
   the main branch is force-pushed or reverted past an allocation.
5. **The long-lived branch.** A branch holds a document with many provisional
   records for weeks, is cited by provisional identifier from other branches
   and other repositories, and is assigned after main has moved on.
6. **Forks and outside contributors.** A pull request comes from a fork, whose
   CI runs with fewer permissions, and whose author is not a code owner.
7. **Several namespaces, and moving ones.** One repository owns two
   namespaces; a namespace's documents move to another repository; two
   repositories claim one namespace.
8. **Damage.** The ledger is deleted, truncated, or reformatted by an editor or
   a tool; a merge driver is configured that hides conflicts; the file grows to
   thousands of entries.
9. **Adoption.** A corpus written before Compass, with numbers already in use
   and some used twice, adopts the ledger.

## The Rubric

The qualities assessed, each with what holding up means:

- **C1 — Uniqueness.** No number allocated twice reaches the main branch, under
  any scenario above, without a check failing first.
- **C2 — Permanence.** No number, once allocated, is reused or loses its record;
  every reference written with an old provisional identifier still resolves.
- **C3 — Recoverability.** Every way of getting into trouble has a documented,
  tool-supported way out that loses no allocation and no alias.
- **C4 — Bypass resistance.** The guarantee holds without relying on
  contributors' care; where it relies on repository settings, the reliance is
  stated and checkable.
- **C5 — Cost.** Allocation is one command at acceptance; conflicts are rare and
  cheap to resolve; the rules add little to a check's time.
- **C6 — Federation.** Numbers and aliases are resolvable and unambiguous across
  the repositories of a federation.
- **C7 — Auditability.** Who allocated what, when, and from which provisional
  identifier can be read from the ledger and Git alone.
- **C8 — Independence from tools.** The ledger is readable and correct without
  the toolchain, and the design does not depend on one forge.

## Findings

No findings are recorded yet. Each will be an open-question record of this
document, listed in its `open-questions:` field, with the fields of a finding
(§8): `**Rationale:**`, `**Objection:**`, `**Evidence:**`, `**Severity:**`, and
optionally `**Seed:**`. A person adds each `**Resolution:**`.

## Synthesis

None yet: the synthesis ranks the findings' themes by severity, names the seeds
worth a Survey or a Plan, and restates what the critique did not examine, once
there are findings to rank.
