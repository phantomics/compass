---
id:            COMPASS-DRAFT-secure-development
title:         Compass and Secure Development in the Age of Coding Agents
genre:         Survey
scope:         program
program:       Compass
component:     security
language:      en
status:        Draft
authors:
  - Sloane
provenance:
  assistant:   opencode
relates-to:
  - COMPASS-0001
  - COMPASS-DRAFT-toolchain
  - COMPASS-DRAFT-source-headers
  - COMPASS-DRAFT-agent-workflow
  - COMPASS-DRAFT-agent-context-eval
  - COMPASS-DRAFT-operator-memory
cites:
  - title:     "RFC 3552 (BCP 72) — Guidelines for Writing RFC Text on Security Considerations"
    locator:   "§5, Writing Security Considerations Sections"
    external:  true
  - title:     "NIST SP 800-218 — Secure Software Development Framework (SSDF) Version 1.1"
    locator:   "Practices PO.1, PW.1, PW.2, PW.7, PS.3, RV.1"
    external:  true
  - title:     "NIST SP 800-218 Rev. 1 (draft) — SSDF Version 1.2"
    locator:   "Preliminary update, 2025-12-17; new practices PO.6 and PS.4"
    external:  true
  - title:     "NIST SP 800-218A — Secure Software Development Practices for Generative AI and Dual-Use Foundation Models"
    locator:   "Table 1, SSDF Community Profile"
    external:  true
  - title:     OWASP Software Assurance Maturity Model (SAMM) v2
    locator:   "Design: Threat Assessment; Verification: Requirements-driven Testing"
    external:  true
  - title:     Threat Modeling Manifesto
    locator:   "The four questions; values and principles"
    external:  true
  - title:     "OWASP Top 10 for LLM Applications"
    locator:   "LLM01 Prompt Injection"
    external:  true
  - title:     "SLSA — Supply-chain Levels for Software Artifacts, v1.0"
    locator:   "Build track"
    external:  true
  - title:     "Regulation (EU) 2024/2847 — Cyber Resilience Act"
    locator:   "Annex VII, technical documentation"
    external:  true
  - title:     Operator Memory repository (aerovato/operator-memory)
    locator:   "docs/troubleshooting.md (index linter, private-path leaks)@e394f1c"
    external:  true
open-questions:
  - COMPASS-DRAFT-secure-development-O1
  - COMPASS-DRAFT-secure-development-O2
  - COMPASS-DRAFT-secure-development-O3
  - COMPASS-DRAFT-secure-development-O4
  - COMPASS-DRAFT-secure-development-O5
  - COMPASS-DRAFT-secure-development-O6
---

# Compass and Secure Development: Survey

This survey asks how Compass's conventions can support secure software
development, from a project's earliest design work onward, and how they can do
so for coding agents as well as people. It also asks the reverse question: what
new risks Compass creates once its corpus is delivered into agents' context. It
builds on the content model of [COMPASS-0001](../Compass.md), the toolchain of
[COMPASS-DRAFT-toolchain](Plan.Toolchain.md), the source headers of
[COMPASS-DRAFT-source-headers](Spec.SourceHeaders.md), and the agent workflow of
[COMPASS-DRAFT-agent-workflow](Plan.AgentWorkflow.md). Like any Survey it is
exploratory and non-normative; each candidate it recommends would arrive as a
Plan decision or an amendment (§13).

## Motivation

Coding agents now write a large share of new code, and the security dialogue
around them is urgent. Two concerns dominate. Agents reproduce insecure
patterns and silently drop constraints they were never told about, or were told
about many turns ago. And the instructions and context fed to agents have become
an attack surface of their own.

Secure-development frameworks agree on what a project must do. NIST's SSDF asks
producers to define security requirements (PO.1), design software to meet them
and mitigate risks (PW.1), review the design against them (PW.2), and keep
evidence of all of it. Its generative-AI profile (SP 800-218A) adds traceability
for AI involvement. OWASP SAMM and the Threat Modeling Manifesto describe how to
assess threats during design. What none of them prescribes is how to keep that
documentation **current**, how to **link** it to the code it governs, or how to
put it in front of whoever is changing that code at the moment they change it.
Those are the problems Compass already exists to solve for design knowledge in
general.

