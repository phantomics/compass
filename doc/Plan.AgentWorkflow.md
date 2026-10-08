---
id:            COMPASS-DRAFT-agent-workflow
title:         Compass Agent Workflow — Memos, Review Gates, and the Maintenance Loop
genre:         Plan
scope:         program
program:       Compass
component:     authoring-assistance
language:      en
status:        Accepted
authors:
  - Andrew Sengul
approved-by:   Andrew Sengul
reviewed:      2026-10-08
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-0001
  - COMPASS-DRAFT-authoring-assistance
  - COMPASS-DRAFT-toolchain
  - COMPASS-DRAFT-operator-memory
  - COMPASS-DRAFT-source-headers
  - COMPASS-DRAFT-agent-context-eval
cites:
  - title:     RFC 7322 — RFC Style Guide
    locator:   "§4.6 Status of This Memo"
    external:  true
  - title:     git-interpret-trailers(1)
    locator:   "DESCRIPTION; trailer syntax"
    external:  true
  - title:     Developer Certificate of Origin, version 1.1
    locator:   "Signed-off-by trailer"
    external:  true
  - title:     Operator Memory injected preamble and tenets
    locator:   "packages/core/src/prompts/preamble.ts@e394f1c"
    external:  true
  - title:     Operator Memory OpenCode V2 adapter
    locator:   "packages/opencode-v2/src/index.ts@e394f1c"
    external:  true
decisions:
  - COMPASS-DRAFT-agent-workflow-D1
  - COMPASS-DRAFT-agent-workflow-D2
  - COMPASS-DRAFT-agent-workflow-D3
  - COMPASS-DRAFT-agent-workflow-D4
  - COMPASS-DRAFT-agent-workflow-D5
  - COMPASS-DRAFT-agent-workflow-D6
  - COMPASS-DRAFT-agent-workflow-D7
  - COMPASS-DRAFT-agent-workflow-D8
  - COMPASS-DRAFT-agent-workflow-D9
  - COMPASS-DRAFT-agent-workflow-D10
  - COMPASS-DRAFT-agent-workflow-D11
open-questions:
  - COMPASS-DRAFT-agent-workflow-O1
  - COMPASS-DRAFT-agent-workflow-O2
  - COMPASS-DRAFT-agent-workflow-O3
  - COMPASS-DRAFT-agent-workflow-O4
---

# Compass Agent Workflow: Development Plan

