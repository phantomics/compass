---
id:            <NAMESPACE>-DRAFT-<slug>
title:         <Topic> Development Log
genre:         Log
scope:         component            # component | project | program
project:       <project>
component:     <component>
language:      en
status:        Draft                # Draft while in progress; Accepted/Implemented when done (§6)
# authors/created/updated may be omitted and derived from Git (§7)
provenance:
  assistant:   <assistant>         # required when LLM-assisted (§7); remove if not
relates-to:
  - <ID>                            # optional; remove if none
decisions:
  - <NAMESPACE>-DRAFT-<slug>-D1     # records this log defines or amends (§8); remove if none
---

# <Topic>: Development Log

This document chronicles <the work: what was built and verified>.

## Problem

<The problem this work addresses, and why it mattered now.>

<!-- optional background section(s) before Design Decisions, e.g.:
## Investigation
## Starting point
## How real terminals do this
-->

## Design Decisions

<ADR-shaped D-records (§8). One ### per decision.>

### <NAMESPACE>-DRAFT-<slug>-D1 — <decision title>

**Status:** Proposed         <!-- a person sets Accepted (§6) -->
**Context:** <the problem and forces>
**Decision:** <what was chosen>
**Alternatives:** <what was rejected, and why>

## Implementation

<Subsections per component/file. Anchor claims with commit-pinned code
references (§9): `path:symbol@revision` — mandatory in a Log.>

### `<path>`

<What changed here, referencing `<path>:<symbol>@<revision>`.>

<!-- optional, between Implementation and Verification:
## Design Properties
<invariants the change preserves>
-->

## Verification

<State the test-run command and the pass count. Note any manual/headless
caveats. e.g. "Run via `<command>`. Result: N checks, 100% pass; 0 regressions.">

## Files

| File | Action | Description |
|------|--------|-------------|
| `<path>` | **New** | <what it is> |
| `<path>` | Modified | <what changed> |

<!-- add a leading `Repo` column only for cross-repository work (§14) -->

<!-- optional after Verification/Files, a "meaning" section:
## What This Enables
## What This Demonstrates
## The Principle That Emerged
-->

<!-- optional, defined counters only (§14):
## Metrics
- Test checks added: <n>
- Regressions: <n>
- New source files: <n>
-->

## Outstanding Work

- **<item>.** <what remains and why it was deferred>

<!-- Follow-up work is appended as `## Update <date> — <title>` sections;
     larger follow-ups become new Log documents linked via relates-to (§14). -->