### A worked gap: Classic's security analysis

Classic contains a careful security analysis,
`CLASSIC:securityPoints.md@6e4f02d`, written alongside the theme model in
`d20ec8c`. In 104 lines it records:
- what exists (role-based permissions through `account-has-permission-p`,
  role-checked workflow transitions through `attempt-transition`);
- six unaddressed areas: authentication, authorisation beyond roles, input
  validation and sanitisation, federation security, multi-tenant isolation, and
  audit logging;
- a priority ranking and an implementation approach.

It is exactly the early security thinking every framework asks for. Yet it sits
at the repository root with no identifier, no status, no genre, and no
individually addressable items. None of its gaps can be cited, tracked to
resolution, linked from `receive-from-peer` (which, it notes, "accepts anything
from any registered peer"), or shown to an agent working on federation. When the
gaps are closed, nothing will mark the document as superseded. The knowledge is
present; its form keeps it from doing work.

## What Compass can and cannot claim

Compass is not a security tool. It does not scan, fuzz, sign, attest, or
detect, and §2 already declines to be a compliance system of record. It can
honestly claim three contributions:

1. **Keeping security knowledge alive**: typed, citable, carrying a status, and
   linked from design through code to tests.
2. **Delivering it to the point of change**, for agents and people alike.
3. **Not becoming an attack surface itself**, which decides whether a tool that
   injects text into agents' context is credible at all.

## Security from the design phase

Most of what is needed uses machinery Compass already has or has planned.

Table: Secure-design practices and their Compass forms.

| Practice | Compass form | Status |
|---|---|---|
| Security considered in every design | A required `## Security Considerations` section in `Plan`, `Arch`, and `Spec`, checked by `shape/sections`. "None" is acceptable only with a stated reason. A `Log` may discuss security where a change affects it, but no section is required | New: patch to §14, modelled on RFC 3552 |
| Threat model | An `Eval` with the new subtype `threat-model` | New: minor amendment to §4 |
| Threats tracked to resolution | An unmitigated threat is an `O`-record. A mitigation or an accepted risk is a `D`-record, whose Alternatives record what was rejected and why. A threat found not to apply is closed in prose | Existing registers |
| Security properties of running code | Memos, such as "the codec never evaluates input" or "federation receivers must be idempotent" | Planned (COMPASS-DRAFT-agent-workflow-D1) |
| File-level trust boundaries | Source header `Concerns: security-boundary`, `Invariant:` lines, `See:` to the decisions behind them, `Tests:` to the negative tests | Specified (COMPASS-DRAFT-source-headers) |
| Outdated security guidance stays out of use | A superseded security decision has weight Excluded, so agents follow its successor | Planned (COMPASS-DRAFT-toolchain-D12) |
| Claims a reviewer can verify | "The check lives here" pinned to a commit | Existing (§9) |

Together these give one chain of identifiers from design to verification:

```text
threat (O-record) → mitigation (D-record) → code (See:, Invariant:)
                  → tests (Tests:) → observed property (memo)
```

Description: an unmitigated threat is an open-question record; its resolution
is a decision record; source files cite the decision and state the invariant it
imposes; their headers name the tests that check it; and a memo may record the
property as observed in running code.

This is linking, not a requirements register. §2 keeps requirements
specification and traceability matrices (IEEE 29148) out of scope, and this
chain does not reintroduce them: it records why the code is as it is, not
whether every requirement is met.

### Security Considerations sections

RFC 3552 (BCP 72) requires every RFC to carry a Security Considerations section
and asks authors to state what is in scope, which attacks are considered, and
what residual risk remains. A section that says only "none" is not acceptable
without a reason. The same rule suits Compass's design genres. A sketch of the
section's expected content:

- the assets and trust boundaries the design touches;
- the threats considered, citing the threat-model `Eval` and its records where
  one exists;
- the mitigations chosen, as `D`-records, and the risks accepted;
- open security questions, as `O`-records;
- or, if security is unaffected, one sentence saying why.

### The threat-model subtype

A threat model fits `Eval` because it is evidential analysis against a rubric
(§4). The subtype would follow the Threat Modeling Manifesto's four questions:

Table: Sketch of the `threat-model` section shape, mapped onto the Eval spine.

| Eval section (§14) | Threat-model content |
|---|---|
| Method | Scope, method (for example STRIDE), and what counts as evidence |
| The Shared Scenario | "What are we working on?": the system, its assets, data flows, and trust boundaries, with a diagram |
| The Rubric | "What can go wrong?": the threat categories assessed |
| Per-threat renditions | Each threat with its likelihood and impact, linked to an `O`-record if open or a `D`-record if mitigated or accepted |
| Synthesis | "What are we going to do about it?" and "Did we do a good job?" |

## What the toolchain could check

Given the plans already written, each of these is cheap and deterministic:

- **A security-boundary map.** `compass map --concern security-boundary` lists
  every trust-boundary file with its effective invariants, rationale, and tests:
  one view for reviewers, auditors, and agents.
- **Coverage warnings:**
  - a `security-boundary` file without `Tests:`;
  - a `security-boundary` file without `See:`;
  - a `Plan`, `Arch`, or `Spec` without Security Considerations;
  - an `Accepted` document that cites an open security `O`-record without
    acknowledging it.
- **Review routing.** Generate `CODEOWNERS` entries from `Concerns:`, so that a
  change to a security boundary requires a named reviewer. `compass diff`
  (COMPASS-DRAFT-agent-workflow-D5) classifies any change touching such a file as
  substantive, never mechanical.
- **Secret and leak scanning of the corpus.** Memos and Logs invite environment
  detail: host names, local paths, keys pasted while debugging. Operator Memory's
  index linter already checks for private-path leaks; Compass should at least
  match it, ideally by running an established secret scanner over `doc/` and
  source headers rather than writing its own.

## The agent angle

This is where Compass's contribution is most distinctive.

- **Constraints at the point of change.** The session catalog and source map
  put a file's invariants in front of an agent before it edits that file. The
  2026 context-rot study by Xue (cited in
  [COMPASS-DRAFT-agent-context-eval](Eval.AgentContext.md)) found that rot most
  often appears as a silently dropped requirement; a security invariant is the
  most costly requirement to drop.
- **Escalation in the maintenance loop.** When a change touches a
  `security-boundary` file, `compass-maintain` would require the governing
  document's Security Considerations to be revisited and flag the change for
  human review before any acceptance.
- **Traceable AI involvement.** `Assisted-by:` trailers
  (COMPASS-DRAFT-agent-workflow-D7) make it auditable where AI-assisted changes
  landed in security-sensitive code, the kind of traceability SP 800-218A asks
  of AI-involved development.
- **Measured, not asserted.** Track 1 of
  [COMPASS-DRAFT-agent-context-eval](Eval.AgentContext.md) now includes
  security-invariant trap tasks, so the claim that typed context helps agents
  keep security constraints can be tested rather than asserted.

## Compass as an attack surface

Delivering a corpus into agents' context creates risks Compass must own.

1. **Prompt injection through the corpus** (OWASP LLM01). Text that reaches the
   catalog or a source header becomes context in every future session: a
   `read-if:` line, a memo title, an `Invariant:` line. One malicious pull
   request could plant instructions for every agent that follows. Candidate
   mitigations:
   - the catalog carries only short metadata fields, each with a length limit,
     never bodies (already true of COMPASS-DRAFT-toolchain-D11);
   - the adapter frames injected text as reference data, not as instructions;
   - only human-accepted (Authoritative) entries receive prominence, and the
     change gate (COMPASS-DRAFT-agent-workflow-D5) means a human merged
     everything that is injected;
   - a lint flags imperative or injection-like phrasing in routing fields.
2. **Federated trust.** One-hop federation (COMPASS-DRAFT-toolchain-D11) brings
   another repository's text into local sessions. Federation entries in the
   manifest should carry a trust level, and text from an untrusted namespace
   should never be injected.
3. **The toolchain on untrusted input.** In CI the toolchain reads pull requests,
   including ones from forks. The ledger and manifest already use a restricted
   reader with `*read-eval*` bound to false. Front-matter passes through libyaml
   by way of CFFI, a native parsing surface, which adds a security argument to
   COMPASS-DRAFT-toolchain-O1. The pinned, sigstore-verified ocicl dependencies
   of COMPASS-DRAFT-toolchain-D8 already align with SSDF's toolchain practices
   and SLSA's build track.
4. **Disclosure timing.** A public corpus must not describe an unfixed
   vulnerability. Embargoed issues belong in the forge's private advisory
   mechanism; they enter the corpus, as a `Log` or a resolved `O`-record, only
   after disclosure. A threat model of a public project should be written with
   the same care.

## Alignment with established frameworks

Compass should not compete with these frameworks. It can supply the design-
intent layer they assume exists.

Table: Security frameworks and what Compass could supply to each.

| Framework | What Compass supplies |
|---|---|
| NIST SSDF (SP 800-218 v1.1; v1.2 in draft) | PO.1 security requirements and PW.1 risk-informed design as typed decisions and threat records; PW.2 design review through §6 review; evidence through Logs and commit-pinned references |
| NIST SP 800-218A | Records of AI involvement; human gates on agent changes |
| OWASP SAMM | Threat Assessment through the `threat-model` subtype; requirements-driven testing through `Tests:` |
| Threat Modeling Manifesto | The shape of the `threat-model` subtype |
| SLSA, OpenSSF Scorecard, SBOM and VEX | Out of scope; linked from a `Ref` or the manifest as external artefacts |
| EU Cyber Resilience Act | Supporting material for the technical documentation of Annex VII; never the record itself |

A positioning statement follows from this: **Compass is the design-intent
layer that secure-development frameworks require and that coding agents can
consume: typed so that outdated guidance is excluded, delivered at the point of
change, and gated by human review.**

## Candidate imports

Each is listed with its form, dependency, and likely amendment class under
§13. The order is the suggested order of adoption.

Table: Candidate security imports, with form, dependency, and amendment class.

| # | Candidate | Form | Depends on | Class |
|---|---|---|---|---|
| 1 | Prompt-injection hardening of delivered context | Decisions in COMPASS-DRAFT-toolchain (catalog field limits, routing-field lint) and COMPASS-DRAFT-agent-workflow (adapter framing) | This survey's acceptance | None to core |
| 2 | Federation trust levels | A `:trust` key on manifest `:federation` entries; untrusted text never injected | COMPASS-DRAFT-toolchain-D4, D11 | None to core |
| 3 | Security Considerations section | Required in `Plan`, `Arch`, `Spec`; `shape/sections` checks it | None | Patch (§14) |
| 4 | `threat-model` Eval subtype | Section shape as sketched above; a template | None | Minor (§4, §14) |
| 5 | Coverage warnings and the security-boundary map | Toolchain rules and `compass map --concern` | COMPASS-DRAFT-toolchain-D14 | None to core |
| 6 | Review routing | `CODEOWNERS` generation from `Concerns:`; boundary changes always substantive | Candidate 5; COMPASS-DRAFT-agent-workflow-D5 | None to core |
| 7 | Corpus secret scanning | An external scanner run over `doc/` and source headers in CI | None | None to core |
| 8 | Security escalation in `compass-maintain` | Boundary changes require revisiting Security Considerations | COMPASS-DRAFT-agent-workflow-D9 | None to core |
| 9 | Security-invariant trap tasks | Track 1 of COMPASS-DRAFT-agent-context-eval | Done in that document | None |
| 10 | Disclosure guidance | A short rule in §2 or §9: no unfixed vulnerabilities in a public corpus | None | Patch |

Candidates 1 and 2 should be decided before the catalog is built, since they
constrain its design; COMPASS-DRAFT-toolchain step 6 is in any case gated on the
evaluation, which leaves time.

## Honest Limits

- **Documentation is not security.** A complete, current, well-linked threat
  model protects nothing by itself. Compass can make security knowledge
  available and harder to lose; whether anyone acts on it is outside its reach.
- **No evidence yet.** Whether typed context helps agents keep security
  invariants is untested. The new Track 1 tasks will give a first measurement on
  one repository.
- **Classic is an immature security target.** Most of its security analysis
  describes what is missing, so its trap tasks can only test that existing
  checks are preserved. A codebase with real trust boundaries, such as Origin's
  wire codec, would be a stronger test.
- **New ceremony.** A mandatory section and a new subtype add authoring cost,
  which the operator-memory survey warned suppresses updates. A reasoned "none"
  must stay cheap.
- **Injection mitigations are partial.** Length limits, framing, and lint reduce
  the risk of prompt injection through the corpus; none eliminates it. Human
  review of everything injected remains the real control.
- **Public threat models inform attackers too.** The disclosure rule covers
  unfixed vulnerabilities, but even a thorough account of mitigated threats maps
  a system's defences.

## Relationship to Other Work

- [COMPASS-0001](../Compass.md):
  - §2 keeps compliance regimes, requirements traceability, and incident
    postmortems out of scope; this survey respects all three.
  - §4 and §14 receive the `threat-model` subtype and the Security
    Considerations section.
  - §6's review rules and §9's commit-pinned references carry most of the
    verification burden.
- [COMPASS-DRAFT-toolchain](Plan.Toolchain.md): the catalog (D11), weight (D12),
  source map (D14), manifest (D4, D15), and the YAML-parser question (O1).
- [COMPASS-DRAFT-source-headers](Spec.SourceHeaders.md): `Concerns:
  security-boundary`, `Invariant:`, `See:`, and `Tests:` are the file-level
  carriers.
- [COMPASS-DRAFT-agent-workflow](Plan.AgentWorkflow.md): memos, review gates,
  `Assisted-by:` trailers, `compass-maintain`, and the session adapter.
- [COMPASS-DRAFT-agent-context-eval](Eval.AgentContext.md): the security trap
  tasks.
- Classic's `securityPoints.md` is the worked example and the natural first
  migration: a `threat-model` Eval with one `O`-record per unaddressed area.

## Open Questions

### COMPASS-DRAFT-secure-development-O1 — Security-boundary lint severity

Should a `security-boundary` file without `Tests:` or `See:` be a warning, as
proposed, or an error? An error enforces the chain but would block adoption in
repositories with many boundary files and no tests yet.

### COMPASS-DRAFT-secure-development-O2 — Injection lint precision

What does "injection-like phrasing" mean precisely enough to lint? A pattern
list catches crude attempts and produces false positives on legitimate routing
lines ("Read-if: you must change the codec"). Is a lint worth its noise, or
should the controls rest on length limits, framing, and review?

### COMPASS-DRAFT-secure-development-O3 — Where threat models live

Should a threat model always be a separate `threat-model` Eval, or may a small
project's threat model live entirely in an `Arch`'s or `Plan`'s Security
Considerations section, with records but no separate document?

### COMPASS-DRAFT-secure-development-O4 — Security memos and disclosure

A memo stating a security property ("receivers are not authenticated") is also
a statement of a weakness. Should security-relevant memos be marked, held back
from public catalogs, or kept out of public corpora until mitigated?

### COMPASS-DRAFT-secure-development-O5 — A `security` audience

The §21 audience extension (`developer | end-user | both`) may need a
`security-reviewer` persona (cf. §23 O5), so that a projection can produce a
security review packet from the corpus. Is that worth defining?

### COMPASS-DRAFT-secure-development-O6 — Migrating Classic's analysis

Should Classic's `securityPoints.md` be the first migrated document, as a
`threat-model` Eval with six `O`-records, and if so, before or after the
evaluation's seed corpora are frozen? Migrating it first would change what the
Track 1 corpus contains.