This plan covers how coding agents work *within* a Compass corpus: where they
record durable knowledge, what they may change and who must approve it, how
their assistance is recorded, and the loop that keeps the corpus current as code
changes. It resolves open questions O4 and O5 of
[COMPASS-DRAFT-operator-memory](Survey.OperatorMemory.md) and carries O6 forward.
It is the authoring-assistance (S9) counterpart of the agent-context outputs in
[COMPASS-DRAFT-toolchain](Plan.Toolchain.md) (COMPASS-DRAFT-toolchain-D10 to
COMPASS-DRAFT-toolchain-D15), which generate the session catalog and source map
that this plan's adapter delivers. It extends
[COMPASS-DRAFT-authoring-assistance](Plan.AuthoringAssistance.md) and uses the
source headers of [COMPASS-DRAFT-source-headers](Spec.SourceHeaders.md). Every
change it proposes to [COMPASS-0001](../Compass.md) is listed under
[Amendments to the standard](#amendments-to-the-standard) and lands only by
accepted amendment (§13).

## Problem

The Operator Memory survey resolved to import the useful parts of Operator
Memory rather than run it alongside Compass (COMPASS-DRAFT-toolchain-D10). Three
of Operator Memory's functions then need a home inside Compass.

- **Durable working knowledge has nowhere to go.** Agents and developers learn
  facts that are consequential but do not merit a full document: a property a
  subsystem relies on, a library's surprising behaviour, a constraint found by
  debugging. §2 classes this material as "disposable scratch", yet much of it is
  neither. Without a home it is lost at the end of each session, or it leaks into
  documents of the wrong genre.
- **The review rule cannot be satisfied by a solo maintainer.** §6 says that for
  project- and program-scope documents "the approver MUST NOT be the sole
  author." Every document in this repository has one human author. As written,
  none of them can ever be accepted.
- **Agent edits have no defined authority or record.** Nothing says what an agent
  may change without a human, what counts as a substantive edit, or how per-edit
  assistance is recorded. `provenance:` records how a document began, not who
  helped revise it (COMPASS-O3, §23 P2).
- **Nothing drives the update half of the loop.** Operator Memory's protocol is
  *consult → build → update*. Compass's maturity ladder implies the same loop,
  but no skill or instruction carries it out. `compass-author` creates documents
  and does not maintain existing ones.

The survey also warns that ceremony suppresses updates: agents already prefer
the status quo, and Compass's heavier requirements may make them less willing
still. Every decision below is weighed against that risk.

## Goals

- Give durable, consequential, non-obvious system knowledge a typed, citable,
  low-ceremony home: the **Memo** genre.
- Keep a human in the loop for every significant change, while letting a solo
  maintainer accept their own documents explicitly.
- Separate *review of a change* from *acceptance into authority*, so that drafts
  are cheap and authority is deliberate.
- Record per-edit assistance without hand-maintained fields.
- Define a maintenance skill and protocol that propose the corpus updates a code
  change implies, and propose nothing else.
- Deliver the session catalog to the agent, and fail loudly when it cannot.

## Settled Decisions

This Plan was accepted on 2026-10-07 by its solo steward (D6). Decisions D1–D6
were accepted with it, and their amendments to COMPASS-0001 have landed (see
[Amendments to the standard](#amendments-to-the-standard)). D11, which amends
the catalog rule of D4, was accepted by the steward on 2026-10-08. D7–D10
remain **Proposed** until accepted individually.

### COMPASS-DRAFT-agent-workflow-D1 — A Memo genre for durable system knowledge

**Status:** Accepted

**Context:** COMPASS-DRAFT-operator-memory-O4 asked where durable but
unpublished knowledge belongs. The answer settled with the maintainer: a genre
for items likely to be useful in future work, such as system properties whose
understanding is key to the system's function, and explicitly not a scratchpad.
The §4 normativity grid has an empty cell, *existing system, non-normative*:
`Ref` and `Spec` describe running software normatively, and nothing records
how it is observed to behave.

**Decision:** Add an eleventh genre, **Memo** (prefix `Memo.`, code `ME`). A
Memo document records verified, present-tense properties of existing software
that matter for working on it. It fills the empty grid cell. A Compass memo
records a lasting property of a system; it is not a dated message to a reader.
The name follows the RFC series, in which every RFC calls itself a memo, and
its Latin root, *memorandum*, "a thing to be remembered". §2's "disposable
scratch" non-goal stays, with a clarification that durable findings belong in a
Memo. A second clarification separates memos (engineering facts for developers
and agents) from the knowledge-base and FAQ non-goal. Amends §2 (patch) and §4
(minor).

**Alternatives:**
- `Note`. Rejected: it reads as a scratchpad, the use this genre must avoid.
- `Finding`. Rejected: it suggests a review result or an audit item.
- No genre, using Operator Memory's private partition. Rejected by the survey's
  O1 resolution (import, do not run alongside).
- A `Ref` subtype. Rejected: a `Ref` is normative and comprehensive, whereas a
  memo is a single observed fact that may later be folded into a `Ref`.

### COMPASS-DRAFT-agent-workflow-D2 — Memos are numbered records in a host document

**Status:** Accepted

**Context:** A memo is often a few sentences long. One file per memo would
proliferate files and make §7 front-matter longer than the content. Several
memos per file reduces both costs, but only if each memo keeps its own
identity, status, routing, catalog entry, retrieval, and supersession. Compass
already has a pattern for that: `D`- and `O`-records are numbered entries
inside a host document (§8).

**Decision:** Memos are a third kind of register entry, the **M-record**,
identified `<NS>-M<n>`. They follow the D-record shape and the rules of §8:
- **Host.** M-records appear only in Memo documents, and a Memo document holds
  only M-records. A host is named `Memo.<Topic>.md` and is normally one per
  component. Its front-matter lists its records in a new `memos:` field, mirrored
  against the body.
- **Record.** Each record has a heading `### <ID> — <the property, as a claim>`,
  a fixed set of bold-label fields, and a short body. See
  [The Memo genre](#the-memo-genre).
- **Provisional identifiers.** A record in an unassigned host is
  `<NS>-DRAFT-<slug>-M<n>`, as COMPASS-DRAFT-toolchain-D2 defines for `D` and
  `O`. `compass assign` gives it a canonical `<NS>-M<n>`, and the ledger records
  it as `:kind :memo`.
- **Never deleted.** A retired record stays in place with its status changed, and
  its number is never reused (§13).

Amends §7 (minor: the `memos:` field), §8 (minor: the third register), and §13.

**Alternatives:**
- One memo per file, as an ordinary document. Rejected: front-matter overhead
  per memo, and file proliferation. It remains the right form for a memo that
  grows large, by superseding it with a document.
- Several memos per file as untyped sections. Rejected: memos would lose
  individual identity, status, weight, routing, and supersession.
- Allow M-records in any genre, as D-records are. Rejected for v1: keeping memos
  in one genre keeps them findable and gives the genre its purpose.

### COMPASS-DRAFT-agent-workflow-D3 — Four admission tests, and a mandatory basis

**Status:** Accepted

**Context:** The value of the genre depends on keeping it from becoming the
scratchpad the maintainer ruled out. An unverified memo is worse than none,
because it carries authority it has not earned.

**Decision:** A memo is admitted only if it passes all four tests:
1. **Durable.** It should remain true for the expected life of the code it
   concerns, not just for one session or one branch.
2. **Consequential.** Misunderstanding it leads to wrong code or wasted work.
3. **Not evident.** It cannot be read from the code, a source header, or an
   existing document.
4. **Grounded.** It states how it is known, in a form a reader could check.

Test 4 is enforced: the `**Basis:**` field MUST contain at least one
commit-pinned code reference (§9), a Compass identifier, or the title of an
entry in the host's `cites:`. Tests 1–3 are judgment; `compass-review` and the
maintenance skill (D9) apply them, and the maintenance skill states which test
each proposed memo passes and why.

**Alternatives:**
- No admission bar. Rejected: it produces the scratchpad.
- Require review before a memo may be recorded at all. Rejected: it suppresses
  capture. The acceptance gate (D5) controls authority instead.

### COMPASS-DRAFT-agent-workflow-D4 — Memo status and authority weight

**Status:** Accepted

**Context:** The weight function of COMPASS-DRAFT-toolchain-D12 needs status
values for the host and its records. Memos describe running software, so the
reference-genre statuses fit, with the addition of supersession.

**Decision:**
- **Record status:** `Draft` (recorded, not yet accepted), `Current` (accepted,
  and still holds), `Deprecated` (no longer true or relevant), or `Superseded`
  (replaced; `**Superseded-by:**` names the successor, which may be another
  M-record or a whole document such as a `Ref`).
- **Host status:** the same four values. A host is `Current` while it is
  maintained, regardless of how many of its records are drafts.
- **Weight:** a `Current` M-record is **Authoritative**, since it states a
  verified present fact about running code. A `Draft` record is Provisional, and
  `Deprecated` and `Superseded` records are Excluded. The host caps its records
  as for D-records: a `Draft` host makes every record at most Provisional, and a
  retired host makes them Excluded.
- **Catalog:** each Authoritative memo gets one line in the session catalog,
  with its `read-if:`. The host itself is not listed as a document. *Amended by
  D11:* Provisional memos are listed too, in a separate section marked
  unreviewed.

Amends §6 (minor).

**Alternatives:**
- Weight a `Current` memo as Directive. Rejected: a memo is non-normative, but
  it is a verified fact about the code, which is what Authoritative means in D12.
- A status only on the host. Rejected: memos in one host are recorded, verified,
  and retired independently.

### COMPASS-DRAFT-agent-workflow-D5 — Three review gates

**Status:** Accepted

**Context:** COMPASS-DRAFT-operator-memory-O5 settled that changes to project-
and program-scope documents are always reviewed by a human. Applied literally to
every edit, that rule makes bulk mechanical rewrites (`compass assign`,
`compass renumber`, link repair after supersession) as costly to review as
design changes. It also invites review fatigue, which ends in rubber-stamping.
"Review" covers three different acts that need different rules.

**Decision:** Three gates:
1. **The change gate.** A change to a project- or program-scope document reaches
   the main branch only in a commit made by a human, or through a pull request a
   human approves. An agent never makes the final commit to the main branch by
   itself. Branch protection (COMPASS-DRAFT-toolchain-D1) enforces this. For
   component-scope documents the gate is RECOMMENDED.
2. **The acceptance gate.** A transition into an authoritative status
   (`Accepted`, `Design-Record`, `Current`, including a memo's `Current`)
   requires a human `approved-by` at any scope (D6). An agent never sets
   `approved-by` or `reviewers`.
3. **Mechanical changes.** A change consisting only of identifier rewrites,
   link-target updates, supersession mirroring, and regenerated outputs passes
   the change gate without reopening acceptance. `compass diff` classifies each
   changed document as mechanical or substantive, so the reviewer can focus on
   the substantive ones.

A substantive edit to an accepted document passes through the change gate and
keeps its status; the human who approves the change is reviewing it. Amends §6
(minor).

**Alternatives:**
- One undifferentiated review requirement. Rejected for the cost and fatigue
  reasons above.
- Let agents commit drafts directly to the main branch. Rejected: contrary to the
  maintainer's practice of keeping humans in the loop for significant changes.

### COMPASS-DRAFT-agent-workflow-D6 — Solo stewards may approve their own documents

**Status:** Accepted

**Context:** §6 forbids the sole author from approving project- and
program-scope documents. For a namespace with one maintainer this is not
impractical but impossible. Of the two options considered, the maintainer chose
an explicit solo-steward declaration (option a) over counting the human
reviewer of an agent's draft as the second pair of eyes (option b).

**Decision:** The project manifest declares each namespace's steward, and may
mark the namespace's approval mode as solo (COMPASS-DRAFT-toolchain-D15). In a
solo namespace the steward MAY be the `approved-by` of a document they also
authored. The rule `review/approver` enforces:
- `approved-by` is never an assistant: not the `provenance: assistant`, and not
  a tool named in an `Assisted-by:` trailer (D7);
- in a namespace without solo approval, `approved-by` is not the sole author;
- self-approval occurs only by the declared steward of a solo namespace.

The declaration is visible and reversible: when a second maintainer joins, the
mode is changed and the normal rule resumes for new acceptances. Amends §6
(minor).

**Alternatives:**
- (b) The human reviewer of agent-drafted content counts as the second reviewer.
  Rejected: it quietly counts the LLM as the first pair of eyes.
- Waive review for solo namespaces. Rejected: `approved-by` still records a
  deliberate act of acceptance, which the weight function depends on.

### COMPASS-DRAFT-agent-workflow-D7 — Per-edit assistance is recorded in commit trailers

**Status:** Proposed

**Context:** `provenance:` (§7) records the assisted origin of a document.
Recording every later assisted edit in front-matter would be hand-maintained and
would drift, the problem §7 already solved for `authors` and dates by deriving
them from Git. COMPASS-O3 and §23 P2 ask what granularity to record.

**Decision:** An assisted commit carries a Git trailer:

```text
Assisted-by: opencode (claude-opus-5-5)
```

The form is `<tool> (<model>)`, with the model optional. Skills and adapters add
the trailer to commits they prepare, and the human committing keeps it. The
toolchain derives each document's assistance history from the trailers on the
commits that touched it, as it derives `authors` (§7), and `compass show`
reports it. `provenance:` keeps its meaning: the assisted origin of the
document. Per-section attribution is not recorded. Amends §7 (minor); partly
resolves COMPASS-O3.

**Alternatives:**
- A `provenance:` list updated on every edit. Rejected: hand-maintained, drifts,
  and creates merge conflicts.
- `Co-authored-by:`. Rejected: it credits an author, which an assistant is not,
  and forges display it as a person.

### COMPASS-DRAFT-agent-workflow-D8 — What an agent may do, by scope

**Status:** Proposed

**Context:** D5 and D6 define the gates. Agents and skills need the result
stated as permissions they can follow.

**Decision:** Adopt the permission table under
[Agent permissions](#agent-permissions) as the normative rule for skills and
adapters. Its principle: agents **propose**; humans **commit and accept**; the
toolchain **checks** (§22).

**Alternatives:** Leave permissions implicit in §6. Rejected: an agent cannot
reliably derive "may I edit this?" from a review rule.

### COMPASS-DRAFT-agent-workflow-D9 — A maintenance skill and the consult → build → update protocol

**Status:** Proposed

**Context:** Operator Memory's protocol tells the agent to consult before
building and update after, but nothing checks that updates happen; its roadmap
still lists "Reliable Brain Updates" as unbuilt. Compass needs both the
instruction and a skill that does the update work, without flooding the human
with proposals.

**Decision:**
- **Protocol text.** A short protocol, given under
  [The maintenance loop](#the-maintenance-loop), is placed in the session
  catalog's preamble (COMPASS-DRAFT-toolchain-D11) and in
  `templates/AGENTS.snippet.md`.
- **A fifth skill, `compass-maintain`.** Given a change (a diff or a commit
  range), it proposes the corpus updates the change implies: corrections to
  Authoritative claims the change made false, source-header updates, a `Log`
  entry where the change is significant, and memos that pass D3. Amends
  COMPASS-D1, which fixed four skills.
- **Proposal bar.** It proposes an edit only when a claim has become false or a
  D3 memo has been established. It does not propose style changes.
- **Same change.** Its proposals go into the same commit or pull request as the
  code they describe, so the human reviews once.
- **Never accepts.** It writes new memos as `Draft` and never changes a status
  into an authoritative one (D5).

**Alternatives:**
- Extend `compass-author`. Rejected: creating and maintaining are different
  triggers, and `compass-author`'s contract is scaffolding.
- A post-commit hook that checks whether documentation was updated. Rejected for
  v1: it cannot tell which updates a change needs; that judgment is the skill's.

### COMPASS-DRAFT-agent-workflow-D10 — The session adapter delivers the catalog and fails loudly

**Status:** Proposed

**Context:** The toolchain commits `doc/CATALOG.md` (COMPASS-DRAFT-toolchain-D10)
so that an adapter can deliver it without Lisp. Operator Memory's OpenCode
adapter injects its preamble through a session `context` hook, caches it per
session, and replaces it with a diagnostic if any part fails to load.

**Decision:** The OpenCode adapter is a plugin that, at session start:
1. reads `doc/CATALOG.md` (the document directory comes from `compass.sexp`);
2. injects it into the system context, cached for the session;
3. if the catalog is missing or unreadable, injects a short diagnostic instead,
   telling the agent that the corpus is unverified and how to regenerate the
   catalog. It does not silently proceed with no context;
4. if the catalog's input digest shows it is stale, behaves as
   COMPASS-DRAFT-toolchain-O7 decides.

It never writes files. Adapters for other harnesses follow the same contract
(§23 S9).

**Alternatives:**
- Have the adapter run `compass catalog` itself. Rejected for the reasons in
  COMPASS-DRAFT-toolchain-D10: every session would need the toolchain binary,
  and session start would wait on Git.
- Refuse to load anything if one input fails, as Operator Memory does. Adopted in
  spirit: the catalog is one generated file, so "fails to load" means the whole
  catalog, and the diagnostic replaces it.

### COMPASS-DRAFT-agent-workflow-D11 — Unreviewed memos are listed in the catalog

**Status:** Accepted

**Context:** Memos exist so that agents can store what they learn for later
sessions, and agents may write them freely at any scope (D3, D8). Under D4 and
D5 as accepted, however, an agent's memo stays `Draft` until a person moves it
to `Current`, a `Draft` memo weighs as Provisional, and only Authoritative
memos reach the session catalog. Machine-authored memos were therefore stored
but invisible to the next session until reviewed, which defeated their purpose.
Letting agents set `Current` themselves was considered and rejected below.

**Decision:** Amends the catalog rule of D4. The session catalog lists memos in
two sections:
- **Memos:** M-records of weight Authoritative (status `Current`, accepted by a
  person), as before;
- **Unreviewed memos:** M-records of weight Provisional (status `Draft`), each
  with its id, title, and `**Read-if:**` line, under a heading that marks them
  as recorded but not yet reviewed.

Nothing else changes. Memos are written as `Draft`, by agents or people, with
no review needed to record them. A `Draft` memo's `**Basis:**` is still
required and checked (D3), so every unreviewed memo can be verified by the
agent that reads it. Moving a memo to `Current` still passes the acceptance
gate (D5): a person approves it, and the host's `approved-by` and `reviewed`
record the latest acceptance. The maintenance-loop text tells agents to treat
unreviewed memos as leads to verify against their basis, never as present
truth.

Two limits keep unreviewed text from crowding out or masquerading as reviewed
knowledge, which the injection concerns of
[COMPASS-DRAFT-secure-development](Survey.SecureDevelopment.md) call for:
- unreviewed memos come after every Authoritative, Directive, and Contextual
  entry, so they are the first entries dropped when the catalog exceeds its
  budget (COMPASS-DRAFT-toolchain-D11);
- the catalog shows only their title and `Read-if` line, both length-limited,
  never their body.

**Alternatives:**
- Keep D4 unchanged: unreviewed memos stay out of the catalog until a person
  accepts them. Rejected: machine-authored memos would wait unseen for review,
  and the point of the genre is that later sessions find them.
- Exempt memos from the acceptance gate, so that agents may set `Current` and
  their memos weigh as Authoritative. Rejected: an agent's mistaken memo would
  become present truth for every later session, and the distinction between
  what an agent observed and what a person verified, which the weight function
  exists to draw, would be lost.

## The Memo genre

### Host document shape

A host document opens with ordinary §7 front-matter and holds its records under
a single `## Memos` section, in identifier order. The template shape, now
`templates/Memo.template.md`:

```markdown
---
id:            <NAMESPACE>-DRAFT-<slug>
title:         <Component> Memos
genre:         Memo
scope:         component            # component | project | program
project:       <project>
component:     <component>
language:      en
status:        Current              # Current | Draft | Deprecated | Superseded
provenance:
  assistant:   <assistant>
memos:
  - <NAMESPACE>-DRAFT-<slug>-M1
---

# <Component>: Memos

<One paragraph: the system or component these memos concern, and where its
normative documentation lives (link the Ref/Spec by id).>

## Memos

### <NAMESPACE>-DRAFT-<slug>-M1 — <The property, stated as a claim>

**Status:** Draft
**Read-if:** <the task or situation in which this matters>
**Basis:** <commit-pinned reference, Compass id, or cites title>; <how established>
**Recorded:** <YYYY-MM-DD>           <!-- optional -->
**Superseded-by:** <id>              <!-- only with status Superseded -->

<The property in the present tense, then what it implies for someone changing
the system. Keep it under about 200 words.>
```

### Record fields

Table: M-record fields.

| Field | Required | Value |
|---|---|---|
| `**Status:**` | yes | `Draft`, `Current`, `Deprecated`, or `Superseded` (D4) |
| `**Read-if:**` | yes | A condition, within 160 characters; the routing line the catalog shows |
| `**Basis:**` | yes | At least one commit-pinned code reference, Compass identifier, or `cites:` title, then how the property was established (D3) |
| `**Recorded:**` | no | The date the memo was recorded. Git cannot supply a per-record date |
| `**Superseded-by:**` | with `Superseded` | The successor's identifier; required with, and only with, that status |

### Example

```markdown
### CLASSIC-M3 — Federation outbox delivery is at-least-once

**Status:** Current
**Read-if:** writing a federation receiver, or changing outbox flush or retry
**Basis:** `mod/classic.engine.ref/federation/delivery.lisp:receive@<sha>`; duplicate delivery reproduced after a forced retry

A batch can be delivered more than once after a timeout. Receivers must be
idempotent; the stale-content check in `delivery.lisp` is the current guard.
```

The identifier and evidence are illustrative.

### Where a memo ends and other forms begin

Table: Choosing between a memo and the neighbouring forms.

| The knowledge is… | Record it as |
|---|---|
| A rule about one file's code | An `Invariant:` in that file's source header |
| A property spanning files or components, observed in running code | A memo |
| A choice between alternatives, with rationale | A `D`-record |
| A known gap or unresolved issue | An `O`-record |
| A comprehensive, normative description of a component | A `Ref` or `Spec`; fold the component's memos into it and mark them `Superseded` |
| Relevant only to the current session or branch | Nothing; it is disposable scratch (§2) |

A source header can point at a memo with `See:`, so a file-level invariant can
link to the system-level property behind it.

## Review and authority

### Agent permissions

Table: What an agent may do, by action and document scope (D8).

| Action | Component scope | Project or program scope |
|---|---|---|
| Create a document or memo with status `Draft` | Yes | Yes |
| Edit a `Draft` document | Yes | Yes |
| Propose edits to an authoritative document | Yes | Yes |
| Run `compass assign`, `renumber`, `index`, `catalog`, `map` | Yes | Yes |
| Commit to a working branch | Yes | Yes |
| Make the final commit to the main branch | Discouraged (D5, RECOMMENDED gate) | No |
| Change a status into an authoritative one | No | No |
| Set `approved-by` or `reviewers` | No | No |
| Edit the ledger by hand | No | No |

In short, agents may draft, edit drafts, propose edits, and run the toolchain at
any scope. They never accept a document, record an approval, edit the ledger by
hand, or land a project- or program-scope change on the main branch without a
human.

### Acceptance in a solo namespace

A manifest declaring a solo steward (COMPASS-DRAFT-toolchain-D15):

```lisp
:stewards ((:namespace "COMPASS" :steward "Andrew Sengul" :approval :solo))
```

With this declaration, Andrew Sengul may set `approved-by: Andrew Sengul` on a
document he authored. Without it, or with `:approval :second-reviewer`, the §6
rule applies unchanged.

## The maintenance loop

The protocol text placed in the catalog preamble and the AGENTS snippet:

```text
Before you build: read the catalog. Open the Authoritative documents, decisions,
and memos whose Read-if matches your task, and the source-map entries for the
files you will touch. Prefer `compass show ID#anchor` to reading whole files.

While you build: treat Authoritative entries as present truth. If the code
disagrees with one, raise it; do not silently follow either. Treat unreviewed
memos as leads: check one against its Basis before relying on it.

After you build: run compass-maintain on your change. Include its proposals in
the same change: corrections to claims your change made false, source-header
updates, a Log entry if the change is significant, and Draft memos for durable
facts you established. Do not restate what the code shows. Never set an
authoritative status or approved-by; a human does that.
```

The text is short by design; the session catalog's budget
(COMPASS-DRAFT-toolchain-D11) covers it.

`compass-maintain` works through a change in this order:

1. List the files changed, and through their source headers the documents,
   decisions, and memos they cite (`See:`) and the invariants they declare.
2. For each Authoritative claim in those targets, decide whether the change has
   made it false. Propose a correction for each one that has.
3. For each changed file, check that its header's summary, `Read-if`,
   `Invariant`, `Tests`, and `Co-change` still hold. Propose updates.
4. If the change is significant (a new capability, a fixed defect with a lesson,
   a changed contract), propose a `Log` or an `## Update` section to an existing
   one.
5. For each durable fact established during the work, apply the D3 tests and
   propose a `Draft` memo in the component's host, creating the host if needed.
6. Report what it proposes, with the reason for each item, for the human to
   accept or discard.

## Amendments to the standard

Table: Changes to COMPASS-0001 that this plan proposes, with amendment class
under §13.

| Section | Change | Class | Decision |
|---|---|---|---|
| §2 | Durable findings belong in a Memo; memos are not knowledge-base content | patch | D1 |
| §4 | Eleventh genre `Memo` (`Memo.`, `ME`); fills the existing/non-normative grid cell | minor | D1 |
| §6 | Memo status vocabulary; three review gates; solo-steward approval | minor | D4, D5, D6 |
| §7 | `memos:` field; `Assisted-by:` trailer as a derived field | minor | D2, D7 |
| §8 | M-records as a third register | minor | D2 |
| §13 | M-records in provisional and canonical allocation | minor | D2 |
| §14 | Memo section shape | minor | D2 |

**Status (2026-10-07):** the rows for D1–D6 have landed in COMPASS-0001, as a
minor amendment under §13. COMPASS-0001 does not yet record a version number;
it gains one with its front-matter (COMPASS-DRAFT-toolchain-D9). The
`Assisted-by:` half of the §7 row waits on D7. `skills/reference/vocabularies.md`, the `compass-author` genre list, and
`templates/Memo.template.md` now offer the Memo genre.

The identifier grammar for M-records follows the D- and O-records. Their
provisional form (`<NS>-DRAFT-<slug>-M<n>`) is the one
COMPASS-DRAFT-toolchain-D2 proposes for all three registers; §13 adopts it for
M-records now, and for D- and O-records when that decision is accepted.

**Open detail:** an M-record has no `approved-by` of its own. Until the
toolchain plan settles it, a record's move to `Current` is approved by the
human who approves the change (D5), and the host's `approved-by` and `reviewed`
record the most recent acceptance.

## Open Questions

### COMPASS-DRAFT-agent-workflow-O1 — Measuring whether the workflow helps

Carried forward from COMPASS-DRAFT-operator-memory-O6. Neither Compass nor
Operator Memory has evaluated agent behaviour. The maintainer favours a
documented, repeatable test committed to the Compass repository. What tasks,
fixture repositories, and measures would it use: for example, exploration cost,
consultation of decisions and memos, correctness with respect to superseded
documents, and whether `compass-maintain`'s proposals were accurate and
accepted?

**Status (2026-10-07):** Open, with a protocol in
[COMPASS-DRAFT-agent-context-eval](Eval.AgentContext.md). It is an `Eval` with
a harness, run on a snapshot of Classic. Its primary track is a relay of real
development steps from Classic's history, comparing one long session, fresh
sessions with no context, fresh sessions with untyped agent-maintained notes,
and fresh sessions with the full Compass stack; it measures quality and ethos
conformance over time. A secondary track repeats the snapshot design of the
2026 context-file studies (Gloaguen et al.; Khatri), which found no gain in
task success from context files. This question is resolved when that
evaluation's Synthesis is written.

### COMPASS-DRAFT-agent-workflow-O2 — Host granularity

D2 suggests one host per component. A busy component may accumulate many
memos, and two branches appending to one host conflict textually (resolvable,
since draft identifiers do not collide). When should a host be split by topic,
and should the toolchain warn above a record count or size?

### COMPASS-DRAFT-agent-workflow-O3 — Trust in `Assisted-by:` trailers

Trailers are self-declared. A human may drop one, and a tool may omit it. Should
a commit-message hook add the trailer automatically when a skill prepared the
change? Should the validator warn when a document's `provenance:` names an
assistant but no commit touching it carries a trailer?

### COMPASS-DRAFT-agent-workflow-O4 — Adapters beyond OpenCode

D10 specifies the OpenCode adapter. Claude Code hooks, Cursor rules, and MCP
resources can carry the same catalog, with different caching and size limits.
Which come next, and does the catalog need per-harness budgets?

## Prior Art

Table: Prior systems and what this plan draws from each.

| System | What to draw from |
|---|---|
| Operator Memory | Consult → build → update; session-start injection with a load diagnostic; the observation that agents resist updating. Its agent self-approval and present-tense rewriting are not adopted |
| IETF RFC series | Every RFC calls itself a memo ("Status of This Memo"); the source of the genre's name |
| ADR / MADR | Numbered, individually addressable records in a host document, as `D`-records already are (§8) |
| Git trailers (`Signed-off-by`, DCO) | Per-commit attestations parsed by tools; the model for `Assisted-by:` |
| GitHub branch protection, `CODEOWNERS` | Mechanical enforcement of the change gate (COMPASS-DRAFT-toolchain-D1) |
| Django migrations `--check`, renumbering | Bulk mechanical changes that are reviewed as such rather than as design changes |

## Roadmap

1. **This Plan.** Record the decisions. No change to `Compass.md` yet.
2. **Amendment.** A minor amendment to COMPASS-0001 carrying the table under
   [Amendments to the standard](#amendments-to-the-standard).
3. **Toolchain support** (COMPASS-DRAFT-toolchain roadmap step 6): M-records,
   memo rules, `review/approver`, the `:stewards` manifest key, `compass diff`,
   and trailer derivation.
4. **Templates and skills.** `templates/Memo.template.md`; the Memo genre in
   `skills/reference/vocabularies.md` and `compass-author`; the D3 tests and
   memo checks in `compass-review`.
5. **Maintenance.** The `compass-maintain` skill; the protocol text in the AGENTS
   snippet and the catalog preamble.
6. **Evaluation pilot.** Run the pilot of
   [COMPASS-DRAFT-agent-context-eval](Eval.AgentContext.md). The session
   adapter, and the catalog it delivers, are built only after it, subject to its
   decision rules.
7. **Delivery.** The OpenCode session adapter (D10).
8. **Full evaluation.** Complete the study and resolve O1.
